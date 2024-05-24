#include <neorv32.h>
#include <string.h>

#define BAUD_RATE 19200

// This defines is used to bypass the intermediate print functions between cfu functions (for latency measurements)
// Comment these defines to perform a normal execution
// Uncomment lat_mult to perform latency measurements with mult_wfifos
// Uncomment lat_multpw to perform latency measurements with multp_wfifos
// Uncomment lat_multp to perform latency measurements with multp
//#define lat_mult
//#define lat_multpw
//#define lat_multp

int main() {
    
  // Capture all exceptions and give debug info via UART0
  neorv32_rte_setup();

  // Setup UART at default baud rate, no interrupts
  neorv32_uart0_setup(BAUD_RATE, 0);

  // Check if UART0 unit is implemented at all
  if (neorv32_uart0_available() == 0) {
    return -1; // abort if not implemented
  }

  // check if the CFU is implemented at all (the CFU is wrapped in the core's "Zxcfu" ISA extension)
  if (neorv32_cpu_cfu_available() == 0) {
    neorv32_uart0_printf("ERROR! CFU ('Zxcfu' ISA extensions) not implemented!\n");
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

  #ifdef lat_mult
  // Intro
  neorv32_uart0_printf("\n CFU-mw \n\n");
 // Perform 4 multiplication through custom instruction (funct3=000)
    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cfu_r3_instr(0b1111111, 0b000, fir, 0); 
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cfu_r3_instr(0b1111111, 0b000, sec, 0); 
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cfu_r3_instr(0b1111111, 0b000, thi, 0); 
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cfu_r3_instr(0b1111111, 0b000, fou, 0); 
    neorv32_cpu_csr_read(CSR_MCYCLE); 
  // End
  neorv32_uart0_printf("\nEND-mw\n");
  #elif defined lat_multpw
  // Intro
  neorv32_uart0_printf("\n CFU-mpw \n\n");
 // Perform 4 multiplication through custom instruction (funct3=001)
    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cfu_r3_instr(0b1111111, 0b001, fir, 0); 
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cfu_r3_instr(0b1111111, 0b001, sec, 0); 
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cfu_r3_instr(0b1111111, 0b001, thi, 0); 
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cfu_r3_instr(0b1111111, 0b001, fou, 0); 
    neorv32_cpu_csr_read(CSR_MCYCLE); 
  // End
  neorv32_uart0_printf("\nEND-mpw\n");
  #elif defined lat_multp
  // Intro
  neorv32_uart0_printf("\n CFU-mp \n\n");
 // Perform 4 multiplication through custom instruction (funct3=010)
    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cfu_r3_instr(0b1111111, 0b010, fir, 0); 
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cfu_r3_instr(0b1111111, 0b010, sec, 0); 
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cfu_r3_instr(0b1111111, 0b010, thi, 0); 
    neorv32_cpu_csr_read(CSR_MCYCLE); 

    neorv32_cpu_csr_write(CSR_MCYCLE, 0);
    neorv32_cfu_r3_instr(0b1111111, 0b010, fou, 0); 
    neorv32_cpu_csr_read(CSR_MCYCLE); 
  // End
  neorv32_uart0_printf("\nEND-mp\n");
  #else
  int i;
  // Intro
  neorv32_uart0_printf("\n<<< MULT(P) via CFU demo program >>>\n\n");
  neorv32_uart0_printf("\n--- CFU R3-Type: Multiplier Instruction ---\n");
  neorv32_uart0_printf("\n rs1= 0xIN1-IN2, rs2= DC, rd = IN1 x IN2 \n\n");
  // Write 4 inputs to mult and read the outputs from mult one by one in mult_wfifos
    neorv32_uart0_printf("\n Mult_wfifos: \n\n");
    for (i=0; i<4 ; i++) {
    if(i==0){
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b000, [rs1]=0x%x, [rs2]=0x%x ) = ", i, fir, 0);
            neorv32_uart0_printf("0x%x\n",neorv32_cfu_r3_instr(0b1111111, 0b000, fir, 0)); 
           } 
    if(i==1){
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b000, [rs1]=0x%x, [rs2]=0x%x ) = ", i, sec, 0);
            neorv32_uart0_printf("0x%x\n",neorv32_cfu_r3_instr(0b1111111, 0b000, sec, 0));  
           }   
    if(i==2){
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b000, [rs1]=0x%x, [rs2]=0x%x ) = ", i, thi, 0);
            neorv32_uart0_printf("0x%x\n",neorv32_cfu_r3_instr(0b1111111, 0b000, thi, 0));  
           }   
    if(i==3){
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b000, [rs1]=0x%x, [rs2]=0x%x ) = ", i, fou, 0);
            neorv32_uart0_printf("0x%x\n",neorv32_cfu_r3_instr(0b1111111, 0b000, fou, 0)); 
           }   
    } 
  // Write 4 inputs to mult and read the outputs from mult one by one in multp_wfifos
    neorv32_uart0_printf("\n Multp_wfifos: \n\n");
    for (i=0; i<4 ; i++) {
    if(i==0){
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b001, [rs1]=0x%x, [rs2]=0x%x ) = ", i, fir, 0);
            neorv32_uart0_printf("0x%x\n",neorv32_cfu_r3_instr(0b1111111, 0b001, fir, 0)); 
           } 
    if(i==1){
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b001, [rs1]=0x%x, [rs2]=0x%x ) = ", i, sec, 0);
            neorv32_uart0_printf("0x%x\n",neorv32_cfu_r3_instr(0b1111111, 0b001, sec, 0));  
           }   
    if(i==2){
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b001, [rs1]=0x%x, [rs2]=0x%x ) = ", i, thi, 0);
            neorv32_uart0_printf("0x%x\n",neorv32_cfu_r3_instr(0b1111111, 0b001, thi, 0));  
           }   
    if(i==3){
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b001, [rs1]=0x%x, [rs2]=0x%x ) = ", i, fou, 0);
            neorv32_uart0_printf("0x%x\n",neorv32_cfu_r3_instr(0b1111111, 0b001, fou, 0)); 
           }   
    } 
  // Write 4 inputs to mult and read the outputs from mult one by one in multp
    neorv32_uart0_printf("\n Multp: \n\n");
    for (i=0; i<4 ; i++) {
    if(i==0){
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b010, [rs1]=0x%x, [rs2]=0x%x ) = ", i, fir, 0);
            neorv32_uart0_printf("0x%x\n",neorv32_cfu_r3_instr(0b1111111, 0b010, fir, 0)); 
           } 
    if(i==1){
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b010, [rs1]=0x%x, [rs2]=0x%x ) = ", i, sec, 0);
            neorv32_uart0_printf("0x%x\n",neorv32_cfu_r3_instr(0b1111111, 0b010, sec, 0));  
           }   
    if(i==2){
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b010, [rs1]=0x%x, [rs2]=0x%x ) = ", i, thi, 0);
            neorv32_uart0_printf("0x%x\n",neorv32_cfu_r3_instr(0b1111111, 0b010, thi, 0));  
           }   
    if(i==3){
            neorv32_uart0_printf("%u: neorv32_cfu_r3_instr( funct7=0b1111111, funct3=0b010, [rs1]=0x%x, [rs2]=0x%x ) = ", i, fou, 0);
            neorv32_uart0_printf("0x%x\n",neorv32_cfu_r3_instr(0b1111111, 0b010, fou, 0)); 
           }   
    } 
  // End
  neorv32_uart0_printf("\nCFU demo program completed.\n");
  #endif

  return 0;
}

