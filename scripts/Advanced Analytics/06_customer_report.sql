/*
===============================================================================
 Script: 06_customer_report.sql
 Project: Data Warehouse - Advanced Analytics | Layer: Gold
 Object: gold.report_customers
 Report: Customer Report

 Purpose:
   Create a customer-level report combining customer attributes, purchasing
   behavior, segmentation, and KPIs.

 Highlights:
   - Customer name, age, and age group
   - Spending segment (VIP, Regular, New)
   - Total orders, sales, quantity, and unique products purchased
   - Sales-history lifespan and recency
   - Average order value and average monthly spend

 Notes:
   - Includes customers with sales records only.
   - Lifespan uses DATEDIFF(MONTH), which counts month boundaries.
   - Average monthly spend divides by lifespan + 1 to include both the first
     and last calendar months in the observed sales period.
===============================================================================
*/
CREATE OR ALTER VIEW gold.report_customers
AS
WITH base_query AS (
    -- Combine sales transactions with customer attributes.
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        -- Calculate age, adjusting if the birthday has not occurred this year.
        CASE
            WHEN c.birthdate IS NULL THEN NULL
            ELSE DATEDIFF(YEAR, c.birthdate, GETDATE())
                 - CASE
                       WHEN DATEADD(
                           YEAR,
                           DATEDIFF(YEAR, c.birthdate, GETDATE()),
                           c.birthdate
                       ) > GETDATE()
                       THEN 1
                       ELSE 0
                   END
        END AS age
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_customers AS c
        ON f.customer_key = c.customer_key
    WHERE f.order_date IS NOT NULL
),
customer_aggregation AS (
    -- Aggregate transaction-level data to one row per customer.
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order_date,
        DATEDIFF(
            MONTH,
            MIN(order_date),
            MAX(order_date)
        ) AS customer_lifespan_months
    FROM base_query
    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        age
),
final_result AS (
    -- Derive customer segments and performance indicators.
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        CASE
            WHEN age IS NULL THEN 'Unknown'
            WHEN age < 20 THEN 'Under 20'
            WHEN age BETWEEN 20 AND 39 THEN '20-39'
            WHEN age BETWEEN 40 AND 59 THEN '40-59'
            ELSE '60 and Above'
        END AS age_group,
        CASE
            WHEN customer_lifespan_months < 12 THEN 'New'
            WHEN total_sales > 5000 THEN 'VIP'
            ELSE 'Regular'
        END AS customer_segment,
        DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,
        total_orders,
        total_sales,
        total_quantity,
        total_products,
        last_order_date,
        customer_lifespan_months,
        -- Average revenue per distinct order.
        ROUND(
            CAST(total_sales AS FLOAT) / NULLIF(total_orders, 0),
            2
        ) AS average_order_value,
        -- Average monthly spend over the inclusive calendar-month span.
        ROUND(
            CAST(total_sales AS FLOAT)
            / NULLIF(customer_lifespan_months + 1, 0),
            2
        ) AS average_monthly_spend
    FROM customer_aggregation
)
SELECT *
FROM final_result;
GO
