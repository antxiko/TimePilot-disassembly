# Time Pilot (Konami, MSX1) — commented disassembly

Konami's RC-703 cartridge, taken apart byte by byte. All 16,384 bytes are
accounted for and explained: no unjustified gaps, no "graphics blob", no guessed
table.

🌐 **[Read it as a website](https://antxiko.github.io/TimePilot-disassembly/)**

[README en español](README.es.md)

---

## What this is

*Time Pilot* is the game where you fly a plane that always sits in the middle of
the screen, turn on the spot and shoot, and once you have shot down enough
enemies a huge machine turns up that you have to bring down to jump to another
era. This is its code, commented, with the tools to rebuild it and check that
what comes out is the original.

The machine maps the 16 KB at 0x4000-0x7FFF —page 1—, the BIOS calls the entry
point at 0x4203, and there the boot code writes a `jp` into the H.KEYI hook and
splits the work: the main program runs the game —score, lives, changing era— and
the interrupt moves everything you can see, one step per frame.

## What is special about it

**The interrupt does not do the same thing on every frame.** It keeps a counter
from 0 to 5 and a six-entry table (0x4118): on one frame it moves the shots, the
clouds and the plane; on another the background; on another the big machine; and
on the remaining three, the enemies. Spreading the work over a six-frame cycle is
what lets it move so much on an MSX1.

**The shots and the big machine are not sprites: they are characters.** The MSX
can only show four sprites on a line, so Time Pilot keeps the sprites for the
planes and draws the eight shots and the end-of-era machine —six characters wide
by four tall— straight into the name table. Before painting, each shot **reads**
the cell: if it does not find sky there, it is not drawn.

**The plane does not turn on the spot.** The controls say which of the sixteen
directions you want, and the plane turns one step at a time until it gets there.
Each direction has its own 32 bytes of artwork, and only the one in use is in
video memory.

## Why you can believe this

`make` traces the flow, builds the listing and demands that assembling it give
back exactly the original:

```
  ensamblado : 16384 bytes  183e8026...4d54a70d9
  original   : 16384 bytes  183e8026...4d54a70d9
OK: reproducible byte a byte
```

A listing can reassemble perfectly and still be wrong —if artwork is read as
instructions the bytes do not change— so two more checks run: no range declared
as data may come out as code, and no entry point may fall inside one.

## The game in numbers

| | |
|---|---|
| bytes of code | 8,911 |
| bytes of data | 7,473 |
| bytes unidentified | **0** |
| named labels | 593 |
| anchored comments | 1,170 |
| explained data ranges | 106 |

## Some of what turned up

- **The fourth era is 1984, not 1982.** The five years the panel paints are at
  0x4E7C, four characters each: 1910, 1940, 1970, **1984** and 2001. In the
  arcade that fourth era is 1982, the year of the original; this conversion
  changed it.
- **The attract mode flies by reading the cartridge itself.** When the demo
  plays, the "joystick" does not come from any random generator: 0x546B takes
  the R register —the memory refresh one— and uses it to pick a byte of the code
  from 0x5399 on, and that byte goes straight into 0xE009 as if it came from the
  controls.
- **The shots are characters that look before they write.** Each of the eight
  reads the name table cell it is heading for and only draws itself if what is
  there is sky, so they neither overwrite each other nor cover the scenery.
- **The same letters are in video memory twice and in the cartridge once.** The
  bytes from 0x798B on are uploaded into two different character sets, so the
  same alphabet comes out in two colours without taking twice the room. The
  digits do the same (0x79D3).
- **The big machine takes twenty-four hits** (0x5CF5) and is worth 500 points; a
  normal enemy 50, and picking up the passenger 500.
- **The number of enemies you must shoot goes up in fives.** It starts at 25 and
  every five rounds five more are needed, up to a cap of 50 (0x48A5).
- **An extra life at 10,000 points and then every 50,000**: the threshold lives
  in the top digits of the score and grows by five (0x48F0).
- **A `ret` nobody reaches** at 0x6012, between two routines.
- **Silence is an empty sound program.** To shut channel 2 up at once, 0x5C8F
  points it at the 0xFF that closes the program at 0x7E40: the channel reads the
  end and goes quiet.
- **The helicopters do not turn because there are no drawings.** The biplane,
  the fighter and the jet bring eight rotations each; the era 3 helicopter
  brings 96 bytes, three drawings (0x75F2). And that era gets exactly the three
  behaviours that do not turn (0x68EE).
- **The interrupt eats half the frame.** Measured in openMSX over a recorded
  game: 50.11% of the frame, 10.09 ms out of 20.1, checked by two independent
  methods; and the six-phase split comes out even, from 8.81 to 11.10 ms. With
  the attract mode running it goes up to 71.32%.
- **This cartridge does not carry Konami's hidden mark.** Other cartridges from
  the same house hide their catalogue number and title in katakana at the end of
  the ROM, a detail documented by Manuel Pazos; here there are only 226 bytes of
  0xFF from 0x7F1E on.

## Getting started

You need `pasmo`, `z80dasm` and Python 3. The cartridge image is **not**
distributed here: put your own in the root as `timepilot.rom`, 16384 bytes,
sha256 `183e80262301b18d41762d64a2fc326f4a4bef17832109225637e184d54a70d9`.

```sh
make          # trace, build the listing and check everything
make verify   # assemble and compare with the cartridge
make sanity   # what reassembly cannot catch
make test     # the 23 tests on the listing
```

## Licence and attribution

The game is not ours: *Time Pilot* belongs to Konami, and all rights remain with
their holders. What is ours —the tools, the comments and the documentation— is
released under the licence in `LICENSE`. The cartridge image is not
distributed. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
