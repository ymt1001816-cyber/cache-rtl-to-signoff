// cache_scoreboard.sv : predicts the right answer and checks every read
// Same idea as ref_mem in tb/tb_cache.v:
//   - ref_mem starts with the same pattern as the memory (32'hA000_0000 + i)
//   - a write updates ref_mem
//   - a read must return ref_mem[addr[15:2]], otherwise FAIL
class cache_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(cache_scoreboard)

  uvm_analysis_imp #(cache_item, cache_scoreboard) imp;  // the monitor's items arrive here (calls write())

  bit [31:0] ref_mem [0:16383];
  int        pass_cnt, fail_cnt;
  int        min_checks = 1; // a test may require a higher number of compared reads

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp = new("imp", this);
    for (int i = 0; i < 16384; i++)
      ref_mem[i] = 32'hA000_0000 + i;
    pass_cnt = 0;
    fail_cnt = 0;
  endfunction

  // called automatically every time the monitor does ap.write(it)
  function void write(cache_item it);
    if (it.is_write) begin
      ref_mem[it.addr[15:2]] = it.wdata; // predict from CPU intent, independently of responder memory
    end else if (it.rdata !== ref_mem[it.addr[15:2]]) begin
      fail_cnt++;
      `uvm_error("MISMATCH", $sformatf("addr=%h got=%h exp=%h",
                 it.addr, it.rdata, ref_mem[it.addr[15:2]]))
    end else begin
      pass_cnt++;
    end
  endfunction

  // runs once at the end of the simulation
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB", $sformatf("PASS = %0d, FAIL = %0d", pass_cnt, fail_cnt), UVM_NONE)
    if (pass_cnt + fail_cnt < min_checks) begin
      `uvm_error("SCB", $sformatf("Too few reads checked: got %0d, require at least %0d",
                                pass_cnt + fail_cnt, min_checks))
    end
  endfunction

endclass
