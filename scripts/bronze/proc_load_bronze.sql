
/*
===============================================================================
  Stored Procedure: bronze.load_bronze
  Description:      Loads raw CRM and ERP data from CSV files into the Bronze
                    layer.
  Database:         DataWarehouse
  Layer:            Bronze (Raw Data)
===============================================================================

  Tables:
      CRM:
          bronze.crm_cust_info
          bronze.crm_prd_info
          bronze.crm_sales_details

      ERP:
          bronze.erp_cust_az12
          bronze.erp_loc_a101
          bronze.erp_px_cat_g1v2

  Operations:
      1. Truncate existing data from each Bronze table.
      2. Bulk load fresh data from CSV source files.
      3. Measure each table's loading duration.
      4. Measure total batch execution time.
      5. Roll back the transaction if an error occurs.

  WARNING:
      All existing data in the six target tables will be replaced.

===============================================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StartTime      DATETIME2(7);
    DECLARE @EndTime        DATETIME2(7);
    DECLARE @BatchStartTime DATETIME2(7) = SYSDATETIME();
    DECLARE @BatchEndTime   DATETIME2(7);
    DECLARE @DurationMs     BIGINT;

    BEGIN TRY
        BEGIN TRANSACTION;

        PRINT '=============================================';
        PRINT '       STARTING BRONZE LAYER LOAD';
        PRINT '=============================================';


        -- =============================================
        -- 1. CRM CUSTOMER INFORMATION
        -- =============================================

        SET @StartTime = SYSDATETIME();

        PRINT 'Loading bronze.crm_cust_info...';

        TRUNCATE TABLE bronze.crm_cust_info;

        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\11\Desktop\warehouse\source_crm\cust_info.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @EndTime = SYSDATETIME();

        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @StartTime, @EndTime
        );

        PRINT 'Table bronze.crm_cust_info loaded successfully in '
            + CAST(@DurationMs AS VARCHAR(20)) + ' ms.';


        -- =============================================
        -- 2. CRM PRODUCT INFORMATION
        -- =============================================

        SET @StartTime = SYSDATETIME();

        PRINT 'Loading bronze.crm_prd_info...';

        TRUNCATE TABLE bronze.crm_prd_info;

        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\11\Desktop\warehouse\source_crm\prd_info.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @EndTime = SYSDATETIME();

        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @StartTime, @EndTime
        );

        PRINT 'Table bronze.crm_prd_info loaded successfully in '
            + CAST(@DurationMs AS VARCHAR(20)) + ' ms.';


        -- =============================================
        -- 3. CRM SALES DETAILS
        -- =============================================

        SET @StartTime = SYSDATETIME();

        PRINT 'Loading bronze.crm_sales_details...';

        TRUNCATE TABLE bronze.crm_sales_details;

        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\11\Desktop\warehouse\source_crm\sales_details.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @EndTime = SYSDATETIME();

        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @StartTime, @EndTime
        );

        PRINT 'Table bronze.crm_sales_details loaded successfully in '
            + CAST(@DurationMs AS VARCHAR(20)) + ' ms.';


        -- =============================================
        -- 4. ERP CUSTOMER INFORMATION
        -- =============================================

        SET @StartTime = SYSDATETIME();

        PRINT 'Loading bronze.erp_cust_az12...';

        TRUNCATE TABLE bronze.erp_cust_az12;

        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\11\Desktop\warehouse\source_erp\CUST_AZ12.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @EndTime = SYSDATETIME();

        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @StartTime, @EndTime
        );

        PRINT 'Table bronze.erp_cust_az12 loaded successfully in '
            + CAST(@DurationMs AS VARCHAR(20)) + ' ms.';


        -- =============================================
        -- 5. ERP LOCATION INFORMATION
        -- =============================================

        SET @StartTime = SYSDATETIME();

        PRINT 'Loading bronze.erp_loc_a101...';

        TRUNCATE TABLE bronze.erp_loc_a101;

        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\11\Desktop\warehouse\source_erp\LOC_A101.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @EndTime = SYSDATETIME();

        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @StartTime, @EndTime
        );

        PRINT 'Table bronze.erp_loc_a101 loaded successfully in '
            + CAST(@DurationMs AS VARCHAR(20)) + ' ms.';


        -- =============================================
        -- 6. ERP PRODUCT CATEGORY INFORMATION
        -- =============================================

        SET @StartTime = SYSDATETIME();

        PRINT 'Loading bronze.erp_px_cat_g1v2...';

        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\11\Desktop\warehouse\source_erp\PX_CAT_G1V2.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @EndTime = SYSDATETIME();

        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @StartTime, @EndTime
        );

        PRINT 'Table bronze.erp_px_cat_g1v2 loaded successfully in '
            + CAST(@DurationMs AS VARCHAR(20)) + ' ms.';


        -- =============================================
        -- COMMIT TRANSACTION AND REPORT TOTAL TIME
        -- =============================================

        COMMIT TRANSACTION;

        SET @BatchEndTime = SYSDATETIME();

        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @BatchStartTime, @BatchEndTime
        );

        PRINT '=============================================';
        PRINT 'BRONZE LAYER LOADED SUCCESSFULLY';
        PRINT 'Total execution time: '
            + CAST(@DurationMs AS VARCHAR(20)) + ' ms';
        PRINT 'Transaction committed.';
        PRINT '=============================================';

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @BatchEndTime = SYSDATETIME();

        SET @DurationMs = DATEDIFF_BIG(
            MILLISECOND, @BatchStartTime, @BatchEndTime
        );

        PRINT '=============================================';
        PRINT 'ERROR: BRONZE LAYER LOAD FAILED';
        PRINT 'Error: ' + ERROR_MESSAGE();
        PRINT 'Elapsed time before failure: '
            + CAST(@DurationMs AS VARCHAR(20)) + ' ms';
        PRINT 'Transaction rolled back.';
        PRINT '=============================================';

        THROW;

    END CATCH;
END;
GO

