// mem_responder.sv : plays the main memory. Answers the cache's mem_rd / mem_wr requests.
// Same behavior as the memory model in tb/tb_cache.v:
//   - 16K words, word i starts as 32'hA000_0000 + i
//   - a request waits MEM_LAT cycles, then mem_ack = 1 for one cycle
//   - read: mem_rdata <= mem[mem_addr];  write: mem[mem_addr] <= mem_wdata
class mem_responder extends uvm_component;
  `uvm_component_utils(mem_responder)

  virtual cache_if vif;
  localparam int MEM_LAT = 2;        // cycles before mem_ack (same as tb_cache.v)
  bit [31:0] mem [0:16383];          // 16K words
  int        wait_cnt;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cache_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "mem_responder: no virtual interface 'vif' in config_db")
    for (int i = 0; i < 16384; i++)
      mem[i] = 32'hA000_0000 + i;
  endfunction

  task run_phase(uvm_phase phase);
    vif.mem_ack   <= 0;
    vif.mem_rdata <= 0;
    wait_cnt = 0;
    forever begin
      @(posedge vif.clk);
      vif.mem_ack <= 1'b0; // acknowledge for one cycle, then leave a gap
      if ((vif.mem_rd || vif.mem_wr) && !vif.mem_ack) begin
        if (wait_cnt == MEM_LAT-1) begin
          vif.mem_ack <= 1'b1;
          wait_cnt = 0;
          if (vif.mem_rd) vif.mem_rdata <= mem[vif.mem_addr];
          if (vif.mem_wr) mem[vif.mem_addr] = vif.mem_wdata;
        end else
          wait_cnt = wait_cnt + 1;
      end
    end
  endtask

endclass
