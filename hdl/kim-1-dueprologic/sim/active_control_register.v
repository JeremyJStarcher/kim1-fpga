/******************************************************
 * $Workfile::                                       
 * $Author::                                         
 * $Date::                                           
 * $Revision::                                       
 *
 *
 * This header files defines the input/output
******************************************************/
`timescale 1 ns / 10 ps

module active_control_register
  (
   input wire                  CLK,
   input wire                  RST,
   input wire                  TRANSFER_IN_RECEIVED,
   input wire [7:0]            TRANSFER_IN_BYTE,

   output reg  [7:0]           CONTROL_REGISTER
   );

   //-----------------------------------------------
   // Parameters
   //-----------------------------------------------

   //Header Bytes for the Transfer Loopback detection
   parameter                   TRANSFER_CONTROL_BYTE1 = 8'h5A;
   parameter                   TRANSFER_CONTROL_BYTE2 = 8'hC3;
   parameter                   TRANSFER_CONTROL_BYTE3 = 8'h7E;
   
   //State Machine Transfer Loopback detection
   parameter                   TRANSFER_CONTROL_IDLE = 0,
			                   TRANSFER_CONTROL_HDR1 = 1,
			                   TRANSFER_CONTROL_HDR2 = 2,
			                   TRANSFER_DECODE_BYTE   = 3,
			                   TRANSFER_CONTROL_SET  = 4;

//***************************************************************************
//* Internal Signals and Registers Declarations
//***************************************************************************

	reg                        transfer_in_received_reg;
	reg  [3:0]                 transfer_control_state;
   
   //-----------------------------------------------
   // State Machine: Control Register from Transfer In 
   //-----------------------------------------------
    always @(posedge CLK or negedge RST) 
	begin
	     if (!RST)
		 begin
			 transfer_in_received_reg <= 1'b0;
			 transfer_control_state <= TRANSFER_CONTROL_IDLE;
			 CONTROL_REGISTER <= 0;
		 end 
		 else 
		 begin 
		     if(TRANSFER_IN_RECEIVED & !transfer_in_received_reg)
			 begin
			     transfer_in_received_reg <= 1'b1;
		         case(transfer_control_state)
			     TRANSFER_CONTROL_IDLE:
		             if((TRANSFER_IN_BYTE == TRANSFER_CONTROL_BYTE1))
			             transfer_control_state <= TRANSFER_CONTROL_HDR1;
				     else if((TRANSFER_IN_BYTE != TRANSFER_CONTROL_BYTE1))
			             transfer_control_state <= TRANSFER_CONTROL_IDLE;
				     else
				         transfer_control_state <= TRANSFER_CONTROL_IDLE;
			     TRANSFER_CONTROL_HDR1:
		             if((TRANSFER_IN_BYTE == TRANSFER_CONTROL_BYTE2))
			             transfer_control_state <= TRANSFER_CONTROL_HDR2;
				     else if((TRANSFER_IN_BYTE != TRANSFER_CONTROL_BYTE2))
			             transfer_control_state <= TRANSFER_CONTROL_IDLE;
				     else
				         transfer_control_state <= TRANSFER_CONTROL_HDR1;
			     TRANSFER_CONTROL_HDR2:
		             if((TRANSFER_IN_BYTE == TRANSFER_CONTROL_BYTE3))
			             transfer_control_state <= TRANSFER_DECODE_BYTE;
				     else if((TRANSFER_IN_BYTE != TRANSFER_CONTROL_BYTE3))
			             transfer_control_state <= TRANSFER_CONTROL_IDLE;
				     else
				         transfer_control_state <= TRANSFER_CONTROL_HDR2;
			     TRANSFER_DECODE_BYTE:
			     begin
					 CONTROL_REGISTER <= TRANSFER_IN_BYTE;
			         transfer_control_state <= TRANSFER_CONTROL_SET;
				 end
			     TRANSFER_CONTROL_SET:
			     begin
			         transfer_control_state <= TRANSFER_CONTROL_IDLE;
				 end
			     endcase
			 end
			 else if(!TRANSFER_IN_RECEIVED & transfer_in_received_reg)
			     transfer_in_received_reg <= 1'b0;
         end
	end	 
endmodule 

