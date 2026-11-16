-- =====================================================================
--  Hub City Laundering — server
--  Rotation is derived from the clock (like the black market dealers),
--  so hubcity-tablet can advertise the same active spot(s) through the
--  GetActiveWashInfo export. Wash sessions live in memory: a resource
--  or server restart loses an in-progress wash (see RISKS).
--  All amounts come from item metadata read server-side — the client
--  never names a number.
-- =====================================================================

local sessions = {} -- citizenid -> { gross, fee, net, readyAt, spotIndex }

local function activeIndices()
    local slot = math.floor(os.time() / (Config.RotationMinutes * 60))
    local out = {}
    for i = 0, (Config.ActiveSpots or 1) - 1 do
        out[#out + 1] = ((slot + i) % #Config.Spots) + 1
    end
    return out
end

local function isActive(idx)
    for _, a in ipairs(activeIndices()) do if a == idx then return true end end
    return false
end

--- Used by hubcity-tablet to advertise the wash in the Black Market app.
exports('GetActiveWashInfo', function()
    local out = {}
    for _, idx in ipairs(activeIndices()) do
        out[#out + 1] = {
            neighborhood = Config.Spots[idx].neighborhood,
            feePercent = Config.WashFeePercent,
            processingMinutes = Config.ProcessingMinutes,
        }
    end
    return out
end)

lib.callback.register('hubcity-laundering:getActiveSpots', function(_)
    local out = {}
    for _, idx in ipairs(activeIndices()) do
        local s = Config.Spots[idx]
        out[#out + 1] = { index = idx, coords = s.coords, heading = s.heading, ped = s.ped }
    end
    return out
end)

lib.callback.register('hubcity-laundering:getMyWash', function(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return nil end
    local s = sessions[Player.PlayerData.citizenid]
    if not s then return nil end
    return {
        net = s.net,
        ready = os.time() >= s.readyAt,
        minutesLeft = math.max(0, math.ceil((s.readyAt - os.time()) / 60)),
        spotIndex = s.spotIndex,
    }
end)

lib.callback.register('hubcity-laundering:startWash', function(source, spotIndex)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return { ok = false, message = 'Player not found.' } end
    local cid = Player.PlayerData.citizenid
    local spot = Config.Spots[spotIndex]
    if not spot or not isActive(spotIndex) then
        return { ok = false, message = 'Nobody is washing here right now.' }
    end
    -- Proximity validation (server-side)
    local ped = GetPlayerPed(source)
    if ped == 0 then return { ok = false, message = 'Try again.' } end
    local pcoords = GetEntityCoords(ped)
    if #(pcoords - spot.coords) > 15.0 then
        return { ok = false, message = 'You are not at the wash spot.' }
    end
    if sessions[cid] then
        return { ok = false, message = 'You already have a wash running. One at a time.' }
    end

    -- Read the player's marked bills + worth from metadata (server-side)
    local slots = exports.ox_inventory:Search(source, 'slots', Config.DirtyItem) or {}
    local taken, gross = 0, 0
    for _, item in ipairs(slots) do
        local worth = 0
        if item.metadata then
            worth = item.metadata.worth or (item.metadata.info and item.metadata.info.worth) or 0
        end
        worth = math.floor(tonumber(worth) or 0)
        if worth > 0 and gross + worth <= Config.SessionLimit then
            if exports.ox_inventory:RemoveItem(source, Config.DirtyItem, 1, nil, item.slot) then
                taken = taken + 1
                gross = gross + worth
            end
        end
    end
    if taken == 0 or gross <= 0 then
        return { ok = false, message = 'You have no marked bills worth washing (or they exceed the session limit).' }
    end

    local fee = math.floor(gross * Config.WashFeePercent / 100 + 0.5)
    local net = gross - fee
    sessions[cid] = {
        gross = gross, fee = fee, net = net,
        readyAt = os.time() + Config.ProcessingMinutes * 60,
        spotIndex = spotIndex,
    }

    if Config.PoliceAlert.Enabled and math.random(1, 100) <= Config.PoliceAlert.ChancePercent then
        -- Hook for dispatch integration (ps-dispatch / qbx police alerts):
        -- wire this event to the server's dispatch in a small bridge.
        TriggerEvent('hubcity-laundering:server:policeAlert', spot.coords, spot.neighborhood)
        print(('[hubcity-laundering] police alert rolled at %s'):format(spot.neighborhood))
    end

    return { ok = true, message = ('Washing $%d of marked bills. Fee $%d. Come back in ~%d minutes to collect $%d clean.'):format(
        gross, fee, Config.ProcessingMinutes, net), net = net, minutes = Config.ProcessingMinutes }
end)

lib.callback.register('hubcity-laundering:collectWash', function(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return { ok = false, message = 'Player not found.' } end
    local cid = Player.PlayerData.citizenid
    local s = sessions[cid]
    if not s then return { ok = false, message = 'You have nothing being washed.' } end
    if os.time() < s.readyAt then
        return { ok = false, message = ('Still washing — about %d minute(s) left.'):format(math.max(1, math.ceil((s.readyAt - os.time()) / 60))) }
    end
    -- Must collect at the same spot where the wash started
    local spot = Config.Spots[s.spotIndex]
    local ped = GetPlayerPed(source)
    if ped == 0 or #(GetEntityCoords(ped) - spot.coords) > 15.0 then
        return { ok = false, message = 'Collect from the same spot where you dropped the bills off.' }
    end
    sessions[cid] = nil
    Player.Functions.AddMoney('bank', s.net, 'hubcity-laundered-money')
    return { ok = true, message = ('$%d clean money deposited to your bank.'):format(s.net) }
end)
