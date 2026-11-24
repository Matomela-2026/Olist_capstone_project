
USE olist_dwh;

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE silver.geolocation;

;WITH Cleaned AS
(
    SELECT
        RIGHT('00000' + LTRIM(RTRIM(geolocation_zip_code_prefix)), 5)
            AS geolocation_zip_code_prefix,

        CASE
            WHEN TRY_CONVERT(
                DECIMAL(10,7),
                TRY_CONVERT(FLOAT, geolocation_lat)
            ) BETWEEN -34 AND 6
            THEN TRY_CONVERT(
                DECIMAL(10,7),
                TRY_CONVERT(FLOAT, geolocation_lat)
            )
            ELSE NULL
        END AS geolocation_lat,

        CASE
            WHEN TRY_CONVERT(
                DECIMAL(10,7),
                TRY_CONVERT(FLOAT, geolocation_lng)
            ) BETWEEN -74 AND -32
            THEN TRY_CONVERT(
                DECIMAL(10,7),
                TRY_CONVERT(FLOAT, geolocation_lng)
            )
            ELSE NULL
        END AS geolocation_lng,

        LOWER(LTRIM(RTRIM(geolocation_city)))
            AS geolocation_city,

        CASE
            WHEN LTRIM(RTRIM(geolocation_state)) = 'rio de ja'
                THEN 'RJ'
            WHEN LTRIM(RTRIM(geolocation_state)) = 'bahia, br'
                THEN 'BA'
            ELSE UPPER(LTRIM(RTRIM(geolocation_state)))
        END AS geolocation_state,

        dwh_load_ts

    FROM bronze.olist_geolocation
),
CityFrequency AS
(
    SELECT
        geolocation_zip_code_prefix,
        geolocation_city,
        ROW_NUMBER() OVER
        (
            PARTITION BY geolocation_zip_code_prefix
            ORDER BY COUNT(*) DESC, geolocation_city ASC
        ) AS city_rank
    FROM Cleaned
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_city
),
StateFrequency AS
(
    SELECT
        geolocation_zip_code_prefix,
        geolocation_state,
        ROW_NUMBER() OVER
        (
            PARTITION BY geolocation_zip_code_prefix
            ORDER BY COUNT(*) DESC, geolocation_state ASC
        ) AS state_rank
    FROM Cleaned
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_state
),
CoordinateAverage AS
(
    SELECT
        geolocation_zip_code_prefix,
        AVG(geolocation_lat) AS geolocation_lat,
        AVG(geolocation_lng) AS geolocation_lng,
        MAX(dwh_load_ts) AS dwh_load_ts
    FROM Cleaned
    GROUP BY geolocation_zip_code_prefix
)
INSERT INTO silver.geolocation
(
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    dwh_load_ts
)
SELECT
    a.geolocation_zip_code_prefix,
    a.geolocation_lat,
    a.geolocation_lng,
    c.geolocation_city,
    s.geolocation_state,
    a.dwh_load_ts
FROM CoordinateAverage AS a
INNER JOIN CityFrequency AS c
    ON a.geolocation_zip_code_prefix = c.geolocation_zip_code_prefix
   AND c.city_rank = 1
INNER JOIN StateFrequency AS s
    ON a.geolocation_zip_code_prefix = s.geolocation_zip_code_prefix
   AND s.state_rank = 1;
    COMMIT TRANSACTION;

    PRINT 'Silver geolocation transformation completed successfully.';

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Silver geolocation transformation failed.';

    THROW;

END CATCH;