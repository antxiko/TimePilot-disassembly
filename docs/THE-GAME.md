# The game

A plane in the middle of the screen, sixteen directions, enemies coming from
everywhere and, once you have shot down enough of them, a huge machine you have
to bring down to jump to another era. Everything on this page comes from reading
the code that does it.

## The title screen

![The title screen with the menu](imagenes/menu.png)

The cartridge signs **©KONAMI 1983** twice, in its own font: under the title and
at the foot of the scoreboard. Below that, PLAY SELECT and four options, which
are four label lists one after the other (0x4EE8 onwards): one or two players,
with joystick or keyboard. Whichever key you press decides both things at once
(0x438E), and 0xE007 keeps the choice.

Touch nothing and the demo starts. And the demo does not carry a recorded
script: its "joystick" comes from reading **the cartridge's own code**, with the
R register as the source of chance. It is in [Findings](FINDINGS.html).

## The five eras

The panel paints the year of the current era, four characters from the table at
0x4E7C:

| era | year |
|---|---|
| 1 | 1910 |
| 2 | 1940 |
| 3 | 1970 |
| 4 | **1984** |
| 5 | 2001 |

Each era brings its own character set (0x73F4 onwards), its own scenery (0x6BF2
onwards) and its own colour list (0x4D39 onwards), which is what changes the
colour of the sky. Past era 5 it wraps back to 1 (0x489D).

## The plane

The controls do not move the plane: they tell it **which way to face**. The
table at 0x545B turns the joystick nibble into one of the sixteen directions —0
is up, 4 right, 8 down and 12 left— and the plane turns one step at a time until
it gets there, always the short way round (0x53CE).

![The sixteen drawings of the plane](imagenes/aviones.png)

Each direction has its own 32 bytes of artwork at 0x6F2B, and only one is in
video memory: the one in use, uploaded as soon as the plane turns (0x53E3). What
moves is the background, which scrolls the other way (0x4FE9), and the nine
clouds, which are name-table characters that wrap around at the edge.

## The shots

The button fires up to **eight shots at once**, each with its four-byte slot at
0xE230: the name-table cell, the direction it flies in and the character that
draws it. The table at 0x54F6 says which cell each one comes out of, depending on
the plane's direction.

They are not sprites. Every frame they are erased from their cell, the next one
is worked out —one routine per direction, at 0x5570 onwards— and they are painted
again; and before painting themselves they **read** what is in the cell (0x557B):
if it is not sky, the shot is not drawn. With the controls you can chain four in
a row (0x54E8); the demo fires always.

## The enemies

Seven ten-byte slots at 0xE2D0, with **eight different behaviours** (table at
0x605C). They all end up calling the same mover; what changes is how they choose
their direction and how often they change it: some pick at random, some aim at
the centre of the screen —which is where the plane always is— and some stop to
shoot. The routine at 0x5AB5 is the one that says, for any position, which of the
eight directions leads to the centre.

On top of that there are four era-specific slots at 0xE260 (era 1) or 0xE2A0
(from era 3 on), and from era 3 onwards two more enemies come out every eight
steps (0x5BAE).

Shooting down an enemy is worth **50 points**; an era-specific one, **500**; and
picking up the passenger, another 500.

## The big machine

Once none of the required enemies is left, the big machine turns up (0x6540). It
is not a sprite either: it is **six characters wide by four tall** painted into
the name table (0x69C5), erased and painted again every time it moves. It takes
**twenty-four hits** (0x5CF5), is worth 500 points and, on going down, takes
everything else on screen with it (0x5DE1). If it leaves the edge without being
shot down, the stage ends just the same.

## Lives, rounds and points

Two lives per player (0x443E) and one more at **10,000 points**, then every
**50,000** (0x48F0). The score is three BCD bytes, six digits, painted by adding
0xE5 to each one, which is where the digits start in the character set.

The number of enemies you must shoot down before the big machine turns up starts
at **25** and goes up by five every five rounds, capped at **50** (0x48A5). With
two players, each keeps their own era, round and count, and they take turns on
losing a life (0x4AB3).
