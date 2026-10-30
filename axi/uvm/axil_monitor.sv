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

  task run_phase(uvm_phase phase);
    bit [31:0] aw_addr, w_data, ar_addr;
    bit rd_pending = 0;
    bit saw_mem_rd = 0;
    cache_item it;
    forever begin
      @(posedge vif.clk);
      if (!vif.rst_n) begin
        rd_pending = 0;
        saw_mem_rd = 0;
        aw_addr = 0;
        w_data = 0;
        ar_addr = 0;
        continue;
      end
      if (rd_pending && cvif.mem_rd) saw_mem_rd = 1;
      if (vif.awvalid && vif.awready) aw_addr = vif.awaddr;
      if (vif.wvalid && vif.wready) w_data = vif.wdata;
      if (vif.arvalid && vif.arready) begin
        ar_addr = vif.araddr;
        rd_pending = 1;
        saw_mem_rd = 0;
      end
      if (vif.rvalid && vif.rready) begin
        it = cache_item::type_id::create("it");
        it.is_write = 0;
        it.addr = ar_addr[15:0];
        it.rdata = vif.rdata;
        it.hit = !saw_mem_rd;
        if (!ar_addr[16]) ap.write(it);
        rd_pending = 0;
        saw_mem_rd = 0;
      end
      if (vif.bvalid && vif.bready) begin
        it = cache_item::type_id::create("it");
        it.is_write = 1;
        it.addr = aw_addr[15:0];
        it.wdata = w_data;
        if (!aw_addr[16]) ap.write(it);
      end
    end
  endtask
endclass
