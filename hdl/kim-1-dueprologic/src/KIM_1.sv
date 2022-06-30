/*
 * Model of a KIM-1
 *
 * Stephen A. Edwards
 * sedwards@cs.columbia.edu
 *
 *
 * Memory Map:
 *
 * 0000 - 03FF RAM (1K)
 * 1700 - 173F 6530-003 registers  (application connector)
 * 1740 - 177F 6530-002 registers  (keyboard, LEDs, TTY, cassette)
 * 1780 - 17FF RAM (128 bytes, 6530s)
 * 1800 - 1FFF ROM (2K)     1800-1BFF 6530-003  1C00-1FFF 6530-002
 *
 * 6530 registers
 *
 * 0,8 A Data             R/W
 * 1,9 A Data Direction   R/W
 * 2,A B Data             R/W
 * 3,B B Data Direction   R/W
 *
 * 4  Timer /1            W
 * 5  Timer /8            W
 * 6  Timer /64           W
 * 7  Timer /1024         W
 *
 * 4,6 Timer value        R
 * 5,7,D,F Interrupt flag R
 *
 * C  Timer /1 + Int      W
 * D  Timer /8 + Int      W
 * E  Timer /64 + Int     W
 * F  Timer /1024 + Int   W
 *
 * C,E Timer value + Int  R
 *
 * 1740 : Keyboard columns/LED segments
 * 1742 : Keyboard row/LED digits
 *
 */

module KIM_1 (
    output [15:0] PC_D,     // Debug program counter

    input         clk,
    input         reset,
    input         NMI,
    output [15:0] AB,
    output [ 7:0] DO,
    output [ 7:0] DI,
    output        WE,
    input         DECODE_ENABLE,  // 0 = enable address decode
    output        RDY,

    output [7:0] PAO,   // Application connector PA
    input  [7:0] PAI,
    output [7:0] PAOE,
    output [7:0] PBO,   // Application connector PB
    input  [7:0] PBI,
    output [7:0] PBOE,

    output [3:0] KB_ROW,   // Active-low keyboard row select
    input  [6:0] KB_COL,   // Active-low keyboard column data
    output [9:4] LED_DIG,  // Active-low LED digit select
    output [6:0] LED_SEG,  // Active-low LED segment

    output [7:0] K,  // Address decoder output, active low

    output TTYO,
    input  TTYI,
    input  ENABLE_TTY, // When high, emulate TTY jumper V-21

    // V is "row 3/O3 from U24, the '145
    // 21 is PA0/col A of RIOT002

    input  AUDIOI,
    output AUDIOO,

    output [2:0] LED,

	 input	SST_SWITCH // Single step - active low
);

  logic [7:0] RIOT002_DO;  // Read data from 6530-002
  logic       RIOT002_OE;
  logic [7:0] RIOT003_DO;  // Read data from 6530-003
  logic       RIOT003_OE;

  logic [7:0] RIOT002_PAO;
  logic [7:0] RIOT002_PAI;
  logic [7:0] RIOT002_PAOE;
  logic [7:0] RIOT002_PBO;
  logic [7:0] RIOT002_PBI;
  logic [7:0] RIOT002_PBOE;

  assign RDY     = 1;

  assign LED_SEG = ~RIOT002_PAO[6:0];


  mcs6502 U1 (
      .clk(clk),
      .reset(reset),
      .AB(AB),
      .DI(DI),
      .DO(DO),
      .WE(WE),
      .IRQ(1'b0),
      .NMI(NMI),
      .RDY(RDY),
      .PC_D(PC_D)
  );

  mcs6530 #( 16'h1740 )  // Base of IO & Timer
           U2(
      .clk(clk),
      .reset(reset),
      .RW(~WE),
      .A(AB[9:0]),
      .DI(DO),
      .DO(RIOT002_DO),
      .OE(RIOT002_OE),
      .CS1(K[5]),
      .PAO(RIOT002_PAO),
      .PAI(RIOT002_PAI),
      .PAOE(RIOT002_PAOE),
      .PBO(RIOT002_PBO),
      .PBI(RIOT002_PBI),
      .PBOE(RIOT002_PBOE)
  );

  mcs6530 #( 16'h1700 )  // Base of IO & Timer
           U3(
      .clk(clk),
      .reset(reset),
      .RW(~WE),
      .A(AB[9:0]),
      .DI(DO),
      .DO(RIOT003_DO),
      .OE(RIOT003_OE),
      .CS1(K[5]),
      .PAO(PAO),
      .PAI(PAI),
      .PAOE(PAOE),
      .PBO(PBO),
      .PBI(PBI),
      .PBOE(PBOE)
  );

  // U4, a '145 four-to-ten decoder with active-low outputs
  //
  // This divides the memory space into 8 1K regions
  // K0 0000-03FF  1K RAM
  // K1 0400-07FF
  // K2 0800-0BFF
  // K3 0C00-0FFF
  // K4 1000-13FF
  // K5 1400-17FF  6530 Registers/RAM
  // K6 1800-1BFF  6530-003 ROM
  // K7 1C00-1FFF  6530-002 ROM
  logic [9:0] u4out;
  SN74145 U4 (
      .select({DECODE_ENABLE, AB[12:10]}),
      .out(u4out)
  );
  assign K = u4out[7:0];  // outputs 8,9 are not connected

  // U24, a '145 four-to-ten decoder that selects the keyboard rows and
  // the LED digits
  SN74145 U24 (
      .select(RIOT002_PBO[4:1]),
      .out({LED_DIG, KB_ROW})
  );

  // Emulate the tri-state data bus being driven by the peripherals
  always_comb
    if (RAM1K_OE) DI = RAM1K_DO;
    else if (RAM128_OE) DI = RAM128_DO;
    else if (ROM2K_OE) DI = ROM2K_DO;
    else if (RIOT002_OE) DI = RIOT002_DO;
    else if (RIOT003_OE) DI = RIOT003_DO;
    // else DI = 8'bx;
    // Ghosts in the data were sometimes echoing the last value 
    // of DI, which resulted in the memory test (first book of KIM)
    // to return extra bytes of RAM.
    //
    // So hard code in a value instead.
    else DI = 8'10100101;

  // U5-U14: 1K Static RAM

  logic [7:0] RAM1K                              [0:1023];
  initial $readmemh("ram.hex", RAM1K);  // Load the ROM from a file
  logic [7:0] RAM1K_DO;  // Read data from 1K RAM
  logic       RAM1K_OE;  // Data from the 1K RAM

  always_ff @(posedge clk) begin
    {RAM1K_OE, RAM1K_DO} <= {1'b0, 8'bx};
    if (!K[0])
      if (WE) RAM1K[AB[9:0]] <= DO;
      else {RAM1K_OE, RAM1K_DO} <= {1'b1, RAM1K[AB[9:0]]};
  end

  // 2K ROM within the two 6530s

  logic [7:0] ROM2K[0:2047];
  initial $readmemh("ROM.hex", ROM2K);  // Load the ROM from a file
  logic [7:0] ROM2K_DO;  // Read data from 2K ROM
  logic       ROM2K_OE;  // Data from the 2K ROM

  always_ff @(posedge clk) begin
    {ROM2K_OE, ROM2K_DO} <= {1'b0, 8'bx};
    if (!K[6] || !K[7]) {ROM2K_OE, ROM2K_DO} <= {1'b1, ROM2K[AB[10:0]]};
  end

  // 128-BYTE RAM within the two 6530s
  // This is mapped to 1780 to 17FF
  // K5 decodes 1400 - 17FF (12:10)
  //
  // 5432 1098 7654 3210
  // 0001 0111 1000 0000  1780
  // 0001 0111 1111 1111  17FF
  // ---K KK11 1aaa aaaa

  logic [7:0] RAM128    [0:127];
  initial $readmemh("ram128.hex", RAM128);  // Load the ROM from a file

  logic [7:0] RAM128_DO;
  logic       RAM128_OE;

  always_ff @(posedge clk) begin
    {RAM128_OE, RAM128_DO} <= {1'b0, 8'bx};
    if (!K[5] && (AB[9:7] == 3'b111))
      if (WE) RAM128[AB[6:0]] <= DO;
      else {RAM128_OE, RAM128_DO} <= {1'b1, RAM128[AB[6:0]]};
  end

  // Teletype and Tape interface
  // Tape and teletype use RIOT002
  // PB5, PB7, PB0, and PA7
  //
  //   PB0 is TTY output    (start = 0; stop = 1; non-inverted)
  //   PA7 is TTY input
  //   PB7 is tape output and tape input
  //   PB5 is "TTY and Tape I/O Control"  (0 = enable input on PA7)
  //
  // PA7 is generally set as an input
  //
  // PB7 <= Tape input && !PB5
  // PB0 && PA7 => TTY output
  // PA7 <= !PB5 && TTY input
  //
  // Goes through RIOT002:
  // 1740  SAD   Port A data
  // 1741  PADD  Port A direction
  // 1742  SBD   Port B data
  // 1743  PBDD  Port B direction
  //
  //   PB0 (Bit 0) is used as output
  //   Start bit is 0; stop bit is 1.  Data bits are non-inverted

  // Emulate the effect of the TTY/Keypad jumper:
  // When KB_ROW3 is selected (low), the jumper pulls PA0 low
  assign RIOT002_PAI[6:0] = {KB_COL[6:1], KB_COL[0] && (KB_ROW[3] || !ENABLE_TTY)};

  assign RIOT002_PAI[7] = ~(~TTYI && ~RIOT002_PBO[5]);
  assign TTYO = RIOT002_PBO[0] && RIOT002_PAI[7];

  assign LED[2] = ~RIOT002_PAI[7];
  assign LED[1] = ~RIOT002_PBO[5];
  assign LED[0] = ~RIOT002_PBO[0];

  // Audio interface (incomplete)

  assign RIOT002_PBI[7] = AUDIOI;
  assign AUDIOO = RIOT002_PBO[7];

endmodule

// BCD-to-decimal decoder, active-low outputs
// Actual '145 has open-collector outputs (i.e. Z when H)
module SN74145 (
    input  [3:0] select,
    output [9:0] out
);
  always_comb

    case (select)
      4'd0:    out = 10'b11_1111_1110;
      4'd1:    out = 10'b11_1111_1101;
      4'd2:    out = 10'b11_1111_1011;
      4'd3:    out = 10'b11_1111_0111;
      4'd4:    out = 10'b11_1110_1111;
      4'd5:    out = 10'b11_1101_1111;
      4'd6:    out = 10'b11_1011_1111;
      4'd7:    out = 10'b11_0111_1111;
      4'd8:    out = 10'b10_1111_1111;
      4'd9:    out = 10'b01_1111_1111;
      default: out = 10'b11_1111_1111;
    endcase

endmodule
