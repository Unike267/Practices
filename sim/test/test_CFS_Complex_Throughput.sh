#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

cd ../..

mv rtl/mult/CFS/sim/THROUGHPUT/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
mv rtl/mult/CFS/neorv32_cfs.vhd neorv32-setups/neorv32/rtl/core

cd sim/CFS-THR

echo "Start test"

./run.py -v --gtkwave-fmt vcd
mv vunit_out/wave/wave_complex_mult_wfifos_cfs.vcd ../..
mv vunit_out/wave/wave_complex_multp_wfifos_cfs.vcd ../..

echo "Test completed"
