// csr_counter.sv : reference for the hardware counters, built only from what the AXI monitor sees
//   (read hit = no memory read between AR and R). Tests compare it with HIT_CNT / MISS_CNT / WR_CNT.
class csr_counter extends uvm_subscriber #(cache_item);
  `uvm_component_utils(csr_counter)
  int unsigned hits, misses, writes;
  bit enable = 1;                              // mirrors CTRL.cnt_en; the test keeps it in step
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void write(cache_item t);
    if (!enable) return;
    if (t.is_write) writes++;
    else if (t.hit) hits++;
    else misses++;
  endfunction
  function void clear(); hits = 0; misses = 0; writes = 0; endfunction
endclass
