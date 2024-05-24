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

entity multp_wfifos is
  generic (
    g_data_width : natural := 32;
    g_fifo_depth : natural := 0 -- ceiling of the log base 2 of the desired FIFO length
  );
  port (
     CLK_IN   : in std_logic;
     CLK_MULT : in std_logic;
     CLK_OUT  : in std_logic;
     RST      : in std_logic;
     DIN      : in std_logic_vector (g_data_width-1 downto 0);
     DOUT     : out std_logic_vector (g_data_width-1 downto 0);
     WRITE    : in std_logic;
     READ     : in std_logic;
     FULL     : out std_logic;
     EMPTY    : out std_logic
);
end multp_wfifos;

architecture rtl of multp_wfifos is

  signal data_in    : std_logic_vector(g_data_width-1 downto 0);
  signal data_out   : std_logic_vector(g_data_width-1 downto 0);
  signal i_read     : std_logic;
  signal i_write    : std_logic;
  signal i_empty    : std_logic;
  signal i_full     : std_logic;
  signal in_valid   : std_logic;
  signal in_ready   : std_logic;
  signal out_valid  : std_logic;
  signal out_ready  : std_logic;

begin

  fifo_in : entity work.fifo
    generic map (
      N_bits => g_data_width,
      Log2_elements => g_fifo_depth)
    port map (
      clk_wr => CLK_IN,
      clk_rd => CLK_MULT,
      rst => RST,
      fifo_in => DIN,
      fifo_out => data_in,
      wr => WRITE,
      rd => i_read,
      full_o => FULL,
      empty_o => i_empty
    );

  i_read <= in_ready and not i_empty;

  process (CLK_MULT) begin
    if rising_edge(CLK_MULT) then
      if RST then
        in_valid <= '0';
      else
        in_valid <= i_read;
      end if;
    end if;
  end process;

  multp : entity work.multp(combinatorial)
    generic map (
      g_data_width => g_data_width
    )
    port map (
      CLK => CLK_MULT,
      RST => RST,
      IN_VALID => in_valid,
      IN_READY => in_ready,
      DIN => data_in,
      OUT_VALID => out_valid,
      OUT_READY => out_ready,
      DOUT => data_out
    );

  i_write <= out_valid and out_ready;
  out_ready <= not i_full;

  fifo_out : entity work.fifo
    generic map (
      N_bits => g_data_width,
      Log2_elements => g_fifo_depth
    )
    port map (
      clk_wr => CLK_MULT,
      clk_rd => CLK_OUT,
      rst => RST,
      fifo_in => data_out,
      fifo_out => DOUT,
      wr => i_write,
      rd => READ,
      full_o => i_full,
      empty_o => EMPTY
    );

end rtl;
