-- Behavioral of vunit test bench:

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_mult is
    generic (runner_cfg : string);
end tb_mult;

architecture behav of tb_mult is

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
signal din : std_logic_vector (N_bits-1 downto 0);
signal dout : std_logic_vector (N_bits-1 downto 0);
signal wr : std_logic;
signal rd : std_logic;
signal empty: std_logic;

-- Declariation of result array

type array_type is array ((2*(2**Log2_elements))-1 downto 0) of std_logic_vector(N_bits-1 downto 0); -- Is 2* because this array it's going to save the result of the two FIFOs (in and out)
signal res_array : array_type := (others => (others => '0'));

begin

-- Mult_wfifos instantation

mult_wfifos_0 : entity work.mult_wfifos
                generic map (N_bits => N_bits,
                             Log2_elements => Log2_elements)
                port map (clk_wr => clk_wr,
                          clk_mult => clk_mult,
                          clk_rd => clk_rd,
                          rst => rst,
                          din => din,
                          dout => dout,
                          wr => wr,
                          rd => rd,
                          full => open,
                          empty => empty);

--Generate clocks

clk_wr <= not clk_wr after Twr/2;
clk_mult <= not clk_mult after Tmult/2;
clk_rd <= not clk_rd after Trd/2;

tests : process

    procedure write_word(constant x,y: integer;
                         constant enable_res : boolean; -- Enable res to operate saving values ​​in res_array
                         constant i : integer) is
    begin
        if enable_res then
            wait until rising_edge(clk_wr);
            din <= std_logic_vector(to_unsigned(x, 4)) & std_logic_vector(to_unsigned(y, 4)); -- 15 x 0 = 1111 x 0000
            wait for Twr*2;
            res_array(i) <= din;
            wr <= '1';
            info("Data to write is: " & to_string(din(7 downto 4)) & " x " & to_string(din(3 downto 0)));
            wait for Twr;
            wr <= '0';
            wait for 5*Tmult;
        else
            wait until rising_edge(clk_wr);
            din <= std_logic_vector(to_unsigned(x, 4)) & std_logic_vector(to_unsigned(y, 4));
            wait for Twr*2;
            wr <= '1';
            info("Data to write is: " & to_string(din(7 downto 4)) & " x " & to_string(din(3 downto 0)));
            wait for Twr;
            wr <= '0';
            wait for 5*Tmult;
        end if;

    end procedure;

    procedure read_word(constant enable_res : boolean; -- Enable res to operate saving values ​​in res_array
                        constant i : integer) is
    begin
        if enable_res then
            wait until rising_edge(clk_rd);
            rd <= '1';
            wait for Trd;
            rd <= '0';
            wait for Tmult*5;
            info("Expected output is: " & to_string(std_logic_vector(unsigned(res_array(i)(7 downto 4)) * unsigned(res_array(i)(3 downto 0)))));
            info ("Mult_wfifos output is: " & to_string(dout));

            check_equal(dout,std_logic_vector(unsigned(res_array(i)(7 downto 4)) * unsigned(res_array(i)(3 downto 0))),
            "This is a failure!");
        else
            wait until rising_edge(clk_rd);
            rd <= '1';
            wait for Trd;
            rd <= '0';
            wait for 5*Tmult;
            info ("Expected output is: " & to_string(std_logic_vector(unsigned(din(7 downto 4)) * unsigned(din(3 downto 0)))));
            info ("Mult_wfifos output is: " & to_string(dout));

            check_equal(dout,std_logic_vector(unsigned(din(7 downto 4)) * unsigned(din(3 downto 0))),
            "This is a failure!");
        end if;
    end procedure;

    begin
    test_runner_setup(runner, runner_cfg);
    info ("Simulation start");
    -- Initialize
    rst <= '1';
    wr <= '0';
    rd <= '0';
    din <= (others=>'0');

    wait for Twr*5;

    rst <= '0';

    wait for Twr*5;

    if run("Write one read one") then
        info(">>> This test writes one data and then reads it <<<");
        info("> Input data:");   write_word(5,5,false,0); -- 5 x 5 = 0101 x 0101
        info("Read output"); read_word(false,0);
        wait for 5*Tmult;

    elsif run("Write all and try another") then
        info(">>> This test fills both fifos (4 elements per fifo) and then tries to write another data <<<");
        info("> First input");   write_word(15,0,false,0);  -- 15 x 0 = 1111 x 0000
        info("> Second input");  write_word(15,1,false,0);  -- 15 x 1 = 1111 x 0001
        info("> Third input");   write_word(15,3,false,0);  -- 15 x 3 = 1111 x 0011
        info("> Fourth input");  write_word(15,7,false,0);  -- 15 x 7 = 1111 x 0111
        warning("Now output FIFO is full and it's holding in the input FIFO");
        info("> Fifth input");   write_word(15,15,false,0); -- 15 x 15 = 1111 x 1111
        info("> Sixth input");   write_word(2,2,false,0);   -- 2 x 2 = 0010 x 0010
        info("> Seventh input"); write_word(4,4,false,0);   -- 4 x 4 = 0100 x 0100
        info("> Eighth input");  write_word(8,8,false,0);   -- 8 x 8 = 1000 x 1000
        warning("Now the two FIFOs are full and the following data is going to lost!");
        info("> Ninth input");   write_word(15,7,false,0);  -- 10 x 10 = 1010 x 1010
        warning("Open gui to see FIFO input array and check the lost data");
        wait for 5*Tmult;

    elsif run("Write all read all") then
        info(">>> This test writes all fifo (4 elements per fifo) and then reads all <<<");
        info("> First input");   write_word(15,0,true,0);  -- 15 x 0 = 1111 x 0000
        info("> Second input");  write_word(15,1,true,1);  -- 15 x 1 = 1111 x 0001
        info("> Third input");   write_word(15,3,true,2);  -- 15 x 3 = 1111 x 0011
        info("> Fourth input");  write_word(15,7,true,3);  -- 15 x 7 = 1111 x 0111
        warning("Now output FIFO is full and it's holding in the input FIFO");
        info("> Fifth input");   write_word(15,15,true,4); -- 15 x 15 = 1111 x 1111
        info("> Sixth input");   write_word(2,2,true,5);   -- 2 x 2 = 0010 x 0010
        info("> Seventh input"); write_word(4,4,true,6);   -- 4 x 4 = 0100 x 0100
        info("> Eighth input");  write_word(8,8,true,7);   -- 8 x 8 = 1000 x 1000
        info("Now it's going to read");
        info("Read first data"); read_word(true,0);
        info("Read second data"); read_word(true,1);
        info("Read third data"); read_word(true,2);
        info("Read fourth data"); read_word(true,3);
        info("Read fifth data"); read_word(true,4);
        info("Read sixth data"); read_word(true,5);
        info("Read seventh data"); read_word(true,6);
        info("Read eighth data"); read_word(true,7);
        wait for Tmult*5;

    elsif run("Read twice") then
        info(">>> This test writes one data, then reads it and then tries to read again <<<");
        info("> Input data:");   write_word(5,5,false,0); -- 5 x 5 = 0101 x 0101
        info("Read output"); read_word(false,0);
        info("Read output again"); read_word(false,0);
        wait for 5*Tmult;

    end if;
    info("Simulation end"); 
    test_runner_cleanup(runner); -- Simulation ends here
    end process tests;
end behav;
