`timescale 1ns/1ns

module top_level_fft (
    input clock,           // Master Clock
    input reset,           // Active High Reset
    input [3:0] sw,        // Switch inputs: sw[1]: input1.txt, sw[2]: input2.txt, sw[3]: input3.txt
    output [11:0] magnitude_out, // Magnitude 값
    output [9:0] led,          // 10개의 LED 출력
    output [34:0] seg          // Combined Seven Segment Outputs (HEX4 ~ HEX0)
);

    parameter WIDTH = 16;

    // Internal signals
    wire di_en;
    wire [15:0] di_re, di_im;
    wire do_en;
    wire [15:0] do_re, do_im;
    wire fft64_do_en;
    wire [6:0] seg_a, seg_b, seg_c, seg_d, seg_e; // Individual Seven Segment Outputs

    // Input Selector Module
    input_selector #(.WIDTH(WIDTH)) input_selector_inst (
        .clock(clock),
        .reset(reset),
        .sw1(sw[1]),        // Select input1.txt
        .sw2(sw[2]),        // Select input2.txt
        .sw3(sw[3]),        // Select input3.txt
        .di_en(di_en),      // Automatically set based on sw1~sw3
        .di_re(di_re),      // Real part of input
        .di_im(di_im)       // Imaginary part of input
    );

    // Seven Segment Controller
    seven_segment_controller seg_ctrl (
        .clock(clock),
        .reset(reset),
        .fft64_do_en(fft64_do_en), // FFT64 활성화 신호
        .fft64_do_re(di_re),       // FFT64 데이터 (Real part)
        .do_en(do_en),             // FFT128 활성화 신호
        .do_re(do_re),             // FFT128 데이터 (Real part)
        .seg_a(seg_a),             // Seven Segment HEX4
        .seg_b(seg_b),             // Seven Segment HEX3
        .seg_c(seg_c),             // Seven Segment HEX2
        .seg_d(seg_d),             // Seven Segment HEX1
        .seg_e(seg_e)              // Seven Segment HEX0
    );

    assign seg = {seg_e, seg_d, seg_c, seg_b, seg_a}; // Combine HEX4 ~ HEX0 into a single output

    // 2D FFT Top Module
    top_2d_fft #(.WIDTH(WIDTH)) fft_module (
        .clock(clock),
        .reset(reset),
        .di_en(di_en),
        .di_re(di_re),
        .di_im(di_im),
        .do_en(do_en),
        .do_re(do_re),
        .do_im(do_im),
        .fft64_do_en(fft64_do_en)
    );

    // Magnitude Calculator
    magnitude_calculator magnitude_inst (
        .clock(clock),
        .reset(reset),
        .do_re(do_re),
        .do_im(do_im),
        .magnitude(magnitude_out) // 최종 Magnitude 출력
    );

    // LED Controller
    led_controller led_controller_inst (
        .clock(clock),
        .reset(reset),
        .sw0(sw[0]),        // Top-level LED operation switch
        .di_en(di_en),
        .fft64_do_en(fft64_do_en),
        .do_en(do_en),
        .led(led)
    );

endmodule




// Magnitude Calculator Module
module magnitude_calculator (
    input clock,
    input reset,
    input [15:0] do_re,    // Real part
    input [15:0] do_im,    // Imaginary part
    output reg [15:0] magnitude // Magnitude 값
);

    reg [31:0] re_squared;
    reg [31:0] im_squared;
    reg [31:0] sum;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            re_squared <= 32'b0;
            im_squared <= 32'b0;
            sum <= 32'b0;
            magnitude <= 16'b0;
        end else begin
            // Real^2 + Imaginary^2 계산
            re_squared <= do_re * do_re;
            im_squared <= do_im * do_im;
            sum <= re_squared + im_squared;

            // 제곱근 계산 (sqrt(sum))
            magnitude <= sqrt(sum);
        end
    end

    // 제곱근 함수
    function [15:0] sqrt;
        input [31:0] value;
        integer i;
        reg [31:0] temp;
        reg [15:0] result;
        begin
            result = 16'b0;
            temp = 32'b0;
            for (i = 15; i >= 0; i = i - 1) begin
                temp = (result | (1 << i)) * (result | (1 << i));
                if (temp <= value)
                    result = result | (1 << i);
            end
            sqrt = result;
        end
    endfunction

endmodule



module input_selector #(parameter WIDTH = 16) (
    input clock,
    input reset,
    input sw1,                // Activate input1
    input sw2,                // Activate input2
    input sw3,                // Activate input3
    output reg di_en,         // Enable signal for data input
    output reg [WIDTH-1:0] di_re, // Real part of input data
    output reg [WIDTH-1:0] di_im, // Imaginary part of input data
    output [12:0] index       // Index for data reading
);

    // Index for sequential data traversal
    reg [12:0] index_reg;     // 13 bits for 8192 data points

    // Wire declarations for ROM outputs
    wire [WIDTH-1:0] in1_re_data, in1_im_data;
    wire [WIDTH-1:0] in2_re_data, in2_im_data;
    wire [WIDTH-1:0] in3_re_data, in3_im_data;

    // Assign internal index to output
    assign index = index_reg;

    // ROM instances for input1 (real and imaginary parts)
    in1_re in1_re_inst (
        .address(index_reg),
        .clock(clock),
        .q(in1_re_data)
    );

    in1_im in1_im_inst (
        .address(index_reg),
        .clock(clock),
        .q(in1_im_data)
    );

    // ROM instances for input2 (real and imaginary parts)
    in2_re in2_re_inst (
        .address(index_reg),
        .clock(clock),
        .q(in2_re_data)
    );

    in2_im in2_im_inst (
        .address(index_reg),
        .clock(clock),
        .q(in2_im_data)
    );

    // ROM instances for input3 (real and imaginary parts)
    in3_re in3_re_inst (
        .address(index_reg),
        .clock(clock),
        .q(in3_re_data)
    );

    in3_im in3_im_inst (
        .address(index_reg),
        .clock(clock),
        .q(in3_im_data)
    );

    // Main logic for input selection and `di_en` control
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            di_en <= 1'b0;
            di_re <= {WIDTH{1'b0}};
            di_im <= {WIDTH{1'b0}};
            index_reg <= 13'd0;
        end else if (sw1 || sw2 || sw3) begin
            di_en <= 1'b1; // Enable signal activated when any switch is on

            // Select input data based on the active switch
            if (sw1) begin
                di_re <= in1_re_data;
                di_im <= in1_im_data;
            end else if (sw2) begin
                di_re <= in2_re_data;
                di_im <= in2_im_data;
            end else if (sw3) begin
                di_re <= in3_re_data;
                di_im <= in3_im_data;
            end

            // Increment index for sequential data reading
            if (index_reg < 13'd8191)
                index_reg <= index_reg + 1;
            else begin
                index_reg <= 13'd0; // Reset index after last data point
                di_en <= 1'b0; // Disable di_en when all data is read
            end
        end else begin
            di_en <= 1'b0; // Disable signal when no switch is active
            di_re <= {WIDTH{1'b0}};
            di_im <= {WIDTH{1'b0}};
            index_reg <= 13'd0; // Reset index
        end
    end

endmodule


module led_controller (
    input wire clock,          // 50MHz 클록
    input wire reset,          // 리셋 신호 (Active High)
    input wire sw0,            // 스위치 0 (LED 동작 트리거)
    input wire di_en,          // di_en 신호
    input wire fft64_do_en,    // fft64_do_en 신호
    input wire do_en,          // do_en 신호
    output reg [9:0] led       // 10개의 LED 출력
);

    //================================================
    // 내부 상태 레지스터
    //================================================
    reg do_en_prev; // 이전 do_en 상태 저장

    //================================================
    // LED 출력 로직
    //================================================
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            led <= 10'b0000000000;       // 리셋 시 모든 LED 꺼짐
            do_en_prev <= 1'b0;         // do_en 이전 상태 초기화
        end else begin
            // 이전 do_en 상태 업데이트
            do_en_prev <= do_en;

            // do_en이 1에서 0으로 전환될 때
            if (do_en_prev && !do_en) begin
                led <= 10'b1111111111;  // LED 0~9 켜짐
            end else if (do_en) begin
                // do_en = 1일 경우 LED 0~8 켜기
                led <= 10'b1111111110;  // LED 0~8 켜짐
            end else if (fft64_do_en) begin
                // fft64_do_en = 1일 경우 di_en과 관계없이 LED 0~5 켜기
                led <= 10'b0000011111;  // LED 0~5 켜짐
            end else if (di_en) begin
                // di_en = 1일 경우 LED 0~2 켜기
                led <= 10'b0000000111;  // LED 0~2 켜짐
            end else begin
                // 모든 신호 비활성화 시 LED 꺼짐
                led <= 10'b0000000000;  // 모든 LED 꺼짐
            end
        end
    end

endmodule


module seven_segment_controller (
    input clock,             // Master Clock
    input reset,             // Reset Signal
    input fft64_do_en,       // FFT64 활성화 신호
    input [15:0] fft64_do_re, // FFT64 출력 데이터 (Real part)
    input do_en,             // FFT128 활성화 신호
    input [15:0] do_re,      // FFT128 출력 데이터 (Real part)
    output reg [6:0] seg_a,  // Seven Segment HEX4
    output reg [6:0] seg_b,  // Seven Segment HEX3
    output reg [6:0] seg_c,  // Seven Segment HEX2
    output reg [6:0] seg_d,  // Seven Segment HEX1
    output reg [6:0] seg_e   // Seven Segment HEX0
);

    // Seven Segment display patterns
    localparam [6:0] SEG_0    = 7'b1000000;  // "0"
    localparam [6:0] SEG_1    = 7'b1111001;  // "1"
    localparam [6:0] SEG_2    = 7'b0100100;  // "2"
    localparam [6:0] SEG_3    = 7'b0110000;  // "3"
    localparam [6:0] SEG_4    = 7'b0011001;  // "4"
    localparam [6:0] SEG_5    = 7'b0010010;  // "5"
    localparam [6:0] SEG_6    = 7'b0000010;  // "6"
    localparam [6:0] SEG_7    = 7'b1111000;  // "7"
    localparam [6:0] SEG_8    = 7'b0000000;  // "8"
    localparam [6:0] SEG_9    = 7'b0010000;  // "9"
    localparam [6:0] SEG_DASH = 7'b1111110;  // "-"

    // Counters for processed data
    reg [12:0] fft64_counter;  // FFT64 데이터 개수 카운터
    reg [12:0] fft128_counter; // FFT128 데이터 개수 카운터

    // Previous values to detect new data
    reg [15:0] prev_fft64_re;
    reg [15:0] prev_do_re;

    // Refresh counter for "--64--" and "-128-"
    reg [19:0] refresh_counter;
	 
	 initial begin
    seg_a = 7'b1111111; // Blank
    seg_b = 7'b1111111; // Blank
    seg_c = 7'b1111111; // Blank
    seg_d = 7'b1111111; // Blank
    seg_e = 7'b1111111; // Blank
end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // 초기화
            fft64_counter <= 0;
            fft128_counter <= 0;
            prev_fft64_re <= 16'b0;
            prev_do_re <= 16'b0;
            refresh_counter <= 0;
            seg_a <= 7'b1111111; // Blank
            seg_b <= 7'b1111111; // Blank
            seg_c <= 7'b1111111; // Blank
            seg_d <= 7'b1111111; // Blank
            seg_e <= 7'b1111111; // Blank
        end else begin
            if (fft64_do_en) begin
                // FFT64 처리 중
                if (fft64_do_re != prev_fft64_re) begin
                    fft64_counter <= fft64_counter + 1;
                    prev_fft64_re <= fft64_do_re;
                end

                // FFT64 처리 개수를 Seven Segment에 표시
                seg_a <= SEG_0 + fft64_counter[3:0];    // Lower nibble
                seg_b <= SEG_0 + fft64_counter[7:4];    // Second nibble
                seg_c <= SEG_0 + fft64_counter[11:8];   // Third nibble
                seg_d <= SEG_0 + fft64_counter[12];     // MSB
                seg_e <= SEG_DASH;                     // "-"
            end else if (do_en) begin
                // FFT128 처리 중
                if (do_re != prev_do_re) begin
                    fft128_counter <= fft128_counter + 1;
                    prev_do_re <= do_re;
                end

                // FFT128 처리 개수를 Seven Segment에 표시
                seg_a <= SEG_0 + fft128_counter[3:0];    // Lower nibble
                seg_b <= SEG_0 + fft128_counter[7:4];    // Second nibble
                seg_c <= SEG_0 + fft128_counter[11:8];   // Third nibble
                seg_d <= SEG_0 + fft128_counter[12];     // MSB
                seg_e <= SEG_DASH;                      // "-"
            end else begin
                // 처리 완료 후 "--64--" 또는 "-128-" 표시
                refresh_counter <= refresh_counter + 1;

                if (refresh_counter < 20'd500000) begin
                    // "--64--" 표시
                    seg_a <= SEG_DASH;
                    seg_b <= SEG_6;
                    seg_c <= SEG_4;
                    seg_d <= SEG_DASH;
                    seg_e <= 7'b1111111; // Blank
                end else begin
                    // "-128-" 표시
                    seg_a <= SEG_DASH;
                    seg_b <= SEG_1;
                    seg_c <= SEG_2;
                    seg_d <= SEG_8;
                    seg_e <= SEG_DASH;
                end
            end
        end
    end

endmodule



