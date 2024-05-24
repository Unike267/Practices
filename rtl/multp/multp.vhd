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

entity multp_op is
  generic (
    g_data_width : natural
  );
  port (
    DIN : in std_logic_vector (g_data_width-1 downto 0);
    DOUT : out std_logic_vector(g_data_width-1 downto 0)
  );
end multp_op;

architecture arch of multp_op is
begin

  DOUT <= std_logic_vector(
    signed(DIN(g_data_width-1 downto g_data_width/2))
    *
    signed(DIN((g_data_width/2)-1 downto 0))
  );

end arch;


library ieee;
context ieee.ieee_std_context;

entity multp is
  generic (
    g_data_width : natural
  );
  port (
    CLK : in std_logic;
    RST : in std_logic;
    IN_VALID : in std_logic;
    IN_READY : out std_logic;
    DIN : in std_logic_vector (g_data_width-1 downto 0);
    OUT_VALID : out std_logic;
    OUT_READY : in std_logic;
    DOUT : out std_logic_vector(g_data_width-1 downto 0)
  );
end multp;

architecture registered of multp is

  signal ready: std_logic;
  signal valid : std_logic;
  signal transfer_in : std_logic;
  signal transfer_out : std_logic;
  signal result : std_logic_vector(g_data_width-1 downto 0);

begin

  transfer_in <= IN_VALID and ready;
  transfer_out <= valid and OUT_READY;
  ready <= not rst and ((not valid) or transfer_out);

  IN_READY <= ready;
  OUT_VALID <= valid;

  i_multp_op : entity work.multp_op
    generic map (
      g_data_width => g_data_width
    )
    port map (
      DIN  => DIN,
      DOUT => result
    );

  process (CLK) begin
    if rising_edge(CLK) then
      if RST then
        DOUT <= (others=>'0');
      elsif transfer_in then
        DOUT <= result;
      end if;
    end if;
  end process;

  process (CLK) begin
    if rising_edge(CLK) then
      if RST then
        valid <= '0';
      else
        if transfer_in then
          valid <= '1';
        elsif transfer_out then
          valid <= '0';
        end if;
      end if;
    end if;
  end process;

end registered;

architecture combinatorial of multp is

begin

  IN_READY <= OUT_READY;
  OUT_VALID <= IN_VALID;

  i_multp_op : entity work.multp_op
    generic map (
      g_data_width => g_data_width
    )
    port map (
      DIN  => DIN,
      DOUT => DOUT
    );

end combinatorial;
