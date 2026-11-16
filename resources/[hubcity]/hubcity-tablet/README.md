# hubcity-tablet — the phone flips out: Black Market (deal-first) + Vibez + Need 2 Speed

**One device, two modes.** The tablet is the phone's big mode: the
player flips their phone out and the screen grows into this **wide
tablet NUI** with the extra apps the phone doesn't get.

## Ways in (three)
1. **Tablet Mode app in the phone** — the `phone/npwd_tabletmode`
   NPWD scaffold adds a "Tablet Mode" button to the phone; tapping it
   hands off to this resource (`flipFromPhone` NUI callback) and the
   wide UI opens full-screen. Scaffold-level handoff — see that
   folder's README and the pack's RISKS.
2. **Keybind / command** — **F6** or `/tablettoggle`
   (`Config.TabletToggleKey` / `Config.TabletToggleCommand`; players
   can rebind in GTA Settings → Key Bindings → FiveM). Works for any
   player carrying a phone (`Config.PhoneItem`). The guaranteed path —
   no npwd app needed.
3. **The standalone tablet item** — `hubcity_tablet` (ox_inventory)
   opens the same UI for players who buy a separate tablet. Kept as a
   second way in; not the main one anymore.

**Prop:** item and keybind opens put a tablet prop in the player's
hands. A phone flip does **not** — npwd owns the hand prop while the
phone is open, and stacking both props on one hand looks broken, so
only the screen grows. (Documented in the pack's RISKS.)

## Apps
- **Black Market** — deal-first, no walk-up buying (see below).
- **Vibez** — the real Vibez site (https://vibez-social-hub.base44.app)
  in the tablet frame. Same mirror rule as the phone app: one platform,
  two doors; no in-game copy of the feed.
- **Need 2 Speed** — street racing (see below).

## Need 2 Speed — street racing lives here, and only here
The **Need 2 Speed** app is the *only* door into street racing —
Daniel's explicit rule. The `hubcity-streetrace` resource has no
command, no keybind and no item; this tablet is the whole lobby.

Same pattern as the laundering panel: the tablet is just the screen.
All state — open lobbies, route list, live race membership, results,
and the per-route records (wins / best times) — lives in
**hubcity-streetrace's server**; this resource's client bridges the
NUI to its callbacks (`getStreetRaceData`, `srCreateRace`,
`srJoinRace`, `srLeaveRace`, `srStartRace`, `srCancelRace`), and a
`lobbiesChanged` broadcast refreshes the app live while it's open.
If hubcity-streetrace isn't running, the app shows empty lists instead
of breaking. The racing itself — grid, countdown, checkpoints, the
NPC blocker crew — is all in hubcity-streetrace; see its README.

## Black Market — DEAL-FIRST flow
1. In the app, the player builds an order from `Config.Catalog` and
   submits a **deal request**.
2. The server rolls `Config.DealAgreeChance` (0.8), checks stock at the
   assigned dealer, prices the deal (±`Config.PriceVariancePercent`),
   and on agreement stores the deal in the **`hubcity_deals`** table
   (survives restarts): items, total, assigned location = the currently
   active dealer spot, expiry = `Config.DealWindowMinutes` (45).
   One active deal per player.
3. The app confirms items, total, neighborhood, and the time window.
4. At the spot, the dealer ped's ox_target offers **"Complete the
   deal"** only to a player holding an agreed deal for that spot:
   cash is taken, items handed over, deal closes. Everyone else gets
   the brush-off: *"Deals go through the app. I don't know you."*
5. Expired deals are swept by the server (stock is released); the
   player can submit a new request.

**Dealers:** 5 spots in `Config.Dealers` (Cypress Flats, Strawberry,
La Mesa, Elysian Island, Del Perro). ONE is active, rotating every
`Config.RotationMinutes` (180) — or all of them with
`Config.AllDealersActive`. The app shows only the active neighborhood's
name. No blips. **All 5 coords are estimates — verify in game.**

**Catalog:** tools/contraband only by default — lockpick,
advancedlockpick (stock ox items) + custom stubs `hubcity_vpn`,
`hubcity_burnerphone`, `hubcity_fakeid` (definitions in
`items/hubcity_items.lua`; they are flavor items with no consuming
system yet). **No complete firearms in v1 — Daniel's call, editable in
config.**

**Laundering section:** the Black Market app also advertises the
currently active money-laundering wash spot (neighborhood + fee) —
that data comes from the separate **hubcity-laundering** resource's
export; laundering itself does not happen in the tablet.

## Files
- `web/` — the tablet NUI (functional v1, not polished).
- `items/hubcity_items.lua` — paste into `ox_inventory/data/items.lua`.
- `sql/hubcity_deals.sql` — the server also auto-creates the table.
