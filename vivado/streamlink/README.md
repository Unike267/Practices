# Connect *acceler* with NEORV32 using Stream Link Interface (AXI4-Stream)

# Context:

When we have designed and tested the *acceler* component it's time to connect with the [NEORV32](https://github.com/stnolting/neorv32) CPU. There are many ways for add a module to a processor.

- External Bus Interface.
- Custom Function Subsystem.
- Custom Function Unit.
- Stream Link Interface.

In this case the connection via Stream Link is chosen.

### Process:

The following diagram shows the implementation: 

![Plano](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/PLANO_SLINK.png)

Steps:

- A layer called *acceler_axi_buffer* is made. In that layer the AXI4-Stream necesary signals are generated. Also, the necesary logic for *acceler* write and read signals are made.
- The signals of the *acceler-axi-buffer* with the Stream Link signals are maped. For this, in the top of the design *neorv32_test_top* the *acceler_axi_buffer* is added as a component and it's routed with *neorv32_top* SLINK signals.
    - Note: the neorv32 use **ulogic signals** ergo it is necesary to transform them. In the case of *std_logic_vector* signals *to_std_ulogic_vector()* function is aplicated directly. In the case of *std_ulogic_vector* signals *to_std_logic_vector()* function is aplicated directly. But in the case of *std_logic* and *std_ulogic* signals it isn't necessary to transform them **because a directly assignment doesn't generate a conflict.**
    - Note 2: when the *neorv32_top* is imported, in the *generic map* must be added the constants of the SLINK module, for active the synthesis of the module and decide the depth of de *RX* and *TX* fifos. Also, in the *port map* must be added the signals of the SLINK interface.
- A *.c* program is made. This program will write and read datas through SLINK interface and it will show them via UART.
    - Note: ~~In the program *neorv32_slink_available()* function is used. That function use the [neorv32_slink.c](https://github.com/stnolting/neorv32/blob/main/sw/lib/source/neorv32_slink.c) library. **The point is that the library has a bug**, specifically on the 51 line it's written *if (NEORV32_SYSINFO->SOC & (1 << SYSINFO_SOC_IO_SDI))* when the correct form is *if (NEORV32_SYSINFO->SOC & (1 << SYSINFO_SOC_IO_SLINK))*.~~ **The bug is solved in the [pull](https://github.com/stnolting/neorv32/pull/717).**
- When the bug is fixed, the program is compiled and the *neorv32_application_image* is overwritten. This will make that when the design is synthetized our program will be loaded in the instruction memory *neorv32_imem.default*, check [#6](https://gitlab.com/EHU-GDED/NEORV32/-/issues/6).
- With the file *create_project.tcl* the complete design is synthesized. Then communication is established via UART and the results are displayed.

### Results:

The following results are obtained with CuteCom terminal:

![Result](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/CUTECOM.png)


    

