library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity top_rom is
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
end top_rom;

architecture arch of top_rom is
	signal z : std_logic := '0';
begin

process(clock) is
begin
	if(rising_edge(clock) and rom_enable = '1') then
		case address is
			when x"FFFA" => data_output <= x"1C"; -- NMI
			when x"FFFB" => data_output <= x"1C"; -- NMI
			when x"FFFC" => data_output <= x"22"; -- RESET
			when x"FFFD" => data_output <= x"1C"; -- RESET
			when x"FFFE" => data_output <= x"1F"; -- IRQ/BRK
			when x"FFFF" => data_output <= x"1C"; -- IRQ/BRK
			when others => z <= '1';
		end case;
	end if;
end process;

end arch;