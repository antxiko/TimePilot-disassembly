# El cartucho

## La cabecera y la máquina

Los dieciocho primeros bytes son la cabecera que lee la BIOS:

```
4000  41 42        "AB", la firma de un cartucho
4002  03 42        INIT = 0x4203
4004  00 00 00 00 00 00   STATEMENT, DEVICE y TEXT a cero
400A  00 x8        relleno
```

Con la cabecera en 0x4000 la BIOS mapea el cartucho en la **página 1**
(0x4000-0x7FFF) y salta a INIT al terminar de arrancar. INIT escribe
`jp 0x4037` en el gancho H.KEYI (0xFD9A), borra la RAM de 0xE000 a 0xE7FE y
deja la pila justo detrás, en 0xE7FF. A partir de ahí el trabajo se reparte: el
programa principal lleva la partida —marcador, vidas, cambio de época— y la
interrupción mueve todo lo que se ve.

Con 0xE000-0xE7FF de RAM basta un MSX de 16 KB.

## La memoria de vídeo

SCREEN 2, con los ocho registros de 0x4D05:

| registro | valor | qué dice |
|---|---|---|
| R0 | 0x02 | modo gráfico 2 |
| R1 | 0xE2 | 16 K, pantalla e interrupción encendidas, sprites de 16 × 16 |
| R2 | 0x0E | tabla de nombres en 0x3800 |
| R3 | 0x7F | tabla de color en 0x0000 |
| R4 | 0x07 | tabla de patrones en 0x2000 |
| R5 | 0x76 | atributos de sprite en 0x3B00 |
| R6 | 0x03 | patrones de sprite en 0x1800 |
| R7 | 0xE1 | tinta 14 sobre fondo 1 |

En SCREEN 2 la pantalla está partida en **tres tercios** de ocho filas, y cada
tercio tiene sus propios 256 patrones y sus propios colores. Time Pilot carga
los tres **iguales**: sube el primero y luego lo copia dos veces con
`COPIA_VRAM_A_VRAM` (0x4C97), que va leyendo y escribiendo byte a byte con 0x800
de salto. Como al llegar al segundo tercio ya está escrito, la copia se propaga
sola al tercero.

El área de juego son las 24 primeras columnas y las 24 filas; el marcador va en
la fila de arriba y en la columna 24 en adelante.

## Los caracteres

![Los caracteres del título y del menú](../imagenes/letras.png)

Los caracteres se suben con una lista de bloques (0x4BF8): dos bytes con la
dirección de VRAM, uno con cuántos vienen y los datos detrás. El título y el
menú están escritos con los caracteres 0xC3 en adelante, y la fuente del juego
—las letras y las cifras— con los 0xDC en adelante.

Lo curioso es que **son los mismos bytes**: 0x798B se sube dos veces, una como
final del bloque del menú y otra como principio de la fuente (0x427A), y con las
cifras de 0x79D3 pasa lo mismo (0x45E9). En SCREEN 2 el color va por carácter,
así que tener el mismo dibujo con dos números es lo que permite el mismo
alfabeto en dos colores sin ocupar el doble.

Los dieciséis primeros caracteres no son letras: los ocho primeros son los ocho
dibujos del disparo del jugador, el noveno la navecita con la que se pintan las
vidas (0x6A85), y luego vienen la marca de enemigo que falta —distinta en cada
época (0x6AD0)— y la casilla de debajo del avión (0x6AF0).

![Los primeros dieciséis caracteres](../imagenes/caracteres.png)

## Los sprites

La tabla de atributos son 32 sprites, y la copia de trabajo vive en RAM
(0xE380): la interrupción la sube entera a la VRAM en cada fotograma (0x40CA).
Al empezar cada época, siete grupos de tres bytes (cuántos, patrón, color)
reparten los 21 sprites que hacen falta —el avión, los enemigos, los disparos y
los rótulos (0x4DEB)— y los dejan todos fuera de la pantalla, en Y = 0xD1.

El avión es el único que cambia de dibujo: sus dieciséis patrones están en
0x6F2B y solo el que toca sube a la VRAM.

## El sonido

Tres canales de ocho bytes en 0xE020, 0xE028 y 0xE030, y un reproductor
(0x4160) que le da un paso a cada uno en cada fotograma. Un programa de sonido
es una tira de notas de **tres bytes**: el periodo fino, el periodo grueso con
el volumen en el nibble de arriba y el bit 3 para el ruido, y la duración. Con
el bit 7 de la duración puesto, la nota se va apagando sola escalón a escalón.
Un 0xFF termina el programa.

Un canal está callado cuando el byte alto de su puntero vale cero, y para
callarlo de golpe basta con apuntarlo a un 0xFF: eso es justo lo que hace 0x5C8F
con el que cierra el programa de 0x7E40.

## El mapa de la RAM

| dirección | qué guarda |
|---|---|
| 0xE000/0xE001 | modo de juego y jugador que juega |
| 0xE002/0xE003 | vidas de cada jugador |
| 0xE005/0xE006 | próximo escalón de vida extra |
| 0xE00B-0xE013 | puntos de los dos jugadores y el récord, en BCD |
| 0xE018 | la espera: la interrupción se la baja una vez cada 32 fotogramas |
| 0xE019 | el contador de fotogramas del que tira todo |
| 0xE01F | la fase del reparto de la interrupción (0-5) |
| 0xE020-0xE037 | los tres canales de sonido |
| 0xE120/0xE122 | enemigos que faltan por derribar, por jugador |
| 0xE121/0xE123 | cuántos hay en pantalla ahora mismo |
| 0xE126/0xE127 | cuántos han salido desde que empezó la vida |
| 0xE130-0xE134 | cuándo sale el próximo grupo y por dónde |
| 0xE145/0xE146 | el estado del avión y la dirección en la que vuela (0-15) |
| 0xE180-0xE183 | la época y la ronda de cada jugador |
| 0xE200-0xE20F | el bicho grande del final de época |
| 0xE210-0xE22F | las nueve nubes |
| 0xE230-0xE24F | los ocho disparos, cuatro bytes cada uno |
| 0xE260-0xE29F | las bombas de la época 1 y los disparos enemigos |
| 0xE2A0-0xE2CF | los misiles y el pasajero |
| 0xE2D0-0xE2FF | las siete fichas de enemigo, dieciséis bytes cada una |
| 0xE380-0xE3FF | la copia en RAM de la tabla de sprites |
| 0xE400-0xE4A0 | el taller donde se desplazan los caracteres |

El avión del jugador **no está en esta lista**, y no es un olvido: no tiene
ficha porque no se mueve. Está clavado en Y = 0x5C, X = 0x54 (0x5408); lo que se
mueve es todo lo demás.

## De qué está hecho

| | bytes | |
|---|---|---|
| código | 8911 | 54,4 % |
| datos | 7473 | 45,6 % |
| sin identificar | **0** | |

Los datos, por dentro:

| | bytes | |
|---|---|---|
| los diecisiete programas de sonido | 1.179 | se llevan casi todo el final del cartucho |
| el bicho grande de las cinco épocas | 1.113 | sus dibujos, el mapa de caracteres y el humo |
| los caracteres propios de cada época | 926 | los patrones de sprite de sus enemigos |
| el título, el menú y la fuente | 753 | |
| los patrones de sprite comunes | 617 | los que valen para todas las épocas |
| los dieciséis dibujos del avión | 512 | 32 bytes cada uno |
| las nubes | 542 | los dibujos, sus copias desplazadas y las tablas |
| tablas y listas de rótulos | 1.605 | los años, los choques, las direcciones, los despachos |
| relleno del final | 226 | 0xFF desde 0x7F1E hasta el último byte |

Ese relleno del final tiene su gracia: es justo donde otros cartuchos de Konami
llevan escondida su marca —el número de catálogo y el título en katakana—, un
detalle que documentó Manuel Pazos. Time Pilot no la lleva: desde 0x7F1E hasta
0x7FFF no hay más que 0xFF.
