/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Omar Mejia, 
Date: 2017/10/24
Description:
	*CW-950 Se agrega como resultado del SP el collation de la base CCenterRia para que pueda ser usado 
	en el AdminASP para hacer cast cuando se realize una carga de base de datos desde una BD con un collation diferente.


Database: CCenterRia
Required version: 119.09-3

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

set @version = 119--**********actualizar a 119 sin fix
set @versionfix = 94
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and (@actualVersionFix = @versionfix-1)
	begin
		begin tran
		begin try
		
		set @process = 'ALTER PROCedure [dbo].[ccsp_RIAServerIP] CW-950-DatabaseLoaderWithDifferentsAccents'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAServerIP]
					AS
					Select valor,DATABASEPROPERTYEX(''CCenterRia'', ''Collation'') AS DBCollation from ccSettings where setting_id = 67'
    	EXEC(@Sql)
		
    	set @process = ''
		set @Sql= ''
    	EXEC(@Sql)
		
    	
    	set @process = ''
		set @Sql= ''
    	EXEC(@Sql)

    	/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
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