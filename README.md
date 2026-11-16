# hubcity-resources

Custom resources for **Hub City Roleplay 5M**, cloned by the Hub City
txAdmin recipe (`recipe.yaml`, one folder up from this repo's eventual
home — see the recipe's header comment).

Layout is a mirror of the server's resources folder:

- `resources/[hubcity]/` — every Hub City resource (bailbonds,
  raiderville, applications, tablet, loans, laundering, zones,
  dragrace, streetrace, crafting, noose). The recipe clones this
  folder into the server's `resources/[hubcity]/` and runs the SQL
  files inside `hubcity-applications/sql/`, `hubcity-tablet/sql/`,
  `hubcity-loans/sql/`, `hubcity-dragrace/sql/`,
  `hubcity-streetrace/sql/` and `hubcity-noose/sql/`.

No credentials, license keys or webhook URLs live in this repo — the
Discord webhook field in `hubcity-applications/config.lua` ships empty
on purpose (see the pack's INSTALL.md).
