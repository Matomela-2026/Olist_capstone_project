
/*
    Project: Olist SSIS Medallion Data Warehouse
    Purpose: Start and finish ETL batch logging
    Layer: ETL
*/

CREATE OR ALTER PROCEDURE etl.usp_start_batch
    @process_name NVARCHAR(100),
    @batch_id UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @batch_id = NEWID();

    INSERT INTO etl.batch_log
    (
        batch_id,
        process_name,
        start_time,
        status
    )
    VALUES
    (
        @batch_id,
        @process_name,
        SYSUTCDATETIME(),
        'Running'
    );
END;
GO

CREATE OR ALTER PROCEDURE etl.usp_finish_batch
    @batch_id UNIQUEIDENTIFIER,
    @status NVARCHAR(20),
    @rows_processed INT = NULL,
    @error_message NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @status NOT IN ('Succeeded', 'Failed')
    BEGIN
        THROW 50001, 'Status must be Succeeded or Failed.', 1;
    END;

    UPDATE etl.batch_log
    SET
        end_time = SYSUTCDATETIME(),
        status = @status,
        rows_processed = @rows_processed,
        error_message = @error_message
    WHERE batch_id = @batch_id
      AND status = 'Running';

    IF @@ROWCOUNT = 0
    BEGIN
        THROW 50002, 'No running batch found for the supplied batch ID.', 1;
    END;
END;
GO
