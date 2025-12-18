`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DigilentInc
// Engineer: Arthur Brown (Modified for Arty Z7 125MHz by User)
// 
// Module Name: Pmod_SPI
// Description: SPI Controller for Pmod AD1
//              Target Board: Arty Z7 (125MHz System Clock)
//////////////////////////////////////////////////////////////////////////////////

module Pmod_SPI (
    input  wire        clk,
    input  wire        rst,
    output wire        cs,
    input  wire        sdin0,
    input  wire        sdin1,
    output wire        sclk,
    output reg         drdy = 0,      // Data Ready Pulse
    output reg [15:0]  dout0 = 0,     // ADC Data Channel 0
    output reg [15:0]  dout1 = 0      // ADC Data Channel 1
);

    // ===========================================================================
    // Parameters for 125MHz System Clock (Arty Z7)
    // ===========================================================================
    // SCLK Frequency = System_Clock / CLOCKS_PER_BIT
    // 125MHz / 12 ~= 10.4 MHz (AD7476A Max SCLK is 20MHz)
    parameter CLOCKS_PER_BIT = 12; 
    
    // CS High Time (Quiet time between samples)
    parameter CLOCKS_BETWEEN_TRANSACTIONS = 400; 
    
    // Setup time before first bit
    parameter CLOCKS_BEFORE_DATA = 60;
    
    // Hold time after last bit
    parameter CLOCKS_AFTER_DATA = 100;

    // Constants
    localparam BITS_PER_TRANSACTION = 16;
    localparam BIT_HALFWAY_CLOCK = CLOCKS_PER_BIT >> 1;

    // ===========================================================================
    // FSM States
    // ===========================================================================
    localparam S_HOLD        = 0; 
    localparam S_FRONT_PORCH = 1; 
    localparam S_SHIFTING    = 2; 
    localparam S_BACK_PORCH  = 3; 
        
    reg [1:0] state = S_HOLD;
    reg [31:0] count0 = 0;
    reg [31:0] count1 = 0;
    reg [15:0] shft0 = 0;
    reg [15:0] shft1 = 0;
    
    // CS is Active Low (Logic handles it as: High in HOLD, Low otherwise)
    // But Pmod AD1 CS is active Low. 
    // Here: state == S_HOLD -> cs = 1 (Idle), else cs = 0 (Active) -> Correct.
    assign cs = (state == S_HOLD) ? 1'b1 : 1'b0;
    
    // SCLK Generation: Only active during shifting
    assign sclk = (state == S_SHIFTING && count0 <= BIT_HALFWAY_CLOCK-1) ? 1'b0 : 1'b1;
    
    // ===========================================================================
    // Main Logic
    // ===========================================================================
    always @(posedge clk) begin
        if (rst == 1'b1) begin
            drdy   <= 0;
            dout0  <= 0;
            dout1  <= 0;
            state  <= S_HOLD;
            count0 <= 0;
            count1 <= 0;
            shft0  <= 0;
            shft1  <= 0;
        end else begin
            case (state)
                // 1. Idle State (CS High)
                S_HOLD: begin
                    if (count0 == CLOCKS_BETWEEN_TRANSACTIONS-1) begin
                        state  <= S_FRONT_PORCH;
                        count0 <= 0;
                    end else begin
                        count0 <= count0 + 1;
                    end
                end

                // 2. Chip Select goes Low, wait for setup
                S_FRONT_PORCH: begin
                    if (count0 == CLOCKS_BEFORE_DATA-1) begin
                        state  <= S_SHIFTING;
                        count0 <= 0;
                        count1 <= 0;
                        shft0  <= 0;
                        shft1  <= 0;
                    end else begin
                        count0 <= count0 + 1;
                    end
                end

                // 3. Shift Data Bits (16 bits)
                S_SHIFTING: begin
                    if (count0 == CLOCKS_PER_BIT-1) begin
                        count0 <= 0;
                        if (count1 == BITS_PER_TRANSACTION-1) begin
                            // Latch Data to Output
                            dout0 <= shft0;
                            dout1 <= shft1;
                            drdy  <= 1; // Signal Data Ready
                            state <= S_BACK_PORCH;
                        end else begin
                            count1 <= count1 + 1;
                        end
                    end else begin
                        count0 <= count0 + 1;
                        // Sample data at the halfway point (Falling edge of SCLK effectively)
                        if (count0 == BIT_HALFWAY_CLOCK-1) begin
                            shft0 <= {shft0[14:0], sdin0}; // MSB first shift
                            shft1 <= {shft1[14:0], sdin1};
                        end
                    end
                end

                // 4. Hold CS Low for a bit longer, then return to Idle
                S_BACK_PORCH: begin
                    if (count0 == CLOCKS_AFTER_DATA-1) begin
                        count0 <= 0;
                        drdy   <= 0;
                        state  <= S_HOLD;
                    end else begin
                        count0 <= count0 + 1;
                    end
                end
            endcase
        end
    end
        
endmodule
