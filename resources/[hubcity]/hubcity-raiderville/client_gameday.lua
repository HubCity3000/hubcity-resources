-- Raiderville Stadium — GAME DAY busy layer (client side).
--
-- The server says whether today is a game day ('hubcity-raiderville:client:setGameDay').
-- When it is AND the player is near the stadium, this module spawns the busy
-- layer: extra tailgate props, parked cars, ambient fan peds — all local
-- (client-side, non-networked), exactly like the base dressing. Everything
-- is removed when the player leaves the area, when the day flips off, or
-- when the resource stops. Nothing spawns for far-away players.

local gameDayActive = false
local layerSpawned = false
local layerProps = {}
local layerCars = {}
local layerPeds = {}

local TEAM_COLOURS = {
    red = { 204, 0, 0 },     -- Texas Tech scarlet
    black = { 12, 12, 12 },
    white = { 240, 240, 240 },
}

local function loadModel(modelName)
    local hash = GetHashKey(modelName)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil -- unknown/bad model name: skip gracefully
    end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 3000 do
        Wait(50)
        timeout = timeout + 50
    end
    if not HasModelLoaded(hash) then
        return nil
    end
    return hash
end

local function spawnLayer()
    if layerSpawned or not Config.GameDay then return end
    layerSpawned = true

    -- Extra props
    for _, prop in ipairs(Config.GameDay.Props or {}) do
        local hash = loadModel(prop.model)
        if hash then
            local obj = CreateObject(hash, prop.x, prop.y, prop.z, false, false, false)
            if obj and obj ~= 0 then
                SetEntityHeading(obj, prop.h or 0.0)
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                SetEntityCollision(obj, true, true)
                layerProps[#layerProps + 1] = obj
            end
            SetModelAsNoLongerNeeded(hash)
        end
    end

    -- Parked cars
    for _, car in ipairs(Config.GameDay.Cars or {}) do
        local hash = loadModel(car.model)
        if hash then
            local veh = CreateVehicle(hash, car.x, car.y, car.z, car.h or 0.0, false, false)
            if veh and veh ~= 0 then
                local rgb = TEAM_COLOURS[car.colour] or TEAM_COLOURS.red
                SetVehicleCustomPrimaryColour(veh, rgb[1], rgb[2], rgb[3])
                SetVehicleCustomSecondaryColour(veh, rgb[1], rgb[2], rgb[3])
                SetVehicleDoorsLocked(veh, 2)
                SetVehicleEngineOn(veh, false, true, true)
                SetEntityCollision(veh, true, true)
                FreezeEntityPosition(veh, true)
                layerCars[#layerCars + 1] = veh
            end
            SetModelAsNoLongerNeeded(hash)
        end
    end

    -- Fan peds
    for _, fan in ipairs(Config.GameDay.Peds or {}) do
        local hash = loadModel(fan.model)
        if hash then
            local ped = CreatePed(4, hash, fan.x, fan.y, fan.z, fan.h or 0.0, false, false)
            if ped and ped ~= 0 then
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                -- Best-effort team colours: try a red or black top on the
                -- ped's shirt component. Wardrobes differ per model, so this
                -- is approximate — some fans will just wear what they wear.
                local tops = GetNumberOfPedTextureVariations(ped, 11, 0)
                if tops > 0 then
                    SetPedComponentVariation(ped, 11, 0, math.random(0, tops - 1), 0)
                end
                if fan.scenario then
                    TaskStartScenarioInPlace(ped, fan.scenario, 0, true)
                end
                layerPeds[#layerPeds + 1] = ped
            end
            SetModelAsNoLongerNeeded(hash)
        end
    end
end

local function despawnLayer()
    for _, obj in ipairs(layerProps) do
        if DoesEntityExist(obj) then DeleteObject(obj) end
    end
    for _, veh in ipairs(layerCars) do
        if DoesEntityExist(veh) then DeleteVehicle(veh) end
    end
    for _, ped in ipairs(layerPeds) do
        if DoesEntityExist(ped) then DeletePed(ped) end
    end
    layerProps, layerCars, layerPeds = {}, {}, {}
    layerSpawned = false
end

RegisterNetEvent('hubcity-raiderville:client:setGameDay', function(active)
    gameDayActive = active == true
    if not gameDayActive and layerSpawned then
        despawnLayer()
    end
end)

-- Ask the server for the current state once we're loaded.
CreateThread(function()
    Wait(3000)
    TriggerServerEvent('hubcity-raiderville:server:requestState')
end)

-- Proximity loop, same rhythm as the base dressing.
CreateThread(function()
    while true do
        if gameDayActive then
            local ped = PlayerPedId()
            if ped and ped ~= 0 then
                local dist = #(GetEntityCoords(ped) - Config.TentCityAnchor)
                if dist < Config.SpawnDistance and not layerSpawned then
                    spawnLayer()
                elseif dist > Config.DespawnDistance and layerSpawned then
                    despawnLayer()
                end
            end
        elseif layerSpawned then
            despawnLayer()
        end
        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    despawnLayer()
end)

-- ── Game-day red accent lighting ────────────────────────────────────────
-- Brighter/wider than the base layer's subtle lot lighting. Runs only
-- while a game day is active AND a player is near the stadium.
CreateThread(function()
    local light = Config.GameDay and Config.GameDay.Lighting
    if not light then return end
    while true do
        local sleep = 1000
        if gameDayActive then
            local ped = PlayerPedId()
            if ped and ped ~= 0 and #(GetEntityCoords(ped) - Config.TentCityAnchor) < 250.0 then
                sleep = 0
                for _, p in ipairs(light.Points) do
                    DrawLightWithRange(p.x, p.y, p.z,
                        light.Color.r, light.Color.g, light.Color.b,
                        light.Range, light.Intensity)
                end
            end
        end
        Wait(sleep)
    end
end)
