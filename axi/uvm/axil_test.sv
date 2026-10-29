// axil_test.sv : the same stimulus as cache_test (directed + 10,000 random + stride), sent through the AXI agent
class axil_test extends uvm_test;
  `uvm_component_utils(axil_test)
  axil_env env;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axil_env::type_id::create("env", this);
  endfunction
  task run_phase(uvm_phase phase);
    cache_directed_seq d = cache_directed_seq::type_id::create("d");
    cache_random_seq   r = cache_random_seq::type_id::create("r");
    cache_stride_seq   s = cache_stride_seq::type_id::create("s");
    phase.raise_objection(this);
    wait (env.agt.drv.vif.rst_n === 1'b1);
    d.start(env.agt.sqr);
    r.start(env.agt.sqr);
    if (!s.randomize()) `uvm_fatal("RAND", "axil_test: stride sequence randomize failed")
    s.start(env.agt.sqr);
    #200;
    phase.drop_objection(this);
  endtask
endclass
