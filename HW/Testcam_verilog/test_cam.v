`timescale 1ns / 1ps
module test_cam(
    input wire clk,           // board clock: 32 MHz or 100MHz para nexys4
    input wire rst,         	// reset button

	// VGA input/output  
	/*
    output wire VGA_Hsync_n,  // horizontal sync output
    output wire VGA_Vsync_n,  // vertical sync output
    output wire [3:0] VGA_R,	// 4-bit VGA red output
    output wire [3:0] VGA_G,  // 4-bit VGA green output
    output wire [3:0] VGA_B,  // 4-bit VGA blue output
	*/
	//CAMARA input/output
	
	output wire CAM_xclk,		// System  clock imput
	output wire CAM_pwdn,		// power down mode 
	output wire CAM_reset,		// clear all registers of cam
	input wire CAM_pclk,
	input wire CAM_vsync,
	input wire CAM_href,
	input wire  CAM_px_data_0,		//Reloj que indica que se ha enviado toda una imagen completa
	input wire  CAM_px_data_1,
	input wire  CAM_px_data_2,
	input wire  CAM_px_data_3,
	input wire  CAM_px_data_4,
	input wire  CAM_px_data_5,
	input wire  CAM_px_data_6,
	input wire  CAM_px_data_7,
  // Conexios con el periferico 
  
  						 // Direccion que solicita el procesador 
	input   init,  		// inicia la caputa de una foto 
	// output wire status, //status : 1 si esta procesando una imagen y 0  si ya acabo de procersar una imagen
	output wire [2:0] result, //Datos de salida del dp_ram al procesador
	output wire done  );

// Configuraciones para SoC
wire [7:0] data = {CAM_px_data_7,CAM_px_data_6,CAM_px_data_5,CAM_px_data_4,CAM_px_data_3,CAM_px_data_2,CAM_px_data_1,CAM_px_data_0}; 


// TAMAÑO DE ADQUISICIÓN DE LA CAMARA 
parameter CAM_SCREEN_X = 160;
parameter CAM_SCREEN_Y = 120;

localparam AW = 15; // LOG2(CAM_SCREEN_X*CAM_SCREEN_Y) ADRRESS WIDTH
localparam DW = 8;  //  WIDTH

// El color es RGB 332
localparam RED_VGA =   8'b11100000;
localparam GREEN_VGA = 8'b00011100;
localparam BLUE_VGA =  8'b00000011;


// Clk 
wire clk32M;
wire clk25M;
wire clk24M;

// Conexión dual por ram

wire  [AW-1: 0] DP_RAM_addr_in;  //addres de cam_read al buffer_ram
wire  [DW-1: 0] DP_RAM_in;      // data de la cam_read a la memoria
wire DP_RAM_regW;             // dice cuando hay un pixel completo para ver 

wire  [AW-1: 0] DP_RAM_addr_out;  
	
// Conexión VGA Driver
 wire [DW-1:0]data_mem;	   // Salida de dp_ram al driver VGA
wire [DW-1:0]data_RGB332;  // salida del driver VGA al puerto
wire [9:0]VGA_posX;		   // Determinar la pos de memoria que viene del VGA
wire [8:0]VGA_posY;		   // Determinar la pos de memoria que viene del VGA
/* ****************************************************************************
la pantalla VGA es RGB 444, pero el almacenamiento en memoria se hace 332
por lo tanto, los bits menos significactivos deben ser cero
**************************************************************************** */
assign VGA_R = {data_RGB332[7:5],1'b0};
assign VGA_G = {data_RGB332[4:2],1'b0};
assign VGA_B = {data_RGB332[1:0],2'b00};



/* ****************************************************************************
Asignación de las señales de control xclk pwdn y reset de la camara 
**************************************************************************** */

assign CAM_xclk =  clk25M;    // debe ir a clk24Mhz con el PLL y con el divisor va a clk25Mhz
assign CAM_pwdn=  0 ;			// power down mode 
assign CAM_reset=  1  ;



/* ****************************************************************************
  Este bloque se debe modificar según sea le caso. El ejemplo esta dado para
  fpga Spartan6 lx9 a 32MHz.
  usar "tools -> Core Generator ..."  y general el ip con Clocking Wizard
  el bloque genera un reloj de 25Mhz usado para el VGA  y un relo de 24 MHz
  utilizado para la camara , a partir de una frecuencia de 32 Mhz
**************************************************************************** */
//assign clk32M =clk;
/*
clk24_25_nexys4  clk25_24(
  .CLK_IN1(clk),
  .CLK_OUT1(clk25M),
  .CLK_OUT2(clk24M),
  .RESET(rst)
 );
*/
/* ***************************************************************************
Prueba con modulo de divisor de frecuencia salida de 25Mhz
**************************************************************************** */

divisor divisor(
	 
	.clki(clk),
	.clko(clk25M)	

);


/* ****************************************************************************
buffer_ram_dp buffer memoria dual port y reloj de lectura y escritura separados
Se debe configurar AW  según los calculos realizados en el Wp01
se recomiendia dejar DW a 8, con el fin de optimizar recursos  y hacer RGB 332
**************************************************************************** */
buffer_ram_dp #( AW,DW)DP_RAM(  
	.clk_w(CAM_pclk), 
	.addr_in(DP_RAM_addr_in), 
	.data_in(DP_RAM_in),
	.regwrite(DP_RAM_regW), 
	
	.clk_r(clk25M), 
	.addr_out(DP_RAM_addr_out),
	.data_out(data_mem)
	);
	
	

/* ****************************************************************************
VGA_Driver640x480
**************************************************************************** */
/*
VGA_Driver640x480 VGA640x480
(
	.rst(rst),
	.clk(clk25M), 				// 25MHz  para 60 hz de 640x480
	.pixelIn(data_mem), 		// entrada del valor de color  pixel RGB 332 
	.pixelOut(data_RGB332), // salida del valor pixel a la VGA 
	.Hsync_n(VGA_Hsync_n),	// se�al de sincronizaci�n en horizontal negada
	.Vsync_n(VGA_Vsync_n),	// se�al de sincronizaci�n en vertical negada 
	.posX(VGA_posX), 			// posici�n en horizontal del pixel siguiente
	.posY(VGA_posY) 			// posici�n en vertical  del pixel siguiente

);
*/
/* ****************************************************************************
captura_datos_downsampler Transformar los datos de formato RGB565 A RGB332 y enviar a la memoria
**************************************************************************** */
 wire done_image;
cam_read cam_read(
	.rst(rst),
	.init(init),
	.done(done_image),
	.px_data(data), 		// Los datos de la camara 
	.href(CAM_href), 		// reloj de la camara cada ventana
	.pclk(CAM_pclk),		//reloj de la camara cada medio dato
	.vsync(CAM_vsync),  	// reloj cada foto 
	// Conexiones modulocaptura - memoria RAM 
	.mem_px_addr(DP_RAM_addr_in),			//direccion enviada a la camara
	.mem_px_data(DP_RAM_in),			// datos enviados a la Memoria
	.px_wr (DP_RAM_regW)						// cuando leer datos

 );
 
 
/* ****************************************************************************
LÓgica para actualizar el pixel acorde con la buffer de memoria y el pixel de 
VGA si la imagen de la camara es menor que el display  VGA, los pixeles 
adicionales seran iguales al color del último pixel de memoria 
**************************************************************************** */
/*
always @ (VGA_posX, VGA_posY) begin
		if ((VGA_posX>CAM_SCREEN_X-1) || (VGA_posY>CAM_SCREEN_Y-1))
			DP_RAM_addr_out = 15'b111111111111111;
			
		else
			DP_RAM_addr_out=VGA_posX+VGA_posY*CAM_SCREEN_X;
end
*/
analizador analizador (
	.data(data_mem),
	.clk(clk25M),
	.init(done_image),
	.addr(DP_RAM_addr_out),
	.Done(done),
	.valor(result)
);
endmodule
