Config = {}

-- ============================================================================
-- Front desk — where the "Fill out an application" target sits.
-- HCPD headquarters, Mission Row PD public lobby.
--
-- ⚠️ VERIFY IN GAME ON FIRST VISIT: this point is the lobby centre of the
-- Mission Row interior, not a surveyed desk position. Stand at the front
-- desk, grab your coords (txAdmin / a coords tool), and change this ONE
-- line so the target sits exactly on the desk. Radius is generous on
-- purpose until then.
-- ============================================================================
Config.Desk = {
    coords = vector3(248.0, -291.0, 49.5),
    radius = 2.5,
}

-- Departments a player can apply to. `job` is the internal Qbox job key the
-- hire is given with /setjob — keys never change, only labels do.
Config.Departments = {
    police = {
        label = 'HCPD — Law Enforcement',
        shortLabel = 'HCPD',
        job = 'police',
    },
    ambulance = {
        label = 'EMS — Medical Services',
        shortLabel = 'EMS',
        job = 'ambulance',
    },
}

-- Discord webhook for the #job-applications channel.
-- Create it at install time: Discord → #job-applications → Edit Channel →
-- Integrations → Webhooks → New Webhook → Copy URL → paste it here.
-- Leave as '' to disable Discord posting (applications still save to the
-- database). Treat the URL like a password: anyone who has it can post to
-- the channel. It lives ONLY in this server-side config — never share it.
Config.DiscordWebhook = ''
Config.WebhookUsername = 'Hub City Applications'

-- Also ping on-duty HCPD/EMS staff in game when an application lands?
-- Off by default — Discord + the database are the review queue.
Config.NotifyStaffInGame = false

-- Field length caps (server enforces these, the form is only a suggestion).
Config.MaxLengths = {
    name = 60,
    phone = 24,
    experience = 500,
    statement = 1000,
}
