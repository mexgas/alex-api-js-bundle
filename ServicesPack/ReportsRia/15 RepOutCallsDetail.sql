use [CCReportsRIA]

IF NOT EXISTS (
    SELECT TOP 1 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('RepOutCallsDetail') 
      AND name = 'callStatusId'
)
BEGIN
    ALTER TABLE RepOutCallsDetail ADD callStatusId tinyint NULL;
END

