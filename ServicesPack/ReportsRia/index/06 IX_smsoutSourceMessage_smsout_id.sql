USE [CCReportsRIA]
GO


IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_smsoutSourceMessage_smsout_id'
    AND object_id = OBJECT_ID('smsoutSourceMessage')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_smsoutSourceMessage_smsout_id
    ON dbo.smsoutSourceMessage (smsout_id)
    INCLUDE ([message]);
END


