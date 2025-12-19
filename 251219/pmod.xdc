## 1. System Clock
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports CLK100MHZ]
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} -add [get_ports CLK100MHZ]

## 2. Reset Button
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports ck_rst]

## 3. LEDs
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## 4. PMOD AD1 (ADC)
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports JA1_CS]
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports JA2_DATA0]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports JA3_DATA1]
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports JA4_SCLK]

## 5. Raspberry Pi SPI
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports ck_ss]
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS33} [get_ports ck_miso]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports ck_sck]
set_property -dict {PACKAGE_PIN T12 IOSTANDARD LVCMOS33} [get_ports ck_mosi]

## 6. Timing & Clock Settings
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ck_sck_IBUF]
create_clock -period 100.000 -name spi_sck [get_ports ck_sck]
set_clock_groups -asynchronous -group [get_clocks sys_clk_pin] -group [get_clocks spi_sck]
