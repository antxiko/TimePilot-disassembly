# omsx_control.tcl - El CONTROL de toda medida: comprueba que el latido del
# cuadro se ve desde el depurador antes de fiarse de ningun otro contador.
#
# Cuenta las pasadas por 0x0038 (el vector de interrupcion de la BIOS) en
# tramos de 2 s de tiempo EMULADO, para ver el arranque de la maquina y a
# partir de que momento el ritmo es estable. Vuelca a work/omsx/control.txt.
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart timepilot.rom -script tools/omsx_control.tcl
#
# Si esto sale a cero, la instrumentacion esta rota; no es un hallazgo.

set ::SALIDA "C:/Users/Antxiko/Documents/DES_ASM/TIMEPILOT_DISAM/work/omsx/control.txt"
set ::TRAMOS 15
set ::PASO 2.0

set ::n38 0
proc tic38 {} { incr ::n38 }
debug set_bp 0x0038 {} { tic38 }

set ::lineas {}
set ::previo 0
set ::i 0

proc tramo {} {
    set t [machine_info time]
    set d [expr {$::n38 - $::previo}]
    set ::previo $::n38
    lappend ::lineas [format "t=%6.2f  en_el_tramo=%4d  por_s=%7.3f  E014=%d E015=%d" \
        $t $d [expr {$d / $::PASO}] \
        [debug read memory 0xE014] [debug read memory 0xE015]]
    incr ::i
    if {$::i >= $::TRAMOS} { informe } else { after time $::PASO tramo }
}

proc informe {} {
    set f [open $::SALIDA w]
    foreach l $::lineas { puts $f $l }
    puts $f "total_0x0038 $::n38"
    puts $f "E01F_ciclo [debug read memory 0xE01F]"
    close $f
    exit
}

set throttle off
after time $::PASO tramo
