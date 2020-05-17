////////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Fredrik Åkerlund
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
//
// Description:
//
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// Base Sequence
//
// Features:
//  * Can provide the git root path of the repository so a user can define paths
//  * Provides a function to read the contents of a file into a buffer
//  * Functions for
//    - Write one word
//    - Write masked, i.e., write bits
//    - Read one word
// -----------------------------------------------------------------------------
class vip_apb3_base_seq #(
  vip_apb3_cfg_t vip_cfg = '{default: '0}
  ) extends uvm_sequence #(vip_apb3_item #(vip_cfg));

  `uvm_object_param_utils(vip_apb3_base_seq #(vip_cfg))

  vip_apb3_item #(vip_cfg) apb_item;


  function new(string name = "vip_apb3_base_seq");

    super.new(name);

  endfunction



  task write_word(logic [vip_cfg.APB_ADDR_WIDTH_P-1 : 0] paddr,
                  logic [vip_cfg.APB_DATA_WIDTH_P-1 : 0] pwdata);

    apb_item = new();

    apb_item.paddr  = paddr;
    apb_item.pwrite = '1;
    apb_item.pwdata = pwdata;

    req = apb_item;
    start_item(req);
    finish_item(req);

  endtask



  task read_word(logic [vip_cfg.APB_ADDR_WIDTH_P-1 : 0] paddr,
                 logic [vip_cfg.APB_DATA_WIDTH_P-1 : 0] prdata);

    apb_item = new();

    apb_item.paddr  = paddr;
    apb_item.pwrite = '0;

    req = apb_item;
    start_item(req);
    finish_item(req);

    get_response(rsp);

    prdata = rsp.prdata;

  endtask



  task write_masked(logic [vip_cfg.APB_ADDR_WIDTH_P-1 : 0] paddr,
                    logic [vip_cfg.APB_DATA_WIDTH_P-1 : 0] pwdata,
                    logic [vip_cfg.APB_DATA_WIDTH_P-1 : 0] mask);

    logic [vip_cfg.APB_ADDR_WIDTH_P-1 : 0] prdata;
    read_word(paddr,  prdata);
    write_word(paddr, prdata & ~mask | pwdata & mask);

  endtask

endclass
