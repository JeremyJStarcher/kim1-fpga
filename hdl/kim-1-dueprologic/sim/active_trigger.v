//------------------------------------------------------------------------
// active_trigger.v
// 
//------------------------------------------------------------------------
// 
// Copyright (c) 2012 Earth People Technology Incorporated
// $Rev: 100 $ $Date: 2012-05-30 21:04:27 -0800 (Wed, 30 May 2012) $
//------------------------------------------------------------------------
`include "../src/define.v"

`timescale 1ns/1ps

module active_trigger (
	input  wire         uc_clk,
	input  wire         uc_reset,
	input  wire [`UC_IN_END:`UC_IN_START]  uc_in,
	output wire [`UC_OUT_END:`UC_OUT_START]  uc_out,

	input wire   [`UC_DATAIN_END:`UC_DATAIN_START]  trigger_to_host,
	output wire  [`UC_DATAOUT_END:`UC_DATAOUT_START]  trigger_to_device
	
	);
	
   //-----------------------------------------------
   // Parameters
   //-----------------------------------------------
	parameter                   TO_TRIGUPDATE_COUNT = 3'h3;

   //-----------------------------------------------
   // Internal Signals
   //-----------------------------------------------
	reg                 to_trigupdate;
	reg                 trigger_to_host_flag;
	reg [`UC_DATAOUT_END:`UC_DATAOUT_START]  previous_to_trigupdate;
	
	//Trigger to Host Update Reset Registers
	reg [`UC_ADDRESS_END:`UC_ADDRESS_START]  to_trigupdate_counter;
	reg [`UC_ADDRESS_END:`UC_ADDRESS_START] xint;
	
   //-----------------------------------------------
   // Assignments
   //-----------------------------------------------
    assign uc_out[`UC_DATAOUT_END:`UC_DATAOUT_START] = to_trigupdate ? trigger_to_host : 8'h0;
	assign uc_out[`UC_CMD_END:`UC_CMD_START]  = to_trigupdate ? `TRIGGER_OUT_CMD : 3'h0;
	assign uc_out[`UC_ADDRESS_END:`UC_ADDRESS_START]  = 3'h0;
	assign uc_out[`UC_LENGTH_END:`UC_LENGTH_START]  = 8'h0;
	
	assign trigger_to_device = (uc_in[`UC_CMD_END:`UC_CMD_START] == `TRIGGER_IN_CMD) ? uc_in[`UC_DATAOUT_END:`UC_DATAOUT_START] : 8'h0;

   //-----------------------------------------------
   // Trigger to Host 
   //-----------------------------------------------
    always @(posedge uc_clk or negedge uc_reset) 
    //always @(trigger_to_host or trigger_to_host_flag or uc_reset) 
	begin
	     if (!uc_reset)
		 begin
		     to_trigupdate <= 1'b0;	
             previous_to_trigupdate <= 0;			 
		 end
	     else
		 begin
		     if(trigger_to_host_flag)
		         to_trigupdate <= 1'b0;
		     else if(previous_to_trigupdate == trigger_to_host)
		         to_trigupdate <= 1'b0;
		     else if(trigger_to_host > previous_to_trigupdate)
		     begin
		         to_trigupdate <= 1'b1;	
                 previous_to_trigupdate <= trigger_to_host;			 
		     end
			 else
			 begin
			     if(xint <= 7)
				 begin
				     if(trigger_to_host[xint] == 1'b0)
					     previous_to_trigupdate[xint] <= 1'b0;
				     xint <= xint + 1'd1;
				 end
				 else 
				     xint <= 0;
			 end
		 end
	end
	
   //-----------------------------------------------
   // Reset Trigger to Host 
   //-----------------------------------------------
    always @(posedge uc_clk or negedge uc_reset) 
	begin
	     if (!uc_reset)
		 begin
		     trigger_to_host_flag <= 1'b0;
			 to_trigupdate_counter <= 0;
	     end 
		 else 
		 begin
             if(to_trigupdate)
             begin
                 if(to_trigupdate_counter < TO_TRIGUPDATE_COUNT)
                 begin	
                     to_trigupdate_counter <= to_trigupdate_counter + 1'd1;				 
		             trigger_to_host_flag <= 1'b0;
			     end
		         else
		            trigger_to_host_flag <= 1'b1;
			 end
			 else
			 begin
			     trigger_to_host_flag <= 1'b0;
				 to_trigupdate_counter <= 0;
			 end
	     end
    end



endmodule
