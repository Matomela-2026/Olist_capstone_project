
-- =====================================================
-- Project: Olist SSIS Medallion Data Warehouse
-- Layer: Gold
-- Script: 01_dim_product.sql
-- Purpose: Create and populate the product dimension
-- Grain: One row per product_id
-- =====================================================

-- Create product dimension if it does not exist

IF OBJECT_ID(N'gold.dim_product', N'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_product
    (
        product_key INT IDENTITY(1,1) NOT NULL,
        product_id NVARCHAR(50) NOT NULL,
        product_category_name NVARCHAR(100) NULL,
        product_category_name_english NVARCHAR(100) NULL,
        product_name_length INT NULL,
        product_description_length INT NULL,
        product_photos_qty INT NULL,
        product_weight_g INT NULL,
        product_length_cm INT NULL,
        product_height_cm INT NULL,
        product_width_cm INT NULL,

        CONSTRAINT PK_gold_dim_product
            PRIMARY KEY (product_key),

        CONSTRAINT UQ_gold_dim_product_product_id
            UNIQUE (product_id)
    );
END;

-- Load product records only when the dimension is empty

IF NOT EXISTS
(
    SELECT 1
    FROM gold.dim_product
)
BEGIN
    INSERT INTO gold.dim_product
    (
        product_id,
        product_category_name,
        product_category_name_english,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    )
    SELECT
        p.product_id,
        p.product_category_name,
        CASE
    WHEN p.product_category_name = 'pc_gamer'
        THEN 'gaming_pc'
    WHEN p.product_category_name =
        'portateis_cozinha_e_preparadores_de_alimentos'
        THEN 'portable_kitchen_and_food_preparers'
    ELSE t.product_category_name_english
END,
        p.product_name_length,
        p.product_description_length,
        p.product_photos_qty,
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm
    FROM silver.products p
    LEFT JOIN silver.product_category_name_translation t
        ON p.product_category_name = t.product_category_name;
END;
