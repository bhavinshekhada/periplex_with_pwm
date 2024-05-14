`include "periplex.vh"

module pp_decoder(
    input                           clk,
    input [RAH_PACKET_WIDTH-1:0]    fifo_read_data,
    input                           f_empty,
    input                           f_a_empty,
    output                          fifo_read_en,
    output                          parallel,
    output [SEL_WIDTH-1:0]          slv_sel,
    output                          cfg,
    output [LEN_WIDTH-1:0]          str_len,
    output [VALUE_WIDTH-1:0]        value,
    output                          flag_frame_1,
    output                          uart_grp_en,
    output                          i2c_grp_en,
    output                          gpio_grp_en,
    output                          pwm_grp_en,
    output                          hold
);

/* Global Parameters */
parameter RAH_PACKET_WIDTH  = 48;
parameter SEL_WIDTH         = 7;
parameter LEN_WIDTH         = 7;
parameter STROBE_WIDTH      = 4;
parameter VALUE_WIDTH       = 48;
parameter I2C_COMMOM_RANGE  = `TOTAL_UART+`TOTAL_I2C;
parameter GPIO_COMMOM_RANGE = `TOTAL_UART+`TOTAL_I2C+`TOTAL_GPIO_CTRLS;
parameter PWM_COMMOM_RANGE =  `TOTAL_UART+`TOTAL_I2C+`TOTAL_GPIO_CTRLS+`TOTAL_PWM;
/* Register declaration and initialization */
reg                     r_fifo_read_en = 0;
reg                     r_parallel = 0;
reg [SEL_WIDTH-1:0]     r_slv_sel = 0;
reg                     r_cfg = 0;
reg [LEN_WIDTH-1:0]     r_str_len = 0;
reg [VALUE_WIDTH-1:0]   r_value = 0;
reg                     r_uart_grp_en = 0;
reg                     r_i2c_grp_en = 0;
reg                     r_gpio_grp_en = 0;
reg                     r_pwm_grp_en = 0;

/* flags */
reg flag_data_sample = 0;
reg flag_serial = 0;
reg r_flag_frame_1 = 0;
reg flag_hold = 0;

always @(posedge clk) begin
    /* Input FIFO read control */
    if(!f_empty) begin
        r_fifo_read_en <= 1;
    end
    
    if(f_a_empty && r_fifo_read_en )begin
        r_fifo_read_en <= 0;
    end
   
    
    /* Control for data sample */
    if(r_fifo_read_en) begin
        flag_data_sample <= 1;
    end else begin
        flag_data_sample <= 0;
    end
    
    
    /* Data sample and transfer */
    if(flag_data_sample) begin 
        if(!flag_serial) begin // Parallel Mode
            r_uart_grp_en <= 0;
            r_i2c_grp_en  <= 0;
            r_gpio_grp_en <= 0;
            r_pwm_grp_en <=  0;
            r_cfg         <= fifo_read_data[47];
            r_slv_sel     <= fifo_read_data[46:40];
            r_parallel    <= fifo_read_data[39];
            r_str_len     <= fifo_read_data[38:32];
            r_value       <= {{16{1'b0}},fifo_read_data[31:0]};
            
            /* Flag control for serial and parallel mode */
            if(!fifo_read_data[39] && (fifo_read_data[38:32] > 7'h3)) begin
                flag_serial <= 1;
                r_flag_frame_1 <= 1;
                flag_hold <= 1;
            end
            
            /* Peripheral group selector */
            if(fifo_read_data[46:40] < `TOTAL_UART) begin
                r_uart_grp_en <= 1;
            end else if (fifo_read_data[46:40] < I2C_COMMOM_RANGE) begin
                r_i2c_grp_en  <= 1;
            end else if(fifo_read_data[46:40] < GPIO_COMMOM_RANGE)begin
                r_gpio_grp_en  <= 1;
            end else if(fifo_read_data[46:40] < PWM_COMMOM_RANGE)begin
                r_pwm_grp_en  <= 1;
            end
            
        end else begin // Serial Mode

            if(flag_hold) begin
                flag_hold <= 0;
                
                if(r_slv_sel < `TOTAL_UART) begin
                    r_uart_grp_en <= 1;
                end else if (r_slv_sel < I2C_COMMOM_RANGE) begin
                    r_i2c_grp_en  <= 1;
                end else if(r_slv_sel < GPIO_COMMOM_RANGE)begin
                    r_gpio_grp_en  <= 1;
                end else if(r_slv_sel < PWM_COMMOM_RANGE)begin
                    r_pwm_grp_en  <= 1;
                end
                end
            r_value       <= fifo_read_data[47:0];
            r_slv_sel     <= r_slv_sel;
            r_parallel    <= r_parallel;
                
            if(r_flag_frame_1) begin // For first data frame
                r_str_len     <= r_str_len - 4;
                r_flag_frame_1  <= 0;
                
                if((r_str_len- 4) < 4'h6) begin
                    flag_serial <= 0;
                end else begin
                    flag_hold <= 1;
                end 
            end else begin // For other than first data frame 
                r_str_len     <= r_str_len - 6;
       
                if((r_str_len - 6) < 4'h6) begin
                    flag_serial <= 0;
                end else begin
                    flag_hold <= 1;
                end 
            end
        end
    end else if(!flag_data_sample && flag_hold) begin 
        /* Reset only control registers */
        r_uart_grp_en <= 0;
        r_i2c_grp_en  <= 0;
        r_gpio_grp_en <= 0;
        r_pwm_grp_en  <= 0;
        r_cfg         <= 0;
        r_value       <= 0;
    end else if(!flag_data_sample && !flag_hold) begin 
        /* Reset all registers */
        r_uart_grp_en <= 0;
        r_i2c_grp_en  <= 0;
        r_gpio_grp_en <= 0;
        r_pwm_grp_en  <= 0;
        r_slv_sel     <= 0;
        r_cfg         <= 0;
        r_str_len     <= 0;
        r_value       <= 0;
        r_parallel    <= 0;
    end
end

assign fifo_read_en = r_fifo_read_en;
assign parallel     = r_parallel;
assign slv_sel      = r_slv_sel;
assign cfg          = r_cfg;
assign str_len      = r_str_len;
assign value        = r_value;
assign flag_frame_1 = r_flag_frame_1;
assign hold         = flag_hold;
assign uart_grp_en  = r_uart_grp_en;
assign i2c_grp_en   = r_i2c_grp_en;
assign gpio_grp_en   = r_gpio_grp_en;
assign pwm_grp_en   = r_pwm_grp_en;
endmodule
