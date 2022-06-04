/*****************************************************
 * $Workfile::                                       
 * $Author::	RJolly                                         
 * $Date::    	11/16/11                                       
 * $Revision::   	002                                    
 *
 * Copyright Stereovision, Inc. 2011
 *
 * This header files defines the input/output
 *	11/16/11	Created this file from Digital Video Recorder
		
******************************************************/
`ifndef _TOP_DEFINE
 `define _TOP_DEFINE

 // Commands
 `define TRIGGER_OUT_CMD                 3'h1
 `define TRANSFER_OUT_CMD                3'h2
 `define BLOCK_OUT_CMD                   3'h4
 `define TRANSFER_OUT_CONTINUATION_CMD   3'h6
 `define TRIGGER_IN_CMD                  3'h1
 `define TRANSFER_IN_CMD                 3'h2
 `define BLOCK_IN_CMD                    3'h4
 `define TRANSFER_IN_CONTINUATION_CMD    3'h6
 

 //Counter values for automated write byte to UART
`ifdef SIM
 `define TRIGGER_OUT_COUNT               26'hf000
`else
 `define TRIGGER_OUT_COUNT               26'h3ef1
`endif

 // UC vector parameters
 `define UC_DATAIN_START                0
 `define UC_DATAIN_END                  7
 `define UC_DATAOUT_START               0
 `define UC_DATAOUT_END                 7
 `define UC_PAYLOAD_START               0
 `define UC_PAYLOAD_END                 7
 `define UC_ADDRESS_START               8
 `define UC_ADDRESS_END                 10
 `define UC_LENGTH_START                11
 `define UC_LENGTH_END                  18
 `define UC_CMD_START                   19
 `define UC_CMD_END                     21
 `define UC_OUT_START                   0
 `define UC_OUT_END                     21
 `define UC_IN_START                    0
 `define UC_IN_END                      23
 
 // UC Bit defines
 `define UC_IN_FIFO_EN                  22
 `define UC_IN_BUSY                     23
 
  // EPT parameters
 `define EPT_DATAIN_START                0
 `define EPT_DATAIN_END                  7
 `define EPT_ADDRESS_START               0
 `define EPT_ADDRESS_END                 2
 `define EPT_LENGTH_START                0
 `define EPT_LENGTH_END                  7
 `define EPT_BCIN_START                  0
 `define EPT_BCIN_END                    1
 `define EPT_BCOUT_START                 0
 `define EPT_BCOUT_END                   2
 `define EPT_AA_START                    0
 `define EPT_AA_END                      1


`endif //  `ifndef _TOP_DEFINE

