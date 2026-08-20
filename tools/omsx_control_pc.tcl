# Control independiente del coste de la interrupcion.
#
# EL ERROR QUE HAY QUE NO REPETIR: contar las muestras del PC que caen entre
# 0x4037 y 0x4117 NO mide la interrupcion. El gancho LLAMA a rutinas repartidas
# por todo el cartucho (0x5xxx y 0x6xxx), asi que el PC casi nunca esta dentro
# de ese rango aunque se este ejecutando la interrupcion. Asi salio un 1,20 %
# contra el 50 % del cronometro, y el que estaba mal era el control.
#
# Lo que si vale: una bandera que enciende el punto de ruptura de la entrada y
# apaga el de la salida, y muestrear ESA bandera. Es independiente de la
# aritmetica de tiempos del otro metodo, que es justo lo que se quiere validar.
#
# Uso:  openmsx -script tools/omsx_control_pc.tcl
set ::destino [file normalize "work/replays"]
set renderer none
set throttle off
reverse loadreplay -viewonly [file join $::destino "partida.omr"]
reverse goto 30

set ::en_interrupcion 0
set ::n 0 ; set ::dentro 0 ; set ::rango 0
set ::minimo 1.0 ; set ::maximo 0.0 ; set ::t_ent 0

debug set_bp 0x4037 {} { set ::en_interrupcion 1 ; set ::t_ent [machine_info time] }
debug set_bp 0x4117 {} {
    set ::en_interrupcion 0
    set d [expr {[machine_info time] - $::t_ent}]
    if {$d < $::minimo} { set ::minimo $d }
    if {$d > $::maximo} { set ::maximo $d }
}

proc muestrea {} {
    incr ::n
    if {$::en_interrupcion} { incr ::dentro }
    set pc [reg PC]
    if {$pc >= 0x4037 && $pc <= 0x4117} { incr ::rango }
    after time 0.001 muestrea
}
muestrea
after time 60 {
    set f [open [file join $::destino "control_pc.txt"] w]
    puts $f "muestras del PC cada 1 ms de tiempo emulado, 60 s de partida (t=30 a t=90)"
    puts $f "  muestras                                  $::n"
    puts $f "  con la interrupcion en marcha             $::dentro   ([format %.2f [expr {100.0*$::dentro/$::n}]] %)"
    puts $f "  con el PC dentro de 0x4037-0x4117         $::rango   ([format %.2f [expr {100.0*$::rango/$::n}]] %)"
    puts $f "    (esta segunda cifra NO es el coste: el gancho llama a rutinas de fuera)"
    puts $f "  la interrupcion mas corta                 [format %.3f [expr {1000.0*$::minimo}]] ms"
    puts $f "  la mas larga                              [format %.3f [expr {1000.0*$::maximo}]] ms"
    close $f
    exit
}
