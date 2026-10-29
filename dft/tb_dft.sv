// tb_dft.sv : test-mode checks of cache_top_dft
//   1. test_en: a gated clock is off while nothing is written, and always on with test_en = 1
//   2. MBIST on the real data array: March C- passes
//   3. planted defect: the clock gate of word 37 stuck off (gclk[37] = 0) -> MBIST must fail
// run: iverilog -g2012 -o sim cache_top_dft.v clk_gate_te.v mbist_march.v tb_dft.sv && vvp -n sim
`timescale 1ns/1ps
module tb_dft;
    reg clk = 0, rst_n = 0, test_en = 0, test_mode = 0, mbist_start = 0;
    always #5 clk = ~clk;
    wire [31:0] cpu_rdata, mem_wdata; wire [13:0] mem_addr; wire cpu_ready, mem_rd, mem_wr, done, fail;
    cache_top_dft dut (.clk(clk), .rst_n(rst_n), .cpu_addr(16'h0), .cpu_wdata(32'h0), .cpu_rd(1'b0), .cpu_wr(1'b0),
        .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rd(mem_rd),
        .mem_wr(mem_wr), .mem_rdata(32'h0), .mem_ack(1'b0),
        .test_en(test_en), .test_mode(test_mode), .mbist_start(mbist_start), .mbist_done(done), .mbist_fail(fail));

    integer edges, errors = 0, cyc;
    always @(posedge dut.gclk[100]) edges = edges + 1;

    task run_mbist(output integer cycles);
        begin
            test_mode = 1;
            @(negedge clk) mbist_start = 1; @(negedge clk) mbist_start = 0;
            cycles = 0;
            while (!done && !fail && cycles < 5000) begin @(posedge clk); cycles = cycles + 1; end
            repeat (2) @(posedge clk);
            test_mode = 0;
        end
    endtask

    initial begin
        repeat (3) @(posedge clk); @(negedge clk) rst_n = 1;
        // 1. test_en
        edges = 0; repeat (10) @(posedge clk);
        if (edges == 0) $display("PASS  gated clock off while idle (0 edges in 10 cycles)");
        else begin $display("FAIL  gated clock toggles while idle: %0d edges", edges); errors = errors + 1; end
        @(negedge clk) test_en = 1; edges = 0; repeat (10) @(posedge clk); @(negedge clk) test_en = 0;
        if (edges >= 9) $display("PASS  test_en = 1 opens the clock gate (%0d edges in 10 cycles)", edges);
        else begin $display("FAIL  test_en = 1 does not open the clock gate: %0d edges", edges); errors = errors + 1; end
        // 2. MBIST, fault-free
        run_mbist(cyc);
        if (done && !fail) $display("PASS  MBIST on the data array: done after %0d cycles, no fail", cyc);
        else begin $display("FAIL  MBIST fault-free: done=%0d fail=%0d after %0d cycles", done, fail, cyc); errors = errors + 1; end
        // 3. MBIST with the clock gate of word 37 stuck off
        force dut.gclk[37] = 1'b0;
        run_mbist(cyc);
        release dut.gclk[37];
        if (fail) $display("PASS  MBIST finds the stuck-off clock gate of word 37 (fail after %0d cycles)", cyc);
        else begin $display("FAIL  MBIST missed the stuck-off clock gate"); errors = errors + 1; end
        if (errors) $display("*** %0d FAILED ***", errors); else $display("ALL DFT CHECKS PASSED");
        $finish;
    end
endmodule
