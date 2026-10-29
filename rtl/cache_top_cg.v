`timescale 1ns/1ps

// cache_top_cg.v
// 1 KB direct-mapped write-through cache with clock gating on the data array (copy of cache_top.v)
// Author: Meiyu Kuo

// Handshake:
//   CPU holds cpu_addr / cpu_wdata / cpu_rd / cpu_wr stable until cpu_ready = 1.
//   Memory pulses mem_ack for one cycle when a read or write is done.

module cache_top_cg #(
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
    reg [DATA_W-1:0] data_arr [0:LINES*WORDS-1]; // all cache data words

    wire [TAG_W-1:0] addr_tag = cpu_addr[ADDR_W-1:ADDR_W-TAG_W]; // address tag
    wire [IDX_W-1:0] addr_idx = cpu_addr[OFF_W+IDX_W-1:OFF_W];   // cache line index
    wire [$clog2(WORDS)-1:0] addr_word = cpu_addr[OFF_W-1:$clog2(DATA_W/8)]; // word index within a block

    wire hit = valid_arr[addr_idx] && (tag_arr[addr_idx] == addr_tag); // tag match and line valid

    localparam IDLE = 2'd0, COMPARE = 2'd1, REFILL = 2'd2, WRITE_MEM = 2'd3; // controller states
    reg [1:0] state;       // current controller state
    reg [$clog2(WORDS)-1:0] refill_cnt; // current refill word (0 to WORDS-1)

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
                            state <= COMPARE;              // compare again after refill
                        end
                    end
                WRITE_MEM:
                    if (mem_ack) state <= IDLE;             // memory write complete
                default: state <= IDLE;                    // safety: unknown state goes back to idle
            endcase
        end
    end

    // Only the word being updated receives a clock edge.
    wire word_we = (state == REFILL && mem_ack)
                || (state == WRITE_MEM && mem_ack && hit);
    wire [IDX_W+$clog2(WORDS)-1:0] word_sel = (state == REFILL)
                                            ? {addr_idx, refill_cnt} : {addr_idx, addr_word};
    wire [DATA_W-1:0] word_wd = (state == REFILL) ? mem_rdata : cpu_wdata;
    wire [LINES*WORDS-1:0] gclk;
    genvar w;
    generate
        for (w = 0; w < LINES*WORDS; w = w + 1) begin : gen_word
            clk_gate u_gate (.clk(clk), .en(word_we && (word_sel == w)), .gclk(gclk[w]));
            always @(posedge gclk[w]) data_arr[w] <= word_wd;
        end
    endgenerate

    // Storage arrays: no reset needed (valid bits guard the contents)
    always @(posedge clk) begin
        if (state == REFILL && mem_ack) begin
            if (refill_cnt == WORDS-1)
                tag_arr[addr_idx] <= addr_tag;            // last word: store the tag
        end
    end

    // Outputs
    assign cpu_rdata = data_arr[{addr_idx, addr_word}];              // selected word
    assign cpu_ready = (state == COMPARE && !cpu_wr && hit)          // read hit
                    || (state == WRITE_MEM && mem_ack);             // write done
    assign mem_rd    = (state == REFILL);                           // refill in progress
    assign mem_wr    = (state == WRITE_MEM);                        // write-through in progress
    assign mem_addr  = (state == REFILL) ? {addr_tag, addr_idx, refill_cnt} // refill: block words 0-3
                                        : cpu_addr[ADDR_W-1:2];     // write: CPU word address
    assign mem_wdata = cpu_wdata;                                   // write data from CPU

endmodule
