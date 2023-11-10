-- Behavioral of vunit test bench:

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_acceler_vunit_auto is
    generic (runner_cfg : string);
end tb_acceler_vunit_auto;

architecture behav of tb_acceler_vunit_auto is

-- Declaration of constants

constant Twr : time := 25 ns; -- period for write
constant Tmult : time := 10 ns; -- period for mult
constant Trd : time := 27 ns; -- period for read
constant N_bits : natural := 8; -- 8 bits (4 bits plus 4 bits)
constant Log2_elements : natural := 2; -- Log2 is 2 ergo FIFO has 4 elements

-- Declaration of signals

signal clk_wr : std_logic := '0';
signal clk_mult : std_logic := '0';
signal clk_rd : std_logic := '0';
signal rst : std_logic := '0';
signal acceler_in : std_logic_vector (N_bits-1 downto 0);
signal acceler_out : std_logic_vector (N_bits-1 downto 0);
signal wr_acceler : std_logic;
signal rd_acceler : std_logic;
signal empty_acceler: std_logic;
signal start, write_ok, read_ok : boolean := false;

begin

-- Acceler instantation

acceler_0 : entity work.acceler
                generic map (N_bits => N_bits,
                             Log2_elements => Log2_elements)
                port map (clk_wr => clk_wr,
                          clk_mult => clk_mult,
                          clk_rd => clk_rd,
                          rst => rst,
                          acceler_in => acceler_in,
                          acceler_out => acceler_out,
                          wr_acceler => wr_acceler,
                          rd_acceler => rd_acceler,
                          full_acceler => open,
                          empty_acceler => empty_acceler);
--Generate clocks

clk_wr <= not clk_wr after Twr/2;
clk_mult <= not clk_mult after Tmult/2;
clk_rd <= not clk_rd after Trd/2;

    main : process
    begin
        test_runner_setup(runner, runner_cfg);        
        if run ("test") then
            -- Initialize
            rst <= '1';
            wait for Twr*5;
            rst <= '0';

            report "Simulation start. ";
            
            wait until rising_edge(clk_mult);
            start <= true;
            wait until rising_edge(clk_mult);
            start <= false;
            wait until (write_ok and read_ok and rising_edge(clk_mult));
            report "Simulation end. ";
            test_runner_cleanup(runner); -- Simulation ends here
        end if;
    end process main;

    write : process
    begin
        wr_acceler <= '0';     
        acceler_in <= (others=>'0'); 
        wait until start and rising_edge(clk_mult);
        write_ok <= false;  
        wait until rising_edge(clk_mult);
        
        report "Initialize to write";

        for x in 0 to (2**Log2_elements)-1 loop
            wait until rising_edge(clk_wr);

            acceler_in <= std_logic_vector(to_unsigned(x, 4)) & std_logic_vector(to_unsigned(x, 4));
            
            wait for Twr*2;

            report "Input data (" & integer'image(x) & ") to write is: " & to_string(acceler_in(7 downto 4)) & " x " & to_string(acceler_in(3 downto 0));

            wr_acceler <= '1';

            wait for Twr;

            wr_acceler <= '0';

            wait for Twr;

            -- Wait until make a read for put new data into input

            wait until falling_edge(rd_acceler);
            wait for Trd;

        end loop;

        wait until rising_edge(clk_mult);
        write_ok <= true;
    
    end process write;

    read : process
    begin   
        rd_acceler <= '0';
        wait until start and rising_edge(clk_mult);
        read_ok <= false;
        wait until rising_edge(clk_mult);
        
        report "Initialize to read";

        for x in 0 to (2**Log2_elements)-1 loop
            wait until not empty_acceler;
            wait until rising_edge(clk_rd);

            report "Read output from the acceler";

            rd_acceler <= '1';

            wait for Trd;

            rd_acceler <= '0';

            wait for Trd;
            
            report "Expected output is: " & to_string(std_logic_vector(unsigned(acceler_in(7 downto 4)) * unsigned(acceler_in(3 downto 0))));
            report "Acceler output is: " & to_string(acceler_out);

            assert acceler_out = std_logic_vector(unsigned(acceler_in(7 downto 4)) * unsigned(acceler_in(3 downto 0)))
            report "This is a failure!";
              
        end loop;

        wait until rising_edge(clk_mult);
        read_ok <= true;
    end process read;

end behav;
