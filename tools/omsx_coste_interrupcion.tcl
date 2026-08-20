# omsx_coste_interrupcion.tcl - Cuanto del cuadro se pasa Time Pilot dentro del
# gancho H.KEYI (0x4037-0x4117).
#
# Cronometra con el reloj de emulacion dos tramos complementarios:
#   DENTRO  0x4037 (entrada del gancho) -> 0x4112 (el `pop af` de la salida,
#           que solo se pisa cuando la interrupcion se va de verdad; asi el
#           tiempo incluye los pasos extra que da 0x410F si ha llegado otra
#           interrupcion mientras tanto)
#   FUERA   0x4112 -> la siguiente 0x4037
# Dentro + fuera tiene que dar el periodo del cuadro: ese es el cuadre.
#
# Reparte lo medido leyendo 0xE014 (demo) y 0xE015 (fase en marcha), y ademas
# por la fase del ciclo de seis (0xE01F, leida a la salida, que es la que se
# acaba de ejecutar).
#
# Controles de la misma pasada: pasadas por 0x0038 (el vector de la BIOS) y
# fotogramas del VDP (machine_info VDP_frame_count). Si los fotogramas salen a
# cero o entradas y salidas no cuadran, la medida no vale.
#
# Variables de entorno:
#   TP_MODO     demo (por defecto) o partida
#   TP_PILOTO   1 para que juegue el piloto sintetico de omsx_comun.tcl
#   TP_VENTANA  segundos emulados de medida (30 por defecto)
#   TP_SALIDA   fichero de resultado
#
#   TP_MODO=partida TP_PILOTO=1 "C:/Program Files/openMSX/openmsx.exe" \
#       -machine Philips_VG_8020 -cart timepilot.rom \
#       -script tools/omsx_coste_interrupcion.tcl

source "C:/Users/Antxiko/Documents/DES_ASM/TIMEPILOT_DISAM/tools/omsx_comun.tcl"

set ::MODO    [opcion TP_MODO demo]
set ::PILOTO  [opcion TP_PILOTO 0]
set ::VENTANA [expr {double([opcion TP_VENTANA 30])}]
set ::SALIDA  [opcion TP_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/TIMEPILOT_DISAM/work/omsx/coste_interrupcion_$::MODO.txt"]

set ::mide 0
set ::tent 0.0
set ::tsal 0.0
set ::hay_salida 0
set ::entradas 0
set ::salidas 0
set ::pasos 0
set ::n38 0
set ::desparejadas 0
array set ::acu {}
array set ::acufase {}
array set ::fuera {}

proc suma {arr clave dt} {
    upvar #0 $arr a
    if {![info exists a($clave)]} { set a($clave) {0 0.0} }
    lassign $a($clave) n t
    set a($clave) [list [expr {$n + 1}] [expr {$t + $dt}]]
}

proc etiqueta {} {
    set demo [debug read memory 0xE014]
    if {[debug read memory 0xE015] == 0} { return titulo }
    if {$demo == 1} { return demo_fase }
    return partida
}

proc entra {} {
    if {!$::mide} return
    set t [machine_info time]
    if {$::hay_salida} { suma ::fuera [etiqueta] [expr {$t - $::tsal}] }
    incr ::entradas
    set ::tent $t
}

proc sale {} {
    if {!$::mide} return
    if {$::entradas == $::salidas} { incr ::desparejadas ; return }
    incr ::salidas
    set t [machine_info time]
    set ::tsal $t
    set ::hay_salida 1
    set dt [expr {$t - $::tent}]
    set e [etiqueta]
    suma ::acu $e $dt
    suma ::acufase "$e/[debug read memory 0xE01F]" $dt
}

proc paso {} { if {$::mide} { incr ::pasos } }
proc tic38 {} { if {$::mide} { incr ::n38 } }

debug set_bp 0x4037 {} { entra }
debug set_bp 0x4112 {} { sale }
debug set_bp 0x403D {} { paso }
debug set_bp 0x0038 {} { tic38 }

proc arranca {} {
    set ::t0 [machine_info time]
    set ::f0 [machine_info VDP_frame_count]
    set ::foto0 [foto]
    set ::mide 1
    if {$::PILOTO} { piloto_arranca }
    after time $::VENTANA informe
}

proc informe {} {
    set ::mide 0
    set t1 [machine_info time]
    set f1 [machine_info VDP_frame_count]
    set ventana [expr {$t1 - $::t0}]
    set fotogramas [expr {$f1 - $::f0}]
    set f [open $::SALIDA w]
    puts $f "# MODO $::MODO   PILOTO $::PILOTO"
    puts $f "estado_al_abrir  $::foto0"
    puts $f "estado_al_cerrar [foto]"
    puts $f ""
    puts $f "# CONTROLES"
    puts $f "ventana_emulada_s    [format %.6f $ventana]"
    puts $f "fotogramas_VDP       $fotogramas"
    puts $f "fotogramas_por_s     [format %.4f [expr {$fotogramas / $ventana}]]"
    puts $f "periodo_de_cuadro_us [format %.2f [expr {$ventana / $fotogramas * 1e6}]]"
    puts $f "pasadas_0x0038       $::n38"
    puts $f "entradas_0x4037      $::entradas"
    puts $f "salidas_0x4112       $::salidas"
    puts $f "pasos_0x403D         $::pasos"
    puts $f "repeticiones_extra   [expr {$::pasos - $::entradas}]"
    puts $f "salidas_desparejadas $::desparejadas"
    puts $f "fotogramas_sin_int   [expr {$fotogramas - $::n38}]"
    puts $f "z80_freq             [machine_info z80_freq]"
    puts $f ""
    puts $f "# DENTRO DEL GANCHO, POR ESTADO"
    puts $f [format "%-11s %6s %11s %10s %9s %9s" estado veces total_s media_us ciclosZ80 %ventana]
    foreach k [lsort [array names ::acu]] {
        lassign $::acu($k) n t
        puts $f [format "%-11s %6d %11.6f %10.1f %9.0f %8.2f%%" $k $n $t \
            [expr {$t / $n * 1e6}] [expr {$t / $n * 3579545.0}] [expr {$t / $ventana * 100.0}]]
    }
    puts $f ""
    puts $f "# CUADRE: dentro + fuera = periodo entre interrupciones"
    puts $f [format "%-11s %6s %10s %10s %10s %9s" estado veces dentro_us fuera_us suma_us %dentro]
    foreach k [lsort [array names ::acu]] {
        if {![info exists ::fuera($k)]} continue
        lassign $::acu($k) nd td
        lassign $::fuera($k) nf tf
        set md [expr {$td / $nd * 1e6}]
        set mf [expr {$tf / $nf * 1e6}]
        puts $f [format "%-11s %6d %10.1f %10.1f %10.1f %8.2f%%" $k $nf $md $mf \
            [expr {$md + $mf}] [expr {$md / ($md + $mf) * 100.0}]]
    }
    puts $f ""
    puts $f "# DENTRO DEL GANCHO, POR FASE DEL CICLO DE SEIS (0xE01F a la salida)"
    puts $f [format "%-15s %6s %11s %10s %9s" estado/fase veces total_s media_us ciclosZ80]
    foreach k [lsort [array names ::acufase]] {
        lassign $::acufase($k) n t
        puts $f [format "%-15s %6d %11.6f %10.1f %9.0f" $k $n $t \
            [expr {$t / $n * 1e6}] [expr {$t / $n * 3579545.0}]]
    }
    close $f
    exit
}

set throttle off
perro_guardian 180
al_estado
