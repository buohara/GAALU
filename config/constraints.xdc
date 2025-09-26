set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property PACKAGE_PIN H5  [get_ports {leds[0]}] ;
set_property IOSTANDARD LVCMOS33 [get_ports {leds[0]}]

set_property PACKAGE_PIN J5  [get_ports {leds[1]}] ;
set_property IOSTANDARD LVCMOS33 [get_ports {leds[1]}]

set_property PACKAGE_PIN T9  [get_ports {leds[2]}] ;
set_property IOSTANDARD LVCMOS33 [get_ports {leds[2]}]

set_property PACKAGE_PIN T10 [get_ports {leds[3]}] ;
set_property IOSTANDARD LVCMOS33 [get_ports {leds[3]}]

set_property PACKAGE_PIN H6  [get_ports {leds[4]}] ;
set_property IOSTANDARD LVCMOS33 [get_ports {leds[4]}]

set_property PACKAGE_PIN U12 [get_ports {leds[5]}] ;
set_property IOSTANDARD LVCMOS33 [get_ports {leds[5]}]

set_property PACKAGE_PIN U11 [get_ports {leds[6]}] ;
set_property IOSTANDARD LVCMOS33 [get_ports {leds[6]}]

set_property PACKAGE_PIN V10 [get_ports {leds[7]}] ;
set_property IOSTANDARD LVCMOS33 [get_ports {leds[7]}]

set_property PACKAGE_PIN E3 [get_ports {clk_100mhz}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk_100mhz}]

create_clock -period 10.000 -name clk_100mhz -waveform {0 5} [get_ports {clk_100mhz}]

set_property PACKAGE_PIN D18 [get_ports {reset_btn}]
set_property IOSTANDARD LVCMOS33 [get_ports {reset_btn}]
set_property PULLUP TRUE [get_ports {reset_btn}]

set_property PACKAGE_PIN C12 [get_ports {uart_rx}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rx}]
set_property PACKAGE_PIN B12 [get_ports {uart_tx}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_tx}]