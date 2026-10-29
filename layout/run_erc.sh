#!/bin/bash
# run_erc.sh <gds> <out_name> : Calibre ERC (lec10 p26). FreePDK45 ships no ERC rules, so these checks are
# written on top of its LVS connectivity (calibreLVS.rul). Layer maps reuse the Run 4 LVS runset.
source /ECEnet/Apps1/linux/EECE7353/cadence618_eda_tools_cad13_only_safe.sh > /dev/null 2>&1
export USE_CALIBRE_VCO=aoi
GDS=$1; OUT=$2; D=~/EECE7353/cache/05_Calibre/erc/$OUT
mkdir -p $D && cd $D
{
sed -e "s#^LAYOUT PATH .*#LAYOUT PATH \"$GDS\"#" -e '/^SOURCE /d' ~/EECE7353/cache/05_Calibre/lvs/run4/run4.svrf
cat <<'R'
ERC RESULTS DATABASE "erc.results" ASCII
ERC SUMMARY REPORT "erc.summary" REPLACE HIER
ERC MAXIMUM RESULTS 1000
ERC SELECT CHECK float_net nwell_float pwell_float gate_tied
// nets with no path through transistors to either supply: floating gates
// (primary inputs also show up here, since they are driven from outside the chip)
float_net { PATHCHK !POWER && !GROUND }
// wells that are not on the supply net (latch-up)
nwell_float { NOT NET nsub vdd VDD }
pwell_float { NOT NET pwell gnd GND VSS }
// transistor gates wired straight to a supply (OSU has no tie cells)
gate_tied { (NET poly vdd VDD gnd GND VSS) INTERACT (ngate OR pgate) }
R
} > $OUT.svrf
S=$(date +%s)
calibre -spice $OUT.sp -hier $OUT.svrf > $OUT.log 2>&1 < /dev/null
echo "calibre exit: $? ($(( $(date +%s) - S )) s)"
grep -E "^ERROR|Short circuit" $OUT.log | head -5
grep -E "RULECHECK|TOTAL" erc.summary | head -20
