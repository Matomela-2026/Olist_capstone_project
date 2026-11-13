# Raw Source Data

## Overview
This directory is intended to hold the original Olist dataset CSV files used by the data warehouse ETL process.

## Required Files
The following nine source files are required:

- `olist_customers_dataset.csv`
- `olist_geolocation_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_order_payments_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_orders_dataset.csv`
- `olist_products_dataset.csv`
- `olist_sellers_dataset.csv`
- `product_category_name_translation.csv`

## Usage
The SSIS package reads these files and loads their contents into the Bronze layer of the `olist_dwh` database.

## Version Control
CSV files are excluded from Git using `.gitignore` because of their size. This README is retained to document the expected source files and directory structure.

Obtain the original Olist dataset separately and place the CSV files in this directory before running the ETL package.
