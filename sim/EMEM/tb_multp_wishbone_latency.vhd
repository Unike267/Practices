library ieee;
context ieee.ieee_std_context;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity tb_multp_wishbone_latency is
  generic (
    runner_cfg : string
  );
end entity;

architecture tb of tb_multp_wishbone_latency is

  -- Simulation constants

  constant clk_period : time    := 10 ns;
  constant data_width : natural := 32;
  constant adr_width : natural := 32;

  -- Wishbone Verification Components constant

  constant bus_handle : bus_master_t := new_bus(
    data_length => data_width,
    address_length => adr_width
  );

  -- Logging

  constant logger : logger_t := get_logger("tb_multp_wishbone_latency");
  constant file_handler : log_handler_t := new_log_handler(
    output_path(runner_cfg) & "log.csv",
    format => csv,
    use_color => false
  );

  constant strobe_high_probability : real range 0.0 to 1.0 := 1.0;

  -- tb signals and variables

  signal clk, rst, rstn, ack: std_logic := '0';
  signal start, done, checked : boolean := false;

  constant test_items : natural := 4;
  type test_t is array (0 to test_items-1, 0 to 2) of integer;
  constant test_data : test_t := (
    (1, 1, 1),
    (2, 2, 4),
    (4, 4, 16),
    (8, 8, 64)
  );

begin

  clk <= not clk after clk_period/2;
  rstn <= not rst;

  main: process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test") then
        set_log_handlers(logger, (display_handler, file_handler));
        show_all(logger, file_handler);
        show_all(logger, display_handler);

        rst <= '1';
        wait for 15*clk_period;
        rst <= '0';
        info(logger, "Init test");
        wait until rising_edge(clk);
        start <= true;
        wait until rising_edge(clk);
        start <= false;
        wait until (done and checked and rising_edge(clk));
        info(logger, "Test done");
      end if;
    end loop;
    test_runner_cleanup(runner);
    wait;
  end process;

  stimuli: process
    variable word : std_logic_vector(data_width-1 downto 0);
  begin
    done <= false;
    wait until start and rising_edge(clk);

    for x in 0 to test_items-1 loop
      word(data_width-1 downto data_width/2) := std_logic_vector(to_signed(test_data(x, 0), data_width/2));
      word(data_width/2-1 downto 0) := std_logic_vector(to_signed(test_data(x, 1), data_width/2));
      write_bus(net, bus_handle, x"90000000", word); -- Write to 0x90000000 address
      wait_until_idle(net, bus_handle);
    end loop;

    wait until rising_edge(clk);
    done <= true;
    wait;
  end process;

  check: process
    variable tmp : std_logic_vector(31 downto 0);
  begin
    checked <= false;
    wait until start and rising_edge(clk);

    for x in 0 to test_items-1 loop
      wait_until_idle(net, bus_handle);
      read_bus(net, bus_handle, x"90000000", tmp); -- Read from 0x90000000 address
      check_equal(to_signed(test_data(x,2), data_width),signed(tmp),"This is a failure!");
    end loop;

    wait until rising_edge(clk);
    checked <= true;
    wait;
  end process;

  uut_vc: entity work.multp_wishbone_vcs
  generic map (
    bus_handle => bus_handle,
    strobe_high_probability => strobe_high_probability,
    N_bits => data_width,
    test_items => test_items,
    logger => logger
  )
  port map (
    clk  => clk,
    rstn => rstn,
    ack_o => ack
  );

end architecture;

