# Repasa una partida grabada y dice, segundo a segundo, que estaba pasando.
#
# Sirve para elegir DONDE medir antes de gastar una medida cara. Las trampas
# que evita:
#
#   - La demo corre EL MISMO codigo que la partida, asi que medir sin separarlas
#     mezcla al jugador con la maquina. Aqui se lee 0xE014 (demo) y 0xE015 (fase
#     en marcha) en cada muestra.
#   - `reverse goto` seguido de una espera en tiempo REAL no captura el instante
#     pedido: la maquina sigue corriendo mientras se espera. Por eso aqui el
#     `goto` y las lecturas van en la MISMA secuencia, sin esperas de por medio.
#
# Uso:  openmsx -script tools/omsx_repasa.tcl
#       (la maquina y el cartucho los trae dentro el propio replay)

set ::destino [file normalize "work/replays"]
set ::salida [open [file join $::destino "repaso.txt"] w]

set renderer none
set throttle off

reverse loadreplay -viewonly [file join $::destino "partida.omr"]

proc lee {d} { debug read memory $d }

puts $::salida "  seg  demo fase epoca ronda vidas  faltan  enpant  puntos"
puts $::salida "  ---------------------------------------------------------"

# El final del replay, para no pedir un instante que no existe.
set fin [dict get [reverse status] end]

for {set t 2} {$t < $fin} {incr t 2} {
    reverse goto $t
    set demo   [lee 0xE014]
    set fase   [lee 0xE015]
    set epoca  [lee 0xE180]
    set ronda  [lee 0xE182]
    set vidas  [lee 0xE002]
    set faltan [lee 0xE120]
    set enpant [lee 0xE121]
    set p1 [lee 0xE00B] ; set p2 [lee 0xE00C] ; set p3 [lee 0xE00D]
    puts $::salida [format "  %4d   %2d   %2d    %2d    %02X    %2d    %4d    %4d   %02X%02X%02X" \
        $t $demo $fase $epoca $ronda $vidas $faltan $enpant $p1 $p2 $p3]
}
puts $::salida "  ---- fin del replay en [format %.1f $fin] s"
close $::salida
exit
