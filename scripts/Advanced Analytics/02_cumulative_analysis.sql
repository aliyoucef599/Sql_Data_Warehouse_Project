/*
===============================================================================
 Script: 02_cumulative_analysis.sql
 Project: Data Warehouse - Advanced Analytics | Layer: Gold
 Analysis: Cumulative Analysis

 Purpose:
   Aggregate revenue by month and calculate a year-to-date running total.
   The cumulative total resets at the beginning of each calendar year.
===============================================================================
*/
WITH monthly_sales AS (
    -- Calculate total revenue for each  month.
    SELECT
        DATETRUNC(MONTH, order_date) AS order_month,
        SUM(sales_amount) AS total_revenue
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, order_date)
)
SELECT
    order_month,
    total_revenue,
    SUM(total_revenue) OVER (
        PARTITION BY YEAR(order_month)
        ORDER BY order_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM monthly_sales
ORDER BY order_month;
GO
