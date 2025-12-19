//----------------------------------------------------------------------
//  SdfUnit2: Radix-2 SDF Dedicated for Twiddle Resolution M = 2
//  ? 구조 동일
//  ? 수정: signed 포트 + x → 0
//----------------------------------------------------------------------

module SdfUnit2 #(
    parameter   WIDTH = 16, //  Data Bit Length
    parameter   BF_RH = 0   //  Butterfly Round Half Up
)(
    input                   clock,  //  Master Clock
    input                   reset,  //  Active High Asynchronous Reset
    input                   di_en,  //  Input Data Enable

    // ★ signed input
    input  signed [WIDTH-1:0] di_re,  //  Input Data (Real)
    input  signed [WIDTH-1:0] di_im,  //  Input Data (Imag)

    output  reg              do_en,  //  Output Data Enable

    // ★ signed output
    output  reg signed [WIDTH-1:0] do_re,  //  Output Data (Real)
    output  reg signed [WIDTH-1:0] do_im   //  Output Data (Imag)
);

//----------------------------------------------------------------------
//  Internal Regs and Nets (변경 없음)
//----------------------------------------------------------------------
reg             bf_en;      //  Butterfly Add/Sub Enable
wire [WIDTH-1:0] x0_re;
wire [WIDTH-1:0] x0_im;
wire [WIDTH-1:0] x1_re;
wire [WIDTH-1:0] x1_im;
wire [WIDTH-1:0] y0_re;
wire [WIDTH-1:0] y0_im;
wire [WIDTH-1:0] y1_re;
wire [WIDTH-1:0] y1_im;
wire [WIDTH-1:0] db_di_re;
wire [WIDTH-1:0] db_di_im;
wire [WIDTH-1:0] db_do_re;
wire [WIDTH-1:0] db_do_im;
wire [WIDTH-1:0] bf_sp_re;
wire [WIDTH-1:0] bf_sp_im;
reg              bf_sp_en;

//----------------------------------------------------------------------
//  Butterfly Add/Sub
//----------------------------------------------------------------------
always @(posedge clock or posedge reset) begin
    if (reset) begin
        bf_en <= 1'b0;
    end else begin
        bf_en <= di_en ? ~bf_en : 1'b0;
    end
end

// ★★★ FIX: {WIDTH{1'bx}} → {WIDTH{1'b0}} ★★★
assign  x0_re = bf_en ? db_do_re : {WIDTH{1'b0}};
assign  x0_im = bf_en ? db_do_im : {WIDTH{1'b0}};
assign  x1_re = bf_en ? di_re    : {WIDTH{1'b0}};
assign  x1_im = bf_en ? di_im    : {WIDTH{1'b0}};

Butterfly #(.WIDTH(WIDTH),.RH(BF_RH)) BF (
    .x0_re  (x0_re  ),
    .x0_im  (x0_im  ),
    .x1_re  (x1_re  ),
    .x1_im  (x1_im  ),
    .y0_re  (y0_re  ),
    .y0_im  (y0_im  ),
    .y1_re  (y1_re  ),
    .y1_im  (y1_im  )
);

DelayBuffer #(.DEPTH(1),.WIDTH(WIDTH)) DB (
    .clock  (clock      ),
    .di_re  (db_di_re   ),
    .di_im  (db_di_im   ),
    .do_re  (db_do_re   ),
    .do_im  (db_do_im   )
);

assign  db_di_re = bf_en ? y1_re : di_re;
assign  db_di_im = bf_en ? y1_im : di_im;
assign  bf_sp_re = bf_en ? y0_re : db_do_re;
assign  bf_sp_im = bf_en ? y0_im : db_do_im;

always @(posedge clock or posedge reset) begin
    if (reset) begin
        bf_sp_en <= 1'b0;
        do_en    <= 1'b0;
    end else begin
        bf_sp_en <= di_en;
        do_en    <= bf_sp_en;
    end
end

always @(posedge clock) begin
    do_re <= bf_sp_re;
    do_im <= bf_sp_im;
end

endmodule
