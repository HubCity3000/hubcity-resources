# hubcity-crafting — Craft Your Own Backpack

Players asked to make their own bags, so here it is: walk up to a
**crafting bench**, pick a backpack, and stitch it together from raw
materials. Three tiers, all real **ox_inventory containers** — open a
finished bag and it has its own slots and weight limit inside.

## How it plays

1. Go to a bench (below) and target it: **Use Crafting Bench**.
2. The menu lists every recipe with the materials it needs **and how
   many you actually have** — those counts are read by the server, so
   what you see is what's true. Recipes you can't afford are greyed out.
3. Pick one → progress bar (8–25 s by tier) → materials are consumed and
   the finished bag lands in your inventory. The menu reopens so you can
   chain another craft.
4. Use the bag from your inventory to open it, like any container.

## The recipes

| Product | Capacity | Materials | Time |
|---|---|---|---|
| Small Backpack | 10 slots / 15 kg | 4× Fabric, 2× Plastic, 1× Aluminium | 8 s |
| Large Backpack | 18 slots / 30 kg | 8× Fabric, 4× Plastic, 3× Aluminium, 2× Leather | 15 s |
| Duffel Bag | 24 slots / 45 kg | 10× Fabric, 5× Leather, 5× Plastic, 2× Steel, 2× Rubber | 25 s |

Everything is in `config.lua` (`Config.Recipes`) — add a recipe by
copying a block. Capacity lives there too, in each recipe's `container`
field.

## Materials — what exists and what's new

Checked against the items.lua the Qbox recipe actually installs:

- **Already in the city:** `plastic`, `aluminum`, `steel`, `rubber`
  (plus iron, copper, glass, metalscrap). The recipes lean on these.
- **Added by this resource's snippet:** `hubcity_fabric` (Fabric) and
  `hubcity_leather` (Leather) — the stock items.lua has no cloth or
  leather at all, and a backpack needs both.

⚠️ **Getting materials into players' hands is a separate tap to turn
on.** The stock materials circulate through the city's existing
economy; Fabric and Leather are brand new, so until something sells or
drops them, nobody can craft. The 30-second fix at install time: add
these two lines to the **Home Ground** shop inventory in
`ox_inventory/data/shops.lua` (next to the lockpick line), priced how
you like:

```lua
{ name = 'hubcity_fabric',  price = 25 },
{ name = 'hubcity_leather', price = 40 },
```

## Benches

| Bench | Coords (first-pass) |
|---|---|
| Home Ground — Workbench (La Mesa hardware store) | (2745.5, 3470.5, 55.67) |
| Sandy Shores Workshop (Panorama Dr repair shop) | (1177.0, 2641.0, 37.9) |
| Depot District Workshop (off Vinewood Blvd) | (438.5, 168.0, 103.2) |

## ⚠️ Coordinates — VERIFY IN GAME

All three bench positions are **first-pass estimates**, flagged like
every other Hub City coordinate. The Home Ground bench is grounded in
the real shop layout (a couple of metres from the hardware counter
target at 2746.8, 3473.13, 55.67); the other two are plausible spots
that have never been stood on. First visit: stand where the bench
should be, grab coords, fix the one line in `config.lua`.

## Server-side honesty

- The craft is a **begin/finish pair**: the server stamps the start,
  and the finish is rejected if the progress bar didn't really run
  (`Config.ProgressTolerance` covers timing jitter only).
- Bench proximity is checked on the server at **both** ends — you can't
  start at a bench and finish across the map.
- Materials are **re-counted at the finish line**, not trusted from the
  menu; capacity is checked before anything is consumed; and if the
  hand-over somehow fails after materials are taken, **everything is
  refunded** — a failed craft never eats materials.
- Container capacities are stamped into a bag's metadata **when the bag
  is created**. Retuning `container` in config changes future bags only;
  bags already in the city keep the size they were born with.
- The resource registers its containers when it starts (it waits for
  ox_inventory). If ox_inventory is restarted on its own, restart
  hubcity-crafting too so the registration is fresh.
