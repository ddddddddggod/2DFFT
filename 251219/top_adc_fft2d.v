module top_adc_fft2d (
    input  wire clk50,
    input  wire resetn,      // active-low reset

    // PMOD AD1 pins
    output wire JA1_CS,
    input  wire JA2_DATA0,
    input  wire JA3_DATA1,
    output wire JA4_SCLK,

    // Debug signals
    output wire        dbg_di_en,
    output wire [15:0] dbg_di_re,
    output wire [15:0] dbg_di_im,
    output wire        dbg_range_finish,
    output wire        dbg_doppler_start,
    output wire        dbg_do_en,
    output wire signed [15:0] dbg_do_re,
    output wire signed [15:0] dbg_do_im

);

    // ============================================================
    // Reset (active-low → active-high)
    // ============================================================
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
        .clk   (clk50),
        .rst   (reset),
        .cs    (JA1_CS),
        .sdin0 (JA2_DATA0),
        .sdin1 (JA3_DATA1),
        .sclk  (JA4_SCLK),
        .drdy  (drdy),
        .dout0 (adc_raw0),
        .dout1 (adc_raw1)
    );

    // ============================================================
    // 2) ADC → FFT input (SIGNED, zero-centered)
    // ============================================================
        // Debug taps
    assign dbg_di_en = di_en;
    assign dbg_di_re = di_re;
    assign dbg_di_im = di_im;
    
    wire di_en = drdy;

    // 12-bit unsigned ADC → signed Q1.15
    //wire signed [15:0] di_re = ($signed({1'b0, adc_raw0[11:0]}) - 16'sd1861) <<< 4;
    //wire signed [15:0] di_im = ($signed({1'b0, adc_raw1[11:0]}) - 16'sd1861) <<< 4;
    //방법1
    wire signed [15:0] di_re = ($signed({1'b0, adc_raw0[11:0]}) - 16'sd1861) <<< 1;
    wire signed [15:0] di_im = ($signed({1'b0, adc_raw1[11:0]}) - 16'sd1861) <<< 1;
    //방법 2 (아예 시프트 제거)
    //wire signed [15:0] di_re = $signed({1'b0, adc_raw0[11:0]}) - 16'sd1861;
    //wire signed [15:0] di_im = $signed({1'b0, adc_raw1[11:0]}) - 16'sd1861;

    // ============================================================
    // 3) FFT2D (128 × 128)
    // ============================================================
    wire do_en;
    wire signed [15:0] do_re;
    wire signed  [15:0] do_im;
    
    wire range_finish;
    wire doppler_start;

    FFT2D_128x128 #(
        .WIDTH(16)
    ) fft2d (
        .clock         (clk50),
        .reset         (reset),
        .di_en         (di_en),
        .di_re         (di_re),
        .di_im         (di_im),
        .do_en         (do_en),
        .do_re         (do_re),
        .do_im         (do_im),
        .range_finish  (range_finish),
        .doppler_start (doppler_start)
    );

    assign dbg_range_finish  = range_finish;
    assign dbg_doppler_start = doppler_start;
    assign dbg_do_en         = do_en;
    assign dbg_do_re         = do_re;
    assign dbg_do_im         = do_im;;

    // ============================================================
    // 4) ILA (Probe mapping 고정)
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
    // ============================================================
    // ILA (RTL 인스턴스 유지)
    // ============================================================
    ila_0 ila_inst (
        .clk    (clk50),
        .probe0 (drdy),
        .probe1 (di_en),
        .probe2 (di_re),
        .probe3 (di_im),
        .probe4 (range_finish),
        .probe5 (doppler_start),
        .probe6 (do_en),
        .probe7 (do_re),
        .probe8 (do_im)
    );

endmodule

