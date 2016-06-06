/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2016/06/08
Description:

Se agrega permiso ccuser de sysadmin para utilizar el garbage collector
se agrega sp  PROCEDURE [dbo].[ccsp_ResetGarbageCollector]


Database: CCenterRia
Required version: 119.03

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
set @versionfix = 4
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and @actualVersionFix = @versionfix-1
	begin
		begin tran
		begin try

		set @process = 'Add Role sysadmin -- ccUser'
		set @Sql= 'EXEC master..sp_addsrvrolemember @loginame = N''ccUser'', @rolename = N''sysadmin'''
		EXEC(@Sql)

		set @process = 'Insert messageStatus file not exists'
		set @sql='if not exists(select * from messageStatus where name=''Other'') insert into messageStatus(name,description,isFinished) values(''Other'',''File not exists'',0)'
		EXEC(@sql)

		set @process = 'drop PROCEDURE -------- ccsp_ResetGarbageCollector'
		set @Sql= 'if exists (select * from sys.procedures where name = N''ccsp_ResetGarbageCollector'') drop procedure ccsp_ResetGarbageCollector'
		EXEC(@Sql)

		set @process = 'create PROCEDURE [dbo].[ccsp_ResetGarbageCollector]'
		set @sql='create PROCEDURE [dbo].[ccsp_ResetGarbageCollector]
AS
BEGIN

CHECKPOINT
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
DBCC FREESYSTEMCACHE (''ALL'') WITH MARK_IN_USE_FOR_REMOVAL
DBCC FREESESSIONCACHE
END'
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
else if if @actualVersion = @version and @actualVersionFix = @versionfix begin
	begin tran
	begin try

		set @process = ''
		set @sql=''
		EXEC(@sql)

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