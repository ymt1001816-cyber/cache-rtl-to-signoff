`timescale 1ns/1ps

// clk_gate_te.v : clk_gate.v + test enable, like an industry ICG cell (TE / SE pin)
//   test_en = 1 (scan mode): the clock is always on, so the scan chain can shift through every flip-flop
//   gclk = clk only in cycles where en was 1 before the rising edge; no glitch because
//   the latch holds en while clk is high
module clk_gate_te (
    input  clk,   // free-running clock
    input  en,    // 1 = let the next clock edge through
    input  test_en, // 1 = clock always on (scan / test mode)
    output gclk   // gated clock
);
    reg en_l;
    always @(*) if (!clk) en_l <= en | test_en; // both enables are held throughout the high phase
    assign gclk = clk & en_l;
endmodule
