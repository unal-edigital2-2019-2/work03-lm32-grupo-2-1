`timescale 1ns / 1ps

module analizador(
            input [7:0] data,
            input clk, 
            input init,
            input rst, 
            output reg [15:0] addr;
            output reg Done;
            output reg[2:0] valor
);


reg sum;
reg [15:0] count;
reg [17:0] totr;
reg [17:0] totg;
reg [17:0] totb;

wire [2:0] datar;
wire [2:0] datag;
wire [2:0] datab;

initial begin 

        addr <= 15'h4b00;
        Done <= 0;
        count <= 0;
        totr <= 0;
        totg <= 0;
        totb <= 0;
        end 
assign datar = dator[7:5];
assign datag = dator[4:2];
assign datab = {dator[2:0]; 1'b0};

always @(posedge clk) begin
    if (rst) begin
		Done <= 0;	
		count = 0;
		totr = 0;
		totg = 0;
		totb = 0;
	end else begin  
            if(sum) begin
            if (dator[7] == 1 && dator[4] == 0 && dator[1] == 0) begin
            totr = totr + 1;
        end else if (dator[7] == 0 && dator[4] == 1 && dator[1] == 0) begin
            totg = totg + 1;
        end else if (dator[7] == 0 && dator[4] == 0 && dator[1] == 1) begin
            totb = totb + 1;
        end 
        always@(negedge clk)begin
	        if(sum)begin
		        if((totr > totg)&&(totr > totb))begin
		        result = 3'b100;
		        end else begin
		            if((totg > totr)&&(totg > totb))begin
		            result = 3'b010;
		            end else begin
		                if((totb > totr)&&(totb > totg))begin
		                    result = 3'b001;
		                end else begin
	                         result = 3'b000;
	                        end else begin 
                                if (count < 19200) begin
                                    count= count+1;
                                    addr <= addr+1;
                                    end else begin
                                    count=0;
                                    Done = 0;
                            end
                    end
               end
            end            

        end
    end


endmodule

 