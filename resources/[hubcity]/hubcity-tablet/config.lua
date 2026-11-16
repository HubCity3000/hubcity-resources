Config = {}

-- The usable inventory item that opens the tablet (definition lives in
-- items/hubcity_items.lua — paste it into ox_inventory/data/items.lua).
-- This is the STANDALONE tablet — a second way in, for players who buy
-- one. The primary way is the phone flip below.
Config.TabletItem = 'hubcity_tablet'

-- The Vibez tile opens the REAL Vibez platform in the tablet frame.
-- One platform, two doors — same rule as the phone app. Not a copy.
Config.VibezUrl = 'https://vibez-social-hub.base44.app'

-- ============================================================================
-- TABLET MODE — the phone flips out (primary way in)
-- ============================================================================
-- The tablet is the PHONE's big mode, not just a separate gadget:
--   1. The "Tablet Mode" app inside npwd (the phone/npwd_tabletmode
--      scaffold) — its button hands off to this resource and the wide
--      UI opens full-screen, "flipped out" from phone size.
--   2. The keybind / command below — works for any player carrying a
--      phone, even if the npwd app handoff needs adjusting on your
--      npwd build. This is the guaranteed path.
--   3. The hubcity_tablet item above — kept as a second way in.

-- Inventory item that counts as "has a phone" for the keybind flip.
Config.PhoneItem = 'phone'

-- Command + default key that flips the phone into tablet mode (and
-- back). Players can rebind it in GTA Settings → Key Bindings → FiveM.
-- Set the key to '' for no default key (the command still works).
Config.TabletToggleCommand = 'tablettoggle'
Config.TabletToggleKey = 'F6'

-- ============================================================================
-- BLACK MARKET
-- ============================================================================

-- How often the active dealer moves (minutes). Default 180 = 3 hours.
-- Rotation decides where NEW deals are assigned. An already-agreed deal
-- keeps its own location until it expires (see DealWindowMinutes).
Config.RotationMinutes = 180

-- Set true to make ALL dealers deal-ready at once (events, testing).
-- New deals are then assigned to a random active spot.
Config.AllDealersActive = false

-- ── Deals ──────────────────────────────────────────────────────────────────
-- Nobody buys by walking up. A player builds an order in the tablet app and
-- submits a DEAL REQUEST. The dealer agrees or passes:

-- Chance (0.0–1.0) that a valid request is agreed. Stock shortages also
-- cause a pass. Default 0.8 = agrees 4 times out of 5.
Config.DealAgreeChance = 0.8

-- Agreed prices can drift from the catalog by up to this percent, either
-- way (the deal total shows the real number before anyone travels).
-- 0 = catalog prices, always.
Config.PriceVariancePercent = 10

-- Minutes the player has to reach the dealer and complete an agreed deal
-- before it expires. Default 45.
Config.DealWindowMinutes = 45

-- Dealer spots. The tablet only names the NEIGHBORHOOD of the active one —
-- no blip, no exact pin. Players have to go look.
--
-- ⚠️ EVERY coordinate here is a first-pass pick in a sensible industrial /
-- alley / dock area and is UNVERIFIED. Walk each spot in game, stand where
-- the dealer should lean, grab your coords, and fix the one line here.
Config.Dealers = {
    { name = 'Cypress Flats', coords = vector3(842.5, -915.6, 25.5),  heading = 270.0, ped = 'a_m_m_business_01' },
    { name = 'Strawberry',    coords = vector3(185.0, -1790.0, 28.5), heading = 90.0,  ped = 'a_m_y_business_01' },
    { name = 'La Mesa',       coords = vector3(1075.0, -2005.0, 29.5), heading = 180.0, ped = 'a_m_m_business_01' },
    { name = 'Elysian Island', coords = vector3(155.0, -2865.0, 6.0), heading = 0.0,   ped = 'a_m_y_business_01' },
    { name = 'Del Perro',     coords = vector3(-1575.0, -895.0, 10.5), heading = 135.0, ped = 'a_m_m_business_01' },
}

-- The catalog. Prices are CASH. `stock` is per dealer, per rotation — when a
-- dealer becomes the active one, their stock refills to these numbers.
-- Agreeing a deal RESERVES its items from the assigned dealer's stock;
-- an expired deal releases them back.
--
-- ⚠️ WEAPONS DECISION (Daniel's call): v1 sells NO complete firearms —
-- tools and contraband only. This table is the whole shop: add, remove or
-- reprice lines here and restart the resource. If you ever add weapons,
-- that's your explicit decision, made by editing this file.
--
-- lockpick / advancedlockpick are ox_inventory default items.
-- hubcity_vpn / hubcity_fakeid / hubcity_burnerphone are custom items from
-- items/hubcity_items.lua — in v1 they are contraband flavor: owning them
-- is the point; no system consumes them yet (see README).
Config.Catalog = {
    { item = 'lockpick',         label = 'Lockpick',        price = 250,  stock = 5 },
    { item = 'advancedlockpick', label = 'Advanced Lockpick', price = 750, stock = 3 },
    { item = 'hubcity_vpn',      label = 'VPN (untraceable)', price = 500, stock = 3 },
    { item = 'hubcity_burnerphone', label = 'Burner Phone', price = 350,  stock = 4 },
    { item = 'hubcity_fakeid',   label = 'Forged ID',       price = 1200, stock = 2 },
}
