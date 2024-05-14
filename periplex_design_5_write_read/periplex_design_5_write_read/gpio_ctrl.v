module gpio_ctrl #(
       parameter DATAWIDTH = 8
)(
    input                         clock,
    input                         empty,
    input       [DATAWIDTH-1:0]   i_data,
    input       [DATAWIDTH-1:0]   gpio_config, //1 1 for config 0 then data
    
    output                        read,
    output      [DATAWIDTH-1:0]   gpio_oe,
    output  reg [DATAWIDTH-1:0]   gpio_out,
    output       [DATAWIDTH-1:0]  gpio_in
    
);

    reg [DATAWIDTH-1:0] g_data;// input i data
    reg [DATAWIDTH-1:0] g_in_data;// output gpio in input mode
    reg [DATAWIDTH-1:0] g_oe; // configuration 
    integer i;
    reg g_rd_en;
    
    reg [2:0] g_state=0;
    parameter idle = 3'd0;
    parameter setup = 3'd1;
    parameter configure = 3'd2;
    parameter hold = 3'd3; 
   // parameter configure = 3'd4;
    
    always @ (posedge clock) begin
        case(g_state)
            idle:
                begin
                     g_data <=0;
                     g_rd_en <=0;
                     g_oe <= gpio_config;
                    if(!empty) begin
                        g_rd_en <= 1'b1;
                        g_state <= setup;
                end
                    else begin
                        g_state <= idle;
                end
                end
                
            setup: 
                begin
                    g_rd_en <= 0;
                   g_state <= hold;
                end
                
                 hold:
                begin
                     g_data <= i_data;
                     g_state <= configure;
                end
             configure: 
                begin
                for (i = 0; i < DATAWIDTH; i = i + 1) begin
                        if (!g_oe[i]) begin
                            g_in_data[i] <= 0; 
                        end else begin
                            gpio_out[i] <= g_data[i];
                        end
                    end
                            g_state <= idle;
                end
         endcase
    end
   assign read = g_rd_en;
   assign gpio_oe = g_oe;
   assign gpio_in = g_in_data;
endmodule