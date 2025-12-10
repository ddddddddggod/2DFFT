//----------------------------------------------------------------------
// adc_to_fft_bridge
//  - PMOD AD1의 12bit ADC 데이터를 FFT2D_128x128 입력(Q1.15)으로 변환
//  - FFT 입력은 signed 16bit(real), di_en pulse, imaginary=0
//----------------------------------------------------------------------

module adc_to_fft_bridge (
    input              clk,
    input              reset,

    // PMOD AD1 IP Output
    input      [11:0]  adc_data,    // 12-bit ADC sample (unsigned)
    input              adc_valid,   // 1-clk valid pulse

    // FFT2D_128x128 Input
    output reg         fft_di_en,
    output reg [15:0]  fft_di_re,
    output reg [15:0]  fft_di_im
);

    //------------------------------------------------------------------
    // 12-bit ADC (0~4095) → signed Q1.15 변환
    //
    // Step1) 12bit unsigned → centered signed
    //        centered = adc_data - 2048  (midpoint bias 제거)
    //
    // Step2) 12bit → 16bit 확장 (<<4)
    //
    // Example:
    //   adc=2048 → 0
    //   adc=4095 → +2047 → <<4 = +32752   (~+1.0에 해당)
    //   adc=0    → -2048 → <<4 = -32768   (~-1.0에 해당)
    //------------------------------------------------------------------

    wire signed [12:0] centered_val  = {1'b0, adc_data} - 13'd2048;  // -2048 ~ +2047
    wire signed [15:0] q15_val       = centered_val <<< 4;           // -32768 ~ +32752

    //------------------------------------------------------------------
    // Register output (1-clock delayed, synchronous to clk)
    //------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            fft_di_en <= 1'b0;
            fft_di_re <= 16'd0;
            fft_di_im <= 16'd0;
        end else begin
            fft_di_en <= adc_valid;   // valid pulse 그대로 사용
            fft_di_re <= q15_val;     // Q1.15 실수값
            fft_di_im <= 16'd0;       // imaginary = 0 (단일 ADC)
        end
    end

endmodule
