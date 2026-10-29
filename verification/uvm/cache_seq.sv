// cache_seq.sv : the stimulus. Each sequence = one kind of test (same tests as tb/tb_cache.v)
// 
// ---------------------------------------------------------------------------
// Base sequence: two helper tasks that every other sequence uses
// ---------------------------------------------------------------------------
class cache_base_seq extends uvm_sequence #(cache_item);
  `uvm_object_utils(cache_base_seq)
  function new(string name = "cache_base_seq"); super.new(name); endfunction

  // one read request (example: already written)
  task do_read(bit [15:0] addr);
    cache_item it = cache_item::type_id::create("it");
    start_item(it);              // wait until the driver is ready for a new item
    it.addr     = addr;
    it.is_write = 0;
    finish_item(it);             // hand it to the driver and wait until item_done()
  endtask

  task do_write(bit [15:0] addr, bit [31:0] data);
    cache_item it = cache_item::type_id::create("it");
    start_item(it);
    it.addr     = addr;
    it.wdata    = data;
    it.is_write = 1;
    finish_item(it);
  endtask
endclass

// ---------------------------------------------------------------------------
// Directed: Tests 1-4 from tb_cache.v (Test 5 = reset is done in the test, step 5)
// ---------------------------------------------------------------------------
class cache_directed_seq extends cache_base_seq;
  `uvm_object_utils(cache_directed_seq)
  function new(string name = "cache_directed_seq"); super.new(name); endfunction

  task body();
    // Test 1: cold miss followed by hits in the same block
    do_read(16'h1A34);
    do_read(16'h1A30);
    do_read(16'h1A38);
    do_read(16'h1A3C);
    // Test 2: conflicting blocks evict each other
    do_read(16'h0034);
    do_read(16'h0434);
    do_read(16'h0034);
    // Test 3: write hit must return the updated data
    do_write(16'h1A34, 32'hDEAD_BEEF);
    do_read(16'h1A34);
    // Test 4: read after write miss must observe the memory update
    do_write(16'h2000, 32'hCAFE_F00D);
    do_read(16'h2000);
  endtask
endclass

// ---------------------------------------------------------------------------
// Random: Test 6 = random reads and writes in 0x0000-0x07FF
// ---------------------------------------------------------------------------
class cache_random_seq extends cache_base_seq;
  `uvm_object_utils(cache_random_seq)
  int n = 10000;                 // number of requests (a test can change it)
  function new(string name = "cache_random_seq"); super.new(name); endfunction

  task body();
    repeat (n) begin
      cache_item it = cache_item::type_id::create("it");
      start_item(it);
      if (!it.randomize() with { addr < 16'h0800; })
        `uvm_fatal("RAND", "cache_random_seq: randomize failed")
      finish_item(it);
    end
  endtask
endclass

// ---------------------------------------------------------------------------
// Stride: W3 = alternate between base and base + stride (conflict-miss workload)
// ---------------------------------------------------------------------------
class cache_stride_seq extends cache_base_seq;
  `uvm_object_utils(cache_stride_seq)
  rand bit [15:0] base;
  rand int        stride;
  int             rounds = 100;
  constraint c_stride {
    base[1:0] == 2'b00;
    stride inside {1024, 2048};
  }
  function new(string name = "cache_stride_seq"); super.new(name); endfunction

  task body();
    repeat (rounds) begin
      do_read(base);
      do_read(base + stride);
    end
  endtask
endclass

// ---------------------------------------------------------------------------
// One read (used by cache_reset_test)
// ---------------------------------------------------------------------------
class cache_read_seq extends cache_base_seq;
  bit [15:0] addr;
  `uvm_object_utils(cache_read_seq)

  function new(string name = "cache_read_seq");
    super.new(name);
  endfunction

  task body();
    do_read(addr);
  endtask
endclass

// ---------------------------------------------------------------------------
// biased random = still legal, but rare cases come up more often.
// Uniform random in 0x0000-0x07FF rarely hits the same line twice in a row or two tags on one index.
// ---------------------------------------------------------------------------
class cache_biased_seq extends cache_base_seq;
  `uvm_object_utils(cache_biased_seq)
  int n = 5000;
  bit [15:0] hot = 16'h0030;     // block-aligned hot address inside 0x0000-0x07FF
  function new(string name = "cache_biased_seq"); super.new(name); endfunction

  task body();
    repeat (n) begin
      cache_item it = cache_item::type_id::create("it");
      int kind;
      start_item(it);
      if (!std::randomize(kind) with { kind dist {0 := 40, 1 := 30, 2 := 30}; })
        `uvm_fatal("RAND", "cache_biased_seq: kind randomize failed")
      if (!it.randomize() with {
        addr < 16'h0800;
        is_write dist {1 := 20, 0 := 80};
        (local::kind == 0) -> addr[15:4] == local::hot[15:4];
        (local::kind == 1) -> addr[9:4] == local::hot[9:4];
      })
        `uvm_fatal("RAND", "cache_biased_seq: item randomize failed")
      finish_item(it);
    end
  endtask
endclass
