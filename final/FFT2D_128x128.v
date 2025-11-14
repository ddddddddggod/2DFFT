//----------------------------------------------------------------------
//  FFT2D_128x128: 2D FFT Top (Range FFT + Transpose Buffer + Doppler FFT)
//----------------------------------------------------------------------
//  입력  : FMCW beat signal (complex) 128x128 프레임
//          - fast-time(샘플 인덱스) 방향으로 128pt Range FFT
//          - slow-time(차프 인덱스) 방향으로 128pt Doppler FFT
//  출력  : 2D FFT 결과 스트림 (Doppler FFT 출력)
//----------------------------------------------------------------------
//  ★ NEW TOP MODULE: 기존 FFT 코어는 수정하지 않고, instantiation만 추가
//----------------------------------------------------------------------

module FFT2D_128x128 #(
    parameter WIDTH = 16
)(
    input                   clock,
    input                   reset,

    // 입력: ADC 또는 전처리에서 넘어오는 beat signal (complex)
    input                   di_en,
    input       [WIDTH-1:0] di_re,
    input       [WIDTH-1:0] di_im,

    // 출력: 최종 2D FFT 결과 (Doppler FFT 출력 스트림)
    output                  do_en,
    output      [WIDTH-1:0] do_re,
    output      [WIDTH-1:0] do_im
);

    //------------------------------------------------------------------
    //  Range FFT (1D 128pt FFT)  ★ 기존 FFT를 그대로 Range 방향에 사용
    //------------------------------------------------------------------
    wire                range_do_en;
    wire [WIDTH-1:0]    range_do_re;
    wire [WIDTH-1:0]    range_do_im;

    // ★ 여기가 "Range FFT" 역할
    FFT #(.WIDTH(WIDTH)) RANGE_FFT (
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
    //  중간 전치 버퍼 (Range → Doppler)  ★ FFT2D_Buffer 사용
    //------------------------------------------------------------------
    wire                buf_do_en;
    wire [WIDTH-1:0]    buf_do_re;
    wire [WIDTH-1:0]    buf_do_im;

    FFT2D_Buffer #(
        .WIDTH (WIDTH),
        .N     (128)
    ) RD_BUFFER (
        .clock (clock      ),
        .reset (reset      ),

        // Range FFT 출력 → 버퍼 입력
        .di_en (range_do_en),
        .di_re (range_do_re),
        .di_im (range_do_im),

        // 버퍼 출력 → Doppler FFT 입력
        .do_en (buf_do_en  ),
        .do_re (buf_do_re  ),
        .do_im (buf_do_im  )
    );

    //------------------------------------------------------------------
    //  Doppler FFT (1D 128pt FFT)  ★ 기존 FFT를 Doppler 방향에 재사용
    //------------------------------------------------------------------
    // 버퍼에서 나오는 데이터는 이미 전치된 상태 (range-bin 별 slow-time)
    // → Doppler FFT는 각 range-bin에 대해 128pt FFT 수행
    //------------------------------------------------------------------
    FFT #(.WIDTH(WIDTH)) DOPPLER_FFT (
        .clock  (clock     ),
        .reset  (reset     ),
        .di_en  (buf_do_en ),   // 버퍼의 do_en이 Doppler FFT의 di_en
        .di_re  (buf_do_re ),
        .di_im  (buf_do_im ),
        .do_en  (do_en     ),   // 최종 2D FFT 출력
        .do_re  (do_re     ),
        .do_im  (do_im     )
    );

endmodule
