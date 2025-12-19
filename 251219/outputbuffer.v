`timescale 1ns / 1ps

module output_buffer #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 14  // 128 * 128 = 16,384
)(
    input wire clk,
    // Port A: FFT Write
    input wire we_a,
    input wire [ADDR_WIDTH-1:0] addr_a,
    input wire [DATA_WIDTH-1:0] din_a,
    
    // Port B: SPI Read
    input wire [ADDR_WIDTH-1:0] addr_b,
    output reg [DATA_WIDTH-1:0] dout_b
);

    // BRAM 리소스를 사용하도록 강제하는 attribute (선택 사항)
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    // Write Logic (Port A)
    always @(posedge clk) begin
        if (we_a) begin
            ram[addr_a] <= din_a;
        end
    end

    // Read Logic (Port B)
    always @(posedge clk) begin
        dout_b <= ram[addr_b];
    end

endmodule 
