module top( 
    input  clk,
    input   rst_n,
    input   BTNU,
    output  h_sync,
    output  v_sync,
    output  wire [3:0] red,
    output wire [3:0] green,
    output wire [3:0] blue,
    output [3:0] an,
output [6:0] seg
);

    wire clk_148_5;
    wire point_scored;

 design_1_wrapper clk148_5
   (
   .clk_in1_0(clk),
    .clk_out1_0(clk_148_5),
    .reset_0(rst_n)
    );

    vgaf vga_inst (
        .clk148(clk_148_5),
        .rst_n(rst_n),
        .BTNU(BTNU),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .red(red),
        .green(green),
        .blue(blue),
        .point_scored(point_scored)  );
        
        score scor_inst(
    .clk148(clk_148_5),         
    .rst_n(rst_n),
    .point(point_scored),
    .an(an),
    .seg(seg)
);
         
endmodule
