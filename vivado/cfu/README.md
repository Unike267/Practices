# Connect *mult_wrapper* with NEORV32 using CFU

# Context:

When we have designed and tested the *mult_wrapper* component it's time to connect with the [NEORV32](https://github.com/stnolting/neorv32) CPU. There are many ways for add a module to a processor.

- External Bus Interface.
- Custom Function Subsystem.
- Custom Function Unit.
- Stream Link Interface.

In this case the connection via CFU (Custom Function Unit) is chosen.

Note: It isn't added the *mult_wrapper* component complete. Only multiplier (without fifos).

### Process:

The following diagram shows the implementation: 

![Plano](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/cfu_plano.png)

Steps:

- Custom instruction is determined. 
    - In this case R3-type: *funct7* = 1111111; *funct3* = 000.
- *Mult* logic is added in *neorv32_cpu_cp_cfu*.
- *Mult* signals are routed with the control signals.
    - Note: *std_logic_vector* signals are adapted with *std_ulogic_vector* signals and vice versa, check [#7](https://gitlab.com/EHU-GDED/NEORV32/-/issues/7).
- The mult logic is only associated to R3-type custom instruction and when *funct3* is 000.
    - This is implemented in output select case.
- A .c program is made. This program will call to our custom instruction and it will return the multiplication result (inside the rd register).
- The program is compiled and the *neorv32_application_image* is overwritten. This will make that when the design is synthesized our program will be loaded in the instruction memory *neorv32_imem.default*, check [#6](https://gitlab.com/EHU-GDED/NEORV32/-/issues/6).
- With the file create_project.tcl the complete design is synthesized. Then communication is established via UART and the results are displayed.

### Results:

The following results are obtained with CuteCom terminal:

![Result](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/cfu_result.png)

    
