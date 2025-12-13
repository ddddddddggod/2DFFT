`timescale 1ns / 1ps

module SPI_Slave (
    input  wire        clk,        // 시스템 클럭 (미사용)
    input  wire        rst,        // 리셋 (미사용)
    
    // SPI Interface
    input  wire        spi_cs,     // Active Low Chip Select
    input  wire        spi_sclk,   // Serial Clock
    output reg         spi_miso,   // MISO
    
    // Data
    input  wire [31:0] data_in
);

    reg [31:0] shift_reg;
    reg [5:0]  bit_cnt;

    // ★ 수정 핵심: 두 개로 나뉘어 있던 always 구문을 하나로 합쳤습니다.
    // SPI Mode 0: Master는 Rising Edge에서 읽음 -> Slave는 Falling에서 변경
    // CS가 High일 때(통신 안 할 때)를 '리셋 상태'로 봅니다.
    
    always @(negedge spi_sclk or posedge spi_cs) begin
        if (spi_cs) begin
            // 1. CS가 High일 때 (대기 상태)
            // 이때 데이터를 계속 로드해두고, 카운터를 0으로 잡고 있습니다.
            // CS가 Low로 떨어지는 순간 이 값들이 그대로 유지된 채 통신이 시작됩니다.
            bit_cnt   <= 0;
            shift_reg <= data_in;      // 최신 데이터 로드
            spi_miso  <= data_in[31];  // MSB 미리 준비
        end else begin
            // 2. CS가 Low이고, SCLK가 Falling Edge일 때 (동작 상태)
            if (bit_cnt < 31) begin
                bit_cnt   <= bit_cnt + 1;
                shift_reg <= {shift_reg[30:0], 1'b0}; // Shift Left
                spi_miso  <= shift_reg[30];           // 다음 비트 출력
            end
        end
    end

endmodule
