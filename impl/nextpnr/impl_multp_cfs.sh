#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

if [[ -z "${Board}" ]]; then
  Arty='35t'
elif [[ $Board == '35t' ]]; then
  Arty='35t'
elif [[ $Board == '100t' ]]; then
  Arty='100t'
else
  echo "Error Board must be 35t or 100t"
  exit
fi
echo "Selected board is" $Arty

cd ../..

mv rtl/multp/CFS/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core
mv rtl/multp/CFS/neorv32_cfs.vhd neorv32-setups/neorv32/rtl/core

mkdir -p build

echo "Analyze NEORV32 CPU + MULT(P) via CFS"

ghdl -i --std=08 --workdir=build --work=neorv32  ./neorv32-setups/neorv32/rtl/core/*.vhd
ghdl -i --std=08 --workdir=build --work=neorv32  ./neorv32-setups/neorv32/rtl/core/mem/neorv32_dmem.default.vhd
ghdl -i --std=08 --workdir=build --work=neorv32  ./neorv32-setups/neorv32/rtl/core/mem/neorv32_imem.default.vhd
ghdl -i --std=08 --workdir=build --work=neorv32 ./rtl/multp/*.vhd
ghdl -i --std=08 --workdir=build --work=neorv32 ./rtl/multp/CFS/neorv32_multp_cfs.vhd
ghdl -m --std=08 --workdir=build --work=neorv32 neorv32_multp_cfs

echo "Synthesis with yosys and ghdl as module"

yosys -m ghdl -p 'ghdl --std=08 --workdir=build --work=neorv32 neorv32_multp_cfs; synth_xilinx -nodsp -nolutram -flatten -abc9 -arch xc7 -top neorv32_multp_cfs; write_json neorv32_multp_cfs.json' 

if [[ $Arty == '35t' ]]; then
  echo "Place and route"
  nextpnr-xilinx --chipdb /usr/local/share/nextpnr/xilinx-chipdb/xc7a35t.bin --xdc impl/nextpnr/arty.xdc --json neorv32_multp_cfs.json --write neorv32_multp_cfs_routed.json --fasm neorv32_multp_cfs.fasm
  echo "Generate bitstream"
  ../../prjxray/utils/fasm2frames.py --part xc7a35tcsg324-1 --db-root /usr/local/share/nextpnr/prjxray-db/artix7 neorv32_multp_cfs.fasm > neorv32_multp_cfs.frames
  ../../prjxray/build/tools/xc7frames2bit --part_file /usr/local/share/nextpnr/prjxray-db/artix7/xc7a35tcsg324-1/part.yaml --part_name xc7a35tcsg324-1 --frm_file neorv32_multp_cfs.frames --output_file neorv32_multp_cfs_35t.bit
elif [[ $Arty == '100t' ]]; then
  echo "Place and route"
  nextpnr-xilinx --chipdb /usr/local/share/nextpnr/xilinx-chipdb/xc7a100t.bin --xdc impl/nextpnr/arty.xdc --json neorv32_multp_cfs.json --write neorv32_multp_cfs_routed.json --fasm neorv32_multp_cfs.fasm
  echo "Generate bitstream"
  ../../prjxray/utils/fasm2frames.py --part xc7a100tcsg324-1 --db-root /usr/local/share/nextpnr/prjxray-db/artix7 neorv32_multp_cfs.fasm > neorv32_multp_cfs.frames
  ../../prjxray/build/tools/xc7frames2bit --part_file /usr/local/share/nextpnr/prjxray-db/artix7/xc7a100tcsg324-1/part.yaml --part_name xc7a100tcsg324-1 --frm_file neorv32_multp_cfs.frames --output_file neorv32_multp_cfs_100t.bit
fi

echo "Implementation completed"
