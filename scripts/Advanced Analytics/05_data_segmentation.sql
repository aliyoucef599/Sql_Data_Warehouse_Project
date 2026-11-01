/*
===============================================================================
 Script: 05_data_segmentation.sql
 Project: Data Warehouse - Advanced Analytics | Layer: Gold
 Analysis: Data Segmentation

 Purpose:
   1. Segment products by cost and count products in each range.
   2. Segment customers by total spending and sales-history lifespan.

 Notes:
   - Customer segmentation includes customers with sales records only.
   - DATEDIFF(MONTH, ...) counts month boundaries, not complete elapsed months.
===============================================================================
*/


/*
===============================================================================
 1. Product Segmentation by Cost

 Ranges:
   - Below 100
   - 100 to below 500
   - 500 to 1,000
   - Above 1,000

 The conditions are mutually exclusive, including for decimal cost values.
===============================================================================
*/
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        category,
        cost,
        CASE
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost < 500 THEN '100 to below 500'
            WHEN cost <= 1000 THEN '500 to 1,000'
            ELSE 'Above 1,000'
        END AS cost_range
    FROM gold.dim_products
    WHERE cost IS NOT NULL
)
SELECT
    cost_range,
    COUNT(*) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;
GO


/*
===============================================================================
 2. Customer Segmentation by Spending Behavior

 Rules:
   - VIP: At least 12 months of history and total sales > 5,000.
   - Regular: At least 12 months of history and total sales <= 5,000.
   - New: Sales-history lifespan of less than 12 months.

 Only customers with at least one sales record are included.
===============================================================================
*/
WITH customer_gap AS (
    -- Aggregate sales and calculate each customer's sales-history lifespan.
    SELECT
        f.customer_key,
        SUM(f.sales_amount) AS total_sales,
        DATEDIFF(
            MONTH,
            MIN(f.order_date),
            MAX(f.order_date)
        ) AS customer_lifespan_months
    FROM gold.fact_sales AS f
    WHERE f.customer_key IS NOT NULL
      AND f.order_date IS NOT NULL
    GROUP BY f.customer_key
),
customer_segments AS (
    -- Assign a segment to each customer.
    SELECT
        customer_key,
        total_sales,
        customer_lifespan_months,
        CASE
            WHEN customer_lifespan_months < 12 THEN 'New'
            WHEN total_sales > 5000 THEN 'VIP'
            ELSE 'Regular'
        END AS customer_segment
    FROM customer_gap
)
SELECT
    customer_segment,
    COUNT(*) AS total_customers
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_customers DESC;
GO
