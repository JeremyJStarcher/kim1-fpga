library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity Kim is
port (
	clk	: in std_logic;  -- clock is on 17
	led0	: out std_logic; -- led on 3
	led1	: out std_logic; -- led on 7
	led2	: out std_logic; -- led on 9
	sw0	: in std_logic;   -- switch on 114

	max_din : out std_logic; -- 76
	max_cs  : out std_logic; -- 80
	max_clk : out std_logic -- 86
);
end Kim;

architecture rtl of Kim is
	signal max_d 	: std_logic_vector(27 downto 0) := "0000000000000000000000000000";
	signal tt 		: std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
	signal Q1		: std_logic_vector(3 downto 0);
	signal reset	: std_logic;

	signal spi_clock : std_logic;
	signal tick_clock : std_logic;

	signal TOP_ROM_DO	: std_logic_vector(7 downto 0);
	signal TOP_ROM_EN : std_logic;

	shared variable	HAB1		: std_logic_vector(15 downto 0);	-- address bus
	shared variable	HAB2		: std_logic_vector(15 downto 0);	-- address bus

	signal	AB		: std_logic_vector(15 downto 0);	-- address bus
	signal	DI		: std_logic_vector(7 downto 0);		-- data in, read bus
	shared variable	HDI	: std_logic_vector(7 downto 0);		-- data in, read bus

	signal 	DO		: std_logic_vector(7 downto 0);		-- data out, write bus
	signal	WE		: std_logic;								-- write enable
	signal	IRQ	: std_logic;								-- interrupt request
	signal	NMI	: std_logic;								-- non-maskable interrupt request
	signal	RDY	: std_logic;								-- Ready signal. Pauses CPU when RDY=0


component Bit4 is
	port(C, CLR : in std_logic;
	Q : out std_logic_vector(3 downto 0));
end component;

component M7219 is
    port (
      clk : in std_logic;
      parallel : in std_logic_vector(31 downto 0);
      clk_out : out std_logic;
      data_out : out std_logic;
      load : out std_logic
    );
end component;

component Clock is
	port(C, CLR : in std_logic;
	spi_clock : out std_logic;
	tick_clock : out std_logic);
end component;

component cpu is
	port(
		clk	: in std_logic;								-- CPU clock
		reset	: in std_logic;								-- reset signal
		AB		: out std_logic_vector(15 downto 0);	-- address bus
		DI		: in std_logic_vector(7 downto 0);		-- data in, read bus
		DO		: out std_logic_vector(7 downto 0);		-- data out, write bus
		WE		: out std_logic;								-- write enable
		IRQ	: in std_logic;								-- interrupt request
		NMI	: in std_logic;								-- non-maskable interrupt request
		RDY	: in std_logic);								-- Ready signal. Pauses CPU when RDY=0
end component;

component top_rom is
generic(
	address_length: natural := 16;
	data_length: natural := 8
);
port(
	clock: in std_logic;
	rom_enable: in std_logic;
	address: in std_logic_vector((address_length - 1) downto 0);
	data_output: out std_logic_vector ((data_length - 1) downto 0)
);
end component;

begin
	c1: Clock port map (C => clk, CLR => reset, spi_clock => spi_clock, tick_clock => tick_clock);
	div1: Bit4 port map (C => tick_clock, CLR => reset, Q => Q1);

	NMI <= '1';
	RDY <= '1';

	cpu1: cpu port map(
		clk => tick_clock,
		reset => reset,
		AB	=> AB,
		DI	=> DI,
		DO	=> DO,
		WE => WE,
		IRQ => IRQ,
		NMI => NMI,
		RDY => RDY
);
	
	max1: M7219 port map (clk => spi_clock,
		parallel => tt,
		clk_out => max_clk,
		load => max_cs,
		data_out => max_din
	);

		tt(31 downto 28)<= HAB2(15 downto 12); -- "1010";
		tt(27 downto 24)<= HAB2(11 downto 8); -- )"1011";
		tt(23 downto 20)<= HAB2(7 downto 4); --)"1100";
		tt(19 downto 16)<= HAB2(3 downto 0); -- ))"1101";

	rom1: top_rom port map (
		clock => tick_clock,
		rom_enable => TOP_ROM_EN,
		address => HAB2,
		data_output => TOP_ROM_DO
	);

	DI <= HDI;

	led2 <= not Q1(0);
	led1 <= not Q1(1);
	led0 <= not Q1(2);

	process(tick_clock)
	begin
		if tick_clock'event and tick_clock='1' then
			HAB2 := HAB1;
			HAB1 := AB;
		
			case HAB1 is
			when x"FFFA"
				| x"FFFB"
				| x"FFFC"
				| x"FFFD"
				| x"FFFE"
				| x"FFFF"	=>
				TOP_ROM_EN <= '1';
				HDI := TOP_ROM_DO;
			when others =>
				HDI := x"EA"; -- hard wire in a NOP
				-- TOP_ROM_EN <= '0';
			end case;
		end if;
				
		tt(15 downto 12)<=  HDI(7 downto 4);
		tt(11 downto 8)<=  HDI(3 downto 0);

		tt(7 downto 4)<= TOP_ROM_DO(7 downto 4); -- ))"1101";
		tt(3 downto 0)<= TOP_ROM_DO(3 downto 0); -- ))"1101";

	end process;

	process(clk, sw0)

	begin

		if rising_edge(clk) then
			if sw0='0' then
				reset <= '1';
			else
				reset <= '0';
			end if;
		end if;

	end process;

end rtl;
