module dt_ctrl(
    input                           clk,
    input [DATA_PACKET_WIDTH-1:0]   data_packet,
    input                           f_empty,
    
    output reg                      rd_en=0,
    output [UART_DATA_WIDTH-1:0]    data_byte,
    output                          we
);

/* Global parameters */
parameter DATA_PACKET_WIDTH = 51;
parameter UART_DATA_WIDTH   = 8;
parameter SEL_WIDTH         = 3;
parameter DATA_WIDTH        = 48;

/* Register declaration and instantiation */
reg [DATA_PACKET_WIDTH-1:0] c_data_packet = 0;
reg [UART_DATA_WIDTH-1:0]   c_data_byte = 0;
reg [SEL_WIDTH-1:0]         byte_count = 0;
reg [SEL_WIDTH-1:0]         c_sel = 0;
reg [DATA_WIDTH-1:0]        data = 0;
reg                         output_we = 0;

/* State Machine Parameters */
reg [1:0]  state = 0;
localparam IDLE         = 2'b00;
localparam DATA_FETCH   = 2'b01;
localparam DATA_DECODE  = 2'b10;
localparam DATA_SEND    = 2'b11;


always @(posedge clk) begin
    case (state)
        IDLE: begin
            if (!f_empty) begin
                rd_en <= 1;
                state <= DATA_FETCH;
            end
        end

        DATA_FETCH: begin
            rd_en <= 0; // Disable read enable while fetching data
            state <= DATA_DECODE;
        end
            
        DATA_DECODE: begin
            c_sel   <= data_packet[50:48]; // Extract sel bits from data_packet
            data    <= data_packet[47:0]; // Extract data bits from data_packet
            state   <= DATA_SEND;
        end  
                
        DATA_SEND: begin
            if (byte_count <= c_sel) begin
                c_data_byte <= data[byte_count * UART_DATA_WIDTH +: UART_DATA_WIDTH]; // Send bytes one by one
                output_we   <= 1; // Enable write enable during sending bytes
                byte_count  <= byte_count + 1;
                state       <= DATA_SEND; // Stay in data_decode state to send more bytes
            end
            else begin
                output_we   <= 0; // Disable write enable after sending required bytes
                c_data_byte <= 0;
                byte_count  <= 0; // Reset byte count for next data_packet
                state       <= IDLE; // Transition back to IDLE state
            end
        end
    endcase
end

assign data_byte = c_data_byte;
assign we = output_we;

endmodule