-- Hub City NOOSE — server.
-- Undercover department tooling: the CI registry and the tip queue.
--
-- SECRECY MODEL (the whole point of this resource):
--   * Every callback re-checks the caller's job AND grade on the server.
--     The client deciding to *show* a menu proves nothing.
--   * CI rows and tip contents are only ever sent to clients whose grade
--     clears the matching Config.Permissions entry.
--   * Real identities (name / citizenid / who handles whom) are only
--     included when the caller clears SeeIdentity (Director). Below
--     that, everything is codenames — even to the CI's own handler.
--   * A CI's own status call returns only their own codename, and it's
--     also how offline tip payouts get delivered (see getMyStatus).

local function clean(value, maxLen)
    if type(value) ~= 'string' then return nil end
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    if value == '' then return nil end
    if #value > maxLen then value = value:sub(1, maxLen) end
    return value
end

--- The qbx player object + grade level if src holds the NOOSE job, else nil.
local function getOfficer(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil end
    local job = player.PlayerData.job
    if not job or job.name ~= Config.JobName then return nil end
    return player, (job.grade and job.grade.level) or 0
end

local function getActiveCI(citizenid)
    return MySQL.single.await(
        'SELECT * FROM hubcity_ci WHERE citizenid = ? AND status = ? LIMIT 1',
        { citizenid, 'active' }
    )
end

local function generateCodename()
    local words = Config.CodenameWords
    for _ = 1, 10 do
        local codename = ('%s %s %s'):format(
            words.adjectives[math.random(#words.adjectives)],
            words.nouns[math.random(#words.nouns)],
            math.random(10, 99)
        )
        local clash = MySQL.scalar.await(
            'SELECT id FROM hubcity_ci WHERE codename = ? AND status = ? LIMIT 1',
            { codename, 'active' }
        )
        if not clash then return codename end
    end
    return nil
end

local function charName(charinfoJson)
    if not charinfoJson then return nil end
    local ok, info = pcall(json.decode, charinfoJson)
    if not ok or type(info) ~= 'table' then return nil end
    local name = ('%s %s'):format(info.firstname or '', info.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
    return name ~= '' and name or nil
end

-- Safety net: create the tables if the SQL file wasn't imported by hand.
MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `hubcity_ci` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(50) NOT NULL,
            `codename` VARCHAR(32) NOT NULL,
            `handler_citizenid` VARCHAR(50) NOT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'active',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_ci_citizen_status` (`citizenid`, `status`),
            INDEX `idx_ci_codename_status` (`codename`, `status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `hubcity_ci_tips` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `ci_id` INT NOT NULL,
            `tip` TEXT NOT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
            `payment` INT NOT NULL DEFAULT 0,
            `handled_by` VARCHAR(50) DEFAULT NULL,
            `delivered` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `handled_at` TIMESTAMP NULL DEFAULT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_tips_ci` (`ci_id`),
            INDEX `idx_tips_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- =====================================================================
-- CI side
-- =====================================================================

-- A player's own program status: only their own codename, nothing else.
-- Also delivers any approved payouts that were waiting while they were
-- offline — this is the one call every CI client makes on check-in.
lib.callback.register('hubcity-noose:getMyStatus', function(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return { isCI = false } end

    local ci = getActiveCI(player.PlayerData.citizenid)
    if not ci then return { isCI = false } end

    local payout = 0
    local owed = MySQL.query.await(
        'SELECT id, payment FROM hubcity_ci_tips WHERE ci_id = ? AND status = ? AND delivered = 0',
        { ci.id, 'paid' }
    )
    if owed then
        for _, tip in ipairs(owed) do payout = payout + (tip.payment or 0) end
    end
    if payout > 0 then
        player.Functions.AddMoney('bank', payout, 'hubcity-noose-ci-payment')
        MySQL.update.await(
            'UPDATE hubcity_ci_tips SET delivered = 1 WHERE ci_id = ? AND status = ? AND delivered = 0',
            { ci.id, 'paid' }
        )
    end

    return { isCI = true, codename = ci.codename, payout = payout }
end)

-- Leave a tip at a drop point. Caller must be an active CI *and*
-- physically at the phone they claim to be using (server-side distance
-- check against the config coords).
lib.callback.register('hubcity-noose:submitTip', function(src, text, dropIndex)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return { ok = false, message = 'This phone is not in service.' } end

    local ci = getActiveCI(player.PlayerData.citizenid)
    if not ci then return { ok = false, message = 'This phone is not in service.' } end

    local point = Config.DropPoints[dropIndex]
    if not point then return { ok = false, message = 'This phone is not in service.' } end

    local coords = GetEntityCoords(GetPlayerPed(src))
    if #(coords - point.coords) > 10.0 then
        return { ok = false, message = 'You need to be at the phone to use it.' }
    end

    local tip = clean(text, Config.MaxTipLength)
    if not tip then return { ok = false, message = 'Say something worth hearing, or hang up.' } end

    MySQL.insert.await(
        'INSERT INTO hubcity_ci_tips (ci_id, tip, status) VALUES (?, ?, ?)',
        { ci.id, tip, 'pending' }
    )
    print(('[hubcity-noose] Tip received from %s at %s'):format(ci.codename, point.label))
    return { ok = true, message = 'It will be passed along. Walk away.' }
end)

-- =====================================================================
-- Garage
-- =====================================================================

-- The fleet list for this officer's grade (client display only —
-- authorizeSpawn re-checks before anything is spawned).
lib.callback.register('hubcity-noose:getGarageVehicles', function(src)
    local _, grade = getOfficer(src)
    if not grade or grade < Config.Permissions.Garage then return {} end
    local list = {}
    for _, veh in ipairs(Config.Vehicles) do
        if grade >= (veh.minGrade or 0) then
            list[#list + 1] = { model = veh.model, label = veh.label }
        end
    end
    return list
end)

-- Final say before the client spawns anything: job + grade + the model
-- must be on the fleet list. (The spawn itself is a client native, like
-- the rest of the pack's vehicle work — this gates the legitimate flow.)
lib.callback.register('hubcity-noose:authorizeSpawn', function(src, model)
    local _, grade = getOfficer(src)
    if not grade or grade < Config.Permissions.Garage then return false end
    if type(model) ~= 'string' then return false end
    for _, veh in ipairs(Config.Vehicles) do
        if veh.model == model then
            return grade >= (veh.minGrade or 0)
        end
    end
    return false
end)

-- =====================================================================
-- Handler program
-- =====================================================================

-- Everything the handler menu needs, in one call. Identity fields are
-- added per-row ONLY for a Director (SeeIdentity); everyone else gets
-- codenames, statuses, and a `mine` flag for their own files.
lib.callback.register('hubcity-noose:getHandlerData', function(src)
    local officer, grade = getOfficer(src)
    if not officer or grade < Config.Permissions.HandlerMenu then return nil end

    local seeIdentity = grade >= Config.Permissions.SeeIdentity
    local myCitizenid = officer.PlayerData.citizenid

    local cis = {}
    local rows = MySQL.query.await([[
        SELECT c.id, c.citizenid, c.codename, c.handler_citizenid, c.status, c.created_at,
               p.charinfo AS ci_charinfo, h.charinfo AS handler_charinfo
        FROM hubcity_ci c
        LEFT JOIN players p ON p.citizenid = c.citizenid
        LEFT JOIN players h ON h.citizenid = c.handler_citizenid
        ORDER BY c.status ASC, c.codename ASC
    ]]) or {}
    for _, row in ipairs(rows) do
        local entry = {
            id = row.id,
            codename = row.codename,
            status = row.status,
            mine = row.handler_citizenid == myCitizenid,
            created = row.created_at,
        }
        if seeIdentity then
            entry.realName = charName(row.ci_charinfo)
            entry.citizenid = row.citizenid
            entry.handlerName = charName(row.handler_charinfo)
            entry.handlerCitizenid = row.handler_citizenid
        end
        cis[#cis + 1] = entry
    end

    local tips = {}
    if grade >= Config.Permissions.ReviewTips then
        local tipRows = MySQL.query.await([[
            SELECT t.id, t.tip, t.created_at, c.codename
            FROM hubcity_ci_tips t
            JOIN hubcity_ci c ON c.id = t.ci_id
            WHERE t.status = 'pending'
            ORDER BY t.created_at ASC
            LIMIT 50
        ]]) or {}
        for _, row in ipairs(tipRows) do
            tips[#tips + 1] = {
                id = row.id,
                codename = row.codename,
                tip = row.tip,
                created = row.created_at,
            }
        end
    end

    return { cis = cis, tips = tips, seeIdentity = seeIdentity }
end)

-- Recruit a civilian. Target is either a nearby player's server id
-- (resolved here, never trusted from the client beyond the id) or a
-- citizenid typed by hand (validated against the players table).
lib.callback.register('hubcity-noose:registerCI', function(src, data)
    local officer, grade = getOfficer(src)
    if not officer or grade < Config.Permissions.RegisterCI then
        return { ok = false, message = 'Not authorized.' }
    end
    if type(data) ~= 'table' then return { ok = false, message = 'Nothing to register.' } end

    local citizenid
    if data.targetId then
        local target = exports.qbx_core:GetPlayer(tonumber(data.targetId))
        if not target then return { ok = false, message = 'That person is not around.' } end
        if target.PlayerData.job and target.PlayerData.job.name == Config.JobName then
            return { ok = false, message = 'You cannot run one of your own as an informant.' }
        end
        citizenid = target.PlayerData.citizenid
    else
        citizenid = clean(data.citizenid, 50)
        if not citizenid then
            return { ok = false, message = 'Pick the person standing here, or enter a citizen ID.' }
        end
        local exists = MySQL.scalar.await('SELECT citizenid FROM players WHERE citizenid = ? LIMIT 1', { citizenid })
        if not exists then return { ok = false, message = 'No citizen with that ID.' } end
    end

    if citizenid == officer.PlayerData.citizenid then
        return { ok = false, message = 'You cannot register yourself.' }
    end

    local existing = getActiveCI(citizenid)
    if existing then
        return { ok = false, message = ('That person already has an active file (%s).'):format(existing.codename) }
    end

    local codename = clean(data.codename, Config.MaxCodenameLength)
    if codename then
        local clash = MySQL.scalar.await(
            'SELECT id FROM hubcity_ci WHERE codename = ? AND status = ? LIMIT 1',
            { codename, 'active' }
        )
        if clash then return { ok = false, message = ('Codename "%s" is already in use.'):format(codename) } end
    else
        codename = generateCodename()
        if not codename then return { ok = false, message = 'Could not assign a codename — try again.' } end
    end

    MySQL.insert.await(
        'INSERT INTO hubcity_ci (citizenid, codename, handler_citizenid, status) VALUES (?, ?, ?, ?)',
        { citizenid, codename, officer.PlayerData.citizenid, 'active' }
    )
    print(('[hubcity-noose] %s registered informant %s'):format(officer.PlayerData.citizenid, codename))

    -- If the new CI is online, let their client pick up the drop points now.
    local target = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    if target then
        TriggerClientEvent('hubcity-noose:client:refreshAccess', target.PlayerData.source)
    end

    return { ok = true, message = ('Informant registered as %s.'):format(codename) }
end)

-- Approve a tip and pay the CI's bank. Online CIs are paid instantly
-- (and quietly notified); offline CIs are paid on their next check-in
-- via getMyStatus. The full amount trail lives on the tip row.
lib.callback.register('hubcity-noose:payTip', function(src, tipId, amount)
    local officer, grade = getOfficer(src)
    if not officer or grade < Config.Permissions.PayTips then
        return { ok = false, message = 'Not authorized.' }
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then return { ok = false, message = 'Enter an amount.' } end
    if amount > Config.Payments.MaxTip then amount = Config.Payments.MaxTip end

    local tip = MySQL.single.await([[
        SELECT t.*, c.citizenid, c.codename
        FROM hubcity_ci_tips t
        JOIN hubcity_ci c ON c.id = t.ci_id
        WHERE t.id = ? LIMIT 1
    ]], { tipId })
    if not tip then return { ok = false, message = 'Tip not found.' } end
    if tip.status ~= 'pending' then return { ok = false, message = 'That tip was already handled.' } end

    if Config.Payments.FromHandlerBank then
        if not officer.Functions.RemoveMoney('bank', amount, 'hubcity-noose-ci-payment') then
            return { ok = false, message = 'Your bank balance cannot cover that payment.' }
        end
    end

    local target = exports.qbx_core:GetPlayerByCitizenId(tip.citizenid)
    local delivered = false
    if target then
        target.Functions.AddMoney('bank', amount, 'hubcity-noose-ci-payment')
        delivered = true
    end

    MySQL.update.await(
        'UPDATE hubcity_ci_tips SET status = ?, payment = ?, handled_by = ?, delivered = ?, handled_at = NOW() WHERE id = ?',
        { 'paid', amount, officer.PlayerData.citizenid, delivered and 1 or 0, tipId }
    )
    print(('[hubcity-noose] Tip #%s paid: $%s to %s (by %s)'):format(tipId, amount, tip.codename, officer.PlayerData.citizenid))

    if delivered and target then
        TriggerClientEvent('hubcity-noose:client:paymentReceived', target.PlayerData.source, amount)
    end

    return { ok = true, message = ('Paid $%s to %s.'):format(amount, tip.codename) }
end)

lib.callback.register('hubcity-noose:rejectTip', function(src, tipId)
    local officer, grade = getOfficer(src)
    if not officer or grade < Config.Permissions.PayTips then
        return { ok = false, message = 'Not authorized.' }
    end

    local tip = MySQL.single.await('SELECT id, status FROM hubcity_ci_tips WHERE id = ? LIMIT 1', { tipId })
    if not tip then return { ok = false, message = 'Tip not found.' } end
    if tip.status ~= 'pending' then return { ok = false, message = 'That tip was already handled.' } end

    MySQL.update.await(
        'UPDATE hubcity_ci_tips SET status = ?, handled_by = ?, handled_at = NOW() WHERE id = ?',
        { 'rejected', officer.PlayerData.citizenid, tipId }
    )
    return { ok = true, message = 'Tip rejected.' }
end)

-- Deactivate / reactivate a CI file. Files are never deleted — the
-- record (and its tip history) stays in the database for audit.
lib.callback.register('hubcity-noose:setCIStatus', function(src, ciId, status)
    local officer, grade = getOfficer(src)
    if not officer or grade < Config.Permissions.DeactivateCI then
        return { ok = false, message = 'Not authorized.' }
    end
    if status ~= 'active' and status ~= 'inactive' then
        return { ok = false, message = 'Unknown status.' }
    end

    local ci = MySQL.single.await('SELECT * FROM hubcity_ci WHERE id = ? LIMIT 1', { ciId })
    if not ci then return { ok = false, message = 'File not found.' } end
    if ci.status == status then
        return { ok = false, message = ('%s is already %s.'):format(ci.codename, status) }
    end

    if status == 'active' then
        local other = getActiveCI(ci.citizenid)
        if other and other.id ~= ci.id then
            return { ok = false, message = 'That citizen already has a different active file.' }
        end
    end

    MySQL.update.await('UPDATE hubcity_ci SET status = ? WHERE id = ?', { status, ciId })
    print(('[hubcity-noose] File %s set to %s by %s'):format(ci.codename, status, officer.PlayerData.citizenid))

    -- Nudge the CI's client so drop points appear/disappear promptly.
    local target = exports.qbx_core:GetPlayerByCitizenId(ci.citizenid)
    if target then
        TriggerClientEvent('hubcity-noose:client:refreshAccess', target.PlayerData.source)
    end

    return {
        ok = true,
        message = status == 'active'
            and ('%s is active again.'):format(ci.codename)
            or ('%s has been deactivated.'):format(ci.codename),
    }
end)
