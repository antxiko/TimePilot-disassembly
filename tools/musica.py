#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Time Pilot no tiene una rutina de "pedir sonido": quien quiere que suene algo
escribe el puntero de su pista en la ficha de un canal (0xE020, 0xE028, 0xE030)
y `PASO_DE_CANAL` (0x4160), que la interrupcion llama una vez por canal desde
0x40E1, 0x40E7 y 0x40ED, la va tocando. Aqui cada pieza es esa lista de
escrituras (PISTAS), con el numero 1, 2... como clave.
Uso:  musica.py registros 1 [cuadros] | mp3 1 f.mp3 | todas docs/audio | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

# Las fichas de los tres canales, de ocho en ocho: puntero (2 bytes), lo que le
# queda a la nota, el registro del PSG del canal (0, 2, 4), volumen, ...
FICHAS = (0xE020, 0xE028, 0xE030)
LIBRES = [("b", f + 2, 0) for f in FICHAS]        # sin nota a medias


def canales(*punteros):
    return LIBRES + [("w", f, p) for f, p in zip(FICHAS, punteros)]


PISTAS = {
    1: canales(0x7A83, 0x7ADB, 0x7B33),       # MUSICA_DE_ARRANQUE (0x43FC)
    2: canales(0x7B94),                       # CAMBIA_DE_EPOCA (0x484A)
}

PIEZAS = [
    P(1, "La música de arranque", "The start-up tune",
      "`MUSICA_DE_ARRANQUE` (0x43FC): tres canales, programas de 0x7A83, "
      "0x7ADB y 0x7B33"),
    P(2, "La música de la época nueva", "The new-era tune",
      "`CAMBIA_DE_EPOCA` (0x484A): un canal, programa de 0x7B94"),
]

PAGINA = motor_musica.pagina_basica(
    "`PASO_DE_CANAL`, 0x4160, una vez por canal desde la interrupción, y las "
    "pistas que cada rutina apunta en las fichas de 0xE020, 0xE028 y 0xE030",
    "`PASO_DE_CANAL`, 0x4160, once per channel from the interrupt, and the "
    "tracks each routine points the channel records at, 0xE020, 0xE028 and "
    "0xE030",
    "C-BIOS MSX1 japonés",
    [("la música de arranque entera, 332 cuadros",
      "the start-up tune, whole, 332 frames"),
     ("la música de la época nueva entera, 188 cuadros",
      "the new-era tune, whole, 188 frames")],
    [("Cómo suena una pieza",
      "Este juego no tiene una rutina que reciba el número de un sonido: quien "
      "quiere que suene algo escribe en la ficha de un canal el puntero de su "
      "pista, y `PASO_DE_CANAL` la va leyendo nota a nota. Cada ficha son ocho "
      "bytes: puntero, lo que queda de la nota, el registro del PSG del canal "
      "(0, 2 o 4), el volumen... La música de arranque ocupa los tres canales; "
      "la de época, uno. En la demo el reproductor no corre. El cotejo con "
      "openMSX se hizo escribiendo esas mismas fichas en la partida, ya en "
      "juego, y comparando lo que el PSG recibe a partir de ahí. El motor no "
      "escribe el mezclador del PSG salvo para el ruido: lo deja el arranque, "
      "y aquí se parte de su mismo valor, 0xB8.",
      "How a piece plays",
      "This game has no routine that takes a sound number: whoever wants "
      "something to play writes the pointer to its track into a channel "
      "record, and `PASO_DE_CANAL` reads it note by note. Each record is "
      "eight bytes: pointer, what is left of the note, the channel's PSG "
      "register (0, 2 or 4), the volume... The start-up tune takes all three "
      "channels; the era tune, one. The player does not run in the demo. The "
      "openMSX check was done by writing those same records during play and "
      "comparing what the PSG receives from then on. The engine does not "
      "write the PSG mixer except for noise: start-up leaves it set, and "
      "here it starts from the same value, 0xB8.")])

CFG = dict(rom="timepilot.rom", org=0x4000, bp_frame=0x40DE,
           frame=[(0x4160, {"hl": 0xE021}), (0x4160, {"hl": 0xE029}),
                  (0x4160, {"hl": 0xE031})],
           ram=(0xE020, 0xE038), ram0=[(0xE02B, 2), (0xE033, 4)], hz=60,
           psg0={7: 0xB8}, pistas=PISTAS, piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(1, 332, None), (2, 188, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
