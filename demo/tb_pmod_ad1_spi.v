//pmod_spi모듈만 잘 나오는지 테스트 하는 모듈
`timescale 1ns/1ps

module tb_pmod_ad1_spi;

    reg clk = 0;
    reg rst = 1;

    wire cs;
    wire sclk;
    reg  sdin0;
    reg  sdin1;

    wire drdy;
    wire [15:0] dout0;
    wire [15:0] dout1;

    // -------------------------------
    //  DUT: PMOD AD1 SPI Driver
    // -------------------------------
    Pmod_SPI #(
        .CLOCKS_PER_BIT(10),       // 10 -> sclk = 50MHz/10 = 5MHz
        .CLOCKS_BEFORE_DATA(30),
        .CLOCKS_AFTER_DATA(200),
        .CLOCKS_BETWEEN_TRANSACTIONS(200)
    ) dut (
        .clk(clk),
        .rst(rst),
        .cs(cs),
        .sdin0(sdin0),
        .sdin1(sdin1),
        .sclk(sclk),
        .drdy(drdy),
        .dout0(dout0),
        .dout1(dout1)
    );

    // -------------------------------
    // Clock generation (50MHz)
    // -------------------------------
    always #10 clk = ~clk;    // 20ns → 50MHz

    // -------------------------------
    // Fake ADC Model (AD7476A behavior)
    // -------------------------------
    reg [15:0] fake_ch0;
    reg [15:0] fake_ch1;
    integer bitcnt;

    // CS falling → start shift new frame
    always @(negedge cs) begin
        fake_ch0 = {4'h0, 12'h5A5};   // ADC sample (example)
        fake_ch1 = {4'h0, 12'hA3C};
        bitcnt   = 0;
    end

    // SPI: sample SDIN at rising edge of SCLK
    always @(posedge sclk) begin
        if (!cs) begin
            sdin0 <= fake_ch0[15 - bitcnt];
            sdin1 <= fake_ch1[15 - bitcnt];
            bitcnt <= bitcnt + 1;
        end
    end

    // -------------------------------
    // Simulation run
    // -------------------------------
    initial begin
        $dumpfile("pmod_test.vcd");
        $dumpvars(0, tb_pmod_ad1_spi);

        #200 rst = 0;    // release reset
        #20000 $finish;
    end

endmodule
