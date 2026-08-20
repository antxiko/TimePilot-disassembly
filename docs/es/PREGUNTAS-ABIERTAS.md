# Preguntas abiertas

Lo que el binario no resuelve por sí solo. El cartucho está explicado byte a
byte y el listado vuelve a dar la ROM; esto es lo que queda por medir o por
decidir.

## Qué hace cada uno de los ocho comportamientos

Las siete fichas de enemigo de 0xE2D0 llevan cada una uno de los ocho
comportamientos de la tabla de 0x605C, y lo que se puede leer del código es
cómo eligen la dirección y cada cuánto la cambian: unos sortean el rumbo con el
registro R, otros apuntan al centro de la pantalla, otros se paran a disparar.
Lo que **no** está cerrado es qué enemigo del juego es cada uno: eso hay que
jugarlo y mirarlo, o medirlo en el emulador.

## Los 192 bytes de 0x62E2

Entre el último comportamiento y la rutina que elige el sprite hay 192 bytes que
solo se leen desde ahí, con índices que salen de la dirección y del fotograma
de la animación. Están declarados como lo que son —tablas del comportamiento de
los enemigos— pero no se ha separado entrada por entrada.

## El segundo juego de nubes

0x6981 tiene 68 bytes que 0x50F8 lee en grupos de dieciséis, y sobran cuatro al
final. O el último grupo es más corto, o esos cuatro bytes no los usa nadie; el
código no lo aclara.

## La pantalla de juego, sin reconstruir del todo

`tools/graficos.py` rehace la pantalla de título entera —los caracteres, sus
colores y las listas de rótulos— y sale bien. La pantalla de partida se
reconstruye a medias: el cielo y los colores de la época salen, pero el marcador
todavía no aparece con su color, así que aquí no se publica ninguna imagen de
partida. Lo que no se puede comprobar, no se enseña.

## Nada medido en el emulador

Todo lo que hay en estas páginas sale de leer el binario. No hay ni una medida
de openMSX: ni cuánto tarda la interrupción, ni cuántas escrituras al VDP hace
por fotograma, ni si el reparto en seis fotogramas llega justo o sobrado.
