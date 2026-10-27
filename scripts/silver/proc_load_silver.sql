/*
Stored procedure: silver.load_silver
Bronze -> Silver ETL (truncate & insert) applying cleansing rules:
  * remove duplicates / null keys, trim strings
  * normalize coded values (gender, marital status, product line, country)
  * derive columns (category id, product end date, sales/price consistency)
  * convert INT dates (YYYYMMDD) to DATE, null out invalid ones
Usage:  EXEC silver.load_silver;
*/
USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @batch_start DATETIME = GETDATE();

    BEGIN TRY
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        ------------------------------------------------------------------ crm_cust_info
        SET @start_time = GETDATE();
        PRINT '>> silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        INSERT INTO silver.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
        SELECT
            cst_id,
            TRIM(cst_key),
            TRIM(cst_firstname),
            TRIM(cst_lastname),
            CASE UPPER(TRIM(cst_marital_status)) WHEN 'S' THEN 'Single' WHEN 'M' THEN 'Married' ELSE 'n/a' END,
            CASE UPPER(TRIM(cst_gndr))           WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male'    ELSE 'n/a' END,
            cst_create_date
        FROM (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE flag_last = 1;                       -- keep the most recent record per customer
        PRINT '   duration: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR) + ' s';

        ------------------------------------------------------------------ crm_prd_info
        SET @start_time = GETDATE();
        PRINT '>> silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        INSERT INTO silver.crm_prd_info (prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')               AS cat_id,   -- matches erp_px_cat_g1v2.id
            SUBSTRING(prd_key, 7, LEN(prd_key))                       AS prd_key,  -- matches sales.sls_prd_key
            TRIM(prd_nm),
            ISNULL(prd_cost, 0),
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain' WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales' WHEN 'T' THEN 'Touring' ELSE 'n/a' END,
            prd_start_dt,
            -- end date = day before the next version's start date (SCD-like validity window)
            DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt))
        FROM bronze.crm_prd_info;
        PRINT '   duration: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR) + ' s';

        ------------------------------------------------------------------ crm_sales_details
        SET @start_time = GETDATE();
        PRINT '>> silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        INSERT INTO silver.crm_sales_details (sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) <> 8 THEN NULL ELSE CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE) END,
            CASE WHEN sls_ship_dt  <= 0 OR LEN(sls_ship_dt)  <> 8 THEN NULL ELSE CAST(CAST(sls_ship_dt  AS VARCHAR(8)) AS DATE) END,
            CASE WHEN sls_due_dt   <= 0 OR LEN(sls_due_dt)   <> 8 THEN NULL ELSE CAST(CAST(sls_due_dt   AS VARCHAR(8)) AS DATE) END,
            -- recompute sales when missing / wrong
            CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> sls_quantity * ABS(sls_price)
                 THEN sls_quantity * ABS(sls_price) ELSE sls_sales END,
            sls_quantity,
            -- derive price when missing / invalid
            CASE WHEN sls_price IS NULL OR sls_price <= 0
                 THEN sls_sales / NULLIF(sls_quantity, 0) ELSE sls_price END
        FROM bronze.crm_sales_details;
        PRINT '   duration: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR) + ' s';

        ------------------------------------------------------------------ erp_cust_az12
        SET @start_time = GETDATE();
        PRINT '>> silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END,   -- drop 'NAS' prefix
            CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END,                      -- future birthdates are invalid
            CASE UPPER(TRIM(gen)) WHEN 'F' THEN 'Female' WHEN 'FEMALE' THEN 'Female'
                                  WHEN 'M' THEN 'Male'   WHEN 'MALE'   THEN 'Male' ELSE 'n/a' END
        FROM bronze.erp_cust_az12;
        PRINT '   duration: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR) + ' s';

        ------------------------------------------------------------------ erp_loc_a101
        SET @start_time = GETDATE();
        PRINT '>> silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT
            REPLACE(cid, '-', ''),
            CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                 WHEN TRIM(cntry) = 'AU' THEN 'Australia'
                 WHEN TRIM(cntry) = 'CA' THEN 'Canada'
                 WHEN TRIM(cntry) = 'FR' THEN 'France'
                 WHEN TRIM(cntry) = 'UK' THEN 'United Kingdom'
                 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                 ELSE TRIM(cntry) END
        FROM bronze.erp_loc_a101;
        PRINT '   duration: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR) + ' s';

        ------------------------------------------------------------------ erp_px_cat_g1v2
        SET @start_time = GETDATE();
        PRINT '>> silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
        SELECT id, cat, subcat, maintenance FROM bronze.erp_px_cat_g1v2;
        PRINT '   duration: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR) + ' s';

        PRINT 'Silver layer loaded in ' + CAST(DATEDIFF(SECOND, @batch_start, GETDATE()) AS NVARCHAR) + ' s';
    END TRY
    BEGIN CATCH
        PRINT '=========================================';
        PRINT 'ERROR DURING LOADING SILVER LAYER';
        PRINT 'Message: ' + ERROR_MESSAGE();
        PRINT 'Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '=========================================';
        THROW;
    END CATCH
END;
GO
