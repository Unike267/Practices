-- RTL of mult_axis

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mult_wfifos_axis is
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
end mult_wfifos_axis;

architecture rtl of mult_wfifos_axis is

signal reset, write, read, valid, empty, full : std_logic;

begin

-- Mult_wfifos instantation

mult_wfifos_0 : entity work.mult_wfifos
                generic map (N_bits => N_bits,
                             Log2_elements => Log2_elements)
                port map (clk_wr => s_axis_clk,
                          clk_mult => clk_mult,
                          clk_rd => m_axis_clk,
                          rst => reset,
                          din => s_axis_data,
                          dout => m_axis_data,
                          wr => write,
                          rd => read,
                          full => full,
                          empty => empty);

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
