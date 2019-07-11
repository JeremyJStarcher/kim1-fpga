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
	signal max_d 	: std_logic_vector(27 downto 0) := "0001111111111111111111111110";
	signal tt 		: std_logic_vector(31 downto 0) := "00011111111111111111111111111110";
	signal Q1		: std_logic_vector(3 downto 0);
	signal reset	: std_logic;
	signal spi_clock : std_logic;
	signal tick_clock : std_logic;

	
	signal	AB		: std_logic_vector(15 downto 0);	-- address bus
	signal	DI		: std_logic_vector(7 downto 0);		-- data in, read bus
	signal 	DO		: std_logic_vector(7 downto 0);		-- data out, write bus
	signal	WD		: std_logic;								-- write enable
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
		WD		: in std_logic;								-- write enable
		IRQ	: in std_logic;								-- interrupt request
		NMI	: in std_logic;								-- non-maskable interrupt request
		RDY	: in std_logic);								-- Ready signal. Pauses CPU when RDY=0

end component;


begin
	c1: Clock port map (C => clk, CLR => reset, spi_clock => spi_clock, tick_clock => tick_clock);
	div1: Bit4 port map (C => tick_clock, CLR => reset, Q => Q1);

	max1: M7219 port map (clk => spi_clock,
		parallel => tt,
		clk_out => max_clk,
		load => max_cs,
		data_out => max_din
	);


	led2 <= not Q1(0);
	led1 <= not Q1(1);
	led0 <= not Q1(2);

	process(tick_clock)
	begin
		if (reset = '1') then
			max_d <= (others => '0');
		elsif rising_edge(tick_clock) then
			max_d <= max_d + 1;
		end if;
		
		tt(31 downto 28)<= "1010";
		tt <= (others => '0');
		-- tt(27 downto 0)<= max_d;
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
