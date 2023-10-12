SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 125

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	---------------------------------------BEGIN Hugo Longoria-----------------------------------------------------------
	SET @process = 'KR093000-rename column clientPhoneNumber into RepCallXfer'
	SET @sql = 'if exists (select * from sys.columns where name = N''clientPhoneNumber'' and Object_ID = Object_ID(N''RepCallXfer''))
		begin
			EXEC sp_rename ''RepCallXfer.clientPhoneNumber'', ''incomingNumber''; 
		end'
	EXEC(@sql)

	SET @process = 'KR093000-add column incomingNumber into RepCallXfer'
	SET @sql = 'if not exists (select * from sys.columns where name = N''incomingNumber'' and Object_ID = Object_ID(N''RepCallXfer''))
		begin
			alter table RepCallXfer add incomingNumber varchar(50) null 
		end'
	EXEC(@sql)
	---------------------------------------END Hugo Longoria-----------------------------------------------------------
	
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
