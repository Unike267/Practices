-- RTL of multp_wfifos_wishbone

library ieee;
context ieee.ieee_std_context;

entity multp_wfifos_wishbone is
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
end multp_wfifos_wishbone;

architecture rtl of multp_wfifos_wishbone is

signal reset, write, read, empty, full : std_logic;
signal ack_wr, ack_rd : std_logic;
signal stall : std_logic;
signal input : std_logic_vector(31 downto 0);
signal output : std_logic_vector(31 downto 0);

type state_t is (wait_in,ack_write,ack_read);
signal state : state_t;
signal next_state : state_t;

begin

-- Multp_wfifos instantation

multp_wfifos_0 : entity work.multp_wfifos
                 generic map (g_data_width => N_bits,
                              g_fifo_depth => Log2_elements)
                 port map (clk_in => clk_i,
                           clk_mult => clk_i,
                           clk_out => clk_i,
                           rst => reset,
                           din => input,
                           dout => output,
                           write => write,
                           read => read,
                           full => full,
                           empty => empty);

-- Reset (NEORV32 rst is low-active)

reset <= not rst_i;

-- Make error signal

err_o <= '0'; --tie to zero if not explicitly used

-- Make stall signal

stall <= full  when we_i = '1' else
         empty when we_i = '0';

stall_o <= stall;

--State machine
    --Sequential:
state_reg: process (clk_i,rst_i)
           begin
             if (rst_i = '0') then
                state <= wait_in;
             elsif (rising_edge(clk_i)) then
                state <= next_state;
             end if;
           end process state_reg;
    -- Combinatorial:
        -- Next states & outputs:
next_states : process (state,stb_i,cyc_i,we_i,adr_i,stall)
              begin
              next_state <= state;
                case state is
                    when wait_in =>
                        if((stb_i and cyc_i and we_i) = '1' and stall = '0' and adr_i = "10010000000000000000000000000000") then --In our case the address is 0x90000000; See main.c
                            input <= dat_i; 
                            write <= '1'; 
                            ack_wr <= '0';                          
                            next_state <= ack_write;
                        elsif(stb_i = '1' and cyc_i = '1' and we_i = '0' and stall = '0' and adr_i = "10010000000000000000000000000000") then 
                            dat_o <= (others => '0'); 
                            ack_rd <= '0';                           
                            read <= '1';
                            next_state <= ack_read;
                        else
                            input <= (others => '0'); 
                            write <= '0'; 
                            ack_wr <= '0';
                            dat_o <= (others => '0');  
                            read <= '0'; 
                            ack_rd <= '0';  
                            next_state <= wait_in;
                        end if;
                    when ack_write =>
                        input <= (others => '0'); 
                        write <= '0'; 
                        next_state <= wait_in;
                        ack_wr <= '1';
                    when ack_read =>
                        dat_o <= output;
                        read <= '0'; 
                        ack_rd <= '1';
                        next_state <= wait_in;
                end case;
              end process next_states;

ack_o <= ack_wr or ack_rd;

end rtl;
