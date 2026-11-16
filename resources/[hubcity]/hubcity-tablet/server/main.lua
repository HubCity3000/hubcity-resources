-- Hub City Tablet / Black Market — server. DEAL-FIRST design:
--
-- Nobody buys by walking up. A player builds an order in the tablet app and
-- submits a deal request. The dealer agrees (Config.DealAgreeChance, stock
-- permitting) or passes. An agreed deal is stored in `hubcity_deals` with
-- its items, total, assigned location (the currently active dealer spot)
-- and expiry. The exchange can ONLY be completed in person at that spot.
-- Rotation is computed from the clock: active index =
-- floor(now / rotation) % dealerCount — no stored state, restarts agree.
-- An agreed deal keeps its own location even if rotation moves on.

local stock = {} -- stock[dealerIndex][item] = count (reserved by agreed deals)
local lastActiveKey = nil

local function activeKey()
    return math.floor(os.time() / (Config.RotationMinutes * 60))
end

local function activeIndexes()
    if Config.AllDealersActive then
        local all = {}
        for i = 1, #Config.Dealers do all[#all + 1] = i end
        return all
    end
    return { (activeKey() % #Config.Dealers) + 1 }
end

local function assignDealerIndex()
    local actives = activeIndexes()
    return actives[math.random(#actives)]
end

local function restock(idx)
    stock[idx] = {}
    for _, entry in ipairs(Config.Catalog) do
        stock[idx][entry.item] = entry.stock
    end
end

local function releaseReservation(deal)
    local items = json.decode(deal.items or '[]') or {}
    local idx = deal.dealer_index
    if not stock[idx] then restock(idx) end
    for _, line in ipairs(items) do
        local entry = nil
        for _, e in ipairs(Config.Catalog) do if e.item == line.item then entry = e end end
        local cap = entry and entry.stock or line.amount
        stock[idx][line.item] = math.min(((stock[idx][line.item]) or 0) + line.amount, cap)
    end
end

local function catalogEntry(item)
    for _, entry in ipairs(Config.Catalog) do
        if entry.item == item then return entry end
    end
    return nil
end

local function playerNearDealer(src, idx)
    local dealer = Config.Dealers[idx]
    if not dealer then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - dealer.coords) < 10.0
end

local function getActiveDeal(citizenid)
    return MySQL.single.await(
        'SELECT * FROM hubcity_deals WHERE citizenid = ? AND status = ? LIMIT 1',
        { citizenid, 'agreed' }
    )
end

local function expireDeal(deal, notifyPlayer)
    MySQL.update.await('UPDATE hubcity_deals SET status = ? WHERE id = ? AND status = ?',
        { 'expired', deal.id, 'agreed' })
    releaseReservation(deal)
    if notifyPlayer then
        for _, playerId in ipairs(GetPlayers()) do
            local p = exports.qbx_core:GetPlayer(tonumber(playerId))
            if p and p.PlayerData.citizenid == deal.citizenid then
                TriggerClientEvent('hubcity-tablet:client:dealExpired', playerId)
                break
            end
        end
    end
    print(('[hubcity-tablet] deal #%s expired for %s — reservation released'):format(deal.id, deal.citizenid))
end

-- ── Lifecycle: stock, rotation watcher, expiry sweeper ─────────────────────

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `hubcity_deals` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(50) NOT NULL,
            `dealer_index` INT NOT NULL,
            `items` TEXT NOT NULL,
            `total` INT NOT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'agreed',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `expires_at` BIGINT NOT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_citizen_status` (`citizenid`, `status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

CreateThread(function()
    for i = 1, #Config.Dealers do restock(i) end
    lastActiveKey = activeKey()
    Wait(2000)
    TriggerClientEvent('hubcity-tablet:client:setActiveDealers', -1, activeIndexes())
    print(('[hubcity-tablet] black market live — new deals point at: %s (rotation every %d min)')
        :format(Config.Dealers[activeIndexes()[1]].name, Config.RotationMinutes))
    while true do
        Wait(30000)
        local key = activeKey()
        if key ~= lastActiveKey then
            lastActiveKey = key
            if not Config.AllDealersActive then
                restock(activeIndexes()[1])
            end
            TriggerClientEvent('hubcity-tablet:client:setActiveDealers', -1, activeIndexes())
            print(('[hubcity-tablet] dealer rotated — new deals point at: %s'):format(Config.Dealers[activeIndexes()[1]].name))
        end
        -- Expiry sweep
        local stale = MySQL.query.await(
            'SELECT * FROM hubcity_deals WHERE status = ? AND expires_at < ?',
            { 'agreed', os.time() }
        ) or {}
        for _, deal in ipairs(stale) do
            expireDeal(deal, true)
        end
    end
end)

RegisterNetEvent('hubcity-tablet:server:requestDealers', function()
    TriggerClientEvent('hubcity-tablet:client:setActiveDealers', source, activeIndexes())
end)

-- ── Callbacks used by the tablet app ───────────────────────────────────────

-- The tablet shows only the neighborhood name. No coords, no blip — by design.
lib.callback.register('hubcity-tablet:server:getHotSpot', function()
    if Config.AllDealersActive then return nil end
    return Config.Dealers[activeIndexes()[1]].name
end)

-- Laundering advertisement: hubcity-laundering's active wash spot(s) are
-- advertised ONLY here, inside the Black Market app (neighborhood + fee).
lib.callback.register('hubcity-tablet:server:getLaundering', function()
    if GetResourceState('hubcity-laundering') ~= 'started' then return nil end
    local ok, info = pcall(function() return exports['hubcity-laundering']:GetActiveWashInfo() end)
    if ok then return info end
    return nil
end)

lib.callback.register('hubcity-tablet:server:getMyDeal', function(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil end
    local deal = getActiveDeal(player.PlayerData.citizenid)
    if not deal then return nil end
    if deal.expires_at < os.time() then
        expireDeal(deal, false)
        return nil
    end
    return {
        items = json.decode(deal.items),
        total = deal.total,
        neighborhood = Config.Dealers[deal.dealer_index].name,
        minutesLeft = math.max(0, math.floor((deal.expires_at - os.time()) / 60)),
    }
end)

lib.callback.register('hubcity-tablet:server:submitDeal', function(src, order)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return { state = 'error', message = 'Something went wrong.' } end
    local citizenid = player.PlayerData.citizenid

    if type(order) ~= 'table' or #order == 0 then
        return { state = 'error', message = 'Your order is empty.' }
    end

    -- One active deal per player.
    local existing = getActiveDeal(citizenid)
    if existing then
        if existing.expires_at < os.time() then
            expireDeal(existing, false)
        else
            return { state = 'already', message = 'You already have a deal in. Finish it or let it expire first.' }
        end
    end

    -- Validate the order against the catalog.
    local idx = assignDealerIndex()
    if not stock[idx] then restock(idx) end
    local lines = {}
    for _, line in ipairs(order) do
        local entry = catalogEntry(line.item)
        local amount = math.floor(tonumber(line.amount) or 0)
        if not entry or amount < 1 or amount > 99 then
            return { state = 'error', message = 'Something in that order is not for sale.' }
        end
        lines[#lines + 1] = { entry = entry, amount = amount }
    end

    -- Stock check at the assigned dealer.
    for _, line in ipairs(lines) do
        if line.amount > (stock[idx][line.entry.item] or 0) then
            return { state = 'passed', message = 'The dealer passes — not enough stock for that order right now.' }
        end
    end

    -- The dealer's call.
    if math.random() > Config.DealAgreeChance then
        return { state = 'passed', message = 'The dealer passes. Try again later, or trim the order.' }
    end

    -- Price the deal (optional variance), reserve the stock, store the deal.
    local variance = 1.0
    if Config.PriceVariancePercent and Config.PriceVariancePercent > 0 then
        variance = 1.0 + (math.random(-Config.PriceVariancePercent, Config.PriceVariancePercent) / 100.0)
    end
    local total = 0
    local storedItems = {}
    for _, line in ipairs(lines) do
        local unit = math.max(1, math.floor(line.entry.price * variance + 0.5))
        total = total + unit * line.amount
        stock[idx][line.entry.item] = stock[idx][line.entry.item] - line.amount
        storedItems[#storedItems + 1] = { item = line.entry.item, label = line.entry.label, amount = line.amount, unitPrice = unit }
    end

    local expiresAt = os.time() + Config.DealWindowMinutes * 60
    MySQL.insert.await(
        'INSERT INTO hubcity_deals (citizenid, dealer_index, items, total, status, expires_at) VALUES (?, ?, ?, ?, ?, ?)',
        { citizenid, idx, json.encode(storedItems), total, 'agreed', expiresAt }
    )

    print(('[hubcity-tablet] deal agreed: %s -> %s, $%d, %d min window')
        :format(citizenid, Config.Dealers[idx].name, total, Config.DealWindowMinutes))
    return {
        state = 'agreed',
        message = 'Deal agreed.',
        deal = {
            items = storedItems,
            total = total,
            neighborhood = Config.Dealers[idx].name,
            minutesLeft = Config.DealWindowMinutes,
        },
    }
end)

-- ── In-person completion at the dealer ─────────────────────────────────────

lib.callback.register('hubcity-tablet:server:getDealForDealer', function(src, idx)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil end
    local deal = getActiveDeal(player.PlayerData.citizenid)
    if not deal or deal.dealer_index ~= idx then return nil end
    if deal.expires_at < os.time() then
        expireDeal(deal, false)
        return nil
    end
    return {
        items = json.decode(deal.items),
        total = deal.total,
        minutesLeft = math.max(0, math.floor((deal.expires_at - os.time()) / 60)),
    }
end)

lib.callback.register('hubcity-tablet:server:completeDeal', function(src, idx)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false, 'Something went wrong.' end
    local citizenid = player.PlayerData.citizenid

    local deal = getActiveDeal(citizenid)
    if not deal or deal.dealer_index ~= idx then
        return false, "Deals go through the app. I don't know you."
    end
    if deal.expires_at < os.time() then
        expireDeal(deal, false)
        return false, 'Too late — that deal expired. Submit a new one in the app.'
    end
    if not playerNearDealer(src, idx) then
        return false, 'You need to be at the dealer.'
    end

    local items = json.decode(deal.items) or {}

    -- Room check BEFORE money moves.
    for _, line in ipairs(items) do
        if not exports.ox_inventory:CanCarryItem(src, line.item, line.amount) then
            return false, 'No room in your pockets. Deal is still on — come back lighter.'
        end
    end

    if player.PlayerData.money.cash < deal.total then
        return false, ('You need $%d cash on you. Deal is still on — go get it.'):format(deal.total)
    end
    if not player.Functions.RemoveMoney('cash', deal.total, 'hubcity-blackmarket-deal') then
        return false, 'Payment failed. Deal is still on.'
    end

    for _, line in ipairs(items) do
        exports.ox_inventory:AddItem(src, line.item, line.amount)
    end

    MySQL.update.await('UPDATE hubcity_deals SET status = ? WHERE id = ?', { 'completed', deal.id })
    print(('[hubcity-tablet] deal #%s completed: %s paid $%d at %s')
        :format(deal.id, citizenid, deal.total, Config.Dealers[idx].name))
    return true, ('Deal done. $%d paid. Walk away.'):format(deal.total)
end)
