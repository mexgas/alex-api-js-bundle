SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 128

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	-----------------------------------------------------BEGIN Rod Salazar -----------------------------------------------------------------

	set @process = 'KR096030 Modificar columna RepWhatsAppDetailConversationOut -> disposition'
	set @sql='
	if exists(select * from sys.columns where name = ''disposition'' and object_id = OBJECT_ID(''RepWhatsAppDetailConversationOut''))
	begin
		ALTER TABLE RepWhatsAppDetailConversationOut ALTER COLUMN disposition varchar(150)
	end
	'
	EXEC(@sql)

	set @process = 'KR096030 Modificar columna RepWhatsAppDetailConversationOut -> subDisposition'
	set @sql='
	if exists(select * from sys.columns where name = ''subDisposition'' and object_id = OBJECT_ID(''RepWhatsAppDetailConversationOut''))
	begin
		ALTER TABLE RepWhatsAppDetailConversationOut ALTER COLUMN subDisposition varchar(150)
	end
	'
	EXEC(@sql)

	
	-----------------------------------------------------END Rod Salazar -----------------------------------------------------------------

	
	
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
