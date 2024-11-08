#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

cd ../..

mv rtl/mult/slink/sim/LATENCY/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core

cd sim/slink/complex-lat

echo "Start test"

./run.py -v --gtkwave-fmt vcd
mv vunit_out/wave/wave_complex_mult_wfifos_slink.vcd ../../..
mv vunit_out/wave/wave_complex_multp_wfifos_slink.vcd ../../..
mv vunit_out/wave/wave_complex_multp_slink.vcd ../../..

echo "Test completed"
