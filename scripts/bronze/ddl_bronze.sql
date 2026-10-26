

/*
===============================================================================
  Script:      Create Bronze Layer Tables
  Description: Creates the CRM and ERP source tables in the Bronze schema
               if they do not already exist.
  Database:    DataWarehouse
  Layer:       Bronze (Raw Data)
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

  Notes:
      - Creates tables only if they do not already exist.
      - Preserves existing tables and their data.
      - Stores raw data from source systems without transformation.

===============================================================================
*/

USE DataWarehouse;
GO

-- =============================================
-- CRM TABLES
-- =============================================

-- 1. Customer Information
IF OBJECT_ID(N'bronze.crm_cust_info', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.crm_cust_info
    (
        cst_id              INT,
        cst_key             NVARCHAR(50),
        cst_firstname       NVARCHAR(50),
        cst_lastname        NVARCHAR(50),
        cst_marital_status  NVARCHAR(50),
        cst_gndr            NVARCHAR(50),
        cst_create_date     DATE
    );
END;
GO

-- 2. Product Information
IF OBJECT_ID(N'bronze.crm_prd_info', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.crm_prd_info
    (
        prd_id       INT,
        prd_key      NVARCHAR(50),
        prd_nm       NVARCHAR(50),
        prd_cost     INT,
        prd_line     NVARCHAR(50),
        prd_start_dt DATETIME,
        prd_end_dt   DATETIME
    );
END;
GO

-- 3. Sales Details
IF OBJECT_ID(N'bronze.crm_sales_details', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.crm_sales_details
    (
        sls_ord_num  NVARCHAR(50),
        sls_prd_key  NVARCHAR(50),
        sls_cust_id  INT,
        sls_order_dt INT,
        sls_ship_dt  INT,
        sls_due_dt   INT,
        sls_sales    INT,
        sls_quantity INT,
        sls_price    INT
    );
END;
GO

-- =============================================
-- ERP TABLES
-- =============================================

-- 4. Customer Information
IF OBJECT_ID(N'bronze.erp_cust_az12', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.erp_cust_az12
    (
        cid   NVARCHAR(50),
        bdate DATE,
        gen   NVARCHAR(50)
    );
END;
GO

-- 5. Location Information
IF OBJECT_ID(N'bronze.erp_loc_a101', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.erp_loc_a101
    (
        cid   NVARCHAR(50),
        cntry NVARCHAR(50)
    );
END;
GO

-- 6. Product Category Information
IF OBJECT_ID(N'bronze.erp_px_cat_g1v2', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.erp_px_cat_g1v2
    (
        id          NVARCHAR(50),
        cat         NVARCHAR(50),
        subcat      NVARCHAR(50),
        maintenance NVARCHAR(50)
    );
END;
GO
