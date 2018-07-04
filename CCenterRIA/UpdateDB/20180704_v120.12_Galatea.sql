/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Armando Rodriguez
Date: 2017/04/26
Description:
	CW-1087 Setting de Cola mensajeria
	CW-1058 Programar notReady en la maquina de estados
	CW-1160 Cambio para guardar tiempo llamada ACD
	CW-1170 Guardar las lista de calificaciones
	CW-1439 Setting_ID 201 Cadena de conexion(ODBC) para consultar una BD externa en la llamada manual
	
Database: CCenterRia
Required version: 119.74

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 12
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix = @versionfix-1
	begin
		begin tran
		begin try	

	set @process = ''
    set @Sql= ''
    EXEC(@Sql)

	set @process = 'Setting_id 204 Configuration of Galatea integration service'
    set @Sql= 'IF not exists (SELECT * FROM ccSettings WHERE setting_id = 204)
	INSERT INTO ccSettings (setting_id, valor, descripcion,	Status,	Tipo,detalle,description,bLoadSettings,	validate)
	VALUES	(204, ''0.0.0.0|1337|1338'', ''Configuración de Galatea integration service'',	1,''x'',
			''IP|WebSocketServerPort|SocketServerPort'',
			'' Galatea Integration Service configuration'',	1, ''.*'')'
    EXEC(@Sql)

		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end