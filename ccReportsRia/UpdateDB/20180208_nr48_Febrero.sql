/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Hugo Longoria
Date: 2018/01/17
Description:
**********************************************************************************************
CW-1043 - faltan relaciones en las tablas de survey
**********************************************************************************************
Database: ccReportsRia
Required version: 46


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =48
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try

	set @process = 'CW-1428 - Alter COLUMN RepMKTAgentes.agentName'
	set @Sql= 'ALTER TABLE RepMKTAgentes ALTER COLUMN agentName varchar(255)'
	EXEC(@sql)


	set @process = 'CW-1428 - SP ReportsMasterProcess'
	set @Sql= 'ALTER procedure [dbo].[ReportsMasterProcess] as

set nocount on

declare @dateStart datetime
declare @delay int
declare @strDelay nvarchar(8)
declare @reportName nvarchar(100), @replicationName nvarchar(100)
declare @numOfReports int,@numOfReplications int
declare @repDelay int
declare @repStrDelay nvarchar(8)
declare @minReplication int,@minReports int
DECLARE @dateBegin DATETIME,@dateSP datetime

---shedule
declare @schedule_id int,@nameSchudule sysname,@job_id uniqueidentifier,@scheduleTime int
declare @isSunday tinyint,  @hourSunday tinyint,@minSunday tinyint

--------------------------- Creacion tablas cada domingo ---------------------------
select  @isSunday = datepart(dw, getdate()),@hourSunday = datepart(hh, getdate()), @minSunday = datepart(mi, getdate())

if @isSunday=1 and @hourSunday = 3 and @minSunday>=30 begin

	if exists (select * from sys.tables where name = ''logsReportsMaster'')
			drop table logsReportsMaster

	create table [logsReportsMaster](
		[id] int identity not null primary key,
		[name] varchar(100) not null,
		[status] tinyint not null,
		[dateStart] datetime not null,
		[dateEnd] datetime not null,
		[error] varchar(max) not null,
		[maxTime] int not null)

	CREATE NONCLUSTERED INDEX [IX_logsReportsMaster1] ON [dbo].[logsReportsMaster]
	(
		[name] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

	CREATE NONCLUSTERED INDEX [IX_logsReportsMaster2] ON [dbo].[logsReportsMaster]
	(
	[status] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

	CREATE NONCLUSTERED INDEX [IX_logsReportsMaster3] ON [dbo].[logsReportsMaster]
	(
	[maxTime] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

end

--------------------------- Termina Creacion tablas cada domingo ---------------------------

set @dateStart = getdate()
set @delay = 0
set @strDelay = ''''
set @reportName = ''''
set @replicationName = ''''
set @numOfReports = 0
set @numOfReplications = 0
set @repDelay = 0
set @repStrDelay = ''''
set @minReplication = 0
set @minReports = 0
set @scheduleTime = 10

--- obtiene el job_id, y el nombre del schedule_id asocioado al job reports Master
select  @job_id=A.job_id,@schedule_id=C.schedule_id, @nameSchudule=C.name,@scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name=''ReportsMasterProcess''

-- obtiene los valores de los settings para el tiempo ejecucion de las replicas  y los jobs
select @minReplication = cast(substring(valor, 0, charindex(''|'',valor)) as int) from ccsettings where setting_id = 28
select @minReports = cast(substring(valor, charindex(''|'',valor) + 1, len(valor)) as int) from ccsettings where setting_id = 28

---- revisar los tiempos y actulizar el setting
if (@minReplication + @minReports) > @scheduleTime
begin
	set @scheduleTime= @minReplication + @minReports
	EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
end

set @minReplication = @minReplication * 60

-------------------- Revision que no existe conflictos  -----------------------------------------

if exists (select * from sys.triggers where name = N''trigPosicionEspecialidad'' and parent_id = OBJECT_ID(N''ccloglogin''))
	DROP TRIGGER trigPosicionEspecialidad


-------------------- ejecuccion de las replicas -----------------------------------------

create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%ccReportsRia- 0%'' and [name] like ''%CCenterRia%''

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%ccReportsRia- 0%'' and [name] like ''%CCRecorderRia%'' order by [name]

select @numOfReplications = count(*) from #replications with(nolock)

set @repDelay = floor(cast(@minReplication as decimal) / cast(@numOfReplications as decimal))

set @repStrDelay = CONVERT(char(8), DATEADD(second, @repDelay, ''00:00:00''), 108)

set @dateSP = getdate()

while(select count(*) from #replications with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @replicationName


	update #replications with(rowlock) 	set flag = 1 where [name] = @replicationName

	WAITFOR DELAY ''00:00:01''

	while(
		SELECT count(*) FROM msdb.dbo.sysjobactivity ja
		LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
		INNER JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
		INNER JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
		WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions   ORDER BY agent_start_date DESC)
		AND start_execution_date is not null AND stop_execution_date is null and j.name=@replicationName
	) > 0
	begin
		WAITFOR DELAY ''00:00:01''
	end
end

drop table #replications

-------------------- ejecuccion de las construnccion de los reportes -----------------------------------------

declare @descError nvarchar(max)
declare @i int,@count int
declare @name sysname,@sql nvarchar(max)



create table #tmpProcedureReports( id int, name sysname)

insert into #tmpProcedureReports
select ROW_NUMBER() OVER(ORDER BY [name] ) AS id,[name] from  sys.procedures where [name] like ''ccspRep%'' and [name] not in(''ccspRepCatalogos'',''ccsprepLogAgentriaseparate'')

insert into [logsReportsMaster] (name,status,dateStart,dateEnd,error,maxTime)
select name,0,''19000101'',''19000101'','''',@scheduleTime from #tmpProcedureReports

select @i=1,@count =count(*) from #tmpProcedureReports

while @i<=@count
begin
	select @name = name from #tmpProcedureReports where id=@i

	set @sql =''EXEC ''+ @name +'' @action=1''
	set @dateSP = getdate()
	begin try

		exec (@sql)
		WAITFOR DELAY ''00:00:01''

		while(SELECT count(*)
			FROM sys.dm_exec_requests a
			INNER JOIN sys.dm_exec_connections b ON a.session_id = b.session_id
			INNER JOIN sys.dm_exec_sessions c ON c.session_id = a.session_id
			CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d WHERE a.session_id > 50
			AND a.session_id = @@SPID and d.text = @sql) > 0
		begin
			WAITFOR DELAY ''00:00:01''
		end

		if( datediff(mi,@dateStart,getdate()) > @scheduleTime) begin
		set @scheduleTime = @scheduleTime+1
			update [logsReportsMaster] set status=2,dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime,error=''Increment time shuduler ''+convert(varchar(max),@scheduleTime)  where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
			update [logsReportsMaster] set dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime where status=0 and dateStart=''19000101'' and dateEnd=''19000101''

			set @minReplication=@minReplication/60
			if(@scheduleTime>60) set @scheduleTime=59
			EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
			update ccsettings set valor=convert(varchar(max),@minReplication)+''|''+convert(varchar(max),@minReports+1),descripcion = ''Min. replicas | Min. reportes este se modifica automaticamente revisar tabla de logsReportsMaster, (Total ''+convert(varchar(max),@scheduleTime) +'' Minutos)'' where setting_id = 28
			break
		end
		set @i = @i+1
		update [logsReportsMaster] set status=1,dateStart=@dateSP,dateEnd=getdate() where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
	end try
	begin catch
		select @descError = ''Line: '' + cast(error_line() as nvarchar) + '' Number: '' + cast(@@error as nvarchar) + '' Message: '' + error_message()
		update [logsReportsMaster] set status=3,dateStart=@dateSP,dateEnd=getdate(),error=@descError where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
		set @i = @i+1
	end catch
end

drop table #tmpProcedureReports

-------------------- Reinicializa las subcripciones en caso de caducar-----------------------------------------

declare @lastTenMinuteFirst datetime
declare @lastTenMinuteSecond datetime
declare @id int
declare @publisher_reinit nvarchar(max)
declare @publisher_db_reinit nvarchar(max)
declare @publication_reinit nvarchar(max)
declare @upload_first_reinit nvarchar(max)

set @lastTenMinuteFirst = dateadd(minute,-10,dateadd(minute, datepart(minute, getdate()) / 10 * 10, dateadd(hour, datediff(hour, 0,getdate()), 0)))
set @lastTenMinuteSecond = dateadd(minute,10,@lastTenMinuteFirst)

create table #reinitmergepullsubscription(
id int not null identity,
publisher nvarchar(max) not null,
publisher_db nvarchar(max)not null,
publication nvarchar(max) not null,
upload_first nvarchar(max) not null,
[status] bit not null
)

insert into #reinitmergepullsubscription
select s.name, ma.publisher_db, ma.publication, ''false'', 0
from distribution.dbo.MSmerge_history mh
left outer join distribution.dbo.MSrepl_errors me
on (mh.error_id = me.id)
left outer join distribution.dbo.MSmerge_agents ma
on (mh.agent_id = ma.id)
left outer join master.sys.servers s
on (ma.publisher_id = s.server_id)
where mh.comments like ''%You must reinitialize the subscription (without upload)%''
and me.error_code = -2147199402
and mh.time >= @lastTenMinuteFirst
and mh.time < @lastTenMinuteSecond
and ma.subscriber_db = ''ccReportsRia''
order by mh.time desc

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
	begin
		set rowcount 1
		select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first
		from #reinitmergepullsubscription
		where [status] = 0
		set rowcount 0

		EXEC sp_reinitmergepullsubscription @publisher = @publisher_reinit, @publisher_db = @publisher_db_reinit, @publication = @publication_reinit, @upload_first = @upload_first_reinit

		update #reinitmergepullsubscription
		set [status] = 1
		where id = @id
	end

drop table #reinitmergepullsubscription'
	EXEC(@sql)
	
	set @process = 'CW-1428 - SP ccspRepAnsweredCallsByDialingRetries'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAnsweredCallsByDialingRetries]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepAnsweredCallsByDialingRetries with(rowlock)
	where date >= @from and date < @to

	INSERT INTO RepAnsweredCallsByDialingRetries
	select
	A.cal_Inicio as [date],
	A.cal_id as [calId],
	A.cal_telefono as [telephone],
	B.tipoResDial_id as [dialResultId],
	resDial.descripcion as [dialResult],
	isnull(C.cal_intentos,0) as [tries],
	A.cam_id as [campaignId],
	E.cam_descripcion as [campaign],
	A.User_id as [userId],
	D.Nombres + '' '' + D.ApellidoPaterno + '' '' + D.ApellidoMaterno as [agentName],
	(select top 1 Extension from ccLogLogin where user_id=A.User_id and tipoMov=1 and fecha<A.cal_inicio order by fecha desc) as [extension],
	convert(varchar(12),A.cal_Inicio,108) as [startHour],
	convert(varchar(12),dateadd(ss,A.cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,A.cal_Inicio),108) as [endHour],
	cal_tDialog as [dialogTime],
	isnull(A.calif_id,0) as [dispositionId],
	isnull(A.califSub_id,0) as [subDispositionId],
	isnull(disp.Description,''systemTranslated_Dispositionless'') as [disposition],
	isnull(subDisp.califSubDesc,''systemTranslated_NoSubDisposition'') as [subDisposition],
	A.cal_tNotas as [wrapup],
	datepart(yyyy,cal_Inicio) AS [year],
	datepart(mm,cal_Inicio) as [month],
	datepart(dd,cal_Inicio) as [day],
	datepart(hh,cal_Inicio) as [hour],
	datepart(mi,cal_Inicio) as [minutes]


	from ccoCallsOut A
	left join ccoLogDials B on A.cal_id=B.cal_id
	left join ccoCallsOutSource C on C.callout_id=A.callout_id
	left join ccUsers D on A.User_id=D.User_id
	left join ccCamps E on A.cam_id=E.cam_id
	left join ccTipoCalifOUT disp On disp.calif_id=A.calif_id
	left join ccTipoCalifSubOUT subDisp On subDisp.califSub_id=A.califSub_id
	left join ccTipoResultadoDial resDial on resDial.tipoResDial_id=B.tipoResDial_id

	where A.cal_Inicio >= @from
	and A.cal_Inicio < @to
	and A.cal_manual in(0,2)
	order by date
END'
	EXEC(@sql)

	
	 if @actualVersion  = @version - 1
	 	exec ccsp_getVersion 'BD', @version


	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off