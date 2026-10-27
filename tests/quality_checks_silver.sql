/*
Data quality checks for the Silver layer.
Expectation: every query returns NO ROWS (unless stated otherwise).
Run after: EXEC silver.load_silver;
*/
USE DataWarehouse;
GO

-- crm_cust_info: duplicates / nulls in primary key
SELECT cst_id, COUNT(*) AS cnt FROM silver.crm_cust_info GROUP BY cst_id HAVING COUNT(*) > 1 OR cst_id IS NULL;
-- crm_cust_info: unwanted spaces
SELECT cst_firstname, cst_lastname FROM silver.crm_cust_info WHERE cst_firstname <> TRIM(cst_firstname) OR cst_lastname <> TRIM(cst_lastname);
-- crm_cust_info: standardization (expect only Single/Married/n/a and Female/Male/n/a)
SELECT DISTINCT cst_marital_status, cst_gndr FROM silver.crm_cust_info;

-- crm_prd_info: duplicate / null product id
SELECT prd_id, COUNT(*) FROM silver.crm_prd_info GROUP BY prd_id HAVING COUNT(*) > 1 OR prd_id IS NULL;
-- crm_prd_info: negative or null cost
SELECT prd_id, prd_cost FROM silver.crm_prd_info WHERE prd_cost < 0 OR prd_cost IS NULL;
-- crm_prd_info: invalid date order
SELECT * FROM silver.crm_prd_info WHERE prd_end_dt < prd_start_dt;
-- crm_prd_info: standardization (expect Mountain/Road/Other Sales/Touring/n/a)
SELECT DISTINCT prd_line FROM silver.crm_prd_info;

-- crm_sales_details: invalid date order
SELECT * FROM silver.crm_sales_details WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;
-- crm_sales_details: sales = quantity * price, no null/zero/negative
SELECT DISTINCT sls_sales, sls_quantity, sls_price FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0;

-- erp_cust_az12: out-of-range birthdates
SELECT DISTINCT bdate FROM silver.erp_cust_az12 WHERE bdate < '1924-01-01' OR bdate > GETDATE();
-- erp_cust_az12: standardization
SELECT DISTINCT gen FROM silver.erp_cust_az12;

-- erp_loc_a101: country standardization (inspect the list manually)
SELECT DISTINCT cntry FROM silver.erp_loc_a101 ORDER BY cntry;

-- erp_px_cat_g1v2: unwanted spaces
SELECT * FROM silver.erp_px_cat_g1v2 WHERE cat <> TRIM(cat) OR subcat <> TRIM(subcat) OR maintenance <> TRIM(maintenance);
