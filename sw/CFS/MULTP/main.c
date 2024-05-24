#include <neorv32.h>

#define BAUD_RATE 19200

// This defines is used to bypass the intermediate print functions between CFS functions (for latency measurements)
// Comment these defines to perform a normal execution
// Uncomment latency to perform latency measurements
//#define latency

int main() {

  // Capture all exceptions and give debug info via UART0
  neorv32_rte_setup();

  // Setup UART at default baud rate, no interrupts
  neorv32_uart0_setup(BAUD_RATE, 0);

  // Check if UART0 unit is implemented at all
  if (neorv32_uart0_available() == 0) {
    return -1; // abort if not implemented
  }

  // check if CFS is implemented at all
  if (neorv32_cfs_available() == 0) {
    neorv32_uart0_printf("Error! No CFS synthesized!\n");
    return 1;
  }

  // check if the CPU base counters are implemented
  if ((neorv32_cpu_csr_read(CSR_MXISA) & (1 << CSR_MXISA_ZICNTR)) == 0) {
    neorv32_uart0_printf("ERROR! Base counters ('Zicntr' ISA extensions) not implemented!\n");
    return -1;
  }

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
  neorv32_uart0_printf("\n CFS-lat \n\n");
  // Write 4 inputs to mult and read the outputs from mult one by one
    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    NEORV32_CFS->REG[0] = fir; // Write fir to CFS memory-mapped register 0
    NEORV32_CFS->REG[0]; // Read mult result from CFS memory-mapped register 0  
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    NEORV32_CFS->REG[0] = sec; // Write sec to CFS memory-mapped register 0
    NEORV32_CFS->REG[0]; // Read mult result from CFS memory-mapped register 0  
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    NEORV32_CFS->REG[0] = thi; // Write thi to CFS memory-mapped register 0
    NEORV32_CFS->REG[0]; // Read mult result from CFS memory-mapped register 0  
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    NEORV32_CFS->REG[0] = fou; // Write fou to CFS memory-mapped register 0
    NEORV32_CFS->REG[0]; // Read mult result from CFS memory-mapped register 0  
    neorv32_cpu_csr_read(CSR_MCYCLE); 

  // End
  neorv32_uart0_printf("\nEND-lat\n");
  #else
  // Intro
  int i;
  neorv32_uart0_printf("\n<<< MULT(P) via CFS demo program >>>\n\n");
  neorv32_uart0_printf("CFS memory-mapped registers:\n"
                       " * NEORV32_CFS->REG[0] (r/w): input/output data register.\n\n");
  neorv32_uart0_printf("-------- Write data to MULT(P) --------\n");
  // Write 4 inputs to mult and read the outputs from mult one by one
    for (i=0; i<4 ; i++) {
    if(i==0){
            NEORV32_CFS->REG[0] = fir; // Write fir to CFS memory-mapped register 0
            neorv32_uart0_printf("%i: IN = 0x%x, OUT = 0x%x\n", i, fir, NEORV32_CFS->REG[0]);  // Read mult result from CFS memory-mapped register 0  
           } 
    if(i==1){
            NEORV32_CFS->REG[0] = sec; // Write sec to CFS memory-mapped register 0
            neorv32_uart0_printf("%i: IN = 0x%x, OUT = 0x%x\n", i, sec, NEORV32_CFS->REG[0]);  // Read mult result from CFS memory-mapped register 0  
           }   
    if(i==2){
            NEORV32_CFS->REG[0] = thi; // Write thi to CFS memory-mapped register 0
            neorv32_uart0_printf("%i: IN = 0x%x, OUT = 0x%x\n", i, thi, NEORV32_CFS->REG[0]);  // Read mult result from CFS memory-mapped register 0  
           }   
    if(i==3){
            NEORV32_CFS->REG[0] = fou; // Write fou to CFS memory-mapped register 0
            neorv32_uart0_printf("%i: IN = 0x%x, OUT = 0x%x\n", i, fou, NEORV32_CFS->REG[0]);  // Read mult result from CFS memory-mapped register 0  
           }   
    } 
  // End
  neorv32_uart0_printf("\nCFS demo program completed.\n");
  #endif

  return 0;
}
