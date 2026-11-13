# SQL Scripts

This directory contains the SQL scripts used to create, transform and validate the Olist data warehouse.

## Directory Structure

| Directory | Purpose |
|---|---|
| `administration/` | Database administration and supporting scripts. |
| `bronze/` | Bronze schema and source data preparation scripts. |
| `silver/` | Data cleaning, transformation and validation scripts. |
| `gold/` | Dimension and fact table creation, loading and validation scripts. |
| `etl/` | ETL batch logging tables and stored procedures. |

## Silver Layer

- `09_silver_geolocation.sql` – Cleans, standardises and deduplicates geolocation data.
- `10_validate_customers.sql` – Checks customer data quality and relationships with orders.
- `11_check_orders.sql` – Checks order completeness, uniqueness and customer relationships.

See `silver/README.md` for more information.

## Gold Layer

Contains scripts for customer, product, seller and date dimensions, order item, payment and review fact tables, and fact table validation.

See `gold/README.md` for implementation details.

## ETL Layer

- `00_create_batch_log.sql` – Creates the batch logging table.
- `01_batch_logging_procedures.sql` – Creates procedures for starting and completing ETL batches.

## Execution

Execute the scripts in SQL Server Management Studio against the `olist_dwh` database, following the appropriate layer dependencies.

The SSIS package handles configured database creation, Bronze ingestion and Silver geolocation processing. Other SQL scripts are executed separately as required.