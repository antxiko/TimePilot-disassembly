# omsx_perfil_interrupcion.tcl - En que se le va el tiempo a la interrupcion.
#
# Pone hitos en los puntos de costura del gancho H.KEYI y cronometra cada tramo
# con el reloj de emulacion. Como los hitos son direcciones reales, los tramos
# que el codigo se salta (los `jp nz` de 0x4041, 0x40B1 y 0x40D9, y el `jp z`
# de 0x4049) aparecen solos como saltos de un hito a otro no consecutivo:
#
#   0x4037 entrada del gancho           0x4098 el ciclo de seis (0xE01F)
#   0x403D el paso (aqui vuelve 0x410F) 0x40AC vuelta del despachador
#   0x40CA subir la tabla de sprites    0x40D5 tabla de sprites subida
#   0x40F0 los contadores               0x4112 la salida de verdad
#
# Variables de entorno: TP_MODO (demo|partida), TP_PILOTO, TP_VENTANA, TP_SALIDA.
#
#   TP_MODO=partida TP_PILOTO=1 "C:/Program Files/openMSX/openmsx.exe" \
#       -machine Philips_VG_8020 -cart timepilot.rom \
#       -script tools/omsx_perfil_interrupcion.tcl

source "C:/Users/Antxiko/Documents/DES_ASM/TIMEPILOT_DISAM/tools/omsx_comun.tcl"

set ::MODO    [opcion TP_MODO demo]
set ::PILOTO  [opcion TP_PILOTO 0]
set ::VENTANA [expr {double([opcion TP_VENTANA 30])}]
set ::SALIDA  [opcion TP_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/TIMEPILOT_DISAM/work/omsx/perfil_interrupcion_$::MODO.txt"]

array set ::NOMBRE {
    16439 "4037 entrada"
    16445 "403D paso"
    16536 "4098 ciclo6"
    16556 "40AC vuelta-despacho"
    16586 "40CA sube-sprites"
    16597 "40D5 sprites-hechos"
    16624 "40F0 contadores"
    16658 "4112 salida"
}

set ::mide 0
set ::previo ""
set ::tprevio 0.0
array set ::tramo {}

proc hito {a} {
    if {!$::mide} return
    set t [machine_info time]
    if {$::previo ne ""} {
        set k "$::previo -> $::NOMBRE($a)"
        if {![info exists ::tramo($k)]} { set ::tramo($k) {0 0.0} }
        lassign $::tramo($k) n s
        set ::tramo($k) [list [expr {$n + 1}] [expr {$s + $t - $::tprevio}]]
    }
    set ::previo $::NOMBRE($a)
    set ::tprevio $t
    if {$a == 16658} { set ::previo "" }
}

foreach a [array names ::NOMBRE] { debug set_bp $a {} "hito $a" }

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
    set fot [expr {[machine_info VDP_frame_count] - $::f0}]
    set ven [expr {$t1 - $::t0}]
    set f [open $::SALIDA w]
    puts $f "# MODO $::MODO   PILOTO $::PILOTO"
    puts $f "estado_al_abrir  $::foto0"
    puts $f "estado_al_cerrar [foto]"
    puts $f "ventana_emulada_s [format %.6f $ven]"
    puts $f "fotogramas_VDP    $fot"
    puts $f ""
    puts $f [format "%-42s %6s %11s %10s %9s %9s" tramo veces total_s media_us ciclosZ80 %ventana]
    set tot 0.0
    foreach k [lsort [array names ::tramo]] {
        lassign $::tramo($k) n s
        set tot [expr {$tot + $s}]
        puts $f [format "%-42s %6d %11.6f %10.1f %9.0f %8.2f%%" $k $n $s \
            [expr {$s / $n * 1e6}] [expr {$s / $n * 3579545.0}] [expr {$s / $ven * 100.0}]]
    }
    puts $f ""
    puts $f [format "SUMA DE TRAMOS %11.6f s = %.2f%% de la ventana" $tot [expr {$tot / $ven * 100.0}]]
    close $f
    exit
}

set throttle off
perro_guardian 180
al_estado
