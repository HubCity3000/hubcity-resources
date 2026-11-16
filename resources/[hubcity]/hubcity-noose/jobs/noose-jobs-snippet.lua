-- ============================================================================
-- Hub City Roleplay 5M — NOOSE job for QBOX
-- ============================================================================
-- WHERE THIS GOES:
--   File:  resources/[qbx]/qbx_core/shared/jobs.lua
--          (on Daniel's PC: C:\HubCityServer\server-data\resources\[qbx]\qbx_core\shared\jobs.lua
--           — the [qbx] folder name can vary; find the folder that contains qbx_core)
--
-- HOW:
--   Same drill as the pack's other jobs (jobs/qbx-jobs-snippet.lua in the
--   pack root): paste the entry below INSIDE the big jobs table, alongside
--   the existing jobs — right next to the bailbonds / bountyhunter entries
--   is a good spot. Make sure the entry above ends with a comma. Do NOT
--   paste it above `return {` or below the final closing `}`.
--
-- THEN:
--   Save the file and restart the whole server (or restart qbx_core).
--   Jobs only load when qbx_core starts. Hire with /setjob <id> noose <grade>.
--
-- WHY THE LABEL ISN'T "NOOSE":
--   NOOSE is an UNDERCOVER department. The job key stays 'noose' (that's
--   what this resource checks), but the LABEL — the text players see in
--   job menus, the phone, and paychecks — is the bland "Federal Task
--   Force". A marked-up "NOOSE" label on a paycheck would blow the cover
--   the department exists to keep. The NOOSE name lives where it belongs:
--   in the internal key, the vehicle plates, and with the officers.
--
-- GRADES:
--   [0] Operative       — field agent; garage access
--   [1] Handler         — runs informants: register CIs, review + pay tips
--   [2] Senior Handler  — same program access, seniority + pay
--   [3] Director        — boss grade (isboss + bankAuth, like the pack's
--                         other boss grades). ONLY the Director sees a
--                         CI's real identity — see Config.Permissions.
-- ============================================================================

    ['noose'] = {
        label = 'Federal Task Force',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = { name = 'Operative', payment = 120 },
            [1] = { name = 'Handler', payment = 160 },
            [2] = { name = 'Senior Handler', payment = 200 },
            [3] = { name = 'Director', isboss = true, bankAuth = true, payment = 260 },
        },
    },
