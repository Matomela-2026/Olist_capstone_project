USE olist_dwh;
GO

-- 1. Total rows versus unique customer IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids
FROM silver.customers;

-- 2. Missing customer attributes
SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS missing_unique_id,
    SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS missing_postal_code,
    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS missing_state
FROM silver.customers;

-- 3. Invalid postal codes
SELECT COUNT(*) AS invalid_postal_codes
FROM silver.customers
WHERE LEN(customer_zip_code_prefix) <> 5
   OR customer_zip_code_prefix LIKE '%[^0-9]%';

-- 4. Customers without matching orders
SELECT COUNT(*) AS unmatched_customers
FROM silver.customers c
LEFT JOIN silver.orders o
    ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;
