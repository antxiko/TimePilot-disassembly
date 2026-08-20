# omsx_vdp.tcl - Cuantas escrituras al VDP hace Time Pilot por fotograma.
#
# Pone un watchpoint de E/S en el puerto 0x98 (datos) y otro en el 0x99
# (direccion y registros) y cuenta. Cada escritura se apunta dos veces:
#   - por QUIEN: en que tramo del gancho H.KEYI se hizo, o fuera de el; los
#     tramos son los mismos hitos que usa omsx_perfil_interrupcion.tcl
#   - por DONDE: el PC que da el depurador en el momento del OUT, que separa el
#     bucle de COPIA_A_VRAM_YA (0x4022) del de RELLENA_VRAM_CON_A (0x402C) y de
#     PON_DIRECCION_VDP (0x4018/0x401B)
#
# De propina cuenta las vueltas del bucle principal: pasa por 0x4796
# (PINTA_RECORD) una vez por vuelta, asi que sale gratis.
#
# El divisor son los fotogramas del VDP (machine_info VDP_frame_count), no una
# cuenta propia. Control: las pasadas por 0x0038.
#
# Variables de entorno: TP_MODO (demo|partida), TP_PILOTO, TP_VENTANA, TP_SALIDA.
#
#   TP_MODO=partida TP_PILOTO=1 "C:/Program Files/openMSX/openmsx.exe" \
#       -machine Philips_VG_8020 -cart timepilot.rom -script tools/omsx_vdp.tcl

source "C:/Users/Antxiko/Documents/DES_ASM/TIMEPILOT_DISAM/tools/omsx_comun.tcl"

set ::MODO    [opcion TP_MODO demo]
set ::PILOTO  [opcion TP_PILOTO 0]
set ::VENTANA [expr {double([opcion TP_VENTANA 20])}]
set ::SALIDA  [opcion TP_SALIDA "C:/Users/Antxiko/Documents/DES_ASM/TIMEPILOT_DISAM/work/omsx/vdp_$::MODO.txt"]

set ::mide 0
set ::zona 7
set ::n38 0
set ::vueltas 0
set ::pc98 [dict create]
set ::pc99 [dict create]
array set ::d99 {registro 0 vram_escribir 0 vram_leer 0}

# los siete tramos; el 7 es todo lo que pasa fuera del gancho
array set ::ZONA {
    1 "1 gancho: entrada y mandos  4037-4098"
    2 "2 gancho: ciclo de seis     4098-40AC"
    3 "3 gancho: los choques       40AC-40CA"
    4 "4 gancho: sube los sprites  40CA-40D5"
    5 "5 gancho: parpadeo y sonido 40D5-40F0"
    6 "6 gancho: contadores        40F0-4112"
    7 "7 el programa principal"
}

# callbacks BARATOS: solo un dict incr; el formateo, al final
proc cb98 {} { if {$::mide} { dict incr ::pc98 [expr {[reg PC] | ($::zona << 24)}] } }
proc cb99 {} { if {$::mide} { dict incr ::pc99 [expr {[reg PC] | ($::zona << 24)}] } }
proc tic38 {} { if {$::mide} { incr ::n38 } }
# El segundo byte que va al 0x99 sale de D (PON_DIRECCION_VDP, 0x401A-0x401B) y
# dice para que era: bit 7 = escribir un REGISTRO, bit 6 = preparar la VRAM para
# escribir, ninguno = prepararla para leer.
proc clasifica99 {} {
    if {!$::mide} return
    set d [expr {([reg DE] >> 8) & 0xC0}]
    if {$d & 0x80} { incr ::d99(registro) } elseif {$d & 0x40} { incr ::d99(vram_escribir) } else { incr ::d99(vram_leer) }
}
proc vuelta {} { if {$::mide} { incr ::vueltas } }

debug set_watchpoint write_io 0x98 {} { cb98 }
debug set_watchpoint write_io 0x99 {} { cb99 }
foreach {a z} {0x4037 1 0x4098 2 0x40AC 3 0x40CA 4 0x40D5 5 0x40F0 6 0x4112 7} {
    debug set_bp $a {} "set ::zona $z"
}
debug set_bp 0x0038 {} { tic38 }
debug set_bp 0x4796 {} { vuelta }
debug set_bp 0x401B {} { clasifica99 }

proc arranca {} {
    set ::t0 [machine_info time]
    set ::f0 [machine_info VDP_frame_count]
    set ::foto0 [foto]
    set ::mide 1
    if {$::PILOTO} { piloto_arranca }
    after time $::VENTANA informe
}

proc vuelca {f titulo d fot} {
    puts $f ""
    puts $f "# $titulo"
    puts $f [format "%-38s %-7s %10s %13s" tramo PC escrituras por_fotograma]
    foreach k [lsort -integer [dict keys $d]] {
        set n [dict get $d $k]
        puts $f [format "%-38s 0x%04X  %10d %13.2f" $::ZONA([expr {$k >> 24}]) \
            [expr {$k & 0xFFFF}] $n [expr {double($n) / $fot}]]
    }
}

proc resumen {f titulo d fot} {
    array set z {}
    set tot 0
    foreach k [dict keys $d] {
        set n [dict get $d $k] ; set i [expr {$k >> 24}]
        if {![info exists z($i)]} { set z($i) 0 }
        incr z($i) $n ; incr tot $n
    }
    puts $f ""
    puts $f "# $titulo"
    foreach i [lsort -integer [array names z]] {
        puts $f [format "%-38s %10d %13.2f" $::ZONA($i) $z($i) [expr {double($z($i)) / $fot}]]
    }
    puts $f [format "%-38s %10d %13.2f" TOTAL $tot [expr {double($tot) / $fot}]]
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
    puts $f "ventana_emulada_s  [format %.6f $ven]"
    puts $f "fotogramas_VDP     $fot"
    puts $f "pasadas_0x0038     $::n38"
    puts $f "vueltas_bucle_ppal $::vueltas   ([format %.2f [expr {double($::vueltas) / $fot}]] por fotograma)"
    puts $f ""
    puts $f "# PARA QUE ERA CADA PAREJA DEL 0x99 (el byte alto, leido de D en 0x401B)"
    foreach k {registro vram_escribir vram_leer} {
        puts $f [format "%-38s %10d %13.2f" $k $::d99($k) [expr {double($::d99($k)) / $fot}]]
    }
    resumen $f "PUERTO 0x98 (datos) POR TRAMO" $::pc98 $fot
    resumen $f "PUERTO 0x99 (direccion/registros) POR TRAMO" $::pc99 $fot
    vuelca  $f "PUERTO 0x98 (datos), tramo y PC" $::pc98 $fot
    vuelca  $f "PUERTO 0x99 (direccion/registros), tramo y PC" $::pc99 $fot
    close $f
    exit
}

set throttle off
perro_guardian 180
al_estado
