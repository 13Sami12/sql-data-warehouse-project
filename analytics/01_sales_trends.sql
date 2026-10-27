/* SALES TRENDS - changes over time, cumulative analysis, performance (YoY) */
USE DataWarehouse;
GO

-- 1) Monthly sales, customers and units
SELECT
    DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)      AS order_month,
    SUM(sales_amount)                 AS total_sales,
    COUNT(DISTINCT customer_key)      AS total_customers,
    SUM(quantity)                     AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
ORDER BY order_month;

-- 2) Running total and moving average price (per year)
SELECT
    order_year,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_year)  AS running_total_sales,
    AVG(avg_price)   OVER (ORDER BY order_year)  AS moving_average_price
FROM (
    SELECT DATEFROMPARTS(YEAR(order_date), 1, 1) AS order_year,
           SUM(sales_amount) AS total_sales,
           AVG(price)        AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(order_date), 1, 1)
) t;

-- 3) Year-over-year performance per product (vs. product average and vs. previous year)
WITH yearly_product_sales AS (
    SELECT YEAR(f.order_date) AS order_year, p.product_name, SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date), p.product_name
)
SELECT
    order_year, product_name, current_sales,
    AVG(current_sales) OVER (PARTITION BY product_name)                          AS avg_sales,
    current_sales - AVG(current_sales) OVER (PARTITION BY product_name)          AS diff_from_avg,
    CASE WHEN current_sales > AVG(current_sales) OVER (PARTITION BY product_name) THEN 'Above Avg'
         WHEN current_sales < AVG(current_sales) OVER (PARTITION BY product_name) THEN 'Below Avg'
         ELSE 'Avg' END                                                          AS avg_change,
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year)      AS py_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
    CASE WHEN current_sales > LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) THEN 'Increase'
         WHEN current_sales < LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) THEN 'Decrease'
         ELSE 'No Change' END                                                    AS py_change
FROM yearly_product_sales
ORDER BY product_name, order_year;
