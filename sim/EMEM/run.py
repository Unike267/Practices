#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit
from shutil import copyfile
from os import makedirs, getenv
import re

# Function to take the csv from a folder with unknown path and put that csv into a folder with known path
def post_func(results):
    report = results.get_report()
    out_dir = Path(report.output_path) / "outcsv"
    try:
        makedirs(str(out_dir))
    except FileExistsError:
        pass
    for key, item in report.tests.items():
        if key == "lib.tb_mult_wfifos_wishbone_latency.test": # Copy the output csv of mult_wfifos to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir / "tb_mult_wfifos_wishbone_latency.csv"),
            )
        elif key == "lib.tb_mult_wfifos_wishbone_throughput.test": # Copy the output csv of mult_wfifos to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir / "tb_mult_wfifos_wishbone_throughput.csv"),
            )
        elif key == "lib.tb_multp_wfifos_wishbone_latency.test": # Copy the output csv of multp_wfifos to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir / "tb_multp_wfifos_wishbone_latency.csv"),
            )
        elif key == "lib.tb_multp_wfifos_wishbone_throughput.test": # Copy the output csv of multp_wfifos to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir / "tb_multp_wfifos_wishbone_throughput.csv"),
            )
        elif key == "lib.tb_multp_wishbone_latency.test": # Copy the output csv of multp_wfifos to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir / "tb_multp_wishbone_latency.csv"),
            )

vu = VUnit.from_argv()
vu.add_vhdl_builtins()
vu.add_verification_components()
vu.enable_location_preprocessing()

SRC_PATH_1 = Path(__file__).parent / ".." / ".." / "rtl" / "mult" 
SRC_PATH_2 = Path(__file__).parent / ".." / ".." / "rtl" / "multp"
SRC_PATH_3 = Path(__file__).parent  

vu.add_library("lib").add_source_files([
SRC_PATH_1/ "fifo.vhd",
SRC_PATH_1/ "mult.vhd",
SRC_PATH_1/ "mult_wfifos.vhd", 
SRC_PATH_1/ "mult_wfifos_wishbone.vhd", 
SRC_PATH_2/ "multp.vhd",
SRC_PATH_2/ "multp_wishbone.vhd",
SRC_PATH_2/ "multp_wfifos.vhd", 
SRC_PATH_2/ "multp_wfifos_wishbone.vhd", 
SRC_PATH_3/ "*.vhd",
])

vu.main(post_run=post_func)

