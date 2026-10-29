// axil_cache.v : AXI4-Lite slave wrapper around cache_top (CPU side); the memory side is unchanged
//   AXI4-Lite read / write  ->  cpu_rd / cpu_wr  ->  wait for cpu_ready  ->  AXI response
//   See AXI_GUIDE.md for the handshake rules.
module axil_cache (
    input             clk,
    input             rst_n,
    // AXI4-Lite slave: write address
    input             awvalid,
    output            awready,
    input      [31:0] awaddr,
    // write data
    input             wvalid,
    output            wready,
    input      [31:0] wdata,
    input      [3:0]  wstrb,
    // write response
    output            bvalid,
    input             bready,
    output     [1:0]  bresp,
    // read address
    input             arvalid,
    output            arready,
    input      [31:0] araddr,
    // read data
    output            rvalid,
    input             rready,
    output     [31:0] rdata,
    output     [1:0]  rresp,
    // memory side of the cache (same as cache_top)
    output     [13:0] mem_addr,
    output     [31:0] mem_wdata,
    output            mem_rd,
    output            mem_wr,
    input      [31:0] mem_rdata,
    input             mem_ack
);
    // TODO: state machine IDLE / READ / WRITE / RRESP / BRESP
    // TODO: registers for the captured address, write data, "AW received", "W received", read data
    // TODO: AXI outputs (awready, wready, arready, bvalid, bresp, rvalid, rdata, rresp)
    // TODO: cache_top instance, driven from the registers:
    //   cache_top u_cache (.clk(clk), .rst_n(rst_n), .cpu_addr(...), .cpu_wdata(...), .cpu_rd(...), .cpu_wr(...),
    //                      .cpu_rdata(...), .cpu_ready(...), .mem_addr(mem_addr), .mem_wdata(mem_wdata),
    //                      .mem_rd(mem_rd), .mem_wr(mem_wr), .mem_rdata(mem_rdata), .mem_ack(mem_ack));
endmodule
