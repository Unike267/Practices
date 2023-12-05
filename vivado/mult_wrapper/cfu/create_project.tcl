set board "arty-a7-35"

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
}

# Create project
create_project -part $a7part $a7prj $outputdir

set_property board_part digilentinc.com:${board}:part0:1.0 [current_project]
set_property target_language VHDL [current_project]

# Define filesets

## Core: NEORV32 (Multiplier via CFU included)
add_files ./../../../rtl/mult_wrapper/src/mult.vhd [glob ./../../../neorv32-setups/neorv32/rtl/core/*.vhd] ./../../../neorv32-setups/neorv32/rtl/core/mem/neorv32_dmem.default.vhd ./../../../neorv32-setups/neorv32/rtl/core/mem/neorv32_imem.default.vhd
set_property library neorv32 [get_files [glob ./../../../neorv32-setups/neorv32/rtl/core/*.vhd]]
set_property library neorv32 [get_files [glob ./../../../neorv32-setups/neorv32/rtl/core/mem/neorv32_*mem.default.vhd]]
set_property library neorv32 [get_files ./../../../rtl/mult_wrapper/src/mult.vhd]

## Design: processor subsystem template, and (optionally) BoardTop and/or other additional sources 
set fileset_design ./../../../rtl/mult_wrapper/cfu/neorv32_test_top_cfu.vhd

## Constraints
set fileset_constraints [glob ./*.xdc]

## Simulation-only sources
set fileset_sim [list ./../../../neorv32-setups/neorv32/sim/simple/neorv32_tb.simple.vhd ./../../../neorv32-setups/neorv32/sim/simple/uart_rx.simple.vhd]

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
