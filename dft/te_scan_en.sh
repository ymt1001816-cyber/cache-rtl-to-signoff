#!/bin/bash
# te_scan_en.sh : 4a, where should the clock-gate test enable come from?
#   run_dft_te : test_en is its own pin, tied to 1 for the whole test (shift AND capture): gates always open
#   run_dft_se : test_en driven by scan_en: gates open while shifting, but follow the functional enable in capture,
#                so the enable logic itself is tested (like an industry ICG with TE tied to scan enable)
# Same scan netlist and ATPG script as run_dft_te; only the one gate input that reads test_en is moved to scan_en.
cd "$(dirname "$0")"; A=run_dft_te; B=run_dft_se
rm -rf $B; mkdir -p $B
n=$(grep -c "(test_en)" $A/cache_scan.v)
sed 's/\.A (test_en)/.A (scan_en)/' $A/cache_scan.v > $B/cache_scan.v
echo "test_en uses moved to scan_en: $n -> $(grep -c '(test_en)' $B/cache_scan.v) left"
grep -v "pin=test_en " $A/pins.assign > $B/pins.assign     # test_en no longer drives anything
cp $A/atpg.tcl $B/
( cd $B && env -i HOME=$HOME USER=$USER LOGNAME=$USER SHELL=/bin/bash TERM=dumb \
    PATH=/ECEnet/Apps1/linux/Cadence/MODUS251/bin:/usr/bin:/bin CDS_LIC_FILE=$CDS_LIC_FILE \
    timeout 7200 modus -batch -disable_user_startup -files atpg.tcl > atpg.out 2>&1 )
echo "modus exit $?"
for d in $A $B; do
  echo "== $d"
  grep -E "TTM-35[79]" $d/atpg.out | head -2
  echo "TSV-315: $(grep -c 'WARNING (TSV-315)' $d/atpg.out)"
  grep -E "^Total Static" $d/atpg.out | tail -1
  grep -E "INFO \(TDA-220\): +[0-9]+ +[0-9]+" $d/atpg.out | tail -1
done
echo TE_SCAN_EN_DONE
