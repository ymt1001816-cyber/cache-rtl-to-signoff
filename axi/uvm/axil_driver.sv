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
    vif.awvalid <= 0;
    vif.wvalid <= 0;
    vif.bready <= 0;
    vif.arvalid <= 0;
    vif.rready <= 0;
    vif.awaddr <= 0;
    vif.wdata <= 0;
    vif.araddr <= 0;
    vif.wstrb <= 4'hf;
    forever begin
      seq_item_port.get_next_item(req);
      wait (vif.rst_n === 1'b1);
      if (req.is_write) axi_write(req); else axi_read(req);
      seq_item_port.item_done();
    end
  endtask

  task axi_read(cache_item it);
    @(negedge vif.clk);
    vif.arvalid <= 1;
    vif.araddr <= {it.csr, it.addr};
    do @(posedge vif.clk); while (!vif.arready);
    @(negedge vif.clk);
    vif.arvalid <= 0;
    while (!vif.rvalid) @(negedge vif.clk);
    repeat ($urandom_range(0, 3)) @(negedge vif.clk);
    vif.rready <= 1;
    it.rdata = vif.rdata;
    it.resp = vif.rresp;
    @(negedge vif.clk);
    vif.rready <= 0;
  endtask

  task axi_write(cache_item it);
    int order;
    bit aw_done, w_done;
    order = $urandom_range(0, 2);
    aw_done = 0;
    w_done = 0;
    @(negedge vif.clk);
    vif.awaddr <= {it.csr, it.addr};
    vif.wdata <= it.wdata;
    vif.wstrb <= 4'hf;
    vif.awvalid <= (order != 1);
    vif.wvalid <= (order != 0);
    while (!(aw_done && w_done)) begin
      @(posedge vif.clk);
      if (vif.awvalid && vif.awready) aw_done = 1;
      if (vif.wvalid && vif.wready) w_done = 1;
      @(negedge vif.clk);
      // A completed channel drops VALID; the other starts or keeps waiting.
      vif.awvalid <= !aw_done;
      vif.wvalid <= !w_done;
    end
    while (!vif.bvalid) @(negedge vif.clk);
    repeat ($urandom_range(0, 3)) @(negedge vif.clk);
    vif.bready <= 1;
    it.resp = vif.bresp;
    @(negedge vif.clk);
    vif.bready <= 0;
  endtask
endclass
