Config = {}

-- Jobs that use this resource (defined in qbx_core/shared/jobs.lua — see the jobs/ folder in this pack)
Config.BondsJob = 'bailbonds'        -- Hub City Bail Bonds (office staff)
Config.HunterJob = 'bountyhunter'    -- Bounty Hunter (field)

-- Office location (placeholder: near the HCPD station at Mission Row / downtown — set exact coords in-game later)
Config.Office = vector3(252.0, -290.0, 49.0)
Config.OfficeBlip = { sprite = 188, colour = 5, scale = 0.8, label = 'Hub City Bail Bonds' }

-- Gameplay tuning (see README.md for the full design)
Config.BailFeePercent = 10           -- % of bail the bonds office charges the client (non-refundable fee)
Config.BountyCutPercent = 20         -- % of a recovered bounty paid out as the hunter reward pool
Config.MaxBail = 250000              -- highest bail the office will post
Config.BountyBoardRefresh = 60000    -- ms between bounty board syncs
