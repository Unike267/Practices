-- RTL of MULT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mult is
generic (  
        -- Number of bits that the input/output data has. 
        N_bits : in natural
        );
port (
        -- Clock signal
        clk : in std_logic;
        -- Mult in/out signals
        mult_in : in std_logic_vector (N_bits-1 downto 0);
        mult_out : out std_logic_vector(N_bits-1 downto 0)
     );
end mult;

architecture rtl of mult is

-- Declaration of signals

signal in_1 : unsigned ((N_bits/2)-1 downto 0) := (others => '0');
signal in_2 : unsigned ((N_bits/2)-1 downto 0) := (others => '0');

begin
  
    -- Assign inputs to the multipler 

    in_1 <= unsigned(mult_in(N_bits-1 downto N_bits/2));
    in_2 <= unsigned(mult_in((N_bits/2)-1 downto 0));

    -- Make multiplication and assign output

    mult_make : process ( clk )
        begin
            if( rising_edge (clk) ) then
                mult_out <= std_logic_vector(in_1 * in_2);
            end if;
    end process mult_make;

end rtl;
