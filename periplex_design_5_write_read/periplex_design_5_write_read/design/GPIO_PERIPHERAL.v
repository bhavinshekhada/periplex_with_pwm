`include "periplex.vh"

module GPIO_PERIPHERAL # (parameter GPIO_FIFO_WIDTH = 8, DATA_PACKET_WIDTH = 51, CONFIG_DATA_WIDTH = 32, DATAWIDTH = 8)(
    /* Clock Signals */
    input                           clk1,
    input                           clk2,
    
    /* Control Signals */
    input [CONFIG_DATA_WIDTH-1:0]   g_config_data,
    input     [DATAWIDTH-1:0]       gpio_in,
    output   [DATAWIDTH-1:0]        gpio_oe,
    output   [DATAWIDTH-1:0]        gpio_out,
    input                           dt_gpio_fifo_enable,
    input [DATA_PACKET_WIDTH-1:0]   dt_gpio_fifo_data,
    input                           rd_gpio_fifo_en,
    output [GPIO_FIFO_WIDTH-1:0]    rd_gpio_fifo_data,
    output                          rd_gpio_f_empty
);


/* Gloabal parameters */
parameter ASYNC_FIFO_DEPTH  = 16;
parameter UART_DATA_WIDTH   = 8;
parameter UART_FIFO_DEPTH   = 8;
/* Connecting Wires */
wire                        w_gpio_wr_en;
wire [UART_DATA_WIDTH-1:0]  w_gpio_data_byte;

/* Module Instantiations */
dt_top dt_module(
    .clk1       (clk1),
    .clk2       (clk2),
    .fifo_enable(dt_gpio_fifo_enable),
    .fifo_data  (dt_gpio_fifo_data),
    .w_en       (w_gpio_wr_en),
    .data_byte  (w_gpio_data_byte)
);
GPIO_phy #(
    .GPIO_FIFO_WIDTH   (GPIO_FIFO_WIDTH),
    .DATAWIDTH(DATAWIDTH),
    .CONFIG_DATA_WIDTH(CONFIG_DATA_WIDTH),
    .UART_FIFO_DEPTH(UART_FIFO_DEPTH)
) GPIO_phy_dut (
    .clk1               (clk1),
    .clk2               (clk2), 
    .gpio_config_data   (g_config_data),
    .gpio_in            (gpio_in),
    .gpio_oe            (gpio_oe),
    .gpio_out           (gpio_out),
    .wr_fifo_enable     (w_gpio_wr_en),
    .wr_fifo_data       (w_gpio_data_byte),
    .rd_fifo_en         (rd_gpio_fifo_en),
    .rd_fifo_data       (rd_gpio_fifo_data),
    .rd_gpio_f_empty    (rd_gpio_f_empty)
 );
        
endmodule        