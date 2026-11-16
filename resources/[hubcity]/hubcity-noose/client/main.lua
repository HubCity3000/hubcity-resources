-- Hub City NOOSE — client.
-- Everything here is VISIBILITY ONLY, and the visibility is the secrecy:
-- the garage point only exists for players holding the NOOSE job, the
-- payphone drop points only exist for registered CIs, and to everyone
-- else none of it renders at all. Every action is re-authorized on the
-- server regardless of what this client shows.

local garageZone
local dropZones = {}
local isOfficer, myGrade, isCI = false, 0, false
local currentVehicle

local function notify(title, description, type)
    lib.notify({ title = title, description = description, type = type or 'inform', duration = 7000 })
end

-- =====================================================================
-- Vehicles
-- =====================================================================

local function spawnVehicle(model)
    local hash = joaat(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 50 do Wait(100) timeout = timeout + 1 end
    if not HasModelLoaded(hash) then
        notify('NOOSE', 'That vehicle is unavailable right now.', 'error')
        return
    end

    if currentVehicle and DoesEntityExist(currentVehicle) then DeleteEntity(currentVehicle) end

    local s = Config.Garage.spawn
    local veh = CreateVehicle(hash, s.x, s.y, s.z, s.w, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleNumberPlateText(veh, 'NOOSE' .. math.random(100, 999))
    SetVehicleEngineOn(veh, true, true, false)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    SetModelAsNoLongerNeeded(hash)

    currentVehicle = veh
    notify('NOOSE', 'Vehicle signed out. Keep it forgettable.', 'success')
end

local function returnVehicle()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        notify('NOOSE', 'You have no vehicle signed out.', 'error')
        return
    end
    local dist = #(GetEntityCoords(currentVehicle) - Config.Garage.coords)
    if dist > Config.Garage.returnDistance then
        notify('NOOSE', 'Bring the vehicle back to the garage point first.', 'error')
        return
    end
    if GetPedInVehicleSeat(currentVehicle, -1) == PlayerPedId() then
        TaskLeaveVehicle(PlayerPedId(), currentVehicle, 0)
        Wait(600)
    end
    DeleteEntity(currentVehicle)
    currentVehicle = nil
    notify('NOOSE', 'Vehicle returned. It was never here.', 'success')
end

local function openGarageMenu()
    local vehicles = lib.callback.await('hubcity-noose:getGarageVehicles', false) or {}
    if #vehicles == 0 then
        notify('NOOSE', 'No vehicles are available to your grade.', 'error')
        return
    end
    local options = {}
    for _, veh in ipairs(vehicles) do
        options[#options + 1] = {
            title = veh.label,
            description = veh.model,
            icon = 'fa-solid fa-car-side',
            onSelect = function()
                local ok = lib.callback.await('hubcity-noose:authorizeSpawn', false, veh.model)
                if ok then
                    spawnVehicle(veh.model)
                else
                    notify('NOOSE', 'Not authorized for that vehicle.', 'error')
                end
            end,
        }
    end
    lib.registerContext({ id = 'hubcity_noose_garage', title = 'NOOSE Garage', options = options })
    lib.showContext('hubcity_noose_garage')
end

-- =====================================================================
-- Handler program (menus)
-- =====================================================================

local function openRegisterDialog()
    local nearby = lib.getNearbyPlayers(GetEntityCoords(PlayerPedId()), 10.0, false) or {}
    local targetOptions = { { value = 'manual', label = 'Enter a citizen ID instead' } }
    for _, p in ipairs(nearby) do
        targetOptions[#targetOptions + 1] = {
            value = tostring(p.id),
            label = ('Person standing here (server #%s)'):format(p.id),
        }
    end

    local input = lib.inputDialog('Register an informant', {
        { type = 'select', label = 'Who are you recruiting?', required = true, options = targetOptions },
        { type = 'input', label = 'Citizen ID (only for the manual option)', required = false },
        { type = 'input', label = 'Codename (blank = auto-assign)', required = false, max = Config.MaxCodenameLength },
    })
    if not input then return end

    local data = {}
    if input[1] ~= 'manual' then
        data.targetId = tonumber(input[1])
    else
        data.citizenid = input[2]
    end
    if input[3] and input[3] ~= '' then data.codename = input[3] end

    local res = lib.callback.await('hubcity-noose:registerCI', false, data)
    notify('CI Program', res.message, res.ok and 'success' or 'error')
end

local function openCIDetail(ci)
    local description = ('Status: %s'):format(ci.status)
    if ci.mine then description = description .. '  •  Your file' end
    if ci.realName then
        description = description .. ('\nReal identity: %s (%s)'):format(ci.realName, ci.citizenid or '?')
    end
    if ci.handlerName then
        description = description .. ('\nHandler: %s'):format(ci.handlerName)
    end
    if ci.created then
        description = description .. ('\nOn the books since %s'):format(ci.created)
    end

    local options = {
        { title = ci.codename, description = description, icon = 'fa-solid fa-user-secret' },
    }
    if ci.status == 'active' then
        options[#options + 1] = {
            title = 'Deactivate this file',
            description = 'They lose drop-point access immediately. The file and its tips stay on record.',
            icon = 'fa-solid fa-ban',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = ('Deactivate %s?'):format(ci.codename),
                    content = 'They will no longer be able to leave tips. This can be undone by reactivating the file.',
                    centered = true,
                    cancel = true,
                })
                if alert == 'confirm' then
                    local res = lib.callback.await('hubcity-noose:setCIStatus', false, ci.id, 'inactive')
                    notify('CI Program', res.message, res.ok and 'success' or 'error')
                end
            end,
        }
    else
        options[#options + 1] = {
            title = 'Reactivate this file',
            icon = 'fa-solid fa-rotate-left',
            onSelect = function()
                local res = lib.callback.await('hubcity-noose:setCIStatus', false, ci.id, 'active')
                notify('CI Program', res.message, res.ok and 'success' or 'error')
            end,
        }
    end

    lib.registerContext({ id = 'hubcity_noose_ci_' .. ci.id, title = ci.codename, menu = 'hubcity_noose_cis', options = options })
    lib.showContext('hubcity_noose_ci_' .. ci.id)
end

local function openTipDetail(tip)
    local options = {
        {
            title = ('Tip from %s'):format(tip.codename),
            description = tip.tip,
            icon = 'fa-solid fa-envelope-open-text',
        },
        {
            title = 'Approve and pay',
            description = ('Default $%s — you can change the amount'):format(Config.Payments.DefaultTip),
            icon = 'fa-solid fa-money-bill-wave',
            onSelect = function()
                local input = lib.inputDialog(('Pay %s'):format(tip.codename), {
                    { type = 'number', label = 'Amount ($)', required = true, default = Config.Payments.DefaultTip, min = 1, max = Config.Payments.MaxTip },
                })
                if not input then return end
                local res = lib.callback.await('hubcity-noose:payTip', false, tip.id, input[1])
                notify('CI Program', res.message, res.ok and 'success' or 'error')
            end,
        },
        {
            title = 'Reject this tip',
            description = 'No payment. The tip stays on record as rejected.',
            icon = 'fa-solid fa-xmark',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Reject this tip?',
                    content = 'No payment will be made.',
                    centered = true,
                    cancel = true,
                })
                if alert == 'confirm' then
                    local res = lib.callback.await('hubcity-noose:rejectTip', false, tip.id)
                    notify('CI Program', res.message, res.ok and 'success' or 'error')
                end
            end,
        },
    }
    lib.registerContext({ id = 'hubcity_noose_tip_' .. tip.id, title = 'Tip review', menu = 'hubcity_noose_tips', options = options })
    lib.showContext('hubcity_noose_tip_' .. tip.id)
end

local function openHandlerMenu()
    local data = lib.callback.await('hubcity-noose:getHandlerData', false)
    if not data then
        notify('CI Program', 'Not authorized.', 'error')
        return
    end

    local ciOptions = {}
    if #data.cis == 0 then
        ciOptions[1] = { title = 'No informant files yet', icon = 'fa-solid fa-folder-open' }
    end
    for _, ci in ipairs(data.cis) do
        ciOptions[#ciOptions + 1] = {
            title = ci.codename,
            description = ('%s%s'):format(ci.status, ci.mine and '  •  your file' or ''),
            icon = ci.status == 'active' and 'fa-solid fa-user-secret' or 'fa-solid fa-user-slash',
            onSelect = function() openCIDetail(ci) end,
        }
    end
    lib.registerContext({ id = 'hubcity_noose_cis', title = 'Informant files', menu = 'hubcity_noose_handler', options = ciOptions })

    local tipOptions = {}
    if #data.tips == 0 then
        tipOptions[1] = { title = 'No tips waiting', icon = 'fa-solid fa-inbox' }
    end
    for _, tip in ipairs(data.tips) do
        local preview = #tip.tip > 60 and (tip.tip:sub(1, 60) .. '…') or tip.tip
        tipOptions[#tipOptions + 1] = {
            title = tip.codename,
            description = preview,
            icon = 'fa-solid fa-envelope',
            onSelect = function() openTipDetail(tip) end,
        }
    end
    lib.registerContext({ id = 'hubcity_noose_tips', title = 'Tips awaiting review', menu = 'hubcity_noose_handler', options = tipOptions })

    lib.registerContext({
        id = 'hubcity_noose_handler',
        title = data.seeIdentity and 'CI Program — Director view' or 'CI Program',
        options = {
            {
                title = 'Register an informant',
                description = 'Recruit the person standing with you, or by citizen ID',
                icon = 'fa-solid fa-user-plus',
                onSelect = openRegisterDialog,
            },
            {
                title = ('Informant files (%s)'):format(#data.cis),
                description = data.seeIdentity and 'Codenames and real identities' or 'Codenames only — identities are Director-only',
                icon = 'fa-solid fa-folder',
                menu = 'hubcity_noose_cis',
            },
            {
                title = ('Tips awaiting review (%s)'):format(#data.tips),
                icon = 'fa-solid fa-inbox',
                menu = 'hubcity_noose_tips',
            },
        },
    })
    lib.showContext('hubcity_noose_handler')
end

-- =====================================================================
-- CI side (drop points)
-- =====================================================================

local function openTipForm(dropIndex)
    local input = lib.inputDialog('Payphone', {
        { type = 'textarea', label = 'What did you hear?', placeholder = 'Keep it short. No names — yours or anyone\'s.', required = true, max = Config.MaxTipLength },
    })
    if not input then return end
    local res = lib.callback.await('hubcity-noose:submitTip', false, input[1], dropIndex)
    notify('Payphone', res.message, res.ok and 'success' or 'error')
end

-- =====================================================================
-- Access / zones — rebuilt whenever job or CI status may have changed
-- =====================================================================

local function addGarageZone()
    if garageZone then return end
    garageZone = exports.ox_target:addSphereZone({
        coords = Config.Garage.coords,
        radius = Config.Garage.radius,
        debug = false,
        options = {
            {
                name = 'hubcity_noose_garage',
                icon = 'fa-solid fa-car',
                label = 'NOOSE garage',
                distance = 2.5,
                onSelect = openGarageMenu,
            },
            {
                name = 'hubcity_noose_return',
                icon = 'fa-solid fa-rotate-left',
                label = 'Return vehicle',
                distance = 2.5,
                onSelect = returnVehicle,
            },
            {
                name = 'hubcity_noose_handler',
                icon = 'fa-solid fa-user-secret',
                label = 'CI program',
                distance = 2.5,
                canInteract = function()
                    return myGrade >= Config.Permissions.HandlerMenu
                end,
                onSelect = openHandlerMenu,
            },
        },
    })
end

local function removeGarageZone()
    if garageZone then exports.ox_target:removeZone(garageZone) end
    garageZone = nil
end

local function addDropZones()
    for i, point in ipairs(Config.DropPoints) do
        if not dropZones[i] then
            dropZones[i] = exports.ox_target:addSphereZone({
                coords = point.coords,
                radius = 1.5,
                debug = false,
                options = {
                    {
                        name = 'hubcity_noose_drop_' .. i,
                        icon = 'fa-solid fa-phone',
                        label = 'Use the phone',
                        distance = 2.0,
                        onSelect = function() openTipForm(i) end,
                    },
                },
            })
        end
    end
end

local function removeDropZones()
    for i, zone in pairs(dropZones) do
        exports.ox_target:removeZone(zone)
        dropZones[i] = nil
    end
end

local function refreshAccess()
    if not LocalPlayer.state.isLoggedIn then return end

    local pd = exports.qbx_core:GetPlayerData()
    local job = pd and pd.job
    local wasOfficer, wasCI = isOfficer, isCI
    isOfficer = (job and job.name == Config.JobName) or false
    myGrade = isOfficer and ((job.grade and job.grade.level) or 0) or 0

    if isOfficer and not garageZone then addGarageZone() end
    if not isOfficer and wasOfficer then removeGarageZone() end

    local status = lib.callback.await('hubcity-noose:getMyStatus', false)
    isCI = (status and status.isCI) or false
    if status and status.payout and status.payout > 0 then
        notify('Bank', ('A deposit of $%s just landed in your account.'):format(status.payout), 'success')
    end
    if isCI and not wasCI then addDropZones() end
    if not isCI and wasCI then removeDropZones() end
end

RegisterNetEvent('hubcity-noose:client:refreshAccess', refreshAccess)

RegisterNetEvent('hubcity-noose:client:paymentReceived', function(amount)
    notify('Bank', ('A deposit of $%s just landed in your account.'):format(amount), 'success')
end)

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(500) end
    refreshAccess()
    while true do
        Wait(60000)
        refreshAccess()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    removeGarageZone()
    removeDropZones()
    if currentVehicle and DoesEntityExist(currentVehicle) then DeleteEntity(currentVehicle) end
end)
