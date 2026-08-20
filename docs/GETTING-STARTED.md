# Getting started

## What you need

`pasmo` and `z80dasm` to assemble and disassemble, and Python 3 for the tools.
Nothing else.

The cartridge is not distributed with this repository: you need your own copy,
named `timepilot.rom` in the project root. It is exactly 16384 bytes with this
sha256:

    183e80262301b18d41762d64a2fc326f4a4bef17832109225637e184d54a70d9

With any other dump the listing will not reassemble. `make comprueba` tells you
in one line.

## The commands

```sh
make          # trace, generate the listing and check everything
make verify   # assemble the listing and compare its sha256 with the cartridge
make sanity   # what reassembly cannot catch
make test     # the tests on the listing, which do not need the cartridge
make imagenes # redraw the reconstructed pictures
make web      # the pictures and these pages
```

`make` chains the first four. If all goes well, the line that matters is this
one:

```
  ensamblado : 16384 bytes  183e8026...4d54a70d9
  original   : 16384 bytes  183e8026...4d54a70d9
OK: reproducible byte a byte
```

## What is in each folder

| | |
|---|---|
| `src/timepilot.asm` | the commented listing, generated; never edited by hand |
| `src/timepilot.notes` | the annotations: labels, comments, headers and data ranges, anchored to addresses |
| `src/timepilot.entries` | the entry points the trace cannot deduce, each with its justification |
| `src/timepilot.nocode` | the zones the tracer must not read as code |
| `tools/` | the tracer, the listing generator, the checks and the drawing tools |
| `tests/` | the tests on the listing and the notes |
| `docs/` | this site |
| `work/` | what `make` produces along the way |

## How to read the listing

Every routine has an uppercase name and, where it matters, a comment saying what
it does. Data blocks are labelled `DATA_<use>`, with the width of their structure
and an explanation of what they are and how that is known. Addresses are the real
ones of the cartridge in page 1: 0x4000-0x7FFF.

To change anything, edit `src/timepilot.notes` and run `make` again: the listing
is regenerated and the checks say whether it still holds.

## How it was done

The tracer (`tools/z80trace.py`) follows the flow from the header's entry point
and from what `timepilot.entries` declares. What cannot be deduced on its own
here is **eight dispatch tables**: Time Pilot does not put the table right after
the `call`, the way other cartridges do; it loads it with a `ld hl,nn` and jumps
through a `jp (hl)` that lives somewhere else. Each one is declared, with the
instruction that loads it alongside.

Whatever is not code is left as a gap, and every gap is closed by finding the
instruction that reads it (`tools/quien_apunta.py`) and checking that the format
matches what the consuming code does with it.

What cannot be read is drawn. `tools/graficos.py` uploads to a make-believe video
memory exactly what the cartridge uploads, at the same addresses, and builds the
screen from its own label lists: if the reading were wrong, it would come out as
noise.

## Reproducibility

- assembling returns the cartridge's sha256
- no range declared as data comes out as code in the trace
- no entry point falls inside a data range
- all 16384 bytes are assigned: 8911 of code, 7473 of data, 0 unidentified
