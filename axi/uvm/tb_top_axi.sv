// tb_top_axi.sv : UVM top for axil_cache. The AXI agent drives the AXI pins; the reused mem_responder
//   answers the memory side through cache_if. cache_if's cpu_* signals are tapped from the cache INSIDE the
//   wrapper, so the original cache SVAs (no write-allocate, latency, no X) keep checking it under AXI traffic.
`timescale 1ns/1ps
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "cache_item.sv"
`include "mem_responder.sv"
`include "cache_scoreboard.sv"
`include "cache_coverage.sv"
`include "cache_seq.sv"
`include "axil_driver.sv"
`include "axil_monitor.sv"
`include "axil_agent.sv"
`include "axil_env.sv"
`include "axil_test.sv"

module tb_top_axi;
  logic clk = 0;
  always #5 clk = ~clk;

  axil_if  aif(clk);
  cache_if cif(clk);

  axil_cache dut (
    .clk(clk), .rst_n(aif.rst_n),
    .awvalid(aif.awvalid), .awready(aif.awready), .awaddr(aif.awaddr),
    .wvalid(aif.wvalid), .wready(aif.wready), .wdata(aif.wdata), .wstrb(aif.wstrb),
    .bvalid(aif.bvalid), .bready(aif.bready), .bresp(aif.bresp),
    .arvalid(aif.arvalid), .arready(aif.arready), .araddr(aif.araddr),
    .rvalid(aif.rvalid), .rready(aif.rready), .rdata(aif.rdata), .rresp(aif.rresp),
    .mem_addr(cif.mem_addr), .mem_wdata(cif.mem_wdata), .mem_rd(cif.mem_rd), .mem_wr(cif.mem_wr),
    .mem_rdata(cif.mem_rdata), .mem_ack(cif.mem_ack));

  // white-box tap: the cache inside the wrapper
  assign cif.rst_n     = aif.rst_n;
  assign cif.cpu_addr  = dut.u_cache.cpu_addr;
  assign cif.cpu_wdata = dut.u_cache.cpu_wdata;
  assign cif.cpu_rd    = dut.u_cache.cpu_rd;
  assign cif.cpu_wr    = dut.u_cache.cpu_wr;
  assign cif.cpu_rdata = dut.u_cache.cpu_rdata;
  assign cif.cpu_ready = dut.u_cache.cpu_ready;

  initial begin
    aif.rst_n = 0;
    repeat (3) @(posedge clk);
    @(negedge clk) aif.rst_n = 1;
  end

  initial begin
    uvm_config_db#(virtual axil_if)::set(null, "*", "axi_vif", aif);
    uvm_config_db#(virtual cache_if)::set(null, "*", "vif", cif);
    run_test("axil_test");
  end
endmodule
