/* CUSTOMER BEHAVIOR - demographics, RFM-like segmentation, top customers */
USE DataWarehouse;
GO

-- 1) Customers & revenue by country and gender
SELECT c.country, c.gender, COUNT(DISTINCT c.customer_key) AS customers, SUM(f.sales_amount) AS revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY c.country, c.gender
ORDER BY revenue DESC;

-- 2) Segmentation: VIP / Regular / New (lifespan + spending)
WITH customer_spending AS (
    SELECT c.customer_key,
           SUM(f.sales_amount) AS total_spending,
           MIN(f.order_date)   AS first_order,
           MAX(f.order_date)   AS last_order,
           DATEDIFF(MONTH, MIN(f.order_date), MAX(f.order_date)) AS lifespan_months
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
)
SELECT customer_segment, COUNT(customer_key) AS total_customers
FROM (
    SELECT customer_key,
           CASE WHEN lifespan_months >= 12 AND total_spending > 5000  THEN 'VIP'
                WHEN lifespan_months >= 12 AND total_spending <= 5000 THEN 'Regular'
                ELSE 'New' END AS customer_segment
    FROM customer_spending
) s
GROUP BY customer_segment
ORDER BY total_customers DESC;

-- 3) Top 10 customers by revenue
SELECT TOP 10 c.customer_key, c.first_name, c.last_name, SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC;
