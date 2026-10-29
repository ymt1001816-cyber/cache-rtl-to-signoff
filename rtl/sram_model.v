`timescale 1ns/1ps

// sram_model.v
// Behavioral single-port SRAM (stand-in for the OpenRAM macro)
// Author: Meiyu Kuo
//
// Spec
//   csb0 = 0 : chip selected (active low)
//   web0 = 0 : write, web0 = 1 : read (active low)
//   write : at posedge, mem[addr0] <= din0
//   read  : at posedge, dout0 <= mem[addr0]  (data visible in the NEXT cycle)

module sram_model #(
    parameter ADDR_W = 8,    // 256 words
    parameter DATA_W = 32    // 32-bit words
) (
    input  wire              clk0,   // clock
    input  wire              csb0,   // chip select (active low)
    input  wire              web0,   // write enable (active low)
    input  wire [ADDR_W-1:0] addr0,  // word address
    input  wire [DATA_W-1:0] din0,   // write data
    output reg  [DATA_W-1:0] dout0   // read data (registered)
);

    reg [DATA_W-1:0] mem [0:2**ADDR_W-1]; // 2^ADDR_W words, each holding DATA_W bits

    always @(posedge clk0) begin
        if (!csb0 && !web0)
            mem[addr0] <= din0; // selected write updates only the addressed word
        if (!csb0 && web0)
            dout0 <= mem[addr0]; // synchronous read becomes visible after this edge, for the following cycle
    end

endmodule
