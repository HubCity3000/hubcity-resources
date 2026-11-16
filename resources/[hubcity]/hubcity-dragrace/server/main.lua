-- Hub City Drag Race — server.
-- Owns the two-lane race state, validates staging and finishes,
-- stores every finished pass in `hubcity_drag_times` and serves the
-- timing board. Clients measure their own elapsed time (their clock
-- starts on their GO); the server plausibility-checks every time
-- before it is recorded.

local lanes = { [1] = nil, [2] = nil } -- lane -> entry (see stage handler)
local state = 'idle'                   -- idle | countdown | racing
local raceToken = 0                    -- bumped on reset to kill stale timers

local function otherLane(lane)
    return lane == 1 and 2 or 1
end

local function laneOf(src)
    for lane = 1, 2 do
        if lanes[lane] and lanes[lane].src == src then return lane end
    end
    return nil
end

local function laneStagingPoint(lane)
    local dir = Config.Direction
    local perp = vector2(-dir.y, dir.x)
    local offset = (lane == 1) and Config.LaneOffset or -Config.LaneOffset
    return vector3(
        Config.StartLine.x + perp.x * offset,
        Config.StartLine.y + perp.y * offset,
        Config.StartLine.z
    )
end

local function resetRace()
    raceToken = raceToken + 1
    lanes = { [1] = nil, [2] = nil }
    state = 'idle'
end

-- Safety net: create the table if the SQL file wasn't imported by hand.
MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `hubcity_drag_times` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(50) NOT NULL,
            `name` VARCHAR(100) NOT NULL,
            `vehicle` VARCHAR(50) NOT NULL,
            `time_ms` INT NOT NULL,
            `speed` DECIMAL(6,2) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_drag_time` (`time_ms`),
            INDEX `idx_drag_citizen` (`citizenid`, `time_ms`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

local function concludeRace()
    -- Winner = fastest finished, non-void lane. One finisher wins by
    -- default; a void (red light) can never win.
    local winner = nil
    for lane = 1, 2 do
        local e = lanes[lane]
        if e and e.finished and not e.void then
            if not winner or e.timeMs < winner.timeMs then winner = e end
        end
    end

    local occupied = 0
    for lane = 1, 2 do if lanes[lane] then occupied = occupied + 1 end end

    for lane = 1, 2 do
        local e = lanes[lane]
        if e then
            local o = lanes[otherLane(lane)]
            TriggerClientEvent('hubcity-dragrace:client:results', e.src, {
                solo = occupied < 2,
                yourTime = e.finished and e.timeMs or nil,
                yourSpeed = e.finished and e.speed or nil,
                youVoid = e.void or false,
                isPersonalBest = e.isPersonalBest or false,
                oppName = o and o.name or nil,
                oppTime = (o and o.finished) and o.timeMs or nil,
                oppSpeed = (o and o.finished) and o.speed or nil,
                oppVoid = o and (o.void or false) or false,
                winnerName = winner and winner.name or nil,
            })
        end
    end

    resetRace()
end

local function maybeConclude()
    if state ~= 'racing' then return end
    for lane = 1, 2 do
        local e = lanes[lane]
        if e and not e.finished and not e.void and not e.dnf then
            return -- someone is still running
        end
    end
    concludeRace()
end

local function beginCountdown()
    if state ~= 'idle' then return end
    state = 'countdown'
    local token = raceToken

    for lane = 1, 2 do
        if lanes[lane] then
            TriggerClientEvent('hubcity-dragrace:client:countdown', lanes[lane].src, Config.CountdownSeconds * 1000)
        end
    end

    SetTimeout(Config.CountdownSeconds * 1000, function()
        if token ~= raceToken or state ~= 'countdown' then return end
        state = 'racing'
        for lane = 1, 2 do
            if lanes[lane] and not lanes[lane].void then
                TriggerClientEvent('hubcity-dragrace:client:go', lanes[lane].src)
            end
        end
        -- Unfinished lanes are called DNF after the timeout.
        SetTimeout(Config.RaceTimeoutSeconds * 1000, function()
            if token ~= raceToken or state ~= 'racing' then return end
            concludeRace()
        end)
    end)
end

-- ---------------------------------------------------------------------
-- Staging
-- ---------------------------------------------------------------------
RegisterNetEvent('hubcity-dragrace:server:stage', function(lane, netId)
    local src = source
    lane = tonumber(lane)
    if lane ~= 1 and lane ~= 2 then return end

    if state ~= 'idle' then
        TriggerClientEvent('hubcity-dragrace:client:stageDenied', src, 'A race is already running — wait for the strip to clear.')
        return
    end
    if lanes[lane] then
        TriggerClientEvent('hubcity-dragrace:client:stageDenied', src, 'That lane is taken — use the other one.')
        return
    end
    if laneOf(src) then
        TriggerClientEvent('hubcity-dragrace:client:stageDenied', src, 'You are already staged.')
        return
    end

    -- Validate the claim: the player must actually be driving the
    -- vehicle they named, in the staging box they named.
    local veh = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    if GetPedInVehicleSeat(veh, -1) ~= GetPlayerPed(src) then return end
    if #(GetEntityCoords(veh) - laneStagingPoint(lane)) > Config.StageRadius + 3.0 then
        TriggerClientEvent('hubcity-dragrace:client:stageDenied', src, 'You are not in the staging box.')
        return
    end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local info = player.PlayerData.charinfo or {}
    local name = ((info.firstname or '') .. ' ' .. (info.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then name = 'Unknown Racer' end

    lanes[lane] = {
        src = src,
        citizenid = player.PlayerData.citizenid,
        name = name,
        void = false,
        finished = false,
        dnf = false,
        timeMs = nil,
        speed = nil,
        isPersonalBest = false,
    }
    TriggerClientEvent('hubcity-dragrace:client:staged', src, lane)
    print(('[hubcity-dragrace] %s (%s) staged in lane %d'):format(name, player.PlayerData.citizenid, lane))

    if lanes[otherLane(lane)] then
        -- Head-to-head: short pause so both drivers register, then lights.
        local token = raceToken
        SetTimeout(1200, function()
            if token == raceToken and state == 'idle' then beginCountdown() end
        end)
    else
        -- Solo: wait for an opponent, then run a timed pass alone.
        local token = raceToken
        SetTimeout(Config.SoloWaitSeconds * 1000, function()
            if token ~= raceToken or state ~= 'idle' then return end
            if lanes[lane] and not lanes[otherLane(lane)] then beginCountdown() end
        end)
    end
end)

RegisterNetEvent('hubcity-dragrace:server:unstage', function()
    local src = source
    if state ~= 'idle' then return end
    local lane = laneOf(src)
    if not lane then return end
    lanes[lane] = nil
    TriggerClientEvent('hubcity-dragrace:client:unstaged', src)
end)

-- ---------------------------------------------------------------------
-- False start / DNF / finish
-- ---------------------------------------------------------------------
RegisterNetEvent('hubcity-dragrace:server:falseStart', function()
    local src = source
    if state ~= 'countdown' then return end
    local lane = laneOf(src)
    if not lane then return end
    local entry = lanes[lane]
    if entry.void then return end

    entry.void = true
    TriggerClientEvent('hubcity-dragrace:client:redLight', src)
    print(('[hubcity-dragrace] %s red-lit in lane %d'):format(entry.name, lane))

    local other = lanes[otherLane(lane)]
    if other and other.void then
        -- Both lanes red-lit: nobody runs. Wrap it up now; bumping the
        -- token kills the pending GO timer inside beginCountdown.
        raceToken = raceToken + 1
        state = 'racing' -- lets concludeRace treat this as a finished race
        concludeRace()
    end
    -- Otherwise the clean lane still gets its GO on schedule.
end)

RegisterNetEvent('hubcity-dragrace:server:dnf', function()
    local src = source
    if state ~= 'racing' then return end
    local lane = laneOf(src)
    if not lane then return end
    lanes[lane].dnf = true
    maybeConclude()
end)

RegisterNetEvent('hubcity-dragrace:server:finish', function(timeMs, speed, vehicleLabel)
    local src = source
    if state ~= 'racing' then return end
    local lane = laneOf(src)
    if not lane then return end
    local entry = lanes[lane]
    if entry.void or entry.finished or entry.dnf then return end

    timeMs = math.floor(tonumber(timeMs) or 0)
    speed = tonumber(speed) or 0.0
    if timeMs < Config.MinPlausibleTimeMs or timeMs > (Config.RaceTimeoutSeconds * 1000) + 5000 then
        return -- impossible time: not recorded, lane stays unresolved
    end
    if speed < 0.0 or speed > 500.0 then speed = 0.0 end
    if type(vehicleLabel) ~= 'string' or vehicleLabel == '' then vehicleLabel = 'Unknown' end
    if #vehicleLabel > 50 then vehicleLabel = vehicleLabel:sub(1, 50) end

    entry.finished = true
    entry.timeMs = timeMs
    entry.speed = speed

    MySQL.insert.await(
        'INSERT INTO hubcity_drag_times (citizenid, name, vehicle, time_ms, speed) VALUES (?, ?, ?, ?, ?)',
        { entry.citizenid, entry.name, vehicleLabel, timeMs, speed }
    )
    local best = MySQL.scalar.await(
        'SELECT MIN(time_ms) FROM hubcity_drag_times WHERE citizenid = ?',
        { entry.citizenid }
    )
    entry.isPersonalBest = (best == timeMs)
    print(('[hubcity-dragrace] %s ran %.3f s at %.1f %s in a %s'):format(
        entry.name, timeMs / 1000.0, speed, Config.SpeedUnit, vehicleLabel))

    maybeConclude()
end)

-- ---------------------------------------------------------------------
-- Timing board
-- ---------------------------------------------------------------------
lib.callback.register('hubcity-dragrace:server:getBoard', function(src)
    local top = MySQL.query.await(
        'SELECT name, vehicle, time_ms, speed FROM hubcity_drag_times ORDER BY time_ms ASC LIMIT 10'
    )

    local personalBest = nil
    local player = exports.qbx_core:GetPlayer(src)
    if player then
        local rows = MySQL.query.await(
            'SELECT vehicle, time_ms, speed FROM hubcity_drag_times WHERE citizenid = ? ORDER BY time_ms ASC LIMIT 1',
            { player.PlayerData.citizenid }
        )
        if rows and rows[1] then personalBest = rows[1] end
    end

    return { top = top or {}, personalBest = personalBest }
end)

-- ---------------------------------------------------------------------
-- Disconnect cleanup
-- ---------------------------------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source
    local lane = laneOf(src)
    if not lane then return end
    if state == 'idle' then
        lanes[lane] = nil
    elseif state == 'racing' then
        lanes[lane].dnf = true
        maybeConclude()
    else -- countdown: treat as a void lane so the other driver can run
        lanes[lane].void = true
        local other = lanes[otherLane(lane)]
        if other and other.void then
            raceToken = raceToken + 1
            state = 'racing'
            concludeRace()
        end
    end
end)

print('[hubcity-dragrace] Sandy Shores Drag Strip loaded')
