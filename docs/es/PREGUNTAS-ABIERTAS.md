# Preguntas abiertas

Lo que el binario no resuelve por sí solo. El cartucho está explicado byte a
byte y el listado vuelve a dar la ROM; esto es lo que queda por medir o por
decidir.

## Cuatro bytes de más en el segundo juego de nubes

0x6981 tiene 68 bytes que 0x50F8 lee en grupos de dieciséis, y sobran cuatro al
final. O el último grupo es más corto, o esos cuatro bytes no los usa nadie; el
código no lo aclara.

## Dos bytes de RAM que nadie lee

0xE124 y 0xE125 se ponen a cero al empezar cada vida (0x47E9) y no se les ha
encontrado ningún lector. Están en medio de las cuentas de la fase —a un lado
los enemigos que faltan, al otro los que han salido—, así que lo más probable es
que sean una cuenta que se dejó de usar, pero eso ya es una suposición: lo
comprobable es que se escriben y no se leen.

## Los veinticuatro bytes de 0x6909

Los leen 0x5D4A y 0x5EC7, las dos rutinas que miran los choques, y con eso está
acotado de dónde salen y para qué sirven; lo que no se ha cerrado es qué
significa cada byte por separado.

## Qué suena en cada programa de sonido

Los diecisiete programas están acotados y se sabe quién pide cada uno: hay tres
canales de la música de arranque, la música que suena al cambiar de época y
trece efectos. Lo que no está hecho es escuchar uno por uno y ponerles nombre
—«el disparo», «la explosión»— más allá de los que ya se llaman así porque su
llamador no deja dudas.

---

Y lo que estaba en esta página y **ya está contestado**: qué enemigo es cada uno
de los ocho comportamientos y por qué la época 3 no gira, los 192 bytes de
0x62E2 —que eran tres tablas: dos trayectorias y una onda—, la pantalla de
partida, que ahora se reconstruye entera, y las medidas del emulador. Están en
[El juego](EL-JUEGO.html), [Hallazgos](HALLAZGOS.html) y [En el
emulador](EN-EL-EMULADOR.html).
