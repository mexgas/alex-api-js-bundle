/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Vic Gonzalez

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.35

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

IF @actualVersion = @version AND @actualVersionFix >= 35
BEGIN
	BEGIN TRAN
	BEGIN TRY
		

		-- *********************** START 121.03-6_20190506 *********************** ---

		
		SET @process = 'CW-2556 ST_2018_12_35 some area codes are missing (USA)'
		SET @Sql = 'insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
 select id_country, area, location, tz_standard, tz_daylight, call_record from (
	values (4,327,''AR'',64,32,null), 
  (4,986,''ID'',128,64,null),(4,930,''IN'',32,16,null),(4,332,''NY'',32,16,null),
  (4,680,''NY'',32,16,null),(4,838,''NY'',32,16,null),(4,929,''NY'',32,16,null),(4,934,''NY'',32,16,null),
  (4,445,''PA'',32,16,null)
 ) as timezone(id_country, area, location, tz_standard, tz_daylight, call_record) where area not in (select area from ccTimeZoneArea where id_country = 4)'
		EXEC (@Sql)
	
		
	-- *********************** END 	121.03-6_20190506 *********************** ---
		
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
