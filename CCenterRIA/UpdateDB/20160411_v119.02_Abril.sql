/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Perez
Date: 2016/04/11
Description:



Database: CCenterRia
Required version: 119.01

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
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 118 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 118 sin fix
set @versionfix = 2
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and actualVersionFix = versionfix-1
	begin
		begin tran
		begin try

		set @process = 'INSERT -------- ccMenus'
		set @sql ='if not exists(select * from ccmenus where type=3 and menu_id in(4220, 4230, 4240)) begin
						insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release ) values (4220, ''Reporte de teléfonos por estado de la república|Telephone report ordered by republic states'', 4000, ''B'', 4, 3, '''', ''60b188045ce43b6a1d77f7a81f67767fc90fbef71d57e4498d362c5c67a3c097d076f2f127f0f7af01beda4ac36008993c52871865dfbcc8d37183f0a429089f59ae97a60b9d269449063e6d38f93222a414d69d2a3fb7b721155619d8e6b4e2'')
						insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release ) values (4230, ''Reporte de Número de Teléfonos por Registro por Lista|Telephone Report per Registry List'',  4000, ''B'', 4, 3, '''',''074a6cc91623e51a5020bb702fad033d304b666112d87ff90249fb8676ec86395611c16cf4e162ebabf8555caeea9365241fede8508032e858587c216da52aa9fea8e00d5e2f12006bb1564615249179bb0886e83a3aa729313cdd7fcd79cf35'')
						insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release ) values (4240, ''Reporte de resultados de marcación|Dialing Result Report'', 4000, ''B'', 4, 3, '''', ''9cf7679f1b10838b63e4eae2368159813ae5d3eecaf4bccecfb21a247080897dc3e3d80988c85c0931f5a2fe77da619d446f04bcc6ff01e8247b5531a00ded6b'')
				   end'
		EXEC(@sql)

		set @process = ''
		set @sql=''
		EXEC(@sql)


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
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ''', version to release: ''' + cast(@version as varchar(5))
	end

set nocount off