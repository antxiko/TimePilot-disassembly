# Open questions

What the binary does not settle on its own. The whole cartridge is explained byte
by byte and the listing gives the ROM back; this is what remains to be measured
or decided.

## What each of the eight behaviours actually is

The seven enemy slots at 0xE2D0 each carry one of the eight behaviours in the
table at 0x605C, and what can be read from the code is how they choose their
direction and how often they change it: some draw the course from the R register,
some aim at the centre of the screen, some stop to shoot. What is **not** settled
is which enemy in the game each one is: that needs playing and watching, or
measuring in the emulator.

## The 192 bytes at 0x62E2

Between the last behaviour and the routine that picks the sprite there are 192
bytes read only from there, with indices that come from the direction and the
animation frame. They are declared as what they are —tables of the enemies'
behaviour— but they have not been separated entry by entry.

## The second set of clouds

0x6981 holds 68 bytes that 0x50F8 reads in groups of sixteen, and four are left
over at the end. Either the last group is shorter, or nobody uses those four
bytes; the code does not say.

## The game screen, not fully reconstructed

`tools/graficos.py` rebuilds the whole title screen —the characters, their
colours and the label lists— and it comes out right. The game screen is only
half rebuilt: the sky and the era's colours come out, but the scoreboard does not
yet appear with its colour, so no picture of a game in progress is published
here. What cannot be checked is not shown.

## Nothing measured in the emulator

Everything on these pages comes from reading the binary. There is not one openMSX
measurement: not how long the interrupt takes, not how many VDP writes it does
per frame, not whether the six-frame share-out comes out tight or comfortable.
