# [Unike267(https://github.com/Unike267)] PRACTICES
---
---

- **University**: UPV-EHU.
- **Master**: Advanced Electronic Systems, [SIEAV(https://github.com/umarcor/SIEAV)].
- **Student**: Unai S.

---
---

### Abstract:

In this repo I'm going to upload all the code that I'm making in the practices. This practices are being carried out in the Digital Electronics Design Group (GDED) at the University of the Basque Country.

### STEPS:

- First: [NEORV32(https://github.com/stnolting/neorv32/tree/main)] is synthesized (executing the .tcl [file(https://github.com/stnolting/neorv32-setups/tree/main/vivado/arty-a7-test-setup)]and program the output bitstream with Vivado) on the Artix-7 FPGA (ARTYA7 Digilent board). 
    - Communication is established using uart.
    - Blinking led demo program is uploaded to CPU.
- Second: an external component is developed. 
    - The "acceler" component is designed.
    - Several test benchs are generated and its correct operation is verified.
- Third: the external component is routed with NEORV32 in different ways.
    - Usign stream link (AXI4_Stream).
