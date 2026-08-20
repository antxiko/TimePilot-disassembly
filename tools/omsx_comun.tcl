# omsx_comun.tcl - Lo que comparten todas las medidas de openMSX de Time Pilot.
# No se lanza solo: lo cargan con `source` los omsx_*.tcl.
#
# Da cuatro cosas:
#   opcion            variables de entorno con valor por defecto
#   espera/pulsa      llevar el juego al estado que se quiere medir (demo o
#                     partida) antes de abrir la ventana de medida
#   piloto            un piloto sintetico para la partida: barre las ocho
#                     direcciones en circulo y va soltando el boton, que es lo
#                     que mantiene vivo al jugador. Hace falta soltar porque
#                     0x54E8 solo deja cuatro disparos seguidos (cuenta en
#                     0xE140, rearmada al soltar en 0x54F2)
#   perro_guardian    a los N segundos de reloj REAL se vuelca lo que haya y se
#                     sale; un script roto no puede dejar openMSX colgado
#
# El fichero de medida tiene que definir `informe`, `::SALIDA` y poner
# `::t0`/`::f0` al abrir la ventana.

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

# --- la fila 8 del teclado: cursores y barra (LEE_TECLAS_DE_DIRECCION, 0x4A4C)
set ::TECLA_FUEGO 0x01
set ::TECLA_IZQ   0x10
set ::TECLA_ARR   0x20
set ::TECLA_ABA   0x40
set ::TECLA_DER   0x80
# las ocho direcciones en circulo, empezando arriba y girando a la derecha
set ::CIRCULO {0x20 0xA0 0x80 0xC0 0x40 0x50 0x10 0x30}
set ::MASCARA_DIRS 0xF0

# --- foto del estado del juego, para demostrar que se midio lo que se dice
proc foto {} {
    set p ""
    foreach a {0xE00B 0xE00C 0xE00D} { append p [format %02X [debug read memory $a]] }
    return [list vidas [debug read memory 0xE002] puntos $p \
                 quedan [debug read memory 0xE120] demo [debug read memory 0xE014] \
                 fase [debug read memory 0xE015] muerto [debug read memory 0xE050] \
                 fin [debug read memory 0xE052]]
}

# --- llevar el juego al estado pedido -----------------------------------
# MODO demo: se deja que la atraccion arranque sola (E014=1, E015=1)
# MODO partida: se pulsa la 3 del menu (fila 0, mascara 0x08: un jugador con
#   teclado, 0x438E-0x43B4) y se espera a E014=0 y E015=1
proc espera {} {
    set demo [debug read memory 0xE014]
    set fase [debug read memory 0xE015]
    if {$::MODO eq "partida"} {
        if {$demo == 0 && $fase == 1} { arranca ; return }
    } else {
        if {$demo == 1 && $fase == 1} { arranca ; return }
    }
    if {[machine_info time] > 90.0} {
        set f [open $::SALIDA w]
        puts $f "FALLO: a los 90 s emulados no se llego al estado '$::MODO' (E014=$demo E015=$fase)"
        close $f
        exit
    }
    after time 0.25 espera
}
proc pulsa_menu {}  { keymatrixdown 0 0x08 ; after time 0.4 suelta_menu }
proc suelta_menu {} { keymatrixup 0 0x08 ; espera }

proc al_estado {} {
    if {$::MODO eq "partida"} { after time 8.0 pulsa_menu } else { after time 8.0 espera }
}

# --- el piloto sintetico -------------------------------------------------
set ::piloto_i 0
proc piloto_gira {} {
    if {!$::mide} { keymatrixup 8 $::MASCARA_DIRS ; return }
    keymatrixup 8 $::MASCARA_DIRS
    keymatrixdown 8 [lindex $::CIRCULO $::piloto_i]
    set ::piloto_i [expr {($::piloto_i + 1) % 8}]
    after time 0.08 piloto_gira
}
proc piloto_dispara {} {
    if {!$::mide} { keymatrixup 8 $::TECLA_FUEGO ; return }
    keymatrixdown 8 $::TECLA_FUEGO
    after time 0.04 piloto_suelta
}
proc piloto_suelta {} {
    keymatrixup 8 $::TECLA_FUEGO
    if {$::mide} { after time 0.04 piloto_dispara }
}
proc piloto_arranca {} { piloto_gira ; piloto_dispara }

# --- perro guardian ------------------------------------------------------
proc perro_guardian {segundos} {
    after realtime $segundos {
        if {![info exists ::f0]} { set ::f0 [machine_info VDP_frame_count] ; set ::t0 [machine_info time] }
        catch {informe} e
        catch { set f [open "$::SALIDA.error" w] ; puts $f "PERRO GUARDIAN: $e" ; close $f }
        exit
    }
}
