/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/05/06
Description:

Database: CCenterRia
Required version: 122.19

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
SET @version = 122 --**********actualizar a 122 sin fix
SET @versionfix = 21
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 19
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-4303-Crear nuevo setting globar con id 222 para hunaku'
		set @sql = 'insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
 values(222,''1'',''Lugar donde hunaku guarda grabaciones'',1,''X'',''Lugar donde los hunakus guardan las grabaciones. Este setting afecta a todos los hunakus. 0=GUARDA EN LOCAL. 1=GUARDA EN REMOTO'',
 ''Place where hunaku keeps recordings'',0,''/^[0-1]$/'')'
		EXEC(@sql)

		set @process = 'CW-4303 drop sp para cambiar a grabacion local en hunaku'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccspHunaku_record_locally'')
	    begin
	        DROP PROCEDURE ccspHunaku_record_locally;
	    end'
		EXEC(@sql)

		set @process = 'CW-4303 agregar sp para cambiar a grabacion local en hunaku'
		set @sql = 'create procedure ccspHunaku_record_locally
as
update ccSettings set valor=0 where setting_id=222'
		EXEC(@sql)


		set @process = 'CW-4303 drop sp para cambiar a grabacion remota en hunaku'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccspHunaku_record_remotely'')
	    begin
	        DROP PROCEDURE ccspHunaku_record_remotely;
	    end'
		EXEC(@sql)

		set @process = 'CW-4303 agregar sp para cambiar a grabacion remota en hunaku'
		set @sql = 'create procedure ccspHunaku_record_remotely
as
update ccSettings set valor=1 where setting_id=222'
		EXEC(@sql)



		
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		-- exec ccsp_getVersion 'BD', @version
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
