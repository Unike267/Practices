-- RTL of Mult_wfifos

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mult_wfifos is
generic (
        -- Number of bits that the input/output data has
        N_bits : in natural;
        -- Log2 of number of elements that the FIFOs have; Both the same size; Number of FIFO elements has to be a power of two
        Log2_elements : in natural
        );
port (
        -- Mult_wfifos clocks and reset signals
        clk_wr : in std_logic;
        clk_mult : in std_logic;
        clk_rd : in std_logic;
        rst : in std_logic;
        -- Mult_wfifos input/output data
        din : in std_logic_vector (N_bits-1 downto 0);
        dout : out std_logic_vector (N_bits-1 downto 0);
        -- Mult_wfifos write and read signals;
        wr : in std_logic;
        rd : in std_logic;
        -- Mult_wfifos status signals
        full : out std_logic;
        empty : out std_logic
);
end mult_wfifos;

architecture rtl of mult_wfifos is

-- Declaration of signals
signal in_pre_mult : std_logic_vector(N_bits-1 downto 0) := (others => '0');
signal in_post_mult : std_logic_vector(N_bits-1 downto 0) := (others => '0');
signal rd_inter : std_logic := '0';
signal wr_inter : std_logic := '0';
signal empty_inter : std_logic := '0';
signal full_inter : std_logic := '0';

type t_states is (CHECK,READ,MULTI,WRITE);
signal state : t_states := CHECK;
signal next_state : t_states;


begin

-- Fifo IN instantiation

fifo_IN : entity work.fifo
                generic map (N_bits => N_bits,
                             Log2_elements => Log2_elements)
                port map (clk_wr => clk_wr,
                          clk_rd => clk_mult,
                          rst => rst,
                          fifo_in => din,
                          fifo_out => in_pre_mult,
                          wr => wr,
                          rd => rd_inter,
                          full_o => full,
                          empty_o => empty_inter);

-- mult instantiation

mult_0 : entity  work.mult
                generic map (N_bits => N_bits)
                port map (clk => clk_mult,
                          mult_in => in_pre_mult,
                          mult_out => in_post_mult);

-- Fifo OUT instantiation

fifo_OUT : entity work.fifo
                generic map (N_bits => N_bits,
                             Log2_elements => Log2_elements)
                port map (clk_wr => clk_mult,
                          clk_rd => clk_rd,
                          rst => rst,
                          fifo_in => in_post_mult,
                          fifo_out => dout,
                          wr => wr_inter,
                          rd => rd,
                          full_o => full_inter,
                          empty_o => empty);

-- State machine
    -- Combinational

    Combinational_of_state_machine : process (state, empty_inter, full_inter)
    begin
        next_state <= state;
        case state is
            when CHECK =>
                if (empty_inter = '0' and full_inter = '0') then
                    next_state <= READ;
                else
                    next_state <= CHECK;
                end if;
            when READ =>
                next_state <= MULTI;
            when MULTI =>
                next_state <= WRITE;
            when WRITE =>
                next_state <= CHECK;
            when others =>
                next_state <= CHECK;
        end case;
    end process Combinational_of_state_machine;

    -- Outputs

    with state select
        wr_inter <= '1' when WRITE,
                    '0' when others;
    with state select
        rd_inter <= '1' when READ,
                    '0' when others;

    -- Sequential

    state_machine_state_reg : process ( clk_mult )
    begin
        if( rising_edge(clk_mult) ) then
            if( rst = '1' ) then
                state <= CHECK;
            else
                state <= next_state;
            end if;
        end if;
    end process state_machine_state_reg;

end rtl;
