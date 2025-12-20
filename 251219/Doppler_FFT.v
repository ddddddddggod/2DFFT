//----------------------------------------------------------------------
//  FFT: 128-Point FFT Using Radix-2^2 Single-Path Delay Feedback
//  Module: Doppler_FFT (Signed-safe version)
//----------------------------------------------------------------------

module Doppler_FFT #(
    parameter WIDTH = 16
)(
    input                    clock,  // Master Clock
    input                    reset,  // Active High Asynchronous Reset
    input                    di_en,  // Input Data Enable

    // Signed FFT Input
    input  signed [WIDTH-1:0] di_re,  // Input Data (Real)
    input  signed [WIDTH-1:0] di_im,  // Input Data (Imag)

    // Signed FFT Output
    output                   do_en,  // Output Data Enable
    output signed [WIDTH-1:0] do_re,  // Output Data (Real)
    output signed [WIDTH-1:0] do_im   // Output Data (Imag)
);

//----------------------------------------------------------------------
//  Internal Wires (SIGNED)
//----------------------------------------------------------------------

wire             su1_do_en;
wire signed [WIDTH-1:0] su1_do_re;
wire signed [WIDTH-1:0] su1_do_im;

wire             su2_do_en;
wire signed [WIDTH-1:0] su2_do_re;
wire signed [WIDTH-1:0] su2_do_im;

wire             su3_do_en;
wire signed [WIDTH-1:0] su3_do_re;
wire signed [WIDTH-1:0] su3_do_im;

//----------------------------------------------------------------------
//  SDF Stages
//----------------------------------------------------------------------

SdfUnit #(.N(128), .M(128), .WIDTH(WIDTH)) SU1 (
    .clock  (clock),
    .reset  (reset),
    .di_en  (di_en),
    .di_re  (di_re),
    .di_im  (di_im),
    .do_en  (su1_do_en),
    .do_re  (su1_do_re),
    .do_im  (su1_do_im)
);

SdfUnit #(.N(128), .M(32), .WIDTH(WIDTH)) SU2 (
    .clock  (clock),
    .reset  (reset),
    .di_en  (su1_do_en),
    .di_re  (su1_do_re),
    .di_im  (su1_do_im),
    .do_en  (su2_do_en),
    .do_re  (su2_do_re),
    .do_im  (su2_do_im)
);

SdfUnit #(.N(128), .M(8), .WIDTH(WIDTH)) SU3 (
    .clock  (clock),
    .reset  (reset),
    .di_en  (su2_do_en),
    .di_re  (su2_do_re),
    .di_im  (su2_do_im),
    .do_en  (su3_do_en),
    .do_re  (su3_do_re),
    .do_im  (su3_do_im)
);

//----------------------------------------------------------------------
//  Final Stage (No Twiddle)
//----------------------------------------------------------------------

SdfUnit2 #(.WIDTH(WIDTH)) SU4 (
    .clock  (clock),
    .reset  (reset),
    .di_en  (su3_do_en),
    .di_re  (su3_do_re),
    .di_im  (su3_do_im),
    .do_en  (do_en),
    .do_re  (do_re),
    .do_im  (do_im)
);

endmodule
