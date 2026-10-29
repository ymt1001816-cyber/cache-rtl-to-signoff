// cpu_driver.sv : takes cache_items from the sequencer and drives them on the CPU pins
// Same timing as cpu_read / cpu_write in tb/tb_cache.v:
//   1. at a negedge: put addr (and wdata), raise cpu_rd or cpu_wr
//   2. wait (at negedges) until cpu_ready = 1
//   3. wait one posedge (the cache finishes the request)
//   4. at the next negedge: drop cpu_rd / cpu_wr
// Checking the read data is NOT the driver's job (the monitor + scoreboard do it in step 3).
class cpu_driver extends uvm_driver #(cache_item);
  `uvm_component_utils(cpu_driver)

  virtual cache_if vif;   // handle to the real pins (set in build_phase)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // get the interface handle that tb_top puts into the config database
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cache_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "cpu_driver: no virtual interface 'vif' in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    vif.cpu_rd    <= 0;
    vif.cpu_wr    <= 0;
    vif.cpu_addr  <= 0;
    vif.cpu_wdata <= 0;

    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  // one CPU request, steps 1-4 from the top of this file
  task drive_item(cache_item it);
    @(negedge vif.clk);
    vif.cpu_addr  <= it.addr;
    vif.cpu_wdata <= it.wdata;
    vif.cpu_rd    <= !it.is_write;
    vif.cpu_wr    <= it.is_write;
    @(negedge vif.clk); // allow the cache to see the new request before checking ready
    while (!vif.cpu_ready) @(negedge vif.clk);
    @(posedge vif.clk); // let the cache complete the acknowledged request
    @(negedge vif.clk);
    vif.cpu_rd <= 0;
    vif.cpu_wr <= 0;
  endtask

endclass
