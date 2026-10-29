// cache_stub.v : abstract cache_top for formal (same ports). cpu_ready and cpu_rdata are free (any value, any cycle),
// so the proof holds for every possible cache behavior, and the 8,644 cache flip-flops stay out of the proof.
module cache_top (
    input         clk, rst_n,
    input  [15:0] cpu_addr,
    input  [31:0] cpu_wdata,
    input         cpu_rd, cpu_wr,
    output [31:0] cpu_rdata,
    output        cpu_ready,
    output [13:0] mem_addr,
    output [31:0] mem_wdata,
    output        mem_rd, mem_wr,
    input  [31:0] mem_rdata,
    input         mem_ack
);
    (* anyseq *) reg [31:0] f_rdata;
    (* anyseq *) reg        f_ready;
    assign cpu_rdata = f_rdata;
    assign cpu_ready = f_ready;
    assign mem_addr = 0, mem_wdata = 0, mem_rd = 0, mem_wr = 0;
endmodule
