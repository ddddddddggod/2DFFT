module top_adc_fft2d (
    input  wire clk50,
    input  wire resetn,      // active-low reset

    // PMOD AD1 pins
    output wire JA1_CS,
    input  wire JA2_DATA0,
    input  wire JA3_DATA1,
    output wire JA4_SCLK,

    // Debug signals (simulation + ILA)
    output wire        dbg_di_en,
    output wire [15:0] dbg_di_re,
    output wire [15:0] dbg_di_im,
    output wire        dbg_range_finish,
    output wire        dbg_doppler_start,
    output wire        dbg_do_en,
    output wire [15:0] dbg_do_re,
    output wire [15:0] dbg_do_im
);

    // Convert active-low reset to active-high
    wire reset = ~resetn;

    // ============================================================
    // 1) PMOD AD1 SPI Driver
    // ============================================================
    wire        drdy;
    wire [15:0] adc_raw0;
    wire [15:0] adc_raw1;

    Pmod_SPI #(
        .CLOCKS_PER_BIT(5),          // 50MHz / 5 = 10MHz SCLK
        .CLOCKS_BEFORE_DATA(30),
        .CLOCKS_AFTER_DATA(250),
        .CLOCKS_BETWEEN_TRANSACTIONS(250)
    ) adc_driver (
        .clk(clk50),
        .rst(reset),
        .cs(JA1_CS),
        .sdin0(JA2_DATA0),
        .sdin1(JA3_DATA1),
        .sclk(JA4_SCLK),
        .drdy(drdy),
        .dout0(adc_raw0),
        .dout1(adc_raw1)
    );

    // ============================================================
    // 2) 12bit ADC → 16bit FFT 입력 정규화
    // ============================================================
    wire        di_en = drdy;
    wire [15:0] di_re = adc_raw0 << 4;    // 12 → 16bit 확장
    wire [15:0] di_im = adc_raw1 << 4;

    // Debug output for TB/ILA
    assign dbg_di_en = di_en;
    assign dbg_di_re = di_re;
    assign dbg_di_im = di_im;
    
    // ============================================================
    // 2) 12bit ADC → 16bit FFT 입력 정규화 (DC 오프셋 제거 포함!)
    // ============================================================
    wire        di_en = drdy;
    // [중요] ADC 값에서 2048을 빼서 1.5V를 0으로 만듦
    // adc_raw0는 [15:0]이지만 실제 데이터는 하위 12비트(0~4095)에 있다고 가정
    // Signed 연산을 위해 $signed() 시스템 함수 사용 혹은 수동 확장
    // 설명: (입력값 - 2048)을 한 뒤, 16배(<<4) 키워서 FFT 입력 범위(-32768 ~ +32767)를 꽉 채움
    wire signed [15:0] di_re = ($signed({1'b0, adc_raw0[11:0]}) - 16'd2048) <<< 4;
    wire signed [15:0] di_im = ($signed({1'b0, adc_raw1[11:0]}) - 16'd2048) <<< 4;

    // ============================================================
    // 3) FFT2D (128×128)
    // ============================================================
    wire        do_en;
    wire [15:0] do_re;
    wire [15:0] do_im;

    wire        range_finish;
    wire        doppler_start;

    FFT2D_128x128 #(
        .WIDTH(16)
    ) fft2d (
        .clock(clk50),
        .reset(reset),
        .di_en(di_en),
        .di_re(di_re),
        .di_im(di_im),
        .do_en(do_en),
        .do_re(do_re),
        .do_im(do_im),
        .range_finish(range_finish),
        .doppler_start(doppler_start)
    );

    // Output debug to top
    assign dbg_range_finish  = range_finish;
    assign dbg_doppler_start = doppler_start;
    assign dbg_do_en         = do_en;
    assign dbg_do_re         = do_re;
    assign dbg_do_im         = do_im;
    
        // ============================================================
    // 4) ILA 연결 (11 probes)
    // ============================================================

    // ILA 포트 안내:
    // probe0  = drdy (1bit)
    // probe1  = adc_raw0 (16bit)
    // probe2  = adc_raw1 (16bit)
    // probe3  = di_en (1bit)
    // probe4  = di_re (16bit)
    // probe5  = di_im (16bit)
    // probe6  = range_finish (1bit)
    // probe7  = doppler_start (1bit)
    // probe8  = do_en (1bit)
    // probe9  = do_re (16bit)
    // probe10 = do_im (16bit)

    ila_0 ila_inst (
        .clk(clk50),
        .probe0(drdy),
        .probe1(adc_raw0),
        .probe2(adc_raw1),
        .probe3(di_en),
        .probe4(di_re),
        .probe5(di_im),
        .probe6(range_finish),
        .probe7(doppler_start),
        .probe8(do_en),
        .probe9(do_re),
        .probe10(do_im)
    );

endmodule
