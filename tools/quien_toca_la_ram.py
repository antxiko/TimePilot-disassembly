#!/usr/bin/env python3
"""Para cada direccion de RAM, que instrucciones la nombran y desde donde.

El mapa de RAM de las notas se escribe leyendo el codigo, y es facil colar una
lectura mal. Esto saca la lista completa para poder repasarla entera.

Uso: quien_toca_la_ram.py <asm> [prefijo]      (prefijo: e1, e2, e12...)
"""
import re
import sys

asm = open(sys.argv[1], encoding="utf-8").read().splitlines()
pref = (sys.argv[2] if len(sys.argv) > 2 else "e").lower()
etiqueta, usos = "(cabecera)", {}
for ln in asm:
    m = re.match(r"^([A-Za-z_][A-Za-z_0-9]*):", ln)
    if m:
        etiqueta = m.group(1)
        continue
    m = re.match(r"^\t(.*?)\s*;([0-9a-f]{4})", ln)
    if not m:
        continue
    instr, dire = m.group(1).strip(), m.group(2)
    for r in re.findall(r"0(" + pref + r"[0-9a-f]{2,3})h", instr):
        usos.setdefault(r.upper(), []).append((dire, instr, etiqueta))
for r in sorted(usos):
    print("0x%s" % r)
    for d, i, e in usos[r]:
        print("    %s  %-28s %s" % (d, i, e))
