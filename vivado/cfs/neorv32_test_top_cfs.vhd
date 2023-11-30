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

entity neorv32_test_top_cfs is
  generic (
    -- adapt these for your setup --
    CLOCK_FREQUENCY   : natural := 100000000; -- clock frequency of clk_i in Hz
    MEM_INT_IMEM_SIZE : natural := 16*1024;   -- size of processor-internal instruction memory in bytes
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

architecture neorv32_test_top_cfs_rtl of neorv32_test_top_cfs is

  signal con_gpio_o : std_ulogic_vector(63 downto 0);

  -- Acceler constants:
  constant N_bits : natural := 32; -- 32 bits (16 bits plus 16 bits)
  constant Log2_elements : natural := 2; -- Log2 is 2 ergo FIFO has 4 elements
  -- Acceler signals
  signal reset : std_logic;
  signal acceler_input : std_logic_vector(31 downto 0);
  signal acceler_control : std_logic_vector(1 downto 0);
  signal acceler_output : std_logic_vector(31 downto 0);
  signal acceler_write : std_logic;
  signal acceler_read : std_logic;
  signal full_buffer : std_logic;
  signal empty_buffer : std_logic;

  signal aux_write : std_logic;
  signal aux_read : std_logic;
  
  signal cfs_o_buffer : std_ulogic_vector(33 downto 0);
  signal acceler_input_u : std_ulogic_vector(31 downto 0);
  signal acceler_control_u : std_ulogic_vector(1 downto 0);
  signal acceler_output_u : std_ulogic_vector(31 downto 0); 


begin
  
  -- Acceler instantation

  acceler_0 : entity work.acceler
                generic map (N_bits => N_bits,
                             Log2_elements => Log2_elements)
                port map (clk_wr => clk_i,
                          clk_mult => clk_i,
                          clk_rd => clk_i,
                          rst => reset,
                          acceler_in => acceler_input,
                          acceler_out => acceler_output,
                          wr_acceler => acceler_write,
                          rd_acceler => acceler_read,
                          full_acceler => full_buffer,
                          empty_acceler => empty_buffer);

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
    -- CFS
    IO_CFS_EN                    => true,              -- implement custom functions subsystem (CFS)?
    IO_CFS_CONFIG                => x"00000000",       -- custom CFS configuration generic
    IO_CFS_IN_SIZE               => 32,                -- size of CFS input conduit in bits
    IO_CFS_OUT_SIZE              => 34,                -- size of CFS output conduit in bits
    -- Processor peripherals --
    IO_GPIO_NUM                  => 8,                 -- number of GPIO input/output pairs (0..64)
    IO_MTIME_EN                  => true,              -- implement machine system timer (MTIME)?
    IO_UART0_EN                  => true              -- implement primary universal asynchronous receiver/transmitter (UART0)?
  )
  port map (
    -- Global control --
    clk_i       => clk_i,       -- global clock, rising edge
    rstn_i      => rstn_i,      -- global reset, low-active, async
    -- Custom Functions Subsystem IO (available if IO_CFS_EN = true) --
    cfs_in_i    => acceler_output_u, -- custom CFS inputs conduit
    cfs_out_o   => cfs_o_buffer, -- custom CFS outputs conduit
    -- GPIO (available if IO_GPIO_EN = true) --
    gpio_o      => con_gpio_o,  -- parallel output
    -- primary UART0 (available if IO_GPIO_NUM > 0) --
    uart0_txd_o => uart0_txd_o, -- UART0 send data
    uart0_rxd_i => uart0_rxd_i  -- UART0 receive data
  );

    -- Acceler connection
    -- Reset (NEORV32 rst is low-active)
    reset <= not(rstn_i);

    acceler_input_u <= cfs_o_buffer(31 downto 0);
    acceler_control_u <= cfs_o_buffer(33 downto 32);
    
    acceler_input <= To_StdLogicVector(acceler_input_u);
    acceler_control <= To_StdLogicVector(acceler_control_u);

    acceler_output_u <= To_StdULogicVector(acceler_output);

    -- Make acceler write and read signals; Make sure that the write and read signals only last one cycle.
    
    Make_acceler_write : process (clk_i,reset)
        begin   
            if(reset = '1') then
                acceler_write <= '0';
                aux_write <= '0';            
            elsif( rising_edge(clk_i) ) then
                if(acceler_control(0) = '0' and aux_write = '1') then
                    aux_write <= '0';            
                elsif(acceler_control(0) = '1' and aux_write = '0') then
                    if (full_buffer = '0') then                   
                        acceler_write <= '1'; -- Write in the acceler
                        aux_write <= '1';
                    end if;
                elsif(acceler_control(0) = '1' and aux_write = '1') then
                    acceler_write <= '0'; -- The write signal only lasts one cycle
                end if;
            end if;
        end process Make_acceler_write;

    Make_acceler_read : process (clk_i,reset)
        begin   
            if(reset = '1') then
                acceler_read <= '0';
                aux_read <= '0';            
            elsif( rising_edge(clk_i) ) then
                if(acceler_control(1) = '0' and aux_read = '1') then
                    aux_read <= '0';            
                elsif(acceler_control(1) = '1' and aux_read = '0') then
                    if (empty_buffer = '0') then                   
                        acceler_read <= '1'; -- Read from the acceler
                        aux_read <= '1';
                    end if;
                elsif(acceler_control(1) = '1' and aux_read = '1') then
                    acceler_read <= '0'; -- The read signal only lasts one cycle
                end if;
            end if;
        end process Make_acceler_read;

    -- GPIO output --
    gpio_o <= con_gpio_o(7 downto 0);

end architecture;
