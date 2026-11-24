-- THE PRICE OF BEAUTY | Sephora Skincare SQL Portfolio Analysis
-- MySQL 8.0+
-- Run 00_setup.sql first to create the cleaned product table.
-- Ratings are customer review scores, not evidence of clinical effectiveness.

USE sephora_portfolio;

-- 01. Portfolio overview: all skincare listings
SELECT COUNT(*) AS total_products,
       ROUND(AVG(price_usd),2) AS avg_price,
       ROUND(AVG(rating),2) AS avg_rating,
       MIN(price_usd) AS min_price,
       MAX(price_usd) AS max_price,
       SUM(rating IS NULL) AS missing_ratings
FROM skincare_products;

-- 02. Price-tier distribution and ratings (all listings)
SELECT price_tier, COUNT(*) AS total_products,
       ROUND(AVG(price_usd),2) AS avg_price,
       ROUND(AVG(rating),3) AS avg_rating,
       COUNT(rating) AS rated_products,
       ROUND(AVG(review_count),0) AS avg_reviews
FROM skincare_products
GROUP BY price_tier
ORDER BY FIELD(price_tier,'Budget','Affordable','Premium','Luxury');

-- 03. Price-tier satisfaction among products with >= 100 reviews
SELECT price_tier, COUNT(*) AS total_products,
       ROUND(AVG(price_usd),2) AS avg_price,
       ROUND(AVG(rating),3) AS avg_rating,
       ROUND(SUM(rating * review_count)/NULLIF(SUM(review_count),0),3) AS review_weighted_rating,
       SUM(review_count) AS total_reviews
FROM skincare_products
WHERE review_count >= 100 AND rating IS NOT NULL
GROUP BY price_tier
ORDER BY FIELD(price_tier,'Budget','Affordable','Premium','Luxury');

-- 04. Pearson correlation between price and customer rating
-- Calculated on all products with >= 100 reviews (no $300 chart display cap).
WITH qualified AS (
    SELECT price_usd AS x, rating AS y
    FROM skincare_products
    WHERE review_count >= 100 AND rating IS NOT NULL AND price_usd IS NOT NULL
)
SELECT ROUND((AVG(x*y)-AVG(x)*AVG(y)) /
             NULLIF(SQRT((AVG(x*x)-POW(AVG(x),2))*(AVG(y*y)-POW(AVG(y),2))),0),4)
       AS pearson_price_rating_r
FROM qualified;

-- 05. Category-level descriptive statistics
SELECT secondary_category, COUNT(*) AS total_products,
       ROUND(AVG(price_usd),2) AS avg_price,
       ROUND(AVG(rating),3) AS avg_rating
FROM skincare_products
GROUP BY secondary_category
ORDER BY total_products DESC;

-- 06. Category × price-tier heatmap source
-- At least five products in each cell; at least 100 reviews per product.
SELECT secondary_category, price_tier, COUNT(*) AS products,
       ROUND(AVG(rating),3) AS avg_rating
FROM skincare_products
WHERE review_count >= 100 AND rating IS NOT NULL
  AND secondary_category IN ('Cleansers','Masks','Moisturizers','Sunscreen','Treatments')
GROUP BY secondary_category, price_tier
HAVING COUNT(*) >= 5
ORDER BY secondary_category,
         FIELD(price_tier,'Budget','Affordable','Premium','Luxury');

-- 07. Top-rated brands: CTEs + DENSE_RANK window function
-- Qualifying brands have >= 10 products with >= 100 reviews each.
WITH brand_metrics AS (
    SELECT brand_name, COUNT(*) AS total_products,
           ROUND(AVG(price_usd),2) AS avg_price,
           ROUND(AVG(rating),3) AS avg_rating,
           SUM(review_count) AS total_reviews
    FROM skincare_products
    WHERE review_count >= 100 AND rating IS NOT NULL AND price_usd IS NOT NULL
    GROUP BY brand_name
    HAVING COUNT(*) >= 10
), ranked_brands AS (
    SELECT *, DENSE_RANK() OVER (ORDER BY avg_rating DESC) AS brand_rank
    FROM brand_metrics
)
SELECT * FROM ranked_brands
WHERE brand_rank <= 10
ORDER BY brand_rank, brand_name;

-- 08. Product-level comparison: most-reviewed listings
SELECT product_name, brand_name, secondary_category, price_usd,
       rating, review_count, price_tier
FROM skincare_products
WHERE rating IS NOT NULL AND review_count IS NOT NULL
ORDER BY review_count DESC, product_name
LIMIT 20;
