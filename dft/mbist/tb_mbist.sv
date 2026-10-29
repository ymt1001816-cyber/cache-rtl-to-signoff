// tb_mbist.sv : runs mbist_march on mem_fault once fault-free and once per injected fault
//   expected: fault-free -> done, no fail;  every fault -> fail.   Prints the cycle count of each run.
// run: xrun -sv mem_fault.sv mbist_march.v tb_mbist.sv
`timescale 1ns/1ps
module tb_mbist;
    localparam AW = 8, DW = 32;
    reg clk = 0, rst_n = 0, start = 0;
    wire done, fail, we;
    wire [AW-1:0] addr;
    wire [DW-1:0] wdata, rdata;
    always #5 clk = ~clk;

    mbist_march #(AW, DW) dut (.clk(clk), .rst_n(rst_n), .start(start), .done(done), .fail(fail),
                               .mem_we(we), .mem_addr(addr), .mem_wdata(wdata), .mem_rdata(rdata));
    mem_fault   #(AW, DW) mem (.clk(clk), .we(we), .addr(addr), .wdata(wdata), .rdata(rdata));

    string name [0:5] = '{"fault-free", "stuck-at-0", "stuck-at-1", "transition", "coupling", "address decoder"};
    integer f, cycles, errors = 0;
    initial begin
        for (f = 0; f <= 5; f = f + 1) begin
            mem.FAULT = f;
            rst_n = 0; repeat (2) @(posedge clk); rst_n = 1;
            @(negedge clk) start = 1; @(negedge clk) start = 0;
            cycles = 0;
            while (!done && !(f != 0 && fail) && cycles < 20000) begin @(posedge clk); cycles = cycles + 1; end
            if (f == 0 ? (done && !fail) : fail)
                $display("PASS  %-16s done=%0d fail=%0d after %0d cycles", name[f], done, fail, cycles);
            else begin
                $display("FAIL  %-16s done=%0d fail=%0d after %0d cycles", name[f], done, fail, cycles);
                errors = errors + 1;
            end
        end
        if (errors) $display("*** %0d FAILED ***", errors);
        else        $display("ALL 6 PASSED");
        $finish;
    end
endmodule
