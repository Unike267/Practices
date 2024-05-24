#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit
from shutil import copyfile
from os import makedirs, getenv
import re

# Function to take the csv from a folder with unknown path and put that csv into a folder with known path
def post_func(results):
    report = results.get_report()
    out_dir_csv = Path(report.output_path) / "outcsv"
    out_dir_wave = Path(report.output_path) / "wave"
    list = [out_dir_csv,out_dir_wave]

    for items in list:        
        try:
            makedirs(str(items))
        except FileExistsError:
            pass

    for key, item in report.tests.items():
        if key == "neorv32.tb_complex_mult_wfifos_wishbone.test": # Copy the output csv and the wave in vcd of tb_complex_mult_wfifos to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_complex_mult_wfifos_wishbone.csv"),
            )
            copyfile(
                str(Path(item.path) / "ghdl" / "wave.vcd"),
                str(out_dir_wave / "wave_complex_mult_wfifos_wishbone.vcd"),
            )
        elif key == "neorv32.tb_complex_multp_wfifos_wishbone.test": # Copy the output csv and the wave in vcd of tb_complex_multp_wfifos to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_complex_multp_wfifos_wishbone.csv"),
            )
            copyfile(
                str(Path(item.path) / "ghdl" / "wave.vcd"),
                str(out_dir_wave / "wave_complex_multp_wfifos_wishbone.vcd"),
            )
        elif key == "neorv32.tb_complex_multp_wishbone.test": # Copy the output csv and the wave in vcd of tb_complex_multp_wfifos to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir_csv / "tb_complex_multp_wishbone.csv"),
            )
            copyfile(
                str(Path(item.path) / "ghdl" / "wave.vcd"),
                str(out_dir_wave / "wave_complex_multp_wishbone.vcd"),
            )
vu = VUnit.from_argv()
vu.add_vhdl_builtins()
vu.enable_location_preprocessing()

ROOT = Path(__file__).parent

NEORV32 = vu.add_library("neorv32")
NEORV32.add_source_files([
    ROOT / "../../../rtl/mult/*.vhd",
    ROOT / "../../../rtl/multp/*.vhd",
    ROOT / "../../../rtl/mult/EMEM/neorv32_mult_wfifos_wishbone.vhd",
    ROOT / "../../../rtl/multp/EMEM/neorv32_multp_wfifos_wishbone.vhd",
    ROOT / "../../../rtl/multp/EMEM/neorv32_multp_wishbone.vhd",
    ROOT / "*.vhd",
    ROOT / "../../../neorv32-setups/neorv32/rtl/core/*.vhd", # Make sure that the app_image is for latency or throughput measurements  
    ROOT / "../../../neorv32-setups/neorv32/rtl/core/mem/*.vhd"
])

vu.main(post_run=post_func)
