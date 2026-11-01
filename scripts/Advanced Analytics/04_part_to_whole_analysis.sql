/*
===============================================================================
 Script: 04_part_to_whole_analysis.sql
 Project: Data Warehouse - Advanced Analytics | Layer: Gold
 Analysis: Part-to-Whole Analysis

 Purpose:
   Calculate total sales by product category and each category's percentage
   contribution to overall sales. NULL categories, if any, remain in the result.
===============================================================================
*/
WITH category_sales AS (
    -- Calculate revenue for each category.
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    CONCAT(
        CAST(
            ROUND(
                100.0 * total_sales
                / NULLIF(SUM(total_sales) OVER (), 0),
                2
            ) AS DECIMAL(10, 2)
        ),
        '%'
    ) AS percentage_of_total_sales
FROM category_sales
ORDER BY total_sales DESC;
GO
