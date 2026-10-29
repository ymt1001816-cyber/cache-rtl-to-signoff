// cpu_monitor.sv : watches the CPU pins (never drives them) and reports each finished request
// When a request finishes (cpu_ready = 1, sampled at a negedge like the old testbench),
// build a cache_item that records what happened and send it out on the analysis port.
class cpu_monitor extends uvm_monitor;
  `uvm_component_utils(cpu_monitor)

  virtual cache_if vif;
  uvm_analysis_port #(cache_item) ap;   // anyone can listen: scoreboard (step 3), coverage (step 5)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual cache_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "cpu_monitor: no virtual interface 'vif' in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    cache_item it;
    int wait_cnt = 0;
    bit saw_mem_rd = 0;
    forever begin
      @(negedge vif.clk);
      // Include this sampling edge before classifying a completed request.
      if (vif.rst_n && (vif.cpu_rd || vif.cpu_wr) && vif.mem_rd)
        saw_mem_rd = 1;
      if (vif.rst_n && vif.cpu_ready && (vif.cpu_rd || vif.cpu_wr)) begin
        it = cache_item::type_id::create("it");
        it.addr     = vif.cpu_addr;
        it.is_write = vif.cpu_wr;
        it.wdata    = vif.cpu_wdata;
        it.rdata    = vif.cpu_rdata;
        it.latency  = wait_cnt;
        it.hit = !saw_mem_rd;
        saw_mem_rd = 0;
        wait_cnt = 0;
        ap.write(it); // publish a fresh transaction without driving any pins
      end else if (!vif.rst_n || !(vif.cpu_rd || vif.cpu_wr)) begin
        wait_cnt = 0;
        saw_mem_rd = 0;
      end else begin
        wait_cnt++;
      end
    end
  endtask

endclass
