SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 100

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'CW-4905 se agrega columna showFilter'
		SET @sql = '
			if not exists (select * from sys.columns where name = N''showFilter'' and Object_ID = Object_ID(N''ReportsFiltersMenus''))
    begin
        ALTER TABLE ReportsFiltersMenus ADD showFilter bit not null default''1''
    end
		'
		EXEC(@sql)


		SET @process = 'CW-4905 se agrega columna defaultValue'
		SET @sql = '
			if not exists (select * from sys.columns where name = N''defaultValue'' and Object_ID = Object_ID(N''ReportsFiltersMenus''))
    begin
        ALTER TABLE ReportsFiltersMenus ADD defaultValue varchar(8) not null default''''
    end
		'
		EXEC(@sql)


		SET @process = 'CW-4905 se modifica sp GetReportFiltersMenus'
		SET @sql = '	
ALTER PROCEDURE [dbo].[GetReportFiltersMenus]
	@id int
AS
BEGIN
	SELECT id,name,showFilter,defaultValue
	FROM dbo.FiltersMenus as f, dbo.ReportsFiltersMenus fm
	WHERE f.name = fm.filterMenuName
	AND fm.idReport = @id
	order by id
END
		'
		EXEC(@sql)


		SET @process = 'CW-4905 se modifican valores para reporte 8082'
		SET @sql = '
			update ReportsFiltersMenus set showFilter=''0'', defaultValue=''PE'' where idReport=8082 and filterMenuName=''groupBy''
		'
		EXEC(@sql)

		SET @process = 'CW-4905 se modifican valores para reporte 8064'
		SET @sql = '
			update ReportsFiltersMenus set showFilter=''0'', defaultValue=''PE'' where idReport=8064 and filterMenuName=''groupBy''
		'
		EXEC(@sql)
		

		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

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

