`include "periplex.vh"

module dt_top(
    input                           clk1,
    input                           clk2,
    input                           fifo_enable,
    input [DATA_PACKET_WIDTH-1:0]   fifo_data,
    output                          w_en,
    output [UART_DATA_WIDTH-1:0]    data_byte
);
 
/* Gloabal parameters */
parameter ASYNC_FIFO_DEPTH  = 16;
parameter DATA_PACKET_WIDTH = 51;
parameter UART_DATA_WIDTH   = 8;

/* Wire Declarations */
wire [DATA_PACKET_WIDTH-1:0]    w_data;
wire                            w_f_empty;
wire                            w_rd_en;


/* Module instantiations */
dt_fifo dt_fifo_51(
    .wr_clk_i   (clk1),
    .rd_clk_i   (clk2),
    .wr_en_i    (fifo_enable),
    .wdata      (fifo_data),
    .rd_en_i    (w_rd_en),
    .rdata      (w_data), 
    .empty_o    (w_f_empty)
);

dt_ctrl #(
    .DATA_PACKET_WIDTH(DATA_PACKET_WIDTH),
    .UART_DATA_WIDTH(UART_DATA_WIDTH)
)dt_ctrl(
    .clk            (clk2),
    .data_packet    (w_data),
    .f_empty        (w_f_empty),
    .rd_en          (w_rd_en),
    .data_byte      (data_byte),
    .we             (w_en)
);

endmodule
