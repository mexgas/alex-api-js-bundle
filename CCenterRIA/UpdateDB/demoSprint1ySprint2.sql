/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio García
Date: 2025/06/23
Description: Demo/Sprint2
Database: CCenterRia
Required version: 127.2
IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @sql VARCHAR(max)
DECLARE @process VARCHAR(max)
------------------- BEGIN MAGV --------------------------------
/*DEV3-1182*/
SET @process = 'K070088 - Se realiza cambio de tags, para portugues ya que estaba mal la etiqueta para el historial de actividad'
SET @sql = '
IF EXISTS (
    SELECT 1 FROM dbo.ccGalateaIdentifiers
    WHERE Description = ''COMMON_NONE_O''
)
BEGIN
    UPDATE dbo.ccGalateaIdentifiers
	SET TagEs = ''Ninguna'', TagPt = ''Nenhuma''
	WHERE Description = ''COMMON_NONE_O''
END
'
EXEC(@sql)


/*K070254*/
-- Para ccoCallsOutDispositionIA
SET @process = 'K070254 - add column disposition_id in ccoCallsOutDispositionIA table to save CW dispositions'
SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = ''ccoCallsOutDispositionIA''
      AND COLUMN_NAME = ''disposition_id''
)
BEGIN
	ALTER TABLE ccoCallsOutDispositionIA ADD 
	disposition_id SMALLINT NULL
END;'

EXEC(@sql)

-- Para ccCallsInDispositionIA
SET @process = 'K070254 - add column disposition_id in ccCallsInDispositionIA table to save CW dispositions'
SET @sql = 'IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = ''ccCallsInDispositionIA''
      AND COLUMN_NAME = ''disposition_id''
)
BEGIN
	ALTER TABLE ccCallsInDispositionIA ADD 
	disposition_id SMALLINT NULL
END;'
EXEC(@sql)

SET @process = 'K070254 - delete store procedure [SaveDispositionsAI]'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''SaveDispositionsAI'')
		BEGIN
			DROP PROCEDURE SaveDispositionsAI
		END'
EXEC(@sql)

SET @process = 'K070254 - CREATE store procedure [SaveDispositionsAI]
1.- Se le agregó al sp el parametro @disposition_Id para recibir la calificación de CW
2.- Se modificaron las opciones 1 y 3, para agregarles el @disposition_Id y se pueda registrar '
SET @sql = 'CREATE PROCEDURE [dbo].[SaveDispositionsAI]
		@action smallint = null,
		@call_Id int = null,
		@Qualification varchar(max) = null,
		@result VARCHAR(MAX) = null,
		@Observations VARCHAR(MAX) = null,
		@Transcription VARCHAR(MAX) = null,
		@CamType bit = 0,
		@disposition_Id SMALLINT = null

		AS
		IF @action = 1  --Outbound
		BEGIN
			insert into ccoCallsOutDispositionIA (call_id, Qualification, result, Observations, disposition_id) values (@call_Id, @Qualification, @result, @Observations, @disposition_Id)
		END
		
		IF @action = 2 --Outbound
		BEGIN
			insert into ccoCallsOutTranscriptionIA (call_id, Transcription) values (@call_Id, @Transcription)
		END

		IF @action = 3 --Inbound
		BEGIN
			insert into ccCallsInDispositionIA (call_id, Qualification, result, Observations, disposition_id) values (@call_Id, @Qualification, @result, @Observations, @disposition_Id)
		END

		IF @action = 4 --Inbound
		BEGIN
			insert into ccCallsInTranscriptionIA (call_id, Transcription) values (@call_Id, @Transcription)
		END'
EXEC(@sql)
------------------- END MAGV  ----------------------------------------
------------------- Begin DMM  ----------------------------------------
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_AIToHumanTransfer'')
		BEGIN
			DROP PROCEDURE ccsp_AIToHumanTransfer
		END'
EXEC(@sql)

SET @process = ''
SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_AIToHumanTransfer]
	@action int = null,
	@camId int = null,
	@CallOutId int = null,
	@acdId int = null

AS
BEGIN 
	if @action = 1
	Begin
		select Inbound_id from ccInbound where cam_id = @camId
	end

	if @action = 2
	Begin
		select data_overflow_variables_quantum from ccoCallsOutSource where callout_id = @CallOutId
	end

	if @action = 3
	Begin
		select idForNonComprehension from ccInbound where Inbound_id = @acdId
	end

	if @action = 4
	Begin
		select idForSuccessfulTransaction from ccInbound where Inbound_id = @acdId
	end
END'
EXEC(@sql)
------------------- End DMM  ----------------------------------------