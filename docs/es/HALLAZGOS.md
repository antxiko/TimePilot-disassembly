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

Y el avión **no tiene ni ficha ni coordenadas**: está clavado en Y = 0x5C,
X = 0x54 (0x5408). En este juego el que no se mueve es el jugador.

## Por qué los helicópteros no giran

En la época 3 los enemigos no dan la vuelta, y no es una decisión de diseño: es
que **no hay dibujos**. Cada época sube sus propios patrones de sprite, y el
biplano (0x73F4), el caza (0x74F4) y el reactor (0x7652) traen ocho rotaciones
de 32 bytes cada una; el helicóptero (0x75F2) trae **96 bytes, tres dibujos**.

Las cinco listas de 0x68DC a 0x6909 dicen qué comportamientos pueden salir en
cada época, y a la 3 le tocan justo el 5, el 6 y el 7, que son los tres únicos
que no giran: uno va en horizontal, otro en onda y el tercero se pone de perfil
en un tramo y de frente en el resto (0x620D usa los dibujos 0x24 y 0x28). Los
comportamientos están repartidos por época según los dibujos que hay.

El platillo de la época 5 es el otro extremo: **un solo dibujo**, que 0x45BB
sube ocho veces seguidas para llenar los ocho huecos de patrón.

## La onda del enemigo está tabulada, y cierra

El comportamiento 6 no calcula ninguna curva: se la lee de 64 parejas en 0x6322,
cada una con lo que se le suma a la Y y lo que se le suma a la X. Sumadas, las Y
dan **exactamente cero** —los 32 primeros pasos bajan 51 píxeles y los 32
siguientes son su espejo—, así que el bicho vuelve siempre a la altura por la
que entró mientras avanza 106 píxeles. El bit 0 de su estado decide si la onda
va hacia la derecha o hacia la izquierda.

El comportamiento 8 tiene dos tablas de dieciséis tramos y el registro R elige a
cara o cruz: la de 0x62E2 suma +8 de giro, o sea una vuelta entera en 216
fotogramas, y la de 0x6302 suma −6 en 424, así que no llega a cerrar el círculo.

## El bicho grande de cada época acaba justo donde empieza el marcador

Los cinco bloques de 0x6BF2 en adelante no son decorados: son **los dibujos del
bicho grande**, uno por época, y se suben a la VRAM 0x2340 con tres copias
desplazadas al lado para poder moverlo en pasos de dos píxeles. La cuenta cuadra
al byte: cinco tiras de cuatro caracteres con sus copias son 760 bytes, y
0x2340 + 760 = 0x2638, que es exactamente donde `CARGA_MARCADOR` (0x45E9) mete
las cifras.

![El bicho grande de la época 3](../imagenes/bicho3.png)

## La interrupción reparte el trabajo en seis fotogramas

0xE01F cuenta de 0 a 5 y la tabla de 0x4118 dice qué toca en cada uno: los
disparos y el avión, el fondo, el bicho grande, y los enemigos tres veces de cada
seis. Y al salir se vuelve a mirar el estado del VDP: si ha llegado otra
interrupción mientras tanto, se da otro paso sin salir (0x410B).

Medido en el emulador sobre una partida de verdad, ese reparto sale parejo —de
8,8 a 11,1 milisegundos por fase— y la interrupción se come **la mitad justa**
del fotograma. Las cifras están en [En el emulador](EN-EL-EMULADOR.html).

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

## Por qué funciona el truco de disparar dando vueltas

Cada disparo se lleva puesta la dirección en la que volaba el avión cuando
salió: 0x54EC la copia de 0xE146 a la ficha, y a partir de ahí el disparo sigue
por su cuenta (0x5570 y siguientes). No hay ninguna rutina que los reoriente.

De ahí que girando sin soltar el botón se acabe rodeado de disparos abriéndose
en abanico: caben ocho a la vez, cada uno con su rumbo, y con el mando se pueden
encadenar de cuatro en cuatro (0x54E8), rearmando la cuenta al soltar. El
cartucho no premia esa manera de jugar por ninguna parte; sale sola de que la
dirección se copie una vez y no se vuelva a tocar.

## Las cuentas del juego

- **Vidas**: dos por jugador, y una más a los 10.000 puntos y luego cada 50.000
  (0x48F0). El escalón se guarda en las cifras altas de la puntuación y sube de
  cinco en cinco.
- **Enemigos por ronda**: 25 la primera, y cinco más cada cinco rondas hasta un
  tope de 50 (0x48A5). La cuenta viva está en 0xE120, y al salir el bicho grande
  se queda en 5 (0x56F3).
- **Puntos**: 50 por un enemigo, 500 por uno de los propios de la época, 500 por
  recoger al pasajero y 500 por el bicho grande, que aguanta **veinticuatro
  impactos** (0x5CF5).
- **Disparos**: ocho a la vez como mucho, y con el mando no más de cuatro
  seguidos (0x54E8); la demo dispara siempre.
- **La espera no va en fotogramas**: 0xE018 la baja la interrupción una vez cada
  32 cuadros (0x40F5), así que un punto de espera son 0,64 segundos. Los
  dieciséis puntos que se piden al empezar una vida son unos diez segundos.

## Este cartucho no lleva la marca oculta de Konami

Otros cartuchos de la casa esconden al final de la ROM su número de catálogo y
el título en katakana, un detalle que documentó **Manuel Pazos**. Aquí no hay
nada: el último byte con contenido es el 0xFF que cierra el programa de sonido
de 0x7EED, en 0x7F1D, y de 0x7F1E hasta 0x7FFF hay 226 bytes de relleno, todos
0xFF.

## Un `ret` al que no llega nadie

En 0x6012 hay un byte 0xC9 suelto entre el último de los pasos del disparo
enemigo y la rutina de 0x6013. Ninguna instrucción del listado salta ahí y
ningún puntero cae ahí. Hay otro igual en 0x415F, detrás del `jp (hl)` de
0x415E.
