### Delivery Performance Calculation

Delivery performance is calculated using calendar dates rather than full timestamps.

- `days_to_deliver`: Number of calendar days between purchase date and actual customer delivery date.
- `delivery_delay_days`: Number of calendar days between estimated delivery date and actual customer delivery date. Positive values indicate late delivery; zero or negative values indicate on-time or early delivery.
- `is_late`: 1 when the actual delivery date is later than the estimated delivery date; otherwise 0.
- Undelivered orders retain NULL delivery measures because their delivery performance cannot yet be determined.

**Design rationale:** Comparing calendar dates avoids classifying an order delivered later in the day on its estimated delivery date as late. Timestamp comparison identified 8,715 late deliveries, whereas calendar-date comparison identified 7,265. The difference of 1,450 represents orders delivered after the estimated time but still on the estimated calendar date.
### Silver Products — Missing Attribute Handling

During Silver layer data-quality validation, 610 product records were identified with missing values in four attributes:

- `product_category_name`
- `product_name_length`
- `product_description_length`
- `product_photos_qty`

**Source investigation:**

- Bronze contains 610 blank or whitespace-only values in each of these four attributes.
- Silver contains 610 NULL values in each corresponding attribute.
- A source-to-Silver comparison using `product_id` confirmed that all 610 affected records have matching missing values across both layers.
- No partially missing records were identified among these four attributes.

**Design decision:** Missing or blank product attributes are represented as NULL in the Silver layer rather than retaining empty strings or deleting the affected product records.

**Design rationale:** NULL provides a consistent representation of missing information and allows downstream queries to distinguish unavailable attributes from populated values. Retaining the records preserves product data and prevents unnecessary loss of product identifiers and other available attributes.

**Validation outcome:** All 32,951 product records were retained. Product identifiers were unique and non-NULL, with zero duplicate product IDs. The 610 affected records were successfully traced from Bronze to Silver.