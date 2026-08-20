# The code

Nearly nine thousand bytes of Z80 with 593 labels and the frame Konami reused
across its cartridges: the interrupt driving what moves, a dispatcher that jumps
through tables and a three-channel sound player.

## The interrupt shares out the work

INIT hooks `jp 0x4037` into H.KEYI and from then on there are two programs
running: the main one runs the game —the score, the lives, changing era, GAME
OVER— and the interrupt moves everything you can see.

The interesting part is that **it does not do the same thing on every frame**.
0xE01F counts from 0 to 5 and the six-entry table at 0x4118 says what is due:

| frame | what moves |
|---|---|
| 0 | the shots, the clouds, the plane and the collisions |
| 1, 3 and 5 | the enemies |
| 2 | the scrolling background |
| 4 | the big machine and the stage count |

Three frames out of six go to the enemies, which are what there is most of. And
at the end of the interrupt the VDP status is read again: if another one has
arrived meanwhile, it takes one more step without leaving (0x410B), so a long
frame does not swallow the next one.

## The dispatchers

Time Pilot does not put the table right after the `call`, the way other
cartridges from the same house do. The pattern here is:

```
	ld hl,<table>
	call 0x5961        ; hl = table[A]
	call 0x415E        ; jp (hl)
```

0x5961 is five instructions —`rlca`, add A to HL, read the word— and 0x415E,
0x554E and 0x6696 are three loose `jp (hl)` that serve as *call (hl)*. There are
**eight tables** like that: the six entries of the interrupt's share-out, the
sixteen directions of flight, the sixteen of the shot, the eight enemy
behaviours, the eight starts, and three more of eight steps each.

Since the table is loaded with a `ld hl,nn` and the jump lives elsewhere, a
static trace cannot follow them: all eight are declared by hand in
`src/timepilot.entries`, each with the instruction that loads it.

## The sixteen directions

Everything that flies carries a direction from 0 to 15 —0 is up, 4 is right— and
a two-component velocity. Moving means jumping to the routine for its direction
(0x52D9 onwards): each one adds or subtracts the two components to the position,
**in BCD**, with a `daa` after every addition and the carry passing to the next
cell.

The player's plane is the only one that turns gradually: the controls ask for a
direction and 0x53BB takes it there one step at a time, the short way round. The
rest change course at once.

## The actors

| where | what it is | how many |
|---|---|---|
| 0xE200 | the big machine at the end of the era | 1 |
| 0xE210 | the background clouds | 9 |
| 0xE230 | the player's shots | 8 |
| 0xE260 / 0xE2A0 | the era's own enemies | 4 |
| 0xE2CE | the passenger | 1 |
| 0xE2D0 | the enemies | 7 |

The enemies and the enemy shots move as sprites; the clouds, the player's shots
and the big machine move by writing characters into the name table. That is the
cartridge's important difference: on the MSX only four sprites fit on a line, and
this way eight are saved.

## The sound

Three eight-byte channels and a player that gives each one a step per frame
(0x4160). A channel's program is a run of three-byte notes —fine period, coarse
period with the volume and the noise bit, and duration— and an 0xFF at the end.
If the duration has bit 7 set, the note fades out on its own.

When a new sound starts it is compared with the number of the one already playing
on that channel: if the one playing is worth more, it keeps its place.

## The collisions

Everything is compared against the same rectangle, taken from a table of six
(0x4E64): the four bytes are the margin above, below, left and right. The shots,
which live in name-table cells, are first turned into pixel coordinates by
multiplying by eight (0x5C2A).

## The demo

When nobody touches anything, the game is played by 0x546B, and there is the
oddest thing in the cartridge: the demo's controls are not a recorded script nor
a random generator, but **the code itself**. The R register is taken, added to
0x5399, and whatever byte is there goes into 0xE009 as if it came from the
joystick.
