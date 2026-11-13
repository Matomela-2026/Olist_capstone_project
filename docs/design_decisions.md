### Delivery Performance Calculation

Delivery performance is calculated using calendar dates rather than full timestamps.

- `days_to_deliver`: Number of calendar days between purchase date and actual customer delivery date.
- `delivery_delay_days`: Number of calendar days between estimated delivery date and actual customer delivery date. Positive values indicate late delivery; zero or negative values indicate on-time or early delivery.
- `is_late`: 1 when the actual delivery date is later than the estimated delivery date; otherwise 0.
- Undelivered orders retain NULL delivery measures because their delivery performance cannot yet be determined.

**Design rationale:** Comparing calendar dates avoids classifying an order delivered later in the day on its estimated delivery date as late. Timestamp comparison identified 8,715 late deliveries, whereas calendar-date comparison identified 7,265. The difference of 1,450 represents orders delivered after the estimated time but still on the estimated calendar date.