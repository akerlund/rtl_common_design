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

module oscillator_top #(
    parameter int SYS_CLK_FREQUENCY_P  = -1,
    parameter int PRIME_FREQUENCY_P    = -1,
    parameter int WAVE_WIDTH_P         = -1,
    parameter int DUTY_CYCLE_DIVIDER_P = -1, // Needs to be high so the vector will fit [N_BITS_P-1 : 0]
    parameter int N_BITS_P             = -1,
    parameter int Q_BITS_P             = -1,
    parameter int AXI_DATA_WIDTH_P     = -1,
    parameter int AXI_ID_WIDTH_P       = -1,
    parameter int AXI_ID_P             = -1,
    parameter int APB_BASE_ADDR_P      = -1,
    parameter int APB_ADDR_WIDTH_P     = -1,
    parameter int APB_DATA_WIDTH_P     = -1
  )(
    // Clock and reset
    input  wire                                    clk,
    input  wire                                    rst_n,

    // Waveform output
    output logic signed       [WAVE_WIDTH_P-1 : 0] waveform,

    // Long division interface
    output logic                                   div_egr_tvalid,
    input  wire                                    div_egr_tready,
    output logic          [AXI_DATA_WIDTH_P-1 : 0] div_egr_tdata,
    output logic                                   div_egr_tlast,
    output logic            [AXI_ID_WIDTH_P-1 : 0] div_egr_tid,

    input  wire                                    div_ing_tvalid,
    output logic                                   div_ing_tready,
    input  wire           [AXI_DATA_WIDTH_P-1 : 0] div_ing_tdata,     // Quotient
    input  wire                                    div_ing_tlast,
    input  wire             [AXI_ID_WIDTH_P-1 : 0] div_ing_tid,
    input  wire                                    div_ing_tuser,     // Overflow

    // CORDIC interface
    output logic                                   egr_cor_tvalid,
    input  wire                                    egr_cor_tready,
    output logic signed   [AXI_DATA_WIDTH_P-1 : 0] egr_cor_tdata,
    output logic                                   egr_cor_tlast,
    output logic            [AXI_ID_WIDTH_P-1 : 0] egr_cor_tid,
    output logic                                   egr_cor_tuser,     // Vector selection
    input  wire                                    cor_ing_tvalid,
    output logic                                   cor_ing_tready,
    input  wire  signed [2*AXI_DATA_WIDTH_P-1 : 0] cor_ing_tdata,
    input  wire                                    cor_ing_tlast,

    // APB interface
    input  wire                                    apb3_psel,
    output logic                                   apb3_pready,
    output logic          [APB_DATA_WIDTH_P-1 : 0] apb3_prdata,
    input  wire                                    apb3_pwrite,
    input  wire                                    apb3_penable,
    input  wire           [APB_ADDR_WIDTH_P-1 : 0] apb3_paddr,
    input  wire           [APB_DATA_WIDTH_P-1 : 0] apb3_pwdata
  );


  // Waveform outputs from the core
  logic signed     [WAVE_WIDTH_P-1 : 0] wave_square;
  logic signed     [WAVE_WIDTH_P-1 : 0] wave_triangle;
  logic signed     [WAVE_WIDTH_P-1 : 0] wave_saw;
  logic signed         [N_BITS_P-1 : 0] wave_sin;


  // APB signals
  logic        [APB_DATA_WIDTH_P-1 : 0] cr_waveform_select;
  logic        [APB_DATA_WIDTH_P-1 : 0] cr_frequency;
  logic        [APB_DATA_WIDTH_P-1 : 0] cr_duty_cycle;
  logic                         [1 : 0] cr_nq_waveform_select;
  logic                [N_BITS_P-1 : 0] cr_nq_frequency;
  logic                [N_BITS_P-1 : 0] cr_nq_duty_cycle;

  // Type converting the configuration in "cr_waveform_select"
  osc_waveform_type_t osc_selected_waveform;
  assign osc_selected_waveform = osc_waveform_type_t'(cr_waveform_select);

  // Resizing the configuration registers
  assign cr_nq_waveform_select = cr_waveform_select[1 : 0];
  assign cr_nq_frequency       = cr_frequency[N_BITS_P-1 : 0];
  assign cr_nq_duty_cycle      = cr_duty_cycle[N_BITS_P-1 : 0];


  // Waveform output selection
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      waveform <= '0;
    end
    else begin

      case (osc_selected_waveform)

        OSC_SQUARE_E: begin
          waveform <= wave_square   >>> (WAVE_WIDTH_P - Q_BITS_P - 1);
        end

        OSC_TRIANGLE_E: begin
          waveform <= wave_triangle >>> (WAVE_WIDTH_P - Q_BITS_P - 1);
        end

        OSC_SAW_E: begin
          waveform <= wave_saw      >>> (WAVE_WIDTH_P - Q_BITS_P - 1);
        end

        OSC_SINE_E: begin
          waveform <= wave_saw      >>> (WAVE_WIDTH_P - Q_BITS_P - 1);
        end

      endcase

    end

  end

  oscillator_core #(
    .SYS_CLK_FREQUENCY_P  ( SYS_CLK_FREQUENCY_P   ),
    .PRIME_FREQUENCY_P    ( PRIME_FREQUENCY_P     ),
    .WAVE_WIDTH_P         ( WAVE_WIDTH_P          ),
    .DUTY_CYCLE_DIVIDER_P ( DUTY_CYCLE_DIVIDER_P  ),
    .N_BITS_P             ( N_BITS_P              ),
    .Q_BITS_P             ( Q_BITS_P              ),
    .AXI_DATA_WIDTH_P     ( AXI_DATA_WIDTH_P      ),
    .AXI_ID_WIDTH_P       ( AXI_ID_WIDTH_P        ),
    .AXI_ID_P             ( AXI_ID_P              )
  ) oscillator_core_i0 (
    .clk                  ( clk                   ), // input
    .rst_n                ( rst_n                 ), // input
    .wave_square          ( wave_square           ), // output
    .wave_triangle        ( wave_triangle         ), // output
    .wave_saw             ( wave_saw              ), // output
    .wave_sin             ( wave_sin              ), // output
    .div_egr_tvalid       ( div_egr_tvalid        ), // output
    .div_egr_tready       ( div_egr_tready        ), // input
    .div_egr_tdata        ( div_egr_tdata         ), // output
    .div_egr_tlast        ( div_egr_tlast         ), // output
    .div_egr_tid          ( div_egr_tid           ), // output
    .div_ing_tvalid       ( div_ing_tvalid        ), // input
    .div_ing_tready       ( div_ing_tready        ), // output
    .div_ing_tdata        ( div_ing_tdata         ), // input
    .div_ing_tlast        ( div_ing_tlast         ), // input
    .div_ing_tid          ( div_ing_tid           ), // input
    .div_ing_tuser        ( div_ing_tuser         ), // input
    .cordic_egr_tvalid    ( egr_cor_tvalid        ), // output
    .cordic_egr_tready    ( egr_cor_tready        ), // input
    .cordic_egr_tdata     ( egr_cor_tdata         ), // output
    .cordic_egr_tlast     ( egr_cor_tlast         ), // output
    .cordic_egr_tid       ( egr_cor_tid           ), // output
    .cordic_egr_tuser     ( egr_cor_tuser         ), // output
    .cordic_ing_tvalid    ( cor_ing_tvalid        ), // input
    .cordic_ing_tready    ( cor_ing_tready        ), // output
    .cordic_ing_tdata     ( cor_ing_tdata         ), // input
    .cordic_ing_tlast     ( cor_ing_tlast         ), // input
    .cr_waveform_select   ( cr_nq_waveform_select ), // input
    .cr_frequency         ( cr_nq_frequency       ), // input
    .cr_duty_cycle        ( cr_nq_duty_cycle      )  // input
  );


  oscillator_apb3_slave #(
    .APB_BASE_ADDR_P     ( APB_BASE_ADDR_P     ),
    .APB_ADDR_WIDTH_P    ( APB_ADDR_WIDTH_P    ),
    .APB_DATA_WIDTH_P    ( APB_DATA_WIDTH_P    )
  ) oscillator_apb3_slave_i0 (
    .clk                 ( clk                 ), // input
    .rst_n               ( rst_n               ), // input
    .apb3_psel           ( apb3_psel           ), // input
    .apb3_pready         ( apb3_pready         ), // output
    .apb3_prdata         ( apb3_prdata         ), // output
    .apb3_pwrite         ( apb3_pwrite         ), // input
    .apb3_penable        ( apb3_penable        ), // input
    .apb3_paddr          ( apb3_paddr          ), // input
    .apb3_pwdata         ( apb3_pwdata         ), // input
    .cr_waveform_select  ( cr_waveform_select  ), // output
    .cr_frequency        ( cr_frequency        ), // output
    .cr_duty_cycle       ( cr_duty_cycle       )  // output
  );

endmodule

`default_nettype wire