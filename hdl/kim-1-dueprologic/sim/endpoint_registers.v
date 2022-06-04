//------------------------------------------------------------------------
// endpoint_registers.v
// 
//------------------------------------------------------------------------
// 
// Copyright (c) 2014 Earth People Technology Incorporated
// $Rev: 100 $ $Date: 2012-05-31 23:49:17 -0800 (Thur, 31 May 2012) $
//
// Rev 1.1   11/11/2012
//           RJJ    Added transfer_busy net to UC_IN[23].
//                  Signals that the endpoint_registers.v state machine
//                  has completed the transfer in.
//
// Rev 1.5   1/6/2014
//           RJJ    Recompiled for ft_245_state_machine.v
//                  
// Rev 1.6   06/14/14
//           RJJ   Added uc_in_address = 0; to READ Register decode logic
//                 section  in the case( command_to_device ) under the
//			       `TRIGGER_IN_CMD case statement
//                  
// Rev 1.7   5/31/14
//           RJJ   Changed command_to_device to equal control_multiplexor[5:3] and
//                 address_to_device to equal control_multiplexor[2:0]. Added 
//                 address_to_device and command_to_device to the State Machine
//                 sensitivity list.
// Rev 1.8   5/31/15
//                 Added ENDPOINT_BUSY
// Rev 1.9   6/2/15
//                 Added FT_245_SM_BUSY
//
//------------------------------------------------------------------------
`include "../src/define.v"

`timescale 1ns/1ps


module	endpoint_registers
	(	
	input wire                                      CLK,
	input wire                                      RST_N,
	
	input wire [`UC_DATAIN_END:`UC_DATAIN_START] ENDPOINT_DECODE,
	
	input wire                                      DATA_BYTE_READY,
	output wire                                     ENDPOINT_EN,
	output wire                                     ENDPOINT_BUSY,
	input wire                                      FT_245_SM_BUSY,
	
	output reg                                      WRITE_EN,
	input wire                                      WRITE_READY,
	output reg [`UC_DATAOUT_END:`UC_DATAOUT_START]  WRITE_BYTE,
	input wire                                      WRITE_COMPLETE,

	output  wire [`UC_IN_END:`UC_IN_START]          UC_IN,
	input wire [`UC_OUT_END:`UC_OUT_START]          UC_OUT,
	
	
	output wire [7:0]                               TEST_OUT,
	output reg [3:0]                                STATE_OUT
	);
	
	//----------------------------------------------
   // Parameter Declarations  
   //----------------------------------------------
   parameter IDLE						= 0,
			DECODE_BYTE		 			= 1,
			READ_CONTROL_BYTE	 		= 2,
			READ_DATA_BYTE				= 3,
			WAIT_FIFO_READY				= 4,
			//DECODE_BYTE_FAIL			= 5,
			WRITE_CONTROL_BYTE			= 6,
			WRITE_CONTROL_BYTE_DELAY	= 7,
			WRITE_CONTROL_COMPLETE		= 8;
			
   //------------------------------------------------
   // Wire and Register Declarations                
   //------------------------------------------------
	reg 	[8:0]                        state, next;
	
	//byte_count 
	reg	[7:0]                            byte_count;

	//Decode Byte multiplexor
	reg	[7:0]                            control_multiplexor;

	//Register to store the decode value
	wire                                 command_byte;

	//Write byte control registers
	reg	[8:0]                            write_control_mux;
	reg                                  write_control_mux_reg;
	reg                                  write_en_reg;
	reg                                  write_data_byte;

	//Registers for the state[DECODE_BYTE_FAIL]
	//reg                                  decode_byte_fail_reg;
	//reg	[3:0]                            decode_byte_fail_count;

    // Registers to convert UC_IN bits for USB transfer message
    wire [2:0]                           device;
    reg [2:0]                            command_from_device;
    reg [7:0]                            length_from_device;
    reg [2:0]                            address_from_device;
    reg [7:0]                            payload_from_device;
    reg [7:0]                            uc_in_payload;
    reg [2:0]                            uc_in_command;
    reg [2:0]                            uc_in_address;
    reg [7:0]                            uc_in_length;

	// Register to start the write to Host state machine
    reg                                  write_to_host;	
	reg                                  write_to_host_delay;
	reg                                  write_to_host_reg;
	
	// Registers from FT2232H to Device
	wire [2:0]                           command_to_device;
	wire [2:0]                           address_to_device;
	reg [7:0]                            length_to_device;
	
	// Registers for the Block Transfer
	reg                                  block_read_byte;
	reg                                  byte_count_reg;
	reg                                  transfer_busy;
	reg [2:0]                            data_byte_ready_delay_cnt;
 
    // Reset Registers
	reg                                  reset_uc_in;
	reg                                  reset_uc_in_reg;
	reg [3:0]                            reset_uc_in_counter;

    // UC_OUT meta stability registers	
	reg [3:0]                            uc_out_command;
	reg [3:0]                            uc_out_command_meta;

	//Test registesr
	reg                                  state_out_reg;
	//reg                                  write_to_host_hold;

`ifdef SIM
   reg [8*26:1] state_name;
`endif

   //--------------------------------------------------
   // Signal Assignments
   //--------------------------------------------------   
	assign		command_byte	=	((byte_count == 0) && (ENDPOINT_DECODE[7:6] == 2'b10)) ? 1'b1 : 1'b0;

	assign  command_to_device = control_multiplexor[5:3];
	assign  address_to_device = control_multiplexor[2:0];
	
	//Register to indicate to the ft_245_state_machine that a write to the
	//FT chip is in process. The read from the FT chip should be delayed until
	// the write is complete.
	assign ENDPOINT_BUSY = write_to_host | transfer_busy;
	
	assign UC_IN[`UC_IN_BUSY] = transfer_busy;
	assign UC_IN[`UC_IN_FIFO_EN] = (state[WRITE_CONTROL_COMPLETE] & (command_from_device == `TRANSFER_OUT_CONTINUATION_CMD) & write_data_byte) | (state[READ_DATA_BYTE] & (byte_count > 8'h3) & reset_uc_in) ? 1'b1 : 1'b0;
	assign UC_IN[`UC_PAYLOAD_END:`UC_PAYLOAD_START] = reset_uc_in ? uc_in_payload : 0;
	assign UC_IN[`UC_CMD_END:`UC_CMD_START] = reset_uc_in ? uc_in_command : 0;
	assign UC_IN[`UC_ADDRESS_END:`UC_ADDRESS_START] = reset_uc_in ? uc_in_address : 0;
	assign UC_IN[`UC_LENGTH_END:`UC_LENGTH_START] = reset_uc_in ? uc_in_length : 0;
	
	
	//TEST ONLY
	assign TEST_OUT[5:0] = control_multiplexor;
	assign TEST_OUT[7:6] = 2'h0;
	
   //-----------------------------------------------
   // Create the ENDPOINT_EN register for Hand Shaking
   // with ft_245_state_machine.v
   //-----------------------------------------------
   assign ENDPOINT_EN = ( state[READ_CONTROL_BYTE] || state[READ_DATA_BYTE] /*|| 
                          state[DECODE_BYTE_FAIL]*/ ) ? 1'b1 : 1'b0;

   //-----------------------------------------------
   // Create a State Test Output Signal
   //-----------------------------------------------
   always @(posedge CLK or negedge RST_N)
   begin
	if (!RST_N)
	begin
	  STATE_OUT <= 0;
	end
	else
	  begin
	     if (state[IDLE])
            STATE_OUT <= 4'h0;
	     if (state[DECODE_BYTE])
	       STATE_OUT <= 4'h1;
	     if (state[READ_CONTROL_BYTE])
	       STATE_OUT <= 4'h2;
	     if (state[READ_DATA_BYTE])
	       STATE_OUT <= 4'h3;
	     if (state[WAIT_FIFO_READY])
	       STATE_OUT <= 4'h4;
	     //if (state[DECODE_BYTE_FAIL])
	     //  STATE_OUT <= 4'h5;
	     if (state[WRITE_CONTROL_BYTE])
	       STATE_OUT <= 4'h6;
	     if (state[WRITE_CONTROL_BYTE_DELAY])
	       STATE_OUT <= 4'h7;
	     if (state[WRITE_CONTROL_COMPLETE])
	       STATE_OUT <= 4'h8;
	  end // else: !if(!RST_N)
     end // always @ (posedge CLK or negedge RST_N)


   //-----------------------------------------------
   // Detect Trigger To Host 
   // 
   //
   //      UC_IN Bit         Description
   //         22             Block Transfer - byte ready
   //         21             Command - Block Transfer
   //         20             Command - Single Transfer
   //         19             Command - Trigger
   //         18             Length[7]
   //         17             Length[6]
   //         16             Length[5]
   //         15             Length[4]
   //         14             Length[3]
   //         13             Length[2]
   //         12             Length[1]
   //         11             Length[0]
   //         10             Address[2]
   //          9             Address[1]
   //          8             Address[0]
   //          [7:0]         Transfer Byte
   //-----------------------------------------------
  always @(posedge CLK or negedge RST_N)
  begin
	if (!RST_N)
	begin
		write_to_host <= 1'b0;
        write_to_host_delay <= 1'b0;
		write_to_host_reg <= 0;
        command_from_device <= 0;
        length_from_device <=  0;
        address_from_device <= 0;
        payload_from_device <= 0;
	end
	else
	begin 
	     if((UC_OUT[`UC_CMD_END:`UC_CMD_START] > 3'h0) & !write_to_host_reg)
		 begin
		     if(UC_OUT[`UC_CMD_END:`UC_CMD_START] != 3'h6)
			 begin
			    if(FT_245_SM_BUSY)
				begin
                   write_to_host <= 1'b0;
                   write_to_host_delay <= 1'b1;
                   write_to_host_reg <= 1'b0;
				end
				else
				begin
                   write_to_host <= 1'b1;
                   write_to_host_reg <= 1'b1;
			    end
			 end
             command_from_device <= UC_OUT[`UC_CMD_END:`UC_CMD_START];
             length_from_device <=  UC_OUT[`UC_LENGTH_END:`UC_LENGTH_START];
             address_from_device <= UC_OUT[`UC_ADDRESS_END:`UC_ADDRESS_START];
             payload_from_device <= UC_OUT[`UC_PAYLOAD_END:`UC_PAYLOAD_START];
		 end
         else if(write_to_host_delay)
		 begin
		    if(!FT_245_SM_BUSY)
			begin
                   write_to_host <= 1'b1;
                   write_to_host_delay <= 1'b0;
                   write_to_host_reg <= 1'b1;
			end
		 end
         else if(state[WRITE_CONTROL_COMPLETE] & write_to_host_reg)
		 begin
             write_to_host <= 1'b0;
             write_to_host_delay <= 1'b0;
             write_to_host_reg <= 1'b0;
		 end
	end
  end
  
   //-----------------------------------------------
   // Transfer Busy Register
   //-----------------------------------------------
   always @(state[WRITE_CONTROL_BYTE] or state[IDLE])
   begin
       if(state[IDLE])
           transfer_busy = 1'b0;
	   else if(state[WRITE_CONTROL_BYTE])
	       transfer_busy = 1'b1;
   end

   //-----------------------------------------------
   // WRITE_EN output
   // 
   //-----------------------------------------------
   always @(posedge CLK or negedge RST_N)
     begin
	if (!RST_N)
	begin
				WRITE_EN <= 0;
				write_en_reg <= 0;
	end
	else
	begin
		if ( state[WRITE_CONTROL_BYTE] && !write_en_reg)
		begin
			WRITE_EN <= 1;
			write_en_reg <= 1;
		end
		else if ( WRITE_READY && write_en_reg)
		begin
				WRITE_EN <= 0;
				write_en_reg <= 0;
		end
     end
	end

   //-----------------------------------------------
   // This section allows the current value of the 
   // selected register to be transmitted to the 
   // the ft_245_state_machine.v.
   //-----------------------------------------------
   always @(posedge CLK or negedge RST_N)
   begin
	if (!RST_N)
	begin
		    write_control_mux_reg <= 1'b0;
			write_control_mux <= 0;
			WRITE_BYTE <= 0;
			write_data_byte <= 1'b1;
	end
	else
	begin
		if ( state[WRITE_CONTROL_BYTE] & !write_control_mux_reg )
		begin
		    write_control_mux_reg <= 1'b1;
			write_control_mux <= write_control_mux + 1'd1;
		end
		else if ( state[WRITE_CONTROL_COMPLETE] & write_control_mux_reg )
		begin
		    write_control_mux_reg <= 1'b0;
			write_control_mux <= write_control_mux;
		end
		else if ( state[IDLE] )
		begin
		    write_control_mux_reg <= 1'b0;
			write_control_mux <= 0;
		end
			
		case( write_control_mux )
			9'h01:
			begin
					WRITE_BYTE <= {2'b11,command_from_device,address_from_device};
					write_data_byte <= 1'b1;
			end
			9'h02:
			begin
			     if((command_from_device == `TRIGGER_OUT_CMD) |
				     (command_from_device == `TRANSFER_OUT_CMD))
				 begin
					     WRITE_BYTE <= payload_from_device;
					     write_data_byte <= 1'b0;
				 end
				 else
				 begin
					WRITE_BYTE <= length_from_device;
					write_data_byte <= 1'b1;
				 end
			end
			9'h03:
			begin
					WRITE_BYTE <= payload_from_device;
			end
			default:	
			begin
					WRITE_BYTE <= payload_from_device;
					if((write_control_mux - 8'h2) < length_from_device)
					     write_data_byte <= 1'b1;
					else
					     write_data_byte <= 1'b0;
			end
		endcase
		
	end 
     end 
 
   //-----------------------------------------------
   // Store control_multiplexor at state[READ_CONTROL_BYTE]
   //-----------------------------------------------
   always @(posedge CLK or negedge RST_N)
   begin
	if (!RST_N)
	begin
			control_multiplexor <= 0;
	end
	else
	begin
		if ( state[READ_CONTROL_BYTE] )
			control_multiplexor <= ENDPOINT_DECODE;
		else
			control_multiplexor <= control_multiplexor;
			
	end
	end
	
   //-----------------------------------------------
   // Reset UC_IN 
   //-----------------------------------------------
   always @(posedge CLK or negedge RST_N)
   begin
		if (!RST_N)
		begin
			reset_uc_in <= 1'b0;
			reset_uc_in_reg <= 1'b0;
			reset_uc_in_counter <= 0;
		end
		else 
		begin
			if (state[READ_DATA_BYTE] & !reset_uc_in_reg)
			begin
			    reset_uc_in <= 1'b1;
			     reset_uc_in_reg <= 1'b1;
			end
			else if(reset_uc_in_reg)
			begin
				 if(reset_uc_in_counter < 4'h2)
				 begin
				     reset_uc_in_counter <= reset_uc_in_counter + 1'd1;
				 end
			     else 
			     begin
			         reset_uc_in <= 1'b0;
			         reset_uc_in_reg <= 1'b0;
					 reset_uc_in_counter <= 0;
			     end
		    end
		end
	end

   //-----------------------------------------------
   // READ Register decode logic
   //-----------------------------------------------
   always @(posedge CLK or negedge RST_N)
   begin
	if (!RST_N)
	begin
	     uc_in_payload = 0;
	     uc_in_command = 0;
	     uc_in_address = 0;
		 uc_in_length = 0;
		 block_read_byte = 1'b0;
	end
	else 
	if ( state[READ_DATA_BYTE] )
	begin	
		case( command_to_device )
			`TRIGGER_IN_CMD:
			begin
			        uc_in_payload = ENDPOINT_DECODE;
					uc_in_command = command_to_device;
			end
			`TRANSFER_IN_CMD:
			begin
			        uc_in_payload = ENDPOINT_DECODE;
					uc_in_address = address_to_device;
					uc_in_command = command_to_device;
			end
			`BLOCK_IN_CMD:
			begin 
			     case(byte_count)
				 //8'h0:
				 //8'h1:
				 8'h2:
				 begin
				    uc_in_payload  = ENDPOINT_DECODE;
					uc_in_address = address_to_device;
					uc_in_length  = length_to_device;
					uc_in_command = command_to_device;
				 end
				 8'h3:
				 begin
				    length_to_device = ENDPOINT_DECODE;
			        uc_in_payload = uc_in_payload;
					uc_in_address = address_to_device;
					uc_in_length  = ENDPOINT_DECODE;
					uc_in_command = command_to_device;
					block_read_byte = 1'b1;
				 end
				 default:
				 begin
			        uc_in_payload = ENDPOINT_DECODE;
					uc_in_address = address_to_device;
					uc_in_length  = length_to_device;
					uc_in_command = command_to_device;
				 end
				 endcase
			end
			default:	
			begin
	             uc_in_payload = uc_in_payload;
	             uc_in_command = uc_in_command;
	             uc_in_address = uc_in_address;
		         uc_in_length  = uc_in_length;
			end
		endcase
		end
		else if (state[IDLE])
		begin
			block_read_byte = 1'b0;
		end
    end 

   //-----------------------------------------------
   // Increment the byte_count 
   //-----------------------------------------------
   always @(posedge CLK or negedge RST_N)
     begin
		if (!RST_N)
		begin
			byte_count <= 1'b0;
			byte_count_reg <= 1'b0;
		end
		else
		begin
			if ( state[DECODE_BYTE] & ( command_byte ) & ( byte_count == 0 ))
				byte_count <= 4'h2;
			else if(state[DECODE_BYTE] & !command_byte & !block_read_byte)
				byte_count <= byte_count + 1'd1;
			else if ((state[WAIT_FIFO_READY] & (byte_count >= 4'h3)) & block_read_byte & !byte_count_reg)
			begin
				byte_count <= byte_count + 1'd1;
				byte_count_reg <= 1'b1;
			end
			else if (state[READ_DATA_BYTE] & byte_count_reg)
			    byte_count_reg <= 1'b0;
			else if (( state[IDLE] & ( byte_count >= 4'h3 )))
				byte_count <= 4'h0;
		end // else: !if(!RST_N)
     end // always @ (posedge CLK or negedge RST_N)

   //-----------------------------------------------
   // Register for the data_byte_ready_delay. This will allow
   // state[READ_DATA_BYTE] to assert for one extra clock
   //-----------------------------------------------
   always @(posedge CLK or negedge RST_N)
   begin
	if (!RST_N)
	begin
			data_byte_ready_delay_cnt <= 0;
	end
	else
	begin
		if ( state[READ_DATA_BYTE] )
			data_byte_ready_delay_cnt <= data_byte_ready_delay_cnt + 1;
		else if ( state[WAIT_FIFO_READY] )
		begin
			data_byte_ready_delay_cnt <= 0;
		end
     end
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
   always @ ( state or DATA_BYTE_READY or byte_count or WRITE_COMPLETE or
			ENDPOINT_DECODE or ENDPOINT_EN or command_byte or
			WRITE_READY or data_byte_ready_delay_cnt or write_to_host or 
			write_data_byte or command_to_device or address_to_device)
     begin
	next = 9'h000;

	if (state[IDLE])
	  begin
	     if ( DATA_BYTE_READY )
	       next[DECODE_BYTE] = 1'b1;
	     else if(write_to_host)
			next[WRITE_CONTROL_BYTE] = 1'b1;
         else		 
	       next[IDLE] = 1'b1;
	  end

	
	if (state[DECODE_BYTE])
	  begin
		if ( command_byte )
			next[READ_CONTROL_BYTE] = 1'b1;
		else if ( byte_count >= 4'h2)
			next[READ_DATA_BYTE] = 1'b1;
		else 
	       next[IDLE] = 1'b1;
		//	next[DECODE_BYTE_FAIL] = 1'b1;
	  end

	if (state[READ_CONTROL_BYTE])
	  begin
	     if ( !DATA_BYTE_READY )
	       next[IDLE] = 1'b1;
		else
	       next[READ_CONTROL_BYTE] = 1'b1;
	  end

	if (state[READ_DATA_BYTE])
	begin
	     if ( !DATA_BYTE_READY )
		 begin
		     case(command_to_device)
			 `TRIGGER_IN_CMD:
			         next[IDLE] = 1'b1;	
			 `TRANSFER_IN_CMD:
			         next[IDLE] = 1'b1;	
			 `BLOCK_IN_CMD:
			     begin
				     if(data_byte_ready_delay_cnt < 3'h2)
	                     next[READ_DATA_BYTE] = 1'b1;
					 else
			             next[WAIT_FIFO_READY] = 1'b1;	
				 end
             default:			 
			         next[IDLE] = 1'b1;	
			 endcase
		 end
		else
	       next[READ_DATA_BYTE] = 1'b1;
	end
	
	if (state[WAIT_FIFO_READY])
	begin
	     if(byte_count > (length_to_device + 8'h3))
			next[IDLE] = 1'b1;	
	     else if (DATA_BYTE_READY)
	       next[READ_DATA_BYTE] = 1'b1;
		else
	       next[WAIT_FIFO_READY] = 1'b1;
	end

/*	if ( state[DECODE_BYTE_FAIL] )
	begin
	     if ( decode_byte_fail_count >= 8'h6 )
			next[IDLE] = 1'b1;	
		else
	       next[DECODE_BYTE_FAIL] = 1'b1;
	end
*/


	if ( state[WRITE_CONTROL_BYTE] )
	begin
	     if ( WRITE_READY )
			 next[WRITE_CONTROL_BYTE_DELAY] = 1'b1;	
		else
	       next[WRITE_CONTROL_BYTE] = 1'b1;
	end

	if ( state[WRITE_CONTROL_BYTE_DELAY] )
	begin
		if ( WRITE_COMPLETE )
			next[WRITE_CONTROL_COMPLETE] = 1'b1;	
		else
	       next[WRITE_CONTROL_BYTE_DELAY] = 1'b1;
	end

	if ( state[WRITE_CONTROL_COMPLETE] )
	begin
		if ( write_data_byte )
		begin
		     case(command_from_device)
			 `TRIGGER_OUT_CMD:
			         next[WRITE_CONTROL_BYTE] = 1'b1;	
			 `TRANSFER_OUT_CMD:
			         next[WRITE_CONTROL_BYTE] = 1'b1;	
			 `BLOCK_OUT_CMD:
			         next[WRITE_CONTROL_BYTE] = 1'b1;	
             `TRANSFER_OUT_CONTINUATION_CMD:
			         next[WRITE_CONTROL_BYTE] = 1'b1;	
             default:			 
			         next[IDLE] = 1'b1;	
			 endcase
		end
		else
	       next[IDLE] = 1'b1;
	end

`ifdef SIM
	   if ( state == ( 1 << IDLE ))
		   state_name = "IDLE";
	   else if ( state == ( 1 << DECODE_BYTE ))
		   state_name = "DECODE_BYTE";
	   else if ( state == ( 1 << READ_CONTROL_BYTE ))
		   state_name = "READ_CONTROL_BYTE";
	   else if ( state == ( 1 << READ_DATA_BYTE ))
		   state_name = "READ_DATA_BYTE";
	   else if ( state == ( 1 << WAIT_FIFO_READY ))
		   state_name = "WAIT_FIFO_READY";
	   //else if ( state == ( 1 << DECODE_BYTE_FAIL ))
	   //	   state_name = "DECODE_BYTE_FAIL";
	   else if ( state == ( 1 << WRITE_CONTROL_BYTE ))
		   state_name = "WRITE_CONTROL_BYTE";
	   else if ( state == ( 1 << WRITE_CONTROL_BYTE_DELAY ))
		   state_name = "WRITE_CONTROL_DELAY";
	   else if ( state == ( 1 << WRITE_CONTROL_COMPLETE ))
		   state_name = "WRITE_CONTROL_COMPLETE";
`endif

	end//end of state machine

   
endmodule 
