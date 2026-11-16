# NOT-IN-RECIPE — the hand steps that remain after the Hub City recipe

The recipe (`recipe.yaml`) deploys the complete Qbox base **and** clones
every Hub City resource, imports the Hub City tables, and appends the
Hub City block (permanent Discord link + all `ensure` lines) to
server.cfg. What follows is everything a txAdmin recipe **cannot** do —
kept as a short post-deploy checklist. Each item says why it's not in the
recipe and points at the pack's `INSTALL.md` section that covers it.
Work them in order; the whole list is well under an hour, and most of it
is one-time setup.

## 1. Paste the jobs into qbx_core — INSTALL "Step 2" + the NOOSE section
`jobs/qbx-jobs-snippet.lua` (in the pack) adds `bailbonds` and
`bountyhunter` **inside** the jobs table in
`resources/[qbx]/qbx_core/shared/jobs.lua`. The **NOOSE** job pastes
into the same file the same way, from its own snippet —
`hubcity-noose/jobs/noose-jobs-snippet.lua` adds `['noose']` (label
"Federal Task Force" — the department is undercover) alongside them.
**Why not in the recipe:** it's an insert into the middle of a table in a
file the recipe downloads from upstream. The recipe format's only text
tool is search-and-replace, and there is no unique, version-stable anchor
to hang an insert on — a `replace_string` here would be a fragile hack
that could corrupt the core's jobs file or silently fail on the next
qbx_core update. Two-minute manual paste instead.

## 2. Rename the police label to HCPD — INSTALL "Step 2b"
One line in the same `jobs.lua`: the `['police']` entry's label becomes
`'Hub City Police Department'` (the **key stays `police`**).
**Why not in the recipe:** same downloaded-file problem as #1. A
`replace_string` on the exact upstream label text was considered and
rejected: the string differs between qbx_core versions, and a
non-matching search risks an unpredictable deploy failure for the sake
of a ten-second edit.

## 3. Paste the Hub City items into ox_inventory — INSTALL tablet section, step 1 + the crafting section
`hubcity-tablet/items/hubcity_items.lua` (the tablet + vpn / burner
phone / forged ID) goes into `ox_inventory/data/items.lua` — and so
does `hubcity-crafting/items/hubcity_crafting_items.lua` (the three
backpacks + the `hubcity_fabric` / `hubcity_leather` materials), in
the same paste session.
**Why not in the recipe:** another insert into a downloaded file — and
this one the recipe itself **overwrites** from the upstream Qbox repo
(the stock recipe's `items.lua` move). Shipping a forked full-length
`items.lua` in our repo would work on day one and then silently drift
from every upstream item update after it. Rejected on purpose; the
manual paste stays current forever.

## 4. Rename the shops in shops.lua — "Home Ground" + "Quick Doors" + crafting materials — INSTALL "Store rebrand" + the crafting section
Three small edits, all in `ox_inventory/data/shops.lua`:
- The hardware shop's `name` becomes `'Home Ground'`.
- The **general stores'** `name` becomes `'Quick Doors'` (same rename,
  the convenience-store chain).
- Two lines added to the Home Ground shop's inventory so backpack
  crafting has its materials:
  `{ name = 'hubcity_fabric', price = 25 }` and
  `{ name = 'hubcity_leather', price = 40 }` — until this lands, the
  fabric/leather items exist but nothing sells them and no backpack
  can be crafted.
**Why not in the recipe:** edits inside the downloaded ox_inventory
release, whose exact entry text varies between ox_inventory versions.
Same reasoning as #2 — not worth a blind replace. A few minutes of
manual edits in one file.

## 5. Rename the HCPD station & jail blips — INSTALL "HCPD — station & jail blip names"
Mission Row blip → **Hub City Police Department**, Bolingbroke blip →
**HCPD Jail**, inside the police/prison resources' own configs.
**Why not in the recipe:** those blips belong to recipe resources
(`qbx_policejob` lineage / xt-prison), and INSTALL.md itself treats this
as a find-and-rename because file names and label strings vary between
versions. A recipe can't safely guess them.

## 6. Build the two npwd phone apps (Vibez + Tablet Mode) — INSTALL phone sections
`phone/npwd_vibez/` and `phone/npwd_tabletmode/` (in the pack) are
**scaffolds**: they must be dropped into npwd's app template and
**compiled** (Node build → `web/dist/`), then registered in
`npwd/config.json`'s apps list and ensured **before** npwd in
server.cfg.
**Why not in the recipe:** a recipe can only download, move and write
files — it cannot run a build toolchain. And the registration edits
depend on the built output existing. The F6 keybind flip and the
standalone tablet item work without these apps; the apps are the pretty
door, not a dependency. (The npwd "Driver not found" decision tree in
INSTALL is likewise a post-deploy check, not a recipe step.)

## 7. Register the Mission Row doors in game — INSTALL "HCPD headquarters"
The pack's `doorlock/hcpd-mission-row-doors.lua` is a **spec** (front
doors/lobby public; offices, cells, garage, roof HCPD-only; armory
grade 2+). Real doorlock entries need the **door model + exact
coordinates captured in game** with the doorlock admin flow — that's
how qbx_doorlock is designed to work, so no file a recipe ships can
contain them.
**IPL half is already covered:** the stock recipe ships `bob74_ipl`,
so the Mission Row interior loader is present — just run INSTALL's
three-step verification (civilian walks in, interior complete, staff
door locked without the job / opens with it).

## 8. Paste the applications Discord webhook — INSTALL applications section, step 2
Create the webhook in the Discord **#job-applications** channel and
paste its URL into `Config.DiscordWebhook` in
`hubcity-applications/config.lua`.
**Why not in the recipe:** a webhook URL is a **secret**. It must never
live in a recipe or a git repo. It ships empty on purpose; applications
save to the database even without it.

## 9. Verify every Hub City coordinate in game — INSTALL "RISKS"
Every location in the pack is a **first-pass estimate** (INSTALL.md says
so for each): the Raiderville tent-city anchor and lighting positions,
the applications desk, the 5 black-market dealer spots, the 4
laundering wash spots, the loans motor-pool point, the 4 bank points,
the Depot District blip in `hubcity-zones`, the drag strip pins in
`hubcity-dragrace` (start line, the two staging lanes and finish line
derived from it, and the timing-board point at Sandy Shores Airfield),
every street-race route in `hubcity-streetrace` (3 starts, all
checkpoints, and the NPC blocker points on each route), the 3 crafting
bench points in `hubcity-crafting` (Home Ground counter, Sandy Shores,
Depot District), and NOOSE's garage point + vehicle spawn and its 4
payphone CI drop points in `hubcity-noose`. Walk the city once,
nudge the numbers in each resource's `config.lua` (one-line fixes),
restart the resource. No recipe can do this — the numbers only become
true standing in the city.

## 10. Deploy-time inputs (not steps, just so they're expected)
txAdmin will still ask for the **license key**, the **MariaDB**
connection, and the **server name** when the recipe runs. That's the
deployer working as designed — credentials belong in that prompt,
never inside the recipe file.

---
*Companion files: `recipe.yaml` (what the recipe does) and the pack's
`INSTALL.md` (the full manual guide this list references). The bail
bonds gameplay loop remains a starter skeleton — see the pack's RISKS;
that's a build job, not an install step.*
