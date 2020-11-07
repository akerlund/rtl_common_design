////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Fredrik Åkerlund
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
// Description:
//
////////////////////////////////////////////////////////////////////////////////

import uvm_pkg::*;
import arb_tb_pkg::*;
import arb_tc_pkg::*;

module arb_tb_top;

  bit clk;
  bit rst_n;

  time clk_period = 10ns;

  // IF
  vip_axi4s_if #(vip_axi4s_cfg) mst0_vif(clk, rst_n);
  vip_axi4s_if #(vip_axi4s_cfg) mst1_vif(clk, rst_n);
  vip_axi4s_if #(vip_axi4s_cfg) mst2_vif(clk, rst_n);
  vip_axi4s_if #(vip_axi4s_cfg) slv0_vif(clk, rst_n);

  localparam int NR_OF_MASTERS_C  = 3;
  localparam int AXI_DATA_WIDTH_C = vip_axi4s_cfg.AXI_DATA_WIDTH_P;
  localparam int AXI_STRB_WIDTH_C = vip_axi4s_cfg.AXI_STRB_WIDTH_P;
  localparam int AXI_KEEP_WIDTH_C = vip_axi4s_cfg.AXI_KEEP_WIDTH_P;
  localparam int AXI_ID_WIDTH_C   = vip_axi4s_cfg.AXI_ID_WIDTH_P;
  localparam int AXI_DEST_WIDTH_C = vip_axi4s_cfg.AXI_DEST_WIDTH_P;
  localparam int AXI_USER_WIDTH_C = vip_axi4s_cfg.AXI_USER_WIDTH_P;

  logic [NR_OF_MASTERS_C-1 : 0]                          mst_tvalid;
  logic [NR_OF_MASTERS_C-1 : 0]                          mst_tready;
  logic [NR_OF_MASTERS_C-1 : 0] [AXI_DATA_WIDTH_C-1 : 0] mst_tdata;
  logic [NR_OF_MASTERS_C-1 : 0] [AXI_STRB_WIDTH_C-1 : 0] mst_tstrb;
  logic [NR_OF_MASTERS_C-1 : 0] [AXI_KEEP_WIDTH_C-1 : 0] mst_tkeep;
  logic [NR_OF_MASTERS_C-1 : 0]                          mst_tlast;
  logic [NR_OF_MASTERS_C-1 : 0]   [AXI_ID_WIDTH_C-1 : 0] mst_tid;
  logic [NR_OF_MASTERS_C-1 : 0] [AXI_DEST_WIDTH_C-1 : 0] mst_tdest;
  logic [NR_OF_MASTERS_C-1 : 0] [AXI_USER_WIDTH_C-1 : 0] mst_tuser;



  assign mst_tvalid[0]   = mst0_vif.tvalid;
  assign mst0_vif.tready = mst_tready[0];
  assign mst_tdata[0]    = mst0_vif.tdata;
  assign mst_tstrb[0]    = mst0_vif.tstrb;
  assign mst_tkeep[0]    = mst0_vif.tkeep;
  assign mst_tlast[0]    = mst0_vif.tlast;
  assign mst_tid[0]      = mst0_vif.tid;
  assign mst_tdest[0]    = mst0_vif.tdest;
  assign mst_tuser[0]    = mst0_vif.tuser;

  assign mst_tvalid[1]   = mst1_vif.tvalid;
  assign mst1_vif.tready = mst_tready[1];
  assign mst_tdata[1]    = mst1_vif.tdata;
  assign mst_tstrb[1]    = mst1_vif.tstrb;
  assign mst_tkeep[1]    = mst1_vif.tkeep;
  assign mst_tlast[1]    = mst1_vif.tlast;
  assign mst_tid[1]      = mst1_vif.tid;
  assign mst_tdest[1]    = mst1_vif.tdest;
  assign mst_tuser[1]    = mst1_vif.tuser;

  assign mst_tvalid[2]   = mst2_vif.tvalid;
  assign mst2_vif.tready = mst_tready[2];
  assign mst_tdata[2]    = mst2_vif.tdata;
  assign mst_tstrb[2]    = mst2_vif.tstrb;
  assign mst_tkeep[2]    = mst2_vif.tkeep;
  assign mst_tlast[2]    = mst2_vif.tlast;
  assign mst_tid[2]      = mst2_vif.tid;
  assign mst_tdest[2]    = mst2_vif.tdest;
  assign mst_tuser[2]    = mst2_vif.tuser;

  axi4s_m2s_arbiter #(

    .NR_OF_MASTERS_P  ( NR_OF_MASTERS_C  ),
    .AXI_DATA_WIDTH_P ( AXI_DATA_WIDTH_C ),
    .AXI_STRB_WIDTH_P ( AXI_STRB_WIDTH_C ),
    .AXI_KEEP_WIDTH_P ( AXI_KEEP_WIDTH_C ),
    .AXI_ID_WIDTH_P   ( AXI_ID_WIDTH_C   ),
    .AXI_DEST_WIDTH_P ( AXI_DEST_WIDTH_C ),
    .AXI_USER_WIDTH_P ( AXI_USER_WIDTH_C )

  ) axi4s_m2s_arbiter_i0 (

    // Clock and reset
    .clk              ( clk              ), // input
    .rst_n            ( rst_n            ), // input

    .mst_tvalid       ( mst_tvalid       ), // input
    .mst_tready       ( mst_tready       ), // output
    .mst_tdata        ( mst_tdata        ), // input
    .mst_tstrb        ( mst_tstrb        ), // input
    .mst_tkeep        ( mst_tkeep        ), // input
    .mst_tlast        ( mst_tlast        ), // input
    .mst_tid          ( mst_tid          ), // input
    .mst_tdest        ( mst_tdest        ), // input
    .mst_tuser        ( mst_tuser        ), // input

    .slv_tvalid       ( slv0_vif.tvalid  ), // output
    .slv_tready       ( slv0_vif.tready  ), // input
    .slv_tdata        ( slv0_vif.tdata   ), // output
    .slv_tstrb        ( slv0_vif.tstrb   ), // output
    .slv_tkeep        ( slv0_vif.tkeep   ), // output
    .slv_tlast        ( slv0_vif.tlast   ), // output
    .slv_tid          ( slv0_vif.tid     ), // output
    .slv_tdest        ( slv0_vif.tdest   ), // output
    .slv_tuser        ( slv0_vif.tuser   )  // output
  );

  initial begin

    uvm_config_db #(virtual vip_axi4s_if #(vip_axi4s_cfg))::set(uvm_root::get(), "uvm_test_top.tb_env.vip_axi4s_agent_mst0*", "vif", mst0_vif);
    uvm_config_db #(virtual vip_axi4s_if #(vip_axi4s_cfg))::set(uvm_root::get(), "uvm_test_top.tb_env.vip_axi4s_agent_mst1*", "vif", mst1_vif);
    uvm_config_db #(virtual vip_axi4s_if #(vip_axi4s_cfg))::set(uvm_root::get(), "uvm_test_top.tb_env.vip_axi4s_agent_mst2*", "vif", mst2_vif);
    uvm_config_db #(virtual vip_axi4s_if #(vip_axi4s_cfg))::set(uvm_root::get(), "uvm_test_top.tb_env.vip_axi4s_agent_slv0*", "vif", slv0_vif);

    run_test();
    $stop();

  end



  initial begin

    // With recording detail you can switch on/off transaction recording.
    if ($test$plusargs("RECORD")) begin
      uvm_config_db #(uvm_verbosity)::set(null,"*", "recording_detail", UVM_FULL);
    end
    else begin
      uvm_config_db #(uvm_verbosity)::set(null,"*", "recording_detail", UVM_NONE);
    end
  end


  // Generate reset
  initial begin

    rst_n = 1'b1;

    #(clk_period*5)

    rst_n = 1'b0;

    #(clk_period*5)

    @(posedge clk);

    rst_n = 1'b1;

  end

  // Generate clock
  always begin
    #(clk_period/2)
    clk = ~clk;
  end

endmodule
