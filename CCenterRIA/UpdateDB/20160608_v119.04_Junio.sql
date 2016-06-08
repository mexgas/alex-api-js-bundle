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

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else if @actualVersion = @version and @actualVersionFix = @versionfix begin
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