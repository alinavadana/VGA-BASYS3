module clk(
    input  clk,      // 100 MHz de pe Basys3
    input  rst_n,
    output  clk25    // 25 MHz pentru VGA
);
    reg [1:0] clkdiv;
    always @(posedge clk or posedge rst_n)
        if (rst_n)
            clkdiv <= 0;
        else
            clkdiv <= clkdiv + 1;

    assign clk25 = (~|clkdiv);
endmodule