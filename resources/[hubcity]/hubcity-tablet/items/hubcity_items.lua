-- ============================================================================
-- Hub City Tablet + Black Market — ox_inventory item definitions
-- ============================================================================
-- WHERE THIS GOES:
--   File: resources/[ox]/ox_inventory/data/items.lua
--   Paste these entries INSIDE the big items table, alongside the defaults
--   (same drill as the jobs: inside the table, commas between entries).
--   Then restart ox_inventory (or the whole server).
--
-- hubcity_tablet opens the tablet via a client export in hubcity-tablet.
-- The three contraband items are v1 flavor — no system consumes them yet.
-- ============================================================================

    ['hubcity_tablet'] = {
        label = 'Tablet',
        weight = 800,
        stack = false,
        close = true,
        description = 'A wide-screen tablet. Black Market and Vibez live here.',
        client = {
            export = 'hubcity-tablet.useTablet',
        },
    },

    ['hubcity_vpn'] = {
        label = 'VPN',
        weight = 100,
        stack = true,
        description = 'Routes your traffic through somewhere else. Probably.',
    },

    ['hubcity_burnerphone'] = {
        label = 'Burner Phone',
        weight = 200,
        stack = false,
        description = 'Prepaid, unregistered, disposable.',
    },

    ['hubcity_fakeid'] = {
        label = 'Forged ID',
        weight = 50,
        stack = false,
        description = 'The photo almost looks like you.',
    },
