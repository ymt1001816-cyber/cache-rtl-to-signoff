// cache_item.sv : one CPU request (read or write) = one UVM transaction
// 
class cache_item extends uvm_sequence_item;

  rand bit [15:0] addr;      // CPU byte address
  rand bit [31:0] wdata;     // write data (unused for reads)
  rand bit        is_write;  // 1 = write, 0 = read
       bit [31:0] rdata;     // data read back (filled by the monitor, not random)
  int latency;              // waiting negedges before ready, measured by the monitor
  bit hit;                  // no memory read observed during this request (used for reads)

  constraint c_align { addr[1:0] == 2'b00; } // requests address whole 32-bit words

  `uvm_object_utils(cache_item)

  function new(string name = "cache_item");
    super.new(name);
  endfunction

endclass
