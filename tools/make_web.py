#!/usr/bin/env python3
"""Genera la portada de la web, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Ni el rotulo de la cabecera ni la galeria son ilustraciones traidas de fuera, y
tampoco son capturas: salen de repetir, paso a paso, lo que hace el propio
cartucho. tools/graficos.py reconstruye la memoria de video repitiendo las copias de la
ROM y monta la pantalla con sus mismas listas de rotulos; si un rango estuviera
mal etiquetado, la galeria saldria ruido.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras de la portada salen de contar sobre el listado generado, no de
# escribirlas aqui a ojo: 16384 = 8911 + 7473, que es lo que imprime
# tools/presupuesto.py (make sanity).
CODIGO = 8911
DATOS = 7473
EPOCAS = 5                          # los cinco anos de la tabla de 0x4E7C
DIRECCIONES = 16                    # las dieciseis direcciones de vuelo


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Time Pilot — desensamblado comentado",
        aviso="<b>Aquí no hay ni una captura de pantalla.</b> Las imágenes "
              "están dibujadas repitiendo lo que hace el cartucho: se sube a "
              "la memoria de vídeo lo mismo que sube él, con sus mismas "
              "direcciones, y se monta la pantalla con sus mismas listas. Lo "
              "demás —el listado y las cifras— sale del binario y se "
              "reproduce con <code>make</code>.",
        claim="Un cartucho de 16 KB en el que el avión no se mueve: gira. "
              "Los disparos y el bicho del final de época no son sprites, "
              "son letras de la pantalla que miran antes de escribirse, y la "
              "interrupción reparte el trabajo en un ciclo de seis "
              "fotogramas.",
        ficha=["Konami · <b>©KONAMI 1983</b>",
               "Cartucho <b>RC-703</b>, 16 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>183e8026…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El juego en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(EPOCAS), "épocas, de 1910 a 2001"),
                (str(DIRECCIONES), "direcciones de vuelo"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Cada una de estas imágenes es el cartucho repetido fuera "
                 "de él: los caracteres se suben como los sube la ROM, con "
                 "sus colores, y la pantalla se monta con las mismas listas de "
                 "rótulos. Debajo de cada pie está la dirección de donde "
                 "sale.",
        pie_leg="Esto es trabajo de documentación y preservación: el "
                "código y los gráficos siguen siendo de sus autores y de "
                "Konami, y la imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Time Pilot — a commented disassembly",
        aviso="<b>There is not one screenshot here.</b> The pictures are drawn "
              "by repeating what the cartridge does: the same bytes go up to "
              "video memory at the same addresses, and the screen is built "
              "from its own label lists. Everything else —the listing and "
              "the numbers— comes from the binary and is reproducible with "
              "<code>make</code>.",
        claim="A 16 KB cartridge where the plane does not move: it turns. The "
              "shots and the end-of-era machine are not sprites but screen "
              "characters that look before they write, and the interrupt "
              "spreads its work over a six-frame cycle.",
        ficha=["Konami · <b>©KONAMI 1983</b>",
               "An <b>RC-703</b> 16 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>183e8026…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The game in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(EPOCAS), "eras, from 1910 to 2001"),
                (str(DIRECCIONES), "directions of flight"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Each of these pictures is the cartridge replayed outside it: "
                 "the characters go up the way the ROM sends them, with their "
                 "colours, and the screen is built from the same label lists. "
                 "Under each caption is the address it comes from.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("La cuarta época es 1984, no 1982",
         "<p>Los cinco años que pinta el marcador están en 0x4E7C, cuatro "
         "caracteres cada uno: <b>1910, 1940, 1970, 1984 y 2001</b>. En el "
         "salón recreativo esa cuarta época es 1982, el año del original; "
         "esta conversión la cambió, aunque el propio cartucho firma "
         "©KONAMI 1983.</p>"),
        ("La demo se pilota leyendo el propio cartucho",
         "<p>Cuando el juego se queda solo, el joystick no sale de ningún "
         "generador de números. 0x546B coge el <b>registro R</b> —el del "
         "refresco de la memoria— y con él elige un byte del código a "
         "partir de 0x5399; ese byte se mete tal cual en 0xE009 como si "
         "viniera del mando.</p>"
         "<p>O sea que la demo vuela leyendo el programa que la está "
         "moviendo.</p>"),
        ("Los disparos son caracteres que miran antes de escribir",
         "<p>El MSX solo puede enseñar cuatro sprites en una línea, así que "
         "Time Pilot deja los sprites para los aviones y dibuja los ocho "
         "disparos <b>en la tabla de nombres</b>. Cada ficha son cuatro bytes "
         "(0xE230): la casilla, la dirección y el carácter.</p>"
         "<p>Antes de pintarse, cada disparo <b>lee</b> la casilla a la que va "
         "(0x557B): si lo que hay no es cielo, no se dibuja. Con eso ni se "
         "pisan entre ellos ni tapan el decorado.</p>"),
        ("El avión no se mueve: gira",
         "<p>El mando dice a cuál de las dieciséis direcciones se quiere ir "
         "(0x545B), y el avión <b>va girando un paso cada vez</b> hasta "
         "llegar, siempre por el lado corto (0x53CE). Cada dirección tiene "
         "sus 32 bytes de dibujo en 0x6F2B, y solo el que toca está en la "
         "memoria de vídeo: se sube en cuanto cambia.</p>"),
        ("La interrupción reparte el trabajo en seis fotogramas",
         "<p>0xE01F cuenta de 0 a 5 y una tabla de seis entradas (0x4118) dice "
         "qué toca: en uno los disparos, las nubes y el avión; en otro el "
         "fondo; en otro el bicho grande; y en los tres restantes, los "
         "enemigos. Repartir así es lo que le deja mover tantas cosas en un "
         "MSX1.</p>"),
        ("Las mismas letras, dos veces en la VRAM y una en el cartucho",
         "<p>Los bytes de 0x798B en adelante se suben a <b>dos juegos de "
         "caracteres distintos</b>, uno para el menú y otro para la fuente. "
         "Como en SCREEN 2 el color va por carácter, tener el mismo dibujo "
         "con dos números es lo que permite el mismo alfabeto en dos "
         "colores, sin gastar el doble de cartucho. Con las cifras (0x79D3) "
         "pasa igual.</p>"),
        ("El silencio es un programa de sonido vacío",
         "<p>Para callar el canal 2 de golpe, 0x5C8F no toca el PSG: le apunta "
         "el puntero al <b>0xFF que cierra</b> el programa de 0x7E40. El canal "
         "lee el final y se calla él solo, por el camino de siempre.</p>"),
    ],
    "en": [
        ("The fourth era is 1984, not 1982",
         "<p>The five years the panel paints are at 0x4E7C, four characters "
         "each: <b>1910, 1940, 1970, 1984 and 2001</b>. In the arcade that "
         "fourth era is 1982, the year of the original; this conversion "
         "changed it, even though the cartridge itself signs ©KONAMI "
         "1983.</p>"),
        ("The attract mode flies by reading the cartridge itself",
         "<p>When the game is left alone, the joystick does not come from "
         "any random generator. 0x546B takes the <b>R register</b> —the "
         "memory refresh one— and uses it to pick a byte of the code from "
         "0x5399 on; that byte goes straight into 0xE009 as if it came from "
         "the controls.</p>"
         "<p>So the demo flies by reading the very program that is flying "
         "it.</p>"),
        ("The shots are characters that look before they write",
         "<p>The MSX can only show four sprites on a line, so Time Pilot keeps "
         "the sprites for the planes and draws the eight shots <b>in the name "
         "table</b>. Each slot is four bytes (0xE230): the cell, the direction "
         "and the character.</p>"
         "<p>Before painting itself, each shot <b>reads</b> the cell it is "
         "heading for (0x557B): if what is there is not sky, it is not drawn. "
         "That way they neither overwrite each other nor cover the "
         "scenery.</p>"),
        ("The plane does not move: it turns",
         "<p>The controls say which of the sixteen directions you want "
         "(0x545B), and the plane <b>turns one step at a time</b> until it "
         "gets there, always the short way round (0x53CE). Each direction has "
         "its own 32 bytes of artwork at 0x6F2B, and only the one in use is in "
         "video memory: it goes up as soon as it changes.</p>"),
        ("The interrupt spreads its work over six frames",
         "<p>0xE01F counts from 0 to 5 and a six-entry table (0x4118) says "
         "what is due: on one frame the shots, the clouds and the plane; on "
         "another the background; on another the big machine; and on the "
         "remaining three, the enemies. Splitting it like that is what lets it "
         "move so much on an MSX1.</p>"),
        ("The same letters, twice in VRAM and once in the cartridge",
         "<p>The bytes from 0x798B on are uploaded into <b>two different "
         "character sets</b>, one for the menu and one for the font. Since "
         "colour in SCREEN 2 goes per character, having the same drawing under "
         "two numbers is what allows the same alphabet in two colours without "
         "spending twice the cartridge. The digits (0x79D3) do the same.</p>"),
        ("Silence is an empty sound program",
         "<p>To shut channel 2 up at once, 0x5C8F does not touch the PSG: it "
         "points the channel at the <b>0xFF that closes</b> the program at "
         "0x7E40. The channel reads the end and goes quiet on its own, the "
         "usual way.</p>"),
    ],
}

# La galeria: fichero, pie en castellano, pie en ingles.
GALERIA = [
    ("titulo.png",
     "0x4A62 — la pantalla de título, montada con las listas de rótulos de "
     "0x4EAB y 0x4E90 sobre los caracteres que sube INIT",
     "0x4A62 — the title screen, built from the label lists at 0x4EAB and "
     "0x4E90 over the characters INIT uploads"),
    ("menu.png",
     "0x4EE8 — y con las cuatro opciones del menú encima: uno o dos "
     "jugadores, con joystick o con teclado. Cada opción es una lista de "
     "rótulos más",
     "0x4EE8 — and with the four menu options on top: one or two players, "
     "with joystick or keyboard. Each option is one more label list"),
    ("letras.png",
     "0x7792 y 0x798B — los caracteres con los que está escrito todo eso, "
     "con su color. A la derecha están los mismos bytes subidos otra vez con "
     "otro número de carácter, que es como salen en dos colores",
     "0x7792 and 0x798B — the characters all of that is written with, in "
     "their colours. On the right are the same bytes uploaded again under "
     "another character number, which is how they come out in two colours"),
    ("aviones.png",
     "0x6F2B — los dieciséis dibujos del avión, uno por dirección de "
     "vuelo, de 32 bytes cada uno. En la memoria de vídeo solo hay uno: el "
     "que toca",
     "0x6F2B — the sixteen drawings of the plane, one per direction of "
     "flight, 32 bytes each. Only one is in video memory: the one in use"),
    ("sprites.png",
     "0x712B — parte de los patrones de sprite comunes, los que valen para "
     "todas las épocas",
     "0x712B — some of the common sprite patterns, the ones that work for "
     "every era"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    ruta_logo = os.path.join(imgdir, "logo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Time Pilot">'
                if os.path.exists(ruta_logo) else "<h1>Time Pilot</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
