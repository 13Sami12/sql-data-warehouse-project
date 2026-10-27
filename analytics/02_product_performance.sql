/* PRODUCT PERFORMANCE - part-to-whole, ranking, cost/price segmentation */
USE DataWarehouse;
GO

-- 1) Which categories contribute most to overall sales?
WITH category_sales AS (
    SELECT p.category, SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
    GROUP BY p.category
)
SELECT category, total_sales,
       SUM(total_sales) OVER ()                                              AS overall_sales,
       CONCAT(ROUND(CAST(total_sales AS FLOAT) / SUM(total_sales) OVER () * 100, 2), '%') AS pct_of_total
FROM category_sales
ORDER BY total_sales DESC;

-- 2) Top 5 / bottom 5 products by revenue
SELECT * FROM (
    SELECT p.product_name, SUM(f.sales_amount) AS total_revenue,
           RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_best,
           RANK() OVER (ORDER BY SUM(f.sales_amount) ASC)  AS rank_worst
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
    GROUP BY p.product_name
) r
WHERE rank_best <= 5 OR rank_worst <= 5
ORDER BY total_revenue DESC;

-- 3) Product segmentation by cost range
WITH product_segments AS (
    SELECT product_key, product_name, cost,
           CASE WHEN cost < 100 THEN 'Below 100'
                WHEN cost BETWEEN 100 AND 500 THEN '100-500'
                WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
                ELSE 'Above 1000' END AS cost_range
    FROM gold.dim_products
)
SELECT cost_range, COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;
