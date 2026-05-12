Use CCReportsRIA;
Go

IF NOT EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE Name = N'SystemApiId'
      AND Object_ID = Object_ID(N'RepOutSMSSentMessagesDetail')
)
BEGIN
    ALTER TABLE RepOutSMSSentMessagesDetail
    ADD SystemApiId VARCHAR(100) NULL;
END