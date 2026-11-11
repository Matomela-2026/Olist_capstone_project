IF OBJECT_ID('gold.fact_order_payments', 'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_order_payments
    (
        order_id NVARCHAR(50) NOT NULL,
        payment_sequential INT NOT NULL,
        order_date_key INT NOT NULL,
        payment_type NVARCHAR(50) NOT NULL,
        payment_installments INT NOT NULL,
        payment_value DECIMAL(10,2) NOT NULL,

        CONSTRAINT PK_gold_fact_order_payments
            PRIMARY KEY (order_id, payment_sequential),

        CONSTRAINT FK_fact_order_payments_order_date
            FOREIGN KEY (order_date_key)
            REFERENCES gold.dim_date(date_key)
    );
END;

IF NOT EXISTS
(
    SELECT 1
    FROM gold.fact_order_payments
)
BEGIN
    INSERT INTO gold.fact_order_payments
    (
        order_id,
        payment_sequential,
        order_date_key,
        payment_type,
        payment_installments,
        payment_value
    )
    SELECT
        p.order_id,
        p.payment_sequential,
        d.date_key,
        p.payment_type,
        p.payment_installments,
        p.payment_value
    FROM silver.order_payments p
    INNER JOIN silver.orders o
        ON p.order_id = o.order_id
    INNER JOIN gold.dim_date d
        ON CAST(o.order_purchase_timestamp AS DATE) = d.full_date;
END;