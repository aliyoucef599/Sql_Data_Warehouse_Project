
/*
===============================================================================
  Script Name : Gold Layer - Dimensions and Fact Views
  Database    : DataWarehouse
  Schema      : gold
  Description : Creates the Gold-layer views following a star schema.
                1. gold.dim_customers
                2. gold.dim_products
                3. gold.fact_sales
===============================================================================
*/


/*
===============================================================================
  Step 1: Drop Existing Views
  Purpose: Drop views if they already exist before recreating them.
           Drop the fact view first because it depends on the dimensions.
===============================================================================
*/

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO


/*
===============================================================================
  Step 2: Create Customer Dimension
  View: gold.dim_customers

  Purpose:
      Combines CRM customer information with ERP customer and location data.

  Transformations:
      - Generates a surrogate key using ROW_NUMBER().
      - Uses CRM as the primary source for gender.
      - Falls back to ERP gender when CRM gender is 'n/a'.
===============================================================================
*/

CREATE VIEW gold.dim_customers
AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY ci.cst_id
    ) AS customer_key,                    -- Surrogate key

    ci.cst_id AS customer_id,             -- Source customer ID
    ci.cst_key AS customer_number,        -- Customer business key
    ci.cst_firstname AS first_name,       -- Customer first name
    ci.cst_lastname AS last_name,         -- Customer last name
    la.cntry AS country,                  -- Customer country
    ci.cst_marital_status AS marital_status, -- Marital status

    CASE
        WHEN ci.cst_gndr <> 'n/a'
            THEN ci.cst_gndr              -- CRM is the master for gender
        ELSE COALESCE(ca.gen, 'n/a')      -- Use ERP gender as fallback
    END AS gender,

    ca.bdate AS birthdate,                -- Customer birthdate
    ci.cst_create_date AS create_date     -- Customer creation date

FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
    ON ci.cst_key = la.cid;
GO


/*
===============================================================================
  Step 3: Create Product Dimension
  View: gold.dim_products

  Purpose:
      Combines CRM product information with ERP category information.

  Transformations:
      - Generates a surrogate key using ROW_NUMBER().
      - Includes category, subcategory, and maintenance information.
      - Keeps only current product versions (prd_end_dt IS NULL).
===============================================================================
*/

CREATE VIEW gold.dim_products
AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY pr.prd_start_dt, pr.prd_nm
    ) AS product_key,                     -- Surrogate key

    pr.prd_id AS product_id,              -- Source product ID
    pr.prd_key AS product_number,         -- Product business key
    pr.prd_nm AS product_name,            -- Product name
    pr.cat_id AS category_id,             -- Category ID
    px.cat AS category,                   -- Category name
    px.subcat AS subcategory,             -- Subcategory name
    pr.prd_line AS product_line,           -- Product line
    px.maintenance AS maintenance,        -- Maintenance classification
    pr.prd_cost AS cost,                  -- Product cost
    pr.prd_start_dt AS start_date         -- Product start date

FROM silver.crm_prd_info AS pr
LEFT JOIN silver.erp_px_cat_g1v2 AS px
    ON pr.cat_id = px.id
WHERE pr.prd_end_dt IS NULL;              -- Current products only
GO


/*
===============================================================================
  Step 4: Create Sales Fact
  View: gold.fact_sales

  Purpose:
      Combines sales transaction data with product and customer surrogate keys.

  Transformations:
      - Renames source columns to business-friendly names.
      - Retrieves product_key from gold.dim_products.
      - Retrieves customer_key from gold.dim_customers.
      - Uses LEFT JOINs to retain sales records without dimension matches.
===============================================================================
*/

CREATE VIEW gold.fact_sales
AS
SELECT
    sd.sls_ord_num AS order_number,       -- Sales order number
    pr.product_key,                       -- FK to product dimension
    cu.customer_key,                      -- FK to customer dimension
    sd.sls_order_dt AS order_date,         -- Order date
    sd.sls_ship_dt AS shipping_date,       -- Shipping date
    sd.sls_due_dt AS due_date,             -- Due date
    sd.sls_sales AS sales_amount,          -- Sales amount
    sd.sls_quantity AS quantity,           -- Quantity sold
    sd.sls_price AS price                  -- Sales price

FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;
GO
