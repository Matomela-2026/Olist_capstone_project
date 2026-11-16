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

## Order Timestamp Chronology Validation

### Objective
Validate the chronological consistency of order timestamps between the Bronze and Silver layers while preserving the original source values.

### Validation rules

Two chronology rules were evaluated:

1. `order_delivered_carrier_date` should not precede `order_purchase_timestamp`.
2. `order_delivered_customer_date` should not precede `order_delivered_carrier_date`.

### Missing timestamp handling

The Bronze order dataset contains empty strings in optional delivery timestamp fields.

During validation, empty strings were explicitly converted to SQL `NULL` using `NULLIF` and `TRY_CONVERT(datetime2, ...)` before chronology comparisons.

This prevents missing values from being incorrectly classified as chronology anomalies.

### Validation results

| Validation | Bronze | Silver |
|---|---:|---:|
| Total orders | 99,441 | 99,441 |
| Carrier before purchase | 161 | 161 |
| Customer delivery before carrier | 23 | 23 |

Additional timestamp preservation validation confirmed that no genuine Bronze carrier or customer delivery timestamps were missing in Silver.

### Design decision

The 161 carrier-before-purchase anomalies and 23 customer-delivery-before-carrier anomalies were retained in Silver.

These values originate in the source dataset. No unsupported timestamp corrections were applied.

The Silver layer preserves the source timestamps while normalising empty optional timestamp values to SQL `NULL`.

The anomalies should be treated as source-data quality exceptions and considered when interpreting delivery performance analytics.

### Conclusion

Bronze and Silver contain the same 99,441 orders. Both layers produce identical chronology anomaly counts after correct date conversion and empty-string handling.

The validation therefore confirms timestamp preservation and consistent missing-value handling between the two layers.