module EdgeDetector (
    input clk,
    input rst,
    input in,
    output rising,
    output falling
);
    /**
     * Design assumptions: D is an offchip signal, there are no timing guarentees
     * 1. posedge clk, store last, compare current signal. Pros: no cycle lost, Cons: potential meta-stable state when D arrives very closely before clk. 
     * => 2. posedge clk, store last 2, output if last 2 dif. Pros: no meta-stability, Cons: 1 lost cycle need to be accounted. But not sampling/sending immediately anyways. 
     * 3. Use negedge clk, store last, compare current signal. Not sure how fpga will like this...
     */
    
    
    
    /*
    ila_2(.clk(clk), .probe0(data_D), .probe1(data_Q), .probe2(falling), .probe3(rising));
    wire [1:0] data_Q, data_D;
    
    assign falling = data_Q[1] & !data_Q[0];
    assign rising = !data_Q[1] & data_Q[0];
    assign data_D = {data_Q[0], in};
    //assign falling = data_Q[0];
    //assign rising = data_Q[1];
    
    RegInit #(.WIDTH(2), .INIT(0))
    data(
        .clk(clk), .rst(rst), .en(1),
        .D(data_D),
        .Q(data_Q)
    );
    */
    
    //ila_2(.clk(clk), .probe0(data), .probe1(in), .probe2(rising), .probe3(falling));
    reg data;
    always @(posedge clk) begin
        data <= in;
    end
    
    assign rising = (!data) && in;
    assign falling = data && (!in);
    

endmodule
