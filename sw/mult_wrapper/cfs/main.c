// #################################################################################################
// # << NEORV32 - Custom Functions Subsystem (CFS) Demo Program >>                                 #
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
 * @file demo_cfs/main.c
 * @author Stephan Nolting
 * @brief Simple demo program for the _default_ custom functions subsystem (CFS) module.
 **************************************************************************/

#include <neorv32.h>


/**********************************************************************//**
 * @name User configuration
 **************************************************************************/

/** UART BAUD rate */
#define BAUD_RATE 19200


/**********************************************************************//**
 * Main function
 *
 * @note This program requires the CFS and UART0.
 *
 * @return 0 if execution was successful
 **************************************************************************/
int main() {

  uint32_t i;

  // capture all exceptions and give debug info via UART0
  // this is not required, but keeps us safe
  neorv32_rte_setup();

  // setup UART at default baud rate, no interrupts
  neorv32_uart0_setup(BAUD_RATE, 0);


  // check if CFS is implemented at all
  if (neorv32_cfs_available() == 0) {
    neorv32_uart0_printf("Error! No CFS synthesized!\n");
    return 1;
  }


  // intro
  neorv32_uart0_printf("\n<<< NEORV32 Custom Functions Subsystem (CFS) >>>\n\n");

  neorv32_uart0_printf(" This program works with the mult_wrapper integrate as a CFS \n\n");

  neorv32_uart0_printf("CFS memory-mapped registers:\n"
                       " * NEORV32_CFS->REG[0] (r/w): throw inputs to the mult_wrapper/read output from the mult_wrapper\n"
                       " * NEORV32_CFS->REG[1] (w): Set write/read control signal to the mult_wrapper\n\n");

  for (i=0; i<4; i++) {
    if(i==0){
            static uint32_t pri = 65537;
            //0000000000000001 x 0000000000000001
            NEORV32_CFS->REG[0] = pri; // write to CFS memory-mapped register 0
            //00000000000000000000000000000001
            NEORV32_CFS->REG[1] = 1; // write to CFS memory-mapped register 1; Write pri to mult_wrapper
            //00000000000000000000000000000010
            NEORV32_CFS->REG[1] = 2; // write to CFS memory-mapped register 1; Read pri from mult_wrapper
            //00000000000000000000000000000000
            NEORV32_CFS->REG[1] = 0; // write to CFS memory-mapped register 1; Clean the control signals

            neorv32_uart0_printf("%u: IN = 0x%x, OUT = 0x%x\n", i, pri, NEORV32_CFS->REG[0]); // read from CFS memory-mapped register 0          
           }
    if(i==1){
            static uint32_t sec = 131074;
            //0000000000000010 x 0000000000000010
            NEORV32_CFS->REG[0] = sec; // write to CFS memory-mapped register 0
            //00000000000000000000000000000001
            NEORV32_CFS->REG[1] = 1; // write to CFS memory-mapped register 1; Write sec to mult_wrapper
            //00000000000000000000000000000010
            NEORV32_CFS->REG[1] = 2; // write to CFS memory-mapped register 1; Read sec from mult_wrapper
            //00000000000000000000000000000000
            NEORV32_CFS->REG[1] = 0; // write to CFS memory-mapped register 1; Clean the control signals

            neorv32_uart0_printf("%u: IN = 0x%x, OUT = 0x%x\n", i, sec, NEORV32_CFS->REG[0]); // read from CFS memory-mapped register 0  
           }
    if(i==2){
            static uint32_t ter = 262148;
            //0000000000000100 x 0000000000000100
            NEORV32_CFS->REG[0] = ter; // write to CFS memory-mapped register 0
            //00000000000000000000000000000001
            NEORV32_CFS->REG[1] = 1; // write to CFS memory-mapped register 1; Write ter to mult_wrapper
            //00000000000000000000000000000010
            NEORV32_CFS->REG[1] = 2; // write to CFS memory-mapped register 1; Read ter from mult_wrapper
            //00000000000000000000000000000000
            NEORV32_CFS->REG[1] = 0; // write to CFS memory-mapped register 1; Clean the control signals

            neorv32_uart0_printf("%u: IN = 0x%x, OUT = 0x%x\n", i, ter, NEORV32_CFS->REG[0]); // read from CFS memory-mapped register 0       
           }
    if(i==3){
            static uint32_t cua = 524296;
            //0000000000001000 x 0000000000001000
            NEORV32_CFS->REG[0] = cua; // write to CFS memory-mapped register 0
            //00000000000000000000000000000001
            NEORV32_CFS->REG[1] = 1; // write to CFS memory-mapped register 1; Write cua to mult_wrapper
            //00000000000000000000000000000010
            NEORV32_CFS->REG[1] = 2; // write to CFS memory-mapped register 1; Read cua from mult_wrapper
            //00000000000000000000000000000000
            NEORV32_CFS->REG[1] = 0; // write to CFS memory-mapped register 1; Clean the control signals

            neorv32_uart0_printf("%u: IN = 0x%x, OUT = 0x%x\n", i, cua, NEORV32_CFS->REG[0]); // read from CFS memory-mapped register 0    
           }
  }

  neorv32_uart0_printf("\nCFS demo program completed.\n");

  return 0;
}
