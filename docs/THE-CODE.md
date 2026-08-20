# The code

Almost nine thousand bytes of Z80 with 593 labels and the framework Konami kept
reusing in its cartridges: the interrupt carrying whatever moves, a dispatcher
that jumps through tables, and a three-channel sound player.

## The interrupt splits the work

INIT hooks `jp 0x4037` into H.KEYI and from then on there are two programs
running: the main one runs the game —the scoreboard, the lives, the change of
era, the GAME OVER— and the interrupt moves everything you can see.

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
arrived in the meantime, it takes one more step without leaving (0x410B), so a
long frame does not swallow the next one.

That split has been measured in the emulator and it comes out even: between 8.8
and 11.1 milliseconds per phase. The numbers are in [In the
emulator](IN-THE-EMULATOR.html).

## The dispatchers

Time Pilot does not put the table behind the `call`, the way other cartridges
from the same house do. The pattern here is:

```
	ld hl,<table>
	call 0x5961        ; hl = table[A]
	call 0x415E        ; jp (hl)
```

0x5961 is five instructions —`rlca`, add A to HL, read the word— and 0x415E,
0x554E and 0x6696 are three loose `jp (hl)` that act as a *call (hl)*. There are
**eight tables** like this: the six entries of the interrupt split, the sixteen
directions of flight, the sixteen of the shot, the eight enemy behaviours, the
eight starts, and three more of eight steps.

Since the table is loaded with an `ld hl,nn` and the jump is somewhere else, a
static trace cannot follow them: all eight are declared by hand in
`src/timepilot.entries`, each with the instruction that loads it.

## The sixteen directions

Everything that flies carries a direction from 0 to 15 —0 is up, 4 is right— and
a two-component speed. Moving is jumping to the routine for its direction
(0x52D9 on): each one adds or subtracts the two components to the position, **in
BCD**, with a `daa` after each addition and the carry passing to the cell next
door.

The player's plane is the only one that turns gradually: the controls ask for a
direction and 0x53BB walks it there one step at a time, the short way round. The
rest change course all at once.

## The actors

| where | what it is | how many | bytes per slot |
|---|---|---|---|
| 0xE200 | the end-of-era big machine | 1 | 16 |
| 0xE210 | the background clouds | 9 | — |
| 0xE230 | the player's shots | 8 | 4 |
| 0xE260 | the era 1 bombs | 4 | 3 |
| 0xE270 | the enemy shots | 6 | 7 |
| 0xE2A0 | the missiles of eras 3, 4 and 5 | 4 | 9 |
| 0xE2CE | the passenger | 1 | 2 |
| 0xE2D0 | the enemies | 7 | 16 |

The enemies, the enemy shots, the bombs and the missiles move as sprites; the
clouds, the player's shots and the big machine, by writing characters into the
name table. That is the important difference in this cartridge: on the MSX only
four sprites fit on a line, and drawing the eight shots and the big machine with
characters saves nine.

The player's plane is not on the list because it has no slot: it does not move.

## The eight behaviours

Each enemy slot carries in its byte 1 which of the eight behaviours it has been
given, and the dispatcher at 0x606C jumps through the table at 0x605C. Two of
them fly a trajectory that is written down in a table:

- number **6** goes in a wave, with the 64 steps at 0x6322: each step is how much
  is added to Y and how much to X. The first 32 come down 51 pixels and the next
  32 are their exact mirror, so the Ys add up to zero and the thing comes back to
  the height it entered at while advancing 106 pixels.
- number **8** has two trajectories, and the R register tosses a coin for which
  one each actor gets: the short one (0x62E2) is sixteen stretches adding up to
  +8 of turn, a full circle in 216 frames; the long one (0x6302) opens the
  stretches up to 64 frames, 424 in total, and adds up to −6, so it never closes
  the circle.

All of them, whenever they change course, go through 0x63A2, which is where the
two flags in the state are checked: with bit 1 the actor fires at the plane, and
with bit 3 it drops a missile. Both are cleared as they are used, so each flag is
good for one go.

## The sound

Three channels of eight bytes and a player that gives each one a step per frame
(0x4160). A channel's program is a string of three-byte notes —fine period,
coarse period with the volume and the noise bit, and duration— and an 0xFF at
the end. If the duration has bit 7 set, the note fades out on its own.

When a new sound starts it is compared with the number of the one already
playing on that channel: if the one playing is worth more, it keeps its place.

## The collisions

Everything is compared against the same rectangle, taken from a table of six
(0x4E64): the four bytes are the minimum Y, the maximum Y, the minimum X and the
maximum X, and each class of collision has its own. The shots, which live in
name-table cells, are converted to pixel coordinates first by multiplying by
eight (0x5C2A).

## The attract mode

When nobody touches anything, the game is played by 0x546B, and that is the
strangest thing in the cartridge: the attract mode's controller is not a
recorded script nor a number generator, but **the code itself**. It takes the R
register, adds it to 0x5399, and whatever byte is there goes into 0xE009 as if
it came from the joystick.
