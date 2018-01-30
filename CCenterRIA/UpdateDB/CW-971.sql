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
set @versionfix = 113
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version -- and  @actualVersionFix in (@versionfix-1,@versionfix)
	begin
		begin tran
		begin try


		set @process = 'CW-971 -- ALTER SP ccspAgent_GetLastCalls'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id int AS
set nocount on

select * from

(select top 10 cal_id as id, ''IN'' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_ani as Telefono, descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, 
convert(varchar(14), dateadd(second, cal_tDialog-cal_tMoh,0), 108) Duracion,
'''' as CallBack, cal_key, c.inbound_id as IDCampEsp
from ccCallsIn c with(nolock index(IX_ccCallsIn_4)) 
inner join ccInbound i on c.inbound_id = i.inbound_id
left join ccTipoCalif cal on c.calif_id = cal.calif_id
where user_id = @user_id
and cal_inicio > dateadd(hh, -3, getdate())
order by cal_id desc) a

Union

select * from
(select top 10 cal_id as id, ''OUT'' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_telefono as Telefono,cam_descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, 
convert(varchar(14), dateadd(second, cal_tDialog-cal_tMoh,0), 108) Duracion,
convert(varchar(16), cal_fcallback, 121) as CallBack, cal_key, c.cam_id as IDCampEsp
from ccoCallsOut c with(nolock index(IX_ccoCallsOut_9)) 
inner join ccCamps o on c.cam_id = o.cam_id
left join ccTipoCalifOut cal on c.calif_id = cal.calif_id
where user_id = @user_id
and cal_inicio > dateadd(hh, -3, getdate())
order by cal_id desc) b

order by hora desc

set nocount off
	'
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