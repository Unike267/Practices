-- RTL of acceler axi buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity acceler_axi_buffer is
generic (  
        -- Number of bits that the input/output data has
        N_bits : in natural;
        -- Log2 of number of elements that the FIFOs have; Both the same size; Number of FIFO elements has to be a power of two
        Log2_elements : in natural
        );
port (
    -- Clk mult
    clk_mult : in std_logic;    

    -- Slave signals
    s_axis_clk   : in  std_logic;
    s_axis_rstn  : in  std_logic;
    s_axis_rdy   : out std_logic;
    s_axis_data  : in  std_logic_vector(N_bits-1 downto 0);
    s_axis_valid : in  std_logic;

    -- Master signals
    m_axis_clk   : in  std_logic;
    m_axis_rstn  : in  std_logic;
    m_axis_valid : out std_logic;
    m_axis_data  : out std_logic_vector(N_bits-1 downto 0);
    m_axis_rdy   : in  std_logic
    );
end acceler_axi_buffer;

architecture rtl of acceler_axi_buffer is

component acceler is
generic (  
        -- Number of bits that the input/output data has
        N_bits : in natural;
        -- Log2 of number of elements that the FIFOs have; Both the same size; Number of FIFO elements has to be a power of two
        Log2_elements : in natural
        );
port (
        -- Acceler clocks and reset signals        
        clk_wr : in std_logic;
        clk_mult : in std_logic;
        clk_rd : in std_logic;
        rst : in std_logic;
        -- Acceler input/output data
        acceler_in : in std_logic_vector (N_bits-1 downto 0);
        acceler_out : out std_logic_vector (N_bits-1 downto 0);     
        -- Acceler write and read signals; 
        wr_acceler : in std_logic;
        rd_acceler : in std_logic;
        -- Acceler status signals
        full_acceler : out std_logic;
        empty_acceler : out std_logic
);
end component;

signal reset, write, read, valid, empty, full : std_logic;

begin

-- Acceler instantation

acceler_0 : acceler
 generic map (
  N_bits => N_bits,
  Log2_elements => Log2_elements
 )
 port map (
  clk_wr => s_axis_clk,
  clk_mult => clk_mult,
  clk_rd => m_axis_clk,
  rst => reset,
  acceler_in => s_axis_data,
  acceler_out => m_axis_data,
  wr_acceler => write,
  rd_acceler => read,
  full_acceler => full,
  empty_acceler => empty
);

-- Reset (NEORV32 rst is low-active)

reset <= (s_axis_rstn nand m_axis_rstn);

-- Write and read signals

write <= s_axis_valid and not(full);

read <= not(empty) and (valid nand not(m_axis_rdy));

-- Make valid signal

make_valid : process(m_axis_clk) begin
    if rising_edge(m_axis_clk) then
        if (((not m_axis_rstn) or ((valid and empty) and m_axis_rdy)) = '1') then
            valid <= '0';
        elsif (read = '1') then
            valid <= '1';
        end if;
    end if;
    end process make_valid;

-- Assing axi signals

s_axis_rdy <= not(full);
m_axis_valid <= valid;

end rtl;
