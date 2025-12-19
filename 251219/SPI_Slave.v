
module SPI_Slave (
    input  wire        clk,        // 시스템 클럭
    input  wire        rst,        // 리셋
    input  wire        spi_cs,     // CS (Active Low)
    input  wire        spi_sclk,   // SCLK
    input  wire        spi_mosi,   // MOSI (주소 수신용)
    output reg         spi_miso,   // MISO (데이터 송신용)
    output wire [13:0] addr_out,   // 메모리로 보낼 주소
    input  wire [31:0] data_in     // 메모리에서 읽어온 데이터
);
    reg [5:0]  bit_cnt;
    reg [15:0] addr_reg;
    reg [31:0] shift_reg;

    assign addr_out = addr_reg[13:0];

    // 1. MOSI를 통해 주소 수신 (SPI Mode 0: Rising Edge에서 샘플링)
    always @(posedge spi_sclk or posedge spi_cs) begin
        if (spi_cs) begin
            bit_cnt <= 0;
            addr_reg <= 0;
        end else begin
            if (bit_cnt < 16) begin
                addr_reg <= {addr_reg[14:0], spi_mosi};
                bit_cnt  <= bit_cnt + 1;
            end else if (bit_cnt < 48) begin
                bit_cnt  <= bit_cnt + 1;
            end
        end
    end

    // 2. MISO를 통해 데이터 송신 (Falling Edge에서 데이터 변경)
    always @(negedge spi_sclk or posedge spi_cs) begin
        if (spi_cs) begin
            shift_reg <= data_in;
            spi_miso  <= data_in[31];
        end else begin
            if (bit_cnt >= 16) begin // 16비트 주소 수신 후 데이터 시프트 시작
                shift_reg <= {shift_reg[30:0], 1'b0};
                spi_miso  <= shift_reg[30];
            end else begin
                spi_miso  <= data_in[31]; // 대기 중에는 MSB 유지
                shift_reg <= data_in;
            end
        end
    end
endmodule
