`include "periplex.vh"

module PWM_peripheral # (parameter PWM_FIFO_WIDTH = 8, DATA_PACKET_WIDTH = 51, CONFIG_DATA_WIDTH = 32, PWM_DATAWIDTH = 64)(
    /* Clock Signals */
    input                           clk1,
    input                           clk2,
    input [CONFIG_DATA_WIDTH-1:0]   pwm_config_data,
    input                           dt_pwm_fifo_enable,
    input [DATA_PACKET_WIDTH-1:0]   dt_pwm_fifo_data,
    
    output                          pwm_out
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
    .fifo_enable(dt_pwm_fifo_enable),
    .fifo_data  (dt_pwm_fifo_data),
    
    .w_en       (w_gpio_wr_en),
    .data_byte  (w_gpio_data_byte)
);
PWM_phy #(
    .PWM_FIFO_WIDTH   (PWM_FIFO_WIDTH),
    .PWM_DATAWIDTH(PWM_DATAWIDTH),
    .CONFIG_DATA_WIDTH(CONFIG_DATA_WIDTH)
    
) PWM_phy_dut (
    .clk1               (clk1),
    .clk2               (clk2), 
    .pwm_config_data    (pwm_config_data),
    .wr_fifo_enable     (w_gpio_wr_en),
    .wr_fifo_data       (w_gpio_data_byte),
    .pwm_out            (pwm_out)
 );
        
endmodule        