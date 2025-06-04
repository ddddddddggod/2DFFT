`timescale 1ns / 1ps

module testbench;

    // 기본 파라미터
    parameter WIDTH = 16;
    parameter N = 64;

    // DUT 포트 연결용 레지스터
    reg clk, reset;
    reg di_en;
    reg signed [WIDTH-1:0] di_re, di_im;
    wire do_en;
    wire signed [WIDTH-1:0] do_re, do_im;

    // 입력 메모리 (real + imag 순)
    reg [15:0] input_mem [0:2*N-1];  // 64 complex → 128 words
    integer i;

    // 출력 저장용 파일
    integer fout;

    // --------------------------
    // 클럭 생성 (10ns period)
    // --------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // --------------------------
    // FFT DUT 인스턴스 연결
    // --------------------------
    FFT #(WIDTH) dut (
        .clock(clk),
        .reset(reset),
        .di_en(di_en),
        .di_re(di_re),
        .di_im(di_im),
        .do_en(do_en),
        .do_re(do_re),
        .do_im(do_im)
    );

    // --------------------------
    // 초기화 및 입력 주입
    // --------------------------
    initial begin
        // 입력 파일 읽기
        $readmemh("if_input.txt", input_mem);
        fout = $fopen("fft_output.txt", "w");

        // 초기 상태
        reset = 1;
        di_en = 0;
        di_re = 0;
        di_im = 0;
        i = 0;

        // 리셋 펄스
        #20;
        reset = 0;

        // 64개 복소수 입력값 주입
        #10;
        for (i = 0; i < N; i = i + 1) begin
            @(posedge clk);
            di_en <= 1;
            di_re <= $signed(input_mem[2*i]);     // real
            di_im <= $signed(input_mem[2*i + 1]); // imag
        end

        // 입력 종료
        @(posedge clk);
        di_en <= 0;

        // 출력 받을 시간 대기 (latency 고려)
        repeat (100) @(posedge clk);
        $fclose(fout);
        $finish;
    end

    // --------------------------
    // 출력값 저장
    // --------------------------
    always @(posedge clk) begin
        if (do_en) begin
            $fwrite(fout, "%04x %04x\n", do_re[15:0], do_im[15:0]);
        end
    end

endmodule
