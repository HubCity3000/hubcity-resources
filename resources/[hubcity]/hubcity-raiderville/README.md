# Raiderville Stadium — Texas Tech at ULSA

**Hub City Roleplay 5M** · Hub City is Lubbock, Texas — so the university
stadium in Richman (ULSA's track-and-field complex, approx. -1660, 185, 62)
**is Texas Tech University**, and its stadium is **Raiderville Stadium**.

> **Moved (Nov 2026):** this pack used to dress Maze Bank Arena. Per Daniel's
> Lubbock direction it now lives at ULSA. Nothing in this pack touches Maze
> Bank Arena anymore — what the arena becomes is Daniel's call, still pending.

## What it does

- **Map blip** named **"Raiderville Stadium"** (stadium icon, scarlet red)
  on the ULSA stadium, visible city-wide.
- **Tent city tailgate camp** in the stadium lots, honouring the real
  Raiderville tradition — Texas Tech students camp out in rows of tents
  before big games:
  - Two facing rows of camping tents (12 total)
  - Feather/banner flags down the middle walkway
  - Flag poles at the camp entrance and the stadium plaza
  - Event barriers lining the lot, queue barriers and cones at the entrance
  - Tailgate dressing: folding-chair and keg clusters by the tents
- Props are **client-side and proximity-based**: they spawn when a player
  comes within 300 m and despawn beyond 320 m, and everything is cleaned up
  if the resource stops. Models that fail to load are skipped silently, so a
  bad prop name can never break the resource.
- **Texas Tech palette — red / black / white** across everything the
  resource controls: the red blip; **subtle red lot lighting at night**
  (scripted lights, `Config.Lighting`) so the stadium reads on-theme after
  dark even on quiet days; on game days, brighter **red accent lighting**,
  red/black/white parked cars, fan peds dressed red/black, and the
  🔴⚫⚪ announcement. Vanilla prop models mostly can't be recoloured by
  script, so the palette is carried by light, cars, fans, flags and the
  blip — not repainted tents (see Honest limits).

## 🏈 Game Day mode

Every **other real-world day** is a Texas Tech game day (alternating days,
counted from an anchor date the server remembers across restarts — see
`server_gameday.lua`). On game days:

- A **busy layer** appears around the tent city: grills, coolers and picnic
  tables, extra flags, **parked cars** filling the lots (red/black/white),
  and **ambient fan peds** standing, cheering and drinking.
- The map blip becomes **"Raiderville Stadium — GAME DAY"** and flashes.
- The server broadcasts: *"🏈 It's GAME DAY at Raiderville Stadium — Texas
  Tech fans are taking over the lots!"* when the day starts (and tells each
  player who joins on a game day).

On off days the layer is gone — base dressing only, stadium quiet.

Force it for testing from the **txAdmin console**:

```
raiderville gameday on      force a game day
raiderville gameday off     force a quiet day
raiderville gameday auto    back to the every-other-day schedule
raiderville gameday status  show anchor / today / current state
```

Schedule settings live in `config.lua` under `Config.GameDay` (enable/disable,
anchor date override). Day flips happen at **local midnight on the server
PC** — keep the PC clock on Central time.

## Install

Already in `resources/[hubcity]/hubcity-raiderville/`. Add to server.cfg:

```
ensure hubcity-raiderville
```

No dependencies, no framework required (works alongside Qbox).

## Tuning

Everything lives in `config.lua`: blip, spawn distances, the base prop list,
and the whole Game Day layer (props / cars / peds). Z heights are
approximate — the client snaps props to the ground when they spawn.

## Honest limits — read this

- **Coordinates are unverified.** The stadium position comes from published
  map data for the ULSA campus; the tent-city layout kept its old shape and
  was moved as one block into the stadium lots. **Check it in game on the
  first visit** — if the camp sits off the lot, shift `Config.TentCityAnchor`
  and the prop coordinates together (same for the Game Day cars/peds).
- **The stadium still says ULSA.** This pack renames the place on the map
  and dresses the lots — it does **not** change the physical in-game signage
  on the 3D stadium buildings. Re-texturing the actual ULSA signs is a
  separate, later phase (custom streamed textures), deliberately out of
  scope here.
- **No stadium MLO is included.** The vanilla ULSA track-and-field complex
  is the stadium underneath. A true Jones AT&T Stadium replica would be a
  paid custom MLO; if one is ever bought or built, it drops in at this same
  spot and this pack's blip + camps will sit around it unchanged.
- Game Day extras (grill/cooler models, fan outfits, car/ped placement) are
  best-effort first passes — see the RISKS section of the pack's INSTALL.md.
