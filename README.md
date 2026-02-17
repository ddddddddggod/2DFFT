# 2DFFT
반도체 전공 트랙 프로젝트

Memory-efficient 2D FFT architecture for In-Cabin Monitoring Systems (ICMS)

## FPGA
** The FPGA platform was migrated to the Arty Z7 using a Digilent ADC module.
- Arty Z7-20
- Altera Cyclone® IV 4CE115 FPGA device
- MAX 10 10M50DAF484C7G Device
## Tool
- Vivado, Modelsim : FPGA Simulation & Algorithm verification 
- Matlab : Algorithm verification

## Addtional
- The architecture was initially planned as a 68×128 design but was ultimately finalized as a 128×128 configuration.
- Throughout the project, all development stages and revisions were preserved without modification and systematically organized into separate folders. The final version of the project is contained in the `251219` directory.
- The system was constructed as a demonstration pipeline consisting of analog signal acquisition, ADC conversion, 2D FFT processing, and result visualization on a Raspberry Pi.
