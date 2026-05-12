USE [CCenterRIA]

ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN ReplyGreeting NVARCHAR(1000);
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN ReplyFarewell NVARCHAR(1000);
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN ReplySystemFailure NVARCHAR(1000);
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN ReplyNoUnderstanding NVARCHAR(1000);

ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN rules VARCHAR(6000);
ALTER TABLE dbo.ccVirtualAgent ALTER COLUMN instructions VARCHAR(MAX);