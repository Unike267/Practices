# [Unike267](https://github.com/Unike267) PRACTICES

- **University**: UPV-EHU.
- **Master**: Advanced Electronic Systems, [SIEAV](https://github.com/umarcor/SIEAV).
- **Group**: GDED.
- **Student**: Unai S.

---

### Abstract:

In this repo I'm going to upload all the code that I'm making in the practices. This practices are being carried out in the Digital Electronics Design Group (GDED) at the University of the Basque Country.

### STEPS:

- First: [NEORV32](https://github.com/stnolting/neorv32/tree/main) is synthesized (executing the .tcl [file](https://github.com/stnolting/neorv32-setups/tree/main/vivado/arty-a7-test-setup) and program the output bitstream with Vivado) on the Artix-7 FPGA (ARTYA7 Digilent board). 
    - Communication is established using UART.
    - Blinking led demo program is loaded to CPU.
- Second: an external component is developed. 
    - The *mult_wrapper* component is designed.
    - Several testbenches are generated and its correct operation is verified.
- Third: the external component is routed with NEORV32 in different ways.
    - Usign [stream link](https://github.com/Unike267/Practices/tree/main/doc/streamlink) (AXI4-Stream).
    - Using [CFU](https://github.com/Unike267/Practices/tree/main/doc/cfu).
    - Using [CFS](https://github.com/Unike267/Practices/tree/main/doc/cfs).

### Mult_wrapper:

The following diagram shows the design of *mult_wrapper* component: 

![Plano](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/mult_wrapper.png)

### Results:

Four multiplications are done to check that the routed design works.

**Stream Link:**

![Result](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/slink_result.png)

**CFU:**

![Result](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/cfu_result.png)

**CFS:**

![Result](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/cfs_result.png)

