# Run implementation with vivado

## SLINK (AXI4-Stream)

Place in the root of the repository and run:

``` bash
git clone --recursive https://github.com/stnolting/neorv32-setups
cp rtl/mult/slink/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
cd impl/vivado/slink
source /tools/Xilinx/Vivado/2022.2/settings64.sh
# For mult_wfifos
DESIGN=mult vivado -mode batch -nojournal -nolog -source create_project.tcl
echo "Move bitstream to repository root"
mv work/arty-a7-35-test-setup.runs/impl_1/neorv32_mult_wfifos_slink.bit ../../..
# For multp_wfifos
DESIGN=multp-wfifos vivado -mode batch -nojournal -nolog -source create_project.tcl
echo "Move bitstream to repository root"
mv work/arty-a7-35-test-setup.runs/impl_1/neorv32_multp_wfifos_slink.bit ../../..
# For multp
DESIGN=multp vivado -mode batch -nojournal -nolog -source create_project.tcl
echo "Move bitstream to repository root"
mv work/arty-a7-35-test-setup.runs/impl_1/neorv32_multp_slink.bit ../../..
```

## EMEM (Wishbone)

Place in the root of the repository and run:

``` bash
git clone --recursive https://github.com/stnolting/neorv32-setups
cp rtl/mult/EMEM/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
cd impl/vivado/EMEM
source /tools/Xilinx/Vivado/2022.2/settings64.sh
# For mult_wfifos
DESIGN=mult vivado -mode batch -nojournal -nolog -source create_project.tcl
echo "Move bitstream to repository root"
 mv work/arty-a7-35-test-setup.runs/impl_1/neorv32_mult_wfifos_wishbone.bit ../../..
# For multp_wfifos
DESIGN=multp-wfifos vivado -mode batch -nojournal -nolog -source create_project.tcl
echo "Move bitstream to repository root"
mv work/arty-a7-35-test-setup.runs/impl_1/neorv32_multp_wfifos_wishbone.bit ../../..
```

## CFU

Place in the root of the repository and run:

```bash
git clone --recursive https://github.com/stnolting/neorv32-setups
# For mult_wfifos & multp_wfifos & multp
cp rtl/mult/CFU/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
cp rtl/mult/CFU/neorv32_cpu_cp_cfu.vhd neorv32-setups/neorv32/rtl/core
cd impl/vivado/CFU
source /tools/Xilinx/Vivado/2022.2/settings64.sh
vivado -mode batch -nojournal -nolog -source create_project.tcl
echo "Move bitstream to repository root"
mv work/arty-a7-35-test-setup.runs/impl_1/neorv32_mults_cfu.bit ../../..
```

## CFS

Place in the root of the repository and run:

```bash
git clone --recursive https://github.com/stnolting/neorv32-setups
# For mult_wfifos & multp_wfifos
cp rtl/mult/CFS/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
cp rtl/mult/CFS/neorv32_cfs.vhd neorv32-setups/neorv32/rtl/core
cd impl/vivado/CFS
source /tools/Xilinx/Vivado/2022.2/settings64.sh
# For mult_wfifos
DESIGN=mult vivado -mode batch -nojournal -nolog -source create_project.tcl
echo "Move bitstream to repository root"
mv work/arty-a7-35-test-setup.runs/impl_1/neorv32_mult_wfifos_cfs.bit ../../..
# For multp_wfifos
DESIGN=multp-wfifos vivado -mode batch -nojournal -nolog -source create_project.tcl
echo "Move bitstream to repository root"
mv work/arty-a7-35-test-setup.runs/impl_1/neorv32_multp_wfifos_cfs.bit ../../..
# For multp
cd ../../..
cp rtl/multp/CFS/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
cp rtl/multp/CFS/neorv32_cfs.vhd neorv32-setups/neorv32/rtl/core
cd impl/vivado/CFS
source /tools/Xilinx/Vivado/2022.2/settings64.sh
DESIGN=multp vivado -mode batch -nojournal -nolog -source create_project.tcl
echo "Move bitstream to repository root"
mv work/arty-a7-35-test-setup.runs/impl_1/neorv32_multp_cfs.bit ../../..
```

