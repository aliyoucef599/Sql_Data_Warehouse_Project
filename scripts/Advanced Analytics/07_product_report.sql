/*
===============================================================================
 Script: 07_product_report.sql
 Project: Data Warehouse - Advanced Analytics | Layer: Gold
 Object: gold.report_products
 Report: Product Report

 Purpose:
   Create a product-level report combining product attributes, sales
   performance, customer reach, segmentation, and KPIs.

 Highlights:
   - Product name, category, subcategory, and cost
   - Revenue-based product segment
   - Total orders, sales, and quantity sold
   - Number of unique customers
   - Sales activity lifespan and recency
   - Average selling price, average order revenue, and average monthly revenue

 Segmentation Rules:
   - High-Performers: Total sales > 50,000.
   - Mid-Range: Total sales >= 1,000 and <= 50,000.
   - Low-Performers: Total sales < 1,000.

 Notes:
   - Includes products with sales records only.
   - Lifespan uses DATEDIFF(MONTH), which counts month boundaries.
   - Average monthly revenue divides by lifespan + 1 to include both the first
     and last calendar months in the observed sales period.
===============================================================================
*/
CREATE OR ALTER VIEW gold.report_products
AS
WITH base_query AS (
    -- Combine sales transactions with product attributes.
    SELECT
        f.order_number,
        f.order_date,
        f.sales_amount,
        f.quantity,
        f.customer_key,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
),
product_aggregation AS (
    -- Aggregate sales and customer metrics for each product.
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT customer_key) AS total_customers,
        MAX(order_date) AS last_order_date,
        DATEDIFF(
            MONTH,
            MIN(order_date),
            MAX(order_date)
        ) AS lifespan,
        -- Unweighted average of transaction-level selling prices.
        AVG(
            CAST(sales_amount AS FLOAT)
            / NULLIF(quantity, 0)
        ) AS avg_selling_price
    FROM base_query
    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        cost
),
final_result AS (
    -- Classify products and calculate performance indicators.
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        CASE
            WHEN total_sales > 50000 THEN 'High-Performers'
            WHEN total_sales >= 1000 THEN 'Mid-Range'
            ELSE 'Low-Performers'
        END AS product_segment,
        DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency_in_months,
        lifespan,
        total_orders,
        total_sales,
        total_quantity,
        total_customers,
        last_order_date,
        ROUND(avg_selling_price, 2) AS avg_selling_price,
        -- Average revenue per distinct order.
        ROUND(
            CAST(total_sales AS FLOAT)
            / NULLIF(total_orders, 0),
            2
        ) AS average_order_revenue,
        -- Average monthly revenue over the inclusive calendar-month span.
        ROUND(
            CAST(total_sales AS FLOAT)
            / NULLIF(lifespan + 1, 0),
            2
        ) AS average_monthly_revenue
    FROM product_aggregation
)
SELECT *
FROM final_result;
GO
