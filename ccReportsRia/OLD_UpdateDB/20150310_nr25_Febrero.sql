/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jose Velasco. Jesus Gallardo
Date: 2015/03/10
Description:

	Crear tabla RepSpececialAbndPercentage
	Crear tabla RepSpececialAbndProfiles
	Crear tabla RepSpececialAbndTimes
	Crear tabla RepMKTAgentes

	Se borran los filtros ReportsFilters
    Inserta los viejos filtros ReportsFilters
	Inserta los viejos filtros ReportsFilters

	Inserta nuevos reportes ReportsTotals

	CREATE index -- RepMKTAgentes
	CREATE index -- RepSpececialAbndProfiles
	CREATE index -- RepSpececialAbndPercentage
	CREATE index -- RepSpececialAbndPercentage

	Update in -- PivotReports

	create SP -- ccspRepSpececialAbndPercentage
	CREATE SP -- ccspRepSpececialAbndProfiles
	CREATE SP -- ccspRepSpececialAbndTimes
	CREATE SP -- ccspRepMKTAgentes

	Alter SP -- ccspRepAgentNotReady
	Alter SP -- GetReportMenus
	Alter SP -- ccspRepAgentGI
	Alter SP -- GetReportFiltersMenus
Database: ccReportsRia
Required version: 24

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 25

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version-1
	begin
		begin tran
		begin try

		/* Start script release */

		set @process = 'create table -- RepSpececialAbndPercentage'
		set @sql='if not exists (select * from sys.tables where name = N''RepSpececialAbndPercentage'')
	begin
CREATE TABLE [dbo].[RepSpececialAbndPercentage](
	[date] [datetime] NOT NULL,
	[inboundId] [int] NOT NULL,
	[inbound] [varchar](255) NOT NULL,
	[5] smallint not null,
	[10] smallint not null,
	[15] smallint not null,
	[20] smallint not null,
	[25] smallint not null,
	[30] smallint not null,
	[40] smallint not null,
	[50] smallint not null,
	[60] smallint not null,
	[gt60] smallint not null,
) ON [PRIMARY]
end'
		EXEC(@sql)


		set @process = 'create table -- RepSpececialAbndProfiles'
		set @sql='if not exists (select * from sys.tables where name = N''RepSpececialAbndProfiles'')
	begin
CREATE TABLE [dbo].[RepSpececialAbndProfiles](
	[date] [datetime] NOT NULL,
	[inboundId] [int] NOT NULL,
	[inbound] [varchar](255) NOT NULL,
	[5] smallint not null,
	[10] smallint not null,
	[15] smallint not null,
	[20] smallint not null,
	[25] smallint not null,
	[30] smallint not null,
	[40] smallint not null,
	[50] smallint not null,
	[60] smallint not null,
	[gt60] smallint not null,
	[total] smallint not null,
) ON [PRIMARY]
end'
		EXEC(@sql)


		set @process = 'create table -- RepSpececialAbndTimes'
		set @sql='if not exists (select * from sys.tables where name = N''RepSpececialAbndTimes'') begin
		CREATE TABLE [dbo].[RepSpececialAbndTimes](
	[date] [datetime] NOT NULL,
	[inboundId] [int] NOT NULL,
	[inbound] [varchar](255) NOT NULL,
	[5] smallint not null,
	[10] smallint not null,
	[15] smallint not null,
	[20] smallint not null,
	[25] smallint not null,
	[30] smallint not null,
	[40] smallint not null,
	[50] smallint not null,
	[60] smallint not null,
	[gt60] smallint not null,
) ON [PRIMARY]
end'
		EXEC(@sql)


		set @process = 'create table -- RepMKTAgentes'
		set @sql='if not exists (select * from sys.tables where name = N''RepMKTAgentes'') begin
CREATE TABLE [dbo].[RepMKTAgentes](
	[date] [varchar](255) NOT NULL,
	[userId] [varchar](255) NOT NULL,
	[login] [varchar](255) NOT NULL,
	[agentName] [varchar](25) NOT NULL,
	[CallsperACDGroupD] [int] NOT NULL,
	[tACD] [int] NOT NULL,
	[tAgent] [int] NOT NULL,
	[oHour] [int] NOT NULL,
	[tAux] [int] NOT NULL,
	[readyTime] [int] NOT NULL,
	[tPer] [int] NOT NULL,
	[Ayuda] [int] NOT NULL,
	[nxfer] [int] NOT NULL,
	[nacw] [int] NOT NULL,
	[tACW] [int] NOT NULL,
	[year] [varchar](255) NOT NULL,
	[month] [varchar](255) NOT NULL,
	[day] [varchar](255) NOT NULL,
	[hour] [varchar](255) NOT NULL,
	[minutes] [varchar](255) NOT NULL
) ON [PRIMARY]
end'
		EXEC(@sql)


		set @process = 'delete relation ReportsFilters'
		set @sql=' Delete from ReportsFilters'
		EXEC(@sql)


		set @process = 'Insert values in ReportsFilters'
		set @sql='insert into ReportsFilters values (''General Information'',''users'',2010)
			insert into ReportsFilters values (''Sessions'',''users'',2020)
			insert into ReportsFilters values (''Unavailable'',''unavailables'',2030)
			insert into ReportsFilters values (''Unavailable'',''users'',2030)
			insert into ReportsFilters values (''Unavailable Detail'',''unavailables'',2040)
			insert into ReportsFilters values (''Unavailable Detail'',''users'',2040)
			insert into ReportsFilters values (''KPI Agents Report'',''users'',2050)
			insert into ReportsFilters values (''Call Detail'',''acds'',3010)
			insert into ReportsFilters values (''Calls by ACD Group DID general WG Area'',''acds'',3020)
			insert into ReportsFilters values (''Calls by ACD Group DID general WG Area'',''areas'',3020)
			insert into ReportsFilters values (''Calls by ACD Group DID general WG Area'',''dids'',3020)
			insert into ReportsFilters values (''Calls by ACD Group DID general WG Area'',''workgroups'',3020)
			insert into ReportsFilters values (''Not Transferred by ACD Group general WG Area'',''acds'',3030)
			insert into ReportsFilters values (''Not Transferred by ACD Group general WG Area'',''areas'',3030)
			insert into ReportsFilters values (''Not Transferred by ACD Group general WG Area'',''calltypes'',3030)
			insert into ReportsFilters values (''Not Transferred by ACD Group general WG Area'',''workgroups'',3030)
			insert into ReportsFilters values (''Call Disposition by ACD Group general WG Area'',''acds'',3040)
			insert into ReportsFilters values (''Call Disposition by ACD Group general WG Area'',''areas'',3040)
			insert into ReportsFilters values (''Call Disposition by ACD Group general WG Area'',''dispositionsIn'',3040)
			insert into ReportsFilters values (''Call Disposition by ACD Group general WG Area'',''workgroups'',3040)
			insert into ReportsFilters values (''Effectiveness'',''acds'',3060)
			insert into ReportsFilters values (''Change flow'',''acds'',3070)
			insert into ReportsFilters values (''Billing 01 900'',''acds'',3080)
			insert into ReportsFilters values (''Symposium'',''acds'',3090)
			insert into ReportsFilters values (''Resume per DID'',''dids'',3100)
			insert into ReportsFilters values (''Rejected Calls'',''dids'',3110)
			insert into ReportsFilters values (''Call SubDisposition'',''subdispositionsIn'',3120)
			insert into ReportsFilters values (''Call SubDisposition'',''acds'',3120)
			insert into ReportsFilters values (''ACD Chats'',''acds'',3131)
			insert into ReportsFilters values (''ACD Chats'',''areas'',3131)
			insert into ReportsFilters values (''Chats not contacted'',''acds'',3132)
			insert into ReportsFilters values (''Chats not contacted'',''areas'',3132)
			insert into ReportsFilters values (''Chats detail'',''acds'',3133)
			insert into ReportsFilters values (''Average Answer Time'',''acds'',3134)
			insert into ReportsFilters values (''Average Answer Time'',''users'',3134)
			insert into ReportsFilters values (''Chats Effectiveness'',''acds'',3135)
			insert into ReportsFilters values (''General Calls and Chats'',''acds'',3136)
			insert into ReportsFilters values (''Abandoned'',''acds'',3141)
			insert into ReportsFilters values (''Abandoned'',''areas'',3141)
			insert into ReportsFilters values (''Abandoned'',''workgroups'',3141)
			insert into ReportsFilters values (''Answered'',''acds'',3142)
			insert into ReportsFilters values (''Answered'',''areas'',3142)
			insert into ReportsFilters values (''Answered'',''workgroups'',3142)
			insert into ReportsFilters values (''Dialing Detail'',''campaigns'',4010)
			insert into ReportsFilters values (''Dialing Detail'',''dialresults'',4010)
			insert into ReportsFilters values (''Answered Calls Detail'',''campaigns'',4020)
			insert into ReportsFilters values (''Answered Calls Detail'',''users'',4020)
			insert into ReportsFilters values (''Answered Calls by Campaign general wg area'',''areas'',4030)
			insert into ReportsFilters values (''Answered Calls by Campaign general wg area'',''campaigns'',4030)
			insert into ReportsFilters values (''Answered Calls by Campaign general wg area'',''users'',4030)
			insert into ReportsFilters values (''Answered Calls by Campaign general wg area'',''workgroups'',4030)
			insert into ReportsFilters values (''Call Disposition campaign wg area'',''areas'',4040)
			insert into ReportsFilters values (''Call Disposition campaign wg area'',''campaigns'',4040)
			insert into ReportsFilters values (''Call Disposition campaign wg area'',''dispositionsOut'',4040)
			insert into ReportsFilters values (''Call Disposition campaign wg area'',''workgroups'',4040)
			insert into ReportsFilters values (''Dialing by Campaign wg area'',''areas'',4050)
			insert into ReportsFilters values (''Dialing by Campaign wg area'',''campaigns'',4050)
			insert into ReportsFilters values (''Dialing by Campaign wg area'',''dialresults'',4050)
			insert into ReportsFilters values (''Dialing by Campaign wg area'',''workgroups'',4050)
			insert into ReportsFilters values (''Call Billing'',''campaigns'',4060)
			insert into ReportsFilters values (''Call Billing'',''providers'',4060)
			insert into ReportsFilters values (''Call Billing'',''users'',4060)
			insert into ReportsFilters values (''Answered Calls per telephone number'',''campaigns'',4070)
			insert into ReportsFilters values (''KPI Outbound Report'',''campaigns'',4090)
			insert into ReportsFilters values (''Call SubDisposition'',''subdispositionsOut'',4100)
			insert into ReportsFilters values (''Call SubDisposition'',''campaigns'',4100)
			insert into ReportsFilters values (''CallBacks'',''campaigns'',4110)
			insert into ReportsFilters values (''CallBacks'',''users'',4110)
			insert into ReportsFilters values (''Answered Calls by Status'',''areas'',4130)
			insert into ReportsFilters values (''Answered Calls by Status'',''campaigns'',4130)
			insert into ReportsFilters values (''Answered Calls by Status'',''workgroups'',4130)
			insert into ReportsFilters values (''Answered Calls On Chat Detail'',''campaigns'',4140)
			insert into ReportsFilters values (''Answered Calls On Chat Detail'',''users'',4140)
			insert into ReportsFilters values (''Abandon reports'',''acds'',7010)
			insert into ReportsFilters values (''Abandon reports'',''campaigns'',7010)
			insert into ReportsFilters values (''Agent summary'',''users'',7020)
			insert into ReportsFilters values (''Movements per campaign'',''campaigns'',7030)
			insert into ReportsFilters values (''Promises per campaign'',''acds'',7040)
			insert into ReportsFilters values (''Promises per campaign'',''campaigns'',7040)
			insert into ReportsFilters values (''Performance per agent'',''users'',7050)
			insert into ReportsFilters values (''Account history'',''campaigns'',7060)
			insert into ReportsFilters values (''Outbound Trunks busy'',''campaigns'',8020)
			insert into ReportsFilters values (''Inbound Trunks busy'',''acds'',8030)
			insert into ReportsFilters values (''Special Times'',''acds'',8040)
			insert into ReportsFilters values (''Special Times'',''campaigns'',8040)
			insert into ReportsFilters values (''Agent'',''users'',8061)
			insert into ReportsFilters values (''Agent'',''users'',8081)
			insert into ReportsFilters values (''Disposition'',''users'',8080)
			insert into ReportsFilters values (''Rate Detail'',''supervisors'',8071)
			insert into ReportsFilters values (''Rate Detail'',''template'',8071)
			insert into ReportsFilters values (''Rate Detail'',''users'',''8071'')
			insert into ReportsFilters values (''RateChat'',''template'',''8083'')
			insert into ReportsFilters values (''RateChat'',''users'',''8083'')
			insert into ReportsFilters values (''RepAVRSQuestion'',''Questions'',8064)
			insert into ReportsFilters values (''RepAVRSQuestionChat'',''QuestionsChat'',8082)
			insert into ReportsFilters values (''Section'',''templateSection'',8063)
			insert into ReportsFilters values (''Supervisors'',''supervisors'',8062)
			'
		EXEC(@sql)

		set @process = 'Insert new reports -- ReportsFilters'
		set @sql='insert into reportsfilters values (''Abandon report percentage'',''acds'',7090)
insert into reportsfilters values (''Abandon report profiles'',''acds'',7100)
insert into reportsfilters values (''Abandon report times'',''acds'',7110)
insert into ReportsFilters values (''MKT Agentes'', ''users'',7070)'
		EXEC(@sql)

		set @process = 'Insert new reports -- reportsfiltersmenus'
		set @sql='if not exists (select * from reportsfiltersmenus where idReport in(7070,7090,7100,7110) ) begin
	insert into reportsfiltersmenus values (7090,''date'')
	insert into reportsfiltersmenus values (7090,''filterby'')
	insert into reportsfiltersmenus values (7100,''date'')
	insert into reportsfiltersmenus values (7100,''filterby'')
	insert into reportsfiltersmenus values (7110,''date'')
	insert into reportsfiltersmenus values (7110,''filterby'')
	insert into ReportsFiltersMenus values (7070,''groupby'')
	insert into ReportsFiltersMenus values (7070,''filterby'')
	insert into ReportsFiltersMenus values (7070,''date'')
end'
		EXEC(@sql)

		set @process = 'Insert new reports -- ReportsTotals'
		set @sql='if not exists (select * from ReportsTotals where id in(7070,7090,7100,7110) ) begin
	insert into ReportsTotals values (7090,''sum:5|sum:10|sum:15|sum:20|sum:25|sum:30|sum:40|sum:50|sum:60|sum:gt60'')
	insert into ReportsTotals values (7100,''sum:5|sum:10|sum:15|sum:20|sum:25|sum:30|sum:40|sum:50|sum:60|sum:gt60|sum:total'')
	insert into ReportsTotals values (7110,''sum:5|sum:10|sum:15|sum:20|sum:25|sum:30|sum:40|sum:50|sum:60|sum:gt60'')
	insert into ReportsTotals (id, totalColumns) values (7070,''sum:CallsperACDGroupD|sum:tACD|sum:tAgent|sum:oHour|sum:tAux|sum:readyTime|sum:tPer|sum:Ayuda|sum:nxfer|special:sum:tPromACD|special:tPromACD:(case when sum(CallsperACDGroupD) > 0 then sum(tACD) / sum(CallsperACDGroupD) else 0 end)|special:tPromACW:(case when sum(nacw) > 0 then sum(tACW) / sum(nacw) else 0 end)'')
end'
		EXEC(@sql)

		set @process = 'CREATE index -- RepMKTAgentes'
		set @sql='if not exists (select * from sys.indexes where name = N''IX_RepMKTAgentes'' and object_id = OBJECT_ID(N''RepMKTAgentes'')) begin
CREATE CLUSTERED INDEX [IX_RepMKTAgentes] ON [dbo].[RepMKTAgentes]
(
	[date] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
end'
		EXEC(@sql)

		set @process = 'CREATE index -- RepSpececialAbndProfiles'
		set @sql='if not exists (select * from sys.indexes where name = N''IX_RepSpececialAbndProfiles'' and object_id = OBJECT_ID(N''RepSpececialAbndProfiles'')) begin
CREATE CLUSTERED INDEX [IX_RepSpececialAbndProfiles] ON [dbo].[RepSpececialAbndProfiles]
(
	[date] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
end'
		EXEC(@sql)

		set @process = 'CREATE index -- RepSpececialAbndPercentage'
		set @sql='if not exists (select * from sys.indexes where name = N''IX_RepSpececialAbndTimes'' and object_id = OBJECT_ID(N''RepSpececialAbndTimes'')) begin
CREATE CLUSTERED INDEX [IX_RepSpececialAbndTimes] ON [dbo].[RepSpececialAbndTimes]
(
	[date] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
end'
		EXEC(@sql)

		set @process = 'CREATE index -- RepSpececialAbndPercentage'
		set @sql='if not exists (select * from sys.indexes where name = N''IX_RepSpececialAbndPercentage'' and object_id = OBJECT_ID(N''RepSpececialAbndPercentage'')) begin
CREATE CLUSTERED INDEX [IX_RepSpececialAbndPercentage] ON [dbo].[RepSpececialAbndPercentage]
(
	[date] DESC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
 end'
		EXEC(@sql)

		set @process = 'Update in -- PivotReports'
		set @sql='update PivotReports set complementColumns=''login|date|user|sessionTime|userId'' where id=2030'
		EXEC(@sql)


		set @process = 'Drop  SP -- ccspRepSpececialAbndPercentage'
		set @sql='if exists (select * from sys.procedures where name = N''ccspRepSpececialAbndPercentage'') DROP PROCEDURE ccspRepSpececialAbndPercentage'
		EXEC(@sql)

		set @process = 'Drop  SP -- ccspRepSpececialAbndProfiles'
		set @sql='if exists (select * from sys.procedures where name = N''ccspRepSpececialAbndProfiles'') DROP PROCEDURE ccspRepSpececialAbndProfiles'
		EXEC(@sql)


		set @process = 'Drop  SP -- ccspRepSpececialAbndTimes'
		set @sql='if exists (select * from sys.procedures where name = N''ccspRepSpececialAbndTimes'') DROP PROCEDURE ccspRepSpececialAbndTimes'
		EXEC(@sql)

		set @process = 'Drop  SP -- ccspRepSpececialAbndPercentage'
		set @sql='if exists (select * from sys.procedures where name = N''ccspRepMKTAgentes'') DROP PROCEDURE ccspRepMKTAgentes'
		EXEC(@sql)


		set @process = 'create SP -- ccspRepSpececialAbndPercentage'
		set @sql='Create PROCEDURE [dbo].[ccspRepSpececialAbndPercentage]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null
		select @to = getdate()

	delete RepSpececialAbndPercentage with(rowlock)
	where [date] between @from and @to

	insert RepSpececialAbndPercentage select [date], inboundId, [inbound]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [5]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [10]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [15]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [20]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [25]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [30]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [40]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [50]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [60]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [>60]
			from (
				select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
				,cal_id
				,SUM(CASE WHEN (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
				,COUNT(CASE WHEN (statuscall_id <> 13) THEN 1 ELSE NULL END) AS nAbnd
				from cccallsin ci with(index(IX_ccCallsIn),nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id
				where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
			) xCalls
		GROUP BY [date], inboundId, [inbound]
end'
		EXEC(@sql)

		set @process = 'CREATE SP -- ccspRepSpececialAbndProfiles'
		set @sql='CREATE PROCEDURE [dbo].[ccspRepSpececialAbndProfiles]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null
		select @to = getdate()

	delete RepSpececialAbndProfiles with(rowlock)
	where [date] between @from and @to

	insert RepSpececialAbndProfiles select [date], inboundId, [inbound]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))) AS [5]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))) AS [10]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))) AS [15]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))) AS [20]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))) AS [25]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))) AS [30]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))) AS [40]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))) AS [50]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))) AS [60]
		, (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 THEN 1 ELSE NULL END),0))) AS [>60]
		, COUNT(*) total
			from (
				select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
				,cal_id
				,SUM(CASE WHEN (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
				,COUNT(CASE WHEN (statuscall_id <> 13) THEN 1 ELSE NULL END) AS nAbnd
				from cccallsin ci with(index(IX_ccCallsIn),nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id
				where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
			) xCalls
		GROUP BY [date], inboundId, [inbound]
end'
		EXEC(@sql)

		set @process = 'CREATE SP -- ccspRepSpececialAbndTimes'
		set @sql='CREATE PROCEDURE [dbo].[ccspRepSpececialAbndTimes]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null
		select @to = getdate()

	delete RepSpececialAbndTimes with(rowlock)
	where [date] between @from and @to

	insert RepSpececialAbndTimes select [date], inboundId, [inbound]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [5]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [10]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [15]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [20]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [25]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [30]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [40]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [50]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [60]
		, CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [>60]
			from (
				select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
				,cal_id
				,SUM(CASE WHEN (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
				,COUNT(CASE WHEN (statuscall_id <> 13) THEN 1 ELSE NULL END) AS nAbnd
				from cccallsin ci with(index(IX_ccCallsIn),nolock) left join ccinbound ib on ib.inbound_id=ci.inbound_id
				where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
			) xCalls
		GROUP BY [date], inboundId, [inbound]
end'
		EXEC(@sql)

		set @process = 'CREATE SP -- ccspRepMKTAgentes'
		set @sql='CREATE PROCEDURE [dbo].[ccspRepMKTAgentes]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
 set nocount on
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
		select @to = getdate()

if @action = 1 begin

CREATE TABLE #times(
	[ID] INT primary key,
	[Start] DATETIME,
	[Stop] DATETIME
	)

	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

declare @starttime datetime,@number int
	set @starttime = @from
	set @number = 0



while @number <= (datediff(mi,@starttime,@to)/15) begin
		   insert into #times
		   select @number,DATEADD(mi, @number*15, @starttime),DATEADD(mi, (@number+1)*15, @StartTime)
		   set @number = @number +1
	end


select
	cal_inicio dateStartDetail,
	dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
	case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_inicio,121) + '':00:00.000''
	     when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_inicio,121) + '':15:00.000''
		 when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_inicio,121) + '':30:00.000''
		 when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_inicio,121) + '':45:00.000'' end as timegroup,
	case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':15:00.000''
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':30:00.000''
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':45:00.000''
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 45 and 59 then  convert(varchar(13), dateadd(hh,1,cal_Inicio),121) + '':00:00.000'' end as timegroup_next,
		 c.user_id,isnull(count(case when c.statusCall_id=13 then 1 else null end),0) nacd,
         isnull(count(case when c.statusCall_id=13 and c.cal_tnotas>0 then 1 else null end),0) nacw,

         isnull(count(case when l.modo in (3,4) and l.tipo=1 then 1 else NULL end),0) cayuda,
         isnull(count(case when l.modo in (0,3,4) and l.tipo=1 then 1 else NULL end),0) nxfersal,
		 isnull(sum(case when c.statuscall_id = 13 then (c.cal_twait + c.cal_txfer + c.cal_tring) else 0 end),0) tresp,
		 isnull(sum(case when c.statusCall_id=13 and c.cal_tdialog>=0 then c.cal_tdialog else 0 end),0) tacd,
         isnull(sum(case when c.statusCall_id=13 then c.cal_tnotas else 0 end),0) tacw

		,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
	   into #timeAgenteTransfer
       from cccallsin c
       LEFT OUTER JOIN ccLogTransfers l (nolock) on (l.cal_id = c.cal_id and l.fechaFin between @from and @to)
       where c.cal_inicio between @from and @to and c.user_id>0 and c.inbound_id>0
       group by c.user_id,cal_inicio

	select * into #timeAgenteTransfer2 from #timeAgenteTransfer where datediff(mi,timegroup,timegroup_next)>15
	delete #timeAgenteTransfer where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeAgenteTransfer
	select dateStartDetail,dateEndDetail,th.start,th.stop,user_id
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nacd else 0 end nacd
,case when th.start > dateStartDetail and th.stop > dateEndDetail then nacw else 0 end nacw
,case when th.start > dateStartDetail and th.stop > dateEndDetail then cayuda else 0 end cayuda
,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfersal else 0 end nxfersal
,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,dateStartDetail,time_dialog)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_dialog then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_dialog and  th.stop > time_notes then datediff(ss,th.start,time_dialog)
	  when th.start > dateStartDetail and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tresp
,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
	  when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
	  when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
	  when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tacd
,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
	  when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
	  when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
	  when th.start > time_notes and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tacd
,time_dialog,time_notes,time_end_call
	from #timeAgenteTransfer2 t
	join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0


select dateadd(ss,isnull(-tstatus,0),fecha) dateStartDetail,fecha dateEndDetail,
	case when datepart(mi,dateadd(ss,isnull(-tstatus,0),fecha))
		   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(-tstatus,0),fecha),121) + '':00:00.000''
		   when datepart(mi,dateadd(ss,isnull(-tstatus,0),fecha))
		   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(-tstatus,0),fecha),121) + '':15:00.000''
		   when datepart(mi,dateadd(ss,isnull(-tstatus,0),fecha))
		   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(-tstatus,0),fecha),121) + '':30:00.000''
		   when datepart(mi,dateadd(ss,isnull(-tstatus,0),fecha))
		   between 45 and 59 then convert(varchar(13),dateadd(ss,isnull(-tstatus,0),fecha),121) + '':45:00.000'' end as timegroup,
	case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
	     when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
		 when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
		 when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end as timegroup_next,
	user_id,
             (case when TipoStatusAge_id = 7 then tstatus else 0 end) t_otra,
             (case when TipoStatusAge_id = 2 then tstatus else 0 end) t_aux,
             (case when TipoStatusAge_id = 3 then tstatus else 0 end) t_disp,
             (case when TipoStatusAge_id = 4 then tstatus else 0 end) t_dialog,
             (case when TipoStatusAge_id = 6 then tstatus else 0 end) t_notas,
             tstatus t_pers
		, case when TipoStatusAge_id = 7 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_otra
, case when TipoStatusAge_id = 2 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_aux
, case when TipoStatusAge_id = 3 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_disp
, case when TipoStatusAge_id = 4 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_dialog
, case when TipoStatusAge_id = 6 then fecha else dateadd(ss,isnull(-tstatus,0),fecha) end time_notas
,fecha time_total
		into #timeAgenteStatus
       from cclogagentesdia
	   where fecha between @from and @to
	order by user_id,fecha
       --group by user_id,fecha

	select * into #timeAgenteStatus2 from #timeAgenteStatus where datediff(mi,timegroup,timegroup_next)>15
	delete #timeAgenteStatus where datediff(mi,timegroup,timegroup_next) > 15


	insert into #timeAgenteStatus
	select dateStartDetail,dateEndDetail,th.start,th.stop,user_id
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_otra and  th.stop > time_otra and t_otra>0 then datediff(ss,dateStartDetail,time_otra)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_otra and t_otra>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_otra and  th.stop > time_otra and t_otra>0 then datediff(ss,th.start,time_otra)
	  when th.start > dateStartDetail and th.stop < time_otra and t_otra>0 then datediff(ss,th.start,th.stop) else  0 end as t_otra
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_aux and  th.stop > time_aux and t_aux>0  then datediff(ss,dateStartDetail,time_aux)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_aux and t_aux>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_aux and  th.stop > time_aux and t_aux>0 then datediff(ss,th.start,time_aux)
	  when th.start > dateStartDetail and th.stop < time_aux and t_aux>0 then datediff(ss,th.start,th.stop)  else  0 end as t_aux

	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_disp and  th.stop > time_disp and t_disp>0 then datediff(ss,dateStartDetail,time_disp)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_disp and t_disp>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_disp and  th.stop > time_disp and t_disp>0 then datediff(ss,th.start,time_disp)
	  when th.start > dateStartDetail and th.stop < time_disp and t_disp>0 then datediff(ss,th.start,th.stop) else  0 end as t_disp

	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_dialog and  th.stop > time_dialog and t_dialog>0 then datediff(ss,dateStartDetail,time_dialog)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_dialog and t_dialog>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_dialog and  th.stop > time_dialog and t_dialog>0 then datediff(ss,th.start,time_dialog)
	  when th.start > dateStartDetail and th.stop < time_dialog and t_dialog>0 then datediff(ss,th.start,th.stop) else  0 end as t_dialog
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_notas and  th.stop > time_notas and t_notas>0 then datediff(ss,dateStartDetail,time_notas)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_notas and t_notas>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_notas and  th.stop > time_notas and t_notas>0 then datediff(ss,th.start,time_notas)
	  when th.start > dateStartDetail and th.stop < time_notas and t_notas>0 then datediff(ss,th.start,th.stop) else  0 end as t_notas
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_total and  th.stop > time_total and t_pers>0 then datediff(ss,dateStartDetail,time_total)
	  when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_total and t_pers>0 then datediff(ss,dateStartDetail,th.stop)
	  when th.start > dateStartDetail and th.start <= time_total and  th.stop > time_total and t_pers>0 then datediff(ss,th.start,time_total)
	  when th.start > dateStartDetail and th.stop < time_total and t_pers>0 then datediff(ss,th.start,th.stop) else  0 end as t_pers
	,time_otra,time_aux,time_disp,time_dialog,time_notas,time_total
	from #timeAgenteStatus2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0

delete from dbo.RepMKTAgentes with(rowlock)
		where date >= @from AND date < @to


insert into dbo.RepMKTAgentes
select convert(varchar(24),acd.timegroup,121) date,acd.user_Id,(isnull(users.login,'''')) [Login],
		(isnull(users.apellidopaterno,'''')+'' ''+isnull(users.apellidomaterno,'''')+'' ''+isnull(users.nombres,'''')) agt_name
		,acd.nacd [Llamadas ACD],
		acd.tacd [Tiempo ACD],
		acd.tresp [Tiempo Llamado Agente],
		tready.t_otra [Otra Hora],
       tready.t_aux [Tiempo AUX],
       tready.t_disp [Tiempo Dis5ponible],
       tready.t_pers [Tiempo Personal],
       acd.cayuda [Ayuda],
       acd.nxfersal [Trans Salida],
datepart(yyyy,convert(varchar(24),acd.timegroup,121)) year,
	datepart(mm, acd.timegroup) month,
	datepart(dd, convert(varchar(24),acd.timegroup,121)) day,
	datepart(hh, convert(varchar(24),acd.timegroup,121)) hour,
	datepart(mi,convert(varchar(24),acd.timegroup,121)) minutes
from (
select acd.timegroup,acd.user_id,sum(nacd) nacd,sum(nacw) nacw,sum(cayuda) cayuda ,sum(nxfersal) nxfersal,sum(tresp) tresp,sum(tacd) tacd,sum(tacw) tacw
	from #timeAgenteTransfer acd group by acd.timegroup,acd.user_id) acd
left join
(select timegroup,user_id,sum(t_otra) t_otra,sum(t_aux) t_aux,sum(t_disp) t_disp,sum(t_pers) t_pers
	from #timeAgenteStatus group by timegroup,user_id) tready on tready.user_id=acd.user_id and tready.timegroup=acd.timegroup

left join ccusers users ON users.user_id=acd.user_id
order by date,Login
drop table #times
drop table #timeAgenteTransfer
drop table #timeAgenteTransfer2
drop table #timeAgenteStatus
drop table #timeAgenteStatus2

END '
		EXEC(@sql)

		set @process = 'Alter SP -- ccspRepAgentGI'
		set @sql='ALTER PROCEDURE [dbo].[ccspRepAgentGI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS off
SET NOCOUNT ON


--declare @action as tinyint,@from as datetime,@to as datetime
--select @action=1,@from=''2015-02-20 00:00:00'',@to=''2015-02-20 23:59:59''
--select @to = getdate()

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action=1 begin

	DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
	SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
	DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

	EXEC @tresRing=ccspConfigTresRing
	EXEC @tresDialog=ccspConfigTresDialog
	EXEC @tresDelayIn=ccspConfigtresDelayIn

	declare @starttime datetime,@number int
	set @starttime = @from
	set @number = 0

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

	CREATE TABLE #times(
	[ID] INT primary key,
	[Start] DATETIME,
	[Stop] DATETIME
	)

	create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
	create nonclustered index ix_times2 on #times([Start] DESC)

	create table #timeDetailAgent(
	[User_id] int null,
	dateStartDetail datetime null,dateEndDetail datetime null,timegroup datetime null,
	timegroup_next datetime null,tunknown int null,
	tnot_av int null,tav int null,tprob int null,
	tother int null,nother int null,tmanualcall int null)

	create table #notReady(
	[Row] int identity primary key,
	dateStartDetail datetime,dateEndDetail datetime,
	timegroup   datetime,timegroup_next datetime,
	[User_id] int,timeNotReady int)

	while @number <= (datediff(mi,@starttime,@to)/15) begin
		   insert into #times
		   select @number,DATEADD(mi, @number*15, @starttime),DATEADD(mi, (@number+1)*15, @StartTime)
		   set @number = @number +1
	end


	-- Session Time
	select sessiontime.user_id as user_id, subLogin as login,subLogout as logout, extension
	into #sessionTime
		   from(
				 select a.extension, a.user_id, a.fecha as ''subLogin'',
							   (
							   select isnull(max(Fecha),getdate()) from ccLogLogin b with(nolock) where b.user_id = a.user_id and b.tipomov = 0 and b.fecha >= a.fecha and b.fecha <=
									  (
									  select isnull(min(fecha),''99991231 23:59:59.998'') from ccLogLogin with(nolock) where user_id = b.user_id and tipomov = 1 and fecha > a.fecha
									  )
							   ) as ''subLogout''
						from ccLogLogin a where a.tipomov=1 and fecha >= @from and fecha <= @to
		   ) as sessiontime
		   left join ccusers u on (sessiontime.user_id = u.user_id)
		   where u.login is not null
		   order by user_id, login

	--Contabliza el tiempo que exceda las 24hrs
	SELECT TOP 0 * INTO #temp_RepAgentSession FROM #sessionTime
	INSERT INTO #temp_RepAgentSession
	select sessiontime.user_id as user_id, subLogin as login,  subLogout as logout, extension from (
	select a.extension, a.user_id,a.fecha as ''subLogout'',
		(
			select isnull(max(b.fecha),getdate()) from ccLogLogin b with(nolock)
				where b.user_id = a.user_id and b.tipomov = 1 and b.fecha <= a.fecha
				and b.fecha >= (
					select isnull(max(fecha),b.fecha) from ccLogLogin with(nolock) where user_id = b.user_id and tipomov = 0 and fecha < a.fecha
					)

				 )  as ''subLogin''
		from ccLogLogin a where a.tipomov=0 and fecha >= @from and fecha <= @to)sessiontime
		left join ccusers u on (sessiontime.user_id = u.user_id)
		where datediff(day,subLogin,subLogout) >= 1
		order by user_id, login

	UPDATE a with (rowlock) set a.logout = b.logout
		   FROM #temp_RepAgentSession b
		   INNER JOIN #sessionTime a on a.user_Id = b.user_Id and a.login = b.login and a.logout <> b.logout

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
	select * from (
	SELECT cal_inicio as dateStartDetail,
		   dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
		   case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_inicio,121) + '':00:00.000''
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_inicio,121) + '':15:00.000''
		   when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_inicio,121) + '':30:00.000''
		   when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_inicio,121) + '':45:00.000'' end as timegroup,
		   case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':15:00.000''
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':30:00.000''
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':45:00.000''
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		   between 45 and 59 then  convert(varchar(13), dateadd(hh,1,cal_Inicio),121) + '':00:00.000'' end as timegroup_next
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
		   group by cal_id,[User_id],Inbound_id,cal_inicio,dni_id)inboundData
		   where not(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
		   AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
		   AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
		   AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)

	select * into #inboundData2 from #inboundData where datediff(mi,timegroup,timegroup_next)>15
	delete #inboundData where datediff(mi,timegroup,timegroup_next) > 15

	insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
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
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
	from #inboundData2 t
	join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	order by cal_id

	insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto)
	select * from (
	SELECT cal_Inicio AS dateStartDetail,DATEADD(ss,isnull(sum(cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio) AS dateEndDetail
		   ,case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_Inicio,121) + '':00:00.000''
				 when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_Inicio,121) + '':15:00.000''
		   when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_Inicio,121) + '':30:00.000''
		   when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_Inicio,121) + '':45:00.000'' end as timegroup
		   ,case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':15:00.000''
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':30:00.000''
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio),121) + '':45:00.000''
		   when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_Inicio))
		   between 45 and 59 then  convert(varchar(13),dateadd(hh,1,cal_Inicio),121) + '':00:00.000'' end as timegroup_next
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
		   ,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
		   ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
		   ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
		   ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
		   ,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
		   ,isnull(max(cal_telefono),0) as phone_out,cal_id,cal_puerto
		   FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
		   WHERE cal_Inicio>=@fromExtended AND cal_inicio<@to
		   -- para contar bien las llamadas manuales
		   and cal_manual in(0,2)
		   group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto)outboundData
		   where not(ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
				   AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
				   AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0 )

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
				 from #outboundData2 t
				 inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
				 where  datediff(ss,th.start,timegroup_next)>0

	insert into #timeDetailAgent
	select [User_id],DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
		   convert(datetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				 when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				 when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				 when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end) AS timegroup
		   ,convert(datetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				 when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				 when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				 when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end) as timegroup_next
				 ,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE 0 END),0) AS tunknown
				 ,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE 0 END),0) AS tnot_av
				 ,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE 0 END),0) AS tav
				 ,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE 0 END),0) AS tprob
				 ,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE 0 END),0) AS tother
				 ,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
				 ,ISNULL(SUM(CASE WHEN(tipostatusage_id=21)THEN tStatus ELSE 0 END),0) AS tmanualcall
				 --into #timeDetailAgent
		   from ccLogAgentesDia
		   WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
		   GROUP BY
		   convert(datetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				 when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				 when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				 when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end)
		   ,convert(datetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				 when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				 when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				 when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end), [User_id]

	select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15
	delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

	insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother,tmanualCall)
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
				 ,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tmanualCall,dateStartDetail))
							   when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
							   when th.start > dateStartDetail and th.start <= dateadd(ss,tmanualCall,dateStartDetail) and  th.stop > dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tmanualCall,dateStartDetail))
							   when th.start > dateStartDetail and th.stop < dateadd(ss,tmanualCall,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tmanualCall
	from #timeDetailAgent2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	group by th.start,th.stop,[User_id]

	select ROW_NUMBER() OVER(ORDER BY xTimeDetail.timegroup,xTimeDetail.[user_id] ) AS Row,
	xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother,
	isnull(calls.txfer,0) txfer,isnull(tdialog,0) tdialog,isnull(tnotes,0) tnotes,isnull(tring,0) tring,
	isnull(nMoh,0) nMoh,isnull(nWHag,0) nWHag,isnull(nWHcl,0) nWHcl,isnull(tmanualcall,0) tmanualcall,
	isnull((
		--SELECT top 1 DATEDIFF(ss,login,DATEADD(ss,900,xTimeDetail.timegroup)) FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
		--AND login>=xTimeDetail.timegroup AND login<DATEADD(ss,900,xTimeDetail.timegroup) AND logout>=DATEADD(ss,900,xTimeDetail.timegroup)
		SELECT top 1 DATEDIFF(ss,xTimeDetail.timegroup,logout) FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
		AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(ss,900,xTimeDetail.timegroup)
	),0) t1,
	isnull((
		--SELECT top 1 DATEDIFF(ss,login,logout) FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
		--AND login>=xTimeDetail.timegroup  AND login<DATEADD(ss,900,xTimeDetail.timegroup) AND logout<DATEADD(ss,900,xTimeDetail.timegroup)
		--AND login < logout
		SELECT top 1 900 FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
			AND login<=xTimeDetail.timegroup AND logout>DATEADD(ss,900,xTimeDetail.timegroup)
	),0) t2,
	isnull((
		--SELECT top 1 DATEDIFF(ss,xTimeDetail.timegroup ,logout) FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
		--AND login<xTimeDetail.timegroup  AND logout<=DATEADD(ss,900,xTimeDetail.timegroup) AND logout>xTimeDetail.timegroup
		SELECT SUM(DATEDIFF(ss,login,logout)) FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
		AND login>xTimeDetail.timegroup AND logout<DATEADD(ss,900,xTimeDetail.timegroup)
	),0)t3,
	isnull((
		--SELECT top 1 DATEDIFF(ss,xTimeDetail.timegroup ,DATEADD(ss,900,xTimeDetail.timegroup)) FROM #sessionTime
		--WHERE [user_id]=xTimeDetail.[user_id] AND login<xTimeDetail.timegroup  AND logout>DATEADD(ss,900,xTimeDetail.timegroup)
		SELECT top 1 DATEDIFF(ss,login,DATEADD(ss,900,xTimeDetail.timegroup)) FROM #sessionTime WHERE [user_id]=xTimeDetail.[user_id]
		AND login>xTimeDetail.timegroup AND login<DATEADD(ss,900,xTimeDetail.timegroup)AND logout>DATEADD(ss,900,xTimeDetail.timegroup)
	),0)t4
	into #agentInformation
	from(
		select [User_id],min(dateStartDetail) dateStartDetail,min(dateEndDetail) dateEndDetail,timegroup,timegroup_next
			   ,sum(tunknown) as tunknown,sum(tnot_av) as tnot_av,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother,sum(nother) as nother, sum(tmanualcall) as tmanualcall
			   from #timeDetailAgent
			   group by timegroup,timegroup_next,user_id
	)xTimeDetail
	full join
	(
		select (case when _in.timegroup is not null then _in.timegroup else _out.timegroup end) timegroup,
			(case when _in.[user_id] is not null then _out.[user_id] else _out.[user_id] end ) [user_id],
			sum(isnull(_in.txfer,0)) + sum(isnull(_out.txfer,0)) txfer,
			sum(isnull(_in.tdialog,0)) + sum(isnull(_out.tdialog,0)) tdialog,
			sum(isnull(_in.tnotes,0)) + sum(isnull(_out.tnotes,0)) tnotes,
			sum(isnull(_in.tring,0)) + sum(isnull(_out.tring,0)) tring,
			sum(isnull(_in.nMoh,0)) + sum(isnull(_out.nMoh,0)) nMoh,
			sum(isnull(_in.nWHag,0)) + sum(isnull(_out.nWHag,0)) nWHag,
			sum(isnull(_in.nWHcl,0)) + sum(isnull(_out.nWHcl,0)) nWHcl
		from
			(select timegroup,[user_id],
			sum(txfer) txfer,sum(tdialog) tdialog,sum(tnotes) tnotes,
			sum(tring) tring,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl
			from #inboundData group by timegroup,[user_id]) _in
			full join
			(select timegroup,[user_id],
			sum(txfer) txfer,sum(tdialog) tdialog,sum(tnotes) tnotes,
			sum(tring) tring,sum(nMoh) nMoh,sum(nWHag) nWHag,sum(nWHcl) nWHcl
			from #outboundData group by timegroup,[user_id]) _out
		on _in.timegroup=_out.timegroup and _in.[user_id]=_out.[user_id]
		where (case when _in.[user_id] is not null then _out.[user_id] else _out.[user_id] end ) is not null
		and (case when _in.[user_id] is not null then _out.[user_id] else _out.[user_id] end )=2
		group by
		(case when _in.timegroup is not null then _in.timegroup else _out.timegroup end),
		(case when _in.[user_id] is not null then _out.[user_id] else _out.[user_id] end )
	) calls
	on calls.timegroup = xTimeDetail.timegroup and xTimeDetail.[user_id]=calls.[user_id]
	where xTimeDetail.timegroup is not null
	order by  xTimeDetail.[user_id], xTimeDetail.timegroup

	insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,timeNotReady)
	SELECT DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
		convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end) AS timegroup
		,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end) as timegroup_next
				,[User_id],SUM(tStatus) as [timeNotReady]
		FROM ccLogAgentesNotReady
		WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
	GROUP BY
		convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
				when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end)
		,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
				when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
				when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
				when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end), [User_id]

	select * into #notReady2 from #notReady where datediff(mi,timegroup,timegroup_next)>15
	delete #notReady where datediff(mi,timegroup,timegroup_next) > 15

	insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,timeNotReady)
	select min(dateStartDetail),min(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
	,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,timeNotReady,dateStartDetail))
					when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
					when th.start > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,dateadd(ss,timeNotReady,dateStartDetail))
					when th.start > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as timeNotReady
	from #notReady2 t
	inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	where  datediff(ss,th.start,timegroup_next)>0
	group by th.start,th.stop,[User_id]

	select
	ROW_NUMBER() OVER(ORDER BY
						CASE WHEN agtInf.timegroup IS NOT NULL THEN agtInf.timegroup WHEN calls.timegroup IS NOT NULL  THEN calls.timegroup ELSE 0 END,
						CASE WHEN agtInf.user_id IS NOT NULL THEN agtInf.user_id WHEN calls.userId IS NOT NULL THEN calls.userId ELSE - 1 END
					) AS id,
	agtInf.[row] rowAgentInformation,
	isnull(#notReady.Row,-1) as rowNotReady
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
	,ISNULL(agtInf.t1, 0)+ISNULL(agtInf.t2, 0)+ISNULL(agtInf.t3, 0)+ISNULL(agtInf.t4, 0)  AS tlog
	,ISNULL(dbo.#notReady.timeNotReady, 0) AS treq
	,ISNULL(agtInf.tav, 0) AS tav
	,ISNULL(agtInf.tother, 0) + isnull(tmanualcall,0) AS tother
	,ISNULL(agtInf.tprob, 0) AS tprob

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
	left join ccusers u ON agtInf.[user_id] = u.[user_id]
	left join #notReady ON agtInf.[user_id] = #notReady.[user_id] AND #notReady.timegroup = agtInf.timegroup
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


	SELECT
		   RANK() OVER(PARTITION BY rowAgentInformation ORDER by id) as [rank],
		   ROW_NUMBER() OVER(Order by id) as rowNumber,id
		   into #tempTime
		   FROM #tempRepAgentGI
		   where rowAgentInformation in
				 (select rowAgentInformation from #tempRepAgentGI temp GROUP BY temp.rowAgentInformation HAVING Count(*) > 1 )

	update t set nother=0,tunknown=0,tnotav=0,tlog=0,tother=0,tprob=0,tav=0
		   from #tempRepAgentGI t     inner join #tempTime temp on t.id = temp.id
		   where [rank]>1

	delete #tempTime

	insert into #tempTime
	SELECT
	RANK() OVER(PARTITION BY rowNotReady ORDER by id) as [rank],
	ROW_NUMBER() OVER(Order by id) as rowNumber,id
	FROM #tempRepAgentGI
	where rowNotReady in
		   (select rowNotReady from #tempRepAgentGI temp GROUP BY temp.rowNotReady HAVING Count(*) > 1 )

	update t set treq=0
		   from #tempRepAgentGI t inner join #tempTime temp on t.id = temp.id
		   where [rank]>1

	delete #tempTime

	insert into #tempTime
	SELECT
		   RANK() OVER(PARTITION BY rowIn ORDER by id) as [rank],
		   ROW_NUMBER() OVER(Order by id) as rowNumber,id
		   FROM #tempRepAgentGI
		   where rowIn in
				 (select rowIn from #tempRepAgentGI temp GROUP BY temp.rowIn HAVING Count(*) > 1 )

	update t
		   set nxferin=0,nanswerin=0,nabndxferin=0,nabndringin=0,nabnddlgin=0,abndaxferin=0,nnoanswerin=0
						,nlostin=0,tdialogin=0,tnotesin=0,tringin=0,txferin=0,nMohin=0,nWHagin=0,nWHcliin=0
		   from #tempRepAgentGI t
		   inner join #tempTime temp on t.id = temp.id
		   where [rank]>1

	delete #tempTime

	insert into #tempTime
	SELECT
	RANK() OVER(PARTITION BY rowOut ORDER by id) as [rank],
	ROW_NUMBER() OVER(Order by id) as rowNumber,
	id
	FROM #tempRepAgentGI
	where rowOut in
		   (select rowOut from #tempRepAgentGI temp GROUP BY temp.rowOut HAVING Count(*) > 1 )

	update t
		   set nxferout=0,nanswerout=0,nabndxferout=0,nabndringout=0,nabnddlgout=0,abndaxferout=0,nnoanswerout=0,nlostout=0,tdialogout=0
						,tnotesout=0,tringout=0,txferout=0,nMohout=0,nWHagout=0,nWHcliout=0
		   from #tempRepAgentGI t
		   inner join #tempTime temp on t.id = temp.id
		   where [rank]>1

	delete from RepAgentGI with(rowlock) where date >= @from AND date < @to
	--update #tempRepAgentGI set tlog = 0 where tdialogout = 0 and tlog > 0

	insert into RepAgentGI(date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,treq,tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotavg)
	select date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,treq,tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotav
	 from #tempRepAgentGI

	--select * from #sessionTime where User_id=2 order by login

	--select t1+t2+t3+t4 tlog,tnot_av+tav+tprob+tother+tunknown+txfer+tdialog+tnotes+tring+tmanualcall,* from #agentInformation where User_id=2

	---DROP TABLES TEMP
	drop table #sessionTime
	drop table #times
	drop table #temp_RepAgentSession
	drop table #inboundData
	drop table #inboundData2
	drop table #outboundData
	drop table #outboundData2
	drop table #timeDetailAgent
	drop table #timeDetailAgent2
	drop table #notReady
	drop table #notReady2
	drop table #agentInformation
	drop table #tempTime
	drop table #tempRepAgentGI


end'
		EXEC(@sql)


		set @process = 'Alter SP --- GetReportMenus'
		set @sql=' ALTER PROCEDURE [dbo].[GetReportMenus]
	@userId int,
	@activeChat tinyint,
	@activeAVRS tinyint,
	@activeCRM tinyint=0
AS
BEGIN

	select menu_id,
		substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip)) as menu_descrip,
		nullif(parent,menu_id) as parent,Nivel,ordengral
		into #tempCCMenus from ccMenus with(nolock)
		where type = 3 and menu_id >= 2000 and(
			(menu_id not in (3130,3131,3132,3133,3134,3135,3136,8050,8060,8061,8062,8063,8070,8071,8072,8080,9000,9010))
			or  (@activeChat = 1 and menu_id in (3130,3131,3132,3133,3134,3135,3136))
			or  (@activeAVRS = 1 and menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080) )
			or  (@activeCRM = 1 and menu_id in (9000,9010) )  )
			order by menu_id


	;WITH ccMenusUserRec(Nivel, menu_descrip, menu_id, ordengral, parent)
	AS
	(
		select
			distinct b.Nivel as Nivel,
			b.menu_descrip as menu_descrip,
			b.menu_id as menu_id,
			b.ordengral as ordengral,
			b.parent as parent
			from #tempCCMenus as b
			inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId and b.menu_id<>b.parent and a.type = 3
		UNION ALL
	--RECURSIViDAD
		select a.Nivel, a.menu_descrip, a.menu_id, a.ordengral, a.parent
			from #tempCCMenus a inner join ccMenusUserRec b on a.menu_id=b.parent
	)

	select distinct Nivel,menu_descrip,menu_id,ordengral,parent into #tempCCMenusUser from ccMenusUserRec order by menu_id

	select distinct A.Nivel, A.menu_descrip, A.menu_id, A.ordengral,5 filtersType from #tempCCMenusUser A
	where  menu_id not in
		(select distinct parent from  #tempCCMenus where Nivel=''C'' and parent not in (select distinct  A.parent from  #tempCCMenusUser A where A.Nivel=''C''))
	order by menu_id

	drop table #tempCCMenus
	drop table #tempCCMenusUser

END'
		EXEC(@sql)

		set @process = 'Alter SP -- ccspRepAgentNotReady'
		set @sql='ALTER PROCEDURE [dbo].[ccspRepAgentNotReady]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS OFF
SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
begin
	delete from RepAgentNotReady with(rowlock)
	where date >= @from AND date < @to

	-- Session Time
	select sessiontime.user_id as user_id, subLogin as login,
	subLogout as logout, extension
	into #sessionTime
	from(select a.extension, a.user_id, a.fecha as ''subLogin'',
	(select isnull(max(Fecha),getdate())
		from ccLogLogin b with(nolock)
		where b.user_id = a.user_id and
		b.tipomov = 0 and
		b.fecha >= a.fecha and
		b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
		from ccLogLogin with(nolock)
		where user_id = b.user_id and
		tipomov = 1 and
		fecha > a.fecha)
	) as ''subLogout''
	from ccLogLogin a
	where a.tipomov=1
	and fecha >= @from
	and fecha <= @to
	) as sessiontime
	left join ccusers u on (sessiontime.user_id = u.user_id)
	where u.login is not null
	order by user_id, login

	SELECT TOP 0 * INTO #temp_RepAgentSession FROM #sessionTime

	INSERT INTO #temp_RepAgentSession
	select sessiontime.user_id as user_id, subLogin as login,
	subLogout as logout, extension
	from(select a.extension, a.user_id, a.fecha as ''subLogout'',
	(select isnull(max(Fecha),getdate())
		from ccLogLogin b with(nolock)
		where b.user_id = a.user_id and
		b.tipomov = 1 and
		b.fecha <= a.fecha and
		b.fecha >= (select isnull(max(fecha),b.fecha)
		from ccLogLogin with(nolock)
		where user_id = b.user_id and
		tipomov = 0 and
		fecha < a.fecha)
	) as ''subLogin''
	from ccLogLogin a
	where a.tipomov=0
	and fecha >= @from
	and fecha <= @to
	) as sessiontime
	left join ccusers u on (sessiontime.user_id = u.user_id)
	where datediff(day,subLogin,subLogout) >= 1
	order by user_id, login

	UPDATE a with (rowlock)
	SET a.logout = b.logout
	FROM #temp_RepAgentSession b
	INNER JOIN #sessionTime a
	on a.user_Id = b.user_Id
	and a.login = b.login
	and a.logout <> b.logout

	DROP TABLE #temp_RepAgentSession

	-- Inbound Data
	SELECT timegroup,inbound_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
	,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
	,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
	into #inboundData
	FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
		,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
		,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
		,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
		,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
		,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
		,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
		,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
	FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,[user_id]
		,COUNT(cal_id)AS ntotal
		,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
		,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour
		,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
		,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd
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
	GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,[user_id])xDetailCount
	right JOIN(SELECT timegroup,inbound_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
		,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
	FROM(SELECT timegroup,inbound_id,[user_id]
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
	SELECT timegroup_next,inbound_id,[user_id]
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
	GROUP BY timegroup,inbound_id,[user_id])xDetailTime
	ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
	AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
	AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
	AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
	ORDER BY timegroup,inbound_id,[user_id]

	--Outbound Data
	SELECT timegroup,cam_id,[user_id],ntotal
	,nno_agent,nxfer
	,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost
	,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
	into #outboundData
	FROM(
		SELECT xDetailTime.timegroup,xDetailTime.cam_id,xDetailTime.[user_id]
			,ISNULL(ntotal,0)AS ntotal
			,ISNULL(no_agent,0)AS nno_agent,ISNULL(xfer,0)AS nxfer
			,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost
			,xDetailTime.txfer,xDetailTime.tring
			,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp
			,ISNULL(hung_up,0)AS nhangup,ISNULL(nMoh,0) as nMoh,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM(
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,cam_id
					,[user_id]
					,COUNT(cal_id)AS ntotal
					,COUNT(CASE WHEN(statuscall_id=6)THEN cal_id ELSE NULL END)AS hung_up --Ne se usa,as que es igual a total para las llamadas sin agente asignada(->agente 0)
					,COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END)AS no_agent
					,COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END)AS xfer
					--,COUNT(CASE WHEN(statuscall_id in(11,15,13,16))THEN 1 ELSE NULL END)AS xfer
					,COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END)AS no_answer
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END)AS answer
					,COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END)AS lost
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
					,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
					-- para contar bien las llamadas manuales
					and cal_manual in(0,2)
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),cam_id,[user_id]
			)xDetailCount
			--RIGHT OUTER JOIN
			LEFT JOIN
			(
				SELECT timegroup
					,cam_id
					,[user_id]
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(cal_tring),0)AS tring
					,ISNULL(SUM(cal_tdialog),0)AS tdialog
					,ISNULL(SUM(cal_tnotas),0)AS tnotes
				 FROM(	SELECT timegroup,cam_id,[user_id]
						,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					UNION
					SELECT timegroup_next,cam_id,[user_id]
						,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 AS time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					)xTimeDetail
				 GROUP BY timegroup,cam_id,[user_id]
			)xDetailTime
			ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.cam_id=xDetailCount.cam_id AND xDetailTime.[user_id]=xDetailCount.[user_id])
	)xComplete
	WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nno_agent=0
		 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		 AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
	ORDER BY timegroup,cam_id,[user_id]

	-- Agent Information
	SELECT timegroup,[user_id],tlog, 0 as treq, tnot_av
	,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
	,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
	,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
	,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
	,nother,nMoh,nWHag,nWHcl
	into #agentInformation
 FROM(
		SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
			,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
		 FROM(
			SELECT
				xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
				,ISNULL(SUM(#inboundData.txfer),0)+ ISNULL(SUM(#outboundData.txfer),0)as txfer
				,ISNULL(SUM(#inboundData.tdialog),0)+ ISNULL(SUM(#outboundData.tdialog),0)as tdialog
				,ISNULL(SUM(#inboundData.tnotes),0)+ ISNULL(SUM(#outboundData.tnotes),0)as tnotes
				,ISNULL(SUM(#inboundData.tring),0)+ ISNULL(SUM(#outboundData.tring),0)as tring
				,ISNULL(SUM(#inboundData.nMoh),0)+ ISNULL(SUM(#outboundData.nMoh),0)as nMoh
				,ISNULL(SUM(#inboundData.nWHag),0)+ ISNULL(SUM(#outboundData.nWHag),0)as nWHag
				,ISNULL(SUM(#inboundData.nWHcl),0)+ ISNULL(SUM(#outboundData.nWHcl),0)as nWHcl

				,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t1
				,ISNULL((SELECT top 1 3600
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t2
				,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
							 FROM #sessionTime
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t3
				,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
							 FROM #sessionTime
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
					 FROM ccLogAgentesDia with(nolock, index(IX_ccLogAgentesDia))
					 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
					 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
				)xTimeDetail
					LEFT OUTER JOIN #inboundData ON(xTimeDetail.timegroup=#inboundData.timegroup AND xTimeDetail.[user_id]=#inboundData.[user_id])
					LEFT OUTER JOIN #outboundData ON(xTimeDetail.timegroup=#outboundData.timegroup AND xTimeDetail.[user_id]=#outboundData.[user_id])
				GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		 	)xDetail
	)xAllTimes
 WHERE tlog>0
 ORDER BY timegroup,[user_id]

	SELECT CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121) AS timegroup
		, [user_id], tiponotready_id
		, COUNT(tStatus) as [count], SUM(tStatus) as [time]
		--, sum( case when separado in (0,3) then 1 else null end ) as amountReal --amount Real
	 into #notReady
	 FROM ccLogAgentesNotReady with(nolock, index(IX_ccLogAgentesNotReady_2))
	 WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
	 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121), [user_id], tiponotready_id

	insert into RepAgentNotReady
	select a.timegroup as date, c.login, a.user_id as [userId], c.apellidopaterno + '' '' + c.apellidomaterno + '' '' + c.nombres as [user],
	a.tlog as sessionTime,
	isnull(d.tiponotready_id,0), isnull(d.descripcion,''''),
	isnull(d.descripcion,'''') + ''_Count'' as descripcion_count, isnull([count],0), isnull(d.descripcion,'''') + ''_Time'' as descripcion_time,
	isnull([time],0), isnull([time],0) as timeSeconds--, amountReal
	,datepart(yyyy,a.timegroup), datepart(mm,a.timegroup), datepart(dd,a.timegroup), datepart(hh,a.timegroup), datepart(mi,a.timegroup)
	from #agentInformation a
	left outer join #notReady b on (a.timegroup = b.timegroup)
	left outer join (
		select user_id, login, apellidopaterno, apellidomaterno, nombres
		from ccusers
	) as c on (a.user_id = c.user_id)
	left outer join (
		select tiponotready_id, descripcion
		from ccTipoNotReady
	) as d on (b.tiponotready_id = d.tiponotready_id)

	drop table #sessionTime
	drop table #inboundData
	drop table #outboundData
	drop table #agentInformation
	drop table #notReady

end'
		EXEC(@sql)

		set @process = 'Alter SP --- GetReportFiltersMenus'
		set @sql='ALTER PROCEDURE [dbo].[GetReportFiltersMenus]
	@id int
AS
BEGIN
	SELECT id,name
	FROM dbo.FiltersMenus as f, dbo.ReportsFiltersMenus fm
	WHERE f.name = fm.filterMenuName
	AND fm.idReport = @id
	order by id
END'
		EXEC(@sql)

		/* End script release */

		/* Upgrade database version (use your own script to do it) */
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