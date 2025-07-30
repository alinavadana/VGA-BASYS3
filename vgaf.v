`timescale 1ns / 1ps
module vgaf(
    input  clk148,        // Ceas de 148.5 MHz pentru sincronizarea VGA
    input  rst_n,         // Reset activ HIGH 
    input  BTNU,          // Buton pentru 'jump'
    output wire h_sync,       // Semnal sincronizare orizontală VGA
    output wire v_sync,       // Semnal sincronizare verticală VGA
    output reg [3:0] red,     // Canal roșu pentru VGA (4 biți)
    output reg [3:0] green,   // Canal verde pentru VGA (4 biți)
    output reg [3:0] blue,    // Canal albastru pentru VGA (4 biți)
    output reg point_scored   // Semnal pentru punctaj 
);

    // ------------ Parametrii temporali VGA 1920x1080@60Hz ------------
    localparam H_PIXELS = 1920;    // Număr pixeli vizibili orizontal
    localparam H_FP     = 88;      // Front porch orizontal (pauză înainte de sync)
    localparam H_SYNC   = 44;      // Durata semnalului de sincronizare orizontală
    localparam H_BP     = 148;     // Back porch orizontal (pauză după sync)
    localparam H_TOTAL  = H_PIXELS + H_FP + H_SYNC + H_BP;  // Total pixeli pe linie (incluzând porțile)

    localparam V_LINES  = 1080;    // Număr linii vizibile vertical
    localparam V_FP     = 4;       // Front porch vertical
    localparam V_SYNC   = 5;       // Durata semnalului de sincronizare verticală
    localparam V_BP     = 36;      // Back porch vertical
    localparam V_TOTAL  = V_LINES + V_FP + V_SYNC + V_BP;   // Total linii pe cadru

    // ---------------- Registri pentru coordonate și stări ----------------
    reg [11:0] h_count = 0;  // Contor poziție orizontală pe linie (0...H_TOTAL-1)
    reg [11:0] v_count = 0;  // Contor poziție verticală pe cadru (0...V_TOTAL-1)

    reg [11:0] circle_y = 540;   // Poziția verticală a păsării
    reg [11:0] wall_x = H_PIXELS; // Poziția orizontală a obstacolului 
    reg [11:0] hole_y = 300;     // Poziția verticală a golului (locul pe unde trece păsarea)

    localparam HOLE_HEIGHT = 300; // Înălțimea golului în obstacol
    localparam CIRCLE_X = 200;    // Poziția orizontală fixă a păsării

    reg [21:0] gravity_cnt = 0;   // Contor pentru implementarea gravitației (întârziere)
    reg [21:0] wall_cnt = 0;      // Contor pentru mișcarea obstacolului (întârziere)

    reg jump_request = 0;          // Flag pentru săritură în curs
    reg [3:0] jump_counter = 0;    // Contor pentru durata săriturii
    reg prev_BTNU = 0;             // Salvare stare anterioară buton pentru detectare front crescător
    reg game_over = 0;             // Flag pentru stare joc pierdut

    wire visible = (h_count < H_PIXELS) && (v_count < V_LINES);  // Semnal că pixelul curent este pe zona vizibilă

    // ----------------- Detectarea coliziunii -----------------
    // Coliziune dacă păsarea este în zona obstacolului pe orizontală
    // și dacă nu este în gol pe verticală
    wire collision = (CIRCLE_X + 20 >= wall_x && CIRCLE_X - 20 <= wall_x + 80) &&
                     (circle_y - 20 < hole_y || circle_y + 20 > hole_y + HOLE_HEIGHT);

    // ------------ Contor orizontal (pe linie) ------------
    always @(posedge clk148 or posedge rst_n) begin
        if (rst_n)
            h_count <= 0;
        else if (h_count == H_TOTAL - 1)
            h_count <= 0;            // Resetează la sfârșitul liniei
        else
            h_count <= h_count + 1;  // Incrementare poziție pixel pe linie
    end

    // ------------ Contor vertical (pe cadru) ------------
    always @(posedge clk148 or posedge rst_n) begin
        if (rst_n)
            v_count <= 0;
        else if (h_count == H_TOTAL - 1) begin
            // La sfârșitul liniei incrementăm linia verticală
            if (v_count == V_TOTAL - 1)
                v_count <= 0;          // Resetează la sfârșitul cadrului
            else
                v_count <= v_count + 1;
        end
    end

    // ------------- Generare semnale sincronizare VGA -------------
    assign h_sync = (h_count >= H_PIXELS + H_FP && h_count < H_PIXELS + H_FP + H_SYNC);
    assign v_sync = (v_count >= V_LINES + V_FP && v_count < V_LINES + V_FP + V_SYNC);

    // ------------- Gestionare săritură (jump) -------------
    always @(posedge clk148 or posedge rst_n) begin
        if (rst_n) begin
            prev_BTNU <= 0;
            jump_request <= 0;
            jump_counter <= 0;
        end else begin
            prev_BTNU <= BTNU;  // Salvăm starea butonului de pe ceasul anterior

            if (BTNU && !prev_BTNU)
                jump_request <= 1;  // Detectăm front crescător (apasare buton) și cerem săritură

            if (jump_request) begin
                if (jump_counter <= 10)
                    jump_counter <= jump_counter + 1;  // Ținem săritura activă pentru câteva cicluri
                else begin
                    jump_counter <= 0;
                    jump_request <= 0;  // Final săritură
                end
            end
        end
    end

    // ------------ Contor pentru gravitație (întârziere cădere) ------------
always @(posedge clk148 or posedge rst_n) begin
        if (rst_n)
            gravity_cnt <= 0;
        else
            gravity_cnt <= gravity_cnt + 1;
    end

    // ------------- Mișcarea verticală a păsării -------------
    always @(posedge clk148 or posedge rst_n) begin
        if (rst_n)
            circle_y <= 270;  // Poziția inițială verticală
        else if (jump_request && jump_counter <= 10 && circle_y > 5)
            circle_y <= circle_y - 3;  // Săritură - urcă păsarea
        else if (!jump_request && gravity_cnt == 1_000_000 && circle_y < 1080)
            circle_y <= circle_y + 2;  // Gravitație - cade păsarea (la o anumită întârziere)
    end

    // ------------- Mișcarea obstacolului pe orizontală -------------
    always @(posedge clk148 or posedge rst_n) begin
        if (rst_n) begin
            wall_cnt <= 0;
            wall_x <= H_PIXELS;  // Obstacolul începe în dreapta ecranului
        end else if (!game_over) begin
            if (wall_cnt == 2_000_000) begin
                wall_cnt <= 0;
                if (wall_x > 0)
                    wall_x <= wall_x - 4;  // Mută obstacolul spre stânga
                else
                    wall_x <= H_PIXELS;    // Resetează la dreapta când iese din ecran
            end else begin
                wall_cnt <= wall_cnt + 1;
            end
        end
    end

    // ------------- Schimbă poziția golului în obstacol și punctaj -------------
    always @(posedge clk148 or posedge rst_n) begin
        if (rst_n) begin
            hole_y <= 300;         // Poziție inițială gol
            point_scored <= 0;     // Resetare semnal punctaj
        end else if (!game_over) begin
            if (wall_cnt == 2_000_000 && wall_x == 0) begin
                hole_y <= (hole_y == 300) ? 500 : 300;  // Alternăm poziția golului sus-jos
                point_scored <= 1;                       // Semnal că s-a trecut un obstacol (scor crescut)
            end else begin
                point_scored <= 0;
            end
        end else begin
            point_scored <= 0;  // Dacă jocul s-a terminat, nu se mai marchează puncte
        end
    end

    // ------------- Detectare coliziune și setare stare game over -------------
    always @(posedge clk148 or posedge rst_n) begin
        if (rst_n)
            game_over <= 0;
        else if (collision)
            game_over <= 1;  // Dacă detectăm coliziune, jocul se termină
    end

    // ------------- Generare culoare pixel curent (desenare) -------------
    always @(*) begin
        red = 0;
        green = 0;
        blue = 0;

        if (visible) begin
            if (game_over) begin
                // Ecran roșu când jocul e pierdut
                red = 4'b1111;
            end else begin
                // Desenare păsărică (cerc de 40x40 pixeli)
                if (h_count >= CIRCLE_X - 20 && h_count < CIRCLE_X + 20 &&
                    v_count >= circle_y - 20 && v_count < circle_y + 20) begin
                    // Ciocul păsării (zona portocalie)
                    if (h_count >= CIRCLE_X + 10 && h_count < CIRCLE_X + 20 &&
                        v_count >= circle_y - 5 && v_count < circle_y + 5) begin
                        red = 4'b1111;
                        green = 4'b1000;
                        blue = 4'b0000;
                    end else begin
                        // Corpul păsării (galben)
                        red = 4'b1111;
                        green = 4'b1111;
                        blue = 0;
                    end
                end

                // Desenare obstacol (perete de 80 pixeli latime)
                if (h_count >= wall_x && h_count < wall_x + 80) begin
                    // Zona obstacolului în afara golului devine cyan (verde + albastru)
                    if (v_count < hole_y || v_count > hole_y + HOLE_HEIGHT) begin
                        green = 4'b1111;
                        blue = 4'b1111;
                    end
                end
            end
        end
    end

endmodule
