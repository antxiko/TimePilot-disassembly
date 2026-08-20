#!/usr/bin/env python3
"""Reconstruye lo que Time Pilot dibuja, repitiendo lo que hace el cartucho.

    python3 tools/graficos.py timepilot.rom docs/imagenes

No inventa nada: es la lista de copias del propio cartucho pasada a Python.

  - INIT (0x4203) borra la VRAM, sube los caracteres del titulo (0x7792 y
    0x712B por la lista de bloques de 0x4BF8), la fuente de 0x798B y los
    colores de 0x4D2F, y luego copia el primer tercio a los otros dos
    (0x4C97), que es como los tres tercios quedan iguales.
  - ESCRIBE_ROTULO (0x4A72) monta la tabla de nombres desde las listas de
    0x4EAB, 0x4E90 y las cuatro del menu.
  - El avion son dieciseis dibujos de 32 bytes en 0x6F2B, uno por direccion.

Si un rango estuviera mal etiquetado, estas imagenes saldrian ruido.
"""
import os
import struct
import sys
import zlib

ORG = 0x4000
# La paleta del TMS9918, tal como la da openMSX.
PAL = [(0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120), (84, 85, 237),
       (125, 118, 252), (212, 82, 77), (66, 235, 245), (252, 85, 84),
       (255, 121, 120), (212, 193, 84), (230, 206, 128), (33, 176, 59),
       (201, 91, 186), (204, 204, 204), (255, 255, 255)]
FONDO = PAL[1]                                   # R7 = 0xE1: borde negro


def png(w, h, px, fn):
    raw = b"".join(b"\x00" + bytes(v for p in row for v in p) for row in px)

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff))
    open(fn, "wb").write(b"\x89PNG\r\n\x1a\n"
                         + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                         + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


# ---------------------------------------------------------------------------
# La VRAM del cartucho
# ---------------------------------------------------------------------------

def lista_de_bloques(rom, a, c, v):
    """0x4BF8: C bloques de (direccion de VRAM, cuantos, datos)."""
    p = a - ORG
    for _ in range(c):
        d = ((rom[p] << 8) | rom[p + 1]) & 0x3FFF
        n = rom[p + 2] or 256
        p += 3
        v[d:d + n] = rom[p:p + n]
        p += n
    return ORG + p


def copia(rom, a, dst, n, v):
    """0x401E: N bytes de la ROM a la VRAM."""
    v[dst & 0x3FFF:(dst & 0x3FFF) + n] = rom[a - ORG:a - ORG + n]


def rellena(rom, a, dst, c, v):
    """0x4620: la lista de parejas (cuantos, byte) sobre la VRAM."""
    p = a - ORG
    d = dst & 0x3FFF
    for _ in range(c):
        n = rom[p] or 256
        b = rom[p + 1]
        v[d:d + n] = bytes([b]) * n
        d += n
        p += 2
    return d


def vram_del_titulo(rom):
    """Lo que deja INIT antes de la pantalla de titulo."""
    v = bytearray(0x4000)
    lista_de_bloques(rom, 0x6A85, 1, v)              # 0x4253
    lista_de_bloques(rom, 0x7792, 3, v)              # 0x4272
    copia(rom, 0x798B, 0x66E0, 0xF8, v)              # 0x427A: la fuente
    lista_de_bloques(rom, 0x712B, 3, v)              # 0x4285: sprites
    rellena(rom, 0x4D2F, 0x4468, 5, v)               # 0x42AD: los colores
    # 0x42C5 y 0x42CB: L_4C97 copia byte a byte con 0x800 de salto, asi que lo
    # que escribe en el segundo tercio lo vuelve a leer para el tercero
    for i in range(0x1000):
        v[0x0800 + i] = v[i]
    for i in range(0x1000):
        v[0x2800 + i] = v[0x2000 + i]
    return v


def escribe_rotulo(rom, a, v, maxren=40):
    """0x4A72: palabra con la direccion, caracteres, 0xFE repite, 0xFF acaba."""
    p = a - ORG
    for _ in range(maxren):
        d = (((rom[p] << 8) | rom[p + 1]) & 0x3FFF)
        p += 2
        while True:
            c = rom[p]
            p += 1
            if c == 0xFF:
                break
            if c == 0xFE:
                n = rom[p] or 256
                b = rom[p + 1]
                p += 2
                v[d:d + n] = bytes([b]) * n
                d += n
                continue
            v[d] = c
            d += 1
        if rom[p] == 0xFF:
            p += 1
            break
    return ORG + p


# ---------------------------------------------------------------------------
# El dibujo
# ---------------------------------------------------------------------------

def pinta_pantalla(v, filas=24, cols=32, esc=2):
    """La tabla de nombres de 0x3800 con los patrones de 0x2000 y el color."""
    w, h = cols * 8 * esc, filas * 8 * esc
    px = [[FONDO] * w for _ in range(h)]
    for f in range(filas):
        tercio = (f // 8) * 0x800
        for c in range(cols):
            n = v[0x3800 + f * 32 + c]
            for y in range(8):
                pat = v[0x2000 + tercio + n * 8 + y]
                col = v[0x0000 + tercio + n * 8 + y]
                tinta = PAL[col >> 4] if (col >> 4) else FONDO
                fondo = PAL[col & 15] if (col & 15) else FONDO
                for x in range(8):
                    color = tinta if pat & (0x80 >> x) else fondo
                    for dy in range(esc):
                        for dx in range(esc):
                            px[(f * 8 + y) * esc + dy][(c * 8 + x) * esc + dx] = color
    return w, h, px


def pinta_sprites(rom, a, n, fn, cols=8, esc=4, color=(255, 255, 255)):
    """N sprites de 16x16 seguidos, en un solo color (el MSX no da mas)."""
    filas = (n + cols - 1) // cols
    w, h = cols * 18 * esc, filas * 18 * esc
    px = [[(24, 24, 24)] * w for _ in range(h)]
    for s in range(n):
        base = a - ORG + 32 * s
        cx, cy = (s % cols) * 18, (s // cols) * 18
        for q in range(4):
            ox, oy = (q // 2) * 8, (q % 2) * 8
            for y in range(8):
                b = rom[base + q * 8 + y]
                for x in range(8):
                    if b & (0x80 >> x):
                        for dy in range(esc):
                            for dx in range(esc):
                                px[(cy + oy + y) * esc + dy][(cx + ox + x) * esc + dx] = color
    png(w, h, px, fn)


def pinta_caracteres(v, prim, n, fn, cols=16, esc=4):
    """Los caracteres tal como quedan en la VRAM, con su color."""
    filas = (n + cols - 1) // cols
    w, h = cols * 9 * esc, filas * 9 * esc
    px = [[(24, 24, 24)] * w for _ in range(h)]
    for i in range(n):
        c = prim + i
        cx, cy = (i % cols) * 9, (i // cols) * 9
        for y in range(8):
            pat = v[0x2000 + c * 8 + y]
            col = v[0x0000 + c * 8 + y]
            tinta = PAL[col >> 4] if (col >> 4) else FONDO
            fondo = PAL[col & 15] if (col & 15) else FONDO
            for x in range(8):
                color = tinta if pat & (0x80 >> x) else fondo
                for dy in range(esc):
                    for dx in range(esc):
                        px[(cy + y) * esc + dy][(cx + x) * esc + dx] = color
    png(w, h, px, fn)



def desplaza(v, dst, n, veces, bits):
    """0x4BA4: cada bloque de N caracteres se repite desplazado a la izquierda.

    Los bits que salen de un byte entran en el byte del caracter de al lado, y
    asi el fondo se puede mover de dos en dos o de cuatro en cuatro pixeles sin
    tocar la tabla de nombres.
    """
    ini = dst & 0x3FFF
    for k in range(veces):
        base = ini + n * 8 * k
        sig = base + n * 8
        for i in range(n * 8):
            v[sig + i] = v[base + i]
        for _ in range(bits):
            acarreo = 0
            for i in range(n * 8 - 1, -1, -1):
                b = v[sig + i]
                v[sig + i] = ((b << 1) & 0xFF) | acarreo
                acarreo = (b >> 7) & 1
    return ini


def bloques_con_11(rom, a, n, dst, v, veces, bits):
    """0x4B81: N bloques de caracteres, cada uno cerrado con un 0x11."""
    p = a - ORG
    d = dst & 0x3FFF
    for _ in range(n):
        ini = p
        while True:
            p += 8
            if rom[p] == 0x11:
                p += 1
                break
        cuantos = (p - ini - 1) // 8
        v[d:d + cuantos * 8] = rom[ini:ini + cuantos * 8]
        desplaza(v, d, cuantos, veces, bits)
        d += cuantos * 8 * (veces + 1)
    return ORG + p


def vram_de_la_epoca(rom, epoca):
    """Lo que deja EMPIEZA_VIDA (0x44A3) para la epoca que se le pida."""
    v = bytearray(0x4000)
    copia(rom, 0x6AF0, 0x6060, 8, v)                 # 0x44E4: el caracter del cielo
    copia(rom, 0x6F2B, 0x5800, 0x20, v)              # 0x44EF: el avion
    copia(rom, 0x71F1, 0x5A00, 256, v)               # 0x44FD
    nube = {1: 0x6AD0, 2: 0x6AD0, 3: 0x6AD8, 4: 0x6AE0}.get(epoca, 0x6AE8)
    copia(rom, nube, 0x6058, 8, v)                   # 0x4525
    pat = {1: 0x73F4, 2: 0x74F4, 3: 0x75F2, 4: 0x7652}.get(epoca)
    if pat:
        copia(rom, pat, 0x5900, 96 if epoca == 3 else 256, v)
    else:
        for k in range(8):
            copia(rom, 0x7752, 0x5900 + 0x20 * k, 0x20, v)
        for k in range(8):
            copia(rom, 0x7772, 0x5A00 + 0x20 * k, 0x20, v)
    dib = {1: 0x6BF2, 2: 0x6C97, 3: 0x6D3C, 4: 0x6DE1}.get(epoca, 0x6E86)
    bloques_con_11(rom, dib, 5, 0x6340, v, 3, 2)     # 0x4562: el decorado
    copia(rom, 0x79D3, 0x6638, 0x50, v)              # 0x45E9: las cifras
    col = {1: 0x4D39, 2: 0x4D61, 3: 0x4D82, 4: 0x4DAD}.get(epoca, 0x4DD3)
    cuantos = {1: 0x0C, 2: 0x0D, 3: 0x0B, 4: 0x0C}.get(epoca, 0x0C)
    rellena_con_bloques(rom, col, 0x4008, cuantos, v)
    for i in range(0x1000):
        v[0x2800 + i] = v[0x2000 + i]
    for i in range(0x1000):
        v[0x0800 + i] = v[i]
    return v


def rellena_con_bloques(rom, a, dst, c, v):
    """0x4620: parejas (cuantos, byte), y un 0xFF manda a 0x4D0D."""
    p = a - ORG
    d = dst & 0x3FFF
    for _ in range(c):
        if rom[p] == 0xFF:
            p, d = bloque_de_fondo(rom, p, d, v)
        n = rom[p] or 256
        b = rom[p + 1]
        v[d:d + n] = bytes([b]) * n
        d += n
        p += 2
        if rom[p] == 0xFF:
            p, d = bloque_de_fondo(rom, p, d, v)
    return d


def bloque_de_fondo(rom, p, d, v):
    """0x4D0D: filas de tramos de (cuantos, byte), y al final un salto."""
    while True:
        p += 1
        filas = rom[p]
        p += 1
        ini = p
        for _ in range(filas):
            p = ini
            tramos = rom[p]
            p += 1
            for _ in range(tramos):
                n = rom[p] or 256
                b = rom[p + 1]
                v[d:d + n] = bytes([b]) * n
                d += n
                p += 2
        d += rom[p] * 2
        p += 1
        if rom[p] != 0xFF:
            break
    return p, d


def main():
    rom = open(sys.argv[1], "rb").read()
    out = sys.argv[2] if len(sys.argv) > 2 else "docs/imagenes"
    os.makedirs(out, exist_ok=True)

    # 1. La pantalla de titulo entera, como la monta 0x4A62 + 0x42F0
    v = vram_del_titulo(rom)
    escribe_rotulo(rom, 0x4EAB, v)                 # la pantalla fija
    escribe_rotulo(rom, 0x4E90, v)                 # el rotulo grande
    w, h, px = pinta_pantalla(v)
    png(w, h, px, os.path.join(out, "titulo.png"))
    print("titulo.png")

    # el rotulo grande solo, para la cabecera de la web
    w, h, px = pinta_pantalla(v, filas=6, cols=32, esc=3)
    corte = [fila[10 * 8 * 3:24 * 8 * 3] for fila in px[2 * 8 * 3:6 * 8 * 3]]
    png(len(corte[0]), len(corte), corte, os.path.join(out, "logo.png"))
    print("logo.png")

    # 2. La misma con el menu encima (0x4396 en adelante)
    for a in (0x4EE8, 0x4F05, 0x4F22, 0x4F3F):
        escribe_rotulo(rom, a, v)
    w, h, px = pinta_pantalla(v)
    png(w, h, px, os.path.join(out, "menu.png"))
    print("menu.png")

    # 3. Los caracteres con los que esta escrito todo eso
    pinta_caracteres(v, 0xC3, 0x38, os.path.join(out, "letras.png"))
    print("letras.png")

    # 4. Los dieciseis dibujos del avion (0x6F2B), uno por direccion
    pinta_sprites(rom, 0x6F2B, 16, os.path.join(out, "aviones.png"))
    print("aviones.png")

    # 5. Los patrones de sprite comunes (0x712B, primer bloque a 0x1840)
    v2 = bytearray(0x4000)
    lista_de_bloques(rom, 0x712B, 3, v2)
    pinta_sprites(rom, 0x71EE + 3, 8, os.path.join(out, "sprites.png"))
    print("sprites.png")

    # 6. El bicho grande del final de epoca (0x69C5): 6 x 4 caracteres
    # El bicho grande del final de epoca (0x69C5) se pinta con caracteres del
    # juego de la epoca, que aqui todavia no se reconstruye entero; por eso no
    # se dibuja: no se publica una imagen que no se pueda comprobar.

    # La pantalla de juego se reconstruye con vram_de_la_epoca(), pero el
    # panel del marcador todavia no sale con sus colores, asi que no se publica
    # ninguna imagen de partida: aqui no se ensena nada que no este comprobado.


if __name__ == "__main__":
    main()
