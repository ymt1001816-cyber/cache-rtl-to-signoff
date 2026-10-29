// axil_cache.v : AXI4-Lite slave wrapper around cache_top (CPU side); the memory side is unchanged
//   AXI4-Lite read / write  ->  cpu_rd / cpu_wr  ->  wait for cpu_ready  ->  AXI response
//   See AXI_GUIDE.md for the handshake rules.
module axil_cache (
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
    reg [1:0] write_resp;
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
    assign rresp = 2'b00;

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
        end else begin
            case (state)
                IDLE: begin
                    if (awvalid && awready) begin
                        write_addr <= awaddr[15:0];
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
                        if ((have_w ? write_strb : wstrb) != 4'hf) begin
                            write_resp <= 2'b10; // unsupported byte strobes: no cache write
                            state <= BRESP;
                        end else begin
                            write_resp <= 2'b00;
                            state <= WRITE;
                        end
                    end else if (arvalid && arready) begin
                        read_addr <= araddr[15:0];
                        state <= READ;
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

    cache_top u_cache (
        .clk(clk), .rst_n(rst_n),
        .cpu_addr(state == WRITE ? write_addr : read_addr),
        .cpu_wdata(write_data), .cpu_rd(state == READ), .cpu_wr(state == WRITE),
        .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rd(mem_rd), .mem_wr(mem_wr),
        .mem_rdata(mem_rdata), .mem_ack(mem_ack)
    );
endmodule
