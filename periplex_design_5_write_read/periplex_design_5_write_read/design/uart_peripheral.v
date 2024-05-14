`include "periplex.vh"

module uart_peripheral (
   /* Clock Signals */
    input                           clk1,
    input                           clk2,
    
    /* Control Signals */
    input [CONFIG_DATA_WIDTH-1:0]   uart_config_data,
    
    /* UART Tx Signals */
    input                           uart_dt_fifo_enable,
    input [DATA_PACKET_WIDTH-1:0]   uart_dt_fifo_data,
    output                          Tx_Active,
    output                          Tx_Serial,
    output                          Tx_Done,
    
    /* UART Rx Signals */
    input                           rx_serial,
    input                           rd_fifo_en,
    output [UART_FIFO_WIDTH-1:0]    rd_fifo_data,
    output                          rd_f_empty
);


/* Gloabal parameters */
parameter ASYNC_FIFO_DEPTH  = 16;
parameter DATA_PACKET_WIDTH = 51;
parameter UART_DATA_WIDTH   = 8;
parameter STROBE_WIDTH      = 4;
parameter CLKS_PER_BIT      = 87;
parameter UART_FIFO_WIDTH   = 8;
parameter UART_FIFO_DEPTH   = 8;
parameter CONFIG_DATA_WIDTH = 32;

/* Connecting Wires */
wire                        w_wr_en;
wire [UART_DATA_WIDTH-1:0]  w_data_byte;

/* Module Instantiations */
dt_top dt_module(
    .clk1       (clk1),
    .clk2       (clk2),
    .fifo_enable(uart_dt_fifo_enable),
    .fifo_data  (uart_dt_fifo_data),
    .w_en       (w_wr_en),
    .data_byte  (w_data_byte)
);
uart_phy #(
    .STROBE_WIDTH   (STROBE_WIDTH),
    .UART_DATA_WIDTH(UART_DATA_WIDTH),
    .UART_FIFO_WIDTH(UART_FIFO_WIDTH),
    .UART_FIFO_DEPTH(UART_FIFO_DEPTH)
) uart (
    .clk1           (clk1),
    .clk2           (clk2),
    .wr_fifo_enable (w_wr_en),
    .wr_fifo_data   (w_data_byte),
    .config_data    (uart_config_data),
    .tx_active      (Tx_Active),
    .tx_done        (Tx_Done),
    .tx_serial      (Tx_Serial),
    .rx_serial      (rx_serial),
    .rd_fifo_en     (rd_fifo_en),
    .rd_fifo_data   (rd_fifo_data),
    .rd_f_empty     (rd_f_empty)
);
        
endmodule        