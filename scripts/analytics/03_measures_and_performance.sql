
/*
===============================================================================
  Script Name : 03_measures_and_performance.sql
  Database    : DataWarehouse
  Description : Analyze key business measures and sales performance.
                - Calculate overall business KPIs
                - Identify top and bottom performing products
                - Rank products by revenue
                - Identify top customers by revenue
                - Identify customers with the fewest orders
===============================================================================
*/


/*
===============================================================================
  1. Calculate Overall Business Metrics
  Purpose: Calculate key business indicators in a single result set.
===============================================================================
*/

SELECT
    'Total Sales' AS measure_name,
    CAST(SUM(sales_amount) AS DECIMAL(18,2)) AS measure_values
FROM gold.fact_sales

UNION ALL

SELECT
    'Total Quantity Sold',
    CAST(SUM(quantity) AS DECIMAL(18,2))
FROM gold.fact_sales

UNION ALL

SELECT
    'Average Selling Price',
    CAST(AVG(price) AS DECIMAL(18,2))
FROM gold.fact_sales

UNION ALL

SELECT
    'Total Number of Orders',
    CAST(COUNT(DISTINCT order_number) AS DECIMAL(18,2))
FROM gold.fact_sales

UNION ALL

SELECT
    'Total Number of Products',
    CAST(COUNT(DISTINCT product_id) AS DECIMAL(18,2))
FROM gold.dim_products

UNION ALL

SELECT
    'Total Number of Customers',
    CAST(COUNT(customer_key) AS DECIMAL(18,2))
FROM gold.dim_customers

UNION ALL

SELECT
    'Customers Who Placed an Order',
    CAST(COUNT(DISTINCT customer_key) AS DECIMAL(18,2))
FROM gold.fact_sales;
GO


/*
===============================================================================
  2. Top 5 Products by Revenue
  Purpose: Identify the five products generating the highest revenue.
===============================================================================
*/

SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;
GO


/*
===============================================================================
  3. Bottom 5 Products by Revenue
  Purpose: Identify the five products generating the lowest revenue
           among products with sales records.
===============================================================================
*/

SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC;
GO


/*
===============================================================================
  4. Rank Products by Revenue
  Purpose: Rank products according to their total revenue and display
           the top five products.
===============================================================================
*/

SELECT
    product_name,
    total_revenue,
    rank_products
FROM (
    SELECT
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        ROW_NUMBER() OVER (
            ORDER BY SUM(f.sales_amount) DESC
        ) AS rank_products
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    GROUP BY p.product_name
) AS ranked_products
WHERE rank_products <= 5
ORDER BY rank_products;
GO


/*
===============================================================================
  5. Top 10 Customers by Revenue
  Purpose: Identify the ten customers generating the highest total revenue.
===============================================================================
*/

SELECT TOP 10
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_revenue DESC;
GO


/*
===============================================================================
  6. Three Customers with the Fewest Orders
  Purpose: Identify the three customers who have placed the fewest orders.
           Only customers with at least one order are included.
===============================================================================
*/

SELECT TOP 3
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    total_orders ASC,
    c.customer_id;
GO
