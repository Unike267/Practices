-- #################################################################################################
-- # << NEORV32 - Custom Functions Subsystem (CFS) >>                                              #
-- # ********************************************************************************************* #
-- # Intended for tightly-coupled, application-specific custom co-processors. This module provides #
-- # 64x 32-bit memory-mapped interface registers, one interrupt request signal and custom IO      #
-- # conduits for processor-external or chip-external interface.                                   #
-- #                                                                                               #
-- # NOTE: This is just an example/illustration template. Modify/replace this file to implement    #
-- #       your own custom design logic.                                                           #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2023, Stephan Nolting. All rights reserved.                                     #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_cfs is
  generic (
    CFS_CONFIG   : std_ulogic_vector(31 downto 0); -- custom CFS configuration generic
    CFS_IN_SIZE  : natural; -- size of CFS input conduit in bits
    CFS_OUT_SIZE : natural  -- size of CFS output conduit in bits
  );
  port (
    clk_i       : in  std_ulogic; -- global clock line
    rstn_i      : in  std_ulogic; -- global reset line, low-active, use as async
    bus_req_i   : in  bus_req_t;  -- bus request
    bus_rsp_o   : out bus_rsp_t;  -- bus response
    clkgen_en_o : out std_ulogic; -- enable clock generator
    clkgen_i    : in  std_ulogic_vector(07 downto 0); -- "clock" inputs
    irq_o       : out std_ulogic; -- interrupt request
    cfs_in_i    : in  std_ulogic_vector(CFS_IN_SIZE-1 downto 0); -- custom inputs
    cfs_out_o   : out std_ulogic_vector(CFS_OUT_SIZE-1 downto 0) -- custom outputs
  );
end neorv32_cfs;

architecture neorv32_cfs_rtl of neorv32_cfs is

  -- default CFS interface registers --
  signal cfs_acceler_data : std_ulogic_vector(31 downto 0);
  signal cfs_acceler_control : std_ulogic_vector(31 downto 0);
  signal cfs_acceler_res : std_ulogic_vector(31 downto 0);

begin

  -- CFS Generics ---------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- In it's default version the CFS provides three configuration generics:
  -- > CFS_IN_SIZE  - configures the size (in bits) of the CFS input conduit cfs_in_i
  -- > CFS_OUT_SIZE - configures the size (in bits) of the CFS output conduit cfs_out_o
  -- > CFS_CONFIG   - is a blank 32-bit generic. It is intended as a "generic conduit" to propagate
  --                  custom configuration flags from the top entity down to this module.


  -- CFS IOs --------------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- By default, the CFS provides two IO signals (cfs_in_i and cfs_out_o) that are available at the processor's top entity.
  -- These are intended as "conduits" to propagate custom signals from this module and the processor top entity.

  -- Reset System ---------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- The CFS can be reset using the global rstn_i signal. This signal should be used as asynchronous reset and is active-low.
  -- Note that rstn_i can be asserted by a processor-external reset, the on-chip debugger and also by the watchdog.
  --
  -- Most default peripheral devices of the NEORV32 do NOT use a dedicated hardware reset at all. Instead, these units are
  -- reset by writing ZERO to a specific "control register" located right at the beginning of the device's address space
  -- (so this register is cleared at first). The crt0 start-up code writes ZERO to every single address in the processor's
  -- IO space - including the CFS. Make sure that this initial clearing does not cause any unintended CFS actions.


  -- Clock System ---------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- The processor top unit implements a clock generator providing 8 "derived clocks".
  -- Actually, these signals should not be used as direct clock signals, but as *clock enable* signals.
  -- clkgen_i is always synchronous to the main system clock (clk_i).
  --
  -- The following clock dividers are available:
  -- > clkgen_i(clk_div2_c)    -> MAIN_CLK/2
  -- > clkgen_i(clk_div4_c)    -> MAIN_CLK/4
  -- > clkgen_i(clk_div8_c)    -> MAIN_CLK/8
  -- > clkgen_i(clk_div64_c)   -> MAIN_CLK/64
  -- > clkgen_i(clk_div128_c)  -> MAIN_CLK/128
  -- > clkgen_i(clk_div1024_c) -> MAIN_CLK/1024
  -- > clkgen_i(clk_div2048_c) -> MAIN_CLK/2048
  -- > clkgen_i(clk_div4096_c) -> MAIN_CLK/4096
  --
  -- For instance, if you want to drive a clock process at MAIN_CLK/8 clock speed you can use the following construct:
  --
  --   if (rstn_i = '0') then -- async and low-active reset (if required at all)
  --   ...
  --   elsif rising_edge(clk_i) then -- always use the main clock for all clock processes
  --     if (clkgen_i(clk_div8_c) = '1') then -- the div8 "clock" is actually a clock enable
  --       ...
  --     end if;
  --   end if;
  --
  -- The clkgen_i input clocks are available when at least one IO/peripheral device (for example UART0) requires the clocks
  -- generated by the clock generator. The CFS can enable the clock generator by itself by setting the clkgen_en_o signal high.
  -- The CFS cannot ensure to deactivate the clock generator by setting the clkgen_en_o signal low as other peripherals might
  -- still keep the generator activated. Make sure to deactivate the CFS's clkgen_en_o if no clocks are required in here to
  -- reduce dynamic power consumption.

  clkgen_en_o <= '0'; -- not used for this minimal example


  -- Interrupt ------------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- The CFS features a single interrupt signal, which is connected to the CPU's "fast interrupt" channel 1 (FIRQ1).
  -- The interrupt is triggered by a one-cycle high-level. After triggering, the interrupt appears as "pending" in the CPU's
  -- mip CSR ready to trigger execution of the according interrupt handler. It is the task of the application to programmer
  -- to enable/clear the CFS interrupt using the CPU's mie and mip registers when required.

  irq_o <= '0'; -- not used for this minimal example


  -- Read/Write Access ----------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- Here we are reading/writing from/to the interface registers of the module and generate the CPU access handshake (bus response).
  --
  -- The CFS provides up to 64 memory-mapped 32-bit interface registers. For instance, these could be used to provide a
  -- <control register> for global control of the unit, a <data register> for reading/writing from/to a data FIFO, a
  -- <command register> for issuing commands and a <status register> for status information.
  --
  -- Following the interface protocol, each read or write access has to be acknowledged in the following cycle using the ack_o
  -- signal (or even later if the module needs additional time). If no ACK is generated at all, the bus access will time out
  -- and cause a bus access fault exception. The current CPU privilege level is available via the 'priv_i' signal (0 = user mode,
  -- 1 = machine mode), which can be used to constrain access to certain registers or features to privileged software only.
  --
  -- This module also provides an optional ERROR signal to indicate a faulty access operation (for example when accessing an
  -- unused, read-only or "locked" CFS register address). This signal may only be set when the module is actually accessed
  -- and is set INSTEAD of the ACK signal. Setting the ERR signal will raise a bus access exception with a "Device Error" qualifier
  -- that can be handled by the application software. Note that the current privilege level should not be exposed to software to
  -- maintain full virtualization. Hence, CFS-based "privilege escalation" should trigger a bus access exception (e.g. by setting 'err_o').

  bus_rsp_o.err <= '0'; -- Tie to zero if not explicitly used.


  -- Host access example: Read and write access to the interface registers + bus transfer acknowledge. This example only
  -- implements four physical r/w register (the four lowest CFS registers). The remaining addresses of the CFS are not associated
  -- with any physical registers - any access to those is simply ignored but still acknowledged. Only full-word write accesses are
  -- supported (and acknowledged) by this example. Sub-word write access will not alter any CFS register state and will cause
  -- a "bus store access" exception (with a "Device Timeout" qualifier as not ACK is generated in that case).

bus_access: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      cfs_acceler_data <= (others => '0');
      cfs_acceler_control <= (others => '0');
      --
      bus_rsp_o.ack  <= '0';
      bus_rsp_o.err  <= '0';
      bus_rsp_o.data <= (others => '0');
    elsif rising_edge(clk_i) then -- synchronous interface for read and write accesses
      -- transfer/access acknowledge --
      bus_rsp_o.ack <= bus_req_i.stb;

      -- tie to zero if not explicitly used --
      bus_rsp_o.err <= '0';

      -- defaults --
      bus_rsp_o.data <= (others => '0'); -- the output HAS TO BE ZERO if there is no actual (read) access

      -- bus access --
      if (bus_req_i.stb = '1') then -- valid access cycle, STB is high for one cycle

        -- write access --
        if (bus_req_i.rw = '1') then
          if (bus_req_i.addr(7 downto 2) = "000000") then -- address size is fixed!
            cfs_acceler_data <= bus_req_i.data; -- write to CFS memory-mapped register 0; Acceler inputs
          end if;
          if (bus_req_i.addr(7 downto 2) = "000001") then
            cfs_acceler_control <= bus_req_i.data; -- write to CFS memory-mapped register 1; Acceler control
          end if;

        -- read access --
        else
          case bus_req_i.addr(7 downto 2) is -- address size is fixed!
            when "000000" => bus_rsp_o.data <= cfs_acceler_res; -- read from CFS memory-mapped register 0; Acceler outputs
            when others   => bus_rsp_o.data <= (others => '0');
          end case;
        end if;
      end if;
    end if;
  end process bus_access;

-- cfs_out_o 34 bits.
-- cfs_acceler_control(1) => read_acceler; cfs_acceler_control(0) => write_acceler

 cfs_out_o <= cfs_acceler_control(1) & cfs_acceler_control(0) & cfs_acceler_data; 

-- cfs_in_i 32 bits. Acceler output (16 bits x 16 bits).

 cfs_acceler_res <= cfs_in_i;

end neorv32_cfs_rtl;
