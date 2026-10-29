import uvm_pkg::*;
`include "uvm_macros.svh"

// cache_if.sv : all signals between the testbench and cache_top, in one bundle
// Driver, monitor and memory responder all use this interface.
interface cache_if (input logic clk);

  logic        rst_n;      // active-low reset

  // ---- CPU side (driven by the testbench) ----
  logic [15:0] cpu_addr;   // CPU byte address
  logic [31:0] cpu_wdata;  // CPU write data
  logic        cpu_rd;     // CPU read request
  logic        cpu_wr;     // CPU write request

  // ---- CPU side (driven by the cache) ----
  logic [31:0] cpu_rdata;  // CPU read data
  logic        cpu_ready;  // CPU request complete

  // ---- memory side (driven by the cache) ----
  logic [13:0] mem_addr;   // memory word address (byte offset removed)
  logic [31:0] mem_wdata;  // memory write data
  logic        mem_rd;     // memory read request
  logic        mem_wr;     // memory write request

  // ---- memory side (driven by the testbench memory) ----
  logic [31:0] mem_rdata;  // memory read data
  logic        mem_ack;    // memory request acknowledged

  // ---- assertion (replaces the old mem_reads check of Test 4) ----
  // Write-through + no-write-allocate: while the CPU is writing, the cache must never READ memory
  // (a write hit or a write miss only writes memory; reading would mean a line was allocated).
  a_no_read_on_write : assert property (@(posedge clk) disable iff (!rst_n) cpu_wr |-> !mem_rd)
    else `uvm_error("SVA", "cache read memory during a CPU write (no-write-allocate violation)")

  // Control outputs must be known after reset so requests cannot silently stall.
  a_no_x_ctrl : assert property (@(posedge clk) disable iff (!rst_n)
                                !$isunknown({cpu_ready, mem_rd, mem_wr}))
    else `uvm_error("SVA", "X/Z detected on cache control outputs: cpu_ready, mem_rd, or mem_wr")

  // ---- bounded latency = every request finishes in time ----
  // Like lec10's "req |-> ##[1:3] ack": while a request is waiting, cpu_ready must come within MAX_LAT cycles.
  // (read hit 2 cycles, read miss 15; MAX_LAT leaves room for the slower SRAM versions)
  localparam int MAX_LAT = 20;
  a_req_done : assert property (@(posedge clk) disable iff (!rst_n)
                               ((cpu_rd || cpu_wr) && !cpu_ready) |-> ##[1:MAX_LAT] cpu_ready)
    else `uvm_error("SVA", "CPU request did not complete within MAX_LAT cycles")

  // ---- liveness = "every request is EVENTUALLY answered" (no cycle limit) ----
  // Unlike a_req_done (bounded = safety), a liveness failure can only be reported when the simulation ENDS:
  // Xcelium prints *E,ASEOSF "failed at end of simulation" if a request is still waiting.
  a_req_eventually : assert property (@(posedge clk) disable iff (!rst_n)
                                     (cpu_rd || cpu_wr) |-> s_eventually cpu_ready)
    else `uvm_error("SVA", "CPU request was not eventually answered")

  // ---- cover properties = "did this ever happen?" ----
  // An assertion that never triggers is vacuous (lec11 practice 3B): a cover shows the trigger really happened.
  int n_cov_write_hit_or_miss = 0;   // CPU write finished
  int n_cov_refill = 0;              // read that had to refill from memory
  int n_cov_refill_done = 0;         // temporal refill-to-response cover matches
  c_write : cover property (@(posedge clk) disable iff (!rst_n)
                                 cpu_wr && cpu_ready) n_cov_write_hit_or_miss++;
  c_read_refill : cover property (@(posedge clk) disable iff (!rst_n)
                                  cpu_rd && mem_rd) n_cov_refill++;
  // Observe a refill start followed by a response within the bounded window.
  c_refill_done : cover property (@(posedge clk) disable iff (!rst_n)
                                  $rose(mem_rd) ##[1:MAX_LAT] cpu_ready) n_cov_refill_done++;
  final $display("COVER write=%0d refill=%0d refill_done=%0d",
                 n_cov_write_hit_or_miss, n_cov_refill, n_cov_refill_done);

endinterface
