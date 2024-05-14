`include "periplex.vh"

module periplex(
    /* Clock Signals */
    input                                     pp_clk,
    input                                     dt_clk,
    /* Decoder data and control signals */
    input                                     f_empty,
    input                                     f_a_empty,
    input [RAH_PACKET_WIDTH-1:0]              fifo_read_data,
    output                                    fifo_read_en,
    output [`TOTAL_UART-1:0]                  o_Tx_Active,
    output [`TOTAL_UART-1:0]                  o_Tx_Serial,
    output [`TOTAL_UART-1:0]                  o_Tx_Done,
    output                                    hold,
    /* Encoder data and control signals */
    input [`TOTAL_UART-1:0]                   i_Rx_Serial,
    output                                    fifo_en,
    output [RD_DATA_BUS_WIDTH-1:0]            fifo_data,
    /* gpio inout signals */
    input  [`TOTAL_GPIO_CTRLS*DATAWIDTH-1:0]  gpio_in,
    output [`TOTAL_GPIO_CTRLS*DATAWIDTH-1:0]  gpio_oe,
    output [`TOTAL_GPIO_CTRLS*DATAWIDTH-1:0]  gpio_out,
    output [`TOTAL_PWM-1:0]                   pwm_out
);

/* Global Parameters */
parameter RAH_PACKET_WIDTH  = 48;
parameter SEL_WIDTH         = 7;
parameter LEN_WIDTH         = 7;
parameter GPIO_CONFIG_DATA_WIDTH =32;
parameter STROBE_WIDTH      = 4;
parameter VALUE_WIDTH       = 48;
parameter UART_FIFO_WIDTH   = 8;
parameter GPIO_FIFO_WIDTH   = 8;
parameter PWM_FIFO_WIDTH    = 8;
parameter UART_DATA_WIDTH   = 8;
parameter UART_FIFO_DEPTH   = 16;
parameter ASYNC_FIFO_WIDTH  = 51;
parameter CONFIG_DATA_WIDTH = 32;
parameter DATAWIDTH         = 8;
parameter PWM_DATAWIDTH     = 64;

parameter UART_TOTAL_GRP = ((TOTAL_UART + 3) >> 2); 
parameter GPIO_TOTAL_GRP = ((TOTAL_GPIO_CTRLS + 3) >> 2);
parameter TOTAL_GRP = UART_TOTAL_GRP + GPIO_TOTAL_GRP;

parameter RD_DATA_BUS_WIDTH = 48;

/* Derived Parameters */
parameter TOTAL_UART            = `TOTAL_UART;
parameter TOTAL_I2C             = `TOTAL_I2C;
parameter TOTAL_GPIO_CTRLS      = `TOTAL_GPIO_CTRLS;
parameter TOTAL_PWM             = `TOTAL_PWM;
parameter UART_WR_GRP_BUS_WIDTH = TOTAL_UART * ASYNC_FIFO_WIDTH;
parameter GPIO_WR_GRP_BUS_WIDTH = TOTAL_GPIO_CTRLS * ASYNC_FIFO_WIDTH;
parameter PWM_WR_GRP_BUS_WIDTH =  TOTAL_PWM * ASYNC_FIFO_WIDTH;
parameter UART_CONFIG_BUS_WIDTH = TOTAL_UART * CONFIG_DATA_WIDTH;
parameter GPIO_CONFIG_BUS_WIDTH = TOTAL_GPIO_CTRLS * GPIO_CONFIG_DATA_WIDTH;
parameter PWM_CONFIG_BUS_WIDTH =  TOTAL_PWM * GPIO_CONFIG_DATA_WIDTH;
parameter UART_RD_GRP_BUS_WIDTH = TOTAL_UART * UART_DATA_WIDTH;
parameter GPIO_RD_GRP_BUS_WIDTH = TOTAL_GPIO_CTRLS * DATAWIDTH;
parameter I2C_CONFIG_BUS_WIDTH  = TOTAL_I2C * CONFIG_DATA_WIDTH;

/* Connecting Wires */
wire [SEL_WIDTH-1:0]                w_slv_sel;
wire                                w_cfg;
wire [LEN_WIDTH-1:0]                w_str_len;
wire [VALUE_WIDTH-1:0]              w_value;
wire                                w_uart_grp_en;
wire                                w_i2c_grp_en;
wire                                w_gpio_grp_en;
wire                                w_pwm_grp_en;
wire [`TOTAL_UART-1:0]              w_uart_dt_fifo_enable;
wire [`TOTAL_GPIO_CTRLS-1:0]        w_gpio_dt_fifo_enable;

wire [`TOTAL_PWM-1:0]               w_pwm_dt_fifo_enable;
wire [UART_WR_GRP_BUS_WIDTH-1:0]    w_uart_dt_fifo_data;
wire [GPIO_WR_GRP_BUS_WIDTH-1:0]    w_gpio_dt_fifo_data;
wire [PWM_WR_GRP_BUS_WIDTH-1:0]     w_pwm_dt_fifo_data;
wire                                w_parallel;
wire                                w_flag_frame_1;
wire [UART_CONFIG_BUS_WIDTH-1:0]    w_uart_config_bus;
wire [GPIO_CONFIG_BUS_WIDTH-1:0]    w_gpio_config_bus;
wire [PWM_CONFIG_BUS_WIDTH-1:0]     w_pwm_config_bus;
wire [`TOTAL_UART-1:0]              w_uart_rd_f_empty;
wire [`TOTAL_GPIO_CTRLS-1:0]        w_gpio_rd_f_empty;
wire [UART_RD_GRP_BUS_WIDTH-1:0]    w_uart_rd_fifo_data;
wire [GPIO_RD_GRP_BUS_WIDTH-1:0]    w_gpio_rd_fifo_data;
wire [`TOTAL_UART-1:0]              w_uart_rd_fifo_en;
wire [`TOTAL_GPIO_CTRLS-1:0]        w_gpio_rd_fifo_en;
wire [TOTAL_GRP-1:0]                w_interrupt;
wire                                w_rd_req;
wire                                w_rd_req_ack;
wire [TOTAL_GRP-1: 0]               w_rd_slave_id;
wire [TOTAL_GRP-1:0]                w_int_ack;
wire                                w_rd_dv;
wire [RD_DATA_BUS_WIDTH-1:0]        w_rd_data;


/* Module Instantiations */
pp_decoder #(
    .RAH_PACKET_WIDTH   (RAH_PACKET_WIDTH),
    .SEL_WIDTH          (SEL_WIDTH),
    .STROBE_WIDTH       (STROBE_WIDTH), 
    .VALUE_WIDTH        (VALUE_WIDTH)   
)ppd1(
  .clk              (pp_clk),
  .fifo_read_data   (fifo_read_data),
  .f_empty          (f_empty),
  .f_a_empty        (f_a_empty),
  .fifo_read_en     (fifo_read_en),
  .parallel         (w_parallel),
  .slv_sel          (w_slv_sel),
  .cfg              (w_cfg),
  .str_len          (w_str_len),
  .value            (w_value),
  .flag_frame_1     (w_flag_frame_1),
  .uart_grp_en      (w_uart_grp_en),
 // .i2c_grp_en       (w_i2c_grp_en),
  .gpio_grp_en      (w_gpio_grp_en),
  .pwm_grp_en       ( w_pwm_grp_en),
  .hold             (hold)
);


uart_grp_ctrl #(
    .SEL_WIDTH          (SEL_WIDTH),
    .STROBE_WIDTH       (STROBE_WIDTH),
    .LEN_WIDTH          (LEN_WIDTH),
    .VALUE_WIDTH        (VALUE_WIDTH),    
    .ASYNC_FIFO_WIDTH   (ASYNC_FIFO_WIDTH)
)uart_grp(
    .clk                    (pp_clk),
    .uart_grp_en            (w_uart_grp_en),
    .parallel               (w_parallel),
    .slv_sel                (w_slv_sel),
    .cfg                    (w_cfg),
    .str_len                (w_str_len),
    .value                  (w_value),
    .flag_frame_1           (w_flag_frame_1),
    .uart_dt_fifo_enable    (w_uart_dt_fifo_enable),
    .uart_dt_fifo_data      (w_uart_dt_fifo_data),
    .uart_config_bus        (w_uart_config_bus),
    
    .rd_f_empty             (w_uart_rd_f_empty),
    .rd_fifo_data           (w_uart_rd_fifo_data),
    .int_ack                (w_int_ack[0 +: UART_TOTAL_GRP]),
    .rd_fifo_en             (w_uart_rd_fifo_en),
    .interrupt              (w_interrupt[0 +: UART_TOTAL_GRP]),
    .rd_dv                  (w_rd_dv),
    .rd_data                (w_rd_data)
);

gpio_grp_ctrl#(
    .SEL_WIDTH          (SEL_WIDTH),
    .STROBE_WIDTH       (STROBE_WIDTH),
    .LEN_WIDTH          (LEN_WIDTH),
    .VALUE_WIDTH        (VALUE_WIDTH),    
    .ASYNC_FIFO_WIDTH   (ASYNC_FIFO_WIDTH)
)GPIO_grp(
    .clk                    (pp_clk),
    .gpio_grp_en            (w_gpio_grp_en),
    .parallel               (w_parallel),
    .slv_sel                (w_slv_sel),
    .cfg                    (w_cfg),
    .str_len                (w_str_len),
    .value                  (w_value),
    .flag_frame_1           (w_flag_frame_1),
    .dt_fifo_enable         (w_gpio_dt_fifo_enable),
    .dt_fifo_data           (w_gpio_dt_fifo_data),
    .config_bus             (w_gpio_config_bus),
    
    .rd_f_empty             (w_gpio_rd_f_empty),
    .rd_fifo_data           (w_gpio_rd_fifo_data),
    .int_ack                (w_int_ack[UART_TOTAL_GRP +: GPIO_TOTAL_GRP]),
    .rd_fifo_en             (w_gpio_rd_fifo_en),
    .interrupt              (w_interrupt[UART_TOTAL_GRP +: GPIO_TOTAL_GRP]),
    .rd_dv                  (w_rd_dv),
    .rd_data                (w_rd_data)
    
);

pwm_grp_ctrl #(
    .SEL_WIDTH          (SEL_WIDTH),
    .STROBE_WIDTH       (STROBE_WIDTH),
    .LEN_WIDTH          (LEN_WIDTH),
    .VALUE_WIDTH        (VALUE_WIDTH),    
    .ASYNC_FIFO_WIDTH   (ASYNC_FIFO_WIDTH)
)PWM_GRP(
    .clk(pp_clk),
    .pwm_grp_en(w_pwm_grp_en),
    .parallel               (w_parallel),
    .slv_sel                (w_slv_sel),
    .cfg                    (w_cfg),
    .str_len                (w_str_len),
    .value                  (w_value),
    .flag_frame_1           (w_flag_frame_1),
    .dt_fifo_enable         (w_pwm_dt_fifo_enable),
    .dt_fifo_data           (w_pwm_dt_fifo_data),
    .config_bus             (w_pwm_config_bus)
);

/* UART Peripheral generate block */
genvar i;
generate
    for (i = 0; i < `TOTAL_UART; i = i + 1) begin: UART_PERIPHERAL
        uart_peripheral #(
            .STROBE_WIDTH   (STROBE_WIDTH),
            .UART_DATA_WIDTH(UART_DATA_WIDTH),
            .UART_FIFO_WIDTH(UART_FIFO_WIDTH),
            .UART_FIFO_DEPTH(UART_FIFO_DEPTH)
        ) uartperipheral (
            .clk1                   (pp_clk),
            .clk2                   (dt_clk),
            .uart_dt_fifo_enable    (w_uart_dt_fifo_enable[i]),
            .uart_dt_fifo_data      (w_uart_dt_fifo_data[i*ASYNC_FIFO_WIDTH +: ASYNC_FIFO_WIDTH]),
            .uart_config_data       (w_uart_config_bus[i*CONFIG_DATA_WIDTH +: CONFIG_DATA_WIDTH]),
            .Tx_Active              (o_Tx_Active[i]),
            .Tx_Done                (o_Tx_Done[i]),
            .Tx_Serial              (o_Tx_Serial[i]),
            .rx_serial              (i_Rx_Serial[i]),
            .rd_fifo_en             (w_uart_rd_fifo_en[i]),
            .rd_fifo_data           (w_uart_rd_fifo_data[i*UART_DATA_WIDTH +: UART_DATA_WIDTH]),
            .rd_f_empty             (w_uart_rd_f_empty[i])
        );
    end
endgenerate
 
genvar k;
generate
    for (k = 0; k < `TOTAL_GPIO_CTRLS; k = k + 1) begin: GPIO_PERIPHERAL
        GPIO_PERIPHERAL #(
             .GPIO_FIFO_WIDTH   (GPIO_FIFO_WIDTH),
             .DATAWIDTH         (DATAWIDTH),
             .CONFIG_DATA_WIDTH(GPIO_CONFIG_DATA_WIDTH),
             .DATA_PACKET_WIDTH(ASYNC_FIFO_WIDTH)
        ) GPIOPERIPHERAL (
            .clk1                   (pp_clk),
            .clk2                   (dt_clk),
            .g_config_data          (w_gpio_config_bus[k*GPIO_CONFIG_DATA_WIDTH +: GPIO_CONFIG_DATA_WIDTH]),
            
            .gpio_in                (gpio_in[k*DATAWIDTH +:DATAWIDTH]), 
            .gpio_oe                (gpio_oe[k*DATAWIDTH +:DATAWIDTH]), 
            .gpio_out               (gpio_out[k*DATAWIDTH +:DATAWIDTH]),
            .dt_gpio_fifo_enable    (w_gpio_dt_fifo_enable[k]),
            .dt_gpio_fifo_data      (w_gpio_dt_fifo_data[k*ASYNC_FIFO_WIDTH +: ASYNC_FIFO_WIDTH]),
            .rd_gpio_fifo_data      (w_gpio_rd_fifo_data[k*DATAWIDTH +: DATAWIDTH]),
            .rd_gpio_fifo_en        (w_gpio_rd_fifo_en[k]),
            .rd_gpio_f_empty        (w_gpio_rd_f_empty[k])
             ); 
    end
endgenerate


genvar j;
generate
    for (j = 0; j < `TOTAL_PWM; j = j + 1) begin: PWM_PERIPHERAL
        PWM_peripheral #(
             .PWM_FIFO_WIDTH   (PWM_FIFO_WIDTH),
             .PWM_DATAWIDTH         (PWM_DATAWIDTH),
             .CONFIG_DATA_WIDTH(GPIO_CONFIG_DATA_WIDTH),
             .DATA_PACKET_WIDTH(ASYNC_FIFO_WIDTH)
        ) PWMPERIPHERAL (
            .clk1                   (pp_clk),
            .clk2                   (dt_clk),
            .pwm_config_data        (w_pwm_config_bus[j*CONFIG_DATA_WIDTH +: CONFIG_DATA_WIDTH]),
            .dt_pwm_fifo_enable     (w_pwm_dt_fifo_enable[j]),
            .dt_pwm_fifo_data       (w_pwm_dt_fifo_data[j*ASYNC_FIFO_WIDTH +: ASYNC_FIFO_WIDTH]),
            .pwm_out                (pwm_out[j])
     ); 
    end
endgenerate
/* Encoder Module Instantiations */
rd_req_arb req_arb(
    .clk        (pp_clk),
    .i_interrupt (w_interrupt),
    .rd_req_ack (w_rd_req_ack),
    .rd_slave_id(w_rd_slave_id),
    .rd_req     (w_rd_req)
);

pp_encoder ppe1(
    .clk        (pp_clk),
    .rd_req     (w_rd_req),
    .rd_slave_id(w_rd_slave_id),
    .rd_dv      (w_rd_dv),
    .rd_data    (w_rd_data),
    .rd_req_ack (w_rd_req_ack),
    .int_ack    (w_int_ack),
    .fifo_en    (fifo_en),
    .fifo_data  (fifo_data)
 );

endmodule

