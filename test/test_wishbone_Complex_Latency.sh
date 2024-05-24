#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

apt update -qq

apt install -y git

cd ..

git clone --recursive https://github.com/stnolting/neorv32-setups

mv rtl/mult/EMEM/sim/LATENCY/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core

cd sim/EMEM/complex-lat

echo "Start test"

./run.py -v --gtkwave-fmt vcd
mv vunit_out/wave/wave_complex_mult_wfifos_wishbone.vcd ../../..
mv vunit_out/wave/wave_complex_multp_wfifos_wishbone.vcd ../../..
mv vunit_out/wave/wave_complex_multp_wishbone.vcd ../../..

echo "Test completed"
