// axil_driver.sv : AXI4-Lite master driver. Turns each cache_item into one AXI transaction.
//   write: AW (addr) and W (data, wstrb = 4'hf) in a RANDOM order (AW first / W first / same cycle), then wait for B
//   read : AR (addr), then wait for R
//   bready / rready: raise them a random 0-3 cycles AFTER bvalid / rvalid (tests that the slave holds its response)
// Drive at negedges; a handshake happens at the posedge where VALID && READY.
// Rule: once VALID is 1, keep it (and the payload) until the handshake.
class axil_driver extends uvm_driver #(cache_item);
  `uvm_component_utils(axil_driver)

  virtual axil_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axil_if)::get(this, "", "axi_vif", vif))
      `uvm_fatal("NOVIF", "axil_driver: no virtual interface 'axi_vif' in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    // TODO: set every master output (awvalid, wvalid, bready, arvalid, rready, addresses, data, wstrb) to 0
    forever begin
      seq_item_port.get_next_item(req);
      if (req.is_write) axi_write(req); else axi_read(req);
      seq_item_port.item_done();
    end
  endtask

  // TODO: task axi_write(cache_item it);
  //   pick the AW/W order with $urandom_range(0, 2)
  //   loop at negedges until both AW and W were accepted (check awvalid && awready at the posedge in between)
  //   wait for bvalid, wait $urandom_range(0, 3) cycles, pulse bready for one cycle
  // TODO: task axi_read(cache_item it);
  //   arvalid + araddr until arready, then wait for rvalid, random delay, pulse rready
endclass
