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

    // 디버깅용 신호
    output                  range_finish,   // Range FFT 한 프레임 저장 완료 순간
    output                  doppler_start   // Doppler FFT 읽기 시작 순간
);

    //------------------------------------------------------------------
    //  Range FFT (1D 128pt FFT)
    //------------------------------------------------------------------
    wire             range_do_en;
    wire [WIDTH-1:0] range_do_re;
    wire [WIDTH-1:0] range_do_im;

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
    wire             buf_do_en;
    wire [WIDTH-1:0] buf_do_re;
    wire [WIDTH-1:0] buf_do_im;
    
    // 버퍼 내부에서 나오는 디버그 신호를 받을 와이어
    wire             buf_range_finish;
    wire             buf_doppler_start;

    // 모듈 이름을 FFT2D_Buffer로 통일했습니다. (아래 제공된 코드 사용 필수)
    FFT2D_Buffer #(.WIDTH(WIDTH)) TRANS_BUF (
        .clock         (clock),
        .reset         (reset),
        
        // Write (From Range FFT)
        .wr_en         (range_do_en),
        .wr_re         (range_do_re),
        .wr_im         (range_do_im),
        
        // Read (To Doppler FFT) - ★ 이름 수정됨 (trans_rd -> buf_do)
        .rd_valid      (buf_do_en),
        .rd_re         (buf_do_re),
        .rd_im         (buf_do_im),
        
        // Debug Outputs - ★ 버퍼 모듈에 이 포트가 추가되어야 함
        .range_finish  (buf_range_finish),
        .doppler_start (buf_doppler_start)
    );

    //------------------------------------------------------------------
    //  Doppler FFT (1D 128pt FFT)
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

    // Top-level 출력 연결
    assign range_finish  = buf_range_finish;
    assign doppler_start = buf_doppler_start;

endmodule
