-- Hub City Drag Race — client.
-- Staging prompts, the vehicle hold, the on-screen countdown, the
-- false-start watch, finish-line detection and the timing board.
-- The server owns the race state, validates everything and writes the
-- times to `hubcity_drag_times`.

local staged = false       -- this player is staged in a lane
local myLane = nil
local countingDown = false
local racing = false
local raceVehicle = 0
local stagedPos = nil
local countdownEndsAt = 0  -- GetGameTimer() value at GO
local goAt = 0             -- GetGameTimer() value when GO fired
local lastCountShown = nil
local redLightUntil = 0    -- draw the red light until this timer value
local goFlashUntil = 0     -- draw GO! until this timer value
local promptLane = nil     -- lane whose stage prompt is on screen

local function trackLength()
    return Config.Distances[Config.DistancePreset] or Config.Distances.quarter
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

local function finishPoint(lane)
    local start = laneStagingPoint(lane)
    return vector3(
        start.x + Config.Direction.x * trackLength(),
        start.y + Config.Direction.y * trackLength(),
        start.z
    )
end

-- Distance travelled past the start line, along the race direction.
local function progressAlongTrack(pos)
    local dx = pos.x - Config.StartLine.x
    local dy = pos.y - Config.StartLine.y
    return (dx * Config.Direction.x) + (dy * Config.Direction.y)
end

local function myVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then return veh end
    return 0
end

local function formatTime(ms)
    if not ms then return '—' end
    return ('%.3f s'):format(ms / 1000.0)
end

local function formatSpeed(speed)
    if not speed then return '—' end
    return ('%.1f %s'):format(speed, Config.SpeedUnit)
end

local function drawCentreText(text, r, g, b, scale)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, 255)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentString(text)
    EndTextCommandDisplayText(0.5, 0.28)
end

local function releaseVehicle()
    if raceVehicle ~= 0 and DoesEntityExist(raceVehicle) then
        FreezeEntityPosition(raceVehicle, false)
    end
end

-- ---------------------------------------------------------------------
-- Blip
-- ---------------------------------------------------------------------
CreateThread(function()
    local c = Config.Blip.coords
    local blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipColour(blip, Config.Blip.colour)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blip.label)
    EndTextCommandSetBlipName(blip)
end)

-- ---------------------------------------------------------------------
-- Timing board (ox_target)
-- ---------------------------------------------------------------------
local function openBoard()
    local data = lib.callback.await('hubcity-dragrace:server:getBoard', false)
    if not data then
        lib.notify({ title = 'Drag Strip', description = 'The timing board is not answering.', type = 'error' })
        return
    end

    local lines = {}
    if data.personalBest then
        lines[#lines + 1] = ('**Your best:** %s in a %s at %s'):format(
            formatTime(data.personalBest.time_ms), data.personalBest.vehicle, formatSpeed(data.personalBest.speed))
        lines[#lines + 1] = ''
    else
        lines[#lines + 1] = 'You have no timed pass yet — go set one.'
        lines[#lines + 1] = ''
    end

    if data.top and #data.top > 0 then
        lines[#lines + 1] = '**Top times**'
        for i, row in ipairs(data.top) do
            lines[#lines + 1] = ('%d. %s — %s — %s (%s)'):format(
                i, row.name, formatTime(row.time_ms), formatSpeed(row.speed), row.vehicle)
        end
    else
        lines[#lines + 1] = 'No times on the board yet. Be the first.'
    end

    lib.alertDialog({
        header = 'Sandy Shores Drag Strip — Timing Board',
        content = table.concat(lines, '\n'),
        centered = true,
        cancel = false,
        labels = { confirm = 'Close' },
    })
end

CreateThread(function()
    exports.ox_target:addSphereZone({
        coords = Config.Board.coords,
        radius = Config.Board.radius,
        debug = false,
        options = {
            {
                name = 'hubcity_dragrace_board',
                icon = 'fa-solid fa-stopwatch',
                label = Config.Board.label,
                distance = 2.5,
                onSelect = openBoard,
            },
        },
    })
end)

-- ---------------------------------------------------------------------
-- Staging prompt loop (idle state only)
-- ---------------------------------------------------------------------
CreateThread(function()
    while true do
        local wait = 500
        if not staged and not countingDown and not racing then
            local veh = myVehicle()
            if veh ~= 0 then
                local pos = GetEntityCoords(veh)
                local nearLane = nil
                for lane = 1, 2 do
                    if #(pos - laneStagingPoint(lane)) <= Config.StageRadius then
                        nearLane = lane
                        break
                    end
                end

                if nearLane then
                    wait = 0
                    if promptLane ~= nearLane then
                        promptLane = nearLane
                        lib.showTextUI(('[E] — Stage for a drag race (Lane %d)'):format(nearLane))
                    end
                    if IsControlJustReleased(0, 38) then -- E
                        lib.hideTextUI()
                        promptLane = nil
                        TriggerServerEvent('hubcity-dragrace:server:stage', nearLane, VehToNet(veh))
                    end
                elseif promptLane then
                    promptLane = nil
                    lib.hideTextUI()
                end

                -- Ground markers at the staging boxes while nearby.
                if Config.DrawMarkers and #(pos - Config.StartLine) < 120.0 then
                    for lane = 1, 2 do
                        local p = laneStagingPoint(lane)
                        DrawMarker(1, p.x, p.y, p.z - 0.8, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            4.5, 4.5, 1.0, 255, 200, 0, 60, false, false, 2, false, nil, nil, false)
                    end
                end
            elseif promptLane then
                promptLane = nil
                lib.hideTextUI()
            end
        end
        Wait(wait)
    end
end)

-- ---------------------------------------------------------------------
-- Server-driven race events
-- ---------------------------------------------------------------------
RegisterNetEvent('hubcity-dragrace:client:staged', function(lane)
    staged = true
    myLane = lane
    raceVehicle = myVehicle()
    if raceVehicle ~= 0 then
        stagedPos = GetEntityCoords(raceVehicle)
        FreezeEntityPosition(raceVehicle, true)
        SetVehicleEngineOn(raceVehicle, true, true, false)
    end
    lib.notify({
        title = 'Drag Strip',
        description = ('You are staged in Lane %d. Hold tight — lights are coming. Press E to back out.'):format(lane),
        type = 'success',
        duration = 6000,
    })
end)

RegisterNetEvent('hubcity-dragrace:client:unstaged', function()
    staged = false
    myLane = nil
    releaseVehicle()
    raceVehicle = 0
    stagedPos = nil
    lib.notify({ title = 'Drag Strip', description = 'You backed out of the lane.', type = 'inform' })
end)

RegisterNetEvent('hubcity-dragrace:client:stageDenied', function(message)
    lib.notify({ title = 'Drag Strip', description = message, type = 'error' })
end)

RegisterNetEvent('hubcity-dragrace:client:countdown', function(durationMs)
    countingDown = true
    lastCountShown = nil
    countdownEndsAt = GetGameTimer() + durationMs
end)

RegisterNetEvent('hubcity-dragrace:client:go', function()
    -- The main loop flips into racing when its own countdown ends; this
    -- event is a belt-and-braces trigger in case of timer drift.
    if countingDown then
        countdownEndsAt = math.min(countdownEndsAt, GetGameTimer())
    end
end)

RegisterNetEvent('hubcity-dragrace:client:redLight', function()
    countingDown = false
    racing = false
    staged = false
    redLightUntil = GetGameTimer() + 4000
    releaseVehicle()
    lib.notify({
        title = 'RED LIGHT',
        description = 'False start — your run is void. Roll back and stage again.',
        type = 'error',
        duration = 8000,
    })
end)

RegisterNetEvent('hubcity-dragrace:client:results', function(res)
    staged = false
    countingDown = false
    racing = false
    releaseVehicle()
    raceVehicle = 0

    local lines = {}
    if res.youVoid then
        lines[#lines + 1] = 'You red-lit. No time recorded.'
    elseif res.yourTime then
        lines[#lines + 1] = ('**Your pass:** %s at %s'):format(formatTime(res.yourTime), formatSpeed(res.yourSpeed))
        if res.isPersonalBest then
            lines[#lines + 1] = '🏆 New personal best!'
        end
    else
        lines[#lines + 1] = 'You did not finish (DNF). No time recorded.'
    end

    if not res.solo then
        lines[#lines + 1] = ''
        if res.oppVoid then
            lines[#lines + 1] = ('%s red-lit their run.'):format(res.oppName or 'Your opponent')
        elseif res.oppTime then
            lines[#lines + 1] = ('**%s:** %s at %s'):format(res.oppName or 'Opponent', formatTime(res.oppTime), formatSpeed(res.oppSpeed))
        else
            lines[#lines + 1] = ('%s did not finish.'):format(res.oppName or 'Your opponent')
        end
        lines[#lines + 1] = ''
        if res.winnerName then
            lines[#lines + 1] = ('🏁 **Winner: %s**'):format(res.winnerName)
        else
            lines[#lines + 1] = '🏁 No winner this run.'
        end
    end

    lib.alertDialog({
        header = 'Sandy Shores Drag Strip — Results',
        content = table.concat(lines, '\n'),
        centered = true,
        cancel = false,
        labels = { confirm = 'Close' },
    })
end)

-- ---------------------------------------------------------------------
-- Main race loop: unstage key, countdown display + false-start watch,
-- then finish detection while racing.
-- ---------------------------------------------------------------------
CreateThread(function()
    while true do
        local wait = 250

        if staged and not countingDown and not racing then
            wait = 0
            -- Back out before the lights start.
            if IsControlJustReleased(0, 38) then -- E
                TriggerServerEvent('hubcity-dragrace:server:unstage')
            end
            -- Driver climbed out before the race: unstage.
            if myVehicle() == 0 then
                TriggerServerEvent('hubcity-dragrace:server:unstage')
            end
        elseif countingDown then
            wait = 0
            local now = GetGameTimer()
            local veh = myVehicle()

            if veh == 0 then
                -- Out of the car on the lights = false start.
                TriggerServerEvent('hubcity-dragrace:server:falseStart')
                countingDown = false
            else
                -- False start: moved off the staged spot before GO.
                if stagedPos and #(GetEntityCoords(veh) - stagedPos) > Config.FalseStartDistance then
                    TriggerServerEvent('hubcity-dragrace:server:falseStart')
                    countingDown = false
                else
                    local remaining = countdownEndsAt - now
                    if remaining > 0 then
                        local count = math.ceil(remaining / 1000.0)
                        if count ~= lastCountShown then
                            lastCountShown = count
                            PlaySoundFrontend(-1, '3_2_1', 'HUD_MINI_GAME_SOUNDSET', true)
                        end
                        drawCentreText(tostring(count), 255, 200, 0, 2.2)
                    else
                        -- GO!
                        countingDown = false
                        racing = true
                        goAt = now
                        goFlashUntil = now + 900
                        releaseVehicle()
                        PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)
                        drawCentreText('GO!', 0, 220, 0, 2.6)
                    end
                end
            end
        elseif racing then
            wait = 0
            local now = GetGameTimer()
            if now < goFlashUntil then
                drawCentreText('GO!', 0, 220, 0, 2.6)
            end

            local veh = myVehicle()
            if veh == 0 then
                racing = false
                TriggerServerEvent('hubcity-dragrace:server:dnf')
            else
                raceVehicle = veh
                -- Finish-line marker while running.
                if Config.DrawMarkers and myLane then
                    local f = finishPoint(myLane)
                    DrawMarker(1, f.x, f.y, f.z - 0.8, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        4.5, 4.5, 1.0, 0, 220, 0, 60, false, false, 2, false, nil, nil, false)
                end

                if progressAlongTrack(GetEntityCoords(veh)) >= trackLength() then
                    racing = false
                    local timeMs = GetGameTimer() - goAt
                    local speed = GetEntitySpeed(veh)
                    if Config.SpeedUnit == 'mph' then
                        speed = speed * 2.236936
                    else
                        speed = speed * 3.6
                    end
                    local label = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                    TriggerServerEvent('hubcity-dragrace:server:finish', timeMs, speed, label)
                    lib.notify({
                        title = 'Drag Strip',
                        description = ('You crossed at %s — trap speed %s.'):format(formatTime(timeMs), formatSpeed(speed)),
                        type = 'success',
                        duration = 6000,
                    })
                end
            end
        end

        -- Red light display (set by the server event above).
        if GetGameTimer() < redLightUntil then
            drawCentreText('RED LIGHT', 255, 30, 30, 2.4)
            wait = 0
        end

        Wait(wait)
    end
end)
