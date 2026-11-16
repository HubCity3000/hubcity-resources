-- Optional import file. The server ALSO creates this table automatically
-- on start (CREATE TABLE IF NOT EXISTS in server/main.lua).
-- One row per racer per finished race. Finishers get a position and a
-- time; DNFs get position 0 and a NULL time. The tablet app's records
-- view aggregates wins and best times per player per route from this.
CREATE TABLE IF NOT EXISTS `hubcity_streetrace_records` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `name` VARCHAR(80) NOT NULL,
    `route_id` VARCHAR(40) NOT NULL,
    `route_name` VARCHAR(80) NOT NULL,
    `position` INT NOT NULL DEFAULT 0,   -- 1..n for finishers, 0 = DNF
    `time_ms` INT NULL,                  -- finish time in ms, NULL for DNF
    `won` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_sr_route` (`route_id`),
    INDEX `idx_sr_citizen` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
