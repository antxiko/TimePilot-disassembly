# The cartridge

## The header and the machine

The first eighteen bytes are the header the BIOS reads:

```
4000  41 42        "AB", a cartridge's signature
4002  03 42        INIT = 0x4203
4004  00 00 00 00 00 00   STATEMENT, DEVICE and TEXT set to zero
400A  00 x8        padding
```

With the header at 0x4000 the BIOS maps the cartridge into **page 1**
(0x4000-0x7FFF) and jumps to INIT once it has finished booting. INIT writes
`jp 0x4037` into the H.KEYI hook (0xFD9A), clears RAM from 0xE000 to 0xE7FE and
leaves the stack right behind it, at 0xE7FF. From then on the work is split: the
main program runs the game —score, lives, changing era, GAME OVER— and the
interrupt moves everything you can see.

With 0xE000-0xE7FF of RAM, a 16 KB MSX is enough.

## Video memory

SCREEN 2, with the eight registers at 0x4D05:

| register | value | what it says |
|---|---|---|
| R0 | 0x02 | graphics mode 2 |
| R1 | 0xE2 | 16 K, screen and interrupt on, 16 × 16 sprites |
| R2 | 0x0E | name table at 0x3800 |
| R3 | 0x7F | colour table at 0x0000 |
| R4 | 0x07 | pattern table at 0x2000 |
| R5 | 0x76 | sprite attributes at 0x3B00 |
| R6 | 0x03 | sprite patterns at 0x1800 |
| R7 | 0xE1 | ink 14 on background 1 |

In SCREEN 2 the screen is split into **three thirds** of eight rows, and each
third has its own 256 patterns and its own colours. Time Pilot loads all three
the **same**: it uploads the first and then copies it twice with
`COPIA_VRAM_A_VRAM` (0x4C97), which reads and writes byte by byte with an offset
of 0x800. Since by the time it reaches the second third that third is already
written, the copy propagates into the third one on its own.

The play area is the first 24 columns and all 24 rows; the scoreboard lives in
the top row and from column 24 on.

## The characters

![The title and menu characters](imagenes/letras.png)

Characters go up through a block list (0x4BF8): two bytes with the VRAM address,
one with how many are coming and the data behind it. The title and the menu are
written with characters from 0xC3 on, and the game's font —letters and digits—
with those from 0xDC on.

The odd part is that **they are the same bytes**: 0x798B is uploaded twice, once
as the tail of the menu block and once as the head of the font (0x427A), and the
digits at 0x79D3 do the same (0x45E9). In SCREEN 2 colour goes per character, so
having the same drawing under two numbers is what allows the same alphabet in two
colours without taking twice the room.

## The sprites

The attribute table holds 32 sprites, and the working copy lives in RAM
(0xE380): the interrupt sends it up to VRAM in full on every frame (0x40CA). At
the start of each era, seven groups of three bytes (how many, pattern, colour)
share out the 21 sprites needed —the plane, the enemies, the shots and the
labels— and leave them all off-screen, at Y = 0xD1.

The plane is the only one that changes artwork: its sixteen patterns are at
0x6F2B and only the one in use goes up to VRAM.

## The sound

Three eight-byte channels at 0xE020, 0xE028 and 0xE030, and a player (0x4160)
that gives each one a step per frame. A sound program is a run of **three-byte**
notes: fine period, coarse period with the volume in the top nibble and bit 3 for
noise, and duration. With bit 7 of the duration set, the note fades away by
itself one step at a time. An 0xFF ends the program.

A channel is silent when the high byte of its pointer is zero, and to shut it up
at once it is enough to point it at an 0xFF: that is exactly what 0x5C8F does
with the one that closes the program at 0x7E40.

## The RAM map

| address | what it holds |
|---|---|
| 0xE000/0xE001 | game mode and which player is playing |
| 0xE002/0xE003 | each player's lives |
| 0xE005/0xE006 | next extra-life threshold |
| 0xE00B-0xE013 | both players' scores and the high score, in BCD |
| 0xE019 | the frame counter everything hangs off |
| 0xE01F | the interrupt's share-out phase (0-5) |
| 0xE020-0xE037 | the three sound channels |
| 0xE120-0xE122 | the plane's direction, the one the controls ask for and the turn count |
| 0xE180-0xE183 | each player's era and round |
| 0xE200-0xE20F | the big machine |
| 0xE210-0xE22F | the nine clouds |
| 0xE230-0xE24F | the eight shots, four bytes each |
| 0xE260-0xE2CF | the era's enemies and the passenger |
| 0xE2D0-0xE2FF | the seven enemy slots |
| 0xE380-0xE3FF | the RAM copy of the sprite table |
| 0xE400-0xE4A0 | the workshop where characters get shifted |

## What it is made of

| | bytes | |
|---|---|---|
| code | 8911 | 54.4 % |
| data | 7473 | 45.6 % |
| unidentified | **0** | |

The data, from the inside: **1,405** bytes are the fifteen sound programs, which
take up almost all the end of the cartridge; **1,267** the scenery of the five
eras and of the title screen; **926** each era's own characters; **828** those of
the title, the menu and the font; **713** the common sprite patterns; and **512**
the sixteen drawings of the plane. The rest —some 1,800— are tables: the years,
the collision boxes, the sixteen directions, the screen's label lists and the
eight dispatch tables.
