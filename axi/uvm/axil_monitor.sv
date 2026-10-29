// axil_monitor.sv : watches the AXI pins (never drives them) and sends one cache_item per finished transaction
//   read  done = R handshake (rvalid && rready):  addr = the accepted araddr, rdata = rdata
//   write done = B handshake (bvalid && bready):  addr = the accepted awaddr, wdata = the accepted wdata
//   hit (for coverage): a read is a hit if the cache did not read memory (mem_rd) between AR and R.
//     mem_rd is on the memory side, so also get the cache_if handle "vif" (already in config_db).
// Sample at posedges: a transfer happens at the posedge where VALID && READY.
class axil_monitor extends uvm_monitor;
  `uvm_component_utils(axil_monitor)

  virtual axil_if  vif;
  virtual cache_if cvif;                 // memory-side pins (for the hit flag)
  uvm_analysis_port #(cache_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual axil_if)::get(this, "", "axi_vif", vif))
      `uvm_fatal("NOVIF", "axil_monitor: no virtual interface 'axi_vif' in config_db")
    if (!uvm_config_db#(virtual cache_if)::get(this, "", "vif", cvif))
      `uvm_fatal("NOVIF", "axil_monitor: no virtual interface 'vif' in config_db")
  endfunction

  // TODO: run_phase
  //   forever @(posedge vif.clk) if (vif.rst_n):
  //     remember awaddr / wdata / araddr when their handshake happens
  //     while a read is pending, note if cvif.mem_rd was 1
  //     on an R handshake: create a cache_item (is_write = 0, addr, rdata, hit) and ap.write(it)
  //     on a B handshake : create a cache_item (is_write = 1, addr, wdata) and ap.write(it)
endclass
