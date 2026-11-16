-- Hub City Street Racing ("Need 2 Speed") — client.
--
-- There is NO way to open street racing from here: no command, no
-- keybind, no item. The only door is the Need 2 Speed app in the tablet
-- (hubcity-tablet), which talks to the server. This client is just the
-- in-world half once the server says a race is on: grid marker, frozen
-- countdown, checkpoint racing with a live HUD, thinner traffic, and
-- the blocker crew.
--
-- Blocker honesty: the server broadcasts each running race's blocker
-- points to EVERY client; each client spawns the ones near itself —
-- frozen, invincible NPC cars with drivers, parked across the listed
-- side streets. They are scripted set dressing at chosen intersections,
-- not city-wide traffic control (see README).

local myRace = nil   -- { id, routeName, start, checkpoints, state, myCp, gridSent, finished, lastProgress }
local standing = nil -- last standings payload from the server
local frozenVeh = nil
local blockerSets = {} -- raceId -> { { coords = vector3, heading, veh, ped }, ... }

-- ── Helpers ────────────────────────────────────────────────────────────────

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

local function fmtTime(ms)
    if not ms then return 'DNF' end
    local minutes = math.floor(ms / 60000)
    local seconds = math.floor((ms % 60000) / 1000)
    local millis = math.floor(ms % 1000)
    return ('%d:%02d.%03d'):format(minutes, seconds, millis)
end

local function setFrozen(freeze)
    local ped = PlayerPedId()
    local veh = ped and GetVehiclePedIsIn(ped, false) or 0
    if freeze and veh ~= 0 then
        FreezeEntityPosition(veh, true)
        frozenVeh = veh
    elseif frozenVeh and DoesEntityExist(frozenVeh) then
        FreezeEntityPosition(frozenVeh, false)
        frozenVeh = nil
    end
end

local function updateHud()
    if not myRace then
        lib.hideTextUI()
        return
    end
    if myRace.finished then
        lib.showTextUI(('🏁 Finished — P%s of %s'):format(
            standing and standing.position or '?',
            standing and standing.total or '?'))
        return
    end
    if myRace.state ~= 'racing' then return end
    local cpShown = math.min(myRace.myCp, #myRace.checkpoints)
    lib.showTextUI(('🏁 P%s/%s · Checkpoint %d/%d'):format(
        standing and standing.position or '?',
        standing and standing.total or '?',
        cpShown, #myRace.checkpoints))
end

local function drawBigText(text, r, g, b)
    CreateThread(function()
        local untilTime = GetGameTimer() + 900
        while GetGameTimer() < untilTime do
            SetTextFont(7)
            SetTextProportional(1)
            SetTextScale(1.4, 1.4)
            SetTextColour(r, g, b, 255)
            SetTextCentre(true)
            SetTextDropShadow()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(text)
            EndTextCommandDisplayText(0.5, 0.32)
            Wait(0)
        end
    end)
end

local function clearRace()
    setFrozen(false)
    myRace = nil
    standing = nil
    lib.hideTextUI()
end

-- ── Race events (from the server) ──────────────────────────────────────────

RegisterNetEvent('hubcity-streetrace:client:raceData', function(data)
    local checkpoints = {}
    for i, cp in ipairs(data.checkpoints or {}) do
        checkpoints[i] = vector3(cp.x, cp.y, cp.z)
    end
    myRace = {
        id = data.raceId,
        routeName = data.routeName,
        start = data.start,
        checkpoints = checkpoints,
        state = 'grid',
        myCp = 1,
        gridSent = false,
        finished = false,
        lastProgress = 0,
    }
    standing = nil
    SetNewWaypoint(data.start.x, data.start.y)
    lib.notify({
        title = 'Need 2 Speed',
        description = ('%s — the start line is on your GPS. Grid up!'):format(data.routeName),
        type = 'inform',
        duration = 8000,
    })
end)

RegisterNetEvent('hubcity-streetrace:client:countdownStart', function(raceId)
    if not myRace or myRace.id ~= raceId then return end
    myRace.state = 'countdown'
    setFrozen(true)
end)

RegisterNetEvent('hubcity-streetrace:client:countdown', function(n)
    if not myRace then return end
    drawBigText(tostring(n), 255, 70, 60)
    PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
end)

RegisterNetEvent('hubcity-streetrace:client:go', function(raceId)
    if not myRace or myRace.id ~= raceId then return end
    myRace.state = 'racing'
    setFrozen(false)
    drawBigText('GO!', 80, 230, 110)
    PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
    local cp = myRace.checkpoints[1]
    if cp then SetNewWaypoint(cp.x, cp.y) end
    updateHud()
end)

RegisterNetEvent('hubcity-streetrace:client:standings', function(data)
    standing = data
    if myRace and (myRace.state == 'racing' or myRace.finished) then
        updateHud()
    end
end)

RegisterNetEvent('hubcity-streetrace:client:results', function(payload)
    local routeName = payload.routeName
    local rows = payload.rows or {}
    clearRace()
    local lines = {}
    for _, row in ipairs(rows) do
        local place = row.position and row.position > 0 and ('P' .. row.position) or 'DNF'
        lines[#lines + 1] = ('%s — %s — %s%s'):format(
            place, row.name, fmtTime(row.timeMs), row.me and '  ← you' or '')
    end
    lib.alertDialog({
        header = '🏁 Need 2 Speed — ' .. routeName,
        content = #lines > 0 and table.concat(lines, '\n') or 'No finishers.',
        centered = true,
        cancel = false,
        labels = { confirm = 'Close' },
    })
end)

RegisterNetEvent('hubcity-streetrace:client:raceCancelled', function(reason)
    if not myRace then return end
    clearRace()
    lib.notify({
        title = 'Need 2 Speed',
        description = reason or 'Race cancelled.',
        type = 'error',
        duration = 7000,
    })
end)

-- ── The blocker crew ───────────────────────────────────────────────────────

local function spawnBlocker(b)
    local vehHash = loadModel(Config.BlockerVehicles[math.random(#Config.BlockerVehicles)])
    if not vehHash then return end
    local veh = CreateVehicle(vehHash, b.coords.x, b.coords.y, b.coords.z, b.heading, false, false)
    if not veh or veh == 0 then
        SetModelAsNoLongerNeeded(vehHash)
        return
    end
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    FreezeEntityPosition(veh, true)
    SetEntityInvincible(veh, true)
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleHandbrake(veh, true)
    b.veh = veh

    local pedHash = loadModel(Config.BlockerPeds[math.random(#Config.BlockerPeds)])
    if pedHash then
        local ped = CreatePedInsideVehicle(veh, 4, pedHash, -1, false, false)
        if ped and ped ~= 0 then
            SetEntityAsMissionEntity(ped, true, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedCanBeDraggedOut(ped, false)
            b.ped = ped
        end
        SetModelAsNoLongerNeeded(pedHash)
    end
    SetModelAsNoLongerNeeded(vehHash)
end

local function removeBlocker(b)
    if b.ped and DoesEntityExist(b.ped) then DeletePed(b.ped) end
    if b.veh and DoesEntityExist(b.veh) then DeleteVehicle(b.veh) end
    b.ped = nil
    b.veh = nil
end

RegisterNetEvent('hubcity-streetrace:client:blockersOn', function(raceId, list)
    local set = {}
    for i, b in ipairs(list or {}) do
        set[i] = {
            coords = vector3(b.coords.x, b.coords.y, b.coords.z),
            heading = b.heading or 0.0,
        }
    end
    blockerSets[raceId] = set
end)

RegisterNetEvent('hubcity-streetrace:client:blockersOff', function(raceId)
    local set = blockerSets[raceId]
    if set then
        for _, b in ipairs(set) do removeBlocker(b) end
    end
    blockerSets[raceId] = nil
end)

-- Spawn/despawn blockers by distance, for every running race.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if ped and ped ~= 0 then
            local myCoords = GetEntityCoords(ped)
            for _, set in pairs(blockerSets) do
                for _, b in ipairs(set) do
                    local dist = #(myCoords - b.coords)
                    if not b.veh and dist < Config.BlockerSpawnDistance then
                        spawnBlocker(b)
                    elseif b.veh and dist > Config.BlockerDespawnDistance then
                        removeBlocker(b)
                    end
                end
            end
        end
        Wait(1500)
    end
end)

-- ── Grid + race loop ───────────────────────────────────────────────────────

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        if myRace and ped and ped ~= 0 then
            local veh = GetVehiclePedIsIn(ped, false)
            local myCoords = GetEntityCoords(ped)

            if myRace.state == 'grid' then
                sleep = 0
                local s = myRace.start
                DrawMarker(1, s.x, s.y, s.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    Config.GridRadius * 2.0, Config.GridRadius * 2.0, 6.0,
                    179, 18, 46, 120, false, false, 2, false, nil, nil, false)
                if veh ~= 0 and not myRace.gridSent
                    and #(myCoords - vector3(s.x, s.y, s.z)) < Config.GridRadius then
                    myRace.gridSent = true
                    TriggerServerEvent('hubcity-streetrace:server:gridReady')
                    lib.notify({
                        title = 'Need 2 Speed',
                        description = 'You are on the grid. Wait for the rest of the field…',
                        type = 'success',
                    })
                end

            elseif myRace.state == 'racing' and not myRace.finished then
                sleep = 0
                -- Thinner traffic around racers while the race runs.
                SetVehicleDensityMultiplierThisFrame(Config.TrafficDensity)
                SetRandomVehicleDensityMultiplierThisFrame(Config.TrafficDensity)
                SetParkedVehicleDensityMultiplierThisFrame(Config.ParkedDensity)
                SetPedDensityMultiplierThisFrame(Config.PedDensity)
                SetScenarioPedDensityMultiplierThisFrame(Config.PedDensity, Config.PedDensity)

                local cp = myRace.checkpoints[myRace.myCp]
                if cp then
                    DrawMarker(1, cp.x, cp.y, cp.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        Config.CheckpointRadius * 2.0, Config.CheckpointRadius * 2.0, 8.0,
                        255, 200, 40, 140, false, false, 2, false, nil, nil, false)
                    local dist = #(myCoords - cp)
                    if veh ~= 0 and dist < Config.CheckpointRadius then
                        myRace.myCp = myRace.myCp + 1
                        if myRace.myCp > #myRace.checkpoints then
                            myRace.finished = true
                            TriggerServerEvent('hubcity-streetrace:server:finished')
                            lib.notify({
                                title = 'Need 2 Speed',
                                description = 'Finished! Waiting on the rest of the field…',
                                type = 'success',
                            })
                            updateHud()
                        else
                            local nxt = myRace.checkpoints[myRace.myCp]
                            SetNewWaypoint(nxt.x, nxt.y)
                            TriggerServerEvent('hubcity-streetrace:server:progress', myRace.myCp, dist)
                            updateHud()
                        end
                    elseif GetGameTimer() - myRace.lastProgress > 2000 then
                        myRace.lastProgress = GetGameTimer()
                        TriggerServerEvent('hubcity-streetrace:server:progress', myRace.myCp, dist)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for _, set in pairs(blockerSets) do
        for _, b in ipairs(set) do removeBlocker(b) end
    end
    blockerSets = {}
    clearRace()
end)
