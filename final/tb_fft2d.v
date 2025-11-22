`timescale 1ns/1ps

module tb_fft2d;

    localparam WIDTH = 16;
    localparam N     = 128;

    reg                     clock;
    reg                     reset;
    reg                     di_en;
    reg signed [WIDTH-1:0]  di_re;
    reg signed [WIDTH-1:0]  di_im;

    wire                    do_en;
    wire signed [WIDTH-1:0] do_re;
    wire signed [WIDTH-1:0] do_im;

    // 디버깅용 Range/Doppler 경계 신호
    wire range_finish;
    wire doppler_start;

    integer fd;
    integer code;
    integer i;

    // ★ ADDED: 출력 파일 핸들 & 출력 카운트
    integer fd_out;          // output FFT 결과 파일
    integer out_count;

    //-----------------------------------------------------
    // DUT
    //-----------------------------------------------------
    FFT2D_128x128 #(
        .WIDTH(WIDTH)
    ) DUT (
        .clock          (clock),
        .reset          (reset),
        .di_en          (di_en),
        .di_re          (di_re),
        .di_im          (di_im),
        .do_en          (do_en),
        .do_re          (do_re),
        .do_im          (do_im),

        // 디버그 출력
        .range_finish   (range_finish),
        .doppler_start  (doppler_start)
    );

    //-----------------------------------------------------
    // ★ Range FFT 내부 신호 alias
    //-----------------------------------------------------
    wire                    range_di_en = DUT.RANGE_FFT.di_en;
    wire signed [WIDTH-1:0] range_di_re = DUT.RANGE_FFT.di_re;
    wire signed [WIDTH-1:0] range_di_im = DUT.RANGE_FFT.di_im;

    wire                    range_do_en = DUT.RANGE_FFT.do_en;
    wire signed [WIDTH-1:0] range_do_re = DUT.RANGE_FFT.do_re;
    wire signed [WIDTH-1:0] range_do_im = DUT.RANGE_FFT.do_im;

    //-----------------------------------------------------
    // ★ Doppler FFT 내부 신호 alias
    //-----------------------------------------------------
    wire                    dopp_di_en = DUT.DOPPLER_FFT.di_en;
    wire signed [WIDTH-1:0] dopp_di_re = DUT.DOPPLER_FFT.di_re;
    wire signed [WIDTH-1:0] dopp_di_im = DUT.DOPPLER_FFT.di_im;

    wire                    dopp_do_en = DUT.DOPPLER_FFT.do_en;
    wire signed [WIDTH-1:0] dopp_do_re = DUT.DOPPLER_FFT.do_re;
    wire signed [WIDTH-1:0] dopp_do_im = DUT.DOPPLER_FFT.do_im;

    //-----------------------------------------------------
    // Clock 100MHz
    //-----------------------------------------------------
    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end

    //-----------------------------------------------------
    // ★ 출력 카운터: do_en이 1일 때마다 증가
    //-----------------------------------------------------
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            out_count <= 0;
        end else if (do_en) begin
            out_count <= out_count + 1;
        end
    end

    //-----------------------------------------------------
    // ★ FFT 출력 파일로 저장
    //    - do_en이 1일 때마다 한 줄씩 기록
    //    - 형식: "실수 허수" (둘 다 16비트 hex)
    //-----------------------------------------------------
    always @(posedge clock) begin
        if (do_en) begin
            // MATLAB에서 textscan으로 읽기 편하게 공백으로 구분
            // 예: fprintf(fid, '%04X %04X\n', ...)과 동일 느낌
            $fdisplay(fd_out, "%h %h", do_re, do_im);  // ★ ADDED
        end
    end

    //-----------------------------------------------------
    // (옵션) range_finish / doppler_start 타이밍 로그
    //-----------------------------------------------------
    initial begin
        @(negedge reset);
        @(posedge clock);

        @(posedge range_finish);
        $display("[%0t] range_finish asserted (Range frame write done)", $time);

        @(posedge doppler_start);
        $display("[%0t] doppler_start asserted (Doppler frame read start)", $time);
    end

    //-----------------------------------------------------
    // Stimulus
    //-----------------------------------------------------
    initial begin
        reset = 1'b1;
        di_en = 1'b0;
        di_re = 0;
        di_im = 0;

        // input file open
        fd = $fopen("input_complex.txt", "r");
        if (fd == 0) begin
            $display("ERROR: cannot open input_complex.txt");
            $finish;
        end

        // ★ ADDED: output file open
        fd_out = $fopen("output_fft2d.txt", "w");
        if (fd_out == 0) begin
            $display("ERROR: cannot open output_fft2d.txt");
            $finish;
        end

        // release reset
        #50;
        reset = 1'b0;
        @(posedge clock);

        // 128×128 = 16384 sample 입력
        for (i = 0; i < N*N; i = i + 1) begin
            code = $fscanf(fd, "%h %h\n", di_re, di_im);
            if (code != 2) begin
                $display("ERROR: fscanf error at sample %0d", i);
                $finish;
            end

            di_en = 1'b1;
            @(posedge clock);
        end

        // 입력 종료
        di_en = 1'b0;
        di_re = 0;
        di_im = 0;
        $fclose(fd);

        // 출력 N×N개 나올 때까지 기다림
        $display("[%0t] All inputs injected. Waiting for %0d outputs...", $time, N*N);
        wait (out_count == N*N);
        $display("[%0t] Doppler FFT %0d outputs completed!", $time, N*N);

        // pipeline clean-up extra cycles
        repeat (200) @(posedge clock);

        // ★ ADDED: 출력 파일 닫기
        $fclose(fd_out);

        $display("Simulation DONE.");
        $finish;
    end

endmodule
