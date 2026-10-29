// axil_sva.sv : AXI4-Lite protocol assertions for the slave outputs of axil_cache
//   Attached to the design with "bind" (no change to axil_cache.v). The same checks as the testbench monitor,
//   but written as SVA, so they also work in formal tools and in any other testbench.
// run (Xcelium; Icarus has no concurrent SVA): xrun -sv ../rtl/cache_top.v axil_cache.v axil_sva.sv tb_axil_cache.sv
module axil_sva (
    input        clk, rst_n,
    input        awvalid, awready, wvalid, wready, bvalid, bready,
    input        arvalid, arready, rvalid, rready,
    input [1:0]  bresp, rresp,
    input [31:0] rdata
);
    default clocking cb @(posedge clk); endclocking
    default disable iff (!rst_n);

    // Example (done): during reset the slave drives no valid
    a_reset_no_valid: assert property (@(posedge clk) disable iff (1'b0)
                                       !rst_n |-> (!bvalid && !rvalid));

    // A stalled response remains valid and stable through the accepting edge.
    a_rvalid_hold: assert property ((rvalid && !rready) |=> rvalid);
    a_rdata_stable: assert property ((rvalid && !rready) |=> $stable(rdata));
    a_bvalid_hold: assert property ((bvalid && !bready) |=> bvalid);
    a_bresp_stable: assert property ((bvalid && !bready) |=> $stable(bresp));

    longint unsigned aw_count, b_count;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_count <= 0;
            b_count <= 0;
        end else begin
            if (awvalid && awready) aw_count <= aw_count + 1;
            if (bvalid && bready) b_count <= b_count + 1;
        end
    end
    // Sampled counters include only handshakes from earlier edges.
    a_b_after_aw: assert property (bvalid |-> (aw_count > b_count));

    c_aw_w_same_cycle: cover property (awvalid && awready && wvalid && wready);
endmodule

bind axil_cache axil_sva u_sva (.*);
