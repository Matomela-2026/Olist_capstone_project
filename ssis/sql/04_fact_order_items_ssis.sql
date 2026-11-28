
-- =====================================================
-- Project: Olist SSIS Medallion Data Warehouse
-- Layer: Gold
-- Script: 04_fact_order_items.sql
-- Purpose: Create and load the order-item fact table
-- Grain: One row per order_id + order_item_id
-- =====================================================

-- Create the fact table if it does not already exist
IF OBJECT_ID(N'gold.fact_order_items', N'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_order_items
    (
        order_id NVARCHAR(50) NOT NULL,
        order_item_id INT NOT NULL,

        customer_key INT NOT NULL,
        product_key INT NOT NULL,
        seller_key INT NOT NULL,
        order_date_key INT NOT NULL,
        shipping_date_key INT NOT NULL,

        price DECIMAL(10,2) NOT NULL,
        freight_value DECIMAL(10,2) NOT NULL,
        quantity INT NOT NULL,

        CONSTRAINT PK_gold_fact_order_items
            PRIMARY KEY (order_id, order_item_id),

        CONSTRAINT FK_fact_order_items_customer
            FOREIGN KEY (customer_key)
            REFERENCES gold.dim_customer(customer_key),

        CONSTRAINT FK_fact_order_items_product
            FOREIGN KEY (product_key)
            REFERENCES gold.dim_product(product_key),

        CONSTRAINT FK_fact_order_items_seller
            FOREIGN KEY (seller_key)
            REFERENCES gold.dim_seller(seller_key),

        CONSTRAINT FK_fact_order_items_order_date
            FOREIGN KEY (order_date_key)
            REFERENCES gold.dim_date(date_key),

        CONSTRAINT FK_fact_order_items_shipping_date
            FOREIGN KEY (shipping_date_key)
            REFERENCES gold.dim_date(date_key)
    );
END;

-- Load the fact table only when it is empty.
-- This prevents accidental duplicate inserts.

IF NOT EXISTS
(
    SELECT 1
    FROM gold.fact_order_items
)
BEGIN
    INSERT INTO gold.fact_order_items
    (
        order_id,
        order_item_id,
        customer_key,
        product_key,
        seller_key,
        order_date_key,
        shipping_date_key,
        price,
        freight_value,
        quantity
    )
    SELECT
        oi.order_id,
        oi.order_item_id,
        dc.customer_key,
        dp.product_key,
        ds.seller_key,
        dd.date_key,
        dship.date_key,
        oi.price,
        oi.freight_value,
        1
    FROM silver.order_items oi
    INNER JOIN silver.orders o
        ON oi.order_id = o.order_id
    INNER JOIN silver.customers c
        ON o.customer_id = c.customer_id
    INNER JOIN gold.dim_customer dc
        ON c.customer_unique_id = dc.customer_unique_id
        AND o.order_purchase_timestamp >= dc.effective_from
        AND o.order_purchase_timestamp < dc.effective_to
    INNER JOIN gold.dim_product dp
        ON oi.product_id = dp.product_id
    INNER JOIN gold.dim_seller ds
        ON oi.seller_id = ds.seller_id
    INNER JOIN gold.dim_date dd
        ON CAST(o.order_purchase_timestamp AS DATE) = dd.full_date
    INNER JOIN gold.dim_date dship
        ON CAST(oi.shipping_limit_date AS DATE) = dship.full_date;
END;
