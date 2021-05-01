#!/bin/bash

git_root="$(git rev-parse --show-toplevel)"

# Specify the top files
rtl_top=iir_biquad_top
uvm_top="iir_tb_top"

# ------------------------------------------------------------------------------
# Source submodules
# ------------------------------------------------------------------------------

git_sub_root="$(git rev-parse --show-toplevel)"

git_root="$(git rev-parse --show-toplevel)/submodules/VIP"
source $git_sub_root/submodules/VIP/bool/files.lst
source $git_sub_root/submodules/VIP/vip_axi4_agent/files.lst
source $git_sub_root/submodules/VIP/vip_axi4s_agent/files.lst
source $git_sub_root/submodules/VIP/vip_clk_rst_agent/files.lst
source $git_sub_root/submodules/VIP/report_server/files.lst

git_root="$(git rev-parse --show-toplevel)/submodules/PYRG"
source $git_sub_root/submodules/PYRG/rtl/files.lst

# ------------------------------------------------------------------------------
# Source modules
# ------------------------------------------------------------------------------

# Restoring the git root
git_root="$(git rev-parse --show-toplevel)"

#source $git_root/modules/math/long_division/rtl/files.lst
#source $git_root/modules/math/cordic/rtl/files.lst
#source $git_root/modules/math/multiplication/rtl/files.lst
#
## Source the module's file lists
#source ./rtl/files.lst
source ./tb/files.lst

# Parameter override
#parameters+=("AXI_DATA_WIDTH_P=32 ")
#parameters+=("AXI_ID_WIDTH_P=4 ")
#parameters+=("AXI4S_ID_P=1 ")
#parameters+=("APB_DATA_WIDTH_P=32 ")
#parameters+=("N_BITS_P=32 ")
#parameters+=("Q_BITS_P=17 ")
