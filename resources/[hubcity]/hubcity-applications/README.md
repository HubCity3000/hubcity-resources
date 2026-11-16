# Hub City Applications

Job application desk for **Hub City Roleplay 5M** (Qbox). Any player can
walk up to the front desk in the HCPD lobby (Mission Row PD) and apply for
**HCPD** (police) or **EMS** (ambulance) with an ox_lib form.

## How it works

1. Player uses the ox_target point **"Fill out an application"** at the desk.
2. Form: department, character name, phone, experience, why-join statement.
3. Server validates everything, checks the anti-spam rule, and saves the
   application to the `hubcity_applications` table as `pending`.
4. If a Discord webhook is configured, the application is posted to the
   **#job-applications** channel for staff review.
5. The applicant gets an in-game confirmation. Staff review in Discord / the
   database, interview, and hire in game with `/setjob`.

## Rules built in

- **One pending application per player per department** — a second try gets
  a friendly "you already have an application in" message. Once staff mark
  the row `approved`/`denied`, the player can apply again.
- Server-side length caps and department whitelist — the client form is
  never trusted.
- Optional in-game ping to on-duty staff of that department
  (`Config.NotifyStaffInGame`, **off by default**).

## Config (`config.lua`)

- `Config.Desk.coords` — the target point. **Verify in game**: it starts at
  the Mission Row lobby centre; move it onto the actual front desk.
- `Config.DiscordWebhook` — paste the #job-applications webhook URL here.
  Empty = no Discord posting. Treat the URL like a password.
- `Config.Departments` — labels and the Qbox job keys used for hiring hints.

## Database

`sql/hubcity_applications.sql` creates the table. The resource also creates
it automatically on start if missing.

## Dependencies

`qbx_core`, `ox_lib`, `ox_target`, `oxmysql` — all standard in the Qbox
recipe. Ensure it **after** them (see the pack's INSTALL.md).
