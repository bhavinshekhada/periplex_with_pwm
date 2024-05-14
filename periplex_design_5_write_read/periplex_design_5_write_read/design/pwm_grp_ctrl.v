`include "periplex.vh"

module pwm_grp_ctrl(
    /* Clock Signals */
    input                               clk,
    input                               pwm_grp_en,
        
    /* Decoder Signals */   
    input                               parallel,
    input [SEL_WIDTH-1:0]               slv_sel,
    input                               cfg,
    input [LEN_WIDTH-1:0]               str_len,
    input [VALUE_WIDTH-1:0]             value,
    input                               flag_frame_1,
    output [`TOTAL_PWM-1:0]             dt_fifo_enable,
    output [PWM_WR_GRP_BUS_WIDTH-1:0]   dt_fifo_data,
    output [CONFIG_BUS_WIDTH-1:0]       config_bus
   
);
  
/* Global Parameters */
parameter SEL_WIDTH         = 7;
parameter LEN_WIDTH         = 7;
parameter STROBE_WIDTH      = 4;
parameter VALUE_WIDTH       = 48;
parameter PARL_DATA_WIDTH   = 8;
parameter ASYNC_FIFO_WIDTH  = 51;
parameter CONFIG_DATA_WIDTH = 32;

/* Derived Parameters */

parameter TOTAL_UART = `TOTAL_UART;
parameter TOTAL_I2C = `TOTAL_I2C;
parameter TOTAL_GPIO_CTRLS = `TOTAL_GPIO_CTRLS;
parameter TOTAL_PWM = `TOTAL_PWM;

parameter PWM_WR_GRP_BUS_WIDTH = TOTAL_PWM * ASYNC_FIFO_WIDTH;
parameter CONFIG_BUS_WIDTH = TOTAL_PWM * CONFIG_DATA_WIDTH;

/* Register declaration and initialization */
reg [`TOTAL_PWM-1:0]           r_dt_fifo_enable = 0;
reg [PWM_WR_GRP_BUS_WIDTH-1:0] r_dt_fifo_data = 0;
reg [CONFIG_BUS_WIDTH-1:0]      r_config_bus = {`TOTAL_PWM{32'd0}};

wire [SEL_WIDTH-1:0]            pwm_slv_sel;
assign pwm_slv_sel = slv_sel - (TOTAL_UART+TOTAL_I2C+TOTAL_GPIO_CTRLS);

integer i = 0;

/* Decoder Block */
always @(posedge clk) begin
if(!cfg) begin
    if(pwm_grp_en) begin
        if(parallel) begin // Parallel Mode
            r_dt_fifo_enable <= 0; // Reset FIFO Enable
            r_dt_fifo_data <= 0;   // Reset FIFO Data
            
            for (i = 0; i<STROBE_WIDTH; i=i+1) begin
                r_dt_fifo_enable[pwm_slv_sel+i] <= str_len[i]; // Depends upon the str_len so no need to reset in between
                if(str_len[i]) begin
                    r_dt_fifo_data [((pwm_slv_sel+i)*ASYNC_FIFO_WIDTH) +: (ASYNC_FIFO_WIDTH-3)] <= value[(i*PARL_DATA_WIDTH) +: PARL_DATA_WIDTH];
                    r_dt_fifo_data [(((pwm_slv_sel+i)*ASYNC_FIFO_WIDTH)-3) +: 3] <= 0;
                end else begin
                    r_dt_fifo_data [((pwm_slv_sel+i)*ASYNC_FIFO_WIDTH) +: ASYNC_FIFO_WIDTH] <= 0;
                end 
            end
        end else begin // Serial Mode
            r_dt_fifo_enable <= 0; // Reset FIFO Enable
            r_dt_fifo_data <= 0;   // Reset FIFO Data
            
            r_dt_fifo_enable[pwm_slv_sel] <= 1;
            r_dt_fifo_data [((pwm_slv_sel)*ASYNC_FIFO_WIDTH) +: (ASYNC_FIFO_WIDTH-3)] <= value;

            if(str_len < 6) begin // Assigning sel of fifo data packet
                r_dt_fifo_data [(((pwm_slv_sel+1)*ASYNC_FIFO_WIDTH)-3) +: 3] <= str_len;
            end else begin
                if(flag_frame_1) begin
                    r_dt_fifo_data [(((pwm_slv_sel+1)*ASYNC_FIFO_WIDTH)-3) +: 3] <= 3'B011;
                end else begin
                    r_dt_fifo_data [(((pwm_slv_sel+1)*ASYNC_FIFO_WIDTH)-3) +: 3] <= 3'B101;
                end
            end
        end
    end else begin
        r_dt_fifo_enable <= 0;
        r_dt_fifo_data <= 0;
    end
end else begin // Configuration Mode
    r_dt_fifo_enable <= 0;
    r_dt_fifo_data  <= 0;
    r_config_bus [pwm_slv_sel*CONFIG_DATA_WIDTH +: CONFIG_DATA_WIDTH] <= value[0 +: CONFIG_DATA_WIDTH];
end
end
assign config_bus       = r_config_bus;
assign dt_fifo_enable   = r_dt_fifo_enable;
assign dt_fifo_data     = r_dt_fifo_data;
endmodule