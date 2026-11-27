
USE olist_dwh;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Create the Silver table if it does not exist.
    IF OBJECT_ID('silver.order_reviews', 'U') IS NULL
    BEGIN
        CREATE TABLE silver.order_reviews
        (
            review_id NVARCHAR(100) NOT NULL,
            order_id NVARCHAR(100) NOT NULL,
            review_score INT NOT NULL,
            review_comment_title NVARCHAR(MAX) NULL,
            review_comment_message NVARCHAR(MAX) NULL,
            review_creation_date DATETIME2 NOT NULL,
            review_answer_timestamp DATETIME2 NOT NULL,
            dwh_load_ts DATETIME2 NOT NULL
        );
    END;

    -- Remove the existing primary key so the table can be rebuilt.
   IF EXISTS
(
    SELECT 1
    FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID('silver.order_reviews')
      AND type = 'PK'
)
BEGIN
    ALTER TABLE silver.order_reviews
    DROP CONSTRAINT PK_silver_order_reviews;
END;

    -- Full refresh: remove the previous Silver contents.
    DELETE FROM silver.order_reviews;

    -- Convert, validate and deduplicate the Bronze records.
    ;WITH ParsedReviews AS
    (
        SELECT
            review_id,
            order_id,
            TRY_CONVERT(INT, review_score) AS review_score,
            review_comment_title,
            review_comment_message,
            TRY_CONVERT(DATETIME2, review_creation_date, 101)
                AS review_creation_date,
            TRY_CONVERT(DATETIME2, review_answer_timestamp, 101)
                AS review_answer_timestamp,
            dwh_load_ts
        FROM bronze.olist_order_reviews
    ),
    RankedReviews AS
    (
        SELECT
            *,
            ROW_NUMBER() OVER
            (
                PARTITION BY review_id
                ORDER BY review_answer_timestamp DESC, order_id DESC
            ) AS rn
        FROM ParsedReviews
        WHERE review_id IS NOT NULL
          AND LTRIM(RTRIM(review_id)) <> ''
          AND TRY_CONVERT(INT, review_score) BETWEEN 1 AND 5
          AND review_creation_date IS NOT NULL
          AND review_answer_timestamp IS NOT NULL
    )
    INSERT INTO silver.order_reviews
    (
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        dwh_load_ts
    )
    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        dwh_load_ts
    FROM RankedReviews
    WHERE rn = 1;

    -- Enforce one row per review_id.
    ALTER TABLE silver.order_reviews
    ADD CONSTRAINT PK_silver_order_reviews
        PRIMARY KEY (review_id);

    COMMIT TRANSACTION;

    PRINT 'Silver order reviews refreshed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO
