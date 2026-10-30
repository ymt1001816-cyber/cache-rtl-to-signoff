`timescale 1ns/1ps

// axil_cache_csr.v : axil_cache.v + control / status registers (CSR) at AXI address bit 16 = 1
//   0x1_0000 ID (RO)  0x1_0004 CTRL (RW, bit0 cnt_en)  0x1_0008 CMD (WO, bit0 flush, bit1 cnt_clr)
//   0x1_000C HIT_CNT  0x1_0010 MISS_CNT  0x1_0014 WR_CNT (RO)    other CSR offsets: SLVERR
//   AXI4-Lite read / write  ->  cpu_rd / cpu_wr  ->  wait for cpu_ready  ->  AXI response
//   See AXI_GUIDE.md for the handshake rules.
module axil_cache_csr (
    input             clk,
    input             rst_n,
    // AXI4-Lite slave: write address
    input             awvalid,
    output            awready,
    input      [31:0] awaddr,
    // write data
    input             wvalid,
    output            wready,
    input      [31:0] wdata,
    input      [3:0]  wstrb,
    // write response
    output            bvalid,
    input             bready,
    output     [1:0]  bresp,
    // read address
    input             arvalid,
    output            arready,
    input      [31:0] araddr,
    // read data
    output            rvalid,
    input             rready,
    output     [31:0] rdata,
    output     [1:0]  rresp,
    // memory side of the cache (same as cache_top)
    output     [13:0] mem_addr,
    output     [31:0] mem_wdata,
    output            mem_rd,
    output            mem_wr,
    input      [31:0] mem_rdata,
    input             mem_ack
);
    localparam IDLE = 3'd0, READ = 3'd1, WRITE = 3'd2,
               RRESP = 3'd3, BRESP = 3'd4;
    reg [2:0] state;
    reg [15:0] read_addr, write_addr;
    reg [31:0] write_data, read_data;
    reg [3:0] write_strb;
    reg have_aw, have_w;
    reg [1:0] write_resp, read_resp;
    reg w_csr;                              // the stored write address is a CSR (address bit 16)

    // ---- CSR ----
    localparam [31:0] ID = 32'hCA0E_0001;
    reg        cnt_en;                      // CTRL bit 0
    reg        flush, cnt_clr;              // CMD bits: 1-cycle pulses
    reg [31:0] hit_cnt, miss_cnt, wr_cnt;
    reg        refilled;                    // the current read needed a refill (= miss)
    function csr_ok(input [15:0] a);        // mapped CSR offsets 0x00-0x14
        csr_ok = (a[15:5] == 0) && (a[4:2] <= 3'd5);
    endfunction
    function [31:0] csr_rdata(input [15:0] a);
        case (a[4:2])
            0: csr_rdata = ID;
            1: csr_rdata = {31'b0, cnt_en};
            3: csr_rdata = hit_cnt;
            4: csr_rdata = miss_cnt;
            5: csr_rdata = wr_cnt;
            default: csr_rdata = 0;
        endcase
    endfunction
    wire        aw_csr  = have_aw ? w_csr : awaddr[16];
    wire [15:0] aw_off  = have_aw ? write_addr : awaddr[15:0];
    wire [31:0] w_data  = have_w ? write_data : wdata;
    wire [3:0]  w_strb  = have_w ? write_strb : wstrb;
    wire cpu_ready;
    wire [31:0] cpu_rdata;

    // Give writes priority; a partial write reserves the single request slot.
    assign awready = rst_n && state == IDLE && !have_aw;
    assign wready  = rst_n && state == IDLE && !have_w;
    assign arready = rst_n && state == IDLE && !have_aw && !have_w
                   && !awvalid && !wvalid;
    assign bvalid = rst_n && state == BRESP;
    assign bresp = write_resp;
    assign rvalid = rst_n && state == RRESP;
    assign rdata = read_data;
    assign rresp = read_resp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            have_aw <= 0;
            have_w <= 0;
            read_addr <= 0;
            write_addr <= 0;
            write_data <= 0;
            write_strb <= 0;
            read_data <= 0;
            write_resp <= 0;
            read_resp <= 0;
            w_csr <= 0;
            cnt_en <= 1;
            flush <= 0;
            cnt_clr <= 0;
            hit_cnt <= 0;
            miss_cnt <= 0;
            wr_cnt <= 0;
            refilled <= 0;
        end else begin
            flush <= 0;                     // CMD bits are pulses
            cnt_clr <= 0;
            // ---- counters ----
            if (state == READ && mem_rd && mem_ack) refilled <= 1;
            if (cnt_clr) begin
                hit_cnt <= 0;
                miss_cnt <= 0;
                wr_cnt <= 0;
            end else if (cnt_en) begin
                if (state == READ && cpu_ready) begin
                    if (refilled) miss_cnt <= miss_cnt + 1'b1;
                    else hit_cnt <= hit_cnt + 1'b1;
                end
                if (state == WRITE && cpu_ready) wr_cnt <= wr_cnt + 1'b1;
            end
            case (state)
                IDLE: begin
                    if (awvalid && awready) begin
                        write_addr <= awaddr[15:0];
                        w_csr <= awaddr[16];
                        have_aw <= 1;
                    end
                    if (wvalid && wready) begin
                        write_data <= wdata;
                        write_strb <= wstrb;
                        have_w <= 1;
                    end
                    // Include handshakes on this edge, not just the saved flags.
                    if ((have_aw || (awvalid && awready)) &&
                        (have_w || (wvalid && wready))) begin
                        if (w_strb != 4'hf || (aw_csr && !csr_ok(aw_off))) begin
                            write_resp <= 2'b10; // partial write or unmapped CSR: SLVERR, no write
                            state <= BRESP;
                        end else if (aw_csr) begin
                            case (aw_off[4:2])
                                1: cnt_en <= w_data[0];
                                2: begin flush <= w_data[0]; cnt_clr <= w_data[1]; end
                                default: begin end // writes to mapped RO registers are ignored
                            endcase
                            write_resp <= 2'b00;
                            state <= BRESP;
                        end else begin
                            write_resp <= 2'b00;
                            state <= WRITE;
                        end
                    end else if (arvalid && arready) begin
                        read_addr <= araddr[15:0];
                        if (araddr[16]) begin    // CSR read: answer at once, no cache access
                            read_data <= csr_rdata(araddr[15:0]);
                            read_resp <= csr_ok(araddr[15:0]) ? 2'b00 : 2'b10;
                            state <= RRESP;
                        end else begin
                            read_resp <= 2'b00;
                            refilled <= 0;
                            state <= READ;
                        end
                    end
                end
                READ: if (cpu_ready) begin
                    read_data <= cpu_rdata; // hold the completed value through R backpressure
                    state <= RRESP;
                end
                WRITE: if (cpu_ready) state <= BRESP;
                RRESP: if (rready) state <= IDLE;
                BRESP: if (bready) begin
                    have_aw <= 0;
                    have_w <= 0;
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                    have_aw <= 0;
                    have_w <= 0;
                end
            endcase
        end
    end

    cache_top_csr u_cache (
        .clk(clk), .rst_n(rst_n),
        .cpu_addr(state == WRITE ? write_addr : read_addr),
        .cpu_wdata(write_data), .cpu_rd(state == READ), .cpu_wr(state == WRITE),
        .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rd(mem_rd), .mem_wr(mem_wr),
        .mem_rdata(mem_rdata), .mem_ack(mem_ack), .flush(flush)
    );
endmodule
