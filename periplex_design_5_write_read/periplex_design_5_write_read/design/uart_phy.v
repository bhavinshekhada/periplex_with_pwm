module uart_phy(
    /* Clock inputs */
    input                       clk1,
    input                       clk2,
    
    /*Control inputs */
    input [CONFIG_DATA_WIDTH-1:0] config_data,
    
    /* UART Tx Signals */
    input                       wr_fifo_enable,
    input [UART_FIFO_WIDTH-1:0] wr_fifo_data,
    output                      tx_active,
    output                      tx_done,
    output                      tx_serial,
    
    /* UART Rx Signals */
    input                        rx_serial,
    input                        rd_fifo_en,
    output [UART_FIFO_WIDTH-1:0] rd_fifo_data,
    output                       rd_f_empty
);

/* Gloabal parameters */
parameter STROBE_WIDTH    = 4;
parameter UART_DATA_WIDTH = 8;
parameter UART_FIFO_WIDTH = 8;
parameter UART_FIFO_DEPTH = 8;
parameter CONFIG_DATA_WIDTH = 32;

/* Connecting Wires */
wire                        w_f_empty;
wire [UART_FIFO_WIDTH-1:0]  w_fifo_read_data;
wire                        w_fifo_read_en;
wire                        w_uart_dv;
wire [UART_DATA_WIDTH-1:0]  w_uart_data;
wire [UART_DATA_WIDTH-1:0]  w_rx_byte;
wire                        w_rx_dv;

/* Module Instantiation */
/* UART Tx Modules */

uart_fifo uart_wr_fifo(
    .wr_clk_i   (clk2),
    .rd_clk_i   (clk1),
    .wr_en_i    (wr_fifo_enable),
    .wdata      (wr_fifo_data),
    .rd_en_i    (w_fifo_read_en),
    .rdata      (w_fifo_read_data), 
    .empty_o    (w_f_empty)
);

uart_ctrl #(
    .UART_FIFO_WIDTH(UART_FIFO_WIDTH),
    .UART_DATA_WIDTH(UART_DATA_WIDTH)
) uart_write_ctrl(
    .clk            (clk1),
    .f_empty        (w_f_empty),
    .fifo_read_data (w_fifo_read_data),
    .uart_tx_done   (tx_done),
    .fifo_read_en   (w_fifo_read_en),
    .uart_dv        (w_uart_dv),
    .uart_data      (w_uart_data)
);

uart_tx uarttx (
    .i_Clock        (clk1),
    .i_Tx_DV        (w_uart_dv),
    .i_Tx_Byte      (w_uart_data),
    .config_data    (config_data),
    .o_Tx_Active    (tx_active),
    .o_Tx_Serial    (tx_serial),
    .o_Tx_Done      (tx_done)
);

/* UART Rx Modules */
uart_rx uartrx(
    .i_Clock        (clk1),
    .i_Rx_Serial    (rx_serial),
    .config_data    (config_data),
    .o_Rx_DV        (w_rx_dv),
    .o_Rx_Byte      (w_rx_byte)
);

uart_fifo uart_rd_fifo(
    .wr_clk_i   (clk1),
    .rd_clk_i   (clk1),
    .wr_en_i    (w_rx_dv),
    .wdata      (w_rx_byte),
    .rd_en_i    (rd_fifo_en),
    .rdata      (rd_fifo_data), 
    .empty_o    (rd_f_empty)
);

    
endmodule