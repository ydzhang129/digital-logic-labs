`timescale 1ns / 1ps

module data_selector_74151(
    input [7:0] d,
    input [2:0] a,
    input       en_n,
    output reg  y,
    output      y_n
    );
    
    assign y_n = ~y;
    
    always @(*) begin
        if (en_n)   begin
            y = 0;
        end    else begin
            case (a)
                3'b000: y = d[0];
                3'b001: y = d[1];
                3'b010: y = d[2];
                3'b011: y = d[3];
                3'b100: y = d[4];
                3'b101: y = d[5];
                3'b110: y = d[6];
                3'b111: y = d[7];
                default: y = 0;
            endcase
        end
    end
            
endmodule
