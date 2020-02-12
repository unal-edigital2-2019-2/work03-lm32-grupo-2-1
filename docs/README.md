# Documentación 3:  Integración controlador OV7670 con SoC

**Juan Carrillo** 1014290694

**Sebastian Betancourt** 1016089847

**Sara Ramos** 1020837947

Para esta entrega se nos pide: 
- Integrar por medio de Litex el controlador de la cámara.

## test_cam 


### Diagrama de caja negra 
![] (https://github.com/unal-edigital2-2019-2/work03-lm32-grupo-2-1/blob/master/docs/figs/test_cam_caja.png)
Como se puede ver cuenta con 8 entradas y 11 salidas. De las entradas 4 son relojes, 2 son señales de control y 2 son cadenas de caracteres
que indican la dirección y los datos enviados por la cámara. Las salidas son las señales de sincronización de la VGA, un reloj, el status,
los datos que se envían a la VGA, data_mem es la salida de los datos y CAM_reset y CAM_pwdw son pines. 



## Cam_read

### Diagrama de caja negra
![] (https://github.com/unal-edigital2-2019-2/work03-lm32-grupo-2-1/blob/master/docs/figs/test_cam_caja.png)

### Máquina de estados

### Descripción

Tiene como entradas: init, pclk, rst, vsync, href, px_data y como salidas: los registros, mem_px_addr, mem_px_data, px_wr y done_image.

Internamente se tienen los siguientes registros: FSM_state, piel_half, temp_rgb, widthimage, lenghtimage, mem_px_RG, vsync_old y href_old.

Y los parámetros locales: Maxwidhtimage, Maxlenghtimage, WAIT_FRAME_START, ROW_CAPTURE, DATA_OUT_RANGE, DONE.

Posteriormente, se inicializan los siguientes registros: 

Y cada vez que hay un flanco de subida del pclk, se guardan vsync_old y href_old. Y se inicia un case con FSM_state. 

Para el primer caso, si es un flanco de bajada de vsync , se guarda en m
