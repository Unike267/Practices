// #################################################################################################
// # << NEORV32 - SLINK Demo Program >>                                                            #
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
 * @file demo_slink/main.c
 * @author Stephan Nolting
 * @brief SLINK demo program.
 **************************************************************************/
#include <neorv32.h>
#include <string.h>


/**********************************************************************//**
 * @name User configuration
 **************************************************************************/
/**@{*/
/** UART BAUD rate */
#define BAUD_RATE 19200
/**@}*/

/**********************************************************************//**
 * Simple SLINK demo program.
 *
 * @note This program requires the UART0 and the SLINK to be synthesized.
 *
 * @return =! 0 if execution failed.
 **************************************************************************/
int main() {

  int i, slink_rc;


  // capture all exceptions and give debug info via UART0
  neorv32_rte_setup();

  // setup UART at default baud rate, no interrupts
  neorv32_uart0_setup(BAUD_RATE, 0);

  // check if UART0 unit is implemented at all
  if (neorv32_uart0_available() == 0) {
    return -1; // abort if not implemented
  }


  // intro
  neorv32_uart0_printf("\n<<< ACCELER via Slink demo program >>>\n\n");

  // check if SLINK is implemented at all
  if (neorv32_slink_available() == 0) {
    neorv32_uart0_printf("ERROR! SLINK module not implemented.");
    return -1;
  }

  // show SLINK FIFO configuration
  int rx_depth = neorv32_slink_get_rx_fifo_depth();
  int tx_depth = neorv32_slink_get_tx_fifo_depth();
  neorv32_uart0_printf("RX FIFO depth: %u\n"
                       "TX FIFO depth: %u\n\n",
                       rx_depth, tx_depth);

  // setup SLINK module
  neorv32_slink_setup(0);

  // TX demo
  neorv32_uart0_printf("-------- Write data to acceler --------\n");

  //Acceler Fifos have 4 elements
  for (i=0; i<4 ; i++) {
    if(i==0){
            static uint32_t pri = 65537;
            //0000000000000001 x 0000000000000001
            neorv32_uart0_printf("[%i] Sending 0x%x... ", i, pri);

            slink_rc = neorv32_slink_tx_status();
            if (slink_rc == SLINK_FIFO_FULL) {
                neorv32_uart0_printf("FAILED! TX FIFO full!\n");
                break;
            }
            else {
                neorv32_slink_put(pri);
                neorv32_uart0_printf("ok\n");
                 }
           } 
    if(i==1){
            static uint32_t sec = 131074;
            //0000000000000010 x 0000000000000010
            neorv32_uart0_printf("[%i] Sending 0x%x... ", i, sec);

            slink_rc = neorv32_slink_tx_status();
            if (slink_rc == SLINK_FIFO_FULL) {
                neorv32_uart0_printf("FAILED! TX FIFO full!\n");
                break;
            }
            else {
                neorv32_slink_put(sec);
                neorv32_uart0_printf("ok\n");
                 }
           }   
    if(i==2){
            static uint32_t ter = 262148;
            //0000000000000100 x 0000000000000100
            neorv32_uart0_printf("[%i] Sending 0x%x... ", i, ter);

            slink_rc = neorv32_slink_tx_status();
            if (slink_rc == SLINK_FIFO_FULL) {
                neorv32_uart0_printf("FAILED! TX FIFO full!\n");
                break;
            }
            else {
                neorv32_slink_put(ter);
                neorv32_uart0_printf("ok\n");
                 }
           }   

      if(i==3){
            static uint32_t cua = 524296;
            //0000000000001000 x 0000000000001000
            neorv32_uart0_printf("[%i] Sending 0x%x... ", i, cua);

            slink_rc = neorv32_slink_tx_status();
            if (slink_rc == SLINK_FIFO_FULL) {
                neorv32_uart0_printf("FAILED! TX FIFO full!\n");
                break;
            }
            else {
                neorv32_slink_put(cua);
                neorv32_uart0_printf("ok\n");
                 }
           }   
    
  }


  // RX demo
  neorv32_uart0_printf("\n-------- Read data from acceler --------\n");

  for (i=0; i<4; i++) {
    neorv32_uart0_printf("[%i] Reading RX data... ", i);

    slink_rc = neorv32_slink_rx_status();
    if (slink_rc == SLINK_FIFO_EMPTY) {
      neorv32_uart0_printf("FAILED! RX FIFO empty!\n");
      break;
    }
    else {
      neorv32_uart0_printf("0x%x\n", neorv32_slink_get());
    }
  }

  neorv32_uart0_printf("\nProgram execution completed.\n");
  return 0;
}

