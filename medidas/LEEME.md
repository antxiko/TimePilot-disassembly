# Las medidas en crudo

Esto es la salida tal cual de las herramientas de openMSX (`tools/omsx_*.tcl`),
sin retocar. Lo que se cuenta con ellas está en
[docs/es/EN-EL-EMULADOR.md](../docs/es/EN-EL-EMULADOR.md) y en
[docs/IN-THE-EMULATOR.md](../docs/IN-THE-EMULATOR.md); aquí están los números de
donde sale, por si alguien quiere mirarlos o rehacerlos.

| fichero | qué es |
|---|---|
| `estado.txt` | la partida grabada: máquina, tiempo emulado y último guardado |
| `repaso.txt` | el replay repasado segundo a segundo: demo o partida, época, ronda, vidas, enemigos que faltan y puntos |
| `medidas.txt` | la medida buena: interrupciones, porcentaje del cuadro, reparto por fases y escrituras al VDP, sobre la ventana de t=30 a t=90 |
| `control_pc.txt` | el control independiente, por muestreo del contador de programa. Incluye el 1,20 % que **no** mide el coste, y por qué |
| `coste_interrupcion_partida_piloto.txt` | otra ventana, de 30 s pilotando |
| `coste_interrupcion_demo.txt` | y otra de 60 s con la demo corriendo |
| `vdp_partida_piloto.txt` | de dónde sale cada escritura al VDP, por tramo de código |

La partida grabada (`work/replays/partida.omr`) no viaja con el repositorio: son
170 segundos de alguien jugando. Para hacer una propia:

```sh
"/c/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
    -cart timepilot.rom -script tools/omsx_graba.tcl
```

y luego `tools/omsx_repasa.tcl` para ver qué hay dentro y `tools/omsx_mide.tcl`
para medir la ventana que se elija.
