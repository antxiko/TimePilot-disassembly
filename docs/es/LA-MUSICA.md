# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`PASO_DE_CANAL`, 0x4160, una vez por canal desde la interrupción, y las pistas que cada rutina apunta en las fichas de 0xE020, 0xE028 y 0xE030) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la música de arranque entera, 332 cuadros;
- la música de la época nueva entera, 188 cuadros.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo suena una pieza

Este juego no tiene una rutina que reciba el número de un sonido: quien quiere que suene algo escribe en la ficha de un canal el puntero de su pista, y `PASO_DE_CANAL` la va leyendo nota a nota. Cada ficha son ocho bytes: puntero, lo que queda de la nota, el registro del PSG del canal (0, 2 o 4), el volumen... La música de arranque ocupa los tres canales; la de época, uno. En la demo el reproductor no corre. El cotejo con openMSX se hizo escribiendo esas mismas fichas en la partida, ya en juego, y comparando lo que el PSG recibe a partir de ahí. El motor no escribe el mezclador del PSG salvo para el ruido: lo deja el arranque, y aquí se parte de su mismo valor, 0xB8.

## Las músicas

**La música de arranque** (0x01)

Lo pide `MUSICA_DE_ARRANQUE` (0x43FC): tres canales, programas de 0x7A83, 0x7ADB y 0x7B33; dura 5,5 s.

<audio controls preload="none" src="../audio/musica_01.mp3?v=0be7b5fc"></audio>

**La música de la época nueva** (0x02)

Lo pide `CAMBIA_DE_EPOCA` (0x484A): un canal, programa de 0x7B94; dura 3,1 s.

<audio controls preload="none" src="../audio/musica_02.mp3?v=bb1a2e39"></audio>
