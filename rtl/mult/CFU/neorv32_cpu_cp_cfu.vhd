-- ================================================================================ --
-- NEORV32 CPU - Co-Processor: Custom (RISC-V Instructions) Functions Unit (CFU)    --
-- -------------------------------------------------------------------------------- --
-- For custom/user-defined RISC-V instructions (R3-type, R4-type and R5-type        --
-- formats). See the  CPU's documentation for more information. Also take a look at --
-- the "software-counterpart" this default CFU hardware in 'sw/example/demo_cfu'.   --
-- -------------------------------------------------------------------------------- --
-- The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              --
-- Copyright (c) NEORV32 contributors.                                              --
-- Copyright (c) 2020 - 2024 Stephan Nolting. All rights reserved.                  --
-- Licensed under the BSD-3-Clause license, see LICENSE for details.                --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_cpu_cp_cfu is
  port (
    -- global control --
    clk_i       : in  std_ulogic; -- global clock, rising edge
    rstn_i      : in  std_ulogic; -- global reset, low-active, async
    ctrl_i      : in  ctrl_bus_t; -- main control bus
    start_i     : in  std_ulogic; -- trigger operation
    -- CSR interface --
    csr_we_i    : in  std_ulogic; -- write enable
    csr_addr_i  : in  std_ulogic_vector(1 downto 0); -- address
    csr_wdata_i : in  std_ulogic_vector(XLEN-1 downto 0); -- write data
    csr_rdata_o : out std_ulogic_vector(XLEN-1 downto 0) := (others => '0'); -- read data
    -- data input --
    rs1_i       : in  std_ulogic_vector(XLEN-1 downto 0); -- rf source 1
    rs2_i       : in  std_ulogic_vector(XLEN-1 downto 0); -- rf source 2
    rs3_i       : in  std_ulogic_vector(XLEN-1 downto 0); -- rf source 3
    rs4_i       : in  std_ulogic_vector(XLEN-1 downto 0); -- rf source 4
    -- result and status --
    res_o       : out std_ulogic_vector(XLEN-1 downto 0) := (others => '0'); -- operation result
    valid_o     : out std_ulogic := '0' -- data output valid
  );
end neorv32_cpu_cp_cfu;

architecture neorv32_cpu_cp_cfu_rtl of neorv32_cpu_cp_cfu is

  -- CFU Control ---------------------------------------------
  -- ------------------------------------------------------------
  type control_t is record
    busy   : std_ulogic; -- CFU is busy
    done   : std_ulogic; -- set to '1' when processing is done
    result : std_ulogic_vector(XLEN-1 downto 0); -- CFU processing result (for write-back to register file)
    rtype  : std_ulogic_vector(1 downto 0); -- instruction type, see constants below
    funct3 : std_ulogic_vector(2 downto 0); -- "funct3" bit-field from custom instruction word
    funct7 : std_ulogic_vector(6 downto 0); -- "funct7" bit-field from custom instruction word
  end record;
  signal control : control_t;

  -- instruction format types --
  constant r3type_c  : std_ulogic_vector(1 downto 0) := "00"; -- R3-type instructions (custom-0 opcode)
  constant r4type_c  : std_ulogic_vector(1 downto 0) := "01"; -- R4-type instructions (custom-1 opcode)
  constant r5typeA_c : std_ulogic_vector(1 downto 0) := "10"; -- R5-type instruction A (custom-2 opcode)
  constant r5typeB_c : std_ulogic_vector(1 downto 0) := "11"; -- R5-type instruction B (custom-3 opcode)

  -- User-Defined Logic --------------------------------------
  -- ------------------------------------------------------------

  constant N_bits : natural := 32; -- 32 bits (16 bits plus 16 bits)
  constant Log2_elements : natural := 2; -- Log2 is 2 ergo FIFO has 4 elements

  signal reset : std_logic;

  type mult_wfifos_t is record
    sreg : std_ulogic_vector(5 downto 0); -- 6 cycles latency = 6 bits in arbitration shift register + 1 cycle for output = 7 cycles in total
    done : std_logic;
    --
    input : std_logic_vector(31 downto 0);
    output : std_logic_vector(31 downto 0);
    output_u  : std_ulogic_vector(31 downto 0);
    wr : std_logic;
    rd : std_logic;
  end record;
  signal mw : mult_wfifos_t;

  type multp_wfifos_t is record
    sreg : std_ulogic_vector(3 downto 0); -- 4 cycles latency = 4 bits in arbitration shift register + 1 cycle for output = 5 cycles in total
    done : std_logic;
    --
    input : std_logic_vector(31 downto 0);
    output : std_logic_vector(31 downto 0);
    output_u  : std_ulogic_vector(31 downto 0);
    wr : std_logic;
    rd : std_logic;
  end record;
  signal mpw : multp_wfifos_t;

  type multp_t is record
    sreg : std_logic; -- 1 cycle latency = 1 bit in arbitration shift register + 1 cycle for output = 2 cycles in total
    done : std_logic;
    --
    input : std_logic_vector(31 downto 0);
    output : std_logic_vector(31 downto 0);
    output_u  : std_ulogic_vector(31 downto 0);
  end record;
  signal mp : multp_t;

begin

  -- **************************************************************************************************************************
  -- This controller is required to handle the CFU-CPU interface.
  -- **************************************************************************************************************************

  -- CFU Controller -------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- The <control> record acts as proxy logic that ensures correct communication with the
  -- CPU pipeline. However, this control instance adds one additional cycle of latency.
  -- Advanced users can remove this default control instance to obtain maximum throughput.
  cfu_control: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      res_o        <= (others => '0');
      control.busy <= '0';
    elsif rising_edge(clk_i) then
      res_o <= (others => '0'); -- default; all CPU co-processor outputs are logically OR-ed
      if (control.busy = '0') then -- CFU is idle
        control.busy <= start_i; -- trigger new CFU operation
      else -- CFU operation in progress
        res_o <= control.result; -- output result only if CFU is processing; has to be all-zero otherwise
        if (control.done = '1') or (ctrl_i.cpu_trap = '1') then -- operation done or abort if trap (exception)
          control.busy <= '0';
        end if;
      end if;
    end if;
  end process cfu_control;

  -- CPU feedback --
  valid_o <= control.busy and control.done; -- set one cycle before result data

  -- pack user-defined instruction type/function bits --
  control.rtype  <= ctrl_i.ir_opcode(6 downto 5);
  control.funct3 <= ctrl_i.ir_funct3;
  control.funct7 <= ctrl_i.ir_funct12(11 downto 5);


  -- **************************************************************************************************************************
  -- CFU Hardware Documentation
  -- **************************************************************************************************************************

  -- ----------------------------------------------------------------------------------------
  -- CFU Instruction Formats
  -- ----------------------------------------------------------------------------------------
  -- The CFU supports three instruction types:
  --
  -- Up to 1024 RISC-V R3-Type Instructions (RISC-V standard):
  -- This format consists of two source registers ('rs1', 'rs2'), a destination register ('rd') and two "immediate" bit-fields
  -- ('funct7' and 'funct3').
  --
  -- Up to 8 RISC-V R4-Type Instructions (RISC-V standard):
  -- This format consists of three source registers ('rs1', 'rs2', 'rs3'), a destination register ('rd') and one "immediate"
  -- bit-field ('funct3').
  --
  -- Two individual RISC-V R5-Type Instructions (NEORV32-specific):
  -- This format consists of four source registers ('rs1', 'rs2', 'rs3', 'rs4') and a destination register ('rd'). There are
  -- no immediate fields.

  -- ----------------------------------------------------------------------------------------
  -- Input Operands
  -- ----------------------------------------------------------------------------------------
  -- > rs1_i          (input, 32-bit): source register 1; selected by 'rs1' bit-field
  -- > rs2_i          (input, 32-bit): source register 2; selected by 'rs2' bit-field
  -- > rs3_i          (input, 32-bit): source register 3; selected by 'rs3' bit-field
  -- > rs4_i          (input, 32-bit): source register 4; selected by 'rs4' bit-field
  -- > control.rtype  (input,  2-bit): defining the R-type; driven by OPCODE
  -- > control.funct3 (input,  3-bit): 3-bit function select / immediate value; driven by instruction word's 'funct3' bit-field
  -- > control.funct7 (input,  7-bit): 7-bit function select / immediate value; driven by instruction word's 'funct7' bit-field
  --
  -- [NOTE] The set of usable signals depends on the actual R-type of the instruction.
  --
  -- The general instruction type is identified by the <control.rtype>.
  -- > r3type_c  - R3-type instructions (custom-0 opcode)
  -- > r4type_c  - R4-type instructions (custom-1 opcode)
  -- > r5typeA_c - R5-type instruction A (custom-2 opcode)
  -- > r5typeB_c - R5-type instruction B (custom-3 opcode)
  --
  -- The four signals <rs1_i>, <rs2_i>, <rs3_i> and <rs4_i> provide the source operand data read from the CPU's register file.
  -- The source registers are adressed by the custom instruction word's 'rs1', 'rs2', 'rs3' and 'rs4' bit-fields.
  --
  -- The actual CFU operation can be defined by using the <control.funct3> and/or <control.funct7> signals (if available for a
  -- certain R-type instruction). Both signals are directly driven by the according bit-fields of the custom instruction word.
  -- These immediates can be used to select the actual function or to provide small literals for certain operations (like shift
  -- amounts, offsets, multiplication factors, ...).
  --
  -- [NOTE] <rs1_i>, <rs2_i>, <rs3_i> and <rs4_i> are directly driven by the register file (e.g. block RAM). For complex CFU
  --        designs it is recommended to buffer these signals using CFU-internal registers before actually using them.
  --
  -- [NOTE] The R4-type instructions and R5-type instruction provide additional source register. When used, this will increase
  --        the hardware requirements of the register file.

  -- ----------------------------------------------------------------------------------------
  -- Result Output
  -- ----------------------------------------------------------------------------------------
  -- > control.result (output, 32-bit): processing result
  --
  -- When the CFU has completed computations, the data send via the <control.result> signal will be written to the CPU's register
  -- file. The destination register is addressed by the <rd> bit-field in the instruction word. The CFU result output is registered
  -- in the CFU controller (see above) - so do not worry too much about increasing the CPU's critical path with your custom
  -- logic.

  -- ----------------------------------------------------------------------------------------
  -- Processing Control
  -- ----------------------------------------------------------------------------------------
  -- > rstn_i       (input,  1-bit): asynchronous reset, low-active
  -- > clk_i        (input,  1-bit): main clock, triggering on rising edge
  -- > start_i      (input,  1-bit): operation trigger (start processing, high for one cycle)
  -- > control.done (output, 1-bit): set high when processing is done
  --
  -- For pure-combinatorial instructions (completing within 1 clock cycle) <control.done> can be tied to 1. If the CFU requires
  -- several clock cycles for internal processing, the <start_i> signal can be used to *start* a new iterative operation. As soon
  -- as all internal computations have completed, the <control.done> signal has to be set to indicate completion. This will
  -- complete CFU instruction operation and will also write the processing result <control.result> back to the CPU register file.

  -- ----------------------------------------------------------------------------------------
  -- CFU Exception
  -- ----------------------------------------------------------------------------------------
  -- The CFU does not provide a dedicated exception mechanism. However, if the <control.done> signal is not set within a bound
  -- time window (default = 512 cycles; see "monitor_mc_tmo_c" constant in the main NEORV32 package file) the CFU operation is
  -- automatically terminated by the hardware and an **illegal instruction exception** is raised. This default mechanism combined
  -- with according software handling can be used to "emulate" dedicated CFU exceptions.

  -- ----------------------------------------------------------------------------------------
  -- CFU-Internal Control and Status Registers (CFU-CSRs)
  -- ----------------------------------------------------------------------------------------
  -- > csr_we_i    (input,   1-bit): set to indicate a valid CFU CSR write access
  -- > csr_addr_i  (input,   2-bit): CSR address
  -- > csr_wdata_i (input,  32-bit): CSR write data
  -- > csr_rdata_i (output, 32-bit): CSR read data
  --
  -- The NEORV32 provides four directly accessible CSRs for custom use inside the CFU. These registers can be used to pass
  -- further operands, to check the unit's status or to configure operation modes. For instance, a 128-bit wide key could be
  -- passed to an encryption system.
  --
  -- If more than four CFU-internal CSRs are required the designer can implement an "indirect access mechanism" based on just
  -- two of the default CSRs: one CSR is used to configure the index while the other is used as an alias to exchange data with
  -- the indexed CFU-internal CSR - this concept is similar to the RISC-V Indirect CSR Access Extension Specification (Smcsrind).


  -- **************************************************************************************************************************
  -- Actual CFU User Logic Example: XTEA - Extended Tiny Encryption Algorithm (replace this with your custom logic)
  -- **************************************************************************************************************************

  reset <= not(rstn_i);

  -- Mult_wfifos instantation

  mult_wfifos_0 : entity work.mult_wfifos
                generic map (N_bits => N_bits,
                             Log2_elements => Log2_elements)
                port map (clk_wr => clk_i,
                          clk_mult => clk_i,
                          clk_rd => clk_i,
                          rst => reset,
                          din => mw.input,
                          dout => mw.output,
                          wr => mw.wr,
                          rd => mw.rd,
                          full => open,
                          empty => open);

  -- Multp_wfifos instantation

  multp_wfifos_0 : entity work.multp_wfifos
                 generic map (g_data_width => N_bits,
                              g_fifo_depth => Log2_elements)
                 port map (clk_in => clk_i,
                           clk_mult => clk_i,
                           clk_out => clk_i,
                           rst => reset,
                           din => mpw.input,
                           dout => mpw.output,
                           write => mpw.wr,
                           read => mpw.rd,
                           full => open,
                           empty => open);

  -- Multp instantation

  multp_0 : entity work.multp_op
                 generic map (g_data_width => N_bits)
                 port map (din => mp.input,
                           dout => mp.output);

  -- Inputs
  mw.input <= To_StdLogicVector(rs1_i)  when control.funct3 = "000" and start_i = '1' else
              (others => '0');
  mpw.input <= To_StdLogicVector(rs1_i) when control.funct3 = "001" and start_i = '1' else
              (others => '0');
  mp.input <= To_StdLogicVector(rs1_i)  when mp.done = '1' else
              (others => '0');

  -- Outputs
  mw.output_u <= To_StdULogicVector(mw.output);
  mpw.output_u <= To_StdULogicVector(mpw.output);
  mp.output_u <= To_StdULogicVector(mp.output);

    -- Iteration control
    iteration_control: process(rstn_i, clk_i)
    begin
      if (rstn_i = '0') then
        mw.sreg <= (others => '0');
        mpw.sreg <= (others => '0');
        mp.sreg <= '0';
      elsif rising_edge(clk_i) then
        -- operation trigger --
        if (control.busy = '0') and -- CFU is idle (ready for next operation)
           (start_i = '1') and -- CFU is actually triggered by a custom instruction word
           (control.rtype = r3type_c) and -- this is a R3-type instruction
           (control.funct3 = "000") then -- trigger only for 000 funct3 value
             mw.sreg(0) <= '1';
        elsif (control.busy = '0') and -- CFU is idle (ready for next operation)
              (start_i = '1') and -- CFU is actually triggered by a custom instruction word
              (control.rtype = r3type_c) and -- this is a R3-type instruction
              (control.funct3 = "001") then -- trigger only for 001 funct3 value
             mpw.sreg(0) <= '1';
        elsif (control.busy = '0') and -- CFU is idle (ready for next operation)
              (start_i = '1') and -- CFU is actually triggered by a custom instruction word
              (control.rtype = r3type_c) and -- this is a R3-type instruction
              (control.funct3 = "010") then -- trigger only for 010 funct3 value
             mp.sreg <= '1';
        else
             mw.sreg(0) <= '0';
             mpw.sreg(0) <= '0';
             mp.sreg <= '0';
        end if;
        -- simple shift register for tracking operation --
          mw.sreg(mw.sreg'left downto 1) <= mw.sreg(mw.sreg'left-1 downto 0); -- shift left
          mpw.sreg(mpw.sreg'left downto 1) <= mpw.sreg(mpw.sreg'left-1 downto 0); -- shift left
        end if;
      end process iteration_control;

      -- Processing has reached last stage (= done) when mult_wfifos sreg's MSB is set --
      mw.done <= mw.sreg(mw.sreg'left);

      -- Processing has reached last stage (= done) when multp_wfifos sreg's MSB is set --
      mpw.done <= mpw.sreg(mpw.sreg'left);

      -- Processing has reached last stage (= done) when multp sreg is equal to 1 --
      mp.done <= mp.sreg;

      -- Write signal for mult_wfifos when the operation starts
      mw.wr <= start_i when control.funct3 = "000" else
               '0';
      -- Write signal for multp_wfifos when the operation starts
      mpw.wr <= start_i when control.funct3 = "001" else
               '0';
      -- Read signal for mult_wfifos in the fifth iteration
      mw.rd <= mw.sreg(4);
      -- Read signal for multp_wfifos in the third iteration
      mpw.rd <= mpw.sreg(2);

-- Output select --------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
    out_select: process(control, rs1_i, rs2_i, mw, mpw, mp)
    begin
      case control.rtype is
        when r3type_c => -- R3-type instructions
          case control.funct3 is
            when "000" => -- funct3 = "000": mult_wfifos
              control.result <= mw.output_u;
              control.done   <= mw.done; -- 6 cycles to perform multiplication
            when "001" => -- funct3 = "001": multp_wfifos
              control.result <= mpw.output_u;
              control.done   <= mpw.done; -- 4 cycles to perform multiplication
            when "010" => -- funct3 = "010": multp
              control.result <= mp.output_u;
              control.done   <= mp.done; -- 1 cycle to perform multiplication
            when others => -- not implemented
              control.result <= (others => '0');
              control.done   <= '0'; -- this will cause an illegal instruction exception after timeout
          end case;
        when others => -- undefined
        -- ----------------------------------------------------------------------
          control.result <= (others => '0');
          control.done   <= '0';
      end case;
    end process out_select;

end neorv32_cpu_cp_cfu_rtl;
