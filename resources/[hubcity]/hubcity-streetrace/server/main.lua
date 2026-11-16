-- Hub City Street Racing ("Need 2 Speed") — server.
--
-- All race state lives here. The ONLY way in is the Need 2 Speed app in
-- the tablet (hubcity-tablet bridges its NUI to the callbacks below).
-- There is no command, keybind or item for this resource — by design.
--
-- Flow: host creates a lobby in the app -> racers join -> host starts ->
-- everyone grids up at the route start -> countdown -> checkpoint race
-- with live standings -> finish -> results + records (hubcity_streetrace_
-- records). When the countdown starts, the blocker crew rolls out: every
-- client gets the route's blocker points and spawns the NPC roadblocks
-- near itself for the duration of the race.
--
-- Timing honesty: checkpoints are detected on each racer's client and
-- reported here; finish times are stamped on the server when the finish
-- report lands. Good enough for friendly street racing — this is not an
-- anti-cheat system.

local races = {}        -- raceId -> race table
local raceByPlayer = {} -- server id -> raceId
local lastResults = {}  -- citizenid -> { routeName, rows = {...} }
local nextRaceId = 1

-- Forward declarations (functions used inside threads/events below).
local endRace, cancelRace, beginCountdown

-- ── Helpers ────────────────────────────────────────────────────────────────

local function identity(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil, nil end
    local charinfo = player.PlayerData.charinfo or {}
    local name = ((charinfo.firstname or '') .. ' ' .. (charinfo.lastname or ''))
    name = name:gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then name = player.PlayerData.name or 'Unknown' end
    return player.PlayerData.citizenid, name
end

local function routeById(routeId)
    for _, route in ipairs(Config.Routes) do
        if route.id == routeId then return route end
    end
    return nil
end

local function playerCount(race)
    local n = 0
    for _ in pairs(race.players) do n = n + 1 end
    return n
end

local function broadcastLobbies()
    TriggerClientEvent('hubcity-streetrace:client:lobbiesChanged', -1)
end

local function blockersOff(race)
    if race.blockersOn then
        race.blockersOn = false
        TriggerClientEvent('hubcity-streetrace:client:blockersOff', -1, race.id)
    end
end

local function cleanupRace(race)
    for src in pairs(race.players) do
        if raceByPlayer[src] == race.id then raceByPlayer[src] = nil end
    end
    races[race.id] = nil
end

local function computeStandings(race)
    local list = {}
    for _, p in pairs(race.players) do list[#list + 1] = p end
    table.sort(list, function(a, b)
        if a.finished ~= b.finished then return a.finished end
        if a.finished and b.finished then return (a.position or 99) < (b.position or 99) end
        if a.cpIndex ~= b.cpIndex then return a.cpIndex > b.cpIndex end
        return (a.dist or 0) < (b.dist or 0)
    end)
    local positions = {}
    for i, p in ipairs(list) do positions[p.src] = i end
    return positions, #list
end

local function broadcastStandings(race)
    local positions, total = computeStandings(race)
    for src, p in pairs(race.players) do
        TriggerClientEvent('hubcity-streetrace:client:standings', src, {
            position = positions[src],
            total = total,
            cpIndex = p.cpIndex,
            cpTotal = #race.route.checkpoints,
            finished = p.finished,
        })
    end
end

local function allFinished(race)
    if playerCount(race) == 0 then return false end
    for _, p in pairs(race.players) do
        if not p.finished then return false end
    end
    return true
end

-- ── Race lifecycle ─────────────────────────────────────────────────────────

endRace = function(race, reason)
    if race.state == 'finished' then return end
    race.state = 'finished'

    local finishers, dnfs = {}, {}
    for _, p in pairs(race.players) do
        if p.finished then finishers[#finishers + 1] = p else dnfs[#dnfs + 1] = p end
    end
    table.sort(finishers, function(a, b) return (a.position or 99) < (b.position or 99) end)
    table.sort(dnfs, function(a, b) return a.name < b.name end)

    local rows = {}
    for _, p in ipairs(finishers) do
        rows[#rows + 1] = { citizenid = p.citizenid, name = p.name, position = p.position, timeMs = p.timeMs }
    end
    for _, p in ipairs(dnfs) do
        rows[#rows + 1] = { citizenid = p.citizenid, name = p.name, position = 0, timeMs = nil }
    end

    for _, row in ipairs(rows) do
        MySQL.insert.await(
            'INSERT INTO hubcity_streetrace_records (citizenid, name, route_id, route_name, position, time_ms, won) VALUES (?, ?, ?, ?, ?, ?, ?)',
            { row.citizenid, row.name, race.route.id, race.route.name, row.position, row.timeMs, row.position == 1 and 1 or 0 }
        )
        lastResults[row.citizenid] = { routeName = race.route.name, rows = rows }
    end

    for src, p in pairs(race.players) do
        local myRows = {}
        for _, row in ipairs(rows) do
            myRows[#myRows + 1] = {
                position = row.position,
                name = row.name,
                timeMs = row.timeMs,
                me = row.citizenid == p.citizenid,
            }
        end
        TriggerClientEvent('hubcity-streetrace:client:results', src, {
            routeName = race.route.name,
            rows = myRows,
            reason = reason,
        })
    end

    print(('[hubcity-streetrace] race #%d (%s) ended (%s) — %d finisher(s), %d DNF')
        :format(race.id, race.route.name, reason or 'complete', #finishers, #dnfs))
    blockersOff(race)
    cleanupRace(race)
    broadcastLobbies()
end

cancelRace = function(race, reason)
    if races[race.id] ~= race then return end
    for src in pairs(race.players) do
        TriggerClientEvent('hubcity-streetrace:client:raceCancelled', src, reason or 'Race cancelled.')
    end
    print(('[hubcity-streetrace] race #%d (%s) cancelled: %s')
        :format(race.id, race.route.name, reason or 'cancelled'))
    blockersOff(race)
    cleanupRace(race)
    broadcastLobbies()
end

beginCountdown = function(race)
    if race.state ~= 'grid' then return end
    race.state = 'countdown'

    -- The crew rolls out NOW, city-wide: every client gets the blocker
    -- points and spawns the ones near itself.
    race.blockersOn = true
    local blockers = {}
    for i, b in ipairs(race.route.blockers) do
        blockers[i] = {
            coords = { x = b.coords.x, y = b.coords.y, z = b.coords.z },
            heading = b.heading,
        }
    end
    TriggerClientEvent('hubcity-streetrace:client:blockersOn', -1, race.id, blockers)

    for src in pairs(race.players) do
        TriggerClientEvent('hubcity-streetrace:client:countdownStart', src, race.id)
    end

    CreateThread(function()
        for n = Config.CountdownSeconds, 1, -1 do
            if races[race.id] ~= race or race.state ~= 'countdown' then return end
            for src in pairs(race.players) do
                TriggerClientEvent('hubcity-streetrace:client:countdown', src, n)
            end
            Wait(1000)
        end
        if races[race.id] ~= race or race.state ~= 'countdown' then return end
        race.state = 'racing'
        race.startTime = GetGameTimer()
        race.deadline = os.time() + Config.RaceTimeoutMinutes * 60
        for src in pairs(race.players) do
            TriggerClientEvent('hubcity-streetrace:client:go', src, race.id)
        end
        print(('[hubcity-streetrace] race #%d (%s) is GO — %d racer(s)')
            :format(race.id, race.route.name, playerCount(race)))

        -- Standings ticker + race timeout, for the life of the race.
        while races[race.id] == race and race.state == 'racing' do
            broadcastStandings(race)
            if os.time() > race.deadline then
                endRace(race, 'timeout')
                return
            end
            Wait(2000)
        end
    end)
end

local function dropFromRace(race, src)
    race.players[src] = nil
    if raceByPlayer[src] == race.id then raceByPlayer[src] = nil end
end

-- ── App data (called from the tablet bridge) ───────────────────────────────

local function lobbyList()
    local out = {}
    for _, race in pairs(races) do
        if race.state == 'lobby' then
            out[#out + 1] = {
                id = race.id,
                routeId = race.route.id,
                routeName = race.route.name,
                hostName = race.hostName,
                players = playerCount(race),
                maxRacers = Config.MaxRacers,
            }
        end
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

local function myRaceFor(src)
    local raceId = raceByPlayer[src]
    if not raceId then return nil end
    local race = races[raceId]
    if not race then return nil end
    local names = {}
    for _, p in pairs(race.players) do names[#names + 1] = p.name end
    table.sort(names)
    return {
        id = race.id,
        routeName = race.route.name,
        state = race.state,
        isHost = race.hostSrc == src,
        players = names,
        maxRacers = Config.MaxRacers,
        minRacers = Config.MinRacers,
    }
end

local function recordsView()
    local rows = MySQL.query.await([[
        SELECT route_id, route_name, citizenid, name,
               COUNT(*) AS races, SUM(won) AS wins, MIN(time_ms) AS best_ms
        FROM hubcity_streetrace_records
        GROUP BY route_id, citizenid
        ORDER BY wins DESC, best_ms ASC
    ]]) or {}
    local byRoute, order = {}, {}
    for _, r in ipairs(rows) do
        if not byRoute[r.route_id] then
            byRoute[r.route_id] = { routeName = r.route_name, rows = {} }
            order[#order + 1] = r.route_id
        end
        local list = byRoute[r.route_id].rows
        if #list < 5 then
            list[#list + 1] = {
                name = r.name,
                wins = tonumber(r.wins) or 0,
                races = tonumber(r.races) or 0,
                bestMs = r.best_ms and tonumber(r.best_ms) or nil,
            }
        end
    end
    local out = {}
    for _, routeId in ipairs(order) do out[#out + 1] = byRoute[routeId] end
    return out
end

lib.callback.register('hubcity-streetrace:server:getData', function(src)
    local citizenid = identity(src)
    local routes = {}
    for _, route in ipairs(Config.Routes) do
        routes[#routes + 1] = {
            id = route.id,
            name = route.name,
            description = route.description,
            checkpoints = #route.checkpoints,
        }
    end
    local last = nil
    local mine = citizenid and lastResults[citizenid] or nil
    if mine then
        local rows = {}
        for _, row in ipairs(mine.rows) do
            rows[#rows + 1] = {
                position = row.position,
                name = row.name,
                timeMs = row.timeMs,
                me = row.citizenid == citizenid,
            }
        end
        last = { routeName = mine.routeName, rows = rows }
    end
    return {
        routes = routes,
        races = lobbyList(),
        myRace = myRaceFor(src),
        records = recordsView(),
        lastResults = last,
    }
end)

-- ── App actions ────────────────────────────────────────────────────────────

lib.callback.register('hubcity-streetrace:server:createRace', function(src, routeId)
    local citizenid, name = identity(src)
    if not citizenid then return { ok = false, message = 'Something went wrong.' } end
    if raceByPlayer[src] then
        return { ok = false, message = 'You are already in a race. Leave it first.' }
    end
    local route = routeById(routeId)
    if not route then return { ok = false, message = 'That route is not on the board.' } end

    local id = nextRaceId
    nextRaceId = nextRaceId + 1
    local race = {
        id = id,
        route = route,
        hostSrc = src,
        hostName = name,
        state = 'lobby',
        players = {},
        finishCount = 0,
        blockersOn = false,
        createdAt = os.time(),
    }
    race.players[src] = {
        src = src, citizenid = citizenid, name = name,
        cpIndex = 1, dist = 0.0, finished = false, grid = false,
    }
    races[id] = race
    raceByPlayer[src] = id
    broadcastLobbies()
    print(('[hubcity-streetrace] lobby #%d opened by %s — %s'):format(id, name, route.name))

    CreateThread(function()
        Wait(Config.LobbyTimeoutMinutes * 60000)
        if races[id] == race and race.state == 'lobby' then
            cancelRace(race, 'The lobby sat too long and fell apart.')
        end
    end)

    return { ok = true, message = ('Lobby open for %s. Racers join from the Need 2 Speed app.'):format(route.name) }
end)

lib.callback.register('hubcity-streetrace:server:joinRace', function(src, raceId)
    local citizenid, name = identity(src)
    if not citizenid then return { ok = false, message = 'Something went wrong.' } end
    if raceByPlayer[src] then
        return { ok = false, message = 'You are already in a race. Leave it first.' }
    end
    local race = races[tonumber(raceId) or 0]
    if not race or race.state ~= 'lobby' then
        return { ok = false, message = 'That lobby is gone.' }
    end
    if playerCount(race) >= Config.MaxRacers then
        return { ok = false, message = 'That grid is full.' }
    end
    race.players[src] = {
        src = src, citizenid = citizenid, name = name,
        cpIndex = 1, dist = 0.0, finished = false, grid = false,
    }
    raceByPlayer[src] = race.id
    broadcastLobbies()
    print(('[hubcity-streetrace] %s joined lobby #%d (%s)'):format(name, race.id, race.route.name))
    return { ok = true, message = ('You are in — %s. Wait for the host to start.'):format(race.route.name) }
end)

lib.callback.register('hubcity-streetrace:server:leaveRace', function(src)
    local raceId = raceByPlayer[src]
    if not raceId then return { ok = false, message = 'You are not in a race.' } end
    local race = races[raceId]
    if not race then
        raceByPlayer[src] = nil
        return { ok = true, message = 'Left.' }
    end
    if race.state == 'lobby' and race.hostSrc == src then
        cancelRace(race, 'The host pulled the plug on the lobby.')
        return { ok = true, message = 'Lobby closed.' }
    end
    dropFromRace(race, src)
    TriggerClientEvent('hubcity-streetrace:client:raceCancelled', src, 'You left the race.')
    if playerCount(race) == 0 then
        blockersOff(race)
        cleanupRace(race)
    elseif race.state == 'racing' and allFinished(race) then
        endRace(race, 'complete')
    end
    broadcastLobbies()
    return { ok = true, message = 'Left the race.' }
end)

lib.callback.register('hubcity-streetrace:server:cancelRace', function(src)
    local raceId = raceByPlayer[src]
    if not raceId then return { ok = false, message = 'You are not in a race.' } end
    local race = races[raceId]
    if not race then
        raceByPlayer[src] = nil
        return { ok = true, message = 'Already gone.' }
    end
    if race.hostSrc ~= src then
        return { ok = false, message = 'Only the host can cancel. You can leave instead.' }
    end
    cancelRace(race, 'The host cancelled the race.')
    return { ok = true, message = 'Race cancelled.' }
end)

lib.callback.register('hubcity-streetrace:server:startRace', function(src)
    local raceId = raceByPlayer[src]
    if not raceId then return { ok = false, message = 'You are not in a race.' } end
    local race = races[raceId]
    if not race or race.state ~= 'lobby' then
        return { ok = false, message = 'That race is not in a lobby.' }
    end
    if race.hostSrc ~= src then
        return { ok = false, message = 'Only the host can start the race.' }
    end
    if playerCount(race) < Config.MinRacers then
        return { ok = false, message = ('Need at least %d racer(s) on the grid.'):format(Config.MinRacers) }
    end

    race.state = 'grid'
    race.gridDeadline = os.time() + Config.GridTimeoutSeconds
    local start = race.route.start
    local checkpoints = {}
    for i, cp in ipairs(race.route.checkpoints) do
        checkpoints[i] = { x = cp.x, y = cp.y, z = cp.z }
    end
    for racerSrc in pairs(race.players) do
        TriggerClientEvent('hubcity-streetrace:client:raceData', racerSrc, {
            raceId = race.id,
            routeName = race.route.name,
            start = { x = start.x, y = start.y, z = start.z, heading = start.w or 0.0 },
            checkpoints = checkpoints,
        })
    end
    broadcastLobbies()
    print(('[hubcity-streetrace] race #%d (%s) sent to grid — %d racer(s)')
        :format(race.id, race.route.name, playerCount(race)))

    -- Grid deadline: drop anyone who never showed, then go (or fold).
    CreateThread(function()
        while races[race.id] == race and race.state == 'grid' do
            if os.time() > race.gridDeadline then
                local dropped = {}
                for racerSrc, p in pairs(race.players) do
                    if not p.grid then dropped[#dropped + 1] = racerSrc end
                end
                for _, racerSrc in ipairs(dropped) do
                    dropFromRace(race, racerSrc)
                    TriggerClientEvent('hubcity-streetrace:client:raceCancelled', racerSrc,
                        'You never made it to the grid.')
                end
                if playerCount(race) == 0 then
                    cancelRace(race, 'Nobody made it to the grid.')
                else
                    beginCountdown(race)
                end
                return
            end
            Wait(1000)
        end
    end)

    return { ok = true, message = 'Grid is open — the start line is on everyone\'s GPS.' }
end)

-- ── In-race client reports ─────────────────────────────────────────────────

RegisterNetEvent('hubcity-streetrace:server:gridReady', function()
    local src = source
    local raceId = raceByPlayer[src]
    if not raceId then return end
    local race = races[raceId]
    if not race or race.state ~= 'grid' then return end
    local p = race.players[src]
    if not p then return end
    p.grid = true
    for _, q in pairs(race.players) do
        if not q.grid then return end
    end
    beginCountdown(race)
end)

RegisterNetEvent('hubcity-streetrace:server:progress', function(cpIndex, dist)
    local src = source
    local raceId = raceByPlayer[src]
    if not raceId then return end
    local race = races[raceId]
    if not race or race.state ~= 'racing' then return end
    local p = race.players[src]
    if not p or p.finished then return end
    local idx = math.floor(tonumber(cpIndex) or p.cpIndex)
    if idx < p.cpIndex then idx = p.cpIndex end
    local maxIdx = #race.route.checkpoints + 1
    if idx > maxIdx then idx = maxIdx end
    p.cpIndex = idx
    p.dist = tonumber(dist) or 0.0
end)

RegisterNetEvent('hubcity-streetrace:server:finished', function()
    local src = source
    local raceId = raceByPlayer[src]
    if not raceId then return end
    local race = races[raceId]
    if not race or race.state ~= 'racing' then return end
    local p = race.players[src]
    if not p or p.finished then return end
    p.finished = true
    race.finishCount = race.finishCount + 1
    p.position = race.finishCount
    p.timeMs = GetGameTimer() - race.startTime
    broadcastStandings(race)
    if allFinished(race) then
        endRace(race, 'complete')
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local raceId = raceByPlayer[src]
    if not raceId then return end
    local race = races[raceId]
    if not race then
        raceByPlayer[src] = nil
        return
    end
    if race.state == 'lobby' and race.hostSrc == src then
        cancelRace(race, 'The host left.')
        return
    end
    dropFromRace(race, src)
    if playerCount(race) == 0 then
        blockersOff(race)
        cleanupRace(race)
        broadcastLobbies()
    elseif race.state == 'racing' and allFinished(race) then
        endRace(race, 'complete')
    else
        broadcastLobbies()
    end
end)

-- ── Lifecycle ──────────────────────────────────────────────────────────────

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `hubcity_streetrace_records` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(50) NOT NULL,
            `name` VARCHAR(80) NOT NULL,
            `route_id` VARCHAR(40) NOT NULL,
            `route_name` VARCHAR(80) NOT NULL,
            `position` INT NOT NULL DEFAULT 0,
            `time_ms` INT NULL,
            `won` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_sr_route` (`route_id`),
            INDEX `idx_sr_citizen` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    print(('[hubcity-streetrace] Need 2 Speed live — %d routes on the board'):format(#Config.Routes))
end)
