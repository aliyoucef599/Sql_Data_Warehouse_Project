/*
===============================================================================
 Script: 03_performance_analysis.sql
 Project: Data Warehouse - Advanced Analytics | Layer: Gold
 Analysis: Product Performance Analysis

 Purpose:
   Compare yearly product revenue with each product's average yearly revenue
   and its previous available year's revenue.

 Notes:
   - LAG compares with the previous available year. If a product has no sales
     in a calendar year, that missing year is skipped.
===============================================================================
*/
WITH yearly_product_sales AS (
    -- Aggregate revenue by product and  year.
    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_key,
        p.product_name,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY
        YEAR(f.order_date),
        p.product_key,
        p.product_name
),
product_performance AS (
    -- Calculate average revenue and previous available year's revenue.
    SELECT
        order_year,
        product_key,
        product_name,
        total_sales,
        AVG(total_sales) OVER (
            PARTITION BY product_key
        ) AS average_yearly_sales,
        LAG(total_sales) OVER (
            PARTITION BY product_key
            ORDER BY order_year
        ) AS previous_available_year_sales
    FROM yearly_product_sales
)
SELECT
    order_year,
    product_key,
    product_name,
    total_sales,
    average_yearly_sales,
    total_sales - average_yearly_sales AS difference_from_average,
    CASE
        WHEN total_sales > average_yearly_sales THEN 'Above Average'
        WHEN total_sales < average_yearly_sales THEN 'Below Average'
        ELSE 'Average'
    END AS average_performance,
    previous_available_year_sales,
    total_sales - previous_available_year_sales AS difference_from_previous_year
FROM product_performance
ORDER BY
    product_name,
    order_year;
GO
