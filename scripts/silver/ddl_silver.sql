
/*
===============================================================================
  Script:      Create Silver Layer Tables
  Description: Creates the CRM and ERP source tables in the Silver schema
               if they do not already exist.
  Database:    DataWarehouse
  Layer:       Silver (Cleansed and Transformed Data)
===============================================================================

  Tables:
      CRM:
          silver.crm_cust_info
          silver.crm_prd_info
          silver.crm_sales_details

      ERP:
          silver.erp_cust_az12
          silver.erp_loc_a101
          silver.erp_px_cat_g1v2

  Notes:
      - Creates tables only if they do not already exist.
      - Preserves existing tables and their data.
      - Stores cleaned and transformed data from source systems.

===============================================================================
*/

USE DataWarehouse;
GO

-- =============================================
-- CRM TABLES
-- =============================================

-- 1. Customer Information
IF OBJECT_ID(N'silver.crm_cust_info', N'U') IS NULL
BEGIN
    CREATE TABLE silver.crm_cust_info
    (
        cst_id              INT,
        cst_key             NVARCHAR(50),
        cst_firstname       NVARCHAR(50),
        cst_lastname        NVARCHAR(50),
        cst_marital_status  NVARCHAR(50),
        cst_gndr            NVARCHAR(50),
        cst_create_date     DATE,
        dwh_create_date   DATETIME2 DEFAULT  GETDATE()
    );
END;
GO

-- 2. Product Information
IF OBJECT_ID(N'silver.crm_prd_info', N'U') IS NULL
BEGIN
    CREATE TABLE silver.crm_prd_info
    (
        prd_id       INT,
        cat_id       NVARCHAR(50),
        prd_key      NVARCHAR(50),
        prd_nm       NVARCHAR(50),
        prd_cost     INT,
        prd_line     NVARCHAR(50),
        prd_start_dt DATE,
        prd_end_dt   DATE,
        dwh_create_date   DATETIME2 DEFAULT  GETDATE()
    );
END;
GO
-- 3. Sales Details
IF OBJECT_ID(N'silver.crm_sales_details', N'U') IS NULL
BEGIN
    CREATE TABLE silver.crm_sales_details
    (
        sls_ord_num  NVARCHAR(50),
        sls_prd_key  NVARCHAR(50),
        sls_cust_id  INT,
        sls_order_dt DATE,
        sls_ship_dt  DATE,
        sls_due_dt   DATE,
        sls_sales    INT,
        sls_quantity INT,
        sls_price    INT,
         dwh_create_date   DATETIME2 DEFAULT  GETDATE()
    );
END;
GO

-- =============================================
-- ERP TABLES
-- =============================================

-- 4. Customer Information
IF OBJECT_ID(N'silver.erp_cust_az12', N'U') IS NULL
BEGIN
    CREATE TABLE silver.erp_cust_az12
    (
        cid   NVARCHAR(50),
        bdate DATE,
        gen   NVARCHAR(50),
         dwh_create_date   DATETIME2 DEFAULT  GETDATE()
    );
END;
GO

-- 5. Location Information
IF OBJECT_ID(N'silver.erp_loc_a101', N'U') IS NULL
BEGIN
    CREATE TABLE silver.erp_loc_a101
    (
        cid   NVARCHAR(50),
        cntry NVARCHAR(50),
         dwh_create_date   DATETIME2 DEFAULT  GETDATE()
    );
END;
GO

-- 6. Product Category Information
IF OBJECT_ID(N'silver.erp_px_cat_g1v2', N'U') IS NULL
BEGIN
    CREATE TABLE silver.erp_px_cat_g1v2
    (
        id          NVARCHAR(50),
        cat         NVARCHAR(50),
        subcat      NVARCHAR(50),
        maintenance NVARCHAR(50),
         dwh_create_date   DATETIME2 DEFAULT  GETDATE()
    );
END;
GO
