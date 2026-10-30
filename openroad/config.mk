# config.mk : OpenROAD-flow-scripts (ORFS) design config, open-source RTL-to-GDS for cache_top
#   platform nangate45 = Nangate open cell library on FreePDK45 (same PDK as the Cadence flow, different cells)
#   run (inside the ORFS image):  make -C $FLOW_HOME DESIGN_CONFIG=<repo>/openroad/config.mk REPO=<repo>
export PLATFORM        = nangate45
export DESIGN_NAME     = cache_top
export DESIGN_NICKNAME = cache_top
export VERILOG_FILES   = $(REPO)/rtl/cache_top.v
export SDC_FILE        = $(REPO)/openroad/constraint.sdc

# floorplan: the core size follows from the cell area and the utilization (Cadence Run 5 used 0.6 density)
export CORE_UTILIZATION = 40
export PLACE_DENSITY    = 0.60
