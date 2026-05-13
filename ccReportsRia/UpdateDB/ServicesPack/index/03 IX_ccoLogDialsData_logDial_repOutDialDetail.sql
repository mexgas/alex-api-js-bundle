USE [CCReportsRIA]
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    WHERE i.name = 'IX_ccoLogDialsData_logDial_repOutDialDetail'
      AND i.object_id = OBJECT_ID('dbo.ccoLogDialsData')
)
BEGIN

    CREATE NONCLUSTERED INDEX IX_ccoLogDialsData_logDial_repOutDialDetail
    ON dbo.ccoLogDialsData
    (
        logDial_id
    )
    INCLUDE
    (
        Data1,
        Data2,
        Data3,
        Data4,
        Data5
    );
END
