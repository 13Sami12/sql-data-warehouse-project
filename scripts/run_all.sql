/* Runs the whole pipeline (after the scripts were created). SQLCMD mode not required. */
USE DataWarehouse;
GO
EXEC bronze.load_bronze;
GO
EXEC silver.load_silver;
GO
SELECT 'gold.dim_customers' AS object_name, COUNT(*) AS row_count FROM gold.dim_customers
UNION ALL SELECT 'gold.dim_products', COUNT(*) FROM gold.dim_products
UNION ALL SELECT 'gold.fact_sales',   COUNT(*) FROM gold.fact_sales;
GO
