module tsiToUart #(
    parameter SYSCLK = 100_000_000,
    parameter WIDTH = 123,
    parameter BAUD = 2_000_000
) (
    input clk,
    input rst,
    output uart_tx,
    input tl_rising_clk,
    output tl_in_rd,
    input tl_in_data,
    input tl_in_valid
);
    //ila_3(.clk(clk), .probe0(packet_counter_Q), .probe1(countdown_Q), .probe2(uart_fire), .probe3(uart_idle), .probe4(tl_in_rd), .probe5(uart_tx));
    localparam BAUD_CYCLE = SYSCLK / BAUD;
    localparam BYTE_WIDTH = (WIDTH-1)/8 + 1;
    wire [4-1:0] packet_counter_Q;
    wire [16-1:0] countdown_Q;
    wire uart_fire, uart_idle, sreg_isOut, sreg_out;
    assign uart_tx = (packet_counter_Q == 0) ? uart_idle : ((packet_counter_Q == 9) ? 1'b1 : sreg_out);
    assign uart_fire = (countdown_Q == BAUD_CYCLE);
    assign tl_in_rd = !sreg_isOut || (sreg_isOut && tl_in_valid);
    assign uart_idle = (packet_counter_Q == 0) && !sreg_isOut && (countdown_Q == 16'd0);

    RegInit #(.WIDTH(4), .INIT(0)) 
    packet_counter(
        .clk(clk), .rst(rst || uart_idle || ((packet_counter_Q == 9) && uart_fire)), .en(uart_fire),
        .D(packet_counter_Q + 1'b1),
        .Q(packet_counter_Q)
    );
    RegInit #(.WIDTH(16), .INIT(0)) 
    countdown(
        .clk(clk), .rst(rst || uart_fire || uart_idle), .en(1),
        .D(countdown_Q + 1'b1),
        .Q(countdown_Q)
    );
    shiftReg #(.IN_WIDTH(WIDTH), .OUT_WIDTH(BYTE_WIDTH*8), .D_WIDTH(BYTE_WIDTH*8)) 
    sreg0(
        .clk(clk), .rst(rst), 
        .en(sreg_isOut ? (uart_fire && !((packet_counter_Q == 0) || (packet_counter_Q == 9))) : (tl_rising_clk & tl_in_valid)), 
        .D(tl_in_data),

        .mode(sreg_isOut), // 0: shifting in, 1: shifting out
        .Q(sreg_out)
    );

endmodule