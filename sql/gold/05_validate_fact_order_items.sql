SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN dc.customer_key IS NULL
        THEN 1 ELSE 0 END) AS invalid_customer_keys,

    SUM(CASE WHEN dp.product_key IS NULL
        THEN 1 ELSE 0 END) AS invalid_product_keys,

    SUM(CASE WHEN ds.seller_key IS NULL
        THEN 1 ELSE 0 END) AS invalid_seller_keys,

    SUM(CASE WHEN od.date_key IS NULL
        THEN 1 ELSE 0 END) AS invalid_order_dates,

    SUM(CASE WHEN sd.date_key IS NULL
        THEN 1 ELSE 0 END) AS invalid_shipping_dates

FROM gold.fact_order_items f
LEFT JOIN gold.dim_customer dc
    ON f.customer_key = dc.customer_key
LEFT JOIN gold.dim_product dp
    ON f.product_key = dp.product_key
LEFT JOIN gold.dim_seller ds
    ON f.seller_key = ds.seller_key
LEFT JOIN gold.dim_date od
    ON f.order_date_key = od.date_key
LEFT JOIN gold.dim_date sd
    ON f.shipping_date_key = sd.date_key;