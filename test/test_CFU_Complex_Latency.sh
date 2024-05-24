#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

apt update -qq

apt install -y git

cd ..

git clone --recursive https://github.com/stnolting/neorv32-setups

if [[ -z "${Design}" ]]; then
    mv rtl/mult/CFU/SIM/LATENCY/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
elif [[ $Design == 'mult' ]]; then
    mv rtl/mult/CFU/SIM/LATENCY/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
elif [[ $Design == 'multp_wfifos' ]]; then
    mv rtl/multp/CFU/SIM/LATENCY_MULTP_WFIFOS/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
elif [[ $Design == 'multp' ]]; then
    mv rtl/multp/CFU/SIM/LATENCY_MULTP/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
else
  echo "Error Design must be mult or multp_wfifos or multp"
  exit
fi

echo "Selected design is" $Design

mv rtl/mult/CFU/neorv32_cpu_cp_cfu.vhd neorv32-setups/neorv32/rtl/core

cd sim/CFU

echo "Start test"

./run.py -v --gtkwave-fmt vcd
mv vunit_out/wave/wave_complex_mults_cfu.vcd ../..

echo "Test completed"
