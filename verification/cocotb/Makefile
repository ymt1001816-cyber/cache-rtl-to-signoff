# Makefile : cocotb testbench (test_cache.py) on Icarus Verilog
#   make                      original cache (cache_top.v)
#   make DUT=cg               clock-gated version
#   make DUT=dft              DFT version (test pins tied to 0 by a wrapper)
#   make BUG=write_allocate   planted bug: a write miss refills the line (must FAIL)
#   options: N=<random requests> (default 3000), COCOTB_RANDOM_SEED=<seed>
# needs OSS CAD Suite (cocotb + iverilog) on PATH
RTL  ?= ../../rtl
WRAP ?= ../../dft/cache_top_wrap.v
MBIST ?= ../../dft/mbist/mbist_march.v
DUT  ?= base
SIM  ?= icarus
TOPLEVEL_LANG = verilog
COCOTB_TEST_MODULES = test_cache

ifeq ($(DUT),base)
VERILOG_SOURCES = $(RTL)/cache_top.v
TOPLEVEL = cache_top
endif
ifeq ($(DUT),cg)
VERILOG_SOURCES = $(RTL)/cache_top_cg.v $(RTL)/clk_gate.v
TOPLEVEL = cache_top_cg
endif
ifeq ($(DUT),dft)
VERILOG_SOURCES = $(RTL)/cache_top_dft.v $(RTL)/clk_gate_te.v $(MBIST) $(WRAP)
TOPLEVEL = cache_top
endif
ifeq ($(BUG),write_allocate)
VERILOG_SOURCES = bug_write_allocate.v
DUT = bug
endif
SIM_BUILD = sim_build_$(DUT)
COCOTB_RESULTS_FILE = results_$(DUT).xml

include $(shell cocotb-config --makefiles)/Makefile.sim

bug_write_allocate.v: $(RTL)/cache_top.v
	sed 's/if (cpu_wr) state <= WRITE_MEM; /if (cpu_wr) state <= hit ? WRITE_MEM : REFILL;/' $< > $@
