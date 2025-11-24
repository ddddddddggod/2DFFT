//----------------------------------------------------------------------
//  FFT2D_128x128: 2D FFT Top (Range FFT + Transpose Buffer + Doppler FFT)
//----------------------------------------------------------------------

module FFT2D_128x128 #(
    parameter WIDTH = 16
)(
    input                   clock,
    input                   reset,
    input                   di_en,
    input       [WIDTH-1:0] di_re,
    input       [WIDTH-1:0] di_im,
    output                  do_en,
    output      [WIDTH-1:0] do_re,
    output      [WIDTH-1:0] do_im,

    // ★ ADDED: 디버깅용 Range/Doppler 경계 신호
    output                  range_finish,   // Range FFT 결과 128x128 write 완료
    output                  doppler_start   // Doppler FFT로 첫 샘플 나갈 때
);

    //------------------------------------------------------------------
    //  Range FFT (1D 128pt FFT)  ★ 기존 FFT를 그대로 Range 방향에 사용
    //------------------------------------------------------------------
    wire                range_do_en;
    wire [WIDTH-1:0]    range_do_re;
    wire [WIDTH-1:0]    range_do_im;

    // Range_FFT
    Range_FFT #(.WIDTH(WIDTH)) RANGE_FFT (
        .clock  (clock      ),
        .reset  (reset      ),
        .di_en  (di_en      ),
        .di_re  (di_re      ),
        .di_im  (di_im      ),
        .do_en  (range_do_en),
        .do_re  (range_do_re),
        .do_im  (range_do_im)
    );

    //------------------------------------------------------------------
    //  중간 전치 버퍼 (Range → Doppler) 
    //------------------------------------------------------------------
    wire                buf_do_en;
    wire [WIDTH-1:0]    buf_do_re;
    wire [WIDTH-1:0]    buf_do_im;

    // ★ ADDED: 버퍼 내부 디버그 신호
    wire                buf_range_finish;
    wire                buf_doppler_start;

    FFT2D_Buffer #(
        .WIDTH (WIDTH),
        .N     (128)
    ) RD_BUFFER (
        .clock        (clock      ),
        .reset        (reset      ),
        .di_en        (range_do_en),
        .di_re        (range_do_re),
        .di_im        (range_do_im),
        .do_en        (buf_do_en  ),
        .do_re        (buf_do_re  ),
        .do_im        (buf_do_im  ),

        // ★ ADDED: 버퍼에서 나오는 디버그 신호 연결
        .range_finish (buf_range_finish),
        .doppler_start(buf_doppler_start)
    );

    //------------------------------------------------------------------
    //  Doppler FFT (1D 128pt FFT)  ★ 기존 FFT를 Doppler 방향에 재사용
    //------------------------------------------------------------------
    Doppler_FFT #(.WIDTH(WIDTH)) DOPPLER_FFT (
        .clock  (clock     ),
        .reset  (reset     ),
        .di_en  (buf_do_en ),  
        .di_re  (buf_do_re ),
        .di_im  (buf_do_im ),
        .do_en  (do_en     ),  
        .do_re  (do_re     ),
        .do_im  (do_im     )
    );

    // ★ ADDED: Top-level 디버그 포트로 전달
    assign range_finish  = buf_range_finish;
    assign doppler_start = buf_doppler_start;

endmodule
