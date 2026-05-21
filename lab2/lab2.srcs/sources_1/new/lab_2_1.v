module mul
    (input wire clk,
     input wire [7 : 0] x,
     input wire [7 : 0] y,
     output reg [7 : 0] an,
     output reg [6 : 0] num);

    wire sign = x[7] ^ y[7];
    wire [6 : 0] x_unsign, y_unsign;
    assign x_unsign = x[6 : 0],
           y_unsign = y[6 : 0];
    wire [13 : 0] mul_result;
    assign mul_result = x_unsign * y_unsign;

    reg [15 : 0] cnt = 16'd0;
    always @(posedge clk) begin
        if (cnt == 24999) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1;
        end
    end

    reg [19 : 0] bcd;
    reg [33 : 0] tmp;
    integer i, j;
    always @(*) begin
        tmp = {20'd0, mul_result};
        for (i = 0; i < 14; i = i + 1) begin
            // 调整: 每一位>4就加3
            if (tmp[33 : 30] > 4)
                tmp[33 : 30] = tmp[33 : 30] + 4'd3;
            if (tmp[29 : 26] > 4)
                tmp[29 : 26] = tmp[29 : 26] + 4'd3;
            if (tmp[25 : 22] > 4)
                tmp[25 : 22] = tmp[25 : 22] + 4'd3;
            if (tmp[21 : 18] > 4)
                tmp[21 : 18] = tmp[21 : 18] + 4'd3;
            if (tmp[17 : 14] > 4)
                tmp[17 : 14] = tmp[17 : 14] + 4'd3;
            // 左移
            tmp = tmp << 1;
        end
        bcd = tmp[33 : 14];
    end

    reg [2 : 0] max_digital = 3'd0;
    reg found;
    always @(*) begin
        max_digital = 3'd0;
        found = 1'b0;
        for (j = 4; j >= 0; j = j - 1) begin
            if (!found && (bcd[j * 4 +: 4] != 4'b0000)) begin
                max_digital = j[2 : 0];
                found = 1'b1;  // 找到最高位后锁住，低位不再更新
            end
        end
    end

    reg [2 : 0] digital = 3'd0;
    always @(posedge clk) begin
        if (cnt == 24999) begin
            if (digital == max_digital + 3'b001) begin
                digital <= 3'b000;
            end else begin
                digital <= digital + 1;
            end
        end else begin
            digital <= digital;
        end
    end

    reg [3 : 0] curr_num;
    always @(*) begin
        case (digital)
            3'b000: begin
                an = 8'b11111110;
                curr_num = bcd[3 : 0];
            end
            3'b001: begin
                an = 8'b11111101;
                curr_num = bcd[7 : 4];
            end
            3'b010: begin
                an = 8'b11111011;
                curr_num = bcd[11 : 8];
            end
            3'b011: begin
                an = 8'b11110111;
                curr_num = bcd[15 : 12];
            end
            3'b100: begin
                an = 8'b11101111;
                curr_num = bcd[19 : 16];
            end
            default: begin
                an = 8'b11111111;
                curr_num = bcd[3 : 0];
            end
        endcase
        if (digital == max_digital + 3'b001 && sign == 1 && bcd != 20'b0) begin
            curr_num = 4'b1111;  // 负号
        end else if (digital == max_digital + 3'b001) begin
            curr_num = 4'b1110;
        end
        case (curr_num)
            4'b0000:
                num = 7'b1000000;  // 0
            4'b0001:
                num = 7'b1111001;  // 1
            4'b0010:
                num = 7'b0100100;  // 2
            4'b0011:
                num = 7'b0110000;  // 3
            4'b0100:
                num = 7'b0011001;  // 4
            4'b0101:
                num = 7'b0010010;  // 5
            4'b0110:
                num = 7'b0000010;  // 6
            4'b0111:
                num = 7'b1111000;  // 7
            4'b1000:
                num = 7'b0000000;  // 8
            4'b1001:
                num = 7'b0010000;  // 9
            4'b1111:
                num = 7'b0111111;  //-
            default:
                num = 7'b1111111;
        endcase
    end
endmodule