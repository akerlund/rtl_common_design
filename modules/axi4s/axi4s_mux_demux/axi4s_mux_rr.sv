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

`default_nettype none

module axi4s_mux_rr #(
    parameter int nr_of_streams_p = -1,
    parameter int tdata_width_p   = -1,
    parameter int tid_bit_width_p = $clog2(nr_of_streams_p)
  )(
    // Clock and reset
    input  wire                                                  clk,
    input  wire                                                  rst_n,

    // AXI4-S master side
    output logic                         [nr_of_streams_p-1 : 0] axi4s_i_tready,
    input  wire                          [nr_of_streams_p-1 : 0] axi4s_i_tvalid,
    input  wire                          [nr_of_streams_p-1 : 0] axi4s_i_tlast,
    input  wire  [nr_of_streams_p-1 : 0] [tdata_width_p*8-1 : 0] axi4s_i_tdata,

    // AXI4-S slave side
    input  wire                                                  axi4s_o_tready,
    output logic                                                 axi4s_o_tvalid,
    output logic                                                 axi4s_o_tlast,
    output logic                         [tid_bit_width_p-1 : 0] axi4s_o_tid,
    output logic                         [tdata_width_p*8-1 : 0] axi4s_o_tdata
  );

  logic                       bus_is_locked;
  logic [tid_bit_width_p-1:0] rr_counter;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      axi4s_i_tready <= '0;
      axi4s_o_tvalid <= '0;
      axi4s_o_tdata  <= '0;
      axi4s_o_tlast  <= '0;
      axi4s_o_tid    <= '0;

      bus_is_locked  <= '0;
      rr_counter     <= '0;
    end
    else begin

      axi4s_i_tready[rr_counter] <= axi4s_o_tready;

      axi4s_o_tvalid <= axi4s_i_tvalid[rr_counter];
      axi4s_o_tdata  <= axi4s_i_tdata[rr_counter];
      axi4s_o_tlast  <= axi4s_i_tlast[rr_counter];
      axi4s_o_tid    <= rr_counter;

      // MUX is not locked, finding a valid input
      if (!bus_is_locked) begin

        // Lock the MUX if it is ready and tvalid from a master is high
        if (axi4s_i_tvalid[rr_counter]) begin
          bus_is_locked              <= '1;
        end
        // Count up the round robin counter
        else if ( rr_counter == (nr_of_streams_p-1) ) begin
          rr_counter <= '0;
        end
        else begin
          rr_counter <= rr_counter + 1;
        end

      end
      // MUX is locked, waiting for transaction to finish
      else begin

        // Stop when !tvalid
        if (!axi4s_i_tvalid[rr_counter]) begin
          bus_is_locked  <= '0;
          axi4s_i_tready <= '0; // Reset all

          // Count up the round robin counter
          if ( rr_counter == (nr_of_streams_p-1) ) begin
            rr_counter <= '0;
          end
          else begin
            rr_counter <= rr_counter + 1;
          end
        end

      end
    end
  end

endmodule

`default_nettype wire