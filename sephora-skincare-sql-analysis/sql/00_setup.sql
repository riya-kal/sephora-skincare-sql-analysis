-- MySQL 8.0+ | Reproducible setup from the cleaned CSV
-- Import data/sephora_skincare_clean.csv with MySQL Workbench Table Data Import Wizard.
-- Choose schema sephora_portfolio and table skincare_products; ensure column types below.
CREATE DATABASE IF NOT EXISTS sephora_portfolio;
USE sephora_portfolio;

CREATE TABLE IF NOT EXISTS skincare_products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_name TEXT,
    brand_name VARCHAR(255),
    secondary_category VARCHAR(255),
    price_usd DECIMAL(10,2),
    rating DECIMAL(4,2),
    review_count INT UNSIGNED,
    price_tier VARCHAR(20)
);

-- If local file loading is enabled, import the CSV with this command.
-- Replace /absolute/path/to/ with the actual path on your machine.
-- Alternatively, use Workbench's Table Data Import Wizard instead.
/*
LOAD DATA LOCAL INFILE '/absolute/path/to/sephora_skincare_clean.csv'
INTO TABLE skincare_products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, product_name, brand_name, secondary_category,
 @price, @rating, @reviews, price_tier)
SET price_usd = NULLIF(@price,''),
    rating = NULLIF(@rating,''),
    review_count = NULLIF(@reviews,'');
*/

-- After import, check the expected 2,420 rows.
SELECT COUNT(*) AS imported_products FROM skincare_products;
