/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.38

Se agrega la tarea

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
SET @versionfix = 38
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 37
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-2708 -- Add New Setting ccSettings 216'
		set @sql = 'IF NOT EXISTS
(
	SELECT *
	FROM ccSettings
	WHERE setting_id = 216
)
BEGIN
	INSERT INTO ccSettings( setting_id, valor, descripcion, STATUS, Tipo, detalle, description, bLoadSettings, validate )
	VALUES( 216, ''1|24|smtp.ionos.com|notifications@centernext.net|6zJLvMd2|587|0|0'', ''Notificar vencimiento de licencia vía correo electrónico '', 1,
	''X'', ''Numero dias envio del correo #DaysBefore|#HourSendMail|STMPServer|User|Password|Port|SSL|TLS'',
	''Notify license expiration via email L'', 0,
	''^(\d+)\|(\d+)\|(\w+\.?)+\|[_a-z0-9-]+(.[_a-z0-9-]+)*@[a-z0-9-]+(.[a-z0-9-]+)*(.[a-z]{2,4})\|.*\|\d+\|[0-1]$'' );
END;'
		exec (@sql)

		set @process = 'CW-2708 -- Create table ccRiaCat_AccountMailNotifyExpirationLicense'
		set @sql = 'if not exists(select * from sys.tables where name=''ccRiaCat_AccountMailNotifyExpirationLicense'') begin
create table ccRiaCat_AccountMailNotifyExpirationLicense(
Mail varchar(255) Not NUll,
Name varchar(255) Not null default('''')
)
end'
		exec (@sql)

		set @process = 'CW-2708 -- Create Index ccRiaCat_AccountMailNotifyExpirationLicense.IX_ccRiaCat_AccountMailNotifyExpirationLicense_I'
		set @sql = 'IF NOT EXISTS (SELECT name from sys.indexes  
           WHERE name = N''IX_ccRiaCat_AccountMailNotifyExpirationLicense_I'')   begin   
   CREATE UNIQUE INDEX IX_ccRiaCat_AccountMailNotifyExpirationLicense_I ON ccRiaCat_AccountMailNotifyExpirationLicense (mail);   
end'
		exec (@sql)

		set @process = 'CW-2708 -- Add Mail Send Notify license expiration'
		set @sql = 'if not exists(select * from ccRiaCat_AccountMailNotifyExpirationLicense where Mail=''ccRiaCat_AccountMailNotifyExpirationLicense'')
insert into ccRiaCat_AccountMailNotifyExpirationLicense (Mail) values(''instalaciones@nuxiba.com'')
'
		exec (@sql)

		
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
