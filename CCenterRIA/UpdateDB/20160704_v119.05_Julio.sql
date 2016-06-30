/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2016/06/08
Description:

	ADD COlumna ccCampsNvosCB.dateUpdate actualizar las cubetas por campaña en lugar de global ya no se usa el Setting 21
	ALter SP ccsp_RIAGetCampsNvosCB -- Se modifica para actualizar por camapaña se valida que si pasa el valor solo actualiza
	ALTER SP ccsp_OUTGetNewJobs se manda ejecutar el SP ccsp_RIAGetCampsNvosCB para actualizar cubetas cada vez que el outbound pida datos
	ALTER SP -- ccsp_RIAOUTInsertNewJOBS_WT_Camp Se cambia para actualizar un top 2500 registros

Database: CCenterRia
Required version: 119.04

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

set @version = 119--**********actualizar a 120 sin fix
set @versionfix = 5
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

EXEC master..sp_addsrvrolemember @loginame = N'ccUser', @rolename = N'sysadmin'

if @actualVersion = @version and @actualVersionFix = @versionfix-1
	begin
		begin tran
		begin try


		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		-- exec ccsp_getVersion 'BD', @version
		-- exec ccsp_getVersion 'BDF', @versionFix

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