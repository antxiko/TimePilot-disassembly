#!/usr/bin/env python3
"""Reconstruye lo que Time Pilot dibuja, repitiendo lo que hace el cartucho.

    python3 tools/graficos.py timepilot.rom docs/imagenes

No inventa nada: es la lista de copias del propio cartucho pasada a Python.

  - INIT (0x4203) borra la VRAM, sube los caracteres de los disparos (0x6A85),
    las nubes con sus copias corridas (0x6AF8), los del titulo (0x7792 y
    0x712B), la fuente de 0x798B y los colores de 0x4D2F, y luego copia el
    primer tercio a los otros dos (0x4C97), que es como los tres tercios
    quedan iguales.
  - ESCRIBE_ROTULO (0x4A72) monta la tabla de nombres desde las listas de
    0x4EAB, 0x4E90 y las cuatro del menu.
  - EMPIEZA_EPOCA (0x4468) y EMPIEZA_VIDA (0x44A3) montan la pantalla de
    partida: el marcador entero de 0x4FA3, el ano de 0x4E7C, los dibujos de la
    epoca (0x73F4 y siguientes), el bicho grande girado (0x6BF2 y siguientes),
    las cifras de 0x79D3 y el color del cielo, que sale de las listas de
    0x4D39 y siguientes. Encima van las nueve nubes de 0x4CE9 (0x5103) y el
    sprite del avion, clavado en Y=0x5C, X=0x54 (0x53FE).
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

# La epoca decide cinco cosas, y cada una sale de su tabla del cartucho.
EPOCAS = {
    #        marca 0x0B  dibujos     cuantos  bicho grande  color    vueltas
    1: (0x6AD0, 0x73F4, 0x100, 0x6BF2, 0x4D39, 0x0C),
    2: (0x6AD0, 0x74F4, 0x100, 0x6C97, 0x4D61, 0x0D),
    3: (0x6AD8, 0x75F2, 0x060, 0x6D3C, 0x4D82, 0x0B),
    4: (0x6AE0, 0x7652, 0x100, 0x6DE1, 0x4DAD, 0x0C),
    5: (0x6AE8, None, 0, 0x6E86, 0x4DD3, 0x0C),
}
SPRITES_DE_LA_EPOCA = {1: 0x4DEB, 2: 0x4E00, 3: 0x4E15, 4: 0x4E2A, 5: 0x4E3F}


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
    """0x4620 sin bloques: C parejas (cuantos, byte) escritas seguidas."""
    p = a - ORG
    d = dst & 0x3FFF
    for _ in range(c):
        n = rom[p] or 256
        v[d:d + n] = bytes([rom[p + 1]]) * n
        d += n
        p += 2
    return d


def copia_vram_a_vram(v, org, dst):
    """0x4C97: 0xFFF bytes de la VRAM a otro sitio de la VRAM, byte a byte.

    Como lee y escribe de uno en uno con 0x800 de distancia, en cuanto pasa del
    primer tercio ya esta leyendo lo que acaba de escribir: una sola pasada
    deja los tres tercios cargados iguales.
    """
    o, d = org & 0x3FFF, dst & 0x3FFF
    for _ in range(0xFFF):
        v[d] = v[o]
        o += 1
        d += 1


def borra_los_nombres(v):
    """0x4B15: 3 x 256 ceros desde la VRAM 0x3800, o sea la tabla de nombres
    ENTERA, no solo la fila de arriba."""
    v[0x3800:0x3B00] = bytes(0x300)


def borra_el_area_de_juego(v, c):
    """0x4B29: 24 filas de 24 columnas con el caracter C. Las ocho columnas de
    la derecha, las del marcador, se quedan como estaban."""
    for f in range(24):
        d = 0x3800 + f * 32
        v[d:d + 24] = bytes([c]) * 24


def sube_caracteres_girados(rom, a, n, dst, v, e00a=0):
    """0x4B81: N tiras de caracteres (cerradas con 0x11) y sus copias corridas.

    El taller de 0xE400 tiene OCHO BYTES LIBRES DELANTE: los bits que salen por
    la izquierda de un caracter entran por la derecha del de al lado, y los del
    primero caen en esos ocho. Por eso la tira original ocupa n caracteres
    (0x4B89 sube desde 0xE408) y cada copia n+1 (0x4BDC sube desde 0xE400).
    Con 0xE00A a cero son tres copias de dos bits; con 0xE00A a uno, una de
    cuatro.
    """
    p = a - ORG
    d = dst & 0x3FFF
    vueltas = e00a or 3
    bits = 4 if e00a else 2
    for _ in range(n):
        ini = p
        while rom[p] != 0x11:
            p += 8
        cuantos = (p - ini) // 8
        p += 1
        taller = bytearray(8) + bytearray(rom[ini:ini + cuantos * 8])
        v[d:d + cuantos * 8] = taller[8:]
        d += cuantos * 8
        for _ in range(vueltas):
            for i in range(len(taller)):
                acarreo = 0
                for _ in range(bits):
                    acarreo = (acarreo << 1) | ((taller[i] >> 7) & 1)
                    taller[i] = (taller[i] << 1) & 0xFF
                if i >= 8:
                    taller[i - 8] |= acarreo
            v[d:d + len(taller)] = taller
            d += len(taller)
    return ORG + p


def copia_dos_tiras(rom, v):
    """0x429B: dos tiras del bicho de la epoca 5, alternadas de ocho en ocho
    bytes, a los patrones de sprite 0x74 y 0x78 (VRAM 0x1BA0)."""
    a, b, d = 0x6E86 - ORG, 0x6EA7 - ORG, 0x1BA0
    for _ in range(4):
        v[d:d + 8] = rom[a:a + 8]
        a += 8
        d += 8
        v[d:d + 8] = rom[b:b + 8]
        b += 8
        d += 8


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


def pinta_seis_cifras(bcd, dst, v):
    """0x4A97: tres bytes BCD en seis caracteres, sumandole 0xE5 a cada cifra."""
    d = dst & 0x3FFF
    for b in bcd:
        v[d] = (0xE5 + (b >> 4)) & 0xFF
        v[d + 1] = (0xE5 + (b & 0x0F)) & 0xFF
        d += 2


# ---------------------------------------------------------------------------
# El fondo de la epoca, que es TABLA DE COLOR y no tabla de nombres
# ---------------------------------------------------------------------------

def bloque_de_fondo(rom, p, d, v):
    """0x4D0D: cuantas filas y, detras, UNA sola descripcion de fila -cuantos
    tramos y los tramos de (cuantos, byte)- que se repite todas esas veces.

    Cada fila son ocho bytes, o sea el color de un caracter entero: por eso los
    caracteres del bicho grande salen a rayas. Un 0xFF detras encadena otro
    bloque.
    """
    while True:
        p += 1
        filas = rom[p]
        p += 1
        ini = p
        for _ in range(filas):
            q = ini
            tramos = rom[q]
            q += 1
            for _ in range(tramos):
                n = rom[q] or 256
                v[d:d + n] = bytes([rom[q + 1]]) * n
                d += n
                q += 2
        p = ini + 1 + 2 * rom[ini]
        if rom[p] != 0xFF:
            break
    return p, d


def pinta_fondo_de_la_epoca(rom, a, c, dst, v):
    """0x4620: la lista de la epoca escrita seguida desde la VRAM 0x0008.

    Ojo: eso es la TABLA DE COLOR, no la de nombres. C parejas de (cuantos,
    byte), y un 0xFF delante o detras de la pareja mete un bloque de 0x4D0D en
    medio sin gastar vuelta.
    """
    p, d = a - ORG, dst & 0x3FFF
    for _ in range(c):
        if rom[p] == 0xFF:
            p, d = bloque_de_fondo(rom, p, d, v)
        n = rom[p] or 256
        v[d:d + n] = bytes([rom[p + 1]]) * n
        d += n
        p += 2
        if rom[p] == 0xFF:
            p, d = bloque_de_fondo(rom, p, d, v)
    return d


# ---------------------------------------------------------------------------
# Lo que se mueve: los sprites y las nubes
# ---------------------------------------------------------------------------

def monta_sprites_de_la_epoca(rom, epoca, ram):
    """0x4665: siete grupos de (cuantos, patron, color) a la copia de 0xE380.

    Son 21 sprites y todos nacen fuera de la pantalla, en Y=0xD1. Dentro del
    grupo el patron y el color no cambian: 0x466D guarda DE en cada vuelta.
    """
    p = SPRITES_DE_LA_EPOCA[epoca] - ORG
    d = 0xE380
    for _ in range(7):
        n = rom[p] or 256
        p += 1
        for _ in range(n):
            ram[d] = 0xD1
            ram[d + 1] = 0xFF
            ram[d + 2] = rom[p]
            ram[d + 3] = rom[p + 1]
            d += 4
        p += 2


def jugador_pon_sprite(ram, v):
    """0x53FE: el caracter 0x0C en la casilla de debajo del avion y el sprite,
    que no se mueve nunca: Y=0x5C, X=0x54, patron 0."""
    v[0x398B] = 0x0C
    ram[0xE380] = 0x5C
    ram[0xE381] = 0x54
    ram[0xE382] = 0x00


def pinta_las_nubes(rom, ram, v):
    """0x5103: las nueve nubes de 0xE211 sobre la tabla de nombres.

    Cada nube son tres bytes: desplazamiento y casilla. Con el desplazamiento a
    cero el dibujo son cuatro columnas del juego de 0x6981 y con el a uno son
    seis del de 0x6921; siempre cuatro filas, y siempre pisando lo que hubiera
    debajo. Al pasar de la columna 24 se vuelve al principio de la fila y al
    pasar del ultimo tercio, a la fila de arriba.
    """
    direccion = ram[0xE210]
    seis = 0x6921 - ORG + 0x18 * direccion
    cuatro = 0x6981 - ORG + 0x10 * direccion
    for i in range(9):
        desp = ram[0xE211 + i * 3]
        de = (ram[0xE212 + i * 3] << 8) | ram[0xE213 + i * 3]
        p = seis if desp else cuatro
        ancho = 6 if desp else 4
        for _ in range(4):
            fila = de
            for _ in range(ancho):
                v[de & 0x3FFF] = rom[p]
                p += 1
                de = (de + 1) & 0xFFFF
                if (de & 0x1F) >= 0x18:
                    de &= 0xFFE0
            de = fila + 0x20
            if (de >> 8) == 0x7B:
                de = 0x7800 | (de & 0xFF)


# ---------------------------------------------------------------------------
# Las dos pantallas
# ---------------------------------------------------------------------------

def vram_del_titulo(rom):
    """Lo que deja INIT (0x4203) antes de escribir ningun rotulo."""
    v = bytearray(0x4000)
    lista_de_bloques(rom, 0x6A85, 1, v)              # 0x4253: disparos y vidas
    sube_caracteres_girados(rom, 0x6AF8, 10, 0x2110, v, 1)   # 0x426B: las nubes
    lista_de_bloques(rom, 0x7792, 3, v)              # 0x4272
    copia(rom, 0x798B, 0x66E0, 0xF8, v)              # 0x427A: la fuente
    lista_de_bloques(rom, 0x712B, 3, v)              # 0x4285: sprites
    copia_dos_tiras(rom, v)                          # 0x428D
    rellena(rom, 0x4D2F, 0x4468, 5, v)               # 0x42AD: los colores
    copia_vram_a_vram(v, 0x0000, 0x0800)             # 0x42C5
    copia_vram_a_vram(v, 0x2000, 0x2800)             # 0x42CB
    return v


def vram_de_la_partida(rom, epoca, vidas=3):
    """Lo que dejan EMPIEZA_EPOCA (0x4468), EMPIEZA_VIDA (0x44A3) y la primera
    vuelta de PASO_DE_LA_PARTIDA (0x46FE), con la interrupcion ya pasada una
    vez por las nubes y por el avion.

    Devuelve la VRAM y la RAM, que es donde vive la copia de la tabla de
    atributos de sprite (0xE380) que la interrupcion sube en cada fotograma.
    """
    marca, dibujos, cuantos, bicho, color, vueltas = EPOCAS[epoca]
    v = vram_del_titulo(rom)
    ram = bytearray(0x10000)

    borra_los_nombres(v)                             # 0x4473
    escribe_rotulo(rom, 0x4FA3, v)                   # 0x4476: el marcador entero
    v[0x38F9:0x38FB] = bytes(2)                      # 0x448C: sin segundo jugador
    v[0x3919:0x391F] = bytes(6)                      # 0x4495
    borra_el_area_de_juego(v, 0x00)                  # 0x449E

    copia(rom, 0x4E7C + (epoca - 1) * 4, 0x395A, 4, v)   # 0x44A3: el ano
    copia(rom, 0x6AF0, 0x2060, 8, v)                 # 0x44E4: la marca del avion
    copia(rom, 0x6F2B, 0x1800, 0x20, v)             # 0x44EF: el avion
    copia(rom, 0x71F1, 0x1A00, 0x100, v)            # 0x44FD: sprites comunes
    v[0x2340:0x2640] = bytes(0x300)                  # 0x4505: patrones del bicho
    v[0x0340:0x0640] = bytes(0x300)                  # 0x4515: y su color
    copia(rom, marca, 0x2058, 8, v)                  # 0x4529: el caracter 0x0B
    if dibujos:                                      # 0x4548, 0x456B, 0x4585, 0x45A0
        copia(rom, dibujos, 0x1900, cuantos, v)
    else:                                            # 0x45BB: la epoca 5, a trozos
        for k in range(8):
            copia(rom, 0x7752, 0x1900 + 0x20 * k, 0x20, v)
        for k in range(8):
            copia(rom, 0x7772, 0x1A00 + 0x20 * k, 0x20, v)
    sube_caracteres_girados(rom, bicho, 5, 0x2340, v)    # 0x4562: el bicho grande
    copia(rom, 0x79D3, 0x2638, 0x50, v)              # 0x45E9: las cifras
    pinta_fondo_de_la_epoca(rom, color, vueltas, 0x0008, v)   # 0x45FC
    copia_vram_a_vram(v, 0x2000, 0x2800)             # 0x4634
    copia_vram_a_vram(v, 0x0000, 0x0800)             # 0x463D

    monta_sprites_de_la_epoca(rom, epoca, ram)       # 0x4665
    borra_el_area_de_juego(v, 0x0A)                  # 0x4684: el cielo
    ram[0xE210:0xE22C] = rom[0x4CE9 - ORG:0x4CE9 - ORG + 0x1C]   # 0x4691
    pinta_vidas(v, vidas)                            # 0x46D7
    pinta_enemigos_que_faltan(v, 5)                  # 0x4739: 25 enemigos, de 5 en 5
    pinta_seis_cifras(b"\0\0\0", 0x3859, v)          # 0x4796: el record
    pinta_seis_cifras(b"\0\0\0", 0x38B9, v)          # 0x47B7: los puntos

    pinta_las_nubes(rom, ram, v)                     # 0x5103
    jugador_pon_sprite(ram, v)                       # 0x53FE
    return v, ram


def pinta_vidas(v, vidas):
    """0x46D7: siete casillas borradas en la fila 18 del marcador y una nave
    (el caracter 9) por cada vida de mas, hasta siete."""
    v[0x3A59:0x3A60] = bytes(7)
    n = min(vidas - 1, 7)
    if n > 0:
        v[0x3A59:0x3A59 + n] = bytes([9]) * n


def pinta_enemigos_que_faltan(v, grupos):
    """0x4739: los enemigos que faltan, en marcas de a cinco (caracter 0x0B),
    en dos filas de cinco a partir de la casilla 0x3999."""
    v[0x3999:0x399E] = bytes(5)
    v[0x39B9:0x39BE] = bytes(5)
    d = 0x3999
    while grupos:
        for _ in range(5):
            v[d] = 0x0B
            d += 1
            grupos -= 1
            if not grupos:
                return
        d += 0x20 - 5


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


def pinta_los_sprites(v, ram, px, esc=2):
    """Los sprites de la copia de 0xE380 encima de lo ya pintado.

    Son de 16x16 (R1=0xE2), asi que el patron va de cuatro en cuatro y sus 32
    bytes se leen por cuartos: arriba-izquierda, abajo-izquierda,
    arriba-derecha y abajo-derecha. La Y va una linea por debajo de lo escrito,
    el bit 7 del color corre el sprite 32 pixeles a la izquierda, y 0xD0 cierra
    la lista.
    """
    for s in range(32):
        y, x, pat, col = ram[0xE380 + s * 4:0xE384 + s * 4]
        if y == 0xD0:
            break
        arriba = y + 1 if y < 0xD0 else y + 1 - 256
        izq = x - 32 if col & 0x80 else x
        tinta = col & 0x0F
        if not tinta:
            continue
        base = 0x1800 + (pat & 0xFC) * 8
        for q in range(4):
            ox, oy = (q // 2) * 8, (q % 2) * 8
            for fy in range(8):
                b = v[base + q * 8 + fy]
                for fx in range(8):
                    if not (b & (0x80 >> fx)):
                        continue
                    py, pxx = arriba + oy + fy, izq + ox + fx
                    if not (0 <= py < 192 and 0 <= pxx < 256):
                        continue
                    for dy in range(esc):
                        for dx in range(esc):
                            px[py * esc + dy][pxx * esc + dx] = PAL[tinta]


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


def pinta_el_bicho_grande(rom, v, fn, esc=3):
    """Los ocho fotogramas de 0x69C5, de 6 x 4 caracteres, con los caracteres
    de la epoca que ya estan en la VRAM.

    No es una foto de la partida: es el bicho montado aparte, porque en la
    pantalla solo sale cuando se acaban los enemigos de la fase (0x6518).
    """
    cols, filas = 4, 2
    w, h = cols * 6 * 8 * esc, filas * 4 * 8 * esc
    px = [[FONDO] * w for _ in range(h)]
    for k in range(8):
        base = 0x69C5 - ORG + 24 * k
        cx, cy = (k % cols) * 6 * 8, (k // cols) * 4 * 8
        for i in range(24):
            n = rom[base + i]
            ox, oy = (i % 6) * 8, (i // 6) * 8
            for y in range(8):
                pat = v[0x2000 + n * 8 + y]
                col = v[0x0000 + n * 8 + y]
                tinta = PAL[col >> 4] if (col >> 4) else FONDO
                fondo = PAL[col & 15] if (col & 15) else FONDO
                for x in range(8):
                    color = tinta if pat & (0x80 >> x) else fondo
                    for dy in range(esc):
                        for dx in range(esc):
                            px[(cy + oy + y) * esc + dy][(cx + ox + x) * esc + dx] = color
    png(w, h, px, fn)


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
    pinta_sprites(rom, 0x71EE + 3, 8, os.path.join(out, "sprites.png"))
    print("sprites.png")

    # 6. La pantalla de partida de cada epoca, con el marcador, el cielo, las
    #    nueve nubes de 0x4CE9 y el sprite del avion
    for e in range(1, 6):
        p, ram = vram_de_la_partida(rom, e)
        w, h, px = pinta_pantalla(p)
        pinta_los_sprites(p, ram, px)
        png(w, h, px, os.path.join(out, "partida%d.png" % e))
        print("partida%d.png" % e)

        # y el bicho grande de esa epoca, que se pinta con los caracteres que
        # 0x4562 acaba de subir a la VRAM 0x2340
        pinta_el_bicho_grande(rom, p, os.path.join(out, "bicho%d.png" % e))
        print("bicho%d.png" % e)

        # 7. Los dieciseis primeros caracteres de la partida: los ocho disparos
        #    del jugador (1 a 8), la nave de las vidas (9), el cielo (0x0A), la
        #    marca de los enemigos que faltan (0x0B) y la casilla de debajo del
        #    avion (0x0C)
        if e == 1:
            pinta_caracteres(p, 0x00, 0x10, os.path.join(out, "caracteres.png"))
            print("caracteres.png")


if __name__ == "__main__":
    main()
