IF not exists (SELECT 1 FROM SYS.columns WHERE name='ManualCallANIMode' 
AND OBJECT_ID = OBJECT_ID('ccCampsExtend'))
begin
	ALTER TABLE ccCampsExtend
	ADD ManualCallANIMode SMALLINT NULL;
end

IF exists (SELECT 1 FROM SYS.columns WHERE name='selectRotationManualDialing' 
AND OBJECT_ID = OBJECT_ID('ccCamps'))
begin
	ALTER TABLE ccCamps
	DROP COLUMN selectRotationManualDialing
end

IF NOT EXISTS(select 1 from relationTableColumnIdentifiers 
where tableName = 'cccampsextend' and colunName = 'ManualCallANIMode')
BEGIN
	INSERT INTO relationTableColumnIdentifiers(Identifiers, tableName, colunName)
	VALUES('OUT_MANUAL_CALL_ANI_MODE', 'ccCampsExtend', 'ManualCallANIMode')
END

IF NOT EXISTS(select 1 from ccGalateaIdentifiers 
where [Description] = 'OUT_MANUAL_CALL_ANI_MODE')
BEGIN
	INSERT INTO ccGalateaIdentifiers([Description], TagEs, TagEn, TagPt) VALUES
	('OUT_MANUAL_CALL_ANI_MODE', 'Asignación de ANI (llamada manual)', 'ANI assignment (manual call)', 'Atribuição de ANI (chamada manual)'),
	('OUT_MANUAL_CALL_ANI_MODE_SYSTEM', 'Por sistema', 'By system', 'Pelo sistema'),
	('OUT_MANUAL_CALL_ANI_MODE_AGENT', 'Por agente', 'By agent', 'Pelo agente'),
	('OUT_MANUAL_CALL_ANI_MODE_NONE', 'Ninguna', 'None', 'Nenhuma')
END	