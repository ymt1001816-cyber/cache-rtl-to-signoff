// cache_env.sv : the whole testbench: CPU agent + memory responder + scoreboard + coverage
// class cache_env extends uvm_env;
  `uvm_component_utils(cache_env)

  cpu_agent        agt;
  mem_responder    mem;
  cache_scoreboard scb;
  cache_coverage   cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = cpu_agent::type_id::create("agt", this);
    mem = mem_responder::type_id::create("mem", this);
    scb = cache_scoreboard::type_id::create("scb", this);
    cov = cache_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.ap.connect(scb.imp);
    agt.mon.ap.connect(cov.analysis_export);
  endfunction
endclass
