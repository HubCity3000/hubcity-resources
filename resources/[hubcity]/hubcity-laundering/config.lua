Config = {}

-- =====================================================================
--  Hub City Laundering — wash marked bills into clean bank money
-- =====================================================================
--  Hidden wash spots. NO blips, NO public markers. The only way players
--  learn where to go is the tablet's Black Market app, which advertises
--  the currently ACTIVE spot(s) by neighborhood + the current fee
--  (via this resource's GetActiveWashInfo export).
--
--  Flow: at an active spot, hand over marked bills (their worth is read
--  from item metadata SERVER-SIDE) -> wait the processing time -> come
--  back and collect clean money (minus the fee) into your bank.
-- =====================================================================

Config.DirtyItem = 'markedbills' -- ox_inventory item whose metadata carries 'worth'

Config.WashFeePercent = 25       -- the house cut (Daniel's to tune)
Config.ProcessingMinutes = 3     -- time between drop-off and collection
Config.SessionLimit = 50000      -- max total worth washed per session
Config.ActiveSpots = 1           -- how many spots are active at once (1-2 sensible)
Config.RotationMinutes = 180     -- active spot(s) rotate on this rhythm

-- Optional police alert while a wash starts. DEFAULT OFF — Daniel's
-- choice whether HCPD ever gets tipped. When on, a server event
-- 'hubcity-laundering:server:policeAlert' fires with the spot coords so
-- it can be wired to whatever dispatch the server runs.
Config.PoliceAlert = {
    Enabled = false,
    ChancePercent = 20,
}

-- Wash spots. ⚠️ ALL COORDS ARE ESTIMATES — verify in game on first
-- visit and adjust here (one-line fixes). neighborhood is the ONLY
-- location detail the tablet app ever shows.
Config.Spots = {
    {
        name = 'Laundromat back room',
        neighborhood = 'Strawberry',
        coords = vector3(1053.2, -746.8, 56.4),
        heading = 0.0,
        ped = 'a_m_m_business_01',
    },
    {
        name = 'Car wash office',
        neighborhood = 'Innocence Boulevard',
        coords = vector3(40.0, -1715.0, 29.3),
        heading = 180.0,
        ped = 'a_m_y_business_01',
    },
    {
        name = 'Warehouse office',
        neighborhood = 'Cypress Flats',
        coords = vector3(840.0, -890.0, 25.5),
        heading = 270.0,
        ped = 'a_m_m_business_01',
    },
    {
        name = 'Dock office',
        neighborhood = 'Elysian Island',
        coords = vector3(120.0, -2870.0, 6.5),
        heading = 90.0,
        ped = 'a_m_y_business_01',
    },
}
