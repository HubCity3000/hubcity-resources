# hubcity-loans — HCPD vehicle financing + civilian bank loans

Two separate products sharing one payment engine and one table
(`hubcity_loans`, distinguished by `loan_type`):

## 1. Department Vehicle Program (HCPD officers)
- Point: HCPD motor pool (config `Config.PurchasePoint`) — ox_target
  "Department Vehicle Program".
- Officers (job `police`) finance stock police vehicles from
  `Config.Vehicles` (per-vehicle price + minimum grade; cadets = grade 0).
- Terms (`Config.Terms`): 20% down from bank now, 10% interest on the
  financed amount, 7 payments, one every 24 real hours.
- The vehicle is inserted into `player_vehicles` as player-owned,
  mirroring the vehicle-shop insert, stored at `Config.DefaultGarage`.
- Payments auto-deduct from bank on schedule (server sweep + on login +
  when menus open — only while the officer is online; see INSTALL.md).
- Misses beyond `GraceMisses` (2) → loan `defaulted`, vehicle LOCKED by
  moving it to the non-existent garage id `Config.LockGarage`; a
  successful payment or payoff restores it.
- "My Loan" menu at the same point: balance, make a payment, pay off.

## 2. Personal Loans (any citizen, through the bank)
- Points: `Config.BankPoints` (Fleeca branches + Pacific Standard) —
  ox_target "Bank Loans". NOT at the motor pool; the systems are
  separate by design.
- Tiers in `Config.PersonalTiers` ($5k/$10k/$25k), terms in
  `Config.PersonalTerms` (15% interest, payments every 24h).
- Money lands in the bank account; repayments auto-deduct from bank.
- One active personal loan per citizen. Misses add `LateFee` ($150);
  past grace the loan defaults → borrowing lockout until repaid.
  No vehicle is ever locked for a personal loan.

## Staff
- Server console: `hubcityloan status <citizenid>` /
  `hubcityloan clear <citizenid>` (clear forgives the loans and unlocks
  any locked vehicle).
- SQL: `sql/hubcity_loans.sql` (the server also auto-creates the table).

See INSTALL.md for the full walkthrough and RISKS (notably: the
player_vehicles insert and garage ids must be verified on first use).
