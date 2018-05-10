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

		set @process = 'CW-1331  Version 119.131 -- Alter SP ccsp_EngineLogTransfers'
		set @Sql= 'ALTER procedure [dbo].[ccsp_EngineLogTransfers]
@action as tinyint,
@cal_id as integer,
@tipo as tinyint,
@modo as tinyint,
@destino as varchar(50),
@tantes integer = 0,
@tdespues integer = 0,
@pbxId tinyint =0,
@channel int =0
as
-- tipo: 1 inbound, 2 outbound
-- modo: 0 externa ciega, 1 agente, 2 acd, 3 confer, 4 externa supervisada, 5 desborde

declare @totalCall_Time integer
declare @callout_id int

if @action = 1 begin
    if @modo = 4 begin
        insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel) 
        values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, getdate(), @pbxId,@channel )
        if @tdespues > 0 begin
                select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tdespues
                update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
        end
    end
    else begin
        if not exists (select * from ccLogTransfers where cal_id = @cal_id and tipo = @tipo)
            insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel) 
            values ( @cal_id, @tipo, @modo, @destino, 0, @tantes, getdate() ,@pbxId,@channel )

        if @tipo = 2 begin
            if @modo = 5 begin
                select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
                update ccLogTransfers set tDespuesXfer = @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2), tAntesXfer = @tdespues + (select tAntesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2) where cal_id = @cal_id and tipo = 2
            end
        
            if @modo in (0,1,2) begin
                select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
                update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
            end
        end

        else begin
            if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
                select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
                select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
                update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
            end
        end
    end
   --Valida que no existe y que el tiempo minimo de la grabacion se mayor al establecido para que lo tome el detector de gritos
	if not exists(select * from ccAVRSTransfer where cal_id=@cal_id and tipo= @tipo-1) begin
		declare @tMinAVRS smallint,@cal_tDialog int
		set tMinAVRS=5
		select @tMinAVRS=valor from ccSettings where setting_id=65
		if @tipo=2 begin
			select @cal_tDialog=cal_tDialog from ccoCallsOut where cal_id=@cal_id
		end
		else begin
			select @cal_tDialog=cal_tDialog from ccCallsIn where cal_id=@cal_id
		end

		if @cal_tDialog >= @tMinAVRS begin
			insert into ccAVRSTransfer (cal_id,tipo) values(@cal_id,@tipo-1)
		end
	end
end

else if @action = 2 begin   
    if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
        select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
        update ccLogTransfers set tDespuesXfer = @tdespues + @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2) where cal_id = @cal_id and tipo = 2
        select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
        update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
    end
end

else if @action = 4 begin
    select @totalCall_Time = ISNULL((select sum(tincall) from IVRCallsIn where callout_id = @cal_id), 0) + ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0)
    update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
end'
		EXEC(@sql)

        set @process = 'CW-1741 Version 119.124 -- Alter SP ccspAgent_GetLastCalls'
        set @Sql= 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id int AS
set nocount on

declare @lastCallAgt table(
cal_id int not null,
tipo varchar(10) not null,
Hora varchar(10) not null,
Telefono varchar(55) not null,
EspCamp varchar(55) not null,
Calificacion varchar(60),
Duracion varchar(10) not null,
CallBack varchar(60),
cal_key varchar(20),
IDCampEsp int not null
)
insert into @lastCallAgt
select top 10 c.cal_id as id, ''IN'' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_ani as Telefono, descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, 
convert(varchar(14), dateadd(second, 
cal_tDialog - case when t.tAntesXfer is null then cal_tMoh when cal_tMoh-t.tAntesXfer >0 then cal_tMoh-t.tAntesXfer else 0 end
    +  case when stopRecording=0 then isnull( t.tDespuesXfer ,0) else 0 end
,0), 108) Duracion,
'''' as CallBack, cal_key, c.inbound_id as IDCampEsp
from ccCallsIn c with(nolock index(IX_ccCallsIn_4)) 
inner join ccInbound on ccInbound.Inbound_id=c.Inbound_id
left join ccTipoCalif cal on c.calif_id = cal.calif_id
left join 
(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer  from ccLogTransfers where tipo=1  group by cal_id,tipo ) as t  
 on c.cal_id=t.cal_id 
where user_id = @user_id and cal_inicio > dateadd(hh, -3, getdate())
order by c.cal_inicio desc


insert into @lastCallAgt
select top 10 c.cal_id as id, ''OUT'' as Tipo,convert(varchar(10), cal_inicio, 108) as Hora,cal_telefono as Telefono,cam_descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, 
 CONVERT(varchar(8), DATEADD(ss, 
    cal_tDialog - case when t.tAntesXfer is null then cal_tMoh when cal_tMoh-t.tAntesXfer >0 then cal_tMoh-t.tAntesXfer else 0 end
    +  case when stopRecording=0 then isnull( t.tDespuesXfer ,0) else 0 end
    , 0), 114)  as Duracion,
    isnull(convert(varchar(16), cal_fcallback, 121) ,'''') as CallBack, cal_key, c.cam_id as IDCampEsp  
from ccoCallsOut c
inner join ccCamps on ccCamps.cam_id=c.cam_id
left join ccTipoCalifOut cal on c.calif_id = cal.calif_id
left join  
(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer from ccLogTransfers where tipo=2 group by cal_id,tipo) as t  
on c.cal_id=t.cal_id 

where user_id = @user_id and cal_inicio > dateadd(hh, -3, getdate())
order by c.cal_inicio desc

select * from @lastCallAgt
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
    dateadd(ss,cal_tDialog, cal_inicio) dateEnd,avrs.tipo+1 as callType,avrs.id as avrsId
    from ccCallsIn as  call
    inner join ccInbound on ccInbound.Inbound_id=call.Inbound_id
    inner join ccAVRSTransfer avrs on call.cal_id=avrs.cal_id and avrs.tipo=0   
    left join 
        (select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer from ccLogTransfers where tipo=1 group by cal_id,tipo 
            )trans  
    on call.cal_id=trans.cal_id     
    union       
    Select top(@maxRecordsToTransfer) call.cal_id as CallId, user_id as UserId, call.cam_id as camAcdId, cast(call.calif_id as smallint) as califId, cast(cal_extension as integer) as extension,  
    cal_inicio, cal_telefono, 
    cal_tDialog - case when trans.tAntesXfer is null then cal_tMoh when cal_tMoh-trans.tAntesXfer >0 then cal_tMoh-trans.tAntesXfer else 0 end
    +  case when stopRecording=0 then isnull( trans.tDespuesXfer ,0) else 0 end as duration,
    cal_key, cal_manual, cal_puerto,  0 as dni_id , fvalida , cal_whohung,
    isnull(cast(califSub_id as smallint),0) as califSub_id,
    case when trans.tAntesXfer is null then cal_tMoh when cal_tMoh-trans.tAntesXfer<0 then 0  else cal_tMoh-trans.tAntesXfer end  as cal_tMoh ,
    dateadd(ss,cal_tDialog, cal_inicio) dateEnd,avrs.tipo+1 as callType,avrs.id as avrsId
    from ccoCallsOut  as call   
    inner join ccCamps on ccCamps.cam_id=call.cam_id
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
    cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end,
    totalCall_Time=case when totalCall_Time is null then @cal_tDialog else totalCall_Time end 
    Where cal_id=@IDCall

    -- calcula el costo de la llamada
    exec ccsp_CstoCalculaCosto @IDCall

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

        set @process = 'CW-1652 Version 119.133 -- Remove conflict Replication'
        set @Sql= 'SELECT s.conflict_table, c.rowguid, c.origin_datasource
      INTO #temp_conflicts
      FROM dbo.MSmerge_conflicts_info c
      JOIN sysmergearticles s
      ON c.tablenick = s.nickname
 
--Setup local variables
DECLARE @conflict_table nvarchar(255)
DECLARE @row uniqueidentifier
DECLARE @origin_datasource nvarchar(255)
 
--Step through conflicts and purge by RowGuid
DECLARE conflict_cursor CURSOR FOR
   SELECT conflict_table, rowguid, origin_datasource
   FROM #temp_conflicts
OPEN conflict_cursor;
FETCH NEXT FROM conflict_cursor INTO @conflict_table, @row, @origin_datasource;
WHILE @@FETCH_STATUS = 0
BEGIN
 
      --Purge conflict as "resolved"
    EXEC sp_deletemergeconflictrow
      @conflict_table = @conflict_table,        -- conflict table name from sysmergearticles
      @rowguid = @row,                                      -- row identifier from msmerge_conflicts_info
      @origin_datasource = @origin_datasource   -- origin of the conflict from msmerge_conflicts_info
  
   --Retrieve next conflict to purge
   FETCH NEXT FROM conflict_cursor
   INTO @conflict_table, @row, @origin_datasource;
END
 
CLOSE conflict_cursor;
DEALLOCATE conflict_cursor;
DROP table #temp_conflicts'
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
