## -----------------------------------------------------------------------
## 1. System Clock (125MHz -> CLK100MHZ Port)
## -----------------------------------------------------------------------
# Arty Z7의 H16 핀은 125MHz 오실레이터입니다.
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports CLK100MHZ]
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} -add [get_ports CLK100MHZ]

## -----------------------------------------------------------------------
## 2. Reset Button (BTN0 -> ck_rst Port)
## -----------------------------------------------------------------------
# D19 핀(BTN0)을 리셋으로 사용합니다. (Active High)
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports ck_rst]

## -----------------------------------------------------------------------
## 3. LEDs (LD0 ~ LD3 -> led[3:0] Port)
## -----------------------------------------------------------------------
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## -----------------------------------------------------------------------
## 4. PMOD AD1 (JA Header -> ADC Interface Ports)
## -----------------------------------------------------------------------
# Arty Z7 JA Header Mapping
# JA[1] = Y18
# JA[2] = Y19
# JA[3] = Y16
# JA[4] = Y17

# Chip Select (CS)
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports JA1_CS]

# DATA0 (D0)
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports JA2_DATA0]

# DATA1 (D1)
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports JA3_DATA1]

# Serial Clock (SCLK)
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports JA4_SCLK]


connect_debug_port u_ila_0/probe0 [get_nets [list {do_re[0]} {do_re[1]} {do_re[2]} {do_re[3]} {do_re[4]} {do_re[5]} {do_re[6]} {do_re[7]} {do_re[8]} {do_re[9]} {do_re[10]} {do_re[11]} {do_re[12]} {do_re[13]} {do_re[14]} {do_re[15]}]]
connect_debug_port u_ila_0/probe1 [get_nets [list {do_im[0]} {do_im[1]} {do_im[2]} {do_im[3]} {do_im[4]} {do_im[5]} {do_im[6]} {do_im[7]} {do_im[8]} {do_im[9]} {do_im[10]} {do_im[11]} {do_im[12]} {do_im[13]} {do_im[14]} {do_im[15]}]]
connect_debug_port u_ila_0/probe2 [get_nets [list do_en]]
connect_debug_port u_ila_0/probe3 [get_nets [list doppler_start]]
connect_debug_port u_ila_0/probe4 [get_nets [list range_finish]]


create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list CLK100MHZ_IBUF_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {w_dbg_do_im[0]} {w_dbg_do_im[1]} {w_dbg_do_im[2]} {w_dbg_do_im[3]} {w_dbg_do_im[4]} {w_dbg_do_im[5]} {w_dbg_do_im[6]} {w_dbg_do_im[7]} {w_dbg_do_im[8]} {w_dbg_do_im[9]} {w_dbg_do_im[10]} {w_dbg_do_im[11]} {w_dbg_do_im[12]} {w_dbg_do_im[13]} {w_dbg_do_im[14]} {w_dbg_do_im[15]}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets CLK100MHZ_IBUF_BUFG]

## -----------------------------------------------------------------------
## ★ ChipKit SPI Interface (Raspberry Pi 연결용)
## -----------------------------------------------------------------------
# IO10 (SS) -> 라즈베리 파이 Pin 24 (CE0)
set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS33 } [get_ports { ck_ss }]; 

# IO12 (MISO) -> 라즈베리 파이 Pin 21 (MISO)
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { ck_miso }]; 

# IO13 (SCLK) -> 라즈베리 파이 Pin 23 (SCLK)
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { ck_sck }]; 

## -----------------------------------------------------------------------
## SPI Clock 에러 무시 설정
## -----------------------------------------------------------------------
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ck_sck_IBUF]
