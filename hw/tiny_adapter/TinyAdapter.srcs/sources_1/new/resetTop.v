/* Resets dut and then chip each for the amount of seconds specified by parameter. */
module resetTop #(
    parameter TIME = 50_000_000
) (
    input clk,
    input trigger,
    output dutReset
);
    /* State machine: 
     * trigger which begins the counter
     * counter_Q will begin counting as long as it's non-zero
     * chipReset will be high when counter is non-zero.
     * dutReset will come high, resetting the counter to 0,
     * 
     */
    
    //ila_3(.clk(clk), .probe0(0), .probe1(counter_Q), .probe2(dutReset), .probe3(selfReset), .probe4(trigger), .probe5(0)); 
    wire [32-1:0] counter_Q;
    wire selfReset;
    assign selfReset = counter_Q > TIME;
    assign dutReset = counter_Q > 0;
    
    RegInit #(.WIDTH(32), .INIT(0))
    counter(
        .clk(clk), .rst(selfReset), .en((counter_Q > 0) || trigger),
        .D(counter_Q + 1'b1),
        .Q(counter_Q)
    );
endmodule
