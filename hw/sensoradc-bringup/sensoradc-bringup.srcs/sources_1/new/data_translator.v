module data_translator #(
    parameter INPUT_WIDTH = 20,
    parameter OUTPUT_WIDTH = 8,
    parameter FIFO_DEPTH = 32,
    parameter MARKER_BYTE = 8'hAA
)(
    input clk,
    input rst,
    input [INPUT_WIDTH-1:0] data_in,
    input data_in_valid,
    output data_in_ready,
    output [OUTPUT_WIDTH-1:0] data_out,
    output data_out_valid,
    input data_out_ready
);

wire fifo_full, fifo_empty;
wire [INPUT_WIDTH-1:0] fifo_din;
wire [INPUT_WIDTH-1:0] fifo_dout;
wire fifo_wr_en, fifo_rd_en;

reg data_in_valid_sync_1;
reg data_in_valid_sync_2;

always @(posedge clk) begin
    if (rst) begin
        data_in_valid_sync_1 <= 1'b0;
        data_in_valid_sync_2 <= 1'b0;
    end else begin
        data_in_valid_sync_1 <= data_in_valid;
        data_in_valid_sync_2 <= data_in_valid_sync_1;
    end
end

assign fifo_din = data_in;
assign fifo_wr_en = data_in_valid_sync_2 && !fifo_full;
assign data_in_ready = !fifo_full;

fifo #(
    .WIDTH(INPUT_WIDTH),
    .DEPTH(FIFO_DEPTH)
) input_fifo (
    .clk(clk),
    .rst(rst),
    .wr_en(fifo_wr_en),
    .din(fifo_din),
    .full(fifo_full),
    .rd_en(fifo_rd_en),
    .dout(fifo_dout),
    .empty(fifo_empty)
);

reg [1:0] byte_select;
reg [OUTPUT_WIDTH-1:0] data_out_reg;
reg data_out_valid_reg;
reg send_marker;
reg [INPUT_WIDTH-1:0] fifo_dout_buffer;
reg fifo_dout_valid;

assign data_out = data_out_reg;
assign data_out_valid = data_out_valid_reg;
assign fifo_rd_en = !fifo_empty && !fifo_dout_valid;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        byte_select <= 2'b0;
        data_out_reg <= {OUTPUT_WIDTH{1'b0}};
        data_out_valid_reg <= 1'b0;
        send_marker <= 1'b0;
        fifo_dout_buffer <= {INPUT_WIDTH{1'b0}};
        fifo_dout_valid <= 1'b0;
    end else begin
        if (fifo_rd_en) begin
            fifo_dout_buffer <= fifo_dout;
            fifo_dout_valid <= 1'b1;
        end

        if (fifo_dout_valid) begin
            case (byte_select)
                2'b00: data_out_reg <= fifo_dout_buffer[OUTPUT_WIDTH-1:0];
                2'b01: data_out_reg <= fifo_dout_buffer[2*OUTPUT_WIDTH-1:OUTPUT_WIDTH];
                2'b10: begin
                    data_out_reg <= {{(OUTPUT_WIDTH-4){1'b0}}, fifo_dout_buffer[INPUT_WIDTH-1:2*OUTPUT_WIDTH]};
                    send_marker <= 1'b1;
                end
                default: data_out_reg <= {OUTPUT_WIDTH{1'b0}};
            endcase
            data_out_valid_reg <= 1'b1;
            byte_select <= byte_select + 1;

            if (byte_select == 2'b11 && data_out_ready) begin
                fifo_dout_valid <= 1'b0;
                byte_select <= 2'b00;
            end
        end

        if (data_out_ready) begin
            if (send_marker) begin
                data_out_reg <= MARKER_BYTE;
                send_marker <= 1'b0;
                data_out_valid_reg <= 1'b1;
            end else begin
                data_out_valid_reg <= 1'b0;
            end
        end
    end
end

endmodule