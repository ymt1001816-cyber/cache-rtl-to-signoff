// axil_props.vh : formal properties of axil_cache, included inside the module under `ifdef FORMAL
//   Inside the module, the properties can see internal registers (state, have_aw, have_w). Open-source Yosys cannot
//   reference dut.state from a separate harness: it silently makes a new free wire (warning "implicitly declared").
//   "assume" = what the AXI master does (written with an AI assistant)   "assert" = what the slave must do (Meiyu Kuo)
//   cache_top is replaced by formal/cache_stub.v, so cpu_ready / cpu_rdata are free: the proof holds for any cache behavior.

    // ---- environment (assume) ----
    reg [1:0] f_cyc = 0; always @(posedge clk) if (f_cyc != 2'd3) f_cyc <= f_cyc + 1;
    wire f_past = (f_cyc != 0);
    always @(*) if (f_cyc < 2) assume (!rst_n);                     // reset for 2 cycles, then stay out of reset
    always @(*) if (f_cyc >= 2) assume (rst_n);
    always @(*) if (!rst_n) assume (!awvalid && !wvalid && !arvalid);
    always @(posedge clk) if (f_past && $past(rst_n)) begin         // the master holds VALID and its payload until READY
        if ($past(awvalid && !awready)) assume (awvalid && $stable(awaddr));
        if ($past(wvalid && !wready))   assume (wvalid && $stable(wdata) && $stable(wstrb));
        if ($past(arvalid && !arready)) assume (arvalid && $stable(araddr));
    end

    // accepted transfers per channel (4-bit, they wrap: compare DIFFERENCES such as f_aw - f_b, never f_aw > f_b)
    reg [3:0] f_aw = 0, f_w = 0, f_b = 0, f_ar = 0, f_r = 0;
    always @(posedge clk) if (!rst_n) begin f_aw <= 0; f_w <= 0; f_b <= 0; f_ar <= 0; f_r <= 0; end else begin
        f_aw <= f_aw + (awvalid && awready); f_w <= f_w + (wvalid && wready); f_b <= f_b + (bvalid && bready);
        f_ar <= f_ar + (arvalid && arready); f_r <= f_r + (rvalid && rready);
    end

    // ---- properties (assert): the same rules as axil_sva.sv, written as immediate asserts ----
    always @(*) if (!rst_n) a_reset_no_valid: assert (!bvalid && !rvalid);          // example (done)

    always @(posedge clk) if (f_past && $past(rst_n) && rst_n) begin
        if ($past(rvalid && !rready)) begin
            a_rvalid_hold: assert (rvalid);
            a_rdata_stable: assert ($stable(rdata));
        end
        if ($past(bvalid && !bready)) begin
            a_bvalid_hold: assert (bvalid);
            a_bresp_stable: assert ($stable(bresp));
        end
    end
    // Explicit widths preserve modulo-16 subtraction even across counter wrap.
    wire [3:0] f_aw_pending = f_aw - f_b;
    wire [3:0] f_w_pending = f_w - f_b;
    wire [3:0] f_ar_pending = f_ar - f_r;
    always @(*) if (rst_n) begin
        if (bvalid) begin
            a_b_after_aw: assert (f_aw_pending == 4'd1);
            a_b_after_w: assert (f_w_pending == 4'd1);
        end
        if (rvalid) a_r_after_ar: assert (f_ar_pending == 4'd1);
    end

    // ---- helper invariants (assert): needed by "prove" (k-induction), not by "bmc" ----
    //   Induction may start in an unreachable state, e.g. state == RRESP with no read pending (f_ar == f_r).
    //   Tie the counters to the design state so those states are ruled out. Run "sby -f axil.sby prove":
    //   each failure points to the state that still needs a helper.
    always @(*) if (rst_n) begin
        h_legal_state: assert (state == IDLE || state == READ || state == WRITE ||
                               state == RRESP || state == BRESP);
        h_read_pending: assert (f_ar_pending == ((state == READ || state == RRESP) ? 4'd1 : 4'd0));
        h_aw_pending: assert (f_aw_pending == (have_aw ? 4'd1 : 4'd0));
        h_w_pending: assert (f_w_pending == (have_w ? 4'd1 : 4'd0));
        if (state == WRITE || state == BRESP)
            h_write_collected: assert (have_aw && have_w);
        if (state == READ || state == RRESP)
            h_read_exclusive: assert (!have_aw && !have_w);
        if (state == IDLE)
            h_idle_partial: assert (!(have_aw && have_w));
    end

    // ---- covers: the checks are not vacuous ----
    always @(*) if (rst_n) begin
        c_aw_w_same_cycle: cover (awvalid && awready && wvalid && wready);
        c_read_done:       cover (rvalid && rready);
        c_slverr:          cover (bvalid && bready && bresp == 2'b10);
    end
