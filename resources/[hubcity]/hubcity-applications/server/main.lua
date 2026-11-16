-- Hub City Applications — server.
-- Validates submissions, enforces one PENDING application per player per
-- department, stores rows in `hubcity_applications`, optionally posts to the
-- Discord #job-applications webhook and pings on-duty staff in game.

local function result(src, ok, message)
    TriggerClientEvent('hubcity-applications:client:result', src, ok, message)
end

local function clean(value, maxLen)
    if type(value) ~= 'string' then return nil end
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    if value == '' then return nil end
    if #value > maxLen then value = value:sub(1, maxLen) end
    return value
end

local function postToDiscord(app)
    if not Config.DiscordWebhook or Config.DiscordWebhook == '' then return end
    local dept = Config.Departments[app.department]
    local payload = {
        username = Config.WebhookUsername or 'Hub City Applications',
        embeds = {
            {
                title = ('New application — %s'):format(dept and dept.label or app.department),
                color = app.department == 'police' and 3447003 or 15158332,
                fields = {
                    { name = 'Character', value = app.charname, inline = true },
                    { name = 'Citizen ID', value = app.citizenid, inline = true },
                    { name = 'Phone', value = app.phone, inline = true },
                    { name = 'Experience', value = app.experience },
                    { name = 'Why they want to join', value = app.statement },
                },
                footer = { text = 'Review in Discord or the hubcity_applications table. Hire in game: /setjob <id> ' .. (dept and dept.job or app.department) .. ' 0' },
            },
        },
    }
    PerformHttpRequest(Config.DiscordWebhook, function(status)
        if status < 200 or status >= 300 then
            print(('[hubcity-applications] Discord webhook returned HTTP %s — check Config.DiscordWebhook'):format(status))
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

local function notifyStaff(app)
    if not Config.NotifyStaffInGame then return end
    local dept = Config.Departments[app.department]
    if not dept then return end
    local message = ('A new %s application was filed at the front desk.'):format(dept.shortLabel)
    for _, playerId in ipairs(GetPlayers()) do
        local player = exports.qbx_core:GetPlayer(tonumber(playerId))
        if player and player.PlayerData.job and player.PlayerData.job.name == dept.job and player.PlayerData.job.onduty then
            TriggerClientEvent('hubcity-applications:client:staffAlert', playerId, message)
        end
    end
end

-- Safety net: create the table if the SQL file wasn't imported by hand.
MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `hubcity_applications` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(50) NOT NULL,
            `charname` VARCHAR(100) NOT NULL,
            `department` VARCHAR(32) NOT NULL,
            `phone` VARCHAR(32) NOT NULL,
            `experience` TEXT NOT NULL,
            `statement` TEXT NOT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_citizen_dept_status` (`citizenid`, `department`, `status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

RegisterNetEvent('hubcity-applications:server:submit', function(data)
    local src = source
    if type(data) ~= 'table' then return end

    local dept = Config.Departments[data.department]
    if not dept then
        result(src, false, 'That department is not accepting applications.')
        return
    end

    local max = Config.MaxLengths
    local name = clean(data.name, max.name)
    local phone = clean(data.phone, max.phone)
    local experience = clean(data.experience, max.experience)
    local statement = clean(data.statement, max.statement)
    if not name or not phone or not experience or not statement then
        result(src, false, 'Please fill out every field before submitting.')
        return
    end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local citizenid = player.PlayerData.citizenid

    -- Anti-spam: one pending application per player per department.
    local existing = MySQL.scalar.await(
        'SELECT id FROM hubcity_applications WHERE citizenid = ? AND department = ? AND status = ? LIMIT 1',
        { citizenid, data.department, 'pending' }
    )
    if existing then
        result(src, false, ('You already have an application in with %s — command will review it. Watch Discord for your interview.'):format(dept.shortLabel))
        return
    end

    MySQL.insert.await(
        'INSERT INTO hubcity_applications (citizenid, charname, department, phone, experience, statement, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { citizenid, name, data.department, phone, experience, statement, 'pending' }
    )

    local app = {
        citizenid = citizenid,
        charname = name,
        department = data.department,
        phone = phone,
        experience = experience,
        statement = statement,
    }
    postToDiscord(app)
    notifyStaff(app)

    result(src, true, ('Your application was sent to %s command. Watch Discord for your interview.'):format(dept.shortLabel))
    print(('[hubcity-applications] %s (%s) applied to %s'):format(name, citizenid, dept.label))
end)
