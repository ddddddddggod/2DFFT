
module FFT2D_Buffer #(
    parameter WIDTH = 16,
    parameter N     = 128
)(
    input                   clock,
    input                   reset,
    input                   di_en,
    input       [WIDTH-1:0] di_re,
    input       [WIDTH-1:0] di_im,
    output  reg             do_en,
    output  reg [WIDTH-1:0] do_re,
    output  reg [WIDTH-1:0] do_im,      

    // ★ ADDED: 디버깅용 상태 신호
    output  reg             range_finish,   // Range FFT 결과 N×N 쓰기 완료 1클럭 펄스
    output  reg             doppler_start   // Doppler FFT 첫 샘플 읽기 시작 1클럭 펄스
);

// log2 constant function (SdfUnit과 동일 스타일)
function integer log2;
    input integer x;
    integer value;
    begin
        value = x-1;
        for (log2 = 0; value > 0; log2 = log2 + 1)
            value = value >> 1;
    end
endfunction

localparam LOG_N = log2(N);

//----------------------------------------------------------------------
//  2D Memory (N x N Complex)
//----------------------------------------------------------------------

reg [WIDTH-1:0] mem_re [0:N-1][0:N-1];
reg [WIDTH-1:0] mem_im [0:N-1][0:N-1];

// Write address (row-major: [wr_row][wr_col])
reg [LOG_N-1:0] wr_row;
reg [LOG_N-1:0] wr_col;

// Read address (column-major: [rd_row][rd_col])
reg [LOG_N-1:0] rd_row;
reg [LOG_N-1:0] rd_col;

// Frame 상태
localparam ST_WRITE = 1'b0;
localparam ST_READ  = 1'b1;
reg        state;

// Optional: 카운트 (디버깅용)
reg [LOG_N*2-1:0] wr_count;
reg [LOG_N*2-1:0] rd_count;

//----------------------------------------------------------------------
//  State Machine + Write / Read Logic
//----------------------------------------------------------------------

integer i, j;

always @(posedge clock or posedge reset) begin
    if (reset) begin
        // 상태 & 주소 초기화
        state    <= ST_WRITE;
        wr_row   <= {LOG_N{1'b0}};
        wr_col   <= {LOG_N{1'b0}};
        rd_row   <= {LOG_N{1'b0}};
        rd_col   <= {LOG_N{1'b0}};
        wr_count <= {LOG_N*2{1'b0}};
        rd_count <= {LOG_N*2{1'b0}};

        do_en        <= 1'b0;
        do_re        <= {WIDTH{1'b0}};
        do_im        <= {WIDTH{1'b0}};

        range_finish <= 1'b0;  // ★ ADDED: reset 시 초기화
        doppler_start<= 1'b0;  // ★ ADDED: reset 시 초기화
    end else begin

        // ★ ADDED: 한 클럭짜리 펄스라 매 사이클 기본값은 0으로 깔고 시작
        range_finish  <= 1'b0;
        doppler_start <= 1'b0;

        case (state)
            //----------------------------------------------------------
            // WRITE STATE : Range FFT 결과를 N×N 메모리에 row-major로 저장
            //----------------------------------------------------------
            ST_WRITE: begin
                do_en <= 1'b0;  

                if (di_en) begin
                    // 현재 위치에 쓰기
                    mem_re[wr_row][wr_col] <= di_re;
                    mem_im[wr_row][wr_col] <= di_im;

                    wr_count <= wr_count + 1'b1;

                    // 주소 증가 (row-major: row가 외부, col이 내부)
                    if (wr_col == N-1) begin
                        wr_col <= {LOG_N{1'b0}};
                        if (wr_row == N-1) begin
                            wr_row   <= {LOG_N{1'b0}};

                            // ★ ADDED: N×N 샘플 다 채우는 마지막 write에서 range_finish 펄스
                            range_finish <= 1'b1;

                            // N×N 샘플 다 채우면 READ로 전환
                            state    <= ST_READ;
                            rd_row   <= {LOG_N{1'b0}};
                            rd_col   <= {LOG_N{1'b0}};
                            rd_count <= {LOG_N*2{1'b0}};
                        end else begin
                            wr_row <= wr_row + 1'b1;
                        end
                    end else begin
                        wr_col <= wr_col + 1'b1;
                    end
                end
            end

            //----------------------------------------------------------
            // READ STATE : 메모리에서 column-major 순서로 읽어서 출력
            //----------------------------------------------------------
            ST_READ: begin
                // 한 클럭에 한 sample씩 출력
                do_en <= 1'b1;
                do_re <= mem_re[rd_row][rd_col];
                do_im <= mem_im[rd_row][rd_col];

                // ★ ADDED: READ로 전환 후 첫 샘플에서 doppler_start 펄스
                if (rd_count == {LOG_N*2{1'b0}}) begin
                    doppler_start <= 1'b1;
                end

                rd_count <= rd_count + 1'b1;

                // column-major: col 고정
                if (rd_row == N-1) begin
                    rd_row <= {LOG_N{1'b0}};
                    if (rd_col == N-1) begin
                        // N×N 전부 다 읽었으면 다음 프레임 쓰기로
                        rd_col   <= {LOG_N{1'b0}};
                        state    <= ST_WRITE;
                        wr_row   <= {LOG_N{1'b0}};
                        wr_col   <= {LOG_N{1'b0}};
                        wr_count <= {LOG_N*2{1'b0}};
                        do_en    <= 1'b0;  // 다음 클럭부터는 다시 write
                    end else begin
                        rd_col <= rd_col + 1'b1;
                    end
                end else begin
                    rd_row <= rd_row + 1'b1;
                end
            end

        endcase
    end
end

endmodule
