/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Trejo
		Karen Rodríguez
Date: 2018/05/15
Description:

CW-1730
CW-1825 Reporte MKT Intervalos
CW-1937 MKT Mensual


Database: CCenterRia
Required version: 120.12

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
set @versionfix = 13
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 12
	begin
		begin tran
		begin try

        set @process = 'CW-1730-- Insert in ccMenus'
        set @Sql= 'delete from ccMenus where menu_id=7070
		delete from ccMenus where menu_id=7120
insert into ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
values(7120,''MKT Agentes|MKT Agents'',7000,''B'',7,3,'''',''b4f4b155c759f8c7386fb027acee7f985b999b30ef1b03df4b7a0a752a0f9ba1'')'
        EXEC(@Sql)

		set @process = 'CW-1825 -- VERSION 119.122 INSERT MktIntervalos Menu INTO ccMenus'
		set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ccMenus] WHERE [menu_id] = 7140)
BEGIN
	INSERT INTO ccMenus(menu_id, menu_descrip, parent,Nivel,ordengral,type,HelpSWF,release) values(7140, ''MKT Intervalos|MKT Intervalos'', 7000, ''B'', 7, 3, '''',''ccb46d451ea992fe4a7dc5bd92507ba08baf14ab7f0c3aa900516ba4033f4f38'')
END'
		EXEC(@Sql)

		set @process = 'CW-1937 -- VERSION 119.135 INSERT MktMensual Menu INTO ccMenus'
		set @Sql= 'IF NOT EXISTS (SELECT * FROM [dbo].[ccMenus] WHERE [menu_id] = 7150)
BEGIN
	INSERT INTO ccMenus(menu_id, menu_descrip, parent,Nivel,ordengral,type,HelpSWF,release) values(7150, ''MKT Mensual|MKT Mensual'', 7000, ''B'', 7, 3, '''',''b5a6d57ea092a90659f714f4c26489201c744e4e7c7d8a2871b6a3a28481040e'')
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
