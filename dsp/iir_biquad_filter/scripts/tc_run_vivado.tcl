#-------------------------------------------------------------------------------
# Select testcase
#-------------------------------------------------------------------------------
set test_case "tc_iir_bypass";

set  script_dir [pwd]
cd   rundir
exec xsim top -testplusarg UVM_TESTNAME=$test_case -testplusarg UVM_VERBOSITY=UVM_LOW -gui
cd   $script_dir