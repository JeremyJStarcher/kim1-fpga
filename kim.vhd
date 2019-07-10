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
	constant CLK_FREQ : integer :=   50000000;
	constant BLINK_FREQ : integer := 500000;
	constant CNT_MAX : integer := CLK_FREQ/BLINK_FREQ/2-1;
	
	signal cnt		 : unsigned(24 downto 0);
	signal max_d 	: std_logic_vector(31 downto 0) := "00011111111111111111111111111110";

	signal blink	: std_logic;

	signal Q1		: std_logic_vector(3 downto 0);	
	signal reset	: std_logic;
	
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

	
begin
	div1: Bit4 port map (C => blink, CLR => reset, Q => Q1);

	max1: M7219 port map (clk => blink,
		parallel => max_d,
		clk_out => max_clk,
		load => max_cs,
		data_out => max_din 
	);
	
	led2 <= '1';
	led1 <= '1';
	-- led0 <= '1';
	
	--led2 <= not Q1(0);
	--led1 <= not Q1(1);
	--led0 <= not Q1(2);
		
	process(clk, sw0)
	
	begin
	
	if rising_edge(clk) then
		
			if sw0='0' then
				reset <= '1';
			else
				reset <= '0';
			end if;

			if cnt >= CNT_MAX then
				cnt <= (others => '0');
				blink <= not blink;
			else
			   max_d <= max_d + 1;
				cnt <= cnt + 1;
			end if;
		end if;

	end process;
	
end rtl;
