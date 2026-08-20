# Hallazgos

Lo que aparece al desmontarlo y no se ve jugando. Cada cosa con su dirección.

## La cuarta época es 1984, no 1982

Los cinco años que pinta el marcador están en 0x4E7C, cuatro caracteres cada
uno: **1910, 1940, 1970, 1984 y 2001**. En el salón recreativo esa cuarta época
es 1982, el año del original; esta conversión la cambió. El propio cartucho, en
cambio, firma ©KONAMI 1983, así que el año que se ve en la pantalla de juego es
posterior al que se ve en la de título.

![La pantalla de título con el menú](../imagenes/menu.png)

## La demo se pilota leyendo el propio cartucho

Cuando el juego se queda solo, el "joystick" no sale de ningún generador de
números. `MANDO_DE_LA_DEMO` (0x546B) hace esto:

```
	ld hl,05399h      ; la propia rutina del avión
	ld a,r            ; el registro de refresco de la memoria
	call SUMA_A_HL
	ld a,(hl)
	ld (0e009h),a     ; y eso es el mando
```

O sea que la demo vuela leyendo el programa que la está moviendo. Como el
registro R avanza con cada instrucción, el byte que sale es distinto cada vez, y
como el código no es aleatorio, el avión describe giros que parecen intencionados
sin serlo.

## Los disparos son caracteres que miran antes de escribir

El MSX solo puede enseñar cuatro sprites en una línea, así que Time Pilot deja
los sprites para los aviones y dibuja los ocho disparos **en la tabla de
nombres**. Cada ficha son cuatro bytes en 0xE230: la casilla, la dirección de
vuelo y el carácter.

Antes de pintarse, cada disparo **lee** la casilla a la que va (0x557B): pone la
dirección en modo lectura, mira lo que hay, y solo escribe si lo que encuentra
es cielo. Con eso ni se pisan entre ellos ni tapan el decorado, y borrarse es
volver a escribir el carácter del cielo.

El bicho grande del final de época hace lo mismo, con seis caracteres de ancho
por cuatro de alto.

## El avión no se mueve: gira

El mando dice a cuál de las dieciséis direcciones se quiere ir (tabla de
0x545B), y el avión va girando **un paso cada vez** hasta llegar, siempre por el
lado corto: si la diferencia pasa de ocho, gira al revés (0x53CE).

![Los dieciséis dibujos del avión](../imagenes/aviones.png)

Cada dirección tiene sus 32 bytes de dibujo en 0x6F2B, pero en la memoria de
vídeo solo hay uno: en cuanto la dirección cambia, se suben los 32 bytes que
tocan al mismo sitio (0x53E3). Un sprite, dieciséis dibujos y un solo hueco.

## La interrupción reparte el trabajo en seis fotogramas

0xE01F cuenta de 0 a 5 y la tabla de 0x4118 dice qué toca en cada uno: los
disparos y el avión, el fondo, el bicho grande, y los enemigos tres veces de cada
seis. Y al salir se vuelve a mirar el estado del VDP: si ha llegado otra
interrupción mientras tanto, se da otro paso sin salir (0x410B).

## Las mismas letras, dos veces en la VRAM y una en el cartucho

Los bytes de 0x798B en adelante se suben **dos veces**: una como final del
bloque de caracteres del menú (0x4272) y otra como principio de la fuente
(0x427A). Con las cifras de 0x79D3 pasa igual (0x45E9).

![Los caracteres del título y del menú](../imagenes/letras.png)

En SCREEN 2 el color va por carácter, así que la única manera de tener el mismo
alfabeto en dos colores es tenerlo con dos números de carácter. Time Pilot lo
consigue sin guardar los dibujos dos veces: sube los mismos bytes a dos sitios.

## El silencio es un programa de sonido vacío

Para callar el canal 2 de golpe, 0x5C8F no toca el PSG ni pone banderas: le
apunta el puntero al **0xFF que cierra** el programa de 0x7E40. El canal lee ese
0xFF en el paso siguiente, se calla y se apaga él solo, por el camino de
siempre.

## Los caracteres del fondo se guardan una vez y se suben desplazados

`SUBE_CARACTERES_GIRADOS` (0x4B81) coge un bloque de caracteres, lo sube a la
VRAM y luego repite el bloque **desplazado dos o cuatro pixeles a la izquierda**,
tantas veces como diga 0xE00A. Los bits que salen de un byte entran en el del
carácter de al lado (0x4BC0). Así el decorado se puede mover en pasos de dos
pixeles sin tocar la tabla de nombres y sin guardar más dibujos.

## Las cuentas del juego

- **Vidas**: dos por jugador, y una más a los 10.000 puntos y luego cada 50.000
  (0x48F0). El escalón se guarda en las cifras altas de la puntuación y sube de
  cinco en cinco.
- **Enemigos por ronda**: 25 la primera, y cinco más cada cinco rondas hasta un
  tope de 50 (0x48A5).
- **Puntos**: 50 por un enemigo, 500 por uno de los propios de la época, 500 por
  recoger al pasajero y 500 por el bicho grande, que aguanta **veinticuatro
  impactos** (0x5CF5).
- **Disparos**: ocho a la vez como mucho, y con el mando no más de cuatro
  seguidos (0x54E8); la demo dispara siempre.

## Un `ret` al que no llega nadie

En 0x6012 hay un byte 0xC9 suelto entre el último de los pasos del disparo
enemigo y la rutina de 0x6013. Ninguna instrucción del listado salta ahí y
ningún puntero cae ahí.
