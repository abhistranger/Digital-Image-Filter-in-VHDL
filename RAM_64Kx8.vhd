library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity RAM_64Kx8 is
    port (
    clock : in std_logic;
    read_enable, write_enable : in std_logic; -- signals that enable read/write operation
    address : in std_logic_vector(15 downto 0); -- 2^16 = 64K
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0)
    );
end RAM_64Kx8;

architecture Artix of RAM_64Kx8 is
    type Memory_type is array (0 to 65535) of std_logic_vector (7 downto 0);
    signal Memory_array : Memory_type;
begin
    process (clock) begin
        if rising_edge (clock) then
            if (read_enable = '1') then -- the data read is available after the clock edge
                data_out <= Memory_array (to_integer (unsigned (address)));
            end if;
            if (write_enable = '1') then -- the data is written on the clock edge
                Memory_array (to_integer (unsigned(address))) <= data_in;
            end if;
        end if;
    end process;
end Artix;
