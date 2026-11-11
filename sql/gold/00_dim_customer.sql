
-- =====================================================
-- Project: Olist SSIS Medallion Data Warehouse
-- Layer: Gold
-- Script: 00_dim_customer.sql
-- Purpose: Create and populate customer dimension
-- Method: Slowly Changing Dimension Type 2 (SCD Type 2)
-- Grain: One row per customer address version
-- =====================================================

-- Create customer dimension if it does not exist

IF OBJECT_ID(N'gold.dim_customer', N'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_customer
    (
        customer_key INT IDENTITY(1,1) NOT NULL,
        customer_unique_id NVARCHAR(50) NOT NULL,
        customer_zip_code_prefix CHAR(5) NOT NULL,
        customer_city NVARCHAR(100) NOT NULL,
        customer_state CHAR(2) NOT NULL,
        effective_from DATETIME2 NOT NULL,
        effective_to DATETIME2 NOT NULL,
        is_current BIT NOT NULL,

        CONSTRAINT PK_gold_dim_customer
            PRIMARY KEY (customer_key)
    );
END;

-- Load customer history only when the dimension is empty

IF NOT EXISTS
(
    SELECT 1
    FROM gold.dim_customer
)
BEGIN

    -- Step 1: Identify distinct customer address profiles
    -- and the first observed purchase date for each profile.

    ;WITH customer_profiles AS
    (
        SELECT
            c.customer_unique_id,
            c.customer_zip_code_prefix,
            c.customer_city,
            c.customer_state,
            MIN(o.order_purchase_timestamp) AS effective_from

        FROM silver.customers c

        INNER JOIN silver.orders o
            ON c.customer_id = o.customer_id

        GROUP BY
            c.customer_unique_id,
            c.customer_zip_code_prefix,
            c.customer_city,
            c.customer_state
    ),

    -- Step 2: Identify the next address version
    -- for each customer.

    customer_versions AS
    (
        SELECT
            customer_unique_id,
            customer_zip_code_prefix,
            customer_city,
            customer_state,
            effective_from,

            LEAD(effective_from) OVER
            (
                PARTITION BY customer_unique_id
                ORDER BY effective_from
            ) AS next_effective_from

        FROM customer_profiles
    )

    -- Step 3: Insert customer versions into Gold.

    INSERT INTO gold.dim_customer
    (
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        effective_from,
        effective_to,
        is_current
    )
    SELECT
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        effective_from,

        COALESCE
        (
            next_effective_from,
            CAST('9999-12-31 23:59:59.9999999' AS DATETIME2)
        ) AS effective_to,

        CASE
            WHEN next_effective_from IS NULL THEN 1
            ELSE 0
        END AS is_current

    FROM customer_versions;

END;
