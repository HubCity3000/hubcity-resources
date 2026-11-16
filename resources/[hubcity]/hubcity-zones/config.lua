Config = {}

-- The name Vinewood becomes, everywhere this resource can reach.
Config.DistrictName = 'The Depot District'

-- Map blip marking the district (on Vinewood Blvd, by the Walk of Fame /
-- Oriental Theater strip).
-- ⚠️ FIRST-PASS ESTIMATE, like every Hub City coordinate: verify in game
-- on the first visit and nudge these numbers if the blip sits wrong.
Config.Blip = {
    coords = vector3(451.2, 176.8, 103.5),
    sprite = 162,   -- theatre masks; change freely, it's cosmetic
    colour = 1,     -- red, to match the Hub City theme
    scale  = 0.9,
}

-- EXPERIMENTAL: GTA zone text labels for the Vinewood family of zones.
-- client.lua feeds these to AddTextEntry in the hope the HUD's area name
-- (bottom-right) picks the override up. Whether the zone display honours
-- runtime label overrides is NOT guaranteed — see README.md. A wrong key
-- is harmless: it just registers a label nothing uses.
Config.ZoneLabels = {
    'VINE',    -- Vinewood
    'DTVINE',  -- Downtown Vinewood
    'WVINE',   -- West Vinewood
    'EAST_V',  -- East Vinewood
}
