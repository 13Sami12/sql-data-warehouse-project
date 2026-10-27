/*
Data quality checks for the Gold layer.
Expectation: every query returns NO ROWS.
*/
USE DataWarehouse;
GO

-- surrogate key uniqueness
SELECT customer_key, COUNT(*) AS cnt FROM gold.dim_customers GROUP BY customer_key HAVING COUNT(*) > 1;
SELECT product_key,  COUNT(*) AS cnt FROM gold.dim_products  GROUP BY product_key  HAVING COUNT(*) > 1;

-- business key uniqueness (join fan-out check)
SELECT customer_id,    COUNT(*) FROM gold.dim_customers GROUP BY customer_id    HAVING COUNT(*) > 1;
SELECT product_number, COUNT(*) FROM gold.dim_products  GROUP BY product_number HAVING COUNT(*) > 1;

-- referential integrity: fact rows without a matching dimension
SELECT f.*
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products  p ON p.product_key  = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL;
