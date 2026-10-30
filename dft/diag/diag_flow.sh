#!/bin/bash
# diag_flow.sh : logic diagnosis demo on the 32-chain scan design (run inside a copy of the ATPG workdir with committed tests)
#   1. prepare_diagnostics_setup picks random static logic faults to inject
#   2. report_fault_effects writes, for each injected fault, the tester fail log it would cause (Chip-Pad-Pattern format)
#   3. Modus diagnose_failset_logic needs a Modus_Diagnostics license, which the school does not have, so
#      fault_dict_diag.py does cause-effect diagnosis by fault-dictionary matching instead:
#      the injected fault is hidden among 400 random candidates and must come out on top
M() { env -i HOME=$HOME USER=$USER LOGNAME=$USER SHELL=/bin/bash TERM=dumb PATH=/ECEnet/Apps1/linux/Cadence/MODUS251/bin:/usr/bin:/bin \
      CDS_LIC_FILE=$CDS_LIC_FILE modus -batch -disable_user_startup -files $1 > ${1%.tcl}.out 2>&1; }
cat > inject.tcl <<T
prepare_diagnostics_setup -workdir mdb -testmode FULLSCAN -logicfaults yes -scanfaults no -numlogicfaultinjections 3
report_fault_effects -WORKDIR mdb -TESTMODE FULLSCAN -faultinjectionfile logic_faults_file -outputdirectoryname chips
exit
T
M inject.tcl
mkdir -p dict && cd dict
cat > cand.tcl <<T
prepare_diagnostics_setup -workdir ../mdb -testmode FULLSCAN -logicfaults yes -scanfaults no -numlogicfaultinjections 400
exit
T
M cand.tcl
cat logic_faults_file ../logic_faults_file | sort -u > cand.txt          # the injected faults hidden among the candidates
printf "report_fault_effects -WORKDIR ../mdb -TESTMODE FULLSCAN -faultinjectionfile cand.txt -outputdirectoryname cand\nexit\n" > rfe.tcl
M rfe.tcl; cd ..
for f in chips/*.cpp; do
  python3 fault_dict_diag.py $f dict/cand            # complete fail log
  python3 fault_dict_diag.py $f dict/cand 0.6 7      # tester kept only 40% of the failures
done
