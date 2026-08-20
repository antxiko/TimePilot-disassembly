# El código

Casi nueve mil bytes de Z80 con 593 etiquetas y el armazón que Konami repetía en
sus cartuchos: la interrupción llevando lo que se mueve, un despachador que
salta por tablas y un reproductor de sonido de tres canales.

## La interrupción reparte el trabajo

INIT engancha `jp 0x4037` en H.KEYI y a partir de ahí hay dos programas
corriendo: el principal lleva la partida —el marcador, las vidas, el cambio de
época, el GAME OVER— y la interrupción mueve todo lo que se ve.

Lo interesante es que **no hace lo mismo en todos los fotogramas**. 0xE01F cuenta
de 0 a 5 y la tabla de seis entradas de 0x4118 dice qué toca:

| fotograma | qué se mueve |
|---|---|
| 0 | los disparos, las nubes, el avión y los choques |
| 1, 3 y 5 | los enemigos |
| 2 | el fondo que se desplaza |
| 4 | el bicho grande y la cuenta de la fase |

Tres de cada seis fotogramas van para los enemigos, que son lo que más hay. Y al
final de la interrupción se vuelve a mirar el estado del VDP: si mientras tanto
ha llegado otra, se da otro paso sin salir (0x410B), así que un fotograma largo
no se traga el siguiente.

## Los despachadores

Time Pilot no pone la tabla detrás del `call`, como hacen otros cartuchos de la
casa. El patrón aquí es:

```
	ld hl,<tabla>
	call 0x5961        ; hl = tabla[A]
	call 0x415E        ; jp (hl)
```

0x5961 son cinco instrucciones —`rlca`, sumar A a HL, leer la palabra— y 0x415E,
0x554E y 0x6696 son tres `jp (hl)` sueltos que hacen de *call (hl)*. Hay **ocho
tablas** así: las seis entradas del reparto de la interrupción, las dieciséis
direcciones de vuelo, las dieciséis del disparo, los ocho comportamientos de los
enemigos, los ocho arranques, y tres más de ocho pasos.

Como la tabla se carga con un `ld hl,nn` y el salto está en otro sitio, un
trazado estático no puede seguirlas: las ocho están declaradas a mano en
`src/timepilot.entries`, cada una con la instrucción que la carga.

## Las dieciséis direcciones

Todo lo que vuela lleva una dirección de 0 a 15 —la 0 es arriba, la 4 la
derecha— y una velocidad de dos componentes. Moverse es saltar a la rutina de su
dirección (0x52D9 y siguientes): cada una suma o resta las dos componentes a la
posición, **en BCD**, con `daa` detrás de cada suma y el acarreo pasando a la
casilla de al lado.

El avión del jugador es el único que gira poco a poco: el mando pide una
dirección y 0x53BB lo lleva hacia allí un paso por vez, por el lado corto. Los
demás cambian de rumbo de golpe.

## Los actores

| dónde | qué es | cuántos |
|---|---|---|
| 0xE200 | el bicho grande del final de época | 1 |
| 0xE210 | las nubes del fondo | 9 |
| 0xE230 | los disparos del jugador | 8 |
| 0xE260 / 0xE2A0 | los enemigos propios de la época | 4 |
| 0xE2CE | el pasajero | 1 |
| 0xE2D0 | los enemigos | 7 |

Los enemigos y los disparos enemigos se mueven con sprites; las nubes, los
disparos del jugador y el bicho grande, escribiendo caracteres en la tabla de
nombres. Esa es la diferencia importante del cartucho: en el MSX solo caben
cuatro sprites por línea, y así se ahorran ocho.

## El sonido

Tres canales de ocho bytes y un reproductor que le da un paso a cada uno por
fotograma (0x4160). El programa de un canal es una tira de notas de tres bytes
—periodo fino, periodo grueso con el volumen y el bit del ruido, y duración— y
un 0xFF al final. Si la duración lleva el bit 7 puesto, la nota va bajando de
volumen sola.

Al arrancar un sonido nuevo se compara con el número del que ya suena en ese
canal: si el que suena vale más, no se le quita el sitio.

## Los choques

Todo se compara contra el mismo rectángulo, sacado de una tabla de seis
(0x4E64): los cuatro bytes son el margen por arriba, por abajo, por la izquierda
y por la derecha. Los disparos, que viven en casillas de la tabla de nombres, se
pasan antes a coordenadas de pixel multiplicando por ocho (0x5C2A).

## La demo

Cuando nadie toca nada, la partida la juega 0x546B, y ahí está lo más raro del
cartucho: el mando de la demo no es un guión grabado ni un generador de números,
sino **el propio código**. Se coge el registro R, se le suma a 0x5399, y el byte
que haya ahí se mete en 0xE009 como si viniera del joystick.
