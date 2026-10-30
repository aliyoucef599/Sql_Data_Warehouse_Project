
/*
===============================================================================
  Script Name : 02_dimensions_exploration.sql
  Database    : DataWarehouse
  Description : Explore customer and product dimensions.
                - Customer distribution by country and gender
                - Product distribution by category
                - Average product cost by category
                - Revenue by category and customer
                - Quantity sold by country
===============================================================================
*/


/*
===============================================================================
  1. Customer Distribution by Country
  Purpose: Identify the number of customers in each country.
===============================================================================
*/

SELECT
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;
GO


/*
===============================================================================
  2. Customer Distribution by Gender
  Purpose: Analyze the customer base based on gender.
===============================================================================
*/

SELECT
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;
GO


/*
===============================================================================
  3. Product Distribution by Category
  Purpose: Identify the number of products available in each category.
===============================================================================
*/

SELECT
    category,
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;
GO


/*
===============================================================================
  4. Average Product Cost by Category
  Purpose: Compare the average product cost across different categories.
===============================================================================
*/

SELECT
    category,
    AVG(cost) AS average_cost
FROM gold.dim_products
GROUP BY category
ORDER BY average_cost DESC;
GO


/*
===============================================================================
  5. Total Revenue by Category
  Purpose: Identify which product categories generate the highest revenue.
===============================================================================
*/

SELECT
    p.category,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;
GO


/*
===============================================================================
  6. Total Revenue by Customer
  Purpose: Identify the customers who generate the highest revenue.
===============================================================================
*/

SELECT
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
  7. Distribution of Sold Quantity by Country
  Purpose: Analyze the number of items sold in each country.
===============================================================================
*/

SELECT
    c.country,
    SUM(f.quantity) AS total_quantity_sold
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_quantity_sold DESC;
GO
