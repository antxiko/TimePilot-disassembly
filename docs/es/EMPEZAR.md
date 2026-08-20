# Empezar

## Lo que hace falta

`pasmo` y `z80dasm` para ensamblar y desensamblar, y Python 3 para las
herramientas. Nada más.

El cartucho no viaja con este repositorio: hay que poner el propio, con el
nombre `timepilot.rom` en la raíz del proyecto. Son 16384 bytes exactos, con
este sha256:

    183e80262301b18d41762d64a2fc326f4a4bef17832109225637e184d54a70d9

Con cualquier otro volcado el listado no vuelve a ensamblar. `make comprueba`
lo dice en una línea.

## Los comandos

```sh
make          # traza, genera el listado y lo comprueba todo
make verify   # ensambla el listado y compara su sha256 con el del cartucho
make sanity   # lo que el reensamblado no puede cazar
make test     # los tests sobre el listado, que no necesitan el cartucho
make imagenes # rehace las imágenes reconstruidas
make web      # las imágenes y estas páginas
```

`make` encadena los cuatro primeros. Si todo va bien, la línea que importa es
ésta:

```
  ensamblado : 16384 bytes  183e8026...4d54a70d9
  original   : 16384 bytes  183e8026...4d54a70d9
OK: reproducible byte a byte
```

## Qué hay en cada carpeta

| | |
|---|---|
| `src/timepilot.asm` | el listado comentado, generado; nunca se edita a mano |
| `src/timepilot.notes` | las anotaciones: etiquetas, comentarios, cabeceras y rangos de datos, ancladas a direcciones |
| `src/timepilot.entries` | los puntos de entrada que el trazado no puede deducir, cada uno con su justificación |
| `src/timepilot.nocode` | las zonas que el trazador no debe leer como código |
| `tools/` | el trazador, el generador del listado, las comprobaciones y las herramientas de dibujo |
| `tests/` | los tests sobre el listado y las anotaciones |
| `docs/` | esta web |
| `work/` | lo que `make` va dejando por el camino |

## Cómo se lee el listado

Cada rutina tiene un nombre en mayúsculas y, donde hace falta, un comentario que
dice qué hace. Los bloques de datos se llaman `DATA_<uso>`, llevan la anchura de
su estructura y una explicación de qué son y de cómo se sabe. Las direcciones
son las de verdad del cartucho en la página 1: 0x4000-0x7FFF.

Para cambiar cualquier cosa se edita `src/timepilot.notes` y se vuelve a lanzar
`make`: el listado se regenera y las comprobaciones dicen si sigue en pie.

## Cómo está hecho

El trazador (`tools/z80trace.py`) sigue el flujo desde el punto de entrada de la
cabecera y desde lo que declara `timepilot.entries`. Aquí lo que no se puede
deducir solo son **ocho tablas de despacho**: Time Pilot no pone la tabla detrás
del `call`, como hacen otros cartuchos, sino que la carga con un `ld hl,nn` y
salta con un `jp (hl)` que está en otro sitio. Cada una está declarada, con la
instrucción que la carga al lado.

Lo que no es código se deja como hueco, y cada hueco se cierra buscando la
instrucción que lo lee (`tools/quien_apunta.py`) y comprobando que el formato
encaja con lo que hace el código que lo consume.

Lo que no se puede leer, se dibuja. `tools/graficos.py` sube a una memoria de
vídeo de mentira lo mismo que sube el cartucho, con sus mismas direcciones, y
monta la pantalla con sus mismas listas de rótulos: si la lectura estuviera mal,
saldría ruido.

## Reproducibilidad

- ensamblar devuelve el sha256 del cartucho
- ningún rango declarado como datos sale como código en el trazado
- ningún punto de entrada cae dentro de un rango de datos
- los 16384 bytes están asignados: 8911 de código, 7473 de datos, 0 sin identificar
