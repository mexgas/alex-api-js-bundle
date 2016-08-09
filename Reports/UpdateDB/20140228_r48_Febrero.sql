/*
Autor: Raymundo Gonzalez
Fecha: 2014/02/28
Descripcion:
	Se modifica el SP ccRepOutPortStats para fix
	Se modifica el Job NuxibaReportsMaintenancePlan para actualizacion
	
Version requerida: 47
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '48'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccRepOutPortStats - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccRepOutPortStats]
@fini as varchar(20),
@ffin as varchar(20),
@DateG as varchar(20),
@CamGral as varchar(20),
@cbjUno as varchar(500),
@tipo as tinyint,
@cbjDos as varchar(500) --0 inbound, 1 outbound
as
set nocount on

DECLARE @sGroupDetail as varchar(105), @Sql varchar(max), @ddif as smallint, @idioma as smallint, @desde as varchar(4), @hasta as varchar(4)

select @desde = ltrim(rtrim(Substring(@cbjDos,1,Charindex(''-'',@cbjDos)-1)))
select @hasta = ltrim(rtrim(Substring(@cbjDos,Charindex(''-'',@cbjDos)+len(''-''),len(@cbjDos))))

select @ddif = datediff(dd,@fini,@ffin)
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23
select @DateG = case when @DateG =''Por Medias Hrs'' or @DateG =''Half Hour'' then ''H'' 
					 when @DateG =''Por Día'' or @DateG =''Day'' then ''D'' 
					 when @DateG =''Por Hora'' or @DateG =''Hour'' then ''O'' end

declare @time varchar(10)
select @time = case when @DateG =''H'' then ''30''
					 when @DateG =''D'' then  ''1440''
					 when @DateG =''O'' then ''60'' end

declare @timeSeconds varchar(10)
select @timeSeconds = case when @DateG =''H'' then ''1800''
					 when @DateG =''D'' then  ''216000''
					 when @DateG =''O'' then ''3600'' end

select @CamGral = case when @CamGral =''Campaña'' or @CamGral =''Campaign'' or @CamGral =''Especialidad'' or @CamGral =''ACD group'' then ''C'' 
					   when @CamGral =''General'' or @CamGral =''All Information'' then ''G'' end

set @Sql = ''create table #RtnValue(
[Fecha] datetime,
''+
case @tipo when 1 then
case @CamGral when ''C'' then ''[Campana] varchar(max),'' when ''G'' then '''' end
else
case @CamGral when ''C'' then ''[Grupo ACD] varchar(max),'' when ''G'' then '''' end end +
''[Puerto] varchar(max),
[Tiempo Ocupado] int,
[Llamadas] int,
[% Ocupacion] decimal(10,2),
fechafin datetime,
fechaInicio datetime,
fechaFinal datetime)

create nonclustered index ix_RtnValue on #RtnValue(
[fecha] DESC,
[fechafin] DESC
)

create nonclustered index ix_RtnValue2 on #RtnValue(
[fechaInicio] DESC,
[fechafinal] DESC
)

create table #RtnValue2(
[Fecha] datetime,
''+
case @tipo when 1 then
case @CamGral when ''C'' then ''[Campana] varchar(max),'' when ''G'' then '''' end
else
case @CamGral when ''C'' then ''[Grupo ACD] varchar(max),'' when ''G'' then '''' end end +
''[Puerto] varchar(max),
[Tiempo Ocupado] int,
[Llamadas] int,
[% Ocupacion] decimal(10,2),
fechafin datetime,
fechaInicio datetime,
fechaFinal datetime)

create nonclustered index ix_RtnValue on #RtnValue2(
[fecha] DESC,
[fechafin] DESC
) 
''
if (@CamGral = ''C'')
begin
	set @Sql= @Sql + ''insert into #RtnValue
	select fecha, ''+
	case @tipo when 1 then
	case @CamGral when ''C'' then ''[Campana],'' when ''G'' then '''' end
	else
	case @CamGral when ''C'' then ''[Grupo ACD],'' when ''G'' then '''' end end +
	 '' isnull( dia.descripcion, ''''Pto '''' + convert(varchar(100),detail.[Pto])), 
	[Tiempo Ocupado], [Llamadas], [% Ocupacion], fechafin, [fechaInicio], fechafinal
	from (''

	set @Sql = @Sql + ''select '' + case @DateG when ''H'' then ''convert(varchar(21),timegroup,121) '' when ''D'' then '' CONVERT(varchar(10), timegroup, 121) + '''' 00:00:00'''' '' when ''O'' then '' CONVERT(varchar(13), timegroup, 121) + '''':00:00'''' '' end + '' [Fecha] '' + 
	case @tipo when 1 then
	case @CamGral when ''C'' then '',c.cam_descripcion as [Campana], ps.port as [Pto]'' when ''G'' then '',ps.port as [Pto]'' end
	else
	case @CamGral when ''C'' then '',c.descripcion as [Grupo ACD], ps.port as [Pto]'' when ''G'' then '',ps.port as [Pto]'' end end +
	'', sum(tBusy) as [Tiempo Ocupado], sum(Calls) as [Llamadas], 0.00 as [% Ocupacion], 
	'' +
	''dateadd( ss, sum(tbusy),convert(varchar(21),timegroup,121)) as fechafin,
	convert(varchar(21),timegroup,121)  [fechaInicio],
	case when datepart(mi,dateadd( ss, sum(tbusy),convert(varchar(21),timegroup,121)))
	between 0 and 30 then convert(varchar(13),dateadd( ss, sum(tbusy),convert(varchar(21),timegroup,121)),121) + '''':30:00.000''''
	when datepart(mi,dateadd( ss, sum(tbusy),convert(varchar(21),timegroup,121)))
	between 30 and 59 then convert(varchar(13),dateadd(hh,1,dateadd(ss, sum(tbusy),convert(varchar(21),timegroup,121))),121) + '''':00:00.000'''' end as fechafinal
	''+
	''from ccGenOutPortStats ps'' +
	case @tipo when 1 then
	case @CamGral when ''C'' then '' left join cccamps c on (ps.cam_id = c.cam_id)'' when ''G'' then '''' end
	else 
	case @CamGral when ''C'' then '' left join ccinbound c on (ps.cam_id = c.inbound_id)'' when ''G'' then '''' end end 
	+ '' where'' +
	case when @cbjUno <> '''' then '' ps.cam_id in ('' + @cbjUno + '') and'' else '''' end + case when replace(@cbjDos,''-'','''') <> '''' then '' ps.port between '' + @desde + '' and ''+ @hasta +'' and'' else '''' end + case when @tipo < 2 then '' tipo = '' + convert(varchar(3),@tipo) + '' and'' else '''' end  + '' timegroup >= '''''' + @fini + '''''' AND timegroup < '''''' + @ffin + '''''' group by '' +
	case @DateG when ''H'' then '' timegroup '' when ''D'' then '' CONVERT(varchar(10), timegroup, 121) + '''' 00:00:00'''' ''  when ''O'' then '' CONVERT(varchar(13), timegroup, 121) + '''':00:00'''' '' end +
	case @tipo when 1 then
	case @CamGral when ''C'' then '',c.cam_descripcion,ps.port'' when ''G'' then '',ps.port'' end 
	else
	case @CamGral when ''C'' then '',c.descripcion,ps.port'' when ''G'' then '',ps.port'' end end
	+ '') detail
	full outer join ccoDialers dia on (dia.puerto = detail.puerto)
	where fechainicio is not null''
end
else
begin
	set @CamGral = ''C''
	set @tipo = 1

	set @Sql= @Sql + ''insert into #RtnValue
	select fecha, 
	isnull( dia.descripcion, ''''Pto '''' + convert(varchar(100),detail.[Pto])), 
	[Tiempo Ocupado], [Llamadas], [% Ocupacion], fechafin, [fechaInicio], fechafinal
	from (''

	set @Sql = @Sql + ''select '' + case @DateG when ''H'' then ''convert(varchar(21),timegroup,121) '' when ''D'' then '' CONVERT(varchar(10), timegroup, 121) + '''' 00:00:00'''' '' when ''O'' then '' CONVERT(varchar(13), timegroup, 121) + '''':00:00'''' '' end + '' [Fecha] '' + 
	case @tipo when 1 then
	case @CamGral when ''C'' then '',c.cam_descripcion as [Campana], ps.port as [Pto]'' when ''G'' then '',ps.port as [Pto]'' end
	else
	case @CamGral when ''C'' then '',c.descripcion as [Grupo ACD], ps.port as [Pto]'' when ''G'' then '',ps.port as [Pto]'' end end +
	'', sum(tBusy) as [Tiempo Ocupado], sum(Calls) as [Llamadas], 0.00 as [% Ocupacion], 
	'' +
	''dateadd( ss, sum(tbusy),convert(varchar(21),timegroup,121)) as fechafin,
	convert(varchar(21),timegroup,121)  [fechaInicio],
	case when datepart(mi,dateadd( ss, sum(tbusy),convert(varchar(21),timegroup,121)))
	between 0 and 30 then convert(varchar(13),dateadd( ss, sum(tbusy),convert(varchar(21),timegroup,121)),121) + '''':30:00.000''''
	when datepart(mi,dateadd( ss, sum(tbusy),convert(varchar(21),timegroup,121)))
	between 30 and 59 then convert(varchar(13),dateadd(hh,1,dateadd(ss, sum(tbusy),convert(varchar(21),timegroup,121))),121) + '''':00:00.000'''' end as fechafinal
	''+
	''from ccGenOutPortStats ps'' +
	case @tipo when 1 then
	case @CamGral when ''C'' then '' left join cccamps c on (ps.cam_id = c.cam_id)'' when ''G'' then '''' end
	else 
	case @CamGral when ''C'' then '' left join ccinbound c on (ps.cam_id = c.inbound_id)'' when ''G'' then '''' end end 
	+ '' where'' +
	case when @cbjUno <> '''' then '' ps.cam_id in ('' + @cbjUno + '') and'' else '''' end + case when replace(@cbjDos,''-'','''') <> '''' then '' ps.port between '' + @desde + '' and ''+ @hasta +'' and'' else '''' end + case when @tipo < 2 then '' tipo = '' + convert(varchar(3),@tipo) + '' and'' else '''' end  + '' timegroup >= '''''' + @fini + '''''' AND timegroup < '''''' + @ffin + '''''' group by '' +
	case @DateG when ''H'' then '' timegroup '' when ''D'' then '' CONVERT(varchar(10), timegroup, 121) + '''' 00:00:00'''' ''  when ''O'' then '' CONVERT(varchar(13), timegroup, 121) + '''':00:00'''' '' end +
	case @tipo when 1 then
	case @CamGral when ''C'' then '',c.cam_descripcion,ps.port'' when ''G'' then '',ps.port'' end 
	else
	case @CamGral when ''C'' then '',c.descripcion,ps.port'' when ''G'' then '',ps.port'' end end
	+ '') detail
	full outer join ccoDialers dia on (dia.puerto = detail.puerto)
	where fechainicio is not null

	''

	set @tipo = 0

	set @Sql= @Sql + ''insert into #RtnValue
	select fecha, 
	isnull( dia.descripcion, ''''Pto '''' + convert(varchar(100),detail2.[Pto])), 
	[Tiempo Ocupado], [Llamadas], [% Ocupacion], fechafin, [fechaInicio], fechafinal
	from (''

	set @Sql = @Sql + '' select '' + case @DateG when ''H'' then ''convert(varchar(21),timegroup,121) '' when ''D'' then '' CONVERT(varchar(10), timegroup, 121) + '''' 00:00:00'''' '' when ''O'' then '' CONVERT(varchar(13), timegroup, 121) + '''':00:00'''' '' end + '' [Fecha] '' + 
	case @tipo when 1 then
	case @CamGral when ''C'' then '',c.cam_descripcion as [Campana], ps.port as [Pto]'' when ''G'' then '',ps.port as [Pto]'' end
	else
	case @CamGral when ''C'' then '',c.descripcion as [Grupo ACD], ps.port as [Pto]'' when ''G'' then '',ps.port as [Pto]'' end end +
	'', sum(tBusy) as [Tiempo Ocupado], sum(Calls) as [Llamadas], 0.00 as [% Ocupacion], 
	'' +
	''dateadd( ss, sum(tbusy),convert(varchar(21),timegroup,121)) as fechafin,
	convert(varchar(21),timegroup,121)  [fechaInicio],
	case when datepart(mi,dateadd( ss, sum(tbusy),convert(varchar(21),timegroup,121)))
	between 0 and 30 then convert(varchar(13),dateadd( ss, sum(tbusy),convert(varchar(21),timegroup,121)),121) + '''':30:00.000''''
	when datepart(mi,dateadd( ss, sum(tbusy),convert(varchar(21),timegroup,121)))
	between 30 and 59 then convert(varchar(13),dateadd(hh,1,dateadd(ss, sum(tbusy),convert(varchar(21),timegroup,121))),121) + '''':00:00.000'''' end as fechafinal
	''+
	''from ccGenOutPortStats ps'' +
	case @tipo when 1 then
	case @CamGral when ''C'' then '' left join cccamps c on (ps.cam_id = c.cam_id)'' when ''G'' then '''' end
	else 
	case @CamGral when ''C'' then '' left join ccinbound c on (ps.cam_id = c.inbound_id)'' when ''G'' then '''' end end 
	+ '' where'' +
	case when @cbjUno <> '''' then '' ps.cam_id in ('' + @cbjUno + '') and'' else '''' end + case when replace(@cbjDos,''-'','''') <> '''' then '' ps.port between '' + @desde + '' and ''+ @hasta +'' and'' else '''' end + case when @tipo < 2 then '' tipo = '' + convert(varchar(3),@tipo) + '' and'' else '''' end  + '' timegroup >= '''''' + @fini + '''''' AND timegroup < '''''' + @ffin + '''''' group by '' +
	case @DateG when ''H'' then '' timegroup '' when ''D'' then '' CONVERT(varchar(10), timegroup, 121) + '''' 00:00:00'''' ''  when ''O'' then '' CONVERT(varchar(13), timegroup, 121) + '''':00:00'''' '' end +
	case @tipo when 1 then
	case @CamGral when ''C'' then '',c.cam_descripcion,ps.port'' when ''G'' then '',ps.port'' end 
	else
	case @CamGral when ''C'' then '',c.descripcion,ps.port'' when ''G'' then '',ps.port'' end end
	+ '') detail2
	full outer join ccoDialers dia on (dia.puerto = detail2.puerto)
	where fechainicio is not null''

	set @CamGral = ''G''
end

set @Sql = @Sql + ''

delete #RtnValue
where [Tiempo Ocupado] = 0

declare @starttime datetime
declare @stoptime datetime
declare @number int

select @starttime = min(Fecha), @stoptime = max(fecha)
from #RtnValue

select @number = 0

CREATE TABLE #times(
[ID] INT primary key,
[Start] DATETIME,
[Stop] DATETIME
)

create nonclustered index ix_times on #times(
[Start] DESC,
[Stop] DESC
)
create nonclustered index ix_times2 on #times(
[Start] DESC
)

while @number <= (datediff(mi,@starttime,getdate())/'' + @time + '')
begin
	insert into #times
	SELECT [Hour] = @number,
	StartTime = DATEADD(mi, @number*''+ @time +'', @starttime),
	EndTime = DATEADD(mi, (@number+1)*''+ @time +'', @StartTime)

	set @number = @number +1
end

delete #RtnValue
where llamadas = 0

insert into #RtnValue2
select *
from #RtnValue

where datediff(ss,fechainicio,fechafin) > '' + @timeSeconds + ''

delete #RtnValue
where datediff(ss,fechainicio,fechafin) > '' + @timeSeconds + ''

insert into #RtnValue
select th.start as fecha, '' +
case @tipo when 1 then
case @CamGral when ''C'' then ''t.[Campana],'' when ''G'' then '''' end
else
case @CamGral when ''C'' then ''t.[Grupo ACD],'' when ''G'' then '''' end end + '' t.Pto, 
case when th.start = t.fecha and fechafin > th.stop then datediff(ss,th.start,th.stop) 
when th.start < t.fecha then datediff(ss,fecha,th.stop) 
when th.start > t.fecha and th.stop < t.fechafin then datediff(ss,th.start, th.stop) 
else datediff(ss,th.start,fechafin) end as tBusy, 
case when th.start = t.fecha and fechafin > th.stop then 0 
when th.start < t.fecha then t.llamadas
when th.start > t.fecha and th.stop < t.fechafin then t.llamadas
else t.llamadas end as llamadas, 0.00,
th.stop, th.start, th.stop
from #RtnValue2 t
join #times th on (t.fecha > th.Start and t.fecha < th.stop) OR th.Start between t.fecha and t.fechafin

select fecha, ''+
case @tipo when 1 then
case @CamGral when ''C'' then ''[Campana],'' when ''G'' then '''' end
else
case @CamGral when ''C'' then ''[Grupo ACD],'' when ''G'' then '''' end end +
+'' Pto, dbo.fGetHHmmSS([Tiempo Ocupado]) as [Tiempo Ocupado], llamadas, 
dbo.fPorcentaje([Tiempo Ocupado],1800) as [% Ocupacion]
from #RtnValue
''

set @Sql = @Sql + ''
Union all

select '''''''' as [Fecha]'' +
case @tipo when 1 then
case @CamGral when ''C'' then '','''''''' as [Campana], ''''Total'''' as [Puerto]'' when ''G'' then '',''''Total'''' as [Pto]'' end
else
case @CamGral when ''C'' then '','''''''' as [Grupo ACD], ''''Total'''' as [Puerto]'' when ''G'' then '',''''Total'''' as [Pto]'' end end +

'', dbo.fGetHHmmSS(sum([Tiempo Ocupado])) as [Tiempo Ocupado], 
sum(llamadas) as [Llamadas], 
convert(decimal(10,2),(sum([Tiempo Ocupado]) * 100.00) / (count(distinct(Puerto)) * datediff(ss,''''''+ @fini + '''''',''''''+ @ffin +''''''))) as [% Ocupacion] 
from #RtnValue

drop table #RtnValue
drop table #RtnValue2
drop table #times
''

if @idioma = 1
begin
	set @Sql = replace(@Sql, ''Fecha'', ''Date'') 
	set @Sql = replace(@Sql, ''Campana'', ''Campaign'')
	set @Sql = replace(@Sql, ''Pto'', ''Port'') 
	set @Sql = replace(@Sql, ''Llamadas'', ''Call'') 
	set @Sql = replace(@Sql, ''Ocupacion'', ''Ocupation'')
	set @Sql = replace(@Sql, ''Grupo ACD'', ''ACD Group'') 
	set @Sql = replace(@Sql, ''Tiempo Ocupado'',''Busy Time'')
end
if @idioma = 0
begin
	set @Sql = replace(@Sql, ''Pto'', ''Puerto'') 
end

begin try
	exec(@Sql)
	--print(@Sql)
end try
begin catch
	declare @error varchar(255)
	set @error=''Se presento un problema al generar el reporte, causa del mismo: "''+ERROR_MESSAGE()+''"''
	select @error
end catch
set nocount off'
		
	EXEC(@Sql)

		set @process = 'NuxibaReportsMaintenancePlan - Delete and Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [NuxibaReportsMaintenancePlan]    Script Date: 02/11/2014 18:16:28 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''NuxibaReportsMaintenancePlan'')
EXEC msdb.dbo.sp_delete_job @job_name=N''NuxibaReportsMaintenancePlan'', @delete_unused_schedule=1

/****** Object:  Job [NuxibaReportsMaintenancePlan]    Script Date: 02/11/2014 18:16:51 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 02/11/2014 18:16:51 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''NuxibaReportsMaintenancePlan'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''NuxibaReportsMaintenancePlan'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Database Integrity Task]    Script Date: 02/11/2014 18:16:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Database Integrity Task'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC CHECKDB WITH NO_INFOMSGS'', 
		@database_name=N''ccReports'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Database Task]    Script Date: 02/11/2014 18:16:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Database Task'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKDATABASE(N''''ccReports'''', 10, TRUNCATEONLY)'', 
		@database_name=N''ccReports'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Log Task]    Script Date: 02/11/2014 18:16:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Log Task'', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKFILE(''''ccReports_Log'''',1)'', 
		@database_name=N''ccReports'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Reorginize Index Task]    Script Date: 02/11/2014 18:16:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Reorginize Index Task'', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''ALTER INDEX [IX_ccCalifCamp] ON [dbo].[ccCalifCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCalifCamp_1] ON [dbo].[ccCalifCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_1] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_2] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccCallsIn_3] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCallsIn] ON [dbo].[ccCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccCamps] ON [dbo].[ccCamps] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [usuario] ON [dbo].[ccCampsAgente] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cccatgpo_camp] ON [dbo].[cccatgpo_camp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccDNIS] ON [dbo].[ccDNIS] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGen900] ON [dbo].[ccGen900] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [DF_ccGenAgent_tnot_av] ON [dbo].[ccGenAgent] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenAgent] ON [dbo].[ccGenAgent] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenAgentNotReady] ON [dbo].[ccGenAgentNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenChart] ON [dbo].[ccGenChart] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInAbnd] ON [dbo].[ccGenInAbnd] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInAbndWG] ON [dbo].[ccGenInAbndWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInAnsw] ON [dbo].[ccGenInAnsw] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInAnswWG] ON [dbo].[ccGenInAnswWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCalif] ON [dbo].[ccGenInCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCalifWG] ON [dbo].[ccGenInCalifWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCall] ON [dbo].[ccGenInCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCallDNI] ON [dbo].[ccGenInCallDNI] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInCallWG] ON [dbo].[ccGenInCallWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInSpec] ON [dbo].[ccGenInSpec] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInSpecWG] ON [dbo].[ccGenInSpecWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenInsubCalif] ON [dbo].[ccGenInSubCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccGenMktIntervaloSalida] ON [dbo].[ccGenMktIntervaloSalida] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCall] ON [dbo].[ccGenOutCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallCalif] ON [dbo].[ccGenOutCallCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallCalifWG] ON [dbo].[ccGenOutCallCalifWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [campana] ON [dbo].[ccGenOutCallDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallDials] ON [dbo].[ccGenOutCallDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [tipoMarcacion] ON [dbo].[ccGenOutCallDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallDialsWG] ON [dbo].[ccGenOutCallDialsWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [tipoMarcacion] ON [dbo].[ccGenOutCallDialsWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [WorkGroup] ON [dbo].[ccGenOutCallDialsWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCallWG] ON [dbo].[ccGenOutCallWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCamp] ON [dbo].[ccGenOutCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCampWG] ON [dbo].[ccGenOutCampWG] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccGenOutCstoRes_userId] ON [dbo].[ccGenOutCstoResumen] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutCstoResumen] ON [dbo].[ccGenOutCstoResumen] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccGenOutDialCamp] ON [dbo].[ccGenOutDialCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccGenOutDialCamp_1] ON [dbo].[ccGenOutDialCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutPortStats] ON [dbo].[ccGenOutPortStats] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenOutsubCalif] ON [dbo].[ccGenOutSubCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IndiceResumen] ON [dbo].[ccGenResumenAgente] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSession] ON [dbo].[ccGenSession] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionAgent] ON [dbo].[ccGenSessionAgent] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionInCall] ON [dbo].[ccGenSessionInCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionInSpec] ON [dbo].[ccGenSessionInSpec] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionNotReady] ON [dbo].[ccGenSessionNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionOutCall] ON [dbo].[ccGenSessionOutCall] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccGenSessionOutCamp] ON [dbo].[ccGenSessionOutCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccInbound] ON [dbo].[ccInbound] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [ccLogAgentesDia_fecAsc] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [ccLogAgentesDia_tipoAgeId] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [ccLogAgentesDia_userId] ON [dbo].[ccLogAgentesDia] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccLogAgentesDia_Dialog] ON [dbo].[ccLogAgentesDia_Dialog] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNR_fecha] ON [dbo].[ccLogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccLogAgentesNR_userId] ON [dbo].[ccLogAgentesNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [ccLogLogin_fecha] ON [dbo].[ccLogLogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [ccLogLogin_tipomov] ON [dbo].[ccLogLogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [ccLogLogin_user] ON [dbo].[ccLogLogin] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallBacks] ON [dbo].[ccoCallBacks] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_1] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_2] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_3] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_4] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_5] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_6] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOut_7] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoCallsOut] ON [dbo].[ccoCallsOut] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_1] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_10] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_2] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_3] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_4] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_5] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_6] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_7] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_8] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoCallsOutSource_9] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccodialercamp] ON [dbo].[ccoDialerCamp] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccodialers] ON [dbo].[ccoDialers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_1] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_2] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_3] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_4] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_5] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_6] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_7] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccoLogDials_8] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccoLogDials] ON [dbo].[ccoLogDials] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicion] ON [dbo].[ccPosicion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccPosicion] ON [dbo].[ccPosicion] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicionCamps1] ON [dbo].[ccPosicionCamps] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicionCamps2] ON [dbo].[ccPosicionCamps] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicionCamps3] ON [dbo].[ccPosicionCamps] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicionEspecialidad1] ON [dbo].[ccPosicionEspecialidad] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicionEspecialidad2] ON [dbo].[ccPosicionEspecialidad] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccPosicionEspecialidad3] ON [dbo].[ccPosicionEspecialidad] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIAAreaWorkGroup] ON [dbo].[ccRIAAreaWorkGroup] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccRIACat_Areas] ON [dbo].[ccRIACat_Areas] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_2] ON [dbo].[ccRIAWorkGroup_Calid] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_WGCal_id] ON [dbo].[ccRIAWorkGroup_Calid] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_cccRIAWorkGroup_logdial_id_2] ON [dbo].[ccRIAWorkGroup_logdial_id] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_WGlogDial_id] ON [dbo].[ccRIAWorkGroup_logdial_id] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccSup_Usuario] ON [dbo].[ccSup_Usuario] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccSupervisorCam] ON [dbo].[ccSupervisorCam] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [IX_ccTipoCalif] ON [dbo].[ccTipoCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoCalif] ON [dbo].[ccTipoCalif] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoCalifOUT] ON [dbo].[ccTipoCalifOUT] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoCalifSub] ON [dbo].[ccTipoCalifSub] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoSubCalifOUT] ON [dbo].[ccTipoCalifSubOUT] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoNotReady] ON [dbo].[ccTipoNotReady] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoResultadoDial] ON [dbo].[ccTipoResultadoDial] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccTipoStatusAgente] ON [dbo].[ccTipoStatusAgente] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_ccUsers] ON [dbo].[ccUsers] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cstoProvedor] ON [dbo].[cstoProvedor] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cstoTarifa] ON [dbo].[cstoTarifa] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_cstoTipoLlamada] ON [dbo].[cstoTipoLlamada] REORGANIZE WITH ( LOB_COMPACTION = ON )
ALTER INDEX [PK_IVR_ID_1] ON [dbo].[IVRCallsIn] REORGANIZE WITH ( LOB_COMPACTION = ON )'', 
		@database_name=N''ccReports'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Rebuild Index Task]    Script Date: 02/11/2014 18:16:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Rebuild Index Task'', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''ALTER INDEX [IX_ccCalifCamp] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCalifCamp_1] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_1] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_2] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccCallsIn_3] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCallsIn] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccCamps] ON [dbo].[ccCamps] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [usuario] ON [dbo].[ccCampsAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cccatgpo_camp] ON [dbo].[cccatgpo_camp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccDNIS] ON [dbo].[ccDNIS] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGen900] ON [dbo].[ccGen900] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [DF_ccGenAgent_tnot_av] ON [dbo].[ccGenAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenAgent] ON [dbo].[ccGenAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenAgentNotReady] ON [dbo].[ccGenAgentNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenChart] ON [dbo].[ccGenChart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInAbnd] ON [dbo].[ccGenInAbnd] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInAbndWG] ON [dbo].[ccGenInAbndWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInAnsw] ON [dbo].[ccGenInAnsw] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInAnswWG] ON [dbo].[ccGenInAnswWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCalif] ON [dbo].[ccGenInCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCalifWG] ON [dbo].[ccGenInCalifWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCall] ON [dbo].[ccGenInCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCallDNI] ON [dbo].[ccGenInCallDNI] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInCallWG] ON [dbo].[ccGenInCallWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInSpec] ON [dbo].[ccGenInSpec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInSpecWG] ON [dbo].[ccGenInSpecWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenInsubCalif] ON [dbo].[ccGenInSubCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccGenMktIntervaloSalida] ON [dbo].[ccGenMktIntervaloSalida] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCall] ON [dbo].[ccGenOutCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallCalif] ON [dbo].[ccGenOutCallCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallCalifWG] ON [dbo].[ccGenOutCallCalifWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [campana] ON [dbo].[ccGenOutCallDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallDials] ON [dbo].[ccGenOutCallDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [tipoMarcacion] ON [dbo].[ccGenOutCallDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallDialsWG] ON [dbo].[ccGenOutCallDialsWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [tipoMarcacion] ON [dbo].[ccGenOutCallDialsWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [WorkGroup] ON [dbo].[ccGenOutCallDialsWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCallWG] ON [dbo].[ccGenOutCallWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCamp] ON [dbo].[ccGenOutCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCampWG] ON [dbo].[ccGenOutCampWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccGenOutCstoRes_userId] ON [dbo].[ccGenOutCstoResumen] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutCstoResumen] ON [dbo].[ccGenOutCstoResumen] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccGenOutDialCamp] ON [dbo].[ccGenOutDialCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccGenOutDialCamp_1] ON [dbo].[ccGenOutDialCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutPortStats] ON [dbo].[ccGenOutPortStats] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenOutsubCalif] ON [dbo].[ccGenOutSubCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IndiceResumen] ON [dbo].[ccGenResumenAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSession] ON [dbo].[ccGenSession] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionAgent] ON [dbo].[ccGenSessionAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionInCall] ON [dbo].[ccGenSessionInCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionInSpec] ON [dbo].[ccGenSessionInSpec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionNotReady] ON [dbo].[ccGenSessionNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionOutCall] ON [dbo].[ccGenSessionOutCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccGenSessionOutCamp] ON [dbo].[ccGenSessionOutCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccInbound] ON [dbo].[ccInbound] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [ccLogAgentesDia_fecAsc] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [ccLogAgentesDia_tipoAgeId] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [ccLogAgentesDia_userId] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccLogAgentesDia_Dialog] ON [dbo].[ccLogAgentesDia_Dialog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNR_fecha] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccLogAgentesNR_userId] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [ccLogLogin_fecha] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [ccLogLogin_tipomov] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [ccLogLogin_user] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallBacks] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_1] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_2] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_3] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_4] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_5] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_6] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOut_7] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoCallsOut] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_1] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_10] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_2] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_3] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_4] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_5] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_6] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_7] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_8] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoCallsOutSource_9] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccodialercamp] ON [dbo].[ccoDialerCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccodialers] ON [dbo].[ccoDialers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_1] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_2] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_3] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_4] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_5] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_6] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_7] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccoLogDials_8] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccoLogDials] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicion] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccPosicion] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicionCamps1] ON [dbo].[ccPosicionCamps] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicionCamps2] ON [dbo].[ccPosicionCamps] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicionCamps3] ON [dbo].[ccPosicionCamps] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicionEspecialidad1] ON [dbo].[ccPosicionEspecialidad] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicionEspecialidad2] ON [dbo].[ccPosicionEspecialidad] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccPosicionEspecialidad3] ON [dbo].[ccPosicionEspecialidad] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIAAreaWorkGroup] ON [dbo].[ccRIAAreaWorkGroup] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccRIACat_Areas] ON [dbo].[ccRIACat_Areas] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccRIAWorkGroup_Calid_2] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_WGCal_id] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_cccRIAWorkGroup_logdial_id_2] ON [dbo].[ccRIAWorkGroup_logdial_id] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_WGlogDial_id] ON [dbo].[ccRIAWorkGroup_logdial_id] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccSup_Usuario] ON [dbo].[ccSup_Usuario] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccSupervisorCam] ON [dbo].[ccSupervisorCam] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [IX_ccTipoCalif] ON [dbo].[ccTipoCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoCalif] ON [dbo].[ccTipoCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoCalifOUT] ON [dbo].[ccTipoCalifOUT] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoCalifSub] ON [dbo].[ccTipoCalifSub] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoSubCalifOUT] ON [dbo].[ccTipoCalifSubOUT] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoNotReady] ON [dbo].[ccTipoNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoResultadoDial] ON [dbo].[ccTipoResultadoDial] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccTipoStatusAgente] ON [dbo].[ccTipoStatusAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_ccUsers] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cstoProvedor] ON [dbo].[cstoProvedor] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cstoTarifa] ON [dbo].[cstoTarifa] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_cstoTipoLlamada] ON [dbo].[cstoTipoLlamada] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
ALTER INDEX [PK_IVR_ID_1] ON [dbo].[IVRCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )'', 
		@database_name=N''ccReports'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Statistics Task]    Script Date: 02/11/2014 18:16:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Update Statistics Task'', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''UPDATE STATISTICS [dbo].[ccCalifCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCallsIn] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCallsReject] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCamps] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccCampsAgente] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cccatgpo_camp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccDNIS] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGen900] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenAgent] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenAgentNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenChart] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInAbnd] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInAbndWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInAnsw] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInAnswWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCalifWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCallDNI] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInCallWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInSpec] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInSpecWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenInSubCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenMktIntervaloSalida] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallCalifWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallDials] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallDialsWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCallWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCampWG] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutCstoResumen] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutDialCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutPortStats] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenOutSubCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenResumenAgente] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSession] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionAgent] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionInCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionInSpec] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionOutCall] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccGenSessionOutCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccgenTelMarcados] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInbound] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccInboundAgentes] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgentesDia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgentesDia_Dialog] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogAgentesNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogLogin] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccLogTransfers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoCallBacks] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoCallsOut] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoCallsOutSource] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoDialerCamp] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoDialers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccoLogDials] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPosicion] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPosicionCamps] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccPosicionEspecialidad] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAAreaWorkGroup] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_Areas] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIACat_WorkGroup] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAWorkGroup_Calid] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAWorkGroup_logdial_id] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccRIAWorkGroupUsers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccSettings] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccStatusLLamada] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccSup_Usuario] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccSupervisorCam] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalif] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalifOUT] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalifSub] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoCalifSubOUT] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoNotReady] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoResultadoDial] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoStatusAgente] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccTipoUsers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[ccUsers] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cstoProvedor] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cstoTarifa] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[cstoTipoLlamada] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[Exp_Jobs] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[exportReports] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRCallsIn] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRLlamadas] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVROptions] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[IVRStructure] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[telefonosConferencia] 
WITH FULLSCAN
UPDATE STATISTICS [dbo].[telefonosTransferencia] 
WITH FULLSCAN'', 
		@database_name=N''ccReports'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clean Up History Task]    Script Date: 02/11/2014 18:16:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Clean Up History Task'', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''declare @dt datetime 
select @dt = getdate()

exec msdb.dbo.sp_delete_backuphistory @dt

EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date=@dt

EXECUTE msdb..sp_maintplan_delete_log null,null,@dt'', 
		@database_name=N''ccReports'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Back Up Database Task]    Script Date: 02/11/2014 18:16:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Back Up Database Task'', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @currentdate datetime
declare @date varchar(200)
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = ''''ccReports_backup_MP'''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''.bak''''

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''HKEY_LOCAL_MACHINE'''', N''''Software\Microsoft\MSSQLServer\MSSQLServer'''',N''''BackupDirectory''''

select @rutaBak = Data
from #RutaBak

select @rutaBak= @rutaBak + ''''\'''' + @date

drop table #RutaBak

BACKUP DATABASE [ccReports] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10
'', 
		@database_name=N''ccReports'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Maintenance Clean Up Task]    Script Date: 02/11/2014 18:16:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Maintenance Clean Up Task'', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @currentdate datetime
declare @date datetime
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = dateadd(ww,-3,getdate())

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''HKEY_LOCAL_MACHINE'''', N''''Software\Microsoft\MSSQLServer\MSSQLServer'''',N''''BackupDirectory''''

select @rutaBak = Data
from #RutaBak

EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''bak'''',@date

drop table #RutaBak'', 
		@database_name=N''ccReports'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
 
 	EXEC(@Sql)
 	
------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
