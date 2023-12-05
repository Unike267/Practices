#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

vu = VUnit.from_argv()
vu.add_vhdl_builtins()

SRC_PATH_1 = Path(__file__).parent / ".." / ".." / ".." / "rtl" / "mult_wrapper" / "src"
SRC_PATH_2 = Path(__file__).parent  

lib = vu.add_library("lib").add_source_files([SRC_PATH_1/ "*.vhd", SRC_PATH_2/ "*.vhd"])

vu.main()

