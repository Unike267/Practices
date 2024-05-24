#include <neorv32.h>
#include <string.h>

#define BAUD_RATE 19200

// This defines is used to bypass the intermediate print functions between axi functions (for latency and throughput measurements)
// Comment these defines to perform a normal execution
// Uncomment latency to perform latency measurements
// Uncomment throughput to perform throughput measurements
//#define latency
//#define throughput

int main() {

  // Capture all exceptions and give debug info via UART0
  neorv32_rte_setup();

  // Setup UART at default baud rate, no interrupts
  neorv32_uart0_setup(BAUD_RATE, 0);

  // Check if UART0 unit is implemented at all
  if (neorv32_uart0_available() == 0) {
    return -1; // abort if not implemented
  }

  // check if the CPU base counters are implemented
  if ((neorv32_cpu_csr_read(CSR_MXISA) & (1 << CSR_MXISA_ZICNTR)) == 0) {
    neorv32_uart0_printf("ERROR! Base counters ('Zicntr' ISA extensions) not implemented!\n");
    return -1;
  }

  // check if SLINK is implemented at all
  if (neorv32_slink_available() == 0) {
    neorv32_uart0_printf("ERROR! SLINK module not implemented.");
    return -1;
  }

  // setup SLINK module
  neorv32_slink_setup(0, 0);

  // Declaration of variables 
  //0000000000000001 x 0000000000000001
  static uint32_t fir = 0x00010001;
  //0000000000000010 x 0000000000000010
  static uint32_t sec = 0x00020002;
  //0000000000000100 x 0000000000000100
  static uint32_t thi = 0x00040004;
  //0000000000001000 x 0000000000001000
  static uint32_t fou = 0x00080008;

#ifdef latency
  // Intro
  neorv32_uart0_printf("\n A-lat \n\n");
  // Write 4 inputs to mult and read the outputs from mult one by one
    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_slink_put(fir);
    neorv32_slink_get();
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_slink_put(sec);
    neorv32_slink_get();
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_slink_put(thi);
    neorv32_slink_get();
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_slink_put(fou);
    neorv32_slink_get();
    neorv32_cpu_csr_read(CSR_MCYCLE); 

  // End
  neorv32_uart0_printf("\nEND-lat\n");
  #elif defined throughput
  // Intro
  neorv32_uart0_printf("\n A-thr \n\n");
  // Write 4 inputs to mult

    neorv32_slink_put(fir);

    neorv32_slink_put(sec);

    neorv32_slink_put(thi);

    neorv32_slink_put(fou);

  // Read outputs from mult

    neorv32_slink_get();
    neorv32_cpu_csr_write(CSR_MCYCLE, 0);

    neorv32_slink_get();
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_slink_get();
    neorv32_cpu_csr_read(CSR_MCYCLE);

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_slink_get();
    neorv32_cpu_csr_read(CSR_MCYCLE);

  // End
  neorv32_uart0_printf("\nEND-thr\n");
  #else
  int i, slink_rc;;
  // show SLINK FIFO configuration
  int rx_depth = neorv32_slink_get_rx_fifo_depth();
  int tx_depth = neorv32_slink_get_tx_fifo_depth();
  // Intro
  neorv32_uart0_printf("\n<<< MULT(P) via slink (AXI-Stream) demo program >>>\n\n");
  neorv32_uart0_printf("RX FIFO depth: %u\n"
                       "TX FIFO depth: %u\n\n",
                       rx_depth, tx_depth);
  neorv32_uart0_printf("-------- Write data to MULT(P) --------\n");
  // Write 4 inputs to mult
    for (i=0; i<4 ; i++) {
    if(i==0){
            neorv32_uart0_printf("[%i] Sending 0x%x... ", i, fir);
            slink_rc = neorv32_slink_tx_status();
                if (slink_rc == SLINK_FIFO_FULL) {
                        neorv32_uart0_printf("FAILED! TX FIFO full!\n");
                        break;
                }
                else {
                        neorv32_slink_put(fir);
                        neorv32_uart0_printf("ok\n");
                     }
            } 
    if(i==1){
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
            neorv32_uart0_printf("[%i] Sending 0x%x... ", i, thi);
            slink_rc = neorv32_slink_tx_status();
                if (slink_rc == SLINK_FIFO_FULL) {
                        neorv32_uart0_printf("FAILED! TX FIFO full!\n");
                        break;
                }
                else {
                        neorv32_slink_put(thi);
                        neorv32_uart0_printf("ok\n");
                     }
            }   
    if(i==3){
            neorv32_uart0_printf("[%i] Sending 0x%x... ", i, fou);
            slink_rc = neorv32_slink_tx_status();
                if (slink_rc == SLINK_FIFO_FULL) {
                        neorv32_uart0_printf("FAILED! TX FIFO full!\n");
                        break;
                }
                else {
                        neorv32_slink_put(fou);
                        neorv32_uart0_printf("ok\n");
                     }
            }   
    } 
  neorv32_uart0_printf("\n-------- Read data from MULT(P) --------\n");
  // Read outputs from mult
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
  // End
  neorv32_uart0_printf("\nProgram execution completed.\n");
  #endif

  return 0;
}
