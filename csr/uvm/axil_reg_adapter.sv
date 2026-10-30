// axil_reg_adapter.sv : converts RAL register operations to / from cache_item (the AXI agent's transaction)
class axil_reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(axil_reg_adapter)
  function new(string name = "axil_reg_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses   = 0;    // the driver fills rdata / resp into the same item before item_done
  endfunction
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    cache_item it = cache_item::type_id::create("it");
    it.csr = rw.addr[16];
    it.addr = rw.addr[15:0];
    it.is_write = (rw.kind == UVM_WRITE);
    it.wdata = rw.data;
    return it;
  endfunction
  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    cache_item it;
    if (!$cast(it, bus_item)) `uvm_fatal("ADAPT", "bus2reg: not a cache_item")
    rw.kind = it.is_write ? UVM_WRITE : UVM_READ;
    rw.addr = {it.csr, it.addr};
    rw.data = it.is_write ? it.wdata : it.rdata;
    rw.status = (it.resp == 2'b00) ? UVM_IS_OK : UVM_NOT_OK;
  endfunction
endclass
