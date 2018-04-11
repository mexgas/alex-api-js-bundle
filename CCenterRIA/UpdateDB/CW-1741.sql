/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Alan Minor
Date: 2018/04/10
Description:



Database: CCenterRia
Required version: 119.119.131

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
set @versionfix = 132
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version --and  @actualVersionFix >= 132
	begin
		begin tran
		begin try

		set @process = 'CW-1741 Version 119.124 -- Alter SP ccspAgent_GetLastCalls'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id int AS
set nocount on

select top 10 c.cal_id as id, ''IN'' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_ani as Telefono, descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, 
convert(varchar(14), dateadd(second, 
cal_tDialog - case when t.tAntesXfer is null then cal_tMoh when cal_tMoh-t.tAntesXfer >0 then cal_tMoh-t.tAntesXfer else 0 end
    +  case when stopRecording=0 then isnull( t.tDespuesXfer ,0) else 0 end
,0), 108) Duracion,
'''' as CallBack, cal_key, c.inbound_id as IDCampEsp,
i.prefijo
from ccCallsIn c with(nolock index(IX_ccCallsIn_4)) 
inner join ccInbound i on c.inbound_id = i.inbound_id
left join ccTipoCalif cal on c.calif_id = cal.calif_id
left join 
(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer  from ccLogTransfers where tipo=1  group by cal_id,tipo ) as t  
 on c.cal_id=t.cal_id 

where user_id = @user_id
and cal_inicio > dateadd(hh, -3, getdate())


Union

select top 10 c.cal_id as id, ''OUT'' as Tipo,convert(varchar(10), cal_inicio, 108) as Hora,cal_telefono as Telefono,cam_descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, 
 CONVERT(varchar(8), DATEADD(ss, 
    cal_tDialog - case when t.tAntesXfer is null then cal_tMoh when cal_tMoh-t.tAntesXfer >0 then cal_tMoh-t.tAntesXfer else 0 end
    +  case when stopRecording=0 then isnull( t.tDespuesXfer ,0) else 0 end
    , 0), 114)  as Duracion,
    isnull(convert(varchar(16), cal_fcallback, 121) ,'''') as CallBack, cal_key, c.cam_id as IDCampEsp
    ,o.prefijo
from ccoCallsOut c
inner join ccCamps o on c.cam_id = o.cam_id
left join ccTipoCalifOut cal on c.calif_id = cal.calif_id
left join  
(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer from ccLogTransfers where tipo=2 group by cal_id,tipo) as t  
on c.cal_id=t.cal_id 

where user_id = @user_id
and cal_inicio > dateadd(hh, -3, getdate())

order by hora desc

set nocount off '
    	EXEC(@Sql)

        set @process = 'CW-1741 Version 119.124 -- Alter SP ccsp_AvrsSyncronization '
        set @Sql= 'ALTER procedure [dbo].[ccsp_AvrsSyncronization]
@action smallint,
@maxRecordsToTransfer int=10,
@id int=0
AS
set nocount on
if @action=1 begin

    Select top(@maxRecordsToTransfer) call.cal_id, user_id, call.Inbound_id, call.calif_id, cast(cal_extension as integer) as cal_extension,  
    cal_inicio, cal_ANI as phone, 
    cal_tDialog - case when trans.tAntesXfer is null then cal_tMoh when cal_tMoh-trans.tAntesXfer >0 then cal_tMoh-trans.tAntesXfer else 0 end
    +  case when stopRecording=0 then isnull( trans.tDespuesXfer ,0) else 0 end as duration,
    cal_key, 0 as cal_manual, cal_puerto, dni_id , fvalida , cal_whohung,
    isnull(cast(califSub_id as smallint),0) as califSub_id,
    case when trans.tAntesXfer is null then cal_tMoh when cal_tMoh-trans.tAntesXfer<0 then 0  else cal_tMoh-trans.tAntesXfer end  as cal_tMoh ,
    dateadd(ss,cal_tDialog, cal_inicio) dateEnd,avrs.tipo+1 as callType,avrs.id as avrsId, acds.prefijo 
    from ccCallsIn as  call
    inner join ccAVRSTransfer avrs on call.cal_id=avrs.cal_id and avrs.tipo=0   
    left join 
        (select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer from ccLogTransfers where tipo=1 group by cal_id,tipo 
            )trans  
    on call.cal_id=trans.cal_id 
    left join ccInbound acds on call.Inbound_id = acds.Inbound_id
    union       
    Select top(@maxRecordsToTransfer) call.cal_id as CallId, user_id as UserId, call.cam_id as camAcdId, cast(call.calif_id as smallint) as califId, cast(cal_extension as integer) as extension,  
    cal_inicio, cal_telefono, 
    cal_tDialog - case when trans.tAntesXfer is null then cal_tMoh when cal_tMoh-trans.tAntesXfer >0 then cal_tMoh-trans.tAntesXfer else 0 end
    +  case when stopRecording=0 then isnull( trans.tDespuesXfer ,0) else 0 end as duration,
    cal_key, cal_manual, cal_puerto,  0 as dni_id , fvalida , cal_whohung,
    isnull(cast(califSub_id as smallint),0) as califSub_id,
    case when trans.tAntesXfer is null then cal_tMoh when cal_tMoh-trans.tAntesXfer<0 then 0  else cal_tMoh-trans.tAntesXfer end  as cal_tMoh ,
    dateadd(ss,cal_tDialog, cal_inicio) dateEnd,avrs.tipo+1 as callType,avrs.id as avrsId, camps.prefijo            
    from ccoCallsOut  as call   
    inner join ccAVRSTransfer avrs on call.cal_id=avrs.cal_id and avrs.tipo=1   
    left join 
        (select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer from ccLogTransfers where tipo=2 group by cal_id,tipo 
            )trans  
    on call.cal_id=trans.cal_id 
    left join ccCamps as camps on call.cam_id = camps.cam_id 
end 
else if @action=2 begin
    delete from ccAVRSTransfer where id = @id
end'
        EXEC(@Sql)

        set @process = 'CW-1741 Version 119.124 -- Alter SP ccsp_AgentUpdateCallTimes '
        set @Sql= 'ALTER procedure [dbo].[ccsp_AgentUpdateCallTimes]
@IDCall int,
@cal_tXfer smallint,
@cal_tDialog smallint,
@cal_tNotas smallint,
@TipoCall tinyint,
@cal_tRing smallint=0,
@mtmoh smallint = 0,
@isChatCall bit = 0,
@isErroManualCall bit =0
AS
set nocount on
if @IDCall<=0 
    return(0)

declare @tMinAVRS smallint

if @TipoCall=1 --INBOUND
 begin
  Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
  cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
  cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
  Where cal_id= @IDCall

  --Actualizar tiempo total de llamada
  exec ccsp_EngineLogTransfers 2, @IDCall, @TipoCall, 2, null, @cal_tXfer, @cal_tDialog

  -- Elimina callback generado por abandono
  Declare @ANI_x varchar(19)
  select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

  DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
  DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
 end

if @TipoCall=2 --OUTBOUND
 begin
    Update ccoCallsOUT with(rowlock) Set cal_tXfer=case when @cal_tXfer > 0 then @cal_tXfer else cal_tXfer end, 
    cal_tDialog=case when @cal_tDialog > 0 then @cal_tDialog else cal_tDialog end, 
    @cal_tDialog=case when @cal_tDialog > 0 then @cal_tDialog else cal_tDialog end,
    cal_tNotas=case when @cal_tNotas > 0 then @cal_tNotas else cal_tNotas end, 
    cal_tMoh=case when @mtmoh > 0 then @mtmoh else cal_tMoh end,
    cal_tRing=case when @cal_tRing > 0 then @cal_tRing else cal_tRing end, 
    cal_manual=case when @isChatCall=1 then 3 else cal_manual end,
    cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end 
    Where cal_id=@IDCall

    -- calcula el costo de la llamada
    exec ccsp_CstoCalculaCosto @IDCall

    --Actualizar tiempo total de llamada
    exec ccsp_EngineLogTransfers 3, @IDCall, @TipoCall, 0, null, @cal_tXfer, @cal_tDialog
 end

select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

if @cal_tDialog >= @tMinAVRS begin
    if not exists(select * from ccAVRSTransfer where cal_id=@IDCall and tipo=@TipoCall - 1) begin
        insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
    end
        return(0)
 end

set nocount off'
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
