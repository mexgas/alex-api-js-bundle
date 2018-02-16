/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Alan Minor 
Date: 2017/21/12
Description:



Database: CCenterRia
Required version: 119.10.2

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
set @versionfix = 121
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

if  @actualVersion = @version and  @actualVersionFix >= 121
	begin
		begin tran
		begin try

		set @process = 'CW-1382  Version 119.114 Drop SP -- ccsp_AvrsSyncronization'
		set @Sql= 'if exists (select * from sys.procedures where name = ''ccsp_AvrsSyncronization'') DROP PROCEDURE [dbo].[ccsp_AvrsSyncronization]'
		EXEC(@sql)
	 

		set @process = 'CW-1382 Version 119.114 -- CREATE SP ccsp_AvrsSyncronization'
    	set @Sql= 'Create procedure [dbo].[ccsp_AvrsSyncronization]
@action smallint,
@maxRecordsToTransfer int=10,
@id int=0
AS
set nocount on
if @action=1 begin

	Select top(@maxRecordsToTransfer) call.cal_id, user_id, inbound_id, call.calif_id, cast(cal_extension as integer) as cal_extension,  
	cal_inicio, cal_ANI as phone, 
	cal_tDialog - case when trans.tAntesXfer is null then cal_tMoh			else cal_tMoh-trans.tAntesXfer end 	+ isnull( trans.tDespuesXfer ,0) as duration,
	cal_key, 0 as cal_manual, cal_puerto, dni_id , fvalida , cal_whohung,
	isnull(cast(califSub_id as smallint),0) as califSub_id,
	case when trans.tAntesXfer is null then cal_tMoh when cal_tMoh-trans.tAntesXfer<0 then 0  else cal_tMoh-trans.tAntesXfer end  as cal_tMoh ,
	dateadd(ss,cal_tDialog, cal_inicio) dateEnd,avrs.tipo+1 as callType,avrs.id as avrsId		
	from ccCallsIn as  call
	inner join ccAVRSTransfer avrs on call.cal_id=avrs.cal_id and avrs.tipo=0	
	left join 
		(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer from ccLogTransfers where tipo=1 group by cal_id,tipo 
			)trans 	
	on call.cal_id=trans.cal_id 
	union		
	Select top(@maxRecordsToTransfer) call.cal_id as CallId, user_id as UserId, cam_id as camAcdId, cast(call.calif_id as smallint) as califId, cast(cal_extension as integer) as extension,  
	cal_inicio, cal_telefono, 
	cal_tDialog - case when trans.tAntesXfer is null then cal_tMoh			else cal_tMoh-trans.tAntesXfer end 	+ isnull( trans.tDespuesXfer ,0) as duration,
	cal_key, cal_manual, cal_puerto,  0 as dni_id , fvalida , cal_whohung,
	isnull(cast(califSub_id as smallint),0) as califSub_id,
	case when trans.tAntesXfer is null then cal_tMoh when cal_tMoh-trans.tAntesXfer<0 then 0  else cal_tMoh-trans.tAntesXfer end  as cal_tMoh ,
	dateadd(ss,cal_tDialog, cal_inicio) dateEnd,avrs.tipo+1 as callType,avrs.id as avrsId				
	from ccoCallsOut  as call	
	inner join ccAVRSTransfer avrs on call.cal_id=avrs.cal_id and avrs.tipo=1	
	left join 
		(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer from ccLogTransfers where tipo=2 group by cal_id,tipo 
			)trans 	
	on call.cal_id=trans.cal_id 
end 
else if @action=2 begin
	delete from ccAVRSTransfer where id = @id
end'
    	EXEC(@Sql)


		set @process = 'CW-1382 Version 119.114 -- CREATE SP ccsp_AvrsSyncronization'
    	set @Sql= ''
    	EXEC(@Sql)

		
	/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		--exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
