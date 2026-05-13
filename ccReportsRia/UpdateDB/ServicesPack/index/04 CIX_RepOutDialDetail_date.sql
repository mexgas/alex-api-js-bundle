USE [CCReportsRIA]
GO


IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'CIX_RepOutDialDetail_date'
    AND object_id = OBJECT_ID('RepOutDialDetail')
)
BEGIN
    CREATE CLUSTERED INDEX CIX_RepOutDialDetail_date
    ON dbo.RepOutDialDetail([date]);
END
