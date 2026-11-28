\# Olist Data Warehouse — Data Lineage



\## 1. Purpose



This document describes the movement of Olist e-commerce data from the original CSV files through the Bronze and Silver layers into the Gold dimensional data warehouse.



It records the main transformations, row-count checkpoints, business rules, and relationships between source data and analytical tables.



\## 2. End-to-End Data Flow



```mermaid

flowchart TD

&#x20;   A\[Olist CSV Source Files] --> B\[Bronze Layer]

&#x20;   B --> C\[Silver Layer]

&#x20;   C --> D\[Gold Dimensions]

&#x20;   C --> E\[Gold Fact Tables]

&#x20;   D --> E

&#x20;   E --> F\[Analytics and Reporting]

```



\## 3. Source-to-Bronze Lineage



The nine original Olist CSV files are ingested into the Bronze layer using SSIS Flat File Sources and OLE DB Fast Load destinations.



Bronze preserves the ingested source data and adds ETL metadata:



\- `dwh\_load\_ts`: ingestion timestamp

\- `dwh\_source\_file`: originating source file

\- `dwh\_batch\_id`: batch identifier



\### Bronze row counts



| Source entity | Bronze table | Rows |

|---|---|---:|

| Customers | `bronze.olist\_customers` | 99,441 |

| Sellers | `bronze.olist\_sellers` | 3,095 |

| Products | `bronze.olist\_products` | 32,951 |

| Orders | `bronze.olist\_orders` | 99,441 |

| Order items | `bronze.olist\_order\_items` | 112,650 |

| Order payments | `bronze.olist\_order\_payments` | 103,886 |

| Order reviews | `bronze.olist\_order\_reviews` | 99,224 |

| Geolocation | `bronze.olist\_geolocation` | 1,000,163 |

| Category translation | `bronze.product\_category\_name\_translation` | 71 |

| \*\*Total\*\* | | \*\*1,560,922\*\* |



These counts represent the successfully loaded Bronze source records.



\## 4. Bronze-to-Silver Lineage



The Silver layer applies data cleaning, standardisation, validation, and deduplication to prepare consistent data for dimensional modelling.



Key transformations include:



\- Standardising postal-code values and location attributes.

\- Cleaning and conforming customer, seller, product, order, item, and payment data.

\- Converting source date and timestamp values into appropriate SQL Server data types.

\- Handling invalid or missing values.

\- Removing duplicate review records using `review\_id` as the business key.

\- Aggregating geolocation records to one record per postal-code prefix.



\### Important transformation decisions



\*\*Order reviews\*\*



The original Bronze review table contains 99,224 records. The Silver transformation retains the latest applicable record per `review\_id`, using the review-answer timestamp and order ID as tie-breakers.



| Checkpoint | Rows |

|---|---:|

| Bronze reviews | 99,224 |

| Silver reviews after deduplication | 98,410 |

| Duplicate records removed | 814 |



The resulting Silver review table contains 98,410 unique review IDs.



\*\*Geolocation\*\*



The original Bronze geolocation table contains 1,000,163 records. Silver consolidates the data to 19,015 postal-code records.



Brazilian geographic bounds are applied during coordinate cleaning. Four postal-code records have NULL latitude and longitude because their available coordinates fall outside the accepted bounds. These records are retained rather than silently discarded.



\*\*Customer data\*\*



Customer records are cleaned and standardised before loading into the Gold customer dimension. Customer history is preserved through Slowly Changing Dimension Type 2 logic.



\## 5. Silver-to-Gold Lineage



The Gold layer presents the cleaned data in a dimensional model consisting of seven dimensions and three fact tables.



\### Dimension lineage



| Gold dimension | Main Silver/source input | Purpose |

|---|---|---|

| `gold.dim\_customer` | Silver customers | Customer attributes and historical versions |

| `gold.dim\_date` | Calendar date generation and source dates | Calendar reporting attributes |

| `gold.dim\_geography` | Silver geolocation | Postal-code location attributes |

| `gold.dim\_order\_status` | Silver orders | Order status descriptions |

| `gold.dim\_payment\_type` | Silver order payments | Payment method descriptions |

| `gold.dim\_product` | Silver products and category translations | Product attributes and English category names |

| `gold.dim\_seller` | Silver sellers | Seller attributes and location |



All seven dimensions include an Unknown member using surrogate key `-1` to support unresolved or unavailable dimension references.



The customer dimension uses SCD Type 2 to preserve historical customer attribute versions through effective dates and a current-record indicator.



\### Fact lineage and grain



| Gold fact table | Main Silver inputs | Grain |

|---|---|---|

| `gold.fact\_order\_items` | Silver order items and orders, with customer, product, seller and geography lookups | One row per `order\_id` and `order\_item\_id` |

| `gold.fact\_order\_payments` | Silver order payments and orders, with payment-type lookup | One row per `order\_id` and `payment\_sequential` |

| `gold.fact\_order\_reviews` | Silver order reviews, with date lookups | One row per `review\_id` |



The fact tables use dimension surrogate keys to support analytical joins.



The order-item fact also includes delivery-related measures such as `days\_to\_deliver`, `delivery\_delay\_days`, and `is\_late`.



\## 6. Data Quality and Reconciliation



The project includes a SQL data quality test suite containing ten automated checks.



The latest execution returned \*\*10 PASS results\*\*.



Key reconciliation results include:



| Validation | Result |

|---|---:|

| Bronze source row-count mismatches | 0 |

| Duplicate Silver review IDs | 0 |

| Duplicate Silver geolocation postal codes | 0 |

| NULL dimension business keys | 0 |

| Duplicate dimension surrogate-key groups | 0 |

| Orphan fact-table foreign keys | 0 |

| Silver/Gold order-item price difference | 0.00 |

| Silver/Gold payment-value difference | 0.00 |

| Customers without exactly one current SCD2 record | 0 |

| Negative Silver order-item price/freight records | 0 |



The reconciled order-item price total is 13,591,643.70 in both Silver and Gold.



The reconciled payment-value total is 16,008,872.12 in both Silver and Gold.



\## 7. Analytical Consumption



The Gold layer supports eight business analytics queries covering:



1\. Monthly revenue and order trends.

2\. Top product categories by revenue.

3\. Seller revenue and average review scores.

4\. Late-delivery percentages by customer state.

5\. Average delivery time by seller and customer state.

6\. Payment method distribution and value.

7\. Repeat customer rate.

8\. The relationship between delivery performance and review scores.



These queries demonstrate how the dimensional model supports business reporting and analysis.



\## 8. Lineage Summary



The project follows a layered warehouse architecture:



\- \*\*Source:\*\* Original Olist CSV files.

\- \*\*Bronze:\*\* Source data ingestion with ETL metadata.

\- \*\*Silver:\*\* Cleaning, standardisation, deduplication, and data quality preparation.

\- \*\*Gold:\*\* Dimensional modelling with seven dimensions and three fact tables.

\- \*\*Analytics:\*\* Eight SQL queries supporting business analysis.



The documented row counts and reconciliation results provide checkpoints for validating the data as it moves through the warehouse.





