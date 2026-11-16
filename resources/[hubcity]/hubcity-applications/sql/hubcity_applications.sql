-- Hub City Applications — submissions table.
-- Import into the Qbox server database (HeidiSQL: open the database,
-- File → Run SQL file, or paste into a query tab and run).
-- The resource ALSO creates this table itself on start if it's missing,
-- so importing by hand is a belt-and-braces step, not a hard requirement.
--
-- Review flow: rows start as status 'pending'. When staff decide, set
-- status to 'approved' or 'denied' (HeidiSQL table view is fine). A player
-- can only re-apply to a department once their old row is no longer
-- 'pending'.

CREATE TABLE IF NOT EXISTS `hubcity_applications` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `charname` VARCHAR(100) NOT NULL,
    `department` VARCHAR(32) NOT NULL,
    `phone` VARCHAR(32) NOT NULL,
    `experience` TEXT NOT NULL,
    `statement` TEXT NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_citizen_dept_status` (`citizenid`, `department`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
