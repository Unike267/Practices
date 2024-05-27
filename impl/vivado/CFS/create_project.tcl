# Select board

if {[info exists ::env(TARGET_BOARD) ]} {
  set board_suffix $::env(TARGET_BOARD)
    if {$board_suffix == "100t"} {
      set board "arty-a7-100"
    } elseif {$board_suffix == "35t"} {
      set board "arty-a7-35"
    } else {
      error "Specify a valid value for TARGET_BOARD. 100t or 35t"
    }
} else {
  set board "arty-a7-35"
}

puts "The selected target board is: ${board}t"

# Variables for paths
set root "./../../../"
set core $root/neorv32-setups/neorv32/rtl/core
set mult $root/rtl/mult
set multp $root/rtl/multp
set sim $root/neorv32-setups/neorv32/sim

# Create and clear output directory
set outputdir work
file mkdir $outputdir

set files [glob -nocomplain "$outputdir/*"]
if {[llength $files] != 0} {
  puts "deleting contents of $outputdir"
  file delete -force {*}[glob -directory $outputdir *]; # clear folder contents
} else {
  puts "$outputdir is empty"
}

switch $board {
  "arty-a7-35" {
    set a7part "xc7a35ticsg324-1L"
    set a7prj ${board}-test-setup
  }
  "arty-a7-100" {
    set a7part "xc7a100tcsg324-1"
    set a7prj ${board}-test-setup
  }
}

# Create project
create_project -part $a7part $a7prj $outputdir

set_property board_part digilentinc.com:${board}:part0:1.0 [current_project]
set_property target_language VHDL [current_project]

# Define filesets

## Core: NEORV32
add_files [glob $mult/*.vhd] [glob $multp/*.vhd] [glob $core/*.vhd] $core/mem/neorv32_dmem.default.vhd $core/mem/neorv32_imem.default.vhd
set_property library neorv32 [get_files [glob $core/*.vhd]]
set_property library neorv32 [get_files [glob $core/mem/neorv32_*mem.default.vhd]]

## Design: processor subsystem template, and (optionally) BoardTop and/or other additional sources (Mult_wfifos via CFS is included)
if {[info exists ::env(DESIGN) ]} {
  set design $::env(DESIGN)
    if {$design == "mult"} {
      set fileset_design $mult/CFS/neorv32_mult_wfifos_cfs.vhd
    } elseif {$design == "multp-wfifos"} {
      set fileset_design $multp/CFS/neorv32_multp_wfifos_cfs.vhd
    } elseif {$design == "multp"} {
      set fileset_design $multp/CFS/neorv32_multp_cfs.vhd
    } else {
      error "Specify a valid value for DESIGN \[$design\]: 'mult', 'multp-wfifos', 'multp'"
    }
} else {
  error "Specify a value for DESIGN: 'mult', 'multp-wfifos', 'multp'"
}

set_property file_type {VHDL 2008} [get_files -filter {FILE_TYPE == VHDL}]

## Constraints
set fileset_constraints [glob ./*.xdc]

## Simulation-only sources
set fileset_sim [list $sim/simple/neorv32_tb.simple.vhd $sim/simple/uart_rx.simple.vhd]

# Add source files

## Design
add_files $fileset_design

## Constraints
add_files -fileset constrs_1 $fileset_constraints

## Simulation-only
add_files -fileset sim_1 $fileset_sim

# Run synthesis, implementation and bitstream generation
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
