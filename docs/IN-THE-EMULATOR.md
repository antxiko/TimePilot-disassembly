# In the emulator

Everything else on these pages comes from reading the binary. This page is the
opposite: these are measurements, taken with the cartridge running in openMSX,
and each one says which window it was taken over. What has not been measured is
not here.

## How it was measured

The basis is **a real game**, played and recorded on a Philips VG-8020 with
`tools/omsx_graba.tcl`: 170 seconds, era 1 from t=10 to t=134, era 2 up to t=164
and game over at t=166. The whole replay is saved, so the measurements can be
repeated as many times as needed over exactly the same game.

`tools/omsx_repasa.tcl` walks it second by second reading the game's RAM and says
what state it is in at each point —attract mode or game, era, round, lives,
enemies still to go— and the window is chosen from that: **from t=30 to t=90**,
sixty straight seconds of play in era 1, with no attract mode in between.

Then `tools/omsx_mide.tcl` sets two breakpoints, one at the entry of the
cartridge's hook (0x4037) and one at its exit (0x4112), and times the emulated
time between them.

## What the interrupt takes

| | |
|---|---|
| ROM interrupts in 60 emulated seconds | 2,980 |
| frames per second | 49.67 |
| time inside the hook | 30.07 s out of 60 |
| **percentage of the frame** | **50.11%** |
| per interrupt | 10.09 ms out of a 20.1 ms frame |
| the shortest / the longest | 0.07 ms / 15.15 ms |

So **half the machine's time goes on the cartridge's interrupt**, and the other
half is everything left for the main program.

The figure is checked with a second method that shares nothing with the first:
sampling the program counter every millisecond and counting how many samples
land with the interrupt running. That gives 30,048 samples out of 59,910, or
**50.16%** (`tools/omsx_control_pc.tcl`).

## What each phase of the six-frame cycle costs

The interrupt does not do the same thing on every frame: 0xE01F counts from 0 to
5 and each phase moves one thing. Measuring per phase, over the same window:

| phase | what it moves | average ms |
|---|---|---|
| 0 | the shots, the clouds, the plane and the collisions | 10.18 |
| 1 | the enemies | 10.14 |
| 2 | the scrolling background | 11.10 |
| 3 | the enemies | 10.17 |
| 4 | the big machine and the stage count | 8.81 |
| 5 | the enemies | 10.17 |

Between the dearest phase and the cheapest there are **2.3 milliseconds**: the
split is genuinely balanced, not just a way of ordering the work.

## To the VDP, per frame

| | |
|---|---|
| writes to port 0x98 (data) | 360.6 |
| writes to port 0x99 (address) | 106.6 |

Of the 360.6 data writes, **96 are always the same ones**: the whole sprite
attribute table, which the interrupt uploads every frame from its RAM copy
(0x40CA) without checking whether anything has changed.

## The more there is in the air, the more it costs

The 50% above is a quiet window. Measuring two more, with the same method:

| window | what was going on | % of the frame |
|---|---|---|
| replay, t=30 to t=90 | in play, era 1 | 50.11% |
| 30 s being piloted | in play, era 1, from 25 to 17 enemies to go | 59.04% |
| 60 s of attract mode | the demo, which fires non-stop | 71.32% |

All three are measurements, not estimates. What is **not** measured is how that
difference breaks down: all that can be said without going past what has been
checked is that the dearest window is the one with most things in the air, and
that the attract mode, which presses the button on every frame, is the worst case
of the three.

## The trap that cost an afternoon

The first attempt at measuring the cost was to sample the program counter and
count how many samples landed **between 0x4037 and 0x4117**, which is the piece
of cartridge where the hook lives. That gave **1.20%**.

That figure measures nothing: the hook calls routines spread all over the
cartridge, so most of the time the program counter is outside that range even
though the interrupt is working. What has to be counted is not where the PC is,
but whether it has gone in and not yet come out: a flag that the entry breakpoint
sets and the exit breakpoint clears.

Both figures are in `medidas/control_pc.txt`, side by side, in case the warning
is of use to anyone. That folder, `medidas/`, holds the raw output of all these
tools.

## One number that comes out the same measured as read

Reading the code, 0xE120 starts each stage at 25 and goes down by one per enemy
shot down; when it reaches zero the big machine comes out and the count is left
at 5. Reading that same address second by second in the replay gives exactly
that: 25 at the start, going down, and 5 as soon as the machine appears. That is
what you want from a measurement: for it to confirm the reading or knock it down.

## The tools

| | |
|---|---|
| `tools/omsx_graba.tcl` | records the game into a replay |
| `tools/omsx_repasa.tcl` | walks the replay second by second and says what was there |
| `tools/omsx_mide.tcl` | the measurement: interrupt, phases and VDP |
| `tools/omsx_control_pc.tcl` | the independent control, by sampling the PC |

The recorder carries an `after quit { salva cierre }`: without it, everything
played since the last automatic save is lost when the window is closed. That was
learnt by losing a game.
