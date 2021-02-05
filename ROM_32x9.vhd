library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity ROM_32x9 is
    port (
    clock : in std_logic;
    read_enable : in std_logic; -- signal that enables read operation
    address : in std_logic_vector(4 downto 0); -- 2^5 = 32
    data_out : out std_logic_vector(8 downto 0)
    );
end ROM_32x9;

architecture Artix of ROM_32x9 is
    type Memory_type is array (0 to 31) of std_logic_vector (8 downto 0);
    signal Memory_array : Memory_type;
begin
    process (clock) begin
        if rising_edge (clock) then
            if (read_enable = '1') then -- the data read is available after the clock edge
            data_out <= Memory_array (to_integer (unsigned (address)));
            end if;
        end if;
    end process;
end Artix;
