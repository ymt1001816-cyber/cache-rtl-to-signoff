// cache_formal.sv : formal property verification (FPV) of cache_top with SymbiYosys (lec11 p61-63)
// The formal tool tries EVERY input sequence. "assume" = rules the environment follows (written with an AI assistant,
// same rules as the UVM driver / mem_responder). "assert" = what the cache must do (Meiyu Kuo).
// Open-source Yosys supports only simple SVA, so properties are immediate asserts in always blocks,
// and time windows are written with counters instead of ##[1:N].
module cache_formal (input clk);
  (* anyseq *) reg rst_n, cpu_rd, cpu_wr, mem_ack;   // anyseq = the tool picks any value every cycle
  (* anyseq *) reg [15:0] cpu_addr;
  (* anyseq *) reg [31:0] cpu_wdata, mem_rdata;
  wire [31:0] cpu_rdata, mem_wdata; wire [13:0] mem_addr; wire cpu_ready, mem_rd, mem_wr;
  cache_top dut (.*);

  // ---- environment (assume) ----
  reg [1:0] f_cyc = 0; always @(posedge clk) if (f_cyc != 2'd3) f_cyc <= f_cyc + 1;
  wire f_past = (f_cyc != 0);
  always @(*) if (f_cyc < 2) assume (!rst_n);                       // reset for 2 cycles, then stay out of reset
  always @(*) if (f_cyc >= 2) assume (rst_n);
  always @(*) if (!rst_n) assume (!cpu_rd && !cpu_wr);              // CPU waits for reset (like the UVM driver)
  always @(*) assume (!(cpu_rd && cpu_wr));                          // never read and write at once
  always @(posedge clk) if (f_past && $past(rst_n) && $past((cpu_rd || cpu_wr) && !cpu_ready))
    assume (cpu_rd == $past(cpu_rd) && cpu_wr == $past(cpu_wr) &&    // CPU holds the request until cpu_ready
            cpu_addr == $past(cpu_addr) && cpu_wdata == $past(cpu_wdata));
  always @(*) if (!(mem_rd || mem_wr)) assume (!mem_ack);            // memory only answers a request
  reg [3:0] f_mem_wait;                                              // memory answers within 3 cycles
  always @(posedge clk) if (!rst_n || mem_ack || !(mem_rd || mem_wr)) f_mem_wait <= 0; else f_mem_wait <= f_mem_wait + 1;
  always @(*) assume (f_mem_wait < 3);

  // cycles the current CPU request has been waiting (use it for the latency property)
  reg [5:0] f_wait;
  always @(posedge clk) if (!rst_n || cpu_ready || !(cpu_rd || cpu_wr)) f_wait <= 0; else f_wait <= f_wait + 1;

  // ---- Step 10: properties.  Format:  name: assert (expression);  inside the block ----
  always @(*) if (rst_n) begin
    a_no_read_on_write: assert (!cpu_wr || !mem_rd);
    a_req_done: assert (f_wait < 20);
    a_one_mem_op: assert (!(mem_rd && mem_wr));
    // Helper invariants constrain the reachable protocol states during induction.
    h_refill_is_read: assert (!mem_rd || (cpu_rd && !cpu_wr));
    h_wmem_is_write: assert (!mem_wr || cpu_wr);
  end

  // ---- covers: prove the checks are not vacuous (lec11 practice 3) ----
  always @(*) if (rst_n) begin
    c_read_done: cover (cpu_ready && cpu_rd);
    c_write_done: cover (cpu_ready && cpu_wr);
    c_refill: cover (mem_rd && mem_ack);
  end
endmodule
