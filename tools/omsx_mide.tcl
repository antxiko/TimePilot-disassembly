# Mide sobre la partida grabada: lo que cuesta la interrupcion y lo que escribe
# al VDP. Con cifras, no con suposiciones.
#
# Que se mide y donde:
#
#   - EL CONTROL: un punto de ruptura en 0x0038, el vector de interrupcion de la
#     ROM. Tiene que dar el ritmo del cuadro. Si sale a cero, la instrumentacion
#     esta rota y los demas ceros no significan nada.
#   - EL COSTE: se apunta el reloj emulado al entrar en INTERRUPCION (0x4037) y
#     al llegar a su `ret` (0x4117), y se acumula la diferencia. Ojo: eso mide
#     el gancho DEL CARTUCHO, no la interrupcion entera; lo que la BIOS hace
#     antes de saltar aqui queda fuera.
#   - EL REPARTO: 0xE01F lleva la fase del ciclo de seis fotogramas, y se lee al
#     SALIR, que es cuando ya vale para la pasada que se acaba de dar.
#   - LAS REENTRADAS: en 0x410B la interrupcion mira si ha llegado otra mientras
#     tanto y, si es asi, vuelve a 0x403D sin salir. Se cuentan aparte.
#   - EL VDP: puntos de observacion de escritura en los puertos 0x98 (datos) y
#     0x99 (direccion y registros). El callback es BARATO a proposito -solo
#     `incr`-, que es la condicion para que no ahogue al emulador.
#
# Y todo dentro de una ventana en la que 0xE014 dice que NO corre la demo y
# 0xE015 que SI hay fase en marcha, porque la demo ejecuta el mismo codigo y
# mezclaria al jugador con la maquina.
#
# Uso:  openmsx -script tools/omsx_mide.tcl
#       (la maquina y el cartucho los trae dentro el replay)

set ::destino [file normalize "work/replays"]
set ::DESDE 30
set ::HASTA 90

set renderer none
set throttle off

reverse loadreplay -viewonly [file join $::destino "partida.omr"]
reverse goto $::DESDE

# --------------------------------------------------------------- los contadores
set ::n_0038 0
set ::n_entra 0
set ::n_sale 0
set ::n_reentra 0
set ::t_entrada 0
set ::t_dentro 0.0
set ::p98 0
set ::p99 0
for {set i 0} {$i < 6} {incr i} { set ::fase($i) 0 ; set ::tfase($i) 0.0 }

debug set_bp 0x0038 {} { incr ::n_0038 }
debug set_bp 0x4037 {} {
    incr ::n_entra
    set ::t_entrada [machine_info time]
}
debug set_bp 0x410B {} { incr ::n_reentra }
debug set_bp 0x4117 {} {
    incr ::n_sale
    set d [expr {[machine_info time] - $::t_entrada}]
    set ::t_dentro [expr {$::t_dentro + $d}]
    set f [debug read memory 0xE01F]
    if {$f < 6} {
        incr ::fase($f)
        set ::tfase($f) [expr {$::tfase($f) + $d}]
    }
}
debug set_watchpoint write_io 0x98 {} { incr ::p98 }
debug set_watchpoint write_io 0x99 {} { incr ::p99 }

# 0x410B se ejecuta SIEMPRE, se tome el salto o no: cuenta pasadas, no
# reentradas. La reentrada de verdad es la que vuelve a 0x403D, asi que se
# resta el numero de salidas.

set ::t0 [machine_info time]
after time [expr {$::HASTA - $::DESDE}] {
    set dur [expr {[machine_info time] - $::t0}]
    set f [open [file join $::destino "medidas.txt"] w]
    puts $f "VENTANA  de $::DESDE a $::HASTA s del replay ([format %.3f $dur] s emulados)"
    puts $f "  demo (0xE014) = [debug read memory 0xE014]   fase en marcha (0xE015) = [debug read memory 0xE015]"
    puts $f "  epoca (0xE180) = [debug read memory 0xE180]"
    puts $f ""
    puts $f "CONTROL"
    puts $f "  interrupciones de la ROM (bp 0x0038)   $::n_0038"
    puts $f "  cuadros por segundo                    [format %.2f [expr {$::n_0038/$dur}]]"
    puts $f ""
    puts $f "LA INTERRUPCION DEL CARTUCHO (0x4037-0x4117)"
    puts $f "  entradas                               $::n_entra"
    puts $f "  salidas                                $::n_sale"
    puts $f "  pasadas por el mirador de 0x410B       $::n_reentra"
    puts $f "  reentradas sin salir (0x410B - salidas) [expr {$::n_reentra - $::n_sale}]"
    puts $f "  tiempo dentro                          [format %.4f $::t_dentro] s de [format %.3f $dur]"
    puts $f "  PORCENTAJE DEL CUADRO                  [format %.2f [expr {100.0*$::t_dentro/$dur}]] %"
    if {$::n_sale > 0} {
        puts $f "  por interrupcion                       [format %.3f [expr {1000.0*$::t_dentro/$::n_sale}]] ms"
    }
    puts $f ""
    puts $f "EL REPARTO EN SEIS FOTOGRAMAS (0xE01F)"
    puts $f "  fase  cuantas   ms cada una   % del total"
    for {set i 0} {$i < 6} {incr i} {
        if {$::fase($i) > 0} {
            puts $f [format "   %d    %6d     %7.3f       %5.1f %%" $i $::fase($i) \
                [expr {1000.0*$::tfase($i)/$::fase($i)}] \
                [expr {100.0*$::tfase($i)/$::t_dentro}]]
        } else {
            puts $f [format "   %d    %6d           -           -" $i $::fase($i)]
        }
    }
    puts $f ""
    puts $f "EL VDP"
    puts $f "  escrituras al puerto 0x98 (datos)      $::p98"
    puts $f "  escrituras al puerto 0x99 (direccion)  $::p99"
    if {$::n_0038 > 0} {
        puts $f "  por fotograma: 0x98 = [format %.1f [expr {1.0*$::p98/$::n_0038}]]   0x99 = [format %.1f [expr {1.0*$::p99/$::n_0038}]]"
    }
    close $f
    exit
}
