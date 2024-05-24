#include <neorv32.h>
#include <string.h>

#define BAUD_RATE 19200

// This defines is used to bypass the intermediate print functions between wishbone functions (for latency and throughput measurements)
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

  // Declaration of variables 
  // address 0x90000000
  static uint32_t add = 0x90000000;
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
  neorv32_uart0_printf("\n W-lat \n\n");
  // Write 4 inputs to mult and read the outputs from mult one by one
    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cpu_store_unsigned_word(add, fir);
    neorv32_cpu_load_unsigned_word(add);
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cpu_store_unsigned_word(add, sec);
    neorv32_cpu_load_unsigned_word(add);
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cpu_store_unsigned_word(add, thi);
    neorv32_cpu_load_unsigned_word(add);
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cpu_store_unsigned_word(add, fou);
    neorv32_cpu_load_unsigned_word(add);
    neorv32_cpu_csr_read(CSR_MCYCLE); 

  // End
  neorv32_uart0_printf("\nEND-lat\n");
  #elif defined throughput
  // Intro
  neorv32_uart0_printf("\n W-thr \n\n");
  // Write 4 inputs to mult

    neorv32_cpu_store_unsigned_word(add, fir);

    neorv32_cpu_store_unsigned_word(add, sec);

    neorv32_cpu_store_unsigned_word(add, thi);

    neorv32_cpu_store_unsigned_word(add, fou);

  // Read outputs from mult

    neorv32_cpu_load_unsigned_word(add);
    neorv32_cpu_csr_write(CSR_MCYCLE, 0);

    neorv32_cpu_load_unsigned_word(add);
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cpu_load_unsigned_word(add);
    neorv32_cpu_csr_read(CSR_MCYCLE);

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cpu_load_unsigned_word(add);
    neorv32_cpu_csr_read(CSR_MCYCLE);

  // End
  neorv32_uart0_printf("\nEND-thr\n");
  #else
  int i;
  // Intro
  neorv32_uart0_printf("\n<<< MULT(P) via external memory interface (EMEM) demo program >>>\n\n");
  neorv32_uart0_printf("-------- Write data to MULT(P) --------\n");
  // Write 4 inputs to mult
    for (i=0; i<4 ; i++) {
    if(i==0){
            neorv32_cpu_store_unsigned_word(add, fir);
            neorv32_uart0_printf("\n[%i] Sending 0x%x to address 0x%x \n",i,fir,add);
           } 
    if(i==1){
            neorv32_cpu_store_unsigned_word(add, sec);
            neorv32_uart0_printf("\n[%i] Sending 0x%x to address 0x%x \n",i,sec,add);
           }   
    if(i==2){
            neorv32_cpu_store_unsigned_word(add, thi);
            neorv32_uart0_printf("\n[%i] Sending 0x%x to address 0x%x \n",i,thi,add);
           }   
    if(i==3){
            neorv32_cpu_store_unsigned_word(add, fou);
            neorv32_uart0_printf("\n[%i] Sending 0x%x to address 0x%x \n",i,fou,add);
           }   
  } 
  neorv32_uart0_printf("\n-------- Read data from MULT(P) --------\n");
  // Read outputs from mult
    for (i=0; i<4; i++) {
        neorv32_uart0_printf("\n[%i] The read data is 0x%x \n",i,neorv32_cpu_load_unsigned_word(add));
      }
  // End
  neorv32_uart0_printf("\nProgram execution completed.\n");
  #endif

  return 0;
}

