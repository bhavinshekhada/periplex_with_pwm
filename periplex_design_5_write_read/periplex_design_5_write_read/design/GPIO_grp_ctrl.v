`include "periplex.vh"

module gpio_grp_ctrl(
    /* Clock Signals */
    input                               clk,
    input                               gpio_grp_en,
        
    /* Decoder Signals */   
    input                               parallel,
    input [SEL_WIDTH-1:0]               slv_sel,
    input                               cfg,
    input [LEN_WIDTH-1:0]               str_len,
    input [VALUE_WIDTH-1:0]             value,
    input                               flag_frame_1,
    output [`TOTAL_GPIO_CTRLS-1:0]      dt_fifo_enable,
    output [GPIO_WR_GRP_BUS_WIDTH-1:0]  dt_fifo_data,
    output [GPIO_CONFIG_BUS_WIDTH-1:0]  config_bus,
  
    input [`TOTAL_GPIO_CTRLS-1:0]       rd_f_empty,
    input [UART_RD_GRP_BUS_WIDTH-1:0]   rd_fifo_data,
    input [GPIO_TOTAL_GRP-1:0]          int_ack,
    output [`TOTAL_GPIO_CTRLS-1:0]      rd_fifo_en,
    output [GPIO_TOTAL_GRP-1:0]         interrupt,
    output                              rd_dv,
    output [VALUE_WIDTH-1:0]            rd_data
  
);
  
/* Global Parameters */
parameter SEL_WIDTH         = 7;
parameter LEN_WIDTH         = 7;
parameter STROBE_WIDTH      = 4;
parameter VALUE_WIDTH       = 48;
parameter PARL_DATA_WIDTH   = 8;
parameter ASYNC_FIFO_WIDTH  = 51;
parameter GPIO_CONFIG_DATA_WIDTH = 32;
parameter UART_DATA_WIDTH   = 8;

parameter UART_TOTAL_GRP = ((TOTAL_UART + 3) >> 2); 
parameter GPIO_TOTAL_GRP = ((TOTAL_GPIO_CTRLS + 3) >> 2);
parameter TOTAL_GRP = UART_TOTAL_GRP + GPIO_TOTAL_GRP;

parameter GRP_WIDTH         = 4;
parameter WAIT_CLKS         = 10;

parameter REMAINDER = (`TOTAL_GPIO_CTRLS % GRP_WIDTH == 0) ? GRP_WIDTH : (TOTAL_GPIO_CTRLS % GRP_WIDTH);

/* Derived Parameters */
parameter TOTAL_UART = `TOTAL_UART;
parameter TOTAL_I2C = `TOTAL_I2C;
parameter TOTAL_GPIO_CTRLS = `TOTAL_GPIO_CTRLS;
parameter GPIO_WR_GRP_BUS_WIDTH = `TOTAL_GPIO_CTRLS * ASYNC_FIFO_WIDTH;
parameter GPIO_CONFIG_BUS_WIDTH = `TOTAL_GPIO_CTRLS * GPIO_CONFIG_DATA_WIDTH;
parameter UART_RD_GRP_BUS_WIDTH = `TOTAL_GPIO_CTRLS * UART_DATA_WIDTH;

/* Register declaration and initialization */
reg [`TOTAL_GPIO_CTRLS-1:0]           r_dt_fifo_enable = 0;
reg [GPIO_WR_GRP_BUS_WIDTH-1:0] r_dt_fifo_data = 0;
reg [GPIO_CONFIG_BUS_WIDTH-1:0]      r_config_bus = {`TOTAL_GPIO_CTRLS{32'h000000FF}}; 

wire [SEL_WIDTH-1:0]            gpio_slv_sel;
assign gpio_slv_sel = slv_sel - (TOTAL_UART+TOTAL_I2C);


integer i = 0;

/* Decoder Block */
always @(posedge clk) begin
if(!cfg) begin
    if(gpio_grp_en) begin
        if(parallel) begin // Parallel Mode
            r_dt_fifo_enable <= 0; // Reset FIFO Enable
            r_dt_fifo_data <= 0;   // Reset FIFO Data
            
            for (i = 0; i<STROBE_WIDTH; i=i+1) begin
                r_dt_fifo_enable[gpio_slv_sel+i] <= str_len[i]; // Depends upon the str_len so no need to reset in between
                if(str_len[i]) begin
                    r_dt_fifo_data [((gpio_slv_sel+i)*ASYNC_FIFO_WIDTH) +: (ASYNC_FIFO_WIDTH-3)] <= value[(i*PARL_DATA_WIDTH) +: PARL_DATA_WIDTH];
                    r_dt_fifo_data [(((gpio_slv_sel+i)*ASYNC_FIFO_WIDTH)-3) +: 3] <= 0;
                end else begin
                    r_dt_fifo_data [((gpio_slv_sel+i)*ASYNC_FIFO_WIDTH) +: ASYNC_FIFO_WIDTH] <= 0;
                end 
            end
        end else begin // Serial Mode
            r_dt_fifo_enable <= 0; // Reset FIFO Enable
            r_dt_fifo_data <= 0;   // Reset FIFO Data
            
            r_dt_fifo_enable[gpio_slv_sel] <= 1;
            r_dt_fifo_data [((gpio_slv_sel)*ASYNC_FIFO_WIDTH) +: (ASYNC_FIFO_WIDTH-3)] <= value;

            if(str_len < 6) begin // Assigning sel of fifo data packet
                r_dt_fifo_data [(((gpio_slv_sel+1)*ASYNC_FIFO_WIDTH)-3) +: 3] <= str_len;
            end else begin
                if(flag_frame_1) begin
                    r_dt_fifo_data [(((gpio_slv_sel+1)*ASYNC_FIFO_WIDTH)-3) +: 3] <= 3'B011;
                end else begin
                    r_dt_fifo_data [(((gpio_slv_sel+1)*ASYNC_FIFO_WIDTH)-3) +: 3] <= 3'B101;
                end
            end
        end
    end else begin
        r_dt_fifo_enable <= 0;
        r_dt_fifo_data <= 0;
    end
end else begin // Configuration Mode
    r_config_bus [gpio_slv_sel*GPIO_CONFIG_DATA_WIDTH +: GPIO_CONFIG_DATA_WIDTH] <= value[0 +: GPIO_CONFIG_DATA_WIDTH];
end
end

/* Encoder Block */
/* Interrupt request generator */
reg [GPIO_TOTAL_GRP-1:0] flag_rd = 0;
reg [GPIO_TOTAL_GRP-1:0] r_int = 0;
reg [3:0]           count = 0;

integer j = 0;
always @(posedge clk) begin
    for (j = 0; j<GPIO_TOTAL_GRP; j= j+1) begin
        if( j < GPIO_TOTAL_GRP-1) begin
            flag_rd[j] = |(~(rd_f_empty[j*GRP_WIDTH +: GRP_WIDTH]));
        end else begin
            if(REMAINDER == 0) begin
                flag_rd[j] = |(~(rd_f_empty[j*GRP_WIDTH +: GRP_WIDTH]));
            end else begin
                flag_rd[j] = |(~(rd_f_empty[j*GRP_WIDTH +: REMAINDER]));
            end
        end
        
        if(flag_rd[j]) begin
            if(count == WAIT_CLKS) begin
                count <= 0;
                r_int[j] <= flag_rd[j];
            end else begin
                count <= count + 1;
            end
        end
    end
    if(flag_int_done) begin
        flag_rd[r_grp_id] <= 0; // Flag deassertion
        r_int[r_grp_id] <= 0; // Interrupt flag deassertion 
    end
end

/* Interrupt Handler */
reg [`TOTAL_GPIO_CTRLS-1:0]   r_rd_fifo_en = 0;
reg [GPIO_TOTAL_GRP-1:0]     r_grp_id = 0;
reg [LEN_WIDTH-1:0]     r_strobe = 0;
reg [VALUE_WIDTH-1:0]   r_rd_data = 0;
reg                     r_rd_dv = 0;
reg [SEL_WIDTH-1:0]     r_slv_sel;
reg                     flag_int_done = 0; 

integer k = 0;

localparam str_valid_len = 7 - REMAINDER;

wire [GPIO_TOTAL_GRP-1:0] w_grp_id;
encoder enc (
    .in(int_ack),
    .out(w_grp_id)
);

/* State Machine Parameters */
reg [2:0] state         = 0;
localparam IDLE         = 3'b000;
localparam RD_FIFO_EN   = 3'b001;
localparam RD_WAIT      = 3'b010;
localparam RD_DATA      = 3'b011;

always @(posedge clk) begin
       case (state)
        IDLE: begin 
            r_grp_id <= w_grp_id;
            r_rd_dv <= 0;
            r_rd_data <= 0;
            flag_int_done <= 0;
                                   
            if(|int_ack)begin
                state <= RD_FIFO_EN;
            end else begin
                state <= IDLE;
            end
        end
        
        RD_FIFO_EN: begin
            flag_int_done <= 1;  // To deassert the generated interrupt for the slave_id
            
            /* Control signals to access the data of peripherals */
            r_rd_fifo_en[r_grp_id*GRP_WIDTH +: GRP_WIDTH] <=  ~rd_f_empty[r_grp_id*GRP_WIDTH +: REMAINDER]; // Fix the case width < 4
            r_strobe <= {{str_valid_len{1'b0}}, ~rd_f_empty[r_grp_id*GRP_WIDTH +: REMAINDER]}; // Only strobes are valid in UART as groping of UART and Slow protocol
            //r_slv_sel <= r_grp_id*GRP_WIDTH  ;
            r_slv_sel <= (r_grp_id*GRP_WIDTH) + TOTAL_UART;
            state <= RD_WAIT;
        end
        
        RD_WAIT: begin
            r_rd_fifo_en <= 0;
            state <= RD_DATA;
        end
        
        RD_DATA: begin
            r_rd_dv <= 1;
            
            r_rd_data[38:32] <= r_strobe;
            r_rd_data[39] <= 1;
            r_rd_data[46:40] <= r_slv_sel;
            r_rd_data[47] <= 0;
            for(k = 0; k < REMAINDER; k = k+1) begin
                if(r_strobe[k]) begin
                    r_rd_data[k*UART_DATA_WIDTH +: UART_DATA_WIDTH] <= rd_fifo_data[(r_grp_id+k)*UART_DATA_WIDTH +: UART_DATA_WIDTH];
                end
            end

            state <= IDLE;
        end

    endcase
end

assign rd_fifo_en       = r_rd_fifo_en;
assign rd_dv            = (r_rd_dv) ? r_rd_dv: 1'bz;
assign rd_data          = (r_rd_dv) ? r_rd_data: 48'bz;
assign interrupt        = r_int;
assign config_bus       = r_config_bus;
assign dt_fifo_enable   = r_dt_fifo_enable;
assign dt_fifo_data     = r_dt_fifo_data;
endmodule