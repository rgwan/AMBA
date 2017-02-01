/////////////////////////////////////////////////////////////////
//                                                             //
//    ██████╗  ██████╗  █████╗                                 //
//    ██╔══██╗██╔═══██╗██╔══██╗                                //
//    ██████╔╝██║   ██║███████║                                //
//    ██╔══██╗██║   ██║██╔══██║                                //
//    ██║  ██║╚██████╔╝██║  ██║                                //
//    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝                                //
//          ██╗      ██████╗  ██████╗ ██╗ ██████╗              //
//          ██║     ██╔═══██╗██╔════╝ ██║██╔════╝              //
//          ██║     ██║   ██║██║  ███╗██║██║                   //
//          ██║     ██║   ██║██║   ██║██║██║                   //
//          ███████╗╚██████╔╝╚██████╔╝██║╚██████╗              //
//          ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝ ╚═════╝              //
//                                                             //
//    APB Mux - Allows multiple slaves on one APB bus          //
//      Generates slave PSELs                                  //
//      Decodes PREADY, PSLVERR, PRDATA                        //
//                                                             //
/////////////////////////////////////////////////////////////////
//                                                             //
//             Copyright (C) 2016-2017 ROA Logic BV            //
//             www.roalogic.com                                //
//                                                             //
//    Unless specifically agreed in writing, this software is  //
//  licensed under the RoaLogic Non-Commercial License         //
//  version-1.0 (the "License"), a copy of which is included   //
//  with this file or may be found on the RoaLogic website     //
//  http://www.roalogic.com. You may not use the file except   //
//  in compliance with the License.                            //
//                                                             //
//    THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY        //
//  EXPRESS OF IMPLIED WARRANTIES OF ANY KIND.                 //
//  See the License for permissions and limitations under the  //
//  License.                                                   //
//                                                             //
/////////////////////////////////////////////////////////////////

 
module apb_mux #(
  parameter  PADDR_SIZE = 8,
             PDATA_SIZE = 8,
             SLAVES     = 8
)
(
  //Common signals
  input                   PRESETn,
                          PCLK,

  //To/From APB master
  input                   MST_PSEL,
  input  [PADDR_SIZE-1:0] MST_PADDR, //MSBs of address bus
  output [PDATA_SIZE-1:0] MST_PRDATA,
  output                  MST_PREADY,
  output                  MST_PSLVERR,

  //To/from APB slaves
  input  [PADDR_SIZE-1:0] slv_addr   [SLAVES], //address compare for each slave
  input  [PADDR_SIZE-1:0] slv_mask   [SLAVES],
  output                  SLV_PSEL   [SLAVES],
  input  [PDATA_SIZE-1:0] SLV_PRDATA [SLAVES],
  input                   SLV_PREADY [SLAVES],
  input                   SLV_PSLVERR[SLAVES]
);
  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  import ahb3lite_pkg::*;


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  logic [SLAVES-1:0][PDATA_SIZE-1:0] prdata;
  logic [SLAVES-1:0]                 pready;
  logic [SLAVES-1:0]                 pslverr;

  logic [PDATA_SIZE-1:0][SLAVES-1:0] prdata_switched;


  genvar s,b;


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
generate
    for (s=0;s<SLAVES;s++)
    begin: aa
        /*
         * Decode addresses
         */
        assign SLV_PSEL[s] = MST_PSEL & ( (MST_PADDR & slv_mask[s]) == (slv_addr[s] & slv_mask[s]) );


        /*
         * Mux slave responses
         */
        assign prdata [s] = SLV_PRDATA [s] & {PDATA_SIZE{SLV_PSEL[s]}};
        assign pready [s] = SLV_PREADY [s] & SLV_PSEL[s];
        assign pslverr[s] = SLV_PSLVERR[s] & SLV_PSEL[s];
    end
endgenerate


generate
  for (s=0;s<SLAVES;     s++)
  begin: bb
      for (b=0;b<PDATA_SIZE;b++)
      begin: cc
          assign prdata_switched[b][s] = prdata[s][b];
      end
  end

  for (b=0;b<PDATA_SIZE;b++)
  begin: dd
      assign MST_PRDATA[b] = |prdata_switched[b];
  end
endgenerate


  assign MST_PREADY  = |pready;
  assign MST_PSLVERR = |pslverr;
endmodule
