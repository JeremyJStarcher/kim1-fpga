//------------------------------------------------------------------------
// active_block.v
// 
//------------------------------------------------------------------------
// 
// Copyright (c) 2012 Earth People Technology Incorporated
// $Rev: 1.00 $ $Date: 2012-06-15 21:48:32 -0800 (Fri, 15 June 2012) $
//
// Rev 1.1   11/11/2012
//           RJJ    Added transfer_busy net, dervied from UC_IN[23].
//                  Signals that the endpoint_registers.v state machine
//                  has completed the transfer in.
//
//------------------------------------------------------------------------
`include "../src/define.v"

`timescale 1ns/1ps

module active_block (
	input  wire         uc_clk,
	input  wire         uc_reset,
	input  wire [`UC_IN_END:`UC_IN_START]  uc_in,
	output reg  [`UC_OUT_END:`UC_OUT_START]  uc_out,

	input  wire         start_transfer,
	output reg          transfer_received,
	
	output wire         transfer_ready,
	output wire         transfer_busy,
	
	output reg   [`EPT_LENGTH_END:`EPT_LENGTH_START]    ept_length,

	input  wire  [`EPT_ADDRESS_END:`EPT_ADDRESS_START]  uc_addr,
	input  wire  [`EPT_LENGTH_END:`EPT_LENGTH_START]    uc_length,

	input  wire  [`UC_DATAIN_END:`UC_DATAIN_START]      transfer_to_host,
	output reg   [`UC_DATAOUT_END:`UC_DATAOUT_START]    transfer_to_device//,
	
	);

   //-----------------------------------------------
   // Parameters
   //-----------------------------------------------
   //Block Out State Machine
   parameter   IDLE                    = 0,
			    SEND_COMMAND           = 1,
			    TRANSFER_BYTE          = 2,
			    END_TRANSFER           = 3;
				
	//Block In State Machine
	parameter IN_IDLE                   = 0,
			IN_READ_CMD                 = 1,
			IN_READ_LENGTH              = 2,
			IN_CHECK_COUNT              = 3,
			IN_READ_BYTE                = 4,
            IN_DELAY                    = 5;

   //-----------------------------------------------
   // Internal Signals
   //-----------------------------------------------
	reg 	[5:0]                        state_in, next_in;
   
   // Tranfer to Device registers
	reg  [7:0]                 transfer_received_count;
	
	//State Machine registers
	reg [3:0]                  block_transfer_state;
	reg [7:0]                  data_count;
	reg [1:0]                  block_transfer_state_counter;

`ifdef SIM
   reg [8*26:1] state_name;
`endif
	
   //-----------------------------------------------
   // Assignments
   //-----------------------------------------------
   assign transfer_ready = uc_in[`UC_IN_FIFO_EN];
   assign transfer_busy = uc_in[`UC_IN_BUSY];

   //-----------------------------------------------
   // Block Transfer In  ept_length 
   //-----------------------------------------------
    always @(posedge uc_clk or negedge uc_reset) 
	begin
	  if (!uc_reset)
      begin
		     ept_length <= 0;
      end 
     else 
     begin
		if(state_in[IN_READ_LENGTH])
             ept_length <= uc_in[`UC_LENGTH_END:`UC_LENGTH_START];
		else
		    ept_length <= ept_length;
	 end
	end
	
   //-----------------------------------------------
   // Block Transfer In  transfer_received 
   //-----------------------------------------------
    always @(posedge uc_clk or negedge uc_reset) 
	begin
	  if (!uc_reset)
      begin
		     transfer_received <= 1'b0;
      end 
     else 
     begin
		if(state_in[IN_READ_LENGTH])
             transfer_received <= 1'b1;
		else if(state_in[IN_IDLE])
		    transfer_received <= 1'b0;
	 end
	end
	
   //-----------------------------------------------
   // Block Transfer In  transfer_received_counter
   //-----------------------------------------------
    always @(posedge uc_clk or negedge uc_reset) 
	begin
	     if (!uc_reset)
		 begin
		     transfer_received_count <= 0;
	     end 
		 else 
		 begin
             if(state_in[IN_READ_BYTE] & transfer_ready)	
             begin
		         transfer_received_count <= transfer_received_count + 1'b1;
			     transfer_to_device = uc_in[`UC_DATAIN_END:`UC_DATAIN_START];
			 end
		     else if(state_in[IN_DELAY])
			 begin
		         transfer_received_count <= 0;
			 end
	     end
    end

   
   //-----------------------------------------------
   // Block Transfer In, Finite State Machine
/*	parameter IN_IDLE                   = 0,
			IN_READ_CMD                 = 1,
			IN_READ_LENGTH              = 2,
			IN_CHECK_COUNT              = 3,
			IN_READ_BYTE                = 4,
			IN_DELAY                    = 5;
*/
   //-----------------------------------------------
   // Next State Logic
   always @(posedge uc_clk or negedge uc_reset)
     begin
		if (!uc_reset)
		begin
			state_in <= 6'h00;
			state_in[IN_IDLE] <= 1'b1;
		end
		else
			state_in <= next_in;
	end

     // State Definitions
   always @ ( state_in or uc_in or transfer_ready or transfer_received_count or
             ept_length or uc_addr)
     begin
	next_in = 6'h00;

	if (state_in[IN_IDLE])
	  begin
	     if((uc_in[`UC_ADDRESS_END:`UC_ADDRESS_START] == uc_addr)
		     & (uc_in[`UC_CMD_END:`UC_CMD_START] == `BLOCK_IN_CMD))
	       next_in[IN_READ_CMD] = 1'b1;
         else		 
	       next_in[IN_IDLE] = 1'b1;
	  end

	
	if (state_in[IN_READ_CMD])
	  begin
		if (uc_in[`UC_CMD_END: `UC_CMD_START] == `BLOCK_IN_CMD)
			next_in[IN_READ_LENGTH] = 1'b1;
		else 
			next_in[IN_READ_CMD] = 1'b1;
	  end

	if ( state_in[IN_READ_LENGTH] )
	begin
			next_in[IN_CHECK_COUNT] = 1'b1;	
	end

	if ( state_in[IN_READ_BYTE] )
	begin
		if ( transfer_ready )
		begin
			 next_in[IN_CHECK_COUNT] = 1'b1;	
 		end
		else
	       next_in[IN_READ_BYTE] = 1'b1;
	end

	if ( state_in[IN_CHECK_COUNT] )
	begin
	     if(transfer_received_count < ept_length)
		begin
			 next_in[IN_READ_BYTE] = 1'b1;	
 		end
		else
	       next_in[IN_DELAY] = 1'b1;
	end

	if (state_in[IN_DELAY])
	begin
         if (transfer_received_count == 0)
	       next_in[IN_IDLE] = 1'b1;
		else
	       next_in[IN_DELAY] = 1'b1;
	end


	`ifdef SIM
	   if ( state_in == ( 1 << IN_IDLE ))
		   state_name = "IN_IDLE";
	   else if ( state_in == ( 1 << IN_READ_CMD ))
		   state_name = "IN_READ_CMD";
	   else if ( state_in == ( 1 << IN_READ_LENGTH ))
		   state_name = "IN_READ_LENGTH";
	   else if ( state_in == ( 1 << IN_CHECK_COUNT ))
		   state_name = "IN_CHECK_COUNT";
	   else if ( state_in == ( 1 << IN_READ_BYTE ))
		   state_name = "IN_READ_BYTE";
	   else if ( state_in == ( 1 << IN_DELAY ))
		   state_name = "IN_DELAY";
`endif

	end//end of state_in machine

   //-----------------------------------------------
   // Block Transfer to Host UC_OUT Vector stuffing 
   //-----------------------------------------------
    always @(block_transfer_state or uc_addr or uc_length or uc_reset) 
	begin
	     if (!uc_reset)
		 begin
             uc_out[`UC_CMD_END:`UC_CMD_START]          = 0;
             uc_out[`UC_ADDRESS_END:`UC_ADDRESS_START]  = 0;
             uc_out[`UC_LENGTH_END:`UC_LENGTH_START]    = 0;
		 end
	     else if(block_transfer_state == SEND_COMMAND)
		 begin
             uc_out[`UC_CMD_END:`UC_CMD_START]          = `BLOCK_OUT_CMD;
             uc_out[`UC_ADDRESS_END:`UC_ADDRESS_START]  = uc_addr;
             uc_out[`UC_LENGTH_END:`UC_LENGTH_START]    = uc_length;
		 end
		 else if(block_transfer_state == TRANSFER_BYTE)
		 begin
             uc_out[`UC_CMD_END:`UC_CMD_START]          = `TRANSFER_OUT_CONTINUATION_CMD;
             uc_out[`UC_ADDRESS_END:`UC_ADDRESS_START]  = uc_addr;
             uc_out[`UC_LENGTH_END:`UC_LENGTH_START]    = uc_length;
		 end
		 else if(block_transfer_state == END_TRANSFER)
		 begin
             uc_out[`UC_CMD_END:`UC_CMD_START]          = `TRANSFER_OUT_CONTINUATION_CMD;
             uc_out[`UC_ADDRESS_END:`UC_ADDRESS_START]  = uc_addr;
             uc_out[`UC_LENGTH_END:`UC_LENGTH_START]    = uc_length;
		 end
		 else 
		 begin
             uc_out[`UC_CMD_END:`UC_CMD_START]          = 0;
             uc_out[`UC_ADDRESS_END:`UC_ADDRESS_START]  = 0;
             uc_out[`UC_LENGTH_END:`UC_LENGTH_START]    = 0;
		 end
	end

   //-----------------------------------------------
   // Block Transfer to Host Byte Transfer 
   //-----------------------------------------------
    always @(posedge uc_clk or negedge uc_reset) 
	begin
	  if (!uc_reset)
	  begin
             uc_out[`UC_DATAOUT_END:`UC_DATAOUT_START]    <= 0;
		     data_count <= 0;
	  end 
	  else
	  begin
		 case(block_transfer_state) 
		     SEND_COMMAND :
		          data_count <= uc_length;
		     TRANSFER_BYTE :
		     begin
             	 if(uc_in[`UC_IN_FIFO_EN] )
                 begin			 
                     uc_out[`UC_DATAOUT_END:`UC_DATAOUT_START]    <= transfer_to_host;
				     if(data_count > 0)
		                 data_count <= data_count - 1'd1;
			     end
		         //else
			     //begin
                 //    uc_out[`UC_DATAOUT_END:`UC_DATAOUT_START]    <= 0;
			     //end
			
	         end
			 END_TRANSFER:
			    uc_out[`UC_DATAOUT_END:`UC_DATAOUT_START]    <= transfer_to_host;
			 //default: 
			 //begin
             //   uc_out[`UC_DATAOUT_END:`UC_DATAOUT_START]    <= 0;
		     //end
		 endcase
	  end
    end

   //-----------------------------------------------
   // Block Transfer to Host State Machine 
   //-----------------------------------------------
    always @(posedge uc_clk or negedge uc_reset) 
	begin
	     if (!uc_reset)
		 begin
             block_transfer_state <= IDLE;
			 block_transfer_state_counter <= 0;
	     end 
		 else 
		 begin
		     case(block_transfer_state)
			 IDLE:
			 begin
			     block_transfer_state_counter <= 0;
                 if(start_transfer)
		             block_transfer_state <= SEND_COMMAND;
		         else
		             block_transfer_state <= IDLE;
			 end
			 SEND_COMMAND:
			 begin
			     if(block_transfer_state_counter > 2'h0)
		             block_transfer_state <= TRANSFER_BYTE;
				 else
				     block_transfer_state_counter <= block_transfer_state_counter + 1'd1;
			 end
			 TRANSFER_BYTE:
			 begin
                 if(data_count > 0)		 
		             block_transfer_state <= TRANSFER_BYTE;
		         else
		             block_transfer_state <= END_TRANSFER;
			 end
			 END_TRANSFER:
			 begin
			    if(!transfer_busy)
		         block_transfer_state <= IDLE;
			 end
			 endcase
	     end
    end



endmodule

