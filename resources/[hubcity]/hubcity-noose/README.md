# hubcity-noose — undercover department + CI program

**NOOSE** is Hub City's undercover federal task force: plainclothes
officers, unmarked cars, no blips, no marked units — plus a
**confidential informant (CI) program** that lets NOOSE handlers run
civilian informants under codenames.

## The department

- **Job:** `noose` — defined in `jobs/noose-jobs-snippet.lua` (paste it
  into `qbx_core/shared/jobs.lua` with the pack's other jobs; hire with
  `/setjob <id> noose <grade>`).
- **The label choice:** the job's public-facing label is deliberately
  **"Federal Task Force"**, not "NOOSE". The label is what shows in job
  menus, the phone, and paychecks — a screaming "NOOSE" label would
  blow the cover the department exists to keep. "NOOSE" stays internal:
  the job key, the vehicle plates, and this folder.
- **Grades:** Operative (0) → Handler (1) → Senior Handler (2) →
  Director (3, boss grade with `isboss` + `bankAuth`, same as the
  pack's other boss grades). Who can do what is set per-permission in
  `Config.Permissions`.
- **Vehicles:** one discreet garage point (`Config.Garage`) where
  officers sign out GTA's own NOOSE/unmarked stock: `riot` (the Police
  Riot — *the* NOOSE vehicle), `police4` (unmarked Stainer), `fbi`
  (unmarked Buffalo), `fbi2` (unmarked Granger). Plates read
  `NOOSE###`. Vehicles are temporary spawns — not owned, not stored,
  not persistent — and are returned/deleted at the same point. Taking
  out a new one deletes the one you had.

## The CI program — how it flows

1. **Recruit:** a Handler+ stands with the civilian and opens
   **CI program** at the garage point → *Register an informant* → pick
   the nearby person (or enter a citizen ID) → assign a codename, or
   leave it blank and one is auto-generated ("VELVET FOX 42").
2. **Tip:** the CI walks up to any payphone drop point
   (`Config.DropPoints`) and uses the **"Use the phone"** target —
   which only exists for them — and leaves a tip. It lands in
   `hubcity_ci_tips` as `pending`, filed under the codename.
3. **Review:** handlers open the same garage menu → *Tips awaiting
   review* → read the tip → **Approve and pay** (amount defaults to
   `Config.Payments.DefaultTip`, capped at `MaxTip`) or **Reject**.
4. **Payment:** paid to the CI's **bank**. Online CIs get it instantly
   with a quiet "bank deposit" notification that says nothing about
   NOOSE. Offline CIs get it the next time they check in — the money
   trail (amount, handler, when, delivered or not) lives on the tip
   row. By default payments are department funds; set
   `Config.Payments.FromHandlerBank = true` to make the approving
   handler front the money from their own bank instead.
5. **Deactivate:** handlers can deactivate/reactivate a file at any
   time. Files are **never deleted** — the record and its tip history
   stay in `hubcity_ci` for audit.

## Secrecy rules (enforced server-side, not by hiding UI)

- Every callback re-checks the caller's **job and grade on the
  server**. A tampered client showing itself the menu gets nothing.
- **Identities are Director-only.** The handler data call only includes
  a CI's real name/citizen ID — and which officer handles them — when
  the caller is grade 3 (`Config.Permissions.SeeIdentity`). Everyone
  below, including the CI's own handler, works with codenames only.
- A CI's own status call returns **only their own codename**. CIs
  never see other CIs, the tip queue, or the file list.
- **Non-members see nothing at all:** the garage target zone is only
  created for NOOSE players and the drop-point zones only for active
  CIs. There are no blips anywhere in this resource.
- Tip submission is **distance-checked on the server** — the CI has
  to actually be standing at the payphone.
- A NOOSE officer can't be registered as a CI, and nobody can hold
  two active files.

## Honest limits / wiring notes

- **All coordinates are first-pass estimates** (garage point, spawn
  point, all four drop points) — verify in game and fix in
  `config.lua`, like every other Hub City resource.
- **Vehicle keys are not wired.** Vehicles spawn with the officer
  warped in and the engine on. If the server's vehicle-keys setup
  still locks them, wire your keys resource's give-keys call into
  `spawnVehicle` in `client/main.lua` — that's the one marked spot.
- **Vehicle spawn authorization is server-checked, the spawn itself
  is a client native** — the same pattern as the rest of the pack.
  This gates the legitimate flow; it is not an anti-cheat.
- **No Discord webhook, on purpose.** A webhook announcing tips or
  identities would defeat the secrecy model. Payments and file
  changes are logged to the server console and the database instead.
- Tables are in `sql/hubcity_noose.sql`; the resource also creates
  them itself on start if missing.

## Dependencies

`qbx_core`, `ox_lib`, `ox_target`, `oxmysql` — all standard in the
Qbox recipe. Ensure it **after** them (see the pack's INSTALL.md).
