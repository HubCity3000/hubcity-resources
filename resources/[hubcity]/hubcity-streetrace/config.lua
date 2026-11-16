Config = {}

-- ============================================================================
-- HUB CITY STREET RACING
-- ============================================================================
-- Organized ONLY through the "Need 2 Speed" app inside the tablet (the
-- phone's tablet mode — see hubcity-tablet). There is deliberately NO
-- command, NO keybind and NO item for this resource: if the tablet is
-- closed, street racing does not exist. Daniel was explicit about that.

-- ── Race rules ─────────────────────────────────────────────────────────────

-- Minimum racers in the lobby before the host can start. Default 1 so a
-- solo driver can still run a route against the clock (and so the whole
-- thing can be tested alone). Raise it to 2+ for real head-to-head only.
Config.MinRacers = 1

-- Maximum racers per race.
Config.MaxRacers = 8

-- A lobby that never starts is cancelled after this many minutes.
Config.LobbyTimeoutMinutes = 10

-- After the host starts, racers have this long to reach the start line
-- and grid up. Anyone not on the grid when it runs out is dropped; if
-- nobody is on the grid the race is cancelled.
Config.GridTimeoutSeconds = 180

-- Countdown length (the classic 3-2-1-GO).
Config.CountdownSeconds = 3

-- A race that runs longer than this is ended; unfinished racers are DNF.
Config.RaceTimeoutMinutes = 15

-- How close to the start point (meters, in a vehicle) counts as gridded.
Config.GridRadius = 20.0

-- How close to a checkpoint (meters, in a vehicle) counts as hitting it.
Config.CheckpointRadius = 15.0

-- ── Traffic ────────────────────────────────────────────────────────────────
-- While YOU are in a race, your client thins ambient traffic around you
-- (multipliers 0.0–1.0, 1.0 = normal city traffic). This is a local
-- density effect for racers only — it does not control the city's AI.

Config.TrafficDensity = 0.25
Config.ParkedDensity = 0.4
Config.PedDensity = 0.5

-- ── The blocker crew ───────────────────────────────────────────────────────
-- When a race starts, the organizers' crew rolls out: NPC cars with
-- drivers park ACROSS the side streets and intersections listed in each
-- route's `blockers` table, sealing the course Fast & Furious style.
-- They stay for the whole race and leave when it ends.
--
-- HONEST LIMITS (also in the README): the blockers are scripted cars at
-- the pre-chosen points in each route's config — nothing more. They do
-- not react to traffic, they do not chase anyone, and they cannot seal
-- streets that are not listed. Ambient traffic elsewhere in the city
-- keeps doing its own thing (thinned near racers by the multipliers
-- above). Blockers are frozen and invincible so a tap can't shove the
-- roadblock open — they are scenery with drivers, on purpose.

-- Cars the crew drives (random pick per blocker point).
Config.BlockerVehicles = { 'dominator', 'gauntlet', 'elegy2', 'sultan', 'buffalo' }

-- Drivers the crew is made of (random pick per blocker point).
Config.BlockerPeds = { 'a_m_y_hipster_01', 'a_f_y_hipster_01', 'a_m_y_beach_01', 'a_f_y_beach_01' }

-- Blockers appear when a player gets within this distance (meters) and
-- are removed beyond the despawn distance. Keeps entity counts sane.
Config.BlockerSpawnDistance = 350.0
Config.BlockerDespawnDistance = 450.0

-- ============================================================================
-- ROUTES
-- ============================================================================
-- 3 preset routes. `start` is vector4 (x, y, z, heading) — the grid.
-- `checkpoints` are raced IN ORDER; the LAST checkpoint is the finish.
-- `blockers` are the crew's roadblock points along the route.
--
-- ⚠️ EVERY coordinate in this file is a first-pass estimate picked from
-- the map and is UNVERIFIED. Drive each route in game, stand where each
-- point should be, grab your coords, and fix the lines here. Expect the
-- freeway route's heights (z) to need the most correction.

Config.Routes = {
    {
        id = 'depot_district_dash',
        name = 'Depot District Dash',
        description = 'A night loop of the Depot District (Vinewood): west down Vinewood Blvd, drop to Sunset, and climb back to the start. Tight, lit, and loud.',
        start = vector4(352.0, 190.0, 103.1, 270.0),
        checkpoints = {
            vector3(120.0, 178.0, 103.4),
            vector3(-160.0, 195.0, 71.5),
            vector3(-480.0, 205.0, 56.5),
            vector3(-690.0, 150.0, 52.0),
            vector3(-620.0, -120.0, 38.0),
            vector3(-300.0, -105.0, 30.5),
            vector3(40.0, 30.0, 83.0),
            vector3(345.0, 185.0, 103.1), -- finish, back at the start
        },
        blockers = {
            { coords = vector3(250.0, 214.0, 103.2), heading = 180.0 },
            { coords = vector3(-40.0, 218.0, 78.0), heading = 170.0 },
            { coords = vector3(-420.0, 232.0, 58.0), heading = 190.0 },
            { coords = vector3(-705.0, 60.0, 51.0), heading = 90.0 },
            { coords = vector3(-470.0, -140.0, 33.0), heading = 0.0 },
            { coords = vector3(150.0, -120.0, 45.0), heading = 10.0 },
        },
    },
    {
        id = 'downtown_sprint',
        name = 'Downtown Sprint',
        description = 'A hard loop through the downtown grid: Legion Square, Mission Row, Pillbox Hill, and back. All corners, no straights to hide in.',
        start = vector4(215.0, -925.0, 30.7, 160.0),
        checkpoints = {
            vector3(165.0, -1048.0, 29.2),
            vector3(-35.0, -1075.0, 27.5),
            vector3(-255.0, -960.0, 31.2),
            vector3(-245.0, -725.0, 32.3),
            vector3(15.0, -665.0, 41.5),
            vector3(255.0, -775.0, 36.9),
            vector3(218.0, -918.0, 30.7), -- finish, back at Legion Square
        },
        blockers = {
            { coords = vector3(95.0, -1000.0, 29.0), heading = 90.0 },
            { coords = vector3(-160.0, -1020.0, 28.0), heading = 80.0 },
            { coords = vector3(-320.0, -840.0, 31.0), heading = 0.0 },
            { coords = vector3(-120.0, -760.0, 33.0), heading = 90.0 },
            { coords = vector3(140.0, -700.0, 39.0), heading = 85.0 },
            { coords = vector3(300.0, -860.0, 33.0), heading = 175.0 },
        },
    },
    {
        id = 'senora_freeway_run',
        name = 'Senora Freeway Run',
        description = 'Point to point: Grapeseed to the city on the Senora and Los Santos freeways. The long one — top speed wins, if you can hold it.',
        start = vector4(2445.0, 3835.0, 34.8, 185.0),
        checkpoints = {
            vector3(2490.0, 3280.0, 43.5),
            vector3(2315.0, 2570.0, 57.0),
            vector3(1905.0, 1885.0, 93.0),
            vector3(1470.0, 1080.0, 57.0),
            vector3(1160.0, 340.0, 49.0),
            vector3(1005.0, -320.0, 39.5), -- finish, south end of the freeway
        },
        blockers = {
            { coords = vector3(2520.0, 3560.0, 40.0), heading = 95.0 },
            { coords = vector3(2140.0, 2210.0, 75.0), heading = 100.0 },
            { coords = vector3(1660.0, 1460.0, 62.0), heading = 95.0 },
            { coords = vector3(1090.0, -30.0, 45.0), heading = 90.0 },
            { coords = vector3(985.0, -300.0, 39.0), heading = 90.0 },
        },
    },
}
