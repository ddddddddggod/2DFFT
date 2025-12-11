//리소스 폭발로 변경한 버전
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

    output  reg             range_finish,
    output  reg             doppler_start
);

function integer log2;
    input integer x;
    integer v;
    begin
        v = x-1;
        for (log2 = 0; v > 0; log2 = log2 + 1) v = v >> 1;
    end
endfunction

localparam LOG_N = log2(N);

// 1D 메모리 (BRAM)
(* ram_style = "block" *) reg [WIDTH-1:0] mem_re [0:N*N-1];
(* ram_style = "block" *) reg [WIDTH-1:0] mem_im [0:N*N-1];

// Write index
reg [LOG_N-1:0] wr_row;
reg [LOG_N-1:0] wr_col;

// Read index
reg [LOG_N-1:0] rd_row;
reg [LOG_N-1:0] rd_col;

localparam ST_WRITE = 1'b0;
localparam ST_READ  = 1'b1;
reg state;

always @(posedge clock or posedge reset) begin
    if (reset) begin
        state         <= ST_WRITE;
        wr_row        <= 0;
        wr_col        <= 0;
        rd_row        <= 0;
        rd_col        <= 0;
        do_en         <= 0;
        do_re         <= 0;
        do_im         <= 0;
        range_finish  <= 0;
        doppler_start <= 0;

    end else begin
        range_finish  <= 0;
        doppler_start <= 0;

        case(state)

        //---------------------------------------------------------
        // WRITE : row-major 저장
        //---------------------------------------------------------
        ST_WRITE: begin
            do_en <= 0;

            if (di_en) begin
                // row-major address = wr_row * N + wr_col
                mem_re[wr_row*N + wr_col] <= di_re;
                mem_im[wr_row*N + wr_col] <= di_im;

                if (wr_col == N-1) begin
                    wr_col <= 0;
                    if (wr_row == N-1) begin
                        wr_row <= 0;
                        state  <= ST_READ;
                        range_finish <= 1'b1;
                    end
                    else wr_row <= wr_row + 1;
                end
                else wr_col <= wr_col + 1;
            end
        end

        //---------------------------------------------------------
        // READ: column-major 출력 (원래 코드와 동일)
        //---------------------------------------------------------
        ST_READ: begin
            do_en <= 1'b1;

            // column-major address = rd_row * N + rd_col
            do_re <= mem_re[rd_row*N + rd_col];
            do_im <= mem_im[rd_row*N + rd_col];

            // 첫 샘플에서만 doppler_start 펄스
            if (rd_row == 0 && rd_col == 0)
                doppler_start <= 1'b1;

            // column-major 증가
            if (rd_row == N-1) begin
                rd_row <= 0;
                if (rd_col == N-1) begin
                    rd_col <= 0;
                    state  <= ST_WRITE;
                end
                else rd_col <= rd_col + 1;
            end
            else rd_row <= rd_row + 1;
        end

        endcase
    end
end

endmodule
