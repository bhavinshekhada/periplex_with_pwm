module pwm_generator(
    input                         empty,
    input  [PWM_FIFO_WIDTH-1:0]   i_data,
    input [CONFIG_DATA_WIDTH-1:0]   pwm_config_data, 
    output                        read,
    output reg [PWM_DATAWIDTH-1:0]    o_data=0,
    
    input                         clk,   
    output reg                    PWM_out = 0
);

parameter COUNTER_WIDTH = 32;
parameter PWM_DATAWIDTH = 64;
parameter PWM_FIFO_WIDTH = 8;
parameter CONFIG_DATA_WIDTH = 32;
reg [COUNTER_WIDTH-1:0] on_counter=0;
reg [COUNTER_WIDTH-1:0] off_counter=0;
reg value=0;
reg rd_en =0;
reg [PWM_DATAWIDTH-1:0] data_out=0;
reg [3:0] count=0;
reg[1:0] state=0;
localparam idle = 2'd0;
localparam hold = 2'd1;
localparam accumulate = 2'd2;
localparam done = 2'd3;

always @(posedge clk) begin
    case(state) 
        idle:begin
                
                if(!empty) begin
                        rd_en <= 1'b1;
                        state <= hold;
                end else begin
                        state <= idle;
                    end
                end

        hold:begin
                rd_en <= 0;
                state <= accumulate;
            end
         
        accumulate: begin
            data_out <= {data_out [PWM_DATAWIDTH-1:0] ,i_data};
               if (count < 7) begin
                    count <= count + 1;
                    state <= idle;
               end else begin
                    state  <= done; 
                end
            end
        
            done: begin
                o_data <=data_out;
                count <=0;
                state <= idle;
            end
    endcase    

end

assign read = rd_en;

always @(posedge clk) begin

    if (on_counter > 0) begin
        PWM_out <= 1;
        on_counter <= on_counter - 1;
    end else if (off_counter > 0) begin
        PWM_out <= 0;
        off_counter <= off_counter - 1;
    end else begin
           PWM_out <= ~PWM_out;
       if (value == 0) begin
            on_counter <= o_data[31:0]; 
            off_counter <= 0;
            value = 1; 
        end else begin
            on_counter <= 0; 
            off_counter <= o_data[63:32];
            value = 0; 
        end
    end
end

endmodule
