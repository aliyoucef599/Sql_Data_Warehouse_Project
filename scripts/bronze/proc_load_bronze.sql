
/*
===============================================================================
  Stored Procedure: bronze.load_bronze
  Description:      Loads raw CRM and ERP data into the Bronze layer.
  Database:         DataWarehouse
===============================================================================

  Actions:
      1. Truncate existing data from all six Bronze tables.
      2. Load fresh data from CSV source files.
      3. Commit all changes if loading succeeds.
      4. Roll back all changes if any loading operation fails.

  Error Handling:
      TRY...CATCH with transaction rollback and error propagation.

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
    DECLARE @start_time DATETIME,@end_time DATETIME,@batch_start_time DATETIME,@batch_end_time DATETIME;
     
    BEGIN TRY
        BEGIN TRANSACTION;

        PRINT '=============================================';
        PRINT 'Loading Bronze Layer';
        PRINT '=============================================';

        -- =============================================
        -- Load CRM Tables
        -- =============================================
        set @batch_start_time = GETDATE();
        -- 1. Customer Information
        set @start_time = GETDATE();
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
        set @end_time = GETDATE();

        PRINT 'Loaded bronze.crm_cust_info successfully taking.' +cast (datediff(second,@start_time,@end_time) as nvarchar) + ' seconds';

        -- 2. Product Information
        set @start_time = GETDATE();

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
        set @end_time = GETDATE();
        PRINT 'Loaded bronze.crm_prd_info successfully taking.' +cast (datediff(second,@start_time,@end_time) as nvarchar) + ' seconds';;

        -- 3. Sales Details
        set @start_time = GETDATE();
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
        set @end_time = GETDATE();
        PRINT 'Loaded bronze.crm_sales_details successfully taking.' +cast (datediff(second,@start_time,@end_time) as nvarchar) + ' seconds';;

        -- =============================================
        -- Load ERP Tables
        -- =============================================

        -- 4. Customer Information
        set @start_time = GETDATE();
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
        set @end_time = GETDATE();
        PRINT 'Loaded bronze.erp_cust_az12 successfully taking.' +cast (datediff(second,@start_time,@end_time) as nvarchar) + ' seconds';

        -- 5. Location Information
        set @start_time = GETDATE();
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
        set @end_time = GETDATE();
        PRINT 'Loaded bronze.erp_loc_a101 successfully taking.' +cast (datediff(second,@start_time,@end_time) as nvarchar) + ' seconds';

        -- 6. Product Category Information
        set @start_time = GETDATE();
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
        set @end_time = GETDATE();
        PRINT 'Loaded bronze.erp_px_cat_g1v2 successfully taking.' +cast (datediff(second,@start_time,@end_time) as nvarchar) + ' seconds';

        -- =============================================
        -- Commit Transaction
        -- =============================================

        COMMIT TRANSACTION;
        set @batch_end_time = GETDATE();


        PRINT '=============================================';
        PRINT 'Bronze Layer loaded successfully taking.' +cast (datediff(second,@batch_start_time,@batch_end_time) as nvarchar) + ' seconds';
        PRINT 'Transaction committed.';
        PRINT '=============================================';

    END TRY
    BEGIN CATCH

        -- Roll back changes if a transaction is active
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        PRINT '=============================================';
        PRINT 'ERROR: Bronze Layer loading failed.';
        PRINT ERROR_MESSAGE();
        PRINT 'All transactional changes were rolled back.';
        PRINT '=============================================';

        -- Return the original SQL Server error
        THROW;

    END CATCH;
END;
GO



