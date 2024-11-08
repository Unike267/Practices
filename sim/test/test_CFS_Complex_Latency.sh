#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

cd ../..

if [[ -z "${Fifos}" ]]; then
    echo "Start test"
    mv rtl/mult/CFS/sim/LATENCY/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
    mv rtl/mult/CFS/neorv32_cfs.vhd neorv32-setups/neorv32/rtl/core
    cd sim/CFS-LAT
    ./run.py -v --gtkwave-fmt vcd 'neorv32.tb_complex_mult_wfifos_cfs.test' 'neorv32.tb_complex_multp_wfifos_cfs.test'
    mv vunit_out/wave/wave_complex_mult_wfifos_cfs.vcd ../..
    mv vunit_out/wave/wave_complex_multp_wfifos_cfs.vcd ../..
    echo "Test completed"
elif [[ $Fifos == 'yes' ]]; then
    echo "Start test"
    mv rtl/mult/CFS/sim/LATENCY/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
    mv rtl/mult/CFS/neorv32_cfs.vhd neorv32-setups/neorv32/rtl/core
    cd sim/CFS-LAT
    ./run.py -v --gtkwave-fmt vcd 'neorv32.tb_complex_mult_wfifos_cfs.test' 'neorv32.tb_complex_multp_wfifos_cfs.test'
    mv vunit_out/wave/wave_complex_mult_wfifos_cfs.vcd ../..
    mv vunit_out/wave/wave_complex_multp_wfifos_cfs.vcd ../..
    echo "Test completed"
elif [[ $Fifos == 'no' ]]; then
    echo "Start test"
    mv rtl/multp/CFS/sim/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
    mv rtl/multp/CFS/neorv32_cfs.vhd neorv32-setups/neorv32/rtl/core
    cd sim/CFS-LAT
    ./run.py -v --gtkwave-fmt vcd 'neorv32.tb_complex_multp_cfs.test'
    mv vunit_out/wave/wave_complex_multp_cfs.vcd ../..
    echo "Test completed"
else
  echo "Error Fifos must be yes or no"
  exit
fi
