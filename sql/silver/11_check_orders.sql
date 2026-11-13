USE olist_dwh;
GO

-- 1. Total rows and unique order IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids
FROM silver.orders;

-- 2. Missing critical fields
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_purchase_timestamp,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS missing_order_status
FROM silver.orders;

-- 3. Orders without matching customers
SELECT COUNT(*) AS unmatched_orders
FROM silver.orders o
LEFT JOIN silver.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 4. Duplicate order IDs
SELECT COUNT(*) AS duplicate_order_ids
FROM (
    SELECT order_id
    FROM silver.orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS duplicates;