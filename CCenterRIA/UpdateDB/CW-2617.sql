/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 
		
Date: 2019/01/08
Description:

Database: CCenterRia
Required version: 121.31

Se agrega la tarea
CW-2031
CW-2576

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
SET @versionfix = 32

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 32
BEGIN
	BEGIN TRAN

	BEGIN TRY				

		SET @process = 'CW-2617 update  Area location DF --> CDMX '
		SET @Sql = 'update ccTimeZoneArea set location=''CDMX'' where id_country=1 and location=''DF'''
		EXEC (@Sql)

		SET @process = 'CW-2617 Add Area ccTimeZoneArea '
		SET @Sql = 'insert into ccTimeZoneArea(id_country,area,[location],tz_standard,tz_daylight) values(1,''221'',''PUE'',64,32)
insert into ccTimeZoneArea(id_country,area,[location],tz_standard,tz_daylight) values(1,''479'',''GTO'',64,32)
insert into ccTimeZoneArea(id_country,area,[location],tz_standard,tz_daylight) values(1,''56'',''CDMX'',64,32)
insert into ccTimeZoneArea(id_country,area,[location],tz_standard,tz_daylight) values(1,''663'',''BC'',256,128)
insert into ccTimeZoneArea(id_country,area,[location],tz_standard,tz_daylight) values(1,''729'',''MEX'',64,32)'
		EXEC (@Sql)

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
