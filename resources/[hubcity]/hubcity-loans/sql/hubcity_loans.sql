-- Optional import file. The server ALSO creates this table automatically
-- on start (CREATE TABLE IF NOT EXISTS in server/main.lua), so importing
-- is belt-and-braces. Run against the Qbox database (Qbox_F9F78B).
CREATE TABLE IF NOT EXISTS `hubcity_loans` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `plate` VARCHAR(12) NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `principal` INT NOT NULL,        -- amount financed (after down payment, incl. interest basis below)
    `remaining` INT NOT NULL,        -- amount still owed (incl. interest)
    `payment_amount` INT NOT NULL,   -- per scheduled payment
    `payments_left` INT NOT NULL,
    `next_due` BIGINT NOT NULL,      -- unix epoch of next scheduled payment
    `missed` INT NOT NULL DEFAULT 0, -- consecutive missed payments
    `status` VARCHAR(16) NOT NULL DEFAULT 'active', -- active | paid | defaulted | cleared
    `vehicle_garage` VARCHAR(50) DEFAULT NULL,      -- garage to restore on unlock/payoff
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_loans_citizen` (`citizenid`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
