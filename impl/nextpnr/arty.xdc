## Clock signal

set_property LOC    E3        [ get_ports  clk_i ]

set_property IOSTANDARD     LVCMOS33  [ get_ports clk_i ]

create_clock -name sys_clk_pin -period 10.00 [ get_ports clk_i ]  

## UART

set_property LOC    A9        [ get_ports uart0_rxd_i ]
set_property LOC    D10       [ get_ports uart0_txd_o ]

set_property IOSTANDARD   LVCMOS33  [ get_ports uart0_rxd_i ]
set_property IOSTANDARD   LVCMOS33  [ get_ports uart0_txd_o ]

## RESET

set_property LOC    C2        [ get_ports rstn_i ]
set_property IOSTANDARD   LVCMOS33  [ get_ports rstn_i ]

## LEDs
set_property LOC    H5         [ get_ports gpio_o[0] ] 
set_property LOC    J5         [ get_ports gpio_o[1] ]
set_property LOC    T9         [ get_ports gpio_o[2] ]
set_property LOC    T10        [ get_ports gpio_o[3] ]

set_property IOSTANDARD   LVCMOS33  [ get_ports gpio_o[0] ]
set_property IOSTANDARD   LVCMOS33  [ get_ports gpio_o[1] ]
set_property IOSTANDARD   LVCMOS33  [ get_ports gpio_o[2] ]
set_property IOSTANDARD   LVCMOS33  [ get_ports gpio_o[3] ]

## Pmod Header JA (unused GPIO outputs)

set_property LOC    G13        [ get_ports gpio_o[4] ]
set_property LOC    B11        [ get_ports gpio_o[5] ]
set_property LOC    A11        [ get_ports gpio_o[6] ]
set_property LOC    D12        [ get_ports gpio_o[7] ]

set_property IOSTANDARD   LVCMOS33  [ get_ports gpio_o[4] ]
set_property IOSTANDARD   LVCMOS33  [ get_ports gpio_o[5] ]
set_property IOSTANDARD   LVCMOS33  [ get_ports gpio_o[6] ]
set_property IOSTANDARD   LVCMOS33  [ get_ports gpio_o[7] ]
