module clock
    (input wire clk,
     input wire [4 : 0] button,
     // up 0 center 1 down 2 left 3 right 4
     input wire [1 : 0] sign,
     input wire alarm_sign,
     output reg [7 : 0] an,
     output reg [6 : 0] num,
     output reg [15 : 0] light);

    integer second_cnt = 100000000 - 1;
    integer flash = 25000000 - 1;
    integer cnt = 0;  // cnt form zero
    integer cnt_quick = 0;
    integer cnt_flash = 0;
    always @(posedge clk) begin  // 分频时钟计数
        if (cnt < second_cnt) begin
            cnt <= cnt + 1;
        end else begin
            cnt <= 0;
        end
        if (cnt_quick < 24999) begin
            cnt_quick <= cnt_quick + 1;
        end else begin
            cnt_quick <= 0;
        end
        if (cnt_flash < flash) begin
            cnt_flash <= cnt_flash + 1;
        end else begin
            cnt_flash <= 0;
        end
    end

    reg [2 : 0] digital = 3'd0;
    always @(posedge clk) begin  // 数位分频
        if (cnt_quick == 24999) begin
            if (digital == 3'b111) begin
                digital <= 0;
            end else begin
                digital <= digital + 1;
            end
        end else begin
        end
    end

    reg [4 : 0] button_d;
    reg [4 : 0] button_pro;
    integer delay = 0;
    always @(posedge clk) begin  // 防抖
        if (button_pro != button) begin
            delay <= delay + 1;
        end else begin
            delay <= 0;
        end
        if (delay == 99999) begin
            button_pro <= button;
        end else begin
        end
    end

    always @(posedge clk)
        button_d <= button_pro;

    wire [4 : 0] button_press;
    assign button_press = button_pro & ~button_d;  // 上升沿检测

    reg show_real_time = 1;
    always @(posedge clk) begin
        if (button_press[1]) begin
            show_real_time <= ~show_real_time;
        end else begin
        end
    end

    reg [4 : 0] hour = 5'd0;
    reg [5 : 0] min = 6'd0;
    reg [5 : 0] sec = 6'd1;
    always @(posedge clk) begin  // 时间累计+校时
        if (cnt == second_cnt) begin
            if (sec + 1 < 60) begin
                sec <= sec + 1;
            end else begin
                sec <= 0;
                if (min + 1 < 60) begin
                    min <= min + 1;
                end else begin
                    min <= 0;
                    if (hour + 1 < 24) begin
                        hour <= hour + 1;
                    end else begin
                        hour <= 0;
                    end
                end
            end
        end

        if (show_real_time) begin
            if (button_press[0]) begin
                if (sign[0] == 1) begin
                    if (hour + 1 < 24) begin
                        hour <= hour + 1;
                    end else begin
                        hour <= 0;
                    end
                end else begin
                end
                if (sign[1] == 1) begin
                    if (min + 1 < 60) begin
                        min <= min + 1;
                    end else begin
                        min <= 0;
                        if (hour + 1 < 24) begin
                            hour <= hour + 1;
                        end else begin
                            hour <= 0;
                        end
                    end
                end else begin
                end
            end

            if (button_press[2]) begin
                if (sign[0] == 1) begin
                    if (hour > 0) begin
                        hour <= hour - 1;
                    end else begin
                        hour <= 5'd23;
                    end
                end else begin
                end
                if (sign[1] == 1) begin
                    if (min > 0) begin
                        min <= min - 1;
                    end else begin
                        min <= 6'd59;
                    end
                end else begin
                end
            end
        end else begin
        end
    end

    reg [4 : 0] a_hour = 5'd23;
    reg [5 : 0] a_min = 6'd57;
    reg [5 : 0] a_sec = 6'd0;

    always @(posedge clk) begin
        if (!show_real_time) begin
            if (button_press[0]) begin
                if (sign[0] == 1) begin
                    if (a_hour + 1 < 24) begin
                        a_hour <= a_hour + 1;
                    end else begin
                        a_hour <= 0;
                    end
                end else begin
                end
                if (sign[1] == 1) begin
                    if (a_min + 1 < 60) begin
                        a_min <= a_min + 1;
                    end else begin
                        a_min <= 0;
                        if (a_hour + 1 < 24) begin
                            a_hour <= a_hour + 1;
                        end else begin
                            a_hour <= 0;
                        end
                    end
                end else begin
                end
            end

            if (button_press[2]) begin
                if (sign[0] == 1) begin
                    if (a_hour > 0) begin
                        a_hour <= a_hour - 1;
                    end else begin
                        a_hour <= 5'd23;
                    end
                end else begin
                end
                if (sign[1] == 1) begin
                    if (a_min > 0) begin
                        a_min <= a_min - 1;
                    end else begin
                        a_min <= 6'd59;
                    end
                end else begin
                end
            end
        end else begin
        end
    end

    // ========== 灯控部分 ==========
    reg light_on = 0;
    always @(posedge clk) begin
        if (cnt_flash == flash) begin
            light_on <= ~light_on;
        end
    end

    reg need_flash = 0;
    reg alarm_flash = 0;
    reg flag = 1;
    reg [3 : 0] flash_cnt = 0;
    reg light_prev = 0;

    always @(posedge clk) begin
        if (min == 0 && sec < 2)
            need_flash <= 1;
        else
            need_flash <= 0;

        if (hour == a_hour && min == a_min && flag && show_real_time) begin
            alarm_flash <= 1;
            flag <= 0;
        end else if (hour != a_hour || min != a_min) begin
            flag <= 1;
        end

        if (light_on && !light_prev) begin
            if (need_flash || alarm_flash) begin
                if (flash_cnt == 5) begin
                    flash_cnt <= 0;
                    if (alarm_flash)
                        alarm_flash <= 0;
                end else begin
                    flash_cnt <= flash_cnt + 1;
                end
            end
        end
        light_prev <= light_on;

        if (light_on && (need_flash || alarm_flash))
            light <= 16'hFFFF;
        else
            light <= 16'h0000;
    end

    // ========== BCD 转换 ==========
    reg [7 : 0] hour_bcd = 8'd0;
    reg [7 : 0] min_bcd = 8'd0;
    reg [7 : 0] sec_bcd = 8'd0;
    integer i = 0;
    always @(*) begin  // hour bcd
        hour_bcd = 8'd0;
        if (show_real_time) begin
            for (i = 0; i < 5; i = i + 1) begin
                if (hour_bcd[7 : 4] >= 5)
                    hour_bcd[7 : 4] = hour_bcd[7 : 4] + 3;
                if (hour_bcd[3 : 0] >= 5)
                    hour_bcd[3 : 0] = hour_bcd[3 : 0] + 3;
                hour_bcd = hour_bcd << 1;
                hour_bcd = hour_bcd + hour[4 - i];
            end
        end else begin
            for (i = 0; i < 5; i = i + 1) begin
                if (hour_bcd[7 : 4] >= 5)
                    hour_bcd[7 : 4] = hour_bcd[7 : 4] + 3;
                if (hour_bcd[3 : 0] >= 5)
                    hour_bcd[3 : 0] = hour_bcd[3 : 0] + 3;
                hour_bcd = hour_bcd << 1;
                hour_bcd = hour_bcd + a_hour[4 - i];
            end
        end
    end
    always @(*) begin  // min bcd
        min_bcd = 8'd0;
        if (show_real_time) begin
            for (i = 0; i < 6; i = i + 1) begin
                if (min_bcd[7 : 4] >= 5)
                    min_bcd[7 : 4] = min_bcd[7 : 4] + 3;
                if (min_bcd[3 : 0] >= 5)
                    min_bcd[3 : 0] = min_bcd[3 : 0] + 3;
                min_bcd = min_bcd << 1;
                min_bcd = min_bcd + min[5 - i];
            end
        end else begin
            for (i = 0; i < 6; i = i + 1) begin
                if (min_bcd[7 : 4] >= 5)
                    min_bcd[7 : 4] = min_bcd[7 : 4] + 3;
                if (min_bcd[3 : 0] >= 5)
                    min_bcd[3 : 0] = min_bcd[3 : 0] + 3;
                min_bcd = min_bcd << 1;
                min_bcd = min_bcd + a_min[5 - i];
            end
        end
    end
    always @(*) begin  // sec bcd
        sec_bcd = 8'd0;
        if (show_real_time) begin
            for (i = 0; i < 6; i = i + 1) begin
                if (sec_bcd[7 : 4] >= 5)
                    sec_bcd[7 : 4] = sec_bcd[7 : 4] + 3;
                if (sec_bcd[3 : 0] >= 5)
                    sec_bcd[3 : 0] = sec_bcd[3 : 0] + 3;
                sec_bcd = sec_bcd << 1;
                sec_bcd = sec_bcd + sec[5 - i];
            end
        end else begin
            for (i = 0; i < 6; i = i + 1) begin
                if (sec_bcd[7 : 4] >= 5)
                    sec_bcd[7 : 4] = sec_bcd[7 : 4] + 3;
                if (sec_bcd[3 : 0] >= 5)
                    sec_bcd[3 : 0] = sec_bcd[3 : 0] + 3;
                sec_bcd = sec_bcd << 1;
                sec_bcd = sec_bcd + a_sec[5 - i];
            end
        end
    end

    reg [3 : 0] curr_num = 4'd0;

    // ========== 数码管显示（加入闹钟设置闪烁） ==========
    always @(*) begin
        case (digital)  // 最右侧为digital 0
            3'b000: begin
                an = 8'b11111110;
                curr_num = sec_bcd[3 : 0];
            end
            3'b001: begin
                an = 8'b11111101;
                curr_num = sec_bcd[7 : 4];
            end
            3'b010: begin
                an = 8'b11111011;
                curr_num = 4'b1111;
            end  // 代表小短横线
            3'b011: begin
                an = 8'b11110111;
                curr_num = min_bcd[3 : 0];
            end
            3'b100: begin
                an = 8'b11101111;
                curr_num = min_bcd[7 : 4];
            end
            3'b101: begin
                an = 8'b11011111;
                curr_num = 4'b1111;
            end
            3'b110: begin
                an = 8'b10111111;
                curr_num = hour_bcd[3 : 0];
            end
            3'b111: begin
                an = 8'b01111111;
                curr_num = hour_bcd[7 : 4];
            end
            default: begin
                an = 8'b11111111;
                curr_num = 4'b1111;
            end
        endcase
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

        // ======== 闹钟设置时数码管闪烁 ========
        if (!show_real_time) begin
            // 小时位 (digital 6,7) 根据 sign[0] 闪烁
            // 分钟位 (digital 3,4) 根据 sign[1] 闪烁
            if ((sign[0] && (digital == 3'b110 || digital == 3'b111)) ||
                (sign[1] && (digital == 3'b011 || digital == 3'b100))) begin
                if (!light_on)  // 复用 LED 闪烁分频，低电平时熄灭
                    num = 7'b1111111;
            end
        end
    end
endmodule
