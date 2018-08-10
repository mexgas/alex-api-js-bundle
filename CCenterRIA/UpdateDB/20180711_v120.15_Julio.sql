/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
		
Date: 2018/05/15
Description:

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

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 15
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 13
	begin
		begin tran
		begin try

		set @process = 'CW-1974 -- Columna cal_tMsg en ccocallsout'
		set @Sql= 'if not exists (select * from sys.columns where name = N''cal_tMsg'' and Object_ID = Object_ID(N''ccocallsout''))
			begin
				alter table ccocallsout ADD cal_tMsg smallint null
			end'
		EXEC(@Sql)

		set @process = 'CW-1974 -- SP ccsp_DLRUpdateMachineTime'
		set @Sql= 'ALTER  PROCEDURE [dbo].[ccsp_DLRUpdateMachineTime]
			@CallID as int,
			@tMsg smallint = 0
			AS
			/*
			SP para guardar el tiempo que duró reproduciendo el mensaje
			*/
			update ccocallsout set cal_tMsg = @tMsg where cal_id = @CallID'
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
