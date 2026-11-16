-- Hub City Tablet — client.
-- * TABLET MODE is the phone's big mode: the phone flips out into this
--   wide tablet NUI (app grid: Black Market + Vibez + Need 2 Speed).
--   Three ways in:
--     1. The "Tablet Mode" app inside npwd hands off to this resource
--        (RegisterNUICallback 'flipFromPhone' below — scaffold-level,
--        see phone/npwd_tabletmode/README.md).
--     2. The /tablettoggle keybind (default F6) — any player carrying
--        a phone. The guaranteed path.
--     3. The hubcity_tablet item — a standalone tablet, second way in.
-- * The black-market dealer ped exists only at the ACTIVE location (the
--   server decides rotation); walk up and use ox_target to browse/buy.

local tabletOpen = false
local tabletSource = nil -- 'phone' | 'keybind' | 'item' — how the UI was opened
local tabletProp = nil
local propAttached = false -- true only if THIS resource attached the prop
local activeDealers = {} -- set of dealer indexes currently taking new deals
local myDealSpot = nil   -- dealer index of MY agreed deal, if any
local dealerPed = nil
local dealerIndex = nil

-- ── Tablet prop ─────────────────────────────────────────────────────────────

local function attachTablet()
    local ped = PlayerPedId()
    local model = GetHashKey('prop_cs_tablet')
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 2000 do
        Wait(50); timeout = timeout + 50
    end
    if not HasModelLoaded(model) then return end
    tabletProp = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    propAttached = true
    -- SKEL_R_Hand (57005). Offsets are a best-effort fit — check in game.
    AttachEntityToEntity(tabletProp, ped, GetPedBoneIndex(ped, 57005),
        0.12, 0.02, -0.02, -10.0, -160.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
    -- Tablet idle animation; if the dict is wrong the prop still shows.
    local dict = 'amb@world_human_seat_wall_tablet@male@base'
    RequestAnimDict(dict)
    timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 1500 do
        Wait(50); timeout = timeout + 50
    end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, 'base', 4.0, -4.0, -1, 49, 0, false, false, false)
    end
end

local function detachTablet()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteObject(tabletProp)
    end
    tabletProp = nil
    propAttached = false
end

-- ── Tablet UI ───────────────────────────────────────────────────────────────

local function closeTablet()
    if not tabletOpen then return end
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    -- Only fuss with the prop if WE put it there. On a phone flip npwd
    -- owns the hand prop — leave it (and its animation) alone.
    if propAttached then detachTablet() end
    tabletSource = nil
end

local function openTablet(source)
    if tabletOpen then return end
    tabletOpen = true
    tabletSource = source or 'item'
    -- PROP: from the phone, npwd is holding its phone prop on the same
    -- hand bone this attaches to. Stacking the tablet prop on top looks
    -- broken, so a phone flip keeps npwd's prop and only the SCREEN
    -- grows. Item and keybind opens attach the tablet prop as before.
    -- (Documented limitation — see INSTALL.md RISKS.)
    if tabletSource ~= 'phone' then attachTablet() end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

-- Way in #3: the standalone tablet item (ox_inventory client export).
exports('useTablet', function()
    openTablet('item')
end)

-- ── Flip from phone ─────────────────────────────────────────────────────────

-- Way in #1: the npwd "Tablet Mode" app (phone/npwd_tabletmode) POSTs
-- to this NUI callback when its button is tapped. FiveM routes NUI
-- messages by resource name, so the message reaches this resource even
-- though it was sent from inside npwd's frame. Scaffold-level handoff:
-- whether a given npwd build passes it through is what the in-game
-- test in INSTALL.md verifies. The keybind below always works.
RegisterNUICallback('flipFromPhone', function(_, cb)
    cb('ok')
    openTablet('phone')
end)

-- Way in #2: keybind / command — any player carrying a phone can flip.
local function hasPhone()
    local count = exports.ox_inventory:Search('count', Config.PhoneItem)
    return count ~= nil and count > 0
end

local function toggleTablet()
    if tabletOpen then
        closeTablet()
    elseif hasPhone() then
        openTablet('keybind')
    else
        lib.notify({
            title = 'Tablet Mode',
            description = 'You need a phone to flip into tablet mode.',
            type = 'error',
        })
    end
end

RegisterCommand(Config.TabletToggleCommand, toggleTablet, false)
RegisterKeyMapping(Config.TabletToggleCommand, 'Flip phone into tablet mode', 'keyboard', Config.TabletToggleKey)

RegisterNUICallback('closeTablet', function(_, cb)
    closeTablet()
    cb('ok')
end)

RegisterNUICallback('getTabletData', function(_, cb)
    local hot = lib.callback.await('hubcity-tablet:server:getHotSpot', false)
    local laundering = lib.callback.await('hubcity-tablet:server:getLaundering', false)
    local catalog = {}
    for _, entry in ipairs(Config.Catalog) do
        catalog[#catalog + 1] = { item = entry.item, label = entry.label, price = entry.price }
    end
    cb({
        hotNeighborhood = hot,
        allActive = Config.AllDealersActive,
        catalog = catalog,
        laundering = laundering,
        vibezUrl = Config.VibezUrl,
    })
end)

RegisterNUICallback('submitOrder', function(data, cb)
    local res = lib.callback.await('hubcity-tablet:server:submitDeal', false, data and data.items)
    if res and res.state == 'agreed' then
        refreshMyDealSpot()
    end
    cb(res or { state = 'error', message = 'No answer. Try again.' })
end)

RegisterNUICallback('getMyDeal', function(_, cb)
    cb(lib.callback.await('hubcity-tablet:server:getMyDeal', false))
end)

RegisterNetEvent('hubcity-tablet:client:dealExpired', function()
    myDealSpot = nil
    lib.notify({ title = 'Black Market', description = 'Your deal expired. The goods are back on the shelf.', type = 'error', duration = 7000 })
    if tabletOpen then
        SendNUIMessage({ action = 'dealExpired' })
    end
end)

-- ── Need 2 Speed app (street racing) ────────────────────────────────────────
-- Same pattern as the laundering section of the Black Market app: the
-- tablet is only the screen. ALL street-race state — lobbies, races,
-- records — lives in hubcity-streetrace's server; these callbacks just
-- bridge the NUI to it. There is no other door into street racing:
-- hubcity-streetrace itself has no command, keybind or item.

local function streetRaceOffline()
    return { routes = {}, races = {}, records = {}, myRace = nil, lastResults = nil }
end

RegisterNUICallback('getStreetRaceData', function(_, cb)
    if GetResourceState('hubcity-streetrace') ~= 'started' then
        cb(streetRaceOffline())
        return
    end
    cb(lib.callback.await('hubcity-streetrace:server:getData', false) or streetRaceOffline())
end)

local function streetRaceAction(name, arg)
    if GetResourceState('hubcity-streetrace') ~= 'started' then
        return { ok = false, message = 'Need 2 Speed is offline.' }
    end
    return lib.callback.await(name, false, arg) or { ok = false, message = 'No answer. Try again.' }
end

RegisterNUICallback('srCreateRace', function(data, cb)
    cb(streetRaceAction('hubcity-streetrace:server:createRace', data and data.routeId))
end)

RegisterNUICallback('srJoinRace', function(data, cb)
    cb(streetRaceAction('hubcity-streetrace:server:joinRace', data and data.raceId))
end)

RegisterNUICallback('srLeaveRace', function(_, cb)
    cb(streetRaceAction('hubcity-streetrace:server:leaveRace'))
end)

RegisterNUICallback('srStartRace', function(_, cb)
    cb(streetRaceAction('hubcity-streetrace:server:startRace'))
end)

RegisterNUICallback('srCancelRace', function(_, cb)
    cb(streetRaceAction('hubcity-streetrace:server:cancelRace'))
end)

-- Lobbies change for everyone (created, joined, started, cancelled) —
-- refresh the app live if a player is looking at it.
RegisterNetEvent('hubcity-streetrace:client:lobbiesChanged', function()
    if tabletOpen then
        SendNUIMessage({ action = 'streetRaceUpdate' })
    end
end)

-- ── Dealer ──────────────────────────────────────────────────────────────────

local function loadModel(modelName)
    local hash = GetHashKey(modelName)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 3000 do
        Wait(50); timeout = timeout + 50
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function removeDealer()
    if dealerPed and DoesEntityExist(dealerPed) then
        exports.ox_target:removeLocalEntity(dealerPed)
        DeletePed(dealerPed)
    end
    dealerPed = nil
    dealerIndex = nil
end

function refreshMyDealSpot()
    local deal = lib.callback.await('hubcity-tablet:server:getMyDeal', false)
    if deal then
        for idx, dealer in ipairs(Config.Dealers) do
            if dealer.name == deal.neighborhood then
                myDealSpot = idx
                return
            end
        end
    end
    myDealSpot = nil
end

-- Talking to a dealer: with an agreed deal assigned HERE, you get the
-- completion menu. Without one, you get brushed off — deals go through
-- the app, full stop.
local function talkToDealer(idx)
    local deal = lib.callback.await('hubcity-tablet:server:getDealForDealer', false, idx)
    if not deal then
        lib.notify({
            title = 'Dealer',
            description = "Deals go through the app. I don't know you.",
            type = 'error',
            duration = 6000,
        })
        return
    end

    local options = {}
    for _, line in ipairs(deal.items) do
        options[#options + 1] = {
            title = ('%dx %s'):format(line.amount, line.label),
            description = ('$%d each'):format(line.unitPrice),
            icon = 'fa-solid fa-box',
            disabled = true,
        }
    end
    options[#options + 1] = {
        title = ('Complete the deal — $%d cash'):format(deal.total),
        description = ('%d minutes left on this deal'):format(deal.minutesLeft),
        icon = 'fa-solid fa-handshake',
        onSelect = function()
            local ok, message = lib.callback.await('hubcity-tablet:server:completeDeal', false, idx)
            lib.notify({ title = 'Black Market', description = message, type = ok and 'success' or 'error', duration = 7000 })
            if ok then myDealSpot = nil end
        end,
    }

    lib.registerContext({
        id = 'hubcity_blackmarket_deal',
        title = 'Your deal',
        options = options,
    })
    lib.showContext('hubcity_blackmarket_deal')
end

local function spawnDealer(idx)
    local dealer = Config.Dealers[idx]
    if not dealer then return end
    local hash = loadModel(dealer.ped)
    if not hash then return end
    dealerPed = CreatePed(4, hash, dealer.coords.x, dealer.coords.y, dealer.coords.z - 1.0, dealer.heading, false, false)
    dealerIndex = idx
    SetEntityInvincible(dealerPed, true)
    SetBlockingOfNonTemporaryEvents(dealerPed, true)
    FreezeEntityPosition(dealerPed, true)
    TaskStartScenarioInPlace(dealerPed, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
    exports.ox_target:addLocalEntity(dealerPed, {
        {
            name = 'hubcity_blackmarket_talk',
            icon = 'fa-solid fa-comments',
            label = 'Talk to the dealer',
            distance = 2.0,
            onSelect = function() talkToDealer(idx) end,
        },
    })
    SetModelAsNoLongerNeeded(hash)
end

RegisterNetEvent('hubcity-tablet:client:setActiveDealers', function(indexes)
    activeDealers = {}
    for _, idx in ipairs(indexes or {}) do activeDealers[idx] = true end
    if dealerIndex and not activeDealers[dealerIndex] then
        removeDealer()
    end
end)

CreateThread(function()
    Wait(3000)
    TriggerServerEvent('hubcity-tablet:server:requestDealers')
    refreshMyDealSpot()
end)

-- Spawn a dealer when near one of the spots that matters: the active
-- (deal-taking) spots, plus the spot of MY agreed deal if rotation has
-- since moved on. Remove when far.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if ped and ped ~= 0 then
            local myCoords = GetEntityCoords(ped)
            if dealerPed then
                local dealer = Config.Dealers[dealerIndex]
                if not dealer or #(myCoords - dealer.coords) > 200.0 then
                    removeDealer()
                end
            end
            if not dealerPed then
                local candidates = {}
                for idx in pairs(activeDealers) do candidates[idx] = true end
                if myDealSpot then candidates[myDealSpot] = true end
                for idx in pairs(candidates) do
                    local dealer = Config.Dealers[idx]
                    if dealer and #(myCoords - dealer.coords) < 150.0 then
                        spawnDealer(idx)
                        break
                    end
                end
            end
        end
        Wait(1500)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    removeDealer()
    closeTablet()
end)
