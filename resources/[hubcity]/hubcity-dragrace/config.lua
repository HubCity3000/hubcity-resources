Config = {}

-- =====================================================================
--  Hub City Drag Race — Sandy Shores Drag Strip
-- =====================================================================
--  Drag racing on the Sandy Shores Airfield (McKenzie Field) runway:
--  two staging lanes, a 3-2-1-GO countdown, false-start red lights,
--  elapsed time + trap speed at the finish, and a timing board backed
--  by the `hubcity_drag_times` table. No wagering — Daniel didn't ask
--  for betting, so there is none.
--
--  ⚠️ EVERY coordinate in this file is a FIRST-PASS ESTIMATE, like
--  every other Hub City coordinate: verify in game on the first visit
--  and nudge the numbers here (they're all one-line fixes). See the
--  resource README and the pack INSTALL.md drag racing section.
-- =====================================================================

-- The start line: centre point BETWEEN the two lanes, on the runway
-- near its WEST end, so the run goes east with the whole strip ahead.
-- Runway centre is roughly (1743, 3278, 41) and it runs east–west.
-- ⚠️ VERIFY IN GAME: if the lanes sit off the pavement or angled wrong,
-- move this point (and check Config.Direction) — everything else
-- (staging boxes, finish line) is derived from these two values.
Config.StartLine = vector3(1540.0, 3278.0, 41.5)

-- Race direction as a flat unit vector: (1, 0) = due east.
-- ⚠️ VERIFY IN GAME with the start line above.
Config.Direction = vector2(1.0, 0.0)

-- How far each lane sits from the centre line (metres, either side).
-- Lane 1 is on the +perpendicular side (north, with the direction
-- above), lane 2 on the other.
Config.LaneOffset = 3.2

-- How close to the lane's staging point a car has to be to stage
-- (metres). The staging point is ON the start line.
Config.StageRadius = 4.0

-- Race distance. 'quarter' = 402.336 m (quarter mile), 'eighth' =
-- 201.168 m (eighth mile). The quarter uses most of the runway — if
-- the shutdown area past the finish feels short in game, switch to
-- 'eighth' here; the finish line moves automatically.
Config.DistancePreset = 'quarter'
Config.Distances = {
    quarter = 402.336,
    eighth  = 201.168,
}

-- Countdown length (seconds): 3 - 2 - 1 - GO.
Config.CountdownSeconds = 3

-- How long a lone staged driver waits for an opponent before their
-- solo timed pass starts (seconds). Stage a second car during the
-- wait and it becomes a head-to-head instead.
Config.SoloWaitSeconds = 10

-- After GO, how long (seconds) racers get to finish before the run is
-- called and unfinished lanes are marked DNF.
Config.RaceTimeoutSeconds = 90

-- Moving more than this (metres) from the staged spot before GO is a
-- false start: red light, run void.
Config.FalseStartDistance = 1.5

-- Sanity floor for a recorded time (ms). Anything faster is rejected
-- server-side as impossible — light anti-cheat, not a guarantee.
Config.MinPlausibleTimeMs = 2000

-- Trap speed unit shown to players and stored on the board: 'mph'
-- (Texas) or 'kmh'.
Config.SpeedUnit = 'mph'

-- Timing board: walk-up point near the start line, off the runway's
-- south edge — target it to see the top 10 and your personal best.
-- ⚠️ VERIFY IN GAME: nudge so it sits somewhere sensible by the strip.
Config.Board = {
    coords = vector3(1532.0, 3266.0, 41.5),
    radius = 2.0,
    label  = 'View timing board',
}

-- Map blip at the start line.
Config.Blip = {
    coords = vector3(1540.0, 3278.0, 41.5), -- same spot as Config.StartLine
    sprite = 315,  -- flag; cosmetic, change freely
    colour = 5,    -- yellow
    scale  = 0.9,
    label  = 'Sandy Shores Drag Strip',
}

-- Draw simple ground markers at the staging boxes (and the finish
-- line while a race is on) so drivers can see where to sit.
Config.DrawMarkers = true
