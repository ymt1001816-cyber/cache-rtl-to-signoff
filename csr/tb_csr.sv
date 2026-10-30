// tb_csr.sv : test of the CSR block in axil_cache_csr (AXI4-Lite master + reference model)
//   1. reset values (ID, CTRL), CMD reads 0, writes to read-only registers are ignored, unmapped offsets -> SLVERR
//   2. random cache traffic: every read checked against a reference memory, and HIT / MISS / WR counters
//      checked against a reference tag model (write-through, no-write-allocate)
//   3. cnt_en = 0 freezes the counters, cnt_clr clears them
//   4. flush: every line that was a hit before the flush is a miss after it (data unchanged)
// run: iverilog -g2012 -o sim cache_top_csr.v axil_cache_csr.v tb_csr.sv && vvp -n sim
`timescale 1ns/1ps
module tb_csr;
    reg clk = 0, rst_n = 0;
    always #5 clk = ~clk;

    reg         awvalid = 0, wvalid = 0, bready = 0, arvalid = 0, rready = 0;
    reg  [31:0] awaddr = 0, wdata = 0, araddr = 0;
    reg  [3:0]  wstrb = 4'hf;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [1:0]  bresp, rresp;
    wire [31:0] rdata;
    wire [13:0] mem_addr;
    wire [31:0] mem_wdata;
    wire        mem_rd, mem_wr;
    reg  [31:0] mem_rdata = 0;
    reg         mem_ack = 0;

    axil_cache_csr dut (.clk(clk), .rst_n(rst_n),
        .awvalid(awvalid), .awready(awready), .awaddr(awaddr),
        .wvalid(wvalid), .wready(wready), .wdata(wdata), .wstrb(wstrb),
        .bvalid(bvalid), .bready(bready), .bresp(bresp),
        .arvalid(arvalid), .arready(arready), .araddr(araddr),
        .rvalid(rvalid), .rready(rready), .rdata(rdata), .rresp(rresp),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rd(mem_rd), .mem_wr(mem_wr),
        .mem_rdata(mem_rdata), .mem_ack(mem_ack));

    // ---- memory model (same as tb/tb_cache.v) ----
    reg [31:0] mem [0:16383], ref_mem [0:16383];
    integer i, wait_cnt = 0;
    initial for (i = 0; i < 16384; i = i + 1) begin mem[i] = 32'hA000_0000 + i; ref_mem[i] = 32'hA000_0000 + i; end
    always @(posedge clk) begin
        mem_ack <= 1'b0;
        if ((mem_rd || mem_wr) && !mem_ack) begin
            if (wait_cnt == 1) begin
                mem_ack <= 1'b1; wait_cnt <= 0;
                if (mem_rd) mem_rdata <= mem[mem_addr];
                if (mem_wr) mem[mem_addr] <= mem_wdata;
            end else wait_cnt <= wait_cnt + 1;
        end
    end

    // ---- reference model: tags and counters ----
    localparam CSR = 32'h1_0000, ID = CSR + 'h00, CTRL = CSR + 'h04, CMD = CSR + 'h08,
               HIT = CSR + 'h0C, MISS = CSR + 'h10, WR = CSR + 'h14;
    reg [6:0] ref_tag [0:63];                  // {valid, tag}
    integer   exp_hit = 0, exp_miss = 0, exp_wr = 0;
    reg       counting = 1;
    initial for (i = 0; i < 64; i = i + 1) ref_tag[i] = 0;

    // ---- AXI master (inputs change at negedge) ----
    integer errors = 0, checks = 0;
    reg [1:0] last_resp;
    reg [31:0] last_rdata;
    task check(input ok, input [8*80-1:0] msg);
        begin checks = checks + 1; if (!ok) begin errors = errors + 1; $display("FAIL %0t: %0s", $time, msg); end end
    endtask
    task axi_write(input [31:0] a, input [31:0] d);
        begin
            @(negedge clk); awvalid = 1; awaddr = a; wvalid = 1; wdata = d;
            @(posedge clk); while (!(awready && wready)) @(posedge clk);
            @(negedge clk); awvalid = 0; wvalid = 0;
            while (!bvalid) @(negedge clk);
            last_resp = bresp; bready = 1; @(negedge clk); bready = 0;
        end
    endtask
    task axi_read(input [31:0] a);
        begin
            @(negedge clk); arvalid = 1; araddr = a;
            @(posedge clk); while (!arready) @(posedge clk);
            @(negedge clk); arvalid = 0;
            while (!rvalid) @(negedge clk);
            last_resp = rresp; last_rdata = rdata; rready = 1; @(negedge clk); rready = 0;
        end
    endtask

    // cache accesses through the model
    task cache_read(input [15:0] a);
        begin
            if (ref_tag[a[9:4]] == {1'b1, a[15:10]}) begin if (counting) exp_hit = exp_hit + 1; end
            else begin if (counting) exp_miss = exp_miss + 1; ref_tag[a[9:4]] = {1'b1, a[15:10]}; end
            axi_read({16'h0, a});
            check(last_rdata === ref_mem[a[15:2]] && last_resp == 2'b00, "cache read data");
        end
    endtask
    task cache_write(input [15:0] a, input [31:0] d);
        begin
            if (counting) exp_wr = exp_wr + 1;     // no-write-allocate: tags unchanged
            axi_write({16'h0, a}, d); ref_mem[a[15:2]] = d;
            check(last_resp == 2'b00, "cache write OKAY");
        end
    endtask
    task check_counters;
        begin
            axi_read(HIT);  check(last_rdata == exp_hit,  "HIT_CNT");
            if (last_rdata != exp_hit)  $display("     HIT_CNT %0d, expected %0d", last_rdata, exp_hit);
            axi_read(MISS); check(last_rdata == exp_miss, "MISS_CNT");
            if (last_rdata != exp_miss) $display("     MISS_CNT %0d, expected %0d", last_rdata, exp_miss);
            axi_read(WR);   check(last_rdata == exp_wr,   "WR_CNT");
            if (last_rdata != exp_wr)   $display("     WR_CNT %0d, expected %0d", last_rdata, exp_wr);
        end
    endtask
    task random_traffic(input integer n);
        integer k; reg [15:0] a;
        for (k = 0; k < n; k = k + 1) begin
            a = (($urandom % 4) << 10) | (($urandom % 64) << 4) | (($urandom % 4) << 2);
            if ($urandom % 4 == 0) cache_write(a, $urandom); else cache_read(a);
        end
    endtask

    initial begin                              // watchdog: a design that never answers fails instead of hanging
        #5_000_000;
        $display("TIMEOUT: no AXI response (%0d checks, %0d errors so far)", checks, errors);
        $display("*** CSR TEST FAILED ***");
        $finish;
    end

    integer k, hits_before;
    initial begin
        repeat (3) @(posedge clk); rst_n = 1;
        // 1. register basics
        axi_read(ID);   check(last_rdata == 32'hCA0E_0001 && last_resp == 2'b00, "ID reset value");
        axi_read(CTRL); check(last_rdata == 32'h1, "CTRL reset value (cnt_en = 1)");
        axi_read(CMD);  check(last_rdata == 0, "CMD reads 0");
        axi_write(ID, 32'hFFFF_FFFF); axi_read(ID); check(last_rdata == 32'hCA0E_0001, "write to ID ignored");
        axi_write(CTRL, 0); axi_read(CTRL); check(last_rdata == 0, "CTRL write 0");
        axi_write(CTRL, 1); axi_read(CTRL); check(last_rdata == 1, "CTRL write 1");
        axi_read(CSR + 'h18); check(last_resp == 2'b10, "unmapped CSR read -> SLVERR");
        axi_write(CSR + 'h40, 0); check(last_resp == 2'b10, "unmapped CSR write -> SLVERR");
        check_counters;                        // all 0
        // 2. counters follow the traffic
        random_traffic(2000); check_counters;
        // 3. cnt_en = 0 freezes, cnt_clr clears
        axi_write(CTRL, 0); counting = 0; random_traffic(200); check_counters;
        axi_write(CMD, 2); exp_hit = 0; exp_miss = 0; exp_wr = 0; check_counters;
        axi_write(CTRL, 1); counting = 1;
        // 4. flush: warm 16 lines, flush, the same reads must all miss and still return the right data
        for (k = 0; k < 16; k = k + 1) cache_read(k << 4);
        hits_before = exp_hit;
        for (k = 0; k < 16; k = k + 1) cache_read(k << 4);
        check(exp_hit == hits_before + 16, "model: warm lines hit before flush");
        axi_write(CMD, 1); for (k = 0; k < 64; k = k + 1) ref_tag[k] = 0;
        for (k = 0; k < 16; k = k + 1) cache_read(k << 4);
        check_counters;
        $display("CSR: %0d checks, %0d errors (hits %0d, misses %0d, writes %0d)", checks, errors, exp_hit, exp_miss, exp_wr);
        if (errors == 0) $display("ALL CSR CHECKS PASSED"); else $display("*** CSR TEST FAILED ***");
        $finish;
    end
endmodule
