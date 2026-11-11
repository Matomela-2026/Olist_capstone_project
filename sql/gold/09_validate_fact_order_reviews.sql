-- Validate review fact table grain, scores and comments

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(DISTINCT CONCAT(review_id, '|', order_id))
        AS distinct_review_order_pairs,
    AVG(CAST(review_score AS DECIMAL(10,2)))
        AS average_review_score,
    SUM(CASE WHEN review_score NOT BETWEEN 1 AND 5
        THEN 1 ELSE 0 END) AS invalid_scores,
    SUM(CASE WHEN review_comment_title IS NULL
        THEN 1 ELSE 0 END) AS missing_titles,
    SUM(CASE WHEN review_comment_message IS NULL
        THEN 1 ELSE 0 END) AS missing_comments
FROM gold.fact_order_reviews;


-- Validate date dimension relationships

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN d1.date_key IS NULL
        THEN 1 ELSE 0 END) AS invalid_review_dates,
    SUM(CASE WHEN d2.date_key IS NULL
        THEN 1 ELSE 0 END) AS invalid_answer_dates
FROM gold.fact_order_reviews f
LEFT JOIN gold.dim_date d1
    ON f.review_date_key = d1.date_key
LEFT JOIN gold.dim_date d2
    ON f.review_answer_date_key = d2.date_key;