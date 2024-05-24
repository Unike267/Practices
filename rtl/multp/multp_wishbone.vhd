-- RTL of multp_wfifos_wishbone

library ieee;
context ieee.ieee_std_context;

entity multp_wishbone is
generic (  
        -- Number of bits that the input/output data has
        N_bits : in natural
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
end multp_wishbone;

architecture rtl of multp_wishbone is

signal reset : std_logic;
signal ack : std_logic;
signal input : std_logic_vector(31 downto 0);
signal output : std_logic_vector(31 downto 0);
signal transfer_in : std_logic;
signal transfer_out : std_logic;

begin

-- Multp instantation

multp_0 : entity work.multp_op
                 generic map (g_data_width => N_bits)
                 port map (din => input,
                           dout => output);

-- Reset (NEORV32 rst is low-active)

reset <= not rst_i;

-- Make error signal

err_o <= '0'; --tie to zero if not explicitly used

-- Make stall signal

stall_o <= '0';

-- Make transfer in/out signals

transfer_in  <= (stb_i and cyc_i and we_i) when adr_i = "10010000000000000000000000000000" else
                '0';

transfer_out <= (stb_i and cyc_i and not(we_i)) when adr_i = "10010000000000000000000000000000" else
                '0';

-- Manage inputs/outputs

process (clk_i) begin
    if rising_edge(clk_i) then
      if reset = '1' then
        input <= (others=>'0');
        dat_o <= (others=>'0');
      elsif transfer_in then
        input <= dat_i;
        dat_o <= (others=>'0');
      elsif transfer_out then
        dat_o <= output;
      else
        dat_o <= (others=>'0');
      end if;
    end if;
end process;

-- Make ack signal

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
