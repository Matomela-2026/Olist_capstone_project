# Olist E-Commerce Data Warehouse | SSIS Medallion Architecture

## Project Overview

This project implements an end-to-end data warehouse using the Brazilian Olist e-commerce dataset. It demonstrates how raw transactional data can be extracted, loaded, cleaned, validated and transformed into an analytical data warehouse using Microsoft SQL Server and SQL Server Integration Services (SSIS).

The solution follows the **Medallion Architecture**, separating data processing into Bronze, Silver and Gold layers, with an additional ETL layer for batch logging and process monitoring.

## Technology Stack

- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- SQL Server Integration Services (SSIS)
- Visual Studio with SQL Server Data Tools
- Transact-SQL (T-SQL)
- Git and GitHub

## Architecture

The solution uses four database schemas:

| Layer | Schema | Purpose |
|---|---|---|
| Bronze | `bronze` | Stores raw data loaded from the source CSV files. |
| Silver | `silver` | Holds cleaned and refined data, supported by data-quality validation. |
| Gold | `gold` | Contains analytical dimensions and fact tables for reporting. |
| ETL | `etl` | Tracks ETL batch execution, status, row counts and errors. |

### Data Flow

1. Source CSV files are loaded into the Bronze layer through SSIS.
2. Silver processing cleans and standardises data. Geolocation transformation and customer/order validation are implemented in SQL.
3. Gold dimension and fact tables are populated using SQL transformation scripts.
4. ETL stored procedures record batch execution details and outcomes.

## Source Dataset

The project uses the Olist Brazilian E-Commerce Public Dataset.

Nine source CSV files are used:

- Customers
- Geolocation
- Order items
- Order payments
- Order reviews
- Orders
- Products
- Sellers
- Product category translation

The original CSV files are excluded from Git version control because of their size. Obtain the dataset separately and place the nine source files in `data/raw/`, following the instructions in `data/raw/README.md`.

## Bronze Layer

The Bronze layer stores the source data in SQL Server with additional ETL metadata.

SSIS performs the data loading using Data Flow Tasks and Fast Load destinations.

Each load includes metadata such as:

- `dwh_load_ts`
- `dwh_source_file`
- `dwh_batch_id`

### Validated Bronze Record Counts

| Source table | Records |
|---|---:|
| Customers | 99,441 |
| Geolocation | 1,000,163 |
| Order items | 112,650 |
| Order payments | 103,886 |
| Order reviews | 99,224 |
| Orders | 99,441 |
| Products | 32,951 |
| Sellers | 3,095 |
| Category translation | 71 |
| **Total** | **1,550,922** |

## Silver Layer

The Silver layer prepares data for downstream analytical processing.

The implemented geolocation transformation:

- Standardises postal codes, city names and state values.
- Converts and validates latitude and longitude values.
- Removes duplicate location records.
- Reloads the refined data into `silver.geolocation`.

The repository also includes SQL validation scripts for customer and order data, checking record counts, missing attributes, invalid postal codes, duplicate order IDs and relationships between customers and orders.

**Validated Silver geolocation count: 738,297 records.**

See `sql/silver/README.md` for script details.

## Gold Layer

The Gold layer contains dimensional and fact tables designed for analytical queries.

### Dimensions

| Dimension | Records |
|---|---:|
| `gold.dim_customer` | 96,352 |
| `gold.dim_product` | 32,951 |
| `gold.dim_seller` | 3,095 |
| `gold.dim_date` | 1,583 |

The customer dimension implements **Slowly Changing Dimension Type 2 (SCD Type 2)** to preserve customer history.

### Fact Tables

| Fact table | Records |
|---|---:|
| `gold.fact_order_items` | 112,650 |
| `gold.fact_order_payments` | 103,886 |
| `gold.fact_order_reviews` | 99,224 |

Gold validation scripts check record counts, uniqueness, missing values and dimension key relationships.

## ETL Logging and Monitoring

The ETL schema provides batch execution tracking through:

- `etl.batch_log`
- `etl.usp_start_batch`
- `etl.usp_finish_batch`

The logging framework records:

- Batch ID
- Process name
- Start and end timestamps
- Execution status
- Rows processed
- Error messages

Both successful and failed batch scenarios were tested.

## Repository Structure

```text
Olist_capstone_project/
│
├── data/
│   ├── raw/
│   └── README.md
│
├── docs/
│
├── sql/
│   ├── administration/
│   ├── bronze/
│   ├── silver/
│   ├── gold/
│   └── etl/
│
├── ssis/
│
├── tests/
│
├── .gitignore
└── README.md
```

## Running the Project

1. Install SQL Server and the required SSIS development tools.
2. Obtain the Olist source dataset and place the nine CSV files in `data/raw/`.
3. Open the SSIS solution in the `ssis/` directory.
4. Configure the `MATOMELA` connection manager for the local SQL Server instance.
5. Execute the SSIS package to create the database objects and load the Bronze data, followed by the configured Silver geolocation processing.
6. Execute the remaining Silver validation and Gold SQL scripts in the appropriate order.
7. Create the ETL logging objects and execute the stored procedure tests.

Review the SQL scripts and README files in each layer for further implementation details.

## Project Outcome

The project demonstrates an end-to-end data engineering workflow involving source data ingestion, layered warehouse design, SQL transformation, data-quality validation, dimensional modelling, ETL logging and version control.

It provides a foundation for analytical reporting and further business intelligence development.