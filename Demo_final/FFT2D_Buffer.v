//----------------------------------------------------------------------
// Module: FFT2D_Buffer (Transpose Buffer)
// Description: Fixed for Vivado Block RAM Inference.
//              Separates Control Logic from Memory Core.
//----------------------------------------------------------------------
module FFT2D_Buffer #(
    parameter WIDTH = 16
)(
    input               clock,
    input               reset,

    // Write Interface (Input from Range FFT)
    input               wr_en,
    input  [WIDTH-1:0]  wr_re,
    input  [WIDTH-1:0]  wr_im,

    // Read Interface (Output to Doppler FFT)
    output reg          rd_valid,
    output [WIDTH-1:0]  rd_re,
    output [WIDTH-1:0]  rd_im,

    // Debug Signals
    output reg          range_finish,
    output reg          doppler_start
);

    localparam N = 128;
    localparam TOTAL_SAMPLES = N * N; // 16,384
    localparam ADDR_BIT = 14;

    //------------------------------------------------------------------
    // 1. Control Logic (Address & State Machine)
    //------------------------------------------------------------------
    reg [ADDR_BIT-1:0] wr_addr;
    reg [ADDR_BIT-1:0] rd_addr_linear;
    wire [ADDR_BIT-1:0] rd_addr_trans;
    
    reg bank_sel_wr; // 0: Write Bank0, 1: Write Bank1
    reg rd_active;   // Read Enable Flag

    // Transpose Address Mapping
    assign rd_addr_trans = {rd_addr_linear[6:0], rd_addr_linear[13:7]};

    // --- Control Logic Block (With Reset) ---
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            wr_addr        <= 0;
            rd_addr_linear <= 0;
            bank_sel_wr    <= 0;
            rd_active      <= 0;
            rd_valid       <= 0;
            range_finish   <= 0;
            doppler_start  <= 0;
        end else begin
            // Pulse Reset
            range_finish   <= 0;
            doppler_start  <= 0;

            // Write Address Control
            if (wr_en) begin
                if (wr_addr == TOTAL_SAMPLES - 1) begin
                    wr_addr      <= 0;
                    bank_sel_wr  <= ~bank_sel_wr; // Toggle Write Bank
                    rd_active    <= 1'b1;         // Enable Read
                    
                    // Debug Pulses
                    range_finish <= 1'b1;
                    if (rd_active == 0) doppler_start <= 1'b1;
                end else begin
                    wr_addr      <= wr_addr + 1;
                end
            end

            // Read Address Control
            if (rd_active) begin
                rd_valid <= 1'b1;
                if (rd_addr_linear == TOTAL_SAMPLES - 1) begin
                    rd_addr_linear <= 0;
                end else begin
                    rd_addr_linear <= rd_addr_linear + 1;
                end
            end else begin
                rd_valid <= 0;
            end
        end
    end

    //------------------------------------------------------------------
    // 2. Memory Core (Strict BRAM Template - NO RESET HERE!)
    //------------------------------------------------------------------
    (* ram_style = "block" *) reg [WIDTH-1:0] mem_re_0 [0:TOTAL_SAMPLES-1];
    (* ram_style = "block" *) reg [WIDTH-1:0] mem_im_0 [0:TOTAL_SAMPLES-1];
    (* ram_style = "block" *) reg [WIDTH-1:0] mem_re_1 [0:TOTAL_SAMPLES-1];
    (* ram_style = "block" *) reg [WIDTH-1:0] mem_im_1 [0:TOTAL_SAMPLES-1];

    reg [WIDTH-1:0] dout_re_0, dout_im_0;
    reg [WIDTH-1:0] dout_re_1, dout_im_1;

    // Bank 0 Access
    always @(posedge clock) begin
        // Write Port (Bank 0 is written when bank_sel_wr == 0)
        if (wr_en && (bank_sel_wr == 0)) begin
            mem_re_0[wr_addr] <= wr_re;
            mem_im_0[wr_addr] <= wr_im;
        end
        // Read Port (Always read, Mux logic selects later)
        dout_re_0 <= mem_re_0[rd_addr_trans];
        dout_im_0 <= mem_im_0[rd_addr_trans];
    end

    // Bank 1 Access
    always @(posedge clock) begin
        // Write Port (Bank 1 is written when bank_sel_wr == 1)
        if (wr_en && (bank_sel_wr == 1)) begin
            mem_re_1[wr_addr] <= wr_re;
            mem_im_1[wr_addr] <= wr_im;
        end
        // Read Port
        dout_re_1 <= mem_re_1[rd_addr_trans];
        dout_im_1 <= mem_im_1[rd_addr_trans];
    end

    //------------------------------------------------------------------
    // 3. Output Mux Logic
    //------------------------------------------------------------------
    // If Write is on Bank 0, Read comes from Bank 1.
    // If Write is on Bank 1, Read comes from Bank 0.
    // (Pipelined Mux to match BRAM latency if needed, currently combinational after Reg)
    
    assign rd_re = (bank_sel_wr == 0) ? dout_re_1 : dout_re_0;
    assign rd_im = (bank_sel_wr == 0) ? dout_im_1 : dout_im_0;

endmodule
