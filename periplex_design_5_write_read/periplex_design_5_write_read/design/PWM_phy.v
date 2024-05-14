`timescale 1ns / 1ps
 
module PWM_phy # (parameter PWM_FIFO_WIDTH = 8, CONFIG_DATA_WIDTH = 32, PWM_DATAWIDTH = 64)( 
    /* Clock inputs */
    input                           clk1,
    input                           clk2,
    input [CONFIG_DATA_WIDTH-1:0]   pwm_config_data, 
    input                           wr_fifo_enable,
    input [PWM_FIFO_WIDTH-1:0]      wr_fifo_data,
    output                          pwm_out
    );
/* Connecting Wires */
wire                        w_f_empty;
wire [PWM_FIFO_WIDTH-1:0]  w_fifo_read_data;
wire                        w_fifo_read_en;



/* Module Instantiation */
/* FIFO Modules */
uart_fifo pwm_wr_fifo(
    .wr_clk_i   (clk2),
    .rd_clk_i   (clk1),
    .wr_en_i    (wr_fifo_enable),
    .wdata      (wr_fifo_data),
    
    .rd_en_i    (w_fifo_read_en),
    .rdata      (w_fifo_read_data), 
    .empty_o    (w_f_empty)
);

pwm_generator #(
    .PWM_FIFO_WIDTH(PWM_FIFO_WIDTH),.PWM_DATAWIDTH(PWM_DATAWIDTH)
) pwm_generator_dut(
    .clk(clk1),   
    .empty(w_f_empty),
    .pwm_config_data(pwm_config_data),
    .i_data(w_fifo_read_data),
    .read(w_fifo_read_en),
    .o_data(),
    .PWM_out(pwm_out)
    );
    
endmodule