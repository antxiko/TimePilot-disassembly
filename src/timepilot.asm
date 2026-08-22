; ==========================================================================
; TIME PILOT - Konami - MSX1 - cartucho RC-703 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: La cabecera que lee la BIOS: "AB", INIT=0x4203
;   y a cero STATEMENT, DEVICE y TEXT. Con la cabecera en 0x4000 la BIOS mapea
;   el cartucho en la PAGINA 1 y salta a INIT al acabar de arrancar
;   0x4000..0x4012  (18 bytes)
DATA_cabecera_del_cartucho:
	defb 041h,042h	; 4000
	defw 04203h,00000h,00000h,00000h	; 4002  -> INIT 0x0000 0x0000 0x0000
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 400a  ........

; ======================================================================
; CODIGO 0x4012..0x4118  (262 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS RUTINAS DE SERVICIO. Lo que usa todo el cartucho: sumar a HL, poner la direccion del VDP y volcar o rellenar por el puerto de datos.
; ----------------------------------------------------------------------
SUMA_A_HL:		; HL = HL + A, con el acarreo puesto en H
	add a,l			;4012   ; HL = HL + A, arrastrando el acarreo a H
	ld l,a			;4013
	ret nc			;4014
	inc h			;4015
	ret			;4016
PON_DIRECCION_VDP:		; Manda DE por el puerto 0x99: la direccion de VRAM y el modo (bit 14 puesto = escribir)
	ld a,e			;4017
	out (099h),a		;4018   ; el puerto 0x99 es el de la direccion y los registros del VDP
	ld a,d			;401a
	out (099h),a		;401b   ; con el bit 14 puesto en D, el VDP se prepara para ESCRIBIR
	ret			;401d
COPIA_A_VRAM:		; Pone la direccion DE y sube B bytes desde (HL)
	call PON_DIRECCION_VDP		;401e   ; copiar B bytes a la VRAM: se pone la direccion una vez y luego solo datos
COPIA_A_VRAM_YA:		; El bucle, con la direccion ya puesta
	ld a,(hl)			;4021
	out (098h),a		;4022   ; y el 0x98 es el de los datos
	inc hl			;4024
	djnz COPIA_A_VRAM_YA		;4025
	ret			;4027
RELLENA_VRAM:		; Pone la direccion DE y escribe B veces el byte C
	call PON_DIRECCION_VDP		;4028   ; y rellenar es lo mismo con el byte siempre igual
RELLENA_VRAM_YA:		; Con la direccion ya puesta; el byte va en C
	ld a,c			;402b
RELLENA_VRAM_CON_A:		; Igual, pero el byte ya esta en A
	out (098h),a		;402c
	nop			;402e   ; el nop es para darle tiempo al VDP entre escritura y escritura
	djnz RELLENA_VRAM_CON_A		;402f
	ret			;4031
LEE_JUGADOR:		; Deja en A el jugador que esta jugando (0xE001) y pone Z si es el primero
	ld a,(0e001h)		;4032   ; 0xE001 dice cual de los dos jugadores esta jugando
	or a			;4035
	ret			;4036
INTERRUPCION:		; El gancho H.KEYI. Mueve todo lo que se ve, un paso por fotograma
	push hl			;4037   ; la interrupcion guarda los cuatro pares que va a tocar
	push de			;4038
	push bc			;4039
	push af			;403a
	in a,(099h)		;403b   ; leer el estado del VDP baja la peticion de interrupcion
INTERRUPCION_PASO:
	ld a,(0e050h)		;403d   ; 0xE050 se pone cuando el jugador se ha estrellado
	or a			;4040
	jp nz,INTERRUPCION_SPRITES		;4041
	ld hl,0e015h		;4044   ; 0xE015 dice si hay una fase en marcha
	xor a			;4047
	cp (hl)			;4048
	jp z,INTERRUPCION_CONTADORES		;4049
	dec hl			;404c
	cp (hl)			;404d
	jr nz,INTERRUPCION_SIN_MANDO		;404e
	ld a,(0e007h)		;4050   ; 0xE007: con joystick se lee por el PSG, con teclado por la matriz
	or a			;4053
	jr z,INTERRUPCION_LEE_MANDOS		;4054
	call LEE_JUGADOR		;4056   ; con joystick se lee por el registro 15 del PSG
	ld a,00fh		;4059
	out (0a0h),a		;405b   ; registro 15 del PSG: la seleccion de los puertos de mando
	ld a,08fh		;405d
	jr z,INTERRUPCION_TECLADO_PSG		;405f
	ld a,0cfh		;4061   ; el 0xCF elige el segundo puerto de mando
INTERRUPCION_TECLADO_PSG:
	out (0a1h),a		;4063
	call LEE_JOYSTICK		;4065
	jr INTERRUPCION_GUARDA_MANDO		;4068
INTERRUPCION_LEE_MANDOS:
	call LEE_TECLAS_DE_DIRECCION		;406a   ; sin joystick, los cursores y la barra de la fila 8 del teclado
	ld b,a			;406d   ; lo leido del teclado se junta con lo del joystick en B
	ld a,c			;406e
	rrca			;406f
	jr nc,INTERRUPCION_MIRA_DISPARO		;4070
	ld a,0efh		;4072
	and b			;4074
	ld b,a			;4075
INTERRUPCION_MIRA_DISPARO:
	ld a,007h		;4076   ; la fila 7 del teclado: el bit 6 es la barra espaciadora
	call LEE_FILA_DEL_TECLADO		;4078
	bit 6,a		;407b
	jr nz,INTERRUPCION_MANDO_LISTO		;407d
	ld a,0dfh		;407f   ; y se apaga el bit 5, que es el segundo boton
	and b			;4081
	ld b,a			;4082
INTERRUPCION_MANDO_LISTO:
	ld a,b			;4083
	jr INTERRUPCION_GUARDA_MANDO		;4084
INTERRUPCION_SIN_MANDO:
	ld a,0ffh		;4086   ; el `cpl` endereza la logica negativa del hardware
INTERRUPCION_GUARDA_MANDO:
	cpl			;4088
	and 03fh		;4089   ; solo interesan seis bits: cuatro direcciones y dos disparos
	ld hl,0e008h		;408b   ; 0xE008 guarda lo de antes y 0xE009 lo de ahora
	cp (hl)			;408e   ; si el mando no ha cambiado se guarda en 0xE009 y no en 0xE008: asi se sabe si hay flanco
	jr z,INTERRUPCION_MANDO_REPETIDO		;408f
	ld (hl),a			;4091
	jr INTERRUPCION_FASE		;4092
INTERRUPCION_MANDO_REPETIDO:
	ld hl,0e009h		;4094
	ld (hl),a			;4097
INTERRUPCION_FASE:
	ld hl,0e01fh		;4098   ; 0xE01F cuenta de 0 a 5: el ciclo de reparto de la interrupcion
	ld a,(hl)			;409b
	inc a			;409c
	cp 006h		;409d
	jr nz,INTERRUPCION_DESPACHA		;409f
	xor a			;40a1
INTERRUPCION_DESPACHA:		; Reparte el trabajo entre los seis fotogramas del ciclo
	ld (hl),a			;40a2   ; seis entradas, una por fotograma del ciclo
	ld hl,04118h		;40a3   ; seis entradas, una por fotograma del ciclo
	call LEE_PALABRA_DE_TABLA		;40a6
	call SALTA_A_HL_2		;40a9
	ld a,(0e145h)		;40ac   ; 0xE145 con algo en los tres bits altos: la fase esta en una transicion y no se miran choques
	and 0e0h		;40af
	jr nz,INTERRUPCION_SPRITES		;40b1
	ld hl,0e22fh		;40b3
	xor a			;40b6
	cp (hl)			;40b7
	ld (hl),a			;40b8
	jr nz,INTERRUPCION_SPRITES		;40b9
	call MIRA_LOS_CHOQUES		;40bb   ; cinco tandas de choques, cada una con su lista
	call CHOQUE_CON_EL_PASAJERO		;40be
	call CHOQUE_DEL_JUGADOR		;40c1
	call CHOQUE_CON_LOS_AVIONES		;40c4
	call CHOQUE_CON_LOS_DISPAROS_ENEMIGOS		;40c7
INTERRUPCION_SPRITES:		; Sube los 0x60 bytes de 0xE380 a la tabla de atributos de sprite
	ld hl,0e380h		;40ca   ; la tabla de sprites se sube entera de RAM a VRAM cada fotograma
	ld de,07b00h		;40cd   ; 0x7B00 es la tabla de atributos de sprites, y son 0x60 bytes: 24 sprites
	ld b,060h		;40d0
	call COPIA_A_VRAM		;40d2
	ld a,(0e014h)		;40d5   ; 0xE014 dice si esta corriendo la demo
	or a			;40d8
	jr nz,INTERRUPCION_CONTADORES		;40d9
	call PARPADEA_EL_JUGADOR		;40db
	ld hl,0e021h		;40de
	call PASO_DE_CANAL		;40e1   ; los tres canales de sonido, uno detras de otro
	ld hl,0e029h		;40e4
	call PASO_DE_CANAL		;40e7
	ld hl,0e031h		;40ea
	call PASO_DE_CANAL		;40ed
INTERRUPCION_CONTADORES:		; Sube el contador de fotogramas y baja las cuentas atras
	ld hl,0e019h		;40f0
	inc (hl)			;40f3   ; 0xE019 es el contador de fotogramas del que tira todo el juego, y SUBE
	ld a,(hl)			;40f4
	and 01fh		;40f5   ; lo de abajo solo pasa un fotograma de cada 32
	jr nz,INTERRUPCION_SALIDA		;40f7
	push hl			;40f9
	ld hl,0e130h		;40fa   ; la cuenta de cuando toca soltar enemigos: a cero, se recarga con 40
	dec (hl)			;40fd
	jr nz,INTERRUPCION_CUENTA		;40fe
	ld (hl),028h		;4100   ; cuarenta cuadros entre tanda y tanda de enemigos
	inc hl			;4102
	ld (hl),001h		;4103
INTERRUPCION_CUENTA:
	pop hl			;4105
	dec hl			;4106   ; y aqui baja 0xE018, la espera que piden las rutinas: un punto por cada 32 cuadros
	cp (hl)			;4107
	jr z,INTERRUPCION_SALIDA		;4108
	dec (hl)			;410a
INTERRUPCION_SALIDA:		; Si ha llegado otra interrupcion mientras tanto, da otro paso antes de salir
	in a,(099h)		;410b   ; si mientras tanto ha entrado otra interrupcion, se da otro paso sin salir
	bit 7,a		;410d
	jp nz,INTERRUPCION_PASO		;410f   ; y si la hay, se da otro paso sin salir: asi no se pierden fotogramas cuando el juego se atraganta
	pop af			;4112   ; los mismos cuatro pares que se metieron al entrar
	pop bc			;4113
	pop de			;4114
	pop hl			;4115
	ei			;4116
	ret			;4117

; ----------------------------------------------------------------------
; DATOS reparto_de_la_interrupcion: Las seis entradas del despachador de
;   0x40A3: que le toca hacer a la interrupcion en cada uno de los seis
;   fotogramas del ciclo (0xE01F). Las fases 1, 3 y 5 repiten la misma rutina,
;   asi que lo que se hace tres veces de cada seis es mover a los enemigos
;   0x4118..0x4124  (12 bytes)
DATA_reparto_de_la_interrupcion:
	defw 04124h	; 4118  -> FOTOGRAMA_0
	defw 04134h	; 411a  -> FOTOGRAMA_IMPAR
	defw 04147h	; 411c  -> FOTOGRAMA_2
	defw 04134h	; 411e  -> FOTOGRAMA_IMPAR
	defw 04151h	; 4120  -> FOTOGRAMA_4
	defw 04134h	; 4122  -> FOTOGRAMA_IMPAR

; ======================================================================
; CODIGO 0x4124..0x415f  (59 bytes)
; ======================================================================


FOTOGRAMA_0:		; Disparos, nubes, el avion del jugador y los choques
	call PASO_DE_LOS_ACTORES		;4124   ; fotograma 0 del ciclo: los disparos, las nubes y el avion
	call MUEVE_LOS_DISPAROS		;4127
	call PASO_DEL_JUGADOR		;412a
	call DISPARA		;412d   ; disparar y soltar bombas van juntos, en el mismo fotograma del ciclo
	call SUELTA_LAS_BOMBAS		;4130
	ret			;4133
FOTOGRAMA_IMPAR:		; Lo que se hace tres fotogramas de cada seis: los enemigos
	call PASO_DE_LOS_ACTORES		;4134   ; fotogramas 1, 3 y 5: los enemigos, tres veces de cada seis
	call PASO_DE_LOS_ACTORES_2		;4137   ; los enemigos se atienden en tres de los seis fotogramas: son lo que mas cuesta
	call PASO_DEL_PASAJERO		;413a
	call PASO_DE_LAS_BOMBAS		;413d
	call PASO_DE_LOS_MISILES		;4140
	call PASO_DE_LOS_DISPAROS_ENEMIGOS		;4143
	ret			;4146
FOTOGRAMA_2:		; El desplazamiento del fondo
	call PASO_DE_LOS_ACTORES		;4147   ; fotograma 2: el fondo que se desplaza
	call PASO_DEL_FONDO		;414a
	call SUELTA_DOS_MISILES_DE_ABAJO		;414d   ; los misiles de abajo salen en el fotograma del fondo
	ret			;4150
FOTOGRAMA_4:
	call PASO_DE_LOS_ACTORES		;4151   ; fotograma 4: el bicho grande y la cuenta de la fase
	call PASO_DEL_BICHO_GRANDE		;4154
	call PASO_DE_LOS_DISPAROS_ENEMIGOS		;4157
	call PASO_DE_LA_FASE		;415a   ; y la cuenta de la fase, en el ultimo del ciclo
	ret			;415d
SALTA_A_HL_2:		; Un `jp (hl)` suelto que hace de "call (hl)": el despachador de 0x40A3 entra aqui
	jp (hl)			;415e   ; `jp (hl)` pelado: es el salto de la tabla de arriba

; ----------------------------------------------------------------------
; DATOS relleno_ret: Un `ret` suelto detras del `jp (hl)` de 0x415E, al que no
;   llega nadie
;   0x415f..0x4160  (1 bytes)
DATA_relleno_ret:
	defb 0c9h	; 415f

; ======================================================================
; CODIGO 0x4160..0x4c91  (2865 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL REPRODUCTOR DE SONIDO. Un canal por llamada, con la ficha de 8 bytes en HL-1. El programa se guarda en el propio cartucho como una tira de notas de tres bytes: periodo bajo, periodo alto con el volumen en el nibble de arriba y el bit 3 para el ruido, y duracion. Con la duracion negativa la nota se va apagando sola.
; ----------------------------------------------------------------------
PASO_DE_CANAL:		; Un paso del canal cuya ficha empieza en HL-1
	ld a,(hl)			;4160   ; con el byte de arriba del puntero a cero, el canal esta callado
	or a			;4161
	ret z			;4162
	dec hl			;4163   ; los dos primeros bytes de la ficha son el puntero al programa
	ld e,(hl)			;4164   ; los dos primeros bytes de la ficha son el puntero al programa
	inc hl			;4165
	ld d,(hl)			;4166
	ld c,0a1h		;4167
	inc hl			;4169
	ld a,(hl)			;416a   ; el tercero es lo que le queda a la nota; con el bit 7, ademas, se apaga sola
	and 07fh		;416b   ; los siete bits de abajo son la duracion; el 7 es la marca de nota que se apaga sola
	jr z,CANAL_NOTA_NUEVA		;416d
	ld a,(hl)			;416f
	bit 7,a		;4170
	jr z,CANAL_SIGUE		;4172
	and 07fh		;4174
	inc hl			;4176   ; el escalon del apagado va en el byte 6 de la ficha
	inc hl			;4177
	inc hl			;4178
	dec (hl)			;4179   ; el escalon baja y se compara con lo que queda de nota
	cp (hl)			;417a
	jr z,CANAL_MIRA_ESCALON		;417b
	dec (hl)			;417d
CANAL_BAJA_VOLUMEN:		; Un escalon menos de volumen, y a esperar
	dec hl			;417e   ; un escalon menos de volumen
	dec (hl)			;417f
	ld a,(hl)			;4180   ; con el volumen a cero ya no hay nada que apagar
	or a			;4181
	ret z			;4182
	ld b,(hl)			;4183
	dec hl			;4184
	call ESCRIBE_VOLUMEN		;4185   ; y el volumen nuevo, al PSG
	dec hl			;4188
	set 7,(hl)		;4189   ; se vuelve a poner el bit 7 para seguir apagandose
	jr CANAL_SIGUE		;418b
CANAL_NOTA_NUEVA:		; Lee del programa la nota que toca
	ld a,(de)			;418d   ; 0xFF termina el programa
	cp 0ffh		;418e
	jr z,CANAL_FIN		;4190
	inc hl			;4192
	ld a,(hl)			;4193
	ld c,0a1h		;4194
	ex de,hl			;4196
	out (0a0h),a		;4197   ; registro 2n del PSG: el periodo fino del canal n
	outi		;4199   ; el `outi` manda el byte y avanza el puntero de una vez
	inc a			;419b
	out (0a0h),a		;419c   ; y el 2n+1: los cuatro bits altos del periodo
	ld a,(hl)			;419e
	and 007h		;419f   ; tres bits: el periodo del PSG son doce bits en dos registros
	out (c),a		;41a1
	bit 3,(hl)		;41a3   ; el bit 3 del segundo byte enciende el ruido
	jr z,CANAL_PON_VOLUMEN		;41a5
	ld a,007h		;41a7
	out (0a0h),a		;41a9   ; registro 7: la mezcla, con el ruido puesto en el canal C
	ld b,098h		;41ab   ; 0x98 en la mezcla: los tres tonos abiertos y el ruido solo en el canal C
	out (c),b		;41ad
	dec a			;41af
	out (0a0h),a		;41b0
	ld a,01fh		;41b2   ; y el registro 6 con 0x1F, el periodo de ruido mas lento
	out (c),a		;41b4
CANAL_PON_VOLUMEN:
	ex de,hl			;41b6
	ld a,(de)			;41b7
	and 0f0h		;41b8   ; el nibble alto del segundo byte es el volumen de arranque
	rrca			;41ba   ; cuatro rotaciones para bajar el nibble alto
	rrca			;41bb
	rrca			;41bc
	rrca			;41bd
	ld b,a			;41be
	call ESCRIBE_VOLUMEN		;41bf
	inc de			;41c2
	inc hl			;41c3
	ld (hl),b			;41c4   ; el volumen de arranque se guarda en la ficha para poder ir bajandolo
	dec hl			;41c5
	dec hl			;41c6
	ld a,(de)			;41c7   ; el tercer byte es la duracion de la nota
	ld (hl),a			;41c8
	bit 7,a		;41c9   ; con el bit 7 en la duracion, la nota se va apagando sola
	jr z,CANAL_GUARDA_PUNTERO		;41cb
	and 07fh		;41cd
	inc hl			;41cf
	inc hl			;41d0
	inc hl			;41d1
	add a,003h		;41d2   ; tres pasos mas de los que dure la nota
	ld (hl),a			;41d4
	dec hl			;41d5
	dec hl			;41d6
	dec hl			;41d7
CANAL_GUARDA_PUNTERO:
	inc de			;41d8   ; y el puntero avanza a la nota siguiente
	dec hl			;41d9
	ld (hl),d			;41da   ; el puntero nuevo se guarda en los dos primeros bytes de la ficha
	dec hl			;41db
	ld (hl),e			;41dc
	inc hl			;41dd
	inc hl			;41de
CANAL_SIGUE:
	dec (hl)			;41df
	ret			;41e0
CANAL_FIN:		; Se acabo el programa: se calla el canal y se enciende el ruido
	inc a			;41e1   ; se acabo el programa: el puntero se deja apuntando al 0xFF
	dec hl			;41e2
	ld (hl),a			;41e3
	inc hl			;41e4
	inc hl			;41e5
	ld a,007h		;41e6   ; al acabar el programa, la mezcla vuelve a dejar el ruido suelto
	out (0a0h),a		;41e8
	ld a,0b8h		;41ea
	out (0a1h),a		;41ec
	ld b,000h		;41ee
ESCRIBE_VOLUMEN:		; Registro 8+canal del PSG = B
	ld a,(hl)			;41f0   ; el numero de canal sale de la propia direccion de la ficha
	rrca			;41f1   ; el `rrca` del byte bajo de la direccion: las fichas van de ocho en ocho, asi que el bit 3 se convierte en el numero de canal
	add a,008h		;41f2   ; registro 8+n del PSG: el volumen del canal n
	out (0a0h),a		;41f4
	out (c),b		;41f6
	ret			;41f8
CANAL_MIRA_ESCALON:
	ld a,(hl)			;41f9   ; el escalon del apagado no baja de 3
	cp 003h		;41fa   ; por debajo del escalon 3 ya no se baja mas
	jr c,CANAL_BAJA_VOLUMEN		;41fc
	dec hl			;41fe
	dec hl			;41ff
	dec hl			;4200
	jr CANAL_SIGUE		;4201

; ----------------------------------------------------------------------
; INIT. Lo llama la BIOS al arrancar, con el cartucho ya mapeado en la pagina 1. Engancha la interrupcion, borra la RAM, pone la pila, carga los caracteres y se mete en la pantalla de titulo.
; ----------------------------------------------------------------------
INIT:
	di			;4203
	ld a,0c3h		;4204   ; se escribe `jp 0x4037` en el gancho H.KEYI de la BIOS
	ld (0fd9ah),a		;4206
	ld hl,04037h		;4209
	ld (0fd9bh),hl		;420c
	ld hl,0e000h		;420f   ; la RAM del juego, de 0xE000 a 0xE7FE, a cero
	ld de,0e001h		;4212
	ld bc,007feh		;4215
	ld (hl),l			;4218   ; el `ld (hl),l` siembra un cero porque L vale 0: dos bytes en vez de tres
	ldir		;4219
	ld sp,hl			;421b   ; y la pila justo detras
	ld de,081a2h		;421c   ; antes que nada, el VDP apagado: registro 1 a 0xA2
	call PON_DIRECCION_VDP		;421f
	ld b,00fh		;4222   ; los quince registros del PSG, uno detras de otro
	call ESCRIBE_PSG		;4224   ; y el PSG callado del todo
	ld a,00fh		;4227
	out (0a0h),a		;4229   ; registro 15 del PSG: los puertos de mando como salida
	ld a,0cfh		;422b
	out (0a1h),a		;422d
	ld a,0f0h		;422f
	out (0aah),a		;4231   ; el puerto 0xAA es la fila del teclado que se va a leer
	ld hl,04d05h		;4233   ; los ocho registros del VDP, uno detras de otro desde el 0
	ld b,008h		;4236
	ld d,080h		;4238   ; D empieza en 0x80 y sube: el registro se escribe en el byte alto de la direccion del VDP
INIT_REGISTROS_VDP:
	ld e,(hl)			;423a
	call PON_DIRECCION_VDP		;423b
	inc hl			;423e
	inc d			;423f
	djnz INIT_REGISTROS_VDP		;4240
	im 1		;4242   ; modo 1 de interrupcion, que es el que usa la BIOS del MSX
PANTALLA_DE_TITULO:		; Borra la VRAM y monta la pantalla de titulo
	di			;4244
	ld de,04000h		;4245   ; la VRAM se borra entera, los 16 KB, de arriba abajo
	call PON_DIRECCION_VDP		;4248
BORRA_VRAM:
	ld b,e			;424b   ; B y C a cero: 256 vueltas por tanda, y D baja por cada pagina
	ld c,e			;424c
	call RELLENA_VRAM_YA		;424d
	dec d			;4250
	jr nz,BORRA_VRAM		;4251
	ld hl,06a85h		;4253   ; los caracteres del marco del marcador
	ld c,001h		;4256
	call CARGA_LISTA_DE_BLOQUES		;4258
	ld a,001h		;425b
	ld (0e00ah),a		;425d   ; 0xE00A a 1: las nubes del titulo se copian desplazadas dos bits
	ld hl,06af8h		;4260
	ld de,06110h		;4263
	ld b,00ah		;4266   ; diez caracteres girados: las nubes del titulo
	call PON_DIRECCION_VDP		;4268
	call SUBE_CARACTERES_GIRADOS		;426b
	xor a			;426e
	ld (0e00ah),a		;426f
	ld hl,07792h		;4272   ; los caracteres con los que estan escritos el titulo y el menu
	ld c,003h		;4275
	call CARGA_LISTA_DE_BLOQUES		;4277
	ld hl,0798bh		;427a   ; la fuente: 248 bytes, o sea 31 caracteres, en 0xDC-0xFA
	ld de,066e0h		;427d
	ld b,0f8h		;4280   ; 0xF8 bytes: 31 caracteres de ocho filas
	call COPIA_A_VRAM		;4282
	ld hl,0712bh		;4285   ; los patrones de sprite que valen para todas las epocas
	ld c,003h		;4288
	call CARGA_LISTA_DE_BLOQUES		;428a
	ld de,05ba0h		;428d   ; las dos primeras tiras de las nubes de la epoca 5, alternadas de ocho en ocho
	call PON_DIRECCION_VDP		;4290
	ld c,004h		;4293   ; cuatro parejas de tiras
	ld hl,06e86h		;4295
	ld de,06ea7h		;4298
COPIA_DOS_TIRAS:
	ld b,008h		;429b   ; las dos tiras de la epoca 5 se suben alternando de ocho en ocho bytes
	call COPIA_A_VRAM_YA		;429d
	ex de,hl			;42a0
	ld b,008h		;42a1
	call COPIA_A_VRAM_YA		;42a3
	ex de,hl			;42a6
	dec c			;42a7
	jr nz,COPIA_DOS_TIRAS		;42a8
	call APAGA_LOS_SPRITES		;42aa   ; los sprites se apagan antes de pintar nada
	ld hl,04d2fh		;42ad   ; el marco del marcador, con listas de (cuantos, caracter)
	ld de,EMPIEZA_EPOCA		;42b0
	call PON_DIRECCION_VDP		;42b3
	ld c,005h		;42b6   ; cinco tramos de marco, cada uno con su cuenta y su caracter
PINTA_MARCO:
	ld b,(hl)			;42b8
	inc hl			;42b9
	ld a,(hl)			;42ba
	call RELLENA_VRAM_CON_A		;42bb
	inc hl			;42be
	dec c			;42bf
	jr nz,PINTA_MARCO		;42c0
	ld de,00000h		;42c2
	ld hl,04800h		;42c5   ; y las tres partes de la pantalla cargadas iguales, para que un numero
	call COPIA_VRAM_A_VRAM		;42c8   ; la pantalla de arriba se copia a la de en medio y a la de abajo dentro de la propia VRAM
	ld de,02000h		;42cb   ; de caracter valga en cualquier fila
	ld hl,06800h		;42ce
	call COPIA_VRAM_A_VRAM		;42d1
	ld a,002h		;42d4   ; los canales 2 y 3 arrancan con prioridad 2 y 4
	ld (0e02bh),a		;42d6
	add a,a			;42d9   ; el `add a,a` deja 4 en el tercer canal: el 2 tiene prioridad sobre el 3
	ld (0e033h),a		;42da
	ei			;42dd
	ld hl,0e038h		;42de   ; si se venia del juego con una tecla ya pulsada, se salta al menu
	ld a,(hl)			;42e1
	ld (hl),000h		;42e2
	or a			;42e4
	jp nz,ELIGE_MODO		;42e5
	ld a,001h		;42e8
	call ESPERA		;42ea   ; un punto de espera con el titulo, o sea medio segundo largo
	ld de,07aebh		;42ed
TITULO_ESPERA:		; Espera un fotograma y mira si tocan una tecla
	ld hl,0e019h		;42f0
	ld a,(hl)			;42f3
	rrca			;42f4   ; el bit 0 del contador de fotogramas: el rotulo parpadea
	jr nc,TITULO_ESPERA		;42f5
	ld (hl),000h		;42f7
	di			;42f9   ; mientras se pinta el rotulo no puede entrar la interrupcion
	xor a			;42fa
	call LEE_FILA_DEL_TECLADO		;42fb
	ei			;42fe
	and 01eh		;42ff   ; cuatro bits: las teclas 1 a 4 de la fila 0
	cp 01eh		;4301   ; la fila 8 del teclado: si no hay ninguna tecla, seguir esperando
	jp nz,ELIGE_MODO		;4303
	ld hl,078cbh		;4306   ; cuando el rotulo llega al ultimo renglon, se pasa al menu
	or a			;4309
	sbc hl,de		;430a
	jr z,TITULO_MENU		;430c
	ld c,000h		;430e   ; y el renglon de antes se borra: el rotulo baja borrando su rastro
	ld b,00ch		;4310   ; 0x0C casillas: el ancho del rotulo
	di			;4312
	call RELLENA_VRAM		;4313
	ei			;4316
	ld hl,04e90h		;4317
	ld c,002h		;431a
TITULO_RESTA:
	push hl			;431c   ; cada renglon del rotulo se pinta tres veces, una por tercio
	ld hl,00020h		;431d   ; cada renglon se resta 32 casillas para bajar al tercio anterior
	or a			;4320
	ex de,hl			;4321
	sbc hl,de		;4322
	ex de,hl			;4324
	pop hl			;4325
	ld b,00ch		;4326   ; doce casillas por renglon
	di			;4328   ; el renglon se sube tres veces, y cada una a su tercio
	call COPIA_A_VRAM		;4329
	ei			;432c
	dec c			;432d
	jr nz,TITULO_RESTA		;432e
	push hl			;4330
	ld hl,00020h		;4331
	or a			;4334
	ex de,hl			;4335
	sbc hl,de		;4336
	ex de,hl			;4338
	pop hl			;4339
	ld b,003h		;433a   ; y el ultimo tercio solo lleva tres
	di			;433c
	call COPIA_A_VRAM		;433d
TITULO_SIGUIENTE_RENGLON:
	ei			;4340
	ld hl,00040h		;4341   ; y el siguiente renglon va dos filas mas abajo
	add hl,de			;4344
	ex de,hl			;4345
	jr TITULO_ESPERA		;4346
TITULO_MENU:		; El menu: uno o dos jugadores
	ld a,002h		;4348   ; al llegar abajo del todo se pasa al menu
	ld (0e018h),a		;434a   ; dos puntos con el menu en pantalla, o sea segundo y pico
TITULO_MENU_ESPERA:
	xor a			;434d
	di			;434e   ; la espera del menu se corta con cualquiera de las cuatro teclas
	call LEE_FILA_DEL_TECLADO		;434f
	ei			;4352
	and 01eh		;4353
	cp 01eh		;4355
	jp nz,ELIGE_MODO		;4357
	ld a,(0e018h)		;435a
	or a			;435d
	jr nz,TITULO_MENU_ESPERA		;435e
	di			;4360
	call PINTA_LA_PANTALLA_FIJA		;4361   ; los cinco rotulos fijos del menu
	ei			;4364
	ld a,008h		;4365
	ld (0e018h),a		;4367   ; y ocho puntos mas, unos cinco segundos, antes de que se aburra
TITULO_DEMO:		; Arranca la demo, que juega sola
	ld hl,0e014h		;436a
	ld a,001h		;436d
	ld (hl),a			;436f   ; la demo se marca en 0xE014, y se le da una vida
	ld (0e002h),a		;4370
	ld a,(0e018h)		;4373   ; y si nadie toca nada, arranca la demo
	or a			;4376
	jp z,EMPIEZA_PARTIDA		;4377
	xor a			;437a
	ld (0e021h),a		;437b   ; los tres canales de sonido callados antes de arrancar la demo
	ld (0e029h),a		;437e
	ld (0e031h),a		;4381
	ld (0e002h),a		;4384   ; al salir de la demo se apaga todo y se lee la tecla
	ld (hl),a			;4387
	xor a			;4388
	di			;4389
	call LEE_FILA_DEL_TECLADO		;438a
	ei			;438d
ELIGE_MODO:		; Con la tecla pulsada decide uno o dos jugadores, y con teclado o joystick
	push af			;438e   ; la tecla dice el modo: uno o dos jugadores, con joystick o con teclado
	ld a,001h		;438f
	ld (0e007h),a		;4391   ; 0xE007 a 1 quiere decir joystick
	pop af			;4394
	rrca			;4395   ; el bit 0 de la fila 0 es la tecla 1
	ld hl,04ee8h		;4396
	rrca			;4399
	jr nc,MODO_UN_JUGADOR		;439a
	ld hl,04f05h		;439c   ; la 2 son dos jugadores con joystick
	rrca			;439f
	jr nc,MODO_DOS_JUGADORES		;43a0
	ex af,af'			;43a2
	xor a			;43a3   ; las opciones 3 y 4 son con el teclado
	ld (0e007h),a		;43a4
	ex af,af'			;43a7
	ld hl,04f22h		;43a8
	rrca			;43ab
	jr nc,MODO_UN_JUGADOR		;43ac
	ld hl,04f3fh		;43ae
	rrca			;43b1
	jr nc,MODO_DOS_JUGADORES		;43b2
	jr TITULO_DEMO		;43b4   ; y si no era ninguna de las cuatro, vuelta a la demo
MODO_UN_JUGADOR:
	xor a			;43b6
	jr PREPARA_PARTIDA		;43b7
MODO_DOS_JUGADORES:
	ld a,001h		;43b9   ; 0xE000 a 1: dos jugadores
PREPARA_PARTIDA:
	ld (0e000h),a		;43bb
	push hl			;43be
	di			;43bf
	call PINTA_LA_PANTALLA_FIJA		;43c0   ; la pantalla fija se pinta antes de la cuenta atras
	ei			;43c3
	pop hl			;43c4
	ld de,00bf8h		;43c5   ; dos cuentas de golpe: 0xE019 a 0xF8 y 0xE01A a once
	ld (0e019h),de		;43c8   ; los dos bytes se escriben de una vez con un `ld (nn),de`
PINTA_ROTULOS_BUCLE:
	push hl			;43cc
ESPERA_FOTOGRAMA:
	ld hl,0e019h		;43cd
	ld a,(hl)			;43d0   ; aqui se espera a que la interrupcion de la vuelta al contador
	or a			;43d1
	jr nz,ESPERA_FOTOGRAMA		;43d2
	ld (hl),0f8h		;43d4   ; 0xE019 lo SUBE la interrupcion, asi que puesto a 0xF8 da la vuelta en ocho fotogramas
	inc hl			;43d6
	dec (hl)			;43d7   ; y 0xE01A va contando los once pasos de la presentacion
	ex de,hl			;43d8
	pop hl			;43d9
	jr z,MUSICA_DE_ARRANQUE		;43da
	inc de			;43dc
	ld a,(de)			;43dd
	push hl			;43de
	or a			;43df   ; un paso pinta y el siguiente borra, alternando
	jr nz,ROTULO_BORRA		;43e0
	inc a			;43e2
	ld (de),a			;43e3
	ld d,(hl)			;43e4   ; el destino de cada rotulo viene en la propia tabla, dos bytes
	inc hl			;43e5
	ld e,(hl)			;43e6
	ld bc,01a00h		;43e7   ; borrar es rellenar 0x1A casillas con el caracter 0
	di			;43ea
	call RELLENA_VRAM		;43eb
	ei			;43ee
	pop hl			;43ef
	jr PINTA_ROTULOS_BUCLE		;43f0
ROTULO_BORRA:
	xor a			;43f2   ; el paso siguiente vuelve a pintar, asi que se apunta que toca
	ld (de),a			;43f3
	di			;43f4
	call ESCRIBE_ROTULO		;43f5   ; y en el paso de pintar, el rotulo entero
	ei			;43f8
	pop hl			;43f9
	jr PINTA_ROTULOS_BUCLE		;43fa
MUSICA_DE_ARRANQUE:		; Los tres canales con los tres programas de 0x7A83, 0x7ADB y 0x7B33
	di			;43fc   ; los tres canales, con los tres programas de la musica de arranque
	ld hl,07a83h		;43fd   ; los tres canales, con los tres programas de la musica de arranque
	ld (0e020h),hl		;4400
	ld hl,07adbh		;4403   ; el canal 2, con el suyo
	ld (0e028h),hl		;4406
	ld hl,07b33h		;4409
	ld (0e030h),hl		;440c
	ld a,001h		;440f   ; los cuatro bytes de arranque de los canales, uno por ficha
	ld (0e03fh),a		;4411
	ld (0e027h),a		;4414
	ld (0e02fh),a		;4417
	ld (0e037h),a		;441a
	ld hl,00303h		;441d   ; los dos jugadores empiezan con tres vidas
	ld (0e002h),hl		;4420
	di			;4423
	call BORRA_LA_TABLA_DE_NOMBRES		;4424   ; la pantalla se borra antes de escribir el rotulo
	ld de,0792bh		;4427
	call PON_DIRECCION_VDP		;442a
	ld hl,04f5dh		;442d
	call ESCRIBE_ROTULO_BUCLE		;4430
	ei			;4433
	ld a,002h		;4434
	call ESPERA		;4436   ; dos puntos de espera con el rotulo puesto
EMPIEZA_PARTIDA:		; Vidas, epoca 1, ronda 1 y el marcador a cero
	ld a,065h		;4439   ; 0xE051 es la cuenta atras que lleva la fase
	ld (0e051h),a		;443b
	ld hl,00101h		;443e   ; dos vidas por jugador
	ld (0e180h),hl		;4441
	ld (0e182h),hl		;4444
	ld (0e005h),hl		;4447   ; la primera vida extra, a los 10000 puntos
	ld hl,00000h		;444a
	ld (0e040h),hl		;444d
	ld hl,0e110h		;4450   ; 0x18 bytes de estado del jugador a cero
	ld b,018h		;4453
BORRA_ESTADO_DEL_JUGADOR:
	xor a			;4455
	ld (hl),a			;4456
	inc hl			;4457
	djnz BORRA_ESTADO_DEL_JUGADOR		;4458
	ld a,019h		;445a
	ld (0e120h),a		;445c   ; 0x19 son VEINTICINCO: los enemigos que hay que derribar en la fase, y la misma cifra a la cuenta que se ensena
	ld (0e122h),a		;445f
	ld (0e042h),a		;4462   ; y la misma cuenta al marcador que se ensena
	ld (0e043h),a		;4465
EMPIEZA_EPOCA:		; Monta la pantalla de la epoca que toca
	ld a,014h		;4468   ; la epoca nueva empieza por borrar y repintar la pantalla entera
	ld (0e130h),a		;446a   ; veinte pasos de la interrupcion, o sea unos trece segundos, hasta el primer grupo
	ld a,002h		;446d
	call ESPERA		;446f   ; otros dos puntos antes de empezar
	di			;4472
	call BORRA_LA_TABLA_DE_NOMBRES		;4473
	ld hl,04fa3h		;4476
	call ESCRIBE_ROTULO		;4479
	ld a,(0e014h)		;447c
	or a			;447f
	jr z,EPOCA_UN_JUGADOR		;4480
	xor a			;4482   ; en la demo se juega siempre con un solo jugador
	ld (0e000h),a		;4483
EPOCA_UN_JUGADOR:
	ld a,(0e000h)		;4486   ; con un solo jugador se borra el hueco del segundo del marcador
	or a			;4489
	jr nz,EPOCA_BORRA_PANTALLA		;448a
	ld de,078f9h		;448c
	ld bc,00200h		;448f   ; 0x200 casillas: el hueco entero del segundo jugador
	call RELLENA_VRAM		;4492
	ld de,07919h		;4495
	ld b,006h		;4498
	call RELLENA_VRAM		;449a
EPOCA_BORRA_PANTALLA:
	di			;449d
	ld c,000h		;449e
	call BORRA_AREA_CON_C		;44a0
EMPIEZA_VIDA:		; Coloca el avion, borra los actores y carga los graficos de la epoca
	ld de,0795ah		;44a3   ; el rotulo de la epoca en el marcador: cuatro caracteres por epoca
	call LEE_EPOCA		;44a6
	dec a			;44a9
	rlca			;44aa   ; dos rotaciones: la epoca por cuatro, que son los caracteres de su rotulo
	rlca			;44ab
	ld hl,04e7ch		;44ac
	call SUMA_A_HL		;44af
	ld b,004h		;44b2   ; cuatro caracteres: el rotulo de la epoca
	di			;44b4
	call COPIA_A_VRAM		;44b5
	ei			;44b8
	ld hl,0e121h		;44b9
	call LEE_JUGADOR		;44bc
	rlca			;44bf   ; el `rlca` pasa el numero de jugador a desplazamiento: cada uno tiene su pareja de bytes
	call SUMA_A_HL		;44c0
	xor a			;44c3
	ld (hl),a			;44c4   ; ningun enemigo en pantalla al empezar
	ld hl,0e03fh		;44c5
	ld a,(hl)			;44c8
	ld b,010h		;44c9   ; dieciseis puntos de espera -unos diez segundos-, o seis si se venia de morir
	ld (hl),000h		;44cb
	dec a			;44cd
	jr z,VIDA_ESPERA		;44ce
	ld b,006h		;44d0
VIDA_ESPERA:
	ld a,b			;44d2
	ld (0e018h),a		;44d3
	ld hl,0e200h		;44d6   ; y las cuatro paginas de fichas y sprites, a cero de una tacada
	ld de,0e201h		;44d9
	ld bc,001ffh		;44dc   ; 0x1FF bytes mas el que se siembra: las cuatro paginas enteras
	ld (hl),000h		;44df
	ldir		;44e1
	di			;44e3
	ld hl,06af0h		;44e4
	ld de,06060h		;44e7
	ld b,008h		;44ea   ; ocho bytes: un caracter
	call COPIA_A_VRAM		;44ec
	ld hl,06f2bh		;44ef   ; los dieciseis dibujos del avion, uno por direccion
	ld de,05800h		;44f2
	ld b,020h		;44f5   ; 0x20 bytes en total para los dieciseis: dos por dibujo
	call COPIA_A_VRAM		;44f7
	ld de,05a00h		;44fa
	ld hl,071f1h		;44fd   ; 256 bytes de patrones de sprite comunes
	ld b,000h		;4500   ; B a cero son 256 vueltas
	call COPIA_A_VRAM		;4502
	ld de,06340h		;4505
	call PON_DIRECCION_VDP		;4508
	ld c,003h		;450b   ; tres tercios, uno por pasada
BORRA_TRES_TERCIOS:
	xor a			;450d   ; la tabla de color se borra en los tres tercios
	ld b,a			;450e
	call RELLENA_VRAM_CON_A		;450f
	dec c			;4512
	jr nz,BORRA_TRES_TERCIOS		;4513
	ld de,TITULO_SIGUIENTE_RENGLON		;4515
	call PON_DIRECCION_VDP		;4518
	ld c,003h		;451b
BORRA_TRES_TERCIOS_2:
	xor a			;451d   ; y la de nombres tambien
	ld b,a			;451e
	call RELLENA_VRAM_CON_A		;451f
	dec c			;4522
	jr nz,BORRA_TRES_TERCIOS_2		;4523
	call LEE_EPOCA		;4525   ; la epoca decide los dibujos, el color del cielo y las nubes
	push af			;4528
	ld de,06058h		;4529
	ld hl,06ad0h		;452c
	cp 003h		;452f
	jr c,CARGA_NUBES		;4531
	ld hl,06ad8h		;4533
	jr z,CARGA_NUBES		;4536
	ld hl,06ae0h		;4538
	cp 004h		;453b
	jr z,CARGA_NUBES		;453d
	ld hl,06ae8h		;453f
CARGA_NUBES:
	ld b,008h		;4542   ; la nube de la pantalla de titulo, un caracter por epoca
	call COPIA_A_VRAM		;4544
	pop af			;4547
	ld hl,073f4h		;4548   ; la epoca 1
	ld de,05900h		;454b
	ld b,000h		;454e   ; B a cero otra vez: los 256 bytes de los dibujos de la epoca
	dec a			;4550
	jp nz,EPOCA_2		;4551
	call COPIA_A_VRAM		;4554
	ld de,06340h		;4557
	ld hl,06bf2h		;455a
	call PON_DIRECCION_VDP		;455d
	ld b,005h		;4560
	call SUBE_CARACTERES_GIRADOS		;4562   ; los caracteres del fondo se suben girados: el mismo dibujo vale para varias direcciones
	jp CARGA_MARCADOR		;4565
EPOCA_2:
	dec a			;4568   ; la epoca 2
	jr nz,EPOCA_3		;4569
	ld hl,074f4h		;456b
	call COPIA_A_VRAM		;456e
	ld de,06340h		;4571
	ld hl,06c97h		;4574
	call PON_DIRECCION_VDP		;4577
	ld b,005h		;457a   ; cinco caracteres de color por epoca
	call SUBE_CARACTERES_GIRADOS		;457c
	jp CARGA_MARCADOR		;457f
EPOCA_3:
	dec a			;4582   ; la epoca 3 solo sube 0x60 bytes: sus enemigos son TRES dibujos, no ocho
	jr nz,EPOCA_4		;4583
	ld hl,075f2h		;4585
	ld b,060h		;4588   ; y por eso el bloque de la epoca 3 cabe en 96 bytes
	call COPIA_A_VRAM		;458a
	ld hl,06d3ch		;458d
	ld de,06340h		;4590
	call PON_DIRECCION_VDP		;4593
	ld b,005h		;4596
	call SUBE_CARACTERES_GIRADOS		;4598
	jr CARGA_MARCADOR		;459b
EPOCA_4:
	dec a			;459d   ; y la epoca 4 vuelve a los ocho
	jr nz,EPOCA_5		;459e
	ld hl,07652h		;45a0   ; la epoca 4 vuelve a los ocho dibujos, 256 bytes
	ld b,000h		;45a3
	call COPIA_A_VRAM		;45a5
	ld hl,06de1h		;45a8
	ld de,06340h		;45ab
	call PON_DIRECCION_VDP		;45ae
	ld b,005h		;45b1
	call SUBE_CARACTERES_GIRADOS		;45b3
	jr CARGA_MARCADOR		;45b6
EPOCA_5:
	call PON_DIRECCION_VDP		;45b8   ; la epoca 5, que necesita dos tandas de ocho bloques
	ld hl,07752h		;45bb
	ld c,002h		;45be
	ld b,008h		;45c0
EPOCA_5_BUCLE:
	push bc			;45c2   ; la epoca 5 sube el mismo dibujo ocho veces: su platillo no gira
	push hl			;45c3
	ld b,020h		;45c4   ; 0x20 bytes por tanda: cuatro caracteres
	call COPIA_A_VRAM_YA		;45c6
	pop hl			;45c9
	pop bc			;45ca
	djnz EPOCA_5_BUCLE		;45cb   ; dos tandas de ocho, una por juego de dibujos
	ld de,05a00h		;45cd   ; y la segunda mitad va al bloque comun, encima de los misiles
	call PON_DIRECCION_VDP		;45d0
	ld b,008h		;45d3
	ld hl,07772h		;45d5
	dec c			;45d8
	jr nz,EPOCA_5_BUCLE		;45d9
	ld hl,06e86h		;45db
	ld de,06340h		;45de
	call PON_DIRECCION_VDP		;45e1
	ld b,005h		;45e4
	call SUBE_CARACTERES_GIRADOS		;45e6
CARGA_MARCADOR:		; Los caracteres del marcador y la fila de arriba
	ld hl,079d3h		;45e9   ; las diez cifras del marcador, otra vez, con su otro color
	ld de,06638h		;45ec
	ld b,050h		;45ef   ; 0x50 bytes: diez caracteres del fondo comunes
	call COPIA_A_VRAM		;45f1
	ld de,04008h		;45f4   ; la fila de arriba se pinta aparte, con su propia lista
	call PON_DIRECCION_VDP		;45f7
	ld c,00ch		;45fa   ; doce tramos de fondo en la primera epoca, trece en la segunda y once en la tercera
	call LEE_EPOCA		;45fc   ; y el fondo, que se pinta con listas de (cuantos, caracter)
	ld hl,04d39h		;45ff
	dec a			;4602
	jr z,PINTA_FONDO_DE_LA_EPOCA		;4603
	ld hl,04d61h		;4605
	ld c,00dh		;4608
	dec a			;460a
	jr z,PINTA_FONDO_DE_LA_EPOCA		;460b
	ld hl,04d82h		;460d
	ld c,00bh		;4610
	dec a			;4612
	jr z,PINTA_FONDO_DE_LA_EPOCA		;4613
	ld hl,04dadh		;4615
	ld c,00ch		;4618
	dec a			;461a
	jr z,PINTA_FONDO_DE_LA_EPOCA		;461b
	ld hl,04dd3h		;461d
PINTA_FONDO_DE_LA_EPOCA:
	ld a,(hl)			;4620   ; un 0xFF en la lista quiere decir "aqui va un bloque entero"
	inc a			;4621   ; un 0xFF en la lista no es un caracter: es una orden de bloque
	call z,PINTA_BLOQUE_DE_FONDO		;4622
	ld b,(hl)			;4625   ; y si no, es una pareja (cuantos, caracter)
	inc hl			;4626
	ld a,(hl)			;4627
	call RELLENA_VRAM_CON_A		;4628   ; y si no, se rellenan tantas casillas como diga
	inc hl			;462b
	ld a,(hl)			;462c   ; y otro 0xFF detras cierra la fila
	inc a			;462d
	call z,PINTA_BLOQUE_DE_FONDO		;462e
	dec c			;4631
	jr nz,PINTA_FONDO_DE_LA_EPOCA		;4632
	ld de,02000h		;4634   ; el fondo se pinta en la tabla de color, no en la de nombres
	ld hl,06800h		;4637
	call COPIA_VRAM_A_VRAM		;463a
	ld de,00000h		;463d
	ld hl,04800h		;4640
	call COPIA_VRAM_A_VRAM		;4643
	ei			;4646
	call LEE_EPOCA		;4647
	ld de,04debh		;464a
	dec a			;464d
	jr z,MONTA_SPRITES_DE_LA_EPOCA		;464e
	ld de,04e00h		;4650
	dec a			;4653
	jr z,MONTA_SPRITES_DE_LA_EPOCA		;4654
	ld de,04e15h		;4656
	dec a			;4659
	jr z,MONTA_SPRITES_DE_LA_EPOCA		;465a
	ld de,04e2ah		;465c
	dec a			;465f
	jr z,MONTA_SPRITES_DE_LA_EPOCA		;4660
	ld de,04e3fh		;4662
MONTA_SPRITES_DE_LA_EPOCA:
	ld hl,0e380h		;4665   ; los 21 sprites de la epoca: patron y color, y todos fuera de pantalla
	ld c,007h		;4668   ; siete grupos de sprites, cada uno con su cuenta al frente
MONTA_SPRITES_GRUPO:
	ld a,(de)			;466a
	ld b,a			;466b
	inc de			;466c
MONTA_SPRITES_UNO:
	push de			;466d
	ld (hl),0d1h		;466e   ; todos los sprites arrancan fuera de pantalla, en Y=0xD1
	inc hl			;4670
	ld (hl),0ffh		;4671
	inc hl			;4673
	ld a,(de)			;4674   ; y con la posicion que dice la lista, que va de dos en dos
	ld (hl),a			;4675
	inc hl			;4676
	inc de			;4677
	ld a,(de)			;4678
	ld (hl),a			;4679
	inc hl			;467a
	pop de			;467b
	djnz MONTA_SPRITES_UNO		;467c   ; tantos sprites como diga la cuenta del grupo
	inc de			;467e
	inc de			;467f
	dec c			;4680
	jr nz,MONTA_SPRITES_GRUPO		;4681   ; y se pasa al grupo siguiente hasta agotar los siete
	di			;4683
	call BORRA_EL_AREA_DE_JUEGO		;4684   ; el area de juego se borra antes de montar la fase
	ei			;4687
	ld a,001h		;4688
	ld (0e015h),a		;468a   ; 0xE015 dice que hay fase en marcha
	xor a			;468d
	ld (0e146h),a		;468e   ; 0xE146 a cero: no hay aviso de fase pendiente
	ld hl,04ce9h		;4691   ; las nueve nubes, a sus casillas de salida
	ld de,0e210h		;4694
	ld bc,0001ch		;4697   ; 0x1C bytes: las nueve nubes y su cierre
	ldir		;469a
	ld hl,0e100h		;469c
	ld (hl),001h		;469f   ; el fondo arranca con el bit 0 puesto: acelerando
	inc hl			;46a1
	ld (hl),004h		;46a2   ; la direccion del fondo arranca en la 4 y su cuenta atras en 3
	inc hl			;46a4
	ld (hl),003h		;46a5
	inc hl			;46a7
	ld (hl),000h		;46a8
	ld hl,079ach		;46aa   ; el marcador que se dibuja solo, casilla a casilla
	ld (0e039h),hl		;46ad   ; 0xE039 guarda por donde va el marcador que se dibuja solo
	ld hl,0e03bh		;46b0
	ld (hl),001h		;46b3   ; y 0xE03B es su cuenta atras entre casilla y casilla
	ld hl,00000h		;46b5
	ld (0e03ch),hl		;46b8
	xor a			;46bb
	ld (0e03eh),a		;46bc
	ld hl,0e120h		;46bf
	call LEE_JUGADOR		;46c2
	rlca			;46c5   ; el `rlca` convierte el numero de jugador en desplazamiento de dos bytes
	call SUMA_A_HL		;46c6
	ld c,000h		;46c9
	ld a,(hl)			;46cb
CUENTA_ENEMIGOS_QUE_FALTAN:
	inc c			;46cc   ; cuantos enemigos faltan, en grupos de cinco
	sub 005h		;46cd
	jr z,GUARDA_ENEMIGOS_QUE_FALTAN		;46cf
	jr nc,CUENTA_ENEMIGOS_QUE_FALTAN		;46d1
GUARDA_ENEMIGOS_QUE_FALTAN:
	ld a,c			;46d3
	ld (0e044h),a		;46d4
PINTA_VIDAS:		; Los aviones que quedan, en la fila de abajo
	ld hl,0e002h		;46d7   ; las vidas se pintan en la fila de abajo, siete como mucho
	call LEE_POR_JUGADOR		;46da
	ld de,07a59h		;46dd   ; los aviones que le quedan al jugador, en la fila de abajo
	ld b,007h		;46e0   ; siete casillas: el hueco entero de las vidas
	ld c,000h		;46e2
	di			;46e4
	call RELLENA_VRAM		;46e5   ; primero se borran las siete
	ei			;46e8
	ld a,(hl)			;46e9
	dec a			;46ea
	jr z,PARTIDA_MIRA_MARCADOR		;46eb
	cp 008h		;46ed
	jr c,PINTA_VIDAS_BUCLE		;46ef
	ld a,007h		;46f1
PINTA_VIDAS_BUCLE:
	ld b,a			;46f3   ; siete vidas es lo mas que cabe en la fila
	ld de,07a59h		;46f4
	ld c,009h		;46f7   ; y luego se pintan tantos aviones como vidas queden
	di			;46f9
	call RELLENA_VRAM		;46fa
	ei			;46fd
PASO_DE_LA_PARTIDA:		; El bucle exterior: lo que el programa principal hace mientras se juega
	ld hl,0e044h		;46fe   ; 0xE044 avisa de que ha cambiado el numero de enemigos que faltan
	ld a,(hl)			;4701
	ld c,a			;4702
	ld (hl),000h		;4703   ; el aviso se consume al leerlo
	or a			;4705
	jr nz,PINTA_ENEMIGOS_QUE_FALTAN		;4706
PARTIDA_MIRA_MARCADOR:
	ld c,001h		;4708   ; 0xE1A0 avisa de que hay que repintar la cuenta de enemigos
	ld hl,0e1a0h		;470a
	ld a,(hl)			;470d
	ld (hl),000h		;470e
	or a			;4710
	jr nz,PINTA_ENEMIGOS_QUE_FALTAN		;4711   ; con el aviso puesto se repinta aunque no haya cambiado la cuenta
	ld hl,0e120h		;4713
	call LEE_JUGADOR		;4716
	rlca			;4719
	call SUMA_A_HL		;471a
	ld b,(hl)			;471d   ; la cuenta que se ensena y la de verdad no son la misma
	ld hl,0e042h		;471e
	call LEE_JUGADOR		;4721
	call SUMA_A_HL		;4724
	ld a,(hl)			;4727
	ld c,000h		;4728
	cp b			;472a
	jr c,MIRA_RECORD		;472b   ; si ya coinciden no hay nada que repintar
	or a			;472d
	jr z,PINTA_ENEMIGOS_QUE_FALTAN		;472e
PARTIDA_DESCUENTA:
	inc c			;4730   ; cuantos grupos de cinco quedan
	sub 005h		;4731
	jr nz,PARTIDA_DESCUENTA		;4733
	ld a,(hl)			;4735
	sub 005h		;4736   ; y la cuenta que se ensena baja de cinco en cinco hasta alcanzar a la de verdad
	ld (hl),a			;4738
PINTA_ENEMIGOS_QUE_FALTAN:
	push bc			;4739   ; los enemigos que faltan se ensenan como marcas, de cinco en cinco
	ld de,07999h		;473a
	push de			;473d
	ld c,002h		;473e
PINTA_ENEMIGOS_BORRA:
	ld b,005h		;4740   ; dos filas de cinco marcas
	di			;4742
	call PON_DIRECCION_VDP		;4743
	xor a			;4746
	call RELLENA_VRAM_CON_A		;4747
	ei			;474a
	ex de,hl			;474b
	ld a,020h		;474c   ; la segunda fila va 32 casillas mas alla
	call SUMA_A_HL		;474e
	ex de,hl			;4751
	dec c			;4752
	jr nz,PINTA_ENEMIGOS_BORRA		;4753
	pop de			;4755
	pop bc			;4756
	ld a,c			;4757
	or a			;4758
	jr z,MIRA_RECORD		;4759
PINTA_ENEMIGOS_MARCAS:
	ld b,005h		;475b   ; cinco marcas por fila
	di			;475d
	call PON_DIRECCION_VDP		;475e
	ei			;4761
PINTA_ENEMIGOS_MARCA:
	di			;4762   ; el caracter 0x0B es la marca del enemigo que falta
	ld a,00bh		;4763   ; y luego se pinta el caracter 0x0B tantas veces como grupos queden
	out (098h),a		;4765
	ei			;4767
	dec c			;4768
	jr z,MIRA_RECORD		;4769
	djnz PINTA_ENEMIGOS_MARCA		;476b   ; hasta llenar la fila o agotar los grupos
	ex de,hl			;476d
	ld a,020h		;476e
	call SUMA_A_HL		;4770
	ex de,hl			;4773
	jr PINTA_ENEMIGOS_MARCAS		;4774
MIRA_RECORD:		; Si los puntos pasan del record, el record cambia
	ei			;4776   ; si los puntos pasan del record, el record cambia
	ld hl,0e00dh		;4777
	call LEE_JUGADOR		;477a
	jr z,MIRA_RECORD_RESTA		;477d
	ld l,010h		;477f
MIRA_RECORD_RESTA:
	ld de,0e013h		;4781
	ld b,003h		;4784   ; el record son tres bytes en BCD
	or a			;4786
MIRA_RECORD_BUCLE:
	ld a,(de)			;4787   ; la resta de tres bytes, del mas bajo al mas alto, dice quien va delante
	sbc a,(hl)			;4788
	dec hl			;4789
	dec de			;478a
	djnz MIRA_RECORD_BUCLE		;478b
	jr nc,PINTA_RECORD		;478d
	inc hl			;478f
	inc de			;4790
	ld bc,00003h		;4791   ; si el jugador ha pasado al record, se copia encima
	ldir		;4794
PINTA_RECORD:
	ld hl,0e011h		;4796
	ld de,07859h		;4799
	di			;479c
	call PINTA_SEIS_CIFRAS		;479d   ; seis cifras: los tres bytes en BCD
	ei			;47a0
	ld a,(0e014h)		;47a1   ; en la demo no se repinta el marcador del jugador
	or a			;47a4
	jr nz,MIRA_SI_HA_MUERTO		;47a5
	ld hl,0e00bh		;47a7
	ld de,078b9h		;47aa
	call LEE_JUGADOR		;47ad   ; cada jugador tiene su hueco: 0xE00B y 0x78B9, o 0xE00E y 0x7919
	jr z,PINTA_PUNTOS_DEL_JUGADOR		;47b0
	ld l,00eh		;47b2
	ld de,07919h		;47b4
PINTA_PUNTOS_DEL_JUGADOR:
	di			;47b7
	call PINTA_SEIS_CIFRAS		;47b8
	ei			;47bb
MIRA_SI_HA_MUERTO:
	ld hl,0e050h		;47bc   ; 0xE050 se pone al estrellarse
	ld a,(0e014h)		;47bf
	or a			;47c2
	jr z,MUERTE_DEL_JUGADOR		;47c3
	ld a,(hl)			;47c5   ; en la demo, morirse solo sirve para pasar al otro jugador
	or a			;47c6
	jp z,MIRA_TECLA_DE_ARRANQUE		;47c7
	xor a			;47ca
	ld (hl),a			;47cb
	jp CAMBIA_DE_JUGADOR		;47cc
MUERTE_DEL_JUGADOR:
	ld a,(hl)			;47cf   ; el jugador se ha estrellado
	or a			;47d0
	jp z,MIRA_VIDA_EXTRA		;47d1
	ld a,0d0h		;47d4   ; al morir, el sprite del avion se manda a Y=0xD0, fuera de la pantalla
	ld (0e380h),a		;47d6
	di			;47d9
	call APAGA_LOS_SPRITES		;47da   ; los sprites se apagan mientras dura la explosion
	ei			;47dd
PREPARA_VIDA_NUEVA:
	xor a			;47de   ; la vida nueva empieza sin fase en marcha
	ld (0e015h),a		;47df
	ex de,hl			;47e2
	ld hl,0e124h		;47e3   ; se limpian las cuentas de la vida que empieza
	call LEE_POR_JUGADOR		;47e6
	xor a			;47e9
	ld (hl),a			;47ea
	inc hl			;47eb
	inc hl			;47ec
	ld (hl),a			;47ed
	ld a,(0e004h)		;47ee   ; si no le quedan vidas, le toca al otro jugador
	or a			;47f1
	jr z,VIDA_ESPERA_FOTOGRAMA		;47f2
	ld hl,0e002h		;47f4
	call LEE_POR_JUGADOR		;47f7
	ex de,hl			;47fa
	ld (hl),000h		;47fb   ; al perder la ultima vida el hueco queda a cero
	dec a			;47fd
	jp z,CAMBIA_DE_JUGADOR		;47fe
	inc (hl)			;4801   ; y si aun le quedan, se le descuenta una
	ex de,hl			;4802
VIDA_ESPERA_FOTOGRAMA:
	ld hl,0e019h		;4803
	ld a,(hl)			;4806
	rrca			;4807   ; esto solo se hace un fotograma de cada dos
	jp nc,PASO_DE_LA_PARTIDA		;4808
	ld (hl),000h		;480b
	ex de,hl			;480d
	inc hl			;480e
	ld a,065h		;480f   ; 0x65 es la cuenta con la que empieza cada fase
	cp (hl)			;4811   ; al llegar a 0x65 la cuenta, se cambia de epoca
	jr nz,BAJA_LA_CUENTA		;4812
	push hl			;4814
	ld de,047e0h		;4815
	call LEE_EPOCA		;4818
	inc a			;481b
	ld hl,04d3dh		;481c   ; cada epoca borra la pantalla con su propia pareja (cuantos, caracter)
	cp 006h		;481f   ; la sexta vuelta al contador vuelve a la primera epoca
	jr z,CAMBIA_DE_EPOCA		;4821
	ld hl,04d65h		;4823
	dec a			;4826
	dec a			;4827
	jr z,CAMBIA_DE_EPOCA		;4828
	ld hl,04d86h		;482a
	dec a			;482d
	jr z,CAMBIA_DE_EPOCA		;482e
	ld hl,04db1h		;4830
	dec a			;4833
	jr z,CAMBIA_DE_EPOCA		;4834
	ld hl,04dd7h		;4836
CAMBIA_DE_EPOCA:
	di			;4839   ; al pasar de epoca se borra la pantalla con la pareja de la lista
	ld b,(hl)			;483a
	inc hl			;483b
	ld c,(hl)			;483c
	call RELLENA_VRAM		;483d
	ld de,00000h		;4840
	ld hl,04800h		;4843   ; y el tercero borrado se copia a los otros dos, que es lo barato
	call COPIA_VRAM_A_VRAM		;4846
	ei			;4849
	ld hl,07b94h		;484a   ; y suena la musica de la epoca nueva
	ld (0e020h),hl		;484d
	ld a,004h		;4850   ; el canal 4 es el de la musica
	ld (0e027h),a		;4852
	pop hl			;4855
BAJA_LA_CUENTA:
	dec (hl)			;4856   ; y la cuenta baja un paso
PASO_DEL_ROTULO:
	di			;4857
	call PASO_DEL_ROTULO_DEL_TITULO		;4858
	ei			;485b
	ld a,(0e051h)		;485c
	or a			;485f
	jr z,MIRA_FIN_DE_FASE		;4860
	ld bc,00010h		;4862   ; mientras la fase se acaba sola, dieciseis puntos por fotograma
	call SUMA_PUNTOS		;4865   ; el jugador cobra por lo que queda vivo cuando la fase se acaba sola
	jp PASO_DE_LA_PARTIDA		;4868
MIRA_FIN_DE_FASE:
	ld hl,0e03eh		;486b   ; 0xE03E lo pone el rotulo cuando acaba su animacion
	ld a,(hl)			;486e
	ld (hl),000h		;486f   ; el aviso se consume al leerlo
	or a			;4871
	jr nz,FASE_SIGUIENTE		;4872
FASE_ESPERA:
	ld a,(0e019h)		;4874   ; y si no, a esperar un fotograma si y otro no
	rrca			;4877
	jr nc,FASE_ESPERA		;4878
	xor a			;487a
	ld (0e019h),a		;487b
	jr PASO_DEL_ROTULO		;487e
FASE_SIGUIENTE:		; La ronda sube, y con ella la epoca y los enemigos que hacen falta
	ld a,(0e021h)		;4880   ; antes de pasar de fase se espera a que se acabe lo que este sonando
	or a			;4883
	jr nz,FASE_SIGUIENTE		;4884
	xor a			;4886
	ld (0e03eh),a		;4887
	ld hl,0e050h		;488a
	ld (hl),000h		;488d
	inc hl			;488f
	ld (hl),065h		;4890   ; la cuenta de la fase, otra vez a 0x65
	ld hl,0e182h		;4892
	call LEE_POR_JUGADOR		;4895
	inc a			;4898   ; la ronda sube de una en una, y en BCD
	daa			;4899
	ld (hl),a			;489a
	dec hl			;489b
	dec hl			;489c
	inc (hl)			;489d   ; y la epoca con ella, de la 1 a la 5 y vuelta a empezar
	ld a,(hl)			;489e
	cp 006h		;489f   ; pasada la quinta epoca se vuelve a la primera
	jr c,CUANTOS_ENEMIGOS		;48a1
	ld (hl),001h		;48a3
CUANTOS_ENEMIGOS:
	ld hl,0e120h		;48a5
	call LEE_JUGADOR		;48a8
	jr z,CUANTOS_ENEMIGOS_PREPARA		;48ab
	inc hl			;48ad
	inc hl			;48ae
CUANTOS_ENEMIGOS_PREPARA:
	push hl			;48af
	ld hl,0e182h		;48b0
	call LEE_POR_JUGADOR		;48b3
	pop hl			;48b6
	ld c,019h		;48b7   ; 25 enemigos la primera ronda
	ld b,006h		;48b9   ; el escalon sube de cinco en cinco rondas
CUANTOS_ENEMIGOS_BUCLE:		; Cinco enemigos mas cada cinco rondas, hasta cincuenta
	ld (hl),c			;48bb   ; los enemigos que hay que derribar salen de la ronda
	cp b			;48bc
	jr c,GUARDA_CUANTOS_ENEMIGOS		;48bd   ; hasta la ronda 5 son 25, de la 6 a la 10 treinta, y asi
	ld d,a			;48bf
	ld a,032h		;48c0   ; con el tope en 50
	cp c			;48c2
	jr z,GUARDA_CUANTOS_ENEMIGOS		;48c3
	ld a,005h		;48c5   ; y cinco mas cada cinco rondas
	add a,b			;48c7
	daa			;48c8
	ld b,a			;48c9
	ld a,005h		;48ca
	add a,c			;48cc
	ld c,a			;48cd
	ld a,d			;48ce
	jr CUANTOS_ENEMIGOS_BUCLE		;48cf
GUARDA_CUANTOS_ENEMIGOS:
	ld b,(hl)			;48d1
	ld hl,0e042h		;48d2
	call LEE_JUGADOR		;48d5
	call SUMA_A_HL		;48d8
	ld (hl),b			;48db   ; los enemigos de la ronda quedan apuntados en el hueco del jugador
	di			;48dc
	call APAGA_LOS_SPRITES		;48dd   ; los sprites se apagan mientras se monta la fase nueva
	ei			;48e0
	ld a,(0e004h)		;48e1   ; si el jugador esta vivo, suena el aviso de fase nueva
	or a			;48e4
	jr nz,BORRA_MARCADOR_DEL_JUGADOR		;48e5
	ld hl,07d57h		;48e7
	ld (0e030h),hl		;48ea   ; el canal 5 es el de los avisos
	jp EMPIEZA_VIDA		;48ed
MIRA_VIDA_EXTRA:		; A los 10000 puntos y luego cada 50000
	ld de,0e00bh		;48f0   ; la vida extra: se compara la cifra alta de los puntos con el escalon
	ld hl,0e005h		;48f3
	call LEE_JUGADOR		;48f6
	jr z,VIDA_EXTRA_COMPARA		;48f9
	inc hl			;48fb
	ld e,00eh		;48fc
VIDA_EXTRA_COMPARA:
	ld a,(de)			;48fe
	cp (hl)			;48ff   ; la cifra alta de los puntos contra el escalon de la vida extra
	jr nz,FIN_DE_LA_VIDA		;4900
	push hl			;4902
	ld hl,07e7fh		;4903
	ld (0e030h),hl		;4906
	ld a,00ah		;4909
	ld (0e037h),a		;490b   ; 0x0A fotogramas de aviso de vida extra
	pop hl			;490e
	ex de,hl			;490f
	ld hl,0e040h		;4910
	call LEE_POR_JUGADOR		;4913
	ld a,005h		;4916   ; y el escalon sube de cinco en cinco: 10000, 60000, 110000...
	add a,(hl)			;4918
	daa			;4919
	ld (hl),a			;491a
	ld (de),a			;491b
	ld hl,0e002h		;491c
	call LEE_POR_JUGADOR		;491f
	inc (hl)			;4922   ; una vida mas
	jp PINTA_VIDAS		;4923
MIRA_TECLA_DE_ARRANQUE:
	di			;4926
	xor a			;4927
	call LEE_FILA_DEL_TECLADO		;4928   ; la fila 0 del teclado: las teclas 1 a 4
	ei			;492b
	and 01eh		;492c   ; solo interesan cuatro bits: las teclas 1 a 4
	cp 01eh		;492e
	jp z,FIN_DE_LA_VIDA		;4930
	ld (0e038h),a		;4933   ; cual se pulso, para elegir uno o dos jugadores
	ld hl,00000h		;4936
	ld (0e014h),hl		;4939   ; se apaga la demo y se vuelve al titulo
	ld (0e145h),hl		;493c
	xor a			;493f
	ld (0e052h),a		;4940
	jp PANTALLA_DE_TITULO		;4943
FIN_DE_LA_VIDA:
	ld a,(0e004h)		;4946   ; sin muerte pendiente no hay nada que cerrar
	or a			;4949
	jp z,PASO_DE_LA_PARTIDA		;494a
	ld hl,0e050h		;494d
	ld a,(hl)			;4950
	or a			;4951
	jp nz,PREPARA_VIDA_NUEVA		;4952
BORRA_MARCADOR_DEL_JUGADOR:
	di			;4955   ; al cambiar de jugador se borra su rotulo del marcador
	ld de,07899h		;4956   ; al cambiar de jugador se borra su rotulo del marcador
	ld hl,04fb0h		;4959
	ld b,002h		;495c
	call COPIA_A_VRAM		;495e   ; dos casillas: el rotulo de 1UP o 2UP
	call LEE_JUGADOR		;4961
	jr z,CAMBIA_DE_JUGADOR		;4964
	ld de,078f9h		;4966
	ld hl,04fbbh		;4969
	ld b,002h		;496c
	call COPIA_A_VRAM		;496e
CAMBIA_DE_JUGADOR:
	call APAGA_LOS_SPRITES		;4971   ; y los sprites del jugador que se va, apagados
	xor a			;4974
	ld (0e004h),a		;4975
	ld (0e015h),a		;4978
	ei			;497b
	ld hl,0e002h		;497c
	call LEE_JUGADOR		;497f
	call SUMA_A_HL		;4982
	dec (hl)			;4985   ; una vida menos; si eran las ultimas, se acabo
	jp z,FIN_DE_PARTIDA		;4986
	xor a			;4989
	ld (0e20fh),a		;498a
	ld (0e021h),a		;498d   ; los tres canales de sonido, callados
	ld (0e029h),a		;4990
	ld (0e031h),a		;4993
	di			;4996
	ld b,00fh		;4997   ; y el registro 15 del PSG a cero
	call ESCRIBE_PSG		;4999   ; el registro 15 del PSG a cero: se apaga tambien el puerto de salida
	ei			;499c
	ld a,(0e000h)		;499d
	or a			;49a0
	jp z,EPOCA_BORRA_PANTALLA		;49a1
	call SIGUIENTE_JUGADOR		;49a4
	jr c,OTRO_JUGADOR_EMPIEZA		;49a7   ; si no hay otro jugador esperando, sigue el mismo
	ld a,b			;49a9
	ld (0e001h),a		;49aa
OTRO_JUGADOR_EMPIEZA:
	di			;49ad
	ld c,000h		;49ae
	call BORRA_AREA_CON_C		;49b0   ; el area de juego se borra en negro antes de pasarle el turno al otro
	ei			;49b3
	ld hl,04f5ch		;49b4   ; y sale el rotulo de que jugador entra
	call LEE_JUGADOR		;49b7
	jr z,OTRO_JUGADOR_ROTULO		;49ba
	ld hl,04f68h		;49bc
OTRO_JUGADOR_ROTULO:
	di			;49bf
	call ESCRIBE_ROTULO		;49c0
	ld de,07999h		;49c3
	ld c,002h		;49c6
OTRO_JUGADOR_BORRA:
	ld b,005h		;49c8   ; diez casillas en dos filas
	di			;49ca
	call PON_DIRECCION_VDP		;49cb
	xor a			;49ce
	call RELLENA_VRAM_CON_A		;49cf
	ex de,hl			;49d2
	ld a,020h		;49d3   ; y la fila siguiente, 32 casillas mas alla
	call SUMA_A_HL		;49d5
	ex de,hl			;49d8
	dec c			;49d9
	jr nz,OTRO_JUGADOR_BORRA		;49da
	ei			;49dc
	ld a,002h		;49dd
	call ESPERA		;49df   ; dos puntos de espera con el rotulo puesto
	jp EPOCA_BORRA_PANTALLA		;49e2
FIN_DE_PARTIDA:
	xor a			;49e5
	ld (0e021h),a		;49e6   ; los tres canales, callados
	ld (0e029h),a		;49e9
	ld (0e031h),a		;49ec
	di			;49ef
	ld b,00fh		;49f0
	call ESCRIBE_PSG		;49f2
	ei			;49f5
	ld a,(0e014h)		;49f6   ; en la demo no se ensena el GAME OVER
	or a			;49f9
	jr nz,BORRA_MARCADORES		;49fa
	di			;49fc
	ld hl,04f74h		;49fd
	call ESCRIBE_ROTULO		;4a00
	call LEE_JUGADOR		;4a03
	jr z,FIN_DE_PARTIDA_ROTULO		;4a06
	ld de,0796fh		;4a08   ; al segundo jugador se le cambia una casilla del rotulo
	call PON_DIRECCION_VDP		;4a0b
	ld a,0e7h		;4a0e   ; el 0xE7 es el "2" que sustituye al "1" del rotulo
	out (098h),a		;4a10
FIN_DE_PARTIDA_ROTULO:
	ei			;4a12
	ld a,002h		;4a13
	call ESPERA		;4a15   ; dos puntos de espera con el GAME OVER puesto
	ld a,(0e000h)		;4a18   ; con un solo jugador no hay a quien pasarle el turno
	or a			;4a1b
	jr z,BORRA_MARCADORES		;4a1c
	call SIGUIENTE_JUGADOR		;4a1e
	jr c,OTRO_JUGADOR_EMPIEZA		;4a21
BORRA_MARCADORES:
	ld b,006h		;4a23
	ld hl,0e00bh		;4a25   ; los seis bytes de los dos marcadores, a cero
BORRA_MARCADORES_BUCLE:
	xor a			;4a28   ; los seis bytes de los dos marcadores, a cero
	ld (hl),a			;4a29
	inc hl			;4a2a
	djnz BORRA_MARCADORES_BUCLE		;4a2b
	ld (0e001h),a		;4a2d   ; y se vuelve al jugador 1, con la demo apagada
	ld (0e014h),a		;4a30
	ld a,002h		;4a33
	call ESPERA		;4a35   ; dos puntos de espera antes de volver al titulo
	jp PANTALLA_DE_TITULO		;4a38
LEE_JOYSTICK:		; Registro 14 del PSG por el puerto 0xA2
	ld a,00eh		;4a3b   ; registro 14 del PSG: el joystick, por el puerto 0xA2
	out (0a0h),a		;4a3d
	nop			;4a3f   ; el `nop` es la espera que pide el PSG entre escribir el registro y leerlo
	in a,(0a2h)		;4a40
	ret			;4a42
LEE_FILA_DEL_TECLADO:		; Deja en A la fila A de la matriz del teclado
	or 0f0h		;4a43   ; el nibble alto a unos: solo se elige fila, no se escribe nada mas
	out (0aah),a		;4a45   ; la fila del teclado se escribe dos veces por seguridad
	out (0aah),a		;4a47
	in a,(0a9h)		;4a49
	ret			;4a4b
LEE_TECLAS_DE_DIRECCION:		; La fila 8 (cursores y espacio), pasada por la tabla de 0x4E54
	ld a,008h		;4a4c   ; la fila 8: los cuatro cursores y la barra
	call LEE_FILA_DEL_TECLADO		;4a4e
	cpl			;4a51   ; el teclado da las teclas a cero; se invierte para trabajar con unos
	ld c,a			;4a52
	rrca			;4a53   ; los cuatro cursores estan en el nibble alto de la fila 8
	rrca			;4a54
	rrca			;4a55
	rrca			;4a56
	and 00fh		;4a57
	ld hl,04e54h		;4a59   ; y la tabla los pasa a la misma forma que da el joystick
	call SUMA_A_HL		;4a5c
	ld a,(hl)			;4a5f
	cpl			;4a60
	ret			;4a61
PINTA_LA_PANTALLA_FIJA:		; Los cinco rotulos de 0x4EAB
	call BORRA_LA_TABLA_DE_NOMBRES		;4a62
	ld hl,04eabh		;4a65
	ld b,005h		;4a68   ; cinco listas de rotulos, una detras de otra
PINTA_ROTULO_SIGUIENTE:
	push bc			;4a6a
	call ESCRIBE_ROTULO		;4a6b
	pop bc			;4a6e
	djnz PINTA_ROTULO_SIGUIENTE		;4a6f
	ret			;4a71
ESCRIBE_ROTULO:		; El formato: una palabra con la direccion de VRAM, los caracteres, 0xFE para repetir uno, 0xFF para terminar el renglon y otro 0xFF para terminar la lista
	ld d,(hl)			;4a72   ; la primera palabra de cada renglon es la direccion de la VRAM
	inc hl			;4a73
	ld e,(hl)			;4a74
	call PON_DIRECCION_VDP		;4a75
ESCRIBE_ROTULO_BUCLE:
	inc hl			;4a78   ; los caracteres van tal cual, salvo el 0xFE y el 0xFF
	ld a,(hl)			;4a79
	cp 0feh		;4a7a   ; 0xFE repite un caracter B veces
	jr nz,ESCRIBE_ROTULO_MIRA_FIN		;4a7c
	inc hl			;4a7e
	ld b,(hl)			;4a7f
	inc hl			;4a80
	ld a,(hl)			;4a81
	call RELLENA_VRAM_CON_A		;4a82   ; el caracter se repite sin volver a poner direccion
	inc hl			;4a85
	ld a,(hl)			;4a86
ESCRIBE_ROTULO_MIRA_FIN:
	cp 0ffh		;4a87   ; 0xFF acaba el renglon; otro 0xFF detras, la lista entera
	jr z,ESCRIBE_ROTULO_SIGUIENTE		;4a89
	out (098h),a		;4a8b   ; y cualquier otro byte se manda tal cual al VDP
	jr ESCRIBE_ROTULO_BUCLE		;4a8d
ESCRIBE_ROTULO_SIGUIENTE:
	inc hl			;4a8f   ; detras del 0xFF del renglon, otro 0xFF cierra la lista entera
	ld a,(hl)			;4a90
	cp 0ffh		;4a91
	jr nz,ESCRIBE_ROTULO		;4a93
	inc hl			;4a95
	ret			;4a96
PINTA_SEIS_CIFRAS:		; Tres bytes BCD en seis caracteres, sumandole 0xE5 a cada cifra
	call PON_DIRECCION_VDP		;4a97
	ld b,003h		;4a9a   ; tres bytes: seis cifras
PINTA_CIFRA:
	ld a,(hl)			;4a9c
	ld e,(hl)			;4a9d
	ld d,0e5h		;4a9e   ; las cifras empiezan en el caracter 0xE5
	and 0f0h		;4aa0   ; primero el nibble alto y luego el bajo: son bytes BCD
	rrca			;4aa2
	rrca			;4aa3
	rrca			;4aa4
	rrca			;4aa5
	add a,d			;4aa6
	out (098h),a		;4aa7
	ld a,e			;4aa9
	and 00fh		;4aaa
	add a,d			;4aac
	out (098h),a		;4aad
	inc hl			;4aaf
	djnz PINTA_CIFRA		;4ab0   ; tres bytes, dos cifras cada uno
	ret			;4ab2
SIGUIENTE_JUGADOR:		; Cambia de jugador y devuelve carry si al nuevo le quedan vidas
	ld hl,0e001h		;4ab3   ; los dos jugadores se turnan al morir
	ld a,(hl)			;4ab6
	ld b,(hl)			;4ab7
	inc a			;4ab8   ; el jugador que toca es el otro: 0 y 1 se turnan
	and 001h		;4ab9
	ld (hl),a			;4abb
	inc hl			;4abc
	call SUMA_A_HL		;4abd   ; el hueco de vidas del jugador que entra
	ld a,(hl)			;4ac0   ; y se devuelve carry solo si al que entra le quedan vidas
	or a			;4ac1
	ret z			;4ac2
	scf			;4ac3
	ret			;4ac4
PARPADEA_EL_JUGADOR:		; Enciende y apaga el rotulo del jugador que juega, cada 0x40 fotogramas
	ld hl,0e016h		;4ac5
	dec (hl)			;4ac8   ; el rotulo del jugador que juega parpadea cada 0x40 fotogramas
	ret nz			;4ac9
	ld (hl),040h		;4aca
	inc hl			;4acc
	ld de,04fb0h		;4acd
	call LEE_JUGADOR		;4ad0
	jr z,PARPADEO_ENCIENDE		;4ad3
	ld de,04fbbh		;4ad5
PARPADEO_ENCIENDE:
	ld a,(hl)			;4ad8   ; el rotulo se enciende y se apaga alternando dos parejas de caracteres
	or a			;4ad9
	jr nz,PARPADEO_APAGA		;4ada
	inc (hl)			;4adc
	ld de,04e5ah		;4add
	jr PARPADEO_ESCRIBE		;4ae0
PARPADEO_APAGA:
	dec (hl)			;4ae2
PARPADEO_ESCRIBE:
	ex de,hl			;4ae3
	ld de,07899h		;4ae4
	call LEE_JUGADOR		;4ae7
	jr z,PARPADEO_SUBE		;4aea
	ld de,078f9h		;4aec
PARPADEO_SUBE:
	ld b,002h		;4aef   ; dos casillas: el rotulo entero
	call COPIA_A_VRAM		;4af1
	ret			;4af4
SUMA_PUNTOS:		; Suma BC en BCD a los puntos del jugador que juega
	ld a,(0e014h)		;4af5   ; en la demo no se puntua
	or a			;4af8
	ret nz			;4af9
	ld hl,0e00dh		;4afa   ; los puntos son tres bytes BCD, el mas alto primero
	call LEE_JUGADOR		;4afd
	jr z,SUMA_PUNTOS_YA		;4b00
	ld l,010h		;4b02
SUMA_PUNTOS_YA:
	ld a,(hl)			;4b04
	add a,c			;4b05   ; se suma en BCD, del byte bajo al alto, con daa detras de cada suma
	daa			;4b06
	ld (hl),a			;4b07
	dec hl			;4b08
	ld a,(hl)			;4b09
	adc a,b			;4b0a
	daa			;4b0b
	ld (hl),a			;4b0c
	ret nc			;4b0d   ; sin acarreo no hace falta tocar el byte alto
	dec hl			;4b0e   ; y el acarreo se propaga al byte de las centenas de millar
	ld a,(hl)			;4b0f
	add a,001h		;4b10
	daa			;4b12
	ld (hl),a			;4b13
	ret			;4b14
BORRA_LA_TABLA_DE_NOMBRES:		; Borra la tabla de nombres ENTERA, no una fila: con H=3 y B=0 son tres vueltas de 256 bytes, o sea los 768 de 0x3800
	ld de,07800h		;4b15   ; 0x7800 es el arranque de la tabla de nombres
	call PON_DIRECCION_VDP		;4b18
	ld h,003h		;4b1b   ; la fila del marcador se borra en los tres tercios
	xor a			;4b1d
BORRA_FILA_BUCLE:
	ld b,000h		;4b1e   ; B a cero son 256 casillas
	call RELLENA_VRAM_CON_A		;4b20
	dec h			;4b23
	jr nz,BORRA_FILA_BUCLE		;4b24
	ret			;4b26
BORRA_EL_AREA_DE_JUEGO:		; Las 24 filas de 24 columnas
	ld c,00ah		;4b27
BORRA_AREA_CON_C:
	ld de,07800h		;4b29
	ld h,018h		;4b2c
BORRA_AREA_FILA:
	ld b,018h		;4b2e   ; el area de juego son 24 filas de 24 columnas
	call RELLENA_VRAM		;4b30
	ex de,hl			;4b33
	ld a,020h		;4b34
	call SUMA_A_HL		;4b36   ; de una fila a la siguiente van 32 casillas, no 24
	ex de,hl			;4b39
	dec h			;4b3a
	jr nz,BORRA_AREA_FILA		;4b3b
	ret			;4b3d
CHOCAN:		; Compara las posiciones DE y BC con el rectangulo que dice la tabla de 0x4E64; devuelve carry si se tocan
	push af			;4b3e
	ld hl,04e64h		;4b3f   ; cada clase de choque tiene su rectangulo en la tabla de 0x4E64
	rlca			;4b42
	rlca			;4b43
	call SUMA_A_HL		;4b44
	pop af			;4b47
	cp 002h		;4b48   ; con margen 0 y 1 basta comparar; de 2 en adelante el rectangulo no es simetrico
	jr nc,CHOCAN_GRANDE		;4b4a
	ld a,d			;4b4c   ; la distancia en Y tiene que caer entre los dos limites de la tabla
	sub b			;4b4d
	cp (hl)			;4b4e
	jr c,CHOCAN_NO		;4b4f
	inc hl			;4b51
	cp (hl)			;4b52
	jr nc,CHOCAN_NO		;4b53
	ld a,e			;4b55   ; y la distancia en X, entre los otros dos
	sub c			;4b56
	inc hl			;4b57
	cp (hl)			;4b58
	jr c,CHOCAN_NO		;4b59
	inc hl			;4b5b
	cp (hl)			;4b5c
	jr nc,CHOCAN_NO		;4b5d
CHOCAN_SI:
	scf			;4b5f   ; dentro de los cuatro limites: se tocan
	ret			;4b60
CHOCAN_NO:
	or a			;4b61   ; y si no, carry a cero
	ret			;4b62
CHOCAN_GRANDE:
	ld a,d			;4b63   ; con el rectangulo torcido hay que mirar los dos lados por separado
	sub b			;4b64
	jr nc,CHOCAN_GRANDE_X		;4b65
	cp (hl)			;4b67
	jr c,CHOCAN_NO		;4b68
	inc hl			;4b6a
	jr CHOCAN_GRANDE_Y		;4b6b
CHOCAN_GRANDE_X:
	inc hl			;4b6d
	cp (hl)			;4b6e
	jr nc,CHOCAN_NO		;4b6f
CHOCAN_GRANDE_Y:
	inc hl			;4b71   ; y lo mismo con la otra coordenada
	ld a,e			;4b72
	sub c			;4b73
	jr nc,CHOCAN_GRANDE_Y2		;4b74
	cp (hl)			;4b76
	jr c,CHOCAN_NO		;4b77
	jr CHOCAN_SI		;4b79
CHOCAN_GRANDE_Y2:
	inc hl			;4b7b
	cp (hl)			;4b7c
	jr nc,CHOCAN_NO		;4b7d
	jr CHOCAN_SI		;4b7f
SUBE_CARACTERES_GIRADOS:		; Sube a la VRAM un juego de caracteres y, detras, sus copias desplazadas lateralmente; con eso el fondo se mueve de dos en dos o de cuatro en cuatro pixeles sin tocar la tabla de nombres
	push bc			;4b81   ; los caracteres del fondo se suben con sus copias desplazadas
	call COPIA_AL_TALLER		;4b82   ; primero el bloque original va al taller de 0xE400
	push hl			;4b85
	ld hl,0e408h		;4b86
	call SUBE_EL_TALLER		;4b89   ; se sube tal cual
	call DESPLAZA_LOS_CARACTERES		;4b8c   ; y luego se desplaza y se vuelve a subir, tantas veces como diga 0xE00A
	pop hl			;4b8f
	pop bc			;4b90
	djnz SUBE_CARACTERES_GIRADOS		;4b91   ; tantos bloques como diga B
	ret			;4b93
COPIA_AL_TALLER:
	ld de,0e408h		;4b94
COPIA_AL_TALLER_BUCLE:
	ld bc,00008h		;4b97   ; ocho bytes: un caracter
	ldir		;4b9a
	ld a,(hl)			;4b9c
	cp 011h		;4b9d   ; el 0x11 cierra cada bloque de caracteres
	jr nz,COPIA_AL_TALLER_BUCLE		;4b9f
	ld (de),a			;4ba1   ; el 0x11 se copia tambien, para cerrar el taller
	inc hl			;4ba2
	ret			;4ba3
DESPLAZA_LOS_CARACTERES:
	ld a,(0e00ah)		;4ba4
	ld b,003h		;4ba7   ; sin desplazamiento apuntado se hacen tres vueltas
	or a			;4ba9
	jr z,DESPLAZA_UNA_VUELTA		;4baa
	ld b,a			;4bac
DESPLAZA_UNA_VUELTA:
	push bc			;4bad
	ld hl,0e400h		;4bae
DESPLAZA_CARACTER:
	ld b,008h		;4bb1   ; los ocho bytes del caracter, uno a uno
DESPLAZA_BYTE:
	push bc			;4bb3
	xor a			;4bb4
	ld c,a			;4bb5
	ld a,(0e00ah)		;4bb6   ; 0xE00A dice cuantas copias hacen falta, y de cuantos bits
	ld b,002h		;4bb9   ; dos bits por vuelta dan cuatro copias; cuatro bits dan dos
	or a			;4bbb
	jr z,DESPLAZA_BITS		;4bbc
	ld b,004h		;4bbe
DESPLAZA_BITS:
	sla (hl)		;4bc0   ; dos bits o cuatro, segun cuantas copias hagan falta
	rl c		;4bc2
	djnz DESPLAZA_BITS		;4bc4   ; ocho bytes por caracter, y lo que sale se guarda para el de al lado
	ld de,00008h		;4bc6   ; lo que sale por la izquierda de un caracter entra por la derecha del anterior
	or a			;4bc9
	sbc hl,de		;4bca
	ld a,(hl)			;4bcc
	or c			;4bcd
	ld (hl),a			;4bce
	add hl,de			;4bcf
	inc hl			;4bd0
	pop bc			;4bd1
	djnz DESPLAZA_BYTE		;4bd2   ; ocho bytes por caracter
	ld a,(hl)			;4bd4
	cp 011h		;4bd5   ; y se sigue hasta el 0x11 que cierra el bloque
	jr nz,DESPLAZA_CARACTER		;4bd7
	ld hl,0e400h		;4bd9
	call SUBE_EL_TALLER		;4bdc
	pop bc			;4bdf
	djnz DESPLAZA_UNA_VUELTA		;4be0
	ld hl,0e400h		;4be2
	ld b,0a0h		;4be5   ; 0xA0 bytes: los veinte caracteres que caben en el taller
BORRA_EL_TALLER:
	xor a			;4be7
	ld (hl),a			;4be8
	inc hl			;4be9
	djnz BORRA_EL_TALLER		;4bea
	ret			;4bec
SUBE_EL_TALLER:
	ld b,008h		;4bed   ; el taller se sube de ocho en ocho bytes hasta dar con el 0x11
	call COPIA_A_VRAM_YA		;4bef
	ld a,(hl)			;4bf2
	cp 011h		;4bf3
	jr nz,SUBE_EL_TALLER		;4bf5
	ret			;4bf7
CARGA_LISTA_DE_BLOQUES:		; C bloques seguidos de (direccion de VRAM, cuantos, datos)
	ld d,(hl)			;4bf8   ; cada bloque son dos bytes de direccion, uno de cuantos y los datos detras
	inc hl			;4bf9
	ld e,(hl)			;4bfa
	inc hl			;4bfb
	ld b,(hl)			;4bfc
	inc hl			;4bfd
	call COPIA_A_VRAM		;4bfe
	dec c			;4c01   ; tantos bloques como diga C
	jr nz,CARGA_LISTA_DE_BLOQUES		;4c02
	ret			;4c04
PASO_DEL_ROTULO_DEL_TITULO:		; Mueve el rotulo que se desliza en la pantalla de titulo
	ld de,(0e039h)		;4c05   ; 0xE039 lleva la casilla por la que va el rotulo
	ld a,(0e03ch)		;4c09
	or a			;4c0c
	jr nz,ROTULO_PASO_2		;4c0d
	ld hl,00022h		;4c0f   ; el primer tramo sube 0x22 casillas: una fila y dos columnas
	call ROTULO_RESTA		;4c12
	jr ROTULO_GUARDA		;4c15
ROTULO_PASO_2:
	dec a			;4c17
	jr nz,ROTULO_PASO_3		;4c18
	ld hl,00060h		;4c1a   ; el segundo, 0x60: tres filas justas
	call ROTULO_RESTA		;4c1d
	jr ROTULO_GUARDA		;4c20
ROTULO_PASO_3:
	dec a			;4c22
	jr nz,ROTULO_PASO_4		;4c23
	ld hl,0001eh		;4c25   ; el tercero, 0x1E: casi una fila
	call ROTULO_RESTA		;4c28
	jr ROTULO_GUARDA		;4c2b
ROTULO_PASO_4:
	ld hl,00020h		;4c2d   ; y el cuarto baja una fila entera
	add hl,de			;4c30
	ex de,hl			;4c31
	call ROTULO_PINTA_DOS		;4c32   ; el rotulo son dos casillas, que se pintan juntas
ROTULO_GUARDA:
	ld (0e039h),de		;4c35
	ld hl,0e03bh		;4c39   ; 0xE03B es lo que falta para el paso siguiente
	dec (hl)			;4c3c   ; sin llegar a cero no toca mover
	ret nz			;4c3d
	push hl			;4c3e
	ld a,(0e03dh)		;4c3f
	ld hl,04c91h		;4c42   ; el retardo de cada tramo sale de la lista de 0x4C91
	call SUMA_A_HL		;4c45
	ld a,(hl)			;4c48
	ld (0e03bh),a		;4c49
	pop hl			;4c4c
ROTULO_CUENTA:
	inc hl			;4c4d
	inc (hl)			;4c4e   ; cuatro pasos por tramo
	ld a,004h		;4c4f
	cp (hl)			;4c51
	ret nz			;4c52
ROTULO_SALTA_LINEA:
	push hl			;4c53
	ld hl,00042h		;4c54   ; 0x42 casillas: dos filas mas abajo y dos columnas a la derecha
	add hl,de			;4c57
	ex de,hl			;4c58
	ld (0e039h),de		;4c59
	pop hl			;4c5d
	ld (hl),000h		;4c5e
	inc hl			;4c60
	inc (hl)			;4c61   ; y el paso siguiente de la animacion
	ld a,(hl)			;4c62
	inc hl			;4c63
	ld (hl),001h		;4c64
	cp 006h		;4c66   ; y al llegar al sexto tramo, el rotulo se queda quieto
	ret z			;4c68
ROTULO_VUELVE:
	ld (hl),000h		;4c69   ; al pasar de tramo se coge el retardo nuevo de la lista
	dec hl			;4c6b
	ld a,(hl)			;4c6c
	ld hl,04c91h		;4c6d
	call SUMA_A_HL		;4c70
	ld a,(hl)			;4c73
	ld (0e03bh),a		;4c74
	ret			;4c77
ROTULO_RESTA:
	ex de,hl			;4c78
	or a			;4c79
	sbc hl,de		;4c7a
	ex de,hl			;4c7c
ROTULO_PINTA_DOS:
	ld b,002h		;4c7d   ; el rotulo se pinta con el caracter 0xFC, dos casillas por fila y dos filas
	ld c,0fch		;4c7f
	call RELLENA_VRAM		;4c81
	ld hl,00020h		;4c84
	add hl,de			;4c87
	ex de,hl			;4c88
	ld b,002h		;4c89
	ld c,0fch		;4c8b
	call RELLENA_VRAM		;4c8d
	ret			;4c90

; ----------------------------------------------------------------------
; DATOS pasos_del_rotulo: Los seis retardos de la animacion del rotulo de la
;   pantalla de titulo (0xE03B), elegidos por 0xE03D
;   0x4c91..0x4c97  (6 bytes)
DATA_pasos_del_rotulo:
	defb 001h,003h,005h,007h,009h,00bh	; 4c91

; ======================================================================
; CODIGO 0x4c97..0x4cdd  (70 bytes)
; ======================================================================


COPIA_VRAM_A_VRAM:		; Copia 0xFFF bytes de la VRAM a otro sitio de la VRAM, byte a byte: asi los tres tercios de la pantalla quedan cargados iguales
	ld bc,00fffh		;4c97   ; copiar VRAM a VRAM, byte a byte, leyendo y escribiendo
COPIA_VRAM_BUCLE:
	call PON_DIRECCION_VDP		;4c9a   ; copiar dentro de la VRAM va byte a byte: leer, cambiar direccion y escribir
	inc de			;4c9d
	in a,(098h)		;4c9e
	ex de,hl			;4ca0
	push af			;4ca1
	call PON_DIRECCION_VDP		;4ca2   ; y la direccion de escritura hay que ponerla otra vez en cada byte
	inc de			;4ca5
	pop af			;4ca6
	out (098h),a		;4ca7
	ex de,hl			;4ca9
	dec bc			;4caa
	ld a,b			;4cab
	or c			;4cac
	jr nz,COPIA_VRAM_BUCLE		;4cad
	ret			;4caf
ESPERA:		; Deja A en 0xE018 y espera a que la interrupcion lo baje a cero. Cada punto son 32 fotogramas, no uno
	ld hl,0e018h		;4cb0
	ld (hl),a			;4cb3   ; 0xE018 lo baja la interrupcion UNA VEZ CADA 32 fotogramas, no cada uno
ESPERA_BUCLE:
	ld a,(hl)			;4cb4
	or a			;4cb5
	jr nz,ESPERA_BUCLE		;4cb6
	ret			;4cb8
APAGA_LOS_SPRITES:		; Manda los 32 sprites fuera de la pantalla (Y = 0xD1)
	ld de,07b00h		;4cb9   ; 0x7B00 es la tabla de atributos de los sprites
	ld b,080h		;4cbc   ; 0x80 bytes: los 32 sprites de cuatro bytes
	ld c,0d1h		;4cbe   ; se rellena entero con 0xD1, que como Y deja el sprite fuera de la pantalla
	call RELLENA_VRAM		;4cc0
	ret			;4cc3
LEE_EPOCA:		; Deja en A la epoca del jugador que juega (0xE180/0xE181)
	ld hl,0e180h		;4cc4   ; 0xE180/0xE181: la epoca de cada jugador
LEE_POR_JUGADOR:		; Deja en A el byte de (HL + jugador), y deja HL apuntandolo
	call LEE_JUGADOR		;4cc7
	call SUMA_A_HL		;4cca
	ld a,(hl)			;4ccd
	ret			;4cce
ESCRIBE_PSG:		; B parejas (registro, valor) desde 0x4CDD
	ld hl,04cddh		;4ccf
ESCRIBE_PSG_BUCLE:
	ld c,0a0h		;4cd2   ; el registro se elige por el 0xA0 y el valor va por el 0xA1
	outi		;4cd4   ; registro y valor, por los puertos 0xA0 y 0xA1
	ld c,0a1h		;4cd6
	outi		;4cd8
	djnz ESCRIBE_PSG_BUCLE		;4cda   ; tantas parejas como diga B
	ret			;4cdc

; ----------------------------------------------------------------------
; DATOS psg_al_arrancar: Doce bytes en parejas (registro del PSG, valor) que
;   escribe 0x4CCF: mezcla, ruido, los tres volumenes a cero y otra vez la
;   mezcla
;   0x4cdd..0x4ce9  (12 bytes)
DATA_psg_al_arrancar:
	defb 007h,0b8h	; 4cdd
	defb 006h,01eh	; 4cdf
	defb 008h,000h	; 4ce1
	defb 009h,000h	; 4ce3
	defb 00ah,000h	; 4ce5
	defb 007h,088h	; 4ce7

; ----------------------------------------------------------------------
; DATOS nubes_iniciales: Los 28 bytes que 0x4691 copia a 0xE210: la direccion
;   de las nubes y las nueve casillas de la tabla de nombres por las que
;   empiezan
;   0x4ce9..0x4d05  (28 bytes)
DATA_nubes_iniciales:
	defb 000h,000h,078h,000h	; 4ce9
	defb 001h,078h,028h,000h	; 4ced
	defb 078h,02fh,001h,079h	; 4cf1
	defb 003h,000h,079h,00bh	; 4cf5
	defb 001h,079h,034h,000h	; 4cf9
	defb 07ah,001h,001h,07ah	; 4cfd
	defb 029h,001h,07ah,032h	; 4d01

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho registros que escribe 0x4233: R0=02
;   (SCREEN 2), R1=E2 (16K, pantalla e interrupcion encendidas, sprites de
;   16x16), R2=0E (nombres en 0x3800), R3=7F y R4=07 (color en 0x0000 y
;   patrones en 0x2000), R5=76 (atributos de sprite en 0x3B00), R6=03
;   (patrones de sprite en 0x1800), R7=E1 (tinta 14 sobre fondo 1)
;   0x4d05..0x4d0d  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e1h	; 4d05  .....v..

; ======================================================================
; CODIGO 0x4d0d..0x4d2f  (34 bytes)
; ======================================================================


PINTA_BLOQUE_DE_FONDO:		; Un dibujo del fondo, en filas de tramos repetidos: cuantas filas, y por fila cuantos tramos de (cuantos, caracter)
	push bc			;4d0d   ; un dibujo del fondo: filas de tramos de (cuantos, caracter)
	inc hl			;4d0e
	ld c,(hl)			;4d0f
	inc hl			;4d10
PINTA_BLOQUE_FILA:
	push hl			;4d11
	ld b,(hl)			;4d12
	inc hl			;4d13
PINTA_BLOQUE_TRAMO:
	push bc			;4d14
	ld b,(hl)			;4d15   ; cada tramo es una pareja (cuantos, caracter)
	inc hl			;4d16
	ld a,(hl)			;4d17
	call RELLENA_VRAM_CON_A		;4d18
	inc hl			;4d1b
	pop bc			;4d1c
	djnz PINTA_BLOQUE_TRAMO		;4d1d
	pop hl			;4d1f
	dec c			;4d20
	jr nz,PINTA_BLOQUE_FILA		;4d21
	pop bc			;4d23
	ld a,(hl)			;4d24   ; y detras de la lista viene el salto a la fila siguiente
	rlca			;4d25
	call SUMA_A_HL		;4d26
	inc hl			;4d29
	ld a,(hl)			;4d2a   ; un 0xFF cierra el fondo
	inc a			;4d2b
	jr z,PINTA_BLOQUE_DE_FONDO		;4d2c
	ret			;4d2e

; ----------------------------------------------------------------------
; DATOS fondo_del_titulo: Cinco parejas (cuantos, caracter) que 0x42AD escribe
;   seguidas en la VRAM 0x0468: el fondo de la pantalla de titulo
;   0x4d2f..0x4d39  (10 bytes)
DATA_fondo_del_titulo:
	defb 0c8h,0f0h	; 4d2f
	defb 0d0h,040h	; 4d31
	defb 018h,000h	; 4d33
	defb 0c8h,070h	; 4d35
	defb 0f8h,0f0h	; 4d37

; ----------------------------------------------------------------------
; DATOS fondo_epoca_1: La lista de la epoca 1 para 0x4620: parejas (cuantos,
;   caracter), y un 0xFF hace que 0x4D0D pinte un bloque entero. Doce vueltas.
;   Los bytes de 0x4D3D los vuelve a leer 0x481C como la pareja con la que se
;   borra la pantalla al cambiar de epoca
;   0x4d39..0x4d61  (40 bytes)
DATA_fondo_epoca_1:
	defb 040h,0f4h,008h,0f0h,008h,004h,008h,030h,020h,0d4h,090h,084h,000h,0e4h,000h,0e4h	; 4d39  @......0 .......
	defb 030h,0e4h,098h,094h,0ffh,013h,003h,002h,094h,002h,0f4h,004h,064h,098h,094h,0ffh	; 4d49  0...........d...
	defb 013h,002h,006h,094h,002h,0f4h,098h,064h	; 4d59  .......d

; ----------------------------------------------------------------------
; DATOS fondo_epoca_2: Igual para la epoca 2, trece vueltas; 0x4D65 es la
;   pareja de borrado
;   0x4d61..0x4d82  (33 bytes)
DATA_fondo_epoca_2:
	defb 040h,0f5h,008h,0f0h,008h,005h,008h,060h,020h,0d5h,090h,085h,000h,0e5h,000h,0e5h	; 4d61  @......` .......
	defb 030h,0e5h,098h,085h,098h,095h,098h,085h,0ffh,013h,002h,004h,085h,004h,095h,098h	; 4d71  0...............
	defb 095h	; 4d81

; ----------------------------------------------------------------------
; DATOS fondo_epoca_3: Igual para la epoca 3, once vueltas; 0x4D86 es la
;   pareja de borrado
;   0x4d82..0x4dad  (43 bytes)
DATA_fondo_epoca_3:
	defb 040h,0fdh,008h,0f0h,008h,00dh,008h,0b0h,020h,0ddh,090h,08dh,000h,0edh,000h,0edh	; 4d82  @....... .......
	defb 030h,0edh,0ffh,013h,002h,004h,01dh,004h,0cdh,0ffh,013h,002h,002h,0cdh,006h,03dh	; 4d92  0..............=
	defb 098h,01dh,0ffh,013h,002h,006h,0cdh,002h,03dh,098h,03dh	; 4da2  ........=.=

; ----------------------------------------------------------------------
; DATOS fondo_epoca_4: Igual para la epoca 4, doce vueltas; 0x4DB1 es la
;   pareja de borrado
;   0x4dad..0x4dd3  (38 bytes)
DATA_fondo_epoca_4:
	defb 040h,0fch,008h,0f0h,008h,00ch,008h,070h,020h,0dch,090h,08ch,000h,0ech,000h,0ech	; 4dad  @......p .......
	defb 030h,0ech,098h,08ch,0ffh,013h,002h,001h,08ch,007h,0fch,098h,08ch,0ffh,013h,002h	; 4dbd  0...............
	defb 005h,08ch,003h,0fch,098h,0fch	; 4dcd

; ----------------------------------------------------------------------
; DATOS fondo_epoca_5: Igual para la epoca 5; 0x4DD7 es la pareja de borrado
;   0x4dd3..0x4deb  (24 bytes)
DATA_fondo_epoca_5:
	defb 040h,0f1h,008h,0f0h,008h,001h,008h,050h,020h,0d1h,090h,081h,000h,061h,000h,061h	; 4dd3  @......P ....a.a
	defb 030h,061h,000h,041h,000h,041h,0f8h,041h	; 4de3  0a.A.A.A

; ----------------------------------------------------------------------
; DATOS sprites_epoca_1: Siete grupos de tres bytes (cuantos, patron, color)
;   que 0x4665 reparte por la tabla de sprites de 0xE380. Son 21 sprites: el
;   jugador, los enemigos, los disparos y los rotulos
;   0x4deb..0x4e00  (21 bytes)
DATA_sprites_epoca_1:
	defb 001h,000h,00fh	; 4deb
	defb 001h,074h,004h	; 4dee
	defb 001h,078h,004h	; 4df1
	defb 007h,020h,003h	; 4df4
	defb 001h,06ch,00ah	; 4df7
	defb 004h,064h,001h	; 4dfa
	defb 006h,060h,001h	; 4dfd

; ----------------------------------------------------------------------
; DATOS sprites_epoca_2: Igual para la epoca 2
;   0x4e00..0x4e15  (21 bytes)
DATA_sprites_epoca_2:
	defb 001h,000h,00fh	; 4e00
	defb 001h,074h,004h	; 4e03
	defb 001h,078h,004h	; 4e06
	defb 007h,020h,006h	; 4e09
	defb 001h,06ch,008h	; 4e0c
	defb 004h,064h,001h	; 4e0f
	defb 006h,060h,001h	; 4e12

; ----------------------------------------------------------------------
; DATOS sprites_epoca_3: Igual para la epoca 3
;   0x4e15..0x4e2a  (21 bytes)
DATA_sprites_epoca_3:
	defb 001h,000h,00fh	; 4e15
	defb 001h,074h,004h	; 4e18
	defb 001h,078h,004h	; 4e1b
	defb 007h,020h,00bh	; 4e1e
	defb 001h,06ch,008h	; 4e21
	defb 004h,040h,001h	; 4e24
	defb 006h,060h,001h	; 4e27

; ----------------------------------------------------------------------
; DATOS sprites_epoca_4: Igual para la epoca 4
;   0x4e2a..0x4e3f  (21 bytes)
DATA_sprites_epoca_4:
	defb 001h,000h,00fh	; 4e2a
	defb 001h,074h,004h	; 4e2d
	defb 001h,078h,004h	; 4e30
	defb 007h,020h,007h	; 4e33
	defb 001h,06ch,008h	; 4e36
	defb 004h,064h,001h	; 4e39
	defb 006h,060h,001h	; 4e3c

; ----------------------------------------------------------------------
; DATOS sprites_epoca_5: Igual para la epoca 5
;   0x4e3f..0x4e54  (21 bytes)
DATA_sprites_epoca_5:
	defb 001h,000h,00fh	; 4e3f
	defb 001h,074h,004h	; 4e42
	defb 001h,078h,004h	; 4e45
	defb 007h,020h,005h	; 4e48
	defb 001h,06ch,00fh	; 4e4b
	defb 004h,064h,00ah	; 4e4e
	defb 006h,060h,00ah	; 4e51

; ----------------------------------------------------------------------
; DATOS teclas_a_joystick: Los dieciseis valores con los que 0x4A4C convierte
;   el nibble de la fila 8 del teclado -los cursores- en los mismos bits que
;   da el joystick
;   0x4e54..0x4e64  (16 bytes)
DATA_teclas_a_joystick:
	defb 000h,004h,001h,005h,002h,006h,000h,000h,008h,000h,009h,000h,00ah,000h,000h,000h	; 4e54  ................

; ----------------------------------------------------------------------
; DATOS rectangulos_de_choque: Seis rectangulos de cuatro bytes (Y minima, Y
;   maxima, X minima, X maxima) que usa 0x4B3E: cada clase de choque tiene el
;   suyo
;   0x4e64..0x4e7c  (24 bytes)
DATA_rectangulos_de_choque:
	defb 000h,00fh,000h,00fh	; 4e64
	defb 000h,01ah,004h,00ch	; 4e68
	defb 0fbh,005h,0fbh,005h	; 4e6c
	defb 0f6h,00ah,0f6h,00ah	; 4e70
	defb 0eah,00ch,0f6h,00ah	; 4e74
	defb 0ffh,01ah,0ffh,00fh	; 4e78

; ----------------------------------------------------------------------
; DATOS anos_de_las_epocas: Los cinco anos que se pintan en el marcador,
;   cuatro caracteres cada uno: 1910, 1940, 1970, 1984 y 2001. Los escribe
;   0x44A3 en la VRAM 0x395A
;   0x4e7c..0x4e90  (20 bytes)
DATA_anos_de_las_epocas:
	defb 0e6h,0eeh,0e6h,0e5h	; 4e7c
	defb 0e6h,0eeh,0e9h,0e5h	; 4e80
	defb 0e6h,0eeh,0ech,0e5h	; 4e84
	defb 0e6h,0eeh,0edh,0e9h	; 4e88
	defb 0e7h,0e5h,0e5h,0e6h	; 4e8c

; ----------------------------------------------------------------------
; DATOS rotulo_del_titulo: Para 0x4A72: los dos renglones del dibujo grande de
;   TIME PILOT, hechos con los caracteres 0x8D a 0xBF
;   0x4e90..0x4eab  (27 bytes)
DATA_rotulo_del_titulo:
	defb 09ah,09bh,09ch,09dh,09eh,09fh,0a0h,0a1h,0a2h,0a3h,0a4h,0a5h,08fh,090h,091h,092h	; 4e90  ................
	defb 093h,094h,095h,096h,097h,098h,099h,000h,000h,08dh,08eh	; 4ea0  ...........

; ----------------------------------------------------------------------
; DATOS pantalla_fija: Para 0x4A72: lo que sale en la pantalla de titulo y no
;   cambia -el dibujo grande, el copyright de KONAMI y el 1983-, en cuatro
;   renglones
;   0x4eab..0x4ee8  (61 bytes)
DATA_pantalla_fija:
	defb 078h,08ah,0a6h,0a7h,0a8h,0a9h,0aah,0abh,0ach,0adh,0aeh,0afh,0b0h,0b1h,0b2h,0ffh	; 4eab  x...............
	defb 078h,0aah,0b3h,0b4h,0b5h,0b6h,0b7h,0b8h,0b9h,0bah,0bbh,0bch,0bdh,0beh,0bfh,0ffh	; 4ebb  x...............
	defb 078h,0ebh,0f3h,0f4h,0f5h,0f6h,0f7h,0f8h,000h,0e6h,0eeh,0edh,0e8h,0ffh,079h,06bh	; 4ecb  x.............yk
	defb 0d0h,0d1h,0d2h,0d3h,000h,0d6h,0d4h,0d1h,0d4h,0c7h,0c6h,0ffh,0ffh	; 4edb  .............

; ----------------------------------------------------------------------
; DATOS menu_opcion_1: Para 0x4A72: el primer renglon del menu. Lleva el 1,
;   dos caracteres de letra pequena, 1PLAYER, otros dos de letra pequena y
;   JOYSTICK
;   0x4ee8..0x4f05  (29 bytes)
DATA_menu_opcion_1:
	defb 079h,0e4h,0d8h,0cbh,0cch,0cdh,000h,0d8h,0d0h,0d1h,0d2h,0d3h,0d4h,0d5h,000h,000h	; 4ee8  y...............
	defb 0c3h,0c4h,000h,0c5h,0ceh,0d3h,0d6h,0c6h,0cfh,0c7h,0c8h,0ffh,0ffh	; 4ef8  .............

; ----------------------------------------------------------------------
; DATOS menu_opcion_2: El segundo renglon: 2PLAYERS con JOYSTICK
;   0x4f05..0x4f22  (29 bytes)
DATA_menu_opcion_2:
	defb 07ah,024h,0d9h,0cbh,0cch,0cdh,000h,0d9h,0d0h,0d1h,0d2h,0d3h,0d4h,0d5h,0d6h,000h	; 4f05  z$..............
	defb 0c3h,0c4h,000h,0c5h,0ceh,0d3h,0d6h,0c6h,0cfh,0c7h,0c8h,0ffh,0ffh	; 4f15  .............

; ----------------------------------------------------------------------
; DATOS menu_opcion_3: El tercero: 1PLAYER con KEYBOARD
;   0x4f22..0x4f3f  (29 bytes)
DATA_menu_opcion_3:
	defb 07ah,064h,0dah,0cbh,0cch,0cdh,000h,0d8h,0d0h,0d1h,0d2h,0d3h,0d4h,0d5h,000h,000h	; 4f22  zd..............
	defb 0c3h,0c4h,000h,0c8h,0d4h,0d3h,0c9h,0ceh,0d2h,0d5h,0cah,0ffh,0ffh	; 4f32  .............

; ----------------------------------------------------------------------
; DATOS menu_opcion_4: El cuarto: 2PLAYERS con KEYBOARD
;   0x4f3f..0x4f5c  (29 bytes)
DATA_menu_opcion_4:
	defb 07ah,0a4h,0dbh,0cbh,0cch,0cdh,000h,0d9h,0d0h,0d1h,0d2h,0d3h,0d4h,0d5h,0d6h,000h	; 4f3f  z...............
	defb 0c3h,0c4h,000h,0c8h,0d4h,0d3h,0c9h,0ceh,0d2h,0d5h,0cah,0ffh,0ffh	; 4f4f  .............

; ----------------------------------------------------------------------
; DATOS rotulo_jugador_1: Para 0x4A72: "PLAYER 1" en el centro de la pantalla.
;   0x442D entra en 0x4F5D, un byte mas alla, para escribirlo en otro sitio
;   0x4f5c..0x4f68  (12 bytes)
DATA_rotulo_jugador_1:
	defb 079h,049h,0deh,0dfh,0e0h,0e1h,0e2h,0e3h,000h,0e6h,0ffh,0ffh	; 4f5c  yI..........

; ----------------------------------------------------------------------
; DATOS rotulo_jugador_2: Igual con "PLAYER 2"
;   0x4f68..0x4f74  (12 bytes)
DATA_rotulo_jugador_2:
	defb 079h,049h,0deh,0dfh,0e0h,0e1h,0e2h,0e3h,000h,0e7h,0ffh,0ffh	; 4f68  yI..........

; ----------------------------------------------------------------------
; DATOS rotulo_fin_de_partida: Para 0x4A72: cuatro renglones con "PLAYER 1" y
;   "GAME OVER" y las lineas en blanco de alrededor
;   0x4f74..0x4fa3  (47 bytes)
DATA_rotulo_fin_de_partida:
	defb 079h,045h,0feh,00eh,000h,0ffh,079h,065h,000h,000h,000h,0deh,0dfh,0e0h,0e1h,0e2h	; 4f74  yE....ye........
	defb 0e3h,000h,0e6h,000h,000h,000h,0ffh,079h,085h,000h,000h,0f0h,0e0h,0f1h,0e2h,000h	; 4f84  .......y........
	defb 000h,0dch,0f2h,0e2h,0e3h,000h,000h,0ffh,079h,0a5h,0feh,00eh,000h,0ffh,0ffh	; 4f94  ........y......

; ----------------------------------------------------------------------
; DATOS marcador: Para 0x4A72: el marcador entero -HI, 1P, 2P con sus seis
;   ceros, el ano de la epoca, PLAYER y el copyright-. Los dos caracteres de
;   0x4FB0 ("1P") y los de 0x4FBB ("2P") se vuelven a leer sueltos para
;   encender y apagar el rotulo del jugador que juega
;   0x4fa3..0x4fe9  (70 bytes)
DATA_marcador:
	defb 078h,039h,0efh,0ddh,0ffh,078h,059h,0feh,006h,0e5h,0ffh,078h,099h,0e6h,0deh,0ffh	; 4fa3  x9...xY....x....
	defb 078h,0b9h,0feh,006h,0e5h,0ffh,078h,0f9h,0e7h,0deh,0ffh,079h,019h,0feh,006h,0e5h	; 4fb3  x.....x....y....
	defb 0ffh,079h,059h,0fah,0e6h,0eeh,000h,000h,0f9h,0ffh,07ah,019h,0deh,0dfh,0e0h,0e1h	; 4fc3  .yY.......z.....
	defb 0e2h,0e3h,0ffh,07ah,099h,0f3h,0f4h,0f5h,0f6h,0f7h,0f8h,0ffh,07ah,0d9h,000h,000h	; 4fd3  ...z........z...
	defb 0e6h,0eeh,0edh,0e8h,0ffh,0ffh	; 4fe3

; ======================================================================
; CODIGO 0x4fe9..0x5197  (430 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL FONDO QUE SE MUEVE. Las nueve nubes son caracteres de la tabla de nombres, no sprites: cada fotograma se borran, se les suma el desplazamiento que toca a la direccion de vuelo y se vuelven a pintar. Al llegar al borde dan la vuelta.
; ----------------------------------------------------------------------
PASO_DEL_FONDO:
	ld hl,0e108h		;4fe9   ; 0xE108 cuenta los pasos del desplazamiento del fondo
	inc (hl)			;4fec
	ld hl,0e101h		;4fed
	ld a,(0e009h)		;4ff0   ; un paso de fondo cada dieciseis fotogramas
	and 00fh		;4ff3
	jp nz,FONDO_GIRA		;4ff5
	ld a,(0e146h)		;4ff8   ; el fondo se mueve en la direccion CONTRARIA a la del avion: mas ocho de dieciseis
	add a,008h		;4ffb
	and 00fh		;4ffd
	ld (hl),a			;4fff
FONDO_CUENTA:
	inc hl			;5000
	dec (hl)			;5001   ; 0xE102 es lo que falta para el siguiente paso de fondo
	ret nz			;5002
	dec hl			;5003
	dec hl			;5004
	bit 0,(hl)		;5005   ; el bit 0 de 0xE100 dice si el fondo esta acelerando
	inc hl			;5007
	inc hl			;5008
	inc hl			;5009
	jp nz,FONDO_ACELERA		;500a
	dec (hl)			;500d   ; y 0xE103 va bajando hasta que se llega a la velocidad de crucero
	jr nz,FONDO_LEE_VELOCIDAD		;500e
	ld a,001h		;5010
	ld (0e100h),a		;5012   ; al acabar la aceleracion el bit 0 se queda solo
FONDO_LEE_VELOCIDAD:
	ld a,(hl)			;5015
	push hl			;5016
	ld hl,05217h		;5017   ; la velocidad del fondo sale de 0xE103
	call SUMA_A_HL		;501a
	ld a,(hl)			;501d
	pop hl			;501e
	dec hl			;501f
	ld (hl),a			;5020
	dec hl			;5021
	ld c,(hl)			;5022
	ld a,(0e108h)		;5023
	rrca			;5026   ; los pasos impares redondean para el otro lado: asi las diagonales no cojean
	jr c,FONDO_REDONDEA		;5027
	rr c		;5029
	jr FONDO_DIRECCION		;502b
FONDO_REDONDEA:
	rr c		;502d
	jr nc,FONDO_DIRECCION		;502f
	inc c			;5031
FONDO_DIRECCION:
	ld a,c			;5032   ; la direccion queda en tres bits, de 0 a 7
	and 007h		;5033   ; ocho rumbos: los tres bits de abajo
	ld c,a			;5035
	push bc			;5036
	cp 002h		;5037   ; arriba y abajo no necesitan correccion
	jr z,FONDO_MUEVE_LAS_NUBES		;5039
	cp 006h		;503b   ; lo mismo con el rumbo contrario
	jr z,FONDO_MUEVE_LAS_NUBES		;503d
	inc a			;503f
	and 004h		;5040
	ld c,a			;5042
FONDO_MUEVE_AL_JUGADOR:
	ld hl,0e200h		;5043   ; el bicho grande tambien se mueve con el fondo
	ld a,(hl)			;5046
	and 0e0h		;5047   ; los tres bits altos de la ficha dicen de que clase es
	cp 080h		;5049
	jr nz,FONDO_MUEVE_LAS_NUBES		;504b
	inc hl			;504d
	ld d,(hl)			;504e
	inc hl			;504f
	ld e,(hl)			;5050
	inc hl			;5051
	ld a,(hl)			;5052
	push hl			;5053
	bit 2,a		;5054   ; el bit 2 de la ficha elige entre las dos tablas de desplazamiento
	ld hl,05197h		;5056   ; la tabla de desplazamientos: caracter y salto sobre la tabla de nombres
	jr z,FONDO_LEE_TABLA		;5059
	ld hl,051d7h		;505b
FONDO_LEE_TABLA:
	res 2,a		;505e
	rlca			;5060   ; dieciseis bytes por direccion, dos por cada uno de los ocho rumbos
	rlca			;5061
	rlca			;5062
	rlca			;5063
	call SUMA_A_HL		;5064
	ld a,c			;5067
	rlca			;5068
	call SUMA_A_HL		;5069   ; y dentro de cada tabla, dos bytes por rumbo
	ld a,(hl)			;506c
	inc hl			;506d
	ld l,(hl)			;506e
	ld h,000h		;506f
	bit 7,l		;5071   ; el salto es con signo: con el bit 7 puesto, hacia atras
	jr z,FONDO_SUMA		;5073
	dec h			;5075   ; el signo se extiende poniendo H a 0xFF
FONDO_SUMA:
	add hl,de			;5076
	ex de,hl			;5077
	pop hl			;5078
	ld (hl),a			;5079   ; y la ficha se queda con el caracter y la casilla nuevos
	dec hl			;507a
	ld (hl),e			;507b
	dec hl			;507c
	ld (hl),d			;507d
	ld b,a			;507e
	call BICHO_GRANDE_PINTA		;507f   ; y el bicho grande se repinta en su casilla nueva
FONDO_MUEVE_LAS_NUBES:
	pop bc			;5082   ; y las nueve nubes, una a una
	ld hl,0e210h		;5083
	ld a,(hl)			;5086   ; la nube 0 lleva la direccion que valen todas
	push hl			;5087
	rlca			;5088   ; la nube 0 marca el rumbo, y las otras ocho la copian
	rlca			;5089
	rlca			;508a
	rlca			;508b
	ld hl,05197h		;508c
	call SUMA_A_HL		;508f
	ld a,c			;5092
	rlca			;5093
	call SUMA_A_HL		;5094
	ld a,(hl)			;5097
	inc hl			;5098
	ld l,(hl)			;5099
	ld h,000h		;509a
	bit 7,l		;509c
	jr z,NUBES_GUARDA		;509e
	dec h			;50a0
NUBES_GUARDA:
	ex de,hl			;50a1
	pop hl			;50a2
	ld (hl),a			;50a3
	ld hl,0e212h		;50a4
	ld b,009h		;50a7   ; nueve nubes en el cielo
NUBE_SIGUIENTE:
	push bc			;50a9   ; las nueve nubes se corren todas lo mismo
	push hl			;50aa
	ld a,(hl)			;50ab
	inc hl			;50ac
	ld l,(hl)			;50ad
	ld h,a			;50ae
	add hl,de			;50af
	ld a,l			;50b0
	and 01fh		;50b1   ; al llegar a la columna 24 la nube da la vuelta
	cp 018h		;50b3
	jr nz,NUBE_BORDE_DERECHO		;50b5
	ld a,l			;50b7
	and 0e0h		;50b8
	jr NUBE_PON_L		;50ba
NUBE_BORDE_DERECHO:
	cp 01fh		;50bc   ; y por la columna 31, que es la de la vuelta
	jr nz,NUBE_MIRA_FILA		;50be
	ld a,l			;50c0
	add a,018h		;50c1   ; se salta al otro lado sumando las 24 columnas del area
	jr nc,NUBE_PON_L		;50c3
	inc h			;50c5
NUBE_PON_L:
	ld l,a			;50c6
NUBE_MIRA_FILA:
	ld a,h			;50c7
	cp 077h		;50c8   ; y lo mismo por arriba y por abajo, entre las filas 0x77 y 0x7B
	jr nz,NUBE_ARRIBA		;50ca
	inc h			;50cc
	inc h			;50cd
	inc h			;50ce
NUBE_ARRIBA:
	cp 07bh		;50cf
	jr nz,NUBE_GUARDA		;50d1
	dec h			;50d3
	dec h			;50d4
	dec h			;50d5
NUBE_GUARDA:
	ld b,h			;50d6   ; la casilla nueva se guarda en la ficha de la nube
	ld c,l			;50d7
	pop hl			;50d8
	ld (hl),b			;50d9
	inc hl			;50da
	ld (hl),c			;50db
	inc hl			;50dc
	inc hl			;50dd
	pop bc			;50de
	djnz NUBE_SIGUIENTE		;50df
	exx			;50e1   ; el juego alterno de registros se usa para llevar dos punteros a la vez
	ld a,(0e210h)		;50e2
	ld b,a			;50e5
	ld hl,06921h		;50e6   ; el dibujo de la nube depende de por donde se vuele: cuatro juegos de 24
	or a			;50e9
	jr z,NUBE_PATRONES		;50ea
	xor a			;50ec
NUBE_INDICE:
	add a,018h		;50ed   ; 24 caracteres por juego
	djnz NUBE_INDICE		;50ef
	call SUMA_A_HL		;50f1
NUBE_PATRONES:
	ex de,hl			;50f4
	ld a,(0e210h)		;50f5
	ld hl,06981h		;50f8   ; y el segundo juego va en grupos de dieciseis
	rlca			;50fb
	rlca			;50fc
	rlca			;50fd
	rlca			;50fe
	call SUMA_A_HL		;50ff
	exx			;5102
PINTA_LAS_NUBES:
	ld a,001h		;5103   ; 0xE22F avisa de que hay que repintar las nubes
	ld (0e22fh),a		;5105
	ld hl,0e213h		;5108
	ld b,009h		;510b   ; nueve nubes otra vez
PINTA_NUBE:
	push bc			;510d   ; cada nube va por su cuenta: nueve fichas seguidas
	push hl			;510e
	ld e,(hl)			;510f   ; cada nube son tres bytes: su desplazamiento y su casilla
	dec hl			;5110
	ld d,(hl)			;5111
	dec hl			;5112
	ld a,(hl)			;5113
	exx			;5114
	or a			;5115
	jr z,PINTA_NUBE_SIN_DESPLAZAR		;5116
	push de			;5118
	ld b,006h		;5119   ; la nube desplazada ocupa dos filas mas
	jr PINTA_NUBE_FILAS		;511b

; ----------------------------------------------------------------------
; EL BORRADO Y EL PINTADO DE LAS NUBES.
; ----------------------------------------------------------------------
PINTA_NUBE_SIN_DESPLAZAR:
	push hl			;511d
	ld b,004h		;511e   ; sin desplazar son cuatro filas; desplazada, seis
PINTA_NUBE_FILAS:
	exx			;5120
	pop hl			;5121
	ld c,004h		;5122   ; cuatro casillas de ancho
PINTA_NUBE_FILA:
	exx			;5124
	ld a,b			;5125
	exx			;5126
	ld b,a			;5127
	push de			;5128
PINTA_NUBE_PONE:
	call PON_DIRECCION_VDP		;5129
PINTA_NUBE_BYTE:
	ld a,(hl)			;512c   ; aqui las nubes se escriben sin mirar lo que hay debajo
	out (098h),a		;512d
	inc hl			;512f
	inc de			;5130
	ld a,e			;5131
	and 01fh		;5132   ; al pasar de la columna 24 se vuelve al principio de la fila
	cp 018h		;5134
	jr c,PINTA_NUBE_SIGUE		;5136
	ld a,e			;5138
	and 0e0h		;5139
	ld e,a			;513b
	djnz PINTA_NUBE_PONE		;513c
	jr PINTA_NUBE_BAJA		;513e
PINTA_NUBE_SIGUE:
	djnz PINTA_NUBE_BYTE		;5140
PINTA_NUBE_BAJA:
	pop de			;5142
	ex de,hl			;5143
	call SUMA_32_A_HL		;5144   ; de una fila a la siguiente, 32 casillas
	ex de,hl			;5147
	ld a,d			;5148
	cp 07bh		;5149   ; y al pasar del ultimo tercio, al primero
	jr nz,PINTA_NUBE_CUENTA		;514b
	ld d,078h		;514d   ; 0x78 es el primer tercio
PINTA_NUBE_CUENTA:
	dec c			;514f   ; cuatro filas por nube, o seis si va desplazada
	jr nz,PINTA_NUBE_FILA		;5150
	pop hl			;5152
	pop bc			;5153
	ld a,003h		;5154
	call SUMA_A_HL		;5156   ; tres bytes: la ficha de la nube siguiente
	djnz PINTA_NUBE		;5159
	ld a,(0e145h)		;515b   ; si el avion esta vivo, se le vuelve a poner el sprite encima
	and 0e0h		;515e
	jp z,JUGADOR_PON_SPRITE		;5160
	ret			;5163
FONDO_ACELERA:
	ld a,(hl)			;5164
	cp 003h		;5165   ; la velocidad sube de uno en uno hasta el tope, que es 3
	jp z,FONDO_LEE_VELOCIDAD		;5167
	inc (hl)			;516a
	jp FONDO_LEE_VELOCIDAD		;516b
FONDO_GIRA:
	ld a,(0e146h)		;516e   ; el fondo persigue a la direccion del avion, pero girado media vuelta
	add a,008h		;5171
	and 00fh		;5173
	cp (hl)			;5175
	jp z,FONDO_CUENTA		;5176
	inc hl			;5179
	dec (hl)			;517a   ; el giro del fondo no es instantaneo: hay una cuenta de por medio
	ret nz			;517b
	inc hl			;517c
	ld b,a			;517d
	xor a			;517e
	cp (hl)			;517f
	jr nz,FONDO_GIRA_YA		;5180
	inc (hl)			;5182   ; el giro se apunta y se hace en la vuelta de despues
	dec hl			;5183
	dec hl			;5184
	ld (hl),b			;5185
	inc hl			;5186
	inc hl			;5187
	jp FONDO_LEE_VELOCIDAD		;5188
FONDO_GIRA_YA:
	xor a			;518b
	dec (hl)			;518c
	jr nz,FONDO_GUARDA_ESTADO		;518d
	ld a,001h		;518f
FONDO_GUARDA_ESTADO:
	ld (0e100h),a		;5191   ; y al acabar el giro se vuelve a acelerar
	jp FONDO_LEE_VELOCIDAD		;5194

; ----------------------------------------------------------------------
; DATOS desplazamiento_de_las_nubes: Cuatro grupos de ocho parejas (caracter,
;   desplazamiento con signo sobre la tabla de nombres): con eso las nubes se
;   mueven en la direccion en la que vuela el avion. Lo lee 0x5056
;   0x5197..0x51d7  (64 bytes)
DATA_desplazamiento_de_las_nubes:
	defb 001h,0e0h,003h,0e0h,002h,001h,003h,000h,001h,000h,003h,0ffh,002h,000h,003h,0dfh	; 5197  ................
	defb 000h,000h,002h,001h,003h,000h,002h,021h,000h,020h,002h,020h,003h,0ffh,002h,000h	; 51a7  .......!. . ....
	defb 003h,0dfh,001h,0e0h,000h,000h,001h,000h,003h,0ffh,001h,0ffh,000h,0ffh,001h,0dfh	; 51b7  ................
	defb 002h,001h,000h,001h,001h,001h,000h,021h,002h,021h,000h,020h,001h,000h,000h,000h	; 51c7  .......!.!. ....

; ----------------------------------------------------------------------
; DATOS desplazamiento_de_las_nubes_2: El segundo juego, el que se usa cuando
;   el bit 2 del estado dice que el fondo va mas deprisa (0x505B)
;   0x51d7..0x5217  (64 bytes)
DATA_desplazamiento_de_las_nubes_2:
	defb 005h,0e0h,007h,0e0h,006h,000h,007h,000h,005h,000h,007h,0ffh,006h,0ffh,007h,0dfh	; 51d7  ................
	defb 004h,000h,006h,000h,007h,000h,006h,020h,004h,020h,006h,01fh,007h,0ffh,006h,0ffh	; 51e7  ....... . ......
	defb 007h,0e0h,005h,0e1h,004h,001h,005h,001h,007h,000h,005h,000h,004h,000h,005h,0e0h	; 51f7  ................
	defb 006h,000h,004h,001h,005h,001h,004h,021h,006h,020h,004h,020h,005h,000h,004h,000h	; 5207  .......!. . ....

; ----------------------------------------------------------------------
; DATOS velocidad_del_fondo: Los cuatro retardos del desplazamiento del fondo,
;   elegidos por 0xE103 en 0x5017
;   0x5217..0x521b  (4 bytes)
DATA_velocidad_del_fondo:
	defb 001h,001h,001h,001h	; 5217

; ======================================================================
; CODIGO 0x521b..0x52b9  (158 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; MUEVE A TODO EL MUNDO. Recorre las fichas de los actores -el jefe, los enemigos y los disparos enemigos- y a cada uno le suma su velocidad en la direccion en la que vuela.
; ----------------------------------------------------------------------
PASO_DE_LOS_ACTORES:
	ld hl,0e0a4h		;521b
	ld de,0e38ch		;521e
	exx			;5221
	ld a,(0e101h)		;5222   ; la direccion del fondo vale para todos: todo se mueve a la vez
	ld c,a			;5225
	call LEE_EPOCA		;5226
	ld de,03367h		;5229   ; la velocidad, en centesimas BCD: 0,33 y 0,67 hasta la epoca 3
	cp 004h		;522c
	jr c,ACTORES_PRIMER_GRUPO		;522e
	ld de,04983h		;5230   ; y 0,49 y 0,83 de la epoca 4 en adelante, o sea un cuarto mas rapido
ACTORES_PRIMER_GRUPO:
	ld hl,0e2d0h		;5233
	ld b,007h		;5236   ; siete fichas en el primer grupo
ACTORES_GRUPO_1:
	call MUEVE_UN_ACTOR		;5238
	call SUMA_10_A_HL		;523b   ; diez bytes por ficha
	djnz ACTORES_GRUPO_1		;523e
	exx			;5240
	ld hl,0e0b2h		;5241
	ld de,0e3a8h		;5244
	exx			;5247
	ld hl,0e2ceh		;5248   ; el pasajero se mueve como los demas, pero siempre a la velocidad lenta
	ld de,03367h		;524b
	call MUEVE_UN_ACTOR		;524e
	exx			;5251
	ld hl,0e0b4h		;5252
	ld de,0e3ach		;5255
	exx			;5258
	call LEE_EPOCA		;5259
	dec a			;525c
	ld hl,0e260h		;525d   ; en la epoca 1 este grupo son las bombas, y en las demas los misiles
	jr z,ACTORES_GRUPO_2		;5260
	ld hl,0e2a0h		;5262
ACTORES_GRUPO_2:
	ld b,004h		;5265   ; cuatro fichas en el segundo grupo
ACTORES_GRUPO_2_UNO:
	ld de,03367h		;5267
	call MUEVE_UN_ACTOR		;526a
	push hl			;526d
	call LEE_EPOCA		;526e
	pop hl			;5271
	dec a			;5272
	ld a,003h		;5273   ; y de paso cambia la anchura de la ficha: tres bytes o nueve
	jr z,ACTORES_GRUPO_2_SIGUIENTE		;5275
	ld a,009h		;5277
ACTORES_GRUPO_2_SIGUIENTE:
	call SUMA_A_HL		;5279   ; tres bytes por bomba, nueve por misil
	djnz ACTORES_GRUPO_2_UNO		;527c
	exx			;527e
	ld hl,0e0bch		;527f
	ld de,0e3bch		;5282
	exx			;5285
	ld hl,0e270h		;5286   ; y siete por disparo enemigo
	ld b,006h		;5289   ; seis fichas en el tercero
ACTORES_GRUPO_3:
	ld de,03367h		;528b
	call MUEVE_UN_ACTOR		;528e
	call SUMA_7_A_HL		;5291   ; siete bytes por disparo
	djnz ACTORES_GRUPO_3		;5294
	ret			;5296
MUEVE_UN_ACTOR:		; Si la ficha esta viva, salta a la rutina de su direccion
	ld a,(hl)			;5297   ; solo se mueve la ficha si su estado es 0x80, o sea viva
	and 0e0h		;5298
	cp 080h		;529a
	jr nz,ACTOR_LIBRE		;529c
	push hl			;529e
	ld hl,052b9h		;529f   ; dieciseis rutinas, una por direccion de vuelo
	ld a,c			;52a2
	call LEE_PALABRA_DE_TABLA		;52a3
	call SALTA_A_HL		;52a6
	inc hl			;52a9   ; cada ficha lleva dos bytes de acumulado y su sprite cuatro
	inc de			;52aa
	inc de			;52ab
	inc de			;52ac
	exx			;52ad
	pop hl			;52ae
	ret			;52af
ACTOR_LIBRE:
	exx			;52b0   ; con la ficha libre solo hay que saltarse su hueco
	inc hl			;52b1
	inc hl			;52b2
	inc de			;52b3
	inc de			;52b4
	inc de			;52b5
	inc de			;52b6
	exx			;52b7
	ret			;52b8

; ----------------------------------------------------------------------
; DATOS movimiento_por_direccion: Las dieciseis rutinas de 0x52D9 en adelante,
;   una por direccion de vuelo: cada una suma o resta las dos componentes de
;   la velocidad a la posicion, en BCD. Destino del despachador de 0x529F
;   0x52b9..0x52d9  (32 bytes)
DATA_movimiento_por_direccion:
	defw 052d9h	; 52b9  -> VUELA_0
	defw 052e0h	; 52bb  -> VUELA_1
	defw 052eah	; 52bd  -> VUELA_2
	defw 052f4h	; 52bf  -> VUELA_3
	defw 052feh	; 52c1  -> VUELA_4
	defw 05305h	; 52c3  -> VUELA_5
	defw 0530fh	; 52c5  -> VUELA_6
	defw 05319h	; 52c7  -> VUELA_7
	defw 05323h	; 52c9  -> VUELA_8
	defw 0532ah	; 52cb  -> VUELA_9
	defw 05334h	; 52cd  -> VUELA_10
	defw 0533eh	; 52cf  -> VUELA_11
	defw 05348h	; 52d1  -> VUELA_12
	defw 0534fh	; 52d3  -> VUELA_13
	defw 05359h	; 52d5  -> VUELA_14
	defw 05363h	; 52d7  -> VUELA_15

; ======================================================================
; CODIGO 0x52d9..0x545b  (386 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS DIECISEIS DIRECCIONES DE VUELO. Una rutina por direccion, todas iguales por dentro: sumar o restar a la posicion las dos componentes de la velocidad, la de arriba y la de al lado, en BCD y con acarreo a la casilla siguiente. Time Pilot no tiene angulos: tiene dieciseis.
; ----------------------------------------------------------------------
VUELA_0:		; Arriba del todo
	exx			;52d9
	call RESTA_Y_BAJA		;52da
	inc hl			;52dd
	inc de			;52de
	ret			;52df
VUELA_1:
	exx			;52e0   ; en diagonal se suman las dos componentes, la alta y la baja
	call RESTA_Y_BAJA		;52e1
	inc hl			;52e4
	inc de			;52e5
	call SUMA_Y_ALTA		;52e6
	ret			;52e9
VUELA_2:
	exx			;52ea   ; y en las diagonales de 45 grados, la baja dos veces
	call RESTA_Y_BAJA		;52eb
	inc hl			;52ee
	inc de			;52ef
	call SUMA_Y_BAJA		;52f0
	ret			;52f3
VUELA_3:
	exx			;52f4   ; direccion 3: a la derecha, con poca subida
	call RESTA_Y_ALTA		;52f5
	inc hl			;52f8
	inc de			;52f9
	call SUMA_Y_BAJA		;52fa
	ret			;52fd
VUELA_4:		; A la derecha del todo
	exx			;52fe
	inc hl			;52ff
	inc de			;5300
	call SUMA_Y_BAJA		;5301   ; direccion 4: a la derecha del todo
	ret			;5304
VUELA_5:
	exx			;5305   ; direccion 5: a la derecha, con poca bajada
	call SUMA_Y_ALTA		;5306
	inc hl			;5309
	inc de			;530a
	call SUMA_Y_BAJA		;530b
	ret			;530e
VUELA_6:
	exx			;530f   ; direccion 6: abajo y a la derecha, a 45 grados
	call SUMA_Y_BAJA		;5310
	inc hl			;5313
	inc de			;5314
	call SUMA_Y_BAJA		;5315
	ret			;5318
VUELA_7:
	exx			;5319   ; hacia abajo tirando a la derecha, con la componente corta en X
	call SUMA_Y_BAJA		;531a
	inc hl			;531d
	inc de			;531e
	call SUMA_Y_ALTA		;531f
	ret			;5322
VUELA_8:		; Abajo del todo
	exx			;5323
	call SUMA_Y_BAJA		;5324   ; direccion 8: abajo del todo
	inc hl			;5327
	inc de			;5328
	ret			;5329
VUELA_9:
	exx			;532a   ; direccion 9: hacia abajo, tirando a la izquierda
	call SUMA_Y_BAJA		;532b
	inc hl			;532e
	inc de			;532f
	call RESTA_Y_ALTA		;5330
	ret			;5333
VUELA_10:
	exx			;5334   ; direccion 10: abajo y a la izquierda, a 45 grados
	call SUMA_Y_BAJA		;5335
	inc hl			;5338
	inc de			;5339
	call RESTA_Y_BAJA		;533a
	ret			;533d
VUELA_11:
	exx			;533e   ; direccion 11: a la izquierda, con poca bajada
	call SUMA_Y_ALTA		;533f
	inc hl			;5342
	inc de			;5343
	call RESTA_Y_BAJA		;5344
	ret			;5347
VUELA_12:		; A la izquierda del todo
	exx			;5348
	inc hl			;5349
	inc de			;534a
	call RESTA_Y_BAJA		;534b   ; direccion 12: a la izquierda del todo
	ret			;534e
VUELA_13:
	exx			;534f   ; direccion 13: a la izquierda, con poca subida
	call RESTA_Y_ALTA		;5350
	inc hl			;5353
	inc de			;5354
	call RESTA_Y_BAJA		;5355
	ret			;5358
VUELA_14:
	exx			;5359   ; direccion 14: arriba y a la izquierda, a 45 grados
	call RESTA_Y_BAJA		;535a
	inc hl			;535d
	inc de			;535e
	call RESTA_Y_BAJA		;535f
	ret			;5362
VUELA_15:
	exx			;5363   ; direccion 15: hacia arriba, tirando a la izquierda
	call RESTA_Y_BAJA		;5364
	inc hl			;5367
	inc de			;5368
	call RESTA_Y_ALTA		;5369
	ret			;536c
SUMA_Y_ALTA:		; Suma la componente alta de la velocidad, en BCD, y acarrea a la casilla
	ld a,(hl)			;536d   ; la posicion tiene decimales: se lleva en BCD y `daa` detras de cada suma
	exx			;536e
	add a,d			;536f
	exx			;5370
	daa			;5371
	ld (hl),a			;5372
	ret nc			;5373   ; y cuando pasa de 100 centesimas, el pixel avanza uno
	ld a,(de)			;5374
	inc a			;5375
	ld (de),a			;5376
	ret			;5377
SUMA_Y_BAJA:
	ld a,(hl)			;5378   ; la componente baja, la de las direcciones rectas y las de 45 grados
	exx			;5379
	add a,e			;537a
	exx			;537b
	daa			;537c   ; el `daa` es lo que convierte la suma en centesimas
	ld (hl),a			;537d
	ret nc			;537e
	ld a,(de)			;537f
	inc a			;5380
	ld (de),a			;5381
	ret			;5382
RESTA_Y_ALTA:
	ld a,(hl)			;5383   ; y la alta, que es la corta: la que redondea las direcciones intermedias
	exx			;5384
	sub d			;5385
	exx			;5386
	daa			;5387   ; restar la componente corta es subir un poco
	ld (hl),a			;5388
	ret nc			;5389
	ld a,(de)			;538a
	dec a			;538b
	ld (de),a			;538c
	ret			;538d
RESTA_Y_BAJA:
	ld a,(hl)			;538e   ; restar es lo mismo, pero hacia arriba o hacia la izquierda
	exx			;538f
	sub e			;5390
	exx			;5391
	daa			;5392   ; y restar la larga, subir del todo o irse a la izquierda
	ld (hl),a			;5393
	ret nc			;5394
	ld a,(de)			;5395
	dec a			;5396
	ld (de),a			;5397
	ret			;5398

; ----------------------------------------------------------------------
; EL AVION DEL JUGADOR. Time Pilot no gira de golpe: el mando dice a que direccion se quiere ir, y el avion va girando un paso cada vez hasta llegar. Cada direccion tiene sus 32 bytes de patron de sprite, que se suben a la VRAM en cuanto cambia.
; ----------------------------------------------------------------------
PASO_DEL_JUGADOR:
	call MANDO_DE_LA_DEMO		;5399
	ld hl,0e145h		;539c
	ld a,(hl)			;539f   ; 0xE145 lleva el estado del avion: 0x80 volando, 0xA0 y 0xC0 explotando
	and 0e0h		;53a0
	jr z,JUGADOR_MIRA_MANDO		;53a2
	cp 0c0h		;53a4
	jp z,JUGADOR_EXPLOTA		;53a6
	cp 0a0h		;53a9
	jp z,JUGADOR_CAE		;53ab
	jp JUGADOR_ESPERA_A_REVIVIR		;53ae
JUGADOR_MIRA_MANDO:
	ld a,(0e009h)		;53b1
	and 00fh		;53b4
	ld (hl),a			;53b6
	jr z,JUGADOR_PON_SPRITE		;53b7
	inc hl			;53b9
	push hl			;53ba
	ld hl,0545bh		;53bb   ; el nibble del joystick, pasado a una de las dieciseis direcciones
	call SUMA_A_HL		;53be
	ld a,(hl)			;53c1
	pop hl			;53c2
	sub (hl)			;53c3
	ld b,000h		;53c4
	jr z,JUGADOR_GUARDA_GIRO		;53c6   ; si ya se va por ahi, no hay nada que girar
	ld b,001h		;53c8
	jr nc,JUGADOR_MIRA_VUELTA		;53ca
	neg		;53cc
	cp 008h		;53ce   ; el giro va por el lado corto: como mucho ocho pasos
	jr c,JUGADOR_GIRA_MENOS		;53d0
JUGADOR_GIRA_MAS:
	ld a,(hl)			;53d2
	inc a			;53d3
	jr JUGADOR_CARGA_SPRITE		;53d4
JUGADOR_MIRA_VUELTA:
	cp 00ah		;53d6
	jr c,JUGADOR_GIRA_MAS		;53d8
JUGADOR_GIRA_MENOS:
	ld b,002h		;53da
	ld a,(hl)			;53dc
	dec a			;53dd
JUGADOR_CARGA_SPRITE:
	and 00fh		;53de   ; la direccion se guarda en cuatro bits
	ld c,a			;53e0
	push hl			;53e1
	push bc			;53e2
	ld hl,06f2bh		;53e3   ; y el dibujo del avion se sube a la VRAM en cuanto cambia la direccion
	ld d,000h		;53e6
	rlca			;53e8
	rlca			;53e9
	rlca			;53ea
	rlca			;53eb
	rla			;53ec
	rl d		;53ed
	ld e,a			;53ef
	add hl,de			;53f0
	ld de,05800h		;53f1
	ld b,020h		;53f4
	call COPIA_A_VRAM		;53f6
	pop bc			;53f9
	pop hl			;53fa
	ld (hl),c			;53fb
JUGADOR_GUARDA_GIRO:
	dec hl			;53fc
	ld (hl),b			;53fd
JUGADOR_PON_SPRITE:
	ld de,0798bh		;53fe   ; el caracter 0x0C: la casilla de debajo del avion, encendida
	call PON_DIRECCION_VDP		;5401
	ld a,00ch		;5404
	out (098h),a		;5406
	ld hl,0e380h		;5408   ; el avion NO se mueve: su sprite siempre en Y=0x5C, X=0x54
	ld (hl),05ch		;540b
	inc hl			;540d
	ld (hl),054h		;540e
	inc hl			;5410
	ld (hl),000h		;5411
	ret			;5413
JUGADOR_EXPLOTA:
	ld a,(hl)			;5414   ; la explosion son dos pasos, uno cada ocho fotogramas
	and 007h		;5415
	jr z,JUGADOR_EXPLOTA_2		;5417
	dec (hl)			;5419
	ret			;541a
JUGADOR_EXPLOTA_2:
	ld a,00ch		;541b   ; patron 0x0C: el segundo paso de la explosion
	ld (0e382h),a		;541d
	ld a,0a4h		;5420
	ld (0e145h),a		;5422   ; estado 0xA4, o sea cayendo, con cuatro fotogramas
	ret			;5425
JUGADOR_CAE:
	ld a,(hl)			;5426
	and 007h		;5427
	jr z,JUGADOR_CAE_2		;5429
	dec (hl)			;542b
	ret			;542c
JUGADOR_CAE_2:
	ld a,0d1h		;542d   ; el sprite se va a Y=0xD1, fuera de la pantalla
	ld (0e380h),a		;542f
	ld a,090h		;5432
	ld (0e145h),a		;5434   ; estado 0x90: esperando a revivir, con dieciseis fotogramas
	ld de,0798bh		;5437
	call PON_DIRECCION_VDP		;543a
	ld a,00ah		;543d
	out (098h),a		;543f
	ret			;5441
JUGADOR_ESPERA_A_REVIVIR:
	ld a,(hl)			;5442
	and 01fh		;5443   ; esta espera es de 0x1F, no de 7 como las otras dos
	jr z,JUGADOR_REVIVE		;5445
	dec (hl)			;5447
	ret			;5448
JUGADOR_REVIVE:
	ld (hl),000h		;5449
	ld a,001h		;544b
	ld (0e004h),a		;544d   ; 0xE004 dice que se ha acabado la vida
	ld hl,0e052h		;5450   ; y si ademas se acabo la partida, se avisa al programa principal
	cp (hl)			;5453
	ret nz			;5454
	ld (hl),000h		;5455
	ld (0e050h),a		;5457
	ret			;545a

; ----------------------------------------------------------------------
; DATOS mando_a_direccion: El nibble del joystick pasado a direccion de vuelo
;   (0..15, 0 arriba y 4 a la derecha). 0xFF quiere decir que esa combinacion
;   no gira. La lee 0x53BB, y ademas 0x546B la usa como ruido para el mando de
;   la demo
;   0x545b..0x546b  (16 bytes)
DATA_mando_a_direccion:
	defb 0ffh,000h,008h,0ffh,00ch,00eh,00ah,0ffh,004h,002h,006h,0ffh,0ffh,0ffh,0ffh,0ffh	; 545b  ................

; ======================================================================
; CODIGO 0x546b..0x54f6  (139 bytes)
; ======================================================================


MANDO_DE_LA_DEMO:		; Cuando juega la demo, el "mando" sale de leer el propio codigo del cartucho: el registro R elige un byte a partir de 0x5399 y eso es lo que se toma por joystick
	ld a,(0e014h)		;546b   ; con la demo, el "joystick" sale del propio codigo del cartucho
	or a			;546e
	ret z			;546f
	ld hl,05399h		;5470
	call SUMA_A_HL		;5473   ; el desplazamiento sale de la direccion en la que ya se vuela
	ld a,r		;5476   ; el registro R -el de refresco de la memoria- hace de azar
	call SUMA_A_HL		;5478
	ld a,(hl)			;547b   ; y el byte que salga se mete tal cual en 0xE009
	ld (0e009h),a		;547c
	ret			;547f
DISPARA:		; Saca un disparo por la casilla que le toca a la direccion de vuelo
	call MIRA_EL_BOTON		;5480
	ret nc			;5483
	and 00fh		;5484   ; el nibble bajo son las cuatro direcciones del mando
	ld c,a			;5486
	ld a,(0e145h)		;5487   ; muerto no se dispara
	and 0e0h		;548a
	ret nz			;548c   ; con el jugador estrellado no hay disparo
	ld a,c			;548d
	ld hl,054f6h		;548e   ; la casilla y el caracter con el que sale el disparo, segun la direccion
	rlca			;5491   ; dos bytes por direccion: el desplazamiento y el caracter
	call SUMA_A_HL		;5492
	ld e,(hl)			;5495
	inc hl			;5496
	ld b,(hl)			;5497
	ld d,079h		;5498   ; 0x79 es el byte alto: la tabla de nombres del ultimo tercio
	push bc			;549a
	ld hl,0e230h		;549b
	ld b,008h		;549e   ; ocho disparos como mucho a la vez
DISPARA_BUSCA_HUECO:
	ld a,(hl)			;54a0   ; ocho fichas de disparo; si estan todas ocupadas, no sale
	or a			;54a1
	jr z,DISPARA_PON		;54a2
	call SUMA_4_A_HL		;54a4   ; cuatro bytes por ficha de disparo
	djnz DISPARA_BUSCA_HUECO		;54a7
	pop bc			;54a9
	ret			;54aa
DISPARA_PON:
	ld (hl),d			;54ab   ; la ficha se queda con la casilla y el caracter
	inc hl			;54ac
	ld (hl),e			;54ad
	inc hl			;54ae
	pop bc			;54af
	ld (hl),c			;54b0
	inc hl			;54b1
	ld (hl),b			;54b2
	res 6,d		;54b3   ; quitar el bit 6 de la direccion pone el VDP en modo LECTURA
	call PON_DIRECCION_VDP		;54b5   ; antes de pintar se lee la casilla: si no es cielo, el disparo no se dibuja
	in a,(099h)		;54b8   ; el byte que hay en la casilla se lee por el puerto 0x99
	set 6,d		;54ba
	cp 00bh		;54bc   ; si la casilla ya lleva algo que no es cielo, el disparo no se dibuja
	jr nc,DISPARA_SUENA		;54be
	call PON_DIRECCION_VDP		;54c0
	ld a,b			;54c3
	out (098h),a		;54c4
DISPARA_SUENA:
	ld a,(0e029h)		;54c6   ; el disparo solo suena si el canal 2 esta libre
	or a			;54c9
	ret nz			;54ca
	ld hl,07e69h		;54cb   ; y suena el disparo
	ld (0e028h),hl		;54ce
	ld a,009h		;54d1
	ld (0e02fh),a		;54d3   ; nueve fotogramas dura el disparo
	ret			;54d6
MIRA_EL_BOTON:		; Con la demo dispara siempre; con mando, hasta cuatro seguidos
	ld a,(0e014h)		;54d7   ; la demo dispara siempre, sin mirar boton
	or a			;54da
	jr nz,MIRA_BOTON_SI		;54db
	ld a,(0e009h)		;54dd   ; los bits 4 y 5 son los dos botones
	and 030h		;54e0   ; los bits 4 y 5 son los dos botones
	jr z,MIRA_BOTON_NO		;54e2
	ld hl,0e140h		;54e4
	ld a,(hl)			;54e7
	cp 004h		;54e8   ; con el mando, cuatro disparos seguidos como mucho
	ret nc			;54ea
	inc (hl)			;54eb   ; y se apunta uno mas
MIRA_BOTON_SI:
	ld a,(0e146h)		;54ec   ; el disparo sale en la direccion en la que vuela el avion
	or a			;54ef
	scf			;54f0
	ret			;54f1
MIRA_BOTON_NO:
	ld (0e140h),a		;54f2   ; y al soltar el boton se rearma la cuenta
	ret			;54f5

; ----------------------------------------------------------------------
; DATOS disparo_al_nacer: Dieciseis parejas (desplazamiento sobre la casilla
;   del avion, caracter) que 0x548E usa para poner el disparo que sale, una
;   por direccion
;   0x54f6..0x5516  (32 bytes)
DATA_disparo_al_nacer:
	defb 04bh,006h	; 54f6
	defb 04ch,006h	; 54f8
	defb 04dh,007h	; 54fa
	defb 06dh,007h	; 54fc
	defb 08dh,008h	; 54fe
	defb 0adh,001h	; 5500
	defb 0cdh,001h	; 5502
	defb 0cch,002h	; 5504
	defb 0cbh,002h	; 5506
	defb 0cah,003h	; 5508
	defb 0c9h,003h	; 550a
	defb 0a9h,004h	; 550c
	defb 089h,004h	; 550e
	defb 069h,004h	; 5510
	defb 049h,005h	; 5512
	defb 04ah,005h	; 5514

; ======================================================================
; CODIGO 0x5516..0x554f  (57 bytes)
; ======================================================================


MUEVE_LOS_DISPAROS:		; Los ocho, uno a uno: borra la casilla y salta a la rutina de su direccion
	ld hl,0e230h		;5516   ; los ocho disparos, uno a uno
	ld b,008h		;5519   ; ocho fichas de disparo
MUEVE_DISPARO:
	push hl			;551b
	push bc			;551c
	xor a			;551d
	cp (hl)			;551e   ; la ficha a cero es un hueco libre
	jr z,MUEVE_DISPARO_SIGUIENTE		;551f
	ld d,(hl)			;5521
	inc hl			;5522
	ld e,(hl)			;5523
	inc hl			;5524
	res 6,d		;5525   ; el bit 6 quitado de D deja la direccion en modo lectura
	call PON_DIRECCION_VDP		;5527
	in a,(098h)		;552a
	set 6,d		;552c
	cp 00bh		;552e   ; los caracteres por debajo del 0x0B son cielo
	jr nc,MUEVE_DISPARO_DESPACHA		;5530
	call PON_DIRECCION_VDP		;5532
	ld a,00ah		;5535   ; se borra escribiendo el caracter 0x0A, que es el cielo
	out (098h),a		;5537
MUEVE_DISPARO_DESPACHA:
	ld a,(hl)			;5539
	inc hl			;553a
	push hl			;553b
	pop bc			;553c
	ld hl,05550h		;553d   ; dieciseis rutinas, una por direccion de vuelo del disparo
	call LEE_PALABRA_DE_TABLA		;5540
	call SALTA_A_HL		;5543
MUEVE_DISPARO_SIGUIENTE:
	pop bc			;5546
	pop hl			;5547
	call SUMA_4_A_HL		;5548   ; cuatro bytes por ficha de disparo
	djnz MUEVE_DISPARO		;554b
	ret			;554d
SALTA_A_HL:		; El `jp (hl)` que usan los despachadores
	jp (hl)			;554e   ; el `jp (hl)` que remata el salto por tabla

; ----------------------------------------------------------------------
; DATOS ret_del_despachador: Un `ret` suelto delante de la tabla de 0x5550, al
;   que no llega nadie
;   0x554f..0x5550  (1 bytes)
DATA_ret_del_despachador:
	defb 0c9h	; 554f

; ----------------------------------------------------------------------
; DATOS vuelo_del_disparo: Las dieciseis rutinas que mueven un disparo, una
;   por direccion (destino del despachador de 0x553D). Cada una calcula la
;   casilla siguiente de la tabla de nombres y el caracter que toca
;   0x5550..0x5570  (32 bytes)
DATA_vuelo_del_disparo:
	defw 05570h	; 5550  -> DISPARO_ARRIBA
	defw 0559dh	; 5552  -> DISPARO_1
	defw 055b0h	; 5554  -> DISPARO_2
	defw 055b6h	; 5556  -> DISPARO_3
	defw 055c1h	; 5558  -> DISPARO_4
	defw 055ceh	; 555a  -> DISPARO_5
	defw 055e3h	; 555c  -> DISPARO_6
	defw 055f0h	; 555e  -> DISPARO_7
	defw 055fch	; 5560  -> DISPARO_8
	defw 0560ah	; 5562  -> DISPARO_9
	defw 0562ah	; 5564  -> DISPARO_10
	defw 05630h	; 5566  -> DISPARO_11
	defw 0563ch	; 5568  -> DISPARO_12
	defw 0564bh	; 556a  -> DISPARO_13
	defw 0565bh	; 556c  -> DISPARO_14
	defw 05669h	; 556e  -> DISPARO_15

; ======================================================================
; CODIGO 0x5570..0x5786  (534 bytes)
; ======================================================================


DISPARO_ARRIBA:
	ld hl,0ffe0h		;5570   ; restar 0x20 casillas es subir una fila
	add hl,de			;5573
DISPARO_MIRA_FILA:
	ld a,h			;5574   ; por encima de la fila 0x78 el disparo se ha salido por arriba
	cp 078h		;5575
	jr c,DISPARO_APAGA		;5577
DISPARO_PON_CARACTER:
	ld d,006h		;5579   ; y arriba del todo el dibujo es el 6
DISPARO_ESCRIBE:		; Antes de pintar mira lo que hay en la casilla: si no es fondo, el disparo no se dibuja
	ex de,hl			;557b   ; antes de escribir, mirar: si la casilla ya no es cielo, no se pinta
	res 6,d		;557c
	call PON_DIRECCION_VDP		;557e
	in a,(098h)		;5581
	set 6,d		;5583
	cp 00ah		;5585   ; el 0x0A es el caracter del cielo: si hay otra cosa, la casilla no se toca
	jr nz,DISPARO_GUARDA		;5587
	call PON_DIRECCION_VDP		;5589
	ld a,h			;558c
	out (098h),a		;558d
DISPARO_GUARDA:
	ld a,h			;558f   ; la ficha se rellena hacia atras: caracter, columna y fila
	ld (bc),a			;5590
	dec bc			;5591
	dec bc			;5592
	ld a,e			;5593
	ld (bc),a			;5594
	dec bc			;5595
	ld a,d			;5596
	ld (bc),a			;5597
	ret			;5598
DISPARO_APAGA:
	xor a			;5599   ; y si el disparo se ha salido, se apaga
	ld d,a			;559a
	jr DISPARO_GUARDA		;559b
DISPARO_1:
	ld hl,0ffe0h		;559d
	add hl,de			;55a0
	ld a,(bc)			;55a1   ; al cambiar de dibujo hay que corregir la casilla, porque el punto se mueve dentro
	cp 006h		;55a2
	jr nz,DISPARO_PON_CARACTER		;55a4
	inc hl			;55a6
DISPARO_1_FILA:
	ld a,h			;55a7
	cp 078h		;55a8
	jr c,DISPARO_APAGA		;55aa
	ld d,007h		;55ac
	jr DISPARO_ESCRIBE		;55ae
DISPARO_2:
	ld hl,0ffe1h		;55b0   ; restar 0x1F es subir una fila y correrse una columna
DISPARO_2_SUMA:
	add hl,de			;55b3
	jr DISPARO_1_FILA		;55b4
DISPARO_3:
	inc de			;55b6   ; direccion 3: una columna a la derecha, y una fila arriba si toca cambiar de dibujo
	ld a,(bc)			;55b7
	cp 008h		;55b8
	jr nz,DISPARO_4_COLUMNA		;55ba
	ld hl,0ffe0h		;55bc
	jr DISPARO_2_SUMA		;55bf
DISPARO_4:
	inc de			;55c1   ; direccion 4: a la derecha del todo, sin cambiar de fila
DISPARO_4_COLUMNA:
	ex de,hl			;55c2
	ld a,l			;55c3
	and 01fh		;55c4   ; los cinco bits bajos son la columna
	cp 018h		;55c6   ; pasada la columna 24 el disparo se ha salido por el lado
	jr nc,DISPARO_APAGA		;55c8
	ld d,008h		;55ca
	jr DISPARO_ESCRIBE		;55cc
DISPARO_5:
	inc de			;55ce   ; el dibujo cambia cada dos pasos, y con el la casilla
	ld a,(bc)			;55cf
	cp 008h		;55d0
	jr nz,DISPARO_4_COLUMNA		;55d2
	ld hl,00020h		;55d4   ; y al cambiar de dibujo, la casilla se corre una fila
	add hl,de			;55d7
	ld a,l			;55d8
	and 01fh		;55d9
	cp 018h		;55db
	jr nc,DISPARO_APAGA		;55dd
	ld d,001h		;55df
	jr DISPARO_ESCRIBE		;55e1
DISPARO_6:
	ld hl,00021h		;55e3   ; direccion 6: a 45 grados, una fila y una columna de golpe
	add hl,de			;55e6
	ld a,h			;55e7
	cp 07bh		;55e8
	jr nc,DISPARO_APAGA		;55ea
DISPARO_6_PON:
	ld d,001h		;55ec
	jr DISPARO_ESCRIBE		;55ee
DISPARO_7:
	ld hl,00020h		;55f0   ; direccion 7: baja una fila, y de vez en cuando corre una columna
	add hl,de			;55f3
	ld a,(bc)			;55f4
	cp 002h		;55f5
	jr nz,DISPARO_8_FILA		;55f7
	inc hl			;55f9
	jr DISPARO_6_PON		;55fa
DISPARO_8:
	ld hl,00020h		;55fc   ; direccion 8: abajo del todo, una fila por paso
	add hl,de			;55ff
DISPARO_8_FILA:
	ld a,h			;5600
	cp 07bh		;5601   ; y pasada la fila 0x7B se ha salido por abajo
	jr nc,DISPARO_APAGA		;5603
	ld d,002h		;5605
	jp DISPARO_ESCRIBE		;5607
DISPARO_9:
	ld hl,00020h		;560a   ; direccion 9: baja tirando a la izquierda
	add hl,de			;560d
	ld a,(bc)			;560e
	cp 002h		;560f
	ld d,002h		;5611
	jp nz,DISPARO_ESCRIBE		;5613
	dec hl			;5616
DISPARO_9_COLUMNA:
	ld a,l			;5617   ; se mira que la casilla siga dentro por los dos lados
	and 01fh		;5618
	cp 018h		;561a
	jp nc,DISPARO_APAGA		;561c
	ld a,h			;561f
	cp 07bh		;5620
	jp nc,DISPARO_APAGA		;5622
	ld d,003h		;5625
	jp DISPARO_ESCRIBE		;5627
DISPARO_10:
	ld hl,0001fh		;562a   ; direccion 10: a 45 grados hacia abajo y a la izquierda
DISPARO_10_SUMA:
	add hl,de			;562d
	jr DISPARO_9_COLUMNA		;562e
DISPARO_11:
	dec de			;5630   ; direccion 11: a la izquierda, bajando de vez en cuando
	ld a,(bc)			;5631
	cp 004h		;5632
	jp nz,DISPARO_12_COLUMNA		;5634
	ld hl,00020h		;5637
	jr DISPARO_10_SUMA		;563a
DISPARO_12:
	dec de			;563c   ; direccion 12: a la izquierda del todo
DISPARO_12_COLUMNA:
	ex de,hl			;563d   ; direccion 12: si se sale por la izquierda, se apaga
	ld a,l			;563e
	and 01fh		;563f
	cp 018h		;5641
	jp nc,DISPARO_APAGA		;5643
	ld d,004h		;5646
	jp DISPARO_ESCRIBE		;5648
DISPARO_13:
	dec de			;564b   ; direccion 13: a la izquierda, subiendo de vez en cuando
	ld a,(bc)			;564c
	cp 004h		;564d
	jp nz,DISPARO_12_COLUMNA		;564f
	ld hl,0ffe0h		;5652
	add hl,de			;5655
DISPARO_13_PON:
	ld d,005h		;5656
	jp DISPARO_ESCRIBE		;5658
DISPARO_14:
	ld hl,0ffdfh		;565b   ; direccion 14: a 45 grados hacia arriba y a la izquierda
	add hl,de			;565e
	ld a,l			;565f
	and 01fh		;5660
	cp 018h		;5662
	jp nc,DISPARO_APAGA		;5664
	jr DISPARO_13_PON		;5667
DISPARO_15:
	ld hl,0ffe0h		;5669   ; direccion 15: sube tirando a la izquierda
	add hl,de			;566c
	ld a,(bc)			;566d
	cp 006h		;566e
	jp nz,DISPARO_MIRA_FILA		;5670
	dec hl			;5673
	ld d,005h		;5674
	jp DISPARO_ESCRIBE		;5676

; ----------------------------------------------------------------------
; EL BICHO GRANDE. Al final de la epoca sale un bicho enorme -seis caracteres de ancho por cuatro de alto- que no es un sprite: se pinta en la tabla de nombres, casilla a casilla, y por eso hay que borrarlo antes de moverlo.
; ----------------------------------------------------------------------
PASO_DEL_BICHO_GRANDE:
	ld hl,0e200h		;5679   ; sin bicho en pantalla no hay nada que mover
	ld a,(hl)			;567c   ; cuatro estados: 0x80 volando, 0xA0 y 0xC0 los dos pasos de reventar
	and 0e0h		;567d
	ret z			;567f
	cp 080h		;5680   ; los tres bits altos del byte dicen que clase de orden es
	jr z,BICHO_GRANDE_SUENA		;5682
	cp 0c0h		;5684
	jp z,PINTA_BLOQUE_BAJA		;5686
	cp 0a0h		;5689
	jp nz,PINTA_BLOQUE_SALTA		;568b
	jp PINTA_BLOQUE_VUELTA		;568e
BICHO_GRANDE_SUENA:
	push hl			;5691
	ld a,(0e021h)		;5692   ; el sonido del bicho manda sobre lo que este sonando, salvo algo mas urgente
	or a			;5695
	ld hl,0e027h		;5696
	jr z,BICHO_GRANDE_PIDE_SONIDO		;5699
	ld a,(hl)			;569b
	cp 006h		;569c   ; la prioridad 6 no pisa lo que suene por encima
	jr c,BICHO_GRANDE_MUEVE		;569e
BICHO_GRANDE_PIDE_SONIDO:
	ld (hl),006h		;56a0
	ld hl,07d88h		;56a2   ; el bicho grande tiene su propio sonido, con prioridad 6
	ld (0e020h),hl		;56a5
BICHO_GRANDE_MUEVE:
	pop hl			;56a8   ; la casilla y el dibujo del bicho estan en su ficha
	inc hl			;56a9
	ld d,(hl)			;56aa
	inc hl			;56ab
	ld e,(hl)			;56ac
	inc hl			;56ad
	ld a,(hl)			;56ae
	push hl			;56af
	ld hl,05786h		;56b0   ; la tabla de 0x5786 dice, para cada dibujo, cual va detras y si se corre una casilla
	rlca			;56b3   ; dos bytes por dibujo
	call SUMA_A_HL		;56b4
	ld b,(hl)			;56b7
	inc hl			;56b8
	ld a,(hl)			;56b9
	pop hl			;56ba
	or a			;56bb
	jr z,BICHO_GRANDE_GUARDA		;56bc
	inc de			;56be
BICHO_GRANDE_GUARDA:
	ld (hl),b			;56bf   ; el dibujo nuevo y la casilla nueva se guardan en la ficha
	dec hl			;56c0
	ld (hl),e			;56c1
	dec hl			;56c2
	ld (hl),d			;56c3
BICHO_GRANDE_PINTA:		; Borra el dibujo de antes y lo vuelve a poner en la casilla nueva
	dec hl			;56c4   ; primero se borra el dibujo de antes y luego se pinta en la casilla nueva
	push hl			;56c5
	push de			;56c6
	push bc			;56c7
	call HUMO_DEL_BICHO_GRANDE		;56c8
	pop bc			;56cb
	pop de			;56cc
	pop hl			;56cd
	ld a,e			;56ce   ; si el bicho llega a la columna 24 o 26, se ha salido
	and 01fh		;56cf   ; los cinco bits bajos son la columna
	cp 018h		;56d1
	jr z,BICHO_GRANDE_SE_VA		;56d3
	cp 01ah		;56d5
	jr z,BICHO_GRANDE_SE_VA		;56d7
	ld a,d			;56d9
	cp 07bh		;56da   ; y lo mismo si se pasa del ultimo tercio por arriba
	jr z,BICHO_GRANDE_SE_VA		;56dc
	cp 077h		;56de
	jr nz,BICHO_GRANDE_DIBUJO		;56e0
	ld a,e			;56e2
	cp 0a0h		;56e3
	jr nc,BICHO_GRANDE_DIBUJO		;56e5
BICHO_GRANDE_SE_VA:		; Al salirse por el borde, la fase se da por acabada
	xor a			;56e7   ; al salirse por el borde, la fase se da por terminada
	ld (hl),a			;56e8
	ld hl,0e120h		;56e9
	call LEE_JUGADOR		;56ec
	jr z,BICHO_GRANDE_MARCA		;56ef
	inc hl			;56f1
	inc hl			;56f2
BICHO_GRANDE_MARCA:
	ld (hl),005h		;56f3   ; la fase se cierra con cinco enemigos de propina
	ld a,001h		;56f5
	ld (0e1a0h),a		;56f7   ; y quedan puestos los dos avisos de fase acabada
	ld (0e20fh),a		;56fa
	ret			;56fd
BICHO_GRANDE_DIBUJO:
	ld a,b			;56fe
	ld hl,069c5h		;56ff   ; 24 caracteres por dibujo: seis de ancho por cuatro de alto
	or a			;5702
	jr z,PINTA_BLOQUE_EN_NOMBRES		;5703
	xor a			;5705
BICHO_GRANDE_INDICE:
	add a,018h		;5706   ; 24 caracteres de un dibujo al siguiente
	djnz BICHO_GRANDE_INDICE		;5708
	call SUMA_A_HL		;570a
PINTA_BLOQUE_EN_NOMBRES:		; Pinta C filas de seis caracteres en la tabla de nombres, saltandose lo que caiga fuera del area de juego
	ld c,004h		;570d   ; cuatro filas de seis
PINTA_BLOQUE_FILA_2:
	ld b,006h		;570f
	push de			;5711
PINTA_BLOQUE_CASILLA:
	ld a,e			;5712   ; las casillas que caen fuera del area de juego no se pintan
	and 01fh		;5713
	cp 018h		;5715
	jr nc,PINTA_BLOQUE_SIGUIENTE		;5717
	ld a,d			;5719
	cp 07bh		;571a
	jr z,PINTA_BLOQUE_FUERA		;571c
	cp 077h		;571e   ; la fila 0x77 es la de arriba, la del marcador: tampoco se pinta
	jr z,PINTA_BLOQUE_SIGUIENTE		;5720
	call PON_DIRECCION_VDP		;5722
	ld a,(hl)			;5725
	out (098h),a		;5726
PINTA_BLOQUE_SIGUIENTE:
	inc hl			;5728   ; y la casilla siguiente, a la derecha
	inc de			;5729
	djnz PINTA_BLOQUE_CASILLA		;572a
	pop de			;572c
	ex de,hl			;572d
	call SUMA_32_A_HL		;572e
	ex de,hl			;5731
	dec c			;5732
	jr nz,PINTA_BLOQUE_FILA_2		;5733
	ret			;5735
PINTA_BLOQUE_FUERA:
	pop de			;5736
	ret			;5737
PINTA_BLOQUE_BAJA:
	ld a,(hl)			;5738
	and 007h		;5739   ; los tres bits bajos son la cuenta atras de este paso
	jr z,PINTA_BLOQUE_CUENTA		;573b
	dec (hl)			;573d
	ret			;573e
PINTA_BLOQUE_CUENTA:
	ld (hl),0a4h		;573f
	ld a,018h		;5741
	ld (0e3dah),a		;5743   ; 0xE3DA y 0xE3DE son los bytes de dibujo de dos sprites
	ld a,01ch		;5746
	ld (0e3deh),a		;5748
PINTA_BLOQUE_VUELTA:
	ld a,(hl)			;574b
	and 007h		;574c
	jr z,PINTA_BLOQUE_AJUSTA		;574e
	dec (hl)			;5750
	ret			;5751
PINTA_BLOQUE_AJUSTA:
	ld a,0d1h		;5752   ; la Y 0xD1 deja el sprite fuera de la pantalla
	ld (0e3d4h),a		;5754
	ld (hl),0f0h		;5757   ; y la orden pasa a ser la 0xF0
	ld a,0d1h		;5759
	ld (0e3d8h),a		;575b
	ld (0e3dch),a		;575e
	ret			;5761
PINTA_BLOQUE_SALTA:
	ld a,(hl)			;5762
	and 01fh		;5763   ; aqui la cuenta atras es de cinco bits, que es una espera mucho mas larga
	jr z,PINTA_BLOQUE_SALTA_2		;5765
	dec (hl)			;5767
	ret			;5768
PINTA_BLOQUE_SALTA_2:
	ld a,(0e052h)		;5769
	or a			;576c
	jr nz,PINTA_BLOQUE_FIN		;576d
	ld a,001h		;576f
	ld (0e050h),a		;5771   ; 0xE050 puesto: el jugador se ha estrellado
PINTA_BLOQUE_FIN:
	xor a			;5774   ; el bicho ya no esta, y el avion vuelve a mirar hacia arriba
	ld (0e200h),a		;5775
	ld (0e146h),a		;5778
	ld de,0798bh		;577b   ; y se le devuelve el cielo a la casilla de debajo del avion
	call PON_DIRECCION_VDP		;577e
	ld a,00ah		;5781
	out (098h),a		;5783
	ret			;5785

; ----------------------------------------------------------------------
; DATOS pasos_del_jefe: Ocho parejas que 0x56B0 usa para el bicho grande de
;   0xE200: el caracter con el que se dibuja y si avanza una casilla
;   0x5786..0x5796  (16 bytes)
DATA_pasos_del_jefe:
	defb 006h,000h	; 5786
	defb 007h,000h	; 5788
	defb 004h,000h	; 578a
	defb 005h,001h	; 578c
	defb 000h,000h	; 578e
	defb 001h,000h	; 5790
	defb 002h,001h	; 5792
	defb 003h,000h	; 5794

; ======================================================================
; CODIGO 0x5796..0x5807  (113 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LOS DISPAROS ENEMIGOS. Seis fichas en 0xE270, de siete bytes. Los pone 0x6463 cuando un avion con la bandera de disparar pasa por fuera del recuadro del centro, y salen con el paso que lleva al avion del jugador ya calculado (0x5B73). Se dibujan con el patron 0x60, que es el punto pequeno de 0x72F4.
; ----------------------------------------------------------------------
PASO_DE_LOS_DISPAROS_ENEMIGOS:
	ld hl,0e270h		;5796
	ld de,0e3bch		;5799
	ld b,006h		;579c   ; seis disparos enemigos como mucho
PASO_DE_UN_DISPARO_ENEMIGO:
	ld a,(hl)			;579e   ; las fichas libres se saltan, pero el sprite avanza igual
	or a			;579f
	call z,SIGUIENTE_SPRITE		;57a0
	jr z,DISPARO_ENEMIGO_SIGUIENTE		;57a3
	push hl			;57a5
	inc hl			;57a6
	call CUENTA_ATRAS_DEL_DISPARO_ENEMIGO		;57a7   ; cada disparo lleva sus dos cuentas atras, una por coordenada
	pop hl			;57aa
	call APAGA_SI_SE_SALE		;57ab
DISPARO_ENEMIGO_SIGUIENTE:
	call SUMA_7_A_HL		;57ae   ; siete bytes por ficha de disparo enemigo
	djnz PASO_DE_UN_DISPARO_ENEMIGO		;57b1
	ret			;57b3
PASO_DE_LAS_BOMBAS:		; Las cuatro fichas de 0xE260, que solo se usan en la epoca 1: las bombas que sueltan los aviones al pasar por arriba
	ld hl,0e260h		;57b4
	ld de,0e3ach		;57b7
	ld b,004h		;57ba
PASO_DE_UNA_BOMBA:
	push bc			;57bc
	push de			;57bd
	push hl			;57be
	ld a,(hl)			;57bf
	and 0e0h		;57c0
	cp 080h		;57c2   ; volando
	jr z,BOMBA_CAE		;57c4
	cp 0c0h		;57c6   ; o reventando, que es una cuenta atras y a la basura
	jr nz,BOMBA_SIGUIENTE		;57c8
	ld a,(hl)			;57ca
	and 007h		;57cb
	jr z,BOMBA_SE_APAGA		;57cd
	dec (hl)			;57cf
	jr BOMBA_SIGUIENTE		;57d0
BOMBA_SE_APAGA:
	xor a			;57d2
	ld (hl),a			;57d3
	ld a,0d1h		;57d4
	ld (de),a			;57d6
	jr BOMBA_SIGUIENTE		;57d7
BOMBA_CAE:		; Recorre la trayectoria de 0x5807, paso a paso
	ld c,(hl)			;57d9
	push hl			;57da
	inc hl			;57db
	ld a,(hl)			;57dc
	inc (hl)			;57dd
	ld hl,05807h		;57de   ; la caida esta tabulada: setenta y dos parejas, dos bytes por paso
	rlca			;57e1
	call SUMA_A_HL		;57e2
	ld a,(de)			;57e5
	add a,(hl)			;57e6
	ld (de),a			;57e7
	inc hl			;57e8
	inc de			;57e9
	ld a,(hl)			;57ea
	bit 0,c		;57eb   ; y el avance en X va en un sentido o en el otro segun el bit 0
	jr z,BOMBA_GUARDA_X		;57ed
	neg		;57ef
BOMBA_GUARDA_X:
	ld c,a			;57f1   ; el avance en X se le suma a la casilla de la bomba
	ld a,(de)			;57f2
	add a,c			;57f3
	ld (de),a			;57f4
	pop hl			;57f5
	call APAGA_SI_SE_SALE		;57f6
BOMBA_SIGUIENTE:
	pop hl			;57f9   ; tres bytes por ficha de bomba, que es la ficha mas pequena de todas
	pop de			;57fa
	pop bc			;57fb
	call SIGUIENTE_SPRITE		;57fc
	ld a,003h		;57ff
	call SUMA_A_HL		;5801
	djnz PASO_DE_UNA_BOMBA		;5804
	ret			;5806

; ----------------------------------------------------------------------
; DATOS caida_de_la_bomba: Setenta y dos parejas (cuanto baja, cuanto avanza)
;   que 0x57DE recorre paso a paso: la caida de la bomba de la epoca 1. Los
;   nueve primeros pasos no bajan nada y avanzan dos, o sea que la bomba sale
;   despedida en horizontal; luego va empinandose; y los ocho ultimos bajan
;   ocho y no avanzan nada: se despena en vertical. El bit 0 del estado decide
;   si el avance en X va hacia un lado o hacia el otro
;   0x5807..0x5897  (144 bytes)
DATA_caida_de_la_bomba:
	defb 000h,002h,000h,002h,000h,002h,000h,002h,000h,002h,000h,002h,000h,002h,000h,002h	; 5807  ................
	defb 000h,002h,001h,003h,001h,003h,001h,002h,000h,003h,001h,004h,002h,004h,003h,003h	; 5817  ................
	defb 002h,003h,002h,003h,002h,003h,003h,002h,002h,003h,003h,002h,004h,002h,003h,001h	; 5827  ................
	defb 003h,002h,003h,002h,003h,001h,004h,001h,003h,002h,003h,002h,003h,001h,002h,001h	; 5837  ................
	defb 002h,002h,003h,002h,004h,002h,004h,000h,003h,001h,003h,001h,003h,001h,002h,000h	; 5847  ................
	defb 003h,001h,003h,001h,003h,001h,004h,001h,004h,001h,004h,002h,004h,001h,005h,001h	; 5857  ................
	defb 004h,001h,004h,001h,004h,001h,004h,000h,004h,000h,004h,001h,004h,001h,004h,000h	; 5867  ................
	defb 004h,000h,004h,001h,004h,000h,004h,000h,004h,000h,004h,000h,004h,000h,004h,000h	; 5877  ................
	defb 008h,000h,008h,000h,008h,000h,008h,000h,008h,000h,008h,000h,008h,000h,008h,000h	; 5887  ................

; ======================================================================
; CODIGO 0x5897..0x59fa  (355 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL PASAJERO. La ficha de 0xE2CE baja sola y parpadea entre dos caracteres cada 64 fotogramas.
; ----------------------------------------------------------------------
PASO_DEL_PASAJERO:
	ld hl,0e2ceh		;5897
	ld de,0e3a8h		;589a
	ld a,(hl)			;589d   ; sin pasajero en pantalla no hay nada que hacer
	or a			;589e
	ret z			;589f
	ld a,(de)			;58a0   ; el paracaidista baja un pixel por fotograma, y nada mas
	add a,001h		;58a1
	ld (de),a			;58a3
	inc de			;58a4
	call APAGA_SI_SE_SALE		;58a5   ; y si se sale por abajo, se apaga
	ld a,(hl)			;58a8
	or a			;58a9
	ret z			;58aa
	dec de			;58ab
	dec de			;58ac
	inc hl			;58ad
	ld a,(0e019h)		;58ae   ; el pasajero parpadea entre dos caracteres cada 64 fotogramas
	bit 6,a		;58b1   ; el bit 6 del contador de fotogramas: cambia de dibujo cada 64
	ld a,06ch		;58b3
	jr z,PASAJERO_PARPADEA		;58b5
	ld a,070h		;58b7
PASAJERO_PARPADEA:
	ld (hl),a			;58b9
	ld (de),a			;58ba
	ret			;58bb

; ----------------------------------------------------------------------
; LOS MISILES. Cuatro fichas en 0xE2A0, de nueve bytes. Los sueltan los aviones que llevan la bandera del bit 3 (0x63CB, epocas 3, 4 y 5) y, ademas, salen dos de las esquinas de abajo cada treinta y dos enemigos (0x5BAE). Se dibujan con el patron direccion por cuatro mas 0x40, o sea los ocho palitos de 0x71F1, y van derechos al centro de la pantalla, que es donde esta siempre el avion.
; ----------------------------------------------------------------------
PASO_DE_LOS_MISILES:
	ld hl,0e2a0h		;58bc
	ld de,0e3ach		;58bf
	ld b,004h		;58c2   ; cuatro misiles como mucho
PASO_DE_UN_MISIL:
	push bc			;58c4   ; los cuatro misiles, uno detras de otro
	push hl			;58c5
	ld a,(hl)			;58c6   ; cada misil, en su estado
	and 0e0h		;58c7   ; los tres bits altos: 0x80 vivo, 0xC0 muriendo
	cp 080h		;58c9
	jr z,MISIL_VIVO		;58cb
	cp 0c0h		;58cd
	jr nz,MISIL_SIGUIENTE_FICHA		;58cf
	ld a,(hl)			;58d1
	and 007h		;58d2   ; los tres bits bajos son la cuenta de la explosion
	jr z,MISIL_APAGA		;58d4
	dec (hl)			;58d6
	jr MISIL_SIGUIENTE_FICHA		;58d7
MISIL_APAGA:
	xor a			;58d9
	ld (hl),a			;58da
	ld a,0d1h		;58db   ; la Y 0xD1 deja el sprite fuera de la pantalla
	ld (de),a			;58dd
MISIL_SIGUIENTE_FICHA:
	call SIGUIENTE_SPRITE		;58de
	jr MISIL_SIGUIENTE		;58e1
MISIL_VIVO:
	push hl			;58e3   ; el misil suena al nacer, con prioridad 14
	call LEE_EPOCA		;58e4   ; en la epoca 5 no suena
	cp 005h		;58e7
	jr z,ENEMIGO_MIRA_CUENTA		;58e9
	ld a,(0e031h)		;58eb
	or a			;58ee
	jr nz,ENEMIGO_MIRA_CUENTA		;58ef
	ld hl,07db6h		;58f1
	ld (0e030h),hl		;58f4
	ld a,00eh		;58f7
	ld (0e037h),a		;58f9   ; catorce fotogramas de sonido
ENEMIGO_MIRA_CUENTA:
	pop hl			;58fc
	inc hl			;58fd
	ld a,(hl)			;58fe   ; el byte 1 es una cuenta con signo, como en los comportamientos 3 y 4
	or a			;58ff
	jr z,ENEMIGO_APUNTA_AL_CENTRO		;5900
	inc (hl)			;5902   ; la cuenta sube hasta cero, que es cuando toca apuntar
	jr z,ENEMIGO_APUNTA_AL_CENTRO		;5903
	bit 7,(hl)		;5905   ; en negativo esta girando; en positivo, volando derecho
	jr nz,ENEMIGO_SIGUE_IGUAL		;5907
	dec (hl)			;5909
	dec (hl)			;590a
	jr MISIL_MUEVE		;590b
ENEMIGO_SIGUE_IGUAL:
	inc hl			;590d
	ld a,(hl)			;590e
	jr ENEMIGO_PON_SPRITE		;590f
ENEMIGO_APUNTA_AL_CENTRO:
	call DIRECCION_AL_CENTRO		;5911   ; el misil apunta al centro de la pantalla, que es donde esta el avion
	inc hl			;5914
	cp (hl)			;5915
	jr z,ENEMIGO_DISPARA		;5916
	dec hl			;5918
	ld (hl),0f8h		;5919   ; todavia no mira al centro: gira un octavo y espera ocho fotogramas
	inc hl			;591b
	ld a,(hl)			;591c
	inc a			;591d
	and 007h		;591e   ; ocho rumbos: los tres bits bajos
	ld (hl),a			;5920
ENEMIGO_PON_SPRITE:
	dec hl			;5921
	dec hl			;5922
	ld c,a			;5923
	ld b,002h		;5924   ; los misiles van de dos en dos pixeles
	call MUEVE_SPRITE		;5926
	dec de			;5929
	dec de			;592a
	ld a,c			;592b
	rlca			;592c
	rlca			;592d
	add a,040h		;592e   ; el patron del sprite sale de la direccion, por cuatro, mas 0x40
	ld (de),a			;5930
	inc de			;5931
	inc de			;5932
	jr MISIL_SIGUIENTE		;5933
ENEMIGO_DISPARA:
	inc hl			;5935   ; al llegar a la direccion buena, dispara
	ld bc,002feh		;5936   ; y al llegar disparan con la cuenta puesta a 0xFE
	call PON_DISPARO_ENEMIGO		;5939
	pop hl			;593c
	push hl			;593d
	ld a,(hl)			;593e
	and 003h		;593f   ; los dos bits bajos son la cuenta entre fotograma y fotograma
	jr z,ENEMIGO_CAMBIA_FOTOGRAMA		;5941
	dec (hl)			;5943
	ld a,(hl)			;5944
	and 003h		;5945
ENEMIGO_CAMBIA_FOTOGRAMA:
	inc hl			;5947
	ld (hl),010h		;5948   ; 0x10 fotogramas hasta el paso siguiente
	jr nz,MISIL_MUEVE		;594a
	ld (hl),07eh		;594c
MISIL_MUEVE:
	inc hl			;594e   ; el misil sigue por donde ya iba
	ld c,(hl)			;594f
	pop hl			;5950
	push hl			;5951
	ld b,002h		;5952
	call MUEVE_SPRITE		;5954
MISIL_SIGUIENTE:
	pop hl			;5957   ; nueve bytes por ficha de misil
	call SUMA_9_A_HL		;5958
	pop bc			;595b
	dec b			;595c   ; cuatro misiles
	jp nz,PASO_DE_UN_MISIL		;595d
	ret			;5960
LEE_PALABRA_DE_TABLA:		; HL = la palabra numero A de la tabla que hay en HL; es la primera mitad de todos los despachadores
	rlca			;5961   ; la mitad de todos los despachadores: HL = tabla[A]
	call SUMA_A_HL		;5962
	ld a,(hl)			;5965
	inc hl			;5966
	ld h,(hl)			;5967
	ld l,a			;5968
	ret			;5969
SUMA_4_A_HL:
	ld a,004h		;596a   ; las cuentas de salto que usan las fichas: 4, 7, 9, 10 y 32 bytes
	jr SUMA_A_HL_SALTO		;596c
SUMA_7_A_HL:
	ld a,007h		;596e
	jr SUMA_A_HL_SALTO		;5970
SUMA_9_A_HL:
	ld a,009h		;5972
	jr SUMA_A_HL_SALTO		;5974
SUMA_10_A_HL:
	ld a,00ah		;5976
	jr SUMA_A_HL_SALTO		;5978
SUMA_32_A_HL:		; Una fila entera de la tabla de nombres
	ld a,020h		;597a
SUMA_A_HL_SALTO:
	jp SUMA_A_HL		;597c
HUMO_DEL_BICHO_GRANDE:		; Cuando el bicho lleva impactos encima, le pone un sprite de humo que va a peor. No borra nada: el nombre de antes estaba mal
	ld hl,0e200h		;597f
	ld a,(hl)			;5982
	and 0e0h		;5983
	cp 080h		;5985   ; el bicho grande solo humea si esta vivo
	ret nz			;5987
	inc hl			;5988
	ld d,(hl)			;5989
	inc hl			;598a
	ld e,(hl)			;598b
	inc hl			;598c
	inc hl			;598d
	ld a,(hl)			;598e   ; sin impactos encima, el bicho no echa humo
	or a			;598f
	ret z			;5990
	ld a,e			;5991
	and 01fh		;5992   ; los cinco bits bajos son la columna
	rlca			;5994   ; tres rotaciones: la columna por ocho, que son los pixeles
	rlca			;5995
	rlca			;5996
	add a,008h		;5997   ; la casilla del bicho, pasada a pixeles, con medio caracter de correccion
	ld b,a			;5999
	ld a,e			;599a
	rr d		;599b   ; los dos desplazamientos de DE con acarreo bajan la fila a pixeles
	rra			;599d
	rr d		;599e
	rra			;59a0
	and 0f8h		;59a1
	add a,004h		;59a3
	ld c,a			;59a5
	dec hl			;59a6
	ld a,(hl)			;59a7
	ld hl,059fah		;59a8   ; ocho rutinas, una por dibujo del bicho: cada una corre el humo a su sitio
	call LEE_PALABRA_DE_TABLA		;59ab
	call SALTA_A_HL		;59ae
	ld hl,0e3d5h		;59b1   ; el humo va en el sprite de 0xE3D4, con el patron 0x7C
	ld (hl),b			;59b4
	dec hl			;59b5
	ld (hl),c			;59b6
	ld a,b			;59b7
	cp 0b0h		;59b8   ; si el humo se sale de la pantalla, se manda a Y=0xD1
	jr nc,HUMO_FUERA_DE_PANTALLA		;59ba
	ld a,c			;59bc
	cp 0b0h		;59bd
	jr c,HUMO_PON_PATRON		;59bf
HUMO_FUERA_DE_PANTALLA:
	ld (hl),0d1h		;59c1
HUMO_PON_PATRON:
	inc hl			;59c3
	inc hl			;59c4
	ld (hl),07ch		;59c5   ; el patron 0x7C no lleva dibujo fijo: se le suben 32 bytes nuevos cada vez
	inc hl			;59c7
	ld (hl),00fh		;59c8   ; el 0x0F es el color del humo
	ld hl,07394h		;59ca
	ld de,05be0h		;59cd
	ld b,020h		;59d0   ; 0x20 bytes: los cuatro caracteres del sprite grande
	ld a,(0e204h)		;59d2   ; con seis impactos o mas, el humo pasa a los dibujos gordos
	cp 006h		;59d5
	jr nc,HUMO_MUY_TOCADO		;59d7
	ld a,(0e019h)		;59d9   ; y alterna entre dos cada ocho fotogramas
	and 00fh		;59dc
	cp 008h		;59de
	jr nc,HUMO_SUBE_A_VRAM		;59e0
	ld hl,073b4h		;59e2
	jr HUMO_SUBE_A_VRAM		;59e5
HUMO_MUY_TOCADO:
	ld hl,073b4h		;59e7   ; muy tocado, el humo alterna entre los dos dibujos gordos
	ld a,(0e019h)		;59ea
	and 00fh		;59ed
	cp 008h		;59ef
	jr nc,HUMO_SUBE_A_VRAM		;59f1
	ld hl,073d4h		;59f3
HUMO_SUBE_A_VRAM:
	call COPIA_A_VRAM		;59f6
	ret			;59f9

; ----------------------------------------------------------------------
; DATOS tabla_59fa: Ocho rutinas, destino del despachador de 0x59A8
;   0x59fa..0x5a0a  (16 bytes)
DATA_tabla_59fa:
	defw 05a0eh	; 59fa  -> SPRITE_QUIETO
	defw 05a0ah	; 59fc  -> SPRITE_DERECHA_4
	defw 05a0fh	; 59fe  -> SPRITE_ARRIBA_4
	defw 05a14h	; 5a00  -> SPRITE_ABAJO_4
	defw 05a1ah	; 5a02  -> SPRITE_ARRIBA_2
	defw 05a1fh	; 5a04  -> SPRITE_ARRIBA_2_DERECHA
	defw 05a24h	; 5a06  -> SPRITE_ABAJO_2
	defw 05a29h	; 5a08  -> SPRITE_ABAJO_2_DERECHA

; ======================================================================
; CODIGO 0x5a0a..0x5a7c  (114 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS OCHO DIRECCIONES DE LOS SPRITES. Los actores que van por sprite no usan las dieciseis direcciones del avion, sino ocho, y se mueven de dos o de cuatro pixeles por paso.
; ----------------------------------------------------------------------
SPRITE_DERECHA_4:
	ld a,c			;5a0a   ; los ocho dibujos del bicho no llevan el humo en el mismo sitio
	add a,004h		;5a0b   ; cuatro pixeles: medio caracter
	ld c,a			;5a0d
SPRITE_QUIETO:
	ret			;5a0e   ; con el dibujo 0 el humo va sin correr
SPRITE_ARRIBA_4:
	ld a,b			;5a0f
	sub 004h		;5a10
	ld b,a			;5a12
	ret			;5a13
SPRITE_ABAJO_4:
	ld a,b			;5a14
	add a,004h		;5a15
	ld b,a			;5a17
	jr SPRITE_DERECHA_4		;5a18
SPRITE_ARRIBA_2:
	ld a,b			;5a1a
	sub 002h		;5a1b
	ld b,a			;5a1d
	ret			;5a1e
SPRITE_ARRIBA_2_DERECHA:
	call SPRITE_ARRIBA_2		;5a1f
	jr SPRITE_DERECHA_4		;5a22
SPRITE_ABAJO_2:
	ld a,b			;5a24
	add a,002h		;5a25
	ld b,a			;5a27
	ret			;5a28
SPRITE_ABAJO_2_DERECHA:
	call SPRITE_ABAJO_2		;5a29
	jr SPRITE_DERECHA_4		;5a2c
CUENTA_ATRAS_DEL_DISPARO_ENEMIGO:
	call CUENTA_ATRAS_PASO		;5a2e   ; el disparo enemigo mueve las dos coordenadas con la misma cuenta
	inc hl			;5a31
	inc de			;5a32
CUENTA_ATRAS_PASO:
	dec (hl)			;5a33   ; cada coordenada tiene su cuenta atras y su recarga: asi salen las diagonales
	inc hl			;5a34
	inc hl			;5a35
	ret nz			;5a36
	dec hl			;5a37
	ld a,(hl)			;5a38
	dec hl			;5a39
	ld (hl),a			;5a3a
	inc hl			;5a3b
	inc hl			;5a3c
	ld a,(de)			;5a3d
	add a,(hl)			;5a3e   ; y cuando se agota, un pixel para ese lado
	ld (de),a			;5a3f
	ret			;5a40
MUEVE_SPRITE:		; Mueve la posicion (Y, X) de DE en la direccion C, con paso B
	push hl			;5a41   ; la direccion es de ocho, no de dieciseis: los sprites no afinan tanto
	ld hl,05a7ch		;5a42
	ld a,c			;5a45
	call LEE_PALABRA_DE_TABLA		;5a46
	call SALTA_A_HL		;5a49
	pop hl			;5a4c
APAGA_SI_SE_SALE:		; Si el sprite se ha ido de la pantalla, lo manda a Y=0xD1 y libera la ficha
	ld a,(de)			;5a4d   ; si el sprite se ha ido de la pantalla, la ficha se libera
	cp 0b0h		;5a4e   ; por debajo de Y=0xB0 esta dentro; por encima, se ha salido por abajo
	dec de			;5a50
	jr nc,APAGA_SPRITE		;5a51
	ld a,(de)			;5a53
	cp 0d1h		;5a54   ; y 0xD1 es la marca de "ya estaba fuera"
	jr z,SIGUIENTE_SPRITE		;5a56
	cp 0c0h		;5a58
	jr c,SIGUIENTE_SPRITE		;5a5a
APAGA_SPRITE:
	ld a,0d1h		;5a5c   ; la ficha se libera mandando su sprite a Y=0xD1
	ld (de),a			;5a5e
	xor a			;5a5f
	ld (hl),a			;5a60
	ld a,e			;5a61
	cp 0a7h		;5a62   ; solo descuentan los sprites de 0xE38C a 0xE3A7, o sea los siete aviones
	jr nc,SIGUIENTE_SPRITE		;5a64
	cp 08bh		;5a66
	jr c,SIGUIENTE_SPRITE		;5a68
	push hl			;5a6a
	ld hl,0e121h		;5a6b
	call LEE_JUGADOR		;5a6e
	jr z,APAGA_DESCUENTA		;5a71
	inc hl			;5a73
	inc hl			;5a74
APAGA_DESCUENTA:
	dec (hl)			;5a75
	pop hl			;5a76
SIGUIENTE_SPRITE:
	inc de			;5a77
	inc de			;5a78
	inc de			;5a79
	inc de			;5a7a
	ret			;5a7b

; ----------------------------------------------------------------------
; DATOS tabla_5a7c: Ocho rutinas, destino del despachador de 0x5A42
;   0x5a7c..0x5a8c  (16 bytes)
DATA_tabla_5a7c:
	defw 05a8ch	; 5a7c  -> MUEVE_ARRIBA
	defw 05a91h	; 5a7e  -> MUEVE_ARRIBA_DERECHA
	defw 05a98h	; 5a80  -> MUEVE_DERECHA_SOLO
	defw 05a9bh	; 5a82  -> MUEVE_ABAJO_DERECHA
	defw 05aa1h	; 5a84  -> MUEVE_ABAJO
	defw 05aa6h	; 5a86  -> MUEVE_ABAJO_IZQUIERDA
	defw 05aadh	; 5a88  -> MUEVE_IZQUIERDA_SOLO
	defw 05ab0h	; 5a8a  -> MUEVE_ARRIBA_IZQUIERDA

; ======================================================================
; CODIGO 0x5a8c..0x5c13  (391 bytes)
; ======================================================================


MUEVE_ARRIBA:
	ld a,(de)			;5a8c   ; B es la velocidad en pixeles, la misma para las dos coordenadas
	sub b			;5a8d
	ld (de),a			;5a8e
	inc de			;5a8f
	ret			;5a90
MUEVE_ARRIBA_DERECHA:
	call MUEVE_ARRIBA		;5a91   ; en diagonal se mueven las dos coordenadas
MUEVE_DERECHA:
	ld a,(de)			;5a94
	add a,b			;5a95
	ld (de),a			;5a96
	ret			;5a97
MUEVE_DERECHA_SOLO:
	inc de			;5a98   ; el `inc de` deja el puntero en la X
	jr MUEVE_DERECHA		;5a99
MUEVE_ABAJO_DERECHA:
	call MUEVE_DERECHA		;5a9b
	inc de			;5a9e
	jr MUEVE_DERECHA		;5a9f
MUEVE_ABAJO:
	call MUEVE_DERECHA		;5aa1
	inc de			;5aa4
	ret			;5aa5
MUEVE_ABAJO_IZQUIERDA:
	call MUEVE_ABAJO		;5aa6
MUEVE_IZQUIERDA:
	ld a,(de)			;5aa9
	sub b			;5aaa
	ld (de),a			;5aab
	ret			;5aac
MUEVE_IZQUIERDA_SOLO:
	inc de			;5aad
	jr MUEVE_IZQUIERDA		;5aae
MUEVE_ARRIBA_IZQUIERDA:
	call MUEVE_ARRIBA		;5ab0
	jr MUEVE_IZQUIERDA		;5ab3
DIRECCION_AL_CENTRO:		; Deja en A la direccion (0..7) que va de la posicion DE al centro de la pantalla, que es donde vuela siempre el avion del jugador
	push bc			;5ab5   ; la direccion que va de aqui al centro de la pantalla, 0x60,0x60
	push de			;5ab6
	ld a,(de)			;5ab7
	ld c,a			;5ab8
	inc de			;5ab9
	ld a,(de)			;5aba
	ld b,a			;5abb
	ld a,060h		;5abc   ; 0x60 es el centro en las dos coordenadas
	cp b			;5abe
	jr c,AL_CENTRO_ABAJO		;5abf
	cp c			;5ac1
	jr c,AL_CENTRO_DERECHA		;5ac2
	ld a,b			;5ac4   ; con la diferencia de las dos distancias se afina el octavo
	sub c			;5ac5
	ld d,000h		;5ac6
	jp p,AL_CENTRO_ARRIBA		;5ac8   ; el signo dice de que lado esta
	inc d			;5acb
	neg		;5acc
AL_CENTRO_ARRIBA:
	ex af,af'			;5ace   ; por encima y a menos de 0x20 de distancia, se baja recto
	ld a,000h		;5acf
	ex af,af'			;5ad1
	cp 020h		;5ad2
	ld a,003h		;5ad4   ; el rumbo 3 es hacia abajo
	jr c,AL_CENTRO_SALIDA		;5ad6
	ld a,d			;5ad8
	or a			;5ad9
	ld a,004h		;5ada
	jr z,AL_CENTRO_SALIDA		;5adc
AL_CENTRO_DIAGONAL:
	ld a,002h		;5ade   ; y si no, en diagonal
	jr AL_CENTRO_SALIDA		;5ae0
AL_CENTRO_DERECHA:
	ex af,af'			;5ae2
	ld a,001h		;5ae3   ; el rumbo 1 es la diagonal de arriba a la derecha
	ex af,af'			;5ae5
	ld a,b			;5ae6   ; la suma de las dos distancias decide entre recto y diagonal
	add a,c			;5ae7
	cp 0a0h		;5ae8
	jr c,AL_CENTRO_DIAGONAL		;5aea
	cp 0e0h		;5aec   ; por debajo de 0xA0 la diferencia manda, y se va en diagonal
	ld a,001h		;5aee   ; el rumbo 1 tambien vale para la diagonal larga
	jr c,AL_CENTRO_SALIDA		;5af0
	ld a,000h		;5af2
	jr AL_CENTRO_SALIDA		;5af4
AL_CENTRO_ABAJO:
	cp c			;5af6   ; por debajo del centro, mirando si esta a la derecha o a la izquierda
	jr c,AL_CENTRO_IZQUIERDA		;5af7
	ex af,af'			;5af9
	ld a,002h		;5afa
	ex af,af'			;5afc
	ld a,b			;5afd
	add a,c			;5afe
	cp 0a0h		;5aff   ; con la suma de las dos distancias se decide entre recto y diagonal
	jr c,AL_CENTRO_ABAJO_DERECHA		;5b01
	cp 0e0h		;5b03
	ld a,005h		;5b05
	jr c,AL_CENTRO_SALIDA		;5b07
	ld a,006h		;5b09   ; el rumbo 6 es la diagonal de abajo a la izquierda
	jr AL_CENTRO_SALIDA		;5b0b
AL_CENTRO_IZQUIERDA:
	ex af,af'			;5b0d   ; por la izquierda hay que afinar mas: se compara la distancia mayor con la menor
	ld a,003h		;5b0e
	ex af,af'			;5b10
	ld a,b			;5b11
	sub c			;5b12
	ld d,000h		;5b13
	jp p,AL_CENTRO_AFINA		;5b15
	inc d			;5b18
	neg		;5b19
AL_CENTRO_AFINA:
	cp 020h		;5b1b   ; la mayor de las dos distancias contra la menor: eso da los octavos
	ld a,007h		;5b1d   ; el rumbo 7 es hacia la izquierda
	jr c,AL_CENTRO_SALIDA		;5b1f
	ld a,d			;5b21
	or a			;5b22
	ld a,000h		;5b23
	jr z,AL_CENTRO_SALIDA		;5b25
	ld a,006h		;5b27
	jr AL_CENTRO_SALIDA		;5b29
AL_CENTRO_ABAJO_DERECHA:
	ld a,004h		;5b2b   ; el rumbo 4 es hacia la derecha
AL_CENTRO_SALIDA:
	pop de			;5b2d
	pop bc			;5b2e
	ret			;5b2f
VECTOR_AL_CENTRO:		; Calcula el paso (Y, X) que lleva de la posicion DE al centro, dividiendo la distancia mayor entre la menor
	push bc			;5b30   ; el paso que lleva al centro: la distancia mayor partida por la menor
	push af			;5b31
	push hl			;5b32
	push de			;5b33
	ld a,(de)			;5b34
	ld c,a			;5b35
	inc de			;5b36
	ld a,(de)			;5b37
	ld b,a			;5b38
	ld a,055h		;5b39   ; y el centro que se toma aqui es 0x55, no el 0x60 de 0x5AB5
	ld d,003h		;5b3b   ; el 3 y el 1 son los dos sentidos en Y
	sub b			;5b3d
	jp p,VECTOR_RESTA_X		;5b3e
	ld d,001h		;5b41
	neg		;5b43
VECTOR_RESTA_X:
	ld l,a			;5b45   ; se guarda la distancia en X, ya en positivo
	ld a,055h		;5b46
	sub c			;5b48
	jp p,VECTOR_ORDENA		;5b49
	dec d			;5b4c
	neg		;5b4d
VECTOR_ORDENA:
	inc d			;5b4f   ; la mayor de las dos distancias va en H y la menor en L
	ld h,a			;5b50
	cp l			;5b51
	jp p,VECTOR_Y_MANDA		;5b52
	ld h,l			;5b55
	ld l,a			;5b56
	call DIVIDE		;5b57   ; dividir la mayor entre la menor da el paso de la coordenada corta
	ld b,001h		;5b5a   ; la coordenada larga avanza un pixel cada vez
	ld c,a			;5b5c
	jr VECTOR_GUARDA		;5b5d
VECTOR_Y_MANDA:
	call DIVIDE		;5b5f
	ld b,a			;5b62
	ld c,001h		;5b63
VECTOR_GUARDA:
	ld a,d			;5b65   ; el paso se guarda dos veces: una por coordenada
	pop de			;5b66
	pop hl			;5b67
	ld (hl),c			;5b68
	inc hl			;5b69
	ld (hl),c			;5b6a   ; la Y en dos sitios y la X en otros dos: la ficha lleva pareja de cuentas
	inc hl			;5b6b
	inc hl			;5b6c
	ld (hl),b			;5b6d
	inc hl			;5b6e
	ld (hl),b			;5b6f
	pop af			;5b70
	pop bc			;5b71
	ret			;5b72
PON_DISPARO_ENEMIGO:		; Deja la ficha con el paso que lleva al centro y el tiempo de vuelo
	call VECTOR_AL_CENTRO		;5b73   ; el paso al centro se guarda en la ficha, y ya vuela solo
	ex af,af'			;5b76
	dec hl			;5b77
	dec hl			;5b78
	ld (hl),b			;5b79
	bit 0,a		;5b7a
	jr z,DISPARO_ENEMIGO_GUARDA		;5b7c
	ld (hl),c			;5b7e
DISPARO_ENEMIGO_GUARDA:
	inc hl			;5b7f   ; el segundo componente va tres bytes mas alla
	inc hl			;5b80
	inc hl			;5b81
	ld (hl),b			;5b82
	cp 002h		;5b83   ; y solo se usa si la direccion pide las dos coordenadas
	ret c			;5b85
	ld (hl),c			;5b86
	ret			;5b87
DIVIDE:		; Divide H entre L por restas y deja el cociente en A
	push de			;5b88   ; dividir a base de restar
	ex de,hl			;5b89
	ld hl,0e1f2h		;5b8a   ; 0xE1F0 a 0xE1F2 son los tres bytes de trabajo de la division
	ld (hl),e			;5b8d
	dec hl			;5b8e
	ld (hl),d			;5b8f
	dec hl			;5b90
	ld (hl),000h		;5b91
	inc hl			;5b93
	ld b,008h		;5b94
DIVIDE_BUCLE:
	xor a			;5b96   ; ocho vueltas, un bit por vuelta
	rl (hl)		;5b97
	dec hl			;5b99
	rl (hl)		;5b9a
	ld a,(hl)			;5b9c
	inc hl			;5b9d
	inc hl			;5b9e
	sub (hl)			;5b9f   ; la resta que decide si el bit del cociente es 1 o 0
	dec hl			;5ba0
	jp m,DIVIDE_FIN		;5ba1
	dec hl			;5ba4
	ld (hl),a			;5ba5
	inc hl			;5ba6
	set 0,(hl)		;5ba7   ; la resta ha salido: el bit del cociente es 1
DIVIDE_FIN:
	djnz DIVIDE_BUCLE		;5ba9   ; ocho bits de cociente
	ld a,(hl)			;5bab
	pop de			;5bac
	ret			;5bad
SUELTA_DOS_MISILES_DE_ABAJO:		; De la epoca 3 en adelante, uno de cada treinta y dos enemigos trae ademas dos misiles que suben desde las dos esquinas de abajo (tabla de 0x5C13)
	call LEE_EPOCA		;5bae   ; en las epocas 1 y 2 no hay misiles de estos
	cp 003h		;5bb1
	ret c			;5bb3
	ld hl,0e126h		;5bb4
	call LEE_POR_JUGADOR		;5bb7
	and 01fh		;5bba   ; uno de cada treinta y dos enemigos los trae
	cp 008h		;5bbc
	ret nz			;5bbe
	inc (hl)			;5bbf   ; y se apunta uno mas
	ld hl,05c13h		;5bc0   ; dos misiles, y la tabla dice por donde y hacia donde
	ld b,002h		;5bc3
	exx			;5bc5
	ld hl,0e2a0h		;5bc6
	ld de,0e3ach		;5bc9
	ld b,002h		;5bcc   ; dos huecos de misil para estos
MISIL_DE_ABAJO_BUSCA_HUECO:
	ld a,(hl)			;5bce
	or a			;5bcf
	jr z,MISIL_DE_ABAJO_PON		;5bd0
MISIL_DE_ABAJO_SIGUIENTE:
	call SIGUIENTE_SPRITE		;5bd2
	call SUMA_9_A_HL		;5bd5   ; nueve bytes por ficha de misil
	djnz MISIL_DE_ABAJO_BUSCA_HUECO		;5bd8
	ret			;5bda
MISIL_DE_ABAJO_PON:
	push hl			;5bdb
	push de			;5bdc
	ld (hl),083h		;5bdd   ; estado 0x83: vivo, y con las dos banderas puestas
	inc hl			;5bdf
	ld (hl),000h		;5be0   ; el byte 1 a cero: cuenta puesta, sin girar
	inc hl			;5be2
	exx			;5be3   ; la tabla la lleva el juego alterno de registros
	ld a,(hl)			;5be4
	inc hl			;5be5
	push hl			;5be6
	exx			;5be7
	ld c,a			;5be8
	ld (hl),a			;5be9   ; el byte 2 de la ficha es la direccion en la que va el misil
	pop hl			;5bea
	ld a,(hl)			;5beb
	ld (de),a			;5bec
	inc hl			;5bed
	inc de			;5bee
	ld a,(hl)			;5bef
	ld (de),a			;5bf0
	inc de			;5bf1
	ld a,c			;5bf2
	rlca			;5bf3
	rlca			;5bf4
	add a,040h		;5bf5
	ld (de),a			;5bf7
	inc de			;5bf8
	ld a,001h		;5bf9   ; color 1 salvo en la epoca 5
	ld (de),a			;5bfb
	push hl			;5bfc
	call LEE_EPOCA		;5bfd
	pop hl			;5c00
	cp 005h		;5c01   ; que va de amarillo, como todo lo suyo
	jr nz,REFUERZO_OTRO		;5c03
	ld a,00ah		;5c05
	ld (de),a			;5c07
REFUERZO_OTRO:
	inc hl			;5c08   ; y a por el segundo misil de los dos
	push hl			;5c09
	exx			;5c0a
	pop hl			;5c0b
	dec b			;5c0c
	exx			;5c0d
	pop de			;5c0e
	pop hl			;5c0f
	jr nz,MISIL_DE_ABAJO_SIGUIENTE		;5c10
	ret			;5c12

; ----------------------------------------------------------------------
; DATOS misiles_de_abajo: Dos grupos de tres bytes (direccion, Y, X) para los
;   dos misiles que 0x5BAE suelta de la epoca 3 en adelante. Salen los dos de
;   la fila de abajo, 0xB0: uno por la izquierda (X=0x08) subiendo hacia la
;   derecha, y otro por la derecha (X=0xA8) subiendo hacia la izquierda. El
;   patron y el color no estan aqui: los calcula 0x5BF2 con la direccion
;   0x5c13..0x5c19  (6 bytes)
DATA_misiles_de_abajo:
	defb 001h,0b0h,008h	; 5c13
	defb 007h,0b0h,0a8h	; 5c16

; ======================================================================
; CODIGO 0x5c19..0x5fe3  (970 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LOS CHOQUES. Cada uno de los ocho disparos se pasa a coordenadas de pixel -la casilla de la tabla de nombres por ocho- y se cruza con los enemigos, con el pasajero y con el bicho grande. El bicho grande aguanta 24 impactos.
; ----------------------------------------------------------------------
MIRA_LOS_CHOQUES:
	ld hl,0e230h		;5c19   ; los ocho disparos contra todo lo que hay en pantalla
	ld b,008h		;5c1c   ; ocho disparos del jugador
CHOQUES_DE_UN_DISPARO:
	push bc			;5c1e
	push hl			;5c1f
	ld a,(hl)			;5c20   ; un disparo apagado no choca con nada
	or a			;5c21
	jp z,CHOQUE_DISPARO_SIGUIENTE		;5c22
	ld d,a			;5c25
	inc hl			;5c26
	ld e,(hl)			;5c27
	inc hl			;5c28
	inc hl			;5c29
	ld a,e			;5c2a   ; de casilla de la tabla de nombres a coordenada en pixeles
	and 01fh		;5c2b
	rlca			;5c2d   ; tres rotaciones: la columna por ocho, que son los pixeles
	rlca			;5c2e
	rlca			;5c2f
	ld b,a			;5c30
	ld a,e			;5c31
	rr d		;5c32   ; la fila sale de dividir la direccion entre 32, y de ahi la altura
	rra			;5c34
	rr d		;5c35
	rra			;5c37
	and 0f8h		;5c38
	ld e,a			;5c3a
	ld d,b			;5c3b
	ld a,(hl)			;5c3c   ; el byte 3 es cual de los ocho dibujos lleva el disparo
	dec a			;5c3d
	push hl			;5c3e
	ld hl,05fe3h		;5c3f
	call LEE_PALABRA_DE_TABLA		;5c42
	call SALTA_A_HL		;5c45
	pop hl			;5c48
	exx			;5c49
	ld de,0e2d0h		;5c4a   ; primero, contra los siete aviones de la epoca
	ld hl,0e38ch		;5c4d
	ld b,006h		;5c50   ; seis fichas se miran aqui, aunque el grupo que mueve 0x5236 tiene siete
CHOQUE_CON_ACTOR:
	push bc			;5c52
	push hl			;5c53
	push de			;5c54
	call MIRA_SI_LA_FICHA_ESTA_VIVA		;5c55   ; las fichas libres o reventando no cuentan
	jp nc,CHOQUE_ACTOR_SIGUIENTE		;5c58
	ld a,000h		;5c5b
	call CHOCAN		;5c5d   ; con un margen de cero: los dos cuadrados de 16 tienen que solaparse
	jp nc,CHOQUE_ACTOR_SIGUIENTE		;5c60
	pop de			;5c63
	pop hl			;5c64
	pop bc			;5c65
	inc hl			;5c66
	inc hl			;5c67
	ld (hl),008h		;5c68   ; patron 8 y color 8: el primer paso de la explosion
	inc hl			;5c6a
	ld (hl),008h		;5c6b
	push hl			;5c6d
	call LEE_EPOCA		;5c6e
	pop hl			;5c71
	cp 005h		;5c72   ; menos en la epoca 5, que va de amarillo
	jr nz,ACTOR_TOCADO		;5c74
	ld (hl),00ah		;5c76
ACTOR_TOCADO:		; Cincuenta puntos y la explosion
	ld a,0c4h		;5c78   ; estado 0xC4: reventando, con la cuenta puesta
	ld (de),a			;5c7a
	ld bc,00050h		;5c7b   ; derribar un actor son cincuenta puntos
	call SUMA_PUNTOS		;5c7e
	ld a,(0e031h)		;5c81   ; el sonido no se pisa si en el canal 3 hay algo mas urgente
	or a			;5c84
	jr z,ACTOR_TOCADO_SONIDO		;5c85
	ld a,(0e037h)		;5c87
	cp 003h		;5c8a
	jp c,CHOQUE_FIN		;5c8c
ACTOR_TOCADO_SONIDO:
	ld hl,07e4ch		;5c8f   ; el canal 2 se calla apuntandolo a un 0xFF suelto
	ld (0e028h),hl		;5c92
	ld hl,07d57h		;5c95
	ld (0e030h),hl		;5c98
	ld a,003h		;5c9b
	ld (0e02fh),a		;5c9d
	ld (0e037h),a		;5ca0
	jp CHOQUE_FIN		;5ca3
CHOQUE_ACTOR_SIGUIENTE:
	pop hl			;5ca6
	call SUMA_10_A_HL		;5ca7   ; diez bytes por ficha
	ex de,hl			;5caa
	pop hl			;5cab
	call SUMA_4_A_HL		;5cac   ; cuatro bytes por sprite
	pop bc			;5caf
	dec b			;5cb0
	jp nz,CHOQUE_CON_ACTOR		;5cb1
	ld hl,0e200h		;5cb4   ; luego, contra el bicho grande, que no es un sprite sino casillas
	ld a,(hl)			;5cb7
	and 0e0h		;5cb8
	cp 080h		;5cba   ; el bicho solo choca mientras esta volando
	jp nz,CHOQUE_CON_LO_QUE_SUELTA_LA_EPOCA		;5cbc
	inc hl			;5cbf
	ld d,(hl)			;5cc0
	inc hl			;5cc1
	ld e,(hl)			;5cc2
	ld a,e			;5cc3   ; la casilla del bicho, pasada a pixeles con su media casilla de correccion
	and 01fh		;5cc4
	rlca			;5cc6   ; tres rotaciones: la columna por ocho
	rlca			;5cc7
	rlca			;5cc8
	add a,008h		;5cc9
	ld b,a			;5ccb
	ld a,e			;5ccc
	rr d		;5ccd
	rra			;5ccf
	rr d		;5cd0
	rra			;5cd2
	and 0f8h		;5cd3
	add a,008h		;5cd5
	ld c,a			;5cd7
	exx			;5cd8   ; la posicion del disparo se pasa del juego alterno al normal
	push de			;5cd9
	exx			;5cda
	pop de			;5cdb
	push hl			;5cdc
	call LEE_EPOCA		;5cdd
	pop hl			;5ce0
	bit 0,a		;5ce1   ; en las epocas impares el bicho es mas ancho: margen 5 en vez de 1
	ld a,005h		;5ce3
	jr nz,CHOQUE_CON_EL_BICHO_GRANDE		;5ce5
	ld a,001h		;5ce7
CHOQUE_CON_EL_BICHO_GRANDE:
	call CHOCAN		;5ce9
	jp nc,CHOQUE_CON_LO_QUE_SUELTA_LA_EPOCA		;5cec
	ld de,0e204h		;5cef
	ld a,(de)			;5cf2
	inc a			;5cf3   ; un impacto mas de los veinticuatro que aguanta
	ld (de),a			;5cf4   ; y se apunta el impacto
	cp 018h		;5cf5   ; el bicho grande aguanta veinticuatro impactos
	jp nz,CHOQUE_FIN		;5cf7
	xor a			;5cfa   ; los impactos vuelven a cero
	ld (de),a			;5cfb
	push bc			;5cfc
	ld bc,00500h		;5cfd   ; y derribarlo son quinientos puntos
	call SUMA_PUNTOS		;5d00
	pop bc			;5d03
	ld hl,07eedh		;5d04
	ld (0e030h),hl		;5d07   ; el canal 5 lleva el sonido de que el bicho revienta
	ld hl,0e200h		;5d0a
	ld (hl),0c4h		;5d0d   ; el bicho revienta
	exx			;5d0f
	dec hl			;5d10
	dec hl			;5d11
	dec hl			;5d12
	ld (hl),000h		;5d13   ; y el disparo que lo remato se apaga
	exx			;5d15
	ld hl,0e3d8h		;5d16   ; dos explosiones, una encima de otra, porque el bicho ocupa el doble
	ld (hl),c			;5d19
	inc hl			;5d1a
	ld (hl),b			;5d1b
	inc hl			;5d1c
	ld (hl),010h		;5d1d   ; patron 0x10 y color 8: la explosion gorda
	inc hl			;5d1f
	ld (hl),008h		;5d20
	push hl			;5d22
	call LEE_EPOCA		;5d23
	pop hl			;5d26
	cp 005h		;5d27
	jr nz,BICHO_GRANDE_MUERE		;5d29
	ld (hl),00ah		;5d2b   ; en la epoca 5 la explosion va de amarillo
BICHO_GRANDE_MUERE:
	inc hl			;5d2d   ; la segunda explosion tapa la otra mitad del bicho
	ld (hl),c			;5d2e
	inc hl			;5d2f
	ld a,b			;5d30
	add a,010h		;5d31   ; la segunda, dieciseis pixeles mas a la derecha
	ld (hl),a			;5d33
	inc hl			;5d34
	ld (hl),014h		;5d35
	inc hl			;5d37
	ld (hl),008h		;5d38
	push hl			;5d3a
	call LEE_EPOCA		;5d3b
	pop hl			;5d3e
	cp 005h		;5d3f
	jr nz,BICHO_GRANDE_EXPLOTA		;5d41
	ld (hl),00ah		;5d43
BICHO_GRANDE_EXPLOTA:
	ld hl,(0e201h)		;5d45
	ld d,l			;5d48
	ld e,h			;5d49
	ld hl,06909h		;5d4a   ; y se borra de la tabla de nombres pintando encima el bloque de 0x6909
	ld c,004h		;5d4d   ; cuatro filas de bloque
	call PINTA_BLOQUE_EN_NOMBRES		;5d4f
	call MATA_A_TODOS		;5d52   ; y se lleva por delante a todo lo que hay en pantalla
	pop hl			;5d55
	pop hl			;5d56
	pop hl			;5d57
	ld a,010h		;5d58   ; dieciseis puntos de respiro, unos diez segundos, antes de seguir
	ld (0e018h),a		;5d5a
	jp INTERRUPCION_SPRITES		;5d5d
CHOQUE_CON_LO_QUE_SUELTA_LA_EPOCA:
	call LEE_EPOCA		;5d60   ; y por ultimo contra lo que suelta la epoca: bombas en la 1
	dec a			;5d63
	jr nz,CHOQUE_CON_LOS_MISILES_2		;5d64
	ld de,0e260h		;5d66
	ld hl,0e3ach		;5d69
	ld b,004h		;5d6c   ; cuatro bombas
CHOQUE_CON_UNA_BOMBA:
	push bc			;5d6e   ; las cuatro bombas contra el disparo
	push hl			;5d6f
	push de			;5d70
	call MIRA_SI_LA_FICHA_ESTA_VIVA		;5d71
	jr nc,CHOQUE_BOMBA_SIGUIENTE		;5d74
	ld a,000h		;5d76
	call CHOCAN		;5d78
	jr c,MISIL_TOCADO		;5d7b
CHOQUE_BOMBA_SIGUIENTE:
	pop de			;5d7d   ; tres bytes por bomba
	inc de			;5d7e
	inc de			;5d7f
	inc de			;5d80
	pop hl			;5d81
	call SUMA_4_A_HL		;5d82   ; cuatro bytes por sprite
	pop bc			;5d85
	djnz CHOQUE_CON_UNA_BOMBA		;5d86   ; cuatro bombas
	jp CHOQUE_FIN		;5d88
CHOQUE_CON_LOS_MISILES_2:
	call LEE_EPOCA		;5d8b   ; y misiles de la 3 en adelante; en la 2 no hay nada de esto
	cp 003h		;5d8e
	jp c,CHOQUE_FIN		;5d90
	ld de,0e2a0h		;5d93
	ld hl,0e3ach		;5d96
	ld b,004h		;5d99   ; cuatro misiles
CHOQUE_MISIL_BUCLE:
	push bc			;5d9b   ; los cuatro misiles, uno a uno
	push hl			;5d9c
	push de			;5d9d
	call MIRA_SI_LA_FICHA_ESTA_VIVA		;5d9e
	jr nc,CHOQUE_MISIL_SIGUIENTE		;5da1
	ld a,000h		;5da3
	call CHOCAN		;5da5
	jr nc,CHOQUE_MISIL_SIGUIENTE		;5da8
MISIL_TOCADO:		; Quinientos puntos
	pop de			;5daa   ; un misil derribado deja explosion, como los aviones
	pop hl			;5dab
	pop bc			;5dac
	inc hl			;5dad
	inc hl			;5dae
	ld (hl),008h		;5daf   ; tambien revientan con su explosion
	inc hl			;5db1
	ld (hl),008h		;5db2
	push hl			;5db4
	call LEE_EPOCA		;5db5
	pop hl			;5db8
	cp 005h		;5db9
	jr nz,MISIL_TOCADO_PUNTOS		;5dbb
	ld (hl),00ah		;5dbd
MISIL_TOCADO_PUNTOS:
	ld a,0c4h		;5dbf
	ld (de),a			;5dc1
	ld bc,00500h		;5dc2   ; los enemigos de la epoca valen quinientos puntos
	call SUMA_PUNTOS		;5dc5
	jr CHOQUE_FIN		;5dc8
CHOQUE_MISIL_SIGUIENTE:
	pop hl			;5dca   ; nueve por misil
	call SUMA_9_A_HL		;5dcb   ; nueve bytes por misil
	ex de,hl			;5dce
	pop hl			;5dcf
	call SUMA_4_A_HL		;5dd0
	pop bc			;5dd3
	djnz CHOQUE_MISIL_BUCLE		;5dd4
CHOQUE_FIN:
	exx			;5dd6
CHOQUE_DISPARO_SIGUIENTE:
	pop hl			;5dd7   ; el siguiente de los ocho disparos
	call SUMA_4_A_HL		;5dd8   ; cuatro bytes por ficha de disparo
	pop bc			;5ddb
	dec b			;5ddc
	jp nz,CHOQUES_DE_UN_DISPARO		;5ddd
	ret			;5de0
MATA_A_TODOS:		; Al morir el bicho grande se lleva por delante a todo lo que hay en pantalla
	ld de,0e2d0h		;5de1
	ld hl,0e38ch		;5de4
	ld b,006h		;5de7   ; seis fichas otra vez, como en 0x5C50
MATA_A_TODOS_BUCLE:
	push bc			;5de9   ; los siete aviones se van todos a la vez
	push hl			;5dea
	push de			;5deb
	ld a,(de)			;5dec
	and 0e0h		;5ded
	cp 080h		;5def
	jr nz,MATA_A_TODOS_SIGUIENTE		;5df1
	ld a,0c4h		;5df3   ; todos revientan a la vez, con la misma explosion
	ld (de),a			;5df5
	inc hl			;5df6
	inc hl			;5df7
	ld (hl),008h		;5df8
	inc hl			;5dfa
	ld (hl),008h		;5dfb
	push hl			;5dfd
	call LEE_EPOCA		;5dfe
	pop hl			;5e01
	cp 005h		;5e02
	jr nz,MATA_A_TODOS_SIGUIENTE		;5e04
	ld (hl),00ah		;5e06
MATA_A_TODOS_SIGUIENTE:
	pop hl			;5e08   ; el avion enemigo son diez bytes
	call SUMA_10_A_HL		;5e09   ; diez bytes por ficha
	ex de,hl			;5e0c
	pop hl			;5e0d
	call SUMA_4_A_HL		;5e0e
	pop bc			;5e11
	djnz MATA_A_TODOS_BUCLE		;5e12   ; tantas fichas como diga B
	ld hl,0e3a8h		;5e14   ; y los doce sprites de todo lo demas, fuera de la pantalla
	ld b,00ch		;5e17   ; doce sprites
APAGA_LOS_DEMAS_SPRITES:
	ld (hl),0d1h		;5e19
	call SUMA_4_A_HL		;5e1b   ; cuatro bytes por atributo
	djnz APAGA_LOS_DEMAS_SPRITES		;5e1e
	ret			;5e20
CHOQUE_CON_EL_PASAJERO:		; Recogerlo son quinientos puntos
	ld de,0e2ceh		;5e21
	ld hl,0e3a8h		;5e24
	ld a,(de)			;5e27   ; sin pasajero en pantalla no hay choque que mirar
	or a			;5e28
	ret z			;5e29
	push hl			;5e2a
	push de			;5e2b
	ld bc,0545ch		;5e2c   ; el avion siempre en 0x54, 0x5C: es lo unico que no se mueve
	ld e,(hl)			;5e2f
	inc hl			;5e30
	ld d,(hl)			;5e31
	ld a,003h		;5e32
	call CHOCAN		;5e34   ; con el pasajero el margen es 3: se recoge con tocarlo de refilon
	pop de			;5e37
	pop hl			;5e38
	ret nc			;5e39
	xor a			;5e3a
	ld (de),a			;5e3b   ; el pasajero desaparece de la ficha
	ld (hl),0d1h		;5e3c   ; y su sprite se va a Y=0xD1
	ld bc,00500h		;5e3e   ; y recoger al pasajero, otros quinientos
	call SUMA_PUNTOS		;5e41
	ld a,(0e029h)		;5e44   ; y si el canal 2 lleva algo mas urgente, se recoge sin sonido
	or a			;5e47
	ld hl,0e02fh		;5e48
	jr z,PASAJERO_SONIDO		;5e4b
	ld a,(hl)			;5e4d
	cp 008h		;5e4e
	ret c			;5e50
PASAJERO_SONIDO:
	ld (hl),008h		;5e51   ; la prioridad se sube a 8
	ld hl,07e4dh		;5e53
	ld (0e028h),hl		;5e56
	ret			;5e59
CHOQUE_DEL_JUGADOR:		; Mira si el avion del jugador toca algo
	ld hl,0e200h		;5e5a   ; el avion del jugador contra el bicho grande
	ld a,(hl)			;5e5d
	and 0e0h		;5e5e
	cp 080h		;5e60
	jp nz,CHOQUE_JUGADOR_FIN		;5e62
	inc hl			;5e65
	ld d,(hl)			;5e66
	inc hl			;5e67
	ld e,(hl)			;5e68
	ld a,e			;5e69
	and 01fh		;5e6a   ; la casilla del bicho, pasada a pixeles, con medio caracter de correccion
	rlca			;5e6c   ; tres rotaciones: la columna por ocho
	rlca			;5e6d
	rlca			;5e6e
	add a,008h		;5e6f   ; y medio caracter mas para caer en el centro de la casilla
	ld b,a			;5e71
	ld a,e			;5e72
	rr d		;5e73
	rra			;5e75
	rr d		;5e76
	rra			;5e78
	and 0f8h		;5e79
	add a,008h		;5e7b
	ld e,a			;5e7d
	ld d,b			;5e7e
	ld bc,0545ch		;5e7f   ; el avion siempre esta en el mismo sitio: 0x54 y 0x5C
	ld a,004h		;5e82
	push hl			;5e84
	call CHOCAN		;5e85
	pop hl			;5e88
	jp nc,CHOQUE_JUGADOR_FIN		;5e89
	dec hl			;5e8c
	dec hl			;5e8d
	ld (hl),0c4h		;5e8e   ; los dos revientan
	ld hl,0e3d8h		;5e90
	ld (hl),e			;5e93
	inc hl			;5e94
	ld (hl),d			;5e95
	inc hl			;5e96
	ld (hl),010h		;5e97   ; patron 0x10 y color 8: la explosion gorda
	inc hl			;5e99
	ld (hl),008h		;5e9a
	push hl			;5e9c
	call LEE_EPOCA		;5e9d
	pop hl			;5ea0
	cp 005h		;5ea1
	jr nz,CHOQUE_JUGADOR_SIGUIENTE		;5ea3
	ld (hl),00ah		;5ea5   ; en la epoca 5 la explosion va de amarillo
CHOQUE_JUGADOR_SIGUIENTE:
	inc hl			;5ea7   ; el segundo sprite de la explosion del avion
	ld (hl),e			;5ea8
	inc hl			;5ea9
	ld a,d			;5eaa
	add a,010h		;5eab   ; la segunda explosion, dieciseis pixeles a la derecha de la primera
	ld (hl),a			;5ead
	inc hl			;5eae
	ld (hl),014h		;5eaf
	inc hl			;5eb1
	ld (hl),008h		;5eb2
	push hl			;5eb4
	call LEE_EPOCA		;5eb5
	pop hl			;5eb8
	cp 005h		;5eb9
	jr nz,CHOQUE_JUGADOR_MUERE		;5ebb
	ld (hl),00ah		;5ebd
CHOQUE_JUGADOR_MUERE:
	call MATA_A_TODOS		;5ebf   ; el jugador se lleva por delante todo lo que hay en pantalla
	ld hl,(0e201h)		;5ec2
	ld d,l			;5ec5
	ld e,h			;5ec6
	ld hl,06909h		;5ec7   ; y el bicho se borra de la tabla de nombres
	ld c,004h		;5eca   ; cuatro filas de bloque
	call PINTA_BLOQUE_EN_NOMBRES		;5ecc
	ld a,001h		;5ecf
	ld (0e052h),a		;5ed1   ; 0xE052 avisa de que la partida se ha acabado
	jp CHOQUE_MISIL_SIGUE		;5ed4
CHOQUE_JUGADOR_FIN:
	ret			;5ed7
CHOQUE_CON_LOS_AVIONES:		; El avion del jugador contra los siete aviones de la epoca
	ld de,0e2d0h		;5ed8
	ld hl,0e38ch		;5edb
	ld b,006h		;5ede   ; seis fichas de avion
CHOQUE_CON_UN_AVION:
	push hl			;5ee0
	push de			;5ee1
	push bc			;5ee2
	ld a,(de)			;5ee3   ; solo chocan los aviones que estan volando
	and 0e0h		;5ee4
	cp 080h		;5ee6   ; y solo los aviones que estan volando
	jr nz,CHOQUE_AVION_SIGUE		;5ee8
	ld bc,0545ch		;5eea
	ld e,(hl)			;5eed
	inc hl			;5eee
	ld d,(hl)			;5eef
	ld a,003h		;5ef0   ; margen 3 tambien contra los aviones
	call CHOCAN		;5ef2
	jr nc,CHOQUE_AVION_SIGUE		;5ef5
	pop bc			;5ef7
	pop de			;5ef8
	pop hl			;5ef9
	ld a,000h		;5efa
	ld (de),a			;5efc   ; el avion desaparece de su ficha
	ld a,0d1h		;5efd
	ld (hl),a			;5eff   ; y su sprite se va a Y=0xD1
	jp CHOQUE_MISIL_SIGUE		;5f00
CHOQUE_AVION_SIGUE:
	pop bc			;5f03   ; diez bytes por ficha de avion
	pop hl			;5f04
	call SUMA_10_A_HL		;5f05   ; diez bytes por ficha
	ex de,hl			;5f08
	pop hl			;5f09
	call SUMA_4_A_HL		;5f0a
	djnz CHOQUE_CON_UN_AVION		;5f0d
	ret			;5f0f
CHOQUE_CON_LOS_DISPAROS_ENEMIGOS:
	ld de,0e270h		;5f10
	ld hl,0e3bch		;5f13
	ld b,006h		;5f16   ; seis disparos enemigos
CHOQUE_CON_UN_DISPARO_ENEMIGO:
	push bc			;5f18   ; y ninguno con el estado a cero
	push hl			;5f19
	push de			;5f1a
	ld a,(de)			;5f1b
	or a			;5f1c
	jr z,CHOQUE_DISPARO_ENEMIGO_SIGUIENTE		;5f1d
	ld e,(hl)			;5f1f
	inc hl			;5f20
	ld d,(hl)			;5f21
	ld bc,0545ch		;5f22
	ld a,002h		;5f25   ; y margen 2 contra los disparos, que son mas pequenos
	call CHOCAN		;5f27
	jr c,CHOQUE_CON_UN_MISIL		;5f2a
CHOQUE_DISPARO_ENEMIGO_SIGUIENTE:
	pop hl			;5f2c   ; siete por disparo enemigo
	call SUMA_7_A_HL		;5f2d
	ex de,hl			;5f30
	pop hl			;5f31
	call SUMA_4_A_HL		;5f32
	pop bc			;5f35
	djnz CHOQUE_CON_UN_DISPARO_ENEMIGO		;5f36   ; seis disparos
	ld de,0e260h		;5f38
	ld hl,0e3ach		;5f3b
	ld b,004h		;5f3e   ; cuatro fichas de lo que suelta la epoca
CHOQUE_CON_EL_PASAJERO_2:
	push bc			;5f40
	push hl			;5f41
	push de			;5f42
	ld a,(de)			;5f43   ; y lo mismo con lo que suelta la epoca
	and 0e0h		;5f44
	cp 080h		;5f46
	jr nz,CHOQUE_PASAJERO_2		;5f48
	ld e,(hl)			;5f4a
	inc hl			;5f4b
	ld d,(hl)			;5f4c
	ld bc,0545ch		;5f4d   ; el avion siempre en 0x54, 0x5C
	ld a,002h		;5f50
	call CHOCAN		;5f52
	jr c,CHOQUE_CON_UN_MISIL		;5f55
CHOQUE_PASAJERO_2:
	pop de			;5f57   ; los tres bytes de la ficha del pasajero
	inc de			;5f58
	inc de			;5f59
	inc de			;5f5a
	pop hl			;5f5b   ; los cuatro bytes del sprite
	call SUMA_4_A_HL		;5f5c
	pop bc			;5f5f
	djnz CHOQUE_CON_EL_PASAJERO_2		;5f60   ; cuatro fichas
	ld de,0e2a0h		;5f62
	ld hl,0e3ach		;5f65
	ld b,004h		;5f68   ; cuatro misiles
CHOQUE_PASAJERO_SIGUE:
	push bc			;5f6a
	push hl			;5f6b
	push de			;5f6c
	ld a,(de)			;5f6d   ; solo los misiles que estan volando
	and 0e0h		;5f6e
	cp 080h		;5f70
	jr nz,CHOQUE_CON_LOS_MISILES		;5f72
	ld e,(hl)			;5f74
	inc hl			;5f75
	ld d,(hl)			;5f76
	ld bc,0545ch		;5f77   ; el avion, otra vez en su sitio de siempre
	ld a,002h		;5f7a
	call CHOCAN		;5f7c
	jr c,CHOQUE_CON_UN_MISIL		;5f7f
CHOQUE_CON_LOS_MISILES:
	pop hl			;5f81   ; nueve bytes por ficha de misil, cuatro por sprite
	call SUMA_9_A_HL		;5f82
	ex de,hl			;5f85
	pop hl			;5f86
	call SUMA_4_A_HL		;5f87
	pop bc			;5f8a
	djnz CHOQUE_PASAJERO_SIGUE		;5f8b   ; cuatro misiles
	ret			;5f8d
CHOQUE_CON_UN_MISIL:
	pop de			;5f8e   ; los cuatro misiles contra el avion
	pop hl			;5f8f
	pop bc			;5f90
	xor a			;5f91
	ld (de),a			;5f92   ; el misil desaparece de su ficha
	ld a,0d1h		;5f93
	ld (hl),a			;5f95
	ld a,008h		;5f96
	ld (0e382h),a		;5f98   ; patron 8: el primer paso de la explosion
CHOQUE_MISIL_SIGUE:
	ld hl,0e145h		;5f9b   ; y al chocar con un misil, el avion se estrella
	ld (hl),0c4h		;5f9e   ; el estado 0xC0 arranca la explosion del avion
	ld hl,0e382h		;5fa0
	ld (hl),008h		;5fa3
	inc hl			;5fa5
	ld (hl),008h		;5fa6
	push hl			;5fa8
	call LEE_EPOCA		;5fa9
	pop hl			;5fac
	cp 005h		;5fad
	jr nz,MUERE_EL_JUGADOR		;5faf
	ld (hl),00ah		;5fb1
MUERE_EL_JUGADOR:		; Sonido, explosion y el estado 0xC0
	ld hl,07dc3h		;5fb3   ; el avion del jugador se estrella, y su sonido se lleva por delante a los demas
	ld (0e020h),hl		;5fb6
	ld hl,07e0ch		;5fb9
	ld (0e028h),hl		;5fbc
	ld hl,07d57h		;5fbf   ; el sonido del choque, con prioridad 3
	ld (0e030h),hl		;5fc2
	ld a,002h		;5fc5   ; los tres canales, con prioridad 2
	ld (0e027h),a		;5fc7
	ld (0e02fh),a		;5fca
	ld (0e037h),a		;5fcd
	ret			;5fd0
MIRA_SI_LA_FICHA_ESTA_VIVA:		; Devuelve carry y la posicion si la ficha de DE esta en juego
	ld a,(de)			;5fd1   ; una ficha vale si su estado es 0x80; si no, no hay choque que mirar
	and 0e0h		;5fd2
	cp 080h		;5fd4
	jr nz,FICHA_LIBRE		;5fd6
	ld c,(hl)			;5fd8   ; y de paso deja la posicion del sprite en DE
	inc hl			;5fd9
	ld b,(hl)			;5fda
	exx			;5fdb
	push de			;5fdc
	exx			;5fdd
	pop de			;5fde
	scf			;5fdf   ; y con carry, la ficha esta viva
	ret			;5fe0
FICHA_LIBRE:
	or a			;5fe1   ; y si no, carry a cero
	ret			;5fe2

; ----------------------------------------------------------------------
; DATOS correccion_del_disparo: Ocho rutinas, una por dibujo del disparo del
;   jugador. Destino del despachador de 0x5C3F
;   0x5fe3..0x5ff3  (16 bytes)
DATA_correccion_del_disparo:
	defw 05ff7h	; 5fe3  -> PASO_QUIETO
	defw 05ff3h	; 5fe5  -> PASO_ARRIBA_3
	defw 05ff8h	; 5fe7  -> PASO_ARRIBA_6
	defw 05ffdh	; 5fe9  -> PASO_ARRIBA_6_DERECHA_3
	defw 06005h	; 5feb  -> PASO_ARRIBA_6_DERECHA_6
	defw 0600dh	; 5fed  -> PASO_ARRIBA_3_DERECHA_6
	defw 06008h	; 5fef  -> PASO_DERECHA_6
	defw 06000h	; 5ff1  -> PASO_DERECHA_3

; ======================================================================
; CODIGO 0x5ff3..0x6012  (31 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; DONDE CAE EL DISPARO DENTRO DE SU CASILLA. El disparo del jugador no es un sprite: es un caracter, y de sus ocho dibujos (0x54F6) cada uno lleva el punto en un sitio distinto de la casilla de 8x8. Antes de cruzarlo con nadie, 0x5C3F le suma la correccion que le toca: cero, tres o seis pixeles arriba y a la derecha. Sin esto los choques saldrian desviados hasta seis pixeles.
; ----------------------------------------------------------------------
PASO_ARRIBA_3:
	ld a,d			;5ff3   ; el dibujo 1 tiene el punto tres pixeles mas abajo
	add a,003h		;5ff4
	ld d,a			;5ff6
PASO_QUIETO:
	ret			;5ff7   ; el 2 lo tiene justo en la esquina, sin correccion
PASO_ARRIBA_6:
	ld a,d			;5ff8   ; el 3, seis pixeles
	add a,006h		;5ff9
	ld d,a			;5ffb
	ret			;5ffc
PASO_ARRIBA_6_DERECHA_3:
	call PASO_ARRIBA_6		;5ffd
PASO_DERECHA_3:
	ld a,e			;6000
	add a,003h		;6001
	ld e,a			;6003
	ret			;6004
PASO_ARRIBA_6_DERECHA_6:
	call PASO_ARRIBA_6		;6005
PASO_DERECHA_6:
	ld a,e			;6008
	add a,006h		;6009
	ld e,a			;600b
	ret			;600c
PASO_ARRIBA_3_DERECHA_6:
	call PASO_ARRIBA_3		;600d   ; y el 8, tres abajo y seis a la derecha
	jr PASO_DERECHA_6		;6010

; ----------------------------------------------------------------------
; DATOS ret_suelto: Un byte 0xC9 al que no llega nadie, entre el ultimo
;   movimiento de 0x600D y la rutina de 0x6013
;   0x6012..0x6013  (1 bytes)
DATA_ret_suelto:
	defb 0c9h	; 6012

; ======================================================================
; CODIGO 0x6013..0x605c  (73 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL PASO DE LOS SIETE ACTORES. Recorre las siete fichas de 0xE2D0 y le da a cada una el paso de su comportamiento, que sale de la tabla de 0x605C.
; ----------------------------------------------------------------------
PASO_DE_LOS_ACTORES_2:
	ld hl,0e2d0h		;6013   ; las siete fichas de 0xE2D0, una a una
	ld de,0e38ch		;6016
	ld b,007h		;6019   ; siete fichas de actor
PASO_DE_UN_ACTOR:
	push hl			;601b
	push de			;601c
	push bc			;601d
	ld a,(hl)			;601e   ; el estado va en los tres bits de arriba: 0 la ficha esta libre
	and 0e0h		;601f
	jp z,ACTOR_SIGUIENTE		;6021
	cp 080h		;6024   ; 0x80 es el actor volando, y ahi se va derecho al despachador
	jr z,$+70		;6026
	cp 0c0h		;6028   ; 0xC0 es el actor reventando: se le acaba la cuenta y desaparece
	jr z,ACTOR_MIRA_TIEMPO		;602a
	ld a,(hl)			;602c
	and 007h		;602d   ; los tres bits bajos son la cuenta de la explosion
	jr z,ACTOR_ARRANCA		;602f
	jr ACTOR_BAJA_TIEMPO		;6031
ACTOR_ARRANCA:
	xor a			;6033   ; se acabo: la ficha queda libre y el sprite se manda a Y=0xD1, fuera
	ld (hl),a			;6034
	ld a,0d1h		;6035
	ld (de),a			;6037
	ld hl,0e120h		;6038
	call LEE_JUGADOR		;603b
	jr z,ACTOR_CUENTA		;603e
	inc hl			;6040
	inc hl			;6041
ACTOR_CUENTA:
	ld a,(hl)			;6042   ; uno menos de los que faltan por derribar en la fase
	or a			;6043
	jr z,ACTOR_BAJA_CUENTA		;6044
	dec (hl)			;6046
ACTOR_BAJA_CUENTA:
	inc hl			;6047   ; y uno menos de los que hay en pantalla ahora mismo
	dec (hl)			;6048
	jr $+48		;6049
ACTOR_MIRA_TIEMPO:
	ld a,(hl)			;604b
	and 007h		;604c   ; los tres bits bajos son la cuenta
	jr z,ACTOR_REARMA		;604e
ACTOR_BAJA_TIEMPO:
	dec (hl)			;6050
	jr $+40		;6051
ACTOR_REARMA:
	ld (hl),0a4h		;6053   ; estado 0xA4: vuelve a la vida con la cuenta puesta
	inc de			;6055
	inc de			;6056
	ld a,00ch		;6057   ; patron 0x0C: el primer dibujo del actor
	ld (de),a			;6059
	jr $+31		;605a

; ----------------------------------------------------------------------
; DATOS tabla_605c: Ocho rutinas, destino del despachador de 0x6070
;   0x605c..0x606c  (16 bytes)
DATA_tabla_605c:
	defw 06087h	; 605c  -> COMPORTAMIENTO_1
	defw 060c5h	; 605e  -> COMPORTAMIENTO_2
	defw 060f8h	; 6060  -> COMPORTAMIENTO_3
	defw 0612ch	; 6062  -> COMPORTAMIENTO_4
	defw 06186h	; 6064  -> COMPORTAMIENTO_5
	defw 061b2h	; 6066  -> COMPORTAMIENTO_6
	defw 061f1h	; 6068  -> COMPORTAMIENTO_7
	defw 0629ch	; 606a  -> COMPORTAMIENTO_8

; ======================================================================
; CODIGO 0x606c..0x62e2  (630 bytes)
; ======================================================================


ACTOR_DESPACHA:
	inc hl			;606c   ; el byte 1 de la ficha dice cual de los ocho comportamientos le toca
	ld a,(hl)			;606d
	ld b,h			;606e
	ld c,l			;606f
	ld hl,0605ch		;6070   ; ocho comportamientos, y cada ficha lleva el suyo
	call LEE_PALABRA_DE_TABLA		;6073
	call SALTA_A_HL		;6076
ACTOR_SIGUIENTE:
	pop bc			;6079
	pop de			;607a
	pop hl			;607b
	call SIGUIENTE_SPRITE		;607c   ; cada ficha son 16 bytes, y su sprite cuatro
	call SUMA_10_A_HL		;607f   ; diez bytes por ficha
	dec b			;6082
	jp nz,PASO_DE_UN_ACTOR		;6083
	ret			;6086

; ----------------------------------------------------------------------
; LOS OCHO COMPORTAMIENTOS. Cada actor lleva en su ficha cual de estos ocho le toca; todos acaban llamando al mismo movedor, lo que cambia es como eligen la direccion y cada cuanto la cambian.
; ----------------------------------------------------------------------
COMPORTAMIENTO_1:		; Cambia de rumbo al azar cuando se le acaba la cuenta
	ld h,b			;6087   ; COMPORTAMIENTO 1: el byte 2 es la cuenta atras hasta el siguiente giro
	ld l,c			;6088
	inc hl			;6089
	dec (hl)			;608a   ; y mientras no llegue a cero, no gira
	jr nz,COMPORTAMIENTO_1_MUEVE		;608b
	dec hl			;608d
	dec hl			;608e
	ld a,(hl)			;608f   ; el estado guarda en su bit 0 hacia que lado gira este bicho
	ld b,a			;6090
	push hl			;6091
	inc hl			;6092
	inc hl			;6093
	inc hl			;6094
	rrca			;6095
	jr nc,COMPORTAMIENTO_1_RUMBO		;6096
	inc (hl)			;6098   ; con el bit puesto sube dos y baja uno, o sea gira un octavo a la derecha
	inc (hl)			;6099
COMPORTAMIENTO_1_RUMBO:
	dec (hl)			;609a   ; y sin el bit, baja uno: gira un octavo a la izquierda
	ld a,(hl)			;609b
	and 007h		;609c   ; ocho rumbos: los tres bits de abajo
	ld c,a			;609e
	ld (hl),a			;609f
	dec hl			;60a0
	push af			;60a1
	ld a,r		;60a2   ; la cuenta nueva sale del registro R: entre 8 y 23 fotogramas
	and 00fh		;60a4   ; los cuatro bits bajos del R: dieciseis valores
	add a,008h		;60a6
	ld (hl),a			;60a8
	pop af			;60a9
	inc de			;60aa
	inc de			;60ab
	rlca			;60ac   ; el patron del sprite es la direccion por cuatro, mas 0x20
	rlca			;60ad
	add a,020h		;60ae
	ld (de),a			;60b0
	dec de			;60b1
	dec de			;60b2
	call ACTOR_ATACA		;60b3
	pop hl			;60b6
	ld (hl),b			;60b7
	inc hl			;60b8
	inc hl			;60b9
COMPORTAMIENTO_1_MUEVE:
	inc hl			;60ba
	ld c,(hl)			;60bb
	dec hl			;60bc
	dec hl			;60bd
	dec hl			;60be
	ld b,001h		;60bf   ; este vuela de uno en uno
	call MUEVE_SPRITE		;60c1
	ret			;60c4
COMPORTAMIENTO_2:		; Apunta al centro de la pantalla cada vez que se le acaba la cuenta
	ld h,b			;60c5   ; este apunta al centro cada vez que se le acaba la cuenta
	ld l,c			;60c6
	push hl			;60c7
	inc hl			;60c8
	dec (hl)			;60c9   ; COMPORTAMIENTO 2: la cuenta no se recarga, asi que da la vuelta sola
	jr nz,COMPORTAMIENTO_2_MUEVE		;60ca
	dec hl			;60cc
	dec hl			;60cd
	ld b,(hl)			;60ce
	call DIRECCION_AL_CENTRO		;60cf   ; al llegar a cero vuelve a apuntar al centro, que es donde esta el avion
	ld c,a			;60d2
	call ACTOR_ATACA		;60d3
	ld (hl),b			;60d6
	inc hl			;60d7
	inc hl			;60d8
COMPORTAMIENTO_2_MUEVE:
	pop hl			;60d9
COMPORTAMIENTO_2_PASO:
	dec hl			;60da
	inc de			;60db
	inc de			;60dc
	ld a,(de)			;60dd   ; la direccion se saca del propio patron del sprite, al reves de antes
	dec de			;60de
	dec de			;60df
	sub 020h		;60e0
	rrca			;60e2   ; dos rotaciones y tres bits: el camino contrario al de 0x60AC
	rrca			;60e3
	and 007h		;60e4
	ld c,a			;60e6
	push hl			;60e7
	call LEE_EPOCA		;60e8
	pop hl			;60eb
	cp 004h		;60ec   ; de la epoca 4 en adelante estos vuelan del doble de deprisa
	ld b,001h		;60ee
	jr c,COMPORTAMIENTO_2_LANZA		;60f0
	ld b,002h		;60f2
COMPORTAMIENTO_2_LANZA:
	call MUEVE_SPRITE		;60f4
	ret			;60f7
COMPORTAMIENTO_3:		; Espera, apunta al centro y dispara
	ld h,b			;60f8
	ld l,c			;60f9
	inc hl			;60fa
	ld a,(hl)			;60fb   ; COMPORTAMIENTO 3: la cuenta es con signo. Negativa quiere decir girando
	or a			;60fc
	jr z,COMPORTAMIENTO_3_APUNTA		;60fd
	inc (hl)			;60ff   ; subiendo hacia cero: ocho fotogramas de giro
	jr z,COMPORTAMIENTO_3_APUNTA		;6100
	bit 7,(hl)		;6102
	jr nz,COMPORTAMIENTO_4_ESPERA		;6104
	dec (hl)			;6106   ; y en positivo baja de uno en uno hasta que toca volver a apuntar
	dec (hl)			;6107
	jr COMPORTAMIENTO_3_SIGUE		;6108
COMPORTAMIENTO_3_APUNTA:
	call DIRECCION_AL_CENTRO		;610a   ; apunta al centro y mira si ya vuela hacia alli
	inc hl			;610d
	cp (hl)			;610e   ; si ya apunta al centro, dispara
	jr nz,COMPORTAMIENTO_4_GIRA		;610f
	push hl			;6111
	inc hl			;6112
	ld bc,001ffh		;6113   ; el disparo sale con la cuenta puesta a 0xFF
	call PON_DISPARO_ENEMIGO		;6116   ; y este dispara al llegar
	pop hl			;6119
	dec hl			;611a
	ld (hl),07eh		;611b   ; ha disparado: 126 fotogramas hasta la proxima vez
	inc hl			;611d
	ld c,(hl)			;611e
	dec hl			;611f
	dec hl			;6120
	dec hl			;6121
	ld b,(hl)			;6122
	call ACTOR_ATACA		;6123
	ld (hl),b			;6126
	ret			;6127
COMPORTAMIENTO_3_SIGUE:
	dec hl			;6128
	jp COMPORTAMIENTO_2_PASO		;6129
COMPORTAMIENTO_4:
	ld h,b			;612c   ; la misma maquina que el 3, pero dispara mucho mas
	ld l,c			;612d
	inc hl			;612e
	ld a,(hl)			;612f   ; COMPORTAMIENTO 4: la misma maquina que el 3, pero dispara mucho mas
	or a			;6130
	jr z,COMPORTAMIENTO_4_APUNTA		;6131
	inc (hl)			;6133
	jr z,COMPORTAMIENTO_4_APUNTA		;6134
	bit 7,(hl)		;6136
	jr nz,COMPORTAMIENTO_4_ESPERA		;6138
	dec (hl)			;613a   ; dos bajadas por vuelta: el giro va al doble
	dec (hl)			;613b
	jr COMPORTAMIENTO_3_SIGUE		;613c
COMPORTAMIENTO_4_ESPERA:
	inc hl			;613e
	ld a,(hl)			;613f
	jr COMPORTAMIENTO_4_MUEVE		;6140
COMPORTAMIENTO_4_APUNTA:
	call DIRECCION_AL_CENTRO		;6142
	inc hl			;6145
	cp (hl)			;6146
	jr z,COMPORTAMIENTO_4_DISPARA		;6147
COMPORTAMIENTO_4_GIRA:
	dec hl			;6149
	ld (hl),0f8h		;614a   ; todavia no mira al centro: gira un octavo y se toma ocho fotogramas
	inc hl			;614c
	ld a,(hl)			;614d
	inc a			;614e
	and 007h		;614f   ; ocho rumbos: los tres bits de abajo
	ld (hl),a			;6151
COMPORTAMIENTO_4_MUEVE:
	dec hl			;6152   ; mientras gira sigue avanzando, de dos en dos
	dec hl			;6153
	dec hl			;6154
	ld c,a			;6155
	ld b,002h		;6156   ; mientras gira sigue avanzando, y de dos en dos
	call MUEVE_SPRITE		;6158
	dec de			;615b
	dec de			;615c
	ld a,c			;615d
	rlca			;615e   ; el patron del sprite es el rumbo por cuatro, mas 0x20
	rlca			;615f
	add a,020h		;6160
	ld (de),a			;6162
	ret			;6163
COMPORTAMIENTO_4_DISPARA:
	push hl			;6164
	inc hl			;6165
	ld bc,001ffh		;6166   ; el disparo sale con la cuenta puesta a 0xFF
	call PON_DISPARO_ENEMIGO		;6169
	pop hl			;616c
	dec hl			;616d
	ld (hl),035h		;616e   ; 53 fotogramas de descanso entre disparo y disparo
	push hl			;6170
	call LEE_EPOCA		;6171
	pop hl			;6174
	cp 004h		;6175   ; y en la epoca 4, solo 32
	jr nz,COMPORTAMIENTO_4_FIN		;6177
	ld (hl),020h		;6179
COMPORTAMIENTO_4_FIN:
	inc hl			;617b   ; el sprite se pone despues de disparar, no antes
	ld c,(hl)			;617c
	dec hl			;617d
	dec hl			;617e
	dec hl			;617f
	ld b,(hl)			;6180
	call ACTOR_ATACA		;6181
	ld (hl),b			;6184
	ret			;6185
COMPORTAMIENTO_5:
	ld h,b			;6186
	ld l,c			;6187
	dec hl			;6188
	push hl			;6189
	ld b,(hl)			;618a
	inc hl			;618b
	inc hl			;618c
	dec (hl)			;618d   ; COMPORTAMIENTO 5: cada cinco fotogramas repasa lo que tenga pendiente
	jr nz,COMPORTAMIENTO_5_MUEVE		;618e
	ld (hl),005h		;6190   ; y la cuenta vuelve a cinco
	dec hl			;6192
	dec hl			;6193
	ld b,(hl)			;6194
	ld c,002h		;6195   ; la direccion 2 es hacia la derecha y la 6 hacia la izquierda
	bit 0,b		;6197
	jr z,COMPORTAMIENTO_5_PASO		;6199
	ld c,006h		;619b
COMPORTAMIENTO_5_PASO:
	call ACTOR_ATACA		;619d
	ld (hl),b			;61a0
COMPORTAMIENTO_5_MUEVE:
	ld c,001h		;61a1   ; este solo se mueve en horizontal, un pixel por fotograma
	bit 0,b		;61a3
	jr nz,COMPORTAMIENTO_5_FIN		;61a5
	ld c,0ffh		;61a7   ; y hacia la izquierda, un pixel al reves
COMPORTAMIENTO_5_FIN:
	inc de			;61a9   ; este solo toca la X: es el que va en horizontal
	ld a,(de)			;61aa
	add a,c			;61ab
	ld (de),a			;61ac
	pop hl			;61ad
	call APAGA_SI_SE_SALE		;61ae
	ret			;61b1
COMPORTAMIENTO_6:
	ld h,b			;61b2   ; este repasa cada cinco fotogramas, como el 5
	ld l,c			;61b3
	dec hl			;61b4
	push hl			;61b5
	ld b,(hl)			;61b6
	inc hl			;61b7
	inc hl			;61b8
	dec (hl)			;61b9   ; COMPORTAMIENTO 6: igual de cinco en cinco, pero este va en onda
	jr nz,COMPORTAMIENTO_6_MUEVE		;61ba
	ld (hl),005h		;61bc   ; y la cuenta vuelve a cinco
	dec hl			;61be
	dec hl			;61bf
	ld b,(hl)			;61c0
	ld c,002h		;61c1   ; la direccion 2 es a la derecha y la 6 a la izquierda
	bit 0,b		;61c3
	jr z,COMPORTAMIENTO_6_PASO		;61c5
	ld c,006h		;61c7
COMPORTAMIENTO_6_PASO:
	call ACTOR_ATACA		;61c9
	ld (hl),b			;61cc
	inc hl			;61cd
	inc hl			;61ce
COMPORTAMIENTO_6_MUEVE:
	inc hl			;61cf
	ld a,(hl)			;61d0   ; el byte 3 es el paso de la onda, de 0 a 63
	inc a			;61d1
	and 03fh		;61d2   ; los seis bits bajos: 64 pasos de onda
	ld (hl),a			;61d4
	ld hl,06322h		;61d5   ; y la onda esta tabulada: 64 parejas de (cuanto baja, cuanto avanza)
	rlca			;61d8   ; dos bytes por paso
	call SUMA_A_HL		;61d9
	ex de,hl			;61dc
	ld a,(de)			;61dd
	add a,(hl)			;61de
	ld (hl),a			;61df
	inc hl			;61e0
	inc de			;61e1
	ld a,(de)			;61e2
	bit 0,b		;61e3   ; el bit 0 del estado dice si la onda avanza a la derecha o a la izquierda
	jr nz,COMPORTAMIENTO_6_FIN		;61e5
	neg		;61e7   ; el `neg` da la vuelta al paso
COMPORTAMIENTO_6_FIN:
	add a,(hl)			;61e9   ; y este suma la Y de la onda
	ld (hl),a			;61ea
	ex de,hl			;61eb
	pop hl			;61ec
	call APAGA_SI_SE_SALE		;61ed
	ret			;61f0
COMPORTAMIENTO_7:
	ld h,b			;61f1
	ld l,c			;61f2
	dec hl			;61f3
	push hl			;61f4
	ld b,(hl)			;61f5
	inc hl			;61f6
	inc hl			;61f7
	ld c,(hl)			;61f8   ; el byte 2 guarda por donde entro: eso decide la forma del recorrido
	inc hl			;61f9
	dec (hl)			;61fa   ; COMPORTAMIENTO 7: el byte 4 es la cuenta, y se recarga con 32
	jp nz,COMPORTAMIENTO_7_RUMBO		;61fb
	ld (hl),020h		;61fe   ; treinta y dos fotogramas por tramo
	inc hl			;6200
	inc (hl)			;6201   ; y el byte 4 va contando los tramos
	ld a,(hl)			;6202
	dec hl			;6203
	cp 002h		;6204   ; en el tramo 2 el helicoptero se pone de perfil
	jr nz,COMPORTAMIENTO_7_PASO		;6206
	ld (hl),0ffh		;6208
	ex de,hl			;620a
	inc hl			;620b
	inc hl			;620c
	ld a,028h		;620d   ; 0x28 y 0x24 son los dos dibujos del helicoptero, mirando a cada lado
	bit 2,c		;620f   ; y mirando a un lado o a otro segun el bit 2
	jr z,COMPORTAMIENTO_7_GIRA		;6211
	ld a,024h		;6213
	jr COMPORTAMIENTO_7_GIRA		;6215
COMPORTAMIENTO_7_PASO:
	bit 1,c		;6217   ; fuera del tramo 2 manda el bit 1
	jr nz,COMPORTAMIENTO_7_CUENTA		;6219
	ld (hl),0ffh		;621b
	ex de,hl			;621d
	inc hl			;621e
	inc hl			;621f
	ld a,028h		;6220   ; los dos dibujos de perfil, otra vez
	bit 0,c		;6222
	jr z,COMPORTAMIENTO_7_GIRA		;6224
	ld a,024h		;6226
COMPORTAMIENTO_7_GIRA:
	ld (hl),a			;6228
	dec hl			;6229
	dec hl			;622a
	ex de,hl			;622b
	pop hl			;622c
	res 0,c		;622d   ; la bandera de disparar se apaga aqui, no en ACTOR_ATACA
	call ACTOR_ATACA		;622f
	ld (hl),b			;6232
	ret			;6233
COMPORTAMIENTO_7_CUENTA:
	ex de,hl			;6234   ; con el bit 1 puesto se queda de frente, con el dibujo 0x20
	inc hl			;6235
	inc hl			;6236
	ld a,020h		;6237
	jr COMPORTAMIENTO_7_GIRA		;6239
COMPORTAMIENTO_7_RUMBO:
	inc hl			;623b   ; el tramo que toca decide si se mueve en Y o en X y hacia donde
	ld a,(hl)			;623c
	ld b,a			;623d
	ex de,hl			;623e
	or a			;623f
	jr nz,COMPORTAMIENTO_7_MIRA		;6240
	ld a,c			;6242
	cp 002h		;6243
	jr nc,COMPORTAMIENTO_7_MENOS		;6245
COMPORTAMIENTO_7_SIGUE:
	ld a,0ffh		;6247   ; el 0xFF es -1: hacia atras
	jr COMPORTAMIENTO_7_PASO2		;6249
COMPORTAMIENTO_7_MIRA:
	dec a			;624b   ; en el tramo 1 hay cuatro entradas que siguen derechas
	jr nz,COMPORTAMIENTO_7_AJUSTA		;624c
	ld a,c			;624e   ; con el tramo 1, cuatro de las ocho entradas siguen derechas
	cp 003h		;624f
	jr z,COMPORTAMIENTO_7_SIGUE		;6251
	cp 007h		;6253
	jr z,COMPORTAMIENTO_7_SIGUE		;6255
	cp 006h		;6257
	jr z,COMPORTAMIENTO_7_MAS		;6259
	cp 002h		;625b
	jr nz,COMPORTAMIENTO_7_MENOS		;625d
COMPORTAMIENTO_7_MAS:
	ld a,001h		;625f   ; y el 1 es hacia adelante
	jr COMPORTAMIENTO_7_PASO2		;6261
COMPORTAMIENTO_7_MENOS:
	inc hl			;6263   ; las entradas 4 y 5 se van al tope
	cp 004h		;6264
	jr z,COMPORTAMIENTO_7_FIN		;6266
	cp 005h		;6268
	jr z,COMPORTAMIENTO_7_FIN		;626a
	dec hl			;626c
COMPORTAMIENTO_7_AJUSTA:
	inc hl			;626d   ; y las demas ajustan la X
	ld a,b			;626e
	or a			;626f
	jr nz,COMPORTAMIENTO_7_PON		;6270
	ld a,c			;6272
	cp 006h		;6273
	jr c,COMPORTAMIENTO_7_FIN		;6275
COMPORTAMIENTO_7_TOPE:
	ld a,0ffh		;6277
	jr COMPORTAMIENTO_7_MUEVE		;6279
COMPORTAMIENTO_7_PON:
	dec a			;627b   ; en el tramo 1 hay dos entradas que se paran en el tope
	jr nz,COMPORTAMIENTO_7_SONIDO		;627c
	ld a,c			;627e
	or a			;627f
	jr z,COMPORTAMIENTO_7_TOPE		;6280
	cp 004h		;6282
	jr z,COMPORTAMIENTO_7_TOPE		;6284
	jr COMPORTAMIENTO_7_FIN		;6286
COMPORTAMIENTO_7_SONIDO:
	ld a,c			;6288
	cp 006h		;6289
	jr c,COMPORTAMIENTO_7_TOPE		;628b
COMPORTAMIENTO_7_FIN:
	ld a,001h		;628d   ; un pixel por fotograma
COMPORTAMIENTO_7_MUEVE:
	add a,(hl)			;628f   ; los tramos pares corren la X
	ld (hl),a			;6290
	jr COMPORTAMIENTO_7_SALIDA		;6291
COMPORTAMIENTO_7_PASO2:
	add a,(hl)			;6293   ; y los impares la Y
	ld (hl),a			;6294
	inc hl			;6295
COMPORTAMIENTO_7_SALIDA:
	ex de,hl			;6296
	pop hl			;6297
	call APAGA_SI_SE_SALE		;6298
	ret			;629b
COMPORTAMIENTO_8:
	ld h,b			;629c
	ld l,c			;629d
	push hl			;629e
	inc hl			;629f   ; COMPORTAMIENTO 8: el que vuela con una trayectoria tabulada
	dec (hl)			;62a0
	jr nz,COMPORTAMIENTO_8_MUEVE		;62a1
	inc hl			;62a3
	ld a,(hl)			;62a4   ; el byte 3 es el paso, de 0 a 15, y sube uno cada vez
	inc (hl)			;62a5
	and 00fh		;62a6   ; los cuatro bits bajos: dieciseis pasos
	rlca			;62a8   ; dos bytes por entrada
	push hl			;62a9
	ld hl,062e2h		;62aa   ; una de las dos tablas de giro, a cara o cruz con el registro R
	push af			;62ad
	ld a,r		;62ae
	rrca			;62b0
	jr c,COMPORTAMIENTO_8_PASO		;62b1
	ld hl,06302h		;62b3
COMPORTAMIENTO_8_PASO:
	pop af			;62b6
	call SUMA_A_HL		;62b7   ; cada entrada son dos bytes: cuanto dura el tramo y hacia donde gira
	ld b,(hl)			;62ba
	inc hl			;62bb
	ld c,(hl)			;62bc
	pop hl			;62bd
	dec hl			;62be
	ld (hl),b			;62bf   ; el primero recarga la cuenta
	inc hl			;62c0
	inc hl			;62c1
	ld a,(hl)			;62c2   ; y el segundo se le suma a la direccion: +1 o -1, o sea un octavo
	add a,c			;62c3
	and 007h		;62c4   ; ocho rumbos: los tres bits de abajo
	ld (hl),a			;62c6
	inc de			;62c7
	inc de			;62c8
	rlca			;62c9   ; el patron es el rumbo por cuatro, mas 0x20
	rlca			;62ca
	add a,020h		;62cb
	ld (de),a			;62cd
	dec de			;62ce
	dec de			;62cf
	jr COMPORTAMIENTO_8_FIN		;62d0
COMPORTAMIENTO_8_MUEVE:
	inc hl			;62d2
	inc hl			;62d3
COMPORTAMIENTO_8_FIN:
	ld c,(hl)			;62d4   ; la direccion esta en el byte 4, no en el 3 como en los demas
	pop hl			;62d5
	dec hl			;62d6
	ld b,(hl)			;62d7
	call ACTOR_ATACA		;62d8
	ld (hl),b			;62db
	ld b,001h		;62dc   ; este vuela de uno en uno
	call MUEVE_SPRITE		;62de
	ret			;62e1

; ----------------------------------------------------------------------
; DATOS giro_corto_del_comportamiento_8: Las dieciseis paradas de la
;   trayectoria corta del comportamiento 8 (0x62AA). Cada pareja es (cuantos
;   fotogramas dura el tramo, hacia donde gira al acabarlo: 0x01 un octavo a
;   la derecha, 0xFF un octavo a la izquierda). Los giros suman +8, o sea una
;   vuelta entera, y las duraciones 216 fotogramas
;   0x62e2..0x6302  (32 bytes)
DATA_giro_corto_del_comportamiento_8:
	defb 010h,001h	; 62e2
	defb 010h,001h	; 62e4
	defb 008h,0ffh	; 62e6
	defb 008h,0ffh	; 62e8
	defb 010h,0ffh	; 62ea
	defb 008h,0ffh	; 62ec
	defb 010h,001h	; 62ee
	defb 010h,001h	; 62f0
	defb 010h,001h	; 62f2
	defb 010h,001h	; 62f4
	defb 008h,001h	; 62f6
	defb 010h,001h	; 62f8
	defb 008h,001h	; 62fa
	defb 010h,001h	; 62fc
	defb 008h,001h	; 62fe
	defb 018h,001h	; 6300

; ----------------------------------------------------------------------
; DATOS giro_largo_del_comportamiento_8: La otra trayectoria del
;   comportamiento 8 (0x62B3), con el mismo formato. Esta es mas abierta:
;   tramos de hasta 64 fotogramas, 424 en total, y los giros suman -6, asi que
;   no llega a cerrar la vuelta. El registro R decide a cara o cruz cual de
;   las dos le toca a cada actor
;   0x6302..0x6322  (32 bytes)
DATA_giro_largo_del_comportamiento_8:
	defb 020h,001h	; 6302
	defb 020h,001h	; 6304
	defb 020h,0ffh	; 6306
	defb 010h,0ffh	; 6308
	defb 020h,001h	; 630a
	defb 020h,0ffh	; 630c
	defb 008h,0ffh	; 630e
	defb 040h,0ffh	; 6310
	defb 010h,0ffh	; 6312
	defb 010h,0ffh	; 6314
	defb 020h,001h	; 6316
	defb 010h,0ffh	; 6318
	defb 020h,0ffh	; 631a
	defb 020h,0ffh	; 631c
	defb 010h,001h	; 631e
	defb 010h,0ffh	; 6320

; ----------------------------------------------------------------------
; DATOS onda_del_comportamiento_6: Los sesenta y cuatro pasos de la onda del
;   comportamiento 6 (0x61D5). Cada pareja es (cuanto se le suma a la Y,
;   cuanto a la X). Los 32 primeros pasos bajan 51 pixeles y los 32 siguientes
;   son su espejo exacto, asi que suben los mismos 51: la suma de las Y es
;   cero y el bicho vuelve a la altura de salida. Las X suman 106 pixeles por
;   vuelta, y el bit 0 del estado decide si se avanza a la derecha o a la
;   izquierda
;   0x6322..0x63a2  (128 bytes)
DATA_onda_del_comportamiento_6:
	defb 001h,002h	; 6322
	defb 001h,002h	; 6324
	defb 002h,002h	; 6326
	defb 002h,002h	; 6328
	defb 002h,003h	; 632a
	defb 002h,001h	; 632c
	defb 003h,002h	; 632e
	defb 002h,002h	; 6330
	defb 002h,001h	; 6332
	defb 001h,001h	; 6334
	defb 002h,001h	; 6336
	defb 002h,001h	; 6338
	defb 002h,001h	; 633a
	defb 002h,001h	; 633c
	defb 003h,002h	; 633e
	defb 002h,002h	; 6340
	defb 001h,001h	; 6342
	defb 002h,001h	; 6344
	defb 001h,001h	; 6346
	defb 002h,003h	; 6348
	defb 002h,002h	; 634a
	defb 002h,002h	; 634c
	defb 002h,001h	; 634e
	defb 002h,002h	; 6350
	defb 001h,002h	; 6352
	defb 001h,002h	; 6354
	defb 001h,001h	; 6356
	defb 001h,002h	; 6358
	defb 001h,002h	; 635a
	defb 001h,002h	; 635c
	defb 000h,001h	; 635e
	defb 000h,002h	; 6360
	defb 0ffh,002h	; 6362
	defb 0ffh,002h	; 6364
	defb 0feh,002h	; 6366
	defb 0feh,002h	; 6368
	defb 0feh,003h	; 636a
	defb 0feh,001h	; 636c
	defb 0fdh,002h	; 636e
	defb 0feh,002h	; 6370
	defb 0feh,001h	; 6372
	defb 0ffh,001h	; 6374
	defb 0feh,001h	; 6376
	defb 0feh,001h	; 6378
	defb 0feh,001h	; 637a
	defb 0feh,001h	; 637c
	defb 0fdh,002h	; 637e
	defb 0feh,002h	; 6380
	defb 0ffh,001h	; 6382
	defb 0feh,001h	; 6384
	defb 0ffh,001h	; 6386
	defb 0feh,003h	; 6388
	defb 0feh,002h	; 638a
	defb 0feh,002h	; 638c
	defb 0feh,001h	; 638e
	defb 0feh,002h	; 6390
	defb 0ffh,002h	; 6392
	defb 0ffh,002h	; 6394
	defb 0ffh,001h	; 6396
	defb 0ffh,002h	; 6398
	defb 0ffh,002h	; 639a
	defb 0ffh,002h	; 639c
	defb 000h,001h	; 639e
	defb 000h,002h	; 63a0

; ======================================================================
; CODIGO 0x63a2..0x6697  (757 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LO QUE EL ACTOR HACE ADEMAS DE VOLAR. Todos los comportamientos llaman aqui justo al cambiar de rumbo. El estado del actor lleva dos banderas: con el bit 1 le dispara al avion del jugador, y con el bit 3 suelta un misil que sale volando hacia el centro. Las dos se apagan en cuanto se usan, asi que cada bandera vale para una sola vez.
; ----------------------------------------------------------------------
ACTOR_ATACA:		; Lo que el actor hace ademas de volar. Los bits 1 y 3 de su estado: el 1 le dispara al avion, el 3 suelta un misil. Se apagan al usarlos
	ld a,b			;63a2
	and 00eh		;63a3   ; sin ninguna de las dos banderas puestas, no hay nada que hacer
	ret z			;63a5
	bit 1,a		;63a6
	jp nz,ACTOR_DISPARA		;63a8
	bit 3,a		;63ab
	ret z			;63ad
	res 3,b		;63ae   ; la bandera se apaga: cada misil pide que se la vuelvan a poner
	push hl			;63b0
	push de			;63b1
	push bc			;63b2
	ld hl,0e2a0h		;63b3   ; hasta cuatro misiles a la vez, de nueve bytes cada uno
	ld de,0e3ach		;63b6
	ld b,004h		;63b9
MISIL_BUSCA_FICHA:
	ld a,(hl)			;63bb   ; hasta cuatro misiles; si estan los cuatro fuera, no sale ninguno
	or a			;63bc
	jr z,MISIL_PON		;63bd
	call SIGUIENTE_SPRITE		;63bf
	call SUMA_9_A_HL		;63c2   ; nueve bytes por ficha de misil
	djnz MISIL_BUSCA_FICHA		;63c5   ; cuatro fichas
	pop bc			;63c7
	pop de			;63c8
	pop hl			;63c9
	ret			;63ca
MISIL_PON:		; Monta la ficha del misil en 0xE2A0 y su sprite
	ld (hl),083h		;63cb   ; estado 0x83: el misil nace volando
	inc hl			;63cd
	ld (hl),000h		;63ce
	inc hl			;63d0
	ld (hl),c			;63d1
	pop bc			;63d2
	pop hl			;63d3
	push hl			;63d4
	ld a,(hl)			;63d5   ; el misil sale exactamente de donde esta el actor
	ld (de),a			;63d6
	inc de			;63d7
	inc hl			;63d8
	ld a,(hl)			;63d9
	ld (de),a			;63da
	inc de			;63db
	ld a,c			;63dc
	rlca			;63dd
	rlca			;63de
	add a,040h		;63df   ; el patron del misil es su direccion por cuatro, mas 0x40
	ld (de),a			;63e1
	inc de			;63e2
	push hl			;63e3
	call LEE_EPOCA		;63e4
	pop hl			;63e7
	cp 005h		;63e8   ; en la epoca 5 el misil se pinta de otro color
	ld a,001h		;63ea
	jr nz,MISIL_COLOR		;63ec
	ld a,00ah		;63ee   ; el color 10 en vez del 1
MISIL_COLOR:
	ld (de),a			;63f0
	ld a,(0e031h)		;63f1   ; el sonido solo suena si el canal 3 esta libre o con algo menos urgente
	or a			;63f4
	ld hl,0e037h		;63f5
	jr z,MISIL_SONIDO		;63f8
	ld a,(hl)			;63fa
	cp 00ch		;63fb
	jr c,ACTOR_ATACA_SALIDA		;63fd
MISIL_SONIDO:
	ld (hl),00ch		;63ff   ; la prioridad se sube a 12
	ld hl,07ebdh		;6401
	ld (0e030h),hl		;6404
ACTOR_ATACA_SALIDA:
	pop de			;6407
	pop hl			;6408
	ret			;6409
ACTOR_DISPARA:		; Solo dispara si esta FUERA del recuadro del centro; dentro no, para no ametrallar al jugador a bocajarro
	push hl			;640a
	call LEE_EPOCA		;640b
	pop hl			;640e
	cp 005h		;640f   ; en la epoca 5 estos no disparan
	ret z			;6411
	push bc			;6412
	push hl			;6413
	ld hl,0e182h		;6414   ; a partir de la ronda 5 el recuadro donde no se dispara se hace mas grande
	call LEE_POR_JUGADOR		;6417
	pop hl			;641a
	ld bc,010b0h		;641b
	cp 005h		;641e
	jr c,ACTOR_DISPARA_CAJA		;6420
	ld bc,020a0h		;6422
ACTOR_DISPARA_CAJA:
	ld a,(0e20fh)		;6425   ; y con el bicho grande en pantalla, mas grande todavia
	or a			;6428
	jr z,ACTOR_DISPARA_MIRA		;6429
	ld a,b			;642b
	add a,030h		;642c
	ld b,a			;642e
	ld a,c			;642f
	sub 030h		;6430
	ld c,a			;6432
ACTOR_DISPARA_MIRA:
	ld a,(de)			;6433   ; con el avion enemigo dentro del recuadro no se dispara
	cp b			;6434
	jr c,ACTOR_DISPARA_VALE		;6435
	cp c			;6437
	jr nc,ACTOR_DISPARA_VALE		;6438
	inc de			;643a   ; y tampoco si esta dentro por la otra coordenada
	ld a,(de)			;643b
	dec de			;643c
	cp b			;643d
	jr c,ACTOR_DISPARA_VALE		;643e
	cp c			;6440
	jr nc,ACTOR_DISPARA_VALE		;6441
	pop bc			;6443
	ret			;6444
ACTOR_DISPARA_VALE:
	pop bc			;6445
	res 1,b		;6446   ; la bandera se apaga: cada disparo pide que se la vuelvan a poner
	push hl			;6448
	push de			;6449
	push bc			;644a
	ld hl,0e270h		;644b   ; hasta seis disparos enemigos a la vez, de siete bytes cada uno
	ld de,0e3bch		;644e
	ld b,006h		;6451
ACTOR_DISPARA_SIGUIENTE:
	ld a,(hl)			;6453   ; y hasta seis disparos
	or a			;6454
	jr z,ACTOR_DISPARA_PON		;6455
	call SIGUIENTE_SPRITE		;6457
	call SUMA_7_A_HL		;645a   ; siete bytes por ficha de disparo
	djnz ACTOR_DISPARA_SIGUIENTE		;645d   ; seis fichas
	pop bc			;645f
	pop de			;6460
	pop hl			;6461
	ret			;6462
ACTOR_DISPARA_PON:
	ld (hl),080h		;6463   ; el disparo enemigo sale de la ficha del avion que lo tira
	pop bc			;6465
	exx			;6466
	pop de			;6467
	push de			;6468
	call DIRECCION_AL_CENTRO		;6469   ; el disparo sale apuntando al centro, que es donde vuela el avion
	exx			;646c
	inc hl			;646d
	push hl			;646e
	exx			;646f
	pop hl			;6470
	ld bc,001ffh		;6471   ; el disparo sale con la cuenta puesta a 0xFF
	call PON_DISPARO_ENEMIGO		;6474   ; el disparo enemigo sale apuntando al centro, y se mueve solo
	exx			;6477
	pop hl			;6478
	push hl			;6479
	ld a,(hl)			;647a
	ld (de),a			;647b
	inc hl			;647c
	inc de			;647d
	ld a,(hl)			;647e
	ld (de),a			;647f
	inc de			;6480
	ld a,060h		;6481   ; el patron 0x60 es el del disparo enemigo
	ld (de),a			;6483
	ld hl,07ee0h		;6484   ; y con su sonido propio
	ld (0e020h),hl		;6487
	ld a,005h		;648a   ; prioridad 5 en el canal 1
	ld (0e027h),a		;648c
	pop de			;648f
	pop hl			;6490
	ret			;6491
SUELTA_LAS_BOMBAS:		; Solo en la epoca 1: el avion que lleva la bandera de bomba la suelta al pasar por una de las dos bandas de arriba
	call LEE_EPOCA		;6492   ; SOLO EN LA EPOCA 1: el avion que lleva bomba la suelta al pasar por arriba
	dec a			;6495
	ret nz			;6496
	ld hl,0e2d0h		;6497
	ld de,0e38ch		;649a
	ld b,006h		;649d   ; seis fichas de avion
BOMBA_MIRA_ACTOR:
	ld a,(hl)			;649f   ; la bandera de llevar bomba es el bit 2 del estado
	and 0e4h		;64a0
	cp 084h		;64a2
	jr z,BOMBA_MIRA_ALTURA		;64a4
BOMBA_SIGUIENTE_ACTOR:
	call SIGUIENTE_SPRITE		;64a6
	call SUMA_10_A_HL		;64a9   ; diez bytes por ficha
	djnz BOMBA_MIRA_ACTOR		;64ac   ; seis fichas
	ret			;64ae
BOMBA_MIRA_ALTURA:
	ld a,(de)			;64af   ; tiene que estar en la franja de arriba, entre las alturas 0x10 y 0x30
	cp 010h		;64b0
	jr c,BOMBA_SIGUIENTE_ACTOR		;64b2
	cp 030h		;64b4
	jr c,BOMBA_MIRA_BANDA		;64b6
	ld c,a			;64b8
	ld a,(0e20fh)		;64b9   ; con el bicho grande fuera vale hasta la mitad de la pantalla
	or a			;64bc
	jr z,BOMBA_SIGUIENTE_ACTOR		;64bd
	ld a,c			;64bf
	cp 060h		;64c0
	jr nc,BOMBA_SIGUIENTE_ACTOR		;64c2
BOMBA_MIRA_BANDA:
	inc de			;64c4   ; la banda izquierda va de 0x10 a 0x30 y la derecha de 0x90 a 0xB0
	ld a,(de)			;64c5
	dec de			;64c6
	ld c,080h		;64c7
	cp 010h		;64c9
	jr c,BOMBA_SIGUIENTE_ACTOR		;64cb
	cp 030h		;64cd
	jr c,BOMBA_BUSCA_FICHA		;64cf
	ld c,081h		;64d1   ; la bomba mira a un lado o al otro segun por que banda caiga
	cp 090h		;64d3
	jr c,BOMBA_SIGUIENTE_ACTOR		;64d5
	cp 0b0h		;64d7
	jr nc,BOMBA_SIGUIENTE_ACTOR		;64d9
BOMBA_BUSCA_FICHA:
	res 2,(hl)		;64db   ; la bandera se apaga: una bomba por avion
	push de			;64dd
	ld hl,0e260h		;64de
	ld de,0e3ach		;64e1
	ld b,004h		;64e4   ; cuatro bombas
BOMBA_FICHA_SIGUIENTE:
	ld a,(hl)			;64e6   ; hasta cuatro bombas a la vez
	and 0e0h		;64e7
	jr z,BOMBA_PON		;64e9
	inc hl			;64eb
	inc hl			;64ec
	inc hl			;64ed
	call SIGUIENTE_SPRITE		;64ee
	djnz BOMBA_FICHA_SIGUIENTE		;64f1   ; cuatro fichas
	pop de			;64f3
	ret			;64f4
BOMBA_PON:
	ld (hl),c			;64f5
	inc hl			;64f6
	ld (hl),000h		;64f7   ; subestado 0: la bomba empieza a caer
	pop hl			;64f9
	ex de,hl			;64fa
	ld a,(de)			;64fb
	ld (hl),a			;64fc
	inc hl			;64fd
	inc de			;64fe
	ld a,(de)			;64ff
	ld (hl),a			;6500
	inc hl			;6501
	ld (hl),064h		;6502   ; patron 0x64 si cae por la izquierda
	bit 0,c		;6504
	jr z,BOMBA_COLOR		;6506
	ld (hl),068h		;6508   ; y 0x68 si cae por la derecha, que es el mismo dibujo del reves
BOMBA_COLOR:
	inc hl			;650a
	ld (hl),008h		;650b   ; color 8, rojo
	ret			;650d
PASO_DE_LA_FASE:		; Lleva la cuenta de los enemigos que faltan y, cuando no queda ninguno, saca el bicho grande
	ld a,(0e018h)		;650e   ; con una espera en marcha no se saca nada
	or a			;6511
	ret nz			;6512
	ld a,(0e052h)		;6513   ; con la partida acabada tampoco
	or a			;6516
	ret nz			;6517
	ld hl,0e120h		;6518
	call LEE_JUGADOR		;651b
	jr z,FASE_CUENTA		;651e
	inc hl			;6520
	inc hl			;6521
FASE_CUENTA:
	ld a,(hl)			;6522   ; mientras queden enemigos por derribar, a sacar otro
	or a			;6523
	jr nz,FASE_BICHO_LISTO		;6524
	ld de,0e200h		;6526   ; y si el bicho grande ya esta fuera, tampoco
	ld a,(de)			;6529
	or a			;652a
	jr nz,FASE_BICHO_LISTO		;652b
	ld hl,0e212h		;652d   ; el bicho sale colgado de una nube: se coge la casilla de la primera
	ld a,(hl)			;6530
	inc hl			;6531
	ld l,(hl)			;6532
	ld h,a			;6533
	ld a,080h		;6534   ; y se baja cuatro filas, 128 casillas de la tabla de nombres
	call SUMA_A_HL		;6536
	ld a,h			;6539   ; si eso se sale del tercio, se vuelve al principio
	cp 07bh		;653a
	jr nz,FASE_SUELTA_BICHO		;653c
	ld h,078h		;653e
FASE_SUELTA_BICHO:
	ld a,l			;6540   ; el bicho sale por la columna 29, o sea pegado al borde derecho
	and 0e0h		;6541   ; los tres bits altos son la fila
	or 01dh		;6543
	ld l,a			;6545
	ex de,hl			;6546
	ld (hl),080h		;6547   ; estado 0x80: el bicho grande, volando
	inc hl			;6549
	ld (hl),d			;654a
	inc hl			;654b
	ld (hl),e			;654c
	inc hl			;654d
	ld a,(0e210h)		;654e   ; y el dibujo del bicho es el mismo que el de la nube de la que cuelga
	ld (hl),a			;6551
	ret			;6552
FASE_BICHO_LISTO:
	inc hl			;6553
	ld a,(hl)			;6554   ; siete actores es el tope: mas no caben
	cp 007h		;6555
	ret nc			;6557
	ld b,a			;6558
	ld a,(0e131h)		;6559   ; el bit 0 de 0xE131 lo pone la interrupcion cada 32 fotogramas
	rrca			;655c
	jr nc,FASE_MIRA_EPOCA		;655d
	ld a,b			;655f   ; y cuando toca trio nuevo, el tope baja a cuatro
	cp 004h		;6560
	ret nc			;6562
	dec hl			;6563
	ld a,(hl)			;6564   ; con menos de tres por derribar suena el aviso
	cp 003h		;6565
	jr c,FASE_SIGUE		;6567
	ld a,(0e031h)		;6569
	or a			;656c
	ld hl,0e037h		;656d
	jr z,FASE_SONIDO		;6570
	ld a,(hl)			;6572
	cp 00bh		;6573
	jr c,FASE_SIGUE		;6575
FASE_SONIDO:
	ld (hl),00bh		;6577   ; la prioridad se sube a 11
	ld hl,07e98h		;6579
	ld (0e030h),hl		;657c
FASE_SIGUE:
	ld de,0e130h		;657f   ; cuenta puesta a 32 y bandera de trio en marcha
	ld a,020h		;6582
	ld (de),a			;6584
	inc de			;6585
	ld a,002h		;6586   ; la bandera del trio a 2
	ld (de),a			;6588
	inc de			;6589
	xor a			;658a
	ld (de),a			;658b
	ld a,(0e146h)		;658c   ; la direccion del avion, sin el bit 0: ocho posibilidades
	res 0,a		;658f   ; el bit 0 fuera: los rumbos van de dos en dos
	push hl			;6591
	ld hl,0688ah		;6592   ; de ahi sale la casilla por la que va a salir el trio
	call SUMA_A_HL		;6595
	ld a,r		;6598   ; y el registro R elige una de las dos de cada grupo
	rrca			;659a
	jr c,FASE_VELOCIDAD		;659b
	inc hl			;659d   ; la segunda pareja de la tabla
	inc hl			;659e
FASE_VELOCIDAD:
	inc de			;659f   ; la casilla de salida se guarda en 0xE133 y 0xE134
	ld a,(hl)			;65a0
	ld (de),a			;65a1
	inc hl			;65a2
	inc de			;65a3
	ld a,(hl)			;65a4
	ld (de),a			;65a5
	pop hl			;65a6
FASE_MIRA_EPOCA:
	ld de,0e131h		;65a7
	push hl			;65aa
	call LEE_EPOCA		;65ab
	pop hl			;65ae
	cp 005h		;65af   ; en la epoca 5 no hay pasajero
	jr z,FASE_EPOCA_5		;65b1
	ld a,(0e20fh)		;65b3
	or a			;65b6
	jr nz,FASE_EPOCA_5		;65b7
	push hl			;65b9
	ld hl,0e126h		;65ba
	call LEE_POR_JUGADOR		;65bd
	pop hl			;65c0
	and 00fh		;65c1   ; uno de cada dieciseis enemigos trae el paracaidista detras
	cp 00fh		;65c3
	jr nz,FASE_EPOCA_5		;65c5
	ld a,(0e2ceh)		;65c7
	or a			;65ca
	jr nz,FASE_EPOCA_5		;65cb
	ld a,080h		;65cd   ; el pasajero, en su ficha de 0xE2CE
	ld (0e2ceh),a		;65cf
	ld a,06ch		;65d2   ; patron 0x6C: el paracaidas
	ld (0e2cfh),a		;65d4
	ld a,000h		;65d7   ; baja por el centro y desde arriba del todo
	ld (0e3a8h),a		;65d9
	ld a,060h		;65dc
	ld (0e3a9h),a		;65de
FASE_EPOCA_5:
	ex de,hl			;65e1
	bit 1,(hl)		;65e2   ; el bit 1 dice que hay un trio a medio salir
	jr z,FASE_MIRA_HUECO		;65e4
	inc hl			;65e6
	inc (hl)			;65e7   ; el trio son tres: uno, dos y tres
	ld a,(hl)			;65e8
	ld c,000h		;65e9
	cp 003h		;65eb
	jr nz,FASE_ESPERA_2		;65ed
	ld c,004h		;65ef   ; el tercero cierra el trio y deja cuatro puntos de espera, dos segundos y medio
	dec hl			;65f1
	ld (hl),000h		;65f2   ; y la bandera del trio se apaga
	inc hl			;65f4
FASE_ESPERA_2:
	inc hl			;65f5
	ld d,(hl)			;65f6
	inc hl			;65f7
	ld e,(hl)			;65f8
	dec a			;65f9
	jr z,FASE_PASO_2		;65fa
	ld b,0f0h		;65fc   ; el segundo sale dieciseis pixeles antes
	dec a			;65fe
	jr z,FASE_PON_CUENTA		;65ff
	ld b,010h		;6601   ; y el tercero, dieciseis despues
FASE_PON_CUENTA:
	ld a,d			;6603   ; si la coordenada esta pegada a un borde, se corre la otra
	or a			;6604
	jr z,FASE_CUENTA_2		;6605
	cp 0afh		;6607
	jr z,FASE_CUENTA_2		;6609
	add a,b			;660b
	ld d,a			;660c
	jr FASE_PASO_2		;660d
FASE_CUENTA_2:
	ld a,e			;660f
	add a,b			;6610
	ld e,a			;6611
FASE_PASO_2:
	ld a,c			;6612
	ld (0e018h),a		;6613   ; la espera se apunta en 0xE018
	jr FASE_ELIGE_FORMACION		;6616
FASE_MIRA_HUECO:
	ld hl,0e182h		;6618   ; sin trio en marcha, el enemigo sale suelto
	call LEE_POR_JUGADOR		;661b
	cp 006h		;661e   ; a partir de la ronda 6 se espera un punto menos entre enemigo y enemigo
	ld a,003h		;6620
	jr c,FASE_HUECO_LIBRE		;6622
	ld a,002h		;6624
FASE_HUECO_LIBRE:
	ld (0e018h),a		;6626
	ld hl,0689ch		;6629   ; la casilla de salida sale de la direccion en la que vuela el avion
	ld a,(0e146h)		;662c
	srl a		;662f   ; el `srl` quita el bit 0 y las tres rotaciones multiplican por cuatro
	rlca			;6631
	rlca			;6632
	rlca			;6633
	call SUMA_A_HL		;6634
	ld a,r		;6637   ; y a cara o cruz entre las dos de cada grupo
	and 001h		;6639
	jr z,FASE_COLOCA		;663b
	call SUMA_4_A_HL		;663d   ; cuatro bytes: la segunda pareja de la tabla
FASE_COLOCA:
	ld b,002h		;6640
FASE_COLOCA_2:
	ld d,e			;6642   ; dos vueltas, una por coordenada
	ld a,(hl)			;6643
	inc hl			;6644
	cp (hl)			;6645   ; si los dos bytes son iguales, la coordenada es fija: un borde
	jr z,FASE_FORMACION_2		;6646
	ld a,(0e019h)		;6648   ; y si no, el contador de fotogramas hace de numero al azar
	dec hl			;664b
	cp (hl)			;664c
	inc hl			;664d
	jr c,FASE_FORMACION		;664e
	cp (hl)			;6650
	jr c,FASE_FORMACION_2		;6651
	add a,040h		;6653
FASE_FORMACION:
	add a,060h		;6655
FASE_FORMACION_2:
	inc hl			;6657
	ld e,a			;6658
	djnz FASE_COLOCA_2		;6659   ; dos coordenadas
FASE_ELIGE_FORMACION:
	call LEE_EPOCA		;665b   ; cada epoca tiene su lista de que bichos salen
	ld hl,068dch		;665e   ; la lista de la epoca 1
	dec a			;6661
	jr z,FASE_FORMACION_PON		;6662
	ld hl,068e5h		;6664
	dec a			;6667
	jr z,FASE_FORMACION_PON		;6668
	ld hl,068eeh		;666a
	dec a			;666d
	jr z,FASE_FORMACION_PON		;666e
	ld hl,068f7h		;6670
	dec a			;6673
	jr z,FASE_FORMACION_PON		;6674
	ld hl,06900h		;6676
FASE_FORMACION_PON:
	ld a,r		;6679   ; y de las ocho entradas de la lista se coge una al azar
	and 007h		;667b   ; los tres bits bajos del R: ocho entradas
	jr z,FASE_FORMACION_FIN		;667d
	ld b,a			;667f
FASE_FORMACION_SIGUE:
	ld a,(hl)			;6680
	cp 0ffh		;6681
	jr z,FASE_FORMACION_FIN		;6683
	inc hl			;6685
	djnz FASE_FORMACION_SIGUE		;6686   ; hasta agotar la cuenta
FASE_FORMACION_FIN:
	ld a,(hl)			;6688   ; el 0xFF cierra la lista: si se ha pasado, se vuelve una atras
	cp 0ffh		;6689
	jr nz,FASE_SALIDA		;668b
	dec hl			;668d
FASE_SALIDA:
	ld b,(hl)			;668e
	ld a,b			;668f
	ld hl,06697h		;6690   ; ocho arranques, uno por clase de actor
	call LEE_PALABRA_DE_TABLA		;6693
	jp (hl)			;6696

; ----------------------------------------------------------------------
; DATOS tabla_6697: Ocho rutinas, destino del despachador de 0x6690
;   0x6697..0x66a7  (16 bytes)
DATA_tabla_6697:
	defw 066a7h	; 6697  -> ARRANQUE_1
	defw 066cch	; 6699  -> ARRANQUE_3
	defw 066f9h	; 669b  -> ARRANQUE_4
	defw 0670dh	; 669d  -> ARRANQUE_5
	defw 06721h	; 669f  -> ARRANQUE_6
	defw 0674bh	; 66a1  -> ARRANQUE_7
	defw 06773h	; 66a3  -> ARRANQUE_8
	defw 067bah	; 66a5  -> ARRANQUE_TABLA

; ======================================================================
; CODIGO 0x66a7..0x688a  (483 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LOS OCHO ARRANQUES. Destino del despachador de 0x6690: por donde entra en pantalla cada clase de actor y con que velocidad.
; ----------------------------------------------------------------------
ARRANQUE_1:
	call ARRANQUE_POSICION_7		;66a7   ; CLASE 0: el que gira solo, al azar
	call ARRANQUE_TABLA_2		;66aa
	push de			;66ad
	push bc			;66ae
	exx			;66af
	pop bc			;66b0
	ld (hl),b			;66b1   ; el estado, con las banderas que le haya tocado llevar
	inc hl			;66b2
	ld (hl),000h		;66b3   ; comportamiento 0, o sea el primero de los ocho
	inc hl			;66b5
	ld a,r		;66b6   ; y la primera cuenta, entre 8 y 23 fotogramas
	and 00fh		;66b8   ; los cuatro bits bajos del R: dieciseis valores
	add a,008h		;66ba
	ld (hl),a			;66bc
ARRANQUE_2:
	inc hl			;66bd
	ld (hl),c			;66be   ; la direccion de entrada, que siempre mira hacia dentro de la pantalla
	pop hl			;66bf
	ex de,hl			;66c0
	ld (hl),e			;66c1   ; la posicion en el sprite: primero la Y y luego la X
	inc hl			;66c2
	ld (hl),d			;66c3
	inc hl			;66c4
	ld a,c			;66c5   ; y el patron, que es la direccion por cuatro mas 0x20
	rlca			;66c6
	rlca			;66c7
	add a,020h		;66c8
	ld (hl),a			;66ca
	ret			;66cb
ARRANQUE_3:
	call ARRANQUE_POSICION_7		;66cc   ; este dispara nada mas nacer, sin esperar a ninguna cuenta
	call ARRANQUE_TABLA_2		;66cf
	push de			;66d2
	push bc			;66d3
	exx			;66d4
	pop bc			;66d5
	ld (hl),b			;66d6
	inc hl			;66d7
	ld (hl),001h		;66d8   ; comportamiento 1, o sea el que apunta al centro cada tanto
	inc hl			;66da
	ld (hl),003h		;66db   ; cuenta de 3, o sea que reapunta casi enseguida
	inc hl			;66dd
	ld a,c			;66de
	pop bc			;66df
	push af			;66e0
	ld a,c			;66e1
	ld (de),a			;66e2
	inc de			;66e3
	ld a,b			;66e4
	ld (de),a			;66e5
	inc de			;66e6
	pop af			;66e7
	rlca			;66e8   ; el patron es el rumbo por cuatro, mas 0x20
	rlca			;66e9
	add a,020h		;66ea
	ld (de),a			;66ec
	dec de			;66ed
	dec de			;66ee
	call DIRECCION_AL_CENTRO		;66ef   ; el disparo sale ya, apuntando a donde esta el avion
	ld bc,001ffh		;66f2   ; el disparo sale con la cuenta puesta a 0xFF
	call PON_DISPARO_ENEMIGO		;66f5
	ret			;66f8
ARRANQUE_4:
	call ARRANQUE_POSICION_7		;66f9   ; CLASE 2: el que espera, apunta y dispara
	call ARRANQUE_TABLA_2		;66fc
	push de			;66ff
	push bc			;6700
	exx			;6701
	pop bc			;6702
	ld (hl),b			;6703
	inc hl			;6704
	ld (hl),002h		;6705   ; la entrada 2 de la tabla de 0x605C: la que apunta y dispara
	inc hl			;6707
	ld (hl),000h		;6708   ; cuenta a cero: apunta en el primer fotograma
	jp ARRANQUE_2		;670a
ARRANQUE_5:
	call ARRANQUE_POSICION_7		;670d   ; la misma maquina que el 2, con la cuenta a cero
	call ARRANQUE_TABLA_2		;6710
	push de			;6713
	push bc			;6714
	exx			;6715
	pop bc			;6716
	ld (hl),b			;6717
	inc hl			;6718
	ld (hl),003h		;6719   ; comportamiento 3, el que dispara mas
	inc hl			;671b
	ld (hl),000h		;671c
	jp ARRANQUE_2		;671e
ARRANQUE_6:
	call ARRANQUE_POSICION_7		;6721   ; CLASE 4: el helicoptero que solo va en horizontal
	call ARRANQUE_TABLA_2		;6724
	res 0,b		;6727   ; el bit 0 dice hacia donde va, y lo decide de que lado sale
	ld a,d			;6729
	cp 060h		;672a
	jr nc,ARRANQUE_6_PASO		;672c
	set 0,b		;672e
ARRANQUE_6_PASO:
	push de			;6730
	push bc			;6731
	exx			;6732
	pop bc			;6733
	ld (hl),b			;6734
	inc hl			;6735
	ld (hl),004h		;6736   ; la entrada 4 de la tabla de 0x605C: la que va en horizontal
	inc hl			;6738
	ld (hl),010h		;6739   ; este repasa cada dieciseis fotogramas
ARRANQUE_6_PON:
	pop hl			;673b
	ex de,hl			;673c
	ld (hl),e			;673d
	inc hl			;673e
	ld (hl),d			;673f
	inc hl			;6740
	ld a,028h		;6741   ; y elige uno de los dos dibujos del helicoptero segun el lado
	bit 0,b		;6743
	jr z,ARRANQUE_6_FIN		;6745
	ld a,024h		;6747   ; el 0x24 mira al otro lado
ARRANQUE_6_FIN:
	ld (hl),a			;6749
	ret			;674a
ARRANQUE_7:
	call ARRANQUE_POSICION_7		;674b   ; CLASE 5: el helicoptero que va en onda
	call ARRANQUE_TABLA_2		;674e
	res 0,b		;6751
	ld a,d			;6753
	cp 060h		;6754
	jr nc,ARRANQUE_7_PASO		;6756
	set 0,b		;6758
ARRANQUE_7_PASO:
	ld c,000h		;675a   ; el paso de la onda arranca en 0 o en la mitad, segun la altura
	ld a,e			;675c
	cp 060h		;675d
	jr c,ARRANQUE_7_PON		;675f
	ld c,020h		;6761
ARRANQUE_7_PON:
	push de			;6763   ; el tramo de la onda arranca en 0 o en 32 segun de que lado se entre
	push bc			;6764
	exx			;6765
	pop bc			;6766
	ld (hl),b			;6767
	inc hl			;6768
	ld (hl),005h		;6769   ; la entrada 5 de la tabla de 0x605C: la que va en onda
	inc hl			;676b
	ld (hl),010h		;676c   ; esta repasa cada dieciseis fotogramas
	inc hl			;676e
	ld (hl),c			;676f
	jp ARRANQUE_6_PON		;6770   ; y el resto lo hace el arranque del 6
ARRANQUE_8:
	call ARRANQUE_POSICION_7		;6773   ; CLASE 6: el que sube y baja con la cuenta larga
	call ARRANQUE_TABLA_2		;6776
	ld a,d			;6779
	or a			;677a
	jr nz,ARRANQUE_8_PON		;677b
ARRANQUE_8_PASO:
	ld a,e			;677d
	cp 060h		;677e
	jr c,ARRANQUE_COMUN		;6780
	inc c			;6782
	jr ARRANQUE_COMUN		;6783
ARRANQUE_8_PON:
	cp 0afh		;6785
	jr z,ARRANQUE_8_PASO		;6787
	cp 060h		;6789
	jr nc,ARRANQUE_COMUN		;678b
	inc c			;678d
ARRANQUE_COMUN:
	push de			;678e   ; este arranca con el byte 2 puesto a la mitad del recorrido
	push bc			;678f
	exx			;6790
	pop bc			;6791
	ld (hl),b			;6792
	inc hl			;6793
	ld (hl),006h		;6794   ; comportamiento 7, el de la cuenta larga
	inc hl			;6796
	ld (hl),c			;6797
	inc hl			;6798
	ld a,r		;6799   ; la primera cuenta, entre 16 y 31 fotogramas
	and 00fh		;679b   ; los cuatro bits bajos del R: dieciseis valores
	add a,010h		;679d
	ld (hl),a			;679f
	inc hl			;67a0
	ld (hl),000h		;67a1
	pop hl			;67a3
	ex de,hl			;67a4
	ld (hl),e			;67a5
	inc hl			;67a6
	ld (hl),d			;67a7
	inc hl			;67a8
	ld a,c			;67a9
	ld c,028h		;67aa   ; los tres dibujos del helicoptero: 0x28, 0x24 y 0x20
	cp 006h		;67ac
	jr nc,ARRANQUE_FIN		;67ae
	ld c,024h		;67b0
	bit 1,a		;67b2
	jr nz,ARRANQUE_FIN		;67b4
	ld c,020h		;67b6
ARRANQUE_FIN:
	ld (hl),c			;67b8
	ret			;67b9
ARRANQUE_TABLA:
	call ARRANQUE_POSICION_7		;67ba   ; CLASE 7: el de la trayectoria tabulada
	call ARRANQUE_TABLA_2		;67bd
	push de			;67c0
	push bc			;67c1
	exx			;67c2
	pop bc			;67c3
	ld (hl),b			;67c4
	inc hl			;67c5
	ld (hl),007h		;67c6   ; comportamiento 7, el ultimo de los ocho
	inc hl			;67c8
	ld (hl),010h		;67c9   ; esta repasa cada dieciseis fotogramas
	inc hl			;67cb
	ld a,r		;67cc   ; y arranca en un punto cualquiera de la tabla
	and 00fh		;67ce   ; los cuatro bits bajos del R: dieciseis pasos
	ld (hl),a			;67d0
	inc hl			;67d1
	ld (hl),c			;67d2
	pop hl			;67d3
	ex de,hl			;67d4
	ld (hl),e			;67d5
	inc hl			;67d6
	ld (hl),d			;67d7
	inc hl			;67d8
	ld a,c			;67d9
	rlca			;67da   ; el patron es el rumbo por cuatro, mas 0x20
	rlca			;67db
	add a,020h		;67dc
	ld (hl),a			;67de
	ret			;67df
ARRANQUE_TABLA_2:
	ld hl,0e126h		;67e0   ; uno mas que ha salido en esta vida
	call LEE_POR_JUGADOR		;67e3
	inc a			;67e6
	ld (hl),a			;67e7
	and 003h		;67e8   ; uno de cada cuatro trae bandera
	cp 003h		;67ea
	jr nz,ARRANQUE_TABLA_3		;67ec
	push hl			;67ee
	call LEE_EPOCA		;67ef
	pop hl			;67f2
	cp 001h		;67f3   ; en la epoca 1 la bandera es el bit 2: lleva bomba
	ld b,084h		;67f5
	jr z,ARRANQUE_POSICION		;67f7
	cp 003h		;67f9   ; y de la epoca 3 en adelante es el bit 3: suelta un misil
	ld b,088h		;67fb
	jr nc,ARRANQUE_POSICION		;67fd
ARRANQUE_TABLA_3:
	ld b,080h		;67ff   ; en la epoca 2 no lleva ninguna
ARRANQUE_POSICION:
	ld a,(0e20fh)		;6801   ; normalmente dispara uno de cada cuatro; con el bicho grande fuera, uno de cada dos
	or a			;6804
	ld a,(hl)			;6805
	jr nz,ARRANQUE_POSICION_2		;6806
	and 003h		;6808   ; sin el bicho, hace falta que el contador sea multiplo de cuatro
	jr nz,ARRANQUE_POSICION_3		;680a
ARRANQUE_POSICION_2:
	and 001h		;680c   ; y con el bicho, basta con que sea par
	jr nz,ARRANQUE_POSICION_3		;680e
	set 1,b		;6810   ; el bit 1 puesto: este dispara
ARRANQUE_POSICION_3:
	ld a,d			;6812   ; pegado al borde izquierdo se entra volando hacia la derecha
	or a			;6813
	jr nz,ARRANQUE_POSICION_4		;6814
	ld c,002h		;6816
	ld a,e			;6818
	cp 060h		;6819
	ret nc			;681b
	inc b			;681c   ; y por la mitad de abajo, en diagonal
	ret			;681d
ARRANQUE_POSICION_4:
	cp 0afh		;681e   ; pegado al derecho, hacia la izquierda
	jr nz,ARRANQUE_POSICION_5		;6820
	ld c,006h		;6822
	ld a,e			;6824
	cp 060h		;6825
	ret c			;6827
	inc b			;6828
	ret			;6829
ARRANQUE_POSICION_5:
	ld a,e			;682a   ; por arriba se baja
	or a			;682b
	jr nz,ARRANQUE_POSICION_6		;682c
	ld c,004h		;682e   ; el rumbo 4 es hacia abajo
	ld a,d			;6830
	cp 060h		;6831
	ret c			;6833
	inc b			;6834
	ret			;6835
ARRANQUE_POSICION_6:
	ld c,000h		;6836   ; y por abajo se sube
	ld a,d			;6838
	cp 060h		;6839
	ret nc			;683b
	inc b			;683c
	ret			;683d
ARRANQUE_POSICION_7:
	exx			;683e   ; busca una ficha libre entre las seis primeras
	ld hl,0e2d0h		;683f
	ld de,0e38ch		;6842
	ld b,006h		;6845   ; seis fichas
ARRANQUE_POSICION_8:
	ld a,(hl)			;6847
	or a			;6848
	jr z,ARRANQUE_VELOCIDAD		;6849
	call SIGUIENTE_SPRITE		;684b
	call SUMA_10_A_HL		;684e   ; diez bytes por ficha
	djnz ARRANQUE_POSICION_8		;6851   ; hasta agotar las seis
	pop hl			;6853   ; si no hay ninguna, se tira la direccion de vuelta y no nace nadie
	ret			;6854
ARRANQUE_VELOCIDAD:
	push de			;6855   ; el color del sprite lo pone la epoca
	inc de			;6856
	inc de			;6857
	inc de			;6858
	ex de,hl			;6859
	push hl			;685a
	call LEE_EPOCA		;685b
	pop hl			;685e
	ld (hl),003h		;685f   ; epoca 1, verde claro
	cp 001h		;6861
	jr z,ARRANQUE_VELOCIDAD_2		;6863
	ld (hl),006h		;6865   ; epoca 2, rojo oscuro
	cp 002h		;6867
	jr z,ARRANQUE_VELOCIDAD_2		;6869
	ld (hl),00bh		;686b   ; epoca 3, amarillo claro
	cp 003h		;686d
	jr z,ARRANQUE_VELOCIDAD_2		;686f
	ld (hl),007h		;6871   ; epoca 4, cyan
	cp 004h		;6873
	jr z,ARRANQUE_VELOCIDAD_2		;6875
	ld (hl),005h		;6877   ; y epoca 5, azul claro
ARRANQUE_VELOCIDAD_2:
	ex de,hl			;6879   ; y una mas en la cuenta de los que hay en pantalla
	pop de			;687a
	exx			;687b
	push hl			;687c
	ld hl,0e121h		;687d
	call LEE_JUGADOR		;6880
	jr z,ARRANQUE_SALIDA		;6883
	inc hl			;6885
	inc hl			;6886
ARRANQUE_SALIDA:
	inc (hl)			;6887   ; uno mas en pantalla
	pop hl			;6888
	ret			;6889

; ----------------------------------------------------------------------
; DATOS salida_del_trio: POR DONDE SALE EL TRIO (0x6592). No son velocidades:
;   son posiciones, y los valores lo cantan -0x00, 0x30, 0x90 y 0xAF, o sea
;   bordes y tercios de una pantalla que llega hasta 0xAF. Se indexa con la
;   direccion del avion sin el bit 0, y las parejas se solapan de dos en dos:
;   el registro R decide si se coge la del indice o la de dos mas alla. Los
;   tres del trio salen de esa casilla, uno detras de otro, separados
;   dieciseis pixeles (0x660B)
;   0x688a..0x689c  (18 bytes)
DATA_salida_del_trio:
	defb 030h,000h,090h,000h	; 688a
	defb 0afh,030h,0afh,090h	; 688e
	defb 090h,0afh,030h,0afh	; 6892
	defb 000h,090h,000h,030h	; 6896
	defb 030h,000h	; 689a

; ----------------------------------------------------------------------
; DATOS entradas_por_donde_salen: POR DONDE ENTRA EL ENEMIGO QUE NACE
;   (0x6629). Ocho grupos de ocho bytes, uno por cada dos direcciones del
;   avion: el enemigo entra por el borde hacia el que se esta volando. Cada
;   grupo lleva dos entradas de cuatro bytes y el registro R elige una. En
;   cada entrada, las dos primeras bytes son el margen de una coordenada y los
;   dos siguientes el de la otra; cuando los dos son iguales la coordenada es
;   fija -0x00 o 0xAF, o sea un borde- y cuando son distintos se coge el
;   contador de fotogramas (0xE019) como numero al azar dentro del margen
;   0x689c..0x68dc  (64 bytes)
DATA_entradas_por_donde_salen:
	defb 000h,0afh,000h,000h,000h,0afh,000h,000h,060h,0afh,000h,000h,0afh,0afh,000h,060h	; 689c  ........`......`
	defb 0afh,0afh,000h,0afh,0afh,0afh,000h,0afh,0afh,0afh,060h,0afh,060h,0afh,0afh,0afh	; 68ac  ..........`.`...
	defb 000h,0afh,0afh,0afh,000h,0afh,0afh,0afh,000h,000h,060h,0afh,000h,060h,0afh,0afh	; 68bc  ..........`..`..
	defb 000h,000h,000h,0afh,000h,000h,000h,0afh,000h,060h,000h,000h,000h,000h,000h,060h	; 68cc  .........`.....`

; ----------------------------------------------------------------------
; DATOS clases_de_la_epoca_1: QUE BICHOS SALEN EN LA EPOCA 1. Ocho entradas y
;   un 0xFF de cierre; cada byte es una clase de actor, o sea una entrada del
;   despachador de arranques de 0x6697. Al sacar un enemigo, 0x6679 coge una
;   de las ocho al azar con el registro R, asi que las repeticiones son la
;   probabilidad: aqui salen tres del 7, tres del 1 y dos del 0, o sea los
;   comportamientos 8, 2 y 1
;   0x68dc..0x68e5  (9 bytes)
DATA_clases_de_la_epoca_1:
	defb 007h,001h,007h,001h,000h,007h,001h,000h,0ffh	; 68dc  .........

; ----------------------------------------------------------------------
; DATOS clases_de_la_epoca_2: Los de la epoca 2: dos de cada una de las clases
;   7, 2, 3 y 1, o sea los comportamientos 8, 3, 4 y 2
;   0x68e5..0x68ee  (9 bytes)
DATA_clases_de_la_epoca_2:
	defb 007h,002h,003h,003h,002h,001h,007h,001h,0ffh	; 68e5  .........

; ----------------------------------------------------------------------
; DATOS clases_de_la_epoca_3: Los de la epoca 3, la de los helicopteros: tres
;   de la clase 4, tres de la 5 y dos de la 6, o sea los comportamientos 5, 6
;   y 7, que son los tres unicos que no giran
;   0x68ee..0x68f7  (9 bytes)
DATA_clases_de_la_epoca_3:
	defb 004h,005h,006h,006h,005h,004h,004h,005h,0ffh	; 68ee  .........

; ----------------------------------------------------------------------
; DATOS clases_de_la_epoca_4: Los de la epoca 4: cuatro de la clase 3 y dos de
;   la 1 y de la 2, o sea el comportamiento 4 la mitad de las veces
;   0x68f7..0x6900  (9 bytes)
DATA_clases_de_la_epoca_4:
	defb 001h,002h,003h,003h,002h,001h,003h,003h,0ffh	; 68f7  .........

; ----------------------------------------------------------------------
; DATOS clases_de_la_epoca_5: Los de la epoca 5, la mas variada: las clases 0,
;   1, 3, 5 y 7, o sea cinco comportamientos distintos de los ocho
;   0x6900..0x6909  (9 bytes)
DATA_clases_de_la_epoca_5:
	defb 000h,001h,003h,005h,007h,003h,005h,007h,0ffh	; 6900  .........

; ----------------------------------------------------------------------
; DATOS tabla_6909: Veinticuatro bytes que leen 0x5D4A y 0x5EC7 al mirar los
;   choques
;   0x6909..0x6921  (24 bytes)
DATA_tabla_6909:
	defb 00ah,00ah,00ah,00ah,00ah,00ah,00ah,00ah,00ah,00ah,00ah,00ah,00ah,00ah,00ah,00ah	; 6909  ................
	defb 00ah,00ah,00ah,00ah,00ah,00ah,00ah,00ah	; 6919  ........

; ----------------------------------------------------------------------
; DATOS nubes_por_direccion: Cuatro juegos de 24 caracteres: el dibujo de la
;   nube segun por donde se vuela. Lo lee 0x50E6
;   0x6921..0x6981  (96 bytes)
DATA_nubes_por_direccion:
	defb 00ah,00ah,00ah,00ah,00ah,00ah,00ah,022h,023h,024h,025h,00ah,00ah,02bh,02ch,02dh,02eh,00ah,00ah,00ah,00ah,00ah,00ah,00ah	; 6921  ......."#$%..+,-........
	defb 00ah,00ah,00ah,00ah,00ah,00ah,00ah,034h,035h,036h,037h,00ah,00ah,03dh,03eh,03fh,040h,00ah,00ah,046h,047h,048h,049h,00ah	; 6939  .......4567..=>?@..FGHI.
	defb 00ah,00ah,00ah,00ah,00ah,00ah,026h,027h,028h,029h,02ah,00ah,02fh,030h,031h,032h,033h,00ah,00ah,00ah,00ah,00ah,00ah,00ah	; 6951  ......&'()*./0123.......
	defb 00ah,00ah,00ah,00ah,00ah,00ah,00ah,038h,039h,03ah,03bh,03ch,00ah,041h,042h,043h,044h,045h,00ah,04ah,04bh,04ch,04dh,04eh	; 6969  .......89:;<.ABCDE.JKLMN

; ----------------------------------------------------------------------
; DATOS nubes_patrones: El segundo juego de la nube, en grupos de 16 (0x50F8)
;   0x6981..0x69c5  (68 bytes)
DATA_nubes_patrones:
	defb 00ah,00ah,00ah,00ah,00ah,04fh,050h,00ah,00ah,054h,055h,00ah,00ah,00ah,00ah,00ah	; 6981  .....OP..TU.....
	defb 00ah,00ah,00ah,00ah,00ah,059h,05ah,00ah,00ah,05eh,05fh,00ah,00ah,063h,064h,00ah	; 6991  .....YZ..^_..cd.
	defb 00ah,00ah,00ah,00ah,051h,052h,053h,00ah,056h,057h,058h,00ah,00ah,00ah,00ah,00ah	; 69a1  ....QRS.VWX.....
	defb 00ah,00ah,00ah,00ah,00ah,05bh,05ch,05dh,00ah,060h,061h,062h,00ah,065h,066h,067h	; 69b1  .....[\].`ab.efg
	defb 00ch,000h,00eh,00fh	; 69c1

; ----------------------------------------------------------------------
; DATOS mapa_del_bicho_grande: Los ocho fotogramas del bicho grande que sale
;   al final de la epoca, 24 NUMEROS DE CARACTER cada uno (6 de ancho por 4 de
;   alto), que 0x56FF pinta en la tabla de nombres. Aqui no hay dibujos: son
;   numeros de caracter, y van del 0x68 al 0xC6 mas el 0x0A, que es el cielo y
;   hace de hueco. Los dibujos de esos caracteres son los bloques de 0x6BF2 en
;   adelante, uno por epoca
;   0x69c5..0x6a85  (192 bytes)
DATA_mapa_del_bicho_grande:
	defb 00ah,00ah,00ah,00ah,00ah,00ah,00ah,068h,069h,06ah,06bh,00ah,00ah,07bh,07ch,07dh,07eh,00ah,00ah,00ah,00ah,00ah,00ah,00ah	; 69c5  .......hijk..{|}~.......
	defb 00ah,00ah,00ah,00ah,00ah,00ah,00ah,08eh,08fh,090h,091h,00ah,00ah,0a1h,0a2h,0a3h,0a4h,00ah,00ah,0b4h,0b5h,0b6h,0b7h,00ah	; 69dd  ........................
	defb 00ah,00ah,00ah,00ah,00ah,00ah,071h,072h,073h,074h,075h,00ah,084h,085h,086h,087h,088h,00ah,00ah,00ah,00ah,00ah,00ah,00ah	; 69f5  ......qrstu.............
	defb 00ah,00ah,00ah,00ah,00ah,00ah,00ah,097h,098h,099h,09ah,09bh,00ah,0aah,0abh,0ach,0adh,0aeh,00ah,0bdh,0beh,0bfh,0c0h,0c1h	; 6a0d  ........................
	defb 00ah,00ah,00ah,00ah,00ah,00ah,06ch,06dh,06eh,06fh,070h,00ah,07fh,080h,081h,082h,083h,00ah,00ah,00ah,00ah,00ah,00ah,00ah	; 6a25  ......lmnop.............
	defb 00ah,00ah,00ah,00ah,00ah,00ah,092h,093h,094h,095h,096h,00ah,0a5h,0a6h,0a7h,0a8h,0a9h,00ah,0b8h,0b9h,0bah,0bbh,0bch,00ah	; 6a3d  ........................
	defb 00ah,00ah,00ah,00ah,00ah,00ah,00ah,076h,077h,078h,079h,07ah,00ah,089h,08ah,08bh,08ch,08dh,00ah,00ah,00ah,00ah,00ah,00ah	; 6a55  .......vwxyz............
	defb 00ah,00ah,00ah,00ah,00ah,00ah,00ah,09ch,09dh,09eh,09fh,0a0h,00ah,0afh,0b0h,0b1h,0b2h,0b3h,00ah,0c2h,0c3h,0c4h,0c5h,0c6h	; 6a6d  ........................

; ----------------------------------------------------------------------
; DATOS caracteres_del_disparo_y_las_vidas: Un bloque para 0x4BF8: 72 bytes a
;   la VRAM 0x2008, o sea los caracteres 1 a 9 del primer tercio. Los ocho
;   primeros son LOS OCHO DIBUJOS DEL DISPARO DEL JUGADOR -los mismos que
;   nombra la tabla de 0x54F6- y el noveno es la navecita con la que 0x46F7
;   pinta las vidas que quedan
;   0x6a85..0x6ad0  (75 bytes)
DATA_caracteres_del_disparo_y_las_vidas:
	defb 060h,008h,048h,0c0h,0c0h,000h,000h,000h,000h,000h,000h,018h,018h,000h,000h,000h	; 6a85  `.H.............
	defb 000h,000h,000h,003h,003h,000h,000h,000h,000h,000h,000h,000h,000h,000h,003h,003h	; 6a95  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,003h,003h,000h,000h,000h,000h,000h	; 6aa5  ................
	defb 000h,018h,018h,000h,000h,000h,000h,000h,000h,0c0h,0c0h,000h,000h,000h,0c0h,0c0h	; 6ab5  ................
	defb 000h,000h,000h,008h,018h,01ch,01ch,036h,036h,07fh,063h	; 6ac5  .......66.c

; ----------------------------------------------------------------------
; DATOS marca_de_enemigo_1: Los ocho bytes del caracter 0x0B (VRAM 0x2058),
;   que es la marca con la que 0x4763 pinta los enemigos que faltan. Esta es
;   la de las epocas 1 y 2 (0x452C): un biplano
;   0x6ad0..0x6ad8  (8 bytes)
DATA_marca_de_enemigo_1:
	defb 01ch,008h,07fh,07fh,03eh,008h,01ch,000h	; 6ad0  ....>...

; ----------------------------------------------------------------------
; DATOS marca_de_enemigo_2: La misma marca para la epoca 3: un helicoptero
;   0x6ad8..0x6ae0  (8 bytes)
DATA_marca_de_enemigo_2:
	defb 000h,0f8h,020h,072h,0feh,050h,0f8h,000h	; 6ad8  .. r.P..

; ----------------------------------------------------------------------
; DATOS marca_de_enemigo_3: La de la epoca 4: un reactor
;   0x6ae0..0x6ae8  (8 bytes)
DATA_marca_de_enemigo_3:
	defb 000h,000h,002h,01eh,0feh,038h,000h,000h	; 6ae0  .....8..

; ----------------------------------------------------------------------
; DATOS marca_de_enemigo_4: Y la de la epoca 5: un platillo
;   0x6ae8..0x6af0  (8 bytes)
DATA_marca_de_enemigo_4:
	defb 000h,000h,038h,07ch,0d6h,0feh,07ch,000h	; 6ae8  ..8|..|.

; ----------------------------------------------------------------------
; DATOS caracter_de_debajo_del_avion: Los ocho bytes del caracter 0x0C (VRAM
;   0x2060), el que 0x53FE escribe en la casilla que queda debajo del avion.
;   El area de juego NO se borra con este: se borra con el 0x0A, que es el
;   cielo (0x4B27)
;   0x6af0..0x6af8  (8 bytes)
DATA_caracter_de_debajo_del_avion:
	defb 000h,000h,010h,038h,07ch,038h,010h,000h	; 6af0  ...8|8..

; ----------------------------------------------------------------------
; DATOS nubes: Diez bloques para 0x4B81 -cinco de cuatro caracteres y cinco de
;   dos- con el 0x11 de cierre detras de cada uno: LAS NUBES, con sus copias
;   desplazadas. Van a la VRAM 0x2110, o sea a los caracteres 0x22 a 0x67, que
;   son justo los que nombran las tablas de 0x6921 y 0x6981. Las sube INIT
;   (0x4260) y valen para las dos pantallas: la partida no las recarga
;   0x6af8..0x6bf2  (250 bytes)
DATA_nubes:
	defb 000h,000h,000h,000h,000h,001h,003h,007h,000h,007h,00fh,01fh,01fh,0efh,0feh,0ffh	; 6af8  ................
	defb 000h,0c7h,0bfh,07fh,0ffh,0ffh,0ffh,0ffh,000h,000h,080h,0e0h,0f8h,0d8h,0ech,0eeh	; 6b08  ................
	defb 011h,019h,037h,03fh,01fh,02fh,01eh,00fh,001h,0ffh,0ffh,0ffh,0ffh,0bfh,07dh,0eeh	; 6b18  ..7?./........}.
	defb 0c7h,0bdh,0c3h,0ffh,0ffh,0ffh,0bfh,03ch,0e0h,0eeh,0dfh,0fdh,0ffh,0dah,0e6h,0fch	; 6b28  .......<........
	defb 000h,011h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h	; 6b38  ................
	defb 00fh,01fh,000h,000h,000h,000h,000h,0c7h,0bfh,07fh,000h,000h,000h,000h,000h,000h	; 6b48  ................
	defb 080h,0e0h,011h,000h,001h,003h,007h,019h,037h,03fh,01fh,01fh,0efh,0ffh,0ffh,0ffh	; 6b58  ........7?......
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0bdh,0c3h,0ffh,0ffh,0f8h,0d8h,0ech,0eeh,0eeh	; 6b68  ................
	defb 0dfh,0fdh,0ffh,011h,02fh,01eh,00fh,001h,000h,000h,000h,000h,0bfh,07dh,0eeh,0c7h	; 6b78  ..../........}..
	defb 000h,000h,000h,000h,0ffh,0bfh,03ch,0e0h,000h,000h,000h,000h,0dbh,0e6h,0fch,000h	; 6b88  ......<.........
	defb 000h,000h,000h,000h,011h,000h,000h,000h,000h,00fh,01fh,02fh,03fh,000h,000h,000h	; 6b98  .........../?...
	defb 000h,000h,080h,060h,0b0h,011h,07fh,03fh,05fh,067h,03ch,000h,000h,000h,0beh,07dh	; 6ba8  ...`...?_g<....}
	defb 06fh,0efh,0d8h,000h,000h,000h,011h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 6bb8  o...............
	defb 000h,000h,000h,000h,000h,000h,000h,011h,00fh,01fh,02fh,03fh,07fh,03fh,05fh,067h	; 6bc8  ........../?.?_g
	defb 000h,080h,060h,0b0h,0beh,07dh,06fh,0efh,011h,03ch,000h,000h,000h,000h,000h,000h	; 6bd8  ..`..}o..<......
	defb 000h,0d8h,000h,000h,000h,000h,000h,000h,000h,011h	; 6be8  ..........

; ----------------------------------------------------------------------
; DATOS bicho_grande_epoca_1: Cinco bloques de cuatro caracteres, con su 0x11
;   de cierre: EL BICHO GRANDE de la epoca 1, que 0x4B81 sube a la VRAM 0x2340
;   junto con sus tres copias desplazadas lateralmente. No son nubes. Cuadra
;   al byte: cinco tiras de cuatro caracteres son 4*8 + 3*5*8 por tira, 760
;   bytes en total, y 0x2340 + 760 = 0x2638, que es exactamente donde
;   CARGA_MARCADOR (0x45E9) mete las cifras
;   0x6bf2..0x6c97  (165 bytes)
DATA_bicho_grande_epoca_1:
	defb 000h,000h,018h,01dh,00fh,00fh,01dh,018h,007h,03eh,0f1h,0cfh,0bfh,0ffh,0ffh,0ffh	; 6bf2  .........>......
	defb 0f0h,07eh,08fh,0f3h,0fdh,0ffh,0ffh,0ffh,000h,000h,080h,0c0h,0e0h,0e0h,0c0h,080h	; 6c02  .~..............
	defb 011h,000h,000h,000h,000h,000h,000h,000h,000h,03fh,007h,006h,008h,01eh,00fh,007h	; 6c12  .........?......
	defb 000h,0feh,0f0h,030h,008h,03ch,0f8h,0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; 6c22  ...0.<..........
	defb 000h,011h,000h,000h,000h,000h,000h,000h,018h,01dh,000h,000h,000h,000h,007h,03eh	; 6c32  ...............>
	defb 0f1h,0cfh,000h,000h,000h,000h,0f0h,07eh,08fh,0f3h,000h,000h,000h,000h,000h,000h	; 6c42  .......~........
	defb 080h,0c0h,011h,00fh,00fh,01dh,018h,000h,000h,000h,000h,0bfh,0ffh,0ffh,0ffh,03fh	; 6c52  ...............?
	defb 007h,006h,008h,0fdh,0ffh,0ffh,0ffh,0feh,0f0h,030h,008h,0e0h,0e0h,0c0h,080h,000h	; 6c62  .........0......
	defb 000h,000h,000h,011h,000h,000h,000h,000h,000h,000h,000h,000h,01eh,00fh,007h,000h	; 6c72  ................
	defb 000h,000h,000h,000h,03ch,0f8h,0f0h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 6c82  ....<...........
	defb 000h,000h,000h,000h,011h	; 6c92

; ----------------------------------------------------------------------
; DATOS bicho_grande_epoca_2: Igual para la epoca 2
;   0x6c97..0x6d3c  (165 bytes)
DATA_bicho_grande_epoca_2:
	defb 000h,000h,01ch,03ch,03eh,03fh,03fh,01fh,000h,000h,000h,002h,004h,018h,0e7h,0ffh	; 6c97  ...<>??.........
	defb 000h,000h,000h,000h,000h,001h,0ffh,0ffh,000h,000h,000h,000h,000h,000h,0e0h,090h	; 6ca7  ................
	defb 011h,003h,000h,000h,000h,000h,000h,000h,000h,0ffh,09fh,000h,000h,000h,000h,000h	; 6cb7  ................
	defb 000h,0abh,0ffh,0fch,000h,000h,000h,000h,000h,0fch,0f8h,000h,000h,000h,000h,000h	; 6cc7  ................
	defb 000h,011h,000h,000h,000h,000h,000h,000h,01ch,03ch,000h,000h,000h,000h,000h,000h	; 6cd7  .........<......
	defb 000h,002h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 6ce7  ................
	defb 000h,000h,011h,03eh,03fh,03fh,01fh,003h,000h,000h,000h,004h,018h,0e7h,0ffh,0ffh	; 6cf7  ...>??..........
	defb 09fh,000h,000h,000h,001h,0ffh,0ffh,0abh,0ffh,0fch,000h,000h,000h,0e0h,090h,0fch	; 6d07  ................
	defb 0f8h,000h,000h,011h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 6d17  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 6d27  ................
	defb 000h,000h,000h,000h,011h	; 6d37

; ----------------------------------------------------------------------
; DATOS bicho_grande_epoca_3: Igual para la epoca 3
;   0x6d3c..0x6de1  (165 bytes)
DATA_bicho_grande_epoca_3:
	defb 000h,000h,000h,05bh,001h,003h,007h,005h,000h,000h,000h,0ebh,000h,080h,0c0h,0e0h	; 6d3c  ...[............
	defb 000h,000h,010h,07dh,010h,038h,07ch,062h,000h,000h,000h,0c0h,000h,000h,000h,000h	; 6d4c  ...}.8|b........
	defb 011h,00bh,00fh,01fh,01fh,00fh,007h,000h,000h,0f0h,0ffh,0d9h,09fh,0ffh,0bfh,0c0h	; 6d5c  ................
	defb 000h,0f1h,0ffh,0bfh,09fh,0ffh,0efh,018h,000h,000h,0c0h,0e0h,020h,0c0h,080h,000h	; 6d6c  ............ ...
	defb 000h,011h,000h,000h,000h,000h,000h,000h,000h,05bh,000h,000h,000h,000h,000h,000h	; 6d7c  .........[......
	defb 000h,0ebh,000h,000h,000h,000h,000h,000h,010h,07dh,000h,000h,000h,000h,000h,000h	; 6d8c  .........}......
	defb 000h,0c0h,011h,001h,003h,007h,005h,00bh,00fh,01fh,01fh,000h,080h,0c0h,0e0h,0f0h	; 6d9c  ................
	defb 0ffh,0d9h,09fh,010h,038h,07ch,062h,0f1h,0ffh,0bfh,09fh,000h,000h,000h,000h,000h	; 6dac  ....8|b.........
	defb 0c0h,0e0h,020h,011h,00fh,007h,000h,000h,000h,000h,000h,000h,0ffh,0bfh,0c0h,000h	; 6dbc  .. .............
	defb 000h,000h,000h,000h,0ffh,0efh,018h,000h,000h,000h,000h,000h,0c0h,080h,000h,000h	; 6dcc  ................
	defb 000h,000h,000h,000h,011h	; 6ddc

; ----------------------------------------------------------------------
; DATOS bicho_grande_epoca_4: Igual para la epoca 4
;   0x6de1..0x6e86  (165 bytes)
DATA_bicho_grande_epoca_4:
	defb 000h,000h,038h,01ch,01eh,01fh,009h,00fh,000h,000h,000h,000h,000h,000h,0ffh,0e7h	; 6de1  ..8.............
	defb 000h,000h,000h,000h,01fh,078h,0ffh,057h,000h,000h,000h,000h,000h,0c0h,0f0h,0fch	; 6df1  .....x.W........
	defb 011h,01fh,007h,000h,000h,000h,000h,000h,000h,0ffh,0ffh,000h,000h,000h,000h,000h	; 6e01  ................
	defb 000h,0ffh,0ffh,000h,000h,000h,000h,000h,000h,0e0h,000h,000h,000h,000h,000h,000h	; 6e11  ................
	defb 000h,011h,000h,000h,000h,000h,000h,000h,038h,01ch,000h,000h,000h,000h,000h,000h	; 6e21  ........8.......
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 6e31  ................
	defb 000h,000h,011h,01eh,01fh,009h,00fh,01fh,007h,000h,000h,000h,000h,0ffh,0e7h,0ffh	; 6e41  ................
	defb 0ffh,000h,000h,01fh,078h,0ffh,057h,0ffh,0ffh,000h,000h,000h,0c0h,0f0h,0fch,0e0h	; 6e51  ....x.W.........
	defb 000h,000h,000h,011h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 6e61  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 6e71  ................
	defb 000h,000h,000h,000h,011h	; 6e81

; ----------------------------------------------------------------------
; DATOS bicho_grande_epoca_5: Igual para la epoca 5. INIT (0x4295) coge ademas
;   los dos primeros bloques -0x6E86 y 0x6EA7- y los sube alternando de ocho
;   en ocho bytes a la VRAM 0x1BA0, o sea a los patrones de sprite 0x74 y 0x78
;   0x6e86..0x6f2b  (165 bytes)
DATA_bicho_grande_epoca_5:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,001h,007h,01fh,03fh,016h,016h,07fh,0f7h	; 6e86  ...........?....
	defb 080h,0e0h,0f8h,0fch,068h,068h,0feh,06fh,000h,000h,000h,000h,000h,000h,000h,000h	; 6e96  ....hh.o........
	defb 011h,007h,00fh,01fh,016h,00bh,007h,002h,000h,0ceh,0bdh,0ffh,07bh,085h,003h,001h	; 6ea6  ............{...
	defb 000h,0f3h,0fdh,03fh,0feh,0a1h,0c0h,080h,000h,0e0h,0f0h,0f8h,0c8h,070h,0e0h,040h	; 6eb6  ...?.........p.@
	defb 000h,011h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,007h	; 6ec6  ................
	defb 01fh,03fh,000h,000h,000h,000h,080h,0e0h,0f8h,0fch,000h,000h,000h,000h,000h,000h	; 6ed6  .?..............
	defb 000h,000h,011h,000h,000h,000h,000h,007h,00fh,01fh,016h,016h,016h,07fh,0f7h,0ceh	; 6ee6  ................
	defb 0bdh,0ffh,07bh,068h,068h,0feh,06fh,0f3h,0fdh,03fh,0feh,000h,000h,000h,000h,0e0h	; 6ef6  ..{hh.o..?......
	defb 0f0h,0f8h,0c8h,011h,00bh,007h,002h,000h,000h,000h,000h,000h,085h,003h,001h,000h	; 6f06  ................
	defb 000h,000h,000h,000h,0a1h,0c0h,080h,000h,000h,000h,000h,000h,070h,0e0h,040h,000h	; 6f16  ............p.@.
	defb 000h,000h,000h,000h,011h	; 6f26

; ----------------------------------------------------------------------
; DATOS avion_del_jugador: Los dieciseis dibujos del avion, uno por direccion
;   de vuelo, de 32 bytes cada uno (un sprite de 16x16). 0x53E3 sube a la VRAM
;   el que toque en cuanto el avion gira, asi que en la VRAM solo hay uno
;   0x6f2b..0x712b  (512 bytes)
DATA_avion_del_jugador:
	defb 000h,001h,001h,003h,003h,003h,006h,004h,008h,01ch,03eh,03fh,037h,023h,000h,000h,000h,000h,000h,080h,080h,080h,0c0h,040h,020h,070h,0f8h,0f8h,0d8h,088h,000h,000h	; 6f2b  ..........>?7#.........@ p......
	defb 000h,000h,000h,000h,000h,001h,000h,000h,008h,01ch,03eh,037h,007h,000h,001h,000h,000h,010h,030h,070h,0f0h,0e0h,0e0h,060h,060h,070h,0f0h,0f0h,0e0h,0e0h,0c0h,000h	; 6f4b  ..........>7......0p...``p......
	defb 000h,000h,000h,000h,000h,000h,002h,01ch,028h,07ch,07eh,03fh,03fh,013h,007h,006h,000h,000h,000h,004h,01ch,038h,0f0h,070h,040h,060h,0c0h,0c0h,0c0h,080h,000h,000h	; 6f6b  ........(|~??........8.p@`......
	defb 000h,000h,000h,000h,000h,000h,031h,03ch,078h,07ch,01fh,01fh,003h,007h,000h,000h,000h,000h,000h,000h,000h,006h,07ch,078h,030h,060h,0e0h,0c0h,0c0h,080h,000h,000h	; 6f8b  ......1<x|............|x0`......
	defb 000h,000h,000h,000h,000h,060h,071h,07ch,078h,03ch,01fh,00fh,03fh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,060h,07eh,0f8h,0c0h,000h,000h,000h,000h	; 6fab  .....`q|x<..?...........`~......
	defb 000h,000h,000h,000h,060h,077h,07eh,07ch,078h,03ch,01fh,00fh,01fh,03fh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,060h,0f8h,0feh,0f0h,000h,000h,000h	; 6fcb  ....`w~|x<...?...........`......
	defb 000h,000h,000h,030h,03bh,03dh,01eh,03ch,018h,07ch,07eh,03fh,01fh,000h,000h,000h,000h,000h,000h,000h,000h,080h,080h,040h,020h,060h,0f0h,0f0h,038h,01ch,00ch,000h	; 6feb  ...0;=.<.|~?...........@ `..8...
	defb 000h,000h,030h,038h,03dh,01fh,05eh,07ch,078h,03ch,01fh,007h,000h,000h,000h,000h,000h,000h,080h,0c0h,0e0h,0e0h,0e0h,060h,000h,040h,0e0h,0e0h,0e0h,070h,030h,010h	; 700b  ..08=.^|x<.............`.@...p0.
	defb 000h,000h,000h,023h,037h,03fh,03eh,01ch,008h,004h,006h,003h,003h,003h,001h,001h,000h,000h,000h,088h,0d8h,0f8h,0f8h,070h,020h,040h,0c0h,080h,080h,080h,000h,000h	; 702b  ...#7?>................p @......
	defb 000h,000h,002h,006h,00fh,00fh,00eh,00ch,000h,004h,00fh,00fh,00eh,00ch,018h,010h,000h,000h,018h,038h,078h,0f0h,0f4h,07ch,03ch,078h,0f0h,0c0h,000h,000h,000h,000h	; 704b  ...................8x..|<x......
	defb 000h,000h,000h,000h,001h,003h,002h,004h,008h,00ch,01eh,01fh,039h,070h,060h,000h,000h,000h,000h,018h,0b8h,078h,0f0h,078h,030h,07ch,0fch,0f8h,0f0h,000h,000h,000h	; 706b  ............9p`......x.x0|......
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,00ch,03fh,0ffh,01fh,001h,000h,000h,000h,000h,000h,000h,00ch,0dch,0fch,07ch,03ch,078h,0f0h,0e0h,0f0h,0f8h,000h,000h	; 708b  ..........?............|<x......
	defb 000h,000h,000h,000h,000h,000h,000h,000h,018h,0fch,03fh,007h,001h,000h,000h,000h,000h,000h,000h,000h,000h,00ch,01ch,07ch,03ch,078h,0f0h,0e0h,0f8h,000h,000h,000h	; 70ab  ..........?............|<x......
	defb 000h,000h,000h,000h,000h,0c0h,07ch,03ch,018h,00ch,00fh,007h,007h,003h,000h,000h,000h,000h,000h,000h,000h,000h,018h,078h,03ch,07ch,0f0h,0f0h,080h,0c0h,000h,000h	; 70cb  ......|<...............x<|......
	defb 000h,000h,000h,040h,070h,038h,01eh,01ch,008h,00ch,006h,007h,007h,003h,001h,000h,000h,000h,000h,000h,000h,000h,080h,070h,028h,07ch,0fch,0f8h,0f8h,090h,0c0h,0c0h	; 70eb  ...@p8.................p(|......
	defb 000h,010h,018h,01ch,01eh,00fh,00eh,00ch,00ch,01ch,01eh,01fh,00fh,00eh,007h,000h,000h,000h,000h,000h,000h,000h,000h,000h,020h,070h,0f8h,0d8h,0c0h,000h,000h,000h	; 710b  ........................ p......

; ----------------------------------------------------------------------
; DATOS sprites_comunes: Tres bloques para 0x4BF8: 192 bytes a la VRAM 0x1840,
;   256 a 0x1A00 y 160 a 0x1B00. Son los patrones de sprite que valen para
;   todas las epocas
;   0x712b..0x7394  (617 bytes)
DATA_sprites_comunes:
	defb 058h,040h,0c0h,000h,000h,040h,020h,011h,00bh,00fh,03fh,04fh,007h,007h,004h,010h	; 712b  X@...@ ...?O....
	defb 061h,000h,000h,000h,000h,000h,080h,004h,0c8h,0f0h,0e0h,0e4h,0f8h,0f0h,090h,088h	; 713b  a...............
	defb 004h,000h,000h,040h,020h,038h,01ch,00fh,00fh,007h,03fh,0dfh,087h,003h,007h,00eh	; 714b  ...@ 8....?.....
	defb 01ch,030h,060h,020h,063h,0c7h,0ceh,0fch,0fch,0f8h,0f9h,0ffh,0fch,0f8h,0f8h,0dch	; 715b  .0` c...........
	defb 04eh,042h,0c1h,000h,000h,000h,000h,002h,001h,000h,000h,000h,001h,000h,001h,002h	; 716b  NB..............
	defb 000h,000h,000h,000h,000h,000h,010h,008h,004h,08fh,05fh,07fh,07fh,0bfh,01fh,02fh	; 717b  .........._..../
	defb 042h,001h,000h,000h,000h,000h,088h,084h,048h,09dh,0ffh,0ffh,0feh,0feh,0f1h,088h	; 718b  B.......H.......
	defb 004h,004h,000h,000h,000h,000h,000h,040h,080h,000h,000h,000h,0a0h,040h,000h,0c0h	; 719b  .......@.....@..
	defb 000h,000h,000h,000h,000h,000h,000h,006h,009h,010h,000h,000h,000h,001h,002h,004h	; 71ab  ................
	defb 008h,000h,000h,000h,081h,042h,027h,01fh,09fh,0ffh,07fh,03fh,0ffh,0ffh,01dh,018h	; 71bb  .....B'....?....
	defb 030h,040h,021h,082h,001h,006h,00ch,0b8h,0ffh,0ffh,0feh,0ffh,0ffh,0ffh,0fbh,0f8h	; 71cb  0@!.............
	defb 0c8h,084h,002h,000h,000h,010h,020h,0c0h,080h,000h,040h,0a0h,010h,000h,000h,080h	; 71db  ...... ...@.....
	defb 060h,000h,000h,05ah,000h,000h,000h,000h,000h,000h,001h,001h,001h,003h,001h,001h	; 71eb  `..Z............
	defb 001h,003h,002h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,000h,000h	; 71fb  ................
	defb 000h,080h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,001h,002h,00ch	; 720b  ................
	defb 01ch,008h,000h,000h,000h,000h,000h,000h,000h,000h,020h,040h,080h,080h,000h,000h	; 721b  .......... @....
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,018h,00fh,018h,000h	; 722b  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,0f0h,080h,000h	; 723b  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,008h,01ch,00ch,002h,001h,001h	; 724b  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,080h	; 725b  ................
	defb 040h,020h,000h,000h,000h,000h,000h,000h,000h,000h,001h,001h,000h,000h,000h,001h	; 726b  @ ..............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,040h,0c0h,080h,080h,080h,0c0h	; 727b  ..........@.....
	defb 080h,080h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,001h	; 728b  ................
	defb 002h,004h,000h,000h,000h,000h,000h,000h,000h,000h,010h,038h,030h,040h,080h,080h	; 729b  ...........80@..
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,00fh,001h	; 72ab  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,018h,0f0h,018h	; 72bb  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,004h,002h,001h,001h,000h,000h	; 72cb  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,080h,040h,030h	; 72db  ..............@0
	defb 038h,010h,000h,000h,000h,000h,05bh,000h,0a0h,000h,000h,000h,000h,000h,000h,000h	; 72eb  8.....[.........
	defb 001h,001h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 72fb  ................
	defb 080h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,005h	; 730b  ................
	defb 007h,005h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0c0h	; 731b  ................
	defb 0e0h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,003h	; 732b  ................
	defb 007h,003h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0a0h	; 733b  ................
	defb 0e0h,0a0h,000h,000h,000h,000h,000h,000h,000h,007h,01fh,03fh,07fh,047h,047h,046h	; 734b  ...........?.GGF
	defb 024h,024h,026h,027h,01fh,04fh,033h,002h,003h,0e0h,0f8h,0fch,0ffh,0feh,0ffh,07fh	; 735b  $$&'.O3.........
	defb 07fh,037h,063h,0c1h,082h,01ch,0e0h,000h,000h,007h,01fh,03fh,07fh,07fh,0ffh,0feh	; 736b  .7c........?....
	defb 0feh,0ech,0c6h,083h,041h,038h,007h,000h,000h,0e0h,0f8h,0fch,0feh,0e2h,0e2h,062h	; 737b  ....A8.........b
	defb 024h,024h,064h,0e4h,0f8h,0f2h,0cch,040h,0c0h	; 738b  $$d....@.

; ----------------------------------------------------------------------
; DATOS humo_1: El primer fotograma del humo del bicho grande, un sprite de
;   16x16 (0x59CA)
;   0x7394..0x73b4  (32 bytes)
DATA_humo_1:
	defb 000h,000h,000h,000h,000h,000h,000h,001h,001h,000h,002h,000h,000h,001h,000h,000h,000h,000h,000h,000h,000h,000h,000h,020h,004h,0a8h,07ch,02ch,0feh,036h,04eh,001h	; 7394  ....................... ..|,.6N.

; ----------------------------------------------------------------------
; DATOS humo_2: El segundo fotograma del humo (0x59E2 y 0x59E7). Con menos de
;   seis impactos se alterna con el de 0x7394, y de seis en adelante con el de
;   0x73D4, que es mas gordo
;   0x73b4..0x73d4  (32 bytes)
DATA_humo_2:
	defb 000h,000h,000h,004h,020h,008h,002h,010h,004h,029h,011h,002h,004h,000h,000h,000h,000h,000h,000h,080h,000h,020h,080h,060h,0a8h,070h,0ech,054h,0beh,02eh,002h,000h	; 73b4  .... ....)........... .`.p.T....

; ----------------------------------------------------------------------
; DATOS humo_3: El humo del bicho ya muy tocado, de seis impactos en adelante
;   (0x59F3)
;   0x73d4..0x73f4  (32 bytes)
DATA_humo_3:
	defb 008h,042h,008h,021h,054h,000h,048h,023h,041h,012h,045h,002h,011h,002h,000h,000h,000h,040h,010h,020h,050h,0a0h,048h,038h,0dch,0b8h,0eeh,0d6h,07eh,03ch,00eh,000h	; 73d4  .B.!T.H#A.E......@. P.H8....~<..

; ----------------------------------------------------------------------
; DATOS caracteres_epoca_1: 256 bytes a la VRAM 0x1900: los patrones de sprite
;   propios de la epoca 1 (0x4548)
;   0x73f4..0x74f4  (256 bytes)
DATA_caracteres_epoca_1:
	defb 000h,001h,007h,001h,07fh,07fh,07fh,01ch,003h,003h,003h,00fh,00fh,003h,001h,000h	; 73f4  ................
	defb 000h,000h,0c0h,000h,0fch,0fch,0fch,070h,080h,080h,080h,0e0h,0e0h,080h,000h,000h	; 7404  .......p........
	defb 000h,000h,002h,007h,007h,007h,002h,003h,003h,037h,03fh,03fh,01ch,000h,000h,000h	; 7414  .........7??....
	defb 000h,000h,010h,0c8h,0fch,0fah,0f0h,03ch,0feh,0feh,0ceh,038h,01ch,000h,000h,000h	; 7424  .......<...8....
	defb 000h,000h,000h,000h,000h,030h,030h,03fh,07fh,01fh,000h,000h,000h,000h,000h,000h	; 7434  .....00?........
	defb 000h,000h,000h,000h,000h,0f0h,024h,074h,0feh,0a4h,0f4h,000h,000h,000h,000h,000h	; 7444  ......$t........
	defb 000h,000h,008h,00ch,01ch,03eh,01fh,007h,003h,006h,00fh,01fh,03fh,03bh,016h,000h	; 7454  .....>......?;..
	defb 000h,000h,000h,000h,000h,00ch,01ch,0bch,0fch,078h,0f4h,0f8h,090h,020h,000h,000h	; 7464  .........x... ..
	defb 000h,000h,001h,003h,00fh,00fh,003h,003h,003h,01ch,07fh,07fh,07fh,001h,007h,001h	; 7474  ................
	defb 000h,000h,000h,080h,0e0h,0e0h,080h,080h,080h,070h,0fch,0fch,0fch,000h,0c0h,000h	; 7484  .........p......
	defb 000h,000h,000h,000h,000h,060h,071h,07bh,07fh,03ch,05fh,03fh,013h,009h,000h,000h	; 7494  .....`q{.<_?....
	defb 000h,000h,020h,060h,070h,0f8h,0f0h,0c0h,080h,0c0h,0e0h,0f0h,0f8h,0b8h,0d0h,000h	; 74a4  .. `p...........
	defb 000h,000h,000h,000h,000h,01eh,048h,05dh,0ffh,04bh,05eh,000h,000h,000h,000h,000h	; 74b4  ......H].K^.....
	defb 000h,000h,000h,000h,000h,018h,018h,0f8h,0fch,0f8h,000h,000h,000h,000h,000h,000h	; 74c4  ................
	defb 000h,000h,010h,027h,07fh,0bfh,01eh,079h,0ffh,0ffh,0e7h,039h,070h,000h,000h,000h	; 74d4  ...'...y...9p...
	defb 000h,000h,080h,0c0h,0c0h,0c0h,080h,080h,080h,0d8h,0f8h,0f8h,070h,000h,000h,000h	; 74e4  ............p...

; ----------------------------------------------------------------------
; DATOS caracteres_epoca_2: Los de la epoca 2 (0x456B). Los dos ultimos bytes
;   los comparte con el bloque siguiente
;   0x74f4..0x75f2  (254 bytes)
DATA_caracteres_epoca_2:
	defb 000h,001h,007h,001h,003h,07fh,0feh,0feh,03fh,007h,003h,003h,007h,00fh,003h,000h	; 74f4  ........?.......
	defb 000h,000h,0c0h,000h,080h,0fch,0feh,07eh,0f8h,0c0h,080h,080h,0c0h,0e0h,080h,000h	; 7504  .......~........
	defb 000h,000h,000h,002h,007h,007h,007h,007h,007h,00fh,07fh,0feh,078h,038h,000h,000h	; 7514  ............x8..
	defb 000h,000h,020h,010h,0f8h,0fch,03ah,070h,0fch,0feh,0feh,07ch,018h,000h,000h,000h	; 7524  .. ...:p...|....
	defb 000h,000h,000h,000h,000h,040h,0e1h,0f3h,0ffh,07fh,01fh,000h,000h,000h,000h,000h	; 7534  .....@..........
	defb 000h,000h,000h,000h,000h,000h,0c4h,0f4h,0feh,0f4h,0e4h,000h,000h,000h,000h,000h	; 7544  ................
	defb 000h,000h,00ch,01ch,03ch,03eh,01fh,00fh,007h,007h,007h,007h,007h,007h,003h,000h	; 7554  ....<>..........
	defb 000h,000h,000h,000h,000h,000h,030h,0f8h,0f8h,0f0h,098h,0dah,0fch,0b8h,010h,020h	; 7564  ......0........ 
	defb 000h,000h,003h,00fh,007h,003h,003h,007h,03fh,0feh,0feh,07fh,003h,001h,007h,001h	; 7574  ........?.......
	defb 000h,000h,080h,0e0h,0c0h,080h,080h,0c0h,0f8h,07eh,0feh,0fch,080h,000h,0c0h,000h	; 7584  .........~......
	defb 000h,000h,000h,000h,000h,000h,01ch,03fh,03fh,01fh,033h,0b7h,07fh,03bh,011h,000h	; 7594  .......??.3..;..
	defb 000h,060h,070h,078h,0f8h,0f0h,0e0h,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h,080h,000h,000h	; 75a4  .`px............
	defb 000h,000h,000h,000h,000h,047h,05fh,0ffh,05fh,04fh,000h,000h,000h,000h,000h,000h	; 75b4  .....G_._O......
	defb 000h,000h,000h,000h,004h,00eh,0feh,0fch,0f0h,000h,000h,000h,000h,000h,000h,000h	; 75c4  ................
	defb 008h,010h,03fh,07fh,0b9h,01dh,07fh,0ffh,0ffh,07ch,030h,000h,000h,000h,000h,000h	; 75d4  ..?......|0.....
	defb 000h,080h,0c0h,0c0h,0c0h,0c0h,0c0h,0e0h,0fch,0feh,03ch,038h,000h,000h	; 75e4  ..........<8..

; ----------------------------------------------------------------------
; DATOS caracteres_epoca_3: 96 bytes de la epoca 3 (0x4585)
;   0x75f2..0x7652  (96 bytes)
DATA_caracteres_epoca_3:
	defb 000h,000h,000h,000h,000h,05bh,001h,003h,006h,014h,01fh,007h,008h,000h,000h,000h	; 75f2  .....[..........
	defb 000h,000h,000h,000h,000h,0ech,000h,080h,0c0h,050h,0f0h,0c0h,020h,000h,000h,000h	; 7602  .........P.. ...
	defb 000h,000h,000h,000h,000h,0b7h,080h,0e1h,0b3h,09eh,00fh,000h,001h,000h,000h,000h	; 7612  ................
	defb 000h,000h,000h,000h,080h,0dah,080h,0f0h,0f8h,01ch,0f8h,0a0h,0f0h,000h,000h,000h	; 7622  ................
	defb 000h,000h,000h,000h,002h,0b7h,002h,01fh,03fh,070h,03fh,00ah,01fh,000h,000h,000h	; 7632  ........?p?.....
	defb 000h,000h,000h,000h,000h,0dah,002h,00eh,09ah,0f2h,0e0h,000h,000h,000h,000h,000h	; 7642  ................

; ----------------------------------------------------------------------
; DATOS caracteres_epoca_4: 256 bytes de la epoca 4 (0x45A0)
;   0x7652..0x7752  (256 bytes)
DATA_caracteres_epoca_4:
	defb 000h,001h,001h,003h,002h,006h,002h,003h,00fh,01fh,03eh,07eh,07eh,01fh,003h,000h	; 7652  ..........>~~...
	defb 000h,000h,000h,080h,080h,0c0h,080h,080h,0e0h,0f0h,0f8h,0fch,0fch,0f0h,080h,000h	; 7662  ................
	defb 000h,000h,000h,000h,000h,000h,001h,007h,01fh,037h,07bh,01dh,000h,000h,000h,000h	; 7672  .........7{.....
	defb 000h,006h,00ch,03ch,05ch,070h,0f0h,0f0h,0f0h,0f0h,0f0h,0e0h,060h,000h,000h,000h	; 7682  ...<\p......`...
	defb 000h,000h,000h,000h,000h,070h,068h,05ch,07fh,03fh,00fh,03eh,000h,000h,000h,000h	; 7692  .....ph\.?.>....
	defb 000h,000h,000h,000h,000h,000h,030h,0c8h,0feh,0f0h,0c0h,000h,000h,000h,000h,000h	; 76a2  ......0.........
	defb 000h,000h,000h,000h,01dh,07bh,07dh,03fh,01fh,00fh,001h,000h,000h,000h,000h,000h	; 76b2  .....{}?........
	defb 000h,000h,000h,060h,0e0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,06ch,03ch,00ch,006h,000h	; 76c2  ...`.......l<...
	defb 000h,000h,003h,01fh,07eh,07eh,03eh,01fh,00fh,003h,002h,006h,002h,003h,001h,001h	; 76d2  ....~~>.........
	defb 000h,000h,080h,0f0h,0fch,0fch,0f8h,0f0h,0e0h,080h,080h,0c0h,080h,080h,000h,000h	; 76e2  ................
	defb 000h,000h,000h,00ch,00fh,01fh,01fh,01fh,01fh,01fh,01fh,06ch,078h,060h,0c0h,000h	; 76f2  ...........lx`..
	defb 000h,000h,000h,000h,070h,0bch,0dch,0fch,0f0h,0e0h,000h,000h,000h,000h,000h,000h	; 7702  ....p...........
	defb 000h,000h,000h,000h,000h,000h,018h,026h,0ffh,01fh,007h,000h,000h,000h,000h,000h	; 7712  .......&........
	defb 000h,000h,000h,000h,000h,01ch,02ch,074h,0fch,0f8h,0e0h,0f8h,000h,000h,000h,000h	; 7722  ......,t........
	defb 000h,0c0h,060h,078h,074h,01ch,01fh,01fh,01fh,01fh,01fh,00fh,00ch,000h,000h,000h	; 7732  ..`xt...........
	defb 000h,000h,000h,000h,000h,000h,000h,0c0h,0f0h,0d8h,0bch,070h,000h,000h,000h,000h	; 7742  ...........p....

; ----------------------------------------------------------------------
; DATOS caracteres_epoca_5: La primera mitad de la epoca 5: 0x45BB la sube
;   ocho veces seguidas, de 32 en 32 bytes
;   0x7752..0x7772  (32 bytes)
DATA_caracteres_epoca_5:
	defb 000h,003h,00fh,01ah,03ah,0ffh,07fh,033h,000h,000h,000h,000h,000h,000h,000h,000h	; 7752  ....:..3........
	defb 000h,0c0h,0f0h,058h,05ch,0ffh,0feh,0cch,000h,000h,000h,000h,000h,000h,000h,000h	; 7762  ...X\...........

; ----------------------------------------------------------------------
; DATOS caracteres_epoca_5b: La segunda mitad, que 0x45D5 sube igual a la VRAM
;   0x1A00
;   0x7772..0x7792  (32 bytes)
DATA_caracteres_epoca_5b:
	defb 000h,000h,000h,000h,000h,000h,001h,003h,005h,003h,001h,000h,000h,000h,000h,000h	; 7772  ................
	defb 000h,000h,000h,000h,000h,000h,000h,080h,040h,080h,000h,000h,000h,000h,000h,000h	; 7782  ........@.......

; ----------------------------------------------------------------------
; DATOS caracteres_del_texto: Tres bloques para 0x4BF8: 152 bytes a la VRAM
;   0x2468, 256 a 0x2500 y el principio de los 200 de 0x2618. Son los
;   caracteres con los que estan escritos el titulo y el menu
;   0x7792..0x798b  (505 bytes)
DATA_caracteres_del_texto:
	defb 064h,068h,098h,000h,000h,000h,000h,000h,000h,007h,00fh,000h,000h,000h,000h,000h	; 7792  dh..............
	defb 000h,0f8h,0f0h,03eh,03eh,03eh,03eh,03fh,03fh,03fh,03fh,01fh,03fh,07fh,0ffh,0feh	; 77a2  ...>>>>????.?...
	defb 0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,000h,03eh,03eh,000h,000h,000h,000h,000h	; 77b2  .........>>.....
	defb 01fh,07fh,0fbh,000h,000h,000h,000h,000h,00fh,0cfh,0efh,000h,000h,000h,000h,000h	; 77c2  ................
	defb 078h,0fch,0bch,000h,000h,000h,000h,000h,03fh,07fh,0f3h,000h,000h,000h,000h,000h	; 77d2  x.......?.......
	defb 087h,0c7h,0c7h,000h,000h,000h,000h,000h,0bch,0feh,0dfh,000h,000h,000h,000h,000h	; 77e2  ................
	defb 078h,0fch,0bch,060h,0f0h,0f0h,060h,000h,0f0h,0f0h,0f0h,03fh,03fh,03eh,03eh,03eh	; 77f2  x..`..`....??>>>
	defb 03eh,03eh,03eh,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h,03eh,03eh,03eh,07eh,0fch	; 7802  >>>....?...>>>~.
	defb 0fch,0f8h,0e0h,0f1h,0f1h,0f1h,0f1h,0f1h,0fbh,07fh,01fh,0efh,0efh,0efh,0efh,0efh	; 7812  ................
	defb 0efh,0cfh,00fh,01eh,01eh,01eh,01eh,01eh,01eh,01eh,01eh,065h,000h,000h,0e1h,003h	; 7822  ...........e....
	defb 03fh,0f1h,0e1h,0f3h,07fh,01eh,0e7h,0e7h,0e7h,0e7h,0e7h,0e7h,0e7h,0e7h,08fh,08fh	; 7832  ?...............
	defb 08fh,08fh,08fh,08fh,08fh,08fh,01eh,01eh,01eh,01eh,01eh,01eh,01eh,01eh,0f1h,0f2h	; 7842  ................
	defb 0f5h,0f5h,0f5h,0f5h,0f2h,0f1h,0e0h,010h,0c8h,068h,0c8h,028h,010h,0e0h,0ffh,0ffh	; 7852  .........h.(....
	defb 0ffh,00fh,00fh,00fh,00fh,00fh,0f7h,0f7h,0f7h,007h,007h,007h,007h,007h,0bch,0beh	; 7862  ................
	defb 0bfh,0bfh,0bfh,0bfh,0bdh,0bch,007h,00fh,01fh,0bfh,0ffh,0ffh,0f7h,0e7h,0bfh,0bfh	; 7872  ................
	defb 0bfh,0bch,0bch,0bch,0bfh,0bfh,0f8h,0f8h,0f8h,000h,000h,000h,0f8h,0f8h,0ffh,0ffh	; 7882  ................
	defb 0ffh,0f1h,0f0h,0f0h,0f1h,0ffh,087h,0e7h,0e7h,0f7h,0f7h,0f7h,0f7h,0e7h,0bch,0bch	; 7892  ................
	defb 0bch,0bch,0bch,0bch,0bch,0bch,000h,001h,003h,007h,007h,00fh,00fh,00fh,07eh,0ffh	; 78a2  ..............~.
	defb 0ffh,0e7h,081h,081h,000h,000h,00fh,08fh,0cfh,0e0h,0e0h,0f0h,0f0h,0f0h,0ffh,0ffh	; 78b2  ................
	defb 0ffh,0f0h,0f0h,0f0h,0f0h,0f0h,00fh,00fh,00fh,00fh,00fh,00fh,00fh,00fh,007h,007h	; 78c2  ................
	defb 007h,007h,007h,007h,007h,007h,0bch,0bch,0bch,0bch,0bch,0bch,0bch,0bch,047h,007h	; 78d2  ..............G.
	defb 007h,007h,007h,007h,007h,007h,0bfh,0bch,0bch,0bch,0bch,0bfh,0bfh,0bfh,0f8h,000h	; 78e2  ................
	defb 000h,000h,000h,0f8h,0f8h,0f8h,0ffh,0ffh,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0e7h,087h	; 78f2  ................
	defb 007h,007h,007h,007h,007h,007h,0bch,0bch,0bch,0bch,0bch,0bfh,0bfh,0bfh,00fh,00fh	; 7902  ................
	defb 00fh,007h,007h,0f3h,0f1h,0f0h,000h,000h,081h,081h,0e7h,0ffh,0ffh,07eh,0f0h,0f0h	; 7912  .............~..
	defb 0f0h,0e0h,0e0h,0c0h,080h,000h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,066h,018h	; 7922  ..............f.
	defb 0c8h,000h,000h,002h,000h,08ah,0aah,0aah,0dah,000h,000h,008h,048h,0eeh,04ah,04ah	; 7932  ............H.JJ
	defb 06ah,000h,01fh,006h,006h,006h,006h,066h,03ch,000h,07eh,018h,018h,018h,018h,018h	; 7942  j......f<.~.....
	defb 018h,000h,03eh,063h,060h,060h,060h,063h,03eh,000h,063h,066h,06ch,078h,07ch,06eh	; 7952  ..>c```c>.cflx|n
	defb 067h,000h,07eh,063h,063h,07eh,063h,063h,07eh,000h,07ch,066h,063h,063h,063h,066h	; 7962  g.~cc~cc~.|fcccf
	defb 07ch,000h,000h,000h,000h,07eh,000h,000h,000h,000h,000h,040h,049h,05ah,073h,052h	; 7972  |....~.....@IZsR
	defb 059h,000h,000h,000h,092h,052h,0ceh,002h,0dch	; 7982  Y....R...

; ----------------------------------------------------------------------
; DATOS letras: El final del bloque anterior y, a la vez, el principio de la
;   fuente: 0x427A sube 248 bytes desde aqui a la VRAM 0x26E0, o sea los
;   caracteres 0xDC a 0xFA. Los mismos bytes valen para dos juegos de
;   caracteres distintos, que es como el cartucho tiene las mismas letras en
;   dos colores sin guardarlas dos veces
;   0x798b..0x79d3  (72 bytes)
DATA_letras:
	defb 000h,03eh,063h,063h,063h,063h,063h,03eh,000h,03ch,018h,018h,018h,018h,018h,03ch	; 798b  .>ccccc>.<.....<
	defb 000h,07eh,063h,063h,063h,07eh,060h,060h,000h,060h,060h,060h,060h,060h,060h,07fh	; 799b  .~ccc~``.``````.
	defb 000h,01ch,036h,063h,063h,07fh,063h,063h,000h,066h,066h,07eh,03ch,018h,018h,018h	; 79ab  ..6cc.cc.ff~<...
	defb 000h,07fh,060h,060h,07eh,060h,060h,07fh,000h,07eh,063h,063h,062h,07ch,066h,063h	; 79bb  ..``~``..~ccb|fc
	defb 000h,03eh,063h,060h,03eh,003h,063h,03eh	; 79cb  .>c`>.c>

; ----------------------------------------------------------------------
; DATOS cifras: Las diez cifras y los ultimos simbolos de la fuente. 0x45E9
;   sube ademas estos 80 primeros bytes a la VRAM 0x2638, asi que las cifras
;   estan en la VRAM dos veces, con dos numeros de caracter y dos colores
;   0x79d3..0x7a83  (176 bytes)
DATA_cifras:
	defb 000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h,018h,018h,018h,018h,07eh	; 79d3  .."ccc"...8....~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh	; 79e3  .>c..<p..>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h,07eh,063h,003h,063h,03eh	; 79f3  ...6ff....`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,006h,00ch,018h,018h,018h	; 7a03  .>c`~cc>..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh,003h,063h,03eh	; 7a13  .>cc>cc>.>cc?.c>
	defb 000h,063h,063h,063h,07fh,063h,063h,063h,000h,03eh,063h,060h,067h,063h,063h,03fh	; 7a23  .ccc.ccc.>c`gcc?
	defb 000h,063h,077h,07fh,07fh,06bh,063h,063h,000h,063h,063h,063h,063h,036h,01ch,008h	; 7a33  .cw..kcc.cccc6..
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,000h,003h,003h,003h,003h,003h,003h,003h	; 7a43  <B....B<........
	defb 01ch,038h,070h,0e1h,0cdh,0cdh,0fdh,079h,000h,000h,000h,0eeh,06bh,06bh,06bh,0ebh	; 7a53  .8p....y....kkk.
	defb 000h,000h,000h,073h,01ah,07ah,05ah,07ah,000h,003h,000h,0f3h,05bh,05bh,05bh,05bh	; 7a63  ...s.zZz....[[[[
	defb 030h,018h,00ch,006h,00ch,018h,030h,000h,00ch,018h,030h,060h,030h,018h,00ch,000h	; 7a73  0.....0...0`0...

; ----------------------------------------------------------------------
; DATOS musica_1: El programa del canal 1 de la musica de arranque (0x43FD):
;   notas de tres bytes -periodo bajo, periodo alto con el volumen en el
;   nibble de arriba, y duracion- y 0xFF al final
;   0x7a83..0x7adb  (88 bytes)
DATA_musica_1:
	defb 000h,000h,00fh	; 7a83
	defb 0b3h,0c0h,005h	; 7a86
	defb 09fh,0c0h,094h	; 7a89
	defb 077h,0c0h,08ah	; 7a8c
	defb 000h,000h,00ah	; 7a8f
	defb 059h,0c0h,08ah	; 7a92
	defb 05fh,0c0h,00ah	; 7a95
	defb 05fh,0c0h,09eh	; 7a98
	defb 000h,000h,00ah	; 7a9b
	defb 059h,0c0h,08ah	; 7a9e
	defb 000h,000h,00ah	; 7aa1
	defb 05fh,0c0h,08ah	; 7aa4
	defb 050h,0c0h,00ah	; 7aa7
	defb 050h,0c0h,0bch	; 7aaa
	defb 000h,000h,00fh	; 7aad
	defb 050h,0c0h,005h	; 7ab0
	defb 043h,0c0h,007h	; 7ab3
	defb 047h,0c0h,006h	; 7ab6
	defb 050h,0c0h,007h	; 7ab9
	defb 050h,0c0h,007h	; 7abc
	defb 054h,0c0h,006h	; 7abf
	defb 05fh,0c0h,007h	; 7ac2
	defb 05fh,0c0h,007h	; 7ac5
	defb 064h,0c0h,006h	; 7ac8
	defb 077h,0c0h,007h	; 7acb
	defb 077h,0c0h,007h	; 7ace
	defb 064h,0c0h,006h	; 7ad1
	defb 059h,0c0h,007h	; 7ad4
	defb 077h,0c0h,08ah	; 7ad7
	defb 0ffh	; 7ada

; ----------------------------------------------------------------------
; DATOS musica_2: El canal 2 de la misma musica
;   0x7adb..0x7b33  (88 bytes)
DATA_musica_2:
	defb 000h,000h,00fh	; 7adb
	defb 0cbh,0b2h,005h	; 7ade
	defb 07dh,0b2h,094h	; 7ae1
	defb 0ddh,0b1h,08ah	; 7ae4
	defb 000h,000h,00ah	; 7ae7
	defb 065h,0b1h,08ah	; 7aea
	defb 07bh,0b1h,00ah	; 7aed
	defb 07bh,0b1h,09eh	; 7af0
	defb 000h,000h,00ah	; 7af3
	defb 065h,0b1h,08ah	; 7af6
	defb 000h,000h,00ah	; 7af9
	defb 07bh,0b1h,08ah	; 7afc
	defb 03eh,0b1h,00ah	; 7aff
	defb 03eh,0b1h,0bch	; 7b02
	defb 000h,000h,00fh	; 7b05
	defb 03eh,0b1h,005h	; 7b08
	defb 017h,0b1h,007h	; 7b0b
	defb 01ch,0b1h,006h	; 7b0e
	defb 03eh,0b1h,007h	; 7b11
	defb 03eh,0b1h,007h	; 7b14
	defb 051h,0b1h,006h	; 7b17
	defb 07bh,0b1h,007h	; 7b1a
	defb 065h,0b1h,007h	; 7b1d
	defb 091h,0b1h,006h	; 7b20
	defb 0ddh,0b1h,007h	; 7b23
	defb 0ddh,0b1h,007h	; 7b26
	defb 07bh,0b1h,006h	; 7b29
	defb 065h,0b1h,007h	; 7b2c
	defb 0ddh,0b1h,08ah	; 7b2f
	defb 0ffh	; 7b32

; ----------------------------------------------------------------------
; DATOS musica_3: El canal 3 de la misma musica
;   0x7b33..0x7b94  (97 bytes)
DATA_musica_3:
	defb 0ddh,0b1h,087h	; 7b33
	defb 000h,000h,006h	; 7b36
	defb 0ddh,0b1h,087h	; 7b39
	defb 0ddh,0b1h,087h	; 7b3c
	defb 000h,000h,006h	; 7b3f
	defb 0ddh,0b1h,087h	; 7b42
	defb 0ddh,0b1h,087h	; 7b45
	defb 000h,000h,006h	; 7b48
	defb 0ddh,0b1h,087h	; 7b4b
	defb 0ddh,0b1h,087h	; 7b4e
	defb 000h,000h,006h	; 7b51
	defb 0ddh,0b1h,087h	; 7b54
	defb 0ddh,0b1h,087h	; 7b57
	defb 000h,000h,006h	; 7b5a
	defb 0ddh,0b1h,087h	; 7b5d
	defb 0ddh,0b1h,087h	; 7b60
	defb 000h,000h,006h	; 7b63
	defb 0ddh,0b1h,087h	; 7b66
	defb 0ddh,0b1h,087h	; 7b69
	defb 000h,000h,006h	; 7b6c
	defb 0ddh,0b1h,087h	; 7b6f
	defb 0ddh,0b1h,087h	; 7b72
	defb 000h,000h,006h	; 7b75
	defb 0ddh,0b1h,087h	; 7b78
	defb 07dh,0b2h,087h	; 7b7b
	defb 000h,000h,006h	; 7b7e
	defb 07dh,0b2h,087h	; 7b81
	defb 0f5h,0b2h,094h	; 7b84
	defb 0cbh,0b2h,094h	; 7b87
	defb 0a3h,0b2h,094h	; 7b8a
	defb 017h,0b2h,0d0h	; 7b8d
	defb 0ddh,0b1h,08ah	; 7b90
	defb 0ffh	; 7b93

; ----------------------------------------------------------------------
; DATOS musica_de_epoca: El programa que suena al cambiar de epoca (0x484A)
;   0x7b94..0x7d57  (451 bytes)
DATA_musica_de_epoca:
	defb 040h,0d1h,001h	; 7b94
	defb 043h,0d1h,001h	; 7b97
	defb 030h,0d1h,001h	; 7b9a
	defb 033h,0d1h,001h	; 7b9d
	defb 020h,0d1h,001h	; 7ba0
	defb 023h,0d1h,001h	; 7ba3
	defb 010h,0d1h,001h	; 7ba6
	defb 013h,0d1h,001h	; 7ba9
	defb 000h,0d1h,001h	; 7bac
	defb 003h,0d1h,001h	; 7baf
	defb 0f0h,0d0h,001h	; 7bb2
	defb 0f3h,0d0h,001h	; 7bb5
	defb 0e0h,0d0h,001h	; 7bb8
	defb 0e3h,0d0h,001h	; 7bbb
	defb 0d0h,0d0h,001h	; 7bbe
	defb 0d3h,0d0h,001h	; 7bc1
	defb 0c0h,0d0h,001h	; 7bc4
	defb 0c3h,0d0h,001h	; 7bc7
	defb 0b0h,0d0h,001h	; 7bca
	defb 0b3h,0d0h,001h	; 7bcd
	defb 0a0h,0d0h,001h	; 7bd0
	defb 0a3h,0d0h,001h	; 7bd3
	defb 090h,0d0h,001h	; 7bd6
	defb 093h,0d0h,001h	; 7bd9
	defb 040h,0d1h,001h	; 7bdc
	defb 043h,0d1h,001h	; 7bdf
	defb 030h,0d1h,001h	; 7be2
	defb 033h,0d1h,001h	; 7be5
	defb 020h,0d1h,001h	; 7be8
	defb 023h,0d1h,001h	; 7beb
	defb 010h,0d1h,001h	; 7bee
	defb 013h,0d1h,001h	; 7bf1
	defb 000h,0d1h,001h	; 7bf4
	defb 003h,0d1h,001h	; 7bf7
	defb 0f0h,0d0h,001h	; 7bfa
	defb 0f3h,0d0h,001h	; 7bfd
	defb 0e0h,0d0h,001h	; 7c00
	defb 0e3h,0d0h,001h	; 7c03
	defb 0d0h,0d0h,001h	; 7c06
	defb 0d3h,0d0h,001h	; 7c09
	defb 0c0h,0d0h,001h	; 7c0c
	defb 0c3h,0d0h,001h	; 7c0f
	defb 0b0h,0d0h,001h	; 7c12
	defb 040h,0d1h,001h	; 7c15
	defb 043h,0d1h,001h	; 7c18
	defb 030h,0d1h,001h	; 7c1b
	defb 033h,0d1h,001h	; 7c1e
	defb 020h,0d1h,001h	; 7c21
	defb 023h,0d1h,001h	; 7c24
	defb 010h,0d1h,001h	; 7c27
	defb 013h,0d1h,001h	; 7c2a
	defb 000h,0d1h,001h	; 7c2d
	defb 003h,0d1h,001h	; 7c30
	defb 0f0h,0d0h,001h	; 7c33
	defb 0f3h,0d0h,001h	; 7c36
	defb 0e0h,0d0h,001h	; 7c39
	defb 0e3h,0d0h,001h	; 7c3c
	defb 040h,0d1h,001h	; 7c3f
	defb 043h,0d1h,001h	; 7c42
	defb 030h,0d1h,001h	; 7c45
	defb 033h,0d1h,001h	; 7c48
	defb 020h,0d1h,001h	; 7c4b
	defb 023h,0d1h,001h	; 7c4e
	defb 010h,0d1h,001h	; 7c51
	defb 013h,0d1h,001h	; 7c54
	defb 000h,0d1h,001h	; 7c57
	defb 003h,0d1h,001h	; 7c5a
	defb 0f0h,0d0h,001h	; 7c5d
	defb 040h,0d1h,001h	; 7c60
	defb 043h,0d1h,001h	; 7c63
	defb 030h,0d1h,001h	; 7c66
	defb 033h,0d1h,001h	; 7c69
	defb 020h,0d1h,001h	; 7c6c
	defb 023h,0d1h,001h	; 7c6f
	defb 010h,0d1h,001h	; 7c72
	defb 013h,0d1h,001h	; 7c75
	defb 000h,0d1h,001h	; 7c78
	defb 003h,0d1h,001h	; 7c7b
	defb 0f0h,0d0h,001h	; 7c7e
	defb 0f3h,0d0h,001h	; 7c81
	defb 0e0h,0d0h,001h	; 7c84
	defb 0e3h,0d0h,001h	; 7c87
	defb 0d0h,0d0h,001h	; 7c8a
	defb 0d3h,0d0h,001h	; 7c8d
	defb 0c0h,0d0h,001h	; 7c90
	defb 0c3h,0d0h,001h	; 7c93
	defb 0b0h,0d0h,001h	; 7c96
	defb 0b3h,0d0h,001h	; 7c99
	defb 0a8h,0c0h,001h	; 7c9c
	defb 0ach,0c0h,001h	; 7c9f
	defb 0a0h,0c0h,001h	; 7ca2
	defb 0a3h,0c0h,001h	; 7ca5
	defb 098h,0c0h,001h	; 7ca8
	defb 09ch,0c0h,001h	; 7cab
	defb 090h,0c0h,001h	; 7cae
	defb 093h,0c0h,001h	; 7cb1
	defb 088h,0c0h,001h	; 7cb4
	defb 08ch,0c0h,001h	; 7cb7
	defb 080h,0c0h,001h	; 7cba
	defb 083h,0c0h,001h	; 7cbd
	defb 078h,0c0h,001h	; 7cc0
	defb 07ch,0c0h,001h	; 7cc3
	defb 080h,0c0h,002h	; 7cc6
	defb 000h,000h,001h	; 7cc9
	defb 020h,0c0h,002h	; 7ccc
	defb 000h,000h,002h	; 7ccf
	defb 080h,0c0h,002h	; 7cd2
	defb 000h,000h,001h	; 7cd5
	defb 020h,0c0h,002h	; 7cd8
	defb 000h,000h,002h	; 7cdb
	defb 080h,0b0h,002h	; 7cde
	defb 000h,000h,001h	; 7ce1
	defb 020h,0b0h,002h	; 7ce4
	defb 000h,000h,002h	; 7ce7
	defb 080h,0b0h,002h	; 7cea
	defb 000h,000h,001h	; 7ced
	defb 020h,0b0h,002h	; 7cf0
	defb 000h,000h,002h	; 7cf3
	defb 080h,0b0h,002h	; 7cf6
	defb 000h,000h,001h	; 7cf9
	defb 020h,0b0h,002h	; 7cfc
	defb 000h,000h,002h	; 7cff
	defb 080h,0a0h,002h	; 7d02
	defb 000h,000h,001h	; 7d05
	defb 020h,0a0h,002h	; 7d08
	defb 000h,000h,002h	; 7d0b
	defb 080h,0a0h,002h	; 7d0e
	defb 000h,000h,001h	; 7d11
	defb 020h,0a0h,002h	; 7d14
	defb 000h,000h,002h	; 7d17
	defb 080h,090h,002h	; 7d1a
	defb 000h,000h,001h	; 7d1d
	defb 020h,090h,002h	; 7d20
	defb 000h,000h,002h	; 7d23
	defb 080h,080h,002h	; 7d26
	defb 000h,000h,001h	; 7d29
	defb 020h,080h,002h	; 7d2c
	defb 000h,000h,002h	; 7d2f
	defb 080h,080h,002h	; 7d32
	defb 000h,000h,001h	; 7d35
	defb 020h,080h,002h	; 7d38
	defb 000h,000h,002h	; 7d3b
	defb 080h,070h,002h	; 7d3e
	defb 000h,000h,001h	; 7d41
	defb 020h,070h,002h	; 7d44
	defb 000h,000h,002h	; 7d47
	defb 080h,070h,002h	; 7d4a
	defb 000h,000h,001h	; 7d4d
	defb 020h,070h,002h	; 7d50
	defb 000h,000h,002h	; 7d53
	defb 0ffh	; 7d56

; ----------------------------------------------------------------------
; DATOS sonido_7d57: El sonido que piden 0x48E7, 0x5C95 y 0x5FBF
;   0x7d57..0x7d88  (49 bytes)
DATA_sonido_7d57:
	defb 060h,0eah,003h	; 7d57
	defb 030h,0eah,003h	; 7d5a
	defb 0e0h,0ebh,003h	; 7d5d
	defb 040h,0dah,003h	; 7d60
	defb 0c0h,0dbh,003h	; 7d63
	defb 050h,0cah,003h	; 7d66
	defb 0a0h,0bbh,003h	; 7d69
	defb 0b0h,0aah,003h	; 7d6c
	defb 0d0h,09ah,003h	; 7d6f
	defb 0c0h,08ah,003h	; 7d72
	defb 070h,07bh,003h	; 7d75
	defb 0a0h,06ah,003h	; 7d78
	defb 0e0h,06bh,003h	; 7d7b
	defb 0cch,05ah,003h	; 7d7e
	defb 080h,04bh,003h	; 7d81
	defb 0c0h,03ah,003h	; 7d84
	defb 0ffh	; 7d87

; ----------------------------------------------------------------------
; DATOS sonido_del_bicho_grande: El sonido continuo del bicho grande (0x56A2)
;   0x7d88..0x7db6  (46 bytes)
DATA_sonido_del_bicho_grande:
	defb 0f5h,0a2h,003h	; 7d88
	defb 07dh,0a2h,002h	; 7d8b
	defb 0f5h,092h,003h	; 7d8e
	defb 07dh,092h,002h	; 7d91
	defb 0a3h,082h,003h	; 7d94
	defb 017h,082h,002h	; 7d97
	defb 0a3h,072h,003h	; 7d9a
	defb 017h,072h,002h	; 7d9d
	defb 07dh,072h,005h	; 7da0
	defb 0ffh,000h,000h	; 7da3
	defb 000h,000h,000h	; 7da6
	defb 000h,000h,000h	; 7da9
	defb 000h,000h,000h	; 7dac
	defb 000h,000h,000h	; 7daf
	defb 000h,000h,000h	; 7db2
	defb 000h	; 7db5

; ----------------------------------------------------------------------
; DATOS sonido_7db6: El sonido que pide 0x58F1
;   0x7db6..0x7dc3  (13 bytes)
DATA_sonido_7db6:
	defb 02ch,081h,002h	; 7db6
	defb 0efh,060h,001h	; 7db9
	defb 037h,071h,002h	; 7dbc
	defb 0c9h,080h,084h	; 7dbf
	defb 0ffh	; 7dc2

; ----------------------------------------------------------------------
; DATOS sonido_7dc3: El sonido que pide 0x5FB3
;   0x7dc3..0x7e0c  (73 bytes)
DATA_sonido_7dc3:
	defb 040h,0d8h,002h	; 7dc3
	defb 080h,0f0h,002h	; 7dc6
	defb 0b0h,0d0h,020h	; 7dc9
	defb 0d0h,0d0h,002h	; 7dcc
	defb 0e0h,0d0h,002h	; 7dcf
	defb 0f0h,0d0h,005h	; 7dd2
	defb 050h,0dbh,003h	; 7dd5
	defb 0d0h,0dah,003h	; 7dd8
	defb 0c0h,0dbh,003h	; 7ddb
	defb 0f0h,0cah,003h	; 7dde
	defb 060h,0cbh,003h	; 7de1
	defb 0d0h,0bah,003h	; 7de4
	defb 080h,0bbh,003h	; 7de7
	defb 0a0h,0aah,003h	; 7dea
	defb 0a0h,0abh,003h	; 7ded
	defb 090h,09ah,003h	; 7df0
	defb 0c0h,09bh,003h	; 7df3
	defb 0e0h,08ah,003h	; 7df6
	defb 0f0h,08bh,003h	; 7df9
	defb 0a0h,07bh,003h	; 7dfc
	defb 0b0h,06bh,003h	; 7dff
	defb 0c0h,05bh,003h	; 7e02
	defb 0d0h,04bh,003h	; 7e05
	defb 0f0h,04bh,005h	; 7e08
	defb 0ffh	; 7e0b

; ----------------------------------------------------------------------
; DATOS sonido_7e0c: El sonido que pide 0x5FB9
;   0x7e0c..0x7e40  (52 bytes)
DATA_sonido_7e0c:
	defb 060h,0dah,003h	; 7e0c
	defb 080h,0d3h,003h	; 7e0f
	defb 030h,0d2h,003h	; 7e12
	defb 0e0h,0d3h,003h	; 7e15
	defb 040h,0c2h,003h	; 7e18
	defb 0c0h,0c3h,003h	; 7e1b
	defb 050h,0c3h,003h	; 7e1e
	defb 0a0h,0a3h,003h	; 7e21
	defb 0b0h,0c2h,003h	; 7e24
	defb 0d0h,0a3h,003h	; 7e27
	defb 0d0h,0a2h,003h	; 7e2a
	defb 0f0h,0a3h,003h	; 7e2d
	defb 0c0h,0b2h,003h	; 7e30
	defb 0a0h,083h,003h	; 7e33
	defb 0d0h,092h,003h	; 7e36
	defb 0e0h,083h,003h	; 7e39
	defb 0cch,073h,003h	; 7e3c
	defb 090h	; 7e3f

; ----------------------------------------------------------------------
; DATOS sonido_7e40: El sonido que pide 0x4BF0. Su 0xFF de cierre, en 0x7E4C,
;   se usa ademas como programa vacio: 0x5C8F apunta el canal 2 ahi para
;   callarlo de golpe
;   0x7e40..0x7e4d  (13 bytes)
DATA_sonido_7e40:
	defb 063h,003h,0e0h	; 7e40
	defb 053h,003h,080h	; 7e43
	defb 043h,003h,0f0h	; 7e46
	defb 043h,005h,0ffh	; 7e49
	defb 0ffh	; 7e4c

; ----------------------------------------------------------------------
; DATOS sonido_7e4d: El sonido que pide 0x5E53
;   0x7e4d..0x7e69  (28 bytes)
DATA_sonido_7e4d:
	defb 047h,0c0h,004h	; 7e4d
	defb 050h,0c0h,004h	; 7e50
	defb 059h,0c0h,004h	; 7e53
	defb 05fh,0c0h,004h	; 7e56
	defb 06ah,0c0h,004h	; 7e59
	defb 077h,0c0h,004h	; 7e5c
	defb 07eh,0c0h,004h	; 7e5f
	defb 08eh,0c0h,004h	; 7e62
	defb 09fh,0c0h,010h	; 7e65
	defb 0ffh	; 7e68

; ----------------------------------------------------------------------
; DATOS sonido_del_disparo: El sonido que pide 0x54CB cada vez que sale un
;   disparo
;   0x7e69..0x7e7f  (22 bytes)
DATA_sonido_del_disparo:
	defb 080h,0d9h,001h	; 7e69
	defb 080h,061h,004h	; 7e6c
	defb 080h,0d1h,001h	; 7e6f
	defb 080h,061h,004h	; 7e72
	defb 080h,0d1h,001h	; 7e75
	defb 080h,061h,004h	; 7e78
	defb 080h,0d1h,001h	; 7e7b
	defb 0ffh	; 7e7e

; ----------------------------------------------------------------------
; DATOS sonido_de_vida_extra: El sonido que pide 0x4903 al dar una vida
;   0x7e7f..0x7e98  (25 bytes)
DATA_sonido_de_vida_extra:
	defb 08eh,0b0h,002h	; 7e7f
	defb 077h,0b0h,002h	; 7e82
	defb 06ah,0b0h,002h	; 7e85
	defb 059h,0b0h,002h	; 7e88
	defb 08eh,0b0h,004h	; 7e8b
	defb 0fdh,0b0h,004h	; 7e8e
	defb 047h,0b1h,003h	; 7e91
	defb 0b3h,0b1h,003h	; 7e94
	defb 0ffh	; 7e97

; ----------------------------------------------------------------------
; DATOS sonido_7e98: El sonido que pide 0x6579
;   0x7e98..0x7ebd  (37 bytes)
DATA_sonido_7e98:
	defb 01ch,091h,002h	; 7e98
	defb 0d4h,0a0h,002h	; 7e9b
	defb 00ch,0a1h,002h	; 7e9e
	defb 0c9h,0b0h,002h	; 7ea1
	defb 02ch,091h,003h	; 7ea4
	defb 0e1h,0a0h,003h	; 7ea7
	defb 01ch,0a1h,002h	; 7eaa
	defb 0d4h,0b0h,002h	; 7ead
	defb 00ch,091h,002h	; 7eb0
	defb 0c9h,0a0h,002h	; 7eb3
	defb 02ch,0a1h,003h	; 7eb6
	defb 0e1h,0b0h,003h	; 7eb9
	defb 0ffh	; 7ebc

; ----------------------------------------------------------------------
; DATOS sonido_7ebd: El sonido que pide 0x6401
;   0x7ebd..0x7ee0  (35 bytes)
DATA_sonido_7ebd:
	defb 08eh,0b8h,086h	; 7ebd
	defb 08eh,0a0h,004h	; 7ec0
	defb 077h,090h,003h	; 7ec3
	defb 06ah,070h,003h	; 7ec6
	defb 077h,060h,003h	; 7ec9
	defb 06ah,050h,004h	; 7ecc
	defb 0ffh,000h,000h	; 7ecf
	defb 000h,000h,000h	; 7ed2
	defb 000h,000h,000h	; 7ed5
	defb 000h,000h,000h	; 7ed8
	defb 000h,000h,000h	; 7edb
	defb 000h,000h	; 7ede

; ----------------------------------------------------------------------
; DATOS sonido_7ee0: El sonido que pide 0x6484
;   0x7ee0..0x7eed  (13 bytes)
DATA_sonido_7ee0:
	defb 077h,0c0h,002h	; 7ee0
	defb 05fh,0c0h,002h	; 7ee3
	defb 077h,0c0h,002h	; 7ee6
	defb 05fh,0c0h,002h	; 7ee9
	defb 0ffh	; 7eec

; ----------------------------------------------------------------------
; DATOS sonido_7eed: El ultimo programa de sonido, el que pide 0x5D04:
;   dieciseis notas de tres bytes y el 0xFF de cierre en 0x7F1D
;   0x7eed..0x7f1e  (49 bytes)
DATA_sonido_7eed:
	defb 060h,0eah,005h	; 7eed
	defb 050h,0e2h,005h	; 7ef0
	defb 0e0h,0e2h,003h	; 7ef3
	defb 040h,0e3h,003h	; 7ef6
	defb 080h,0b3h,002h	; 7ef9
	defb 050h,0b2h,002h	; 7efc
	defb 0b0h,0a3h,005h	; 7eff
	defb 090h,0a2h,005h	; 7f02
	defb 0d0h,0a2h,004h	; 7f05
	defb 0c0h,092h,004h	; 7f08
	defb 070h,092h,003h	; 7f0b
	defb 0a0h,082h,003h	; 7f0e
	defb 0e0h,093h,008h	; 7f11
	defb 0cch,083h,007h	; 7f14
	defb 080h,073h,007h	; 7f17
	defb 0c0h,073h,092h	; 7f1a
	defb 0ffh	; 7f1d

; ----------------------------------------------------------------------
; DATOS relleno_del_final: Los 226 bytes que sobran del cartucho, todos 0xFF.
;   Aqui es donde otros cartuchos de Konami llevan la marca oculta -el numero
;   de catalogo y el titulo en katakana, que descubrio Manuel Pazos-; Time
;   Pilot no la lleva
;   0x7f1e..0x8000  (226 bytes)
DATA_relleno_del_final:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f1e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f2e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f3e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f4e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f5e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f6e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f7e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f8e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f9e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fae  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fbe  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fce  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fde  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fee  ................
	defb 0ffh,0ffh	; 7ffe
