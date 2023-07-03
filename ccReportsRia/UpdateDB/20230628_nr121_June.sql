SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 121

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY


	set @process = 'Delete from ccSMSResult'
	set @Sql= 'if exists (select * from sys.tables where name = N''ccSMSResult'')
    begin
        delete from ccSMSResult
    end'
	EXEC(@Sql)	

	set @process = 'Add information to ccSSMSResult'
	set @Sql= '
	if exists (select * from sys.tables where name = N''ccSMSResult'')
    begin
		insert into ccSMSResult (resultId,description,translatedDesc) values (0,''sent'',''systemTranslated_sent'')
		insert into ccSMSResult (resultId,description,translatedDesc) values (1,''delivered'',''systemTranslated_delivered'')
		insert into ccSMSResult (resultId,description,translatedDesc) values (2,''notDelivered'',''systemTranslated_notDelivered'')
		insert into ccSMSResult (resultId,description,translatedDesc) values (3,''rejectedByrecipient'',''systemTranslated_rejectedR'')
		insert into ccSMSResult (resultId,description,translatedDesc) values (4,''rejectedByCarrier'',''systemTranslated_rejectedC'')
		insert into ccSMSResult (resultId,description,translatedDesc) values (5,''rejectedByBalance'',''systemTranslated_rejectedB'')
	end
	'
	EXEC(@Sql)


	SET @process = 'Drop SP ccspRepOutSMSAnswDetailByCamp'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccspRepOutSMSAnswDetailByCamp'')
			BEGIN
				DROP PROCEDURE [dbo].[ccspRepOutSMSAnswDetailByCamp]
			END'
	EXEC(@sql)

	SET @process = 'New SP ccspRepOutSMSAnswDetailByCamp'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccspRepOutSMSAnswDetailByCamp] 
		@action as tinyint,
		@from as datetime = NULL,
		@to as datetime = NULL
		AS

		IF @from IS NULL
			SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

		IF @to IS NULL
			SELECT @to = getdate()

		IF @action = 1
		BEGIN
			--Borrar lo que esta para no repetir
			DELETE
			FROM RepOutSMSAnswDetailByCamp WITH (ROWLOCK)
			WHERE date >= @from AND date < @to

			INSERT INTO RepOutSMSAnswDetailByCamp
			SELECT smsDate date, cam.cam_id camId, cam_descripcion campaignName, message, phone senderNumber, cam.cam_id campaignId
			FROM smsccoLogDial smslog (nolock)
				LEFT JOIN cccamps cam on cam.cam_id=smslog.cam_id
				LEFT JOIN smsoutSourceMessage src on src.smsout_id=smslog.smsout_id
			WHERE smsDate >= @from AND smsDate < @to
			ORDER BY smsDate
		END
	'
	EXEC(@Sql)	

	SET @process = 'Drop SP ccspRepOutSMSSentMessagesDetail'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccspRepOutSMSSentMessagesDetail'')
			BEGIN
				DROP PROCEDURE [dbo].[ccspRepOutSMSSentMessagesDetail]
			END'
	EXEC(@sql)

	SET @process = 'New SP ccspRepOutSMSSentMessagesDetail'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccspRepOutSMSSentMessagesDetail] 
		@action as tinyint,
		@from as datetime = NULL,
		@to as datetime = NULL
		AS

		IF @from IS NULL
			SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

		IF @to IS NULL
			SELECT @to = getdate()

		IF @action = 1
		BEGIN
			--Borrar lo que esta para no repetir
			DELETE
			FROM RepOutSMSSentMessagesDetail WITH (ROWLOCK)
			WHERE date >= @from AND date < @to

			INSERT INTO RepOutSMSSentMessagesDetail
			SELECT smsout_id, cam_descripcion, phone, smsDate,res.translatedDesc, bill, logId, smslog.cam_id campaignId
			FROM smsccoLogDial smslog (nolock)
				LEFT JOIN cccamps cam on cam.cam_id=smslog.cam_id
				LEFT JOIN ccSMSResult res on res.resultId=smslog.statusSystemsId 
			WHERE smsDate >= @from AND smsDate < @to
			ORDER BY smsDate
		END
	'
	EXEC(@Sql)	
	
	SET @process = 'Add column campaignId to RepOutSMSSentMessagesDetail'
	SET @sql = 'IF NOT EXISTS(select * from sys.columns where name = N''campaignId'' and Object_ID = Object_ID(N''RepOutSMSSentMessagesDetail''))
			BEGIN
				ALTER TABLE RepOutSMSSentMessagesDetail ADD campaignId int NOT NULL
			END'
	EXEC(@sql)

	SET @process = 'Add column campaignId to RepOutSMSAnswDetailByCamp'
	SET @sql = 'IF NOT EXISTS(select * from sys.columns where name = N''campaignId'' and Object_ID = Object_ID(N''RepOutSMSAnswDetailByCamp''))
			BEGIN
				ALTER TABLE RepOutSMSAnswDetailByCamp ADD campaignId int NOT NULL
			END'
	EXEC(@sql)

	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
