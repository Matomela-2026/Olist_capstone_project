\# Olist E-Commerce Data Warehouse — Gold Data Dictionary



\## 1. Overview



This document describes the Gold layer of the Olist E-Commerce Data Warehouse. The Gold layer contains conformed dimensions and business-process fact tables designed for analytical reporting.



\*\*Database:\*\* `olist\_dwh`  

\*\*Schema:\*\* `gold`  

\*\*Model:\*\* Dimensional star schema



\### Naming conventions



\- `\*\_key`: Surrogate or foreign key used in dimensional relationships.

\- `\*\_id`: Business identifier originating from the source system.

\- `\*\_date\_key`: Foreign key referencing `gold.dim\_date`.

\- `is\_\*`: Boolean indicator.

\- `\*\_value`: Monetary or numeric measure.



\## 2. Dimension tables



\### 2.1 `gold.dim\_customer`



\*\*Purpose:\*\* Stores customer details and historical customer versions using Slowly Changing Dimension Type 2 (SCD Type 2).



\*\*Grain:\*\* One row per customer version.



| Column | Data type | Nullable | Description |

|---|---|---|---|

| customer\_key | INT | No | Surrogate customer key. |

| customer\_unique\_id | NVARCHAR(50) | No | Source-system unique customer identifier. |

| customer\_zip\_code\_prefix | CHAR(5) | No | Customer postal code prefix. |

| customer\_city | NVARCHAR(100) | No | Customer city. |

| customer\_state | CHAR(2) | No | Customer state abbreviation. |

| effective\_from | DATETIME2 | No | Start date/time for this customer version. |

| effective\_to | DATETIME2 | No | End date/time for this customer version. |

| is\_current | BIT | No | Indicates whether this is the current customer version. |



\### 2.2 `gold.dim\_date`



\*\*Purpose:\*\* Provides calendar attributes for analysing orders, shipping and review dates.



\*\*Grain:\*\* One row per calendar date.



| Column | Data type | Nullable | Description |

|---|---|---|---|

| date\_key | INT | No | Surrogate date key. |

| full\_date | DATE | No | Actual calendar date. |

| calendar\_year | SMALLINT | No | Calendar year. |

| calendar\_quarter | TINYINT | No | Calendar quarter. |

| month\_number | TINYINT | No | Month number (1–12). |

| month\_name | NVARCHAR(20) | No | Month name. |

| day\_of\_month | TINYINT | No | Day within the month. |

| day\_name | NVARCHAR(20) | No | Day name. |

| day\_of\_week | TINYINT | No | Numeric day of week. |

| is\_weekend | BIT | No | Indicates whether the date is a weekend. |



\### 2.3 `gold.dim\_geography`



\*\*Purpose:\*\* Stores geographical information associated with customer and seller postal code prefixes.



\*\*Grain:\*\* One row per geographical postal code prefix.



| Column | Data type | Nullable | Description |

|---|---|---|---|

| geography\_key | INT | No | Surrogate geography key. |

| zip\_code\_prefix | CHAR(5) | No | Postal code prefix. |

| city | NVARCHAR(200) | No | Associated city. |

| state | CHAR(2) | No | State abbreviation. |

| latitude | DECIMAL | Yes | Geographic latitude. |

| longitude | DECIMAL | Yes | Geographic longitude. |



\### 2.4 `gold.dim\_order\_status`



\*\*Purpose:\*\* Provides descriptive order-status values for order analysis.



\*\*Grain:\*\* One row per order status.



| Column | Data type | Nullable | Description |

|---|---|---|---|

| order\_status\_key | INT | No | Surrogate order status key. |

| order\_status | NVARCHAR(50) | No | Order status description. |



\### 2.5 `gold.dim\_payment\_type`



\*\*Purpose:\*\* Provides standardised payment method descriptions for payment analysis.



\*\*Grain:\*\* One row per payment type.



| Column | Data type | Nullable | Description |

|---|---|---|---|

| payment\_type\_key | INT | No | Surrogate payment type key. |

| payment\_type | NVARCHAR(50) | No | Payment method description. |



\### 2.6 `gold.dim\_product`



\*\*Purpose:\*\* Stores product identifiers, translated product categories and product attributes.



\*\*Grain:\*\* One row per product.



| Column | Data type | Nullable | Description |

|---|---|---|---|

| product\_key | INT | No | Surrogate product key. |

| product\_id | NVARCHAR(50) | No | Source-system product identifier. |

| product\_category\_name | NVARCHAR(100) | Yes | Original Portuguese product category. |

| product\_category\_name\_english | NVARCHAR(100) | Yes | English-translated product category. |

| product\_name\_length | INT | Yes | Product name character length. |

| product\_description\_length | INT | Yes | Product description character length. |

| product\_photos\_qty | INT | Yes | Number of product photos. |

| product\_weight\_g | INT | Yes | Product weight in grams. |

| product\_length\_cm | INT | Yes | Product length in centimetres. |

| product\_height\_cm | INT | Yes | Product height in centimetres. |

| product\_width\_cm | INT | Yes | Product width in centimetres. |



\### 2.7 `gold.dim\_seller`



\*\*Purpose:\*\* Stores seller identifiers and geographical attributes.



\*\*Grain:\*\* One row per seller.



| Column | Data type | Nullable | Description |

|---|---|---|---|

| seller\_key | INT | No | Surrogate seller key. |

| seller\_id | NVARCHAR(50) | No | Source-system seller identifier. |

| seller\_zip\_code\_prefix | CHAR(5) | No | Seller postal code prefix. |

| seller\_city | NVARCHAR(100) | No | Seller city. |

| seller\_state | CHAR(2) | No | Seller state abbreviation. |



\## 3. Fact tables



\### 3.1 `gold.fact\_order\_items`



\*\*Purpose:\*\* Records order-item transactions and supports sales, delivery and geographical analysis.



\*\*Grain:\*\* One row per order and order item (`order\_id` + `order\_item\_id`).



| Column | Data type | Nullable | Description |

|---|---|---|---|

| order\_id | NVARCHAR(50) | No | Source-system order identifier. |

| order\_item\_id | INT | No | Item sequence within an order. |

| customer\_key | INT | No | Customer dimension foreign key. |

| product\_key | INT | No | Product dimension foreign key. |

| seller\_key | INT | No | Seller dimension foreign key. |

| order\_date\_key | INT | No | Order date dimension foreign key. |

| shipping\_date\_key | INT | No | Shipping date dimension foreign key. |

| price | DECIMAL | No | Order-item selling price. |

| freight\_value | DECIMAL | No | Freight charge for the order item. |

| quantity | INT | No | Item quantity represented by the fact row. |

| customer\_geography\_key | INT | No | Customer geography dimension foreign key. |

| seller\_geography\_key | INT | No | Seller geography dimension foreign key. |

| order\_status\_key | INT | No | Order status dimension foreign key. |

| days\_to\_deliver | INT | Yes | Delivery duration in days. |

| delivery\_delay\_days | INT | Yes | Delivery delay in days relative to the expected delivery date. |

| is\_late | BIT | Yes | Indicates whether the delivery was late. |



\### 3.2 `gold.fact\_order\_payments`



\*\*Purpose:\*\* Records payment transactions associated with customer orders.



\*\*Grain:\*\* One row per order payment sequence (`order\_id` + `payment\_sequential`).



| Column | Data type | Nullable | Description |

|---|---|---|---|

| order\_id | NVARCHAR(50) | No | Source-system order identifier. |

| payment\_sequential | INT | No | Payment sequence within an order. |

| order\_date\_key | INT | No | Order date dimension foreign key. |

| payment\_type | NVARCHAR(50) | No | Payment method description. |

| payment\_installments | INT | No | Number of payment instalments. |

| payment\_value | DECIMAL | No | Monetary payment amount. |

| payment\_type\_key | INT | No | Payment type dimension foreign key. |



\### 3.3 `gold.fact\_order\_reviews`



\*\*Purpose:\*\* Records customer reviews and supports customer satisfaction analysis.



\*\*Grain:\*\* One row per review (`review\_id`).



| Column | Data type | Nullable | Description |

|---|---|---|---|

| review\_id | NVARCHAR(50) | No | Source-system review identifier. |

| order\_id | NVARCHAR(50) | No | Associated order identifier. |

| review\_date\_key | INT | No | Review creation date dimension foreign key. |

| review\_answer\_date\_key | INT | No | Review response date dimension foreign key. |

| review\_score | INT | No | Customer review score. |

| review\_comment\_title | NVARCHAR(MAX) | Yes | Review comment title. |

| review\_comment\_message | NVARCHAR(MAX) | Yes | Review comment message. |



\## 4. Dimensional model and relationships



The Gold layer contains seven dimensions and three fact tables.



The main relationships are:



\- `fact\_order\_items` references customer, product, seller, date, geography and order status dimensions.

\- `fact\_order\_payments` references the date and payment type dimensions.

\- `fact\_order\_reviews` references the date dimension twice: review creation date and review answer date.

\- The customer dimension uses SCD Type 2 to preserve customer history.

\- Unknown dimension members use the surrogate key `-1` where applicable.



\## 5. Design considerations



\- Surrogate keys provide consistent dimensional relationships.

\- Fact table grains are explicitly defined to support correct aggregation.

\- Date dimensions support time-based reporting.

\- Customer history is maintained through effective dates and the current-row indicator.

\- Nullable product attributes and geographical coordinates are retained where source information is unavailable.

\- English product category translations support business-friendly reporting.



