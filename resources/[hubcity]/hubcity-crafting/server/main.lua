-- Hub City Crafting — server: recipe data, container registration, and the
-- begin/finish craft pair. ALL validation lives here: bench proximity,
-- material counts (read from ox_inventory directly), craft duration, and
-- carry capacity. The client only displays what this file tells it.

local function findRecipe(recipeId)
    for _, recipe in ipairs(Config.Recipes) do
        if recipe.id == recipeId then return recipe end
    end
    return nil
end

local function nearBench(source)
    local ped = GetPlayerPed(source)
    if ped == 0 then return false end
    local pos = GetEntityCoords(ped)
    for _, bench in ipairs(Config.Benches) do
        if #(pos - bench.coords) <= Config.MaxDistance then return true end
    end
    return false
end

local function materialCount(source, item)
    return exports.ox_inventory:Search(source, 'count', item) or 0
end

local function missingMaterials(source, recipe)
    local missing = {}
    for _, mat in ipairs(recipe.materials) do
        local have = materialCount(source, mat.item)
        if have < mat.count then
            missing[#missing + 1] = ('%s (%d/%d)'):format(mat.label, have, mat.count)
        end
    end
    return missing
end

-- Register the backpacks as ox_inventory containers (slots + maxWeight from
-- config). Done here via ox_inventory's setContainerProperties export so
-- nobody has to edit ox_inventory's own containers.lua — if a future
-- ox_inventory ever drops the export, the same three calls are written out
-- in items/hubcity_crafting_items.lua as a paste-in fallback.
CreateThread(function()
    while GetResourceState('ox_inventory') ~= 'started' do Wait(500) end
    Wait(1000)
    for _, recipe in ipairs(Config.Recipes) do
        if recipe.container then
            exports.ox_inventory:setContainerProperties(recipe.item, {
                slots = recipe.container.slots,
                maxWeight = recipe.container.maxWeight,
            })
        end
    end
end)

-- What the bench menu shows: every recipe with the player's REAL material
-- counts, counted here on the server.
lib.callback.register('hubcity-crafting:getRecipes', function(source)
    if not exports.qbx_core:GetPlayer(source) then
        return { ok = false, message = 'You are not signed in.' }
    end
    local recipes = {}
    for _, recipe in ipairs(Config.Recipes) do
        local mats, canCraft = {}, true
        for _, mat in ipairs(recipe.materials) do
            local have = materialCount(source, mat.item)
            if have < mat.count then canCraft = false end
            mats[#mats + 1] = { item = mat.item, label = mat.label, count = mat.count, have = have }
        end
        recipes[#recipes + 1] = {
            id = recipe.id,
            label = recipe.label,
            description = recipe.description,
            duration = recipe.duration,
            materials = mats,
            canCraft = canCraft,
        }
    end
    return { ok = true, recipes = recipes }
end)

-- One in-progress craft per player: recipe id + when it started.
local sessions = {}

lib.callback.register('hubcity-crafting:beginCraft', function(source, recipeId)
    local recipe = findRecipe(recipeId)
    if not recipe then return { ok = false, message = 'Unknown recipe.' } end
    if sessions[source] then return { ok = false, message = 'You are already crafting something.' } end
    if not nearBench(source) then return { ok = false, message = 'You need to be at a crafting bench.' } end

    local missing = missingMaterials(source, recipe)
    if #missing > 0 then
        return { ok = false, message = 'Missing materials: ' .. table.concat(missing, ', ') }
    end

    sessions[source] = { recipeId = recipeId, started = GetGameTimer() }
    return { ok = true }
end)

RegisterNetEvent('hubcity-crafting:server:cancelCraft', function()
    sessions[source] = nil
end)

lib.callback.register('hubcity-crafting:finishCraft', function(source)
    local session = sessions[source]
    if not session then return { ok = false, message = 'No craft in progress.' } end
    sessions[source] = nil

    local recipe = findRecipe(session.recipeId)
    if not recipe then return { ok = false, message = 'Unknown recipe.' } end

    -- The progress bar must actually have run (minus timing tolerance).
    local elapsed = GetGameTimer() - session.started
    if elapsed < recipe.duration - Config.ProgressTolerance then
        return { ok = false, message = 'That was too fast — the craft failed.' }
    end

    if not nearBench(source) then
        return { ok = false, message = 'You wandered away from the bench — the craft failed.' }
    end

    -- Materials are re-counted NOW: whatever the menu showed earlier, the
    -- finish line only believes the current inventory.
    local missing = missingMaterials(source, recipe)
    if #missing > 0 then
        return { ok = false, message = 'Missing materials: ' .. table.concat(missing, ', ') }
    end

    if not exports.ox_inventory:CanCarryItem(source, recipe.item, 1) then
        return { ok = false, message = 'No room to carry the finished ' .. recipe.label .. '.' }
    end

    -- Consume, then give. If the give somehow fails after consuming, every
    -- removed material is refunded — a failed craft never eats materials.
    local removed = {}
    for _, mat in ipairs(recipe.materials) do
        if exports.ox_inventory:RemoveItem(source, mat.item, mat.count) then
            removed[#removed + 1] = mat
        else
            for _, done in ipairs(removed) do
                exports.ox_inventory:AddItem(source, done.item, done.count)
            end
            return { ok = false, message = 'Could not take the materials — nothing was crafted.' }
        end
    end

    if not exports.ox_inventory:AddItem(source, recipe.item, 1) then
        for _, done in ipairs(removed) do
            exports.ox_inventory:AddItem(source, done.item, done.count)
        end
        return { ok = false, message = 'Could not hand over the ' .. recipe.label .. ' — materials refunded.' }
    end

    return { ok = true, message = 'Crafted: ' .. recipe.label }
end)

AddEventHandler('playerDropped', function()
    sessions[source] = nil
end)
