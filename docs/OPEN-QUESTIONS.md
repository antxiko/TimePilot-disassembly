# Open questions

What the binary does not settle on its own. The cartridge is explained byte by
byte and the listing gives the ROM back; this is what is left to measure or to
decide.

## Four bytes too many in the second cloud set

0x6981 has 68 bytes that 0x50F8 reads in groups of sixteen, and four are left
over at the end. Either the last group is shorter, or nobody uses those four
bytes; the code does not make it clear.

## Two RAM bytes nobody reads

0xE124 and 0xE125 are cleared at the start of every life (0x47E9) and no reader
has been found for them. They sit in the middle of the stage counts —enemies
still to go on one side, enemies released on the other— so the likeliest thing is
a count that fell out of use, but that is already a guess: what can be checked is
that they are written and not read.

## The twenty-four bytes at 0x6909

They are read by 0x5D4A and 0x5EC7, the two routines that check collisions, so
where they come from and what they are for is pinned down; what has not been
settled is what each byte means on its own.

## What each sound program sounds like

The seventeen programs are bounded and it is known who asks for each one: three
channels of the opening tune, the tune that plays when the era changes, and
thirteen effects. What has not been done is listening to them one by one and
naming them —"the shot", "the explosion"— beyond the ones already named that way
because their caller leaves no doubt.

---

And what used to be on this page and **is now answered**: which enemy each of the
eight behaviours is and why era 3 does not turn, the 192 bytes at 0x62E2 —which
were three tables: two trajectories and a wave—, the game screen, which is now
rebuilt in full, and the emulator measurements. They are in [The
game](THE-GAME.html), [Findings](FINDINGS.html) and [In the
emulator](IN-THE-EMULATOR.html).
