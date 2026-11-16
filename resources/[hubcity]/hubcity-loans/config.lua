Config = {}

-- =====================================================================
--  Hub City Loans — HCPD department vehicle financing
-- =====================================================================
--  Lets police officers (aimed at cadets, the lowest grade, who can't
--  afford a patrol car outright) finance a department vehicle:
--    * pick a vehicle at the HCPD motor pool point below
--    * pay a down payment from the bank NOW
--    * the vehicle is registered as PLAYER-OWNED (player_vehicles)
--    * the rest is owed as a loan (hubcity_loans table): scheduled bank
--      payments, grace misses, then the vehicle LOCKS until caught up
--  Everything on this page is Daniel's to tune.
-- =====================================================================

Config.JobName = 'police' -- internal Qbox job key (label is "Hub City Police Department")

-- Purchase point: the HCPD motor pool / PD garage desk.
-- ⚠️ VERIFY IN GAME: placed at the Mission Row PD garage area. If the
-- desk/zone sits wrong, move these coords — one-line fix.
Config.PurchasePoint = {
    coords = vector3(459.6, -989.6, 24.9), -- Mission Row PD ground-floor garage area (estimate)
    radius = 2.5,
    label  = 'Department Vehicle Program',
}

-- Where financed vehicles are registered as "stored". MUST be a garage id
-- that exists in qbx_garages' config on THIS install (Daniel: check
-- resources/[qbx]/qbx_garages/config or shared config for the id of the
-- main public garage). One-line fix here if yours differs.
Config.DefaultGarage = 'legionsquare'

-- Garage id used to LOCK a defaulted vehicle: the vehicle's garage is
-- switched to this (non-existent) id, so it cannot be taken out of any
-- real garage until the loan is caught up and the garage is restored.
Config.LockGarage = 'hubcity_loan_hold'

-- Financing terms (ALL configurable)
Config.Terms = {
    DownPaymentPercent  = 20,  -- % of the vehicle price due from bank at purchase
    InterestPercent     = 10,  -- % interest charged on the financed amount
    PaymentCount        = 7,   -- number of scheduled payments
    PaymentIntervalHours = 24, -- one payment due every N real hours
    GraceMisses         = 2,   -- missed payments allowed before the vehicle locks
}

-- Vehicle catalog: stock GTA police models. price + minGrade per vehicle
-- (minGrade = lowest police grade allowed to finance it; grade 0 = cadet).
-- Prices are placeholders in Daniel's hands — tune freely.
Config.Vehicles = {
    { model = 'police',   label = 'Police Cruiser (Stanier)',   price = 18000, minGrade = 0 },
    { model = 'police2',  label = 'Police Cruiser (Buffalo)',   price = 22000, minGrade = 0 },
    { model = 'police3',  label = 'Police Interceptor',         price = 28000, minGrade = 1 },
    { model = 'police4',  label = 'Unmarked Cruiser',           price = 32000, minGrade = 2 },
    { model = 'sheriff',  label = 'Sheriff Cruiser',            price = 24000, minGrade = 0 },
    { model = 'sheriff2', label = 'Sheriff SUV (Granger)',      price = 30000, minGrade = 1 },
}

-- One active loan per officer at a time.
Config.OneActiveLoan = true

-- How often the server sweeps for due payments (minutes). Payments are
-- also processed when an officer with a loan logs in / opens the menu.
Config.PaymentSweepMinutes = 10

-- =====================================================================
--  PERSONAL (CIVILIAN) LOANS — through the BANK. This is a SEPARATE
--  product from the vehicle program above: any citizen, applied for in
--  person at the bank points below, repaid from the bank account.
--  Misses add a late fee; past the grace limit the loan defaults and
--  the citizen is LOCKED OUT of borrowing until it is repaid.
--  There is NO vehicle involved and nothing gets locked but borrowing.
-- =====================================================================

-- Bank interaction points (Fleeca branches + Pacific Standard).
-- ⚠️ VERIFY IN GAME: placed at the banks' front counters from known map
-- positions — nudge in config if a zone sits wrong.
Config.BankPoints = {
    { name = 'Fleeca Bank — Legion Square',   coords = vector3(149.4, -1040.5, 29.4) },
    { name = 'Fleeca Bank — Vinewood',        coords = vector3(311.2, -592.4, 43.3) },
    { name = 'Fleeca Bank — Burton',          coords = vector3(-353.9, -49.8, 49.0) },
    { name = 'Pacific Standard — Vinewood',   coords = vector3(241.5, 225.0, 106.3) },
}

Config.PersonalTerms = {
    InterestPercent      = 15,  -- flat interest on the borrowed amount
    PaymentIntervalHours = 24,  -- one payment due every N real hours
    GraceMisses          = 2,   -- misses allowed before default/lockout
    LateFee              = 150, -- $ added to the balance per missed payment
}

-- Loan tiers (amounts are Daniel's to tune).
Config.PersonalTiers = {
    { amount = 5000,  payments = 5 },
    { amount = 10000, payments = 7 },
    { amount = 25000, payments = 10 },
}
