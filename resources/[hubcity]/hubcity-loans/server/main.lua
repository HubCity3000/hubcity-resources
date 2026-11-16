-- =====================================================================
--  Hub City Loans — server
--  TWO products, ONE engine, kept clearly separate:
--    * VEHICLE loans  — HCPD officers only, at the motor pool point.
--      Down payment now, vehicle registered player-owned, scheduled
--      bank payments; too many misses -> vehicle LOCKED until cured.
--    * PERSONAL loans — any citizen, at bank points only.
--      Tiered amounts into the bank account, scheduled bank payments;
--      misses add a late fee and, past grace, a borrowing LOCKOUT
--      (status 'defaulted') until repaid. No vehicle is involved.
--  All money movement is server-side via qbx_core player functions.
-- =====================================================================

local function now() return os.time() end
local function ceilDiv(a, b) return math.floor((a + b - 1) / b) end

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `hubcity_loans` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(50) NOT NULL,
            `loan_type` VARCHAR(16) NOT NULL DEFAULT 'vehicle',
            `plate` VARCHAR(12) DEFAULT NULL,
            `model` VARCHAR(50) DEFAULT NULL,
            `principal` INT NOT NULL,
            `remaining` INT NOT NULL,
            `payment_amount` INT NOT NULL,
            `payments_left` INT NOT NULL,
            `next_due` BIGINT NOT NULL,
            `missed` INT NOT NULL DEFAULT 0,
            `status` VARCHAR(16) NOT NULL DEFAULT 'active',
            `vehicle_garage` VARCHAR(50) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_loans_citizen` (`citizenid`, `status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    -- If the table already existed from an earlier version without
    -- loan_type, add it (harmless error if the column is already there).
    pcall(function()
        MySQL.query.await("ALTER TABLE `hubcity_loans` ADD COLUMN `loan_type` VARCHAR(16) NOT NULL DEFAULT 'vehicle' AFTER `citizenid`")
    end)
end)

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function getPlayerByCitizenId(citizenid)
    return exports.qbx_core:GetPlayerByCitizenId(citizenid)
end

local function notify(src, msg, ntype)
    TriggerClientEvent('hubcity-loans:client:notify', src, msg, ntype or 'inform')
end

local function findLoan(citizenid, loanType)
    return MySQL.single.await(
        "SELECT * FROM hubcity_loans WHERE citizenid = ? AND loan_type = ? AND status IN ('active','defaulted') ORDER BY id DESC LIMIT 1",
        { citizenid, loanType })
end

local function saveLoan(loan)
    MySQL.update.await(
        "UPDATE hubcity_loans SET remaining = ?, payments_left = ?, next_due = ?, missed = ?, status = ? WHERE id = ?",
        { loan.remaining, loan.payments_left, loan.next_due, loan.missed, loan.status, loan.id })
end

-- ------------------------- vehicle lock -------------------------

local function lockVehicle(loan)
    if loan.loan_type ~= 'vehicle' or not loan.plate then return end
    local row = MySQL.single.await("SELECT garage FROM player_vehicles WHERE plate = ?", { loan.plate })
    if row and row.garage ~= Config.LockGarage then
        MySQL.update.await("UPDATE hubcity_loans SET vehicle_garage = ? WHERE id = ?", { row.garage, loan.id })
        MySQL.update.await("UPDATE player_vehicles SET garage = ?, state = 1 WHERE plate = ?",
            { Config.LockGarage, loan.plate })
    end
end

local function unlockVehicle(loan)
    if loan.loan_type ~= 'vehicle' or not loan.plate then return end
    local restore = loan.vehicle_garage or Config.DefaultGarage
    MySQL.update.await("UPDATE player_vehicles SET garage = ? WHERE plate = ? AND garage = ?",
        { restore, loan.plate, Config.LockGarage })
end

-- ------------------------- payment engine -------------------------

--- Process ONE scheduled cycle for a loan whose owner is online.
--- Returns a short outcome string.
local function processCycle(loan, Player)
    local due = math.min(loan.payment_amount, loan.remaining)
    local interval = (loan.loan_type == 'vehicle' and Config.Terms.PaymentIntervalHours
        or Config.PersonalTerms.PaymentIntervalHours) * 3600
    local grace = (loan.loan_type == 'vehicle' and Config.Terms.GraceMisses
        or Config.PersonalTerms.GraceMisses)

    if Player.Functions.GetMoney('bank') >= due and due > 0 then
        Player.Functions.RemoveMoney('bank', due, 'hubcity-loan-payment')
        loan.remaining = loan.remaining - due
        loan.payments_left = math.max(loan.payments_left - 1, 0)
        loan.missed = 0
        loan.next_due = now() + interval
        if loan.remaining <= 0 then
            loan.remaining = 0
            loan.status = 'paid'
            unlockVehicle(loan)
            saveLoan(loan)
            notify(Player.PlayerData.source, 'Loan paid off in full. Thank you!', 'success')
            return 'paid'
        end
        if loan.status == 'defaulted' then
            loan.status = 'active'
            unlockVehicle(loan)
            notify(Player.PlayerData.source, 'Payment received — your loan is back in good standing.', 'success')
        else
            notify(Player.PlayerData.source, ('Loan payment of $%d taken from your bank. $%d remaining.'):format(due, loan.remaining), 'inform')
        end
        saveLoan(loan)
        return 'paid-cycle'
    end

    -- Missed payment
    loan.missed = loan.missed + 1
    loan.next_due = now() + interval
    if loan.loan_type == 'personal' and Config.PersonalTerms.LateFee > 0 then
        loan.remaining = loan.remaining + Config.PersonalTerms.LateFee
        notify(Player.PlayerData.source, ('Loan payment missed — a $%d late fee was added.'):format(Config.PersonalTerms.LateFee), 'error')
    else
        notify(Player.PlayerData.source, 'Loan payment missed — not enough in your bank account.', 'error')
    end
    if loan.missed > grace and loan.status == 'active' then
        loan.status = 'defaulted'
        if loan.loan_type == 'vehicle' then
            lockVehicle(loan)
            notify(Player.PlayerData.source, 'Your financed vehicle has been LOCKED until you catch up on payments.', 'error')
        else
            notify(Player.PlayerData.source, 'Your personal loan is in default — you cannot borrow again until it is repaid.', 'error')
        end
    end
    saveLoan(loan)
    return 'missed'
end

local function processPlayerLoans(citizenid)
    local Player = getPlayerByCitizenId(citizenid)
    if not Player then return end -- offline: handled when they are next online (see RISKS)
    local rows = MySQL.query.await(
        "SELECT * FROM hubcity_loans WHERE citizenid = ? AND status IN ('active','defaulted') AND next_due <= ?",
        { citizenid, now() }) or {}
    for _, loan in ipairs(rows) do
        processCycle(loan, Player)
    end
end

-- Periodic sweep for everyone online
CreateThread(function()
    while true do
        Wait((Config.PaymentSweepMinutes or 10) * 60000)
        local rows = MySQL.query.await(
            "SELECT DISTINCT citizenid FROM hubcity_loans WHERE status IN ('active','defaulted') AND next_due <= ?",
            { now() }) or {}
        for _, r in ipairs(rows) do
            processPlayerLoans(r.citizenid)
        end
    end
end)

-- Client tells us the player has loaded in -> process anything due
RegisterNetEvent('hubcity-loans:server:playerReady', function()
    local Player = getPlayer(source)
    if Player then processPlayerLoans(Player.PlayerData.citizenid) end
end)

-- ------------------------- shared loan actions -------------------------

local function loanSummary(loan)
    if not loan then return nil end
    return {
        id = loan.id, type = loan.loan_type, model = loan.model, plate = loan.plate,
        remaining = loan.remaining, paymentAmount = loan.payment_amount,
        paymentsLeft = loan.payments_left, missed = loan.missed, status = loan.status,
        nextDueInHours = math.max(0, math.floor((loan.next_due - now()) / 3600)),
    }
end

local function makePayment(src, loanType)
    local Player = getPlayer(src)
    if not Player then return { ok = false, message = 'Player not found.' } end
    processPlayerLoans(Player.PlayerData.citizenid) -- settle anything due first
    local loan = findLoan(Player.PlayerData.citizenid, loanType)
    if not loan then return { ok = false, message = 'You have no active loan.' } end
    if loan.next_due <= now() then
        return { ok = true, message = 'A scheduled payment was just processed.', loan = loanSummary(findLoan(Player.PlayerData.citizenid, loanType)) }
    end
    -- Early manual payment: run one cycle now regardless of schedule
    local outcome = processCycle(loan, Player)
    if outcome == 'missed' then
        return { ok = false, message = 'Not enough money in your bank account for that payment.' }
    end
    return { ok = true, message = 'Payment made.', loan = loanSummary(findLoan(Player.PlayerData.citizenid, loanType)) }
end

local function payOff(src, loanType)
    local Player = getPlayer(src)
    if not Player then return { ok = false, message = 'Player not found.' } end
    local loan = findLoan(Player.PlayerData.citizenid, loanType)
    if not loan then return { ok = false, message = 'You have no active loan.' } end
    if Player.Functions.GetMoney('bank') < loan.remaining then
        return { ok = false, message = ('You need $%d in your bank to pay this loan off.'):format(loan.remaining) }
    end
    Player.Functions.RemoveMoney('bank', loan.remaining, 'hubcity-loan-payoff')
    loan.remaining = 0
    loan.payments_left = 0
    loan.status = 'paid'
    unlockVehicle(loan)
    saveLoan(loan)
    return { ok = true, message = 'Loan paid off in full!' }
end

-- =========================== VEHICLE LOANS ===========================

local function vehicleBreakdown(v)
    local t = Config.Terms
    local down = math.floor(v.price * t.DownPaymentPercent / 100 + 0.5)
    local financed = v.price - down
    local total = math.floor(financed * (1 + t.InterestPercent / 100) + 0.5)
    local perPayment = ceilDiv(total, t.PaymentCount)
    return down, financed, total, perPayment
end

lib.callback.register('hubcity-loans:getVehicleCatalog', function(source)
    local Player = getPlayer(source)
    if not Player then return { ok = false, message = 'Player not found.' } end
    processPlayerLoans(Player.PlayerData.citizenid)
    if Player.PlayerData.job.name ~= Config.JobName then
        return { ok = false, message = 'The Department Vehicle Program is for HCPD officers only.' }
    end
    local grade = Player.PlayerData.job.grade.level or 0
    local out = {}
    for _, v in ipairs(Config.Vehicles) do
        local down, _, total, perPayment = vehicleBreakdown(v)
        out[#out + 1] = {
            model = v.model, label = v.label, price = v.price, minGrade = v.minGrade,
            allowed = grade >= v.minGrade, down = down, totalOwed = total,
            perPayment = perPayment, payments = Config.Terms.PaymentCount,
            intervalHours = Config.Terms.PaymentIntervalHours,
        }
    end
    return { ok = true, vehicles = out, myLoan = loanSummary(findLoan(Player.PlayerData.citizenid, 'vehicle')) }
end)

local function generatePlate()
    for _ = 1, 25 do
        local plate = ('%s%s%s%d%d%d%d'):format(
            string.char(math.random(65, 90)), string.char(math.random(65, 90)), string.char(math.random(65, 90)),
            math.random(0, 9), math.random(0, 9), math.random(0, 9), math.random(0, 9))
        local exists = MySQL.single.await("SELECT plate FROM player_vehicles WHERE plate = ?", { plate })
        if not exists then return plate end
    end
    return nil
end

lib.callback.register('hubcity-loans:financeVehicle', function(source, model)
    local Player = getPlayer(source)
    if not Player then return { ok = false, message = 'Player not found.' } end
    local pd = Player.PlayerData
    if pd.job.name ~= Config.JobName then
        return { ok = false, message = 'HCPD officers only.' }
    end
    local chosen
    for _, v in ipairs(Config.Vehicles) do if v.model == model then chosen = v break end end
    if not chosen then return { ok = false, message = 'That vehicle is not in the program.' } end
    if (pd.job.grade.level or 0) < chosen.minGrade then
        return { ok = false, message = 'Your grade is not high enough for that vehicle yet.' }
    end
    if Config.OneActiveLoan and findLoan(pd.citizenid, 'vehicle') then
        return { ok = false, message = 'You already have an active vehicle loan. Pay it off first.' }
    end
    local down, financed, total, perPayment = vehicleBreakdown(chosen)
    if pd.money.bank < down then
        return { ok = false, message = ('You need the $%d down payment in your bank.'):format(down) }
    end
    local plate = generatePlate()
    if not plate then return { ok = false, message = 'Could not generate a plate — try again.' } end

    Player.Functions.RemoveMoney('bank', down, 'hubcity-vehicle-downpayment')

    -- Register the vehicle as PLAYER-OWNED. This mirrors the insert the
    -- Qbox vehicle shop flow performs into player_vehicles (same table
    -- and core fields). See RISKS in INSTALL.md — verify on first use.
    local okInsert = MySQL.insert.await(
        "INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, fuel, engine, body, state, depotprice, drivingdistance, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        { pd.license, pd.citizenid, chosen.model, GetHashKey(chosen.model), '{}', plate,
          Config.DefaultGarage, 100, 1000, 1000, 1, 0, 0, '' })
    if not okInsert then
        Player.Functions.AddMoney('bank', down, 'hubcity-vehicle-downpayment-refund')
        return { ok = false, message = 'Vehicle registration failed — down payment refunded. Tell an admin.' }
    end

    MySQL.insert.await(
        "INSERT INTO hubcity_loans (citizenid, loan_type, plate, model, principal, remaining, payment_amount, payments_left, next_due, missed, status, vehicle_garage) VALUES (?, 'vehicle', ?, ?, ?, ?, ?, ?, ?, 0, 'active', ?)",
        { pd.citizenid, plate, chosen.model, financed, total, perPayment, Config.Terms.PaymentCount,
          now() + Config.Terms.PaymentIntervalHours * 3600, Config.DefaultGarage })

    return { ok = true, message = ('%s financed! Plate %s. Pick it up from the %s garage. $%d due every %dh — %d payments.'):format(
        chosen.label, plate, Config.DefaultGarage, perPayment, Config.Terms.PaymentIntervalHours, Config.Terms.PaymentCount), plate = plate }
end)

lib.callback.register('hubcity-loans:getMyVehicleLoan', function(source)
    local Player = getPlayer(source)
    if not Player then return nil end
    processPlayerLoans(Player.PlayerData.citizenid)
    return loanSummary(findLoan(Player.PlayerData.citizenid, 'vehicle'))
end)

lib.callback.register('hubcity-loans:makeVehiclePayment', function(source) return makePayment(source, 'vehicle') end)
lib.callback.register('hubcity-loans:payOffVehicle', function(source) return payOff(source, 'vehicle') end)

-- =========================== PERSONAL LOANS ===========================

lib.callback.register('hubcity-loans:getPersonalTiers', function(source)
    local Player = getPlayer(source)
    if not Player then return { ok = false, message = 'Player not found.' } end
    processPlayerLoans(Player.PlayerData.citizenid)
    local t = Config.PersonalTerms
    local out = {}
    for i, tier in ipairs(Config.PersonalTiers) do
        local total = math.floor(tier.amount * (1 + t.InterestPercent / 100) + 0.5)
        out[#out + 1] = {
            index = i, amount = tier.amount, totalOwed = total,
            perPayment = ceilDiv(total, tier.payments), payments = tier.payments,
            intervalHours = t.PaymentIntervalHours, interest = t.InterestPercent,
        }
    end
    return { ok = true, tiers = out, myLoan = loanSummary(findLoan(Player.PlayerData.citizenid, 'personal')) }
end)

lib.callback.register('hubcity-loans:takePersonalLoan', function(source, tierIndex)
    local Player = getPlayer(source)
    if not Player then return { ok = false, message = 'Player not found.' } end
    local pd = Player.PlayerData
    local tier = Config.PersonalTiers[tierIndex]
    if not tier then return { ok = false, message = 'That loan tier does not exist.' } end
    if findLoan(pd.citizenid, 'personal') then
        return { ok = false, message = 'You already have a personal loan out. Repay it before borrowing again.' }
    end
    local t = Config.PersonalTerms
    local total = math.floor(tier.amount * (1 + t.InterestPercent / 100) + 0.5)
    local perPayment = ceilDiv(total, tier.payments)

    Player.Functions.AddMoney('bank', tier.amount, 'hubcity-personal-loan')
    MySQL.insert.await(
        "INSERT INTO hubcity_loans (citizenid, loan_type, plate, model, principal, remaining, payment_amount, payments_left, next_due, missed, status, vehicle_garage) VALUES (?, 'personal', NULL, NULL, ?, ?, ?, ?, ?, 0, 'active', NULL)",
        { pd.citizenid, tier.amount, total, perPayment, tier.payments,
          now() + t.PaymentIntervalHours * 3600 })

    return { ok = true, message = ('Loan approved — $%d is in your bank. You owe $%d total: %d payments of $%d every %dh.'):format(
        tier.amount, total, tier.payments, perPayment, t.PaymentIntervalHours) }
end)

lib.callback.register('hubcity-loans:getMyPersonalLoan', function(source)
    local Player = getPlayer(source)
    if not Player then return nil end
    processPlayerLoans(Player.PlayerData.citizenid)
    return loanSummary(findLoan(Player.PlayerData.citizenid, 'personal'))
end)

lib.callback.register('hubcity-loans:makePersonalPayment', function(source) return makePayment(source, 'personal') end)
lib.callback.register('hubcity-loans:payOffPersonal', function(source) return payOff(source, 'personal') end)

-- =========================== staff console ===========================

--- Server console (or ace 'command.hubcityloan'):
---   hubcityloan clear <citizenid>   -- forgive/clear all active loans, unlock vehicle
---   hubcityloan status <citizenid>  -- print the citizen's loans
RegisterCommand('hubcityloan', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'command.hubcityloan') then return end
    local action, citizenid = args[1], args[2]
    if not action or not citizenid then
        print('[hubcity-loans] Usage: hubcityloan clear|status <citizenid>')
        return
    end
    if action == 'status' then
        local rows = MySQL.query.await("SELECT * FROM hubcity_loans WHERE citizenid = ?", { citizenid }) or {}
        if #rows == 0 then print(('[hubcity-loans] No loans for %s'):format(citizenid)) return end
        for _, l in ipairs(rows) do
            print(('[hubcity-loans] #%d %s %s plate=%s remaining=$%d status=%s missed=%d'):format(
                l.id, l.loan_type, l.model or '-', l.plate or '-', l.remaining, l.status, l.missed))
        end
    elseif action == 'clear' then
        local rows = MySQL.query.await(
            "SELECT * FROM hubcity_loans WHERE citizenid = ? AND status IN ('active','defaulted')", { citizenid }) or {}
        for _, l in ipairs(rows) do
            unlockVehicle(l)
            MySQL.update.await("UPDATE hubcity_loans SET status = 'cleared', remaining = 0 WHERE id = ?", { l.id })
        end
        print(('[hubcity-loans] Cleared %d loan(s) for %s'):format(#rows, citizenid))
    else
        print('[hubcity-loans] Usage: hubcityloan clear|status <citizenid>')
    end
end, true)
