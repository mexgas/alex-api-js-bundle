use CCenterRIA;
Go

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N'IsCallTranscriptionEnabled' AND Object_ID = Object_ID(N'ccCampsExtend'))
BEGIN
	ALTER TABLE ccCampsExtend ADD IsCallTranscriptionEnabled BIT NULL
END

IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = 'IN_CALL_IA_CALL_TRANSCRIPTION' AND tableName = 'ccCampsExtend') BEGIN 
	INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
	VALUES ('IN_CALL_IA_CALL_TRANSCRIPTION','ccCampsExtend','IsCallTranscriptionEnabled')
END
