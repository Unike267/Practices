library ieee;
context ieee.ieee_std_context;

library neorv32;
use neorv32.neorv32_package.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_complex_mult_wfifos_cfs is
  generic (
    runner_cfg : string
  );
end entity;

architecture tb of tb_complex_mult_wfifos_cfs is

signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal rstn : std_logic := '0';
signal gpio_a : std_ulogic_vector(7 downto 0);
signal uart0_txd : std_logic;

constant baud0_rate_c            : natural := 19200;
constant CLOCK_FREQUENCY         : natural := 100000000;

constant uart0_baud_val_c : real := real(CLOCK_FREQUENCY) / real(baud0_rate_c);

constant clk_period : time := 10 ns;

signal csr_we : std_logic;
signal csr_valid : std_logic;
signal csr_addr : std_ulogic_vector(11 downto 0);
signal csr_wdata : std_ulogic_vector(31 downto 0);
signal csr_rdata_o : std_ulogic_vector(31 downto 0);


-- Logging

constant logger : logger_t := get_logger("tb_complex_mult_wfifos_cfs");
constant file_handler : log_handler_t := new_log_handler(
  output_path(runner_cfg) & "log.csv",
  format => csv,
  use_color => false
);

-- Test items (make sure that they are equal to the items defined in the software)

constant test_items : natural := 4;
type test_t is array (0 to test_items-1, 0 to 2) of integer;
constant test_data : test_t := (
  (1, 1, 1),
  (2, 2, 4),
  (4, 4, 16),
  (8, 8, 64)
);

signal start, done: boolean := false;

begin

neorv32_mult_wfifos_cfs_0 : entity work.neorv32_mult_wfifos_cfs
                                                generic map(
                                                            CLOCK_FREQUENCY => CLOCK_FREQUENCY,
                                                            MEM_INT_IMEM_SIZE => 16384,
                                                            MEM_INT_DMEM_SIZE => 8192
                                                           )
                                                port map (
                                                            clk_i => clk,
                                                            rstn_i => rstn,
                                                            gpio_o => gpio_a,
                                                            uart0_txd_o => uart0_txd,
                                                            uart0_rxd_i => uart0_txd
                                                          );
  -- UART Simulation Receiver ---------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  uart0_checker: entity work.uart_rx_simple
  generic map (
    name => "uart0",
    uart_baud_val_c => uart0_baud_val_c
  )
  port map (
    clk => clk,
    uart_txd => uart0_txd
  );

clk <= not clk after clk_period/2;
rstn <= not rst;

 -- Capture CSR signals through external names
  csr_we <= << signal .tb_complex_mult_wfifos_cfs.neorv32_mult_wfifos_cfs_0.neorv32_top_inst.core_complex.neorv32_cpu_inst.neorv32_cpu_control_inst.xcsr_we_o : std_logic >>;
  csr_addr <= << signal .tb_complex_mult_wfifos_cfs.neorv32_mult_wfifos_cfs_0.neorv32_top_inst.core_complex.neorv32_cpu_inst.neorv32_cpu_control_inst.xcsr_addr_o : std_ulogic_vector(11 downto 0) >>;
  csr_wdata <= << signal .tb_complex_mult_wfifos_cfs.neorv32_mult_wfifos_cfs_0.neorv32_top_inst.core_complex.neorv32_cpu_inst.neorv32_cpu_control_inst.xcsr_wdata_o : std_ulogic_vector(31 downto 0) >>;
  csr_rdata_o <= << signal .tb_complex_mult_wfifos_cfs.neorv32_mult_wfifos_cfs_0.neorv32_top_inst.core_complex.neorv32_cpu_inst.neorv32_cpu_control_inst.csr_rdata_o : std_ulogic_vector(31 downto 0) >>;
  csr_valid <= << signal .tb_complex_mult_wfifos_cfs.neorv32_mult_wfifos_cfs_0.neorv32_top_inst.core_complex.neorv32_cpu_inst.neorv32_cpu_control_inst.csr_reg_valid : std_logic >>;

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
        wait until (done and rising_edge(clk));
        info(logger, "Test done");
      end if;
    end loop;
    test_runner_cleanup(runner);
    wait;
  end process;

  mycycle_capture: process
  begin
    done <= false;
    wait until start and rising_edge(clk);
    for x in 0 to test_items-1 loop
      wait until rising_edge(clk) and csr_we = '0' and csr_valid = '1' and csr_addr = x"B00" and csr_rdata_o /= x"00000000"; -- CSR MYCYCLE ADDR IS 0xB00
      info(logger, "Data " & to_string(x+1) & "/" & to_string(test_items) & " latency is " & to_string(to_integer(unsigned(csr_rdata_o))-1) & " cycles"); -- Remove one cycle, see gh:stnolting/neorv32/issues/897
      wait until rising_edge(clk);
    end loop;
    
    wait until rising_edge(clk);
    done <= true;
    wait;
  end process;

end architecture;
