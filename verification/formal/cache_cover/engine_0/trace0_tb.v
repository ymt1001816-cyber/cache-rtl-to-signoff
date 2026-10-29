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
    UUT._witness_.anyinit_procdff_356 = 1'b0;
    UUT._witness_.anyinit_procdff_357 = 1'b0;
    UUT._witness_.anyinit_procdff_358 = 1'b1;
    UUT._witness_.anyinit_procdff_359 = 1'b1;
    UUT._witness_.anyinit_procdff_360 = 16'b1000000000000000;
    UUT._witness_.anyinit_procdff_361 = 32'b10000000000000000000000000000000;
    UUT.dut._witness_.anyinit_procdff_333 = 64'b0000000000000000000000000000000000000000000000000000000000000000;
    UUT.dut._witness_.anyinit_procdff_338 = 2'b00;
    UUT.dut._witness_.anyinit_procdff_343 = 2'b00;
    UUT.f_cyc = 2'b00;
    UUT.f_mem_wait = 4'b0000;
    UUT.dut.data_arr[8'b00000000] = 32'b00000000000000000000000000000000;
    UUT.dut.tag_arr[6'b000000] = 6'b110000;

    // state 0
    UUT.cpu_rd = 1'b0;
    UUT.cpu_wdata = 32'b00000000000000000000000000000000;
    UUT.cpu_wr = 1'b0;
    UUT.mem_ack = 1'b0;
    UUT.mem_rdata = 32'b00000000000000000000000000000000;
    UUT.rst_n = 1'b0;
    UUT.cpu_addr = 16'b0000000000000000;
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
      UUT.cpu_addr <= 16'b1000000000000000;
    end

    // state 2
    if (cycle == 1) begin
      UUT.cpu_rd <= 1'b0;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b1;
      UUT.mem_ack <= 1'b0;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0000000000000000;
    end

    // state 3
    if (cycle == 2) begin
      UUT.cpu_rd <= 1'b0;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b1;
      UUT.mem_ack <= 1'b0;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0000000000000000;
    end

    // state 4
    if (cycle == 3) begin
      UUT.cpu_rd <= 1'b0;
      UUT.cpu_wdata <= 32'b00000000000000000000000000000000;
      UUT.cpu_wr <= 1'b1;
      UUT.mem_ack <= 1'b1;
      UUT.mem_rdata <= 32'b00000000000000000000000000000000;
      UUT.rst_n <= 1'b1;
      UUT.cpu_addr <= 16'b0000000000000000;
    end

    genclock <= cycle < 4;
    cycle <= cycle + 1;
  end
endmodule
