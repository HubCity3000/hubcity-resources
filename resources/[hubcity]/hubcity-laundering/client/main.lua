-- Hub City Laundering — client: spawns a wash contact ped + ox_target
-- zone ONLY at the currently active spot(s) (fetched from the server,
-- refreshed periodically). No blips, no markers — by design.

local activeSpots = {} -- index -> { ped = handle, zone = zoneId }

local function despawnSpot(idx)
    local s = activeSpots[idx]
    if not s then return end
    if s.zone then exports.ox_target:removeZone(s.zone) end
    if s.ped and DoesEntityExist(s.ped) then DeleteEntity(s.ped) end
    activeSpots[idx] = nil
end

local function spawnSpot(spot)
    if activeSpots[spot.index] then return end
    local model = joaat(spot.ped)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 50 do Wait(100) timeout = timeout + 1 end
    if not HasModelLoaded(model) then return end

    local ped = CreatePed(4, model, spot.coords.x, spot.coords.y, spot.coords.z - 1.0, spot.heading, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(model)

    local zone = exports.ox_target:addSphereZone({
        coords = spot.coords,
        radius = 2.0,
        debug = false,
        options = {
            {
                name = 'hubcity_laundering_wash_' .. spot.index,
                icon = 'fa-solid fa-soap',
                label = 'Wash marked bills',
                onSelect = function()
                    local res = lib.callback.await('hubcity-laundering:startWash', false, spot.index)
                    lib.notify({ title = 'Laundering', description = res.message, type = res.ok and 'success' or 'error' })
                end,
            },
            {
                name = 'hubcity_laundering_collect_' .. spot.index,
                icon = 'fa-solid fa-money-bill-transfer',
                label = 'Collect clean money',
                onSelect = function()
                    local res = lib.callback.await('hubcity-laundering:collectWash', false)
                    lib.notify({ title = 'Laundering', description = res.message, type = res.ok and 'success' or 'error' })
                end,
            },
        },
    })

    activeSpots[spot.index] = { ped = ped, zone = zone }
end

local function refreshSpots()
    local spots = lib.callback.await('hubcity-laundering:getActiveSpots', false) or {}
    local wanted = {}
    for _, s in ipairs(spots) do wanted[s.index] = s end
    for idx in pairs(activeSpots) do
        if not wanted[idx] then despawnSpot(idx) end
    end
    for _, s in ipairs(spots) do spawnSpot(s) end
end

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(500) end
    refreshSpots()
    while true do
        Wait(60000)
        refreshSpots()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for idx in pairs(activeSpots) do despawnSpot(idx) end
end)
