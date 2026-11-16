-- Raiderville Stadium client: map blip + proximity-spawned tent city dressing.
-- All props are local (client-side) objects: they appear when a player is
-- near the stadium and are cleaned up when they leave or the resource stops.

local spawnedProps = {}
local propsSpawned = false
local stadiumBlip = nil

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
        return nil -- failed to load in time: skip this prop
    end
    return hash
end

local function spawnProps()
    if propsSpawned then return end
    propsSpawned = true
    for _, prop in ipairs(Config.Props) do
        local hash = loadModel(prop.model)
        if hash then
            local obj = CreateObject(hash, prop.x, prop.y, prop.z, false, false, false)
            if obj and obj ~= 0 then
                SetEntityHeading(obj, prop.h or 0.0)
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                SetEntityCollision(obj, true, true)
                spawnedProps[#spawnedProps + 1] = obj
            end
            SetModelAsNoLongerNeeded(hash)
        end
    end
end

local function despawnProps()
    for _, obj in ipairs(spawnedProps) do
        if DoesEntityExist(obj) then
            DeleteObject(obj)
        end
    end
    spawnedProps = {}
    propsSpawned = false
end

local function setBlipName(name)
    if not stadiumBlip or not DoesBlipExist(stadiumBlip) then return end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(name)
    EndTextCommandSetBlipName(stadiumBlip)
end

-- Map blip: "Raiderville Stadium" on the ULSA stadium (Texas Tech University).
CreateThread(function()
    stadiumBlip = AddBlipForCoord(Config.Blip.coords.x, Config.Blip.coords.y, Config.Blip.coords.z)
    SetBlipSprite(stadiumBlip, Config.Blip.sprite)
    SetBlipDisplay(stadiumBlip, 4)
    SetBlipScale(stadiumBlip, Config.Blip.scale)
    SetBlipColour(stadiumBlip, Config.Blip.colour)
    SetBlipAsShortRange(stadiumBlip, Config.Blip.shortRange)
    setBlipName(Config.StadiumName)
end)

-- Game day (server decides, see server_gameday.lua): the blip calls it out
-- on the map — renamed and flashing while the lots are full.
RegisterNetEvent('hubcity-raiderville:client:setGameDay', function(active)
    if not stadiumBlip or not DoesBlipExist(stadiumBlip) then return end
    if active then
        setBlipName(Config.StadiumName .. ' — GAME DAY')
        SetBlipFlashes(stadiumBlip, true)
        SetBlipScale(stadiumBlip, Config.Blip.scale * 1.2)
    else
        setBlipName(Config.StadiumName)
        SetBlipFlashes(stadiumBlip, false)
        SetBlipScale(stadiumBlip, Config.Blip.scale)
    end
end)

-- Proximity loop: spawn the tent city within range, remove it beyond.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if ped and ped ~= 0 then
            local dist = #(GetEntityCoords(ped) - Config.TentCityAnchor)
            if dist < Config.SpawnDistance and not propsSpawned then
                spawnProps()
            elseif dist > Config.DespawnDistance and propsSpawned then
                despawnProps()
            end
        end
        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    despawnProps()
    if stadiumBlip and DoesBlipExist(stadiumBlip) then
        RemoveBlip(stadiumBlip)
    end
end)

-- ── Base red lot lighting (Texas Tech palette) ──────────────────────────
-- Scripted lights: DrawLightWithRange must be called every frame, so this
-- thread only runs hot when a player is near the stadium after dark —
-- subtle red lot lighting on ALL nights, game day or not.
CreateThread(function()
    local light = Config.Lighting
    if not light or not light.Enabled then return end
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        if ped and ped ~= 0 and #(GetEntityCoords(ped) - Config.TentCityAnchor) < 250.0 then
            local hour = GetClockHours()
            local night = hour >= (light.NightStart or 19) or hour < (light.NightEnd or 6)
            if night or not light.NightOnly then
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
