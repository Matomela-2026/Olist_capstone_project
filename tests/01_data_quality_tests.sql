
USE olist_dwh;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @results TABLE
(
    test_number INT,
    test_name NVARCHAR(150),
    test_status NVARCHAR(10),
    details NVARCHAR(300)
);

DECLARE @bad_count BIGINT;
DECLARE @source_total DECIMAL(38,2);
DECLARE @gold_total DECIMAL(38,2);

-- TEST 1: Bronze row counts match the source CSV counts.
;WITH BronzeCounts AS
(
    SELECT 'customers' AS table_name, 99441 AS expected_rows,
           COUNT_BIG(*) AS actual_rows
    FROM bronze.olist_customers

    UNION ALL
    SELECT 'sellers', 3095, COUNT_BIG(*)
    FROM bronze.olist_sellers

    UNION ALL
    SELECT 'products', 32951, COUNT_BIG(*)
    FROM bronze.olist_products

    UNION ALL
    SELECT 'orders', 99441, COUNT_BIG(*)
    FROM bronze.olist_orders

    UNION ALL
    SELECT 'order_items', 112650, COUNT_BIG(*)
    FROM bronze.olist_order_items

    UNION ALL
    SELECT 'order_payments', 103886, COUNT_BIG(*)
    FROM bronze.olist_order_payments

    UNION ALL
    SELECT 'order_reviews', 99224, COUNT_BIG(*)
    FROM bronze.olist_order_reviews

    UNION ALL
    SELECT 'geolocation', 1000163, COUNT_BIG(*)
    FROM bronze.olist_geolocation

    UNION ALL
    SELECT 'category_translation', 71, COUNT_BIG(*)
    FROM bronze.product_category_name_translation
)
SELECT @bad_count = COUNT_BIG(*)
FROM BronzeCounts
WHERE expected_rows <> actual_rows;

INSERT INTO @results
VALUES
(
    1,
    'Bronze counts match source CSV counts',
    CASE WHEN @bad_count = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(@bad_count, ' Bronze table count mismatches')
);

-- TEST 2: No duplicate review IDs in Silver.
SELECT @bad_count = COUNT_BIG(*)
FROM
(
    SELECT review_id
    FROM silver.order_reviews
    GROUP BY review_id
    HAVING COUNT_BIG(*) > 1
) d;

INSERT INTO @results
VALUES
(
    2,
    'No duplicate Silver review IDs',
    CASE WHEN @bad_count = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(@bad_count, ' duplicate review ID groups')
);

-- TEST 3: One Silver geolocation row per ZIP code.
SELECT @bad_count = COUNT_BIG(*)
FROM
(
    SELECT geolocation_zip_code_prefix
    FROM silver.geolocation
    GROUP BY geolocation_zip_code_prefix
    HAVING COUNT_BIG(*) > 1
) g;

INSERT INTO @results
VALUES
(
    3,
    'One Silver geolocation row per ZIP',
    CASE WHEN @bad_count = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(@bad_count, ' duplicate ZIP groups')
);

-- TEST 4: No NULL business keys in Gold dimensions.
SELECT @bad_count = SUM(null_count)
FROM
(
    SELECT COUNT_BIG(*) AS null_count
    FROM gold.dim_customer
    WHERE customer_unique_id IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.dim_product
    WHERE product_id IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.dim_seller
    WHERE seller_id IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.dim_geography
    WHERE zip_code_prefix IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.dim_order_status
    WHERE order_status IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.dim_payment_type
    WHERE payment_type IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.dim_date
    WHERE full_date IS NULL
) n;

SET @bad_count = COALESCE(@bad_count, 0);

INSERT INTO @results
VALUES
(
    4,
    'No NULL dimension business keys',
    CASE WHEN @bad_count = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(@bad_count, ' NULL dimension business keys')
);

-- TEST 5: Unique surrogate keys across Gold dimensions.
SELECT @bad_count = SUM(duplicate_count)
FROM
(
    SELECT COUNT_BIG(*) AS duplicate_count
    FROM gold.dim_customer
    GROUP BY customer_key
    HAVING COUNT_BIG(*) > 1

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.dim_product
    GROUP BY product_key
    HAVING COUNT_BIG(*) > 1

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.dim_seller
    GROUP BY seller_key
    HAVING COUNT_BIG(*) > 1

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.dim_geography
    GROUP BY geography_key
    HAVING COUNT_BIG(*) > 1

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.dim_date
    GROUP BY date_key
    HAVING COUNT_BIG(*) > 1

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.dim_order_status
    GROUP BY order_status_key
    HAVING COUNT_BIG(*) > 1

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.dim_payment_type
    GROUP BY payment_type_key
    HAVING COUNT_BIG(*) > 1
) d;

SET @bad_count = COALESCE(@bad_count, 0);

INSERT INTO @results
VALUES
(
    5,
    'Unique Gold dimension surrogate keys',
    CASE WHEN @bad_count = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(@bad_count, ' duplicate surrogate key groups')
);

-- TEST 6: No orphan foreign keys in Gold fact tables.
SELECT @bad_count = SUM(orphan_count)
FROM
(
    SELECT COUNT_BIG(*) AS orphan_count
    FROM gold.fact_order_items f
    LEFT JOIN gold.dim_customer d
        ON f.customer_key = d.customer_key
    WHERE d.customer_key IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.fact_order_items f
    LEFT JOIN gold.dim_product d
        ON f.product_key = d.product_key
    WHERE d.product_key IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.fact_order_items f
    LEFT JOIN gold.dim_seller d
        ON f.seller_key = d.seller_key
    WHERE d.seller_key IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.fact_order_items f
    LEFT JOIN gold.dim_date d
        ON f.order_date_key = d.date_key
    WHERE d.date_key IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.fact_order_items f
    LEFT JOIN gold.dim_date d
        ON f.shipping_date_key = d.date_key
    WHERE d.date_key IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.fact_order_items f
    LEFT JOIN gold.dim_geography d
        ON f.customer_geography_key = d.geography_key
    WHERE d.geography_key IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.fact_order_items f
    LEFT JOIN gold.dim_geography d
        ON f.seller_geography_key = d.geography_key
    WHERE d.geography_key IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.fact_order_items f
    LEFT JOIN gold.dim_order_status d
        ON f.order_status_key = d.order_status_key
    WHERE d.order_status_key IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.fact_order_payments f
    LEFT JOIN gold.dim_date d
        ON f.order_date_key = d.date_key
    WHERE d.date_key IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.fact_order_payments f
    LEFT JOIN gold.dim_payment_type d
        ON f.payment_type_key = d.payment_type_key
    WHERE d.payment_type_key IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.fact_order_reviews f
    LEFT JOIN gold.dim_date d
        ON f.review_date_key = d.date_key
    WHERE d.date_key IS NULL

    UNION ALL
    SELECT COUNT_BIG(*)
    FROM gold.fact_order_reviews f
    LEFT JOIN gold.dim_date d
        ON f.review_answer_date_key = d.date_key
    WHERE d.date_key IS NULL
) o;

SET @bad_count = COALESCE(@bad_count, 0);

INSERT INTO @results
VALUES
(
    6,
    'No orphan foreign keys in Gold facts',
    CASE WHEN @bad_count = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(@bad_count, ' orphan fact foreign keys')
);

-- TEST 7: Silver and Gold order-item prices reconcile.
SELECT @source_total = COALESCE(SUM(CAST(price AS DECIMAL(38,2))), 0)
FROM silver.order_items;

SELECT @gold_total = COALESCE(SUM(CAST(price AS DECIMAL(38,2))), 0)
FROM gold.fact_order_items;

INSERT INTO @results
VALUES
(
    7,
    'Order-item price totals reconcile',
    CASE WHEN ABS(@source_total - @gold_total) < 0.01
         THEN 'PASS' ELSE 'FAIL' END,
    CONCAT('Silver: ', @source_total, '; Gold: ', @gold_total)
);

-- TEST 8: Silver and Gold payment totals reconcile.
SELECT @source_total =
       COALESCE(SUM(CAST(payment_value AS DECIMAL(38,2))), 0)
FROM silver.order_payments;

SELECT @gold_total =
       COALESCE(SUM(CAST(payment_value AS DECIMAL(38,2))), 0)
FROM gold.fact_order_payments;

INSERT INTO @results
VALUES
(
    8,
    'Payment value totals reconcile',
    CASE WHEN ABS(@source_total - @gold_total) < 0.01
         THEN 'PASS' ELSE 'FAIL' END,
    CONCAT('Silver: ', @source_total, '; Gold: ', @gold_total)
);

-- TEST 9: Exactly one current SCD Type 2 row per customer.
SELECT @bad_count = COUNT_BIG(*)
FROM
(
    SELECT customer_unique_id
    FROM gold.dim_customer
    GROUP BY customer_unique_id
    HAVING SUM(CASE WHEN is_current = 1 THEN 1 ELSE 0 END) <> 1
) c;

INSERT INTO @results
VALUES
(
    9,
    'One current SCD2 row per customer',
    CASE WHEN @bad_count = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(@bad_count, ' customers without exactly one current row')
);

-- TEST 10: No negative Silver prices or freight values.
SELECT @bad_count = COUNT_BIG(*)
FROM silver.order_items
WHERE price < 0
   OR freight_value < 0;

INSERT INTO @results
VALUES
(
    10,
    'No negative Silver prices or freight',
    CASE WHEN @bad_count = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(@bad_count, ' rows with negative values')
);

-- Display all ten test outcomes.
SELECT
    test_number,
    test_name,
    test_status,
    details
FROM @results
ORDER BY test_number;

-- Fail the suite if any test fails.
IF EXISTS
(
    SELECT 1
    FROM @results
    WHERE test_status = 'FAIL'
)
BEGIN
    THROW 50010, 'One or more data-quality tests failed.', 1;
END;

PRINT 'All 10 data-quality tests passed.';
GO
