`timescale 1ns / 1ps

module shift_register_74194(
    input               clr,
    input  [1:0]        m,
    input               clk,
    input               d_sr,
    input               d_sl,
    input  [3:0]        d,
    output reg [3:0]    q
    );
    
    reg [25:0] counter;
    reg clk_1Hz;
    
    always @(posedge clk or negedge clr)    begin
        if (clr)    begin
            clk_1Hz <= 1'b0;
            counter <= 26'd0;
        end else    begin
            if (counter == 50_000_000 - 1)  begin
                clk_1Hz <= ~clk_1Hz;
                counter <= 26'd0;
            end else    begin
                counter <= counter + 1;
            end
        end
     end
    
    always @(posedge clk_1Hz or negedge clr)   begin
        if (clr)   begin
            q <= 4'b0000;
        end else begin
            case(m)
                2'b00: q <= q;
                2'b01: q <= {d_sr, q[3:1]};
                2'b10: q <= {q[2:0], d_sl};
                2'b11: q <= d;
                default: q <= q;
            endcase
        end
    end
        
endmodule
