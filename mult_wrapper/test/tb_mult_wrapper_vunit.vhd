-- Behavioral of vunit test bench:

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_mult_wrapper_vunit is
    generic (runner_cfg : string);
end tb_mult_wrapper_vunit;

architecture behav of tb_mult_wrapper_vunit is

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
signal mult_wrapper_in : std_logic_vector (N_bits-1 downto 0);
signal mult_wrapper_out : std_logic_vector (N_bits-1 downto 0);
signal wr_mult_wrapper : std_logic;
signal rd_mult_wrapper : std_logic;
signal empty_mult_wrapper: std_logic;

-- Declariation of result array

type array_type is array ((2*(2**Log2_elements))-1 downto 0) of std_logic_vector(N_bits-1 downto 0);
signal res_array : array_type := (others => (others => '0'));

begin

-- Mult_wrapper instantation

mult_wrapper_0 : entity work.mult_wrapper
                generic map (N_bits => N_bits,
                             Log2_elements => Log2_elements)
                port map (clk_wr => clk_wr,
                          clk_mult => clk_mult,
                          clk_rd => clk_rd,
                          rst => rst,
                          mult_wrapper_in => mult_wrapper_in,
                          mult_wrapper_out => mult_wrapper_out,
                          wr_mult_wrapper => wr_mult_wrapper,
                          rd_mult_wrapper => rd_mult_wrapper,
                          full_mult_wrapper => open,
                          empty_mult_wrapper => empty_mult_wrapper);

--Generate clocks

clk_wr <= not clk_wr after Twr/2;
clk_mult <= not clk_mult after Tmult/2;
clk_rd <= not clk_rd after Trd/2;

tests : process
    begin
    test_runner_setup(runner, runner_cfg);
    report "Simulation start. ";
    -- Initialize
    rst <= '1';
    wr_mult_wrapper <= '0';
    rd_mult_wrapper <= '0';
    mult_wrapper_in <= (others=>'0');

    wait for Twr*5;

    rst <= '0';

    wait for Twr*5;

    if run("Write one read one") then
        report "This test writes one data and then reads it";
        
        mult_wrapper_in <= std_logic_vector(to_unsigned(5, 4)) & std_logic_vector(to_unsigned(5, 4)); -- 5 x 5 = 0101 x 0101

        wait for Twr*2;

        report "Input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wr_mult_wrapper <= '1';

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait until not empty_mult_wrapper;
        wait until rising_edge(clk_rd);

        report "Read output from the mult_wrapper";

        rd_mult_wrapper <= '1';

        wait for Trd;

        rd_mult_wrapper <= '0';

        wait for Trd;

        report "Expected output is: " & to_string(std_logic_vector(unsigned(mult_wrapper_in(7 downto 4)) * unsigned(mult_wrapper_in(3 downto 0))));
        report "Mult_wrapper output is: " & to_string(mult_wrapper_out);

        assert mult_wrapper_out = std_logic_vector(unsigned(mult_wrapper_in(7 downto 4)) * unsigned(mult_wrapper_in(3 downto 0)))
        report "This is a failure!";
    
    elsif run("Write all and try another") then
    report "This test fills both fifos (4 elements per fifo) and then try to write another data";

        wait until rising_edge(clk_wr);    
        
        mult_wrapper_in <= std_logic_vector(to_unsigned(15, 4)) & std_logic_vector(to_unsigned(0, 4)); -- 15 x 0 = 1111 x 0000

        wait for Twr*2;

        wr_mult_wrapper <= '1';

        report "First input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;
    
        wait until rising_edge(clk_wr);
        
        mult_wrapper_in <= std_logic_vector(to_unsigned(15, 4)) & std_logic_vector(to_unsigned(1, 4)); -- 15 x 1 = 1111 x 0001

        wait for Twr*2;

        wr_mult_wrapper <= '1';

        report "Second input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;

        wait until rising_edge(clk_wr);

        mult_wrapper_in <= std_logic_vector(to_unsigned(15, 4)) & std_logic_vector(to_unsigned(3, 4)); -- 15 x 3 = 1111 x 0011

        wait for Twr*2;

        wr_mult_wrapper <= '1';

        report "Third input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));
        
        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;

        wait until rising_edge(clk_wr);

        mult_wrapper_in <= std_logic_vector(to_unsigned(15, 4)) & std_logic_vector(to_unsigned(7, 4)); -- 15 x 7 = 1111 x 0111

        wait for Twr*2;

        wr_mult_wrapper <= '1';

        report "Fourth input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;
    
        wait until rising_edge(clk_wr);
        
        mult_wrapper_in <= std_logic_vector(to_unsigned(15, 4)) & std_logic_vector(to_unsigned(15, 4)); -- 15 x 15 = 1111 x 1111

        wait for Twr*2;

        wr_mult_wrapper <= '1';

        report "Now output FIFO is full and it's holding in the input FIFO";        
        report "Fifth input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wait for Twr;

        wr_mult_wrapper <= '0';
        
        wait for 5*Tmult;

        wait until rising_edge(clk_wr);    
        
        mult_wrapper_in <= std_logic_vector(to_unsigned(2, 4)) & std_logic_vector(to_unsigned(2, 4)); -- 2 x 2 = 0010 x 0010

        wait for Twr*2;

        wr_mult_wrapper <= '1';

        report "Sixth input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;
    
        wait until rising_edge(clk_wr);
        
        mult_wrapper_in <= std_logic_vector(to_unsigned(4, 4)) & std_logic_vector(to_unsigned(4, 4)); -- 4 x 4 = 0100 x 0100

        wait for Twr*2;

        wr_mult_wrapper <= '1';

        report "Seventh input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;

        wait until rising_edge(clk_wr);

        mult_wrapper_in <= std_logic_vector(to_unsigned(8, 4)) & std_logic_vector(to_unsigned(8, 4)); -- 8 x 8 = 1000 x 1000

        wait for Twr*2;

        wr_mult_wrapper <= '1';

        report "Eighth input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));
        
        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;

        wait until rising_edge(clk_wr);

        mult_wrapper_in <= std_logic_vector(to_unsigned(15, 4)) & std_logic_vector(to_unsigned(7, 4)); -- 10 x 10 = 1010 x 1010

        wait for Twr*2;

        wr_mult_wrapper <= '1';

        report "Now two FIFOs are full and this data " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0)) & " it`s going to lost"; 
        report "Open gui to see FIFO input array and check the lost data"; 

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 10*Tmult;

    elsif run("Write all read all") then
        report "This test writes all fifo (4 elements per fifo) and then reads all";
        
        res_array <= (others => (others => '0'));

        wait until rising_edge(clk_wr);    
        
        mult_wrapper_in <= std_logic_vector(to_unsigned(15, 4)) & std_logic_vector(to_unsigned(0, 4)); -- 15 x 0 = 1111 x 0000      
        
        wait for Twr*2;

        res_array(0) <= mult_wrapper_in;  
        wr_mult_wrapper <= '1';

        report "First input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;
    
        wait until rising_edge(clk_wr);
        
        mult_wrapper_in <= std_logic_vector(to_unsigned(15, 4)) & std_logic_vector(to_unsigned(1, 4)); -- 15 x 1 = 1111 x 0001

        wait for Twr*2;

        res_array(1) <= mult_wrapper_in;
        wr_mult_wrapper <= '1';

        report "Second input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;

        wait until rising_edge(clk_wr);

        mult_wrapper_in <= std_logic_vector(to_unsigned(15, 4)) & std_logic_vector(to_unsigned(3, 4)); -- 15 x 3 = 1111 x 0011

        wait for Twr*2;

        res_array(2) <= mult_wrapper_in;
        wr_mult_wrapper <= '1';

        report "Third input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));
        
        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;

        wait until rising_edge(clk_wr);

        mult_wrapper_in <= std_logic_vector(to_unsigned(15, 4)) & std_logic_vector(to_unsigned(7, 4)); -- 15 x 7 = 1111 x 0111

        wait for Twr*2;

        res_array(3) <= mult_wrapper_in;
        wr_mult_wrapper <= '1';

        report "Fourth input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;
    
        wait until rising_edge(clk_wr);
        
        mult_wrapper_in <= std_logic_vector(to_unsigned(15, 4)) & std_logic_vector(to_unsigned(15, 4)); -- 15 x 15 = 1111 x 1111

        wait for Twr*2;

        res_array(4) <= mult_wrapper_in;
        wr_mult_wrapper <= '1';

        report "Now output FIFO is full and it's holding in the input FIFO";        
        report "Fifth input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wait for Twr;

        wr_mult_wrapper <= '0';
        
        wait for 5*Tmult;

        wait until rising_edge(clk_wr);    
        
        mult_wrapper_in <= std_logic_vector(to_unsigned(2, 4)) & std_logic_vector(to_unsigned(2, 4)); -- 2 x 2 = 0010 x 0010

        wait for Twr*2;
    
        res_array(5) <= mult_wrapper_in;
        wr_mult_wrapper <= '1';

        report "Sixth input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;
    
        wait until rising_edge(clk_wr);
        
        mult_wrapper_in <= std_logic_vector(to_unsigned(4, 4)) & std_logic_vector(to_unsigned(4, 4)); -- 4 x 4 = 0100 x 0100

        wait for Twr*2;

        res_array(6) <= mult_wrapper_in;
        wr_mult_wrapper <= '1';

        report "Seventh input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 5*Tmult;

        wait until rising_edge(clk_wr);

        mult_wrapper_in <= std_logic_vector(to_unsigned(8, 4)) & std_logic_vector(to_unsigned(8, 4)); -- 8 x 8 = 1000 x 1000

        wait for Twr*2;

        res_array(7) <= mult_wrapper_in;
        wr_mult_wrapper <= '1';

        report "Eighth input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));
        
        wait for Twr;

        wr_mult_wrapper <= '0';

        wait for 10*Tmult;

        report "Now it's going to read";
        report "Read first data from the mult_wrapper";
        
        wait until rising_edge(clk_rd);

        rd_mult_wrapper <= '1';

        wait for Trd;

        rd_mult_wrapper <= '0';

        wait for Tmult*5;

        report "Expected output is: " & to_string(std_logic_vector(unsigned(res_array(0)(7 downto 4)) * unsigned(res_array(0)(3 downto 0)))); 
        report "Mult_wrapper output is: " & to_string(mult_wrapper_out);

        assert mult_wrapper_out = std_logic_vector(unsigned(res_array(0)(7 downto 4)) * unsigned(res_array(0)(3 downto 0))) -- 1111 x 0000 = 00000000
        report "This is a failure!";

        report "Read second data from the mult_wrapper";
        
        wait until rising_edge(clk_rd);

        rd_mult_wrapper <= '1';

        wait for Trd;

        rd_mult_wrapper <= '0';

        wait for Tmult*5;

        report "Expected output is: " & to_string(std_logic_vector(unsigned(res_array(1)(7 downto 4)) * unsigned(res_array(1)(3 downto 0))));
        report "Mult_wrapper output is: " & to_string(mult_wrapper_out);

        assert mult_wrapper_out = std_logic_vector(unsigned(res_array(1)(7 downto 4)) * unsigned(res_array(1)(3 downto 0))) -- 1111 x 0001 = 00001111
        report "This is a failure!";

        report "Read third data from the mult_wrapper";
        
        wait until rising_edge(clk_rd);

        rd_mult_wrapper <= '1';

        wait for Trd;

        rd_mult_wrapper <= '0';

        wait for Tmult*5;

        report "Expected output is: " & to_string(std_logic_vector(unsigned(res_array(2)(7 downto 4)) * unsigned(res_array(2)(3 downto 0))));
        report "Mult_wrapper output is: " & to_string(mult_wrapper_out);

        assert mult_wrapper_out = std_logic_vector(unsigned(res_array(2)(7 downto 4)) * unsigned(res_array(2)(3 downto 0))) -- 1111 x 0011 = 00101101
        report "This is a failure!";

        report "Read fourth data from the mult_wrapper";
        
        wait until rising_edge(clk_rd);

        rd_mult_wrapper <= '1';

        wait for Trd;

        rd_mult_wrapper <= '0';

        wait for Tmult*5;

        report "Expected output is: " & to_string(std_logic_vector(unsigned(res_array(3)(7 downto 4)) * unsigned(res_array(3)(3 downto 0))));
        report "Mult_wrapper output is: " & to_string(mult_wrapper_out);

        assert mult_wrapper_out = std_logic_vector(unsigned(res_array(3)(7 downto 4)) * unsigned(res_array(3)(3 downto 0))) -- 1111 x 0111 = 01101001
        report "This is a failure!";

        report "Read fifth data from the mult_wrapper";
        
        wait until rising_edge(clk_rd);

        rd_mult_wrapper <= '1';

        wait for Trd;

        rd_mult_wrapper <= '0';

        wait for Tmult*5;

        report "Expected output is: " & to_string(std_logic_vector(unsigned(res_array(4)(7 downto 4)) * unsigned(res_array(4)(3 downto 0))));
        report "Mult_wrapper output is: " & to_string(mult_wrapper_out);

        assert mult_wrapper_out = std_logic_vector(unsigned(res_array(4)(7 downto 4)) * unsigned(res_array(4)(3 downto 0))) -- 1111 x 1111 = 11100001
        report "This is a failure!";

        report "Read sixth data from the mult_wrapper";
        
        wait until rising_edge(clk_rd);

        rd_mult_wrapper <= '1';

        wait for Trd;

        rd_mult_wrapper <= '0';

        wait for Tmult*5;

        report "Expected output is: " & to_string(std_logic_vector(unsigned(res_array(5)(7 downto 4)) * unsigned(res_array(5)(3 downto 0))));
        report "Mult_wrapper output is: " & to_string(mult_wrapper_out);

        assert mult_wrapper_out = std_logic_vector(unsigned(res_array(5)(7 downto 4)) * unsigned(res_array(5)(3 downto 0))) -- 0010 x 0010 = 00000100
        report "This is a failure!";

        report "Read seventh data from the mult_wrapper";
        
        wait until rising_edge(clk_rd);

        rd_mult_wrapper <= '1';

        wait for Trd;

        rd_mult_wrapper <= '0';

        wait for Tmult*5;

        report "Expected output is: " & to_string(std_logic_vector(unsigned(res_array(6)(7 downto 4)) * unsigned(res_array(6)(3 downto 0))));
        report "Mult_wrapper output is: " & to_string(mult_wrapper_out);

        assert mult_wrapper_out = std_logic_vector(unsigned(res_array(6)(7 downto 4)) * unsigned(res_array(6)(3 downto 0))) -- 0100 x 0100 = 00010000
        report "This is a failure!";

        report "Read eighth data from the mult_wrapper";
        
        wait until rising_edge(clk_rd);

        rd_mult_wrapper <= '1';

        wait for Trd;

        rd_mult_wrapper <= '0';

        wait for Tmult*5;

        report "Expected output is: " & to_string(std_logic_vector(unsigned(res_array(7)(7 downto 4)) * unsigned(res_array(7)(3 downto 0))));
        report "Mult_wrapper output is: " & to_string(mult_wrapper_out);

        assert mult_wrapper_out = std_logic_vector(unsigned(res_array(7)(7 downto 4)) * unsigned(res_array(7)(3 downto 0))) -- 1000 x 1000 = 01000000
        report "This is a failure!";

        wait for Tmult*20;
        
    elsif run("Read twice") then
        report "This test writes one data, then reads it and then try to read again";

        mult_wrapper_in <= std_logic_vector(to_unsigned(5, 4)) & std_logic_vector(to_unsigned(5, 4)); -- 5 x 5 = 0101 x 0101

        wait for Twr*2;

        report "Input data to write is: " & to_string(mult_wrapper_in(7 downto 4)) & " x " & to_string(mult_wrapper_in(3 downto 0));

        wr_mult_wrapper <= '1';

        wait for Twr;

        wr_mult_wrapper <= '0';

        wait until not empty_mult_wrapper;
        wait until rising_edge(clk_rd);

        report "Read output from the mult_wrapper";

        rd_mult_wrapper <= '1';

        wait for Trd;

        rd_mult_wrapper <= '0';

        wait for Trd;
        
        report "Mult_wrapper output is: " & to_string(mult_wrapper_out);
        
        report "Read output from the mult_wrapper again";

        rd_mult_wrapper <= '1';

        wait for Trd;

        rd_mult_wrapper <= '0';

        wait for Trd;

        report "Expected output is: " & to_string(std_logic_vector(unsigned(mult_wrapper_in(7 downto 4)) * unsigned(mult_wrapper_in(3 downto 0))));
        report "Mult_wrapper output is: " & to_string(mult_wrapper_out);

        assert mult_wrapper_out = std_logic_vector(unsigned(mult_wrapper_in(7 downto 4)) * unsigned(mult_wrapper_in(3 downto 0)))
        report "This is a failure!";
      
    end if;
    report "Simulation end. ";
    test_runner_cleanup(runner); -- Simulation ends here
    end process tests; 
end behav;
