// tb_top.sv : the only module. Clock, reset, interface, DUT, then start UVM.
// `timescale 1ns/1ps
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "cache_item.sv"
`include "cpu_driver.sv"
`include "cpu_monitor.sv"
`include "mem_responder.sv"
`include "cache_scoreboard.sv"
`include "cache_coverage.sv"
`include "cpu_agent.sv"
`include "cache_env.sv"
`include "cache_seq.sv"
`include "cache_test.sv"

module tb_top;
  logic clk = 0;
  always #5 clk = ~clk;              // 100 MHz, same as tb_cache.v

  cache_if vif(clk);

  cache_top dut (
    .clk(clk), .rst_n(vif.rst_n),
    .cpu_addr(vif.cpu_addr), .cpu_wdata(vif.cpu_wdata),
    .cpu_rd(vif.cpu_rd), .cpu_wr(vif.cpu_wr),
    .cpu_rdata(vif.cpu_rdata), .cpu_ready(vif.cpu_ready),
    .mem_addr(vif.mem_addr), .mem_wdata(vif.mem_wdata),
    .mem_rd(vif.mem_rd), .mem_wr(vif.mem_wr),
    .mem_rdata(vif.mem_rdata), .mem_ack(vif.mem_ack)
  );

  initial begin
    vif.rst_n = 0;
    repeat (3) @(posedge clk);
    @(negedge clk) vif.rst_n = 1; // release away from the DUT sampling edge
  end

  initial begin
    uvm_config_db#(virtual cache_if)::set(null, "*", "vif", vif);   // driver, monitor, responder get it here
    run_test();                                                     // test name comes from +UVM_TESTNAME
  end
endmodule
