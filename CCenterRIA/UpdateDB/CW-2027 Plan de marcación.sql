/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

 
/*
Author: 
		
Date: 2018/08/21
Description:

Release  120.24_20180906

Database: CCenterRia
Required version: 120.14

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

set @version = 120
set @versionfix = 24


/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 22
	begin
		begin tran
		begin try

		
		set @process = 'CW-2027 Plan de marcación agregar a cstoTipoLlamada'
		set @Sql= 'if not exists(select * from cstoTipoLlamada where country_id=1 and tipoLlamada_id=12)
		insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,prefijo,longitud)
		values (1,12,''Local'',''%'',''10'')'
		EXEC(@Sql)

		set @process = 'CW-2027 Plan de marcación ALTER function Completa'
		set @Sql= ''
		EXEC(@Sql)


		set @process = 'CW-2027 Plan de marcación ALTER function fnGetTipoLlamada'
		set @Sql= ''
		EXEC(@Sql)

		set @process = 'CW-2027 Plan de marcación alter function verifica2'
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
