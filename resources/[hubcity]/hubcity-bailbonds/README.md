# Hub City Bail Bonds

> **Qbox port note (Nov 2026):** This copy was adjusted for the Qbox server —
> the core export and the fxmanifest dependency now point at `qbx_core`
> (oxmysql is unchanged), and the planned interactions were renamed to their
> Qbox equivalents (ox_target / ox_lib / qbx_policejob). Nothing else changed:
> it is still the same starter skeleton with the same TODOs. The jobs now live
> in `qbx_core/shared/jobs.lua` — see the `jobs/` folder and `INSTALL.md` in
> the Hub City Qbox Pack. Read the RISKS section of INSTALL.md before use.

Custom business + job resource for **Hub City Roleplay 5M**, built for Daniel
(Gamers Never Die). Status: **starter skeleton** — loads cleanly, jobs are live
in QBCore, gameplay loop is designed below and stubbed with TODOs.

## Jobs (defined in qb-core/shared/jobs.lua)

| Job name       | Label              | Grades                                  |
|----------------|--------------------|-----------------------------------------|
| `bailbonds`    | Hub City Bail Bonds| Agent → Senior Agent → Owner (boss)     |
| `bountyhunter` | Bounty Hunter      | Tracker → Hunter → Lead Hunter (boss)   |

## Planned gameplay

1. **Post bail** — After HCPD arrests someone, a judge/officer sets a bail
   amount. The suspect (or a friend) comes to the Hub City Bail Bonds office
   and pays the office a non-refundable fee (**10%** of bail, `Config.BailFeePercent`).
   The office posts the full bail and the suspect is released on bond.
2. **Bounty board** — If a released client skips court, gets re-arrested, or
   an officer requests it, the bond converts into a **bounty** on the office
   board. Only `bountyhunter` job members can view/claim board entries.
3. **Capture & payout** — A hunter tracks the target (board gives last-known
   area), restrains and escorts them back to the office or the HCPD jail.
   On turn-in, the hunter is paid from a **20%** reward pool
   (`Config.BountyCutPercent`) and the office recovers its posted bail.

## Build-out TODO

- [ ] SQL tables `bail_bonds` + `bounties`
- [ ] qb-target interaction at the office desk (Post Bail / Bounty Board)
- [ ] Bounty board UI with qb-menu
- [ ] Capture flow (restrain → escort → deliver) and payout split
- [ ] Hook into qb-policejob jail/bail events; court-date tracking
- [ ] Office interior/MLO pick + exact desk coordinates (Config.Office is a placeholder)

## Config

All tuning lives in `config.lua` (office location, fee %, bounty cut %, caps).
