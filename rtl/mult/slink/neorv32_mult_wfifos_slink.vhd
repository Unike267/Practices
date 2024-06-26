-- #################################################################################################
-- # << NEORV32 - Test Setup using the default UART-Bootloader to upload and run executables >>    #
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
-- # The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32                           #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_mult_wfifos_slink is
  generic (
    -- adapt these for your setup --
    CLOCK_FREQUENCY   : natural := 100000000; -- clock frequency of clk_i in Hz
    MEM_INT_IMEM_SIZE : natural := 6*1024;   -- size of processor-internal instruction memory in bytes
    MEM_INT_DMEM_SIZE : natural := 8*1024     -- size of processor-internal data memory in bytes
  );
  port (
    -- Global control --
    clk_i       : in  std_ulogic; -- global clock, rising edge
    rstn_i      : in  std_ulogic; -- global reset, low-active, async
    -- GPIO --
    gpio_o      : out std_ulogic_vector(7 downto 0); -- parallel output
    -- UART0 --
    uart0_txd_o : out std_ulogic; -- UART0 send data
    uart0_rxd_i : in  std_ulogic  -- UART0 receive data
  );
end entity;

architecture neorv32_mult_wfifos_slink_rtl of neorv32_mult_wfifos_slink is

  signal con_gpio_o : std_ulogic_vector(63 downto 0);

-- Declaration of mult_wfifos constants

constant N_bits : natural := 32; -- 32 bits (16 bits plus 16 bits)
constant Log2_elements : natural := 2; -- Log2 is 2 ergo FIFO has 4 elements

-- Declaration of axi stream conection signals

signal s_ready : std_logic;
signal s_data : std_logic_vector(31 downto 0);
signal s_valid : std_logic;
signal m_ready : std_logic;
signal m_data : std_logic_vector(31 downto 0);
signal m_valid : std_logic;

signal s_data_u : std_ulogic_vector(31 downto 0);
signal m_data_u : std_ulogic_vector(31 downto 0);

begin

-- Mult_axis instantation

 mult_wfifos_axis_0 : entity work.mult_wfifos_axis
                            generic map (N_bits => N_bits,
                                         Log2_elements => Log2_elements)
                            port map (clk_mult => clk_i,
                                      s_axis_clk => clk_i,
                                      s_axis_rstn => rstn_i,
                                      s_axis_rdy => m_ready,
                                      s_axis_data => m_data,
                                      s_axis_valid => m_valid,
                                      m_axis_clk => clk_i,
                                      m_axis_rstn => rstn_i,
                                      m_axis_valid => s_valid,
                                      m_axis_data => s_data,
                                      m_axis_rdy => s_ready);

  -- The Core Of The Problem ----------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  neorv32_top_inst: neorv32_top
  generic map (
    -- General --
    CLOCK_FREQUENCY              => CLOCK_FREQUENCY,   -- clock frequency of clk_i in Hz
    INT_BOOTLOADER_EN            => false,              -- boot configuration: true = boot explicit bootloader; false = boot from int/ext (I)MEM
    -- RISC-V CPU Extensions --
    CPU_EXTENSION_RISCV_C        => true,              -- implement compressed extension?
    CPU_EXTENSION_RISCV_M        => true,              -- implement mul/div extension?
    CPU_EXTENSION_RISCV_Zicntr   => true,              -- implement base counters?
    -- Internal Instruction memory --
    MEM_INT_IMEM_EN              => true,              -- implement processor-internal instruction memory
    MEM_INT_IMEM_SIZE            => MEM_INT_IMEM_SIZE, -- size of processor-internal instruction memory in bytes
    -- Internal Data memory --
    MEM_INT_DMEM_EN              => true,              -- implement processor-internal data memory
    MEM_INT_DMEM_SIZE            => MEM_INT_DMEM_SIZE, -- size of processor-internal data memory in bytes
    -- Processor peripherals --
    IO_GPIO_NUM                  => 8,                 -- number of GPIO input/output pairs (0..64)
    IO_MTIME_EN                  => true,              -- implement machine system timer (MTIME)?
    IO_UART0_EN                  => true,              -- implement primary universal asynchronous receiver/transmitter (UART0)?
    -- Slink configuration --
    IO_SLINK_EN                  => true,              -- implement stream link interface (SLINK)?
    IO_SLINK_RX_FIFO             => 1,                   -- RX fifo depth, has to be a power of two, min 1
    IO_SLINK_TX_FIFO             => 1                   -- TX fifo depth, has to be a power of two, min 1
  )
  port map (
    -- Global control --
    clk_i       => clk_i,       -- global clock, rising edge
    rstn_i      => rstn_i,      -- global reset, low-active, async
    -- GPIO (available if IO_GPIO_EN = true) --
    gpio_o      => con_gpio_o,  -- parallel output
    -- primary UART0 (available if IO_GPIO_NUM > 0) --
    uart0_txd_o => uart0_txd_o, -- UART0 send data
    uart0_rxd_i => uart0_rxd_i,  -- UART0 receive data
    -- Stream Link Interface (available if IO_SLINK_EN = true) --
    slink_rx_dat_i => s_data_u,          -- RX input data
    slink_rx_val_i => s_valid,          -- RX valid input
    slink_rx_rdy_o => s_ready,          -- RX ready to receive
    slink_tx_dat_o => m_data_u,          -- TX output data
    slink_tx_val_o => m_valid,          -- TX valid output
    slink_tx_rdy_i => m_ready         -- TX ready to send

  );

-- GPIO output --
gpio_o <= con_gpio_o(7 downto 0);

-- Adjust with ulogic:

--TX (Master NEORV32 CPU; Slave mult_wfifos)

m_data <= To_StdLogicVector(m_data_u);

--RX (Master mult_wfifos; Slave NEORV32 CPU)

s_data_u <= To_StdULogicVector(s_data);

end architecture;
