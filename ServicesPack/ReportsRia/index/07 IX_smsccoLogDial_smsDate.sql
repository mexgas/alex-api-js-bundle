USE [CCReportsRIA]
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_smsccoLogDial_smsDate'
    AND object_id = OBJECT_ID('smsccoLogDial')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_smsccoLogDial_smsDate
    ON dbo.smsccoLogDial (smsDate)
    INCLUDE (smsout_id, cam_id, phone, [Message], statusSystemsId, Bill, logId, registryClient)
END
