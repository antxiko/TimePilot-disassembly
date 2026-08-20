# The game

A plane in the middle of the screen, sixteen directions, enemies coming from
everywhere and, once you have shot down the ones you needed, a huge machine you
have to bring down to jump to another era. Everything on this page comes from
reading the code that does it.

## The title screen

![The title screen with the menu](imagenes/menu.png)

The cartridge signs **©KONAMI 1983** twice in its own font: under the title and
at the foot of the scoreboard. Below that, PLAY SELECT and four options, which
are four label lists one after another (0x4EE8 on): one or two players, with
joystick or with keyboard. Whichever key you press decides both things at once
(0x438E), and 0xE007 keeps the controller you chose.

If nothing is touched, the attract mode starts. And it does not carry a recorded
script: its "joystick" comes from reading **the cartridge's own code**, with the
R register as the randomness. It is told in [Findings](FINDINGS.html).

## The game screen

![The era 1 screen, rebuilt byte by byte](imagenes/partida1.png)

The play area is the **first 24 columns**; from the 25th on comes the
scoreboard, painted from a single label list (0x4FA3) and then filled in by
pieces: each player's six zeros, the era's year between brackets (0x44A3) and,
under PLAYER, the lives left, drawn with the little ship of character 9
(0x46F7). The row of green marks is **the enemies still to go** before the big
machine turns up: each mark counts five (0x4763), and the mark's drawing changes
with the era (0x6AD0 on).

That picture is not a screenshot: it is built by repeating, outside the
cartridge, the same uploads to video memory and the same label lists it uses.

## The five eras

The scoreboard paints the year of the era you are in, four characters taken from
the table at 0x4E7C:

| era | year | what comes at you |
|---|---|---|
| 1 | 1910 | biplanes |
| 2 | 1940 | propeller fighters |
| 3 | 1970 | helicopters |
| 4 | **1984** | jets |
| 5 | 2001 | flying saucers |

Each era brings three things of its own: the **sprite patterns** of its enemies
(0x73F4 on), the **big machine** it ends with (0x6BF2 on) and the **colour
list** for the sky (0x4D39 on). Past era 5 it goes back to era 1 (0x489D).

And each one has its own sky, which is the first thing you notice: eras 1 and 2
in two different blues, 3 magenta, 4 green and 5 black with red clouds. That is
the colour lists from 0x4D39 on, and the five screens come out of repeating them
outside the cartridge:

![The era 2 screen](imagenes/partida2.png)
![The era 3 screen](imagenes/partida3.png)
![The era 4 screen](imagenes/partida4.png)
![The era 5 screen](imagenes/partida5.png)

What does not change is the scenery: the clouds are always the same (0x6AF8),
uploaded once by INIT for both screens; the game does not reload them.

## The plane

The controls do not move the plane: they tell it **which way to look**. The
table at 0x545B turns the joystick nibble into one of the sixteen directions
—0 is up, 4 is right, 8 is down and 12 is left— and the plane turns one step at
a time until it gets there, always the short way round (0x53CE).

![The sixteen drawings of the plane](imagenes/aviones.png)

Each direction has its own 32 bytes of artwork at 0x6F2B, and there is only one
in video memory: the one in use, uploaded as soon as the plane turns (0x53E3).
The plane has no slot and no coordinates: it is nailed at Y = 0x5C, X = 0x54
(0x5408). What moves is everything else — the background scrolls the opposite
way (0x4FE9), and the nine clouds, which are name-table characters, wrap around
when they reach the edge.

## The shots

The button fires up to **eight shots at a time**, each with its four-byte slot
at 0xE230: the name-table cell, the direction it flies in and the character that
draws it. The table at 0x54F6 says which cell each one starts from, according to
the plane's direction.

![The first sixteen characters: the shots, the little ship of the lives, the enemy mark and the cell under the plane](imagenes/caracteres.png)

They are not sprites. Every frame they are erased from their cell, the next one
is worked out —one routine per direction, at 0x5570 on— and they are painted
again; and before painting themselves they **read** what is in the cell
(0x557B): if it is not sky, the shot is not drawn. With the controls you can
chain four in a row (0x54E8), and the count is rearmed when you let go of the
button; the attract mode fires all the time.

Each shot takes with it the direction the plane was flying in when it left
(0xE146, read at 0x54EC) and never changes it again. That is why the trick of
firing while spinning works: the eight come out of different cells and each one
carries on its own way, so with the plane turning right round you end up
surrounded by shots fanning out. Nothing in the cartridge rewards that: it falls
out of the direction being copied once and left alone.

## The enemies

Seven slots of **sixteen bytes** at 0xE2D0. Each slot carries its state, which
of the **eight behaviours** it has been given (table at 0x605C), a countdown to
the next change and whatever that behaviour needs. They all end up calling the
same mover; what changes is how they pick a direction and how often:

| | what it does | where |
|---|---|---|
| 1 | changes course at random when its count runs out | 0x6087 |
| 2 | aims at the centre of the screen every time its count runs out | 0x60C5 |
| 3 | waits, aims at the centre and fires: 126 frames between shots | 0x60F8 |
| 4 | the same machinery as 3, but with 53 frames of rest, and 32 in era 4 | 0x612C |
| 5 | only moves horizontally, one pixel per frame | 0x6186 |
| 6 | flies a wave, with the 64 tabulated steps at 0x6322 | 0x61B2 |
| 7 | in stretches of 32 frames; on the second one it turns side-on | 0x61F1 |
| 8 | tabulated trajectory: sixteen stretches of (how long, which way it turns) | 0x629C |

The routine at 0x5AB5 is the one that says, for any position, which of the eight
directions leads to the centre of the screen — which is where the plane always
is.

**Which behaviour turns up in each era** is decided by five lists of eight
entries (0x68DC to 0x6909), one per era. When an enemy is released, 0x6679 picks
one of the eight **at random with the R register**, so the repeats in the list
are the odds:

| era | behaviours that can turn up |
|---|---|
| 1 | 8, 2 and 1 |
| 2 | 8, 3, 4 and 2 |
| 3 | 5, 6 and 7 |
| 4 | 4 half the time; 2 and 3 the rest |
| 5 | 1, 2, 4, 6 and 8 |

Era 3 is the odd one out, and there is a reason: **the helicopter is the only
enemy without eight rotations**. Its pattern block is 96 bytes, three drawings
(0x75F2), while the biplane, the fighter and the jet bring eight each. And the
three behaviours of that era —5, 6 and 7— are exactly the three that do not
turn: 5 goes horizontally, 6 goes in a wave and 7 turns side-on for one stretch
and faces front for the rest. No drawings, no turning.

The era 5 saucer goes the other way: **a single 32-byte drawing**, which 0x45BB
uploads eight times over to fill the eight pattern slots.

## What they drop

| where | what it is | how many | who drops it and who moves it |
|---|---|---|---|
| 0xE260 | the era 1 bombs, dropped when they pass overhead | 4 | 0x64DB / 0x57B4 |
| 0xE270 | the enemy shots, the small dot | 6 | 0x6463 / 0x5796 |
| 0xE2A0 | the missiles of eras 3, 4 and 5, which go straight for the centre | 4 | 0x63CB / 0x58BC |
| 0xE2CE | the passenger, the parachutist who comes down every sixteen enemies | 1 | 0x65C7 / 0x5897 |

On top of that, from era 3 on, one enemy in every thirty-two brings two more
missiles that come up from the two bottom corners (0x5BAE, with the positions at
0x5C13).

## The big machine

When none of the enemies you needed are left, the big machine comes out
(0x6540). It is not a sprite either: it is **six characters wide by four tall**
painted into the name table (0x69C5), erased and repainted every time it moves.

![The era 3 big machine, with its frames](imagenes/bicho3.png)

Each era has its own, and its drawings go up to video memory with three shifted
copies beside them, which is what lets it move in two-pixel steps (0x6BF2 on).
It takes **twenty-four hits** (0x5CF5), is worth 500 points and, when it falls,
it takes with it everything else on screen (0x5DE1). If it leaves through the
edge without being shot down, the stage ends all the same.

All five, one after another, exactly as they go up to video memory:

![The era 1 big machine](imagenes/bicho1.png)
![The era 2 big machine](imagenes/bicho2.png)
![The era 4 big machine](imagenes/bicho4.png)
![The era 5 big machine](imagenes/bicho5.png)

## Lives, rounds and points

Two lives per player (0x443E) and one more at **10,000 points**, and then every
**50,000** (0x48F0). The score is three BCD bytes, six digits, painted by adding
0xE5 to each one, which is where the digits start in the character set.

Shooting down an enemy is **50 points**; the ones the era brings, **500**;
picking up the passenger, another 500; and the big machine, 500.

The enemies you have to shoot down before the big machine turns up start at
**25** (0xE120, loaded at 0x445A) and go up by five every five rounds, to a
ceiling of 50 (0x48A5). When the big machine comes out, that count is left at 5
(0x56F3). With two players, each carries their own era, round and count, and
they take turns as they lose a life (0x4AB3).
