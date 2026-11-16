-- Hub City Drag Race — timing board table.
-- Import into the Qbox server database (HeidiSQL: open the database,
-- File → Run SQL file, or paste into a query tab and run).
-- The resource ALSO creates this table itself on start if it's missing,
-- so importing by hand is a belt-and-braces step, not a hard requirement.
--
-- One row per finished pass (solo or head-to-head). False starts and
-- DNFs are never recorded. `speed` is the trap speed at the finish
-- line, in the unit set by Config.SpeedUnit (mph by default).

CREATE TABLE IF NOT EXISTS `hubcity_drag_times` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `vehicle` VARCHAR(50) NOT NULL,
    `time_ms` INT NOT NULL,          -- elapsed time, milliseconds
    `speed` DECIMAL(6,2) NOT NULL,   -- trap speed (mph unless config says kmh)
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_drag_time` (`time_ms`),
    INDEX `idx_drag_citizen` (`citizenid`, `time_ms`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
