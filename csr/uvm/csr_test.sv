// csr_test.sv : register tests through the RAL model
//   csr_reset_test : built-in uvm_reg_hw_reset_seq (every register reads its reset value) + uvm_reg_bit_bash_seq
//   csr_count_test : cache traffic, then HIT / MISS / WR counters vs the monitor-based reference;
//                    cnt_en = 0 freezes, cnt_clr clears, flush makes warm lines miss
class csr_base_test extends uvm_test;
  `uvm_component_utils(csr_base_test)
  csr_env env;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = csr_env::type_id::create("env", this);
  endfunction
  // read one register through the model and compare with an expected value
  task check_reg(uvm_reg r, uvm_reg_data_t exp);
    uvm_status_e st; uvm_reg_data_t v;
    r.read(st, v);
    if (st != UVM_IS_OK || v != exp)
      `uvm_error("CSR", $sformatf("%s = %0d (status %s), expected %0d", r.get_name(), v, st.name(), exp))
    else
      `uvm_info("CSR", $sformatf("%s = %0d as expected", r.get_name(), v), UVM_LOW)
  endtask
  task check_counters();
    check_reg(env.regmodel.hit_cnt,  env.cnt.hits);
    check_reg(env.regmodel.miss_cnt, env.cnt.misses);
    check_reg(env.regmodel.wr_cnt,   env.cnt.writes);
  endtask
endclass

class csr_reset_test extends csr_base_test;
  `uvm_component_utils(csr_reset_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    uvm_reg_hw_reset_seq rst = uvm_reg_hw_reset_seq::type_id::create("rst");
    uvm_reg_bit_bash_seq bash = uvm_reg_bit_bash_seq::type_id::create("bash");
    phase.raise_objection(this);
    wait (env.agt.drv.vif.rst_n === 1'b1);
    // CMD bits are write-1-to-trigger pulses (read back 0) and writing them flushes / clears: not bit-bashable
    uvm_resource_db#(bit)::set({"REG::", env.regmodel.cmd.get_full_name()}, "NO_REG_TESTS", 1, this);
    env.scb.min_checks = 0;                   // this test reads registers only, no cache data
    rst.model = env.regmodel;  rst.start(null);
    `uvm_info("CSR", "uvm_reg_hw_reset_seq done", UVM_LOW)
    bash.model = env.regmodel; bash.start(null);
    `uvm_info("CSR", "uvm_reg_bit_bash_seq done", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass

class csr_count_test extends csr_base_test;
  `uvm_component_utils(csr_count_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    uvm_status_e st;
    cache_random_seq r = cache_random_seq::type_id::create("r");
    cache_read_seq   w;
    int misses_before;
    phase.raise_objection(this);
    wait (env.agt.drv.vif.rst_n === 1'b1);
    // 1. counters follow random traffic
    r.n = 3000; r.start(env.agt.sqr);
    check_counters();
    // 2. cnt_en = 0 freezes the counters
    env.regmodel.ctrl.write(st, 0); env.cnt.enable = 0;
    r.n = 300; r.start(env.agt.sqr);
    check_counters();
    // 3. cnt_clr clears them
    env.regmodel.cmd.write(st, 2); env.cnt.clear();
    check_counters();
    env.regmodel.ctrl.write(st, 1); env.cnt.enable = 1;
    // 4. flush: reread 32 words (warm), flush, reread: all 32 must miss
    for (int pass = 0; pass < 2; pass++)
      for (int k = 0; k < 32; k++) begin
        w = cache_read_seq::type_id::create("w"); w.addr = k << 4; w.start(env.agt.sqr);
      end
    misses_before = env.cnt.misses;
    env.regmodel.cmd.write(st, 1);
    for (int k = 0; k < 32; k++) begin
      w = cache_read_seq::type_id::create("w"); w.addr = k << 4; w.start(env.agt.sqr);
    end
    if (env.cnt.misses - misses_before != 32)
      `uvm_error("FLUSH", $sformatf("%0d of 32 reads missed after flush", env.cnt.misses - misses_before))
    else
      `uvm_info("FLUSH", "all 32 warm lines missed after flush", UVM_LOW)
    check_counters();
    #200;
    phase.drop_objection(this);
  endtask
endclass
