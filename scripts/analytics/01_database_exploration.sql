
/*
===============================================================================
  Script Name : 01_database_exploration.sql
  Database    : DataWarehouse
  Description : Explore the database structure and general business data.
                - Explore database tables and columns
                - Explore available customer countries
                - Explore product categories
                - Identify the first and last order dates
                - Identify the youngest and oldest customers
===============================================================================
*/


/*
===============================================================================
  1. Explore All Tables in the Database
  Purpose: Retrieve information about all tables and views.
===============================================================================
*/

SELECT *
FROM INFORMATION_SCHEMA.TABLES;
GO


/*
===============================================================================
  2. Explore Columns of a Specific Table
  Purpose: Retrieve column metadata for the customer dimension.
===============================================================================
*/

SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
  AND TABLE_NAME = 'dim_customers';
GO


/*
===============================================================================
  3. Explore All Customer Countries
  Purpose: Identify the distinct countries represented in the customer data.
===============================================================================
*/

SELECT DISTINCT
    country
FROM gold.dim_customers
ORDER BY country;
GO


/*
===============================================================================
  4. Explore Product Categories and Subcategories
  Purpose: Explore the product hierarchy and associated product names.
===============================================================================
*/

SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY
    category,
    subcategory,
    product_name;
GO


/*
===============================================================================
  5. Explore Order Date Range
  Purpose:
      - Identify the first order date.
      - Identify the last order date.
      - Calculate the difference between the two dates in years.
===============================================================================
*/

SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(
        YEAR,
        MIN(order_date),
        MAX(order_date)
    ) AS order_range_years
FROM gold.fact_sales;
GO


/*
===============================================================================
  6. Explore Customer Age Range
  Purpose: Identify the youngest and oldest customers based on birthdates.
===============================================================================
*/

SELECT
    MIN(age) AS youngest_age,
    MAX(age) AS oldest_age
FROM (
    SELECT
        DATEDIFF(YEAR, birthdate, GETDATE())
        - CASE
            WHEN DATEADD(
                YEAR,
                DATEDIFF(YEAR, birthdate, GETDATE()),
                birthdate
            ) > GETDATE()
            THEN 1
            ELSE 0
          END AS age
    FROM gold.dim_customers
    WHERE birthdate IS NOT NULL
) AS customer_ages;
GO
