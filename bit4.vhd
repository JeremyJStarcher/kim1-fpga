library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Bit4 is
	port(C, CLR : in std_logic;
	Q : out std_logic_vector(3 downto 0));
end Bit4;

architecture bhv of Bit4 is
	signal tmp: std_logic_vector(3 downto 0);
begin
	process (C, CLR)
	begin
		if (CLR='1') then
			tmp <= "0000";
		elsif (C'event and C='1') then
			tmp <= tmp + 1;
		end if;
	end process;
	Q <= tmp;
end bhv;
