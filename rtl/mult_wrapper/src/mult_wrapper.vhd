-- RTL of Mult_wrapper

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mult_wrapper is
generic (  
        -- Number of bits that the input/output data has
        N_bits : in natural;
        -- Log2 of number of elements that the FIFOs have; Both the same size; Number of FIFO elements has to be a power of two
        Log2_elements : in natural
        );
port (
        -- Mult_wrapper clocks and reset signals        
        clk_wr : in std_logic;
        clk_mult : in std_logic;
        clk_rd : in std_logic;
        rst : in std_logic;
        -- Mult_wrapper input/output data
        mult_wrapper_in : in std_logic_vector (N_bits-1 downto 0);
        mult_wrapper_out : out std_logic_vector (N_bits-1 downto 0);     
        -- Mult_wrapper write and read signals; 
        wr_mult_wrapper : in std_logic;
        rd_mult_wrapper : in std_logic;
        -- Mult_wrapper status signals
        full_mult_wrapper : out std_logic;
        empty_mult_wrapper : out std_logic
);
end mult_wrapper;

architecture rtl of mult_wrapper is

-- Declaration of signals
signal in_pre_mult : std_logic_vector(N_bits-1 downto 0) := (others => '0');
signal in_post_mult : std_logic_vector(N_bits-1 downto 0) := (others => '0');
signal rd_inter : std_logic := '0';
signal wr_inter : std_logic := '0';
signal empty_inter : std_logic := '0';
signal full_inter : std_logic := '0';

type t_states is (CHECK,READ,MULTI,WRITE);
signal state : t_states;
signal next_state : t_states;


begin

-- Fifo IN instantiation

fifo_IN : entity work.fifo  
                generic map (N_bits => N_bits,
                             Log2_elements => Log2_elements)
                port map (clk_wr => clk_wr, 
                          clk_rd => clk_mult, 
                          rst => rst, 
                          fifo_in => mult_wrapper_in, 
                          fifo_out => in_pre_mult,
                          wr => wr_mult_wrapper, 
                          rd => rd_inter, 
                          full_o => full_mult_wrapper, 
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
                          fifo_out => mult_wrapper_out, 
                          wr => wr_inter, 
                          rd => rd_mult_wrapper, 
                          full_o => full_inter, 
                          empty_o => empty_mult_wrapper);

-- State machine

    -- Combinational

    Combinational_of_state_machine : process (state, empty_inter, full_inter)
    begin
        next_state <= state;
        case state is
            when CHECK =>
                wr_inter <= '0';
                rd_inter <= '0';
                if empty_inter = '0' and full_inter = '0' then
                    next_state <= READ;
                end if;
            when READ =>
                wr_inter <= '0';
                rd_inter <= '1';
                next_state <= MULTI;
            when MULTI =>
                wr_inter <= '0';
                rd_inter <= '0';
                next_state <= WRITE;
            when WRITE =>
                wr_inter <= '1';
                rd_inter <= '0';
                next_state <= CHECK;
            when others =>
                next_state <= CHECK;
        end case;    
    end process Combinational_of_state_machine;

    -- Sequential

    state_machine_state_reg : process ( clk_mult )
    begin
        if( rising_edge(clk_mult) ) then
            if( rst ='1' ) then
                state <= CHECK;
            else
                state <= next_state;
            end if;
        end if;
    end process state_machine_state_reg;
    

end rtl;
