/******************************************************************************
 * $Workfile::                                                                $
 * $Author: mcorbett $
 * $Date: 2003-06-25 13:59:23-04 $
 * $Revision: 1.0 $
 *
 * Copyright Commonwealth Technology, Inc. 2003
 *
 * This header files defines the input/output lines being used.
 *****************************************************************************/
`ifndef _TB_DEFINE
 `define _TB_DEFINE


   `define CIS_REGISTERS                   100
   `define READ_CONTROL_WORD               8'h80
   `define REG_BASE_ADDRESS                8'h40
   `define NUMBER_RSB_REG                  8'h0f

   // EPT TestBench Commands
   `define TRIGGER_OUT_CMD_TB              3'h1
   `define TRANSFER_OUT_CMD_TB             3'h2
   `define BLOCK_OUT_CMD_TB                3'h4
   `define TRIGGER_IN_CMD_TB               3'h1
   `define TRANSFER_IN_CMD_TB              3'h2
   `define BLOCK_IN_CMD_TB                 3'h4

   // EPT vector parameters
   `define ADDRESS_000_TB                  3'h0
   `define ADDRESS_001_TB                  3'h1
   `define ADDRESS_002_TB                  3'h2
   `define ADDRESS_003_TB                  3'h3
   `define ADDRESS_004_TB                  3'h4
   `define ADDRESS_005_TB                  3'h5
   `define ADDRESS_006_TB                  3'h6
   `define ADDRESS_007_TB                  3'h7

   // EPT EndTerm parameters
   `define TRANSFER_ENDTERM_1             8'h01
   `define TRANSFER_ENDTERM_2             8'h02
   `define TRANSFER_ENDTERM_3             8'h03
   `define TRANSFER_ENDTERM_4             8'h04
   `define TRANSFER_ENDTERM_5             8'h05
   `define TRANSFER_ENDTERM_6             8'h06
   `define TRANSFER_ENDTERM_7             8'h07

   // Block Transfer Options
   `define START_BLOCK_TRANSFER_OUT       8'hea
   `define START_BLOCK_TRANSFER_IN        8'hea
  

   // Loop control values for TestBench
   `define TEST_50_REPS                    8'h32
   `define TEST_30_REPS                    8'h1e
   `define TEST_20_REPS                    8'h14
   `define TEST_10_REPS                    8'h0a
   `define TEST_4_REPS                     8'h04
   `define TEST_2_REPS                     8'h03
   `define TEST_1_REPS                     8'h01
 
   // Simulation Clocks
   `define CYCLE                           10
   `define CYCLE_10                        50
   `define CYCLE_20                        25
   `define CYCLE_33                        15.15
   `define CYCLE_50                        10
   `define CYCLE_66                        7.5
   `define CYCLE_96                        5.2
   `define CYCLE_100                       5
   `define CYCLE_150                       3.33
   `define CYCLE_300                       1.66
   `define CYCLE_400                       1.25
   `define HALF_CYCLE `CYCLE/2
   `define CYCLE_32K                       15258
   `define CYCLE_800K                      625

 //Parameters for use with UART
   `define TX_PAYLOAD_BYTES		4
 `define RX_PAYLOAD_BYTES		4


   //Header Bytes to initiate the Control Register
   `define TRANSFER_CONTROL_BYTE1          8'h5A
   `define TRANSFER_CONTROL_BYTE2          8'hC3
   `define TRANSFER_CONTROL_BYTE3          8'h7E
   `define TRANSFER_CONTROL_DUMMY_BYTE     8'h00

   //Control Register constants
   `define RESET_CONTROL_REGISTER          8'h00
 
    //LED Blinky Set and Mask bits
   `define SET_RANDOM_BLINKY_BIT        8'h10
   `define CLEAR_RANDOM_BLINKY_BIT      8'hef
   `define SET_SHIFT_LEFT_BLINKY_BIT    8'h20
   `define CLEAR_SHIFT_LEFT_BLINKY_BIT  8'hdf
   `define SET_SHIFT_RIGHT_BLINKY_BIT   8'h30
   `define CLEAR_SHIFT_RIGHT_BLINKY_BIT 8'hcf
   `define SET_STATIC_BLINKY_BIT        8'h60
   `define CLEAR_STATIC_BLINKY_BIT      8'h9f

    //Control Register Bytes
   `define TRANSFER_LOOPBACK            8'h01
   `define BLOCK_LOOPBACK               8'h02
   `define LOAD_BLOCK_IMAGE_TO_BUFFER   8'h02
   `define LOAD_IMAGE_TO_BUFFER         8'h04
   `define SET_STATIC_IMAGE             8'h70
   `define SET_SHIFT_RIGHT_IMAGE        8'h90
   `define SET_SHIFT_LEFT_IMAGE         8'ha0


  //LED Blinky Load Timer, Seed and Shift Count
   `define LOAD_TIMER_VALUE_LOW         8'h10
   `define LOAD_TIMER_VALUE_HIGH        8'h20
   `define LOAD_SEED_VALUE              8'h40
   `define LOAD_SHIFT_COUNT_VALUE       8'h80
   
   //I2C Slave Unit Set and Mask bits
   `define SET_RECEIVE_ENA_IN_BIT       8'h02
   `define CLEAR_RECEIVE_ENA_IN_BIT     8'hfd
   `define SET_TRANSMIT_RDY_IN_BIT      8'h01
   `define CLEAR_TRANSMIT_RDY_IN_BIT    8'hfe


   //MAX11618 ADC Register Configuration
   `define ADC_CONVERSION_START         8'h04
 
   //Memory Location for ADC CONVST Delay Register 
   `define ADC_CONVST_DELAY_1_MEMORY    8'h00
   `define ADC_CONVST_DELAY_2_MEMORY    8'h01
   `define ADC_CONVST_DELAY_3_MEMORY    8'h02
   
   //Memory Locations for MCP4451 Digi-Pots
   `define MCP4451_CHIP_1_WRITE_CMD_MEMORY_LOCATION     8'h03
   `define MCP4451_CHIP_1_WRITE_DATA_MEMORY_LOCATION    8'h04
   `define MCP4451_CHIP_2_WRITE_CMD_MEMORY_LOCATION     8'h05
   `define MCP4451_CHIP_2_WRITE_DATA_MEMORY_LOCATION    8'h06

      //Memory Locations for TMP102 Temperature sensor
   `define TMP102_WRITE_CMD_MEMORY_LOCATION     8'h03
   `define TMP102_WRITE_DATA_MEMORY_LOCATION    8'h04
   `define TMP102_READ_DATA1_MEMORY_LOCATION    8'h05
   `define TMP102_READ_DATA2_MEMORY_LOCATION    8'h06

     //TMP102 Commands
    `define TMP102_TEMPERATURE_REGISTER           8'h0
    `define TMP102_CONFIG_REGISTER                8'h01
	


   //PGA Memory locations
   `define PGA_CH1_MEMORY               8'h10
   `define PGA_CH2_MEMORY               8'h12
   `define PGA_CH3_MEMORY               8'h14
   `define PGA_CH4_MEMORY               8'h16
   
   //Memory Location for PGA Data
   `define PGA_READ_MEMORY_LOCATION      8'h1a

   //PGA Channel Select
   `define PGA_CH1_SELECT               4'h1
   `define PGA_CH2_SELECT               4'h2
   `define PGA_CH3_SELECT               4'h4
   `define PGA_CH4_SELECT               4'h8

   //PGA Gain Settings
   `define PGA_GAIN_1                   4'h0
   `define PGA_GAIN_2                   4'h1
   `define PGA_GAIN_3                   4'h2
   `define PGA_GAIN_10                  4'h3
   `define PGA_GAIN_20                  4'h4
   `define PGA_GAIN_50                  4'h5
   `define PGA_GAIN_100                 4'h6
   `define PGA_GAIN_200                 4'h7
  
   //DSO Control Register Numbers
   `define ADC_CONTROL_REG_0            8'h00
   `define SPI_CONTROL_REG_1            8'h01
   `define I2C0_CONTROL_REG_2           8'h02
   `define I2C1_CONTROL_REG_3           8'h03
   `define ADC_CONVST_CONTROL_REG_4     8'h04
   `define RESET_CONTROL_REG_5          8'h05
   `define RESERVED_REG_6               8'h06
   `define RESERVED_REG_7               8'h07

   //////////////////////////////////////////////////////
   // DSO Control Register Contents
   //////////////////////////////////////////////////////
   // ADC Control Register Bits
   `define ADC_CONTROL_REG_RESET        8'h00
   `define ADC_CONVERSION_START         8'h01
   `define ADC_CONVERSION_STOP          8'h02
   `define ADC_CHANNEL_1                8'h10
   `define ADC_CHANNEL_2                8'h20
   `define ADC_CHANNEL_3                8'h40
   `define ADC_CHANNEL_4                8'h80

   // I2C Bus 0 Control Register Bits
   `define I2C0_CONTROL_REG_RESET        8'h00
   `define I2C0_MCP4451_CHIP_1_START_WRITE     8'h80
   `define I2C0_MCP4451_CHIP_2_START_WRITE     8'h90
   `define I2C0_MCP4451_CHIP_1_START_READ      8'ha0
   `define I2C0_MCP4451_CHIP_2_START_READ      8'hb0
   `define I2C0_TMP102_START_WRITE      8'h90
   `define I2C0_TMP102_START_READ       8'ha0

   // PGA Control Register Bits
   `define SPI_CONTROL_REG_RESET        8'h00
   `define PGA_CHANNEL_1_WRITE          8'h01
   `define PGA_CHANNEL_2_WRITE          8'h02
   `define PGA_CHANNEL_3_WRITE          8'h04
   `define PGA_CHANNEL_4_WRITE          8'h08
   `define PGA_CHANNEL_1_READ           8'h10
   `define PGA_CHANNEL_2_READ           8'h20
   `define PGA_CHANNEL_3_READ           8'h40
   `define PGA_CHANNEL_4_READ           8'h80
   //ADC CONVST Delay Control Register Bits
   `define ADC_CONVST_UPDATE_REG_RESET  8'h00   
   `define ADC_CONVST_UPDATE_REG        8'h01
   //Reset Control Register Bits
   `define SOFTWARE_RESET_BIT           8'h01   
   
   //DSO Trigger Bits
   `define DSO_TRIGGER_WRITE_LATCH      8'h01
   `define DSO_TRIGGER_OE_LATCH         8'h02
   `define DSO_TRIGGER_READ_LATCH       8'h04
   `define DSO_TRIGGER_START_ADC        8'h08
   `define DSO_LOAD_DELAY_BYTE_1        8'h10
   `define DSO_LOAD_DELAY_BYTE_2        8'h20
   `define DSO_LOAD_DELAY_BYTE_3        8'h40
   `define DSO_START_SPI_MASTER_WRITE   8'h80
   
   //MCP4451 Command Bits
   `define MCP4451_WIPER_0              4'h00
   `define MCP4451_WIPER_1              4'h01
   `define MCP4451_WIPER_2              4'h06
   `define MCP4451_WIPER_3              4'h07
   `define MCP4451_WRITE_CMD            2'b00
   `define MCP4451_READ_CMD             2'b11
   
   //MCP4451 I2C Address
   `define MCP4451_BUS_0_CHIP_0_ADDRESS        8'h58
   `define MCP4451_BUS_0_CHIP_1_ADDRESS        8'h5a

   //TMP102 I2C ADDRESS
   `define TMP102_FIXED_ADDRESS                  8'h90 //TMP102 base address is 7'b1001000

`endif //  `ifndef _TB_DEFINE
