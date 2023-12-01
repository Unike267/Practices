# Connect *mult_wrapper* with NEORV32 using CFS

# Context:

When we have designed and tested the *mult_wrapper* component it's time to connect with the [NEORV32](https://github.com/stnolting/neorv32) CPU. There are many ways for add a module to a processor.

- External Bus Interface.
- Custom Function Subsystem.
- Custom Function Unit.
- Stream Link Interface.

In this case the connection via CFS (Custom Functions Subsystem) is chosen.

### Process:

The following diagram shows the implementation: 

![Plano](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/cfs_plano.png)

Steps:

- The *neorv32_cfs* file is modified to associate the memory-mapped register 0 to *cfs_out_o(31 downto 0) and cfs_in_i* and the memory-mapped register 1 to *cfs_out_o(33 downto 32)*. In this way, when the instruction *NEORV32_CFS->REG[0] = value* happens the *value* flows through the *bus_req_i.data*, as well as the address associated to the *CFS REG[0]* (0xffffeb00) flows through the *bus_req_i.addr*. In the *neorv32_cfs* file it's consulted *(7 downto 2)* bits of the address, in this case "000000" and the *value* it is written in *cfs_mult_wrapper_data*. On the other hand, when the instruction *NEORV32_CFS->REG[1] = value* happens the *value* flows through the *bus_req_i.data*, as well as the address associated to the *CFS REG[1]* (0xffffeb04) flows through the *bus_req_i.addr*. In the *neorv32_cfs* file it's consulted *(7 downto 2)* bits of the address in this case "000001" and the *value* it is written in *cfs_mult_wrapper_control*. Thus, there are 64 registers associated to Custom Functions Subsystem, from "000000" to "111111" or in other words from 0xffffeb00 to 0xffffebfc (with 2 bits gap). Finally, when the instruction *neorv32_uart0_printf("%x", NEORV32_CFS->REG[0])* happens the value of *cfs_mult_wrapper_res* associated to the *REG[0]* address flows through the *bus_rsp_o.data* and it is printed via UART.
- In the *neorv32_test_top_cfs* file the *neorv32_cfs* input/output signals are routed: *cfs_out_o(31 downto 0)* to *mult_wrapper_in*, *cfs_out_o(32)* to *Make_mult_wrapper_write*, *cfs_out_o(33)* to *Make_mult_wrapper_read* and *cfs_in_i* to *mult_wrapper_out*.
    - Note: *std_logic_vector* signals are adapted with *std_ulogic_vector* signals and vice versa, check [#1](https://github.com/Unike267/Practices/issues/1).
- A .c program is made. This program will write the inputs to the mult_wrapper, it will set the control signals to the mult_wrapper and finally it will read the outputs from the mult_wrapper and it will print the results via UART.
- The program is compiled and the *neorv32_application_image* is overwritten. This will make that when the design is synthesized our program will be loaded in the instruction memory *neorv32_imem.default*, check [#2](https://github.com/Unike267/Practices/issues/2).
- With the file create_project.tcl the complete design is synthesized. Then communication is established via UART and the results are displayed.

### Results:

The following results are obtained with CuteCom terminal:

![Result](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/cfs_result.png)

    
