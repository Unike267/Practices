-- RTL of FIFO

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
generic (  
        -- Number of bits per element 
        N_bits : in natural;
        -- Log2 of number of elements that the FIFO has; Number of FIFO elements has to be a power of two.
        Log2_elements : in natural
        );
port (
        -- Fifo clocks/reset signals        
        clk_wr : in std_logic;
        clk_rd : in std_logic;
        rst : in std_logic;
        -- Fifo in/out signals
        fifo_in : in std_logic_vector (N_bits-1 downto 0);
        fifo_out : out std_logic_vector(N_bits-1 downto 0);
        -- Fifo write/read signals
        wr : in std_logic;
        rd : in std_logic;
        -- Fifo status signals
        full_o : out std_logic;
        empty_o : out std_logic
     );
end fifo;

architecture rtl of fifo is

-- Declariation of fifo array

type array_type is array ((2**Log2_elements)-1 downto 0) of std_logic_vector(N_bits-1 downto 0);
signal fifo_array : array_type := (others => (others => '0'));

-- Declaration of signals

signal wr_pnt : std_logic_vector(Log2_elements downto 0) := (others => '0');
signal rd_pnt : std_logic_vector(Log2_elements downto 0) := (others => '0');
signal full : std_logic := '0';
signal empty : std_logic := '0';


begin

    -- Signals empty and full logic
    
    full_logic : process ( wr_pnt,rd_pnt )
    begin   
        if( (wr_pnt(Log2_elements-1 downto 0) = rd_pnt(Log2_elements-1 downto 0)) and ( (wr_pnt(wr_pnt'left) xor rd_pnt(rd_pnt'left)) = '1') ) then
            full <= '1';
        else
            full <= '0';
        end if;
    end process full_logic;    

    empty_logic : process ( wr_pnt,rd_pnt )  
    begin
        if ( wr_pnt = rd_pnt ) then
            empty <= '1';
        else
            empty <= '0';
        end if;
    end process empty_logic;

    -- Assign control signals output

    full_o <= full;
    empty_o <= empty;

    -- Write and read process

    write_process: process (clk_wr)
    begin
        if( rising_edge( clk_wr ) ) then
            if( rst = '1' ) then
                wr_pnt <= (others => '0');
            elsif( wr = '1' and full = '0' ) then
                fifo_array(to_integer(unsigned(wr_pnt(Log2_elements-1 downto 0)))) <= fifo_in;
                wr_pnt <= std_logic_vector(unsigned(wr_pnt) + 1);
            end if;                 
        end if;
    end process write_process;

    read_process: process (clk_rd)
    begin
        if( rising_edge( clk_rd ) ) then
            if( rst = '1' ) then
                rd_pnt <= (others => '0');
                fifo_out <= (others => '0');
            elsif( rd = '1' and empty = '0' ) then
                fifo_out <= fifo_array(to_integer(unsigned(rd_pnt(Log2_elements-1 downto 0))));
                rd_pnt <= std_logic_vector(unsigned(rd_pnt) + 1);
            end if;                 
        end if;
    end process read_process;

end rtl;
