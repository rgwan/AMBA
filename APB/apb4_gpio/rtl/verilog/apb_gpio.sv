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
//    APB GPIO                                                 //
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


/*
 * address  description         comment
 * 0x0      mode register       0=push-pull
 *                              1=open-drain
 * 0x1      direction register  0=input
 *                              1=output
 * 0x2      output register     mode-register=0? 0=drive pad low
 *                                               1=drive pad high
 *                              mode-register=1? 0=drive pad low
 *                                               1=open-drain
 * 0x3      input register      returns data at pad
 */

module apb_gpio #(
  PDATA_SIZE = 8
)
(
  input                         PRESETn,
                                PCLK,
  input                         PSEL,
  input                         PENABLE,
  input      [             2:0] PADDR,
  input                         PWRITE,
  input      [PDATA_SIZE/8-1:0] PSTRB,
  input      [PDATA_SIZE  -1:0] PWDATA,
  output reg [PDATA_SIZE  -1:0] PRDATA,
  output                        PREADY,
  output                        PSLVERR,

  input      [PDATA_SIZE  -1:0] gpio_i,
  output reg [PDATA_SIZE  -1:0] gpio_o,
                                gpio_oe
);
  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  import ahb3lite_pkg::*;

  localparam PADDR_SIZE = 3;


  localparam MODE      = 0,
             DIRECTION = 1,
             OUTPUT    = 2,
             INPUT     = 3,
             IOC       = 4, //Interrupt-on-change
             IPENDING  = 5; //Interrupt-pending


  //number of synchronisation flipflop stages on GPIO inputs
  localparam INPUT_STAGES = 3;


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //Control registers
  logic [PDATA_SIZE-1:0] mode_reg;
  logic [PDATA_SIZE-1:0] dir_reg;
  logic [PDATA_SIZE-1:0] out_reg;
  logic [PDATA_SIZE-1:0] in_reg;


  //Input register, to prevent metastability
  logic [PDATA_SIZE-1:0] input_regs [INPUT_STAGES];

  integer n;


  //////////////////////////////////////////////////////////////////
  //
  // Functions
  //

  //Is this a valid read access?
  function automatic is_read();
    return PSEL & PENABLE & ~PWRITE;
  endfunction

  //Is this a valid write access?
  function automatic is_write();
    return PSEL & PENABLE & PWRITE;
  endfunction

  //Is this a valid write to address 0x...?
  //Take 'address' as an argument
  function automatic is_write_to_adr(input integer bits, input [PADDR_SIZE-1:0] address);
    logic [$bits(PADDR)-1:0] mask;
		
    mask = (1 << bits) -1; //only 'bits' LSBs should be '1'
    return is_write() & ( (PADDR & mask) == (address & mask) );
  endfunction

  //What data is written?
  //- Handles PSTRB, takes previous register/data value as an argument
  function automatic [PDATA_SIZE-1:0] get_write_value (input [PDATA_SIZE-1:0] orig_val);
    for (int n=0; n < PDATA_SIZE/8; n++)
       get_write_value[n*8 +: 8] = PSTRB[n] ? PWDATA[n*8 +: 8] : orig_val[n*8 +: 8];
  endfunction


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /*
   * APB accesses
   */
  //The core supports zero-wait state accesses on all transfers.
  //It is allowed to driver PREADY with a steady signal
  assign PREADY  = 1'b1; //always ready
  assign PSLVERR = 1'b0; //Never an error


  /*
   * APB Writes
   */
  //APB write to Mode register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn                ) mode_reg <= 'h0;
    else if ( is_write_to_adr(2,MODE)) mode_reg <= get_write_value(mode_reg);


  //APB write to Direction register
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn                     ) dir_reg <= 'h0;
    else if ( is_write_to_adr(2,DIRECTION)) dir_reg <= get_write_value(dir_reg);


  //APB write to Output register
  //treat writes to Input register same
  always @(posedge PCLK,negedge PRESETn)
    if      (!PRESETn                    ) out_reg <= 'h0;
    else if ( is_write_to_adr(2,OUTPUT) ||
              is_write_to_adr(2,INPUT )  ) out_reg <= get_write_value(out_reg);


  /*
   * APB Reads
   */
  always @(posedge PCLK)
    case (PADDR[1:0])
      MODE     : PRDATA <= mode_reg;
      DIRECTION: PRDATA <= dir_reg;
      OUTPUT   : PRDATA <= out_reg;
      INPUT    : PRDATA <= in_reg;
    endcase


  /*
   * Internals
   */
  always @(posedge PCLK)
    for (n=0; n<INPUT_STAGES; n++)
       if (n==0) input_regs[n] <= gpio_i;
       else      input_regs[n] <= input_regs[n-1];

  always @(posedge PCLK)
    in_reg <= input_regs[INPUT_STAGES-1];


  // mode
  // 0=push-pull    drive out_reg value onto transmitter input
  // 1=open-drain   always drive '0' onto transmitter
  always @(posedge PCLK)
    gpio_o <= mode_reg ? 'h0 : out_reg;


  // direction  mode          out_reg
  // 0=input                           disable transmitter-enable (output enable)
  // 1=output   0=push-pull            always enable transmitter
  //            1=open-drain  1=Hi-Z   disable transmitter
  //                          0=low    enable transmitter
  always @(posedge PCLK)
    gpio_oe <= dir_reg & ~(mode_reg ? out_reg : 'h0);
endmodule
