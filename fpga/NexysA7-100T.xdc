############################
## Clock (100 MHz)
############################
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

############################
## Reset (SW15)
############################
set_property PACKAGE_PIN R15 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

############################
## Switches
############################
## Door (SW0)
set_property PACKAGE_PIN J15 [get_ports door]
set_property IOSTANDARD LVCMOS33 [get_ports door]

## Motion (SW1)
set_property PACKAGE_PIN L16 [get_ports motion]
set_property IOSTANDARD LVCMOS33 [get_ports motion]

############################
## Fire Sensor (PMOD JA1)
############################
set_property PACKAGE_PIN C17 [get_ports sensor_in]
set_property IOSTANDARD LVCMOS33 [get_ports sensor_in]
set_property PULLDOWN true [get_ports sensor_in]

############################
## LEDs
############################
set_property PACKAGE_PIN H17 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN K15 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN J13 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
