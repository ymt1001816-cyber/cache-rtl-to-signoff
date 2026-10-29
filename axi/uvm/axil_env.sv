// axil_env.sv : same environment as cache_env.sv with the CPU agent replaced by the AXI agent
//   reused unchanged: mem_responder, cache_scoreboard, cache_coverage, and every sequence in cache_seq.sv
class axil_env extends uvm_env;
  `uvm_component_utils(axil_env)
  axil_agent       agt;
  mem_responder    mem;
  cache_scoreboard scb;
  cache_coverage   cov;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = axil_agent::type_id::create("agt", this);
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
