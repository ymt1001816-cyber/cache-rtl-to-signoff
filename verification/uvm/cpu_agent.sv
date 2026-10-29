// cpu_agent.sv : groups everything for the CPU side: sequencer + driver + monitor
// Industry testbenches reuse whole agents, not single drivers.
class cpu_agent extends uvm_agent;
  `uvm_component_utils(cpu_agent)

  uvm_sequencer #(cache_item) sqr;
  cpu_driver                  drv;
  cpu_monitor                 mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr = uvm_sequencer#(cache_item)::type_id::create("sqr", this);   // example
    drv = cpu_driver::type_id::create("drv", this);
    mon = cpu_monitor::type_id::create("mon", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
