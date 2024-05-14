module uart_packetizer(
  input                             clk,
  input                             rx_dv,
  input [7:0]                       uart_byte,
  output [RAH_PACKET_WIDTH-1:0]     data_frame,
  output                            wr_en,
  output                            hold
);
    
parameter RAH_PACKET_WIDTH = 48;


reg [RAH_PACKET_WIDTH-1:0]      r1_data_frame = 0;
reg [RAH_PACKET_WIDTH-1:0]      r2_data_frame = 0;
reg                             r_wr_en = 0;
reg                             r_hold = 0;
reg [2:0]                       count = 0;

/* State Machine Parameters */
reg [1:0]  state = 0;
localparam IDLE         = 2'b00;
localparam DATA_FRAME   = 2'b01;
localparam CLEAN_UP     = 2'b10;

always @(posedge clk) begin
case(state)
  IDLE: begin // 0
    r1_data_frame <= 48'b0;
    r2_data_frame <= 48'b0;
    r_wr_en <= 1'b0;
    r_hold <= 1'b1;
    if(rx_dv) begin
      state <= DATA_FRAME;
      r1_data_frame[7:0] <= uart_byte;
      count <= count + 1;
    end else begin
      state <= IDLE;
    end
  end

  DATA_FRAME: begin // 1
    if(count < 6) begin
        if(rx_dv) begin
          count <= count + 1;
          r1_data_frame <= {r1_data_frame [39:0] ,uart_byte};
          state <= DATA_FRAME;
        end 
    end else begin
          state <= CLEAN_UP;
          count <= 0;
        end

  end
  
  CLEAN_UP: begin // 2
    r2_data_frame <= r1_data_frame;
    r_hold <= 0;
    r_wr_en <= 1;
    state <= IDLE;
  end
endcase
end

assign wr_en        = r_wr_en;
assign hold         = r_hold;
assign data_frame   = r2_data_frame;
endmodule