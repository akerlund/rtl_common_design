////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Fredrik Åkerlund
// https://github.com/akerlund/PYRG
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

import osc_address_pkg::*;

module osc_axi_slave #(
    parameter int AUDIO_WIDTH_C = -1,
    parameter int AXI_ADDR_WIDTH_P = -1,
    parameter int AXI_DATA_WIDTH_P = -1,
    parameter int AXI_ID_P = -1,
    parameter int GAIN_WIDTH_C = -1,
    parameter int N_BITS_C = -1,
    parameter int Q_BITS_C = -1
  )(
    axi4_reg_if.slave cif,
    output logic          [1 : 0] cr_osc_waveform_select,
    output logic [N_BITS_C-1 : 0] cr_osc_frequency,
    output logic [N_BITS_C-1 : 0] cr_osc_duty_cycle
  );

  localparam logic [1 : 0] AXI_RESP_SLVERR_C = 2'b01;

  // ---------------------------------------------------------------------------
  // Internal signals
  // ---------------------------------------------------------------------------

  typedef enum {
    WAIT_MST_AWVALID_E,
    WAIT_FOR_BREADY_E,
    WAIT_MST_WLAST_E
  } write_state_t;

  write_state_t write_state;

  logic [AXI_ADDR_WIDTH_P-1 : 0] awaddr_r0;

  typedef enum {
    WAIT_MST_ARVALID_E,
    WAIT_SLV_RLAST_E
  } read_state_t;

  read_state_t read_state;

  logic [AXI_ADDR_WIDTH_P-1 : 0] araddr_r0;
  logic                  [7 : 0] arlen_r0;



  // ---------------------------------------------------------------------------
  // Port assignments
  // ---------------------------------------------------------------------------

  assign cif.rid = AXI_ID_P;

  // ---------------------------------------------------------------------------
  // Write processes
  // ---------------------------------------------------------------------------
  always_ff @(posedge cif.clk or negedge cif.rst_n) begin
    if (!cif.rst_n) begin

      write_state <= WAIT_MST_AWVALID_E;
      awaddr_r0   <= '0;
      cif.awready <= '0;
      cif.wready  <= '0;
      cif.bvalid  <= '0;
      cif.bresp   <= '0;
      cr_osc_waveform_select <= 0;
      cr_osc_frequency       <= 500<<Q_BITS_C;
      cr_osc_duty_cycle      <= 500;

    end
    else begin




      case (write_state)

        default: begin
          write_state <= WAIT_MST_AWVALID_E;
        end

        WAIT_MST_AWVALID_E: begin

          cif.awready <= '1;

          if (cif.awvalid) begin
            write_state <= WAIT_MST_WLAST_E;
            cif.awready <= '0;
            awaddr_r0   <= cif.awaddr;
            cif.wready  <= '1;
          end

        end


        WAIT_FOR_BREADY_E: begin

          if (cif.bvalid && cif.bready) begin
            write_state <= WAIT_MST_AWVALID_E;
            cif.awready <= '1;
            cif.bvalid  <= '0;
            cif.bresp   <= '0;
          end

        end


        WAIT_MST_WLAST_E: begin

          if (cif.wlast && cif.wvalid) begin
            write_state <= WAIT_FOR_BREADY_E;
            cif.bvalid  <= '1;
            cif.wready  <= '0;
          end


          if (cif.wvalid) begin

            awaddr_r0 <= awaddr_r0 + (AXI_DATA_WIDTH_P/8);

            case (awaddr_r0)

              OSC_WAVEFORM_SELECT_ADDR: begin
                cr_osc_waveform_select <= cif.wdata[1 : 0];
              end

              OSC_FREQUENCY_ADDR: begin
                cr_osc_frequency <= cif.wdata[N_BITS_C-1 : 0];
              end

              OSC_DUTY_CYCLE_ADDR: begin
                cr_osc_duty_cycle <= cif.wdata[N_BITS_C-1 : 0];
              end


              default: begin
                cif.bresp <= AXI_RESP_SLVERR_C;
              end

            endcase


          end
        end
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Read process
  // ---------------------------------------------------------------------------

  assign cif.rlast = (arlen_r0 == '0);

  // FSM
  always_ff @(posedge cif.clk or negedge cif.rst_n) begin
    if (!cif.rst_n) begin

      read_state  <= WAIT_MST_ARVALID_E;
      cif.arready <= '0;
      araddr_r0   <= '0;
      arlen_r0    <= '0;
      cif.rvalid  <= '0;

    end
    else begin

      case (read_state)

        default: begin
          read_state <= WAIT_MST_ARVALID_E;
        end

        WAIT_MST_ARVALID_E: begin

          cif.arready <= '1;

          if (cif.arvalid) begin
            read_state  <= WAIT_SLV_RLAST_E;
            araddr_r0   <= cif.araddr;
            arlen_r0    <= cif.arlen;
            cif.arready <= '0;
            cif.rvalid  <= '1;
          end

        end

        WAIT_SLV_RLAST_E: begin


          if (cif.rready) begin
            araddr_r0 <= araddr_r0 + (AXI_DATA_WIDTH_P/8);
          end

          if (cif.rlast && cif.rready) begin
            read_state  <= WAIT_MST_ARVALID_E;
            cif.arready <= '1;
            cif.rvalid  <= '0;
          end

          if (arlen_r0 != '0) begin
            arlen_r0 <= arlen_r0 - 1;
          end

        end
      endcase
    end
  end


  always_comb begin

    cif.rdata = '0;
    cif.rresp = '0;


    case (araddr_r0)

      OSC_WAVEFORM_SELECT_ADDR: begin
        cif.rdata[1 : 0] = cr_osc_waveform_select;
      end

      OSC_FREQUENCY_ADDR: begin
        cif.rdata[N_BITS_C-1 : 0] = cr_osc_frequency;
      end

      OSC_DUTY_CYCLE_ADDR: begin
        cif.rdata[N_BITS_C-1 : 0] = cr_osc_duty_cycle;
      end


      default: begin
        cif.rresp = AXI_RESP_SLVERR_C;
        cif.rdata = '0;
      end

    endcase
  end

endmodule
