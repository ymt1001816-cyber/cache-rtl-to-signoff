// axil_agent.sv : AXI4-Lite master agent = sequencer + driver + monitor (same structure as cpu_agent.sv)
class axil_agent extends uvm_agent;
  `uvm_component_utils(axil_agent)

  uvm_sequencer #(cache_item) sqr;
  axil_driver                 drv;
  axil_monitor                mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // TODO: build_phase  - create sqr, drv, mon (see cpu_agent.sv)
  // TODO: connect_phase - connect the driver to the sequencer
endclass
