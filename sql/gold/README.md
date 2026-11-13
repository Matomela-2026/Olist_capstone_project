# Gold Layer

## Overview
The Gold layer contains the business-ready dimensional model used for reporting and analytical queries.

It follows a dimensional warehouse design with dimension tables and fact tables.

## Dimension Tables
- `00_dim_customer.sql` - Creates and loads the customer dimension using Slowly Changing Dimension Type 2 (SCD Type 2).
- `01_dim_product.sql` - Creates and loads the product dimension, including translated product categories.
- `02_dim_seller.sql` - Creates and loads the seller dimension.
- `03_dim_date.sql` - Creates and loads the date dimension.

## Fact Tables
- `04_fact_order_items.sql` - Stores order item transaction details.
- `06_fact_order_payments.sql` - Stores payment transaction details.
- `08_fact_order_reviews.sql` - Stores customer review details.

## Validation Scripts
- `05_validate_fact_order_items.sql`
- `07_validate_fact_order_payments.sql`
- `09_validate_fact_order_reviews.sql`

These scripts check row counts, key uniqueness, missing values, and relationships with relevant dimensions.

## Execution
Execute the dimension scripts before the fact table scripts in SQL Server Management Studio against the `olist_dwh` database.

Run the corresponding validation scripts after loading the tables.

## Analytical Purpose
The Gold layer supports analysis of customers, products, sellers, orders, payments, and customer reviews.
