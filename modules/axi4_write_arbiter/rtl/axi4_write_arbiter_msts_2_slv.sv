////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Fredrik Åkerlund
// https://github.com/akerlund/RTL
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
// With the value of a counter labeled "wr_rotating_mst", this arbiter checks
// the corresponding "mst_awvalid" port and allows for connection if found
// high. The connection is closed when the handshake on the Write Response
// Channel is detected and the counter will continue to increase until the next
// asserted "mst_awvalid" is found.
//
////////////////////////////////////////////////////////////////////////////////

`default_nettype none

module axi4_write_arbiter_msts_2_slv #(
    parameter int AXI_ID_WIDTH_P   = -1,
    parameter int AXI_ADDR_WIDTH_P = -1,
    parameter int AXI_DATA_WIDTH_P = -1,
    parameter int AXI_STRB_WIDTH_P = -1,
    parameter int NR_OF_MASTERS_P  = -1
  )(

    // Clock and reset
    input  wire                                                   clk,
    input  wire                                                   rst_n,


    // -------------------------------------------------------------------------
    // AXI4 Masters
    // -------------------------------------------------------------------------

    // Write Address Channel
    input  wire  [NR_OF_MASTERS_P-1 : 0]   [AXI_ID_WIDTH_P-1 : 0] mst_awid,
    input  wire  [NR_OF_MASTERS_P-1 : 0] [AXI_ADDR_WIDTH_P-1 : 0] mst_awaddr,
    input  wire  [NR_OF_MASTERS_P-1 : 0]                  [7 : 0] mst_awlen,
    input  wire  [NR_OF_MASTERS_P-1 : 0]                  [2 : 0] mst_awsize,
    input  wire  [NR_OF_MASTERS_P-1 : 0]                  [1 : 0] mst_awburst,
    input  wire  [NR_OF_MASTERS_P-1 : 0]                  [3 : 0] mst_awregion,
    input  wire  [NR_OF_MASTERS_P-1 : 0]                          mst_awvalid,
    output logic [NR_OF_MASTERS_P-1 : 0]                          mst_awready,

    // Write Data Channel
    input  wire  [NR_OF_MASTERS_P-1 : 0] [AXI_DATA_WIDTH_P-1 : 0] mst_wdata,
    input  wire  [NR_OF_MASTERS_P-1 : 0] [AXI_STRB_WIDTH_P-1 : 0] mst_wstrb,
    input  wire  [NR_OF_MASTERS_P-1 : 0]                          mst_wlast,
    input  wire  [NR_OF_MASTERS_P-1 : 0]                          mst_wvalid,
    output logic [NR_OF_MASTERS_P-1 : 0]                          mst_wready,

    // Write Response Channel
    output logic                           [AXI_ID_WIDTH_P-1 : 0] mst_bid,
    output logic                                          [1 : 0] mst_bresp,
    output logic                          [NR_OF_MASTERS_P-1 : 0] mst_bvalid,
    input  wire                           [NR_OF_MASTERS_P-1 : 0] mst_bready,

    // -------------------------------------------------------------------------
    // AXI4 Slave
    // -------------------------------------------------------------------------

    // Write Address Channel
    output logic                           [AXI_ID_WIDTH_P-1 : 0] slv_awid,
    output logic                         [AXI_ADDR_WIDTH_P-1 : 0] slv_awaddr,
    output logic                                          [7 : 0] slv_awlen,
    output logic                                          [2 : 0] slv_awsize,
    output logic                                          [1 : 0] slv_awburst,
    output logic                                          [3 : 0] slv_awregion,
    output logic                                                  slv_awvalid,
    input  wire                                                   slv_awready,

    // Write Data Channel
    output logic                         [AXI_DATA_WIDTH_P-1 : 0] slv_wdata,
    output logic                         [AXI_STRB_WIDTH_P-1 : 0] slv_wstrb,
    output logic                                                  slv_wlast,
    output logic                                                  slv_wvalid,
    input  wire                                                   slv_wready,

    // Write Response Channel
    input  wire                            [AXI_ID_WIDTH_P-1 : 0] slv_bid,
    input  wire                                           [1 : 0] slv_bresp,
    input  wire                                                   slv_bvalid,
    output logic                                                  slv_bready
  );


  localparam logic [$clog2(NR_OF_MASTERS_P)-1 : 0] NR_OF_MASTERS_C = NR_OF_MASTERS_P;

  // ---------------------------------------------------------------------------
  // Write Channel signals
  // ---------------------------------------------------------------------------

  typedef enum {
    FIND_MST_AWVALID_E,
    WAIT_FOR_BVALID_E,
    WAIT_MST_WLAST_E
  } write_state_t;

  write_state_t write_state;

  logic [$clog2(NR_OF_MASTERS_P)-1 : 0] wr_rotating_mst;
  logic [$clog2(NR_OF_MASTERS_P)-1 : 0] wr_selected_mst;
  logic                                 wr_mst_is_chosen;

  // ---------------------------------------------------------------------------
  // Port assignments
  // ---------------------------------------------------------------------------

  assign mst_bid   = slv_bid;
  assign mst_bresp = slv_bresp;

  // ---------------------------------------------------------------------------
  // Write processes
  // ---------------------------------------------------------------------------

  // FSM
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      write_state      <= FIND_MST_AWVALID_E;
      wr_rotating_mst  <= '0;                 // Round Robin counter
      wr_selected_mst  <= '0;                 // MUX select
      wr_mst_is_chosen <= '0;                 // Output enable
      mst_awready      <= '0;
    end
    else begin

      mst_awready <= '0;

      case (write_state)

        FIND_MST_AWVALID_E: begin

          if (slv_awready) begin

            if (wr_rotating_mst == NR_OF_MASTERS_C-1) begin
              wr_rotating_mst <= '0;
            end else begin
              wr_rotating_mst <= wr_rotating_mst + 1;
            end

            if (mst_awvalid[wr_rotating_mst]) begin
              write_state                  <= WAIT_MST_WLAST_E;
              mst_awready[wr_rotating_mst] <= '1;
              wr_selected_mst              <= wr_rotating_mst;
              wr_mst_is_chosen             <= '1;
            end
          end
        end


        WAIT_MST_WLAST_E: begin

          if (slv_awready) begin
            mst_awready <= '0;
          end else begin
            mst_awready <= mst_awready;
          end

          if (slv_wlast && slv_wvalid && slv_wready) begin
            write_state <= WAIT_FOR_BVALID_E;
          end
        end


        WAIT_FOR_BVALID_E: begin

          if (slv_bvalid && slv_bready) begin
            write_state      <= FIND_MST_AWVALID_E;
            wr_mst_is_chosen <= '0;
          end
        end
      endcase
    end
  end


  // MUX
  always_comb begin

    // Write Address Channel
    slv_awid     = '0;
    slv_awaddr   = '0;
    slv_awlen    = '0;
    slv_awvalid  = '0;
    slv_awsize   = '0;
    slv_awburst  = '0;
    slv_awregion = '0;

    // Write Data Channel
    slv_wdata    = '0;
    slv_wstrb    = '0;
    slv_wlast    = '0;
    slv_wvalid   = '0;
    mst_wready   = '0;

    // Write Response Channel
    mst_bvalid   = '0;
    slv_bready   = '0;

    if (!wr_mst_is_chosen) begin

      // Write Address Channel
      slv_awid     = '0;
      slv_awaddr   = '0;
      slv_awlen    = '0;
      slv_awvalid  = '0;
      slv_awsize   = '0;
      slv_awburst  = '0;
      slv_awregion = '0;

      // Write Data Channel
      slv_wdata    = '0;
      slv_wstrb    = '0;
      slv_wlast    = '0;
      slv_wvalid   = '0;
      mst_wready   = '0;

      // Write Response Channel
      mst_bvalid   = '0;
      slv_bready   = '0;

    end
    else begin

      // Write Address Channel
      slv_awid                    = mst_awid     [wr_selected_mst];
      slv_awaddr                  = mst_awaddr   [wr_selected_mst];
      slv_awlen                   = mst_awlen    [wr_selected_mst];
      slv_awvalid                 = mst_awvalid  [wr_selected_mst];
      slv_awsize                  = mst_awsize   [wr_selected_mst];
      slv_awburst                 = mst_awburst  [wr_selected_mst];
      slv_awregion                = mst_awregion [wr_selected_mst];

      // Write Data Channel
      slv_wdata                   = mst_wdata  [wr_selected_mst];
      slv_wstrb                   = mst_wstrb  [wr_selected_mst];
      slv_wlast                   = mst_wlast  [wr_selected_mst];
      slv_wvalid                  = mst_wvalid [wr_selected_mst];
      mst_wready[wr_selected_mst] = slv_wready;

      // Write Response Channel
      mst_bvalid[wr_selected_mst] = slv_bvalid;
      slv_bready                  = mst_bready[wr_selected_mst];

    end

  end

endmodule

`default_nettype wire
