module test_tx_ctrl(
    input           clk,
    input           f_empty,
    input [47:0]    data,
    output          rd_en,
    
    // UART Tx signals
    input           tx_done,
    output          tx_dv,
    output [7:0]    tx_byte
);

/* Register declaration*/
reg             r_rd_en = 0;
reg [47:0]      r_data = 0;
reg [3:0]       count = 0;
reg             r_uart_dv = 0;
reg [7:0]       r_uart_data = 0;

/* State Macine Parameters */
reg [2:0] state = 0;
localparam IDLE = 3'b000;
localparam READ_EN = 3'b001;
localparam READ  = 3'b010;
localparam UART_TX = 3'b011;
localparam UART_ACK = 3'b100;

always @(posedge clk) begin
    case (state) 
        IDLE: begin
            r_uart_data <= 0;
            if(!f_empty) begin
                r_rd_en <= 1;
                state <= READ_EN;
            end else begin
                state <= IDLE;
            end
        end
        
        READ_EN: begin
            r_rd_en <= 0;
            state <= READ;
        end
        
        READ: begin
            r_data <= data;
            state <= UART_TX;
        end
        
        UART_TX: begin
            if (count < 6) begin
                r_uart_dv <= 1;
                r_uart_data <= r_data[count*8 +: 8];
                state <= UART_ACK;
            end else begin
                count  <= 0; 
                state  <= IDLE; 
            end
        end
        
        UART_ACK: begin
            r_uart_dv <= 0;
            if(tx_done) begin
                count <= count + 1;
                state <= UART_TX;
            end else begin
                state <= UART_ACK;
            end
        end
        
    endcase
end

assign rd_en = r_rd_en;
assign tx_dv = r_uart_dv;
assign tx_byte = r_uart_data;

endmodule