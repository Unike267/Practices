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

entity mult_wfifos_axis_vcs is
  generic (
    m_axis : axi_stream_master_t;
    s_axis : axi_stream_slave_t;
    N_bits : natural := 32;
    Log2_elements : natural := 4;
    test_items : natural := 4;
    logger : logger_t
  );
  port (
    clk, rstn: in std_logic
  );
end entity;

architecture arch of mult_wfifos_axis_vcs is

  signal m_valid, m_ready, s_valid, s_ready : std_logic;
  signal m_data, s_data : std_logic_vector(data_length(m_axis)-1 downto 0);

begin

  vunit_axism: entity vunit_lib.axi_stream_master
  generic map (
    master => m_axis
  )
  port map (
    aclk   => clk,
    tvalid => m_valid,
    tready => m_ready,
    tdata  => m_data,
    tlast  => open
  );

  vunit_axiss: entity vunit_lib.axi_stream_slave
  generic map (
    slave => s_axis
  )
  port map (
    aclk   => clk,
    tvalid => s_valid,
    tready => s_ready,
    tdata  => s_data,
    tlast  => open
  );

--

  uut: entity work.mult_wfifos_axis
  generic map (
    N_bits => N_bits,
    Log2_elements => Log2_elements
  )
  port map (
    clk_mult => clk,
    s_axis_clk   => clk,
    s_axis_rstn  => rstn,
    s_axis_rdy   => m_ready,
    s_axis_data  => m_data,
    s_axis_valid => m_valid,
    m_axis_clk   => clk,
    m_axis_rstn  => rstn,
    m_axis_valid => s_valid,
    m_axis_data  => s_data,
    m_axis_rdy   => s_ready
  );

-- To extract time information through the INFO function, for latency measurements

  send_trigger: process
  begin

    for x in 0 to test_items-1 loop
      wait until rising_edge(clk) and m_valid = '1' and m_ready = '1';
      info(logger, "Data (" & to_string(m_data(31 downto 16)) & "x" & to_string(m_data(15 downto 0))  & ") " & to_string(x+1) & "/" & to_string(test_items) & " sent!");
    end loop;
  end process;

  received_trigger: process
  begin

    for x in 0 to test_items-1 loop
      wait until rising_edge(clk) and s_valid = '1' and s_ready = '1';
      info(logger, "Data (" & to_string(s_data) & ") " & to_string(x+1) & "/" & to_string(test_items) & " received!");
    end loop;
  end process;

end architecture;
