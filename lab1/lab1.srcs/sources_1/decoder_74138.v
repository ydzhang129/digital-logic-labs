`timescale 1ns / 1ps

module decoder_74138(
    input   [2:0]       a_n,
    input               s_a, s_b, s_c,
    output  reg [7:0]   y_n
    );
    
    wire enabled;
    assign enabled = (s_a == 1) && (s_b == 0) && (s_c == 0);
    
    always @(*) begin
        if (!enabled)   y_n = 8'b11111111;
        else begin
            case (a_n)
                3'b000: y_n = 8'b1111_1110; 
                3'b001: y_n = 8'b1111_1101;
                3'b010: y_n = 8'b1111_1011;
                3'b011: y_n = 8'b1111_0111; 
                3'b100: y_n = 8'b1110_1111; 
                3'b101: y_n = 8'b1101_1111;
                3'b110: y_n = 8'b1011_1111; 
                3'b111: y_n = 8'b0111_1111;
                default: y_n = 8'b1111_1111;
            endcase
        end
    end

endmodule
