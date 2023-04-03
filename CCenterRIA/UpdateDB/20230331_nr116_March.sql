SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 116

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	----------------------------------------------------- Begin B Dunzz -----------------------------------------------------------------
	set @process = 'KR051000 Modificacion tabla ccMenus'
	set @sql = '
		insert into ccMenuUser (id_User, id_Menu, [type]) values (1, 3230, 3);

		update ccMenus 
		set release = ''3f2db252ad1e8747e879159ed8498ccf30092c85618c7a5edde85033f5b8cfac''
		where menu_id = 3230;

		update ccMenus 
		set type = 3
		where menu_id = 3230;
	'
	EXEC(@sql)
	----------------------------------------------------- END B Dunzz -----------------------------------------------------------------


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
