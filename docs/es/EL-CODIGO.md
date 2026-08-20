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

Ese reparto está medido en el emulador y sale parejo: entre 8,8 y 11,1
milisegundos por fase. Las cifras están en [En el
emulador](EN-EL-EMULADOR.html).

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

| dónde | qué es | cuántos | bytes por ficha |
|---|---|---|---|
| 0xE200 | el bicho grande del final de época | 1 | 16 |
| 0xE210 | las nubes del fondo | 9 | — |
| 0xE230 | los disparos del jugador | 8 | 4 |
| 0xE260 | las bombas de la época 1 | 4 | 3 |
| 0xE270 | los disparos enemigos | 6 | 7 |
| 0xE2A0 | los misiles de las épocas 3, 4 y 5 | 4 | 9 |
| 0xE2CE | el pasajero | 1 | 2 |
| 0xE2D0 | los enemigos | 7 | 16 |

Los enemigos, los disparos enemigos, las bombas y los misiles se mueven con
sprites; las nubes, los disparos del jugador y el bicho grande, escribiendo
caracteres en la tabla de nombres. Esa es la diferencia importante del cartucho:
en el MSX solo caben cuatro sprites por línea, y dibujar los ocho disparos y
el bicho con caracteres ahorra nueve.

El avión del jugador no aparece en la lista porque no tiene ficha: no se mueve.

## Los ocho comportamientos

Cada ficha de enemigo lleva en su byte 1 cuál de los ocho comportamientos le
toca, y el despachador de 0x606C salta por la tabla de 0x605C. Dos de ellos
vuelan con la trayectoria escrita en una tabla:

- el **6** va en onda, con los 64 pasos de 0x6322: cada paso es cuánto se le
  suma a la Y y cuánto a la X. Los 32 primeros bajan 51 píxeles y los 32
  siguientes son su espejo exacto, así que la Y suma cero y el bicho vuelve a la
  altura de salida mientras avanza 106 píxeles.
- el **8** tiene dos trayectorias, y el registro R decide a cara o cruz cuál le
  toca a cada actor: la corta (0x62E2) son dieciséis tramos que suman +8 de giro,
  o sea una vuelta entera en 216 fotogramas; la larga (0x6302) abre los tramos
  hasta 64 fotogramas, 424 en total, y suma −6, así que no llega a cerrar el
  círculo.

Todos, al cambiar de rumbo, pasan por 0x63A2, que es donde se miran las dos
banderas del estado: con el bit 1 el actor le dispara al avión, y con el bit 3
suelta un misil. Las dos se apagan al usarse, así que cada una vale una vez.

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
(0x4E64): los cuatro bytes son la Y mínima, la Y máxima, la X mínima y la X
máxima, y cada clase de choque tiene el suyo. Los disparos, que viven en
casillas de la tabla de nombres, se pasan antes a coordenadas de píxel
multiplicando por ocho (0x5C2A).

## La demo

Cuando nadie toca nada, la partida la juega 0x546B, y ahí está lo más raro del
cartucho: el mando de la demo no es un guión grabado ni un generador de números,
sino **el propio código**. Se coge el registro R, se le suma a 0x5399, y el byte
que haya ahí se mete en 0xE009 como si viniera del joystick.
