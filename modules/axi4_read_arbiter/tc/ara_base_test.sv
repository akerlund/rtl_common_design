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
////////////////////////////////////////////////////////////////////////////////

class ara_base_test extends uvm_test;

  `uvm_component_utils(ara_base_test)

  // ---------------------------------------------------------------------------
  // UVM variables
  // ---------------------------------------------------------------------------

  uvm_table_printer uvm_table_printer0;
  report_server     report_server0;

  // ---------------------------------------------------------------------------
  // Testbench variables
  // ---------------------------------------------------------------------------

  ara_env               tb_env;
  ara_virtual_sequencer v_sqr;

  // ---------------------------------------------------------------------------
  // VIP Agent configurations
  // ---------------------------------------------------------------------------

  clk_rst_config  clk_rst_config0;
  vip_axi4_config axi4_mem_cfg0;
  vip_axi4_config axi4_rd_cfg0;

  // ---------------------------------------------------------------------------
  // Sequences
  // ---------------------------------------------------------------------------

  reset_sequence                      reset_seq0;
  vip_axi4_read_seq #(VIP_AXI4_CFG_C) vip_axi4_read_seq0;


  function new(string name = "ara_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    // UVM
    uvm_config_db #(uvm_verbosity)::set(this, "*", "recording_detail", UVM_FULL);

    report_server0 = new("report_server0");
    uvm_report_server::set_server(report_server0);

    uvm_table_printer0                     = new();
    uvm_table_printer0.knobs.depth         = 3;
    uvm_table_printer0.knobs.default_radix = UVM_DEC;

    // Environment
    tb_env = ara_env::type_id::create("tb_env", this);

    // Configurations
    clk_rst_config0 = clk_rst_config::type_id::create("clk_rst_config0", this);
    axi4_rd_cfg0    = vip_axi4_config::type_id::create("axi4_rd_cfg0",   this);
    axi4_mem_cfg0   = vip_axi4_config::type_id::create("axi4_mem_cfg0",  this);

    axi4_mem_cfg0.vip_axi4_agent_type = VIP_AXI4_SLAVE_AGENT_E;
    axi4_mem_cfg0.mem_slave           = TRUE;
    axi4_mem_cfg0.mem_addr_width      = VIP_AXI4_CFG_C.VIP_AXI4_ADDR_WIDTH_P;

    axi4_rd_cfg0.min_rready_delay_period = 10;
    axi4_rd_cfg0.max_rready_delay_period = 10;

    uvm_config_db #(clk_rst_config)::set(this,  {"tb_env.clk_rst_agent0", "*"}, "cfg", clk_rst_config0);
    uvm_config_db #(vip_axi4_config)::set(this, {"tb_env.mem_agent0",     "*"}, "cfg", axi4_mem_cfg0);
    uvm_config_db #(vip_axi4_config)::set(this, {"tb_env.rd_agent0",      "*"}, "cfg", axi4_rd_cfg0);
  endfunction


  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    v_sqr = tb_env.virtual_sequencer;
    `uvm_info(get_name(), {"VIP AXI4 Agent (Read):\n",   axi4_rd_cfg0.sprint()},  UVM_LOW)
    `uvm_info(get_name(), {"VIP AXI4 Agent (Memory):\n", axi4_mem_cfg0.sprint()}, UVM_LOW)
  endfunction


  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    reset_seq0         = reset_sequence::type_id::create("reset_seq0");
    vip_axi4_read_seq0 = vip_axi4_read_seq #(VIP_AXI4_CFG_C)::type_id::create("vip_axi4_read_seq0");
  endfunction


  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    tb_env.mem_agent0.driver.memory_randomize();
    clk_delay(8);
    reset_seq0.start(v_sqr.clk_rst_sequencer0);
    phase.drop_objection(this);
  endtask


  task clk_delay(int delay);
    #(delay*clk_rst_config0.clock_period);
  endtask


  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    report_server0.test_report();
  endfunction

endclass
