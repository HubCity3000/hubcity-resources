-- Hub City Crafting — client: bench target points + the recipe menu.
-- The menu's material counts come FROM THE SERVER (never the client's own
-- inventory view), and the craft itself is a server begin/finish pair with
-- the progress bar in between — the server re-validates everything at the
-- finish line, so a skipped or sped-up progress bar gains nothing.

RegisterNetEvent('hubcity-crafting:client:notify', function(msg, ntype)
    lib.notify({ title = 'Crafting Bench', description = msg, type = ntype or 'inform' })
end)

local function openBenchMenu(benchName)
    local data = lib.callback.await('hubcity-crafting:getRecipes', false)
    if not data or not data.ok then
        lib.notify({ title = 'Crafting Bench', description = (data and data.message) or 'The bench is unavailable right now.', type = 'error' })
        return
    end

    local options = {}
    for _, recipe in ipairs(data.recipes) do
        local parts = {}
        for _, mat in ipairs(recipe.materials) do
            parts[#parts + 1] = ('%s %d/%d'):format(mat.label, mat.have, mat.count)
        end
        options[#options + 1] = {
            title = recipe.label,
            description = ('%s\nNeeds: %s'):format(recipe.description, table.concat(parts, ' · ')),
            icon = 'fa-solid fa-briefcase',
            disabled = not recipe.canCraft,
            onSelect = function()
                local begin = lib.callback.await('hubcity-crafting:beginCraft', false, recipe.id)
                if not begin or not begin.ok then
                    lib.notify({ title = 'Crafting Bench', description = (begin and begin.message) or 'You cannot craft that right now.', type = 'error' })
                    return
                end

                local finished = lib.progressBar({
                    duration = recipe.duration,
                    label = 'Crafting ' .. recipe.label .. '...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { car = true, move = true, combat = true },
                    anim = { dict = 'amb@world_human_hammering@male@base', clip = 'base' },
                })
                if not finished then
                    TriggerServerEvent('hubcity-crafting:server:cancelCraft')
                    lib.notify({ title = 'Crafting Bench', description = 'Crafting cancelled — no materials used.', type = 'inform' })
                    return
                end

                local res = lib.callback.await('hubcity-crafting:finishCraft', false)
                lib.notify({ title = 'Crafting Bench', description = res.message, type = res.ok and 'success' or 'error' })
                if res.ok then openBenchMenu(benchName) end
            end,
        }
    end

    lib.registerContext({ id = 'hubcity_crafting_bench', title = benchName, options = options })
    lib.showContext('hubcity_crafting_bench')
end

for i, bench in ipairs(Config.Benches) do
    exports.ox_target:addSphereZone({
        coords = bench.coords,
        radius = bench.radius,
        debug = false,
        options = {
            {
                name = 'hubcity_crafting_bench_' .. i,
                icon = 'fa-solid fa-screwdriver-wrench',
                label = 'Use Crafting Bench',
                onSelect = function() openBenchMenu(bench.name) end,
            },
        },
    })

    if bench.blip then
        local blip = AddBlipForCoord(bench.coords.x, bench.coords.y, bench.coords.z)
        SetBlipSprite(blip, bench.blip.sprite)
        SetBlipColour(blip, bench.blip.colour)
        SetBlipScale(blip, bench.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(bench.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end
