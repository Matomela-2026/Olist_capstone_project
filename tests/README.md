# Data Warehouse Testing and Validation

## Overview
This directory is reserved for project-level testing documentation and additional validation resources.

## Validation Approach
Data quality and warehouse validation are performed using SQL validation scripts maintained alongside the relevant data warehouse layers.

### Silver Layer
- `sql/silver/10_validate_customers.sql` - Checks customer records for duplicates, missing values, invalid postal codes, and customer relationships.
- `sql/silver/11_check_orders.sql` - Checks order records for duplicates, missing values, and customer relationships.

### Gold Layer
- `sql/gold/05_validate_fact_order_items.sql` - Validates the order items fact table.
- `sql/gold/07_validate_fact_order_payments.sql` - Validates the order payments fact table.
- `sql/gold/09_validate_fact_order_reviews.sql` - Validates the order reviews fact table.

## Validation Objectives
The validation checks focus on:
- Row counts and record uniqueness.
- Missing or invalid values.
- Duplicate business keys.
- Referential integrity between fact and dimension tables.
- Consistency of loaded warehouse data.

## Execution
Run the relevant SQL scripts in SQL Server Management Studio against the `olist_dwh` database after the corresponding warehouse tables have been created and loaded.

## Results
Validation results are reviewed through SQL query outputs. Successful checks should show no unexpected duplicates, missing required values, or unmatched foreign-key references.
