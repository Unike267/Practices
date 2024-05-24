library ieee;
context ieee.ieee_std_context;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity mult_wfifos_wishbone_vcs is
  generic (
    bus_handle : bus_master_t;
    strobe_high_probability : real range 0.0 to 1.0 := 1.0;
    N_bits : natural := 32;
    Log2_elements : natural := 4;
    test_items : natural := 4;
    logger : logger_t
  );
  port (
    clk, rstn: in std_logic;
    ack_o: out std_logic
  );
end entity;

architecture arch of mult_wfifos_wishbone_vcs is

  signal m_we, m_stb, m_ack, m_cyc , m_stall: std_logic;
  signal m_din, m_dout : std_logic_vector(data_length(bus_handle)-1 downto 0);
  signal m_adr : std_logic_vector(address_length(bus_handle)-1 downto 0);
  signal m_sel : std_logic_vector((data_length(bus_handle)/8)-1 downto 0);

begin

  -- Take out ack signal

  ack_o <= m_ack;

  -- Wishbone verification component instantiation

  vunit_wishbone_master: entity vunit_lib.wishbone_master
  generic map (
    bus_handle => bus_handle,
    strobe_high_probability => strobe_high_probability
  )
  port map (
    clk   => clk,
    adr   => m_adr,
    dat_i => m_din,
    dat_o => m_dout,
    sel   => m_sel,
    cyc   => m_cyc,
    stb   => m_stb,
    we    => m_we,
    stall => m_stall,
    ack   => m_ack
  );

--

  -- Unit under test: Mult_wfifos wishbone

uut: entity work.mult_wfifos_wishbone
            generic map(  
                        N_bits => N_bits,
                        Log2_elements => Log2_elements
                        )
            port map(
                         rst_i => rstn,
                         clk_i => clk,
                         adr_i => m_adr,
                         dat_i => m_dout,
                         dat_o => m_din,
                         we_i => m_we,
                         sel_i => m_sel,
                         stb_i => m_stb,
                         ack_o => m_ack,
                         cyc_i => m_cyc,
                         err_o => open,
                         stall_o => m_stall
                       );

-- To extract time information through the INFO function, for latency measurements

  send_trigger: process
  begin

    for x in 0 to test_items-1 loop
      wait until rising_edge(clk) and m_ack = '1' and m_cyc = '1' and m_we = '1';
      info(logger, "Data (" & to_string(m_dout(31 downto 16)) & "x" & to_string(m_dout(15 downto 0))  & ") " & to_string(x+1) & "/" & to_string(test_items) & " sent!");
    end loop;
  end process;

  received_trigger: process
  begin

    for x in 0 to test_items-1 loop
      wait until rising_edge(clk) and m_ack = '1' and m_cyc = '1' and m_we = '0';
      info(logger, "Data (" & to_string(m_din) & ") " & to_string(x+1) & "/" & to_string(test_items) & " received!");
    end loop;
  end process;

end architecture;

