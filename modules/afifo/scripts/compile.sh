#!/bin/bash

git_root="$(git rev-parse --show-toplevel)"

# Specify the top files
rtl_top="afifo"
uvm_top="fi_tb_top"

# ------------------------------------------------------------------------------
# Source submodules
# ------------------------------------------------------------------------------

git_sub_root="$(git rev-parse --show-toplevel)"

git_root="$(git rev-parse --show-toplevel)/submodules/VIP"
source $git_sub_root/submodules/VIP/bool/files.lst
source $git_sub_root/submodules/VIP/vip_axi4s_agent/files.lst
source $git_sub_root/submodules/VIP/vip_clk_rst_agent/files.lst
source $git_sub_root/submodules/VIP/report_server/files.lst

# ------------------------------------------------------------------------------
# Source modules
# ------------------------------------------------------------------------------

# Restoring the git root
git_root="$(git rev-parse --show-toplevel)"
source $git_root/modules/synchronizers/cdc_bit_sync/rtl/files.lst
source $git_root/modules/memory/reg/rtl/files.lst
source $git_root/modules/memory/ram/rtl/files.lst
source $git_root/modules/fifo/rtl/files.lst
source ./rtl/files.lst
source ./tb/files.lst

# ------------------------------------------------------------------------------
# Parameter override
# ------------------------------------------------------------------------------
parameters+=("DATA_WIDTH_P=128 ")
parameters+=("ADDR_WIDTH_P=2 ")
