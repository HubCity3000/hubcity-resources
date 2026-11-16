-- Optional import file. The server ALSO creates this table automatically
-- on start (CREATE TABLE IF NOT EXISTS in server/main.lua).
-- Deals are the black market's core record: an AGREED deal (items, total,
-- assigned dealer location, expiry) that survives server restarts.
CREATE TABLE IF NOT EXISTS `hubcity_deals` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `dealer_index` INT NOT NULL,
    `items` TEXT NOT NULL,               -- JSON: [{item=..., amount=...}, ...]
    `total` INT NOT NULL,
    `status` VARCHAR(16) NOT NULL DEFAULT 'agreed', -- agreed | completed | expired
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` BIGINT NOT NULL,        -- unix epoch
    PRIMARY KEY (`id`),
    INDEX `idx_deals_citizen` (`citizenid`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
