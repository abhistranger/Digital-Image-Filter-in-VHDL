library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity MAC is
    port (
    clock : in std_logic;
    control : in std_logic; -- ‘0’ for initializing the sum
    data_in1, data_in2 : in std_logic_vector(17 downto 0);
    data_out : out std_logic_vector(17 downto 0)
    );
end MAC;

architecture Artix of MAC is
    signal sum, product : signed (17 downto 0);
begin
    data_out <= std_logic_vector (sum);
    product <= signed (data_in1) * signed (data_in2)
    process (clock) begin
        if rising_edge (clock) then -- sum is available after clock edge
            if (control = '0') then -- initialize the sum with the first product
                sum <= std_logic_vector (product);
            else -- add product to the previous sum
                sum <= std_logic_vector (product + signed (sum));
            end if;
        end if;
    end process;
end Artix;
