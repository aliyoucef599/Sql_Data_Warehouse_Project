/*
===============================================================================
 Script: 01_change_over_time.sql
 Project: Data Warehouse - Advanced Analytics | Layer: Gold
 Analysis: Change Over Time

 Purpose:
   Analyze yearly sales performance using total sales, unique customers,
   and quantity sold. Records without an order date are excluded.
===============================================================================
*/
SELECT
    YEAR(order_date) AS order_year,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY order_year;
GO


