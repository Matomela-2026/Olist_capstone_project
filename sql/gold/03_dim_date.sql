
-- =====================================================
-- Project: Olist SSIS Medallion Data Warehouse
-- Layer: Gold
-- Script: 03_dim_date.sql
-- Purpose: Create and populate the date dimension
-- Range: 2016-09-01 to 2020-12-31
-- =====================================================

-- Create date dimension if it does not exist

IF OBJECT_ID(N'gold.dim_date', N'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_date
    (
        date_key INT NOT NULL,
        full_date DATE NOT NULL,
        calendar_year SMALLINT NOT NULL,
        calendar_quarter TINYINT NOT NULL,
        month_number TINYINT NOT NULL,
        month_name NVARCHAR(20) NOT NULL,
        day_of_month TINYINT NOT NULL,
        day_name NVARCHAR(20) NOT NULL,
        day_of_week TINYINT NOT NULL,
        is_weekend BIT NOT NULL,

        CONSTRAINT PK_gold_dim_date
            PRIMARY KEY (date_key),

        CONSTRAINT UQ_gold_dim_date_full_date
            UNIQUE (full_date)
    );
END;

-- Generate calendar dates and insert missing dates

;WITH calendar_dates AS
(
    SELECT CAST('2016-09-01' AS DATE) AS full_date

    UNION ALL

    SELECT DATEADD(DAY, 1, full_date)
    FROM calendar_dates
    WHERE full_date < '2020-12-31'
)
INSERT INTO gold.dim_date
(
    date_key,
    full_date,
    calendar_year,
    calendar_quarter,
    month_number,
    month_name,
    day_of_month,
    day_name,
    day_of_week,
    is_weekend
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), cd.full_date, 112)),
    cd.full_date,
    YEAR(cd.full_date),
    DATEPART(QUARTER, cd.full_date),
    MONTH(cd.full_date),
    DATENAME(MONTH, cd.full_date),
    DAY(cd.full_date),
    DATENAME(WEEKDAY, cd.full_date),
    ((DATEDIFF(DAY, '19000101', cd.full_date) % 7) + 1),
    CASE
        WHEN ((DATEDIFF(DAY, '19000101', cd.full_date) % 7) + 1)
             IN (6, 7)
        THEN 1 ELSE 0
    END
FROM calendar_dates cd
WHERE NOT EXISTS
(
    SELECT 1
    FROM gold.dim_date d
    WHERE d.full_date = cd.full_date
)
OPTION (MAXRECURSION 0);
