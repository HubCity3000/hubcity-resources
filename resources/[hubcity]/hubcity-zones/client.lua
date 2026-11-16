-- hubcity-zones: Vinewood -> "The Depot District"
--
-- Two halves:
--   1. GUARANTEED: a map blip naming the district (below).
--   2. EXPERIMENTAL: AddTextEntry overrides for the Vinewood zone labels,
--      attempting to rename the area name the HUD shows. Zone text may or
--      may not respond to runtime label overrides — if it doesn't, the
--      blip still carries the rename and nothing breaks.

-- (2) Zone label overrides — applied on start and again after the player
-- session is live, since text entries can be reset by the game.
local function applyZoneLabels()
    for _, label in ipairs(Config.ZoneLabels) do
        AddTextEntry(label, Config.DistrictName)
    end
end

CreateThread(function()
    applyZoneLabels()
end)

AddEventHandler('playerSpawned', function()
    applyZoneLabels()
end)

-- (1) The Depot District blip.
CreateThread(function()
    local c = Config.Blip.coords
    local blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipColour(blip, Config.Blip.colour)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.DistrictName)
    EndTextCommandSetBlipName(blip)
end)
