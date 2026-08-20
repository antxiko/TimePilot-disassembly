# En el emulador

Todo lo demás de estas páginas sale de leer el binario. Esta página es lo
contrario: son medidas, tomadas sobre el cartucho corriendo en openMSX, y cada
una dice sobre qué ventana se ha tomado. Lo que no se ha medido, no está.

## Cómo se ha medido

La base es **una partida de verdad**, jugada y grabada en un Philips VG-8020 con
`tools/omsx_graba.tcl`: 170 segundos, la época 1 de t=10 a t=134, la 2 hasta
t=164 y el fin de partida en t=166. El replay se guarda entero, así que las
medidas se pueden repetir tantas veces como haga falta sobre exactamente la
misma partida.

`tools/omsx_repasa.tcl` la recorre segundo a segundo leyendo la RAM del juego y
dice en qué estado está en cada momento —demo o partida, época, ronda, vidas,
enemigos que faltan—, y con eso se elige la ventana: **de t=30 a t=90**, sesenta
segundos seguidos de partida en la época 1, sin demo por medio.

Luego `tools/omsx_mide.tcl` pone dos puntos de ruptura, uno en la entrada del
gancho del cartucho (0x4037) y otro en su salida (0x4112), y cronometra el
tiempo emulado entre los dos.

## Lo que tarda la interrupción

| | |
|---|---|
| interrupciones de la ROM en 60 s emulados | 2.980 |
| cuadros por segundo | 49,67 |
| tiempo dentro del gancho | 30,07 s de 60 |
| **porcentaje del cuadro** | **50,11 %** |
| por interrupción | 10,09 ms de un cuadro de 20,1 |
| la más corta / la más larga | 0,07 ms / 15,15 ms |

O sea que **la mitad del tiempo de la máquina se la lleva la interrupción del
cartucho**, y la otra mitad es todo lo que queda para el programa principal.

La cifra está comprobada con un segundo método que no comparte nada con el
primero: muestrear el contador de programa cada milisegundo y contar cuántas
muestras caen con la interrupción en marcha. Salen 30.048 muestras de 59.910,
o sea el **50,16 %** (`tools/omsx_control_pc.tcl`).

## Cuánto cuesta cada fase del ciclo de seis

La interrupción no hace lo mismo en todos los fotogramas: 0xE01F cuenta de 0 a 5
y cada fase mueve una cosa. Midiendo por fase, en la misma ventana:

| fase | qué mueve | ms de media |
|---|---|---|
| 0 | los disparos, las nubes, el avión y los choques | 10,18 |
| 1 | los enemigos | 10,14 |
| 2 | el fondo que se desplaza | 11,10 |
| 3 | los enemigos | 10,17 |
| 4 | el bicho grande y la cuenta de la fase | 8,81 |
| 5 | los enemigos | 10,17 |

Entre la fase más cara y la más barata hay **2,3 milisegundos**: el reparto está
equilibrado de verdad, no es solo una manera de ordenar el trabajo.

## Al VDP, por fotograma

| | |
|---|---|
| escrituras al puerto 0x98 (datos) | 360,6 |
| escrituras al puerto 0x99 (dirección) | 106,6 |

De las 360,6 de datos, **96 son siempre las mismas**: la tabla de atributos de
sprite entera, que la interrupción sube en cada fotograma desde su copia en RAM
(0x40CA) sin mirar si ha cambiado algo.

## Cuanto más hay volando, más cuesta

El 50 % de arriba es una ventana tranquila. Midiendo otras dos, con el mismo
método:

| ventana | qué pasaba | % del cuadro |
|---|---|---|
| replay, t=30 a t=90 | partida, época 1 | 50,11 % |
| 30 s pilotando | partida, época 1, de 25 a 17 enemigos por derribar | 59,04 % |
| 60 s de demo | la demo, que dispara sin parar | 71,32 % |

Las tres son medidas, no estimaciones. Lo que **no** está medido es el reparto
de esa diferencia: lo único que se puede decir sin salirse de lo comprobado es
que la ventana más cara es la que tiene más cosas en el aire, y que la demo,
que aprieta el botón en todos los fotogramas, es el peor caso de las tres.

## La trampa que costó una tarde

El primer intento de medir el coste fue muestrear el contador de programa y
contar cuántas muestras caían **entre 0x4037 y 0x4117**, que es el trozo de
cartucho donde vive el gancho. Salió un **1,20 %**.

Esa cifra no mide nada: el gancho llama a rutinas repartidas por todo el
cartucho, así que la mayor parte del tiempo el contador de programa está fuera
de ese rango aunque la interrupción esté trabajando. Lo que hay que contar no es
dónde está el PC, sino si se ha entrado y todavía no se ha salido: una bandera
que enciende el punto de ruptura de la entrada y apaga el de la salida.

Las dos cifras están en `medidas/control_pc.txt`, una al lado de la otra, por
si a alguien le sirve el aviso. Ahí, en `medidas/`, está la salida en crudo de
todas estas herramientas.

## Una cifra que sale igual medida que leída

Leyendo el código, 0xE120 arranca cada fase en 25 y baja uno por cada enemigo
derribado; cuando llega a cero sale el bicho grande y la cuenta se queda en 5.
Leyendo esa misma dirección segundo a segundo en el replay sale exactamente eso:
25 al empezar, bajando, y 5 en cuanto aparece el bicho. Es lo que se pide de una
medida: que confirme la lectura o la tire abajo.

## Las herramientas

| | |
|---|---|
| `tools/omsx_graba.tcl` | graba la partida en un replay |
| `tools/omsx_repasa.tcl` | repasa el replay segundo a segundo y dice qué había |
| `tools/omsx_mide.tcl` | la medida: interrupción, fases y VDP |
| `tools/omsx_control_pc.tcl` | el control independiente, por muestreo del PC |

El grabador lleva un `after quit { salva cierre }`: sin él, todo lo jugado desde
el último guardado automático se pierde al cerrar la ventana. Se aprendió
perdiendo una partida.
