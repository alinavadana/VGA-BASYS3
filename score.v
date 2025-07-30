`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: score
// Descriere: Modul pentru afișarea scorului pe un display cu 7 segmente cu 2 cifre.
//             Scorul crește când semnalul `point` este activ.
//             Se face multiplexare pentru două cifre (unități și zeci).
//////////////////////////////////////////////////////////////////////////////////

module score(
    input clk148,        // Clock de 148.5 MHz, folosit pentru refresh-ul display-ului
    input rst_n,         // Reset activ HIGH
    input point,         // Semnal pentru incrementarea scorului (când se marchează un punct)
    output reg [3:0] an, // Selectarea cifrei active (4 cifre, aici folosim doar 2)
    output reg [6:0] seg // Semnalele pentru cele 7 segmente ale cifrei active
);

    reg [7:0] score;          // Variabila pentru scor, poate ține valori de la 0 la 255 (noi folosim max 99)
    reg [3:0] digit;          // Cifra curentă ce va fi afișată (0-9)
    reg [16:0] refresh_cnt = 0;  // Contor pentru multiplexare (refresh display)
    reg digit_sel = 0;        // Selectează care cifră se afișează (0 = unități, 1 = zeci)
    
    // Creșterea scorului la semnalul point și resetarea la rst_n
    always @(posedge clk148 or posedge rst_n) begin
        if (rst_n) 
            score <= 0;  // La reset scorul revine la 0
        else if (point) begin
            if (score < 99) 
                score <= score + 1;  // Incrementează scorul până la 99
        end
    end
         
    // Contor pentru multiplexarea cifrelor afișajului 7 segmente
    always @(posedge clk148) begin
        refresh_cnt <= refresh_cnt + 1;
        if (refresh_cnt == 100_000) begin  // La aproximativ 0.673 ms (100000 / 148.5MHz)
            refresh_cnt <= 0;
            digit_sel <= ~digit_sel;        // Schimbă cifra activă (unități <-> zeci)
        end
    end
    
    // Logica pentru afișarea cifrei curente pe display
    always @(*) begin
        case (digit_sel)
            1'b0: begin
                digit = score % 10;   // Afișează cifra unităților
                an = 4'b1110;         // Activează primul anod (prima cifră)
            end
            1'b1: begin
                digit = score / 10;   // Afișează cifra zecilor
                an = 4'b1101;         // Activează al doilea anod (a doua cifră)
            end
        endcase

        // Codul pentru afișarea cifrei pe cele 7 segmente (common anode)
        // 0 aprinde toate segmentele în afară de g (7 segmente etichetate a-g)
        case (digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111; // Toate segmentele stinse
        endcase
    end

endmodule
