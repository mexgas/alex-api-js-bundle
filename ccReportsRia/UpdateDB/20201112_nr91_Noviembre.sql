SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 91

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY


		SET @process = 'CW-4512 Coperva DROP PROCEDURE ccspTmpTimesInterval'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccspTmpTimesInterval'')
    begin
        DROP PROCEDURE ccspTmpTimesInterval;
    end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva DROP PROCEDURE ccspTmpSessionGeneral'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccspTmpSessionGeneral'')
    begin
        DROP PROCEDURE ccspTmpSessionGeneral;
    end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva DROP PROCEDURE ccspTmpSessionTimeGroup'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccspTmpSessionTimeGroup'')
    begin
        DROP PROCEDURE ccspTmpSessionTimeGroup;
    end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva DROP PROCEDURE ReportsMasterProcessWIthOnlyGenerate'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ReportsMasterProcessWIthOnlyGenerate'')
    begin
        DROP PROCEDURE ReportsMasterProcessWIthOnlyGenerate;
    end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva alter table RepSpecialTelephoneNumbersByState.state_avg'
		SET @sql = 'alter table RepSpecialTelephoneNumbersByState alter column state_avg varchar(30)'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva ALTER FUNCTION [dbo].[tDialog]'
		SET @sql = 'ALTER FUNCTION [dbo].[tDialog](
		@totalCall_Time int,
		@tdialing int, 
		@cal_tMsg int)
RETURNS INT 
AS
BEGIN
		DECLARE @totalDialog INT
		IF ((COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0), @tdialing) % 60) <> 0 )
		BEGIN
			SET @totalDialog=COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing) + (60 -(COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing) % 60)) 
			RETURN @totalDialog
		END
		ELSE
			SET @totalDialog = 60 + COALESCE(@totalCall_Time + ISNULL(@cal_tMsg,0) + ISNULL(@tdialing,0), @tdialing)
			RETURN @totalDialog
END'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Alter SP ccspGenSession'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspGenSession]
@from as smalldatetime,
@to as smalldatetime
AS
set nocount on

declare @date datetime
CREATE TABLE #tempccGenSession(
	[fila] int NOT NULL,
	[user_id] [smallint] NOT NULL,
	[login] [datetime] NOT NULL,
	[logout] [datetime] NULL,
	[extension] [varchar](7) NOT NULL,
	primary key (fila,user_id)
)

CREATE TABLE #temUserIdLogoutNull([user_id] [smallint] NOT NULL)
CREATE TABLE #temIdMaxLogoutNull([fila] int NOT NULL,[user_id] [smallint] NOT NULL,primary key (fila,user_id))


insert into #tempccGenSession
select A.Fila, A.User_id,A.fecha login,S.fecha logout,A.Extension
from (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha--convert(varchar(19),fecha,121) fecha
from ccLogLogin a where fecha >= @from and fecha <= @to
)A
left join (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha from ccLogLogin a where fecha >= @from	and fecha <= @to
) S
on A.Fila=S.Fila-1 and A.User_id=S.User_id and A.TipoMov=1 and S.TipoMov=0
where A.TipoMov=1
order by login


update x  set x.fila = x.row
from(
	select fila, ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY login) row from #tempccGenSession
)x


insert into #temUserIdLogoutNull
select user_id from #tempccGenSession where logout is null group by user_id


insert into #temIdMaxLogoutNull
select A.fila,A.user_id from #tempccGenSession A
inner join (
select max(fila) fila,user_id from #tempccGenSession where user_id in( select user_id from #temUserIdLogoutNull ) group by user_id)B
	on A.fila=B.fila and A.user_id=B.user_id
	where A.logout is null

set @date=GETDATE()
update A set A.logout=case when @to<@date then @to else @date end from #tempccGenSession A
inner join #temIdMaxLogoutNull B on A.user_id=B.user_id and A.fila=B.fila


update A set A.logout =
	(select case when  max(fecha) is not null then max(fecha) when DATEDIFF(ss,A.login,B.login)<2 then DATEADD(ms,-10,B.login) else DATEADD(ms,5,A.login) end from ccLogAgentesDia C where A.user_Id=C.User_id and fecha between A.login and B.login ) --logout,
 from #tempccGenSession A
left join #tempccGenSession B on A.fila=B.fila-1  and A.user_id=B.user_id
where A.logout is null


delete from #tempccGenSession where login=logout

delete A
from #tempccGenSession A
inner join
(
select user_id,convert(varchar(19),[login],121)[login],convert(varchar(19),logout,121)logout  from #tempccGenSession
group by user_id,convert(varchar(19),[login],121),convert(varchar(19),logout,121) having count(*)>1
) B
on A.user_id=B.user_id and convert(varchar(19), A.login,121) =B.login and convert(varchar(19), A.logout,121)=B.logout

UPDATE a with (ROWLOCK)
SET a.logout = b.logout
FROM #tempccGenSession b
INNER JOIN #tempccGenSession a on a.user_id = b.user_id and a.login = b.login and a.logout <> b.logout

;
--select *,datediff(ss,login,logout) as tlog from(
with tmpccGenSession as(
select user_id, dateadd(ss,-1,[login]) as [login],convert(varchar(19),dateadd(ss,1,[logout]),121) as [logout],extension,
dbo.GetTimeGroup(dateadd(ss,-1,[login]),0) as timeGroup,dbo.GetTimeGroup(dateadd(ss,1,[logout]),1) as timeGroupNext from #tempccGenSession
)

select A.*,datediff(ss,[login],[logout]) as tlog from tmpccGenSession A

drop table #tempccGenSession
drop table #temUserIdLogoutNull
drop table #temIdMaxLogoutNull

set nocount off'
		EXEC(@sql)

		

		SET @process = 'CW-4512 Coperva CREATE SP ccspTmpSessionTimeGroup'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccspTmpSessionTimeGroup]
@from as smalldatetime,
@to as smalldatetime 
AS
set nocount on

if @from is null begin
	select @from = convert(datetime,convert(varchar(11),getdate()))
end

if @to is null begin
	select @to = dateadd(mi,1, convert(varchar(15),getdate(),121)+'':00'')
end

IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup
IF OBJECT_ID(''tempdb..#sessionTimeMayores'') IS NOT NULL drop table #sessionTimeMayores;

CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
CREATE TABLE #sessionTimeMayores([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)


if not exists( select * from sys.tables where name=''tmpSessionTimeGroup'') begin
	CREATE TABLE tmpSessionTimeGroup([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
end
else begin
	truncate table tmpSessionTimeGroup	
	--drop table tmpSessionGeneral
end


INSERT INTO #sessionTimeGroup
select * from tmpSessionGeneral

INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
delete #sessionTimeGroup where  datediff(mi,timegroup,timegroup_next)>15

insert into #sessionTimeGroup
	select [User_id],login,logout,extension, convert(varchar,th.start,121) as timegroup, convert(varchar, th.stop,121) as timegroup_next,
	dbo.TimeInterval(th.start,th.stop,login,logout) as [tlog seg]	 

from #sessionTimeMayores t
inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0;


insert into tmpSessionTimeGroup
select user_id,min([login]) as [login],max([logout]) as [logout],min(extension) as extension,timegroup,timegroup_next,sum(tlog) as tlog from #sessionTimeGroup	
group by user_id,timegroup,timegroup_next	
	

IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup
IF OBJECT_ID(''tempdb..#sessionTimeMayores'') IS NOT NULL drop table #sessionTimeMayores;

set nocount off'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Create SP ccspTmpSessionGeneral'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccspTmpSessionGeneral]
@from as smalldatetime,
@to as smalldatetime 
AS
set nocount on

if @from is null begin
	select @from = convert(datetime,convert(varchar(11),getdate()))
end

if @to is null begin
	select @to = dateadd(mi,1, convert(varchar(15),getdate(),121)+'':00'')
end

if not exists( select * from sys.tables where name=''tmpSessionGeneral'') begin
	CREATE TABLE tmpSessionGeneral(	
	[user_id] [smallint] NOT NULL,
	[login] [datetime] NOT NULL,
	[logout] [datetime] NULL,
	[extension] [varchar](7) NOT NULL,
	[timeGroup] [datetime] NOT NULL,
	[timeGroupNext] [datetime] NULL,
	[tlog] int null,
	)
end
else begin
	truncate table tmpSessionGeneral	
	--drop table tmpSessionGeneral
end

insert into tmpSessionGeneral
exec ccspGenSession @from,@to

set nocount off'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Create SP ccspTmpTimesInterval'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccspTmpTimesInterval]
@from as smalldatetime,
@to as smalldatetime,
@interval as int
AS
set nocount on

if @from is null begin
	select @from = convert(datetime,convert(varchar(11),getdate()))
end

if @to is null begin
	select @to = dateadd(mi,2, convert(varchar(15),getdate(),121)+'':00'')
end

if not exists( select * from sys.tables where name=''TmpTimesInterval'') begin
	CREATE TABLE TmpTimesInterval([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

	create nonclustered index ix_times on TmpTimesInterval([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on TmpTimesInterval([Start] DESC)

end
else begin
	truncate table TmpTimesInterval
--	drop table TmpTimesInterval
end

insert into TmpTimesInterval
exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

set nocount off'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Create SP ReportsMasterProcessWIthOnlyGenerate'
		SET @sql = 'CREATE procedure [dbo].[ReportsMasterProcessWIthOnlyGenerate] 
@from as datetime=null,@to as datetime=null,@scheduleTime int=10,@dateStart datetime =null
as

SET ANSI_WARNINGS off
SET NOCOUNT ON

declare @i int,@count int
declare @SQL varchar(max)
declare @name sysname
declare @descError nvarchar(max)
declare @dateSP datetime

if @from is null begin
	select @from = convert(datetime,convert(varchar(11),getdate()))
end

if @to is null begin	
	set @to=getdate()
end

exec ccspTmpSessionGeneral @from= @from,@to=@to
exec ccspTmpTimesInterval @from= @from,@to=@to,@interval=15
exec ccspTmpSessionTimeGroup @from= @from,@to=@to

create table #tmpProcedureReports( id int, name sysname)

insert into #tmpProcedureReports
select ROW_NUMBER() OVER(ORDER BY [name] ) AS id,[name] from  sys.procedures where [name] like ''ccspRep%'' and [name] not in(''ccspRepCatalogos'',''ccsprepLogAgentriaseparate'')
and name not in(select name from logsReportsMaster where status=0 and dateStart>=@dateStart) 

insert into [logsReportsMaster] (name,status,dateStart,dateEnd,error,maxTime)
select name,0,''19000101'',''19000101'','''',@scheduleTime from #tmpProcedureReports

select @i=1,@count =count(*) from #tmpProcedureReports

while @i<=@count and datediff(mi,@dateStart,getdate()) < @scheduleTime
begin
	select @name = name from #tmpProcedureReports where id=@i
	

	set @sql =''EXEC ''+ @name +'' @action=1,@from=''''''+convert(varchar(max),@from,121)+'''''', @to=''''''+convert(varchar(max),@to,121)+''''''''
	set @dateSP = getdate()
	
	print (@sql)
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
		if( datediff(ss,@dateStart,getdate()) > @scheduleTime*60) begin		
			update [logsReportsMaster] set status=2,dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime+1,error=''Increment time shuduler ''+convert(varchar(max),@scheduleTime)  where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
			update [logsReportsMaster] set dateStart=@dateSP,dateEnd=getdate(),maxTime=@scheduleTime where status=0 and dateStart=''19000101'' and dateEnd=''19000101''			
			break
		end	
		update [logsReportsMaster] set status=1,dateStart=@dateSP,dateEnd=getdate() where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
	end try
	begin catch
		select @descError = ''Line: '' + cast(error_line() as nvarchar) + '' Number: '' + cast(@@error as nvarchar) + '' Message: '' + error_message()
		update [logsReportsMaster] set status=3,dateStart=@dateSP,dateEnd=getdate(),error=@descError where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''		
	end catch

	set @i = @i+1
end

drop table #tmpProcedureReports'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Alter SP ccspRepAgentGI'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentGI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS off
SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to =getdate()

if @action=1 begin


	IF OBJECT_ID(''tempdb..#inboundData'') IS NOT NULL drop table #inboundData
	IF OBJECT_ID(''tempdb..#inboundData2'') IS NOT NULL drop table #inboundData2
	IF OBJECT_ID(''tempdb..#outboundData'') IS NOT NULL drop table #outboundData
	IF OBJECT_ID(''tempdb..#outboundData2'') IS NOT NULL drop table #outboundData2
	IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL drop table #timeDetailAgent
	IF OBJECT_ID(''tempdb..#timeDetailAgent2'') IS NOT NULL drop table #timeDetailAgent2
	IF OBJECT_ID(''tempdb..#agentInformation'') IS NOT NULL drop table #agentInformation
	IF OBJECT_ID(''tempdb..#tempRepAgentGI'') IS NOT NULL drop table #tempRepAgentGI

	IF OBJECT_ID(''tempdb..#tempAgentLastStatus'') IS NOT NULL drop table #tempAgentLastStatus
	IF OBJECT_ID(''tempdb..#tempccLogAgentesDia'') IS NOT NULL drop table #tempccLogAgentesDia
	IF OBJECT_ID(''tempdb..#tempccLogAgentesDia2'') IS NOT NULL drop table #tempccLogAgentesDia2
	IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup

	declare @interval int
	declare @dateNow datetime,@maxLogout datetime
	DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
	SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
	DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog
	EXEC @tresDelayIn=ccspConfigtresDelayIn

	set @dateNow=getdate()
	set @interval=15

	create table #inboundData(
	[row] int identity primary key,Inbound_id int,[User_id] int,phone_in varchar(30),cal_id int,dni_id int,
	dateStartDetail datetime,dateEndDetail datetime,timegroup datetime,timegroup_next datetime,
	time_endque datetime,time_ring datetime,time_dialog datetime,time_notes datetime,
	time_end_call datetime,ntotal int,ninitial int,nout_hour int,nout_service int,nabnd int,
	nno_agent int,nque int,ntimeout int,noverflow int,nxfer int,nxfer_que int,
	nabnd_xfer int,nabnd_ring int,nno_answer int,nabnd_dialog int,nanswer int,nlost int,
	nmsg int,nabnd_tres int,nansw_tres int,tque_max int,tque int,txfer int,tdialog int,
	tnotes int,tring int,tresp int,nMoh int,nWHag int,nWHcl int)

	create nonclustered index iX_InboundUserId on #inboundData([Inbound_id] DESC,[User_id] DESC)

	create table #outboundData(
	row int identity,cam_id int,[User_id] int,cal_id int,cal_puerto int,phone_out varchar(30),
	dateStartDetail datetime,dateEndDetail datetime,timegroup datetime,timegroup_next datetime,
	ntotal int,nno_agent int,nxfer int,nabnd_xfer int,nabnd_ring int,nno_answer int,nabnd_dialog int,nanswer int,
	nlost int,tque int,txfer int,tring int,tdialog int,tnotes int,tresp int,nhangup int,
	nMoh int,nWHag int,nWHcl int,time_endque datetime,time_ring datetime,time_dialog datetime,
	time_notes datetime,time_end_call datetime)

	create nonclustered index iX_CamUserId on #outboundData([cam_id] DESC,[User_id] DESC)	
	create table #timeDetailAgent([User_id] int null,dateStartDetail datetime null,dateEndDetail datetime null,timegroup datetime null,	timegroup_next datetime null,tunknown int null,tnot_av int null,tav int null,tprob int null,tother int null,nother int null,tmanualcall int null,tunknown2 decimal(10,3),tchatting int null)

	--Tiempo ultimo Status del agente
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)

	--
	
	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)	

	--TIempos del agente
	create table #tempccLogAgentesDia(row int not null,user_id int not null,TipoStatusAge_id tinyint not null,tStatus int not null,dateIni datetime not null,dateEnd datetime not null,currentStatus int)
	
	select @maxLogout=max(logout) from TmpSessionTimeGroup

	if CONVERT(varchar(11),@maxLogout,121)=CONVERT(varchar(11),@dateNow,121) and @dateNow>@maxLogout set @dateNow=@maxLogout


	INSERT INTO #sessionTimeGroup
	select 
	 user_id,login,logout,extension
	 ,timegroup,timegroup_next,tlog
	from TmpSessionTimeGroup

	--inserto ultimo tiempo del agente del dia
	insert into #tempAgentLastStatus
	select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia where convert(varchar(11),fecha,121)=CONVERT(varchar(11),@dateNow,121) group by User_id


	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service
	,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl
	)
	select * from (
	SELECT case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end as dateStartDetail,
		   dateadd(ss,0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,
			case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end )
			dateEndDetail
			,dbo.GetTimeGroup(case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end,0) as timegroup	   
			,dbo.GetTimeGroup(dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end )
			,1) as timegroup_next
		   ,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end as time_endque		   
		   ,DATEADD(ss,isnull(cal_txfer,0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_ring
		   ,DATEADD(ss,isnull(cal_txfer + cal_tring,0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_dialog
		   ,DATEADD(ss,isnull(cal_txfer + cal_tring + cal_tdialog,0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_notes
		   ,DATEADD(ss,isnull(cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_end_call
		   ,cal_Ani as phone_in,cal_id,dni_id,Inbound_id,[User_id]
		   ,1 AS ntotal
		   ,ISNULL((CASE WHEN statuscall_id=1 THEN 1 ELSE 0 END),0) AS ninitial
		   ,ISNULL((CASE WHEN statuscall_id=2 THEN 1 ELSE 0 END),0) AS nout_hour
		   ,ISNULL((CASE WHEN statuscall_id=3 THEN 1 ELSE 0 END),0) AS nout_service
		   ,ISNULL((CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nabnd
		   ,ISNULL((CASE WHEN(statuscall_id=4)THEN 1 ELSE 0 END),0) AS nno_agent
		   ,ISNULL((CASE WHEN(cal_que>0)THEN 1 ELSE 0 END),0) AS nque
		   ,ISNULL((CASE WHEN(statuscall_id=7)THEN 1 ELSE 0 END),0) AS ntimeout
		   ,ISNULL((CASE WHEN(statuscall_id=8)THEN 1 ELSE 0 END),0) AS noverflow
		   ,ISNULL((CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nxfer
		   ,ISNULL((CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN 1 ELSE 0 END),0) AS nxfer_que
		   ,ISNULL((CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nabnd_xfer
		   ,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE 0 END),0) AS nabnd_ring
		   ,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE 0 END),0) AS nno_answer
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE 0 END),0) AS nabnd_dialog
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE 0 END),0) AS nanswer
		   ,ISNULL((CASE WHEN(statuscall_id=16)THEN 1 ELSE 0 END),0) AS nlost
		   ,ISNULL((CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE 0 END),0) AS nmsg
		   ,ISNULL((CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE 0 END),0) AS nabnd_tres
		   ,ISNULL((CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE 0 END),0) AS nansw_tres
		   ,cal_twait AS tque_max, cal_twait as tque, cal_txfer AS txfer
		   ,ISNULL((cal_tdialog),0)AS tdialog,ISNULL((cal_tnotas),0)AS tnotes,ISNULL((cal_tring),0)AS tring
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE 0 END),0)AS tresp
		   ,ISNULL((case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		   ,ISNULL((CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL((CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		   FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		   WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
		   )inboundData
		   where not(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
		   AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
		   AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
		   AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)

	update C
	set C.dateEndDetail=@dateNow
	,C.timegroup_next= dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1 ) 
	,C.time_dialog= case when A.currentStatus in (4,5,9) then @dateNow when A.TipoStatusAge_id=4 then B.fecha else C.dateStartDetail end
	,C.time_notes=@dateNow
	,C.time_end_call=@dateNow
	,C.tdialog= case when A.currentStatus in (4,5,9) then B.tiempo when A.TipoStatusAge_id=4 then DATEDIFF(ss,C.dateStartDetail,B.fecha) else 0 end
	,C.tnotes= case when A.currentStatus = 6 then B.tiempo else 0 end
	from ccLogAgentesDia A
	inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
	inner join #inboundData C on A.callID=C.cal_id
	WHERE currentStatus in (4,5,6,9) and A.Tipo=0

	select * into #inboundData2 from #inboundData where datediff(mi,timegroup,timegroup_next)>15
	delete #inboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	select dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next
	,time_endque,time_ring,time_dialog,time_notes,time_end_call
	,phone_in,cal_id,dni_id,Inbound_id,[User_id]
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ninitial else 0 end as ninitial
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_hour else 0 end as nout_hour
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_service else 0 end as nout_service
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd else 0 end as nabnd
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nque else 0 end as nque
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntimeout else 0 end as ntimeout
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then noverflow else 0 end as noverflow
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer_que else 0 end as nxfer_que
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nmsg else 0 end as nmsg
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_tres else 0 end as nabnd_tres
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nansw_tres else 0 end as nansw_tres
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tque_max else 0 end as tque_max
	 ,dbo.TimeInterval(th.start,th.stop,dateStartDetail,time_endque)  as tque	
	 ,dbo.TimeInterval(th.start,th.stop,time_endque,time_ring)  as txfer	     
	 ,dbo.TimeInterval(th.start,th.stop,time_dialog,time_notes)  as tdialog
	 ,dbo.TimeInterval(th.start,th.stop,time_notes,time_end_call)  as tnotes
	 ,dbo.TimeInterval(th.start,th.stop,time_ring,time_dialog)  as tring
	 ,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tresp,dateStartDetail))  as tresp	
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
	from #inboundData2 t
	join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	and th.Start between @from and @to
	order by cal_id

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto)
	select * from (
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		   ,dbo.GetTimeGroup(cal_inicio,0 ) as timegroup
		   ,dbo.GetTimeGroup(dateadd(ss,isnull(sum(cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),0 )  as timegroup_next
		   ,cam_id, [User_id]
		   ,COUNT(cal_id) AS ntotal
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END),0) AS nno_agent
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END),0) AS nxfer
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END),0) AS nabnd_xfer
		   ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END),0) AS nabnd_ring
		   ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END),0) AS nno_answer
		   ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END),0) AS nabnd_dialog
		   ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) AS nanswer
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END),0) AS nlost
		   ,ISNULL(SUM(cal_twait),0) as tque
		   ,ISNULL(SUM(cal_txfer),0)AS txfer
		   ,isnull(SUM(cal_tring),0) as tring
		   ,isnull(SUM(cal_tdialog),0) as tdialog
		   ,isnull(SUM(cal_tnotas),0) as tnotes
		   ,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id=6)THEN cal_id ELSE NULL END),0) AS nhangup
		   ,ISNULL(SUM(CASE WHEN cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag
		   ,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		  ,DATEADD(ss,isnull(sum(0),0),cal_inicio) as time_endque
		   ,DATEADD(ss,isnull(sum(0 + cal_txfer),0),cal_inicio) as time_ring
		   ,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		   ,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		   ,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		   ,isnull(max(cal_telefono),0) as phone_out,cal_id,cal_puerto
		   FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
		   WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
		   -- para contar bien las llamadas manuales
		   and cal_manual in(0,2)
		   group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto
		   )outboundData
		   where not(ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
				   AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
				   AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0 )


	 update C
	 set C.dateEndDetail=@dateNow
	 ,C.timegroup_next= dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1 )
	 ,C.time_dialog= case when A.currentStatus in (4,5,9) then @dateNow when A.TipoStatusAge_id=4 then B.fecha else C.dateStartDetail end
	 ,C.time_notes=@dateNow
	 ,C.time_end_call=@dateNow
	 ,C.tdialog= case when A.currentStatus in (4,5,9) then B.tiempo when A.TipoStatusAge_id=4 then DATEDIFF(ss,C.dateStartDetail,B.fecha) else 0 end
	 ,C.tnotes= case when A.currentStatus = 6 then B.tiempo else 0 end
	 from ccLogAgentesDia A
	 inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
	 inner join #outboundData C on A.callID=C.cal_id
	 WHERE currentStatus in (4,5,6,9) and A.Tipo=1

	select * into #outboundData2 from #outboundData where datediff(mi,timegroup,timegroup_next)>15
	delete #outboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto)
	select
	dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,cam_id,[User_id]
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,time_endque)  as tque	
	 ,dbo.TimeInterval(th.start,th.stop,time_endque,time_ring)  as txfer	     
	 ,dbo.TimeInterval(th.start,th.stop,time_dialog,time_notes)  as tdialog
	 ,dbo.TimeInterval(th.start,th.stop,time_notes,time_end_call)  as tnotes
	 ,dbo.TimeInterval(th.start,th.stop,time_ring,time_dialog)  as tring
	 ,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tresp,dateStartDetail))  as tresp	
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nhangup else 0 end as nhangup
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
	,time_endque,time_ring,time_dialog,time_notes,time_end_call
	,phone_out,cal_id,cal_puerto
	from #outboundData2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	and th.Start between @from and @to

	insert into #tempccLogAgentesDia(row,[User_id],TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus)
	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,
	TipoStatusAge_id,tStatus,DATEADD(ss,-tStatus,fecha) dateIni, fecha dateEnd, isnull(currentStatus,-2)
	from ccLogAgentesDia
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to


	delete A from(
	select case when A.tStatus>S.tStatus then S.row else A.row end row,A.user_id
	from #tempccLogAgentesDia A
	left join #tempccLogAgentesDia S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id=S.TipoStatusAge_id
	and (S.dateEnd between A.dateIni and A.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
	and abs(DATEDIFF(ss,A.dateEnd,S.dateIni))>2
	)x
	inner join 	#tempccLogAgentesDia A on A.row=x.row and A.user_id=x.user_id

	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY dateIni) AS Row,User_id,TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus into #tempccLogAgentesDia2 from #tempccLogAgentesDia

	insert into #timeDetailAgent
	select A.user_id,A.dateIni,A.dateEnd
	,dbo.GetTimeGroup(A.dateIni,0 ) AS timegroup
	,dbo.GetTimeGroup(A.dateEnd,1 ) AS timegroup_next,	
	case when A.tipostatusage_id=1 then A.tStatus else 0 end tunknown,
	case when A.tipostatusage_id=2 then A.tStatus else 0 end tnot_av,
	case when A.tipostatusage_id=3 then A.tStatus else 0 end tav,
	case when A.tipostatusage_id in(11,25,26,27) then A.tStatus else 0 end tprob,--11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
	case when A.tipostatusage_id=7 then A.tStatus else 0 end tother,
	case when A.tipostatusage_id=7 then 1 else 0 end nother,
	case when A.tipostatusage_id=21 then A.tStatus else 0 end tmanualcall,
	case when abs(isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) )>A.tStatus then 0
	when A.currentStatus in(0,-1,-2) then 0 --Logout
	when S.TipoStatusAge_id=1 then 0
	else isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) end	as tunknown2
	,case when A.tipostatusage_id in (23,24) then A.tStatus else 0 end  as tchatting
	from #tempccLogAgentesDia2 A
	left join #tempccLogAgentesDia2 S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id<>0


	update #timeDetailAgent set tunknown2=0  where abs(tunknown2)>2.7

	 insert into #timeDetailAgent(User_id,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tunknown,tnot_av,tav,tprob,tother,nother,tmanualcall,tunknown2,tchatting)
	 select
	 	User_id,
	 	B.fecha as dateStartDetail,
	 	@dateNow as dateEndDetail
		,dbo.GetTimeGroup(B.fecha,0 ) AS timegroup
		,dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha), 1 ) AS timegroup_next
	 	,case when currentStatus = 1 then tiempo else 0 end as tunknown,
	 	case when currentStatus = 2 then tiempo else 0 end as tnot_av,
	 	case when tipostatusage_id=1 then tiempo when currentStatus = 3 then tiempo else 0 end as tav,
	 	 0,0,0,0,0 as tunknown2
		,case when currentStatus in (23,24) then tiempo else 0 end as tchatting
	 	from ccLogAgentesDia A
	 	inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
		where A.currentStatus not in(-2,-1,0)


	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15
	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15


	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother,tmanualCall,tunknown2,tchatting)
	select
	dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))  as tunknown
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))  as tnot_av	
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tav,dateStartDetail))  as tav	
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tprob,dateStartDetail))  as tprob		
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tother,dateStartDetail))  as tother			
	,isnull((case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tmanualCall,dateStartDetail))  as tmanualCall			
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tunknown2 else 0 end as tunknown2
	,dbo.TimeInterval(th.start,th.stop,dateStartDetail,dateadd(ss,tchatting,dateStartDetail))  as tchatting			
	from #timeDetailAgent2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	and th.Start between @from and @to

	select
	ROW_NUMBER() OVER(PARTITION BY xTimeDetail.user_id ORDER BY xTimeDetail.timegroup) AS Row,
	xTimeDetail.timegroup
	,xTimeDetail.[user_id]
	,timeSession.tlog
	,xTimeDetail.tav,xTimeDetail.tnot_av,xTimeDetail.tprob,xTimeDetail.tother,xTimeDetail.tunknown,xTimeDetail.tchatting,xTimeDetail.tmanualCall
	,xTimeDetail.nother
	,isnull(B.txfer,0)+isnull(C.txfer,0) as txfer
	,isnull(B.tdialog,0)+isnull(C.tdialog,0) as tdialog
	,isnull(B.tnotes,0)+isnull(C.tnotes,0) as tnotes
	,isnull(B.tring,0)+isnull(C.tring,0) as tring
	,isnull(B.nMoh,0)+isnull(C.nMoh,0) as nMoh
	,isnull(B.nWHag,0)+isnull(C.nWHag,0) as nWHag
	,isnull(B.nWHcl,0)+isnull(C.nWHcl,0) as nWHcl
	into #agentInformation
	from(
		select x.User_id,x.timegroup
		,case when sum(tunknown+tunknown2)>0 then sum(tunknown+tunknown2) else sum(tunknown) end as tunknown
		,sum(tnot_av) as tnot_av
		,case when sum(tav+tav2)>0 then sum(tav+tav2) else sum(tav) end as tav
		,case when sum(tprob+tprob2)>0 then sum(tprob+tprob2) else sum(tprob) end as tprob
		,case when sum(tother+tother2)>0 then sum(tother+tother2) else sum(tother) end as tother
		,case when sum(tmanualcall+tmanualcall2)>0 then sum(tmanualcall+tmanualcall2) else sum(tmanualcall) end as tmanualcall
		,sum(nother) as nother
		,case when sum(tchatting+tchatting2)>0 then sum(tchatting+tchatting2) else sum(tchatting) end as tchatting
			from(
		select User_id,timegroup
		,tunknown,tnot_av,tav,tprob,tother,tmanualcall,nother,tchatting
		,isnull(cast(case when tunknown>0 then tunknown2 else 0 end as int),0) as tunknown2
		,isnull(cast(case when tav>0 and (tav>abs(tunknown2) and (tunknown2+tav)>0 ) then tunknown2 else 0 end as int),0) as tav2
		,isnull(cast(case when tprob>0 then tunknown2 else 0 end as int),0) as tprob2
		,isnull(cast(case when tother>0 then tunknown2 else 0 end as int),0) as tother2
		,isnull(cast(case when tmanualcall>0 then tunknown2 else 0 end as int),0) as tmanualcall2
		,isnull(cast(case when tchatting>0 or (tchatting>abs(tunknown2) and (tunknown2+tchatting)>0 ) then tunknown2 else 0 end as int),0) as tchatting2
		from #timeDetailAgent A
		)x
		group by x.timegroup,x.User_id
	)xTimeDetail
	inner join
	(select user_id,timegroup,sum(tlog) as tlog from #sessionTimeGroup group by user_id,timegroup) timeSession
	on xTimeDetail.User_id=timeSession.user_id and xTimeDetail.timegroup=timeSession.timegroup
	left join
	(select user_id,timegroup,sum(txfer) as txfer,sum(tring) tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl from #inboundData group by user_id,timegroup) B
	on xTimeDetail.timegroup=B.timegroup and xTimeDetail.User_id=B.User_id
	left join
	(select user_id,timegroup,sum(txfer) as txfer,sum(tring) tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl from #outboundData group by user_id,timegroup) C
	on xTimeDetail.timegroup=C.timegroup and xTimeDetail.User_id=C.User_id

	update B
		set  B.tav=case when A.tav>0 and A.tav+A.tundefinded>=0 then A.tav+A.tundefinded else A.tav end
	 from (
	select User_id,timegroup,tlog,tav,tnot_av,tprob,tother,tunknown,tchatting,tmanualCall,nother,txfer,tdialog,tnotes,tring,
	tlog-tav-tnot_av-tprob-tother-tunknown-tchatting-tmanualCall-nother-txfer-tdialog-tnotes-tring as tundefinded from #agentInformation
	)A
	inner join #agentInformation B on A.User_id=B.User_id and A.timegroup=B.timegroup
	where A.tundefinded<0 and A.tav+A.tundefinded>=0


	update B
		set  B.tunknown=case when A.tunknown>0 and A.tunknown+A.tundefinded>=0 then A.tunknown+A.tundefinded else A.tunknown end
	 from (
	select User_id,timegroup,tlog,tav,tnot_av,tprob,tother,tunknown,tchatting,tmanualCall,nother,txfer,tdialog,tnotes,tring,
	tlog-tav-tnot_av-tprob-tother-tunknown-tchatting-tmanualCall-nother-txfer-tdialog-tnotes-tring as tundefinded from #agentInformation
	)A
	inner join #agentInformation B on A.User_id=B.User_id and A.timegroup=B.timegroup
	where A.tundefinded<0 and A.tunknown+A.tundefinded>=0



	select
	ROW_NUMBER() OVER(ORDER BY
						CASE WHEN agtInf.timegroup IS NOT NULL THEN agtInf.timegroup WHEN calls.timegroup IS NOT NULL  THEN calls.timegroup ELSE 0 END,
						CASE WHEN agtInf.user_id IS NOT NULL THEN agtInf.user_id WHEN calls.userId IS NOT NULL THEN calls.userId ELSE - 1 END
					) AS id,
	agtInf.[row] rowAgentInformation
	,isnull(rowIn,-1) rowIn,isnull(rowOut,-1) rowOut,
	isnull(callIdIn,'''') callIdIn,isnull(phoneIn,'''') phoneIn,isnull(dateStartDetailIn,'''') dateStartDetailIn,
	isnull(callIdOut,'''') callIdOut,isnull(phoneOut,'''') phoneOut,isnull(dateStartDetailOut,'''') dateStartDetailOut,
	(case when agtInf.timegroup IS NOT NULL then agtInf.timegroup when calls.timegroup IS NOT NULL  then calls.timegroup else '''' END) [date],
	(case when agtInf.user_id IS NOT NULL THEN agtInf.user_id when calls.userId IS NOT NULL then calls.userId else -1 END) [userId],
	u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + nombres as [user] , u.login as [login]
	,isnull(nxfer_in,0) as nxferin, isnull(nanswer_in,0) as nanswerin, isnull(nabnd_xfer_in,0) as nabndxferin
	,isnull(nabnd_ring_in,0) as nabndringin,isnull(nabnd_dlg_in,0) as nabnddlgin,isnull(abnd_a_xfer_in,0) as abndaxferin
	,isnull(nno_answer_in,0) as nnoanswerin,isnull(nlost_in,0) as nlostin,isnull(tdialog_in,0) as tdialogin
	,isnull(tnotes_in,0) as tnotesin,isnull(tring_in,0) as tringin,isnull(txfer_in,0) as txferin
	,isnull(nxfer_out,0) as nxferout,isnull(nanswer_out,0) as nanswerout,isnull(nabnd_xfer_out,0) as nabndxferout
	,isnull(nabnd_ring_out,0) as nabndringout,isnull(nabnd_dlg_out,0) as nabnddlgout,isnull(abnd_a_xfer_out,0) as abndaxferout
	,isnull(nno_answer_out,0) as nnoanswerout,isnull(nlost_out,0) as nlostout,isnull(tdialog_out,0) as tdialogout
	,isnull(tnotes_out,0) as tnotesout,isnull(tring_out,0) as tringout, isnull(txfer_out,0) as txferout

	,ISNULL(agtInf.nother, 0) AS nother
	,ISNULL(agtInf.tunknown, 0) AS tunknown
	,ISNULL(agtInf.tnot_av, 0) AS tnotav
	,agtInf.tlog as tlog
	,ISNULL(agtInf.tav, 0) AS tav
	,ISNULL(agtInf.tother, 0) + isnull(tmanualcall,0) AS tother
	,ISNULL(agtInf.tprob, 0) AS tprob
	,ISNULL(agtInf.tchatting, 0) AS tchatting

	,isnull(nMoh_in,0) as nMohin,isnull(nMoh_out,0) as nMohout,isnull(nWHag_in,0) as nWHagin
	,isnull(nWHag_out,0) as nWHagout,isnull(nWHcl_in,0) as nWHcliin,isnull(nWHcl_out,0) as nWHcliout
	, CASE WHEN agtInf.timegroup IS NOT NULL THEN datepart(yy,agtInf.timegroup)
						WHEN calls.timegroup IS NOT NULL THEN datepart(yy,calls.timegroup) ELSE 0 END AS [year]
		   , CASE WHEN agtInf.timegroup IS NOT NULL THEN datepart(mm,agtInf.timegroup)
						WHEN calls.timegroup IS NOT NULL THEN datepart(mm,calls.timegroup) ELSE 0 END AS [month]
		   , CASE WHEN agtInf.timegroup IS NOT NULL THEN datepart(dd,agtInf.timegroup)
						WHEN calls.timegroup IS NOT NULL THEN datepart(dd,calls.timegroup) ELSE 0 END AS [day]
		   , CASE WHEN agtInf.timegroup IS NOT NULL THEN datepart(hh,agtInf.timegroup)
						WHEN calls.timegroup IS NOT NULL THEN datepart(hh,calls.timegroup) ELSE 0 END AS [hour]
		   , CASE WHEN agtInf.timegroup IS NOT NULL THEN datepart(mi,agtInf.timegroup)
						WHEN calls.timegroup IS NOT NULL THEN datepart(mi,calls.timegroup) ELSE 0 END AS [minutes]
	into #tempRepAgentGI
	from #agentInformation agtInf
	left join ccUserView u ON agtInf.[user_id] = u.[user_id]
	left join
	(select
		(case when _in.timegroup is not null then _in.timegroup else _out.timegroup end) timegroup,
		(case when _in.[user_id] is not null then _in.[user_id] else _out.[user_id] end) [userId]
		,isnull(_in.row, -1) as rowIn,isnull(_out.row, -1) as rowOut
		,isnull((_in.nxfer), 0) AS nxfer_in, isnull((_in.nanswer), 0) AS nanswer_in, isnull((_in.nabnd_xfer), 0) AS nabnd_xfer_in
		,isnull((_in.nabnd_ring), 0) AS nabnd_ring_in, ISNULL((_in.nabnd_dialog), 0) AS nabnd_dlg_in
		,isnull((_in.nabnd_xfer), 0) + isnull((_in.nabnd_ring), 0) + isnull((_in.nabnd_dialog), 0) AS abnd_a_xfer_in
		,isnull((_in.nno_answer), 0) AS nno_answer_in, isnull((_in.nlost), 0) AS nlost_in, isnull((_in.tdialog), 0) AS tdialog_in
		,isnull((_in.tnotes), 0) AS tnotes_in, isnull((_in.tring), 0) AS tring_in, isnull((_in.txfer), 0) AS txfer_in
		,isnull((_in.nMoh), 0) AS nMoh_in, isnull((_in.nWHag), 0) AS nWHag_in,isnull((_in.nWHcl), 0) AS nWHcl_in
		,isnull((_out.nxfer), 0) AS nxfer_out, isnull((_out.nanswer), 0) AS nanswer_out, isnull((_out.nabnd_xfer), 0) AS nabnd_xfer_out
		,isnull((_out.nabnd_ring), 0) AS nabnd_ring_out, isnull((_out.nabnd_dialog), 0) AS nabnd_dlg_out
		,isnull((_out.nabnd_xfer), 0) + isnull((_out.nabnd_ring), 0) + isnull((_out.nabnd_dialog), 0) AS abnd_a_xfer_out
		,isnull((_out.nno_answer), 0) AS nno_answer_out, isnull((_out.nlost), 0) AS nlost_out, isnull((_out.tdialog), 0) AS tdialog_out
		,isnull((_out.tnotes), 0) AS tnotes_out, isnull((_out.tring), 0) AS tring_out, isnull((_out.txfer), 0) AS txfer_out
		,isnull((_out.nMoh), 0) AS nMoh_out, isnull((_out.nWHag), 0) AS nWHag_out,isnull((_out.nWHcl), 0) AS nWHcl_out
		,isnull((_in.cal_id),'''') as callIdIn,isnull((_in.phone_in),'''') as phoneIn,isnull((_in.dateStartDetail),'''') as dateStartDetailIn
		,isnull((_out.cal_id),'''') as callIdOut,isnull((_out.phone_out),'''') as phoneOut,isnull((_out.dateStartDetail),'''') as dateStartDetailOut
	from #inboundData _in
	FULL OUTER JOIN #outboundData _out on _in.timegroup=_out.timegroup AND _in.[user_id]=_out.[user_id])  calls
	on calls.timegroup = agtInf.timegroup and agtInf.[user_id]=calls.[userid]
	where agtInf.timegroup is not null

	update A set nother=0,tunknown=0,tnotav=0,tlog=0,tother=0,tprob=0,tav=0,tchatting=0 from (
	select RANK() OVER(PARTITION BY A.rowAgentInformation,A.userId ORDER by id) as [rank], A.id from
	#tempRepAgentGI A
	inner join (
	select temp.rowAgentInformation,temp.[UserId] from #tempRepAgentGI temp GROUP BY temp.rowAgentInformation,temp.[UserId] HAVING Count(*) > 1 )B
	on A.userId=B.userId and A.rowAgentInformation=B.rowAgentInformation)x
	inner join #tempRepAgentGI A on A.id=x.id
	where x.rank>1

	update A
	set nxferin=0,nanswerin=0,nabndxferin=0,nabndringin=0,nabnddlgin=0,abndaxferin=0,nnoanswerin=0,nlostin=0,tdialogin=0,tnotesin=0,tringin=0,txferin=0,nMohin=0,nWHagin=0,nWHcliin=0
	from (
	select RANK() OVER(PARTITION BY A.rowIn,A.userId ORDER by id) as [rank], A.id from
	#tempRepAgentGI A
	inner join (
		select temp.rowIn,temp.[UserId] from #tempRepAgentGI temp GROUP BY temp.rowIn,temp.[UserId] HAVING Count(*) > 1
		)B
		on A.userId=B.userId and A.rowIn=B.rowIn
	)x
	inner join #tempRepAgentGI A on A.id=x.id
	where x.rank>1

	update A
	set nxferout=0,nanswerout=0,nabndxferout=0,nabndringout=0,nabnddlgout=0,abndaxferout=0,nnoanswerout=0,nlostout=0,tdialogout=0,tnotesout=0,tringout=0,txferout=0,nMohout=0,nWHagout=0,nWHcliout=0
	from (
	select RANK() OVER(PARTITION BY A.rowOut,A.userId ORDER by id) as [rank], A.id from
	#tempRepAgentGI A
	inner join (
		select temp.rowOut,temp.[UserId] from #tempRepAgentGI temp GROUP BY temp.rowOut,temp.[UserId] HAVING Count(*) > 1
		)B
		on A.userId=B.userId and A.rowOut=B.rowOut
	)x
	inner join #tempRepAgentGI A on A.id=x.id
	where x.rank>1	

	delete from RepAgentGI where date >= @from AND date < @to

	insert into RepAgentGI(date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,--treq,
			tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotavg,tundefined,tchatting)
	select date,userId,isnull([user],''otro''),isnull(login,''otro'') login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,--treq,
				tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotav,
				(tlog-tdialogin-tnotesin-tringin-txferin-tdialogout-tnotesout-tringout-txferout-tunknown-tnotav-tav-tother-tprob-tchatting) as tundefined
				,tChatting
	 from #tempRepAgentGI
	 

	---DROP TABLES TEMP	
	IF OBJECT_ID(''tempdb..#inboundData'') IS NOT NULL drop table #inboundData
	IF OBJECT_ID(''tempdb..#inboundData2'') IS NOT NULL drop table #inboundData2
	IF OBJECT_ID(''tempdb..#outboundData'') IS NOT NULL drop table #outboundData
	IF OBJECT_ID(''tempdb..#outboundData2'') IS NOT NULL drop table #outboundData2
	IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL drop table #timeDetailAgent
	IF OBJECT_ID(''tempdb..#timeDetailAgent2'') IS NOT NULL drop table #timeDetailAgent2
	IF OBJECT_ID(''tempdb..#agentInformation'') IS NOT NULL drop table #agentInformation
	IF OBJECT_ID(''tempdb..#tempRepAgentGI'') IS NOT NULL drop table #tempRepAgentGI

	IF OBJECT_ID(''tempdb..#tempAgentLastStatus'') IS NOT NULL drop table #tempAgentLastStatus
	IF OBJECT_ID(''tempdb..#tempccLogAgentesDia'') IS NOT NULL drop table #tempccLogAgentesDia
	IF OBJECT_ID(''tempdb..#tempccLogAgentesDia2'') IS NOT NULL drop table #tempccLogAgentesDia2
	IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup
end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Alter SP ccspRepAgentNotReady'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentNotReady]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS OFF
SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
	
	IF OBJECT_ID(''tempdb..#notReady'') IS NOT NULL drop table #notReady	
	IF OBJECT_ID(''tempdb..#notReady2'') IS NOT NULL drop table #notReady2	
	IF OBJECT_ID(''tempdb..#tempFechasR'') IS NOT NULL drop table #tempFechasR

	declare @dateNow datetime
	
	set @dateNow=getdate()
	
	create table #tempFechasR(id int,fecha datetime,tiempo int)	  

	SELECT DATEADD(ss,-(tStatus),(fecha)) as dateStartDetail,(fecha) as dateEndDetail,
	convert(smalldatetime,convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000'',121) AS timegroup
	,dateadd(hh,1,convert(smalldatetime,convert(varchar(13),fecha,121) + '':00:00.000'',121)) as timegroup_next, TipoNotReady_id
	,[User_id],(tStatus) as [timeNotReady],1 as [count], tstatus as [time]
	into #notReady
	FROM ccLogAgentesNotReady
	WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
	
	insert into #tempFechasR   
	select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia
	where CONVERT(varchar(11),fecha,121)=CONVERT(varchar(11), @dateNow,121) group by User_id  

	insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next,TipoNotReady_id,[User_id],[timeNotReady],[count],[time])
	select
	B.fecha as dateStartDetail,
	@dateNow as dateEndDetail,
	CONVERT(smalldatetime,CONVERT(varchar(13),B.fecha,121)+ '':00'',121) AS timegroup,
	case when @dateNow=CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121) then CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121)
	else CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(hh,1,@dateNow),121)+ '':00'',121) end AS timegroup_next
	,0 as TipoNotReady_id,User_id,0 as timeNotReady,1 as [count],tiempo as [time]
	from ccLogAgentesDia A
	inner JOIN #tempFechasR B ON A.fecha=B.fecha  and A.User_id=B.id WHERE currentStatus =2

	select * into #notReady2 from #notReady where datediff(HH,timegroup,timegroup_next)>1
	delete #notReady where datediff(HH,timegroup,timegroup_next) > 1

	;
	with times as(
	select convert(varchar(13),Start,121)+'':00:00'' as Start,dateadd(hh,1, convert(varchar(13),Stop,121)+'':00:00'') as Stop 
	from TmpTimesInterval where start between @from and @to
	group by convert(varchar(13),Start,121)+'':00:00'',convert(varchar(13),Stop,121)+'':00:00''
	)

	insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next, tiponotready_id,User_id,timeNotReady, [count], [time])
	select (dateStartDetail),(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next, tiponotready_id,[User_id]
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,timeNotReady,dateStartDetail))
	when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
	when th.start > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,dateadd(ss,timeNotReady,dateStartDetail))
	when th.start > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as timeNotReady,1 as [count], isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,timeNotReady,dateStartDetail))
	when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
	when th.start > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,dateadd(ss,timeNotReady,dateStartDetail))
	when th.start > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as [time]
	from #notReady2 t
	inner join times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	
	--Delete tepetidos
	delete from RepAgentNotReady with(rowlock) 	where date >= @from AND date < @to
	;
	with tmpSession as(
		select user_id,convert(varchar(14),timegroup,121)+''00:00'' as timegroup 	
		,sum(tlog) as tlog
		from TmpSessionTimeGroup where login between @from and @to
		group by user_id,  convert(varchar(14),timegroup,121)+''00:00''
	),
	timeNotReady as(
		select timegroup,User_id,TipoNotReady_id,sum(timeNotReady) [time],sum([count]) [count] from #notReady 
		group by User_id,timegroup,TipoNotReady_id
	)

	insert into RepAgentNotReady
	select A.timegroup as date,userView.Login,A.user_id, userView.apellidopaterno + '' '' + userView.apellidomaterno + '' '' + userView.nombres as [user]
	,a.tlog as sessionTime
	,isnull(d.tiponotready_id,0) tiponotready_id, isnull(d.descripcion,'''') descripcion
	, isnull(d.descripcion,'''') + ''_Count'' as descripcion_count, isnull([count],0) count, isnull(d.descripcion,'''') + ''_Time'' as descripcion_time
	,isnull(timeNotReady.time,0) as [time],isnull(timeNotReady.time,0) as timeSeconds
	,datepart(yyyy,a.timegroup) year, datepart(mm,a.timegroup) [mounth], datepart(dd,a.timegroup) [day], datepart(hh,a.timegroup) [hour]
	,0 as [minute]
	from tmpSession A
	inner join ccUserView userView on A.user_id=userView.User_id
	left join timeNotReady on timeNotReady.User_id=A.user_id and A.timegroup=timeNotReady.timegroup
	left join ccTipoNotReady d on timeNotReady.TipoNotReady_id=d.TipoNotReady_id	
		
	IF OBJECT_ID(''tempdb..#notReady'') IS NOT NULL drop table #notReady	
	IF OBJECT_ID(''tempdb..#notReady2'') IS NOT NULL drop table #notReady2	
	IF OBJECT_ID(''tempdb..#tempFechasR'') IS NOT NULL drop table #tempFechasR

end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Alter SP ccspRepAgentSession'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentSession]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
	delete from RepAgentSession where date >= @from and date < @to

	insert into RepAgentSession(date,login,userId,[user],extension,loginTime,logoutTime,sessionTime,sessionTimeSeconds,year,month,day,hour,minutes)
	select A.login as date,u.Login,A.user_id,
	u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension,
	A.login,a.logout,
	datediff(ss,A.login,logout) as sessionTime,
	datediff(ss,A.login,logout) as sessionTimeSeconds,
	datepart(yyyy,A.login) [year], datepart(mm,A.login) [mount], datepart(dd,A.login) as [day],
	datepart(hh,A.login) as [hour], datepart(mi,A.login) as [minute]
	 from TmpSessionGeneral A
	inner join ccUserView u on A.user_id=u.User_id

end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva alter SP ccspRepAgentSessionByInterval'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentSessionByInterval]
@action as tinyint,
@from as datetime=null,
@to as datetime=null
AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

	delete from  RepAgentSessionByInterval where [date] between @from and @to;

	insert into RepAgentSessionByInterval(date,login,userId,[user],extension,sessionTime,year,month,day,hour,minutes)
	select  A.timegroup,
	u.Login,A.user_id,
	u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension,
	A.tlog tlog,
	datepart(yyyy,A.timegroup) [year], datepart(mm,A.timegroup) [mount], datepart(dd,A.timegroup) [day],
	datepart(hh,A.timegroup) [hour], datepart(mi,A.timegroup) [minute]
		from TmpSessionTimeGroup  A
	inner join ccUserView u on A.user_id=u.User_id	
end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva alter SP ccspRepAnsweredCallsByDialingRetries'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAnsweredCallsByDialingRetries]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin	
	--Borrar lo que esta para no repetir
	delete from RepAnsweredCallsByDialingRetries where date >= @from and date < @to

	;
	with logExtension as(
		select user_id,max(Extension) ext from ccLogLogin where fecha between @from and @to
		group by user_id
	)

	INSERT INTO RepAnsweredCallsByDialingRetries
	select
	A.cal_Inicio as [date],
	A.cal_id as [calId],
	A.cal_telefono as [telephone],
	isnull(B.tipoResDial_id,0) as [dialResultId],
	isnull(resDial.descripcion,''N/A'') as [dialResult],
	isnull(C.cal_intentos,0) as [tries],
	A.cam_id as [campaignId],
	E.cam_descripcion as [campaign],
	A.User_id as [userId],
	ISnull(D.Nombres + '' '' + D.ApellidoPaterno + '' '' + D.ApellidoMaterno,''systemTranslated_NoName'') as [agentName],
	isnull(logExtension.ext	,'''') as [extension],
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
	left join ccUserView D on A.User_id=D.User_id
	left join ccCamps E on A.cam_id=E.cam_id
	left join ccTipoCalifOUT disp On disp.calif_id=A.calif_id
	left join ccTipoCalifSubOUT subDisp On subDisp.califSub_id=A.califSub_id
	left join ccTipoResultadoDial resDial on resDial.tipoResDial_id=B.tipoResDial_id
	left join logExtension on logExtension.user_id=A.User_id

	where A.cal_Inicio >= @from
	and A.cal_Inicio < @to
	and A.cal_manual in(0,2)
	order by date
END'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Alter SP ccspRepCallXfer'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepCallXfer]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON
		
if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()
		
	delete RepCallXfer with(rowlock)	where [date] between @from and @to
						
	insert RepCallXfer 
	select convert(varchar(10),fechafin,121) [date],
	clt.cal_id callid, case when tipo = 1 then ''systemTranslated_inbound'' else ''systemTranslated_outbound'' end CallTypes, 
	isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccUserView nolock where user_id = 
	(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') Agent,	
	case when modo = 0 then ''systemTranslated_blindXfer'' 
	when modo = 1 then ''systemTranslated_Agent'' 
	when modo = 2 then 
		case when cast(clt.destino as int) >= 0 then ''systemTranslated_acd'' else ''systemTranslated_Survey'' end
	when modo = 3 then ''systemTranslated_conference'' 
	when modo = 4 then ''systemTranslated_supXfer'' 
	when modo in(5,6) then ''systemTranslated_overflow'' end as xfertype,
	case when modo = 0 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
	when modo = 1 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),''systemTranslated_Indefinite'') 
	when modo = 2 then 
		case when cast(clt.destino as bigint) >= 0 then
			isnull((select descripcion from ccinbound where inbound_id = clt.destino),''systemTranslated_Indefinite'') 
		else
			isnull((select top 1 description from survey where active=1 and scriptId = abs(cast(clt.destino as int))),''systemTranslated_Indefinite'') 
		end
	when modo = 3 then isnull((select nombre from telefonosConferencia where tel = clt.destino),clt.destino) 
	when modo = 4 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
	when modo in(5,6) then  isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end destination,
	tantesxfer timebeforexfer,
	tdespuesxfer timeafterxfer,
	dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate,
	fechafin as endDate,		
	case when camp.cam_descripcion is not null then  camp.cam_descripcion 
	when inbound.descripcion is not null then  inbound.descripcion				
	else ''systemTranslated_Indefinite'' end as Origin,
	tantesxfer+tdespuesxfer as TotalTimeDuration,				
	isnull((select case clt.tipoLlamada_id when 1 then ''systemTranslated_fijo''
		when 3 then ''systemTranslated_cellPhone'' else ''systemTranslated_interno'' end
		),''systemTranslated_Indefinite'') as TipoTel
	from cclogtransfers clt 
	left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
	left join cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1
	left join cccamps camp on camp.cam_id =co.cam_id
	left join ccinbound inbound on inbound.Inbound_id =ci.Inbound_id
	WHERE fechafin >= @from and fechafin < @to
end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Alter SP ccspRepDetailAgent'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepDetailAgent]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET NOCOUNT ON

declare @califout as varchar(3) , @califin as varchar(3)

set @califout =''1''
set @califin =''1''


BEGIN
SET ANSI_WARNINGS off
SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to =getdate()

if @action=1 begin

	declare @interval int
	declare @dateNow datetime,@maxLogout datetime
	DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
	SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
	DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint
	
	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog
	EXEC @tresDelayIn=ccspConfigtresDelayIn

	set @dateNow=getdate()
	set @interval=15
	declare @var varchar(100)
	select @var= valor from ccsettings where setting_id = 39
	select @califout = Value from dbo.fn_RIASplitDelimited(@var,''|'') where Id=1
	select @califin =  Value from dbo.fn_RIASplitDelimited(@var,''|'') where Id=2
	
	IF OBJECT_ID(''tempdb..#inboundData'') IS NOT NULL drop table #inboundData
	IF OBJECT_ID(''tempdb..#inboundData2'') IS NOT NULL drop table #inboundData2
	IF OBJECT_ID(''tempdb..#outboundData'') IS NOT NULL drop table #outboundData
	IF OBJECT_ID(''tempdb..#outboundData2'') IS NOT NULL drop table #outboundData2
	IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL drop table #timeDetailAgent
	IF OBJECT_ID(''tempdb..#timeDetailAgent2'') IS NOT NULL drop table #timeDetailAgent2
	IF OBJECT_ID(''tempdb..#agentInformation'') IS NOT NULL drop table #agentInformation	
	IF OBJECT_ID(''tempdb..#tempAgentLastStatus'') IS NOT NULL drop table #tempAgentLastStatus
	IF OBJECT_ID(''tempdb..#tempccLogAgentesDia'') IS NOT NULL drop table #tempccLogAgentesDia
	IF OBJECT_ID(''tempdb..#tempccLogAgentesDia2'') IS NOT NULL drop table #tempccLogAgentesDia2	
	
	create table #inboundData(
	[row] int identity primary key,Inbound_id int,[User_id] int,phone_in varchar(30),cal_id int,dni_id int,
	dateStartDetail datetime,dateEndDetail datetime,timegroup datetime,timegroup_next datetime,
	time_endque datetime,time_ring datetime,time_dialog datetime,time_notes datetime,
	time_end_call datetime,ntotal int,ninitial int,nout_hour int,nout_service int,nabnd int,
	nno_agent int,nque int,ntimeout int,noverflow int,nxfer int,nxfer_que int,
	nabnd_xfer int,nabnd_ring int,nno_answer int,nabnd_dialog int,nanswer int,nlost int,
	nmsg int,nabnd_tres int,nansw_tres int,tque_max int,tque int,txfer int,tdialog int,
	tnotes int,tring int,tresp int,nMoh int,nWHag int,nWHcl int, calif_id int, califSub_id int)

	create nonclustered index iX_InboundUserId on #inboundData([Inbound_id] DESC,[User_id] DESC)

	create table #outboundData(
	row int identity,cam_id int,[User_id] int,cal_id int,cal_puerto int,phone_out varchar(30),
	dateStartDetail datetime,dateEndDetail datetime,timegroup datetime,timegroup_next datetime,
	ntotal int,nno_agent int,nxfer int,nabnd_xfer int,nabnd_ring int,nno_answer int,nabnd_dialog int,nanswer int,
	nlost int,tque int,txfer int,tring int,tdialog int,tnotes int,tresp int,nhangup int,
	nMoh int,nWHag int,nWHcl int,time_endque datetime,time_ring datetime,time_dialog datetime,
	time_notes datetime,time_end_call datetime, calif_id int, califSub_id int)

	create nonclustered index iX_CamUserId on #outboundData([cam_id] DESC,[User_id] DESC)

	create table #timeDetailAgent([User_id] int null,dateStartDetail datetime null,dateEndDetail datetime null,timegroup datetime null,	timegroup_next datetime null,tunknown int null,tnot_av int null,tav int null,tprob int null,tother int null,nother int null,tmanualcall int null,tunknown2 decimal(10,3),tchatting int null)

	--Tiempo ultimo Status del agente
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)
			
	--TIempos del agente
	create table #tempccLogAgentesDia(row int not null,user_id int not null,TipoStatusAge_id tinyint not null,tStatus int not null,dateIni datetime not null,dateEnd datetime not null,currentStatus int)
	
	--Sessiones del agente	
	select @maxLogout=max(logout) from tmpSessionGeneral where login between @from and @to

	if CONVERT(varchar(11),@maxLogout,121)=CONVERT(varchar(11),@dateNow,121) and @dateNow>@maxLogout set @dateNow=@maxLogout

	--inserto ultimo tiempo del agente del dia
	insert into #tempAgentLastStatus
	select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia where convert(varchar(11),fecha,121)=CONVERT(varchar(11),@dateNow,121) group by User_id

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service
	,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl, calif_id, califSub_id
	)
	select * from (
	SELECT case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end as dateStartDetail,
		   dateadd(ss,0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,
			case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end )
			dateEndDetail
			,dbo.GetTimeGroup(case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end,0) AS timegroup	
			,dbo.GetTimeGroup(
			dateadd(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas ,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end )
			,1) AS timegroup_next						 
		   ,DATEADD(ss,isnull((0),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_endque
		   ,DATEADD(ss,isnull((0 + cal_txfer),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_ring
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_dialog
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_notes
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) as time_end_call
		   ,cal_Ani as phone_in,cal_id,dni_id,Inbound_id,[User_id]
		   ,1 AS ntotal
		   ,ISNULL((CASE WHEN statuscall_id=1 THEN 1 ELSE 0 END),0) AS ninitial
		   ,ISNULL((CASE WHEN statuscall_id=2 THEN 1 ELSE 0 END),0) AS nout_hour
		   ,ISNULL((CASE WHEN statuscall_id=3 THEN 1 ELSE 0 END),0) AS nout_service
		   ,ISNULL((CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nabnd
		   ,ISNULL((CASE WHEN(statuscall_id=4)THEN 1 ELSE 0 END),0) AS nno_agent
		   ,ISNULL((CASE WHEN(cal_que>0)THEN 1 ELSE 0 END),0) AS nque
		   ,ISNULL((CASE WHEN(statuscall_id=7)THEN 1 ELSE 0 END),0) AS ntimeout
		   ,ISNULL((CASE WHEN(statuscall_id=8)THEN 1 ELSE 0 END),0) AS noverflow
		   ,ISNULL((CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nxfer
		   ,ISNULL((CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN 1 ELSE 0 END),0) AS nxfer_que
		   ,ISNULL((CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE 0 END),0) AS nabnd_xfer
		   ,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE 0 END),0) AS nabnd_ring
		   ,ISNULL((CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE 0 END),0) AS nno_answer
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE 0 END),0) AS nabnd_dialog
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE 0 END),0) AS nanswer
		   ,ISNULL((CASE WHEN(statuscall_id=16)THEN 1 ELSE 0 END),0) AS nlost
		   ,ISNULL((CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE 0 END),0) AS nmsg
		   ,ISNULL((CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE 0 END),0) AS nabnd_tres
		   ,ISNULL((CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE 0 END),0) AS nansw_tres
		   ,cal_twait AS tque_max, cal_twait as tque, cal_txfer AS txfer
		   ,ISNULL((cal_tdialog),0)AS tdialog,ISNULL((cal_tnotas),0)AS tnotes,ISNULL((cal_tring),0)AS tring
		   ,ISNULL((CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE 0 END),0)AS tresp
		   ,ISNULL((case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		   ,ISNULL((CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL((CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		   ,calif_id,califSub_id
		   FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		   WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
		   )inboundData
		   where not(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
		   AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
		   AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
		   AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)

	update C
	set C.dateEndDetail=@dateNow
	,C.timegroup_next= dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1) 	
	,C.time_dialog= case when A.currentStatus in (4,5,9) then @dateNow when A.TipoStatusAge_id=4 then B.fecha else C.dateStartDetail end
	,C.time_notes=@dateNow
	,C.time_end_call=@dateNow
	,C.tdialog= case when A.currentStatus in (4,5,9) then B.tiempo when A.TipoStatusAge_id=4 then DATEDIFF(ss,C.dateStartDetail,B.fecha) else 0 end
	,C.tnotes= case when A.currentStatus = 6 then B.tiempo else 0 end
	from ccLogAgentesDia A
	inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
	inner join #inboundData C on A.callID=C.cal_id
	WHERE currentStatus in (4,5,6,9) and A.Tipo=0

	select * into #inboundData2 from #inboundData where datediff(mi,timegroup,timegroup_next)>15
	delete #inboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl,calif_id,califSub_id)
	select dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call
	,phone_in,cal_id,dni_id,Inbound_id,[User_id]
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ninitial else 0 end as ninitial
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_hour else 0 end as nout_hour
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_service else 0 end as nout_service
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd else 0 end as nabnd
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nque else 0 end as nque
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntimeout else 0 end as ntimeout
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then noverflow else 0 end as noverflow
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer_que else 0 end as nxfer_que
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nmsg else 0 end as nmsg
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_tres else 0 end as nabnd_tres
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nansw_tres else 0 end as nansw_tres
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tque_max else 0 end as tque_max
	,dbo.TimeInterval(th.start,th.stop , dateStartDetail,time_endque) as tque
	,dbo.TimeInterval(th.start,th.stop , time_endque,time_ring) as txfer
	,dbo.TimeInterval(th.start,th.stop , time_dialog,time_notes) as tdialog
	,dbo.TimeInterval(th.start,th.stop , time_notes,time_end_call) as tnotes
	,dbo.TimeInterval(th.start,th.stop , time_ring,time_dialog) as tring
	,dbo.TimeInterval(th.start,th.stop , dateStartDetail,dateadd(ss,tresp,dateStartDetail)) as tresp	
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
	,t.calif_id, t.califsub_id
	from #inboundData2 t
	join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	and th.start between @from and @to
	--order by cal_id

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,calif_id,califSub_id)
	select * from (
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		,dbo.GetTimeGroup(cal_inicio,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),1) as timegroup_next			   
		   ,cam_id, [User_id]
		   ,COUNT(cal_id) AS ntotal
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END),0) AS nno_agent
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END),0) AS nxfer
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END),0) AS nabnd_xfer
		   ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END),0) AS nabnd_ring
		   ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END),0) AS nno_answer
		   ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END),0) AS nabnd_dialog
		   ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) AS nanswer
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END),0) AS nlost
		   ,ISNULL(SUM(cal_twait),0) as tque
		   ,ISNULL(SUM(cal_txfer),0)AS txfer
		   ,isnull(SUM(cal_tring),0) as tring
		   ,isnull(SUM(cal_tdialog),0) as tdialog
		   ,isnull(SUM(cal_tnotas),0) as tnotes
		   ,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
		   ,ISNULL(COUNT(CASE WHEN(statuscall_id=6)THEN cal_id ELSE NULL END),0) AS nhangup
		   ,ISNULL(SUM(CASE WHEN cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag
		   ,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		  ,DATEADD(ss,isnull(sum(0),0),cal_inicio) as time_endque
		   ,DATEADD(ss,isnull(sum(0 + cal_txfer),0),cal_inicio) as time_ring
		   ,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		   ,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		   ,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		   ,isnull(max(cal_telefono),0) as phone_out,cal_id,cal_puerto
		   ,calif_id,califSub_id
		   FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
		   WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
		   -- para contar bien las llamadas manuales
		   and cal_manual in(0,2)
		   group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto,calif_id,califSub_id
		   )outboundData
		   where not(ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
				   AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
				   AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0 )

	 update C
	 set C.dateEndDetail=@dateNow
	 ,C.timegroup_next= dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1)	 
	 ,C.time_dialog= case when A.currentStatus in (4,5,9) then @dateNow when A.TipoStatusAge_id=4 then B.fecha else C.dateStartDetail end
	 ,C.time_notes=@dateNow
	 ,C.time_end_call=@dateNow
	 ,C.tdialog= case when A.currentStatus in (4,5,9) then B.tiempo when A.TipoStatusAge_id=4 then DATEDIFF(ss,C.dateStartDetail,B.fecha) else 0 end
	 ,C.tnotes= case when A.currentStatus = 6 then B.tiempo else 0 end
	 from ccLogAgentesDia A
	 inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
	 inner join #outboundData C on A.callID=C.cal_id
	 WHERE currentStatus in (4,5,6,9) and A.Tipo=1

	select * into #outboundData2 from #outboundData where datediff(mi,timegroup,timegroup_next)>15
	delete #outboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,calif_id,califSub_id)
	select
	dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,cam_id,[User_id]
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
	,dbo.TimeInterval(th.start,th.stop , dateStartDetail,time_endque) as tque
	,dbo.TimeInterval(th.start,th.stop , time_endque,time_ring) as txfer
	,dbo.TimeInterval(th.start,th.stop , time_ring,time_dialog) as tring
	,dbo.TimeInterval(th.start,th.stop , time_dialog,time_notes) as tdialog
	,dbo.TimeInterval(th.start,th.stop , time_notes,time_end_call) as tnotes	
	,dbo.TimeInterval(th.start,th.stop , dateStartDetail,dateadd(ss,tresp,dateStartDetail)) as tresp		
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nhangup else 0 end as nhangup
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
	,time_endque,time_ring,time_dialog,time_notes,time_end_call
	,phone_out,cal_id,cal_puerto
	,calif_id,califSub_id
	from #outboundData2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	and th.start between @from and @to

	insert into #tempccLogAgentesDia(row,[User_id],TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus)
	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,
	TipoStatusAge_id,tStatus,DATEADD(ss,-tStatus,fecha) dateIni, fecha dateEnd, isnull(currentStatus,-2)
	from ccLogAgentesDia
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to

	delete A from(
	select case when A.tStatus>S.tStatus then S.row else A.row end row,A.user_id
	from #tempccLogAgentesDia A
	left join #tempccLogAgentesDia S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id=S.TipoStatusAge_id
	and (S.dateEnd between A.dateIni and A.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
	and abs(DATEDIFF(ss,A.dateEnd,S.dateIni))>2
	)x
	inner join 	#tempccLogAgentesDia A on A.row=x.row and A.user_id=x.user_id

	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY dateIni) AS Row,User_id,TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus into #tempccLogAgentesDia2 from #tempccLogAgentesDia

	insert into #timeDetailAgent
	select A.user_id,A.dateIni,A.dateEnd
	,dbo.GetTimeGroup(A.dateIni,0) as timegroup
	,dbo.GetTimeGroup(A.dateEnd,1) as timegroup_next,
	case when A.tipostatusage_id=1 then A.tStatus else 0 end tunknown,
	case when A.tipostatusage_id=2 then A.tStatus else 0 end tnot_av,
	case when A.tipostatusage_id=3 then A.tStatus else 0 end tav,
	case when A.tipostatusage_id in(11,25,26,27) then A.tStatus else 0 end tprob,--11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
	case when A.tipostatusage_id=7 then A.tStatus else 0 end tother,
	case when A.tipostatusage_id=7 then 1 else 0 end nother,
	case when A.tipostatusage_id=21 then A.tStatus else 0 end tmanualcall,
	case when abs(isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) )>A.tStatus then 0
	when A.currentStatus in(0,-1,-2) then 0 --Logout
	when S.TipoStatusAge_id=1 then 0
	else isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) end	as tunknown2
	,case when A.tipostatusage_id in (23,24) then A.tStatus else 0 end  as tchatting
	from #tempccLogAgentesDia2 A
	left join #tempccLogAgentesDia2 S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id<>0

	update #timeDetailAgent set tunknown2=0  where abs(tunknown2)>2.7

	 insert into #timeDetailAgent(User_id,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tunknown,tnot_av,tav,tprob,tother,nother,tmanualcall,tunknown2,tchatting)
	 select
		User_id,
		B.fecha as dateStartDetail,
		@dateNow as dateEndDetail
		,dbo.GetTimeGroup(B.fecha,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1) as timegroup_next
		,case when currentStatus = 1 then tiempo else 0 end as tunknown,
		case when currentStatus = 2 then tiempo else 0 end as tnot_av,
		case when tipostatusage_id=1 then tiempo when currentStatus = 3 then tiempo else 0 end as tav,
		 0,0,0,0,0 as tunknown2
		,case when currentStatus in (23,24) then tiempo else 0 end as tchatting
		from ccLogAgentesDia A
		inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
		where A.currentStatus not in(-2,-1,0)

	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15
	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother,tmanualCall,tunknown2,tchatting)
	select
	dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,dbo.TimeInterval(th.start,th.stop , dateStartDetail,dateadd(ss,tunknown,dateStartDetail)) as tunknown
	,dbo.TimeInterval(th.start,th.stop , dateStartDetail,dateadd(ss,tnot_av,dateStartDetail)) as tnot_av
	,dbo.TimeInterval(th.start,th.stop , dateStartDetail,dateadd(ss,tav,dateStartDetail)) as tav
	,dbo.TimeInterval(th.start,th.stop , dateStartDetail,dateadd(ss,tprob,dateStartDetail)) as tprob
	,dbo.TimeInterval(th.start,th.stop , dateStartDetail,dateadd(ss,tother,dateStartDetail)) as tother
	,isnull((case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother	
	,dbo.TimeInterval(th.start,th.stop , dateStartDetail,dateadd(ss,tmanualCall,dateStartDetail)) as tmanualCall		
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tunknown2 else 0 end as tunknown2
	,dbo.TimeInterval(th.start,th.stop , dateStartDetail,dateadd(ss,tchatting,dateStartDetail)) as tchatting	
	from #timeDetailAgent2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	and th.start between @from and @to

	select
	ROW_NUMBER() OVER(PARTITION BY xTimeDetail.user_id ORDER BY xTimeDetail.timegroup) AS Row,
	xTimeDetail.timegroup
	,xTimeDetail.[user_id]
	,timeSession.tlog
	,xTimeDetail.tav,
	xTimeDetail.tnot_av
	,xTimeDetail.tprob,xTimeDetail.tother,xTimeDetail.tunknown,xTimeDetail.tchatting,xTimeDetail.tmanualCall
	,xTimeDetail.nother
	,isnull(B.txfer,0)+isnull(C.txfer,0) as txfer
	,isnull(B.tdialog,0)+isnull(C.tdialog,0) as tdialog
	,isnull(B.tnotes,0)+isnull(C.tnotes,0) as tnotes
	,isnull(B.tring,0)+isnull(C.tring,0) as tring
	,isnull(B.nMoh,0)+isnull(C.nMoh,0) as nMoh
	,isnull(B.nWHag,0)+isnull(C.nWHag,0) as nWHag
	,isnull(B.nWHcl,0)+isnull(C.nWHcl,0) as nWHcl
	,isnull(B.ntotal,0)+isnull(C.ntotal,0) as ntotal
	,C.completeOut, B.completeIn
	into #agentInformation
	from(
		select x.User_id,x.timegroup
		,case when sum(tunknown+tunknown2)>0 then sum(tunknown+tunknown2) else sum(tunknown) end as tunknown
		,sum(tnot_av) as tnot_av
		,case when sum(tav+tav2)>0 then sum(tav+tav2) else sum(tav) end as tav
		,case when sum(tprob+tprob2)>0 then sum(tprob+tprob2) else sum(tprob) end as tprob
		,case when sum(tother+tother2)>0 then sum(tother+tother2) else sum(tother) end as tother
		,case when sum(tmanualcall+tmanualcall2)>0 then sum(tmanualcall+tmanualcall2) else sum(tmanualcall) end as tmanualcall
		,sum(nother) as nother
		,case when sum(tchatting+tchatting2)>0 then sum(tchatting+tchatting2) else sum(tchatting) end as tchatting
			from(
		select User_id,timegroup
		,tunknown,tnot_av,tav,tprob,tother,tmanualcall,nother,tchatting
		,isnull(cast(case when tunknown>0 then tunknown2 else 0 end as int),0) as tunknown2
		,isnull(cast(case when tav>0 and (tav>abs(tunknown2) and (tunknown2+tav)>0 ) then tunknown2 else 0 end as int),0) as tav2
		,isnull(cast(case when tprob>0 then tunknown2 else 0 end as int),0) as tprob2
		,isnull(cast(case when tother>0 then tunknown2 else 0 end as int),0) as tother2
		,isnull(cast(case when tmanualcall>0 then tunknown2 else 0 end as int),0) as tmanualcall2
		,isnull(cast(case when tchatting>0 or (tchatting>abs(tunknown2) and (tunknown2+tchatting)>0 ) then tunknown2 else 0 end as int),0) as tchatting2
		from #timeDetailAgent A
		)x
		group by x.timegroup,x.User_id
	)xTimeDetail
	inner join
	(
		select user_id,timegroup,sum(tlog) as tlog from tmpSessionTimeGroup 
		where login between @from and @to
		group by user_id,timegroup
	) timeSession
	on xTimeDetail.User_id=timeSession.user_id and xTimeDetail.timegroup=timeSession.timegroup
	left join
	(
		select user_id,timegroup,sum(txfer) as txfer,sum(tring) tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl,
		case when sum(ntotal)<count(A.calif_id) then count(A.calif_id) else sum(ntotal) end as ntotal
		,sum(case when A.calif_id = @califin then 1 else 0 end) as completeIn		
		from #inboundData A
		inner join cctipocalif B on A.calif_id=B.calif_id --and A.calif_id = @califin			
		group by user_id,timegroup
	) B
	on xTimeDetail.timegroup=B.timegroup and xTimeDetail.User_id=B.User_id
	left join	
	(
		select user_id,timegroup,sum(txfer) as txfer,sum(tring) tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl,
		case when sum(ntotal)<count(A.calif_id) then count(A.calif_id) else sum(ntotal) end as ntotal
		,sum(case when A.calif_id = @califout then 1 else 0 end) as completeOut
		from #outboundData A
		inner join cctipocalifout B on A.calif_id=B.calif_id 
		group by user_id,timegroup
	) C
	on xTimeDetail.timegroup=C.timegroup and xTimeDetail.User_id=C.User_id

	update B
		set  B.tav=case when A.tav>0 and A.tav+A.tundefinded>=0 then A.tav+A.tundefinded else A.tav end
		from (
			select User_id,timegroup,tlog,tav,tnot_av,tprob,tother,tunknown,tchatting,tmanualCall,nother,txfer,tdialog,tnotes,tring,
			tlog-tav-tnot_av-tprob-tother-tunknown-tchatting-tmanualCall-nother-txfer-tdialog-tnotes-tring as tundefinded from #agentInformation
		)A
	inner join #agentInformation B on A.User_id=B.User_id and A.timegroup=B.timegroup
	where A.tundefinded<0 and A.tav+A.tundefinded>=0

	update B
		set  B.tunknown=case when A.tunknown>0 and A.tunknown+A.tundefinded>=0 then A.tunknown+A.tundefinded else A.tunknown end
		from (
			select User_id,timegroup,tlog,tav,tnot_av,tprob,tother,tunknown,tchatting,tmanualCall,nother,txfer,tdialog,tnotes,tring,
			tlog-tav-tnot_av-tprob-tother-tunknown-tchatting-tmanualCall-nother-txfer-tdialog-tnotes-tring as tundefinded from #agentInformation
		)A
	inner join #agentInformation B on A.User_id=B.User_id and A.timegroup=B.timegroup
	where A.tundefinded<0 and A.tunknown+A.tundefinded>=0


		delete from RepDetailAgent where date>=@from and date<@to

		insert into RepDetailAgent
		select
		A.User_Id,
		min(B.Login) as ''usuario'',
		min((B.Nombres + space(1) + b.ApellidoPaterno + space(1) + b.ApellidoMaterno)) ''NombreAgente'',
		convert(varchar(14),A.timegroup,120)+''00:00'' as [fecha],
		sum(A.tlog) ''Tiempo de sesion'',
		sum(a.tlog - tnot_av) as [Tiempo de operacion] -- tlog - tiempoAuxiliares
		,sum(txfer+tring+tdialog+tnotes) as [Tiempo en dialogo]
		,sum(txfer+tring) as [Tiempo en espera]
		,sum(tnot_av) as [Tiempo en no disponibles]
		,sum(cast((convert(float,tdialog)/36) as decimal(18,3))) as [% en dialogo]
		,sum(cast((convert(float,txfer+tring)/36) as decimal(18,3))) as [% en espera]
		,sum(cast((convert(float,tav)/36) as decimal(18,3))) as [% en disponible]
		,isnull(convert(decimal(10,3), convert(decimal(10,3),sum(tlog - tnotes))/sum(tlog)),0) as [Adherencia]
		,sum(ntotal) as [Numero de llamadas]
		,sum(ntotal) as [Numero de llamadas por hora]--convert(decimal(10,4),convert(decimal(10,4),sum(ntotal))/7) as [Numero de llamadas por hora]
		,count(completeOut)+count(completeIn) as [Completo]
		,convert(decimal(10,4),convert(decimal(10,4),count(completeOut)+count(completeIn))/7) as [Completo por hora]
		,convert(decimal(10,4),isnull(convert(decimal(10,4),count(completeOut)+count(completeIn))/nullif(sum(ntotal),0),0)) as [Completo / llamadas]
		,datepart(YYYY,min(A.timegroup)) [year]
		,datepart(MM,min(A.timegroup)) [month]
		,datepart(DD,min(A.timegroup)) [day]
		,datepart(HH,min(A.timegroup)) [hour]
		,''0'' [minutes]
		from #agentInformation A
		inner join ccUserView B on A.User_id=B.User_id
		group by convert(varchar(14),A.timegroup,120)+''00:00'', A.User_id

	---DROP TABLES TEMP	
	IF OBJECT_ID(''tempdb..#inboundData'') IS NOT NULL drop table #inboundData
	IF OBJECT_ID(''tempdb..#inboundData2'') IS NOT NULL drop table #inboundData2
	IF OBJECT_ID(''tempdb..#outboundData'') IS NOT NULL drop table #outboundData
	IF OBJECT_ID(''tempdb..#outboundData2'') IS NOT NULL drop table #outboundData2
	IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL drop table #timeDetailAgent
	IF OBJECT_ID(''tempdb..#timeDetailAgent2'') IS NOT NULL drop table #timeDetailAgent2
	IF OBJECT_ID(''tempdb..#agentInformation'') IS NOT NULL drop table #agentInformation	
	IF OBJECT_ID(''tempdb..#tempAgentLastStatus'') IS NOT NULL drop table #tempAgentLastStatus
	IF OBJECT_ID(''tempdb..#tempccLogAgentesDia'') IS NOT NULL drop table #tempccLogAgentesDia
	IF OBJECT_ID(''tempdb..#tempccLogAgentesDia2'') IS NOT NULL drop table #tempccLogAgentesDia2
	
end
END'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva ALTER SP ccspRepDialingResultsDetail'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepDialingResultsDetail]
@action as tinyint,
@from as datetime=null,
@to as datetime=null
AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

delete from  RepDialingResultsDetail where [date] between @from and @to

insert into RepDialingResultsDetail(date,telephone,dialResultId,dialResult,userId,login,campaignId,campaign,year,month,day,hour,minutes)
select dial.fecha as [date],dial.Telefono as [telephone],dial.tipoResDial_id as dialResultId,isnull(tr.descripcion,dial.disconnectCause) as dialResult,
isnull(co.User_id,0) as userId,isnull(cast(u.Login  as varchar(50)),''systemTranslated_NoUserName'') as [Login],
dial.cam_id as campaignId,isnull(camp.cam_descripcion,''N/A'') as campaign
,datepart(yyyy,dial.fecha) as [year]
,datepart(mm,dial.fecha) as [month]
,datepart(dd,dial.fecha) as [day]
,datepart(hh,dial.fecha) as [hour]
,datepart(mi,dial.fecha) as [minute]
FROM ccoLogDials dial (nolock)
left join ccocallsout co (nolock) on dial.cal_id=co.cal_id
left join cctipoResultadoDial tr ON dial.tiporesdial_id=tr.tiporesdial_id
left join ccUserView u on u.user_id =co.User_id
left join ccCamps camp on camp.cam_id=dial.cam_id
where dial.fecha>=@from and dial.fecha<@to


end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva ALTER SP ccspRepInCalls'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepInCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off
set ANSI_WARNINGS off

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()



if @action = 1
begin

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

IF OBJECT_ID(''tempdb..#callsin'') IS NOT NULL drop table #callsin
IF OBJECT_ID(''tempdb..#callsin2'') IS NOT NULL drop table #callsin2
IF OBJECT_ID(''tempdb..#agentInformation'') IS NOT NULL drop table #agentInformation
IF OBJECT_ID(''tempdb..#ccGenInSpec'') IS NOT NULL drop table #ccGenInSpec
IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL drop table #timeDetailAgent
IF OBJECT_ID(''tempdb..#timeDetailAgent2'') IS NOT NULL drop table #timeDetailAgent2

create table [#callsin](
row int identity,
dateStartDetail datetime,
dateEndDetail datetime,
timegroup datetime,
timegroup_next datetime,
time_endque datetime,
time_ring datetime,
time_dialog datetime,
time_notes datetime,
time_end_call datetime,
phone_in varchar(30),
cal_id int,
dni_id int,
Inbound_id int,
User_id int,
ntotal int,
ninitial int,
nout_hour int,
nout_service int,
nabnd int,
nno_agent int,
nque int,
ntimeout int,
noverflow int,
nxfer int,
nxfer_que int,
nabnd_xfer int,
nabnd_ring int,
nno_answer int,
nabnd_dialog int,
nanswer int,
nlost int,
nmsg int,
nabnd_tres int,
nansw_tres int,
tque_max int,
tque int,
txfer int,
tdialog int,
tnotes int,
tring int,
tresp int,
nMoh int,
nWHag int,
nWHcl int)

CREATE TABLE [dbo].[#ccGenInSpec](
[timegroup] [datetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[pos_tot] [smallint] NOT NULL,
[pos_time] [int] NOT NULL,
[pos_efect] [smallint] NOT NULL
) ON [PRIMARY]

------ Time Agent In ----------
insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
SELECT cal_inicio as dateStartDetail
	,dateadd(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),cal_inicio) as dateEndDetail
	,dbo.GetTimeGroup(cal_inicio,0)	 as timegroup
	,dbo.GetTimeGroup(dateadd(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),cal_inicio),1)	 as timegroup_next	
	,DATEADD(ss,isnull(cal_twait,0),cal_inicio) as time_endque
	,DATEADD(ss,isnull(cal_twait + cal_txfer,0),cal_inicio) as time_ring
	,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring,0),cal_inicio) as time_dialog
	,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog,0),cal_inicio) as time_notes
	,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,0),cal_inicio) as time_end_call
	,isnull(cal_Ani,0) as phone_in,cal_id,cin.dni_id,Inbound_id,[User_id]
	,1 AS ntotal
	,ISNULL(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END,0) AS ninitial
	,ISNULL(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END,0) AS nout_hour
	,ISNULL(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END,0) AS nout_service
	,ISNULL(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END,0) AS nabnd
	,ISNULL(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END,0) AS nno_agent
	,ISNULL(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END,0) AS nque
	,ISNULL(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END,0) AS ntimeout
	,ISNULL(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END,0) AS noverflow
	,ISNULL(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END,0) AS nxfer
	,ISNULL(CASE WHEN(cal_que>0 and statuscall_id in(11,15,13,16) ) OR (statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')	THEN 1 ELSE NULL END,0) AS nxfer_que
	,ISNULL(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END,0) AS nabnd_xfer
	,ISNULL(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END,0) AS nabnd_ring
	,ISNULL(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END,0) AS nno_answer
	,ISNULL(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END,0) AS nabnd_dialog
	,ISNULL(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END,0) AS nanswer
	,ISNULL(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END,0) AS nlost
	,ISNULL(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END,0) AS nmsg
	,ISNULL(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END,0) AS nabnd_tres
	,ISNULL(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END,0) AS nansw_tres
	,ISNULL(cal_twait,0)AS tque_max,ISNULL(cal_twait,0)AS tque,ISNULL(cal_txfer,0)AS txfer
	,ISNULL(cal_tdialog,0)AS tdialog,ISNULL(cal_tnotas,0)AS tnotes,ISNULL(cal_tring,0)AS tring
	,ISNULL(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END,0)AS tresp
	,ISNULL(case when cal_tMoh>0 then 1 else 0 end,0)as nMoh
	,ISNULL(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END,0)as nWHag,ISNULL(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END,0)as nWHcl
	FROM ccCallsIn cin with (nolock, index(IX_ccCallsIn))
	left join ccdnis dnis on dnis.dni_id = cin.dni_id
	WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0	

delete #callsin WHERE timegroup>=@from AND timegroup<@to AND INBOUND_ID>0
AND ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0

select * into #callsin2 from #callsin where datediff(mi,timegroup,timegroup_next)>15

delete #callsin where datediff(mi,timegroup,timegroup_next) > 15

insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
select
	dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next
	,time_endque,time_ring,time_dialog,time_notes,time_end_call
	,phone_in,cal_id,t.dni_id,Inbound_id,[User_id]
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ninitial else 0 end as ninitial
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_hour else 0 end as nout_hour
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_service else 0 end as nout_service
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd else 0 end as nabnd
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nque else 0 end as nque
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntimeout else 0 end as ntimeout
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then noverflow else 0 end as noverflow
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer_que else 0 end as nxfer_que
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nmsg else 0 end as nmsg
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_tres else 0 end as nabnd_tres
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nansw_tres else 0 end as nansw_tres
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tque_max else 0 end as tque_max
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,time_endque) as tque
	,dbo.TimeInterval(th.start ,th.stop, time_endque,time_ring) as txfer
	,dbo.TimeInterval(th.start ,th.stop, time_dialog,time_notes) as tdialog
	,dbo.TimeInterval(th.start ,th.stop, time_notes,time_end_call) as tnotes
	,dbo.TimeInterval(th.start ,th.stop, time_ring,time_dialog) as tring
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tresp,dateStartDetail)) as tresp	
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
	from #callsin2 t
	join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	left join ccdnis dnis on dnis.dni_id = t.dni_id
	where  datediff(ss,th.start,timegroup_next)>0
	and th.start between @from and @to
	order by cal_id

------------ Session Time Start ----------------


------ Time Agent Common ----------

select DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0) AS timegroup,
dbo.GetTimeGroup(fecha,1) as timegroup_next
		,[User_id]
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE 0 END),0) AS tunknown
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE 0 END),0) AS tnot_av
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE 0 END),0) AS tav
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE 0 END),0) AS tprob
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE 0 END),0) AS tother
		,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
		into #timeDetailAgent
	from ccLogAgentesDia
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
	GROUP BY
	dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0),	
	dbo.GetTimeGroup(fecha,1), [User_id]	
		
select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15

delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother)
select
	dateStartDetail, dateEndDetail,th.start as timegroup,th.stop as timegroup_next, [User_id]
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tunknown,dateStartDetail)) as tunknown
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tnot_av,dateStartDetail)) as tnot_av
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tav,dateStartDetail)) as tav2	
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tprob,dateStartDetail)) as tprob
	,dbo.TimeInterval(th.start ,th.stop, dateStartDetail,dateadd(ss,tother,dateStartDetail)) as tother2	
	,isnull(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end,0) as nother
from #timeDetailAgent2 t
inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0
and th.start between @from and @to

;
with sessionTimeGroup as (

select session.timegroup, session.user_id
,isnull(sum(session.tlog),0) as tlog
from TmpSessionTimeGroup as session 
where login between @from and @to
group by session.timegroup,session.user_id
),
callin as (
select 
callin.timegroup,callin.user_id
,isnull(sum(callin.txfer),0) txfer,isnull(sum(callin.tdialog),0) tdialog,isnull(sum(callin.tnotes),0) tnotes
,isnull(sum(callin.tring),0) tring,isnull(sum(callin.nMoh),0) nMoh,isnull(sum(callin.nWHag),0) nWHag,isnull(sum(callin.nWHcl),0) nWHcl
from #callsin callin
group by callin.timegroup,callin.user_id
), timeAgent as(
select timeAgent.timegroup,timeAgent.user_id,isnull(sum(timeAgent.tnot_av),0) as tnot_av,isnull(sum(timeAgent.tav),0) tav
,isnull(sum(timeAgent.tprob),0) tprob, isnull(sum(timeAgent.tother),0) tother,isnull(sum(timeAgent.tunknown),0) tunknown
,isnull(sum(timeAgent.nother),0) nother
from #timeDetailAgent timeAgent
group by timeAgent.timegroup,timeAgent.user_id
)

select ROW_NUMBER() OVER(ORDER BY session.timegroup,session.[user_id] ) AS Row,
session.timegroup, session.user_id
,isnull(timeAgent.tnot_av,0) as tnot_av,isnull(timeAgent.tav,0) tav,isnull(timeAgent.tprob,0) tprob
,isnull(timeAgent.tother,0) tother,isnull(timeAgent.tunknown,0) tunknown,isnull(timeAgent.nother,0) nother
,isnull(callin.txfer,0) txfer,isnull(callin.tdialog,0) tdialog,isnull(callin.tnotes,0) tnotes
,isnull(callin.tring,0) tring,isnull(callin.nMoh,0) nMoh,isnull(callin.nWHag,0) nWHag,isnull(callin.nWHcl,0) nWHcl
,isnull(session.tlog,0) as tlog
into #agentInformation
from sessionTimeGroup as session 
left join timeAgent on timeAgent.User_id=session.user_id and timeAgent.timegroup=session.timegroup
left join callin on callin.User_id=session.user_id and session.timegroup=callin.timegroup
order by session.timegroup

INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
select timegroup, B.inbound_id
, COUNT(DISTINCT B.[user_id]) AS pos_max -- pos_tot
	,SUM (tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog- (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
from #agentInformation X
INNER JOIN ccInboundAgentes B ON X.[user_id] = B.[user_id]
WHERE timegroup >= @from AND timegroup < @to  
group by timegroup, B.inbound_id

--Borrar lo que esta para no repetir
delete from [RepInCalls] where date >= @from AND date < @to

;
with callsin as(
select timegroup as tg
	,inbound_id as inboundId,	dni_id	
	,ntotal, nxfer, nabnd as nabnd_que, nxfer_que,
	(ninitial + nout_service + nout_hour + nno_agent + ntimeout + noverflow ) nno_xfer , tque_max,
	tque, NULLIF(nque, 0) nque , nanswer, nno_answer , nlost,
		(nabnd_xfer) nabnd_xfer , nabnd_ring, nabnd_dialog
		--,0 as pos_tot, 0 as pos_time --completar		
		, (nansw_tres + nabnd_tres) AS SL_P_1 ,
		(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2
		,ISNULL(tque/ NULLIF(nque, 0), 0) as [avg]
		--,ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0) SL
		,nMoh,  nWHag	,nWHcl
		,DATEPART(yyyy,timegroup) as [year]
		,DATEPART(mm,timegroup) as [mounth]
		,DATEPART(dd,timegroup) as [day]
		,DATEPART(hh,timegroup) as [hour]
		,DATEPART(mi,timegroup) as [minute]
		,cal_id,phone_in	,dateStartDetail
		FROM #callsin		
),
wgByAcd as(
	select max(IDWG) as IDWG,Inbound_id,descripcion from ccWgByAcdView
	group by Inbound_id,descripcion
)

insert into [RepInCalls]
select tg as date,inboundId,ccInbound.descripcion as  inbound
,xDetail.dni_id,isnull(ccDnis.dni_Descripcion,''S/DNIS'') as dnis
,wgByAcd.IDWG workgroupId,isnull(wgByAcd.descripcion,'''') workgroup,ccInbound.IDArea areaID,D.AreaName area
,ntotal,nxfer,nabnd_que,nxfer_que,nno_xfer,tque_max,tque,isnull(nque,0) as nque,nanswer
,nno_answer,nlost,nabnd_xfer,nabnd_ring,nabnd_dialog
,spec.pos_tot pos_tot,spec.pos_tot pos_time
,SL_P_1,SL_P_2,avg,ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0) SL
,nMoh,nWHag,nWHcl
,year,mounth,day,hour,minute,cal_id,phone_in,dateStartDetail,isnull(dni_numero,'''') as DniNumber
 from callsin xDetail
 INNER JOIN ccInbound ON xDetail.inboundId = ccInbound.inbound_id
 LEFT JOIN ccDnis ON xDetail.dni_id = ccDnis.dni_id
 INNER join wgByAcd on wgByAcd.Inbound_id=ccinbound.Inbound_id
 INNER JOIN ccriacat_areas D ON D.IDArea = ccInbound.IDArea
 inner join #ccGenInSpec spec on spec.timegroup=xDetail.tg and spec.inbound_id=xDetail.inboundId
 --order by tg


IF OBJECT_ID(''tempdb..#callsin'') IS NOT NULL drop table #callsin
IF OBJECT_ID(''tempdb..#callsin2'') IS NOT NULL drop table #callsin2
IF OBJECT_ID(''tempdb..#agentInformation'') IS NOT NULL drop table #agentInformation
IF OBJECT_ID(''tempdb..#ccGenInSpec'') IS NOT NULL drop table #ccGenInSpec
IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL drop table #timeDetailAgent
IF OBJECT_ID(''tempdb..#timeDetailAgent2'') IS NOT NULL drop table #timeDetailAgent2
end
'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva ALTER SP ccspRepInCallsDetail'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepInCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS

SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()



IF @action = 1
BEGIN
	DECLARE @tab TABLE (callId INT PRIMARY KEY, [Dato1] VARCHAR(255), [Dato2] VARCHAR(255), [Dato3] VARCHAR(255), [Dato4] VARCHAR(255), [Dato5] VARCHAR(255))

	INSERT INTO @tab
	SELECT callId, [Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5]
	FROM (
		SELECT A.CallId, [Data], [Description]
		FROM DataCallIn A
		INNER JOIN ccCallsIn B ON A.CallId = B.cal_id
		WHERE b.cal_Inicio >= @from AND b.cal_Inicio < @to
		) AS SourceTable
	pivot(max([Data]) FOR [Description] IN ([Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5])) AS pvt

	--Borrar lo que esta para no repetir
	DELETE
	FROM RepInCallsDetail
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepInCallsDetail (DATE, callid, inboundId, ACDGroup, callStatusId, callStatus, dispositionId, disposition, subDispositionId, subDisposition, dnisId, dnis, userId, [user], callKey, ANI, queueTime, xferTime, ringingTime, dialogTime, extension, agentName, whoHangUp, mohTime, year, month, day, hour, minutes, provedorId, provider, trunk, fileMoved, twrapup, AverageHandleTime, Dato1, Dato2, Dato3, Dato4, Dato5, grabId)
	SELECT cal_inicio, 
       a.cal_id, 
       a.Inbound_id,
       ISNULL(ccIn.descripcion, '''') AS Inbound, 
       a.statusCall_id, 
       ISNULL(statusLlamada.descripcion, '''') AS statusCall, 
       a.calif_id, 
       ISNULL(disposition.description, '''') AS calif, 
       ISNULL(a.califSub_id, 0), 
       ISNULL(subDisposition.califSubDesc, '''') AS califSub, 
       a.dni_id, 
       ISNULL(dnis.dni_numero, '''') AS dni, 
       a.user_id, 
       ISNULL(LOGIN, '''') AS [user], 
       ISNULL(a.cal_key, '''') as cal_key, 
       cal_ANI, 
       cal_tWait, 
       cal_tXfer, 
       cal_tRing, 
       cal_tDialog, 
       a.cal_extension, 
       ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''') AS agentName,
       CASE
           WHEN a.cal_whoHung = 0
           THEN ''systemTranslated_Client''
           WHEN a.cal_whoHung = 1
           THEN ''systemTranslated_Agent''
           ELSE ''systemTranslated_AgentSurvey''
       END [whoHangUp], 
       a.cal_tMoh, 
       DATEPART(yyyy, cal_inicio) [year], 
       DATEPART(mm, cal_inicio) [month], 
       DATEPART(dd, cal_inicio) [day], 
       DATEPART(hh, cal_inicio) [hour], 
       DATEPART(mi, cal_inicio) [minute], 
       di.provedor_id, 
       prov.descrip [Proveedor], 
       a.cal_puerto,
       CASE
           WHEN a.file_moved = 1
           THEN ''systemTranslated_Remoto''
           ELSE ''Local''
       END AS file_Moved, 
       cal_tNotas, 
       AverageHandleTime = cal_tNotas + cal_tDialog, 
       ISNULL(tab.Dato1, '''') AS Dato1, 
       ISNULL(tab.Dato2, '''') AS Dato2, 
       ISNULL(tab.Dato3, '''') AS Dato3, 
       ISNULL(tab.Dato4, '''') AS Dato4, 
       ISNULL(tab.Dato5, '''') AS Dato5, 
       ISNULL(rc.cal_id, 0) AS grabId
FROM cccallsin a
     LEFT JOIN ccoDialers di ON di.dialer_id = a.cal_puerto
     LEFT JOIN cstoProvedor prov ON di.provedor_id = prov.provedor_id
     LEFT JOIN @tab tab ON tab.callId = a.cal_id
     LEFT JOIN Ria_grabacion rc ON rc.cal_id = a.cal_id and rc.tipo_llamada=1
     LEFT JOIN ccInbound ccIn ON a.Inbound_id = ccIn.Inbound_id
     LEFT JOIN ccstatusllamada statusLlamada ON a.statusCall_id = statusLlamada.statusCall_id
     LEFT JOIN cctipocalif disposition ON a.calif_id = disposition.calif_id
     LEFT JOIN cctipocalifsub subDisposition ON a.califSub_id = subDisposition.califSub_id
     LEFT JOIN ccdnis dnis ON a.dni_id = dnis.dni_id
     LEFT JOIN ccUserView ccuser ON a.User_id = ccuser.user_id
WHERE cal_inicio >= @from
      AND cal_inicio < @to;

END'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva ALTER SP ccspRepInEffectiveness'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepInEffectiveness]  
@action as tinyint,  
@from as datetime = null,  
@to as datetime = null  
AS  
  
set nocount on  
set ansi_nulls off   
set ANSI_WARNINGS off  
  
if @from is null  
	select @from = convert(datetime,convert(varchar(11),getdate()))  
if @to is null
	select @to = getdate()  
  
DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime  
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)  
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint  
  
EXEC @tresRing=ccspConfigTresRing  
EXEC @tresDialog=ccspConfigTresDialog  
EXEC @tresDelayIn=ccspConfigtresDelayIn  
  
if @action = 1  
begin  
--Consulta de agentes conectados agrupados por hora e inboundid
		create table #RtnValue(
		IDWG int,
		Inbound_id int,
		extension varchar(100),
		user_id int,
		subLogin datetime,
		subLogout dateTime,
		sessionMinutes int,
		fechaInicio datetime,
		fechaFinal datetime
		)
		
		create nonclustered index ix_RtnValue on #RtnValue(
		[subLogin] DESC,
		[subLogout] DESC
		)

		create nonclustered index ix_RtnValue2 on #RtnValue(
		[subLogin] DESC,
		[subLogout] DESC
		)

		create table #RtnValue2(
		IDWG int,
		Inbound_id int,
		extension int,
		user_id int,
		subLogin datetime,
		subLogout dateTime,
		sessionMinutes int,
		fechaInicio datetime,
		fechaFinal datetime)

		create nonclustered index ix_RtnValue on #RtnValue2(
		[subLogin] DESC,
		[subLogout] DESC
		)
		declare @starttime datetime
		declare @number int
		set @starttime = @from
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

		while @number <= (datediff(mi,@starttime,getdate())/60)
		begin
			insert into #times
			SELECT [Hour] = @number,
			StartTime = DATEADD(mi, @number*60, @starttime),
			EndTime = DATEADD(mi, (@number+1)*60, @StartTime)

			set @number = @number +1
		end


		insert into #RtnValue
		select x.IDWG,x.Inbound_id,x.Extension,x.User_id,x.subLogin,x.subLogout, DATEDIFF(mi,x.sublogin,x.sublogout) as sessionMinutes,null,null from (
		select d.IDWG, d.Inbound_id, a.extension, a.user_id, a.fecha as subLogin,
		(select isnull(max(Fecha),getdate()) from ccLogLogin b with(nolock)
		where b.user_id = a.user_id and b.tipomov = 0 and  b.fecha >= a.fecha and b.fecha <=
		( select isnull(min(fecha),''99991231 23:59:59.998'') from ccLogLogin with(nolock)
		where user_id = b.user_id and tipomov = 1 and fecha > a.fecha)
		) as subLogout
		 from ccLogLogin a
		inner join ccinboundagentes d  on a.user_id = d.User_id
		where a.tipomov=1 and fecha >= @from and fecha <= @to
		)as x
						
		
		insert into #RtnValue2
		select x.IDWG,x.Inbound_id,x.Extension,x.User_id,x.subLogin,x.subLogout, x.sessionMinutes,th.Start,th.Stop
		from #RtnValue x
		join #times th on (x.subLogin > th.Start and x.subLogin < th.stop) OR th.Start between x.subLogin and x.subLogout
		

		create table #RtnValue3(
		cont int ,
		user_id int,
		Inbound_id int,
		fechaInicio datetime,
		fechaFinal datetime)
		
		insert into #RtnValue3
		select distinct 1,user_id,Inbound_id,fechaInicio,fechaFinal from #RtnValue2 order by fechaInicio,fechaFinal,Inbound_id	 

		create table #AgentsperInbound(
		NumberAgents int ,
		fechaInicio datetime,
		fechaFinal datetime,
		Inbound_id int)
		
		INSERT INTO #AgentsperInbound
		select sum(cont) as NumberAgents,fechaInicio,fechaFinal,Inbound_id from #RtnValue3 group by fechaInicio,fechaFinal,Inbound_id
		
		
--Fin consulta agentes conectados por inbound

CREATE TABLE [dbo].[#ccGenInCall](  
[timegroup] [smalldatetime] NOT NULL,  
[inbound_id] [smallint] NOT NULL,  
[dni_id] [smallint] NOT NULL,  
[user_id] [smallint] NOT NULL,  
[ntotal] [smallint] NOT NULL,  
[ninitial] [smallint] NOT NULL,  
[nout_hour] [smallint] NOT NULL,  
[nout_service] [smallint] NOT NULL,  
[nabnd] [smallint] NOT NULL,  
[nno_agent] [smallint] NOT NULL,  
[nque] [smallint] NOT NULL,  
[ntimeout] [smallint] NOT NULL,  
[noverflow] [smallint] NOT NULL,  
[nxfer] [smallint] NOT NULL,  
[nxfer_que] [smallint] NOT NULL,  
[nabnd_xfer] [smallint] NOT NULL,  
[nabnd_ring] [smallint] NOT NULL,  
[nno_answer] [smallint] NOT NULL,  
[nabnd_dialog] [smallint] NOT NULL,  
[nanswer] [smallint] NOT NULL,  
[nlost] [smallint] NOT NULL,  
[nmsg] [smallint] NOT NULL,  
[nabnd_tres] [smallint] NOT NULL,  
[nansw_tres] [smallint] NOT NULL,  
[tque_max] [smallint] NOT NULL,  
[tque] [int] NOT NULL,  
[txfer] [int] NOT NULL,  
[tdialog] [int] NOT NULL,  
[tnotes] [int] NOT NULL,  
[tring] [int] NOT NULL,  
[tresp] [int] NOT NULL,  
[nMoh] [smallint] NOT NULL DEFAULT ((0)),  
[nWHag] [smallint] NOT NULL DEFAULT ((0)),  
[nWHcl] [smallint] NOT NULL DEFAULT ((0))  
) ON [PRIMARY]  
  
CREATE TABLE [dbo].[#ccGenSession](  
[user_id] [smallint] NOT NULL,  
[login] [datetime] NOT NULL,  
[logout] [datetime] NOT NULL,  
[extension] [varchar](7) NOT NULL  
) ON [PRIMARY]  
  
CREATE TABLE [dbo].[#agents](  
[timegroup] [smalldatetime] NOT NULL,  
[user_id] [smallint] NOT NULL,  
[tlog] [int] NOT NULL DEFAULT (0),  
[treq] [int] NOT NULL DEFAULT (0),  
[tnot_av] [int] NOT NULL,  
[tav] [int] NOT NULL DEFAULT (0),  
[tprob] [int] NOT NULL DEFAULT (0),  
[tunknown] [int] NOT NULL DEFAULT (0),  
[tother] [int] NOT NULL DEFAULT (0),  
[nother] [int] NOT NULL DEFAULT (0),  
[nMoh] [int] NOT NULL DEFAULT ((0)),  
[nWHag] [int] NOT NULL DEFAULT ((0)),  
[nWHcl] [int] NOT NULL DEFAULT ((0))  
) ON [PRIMARY]    
  
CREATE TABLE [dbo].[#ccGenInSpec](  
[timegroup] [smalldatetime] NOT NULL,  
[inbound_id] [smallint] NOT NULL,  
[pos_tot] [smallint] NOT NULL,  
[pos_time] [int] NOT NULL,  
[pos_efect] [smallint] NOT NULL  
) ON [PRIMARY]  
  
CREATE TABLE [dbo].[#ccGenInAbnd](  
[timegroup] [smalldatetime] NOT NULL,  
[inbound_id] [smallint] NOT NULL,  
[amount] [smallint] NOT NULL,  
[time_max] [smallint] NOT NULL,  
[time_tot] [bigint] NOT NULL,  
[<10] [smallint] NOT NULL,  
[<20] [smallint] NOT NULL,  
[<30] [smallint] NOT NULL,  
[<40] [smallint] NOT NULL,  
[<50] [smallint] NOT NULL,  
[<60] [smallint] NOT NULL,  
[<120] [smallint] NOT NULL,  
[<180] [smallint] NOT NULL,  
[<240] [smallint] NOT NULL,  
[<300] [smallint] NOT NULL,  
[+300] [smallint] NOT NULL  
) ON [PRIMARY]  
  
INSERT INTO #ccGenInCall(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque  
,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg  
,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)  
SELECT timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow  
,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres  
,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl  
FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial  
,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent  
,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer  
,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer  
,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg  
,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque  
,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh  
,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl  
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id,[user_id]  
,COUNT(cal_id)AS ntotal  
,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial  
,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour   
,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service  
,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(isnull(cal_xfer,'''') = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd   
,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent  
,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que   
,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout  
,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow  
,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS xfer  
,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END)AS xfer_que  
,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer  
,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring  
,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer  
,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog  
,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer  
,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost  
,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg  
,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres  
,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres  
,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer  
,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring  
,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh  
,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl  
FROM ccCallsIn with (nolock, index(IX_ccCallsIn))  
WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0  
GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id,[user_id])xDetailCount  
right JOIN(SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer  
,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes  
FROM(SELECT timegroup,inbound_id,dni_id,[user_id]  
,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait  
,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer  
,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring  
,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog  
,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas  
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup  
,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next  
,DATEADD(ss,cal_twait,cal_inicio) AS time_endque  
,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring  
,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog  
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes  
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call  
,*  
FROM ccCallsIn with (nolock, index(IX_ccCallsIn))  
WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail  
UNION  
SELECT timegroup_next,inbound_id,dni_id,[user_id]  
,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait  
,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer  
,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring  
,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog  
,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas  
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup  
,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next  
,DATEADD(ss,cal_twait,cal_inicio) AS time_endque  
,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring  
,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog  
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes  
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call  
,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail  
GROUP BY timegroup,inbound_id,dni_id,[user_id])xDetailTime  
ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id=xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete  
WHERE timegroup>=@from AND timegroup<@to  
AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0  
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0  
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0  
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)  
ORDER BY timegroup,inbound_id,dni_id,[user_id]  
  
INSERT INTO #ccGenSession ([user_id], extension, login, logout)  
SELECT uid, max(ext) ext, login, max(logout) logout  
FROM   
(SELECT uid, ext, login, ISNULL(logout, (SELECT MIN(fecha) FROM ccLogLogin /*with (nolock, index(ccLogLogin_fecha))*/  
WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout   
FROM  
 (SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout  
 FROM   
  (SELECT uid, ext, MAX(login) as login, logout  
  FROM  
   (SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha)   
   FROM ccLogLogin subLogin /*with (nolock, index(ccLogLogin_fecha))*/ WHERE subLogin.tipomov = 0   
   AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout]   
   FROM ccLogLogin Login /*with (nolock, index(ccLogLogin_fecha))*/  
   WHERE login.fecha >= dateadd(dd, -5, @from) and tipomov = 1  
   GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail   
  WHERE logout IS NOT NULL GROUP BY uid, ext, logout) Login   
 RIGHT OUTER JOIN ccLogLogin  /*with (nolock, index(ccLogLogin_fecha))*/  
 ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login AND ccLogLogin.extension = Login.ext)  
 WHERE tipomov = 1  
 and ccLogLogin.fecha >= dateadd( dd, -5, @from)) Det   
) LoginDetail   
WHERE logout IS NOT NULL  
AND login >= @from and login < @to  
GROUP BY uid, login  
  
INSERT INTO #agents(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl)  
SELECT timegroup,[user_id],tlog,tnot_av  
,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav  
,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob  
,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown  
,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother  
,nother,nMoh,nWHag,nWHcl  
FROM(  
 SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother  
  ,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl  
  FROM(  
  SELECT   
   xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother  
   ,ISNULL(SUM(#ccGenInCall.txfer),0) as txfer  
   ,ISNULL(SUM(#ccGenInCall.tdialog),0) as tdialog  
   ,ISNULL(SUM(#ccGenInCall.tnotes),0) as tnotes  
   ,ISNULL(SUM(#ccGenInCall.tring),0) as tring  
   ,ISNULL(SUM(#ccGenInCall.nMoh),0) as nMoh  
   ,ISNULL(SUM(#ccGenInCall.nWHag),0) as nWHag  
   ,ISNULL(SUM(#ccGenInCall.nWHcl),0) as nWHcl  
  
   ,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)  
       FROM #ccGenSession  
       WHERE [user_id]=xTimeDetail.[user_id]  
       AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)  
    ),0)AS t1  
   ,ISNULL((SELECT top 1 3600  
       FROM #ccGenSession  
       WHERE [user_id]=xTimeDetail.[user_id]  
       AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)  
    ),0)AS t2  
   ,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))  
       FROM #ccGenSession  
       WHERE [user_id]=xTimeDetail.[user_id]  
       AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)  
    ),0)AS t3  
   ,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))  
       FROM #ccGenSession  
       WHERE [user_id]=xTimeDetail.[user_id]  
       AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)  
    ),0)AS t4  
  
   FROM(  
    SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup  
     ,ccLogAgentesDia.[user_id]  
     ,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown  
     ,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av  
     ,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav  
     ,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob  
     ,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother  
     ,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother  
     FROM ccLogAgentesDia  
     WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to  
     GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]  
   )xTimeDetail  
    LEFT OUTER JOIN #ccGenInCall ON(xTimeDetail.timegroup=#ccGenInCall.timegroup AND xTimeDetail.[user_id]=#ccGenInCall.[user_id])  
   GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown  
  )xDetail  
)xAllTimes  
WHERE tlog>0  
ORDER BY timegroup,[user_id]  
  
INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)  
SELECT timegroup, ccInboundAgentes.inbound_id  
 , COUNT(DISTINCT #agents.[user_id]) AS pos_max -- pos_tot  
 , SUM(tlog - (tnot_av + tprob + tother)) AS pos_time  
 , COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos  
 FROM #agents  
 INNER JOIN ccInboundAgentes ON (#agents.[user_id] = ccInboundAgentes.[user_id])  
 WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0  
 GROUP BY timegroup, ccInboundAgentes.inbound_id  
  
insert into #ccGenInAbnd (timegroup, inbound_id, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])  
SELECT timegroup  
, inbound_id  
, COUNT(cal_inicio) AS amount  
, MAX(tAbnd) AS time_max  
, SUM(tAbnd) AS time_tot  
, COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [<10]  
, COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [<20]  
, COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [<30]  
, COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [<40]  
, COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [<50]  
, COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [<60]  
, COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [<120]  
, COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [<180]  
, COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [<240]  
, COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [<300]  
, COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [+300]  
FROM (  
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup  
 , cal_inicio  
 , inbound_id  
 , statuscall_id  
 , (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,'''') = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd   
 , (cal_twait + cal_txfer + cal_tring) AS tAbnd  
 FROM ccCallsIn  
 WHERE cal_inicio >= @from AND  cal_inicio < @to  
 AND INBOUND_ID > 0  
) xCalls  
WHERE (abnd IS NOT NULL)   
GROUP BY timegroup, inbound_id  
  
--Borrar lo que esta para no repetir  
delete from RepInEffectiveness with(rowlock)  
where date >= @from AND date < @to  
  
insert into RepInEffectiveness  
SELECT timegroup as date, xDetail.inbound_id, isnull(descripcion, ''systemTranslated_NoACDGroup'') descripcion , ntotal, nanswer, nabnd , isnull(tatention / nullif(nanswer,0),0),   
tque_avg as tqueavg, tQue_tot as tQuetot, nQue_tot as nQuetot, isnull(tabnd_tot / NULLIF(nabnd,0),0) as avgAbandonTime, SL_P_1 as SLP1, SL_P_2 as SLP2, tresp,   
/*pos_tot as postot,*/ pos_count as poscount, ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0)  as Porcentaje  
, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]  
, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]  
, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]  
, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]  
, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]   
, convert(decimal(10,2),(nabnd/nullif(convert(decimal(10,2),ntotal),0))*100) as [avgAbandon]  
, tabnd_tot as tabndtot  
FROM (   
  
SELECT ISNULL(xDetCall.timegroup, ISNULL(xDetSpec.timegroup, xDetAbnd.timegroup)) timegroup, ISNULL(xDetCall.inbound_id,   
ISNULL(xDetSpec.inbound_id, xDetAbnd.inbound_id)) inbound_id, ISNULL(ntotal, 0) ntotal, ISNULL(nanswer, 0) nanswer, ISNULL(nabnd, 0) nabnd,   
ISNULL(tatention, 0) tatention, ISNULL(tque_avg, 0) tque_avg, isnull(tQue_tot, 0) tQue_tot, isnull(nQue_tot, 0) nQue_tot, ISNULL(tabnd_tot, 0) tabnd_tot,   
ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2, ISNULL(tresp, 0) tresp, ISNULL(pos_tot, 0) pos_tot, ISNULL(pos_count, 0) pos_count  
  
FROM (  
  
SELECT timegroup, inbound_id, SUM(ntotal) AS ntotal, SUM(nanswer) AS nanswer, SUM(nabnd) AS nabnd, SUM(tdialog + tnotes) tatention,   
ISNULL(sum(tque)/ NULLIF(sum(nque), 0), 0) AS tque_avg, sum(tque) as tQue_tot, sum(nQue) as nQue_tot, SUM(nansw_tres + nabnd_tres) AS SL_P_1,   
SUM(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, SUM(tresp) AS tresp  
FROM #ccGenInCall    
WHERE timegroup >= @from  
AND timegroup < @to   
GROUP BY timegroup , inbound_id) xDetCall    
LEFT JOIN (  
SELECT timegroup, inbound_id, SUM(pos_tot) AS pos_tot, SUM(pos_tot) AS pos_avg, SUM(pos_efect) AS pos_efect, COUNT(pos_tot) AS pos_count    
FROM #ccGenInSpec   
WHERE timegroup >= @from  
AND timegroup < @to   
GROUP BY timegroup , inbound_id) xDetSpec   
ON (xDetCall.timegroup = xDetSpec.timegroup AND xDetCall.inbound_id = xDetSpec.inbound_id)    
LEFT JOIN (  
SELECT timegroup, inbound_id, SUM(time_tot) AS tabnd_tot     
FROM #ccGenInAbnd    
WHERE timegroup >= @from   
AND timegroup < @to   
GROUP BY timegroup , inbound_id) xDetAbnd   
ON (xDetCall.timegroup = xDetAbnd.timegroup AND xDetCall.inbound_id = xDetAbnd.inbound_id)   
) xDetail    
LEFT JOIN ccInbound ON (xDetail.inbound_id=ccInbound.inbound_id)    
ORDER BY date  
--Update numero de agentes del reporte de efectividad por hora e inbound_Id
update RepInEffectiveness set poscount = ISNULL((select NumberAgents from #AgentsperInbound where fechaInicio = [dbo].[RepInEffectiveness].date and Inbound_Id=[dbo].[RepInEffectiveness].inboundId),0)

drop table #ccGenInCall  
drop table #ccGenInSpec  
drop table #ccGenSession  
drop table #agents  
drop table #ccGenInAbnd  
drop table #times
drop table #RtnValue
drop table #RtnValue2
drop table #RtnValue3
drop table #AgentsperInbound
end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva ALTER SP ccspRepMKTDiarioTiemposTotales'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepMKTDiarioTiemposTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

declare @dateNow datetime,@maxLogout datetime

if @action = 1
begin



select 
	convert(datetime,convert(date,login)) fecha,
	SUM(DATEDIFF(ss, login, logout)) t_ses,
	count(distinct user_id) user_id
into #infoSession
from TmpSessionGeneral
GROUP BY convert(datetime,convert(date,login))

SELECT 
		i.cal_Inicio as [date],
		i.user_id as acduser,
		i.Inbound_id as inboundId,
		case when i.statuscall_id=13 then i.cal_tmoh else 0 end thold,
		case when i.statusCall_id=13 then i.cal_tring else 0 end tring,
		case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end tacd,
		case when i.statusCall_id=13 then i.cal_tnotas else 0 end tacw,
		case when i.statusCall_id=13 then 1 else null end nacd,
		case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else null end nacw,
		case when i.statusCall_id=13 and i.cal_tmoh>0 then 1 else null end nhold,
		case when i.statusCall_id=13 and i.cal_tring>0 then 1 else null end nring	
	into #inboundData2			
	FROM	cccallsin i (NOLOCK)	
	WHERE	i.cal_inicio between @from and @to

SELECT user_id AS agtuser_id,
	login AS agtlogin,
	ISNULL(apellidopaterno,'''')+'' ''+ISNULL(apellidomaterno,'''')+'' ''+ISNULL(nombres,'''') agt_name
	into #users
	FROM ccUserView (NOLOCK)

	delete from [RepMKTDiarioTiemposTotales] with(rowlock) 	where date >= @from AND date <= @to 

	insert RepMKTDiarioTiemposTotales 
	select c.[date]	--
		,isnull(l.agtlogin,''N/A'') as [OpaId]
		,isnull(l.agt_name,'''') [NombreDeOperadora]
		,[InboundID]--
		,[TiempoPromACD]--
		,[TiempoPromACW]--
		,[TiempoPromReten]
		,[TiempoPromRing]
		,[AHT]
		,[LlamadasAtendidas]
		,DATEPART(YYYY, c.[date]) as [year] 
		,DATEPART(mm, c.[date]) as [month]
		,DATEPART(dd, c.[date]) as [day]
		,DATEPART(hh, c.[date]) as [hour]
		,DATEPART(mi, c.[date]) as [minutes]
	 from (
		select convert(datetime,convert(date,[date])) as [date],
			acduser as [user],
			inboundId as [InboundId]
			,case when sum(c.nacd)>0 then sum(c.tacd)/sum(c.nacd) else 0 end as [TiempoPromACD]
			,case when sum(c.nacw)>0 then sum(c.tacw)/sum(c.nacw) else 0 end as [TiempoPromACW]
			,case when sum(c.nhold)>0 then sum(c.thold)/sum(c.nhold) else 0 end as [TiempoPromReten]
			,case when sum(c.nring)>0 then sum(c.tring)/sum(c.nring) else 0 end as [TiempoPromRing]
			,sum(((case when c.nacd>0 then c.tacd/c.nacd else 0 end)+(case when c.nacw>0 then c.tacw/c.nacw else 0 end)+(case when c.nring>0 then c.tring/c.nring else 0 end)+(case when c.nhold>0 then c.thold/c.nhold else 0 end))) [AHT]
			,isnull(sum(c.nacd),0) as [LlamadasAtendidas]
		from #inboundData2 as c 
		group by convert(datetime,convert(date,[date])),inboundId,acduser
	) c
	LEFT JOIN #infoSession G on G.fecha = c.date
	left join #users l on [user]=l.agtuser_id	
	WHERE @from <= C.[date] AND @to >= c.[date] and [LlamadasAtendidas]>0
	order by [date]

drop table #inboundData2
drop table #infoSession 
drop table #users

end
'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva ALTER SP ccspRepMKTIntervalos'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepMKTIntervalos]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off
set ANSI_WARNINGS off


if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1
begin
	
	IF OBJECT_ID(''tempdb..#sessionTimeGroup'')  IS NOT NULL  drop table #sessionTimeGroup
	IF OBJECT_ID(''tempdb..#inbound'')  IS NOT NULL  drop table #inbound
	IF OBJECT_ID(''tempdb..#inboundTimeMayores'')  IS NOT NULL  drop table #inboundTimeMayores
	IF OBJECT_ID(''tempdb..#RepMKTIntervalosTemp'')  IS NOT NULL  drop table #RepMKTIntervalosTemp
	
	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL, [inb_id] [int] NOT NULL)	
	CREATE TABLE #inbound([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,nacd int,tresp int,nabnd int,
	tAbnd int,tacd int,nacw int,tacw int,maxdem int,ncalque int,tcalque int,fent int,fsal int,SalExt int,tprosalext int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
	,[dateTWait] datetime,[dateTResp] datetime,[dateTACD] datetime,[dateTTransferStart] datetime,[dateTTransferEnd] datetime,userId int, ntotal int
	)

	CREATE TABLE #inboundTimeMayores([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,nacd int,tresp int,nabnd int,
	tAbnd int,tacd int,nacw int,tacw int,maxdem int,ncalque int,tcalque int,fent int,fsal int,SalExt int,tprosalext int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
	,[dateTWait] datetime,[dateTResp] datetime,[dateTACD] datetime,[dateTTransferStart] datetime,[dateTTransferEnd] datetime,userId int, ntotal int
	)

	INSERT INTO #sessionTimeGroup
	select st.[user_id],[login],logout,timegroup,timegroup_next timeGroupNext,tlog, wg.IdCampEsp from TmpSessionTimeGroup st
		Inner Join ccriaworkgroupusers wgu ON st.User_id = wgu.User_id
		Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
	where wg.Tipo = 0
	
	insert into #inbound
	select 
		cal_Inicio as [dateStart],
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio) as [dateEnd]
		,Inbound_id as inboundId
		,case when i.statusCall_id=13 then 1 else 0 end as nacd,
		case when i.statuscall_id = 13  then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end as tresp,
		case when (i.statuscall_id <> 13) then 1 else 0 end as nabnd,
		case when (i.statuscall_id <> 13) then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end AS tAbnd
		,case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end as tacd
		,case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else 0 end as nacw
		,case when i.statusCall_id=13 then i.cal_tnotas else 0 end as tacw
		,case when i.statuscall_id = 13 then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end as maxdem
		,case when (i.statuscall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer=0)) then 1 else 0 end as ncalque
		,case when (i.statusCall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer=0)) then i.cal_tWait else 0 end as tcalque
		,CASE WHEN t.modo = 2 then 1 else 0 end as fent
		,CASE WHEN t.modo = 2 and t.tipo=1 then 1 else 0 end as fsal
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else 0 end as SalExt
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else 0 end as tprosalext
		,dbo.GetTimeGroup(dateadd(ss,cal_tDialog+cal_tWait+cal_tXfer+cal_tRing,cal_Inicio) ,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tDialog+cal_tWait+cal_tXfer+cal_tRing,cal_Inicio) ,1) as timegroup
		,dateadd(ss,i.cal_twait,cal_Inicio) as [dateTWait]
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring,cal_Inicio) as [dateTResp]
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring+i.cal_tdialog,cal_Inicio) as [dateTACD]	
		,dateadd(ss,-t.tAntesXfer - t.tDespuesXfer,fechaFin) as [dateTTransferStart]	
		,fechaFin as [dateTTransferEnd]
		,i.User_id
		,1 as ntotal
	from cccallsin i (nolock) 
	left join ccLogTransfers t (nolock) on i.cal_id=t.cal_id and t.tipo=1
	where cal_Inicio between @from and @to
	
	INSERT into #inboundTimeMayores SELECT * from #inbound where datediff(mi,timegroup,timegroup_next)>15
	delete #inbound where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #inbound
	select dateStart,dateEnd,inboundId,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacd) as nacd,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateStart,dateTResp) as tresp,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nabnd) as nabnd,		
		case when tAbnd=0 then 0 else [dbo].TimeInterval( th.[start],th.[stop] ,dateStart,dateTResp) end as tAbnd,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateTResp,[dateTACD]) as tacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacw) as nacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,[dateTACD],dateEnd) as tacw,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,maxdem) as maxdem,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,ncalque) as ncalque,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateStart,[dateTWait]) as tcalque,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,fent) as fent,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,fsal) as fsal,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,SalExt) as SalExt,
		case when [dateTTransferStart] is null then 0 else  [dbo].TimeInterval( th.[start],th.[stop] ,[dateTTransferStart],[dateTTransferEnd]) end as tprosalext,	
		 th.[start] as timegroup,th.[stop] as timegroup_next,
		[dateTWait] ,[dateTResp] ,[dateTACD] ,[dateTTransferStart] ,[dateTTransferEnd] 
		,UserId
		,dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,ntotal) as ntotal
	from #inboundTimeMayores t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	and th.Start between @from and @to		
	
	select case when c.timegroup is not null then c.timegroup else G.timegroup end  as [date]
		,isnull(c.inboundId,inb_id) as inboundId
		,isnull(c.tresp,0) as tresp,isnull(c.nacd,0) as nacd
		,isnull(c.tabnd,0) tabnd,isnull(c.nabnd,0) 	as nabnd	
		,isnull(c.tacd,0)tacd, isnull(c.tacw,0) tacw,isnull(c.nacw,0) nacw		
		,isnull(c.maxdem,0) maxdem
		,isnull(c.fent,0)  fent, isnull(c.fsal,0) fsal,isnull(c.SalExt,0)  SalExt,isnull(c.tprosalext,0)  tprosalext		
		,isnull(c.ncalque,0) ncalque,isnull(c.tcalque,0) tcalque
		,G.userId 
		,isnull(G.[tlog],0) as tlog
		,isnull(c.ntotal, 0) AS ntotal
	INTO #RepMKTIntervalosTemp 				
	 from (
		select [timegroup]
			,inboundId,userId	
			,sum(c.tresp) as tresp,sum(c.nacd) as nacd			
			,sum(c.tabnd) as tabnd
			,sum(c.nabnd) as nabnd
			,sum(c.tacd) as tacd
			,sum(c.tacw) as tacw
			,sum(c.nacw) as nacw			
			,max(c.maxdem) as maxdem			
			,sum(c.ncalque) as ncalque
			,sum(c.tcalque) as tcalque			
			,sum(fent) as fent
			,sum(fsal) as fsal
			,sum(SalExt) as SalExt
			,sum(tprosalext) as tprosalext
			,sum(ntotal) as ntotal	
		from #inbound as c 
		group by [timegroup],inboundId,userId) c		
		full join 
		(select [user_id] as userId, timegroup, inb_id,sum([tlog] ) as [tlog] from  #sessionTimeGroup group by [user_id] ,timegroup,inb_id ) G
		on G.timegroup=c.[timegroup] and c.inboundId = G.inb_id and G.userId=c.userId		
		order by date
	
	delete from [RepMKTIntervalos] 	where date >= @from AND date <= @to
		
	INSERT INTO [RepMKTIntervalos]
	select 
		[date] as [date]
		,inboundId
		,inb.descripcion as Acds
		,case when sum(nacd)>0 then sum(tresp)/isnull(nullif(sum(nacd),0), 1) else 0 end as [avrAnswer]
		,case when sum(nabnd)>0 then sum(tabnd)/sum(nabnd) else 0 end as [AvgAbandonTime]
		,sum(nacd)  [acdCalls]
		,case when sum(nacd)>0 then sum(tacd)/isnull(nullif(sum(nacd),0), 1) else 0 end as [tPromACD]
		,case when sum(nacw)>0 then sum(tacw)/isnull(nullif(sum(nacw),0), 1) else 0 end as [tPromACW]
		,sum(nabnd) as [abondeonedCalls]
		,max(maxdem) as [maxDelay]
		,sum(fent) as  [entryFlow]	
		,sum(fsal) as  [outFLow]
		,sum(SalExt) as [calloutExt]	
		,isnull(case when sum(SalExt)>0 then sum(tprosalext)/isnull(nullif(sum(SalExt),0), 1) else 0 end,0) as [TPromSalidaExt]
		,sum(ncalque) as [callDeleteQue]	
		,case when sum(ncalque)>0 then sum(tcalque)/isnull(nullif(sum(ncalque),0), 1) else 0 end as [TpromElimCola]
		,case when round(case when count(distinct userId)>0 then ((convert(float,(sum(tlog)*100))/isnull(nullif(convert(float,count(distinct userId)*1800),0), 1))*count(distinct userId))/100 else 0 end,1)>0 
		then (case when convert(decimal(15,2),((sum(nacd) * case when sum(nacd)>0 then sum(tacd)/isnull(nullif(sum(nacd),0), 1) else 0 end) / convert(float,((round(case when (count(distinct userId))>0 then ((convert(float,(sum(tlog)*100))/isnull(nullif(convert(float,count(distinct userId)*1800),0), 1))*count(distinct userId))/100 else 0 end,1))*1800)))*100)>100 then 100 
			   else convert(decimal(15,2),((sum(nacd) * case when sum(nacd)>0 then sum(tacd)/isnull(nullif(sum(nacd),0), 1) else 0 end) / convert(float,((round(case when count(distinct userId)>0 then ((convert(float,(sum(tlog)*100))/isnull(nullif(convert(float,count(distinct userId)*1800),0), 1))*count(distinct userId))/100 else 0 end,1))*1800)))*100) end)
		else 0 end [% Tiempo ACD]
		,isnull(case when (sum(nacd)+sum(nabnd))>0 then convert(decimal(15,2),(convert(float,sum(nacd))*100)/isnull(nullif((convert(float,sum(nacd))+convert(float,sum(nabnd))),0), 1)) else 0 end,0) [% Llamadas Resp]
		,round(case when count(distinct userId)>1 then ((convert(float,(sum(tlog)*100))/ isnull(nullif(convert(float,count(distinct userId)*1800),0), 1))*count(distinct userId))/100 else 0 end,1) as [Llamadas por Posic.]
		,case when sum(nacd) >0 then (case when sum(nacd)/isnull(nullif(count(distinct (case when nacd > 0 then userId end)),0), 1) >0 then convert(int, sum(nacd)/isnull(nullif(count(distinct (case when nacd > 0 then userId end)),0), 1)) else 1 end) else 0 end as [LlamadasporPosicion]
		,sum(tresp) as tresp
		,sum(tabnd) as tabnd
		,sum(tacd) as tacd
		,sum(tacw) as tacw
		,sum(nacw) as nacw		
		,sum(tcalque) as tcalque			
		,sum(tprosalext) as tprosalext
		,sum(tlog) as tlog
		,isnull(userId,0) accountUserId			
		,DATEPART(YYYY, [date]) as [year] 
		,DATEPART(mm, [date]) as [month]
		,DATEPART(dd, [date]) as [day]
		,DATEPART(hh, [date]) as [hour]
		,DATEPART(mi, [date]) as [minutes]
		from #RepMKTIntervalosTemp
		Left join ccinbound  inb ON inb.Inbound_id = inboundId
		group by[date],inboundId, userId, inb.descripcion
		having sum(nacd)>0 or sum(nabnd)>0 or sum(tlog) >0	

	IF OBJECT_ID(''tempdb..#sessionTimeGroup'')  IS NOT NULL  drop table #sessionTimeGroup	
	IF OBJECT_ID(''tempdb..#inbound'')  IS NOT NULL  drop table #inbound
	IF OBJECT_ID(''tempdb..#inboundTimeMayores'')  IS NOT NULL  drop table #inboundTimeMayores
	IF OBJECT_ID(''tempdb..#RepMKTIntervalosTemp'')  IS NOT NULL  drop table #RepMKTIntervalosTemp
end
'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva '
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepMKTIntervalosSalidas] 
@action as tinyint, @from as datetime = null, @to as datetime = null	
AS
SET NOCOUNT ON
if @from is null
	select @from = convert(datetime, convert(varchar(11), getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN
	declare
	@tresDialog AS smallint,
	@tresRing AS smallint,
	@number as int

	set @number = 0

	create table #OutboundCalls(
		dia datetime,
		rango1 varchar(5),
		Reductor numeric(18,2),
		Realizadas smallint,
		Staff smallint,
		Contactos smallint,
		Ocupado smallint,
		NoContestan smallint,
		Fax smallint,
		Buzon smallint,
		SinTono smallint,
		NoService smallint,
		Otro smallint,
		Congestion smallint,
		Cancelado smallint,
		Contestadas smallint,
		Abandonadas smallint,
		SinAgentes smallint,
		NoContestadas smallint,
		CortadasRing smallint,
		CortadasDespRing smallint,
		CortadasDlg smallint,
		TMO int,
		TiempoTotalTT int,
		TiempoTotalHold int,
		TiempoTotalACW int,
		TiempoTotalRing int,
		VelocidadResp int,
		Abandono numeric(18,2),
		OcupacionCOPC numeric(18,2),
		Cam_id int
	)

	CREATE TABLE #ccintervalos
			([Id]     [int],
			[fecha]  [datetime],
			[rango1] [varchar](5),
			[rango2] [varchar](5))

	create table #tPersonal(
			rango1 varchar(5),
			rango2 varchar(5),
			uid int,
			tlogueofra int
		)

	create table #sessionTime (
		[user_id] int,
		[tlogueo] int,
		[login] datetime,
		logout datetime,
		login2 varchar(5),
		logout2 varchar(5)
	)

	create table #loglogin(
		[user_id] int,
		tipo int,
		fecha datetime,
		cam_id int
	)

	create table #tDisp(
		fecha datetime,
		rango1 varchar(5),
		rango2 varchar(5),
		tnodispo int,
		tdispo int
	)

	while @number < (datediff(mi,@from,DATEADD(DD,1,@from))/30) 
	begin
		insert into #ccintervalos
		SELECT @number,
		@from,
		StartTime = right(''00'' + cast(datepart(hh,DATEADD(mi, @number*30, @from)) as varchar(2)),2) + '':'' + right(''00'' + cast(datepart(mi,DATEADD(mi, @number*30, @from)) as varchar(2)),2),
		EndTime = right(''00'' + cast(datepart(hh,DATEADD(mi, (@number+1)*30, @from)) as varchar(2)),2) + '':'' + right(''00'' + cast(datepart(mi,DATEADD(mi, (@number+1)*30, @from)) as varchar(2)),2)
		set @number = @number +1
	end

	insert into #loglogin
	select cc.User_id, cc.TipoMov, cc.fecha, cl.IdCampEsp
	from ccloglogin cc
	inner join ccLogAgentesDia cl on cc.User_id = cl.User_id and cc.fecha = cl.fecha
	order by cc.fecha

	EXEC @tresDialog=ccspConfigTresDialog
	EXEC @tresRing=ccspConfigTresRing
	
		insert into #sessionTime
select [user_id], DATEDIFF(ss, d.login, d.logout) as tlogueo, min(d.login) as login, max(d.logout) as logout,
case when datepart(mi,min(d.login)) < 30 then right(''00'' + cast(datepart(hh,min(d.login)) as varchar(2)),2) + '':00'' 
else right(''00'' + cast(datepart(hh,min(d.login)) as varchar(2)),2) + '':30'' end as login2,
case when datepart(mi,max(logout)) < 30 then right(''00'' + cast(datepart(hh,max(logout)) as varchar(2)),2) + '':30'' 
else right(''00'' + cast(datepart(hh,max(logout)) + 1 as varchar(2)),2) + '':00'' end as logout2
from(
select a.[user_id], a.fecha as ''login'',
(select isnull(max(Fecha),getdate()) from #loglogin b with(nolock) where b.user_id = a.user_id and b.tipo = 0 and b.fecha >= a.fecha and b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
from #loglogin with(nolock) where [user_id] = b.[user_id] and tipo = 1 and fecha > a.fecha )) as ''logout'' from #loglogin a
where a.tipo=1 and fecha >= @from and fecha <= @to
union 
select * 
from( select a.[user_id], 
	(select isnull(max(Fecha),getdate()) 
	from #loglogin b with(nolock)
	where b.[user_id] = a.[user_id] and b.tipo = 1 and b.fecha <= a.fecha and b.fecha >= (select isnull(max(fecha),b.fecha) from #loglogin with(nolock) where [user_id] = b.[user_id] and tipo = 0 and fecha < a.fecha )
	) as ''login'', a.fecha as ''logout''
from #loglogin a
where a.tipo = 0 and fecha >= @from and fecha <= @to
) as session
where datediff(day,[login],logout) >= 1
) as D
group by [user_id], d.login, d.logout
order by [user_id]

		insert into #tPersonal
		select Pg.rango1 rango1, Pg.rango2 rango2, count(distinct Pg.uid) uid, sum(Pg.tlogueofra) tlogueofra
			from(
				select Ss.rango1 rango1, Ss.rango2 rango2, Tt.user_id uid,
					sum(case when convert(varchar(5),Tt.login,108)>Ss.rango1 and convert(varchar(5),Tt.logout,108)<(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,convert(varchar(5),Tt.login,108),convert(varchar(8),Tt.logout,108))
								when convert(varchar(5),Tt.login,108)>Ss.rango1 and convert(varchar(5),Tt.logout,108)>(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,convert(varchar(5),Tt.login,108),(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end))
								when convert(varchar(5),Tt.login,108)<Ss.rango1 and convert(varchar(5),Tt.logout,108)>(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then 1800
								when convert(varchar(5),Tt.login,108)<Ss.rango1 and convert(varchar(5),Tt.logout,108)<(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,Ss.rango1,convert(varchar(5),Tt.logout,108))
					else 0 end) tlogueofra 						
				from #ccintervalos Ss
				LEFT OUTER JOIN #sessionTime Tt ON Tt.login2 <= Ss.rango1 and (Tt.logout2 >= case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end or Tt.logout2 is null)		
				group by Ss.rango1,	Ss.rango2, Tt.user_id
			) PG
		group by Pg.rango1,	Pg.rango2
	
		insert into #tDisp
		select Tm.fecha fecha, Tm.rango1 rango1, tm.rango2 rango2,
			isnull(sum(case when Tm.TipoStatusAge_id=2 then Tm.tstatusfra end),0) tnodispo,
			isnull(sum(case when Tm.TipoStatusAge_id=3 then Tm.tstatusfra end),0) tdispo
		from(
			select G.fecha fecha, G.rango1 rango1, G.rango2 rango2, G.user_id user_id,
				case when G.login >= Rg.RangoFinal then 0
						when G.tlogueofra = 1800 and Rg.tstatusfra = 1800 then 1800 
						when Rg.tstatusfra = 1800 then G.tlogueofra 
						when G.tlogueofra = 1800 then Rg.tstatusfra 
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and Rg.RangoInicial >= G.login and Rg.RangoFinal >= G.logout) then datediff(ss,Rg.RangoInicial,G.logout) 
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.login >= Rg.RangoInicial and G.logout <= Rg.RangoFinal) then datediff(ss,G.login,G.logout) 
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.login >= Rg.RangoInicial and G.logout >= Rg.RangoFinal) then datediff(ss,G.login,Rg.RangoFinal)
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.login <= Rg.RangoInicial and G.logout <= Rg.RangoFinal) then datediff(ss,Rg.RangoInicial,G.logout)
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.login <= Rg.RangoInicial and G.logout >= Rg.RangoFinal) then datediff(ss,Rg.RangoInicial,Rg.RangoFinal)
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) >= G.rango2) and (G.login >= Rg.RangoInicial) then datediff(ss,G.login,Rg.RangoFinal) 
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) >= G.rango2) and (G.login <= Rg.RangoInicial) then datediff(ss,Rg.RangoInicial,Rg.RangoFinal) 
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) <= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout <= Rg.RangoFinal) then datediff(ss,Rg.RangoInicial,G.logout) 
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) <= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout >= Rg.RangoFinal) then datediff(ss,Rg.RangoInicial,Rg.RangoFinal)
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.login >= Rg.RangoInicial) then datediff(ss,G.login,G.logout) 
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.login <= Rg.RangoInicial) then datediff(ss,Rg.RangoInicial,G.logout) 
						when (convert(varchar(5),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout <= Rg.RangoFinal) then datediff(ss,G.login,G.logout) 
						when (convert(varchar(5),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout >= Rg.RangoFinal) then datediff(ss,G.login,Rg.RangoFinal)
						when (convert(varchar(5),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) <= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout <= Rg.RangoFinal) then datediff(ss,G.Rango1,convert(varchar(5),G.logout,108)) 
						when (convert(varchar(5),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) <= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout >= Rg.RangoFinal) then datediff(ss,G.Rango1,convert(varchar(5),Rg.RangoFinal,108)) 
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) >= G.rango2) and (G.login >= Rg.RangoInicial) then datediff(ss,convert(varchar(5),G.login,108),G.Rango2) 
						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) >= G.rango2) and (G.login <= Rg.RangoInicial) then datediff(ss,convert(varchar(5),Rg.RangoInicial,108),G.Rango2)
						when (convert(varchar(5),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) >= G.rango2) and (G.login <= Rg.RangoFinal) then datediff(ss,G.login,Rg.RangoFinal) 
						when (convert(varchar(5),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(5),G.login,108) >= G.rango1 and convert(varchar(5),G.logout,108) >= G.rango2) and (G.login >= Rg.RangoFinal) then datediff(ss,Rg.RangoFinal,G.login) 
 						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(5),G.login,108) <= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout <= Rg.RangoInicial) then datediff(ss,G.logout,Rg.RangoInicial) 
 						when (convert(varchar(5),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(5),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(5),G.login,108) <= G.rango1 and convert(varchar(5),G.logout,108) <= G.rango2) and (G.logout >= Rg.RangoInicial) then datediff(ss,Rg.RangoInicial,G.logout) 
						else 0     
				end  tstatusfra,
				case when Rg.tstatusfra is not null then 1 else 0 end nstatusfra,G.tlogueofra tlogueofra,Rg.TipoStatusAge_id TipoStatusAge_id
			from(
				select distinct (S.fecha + S.rango1) fecha, S.rango1 rango1, S.rango2 rango2, T.user_id user_id, T.login login, T.logout logout,
					case when convert(varchar(5),t.login,108)>s.rango1 and convert(varchar(5),t.logout,108)<(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,convert(varchar(5),t.login,108),convert(varchar(5),t.logout,108))
				    			when convert(varchar(5),t.login,108)>s.rango1 and convert(varchar(5),t.logout,108)>(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,convert(varchar(5),t.login,108),(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end))
								when convert(varchar(5),t.login,108)<s.rango1 and convert(varchar(5),t.logout,108)>(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then 1800
								when convert(varchar(5),t.login,108)<s.rango1 and convert(varchar(5),t.logout,108)<(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,s.rango1,convert(varchar(5),t.logout,108))
					else 0 end tlogueofra 						
				from #ccintervalos S
				LEFT OUTER JOIN #sessionTime t ON t.login2 <= s.rango1 and (t.logout2 >= case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end or t.logout2 is null)
			)G
			LEFT OUTER JOIN(
				select	lg.user_id user_id, lg.rangoinicial rangoinicial, lg.rangofinal rangofinal, V.rango1 rango1, V.rango2 rango2,
					sum(case when convert(varchar(5),lg.rangoInicial,108)>V.rango1 and convert(varchar(5),lg.rangoFinal,108)<(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,convert(varchar(5),lg.rangoInicial,108),convert(varchar(5),lg.rangoFinal,108))
						when convert(varchar(5),lg.rangoInicial,108)>V.rango1 and convert(varchar(5),lg.rangoFinal,108)>(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,convert(varchar(5),lg.rangoInicial,108),(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end))
						when convert(varchar(5),lg.rangoInicial,108)<V.rango1 and convert(varchar(5),lg.rangoFinal,108)>(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then 1800
						when convert(varchar(5),lg.rangoInicial,108)<V.rango1 and convert(varchar(5),lg.rangoFinal,108)<(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,V.rango1,convert(varchar(5),lg.rangoFinal,108))
						else 0 end) tstatusfra, 
						lg.TipoStatusAge_id TipoStatusAge_id
				from(
					select user_id as user_id, dateadd(ss,-1*(t.tStatus),t.fecha) rangoInicial,t.fecha rangoFinal,							
						isnull(case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,-1*(t.tstatus),t.fecha)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''30'' end,0) rango1,
						isnull(case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(t.fecha) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(t.fecha) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) end)+'':''+''30'' end,0) rango2,														
						sum(t.tStatus) tstatus, t.TipoStatusAge_id TipoStatusAge_id
					from  cclogagentesdia t 
					where t.fecha between @from and @to
					group by user_id,dateadd(ss,-1*(t.tStatus),t.fecha),t.fecha,
						isnull(case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,-1*(t.tstatus),t.fecha)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''30'' end,0),
						isnull(case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(t.fecha) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(t.fecha) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) end)+'':''+''30'' end,0),
						t.TipoStatusAge_id
				) lg
				left outer join (SELECT rango1,rango2 from #ccintervalos) V on (V.rango1 >= lg.rango1 and case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end <= lg.rango2)
				group by lg.user_id,lg.rangoinicial,lg.rangofinal,V.rango1,V.rango2,lg.TipoStatusAge_id 
			) Rg on (Rg.user_id = G.user_id and Rg.rango1 = G.rango1 and Rg.rangoinicial < G.logout and Rg.rangofinal > G.login)
		) Tm
		group by Tm.fecha,Tm.rango1,Tm.rango2

		insert into #OutboundCalls
		select 
			convert(varchar(10),fecha,121) dia, rango1, isnull(reductor,0) Reductor, isnull(Recibidas,0) Realizadas, isnull(uid,0) Staff,
			isnull(Contactos,0) Contactos, isnull(Ocupado,0) Ocupado, isnull(NoContestan,0) NoContestan, isnull(Fax,0) [Fax/Modem],
			isnull(Buzon,0) Buzon, isnull(SinTono,0) SinTono, isnull(NoService,0) SinServicio, isnull(Otro,0) Otros, isnull(Congestion,0) Congestion,
			isnull(Cancelado,0) Canceladas,isnull(Contestadas,0) Contestadas, isnull(Abandonadas,0) Abandonadas, isnull(SinAgentes,0) SinAgentes,
			isnull(NoContestadas,0) NoContestadas, isnull(CortadasRing,0) CortadasRing, isnull(CortadasDespRing,0) CortadasDespRing , isnull(CortadasDlg,0) CortadasDlg,
			isnull(TMO,0) TMO, isnull(TiempoTotalTT,0) TiempoTotalTT, isnull(TiempoTotalHold,0) TiempoTotalHold, isnull(TiempoTotalACW,0) TiempoTotalACW,
			isnull(TiempoTotalRing,0) TiempoTotalRing, isnull(VelocidadResp,0) VelocidadResp, isnull([Abandono],0) Abandono, isnull(Ocupacion,0) Ocupacion, cam_id as cam_id
			from (
				select 	
					case when CONVERT(int, SUBSTRING(CONVERT(char(30),case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end), 16, 2)) / 30=0 
					then CONVERT(varchar(2), case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then ''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''00'' 
					else CONVERT(varchar(2),case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then ''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''30'' 
					end as rango1,
					sum(cal_tnotas) reductor,
					convert(varchar(10),fecha,121) fecha,
					COUNT(distinct co.user_id) as uid,
					COUNT(*) [Recibidas],
					lo.cam_id as cam_id, 
					COUNT(case when tipoResDial_id = 2 then 1 else null end) Ocupado,
					COUNT(case when tipoResDial_id = 3 then 1 else null end) NoContestan,
					COUNT(case when tipoResDial_id = 4 then 1 else null end) Fax,
					COUNT(case when tipoResDial_id = 11 then 1 else null end) Buzon,
					COUNT(case when tipoResDial_id = 5 then 1 else null end) SinTono,
					COUNT(case when tipoResDial_id = 10 then 1 else null end) NoService,
					COUNT(case when tipoResDial_id = 8 then 1 else null end) Otro,
					COUNT(case when tipoResDial_id = 12 then 1 else null end) Congestion,
					COUNT(case when tipoResDial_id = 13 then 1 else null end) Cancelado,
					COUNT(case when tipoResDial_id = 1 then 1 else null end) [Contactos], --contactos sistema
					COUNT(case when statuscall_id=13 and cal_tdialog > @tresDialog then 1 else null end) [Contestadas], --contactos agente
					COUNT(case when statusCall_id in (6,10,11,12,14,15,16) or (canceledNoAgents<>0 and answerbit=1) or (statuscall_id=13 and cal_tdialog <=@tresDialog) then 1 else null end) [Abandonadas],
					COUNT(case when statuscall_id = 6 then 1 else null end) SinAgentes,
					COUNT(case when statuscall_id in (15,16) then 1 else null end) NoContestadas,
					COUNT(case when statuscall_id in (11,10,12,14) and cal_tring<=@tresRing then 1 else null end) CortadasRing,
					COUNT(case when statuscall_id in (11,10,12,14) and cal_tring>@tresRing then 1 else null end) CortadasDespRing,
					COUNT(case when statuscall_id=13 and cal_tdialog <=@tresDialog then 1 else null end) CortadasDlg,
					case when COUNT(case when statuscall_id=13 then 1 else null end)=0 then 0 else SUM(cal_tDialog+cal_tNotas+cal_tRing+cal_tXfer+cal_tMoh)/COUNT(case when statuscall_id=13 then 1 else null end) end as TMO,
					case when COUNT(case when statuscall_id=13 then 1 else null end)=0 then 0 else SUM(cal_tDialog)/COUNT(case when statuscall_id=13 then 1 else null end) end as TiempoTotalTT,
					SUM(cal_tMoh) TiempoTotalHold,
					SUM(cal_tnotas) TiempoTotalACW,
					sum(cal_tring+cal_txfer) TiempoTotalRing,
					case when COUNT(case when statuscall_id=13 then 1 else null end)=0 then 0 else sum(cal_twait)/COUNT(case when statuscall_id=13 then 1 else null end) end VelocidadResp,
					cast(
						isnull(
							case when count(case when statusCall_id=13 then 1 else null end)=0 then 0 
							else count(case when statusCall_id in (6,10,11,12,14,15,16) 
								or (canceledNoAgents<>0 and answerbit=1) 
								or (statuscall_id=13 and cal_tdialog <=@tresDialog) then 1 else null end)*100.00/
								nullif(count(case when tipoResDial_id=1 then 1 else null end),0) end
								,0.00)
								 as decimal(10,2)) [Abandono],
					SUM(cal_tDialog+cal_tNotas+cal_tRing+cal_tXfer+cal_tMoh) [Ocupacion]
					from ccologdials lo (nolock) 
					left join ccoCallsOut co (nolock) on co.cal_id=lo.cal_id
					where fecha between @from and @to 
					group by 
						case when CONVERT(int, SUBSTRING(CONVERT(char(30), case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end), 16, 2)) / 30=0 
						then CONVERT(varchar(2), case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then ''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''00'' 		
						else CONVERT(varchar(2),case when ({ fn HOUR( case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then ''0''+convert(varchar(2),{ fn HOUR( case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else convert(varchar(2),{ fn HOUR( case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''30'' 
						end, convert(varchar(10),fecha,121), lo.cam_id
			)x
			order by convert(varchar(10),fecha,121)

			delete RepMKTIntervalosSalida with(rowlock) where date between @from and @to

			insert into RepMKTIntervalosSalida
			select 
				oc.dia as date,
				r.rango1,
				r.rango2,
				oc.Staff,
				oc.Realizadas,
				oc.Ocupado,
				oc.NoContestan,
				oc.Fax,
				oc.Buzon,
				oc.SinTono,
				oc.NoService as nout_service,
				oc.Otro as other,
				oc.Congestion,
				oc.Cancelado,
				oc.Contactos,
				oc.Contestadas as Answered,
				oc.Abandonadas as abandonedCalls,
				oc.SinAgentes,
				oc.NoContestadas,
				oc.CortadasRing as nabndxferout,
				oc.CortadasDespRing as nabndringout,
				oc.CortadasDlg nabnddlgout,
				oc.TMO,
				oc.TiempoTotalTT as promDialogo,
				oc.TiempoTotalHold as holdTime,
				oc.TiempoTotalACW as tnotesout,
				TiempoTotalRing as tringout,
				d.tdispo as readyTime,
				d.tnodispo as notReadyTime,
				l.tlogueofra as Personal,
				VelocidadResp as avrAnswer,
				isnull(case when L.tlogueofra=0 then 0 else (oc.Reductor+d.tnodispo)*100/L.tlogueofra end,0) as Reductor,
				oc.Abandono as AvgAbandon,
				isnull(case when L.tlogueofra=0 then 0 else oc.OcupacionCOPC*100.00/L.tlogueofra end,0) as OcupacionCOPC,
				Cam_id
			from #OutboundCalls oc
			left join #ccintervalos r on oc.rango1 = r.rango1
			left join #tPersonal L on L.rango1=r.rango1 and L.rango2=r.rango2
			left join #tDisp d on d.rango1 = r.rango1 and d.rango2 = r.rango2

	drop table #ccintervalos
	drop table #OutboundCalls
	drop table #sessionTime
	drop table #loglogin
	drop table #tPersonal
	drop table #tDisp
END

'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva ALTER SP ccspRepMKTIntervalosTiemposAcuTotales'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepMKTIntervalosTiemposAcuTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

SET NOCOUNT ON

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

declare @dateNow datetime,@maxLogout datetime

if @action = 1
begin

	IF OBJECT_ID(''tempdb..#sessionTimeGroup'')  IS NOT NULL  drop table #sessionTimeGroup;		
	IF OBJECT_ID(''tempdb..#inbound'')  IS NOT NULL  drop table #inbound
	IF OBJECT_ID(''tempdb..#inboundTimeMayores'')  IS NOT NULL  drop table #inboundTimeMayores
	IF OBJECT_ID(''tempdb..#RepMKTIntervalosTiemposAcuTotalesTemp'')  IS NOT NULL  drop table #RepMKTIntervalosTiemposAcuTotalesTemp 
	IF OBJECT_ID(''tempdb..#hold'')  IS NOT NULL  drop table #hold
	IF OBJECT_ID(''tempdb..#tempccHoldSession'')  IS NOT NULL  drop table #tempccHoldSession
	IF OBJECT_ID(''tempdb..#holdMayores2'')  IS NOT NULL  drop table #holdMayores2
	IF OBJECT_ID(''tempdb..#tiempoHold'')  IS NOT NULL  drop table #tiempoHold
	IF OBJECT_ID(''tempdb..#timeHoldInterval'')  IS NOT NULL  drop table #timeHoldInterval
	IF OBJECT_ID(''tempdb..#tempccLogAgentesDia'')  IS NOT NULL  drop table #tempccLogAgentesDia
	IF OBJECT_ID(''tempdb..#tempccLogAgentesDia2'')  IS NOT NULL  drop table #tempccLogAgentesDia2
	IF OBJECT_ID(''tempdb..#timeDetailAgent'')  IS NOT NULL  drop table #timeDetailAgent
	IF OBJECT_ID(''tempdb..#timeDetailAgent2'')  IS NOT NULL  drop table #timeDetailAgent2
	IF OBJECT_ID(''tempdb..#tempAgentLastStatus'')  IS NOT NULL  drop table #tempAgentLastStatus
	IF OBJECT_ID(''tempdb..#timeDetailAgentFinal'')  IS NOT NULL  drop table #timeDetailAgentFinal
	IF OBJECT_ID(''tempdb..#ccLogAgentesDia'')  IS NOT NULL  drop table #ccLogAgentesDia
	IF OBJECT_ID(''tempdb..#ccLogAgentesDiaMayores'')  IS NOT NULL  drop table #ccLogAgentesDiaMayores
	IF OBJECT_ID(''tempdb..#groupLog'')  IS NOT NULL  drop table #groupLog
	
	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)	
	
	CREATE TABLE #hold ([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,call_id int not null,inbound_id int not null,  marca int not null, Tipo_marca int not null,
					Tipo_llamada int not null,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL, [time_dialog] [datetime] not null,[time_notes] [datetime] not null
					,[time_hold] [datetime] not null)
	CREATE TABLE #tempccHoldSession([fila] int NOT NULL,[call_id] [int] NOT NULL,[inbound_id] [int] NOT NULL,[hold] [datetime] NOT NULL,[unhold] [datetime] NULL,[Tipo_marca] [int] not null
				,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL primary key (fila,call_id)			)
	CREATE TABLE #holdMayores2 (call_id int not null, inbound_id int not null,  hold [datetime] not null , [unhold] [datetime] not null,Tipo_marca int not null,tiempoHold int not null,
					[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)
	CREATE TABLE #inbound([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,[cal_id] [int] NOT NULL,[LlamadasRecibidas] [int] NOT NULL, nacd int,nabnd int,
				tacd int,nacw int,tacw int,[txfer] int,[SalExt] int,tprosalext int,nhold int,nserv int,nring int, tring int, thold int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
				,[dateTResp] datetime,[dateTRing] datetime,[dateTACD] datetime
				,[dateTTransferStart] datetime,[dateTTransferEnd] datetime
				,userId int, time_notes datetime, dateEndDetail datetime
				)
	CREATE TABLE #inboundTimeMayores([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,[cal_id] [int] NOT NULL,[LlamadasRecibidas] [int] NOT NULL, nacd int,
				nabnd int,tacd int,nacw int,tacw int,[txfer] int,[SalExt] int,tprosalext int,nhold int,nserv int,nring int, tring int,  thold int, [timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
				,[dateTResp] datetime,[dateTRing] datetime,[dateTACD] datetime
				,[dateTTransferStart] datetime,[dateTTransferEnd] datetime
				,userId int, time_notes datetime , dateEndDetail datetime
				)
	create table #tempccLogAgentesDia(row int not null,user_id int not null,[IdCampEsp] [int] not null,[callId] [int]not null,TipoStatusAge_id tinyint not null,tStatus int not null,dateIni datetime not null,dateEnd datetime not null,currentStatus int)
	create table #timeDetailAgent([User_id] int null,[IdCampEsp][int] not null,[callId][int] not null,dateStartDetail datetime null,dateEndDetail datetime null,timegroup datetime null,	timegroup_next datetime null,tunknown int null,tnot_av int null,tav int null,tprob int null,tother int null,nother int null,tmanualcall int null,tunknown2 decimal(10,3),tlogout int,tcliente int ,tchatting int null,[PromPosicionPersonal] [numeric](18, 1) NULL,)
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)
	create table #ccLogAgentesDia(user_id int not null,[IdCampEsp] [int] not null,TipoStatusAge_id tinyint not null,tStatus int not null, nstatusfra int not null,dateIni datetime not null,dateEnd datetime not null,
	[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)
	create table #ccLogAgentesDiaMayores(user_id int not null,[IdCampEsp] [int] not null,TipoStatusAge_id tinyint not null,tStatus int not null, nstatusfra int not null, dateIni datetime not null,dateEnd datetime not null,
	[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)

	
	INSERT INTO #sessionTimeGroup
	select st.[user_id],[login],logout,timegroup as timeGroup,timegroup_next as timeGroupNext,tlog, wg.IdCampEsp from TmpSessionTimeGroup st
		Inner Join ccriaworkgroupusers wgu ON st.User_id = wgu.User_id
		Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
	where wg.Tipo = 0 
	

-------------------HOLD PROCESS-------------------
insert into #hold
	select 
		cal_Inicio as [dateStart],
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio) as [dateEnd]
		,cal_id as cal_id,
		inbound_id as inbound_id,
		isnull(h.marca,0) as Marca,
		case when (h.tipo_marca>0) then h.tipo_marca else 0 end as Tipo_marca,
		isnull(tipo_llamada,0) as Tipo_llamada
		,dbo.GetTimeGroup(cal_Inicio,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio),1) as timegroup_next
		,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring,0),cal_inicio) as time_dialog
		,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog,0),cal_inicio) as time_notes
		,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + marca,0),cal_Inicio) as time_hold
		
	from cccallsin i (nolock) 
	left join RiaMarkHold h (nolock) on i.cal_id=h.call_id and h.tipo_llamada=1
	where cal_Inicio between @from and @to 

insert into #tempccHoldSession
select A.Fila, A.call_id
,a.inbound_id
,A.time_hold hold,
isnull(S.time_hold,a.time_notes) unhold,
a.Tipo_marca Tipo_marca
,a.timegroup timegroup
,a.timegroup_next timegroup_next
from (select ROW_NUMBER() OVER(PARTITION BY call_id ORDER BY time_hold,tipo_marca) Fila,call_id,inbound_id,marca,tipo_marca,tipo_llamada,time_hold,time_notes,timegroup,timegroup_next
from #hold a where time_hold >= @from and time_hold <= @to
)A
left join (select ROW_NUMBER() OVER(PARTITION BY call_id ORDER BY time_hold,tipo_marca) Fila,call_id,inbound_id,marca,tipo_marca,tipo_llamada,time_hold,time_notes,timegroup,timegroup_next
from #hold a where time_hold >= @from	and time_hold <= @to
) S
on A.Fila=S.Fila-1 and A.call_id=S.call_id and A.tipo_marca=1 and S.tipo_marca=0
where A.tipo_llamada=1 
order by hold


select 
	ths.call_id,
	ths.inbound_id,
	ths.hold,
	ths.unhold,
	ths.Tipo_marca,
	[dbo].TimeInterval( th.[start],th.[stop],ths.hold ,ths.unhold) as tiempohold,
	ths.timegroup,
	ths.timegroup_next
	into #tiempoHold
 from #tempccHoldSession ths
 inner join TmpTimesInterval th on (ths.timegroup > th.Start and ths.timegroup < th.stop) OR th.Start between ths.timegroup and ths.timegroup_next
 where [dbo].TimeInterval( th.[start],th.[stop],ths.hold ,ths.unhold)>0 and Tipo_marca=1
 and th.start between @from and @to

INSERT into #holdMayores2 SELECT * from #tiempoHold where datediff(mi,timegroup,timegroup_next)>15
delete #tiempoHold where  datediff(mi,timegroup,timegroup_next)>15

insert into #tiempoHold
	select DISTINCT  call_id,
		inbound_id,
		hold,
		unhold,
		Tipo_marca,
		[dbo].TimeInterval( th.[start],th.[stop],hold ,unhold) as tiempohold,
		th.[start] as timegroup,
		th.[stop] as timegroup_next
	from #holdMayores2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop ) OR th.Start between t.timegroup and t.timegroup_next
	where [dbo].TimeInterval( th.[start],th.[stop],hold ,unhold)>0 
	and th.start between @from and @to

select 
inbound_id,
sum(tiempohold) tiempohold,
timegroup,
timegroup_next
 into #timeHoldInterval from #tiempoHold where tiempoHold>0 and Tipo_marca=1
 group by inbound_id,timegroup,Tipo_marca,timegroup_next
 ---------------------FINAL HOLD PROCESS----------------------
---------------------oRows---------------------

insert into #tempccLogAgentesDia(row,[User_id],[IdCampEsp],[callId],TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus)
	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,IdCampEsp,callID,
	TipoStatusAge_id,tStatus,DATEADD(ss,-tStatus,fecha) dateIni, fecha dateEnd, isnull(currentStatus,-2)
	from ccLogAgentesDia
		WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
		delete A from(
		select case when A.tStatus>S.tStatus then S.row else A.row end row,A.user_id,a.IdCampEsp,a.callId
		from #tempccLogAgentesDia A
		left join #tempccLogAgentesDia S on A.Row=S.Row-1 and A.user_id=S.user_id
		WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id=S.TipoStatusAge_id
		and (S.dateEnd between A.dateIni and A.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
		and abs(DATEDIFF(ss,A.dateEnd,S.dateIni))>2
		)x
		inner join 	#tempccLogAgentesDia A on A.row=x.row and A.user_id=x.user_id

	
	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY dateIni) AS Row,User_id,IdCampEsp,callId,TipoStatusAge_id,tStatus,dateIni,dateEnd,currentStatus into #tempccLogAgentesDia2 from #tempccLogAgentesDia


	insert into #timeDetailAgent
	select A.user_id,A.IdCampEsp,A.callId,A.dateIni,A.dateEnd
	,dbo.GetTimeGroup(A.dateIni,0) AS timegroup
	,dbo.GetTimeGroup(A.dateEnd,1) AS timegroup_next,
	case when A.tipostatusage_id=1 then A.tStatus else 0 end tunknown,
	case when A.tipostatusage_id=2 then A.tStatus else 0 end tnot_av,
	case when A.tipostatusage_id=3 then A.tStatus else 0 end tav,
	case when A.tipostatusage_id in(11,25,26,27) then A.tStatus else 0 end tprob,--11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
	case when A.tipostatusage_id=7 then A.tStatus else 0 end tother,
	case when A.tipostatusage_id=7 then 1 else 0 end nother,
	case when A.tipostatusage_id=21 then A.tStatus else 0 end tmanualcall,
	case when abs(isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) )>A.tStatus then 0
	when A.currentStatus in(0,-1,-2) then 0 --Logout
	when S.TipoStatusAge_id=1 then 0
	else isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) end	as tunknown2
	,isnull(case when A.TipoStatusAge_id=0 then A.tStatus end,0) tlogout
	,isnull(case when A.TipoStatusAge_id=8 then A.tStatus end,0) tcliente	
	,case when A.tipostatusage_id in (23,24) then A.tStatus else 0 end  as tchatting
	,0.0 [PromPosicionPersonal]
	from #tempccLogAgentesDia2 A
	left join #tempccLogAgentesDia2 S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id<>0

	update #timeDetailAgent set tunknown2=0  where abs(tunknown2)>2.7

insert into #timeDetailAgent(User_id,IdCampEsp,callId,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tunknown,tnot_av,tav,tprob,tother,nother,tmanualcall,tunknown2,tlogout,tcliente,tchatting)
	 select
	 	User_id,
		IdCampEsp,
		callId,
	 	B.fecha as dateStartDetail,
	 	@dateNow as dateEndDetail,
		dbo.GetTimeGroup(B.fecha,0)  as timegroup,
		dbo.GetTimeGroup(dateadd(ss,tiempo,B.fecha),1)  as timegroup_next
	 	,case when currentStatus = 1 then tiempo else 0 end as tunknown,
	 	case when currentStatus = 2 then tiempo else 0 end as tnot_av,
	 	case when currentStatus = 3 then tiempo else 0 end as tav,
	 	 0,0,0,0,0 as tunknown2
		 ,0,0
		,case when currentStatus in (23,24) then tiempo else 0 end as tchatting
	 	from ccLogAgentesDia A
	 	inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id=B.id
		where A.currentStatus not in(-2,-1,0)

select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15
	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,IdCampEsp,callId,tunknown,tnot_av,tav,tprob,tother,nother,tmanualCall,tunknown2,tlogout,tcliente,tchatting)

	select
	dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id],IdCampEsp,callId
	,dbo.TimeInterval(th.Start,th.Stop,dateStartDetail,dateadd(ss,tunknown,dateStartDetail) ) as tunknown
	,dbo.TimeInterval(th.Start,th.Stop,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail) ) as tnot_av
	,dbo.TimeInterval(th.Start,th.Stop,dateStartDetail,dateadd(ss,tav,dateStartDetail) ) as tav
	,dbo.TimeInterval(th.Start,th.Stop,dateStartDetail,dateadd(ss,tprob,dateStartDetail) ) as tprob
	,dbo.TimeInterval(th.Start,th.Stop,dateStartDetail,dateadd(ss,tother,dateStartDetail) ) as tother
	
	,isnull((case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	,dbo.TimeInterval(th.Start,th.Stop,dateStartDetail,dateadd(ss,tmanualCall,dateStartDetail) ) as tmanualCall		
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tunknown2 else 0 end as tunknown2

	,dbo.TimeInterval(th.Start,th.Stop,dateStartDetail,dateadd(ss,tlogout,dateStartDetail) ) as tlogout
	,dbo.TimeInterval(th.Start,th.Stop,dateStartDetail,dateadd(ss,tcliente,dateStartDetail) ) as tcliente
	,dbo.TimeInterval(th.Start,th.Stop,dateStartDetail,dateadd(ss,tchatting,dateStartDetail) ) as tchatting
	from #timeDetailAgent2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	and th.start between @from and @to

  select distinct
		isnull(c.IdCampEsp,0) as IdCampEsp
		,c.timegroup
		,isnull(c.tunknown,0) as tunknown
		,isnull(c.tnot_av,0) as tnot_av
		,isnull(c.tav,0) as tav
		,isnull(c.tother,0) as tother
		,isnull(c.tprob,0) as tprob
		,isnull(c.tmanualCall,0) as tmanualCall
		,isnull(c.tlogout,0) as tlogout
		,isnull(c.tcliente,0) as tcliente
	INTO #timeDetailAgentFinal		
	 from (
		select IdCampEsp,
				timegroup,
				sum(tunknown) tunknown,
				sum(tnot_av) tnot_av,
				sum(tav) tav,
				sum(tother) tother,
				sum(tprob) tprob,
				sum(tmanualCall) tmanualCall,
				sum(tlogout) tlogout,
				sum(tcliente) tcliente
		from #timeDetailAgent as c 
		group by [timegroup],IdCampEsp) c
		left join #sessionTimeGroup s (nolock) on s.inb_id=c.IdCampEsp AND s.timegroup=C.timegroup

----------------------------------------------------------
	insert into #inbound
	select 
		cal_Inicio as [dateStart],
		dateadd(ss,cal_tDialog+cal_tWait+cal_tXfer+cal_tRing,cal_Inicio) as [dateEnd]
		,i.Inbound_id as inboundId
		,i.cal_id as cal_id
		,1 as [LlamadasRecibidas]
		,case when i.statusCall_id=13 then 1 else 0 end as nacd, --[LlamadasAtendidas]
		case when (i.statuscall_id <> 13) then 1 else 0 end as nabnd
		,case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end as tacd
		,case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else null end as nacw
		,case when i.statusCall_id=13 then i.cal_tnotas else 0 end as tacw
		,case when i.statusCall_id=13 then i.cal_txfer else 0 end as txfer
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else 0 end as SalExt
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else 0 end as tprosalext
		,case when i.statusCall_id=13 and i.cal_tmoh>0 then 1 else 0 end nhold
		,case when i.statusCall_id=13 and (i.cal_twait+i.cal_txfer+i.cal_tring)<40 then 1 else null end as nserv
		,case when i.statusCall_id=13 and i.cal_tring>0 then 1 else 0 end as nring
		,case when i.statusCall_id=13 then i.cal_tring else 0 end as tring
		,case when i.statuscall_id = 13 then i.cal_tmoh else 0 end as thold
		,dbo.GetTimeGroup(dateadd(ss,cal_tDialog+cal_tWait+cal_tXfer+cal_tRing,cal_Inicio) ,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tDialog+cal_tWait+cal_tXfer+cal_tRing,cal_Inicio) ,1) as timegroup_next
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring,cal_Inicio) as [dateTResp]
		,dateadd(ss,i.cal_twait + i.cal_txfer,cal_Inicio) as [dateTRing]
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring+i.cal_tdialog,cal_Inicio) as [dateTACD]	
		,dateadd(ss,-t.tAntesXfer - t.tDespuesXfer,fechaFin) as [dateTTransferStart]	
		,fechaFin as [dateTTransferEnd]
		,i.User_id
		,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) as time_notes,
		dateadd(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas ,cal_inicio) as dateEndDetail
	from cccallsin i (nolock) 
	left join ccLogTransfers t (nolock) on i.cal_id=t.cal_id and t.tipo=1
	 where cal_Inicio between @from and @to

				
	INSERT into #inboundTimeMayores SELECT * from #inbound where datediff(mi,timegroup,timegroup_next)>15
	delete #inbound where  datediff(mi,timegroup,timegroup_next)>15
	
	
	insert into #inbound
	select dateStart,dateEnd,
		inboundId
		,cal_id,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,[LlamadasRecibidas]) as[LlamadasRecibidas],
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacd) as nacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nabnd) as nabnd,		
		[dbo].TimeInterval( th.[start],th.[stop] ,dateTResp,[dateTACD]) as tacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacw) as nacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,time_notes,dateEndDetail) as tacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,dateStart,dateTResp) as txfer,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,SalExt) as SalExt,
		case when [dateTTransferStart] is null then 0 else  [dbo].TimeInterval( th.[start],th.[stop] ,[dateTTransferStart],[dateTTransferEnd]) end as tprosalext,	
		 dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nhold) as nhold,
		 dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nserv) as nserv,
		 dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nring) as nring,
		 [dbo].TimeInterval( th.[start],th.[stop] ,dateTRing,dateTResp) as tring,
		 thold,
		 th.[start] as timegroup,
		 th.[stop] as timegroup_next
		,[dateTResp],[dateTRing] ,[dateTACD] 
		,[dateTTransferStart] ,[dateTTransferEnd] 
		,UserId
		,time_notes
		, dateEndDetail
	from #inboundTimeMayores t 
	inner join TmpTimesInterval th on (t.timegroup> th.Start and t.timegroup < th.stop) OR th.Stop between t.timegroup and t.timegroup_next
	and th.start between @from and @to

-----------------------------------------------------------------------------------
insert into #ccLogAgentesDia
	select [User_id]
	,IdCampEsp
	,TipoStatusAge_id
	,tStatus
	,case when tStatus is not null then 1 else 0 end nstatusfra
	,DATEADD(ss,-tStatus,fecha) dateIni
	,fecha dateEnd
	,dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0) as timegroup
	,dbo.GetTimeGroup(fecha,1) as timegroup_next
	from ccLogAgentesDia A
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
	and TipoStatusAge_id = 3

	INSERT into #ccLogAgentesDiaMayores 
	SELECT * from #ccLogAgentesDia where datediff(mi,dateIni,dateEnd)>15
	delete #ccLogAgentesDia where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #ccLogAgentesDia
	select User_id,IdCampEsp
	,TipoStatusAge_id
	,[dbo].TimeInterval( th.[start],th.[stop], dateIni, dateEnd) as tstatus
	,nstatusfra
	,DATEADD(ss,-tStatus,dateEnd) dateIni
	,dateEnd dateEnd
	,th.[start] as timegroup
	,th.[stop] as timegroup_next
	from #ccLogAgentesDiaMayores A 
	inner join TmpTimesInterval th on (A.timegroup > th.Start and A.timegroup < th.stop) OR th.Start between A.timegroup and A.timegroup_next
	WHERE dateIni>=@from AND dateIni<@to
	and TipoStatusAge_id = 3
	and th.start between @from and @to

	select User_id,IdCampEsp
		,TipoStatusAge_id
		,sum(tstatus) as tstatus
		,sum(nstatusfra) as nstatusfra
		,timegroup
	INTO #groupLog
	from #ccLogAgentesDia
	GROUP BY User_id,IdCampEsp,TipoStatusAge_id,timegroup
	
	 select distinct case when c.timegroup is not null then c.timegroup else G.timegroup end  as [date]
		,isnull(c.inboundId,inb_id) as inboundId
		,isnull(ci.descripcion,'''') as [descripcion]
		,isnull(c.ncalls,0) as ncalls--LlamadasRecibidas
		,isnull(c.nacd,0) as nacd	--atendidas
		,isnull(c.nabnd,0) as nabnd	--abandonadas
		,isnull(c.tacd,0) as tacd --TiempoACD
		,isnull(c.tacw,0) as tacw --TiempoACW
		,isnull(d.tlogout,0) as tlogout --TiempoLogout
		,isnull(c.nacw,0) as nacw --nACW
		,isnull(d.tunknown,0) as tunknown --TiempoDescon
		,isnull(d.tnot_av,0) as tnot_av --TiempoNoDispo
		,isnull(c.txfer,0) as txfer --TiempoXfer
		,isnull(d.tother,0) as tother --TiempoOtra
		,isnull(d.tcliente,0) as tcliente --TiempoCliente
		,isnull(d.tprob,0) as tprob --TiempoProblema
		,isnull(d.tmanualCall,0) as tmanualCall --TiempoManual
		,G.userId 
		,isnull(G.[tlog seg],0) as tlog
		,isnull(hi.tiempohold,0) as tiempoHold
		,isnull(c.SalExt,0) as SalExt
		,isnull(c.tprosalext,0)  tprosalext	
		,isnull(c.nhold,0) nhold
		,isnull(thold,0) thold
		,isnull(c.nserv,0) nserv
		,isnull(c.nring,0) nring
		,isnull(c.tring,0) tring
		
	INTO #RepMKTIntervalosTiemposAcuTotalesTemp				
	 from (
		select 
			timegroup
			,inboundId,userId
			,sum(nacd) as nacd			
			,sum(nabnd) as nabnd
			,sum(tacd) as tacd
			,sum(tacw) as tacw
			,sum(nacw) as nacw
			,sum(LlamadasRecibidas) as ncalls
			,sum(txfer) as txfer
			,sum(SalExt) as SalExt
			,sum(tprosalext) as tprosalext
			,sum(nhold) as nhold
			,count(nserv) as nserv
			,sum(tring) as tring
			,sum(nring) as nring
			,sum(thold) as thold
		from #inbound as c 
		group by [timegroup],inboundId,userId) c
		full join 
		(select [user_id] as userId, timegroup, inb_id,sum([tlog seg] ) as [tlog seg] from  #sessionTimeGroup group by [user_id] ,timegroup,inb_id ) G
		on G.timegroup=c.[timegroup] and c.inboundId = G.inb_id and G.userId=c.userId
		LEFT JOIN #timeHoldInterval hi ON hi.inbound_id=C.inboundId AND hi.timegroup=C.timegroup
		left join ccinbound ci (nolock) on ci.Inbound_id=c.inboundId	
		left join #timeDetailAgentFinal d (nolock) on d.IdCampEsp=ci.Inbound_id AND d.timegroup=C.timegroup
		left JOIN #groupLog lo on c.timegroup = lo.timegroup and c.inboundId = lo.IdCampEsp and c.userId = lo.user_id
	
	delete from [RepMKTIntervalosTiemposAcuTotales]	where date >= @from AND date <= @to 	
	
insert INTO [RepMKTIntervalosTiemposAcuTotales]	
	select 
		[date] as [date]
		,inboundId
		,inb.descripcion as descripcion
	    ,round(case when count(distinct userId)>1 then ((convert(float,(sum([tlog])*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1) as [PromPosicionPersonal]
		,sum(ncalls) LlamadasRecibidas
		,sum(nacd)  LlamadasAtendidas
		,sum(nabnd)  LlamadasAban
		,sum(tacd) as TiempoACD --tACD
		,sum(tacw) as TiempoACW --tACW
		,sum(c.tlogout) as TiempoLogout --tLogout
		,sum(c.tunknown) as TiempoDescon --tDescon
		,sum(distinct c.tnot_av) as TiempoNoDispo --tnotav
		,sum(distinct d.tav) as TiempoDispo
		,sum(txfer) as TiempoXfer  --txfer
		,sum(c.tother) as TiempoOtra --tother
		,sum(c.tcliente) as TiempoCliente --tCliente
		,sum(tring) as TiempoRing --tring
		,sum(c.tprob) as TiempoProblema --tprob
		,sum(c.tmanualCall) as TiempoManual --tManual
		,sum(tiempoHold) as TiempoReten --[timeretention]
		,sum(SalExt) as LlamadasSalidaExt
		,case when sum(SalExt)>0 then sum(tprosalext) else 0 end as [TiempoSalidaExt]
		,case when sum(ncalls)>0 then (sum(nserv) * 100) / sum(ncalls) else 0 end [PorcNiveldeServicio4080]
		,((case when sum(nacd)>0 then sum(tacd)/sum(nacd) else 0 end)+(case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end)+(case when sum(nring)>0 then sum(tring)/sum(nring) else 0 end)+(case when sum(nhold)>0 then sum(thold)/sum(nhold) else 0 end)) [AHT]
		,sum(nhold) as LlamadasRetenidas
		,sum(nring) as LlamadasenRing
		,DATEPART(YYYY, [date]) as [year] 
		,DATEPART(mm, [date]) as [month]
		,DATEPART(dd, [date]) as [day]
		,DATEPART(hh, [date]) as [hour]
		,DATEPART(mi, [date]) as [minutes]
		,sum(nserv) as nserv
		,sum(nacw) as nacw
		from #RepMKTIntervalosTiemposAcuTotalesTemp c
		Left join ccinbound  inb ON inb.Inbound_id = inboundId 
		left join #timeDetailAgentFinal d (nolock) on d.IdCampEsp=c.inboundId AND d.timegroup=c.date
		group by[date],inboundId,  inb.descripcion
		having sum(nacd)>0 or sum(nabnd)>0 or sum(tlog) >0

	IF OBJECT_ID(''tempdb..#sessionTimeGroup'')  IS NOT NULL  drop table #sessionTimeGroup;		
	IF OBJECT_ID(''tempdb..#inbound'')  IS NOT NULL  drop table #inbound
	IF OBJECT_ID(''tempdb..#inboundTimeMayores'')  IS NOT NULL  drop table #inboundTimeMayores
	IF OBJECT_ID(''tempdb..#RepMKTIntervalosTiemposAcuTotalesTemp'')  IS NOT NULL  drop table #RepMKTIntervalosTiemposAcuTotalesTemp 
	IF OBJECT_ID(''tempdb..#hold'')  IS NOT NULL  drop table #hold
	IF OBJECT_ID(''tempdb..#tempccHoldSession'')  IS NOT NULL  drop table #tempccHoldSession
	IF OBJECT_ID(''tempdb..#holdMayores2'')  IS NOT NULL  drop table #holdMayores2
	IF OBJECT_ID(''tempdb..#tiempoHold'')  IS NOT NULL  drop table #tiempoHold
	IF OBJECT_ID(''tempdb..#timeHoldInterval'')  IS NOT NULL  drop table #timeHoldInterval
	IF OBJECT_ID(''tempdb..#tempccLogAgentesDia'')  IS NOT NULL  drop table #tempccLogAgentesDia
	IF OBJECT_ID(''tempdb..#tempccLogAgentesDia2'')  IS NOT NULL  drop table #tempccLogAgentesDia2
	IF OBJECT_ID(''tempdb..#timeDetailAgent'')  IS NOT NULL  drop table #timeDetailAgent
	IF OBJECT_ID(''tempdb..#timeDetailAgent2'')  IS NOT NULL  drop table #timeDetailAgent2
	IF OBJECT_ID(''tempdb..#tempAgentLastStatus'')  IS NOT NULL  drop table #tempAgentLastStatus
	IF OBJECT_ID(''tempdb..#timeDetailAgentFinal'')  IS NOT NULL  drop table #timeDetailAgentFinal
	IF OBJECT_ID(''tempdb..#ccLogAgentesDia'')  IS NOT NULL  drop table #ccLogAgentesDia
	IF OBJECT_ID(''tempdb..#ccLogAgentesDiaMayores'')  IS NOT NULL  drop table #ccLogAgentesDiaMayores
	IF OBJECT_ID(''tempdb..#groupLog'')  IS NOT NULL  drop table #groupLog
 end
 '
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva ALTER SP ccspRepMKTTiemposTotales'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepMKTTiemposTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

	IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup;			
	IF OBJECT_ID(''tempdb..#inbound'') IS NOT NULL drop table #inbound
	IF OBJECT_ID(''tempdb..#inboundTimeMayores'') IS NOT NULL drop table #inboundTimeMayores
	IF OBJECT_ID(''tempdb..#holdTime'') IS NOT NULL drop table #holdTime
	IF OBJECT_ID(''tempdb..#hold'') IS NOT NULL DROP TABLE #hold
	IF OBJECT_ID(''tempdb..#tempccHoldSession'') IS NOT NULL DROP TABLE #tempccHoldSession
	IF OBJECT_ID(''tempdb..#tiempoHold'') IS NOT NULL DROP TABLE #tiempoHold
	IF OBJECT_ID(''tempdb..#holdMayores2'') IS NOT NULL DROP TABLE #holdMayores2
	IF OBJECT_ID(''tempdb..#timeHoldInterval'') IS NOT NULL DROP TABLE #timeHoldInterval
	IF OBJECT_ID(''tempdb..#IntervalosInbound'') IS NOT NULL DROP TABLE #IntervalosInbound
	IF OBJECT_ID(''tempdb..#ccLogAgentesDia'') IS NOT NULL DROP TABLE #ccLogAgentesDia
	IF OBJECT_ID(''tempdb..#ccLogAgentesDiaMayores'') IS NOT NULL DROP TABLE #ccLogAgentesDiaMayores
	IF OBJECT_ID(''tempdb..#HoldDisp'') IS NOT NULL drop table #HoldDisp
	IF OBJECT_ID(''tempdb..#groupLog'') IS NOT NULL drop table #groupLog	

	CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
	
	--CREATE TABLE #sessionTimeMayores([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
	CREATE TABLE #inbound([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,ncalls int,nacd int,tresp int,nabnd int,
	nacw int,nring int,tacd int,tacw int,tring int,SalExt int,tprosalext int,nhold int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
	,[dateTResp] datetime,[dateTACD] datetime,[dateTTransferStart] datetime,[dateTTransferEnd] datetime,userId int,ntotal int)
	CREATE TABLE #inboundTimeMayores([dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,[inboundId] [int] NOT NULL,ncalls int,nacd int,tresp int,nabnd int,
	nacw int,nring int,tacd int,tacw int,tring int,SalExt int,tprosalext int,nhold int,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL
	,[dateTResp] datetime,[dateTACD] datetime,[dateTTransferStart] datetime,[dateTTransferEnd] datetime,userId int,ntotal int)
	CREATE TABLE #holdTime([userId] int not null,inbound_id int not null,tiempohold int not null,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)
	
	create table #ccLogAgentesDia(user_id int not null,[IdCampEsp] [int] not null,TipoStatusAge_id tinyint not null,tStatus int not null, nstatusfra int not null,dateIni datetime not null,dateEnd datetime not null,
	[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)
	create table #ccLogAgentesDiaMayores(user_id int not null,[IdCampEsp] [int] not null,TipoStatusAge_id tinyint not null,tStatus int not null, nstatusfra int not null, dateIni datetime not null,dateEnd datetime not null,
	[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)
	
	INSERT INTO #sessionTimeGroup
	select st.[user_id],[login],logout,timegroup as timeGroup,timegroup_next as timeGroupNext,tlog as tlog, wg.IdCampEsp 
	from TmpSessionTimeGroup st
		Inner Join ccriaworkgroupusers wgu ON st.User_id = wgu.User_id
		Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
	where wg.Tipo = 0 			
	
	insert into #inbound
	select 
		cal_Inicio as [dateStart],
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio) as [dateEnd]
		,Inbound_id as inboundId
		,1 as ncalls
		,case when i.statusCall_id=13 then 1 else 0 end as nacd
		,case when i.statuscall_id = 13  then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end as tresp
		,case when (i.statuscall_id <> 13) then 1 else 0 end as nabnd
		,case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else 0 end as nacw
		,case when i.statusCall_id=13 and i.cal_tring>0 then 1 else null end nring
		,case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end as tacd	
		,case when i.statusCall_id=13 then i.cal_tnotas else 0 end as tacw
		,case when i.statusCall_id=13 then i.cal_tring else null end tring
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else 0 end as SalExt
		,CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else 0 end as tprosalext	
		,case when i.statusCall_id=13 and i.cal_tmoh>0 then 1 else 0 end nhold
		,dbo.GetTimeGroup(cal_Inicio,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio),1) as timegroup
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring,cal_Inicio) as [dateTResp]
		,dateadd(ss,i.cal_twait + i.cal_txfer + i.cal_tring+i.cal_tdialog,cal_Inicio) as [dateTACD]	
		,dateadd(ss,-t.tAntesXfer - t.tDespuesXfer,fechaFin) as [dateTTransferStart]	
		,fechaFin as [dateTTransferEnd]
		,i.User_id
		,1 as ntotal
	from cccallsin i (nolock) 
	left join ccLogTransfers t (nolock) on i.cal_id=t.cal_id and t.tipo=1
	where cal_Inicio between @from and @to
	
	INSERT into #inboundTimeMayores 
	SELECT * from #inbound where datediff(mi,timegroup,timegroup_next)>15
	delete #inbound where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #inbound
	select dateStart,dateEnd,inboundId,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,ncalls) as ncalls,	
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacd) as nacd,	
		[dbo].TimeInterval( th.[start],th.[stop] ,dateStart,dateTResp) as tresp,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nabnd) as nabnd,		
		[dbo].TimeInterval( th.[start],th.[stop] ,dateTResp,[dateTACD]) as tacd,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nacw) as nacw,
		[dbo].TimeInterval( th.[start],th.[stop] ,[dateTACD],dateEnd) as tacw,
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nring) as nring
		,[dbo].TimeInterval( th.[start],th.[stop] ,[dateTACD],tring) as tring
		,dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,SalExt) as SalExt,
		case when [dateTTransferStart] is null then 0 else  [dbo].TimeInterval( th.[start],th.[stop] ,[dateTTransferStart],[dateTTransferEnd]) end as tprosalext,	
		dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,nhold) as nhold,
		th.[start] as timegroup,th.[stop] as timegroup_next
		,[dateTResp] ,[dateTACD] ,[dateTTransferStart] ,[dateTTransferEnd] 
		,UserId
		,dbo.AccountInterval(th.[start],th.[stop],dateStart,dateEnd,ntotal) as ntotal
	from #inboundTimeMayores t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next	
	and th.Start between @from and @to

	insert into #ccLogAgentesDia
	select [User_id]
	,IdCampEsp
	,TipoStatusAge_id
	,tStatus
	,case when tStatus is not null then 1 else 0 end nstatusfra
	,DATEADD(ss,-tStatus,fecha) dateIni
	,fecha dateEnd
	,dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0) as timegroup
	,dbo.GetTimeGroup(fecha,1) as timegroup_next
	from ccLogAgentesDia A
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
	and TipoStatusAge_id = 3

	INSERT into #ccLogAgentesDiaMayores 
	SELECT * from #ccLogAgentesDia where datediff(mi,dateIni,dateEnd)>15
	delete #ccLogAgentesDia where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #ccLogAgentesDia
	select User_id,IdCampEsp
	,TipoStatusAge_id
	,[dbo].TimeInterval( th.[start],th.[stop], dateIni, dateEnd) as tstatus
	,nstatusfra
	,DATEADD(ss,-tStatus,dateEnd) dateIni
	,dateEnd dateEnd
	,th.[start] as timegroup
	,th.[stop] as timegroup_next
	from #ccLogAgentesDiaMayores A 
	inner join TmpTimesInterval th on (A.timegroup > th.Start and A.timegroup < th.stop) OR th.Start between A.timegroup and A.timegroup_next
	WHERE dateIni>=@from AND dateIni<@to
	and TipoStatusAge_id = 3
	and th.Start between @from and @to

	select User_id,IdCampEsp
		,TipoStatusAge_id
		,sum(tstatus) as tstatus
		,sum(nstatusfra) as nstatusfra
		,timegroup
	INTO #groupLog
	from #ccLogAgentesDia
	GROUP BY User_id,IdCampEsp,TipoStatusAge_id,timegroup

	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------HOLD TIME--------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	CREATE TABLE #hold ([userId] int not null,[dateStart] [datetime] NOT NULL,[dateEnd] [datetime] NOT NULL,call_id int not null,inbound_id int not null,  marca int not null, Tipo_marca int not null,
					Tipo_llamada int not null,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL, [time_dialog] [datetime] not null,[time_notes] [datetime] not null
					,[time_hold] [datetime] not null)

	CREATE TABLE #tempccHoldSession([fila] int NOT NULL,[call_id] [int] NOT NULL,[userId] int not null,[inbound_id] [int] NOT NULL,[hold] [datetime] NOT NULL,[unhold] [datetime] NULL,[Tipo_marca] [int] not null
				,[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL primary key (fila,call_id))	

	CREATE TABLE #holdMayores2 (call_id int not null,[userId] int not null,inbound_id int not null,  hold [datetime] not null , [unhold] [datetime] not null,Tipo_marca int not null,tiempoHold int not null,
					[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL)

	insert into #hold
	select 
		User_id as userId
		,cal_Inicio as [dateStart],
		dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio) as [dateEnd]
		,cal_id as cal_id		
		,inbound_id as inbound_id
		,isnull(h.marca,0) as Marca,
		case when (h.tipo_marca>0) then h.tipo_marca else 0 end as Tipo_marca,
		isnull(tipo_llamada,0) as Tipo_llamada
		,dbo.GetTimeGroup(cal_Inicio,0) as timegroup
		,dbo.GetTimeGroup(dateadd(ss,cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,cal_Inicio),1) as timegroup_next
		,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring,0),cal_inicio) as time_dialog
		,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + cal_tdialog,0),cal_inicio) as time_notes
		,DATEADD(ss,isnull(cal_twait + cal_txfer + cal_tring + marca,0),cal_Inicio) as time_hold		
	from cccallsin i (nolock) 
	left join RiaMarkHold h (nolock) on i.cal_id=h.call_id and h.tipo_llamada=1
	where cal_Inicio between @from and @to
	

	insert into #tempccHoldSession
	select A.Fila 
		,A.call_id
		,a.userId
		,a.inbound_id
		,A.time_hold hold,
		--S.fecha holdout
		isnull(S.time_hold,a.time_notes) unhold,
		a.Tipo_marca Tipo_marca
		,a.timegroup timegroup
		,a.timegroup_next timegroup_next
	from (
		select ROW_NUMBER() OVER(PARTITION BY call_id ORDER BY time_hold,tipo_marca) Fila,call_id,userId,inbound_id,marca,tipo_marca,tipo_llamada,time_hold,time_notes,timegroup,timegroup_next
		from #hold a where time_hold >= @from and time_hold <= @to
	)A
	left join (
		select ROW_NUMBER() OVER(PARTITION BY call_id ORDER BY time_hold,tipo_marca) Fila,call_id,userId,inbound_id,marca,tipo_marca,tipo_llamada,time_hold,time_notes,timegroup,timegroup_next
		from #hold a where time_hold >= @from	and time_hold <= @to
	) S
	on A.Fila=S.Fila-1 and A.call_id=S.call_id and A.tipo_marca=1 and S.tipo_marca=0
	where A.tipo_llamada=1 --and a.Tipo_marca=1 
	order by hold

	select 
		ths.call_id,
		ths.userId,
		ths.inbound_id,
		ths.hold,
		ths.unhold,
		ths.Tipo_marca,
		[dbo].TimeInterval( th.[start],th.[stop],ths.hold ,ths.unhold) as tiempohold,
		ths.timegroup,
		ths.timegroup_next
		into #tiempoHold
	 from #tempccHoldSession ths
	 inner join TmpTimesInterval th on (ths.timegroup > th.Start and ths.timegroup < th.stop) OR th.Start between ths.timegroup and ths.timegroup_next
	 where [dbo].TimeInterval( th.[start],th.[stop],ths.hold ,ths.unhold)>0 and Tipo_marca=1	
	 and th.Start between @from and @to
	
	INSERT into #holdMayores2 
	SELECT * from #tiempoHold where datediff(mi,timegroup,timegroup_next)>15 
	delete #tiempoHold where  datediff(mi,timegroup,timegroup_next)>15	

	insert into #tiempoHold
	select DISTINCT  call_id,
		userId as userId,
		inbound_id as inbound_id,
		hold,
		unhold,
		Tipo_marca,
		[dbo].TimeInterval( th.[start],th.[stop],hold ,unhold) as tiempohold, 
		th.[start] as timegroup,
		th.[stop] as timegroup_next
	from #holdMayores2 t
	inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop ) OR th.Start between t.timegroup and t.timegroup_next
	where [dbo].TimeInterval( th.[start],th.[stop],hold ,unhold)>0 
	and th.Start between @from and @to

	select 
	inbound_id,
	userId,
	sum(tiempohold) as tiempohold,
	--sum(Tipo_marca) as Tipo_marca,
	timegroup,
	timegroup_next
	into #timeHoldInterval 
	from #tiempoHold 
	where tiempoHold>0 and Tipo_marca=1
	group by userId,inbound_id,timegroup,timegroup_next

	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	select case when c.timegroup is not null then c.timegroup else G.timegroup end  as [date]
		,isnull(c.inboundId,inb_id) as inboundId
		,isnull(c.nacd,0) as nacd
		,isnull(c.nabnd,0) 	as nabnd	
		,isnull(c.tacd,0)tacd, isnull(c.tacw,0) tacw,isnull(c.nacw,0) nacw		
		,isnull(c.SalExt,0)  SalExt,isnull(c.tprosalext,0)  tprosalext
		,G.userId 
		,isnull(G.[tlog seg],0) as tlog
		,isnull(c.ncalls, 0) AS ncalls		
		,isnull(c.tring, 0) AS tring
		,isnull(c.nring, 0) AS nring
		,isnull(c.nhold, 0) AS nhold
	 INTO #IntervalosInbound
	 from (
			select timegroup,inboundId,userId 
				,sum(c.nacd) as nacd			
				,sum(c.nabnd) as nabnd
				,sum(c.tacd) as tacd
				,sum(c.tacw) as tacw
				,sum(c.nacw) as nacw			
				,sum(SalExt) as SalExt
				,sum(tprosalext) as tprosalext
				,sum(c.ncalls) as ncalls	
				,SUM(c.tring) as tring
				,SUM(c.nring) as nring
				,SUM(c.nhold) as nhold
			from #inbound as c
			where inboundId > 0
			group by timegroup,inboundId,userId 
		) c		
	full join 
	(select [user_id] as userId, timegroup, inb_id,sum([tlog seg] ) as [tlog seg] from  #sessionTimeGroup group by [user_id] ,timegroup,inb_id ) G
	on G.timegroup=c.[timegroup] and c.inboundId = G.inb_id and G.userId=c.userId
	 
	select i.*
	,isnull(case when lo.TipoStatusAge_id=3 then isnull(lo.tStatus,0) end,0) tdispo
	,isnull(case when lo.TipoStatusAge_id=3 then lo.nstatusfra end,0) ndispo
	,isnull(h.tiempohold, 0) AS thold
	--,isnull(h.Tipo_marca, 0) AS nhold	
	INTO #HoldDisp
	from #IntervalosInbound i
	left JOIN #groupLog lo on i.date = lo.timegroup and i.inboundId = lo.IdCampEsp and i.userId = lo.user_id
	left JOIN #timeHoldInterval h on h.inbound_id = i.inboundId and i.date = h.timegroup and i.userId = h.userId

	delete from [RepMKTTiemposTotales]	where date >= @from AND date <= @to

	INSERT INTO [RepMKTTiemposTotales]
	select 
		[date] as [date]
		,inboundId
		,inb.descripcion as Acds
		,round(case when count(distinct userId)>1 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1) as [Llamadas por Posic.]
		,sum(ncalls) [Recibidas]
		,sum(nacd) [Atendidas]
		,sum(nabnd) [Abandonadas]
		,case when sum(nacd)>0 then sum(tacd)/sum(nacd) else 0 end as [tPromACD]
		,case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end as [tPromACW]
		,case when sum(nhold)>0 then sum(thold)/sum(nhold) else 0 end as [tPromRetention]
		,sum(SalExt) as [callsOutExt]	
		,isnull(case when sum(SalExt)>0 then sum(tprosalext)/sum(SalExt) else 0 end,0) as [TPromSalidaExt]
		,case when sum(ndispo)>0 then sum(tdispo)/sum(ndispo) else 0 end as [TPromDispon]
		,case when sum(nring)>0 then sum(tring)/sum(nring) else 0 end [TPromRing]
		,sum(((case when nacd>0 then tacd/nacd else 0 end)+(case when nacw>0 then tacw/nacw else 0 end)+(case when nring>0 then tring/nring else 0 end)+(case when nhold>0 then thold/nhold else 0 end))) [AHT1]
		,sum(tacd) as tacd
		,sum(tacw) as tacw
		,sum(nacw) as nacw				
		,sum(tprosalext) as tprosalext
		,sum(tlog) as tlog
		,sum(nhold) as nhold
		,sum(thold) as thold
		,sum(tdispo) as tdispo
		,sum(ndispo) as ndispo
		,sum(tring) as tring
		,sum(nring) as nring
		,userId as accountUserId			
		,DATEPART(YYYY, [date]) as [year] 
		,DATEPART(mm, [date]) as [month]
		,DATEPART(dd, [date]) as [day]
		,DATEPART(hh, [date]) as [hour]
		,DATEPART(mi, [date]) as [minutes]
		from #HoldDisp
		Left join ccinbound  inb ON inb.Inbound_id = inboundId
		group by[date],inboundId, userId, inb.descripcion
		order by date		

	IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup;			
	IF OBJECT_ID(''tempdb..#inbound'') IS NOT NULL drop table #inbound
	IF OBJECT_ID(''tempdb..#inboundTimeMayores'') IS NOT NULL drop table #inboundTimeMayores
	IF OBJECT_ID(''tempdb..#holdTime'') IS NOT NULL drop table #holdTime
	IF OBJECT_ID(''tempdb..#hold'') IS NOT NULL DROP TABLE #hold
	IF OBJECT_ID(''tempdb..#tempccHoldSession'') IS NOT NULL DROP TABLE #tempccHoldSession
	IF OBJECT_ID(''tempdb..#tiempoHold'') IS NOT NULL DROP TABLE #tiempoHold
	IF OBJECT_ID(''tempdb..#holdMayores2'') IS NOT NULL DROP TABLE #holdMayores2
	IF OBJECT_ID(''tempdb..#timeHoldInterval'') IS NOT NULL DROP TABLE #timeHoldInterval
	IF OBJECT_ID(''tempdb..#IntervalosInbound'') IS NOT NULL DROP TABLE #IntervalosInbound
	IF OBJECT_ID(''tempdb..#ccLogAgentesDia'') IS NOT NULL DROP TABLE #ccLogAgentesDia
	IF OBJECT_ID(''tempdb..#ccLogAgentesDiaMayores'') IS NOT NULL DROP TABLE #ccLogAgentesDiaMayores
	IF OBJECT_ID(''tempdb..#HoldDisp'') IS NOT NULL drop table #HoldDisp
	IF OBJECT_ID(''tempdb..#groupLog'') IS NOT NULL drop table #groupLog	

END
	'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva ALTER SP ccspRepOutAnswAndXferCalls'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = NULL

AS

SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = CONVERT(DATETIME,CONVERT(VARCHAR(11),GETDATE()))
IF @to IS NULL
	SELECT @to = GETDATE()

DECLARE @IVA INT
DECLARE @country AS TINYINT
SELECT @IVA = CONVERT(INT,ISNULL(valor,0)) FROM ccsettings WHERE setting_id = 25
SELECT @country = CONVERT(TINYINT,ISNULL(valor,1)) FROM ccsettings WHERE setting_id = 104

IF @country IS NULL SET @country = 1

IF @action = 1
BEGIN
--Borrar lo que esta para no repetir
DELETE FROM RepOutAnswAndXferCalls WHERE DATE >= @from AND DATE < @TO
INSERT INTO RepOutAnswAndXferCalls

SELECT COALESCE([Call].cal_inicio,ccld.fecha) AS [date],
	ISNULL(ccld.cal_id,0) AS [callid],
	ISNULL(ccld.cam_id,0) AS [campaignId],
	ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
	ISNULL([Call].user_id,0) AS [userId],
	ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') AS [Agent],
	dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg) AS [dialog],
	ccld.telefono AS [telephone],
	ISNULL(Call.cal_manual,0) AS [dialId],
	ISNULL((SELECT [description] FROM dialType 
				WHERE dialId = Call.cal_manual),''systemTranslated_Auto'') AS [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
	CASE 
		WHEN provedor_id IS NOT NULL THEN dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),COALESCE(Call.provedor_id,ccld.proBIDs),
			CASE 
				WHEN (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 
					THEN COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) 
				ELSE 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) 
			END,@country)
ELSE  CONVERT(DECIMAL(10,2),(CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) / 60) * ccost.additional_min)))
	END AS [ncost],
	@IVA AS iva,
	CASE
		WHEN provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType),COALESCE(Call.provedor_id,ccld.proBIDs),
			dbo.tDialog(Call.totalCall_Time, ccld.tdialing, cal_tMsg)
			,@country),0.00) * (1 + (@IVA / 100.00)))
		ELSE  CONVERT(DECIMAL(10,2),((CCost.cost_per_min + ((COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) / 60) * ccost.additional_min)) * (1 + (@IVA / 100.00))))
	END	AS total,
	COALESCE(ccld.Puerto, Call.cal_puerto, 0) as [trunk],
	case when dbo.TelAni(ccld.Telefono, camps.id_anilist) <> '''' then dbo.TelAni(ccld.Telefono, camps.id_anilist) else camps.ani end [ANI],
	COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) as dialTimeSec
FROM (SELECT *, [dbo].[GetProveedor](Telefono, Puerto,CallType) AS proBIDs 
		FROM (SELECT *, tipoLlamada_id as CallType 
				FROM ccologdials WITH(NOLOCK)
					WHERE fecha >= @from and fecha < @to and answerbit = 1
				) as basequery 
		) ccld
	LEFT JOIN ccoCallsOut Call WITH(NOLOCK) ON ccld.cal_id = Call.cal_id
			AND ccld.answerbit = 1
	LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
	LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
	LEFT JOIN ccCallCost_RIA ccost (NOLOCK) ON ccost.tipoLlamada_id = tl.tipoLlamada_id
			AND ccost.country_id = tl.country_id
ORDER BY DATE
		
INSERT INTO RepOutAnswAndXferCalls		
SELECT DATEADD(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) AS [date],
	clt.cal_id AS [callid],
	COALESCE(co.cam_id,ci.inbound_id,''0'')  AS [campaignId],
	COALESCE(camps.cam_descripcion, ACD.descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
	ISNULL((CASE tipo 
				WHEN 1 THEN ci.User_id 
				ELSE co.User_id 
			END),0) AS [userId],
	ISNULL((SELECT nombres + '' '' + apellidopaterno + '' '' + apellidomaterno FROM ccusers NOLOCK WHERE user_id = 
				(CASE tipo 
					WHEN 1 THEN ci.User_id 
					ELSE co.User_id 
				END)),''systemTranslated_NoName'') as [Agent],
	dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) AS [dialog],
	CASE 
		WHEN modo = 0 THEN ISNULL((SELECT TOP 1 tel FROM telefonosTransferencia WHERE tel = clt.destino),clt.destino)  
		WHEN modo = 3 THEN isnull((SELECT tel FROM telefonosConferencia WHERE tel = clt.destino),clt.destino) 
		WHEN modo = 4 THEN isnull((SELECT TOP 1 tel FROM telefonosTransferencia WHERE tel = clt.destino),clt.destino) 
		WHEN modo in(5,6) THEN isnull((SELECT Computer FROM ccposicion WHERE pos_id = abs(clt.destino)),clt.destino) 
	END AS [telephone],
	3 AS [dialId],
	(SELECT [description] FROM dialType WHERE dialId = 3) AS [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [CallTypes],
	CASE 
		WHEN tarifa.provedor_id IS NOT NULL THEN ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
			dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0) ,@country), 0) 
		ELSE cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)
	END AS [ncost],
	@IVA AS iva,
	CASE 
		WHEN tarifa.provedor_id IS NOT NULL THEN CONVERT(DECIMAL(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId,
			dbo.tDialog(clt.tAntesXfer,clt.tDespuesXfer,0)
			,@country),0.00) * (1 + (@IVA / 100.00))) 
		ELSE (cCall.cost_per_min + (CEILING((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) + 1) / 60) * cCall.additional_min)) * (1 + (@IVA / 100.00))
	END AS [total],
	IsNull(clt.channel, 0) as [trunk],
	case when (@country = 1 and modo = 4) then case when dbo.TelAni(clt.destino, camps.id_anilist) <> '''' then dbo.TelAni(clt.destino,
	camps.id_anilist) else camps.ani end else '''' end [ANI],
	ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) as dialTimeSec
FROM (SELECT *, tipoLlamada_id AS  CallType 
	FROM cclogtransfers WITH(NOLOCK) 
	WHERE modo not in (1,2) 
		AND (tAntesXfer > 0 or tDespuesXfer > 0) 
		AND dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) >= @from 
		AND dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) < @to) clt
	LEFT JOIN cccallsin ci WITH(NOLOCK) ON ci.cal_id=clt.cal_id AND tipo=1
	LEFT JOIN ccocallsout co WITH(NOLOCK) ON co.cal_id=clt.cal_id AND tipo=2 
	LEFT JOIN ccChannelTransfer channel ON clt.pbxId=channel.pbxId AND clt.channel BETWEEN channel.startChannel AND channel.endChannel
	LEFT JOIN cstoTarifa tarifa ON tarifa.provedor_id=channel.proveedorId AND tarifa.tipoLlamada_id = clt.CallType
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType AND tl.Country_id = @country)
	LEFT JOIN ccCallCost_RIA cCall ON cCall.country_id = tl.country_id AND cCall.tipoLlamada_id = tl.tipoLlamada_id
	LEFT JOIN ccCamps camps ON camps.[cam_id] = co.cam_id
	LEFT JOIN ccInbound ACD ON ACD.[Inbound_id] = ci.Inbound_id
order by date

end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva ALTER SP ccspRepOutAnswCalls'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutAnswCalls]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()
							
	delete RepOutAnswCalls with(rowlock)
	where [date] between @from and @to
						
	insert RepOutAnswCalls select [date], campaignId, ca.cam_descripcion campaign, 
	abnd.IDWG workgroupId, e.WGName workgroup, isnull(f.IDArea,0) areaId, g.AreaName area, total,
	cast(((nasig_tl*100.0)/total) as decimal(5,2)) asig_tl,
	cast(((nasig_nc*100.0)/total) as decimal(5,2)) asig_nc,
	cast(((nAnswered*100.0)/total) as decimal(5,2)) Answered,
	cast(((nassigned*100.0)/total) as decimal(5,2)) assigned,
	cast(((nabdn_sis*100.0)/total) as decimal(5,2)) abdn_sis
	from (
		select convert(varchar(10),cal_inicio,121) [date], co.cam_id campaignId, isnull(min(d.IDWG),1) idwg, count(*) total, 
		COUNT(CASE WHEN(statusCall_id = 16)THEN co.cal_id ELSE NULL END) nasig_tl,
		COUNT(CASE WHEN(statuscall_id = 15)THEN co.cal_id ELSE NULL END) nasig_nc,
		COUNT(CASE WHEN(statuscall_id = 13)THEN co.cal_id ELSE NULL END) nAnswered,
		COUNT(CASE WHEN(statuscall_id = 11)THEN co.cal_id ELSE NULL END) nassigned,
		COUNT(CASE WHEN(statuscall_id in (6,4))THEN co.cal_id ELSE NULL END) nabdn_sis
		from ccocallsout co with(index(IX_ccoCallsOut_2),nolock) 
		left join ccRIAWorkGroup_Calid d on (d.cal_id = co.cal_id)
		where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121),co.cam_id
	) abnd left join cccamps ca on ca.cam_id=abnd.campaignId 
	left join ccRIACat_WorkGroup as e on (e.idwg = abnd.idwg)
	left join ccRIAAreaWorkGroup as f on (f.idwg = e.idwg)
	left join ccRIACat_Areas as g on (g.idarea = f.idarea)
end'
		EXEC(@sql)
		

		SET @process = 'CW-4512 Coperva Alter SP ccspRepOutDialDetail'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail] 
@action AS TINYINT, 
@from AS   DATETIME = NULL, 
@to AS     DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
    SELECT @from =CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE())) - 15
if @to is null
    SELECT @to = GETDATE()

IF @action = 1
BEGIN  

DECLARE @country SMALLINT
SELECT @country = valor
FROM ccSettings
WHERE setting_id = 104

--Borrar lo que esta para no repetir          
DELETE FROM RepOutDialDetail WHERE date >= @from            AND date < @to
		        


--Inserta informacon de reporte  
INSERT INTO RepOutDialDetail
    SELECT fecha, 
            ISNULL(ISNULL(dials.cal_key, cs.cal_key), '''') cal_key, 
            telefono, 
            dials.tiporesdial_id,
			CASE 
				WHEN dials.tipoResDial_id = 14
				THEN ''systemTranslated_CancelledBySystem''
				ELSE ISNULL(descripcion, '''')
			END AS resultado,
            dials.[cam_id], 
            ISNULL(RTRIM(LTRIM(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') AS campa, 
            dials.tbusy AS Msgtime, 
            DATEPART(yyyy, fecha), 
            DATEPART(mm, fecha), 
            DATEPART(dd, fecha), 
            DATEPART(hh, fecha), 
            DATEPART(mi, fecha), 
            ISNULL(rl.name, ''''),
            CASE
                WHEN answerbit = 1
                THEN ''systemTranslated_Charged''
                ELSE ''systemTranslated_NotCharged''
            END AS billed, 
            ISNULL(cs.Dato1, '''') AS data1, 
            ISNULL(cs.Dato2, '''') AS data2, 
            ISNULL(cs.Dato3, '''') AS data3, 
            ISNULL(cs.Dato4, '''') AS data4, 
            ISNULL(cs.Dato5, '''') AS data5,
            CASE
                WHEN dials.[file_moved] = 1
                THEN ''systemTranslated_Remoto''
                ELSE ''Local''
            END AS file_Moved, 
            dials.disconnectCause, 
            COALESCE(dat.description, descripcion, ''N/A'') DCCustomer, 
            dials.dialType,
            CASE
                WHEN @country = 1
                THEN ISNULL(
    (
        SELECT CASE
                    WHEN dials.tipoLlamada_id IN(1, 2, 5)
                    THEN ''systemTranslated_fijo''
                    WHEN dials.tipoLlamada_id IN(3, 4)
                    THEN ''systemTranslated_cellPhone''
                    ELSE ''systemTranslated_Indefinite''
                END
    ), ''systemTranslated_Indefinite'')
                ELSE ''''
            END AS TipoTel, 
            ISNULL(CallDisposition, ''N/A'') AS CallDisposition, 
            ISNULL(califSubDesc, ''N/A'') AS CallSubDisposition
    FROM
    (
        SELECT dial.logDial_id, 
                dial.callout_id, 
                dial.cam_id, 
                CASE
					WHEN dial.canceledNoAgents = 1
					THEN 14
					ELSE dial.tipoResDial_id
				END AS tipoResDial_id,
                dial.Telefono, 
                dial.Puerto, 
                dial.fecha, 
                dial.tDialing,
                CASE
                    WHEN LEFT(dial.TipoDialingMode, 1) = ''1''
                    THEN ''Preview''
                    ELSE CASE
                            WHEN RIGHT(dial.TipoDialingMode, 2) = ''00''
                            THEN ''systemTranslated_Auto''
                            WHEN RIGHT(dial.TipoDialingMode, 2) IN(''10'', ''01'')
                            THEN ''systemTranslated_Manual''
                        END
                END AS dialType,
                dial.tBusy, 
                dial.answerbit, 
                dial.canceledNoAgents, 
                dial.cal_id, 
                dial.disconnectCause, 
                co.cal_key, 
                co.file_moved, 
                dial.tipoLlamada_id, 
                tco.Description AS CallDisposition, 
                tsco.califSubDesc
        FROM ccoLogDials dial(NOLOCK)
                LEFT JOIN ccocallsout co(NOLOCK) ON dial.cal_id = co.cal_id
                LEFT JOIN cctipocalifout tco WITH(NOLOCK) ON tco.calif_id = co.calif_id
                LEFT JOIN cctipocalifsubout tsco WITH(NOLOCK) ON tsco.califSub_id = co.califSub_id
        WHERE fecha >= @from
                AND fecha < @to
    ) dials
    LEFT JOIN ccoCallsOutSource cs(NOLOCK) ON dials.callout_id = cs.callout_id
    LEFT JOIN cctipoResultadoDial tr ON dials.tiporesdial_id = tr.tiporesdial_id
    LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]
    LEFT JOIN ccRIARegistryLists rl ON cs.list_id = rl.list_id
    LEFT JOIN DC_Extra dat ON(dat.id = CASE
                                            WHEN ISNUMERIC(SUBSTRING(dials.disconnectCause, 21, 3)) = 0
                                            THEN ''''
                                            ELSE SUBSTRING(dials.disconnectCause, 21, 3)
                                        END)
    WHERE fecha >= @from
            AND fecha < @to
    ORDER BY fecha
END'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Alter SP ccspRepOutManagementBase'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutManagementBase] 
@action AS TINYINT,
@from AS DATETIME = null,
@to AS DATETIME = null
AS

SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN

	IF OBJECT_ID(''tempdb..#TempRepOutManagementBase'') IS NOT NULL DROP TABLE #TempRepOutManagementBase

	create table #TempRepOutManagementBase(date datetime, dialResultCode int,dialResultId int,dialResult varchar(50),dispositionId int,
	disposition varchar(50),subDispositionId int,subDisposition varchar(50),total int,Agent varchar(100),Campaigns varchar(100)
	,[year] int,[month] int, [day] int ,[hour] int,[minutes] int
	,cal_id int, cal_telefono varchar(50),cal_key varchar(30)
	)

	create index IX_#TempRepOutManagementBase_I ON #TempRepOutManagementBase(cal_id)
	
	insert INTO #TempRepOutManagementBase
	SELECT fecha AS [date], 
       logdial.callout_id AS dialResultCode, 
       logdial.tipoResDial_id AS dialResultId, 
       ISNULL(resdial.descripcion, '''') AS dialResult,       
       ISNULL(tipocal.calif_id, 0) AS dispositionId, 
       ISNULL(tipocal.Description, '''') AS disposition, 
       ISNULL(tiposubcal.califSub_id, 0) AS subDispositionId,       
       ISNULL(tiposubcal.califSubDesc, '''') AS subDisposition, 
       1 AS Total, 
       ISNULL(cUser.LOGIN, '''') AS Agent, 
       ISNULL(ccCamps.cam_descripcion, '''') AS Campaigns
       ,DATEPART(yyyy,fecha) AS [year]
       ,DATEPART(mm, fecha) AS [month]
       ,DATEPART(dd, fecha) AS [day]
       ,DATEPART(hh, fecha) AS [hour]
       ,DATEPART(mi, fecha) AS [minutes]
       ,logDial.cal_id,
	   ISNULL(logdial.Telefono,'''') AS cal_telefono,
	   ISNULL(logdial.cal_Key,'''') AS cal_key	   	   
FROM ccoLogDials logdial with(nolock)
     LEFT JOIN cctipoResultadodial resdial ON logdial.tipoResDial_id = resdial.tipoResDial_id
     LEFT JOIN ccoCallsOut cout ON cout.cal_id = logdial.cal_id
     LEFT JOIN cctipocalifout tipocal ON cout.calif_id = tipocal.calif_id
     LEFT JOIN cctipocalifsubout tiposubcal ON cout.califSub_id = tiposubcal.califSub_id
     LEFT JOIN ccUsers cUser ON cUser.User_id = cout.User_id
     LEFT JOIN ccCamps ON ccCamps.cam_id = logdial.cam_id
	 WHERE fecha BETWEEN @from AND @to


	UPDATE A
	SET A.Agent = isnull(cUser.LOGIN, ''''), A.cal_id = cout.cal_id		
	FROM #TempRepOutManagementBase A
	INNER JOIN (
		SELECT A.cal_id, callout_id, User_id
		FROM ccoCallsOut A
		LEFT JOIN #TempRepOutManagementBase B ON A.cal_id = B.cal_id
		WHERE cal_Inicio BETWEEN @from
				AND @to AND B.cal_id IS NULL
		) cout ON A.dialResultCode = cout.callout_id
	inner JOIN ccUsers cUser ON cUser.User_id = cout.User_id
	WHERE A.cal_id IS NULL

	DELETE	FROM RepOutManagementBase WHERE [date] >= @from AND [date] < @to

	INSERT INTO RepOutManagementBase
							(DATE, 
							 dialResultCode, 
							 dialResultId, 
							 dialResult, 
							 dispositionId, 
							 disposition, 
							 subDispositionId, 
							 subDisposition, 
							 total, 
							 Agent, 
							 Campaigns, 
							 year, 
							 month, 
							 day, 
							 hour, 
							 minutes,
							 calKey,
							 telephone
							)
       SELECT DATE, 
              dialResultCode, 
              dialResultId, 
              dialResult, 
              dispositionId, 
              disposition,
              subDispositionId,
              subDisposition,
              Total, 
              Agent, 
              Campaigns, 
              year, 
              month, 
              day, 
              hour, 
              minutes,
			  cal_Key,
			  cal_telefono
       FROM #TempRepOutManagementBase

	IF OBJECT_ID(''tempdb..#TempRepOutManagementBase'') IS NOT NULL DROP TABLE #TempRepOutManagementBase
END'
		EXEC(@sql)


		SET @process = 'CW-4512 Coperva Alter SP ccspRepSpecialCallKeyHistory'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpecialCallKeyHistory]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()

	delete RepSpecialCallKeyHistory where [date] between @from and @to
	
	insert RepSpecialCallKeyHistory
		select CONVERT(varchar(16),fecha,121) [date], ISNULL(ld.cam_id, 0) campaignId,
		ISNULL(cam_descripcion, ''systemTranslated_NoCampaign'') campaign,
		ld.cal_Key callKey,ld.Telefono telephone,ISNULL(rd.descripcion, ''systemTranslated_NoStatus'') dialResult,
		ISNULL(cal.Description, ''systemTranslated_Dispositionless'') disposition, 
		ISNULL(cal_tdialog, 0) dialogTime, ISNULL(convert(varchar(30),cal_fcallback,121),''systemTranslated_NoCallback'') CallBacks,
		isNull(cast(us.Login as varchar(100)),''systemTranslated_NoUserName'') [login],
		isNull(us.ApellidoPaterno,'''') + '' '' + isNull(us.ApellidoMaterno, '''') + '' '' + IsNull(us.Nombres, ''systemTranslated_NoName'') as [user]
		from ccoLogDials ld  with(nolock)
		left join ccoCallsOut co (nolock) on co.cal_id = ld.cal_id
		left join ccTipoResultadoDial rd on rd.tipoResDial_id = ld.tipoResDial_id left join ccCamps ca on ca.cam_id = ld.cam_id
		left join ccTipoCalifOUT cal on cal.calif_id=co.calif_id 
		left join ccUserView us on us.User_id=co.User_id
		where ld.fecha between @from and @to and len(ld.cal_key)>0
end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Alter SP ccspRepSpecialTelephoneNumbersByRegistry'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpecialTelephoneNumbersByRegistry]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET NOCOUNT ON

create table #tempPhone(
[date] datetime,camId int,
tel1 int,tel2 int,tel3 int,tel4 int,tel5 int,
listid int
)
create table #sumTempPhone (
[date] datetime,
totalPhone int
)

create index IX_TEMPPHONE  on #tempPhone(listid)

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
	delete from RepSpecialTelephoneNumbersByRegistry where date >= @from and date < @to

	insert into #tempPhone
		select
		convert(datetime,convert(varchar(11),min(cal_fechaDial))) as [date],
		cam_id as camId,
		sum(case when cal_telefono <> '''' then 1 else 0 end),
		sum(case when cal_telefono2 <> '''' then 1 else 0 end),
		sum(case when cal_telefono3 <> '''' then 1 else 0 end),
		sum(case when cal_telefono4 <> '''' then 1 else 0 end),
		sum(case when cal_telefono5 <> '''' then 1 else 0 end),
		list_id
	from ccoCallsOutSource --with(index(IX_ccoCallsOutSource_19),nolock)
	where cal_fechaDial >= @from and cal_fechaDial < @to
	group by cam_id,list_id


	insert into #sumTempPhone
	select 	[date],SUM(tel1+tel2+tel3+tel4+tel5) from #tempPhone
	group by [date]



	insert into RepSpecialTelephoneNumbersByRegistry
	select date,campaignId,campaign,listId,listName
	,cPhoneNumber_count as cPhoneNumbers,''systemTranslated_'' + cPhoneNumber_count+''_Count'' as cPhoneNumber_Count,[count]
	,percentage_avg as percentage,''systemTranslated_'' + percentage_avg + ''_Avg'' as percentage_avg,[avg],
	[year],[month],[day],[hour],[minutes]
	from (
	select tem.[date],
	camId as ''campaignId'', camp.cam_descripcion as ''campaign'',
		isnull(rl.list_id,0) as ''listId'', isnull(rl.name, '''') as ''listName'',
		tem.tel1 as cPhoneNumbers1,tem.tel2 as cPhoneNumbers2,tem.tel3 as cPhoneNumbers3,tem.tel4 as cPhoneNumbers4,tem.tel5 as cPhoneNumbers5,
		dbo.fPercentage(tem.tel1,sumTemp.totalPhone ) as percentage1,
		dbo.fPercentage(tem.tel2,sumTemp.totalPhone) as percentage2,
		dbo.fPercentage(tem.tel3,sumTemp.totalPhone) as percentage3,
		dbo.fPercentage(tem.tel4,sumTemp.totalPhone) as percentage4,
		dbo.fPercentage(tem.tel5, sumTemp.totalPhone) as percentage5,
		datepart(yy,convert(datetime, convert(varchar(11),tem.[date]))) as [year],
		datepart(mm,convert(datetime, convert(varchar(11),tem.[date]))) as [month],
		datepart(dd,convert(datetime, convert(varchar(11),tem.[date]))) as [day],
		datepart(hh,convert(datetime, convert(varchar(11),tem.[date]))) as [hour],
		datepart(mi,convert(datetime, convert(varchar(11),tem.[date]))) as [minutes]
	 from #tempPhone tem
	 inner join ccRIARegistryLists rl on tem.listid =  rl.list_id
	 inner join cccamps camp on camp.cam_id=tem.camId
	 inner join #sumTempPhone sumTemp on tem.date=sumTemp.date)p
	 UNPIVOT(
	 [count] FOR cPhoneNumber_count IN  (cPhoneNumbers1, cPhoneNumbers2, cPhoneNumbers3, cPhoneNumbers4, cPhoneNumbers5)
		)AS unpvt
	 UNPIVOT(
	 [avg] FOR percentage_avg IN  (percentage1, percentage2, percentage3, percentage4, percentage5)
		)AS unpvt2
	where RIGHT(cPhoneNumber_count,1) = RIGHT(percentage_avg,1)

	drop table #tempPhone
	drop table #sumTempPhone

end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Alter SP ccspRepTrunkBusy'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepTrunkBusy]

@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS off
SET NOCOUNT ON

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
begin
	
	create table #RtnValue(cal_id int,
	[user_id] int,
	fecha datetime,
	puerto int,
	cam_id int,
	tbusy int,
	contador int,
	tipo int,
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

	create table #RtnValue2(cal_id int,
	[user_id] int,
	fecha datetime,
	puerto int,
	cam_id int,
	tbusy int,
	contador int,
	tipo int,
	fechafin datetime,
	fechaInicio datetime,
	fechaFinal datetime)

	create nonclustered index ix_RtnValue on #RtnValue2(
	[fecha] DESC,
	[fechafin] DESC
	)

	insert into #RtnValue
		select dials.cal_id, calls.user_id, dials.fecha, dials.Puerto, dials.cam_id,
		sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)) as tBusy,1 as contador, 1 as tipo,
		dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha) as fechafin			
		,dbo.GetTimeGroup(dials.fecha,0) as timegroup		
		,dbo.GetTimeGroup(
		dateadd(ss,sum(dials.tDialing+ dials.tBusy+ isnull(calls.cal_tDialog,0)+isnull(calls.cal_tXfer,0)+isnull(calls.cal_tRing,0)),dials.fecha)			
		,1) as timegroup_next					
		from ccologdials as dials left join ccocallsout as calls 
		on (dials.Puerto = calls.cal_puerto and dials.cal_id = calls.cal_id ) 
		where dials.fecha >= @from and dials.fecha < getdate()
		group by dials.cal_id, calls.user_id, dials.fecha, dials.Puerto, dials.cam_id 
	union all
		select incall.cal_id,incall.user_id,incall.cal_inicio as fecha,incall.cal_puerto as puerto, incall.inbound_id as cam_id, 
		sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)) as tBusy,1 as contador, 0 as tipo,
		dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio) as fechafin
		,dbo.GetTimeGroup(incall.cal_inicio,0) as timegroup	
		,dbo.GetTimeGroup(
		dateadd(ss,sum(isnull(incall.cal_tDialog,0) + isnull(incall.cal_tXfer,0)+ isnull(incall.cal_tRing,0)),incall.cal_inicio)
		,1) as timegroup_next				
		from cccallsin as incall 
		where cal_inicio >= @from and cal_inicio < getdate()
		group by incall.cal_id, incall.user_id, incall.cal_inicio, incall.cal_puerto, incall.inbound_id  

	delete #RtnValue
	where tbusy = 0
		
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

	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=15
		
	insert into #RtnValue2
	select *
	from #RtnValue
	where datediff(mi,fechainicio,fechafinal) > 15

	delete #RtnValue
	where datediff(mi,fechainicio,fechafinal) > 15

	insert into #RtnValue
	select cal_id, [user_id], th.start as fecha, t.Puerto, t.cam_id
		,dbo.TimeInterval(th.start,th.stop,t.fecha,fechafin)  as tBusy				
	,t.contador as llamadas, tipo, th.stop, th.start, th.stop
	from #RtnValue2 t
	join #times th on (t.fecha > th.Start and t.fecha < th.stop) OR th.Start between t.fecha and t.fechafin

	drop table #times
	drop table #RtnValue2

	select fecha as timegroup, puerto as port,cam_id,sum(tBusy) as tbusy,sum(contador) as llamadas,tipo
	into #ccGenOutPortStats
	from #RtnValue
	group by fecha, puerto, cam_id, tipo

	drop table #RtnValue
		
	delete from RepInTrunkBusy where date >= @from AND date < @to

	insert into RepInTrunkBusy
		select timegroup, #ccGenOutPortStats.cam_id, [in].descripcion, port, tbusy, llamadas,
		datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year],
		datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month],
		datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day],
		datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour],
		datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
		from #ccGenOutPortStats
		inner join ccInbound [in] on ([in].inbound_id = #ccGenOutPortStats.cam_id and #ccGenOutPortStats.tipo = 0)
		where timegroup >= @from and timegroup < @to
			
	delete from RepOutTrunkBusy where date >= @from AND date < @to

	insert into RepOutTrunkBusy
		select timegroup, #ccGenOutPortStats.cam_id, [out].cam_descripcion, port, tbusy, llamadas,
		datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year],
		datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month],
		datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day],
		datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour],
		datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
		from #ccGenOutPortStats
		inner join cccamps [out] on ([out].cam_id = #ccGenOutPortStats.cam_id and #ccGenOutPortStats.tipo = 1)
		where timegroup >= @from and timegroup < @to
		
	delete from RepTrunkBusy where date >= @from AND date < @to

	insert into RepTrunkBusy
		select timegroup, port, tbusy, llamadas,
		datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year],
		datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month],
		datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day],
		datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour],
		datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
		from #ccGenOutPortStats
		where timegroup >= @from and timegroup < @to
				
	drop table #ccGenOutPortStats 
end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Alter SP ReportsMasterProcess'
		SET @sql = 'ALTER procedure [dbo].[ReportsMasterProcess] 
@from as datetime=null,@WithMedia bit =1,@to as datetime=null
as

set nocount on

declare @replicationName varchar(max)
declare @dateStart datetime,@dateSP datetime
declare @schedule_id int,@scheduleTime int
declare @isSunday tinyint,  @hourSunday tinyint,@minSunday tinyint

declare @sessionKIll table(id int, sessionId int)
declare @i int,@count int
declare @sessionId int
declare @SQL varchar(max)
declare @name sysname
declare @descError nvarchar(max)

set @dateStart = getdate()
set @scheduleTime = 10


print ''---Get schedule_id and @scheduleTime ----''
select @schedule_id=C.schedule_id, @scheduleTime=C.freq_subday_interval
	FROM msdb.dbo.sysjobs A
	LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
	INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
	where A.name=''ReportsMasterProcess''



print ''---Kill Process Replication Merge Agent----''
while exists(SELECT	s.session_id AS SessionID		
	from [master].sys.dm_exec_sessions  as s 
	LEFT OUTER JOIN [master].sys.sysprocesses p	ON s.session_id = p.spid
	where s.session_id in(
	select distinct r.blocking_session_id
	FROM [master].sys.dm_exec_sessions AS s
	INNER JOIN [master].sys.dm_exec_requests AS r ON r.session_id = s.session_id
	WHERE    r.session_id != @@SPID and  r.blocking_session_id   <>0
	)
	and s.[program_name] like ''%Replication Merge Agent%''	
	and DB_NAME(p.dbid)=''ccReportsRia''	
) begin
	insert into @sessionKIll(id,sessionId)
	
	SELECT	ROW_NUMBER() OVER(ORDER BY s.session_id) AS Row#, s.session_id AS SessionID		
	from [master].sys.dm_exec_sessions  as s 
	LEFT OUTER JOIN [master].sys.sysprocesses p	ON s.session_id = p.spid
	where s.session_id in(
	select distinct r.blocking_session_id
	FROM [master].sys.dm_exec_sessions AS s
	INNER JOIN [master].sys.dm_exec_requests AS r ON r.session_id = s.session_id
	WHERE    r.session_id != @@SPID and  r.blocking_session_id   <>0
	)
	and s.[program_name] like ''%Replication Merge Agent%''
	and DB_NAME(p.dbid)=''ccReportsRia''

	select * from @sessionKIll

	select @i=1,@count =COUNT(*) from @sessionKIll
	while @i<=@count begin
		select @sessionId=sessionId from @sessionKIll where id=@i
		SET @SQL = ''KILL '' + CAST(@sessionId as varchar(max))
		begin try
			EXEC (@SQL)
		end try
		begin catch
			print @SQL+ '' is proccess end''
		end catch
		set @i=@i+1
	end
	delete from @sessionKIll
end

print ''--------------- Get Jobs Replication ------------------------------''
create table #replications ([name] nvarchar(100), flag bit)

;

with jobNotStart as(
select distinct A.[name] from msdb.dbo.sysjobs A 
	inner join PublicationLowLoad B on A.[name] like ''%''+B.namePublication+''%''		
	where A.[name] like ''%ccReportsRia- 0%'' and A.[name] like ''%CCenterRia%''	
--union all
--select distinct A.[name] from msdb.dbo.sysjobs A 
--	inner join PublicationHighLoad B on A.[name] like ''%''+B.namePublication+''%''	
--	where A.[name] like ''%ccReportsRia- 0%'' and A.[name] like ''%CCenterRia%''
)

insert into #replications
select distinct A.[name],0 from msdb.dbo.sysjobs A 
	where A.[name] like ''%ccReportsRia- 0%'' and A.[name] like ''%CCenterRia%''	
	and A.name not in(select name from jobNotStart)	

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%ccReportsRia- 0%'' and [name] like ''%CCRecorderRia%'' order by [name]

select @count=count(*) from #replications

while(select count(*) from #replications with(nolock) where flag = 0) > 0 and datediff(ss,@dateStart,getdate())<(@scheduleTime*60)
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0
	
	if (
		SELECT top 1 sjh.run_status
	  FROM msdb.dbo.sysjobhistory                sjh  
	  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
	  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
	  WHERE
	  j.name = @replicationName
	  order by sjh.instance_id desc		
	) <>4 
	or not exists(SELECT top 1 sjh.run_status
	  FROM msdb.dbo.sysjobhistory                sjh  
	  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
	  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
	  WHERE
	  j.name = @replicationName
	  order by sjh.instance_id desc	)
	
	begin
		exec msdb.dbo.sp_start_job @job_name = @replicationName
		print ''sp_start_job ''+@replicationName
	end
	else begin
		print ''Job is Init ''+@replicationName
	end

	update #replications with(rowlock) 	set flag = 1	where [name] = @replicationName

	WAITFOR DELAY ''00:00:03''		

	while (
		SELECT top 1 sjh.run_status
	  FROM msdb.dbo.sysjobhistory                sjh  
	  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
	  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)  
	  WHERE
	  j.name = @replicationName
	  order by sjh.instance_id desc		
	) = 4
	begin	
		WAITFOR DELAY ''00:00:01''
		print ''In Progress Job in ReplicationName: ''+@replicationName
		if datediff(ss,@dateStart,getdate())>((@scheduleTime*60)/@count) begin
			print ''Stop Job in ReplicationName: ''+@replicationName
			break	
		end
	end
	print ''Progress End Job in ReplicationName: ''+@replicationName
end

drop table #replications

print ''--------------------------- Creacion tablas cada domingo ---------------------------''
select  @isSunday = datepart(dw, getdate()),@hourSunday = datepart(hh, getdate()), @minSunday = datepart(mi, getdate())

if @isSunday=1 and @hourSunday = 3 and @minSunday>=30 begin

	if exists (select * from sys.tables where name = ''logsReportsMaster'') begin
		drop table logsReportsMaster
	end

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

print ''--------------------------- Termina Creacion tablas cada domingo ---------------------------''


declare @tableArticle table(nameArticle [sysname],objectId int)
declare @tableTrigger table(id int identity, nameArticle [sysname])

insert into @tableArticle(nameArticle,objectId)
SELECT Art.name nameArticle,t.object_id FROM dbo.sysmergepublications P
inner join dbo.sysmergearticles Art on Art.pubid=P.pubid
inner join sys.tables t on t.name=Art.name

insert into @tableTrigger
select t.name as nameTrigger from @tableArticle Art
inner join sys.triggers  t on Art.objectId=t.parent_id
where name not like ''MSmerge_%''

select @i=1,@count =count(*) from @tableTrigger
while @i<=@count
begin
	select @name = nameArticle  from @tableTrigger where id=@i
	set @sql =''DROP TRIGGER ''+ @name 
	exec (@sql)
	set @i = @i+1
end

print ''--------------------------- DROP TRIGGER Tables ---------------------------''


-------------------- ejecuccion de las construnccion de los reportes -----------------------------------------			
exec ReportsMasterProcessWIthOnlyGenerate @from=@from,@to=@to,@scheduleTime=@scheduleTime,@dateStart=@dateStart

print ''---#reinitmergepullsubscription----''
declare @lastTenMinuteFirst datetime
declare @id int
declare @publisher_reinit nvarchar(max)
declare @publisher_db_reinit nvarchar(max)
declare @publication_reinit nvarchar(max)
declare @upload_first_reinit nvarchar(max)

set @lastTenMinuteFirst = dateadd(minute,-@scheduleTime*2,getdate())

create table #reinitmergepullsubscription(
id int not null identity,
publisher nvarchar(max) not null,
publisher_db nvarchar(max)not null,
publication nvarchar(max) not null,
upload_first nvarchar(max) not null,
[status] bit not null
)

insert into #reinitmergepullsubscription
select distinct s.name, ma.publisher_db, ma.publication, ''false'', 0
from distribution.dbo.MSmerge_history mh
left outer join distribution.dbo.MSrepl_errors me
on (mh.error_id = me.id)
left outer join distribution.dbo.MSmerge_agents ma
on (mh.agent_id = ma.id)
left outer join master.sys.servers s
on (ma.publisher_id = s.server_id)
where 
(mh.comments like ''%You must reinitialize the subscription (without upload)%'' or
mh.comments like  ''%The Merge Agent failed because the schema of the article at the Publisher does not match the schema of the article at the Subscriber%'')
and mh.time >= @lastTenMinuteFirst
and ma.subscriber_db = ''ccReportsRia''

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
	begin
		set rowcount 1
		select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first
		from #reinitmergepullsubscription
		where [status] = 0
		set rowcount 0
		
		exec sp_reinitmergepullsubscription  @publisher = @publisher_reinit,    @puSblisher_db = @publisher_db_reinit,    @publication = @publication_reinit,    @upload_first = @upload_first_reinit

		update #reinitmergepullsubscription
		set [status] = 1
		where id = @id
	end

drop table #reinitmergepullsubscription

if DATEDIFF(ss,@dateStart,getdate())>@scheduleTime*60 begin
	set @scheduleTime=@scheduleTime+1
	if  @scheduleTime < 59 begin
		EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
	end	
end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva JOb ReportsMasterProcess'
		SET @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsMasterProcess'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcess'', @delete_unused_schedule=1
end

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcess'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''ReportsMasterProcess'', 
		@category_name=N''Nuxiba'', 
		@owner_login_name=N''replication'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate Reports]    Script Date: 13/11/2020 02:08:05 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''EXEC ReportsMasterProcess'', 
		@database_name=N''CCReportsRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ReportMasterProcessAfter'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130912, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=40000
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''RepotsMasterProcess'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20201113, 
		@active_end_date=99991231, 
		@active_start_time=43000, 
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

		SET @process = 'CW-4512 Coperva JOb ReportsMasterProcessYesterday'
		SET @sql = 'USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''ReportsMasterProcessYesterday'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''ReportsMasterProcessYesterday'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ReportsMasterProcessYesterday'', 
		@enabled=1, 
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''execute ReportsMasterProcess Yesterday 3:00 AM - 3:00 AM'', 
		@category_name=N''Nuxiba'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Generate Reports'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0,  @subsystem=N''TSQL'', 
			@command=N''declare @from datetime,@to datetime,@dateNow datetime
set @to =convert(datetime,convert(varchar(11),getdate(),121)+''''03:00:00'''',121)
set @from =DATEADD(dd,-1,@to)

set @dateNow =getdate()

EXEC ReportsMasterProcessWIthOnlyGenerate @from=@from,@to=@to,@scheduleTime=30,@dateStart=@dateNow'',
		@database_name=N''ccReportsRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ReportsMasterProcessWIthOnlyGenerate'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130912, 
		@active_end_date=99991231, 
		@active_start_time=40000,  
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

		SET @process = 'CW-4512 Coperva alter sp ccspRepOutCalls'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint
SELECT @HourExtend=2
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint
DECLARE @tresDelayIn AS smallint

if @action = 1
begin

	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog
	EXEC @tresDelayIn=ccspConfigtresDelayIn

	declare @interval int
	 declare @starttime datetime
     declare @number int
     set @starttime = @from
     set @number = 0
	 set @interval=15

      create table #inboundData(row int identity, dateStartDetail datetime,
      dateEndDetail datetime,      timegroup datetime, timegroup_next datetime,      time_endque datetime,
      time_ring datetime,      time_dialog datetime, time_notes datetime,      time_end_call datetime,
      phone_in varchar(30),      cal_id int, dni_id int,      Inbound_id int,
      User_id int,      ntotal int, ninitial int,      nout_hour int,
      nout_service int, nabnd int,     nno_agent int,
      nque int,      ntimeout int,    noverflow int,
      nxfer int,      nxfer_que int,     nabnd_xfer int,      nabnd_ring int,
      nno_answer int,      nabnd_dialog int,
      nanswer int,      nlost int,     nmsg int,      nabnd_tres int,
      nansw_tres int,      tque_max int,
      tque int,      txfer int,     tdialog int,      tnotes int,
      tring int,      tresp int,     nMoh int,      nWHag int,
      nWHcl int)

      create table #outboundData( row int identity,
      dateStartDetail datetime, dateEndDetail datetime,
      timegroup datetime, timegroup_next datetime,
      cam_id int,User_id int,ntotal int,nno_agent int,
      nxfer int,nabnd_xfer int,nabnd_ring int, nno_answer int,
      nabnd_dialog int,nanswer int,
      nlost int,tque int,txfer int,tring int,
      tdialog int,tnotes int,tresp int,nhangup int, nMoh int,nWHag int,nWHcl int,time_endque datetime,
      time_ring datetime,time_dialog datetime,
      time_notes datetime,time_end_call datetime,
      phone_out varchar(30),cal_id int,cal_puerto int, idwg int)

     CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

    create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
    create nonclustered index ix_times2 on #times([Start] DESC)
	CREATE TABLE #sessionTime([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,
	[timegroup] [datetime] NOT NULL,[timegroup_next] [datetime] NOT NULL,tlog int 
	)


	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

	insert into #sessionTime
	exec ccspGenSession @from=@from,@to=@to

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	SELECT      cal_inicio as dateStartDetail,
		  dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
		  dbo.GetTimeGroup(cal_inicio,0) as timegroup,
		  dbo.GetTimeGroup(
		  dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio)
		  ,1)  as timegroup_next
		  ,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		  ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		  ,isnull(max(cal_Ani),0) as phone_in,cal_id,dni_id,Inbound_id,[User_id]
		  ,COUNT(cal_id)AS ntotal
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END),0) AS ninitial
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END),0) AS nout_hour
		  ,ISNULL(COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END),0) AS nout_service
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0) AS nno_agent
		  ,ISNULL(COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END),0) AS nque
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0) AS ntimeout
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0) AS noverflow
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nxfer
		  ,ISNULL(COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END),0) AS nxfer_que
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd_xfer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END),0) AS nabnd_ring
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),0) AS nno_answer
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END),0) AS nabnd_dialog
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) AS nanswer
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0) AS nlost
		  ,ISNULL(COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END),0) AS nmsg
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nabnd_tres
		  ,ISNULL(COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nansw_tres
		  ,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		  ,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
		  ,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
		  ,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
		  ,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
		  FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
		  WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
		  group by cal_id,[User_id],Inbound_id,cal_inicio,dni_id

	delete #inboundData WHERE timegroup>=@from AND timegroup<@to AND INBOUND_ID>0
	AND ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0

	select * into #inboundData2 from #inboundData where datediff(mi,timegroup,timegroup_next)>15

	delete #inboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	select
		  dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call
		  ,phone_in,cal_id,dni_id,Inbound_id,[User_id]
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ninitial else 0 end as ninitial
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_hour else 0 end as nout_hour
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_service else 0 end as nout_service
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd else 0 end as nabnd
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nque else 0 end as nque
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntimeout else 0 end as ntimeout
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then noverflow else 0 end as noverflow
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer_que else 0 end as nxfer_que
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nmsg else 0 end as nmsg
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_tres else 0 end as nabnd_tres
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nansw_tres else 0 end as nansw_tres
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then tque_max else 0 end as tque_max
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				  when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque
		  ,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				  when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
				  when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				  when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer               ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
				  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
		  ,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
				  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				  when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		  ,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				  when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
				  when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				  when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
		  from #inboundData2 t
		  join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  datediff(ss,th.start,timegroup_next)>0
		  order by cal_id

	drop table #inboundData2


	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,idwg)
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull(sum(cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		,dbo.GetTimeGroup(cal_inicio,0) as timegroup
		 ,dbo.GetTimeGroup(
		 dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio)
		 ,1) as timegroup_next
			,cam_id, [User_id]
			,COUNT(cal_id) AS ntotal
			,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END),0) AS nno_agent
			,ISNULL(COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END),0) AS nxfer
			,ISNULL(COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END),0) AS nabnd_xfer
			,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END),0) AS nabnd_ring
			,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END),0) AS nno_answer
			,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END),0) AS nabnd_dialog
			,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) AS nanswer
			,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END),0) AS nlost
			,ISNULL(SUM(cal_twait),0) as tque
			,ISNULL(SUM(cal_txfer),0)AS txfer
			,isnull(SUM(cal_tring),0) as tring
			,isnull(SUM(cal_tdialog),0) as tdialog
			,isnull(SUM(cal_tnotas),0) as tnotes
			,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
			,ISNULL(COUNT(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0) AS nhangup
			,ISNULL(SUM(CASE WHEN cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag
			,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
			,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
			,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
			,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
			,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
			,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
			,isnull(max(cal_telefono),0) as phone_out,cal_id,cal_puerto, 0 as idwg
		  FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
		  WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
		  -- para contar bien las llamadas manuales
		  and cal_manual in (0,2,3)
		  group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto


	delete from #outboundData WHERE timegroup>=@from AND timegroup<@to
		  AND ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		  AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		  AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0  and nhangup=0



    update A
    set idwg = B.idwg
    from #outboundData A
    inner join ccriaworkgroup_calid B on A.cal_id = B.cal_id


	select * into #outboundData2 from #outboundData where datediff(mi,timegroup,timegroup_next)>15

	delete #outboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,idwg)
	select
		  dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,cam_id,[User_id]
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
				  when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque
		  ,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
				  when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
				  when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
				  when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer
		  ,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
				  when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
				  when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
				  when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring
		  ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
				  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
				  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
				  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
		  ,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
				  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
				  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
				  when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
		  ,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nhangup else 0 end as nhangup
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
		  ,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
		  ,time_endque,time_ring,time_dialog,time_notes,time_end_call
		  ,phone_out,cal_id,cal_puerto,idwg
		  from #outboundData2 t
		  inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		  where  datediff(ss,th.start,timegroup_next)>0


	drop table #outboundData2

	select DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail
		,convert(smalldatetime,
		dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0)
		) as timegroup
		,convert(smalldatetime,
			dbo.GetTimeGroup(fecha,1)
		) as timegroup_next

		 
				,[User_id]
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE 0 END),0) AS tunknown
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE 0 END),0) AS tnot_av
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE 0 END),0) AS tav
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE 0 END),0) AS tprob
				,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE 0 END),0) AS tother
				,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
				into #timeDetailAgent
		  from ccLogAgentesDia
		  WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
		  GROUP BY
		 convert(smalldatetime,		dbo.GetTimeGroup(DATEADD(ss,-tStatus,fecha),0)		) 
		,convert(smalldatetime,			dbo.GetTimeGroup(fecha,1)		)
		 , [User_id]

	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15

	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother)
	select
		  min(dateStartDetail),min(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tunknown,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tunknown
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnot_av,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tnot_av
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tprob,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tprob,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tprob
		  ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				  when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				  when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
		  ,isnull(sum(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	group by th.start,th.stop,[User_id]

	drop table #timeDetailAgent2

	select ROW_NUMBER() OVER(ORDER BY xTimeDetail.timegroup,xTimeDetail.[user_id] ) AS Row,
		  xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
		  ,ISNULL(calls.txfer,0) as txfer,ISNULL(tdialog,0) as tdialog,ISNULL(tnotes,0) as tnotes,ISNULL(tring,0) as tring
		  ,ISNULL(nMoh,0) as nMoh,ISNULL(nWHag,0) as nWHag,ISNULL(nWHcl,0) as nWHcl
		  ,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
					 FROM #sessionTime
					 WHERE [user_id]=xTimeDetail.[user_id]
						   AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
		  ),0)AS t1
		  ,ISNULL((SELECT top 1 900
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login<=xTimeDetail.timegroup AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t2
		  ,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t3
		  ,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(mi,15,xTimeDetail.timegroup))
						   FROM #sessionTime
						   WHERE [user_id]=xTimeDetail.[user_id]
								 AND login>xTimeDetail.timegroup AND login<DATEADD(mi,15,xTimeDetail.timegroup)AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
				),0)AS t4
		  into #agentInformation
		  from (select min(dateStartDetail) as dateStartDetail,min(dateEndDetail) as dateEndDetail,timegroup,timegroup_next,[User_id]
			 ,sum(tunknown) as tunknown,sum(tnot_av) as tnot_av,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother,sum(nother) as nother
				from #timeDetailAgent
				group by timegroup,timegroup_next,user_id
				)xTimeDetail
	right join
	(select CASE WHEN #inboundData.timegroup IS NOT NULL THEN #inboundData.timegroup
					 WHEN #outboundData.timegroup IS NOT NULL THEN #outboundData.timegroup ELSE NULL END timegroup,
		  CASE WHEN #inboundData.[user_id] IS NOT NULL THEN #inboundData.[user_id]
				  WHEN #outboundData.[user_id] IS NOT NULL THEN #outboundData.[user_id] ELSE NULL END as [user_id]
		  ,ISNULL(SUM(#inboundData.txfer),0)+ ISNULL(SUM(#outboundData.txfer),0)as txfer
		  ,ISNULL(SUM(#inboundData.tdialog),0)+ ISNULL(SUM(#outboundData.tdialog),0)as tdialog
		  ,ISNULL(SUM(#inboundData.tnotes),0)+ ISNULL(SUM(#outboundData.tnotes),0)as tnotes
		  ,ISNULL(SUM(#inboundData.tring),0)+ ISNULL(SUM(#outboundData.tring),0)as tring
		  ,ISNULL(SUM(#inboundData.nMoh),0)+ ISNULL(SUM(#outboundData.nMoh),0)as nMoh
		  ,ISNULL(SUM(#inboundData.nWHag),0)+ ISNULL(SUM(#outboundData.nWHag),0)as nWHag
		  ,ISNULL(SUM(#inboundData.nWHcl),0)+ ISNULL(SUM(#outboundData.nWHcl),0)as nWHcl
	from #inboundData
	FULL OUTER JOIN #outboundData ON(#inboundData.timegroup=#outboundData.timegroup AND #inboundData.[user_id]=#outboundData.[user_id])
	group by
		  case when #inboundData.timegroup IS NOT NULL then #inboundData.timegroup
				 when #outboundData.timegroup IS NOT NULL then #outboundData.timegroup else NULL end
		  ,case when #inboundData.[user_id] IS NOT NULL then #inboundData.[user_id]
				  when #outboundData.[user_id] IS NOT NULL then #outboundData.[user_id] else NULL end
	) as calls on calls.timegroup = xTimeDetail.timegroup and xTimeDetail.[user_id]=calls.[user_id]
	where xTimeDetail.timegroup is not null

	drop table #timeDetailAgent


	 SELECT timegroup, ccCampsAgente.cam_id
		, SUM((t1+t2+t3+t4) - (tnot_av + tprob + tother)) AS pos_time
		, COUNT(CASE WHEN ((t1+t2+t3+t4) - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE 0 END) AS tresPos
	 INTO #ccGenOutCamp
	 FROM #agentInformation
		INNER JOIN ccCampsAgente ON (#agentInformation.[user_id] = ccCampsAgente.[user_id])
	 WHERE timegroup >= @from AND timegroup < @to
	 GROUP BY timegroup, ccCampsAgente.cam_id

	 select ROW_NUMBER() OVER(Order by row) as id,
		  #outboundData.row, #outboundData.timegroup as [date],0 as areaId,'''' as area
		 ,idwg as workgroupid,'''' as workgroup
		 ,#outboundData.cam_id as campaignid,'''' as campaign
		 ,[User_id] as userId,'''' as [user]
		 ,ntotal, nxfer, nno_agent, nanswer, nno_answer, nlost, nabnd_xfer, nabnd_ring, nabnd_dialog
		 ,1 as pos_tot, pos_time, nhangup, (tdialog + tnotes) as  tatencion
		 ,datepart(yy,convert(datetime,#outboundData.timegroup)) as [year]
		 ,datepart(mm,convert(datetime,#outboundData.timegroup)) as [mounth]
		 ,datepart(dd,convert(datetime,#outboundData.timegroup)) as [day]
		 ,datepart(hh,convert(datetime,#outboundData.timegroup)) as [hour]
		 ,datepart(mi,convert(datetime,#outboundData.timegroup)) as [minutes]
		 ,cal_id,phone_out,dateStartDetail
		 into #tempRepOutCalls
		 from #outboundData
		 left join #ccGenOutCamp  ON (#outboundData.timegroup = #ccGenOutCamp.timegroup and #outboundData.cam_id=#ccGenOutCamp.cam_id)

	 SELECT
      RANK() OVER(PARTITION BY row ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      into #tempTime
      FROM #tempRepOutCalls
      where row in
            (select row from #tempRepOutCalls temp GROUP BY temp.row HAVING Count(*) > 1 )

       update t
            set ntotal=0,nxfer=0,nno_agent=0,nanswer=0,nno_answer=0,nlost=0,nabnd_xfer=0,nabnd_ring=0,nabnd_dialog=0,tatencion=0
            from #tempRepOutCalls t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1

    delete #tempTime

    insert into #tempTime([rank],rowNumber,id)
    SELECT
      RANK() OVER(PARTITION BY cal_id ORDER by id) as [rank],
      ROW_NUMBER() OVER(Order by id) as rowNumber,
      id
      FROM #tempRepOutCalls
      where cal_id in
            (select cal_id from #tempRepOutCalls temp GROUP BY temp.cal_id HAVING Count(*) > 1 )

       update t
            set pos_tot=0
            from #tempRepOutCalls t
            inner join #tempTime temp on t.id = temp.id
            where [rank]>1

    --Borrar lo que esta para no repetir
	delete from RepOutCalls with(rowlock)
	where date >= @from AND date < @to

     insert into RepOutCalls
		select date,areaId,area,workgroupid,workgroup,campaignid,campaign,userId,user,ntotal,nxfer,nno_agent,nanswer,nno_answer,nlost,nabnd_xfer,nabnd_ring,nabnd_dialog
		,isnull(pos_tot,0),isnull(pos_time,0),nhangup,tatencion,year,mounth,day,hour,minutes,cal_id,phone_out,dateStartDetail
		from #tempRepOutCalls order by cal_id


	delete RepOutCalls
	where userId = 0
	and [date] >= @from and [date] < @to

	update RepOutCalls
	set areaId = idArea
	from RepOutCalls
	left outer join ccriaareaworkgroup on (workgroupid = idwg)
	where idarea is not null
	and [date] >= @from and [date] < @to

	delete RepOutCalls
	where areaId = 0
	and [date] >= @from and [date] < @to

	update RepOutCalls set
	area = (select areaname from ccriacat_areas where idarea = areaid)
	,workgroup = (select wgname from ccriacat_workgroup where idwg = workgroupid)
	,campaign = (select cam_descripcion from cccamps where cam_id = campaignid)
	,[user] = (select login from ccUserView where user_id = userid)
	where [date] >= @from and [date] < @to

	drop table #times
	drop table #sessionTime
	drop table #inboundData
	drop table #outboundData
	drop table #agentInformation
	drop table #ccGenOutCamp
	drop table #tempTime
	drop table #tempRepOutCalls

end'
		EXEC(@sql)

		SET @process = 'CW-4512 Coperva Alter SP ccspRepAvgAnswerTimeChats'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAvgAnswerTimeChats]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
	delete RepAvgAnswerTimeChats where date >= @from and date < @to

	insert into RepAvgAnswerTimeChats
	select 
	CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121) as [date], userId, [Login], inboundId, [inbound],
	[user], 
	 convert(decimal(10,2),isnull( sum([answerTime])/count(*),0.00)) as [avgAnswerTime]		
	, datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
	, datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
	, datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
	, datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
	, datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
	from(
	select requestDate as [date], userId, [Login] as [login], 
	inboundId, c.descripcion as [inbound], nombres + '' '' + apellidopaterno + '' '' + apellidomaterno as [user],
	case when firstMessageTime is null then convert(int,isnull(firstMessageTime,0)) 
	else datediff(ss,chatdate,firstMessageTime) end as [answerTime]
	from ccriachats a
	left join ccUserView b on (a.userId = b.user_id)
	left join ccinbound c on (a.inboundId = c.inbound_id)
	where b.user_id is not null
	and c.inbound_id is not null
	and a.chatstatus = 4) as answerTime
	group by CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121), userId, [Login], inboundId, [inbound], [user]

end'
		EXEC(@sql)
		
				
		
		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF

