`timescale 1ns/1ps

// clk_gate.v : latch-based clock gate (OSU gscl45nm has no integrated clock-gating cell)
//   gclk = clk only in cycles where en was 1 before the rising edge; no glitch because
//   the latch holds en while clk is high
module clk_gate (
    input  clk,   // free-running clock
    input  en,    // 1 = let the next clock edge through
    output gclk   // gated clock
);
    reg en_l;
    always @(*) if (!clk) en_l <= en; // hold enable throughout the high phase to avoid glitches
    assign gclk = clk & en_l;
endmodule
