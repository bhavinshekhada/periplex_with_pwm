`include "periplex.vh"

module rd_req_arb(
    input                               clk,
    input  [TOTAL_GRP-1:0]              i_interrupt,
    input                               rd_req_ack,
    output [TOTAL_GRP-1: 0]             rd_slave_id,
    output                              rd_req
);

/* Global parameters */

parameter TOTAL_UART  = `TOTAL_UART;
parameter TOTAL_GPIO_CTRLS = `TOTAL_GPIO_CTRLS;

parameter UART_TOTAL_GRP = ((TOTAL_UART + 3) >> 2); 
parameter GPIO_TOTAL_GRP = ((TOTAL_GPIO_CTRLS + 3) >> 2);
parameter TOTAL_GRP = UART_TOTAL_GRP + GPIO_TOTAL_GRP;

reg [TOTAL_GRP-1:0] mask = 1;
reg [TOTAL_GRP-1:0] masked_input = 0;
reg                   req = 0;

wire [(TOTAL_GRP)-1: 0] slave_id;
reg  [(TOTAL_GRP)-1: 0] r_slave_id = 0;

wire   flag;
assign flag = |i_interrupt;

reg [1:0] state = 0;

localparam IDLE     = 2'b00;
localparam REQUEST  = 2'b01;
localparam ACK      = 2'b10;


always @(posedge clk) begin
    case(state)
        IDLE: begin
            req <= 0;
            if(flag) begin
                masked_input = mask & i_interrupt;
                if(TOTAL_GRP > 1) begin
                    mask = {mask[TOTAL_GRP-2:0], mask[TOTAL_GRP-1]};
                end else begin
                    mask = 1;
                end
                if(|masked_input) begin
                    state <= REQUEST;
                end else begin
                    state <= IDLE;
                end
            end else begin
                state <= IDLE;
            end 
        end
        
        REQUEST: begin
            r_slave_id <= slave_id;
            req <= 1;
            state <= ACK;
        end
        
        ACK: begin
            if(rd_req_ack) begin
                req <= 0;
                r_slave_id <= 0;
                state <= IDLE;
            end
        end
    endcase
end

encoder enc (
    .in(masked_input),
    .out(slave_id)
);

assign rd_slave_id = r_slave_id;
assign rd_req = req;
endmodule

/* Ecoder for uart ID */
module encoder #( parameter WIDTH = TOTAL_GRP)(
    input wire [WIDTH-1: 0] in,
    output [(WIDTH)-1: 0] out
);

parameter TOTAL_UART  = `TOTAL_UART;
parameter TOTAL_GPIO_CTRLS = `TOTAL_GPIO_CTRLS;

parameter UART_TOTAL_GRP = ((TOTAL_UART + 3) >> 2); 
parameter GPIO_TOTAL_GRP = ((TOTAL_GPIO_CTRLS + 3) >> 2);
parameter TOTAL_GRP = UART_TOTAL_GRP + GPIO_TOTAL_GRP;

reg [(WIDTH)-1: 0] r_out = 0;

integer i;
always @* begin
    
    r_out = 'b0;
    for (i = 0; i < WIDTH; i = i + 1) begin
        if (in[i] == 1'b1) begin
            r_out = i;
        end
    end
end
  
assign out = r_out;
endmodule