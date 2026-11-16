# hubcity-dragrace — Sandy Shores Drag Strip

Drag racing at the **Sandy Shores Airfield** (McKenzie Field) runway,
in the Hub City pack's style: stage up, watch the lights, run the
quarter, and see your name on the timing board.

## How a race plays

1. Drive onto the runway's west end and roll into a **staging box** —
   two lanes side by side on the start line. An on-screen prompt
   offers **[E] to stage**. Your car is held in place (engine on —
   rev all you want) and you're staged.
2. **Head-to-head:** when the other lane stages, the countdown starts
   after a beat. **Solo:** if nobody joins within
   `Config.SoloWaitSeconds` (10), you get the lights alone for a timed
   pass. Press **E** before the lights to back out.
3. **Countdown:** big **3 - 2 - 1** on screen with beeps, then **GO!**
   and the hold releases. Move off your spot before GO (more than
   `Config.FalseStartDistance`, 1.5 m) — or climb out of the car —
   and it's a **red light**: run void, no time recorded. Your opponent
   still runs.
4. **Finish:** cross the finish line (a green marker while you race)
   and your **elapsed time** and **trap speed** are recorded. Both
   racers get the results card: both passes, and the **winner**
   (fastest clean run; a red light can never win).
5. **Timing board:** a walk-up point by the start line ("View timing
   board") shows the **top 10 passes ever** plus **your personal
   best**, straight from the `hubcity_drag_times` table.

**No wagering.** Daniel didn't ask for betting, so there is none —
it's racing for times and bragging rights.

## Distance

Quarter mile (**402.336 m**) by default (`Config.DistancePreset`).
The quarter uses most of the runway, so the shutdown area past the
finish is short — if it feels too short in game, set the preset to
`'eighth'` (201.168 m) in `config.lua`; the finish line, markers and
detection all move automatically.

## ⚠️ Coordinates — VERIFY IN GAME

Every position is a **first-pass estimate**, flagged like every other
Hub City coordinate:

- `Config.StartLine` (1540.0, 3278.0, 41.5) — centre of the start
  line, derived from the runway centre (≈ 1743, 3278, 41).
- `Config.Direction` (1.0, 0.0) — racing due **east** down the runway.
- Lanes sit ±3.2 m either side of the start line; staging points are
  (1540.0, 3281.2, 41.5) and (1540.0, 3274.8, 41.5); the quarter-mile
  finish points are (1942.3, 3281.2, 41.5) and (1942.3, 3274.8, 41.5).
- `Config.Board.coords` (1532.0, 3266.0, 41.5) — the timing board
  point, south of the start line.

First visit: check the staging markers sit **on the pavement, side by
side, facing down the runway**. If they're off or angled wrong, nudge
`Config.StartLine` / `Config.Direction` — everything else is derived
from those two values, so two lines fix the whole strip.

## Honest limits

- **Times are client-measured** (each driver's clock starts on their
  own GO), with a server-side plausibility floor
  (`Config.MinPlausibleTimeMs`) before anything is written. That's
  fine for roleplay bragging rights; it is **not** tournament-grade
  anti-cheat.
- The two clients' countdowns can differ by a few tens of milliseconds
  (network timing). Nobody wins a Hub City drag race by 30 ms and
  lives it down anyway.
- Countdown beeps use the standard GTA race HUD sounds; if a sound
  name differs on this build they simply don't play — the numbers and
  GO! text are the real signal.
- The vehicle hold is a position freeze. It can't be overpowered, so
  a false start in practice means the car got moved (bumped) or the
  driver climbed out — both are red lights by design.

## Install

Ships in the Hub City pack (copy `[hubcity]` into resources, add
`ensure hubcity-dragrace` — see the pack's INSTALL.md) and in the
Hub City recipe (cloned + SQL imported automatically). The
`hubcity_drag_times` table is also created by the resource itself on
first start; `sql/hubcity_drag_times.sql` is there if you prefer
importing in HeidiSQL first.
