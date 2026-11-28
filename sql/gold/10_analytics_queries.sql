
USE olist_dwh;
GO

SET NOCOUNT ON;

-- ============================================================
-- OLIST GOLD LAYER: 8 BUSINESS ANALYTICS QUERIES
-- ============================================================


-- Q1. Monthly revenue and order volume for 2017-2018.
-- Revenue is measured using order-item price, excluding freight.

SELECT
    d.calendar_year,
    d.month_number,
    d.month_name,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.price) AS monthly_revenue
FROM gold.fact_order_items f
INNER JOIN gold.dim_date d
    ON f.order_date_key = d.date_key
WHERE d.calendar_year IN (2017, 2018)
GROUP BY
    d.calendar_year,
    d.month_number,
    d.month_name
ORDER BY
    d.calendar_year,
    d.month_number;


-- Q2. Top 10 English product categories by revenue.

SELECT TOP 10
    p.product_category_name_english,
    SUM(f.price) AS total_revenue,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM gold.fact_order_items f
INNER JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY
    p.product_category_name_english
ORDER BY
    total_revenue DESC;


-- Q3. Top 10 sellers by revenue and average review score.
-- Distinct order/seller pairs prevent item-level fan-out
-- when reviews are joined to seller orders.

WITH SellerRevenue AS
(
    SELECT
        f.seller_key,
        SUM(f.price) AS total_revenue
    FROM gold.fact_order_items f
    GROUP BY f.seller_key
),
SellerOrders AS
(
    SELECT DISTINCT
        seller_key,
        order_id
    FROM gold.fact_order_items
),
SellerReviewScores AS
(
    SELECT
        so.seller_key,
        AVG(CAST(r.review_score AS DECIMAL(10,2)))
            AS average_review_score
    FROM SellerOrders so
    INNER JOIN gold.fact_order_reviews r
        ON so.order_id = r.order_id
    GROUP BY so.seller_key
)
SELECT TOP 10
    s.seller_id,
    s.seller_state,
    sr.total_revenue,
    srs.average_review_score
FROM SellerRevenue sr
INNER JOIN gold.dim_seller s
    ON sr.seller_key = s.seller_key
LEFT JOIN SellerReviewScores srs
    ON sr.seller_key = srs.seller_key
ORDER BY sr.total_revenue DESC;


-- Q4. Percentage of late orders by customer state.
-- Each order is counted once, not once per item.

WITH OrderDelivery AS
(
    SELECT
        order_id,
        customer_key,
        MAX(CAST(is_late AS INT)) AS is_late
    FROM gold.fact_order_items
    GROUP BY
        order_id,
        customer_key
)
SELECT
    c.customer_state,
    COUNT(*) AS total_orders,
    SUM(od.is_late) AS late_orders,
    CAST(
        100.0 * SUM(od.is_late) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS late_order_percentage
FROM OrderDelivery od
INNER JOIN gold.dim_customer c
    ON od.customer_key = c.customer_key
GROUP BY c.customer_state
ORDER BY late_order_percentage DESC;


-- Q5. Average delivery days by seller state and customer state.

SELECT
    s.seller_state,
    c.customer_state,
    COUNT(DISTINCT f.order_id) AS total_orders,
    AVG(CAST(f.days_to_deliver AS DECIMAL(10,2)))
        AS average_delivery_days
FROM gold.fact_order_items f
INNER JOIN gold.dim_seller s
    ON f.seller_key = s.seller_key
INNER JOIN gold.dim_customer c
    ON f.customer_key = c.customer_key
WHERE f.days_to_deliver IS NOT NULL
GROUP BY
    s.seller_state,
    c.customer_state
ORDER BY
    average_delivery_days DESC;


-- Q6. Payment type mix, revenue and average installments.

SELECT
    payment_type,
    COUNT(*) AS payment_transactions,
    SUM(payment_value) AS total_payment_value,
    AVG(CAST(payment_installments AS DECIMAL(10,2)))
        AS average_installments,
    CAST(
        100.0 * SUM(payment_value)
        / NULLIF(SUM(SUM(payment_value)) OVER (), 0)
        AS DECIMAL(10,2)
    ) AS revenue_percentage
FROM gold.fact_order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- Q7. Repeat customer rate.
-- Customer versions are consolidated by customer_unique_id.

WITH CustomerOrders AS
(
    SELECT DISTINCT
        c.customer_unique_id,
        f.order_id
    FROM gold.fact_order_items f
    INNER JOIN gold.dim_customer c
        ON f.customer_key = c.customer_key
),
CustomerOrderCounts AS
(
    SELECT
        customer_unique_id,
        COUNT(*) AS order_count
    FROM CustomerOrders
    GROUP BY customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
        AS repeat_customers,
    CAST(
        100.0 *
        SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS repeat_customer_percentage
FROM CustomerOrderCounts;


-- Q8. Effect of late delivery on review scores.
-- One late-delivery status per order avoids item-level
-- multiplication of review records.

WITH OrderDelivery AS
(
    SELECT
        order_id,
        MAX(CAST(is_late AS INT)) AS is_late
    FROM gold.fact_order_items
    GROUP BY order_id
)
SELECT
    CASE
        WHEN od.is_late = 1 THEN 'Late delivery'
        ELSE 'On-time delivery'
    END AS delivery_category,
    COUNT(DISTINCT r.review_id) AS total_reviews,
    AVG(CAST(r.review_score AS DECIMAL(10,2)))
        AS average_review_score
FROM OrderDelivery od
INNER JOIN gold.fact_order_reviews r
    ON od.order_id = r.order_id

-- Q8. Effect of late delivery on review scores.
-- One delivery status per order; explicitly handles unknown status.

WITH OrderDelivery AS
(
    SELECT
        order_id,
        MAX(CAST(is_late AS INT)) AS is_late
    FROM gold.fact_order_items
    GROUP BY order_id
)
SELECT
    CASE
        WHEN od.is_late = 1 THEN 'Late delivery'
        WHEN od.is_late = 0 THEN 'On-time delivery'
        ELSE 'Unknown delivery status'
    END AS delivery_category,
    COUNT(DISTINCT r.review_id) AS total_reviews,
    AVG(CAST(r.review_score AS DECIMAL(10,2)))
        AS average_review_score
FROM OrderDelivery od
INNER JOIN gold.fact_order_reviews r
    ON od.order_id = r.order_id
GROUP BY
    CASE
        WHEN od.is_late = 1 THEN 'Late delivery'
        WHEN od.is_late = 0 THEN 'On-time delivery'
        ELSE 'Unknown delivery status'
    END
ORDER BY delivery_category;
