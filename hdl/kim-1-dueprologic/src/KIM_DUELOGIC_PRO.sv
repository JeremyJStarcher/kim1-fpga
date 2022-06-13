/*
 * Top level of the KIM-1 model for an DUELOGICPRO minimal board
 *
 * Stephen A. Edwards
 * sedwards@cs.columbia.edu
 * Modified by
 * Jeremy J Starcher
 *
 */

module KIM_DUELOGIC_PRO (
    // input clk50,
	 input CLK_66,
	
    inout [7:0] PA,
    inout [7:0] PB,

    output [3:0] KB_ROW,
    input  [6:0] KB_COL,
    output [9:4] LED_DIG,  // Active low: 4 is leftmost
    output [6:0] LED_SEG,  // Active low: 0 is segment A

	 input SST_SWITCH, // Active low
    input ST_KEY,  // Active low
    input RS_KEY,  // Active low

    output TTYO,
    input  TTYI,
    input  ENABLE_TTY, // Active low enable TTY mode

    output AUDIOO,
    input  AUDIOI,

	 output SPI_DO,
	 output SPI_CLK,
	 output SPI_CS,
	
    output [2:0] LED,
    input        KEY

);

  /*
    * Clock divider: converts 50 MHz external clock
    * to the 1 MHz clock of the KIM-1.  Normally, this would
    * be done with an on-chip PLL in the FPGA, but the EP2C5's
    * PLLs can only divide a 50 MHz clock down to about 10 MHz.
    */

//  logic [4:0] clkcount = 5'h0;
//  logic       clk = 1'b0;
//  always @(posedge clk50) begin
//    if (clkcount == 5'd24) begin
//      clkcount <= 5'd0;
//      clk <= ~clk;
//    end else clkcount <= clkcount + 5'd1;
//  end


  logic [7:0] clk_1_count = 8'h0;
  logic       clk_1 = 1'b0;
  always @(posedge CLK_66) begin
    if (clk_1_count == 8'd32) begin
      clk_1_count <= 8'd0;
      clk_1 <= ~clk_1;
    end else begin
      clk_1_count <= clk_1_count + 8'd1;
    end
  end

  logic [15:0] clk_s_count = 16'h0;
  logic clk_s = 1'b0;
  always @(posedge CLK_66) begin
    if (clk_s_count == 16'd65535) begin
      clk_s_count <= 16'd0;
      clk_s <= ~clk_1;
    end else begin
      clk_s_count <= clk_s_count + 16'd1;
    end
  end


  logic reset = 1'b0;

  always_comb begin
    reset = ~KEY || ~RS_KEY;
  end

  logic [15:0] PC_D;     // Debug program counter

  KIM_1 TOP (
      .PAI(PA),
      .PBI(PB),
      .DECODE_ENABLE(1'b0),
      .RDY(),
      .K(K),
      .DO(),
      .DI(),
      .AB(),
      .WE(),
      .reset(reset),
      .NMI(~ST_KEY),
      .ENABLE_TTY(~ENABLE_TTY),
      .KB_ROW(KB_ROW_int),
      .clk(clk_1),

      .PC_D(PC_D),
      .*
  );

  logic [7:0] K;

  logic [63:0] MAX_DISPLAY = 63'h01234567;
  always @(posedge CLK_66) begin
  //  MAX_DISPLAY = PC_D;
  end


  always_comb begin
    MAX_DISPLAY = PC_D;
  end

  MAX7219 M (
        .clk(clk_1),
        .reset_n(~reset),
        .data_vector(MAX_DISPLAY),
        .clk_out(SPI_CLK),
        .data_out(SPI_DO),
        .load_out(SPI_CS)
    );
	

defparam M.devices=2;
// defparam M.intensity =  integer [7];



  /*
    * Tri-state buffers on the PA and PB pins
    */
  logic [7:0] PAO, PAOE, PBO, PBOE;
  genvar i;
  generate
    for (i = 0; i < 8; i++) begin : P_pins
      assign PA[i] = PAOE[i] ? PAO[i] : 1'bZ;
      assign PB[i] = PBOE[i] ? PBO[i] : 1'bZ;
    end
  endgenerate

  /* Emulate open-collector outputs on the KB_ROW signals */
  logic [3:0] KB_ROW_int;
  generate
    for (i = 0; i < 4; i++) begin : KB_ROW_pins
      assign KB_ROW[i] = KB_ROW_int[i] ? 1'bz : 1'b0;
    end
  endgenerate


`ifdef HEARTBEAT
  /*
    * Heartbeat display to confirm the 1 MHz clock functions properly
    */
  logic [19:0] count;

  always_ff @(posedge clk) begin
    if (count == 19'd0) begin
      LED[0] <= ~LED[0];
      count  <= 19'd1_000_000;
    end else count <= count - 19'd1;
  end

  assign LED[1] = KEY;
`endif

`ifdef LED_TEST
  /*
    * Testing the LED
    */

  always_comb
    case (count[15:13])
      3'd0: LED_DIG = 6'b111110;
      3'd1: LED_DIG = 6'b111101;
      3'd2: LED_DIG = 6'b111011;
      3'd3: LED_DIG = 6'b110111;
      3'd4: LED_DIG = 6'b101111;
      3'd5: LED_DIG = 6'b011111;
      default: LED_DIG = 6'b111111;
    endcase

  always_comb
    case (count[18:16])
      3'd0: LED_SEG = 7'b1111110;
      3'd1: LED_SEG = 7'b1111101;
      3'd2: LED_SEG = 7'b1111011;
      3'd3: LED_SEG = 7'b1110111;
      3'd4: LED_SEG = 7'b1101111;
      3'd5: LED_SEG = 7'b1011111;
      3'd6: LED_SEG = 7'b0111111;
      default: LED_SEG = 7'b1111111;
    endcase  // case (count [18:16])
`endif

endmodule
