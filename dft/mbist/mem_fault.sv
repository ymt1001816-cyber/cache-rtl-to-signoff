// mem_fault.sv : 256 x 32 memory with the same read/write timing as data_arr in cache_top
//   write: synchronous (posedge clk, we = 1)     read: combinational (rdata = mem[addr])
// One fault can be injected from the testbench to check that the MBIST controller finds it:
//   FAULT = 0 none, 1 stuck-at-0, 2 stuck-at-1, 3 transition (cell cannot rise 0 -> 1),
//           4 coupling (a rising write to cell AGG flips cell VIC), 5 address decoder (address A2 also writes A1)
module mem_fault #(parameter AW = 8, DW = 32) (
    input               clk,
    input               we,
    input      [AW-1:0] addr,
    input      [DW-1:0] wdata,
    output     [DW-1:0] rdata
);
    reg [DW-1:0] mem [0:(1<<AW)-1];
    integer FAULT = 0;                    // set by the testbench
    integer F_ADDR = 37, F_BIT = 5;       // faulty cell for faults 1-3
    integer AGG = 100, VIC = 101;         // aggressor / victim words for fault 4 (bit F_BIT)
    integer A1 = 12, A2 = 200;            // fault 5: writing A2 also writes A1

    always @(posedge clk) if (we) begin
        if (FAULT == 3 && addr == F_ADDR && !mem[addr][F_BIT] && wdata[F_BIT])
            mem[addr] <= wdata & ~({{(DW-1){1'b0}}, 1'b1} << F_BIT);           // the 0 -> 1 transition fails
        else
            mem[addr] <= wdata;
        if (FAULT == 4 && addr == AGG && !mem[AGG][F_BIT] && wdata[F_BIT])
            mem[VIC][F_BIT] <= ~mem[VIC][F_BIT];                                // coupling: victim flips
        if (FAULT == 5 && addr == A2)
            mem[A1] <= wdata;                                                   // decoder: two words selected
    end

    wire [DW-1:0] raw = mem[addr];
    assign rdata = (FAULT == 1 && addr == F_ADDR) ? raw & ~({{(DW-1){1'b0}}, 1'b1} << F_BIT) :
                   (FAULT == 2 && addr == F_ADDR) ? raw |  ({{(DW-1){1'b0}}, 1'b1} << F_BIT) : raw;
endmodule
