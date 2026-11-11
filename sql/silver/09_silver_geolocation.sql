INSERT INTO silver.geolocation
(
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    dwh_load_ts
)
SELECT DISTINCT
    RIGHT('00000' + LTRIM(RTRIM(geolocation_zip_code_prefix)), 5),

    CASE
        WHEN TRY_CONVERT(DECIMAL(10,7), geolocation_lat)
             BETWEEN -34 AND 6
        THEN TRY_CONVERT(DECIMAL(10,7), geolocation_lat)
        ELSE NULL
    END,

    CASE
        WHEN TRY_CONVERT(DECIMAL(10,7), geolocation_lng)
             BETWEEN -74 AND -34
        THEN TRY_CONVERT(DECIMAL(10,7), geolocation_lng)
        ELSE NULL
    END,

    LOWER(LTRIM(RTRIM(geolocation_city))),

    CASE
        WHEN LTRIM(RTRIM(geolocation_state)) = 'rio de ja'
            THEN 'RJ'
        WHEN LTRIM(RTRIM(geolocation_state)) = 'bahia, br'
            THEN 'BA'
        ELSE UPPER(LTRIM(RTRIM(geolocation_state)))
    END,

    dwh_load_ts

FROM bronze.olist_geolocation;