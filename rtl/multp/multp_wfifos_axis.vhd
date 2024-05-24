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

entity multp_wfifos_axis is
  generic (
    g_data_width : natural := 32;
    g_fifo_depth : natural := 0 -- ceiling of the log base 2 of the desired FIFO length
  );
  port (
    CLK_MULT     : in std_logic;
    s_axis_clk   : in  std_logic;
    s_axis_rstn  : in  std_logic;
    s_axis_rdy   : out std_logic;
    s_axis_data  : in  std_logic_vector(g_data_width-1 downto 0);
    s_axis_valid : in  std_logic;
    m_axis_clk   : in  std_logic;
    m_axis_rstn  : in  std_logic;
    m_axis_valid : out std_logic;
    m_axis_data  : out std_logic_vector(g_data_width-1 downto 0);
    m_axis_rdy   : in  std_logic
  );
end multp_wfifos_axis;

architecture rtl of multp_wfifos_axis is

signal read, empty, full, valid : std_logic;

begin

  s_axis_rdy <= not full;

  i_multp_wfifos : entity work.multp_wfifos
    generic map (
      g_data_width => g_data_width,
      g_fifo_depth => g_fifo_depth
    )
    port map (
      CLK_IN   => s_axis_clk,
      CLK_MULT => clk_mult,
      CLK_OUT  => m_axis_clk,
      RST      => s_axis_rstn nand m_axis_rstn,
      DIN      => s_axis_data,
      DOUT     => m_axis_data,
      WRITE    => s_axis_valid and not full,
      READ     => read,
      FULL     => full,
      EMPTY    => empty
    );

  read <= (valid nand not m_axis_rdy) and not empty;

  process (m_axis_clk) begin
    if rising_edge(m_axis_clk) then
      if (not m_axis_rstn) or ((valid and empty) and m_axis_rdy) then
        valid <= '0';
      elsif read then
        valid <= '1';
      end if;
    end if;
  end process;

  m_axis_valid <= valid;

end rtl;
