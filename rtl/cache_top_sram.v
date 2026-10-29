`timescale 1ns/1ps

// cache_top_sram.v
// 1 KB direct-mapped write-through cache with synchronous single-port SRAM.
// Option A: CPU samples read data at the clock edge (2-cycle hit).
// Author: Meiyu Kuo

// Handshake:
//   CPU holds cpu_addr / cpu_wdata / cpu_rd / cpu_wr stable until cpu_ready = 1.
//   Memory pulses mem_ack for one cycle when a read or write is done.

module cache_top_sram #(
    parameter ADDR_W = 16,   // address width (bits)
    parameter DATA_W = 32,   // data width (bits)
    parameter LINES = 64     // number of cache lines
) (
    input  wire              clk,        // clock
    input  wire              rst_n,      // active-low reset
    input  wire [ADDR_W-1:0] cpu_addr,   // CPU byte address
    input  wire [DATA_W-1:0] cpu_wdata,  // CPU write data
    input  wire              cpu_rd,     // CPU read request
    input  wire              cpu_wr,     // CPU write request
    output wire [DATA_W-1:0] cpu_rdata,  // CPU read data
    output wire              cpu_ready,  // CPU request complete
    output wire [ADDR_W-3:0] mem_addr,   // memory word address (byte offset removed)
    output wire [DATA_W-1:0] mem_wdata,  // memory write data
    output wire              mem_rd,     // memory read request
    output wire              mem_wr,     // memory write request
    input  wire [DATA_W-1:0] mem_rdata,  // memory read data
    input  wire              mem_ack     // memory request acknowledged
);

    localparam WORDS = 4;                       // number of words per block
    localparam IDX_W = $clog2(LINES);           // cache index width (bits)
    localparam OFF_W = $clog2(WORDS*(DATA_W/8)); // block byte offset width (bits)
    localparam TAG_W = ADDR_W - IDX_W - OFF_W;  // cache tag width (bits)

    reg [TAG_W-1:0] tag_arr [0:LINES-1];         // tag stored for each cache line
    reg [LINES-1:0] valid_arr;                  // valid bit for each cache line

    wire [TAG_W-1:0] addr_tag = cpu_addr[ADDR_W-1:ADDR_W-TAG_W]; // address tag
    wire [IDX_W-1:0] addr_idx = cpu_addr[OFF_W+IDX_W-1:OFF_W];   // cache line index
    wire [$clog2(WORDS)-1:0] addr_word = cpu_addr[OFF_W-1:$clog2(DATA_W/8)]; // word index within a block

    wire hit = valid_arr[addr_idx] && (tag_arr[addr_idx] == addr_tag); // tag match and line valid

    localparam IDLE = 3'd0, COMPARE = 3'd1, REFILL = 3'd2, WRITE_MEM = 3'd3, READ = 3'd4; // controller states
    reg [2:0] state;       // current controller state
    reg [$clog2(WORDS)-1:0] refill_cnt; // current refill word (0 to WORDS-1)

    wire sram_csb, sram_web; // active-low select and write controls connect the cache to SRAM
    wire [IDX_W+$clog2(WORDS)-1:0] sram_addr; // word address spans every cache line and word offset
    wire [DATA_W-1:0] sram_din, sram_dout; // write data and registered SRAM read data

    // Controller: state, refill counter, valid bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;  // return to idle on reset
            refill_cnt <= 2'd0;
            valid_arr  <= 0;     // invalidate all cache lines
        end else begin
            case (state)
                IDLE:
                    if (cpu_rd || cpu_wr) state <= COMPARE; // CPU read or write request
                COMPARE:
                    if (cpu_wr) state <= WRITE_MEM;         // always write through to memory
                    else if (!hit) begin                   // read miss: refill the block
                        state      <= REFILL;
                        refill_cnt <= 2'd0;
                    end
                    else state <= IDLE;                    // read hit: return data this cycle
                REFILL:
                    if (mem_ack) begin                     // one word received from memory
                        refill_cnt <= refill_cnt + 1'b1;
                        if (refill_cnt == WORDS-1) begin    // final word received
                            valid_arr[addr_idx] <= 1'b1;
                            state <= READ;                 // read SRAM after final refill write
                        end
                    end
                READ: state <= COMPARE;                   // wait for synchronous SRAM read
                WRITE_MEM:
                    if (mem_ack) state <= IDLE;             // memory write complete
                default: state <= IDLE;                    // safety: unknown state goes back to idle
            endcase
        end
    end

    // Storage arrays: no reset needed (valid bits guard the contents)
    always @(posedge clk) begin
        if (state == REFILL && mem_ack) begin
            if (refill_cnt == WORDS-1)
                tag_arr[addr_idx] <= addr_tag;            // last word: store the tag
        end
    end

    // Single-port SRAM control (active-low select and write enable)
    assign sram_csb = !((state == IDLE && cpu_rd) || (state == READ) // select for IDLE read, READ retry, refill write, or write hit
                     || (state == REFILL && mem_ack)
                     || (state == WRITE_MEM && mem_ack && hit));
    assign sram_web = !((state == REFILL && mem_ack) // only acknowledged refill and write-hit transfers write SRAM
                     || (state == WRITE_MEM && mem_ack && hit));
    assign sram_addr = (state == REFILL) ? {addr_idx, refill_cnt} // refill walks all words; CPU reads use addr_word even after counter wraps
                                       : {addr_idx, addr_word};
    assign sram_din = (state == REFILL) ? mem_rdata : cpu_wdata; // refill takes memory data; write hit takes CPU data

    sram_model #(.ADDR_W(IDX_W+$clog2(WORDS)), .DATA_W(DATA_W)) u_sram ( // SRAM replaces the flip-flop data array
        .clk0(clk), .csb0(sram_csb), .web0(sram_web),
        .addr0(sram_addr), .din0(sram_din), .dout0(sram_dout)
    );

    // Outputs
    assign cpu_rdata = sram_dout;              // selected word
    assign cpu_ready = (state == COMPARE && !cpu_wr && hit)          // read hit
                    || (state == WRITE_MEM && mem_ack);             // write done
    assign mem_rd    = (state == REFILL);                           // refill in progress
    assign mem_wr    = (state == WRITE_MEM);                        // write-through in progress
    assign mem_addr  = (state == REFILL) ? {addr_tag, addr_idx, refill_cnt} // refill: block words 0-3
                                        : cpu_addr[ADDR_W-1:2];     // write: CPU word address
    assign mem_wdata = cpu_wdata;                                   // write data from CPU

endmodule
