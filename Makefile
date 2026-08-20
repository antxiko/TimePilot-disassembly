# Time Pilot (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# La ROM no se distribuye. Hace falta en la raiz como timepilot.rom, y
# `make comprueba` verifica el sha256.

ROM      = timepilot.rom
SHA      = 183e80262301b18d41762d64a2fc326f4a4bef17832109225637e184d54a70d9
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = TIME PILOT - Konami - MSX1 - cartucho RC-703 de 16 KB en la pagina 1

OMSX     = $(WORK)/omsx

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Time Pilot (Konami, RC-703) para MSX, 16384 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo ""
	@echo " Sin el se puede leer el listado ya generado en $(SRC)/, y los"
	@echo " tests que no dependen del binario siguen pasando."
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/timepilot.trace.json: $(ROM) $(SRC)/timepilot.entries $(SRC)/timepilot.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/timepilot.entries \
	        $(WORK)/timepilot $(SRC)/timepilot.nocode

trace: $(WORK)/timepilot.trace.json

listado: $(WORK)/timepilot.trace.json $(SRC)/timepilot.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/timepilot.trace.json \
	        $(SRC)/timepilot.notes work/msx.sym $(SRC)/timepilot.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/timepilot.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/timepilot.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/timepilot.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/timepilot.trace.json $(SRC)/timepilot.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/timepilot.entries $(SRC)/timepilot.notes \
	        $(SRC)/timepilot.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

clean:
	rm -rf $(WORK)/timepilot.trace.json $(WORK)/timepilot.map $(WORK)/png

.PHONY: all comprueba trace listado verify sanity test clean imagenes web

# ---------------------------------------------------------------------------
# Las imagenes y la web
# ---------------------------------------------------------------------------
# No hacen falta capturas de emulador: tools/graficos.py sube a una memoria de
# video de mentira lo mismo que sube el cartucho, con sus mismas direcciones, y
# monta la pantalla con sus mismas listas de rotulos.
imagenes: $(ROM)
	@mkdir -p docs/imagenes work/gfx
	python3 tools/graficos.py $(ROM) work/gfx
	@cp work/gfx/logo.png work/gfx/titulo.png work/gfx/menu.png docs/imagenes/
	@cp work/gfx/letras.png work/gfx/aviones.png work/gfx/sprites.png docs/imagenes/

web: imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	@touch docs/.nojekyll
	@python3 tools/check_enlaces.py docs
