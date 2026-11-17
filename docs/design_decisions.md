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
## Silver Order Payments — Data Quality and Source Anomalies

### Validation Findings

The Silver Order Payments table contains **103,886 payment records**.

The following data quality checks were completed:

| Validation | Result |
|---|---:|
| Total payment records | 103,886 |
| Distinct payment records (`order_id` + `payment_sequential`) | 103,886 |
| Duplicate composite keys | 0 |
| NULL order IDs | 0 |
| Missing payment types | 0 |
| Non-positive payment sequences | 0 |
| Payment records without a matching Silver order | 0 |

The composite key `order_id` + `payment_sequential` represents the payment-record grain. An order may legitimately have multiple payment records.

### Source Data Anomalies

Two payment records contain zero installments. Nine payment records contain a payment value of zero.

These records were compared against the Bronze layer. The same values were present in Bronze, confirming that these conditions originated in the source data and were preserved in Silver.

The nine zero-value records consist of:
- Six voucher payment records.
- Three `not_defined` payment records.

### Payment Sequence Investigation

An initial validation identified 80 orders whose payment sequences did not begin at 1.

Further investigation established that:
- 78 orders contain one payment record with sequence 2.
- Two orders contain two payment records with sequences 2 and 3.
- Bronze and Silver have matching payment sequence aggregates for all 80 orders.
- A further check confirmed that none of the 80 affected orders has a sequence 1 record in Bronze.

This confirms that the sequence patterns were already present in the Bronze source data and were not introduced by the Silver layer.

### Design Decision

The Silver layer preserves these source records and their original payment values.

No artificial payment records were created, payment sequences were not renumbered, and source values were not modified merely to force the validation checks to pass.

This approach maintains data lineage and protects the integrity of the source information while making identified anomalies visible for downstream analysis.

### Conclusion

The Silver Order Payments validation confirmed:
- No duplicate payment composite keys.
- No missing order references.
- No missing payment types or invalid payment sequences.
- Identified installment, payment-value and sequence irregularities were inherited from Bronze.

The findings support the decision to retain the source data and document its limitations rather than introduce unsupported corrections.