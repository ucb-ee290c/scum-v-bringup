module RegInit #(
    parameter WIDTH = 8,
    parameter INIT = 0
) (
    input clk,
    input rst,
    input en,
    input [WIDTH-1:0] D,
    output [WIDTH-1:0] Q
);
    reg [WIDTH-1:0] data;
    assign Q = data;
    always @(posedge clk) begin
        data <= rst ? INIT : (en ? D : Q); 
    end

endmodule
