# Time Pilot (Konami, MSX1) — desensamblado comentado

El cartucho RC-703 de Konami, desmontado byte a byte. Los 16.384 bytes están
acotados y explicados: ni un hueco sin justificar, ni un "bloque de gráficos",
ni una tabla adivinada.

🌐 **[Leerlo como web](https://antxiko.github.io/TimePilot-disassembly/es/)**

[README in English](README.md)

---

## Qué es esto

*Time Pilot* es el juego en el que pilotas un avión que siempre está en el
centro de la pantalla, giras sobre ti mismo y disparas, y cada vez que derribas
a los enemigos que hacen falta aparece un bicho enorme al que hay que tumbar
para saltar a otra época. Aquí está su código, comentado, con las herramientas
para volver a montarlo y comprobar que lo que sale es el original.

La máquina mapea los 16 KB en 0x4000-0x7FFF —la página 1—, la BIOS llama al
punto de entrada 0x4203, y ahí el arranque escribe un `jp` en el gancho H.KEYI y
reparte el trabajo: el programa principal lleva la partida —marcador, vidas,
cambio de época— y la interrupción mueve todo lo que se ve, un paso por
fotograma.

## Lo que tiene de especial

**La interrupción no hace lo mismo en todos los fotogramas.** Lleva un contador
de 0 a 5 y una tabla de seis entradas (0x4118): en uno mueve los disparos, las
nubes y el avión; en otro el fondo; en otro el bicho grande; y en los tres
restantes, los enemigos. Repartir el trabajo en un ciclo de seis fotogramas es
lo que le permite mover tantas cosas en un MSX1.

**Los disparos y el bicho grande no son sprites: son caracteres.** El MSX solo
puede enseñar cuatro sprites por línea, así que Time Pilot deja los sprites para
los aviones y dibuja los ocho disparos y el bicho del final —seis caracteres de
ancho por cuatro de alto— escribiendo directamente en la tabla de nombres. Antes
de pintar, cada disparo **lee** la casilla: si no encuentra cielo, no se dibuja.

**El avión no gira de golpe.** El mando dice a qué dirección se quiere ir, de
las dieciséis que hay, y el avión va girando un paso cada vez hasta llegar. Cada
dirección tiene sus 32 bytes de dibujo, y solo el que toca está en la memoria de
vídeo.

## Por qué esto se puede creer

`make` traza el flujo, construye el listado y exige que al ensamblarlo salga
exactamente el original:

```
  ensamblado : 16384 bytes  183e8026...4d54a70d9
  original   : 16384 bytes  183e8026...4d54a70d9
OK: reproducible byte a byte
```

Un listado puede reensamblar perfectamente y estar mal —si se leen dibujos como
instrucciones, los bytes no cambian—, así que corren dos comprobaciones más:
ningún rango declarado como datos puede salir como código, y ningún punto de
entrada puede caer dentro de uno.

## El juego en cifras

| | |
|---|---|
| bytes de código | 8.911 |
| bytes de datos | 7.473 |
| bytes sin identificar | **0** |
| etiquetas con nombre | 593 |
| comentarios anclados | 1.170 |
| rangos de datos con explicación | 106 |

## Algunas cosas que han salido

- **La cuarta época es 1984, no 1982.** Los cinco años que pinta el marcador
  están en 0x4E7C, cuatro caracteres cada uno: 1910, 1940, 1970, **1984** y
  2001. En el salón recreativo esa cuarta época es 1982, el año del original;
  esta conversión la cambió.
- **La demo se pilota leyendo el propio cartucho.** Cuando juega sola, el
  "joystick" no sale de ningún generador de números: 0x546B coge el registro R
  —el del refresco de la memoria— y con él elige un byte del código a partir de
  0x5399, y ese byte se mete tal cual en 0xE009 como si viniera del mando.
- **Los disparos son caracteres que miran antes de escribir.** Cada uno de los
  ocho lee la casilla de la tabla de nombres a la que va y solo se dibuja si lo
  que hay es cielo, así que ni se pisan entre ellos ni tapan el decorado.
- **Las mismas letras están dos veces en la memoria de vídeo, y una sola vez en
  el cartucho.** Los bytes de 0x798B en adelante se suben a dos juegos de
  caracteres distintos: así el mismo alfabeto sale de dos colores sin ocupar el
  doble. Con las cifras pasa igual (0x79D3).
- **El bicho grande aguanta veinticuatro impactos** (0x5CF5) y vale 500 puntos;
  un enemigo normal, 50, y recoger al pasajero, 500.
- **Los enemigos que hay que derribar suben de cinco en cinco.** Se empieza con
  25 y cada cinco rondas hacen falta cinco más, hasta un tope de 50 (0x48A5).
- **Vida extra a los 10.000 puntos y luego cada 50.000**: el escalón se guarda
  en las cifras altas de la puntuación y sube de cinco en cinco (0x48F0).
- **Un `ret` al que no llega nadie** en 0x6012, entre dos rutinas.
- **El silencio es un programa de sonido vacío.** Para callar el canal 2 de
  golpe, 0x5C8F le apunta el puntero al 0xFF que cierra el programa de 0x7E40:
  el canal lee el final y se calla.
- **Los helicópteros no giran porque no hay dibujos.** El biplano, el caza y el
  reactor traen ocho rotaciones cada uno; el helicóptero de la época 3 trae 96
  bytes, tres dibujos (0x75F2). Y a esa época le tocan justo los tres
  comportamientos que no giran (0x68EE).
- **La interrupción se come la mitad del fotograma.** Medido en openMSX sobre
  una partida grabada: 50,11 % del cuadro, 10,09 ms de 20,1, con dos métodos
  independientes que dan lo mismo; y el reparto en seis fases sale parejo, de
  8,81 a 11,10 ms. Con la demo en marcha sube al 71,32 %.
- **Este cartucho no lleva la marca oculta de Konami.** Otros cartuchos de la
  casa esconden al final de la ROM su número de catálogo y el título en
  katakana, un detalle que documentó Manuel Pazos; aquí solo hay 226 bytes de
  0xFF desde 0x7F1E.

## Cómo empezar

Hacen falta `pasmo`, `z80dasm` y Python 3. La imagen del cartucho **no** se
distribuye aquí: pon la tuya en la raíz como `timepilot.rom`, 16384 bytes,
sha256 `183e80262301b18d41762d64a2fc326f4a4bef17832109225637e184d54a70d9`.

```sh
make          # traza, construye el listado y lo comprueba todo
make verify   # ensambla y compara con el cartucho
make sanity   # lo que el reensamblado no puede cazar
make test     # los 23 tests sobre el listado
```

## Licencia y atribución

El juego no es nuestro: *Time Pilot* es de Konami, y todos los derechos siguen
siendo de sus titulares. Lo que sí es nuestro —las herramientas, los
comentarios y la documentación— se publica con la licencia de `LICENSE`. La
imagen del cartucho no se distribuye. Ver [AVISO-LEGAL.md](AVISO-LEGAL.md).
