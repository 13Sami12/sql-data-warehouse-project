/*
Stored procedure: bronze.load_bronze
Loads the CSV files into the bronze layer (truncate + BULK INSERT).

@base_path = folder (as seen by the SQL Server process) that contains source_crm/ and source_erp/.
  - Docker (default, used by run.sh):  /datasets/
  - Local Windows install:             EXEC bronze.load_bronze @base_path = N'C:/path/to/repo/datasets/';

Usage:  EXEC bronze.load_bronze;
*/
USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
    @base_path NVARCHAR(500) = N'/datasets/'   -- default = Docker mount (see docker-compose.yml)
AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start DATETIME = GETDATE();
    DECLARE @sql NVARCHAR(MAX);

    BEGIN TRY
        PRINT '================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '================================================';

        -- table name, relative file path
        DECLARE @jobs TABLE (id INT IDENTITY, tbl NVARCHAR(100), file_rel NVARCHAR(200), src NVARCHAR(10));
        INSERT INTO @jobs (tbl, file_rel, src) VALUES
            ('bronze.crm_cust_info',     'source_crm/cust_info.csv',     'CRM'),
            ('bronze.crm_prd_info',      'source_crm/prd_info.csv',      'CRM'),
            ('bronze.crm_sales_details', 'source_crm/sales_details.csv', 'CRM'),
            ('bronze.erp_loc_a101',      'source_erp/LOC_A101.csv',      'ERP'),
            ('bronze.erp_cust_az12',     'source_erp/CUST_AZ12.csv',     'ERP'),
            ('bronze.erp_px_cat_g1v2',   'source_erp/PX_CAT_G1V2.csv',   'ERP');

        DECLARE @i INT = 1, @n INT = (SELECT COUNT(*) FROM @jobs), @tbl NVARCHAR(100), @file NVARCHAR(200);
        WHILE @i <= @n
        BEGIN
            SELECT @tbl = tbl, @file = @base_path + file_rel FROM @jobs WHERE id = @i;
            SET @start_time = GETDATE();
            PRINT '>> Truncating & loading: ' + @tbl;
            SET @sql = N'TRUNCATE TABLE ' + @tbl + N'; '
                     + N'BULK INSERT ' + @tbl + N' FROM ''' + @file + N''' '
                     + N'WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK);';
            EXEC sys.sp_executesql @sql;
            SET @end_time = GETDATE();
            PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' s';
            PRINT '-------------';
            SET @i += 1;
        END;

        PRINT 'Bronze layer loaded in ' + CAST(DATEDIFF(SECOND, @batch_start, GETDATE()) AS NVARCHAR) + ' s';
    END TRY
    BEGIN CATCH
        PRINT '=========================================';
        PRINT 'ERROR DURING LOADING BRONZE LAYER';
        PRINT 'Message: ' + ERROR_MESSAGE();
        PRINT 'Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '=========================================';
        THROW;
    END CATCH
END;
GO
