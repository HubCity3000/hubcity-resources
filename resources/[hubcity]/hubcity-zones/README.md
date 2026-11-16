# hubcity-zones — Vinewood becomes "The Depot District"

Part of the Hub City pack's Lubbock theming: Lubbock's entertainment
district is the **Depot District**, so GTA's entertainment district —
Vinewood — takes that name in Hub City Roleplay 5M.

## What it does

1. **Map blip (guaranteed):** a red blip named **"The Depot District"**
   on Vinewood Blvd. This half always works.
2. **Zone label override (⚠️ EXPERIMENTAL):** `client.lua` calls
   `AddTextEntry` for the Vinewood-family zone labels (`VINE`, `DTVINE`,
   `WVINE`, `EAST_V` — see `config.lua`), trying to rename the area name
   shown in the HUD's bottom-right corner when a player enters the area.
   Whether the zone display honours runtime label overrides is **not
   guaranteed** and differs by how the client resolves zone text. Test it
   in game: drive into Vinewood and read the area name. If it still says
   "Vinewood", the override didn't take on this build — the blip rename
   stands, and the full rename waits for the texture phase (the hillside
   **VINEWOOD sign letters** are a game texture either way, same later
   phase as the ULSA/TTU stadium signage and the HCPD building signs).

## Config

Everything is in `config.lua`: the district name, the blip (coords are a
**first-pass estimate** — verify in game and nudge, like every other Hub
City coordinate), and the list of zone labels to attempt.

## Install

Ships inside the Hub City recipe (cloned into `resources/[hubcity]/` and
ensured from server.cfg). Standalone: drop the folder into your resources
and add `ensure hubcity-zones` to server.cfg. Framework-free — no
dependencies.
