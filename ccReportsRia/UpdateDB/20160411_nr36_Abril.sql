/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2016/04/11
Description:

	Se agrega fix para ejeccuion por tiempo report master process
Database: ccReportsRiaPara
Required version: 36

----ALTER PROCEDURE [dbo].[ccspRepCatalogos]

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 36

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

		set @process = 'Drop table -- RepSpecialTelephoneNumbersByRegistry'
		set @sql='if exists(select * from sys.tables where name=''RepSpecialTelephoneNumbersByRegistry'') drop table RepSpecialTelephoneNumbersByRegistry'
		EXEC(@sql)

		set @process = 'DISABLE TRIGGER MSmerge_tr_altertable ---------'
		set @Sql= 'IF EXISTS (SELECT * FROM sys.triggers WHERE [name] = N''MSmerge_tr_altertable'' AND type in (N''TR'') AND is_disabled = 0)
		BEGIN
		DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
		END '
		EXEC(@Sql)

		 set @process = 'alter table ccoCallsOutSource ---------'
		 set @Sql= 'if not exists (select * from sys.columns where name in(N''StatusWorkGroup'',''Region'') and Object_ID = Object_ID(N''ccoCallsOutSource''))
    begin
		ALTER TABLE ccoCallsOutSource add Region varchar(20) null
        ALTER TABLE ccoCallsOutSource add Localidad varchar(20) null
    end'
		 EXEC(@Sql)

		  set @process = 'alter table ccUsers ---------'
		 set @Sql= 'if not exists (select * from sys.columns where name in(N''IDArea'',''Region'') and Object_ID = Object_ID(N''ccUsers''))
    begin
		ALTER TABLE ccUsers add IDArea smallint null
    end'
		 EXEC(@Sql)


		 set @process = 'alter table ccRIACat_WorkGroup ---------'
		 set @Sql= 'if not exists (select * from sys.columns where name = N''StatusWorkGroup'' and Object_ID = Object_ID(N''ccRIACat_WorkGroup''))
    begin
        alter table ccRIACat_WorkGroup add StatusWorkGroup bit not null
    end'
		 EXEC(@Sql)

		 set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
		  set @Sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE [name] = N''MSmerge_tr_altertable'' AND type in (N''TR'') AND is_disabled = 1)
		BEGIN
		 ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
		END'

		EXEC(@Sql)

	set @process = 'Drop table -- RepEmailACD,RepEmailAgente,RepEmailDetail'
	set @sql='if exists(select * from sys.tables where name=''RepEmailACD'') DROP TABLE [dbo].[RepEmailACD]
if exists(select * from sys.tables where name=''RepEmailAgente'') DROP TABLE [dbo].[RepEmailAgente]
if exists(select * from sys.tables where name=''RepEmailDetail'') DROP TABLE [dbo].[RepEmailDetail]
if exists(select * from sys.tables where name=''RepEmailGeneral'') DROP TABLE [dbo].[RepEmailGeneral]
	'
	EXEC(@sql)

	set @process = 'CREATE TABLE -- RepEmailACD'
	set @sql='CREATE TABLE [dbo].[RepEmailACD](
	[date] [datetime] NOT NULL,
	[inbound] [varchar](50) NOT NULL,
	[inbounid] [smallint] NOT NULL,
	[download] [int] NOT NULL,
	[unassignedMultimedia] [int] NOT NULL,
	[ontrack] [int] NOT NULL,
	[rejected] [int] NOT NULL,
	[assigned] [int] NOT NULL,
	[totalAssets] [int] NOT NULL,
	[pendingSend] [int] NOT NULL,
	[abandonedSystem] [int] NOT NULL,
	[abandonedAgent] [int] NOT NULL,
	[finishedConversation] [int] NOT NULL,
	[avgSend] [int] NOT NULL,
	[tQueueMultimedia] [int] NOT NULL,
	[tsend] [int] NOT NULL,
	[twaitMultimedia] [int] NOT NULL,
	[tAvgAtentionMultimedia] [int] NOT NULL,
	[twrapup] [int] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]'
	EXEC(@sql)

	set @process = 'CREATE TABLE -- RepEmailAgente'
	set @sql='CREATE TABLE [dbo].[RepEmailAgente](
	[date] [datetime] NOT NULL,
	[agentName] [varchar](45) NOT NULL,
	[userid] [int] NOT NULL,
	[inbound] [varchar](50) NOT NULL,
	[inbounid] [smallint] NOT NULL,
	[download] [int] NOT NULL,
	[messageUnAssigned] [int] NOT NULL,
	[ontrack] [int] NOT NULL,
	[rejected] [int] NOT NULL,
	[assigned] [int] NOT NULL,
	[totalAssets] [int] NOT NULL,
	[pendingSend] [int] NOT NULL,
	[abandonedSystem] [int] NOT NULL,
	[abandonedAgent] [int] NOT NULL,
	[finishedConversation] [int] NOT NULL,
	[avgSend] [int] NOT NULL,
	[tQueueMultimedia] [int] NOT NULL,
	[tsend] [int] NOT NULL,
	[twaitMultimedia] [int] NOT NULL,
	[tAvgAtentionMultimedia] [int] NOT NULL,
	[twrapup] [int] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]'
	EXEC(@sql)


	set @process = 'CREATE TABLE -- RepEmailDetail'
	set @sql='CREATE TABLE [dbo].[RepEmailDetail](
	[date] [datetime] NOT NULL,
	[statusMail] [varchar](255) NOT NULL,
	[mailClient] [varchar](60) NOT NULL,
	[inbound] [varchar](50) NOT NULL,
	[inbounid] [smallint] NOT NULL,
	[conversationid] [int] NOT NULL,
	[messageId] [int] NOT NULL,
	[messagestatusid] [int] NOT NULL,
	[tQueueMultimedia] [int] NOT NULL,
	[twaitMultimedia] [int] NOT NULL,
	[tAtentionMultimedia] [int] NOT NULL,
	[twrapup] [int] NOT NULL,
	[tsend] [int] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]'
	EXEC(@sql)


	set @process = 'CREATE TABLE -- RepEmailGeneral'
	set @sql='CREATE TABLE [dbo].[RepEmailGeneral](
	[date] [datetime] NOT NULL,
	[inbound] [varchar](50) NOT NULL,
	[inbounid] [smallint] NOT NULL,
	[statusMail] [varchar](255) NOT NULL,
	[messagestatusid] [int] NOT NULL,
	[mailClient] [varchar](60) NOT NULL,
	[conversationid] [int] NOT NULL,
	[tQueueMultimedia] [int] NOT NULL,
	[twaitMultimedia] [int] NOT NULL,
	[tAtentionMultimedia] [int] NOT NULL,
	[twrapup] [int] NOT NULL,
	[tsend] [int] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]'
	EXEC(@sql)

	set @process = 'Create Index -- IX_RepEmailACD'
	set @sql='if not exists (select * from sys.indexes where name = N''IX_RepEmailACD'' and object_id = OBJECT_ID(N''RepEmailACD'')) begin
CREATE NONCLUSTERED INDEX [IX_RepEmailACD] ON [dbo].[RepEmailACD]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
end'
	EXEC(@sql)

	set @process = 'Create Index -- IX_RepEmailAgente'
	set @sql='if not exists (select * from sys.indexes where name = N''IX_RepEmailAgente'' and object_id = OBJECT_ID(N''RepEmailAgente'')) begin
CREATE NONCLUSTERED INDEX [IX_RepEmailAgente] ON [dbo].[RepEmailAgente]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
end'
	EXEC(@sql)

	set @process = 'Create Index -- IX_RepEmailDetail'
	set @sql='if not exists (select * from sys.indexes where name = N''IX_RepEmailDetail'' and object_id = OBJECT_ID(N''RepEmailDetail'')) begin
CREATE NONCLUSTERED INDEX [IX_RepEmailDetail] ON [dbo].[RepEmailDetail]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
end'
	EXEC(@sql)

	set @process = 'Create Index -- IX_RepEmailGeneral'
	set @sql='if not exists (select * from sys.indexes where name = N''IX_RepEmailGeneral'' and object_id = OBJECT_ID(N''RepEmailGeneral'')) begin
CREATE NONCLUSTERED INDEX [IX_RepEmailGeneral] ON [dbo].[RepEmailGeneral]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
end    '
	EXEC(@sql)


	set @process = 'CREATE TABLE -------- RepSpecialTelephoneNumbersByState'
	set @sql='if exists (select * from sys.objects where object_id = OBJECT_ID(N''fPercentage'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    DROP FUNCTION dbo.fPercentage'
	EXEC(@sql)

	set @process = 'CREATE TABLE -------- RepSpecialTelephoneNumbersByState'
	set @sql='if exists (select * from sys.procedures where name = N''ccspRepSpecialTelephoneNumbersByRegistry'')  DROP PROCEDURE dbo.ccspRepSpecialTelephoneNumbersByRegistry
	if exists (select * from sys.procedures where name = N''ccspRepSpecialTelephoneNumbersByState'')  DROP PROCEDURE dbo.ccspRepSpecialTelephoneNumbersByState
	if exists (select * from sys.procedures where name = N''ccspRepSpecialDialingResults'')  DROP PROCEDURE dbo.ccspRepSpecialDialingResults'
	EXEC(@sql)


	set @process = 'CREATE TABLE -------- RepSpecialTelephoneNumbersByState'
	set @sql='if not exists (select * from sys.tables where name = N''RepSpecialTelephoneNumbersByState'') begin
	create table RepSpecialTelephoneNumbersByState
	(
		[date] datetime NOT NULL,
		listId int not null,
		listName varchar(max),
		[state] varchar(max),
		[state_Count] varchar(max) not null,
		[Count] int not null,
		[state_avg] varchar(10) not null,
		[avg] decimal(10,2) not null,
		[year] int NOT NULL,
		[month] int NOT NULL,
		[day] int NOT NULL,
		[hour] int NOT NULL,
		[minutes] int NOT NULL
	)
 end'
	EXEC(@sql)

	set @process = 'CREATE table -- RepSpecialTelephoneNumbersByRegistry'
		set @sql='CREATE TABLE [dbo].[RepSpecialTelephoneNumbersByRegistry](
	[date] [datetime] NOT NULL,
	[campaignId] [smallint] NOT NULL,
	[campaign] [varchar](40) NULL,
	[listId] [int] NOT NULL,
	[listName] [varchar](100) NOT NULL,
	[cPhoneNumber] [varchar](100) NOT NULL,
	[cPhoneNumber_Count] [varchar](100) NOT NULL,
	[count] [int] NOT NULL,
	[percentage] [varchar](100) NOT NULL,
	[percentage_avg] [varchar](100) NOT NULL,
	[avg] [decimal](10,3) NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
)'
		EXEC(@sql)

	set @process = 'CREATE TABLE -------- RepSpecialDialingResults'
	set @sql='if not exists (select * from sys.tables where name = N''RepSpecialDialingResults'') begin
	create table RepSpecialDialingResults
	(
		[date] datetime NOT NULL,
		campaignId smallint not null,
		campaign varchar(40),
		statusCallId int not null,
		statusCall varchar(max) not null,
		statusCall_Count varchar(max) not null,
		[Count] int not null,
		statusCall_avg varchar(max) not null,
		[avg] decimal(10,2),
		[year] int NOT NULL,
		[month] int NOT NULL,
		[day] int NOT NULL,
		[hour] int NOT NULL,
		[minutes] int NOT NULL
	)
end'
	EXEC(@sql)

	set @process = 'INSERT -------- ReportsFiltersText'
	set @sql='if not exists(select * from ReportsFiltersText where id in (4220,4230)) begin
	insert into ReportsFiltersText values (''Telephone Numbers by State Report'', ''A-Z a-z0-9 _\-'', ''listName'', 4220)
	insert into ReportsFiltersText values (''Telephone Numbers by RecordList Report'', ''A-Z a-z0-9 _\-'', ''listName'', 4230)
end'
	EXEC(@sql)

	set @process = 'INSERT -------- ReportsFiltersMenus'
	set @sql='if not exists(select * from ReportsFiltersMenus where idReport in (4220, 4230, 4240)) begin
	insert into [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) values (4220, ''date'')
	insert into [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) values (4220, ''filterby'')
	insert into [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) values (4220, ''text'')

	insert into [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) values (4230, ''date'')
	insert into [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) values (4230, ''filterby'')
	insert into [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) values (4230, ''text'')

	insert into [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) values (4240, ''date'')
	insert into [dbo].[ReportsFiltersMenus] ([idReport], [filterMenuName]) values (4240, ''filterby'')
end'
	EXEC(@sql)

	set @process = 'INSERT -------- Filters'
	set @sql='if not exists(select * from Filters where id  = 27)
	insert into Filters values (27, ''statusCall'', 25, ''StatusCalls'', ''StatusCall'')'
	EXEC(@sql)

	set @process = 'INSERT -------- ReportsFilters'
	set @sql='if not exists(select * from ReportsFilters where id in (4220, 4230, 4240)) begin

	insert into ReportsFilters values (''Telephone Numbers by RecordList Report'', ''campaigns'', 4230)

	insert into ReportsFilters values (''Dialing Results Report'', ''campaigns'', 4240)
end'
	EXEC(@sql)

	set @process = 'INSERT -------- PivotReports'
	set @sql='if not exists(select * from PivotReports where id in (4220, 4240)) begin
	insert into PivotReports values(4220, ''state_Count|state_avg'', ''date|listName'', ''sum'')
	insert into PivotReports values(4240, ''statusCall_Count|statusCall_avg'', ''date|campaign'', ''sum'')
 end'
	EXEC(@sql)



	set @process = 'INSERT -------- ReportsTotals'
	set @sql='if not exists(select * from ReportsTotals where id  in (4220, 4230, 4240)) begin
	insert into ReportsTotals values (4220, '''')
	insert into ReportsTotals values (4230, ''sum:cPhoneNumbers|sum:cPhoneNumbers2|sum:cPhoneNumbers3|sum:cPhoneNumbers4|sum:cPhoneNumbers5|avg:percentage|avg:percentage2|avg:percentage3|avg:percentage4|avg:percentage5'')
	insert into ReportsTotals values (4240, '''')
end'
	EXEC(@sql)


	set @process = 'insert into TranslatedReports------'
	set @sql='if not exists(select * from TranslatedReports where id  in (11040, 10030, 10040)) begin
	insert into TranslatedReports values(11040,''statusTwetter'')
	insert into TranslatedReports values(10030,''statusMail'')
	insert into TranslatedReports values(10040,''statusMail'')
end'
	EXEC(@sql)


	set @process = 'CREATE FUNCTION -------- fPercentage'
	set @sql='CREATE  FUNCTION [dbo].[fPercentage] (@num1 int, @num2 int)
RETURNS decimal(10,2)
AS
BEGIN

	declare @porcentaje decimal(10,2)

	set @porcentaje = isnull(((@num1*1.00)/nullif((@num2*1.00),0))*100.00,0)

	RETURN (@porcentaje)
END'
	EXEC(@sql)

	set @process = 'CREATE SP -- ccspRepSpecialTelephoneNumbersByRegistry'
		set @sql='CREATE PROCEDURE [dbo].[ccspRepSpecialTelephoneNumbersByRegistry]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
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
	delete from RepSpecialTelephoneNumbersByRegistry with(rowlock) where date >= @from and date < @to

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
	from ccoCallsOutSource with(index(IX_ccoCallsOutSource_19),nolock)
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


	set @process = 'CREATE PROCEDURE -------- ccspRepSpecialTelephoneNumbersByState'
	set @sql='CREATE PROCEDURE [dbo].[ccspRepSpecialTelephoneNumbersByState]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

declare @totales int

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
	delete from RepSpecialTelephoneNumbersByState with(rowlock) where date >= @from and date < @to

	select @totales = isnull( COUNT(callout_id), 0)
	from ccoCallsOutSource with(index(IX_ccoCallsOutSource_19),nolock)
	where cal_fechaDial >= @from
	and cal_fechaDial < @to
	and Region is not null

	insert into RepSpecialTelephoneNumbersByState
	select convert(datetime,convert(varchar(11),cal_fechaDial)) as [date],
	   isnull([cos].list_id,0) as ''listId'', isnull(rl.name, '''') as ''listName'',
	   Region as [state],
	   Region + ''_Count'' as [state_Count],
	   isnull( COUNT(callout_id), 0) as ''Count'',
	   Region + ''_Avg'' as ''state_avg'',
	   dbo.fPercentage(isnull( COUNT(callout_id), 0), @totales) as ''avg'',
	   datepart(yy,convert(datetime, convert(varchar(11),cal_fechaDial))) as [year],
	   datepart(mm,convert(datetime, convert(varchar(11),cal_fechaDial))) as [month],
	   datepart(dd,convert(datetime, convert(varchar(11),cal_fechaDial))) as [day],
	   datepart(hh,convert(datetime, convert(varchar(11),cal_fechaDial))) as [hour],
	   datepart(mi,convert(datetime, convert(varchar(11),cal_fechaDial))) as [minutes]
	   from ccoCallsOutSource [cos] with(index(IX_ccoCallsOutSource_19),nolock)
	   left join ccRIARegistryLists rl on [cos].list_id =  rl.list_id
	where cal_fechaDial >= @from
	and cal_fechaDial < @to
	and Region is not null
	group by convert(datetime,convert(varchar(11),cal_fechaDial)) , [cos].list_id, rl.name, Region
end
'
	EXEC(@sql)


	set @process = 'INSERT -------- ReportsCharts'
	set @sql='if not exists(select * from ReportsCharts where id in (4220, 4230, 4240)) begin
insert into ReportsCharts values (4220, ''Telephone Numbers by State Report'', 1, ''state'', '''', '''', '''', ''sum([Count])'', ''Telephone Numbers by State'', 0)
insert into ReportsCharts values (4220, ''Telephone Numbers by State Report'', 2, ''year|month|day'', ''state'', '''', '''', ''sum([Count])'', ''Telephone Numbers by State per Day'', 0)

insert into ReportsCharts values (4230, ''Telephone Numbers by RecordList Report'', 1, ''listName'', '''', '''', '''', ''sum([cPhoneNumbers]+[cPhoneNumbers2]+[cPhoneNumbers3]+[cPhoneNumbers4]+[cPhoneNumbers5])'', ''Telephone Numbers by Record'', 0)
insert into ReportsCharts values (4230, ''Telephone Numbers by RecordList Report'', 2, ''year|month|day'', ''listName'', '''', '''', ''sum([cPhoneNumbers]+[cPhoneNumbers2]+[cPhoneNumbers3]+[cPhoneNumbers4]+[cPhoneNumbers5])'', ''Telephone Numbers by Record per Day'', 0)

insert into ReportsCharts values (4240, ''Dialing Results Report'', 1, ''statusCall'', '''', '''', '''', ''sum([Count])'', ''Dialing Results'', 0)
insert into ReportsCharts values (4240, ''Dialing Results Report'', 2, ''year|month|day|hour'', ''statusCall'', '''', '''', ''sum([Count])'', ''Dialing Results per Hour'', 0)
			end'
	EXEC(@sql)

	set @process = 'update ReportsCharts --4030'
		set @sql='update ReportsCharts set x1=''campaign'',countColumn=''count(distinct([callIdOut]))'' where id=4030 and chartType=1
update ReportsCharts set x1=''year|month|day'',subX1=''campaign'',countColumn=''count(distinct([callIdOut]))'' where id=4030 and chartType=2'
		EXEC(@sql)

		set @process = 'update ReportsTotals --4230'
		set @sql='update ReportsTotals set TotalColumns='''' WHERE Id=4230'
		EXEC(@sql)

		set @process = 'Insert Pivot -- RepSpecialTelephoneNumbersByRegistry(4230)'
		set @sql='if not exists(select * from PivotReports where id=4230)
	insert into PivotReports(id,columns,complementColumns,pivotFunction) values(4230,''cPhoneNumber_Count|percentage_avg'',''date|campaignId|campaign|listId|listName'',''sum'')'
		EXEC(@sql)

		set @process = 'Insert Pivot -- TranslatedReports(4230)'
		set @sql='if not exists(select * from TranslatedReports where id=4230)	insert into TranslatedReports(id,columns) values(4230,''cPhoneNumber|percentage'')'
		EXEC(@sql)

		set @process = 'update ReportsCharts 4230'
		set @sql='update ReportsCharts set x1=''cPhoneNumber_Count'',countColumn=''sum([count])'' where id=4230 and chartType=1
update ReportsCharts set chartType=3,x1='''',subX1=''cPhoneNumber_Count'',countColumn=''sum([count])'',chartDescription=''Telephone Numbers by RecordList Report'' where id=4230 and chartType=2'
		EXEC(@sql)

		set @process = 'update ReportsCharts -- 4220'
		set @sql='update ReportsCharts set chartType=3,x1='''',subX1=''state'',chartDescription=''Telephone Numbers by State'' where id=4220 and chartType=2
update ReportsCharts set chartType=2,x1=''hour'',subX1=''statusCall'',chartDescription=''Dialing Results per Hour'' where id=4240 and chartType=2'
		EXEC(@sql)


	set @process = 'CREATE PROCEDURE -- ccspRepSpecialDialingResults'
		set @sql='CREATE PROCEDURE [dbo].[ccspRepSpecialDialingResults]
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
	delete from RepSpecialDialingResults with(rowlock) where date >= @from and date < @to
	create table #temptable(
		[date] datetime,
		[Count] int
	)

	create index IX_TemptableDate on #temptable([date])

	insert into #temptable
	select convert(datetime, convert(varchar(14),[fecha],121)+ ''00'',121),isnull( COUNT(callout_id), 0)
	from ccoLogDials with(nolock)
	where fecha >= @from and fecha < @to and tipoResDial_id  <> 0
	group by convert(datetime, convert(varchar(14),[fecha],121)+ ''00'',121)

	insert into RepSpecialDialingResults
	select x.[date],[campaignId],[campaign],[statusCallId],[statusCall],[statusCall_Count]
	,isnull( COUNT(callout_id), 0) as ''Count'',[statusCall_avg]
	,dbo.fPercentage(isnull( COUNT(callout_id), 0), t.[Count]) as ''avg'',
		datepart(yy,convert(datetime, convert(varchar(14),x.[date] ,121)+ ''00'',121)) as [year],
		datepart(mm,convert(datetime, convert(varchar(14),x.[date] ,121)+ ''00'',121)) as [month],
		datepart(dd,convert(datetime, convert(varchar(14),x.[date] ,121)+ ''00'',121)) as [day],
		datepart(hh,convert(datetime, convert(varchar(14),x.[date] ,121)+ ''00'',121)) as [hour],
		datepart(mi,convert(datetime, convert(varchar(14),x.[date] ,121)+ ''00'',121)) as [minutes]
	 from (
		select convert(datetime, convert(varchar(14),[fecha],121)+ ''00'',121) as [date],
			[cld].cam_id as ''campaignId'',
			cms.cam_descripcion as ''campaign'',
			case when ctr.descripcion is null then 8 else isnull([cld].tipoResDial_id ,0) end as ''statusCallId'',
			case when ctr.descripcion is null then ''Otro'' else isnull(ctr.descripcion,'''') end as ''statusCall'',
			case when ctr.descripcion is null then ''Otro_Count'' else ctr.descripcion + ''_Count'' end as [statusCall_Count],
			callout_id,
			case when ctr.descripcion is null then ''Otro_Avg'' else ctr.descripcion + ''_Avg'' end as ''statusCall_avg''
		from ccoLogDials  [cld]
		left join ccTipoResultadoDial ctr on [cld].tipoResDial_id = ctr.tipoResDial_id
		left join cccamps cms on [cld].cam_id = cms.cam_id
		where [fecha] >= @from and [fecha] < @to
	)X
	inner join #temptable t on X.date=t.date
	group by x.[date],[campaignId],[campaign],[statusCallId],[statusCall],[statusCall_Count],[statusCall_avg],t.[Count]

	drop table #temptable
end'
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccspRepEmailACD]--------'
	set @sql='ALTER PROCEDURE [dbo].[ccspRepEmailACD]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

delete from RepEmailACD with(rowlock) where date >= @from AND date < @to

	insert into RepEmailACD
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121) date,
		isnull(descripcion,'''') as inboundName, isnull(inboundid,0) as inboundid,
		isnull(count(*),0) Downloads,isnull(sum(unassigned),0) as unassigned, isnull(sum(onTrack),0) onTrack,
		isnull(sum(rejected),0) rejected,isnull(sum(assigned),0) assigned,isnull(sum(actives),0) actives,
		isnull(sum(pendingSend),0) as pendingSend,
		isnull(sum(abandonedsystem),0) abandonedsystem, isnull(sum(abandonedbyagent),0) abandonedbyagent,
		isnull(sum(abandonedsystem+abandonedbyagent),0) finishedconversation,
		isnull(isnull(sum(sendMail),0)/nullif(cast(count(*) as float) ,0),0) * 100 as  sentvsdownloaded,
		isnull(sum(tQueue),0) tQueue, isnull(sum(tsent),0) tsent, isnull(sum(twait),0) twait,
		isnull(sum(tatention)/nullif(sum(pendingSend+onTrack+rejected+abandonedsystem+abandonedbyagent),0),0) tAvgAtentionMultimedia,
		isnull(sum(twrapup),0) twrapup,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [mounth],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [minute]
	 from (
		select msg.date date,
				 inbo.descripcion descripcion ,inbo.inbound_id inboundid,
				 case when msg.messagestatusid in (1,4) then 1 else 0 end unassigned,
				 case when msg.messagestatusid = 2 then 1 else 0 end assigned,
				 case when msg.messagestatusid = 3 then 1 else 0 end actives,
				 case when msg.messagestatusid = 5 then 1 else 0 end pendingSend,
				 case when msg.messagestatusid = 6 then 1 else 0 end onTrack,
				 case when msg.messagestatusid in (7,8,9) then 1 else 0 end rejected,
				 case when msg.messagestatusid = 10 then 1 else 0 end abandonedsystem,
				 case when msg.messagestatusid = 11 then 1 else 0 end abandonedbyagent,
				 case when msg.messagestatusid in(6,10,11) then 1 else 0 end sendMail,
				 datediff(second,msg.date,isnull(msg.tqueue,getdate())) tQueue,
				 datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent,
				 msg.twait twait,
				 msg.twait + msg.tretention + msg.tresponse tatention,
				 msg.twrapup twrapup
				 from [message] msg inner join [conversation] conv
				on msg.conversationId = conv.conversationId
				left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
				left join ccusers usuario on usuario.User_id = msg.userid
				where msg.date >= @from AND msg.date < @to
				)x
				group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid

end'
	EXEC(@sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccspRepEmailAgente]--------'
	set @sql='ALTER PROCEDURE [dbo].[ccspRepEmailAgente]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepEmailAgente with(rowlock)	where date >= @from AND date < @to

	insert into RepEmailAgente
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121) date,
		isnull(name,'''') as name, isnull(userid,0) as userId,
		isnull(descripcion,'''') as inboundName, isnull(inboundid,0) as inboundid,
		isnull(count(*),0) Downloads,isnull(sum(messageUnAssigned),0) messageUnAssigned, isnull(sum(onTrack),0) onTrack,
		isnull(sum(rejected),0) rejected,isnull(sum(assigned),0) assigned,isnull(sum(actives),0) actives,
		isnull(sum(pendingSend),0) as pendingSend,
		isnull(sum(abandonedsystem),0) abandonedsystem, isnull(sum(abandonedbyagent),0) abandonedbyagent,
		isnull(sum(abandonedsystem+abandonedbyagent),0) finishedconversation,
		isnull(isnull(sum(sendMail),0)/nullif(cast(count(*) as float) ,0),0) * 100 as  sentvsdownloaded,

		isnull(sum(tQueue),0) tQueue, isnull(sum(tsent),0) tsent, isnull(sum(twait),0) twait,
		isnull(sum(tatention)/nullif(sum(pendingSend+onTrack+rejected+abandonedsystem+abandonedbyagent),0),0) tAvgAtentionMultimedia,
		isnull(sum(twrapup),0) twrapup,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [mounth],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [minute]
	 from (
		select msg.date date,msg.messageid,
				 inbo.descripcion descripcion ,inbo.inbound_id inboundid,
				 usuario.nombres as name,usuario.[User_Id] as userid,
				 case when msg.messagestatusid in (1,4) then 1 else 0 end unassigned,
				 case when msg.messagestatusid = 2 then 1 else 0 end assigned,
				 case when msg.messagestatusid = 3 then 1 else 0 end actives,
				 case when msg.messagestatusid = 5 then 1 else 0 end pendingSend,
				 case when msg.messagestatusid = 6 then 1 else 0 end onTrack,
				 case when msg.messagestatusid in (7,8,9) then 1 else 0 end rejected,
				 case when msg.messagestatusid = 10 then 1 else 0 end abandonedsystem,
				 case when msg.messagestatusid = 11 then 1 else 0 end abandonedbyagent,
				 case when msg.messagestatusid in(6,10,11) then 1 else 0 end sendMail,
				 sum(case when msgun.messageid is null then 0 else 1 end) messageUnAssigned,
				 datediff(second,msg.date,isnull(msg.tqueue,getdate())) tQueue,
				 datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent,
				 msg.twait twait,
				 msg.twait + msg.tretention + msg.tresponse tatention,
				 msg.twrapup twrapup
				 from [message] msg
				 inner join [conversation] conv on msg.conversationId = conv.conversationId
				 left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
				 left join ccusers usuario on usuario.User_id = msg.userid
				 left join messageUnAssigned msgun on msg.UserId=msgun.UserId and msgun.messageId = msg.messageId
				 where msg.date >= @from AND msg.date < @to
				 group by msg.messageid,msg.date,inbo.descripcion,inbo.inbound_id,usuario.nombres,usuario.[User_Id],msg.messagestatusid,msg.tqueue,
				 msg.twait, msg.tretention, msg.tresponse, msg.twrapup, msg.tSend

				)x
				group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid,name,userId

end'
	EXEC(@sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccspRepCatalogos]---------'
	set @sql='ALTER PROCEDURE [dbo].[ccspRepCatalogos]
@type as tinyint,
@action tinyint = 0 -- 0 Filter select; 1 Filters Range
,@userId int =0 ---- se agrega parametro para filtros

AS
declare @tablatemp table (id int,
						description varchar(100) null)
declare @tempwork table
(idwg int)

if @action = 0
begin


	-- CAMPAIGNS
if @type = 1
begin

		if @userId <> 0 begin

			insert into @tablatemp
			select distinct caesp.IdCampEsp,'''' as description  from ccUsers us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
			inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1
			where us.[User_id] = @userId

			SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn
				from ccCamps camp
				inner join @tablatemp A on camp.cam_id = A.id

		end
		else begin
			SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn
				from ccCamps camp

		end
end


	-- DIAL RESULTS
	if @type = 2
	begin
		Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
		from ccTipoResultadoDial
		order by descripcion
	end

	-- WORKGROUPS
	if @type = 3
	begin
		if @userId <> 0 begin

			insert into @tempwork
			select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

			select distinct catwor.IDWG as id,catwor.WGName as description,''workgroupId'' as dbColumn from ccRIAWorkGroupUsers wgu
			inner join ccRIACat_WorkGroup catwor on wgu.IDWG = catwor.IDWG
			left join @tempwork temp on wgu.IDWG = temp.idwg
			where catwor.StatusWorkGroup = 1
			return
		end
		else  begin
			select idwg as id, wgname as description, ''workgroupId'' as dbColumn
			from ccRIACat_WorkGroup
			group by idwg, wgname	select * from ccRIACat_WorkGroup
			order by wgname
		end
  end


	-- AREAS
	if @type = 4
	begin
	if @userId <> 0 begin

			insert into @tablatemp
			select distinct wgu.User_id,caesp.IDArea  from ccUsers us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
			left join ccUsers caesp on wgu.IDWG = caesp.User_id
			where us.[User_id] = @userId

			select distinct idArea as id, AreaName as description, ''areaId'' as dbColumn
			from ccRIACat_Areas area inner join @tablatemp tem on area.IDArea = tem.id
			return
	end
		else begin

			select idArea as id, AreaName as description, ''areaId'' as dbColumn
			from ccRIACat_Areas
			group by idArea, AreaName
			order by AreaName
		end
	end

	-- DISPOSITIONS OUT
	if @type = 5
	begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalifOut
		order by [description]
	end

	-- USE
	if @type = 6
	begin
	if @userId <> 0 begin

			insert into @tempwork
					select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

			select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUsers us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

			inner join @tempwork awg on wgu.IDWG = awg.idwg
			where us.TipoUser_id = 1 and [status] = 1

			return
		end

		else begin

			SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
			FROM ccUsers B WHERE [status] = 1 and TipoUser_id = 1
			ORDER BY description
		end
	end

	-- ACDS**************
	if @type = 7
	begin
		if @userId <> 0 begin
				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''' as description  from ccUsers us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
				inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
				where us.[User_id] = @userId


				SELECT inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
					from ccinbound B
					inner join @tablatemp A on B.inbound_id = A.id
					return
			end
			else begin
				select inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
					from ccinbound
			end
	end

	-- DIDS
	if @type = 8
	begin
		select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
		from ccdnis
	end

	--DISPOSITIONS IN
	if @type = 9
	begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalif
		order by [description]
	end

	--SUBDISPOSITIONS IN
	if @type = 10
	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM ccTipoCalifSub
		order by [description]
	end

	--PROVIDER
	if @type = 11
	begin
		SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
		FROM cstoProvedor
		order by [description]
	end

	-- UNAVAILABLES
	if @type = 12
	begin
		SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
		FROM cctiponotready
		order by descripcion
	end

	-- DIALERS
	if @type = 13
	begin
		SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
		FROM ccoDialers
		order by descripcion
	end

	-- CallTYpes
	if @type = 14
	begin
			SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
			FROM ccStatusLlamada
		order by descripcion
	end

	-- SUBDISPOSITIONS OUT
	if @type = 21
	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM cctipocalifsubout
		order by [description]
	end

	-- AVRS TEMPLATE-SECTION
	if @type = 15
	begin
		SELECT c.id_concepto as id, (t.nombre+''-''+c.con_descripcion) as description, ''sectionId'' as dbColumn
		FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,nombre,MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato,nombre) as t
		ON f.id_formato = t.id_formato AND f.version = t.version INNER JOIN RIA_CONCEPTOS c
		ON t.id_formato = c.id_formato AND t.version = c.version
		order by f.nombre
	end

	-- AVRS TEMPLATES
	if @type = 16
	begin
		SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
		FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato) as t
		ON f.id_formato = t.id_formato AND f.version = t.version
		order by f.nombre
	end

	-- AVRS SUPERVISOR
	if @type = 17
	begin
		SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
		FROM ccUsers
		WHERE [status] = 1
		and TipoUser_id = 2
		ORDER BY [login]
	end

	select * from ccUsers

	--Status Call
	if @type = 25
	begin
		begin
		select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
		from ccstatusllamada
		order by [descripcion]
	end
	end
end
-----------------------------------------------------------
if @action = 1
begin
	-- TRUNKS
	if @type = 13
	begin
		SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
	end

	-- AVRS DISPOSITION
	if @type = 18
	begin
		SELECT 0 as [min], 100 as [max],''Disposition'' as dbColumn
	end

	-- AVG DISPOSITION
	if @type = 19
	begin
		SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
	end

	-- SCORE
	if @type = 20
	begin
		SELECT 0 as [min], 100 as [max],''score'' as dbColumn
	end
end'
	EXEC(@sql)


	set @process = 'ALTER procedure [dbo].[ccspRepEmailDetail]---------'
	set @sql='ALTER procedure [dbo].[ccspRepEmailDetail]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepEmailDetail with(rowlock)
	where date >= @from AND date < @to

	insert into RepEmailDetail
	select msg.date date,
	case when msg.messagestatusid = 1 then ''systemTranslated_Download_emails_from_server''
	when msg.messagestatusid = 2 then ''systemTranslated_Assign_message_to_agent''
	when msg.messagestatusid = 3 then ''systemTranslated_Read_the_message_agent''
	when msg.messagestatusid = 4 then ''systemTranslated_Unassign_message_to_agent''
	when msg.messagestatusid = 5 then ''systemTranslated_Message_answered_by_agent''
	when msg.messagestatusid = 6 then ''systemTranslated_Message_sent_to_the_client''
	when msg.messagestatusid in (7,8,9) then ''systemTranslated_Message_rejected_for_server''
	when msg.messagestatusid = 10 then ''systemTranslated_conversation_closed_for_system''
	when msg.messagestatusid = 11 then ''systemTranslated_Close_conversation_for_agent'' else '''' end statusMail,
	conv.mailClient mailClient, isnull(inbo.descripcion,'''') descripcion,
	isnull(inbo.inbound_id,0) inboundid, msg.conversationId conversationid,msg.messageId,
	msg.messagestatusid messagestatusid,
	isnull(datediff(second,msg.[date],isnull(msg.tqueue,getdate())),0) tQueue, msg.twait,
	isnull((msg.twait + msg.tretention + msg.tresponse),0) tAtentionMultimedia, msg.twrapup,
	isnull(datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend),0) tsent,
	datepart(yyyy,date) [year],
	datepart(mm,date) [mounth],
	datepart(dd,date) [day],
	datepart(hh,date) [hour],
	datepart(mi,date) [minute]
	from [message] msg inner join [conversation] conv
	on msg.conversationId = conv.conversationId left join [ccInbound] inbo
	on inbo.inbound_Id = conv.inboundId
	left join ccusers usuario on usuario.User_id = msg.userid  left join messageUnAssigned msgun on msg.messageid = msgun.messageid
	where msg.date >= @from AND msg.date < @to
	order by date,msg.conversationId,msg.messageId

end'
	EXEC(@sql)


	set @process = 'ALTER procedure [dbo].[ccspRepEmailGeneral]------'
	set @sql='ALTER procedure [dbo].[ccspRepEmailGeneral]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepEmailGeneral with(rowlock) where date >= @from AND date < @to

	insert into RepEmailGeneral
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),isnull(descripcion,'''') descripcion ,inboundid,
	case max(messagestatusid) when 1 then ''systemTranslated_Download_emails_from_server''
	when 2 then ''systemTranslated_Assign_message_to_agent''
	when 3 then ''systemTranslated_Read_the_message_agent''
	when 4 then ''systemTranslated_Unassign_message_to_agent''
	when 5 then ''systemTranslated_Message_answered_by_agent''
	when 6 then ''systemTranslated_Message_sent_to_the_client''
	when 7 then ''systemTranslated_Message_rejected_for_server''
	when 8 then ''systemTranslated_Message_rejected_for_server''
	when 9 then ''systemTranslated_Message_rejected_for_server''
	when 10 then ''systemTranslated_conversation_closed_for_system''
	when 11 then ''systemTranslated_Close_conversation_for_agent'' else '''' end statusMail,
	isnull(max(messagestatusid),0) messagestatusid,
	isnull(min(mailClient),'''') mailClient,
	conversationId, isnull(sum(tQueue),0) as [tQueueMultimedia],
	isnull(sum(twait),0) as  [twaitMultimedia], isnull(sum(tAtentionMultimedia),0) tAtentionMultimedia, isnull(sum(twrapup),0) twrapup,
	isnull(sum(tsent),0) tsent,
	datepart(yyyy,min(date)) [year],
	datepart(mm,min(date)) [mounth],
	datepart(dd,min(date)) [day],
	datepart(hh,min(date)) [hour],
	datepart(mi,min(date)) [minute]
from(

select
	msg.date date,
	conv.mailClient mailClient, isnull(inbo.descripcion,'''') descripcion,
	isnull(inbo.inbound_id,0) inboundid, msg.conversationId conversationid,
	msg.messagestatusid messagestatusid,
	isnull(datediff(second,msg.[date],isnull(msg.tqueue,getdate())),0) tQueue, msg.twait,
	isnull((msg.twait + msg.tretention + msg.tresponse),0) tAtentionMultimedia, msg.twrapup,
	isnull(datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend),0) tsent
	from [message] msg inner join [conversation] conv
	on msg.conversationId = conv.conversationId
	left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
	left join ccusers usuario on usuario.User_id = msg.userid
	where msg.date >= @from AND msg.date < @to
	)x
	group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion,inboundid,conversationId

end'
	EXEC(@sql)


set @process = 'Alter SP -- GetDefaultChart'
		set @sql='ALTER PROCEDURE [dbo].[GetDefaultChart] @id int
AS
BEGIN
	select reportName, case chartType when 1 then 1 else 2 end as chartType,
	CONVERT(varchar(1),chartType) +''|''+
	case when chartType = 1 then x1
	when x1='''' then subX1
	ELSE x1 + ''|'' + subX1 end as columns, countColumn, chartDescription, isTime
	from ReportsCharts
	WHERE id = @id
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