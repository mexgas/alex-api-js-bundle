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
	set @Sql= 'delete from ccSMSResult'
	EXEC(@Sql)	

	set @process = 'Add information to ccSSMSResult'
	set @Sql= '
	insert into ccSMSResult (resultId,description,translatedDesc) values (0,''sent'',''systemTranslated_sent'')
	insert into ccSMSResult (resultId,description,translatedDesc) values (1,''delivered'',''systemTranslated_delivered'')
	insert into ccSMSResult (resultId,description,translatedDesc) values (2,''notDelivered'',''systemTranslated_notDelivered'')
	insert into ccSMSResult (resultId,description,translatedDesc) values (3,''rejectedByrecipient'',''systemTranslated_rejectedR'')
	insert into ccSMSResult (resultId,description,translatedDesc) values (4,''rejectedByCarrier'',''systemTranslated_rejectedC'')
	insert into ccSMSResult (resultId,description,translatedDesc) values (5,''rejectedByBalance'',''systemTranslated_rejectedB'')
	'
	EXEC(@Sql)	

	
	


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
