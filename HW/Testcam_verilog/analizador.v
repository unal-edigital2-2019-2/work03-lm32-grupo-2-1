`timescale 1ns / 1ps

module analizador(
            input [7:0] data,
            input clk, 
            input init,
            output reg [15:0] addr,
            output reg Done,
            output reg[2:0] valor
);

reg init_old;
reg sum;
reg [15:0] count;
reg [17:0] totr;
reg [17:0] totg;
reg [17:0] totb;

wire [2:0] datar;
wire [2:0] datag;
wire [2:0] datab;

initial begin 

        init_old <= 0;
        addr <= 15'h4b00;
        Done <= 0;
        count <= 0;
        totr <= 0;
        totg <= 0;
        totb <= 0;
        end 
assign datar = data[7:5];
assign datag = data[4:2];
assign datab = {data[2:0], 1'b0};

always @(posedge clk) begin
    if(init && !init_old)begin
			sum <= 1;
			Done <= 0;
			totr <= 0;
			totg <= 0;
			totb <= 0;
		end
    if(sum) begin
        if(count >= 19200)begin
			sum <= 0;
			count <= 0;
			addr <= 15'h7fff;
			Done <= 1;
        if ((totr > totg) && (totr > totb)) begin
            valor = 3'b100;
        end else begin
            if ((totg > totb) && (totg >totr)) begin
                valor = 3'b010;
            end else begin 
                if ((totg > totb) && (totg >totr)) begin
                    valor = 3'b001;
                end else begin
                    valor=3'b111; //Sin dato
                    end
                end
            end
    end else begin 
        addr <= addr+1;
        count <= count+1;
        totr <= totr+datar;
        totg <= totg+datag;
        totb <= totb+datab;
        Done <=0;
    end
end

    init_old=init;
end

endmodule
