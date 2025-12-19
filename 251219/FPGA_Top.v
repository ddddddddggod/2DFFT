module FPGA_Top (
    input  wire CLK100MHZ,
    input  wire ck_rst,

    // PMOD AD1 Interface
    output wire JA1_CS,
    input  wire JA2_DATA0,
    input  wire JA3_DATA1,
    output wire JA4_SCLK,

    // Raspberry Pi SPI Interface (ChipKit Pins)
    input  wire ck_ss,   // IO10 (CS)
    input  wire ck_sck,  // IO13 (SCK)
    input  wire ck_mosi, // IO11 (MOSI) - 주소 전달용 추가
    output wire ck_miso, // IO12 (MISO)

    output wire [3:0] led
);

    wire sys_clk = CLK100MHZ;
    wire resetn = ~ck_rst;

    // FFT 모듈 출력 와이어
    wire        w_dbg_do_en;
    wire [15:0] w_dbg_do_re;
    wire [15:0] w_dbg_do_im;

    // FFT 모듈 인스턴스
    top_adc_fft2d u_logic (
        .clk50             (sys_clk),
        .resetn            (resetn),
        .JA1_CS            (JA1_CS),
        .JA2_DATA0         (JA2_DATA0),
        .JA3_DATA1         (JA3_DATA1),
        .JA4_SCLK          (JA4_SCLK),
        .dbg_do_en         (w_dbg_do_en),
        .dbg_do_re         (w_dbg_do_re),
        .dbg_do_im         (w_dbg_do_im)
        // ... (필요한 다른 포트 연결)
    );

    // 1. FFT 쓰기 주소 카운터 (14비트)
    reg [13:0] fft_wr_addr;
    always @(posedge sys_clk) begin
        if (~resetn) begin
            fft_wr_addr <= 0;
        end else if (w_dbg_do_en) begin
            fft_wr_addr <= fft_wr_addr + 1; // 16383 이후 0으로 자동 롤오버
        end
    end

    // 2. 128x128 Output Memory (Dual-Port)
    wire [13:0] rpi_rd_addr;
    wire [31:0] ram_data_out;

    output_buffer #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(14)
    ) u_mem (
        .clk    (sys_clk),
        .we_a   (w_dbg_do_en),
        .addr_a (fft_wr_addr),
        .din_a  ({w_dbg_do_re, w_dbg_do_im}), // 상위 16:Real, 하위 16:Imag
        .addr_b (rpi_rd_addr),
        .dout_b (ram_data_out)
    );

    // 3. SPI Slave (라즈베리 파이 통신)
    SPI_Slave u_spi (
        .clk      (sys_clk),
        .rst      (~resetn),
        .spi_cs   (ck_ss),
        .spi_sclk (ck_sck),
        .spi_mosi (ck_mosi),
        .spi_miso (ck_miso),
        .addr_out (rpi_rd_addr),
        .data_in  (ram_data_out)
    );

    assign led = {1'b0, !ck_ss, w_dbg_do_en, resetn};

endmodule
