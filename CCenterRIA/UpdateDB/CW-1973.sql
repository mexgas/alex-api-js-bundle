/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Karen Rodríguez López
Date: 2018/06/29
Description: CW-1973 Reporte de resumen de intervalo de tiempos totales



Database: CCenterRia
Required version: 119.119.124

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
set @versionfix = 135
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 134
	begin
		begin tran
		begin try
		
		set @process = 'CW-1973 -- VERSION 120.13 INSERT MktIntervalosTiemposTotales Menu INTO ccMenus'
		set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ccMenus] WHERE [menu_id] = 7170)
BEGIN
	INSERT INTO ccMenus(menu_id, menu_descrip, parent,Nivel,ordengral,type,HelpSWF,release) values(7170, ''Resumen de intervalo de tiempos totales|Total Time by Interval'', 7000, ''B'', 7, 3, '''',''bbbfef17301544a62f7e5f86ed1e5fc3efd0330aefc9e42dc3d453e3db64c7c6c419f65019600780b88f6e8037f79360485376eb5c083c88b13a6f469f539378'')
END'
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