// cache_reg_model.sv : UVM register model (RAL) of the CSR block in axil_cache_csr.v
//   one class per register type, one block with the address map (base 0x1_0000, 4-byte registers)
class id_reg extends uvm_reg;
  `uvm_object_utils(id_reg)
  rand uvm_reg_field id;
  function new(string name = "id_reg"); super.new(name, 32, UVM_NO_COVERAGE); endfunction
  virtual function void build();
    id = uvm_reg_field::type_id::create("id");
    //           parent size lsb access volatile reset         has_reset rand individually_accessible
    id.configure(this, 32,  0,  "RO",  0,       32'hCA0E_0001, 1,        0,   1);
  endfunction
endclass

class ctrl_reg extends uvm_reg;
  `uvm_object_utils(ctrl_reg)
  rand uvm_reg_field cnt_en;
  function new(string name = "ctrl_reg"); super.new(name, 32, UVM_NO_COVERAGE); endfunction
  virtual function void build();
    cnt_en = uvm_reg_field::type_id::create("cnt_en");
    cnt_en.configure(this, 1, 0, "RW", 0, 1, 1, 1, 0);
  endfunction
endclass

class cmd_reg extends uvm_reg;
  `uvm_object_utils(cmd_reg)
  rand uvm_reg_field flush, cnt_clr;
  function new(string name = "cmd_reg"); super.new(name, 32, UVM_NO_COVERAGE); endfunction
  virtual function void build();
    flush = uvm_reg_field::type_id::create("flush");
    cnt_clr = uvm_reg_field::type_id::create("cnt_clr");
    flush.configure(this, 1, 0, "WO", 0, 0, 1, 1, 0);
    cnt_clr.configure(this, 1, 1, "WO", 0, 0, 1, 1, 0);
  endfunction
endclass

class cnt_reg extends uvm_reg;               // HIT_CNT, MISS_CNT, WR_CNT
  `uvm_object_utils(cnt_reg)
  rand uvm_reg_field cnt;
  function new(string name = "cnt_reg"); super.new(name, 32, UVM_NO_COVERAGE); endfunction
  virtual function void build();
    cnt = uvm_reg_field::type_id::create("cnt");
    cnt.configure(this, 32, 0, "RO", 1, 0, 1, 0, 1);
  endfunction
endclass

class cache_reg_block extends uvm_reg_block;
  `uvm_object_utils(cache_reg_block)
  rand id_reg   id;
  rand ctrl_reg ctrl;
  rand cmd_reg  cmd;
  rand cnt_reg  hit_cnt, miss_cnt, wr_cnt;
  function new(string name = "cache_reg_block"); super.new(name, UVM_NO_COVERAGE); endfunction
  virtual function void build();
    id       = id_reg  ::type_id::create("id");       id.configure(this);       id.build();
    ctrl     = ctrl_reg::type_id::create("ctrl");     ctrl.configure(this);     ctrl.build();
    cmd      = cmd_reg ::type_id::create("cmd");      cmd.configure(this);      cmd.build();
    hit_cnt  = cnt_reg ::type_id::create("hit_cnt");  hit_cnt.configure(this);  hit_cnt.build();
    miss_cnt = cnt_reg ::type_id::create("miss_cnt"); miss_cnt.configure(this); miss_cnt.build();
    wr_cnt   = cnt_reg ::type_id::create("wr_cnt");   wr_cnt.configure(this);   wr_cnt.build();
    default_map = create_map("map", 'h1_0000, 4, UVM_LITTLE_ENDIAN);
    default_map.add_reg(id,       'h00, "RO");
    default_map.add_reg(ctrl,     'h04, "RW");
    default_map.add_reg(cmd,      'h08, "WO");
    default_map.add_reg(hit_cnt,  'h0C, "RO");
    default_map.add_reg(miss_cnt, 'h10, "RO");
    default_map.add_reg(wr_cnt,   'h14, "RO");

    lock_model();
  endfunction
endclass
