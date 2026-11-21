-- SQL used in online_retail_analysis.ipynb (SQLite)
-- Tables:
--   raw_sales : the original file, loaded as it is
--   sales     : cleaned sales (snake_case columns: invoice_no, stock_code, description, quantity,
--               invoice_date, unit_price, customer_id, country, revenue, month, weekday, hour)
--   returns   : cancelled invoices (quantity and revenue are negative)
-- The notebook shows how raw_sales is cleaned into sales and returns.

-- 1. Data quality: row counts and problem counts
SELECT COUNT(*)                         AS total_rows,
       SUM(CustomerID IS NULL)          AS missing_customer_id,
       SUM(Description IS NULL)         AS missing_description,
       SUM(Quantity <= 0)               AS qty_zero_or_negative,
       SUM(UnitPrice <= 0)              AS price_zero_or_negative,
       SUM(InvoiceNo LIKE 'C%')         AS cancelled_lines
FROM raw_sales;

-- 2. Data quality: duplicate rows
SELECT SUM(cnt - 1) AS extra_duplicate_rows
FROM (
    SELECT COUNT(*) AS cnt
    FROM raw_sales
    GROUP BY InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country
    HAVING COUNT(*) > 1
);

-- 3. Data quality: non-product stock codes
SELECT StockCode, MAX(Description) AS description, COUNT(*) AS rows_count, ROUND(SUM(Quantity * UnitPrice), 0) AS value
FROM raw_sales
WHERE StockCode NOT GLOB '[0-9][0-9][0-9][0-9][0-9]*'
GROUP BY StockCode
ORDER BY rows_count DESC
LIMIT 10;

-- 4. Largest order lines
SELECT InvoiceNo, StockCode, Description, Quantity, UnitPrice, InvoiceDate, CustomerID
FROM raw_sales
ORDER BY Quantity DESC
LIMIT 3;

-- 5. Check cancellations of the two huge orders
SELECT InvoiceNo, Description, Quantity, UnitPrice, InvoiceDate, CustomerID
FROM raw_sales
WHERE InvoiceNo IN ('581483', 'C581484', '541431', 'C541433')
ORDER BY StockCode, InvoiceDate;

-- 6. Monthly revenue and change vs previous month
WITH monthly AS (
    SELECT month,
           ROUND(SUM(revenue), 0)                                AS revenue,
           COUNT(DISTINCT invoice_no)                            AS orders,
           ROUND(SUM(revenue) / COUNT(DISTINCT invoice_no), 2)   AS avg_order_value
    FROM sales
    GROUP BY month
)
SELECT month, revenue, orders, avg_order_value,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1)            AS pct_change_vs_prev_month
FROM monthly
ORDER BY month;

-- 7. Top 10 products
SELECT stock_code,
       MAX(description)                       AS product,
       SUM(quantity)                          AS units_sold,
       ROUND(SUM(revenue), 0)                 AS revenue,
       ROUND(100.0 * SUM(revenue) / (SELECT SUM(revenue) FROM sales), 2) AS pct_of_total_revenue
FROM sales
GROUP BY stock_code
ORDER BY revenue DESC
LIMIT 10;

-- 8. Top 10 countries
SELECT country,
       COUNT(DISTINCT invoice_no)   AS orders,
       COUNT(DISTINCT customer_id)  AS customers,
       ROUND(SUM(revenue), 0)       AS revenue,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2) AS pct_of_total
FROM sales
GROUP BY country
ORDER BY revenue DESC
LIMIT 10;

-- 9. Best product in each of the top 5 countries
WITH p AS (
    SELECT country, stock_code, MAX(description) AS product, ROUND(SUM(revenue), 0) AS revenue,
           RANK() OVER (PARTITION BY country ORDER BY SUM(revenue) DESC) AS rk
    FROM sales
    WHERE country IN (SELECT country FROM sales GROUP BY country ORDER BY SUM(revenue) DESC LIMIT 5)
    GROUP BY country, stock_code
)
SELECT country, product, revenue
FROM p
WHERE rk = 1
ORDER BY revenue DESC;

-- 10. Orders and revenue by weekday
SELECT weekday, COUNT(DISTINCT invoice_no) AS orders, ROUND(SUM(revenue), 0) AS revenue
FROM sales
GROUP BY weekday
ORDER BY revenue DESC;

-- 11. Busiest hours
SELECT hour, COUNT(DISTINCT invoice_no) AS orders, ROUND(SUM(revenue), 0) AS revenue
FROM sales
GROUP BY hour
ORDER BY orders DESC
LIMIT 5;

-- 12. Customers by number of orders
WITH c AS (
    SELECT customer_id, COUNT(DISTINCT invoice_no) AS orders, SUM(revenue) AS revenue
    FROM sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT CASE WHEN orders = 1 THEN '1 order'
            WHEN orders BETWEEN 2 AND 5 THEN '2 to 5 orders'
            ELSE '6 or more orders' END   AS customer_group,
       COUNT(*)                           AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers,
       ROUND(SUM(revenue), 0)             AS revenue,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS pct_of_revenue
FROM c
GROUP BY customer_group
ORDER BY MIN(orders);

-- 13. Top 10 customers with running share
WITH cust AS (
    SELECT customer_id, COUNT(DISTINCT invoice_no) AS orders, ROUND(SUM(revenue), 0) AS revenue
    FROM sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT customer_id, orders, revenue,
       ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC)
             / (SELECT SUM(revenue) FROM sales WHERE customer_id IS NOT NULL), 1) AS cumulative_pct_of_known_revenue
FROM cust
ORDER BY revenue DESC
LIMIT 10;

-- 14. Sales vs returns
SELECT 'sales' AS table_name, COUNT(DISTINCT invoice_no) AS invoices, ROUND(SUM(revenue), 0) AS value FROM sales
UNION ALL
SELECT 'returns', COUNT(DISTINCT invoice_no), ROUND(SUM(revenue), 0) FROM returns;

-- 15. Top 10 returned products
SELECT stock_code, MAX(description) AS product,
       SUM(-quantity) AS units_returned, ROUND(SUM(-revenue), 0) AS value_returned
FROM returns
GROUP BY stock_code
ORDER BY value_returned DESC
LIMIT 10;

