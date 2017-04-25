/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2016/06/08
Description:

Se agrega permiso ccuser de sysadmin para utilizar el garbage collector
se agrega sp  PROCEDURE [dbo].[ccsp_ResetGarbageCollector]
------FIX------------------------------
	Alter SP ccsp_AgentGetCalificaciones --- Se quita las calificacion con reprogramacion si no tiene una campaña asosicada al ACD
	Alter SP ccsp_RIA_ABCACDGroups --- Se elimna las calificacion con reprogramacion al quitar asosicion de ACD con compaña
	Alter SP ccsp_RIAManageAreas --- Se valida que el si tiene asosciada la campaña a un ACD no elimina nada de la informacion relacionada en Gestion Areas


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

EXEC master..sp_addsrvrolemember @loginame = N'ccUser', @rolename = N'sysadmin'

if @actualVersion = @version and @actualVersionFix = @versionfix-1
	begin
		begin tran
		begin try

		set @process = 'Insert messageStatus file not exists'
		set @sql='if not exists(select * from messageStatus where name=''Other'') insert into messageStatus(name,description,isFinished) values(''Other'',''File not exists'',0)'
		EXEC(@sql)

		set @process = 'drop PROCEDURE -------- ccsp_ResetGarbageCollector'
		set @Sql= 'if exists (select * from sys.procedures where name = N''ccsp_ResetGarbageCollector'') drop procedure ccsp_ResetGarbageCollector'
		EXEC(@Sql)

    set @process = 'update menu -- Admin Encuestas'
    set @Sql= 'update ccMenus set menu_descrip = ''Encuestas|Surveys'', release = ''51d79747960460b9359fc88c227e8e0b14736dd3ca50c7b9604fd08b110deae7'' where menu_id = 86'
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

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory] -----------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory]
@action smallint,
@call_id int = 0,
@startDate varchar(30) = null,@endDate varchar(30) = null,
@state int = 0,
@multipleCall_id as varchar(500) = null,@multipleUser_id as varchar(500) = null,
@agentId int = 0,@camId int=0,@PageNumber int=1,@isCount bit=false

AS
declare @RowsPerPage int
set @RowsPerPage=500


-- INBOUND x cal_id
if @action = 1  begin
  select top 500
    cal_id as call_id,
    c.inbound_id,
    isnull(a.descripcion,'''') as acdGroup,
    cal_ani as phoneNumber,
    isnull(b.user_id,0) as [user_id],
    isnull(login,'''') as login,
    isnull(e.description,'''') as disposition,
    d.descripcion as call_status,
    cal_tDialog as call_tDialog,
    cal_inicio as call_date,
    cal_tNotas as WrapUp,
    cal_tXfer as Xfer,
    cal_tRing as Ringing,
    cal_key as callKey,
    isnull(e.calif_id,'''') as dispositionId,
    isnull(f.califSubDesc,'''') as subDisposition,
    isnull(f.califSub_id,'''') as subDispositionId
  from cccallsin c with(nolock)
  left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
  left join ccusers b on (c.user_id = b.user_id)
  left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
  left join ccTipoCalif e on ( c.calif_id = e.calif_id )
  left join ccTipoCalifSub f on ( c.califSub_id = f.califSub_id )
  where cal_id >= @call_id
  end

-- OUTBOUND x cal_id
else if @action = 2   begin
  select top 500
    cal_id as call_id,
    c.cam_id,
    isnull(a.cam_descripcion,'''') as Campaign,
    c.cal_telefono as phoneNumber,
    isnull(b.user_id,0) as user_id,
    isnull(login,''''),
    isnull(e.description,'''') as disposition,
    d.descripcion as call_status,
    cal_tDialog as call_tDialog,
    cal_inicio as call_date,
    cal_tNotas as WrapUp,
    cal_tXfer as Xfer,
    cal_tRing as Ringing,
    cal_manual as CallManual,
    c.cal_key as callKey,
    list_id,
    isnull(e.calif_id,'''') as dispositionId,
    isnull(f.califSubDesc,'''') as subDisposition,
    isnull(f.califSub_id,'''') as subDispositionId
  from ccocallsout c with(nolock)
  left join ccocallsoutsource cs on (cs.callout_id = c.callout_id)
  left join ccusers b on (c.user_id = b.user_id)
  left join cccamps a on (c.cam_id = a.cam_id)
  left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
  left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
  left join ccTipoCalifSubOUT f on ( c.califSub_id = f.califSub_id )
  where cal_id >= @call_id
end

else if @action = 3 begin --Session time

  declare @fecha_ini datetime
  declare @fecha_fin datetime

  if (@startDate is null or @endDate is null) or (@startDate = '''' or @endDate = '''') begin
    select @fecha_ini = convert(datetime,convert(varchar(30),getdate()))
    select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))
  end
  else begin
    select @fecha_ini = convert(datetime,convert(varchar(30),@startDate))
    select @fecha_fin = convert(datetime,convert(varchar(30),@endDate))
  end

  select user_id, login, logout, datediff(ss,login,logout) as logintime
  from(select a.user_id, a.fecha as ''login'',
      (select isnull(max(Fecha),getdate())
        from ccLogLogin b with(nolock)
        where b.user_id = a.user_id and
        b.tipomov = 0 and
        b.fecha >= a.fecha and
        b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
              from ccLogLogin with(nolock)
              where user_id = b.user_id and
              tipomov = 1 and
              fecha > a.fecha)) as ''logout''
      from ccLogLogin a
      where a.tipomov=1
      and fecha >= @fecha_ini
      and fecha <= @fecha_fin) as sessiontime
  order by user_id, login
end

else if @action = 4 begin -- Estados de los agentes
  select User_id, tStatus, fecha from cclogagentesdia with(nolock) where TipoStatusAge_id = @state and fecha >= @startDate and fecha < @endDate order by User_id,fecha
end

else if @action = 5 begin-- Sinlge Call id Inbound

  select top 500
    cal_id as call_id,
    c.inbound_id,
    isnull(a.descripcion,'''') as acdGroup,
    cal_ani as phoneNumber,
    isnull(b.user_id,0) as user_id,
    isnull(login,'''') as login,
    isnull(e.description,'''') as disposition,
    d.descripcion as call_status,
    cal_tDialog as call_tDialog,
    cal_inicio as call_date,
    cal_tNotas as WrapUp,
    cal_tXfer as Xfer,
    cal_tRing as Ringing,
    cal_key as callKey,
    isnull(e.calif_id,'''') as dispositionId,
    isnull(f.califSubDesc,'''') as subDisposition,
    isnull(f.califSub_id,'''') as subDispositionId
  from cccallsin c with(nolock)
  left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
  left join ccusers b on (c.user_id = b.user_id)
  left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
  left join ccTipoCalif e on ( c.calif_id = e.calif_id )
  left join ccTipoCalifSub f on ( c.califSub_id = f.califSub_id )
  where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') )
end

else if @action = 6 begin-- Single call_id Outbound

select top 500
  cal_id as call_id,
  c.cam_id,
  isnull(a.cam_descripcion,'''') as Campaign,
  c.cal_telefono as phoneNumber,
  isnull(b.user_id,0) as user_id,isnull(login,''''),
  isnull(e.description,'''') as disposition,
  d.descripcion as call_status,
  cal_tDialog as call_tDialog,
  cal_inicio as call_date,
  cal_tNotas as WrapUp,
  cal_tXfer as Xfer,
  cal_tRing as Ringing,
  cal_manual as CallManual,
  c.cal_key as callKey,
  cs.list_id,
  isnull(e.calif_id,'''') as dispositionId,
  isnull(f.califSubDesc,'''') as subDisposition,
  isnull(f.califSub_id,'''') as subDispositionId
from ccocallsout c with(nolock)
left join ccocallsoutsource cs (nolock) on (cs.callout_id = c.callout_id)
left join ccusers b on (c.user_id = b.user_id)
left join cccamps a on (c.cam_id = a.cam_id)
left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
left join ccTipoCalifSubOUT f on ( c.califSub_id = f.califSub_id )
where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') )
end

else if @action = 7 begin--Status Agente
  select tipostatusAge_id, tstatus, dateadd(ss,(-1*tstatus),fecha), IdCampEsp, Tipo
  from cclogagentesdia with(nolock)
  where user_id = @agentId
  and fecha >= @startDate
  and fecha < @endDate
  order by fecha
end

else if @action = 8 begin
  select tipostatusAge_id, tstatus, dateadd(ss,(-1*tstatus),fecha) fecha, IdCampEsp, Tipo, user_id
  from cclogagentesdia with(index(IX_ccLogAgentesDia_4),nolock)
  where user_id in (select value from fn_RIASplitDelimited(@multipleUser_id,'',''))
  and fecha between @startDate
  and @endDate
  order by user_id,fecha
end
else if @action = 9 begin --Call History by CamId and day

  declare @date dateTime,@countRegistry bigint
  if @PageNumber<=0 set @PageNumber=1

  set @date=convert(datetime,convert(nvarchar(11),GETDATE(),121))

  if @isCount = 0 begin ---Datos para la informacion

    select cal_id as call_id,
      c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,
      c.cal_telefono as phoneNumber,
      isnull(b.user_id,0) as user_id, isnull(login,''''),
      isnull(e.description,'''') as disposition,
      d.descripcion as call_status,
      cal_tDialog as call_tDialog,cal_inicio as call_date,
      cal_tNotas as WrapUp,cal_tXfer as Xfer,
      cal_tRing as Ringing,cal_manual as CallManual,
      c.cal_key as callKey,list_id,
      isnull(e.calif_id,'''') as dispositionId,
      isnull(f.califSubDesc,'''') as subDisposition,
      isnull(f.califSub_id,'''') as subDispositionId,
      rowNum,
      cs.Dato1,
      cs.Dato2,
      cs.Dato3,
      cs.Dato4,
      cs.Dato5
    from (
    select ROW_NUMBER() OVER ( ORDER BY cal_id ) AS rowNum,
      c.callout_id,cal_id,c.cam_id,c.cal_telefono,cal_tDialog ,cal_inicio,cal_tNotas,
      cal_tXfer,cal_tRing ,cal_manual,c.cal_key,c.statusCall_id,c.calif_id,c.califSub_id,c.user_id
     from ccocallsout c with(nolock,index(IX_ccoCallsOut_3)) where cam_id=@camId
     --and cal_Inicio >= @date and cal_Inicio<GETDATE()
    ) as c
    left join ccocallsoutsource cs on (cs.callout_id = c.callout_id)
    left join ccusers b on (c.user_id = b.user_id)
    left join cccamps a on (c.cam_id = a.cam_id)
    left join ccStatusLLamada d on  (c.statusCall_id = d.statusCall_id )
    left join ccTipoCalifOUT e on  (c.calif_id = e.calif_id )
    left join ccTipoCalifSubOUT f on  (c.califSub_id = f.califSub_id)
    where  rowNum BETWEEN ((@PageNumber-1)*@RowsPerPage)+1 AND @RowsPerPage*(@PageNumber)
  end
  else begin--Numero de paginas y registros actuales
    select @countRegistry = count(*)   from ccocallsout c with(nolock,index(IX_ccoCallsOut_3)) where cam_id=@camId
    --and cal_Inicio >= @date and cal_Inicio<GETDATE()
    select @RowsPerPage as pagesize, @PageNumber as  currentpage, @countRegistry/cast(@RowsPerPage as float) as totalpages
  end
end'

EXEC(@sql)

    set @process = 'ALTER PROCEDURE [dbo].[ccsp_MailInitialStatistics] -----------'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_MailInitialStatistics]
@inboundId int=0,
@Option AS SMALLINT=0,
@User_id AS SMALLINT=0
AS
BEGIN

SET NOCOUNT ON;

if(@Option=0)
begin
  select
  count(*) received,
  count(case when messageStatusId = 1 then 1 else null end) pending,
  count(case when messageStatusId in (2,3) then 1 else null end) assigned,
  count(case when messageStatusId = 4 then 1 else null end) unassigned,
  count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
  count(case when messageStatusId = 7 then 1 else null end) rejected,
  count(case when messageStatusId = 8 then 1 else null end) programFwd,
  count(case when messageStatusId = 9 then 1 else null end) forwarding,
  count(case when messageStatusId in (10,11) then 1 else null end) closed,
  count(case when messageStatusId = 3 then 1 else null end) active,
  isnull(AVG(B.twait + B.tretention + B.tresponse),0) avgtAtention,
  isnull(AVG(B.twait),0) avgtWait,
  isnull(MAX(B.twait),0) maxtWait
  from conversation A
  inner join message B on A.conversationId=b.conversationId
  where inboundId= @inboundId
  and (
    (
     messageStatusId in (1,4) or
    (tQueue is not null and [date] <> convert(varchar(10), tQueue,121) and convert(varchar(10), tQueue,121) = convert(varchar(10),getdate(),121)) or
    (tSend is not null and [date] <> convert(varchar(10), tsend,121) and convert(varchar(10), tsend,121) = convert(varchar(10), getdate(),121))
    )
   or [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121)
   )
end
if @Option = 1
BEGIN

  select
  count(*) received,
  count(case when messageStatusId = 1 then 1 else null end) pending,
  count(case when messageStatusId in (2,3) then 1 else null end) assigned,
  count(case when messageStatusId = 4 then 1 else null end) unassigned,
  count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
  count(case when messageStatusId = 7 then 1 else null end) rejected,
  count(case when messageStatusId = 8 then 1 else null end) programFwd,
  count(case when messageStatusId = 9 then 1 else null end) forwarding,
  count(case when messageStatusId in (10,11) then 1 else null end) closed,
  count(case when messageStatusId = 3 then 1 else null end) active ,
  isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
  isnull(AVG(msg.twait),0) avgtWait,
  isnull(MAX(msg.twait),0) maxtWait,
  InboundId inboundId
  from message msg (nolock) join conversation con (nolock) on con.conversationId=msg.conversationId
  where inboundId in (select inbound_id from ccInbound where inbound_id in (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0) and chat = 3)
  and (
    (
     messageStatusId in (1,4) or
    (tQueue is not null and [date] <> convert(varchar(10), tQueue,121) and convert(varchar(10), tQueue,121) = convert(varchar(10),getdate(),121)) or
    (tSend is not null and [date] <> convert(varchar(10), tsend,121) and convert(varchar(10), tsend,121) = convert(varchar(10), getdate(),121))
    )
   or [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121)
   )
  GROUP BY InboundId
  END
END
'
EXEC(@sql)

    set @process = 'ALTER PROCEDURE [dbo].[ccsp_TwitterInitialStatistics] -----------'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_TwitterInitialStatistics]
@inboundId int=0,
@Option AS SMALLINT=0,
@User_id AS SMALLINT=0
AS
BEGIN

  SET NOCOUNT ON;

  if(@Option=0)
  begin
    select
    count(*) received,
    count(case when messageStatusId = 1 then 1 else null end) pending,
    count(case when messageStatusId in (2,3) then 1 else null end) assigned,
    count(case when messageStatusId = 4 then 1 else null end) unassigned,
    count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
    count(case when messageStatusId = 7 then 1 else null end) rejected,
    count(case when messageStatusId = 8 then 1 else null end) programFwd,
    count(case when messageStatusId = 9 then 1 else null end) forwarding,
    count(case when messageStatusId in (10,11) then 1 else null end) closed,
    count(case when messageStatusId = 3 then 1 else null end) active ,
    isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
    isnull(AVG(msg.twait),0) avgtWait,
    isnull(MAX(msg.twait),0) maxtWait
    from messageOutTwitter msg(nolock) join conversationTwitter con (nolock) on con.conversationTwitterId=msg.conversationTwitterId
    where inboundId=@inboundId
    and (
      (
       messageStatusId in (1,4) or
      (tQueue is not null and [date] <> convert(varchar(10), tQueue,121) and convert(varchar(10), tQueue,121) = convert(varchar(10),getdate(),121)) or
      (tSend is not null and [date] <> convert(varchar(10), tsend,121) and convert(varchar(10), tsend,121) = convert(varchar(10), getdate(),121))
      )
      or [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121)
    )
  end
  if @Option = 1
  BEGIN
    select
    count(*) received,
    count(case when messageStatusId = 1 then 1 else null end) pending,
    count(case when messageStatusId in (2,3) then 1 else null end) assigned,
    count(case when messageStatusId = 4 then 1 else null end) unassigned,
    count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
    count(case when messageStatusId = 7 then 1 else null end) rejected,
    count(case when messageStatusId = 8 then 1 else null end) programFwd,
    count(case when messageStatusId = 9 then 1 else null end) forwarding,
    count(case when messageStatusId in (10,11) then 1 else null end) closed,
    count(case when messageStatusId = 3 then 1 else null end) active ,
    isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
    isnull(AVG(msg.twait),0) avgtWait,
    isnull(MAX(msg.twait),0) maxtWait,
    InboundId inboundId
    from messageOutTwitter msg (nolock) join conversationTwitter con (nolock) on con.conversationTwitterId=msg.conversationTwitterId
    where inboundId in (select inbound_id from ccInbound where inbound_id in (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0) and chat = 4)

    and (
      (
       messageStatusId in (1,4) or
      (tQueue is not null and [date] <> convert(varchar(10), tQueue,121) and convert(varchar(10), tQueue,121) = convert(varchar(10),getdate(),121)) or
      (tSend is not null and [date] <> convert(varchar(10), tsend,121) and convert(varchar(10), tsend,121) = convert(varchar(10), getdate(),121))
      )
      or [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121)
    )
    GROUP BY InboundId
  END
END
'
		EXEC(@sql)





		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix
		set  @actualVersionFix = @versionfix
    
		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
if @actualVersion = @version and @actualVersionFix = @versionfix begin
	begin tran
	begin try

		set @process = 'create table optionIVR -----------'
    set @sql='if not exists (select * from sys.tables where name = N''optionIVR'')
    begin
create table optionIVR
(dtmf varchar(10),
tag varchar(10),
camID int,
type int)
end'
		EXEC(@sql)

    set @process = 'CREATE UNIQUE INDEX AK_optionIVR_dtmf_tag_camID-----------'
    set @sql='if not exists (select * from sys.indexes where name = N''AK_optionIVR_dtmf_tag_camID'' and object_id = OBJECT_ID(N''optionIVR''))
    begin
    CREATE UNIQUE INDEX AK_optionIVR_dtmf_tag_camID
ON optionIVR (dtmf, tag, camID)
    end'
		EXEC(@sql)



    set @process = 'alter table ccCamps -----------'
    set @sql='if not exists (select * from sys.columns where name = N''funcEspDtmf'' and Object_ID = Object_ID(N''ccCamps''))
    begin
    alter table ccCamps
add funcEspDtmf int default(0)
    end'
		EXEC(@sql)

    set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp] -----------'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
@User_id smallint
AS
set nocount on
 select a1.cam_id, cam_Descripcion
  , cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
  , cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
  , cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
  , detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
  , cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
  , stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, cam_maxqueue as queSize,
  DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
     ,cast (startStopRecording as tinyint)startStopRecording, leaveRecMessage, manualCallOnChat
  ,callBackSurveyAgent,callBackSurveyClient,case when surveycamid is null or surveycamid = 0 then 0 else 1 end isRelationSurvey,isnull(a1.funcEspDtmf,0)
  from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
  inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
  where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
  order by cam_descripcion
 return(0)
 set nocount off'
    EXEC(@sql)

			set @process = 'Alter SP -- ccsp_AgentGetCalificaciones'
    set @sql='ALTER procedure [dbo].[ccsp_AgentGetCalificaciones]
@InOut tinyint, --0 in, 1 out
@cam_id int --campaÏa
AS
set nocount on

IF @InOut = 0 BEGIN
if exists(
	select calif.calif_id from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
	left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
	left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
	where cam_id = @cam_id and tipo = @InOut)
  begin
	 declare @relationCamId int 
	select @relationCamId =cam_id from ccInbound where Inbound_id=@cam_id
	if @relationCamId is null set @relationCamId=0


	select distinct 1 as tag, null as parent, calif.calif_id "selection!1!id", calif.Description "selection!1!string", calif.orden "selection!1!califorden", 
		isnull(calif.EndConversation,0) "selection!1!endConversation",
		null "subSelection!2!id", null "subSelection!2!string", null "subSelection!2!orden",  null "subSelection!2!endConversation"
		from ccTipoCalif calif
	 inner join ccCalifCamp camp on camp.calif_id=calif.calif_id and camp.cam_id=@cam_id and  camp.tipo = @InOut
	 left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
	 left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id 
	 where calif.CanReprogram=0 or (
		calif.CanReprogram=1 and @relationCamId>0
	 )
	 union
	 select distinct 2 as tag, 1 as parent, calif.calif_id "selection!1!id", null "selection!1!string", calif.orden "selection!1!califorden", isnull(calif.EndConversation,0) "selection!1!endConversation",
		sb.califsub_id "subSelection!2!id", sb.califSubDesc "subSelection!2!string", cast(sb.orden as int) "subSelection!2!orden" ,isnull(sb.EndConversation,0) "subSelection!2!endConversation"
		from ccTipoCalif calif 
		inner join ccCalifCamp camp on camp.calif_id=calif.calif_id and camp.cam_id=@cam_id and  camp.tipo = @InOut
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where sb.califsub_id is not null 
		and (
			sb.CanReprogram=0 or 
			(sb.CanReprogram=1 and @relationCamId>0)
		)
		order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden"
	  for xml explicit, type
  end
 return(0)
 END

IF @InOut = 1 BEGIN
 if exists(
	select calif.calif_id from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
	left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
	left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
	where cam_id = @cam_id and tipo = @InOut)
  begin
		select distinct 1 as tag, null as parent, calif.calif_id "selection!1!id", calif.Description "selection!1!string", calif.keepDial "selection!1!keepOnDial",
		calif.orden "selection!1!califorden", null "subSelection!2!id", null "subSelection!2!string", null "subSelection!2!keepOnDial",
		null "subSelection!2!orden"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = @InOut
		union
		  select distinct 2 as tag, 1 as parent, calif.calif_id "selection!1!id", null "selection!1!string", null "selection!1!keepOnDial",
		  calif.orden "selection!1!califorden", sb.califsub_id "subSelection!2!id", sb.califSubDesc "subSelection!2!string", sb.keepDial "subSelection!2!keepOnDial",
		  cast(sb.orden as int) "subSelection!2!orden"
		  from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		  left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		  left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		  where cam_id = @cam_id and tipo = @InOut and sb.califsub_id is not null
		  order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden"
		  for xml explicit, type
  end
 return(0)
 END

IF @InOut = 10
 BEGIN
  select distinct S.califSub_id, S.califSubDesc, orden
  from cctipoSubCalifRel R join cctipoCalifSub S on R.califSub_id = S.califSub_id
 where R.tipoSubRel=1 and S.califSub_Status=1 and R.calif_id=@cam_id
 order by S.orden, S.califSubDesc
 return(0)
 END

IF @InOut = 11
 BEGIN
  select distinct S.califSub_id, S.califSubDesc, orden
  from cctipoSubCalifRel R join cctipoCalifSubOut S on R.califSub_id = S.califSub_id
 where R.tipoSubRel=0 and S.califSubOut_Status=1 and R.calif_id=@cam_id
 order by S.orden, S.califSubDesc
 return(0)
 END

set nocount off'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_RIA_ABCACDGroups'
    set @sql='ALTER procedure [dbo].[ccsp_RIA_ABCACDGroups]
@option smallint,
@userid int,
@descripcion varchar(40),
@inbound_id varchar(1000),
@idarea smallint = null,
@frame tinyint
as
set nocount on
declare @new_inbound_id smallint, @graph_id smallint

if @option = 0 -- all acd
 begin
	 select acd.inbound_id, acd.descripcion, isnull(acd.idarea,0) as idarea,
	isnull(areas.areaname,'''') as areaname
	 from ccinbound as acd with(nolock)
	 left join dbo.ccriacat_areas as areas with(nolock) on acd.idarea = areas.idarea
	 return(0)
 end

if @option = 1 -- select acd
 begin
	 select a1.inbound_id, a1.descripcion, a3.frame, a1.showcalifwnd, a1.starttimeronhangup, isnull(a1.idarea,0), isnull(a1.cam_id,0) cam_id
	 from ccinbound a1 
	  inner join ccriainboundgraph a2 on (a1.inbound_id=a2.inbound_id)
	  inner join ccriagraphics a3 on (a2.graphic_id=a3.graphic_id)
	 where a3.type_id = 1 and a1.inbound_id = (cast(@inbound_id as int))
	 order by descripcion
	 return(0)
 end

if @option = 2 -- insert
 begin
	if exists (select descripcion from ccinbound where descripcion = @descripcion and status = 1)
	 begin
			select -1--, ''nombre en uso''
			return(0)
	 end
	
	if @idarea = 0
	set @idarea = null
	
	insert into ccinbound (descripcion, starttimeronhangup, idarea, showcalifwnd)
	select @descripcion, 1, @idarea, case when exists(select calif_id from cctipocalif) then 1 else 0 end
	
	if @@rowcount = 1
		select @new_inbound_id = inbound_id from ccinbound where descripcion = @descripcion and status = 1

	else
	 begin
		select -2 -- Error al insertar
		return(0)
	 end

	insert into cccalifcamp (calif_id, cam_id, tipo) select calif_id, @new_inbound_id, 0 from cctipocalif where CanReprogram=0 and Calif_Status = 1

	if not exists (select msg_id from ccInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccMsgFiles where msgFile like ''%\Default%''))
	 begin
		insert into ccInboundMsgs (msg_id, inbound_id, orden, type, queue)
		select msg_id, @new_inbound_id, 0, cast(substring(msgFile, 19,3) as integer),0 from ccMsgFiles where msgFile like ''%\Default%''
	 end

	if not exists (select msg_id from ccRIAChatInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccRIAChatMsg where Descripcion like ''%\Default%''))
	 begin
		insert into ccRIAChatInboundMsgs (msg_id, inbound_id, orden, type)
		select msg_id, @new_inbound_id, 0, cast(substring(Descripcion, 19,3) as integer) from ccRIAChatMsg where Descripcion like ''%\Default%''
	 end

	if not exists(select frame from ccriagraphics where frame = @frame and type_id = 1)
	 insert into ccriagraphics (frame,type_id) values (@frame,1)
	
	 select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
	 
	 insert into ccriainboundgraph(Inbound_id,graphic_id) values(@new_inbound_id,@graph_id)
	 select @new_inbound_id
	 return(0) 
 end

if @option = 3 -- update
 begin
	 if not exists (select frame from ccriagraphics where frame=@frame and type_id=1)
		insert into ccriagraphics (frame, type_id) values (@frame, 1)

	 select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
	 update ccinbound set descripcion = @descripcion where inbound_id = (cast(@inbound_id as int))
	 update ccriainboundgraph set graphic_id = @graph_id where inbound_id = (cast(@inbound_id as int))
	 return(0)
 end

if @option = 4 -- delete
 begin
	 delete cccalifcamp where cam_id = @inbound_id and tipo = 0
	 delete ccinboundhorarios where inbound_id = @inbound_id
	 delete ccriainboundgraph where inbound_id = @inbound_id
	 delete ccInboundMsgs where inbound_id = @inbound_id
	 delete ccRIAChatInboundMsgs where inbound_id = @inbound_id
	 delete ccinbound where inbound_id = @inbound_id
	 return(0)
 end

if @option = 5 -- asignar campaña a ACD
 begin
	if not exists (select inbound_id from ccInbound where inbound_id=@inbound_id) or
	 (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
		not exists (select cam_id from ccCamps where cam_id=@descripcion))
	 begin
		select -3 -- Campaña o ACD invalido
		return(0)
	 end
	
	if @descripcion=0 begin

		set @descripcion = null
		--quitamos calificaciones relacionadas a la campaña
		DELETE c FROM ccCalifCamp c
		INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id
		Where c.cam_id=@inbound_id and ci.CanReprogram =1
		--quitamos subcalificaciones relacionadas a la calificacion
		DELETE rel FROM ccCalifCamp c
		INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id and tipo=0
		inner join cctipoSubCalifRel rel on rel.calif_id=ci.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		Where c.cam_id=@inbound_id and sb.canReprogram=1
				
	end
	
	update ccInbound set cam_id = @descripcion where Inbound_id = @inbound_id
		
	if @@rowcount=0
		select -4 -- Error al actualizar

	return(0)
 end
set nocount off'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_RIAManageAreas'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAManageAreas]
@option tinyint,
@IDArea smallint = 0,
@InsertUserId smallint =null,
@DeleteUserId varchar(255)=null,
@InsertCamId smallint=null,
@DeleteCamId smallint=null,
@InsertACDGroupId smallint=null,
@DeleteACDGroupId smallint=null
as
set nocount on

if @option = 1 -- Insert User Area
	begin
	if not exists(select IDArea from ccUsers where IDArea = @IDArea AND User_id = @InsertUserId)
		begin
		Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @InsertUserId
		return(0)
		end	
					 
	select 1
	return(0)
	end

if @option = 3 -- Insert camp area
	begin
	if not exists(select IDArea from ccCamps where IDArea = @IDArea and cam_id = @InsertCamId)
		begin
		Update ccCamps set IDArea = case @IDArea when 0 then null else @IDArea end
		where cam_id = @InsertCamId
		return(0)
		end

	select 1
	return(0)
	end

if @option = 4 begin-- Delete camp area
	

	--Si existe una campaña relacionada con el grupo
	if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
		select -4
		return(0)	 
	end

	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId
				 
	delete from ccCampsAgente where cam_id = @DeleteCamId
	--delete from ccoDialerCamp where cam_id = @DeleteCamId
	delete from ccoWorkingTable where cam_id = @DeleteCamId

	insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1	

	delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
	delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	
	delete from ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @DeleteCamId)
	

	Update ccCamps set IDArea= null where cam_id=@DeleteCamId--, cam_activo = 0 
	return(0)
	end

if @option = 5 -- Insert ACDGroup area
	begin
	if not exists(select IDArea from ccInbound where IDArea = @IDArea and Inbound_Id = @InsertACDGroupId)
		begin
		Update ccInbound set IDArea = @IDArea, status = 1 where Inbound_id = @InsertACDGroupId
		return(0)
		end

	select 1
	return(0)
	end

if @option = 6 -- Delete ACDGroup area
	begin
		insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

	delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
	delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId

	insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId and A.tipo = 0

	delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
	delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
	delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

	Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId
	select 1
	return(0)
	end

if @option in (2, 9, 10, 11)
	begin
		declare @Type tinyint
	select @Type = TipoUser_id from ccUsers where User_id = @DeleteUserId
					
	if @option in (2, 10, 11) -- Delete User area
		begin
		if @Type = 1 -- Agente
			begin

			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
			insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

			delete from ccCampsAgente where user_id = @DeleteUserId
			delete from ccInboundAgentes where user_id = @DeleteUserId

			if @option = 11
				begin
					select IDWG, User_id into #WorkGroupUsers from ccRIAWorkGroupUsers where user_id = @DeleteUserId

					delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
									
					select * from #WorkGroupUsers
					drop table #WorkGroupUsers
									
					return(0)
				end
			end

		else if @Type in (2, 6) -- Supervisor
		begin
			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
			delete from ccSupervisorCam where user_id = @DeleteUserId
		end

		delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
						
		if @option=2
			begin
			update ccPosicion set user_id = 0 where user_id = @DeleteUserId
			update ccUsers set IDArea = null where user_id = @DeleteUserId	
			end
		return(0)
	end

	declare @UserWG varchar(100)
	-- @option = 9 -- Delete User area and get his workgroups

	select @UserWG = IDWG from ccRIAWorkGroupUsers where user_id = @DeleteUserId

	if @Type = 1 -- Agente
		begin
		insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
		insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

		delete from ccCampsAgente where user_id = @DeleteUserId
		delete from ccInboundAgentes where user_id = @DeleteUserId
		end

	if @Type in (2, 6) -- Supervisor
		begin
		insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId

		delete from ccSupervisorCam where user_id = @DeleteUserId
		delete from ccMenuUser where id_User = @DeleteUserId
		end

	delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
	update ccPosicion set user_id = 0 where user_id = @DeleteUserId
					
	if @option <> 11
		update ccUsers set IDArea = null where user_id = @DeleteUserId
					
	select @UserWG, @Type
	return(0)
	end

declare @AllWG varchar(400), @CurrentWG varchar(400), @AreaDescripcion varchar(40)

if @option = 7 begin-- Delete camp area
	
	if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
	
		---Borra las calificacion con reprogramacion
		delete ccCalifCamp from ccInbound A 
		inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
		inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
		where A.cam_id=@DeleteCamId
		---Borra las subcalificacion con reprogramacion
		delete rel from ccInbound A 
		inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
		inner join ccTipoCalif C on B.calif_id=C.calif_id 
		inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
		inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where A.cam_id=@DeleteCamId and sb.canReprogram=1
	
		update ccInbound set cam_id = null where cam_id=@DeleteCamId				
		 
	end

	select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId

	delete from ccCampsAgente where cam_id = @DeleteCamId
	delete from ccoWorkingTable where cam_id = @DeleteCamId or callout_id 
		in (select callout_id from ccoCallsOutSource where cam_id = @DeleteCamId)

	insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1

	delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
	delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	

	select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

	select @AreaDescripcion = area.AreaName
	from ccCamps as camp with(nolock)inner join ccRIACat_Areas as area 
		with(nolock) on camp.IDArea = area.IDArea
	where camp.cam_id = @DeleteCamId
	Update ccCamps set IDArea = null where cam_id = @DeleteCamId

	If @CurrentWG is null
		set @CurrentWG = 0

	If @AllWG is null
		set @AllWG = 0

	select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
	return(0)
	end

if @option = 8 --Delete ACDGroup area
	begin
	if (select cam_id from ccInbound where Inbound_id = @DeleteACDGroupId) is not null
	begin
		update ccInbound set cam_id = null where Inbound_id = @DeleteACDGroupId
	end

	select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

	insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

	delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
	delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId

	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId 

	delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
	delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
	delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

	select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

	select @AreaDescripcion = area.AreaName
	from ccInbound as ACD with(nolock) inner join ccRIACat_Areas as area 
		with(nolock) on ACD.IDArea = area.IDArea
	where ACD.Inbound_id = @DeleteACDGroupId
	Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId

	If @CurrentWG is null
		set @CurrentWG = 0

	If @AllWG is null
		set @AllWG = 0

	select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
	return(0)
	end

return(0)
set nocount off'
	EXEC(@sql)


	set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp] -----------'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
@User_id smallint
AS
set nocount on
 select a1.cam_id, cam_Descripcion
  , cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
  , cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
  , cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
  , detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
  , cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
  , stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, cam_maxqueue as queSize,
  DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
     ,cast (startStopRecording as tinyint)startStopRecording, leaveRecMessage, manualCallOnChat
  ,callBackSurveyAgent,callBackSurveyClient,case when surveycamid is null or surveycamid = 0 then 0 else 1 end isRelationSurvey,isnull(a1.funcEspDtmf,0)
  from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
  inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
  where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
  order by cam_descripcion
 return(0)
 set nocount off'
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig] -----------'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
@cam_id smallint,
@cam_descripcion varchar(40) = null,
@cam_tnotas smallint = null,
@cam_ocupado tinyint = null,
@cam_NoInt_ocupado tinyint = null,
@cam_inter_ocupado smallint = null,
@cam_nocontesto tinyint = null,
@cam_NoInt_nocontesto tinyint = null,
@cam_inter_nocontesto smallint = null,
@cam_fax tinyint = null,
@cam_NoInt_fax tinyint = null,
@cam_inter_fax smallint = null,
@cam_ModoManual tinyint= null,
@ANI varchar(15) = null,
@cam_ShowCalifWnd bit = null,
@cam_StartTimerOnHangUp bit = null,
@editableCallKey bit = null,
@cam_tNoContesta tinyint = null,
@cam_intensive_dialing tinyint = null,
@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
@compliance TinyInt = null,
@cam_inter_graba smallint = null,
@cam_NoInt_graba tinyint = null,
@progDial smallint = null,
@excCallBack Tinyint = null,
@dialOrder Tinyint = null,
@dialPrefix varchar(10) = null,
@dialPrefixMan varchar(10) = null,
@dialPrefixXfe varchar(10) = null,
@listenManualCall bit = null,
@stopRecording bit = null,
@abandonCallback bit = null,
@autoCB smallint = null,
@id_listAni int = null,
@tDialonWrapUp smallint = null,
@quesize smallint=null,
@DNCScrub int=null,
@callerIdDesc varchar(15)=null,
@timeZoneRule int=null,
@callsBySurvey int=null,
@ivrScript int=null,
@surveyPctg int=null,
@call_record tinyint=null,
@dRestrictPlay bit = null,
@leaveRecMessage bit = null,
@manualCallOnChat bit = null,
@callBackSurveyClient bit = null,
@callBackSurveyAgent bit = null,
@funcEspDtmf int =null
as
set nocount on
UPDATE ccCamps SET
 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
 cam_fax = isnull(@cam_fax,cam_fax),
 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
 ANI = isnull(@ANI,ANI),
 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
 editableCallKey = isnull(@editableCallKey, editableCallKey),
 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
 compliance = isnull(@compliance, compliance),
 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
 progDial = isnull(@progDial, progDial),
 excCallBack = isnull(@excCallBack,excCallBack),
 dialOrder = isnull(@dialOrder, dialOrder),
 dialPrefix = isnull(@dialPrefix, dialPrefix),
 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
 listenManualCall = isnull(@listenManualCall, listenManualCall),
 stopRecording = isnull(@stopRecording, stopRecording),
 abandonCallback = isnull(@abandonCallback, abandonCallback),
 t_autoCB = isnull(@autoCB,t_autoCB),
 id_anilist = isnull(@id_listAni,id_anilist),
 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
 cam_maxqueue = isnull(@quesize,cam_maxqueue),
 DNCScrub = isnull(@DNCScrub,DNCScrub),
 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
 ivrScript = isnull(@ivrScript,ivrScript),
 surveyPctg = isnull(@surveyPctg,surveyPctg),
 call_record = isnull(@call_record,call_record),
 startStopRecording = isnull(@dRestrictPlay, startStopRecording),
 leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
 manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
 callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
 callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
 funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf )
Where cam_id = @cam_id

if @cam_ShowCalifWnd = 1
 begin
 If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
  begin
  select 0
  return(0)
  end

 UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
 where cam_id = @cam_id
 select 1
 return(0)
  end

--else
UPDATE ccCamps SET
cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
where cam_id = @cam_id
return(0)
set nocount off'
		EXEC(@sql)


    set @process = 'Add Column -- ccCampsNvosCB.dateUpdate'
    set @sql='if not exists (select * from sys.columns where name = N''dateUpdate'' and Object_ID = Object_ID(N''ccCampsNvosCB''))
    ALTER TABLE ccCampsNvosCB ADD dateUpdate datetime'
    EXEC(@sql)

    set @process = 'Alter SP ccsp_RIAGetCampsNvosCB -- Change update '
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0
as
set nocount on

declare @TipoJobs as int,@isExecOutbound bit

--declare  @cam_id integer, @Tipo tinyint, @user_id int,@regval int
--select @cam_id=1,@Tipo=1,@user_id=4,@regval=0

set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

  declare @id AS INTEGER

  CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
  CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)

  create table #temccocallsoutsource (cam_id int,Pend  int)

  create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

  if @cam_id = 0 begin
    if @user_id > 0 begin
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
      from ccCamps cam left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
      where user_id = @user_id and tipo = 1
    end
    else begin
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
      from ccCamps cam left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
    end

  end
  else begin
    if @Tipo = 2
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
      from ccCamps cam
      --left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
      where cam.cam_id = @cam_id --and user_id = @user_id and tipo = 1
    else
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
        from ccCamps
  end



  insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
  select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0 from(
  select A.* from #Tcamps A
  left join ccCampsNvosCB B on A.cam_id=B.id
  where datediff(ss,B.dateUpdate,getdate())>5 or B.dateUpdate is null)X

  group by cam_id


  --Se revisa que por lo menos una campaña se pueda actualizar para realizar el proceso en caso contrario se regresa el valro extablecido
  if (select count(*) from #Tcamps2)>0 begin

    insert into #temccocallsoutsource(cam_id,Pend)
    SELECT ccos.cam_id, count(ccos.cam_id) as Pend
    FROM ccocallsoutsource ccos --with(nolock index(IX_ccoCallsOutSource))
    left join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
    WHERE cal_status in(0, 7)
    GROUP BY ccos.cam_id

    insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
    SELECT A.cam_id,
    count(case cal_status when 0 then 1 else null end) as New,
    count(case cal_status when 1 then 1 else null end) as Cb,
    count(case cal_status when 2 then 1 else null end) as Pro,
    count(case cal_status when 3 then 1 else null end) as Fin
    FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
    inner join #Tcamps2 B on A.cam_id = B.cam_id
    GROUP BY A.cam_id

    --select * from #Tcamps2

    --Se va agregar al ccsp_OUTGetNewJobs cuando lo ejecute el SP Outbound para actualizar de manera seguida si solo es una campaña
    if @regval = 0 and @cam_id >0 and @Tipo =2 begin
      update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @cam_id
    end
    else begin
      While (select count(*) from #Tcamps2 where status = 0) > 0 Begin
        set rowcount 1
        select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
        set rowcount 0
        EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
        update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
      end
    end

    begin Tran updateccCampsNvosCB

      delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
      where CampNvosCB.id = tcamp.cam_id

      INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial,dateUpdate)
      SELECT cams.cam_id, cams.cam_descripcion,
      isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
      isNull(cs.Pend,0) as pend,
      isNull(wt.Pro,0) as pro,
      isNull(cams.procesando,0) cam_procesando,
      isNull(cams.cam_tipojobs,0) cam_tipojobs,
      isNull(wt.Fin,0) Fin,
      isNull(tc.cantidad,0) cantidad,
      getdate()
      FROM #Tcamps cams with(nolock)
      LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
      LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
      left join #Tcamps2 tc on (tc.cam_id = cams.cam_id)

    COMMIT TRAN updateccCampsNvosCB
  end

  if @isExecOutbound = 0 begin

    if @Tipo = 2
      -- devuelve resultado de la taba, solo las camps del usuario
      SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, res.st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial
      FROM #Tcamps tcam
      left join  ccCampsNvosCB res  on tcam.cam_id  = res.id
      LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
    else
      SELECT id, campaña, new, cb, pro, pen,st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial
      FROM ccCampsNvosCB res
      LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
      WHERE res.id = @cam_id
  end

  drop table #Tcamps
  drop table #Tcamps2
  drop table #temccocallsoutsource
  drop table #temWorkinTable

  return(0)

end

set nocount off'
    EXEC(@sql)

    set @process = 'Alter SP -- ccsp_OUTGetNewJobs ADD update Cubetas exec  SP ccsp_RIAGetCampsNvosCB'
    set @sql='ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID int,
@test int=0,
@nAgentsLogin int=1,
@iZonas int = null
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @sql varchar(4000), @Order_Asc_Desc char(4)
declare @camSurvey int
select @camSurvey = 0
DECLARE @iZonasTable TABLE (value int)

select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

if @iZonas is null begin

      INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
      select @iZonas=value from @iZonasTable
--Checamos si la campaña tiene horarios configurados
      if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
      begin
                  if @iZonas = 0 begin
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                  end
      end
      else begin
            if @camSurvey > 0
                  begin
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                  end
      end
end

set @sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
      cam_id int,
      cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
      cal_status tinyint,
      cal_fechaDial datetime,
      user_id int,
      tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint
)''


-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
select @topCount=case when @nAgentsLogin<3 then 30
      when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
      when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
      when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
      when @nAgentsLogin>=16 then 240 else 20 end

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

declare @isVerano varchar(max)
set @isVerano = ''izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin

            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,
            W.list_id, isNull(R.sequence,0) as sequence
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
            WHERE cal_status=1 -- CallBacks
            and cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
            and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                  ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by prioridad_cb desc, cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)

            --select @sql
end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,
            W.list_id, isNull(R.sequence,0) as sequence
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
            WHERE cal_status=0 -- Nuevas sin Tiempo
            and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                  ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by R.sequence, cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''

end -- TOMA EN CUENTA LAS NUEVAS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @sql=@sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
      begin
            select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
            WHERE callout_id in(select callout_id from #NEW_JOBS)''
end

if @Test = 2
begin
      select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
      declare @nSQL nvarchar(4000)
      set @nSQL=cast(@sql as nvarchar(4000))
      exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
      return(@total)
end
else
begin
      select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5,
case when tz is null then '''''''' else cal_telefono end as tel,
case when tz2 is null then '''''''' else cal_telefono end as tel2,
case when tz3 is null then '''''''' else cal_telefono end as tel3,
case when tz4 is null then '''''''' else cal_telefono end as tel4,
case when tz5 is null then '''''''' else cal_telefono end as tel5,
NULL as dialOrder, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0

---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
declare @regval int
SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
exec ccsp_RIAGetCampsNvosCB @cam_id=1,@Tipo=2,@user_id =0,@regval=@regval
''
end

set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
print (@sql)
exec(@sql)

return(0)'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW Reports Migration Chat'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Reports Migration Chat'') EXEC msdb.dbo.sp_delete_job @job_name=N''CW Reports Migration Chat'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- NuxibaNewReportsMaintenancePlan'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''NuxibaNewReportsMaintenancePlan'') EXEC msdb.dbo.sp_delete_job @job_name=N''NuxibaNewReportsMaintenancePlan'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW AutoStart'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW AutoStart'')  EXEC msdb.dbo.sp_delete_job @job_name=N''CW AutoStart'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW Campaign summary'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Campaign summary'') EXEC msdb.dbo.sp_delete_job @job_name=N''CW Campaign summary'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW Reports Migration Chat'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW (AutoStart),(allback/abandoned update),(Campaign summary)'')  EXEC msdb.dbo.sp_delete_job @job_name=N''CW (AutoStart),(allback/abandoned update),(Campaign summary)'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW (AutoStart),(Callback/abandoned update),(Campaign summary)'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'')   EXEC msdb.dbo.sp_delete_job @job_name=N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW Callback/abandoned update'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Callback/abandoned update'') EXEC msdb.dbo.sp_delete_job @job_name=N''CW Callback/abandoned update'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- AVRS Merge Replication'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''AVRS Merge Replication'') EXEC msdb.dbo.sp_delete_job @job_name=N''AVRS Merge Replication'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW Merge Replication'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Merge Replication'')  EXEC msdb.dbo.sp_delete_job @job_name=N''CW Merge Replication'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'CREATE JOB --- AVRS Merge Replication'
    set @sql='USE [msdb]

/****** Object:  Job [AVRS Merge Replication]    Script Date: 14/06/2016 12:28:23 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 14/06/2016 12:28:23 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''AVRS Merge Replication'',
    @enabled=1,
    @notify_level_eventlog=0,
    @notify_level_email=0,
    @notify_level_netsend=0,
    @notify_level_page=0,
    @delete_level=0,
    @description=N''No description available.'',
    @category_name=N''[Uncategorized (Local)]'',
    @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [AVRS Merge Replication]    Script Date: 14/06/2016 12:28:23 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''AVRS Merge Replication'',
    @step_id=1,
    @cmdexec_success_code=0,
    @on_success_action=1,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N''TSQL'',
    @command=N''if exists (select * from migrationAVRS  with (nolock) where id >= 100 and [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) begin
  declare @id int
  declare @publicationName varchar(max)

  select top 1 @id=id, @publicationName=[description] from migrationAVRS  with (nolock) where [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''') and id>= 100 order by id

  if @id > 100 begin
    declare @temp varchar(max)
    declare @jobName varchar(max)
    declare @tempId int
    set @tempId = @id -1

    select @temp = [description] from migrationAVRS  with (nolock) where id = @id-1

    if (select count(*)
      from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
      where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%'''' and runstatus = 2
      and publication = @temp
      ) = 0
    begin
      set @id = @id - 1
    end

    if (select count(*)
      from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
      where b.publisher_db = ''''CCenterRia'''' and runstatus in (5,6) and publication = @temp
      ) > 0
    begin
      set @id = @id + 1
    end

    if (select [dateStart] from migrationAVRS  with (nolock) where id = @tempId) <> convert(datetime ,''''jan 1 1900'''') begin
        if exists(select * from distribution..MSreplication_monitordata where publication = @temp and agent_type = 1and [status] = 0) begin

        select @jobName = agent_name from distribution..MSreplication_monitordata where publication = @temp and agent_type = 1 and [status] = 0

        create table #jobActivity(
        session_id int null,job_id uniqueidentifier null,
        job_name sysname null, run_requested_date datetime null,
        run_requested_source sysname null, queued_date datetime null,
        start_execution_date datetime null, last_executed_step_id int null,
        last_exectued_step_date datetime null, stop_execution_date datetime null,
        next_scheduled_run_date datetime null, job_history_id int null,
        [message] nvarchar(1024) null, run_status int null,
        operator_id_emailed int null, operator_id_netsent int null,
        operator_id_paged int null)

        insert into #jobActivity exec msdb.dbo.sp_help_jobactivity @job_name = @jobName

        if (select start_execution_date from #jobActivity) is null exec sp_startpublication_snapshot @publication = @temp

        drop table #jobActivity
      end
    end
  end
  if (select [dateStart] from migrationAVRS  with (nolock) where id = @id) = convert(datetime ,''''jan 1 1900'''')  begin
    begin transaction replications
    begin try
      update migrationAVRS with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id - 1 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
      update migrationAVRS with (rowlock) set [dateStart] = getdate() where id = @id
      exec sp_startpublication_snapshot @publication = @publicationName
      commit transaction replications
    end try
    begin catch
      ROLLBACK TRANSACTION replications;
      update migrationAVRS with (rowlock) set [dateStart] = getdate() where id = @id
      update migrationAVRS with (rowlock) set [error] = ERROR_MESSAGE() where id = @id
      update migrationAVRS with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id
    end catch
  end
end
if  exists (select * from migrationAVRS where id = 104 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) begin
  if exists(
  select * from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
    where b.publisher_db = ''''CCenterRia''''
    and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%''''
    and runstatus = 2 and publication = ''''AVRSSettings'''')
  begin
    update migrationAVRS with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 104 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')

  end
end
if not exists (select * from migrationAVRS where id = 104 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) begin
  EXEC msdb.dbo.sp_update_job @job_name=N''''AVRS Merge Replication'''',@enabled = 0
end'',
    @database_name=N''CCenterRia'',
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''replication'',
    @enabled=1,
    @freq_type=4,
    @freq_interval=1,
    @freq_subday_type=4,
    @freq_subday_interval=1,
    @freq_relative_interval=0,
    @freq_recurrence_factor=0,
    @active_start_date=20130625,
    @active_end_date=99991231,
    @active_start_time=0,
    @active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@sql)

    set @process = 'CREATE JOB -- CW (AutoStart),(Callback/abandoned update),(Campaign summary)'
    set @sql='USE [msdb]
/****** Object:  Job [CW (AutoStart),(allback/abandoned update),(Campaign summary)]    Script Date: 14/06/2016 01:11:22 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 14/06/2016 01:11:22 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'',
    @enabled=1,
    @notify_level_eventlog=0,
    @notify_level_email=0,
    @notify_level_netsend=0,
    @notify_level_page=0,
    @delete_level=0,
    @description=N''Se funcioan los jobs CW AutoStart, CW Callback/abandoned update y CW Campaign summary'',
    @category_name=N''[Uncategorized (Local)]'',
    @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW AutoStart]    Script Date: 14/06/2016 01:11:22 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW AutoStart'',
    @step_id=1,
    @cmdexec_success_code=0,
    @on_success_action=3,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N''TSQL'',
    @command=N''exec ccsp_OutGenerateAutoinicio'',
    @database_name=N''CCenterRia'',
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Callback/abandoned update]    Script Date: 14/06/2016 01:11:22 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Callback/abandoned update'',
    @step_id=2,
    @cmdexec_success_code=0,
    @on_success_action=3,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N''TSQL'',
    @command=N''declare @callout_id_array varchar(max), @SQL varchar(max)
set @callout_id_array=''''|''''

select @callout_id_array=@callout_id_array+coalesce('''',''''+cast(callout_id as varchar(10)), @callout_id_array, '''''''')
from ccRIAUpdateCallBack_Abandon where minCallBackAbandonXpire < getdate()

if len(@callout_id_array)>1
 begin
  select @callout_id_array=replace(@callout_id_array, ''''|,'''', '''''''')

  set @SQL=''''delete ccoWorkingTable with(rowlock) where callout_id in (''''+@callout_id_array+'''')''''
  exec(@SQL)

  set @SQL=''''delete ccRIAUpdateCallBack_Abandon with(rowlock) where callout_id in (''''+@callout_id_array+'''')''''
  exec(@SQL)

  set @SQL=''''update ccoCallBacks with(rowlock) set [status] = 4, schedulerStatus = 1 where callout_id in (''''+@callout_id_array+'''') and [status] = 0''''
  exec(@SQL)
 end'',
    @database_name=N''CCenterRia'',
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Campaign summary]    Script Date: 14/06/2016 01:11:22 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Campaign summary'',
    @step_id=3,
    @cmdexec_success_code=0,
    @on_success_action=1,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N''TSQL'',
    @command=N''exec ccsp_RIAGetCampsNvosCB 0,2,0'',
    @database_name=N''CCenterRia'',
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CW Commons Tasj'',
    @enabled=1,
    @freq_type=4,
    @freq_interval=1,
    @freq_subday_type=4,
    @freq_subday_interval=30,
    @freq_relative_interval=0,
    @freq_recurrence_factor=0,
    @active_start_date=20151022,
    @active_end_date=99991231,
    @active_start_time=0,
    @active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@sql)

    set @process = 'CREATE JOB -- CW Merge Replication'
    set @sql='USE [msdb]
/****** Object:  Job [CW Merge Replication]    Script Date: 14/06/2016 12:34:55 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 14/06/2016 12:34:55 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Merge Replication'',
    @enabled=1,
    @notify_level_eventlog=0,
    @notify_level_email=0,
    @notify_level_netsend=0,
    @notify_level_page=0,
    @delete_level=0,
    @description=N''No description available.'',
    @category_name=N''[Uncategorized (Local)]'',
    @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Merge Replication]    Script Date: 14/06/2016 12:34:56 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Merge Replication'',
    @step_id=1,
    @cmdexec_success_code=0,
    @on_success_action=1,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N''TSQL'',
    @command=N''if (select count(*) from migration  with (nolock) where id >= 100 and [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) > 0
  begin
    declare @id int
    declare @publicationName varchar(max)

    select top 1 @id=id, @publicationName=[description] from migration  with (nolock) where [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''') and id>= 100 order by id

    if @id > 100
      begin
        declare @temp varchar(max)
        declare @jobName varchar(max)
        declare @tempId int
        set @tempId = @id -1

        select @temp = [description] from migration  with (nolock) where id = @id-1

        if (select count(*)
        from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
        where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%'''' and runstatus = 2
        and publication = @temp) = 0
        begin
          set @id = @id - 1
        end

        if (select count(*)
        from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
        where b.publisher_db = ''''CCenterRia'''' and runstatus in (5,6)
        and publication = @temp) > 0
        begin
          set @id = @id + 1
        end

        if (select [dateStart] from migration  with (nolock) where id = @tempId) <> convert(datetime ,''''jan 1 1900'''')
        begin
          if exists(select *
                from distribution..MSreplication_monitordata
                where publication = @temp
                and agent_type = 1
                and [status] = 0)
            begin
              select @jobName = agent_name
              from distribution..MSreplication_monitordata
              where publication = @temp
              and agent_type = 1
              and [status] = 0

              create table #jobActivity(
              session_id int null,
              job_id uniqueidentifier null,
              job_name sysname null,
              run_requested_date datetime null,
              run_requested_source sysname null,
              queued_date datetime null,
              start_execution_date datetime null,
              last_executed_step_id int null,
              last_exectued_step_date datetime null,
              stop_execution_date datetime null,
              next_scheduled_run_date datetime null,
              job_history_id int null,
              [message] nvarchar(1024) null,
              run_status int null,
              operator_id_emailed int null,
              operator_id_netsent int null,
              operator_id_paged int null
              )

              insert into #jobActivity
                exec msdb.dbo.sp_help_jobactivity @job_name = @jobName

              if (select start_execution_date from #jobActivity) is null
                begin
                  exec sp_startpublication_snapshot @publication = @temp
                end

              drop table #jobActivity
            end
        end
      end
    if (select [dateStart] from migration  with (nolock) where id = @id) = convert(datetime ,''''jan 1 1900'''')
    begin
      begin transaction replications
      begin try
        update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id - 1 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
        update migration with (rowlock) set [dateStart] = getdate() where id = @id
        exec sp_startpublication_snapshot @publication = @publicationName
        commit transaction replications
      end try
      begin catch
        ROLLBACK TRANSACTION replications;
        update migration with (rowlock) set [dateStart] = getdate() where id = @id
        update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = @id
        update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id
      end catch
    end
  end
  if exists (select * from migration where id = 115 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900''''))
      begin
        if (select count(*)
        from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
        where b.publisher_db = ''''CCenterRia''''
        and b.id = a.agent_id
        and comments like ''''%A snapshot of%%article(s) was generated.%''''
        and runstatus = 2
        and publication = ''''MenuReportsRia'''') = 1
        begin
          update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 115 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
          EXEC msdb.dbo.sp_update_job @job_name=N''''CW Merge Replication'''',@enabled = 0
        end
      end
if not exists (select * from migration where id = 115 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) begin
  EXEC msdb.dbo.sp_update_job @job_name=N''''CW Merge Replication'''',@enabled = 0
end'',
    @database_name=N''CCenterRia'',
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''replication'',
    @enabled=1,
    @freq_type=4,
    @freq_interval=1,
    @freq_subday_type=4,
    @freq_subday_interval=1,
    @freq_relative_interval=0,
    @freq_recurrence_factor=0,
    @active_start_date=20130625,
    @active_end_date=99991231,
    @active_start_time=0,
    @active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@sql)

    set @process = 'Add Column -- ccCampsNvosCB.dateUpdate'
    set @sql='if not exists (select * from sys.columns where name = N''dateUpdate'' and Object_ID = Object_ID(N''ccCampsNvosCB''))
    ALTER TABLE ccCampsNvosCB ADD dateUpdate datetime'
    EXEC(@sql)

    set @process = 'Alter SP ccsp_RIAGetCampsNvosCB -- Change update '
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0
as
set nocount on

declare @TipoJobs as int,@isExecOutbound bit

--declare  @cam_id integer, @Tipo tinyint, @user_id int,@regval int
--select @cam_id=1,@Tipo=1,@user_id=4,@regval=0

set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

  declare @id AS INTEGER

  CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
  CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)

  create table #temccocallsoutsource (cam_id int,Pend  int)

  create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

  if @cam_id = 0 begin
    if @user_id > 0 begin
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
      from ccCamps cam left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
      where user_id = @user_id and tipo = 1
    end
    else begin
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
      from ccCamps cam left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
    end

  end
  else begin
    if @Tipo = 2
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
      from ccCamps cam
      --left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
      where cam.cam_id = @cam_id --and user_id = @user_id and tipo = 1
    else
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
        from ccCamps
  end



  insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
  select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0 from(
  select A.* from #Tcamps A
  left join ccCampsNvosCB B on A.cam_id=B.id
  where datediff(ss,B.dateUpdate,getdate())>5 or B.dateUpdate is null)X

  group by cam_id


  --Se revisa que por lo menos una campaña se pueda actualizar para realizar el proceso en caso contrario se regresa el valro extablecido
  if (select count(*) from #Tcamps2)>0 begin

    insert into #temccocallsoutsource(cam_id,Pend)
    SELECT ccos.cam_id, count(ccos.cam_id) as Pend
    FROM ccocallsoutsource ccos --with(nolock index(IX_ccoCallsOutSource))
    left join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
    WHERE cal_status in(0, 7)
    GROUP BY ccos.cam_id

    insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
    SELECT A.cam_id,
    count(case cal_status when 0 then 1 else null end) as New,
    count(case cal_status when 1 then 1 else null end) as Cb,
    count(case cal_status when 2 then 1 else null end) as Pro,
    count(case cal_status when 3 then 1 else null end) as Fin
    FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
    inner join #Tcamps2 B on A.cam_id = B.cam_id
    GROUP BY A.cam_id

    --select * from #Tcamps2

    --Se va agregar al ccsp_OUTGetNewJobs cuando lo ejecute el SP Outbound para actualizar de manera seguida si solo es una campaña
    if @regval = 0 and @cam_id >0 and @Tipo =2 begin
      update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @cam_id
    end
    else begin
      While (select count(*) from #Tcamps2 where status = 0) > 0 Begin
        set rowcount 1
        select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
        set rowcount 0
        EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
        update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
      end
    end

    begin Tran updateccCampsNvosCB

      delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
      where CampNvosCB.id = tcamp.cam_id

      INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial,dateUpdate)
      SELECT cams.cam_id, cams.cam_descripcion,
      isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
      isNull(cs.Pend,0) as pend,
      isNull(wt.Pro,0) as pro,
      isNull(cams.procesando,0) cam_procesando,
      isNull(cams.cam_tipojobs,0) cam_tipojobs,
      isNull(wt.Fin,0) Fin,
      isNull(tc.cantidad,0) cantidad,
      getdate()
      FROM #Tcamps cams with(nolock)
      LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
      LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
      left join #Tcamps2 tc on (tc.cam_id = cams.cam_id)

    COMMIT TRAN updateccCampsNvosCB
  end

  if @isExecOutbound = 0 begin

    if @Tipo = 2
      -- devuelve resultado de la taba, solo las camps del usuario
      SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, res.st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial
      FROM #Tcamps tcam
      left join  ccCampsNvosCB res  on tcam.cam_id  = res.id
      LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
    else
      SELECT id, campaña, new, cb, pro, pen,st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial
      FROM ccCampsNvosCB res
      LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
      WHERE res.id = @cam_id
  end

  drop table #Tcamps
  drop table #Tcamps2
  drop table #temccocallsoutsource
  drop table #temWorkinTable

  return(0)

end

set nocount off'
    EXEC(@sql)

    set @process = 'Alter SP -- ccsp_OUTGetNewJobs ADD update Cubetas exec  SP ccsp_RIAGetCampsNvosCB'
    set @sql='ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID int,
@test int=0,
@nAgentsLogin int=1,
@iZonas int = null
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @sql varchar(4000), @Order_Asc_Desc char(4)
declare @camSurvey int
select @camSurvey = 0
DECLARE @iZonasTable TABLE (value int)

select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

if @iZonas is null begin

      INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
      select @iZonas=value from @iZonasTable
--Checamos si la campaña tiene horarios configurados
      if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
      begin
                  if @iZonas = 0 begin
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                  end
      end
      else begin
            if @camSurvey > 0
                  begin
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                  end
      end
end

set @sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
      cam_id int,
      cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
      cal_status tinyint,
      cal_fechaDial datetime,
      user_id int,
      tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint
)''


-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
select @topCount=case when @nAgentsLogin<3 then 30
      when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
      when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
      when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
      when @nAgentsLogin>=16 then 240 else 20 end

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

declare @isVerano varchar(max)
set @isVerano = ''izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin

            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,
            W.list_id, isNull(R.sequence,0) as sequence
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
            WHERE cal_status=1 -- CallBacks
            and cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
            and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                  ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by prioridad_cb desc, cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)

            --select @sql
end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,
            W.list_id, isNull(R.sequence,0) as sequence
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
            WHERE cal_status=0 -- Nuevas sin Tiempo
            and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                  ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by R.sequence, cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''

end -- TOMA EN CUENTA LAS NUEVAS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @sql=@sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
      begin
            select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
            WHERE callout_id in(select callout_id from #NEW_JOBS)''
end

if @Test = 2
begin
      select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
      declare @nSQL nvarchar(4000)
      set @nSQL=cast(@sql as nvarchar(4000))
      exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
      return(@total)
end
else
begin
      select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5,
case when tz is null then '''''''' else cal_telefono end as tel,
case when tz2 is null then '''''''' else cal_telefono end as tel2,
case when tz3 is null then '''''''' else cal_telefono end as tel3,
case when tz4 is null then '''''''' else cal_telefono end as tel4,
case when tz5 is null then '''''''' else cal_telefono end as tel5,
NULL as dialOrder, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0

---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
declare @regval int
SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
exec ccsp_RIAGetCampsNvosCB @cam_id=1,@Tipo=2,@user_id =0,@regval=@regval
''
end

set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
print (@sql)
exec(@sql)

return(0)'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW Reports Migration Chat'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Reports Migration Chat'') EXEC msdb.dbo.sp_delete_job @job_name=N''CW Reports Migration Chat'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- NuxibaNewReportsMaintenancePlan'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''NuxibaNewReportsMaintenancePlan'') EXEC msdb.dbo.sp_delete_job @job_name=N''NuxibaNewReportsMaintenancePlan'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW AutoStart'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW AutoStart'')  EXEC msdb.dbo.sp_delete_job @job_name=N''CW AutoStart'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW Campaign summary'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Campaign summary'') EXEC msdb.dbo.sp_delete_job @job_name=N''CW Campaign summary'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW Reports Migration Chat'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW (AutoStart),(allback/abandoned update),(Campaign summary)'')  EXEC msdb.dbo.sp_delete_job @job_name=N''CW (AutoStart),(allback/abandoned update),(Campaign summary)'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW (AutoStart),(Callback/abandoned update),(Campaign summary)'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'')   EXEC msdb.dbo.sp_delete_job @job_name=N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW Callback/abandoned update'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Callback/abandoned update'') EXEC msdb.dbo.sp_delete_job @job_name=N''CW Callback/abandoned update'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- AVRS Merge Replication'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''AVRS Merge Replication'') EXEC msdb.dbo.sp_delete_job @job_name=N''AVRS Merge Replication'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'DROP JOB -- CW Merge Replication'
    set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Merge Replication'')  EXEC msdb.dbo.sp_delete_job @job_name=N''CW Merge Replication'', @delete_unused_schedule=1'
    EXEC(@sql)

    set @process = 'CREATE JOB --- AVRS Merge Replication'
    set @sql='USE [msdb]

/****** Object:  Job [AVRS Merge Replication]    Script Date: 14/06/2016 12:28:23 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 14/06/2016 12:28:23 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''AVRS Merge Replication'',
    @enabled=1,
    @notify_level_eventlog=0,
    @notify_level_email=0,
    @notify_level_netsend=0,
    @notify_level_page=0,
    @delete_level=0,
    @description=N''No description available.'',
    @category_name=N''[Uncategorized (Local)]'',
    @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [AVRS Merge Replication]    Script Date: 14/06/2016 12:28:23 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''AVRS Merge Replication'',
    @step_id=1,
    @cmdexec_success_code=0,
    @on_success_action=1,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N''TSQL'',
    @command=N''if exists (select * from migrationAVRS  with (nolock) where id >= 100 and [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) begin
  declare @id int
  declare @publicationName varchar(max)

  select top 1 @id=id, @publicationName=[description] from migrationAVRS  with (nolock) where [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''') and id>= 100 order by id

  if @id > 100 begin
    declare @temp varchar(max)
    declare @jobName varchar(max)
    declare @tempId int
    set @tempId = @id -1

    select @temp = [description] from migrationAVRS  with (nolock) where id = @id-1

    if (select count(*)
      from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
      where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%'''' and runstatus = 2
      and publication = @temp
      ) = 0
    begin
      set @id = @id - 1
    end

    if (select count(*)
      from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
      where b.publisher_db = ''''CCenterRia'''' and runstatus in (5,6) and publication = @temp
      ) > 0
    begin
      set @id = @id + 1
    end

    if (select [dateStart] from migrationAVRS  with (nolock) where id = @tempId) <> convert(datetime ,''''jan 1 1900'''') begin
        if exists(select * from distribution..MSreplication_monitordata where publication = @temp and agent_type = 1and [status] = 0) begin

        select @jobName = agent_name from distribution..MSreplication_monitordata where publication = @temp and agent_type = 1 and [status] = 0

        create table #jobActivity(
        session_id int null,job_id uniqueidentifier null,
        job_name sysname null, run_requested_date datetime null,
        run_requested_source sysname null, queued_date datetime null,
        start_execution_date datetime null, last_executed_step_id int null,
        last_exectued_step_date datetime null, stop_execution_date datetime null,
        next_scheduled_run_date datetime null, job_history_id int null,
        [message] nvarchar(1024) null, run_status int null,
        operator_id_emailed int null, operator_id_netsent int null,
        operator_id_paged int null)

        insert into #jobActivity exec msdb.dbo.sp_help_jobactivity @job_name = @jobName

        if (select start_execution_date from #jobActivity) is null exec sp_startpublication_snapshot @publication = @temp

        drop table #jobActivity
      end
    end
  end
  if (select [dateStart] from migrationAVRS  with (nolock) where id = @id) = convert(datetime ,''''jan 1 1900'''')  begin
    begin transaction replications
    begin try
      update migrationAVRS with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id - 1 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
      update migrationAVRS with (rowlock) set [dateStart] = getdate() where id = @id
      exec sp_startpublication_snapshot @publication = @publicationName
      commit transaction replications
    end try
    begin catch
      ROLLBACK TRANSACTION replications;
      update migrationAVRS with (rowlock) set [dateStart] = getdate() where id = @id
      update migrationAVRS with (rowlock) set [error] = ERROR_MESSAGE() where id = @id
      update migrationAVRS with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id
    end catch
  end
end
if  exists (select * from migrationAVRS where id = 104 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) begin
  if exists(
  select * from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
    where b.publisher_db = ''''CCenterRia''''
    and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%''''
    and runstatus = 2 and publication = ''''AVRSSettings'''')
  begin
    update migrationAVRS with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 104 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')

  end
end
if not exists (select * from migrationAVRS where id = 104 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) begin
  EXEC msdb.dbo.sp_update_job @job_name=N''''AVRS Merge Replication'''',@enabled = 0
end'',
    @database_name=N''CCenterRia'',
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''replication'',
    @enabled=1,
    @freq_type=4,
    @freq_interval=1,
    @freq_subday_type=4,
    @freq_subday_interval=1,
    @freq_relative_interval=0,
    @freq_recurrence_factor=0,
    @active_start_date=20130625,
    @active_end_date=99991231,
    @active_start_time=0,
    @active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@sql)

    set @process = 'CREATE JOB -- CW (AutoStart),(Callback/abandoned update),(Campaign summary)'
    set @sql='USE [msdb]
/****** Object:  Job [CW (AutoStart),(allback/abandoned update),(Campaign summary)]    Script Date: 14/06/2016 01:11:22 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 14/06/2016 01:11:22 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'',
    @enabled=1,
    @notify_level_eventlog=0,
    @notify_level_email=0,
    @notify_level_netsend=0,
    @notify_level_page=0,
    @delete_level=0,
    @description=N''Se funcioan los jobs CW AutoStart, CW Callback/abandoned update y CW Campaign summary'',
    @category_name=N''[Uncategorized (Local)]'',
    @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW AutoStart]    Script Date: 14/06/2016 01:11:22 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW AutoStart'',
    @step_id=1,
    @cmdexec_success_code=0,
    @on_success_action=3,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N''TSQL'',
    @command=N''exec ccsp_OutGenerateAutoinicio'',
    @database_name=N''CCenterRia'',
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Callback/abandoned update]    Script Date: 14/06/2016 01:11:22 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Callback/abandoned update'',
    @step_id=2,
    @cmdexec_success_code=0,
    @on_success_action=3,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N''TSQL'',
    @command=N''declare @callout_id_array varchar(max), @SQL varchar(max)
set @callout_id_array=''''|''''

select @callout_id_array=@callout_id_array+coalesce('''',''''+cast(callout_id as varchar(10)), @callout_id_array, '''''''')
from ccRIAUpdateCallBack_Abandon where minCallBackAbandonXpire < getdate()

if len(@callout_id_array)>1
 begin
  select @callout_id_array=replace(@callout_id_array, ''''|,'''', '''''''')

  set @SQL=''''delete ccoWorkingTable with(rowlock) where callout_id in (''''+@callout_id_array+'''')''''
  exec(@SQL)

  set @SQL=''''delete ccRIAUpdateCallBack_Abandon with(rowlock) where callout_id in (''''+@callout_id_array+'''')''''
  exec(@SQL)

  set @SQL=''''update ccoCallBacks with(rowlock) set [status] = 4, schedulerStatus = 1 where callout_id in (''''+@callout_id_array+'''') and [status] = 0''''
  exec(@SQL)
 end'',
    @database_name=N''CCenterRia'',
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Campaign summary]    Script Date: 14/06/2016 01:11:22 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Campaign summary'',
    @step_id=3,
    @cmdexec_success_code=0,
    @on_success_action=1,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N''TSQL'',
    @command=N''exec ccsp_RIAGetCampsNvosCB 0,2,0'',
    @database_name=N''CCenterRia'',
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CW Commons Tasj'',
    @enabled=1,
    @freq_type=4,
    @freq_interval=1,
    @freq_subday_type=4,
    @freq_subday_interval=30,
    @freq_relative_interval=0,
    @freq_recurrence_factor=0,
    @active_start_date=20151022,
    @active_end_date=99991231,
    @active_start_time=0,
    @active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@sql)

    set @process = 'CREATE JOB -- CW Merge Replication'
    set @sql='USE [msdb]
/****** Object:  Job [CW Merge Replication]    Script Date: 14/06/2016 12:34:55 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 14/06/2016 12:34:55 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Merge Replication'',
    @enabled=1,
    @notify_level_eventlog=0,
    @notify_level_email=0,
    @notify_level_netsend=0,
    @notify_level_page=0,
    @delete_level=0,
    @description=N''No description available.'',
    @category_name=N''[Uncategorized (Local)]'',
    @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Merge Replication]    Script Date: 14/06/2016 12:34:56 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Merge Replication'',
    @step_id=1,
    @cmdexec_success_code=0,
    @on_success_action=1,
    @on_success_step_id=0,
    @on_fail_action=2,
    @on_fail_step_id=0,
    @retry_attempts=0,
    @retry_interval=0,
    @os_run_priority=0, @subsystem=N''TSQL'',
    @command=N''if (select count(*) from migration  with (nolock) where id >= 100 and [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) > 0
  begin
    declare @id int
    declare @publicationName varchar(max)

    select top 1 @id=id, @publicationName=[description] from migration  with (nolock) where [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''') and id>= 100 order by id

    if @id > 100
      begin
        declare @temp varchar(max)
        declare @jobName varchar(max)
        declare @tempId int
        set @tempId = @id -1

        select @temp = [description] from migration  with (nolock) where id = @id-1

        if (select count(*)
        from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
        where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%'''' and runstatus = 2
        and publication = @temp) = 0
        begin
          set @id = @id - 1
        end

        if (select count(*)
        from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
        where b.publisher_db = ''''CCenterRia'''' and runstatus in (5,6)
        and publication = @temp) > 0
        begin
          set @id = @id + 1
        end

        if (select [dateStart] from migration  with (nolock) where id = @tempId) <> convert(datetime ,''''jan 1 1900'''')
        begin
          if exists(select *
                from distribution..MSreplication_monitordata
                where publication = @temp
                and agent_type = 1
                and [status] = 0)
            begin
              select @jobName = agent_name
              from distribution..MSreplication_monitordata
              where publication = @temp
              and agent_type = 1
              and [status] = 0

              create table #jobActivity(
              session_id int null,
              job_id uniqueidentifier null,
              job_name sysname null,
              run_requested_date datetime null,
              run_requested_source sysname null,
              queued_date datetime null,
              start_execution_date datetime null,
              last_executed_step_id int null,
              last_exectued_step_date datetime null,
              stop_execution_date datetime null,
              next_scheduled_run_date datetime null,
              job_history_id int null,
              [message] nvarchar(1024) null,
              run_status int null,
              operator_id_emailed int null,
              operator_id_netsent int null,
              operator_id_paged int null
              )

              insert into #jobActivity
                exec msdb.dbo.sp_help_jobactivity @job_name = @jobName

              if (select start_execution_date from #jobActivity) is null
                begin
                  exec sp_startpublication_snapshot @publication = @temp
                end

              drop table #jobActivity
            end
        end
      end
    if (select [dateStart] from migration  with (nolock) where id = @id) = convert(datetime ,''''jan 1 1900'''')
    begin
      begin transaction replications
      begin try
        update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id - 1 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
        update migration with (rowlock) set [dateStart] = getdate() where id = @id
        exec sp_startpublication_snapshot @publication = @publicationName
        commit transaction replications
      end try
      begin catch
        ROLLBACK TRANSACTION replications;
        update migration with (rowlock) set [dateStart] = getdate() where id = @id
        update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = @id
        update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id
      end catch
    end
  end
  if exists (select * from migration where id = 115 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900''''))
      begin
        if (select count(*)
        from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
        where b.publisher_db = ''''CCenterRia''''
        and b.id = a.agent_id
        and comments like ''''%A snapshot of%%article(s) was generated.%''''
        and runstatus = 2
        and publication = ''''MenuReportsRia'''') = 1
        begin
          update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 115 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
          EXEC msdb.dbo.sp_update_job @job_name=N''''CW Merge Replication'''',@enabled = 0
        end
      end
if not exists (select * from migration where id = 115 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) begin
  EXEC msdb.dbo.sp_update_job @job_name=N''''CW Merge Replication'''',@enabled = 0
end'',
    @database_name=N''CCenterRia'',
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''replication'',
    @enabled=1,
    @freq_type=4,
    @freq_interval=1,
    @freq_subday_type=4,
    @freq_subday_interval=1,
    @freq_relative_interval=0,
    @freq_recurrence_factor=0,
    @active_start_date=20130625,
    @active_end_date=99991231,
    @active_start_time=0,
    @active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
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