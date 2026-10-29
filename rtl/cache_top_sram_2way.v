`timescale 1ns/1ps

// cache_top_sram_2way.v
// 1 KB 2-way set-associative write-through cache (top module)
// One synchronous single-port SRAM per way; tags, valid bits, and LRU use flip-flops.
// Author: Meiyu Kuo

// Handshake:
//   CPU holds cpu_addr / cpu_wdata / cpu_rd / cpu_wr stable until cpu_ready = 1.
//   Memory pulses mem_ack for one cycle when a read or write is done.

module cache_top_sram_2way #(
    parameter ADDR_W = 16,   // address width (bits)
    parameter DATA_W = 32,   // data width (bits)
    parameter LINES = 64     // total cache lines across both ways
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
    localparam SETS = LINES / 2; // LINES is total capacity, split evenly across two ways
    localparam IDX_W = $clog2(SETS);           // cache index width (bits)
    localparam OFF_W = $clog2(WORDS*(DATA_W/8)); // block byte offset width (bits)
    localparam TAG_W = ADDR_W - IDX_W - OFF_W;  // cache tag width (bits)

    reg [TAG_W-1:0] tag0_arr [0:SETS-1], tag1_arr [0:SETS-1]; // independent tags let two blocks share one set
    reg [SETS-1:0] valid0, valid1; // each way can hold a valid block independently
    reg [SETS-1:0] lru; // next victim when both ways are valid

    wire [TAG_W-1:0] addr_tag = cpu_addr[ADDR_W-1:ADDR_W-TAG_W]; // address tag
    wire [IDX_W-1:0] addr_idx = cpu_addr[OFF_W+IDX_W-1:OFF_W];   // cache line index
    wire [$clog2(WORDS)-1:0] addr_word = cpu_addr[OFF_W-1:$clog2(DATA_W/8)]; // word index within a block

    wire hit0 = valid0[addr_idx] && (tag0_arr[addr_idx] == addr_tag); // way 0 must be valid and match its own tag
    wire hit1 = valid1[addr_idx] && (tag1_arr[addr_idx] == addr_tag); // way 1 must be valid and match its own tag
    wire hit = hit0 || hit1; // either matching way satisfies the request
    wire victim_next = !valid0[addr_idx] ? 1'b0 : // prefer an empty way; use LRU only when both are occupied
                       !valid1[addr_idx] ? 1'b1 : lru[addr_idx];
    reg victim; // latch the chosen way on a miss so refill cannot switch ways

    localparam IDLE = 3'd0, COMPARE = 3'd1, REFILL = 3'd2, WRITE_MEM = 3'd3, READ = 3'd4; // controller states
    reg [2:0] state;       // current controller state
    reg [$clog2(WORDS)-1:0] refill_cnt; // current refill word (0 to WORDS-1)

    // Controller: state, refill counter, valid bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;  // return to idle on reset
            refill_cnt <= 2'd0;
            valid0 <= 0;
            valid1 <= 0;
            lru <= 0;
            victim <= 0;
        end else begin
            case (state)
                IDLE:
                    if (cpu_rd || cpu_wr) state <= COMPARE; // CPU read or write request
                COMPARE: begin
                    if (hit) lru[addr_idx] <= hit0; // used way 0 -> way 1 becomes the next victim, and vice versa
                    if (cpu_wr) state <= WRITE_MEM;         // always write through to memory
                    else if (!hit) begin                   // read miss: refill the block
                        victim     <= victim_next;
                        state      <= REFILL;
                        refill_cnt <= 2'd0;
                    end
                    else state <= IDLE;                    // read hit: return data this cycle
                end
                REFILL:
                    if (mem_ack) begin                     // one word received from memory
                        refill_cnt <= refill_cnt + 1'b1;
                        if (refill_cnt == WORDS-1) begin    // final word received
                            if (victim) valid1[addr_idx] <= 1'b1; // publish the refilled block only in its selected way
                            else valid0[addr_idx] <= 1'b1; // victim 0 completes in way 0
                            state <= READ;                 // read both SRAM ways after refill
                        end
                    end
                READ: state <= COMPARE; // single port needs a read cycle after the final refill write
                WRITE_MEM:
                    if (mem_ack) state <= IDLE;             // memory write complete
                default: state <= IDLE;                    // safety: unknown state goes back to idle
            endcase
        end
    end

    // Storage arrays: no reset needed (valid bits guard the contents)
    always @(posedge clk) begin
        if (state == REFILL && mem_ack) begin
            if (victim) begin
                if (refill_cnt == WORDS-1) tag1_arr[addr_idx] <= addr_tag;
            end else begin
                if (refill_cnt == WORDS-1) tag0_arr[addr_idx] <= addr_tag;
            end
        end
    end

    wire w0_csb, w0_web, w1_csb, w1_web; // each way has separate active-low select and write controls
    wire [IDX_W+$clog2(WORDS)-1:0] sram_addr; // both ways share the set and word address
    wire [DATA_W-1:0] sram_din, w0_dout, w1_dout; // shared write data; separate read outputs feed the way mux

    // Both ways read in parallel; only the selected way writes.
    assign w0_csb = !((state == IDLE && cpu_rd) || (state == READ) // read both ways; write way 0 only for victim 0 or hit0
                   || (state == REFILL && mem_ack && !victim)
                   || (state == WRITE_MEM && mem_ack && hit0));
    assign w0_web = !((state == REFILL && mem_ack && !victim) // only refill to victim 0 and write hit0 enable writes
                   || (state == WRITE_MEM && mem_ack && hit0));
    assign w1_csb = !((state == IDLE && cpu_rd) || (state == READ) // read both ways; write way 1 only for victim 1 or hit1
                   || (state == REFILL && mem_ack && victim)
                   || (state == WRITE_MEM && mem_ack && hit1));
    assign w1_web = !((state == REFILL && mem_ack && victim) // only refill to victim 1 and write hit1 enable writes
                   || (state == WRITE_MEM && mem_ack && hit1));
    assign sram_addr = (state == REFILL) ? {addr_idx, refill_cnt} // shared address walks refill words, otherwise selects the CPU word
                                       : {addr_idx, addr_word};
    assign sram_din = (state == REFILL) ? mem_rdata : cpu_wdata; // shared data comes from memory on refill, CPU on write hit

    sram_model #(.ADDR_W(IDX_W+$clog2(WORDS)), .DATA_W(DATA_W)) u_way0 ( // one SRAM stores this way; each way holds half the total data capacity
        .clk0(clk), .csb0(w0_csb), .web0(w0_web),
        .addr0(sram_addr), .din0(sram_din), .dout0(w0_dout)
    );
    sram_model #(.ADDR_W(IDX_W+$clog2(WORDS)), .DATA_W(DATA_W)) u_way1 ( // one SRAM stores this way; each way holds half the total data capacity
        .clk0(clk), .csb0(w1_csb), .web0(w1_web),
        .addr0(sram_addr), .din0(sram_din), .dout0(w1_dout)
    );

    // Outputs
    assign cpu_rdata = hit1 ? w1_dout : w0_dout; // hit1 selects way 1; otherwise select way 0
    assign cpu_ready = (state == COMPARE && !cpu_wr && hit)          // read hit
                    || (state == WRITE_MEM && mem_ack);             // write done
    assign mem_rd    = (state == REFILL);                           // refill in progress
    assign mem_wr    = (state == WRITE_MEM);                        // write-through in progress
    assign mem_addr  = (state == REFILL) ? {addr_tag, addr_idx, refill_cnt} // refill: block words 0-3
                                        : cpu_addr[ADDR_W-1:2];     // write: CPU word address
    assign mem_wdata = cpu_wdata;                                   // write data from CPU

endmodule
