Config = {}

-- Raiderville Stadium — Texas Tech University, Hub City (Lubbock) style.
-- The site is the ULSA campus stadium / track-and-field complex in Richman,
-- which in Hub City Roleplay IS Texas Tech University. The blip sits on the
-- stadium; the "tent city" tailgate camp dresses the stadium lots just
-- south-west of the track — Raiderville is the real Texas Tech tradition of
-- students camping out before big games.
--
-- ⚠️ COORDINATES — VERIFY IN GAME ON FIRST VISIT:
-- These positions were placed from the published map position of the ULSA
-- campus (approx. -1636, 181 in Richman, ground level ~62) with the tent-city
-- layout carried over, same shape, from the old Maze Bank Arena build. They
-- have NOT been eyeballed in game yet. If the camp sits off the lot (on a
-- road, a slope, or inside a fence), shift TentCityAnchor and the prop block
-- together, or rotate the headings — then update this file.
Config.StadiumName = 'Raiderville Stadium'
Config.Center = vector3(-1660.0, 185.0, 62.0) -- ULSA stadium / track complex, Richman

Config.Blip = {
    coords = vector3(-1660.0, 185.0, 62.0),
    sprite = 135,   -- stadium blip
    colour = 1,     -- red (scarlet, for the Red Raiders)
    scale = 1.0,
    shortRange = false
}

-- Props spawn when any player comes within SpawnDistance of the tent city
-- anchor, and are removed once everyone is beyond DespawnDistance.
Config.SpawnDistance = 300.0
Config.DespawnDistance = 320.0
Config.TentCityAnchor = vector3(-1705.0, 130.0, 62.0)

-- ── Texas Tech palette: RED / BLACK / WHITE ─────────────────────────────
-- Carried by: the red map blip (above), game-day cars (red/black/white),
-- fan peds dressed red/black with white accents where the model's
-- wardrobe allows, the flags/banners, and the scripted LIGHTING below.
-- Honest limit: most vanilla prop models cannot be recoloured by script,
-- so where a prop choice existed, red/white-friendly models were picked
-- (flags, banner flags, barriers) — the palette lives in the light, the
-- cars, the fans and the blip, not in repainted tents.
Config.Lighting = {
    Enabled = true,
    -- Subtle red lot lighting on ALL nights (the base layer), so the
    -- stadium reads on-theme after dark without going full game-day.
    NightOnly = true,
    NightStart = 19, -- game-clock hours
    NightEnd = 6,
    Color = { r = 205, g = 25, b = 30 },
    Range = 16.0,
    Intensity = 1.2, -- subtle on purpose
    Points = { -- above the tent city + lot rows (verify in game at night)
        vector3(-1705.0, 105.0, 66.0),
        vector3(-1730.0, 130.0, 66.0),
        vector3(-1680.0, 130.0, 66.0),
        vector3(-1705.0, 158.0, 66.0),
    },
}

-- Prop models used (all vanilla GTA V):
--   prop_skid_tent_01 / _01b / _03  small camping tents (verified in prop lists)
--   prop_tent_01                    larger camping tent (optional: skipped if it fails to load)
--   prop_flagpole_1a / _2a          flag poles at the entrances
--   prop_beachflag_le               feather/banner flags between the tents
--   prop_barrier_work05             construction/event barriers (row along the lot edge)
--   prop_barrier_work01c            low work barrier
--   prop_mp_barrier_01              queue barriers at the tent-city entrance
--   prop_mp_cone_02                 traffic cones
--   prop_chair_01a                  folding chairs (tailgate clusters)
--   prop_keg_01                     kegs (tailgate dressing)
--
-- Every entry: model, x, y, z (z is a rough ground height - the client
-- snaps each prop to the ground on spawn), heading.
Config.Props = {
    -- ===== Tent city: two facing rows of tents (the Raiderville camp-out) =====
    -- Row A (west side, tents face east / heading 90)
    { model = 'prop_skid_tent_01',  x = -1725.0, y = 113.0, z = 62.0, h = 90.0 },
    { model = 'prop_skid_tent_03',  x = -1725.0, y = 121.0, z = 62.0, h = 90.0 },
    { model = 'prop_skid_tent_01b', x = -1725.0, y = 129.0, z = 62.0, h = 90.0 },
    { model = 'prop_tent_01',       x = -1725.0, y = 137.0, z = 62.0, h = 90.0 },
    { model = 'prop_skid_tent_01',  x = -1725.0, y = 145.0, z = 62.0, h = 90.0 },
    { model = 'prop_skid_tent_03',  x = -1725.0, y = 153.0, z = 62.0, h = 90.0 },
    -- Row B (east side, tents face west / heading 270)
    { model = 'prop_skid_tent_03',  x = -1685.0, y = 113.0, z = 62.0, h = 270.0 },
    { model = 'prop_skid_tent_01b', x = -1685.0, y = 121.0, z = 62.0, h = 270.0 },
    { model = 'prop_skid_tent_01',  x = -1685.0, y = 129.0, z = 62.0, h = 270.0 },
    { model = 'prop_skid_tent_01',  x = -1685.0, y = 137.0, z = 62.0, h = 270.0 },
    { model = 'prop_tent_01',       x = -1685.0, y = 145.0, z = 62.0, h = 270.0 },
    { model = 'prop_skid_tent_01b', x = -1685.0, y = 153.0, z = 62.0, h = 270.0 },

    -- ===== Feather/banner flags down the middle walkway =====
    { model = 'prop_beachflag_le', x = -1705.0, y = 111.0, z = 62.0, h = 0.0 },
    { model = 'prop_beachflag_le', x = -1705.0, y = 123.0, z = 62.0, h = 0.0 },
    { model = 'prop_beachflag_le', x = -1705.0, y = 135.0, z = 62.0, h = 0.0 },
    { model = 'prop_beachflag_le', x = -1705.0, y = 147.0, z = 62.0, h = 0.0 },
    { model = 'prop_beachflag_le', x = -1705.0, y = 159.0, z = 62.0, h = 0.0 },

    -- ===== Flag poles: tent-city entrance + stadium plaza corners =====
    { model = 'prop_flagpole_1a', x = -1713.0, y = 107.0, z = 62.0, h = 0.0 },
    { model = 'prop_flagpole_2a', x = -1697.0, y = 107.0, z = 62.0, h = 0.0 },
    { model = 'prop_flagpole_1a', x = -1669.0, y = 183.0, z = 63.0, h = 0.0 },
    { model = 'prop_flagpole_2a', x = -1701.0, y = 183.0, z = 63.0, h = 0.0 },

    -- ===== Event barriers along the south edge of the lot =====
    { model = 'prop_barrier_work05', x = -1729.0, y = 105.0, z = 62.0, h = 90.0 },
    { model = 'prop_barrier_work05', x = -1721.0, y = 105.0, z = 62.0, h = 90.0 },
    { model = 'prop_barrier_work05', x = -1713.0, y = 105.0, z = 62.0, h = 90.0 },
    { model = 'prop_barrier_work05', x = -1689.0, y = 105.0, z = 62.0, h = 90.0 },
    { model = 'prop_barrier_work05', x = -1681.0, y = 105.0, z = 62.0, h = 90.0 },
    { model = 'prop_barrier_work01c', x = -1705.0, y = 105.0, z = 62.0, h = 90.0 },

    -- ===== Queue barriers + cones at the tent-city entrance =====
    { model = 'prop_mp_barrier_01', x = -1709.0, y = 108.0, z = 62.0, h = 45.0 },
    { model = 'prop_mp_barrier_01', x = -1701.0, y = 108.0, z = 62.0, h = 135.0 },
    { model = 'prop_mp_cone_02', x = -1713.0, y = 109.0, z = 62.0, h = 0.0 },
    { model = 'prop_mp_cone_02', x = -1705.0, y = 109.0, z = 62.0, h = 0.0 },
    { model = 'prop_mp_cone_02', x = -1697.0, y = 109.0, z = 62.0, h = 0.0 },
    { model = 'prop_mp_cone_02', x = -1705.0, y = 163.0, z = 62.0, h = 0.0 },
    { model = 'prop_mp_cone_02', x = -1699.0, y = 163.0, z = 62.0, h = 0.0 },
    { model = 'prop_mp_cone_02', x = -1711.0, y = 163.0, z = 62.0, h = 0.0 },

    -- ===== Tailgate dressing: chair + keg clusters by a few tents =====
    { model = 'prop_chair_01a', x = -1719.0, y = 125.0, z = 62.0, h = 120.0 },
    { model = 'prop_chair_01a', x = -1719.0, y = 128.0, z = 62.0, h = 60.0 },
    { model = 'prop_keg_01',    x = -1720.0, y = 126.5, z = 62.0, h = 0.0 },
    { model = 'prop_chair_01a', x = -1691.0, y = 141.0, z = 62.0, h = 240.0 },
    { model = 'prop_chair_01a', x = -1691.0, y = 144.0, z = 62.0, h = 300.0 },
    { model = 'prop_keg_01',    x = -1690.0, y = 142.5, z = 62.0, h = 0.0 },
}

-- ============================================================================
-- GAME DAY — the "busy layer" (see server_gameday.lua / client_gameday.lua)
-- ============================================================================
-- Every OTHER real-world day is a Texas Tech game day, like Lubbock on a
-- fall Saturday. On game days an extra layer appears around the tent city:
-- grills + coolers + picnic tables, more flags, parked cars filling the
-- lots, and ambient fan peds. On off days none of it exists — base dressing
-- only. The SERVER decides what today is and tells every client; clients
-- only draw. Nothing here spawns for players who aren't near the stadium.
Config.GameDay = {
    Enabled = true,

    -- The schedule counts days from an "anchor" date. The anchor is stored
    -- in the resource's KVP storage the first time the server runs, so the
    -- every-other-day rhythm survives restarts. Days flip at LOCAL MIDNIGHT
    -- on the server PC — the PC clock is the timezone control, so keep the
    -- PC set to America/Chicago (Central) and the schedule is Central.
    --
    -- AnchorDate: leave nil to anchor on the first day the server runs
    -- (that day becomes a game day). Set a 'YYYY-MM-DD' string here to pin
    -- the rhythm yourself — a config value here WINS over the stored anchor.
    AnchorDate = nil,

    -- Chat message broadcast when a game day starts.
    AnnounceMessage = "🏈 🔴⚫⚪ It's GAME DAY at Raiderville Stadium — Texas Tech fans are taking over the lots!",

    -- Red accent lighting for game-day nights: brighter and wider than
    -- the base layer's subtle lot lighting (Config.Lighting). Scripted
    -- lights (DrawLightWithRange) — no fixtures to place or stream.
    Lighting = {
        Color = { r = 225, g = 20, b = 25 },
        Range = 22.0,
        Intensity = 2.6,
        Points = {
            vector3(-1705.0, 105.0, 66.0),
            vector3(-1738.0, 128.0, 66.0),
            vector3(-1672.0, 128.0, 66.0),
            vector3(-1705.0, 130.0, 66.0),
            vector3(-1705.0, 158.0, 66.0),
            vector3(-1720.0, 90.0, 66.0),
        },
    },

    -- Extra props for the busy layer (same shape as Config.Props).
    -- Grills / coolers / picnic tables are best-effort model names — the
    -- client skips any model that doesn't load, so a wrong name can never
    -- break the resource (it just won't appear). Verify in game.
    Props = {
        -- Grills by the tent rows
        { model = 'prop_bbq_1', x = -1719.0, y = 117.0, z = 62.0, h = 90.0 },
        { model = 'prop_bbq_3', x = -1719.0, y = 133.0, z = 62.0, h = 90.0 },
        { model = 'prop_bbq_1', x = -1691.0, y = 125.0, z = 62.0, h = 270.0 },
        { model = 'prop_bbq_3', x = -1691.0, y = 149.0, z = 62.0, h = 270.0 },
        -- Coolers next to the grills / walkway
        { model = 'prop_cool_box_01', x = -1718.0, y = 118.5, z = 62.0, h = 45.0 },
        { model = 'prop_cool_box_01', x = -1692.0, y = 126.5, z = 62.0, h = 0.0 },
        { model = 'prop_cool_box_01', x = -1705.0, y = 141.0, z = 62.0, h = 90.0 },
        { model = 'prop_cool_box_01', x = -1705.0, y = 117.0, z = 62.0, h = 90.0 },
        -- Picnic tables down the middle
        { model = 'prop_picnictable_01', x = -1705.0, y = 129.0, z = 62.0, h = 0.0 },
        { model = 'prop_picnictable_01', x = -1705.0, y = 153.0, z = 62.0, h = 0.0 },
        -- Extra banner flags + poles (the red layer — flags carry the colour)
        { model = 'prop_beachflag_le', x = -1729.0, y = 121.0, z = 62.0, h = 90.0 },
        { model = 'prop_beachflag_le', x = -1729.0, y = 145.0, z = 62.0, h = 90.0 },
        { model = 'prop_beachflag_le', x = -1681.0, y = 121.0, z = 62.0, h = 270.0 },
        { model = 'prop_beachflag_le', x = -1681.0, y = 145.0, z = 62.0, h = 270.0 },
        { model = 'prop_flagpole_1a', x = -1705.0, y = 99.0, z = 62.0, h = 0.0 },
        -- More kegs for the tailgate clusters
        { model = 'prop_keg_01', x = -1721.0, y = 142.5, z = 62.0, h = 0.0 },
        { model = 'prop_keg_01', x = -1689.0, y = 118.5, z = 62.0, h = 0.0 },
    },

    -- Parked cars filling the lots on game day. colour: 'red' | 'black' | 'white'
    -- (Texas Tech colours first). Cars are local (client-side, non-networked),
    -- locked and empty — pure dressing. Positions are lot estimates: VERIFY.
    Cars = {
        { model = 'asea',      x = -1738.0, y = 108.0, z = 62.0, h = 90.0,  colour = 'red' },
        { model = 'bison',     x = -1738.0, y = 116.0, z = 62.0, h = 90.0,  colour = 'black' },
        { model = 'ingot',     x = -1738.0, y = 124.0, z = 62.0, h = 90.0,  colour = 'white' },
        { model = 'dilettante',x = -1738.0, y = 132.0, z = 62.0, h = 90.0,  colour = 'red' },
        { model = 'futo',      x = -1738.0, y = 140.0, z = 62.0, h = 90.0,  colour = 'black' },
        { model = 'sultan',    x = -1738.0, y = 148.0, z = 62.0, h = 90.0,  colour = 'red' },
        { model = 'minivan',   x = -1672.0, y = 108.0, z = 62.0, h = 270.0, colour = 'white' },
        { model = 'burrito3',  x = -1672.0, y = 117.0, z = 62.0, h = 270.0, colour = 'black' },
        { model = 'tailgater', x = -1672.0, y = 125.0, z = 62.0, h = 270.0, colour = 'red' },
        { model = 'oracle',    x = -1672.0, y = 133.0, z = 62.0, h = 270.0, colour = 'black' },
        { model = 'fugitive',  x = -1672.0, y = 141.0, z = 62.0, h = 270.0, colour = 'white' },
        { model = 'premier',   x = -1672.0, y = 149.0, z = 62.0, h = 270.0, colour = 'red' },
    },

    -- Ambient fan peds. scenario: a WORLD_HUMAN_* scenario name, or nil to
    -- just stand. The client tries to dress them in red/black tops — how red
    -- they end up depends on each ped model's wardrobe; verify in game.
    Peds = {
        { model = 'a_m_y_hipster_01',  x = -1703.0, y = 121.0, z = 62.0, h = 90.0,  scenario = 'WORLD_HUMAN_CHEERING' },
        { model = 'a_f_y_hipster_01',  x = -1707.0, y = 123.0, z = 62.0, h = 270.0, scenario = 'WORLD_HUMAN_CHEERING' },
        { model = 'a_m_y_business_01', x = -1717.0, y = 117.5, z = 62.0, h = 90.0,  scenario = 'WORLD_HUMAN_DRINKING' },
        { model = 'a_f_y_business_01', x = -1693.0, y = 125.5, z = 62.0, h = 270.0, scenario = 'WORLD_HUMAN_DRINKING' },
        { model = 'a_m_m_beach_01',    x = -1705.0, y = 135.0, z = 62.0, h = 0.0,   scenario = 'WORLD_HUMAN_PARTYING' },
        { model = 'a_f_y_beach_01',    x = -1702.0, y = 147.0, z = 62.0, h = 180.0, scenario = 'WORLD_HUMAN_PARTYING' },
        { model = 'a_m_y_hipster_01',  x = -1708.0, y = 153.0, z = 62.0, h = 0.0,   scenario = 'WORLD_HUMAN_STAND_MOBILE' },
        { model = 'a_f_y_hipster_01',  x = -1719.0, y = 141.0, z = 62.0, h = 90.0,  scenario = 'WORLD_HUMAN_DRINKING' },
        { model = 'a_m_y_business_01', x = -1691.0, y = 149.5, z = 62.0, h = 270.0, scenario = 'WORLD_HUMAN_CHEERING' },
        { model = 'a_f_y_business_01', x = -1705.0, y = 109.0, z = 62.0, h = 180.0, scenario = 'WORLD_HUMAN_STAND_MOBILE' },
        { model = 'a_m_m_beach_01',    x = -1723.0, y = 129.0, z = 62.0, h = 90.0,  scenario = 'WORLD_HUMAN_CHEERING' },
        { model = 'a_f_y_beach_01',    x = -1687.0, y = 137.0, z = 62.0, h = 270.0, scenario = 'WORLD_HUMAN_DRINKING' },
    },
}
