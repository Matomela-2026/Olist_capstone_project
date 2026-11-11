-- Validate payment fact table grain and totals

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(DISTINCT CONCAT(order_id, '-', payment_sequential))
        AS distinct_payment_records,
    SUM(payment_value) AS total_payment_value,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)
        AS missing_order_ids,
    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END)
        AS missing_payment_values
FROM gold.fact_order_payments;


-- Validate date dimension relationships

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN d.date_key IS NULL
        THEN 1 ELSE 0 END) AS invalid_order_dates
FROM gold.fact_order_payments f
LEFT JOIN gold.dim_date d
    ON f.order_date_key = d.date_key;