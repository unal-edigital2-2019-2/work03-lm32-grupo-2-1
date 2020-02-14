`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:14:22 12/02/2019 
// Design Name: 
// Module Name:    cam_read 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module cam_read #(
		parameter AW = 17 // Cantidad de bits  de la direcci�n 
		)(
		input init,
		input pclk,
		input rst,
		input vsync,
		input href,
		input [7:0] px_data,

		output reg [AW-1:0] mem_px_addr = 0,
		output reg[7:0] mem_px_data ,
		output reg px_wr =0, 
		output reg done );

	reg [1:0]  FSM_state = 2; //Tres estados =  00: WAIT_FRAME_START &  01: ROW_CAPTURE & 11 DATA_OUT_RANGE EN LA FILA & 10: DONE ha enviado la imagen de (160x120) pero sigue recibiendo porque la camara envia (480x260)
    reg pixel_half  = 0; //indica 0:medio pixel y 1 :pixel completo , se inicia en 1 para que en el primer flanco cambie a 0
	reg [10:0] widthimage  ; // registro que lleva el conteo del ancho de pixeles enviados (en 160 debe dentenerse)
	reg [10:0] lengthimage ;// registro que lleva la cuenta de filas de pixeles enviadas (en 120 debe detenerse)
	//reg [7:0] mem_px_RG;
	reg vsync_old;
	reg href_old ;
	reg init_old; 
	

	localparam Maxwidthimage = 160 ;     // tamaño maximo del ancho de la imagen 
	localparam Maxlengthimage = 120;    // tamaño maximo en largo de la imagen
	localparam Maxaddr = Maxlengthimage*Maxwidthimage ;
	localparam WAIT_FRAME_START = 0;
	localparam ROW_CAPTURE = 1;
	localparam DATA_OUT_RANGE =3;
	localparam DONE =2;

	// Inicializando registros 	
always@(posedge pclk)begin 
if(rst)begin
mem_px_addr = 0;
FSM_state = 2;
done = 0;
pixel_half = 0;
end else begin 
	if(init && !init_old)begin
		case(FSM_state)
		DONE:begin // Espero a leer un flanco de bajada de vsync y así sincronizar la imagen con su inicio
				mem_px_addr = 0;
				lengthimage = 0;
				if(!vsync && vsync_old)begin 
				FSM_state = WAIT_FRAME_START;				
				end else begin
					FSM_state = DONE;
				end
			end		
		WAIT_FRAME_START: begin // Ya hubo un flanco de bajada en vsync ahora esero a flanco de subida en href, tal como especifica el datasheet
				if(!href_old && href )begin
				FSM_state = ROW_CAPTURE;
				mem_px_data[7:2] = {px_data[7:5], px_data[2:0]};
				px_wr = 0 ;
				pixel_half = ~pixel_half;
				end else begin
					if (vsync && !vsync_old ) begin
					done  = 1;
					FSM_state = DONE;
					end else begin
						FSM_state = WAIT_FRAME_START;
					end
				end	

			end
		/*Como aparece en el datasheet cuando vsync este bajo y href este alto , me estan enviando datos validos
		en los flancos de subida de (pclk) leo 1byte , cada dos flancos leo el pixel en RGB565, 
		*/
		ROW_CAPTURE: begin 
				if (href) begin  
					if ( pixel_half == 0) begin
						mem_px_data[7:2] = {px_data[7:5], px_data[2:0]};
						px_wr = 0;
					end else begin
						mem_px_data[1:0] = {px_data[4:3]}; //Completamos concatenacion a RGB332
						px_wr = #1 1;
						
						mem_px_addr = mem_px_addr + 1 ;
						widthimage = widthimage + 1 ;
						
								if (widthimage  > Maxwidthimage) begin
								widthimage = 0 ;
								lengthimage = lengthimage + 1 ;
								FSM_state = WAIT_FRAME_START;
									if(lengthimage > Maxlengthimage)begin
									done  = 1; 
									mem_px_addr = 0;
									FSM_state = DONE; 
									end	
								end 
								/*
								if(mem_px_addr < Maxaddr)begin
									px_wr = 1;
									mem_px_addr = mem_px_addr + 1 ;
								end else begin
									mem_px_addr = 0 ;
									FSM_state = WAIT_FRAME_START;
								end
								*/
				    end	
				pixel_half = ~ pixel_half;
				end else begin
					FSM_state = WAIT_FRAME_START;
				end			
		end
		endcase
	end else begin
	done = 0;
	px_wr = 0;
	end
end
vsync_old = vsync;
init_old = init ;
href_old = href ; 
end


endmodule


/*****************************************************************
	OBJETIVO DE ESTE MÓDULO:
	-Transformar los datos de entrada de RGB565 a RGB332
	-Enviar los datos transformados a la dpram
	---> este módulo solo interactua entre la cámara y la dpram <---

	**Cada ciclo del reloj pclk se envía un byte (es el mismo xclk)
	**El reloj href se pone en ALTO durante el envío de la fila (640x2 pclk)
	**hsync mantiene una señal con frecuencia estable dentro de la cual está 
	cada fila, de forma que se puedan sincronizar
	**vsync se pone en alto al inicio del frame y al final del frame

******************************************************************/