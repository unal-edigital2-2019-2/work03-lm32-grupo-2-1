# Documentación 3:  Integración controlador OV7670 con SoC

**Juan Carrillo** 1014290694

**Sebastian Betancourt** 1016089847

**Sara Ramos** 1020837947

Para esta entrega se nos pide: 
- Integrar por medio de Litex el controlador de la cámara.

##test_cam: 


###Diagrama de caja negra 

Como se puede ver cuenta con 8 entradas y 11 salidas. De las entradas 4 son relojes, 2 son señales de control y 2 son cadenas de caracteres
que indican la dirección y los datos enviados por la cámara. Las salidas son las señales de sincronización de la VGA, un reloj, el status,  
los datos que se envían a la VGA, data_mem es la salida de los datos, y CAM_reset y CAM_pwdw son pines. 



##Cam_read

###Diagrama de caja negra


###Máquina de estados