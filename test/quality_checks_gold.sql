
/*
===============================================================================
  Script Name : quality_checks_gold.sql
  Database    : DataWarehouse
  Schema      : gold
  Description : Data quality checks for the Gold layer.
                - Customer dimension duplicate checks
                - Customer gender integration validation
                - Product dimension duplicate checks
                - Fact-to-dimension key integrity checks
===============================================================================
*/


/*
===============================================================================
  1. Customer Dimension - Check for Duplicate Customer Records
  Purpose:
      Verify that joining CRM customers with ERP customer and location data
      does not produce multiple rows for the same customer ID.

  Expected Result:
      No rows should be returned.
===============================================================================
*/

SELECT
    cst_id,
    COUNT(*) AS record_count
FROM (
    SELECT
        ci.cst_id,
        ci.cst_key,
        ci.cst_firstname,
        ci.cst_lastname,
        ci.cst_marital_status,
        ci.cst_gndr,
        ci.cst_create_date,
        ca.bdate,
        ca.gen,
        la.cntry
    FROM silver.crm_cust_info AS ci
    LEFT JOIN silver.erp_cust_az12 AS ca
        ON ci.cst_key = ca.cid
    LEFT JOIN silver.erp_loc_a101 AS la
        ON ci.cst_key = la.cid
) AS t
GROUP BY cst_id
HAVING COUNT(*) > 1;
GO


/*
===============================================================================
  2. Customer Dimension - Validate Gender Integration
  Purpose:
      Review how CRM and ERP gender values are combined.

  Rule:
      - Prefer CRM gender when it is not 'n/a'.
      - Otherwise, use ERP gender.
      - If both are unavailable, return 'n/a'.

  Expected Result:
      Review the distinct combinations and confirm that the resulting
      gender values follow the documented business rules.
===============================================================================
*/

SELECT DISTINCT
    ci.cst_gndr AS crm_gender,
    ca.gen AS erp_gender,
    CASE
        WHEN ci.cst_gndr <> 'n/a'
            THEN ci.cst_gndr                 -- CRM is the master for gender
        ELSE COALESCE(ca.gen, 'n/a')         -- ERP fallback
    END AS integrated_gender
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
    ON ci.cst_key = la.cid;
GO


/*
===============================================================================
  3. Product Dimension - Check for Duplicate Current Products
  Purpose:
      Verify that each current product number appears only once after joining
      CRM product data with ERP category data.

  Expected Result:
      No rows should be returned.
===============================================================================
*/

SELECT
    prd_key AS product_number,
    COUNT(*) AS record_count
FROM (
    SELECT
        pr.prd_id,
        pr.cat_id,
        pr.prd_key,
        pr.prd_nm,
        pr.prd_cost,
        pr.prd_line,
        pr.prd_start_dt,
        pr.prd_end_dt,
        px.cat,
        px.subcat,
        px.maintenance
    FROM silver.crm_prd_info AS pr
    LEFT JOIN silver.erp_px_cat_g1v2 AS px
        ON pr.cat_id = px.id
    WHERE pr.prd_end_dt IS NULL             -- Current products only
) AS t
GROUP BY prd_key
HAVING COUNT(*) > 1;
GO


/*
===============================================================================
  4. Sales Fact - Validate Customer Key Integrity
  Purpose:
      Identify sales records whose customer_key does not match a record
      in gold.dim_customers.

  Expected Result:
      No rows should be returned.
===============================================================================
*/

SELECT
    f.*
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON c.customer_key = f.customer_key
WHERE c.customer_key IS NULL;
GO


/*
===============================================================================
  5. Sales Fact - Validate Product Key Integrity
  Purpose:
      Identify sales records whose product_key does not match a record
      in gold.dim_products.

  Expected Result:
      No rows should be returned.
===============================================================================
*/

SELECT
    f.*
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON p.product_key = f.product_key
WHERE p.product_key IS NULL;
GO
