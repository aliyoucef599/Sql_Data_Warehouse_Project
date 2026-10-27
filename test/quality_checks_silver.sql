
/*
===============================================================================
  Script:      Silver Layer Data Quality Tests
  Description: Validates data quality after cleaning and transforming
               CRM and ERP source data into the Silver layer.
  Database:    DataWarehouse
===============================================================================

  Validation Categories:
      1. Primary Key Uniqueness and NULL Checks
      2. Whitespace Checks
      3. NULL and Invalid Value Checks
      4. Data Standardization and Consistency
      5. Date Validation
      6. Referential Integrity
      7. Business Rule Validation

  Expected Results:
      - Issue-detection queries should return no rows when the data
        satisfies the specified rules.
      - DISTINCT queries display the available values for manual review.

  Note:
      These queries validate data; they do not modify any records.

===============================================================================
*/

USE DataWarehouse;
GO


-- ###########################################################################
-- 1. CRM CUSTOMER INFORMATION
-- Table: silver.crm_cust_info
-- ###########################################################################


-- ===========================================================================
-- 1.1 Check Primary Key: NULL Values and Duplicates
-- Expected: No rows returned.
-- ===========================================================================

SELECT
    cst_id,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
    OR cst_id IS NULL;


-- ===========================================================================
-- 1.2 Check Unwanted Whitespace in Customer Names
-- Expected: No rows returned.
-- ===========================================================================

-- Check first names
SELECT
    cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname);


-- Check last names
SELECT
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname <> TRIM(cst_lastname);


-- ===========================================================================
-- 1.3 Check Customer Key Whitespace in Bronze
-- Expected: No rows returned if source keys are already clean.
-- ===========================================================================

SELECT
    cst_key
FROM bronze.crm_cust_info
WHERE cst_key <> TRIM(cst_key);


-- ===========================================================================
-- 1.4 Check Gender and Marital Status Standardization
-- Expected: Only the standardized values should appear.
-- ===========================================================================

-- Gender values
SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info;


-- Marital status values
SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;


-- ###########################################################################
-- 2. CRM PRODUCT INFORMATION
-- Table: silver.crm_prd_info
-- ###########################################################################


-- ===========================================================================
-- 2.1 Check Primary Key: NULL Values and Duplicates
-- Expected: No rows returned.
-- ===========================================================================

SELECT
    prd_id,
    COUNT(*) AS record_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;


-- ===========================================================================
-- 2.2 Check Unwanted Whitespace in Product Names
-- Expected: No rows returned.
-- ===========================================================================

SELECT
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);


-- ===========================================================================
-- 2.3 Check Product Cost for NULL or Negative Values
-- Expected: No rows returned if costs are required to be non-negative.
-- Note: Your transformation replaces NULL costs with zero.
-- ===========================================================================

SELECT
    prd_id,
    prd_nm,
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0
   OR prd_cost IS NULL;


-- ===========================================================================
-- 2.4 Check Product Line Standardization
-- Expected: Only Mountain, Road, Other Sales, Touring, or n/a.
-- ===========================================================================

SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;


-- ===========================================================================
-- 2.5 Check Product Category IDs Against ERP Categories
-- Expected: No rows returned if every category ID has a matching category.
-- ===========================================================================

SELECT
    p.prd_id,
    p.cat_id
FROM silver.crm_prd_info AS p
WHERE p.cat_id IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM silver.erp_px_cat_g1v2 AS c
      WHERE c.id = p.cat_id
  );


-- ###########################################################################
-- 3. CRM SALES DETAILS
-- Table: silver.crm_sales_details
-- ###########################################################################


-- ===========================================================================
-- 3.1 Check Whitespace in Order Numbers
-- Expected: No rows returned.
-- ===========================================================================

SELECT
    sls_ord_num
FROM silver.crm_sales_details
WHERE sls_ord_num <> TRIM(sls_ord_num);


-- ===========================================================================
-- 3.2 Check Product Referential Integrity
-- Every sales product key should exist in the Silver product table.
-- Expected: No rows returned.
-- ===========================================================================

SELECT
    s.sls_ord_num,
    s.sls_prd_key
FROM silver.crm_sales_details AS s
WHERE s.sls_prd_key IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM silver.crm_prd_info AS p
      WHERE p.prd_key = s.sls_prd_key
  );


-- ===========================================================================
-- 3.3 Check Customer Referential Integrity
-- Every sales customer ID should exist in the customer table.
-- Expected: No rows returned.
-- ===========================================================================

SELECT
    s.sls_ord_num,
    s.sls_cust_id
FROM silver.crm_sales_details AS s
WHERE s.sls_cust_id IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM silver.crm_cust_info AS c
      WHERE c.cst_id = s.sls_cust_id
  );


-- ===========================================================================
-- 3.4 Check Missing or Invalid Order Dates
-- Expected: No rows returned if invalid dates were converted to NULL
-- and order dates are mandatory.
-- ===========================================================================

SELECT
    sls_ord_num,
    sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt IS NULL;


-- ===========================================================================
-- 3.5 Check Missing or Invalid Shipping Dates
-- Expected: No rows returned if shipping dates are mandatory.
-- ===========================================================================

SELECT
    sls_ord_num,
    sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt IS NULL;


-- ===========================================================================
-- 3.6 Check Missing or Invalid Due Dates
-- Expected: No rows returned if due dates are mandatory.
-- ===========================================================================

SELECT
    sls_ord_num,
    sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt IS NULL;


-- ===========================================================================
-- 3.7 Check Chronological Order of Sales Dates
-- Order date must not be later than shipping or due date.
-- Expected: No rows returned.
-- ===========================================================================

SELECT
    sls_ord_num,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt
FROM silver.crm_sales_details
WHERE (sls_ship_dt IS NOT NULL
       AND sls_order_dt > sls_ship_dt)
   OR (sls_due_dt IS NOT NULL
       AND sls_order_dt > sls_due_dt);


-- ===========================================================================
-- 3.8 Check Sales, Quantity, and Price Consistency
-- Expected: No rows returned if all values are valid and consistent.
-- Business rule: Sales = Quantity * Price.
-- ===========================================================================

SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
   OR CAST(sls_sales AS BIGINT)
      <> CAST(sls_quantity AS BIGINT) * sls_price
ORDER BY
    sls_sales,
    sls_quantity,
    sls_price;


-- ###########################################################################
-- 4. ERP CUSTOMER INFORMATION
-- Table: silver.erp_cust_az12
-- ###########################################################################


-- ===========================================================================
-- 4.1 Check Customer ID for NULL Values
-- Expected: No rows returned if customer IDs are mandatory.
-- ===========================================================================

SELECT
    cid
FROM silver.erp_cust_az12
WHERE cid IS NULL
   OR TRIM(cid) = '';


-- ===========================================================================
-- 4.2 Check Birth Dates Against Business Rules
-- Expected: No rows returned for dates outside the accepted range.
-- Business rule: Birth dates must be between 1924-01-01 and today.
-- Adjust the minimum date if your project uses a different rule.
-- ===========================================================================

SELECT
    cid,
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
   OR bdate > CAST(GETDATE() AS DATE);


-- ===========================================================================
-- 4.3 Check Gender Standardization
-- Expected: Only Female, Male, or n/a.
-- ===========================================================================

SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;


-- ###########################################################################
-- 5. ERP LOCATION INFORMATION
-- Table: silver.erp_loc_a101
-- ###########################################################################


-- ===========================================================================
-- 5.1 Check Customer ID for NULL or Empty Values
-- Expected: No rows returned if customer IDs are mandatory.
-- ===========================================================================

SELECT
    cid
FROM silver.erp_loc_a101
WHERE cid IS NULL
   OR TRIM(cid) = '';


-- ===========================================================================
-- 5.2 Check Unwanted Whitespace in Country Names
-- Expected: No rows returned.
-- ===========================================================================

SELECT
    cntry
FROM silver.erp_loc_a101
WHERE cntry <> TRIM(cntry);


-- ===========================================================================
-- 5.3 Check Country Standardization
-- Expected: Review the distinct country names and codes.
-- ===========================================================================

SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;


-- ###########################################################################
-- 6. ERP PRODUCT CATEGORY INFORMATION
-- Table: silver.erp_px_cat_g1v2
-- ###########################################################################


-- ===========================================================================
-- 6.1 Check Unwanted Whitespace in Category Attributes
-- Expected: No rows returned.
-- ===========================================================================

SELECT
    id,
    cat,
    subcat,
    maintenance
FROM silver.erp_px_cat_g1v2
WHERE cat <> TRIM(cat)
   OR subcat <> TRIM(subcat)
   OR maintenance <> TRIM(maintenance);


-- ===========================================================================
-- 6.2 Check Product Category Standardization
-- Expected: Review the distinct category combinations.
-- ===========================================================================

SELECT DISTINCT
    cat,
    subcat,
    maintenance
FROM silver.erp_px_cat_g1v2
ORDER BY
    cat,
    subcat,
    maintenance;


-- ===========================================================================
-- END OF SILVER LAYER DATA QUALITY TESTS
-- ===========================================================================
