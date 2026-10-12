# The music

Everything you hear here comes from running the cartridge's own sound engine (`PASO_DE_CANAL`, 0x4160, once per channel from the interrupt, and the tracks each routine points the channel records at, 0xE020, 0xE028 and 0xE030) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the start-up tune, whole, 332 frames;
- the new-era tune, whole, 188 frames.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece plays

This game has no routine that takes a sound number: whoever wants something to play writes the pointer to its track into a channel record, and `PASO_DE_CANAL` reads it note by note. Each record is eight bytes: pointer, what is left of the note, the channel's PSG register (0, 2 or 4), the volume... The start-up tune takes all three channels; the era tune, one. The player does not run in the demo. The openMSX check was done by writing those same records during play and comparing what the PSG receives from then on. The engine does not write the PSG mixer except for noise: start-up leaves it set, and here it starts from the same value, 0xB8.

## The tunes

**The start-up tune** (0x01)

Asked for by `MUSICA_DE_ARRANQUE` (0x43FC): tres canales, programas de 0x7A83, 0x7ADB y 0x7B33; lasts 5.5 s.

<audio controls preload="none" src="audio/musica_01.mp3?v=0be7b5fc"></audio>

**The new-era tune** (0x02)

Asked for by `CAMBIA_DE_EPOCA` (0x484A): un canal, programa de 0x7B94; lasts 3.1 s.

<audio controls preload="none" src="audio/musica_02.mp3?v=bb1a2e39"></audio>
