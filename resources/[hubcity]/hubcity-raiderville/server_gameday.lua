-- Raiderville Stadium — GAME DAY schedule (server side).
--
-- The server alone decides whether today is a game day and broadcasts it;
-- clients only render what they're told ('hubcity-raiderville:client:setGameDay').
--
-- Schedule: every OTHER calendar day, counting from an anchor date.
--   * Anchor priority: Config.GameDay.AnchorDate (if set) > stored KVP > today.
--   * The anchor is persisted with SetResourceKvp, so the rhythm survives
--     server restarts and resource restarts.
--   * "Today" is the SERVER PC's local date (os.date) — keep the PC clock on
--     America/Chicago and game days flip at Central midnight.
--   * A manual override (console command, below) is also stored in KVP.
--
-- Console command (txAdmin console, or in-game with ace 'command.raiderville'):
--   raiderville gameday on      force game day until changed
--   raiderville gameday off     force quiet day until changed
--   raiderville gameday auto    back to the every-other-day schedule
--   raiderville gameday status  print anchor / today / state to the console

local KVP_ANCHOR = 'hubcity-raiderville:anchorDate'
local KVP_OVERRIDE = 'hubcity-raiderville:gamedayOverride'
local EVENT_CLIENT = 'hubcity-raiderville:client:setGameDay'
local EVENT_REQUEST = 'hubcity-raiderville:server:requestState'

-- Days since 1970-01-01 for a 'YYYY-MM-DD' string (civil date algorithm —
-- pure arithmetic, no timezone tables involved).
local function dayNumber(dateStr)
    local y, m, d = dateStr:match('(%d+)-(%d+)-(%d+)')
    if not y then return nil end
    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    if m <= 2 then y = y - 1; m = m + 12 end
    local era = math.floor(y / 400)
    local yoe = y - era * 400
    local mp = m - 3
    local doy = math.floor((153 * mp + 2) / 5) + d - 1
    local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
    return era * 146097 + doe - 719468
end

local function todayString()
    return os.date('%Y-%m-%d')
end

local function resolveAnchor()
    local cfgAnchor = Config.GameDay and Config.GameDay.AnchorDate
    if cfgAnchor and dayNumber(cfgAnchor) then
        if GetResourceKvpString(KVP_ANCHOR) ~= cfgAnchor then
            SetResourceKvp(KVP_ANCHOR, cfgAnchor)
        end
        return cfgAnchor
    end
    local stored = GetResourceKvpString(KVP_ANCHOR)
    if stored and dayNumber(stored) then
        return stored
    end
    local today = todayString()
    SetResourceKvp(KVP_ANCHOR, today)
    return today
end

local function getOverride()
    local ov = GetResourceKvpString(KVP_OVERRIDE)
    if ov == 'on' then return true end
    if ov == 'off' then return false end
    return nil
end

local function computeGameDay()
    if not (Config.GameDay and Config.GameDay.Enabled) then return false end
    local ov = getOverride()
    if ov ~= nil then return ov end
    local anchor = dayNumber(resolveAnchor())
    local today = dayNumber(todayString())
    if not anchor or not today then return false end
    return ((today - anchor) % 2) == 0
end

local currentState = nil

local function announce(target)
    local msg = Config.GameDay and Config.GameDay.AnnounceMessage
    if not msg then return end
    TriggerClientEvent('chat:addMessage', target, {
        color = { 204, 0, 0 },
        multiline = true,
        args = { 'Raiderville', msg },
    })
end

local function broadcast(state, withAnnouncement)
    TriggerClientEvent(EVENT_CLIENT, -1, state)
    if state and withAnnouncement then
        announce(-1)
    end
end

local function refresh(reason)
    local state = computeGameDay()
    if currentState == nil then
        currentState = state
        broadcast(state, state) -- announce at server start if it's a game day
        print(('[hubcity-raiderville] game day state: %s (anchor %s, today %s, %s)')
            :format(state and 'GAME DAY' or 'quiet', resolveAnchor(), todayString(), reason))
    elseif state ~= currentState then
        currentState = state
        broadcast(state, state)
        print(('[hubcity-raiderville] game day flipped -> %s (%s)')
            :format(state and 'GAME DAY' or 'quiet', reason))
    end
    return state
end

-- Clients ask for the state when they load; late joiners on a game day also
-- get the announcement once, so they know why the lots are full.
RegisterNetEvent(EVENT_REQUEST, function()
    local src = source
    local state = currentState
    if state == nil then state = refresh('first request') end
    TriggerClientEvent(EVENT_CLIENT, src, state)
    if state then announce(src) end
end)

CreateThread(function()
    Wait(2000)
    refresh('resource start')
    while true do
        Wait(60000) -- re-check every minute; flips happen at local midnight
        refresh('schedule tick')
    end
end)

RegisterCommand('raiderville', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'command.raiderville') then
        return
    end
    local function reply(text)
        print('[hubcity-raiderville] ' .. text)
        if source ~= 0 then
            TriggerClientEvent('chat:addMessage', source, { args = { 'Raiderville', text } })
        end
    end

    if args[1] ~= 'gameday' or not args[2] then
        reply('usage: raiderville gameday on|off|auto|status')
        return
    end

    local mode = args[2]:lower()
    if mode == 'on' or mode == 'off' then
        SetResourceKvp(KVP_OVERRIDE, mode)
        currentState = nil -- force re-broadcast on next refresh
        local state = refresh('manual override: ' .. mode)
        reply(('game day override set to %s — today is now %s'):format(mode:upper(), state and 'GAME DAY' or 'quiet'))
    elseif mode == 'auto' then
        DeleteResourceKvp(KVP_OVERRIDE)
        currentState = nil
        local state = refresh('manual override cleared')
        reply(('game day back on AUTO schedule — today is %s'):format(state and 'GAME DAY' or 'quiet'))
    elseif mode == 'status' then
        local ov = GetResourceKvpString(KVP_OVERRIDE)
        reply(('anchor=%s today=%s override=%s state=%s'):format(
            resolveAnchor(), todayString(), ov or 'auto',
            computeGameDay() and 'GAME DAY' or 'quiet'))
    else
        reply('usage: raiderville gameday on|off|auto|status')
    end
end, true)
