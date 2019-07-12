library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity rom is
generic(
	address_length: natural := 3;
	data_length: natural := 8
);
port(
	clock: in std_logic;
	rom_enable: in std_logic;
	address: in std_logic_vector((address_length - 1) downto 0);
	data_output: out std_logic_vector ((data_length - 1) downto 0)
);
end rom;

architecture arch of rom is
	type rom_type is array (0 to (2**(address_length) -1)) of std_logic_vector((data_length - 1) downto 0);
	
	-- set the data on each adress to some value)
	constant mem: rom_type:=
	(
		x"1C", -- NMI
		x"1C", -- NMI
		x"22", -- RESET
		x"1C", -- RESET
		x"1F", -- IRQ/BRK
		x"1C", -- IRQ/BRK
		x"A0",
		x"A0"
		);
begin

process(clock) is
begin
	if(rising_edge(clock) and rom_enable = '1') then
		data_output <= mem(conv_integer(unsigned(address)));
	end if;
end process;

end arch;