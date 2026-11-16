-- ============================================================================
-- Hub City Crafting — ox_inventory item definitions
-- ============================================================================
-- WHERE THIS GOES:
--   File: resources/[ox]/ox_inventory/data/items.lua
--   Paste these entries INSIDE the big items table, alongside the defaults
--   and the other Hub City snippet (hubcity-tablet/items/hubcity_items.lua).
--   Commas between entries. Then restart ox_inventory (or the whole server).
--
-- WHAT'S HERE:
--   * The three craftable backpacks. They are CONTAINERS: their capacity
--     (slots + maxWeight) is registered by hubcity-crafting's server at
--     start via ox_inventory's setContainerProperties export, using the
--     numbers in hubcity-crafting/config.lua — so no edit to ox_inventory's
--     modules/items/containers.lua is needed. (consume = 0 keeps "using"
--     the bag — which opens it — from eating the bag.)
--   * Two NEW materials the stock items.lua doesn't ship: Fabric and
--     Leather. The other recipe materials (plastic, aluminum, steel,
--     rubber) already exist in the Qbox items.lua — do NOT re-add them.
--
-- FALLBACK (only if a future ox_inventory removes the export): paste these
-- three lines into ox_inventory/modules/items/containers.lua instead,
-- above the `return containers` line — same numbers as config.lua:
--   setContainerProperties('hubcity_backpack_small', { slots = 10, maxWeight = 15000 })
--   setContainerProperties('hubcity_backpack_large', { slots = 18, maxWeight = 30000 })
--   setContainerProperties('hubcity_duffel',        { slots = 24, maxWeight = 45000 })
-- ============================================================================

    ['hubcity_backpack_small'] = {
        label = 'Small Backpack',
        weight = 800,
        stack = false,
        close = true,
        consume = 0,
        description = 'Hand-stitched at a Hub City bench. 10 slots, carries 15 kg.',
    },

    ['hubcity_backpack_large'] = {
        label = 'Large Backpack',
        weight = 1400,
        stack = false,
        close = true,
        consume = 0,
        description = 'Double-stitched, leather-trimmed, alloy frame. 18 slots, carries 30 kg.',
    },

    ['hubcity_duffel'] = {
        label = 'Duffel Bag',
        weight = 2000,
        stack = false,
        close = true,
        consume = 0,
        description = 'Steel zip, rubber base, swallows heavy gear. 24 slots, carries 45 kg.',
    },

    ['hubcity_fabric'] = {
        label = 'Fabric',
        weight = 100,
        stack = true,
        description = 'Heavy canvas cloth, by the bolt. Backpack bodies start here.',
    },

    ['hubcity_leather'] = {
        label = 'Leather',
        weight = 100,
        stack = true,
        description = 'Tanned hide for straps, trim and the good bags.',
    },
