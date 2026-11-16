-- Hub City NOOSE — CI (confidential informant) program tables.
-- Import into the Qbox server database (HeidiSQL: open the database,
-- File → Run SQL file, or paste into a query tab and run).
-- The resource ALSO creates these tables itself on start if they're
-- missing, so importing by hand is a belt-and-braces step, not a hard
-- requirement.
--
-- hubcity_ci: one row per informant file. A citizen can only have ONE
-- 'active' file at a time (enforced by the resource). Rows are never
-- deleted — deactivation flips status to 'inactive' so the file (and
-- its tip history) stays auditable.
--
-- hubcity_ci_tips: one row per tip. Lifecycle:
--   'pending'  → handler hasn't decided yet
--   'paid'     → approved; `payment` is the amount, `handled_by` the
--                handler's citizenid, `handled_at` when. `delivered`
--                flips to 1 when the money actually reaches the CI's
--                bank (instant if they're online; otherwise on their
--                next check-in — see the resource README).
--   'rejected' → handler declined it; no payment.

CREATE TABLE IF NOT EXISTS `hubcity_ci` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `codename` VARCHAR(32) NOT NULL,
    `handler_citizenid` VARCHAR(50) NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_ci_citizen_status` (`citizenid`, `status`),
    INDEX `idx_ci_codename_status` (`codename`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `hubcity_ci_tips` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `ci_id` INT NOT NULL,
    `tip` TEXT NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
    `payment` INT NOT NULL DEFAULT 0,
    `handled_by` VARCHAR(50) DEFAULT NULL,
    `delivered` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `handled_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_tips_ci` (`ci_id`),
    INDEX `idx_tips_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
