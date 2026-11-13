# Olist Dataset

## Overview
This directory contains the source data used by the Olist Data Warehouse project.

The dataset represents Brazilian e-commerce transactions and includes information about customers, sellers, products, orders, payments, reviews, and geolocation.

## Directory Structure
- `raw/` - Original source CSV files used by the ETL process.
- `processed/` - Reserved for any processed source files, if required.

## Source Files
The raw dataset consists of nine CSV files:

1. `olist_customers_dataset.csv`
2. `olist_geolocation_dataset.csv`
3. `olist_order_items_dataset.csv`
4. `olist_order_payments_dataset.csv`
5. `olist_order_reviews_dataset.csv`
6. `olist_orders_dataset.csv`
7. `olist_products_dataset.csv`
8. `olist_sellers_dataset.csv`
9. `product_category_name_translation.csv`

## Data Management
The original CSV files are excluded from Git version control through `.gitignore` because of their size.

The source files must be available locally when executing the SSIS package. Their file paths may need to be configured for the target computer.

## Usage
The raw CSV files are loaded into the Bronze layer of the `olist_dwh` database before subsequent Silver and Gold processing.
