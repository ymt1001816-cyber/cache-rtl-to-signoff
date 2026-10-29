`timescale 1ns/1ps

// tb_cache.v
// Self-checking testbench for cache_top
// Author: Meiyu Kuo

module tb_cache;
    parameter LINES = 64;                 // cache size = LINES x 16 bytes (override with -P)

    // Inputs to the cache (driven by the testbench)
    reg         clk, rst_n;
    reg  [15:0] cpu_addr;
    reg  [31:0] cpu_wdata;
    reg         cpu_rd, cpu_wr;
    reg  [31:0] mem_rdata;
    reg         mem_ack;

    // Outputs from the cache
    wire [31:0] cpu_rdata;
    wire        cpu_ready;
    wire [13:0] mem_addr;
    wire [31:0] mem_wdata;
    wire        mem_rd, mem_wr;

    // Device under test (DUT)
    cache_top #(.LINES(LINES)) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .cpu_addr  (cpu_addr),
        .cpu_wdata (cpu_wdata),
        .cpu_rd    (cpu_rd),
        .cpu_wr    (cpu_wr),
        .cpu_rdata (cpu_rdata),
        .cpu_ready (cpu_ready),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_rd    (mem_rd),
        .mem_wr    (mem_wr),
        .mem_rdata (mem_rdata),
        .mem_ack   (mem_ack)
    );

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Main memory model (golden reference)
    localparam MEM_LAT = 2;            // cycles before mem_ack
    reg [31:0] mem [0:16383];          // 16K words
    integer    wait_cnt;
    integer    i;

    // Reference model: updated only by the testbench
    reg [31:0] ref_mem [0:16383];
    integer    pass_cnt, fail_cnt;

    initial begin
        for (i = 0; i < 16384; i = i + 1) begin
            mem[i] = 32'hA000_0000 + i; // known pattern: easy to spot wrong address
            ref_mem[i] = 32'hA000_0000 + i; // same initial pattern as main memory
        end
        mem_ack   = 0;
        mem_rdata = 0;
        wait_cnt  = 0;
    end

    always @(posedge clk) begin
        mem_ack <= 1'b0;                           // ack lasts only one cycle
        if ((mem_rd || mem_wr) && !mem_ack) begin
            if (wait_cnt == MEM_LAT-1) begin       // waited long enough
                mem_ack  <= 1'b1;
                wait_cnt <= 0;
                if (mem_rd) mem_rdata     <= mem[mem_addr];
                if (mem_wr) mem[mem_addr] <= mem_wdata;
            end else
                wait_cnt <= wait_cnt + 1;
        end
    end

    // Count memory reads (one per refilled word)
    integer mem_reads;
    initial mem_reads = 0;
    always @(posedge clk)
        if (mem_rd && mem_ack) mem_reads <= mem_reads + 1;

    // Count CPU reads (for hit rate)
    integer read_cnt;
    initial read_cnt = 0;

    // Cycle counter and total read latency (for AMAT)
    integer cycle, read_cycles;
    initial begin cycle = 0; read_cycles = 0; end
    always @(posedge clk) cycle <= cycle + 1;

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
    end

    // CPU read: send a request, wait for cpu_ready, check the data
    task cpu_read(input [15:0] addr);
        integer t0;
        begin
            @(negedge clk);
            cpu_addr = addr;
            cpu_rd   = 1'b1;
            cpu_wr   = 1'b0;
            read_cnt = read_cnt + 1;
            t0 = cycle;
            @(negedge clk);
            while (!cpu_ready) @(negedge clk);      // wait until the cache is ready
            read_cycles = read_cycles + (cycle - t0) + 1;
            if (cpu_rdata !== ref_mem[addr[15:2]]) begin
                fail_cnt = fail_cnt + 1;
                $display("FAIL read  addr=%h got=%h expected=%h", addr, cpu_rdata, ref_mem[addr[15:2]]);
            end else
                pass_cnt = pass_cnt + 1;
            @(posedge clk);                         // cache finishes this request
            @(negedge clk) cpu_rd = 1'b0;           // drop the request
        end
    endtask

    // CPU write: send a request, wait for cpu_ready, update the reference
    task cpu_write(input [15:0] addr, input [31:0] data);
        begin
            @(negedge clk);
            cpu_addr  = addr;
            cpu_wdata = data;
            cpu_wr    = 1'b1;
            cpu_rd    = 1'b0;
            @(negedge clk);
            while (!cpu_ready) @(negedge clk);      // wait until memory write is done
            ref_mem[addr[15:2]] = data;             // reference follows the CPU write
            @(posedge clk);
            @(negedge clk) cpu_wr = 1'b0;
        end
    endtask

    // Statistics for one workload: call stats_start, run accesses, then stats_print
    integer s_reads, s_mem, s_cyc;
    task stats_start;
        begin
            s_reads = read_cnt;
            s_mem   = mem_reads;
            s_cyc   = read_cycles;
        end
    endtask

    task stats_print(input [8*24-1:0] name);
        integer r, m, hr, c, amat;
        begin
            r  = read_cnt - s_reads;
            m  = (mem_reads - s_mem) / 4;
            c  = read_cycles - s_cyc;
            if (r > 0) begin
                hr = (r - m) * 1000 / r;
                amat = c * 100 / r;
                $display("%0s: reads=%0d misses=%0d hit rate=%0d.%0d%% AMAT=%0d.%02d cycles",
                         name, r, m, hr/10, hr%10, amat/100, amat%100);
            end else
                $display("%0s: reads=0 misses=%0d hit rate=N/A AMAT=N/A", name, m);
        end
    endtask

    // Reset the cache so every workload starts cold
    task cache_reset;
        begin
            @(negedge clk) rst_n = 1'b0;
            repeat (2) @(posedge clk);
            @(negedge clk) rst_n = 1'b1;
        end
    endtask

    // W1 / W2: read bytes starting at base, word by word, passes times
    task wl_loop(input [15:0] base, input integer bytes, input integer passes);
        integer p, a;
        begin
            for (p = 0; p < passes; p = p + 1)
                for (a = 0; a < bytes; a = a + 4)
                    cpu_read(base + a);
        end
    endtask

    // W3: alternate between two addresses that are stride bytes apart
    task wl_stride(input [15:0] base, input integer stride, input integer rounds);
        integer k;
        begin
            for (k = 0; k < rounds; k = k + 1) begin
                cpu_read(base);
                cpu_read(base + stride);
            end
        end
    endtask

    // W4: 80% hot 256-byte region, 20% random in 0x0000-0x3FFC
    task wl_hot(input integer count);
        integer k;
        reg [15:0] a;
        begin
            for (k = 0; k < count; k = k + 1) begin
                if ({$random} % 10 < 8)
                    a = 16'h4000 + ({$random} % 256);
                else
                    a = {$random} % 16'h4000;
                a[1:0] = 2'b00;
                cpu_read(a);
            end
        end
    endtask

    // Test sequence
    initial begin
        cpu_addr = 0; cpu_wdata = 0; cpu_rd = 0; cpu_wr = 0;
        rst_n = 1'b0;                          // hold reset
        repeat (3) @(posedge clk);
        rst_n = 1'b1;                          // release reset

        // Test 1: cold miss, then hits in the same block
        stats_start;
        cpu_read(16'h1A34);                    // miss: refill line 35
        cpu_read(16'h1A30);                    // hit
        cpu_read(16'h1A38);                    // hit
        cpu_read(16'h1A3C);                    // hit
        stats_print("Test1 same block");

        // Test 2: conflict - same index, different tags evict each other
        cpu_read(16'h0034);                    // miss: line 3, tag 0
        cpu_read(16'h0434);                    // miss: line 3, tag 1 (evicts tag 0)
        cpu_read(16'h0034);                    // miss again: tag 0 was evicted

        // Test 3: write hit - cache and memory both updated
        cpu_write(16'h1A34, 32'hDEAD_BEEF);     // line 35 is in the cache
        cpu_read(16'h1A34);                    // must read the new value

        // Test 4: write miss - memory only, no allocate
        i = mem_reads;                         // remember the read count
        cpu_write(16'h2000, 32'hCAFE_F00D);     // not in the cache
        if (mem_reads !== i) begin
            fail_cnt = fail_cnt + 1;
            $display("FAIL write miss allocated a line");
        end
        cpu_read(16'h2000);                    // miss: refill must read CAFEF00D

        // Test 5: reset invalidates every line
        cpu_read(16'h1A30);                    // line 35 is valid now
        rst_n = 1'b0;                          // reset again
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        i = mem_reads;
        cpu_read(16'h1A30);                    // must miss after reset
        if (mem_reads === i) begin             // unchanged count means an incorrect hit
            fail_cnt = fail_cnt + 1;
            $display("FAIL reset did not invalidate the cache");
        end

        // Test 6: random reads and writes in a small address range
        repeat (10000) begin
            cpu_addr = {$random} % 16'h0800;   // 0x0000 to 0x07FF
            cpu_addr[1:0] = 2'b00;             // word aligned
            if ({$random} % 2)
                cpu_write(cpu_addr, $random);
            else
                cpu_read(cpu_addr);
        end

        // ---- Performance workloads (hit rate) ----
        cache_reset; stats_start; wl_loop(16'h8000, 512, 2); stats_print("W1 scan 512B x2");
        cache_reset; stats_start; wl_loop(16'h8000, 768, 8); stats_print("W2 loop 768B x8");
        cache_reset; stats_start; wl_stride(16'h9000, 1024, 100); stats_print("W3 stride 1KB");
        cache_reset; stats_start; wl_hot(2000); stats_print("W4 hot 80/20");

        $display("PASS = %0d, FAIL = %0d", pass_cnt, fail_cnt);
        $finish;
    end

endmodule
