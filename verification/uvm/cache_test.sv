// cache_test.sv : one test = build the env, then run sequences on the CPU agent's sequencer
// Pick the test at run time with +UVM_TESTNAME=cache_test
class cache_test extends uvm_test;
  `uvm_component_utils(cache_test)

  cache_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = cache_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    cache_directed_seq d = cache_directed_seq::type_id::create("d");
    cache_random_seq r = cache_random_seq::type_id::create("r");
    cache_stride_seq s = cache_stride_seq::type_id::create("s");
    phase.raise_objection(this);     // "I am still busy" - the simulation keeps running
    wait (env.agt.drv.vif.rst_n === 1'b1); // wait for reset before sending requests
    d.start(env.agt.sqr);
    r.start(env.agt.sqr);
    if (!s.randomize())
      `uvm_fatal("RAND", "cache_test: stride sequence randomize failed")
    s.start(env.agt.sqr);
    #100;                            // let the last request finish
    phase.drop_objection(this);      // "I am done" - UVM ends the run when nobody is busy
  endtask
endclass

// ---------------------------------------------------------------------------
// reset test = old Test 5. After a reset every line must be invalid,
// so reading an address that was cached must MISS (the cache must read memory again).
// ---------------------------------------------------------------------------
class cache_reset_test extends cache_test;
  `uvm_component_utils(cache_reset_test)

  virtual cache_if vif;   // the test drives rst_n itself

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);   // builds env (from cache_test)
    if (!uvm_config_db#(virtual cache_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "cache_reset_test: no virtual interface 'vif' in config_db")
  endfunction

  task run_phase(uvm_phase phase);   // replaces cache_test's run_phase
    cache_directed_seq d = cache_directed_seq::type_id::create("d");
    cache_read_seq     rd = cache_read_seq::type_id::create("rd");
    bit saw_mem_rd = 0;
    phase.raise_objection(this);
    wait (vif.rst_n === 1'b1);
    d.start(env.agt.sqr);                       // 1A30 is now in the cache (Test 1)

    @(negedge vif.clk) vif.rst_n <= 0;
    repeat (2) @(posedge vif.clk);
    @(negedge vif.clk) vif.rst_n <= 1;

    fork
      begin
        rd.addr = 16'h1A30;
        rd.start(env.agt.sqr);
      end
      forever @(posedge vif.clk)
        if (vif.mem_rd) saw_mem_rd = 1;
    join_any
    disable fork; // the read has completed; stop the memory watcher

    if (!saw_mem_rd) begin
      `uvm_error("RESET", "read after reset hit: lines were not invalidated")
    end else begin
      `uvm_info("RESET", "read after reset missed, as expected", UVM_NONE)
    end

    #100;
    phase.drop_objection(this);
  endtask
endclass

// ---------------------------------------------------------------------------
// biased test = directed + biased random (run with +UVM_TESTNAME=cache_biased_test)
// ---------------------------------------------------------------------------
class cache_biased_test extends cache_test;
  `uvm_component_utils(cache_biased_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  task run_phase(uvm_phase phase);
    cache_directed_seq d = cache_directed_seq::type_id::create("d");
    cache_biased_seq   b = cache_biased_seq::type_id::create("b");
    phase.raise_objection(this);
    wait (env.agt.drv.vif.rst_n === 1'b1);
    d.start(env.agt.sqr);
    b.start(env.agt.sqr);
    #100;
    phase.drop_objection(this);
  endtask
endclass
