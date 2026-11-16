Config = {}

-- =====================================================================
--  Hub City NOOSE — undercover department + CI (informant) program
-- =====================================================================
--  NOOSE is the city's undercover federal task force: plainclothes
--  officers, unmarked cars, no blips, no marked units. Its public-
--  facing job label is deliberately bland ("Federal Task Force") —
--  see jobs/noose-jobs-snippet.lua and the README for the reasoning.
--
--  The CI program: NOOSE handlers recruit civilians as confidential
--  informants under codenames. A CI leaves tips at discreet payphone
--  drop points; handlers review the queue, approve a tip and pay the
--  CI's bank. Everything is checked SERVER-SIDE — the client only
--  decides what to *show*, and it only shows the garage to NOOSE
--  officers and the drop points to registered CIs. To everyone else,
--  none of this exists.
-- =====================================================================

Config.JobName = 'noose' -- internal Qbox job key (from the jobs snippet)

-- Grade levels come from the jobs snippet:
--   [0] Operative   [1] Handler   [2] Senior Handler   [3] Director
-- Each permission is the MINIMUM grade that clears it. Tune freely.
Config.Permissions = {
    Garage = 0,       -- take out / return NOOSE vehicles
    HandlerMenu = 1,  -- open the CI program menu at all
    RegisterCI = 1,   -- recruit a new informant
    ReviewTips = 1,   -- see the pending tip queue
    PayTips = 1,      -- approve + pay a tip (or reject it)
    DeactivateCI = 1, -- deactivate / reactivate an informant file
    SeeIdentity = 3,  -- see a CI's REAL name + citizen ID, and which
                      -- officer handles them. Director only. Everyone
                      -- below works with codenames only.
}

-- =====================================================================
--  Garage — where officers take out / return the unmarked fleet.
--
--  ⚠️ VERIFY IN GAME ON FIRST VISIT: this point is a first-pass
--  estimate at the multi-storey car park by Legion Square (a short
--  walk from Mission Row) — low-key on purpose, no signs, no blip.
--  Stand where the garage point should live, grab your coords, and
--  fix these two lines. `spawn` is where vehicles appear (w = heading).
-- =====================================================================
Config.Garage = {
    coords = vector3(224.5, -808.0, 30.6),
    radius = 2.5,
    spawn = vector4(205.0, -795.0, 30.6, 160.0),
    returnDistance = 30.0, -- how close a spawned vehicle must be to return it
}

-- The fleet: GTA's own NOOSE / unmarked stock models only.
--   riot    — the Police Riot, THE NOOSE vehicle in GTA lore
--   police4 — unmarked Stainer cruiser
--   fbi     — unmarked Buffalo
--   fbi2    — unmarked Granger
-- minGrade gates a model by job grade (the Riot is heavy kit, so it
-- starts at Handler — set it to 0 if every Operative should get one).
Config.Vehicles = {
    { model = 'police4', label = 'Unmarked Cruiser (Stainer)', minGrade = 0 },
    { model = 'fbi', label = 'Unmarked Buffalo', minGrade = 0 },
    { model = 'fbi2', label = 'Unmarked Granger', minGrade = 0 },
    { model = 'riot', label = 'Police Riot — NOOSE transport', minGrade = 1 },
}

-- =====================================================================
--  Drop points — where a registered CI leaves a tip.
--
--  ⚠️ ALL COORDS ARE ESTIMATES — payphone-style street spots picked
--  from the map, verify in game on first visit and adjust here
--  (one-line fixes). Deliberately ordinary places: a CI walks up,
--  "uses the phone", walks away. The target option only exists for
--  players the server confirms are active CIs.
-- =====================================================================
Config.DropPoints = {
    { label = 'Payphone — Downtown', coords = vector3(161.8, -955.5, 29.3) },
    { label = 'Payphone — Strawberry', coords = vector3(405.5, -1638.0, 29.3) },
    { label = 'Payphone — Depot District', coords = vector3(385.0, 245.0, 103.4) },
    { label = 'Payphone — Sandy Shores', coords = vector3(1935.0, 3725.0, 32.3) },
}

-- Tip payments (bank, to the CI). The handler enters the amount when
-- approving; it defaults to DefaultTip and can never exceed MaxTip.
-- FromHandlerBank = false: payments are issued as department funds
-- (created by the payment, logged on the tip row). Set it to true to
-- make the approving handler front the money from their own bank
-- instead — approval then fails if they can't cover it.
Config.Payments = {
    DefaultTip = 500,
    MaxTip = 5000,
    FromHandlerBank = false,
}

-- Field caps (the server enforces these; the form is only a suggestion).
Config.MaxTipLength = 1000
Config.MaxCodenameLength = 32

-- Auto-codenames, used when a handler registers a CI without picking
-- one: ADJECTIVE + NOUN + number, e.g. "VELVET FOX 42".
Config.CodenameWords = {
    adjectives = { 'VELVET', 'HOLLOW', 'QUIET', 'SCARLET', 'COBALT', 'AMBER', 'STATIC', 'LONELY', 'HIDDEN', 'PATIENT' },
    nouns = { 'FOX', 'CROW', 'VIPER', 'LANTERN', 'HARBOR', 'NEEDLE', 'FALCON', 'MIRROR', 'SPARROW', 'ANCHOR' },
}
