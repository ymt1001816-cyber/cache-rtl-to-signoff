// tb_axil_cache.sv : directed-random test of axil_cache (AXI4-Lite slave wrapper around cache_top)
//   AXI master: writes send AW and W in random order (AW first, W first, or together), random bready / rready delays
//   Scoreboard: every read is compared with a reference memory
//   Protocol checks on the slave's outputs: bvalid / rvalid stay high (and their payload stays stable) until accepted,
//   no write response before both AW and W were accepted, no read data without an accepted read address
// run: iverilog -g2012 -o sim ../rtl/cache_top.v axil_cache.v tb_axil_cache.sv && vvp -n sim
`timescale 1ns/1ps
module tb_axil_cache;
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

    axil_cache dut (.clk(clk), .rst_n(rst_n),
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

    // ---- protocol checks on the slave outputs ----
    integer viol = 0, aw_acc = 0, w_acc = 0, b_acc = 0, ar_acc = 0, r_acc = 0;
    reg prev_bvalid = 0, prev_bready = 0, prev_rvalid = 0, prev_rready = 0;
    reg [1:0] prev_bresp; reg [31:0] prev_rdata;
    always @(posedge clk) if (rst_n) begin
        if (prev_bvalid && !prev_bready && (!bvalid || bresp !== prev_bresp)) begin
            viol = viol + 1; $display("PROTOCOL %0t: bvalid dropped or bresp changed before bready", $time); end
        if (prev_rvalid && !prev_rready && (!rvalid || rdata !== prev_rdata)) begin
            viol = viol + 1; $display("PROTOCOL %0t: rvalid dropped or rdata changed before rready", $time); end
        if (bvalid && (b_acc >= aw_acc || b_acc >= w_acc)) begin
            viol = viol + 1; $display("PROTOCOL %0t: bvalid before both AW and W were accepted", $time); end
        if (rvalid && r_acc >= ar_acc) begin
            viol = viol + 1; $display("PROTOCOL %0t: rvalid without an accepted read address", $time); end
        if (awvalid && awready) aw_acc = aw_acc + 1;
        if (wvalid  && wready)  w_acc  = w_acc + 1;
        if (bvalid  && bready)  b_acc  = b_acc + 1;
        if (arvalid && arready) ar_acc = ar_acc + 1;
        if (rvalid  && rready)  r_acc  = r_acc + 1;
        prev_bvalid = bvalid; prev_bready = bready; prev_bresp = bresp;
        prev_rvalid = rvalid; prev_rready = rready; prev_rdata = rdata;
    end

    // ---- AXI master tasks (inputs change at negedge) ----
    integer pass_cnt = 0, fail_cnt = 0, timeouts = 0, t;
    task wait_or_timeout(input string what);
        begin t = t + 1; if (t > 300) begin timeouts = timeouts + 1; $display("TIMEOUT waiting for %s", what); end end
    endtask
    task axi_write(input [15:0] a, input [31:0] d);
        reg aw_done, w_done; integer order, gap;
        begin
            order = $urandom % 3; gap = $urandom % 3; aw_done = 0; w_done = 0; t = 0;
            @(negedge clk);
            if (order != 1) begin awvalid = 1; awaddr = a; end          // AW first or together
            if (order != 0) begin wvalid = 1; wdata = d; end            // W first or together
            while (!(aw_done && w_done) && t <= 300) begin
                @(posedge clk);
                if (awvalid && awready) aw_done = 1;
                if (wvalid && wready) w_done = 1;
                @(negedge clk);
                if (aw_done) awvalid = 0;
                if (w_done) wvalid = 0;
                if (order == 0 && !wvalid && !w_done && (gap-- <= 0)) begin wvalid = 1; wdata = d; end
                if (order == 1 && !awvalid && !aw_done && (gap-- <= 0)) begin awvalid = 1; awaddr = a; end
                wait_or_timeout("AW/W");
            end
            t = 0;                                                       // wait for bvalid first, THEN delay bready:
            while (!bvalid && t <= 300) begin @(negedge clk); wait_or_timeout("B"); end
            repeat ($urandom % 4) @(negedge clk);                        // the slave must hold bvalid meanwhile
            bready = 1; @(negedge clk); bready = 0;
            ref_mem[a[15:2]] = d;
        end
    endtask
    task axi_read(input [15:0] a);
        integer d0;
        begin
            t = 0;
            @(negedge clk); arvalid = 1; araddr = a;
            while (t <= 300) begin @(posedge clk); if (arready) break; @(negedge clk); wait_or_timeout("AR"); end
            @(negedge clk); arvalid = 0;
            t = 0;                                                       // wait for rvalid first, THEN delay rready:
            while (!rvalid && t <= 300) begin @(negedge clk); wait_or_timeout("R"); end
            repeat ($urandom % 4) @(negedge clk);                        // the slave must hold rvalid and rdata meanwhile
            rready = 1;
            if (rdata === ref_mem[a[15:2]]) pass_cnt = pass_cnt + 1;
            else begin fail_cnt = fail_cnt + 1;
                if (fail_cnt <= 5) $display("FAIL read %h: got %h expected %h", a, rdata, ref_mem[a[15:2]]); end
            @(negedge clk); rready = 0;
        end
    endtask

    // ---- test ----
    integer n; reg [15:0] a;
    initial begin
        repeat (3) @(posedge clk); rst_n = 1;
        axi_read(16'h0000); axi_write(16'h0004, 32'h1234_5678); axi_read(16'h0004);   // directed: miss, write hit, read
        axi_write(16'h4404, 32'hCAFE_0001); axi_read(16'h4404);                       // write miss, then read
        for (n = 0; n < 3000 && timeouts == 0; n = n + 1) begin
            a = (($urandom % 8) << 10) | (($urandom % 64) << 4) | (($urandom % 4) << 2);  // 8 tags x 64 lines x 4 words: hits and conflicts
            if ($urandom % 3 == 0) axi_write(a, $urandom); else axi_read(a);
        end
        $display("AXI-LITE: PASS %0d, FAIL %0d, timeouts %0d", pass_cnt, fail_cnt, timeouts);
        $display("protocol violations: %0d", viol);
        if (fail_cnt == 0 && timeouts == 0 && viol == 0 && pass_cnt > 1000) $display("ALL CHECKS PASSED");
        else $display("*** TEST FAILED ***");
        $finish;
    end
endmodule
