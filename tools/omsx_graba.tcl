# Arranca el juego grabando la partida, para poder medir sobre ella despues.
#
# Por que grabar en vez de medir en vivo: una partida jugada por una persona
# llega a sitios a los que la demo no llega nunca, y ademas se puede repetir
# tantas veces como haga falta. Con `reverse loadreplay` + `reverse goto` se
# vuelve a cualquier instante y se muestrea alli, sin tener que volver a jugar.
#
# Cuatro cosas que hay que hacer bien, y que cuestan una tarde si se olvidan:
#
#   1. Lanzado con -script, openMSX arranca con el renderer SIN INICIALIZAR, y
#      entonces `screenshot` contesta que ha ido bien y escribe un PNG NEGRO.
#      Por eso lo primero es encenderlo.
#   2. El acelerador se queda PUESTO. Sin el, la maquina corre a toda pastilla
#      y ademas el renderer se salta cuadros.
#   3. La historia de `reverse` vive en memoria: si openMSX se cierra sin
#      guardar, no queda nada. De ahi el guardado automatico de aqui abajo.
#   4. Y HACE FALTA `after quit`. Sin el, todo lo jugado desde el ultimo
#      guardado automatico se pierde al cerrar la ventana. Pasado el
#      2026-08-20: se perdio una partida entera por esto.
#
# Uso:  openmsx -machine Philips_VG_8020 -cart timepilot.rom \
#               -script tools/omsx_graba.tcl

set ::destino [file normalize "work/replays"]
file mkdir $::destino

set renderer SDLGL-PP
set throttle on

# El joystick de teclado, para que la opcion 1 del menu valga con los cursores
# y la barra.
catch { plug joyporta keyjoystick1 }

# La grabacion. `reverse start` empieza a guardar historia; el fichero se
# escribe con savereplay cada medio minuto y al cerrar.
reverse start

# Una senal en disco de que esto esta de verdad en marcha, para no tener que
# fiarse de la salida por pantalla.
proc apunta_estado {{motivo arranque}} {
    set f [open [file join $::destino "estado.txt"] w]
    puts $f "reverse: [dict get [reverse status] status]"
    puts $f "machine: [machine_info config_name]"
    puts $f "tiempo emulado: [machine_info time]"
    puts $f "ultimo guardado: $motivo"
    close $f
}
apunta_estado

# El cartel, para que se vea en la ventana que se esta grabando.
osd create rectangle grabando -x 0 -y 0 -w 90 -h 14 -rgba 0xc00000c0 -scaled true
osd create text grabando.txt -x 5 -y 3 -size 7 -rgba 0xffffffff \
    -text "GRABANDO" -scaled true

# El guardado. Cada medio minuto de tiempo REAL, no emulado: lo que interesa es
# no perder lo que la persona lleva jugado. Si el guardado con instantaneas
# extra falla, se intenta el simple antes de darse por vencido.
proc salva {motivo} {
    set fichero [file join $::destino "partida"]
    if {[catch {reverse savereplay -maxnofextrasnapshots 40 $fichero} err]} {
        if {[catch {reverse savereplay $fichero} err2]} {
            set f [open [file join $::destino "fallo.txt"] a]
            puts $f "$motivo: $err / $err2"
            close $f
            return
        }
    }
    apunta_estado $motivo
}
proc autoguarda {} { salva minuto; after realtime 30 autoguarda }
after realtime 30 autoguarda

# Y AL CERRAR LA VENTANA, que es lo que faltaba.
after quit { salva cierre }

# Una captura de pantalla a los quince segundos reales, que es de sobra para
# que el juego haya pasado del logotipo. Con el renderer encendido y el
# acelerador puesto sale entera; si saliera negra, pesaria ~1 KB.
after realtime 15 {
    screenshot -raw [file join $::destino "pantalla.png"]
}
