/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2017/01/06
Description:
**********************************************************************************************
	Se agrega tarea CW-561_GASJ_Reportes_Errescuer_Fase_2
Database: ccReportsRia
Required version: 40



IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =42
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try

	set @process = 'Drop SP -- ccspRepDialingResultsDetail 4180'
	set @Sql= 'if exists (select * from sys.procedures where name = ''ccspRepDialingResultsDetail'') DROP PROCEDURE [dbo].[ccspRepDialingResultsDetail]'
	EXEC(@sql)




	set @process = 'Drop SP -- RepOutManagementBase 4170'
	set @Sql= 'if exists (select * from sys.procedures where name = ''ccspRepOutManagementBase'') DROP PROCEDURE [dbo].[ccspRepOutManagementBase]'
	EXEC(@sql)

	set @process = 'Drop SP -- ccspRepAgentCallStatusesByInterval 2070'
	set @Sql= 'if exists (select * from sys.procedures where name = ''ccspRepAgentCallStatusesByInterval'') DROP PROCEDURE [dbo].[ccspRepAgentCallStatusesByInterval]'
	EXEC(@sql)

	set @process = 'Drop Procedures  -- ccspRepAnsweredCallsByDialingRetries'
	set @Sql= 'IF EXISTS (SELECT * FROM sys.procedures where name = N''ccspRepAnsweredCallsByDialingRetries'') Drop PROCEDURE ccspRepAnsweredCallsByDialingRetries'
	EXEC(@sql)

	set @process = 'Drop Procedures  -- ccspRepDetailAgent'
	set @Sql= 'IF EXISTS (SELECT * FROM sys.procedures where name = N''ccspRepDetailAgent'') Drop PROCEDURE ccspRepDetailAgent'
	EXEC(@sql)

	set @process = 'RepAnsweredCallsByDialingRetries - Tabla'
	set @Sql= 'IF NOT EXISTS (SELECT * FROM sys.tables where name = N''RepAnsweredCallsByDialingRetries'')
BEGIN
	create table [dbo].[RepAnsweredCallsByDialingRetries](
		[date] [datetime] NOT NULL,
		[calId] [int] NOT NULL,
		[telephone] [varchar](30) NOT NULL,
		[dialResultId] [int] NOT NULL,
		[dialResult] [varchar](20) NOT NULL,
		[tries] [int] NOT NULL,
		[campaignId] [smallint] NOT NULL,
		[campaing] [varchar](40) NOT NULL,
		[userId] [smallint] NOT NULL,
		[agentName] [varchar](115) NOT NULL,
		[extension] [varchar](7) NOT NULL,
		[startHour] [varchar](12) NOT NULL,
		[endHour] [varchar](12) NOT NULL,
		[dialogTime] [smallint] NOT NULL,
		[dispositionId] [smallint] NOT NULL,
		[subDispositionId] [smallint] NOT NULL,
		[disposition] [varchar](40) NOT NULL,
		[subDisposition] [varchar](40) NOT NULL,
		[wrapup] [smallint] NOT NULL,
		[year] [int] NOT NULL,
		[month] [int] NOT NULL,
		[day] [int] NOT NULL,
		[hour] [int] NOT NULL,
		[minutes] [int] NOT NULL
	) ON [PRIMARY]
END
	'
	EXEC(@sql)

	set @process = 'RepDetailAgent - Tabla'
	set @Sql= 'IF NOT EXISTS (SELECT * FROM sys.tables where name = N''RepDetailAgent'')
BEGIN
	create table RepDetailAgent(
	[userId] int not null,
	[user] varchar(50) not null,
	[userName] varchar(100) not null,
	[date] datetime not null,
	sessionTime int not null,--[Timepo de cinexion]
	activeTime int not null,--[Tiempo efectivo de trabajo]
	talkingtTime int not null,--[Tiempo en llamada]
	holdTime int not null,--[Tiempo en wait]
	unavaibleTime int not null,--[Tiempo en no disponibles]
	talkingPercent float not null,--[% en dialogo]
	waitpercent float not null,--[% en wait]
	readyPercent float not null, --[% en disponible]
	adherencia float not null,--[Adherencia]
	totalCalls int not null,--[Número de llamadas]
	callsByHour int not null,--[Número de llamadas por hora]
	complete float not null,--[completo]
	completeByHour float not null,--[Completo por hora]
	percentComplete float not null,-- [Completo / llamadas.]
	[year] int not null,
	[month] int not null,
	[day] int not null,
	[hour] int not null,
	[minutes] int not null
	) ON [PRIMARY]
END
	'
	EXEC(@sql)

	set @process = 'Create Table -- RepDialingResultsDetail 4180'
	set @Sql= 'if not exists(select * from sys.tables where name=''RepDialingResultsDetail'')
create table RepDialingResultsDetail(
	[date] [datetime] NOT NULL,
	[telephone] [varchar](30) NOT NULL,
	[dialResultId] int NOT NULL,
	[dialResult] varchar(30) NOT NULL,
	[userId] [int] NOT NULL,
	[login] [varchar](50) NOT NULL,
	[campaignId] int NOT NULL,
	[campaign] [varchar](40) NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]'
	EXEC(@sql)

	set @process = 'create table RepOutManagementBase----'
	set @Sql= 'if not exists(select * from sys.tables where name=''RepOutManagementBase'')
	create table RepOutManagementBase(
	[date] [datetime] NOT NULL,
	[dialResultCode] [int] not null,
	[dialResultId] [int] NOT NULL,
	[dialResult] [varchar](20) NOT NULL,
	[dispositionId] [int] NOT NULL,
	[disposition] [varchar](30)NOT NULL,
	[subDispositionId] [int] NOT NULL,
	[subDisposition] [varchar](30) NOT NULL,
	[total] [int] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
)ON [PRIMARY]'

	EXEC(@sql)

	set @process = 'Create table -- ccspRepAgentCallStatusesByInterval 2070'
	set @Sql= 'if not exists (select * from sys.tables where name = ''RepAgentCallStatusesByInterval'')
CREATE TABLE [dbo].[RepAgentCallStatusesByInterval](
[date][datetime] NOT NULL,
[userId][int] NOT NULL,
[agentName][varchar](255) NOT NULL,
[startInterval][datetime] NOT NULL,
[endInterval][datetime] NOT NULL,
[readyTime][int] NOT NULL,
[twrapup][int] NOT NULL,
[tring][int] NOT NULL,
[tother][int] NOT NULL,
[tnav][int] NOT NULL,
[tCallTransf][int] NOT NULL,
[twbCall][int] NOT NULL,
[year][int] NOT NULL,
[month][int] NOT NULL,
[day][int] NOT NULL,
[hour][int] NOT NULL,
[minutes][int] NOT NULL
) ON [PRIMARY]'
	EXEC(@sql)

	set @process = 'AnsweredCallsbyDialingRetries - filtros fecha y seleccion 4190'
	set @Sql= 'IF NOT EXISTS (SELECT * FROM [ReportsFiltersMenus]	WHERE [ReportsFiltersMenus].[idReport] = 4190)
	BEGIN
		INSERT INTO [ReportsFiltersMenus] (idReport, filterMenuName) VALUES (4190, N''date'')
		INSERT INTO [ReportsFiltersMenus] (idReport, filterMenuName) VALUES (4190, N''filterby'')
	END
	'
	EXEC(@sql)

	set @process = 'RepDialingAgent - filtros fecha y seleccion 2080'
	set @Sql= 'if not exists(select * from ReportsFiltersMenus where idReport = 2080) begin
insert ReportsFiltersMenus (idReport, filterMenuName) values(2080, N''date'')
insert ReportsFiltersMenus (idReport, filterMenuName) values(2080, N''filterby'')
end'
	EXEC(@sql)


	set @process = 'RepDialingAgent - filtros fecha y seleccion 4170'
	set @Sql= 'if not exists(select * from ReportsTotals where id = 4170) begin
	insert into ReportsTotals 
	values(4170,'''')
end'
	EXEC(@sql)
	

	set @process = 'RepDialingAgent - filtro usuario -- 2080'
	set @Sql= 'if not exists(select * from ReportsFilters where id=2080) insert ReportsFilters values(''Agent Detail by Day'', ''users'', 2080)'
	EXEC(@sql)

	set @process = 'AnsweredCallsbyDialingRetries - filtros usuario campaña y resultado de marcación 4190'
	set @Sql= '	IF not EXISTS (SELECT * FROM [ReportsFilters]	WHERE [ReportsFilters].[id] = 4190)
	BEGIN
		INSERT INTO ReportsFilters VALUES(''Answered Calls by Dialing Retries'', ''campaigns'', 4190)
		INSERT INTO ReportsFilters VALUES(''Answered Calls by Dialing Retries'', ''users'', 4190)
		INSERT INTO ReportsFilters VALUES(''Answered Calls by Dialing Retries Calls by Dialing Retries'', ''dialresults'', 4190)
	END
	'
	EXEC(@sql)

	set @process = 'Agent Detail By Day - Totales 2080'
	set @Sql= 'IF not EXISTS (SELECT * FROM [ReportsTotals] WHERE [id] = 2080) INSERT INTO ReportsTotals values (2080, '''')'
	EXEC(@sql)

	set @process = 'AnsweredCallsbyDialingRetries - Totales'
	set @Sql= 'IF NOT EXISTS (SELECT * FROM [ReportsTotals]WHERE [ReportsTotals].[id] = 4190) INSERT INTO ReportsTotals values (4190, '''')'
	EXEC(@sql)

	set @process = 'AnsweredCallsbyDialingRetries - Traducciones'
	set @Sql= 'IF NOT EXISTS (SELECT * FROM [TranslatedReports] WHERE [TranslatedReports].[id] = 4190) INSERT INTO TranslatedReports VALUES(4190, ''disposition|subDisposition'')'
	EXEC(@sql)

	set @process = 'Create ReportsFiltersMenus -- 4180'
	set @Sql= 'if not exists(select * from ReportsFiltersMenus where idReport=4180)
begin
	insert into ReportsFiltersMenus(idReport,filterMenuName) values(4180,N''date'')
	insert into ReportsFiltersMenus(idReport,filterMenuName) values(4180,N''filterby'')
end'
	EXEC(@sql)

	set @process = 'Create ReportsFilters -- 4180'
	set @Sql= 'if not exists(select * from ReportsFilters where id=4180) begin
	insert into ReportsFilters(reportName,filterName,id) values(''Report detail Calling Dialing Errescuer'',''campaigns'',4180)
	insert into ReportsFilters(reportName,filterName,id) values(''Report detail Calling Dialing Errescuer'',''users'',4180)
end'
	EXEC(@sql)

	set @process = 'Create ReportsCharts -- 4180'
	set @Sql= 'if not exists(select * from ReportsCharts where id=4180) begin
	insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
	values(4180,''Report detail Calling Dialing Errescuer'',1,''campaign'','''','''','''',''sum([dialResultId])'',''Answered calls detail per Campaign'',0)
	insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
	values(4180,''Report detail Calling Dialing Errescuer'',2,''campaign'',''dialResult'','''','''','''',''Dial Results per Campaign'',0)
end'
	EXEC(@sql)

		set @process = 'Create TranslatedReports -- 4180'
	set @Sql= 'if not exists(select * from TranslatedReports where id=4180) insert into TranslatedReports (id,columns) values(4180,''login'')'
	EXEC(@sql)

	set @process = 'Create ReportsTotals -- 4180'
	set @Sql= 'if not exists(select * from ReportsTotals where id=4180) insert into ReportsTotals(id,totalColumns) values(4180,'''')'
	EXEC(@sql)

	set @process = 'Insert into ReportsFiltersMenus ---- 4170'
	set @Sql= 'if not exists(select * from ReportsFiltersMenus where idReport=4170)
	begin
		insert into ReportsFiltersMenus	values (4170,''date'')
	end'
	EXEC(@sql)

	set @process = 'insert into ReportsFilters---- 4170'
	set @Sql= 'if not exists(select * from ReportsFilters where id=4170)
	begin
		insert into ReportsFilters values(''Report Out Management Base'',''campaigns'',4170)
	end'
	EXEC(@sql)

	set @process = 'insert into ReportsCharts ---------'
	set @Sql= 'if not exists(select * from ReportsFilters where id=4170)
	begin
	insert into ReportsCharts
	values(4170,''Report Out Management Base'',1,''campaign'','''','''','''','''',''Management Base'',0)
	end'
	EXEC(@sql)

	set @process = 'insert into ReportsTotals--------'
	set @Sql= 'if not exists(select * from ReportsFilters where id=4170)
	begin
		insert into ReportsTotals
		values(4170,''sum:total'')
	end'
	EXEC(@sql)

	set @process = 'Insert ReportsFiltersMenus -- 2070'
	set @Sql= 'if not exists(select * from ReportsFiltersMenus where idReport=2070)
begin
INSERT ReportsFiltersMenus (idReport, filterMenuName) VALUES (2070, N''date'')
INSERT ReportsFiltersMenus (idReport, filterMenuName) VALUES (2070, N''filterby'')
INSERT ReportsFiltersMenus (idReport, filterMenuName) values(2070, ''groupby'')
end'
	EXEC(@sql)

	set @process = 'Insert ReportsFilters -- 2070'
	set @Sql= 'if not exists(select * from ReportsFilters where id=2070)
begin
INSERT ReportsFilters VALUES (''Agent and Call Statuses by Interval'',''users'',2070)
end'
	EXEC(@sql)

	set @process = 'Insert ReportsTotals -- 2070'
	set @Sql= 'if not exists (select * from ReportsTotals where id = 2070)
begin
INSERT INTO ReportsTotals values (2070,''sum:readyTime|sum:tring|sum:twrapup|sum:tother|sum:tnav|sum:tCallTransf|sum:twbCall'')
end'
	EXEC(@sql)

	set @process = 'Insert GroupByReports -- 2070'
	set @Sql= 'if not exists(select * from GroupByReports where id=2070)
begin
insert into GroupByReports values (
2070,
''userId|agentName|min([startInterval]):startInterval|max([endInterval]):endInterval|sum([readyTime]):readyTime|sum([twrapup]):twrapup|sum([tring]):tring|sum([tother]):tother|sum([tnav]):tnav|sum([tCallTransf]):tCallTransf|sum([twbCall]):twbCall'',''userId|agentName'')
end'
	EXEC(@sql)

	set @process = 'Insert ccSettings -- 40'
	set @Sql= 'if not exists (select * from ccSettings where setting_id = 40)
begin
INSERT ccSettings (setting_id,valor,descripcion,Status,Tipo) VALUES (40,''1|2'',''Id No disponible 1|Id No disponible 2 especificados por el cliente'',1,''RPT'')
end'
	EXEC(@sql)

	set @process = '[ccspRepDetailAgent] - Procedimiento Almacenado'
	set @Sql= 'CREATE PROCEDURE [ccspRepDetailAgent]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
declare @califout as varchar , @califin as varchar

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

		--EXEC @tresRing=ccspConfigTresRing
		EXEC @tresRing=ccspConfigTresRing
		EXEC @tresDialog=ccspConfigTresDialog
		EXEC @tresDelayIn=ccspConfigtresDelayIn

		set @dateNow=getdate()
		set @interval=15
		declare @var as varchar
		select @var= valor from ccsettings where setting_id = 39
		set @califout = SUBSTRING(@var,0,1)
		set @califin = SUBSTRING(@var,2,1)

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

		CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

		create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
		create nonclustered index ix_times2 on #times([Start] DESC)

		create table #timeDetailAgent([User_id] int null,dateStartDetail datetime null,dateEndDetail datetime null,timegroup datetime null,	timegroup_next datetime null,tunknown int null,tnot_av int null,tav int null,tprob int null,tother int null,nother int null,tmanualcall int null,tunknown2 decimal(10,3),tchatting int null)

		--Tiempo ultimo Status del agente
		create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)

		--
		CREATE TABLE #sessionTime(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL)
		CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
		CREATE TABLE #sessionTimeMayores(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)

		--TIempos del agente
		create table #tempccLogAgentesDia(row int not null,user_id int not null,TipoStatusAge_id tinyint not null,tStatus int not null,dateIni datetime not null,dateEnd datetime not null,currentStatus int)

		insert into #times
		exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

		--Sessiones del agente
		insert into #sessionTime exec ccspGenSession @from=@from,@to=@to

		select @maxLogout=max(logout) from #sessionTime

		if CONVERT(varchar(11),@maxLogout,121)=CONVERT(varchar(11),@dateNow,121) and @dateNow>@maxLogout set @dateNow=@maxLogout

		INSERT INTO #sessionTimeGroup
		select user_id,login,logout,extension
		,convert(datetime,case when datepart(mi,A.login) between 0 and 14 then convert(varchar(13),A.login,121) + '':00:00.000'' --end) AS timegroup
					when datepart(mi,A.login) between 15 and 29 then convert(varchar(13),A.login,121) + '':15:00.000''
					when datepart(mi,A.login) between 30 and 44 then convert(varchar(13),A.login,121) + '':30:00.000''
					when datepart(mi,A.login) between 45 and 59 then convert(varchar(13),A.login,121) + '':45:00.000'' end) AS timegroup
		,convert(datetime,case when datepart(mi,A.logout) between 0 and 14 then convert(varchar(13),A.logout,121) + '':15:00.000'' --end) as timegroup_next
					when datepart(mi,A.logout) between 15 and 29 then convert(varchar(13),A.logout,121) + '':30:00.000''
					when datepart(mi,A.logout) between 30 and 44 then convert(varchar(13),A.logout,121) + '':45:00.000''
					when datepart(mi,A.logout) between 45 and 59 then convert(varchar(13),dateadd(hh,1,A.logout),121) + '':00:00.000'' end) as timegroup_next
		 ,datediff(ss,login,logout)
		 from #sessionTime as A

		 INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>60
		delete #sessionTimeGroup where  datediff(mi,timegroup,timegroup_next)>15

		insert into #sessionTimeGroup
		 select [User_id],login,logout,extension, convert(varchar,th.start,121) as timegroup, convert(varchar, th.stop,121) as timegroup_next,
		 isnull((case when th.start <= login and  th.stop > login and th.start <= dateadd(ss,[tlog],login) and  th.stop > dateadd(ss,[tlog],login) then datediff(ss,login,dateadd(ss,[tlog],login))
						when th.start <= login and  th.stop > login and th.stop < dateadd(ss,[tlog],login) then datediff(ss,login,th.stop)
						when th.start > login and th.start <= dateadd(ss,[tlog],login) and  th.stop > dateadd(ss,[tlog],login) then datediff(ss,th.start,dateadd(ss,[tlog],login))
						when th.start > login and th.stop < dateadd(ss,[tlog],login) then datediff(ss,th.start,th.stop) else  0 end),0) as [tlog seg]

		from #sessionTimeMayores t
		inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		where  datediff(ss,th.start,timegroup_next)>0;

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
				dateEndDetail,
			   case when datepart(mi,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) between 0 and 14 then convert(varchar(13),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ,121) + '':00:00.000''
				when datepart(mi,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) between 15 and 29 then convert(varchar(13),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ,121) + '':15:00.000''
			   when datepart(mi,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) between 30 and 44 then convert(varchar(13),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ,121) + '':30:00.000''
			   when datepart(mi,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ) between 45 and 59 then convert(varchar(13),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ,121) + '':45:00.000'' end as timegroup
			   ,case when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ))
			   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ),121) + '':15:00.000''
			   when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ))
			   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ),121) + '':30:00.000''
			   when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ))
			   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ),121) + '':45:00.000''
			   when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ))
			   between 45 and 59 then  convert(varchar(13), dateadd(hh,1,case when cal_Xfer is null or cal_Xfer =''1900-01-01 00:00:00'' then cal_inicio else cal_Xfer end ),121) + '':00:00.000'' end as timegroup_next
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
		,C.timegroup_next=
		case when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 0 and 14 then convert(varchar(13),dateadd(ss, tiempo,B.fecha),121) + '':15:00.000'' --end
			when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 15 and 29 then convert(varchar(13),dateadd(ss, tiempo,B.fecha),121) + '':30:00.000''
			when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 30 and 44 then convert(varchar(13),dateadd(ss, tiempo,B.fecha),121) + '':45:00.000''
			when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 45 and 59 then convert(varchar(13),dateadd(hh,1,B.fecha),121) + '':00:00.000'' end
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
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl,
		t.calif_id, t.califsub_id
		from #inboundData2 t
		join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		where  datediff(ss,th.start,timegroup_next)>0
		order by cal_id

		insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto,calif_id,califSub_id)
		select * from (
		SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
			   ,case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_Inicio,121) + '':00:00.000'' --end as timegroup
					 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_Inicio,121) + '':15:00.000''
					 when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_Inicio,121) + '':30:00.000''
					 when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_Inicio,121) + '':45:00.000'' end as timegroup
			   ,case when datepart(mi,dateadd(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':15:00.000'' --end as timegroup_next
				   when datepart(mi,dateadd(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':30:00.000''
				   when datepart(mi,dateadd(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
				   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':45:00.000''
				   else  convert(varchar(13),dateadd(hh,1,dateadd(ss,isnull(sum(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio)),121) + '':00:00.000'' end as timegroup_next
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
		 ,C.timegroup_next=
		 case when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 0 and 15 then convert(varchar(13),dateadd(ss, tiempo,B.fecha),121) + '':15:00.000'' --end
			when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 15 and 29 then convert(varchar(13),dateadd(ss, tiempo,B.fecha),121) + '':30:00.000''
			when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 30 and 44 then convert(varchar(13),dateadd(ss, tiempo,B.fecha),121) + '':45:00.000''
			when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 45 and 59 then convert(varchar(13),dateadd(hh,1,B.fecha),121) + '':00:00.000'' end
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
		,phone_out,cal_id,cal_puerto
		,calif_id,califSub_id
		from #outboundData2 t
		inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		where  datediff(ss,th.start,timegroup_next)>0

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
		,convert(datetime,case when datepart(mi,A.dateIni) between 0 and 14 then convert(varchar(13),A.dateIni,121) + '':00:00.000'' --end) AS timegroup
				when datepart(mi,A.dateIni) between 15 and 29 then convert(varchar(13),A.dateIni,121) + '':15:00.000''
				when datepart(mi,A.dateIni) between 30 and 44 then convert(varchar(13),A.dateIni,121) + '':30:00.000''
				when datepart(mi,A.dateIni) between 45 and 59 then convert(varchar(13),A.dateIni,121) + '':45:00.000'' end) AS timegroup
		,convert(datetime,case when datepart(mi,A.dateEnd) between 0 and 14 then convert(varchar(13),A.dateEnd,121) + '':15:00.000'' --end) as timegroup_next,
				when datepart(mi,A.dateEnd) between 15 and 29 then convert(varchar(13),A.dateEnd,121) + '':30:00.000''
				when datepart(mi,A.dateEnd) between 30 and 44 then convert(varchar(13),A.dateEnd,121) + '':45:00.000''
				when datepart(mi,A.dateEnd) between 45 and 59 then convert(varchar(13),dateadd(hh,1,A.dateEnd),121) + '':00:00.000'' end) as timegroup_next,
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
			@dateNow as dateEndDetail,
			case when datepart(mi,B.fecha) between 0 and 14 then convert(varchar(13),B.fecha,121) + '':00:00.000'' --end as timegroup
				when datepart(mi,B.fecha) between 15 and 29 then convert(varchar(13),B.fecha,121) + '':15:00.000''
				when datepart(mi,B.fecha) between 30 and 44 then convert(varchar(13),B.fecha,121) + '':30:00.000''
				when datepart(mi,B.fecha) between 45 and 59 then convert(varchar(13),B.fecha,121) + '':45:00.000'' end as timegroup
			,case when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 0 and 14 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':15:00.000'' --end as timegroup_next
				when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 15 and 29 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':30:00.000''
				when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 30 and 44 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':45:00.000''
				when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 45 and 59 then  convert(varchar(13),dateadd(hh,1,B.fecha),121) + '':00:00.000'' end as timegroup_next
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
		,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))
					when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
					when th.start > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tunknown,dateStartDetail))
					when th.start > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tunknown
		,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))
					when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
					when th.start > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnot_av,dateStartDetail))
					when th.start > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tnot_av
		,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
					when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
					when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
					when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
		,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tprob,dateStartDetail))
					when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
					when th.start > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tprob,dateStartDetail))
					when th.start > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tprob
		,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
					when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
					when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
					when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
		,isnull((case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
		,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tmanualCall,dateStartDetail))
					when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
					when th.start > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tmanualCall,dateStartDetail))
					when th.start > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tmanualCall
		,case when th.start > dateStartDetail and th.stop > dateEndDetail then tunknown2 else 0 end as tunknown2
		,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tchatting,dateStartDetail) and  th.stop > dateadd(ss,tchatting,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tchatting,dateStartDetail))
					when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tchatting,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
					when th.start > dateStartDetail and th.start <= dateadd(ss,tchatting,dateStartDetail) and  th.stop > dateadd(ss,tchatting,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tchatting,dateStartDetail))
					when th.start > dateStartDetail and th.stop < dateadd(ss,tchatting,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tchatting
		from #timeDetailAgent2 t
		inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
		where  datediff(ss,th.start,timegroup_next)>0

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
		,C.completeOut, D.completeIn
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
		(select user_id,timegroup,sum(txfer) as txfer,sum(tring) tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl,sum(ntotal) as ntotal from #inboundData group by user_id,timegroup) B
		on xTimeDetail.timegroup=B.timegroup and xTimeDetail.User_id=B.User_id
		left join
		--(select user_id,timegroup,sum(txfer) as txfer,sum(tring) tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl,sum(ntotal) as ntotal from #outboundData group by user_id,timegroup) C
		(
		select user_id,timegroup,sum(txfer) as txfer,sum(tring) tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl,sum(ntotal) as ntotal
		,count(case when isnull(A.califSub_id, 0) = @califout then isnull(B.calif_id,0) else isnull(C.califSub_id, 0) end) as completeOut
		from #outboundData A
		left join cctipocalifout B on A.calif_id=B.calif_id --and B.contactOwner=1
		left join cctipocalifsubout C on A.califSub_id=C.califSub_id --and C.contactOwner=1
		group by user_id,timegroup
		) C
		on xTimeDetail.timegroup=C.timegroup and xTimeDetail.User_id=C.User_id
		left join
		(
			select user_id,timegroup,sum(txfer) as txfer,sum(tring) tring,sum(tdialog) as tdialog,sum(tnotes) as tnotes,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl,sum(ntotal) as ntotal
			,count(case when isnull(A.califSub_id, 0) = @califin then isnull(B.calif_id,0) else isnull(C.califSub_id, 0) end) as completeIn
			from #outboundData A
			left join cctipocalif B on A.calif_id=B.calif_id --and B.contactOwner=1
			left join cctipocalifsub C on A.califSub_id=C.califSub_id --and C.contactOwner=1
			group by user_id,timegroup
		) D
		on xTimeDetail.timegroup=D.timegroup and xTimeDetail.User_id=D.User_id

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

		--select * from #timeDetailAgent2
		--select * from #agentInformation

		--truncate table RepDetailAgent
			delete from RepDetailAgent where date>=@from and date<@to

			insert into RepDetailAgent
			select
			A.User_id,
			min(B.Login) as ''usuario'',
			min((B.Nombres + space(1) + b.ApellidoPaterno + space(1) + b.ApellidoMaterno)) ''NombreAgente'',
			convert(varchar(14),A.timegroup,120)+''00:00'' as [fecha],
			sum(A.tlog) ''Tiempo de sesion'',
			sum(a.tlog - tnotes) as [Tiempo de operacion] -- tlog - tiempoAuxiliares
			,sum(txfer+tring+tdialog+tnotes) as [Tiempo en dialogo]
			--,sum(tav) [Tiempo en disponible]
			,sum(txfer+tring) as [Tiempo en espera]
			,sum(tnot_av) as [Tiempo en no disponibles]
			,sum(cast((convert(float,tdialog)/36) as decimal(18,4))) as [% en dialogo]
			,sum(cast((convert(float,txfer+tring)/36) as decimal(18,4))) as [% en espera]
			,sum(cast((convert(float,tav)/36) as decimal(18,4))) as [% en disponible]
			,sum(cast(convert(float,(a.tlog - tnotes))/convert(float,A.tlog) as decimal(18,4))) as [Adherencia]
			,sum(ntotal) as [Número de llamadas]
			,sum(cast(convert(float,ntotal)/7 as decimal(18,4)))  as [Número de llamadas por hora]
			,sum(isnull(completeOut + completeIn, 0)) as [Completo]
			,sum(isnull(completeOut + completeIn, 0)) as [Completo por hora]
			,isnull(sum(isnull(completeOut + completeIn, 0)/nullif(ntotal,0)),0) as [Completo / llamadas.]
			,datepart(YYYY,min(A.timegroup)) [year]
			,datepart(MM,min(A.timegroup)) [month]
			,datepart(DD,min(A.timegroup)) [day]
			,datepart(HH,min(A.timegroup)) [hour]
			,datepart(mm,min(A.timegroup)) [minutes]
			from #agentInformation A
			inner join ccUsers B on A.User_id=B.User_id
			group by convert(varchar(14),A.timegroup,120)+''00:00'', A.User_id

		---DROP TABLES TEMP
		drop table #sessionTime
		drop table #times
		drop table #inboundData
		drop table #inboundData2
		drop table #outboundData
		drop table #outboundData2
		drop table #timeDetailAgent
		drop table #timeDetailAgent2
		drop table #agentInformation
		--drop table #tempRepAgentGI

		drop table #tempAgentLastStatus
		drop table #tempccLogAgentesDia
		drop table #tempccLogAgentesDia2
		drop table #sessionTimeGroup
		drop table #sessionTimeMayores;
	end
END'
	EXEC(@sql)


	set @process = 'AnsweredCallsbyDialingRetries - Procedimiento Almacenado'
	set @Sql= 'CREATE PROCEDURE [ccspRepAnsweredCallsByDialingRetries]
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
	C.cal_intentos as [tries], -- añadir a aspx
	A.cam_id as [campaignId],
	E.cam_descripcion as [campaign],
	A.User_id as [userId],
	D.Nombres + '' '' + D.ApellidoPaterno + '' '' + D.ApellidoMaterno as [agentName],
	(select top 1 Extension from ccLogLogin where user_id=A.User_id and tipoMov=1 and fecha<A.cal_inicio order by fecha desc) as [extension],
	convert(varchar(12),A.cal_Inicio,108) as [startHour], -- añadir a aspx
	convert(varchar(12),dateadd(ss,A.cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,A.cal_Inicio),108) as [endHour], -- añadir a aspx
	cal_tDialog as [dialogTime],
	isnull(A.calif_id,0) as [dispositionId],
	isnull(A.califSub_id,0) as [subDispositionId],
	isnull(disp.Description,''systemTranslated_Dispositionless'') as [disposition],
	isnull(subDisp.califSubDesc,''systemTranslated_NoSubDisposition'') as [subDisposition],
	A.cal_tNotas as [wrapup],
	datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) AS [year],
	datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [month],
	datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [day],
	datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [hour],
	datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [minutes]

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
END	'
	EXEC(@sql)

	set @process = 'Create SP -- ccspRepDialingResultsDetail 4180'
	set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepDialingResultsDetail]
@action as tinyint,
@from as datetime=null,
@to as datetime=null
AS

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
dial.cam_id as campaignId,camp.cam_descripcion as campaign
,datepart(yyyy,dial.fecha) as [year]
,datepart(mm,dial.fecha) as [month]
,datepart(dd,dial.fecha) as [day]
,datepart(hh,dial.fecha) as [hour]
,datepart(mi,dial.fecha) as [minute]
FROM ccoLogDials dial
left join ccocallsout co on  dial.callout_id = co.callout_id and dial.Telefono=co.cal_telefono
left join cctipoResultadoDial tr ON dial.tiporesdial_id=tr.tiporesdial_id
left join ccUsers u on u.user_id =co.User_id
left join ccCamps camp on camp.cam_id=dial.cam_id
where dial.fecha>=@from and dial.fecha<@to


end'
	EXEC(@sql)


	set @process = 'Create SP -- ccspRepOutManagementBase 4170'
	set @Sql= 'CREATE PROCEDURE[dbo].[ccspRepOutManagementBase]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
	delete from RepOutManagementBase with(rowlock)
	where [date] >= @from AND [date] < @to

insert into RepOutManagementBase
select  CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121) as fecha,
	cout.callout_id,isnull(resdial.tipoResDial_id,0) as dialResultId,resdial.descripcion as ResultadoMarcacion, --,cout.callout_id as llamada ,
	isnull(tipocal.calif_id,0)as dispositionId,ISNULL( tipocal.Description,'''') as Calificacion,isnull(tiposubcal.califSub_id,0) as dispositionId,
	isnull(tiposubcal.califSubDesc,'''') as SubCalificacion,SUM(cout.cal_manual) as total,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) AS [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [month],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [minutes]
from ccoCallsOut cout
	left join ccoLogDials logdial on cout.callout_id = logdial.callout_id
	left join cctipoResultadodial resdial on logdial.tipoResDial_id = logdial.tipoResDial_id
	left join cctipocalif tipocal on cout.calif_id = tipocal.calif_id
	left join cctipocalifsub tiposubcal on cout.califSub_id = tiposubcal.califSub_id
where fecha >= @from and fecha < @to
group by cout.callout_id,resdial.tipoResDial_id,resdial.descripcion,
tipocal.Description,tiposubcal.califSubDesc,cout.cal_manual,fecha,tipocal.calif_id,tiposubcal.califSub_id

end '
	EXEC(@sql)

	set @process = 'Create SP -- ccspRepAgentCallStatusesByInterval 2070'
	set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepAgentCallStatusesByInterval]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

BEGIN
SET NOCOUNT ON

if @from is null
	select @from = CONVERT(datetime, convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1 begin

	declare @interval int
	declare @dateNow datetime,@maxLogout datetime
	DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
	declare @valuenav varchar(100)
	declare @tnav int, @twbCall int
	SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)

	select @valuenav = valor from ccSettings where setting_id = 40

	select @tnav = Value from dbo.fn_RIASplitDelimited(@valuenav,''|'') where Id = 1
	select @twbCall = Value from dbo.fn_RIASplitDelimited(@valuenav,''|'') where Id = 2

	create table #outboundData(row int identity, [User_id] int, cal_id int,
	dateStartDetail datetime, dateEndDetail datetime,
	timegroup datetime, timegroup_next datetime,
	tque int, txfer int, tring int, tdialog int, tnotes int,
	time_endque datetime, time_ring datetime, time_dialog datetime, time_notes datetime, time_end_call datetime)

	create nonclustered index iX_CamUserId on #outboundData([User_id] DESC)

	CREATE TABLE #times([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

	--Tiempos del agente
	create table #tempccLogAgentesDia(row int not null,user_id int not null,TipoStatusAge_id tinyint not null,tStatus int not null,
	dateIni datetime not null,dateEnd datetime not null,currentStatus int)

	create table #timeDetailAgent([User_id] int null, dateStartDetail datetime null, dateEndDetail datetime null,
	timegroup datetime null, timegroup_next datetime null,
	tav int null, tother int null,  tunknown2 decimal(10,3))

	--Tiempo ultimo Status del agente
	create table #tempAgentLastStatus(id int,fecha datetime,tiempo int)

	create nonclustered index ix_timesNotReady on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_timesNotReady2 on #times([Start] DESC)

	--Tiempos del agente en not ready
	create table #tempccLogAgentesNotReadyDay (row int not null, user_id int not null, TipoNotReady_id tinyint not null, tStatus int not null,
	dateStart datetime null, dateEnd datetime null)

	create table #tempNotReady (user_id int not null,
	dateStartDetail datetime null, dateEndDetail datetime null,
	timegroup datetime null, timegroup_next datetime null, tnav int null, twbcall int null)

	--Tiempo en transferencia estado en llamada
	create nonclustered index ix_timesCallTransf on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_timesCallTransf2 on #times([Start] DESC)

	create table #tempccLogtransfers (user_id int not null, cal_id int,
	dateStartTransf datetime null, dateEndTransf datetime null,
	timegroup datetime null, timegroup_next datetime null, tcallTransf int not null )

	set @dateNow=getdate()
	set @interval=15

	insert into #times
	exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

	-- Columnas Hora intervalo inicio = dateStartDetail, Hora intervalo fin = dateEndDetail, Tiempo en timbrando = tring, Tiempo de notas (acw) = tnotes
	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cal_id,User_id,tque,txfer,tring,tdialog,tnotes,time_endque,time_ring,time_dialog,time_notes,time_end_call)
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		   ,case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_Inicio,121) + '':00:00.000''
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_Inicio,121) + '':15:00.000''
		   when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_Inicio,121) + '':30:00.000''
		   when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_Inicio,121) + '':45:00.000'' end as timegroup
		   ,case when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':15:00.000''
		   when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':30:00.000''
		   when datepart(mi,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':45:00.000''
		   else  convert(varchar(13),dateadd(hh,1,dateadd(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio)),121) + '':00:00.000'' end as timegroup_next
		   ,cal_id
		   , [User_id]
		   ,ISNULL((cal_twait),0) as tque
		   ,ISNULL((cal_txfer),0)AS txfer
		   ,isnull((cal_tring),0) as tring
		   ,isnull((cal_tdialog),0) as tdialog
		   ,isnull((cal_tnotas),0) as tnotes
		  ,DATEADD(ss,isnull((0),0),cal_inicio) as time_endque
		   ,DATEADD(ss,isnull((0 + cal_txfer),0),cal_inicio) as time_ring
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		   ,DATEADD(ss,isnull((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		   FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
		   WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to

	 update C
	 set C.dateEndDetail=@dateNow
	 ,C.timegroup_next=
	 case when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 0 and 14 then convert(varchar(13),dateadd(ss, tiempo,B.fecha),121) + '':15:00.000''
	 	when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 15 and 29 then convert(varchar(13),dateadd(ss, tiempo,B.fecha),121) + '':30:00.000''
	 	when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 30 and 44 then convert(varchar(13),dateadd(ss, tiempo,B.fecha),121) + '':45:00.000''
	 	when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 45 and 59 then convert(varchar(13),dateadd(hh,1,B.fecha),121) + '':00:00.000'' end
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

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tque,txfer,tring,tdialog,tnotes,time_endque,time_ring,time_dialog,time_notes,time_end_call,cal_id)
	select
	dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
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
	,time_endque,time_ring,time_dialog,time_notes,time_end_call,cal_id
	from #outboundData2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------------------------------

	--Columnas Tiempo disponible = tav, Tiempo en otro = tother
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
	select A.user_id, A.dateIni, A.dateEnd
	,convert(datetime,case when datepart(mi,A.dateIni) between 0 and 14 then convert(varchar(13),A.dateIni,121) + '':00:00.000''
			when datepart(mi,A.dateIni) between 15 and 29 then convert(varchar(13),A.dateIni,121) + '':15:00.000''
			when datepart(mi,A.dateIni) between 30 and 44 then convert(varchar(13),A.dateIni,121) + '':30:00.000''
			when datepart(mi,A.dateIni) between 45 and 59 then convert(varchar(13),A.dateIni,121) + '':45:00.000'' end) AS timegroup
	,convert(datetime,case when datepart(mi,A.dateEnd) between 0 and 14 then convert(varchar(13),A.dateEnd,121) + '':15:00.000''
			when datepart(mi,A.dateEnd) between 15 and 29 then convert(varchar(13),A.dateEnd,121) + '':30:00.000''
			when datepart(mi,A.dateEnd) between 30 and 44 then convert(varchar(13),A.dateEnd,121) + '':45:00.000''
			when datepart(mi,A.dateEnd) between 45 and 59 then convert(varchar(13),dateadd(hh,1,A.dateEnd),121) + '':00:00.000'' end) as timegroup_next,
	case when A.tipostatusage_id=3 then A.tStatus else 0 end tav,
	case when A.tipostatusage_id=7 then A.tStatus else 0 end tother,
	case when abs(isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) )>A.tStatus then 0
	when A.currentStatus in(0,-1,-2) then 0 --Logout
	when S.TipoStatusAge_id=1 then 0
	else isnull( 1.0*DATEDIFF(ms,A.dateEnd,S.dateIni)/1000  ,0) end	as tunknown2
	from #tempccLogAgentesDia2 A
	left join #tempccLogAgentesDia2 S on A.Row=S.Row-1 and A.user_id=S.user_id
	WHERE  A.dateIni>=@from AND A.dateIni<@to and A.TipoStatusAge_id<>0

	update #timeDetailAgent set tunknown2=0  where abs(tunknown2)>2.7

	 insert into #timeDetailAgent(User_id,dateStartDetail,dateEndDetail,timegroup,timegroup_next,tav,tother,tunknown2)
	 select
	 	User_id,
	 	B.fecha as dateStartDetail,
	 	@dateNow as dateEndDetail,
	 	case when datepart(mi,B.fecha) between 0 and 14 then convert(varchar(13),B.fecha,121) + '':00:00.000''
	 		when datepart(mi,B.fecha) between 15 and 29 then convert(varchar(13),B.fecha,121) + '':15:00.000''
	 		when datepart(mi,B.fecha) between 30 and 44 then convert(varchar(13),B.fecha,121) + '':30:00.000''
	 		when datepart(mi,B.fecha) between 45 and 59 then convert(varchar(13),B.fecha,121) + '':45:00.000'' end as timegroup
	 	,case when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 0 and 14 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':15:00.000''
	 		when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 15 and 29 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':30:00.000''
	 		when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 30 and 44 then convert(varchar(13),dateadd(ss,tiempo ,B.fecha),121) + '':45:00.000''
	 		when datepart(mi,dateadd(ss,tiempo,B.fecha)) between 45 and 59 then  convert(varchar(13),dateadd(hh,1,B.fecha),121) + '':00:00.000'' end as timegroup_next
	 	,case when tipostatusage_id=1 then tiempo when currentStatus = 3 then tiempo else 0 end as tav,
	 	0,0 as tunknown2
	 	from ccLogAgentesDia A
	 	inner JOIN #tempAgentLastStatus B ON A.fecha=B.fecha and A.User_id = B.id
		where A.currentStatus not in(-2,-1,0)

	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15
	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tav,tother,tunknown2)
	select
	dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tunknown2 else 0 end as tunknown2
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------

	--Columnas Tiempo en capacitación (ND) = tnav, Tiempo en “trabajo previo a llamada” = twbcall
	insert into #tempccLogAgentesNotReadyDay(row,[User_id],TipoNotReady_id,tStatus,dateStart,dateEnd)
	select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY DATEADD(ss,-tStatus,fecha)) AS Row,User_id,
	TipoNotReady_id,tStatus,DATEADD(ss,-tStatus,fecha)as dateStart, fecha as dateEnd
	from cclogagentesnotready
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to and TipoNotReady_id in (@tnav,@twbCall)

	insert into #tempNotReady (user_id,dateStartDetail,dateEndDetail, timegroup, timegroup_next, tnav, twbcall)
	select user_id,dateStart,dateEnd
	,convert(datetime,case when datepart(mi,A.dateStart) between 0 and 14 then convert(varchar(13),A.dateStart,121) + '':00:00.000''
			when datepart(mi,A.dateStart) between 15 and 29 then convert(varchar(13),A.dateStart,121) + '':15:00.000''
			when datepart(mi,A.dateStart) between 30 and 44 then convert(varchar(13),A.dateStart,121) + '':30:00.000''
			when datepart(mi,A.dateStart) between 45 and 59 then convert(varchar(13),A.dateStart,121) + '':45:00.000'' end) AS timegroup
	,convert(datetime,case when datepart(mi,A.dateEnd) between 0 and 14 then convert(varchar(13),A.dateEnd,121) + '':15:00.000''
			when datepart(mi,A.dateEnd) between 15 and 29 then convert(varchar(13),A.dateEnd,121) + '':30:00.000''
			when datepart(mi,A.dateEnd) between 30 and 44 then convert(varchar(13),A.dateEnd,121) + '':45:00.000''
			when datepart(mi,A.dateEnd) between 45 and 59 then convert(varchar(13),dateadd(hh,1,A.dateEnd),121) + '':00:00.000'' end) as timegroup_next,
	case when A.TipoNotReady_id=@tnav then A.tStatus else 0 end tnav,
	case when A.TipoNotReady_id=@twbCall then A.tStatus else 0 end twbcall
	from #tempccLogAgentesNotReadyDay A
	where  A.dateStart>=@from AND A.dateStart<@to and A.TipoNotReady_id in (@tnav,@twbCall)

	select * into #tempNotReady2 from #tempNotReady where datediff(mi,timegroup,timegroup_next)>15
	delete #tempNotReady where datediff(mi,timegroup,timegroup_next) > 15

	insert into #tempNotReady (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tnav,twbcall)
	select dateStartDetail,dateEndDetail,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnav,dateStartDetail) and  th.stop > dateadd(ss,tnav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnav,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,tnav,dateStartDetail) and  th.stop > dateadd(ss,tnav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnav,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,tnav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	,isnull((case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,twbcall,dateStartDetail) and  th.stop > dateadd(ss,twbcall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,twbcall,dateStartDetail))
				when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,twbcall,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
				when th.start > dateStartDetail and th.start <= dateadd(ss,twbcall,dateStartDetail) and  th.stop > dateadd(ss,twbcall,dateStartDetail) then datediff(ss,th.start,dateadd(ss,twbcall,dateStartDetail))
				when th.start > dateStartDetail and th.stop < dateadd(ss,twbcall,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	from #tempNotReady2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	--------------------------------------------------------------------------------------------

	--Columnas Tiempo en “Transferencia estando en llamada” = tcallTransf
	insert into #tempccLogtransfers (user_id, cal_id, dateStartTransf, dateEndTransf, timegroup, timegroup_next, tcallTransf)
	select A.[User_id],A.cal_id, A.dateStartDetail, A.dateEndDetail
	,convert(datetime,case when datepart(mi,A.dateStartDetail) between 0 and 14 then convert(varchar(13),A.dateStartDetail,121) + '':00:00.000''
			when datepart(mi,A.dateStartDetail) between 15 and 29 then convert(varchar(13),A.dateStartDetail,121) + '':15:00.000''
			when datepart(mi,A.dateStartDetail) between 30 and 44 then convert(varchar(13),A.dateStartDetail,121) + '':30:00.000''
			when datepart(mi,A.dateStartDetail) between 45 and 59 then convert(varchar(13),A.dateStartDetail,121) + '':45:00.000'' end) AS timegroup
	,convert(datetime,case when datepart(mi,A.dateEndDetail) between 0 and 14 then convert(varchar(13),A.dateEndDetail,121) + '':15:00.000''
			when datepart(mi,A.dateEndDetail) between 15 and 29 then convert(varchar(13),A.dateEndDetail,121) + '':30:00.000''
			when datepart(mi,A.dateEndDetail) between 30 and 44 then convert(varchar(13),A.dateEndDetail,121) + '':45:00.000''
			when datepart(mi,A.dateEndDetail) between 45 and 59 then convert(varchar(13),dateadd(hh,1,A.dateEndDetail),121) + '':00:00.000'' end) as timegroup_next
	,isnull((0 + B.tAntesXfer + B.tDespuesXfer),0) as tcallTransf
	from #outboundData A
	left join ccLogtransfers B on A.cal_id=B.cal_id and Tipo=2 and modo <> 6
	where  A.dateStartDetail>=@from AND A.dateEndDetail<@to

	select * into #tempccLogtransfers2 from #tempccLogtransfers where datediff(mi,timegroup,timegroup_next)>15
	delete #tempccLogtransfers where datediff(mi,timegroup,timegroup_next) > 15
	--
	insert into #tempccLogtransfers (dateStartTransf,dateEndTransf,timegroup,timegroup_next,User_id,tcallTransf)
	select dateStartTransf,dateEndTransf,th.start as timegroup,th.stop as timegroup_next,[User_id]
	,isnull((case when th.start <= dateStartTransf and  th.stop > dateStartTransf and th.start <= dateadd(ss,tcallTransf,dateStartTransf) and  th.stop > dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,dateStartTransf,dateadd(ss,tcallTransf,dateStartTransf))
				when th.start <= dateStartTransf and  th.stop > dateStartTransf and th.stop < dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,dateStartTransf,th.stop)
				when th.start > dateStartTransf and th.start <= dateadd(ss,tcallTransf,dateStartTransf) and  th.stop > dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,th.start,dateadd(ss,tcallTransf,dateStartTransf))
				when th.start > dateStartTransf and th.stop < dateadd(ss,tcallTransf,dateStartTransf) then datediff(ss,th.start,th.stop) else  0 end),0) as tcallTransf
	from #tempccLogtransfers2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

	-----------------------------------------------------------------------------------------------------------------------------------
	delete RepAgentCallStatusesByInterval with(rowlock) where date >= @from AND date < @to

	insert into RepAgentCallStatusesByInterval
	select
		case when O.timegroup is not null then O.timegroup when Agent.timegroup is not null then Agent.timegroup else nReady.timegroup end as [date],
		case when U.user_id is not null then U.user_id when Agent.User_id is not null then Agent.User_id else nReady.user_id end as [userId],
		U.login as [agentName],
		case when O.timegroup is not null then O.timegroup when Agent.timegroup is not null then Agent.timegroup else nReady.timegroup end as [startInterval],
		case when O.timegroup_next is not null then O.timegroup_next when Agent.timegroup_next is not null then Agent.timegroup_next else nReady.timegroup_next end as [endInterval],
		case when Agent.tav is not null then Agent.tav else 0 end as [readyTime],
		case when O.tnotes is not null then O.tnotes else 0 end as [twrapup],
		case when O.tring is not null then O.tring else 0 end as [tring],
		case when Agent.tother is not null then Agent.tother else 0 end as [tother],
		case when nReady.tnav is not null then nReady.tnav else 0 end as [tnav],
		case when O.tcallTransf is not null then O.tcallTransf else 0 end as [tCallTransf],
		case when nReady.twbcall is not null then nReady.twbcall else 0 end as [twbCall],
		datepart(yyyy,O.timegroup) as [year], datepart(mm,O.timegroup)  as [month], datepart(dd,O.timegroup)  as [day],
		datepart(hh,O.timegroup) as [hour], datepart(mi,O.timegroup)  as [minutes]
		from
			(select O.timegroup, O.timegroup_next, O.User_id, sum(tnotes) as tnotes, sum(tring) as tring
			,isnull(sum(tcallTransf),0) as tcallTransf
			from #outboundData O
			left join #tempccLogtransfers L on O.cal_id=L.cal_id
			group by O.timegroup,O.timegroup_next, O.User_id) O
		full join
			(select timegroup,timegroup_next,User_id,sum(tav) as tav,sum(tother) as tother from #timeDetailAgent
			group by timegroup,timegroup_next,User_id)
		Agent on O.timegroup=Agent.timegroup and O.User_id=Agent.User_id
		full join
			(select timegroup, timegroup_next,user_id, sum(tnav) as tnav,sum(twbcall) as twbcall from #tempNotReady
			group by timegroup, timegroup_next,user_id)
		nReady on nReady.timegroup=O.timegroup and O.User_id=nReady.User_id
		left join ccUsers U on O.User_id = U.User_id or Agent.User_id=U.User_id or nReady.User_id=U.User_id
		where  O.timegroup>=@from AND O.timegroup_next<@to


	---DROP TABLES TEMP
	drop table #tempccLogAgentesDia
	drop table #tempccLogAgentesDia2
	drop table #times
	drop table #timeDetailAgent
	drop table #timeDetailAgent2
	drop table #tempAgentLastStatus
	drop table #outboundData
	drop table #tempccLogAgentesNotReadyDay
	drop table #tempNotReady
	drop table #tempNotReady2
	drop table #outboundData2
	drop table #tempccLogtransfers
	drop table #tempccLogtransfers2
	end
end'
	EXEC(@sql)

	set @process = 'Create Index -- RepDialingResultsDetail.IX_RepDialingResultsDetail 4180'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_RepDialingResultsDetail'' and object_id = OBJECT_ID(N''RepDialingResultsDetail''))
    begin
        CREATE NONCLUSTERED INDEX [IX_RepDialingResultsDetail] ON [dbo].[RepDialingResultsDetail]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
    end'
	EXEC(@sql)

	set @process = 'Create Index -- RepAgentCallStatusesByInterval.IX_RepAgentCallStatusesByInterval 2070'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_RepAgentCallStatusesByInterval'' and object_id = OBJECT_ID(N''RepAgentCallStatusesByInterval''))
    begin
        CREATE NONCLUSTERED INDEX [IX_RepAgentCallStatusesByInterval] ON [dbo].[RepAgentCallStatusesByInterval]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
    end'
	EXEC(@sql)

	set @process = 'Create Index -- RepDetailAgent.IX_RepDetailAgent 2080'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_RepDetailAgent'' and object_id = OBJECT_ID(N''RepDetailAgent''))
    begin
        CREATE NONCLUSTERED INDEX [IX_RepDetailAgent] ON [dbo].[RepDetailAgent]
		(
			[date] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
			end'
	EXEC(@sql)

	set @process = 'Create Index -- RepAnsweredCallsByDialingRetries.IX_RepAnsweredCallsByDialingRetries 4190'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_RepAnsweredCallsByDialingRetries'' and object_id = OBJECT_ID(N''RepAnsweredCallsByDialingRetries''))
    begin
        CREATE NONCLUSTERED INDEX [IX_RepAnsweredCallsByDialingRetries] ON [dbo].[RepAnsweredCallsByDialingRetries]
		(
			[date] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
			end'
	EXEC(@sql)

	set @process = 'Create Index -- RepOutManagementBase.IX_RepOutManagementBase 4170'
	set @Sql= ' if not exists (select * from sys.indexes where name = N''IX_RepOutManagementBase'' and object_id = OBJECT_ID(N''RepOutManagementBase''))
	begin
	CREATE NONCLUSTERED INDEX [IX_RepOutManagementBase] ON [dbo].RepOutManagementBase
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
    end '
	EXEC(@sql)



	set @process = ''
	set @Sql= ''
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