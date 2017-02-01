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
//    AMBA AHB3-Lite Package                                   //
//                                                             //
/////////////////////////////////////////////////////////////////
//                                                             //
//    Copyright (C) 2015-2016 ROA Logic BV                     //
//    www.roalogic.com                                         //
//                                                             //
//   This source file may be used and distributed without      //
// restriction provided that this copyright statement is not   //
// removed from the file and that any derivative work contains //
// the original copyright notice and the associated disclaimer.//
//                                                             //
//     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     //
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   //
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   //
// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      //
// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         //
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    //
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   //
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        //
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  //
// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  //
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  //
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         //
// POSSIBILITY OF SUCH DAMAGE.                                 //
//                                                             //
/////////////////////////////////////////////////////////////////

 
/************************************************
 * AHB3 Lite Package
 */
package ahb3lite_pkg;
  //HTRANS
  parameter [1:0] HTRANS_IDLE   = 2'b00,
                  HTRANS_BUSY   = 2'b01,
                  HTRANS_NONSEQ = 2'b10,
                  HTRANS_SEQ    = 2'b11;

  //HSIZE
  parameter [2:0] HSIZE_B8    = 3'b000,
                  HSIZE_B16   = 3'b001,
                  HSIZE_B32   = 3'b010,
                  HSIZE_B64   = 3'b011,
                  HSIZE_B128  = 3'b100, //4-word line
                  HSIZE_B256  = 3'b101, //8-word line
                  HSIZE_B512  = 3'b110,
                  HSIZE_B1024 = 3'b111,
                  HSIZE_BYTE  = HSIZE_B8,
                  HSIZE_HWORD = HSIZE_B16,
                  HSIZE_WORD  = HSIZE_B32,
                  HSIZE_DWORD = HSIZE_B64;

  //HBURST
  parameter [2:0] HBURST_SINGLE = 3'b000,
                  HBURST_INCR   = 3'b001,
                  HBURST_WRAP4  = 3'b010,
                  HBURST_INCR4  = 3'b011,
                  HBURST_WRAP8  = 3'b100,
                  HBURST_INCR8  = 3'b101,
                  HBURST_WRAP16 = 3'b110,
                  HBURST_INCR16 = 3'b111;

  //HPROT
  parameter [3:0] HPROT_OPCODE         = 4'b0000,
                  HPROT_DATA           = 4'b0001,
                  HPROT_USER           = 4'b0000,
                  HPROT_PRIVILEGED     = 4'b0010,
                  HPROT_NON_BUFFERABLE = 4'b0000,
                  HPROT_BUFFERABLE     = 4'b0100,
                  HPROT_NON_CACHEABLE  = 4'b0000,
                  HPROT_CACHEABLE      = 4'b1000;

  //HRESP
  parameter       HRESP_OKAY  = 1'b0,
                  HRESP_ERROR = 1'b1;

endpackage



/************************************************
 * AHB3 Lite Interface
 */
 `ifndef AHB3_INTERFACES
 `define AHB3_INTERFACES
interface ahb3lite_bus #(
  parameter HADDR_SIZE = 32,
  parameter HDATA_SIZE = 32
)
(
  input logic HCLK,HRESETn
);
  logic                   HSEL;
  logic [HADDR_SIZE -1:0] HADDR;
  logic [HDATA_SIZE -1:0] HWDATA;
  logic [HDATA_SIZE -1:0] HRDATA;
  logic                   HWRITE;
  logic [            2:0] HSIZE;
  logic [            3:0] HBURST;
  logic [            3:0] HPROT;
  logic [            1:0] HTRANS;
  logic                   HMASTLOCK;
  logic                   HREADY;
  logic                   HREADYOUT;
  logic                   HRESP;

`ifdef SIM
  // Master CB Interface Definitions
  clocking cb_master @(posedge HCLK);
      output HSEL;
      output HADDR;
      output HWDATA;
      input  HRDATA;
      output HWRITE;
      output HSIZE;
      output HBURST;
      output HPROT;
      output HTRANS;
      output HMASTLOCK;
      input  HREADY;
      input  HRESP;
  endclocking

  modport master_cb (
    clocking cb_master,
    input    HRESETn
  );

  // Slave Interface Definitions
  clocking cb_slave @(posedge HCLK);
      input  HSEL;
      input  HADDR;
      input  HWDATA;
      output HRDATA;
      input  HWRITE;
      input  HSIZE;
      input  HBURST;
      input  HPROT;
      input  HTRANS;
      input  HMASTLOCK;
      input  HREADY;
      output HREADYOUT;
      output HRESP;
  endclocking

  modport slave_cb (
      clocking cb_slave,
      input HRESETn
  );
`endif

  modport master (
      input  HRESETn,
      input  HCLK,
      output HSEL,
      output HADDR,
      output HWDATA,
      input  HRDATA,
      output HWRITE,
      output HSIZE,
      output HBURST,
      output HPROT,
      output HTRANS,
      output HMASTLOCK,
      input  HREADY,
      input  HRESP
  );

  modport slave (
      input  HRESETn,
      input  HCLK,
      input  HSEL,
      input  HADDR,
      input  HWDATA,
      output HRDATA,
      input  HWRITE,
      input  HSIZE,
      input  HBURST,
      input  HPROT,
      input  HTRANS,
      input  HMASTLOCK,
      input  HREADY,
      output HREADYOUT,
      output HRESP
  );
endinterface


/************************************************
 * APB Lite Interface
 */
interface apb_bus #(
    parameter PADDR_SIZE = 6,
    parameter PDATA_SIZE = 8
  )
  (
    input logic PCLK,PRESETn
  );
    logic                    PSEL;
    logic                    PENABLE;
    logic [             2:0] PPROT;
    logic                    PWRITE;
    logic [PDATA_SIZE/8-1:0] PSTRB;
    logic [PADDR_SIZE  -1:0] PADDR;
    logic [PDATA_SIZE  -1:0] PWDATA;
    logic [PDATA_SIZE  -1:0] PRDATA;
    logic                    PREADY;
    logic                    PSLVERR;

    modport master (
      input  PRESETn,
      input  PCLK,
      output PSEL,
      output PENABLE,
      output PPROT,
      output PADDR,
      output PWRITE,
      output PSTRB,
      output PWDATA,
      input  PRDATA,
      input  PREADY,
      input  PSLVERR
    );

    modport slave (
      import is_read, is_write,

      input  PRESETn,
      input  PCLK,
      input  PSEL,
      input  PENABLE,
      input  PPROT,
      input  PADDR,
      input  PWRITE,
      input  PSTRB,
      input  PWDATA,
      output PRDATA,
      output PREADY,
      output PSLVERR
    );

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
		
      mask = -1 >> ($bits(PADDR) -bits); //only 'bits' LSBs should be '1'		
      return is_write() & ( (PADDR & mask) == (address & mask) );
    endfunction

    //What data is written?
    //- Handles PSTRB, takes previous register/data value as an argument
    function automatic [PDATA_SIZE-1:0] get_write_value (input [PDATA_SIZE-1:0] orig_val);
       for (int n=0; n < PDATA_SIZE/8; n++)
         get_write_value[n*8 +: 8] = PSTRB[n] ? PWDATA[n*8 +: 8] : orig_val[n*8 +: 8];
    endfunction


    //Is this the 'setup' phase of the transfer?
    function automatic is_setup_phase();
      return PSEL & ~PENABLE;
    endfunction


    //Negate PREADY, Negate PSLVERR
    task set_not_ready();
      PREADY  = 1'b0;
      PSLVERR = 1'b0;
    endtask

    //Assert PREADY, Negate PSLVERR
    task set_ready();
      PREADY  = 1'b1;
      PSLVERR = 1'b0;
    endtask

   //Assert PREADY, Assert PSLVERR
   task set_error();
     PREADY  = 1'b1;
     PSLVERR = 1'b1;
   endtask
endinterface
`endif
