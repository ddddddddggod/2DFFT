## ===============================
## Arty Z7-20 PMOD JA (PmodAD1용)
## ===============================

# JA1_P → ja_pin1_io
set_property PACKAGE_PIN Y18 [get_ports {ja_pin1_io}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_pin1_io}]

# JA2_P → ja_pin2_io
set_property PACKAGE_PIN Y16 [get_ports {ja_pin2_io}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_pin2_io}]

# JA3_P → ja_pin3_io
set_property PACKAGE_PIN U18 [get_ports {ja_pin3_io}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_pin3_io}]

# JA4_P → ja_pin4_io
set_property PACKAGE_PIN W18 [get_ports {ja_pin4_io}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_pin4_io}]

## 필요 시 나머지 핀 매핑:
set_property PACKAGE_PIN Y19 [get_ports {ja_pin7_io}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_pin7_io}]

set_property PACKAGE_PIN Y17 [get_ports {ja_pin8_io}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_pin8_io}]

set_property PACKAGE_PIN U19 [get_ports {ja_pin9_io}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_pin9_io}]

set_property PACKAGE_PIN W19 [get_ports {ja_pin10_io}]
set_property IOSTANDARD LVCMOS33 [get_ports {ja_pin10_io}]


## Reset (BTN0)
set_property PACKAGE_PIN D19 [get_ports {reset_rtl}]
set_property IOSTANDARD LVCMOS33 [get_ports {reset_rtl}]
