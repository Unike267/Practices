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
        if key == "lib.tb_mult_wfifos_axis_latency.test": # Copy the output csv of mult_wfifos to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir / "tb_mult_wfifos_axis_latency.csv"),
            )
        if key == "lib.tb_mult_wfifos_axis_throughput.test": # Copy the output csv of mult_wfifos to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir / "tb_mult_wfifos_axis_throughput.csv"),
            )
        elif key == "lib.tb_multp_wfifos_axis_latency.test": # Copy the output csv of multp_wfifos to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir / "tb_multp_wfifos_axis_latency.csv"),
            )
        elif key == "lib.tb_multp_wfifos_axis_throughput.test": # Copy the output csv of multp_wfifos to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir / "tb_multp_wfifos_axis_throughput.csv"),
            )
        elif key == "lib.tb_multp_axis_latency.test": # Copy the output csv of multp to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir / "tb_multp_axis_latency.csv"),
            )
        elif key == "lib.tb_multp_axis_throughput.test": # Copy the output csv of multp to known path
            copyfile(
                str(Path(item.path) / "log.csv"),
                str(out_dir / "tb_multp_axis_throughput.csv"),
            )

vu = VUnit.from_argv()
vu.add_vhdl_builtins()
vu.add_verification_components()
vu.enable_location_preprocessing()

ROOT = Path(__file__).parent

vu.add_library("lib").add_source_files([
    ROOT / "../../rtl/mult/*.vhd",
    ROOT / "../../rtl/multp/*.vhd",
    ROOT / "*.vhd",
])

vu.main(post_run=post_func)
