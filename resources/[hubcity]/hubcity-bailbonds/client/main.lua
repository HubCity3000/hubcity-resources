local QBCore = exports.qbx_core:GetCoreObject()

-- Hub City Bail Bonds — client (STARTER SKELETON, Qbox port)
-- Planned interactions (see README.md):
--   * ox_target on the office NPC/desk: "Post Bail", "View Bounty Board" (job-gated)
--   * Bounty board UI (ox_lib) listing active bounties for bountyhunter job
--   * Capture flow: restrain target (cuffs via qbx_policejob exports or own item), escort, deliver to office/jail

CreateThread(function()
    -- Office blip
    local blip = AddBlipForCoord(Config.Office.x, Config.Office.y, Config.Office.z)
    SetBlipSprite(blip, Config.OfficeBlip.sprite)
    SetBlipColour(blip, Config.OfficeBlip.colour)
    SetBlipScale(blip, Config.OfficeBlip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.OfficeBlip.label)
    EndTextCommandSetBlipName(blip)
end)

RegisterNetEvent('hubcity-bailbonds:client:notify', function(msg)
    QBCore.Functions.Notify(msg)
end)

-- TODO: ox_target office interaction
-- TODO: bounty board menu (pull 'hubcity-bailbonds:server:getBoard')
-- TODO: capture/escort/deliver loop for active bounties
