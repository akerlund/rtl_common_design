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

class tc_arb_simple_test extends arb_base_test;

  arb_vseq #(vip_axi4s_cfg) arb_vseq0;

  `uvm_component_utils(tc_arb_simple_test)



  function new(string name = "tc_arb_simple_test", uvm_component parent = null);

    super.new(name, parent);

  endfunction



  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

  endfunction



  task run_phase(uvm_phase phase);

    super.run_phase(phase);
    phase.raise_objection(this);

    arb_vseq0 = new();
    arb_vseq0.nr_of_bursts            = 10000;
    arb_vseq0.max_idle_between_bursts = 100;
    arb_vseq0.start(v_sqr);

    phase.drop_objection(this);

  endtask

endclass
