// cache_top_wrap.v : module "cache_top" = cache_top_dft with every test pin off,
//   so the original tb/tb_cache.v runs unchanged on the DFT version (normal operation must not change)
module cache_top #(parameter LINES = 64) (
    input clk, rst_n, input [15:0] cpu_addr, input [31:0] cpu_wdata, input cpu_rd, cpu_wr,
    output [31:0] cpu_rdata, output cpu_ready, output [13:0] mem_addr, output [31:0] mem_wdata,
    output mem_rd, mem_wr, input [31:0] mem_rdata, input mem_ack);
    wire done, fail;
    cache_top_dft #(.LINES(LINES)) u (.clk(clk), .rst_n(rst_n), .cpu_addr(cpu_addr), .cpu_wdata(cpu_wdata),
        .cpu_rd(cpu_rd), .cpu_wr(cpu_wr), .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready), .mem_addr(mem_addr),
        .mem_wdata(mem_wdata), .mem_rd(mem_rd), .mem_wr(mem_wr), .mem_rdata(mem_rdata), .mem_ack(mem_ack),
        .test_en(1'b0), .test_mode(1'b0), .mbist_start(1'b0), .mbist_done(done), .mbist_fail(fail));
endmodule
