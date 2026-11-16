# hubcity-laundering — wash marked bills into clean bank money

A hidden system, discovered ONLY through the tablet's Black Market app:

- **Spots:** 4 back-room locations in `Config.Spots` (laundromat, car
  wash office, warehouse office, dock office). No blips, no markers.
  All coords are estimates — verify in game, one-line fixes in config.
- **Rotation:** 1 spot active at a time by default (`Config.ActiveSpots`,
  `Config.RotationMinutes` = 180), derived from the clock so the tablet
  and this resource always agree. hubcity-tablet reads the
  `GetActiveWashInfo` export and shows the active neighborhood + fee in
  its Black Market app — that advertisement is the ONLY public trace.
- **Flow:** at an active spot, "Wash marked bills" hands over
  `markedbills` items; worth is read from item metadata SERVER-SIDE
  (client never names an amount). After `Config.ProcessingMinutes` (3),
  "Collect clean money" at the same spot deposits the washed amount
  minus `Config.WashFeePercent` (25%) into the player's bank.
- **Limits:** `Config.SessionLimit` ($50,000 worth per wash), one wash
  at a time per player.
- **Police alert:** `Config.PoliceAlert` — DEFAULT OFF (Daniel's
  choice). When enabled, starting a wash can fire the server event
  `hubcity-laundering:server:policeAlert` (coords, neighborhood) for
  wiring into a dispatch system; no dispatch is bundled.

Sessions are in-memory: restarting the resource/server mid-wash loses
that wash (the bills are already taken). See INSTALL.md RISKS.
