// csr_env.sv : the AXI environment + register model, adapter and counter reference
class csr_env extends axil_env;
  `uvm_component_utils(csr_env)
  cache_reg_block  regmodel;
  axil_reg_adapter adapter;
  csr_counter      cnt;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    regmodel = cache_reg_block::type_id::create("regmodel");
    regmodel.build();
    adapter = axil_reg_adapter::type_id::create("adapter");
    cnt = csr_counter::type_id::create("cnt", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    regmodel.default_map.set_sequencer(agt.sqr, adapter);
    regmodel.default_map.set_auto_predict(1);   // the mirror follows every read / write done through the model
    agt.mon.ap.connect(cnt.analysis_export);
  endfunction
endclass
