Config = {}

-- ============================================================================
-- Crafting benches — walk up, target the bench, pick a recipe.
--
-- ⚠️ VERIFY IN GAME ON FIRST VISIT: all three positions are first-pass
-- estimates, flagged like every other Hub City coordinate. Stand at the
-- spot you want the bench to live, grab your coords (txAdmin / a coords
-- tool), and change the ONE line. Radius is generous on purpose until then.
-- ============================================================================
Config.Benches = {
    {
        -- Inside Home Ground (the hardware store, La Mesa) — a couple of
        -- metres from the shop counter target at (2746.8, 3473.13, 55.67).
        name = 'Home Ground — Workbench',
        coords = vector3(2745.5, 3470.5, 55.67),
        radius = 2.5,
        blip = { sprite = 402, colour = 69, scale = 0.7, label = 'Crafting Bench' },
    },
    {
        -- Workshop spot in Sandy Shores, by the repair shop on Panorama Dr.
        name = 'Sandy Shores Workshop',
        coords = vector3(1177.0, 2641.0, 37.9),
        radius = 2.5,
        blip = { sprite = 402, colour = 69, scale = 0.7, label = 'Crafting Bench' },
    },
    {
        -- Back-street workshop in the Depot District (Vinewood), just off
        -- Vinewood Blvd near the district blip at (451.2, 176.8, 103.5).
        name = 'Depot District Workshop',
        coords = vector3(438.5, 168.0, 103.2),
        radius = 2.5,
        blip = { sprite = 402, colour = 69, scale = 0.7, label = 'Crafting Bench' },
    },
}

-- How close the server requires a player to be to SOME bench before it
-- believes a craft (anti-cheat distance check, metres). Generous vs the
-- target radius so normal movement during the progress bar never trips it.
Config.MaxDistance = 12.0

-- The finish call may arrive this many ms before the full duration
-- (progress-bar timing jitter). Anything earlier is rejected.
Config.ProgressTolerance = 1500

-- ============================================================================
-- Recipes — config-driven on purpose: to add a craftable later, copy one
-- block, change the item/materials/duration. `item` must exist in
-- ox_inventory's items.lua (the backpacks + the two new materials ship in
-- items/hubcity_crafting_items.lua — see README).
--
-- `container` is the ox_inventory container capacity for the crafted item,
-- registered by the server at start via ox_inventory's
-- setContainerProperties export. NOTE: capacity is stamped into a bag's
-- metadata when the bag is CREATED — changing these numbers later only
-- affects newly crafted bags, never bags already in the city.
--
-- Material labels are display-only (menu text). The server only ever
-- checks `item` + `count` against the real inventory.
-- ============================================================================
Config.Recipes = {
    {
        id = 'small_backpack',
        item = 'hubcity_backpack_small',
        label = 'Small Backpack',
        description = 'A starter pack, stitched from canvas and hardware-store parts.',
        duration = 8000,
        container = { slots = 10, maxWeight = 15000 },
        materials = {
            { item = 'hubcity_fabric', label = 'Fabric',   count = 4 },
            { item = 'plastic',        label = 'Plastic',  count = 2 },
            { item = 'aluminum',       label = 'Aluminium', count = 1 },
        },
    },
    {
        id = 'large_backpack',
        item = 'hubcity_backpack_large',
        label = 'Large Backpack',
        description = 'Double-stitched, leather-trimmed, proper alloy frame.',
        duration = 15000,
        container = { slots = 18, maxWeight = 30000 },
        materials = {
            { item = 'hubcity_fabric',  label = 'Fabric',   count = 8 },
            { item = 'plastic',         label = 'Plastic',  count = 4 },
            { item = 'aluminum',        label = 'Aluminium', count = 3 },
            { item = 'hubcity_leather', label = 'Leather',  count = 2 },
        },
    },
    {
        id = 'duffel_bag',
        item = 'hubcity_duffel',
        label = 'Duffel Bag',
        description = 'The big one. Steel zip, rubber base, swallows heavy gear.',
        duration = 25000,
        container = { slots = 24, maxWeight = 45000 },
        materials = {
            { item = 'hubcity_fabric',  label = 'Fabric',  count = 10 },
            { item = 'hubcity_leather', label = 'Leather', count = 5 },
            { item = 'plastic',         label = 'Plastic', count = 5 },
            { item = 'steel',           label = 'Steel',   count = 2 },
            { item = 'rubber',          label = 'Rubber',  count = 2 },
        },
    },
}
