`timescale 1ns / 1ps
 
module GPIO_phy # (parameter GPIO_FIFO_WIDTH = 8, UART_FIFO_DEPTH = 8, CONFIG_DATA_WIDTH = 32, DATAWIDTH = 8)( 
    /* Clock inputs */
    input                           clk1,
    input                           clk2,
    
    /*Control inputs */
    input [CONFIG_DATA_WIDTH-1:0]   gpio_config_data,
    
    input     [DATAWIDTH-1:0]       gpio_in,
    output    [DATAWIDTH-1:0]       gpio_oe,
    output    [DATAWIDTH-1:0]       gpio_out,
    input                           wr_fifo_enable,
    input [GPIO_FIFO_WIDTH-1:0]     wr_fifo_data,
   
    input                           rd_fifo_en,
    output [GPIO_FIFO_WIDTH-1:0]    rd_fifo_data,
    output                          rd_gpio_f_empty
    );
/* Connecting Wires */
wire                        w_f_empty;
wire [GPIO_FIFO_WIDTH-1:0]  w_fifo_read_data;
wire                        w_fifo_read_en;
wire                        w_uart_dv;
wire [DATAWIDTH-1:0]        w_uart_data;
wire [DATAWIDTH-1:0]        w_rx_byte;
wire                        w_rx_dv;
wire [DATAWIDTH-1:0]        g_fifo_data;
wire                        g_fifo_wr_en;
/* Module Instantiation */
/* FIFO Modules */
uart_fifo gpio_wr_fifo(
    .wr_clk_i   (clk2),
    .rd_clk_i   (clk1),
    .wr_en_i    (wr_fifo_enable),
    .wdata      (wr_fifo_data),
    .rd_en_i    (w_fifo_read_en),
    .rdata      (w_fifo_read_data), 
    .empty_o    (w_f_empty)
);

gpio_ctrl #(
    .DATAWIDTH(DATAWIDTH)
) gpio_write_ctrl(

    .clock         (clk1),
    .empty         (w_f_empty),
    .i_data        (w_fifo_read_data),
    .gpio_config   (gpio_config_data), 
    .read          (w_fifo_read_en),
    .gpio_oe       (gpio_oe),
    .gpio_out      (gpio_out),
    .gpio_in       (gpio_in),
    .rd_gpio_out   (g_fifo_data),
    .rd_fifo_en    (g_fifo_wr_en)     
    );
    


uart_fifo gpio_rd_fifo(
    .wr_clk_i     (clk1),
    .rd_clk_i     (clk1),
    .wr_en_i      (g_fifo_wr_en),
    .wdata        (g_fifo_data),
    .rd_en_i      (rd_fifo_en),
    .rdata        (rd_fifo_data), 
    .empty_o      (rd_gpio_f_empty)
);

    
endmodule