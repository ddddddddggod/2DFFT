module FPGA_Top (
    input  wire CLK100MHZ,      // 125MHz System Clock
    input  wire ck_rst,         // BTN0 (Reset)
    
    // PMOD AD1 Interface
    output wire JA1_CS,
    input  wire JA2_DATA0,
    input  wire JA3_DATA1,
    output wire JA4_SCLK,

    // ★ 추가된 부분 1: 라즈베리 파이 연결용 SPI 포트 (ChipKit 핀)
    input  wire ck_ss,          // IO10 (CS)
    input  wire ck_sck,         // IO13 (SCLK)
    output wire ck_miso,        // IO12 (MISO)

    // Status LED
    output wire [3:0] led
);

    wire sys_clk = CLK100MHZ;
    wire resetn = ~ck_rst;    

    // -----------------------------------------------------------
    // 디버깅용 내부 와이어
    // -----------------------------------------------------------
    (* mark_debug = "true", keep = "true" *) wire        w_dbg_di_en;
    (* mark_debug = "true", keep = "true" *) wire [15:0] w_dbg_di_re;
    (* mark_debug = "true", keep = "true" *) wire [15:0] w_dbg_di_im;
    (* mark_debug = "true", keep = "true" *) wire        w_dbg_range_finish;
    (* mark_debug = "true", keep = "true" *) wire        w_dbg_doppler_start;
    (* mark_debug = "true", keep = "true" *) wire        w_dbg_do_en;
    (* mark_debug = "true", keep = "true" *) wire [15:0] w_dbg_do_re; // FFT 결과 (실수)
    (* mark_debug = "true", keep = "true" *) wire [15:0] w_dbg_do_im; // FFT 결과 (허수)

    // -----------------------------------------------------------
    // 메인 로직 인스턴스 (FFT 계산)
    // -----------------------------------------------------------
    top_adc_fft2d u_logic (
        .clk50    (sys_clk), 
        .resetn   (resetn),
        .JA1_CS    (JA1_CS),
        .JA2_DATA0 (JA2_DATA0),
        .JA3_DATA1 (JA3_DATA1),
        .JA4_SCLK  (JA4_SCLK),

        .dbg_di_en        (w_dbg_di_en),
        .dbg_di_re        (w_dbg_di_re),
        .dbg_di_im        (w_dbg_di_im),
        .dbg_range_finish (w_dbg_range_finish),
        .dbg_doppler_start(w_dbg_doppler_start),
        .dbg_do_en        (w_dbg_do_en),
        .dbg_do_re        (w_dbg_do_re), // 여기서 나온 값이 와이어에 실림
        .dbg_do_im        (w_dbg_do_im)  // 여기서 나온 값이 와이어에 실림
    );

    // -----------------------------------------------------------
    // ★ 추가된 부분 2: 데이터 합치기 & SPI 모듈 연결
    // -----------------------------------------------------------
    
    // 1. 데이터를 32비트 한 줄로 (상위 16비트: 실수, 하위 16비트: 허수)
       wire [31:0] spi_send_data = {w_dbg_do_re, w_dbg_do_im};



    // 2. SPI Slave 모듈을 불러와서 라즈베리 파이 포트와 데이터 선을 연결합니다.
    SPI_Slave u_spi_bridge (
        .clk      (sys_clk),
        .rst      (~resetn),
        .spi_cs   (ck_ss),      // 라즈베리 파이의 CS 신호 받기
        .spi_sclk (ck_sck),     // 라즈베리 파이의 SCLK 신호 받기
        .spi_miso (ck_miso),    // 라즈베리 파이로 데이터 보내기
        .data_in  (spi_send_data) // ★ 합친 FFT 결과값을 여기에 꽂습니다!
    );

    // LED 상태 표시
    assign led[0] = resetn;      
    assign led[1] = w_dbg_do_en; 
    assign led[2] = !ck_ss;      // SPI 통신 중일 때(CS Low) 켜짐
    assign led[3] = 1'b0;

endmodule
