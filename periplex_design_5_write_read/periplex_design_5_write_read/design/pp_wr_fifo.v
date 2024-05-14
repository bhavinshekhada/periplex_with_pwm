module pp_wr_fifo #(parameter WIDTH = 48, DEPTH = 128)(
    input clk,
    input wr_en,
    input [WIDTH-1:0] wr_data,
    input rd_en,
    output [WIDTH-1:0] rd_data, 
    output f_empty,
    output f_full,
    output f_a_empty
);
    
reg [WIDTH-1:0]    r_rd_data=0;
reg [$clog2(DEPTH)-1:0] wr_ptr=0, rd_ptr=0;
reg [WIDTH-1:0]    fifo [DEPTH-1:0];
integer                 count = 0;

always @(posedge clk)
begin
    if(wr_en && !f_full && rd_en && !f_empty)
    begin
        fifo[wr_ptr] <= wr_data;
        wr_ptr <= wr_ptr+1;
        count <= count;
        r_rd_data <= fifo[rd_ptr];
        rd_ptr <= rd_ptr+1;
        fifo[rd_ptr] <= 0;
    end
    else if(wr_en && !f_full)
    begin
        fifo[wr_ptr] <= wr_data;
        wr_ptr <= wr_ptr+1;
        count <= count + 1'b1;
    end
    else if(rd_en && !f_empty)
    begin
        r_rd_data <= fifo[rd_ptr];
        rd_ptr <= rd_ptr+1;
        count <= count - 1'b1;
        fifo[rd_ptr] <= 0;
    end
    else begin
        r_rd_data <= {WIDTH{1'b0}};
    end
end

assign rd_data = r_rd_data;
assign f_a_empty = (count==1) ? 1 : 0;

// assigning flags
assign f_full = (count == DEPTH);
assign f_empty = (count ==0);
endmodule