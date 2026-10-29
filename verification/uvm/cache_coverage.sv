// cache_coverage.sv : functional coverage = which kinds of requests did the test actually send?
// Listens to the monitor (like the scoreboard), counts cases, never checks data.
class cache_coverage extends uvm_subscriber #(cache_item);
  `uvm_component_utils(cache_coverage)

  cache_item it;   // the item being sampled

  covergroup cg;
    cp_op   : coverpoint it.is_write { bins read = {0}; bins write = {1}; }   // example
    cp_index : coverpoint it.addr[9:4];
    cp_word : coverpoint it.addr[3:2];
    x_op_word : cross cp_op, cp_word;
    // Classify reads by memory activity, independently of hit response latency.
    cp_read_hit : coverpoint it.hit iff (!it.is_write) {
      bins hit = {1};
      bins miss = {0};
    }
    x_line_hit : cross cp_index, cp_read_hit;
    cp_align : coverpoint it.addr[1:0] {
      bins ok = {0};
      illegal_bins misaligned = {[1:3]}; // CPU requests must address whole words
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();          // a covergroup must be created in the constructor
  endfunction

  // called for every item the monitor sends
  function void write(cache_item t);
    it = t;
    cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("functional coverage = %0.1f%%", cg.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("  cp_op       %5.1f%%", cg.cp_op.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("  cp_index    %5.1f%%", cg.cp_index.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("  cp_word     %5.1f%%", cg.cp_word.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("  x_op_word   %5.1f%%", cg.x_op_word.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("  cp_read_hit %5.1f%%", cg.cp_read_hit.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("  x_line_hit  %5.1f%%", cg.x_line_hit.get_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("  cp_align    %5.1f%%", cg.cp_align.get_coverage()), UVM_NONE)
  endfunction
endclass
