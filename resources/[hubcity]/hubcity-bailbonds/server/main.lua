local QBCore = exports.qbx_core:GetCoreObject()

-- Hub City Bail Bonds — server (STARTER SKELETON, Qbox port)
-- Data model (to be created when gameplay is built out):
--   bail_bonds  (id, citizenid, amount, fee_paid, posted_by, status, created_at)
--   bounties    (id, citizenid, amount, reason, posted_by, claimed_by, status, created_at)
-- Planned flows (see README.md):
--   * Police set bail -> bonds office posts it for Config.BailFeePercent -> client released on bond
--   * Client skips court / re-offends -> bond becomes a bounty on the board
--   * Bounty hunter captures target and delivers them -> hunter paid from Config.BountyCutPercent pool,
--     bonds office recovers its exposure

QBCore.Functions.CreateCallback('hubcity-bailbonds:server:getBoard', function(source, cb)
    -- TODO: return active rows from `bounties` table via MySQL.query.await
    cb({})
end)

-- TODO: 'hubcity-bailbonds:server:postBail'   (charge fee, mark bond posted, notify police/jail)
-- TODO: 'hubcity-bailbonds:server:skipBail'   (convert a skipped bond into a bounty)
-- TODO: 'hubcity-bailbonds:server:turnIn'     (verify capture, split payout, clear bounty)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    print('[hubcity-bailbonds] starter skeleton loaded — gameplay TODO, see README.md')
end)
