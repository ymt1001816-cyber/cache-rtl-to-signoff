`timescale 1ns/1ps

// cache_top_wb.v
// 1 KB direct-mapped write-back, write-allocate cache (top module)
// Author: Meiyu Kuo

// Handshake:
//   CPU holds cpu_addr / cpu_wdata / cpu_rd / cpu_wr stable until cpu_ready = 1.
//   Memory pulses mem_ack for one cycle when a read or write is done.

module cache_top_wb #(
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
    reg [LINES-1:0] dirty_arr; // marks cached data newer than backing memory; flush before reset
    reg [LINES-1:0] valid_arr;                  // valid bit for each cache line
    reg [DATA_W-1:0] data_arr [0:LINES*WORDS-1]; // all cache data words

    wire [TAG_W-1:0] addr_tag = cpu_addr[ADDR_W-1:ADDR_W-TAG_W]; // address tag
    wire [IDX_W-1:0] addr_idx = cpu_addr[OFF_W+IDX_W-1:OFF_W];   // cache line index
    wire [$clog2(WORDS)-1:0] addr_word = cpu_addr[OFF_W-1:$clog2(DATA_W/8)]; // word index within a block

    wire hit = valid_arr[addr_idx] && (tag_arr[addr_idx] == addr_tag); // tag match and line valid

    localparam IDLE = 2'd0, COMPARE = 2'd1, REFILL = 2'd2, WRITEBACK = 2'd3; // controller states
    reg [1:0] state;       // current controller state
    reg [$clog2(WORDS)-1:0] refill_cnt; // current refill word (0 to WORDS-1)

    // Controller: state, refill counter, valid bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;  // return to idle on reset
            refill_cnt <= 2'd0;
            dirty_arr  <= 0; // reset discards dirty state; it does not write cached data back
            valid_arr  <= 0;     // invalidate all cache lines
        end else begin
            case (state)
                IDLE:
                    if (cpu_rd || cpu_wr) state <= COMPARE; // CPU read or write request
                COMPARE: begin
                    if (hit) begin
                        if (cpu_wr) dirty_arr[addr_idx] <= 1'b1; // write hit changes cache only, so memory is now stale
                        state <= IDLE;
                    end else begin
                        state <= (valid_arr[addr_idx] && dirty_arr[addr_idx]) // preserve a valid dirty victim before allocating the requested block
                               ? WRITEBACK : REFILL; // clean or invalid victims can be overwritten without a writeback
                        refill_cnt <= 0;
                    end
                end
                REFILL:
                    if (mem_ack) begin                     // one word received from memory
                        refill_cnt <= refill_cnt + 1'b1;
                        if (refill_cnt == WORDS-1) begin    // final word received
                            valid_arr[addr_idx] <= 1'b1;
                            dirty_arr[addr_idx] <= 1'b0; // memory and cache agree after completed refill or writeback
                            state <= COMPARE;              // compare again after refill
                        end
                    end
                WRITEBACK: // drain all four words of the old block before starting refill
                    if (mem_ack) begin
                        refill_cnt <= refill_cnt + 1'b1;
                        if (refill_cnt == WORDS-1) begin
                            dirty_arr[addr_idx] <= 1'b0; // memory and cache agree after completed refill or writeback
                            state <= REFILL; // last writeback word is acknowledged; wrapped counter restarts at word 0
                        end
                    end
                default: state <= IDLE;                    // safety: unknown state goes back to idle
            endcase
        end
    end

    // Storage arrays: no reset needed (valid bits guard the contents)
    always @(posedge clk) begin
        if (state == REFILL && mem_ack) begin
            data_arr[{addr_idx, refill_cnt}] <= mem_rdata; // store the refilled word
            if (refill_cnt == WORDS-1)
                tag_arr[addr_idx] <= addr_tag;            // last word: store the tag
        end
        if (state == COMPARE && cpu_wr && hit) // both original write hits and allocated write misses update the cache here
            data_arr[{addr_idx, addr_word}] <= cpu_wdata;  // write hit: update the cached word
    end

    // Outputs
    assign cpu_rdata = data_arr[{addr_idx, addr_word}];              // selected word
    assign cpu_ready = (state == COMPARE && hit); // read and write hits complete without waiting for a memory write
    assign mem_rd = (state == REFILL);
    assign mem_wr = (state == WRITEBACK); // only dirty eviction writes backing memory
    // Eviction uses the cached tag, not the incoming request's tag.
    assign mem_addr = (state == WRITEBACK)
                    ? {tag_arr[addr_idx], addr_idx, refill_cnt} // old tag identifies the block being evicted, not the incoming block
                    : {addr_tag, addr_idx, refill_cnt}; // refill addresses belong to the incoming request
    assign mem_wdata = data_arr[{addr_idx, refill_cnt}]; // writeback streams the victim block word selected by the counter

endmodule
