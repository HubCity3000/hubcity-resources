-- Hub City Applications — client.
-- One ox_target point at the HCPD front desk opens an ox_lib application
-- form. All validation, storage and Discord posting happen server-side.

local zoneId

local function openApplicationForm()
    local deptOptions = {}
    for key, dept in pairs(Config.Departments) do
        deptOptions[#deptOptions + 1] = { value = key, label = dept.label }
    end
    table.sort(deptOptions, function(a, b) return a.label < b.label end)

    local input = lib.inputDialog('Hub City Job Application', {
        { type = 'select', label = 'Department', required = true, options = deptOptions },
        { type = 'input', label = 'Character name', placeholder = 'Firstname Lastname', required = true, max = Config.MaxLengths.name },
        { type = 'input', label = 'Phone number', placeholder = 'e.g. 555-0134', required = true, max = Config.MaxLengths.phone },
        { type = 'textarea', label = 'Experience', placeholder = 'Relevant experience (in-character is fine)', required = true, max = Config.MaxLengths.experience },
        { type = 'textarea', label = 'Why do you want to join?', placeholder = 'A short statement', required = true, max = Config.MaxLengths.statement },
    })

    if not input then return end -- player closed the form

    TriggerServerEvent('hubcity-applications:server:submit', {
        department = input[1],
        name = input[2],
        phone = input[3],
        experience = input[4],
        statement = input[5],
    })
end

CreateThread(function()
    zoneId = exports.ox_target:addSphereZone({
        coords = Config.Desk.coords,
        radius = Config.Desk.radius,
        debug = false,
        options = {
            {
                name = 'hubcity_applications_desk',
                icon = 'fa-solid fa-file-signature',
                label = 'Fill out an application',
                distance = 2.5,
                onSelect = openApplicationForm,
            },
        },
    })
end)

RegisterNetEvent('hubcity-applications:client:result', function(ok, message)
    lib.notify({
        title = 'Job Application',
        description = message,
        type = ok and 'success' or 'error',
        duration = 8000,
    })
end)

RegisterNetEvent('hubcity-applications:client:staffAlert', function(message)
    lib.notify({
        title = 'New Application',
        description = message,
        type = 'inform',
        duration = 8000,
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if zoneId then exports.ox_target:removeZone(zoneId) end
end)
