SELECT *
FROM superstore_sql;

SELECT COUNT(*) 
FROM superstore_sql;

DESCRIBE 
superstore_sql;

SELECT profit
FROM superstore_sql
WHERE profit NOT REGEXP '^-?[0-9]+\\.?[0-9]*$'
LIMIT 20;

SET SQL_SAFE_UPDATES = 0;

UPDATE superstore_sql
SET profit = TRIM(REPLACE(REPLACE(REPLACE(profit, '?', ''), ',', ''), '$', ''));

ALTER TABLE superstore_sql
MODIFY COLUMN profit DECIMAL(10,2);

ALTER TABLE superstore_sql 
MODIFY COLUMN `Order Date` DATE;

ALTER TABLE superstore_sql 
MODIFY COLUMN `Ship Date` DATE;

SELECT DISTINCT `Order Date`
FROM superstore_sql
WHERE `Order Date` LIKE '1%-%-%'
ORDER BY 1
LIMIT 30;

SELECT `Order Date`
FROM superstore_sql
LIMIT 10;

UPDATE superstore_sql
SET `Order Date` = STR_TO_DATE(`Order Date`, '%d-%m-%Y');

UPDATE superstore_sql
SET `Ship Date` = STR_TO_DATE(`Ship Date`, '%d-%m-%Y');

ALTER TABLE superstore_sql 
MODIFY COLUMN `Order Date` DATE;

ALTER TABLE superstore_sql 
MODIFY COLUMN `Ship Date` DATE;

SELECT `Order Date`, `Ship Date`, profit
FROM superstore_sql
ORDER BY `Order Date`
LIMIT 10;

SELECT Region, Category,
       SUM(Sales)  AS total_sales,
       SUM(profit) AS total_profit,
       ROUND(SUM(profit)/SUM(Sales)*100, 1) AS margin_pct
FROM superstore_sql
GROUP BY Region, Category
ORDER BY Region, margin_pct;

SELECT CASE
         WHEN Discount = 0 THEN '0%'
         WHEN Discount <= 0.20 THEN '1-20%'
         WHEN Discount <= 0.30 THEN '21-30%'
         ELSE '30%+'
       END AS discount_band,
       SUM(profit) AS total_profit,
       AVG(profit) AS avg_profit,
       COUNT(*) AS num_orders
FROM superstore_sql
GROUP BY discount_band
ORDER BY discount_band;

SELECT `Sub-Category`,
       SUM(Sales)     AS total_sales,
       SUM(profit)    AS total_profit,
       AVG(Discount)  AS avg_discount
FROM superstore_sql
GROUP BY `Sub-Category`
ORDER BY total_sales ASC;

SELECT Region, `Sub-Category`,
       COUNT(*)      AS n_orders,
       AVG(Discount) AS avg_discount,
       SUM(Sales)    AS total_sales,
       SUM(profit)   AS total_profit
FROM superstore_sql
WHERE `Sub-Category` IN ('Tables', 'Bookcases')
GROUP BY Region, `Sub-Category`
ORDER BY total_profit ASC;

SELECT Region, `Sub-Category`, 
       SUM(profit) AS total_profit
FROM superstore_sql
GROUP BY Region, `Sub-Category`
HAVING SUM(profit) < 0
ORDER BY total_profit ASC;