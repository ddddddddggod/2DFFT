module FPGA_Top (
    input  wire CLK100MHZ,      // 125MHz System Clock
    input  wire ck_rst,         // BTN0 (Reset)
    
    // PMOD AD1 Interface
    output wire JA1_CS,
    input  wire JA2_DATA0,
    input  wire JA3_DATA1,
    output wire JA4_SCLK,

    // Status LED
    output wire [3:0] led
);

    wire sys_clk = CLK100MHZ;
    
    // 리셋 처리 (Active High -> Active Low)
    // ck_rst(BTN0)는 누르면 1, 평소 0
    wire resetn = ~ck_rst;    

    // -----------------------------------------------------------
    // ★ 디버깅용 내부 와이어 선언 (여기에 mark_debug를 붙임)
    // -----------------------------------------------------------
    (* mark_debug = "true", keep = "true" *) wire        w_dbg_di_en;
    (* mark_debug = "true", keep = "true" *) wire [15:0] w_dbg_di_re;
    (* mark_debug = "true", keep = "true" *) wire [15:0] w_dbg_di_im;
    (* mark_debug = "true", keep = "true" *) wire        w_dbg_range_finish;
    (* mark_debug = "true", keep = "true" *) wire        w_dbg_doppler_start;
    (* mark_debug = "true", keep = "true" *) wire        w_dbg_do_en;
    (* mark_debug = "true", keep = "true" *) wire [15:0] w_dbg_do_re;
    (* mark_debug = "true", keep = "true" *) wire [15:0] w_dbg_do_im;


    // -----------------------------------------------------------
    // 모듈 인스턴스화 및 와이어 연결
    // -----------------------------------------------------------
    top_adc_fft2d u_logic (
        .clk50   (sys_clk),    // 실제 125MHz
        .resetn  (resetn),

        // Pmod 연결
        .JA1_CS    (JA1_CS),
        .JA2_DATA0 (JA2_DATA0),
        .JA3_DATA1 (JA3_DATA1),
        .JA4_SCLK  (JA4_SCLK),

        // ★ 디버그 포트를 위에서 선언한 와이어에 연결!
        .dbg_di_en        (w_dbg_di_en),
        .dbg_di_re        (w_dbg_di_re),
        .dbg_di_im        (w_dbg_di_im),
        .dbg_range_finish (w_dbg_range_finish),
        .dbg_doppler_start(w_dbg_doppler_start),
        .dbg_do_en        (w_dbg_do_en),
        .dbg_do_re        (w_dbg_do_re),
        .dbg_do_im        (w_dbg_do_im)
    );

    // LED 상태 표시
    assign led[0] = resetn; // 리셋 풀리면 켜짐
    assign led[1] = w_dbg_do_en; // 결과 나올 때 깜빡임
    assign led[2] = 1'b0;
    assign led[3] = 1'b0;

endmodule
