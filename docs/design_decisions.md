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
## Silver Order Reviews — Data Quality and Source Anomalies

### Validation Findings

The Silver Order Reviews table contains **99,224 records**.

The following checks were completed:

| Validation | Result |
|---|---:|
| Total review records | 99,224 |
| Distinct review IDs | 98,410 |
| Extra rows from repeated review IDs | 814 |
| Repeated review ID groups | 789 |
| Highest occurrences of one review ID | 3 |
| NULL review IDs | 0 |
| NULL order IDs | 0 |
| Invalid review scores | 0 |
| Reviews without matching Silver orders | 0 |
| Answers before review creation | 0 |

### Repeated Review ID Investigation

The investigation identified 789 review ID groups occurring more than once, accounting for 814 extra rows.

Further investigation established that:

- The repeated review ID groups already exist in the Bronze layer.
- All 789 repeated review ID groups in Bronze are associated with multiple orders.
- All repeated groups in Silver have consistent review scores.
- No repeated group has conflicting non-NULL review titles or messages.
- No repeated group contains a mixture of NULL and non-NULL titles or messages.
- Review creation and answer timestamps are consistent within all repeated groups.

A sample review ID was compared directly between Bronze and Silver. The three records associated with that review ID were present in both layers with matching order IDs, scores and comments.

The aggregate comparison also confirmed that Bronze and Silver contain the same total number of rows and distinct review IDs.

These findings indicate that the repeated review identifiers are inherited source-data anomalies rather than evidence of new duplication introduced by Silver.

### Missing Review Comments

The following missing-comment values were identified:

| Attribute | Missing records |
|---|---:|
| Review comment titles | 87,666 |
| Review comment messages | 58,274 |

Missing written feedback does not automatically represent a data-quality failure. Customers may submit a numerical rating without providing a title or written comment.

The review records were therefore retained.

### Review Score Distribution

The review score profile is:

| Review score | Number of reviews | Percentage |
|---|---:|---:|
| 1 | 11,424 | 11.51% |
| 2 | 3,151 | 3.18% |
| 3 | 8,179 | 8.24% |
| 4 | 19,142 | 19.29% |
| 5 | 57,328 | 57.78% |
| **Total** | **99,224** | **100%** |

The distribution shows that five-star reviews represent the largest category, accounting for 57.78% of all review records. Reviews with scores of four or five account for 77.07%.

### Bronze-to-Silver Reconciliation

The row-count comparison produced the following results:

| Metric | Bronze | Silver |
|---|---:|---:|
| Total rows | 99,224 | 99,224 |
| Distinct review IDs | 98,410 | 98,410 |

The matching counts confirm that there was no net row loss or increase between Bronze and Silver.

### Design Decision

Repeated review identifiers were retained because the records were already present in Bronze and were associated with different orders.

No review records were deleted, review identifiers were not artificially regenerated, and missing comments were not treated as grounds for removing records.

This approach preserves source lineage and prevents unsupported changes to customer review information.

### Conclusion

The Silver Order Reviews validation established that:

- All review identifiers and order identifiers are populated.
- Review scores fall within the valid range of 1 to 5.
- Review answer timestamps do not precede review creation timestamps.
- All reviews reference existing Silver orders.
- Repeated review ID patterns originate in Bronze.
- Missing review comments are retained as valid optional attributes.
- Bronze and Silver have matching total row counts and distinct review ID counts.

The Silver Order Reviews table retains the source records while making identified data-quality limitations visible for downstream reporting and analysis.
## Silver Orders – Empty Timestamp Standardisation

### Finding

During Silver Orders validation, differences were identified between the timestamp fields in the Bronze and Silver layers.

The following Bronze columns are stored as `nvarchar`:

- `order_approved_at`
- `order_delivered_carrier_date`
- `order_delivered_customer_date`

Investigation confirmed that some records contain empty strings (`''`) in Bronze, while the corresponding Silver records contain SQL `NULL` values.

### Validation Results

| Timestamp column | Empty strings in Bronze | Corresponding NULL values in Silver |
|---|---:|---:|
| `order_approved_at` | 160 | 160 |
| `order_delivered_carrier_date` | 1,783 | 1,783 |
| `order_delivered_customer_date` | 2,965 | 2,965 |
| **Total field-level differences** | **4,908** | **4,908** |

A final comparison using an INNER JOIN on `order_id` confirmed that all three counts matched exactly.

### Design Decision

Empty timestamp strings in the Bronze layer are represented as SQL `NULL` values in the Silver layer.

This standardisation ensures that missing date values are represented consistently as database NULLs rather than empty text values.

- Bronze preserves the raw source representation.
- Silver uses NULL to represent missing timestamp values.
- These 4,908 field-level differences are explained by this standardisation and are not, by themselves, evidence of data loss.

### Validation Outcome

**PASS** – All three timestamp comparisons reconciled successfully.

The validation confirms the resulting data behaviour. The original SQL or SSIS transformation responsible for this standardisation has not yet been identified in the tracked project files.