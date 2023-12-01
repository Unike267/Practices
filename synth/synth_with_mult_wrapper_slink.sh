#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

apt update -qq

apt install -y git

cd ..

git clone --recursive https://github.com/stnolting/neorv32-setups

echo "Copy the app_image with compiled program"

cp vivado/streamlink/neorv32_application_image.vhd neorv32-setups/neorv32/rtl/core

cd synth

mkdir -p build

echo "Analyze all of design. NEORV32 CPU + Mult_wrapper via Stream Link"

ghdl -i --workdir=build --work=neorv32  ../neorv32-setups/neorv32/rtl/core/*.vhd
ghdl -i --workdir=build --work=neorv32  ../neorv32-setups/neorv32/rtl/core/mem/neorv32_dmem.default.vhd
ghdl -i --workdir=build --work=neorv32  ../neorv32-setups/neorv32/rtl/core/mem/neorv32_imem.default.vhd
ghdl -i --workdir=build --work=neorv32 ../mult_wrapper/src/*.vhd
ghdl -i --workdir=build --work=neorv32 ../vivado/streamlink/neorv32_test_top_slink.vhd
ghdl -m --workdir=build --work=neorv32 neorv32_test_top_slink

echo "Merge all design into a VHDl file"

ghdl --synth --workdir=build --work=neorv32 neorv32_test_top_slink > all_design_slink.vhd

echo "Synthesis with yosys and ghdl as module"

yosys -m ghdl -p 'ghdl --workdir=build --work=neorv32 neorv32_test_top_slink; synth_xilinx -flatten -abc9 -arch xc7 -top neorv32_test_top_slink; write_json neorv32_test_top_slink.json'
