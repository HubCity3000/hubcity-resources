# hubcity-streetrace — "Need 2 Speed" (street racing, tablet-only)

Fast & Furious style street racing for Hub City, organized **only**
through the **Need 2 Speed** app in the tablet — the phone's tablet
mode. There is deliberately **no command, no keybind and no item** for
this resource. If the tablet is closed, street racing does not exist.
(That was Daniel's explicit call.)

## How a race goes
1. **Create** — in the Need 2 Speed app, a host picks one of the preset
   routes and opens a lobby.
2. **Join** — other racers see the lobby in the app and join. The host
   can start once the lobby meets `Config.MinRacers` (default 1, so a
   solo driver can run the clock — raise it for head-to-head only).
3. **Grid** — starting puts the start line on every racer's GPS. Racers
   drive there and roll into the grid circle in a vehicle; anyone who
   doesn't make it within `Config.GridTimeoutSeconds` is dropped.
4. **Countdown** — when the whole field is gridded, cars are frozen for
   a 3-2-1-GO countdown. As the countdown starts, **the blocker crew
   rolls out** (see below).
5. **Race** — checkpoint race: a glowing marker and GPS waypoint for
   the next checkpoint, checkpoints strictly in order, the last one is
   the finish. A HUD shows your live position and checkpoint count,
   fed by standings the server recalculates every 2 seconds from
   racers' progress reports.
6. **Results** — finishing order and times pop up for every racer when
   the field is done (or the race timer runs out — unfinished racers
   are DNF). Every result lands in `hubcity_streetrace_records`, and
   the app's **Records** screen shows wins and best times per route.
   The app also keeps your last race's results.

**No wagering.** Nothing in here moves money — bragging rights only.

## The blocker crew (the signature piece)
When the countdown starts, the server broadcasts the route's blocker
points to every client. Each client spawns the blockers near itself:
NPC cars (`Config.BlockerVehicles`) with drivers
(`Config.BlockerPeds`), parked across the side streets and
intersections listed in the route's `blockers` table — the organizers'
roadblock crew, sealing the course while the race runs. They despawn
when the race ends. While you race, your client also thins ambient
traffic around you (`Config.TrafficDensity` etc.).

**Honest limits — read before promising anyone anything:**
- Blockers are **scripted set dressing at pre-chosen intersections**
  from each route's config. They do not think, react, chase, or seal
  any street that isn't listed. A route's coverage is exactly as good
  as its `blockers` list, and every point is a first-pass estimate.
- Blockers are **frozen and invincible** so a love tap can't shove the
  roadblock open. That's deliberate — they're scenery with drivers.
- Ambient traffic is only *reduced near racers*, on their own clients.
  The rest of the city's AI does whatever it wants. This is not
  city-wide traffic control and can't be — FiveM doesn't offer that.
- Checkpoint hits are detected on each racer's client and reported to
  the server; finish times are stamped server-side when the report
  lands. Fine for friendly racing; it is not an anti-cheat system.

## Routes (all coordinates UNVERIFIED — verify in game)
3 presets in `config.lua`, every coordinate a first-pass map estimate
in the pack's usual style — drive them and fix the lines:
- **Depot District Dash** — a loop of the Depot District (Vinewood):
  Vinewood Blvd west, down to Sunset, back up to the start.
- **Downtown Sprint** — a loop of the downtown grid from Legion
  Square, through Mission Row and Pillbox Hill.
- **Senora Freeway Run** — point to point, Grapeseed to the city on
  the Senora / Los Santos freeways. Expect its z-heights to need the
  most correction.

## Files
- `config.lua` — rules (lobby/grid/race timeouts, radii, densities)
  and the 3 routes with checkpoints + blocker points.
- `server/main.lua` — lobbies, state machine, standings, records.
  Also auto-creates the records table on start.
- `client/main.lua` — grid/countdown/checkpoint HUD, traffic density,
  blocker spawning.
- `sql/hubcity_streetrace_records.sql` — the records table (optional
  import; the server creates it automatically too).

## Depends on
qbx_core, ox_lib, oxmysql — and hubcity-tablet, whose app grid carries
the Need 2 Speed tile. Ensure this resource **after** hubcity-tablet.
