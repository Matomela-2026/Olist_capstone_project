/*
    Project: Olist SSIS Medallion Data Warehouse
    Purpose: Create ETL batch logging table
    Layer: ETL
*/

IF OBJECT_ID('etl.batch_log', 'U') IS NULL
BEGIN
    CREATE TABLE etl.batch_log
    (
        batch_id UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT PK_batch_log PRIMARY KEY,

        process_name NVARCHAR(100) NOT NULL,

        start_time DATETIME2 NOT NULL,

        end_time DATETIME2 NULL,

        status NVARCHAR(20) NOT NULL,

        rows_processed INT NULL,

        error_message NVARCHAR(MAX) NULL
    );
END;