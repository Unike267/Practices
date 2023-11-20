// #################################################################################################
// # << NEORV32 - CFU: Custom Instructions Example Program >>                                      #
// # ********************************************************************************************* #
// # BSD 3-Clause License                                                                          #
// #                                                                                               #
// # Copyright (c) 2023, Stephan Nolting. All rights reserved.                                     #
// #                                                                                               #
// # Redistribution and use in source and binary forms, with or without modification, are          #
// # permitted provided that the following conditions are met:                                     #
// #                                                                                               #
// # 1. Redistributions of source code must retain the above copyright notice, this list of        #
// #    conditions and the following disclaimer.                                                   #
// #                                                                                               #
// # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
// #    conditions and the following disclaimer in the documentation and/or other materials        #
// #    provided with the distribution.                                                            #
// #                                                                                               #
// # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
// #    endorse or promote products derived from this software without specific prior written      #
// #    permission.                                                                                #
// #                                                                                               #
// # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
// # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
// # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
// # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
// # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
// # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
// # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
// # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
// # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
// # ********************************************************************************************* #
// # The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
// #################################################################################################


/**********************************************************************//**
 * @file demo_cfu/main.c
 * @author Stephan Nolting
 * @brief Example program showing how to use the CFU's custom instructions.
 * @note Take a look at the highly-commented "hardware-counterpart" of this CFU
 * example in 'rtl/core/neorv32_cpu_cp_cfu.vhd'.
 **************************************************************************/
#include <neorv32.h>


/**********************************************************************//**
 * @name User configuration
 **************************************************************************/
/**@{*/
/** UART BAUD rate */
#define BAUD_RATE 19200
/**@}*/

/**********************************************************************//**
 * Main function
 *
 * @note This program requires the CFU and UART0.
 *
 * @return 0 if execution was successful
 **************************************************************************/
int main() {

  uint32_t i;

  // initialize NEORV32 run-time environment
  neorv32_rte_setup();

  // setup UART at default baud rate, no interrupts
  neorv32_uart0_setup(BAUD_RATE, 0);

  // check if UART0 is implemented
  if (neorv32_uart0_available() == 0) {
    return 1; // UART0 not available, exit
  }

  // check if the CFU is implemented at all (the CFU is wrapped in the core's "Zxcfu" ISA extension)
  if (neorv32_cpu_cfu_available() == 0) {
    neorv32_uart0_printf("ERROR! CFU ('Zxcfu' ISA extensions) not implemented!\n");
    return 1;
  }


  // intro
  neorv32_uart0_printf("\n<<< NEORV32 Custom Functions Unit (CFU) >>>\n\n");

  neorv32_uart0_printf(" This program works with the multiplier of the acceler integrate as a CFU \n\n");

  // ----------------------------------------------------------
  // R3-type instructions (up to 1024 custom instructions)
  // ----------------------------------------------------------

  neorv32_uart0_printf("\n--- CFU R3-Type: Multiplier Instruction ---\n");
  neorv32_uart0_printf(" rs1= 0xIN1-IN2, rs2= 0, rd = IN1 x IN2 \n\n");
  for (i=0; i<4; i++) {
    if(i==0){
            static uint32_t pri = 65537;
            //0000000000000001 x 0000000000000001
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b000, [rs1]=0x%x, [rs2]=0x%x ) = ", i, pri, 0);
            neorv32_uart0_printf("0x%x\n", neorv32_cfu_r3_instr(0b1111111, 0b000, pri, 0));           
           }
    if(i==1){
            static uint32_t sec = 131074;
            //0000000000000010 x 0000000000000010
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b000, [rs1]=0x%x, [rs2]=0x%x ) = ", i, sec, 0);
            neorv32_uart0_printf("0x%x\n", neorv32_cfu_r3_instr(0b1111111, 0b000, sec, 0));           
           }
    if(i==2){
            static uint32_t ter = 262148;
            //0000000000000100 x 0000000000000100
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b000, [rs1]=0x%x, [rs2]=0x%x ) = ", i, ter, 0);
            neorv32_uart0_printf("0x%x\n", neorv32_cfu_r3_instr(0b1111111, 0b000, ter, 0));           
           }
    if(i==3){
            static uint32_t cua = 524296;
            //0000000000001000 x 0000000000001000
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b000, [rs1]=0x%x, [rs2]=0x%x ) = ", i, cua, 0);
            neorv32_uart0_printf("0x%x\n", neorv32_cfu_r3_instr(0b1111111, 0b000, cua, 0));           
           }
  }

  neorv32_uart0_printf("\nCFU demo program completed.\n");
  return 0;
}
