## Generated SDC file "miniCPU_de2.sdc"

## Copyright (C) 1991-2011 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 11.0 Build 208 07/03/2011 Service Pack 1 SJ Web Edition"

## DATE    "Fri Oct 14 00:38:52 2011"

##
## DEVICE  "EP2C70F896C6"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {altera_reserved_tck} -period 100.000 -waveform { 0.000 50.000 } [get_ports {altera_reserved_tck}]
create_clock -name {clk50mhz} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk50mhz}]
create_clock -name {ps2_clk} -period 30000.000 -waveform { 0.000 15000.000 } [get_ports {ps2_clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {memory_controller:mem|clockgen:clockgen|mem_pll_interface:pll|mem_pll:pll|altpll:altpll_component|_clk0} -source [get_pins {mem|clockgen|pll|pll|altpll_component|pll|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -divide_by 2 -master_clock {clk50mhz} [get_pins {mem|clockgen|pll|pll|altpll_component|pll|clk[0]}] 
create_generated_clock -name {memory_controller:mem|clockgen:clockgen|mem_pll_interface:pll|mem_pll:pll|altpll:altpll_component|_clk1} -source [get_pins {mem|clockgen|pll|pll|altpll_component|pll|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -divide_by 2 -phase 180.000 -master_clock {clk50mhz} [get_pins {mem|clockgen|pll|pll|altpll_component|pll|clk[1]}] 
create_generated_clock -name {serial_clk_16x} -source [get_ports {clk50mhz}] -divide_by 325 -master_clock {clk50mhz} [get_keepers {memory_controller:mem|rs232_receive:rs232_rcv|serial_clk_16x}] 
create_generated_clock -name {generated_fifo_clk} -source [get_ports {clk50mhz}] -duty_cycle 0.990 -multiply_by 1 -divide_by 5200 -phase 180.000 -master_clock {clk50mhz} 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 


#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_dd9:dffpipe16|dffe17a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_cd9:dffpipe13|dffe14a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_fd9:dffpipe9|dffe10a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_ed9:dffpipe6|dffe7a*}]


#**************************************************************
# Set Multicycle Path
#**************************************************************

set_multicycle_path -hold -end -from [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|counter[0]}] -to [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|state.SignalComplete}] 5200
set_multicycle_path -hold -end -from [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|counter[0]}] -to [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|state.TransmitStop}] 5200
set_multicycle_path -hold -end -from [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|counter[0]}] -to [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|state.Transmit7}] 5200
set_multicycle_path -hold -end -from [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|counter[0]}] -to [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|state.Transmit6}] 5200
set_multicycle_path -hold -end -from [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|counter[0]}] -to [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|state.Transmit5}] 5200
set_multicycle_path -hold -end -from [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|counter[0]}] -to [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|state.Transmit4}] 5200
set_multicycle_path -hold -end -from [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|counter[0]}] -to [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|state.Transmit3}] 5200
set_multicycle_path -hold -end -from [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|counter[0]}] -to [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|state.Transmit2}] 5200
set_multicycle_path -hold -end -from [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|counter[0]}] -to [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|state.Transmit1}] 5200
set_multicycle_path -hold -end -from [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|counter[0]}] -to [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|state.Transmit0}] 5200
set_multicycle_path -hold -end -from [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|counter[0]}] -to [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|state.TransmitStart}] 5200
set_multicycle_path -hold -end -from [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|counter[0]}] -to [get_keepers {memory_controller:mem|rs232_transmit:rs232_xmit|state.Prep}] 5200


#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

