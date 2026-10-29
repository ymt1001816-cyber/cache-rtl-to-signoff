// axil_if.sv : AXI4-Lite pins between the UVM AXI agent and axil_cache
interface axil_if (input logic clk);
  logic        rst_n;
  logic        awvalid, awready;  logic [31:0] awaddr;
  logic        wvalid,  wready;   logic [31:0] wdata;  logic [3:0] wstrb;
  logic        bvalid,  bready;   logic [1:0]  bresp;
  logic        arvalid, arready;  logic [31:0] araddr;
  logic        rvalid,  rready;   logic [31:0] rdata;  logic [1:0] rresp;
endinterface
