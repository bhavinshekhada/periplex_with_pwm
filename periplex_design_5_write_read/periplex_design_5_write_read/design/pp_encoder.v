module pp_encoder(
    input                               clk,
    input                               rd_req,
    input [TOTAL_GRP-1: 0]              rd_slave_id,
    input                               rd_dv,
    input [RD_DATA_BUS_WIDTH-1:0]       rd_data,
    output                              rd_req_ack,
    output [TOTAL_GRP-1:0]              int_ack,
    output                              fifo_en,
    output [RD_DATA_BUS_WIDTH-1:0]      fifo_data
);

/* Global parameters */
parameter UART_TOTAL_GRP = ((TOTAL_UART + 3) >> 2); 
parameter GPIO_TOTAL_GRP = ((TOTAL_GPIO_CTRLS + 3) >> 2);
parameter TOTAL_GRP = UART_TOTAL_GRP + GPIO_TOTAL_GRP;

parameter TOTAL_UART        = `TOTAL_UART;
parameter TOTAL_GPIO_CTRLS = `TOTAL_GPIO_CTRLS;
parameter RD_DATA_BUS_WIDTH = 48;

/* Register Declaration and Initializations */
reg  [$clog2(TOTAL_GRP)-1: 0] r_rd_slave_id = 0;
reg [TOTAL_GRP-1:0]           r_int_ack = 0;
reg [RD_DATA_BUS_WIDTH-1:0]   r_rd_data = 0;
reg                           r_fifo_en = 0;
reg [RD_DATA_BUS_WIDTH-1:0]   r_fifo_data = 0;
reg                           r_rd_req_ack = 0;

/* State Machine Parameters */
reg [2:0] state         = 0;
localparam IDLE         = 3'b000;
localparam RD_REQ       = 3'b001;
localparam READ_DATA    = 3'b010;
localparam FIFO_WRITE   = 3'b011;



always @(posedge clk) begin
    case(state)
        IDLE: begin
            r_rd_req_ack <= 0;
            r_fifo_en <= 0;
            r_fifo_data <= 0;
            
            if(rd_req) begin
                r_rd_slave_id <= rd_slave_id;
                state <= RD_REQ;
            end else begin
                state <= IDLE;
            end
        end
        
        RD_REQ: begin
            r_int_ack[r_rd_slave_id] <= 1;
            state <= READ_DATA;
        end
        
        READ_DATA: begin
            r_int_ack <= 0;
            if(rd_dv) begin
            r_rd_req_ack <=1;
                r_rd_data <= rd_data;
                state <= FIFO_WRITE;
            end else begin
                state <= READ_DATA;
            end
        end
        
        FIFO_WRITE: begin
           r_rd_req_ack <= 0;
            r_fifo_en <= 1;
            r_fifo_data <= r_rd_data;
            state <= IDLE;
        end
    endcase
end

assign rd_req_ack   = r_rd_req_ack;
assign fifo_en      = r_fifo_en;
assign fifo_data    = r_fifo_data;
assign int_ack      = r_int_ack;

endmodule