/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Vic Gonzalez
		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.34

Se agrega la tarea
CW-SETTNGS

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 35

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 34
BEGIN
	BEGIN TRAN
	BEGIN TRY
		
			EXEC (@Sql)
		SET @process = 'CW-2805 Drop SP ccsp_GalateaAdminSettings'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSettings'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminSettings;
    end'
		EXEC (@Sql)


		SET @process = 'CW-2805 Galatea Settings'
		SET @Sql = '	CREATE PROCEDURE ccsp_GalateaAdminSettings
AS
BEGIN
	CREATE TABLE #Settings (setting_id tinyint , valor varchar(300), ip_host tinyint)

	INSERT INTO #Settings 
	EXEC  ccsp_RIAADMLoadSettings @ip_admin =''''

	INSERT INTO #Settings (setting_id,valor) 
	SELECT setting_id, valor 
	FROM ccSettings
	WHERE setting_id in(160, 199, 53)
 
	SELECT distinct setting_id, valor from #Settings ORDER BY setting_id 

	DROP TABLE #Settings;
END
'
			
		EXEC (@Sql)

				

		-- *********************** END  121.03-3_201900307 *********************** ---


				/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix
		
		
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
