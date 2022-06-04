//------------------------------------------------------------------------
// active_transfer.v
// 
//------------------------------------------------------------------------
// 
// Copyright (c) 2012 Earth People Technology Incorporated
// $Rev: 100 $ $Date: 2012-06-10 16:03:57 -0800 (Sun, 10 June 2012) $
//------------------------------------------------------------------------
`include "../src/define.v"

`timescale 1ns/1ps

module active_transfer (
	input  wire         uc_clk,
	input  wire         uc_reset,
	input  wire [`UC_IN_END:`UC_IN_START]  uc_in,
	output wire [`UC_OUT_END:`UC_OUT_START]  uc_out,
	
	input  wire         start_transfer,
	output reg          transfer_received,
	
	output reg         transfer_busy,
	
	input  wire  [`EPT_ADDRESS_END:`EPT_ADDRESS_START]  uc_addr,

	input  wire  [`UC_DATAIN_END:`UC_DATAIN_START]  transfer_to_host,
	output reg   [`UC_DATAOUT_END:`UC_DATAOUT_START]  transfer_to_device
	);

   //-----------------------------------------------
   // Parameters
   //-----------------------------------------------
	//Transfer In State Machine
	parameter IN_IDLE                   = 0,
			IN_READ_CMD                 = 1,
			IN_READ_BYTE                = 2,
            IN_DELAY                    = 3;

   //-----------------------------------------------
   // Internal Signals
   //-----------------------------------------------
 	reg 	[3:0]                        state_in, next_in;
  
   // Tranfer to Device registers
	reg                 transfer_to_device_reset;
	
   // Transfer to Host registers
    reg                 start_transfer_in;
	reg                 to_transfer_update;
	reg                 transfer_to_device_meta;
	reg                 start_transfer_reg;
	reg [3:0]           start_transfer_count;
	
	//Transfer busy registers
	reg [1:0]           transfer_busy_reg;

`ifdef SIM
   reg [8*26:1] state_name;
`endif
	
	//-----------------------------------------------
   // Assignments
   //-----------------------------------------------
    assign uc_out[`UC_DATAOUT_END:`UC_DATAOUT_START]  = to_transfer_update ? transfer_to_host : 8'h0;
	assign uc_out[`UC_CMD_END:`UC_CMD_START]          = to_transfer_update ? `TRANSFER_OUT_CMD : 3'h0;
	assign uc_out[`UC_ADDRESS_END:`UC_ADDRESS_START]  = to_transfer_update ? uc_addr : 3'h0;
	assign uc_out[`UC_LENGTH_END:`UC_LENGTH_START]    = 8'h0;

   //-----------------------------------------------
   // Transfer Out, transfer busy
   //-----------------------------------------------
    always @(posedge uc_clk or negedge uc_reset) 
	begin
	  if (!uc_reset)
      begin
		     transfer_busy <= 1'b0;
		     transfer_busy_reg <= 2'b00;
      end 
     else 
     begin
	       if((start_transfer_in | start_transfer_reg | transfer_received) & (transfer_busy == 2'b00))
		   begin
                 transfer_busy <= 1'b1;
		         transfer_busy_reg <= 2'b01;
		   end
		   else if(uc_in[`UC_IN_BUSY] & (transfer_busy_reg == 2'b01))
		   begin
		         transfer_busy <= 1'b1;
		         transfer_busy_reg <= 2'b10;
		   end
		   else if(!uc_in[`UC_IN_BUSY] & (transfer_busy_reg == 2'b10))
		   begin
		        transfer_busy <= 1'b0;
		        transfer_busy_reg <= 2'b00;
		   end
      end
	 end
   //-----------------------------------------------
   // Single Transfer In  transfer_received 
   //-----------------------------------------------
    always @(posedge uc_clk or negedge uc_reset) 
	begin
	  if (!uc_reset)
      begin
		     transfer_to_device <= 0;	
		     transfer_received <= 1'b0;
      end 
     else 
     begin
		if(state_in[IN_READ_BYTE])
		begin
             transfer_received <= 1'b1;
			 transfer_to_device <= uc_in[`UC_DATAIN_END:`UC_DATAIN_START];
		end
		else if(state_in[IN_IDLE])
		    transfer_received <= 1'b0;
	 end
	end
	

   //-----------------------------------------------
   // Transfer to Device Detection
   // parameter IN_IDLE                   = 0,
   //			IN_READ_CMD                 = 1,
   //			IN_READ_BYTE                = 2,
   //			IN_DELAY                    = 3;
   //
   //-----------------------------------------------
   // Next State Logic
   always @(posedge uc_clk or negedge uc_reset)
     begin
		if (!uc_reset)
		begin
			state_in <= 4'h00;
			state_in[IN_IDLE] <= 1'b1;
		end
		else
			state_in <= next_in;
	end

     // State Definitions
   always @ ( state_in or uc_in or uc_addr)
     begin
	next_in = 4'h00;

	if (state_in[IN_IDLE])
	  begin
	     if (uc_in[`UC_ADDRESS_END:`UC_ADDRESS_START] == uc_addr)
	       next_in[IN_READ_CMD] = 1'b1;
         else		 
	       next_in[IN_IDLE] = 1'b1;
	  end

	
	if (state_in[IN_READ_CMD])
	  begin
		if (uc_in[`UC_CMD_END: `UC_CMD_START] == `TRANSFER_IN_CMD)
			next_in[IN_READ_BYTE] = 1'b1;
		else 
			next_in[IN_READ_CMD] = 1'b1;
	  end

	if ( state_in[IN_READ_BYTE] )
	begin
		next_in[IN_DELAY] = 1'b1;	
	end

	if (state_in[IN_DELAY])
	begin
	    next_in[IN_IDLE] = 1'b1;
	end


	`ifdef SIM
	   if ( state_in == ( 1 << IN_IDLE ))
		   state_name = "IN_IDLE";
	   else if ( state_in == ( 1 << IN_READ_CMD ))
		   state_name = "IN_READ_CMD";
	   else if ( state_in == ( 1 << IN_READ_BYTE ))
		   state_name = "IN_READ_BYTE";
	   else if ( state_in == ( 1 << IN_DELAY ))
		   state_name = "IN_DELAY";
`endif

	end//end of state_in machine
/*    always @(uc_in or transfer_to_device_reset or uc_reset) 
	begin
	     if (!uc_reset)
		 begin
		     transfer_to_device = 0;	
             transfer_received = 1'b0;			 
		 end
		 else if(transfer_to_device_reset)
		     transfer_received = 1'b0;	
		 else if(uc_in[`UC_ADDRESS_END:`UC_ADDRESS_START] == uc_addr)
		 begin
		     if(uc_in[`UC_CMD_END: `UC_CMD_START] == `TRANSFER_IN_CMD)
			 begin
			     transfer_to_device = uc_in[`UC_DATAIN_END:`UC_DATAIN_START];
			     transfer_received = 1'b1;
			 end
		 end
    end
*/
   //-----------------------------------------------
   // Transfer to Device Reset 
   //-----------------------------------------------
/*    always @(posedge uc_clk or negedge uc_reset) 
	begin
	     if (!uc_reset)
		 begin
		     transfer_to_device_meta <= 1'b0;
		     transfer_to_device_reset <= 1'b0;
	     end 
		 else 
		 begin
		         transfer_to_device_reset <= 1'b0;
             //if(transfer_received )	
             if(transfer_received & (uc_in == 0))	
             begin			 
		         transfer_to_device_meta <= 1'b1;
		         transfer_to_device_reset <= transfer_to_device_meta;
			 end
		     else
			 begin
		         transfer_to_device_meta <= 1'b0;
			 end
	     end
    end
*/
    //-------------------------------------------------
	// Register the Start Transfer Signal Transfer to Host
	//-------------------------------------------------
    always @(posedge uc_clk or negedge uc_reset)
	begin
	  if(!uc_reset)
	  begin
	     start_transfer_in <= 1'b0;
	  end
	  else
	  begin
	       if(start_transfer)
	           start_transfer_in <= 1'b1;
		    else 
			   start_transfer_in <= 1'b0;
	  end
	end

    //-------------------------------------------------
	// Transfer To Host registers
	//-------------------------------------------------
    always @(posedge uc_clk or negedge uc_reset)
	begin
	  if(!uc_reset)
	  begin
	     start_transfer_reg <= 1'b0;
		 to_transfer_update <= 1'b0;
		 start_transfer_count <= 0;
	  end
	  else
	  begin
	       if(start_transfer_in & !start_transfer_reg)
		   begin
	           start_transfer_reg <= 1'b1;
		       to_transfer_update <= 1'b1;
		   end
		    else if(start_transfer_in & start_transfer_reg)
			begin
			   if(start_transfer_count < 4'h2)
			      start_transfer_count <= start_transfer_count + 1'd1;
				else
				begin
			       start_transfer_reg <= 1'b1;
			       to_transfer_update <= 1'b0;
				end
			end
		    else if(!start_transfer_in & start_transfer_reg)
			begin
			   start_transfer_reg <= 1'b0;
			   to_transfer_update <= 1'b0;
				start_transfer_count <= 0;
			end
		    //else 
			//begin
			//   start_transfer_reg <= 1'b0;
			//   to_transfer_update <= 1'b0;
			//end
	  end
	end



endmodule
