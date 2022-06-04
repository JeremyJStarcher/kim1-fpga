//#######################################################################
//#
//#	Copyright 	Earth People Technology Inc. 2012
//#
//#
//# File Name:  ft_245_state_machine.v
//# Author:     R. Jolly
//# Date:       January 4, 2012
//# Revision:   B
//#
//# Development: USB Test Tool Interface board 
//# Application: Altera MAX II CPLD
//# Description: This file contains verilog code which will allow access
//#              to an eight bit bus in the FPGA. The FPGA receives its commands via
//#				 USB.
//#               
//#              
//#************************************************************************
//#
//# Revision History:	
//#			DATE		VERSION		DETAILS		
//#			01/04/12 	A			Created			RJJ
//#			2/19/15 	B			Added if(usb_rxf_n_reg) to 
//#                                 state[DE_ASSERT_RD_N] in main state machine.
//#                                 This prevents the state machine from starting 
//#                                 the read loop again before the previous read
//#                                 has completed.
//#         5/31/15     C           Added ENDPOINT_BUSY
//#         6/2/15      D           Added FT_245_SM_BUSY
//#
//------------------------------------------------------------------------
// 
// Copyright (c) 2012 Earth People Technology Incorporated
// $Rev: 100 $ $Date: 2012-05-30 20:18:49 -0800 (Wed, 30 May 2012) $
//------------------------------------------------------------------------
`include "../src/define.v"


`timescale 1ns/1ps

module	ft_245_state_machine
	(	
	input  wire                CLK,
	input  wire                RST_N,
	
	input  wire                USB_RXF_N,
	input  wire                USB_TXE_N,

	output reg                 USB_RD_N,
	output reg                 USB_WR,
	output wire                USB_TEST,
	
	output reg   [7:0]         USB_REGISTER_DECODE,
	input wire   [7:0]         USB_DATA_IN,
	output wire  [7:0]         USB_DATA_OUT,
	
	output wire                DATA_BYTE_READY,
	input  wire                RSB_INT_EN,
    input  wire                ENDPOINT_BUSY,
	output wire                FT_245_SM_BUSY,
	
	input  wire                WRITE_EN,
	output wire                 WRITE_READY,
	input wire   [7:0]         WRITE_BYTE,
	output wire                WRITE_COMPLETE,
	
	output reg   [3:0]         STATE_OUT
	
	);

   //----------------------------------------------
   // Parameter Declarations  
   //----------------------------------------------
	parameter 	IDLE							= 0,
				ASSERT_RD_N	 					= 1,
				WAIT_FOR_RD_COMPLETION			= 2,
				WAIT_FOR_DE_ASSERT_RD_N			= 3,
				DE_ASSERT_RD_N					= 4,
				CHECK_TXE						= 5,
				ASSERT_WR						= 6,
				WAIT_FOR_WR_COMPLETION			= 7,
				DE_ASSERT_WR					= 8;
	
  //------------------------------------------------
   // Wire and Register Declarations                
   //------------------------------------------------
	reg 	[8:0] 					state, next;

	//Read/Write Control
	reg							read_complete;
	reg							read_complete_reg;
	reg	[7:0]					read_complete_cntr;
	reg							write_complete;
	reg							write_complete_reg;
	
	//Register the FT245 read control inputs 
	reg							usb_rxf_n_reg;
	reg  [1:0]                  usb_rxf_reg;

	//Register the FT245 write control inputs 
	reg							usb_txe_n_reg;
	

	
`ifdef SIM
   reg [8*26:1] state_name;
`endif

   //--------------------------------------------------
   // Signal Assignments
   //--------------------------------------------------   

	assign				USB_DATA_OUT = ( state[ASSERT_WR] || state[WAIT_FOR_WR_COMPLETION] ) ? WRITE_BYTE : 8'hzz;
	assign				USB_TEST = 1'b0;
	
	
   //-----------------------------------------------
   // DATA_BYTE_READY register signals completion of read cycle
   //-----------------------------------------------
   assign DATA_BYTE_READY = state[WAIT_FOR_RD_COMPLETION] ? 1'b1 : RSB_INT_EN ? 1'b0 : DATA_BYTE_READY;
   
  //
  // FT_245_SM_BUSY assert a signal when the read cycle is busy
  //  
  assign FT_245_SM_BUSY = (!USB_RXF_N | state[WAIT_FOR_RD_COMPLETION] | state[WAIT_FOR_DE_ASSERT_RD_N] ) ? 1'b1 : 1'b0;
   //-----------------------------------------------
   // Create a State Test Output Signal
   //-----------------------------------------------
   always @(posedge CLK or negedge RST_N)
     begin
	if (!RST_N)
	  STATE_OUT <= 0;
	else
	  begin
	     if (state[IDLE])
            STATE_OUT <= 4'h0;
	     if (state[ASSERT_RD_N])
	       STATE_OUT <= 4'h1;
	     if (state[WAIT_FOR_RD_COMPLETION])
	       STATE_OUT <= 4'h2;
	     if (state[WAIT_FOR_DE_ASSERT_RD_N])
	       STATE_OUT <= 4'h3;
	     if (state[DE_ASSERT_RD_N])
	       STATE_OUT <= 4'h4;
	     if (state[CHECK_TXE])
	       STATE_OUT <= 4'h5;
	     if (state[ASSERT_WR])
	       STATE_OUT <= 4'h6;
	     if (state[WAIT_FOR_WR_COMPLETION])
	       STATE_OUT <= 4'h7;
	     if (state[DE_ASSERT_WR])
	       STATE_OUT <= 4'h8;
	  end // else: !if(!RST_N)
     end // always @ (posedge CLK or negedge RST_N)

	 //-----------------------------------------------
   // Store contents of USB_DATA_IN into USB_REGISTER_DECODE
   //-----------------------------------------------
   always @(state[ASSERT_RD_N] or RST_N)
   begin
	     if (!RST_N)
		     USB_REGISTER_DECODE = 0;
		 else if(state[ASSERT_RD_N])
		     USB_REGISTER_DECODE = USB_DATA_IN;
		 else
		     USB_REGISTER_DECODE = USB_REGISTER_DECODE;

   end

	//-----------------------------------------------
   // Create WRITE_COMPLETE for the write cycle
   //-----------------------------------------------
   assign WRITE_COMPLETE = write_complete;
   
   //-----------------------------------------------
   // Create WRITE_READY for the write cycle
   //-----------------------------------------------
   assign WRITE_READY = ( state[ASSERT_WR] || state[WAIT_FOR_WR_COMPLETION] ) ? 1'b1 : state[IDLE] ? 1'b0 : 1'b0;
   
   //-----------------------------------------------
   // Register the USB_RXF_N input
   //-----------------------------------------------
   always @(posedge CLK or negedge RST_N)
   begin
	if (!RST_N)
	begin
		usb_rxf_n_reg <= 1'b1;
	end
	else
	begin
		if(!USB_RXF_N)
		begin
		    if(ENDPOINT_BUSY)
			   usb_rxf_n_reg <= 1'b1;
			else
			usb_rxf_n_reg <= 1'b0;
		end
		else 
		  usb_rxf_n_reg <= 1'b1;
	end
   end

/*   always @(posedge CLK or negedge RST_N)
   begin
	if (!RST_N)
	begin
		usb_rxf_n_reg <= 1'b1;
		usb_rxf_reg <= 2'b00;
	end
	else
	begin
		if(!USB_RXF_N & (usb_rxf_reg == 2'b00))
		begin
		    if(ENDPOINT_BUSY)
			   usb_rxf_reg <= 2'b01;
			else
			  usb_rxf_reg <= 2'b10; 
		end
		else if(!ENDPOINT_BUSY & (usb_rxf_reg == 2'b01))
		   usb_rxf_reg <= 2'b10;
		else if(!USB_RXF_N & (usb_rxf_reg == 2'b10))
		begin
			usb_rxf_n_reg <= 1'b0;
		    usb_rxf_reg <= 2'b11;
		end
		else if(USB_RXF_N & (usb_rxf_reg == 2'b11))
		begin
		    usb_rxf_n_reg <= 1'b1;
		    usb_rxf_reg <= 2'b00;
		end
	end
   end
*/

   //-----------------------------------------------
   // write_complete register will initiate the FT 245
   // to enter the write cycle mode. 
   //-----------------------------------------------
   always @(posedge CLK or negedge RST_N)
     begin
	if (!RST_N)
	begin
					write_complete_reg <= 0;
					write_complete <= 0;
					usb_txe_n_reg <= 0;
					USB_WR <= 1'b1;
	end
	else
	  begin
		if( state[ASSERT_WR] & !write_complete_reg )
		begin
			write_complete_reg <= 1'b1;
			write_complete <= 1'b0;
		end
		else if( state[ASSERT_WR] & write_complete_reg )
		begin
			USB_WR <= 1'b0;
			write_complete <= 1'b0;
			write_complete_reg <= 1'b1;
		end
		else if( state[WAIT_FOR_WR_COMPLETION] )
		begin
				if( USB_TXE_N && !usb_txe_n_reg )
				begin
                    USB_WR <= 1'b1;	
					usb_txe_n_reg <= 1'b1;
					write_complete <= 1'b1;
				end
		end
		else if( state[IDLE] )
		begin
					write_complete_reg <= 1'b0;
					write_complete <= 1'b0;
					usb_txe_n_reg <= 1'b0;
					USB_WR <= 1'b1;
		end
	   end

     end // always @ (posedge CLK or negedge RST_N)



   //-----------------------------------------------
   // Create read_complete read
   //-----------------------------------------------
   always @(posedge CLK or negedge RST_N)
     begin
	if (!RST_N)
	begin
		read_complete <= 1'b0;
		read_complete_reg <= 1'b0;
		read_complete_cntr <= 0;
	end
	else
	  begin
		if( state[ASSERT_RD_N] & !read_complete_reg )
		begin
			read_complete_reg <= 1'b1;
			read_complete <= 1'b0;
		end
		else if( state[WAIT_FOR_RD_COMPLETION] & read_complete_reg )
		begin
		    if(read_complete_cntr < 8'h0f )
			begin
			   read_complete <= 1'b1;
			   read_complete_reg <= 1'b1;
			   read_complete_cntr <= read_complete_cntr + 1'd1;
			end
			else
			begin
			   read_complete_reg <= 1'b0;
			   read_complete_cntr <= 0;
			   read_complete <= 1'b1;
			end
		
		    /*
			read_complete_reg <= 1'b1;
			read_complete_cntr <= read_complete_cntr + 1'd1;
			
				if ( read_complete_cntr <= 8'h0f )
				begin	
					read_complete_reg <= 1'b0;
					read_complete_cntr <= 0;
					read_complete <= 1'b1;
						
				end
			*/
		end
		else if( state[IDLE] )
		begin
					read_complete_reg <= 1'b0;
					read_complete_cntr <= 0;
					read_complete <= 1'b0;
		end
	   end

     end // always @ (posedge CLK or negedge RST_N)

   //-----------------------------------------------
   // Create USB_RD_N output
   //-----------------------------------------------
    always @(state[ASSERT_RD_N] or state[DE_ASSERT_RD_N] or RST_N)
	begin
	     if (!RST_N)
		     USB_RD_N <= 1'b1;
		else if( state[ASSERT_RD_N] )
			USB_RD_N <= 1'b0;
		else if( state[DE_ASSERT_RD_N] )
			USB_RD_N <= 1'b1;
    end
	
   //-----------------------------------------------
   // Finite  State Machine
   //-----------------------------------------------
   // Next State Logic
   always @(posedge CLK or negedge RST_N)
     begin
	if (!RST_N)
	  begin
	     state <= 9'h000;
	     state[IDLE] <= 1'b1;
	  end
	else
	  state <= next;
     end



     // State Definitions
   always @ ( state or usb_rxf_n_reg  or usb_txe_n_reg or read_complete or
		write_complete or WRITE_EN or RSB_INT_EN or USB_TXE_N or
		ENDPOINT_BUSY or usb_rxf_reg) 
     begin
	next = 9'h000;

	if (state[IDLE])
	  begin
	     if (!usb_rxf_n_reg)
	       next[ASSERT_RD_N] = 1'b1;
	     else if (WRITE_EN)
	       next[ASSERT_WR] = 1'b1;
	     else
	       next[IDLE] = 1'b1;
	  end
	
	if (state[ASSERT_RD_N])
	begin
			next[WAIT_FOR_RD_COMPLETION] = 1'b1;
	end

	if (state[WAIT_FOR_RD_COMPLETION])
	begin
		if ( read_complete )
			next[WAIT_FOR_DE_ASSERT_RD_N] = 1'b1;
		else 
			next[WAIT_FOR_RD_COMPLETION] = 1'b1;
	end

	if (state[WAIT_FOR_DE_ASSERT_RD_N])
	begin 
		if ( RSB_INT_EN )
			next[DE_ASSERT_RD_N] = 1'b1;
		else 
			next[WAIT_FOR_DE_ASSERT_RD_N] = 1'b1;
	end

	if (state[DE_ASSERT_RD_N])
	begin
	     if(usb_rxf_n_reg)
			next[IDLE] = 1'b1;
		else
			next[DE_ASSERT_RD_N] = 1'b1;
	end
	
	if (state[CHECK_TXE])
	begin
	     if(!USB_TXE_N)
			next[ASSERT_WR] = 1'b1;
		else
			next[CHECK_TXE] = 1'b1;
	end

	if (state[ASSERT_WR])
	begin
	     if(!USB_WR)
			next[WAIT_FOR_WR_COMPLETION] = 1'b1;
		else
			next[ASSERT_WR] = 1'b1;
	end

	if (state[WAIT_FOR_WR_COMPLETION])
	begin
		if ( write_complete )
			next[IDLE] = 1'b1;		  
		else
			next[WAIT_FOR_WR_COMPLETION] = 1'b1;
	end


`ifdef SIM
 	   if ( state == ( 1 << IDLE ))
		   state_name = "IDLE";
	   else if ( state == ( 1 << ASSERT_RD_N ))
		   state_name = "ASSERT_RD_N";
	   else if ( state == ( 1 << WAIT_FOR_RD_COMPLETION ))
		   state_name = "WAIT_FOR_RD_COMPLETION";
	   else if ( state == ( 1 << WAIT_FOR_DE_ASSERT_RD_N ))
		   state_name = "WAIT_FOR_DE_ASSERT_RD_N";
	   else if ( state == ( 1 << DE_ASSERT_RD_N ))
		   state_name = "DE_ASSERT_RD_N";
	   else if ( state == ( 1 << CHECK_TXE ))
		   state_name = "CHECK_TXE";
	   else if ( state == ( 1 << ASSERT_WR ))
		   state_name = "ASSERT_WR";
	   else if ( state == ( 1 << WAIT_FOR_WR_COMPLETION ))
		   state_name = "WAIT_FOR_WR_COMPLETION";
	   else if ( state == ( 1 << DE_ASSERT_WR ))
		   state_name = "DE_ASSERT_WR";
`endif


	end//end of state machine

	
	
   
endmodule 