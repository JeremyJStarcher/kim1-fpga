library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Clock is
	port(C, CLR : in std_logic;
	spi_clock : out std_logic;
	tick_clock : out std_logic);
end Clock;

architecture cclk of Clock is
	constant CLK_FREQ : integer :=   50000000;
	constant SPI_FREQ : integer := 500000;
	constant SPI_CNT_MAX : integer := CLK_FREQ/SPI_FREQ/2-1;

	constant TICK_FREQ : integer := 5;
	constant TICK_CNT_MAX: integer := CLK_FREQ/TICK_FREQ/2-1;

	signal c_spi : std_logic := '0';
	signal c_tick : std_logic := '0';

	signal spi_cnt		 : unsigned(24 downto 0);
	signal tick_cnt    : unsigned(24 downto 0);
begin
	process (C, CLR)

	begin
		if (CLR='1') then
			spi_cnt <= (others => '0');
			tick_cnt <= (others => '0');
		elsif rising_edge(C) then
			if spi_cnt >= SPI_CNT_MAX then
				spi_cnt <= (others => '0');
				c_spi <= not c_spi;
				spi_clock <= c_spi;
			else
				spi_cnt <= spi_cnt + 1;
			end if;

			if tick_cnt >= TICK_CNT_MAX then
				tick_cnt <= (others => '0');
				c_tick <= not c_tick;
				tick_clock <= c_tick;
			else
				tick_cnt <= tick_cnt + 1;
			end if;

	end if;

	end process;
end cclk;
