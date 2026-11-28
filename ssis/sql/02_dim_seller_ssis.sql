
-- =====================================================
-- Project: Olist SSIS Medallion Data Warehouse
-- Layer: Gold
-- Script: 02_dim_seller.sql
-- Purpose: Create and populate the seller dimension
-- Grain: One row per seller_id
-- =====================================================

-- Create seller dimension if it does not exist

IF OBJECT_ID(N'gold.dim_seller', N'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_seller
    (
        seller_key INT IDENTITY(1,1) NOT NULL,
        seller_id NVARCHAR(50) NOT NULL,
        seller_zip_code_prefix CHAR(5) NOT NULL,
        seller_city NVARCHAR(100) NOT NULL,
        seller_state CHAR(2) NOT NULL,

        CONSTRAINT PK_gold_dim_seller
            PRIMARY KEY (seller_key),

        CONSTRAINT UQ_gold_dim_seller_seller_id
            UNIQUE (seller_id)
    );
END;

-- Load seller records only when the dimension is empty

IF NOT EXISTS
(
    SELECT 1
    FROM gold.dim_seller
)
BEGIN
    INSERT INTO gold.dim_seller
    (
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    )
    SELECT
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    FROM silver.sellers;
END;
