/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Armando Rodriguez
Date: 2017/04/26
Description:
	CW-2092 ccsp_GalateaCallbacksDays Returns days with callbacks made by an agent
Database: CCenterRia
Required version: 120.21

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
set @versionfix = 32
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix = @versionfix - 1
	begin
		begin tran
		begin try	

	set @process = 'CW 2409 Setting_id 204 Configuration of Galatea integration service'
    set @Sql= 'IF exists (SELECT * FROM ccSettings WHERE setting_id = 204)
	UPDATE ccSettings set valor = ''0.0.0.0|1337|1338|0|0'', Tipo = ''X'' detalle = ''IP|WebSocketServerPort|SocketServerPort|Autorun|IconActived'' where setting_id = 204'
    EXEC(@Sql)
	
	set @process = 'CW-2419 Deshardcodear conexión segura - funcion split'
    set @Sql= 'CREATE FUNCTION dbo.splitstring ( @stringToSplit VARCHAR(MAX) )
				RETURNS
				@returnList TABLE ([Name] [nvarchar] (500))
				AS
				BEGIN

				 DECLARE @name NVARCHAR(255)
				 DECLARE @pos INT

				 WHILE CHARINDEX(''|'', @stringToSplit) > 0
				 BEGIN
				  SELECT @pos  = CHARINDEX(''|'', @stringToSplit)  
				  SELECT @name = SUBSTRING(@stringToSplit, 1, @pos-1)

				  INSERT INTO @returnList 
				  SELECT @name

				  SELECT @stringToSplit = SUBSTRING(@stringToSplit, @pos+1, LEN(@stringToSplit)-@pos)
				 END

				 INSERT INTO @returnList
				 SELECT @stringToSplit

				 RETURN
				END'
    EXEC(@Sql)


	set @process = 'CW-2419 Deshardcodear conexión segura'
    set @Sql= ' DECLARE @setting VARCHAR(MAX)
				DECLARE @MQIP VARCHAR(MAX)
				DECLARE @pos INT
				IF EXISTS (SELECT *
						FROM   sys.objects
						WHERE  object_id = OBJECT_ID(N''[dbo].[splitstring]'')
								AND type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
				BEGIN
				SELECT @setting = valor FROM ccSettings
				WHERE setting_id = 199
				update ccSettings set valor = (SELECT CONCAT((SELECT TOP 1 * FROM splitstring(@setting)), ''|15674|15671|/|adminNuxiba|Nuxiba2017|5000'')),
				detalle = ''Configuracion rabbit IP|WSPort|WSSPort|VirtualHost|User|Password|Tiempo expiracion mensaje)'' where setting_id = 199
				END
				ELSE
				SELECT ''Function splitstring does not exists'''
    EXEC(@Sql)

	set @process = ''
    set @Sql= ''
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