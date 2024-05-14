`include "periplex.vh"

module test_module(
    input                                      clk1,
    input                                      clk2,
    input                                      i_test_rx,
    input   [`TOTAL_UART-1:0]                  i_rx_serial,
    output                                     o_test_tx,
    output  [`TOTAL_UART-1:0]                  o_tx_serial,
    output reg                                 led = 1,
    output                                     hold,
    input   [`TOTAL_GPIO_CTRLS*DATAWIDTH-1:0]  gpio_in,
    output  [`TOTAL_GPIO_CTRLS*DATAWIDTH-1:0]  gpio_oe,
    output  [`TOTAL_GPIO_CTRLS*DATAWIDTH-1:0]  gpio_out,
    output  [`TOTAL_PWM-1:0]                   pwm_out
);


parameter CLKS_PER_BIT      = 435;
parameter UART_DATA_WIDTH   = 8;
parameter RAH_PACKET_WIDTH  = 48;
parameter PP_FIFO_WIDTH     = 48;
parameter PP_FIFO_DEPTH     = 64;
parameter ASYNC_FIFO_WIDTH  = 51;
parameter DATAWIDTH         = 8;
parameter GPIO_CONFIG_DATA_WIDTH =8;

/* Derived Parameters */
parameter TOTAL_UART = `TOTAL_UART;
parameter TOTAL_PWM = `TOTAL_PWM;
parameter TOTAL_GPIO_CTRLS = `TOTAL_GPIO_CTRLS;
parameter GPIO_WR_GRP_BUS_WIDTH = TOTAL_GPIO_CTRLS * ASYNC_FIFO_WIDTH;
parameter GPIO_CONFIG_BUS_WIDTH = TOTAL_GPIO_CTRLS * GPIO_CONFIG_DATA_WIDTH;

/* Wires */
wire                        w_rx_dv;
wire [UART_DATA_WIDTH-1:0]  w_uart_byte;
wire [RAH_PACKET_WIDTH-1:0] w_data_frame;
wire                        w_write_en;
wire                        w_rd_en;
wire [RAH_PACKET_WIDTH-1:0] w_rd_data_frame;
wire                        w_f_empty;
wire                        w_f_a_empty;
wire                        w_rd_fifo_en;
wire [RAH_PACKET_WIDTH-1:0] w_rd_fifo_data;
wire                        w_e_f_empty;
wire                        w_e_rd_en;
wire [RAH_PACKET_WIDTH-1:0] w_e_rd_data;
wire                        w_e_tx_done;
wire                        w_e_tx_dv;
wire [UART_DATA_WIDTH-1:0]  w_e_tx_byte;
wire [7:0]                  datacount_o;
wire [7:0]                  datacount;
/* For acknowledge of bitstream */
//reg led = 1;

test_uart_rx #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
)test_uartrx(
    .i_Clock        (clk1),
    .i_Rx_Serial    (i_test_rx),
    .o_Rx_DV        (w_rx_dv),
    .o_Rx_Byte      (w_uart_byte)
);


uart_packetizer test_uartpacket(
  .clk          (clk1),
  .rx_dv        (w_rx_dv),
  .uart_byte    (w_uart_byte),
  .data_frame   (w_data_frame),
  .wr_en        (w_write_en),
  .hold         ()
);

pp_wr_fifo  test_ppd_fifo(

    . empty_o(w_f_empty),
    . almost_empty_o(w_f_a_empty),
    . clk_i(clk1),
    . wr_en_i(w_write_en),
    . rd_en_i(w_rd_en),
    . wdata(w_data_frame),
    . rdata(w_rd_data_frame),
    . datacount_o(datacount)
);

periplex pp(
    .pp_clk         (clk1),
    .dt_clk         (clk2),
    .f_empty        (w_f_empty),
    .f_a_empty      (w_f_a_empty),
    .fifo_read_data (w_rd_data_frame),
    .fifo_read_en   (w_rd_en),
    .o_Tx_Active    (),
    .o_Tx_Serial    (o_tx_serial),
    .o_Tx_Done      (),
    .hold           (hold),
    .i_Rx_Serial    (i_rx_serial),
    .fifo_en        (w_rd_fifo_en),
    .fifo_data      (w_rd_fifo_data),
    .gpio_in        (gpio_in),
    .gpio_oe        (gpio_oe),
    .gpio_out       (gpio_out),
    .pwm_out        (pwm_out)
);
pp_wr_fifo  test_ppe_fifo(

    . empty_o(w_e_f_empty),
    . clk_i(clk1),
    . wr_en_i(w_rd_fifo_en),
    . rd_en_i(w_e_rd_en),
    . wdata(w_rd_fifo_data),
    . rdata(w_e_rd_data),
    .datacount_o(datacount_o)
);
test_tx_ctrl test_txctrl(
    .clk        (clk1),
    .f_empty    (w_e_f_empty),
    .data       (w_e_rd_data),
    .rd_en      (w_e_rd_en),
    .tx_done    (w_e_tx_done),
    .tx_dv      (w_e_tx_dv),
    .tx_byte    (w_e_tx_byte)
);

test_uart_tx #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
)test_uarttx(
    .i_Clock    (clk1),
    .i_Tx_DV    (w_e_tx_dv),
    .i_Tx_Byte  (w_e_tx_byte),
    .o_Tx_Active(           ),
    .o_Tx_Serial(o_test_tx),
    .o_Tx_Done  (w_e_tx_done)
);
endmodule