-- Authors:
--   Unai Martinez-Corral & Unai Sainz-Estebanez
--     <unai.martinezcorral@ehu.eus>
--     <usainz003@ikasle.ehu.eus>
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- SPDX-License-Identifier: Apache-2.0

library ieee;
context ieee.ieee_std_context;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity tb_multp_axis_latency is
  generic (
    runner_cfg : string
  );
end entity;

architecture tb of tb_multp_axis_latency is

  -- Simulation constants

  constant clk_period : time    := 10 ns;
  constant data_width : natural := 32;

  -- AXI4Stream Verification Components

  constant master_axi_stream : axi_stream_master_t := new_axi_stream_master(
    data_length => data_width,
    stall_config => new_stall_config(0.0, 1, 10)
  );
  constant slave_axi_stream  : axi_stream_slave_t  := new_axi_stream_slave(
    data_length => data_width,
    stall_config => new_stall_config(0.0, 1, 10)
  );

  -- Logging

  constant logger : logger_t := get_logger("tb_multp_axis_latency");
  constant file_handler : log_handler_t := new_log_handler(
    output_path(runner_cfg) & "log.csv",
    format => csv,
    use_color => false
  );

  -- tb signals and variables

  signal clk, rst, rstn : std_logic := '0';
  signal start, done : boolean := false;

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
        wait until (done and rising_edge(clk));
        info(logger, "Test done");
      end if;
    end loop;
    test_runner_cleanup(runner);
    wait;
  end process;

  stimuli: process
    variable word : std_logic_vector(data_width-1 downto 0);
    variable o : std_logic_vector(31 downto 0);
    variable last : std_logic:='0';
  begin
    done <= false;
    wait until start and rising_edge(clk);

    for x in 0 to test_items-1 loop
      word(data_width-1 downto data_width/2) := std_logic_vector(to_signed(test_data(x, 0), data_width/2));
      word(data_width/2-1 downto 0) := std_logic_vector(to_signed(test_data(x, 1), data_width/2));
      push_axi_stream(net, master_axi_stream, word);
      pop_axi_stream(net, slave_axi_stream, tdata => o, tlast => last);
      check_equal(signed(o),to_signed(test_data(x,2), data_width),"This is a failure!");
    end loop;

    wait until rising_edge(clk);
    done <= true;
    wait;
  end process;

--

  uut_vc: entity work.multp_axis_vcs
  generic map (
    m_axis => master_axi_stream,
    s_axis => slave_axi_stream,
    g_data_width => data_width,
    test_items => test_items,
    logger => logger
  )
  port map (
    clk  => clk,
    rstn => rstn
  );

end architecture;
