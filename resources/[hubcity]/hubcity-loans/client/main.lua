-- Hub City Loans — client: motor pool point (vehicle program) + bank
-- points (personal loans). Two separate menus for two separate products.

RegisterNetEvent('hubcity-loans:client:notify', function(msg, ntype)
    lib.notify({ title = 'Hub City Loans', description = msg, type = ntype or 'inform' })
end)

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(500) end
    TriggerServerEvent('hubcity-loans:server:playerReady')
end)

local function money(n) return ('$%s'):format(math.floor(n)) end

-- =========================== VEHICLE PROGRAM ===========================

local function openMyVehicleLoan()
    local loan = lib.callback.await('hubcity-loans:getMyVehicleLoan', false)
    if not loan then
        lib.notify({ title = 'Department Vehicle Program', description = 'You have no active vehicle loan.', type = 'inform' })
        return
    end
    lib.registerContext({
        id = 'hubcity_my_vehicle_loan',
        title = ('My Loan — %s (%s)'):format(loan.model or 'vehicle', loan.plate or ''),
        options = {
            {
                title = ('Balance: %s'):format(money(loan.remaining)),
                description = ('%d payments of %s left · next due in ~%dh · missed: %d%s'):format(
                    loan.paymentsLeft, money(loan.paymentAmount), loan.nextDueInHours, loan.missed,
                    loan.status == 'defaulted' and ' · DEFAULTED — vehicle locked' or ''),
                icon = 'fa-solid fa-file-invoice-dollar',
            },
            {
                title = 'Make a payment now',
                description = ('Pay %s from your bank'):format(money(math.min(loan.paymentAmount, loan.remaining))),
                icon = 'fa-solid fa-money-bill-wave',
                onSelect = function()
                    local res = lib.callback.await('hubcity-loans:makeVehiclePayment', false)
                    lib.notify({ title = 'Department Vehicle Program', description = res.message, type = res.ok and 'success' or 'error' })
                end,
            },
            {
                title = 'Pay off early',
                description = ('Pay the full remaining %s now'):format(money(loan.remaining)),
                icon = 'fa-solid fa-circle-check',
                onSelect = function()
                    local res = lib.callback.await('hubcity-loans:payOffVehicle', false)
                    lib.notify({ title = 'Department Vehicle Program', description = res.message, type = res.ok and 'success' or 'error' })
                end,
            },
        },
    })
    lib.showContext('hubcity_my_vehicle_loan')
end

local function openVehicleProgram()
    local data = lib.callback.await('hubcity-loans:getVehicleCatalog', false)
    if not data or not data.ok then
        lib.notify({ title = 'Department Vehicle Program', description = (data and data.message) or 'Unavailable right now.', type = 'error' })
        return
    end
    local options = {}
    if data.myLoan then
        options[#options + 1] = {
            title = 'My Loan',
            description = ('%s · %s remaining'):format(data.myLoan.model or 'vehicle', money(data.myLoan.remaining)),
            icon = 'fa-solid fa-file-invoice-dollar',
            onSelect = openMyVehicleLoan,
        }
    end
    for _, v in ipairs(data.vehicles) do
        options[#options + 1] = {
            title = v.label,
            description = ('Price %s · Down %s now · then %d payments of %s every %dh (total owed %s)%s'):format(
                money(v.price), money(v.down), v.payments, money(v.perPayment), v.intervalHours, money(v.totalOwed),
                v.allowed and '' or (' · Requires grade %d'):format(v.minGrade)),
            icon = 'fa-solid fa-car',
            disabled = not v.allowed or data.myLoan ~= nil,
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Finance ' .. v.label,
                    content = ('Price: %s\nDown payment from your bank now: %s\nThen %d payments of %s every %dh.\nTotal owed after down payment: %s\n\nMiss more than the grace limit and the vehicle is locked until you catch up.'):format(
                        money(v.price), money(v.down), v.payments, money(v.perPayment), v.intervalHours, money(v.totalOwed)),
                    centered = true, cancel = true,
                })
                if alert ~= 'confirm' then return end
                local res = lib.callback.await('hubcity-loans:financeVehicle', false, v.model)
                lib.notify({ title = 'Department Vehicle Program', description = res.message, type = res.ok and 'success' or 'error' })
            end,
        }
    end
    lib.registerContext({ id = 'hubcity_vehicle_program', title = 'Department Vehicle Program', options = options })
    lib.showContext('hubcity_vehicle_program')
end

-- =========================== PERSONAL LOANS ===========================

local function openMyPersonalLoan()
    local loan = lib.callback.await('hubcity-loans:getMyPersonalLoan', false)
    if not loan then
        lib.notify({ title = 'Bank Loans', description = 'You have no active personal loan.', type = 'inform' })
        return
    end
    lib.registerContext({
        id = 'hubcity_my_personal_loan',
        title = 'My Personal Loan',
        options = {
            {
                title = ('Balance: %s'):format(money(loan.remaining)),
                description = ('%d payments of %s left · next due in ~%dh · missed: %d%s'):format(
                    loan.paymentsLeft, money(loan.paymentAmount), loan.nextDueInHours, loan.missed,
                    loan.status == 'defaulted' and ' · DEFAULTED — borrowing locked until repaid' or ''),
                icon = 'fa-solid fa-file-invoice-dollar',
            },
            {
                title = 'Make a payment now',
                description = ('Pay %s from your bank'):format(money(math.min(loan.paymentAmount, loan.remaining))),
                icon = 'fa-solid fa-money-bill-wave',
                onSelect = function()
                    local res = lib.callback.await('hubcity-loans:makePersonalPayment', false)
                    lib.notify({ title = 'Bank Loans', description = res.message, type = res.ok and 'success' or 'error' })
                end,
            },
            {
                title = 'Pay off early',
                description = ('Pay the full remaining %s now'):format(money(loan.remaining)),
                icon = 'fa-solid fa-circle-check',
                onSelect = function()
                    local res = lib.callback.await('hubcity-loans:payOffPersonal', false)
                    lib.notify({ title = 'Bank Loans', description = res.message, type = res.ok and 'success' or 'error' })
                end,
            },
        },
    })
    lib.showContext('hubcity_my_personal_loan')
end

local function openBankLoans()
    local data = lib.callback.await('hubcity-loans:getPersonalTiers', false)
    if not data or not data.ok then
        lib.notify({ title = 'Bank Loans', description = 'Loan services are unavailable right now.', type = 'error' })
        return
    end
    local options = {}
    if data.myLoan then
        options[#options + 1] = {
            title = 'My Personal Loan',
            description = ('%s remaining'):format(money(data.myLoan.remaining)),
            icon = 'fa-solid fa-file-invoice-dollar',
            onSelect = openMyPersonalLoan,
        }
    end
    for _, tier in ipairs(data.tiers) do
        options[#options + 1] = {
            title = ('Borrow %s'):format(money(tier.amount)),
            description = ('Repay %s total (%d%% interest) · %d payments of %s every %dh'):format(
                money(tier.totalOwed), tier.interest, tier.payments, money(tier.perPayment), tier.intervalHours),
            icon = 'fa-solid fa-hand-holding-dollar',
            disabled = data.myLoan ~= nil,
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Personal Loan',
                    content = ('Borrow %s into your bank account now.\nYou repay %s total: %d payments of %s every %dh, taken automatically from your bank.\nMissed payments add a late fee; too many misses locks you out of borrowing until repaid.'):format(
                        money(tier.amount), money(tier.totalOwed), tier.payments, money(tier.perPayment), tier.intervalHours),
                    centered = true, cancel = true,
                })
                if alert ~= 'confirm' then return end
                local res = lib.callback.await('hubcity-loans:takePersonalLoan', false, tier.index)
                lib.notify({ title = 'Bank Loans', description = res.message, type = res.ok and 'success' or 'error' })
            end,
        }
    end
    lib.registerContext({ id = 'hubcity_bank_loans', title = 'Bank Loans', options = options })
    lib.showContext('hubcity_bank_loans')
end

-- =========================== interaction points ===========================

exports.ox_target:addSphereZone({
    coords = Config.PurchasePoint.coords,
    radius = Config.PurchasePoint.radius,
    debug = false,
    options = {
        {
            name = 'hubcity_loans_motorpool',
            icon = 'fa-solid fa-car',
            label = Config.PurchasePoint.label,
            onSelect = openVehicleProgram,
        },
    },
})

for i, bank in ipairs(Config.BankPoints) do
    exports.ox_target:addSphereZone({
        coords = bank.coords,
        radius = 2.5,
        debug = false,
        options = {
            {
                name = 'hubcity_loans_bank_' .. i,
                icon = 'fa-solid fa-building-columns',
                label = 'Bank Loans',
                onSelect = openBankLoans,
            },
        },
    })
end
