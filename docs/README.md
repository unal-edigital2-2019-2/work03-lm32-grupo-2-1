# Documentación 3:  Integración controlador OV7670 con SoC

**Juan Carrillo** 1014290694

**Sebastian Betancourt** 1016089847

**Sara Ramos** 1020837947


## Primera Entrega: Captura de datos con la cámara.
### Introducción:

Para esta entrega se requiere que la cámara muestre una franja de colores en la pantalla con un tamaño de 176 y 144.

Adicional a los módulos que se plantean originalmente se plantean los siguientes módulos:
#### Captura_datos_downsampler

<img src="https://github.com/unal-edigital2-2019-2/work01-camara-grupo-2/blob/master/docs/figs/downsampler.png?raw=true" width = "450">

Este módulo busca hacer la captura del dato para pasarlo a la memoria DP_RAM.

Tiene 4 entradas `href`, `pckl`, `vysnc` y `data`; los tres primeros son clocks y el último es una cadena de 8 caracteres. Además tiene 3 salidas `DP_RAM_addr_out`, `DP_RAM_data_out`, `DP_RAM_regW`; el primero es una cadena de 15 caracteres, el segundo una cadena de 8 caracteres y el tercero es un registro que autoriza la escritura en la DP_RAM. 

Cuenta también con 5 registros `FSM_state`, `pixel_half`, `temp_rgb`, `widthimage` y  lengthimage; el primero es una cadena de 2 caracteres y indica cuatro posibles estados `WAIT_FRAME_STAR(00)` , `DATA_OUT_RANGE(11)`, `DONE (10)` y  `ROW_CAPTURE (01)`; el segundo indica si se está almacenando medio pixel o uno completo, el tercero es una cadena de 16 caracteres en la cual se guarda el pixel completo asumiendo RGR565, el cuarto lleva el conteo del ancho de pixeles enviados y el último lleva el conteo de filas enviadas. 

##### Funcionamiento:

Funciona con un flanco de subida del reloj y tiene diferentes casos que depende de `FSM_state`: 
- Caso 1:  `DONE` se encarga de enviar la imagen a la memoria y espera otra imagen. 
- Caso 2:   `DATA_OUT_RANGE` evita que los datos que están fuera del rango de pantalla sean envíados a la memoría. 
- Caso 3:  `WAIT_FRAME_START` espera por VSYNC
- Caso 4:  `ROW_CAPTURE` guardar el dato

Para el primer caso (`DONE`) ya se ha llenado la memoria,  sin embargo como la cámara sigue tomando imagenes; por lo tanto, si vsync es igual a 0 se mantiene el valor de acabado, es decir no se ha iniciado el proceso de gardar en memoria una nueva imagen y si no se cumple esto si no que vsync es 1 se inicializan todos los valores de nuevo; se guarda en  `DP_RAM_regW `, en  `DP_RAM_addr_out ` y en lengthimage 0; y se inicializa  `ROW_CAPTURE ` . 

En el segundo caso, si `href`  es 1 se mantiene en caso de que los pixeles se hayan salido del rango; en el caso contrario en widthimage y `DP_RAM_regW` se guarda 0 inicializando  `ROW_CAPTURE`.

El tercer estado se mantiene si href es 0. En caso contrario, se inicializa  `ROW_CAPTURE`. 

La captura inicia cuando hay un flanco positivo en el pclk y href. Cuando esto pasa y pixel_half es 0 en temp_rgb se guardan los datos de data y en  `DP_RAM_regW` se guarda 0, con lo cual no se autoriza. De lo contrario la dirección de salida se aumenta en 1, en temp_rgb se guarda data, en  `DP_RAM_data_out` se guardan los tres posibiles registros de temp_rgb, se autoriza la escritura en buffer_dp_ram guardando 1 en  `DP_RAM_regW ` y se aumenta el ancho de la imagen. En caso de que se alcance el máximo tamaño se guarda en  `FSM_state `  `DATA_OUT_RANGE`. En caso contrario, se inicializa  `WAIT_FRAME_START `.

Si href es 0 se aumenta el tamaño de la longitud de una pantalla; en caso de que se alcance el tamaño de longitud máxima se guarda en FSM_state DONE. 
 

Para el cambio de RGB565 a RBG332 se usa la siguiente línea: 
##### DP_RAM_data_out = {temp_rgb[15:13], temp_rgb[10:8],temp_rgb[4:3]}.
En este caso lo que se hace es tomar los bits más significativos de temp_rgb desde la posición 15 hasta la 11; después se toman los más significativos de la 10 a 5 y los más significativos de la 4 a la 1 y se concatenan en la saldia de ocho caracteres.  

#### test_cam:

<img src="https://github.com/unal-edigital2-2019-2/work01-camara-grupo-2/blob/master/docs/figs/t_cam.png?raw=true" width = "250">

- Se le agregó el módulo del captura_datos_downsampler.
Esto se hace instanciado sus variables de entrada: data, vsync, href y pclk. Y sus variables de salida:  `DP_RAM_addr_out `, 
`DP_RAM_data_out` y  `DP_RAM_regW. ` 

## Segunda entrega
Para esta segunda entrega, se nos pidió hacer lo siguiente:

- Crear el módulo `cam_read.v`, encargado de hacer dos tareas:

  - Capturar los datos generados por la cámara en formato RGB565
  - Transformar el formato RGB565 a RGB332

- Instanciar el módulo dentro del proyecto completo `test_cam.xise`, de tal forma que fuese posible simular y probar el funcionamiento del módulo.

La creación del módulo `cam_read.v` se hizo basada en un otro módulo utilizado para la cámara OV7670 al cuál se le hicieron cietras modificaciones:

- Tiene un diagrama de caja negra que es el siguiente:

<img src="https://github.com/unal-edigital2-2019-2/work02-simulation-grupo-2/blob/master/docs/figs/caja_negra.png?raw=true" width = "750" >
- Y funciona de la siguiente manera:

Teniendo en cuenta la imagen, `pclk`, `vsync` y `href` son puertos que reciben las señales generadas por la cámara para la sincronización de los datos. `px_data` recibe los datos generados por la cámara. `mem_px_addr` envía a la memoria ram la dirección en la que debe ir  ubicada cierta información de los pixeles. `mem_px_data` es el puerto que envía los datos. `px_wr` es una señal que autoriza la escritura de datos en la memoria ram.

- Funciona con una máquina de estados que tiene cuatro estados:
  - `WAIT_FRAME_START`, que es el estado inicial, es el encargado de detectar cuando se empieza un fotograma, observando cambios en la señal `vsync`
  - `ROW_CAPTURE`, es el estado en el cuál se capturan los datos de una fila de pixeles.
  - `DATA_OUT_RANGE`, es un estado que avisa cuando ya se tiene la totalidad de los datos de una fila.
  - `DONE`, avisa cuando un fotograma ya está completo y se puede pasar a capturar otro.

Cada pixel tiene dos Bytes de información, los cuales la cámara envía a traves de un puerto de un Byte, por lo que la información completa de un pixel se recibe luego de dos ciclos de reloj. Para hacer el almacenamiento y envío correcto de esta información se crearon dos elementos en el módulo:

- Un registro temporal `temp_rgb`, que tiene el tamaño suficiente para almacenar un pixel completo.
- Una señal llamada `pixel_half`, la cuál está encargada de mostrar 0 si el registro `temp_rgb` tiene la información de medio pixel, o 1 si tiene la información de un pixel completo, estando lista para ser enviada.

Una vez ya está la información de un pixel lo siguiente es hacer una compresión de la imágen, pasandola de `RGB565` a `RGB332`, esto fue hecho en código a traves de una concatenación, tomando partes específicas del registro `temp_rgb` y asignandolas a la salida `mem_px_data`, que las envía a la memoria ram de dos puertos:

```verilog
mem_px_data = {temp_rgb[15:13], temp_rgb[10:8],temp_rgb[4:3]};
```


La máquina de estados funciona teniendo en cuenta las señales de control de la cámara `vsync` y `href`, las cuales se encargan de mostrar los momentos en los que la cámara está haciendo captura de imágenes.

El módulo está configurado para hacer captura de imágenes en tamaño `QQCIF` (120 x 160). Si se desea usarlo para otro formato como `QCIF` O `CIF`, se deben configurar los parámetros `Maxwidthimage` y `Maxlengthimage` a los valores deseados.

### Proceso de simulación

Habiendo instanciado el módulo con el resto del hardware, procedimos a hacer la simulación.

La simulación fue realizada gracias a una herramienta online creada por Eric Eastwood. Disponible en https://ericeastwood.com/lab/vga-simulator/. Este simulador cuenta con todas las consideraciones necesarias para simular,  requiere un archivo del cuál toma los datos para el primer frame de imagen, los siguientes frames ya dependen de la información otorgada por la cámara, que en este caso será iformación contenida en el testbench.

Al hacer la simulación y dejarla correr cierto tiempo, empezó a generar imágenes, las cuales se muestran a continuación:

<img src="https://github.com/unal-edigital2-2019-2/work02-simulation-grupo-2/blob/master/docs/figs/double.png?raw=true" width = "750" >

En esta imágen se puede ver que el software generó en el primer frame la cámara, con los colores azul y morado, los cuales se definen poniendolos como información en hexadecimal en el documento `image.mem`. El segundo frame contiene la imagen que debe salir de la cámara, la cuál se encuentra definida y puede ser modificada en el testbench.

Al acercar la imágen del segundo frame podemos ver lo siguiente:

<img src="https://github.com/unal-edigital2-2019-2/work02-simulation-grupo-2/blob/master/docs/figs/red_close.png?raw=true" width = "750" >

Esto lo interpretamos como puntos que quedaron sin información en la memoria ram. Se puede ver a traves de ellos y lo que se ve detras es la imágen del frame anterior.


## Tercera Entrega
Para esta entrega se nos pide: 
- Integrar por medio de Litex el controlador de la cámara.

### test_cam.v 


#### Diagrama de caja negra 

<img src="https://github.com/unal-edigital2-2019-2/work03-lm32-grupo-2-1/blob/master/docs/figs/test_cam_caja.png?raw=true" width = "250">

#### Descripción

Como se puede ver cuenta con 8 entradas y 11 salidas. De las entradas 4 son relojes, 2 son señales de control y 2 son cadenas de caracteres
que indican la dirección y los datos enviados por la cámara. Las salidas son las señales de sincronización de la VGA, un reloj, el status,
los datos que se envían a la VGA, data_mem es la salida de los datos y `CAM_reset` y `CAM_pwdw` son pines. 

Tiene 7 wires, tres son relojaes de distintas frecuencias (32M, 25M y 24M), 1 indica una dirección, 1 tiene el dato del `cam_read`, 1 wire que indica cunado hay un pixel completo y 1 wire de salida del driver VGA al puerto.  


### Cam_read.v

#### Diagrama de caja negra

<img src="https://github.com/unal-edigital2-2019-2/work03-lm32-grupo-2-1/blob/master/docs/figs/test_cam_caja.png?raw=true" width = "250">


### Máquina de estados

### Descripción

Tiene como entradas: `init`, `pclk`, `rst`, `vsync`, `href`, `px_data` y como salidas los registros: `mem_px_addr`, `mem_px_data`, `px_wr` y `done_image`.

Internamente se tienen los siguientes registros: `FSM_state`, `pixel_half`, `temp_rgb`, `widthimage`, `lenghtimage`, `mem_px_RG`, `vsync_old` y `href_old`.

Y los parámetros locales: `Maxwidhtimage`, `Maxlenghtimage`, `WAIT_FRAME_START`, `ROW_CAPTURE`, `DATA_OUT_RANGE`, `DONE`.

Posteriormente, se inicializan los siguientes registros: 
<img src="https://github.com/unal-edigital2-2019-2/work03-lm32-grupo-2-1/blob/master/docs/figs/init_reg_cam_read.png?raw=true" width = "250">


La captura se compone de tres estados que se evaluan cada vez que hay un flanco de subida del `pclk`; enseguida se guardan en los `vsync_old` y `href_old` los valores de `vsync` y `href`, respectivamente; y se inicia un case con  `FSM_state`. 

Para el primer caso `DONE`, si es un flanco de bajada de vsync , se guardan los siguientes valores: 
```verilog
mem_px_data <= -1 ;
px_wr <= 0;
lenghtimage <=0;
```

Para el segundo estado `WAIT_FRAME_START`, se espera el flanco de subida en href. Tal y como se dice en la datasheet, cada dos flancos de subida de href se lee un pixel en  RGB565. Para este caso:

```verilog
px_wr <= 0;
```
El último estado es `ROW_CAPTURE`, para el cual se tiene que:
Si el registro `pixel_half` es igual a 0: 

```verilog
temp_rgb [15:8] <= px_data;
px_wr <= 0;
```

En caso de que  `pixel_half` sea diferente de 0:

```verilog
mem_px_addr <= mem_px_addr + 1;
temp_rgb [7:0] <= px_data;
mem_px_RG <= {temp_rgb[15:13], temp_rgb[10:8]}; 
mem_px_data <= {mem_px_RG,temp_rgb[4:3]}; 
px_wr <= 1;
widthimage <= widthimage + 1;
```
Además, en este case también se evalua si se completo toda la captura. Esto se revisa mirando las dimensiones máximas de la imagen que se va a capturar. 

Para esto, primero se mire si la fila ya está completa; en caso de que sea así se tiene: 

```verilog
widthimage <= 0 ;
lengthimage <= lengthimage + 1;

```

Después de esto se verifica si las columnas están completas, de ser así:

```verilog
FSM_state <= DONE; //Regresa al estado DONE 
done_image <=1; //Indica que ya se hizo la imagen. 
```

Por útlimo, si el  `FSM_state` está en el estado `ROW_CAPTURE` en un flanco de bajada, se mueve el `pixel_half`.

### Protocolo UART

UART son las siglas de *Universal Asynchronous Receiver-Transmitter* que traducido es **Transmisor Receptor Asíncrono Universal**. Este protocolo es utilizado para comunicación serie entre dispositivos digitales. El UART toma bytes de datos y transmite los bits individuales de forma secuencial. En el destino, un segundo UART reensambla los bits en bytes completos. 

<img src="https://github.com/unal-edigital2-2019-2/work02-simulation-grupo-2/blob/master/docs/figs/UART2.jpeg?raw=true" width = "550" >

Las funciones principales de chip UART son: manejar las interrupciones de los dispositivos conectados al puerto serie y convertir los datos en formato paralelo, transmitidos al bus de sistema, a datos en formato serie, para que puedan ser transmitidos a través de los puertos y viceversa.

El diagrama de tiempo del uart se muestra a continuación:

<img src="https://github.com/unal-edigital2-2019-2/work02-simulation-grupo-2/blob/master/docs/figs/UART.jpg?raw=true" width = "550" >


El uso del protocolo UART es pertinente cuando:
- Se requiere una línea comunicación barata entre dos dispositivos
- No es necesaria alta velocidad de transmisión

### Bus Wishbone

El Wishbone es un bus de hardware de código abierto creado para estandarizar la forma en que se comunican dos circuitos integrados. El objetivo es permitir la conexión de cores diferentes dentro de un chip.

<img src="https://github.com/unal-edigital2-2019-2/work02-simulation-grupo-2/blob/master/docs/figs/wishbone_graph.png?raw=true" width = "550" >

Cada una de las señales tiene una función:

- Las señales `RST_I` y `CLK_I`, compartidas tanto por el maestro como por el esclavo, son generadas por el controlador del sistema (`SysCon`)
- La salida de dirección del maestro `ADR_O0` es recibida por enrada de dirección `ADR_I0` del esclavo.
- Tanto el maestro como el esclavo comparten las señales de entrada `DAT_I0` y `DAT_O0`, cada uno alimentando de datos al otro
- La *write enable output* `WE_O` indica si el ciclo de bus del momento es de tipo *lectura* o *escritura*. La señal es negada para ciclos de *lectura* y de forma corriente para ciclos de *escritura*
- El *select output array* `SEL_O` indica de donde se esperan los datos válidos para la señal `DAT_I` durante los ciclos de lectura, y dónde se tienen que colocar en `DAT_O` durante los ciclos de escritura
- `STB_O` se usa cuando el maestro le quiere hacer saber al esclavo que un envío de datos está el proreso
- El esclavo le indica al maestro que ya ha recibido los datos a traves de `ACK_O` a `ACK_I` (de esclavo a maestro)
- Para indicar que los datos han sido capturados o que se ha visto un ciclo, se usa la señal `CYC_O` (de maestro a esclavo)



### Resuktados obtenidos:

<video src="https://github.com/unal-edigital2-2019-2/work03-lm32-grupo-2-1/blob/master/docs/figs/Generaci%C3%B3n_imagen_pantalla.mp4" width="320" height="200" controls preload></video>

<img src="https://github.com/unal-edigital2-2019-2/work03-lm32-grupo-2-1/blob/master/docs/figs/Color_bar.jpeg" width = "550" >



