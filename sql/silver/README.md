# Silver Layer

## Overview

The Silver layer is the cleaned and refined layer of the Olist Medallion Data Warehouse. It prepares Bronze data for reliable downstream use in the Gold layer.

The Silver layer includes data cleaning, standardisation, duplicate removal and validation.

## Implemented SQL Scripts

| Script | Purpose |
|---|---|
| `09_silver_geolocation.sql` | Cleans, standardises and deduplicates geolocation records before loading them into `silver.geolocation`. |
| `10_validate_customers.sql` | Validates customer records, required attributes, postal codes and relationships with orders. |
| `11_check_orders.sql` | Validates order counts, unique order IDs, required fields, customer relationships and duplicate order IDs. |

## Geolocation Transformation

The geolocation transformation performs the following operations:

- Standardises postal codes to five characters.
- Converts latitude and longitude values into decimal values.
- Checks coordinates against the configured geographic ranges.
- Converts city names to lowercase and removes surrounding spaces.
- Standardises state values.
- Removes duplicate records using `ROW_NUMBER()`, retaining one record for each unique combination of postal code, coordinates, city and state.
- Reloads the Silver table using a truncate-and-load approach.

The transformation is implemented in `09_silver_geolocation.sql` and integrated into the SSIS control flow.

**Validated result:** 738,297 records in `silver.geolocation`.

## Customer Validation

The customer validation script checks:

- Total records compared with unique customer IDs.
- Missing customer IDs and other important customer attributes.
- Invalid postal codes.
- Customers without corresponding orders.

These checks help assess data completeness and referential consistency.

## Orders Validation

The orders validation script checks:

- Total records compared with unique order IDs.
- Missing order IDs, customer IDs, purchase timestamps and order statuses.
- Orders without matching customer records.
- Duplicate order IDs.

These checks help establish the quality and reliability of order data before downstream analytical processing.

## Execution

Run the SQL scripts against the `olist_dwh` database in SQL Server Management Studio.

The geolocation transformation is also included in the SSIS package, following the creation of the Silver schema.

## Layer Outcome

The Silver layer provides cleaned geolocation data and validation checks for customers and orders. It supports the downstream Gold dimensions and fact tables while helping identify data-quality issues early in the warehouse pipeline.