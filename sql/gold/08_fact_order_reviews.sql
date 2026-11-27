
USE olist_dwh;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Create Gold table if it does not exist.
    IF OBJECT_ID('gold.fact_order_reviews', 'U') IS NULL
    BEGIN
        CREATE TABLE gold.fact_order_reviews
        (
            review_id NVARCHAR(100) NOT NULL,
            order_id NVARCHAR(100) NOT NULL,
            review_date_key INT NOT NULL,
            review_answer_date_key INT NOT NULL,
            review_score INT NOT NULL,
            review_comment_title NVARCHAR(MAX) NULL,
            review_comment_message NVARCHAR(MAX) NULL,

            CONSTRAINT PK_gold_fact_order_reviews
               PRIMARY KEY (review_id),

            CONSTRAINT FK_fact_reviews_creation_date
                FOREIGN KEY (review_date_key)
                REFERENCES gold.dim_date(date_key),

            CONSTRAINT FK_fact_reviews_answer_date
                FOREIGN KEY (review_answer_date_key)
                REFERENCES gold.dim_date(date_key),

            CONSTRAINT CK_fact_reviews_score
                CHECK (review_score BETWEEN 1 AND 5)
        );
    END;

    -- Remove the existing primary key.
    IF EXISTS
    (
        SELECT 1
        FROM sys.key_constraints
        WHERE parent_object_id =
              OBJECT_ID('gold.fact_order_reviews')
          AND type = 'PK'
    )
    BEGIN
        ALTER TABLE gold.fact_order_reviews
        DROP CONSTRAINT PK_gold_fact_order_reviews;
    END;

    -- Full refresh from the corrected Silver layer.
    DELETE FROM gold.fact_order_reviews;

    DECLARE @expected_rows BIGINT;
    DECLARE @inserted_rows BIGINT;

    SELECT @expected_rows = COUNT_BIG(*)
    FROM silver.order_reviews;

    INSERT INTO gold.fact_order_reviews
    (
        review_id,
        order_id,
        review_date_key,
        review_answer_date_key,
        review_score,
        review_comment_title,
        review_comment_message
    )
    SELECT
        r.review_id,
        r.order_id,
        d1.date_key,
        d2.date_key,
        r.review_score,
        r.review_comment_title,
        r.review_comment_message
    FROM silver.order_reviews r
    INNER JOIN gold.dim_date d1
        ON CAST(r.review_creation_date AS DATE) = d1.full_date
    INNER JOIN gold.dim_date d2
        ON CAST(r.review_answer_timestamp AS DATE) = d2.full_date;

    SET @inserted_rows = @@ROWCOUNT;

    -- Prevent incomplete Gold loads.
    IF @inserted_rows <> @expected_rows
    BEGIN
        THROW 50001,
              'Gold review load failed: inserted row count does not match Silver.',
              1;
    END;

    -- Enforce one row per review.
    ALTER TABLE gold.fact_order_reviews
    ADD CONSTRAINT PK_gold_fact_order_reviews
        PRIMARY KEY (review_id);

    COMMIT TRANSACTION;

    PRINT 'Gold fact_order_reviews refreshed successfully.';
    PRINT 'Rows loaded: ' + CAST(@inserted_rows AS VARCHAR(20));

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;
GO
