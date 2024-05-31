-- RTL of mult_wfifos_wishbone

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mult_wfifos_wishbone is
generic (  
        -- Number of bits that the input/output data has
        N_bits : in natural;
        -- Log2 of number of elements that the FIFOs have; Both the same size; Number of FIFO elements has to be a power of two
        Log2_elements : in natural
        );
port (
    rst_i : in std_logic;
    clk_i : in std_logic;
    adr_i : in std_logic_vector(31 downto 0);
    dat_i : in std_logic_vector(31 downto 0);
    dat_o : out std_logic_vector(31 downto 0);
    we_i : in std_logic;
    sel_i : in std_logic_vector(3 downto 0);
    stb_i : in std_logic;
    ack_o : out std_logic;
    cyc_i : in std_logic;
    err_o : out std_logic;
    stall_o : out std_logic
    );
end mult_wfifos_wishbone;

architecture rtl of mult_wfifos_wishbone is

signal reset, write, read, empty, full : std_logic;
signal ack : std_logic;
signal stall : std_logic;
signal input : std_logic_vector(31 downto 0);
signal output : std_logic_vector(31 downto 0);
signal transfer_in : std_logic;
signal transfer_out : std_logic;
signal output_window : std_logic := '0';

begin

-- Mult_wfifos instantation

mult_wfifos_0 : entity work.mult_wfifos
                generic map (N_bits => N_bits,
                             Log2_elements => Log2_elements)
                port map (clk_wr => clk_i,
                          clk_mult => clk_i,
                          clk_rd => clk_i,
                          rst => reset,
                          din => input,
                          dout => output,
                          wr => write,
                          rd => read,
                          full => full,
                          empty => empty);

-- Reset (NEORV32 rst is low-active)

reset <= not rst_i;

-- Make error signal

err_o <= '0'; --tie to zero if not explicitly used

-- Make stall signal

with we_i select 
     stall <= full  when '1',
              empty when others;

stall_o <= stall;

-- Make transfer in/out signals

transfer_in  <= (stb_i and cyc_i and we_i and not(stall)) when adr_i = x"90000000" else  -- The address is 0x90000000; See main.c in sw/EMEM
                '0';

transfer_out <= (stb_i and cyc_i and not(we_i) and not(stall)) when adr_i = x"90000000" else
                '0';

-- Manage input/output and write/read signals

with transfer_in select
     input <= dat_i when '1',
              (others => '0') when others;

with transfer_in select
     write <= '1' when '1',
              '0' when others;

with transfer_out select
     read  <= '1' when '1',
              '0' when others;

with output_window select
     dat_o <= output when '1',
              (others => '0') when others;

-- Manage output_window

process (clk_i) begin
    if rising_edge(clk_i) then
      if reset = '1' then
        output_window <= '0';
      elsif transfer_out = '1' then
        output_window <= '1';
      else
        output_window <= '0';
      end if;
    end if;
end process;

-- Manage ack signal

process (clk_i) begin
    if rising_edge(clk_i) then
      if reset = '1' then
        ack <= '0';
      else
        if transfer_in or transfer_out then
          ack <= '1';
        else
          ack <= '0';
        end if;
      end if;
    end if;
  end process;
                
ack_o <= ack;

end rtl;
