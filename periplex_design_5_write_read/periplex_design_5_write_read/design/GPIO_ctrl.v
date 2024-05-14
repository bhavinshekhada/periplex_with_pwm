module gpio_ctrl #(
       parameter DATAWIDTH = 8 ,CONFIG_DATA_WIDTH = 32
)(
    input                                   clock,
    input                                   empty,
    input       [DATAWIDTH-1:0]             i_data,
    input       [CONFIG_DATA_WIDTH-1:0]     gpio_config, 
    
    output                                  read,
    output  wire[DATAWIDTH-1:0]             gpio_oe,
    output  reg [DATAWIDTH-1:0]             gpio_out = 0,
    input       [DATAWIDTH-1:0]             gpio_in,
    
    /*read fifo signals*/
    output  [DATAWIDTH-1:0]      rd_gpio_out,
    output                       rd_fifo_en     
    
);  

reg [DATAWIDTH-1:0]         g_data = 0;
reg                         g_rd_fifo_en=0;
reg [DATAWIDTH-1:0]         gpio_in_prev = 0;
reg [DATAWIDTH-1:0]         gpio_in_new = 0;
reg [DATAWIDTH-1:0]         r_rd_gpio_out=0;
reg [CONFIG_DATA_WIDTH-1:0] g_oe = 0;  
reg [DATAWIDTH-1:0]         rw_config = 0;
reg [DATAWIDTH-1:0]         interrupt_config = 0;
reg [DATAWIDTH-1:0]         edge_config = 0;
integer                     i;
reg                         g_rd_en = 0;
reg [DATAWIDTH-1:0]         pos_edge_detected;
reg [DATAWIDTH-1:0]         neg_edge_detected;
reg [2:0]                   counter = 0;
/* fsm state parameters */    
reg [2:0] g_state=0;
localparam idle = 3'd0;
localparam setup = 3'd1;
localparam hold = 3'd2; 
localparam configure = 3'd3;
   
always @ (posedge clock) begin
          interrupt_config  <= gpio_config[15:8];
          edge_config       <= gpio_config[23:16];
          gpio_in_new       <= gpio_in;
          gpio_in_prev      <= gpio_in_new;
          r_rd_gpio_out     <= 0;
    case(g_state)
    
            idle:begin
                     g_data <=0;
                     counter <= 0 ;
                     g_rd_en <=0;
                     r_rd_gpio_out<=0;
                     g_oe <= gpio_config;
                     g_rd_fifo_en <=0;
                if(!empty) begin
                        g_rd_en <= 1'b1;
                        g_state <= setup;
                end else begin
                        g_state <= idle;
                    end
                end
                
            setup: begin
                    g_rd_en <= 0;
                    rw_config <= g_oe[7:0];
                    g_state <= hold;
                end
                
             hold:begin
                     g_data <= i_data;
                     g_state <= configure;
                end
             configure: begin
                for (i = 0; i < DATAWIDTH; i = i + 1) begin
                        if (!rw_config[i] ) begin
                            r_rd_gpio_out[i] <= gpio_in[i]; 
                            g_rd_fifo_en <=1;
                        end else 
                            gpio_out[i] <= g_data[i];
                        end
                        g_state <= idle;
                    end
                   
               endcase
pos_edge_detected <= gpio_in & ~gpio_in_prev;
neg_edge_detected <= ~gpio_in & gpio_in_prev;
 
 for (i = 0; i < DATAWIDTH; i = i + 1) begin
         if(interrupt_config[i]) begin
            if(pos_edge_detected[i])begin
                if (edge_config[i])begin
                        g_rd_fifo_en <= pos_edge_detected[i] ? 1'b1 : 1'b0;
                        r_rd_gpio_out[i] <= 1;                        
                        if(g_rd_fifo_en) begin 
                            g_rd_fifo_en <= 1'b0;
                        end
                    end 
                end 
        else if (neg_edge_detected[i]) begin
               if (!edge_config[i])begin
                    g_rd_fifo_en <= neg_edge_detected[i] ? 1'b1 :1'b0;
                    r_rd_gpio_out[i] <=1;
                     if(g_rd_fifo_en) begin 
                        g_rd_fifo_en <= 1'b0;
                    end
                end
            end 
        end 
   else begin
         r_rd_gpio_out[i] <= gpio_in[i]; 
        end 
      end
end

   assign rd_gpio_out = r_rd_gpio_out ;
   assign read = g_rd_en;
   assign gpio_oe = g_oe;
   assign rd_fifo_en= g_rd_fifo_en;
endmodule

