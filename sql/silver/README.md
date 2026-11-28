# Silver Layer

## Overview

The Silver layer is the cleaned and refined layer of the Olist Medallion Data Warehouse. It prepares Bronze data for reliable downstream use in the Gold layer.

The Silver layer includes data cleaning, standardisation, duplicate removal and validation.

## Implemented SQL Scripts

| Script | Purpose |
|---|---|
| `09_silver_geolocation.sql` | Cleans, standardises and aggregates geolocation records before loading `silver.geolocation`. |
| `10_validate_customers.sql` | Validates customer records, required attributes, postal codes and relationships with orders. |
| `11_check_orders.sql` | Validates order counts, unique order IDs, required fields, customer relationships and duplicate order IDs. |
| `12_silver_order_reviews.sql` | Deduplicates order reviews by `review_id` and reloads `silver.order_reviews`. |

## Geolocation Transformation

The geolocation transformation performs the following operations:

- Standardises postal codes to five characters.
- Converts latitude and longitude values into decimal values.
- Checks coordinates against configured geographic ranges.
- Converts city names to lowercase and removes surrounding spaces.
- Standardises state values.
- Aggregates geolocation records to one record per postal-code prefix.
- Selects the most frequent city and state for each prefix.
- Calculates average valid coordinates for each prefix.
- Reloads the Silver table using a truncate-and-load approach.

The transformation is implemented in `09_silver_geolocation.sql` and integrated into the SSIS control flow.

**Validated result:** 19,015 records in `silver.geolocation`, representing 19,015 distinct postal-code prefixes.

Four records have NULL latitude and longitude values because their source coordinates fall outside the configured geographic bounds.

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

## Order Review Transformation

The review transformation is implemented in `12_silver_order_reviews.sql`.

The transformation:

- Reads review records from Bronze.
- Deduplicates records using `review_id`.
- Retains one record per review ID.
- Uses the latest `review_answer_timestamp`, with `order_id` as a secondary ordering criterion.
- Reloads `silver.order_reviews` using a full-refresh approach.

**Validated result:**

| Validation | Result |
|---|---:|
| Bronze review records | 99,224 |
| Silver review records | 98,410 |
| Distinct Silver review IDs | 98,410 |
| Duplicate Silver review IDs | 0 |

## Order Timestamp Chronology Validation

### Objective

Validate the chronological consistency of order timestamps between the Bronze and Silver layers while preserving the original source values.

### Validation rules

1. `order_delivered_carrier_date` should not precede `order_purchase_timestamp`.
2. `order_delivered_customer_date` should not precede `order_delivered_carrier_date`.

### Missing timestamp handling

Empty strings in optional delivery timestamp fields are converted to SQL `NULL` using `NULLIF` and `TRY_CONVERT(datetime2, ...)` before chronology comparisons.

### Validation results

| Validation | Bronze | Silver |
|---|---:|---:|
| Total orders | 99,441 | 99,441 |
| Carrier before purchase | 161 | 161 |
| Customer delivery before carrier | 23 | 23 |

The 161 carrier-before-purchase anomalies and 23 customer-delivery-before-carrier anomalies were retained because they originate in the source dataset.

The Silver layer preserves source timestamps while normalising empty optional timestamp values to SQL `NULL`.

### Conclusion

Bronze and Silver contain the same 99,441 orders. Both layers produce identical chronology anomaly counts after date conversion and empty-string handling.

## Geolocation ZIP-Code Validation

### Objective

Validate the uniqueness and row-count reconciliation of postal-code prefixes in the Silver geolocation table.

### Latest validation results

| Validation | Result |
|---|---:|
| Total Silver geolocation rows | 19,015 |
| Distinct ZIP-code prefixes | 19,015 |
| Duplicate ZIP-code prefixes | 0 |

The Silver transformation now produces one aggregated record per postal-code prefix.

This is the result of the updated aggregation design, rather than the earlier approach that retained multiple geolocation records per prefix.

## Execution

The geolocation transformation is integrated into the existing SSIS package following creation of the Silver schema.

The review transformation is maintained as a separate SQL script and must execute after Bronze ingestion.

Customer and order validation scripts can be executed against the `olist_dwh` database in SQL Server Management Studio.

## Layer Outcome

The Silver layer provides refined geolocation and order-review data, alongside customer and order validation checks.

The validated Silver tables currently contain:

| Table | Rows |
|---|---:|
| customers | 99,441 |
| geolocation | 19,015 |
| order_items | 112,650 |
| order_payments | 103,886 |
| order_reviews | 98,410 |
| orders | 99,441 |
| product_category_name_translation | 71 |
| products | 32,951 |
| sellers | 3,095 |

The layer supports downstream Gold dimensions and fact tables while preserving documented source-data quality exceptions.