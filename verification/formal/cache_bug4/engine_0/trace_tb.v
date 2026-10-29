`ifndef VERILATOR
module testbench;
  reg [4095:0] vcdfile;
  reg clock;
`else
module testbench(input clock, output reg genclock);
  initial genclock = 1;
`endif
  reg genclock = 1;
  reg [31:0] cycle = 0;
  wire [0:0] PI_clk = clock;
  cache_formal UUT (
    .clk(PI_clk)
  );
`ifndef VERILATOR
  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end
    #5 clock = 0;
    while (genclock) begin
      #5 clock = 0;
      #5 clock = 1;
    end
  end
`endif
  initial begin
`ifndef VERILATOR
    #1;
`endif
    UUT._witness_.anyinit_procdff_358 = 1'b0;
    UUT._witness_.anyinit_procdff_359 = 1'b0;
    UUT._witness_.anyinit_procdff_360 = 1'b1;
    UUT._witness_.anyinit_procdff_361 = 1'b1;
    UUT._witness_.anyinit_procdff_362 = 16'b1000000000000000;
    UUT._witness_.anyinit_procdff_363 = 32'b10000000000000000000000000000000;
    UUT.dut._witness_.anyinit_procdff_335 = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    UUT.dut._witness_.anyinit_procdff_340 = 2'b00;
    UUT.dut._witness_.anyinit_procdff_345 = 2'b00;
    UUT.f_cyc = 2'b00;
    UUT.f_mem_wait = 4'b0000;
    UUT.f_wait = 6'b000000;
    UUT.dut.data_arr[8'b01010100] = 32'b00000000000000000000000000000000;
    UUT.dut.data_arr[8'b10110000] = 32'b00000000000000000000000000000000;
    UUT.dut.data_arr[8'b11111100] = 32'b00000000000000000000000000000000;
    UUT.dut.tag_arr[6'b010101] = 6'b011110;
    UUT.dut.tag_arr[6'b101100] = 6'b100100;
    UUT.dut.tag_arr[6'b111111] = 6'b011010;

    // state 0
    UUT.cpu_rd = 1'b0;
    UUT.cpu_wdata = 32'b00000000000000000000000000000000;
    UUT.cpu_wr = 1'b0;
    UUT.mem_ack = 1'b0;
    UUT.mem_rdata = 32'b00000000000000000000000000000000;
    UUT.rst_n = 1'b0;
    UUT.cpu_addr = 16'b0000000101010000;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      UUT.cpu_rd <= 1'b0;
      UUT.cpu_wdata <= 32'b10000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b0;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b0;
      UUT.cpu_addr <= 16'b1000001011000000;
    end

    // state 2
    if (cycle == 1) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b0;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 3
    if (cycle == 2) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b0;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 4
    if (cycle == 3) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 5
    if (cycle == 4) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 6
    if (cycle == 5) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 7
    if (cycle == 6) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b0;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 8
    if (cycle == 7) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 9
    if (cycle == 8) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b0;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 10
    if (cycle == 9) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b0;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 11
    if (cycle == 10) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 12
    if (cycle == 11) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b0;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 13
    if (cycle == 12) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 14
    if (cycle == 13) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b0;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 15
    if (cycle == 14) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 16
    if (cycle == 15) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 17
    if (cycle == 16) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 18
    if (cycle == 17) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 19
    if (cycle == 18) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 20
    if (cycle == 19) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 21
    if (cycle == 20) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b0;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    // state 22
    if (cycle == 21) begin
      UUT.cpu_rd <= 1'b1;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b0;
      UUT.mem_ack <= 1'b0;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0111101111110000;
    end

    genclock <= cycle < 22;
    cycle <= cycle + 1;
  end
endmodule
