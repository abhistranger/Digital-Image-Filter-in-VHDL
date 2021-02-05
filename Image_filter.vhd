library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity Image_filter is
    port(
    clock : in std_logic; -- clock of 100MHz 
    reset : in std_logic; -- reset for initiation of state
    start : in std_logic; -- start button to stat filtering
    switch : in std_logic -- switch to decide which filter is to be done. value=0 means Smoothening and value=1 means Sharpening
    );
end entity;

architecture main of Image_filter is
    component RAM_64Kx8 is -- RAM component instantiation
        port (
        clock : in std_logic;
        read_enable, write_enable : in std_logic; -- signals that enable read/write operation
        address : in std_logic_vector(15 downto 0); -- 2^16 = 64K
        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0)
        );
    end component;
    component ROM_32x9 is -- ROM component instantiation
        port (
        clock : in std_logic;
        read_enable : in std_logic; -- signal that enables read operation
        address : in std_logic_vector(4 downto 0); -- 2^5 = 32
        data_out : out std_logic_vector(8 downto 0)
        );
    end component;
    component MAC is -- MAC component instantiation
        port (
        clock : in std_logic;
        control : in std_logic; -- ‘0’ for initializing the sum
        data_in1, data_in2 : in std_logic_vector(17 downto 0);
        data_out : out std_logic_vector(17 downto 0)
        );
    end component;
    type state_type is (A0,A1,A2); --state type defining three states A0,A1,A2
    signal state : state_type; -- state defining
    signal done : std_logic; -- will tell image filteration is done or not, when done it become 0
    signal read_enable : std_logic; --read_enable will tell ram and rom to read when value of it will be 1
    signal write_enable: std_logic; --write_enable will tell ram to write some data inti memory
    signal sub_count: unsigned(3 downto 0); --sub_count will vary from 0 to 10 as it will track of all the work for one value of (I,J) of final image. 0 to 8 for read, 1 to 9 for MAC and 10th for write as read for ram and rom will give data after clock edge
    signal count: unsigned(14 downto 0); -- count will vary from 0 to 18643((118*158)-1) as it will keep track for the for how much (I,J) the work is done, total no of (I,J) is 118*158.
    signal count_col: unsigned(7 downto 0); -- count_col will vary from 0 to 157 as it will keep track how many columns for one row is done. when it will become 157 then we have to increment address_rom1,2,3 by 3.(reason explained in overview)
    signal address_ram1,address_ram2,address_ram3,address_write;address_ram: std_logic_vector(15 downto 0); -- address ram1,2,3 are three vector and address_ram will choose value from these 3 depending upon sub_count
    signal address_rom: std_logic_vector(4 downto 0); -- address_rom is the address given to rom for read, it will start from 0 for Smoothening and 16 for sharpening
    signal data_final: std_logic_vector(7 downto 0); -- data_final is 8 bit vector which will be given to ram when write is to be done
    signal data_out_MAC: std_logic_vector(17 downto 0); -- data_out_MAC is 18 bit product result for one (I,J) which will be given by MAC
    signal button_pressed: std_logic_vector; -- it will keep track that start button will be checked only one time for one 1.
    signal data_in1,data_in2: std_logic_vector(17 downto 0);
    signal data_out_ram: std_logic_vector(7 downto 0);
    signal data_out_rom: std_logic_vector(8 downto 0);

begin
    process(clock,reset)  -- state transition
    begin
        if reset = '1' then state <= A0; -- initial state
        elsif (clock'event and clock = '1') then --rising edge
            case state is
                when A0 => 
                    if start='1' then --when in satate A0 if start=1 then depending on the values of button_pressed and switch it will go into other state 
                        button_pressed<='1';  -- and button_pressed will be 1 and remain 1 until start become 0
                        if button_pressed='0' then --checks if button_pressed=0 or not as(as button_pressed value which is checked at the clock edge is previous value not the modified at the clock cycle)
                                                   -- if it is 0 then change state as if it is 1 then its work is alredy done. 
                            if switch='0' then state<=A1; --switch 0 then state will be A1 for Smoothening
                            else state<=A2; --switch 1 then state will be A2 for Sharpening
                            end if;
                        end if;
                    elsif start='0' then button_pressed<='0'; -- to make button_pressed=0 when start=0
                    end if;
                when A1 =>
                    if done ='1' then state<=A0; --when done=1 that is image is filtered and stored then state will change to A0
                    elsif start<='0' then button_pressed<='0' -- to make button_pressed=0 when start=0
                    end if;
                when A2 =>
                    if done ='1' then state<=A0; --when done=1 that is image is filtered and stored then state will change to A0
                    elsif start<='0' then button_pressed<='0' -- to make button_pressed=0 when start=0(as it may happen in any state)
                    end if;
            end case;
        end if;
    end process;

    process (state,start,count,sub_count) -- data control
    begin
        done <= '0'; read_enable <= '0'; write_enable <= '0'; --variables which is to be 0 when not not specified in state case below
        control<='1'; -- variable which is to be 1 when not not specified in state case below
        case state is
            when A0 => 
                control<='0'; -- control will be zero in state A0
                if start='1' and button_pressed="0" then read_enable<='1'; -- when states changes from A0 to A1 or A2 the read_enable will become 1 for read 
                end if;
            when A1 =>
                if count="100100011010011" then done<='1'; --when in state 
                end if;
                if sub_count="0000" then control<='0';
                end if;
                if sub_count="1001" or sub_count="1010" then read_enable <='0'; -- when sub_count =9 or 10 then read_enable should be 0 as we have to read from 0 to 8 only where it will be 1
                else read_enable <='1';
                end if;
                if sub_count="1010" then write_enable<='1'; -- when sub_count will be 10 then write_enable should be 1 as we have to write at 10th else 0
                else write_enable<='0';
                end if;
            when A2 =>
                if count="100100011010011" then done<='1';-- same as in state A1
                end if;
                if sub_count="0000" then control<='0';
                end if;
                if sub_count="1001" then read_enable <='0'; 
                else read_enable <='1';
                end if;
                if sub_count="1010" then write_enable<='1';
                else write_enable<='0';
                end if;
        end case;
    end process;
    
    process(sub_count,data_out_MAC,data_out_rom)
    begin
        case sub_count is -- choosing address_ram for read and write in ram depending on sub_count
            when "0000" => address_ram<=address_ram1;    
            when "0001" => address_ram<=address_ram1+1; 
            when "0010" => address_ram<=address_ram1+2; 
            when "0011" => address_ram<=address_ram2; 
            when "0100" => address_ram<=address_ram2+1; 
            when "0101" => address_ram<=address_ram2+2; 
            when "0110" => address_ram<=address_ram3; 
            when "0111" => address_ram<=address_ram3+1;  
            when "1000" => address_ram<=address_ram3+2;   
            when others => address_ram<=address_write; 
        end case;
        if data_out_MAC(15)='1' then data_final<="00000000"; -- choosing the data_final which is to be stored in ram by write as it has to be 8-bit
        else data_final<=data_out_MAC(14 downto 7); -- when the first bit is 1 in 9-bit of data_out_MAC after product and ignoring first two bit and last 7 then the data_final to store will be 0
                                                    -- otherwise it will be the remaing 8 bit of the 9-bit
        end if;
        if data_out_rom(8)='1' then data_in2<="111111111" & data_out_rom; -- converting the 9 bit data_out_ram as read from ram to 18 bit so as to give it in MAC
        else data_in2 <= "000000000" & data_out_rom; -- when 9th bit is 1 means negative so add 10 1s before and when 9th bit is 0 means positive then add 10 0s.
        end if;
    end process;

    data_in1 <= "0000000000" & data_out_ram; -- converting the 8 bit data_out_ram as read from ram to 18 bit so as to give it in MAC
   
    -- component call using port map 
    RAM_64Kx8: RAM_64Kx8 port map(clock,read_enable,write_enable,address_ram,data_final,data_out_ram);
    ROM_32x9: ROM_32x9 port map(clock,read_enable,address_rom,data_out_rom);
    MAC: MAC port map(clock,control,data_in1,data_in2,data_out_MAC);

    counter_sub_count: process (clock) --counter for sub_count and address_rom
    begin
        if (clock'event and clock = '1') then
            case state is
                when A0=> sub_count<="0000"; -- when state will be A0 the sub_count will be 0
                    if switch='1' then address_rom<="10000"; --when switch=1 the initial value of address_rom will be 16 otherwise 0
                    else address_rom<="00000";
                    end if;
                when A1=> sub_count <= sub_count+1;address_rom <=address_rom+1; --increment both sub_count and address_rom by 1 for each clock edge when it is in A1
                    if sub_count="1010" then sub_count<="0000";address_rom<="00000"; -- when sub_count will be 10 then for one(I,J) work is done so both sub_count and address_rom become 0
                    end if;
                when A2=> sub_count <=sub_count+1;address_rom <=address_rom+1; --increment both sub_count and address_rom by 1 for each clock edge when it is in A1
                    if sub_count="1010" then sub_count<="0000";address_rom<="10000"; -- when sub_count will be 10 then for one(I,J) work is done so both sub_count and address_rom become 0
                    end if;
            end case;
      	end if;
    end process;

    counter_count: process (clock)
    begin
        if (clock'event and clock = '1') then -- counter for count, address_ram1,2,3 and address_write
            case state is
                -- when in state A0 all the inital value of each parameter will be there
                when A0 => address_ram1 <="0000000000000000"; address_ram2 <="0000000010100000";address_ram3 <="0000000101000000";address_write<="1000000000000000"; count<="000000000000000";count_col<="00000000"; 
                when A1 => if sub_count="1010" then count <= count+1;address_write<=address_write+1; -- when subcount become 10 then write and count will be incremented by 1 
                		   elsif sub_count="1001" then -- when sub_count become 9 then the depending on count_col value the address_ram1,2,3 and count_col will change
                               if(count_col="10011101") then address_ram1<=address_ram1+3; address_ram2<=address_ram2+3;address_ram3<=address_ram3+3;count_col<="00000000";
                               else address_ram1<=address_ram1+1; address_ram2<=address_ram2+1;address_ram3<=address_ram3+1;count_col<=count_col+1;
                               end if;
                           end if;
                when A2 => if sub_count="1010" then count <= count+1;address_write<=address_write+1; --same as in state A1
                		   elsif sub_count="1001" then
                               if(count_col="10011101") then address_ram1<=address_ram1+3; address_ram2<=address_ram2+3;address_ram3<=address_ram3+3;count_col<="00000000";
                               else address_ram1<=address_ram1+1; address_ram2<=address_ram2+1;address_ram3<=address_ram3+1;count_col<=count_col+1;
                               end if;
                           end if;
            end case;
        end if;
    end process;   
end main;

