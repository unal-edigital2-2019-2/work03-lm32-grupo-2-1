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
		parameter AW = 15 // Cantidad de bits  de la direcci�n 
		)(
		input init,
		input pclk,
		input rst,
		input vsync,
		input href,
		input [7:0] px_data,

		output reg [AW-1:0] mem_px_addr = -1 ,
		output reg[7:0]  mem_px_data,
		output reg px_wr 
		output reg done_image );

	reg [1:0]  FSM_state ; //Tres estados =  00: WAIT_FRAME_START &  01: ROW_CAPTURE & 11 DATA_OUT_RANGE EN LA FILA & 10: DONE ha enviado la imagen de (160x120) pero sigue recibiendo porque la camara envia (480x260)
    reg pixel_half ; //indica 0:medio pixel y 1 :pixel completo , se inicia en 1 para que en el primer flanco cambie a 0
	reg [AW:0] temp_rgb  ; //registro temporal para guardar pixel completo, asumiendo RGB565
	reg [10:0] widthimage  ; // registro que lleva el conteo del ancho de pixeles enviados (en 160 debe dentenerse)
	reg [10:0] lengthimage ;// registro que lleva la cuenta de filas de pixeles enviadas (en 120 debe detenerse)
	reg [7:0] mem_px_RG;
	reg vsync_old;
	reg href_old; 

	localparam Maxwidthimage = 160 ;     // tamaño maximo del ancho de la imagen 
	localparam Maxlengthimage = 120;    // tamaño maximo en largo de la imagen
	localparam WAIT_FRAME_START = 0;
	localparam ROW_CAPTURE = 1;
	localparam DATA_OUT_RANGE = 3;
	localparam DONE =  2;

	// Inicializando registros 
	initial begin
	mem_px_addr <= -1;
	FSM_state <= 2;
	pixel_half <= 1; 
	widthimage <= 0 ;
	lengthimage <= 0;
	end
	
always @( posedge pclk)begin 
	if(init)begin
		vsync_old <= vsync ;
		href_old <= href ;
		case(FSM_state)

			DONE:begin // Espero a leer un flanco de bajada de vsync y así sincronizar la imagen con su inicio
				FSM_state <= (!vsync && vsync_old)? WAIT_FRAME_START : DONE;
				px_wr <= 0;
				mem_px_addr <= -1;
				lengthimage <= 0;
			end
		
			WAIT_FRAME_START: begin // Ya hubo un flanco de bajada en vsync ahora esero a flanco de subida en href, tal como especifica el datasheet
				FSM_state <= (href && !href_old && !vsync) ? ROW_CAPTURE : WAIT_FRAME_START;
			
				px_wr <= 0 ;

			
			end
		/*Como aparece en el datasheet cuando vsync este bajo y href este alto , me estan enviando datos validos
		en los flancos de subida de (pclk) leo 1byte , cada dos flancos leo el pixel en RGB565, 
		*/
			ROW_CAPTURE: begin 
				FSM_state <= (href && href_old && !vsync)? ROW_CAPTURE : WAIT_FRAME_START;  
				//pixel_half <= ~ pixel_half;
					if ( pixel_half == 0) begin
						temp_rgb [15:8] <= px_data;
						px_wr <= 0;
					end else begin
						mem_px_addr <= mem_px_addr + 1;
						temp_rgb [7:0] <= px_data;
						mem_px_RG <= {temp_rgb[15:13], temp_rgb[10:8]}; //RGB565 a RGB33
						mem_px_data <= {mem_px_RG,temp_rgb[4:3]}; //Completamos concatenacion a RGB332
						px_wr <= 1;
						widthimage <= widthimage + 1 ;
								if (widthimage  == Maxwidthimage-1) begin
								widthimage <= 0 ;
								lengthimage <= lengthimage + 1 ;
									if(lengthimage == Maxlengthimage-1)begin
									FSM_state <= DONE;
									done_image <=1; 
									end	
								end 					
							end
		
			end		
		endcase
	end
end

always@(negedge pclk)begin
		if (FSM_state == ROW_CAPTURE) begin
			pixel_half <= ~ pixel_half;
		end
end


 



/********************************************************************************

Por favor colocar en este archivo el desarrollo realizado por el grupo para la 
captura de datos de la camara 

debe tener en cuenta el nombre de las entradas  y salidad propuestas 

********************************************************************************/
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