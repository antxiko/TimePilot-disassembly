#!/usr/bin/env python3
"""Saca la marca que Konami escondio al final de algunos cartuchos de MSX.

El hallazgo no es nuestro: lo destapo Manuel Pazos (@ManuelPazosMSX) en
septiembre de 2021. Gracias a el se sabe que hay que mirar ahi.

Detras del relleno 0xFF, leyendo hacia el final del fichero:

    [titulo, N bytes, EN ORDEN INVERSO]  [N]  [las dos ultimas cifras del RC en
    BCD]  [0xAA]

El titulo va en katakana con el codigo de la casa: indice = byte - 0x80, y los
indices 0 a 44 son el gojuon corrido, sin ヲ. El 0x00 es un espacio.

Uso: marca_konami.py <rom> [<rom> ...]
Sale con 1 si ninguna de las ROM lleva marca.
"""
import os
import sys

# El gojuon corrido, que es el orden en el que Konami numero los caracteres.
KANA = ("A I U E O KA KI KU KE KO SA SI SU SE SO TA TI TU TE TO "
        "NA NI NU NE NO HA HI HU HE HO MA MI MU ME MO YA YU YO "
        "RA RI RU RE RO WA N").split()
# Del 45 al 56 solo estan confirmados estos cuatro; el resto, sin comprobar.
EXTRA = {51: "yo", 53: "tsu", 55: '"', 56: "o"}


def caracter(v):
    if v == 0:
        return " "
    i = v - 0x80
    if 0 <= i < len(KANA):
        return KANA[i]
    if i in EXTRA:
        return EXTRA[i]
    return "<%02X>" % v


def marca(rom):
    """(rc, cuantos, titulo ya puesto del derecho) o None si no la lleva."""
    i = len(rom) - 1
    while i > 0 and rom[i] == 0xFF:
        i -= 1
    if i < 3 or rom[i] != 0xAA:
        return None
    rc, n = rom[i - 1], rom[i - 2]
    if n == 0 or n > i - 2:
        return None
    return rc, n, bytes(reversed(rom[i - 2 - n:i - 2]))


def main():
    alguna = False
    for fn in sys.argv[1:]:
        m = marca(open(fn, "rb").read())
        nombre = os.path.basename(fn)
        if not m:
            print("  %-58s sin marca" % nombre[:58])
            continue
        alguna = True
        rc, n, tit = m
        print("  %-58s RC-7%02X  %d bytes" % (nombre[:58], rc, n))
        print("  %-58s %s" % ("", " ".join(caracter(v) for v in tit)))
    sys.exit(0 if alguna else 1)


main()
