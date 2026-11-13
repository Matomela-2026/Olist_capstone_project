# Bronze Layer

## Overview
The Bronze layer is the raw data ingestion layer of the Olist Medallion Data Warehouse.

It stores source data from the original Olist CSV files in SQL Server tables while retaining the source structure for traceability and downstream processing.

## Source Tables
The Bronze layer contains nine source tables:

- `olist_customers`
- `olist_geolocation`
- `olist_order_items`
- `olist_order_payments`
- `olist_order_reviews`
- `olist_orders`
- `olist_products`
- `olist_sellers`
- `product_category_name_translation`

## Data Loading
The Bronze tables are populated using the SSIS package in the `ssis/` directory.

The ETL workflow:
1. Creates the `olist_dwh` database and Bronze schema.
2. Truncates the destination tables before reloading.
3. Uses SSIS Data Flow Tasks with OLE DB destinations configured for Fast Load.
4. Adds data warehouse metadata columns, including load timestamp, source file, and batch ID.

## Data Quality and Traceability
Bronze row counts are checked against the loaded source data to confirm ingestion.

The metadata columns support load tracking and source traceability.

## Next Layer
The Silver layer performs data cleaning, standardisation, and deduplication before data is prepared for the Gold dimensional model.
