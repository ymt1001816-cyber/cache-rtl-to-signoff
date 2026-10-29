#!/bin/bash
# dft_summary.sh : one table of the scan-chain experiments (chains/N*/atpg.out)
#   patterns = effective patterns kept by ATPG;  cycles = tester cycles of the stuck-at pattern set (write_vectors, serial)
cd "$(dirname "$0")/chains"
printf "%-6s %-8s %-10s %-9s %-12s %-10s %-9s\n" chains longest SA_pat SA_cov SA_cycles TR_pat TR_cov
for d in $(ls -d N* | sort -V); do
  f=$d/atpg.out; [ -f $f ] || continue
  last() { awk -v e="$1" '/^@file/{c=$0} /INFO \(TDA-220\): +[0-9]+ +[0-9]+/{if (index(c, "-experiment " e)) l=$0} END{print l}' $f; }
  sa=$(last logic); tr=$(last delay)
  cyc=$(grep "TVE-005" $f | sed -n 2p | grep -oE "Created [0-9]+" | grep -oE "[0-9]+")
  len=$(grep -c "DFFPOSX1\|DFFSR" $d/cache_scan.v)
  n=${d#N}; longest=$(( (len + n - 1) / n ))
  printf "%-6s %-8s %-10s %-9s %-12s %-10s %-9s\n" $n $longest $(echo $sa | awk '{print $4}') $(echo $sa | awk '{print $6}') "$cyc" \
         $(echo $tr | awk '{print $4}') $(echo $tr | awk '{print $6}')
done
