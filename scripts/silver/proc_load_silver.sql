
/*
===============================================================================
  Stored Procedure: silver.load_silver
  Description:      Loads and transforms CRM and ERP data into the Silver layer.
  Database:         DataWarehouse

  Monitoring:
      - Measures elapsed time for each table load (truncate + insert).
      - Records the number of rows inserted into each table.
      - Measures the total execution time.
      - Displays progress, timing, and error messages.

===============================================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StartTime      DATETIME2(7) = SYSDATETIME();
    DECLARE @TableStartTime DATETIME2(7);
    DECLARE @EndTime        DATETIME2(7);
    DECLARE @RowsInserted   BIGINT;
    DECLARE @DurationMs     BIGINT;

    BEGIN TRY
        BEGIN TRANSACTION;

        PRINT '=============================================';
        PRINT '       STARTING SILVER LAYER LOAD';
        PRINT '=============================================';


        -- =============================================
        -- 1. CRM CUSTOMER INFORMATION
        -- =============================================

        SET @TableStartTime = SYSDATETIME();

        PRINT 'Loading silver.crm_cust_info...';

        TRUNCATE TABLE silver.crm_cust_info;

        INSERT INTO silver.crm_cust_info
        (
            cst_id, cst_key, cst_firstname, cst_lastname,
            cst_marital_status, cst_gndr, cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname),
            TRIM(cst_lastname),
            CASE UPPER(TRIM(cst_marital_status))
                WHEN 'S' THEN 'Single'
                WHEN 'M' THEN 'Married'
                ELSE 'n/a'
            END,
            CASE UPPER(TRIM(cst_gndr))
                WHEN 'F' THEN 'Female'
                WHEN 'M' THEN 'Male'
                ELSE 'n/a'
            END,
            cst_create_date
        FROM
        (
            SELECT *,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) AS t
        WHERE flag_last = 1;

        SET @RowsInserted = @@ROWCOUNT;
        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @TableStartTime, SYSDATETIME()
        );

        PRINT 'crm_cust_info: ' + CAST(@RowsInserted AS VARCHAR(20))
            + ' rows inserted in ' + CAST(@DurationMs AS VARCHAR(20))
            + ' ms.';


        -- =============================================
        -- 2. CRM PRODUCT INFORMATION
        -- =============================================

        SET @TableStartTime = SYSDATETIME();

        PRINT 'Loading silver.crm_prd_info...';

        TRUNCATE TABLE silver.crm_prd_info;

        INSERT INTO silver.crm_prd_info
        (
            prd_id, cat_id, prd_key, prd_nm, prd_cost,
            prd_line, prd_start_dt, prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
            SUBSTRING(prd_key, 7, LEN(prd_key)),
            prd_nm,
            COALESCE(prd_cost, 0),
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END,
            CAST(prd_start_dt AS DATE),
            CAST(
                DATEADD(
                    DAY, -1,
                    LEAD(prd_start_dt) OVER (
                        PARTITION BY prd_key
                        ORDER BY prd_start_dt
                    )
                ) AS DATE
            )
        FROM bronze.crm_prd_info;

        SET @RowsInserted = @@ROWCOUNT;
        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @TableStartTime, SYSDATETIME()
        );

        PRINT 'crm_prd_info: ' + CAST(@RowsInserted AS VARCHAR(20))
            + ' rows inserted in ' + CAST(@DurationMs AS VARCHAR(20))
            + ' ms.';


        -- =============================================
        -- 3. CRM SALES DETAILS
        -- =============================================

        SET @TableStartTime = SYSDATETIME();

        PRINT 'Loading silver.crm_sales_details...';

        TRUNCATE TABLE silver.crm_sales_details;

        INSERT INTO silver.crm_sales_details
        (
            sls_ord_num, sls_prd_key, sls_cust_id,
            sls_order_dt, sls_ship_dt, sls_due_dt,
            sls_sales, sls_quantity, sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            CASE
                WHEN sls_order_dt = 0
                  OR LEN(sls_order_dt) <> 8 THEN NULL
                ELSE TRY_CONVERT(
                    DATE, CAST(sls_order_dt AS VARCHAR(8)), 112
                )
            END,

            CASE
                WHEN sls_ship_dt = 0
                  OR LEN(sls_ship_dt) <> 8 THEN NULL
                ELSE TRY_CONVERT(
                    DATE, CAST(sls_ship_dt AS VARCHAR(8)), 112
                )
            END,

            CASE
                WHEN sls_due_dt = 0
                  OR LEN(sls_due_dt) <> 8 THEN NULL
                ELSE TRY_CONVERT(
                    DATE, CAST(sls_due_dt AS VARCHAR(8)), 112
                )
            END,

            CASE
                WHEN sls_sales IS NULL
                  OR sls_sales <= 0
                  OR sls_sales <> sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END,

            sls_quantity,

            CASE
                WHEN sls_price IS NULL OR sls_price <= 0
                    THEN ABS(sls_sales) / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END

        FROM bronze.crm_sales_details;

        SET @RowsInserted = @@ROWCOUNT;
        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @TableStartTime, SYSDATETIME()
        );

        PRINT 'crm_sales_details: ' + CAST(@RowsInserted AS VARCHAR(20))
            + ' rows inserted in ' + CAST(@DurationMs AS VARCHAR(20))
            + ' ms.';


        -- =============================================
        -- 4. ERP CUSTOMER INFORMATION
        -- =============================================

        SET @TableStartTime = SYSDATETIME();

        PRINT 'Loading silver.erp_cust_az12...';

        TRUNCATE TABLE silver.erp_cust_az12;

        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            CASE
                WHEN cid LIKE 'NAS%'
                    THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END,

            CASE
                WHEN bdate > CAST(GETDATE() AS DATE) THEN NULL
                ELSE bdate
            END,

            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
                    THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
                    THEN 'Male'
                ELSE 'n/a'
            END
        FROM bronze.erp_cust_az12;

        SET @RowsInserted = @@ROWCOUNT;
        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @TableStartTime, SYSDATETIME()
        );

        PRINT 'erp_cust_az12: ' + CAST(@RowsInserted AS VARCHAR(20))
            + ' rows inserted in ' + CAST(@DurationMs AS VARCHAR(20))
            + ' ms.';


        -- =============================================
        -- 5. ERP LOCATION INFORMATION
        -- =============================================

        SET @TableStartTime = SYSDATETIME();

        PRINT 'Loading silver.erp_loc_a101...';

        TRUNCATE TABLE silver.erp_loc_a101;

        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT
            REPLACE(TRIM(cid), '-', ''),

            CASE
                WHEN cntry IS NULL OR TRIM(cntry) = ''
                    THEN 'n/a'
                WHEN UPPER(TRIM(cntry))
                    IN ('USA', 'UNITED STATES', 'US')
                    THEN 'United States'
                WHEN UPPER(TRIM(cntry)) = 'DE'
                    THEN 'Germany'
                ELSE TRIM(cntry)
            END
        FROM bronze.erp_loc_a101;

        SET @RowsInserted = @@ROWCOUNT;
        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @TableStartTime, SYSDATETIME()
        );

        PRINT 'erp_loc_a101: ' + CAST(@RowsInserted AS VARCHAR(20))
            + ' rows inserted in ' + CAST(@DurationMs AS VARCHAR(20))
            + ' ms.';


        -- =============================================
        -- 6. ERP PRODUCT CATEGORY INFORMATION
        -- =============================================

        SET @TableStartTime = SYSDATETIME();

        PRINT 'Loading silver.erp_px_cat_g1v2...';

        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        INSERT INTO silver.erp_px_cat_g1v2
        (
            id, cat, subcat, maintenance
        )
        SELECT
            id, cat, subcat, maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @RowsInserted = @@ROWCOUNT;
        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @TableStartTime, SYSDATETIME()
        );

        PRINT 'erp_px_cat_g1v2: ' + CAST(@RowsInserted AS VARCHAR(20))
            + ' rows inserted in ' + CAST(@DurationMs AS VARCHAR(20))
            + ' ms.';


        -- =============================================
        -- COMMIT AND TOTAL EXECUTION TIME
        -- =============================================

        COMMIT TRANSACTION;

        SET @EndTime = SYSDATETIME();
        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @StartTime, @EndTime
        );

        PRINT '=============================================';
        PRINT 'SILVER LAYER LOAD COMPLETED SUCCESSFULLY';
        PRINT 'Total execution time: '
            + CAST(@DurationMs AS VARCHAR(20)) + ' ms';
        PRINT '=============================================';

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @EndTime = SYSDATETIME();
        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @StartTime, @EndTime
        );

        PRINT '=============================================';
        PRINT 'ERROR: SILVER LAYER LOAD FAILED';
        PRINT 'Error: ' + ERROR_MESSAGE();
        PRINT 'Elapsed time before failure: '
            + CAST(@DurationMs AS VARCHAR(20)) + ' ms';
        PRINT 'Transaction rolled back.';
        PRINT '=============================================';

        THROW;
    END CATCH;
END;
GO

exec silver.load_silver
