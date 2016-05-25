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
set @version = 37

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

		set @process = 'Drop table Twitter'
		set @sql='if exists(select * from sys.tables where name=''RepTwitterACD'') DROP TABLE RepTwitterACD
if exists(select * from sys.tables where name=''RepTwitterAgente'') DROP TABLE RepTwitterAgente
if exists(select * from sys.tables where name=''RepTwitterDetail'') DROP TABLE RepTwitterDetail
if exists(select * from sys.tables where name=''RepTwitterGeneral'') DROP TABLE RepTwitterGeneral'
		EXEC(@sql)

		set @process = 'Drop Column exists RepAgentGI.treq'
		set @sql='if exists (select * from sys.columns where name = N''treq'' and Object_ID = Object_ID(N''RepAgentGI'')) ALTER TABLE RepAgentGI DROP COLUMN treq'
		EXEC(@sql)


		set @process = 'Drop table exists RepSpecialAbndCamp'
		set @sql='if exists(select * from sys.tables where name=''RepSpecialAbndCamp'') Drop table RepSpecialAbndCamp'
		EXEC(@sql)

		set @process = 'Drop table exists RepOutDispositionsContacOwner'
		set @sql='if exists(select * from sys.tables where name=''RepOutDispositionsContacOwner'') Drop table RepOutDispositionsContacOwner'
		EXEC(@sql)

		set @process = 'Drop table RepIVRSurveys'
		set @sql='if exists(select * from sys.tables where name=''RepIVRSurveys'') DROP TABLE RepIVRSurveys'
		EXEC(@sql)


		set @process = 'DROP PROCEDURE ccspRepSpecialAbndCamp'
		set @sql='if exists(select * from sys.procedures where name=''ccspRepSpecialAbndCamp'') DROP PROCEDURE ccspRepSpecialAbndCamp'
		EXEC(@sql)

		set @process = 'DROP PROCEDURE ccspRepOutDispositionsContacOwner'
		set @sql='if exists(select * from sys.procedures where name=''ccspRepOutDispositionsContacOwner'') DROP PROCEDURE ccspRepOutDispositionsContacOwner'
		EXEC(@sql)


		set @process = 'Drop PROCEDURE -------- ccspRepIVRSurveys'
		set @Sql= 'if exists (select * from sys.procedures where name = N''ccspRepIVRSurveys'') drop procedure ccspRepIVRSurveys'
		EXEC(@Sql)


		set @process = 'Delete Filter Mail (10010,10020,10030,10040)'
		set @sql='delete from ReportsFilters where id in(10010,10020,10030,10040)'
		EXEC(@sql)


		set @process = 'Delete Filter date,FilterBy and ReportsTotals Twitter(11010,11020,11030,11040)'
		set @sql='delete from ReportsFiltersMenus where idReport in(11010,11020,11030,11040)
		delete from ReportsTotals where id in(11010,11020,11030,11040)'
		EXEC(@sql)

		set @process = 'delete TranslatedReports Twitter-- (11030,11040, 10030, 10040)'
		set @sql='delete from TranslatedReports where id  in (11030,11040, 10030, 10040)'
		EXEC(@sql)

		set @process = 'Delete exists RepOutDispositionsContacOwner'
		set @sql='delete from ReportsCharts where id=4160
		delete from ReportsFiltersMenus where idReport=4160
		delete from ReportsFilters where id=4160
		delete from ReportsCharts where id=4160'
		EXEC(@sql)

		set @process = 'DISABLE TRIGGER MSmerge_tr_altertable ---------'
		set @Sql= 'IF EXISTS (SELECT * FROM sys.triggers WHERE [name] = N''MSmerge_tr_altertable'' AND type in (N''TR'') AND is_disabled = 0) DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE'
		EXEC(@Sql)

		set @process = 'alter table  ccTipoCalifSub---------'
		 set @Sql= 'if not exists (select * from sys.columns where name = N''contactOwner'' and Object_ID = Object_ID(N''ccTipoCalifSub'')) alter table ccTipoCalifSub add contactOwner bit not null'
		 EXEC(@Sql)

		 set @process = 'alter table  ccTipoCalifSubOUT---------'
		 set @Sql= 'if not exists (select * from sys.columns where name = N''contactOwner'' and Object_ID = Object_ID(N''ccTipoCalifSubOUT'')) alter table ccTipoCalifSubOUT add contactOwner bit not null'
		 EXEC(@Sql)
	
		set @process = 'Add Column ccTipoCalifOUT.contactOwner'
		set @sql='if not exists (select * from sys.columns where name = N''contactOwner'' and Object_ID = Object_ID(N''ccTipoCalifOUT'')) ALTER TABLE ccTipoCalifOUT ADD [contactOwner] [bit] NULL'
		 EXEC(@sql)

		set @process = 'Add Column ccTipoCalifSubOUT.contactOwner'
		set @sql='if not exists (select * from sys.columns where name = N''contactOwner'' and Object_ID = Object_ID(N''ccTipoCalifSubOUT'')) ALTER TABLE ccTipoCalifSubOUT ADD [contactOwner] [bit] NULL'
		EXEC(@sql)

		 set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
		 set @Sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE [name] = N''MSmerge_tr_altertable'' AND type in (N''TR'') AND is_disabled = 1) ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE'
		EXEC(@Sql)

		set @process = 'Add column  tfocus -- RepEmailDetail and RepEmailGeneral'
		set @sql='if not exists (select * from sys.columns where name = N''tfocus'' and Object_ID = Object_ID(N''RepEmailDetail'')) alter table RepEmailDetail add tfocus int
if not exists (select * from sys.columns where name = N''tfocus'' and Object_ID = Object_ID(N''RepEmailGeneral'')) alter table RepEmailGeneral add tfocus int'
		EXEC(@sql)

		set @process = 'ADD COLUMN -------- PivotReports'
		set @Sql= 'if not exists (select * from sys.columns where name = N''isGroupPivot'' and Object_ID = Object_ID(N''PivotReports'')) alter table PivotReports add isGroupPivot bit'
		EXEC(@Sql)

		set @process = 'Alter column -- RepOutCallBilling.costo'
		set @sql='alter table RepOutCallBilling alter column costo decimal(10,2)'
		EXEC(@sql)

		set @process = 'Update ReportsTotals and  GroupByReports delete column treq'
		set @sql='update ReportsTotals set totalColumns=
''sum:nxferin|sum:nanswerin|sum:nabndxferin|sum:nabndringin|sum:nabnddlgin|sum:abndaxferin|sum:nnoanswerin|sum:nlostin|sum:tdialogin|sum:tnotesin|sum:tringin|sum:txferin|sum:nxferout|sum:nanswerout|sum:nabndxferout|sum:nabndringout|sum:nabnddlgout|sum:abndaxferout|sum:nnoanswerout|sum:nlostout|sum:tdialogout|sum:tnotesout|sum:tringout|sum:txferout|sum:nother|sum:tunknown|sum:tnotav|sum:tlog|sum:tav|sum:tother|sum:tprob|sum:nmohin|sum:nmohout|sum:nwhagin|sum:nwhagout|sum:nwhcliin|sum:nwhcliout|special:tnotavg:isnull(sum([tdialogin]+[tdialogout])/nullif(sum([nanswerin]+[nanswerout]),0),0)''
where id=2010
update GroupByReports  set [columns]=
''userId|max([user]):user|max([login]):login|sum([nxferin]):nxferin|sum([nanswerin]):nanswerin|sum([nabndxferin]):nabndxferin|sum([nabndringin]):nabndringin|sum([nabnddlgin]):nabnddlgin|sum([abndaxferin]):abndaxferin|sum([nnoanswerin]):nnoanswerin|sum([nlostin]):nlostin|sum([tdialogin]):tdialogin|sum([tnotesin]):tnotesin|sum([tringin]):tringin|sum([txferin]):txferin|sum([nxferout]):nxferout|sum([nanswerout]):nanswerout|sum([nabndxferout]):nabndxferout|sum([nabndringout]):nabndringout|sum([nabnddlgout]):nabnddlgout|sum([abndaxferout]):abndaxferout|sum([nnoanswerout]):nnoanswerout|sum([nlostout]):nlostout|sum([tdialogout]):tdialogout|sum([tnotesout]):tnotesout|sum([tringout]):tringout|sum([txferout]):txferout|sum([nother]):nother|sum([tunknown]):tunknown|sum([tnotav]):tnotav|sum([tlog]):tlog|sum([tav]):tav|sum([tother]):tother|sum([tprob]):tprob|sum([nmohin]):nmohin|sum([nmohout]):nmohout|sum([nwhagin]):nwhagin|sum([nwhagout]):nwhagout|sum([nwhcliin]):nwhcliin|sum([nwhcliout]):nwhcliout|isnull(sum([tdialogin]+[tdialogout])/nullif(sum([nanswerin]+[nanswerout])_0)_0):tnotavg''
	WHERE id = 2010		'
		EXEC(@sql)

		set @process = 'Update PivotReports(4060) Costo'
		set @sql='update PivotReports set pivotFunction=''sum'',complementColumns=''date|campaignId|campaign|userId|agentName|username|providerId|provider''  where id=4060'
		EXEC(@sql)


		set @process = 'Update RepEmailDetail and RepEmailDetail column tfocus valueo (0)'
		set @sql='update RepEmailDetail set tfocus=0
update RepEmailGeneral set tfocus=0'
		EXEC(@sql)


		set @process = 'INSERT -------- ReportsFiltersMenus'
		set @Sql= 'if not exists(select * from ReportsFiltersMenus where idReport = 6050) begin
insert into ReportsFiltersMenus values (6050, ''date'')
insert into ReportsFiltersMenus values(6050, ''filterby'')
end'
		EXEC(@Sql)

		set @process = 'INSERT -------- ReportsTotals'
		set @Sql= 'if not exists(select * from ReportsTotals where id = 6050) insert into ReportsTotals values (6050, '''')'
		EXEC(@Sql)

		set @process = 'Rename Columnas InboundId because filters Mail'
		set @sql='if exists (select * from sys.columns where name = N''inboundid'' COLLATE Latin1_General_CS_AS  and Object_ID = Object_ID(N''RepEmailACD''))
    exec sp_RENAME ''RepEmailACD.[inboundid]'' , ''inboundId'', ''COLUMN''
if exists (select * from sys.columns where name = N''inboundid'' COLLATE Latin1_General_CS_AS  and Object_ID = Object_ID(N''RepEmailDetail''))
    exec sp_RENAME ''RepEmailDetail.[inbounid]'' , ''inboundId'', ''COLUMN''
if exists (select * from sys.columns where name = N''inboundid'' COLLATE Latin1_General_CS_AS  and Object_ID = Object_ID(N''RepEmailGeneral''))
    exec sp_RENAME ''RepEmailGeneral.[inbounid]'' , ''inboundId'', ''COLUMN''
if exists (select * from sys.columns where name = N''inboundid'' COLLATE Latin1_General_CS_AS  and Object_ID = Object_ID(N''RepEmailAgente''))
    exec sp_RENAME ''RepEmailAgente.[inbounid]'' , ''inboundId'', ''COLUMN''
if exists (select * from sys.columns where name = N''userid'' COLLATE Latin1_General_CS_AS  and Object_ID = Object_ID(N''RepEmailAgente''))
    exec sp_RENAME ''RepEmailAgente.[userid]'' , ''userId'', ''COLUMN'''
		EXEC(@sql)

		set @process = 'CREATE TABLE -------- RepIVRSurveys'
		set @Sql= 'create table RepIVRSurveys(
[date] datetime not null,
[userId] smallint not null,
[login] varchar(20) not null,
[scriptId] int not null,
[surveyId] int not null,
[survey] varchar(MAX) not null,
[calId] int not null,
[calKey] varchar(20) not null,
[campaignId] [int] NOT NULL,
[inboundId] [int] NOT NULL,
[campACDDescription] varchar(40) not null,
[questionId] int not null,
[questionDescription] varchar(MAX) not null,
[question_Count] varchar(MAX) not null,
[Count] varchar(MAX) not null,
[year] int not null,
[month] int not null,
[day] int not null,
[hour] int not null,
[minutes] int not null
)'
		EXEC(@Sql)

		set @process = 'CREATE table -- RepSpecialAbndCamp'
		set @sql='CREATE TABLE [dbo].[RepSpecialAbndCamp](
[date] [datetime] NOT NULL,
[campaignId] [int] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[total] [smallint] NOT NULL,
[abandonedCalls] [smallint] NOT NULL,
[abandonedCallsPctg] [decimal](5, 2) NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		EXEC(@Sql)


		set @process = 'CREATE table -- RepOutDispositionsContacOwner'
		set @sql='CREATE TABLE [dbo].[RepOutDispositionsContacOwner](
[date] [datetime] NOT NULL,
[campaignId] [int] NOT NULL,
[campaign] [varchar](255) NOT NULL,
[total] [smallint] NOT NULL,
[dispositionContactOwner] [smallint] NOT NULL,
[dispositionContactOwnerPctg] [decimal](6, 3) NOT NULL,
[year] [int] NOT NULL,
[month] [int] NOT NULL,
[day] [int] NOT NULL,
[hour] [int] NOT NULL,
[minutes] [int] NOT NULL
) ON [PRIMARY]'
		EXEC(@sql)

		set @process = 'CREATE TABLE -- RepTwitterACD'
		set @sql='CREATE TABLE [dbo].[RepTwitterACD](
[date] [datetime] NOT NULL,
[inbound] [varchar](50) NOT NULL,
[inbounId] [smallint] NOT NULL,
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

		set @process = 'CREATE TABLE --RepTwitterAgente'
		set @sql='CREATE TABLE [dbo].[RepTwitterAgente](
[date] [datetime] NOT NULL,
[agentName] [varchar](45) NOT NULL,
[userid] [int] NOT NULL,
[inbound] [varchar](50) NOT NULL,
[inbounId] [smallint] NOT NULL,
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

		set @process = 'CREATE TABLE --RepTwitterDetail'
		set @sql='CREATE TABLE [dbo].[RepTwitterDetail](
	[date] [datetime] NOT NULL,
	[statusTwetter] [varchar](255) NOT NULL,
	[mailClient] [varchar](60) NOT NULL,
	[inbound] [varchar](50) NOT NULL,
	[inbounId] [smallint] NOT NULL,
	[conversationid] [int] NOT NULL,
	[messageId] [int] NOT NULL,
	[messagestatusid] [int] NOT NULL,
	[tQueueMultimedia] [int] NOT NULL,
	[twaitMultimedia] [int] NOT NULL,
	[tAtentionMultimedia] [int] NOT NULL,
	[twrapup] [int] NOT NULL,
	[tsend] [int] NOT NULL,
	[tfocus] [int] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]'
		EXEC(@sql)

		set @process = 'CREATE TABLE --RepTwitterGeneral'
		set @sql='CREATE TABLE [dbo].[RepTwitterGeneral](
	[date] [datetime] NOT NULL,
	[inbound] [varchar](50) NOT NULL,
	[inbounId] [smallint] NOT NULL,
	[statusTwetter] [varchar](255) NOT NULL,
	[messagestatusid] [int] NOT NULL,
	[mailClient] [varchar](60) NOT NULL,
	[conversationid] [int] NOT NULL,
	[tQueueMultimedia] [int] NOT NULL,
	[twaitMultimedia] [int] NOT NULL,
	[tAtentionMultimedia] [int] NOT NULL,
	[twrapup] [int] NOT NULL,
	[tsend] [int] NOT NULL,
	[tfocus] [int] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]'
		EXEC(@sql)

			set @process = 'CREATE Index -- RepIVRSurveys.IX_RepIVRSurveys'
	set @sql='if exists (select * from sys.indexes where name = N''IX_RepIVRSurveys'' and object_id = OBJECT_ID(N''RepIVRSurveys''))
	    begin
	        CREATE NONCLUSTERED INDEX [IX_RepIVRSurveys] ON [dbo].[RepIVRSurveys]
			(
				[date] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	    end'
    EXEC(@sql)

	set @process = 'CREATE Index -- RepSpecialAbndCamp.IX_RepSpecialAbndCamp'
	set @sql='if exists (select * from sys.indexes where name = N''IX_RepSpecialAbndCamp'' and object_id = OBJECT_ID(N''RepSpecialAbndCamp''))
	    begin
	        CREATE NONCLUSTERED INDEX [IX_RepSpecialAbndCamp] ON [dbo].[RepSpecialAbndCamp]
			(
				[date] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	    end'
    EXEC(@sql)

	set @process = 'CREATE Index -- RepOutDispositionsContacOwner.IX_RepOutDispositionsContacOwner'
	set @sql='if exists (select * from sys.indexes where name = N''IX_RepOutDispositionsContacOwner'' and object_id = OBJECT_ID(N''RepOutDispositionsContacOwner''))
	    begin
	        CREATE NONCLUSTERED INDEX [IX_RepOutDispositionsContacOwner] ON [dbo].[RepOutDispositionsContacOwner]
			(
				[date] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	    end'
    EXEC(@sql)

	set @process = 'CREATE Index -- RepTwitterACD.IX_RepTwitterACD'
	set @sql='if exists (select * from sys.indexes where name = N''IX_RepTwitterACD'' and object_id = OBJECT_ID(N''RepTwitterACD''))
	    begin
	        CREATE NONCLUSTERED INDEX [IX_RepTwitterACD] ON [dbo].[RepTwitterACD]
			(
				[date] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	    end'
    EXEC(@sql)

	set @process = 'CREATE Index -- RepTwitterAgente.IX_RepTwitterAgente'
	set @sql='if exists (select * from sys.indexes where name = N''IX_RepTwitterAgente'' and object_id = OBJECT_ID(N''RepTwitterAgente''))
	    begin
	        CREATE NONCLUSTERED INDEX [IX_RepTwitterAgente] ON [dbo].[RepTwitterAgente]
			(
				[date] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	    end'
    EXEC(@sql)

	set @process = 'CREATE Index -- RepTwitterDetail.IX_RepTwitterDetail'
	set @sql='if exists (select * from sys.indexes where name = N''IX_RepTwitterDetail'' and object_id = OBJECT_ID(N''RepTwitterDetail''))
	    begin
	        CREATE NONCLUSTERED INDEX [IX_RepTwitterDetail] ON [dbo].[RepTwitterDetail]
			(
				[date] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	    end'
    EXEC(@sql)

	set @process = 'CREATE Index -- RepTwitterGeneral.IX_RepTwitterGeneral'
	set @sql='if exists (select * from sys.indexes where name = N''IX_RepTwitterGeneral'' and object_id = OBJECT_ID(N''RepTwitterGeneral''))
	    begin
	        CREATE NONCLUSTERED INDEX [IX_RepTwitterGeneral] ON [dbo].[RepTwitterGeneral]
			(
				[date] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	    end'
    EXEC(@sql)



		set @process = 'UPDATE -------- PivotReports'
		set @Sql= 'update PivotReports set isGroupPivot = 1'
		EXEC(@Sql)

		set @process = 'INSERT -------- PivotReports'
		set @Sql= 'if not exists(select * from PivotReports where id = 6050) insert into PivotReports values (6050, ''question_Count'', ''date|userId|login|scriptId|surveyId|survey|calId|calKey|campaignId|inboundId|campACDDescription'', ''max'', 0)
		else update PivotReports set isGroupPivot = 0 where id=6050'
		EXEC(@sql)


		set @process = 'Add Filter date,FilterBy'
		set @sql='if not exists(select * from ReportsFiltersMenus where idReport=4150)
		begin
			INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) values (4150, ''date'')
			INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) values (4150, ''filterby'')
		end'

		EXEC(@sql)
		set @process = 'Add Filter by campaigns'
		set @sql='if not exists(select * from ReportsFilters where id=4150)
		begin
			INSERT INTO ReportsFilters (id,reportName, filterName) values (4150,''Abandoned calls'', ''campaigns'')
		end'

		EXEC(@sql)

		set @process = 'Add ReportsTotals -- 4150'
		set @sql='if not exists(select * from ReportsTotals where id=4150)
		begin
			INSERT INTO ReportsTotals (id, totalColumns) VALUES (4150,''special:abandonedCallsPctg:convert(decimal(10_2)_ISNULL((sum(AbandonedCalls) * 100.00)/NULLIF(sum(total)_0)_0))|sum:abandonedCalls|sum:total'');
		end'

		EXEC(@sql)

		set @process = 'insert ReportsCharts -- 4150'
		set @sql='if not exists(select * from ReportsCharts where id=4150)
		begin
			insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
			values(4150,''Abandoned calls by campaign'',1,''hour'','''','''','''',''sum([abandonedCalls])'',''Abandoned calls by Hour'',0)
			insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
			values(4150,''Abandoned calls by campaign'',3,'''',''hour'','''','''',''isnull(sum([abandonedCalls]),0)'',''Abandoned calls by Hour'',0)
		end'
		EXEC(@sql)



	set @process = 'Add Filter date,FilterBy'
	set @sql='if not exists(select * from ReportsFiltersMenus where idReport=4160) begin
INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) values (4160, ''date'')
INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) values (4160, ''filterby'')
end'
	EXEC(@sql)

	set @process = 'Add Filter by campaigns'
	set @sql='if not exists(select * from ReportsFilters where id=4160) begin
INSERT INTO ReportsFilters (id,reportName, filterName) values (4160,''Abandoned calls'', ''campaigns'')
end'
	EXEC(@sql)

	set @process = 'Add ReportsTotals -- 4160'
	set @sql='if not exists(select * from ReportsTotals where id=4160) begin
INSERT INTO ReportsTotals (id, totalColumns) VALUES (4160,''special:abandonedCallsPctg:convert(decimal(10_2)_ISNULL((sum(AbandonedCalls) * 100.00)/NULLIF(sum(total)_0)_0))|sum:abandonedCalls|sum:total'');
end'
	EXEC(@Sql)

	set @process = 'insert ReportsCharts -- 4160'
	set @sql='if not exists(select * from ReportsCharts where id=4160) begin
		insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
		values(4160,''Report Dispositions by hour'',1,''hour'','''','''','''',''sum([dispositionContactOwner])'',''Dispositions by hour'',0)

		insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
		values(4160,''Report Dispositions by hour'',3,'''',''hour'','''','''',''isnull(sum([dispositionContactOwner]),0)'',''Dispositions by hour'',0)
	end'
	EXEC(@sql)

	set @process = 'insert into --TranslatedReports  Mail Twitter Status Message(11030,11040, 10030, 10040)'
	set @sql='if not exists(select * from TranslatedReports where id  in (11030,11040, 10030, 10040)) begin
	insert into TranslatedReports values(11040,''statusTwetter'')
	insert into TranslatedReports values(11030,''statusTwetter'')
	insert into TranslatedReports values(10030,''statusMail'')
	insert into TranslatedReports values(10040,''statusMail'')
end'
	EXEC(@sql)

	set @process = 'Add Filter date,FilterBy Twitter (11010,11020,11030,11040)'
	set @sql='if not exists(select * from ReportsFiltersMenus where idReport  in(11010,11020,11030,11040)) begin
INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) values (11010, ''date'')
INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) values (11010, ''filterby'')

INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) values (11020, ''date'')
INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) values (11020, ''filterby'')

INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) values (11030, ''date'')
INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) values (11030, ''filterby'')

INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) values (11040, ''date'')
INSERT INTO ReportsFiltersMenus (idReport, filterMenuName) values (11040, ''filterby'')
end'
	EXEC(@sql)

		set @process = 'Change ReportsTotals Twitter'
		set @sql='if not exists(select * from ReportsTotals where id in(11010,11020,11030,11040)) begin
INSERT INTO ReportsTotals (id, totalColumns) VALUES (11010,''sum:download|sum:unassignedMultimedia|sum:ontrack|sum:rejected|sum:assigned|sum:totalAssets|sum:pendingSend|sum:abandonedSystem|sum:abandonedAgent|sum:finishedConversation|sum:avgSend|sum:tQueueMultimedia|sum:tsend|sum:twaitMultimedia|sum:tAvgAtentionMultimedia|sum:twrapup'')
INSERT INTO ReportsTotals (id, totalColumns) VALUES (11020,''sum:download|sum:messageUnAssigned|sum:ontrack|sum:rejected|sum:assigned|sum:totalAssets|sum:pendingSend|sum:abandonedSystem|sum:abandonedAgent|sum:finishedConversation|avg:avgSend|sum:tQueueMultimedia|sum:tsend|sum:twaitMultimedia|sum:tAvgAtentionMultimedia|sum:twrapup'')
INSERT INTO ReportsTotals (id, totalColumns) VALUES (11030,''sum:tQueueMultimedia|sum:twaitMultimedia|sum:tAtentionMultimedia|sum:twrapup|sum:twrapup|sum:tsend|sum:tfocus'')
INSERT INTO ReportsTotals (id, totalColumns) VALUES (11040,''sum:tQueueMultimedia|sum:twaitMultimedia|sum:tAtentionMultimedia|sum:twrapup|sum:tsend|sum:tfocus'')
end'
		EXEC(@sql)

		set @process = 'Change ReportsTotals Mail'
		set @sql='if not exists(select * from ReportsTotals where id in(10010,10020,10030,10040)) begin
INSERT INTO ReportsTotals (id, totalColumns) VALUES (10010,''sum:download|sum:unassignedMultimedia|sum:ontrack|sum:rejected|sum:assigned|sum:totalAssets|sum:pendingSend|sum:abandonedSystem|sum:abandonedAgent|sum:finishedConversation|avg:avgSend|sum:tQueueMultimedia|sum:tsend|sum:twaitMultimedia|sum:tAvgAtentionMultimedia|sum:twrapup'')
INSERT INTO ReportsTotals (id, totalColumns) VALUES (10020,''sum:download|sum:messageUnAssigned|sum:ontrack|sum:rejected|sum:assigned|sum:totalAssets|sum:pendingSend|sum:abandonedSystem|sum:abandonedAgent|sum:finishedConversation|avg:avgSend|sum:tQueueMultimedia|sum:tsend|sum:twaitMultimedia|sum:tAvgAtentionMultimedia|sum:twrapup'')
INSERT INTO ReportsTotals (id, totalColumns) VALUES (10030,''sum:tQueueMultimedia|sum:twaitMultimedia|sum:tAtentionMultimedia|sum:twrapup|sum:tsend|sum:tfocus'')
INSERT INTO ReportsTotals (id, totalColumns) VALUES (10040,''sum:tQueueMultimedia|sum:twaitMultimedia|sum:tAtentionMultimedia|sum:twrapup|sum:tsend|sum:tfocus'')
end '
		EXEC(@sql)

			set @process = 'Add Filter ACD and Agents Mail'
		set @sql='if not exists(select * from ReportsFilters where  id in(10010,10020,10030,10040)) begin
 INSERT INTO ReportsFilters (id,reportName, filterName)  values(10010,''RepEmailACD'',''acds'')
 INSERT INTO ReportsFilters (id,reportName, filterName)  values(10020,''RepEmailAgente'',''acds'')
 INSERT INTO ReportsFilters (id,reportName, filterName)  values(10020,''RepEmailAgente'',''users'')
 INSERT INTO ReportsFilters (id,reportName, filterName)  values(10030,''RepEmailDetail'',''acds'')
 INSERT INTO ReportsFilters (id,reportName, filterName)  values(10040,''RepEmailGeneral'',''acds'')
end'
	EXEC(@sql)

		set @process = 'Add Filter ACD and Agents Twitter'
		set @sql='if not exists(select * from ReportsFilters where  id in(11010,11020,11020,11040)) begin
 INSERT INTO ReportsFilters (id,reportName, filterName)  values(11010,''RepEmailACD'',''acds'')
 INSERT INTO ReportsFilters (id,reportName, filterName)  values(11020,''RepEmailAgente'',''acds'')
 INSERT INTO ReportsFilters (id,reportName, filterName)  values(11020,''RepEmailAgente'',''users'')
 INSERT INTO ReportsFilters (id,reportName, filterName)  values(11030,''RepEmailDetail'',''acds'')
 INSERT INTO ReportsFilters (id,reportName, filterName)  values(11040,''RepEmailGeneral'',''acds'')
end'
	EXEC(@sql)

	set @process = 'INSERT -------- Filters --Revisar Raul'
		set @Sql= 'if not exists(select * from Filters where id = 28) begin
insert into Filters values(28, ''survey'', 26, ''Surveys'', ''Survey'')
end'
		EXEC(@Sql)

		set @process = 'INSERT -------- ReportsFilters---Revisar Raul'
		set @Sql= 'if not exists(select * from ReportsFilters where id = 6050) begin
insert into ReportsFilters values(''IVR Surveys'', ''acds'', ''6050'')
insert into ReportsFilters values(''IVR Surveys'', ''campaigns'', ''6050'')
insert into ReportsFilters values(''IVR Surveys'', ''users'', 6050)
insert into ReportsFilters values (''IVR Surveys'', ''survey'', 6050)
end'
		EXEC(@Sql)


		set @process = 'INSERT -------- ReportsCharts'
		set @Sql= 'if not exists(select * from ReportsCharts where id in (10010, 10020, 10030, 10040, 11010, 11020, 11030, 11040)) begin
insert into ReportsCharts values (10010, ''Email by ACD'', 1, ''inbound'', '''', '''', '''', ''sum([download])'', ''Download Emails by ACD Group'', 0)
insert into ReportsCharts values (10020, ''Email by Agent'', 1, ''agentName'', '''', '''', '''', ''sum([download])'', ''Download Emails by Agent'', 0)
insert into ReportsCharts values (10030, ''Email Detail'', 1, ''inbound'', '''', '''', '''', ''count(messageId)'', ''Total Email Messages by ACD Group'', 0)
insert into ReportsCharts values (10040, ''Email General'', 1, ''inbound'', '''', '''', '''', ''count(conversationid)'', ''Total Email Conversations by ACD Group'', 0)
insert into ReportsCharts values (11010, ''Twitter ACD'', 1, ''inbound'', '''', '''', '''', ''sum([download])'', ''Download Tweets by ACD Group'', 0)
insert into ReportsCharts values (11020, ''Agent Twitter'', 1, ''agentName'', '''', '''', '''', ''sum([download])'', ''Download Tweets by Agent'', 0)
insert into ReportsCharts values (11030, ''Twitter Detail'', 1, ''inbound'', '''', '''', '''', ''count(messageId)'', ''Total Tweet Messages by ACD Group'', 0)
insert into ReportsCharts values (11040, ''Twitter General'', 1, ''inbound'', '''', '''', '''', ''count(conversationid)'', ''Total Twitter Conversations by ACD Group'', 0)
end'
		EXEC(@Sql)

		set @process = 'CREATE PROCEDURE -------- ccspRepIVRSurveys'
		set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepIVRSurveys]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
  if @from is null
    select @from = convert(datetime,convert(varchar(14),getdate(),121)+ ''00'',121)
  if @to is null
    select @to = getdate()


delete RepIVRSurveys with(rowlock)
  where [date] between @from and @to


insert RepIVRSurveys select [date],userId,[login],scriptId,surveyId,survey,calId,calKey,campaignId,inboundId,campACDDescription,
questionId,questionDescription,question_Count,[Count],[year],[month],[day],[hour],[minutes]
from
(
	select distinct
	cci.cal_Inicio as [date],
	isnull(cci.User_id, 0) as ''userId'',
	isnull(ccu.Login, ''No agent'') as ''login'',
	isnull(ivro.IVR_id, 0) as ''scriptId'',
	isnull(s.surveyId, 0) as ''surveyId'',
	isnull(s.description, '''') as ''survey'',
	isnull(cci.cal_id, 0) as ''calId'',
	isnull(cci.cal_Key, '''') as ''calKey'',
	0 as ''campaignId'',
	isnull(cci.Inbound_id, '''') as ''inboundId'',
	''ACD - '' + isnull(ccin.descripcion,'''') as ''campACDDescription'',
	isnull(ivro.questionId, 0) as ''questionId'',
	isnull(sq.description,'''') as ''questionDescription'',
	isnull(sq.description,'''')+ ''_Count'' as ''question_Count'',
	case when ivro.selectedOption = '''' then ''systemTranslated_No_Option''
	when rqa.questionId is null then ivro.selectedOption
	when sa.answerId is not null and ivro.selectedOption = convert(varchar(5),sa.digit) then sa.description    
	else ''systemTranslated_Invalid'' end as ''Count'',
	datepart(yy,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [year],
	datepart(MM,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [month],
	datepart(DD,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [day],
	datepart(HH,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [hour],
	datepart(MI,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [minutes]
	,rsq.orden  
	from ccCallsIn cci with(nolock)
	inner join IVROptions ivro on cci.IVR_id = ivro.IVR_id and ivro.cal_id = cci.cal_id
	inner join ccUsers ccu on cci.User_id = ccu.User_id
	inner join Survey s on ivro.surveyId = s.surveyId
	inner join ccInbound ccin on cci.Inbound_id = ccin.Inbound_id
	inner join SurveyQuestion sq on ivro.questionId = sq.questionId
	inner join relationSurveyQuestion rsq on rsq.surveyId = ivro.surveyId and rsq.questionId=sq.questionId
	left join SurveyAnswer sa on convert(varchar(5),sa.digit) = ivro.selectedOption
	left join relationQuestionAnswer rqa on rsq.surveyId = rqa.surveyId and rqa.questionId = rsq.questionId
	where cal_inicio between @from and @to

  union all

  select distinct 
	cco.cal_Inicio as [date],cco.User_id as ''userId'',
	isnull(ccu.Login, ''No agent'') as ''login'',
	isnull(ivro.IVR_id, 0) as ''scriptId'',
	isnull(s.surveyId, 0) as ''surveyId'',
	isnull(s.description, '''') as ''survey'',
	isnull(cco.cal_id, 0) as ''calId'',
	isnull(cco.cal_Key, '''') as ''calKey'',
	isnull(ccc.[cam_id], '''') as ''campaignId'',
	0 as ''inboundId'',
	''Camp - '' + isnull(ccc.[cam_descripcion],'''') as ''campACDDescription'',
	isnull(ivro.questionId, 0) as ''questionId'',
	isnull(sq.description,'''') as ''questionDescription'',
	isnull(sq.description,'''')+ ''_Count'' as ''question_Count'',	
	case when ivro.selectedOption = '''' then ''systemTranslated_No_Option''
	when rqa.questionId is null then ivro.selectedOption
	when sa.answerId is not null and ivro.selectedOption = convert(varchar(5),sa.digit) then sa.description    
	else ''systemTranslated_Invalid'' end as ''Count'',
		datepart(yy,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [year],
	datepart(MM,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [month],
	datepart(DD,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [day],
	datepart(HH,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [hour],
	datepart(MI,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [minutes]
	,rsq.orden
	from ccoCallsOut cco with(nolock)
	inner join IVROptions ivro on cco.cal_id = ivro.cal_id
	inner join ccUsers ccu on cco.User_id = ccu.User_id
	inner join Survey s on ivro.surveyId = s.surveyId
	inner join ccCamps ccc on cco.cam_id = ccc.cam_id
	inner join SurveyQuestion sq on ivro.questionId = sq.questionId		
	inner join relationSurveyQuestion rsq on rsq.surveyId = ivro.surveyId and rsq.questionId=sq.questionId     
	left join SurveyAnswer sa on convert(varchar(5),sa.digit) = ivro.selectedOption
	left join relationQuestionAnswer rqa on rsq.surveyId = rqa.surveyId and rqa.questionId = rsq.questionId --and rqa.answerId = sa.answerId
	where cal_inicio between @from and @to
	
)surveys
order by calId,orden 
end'
	EXEC(@Sql)


	set @process = 'CREATE SP --ccspRepSpecialAbndCamp'
	set @sql='CREATE PROCEDURE [dbo].[ccspRepSpecialAbndCamp]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null
		select @to = getdate()

	delete RepSpecialAbndCamp with(rowlock)	where [date] between @from and @to

	insert RepSpecialAbndCamp
	select [date], campaignId, cam_descripcion, total, abandonedCalls,
	cast(isnull(((abandonedCalls*100.0)/nullif(total,0)),0) as decimal(5,2)) abandonedCallsPctg,
	[year],[month],[day],[hour],[minutes]
	from(
		select convert(datetime,convert(varchar(13),cal_inicio,121)+'':00'') as [date], co.cam_id campaignId,
		cam_descripcion , count(*) total,
		COUNT(CASE WHEN(statuscall_id in(5,6,7,8,9,10,11,15,16))THEN cal_id ELSE NULL END) abandonedCalls,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) as [month],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) as [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) as [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) as [minutes]
		from ccocallsout co with(index(IX_ccoCallsOut_2),nolock) left join cccamps ca on ca.cam_id=co.cam_id
		where cal_inicio between @from and @to and
		cal_manual in (0,2)
		group by convert(varchar(13),cal_inicio,121), co.cam_id,  cam_descripcion)X

end'
		EXEC(@sql)

		set @process = 'CREATE SP --ccspRepOutDispositionsContacOwner'
		set @sql='CREATE PROCEDURE [dbo].[ccspRepOutDispositionsContacOwner]
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

	--Borrar lo que esta para no repetir
	delete from RepOutDispositionsContacOwner with(rowlock)	where date >= @from AND date < @to

	insert into RepOutDispositionsContacOwner
	select [date],cam_id,Campaign, total,sumContactOwner as totalContactOwner,
	dbo.fPercentage(sumContactOwner,Total) as percentageContactOwner,
	datepart(yyyy,[date]) as [year], datepart(mm,[date]) [mounth],  datepart(dd,[date]) [day],
	datepart(hh,[date]) [hour], datepart(mi,[date]) [minute]
	 from (
	select CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121) as [date],a.cam_id,b.cam_descripcion as Campaign,
	count(*) total,
	sum(
		case when isnull(calOut.contactOwner,0) = 1 then 1
		when isnull(calSubOut.contactOwner,0) = 1  then 1 else 0 end
	 ) as sumContactOwner
	from ccocallsout a
	left join cccamps b on	b.cam_id = a.cam_id
	left join cctipocalifout calOut on calOut.calif_id=a.calif_id
	left join ccTipoCalifSubOUT calSubOut on calSubOut.califSub_id=a.califSub_id
	where a.cal_Inicio>=@from and a.cal_Inicio<@to
	group by CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121),a.cam_id,b.cam_descripcion
	)X
end'

		EXEC(@Sql)


		set @process = 'Alter PROCEDURE -------- GetPivotColumns'
		set @Sql= 'Alter PROCEDURE [dbo].[GetPivotColumns]
@id int
AS
BEGIN
SELECT [columns],complementColumns,pivotFunction,isGroupPivot
FROM dbo.PivotReports
WHERE id = @id
END'
		EXEC(@Sql)

		set @process = 'Alter PROCEDURE -------- ccspRepCatalogos --Revisar Raul'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepCatalogos]
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

	--Status Call
	if @type = 25
	begin
		select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
		from ccstatusllamada
		order by [descripcion]
	end

	--Survey
	if @type = 26
	begin
	select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
	from Survey
	order by [description]
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
		EXEC(@Sql)

		set @process = 'Alter SP --ccspRepTwitterGeneral'
		set @sql='ALTER procedure [dbo].[ccspRepTwitterGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepTwitterGeneral with(rowlock) where date >= @from AND date < @to

	insert into RepTwitterGeneral
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
	isnull(min(screenNameClient),'''') as screenNameClient,
	conversationId, isnull(sum(tQueue),0) as [tQueueMultimedia],
	isnull(sum(twait),0) as  [twaitMultimedia], isnull(sum(tAtentionMultimedia),0) tAtentionMultimedia, isnull(sum(twrapup),0) twrapup,
	isnull(sum(tsent),0) tsent,
	sum(tfocus) as tfocus,
	datepart(yyyy,min(date)) [year],
	datepart(mm,min(date)) [mounth],
	datepart(dd,min(date)) [day],
	datepart(hh,min(date)) [hour],
	datepart(mi,min(date)) [minute]
from(

select
	msg.date date,
	conv.screenNameClient screenNameClient, isnull(inbo.descripcion,'''') descripcion,
	isnull(inbo.inbound_id,0) inboundid, msg.conversationTwitterId conversationid,
	msg.messagestatusid messagestatusid,
	case when msg.tqueue is null then 0 else datediff(second,msg.[date],msg.tqueue) end as tQueue,
	msg.twait,
	isnull((msg.twait + msg.tretention + msg.tresponse),0) tAtentionMultimedia, msg.twrapup,
	case when msg.tsend is null then 0 else datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) end as tsent,
	msg.tresponse as tfocus
	from [messageOutTwitter] msg
	inner join [conversationTwitter] conv on msg.conversationTwitterId = conv.conversationTwitterId
	left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
	left join ccusers usuario on usuario.User_id = msg.userid
	where msg.date >= @from AND msg.date < @to
	)x
	group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion,inboundid,conversationId
end'
		EXEC(@sql)

		set @process = 'Alter SP --ccspRepTwitterDetail'
		set @sql='ALTER procedure [dbo].[ccspRepTwitterDetail]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepTwitterDetail with(rowlock)	where date >= @from AND date < @to

	insert into RepTwitterDetail
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
	conv.screenNameClient screenNameClient, isnull(inbo.descripcion,'''') descripcion,
	isnull(inbo.inbound_id,0) inboundid, msg.conversationTwitterId conversationid,msg.messageOutTwitterId,
	msg.messagestatusid messagestatusid,
	case when msg.tqueue is null then 0 else datediff(second,msg.[date],msg.tqueue) end as tQueue,
	msg.twait,
	isnull((msg.twait + msg.tretention + msg.tresponse),0) tAtentionMultimedia, msg.twrapup,
	case when msg.tsend is null then 0 else datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) end as tsent,
	msg.tresponse as tfocus,
	datepart(yyyy,date) [year],
	datepart(mm,date) [mounth],
	datepart(dd,date) [day],
	datepart(hh,date) [hour],
	datepart(mi,date) [minute]
	from [messageOutTwitter] msg
	inner join [conversationTwitter] conv on msg.conversationTwitterId = conv.conversationTwitterId
	left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
	left join ccusers usuario on usuario.User_id = msg.userid
	left join messageUnAssingedTwit msgun on msg.messageOutTwitterId = msgun.messageOutTwitterId
	where msg.date >= @from AND msg.date < @to
	order by date,msg.conversationTwitterId,msg.messageOutTwitterId

end'
		EXEC(@sql)

		set @process = 'Alter SP --ccspRepTwitterAgente'
		set @sql='ALTER PROCEDURE [dbo].[ccspRepTwitterAgente]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepTwitterAgente with(rowlock)	where date >= @from AND date < @to

	insert into RepTwitterAgente
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
		select msg.date date,msg.messageOutTwitterId,
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
			 sum(case when msgun.messageOutTwitterId is null then 0 else 1 end) messageUnAssigned,
			 datediff(second,msg.date,isnull(msg.tqueue,getdate())) tQueue,
			 datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent,
			 msg.twait twait,
			 msg.twait + msg.tretention + msg.tresponse tatention,
			 msg.twrapup twrapup
			 from [messageOutTwitter] msg
			 inner join [conversationTwitter] conv on msg.conversationTwitterId = conv.conversationTwitterId
			 left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
			 left join ccusers usuario on usuario.User_id = msg.userid
			 left join messageUnAssingedTwit msgun on msg.UserId=msgun.UserId and msgun.messageOutTwitterId = msg.messageOutTwitterId
			 where msg.userId>0 and msg.date >= @from AND msg.date < @to
			 group by msg.messageOutTwitterId,msg.date,inbo.descripcion,inbo.inbound_id,usuario.nombres,usuario.[User_Id],msg.messagestatusid,msg.tqueue,
			 msg.twait, msg.tretention, msg.tresponse, msg.twrapup, msg.tSend

			)x
			group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid,name,userId

end'
		EXEC(@sql)

		set @process = 'Alter SP --ccspRepTwitterACD'
		set @sql='ALTER PROCEDURE [dbo].[ccspRepTwitterACD]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepTwitterACD with(rowlock) where date >= @from AND date < @to

	insert into RepTwitterACD
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
				 from [messageOutTwitter] msg
				 inner join [conversationTwitter] conv
				on msg.conversationTwitterId = conv.conversationTwitterId
				left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
				left join ccusers usuario on usuario.User_id = msg.userid
				--where msg.date >= @from AND msg.date < @to
				)x
				group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid

end'
		EXEC(@sql)

		set @process = 'Alter SP ccspRepEmailDetail-- Add tFocus'
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
	datepart(mi,date) [minute],
	msg.tresponse as tfocus
	from [message] msg inner join [conversation] conv
	on msg.conversationId = conv.conversationId left join [ccInbound] inbo
	on inbo.inbound_Id = conv.inboundId
	left join ccusers usuario on usuario.User_id = msg.userid  left join messageUnAssigned msgun on msg.messageid = msgun.messageid
	where msg.date >= @from AND msg.date < @to
	order by date,msg.conversationId,msg.messageId

end'
		EXEC(@sql)


		set @process = 'ALTER SP ccspRepEmailGeneral -- Add Column tFocus'
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
	datepart(mi,min(date)) [minute],
	sum(tFocus) as tFocus
from(

select
	msg.date date,
	conv.mailClient mailClient, isnull(inbo.descripcion,'''') descripcion,
	isnull(inbo.inbound_id,0) inboundid, msg.conversationId conversationid,
	msg.messagestatusid messagestatusid,
	case when msg.tqueue is null then 0 else datediff(second,msg.[date],msg.tqueue)  end tQueue,
	msg.twait,
	isnull((msg.twait + msg.tretention + msg.tresponse),0) tAtentionMultimedia, msg.twrapup,
	case when msg.tsend is null then 0 else
		datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) end as tsent
	,msg.tresponse as tFocus
	from [message] msg inner join [conversation] conv
	on msg.conversationId = conv.conversationId
	inner join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
	inner join ccusers usuario on usuario.User_id = msg.userid
	where msg.date >= @from AND msg.date < @to
	)x
	group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion,inboundid,conversationId

end'
		EXEC(@sql)


		set @process = 'ALTER SP--ccspRepEmailAgente'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepEmailAgente]
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
			 where  msg.userId>0 and msg.date >= @from AND msg.date < @to
			 group by msg.messageid,msg.date,inbo.descripcion,inbo.inbound_id,usuario.nombres,usuario.[User_Id],msg.messagestatusid,msg.tqueue,
			 msg.twait, msg.tretention, msg.tresponse, msg.twrapup, msg.tSend

			)x
			group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid,name,userId

end'
		EXEC(@Sql)


		set @process = 'ALTER SP -- ccspRepAgentGI'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAgentGI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS off
SET NOCOUNT ON

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
	--,ISNULL(dbo.#notReady.timeNotReady, 0) AS treq
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

	--update t set treq=0
	--	   from #tempRepAgentGI t inner join #tempTime temp on t.id = temp.id
	--	   where [rank]>1

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

	insert into RepAgentGI(date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,--treq,
			tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotavg)
	select date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,--treq,
				tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotav
	 from #tempRepAgentGI

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
		EXEC(@Sql)

		set @process = 'insert TranslatedReports'
		set @Sql= 'if not exists(select * from TranslatedReports where id = 4060)
insert into TranslatedReports values (4060,''agentName|username'')'
		EXEC(@Sql)


		set @process = 'Alter SP -- ccspRepOutCallBilling'
		set @Sql= 'alter PROCEDURE [dbo].[ccspRepOutCallBilling]
 @action as tinyint,
 @from as datetime = null,
 @to as datetime = null

 AS

declare @country as tinyint
declare @iva as decimal(3,2)
declare @aux as varchar(3)

select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104
select @aux = isnull(valor,0) from ccsettings where setting_id = 25
set @iva=convert(decimal(3,2),''1.''+@aux)

if @country is null set @country = 1

if @from is null
 select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1
begin

 delete from RepOutCallBilling with(rowlock)     where date >= @from AND date < @to

 ---creamos tabla temporal con longitud
if exists(select longitud from cstoTipoLlamada where CHARINDEX(''|'',longitud)<>0 and country_id =@country) begin
  declare @longitud varchar(10)
  declare @tipollamada int
  declare @prefijo varchar(50)
  declare @descrip varchar(50)
  select @longitud = CONVERT(varchar(10),longitud),@descrip=descrip,@prefijo=prefijo, @tipollamada= tipoLlamada_id from cstoTipoLlamada where CHARINDEX(''|'',longitud)<>0 and country_id =@country
 end

 create table #cstoTipoLlamadaTemp(
tipoLlamada_id smallint not null,
descrip varchar(50) collate SQL_Latin1_General_CP1_CI_AS not null ,
prefijo varchar(50) collate SQL_Latin1_General_CP1_CI_AS not null,
longitud int not null
)

create index IX_CstoTipoLlamadaTemp on #cstoTipoLlamadaTemp (longitud,tipoLlamada_id)

insert into #cstoTipoLlamadaTemp
 SELECT tipoLlamada_id,descrip,prefijo,longitud
 from (
 select tipoLlamada_id,descrip,prefijo,longitud from cstoTipoLlamada
  where CHARINDEX(''|'',longitud)=0    and country_id = @country
 union all
 select @tipollamada as tipoLlamada_id,@descrip as descrip,@prefijo as prefijo, Value as longitud
  from dbo.fn_RIASplitDelimited(@longitud,''|'') where @tipollamada is not null
)x

  SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS date
   , cam_id, [user_id],
   provedor_id, tipoLlamada_id , min(tipoLlamada) as tipoLlamada
   , COUNT(*) as amount
   , SUM( mins) as mins
   , SUM( costo ) as costo
   , SUM( costo ) * @iva as costoIva
   into #TempOutCallBilling
  FROM
  (
   SELECT cal_inicio, cco.cam_id as cam_id, cco.user_id as user_id, cco.provedor_id,
     cco.tipoLlamada_id, t.descrip as tipoLlamada, CEILING((cal_tXfer + cal_tRing + cal_tDialog +1 ) / 60.0 ) as mins, costo
    FROM ccoCallsOut cco
     inner join cstoTipoLlamada t with(index(IX_cstoTipoLlamada),nolock) on cco.tipoLlamada_id = t.tipoLlamada_id
    WHERE cal_inicio >= @from AND  cal_inicio < @to and cco.provedor_id is not null and cal_manual in (0,2) and country_id = @country
 UNION ALL
 ---- Tambien las llamdas que fueron fax
 select cco.fecha as fecha, cco.cam_id,0 as userId, p.provedor_id, l.tipoLlamada_id,l.descrip as tipoLlamada,1 as mins, t.MinutoUno as costo
 FROM ccoLogDials  cco with(index(IX_ccoLogDials),nolock)
 inner join ccoDialers cd with(index(IX_ccoDialers),nolock)  on cco.puerto = cd.puerto
 inner join cstoProvedor p on cd.provedor_id = p.provedor_id
 inner join cstoTarifa t on  p.provedor_id = t.provedor_id
 inner join #cstoTipoLlamadaTemp l on  l.longitud = len(cco.telefono) and t.tipoLlamada_id = l.tipoLlamada_id
 WHERE cco.fecha >=  @from AND cco.fecha < @to  and cco.answerbit = 1 and cco.tiporesdial_id <> 1
 and cco.telefono like l.prefijo
  ) costo
  GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), cam_id, [user_id], provedor_id, tipoLlamada_id


 insert RepOutCallBilling
  select [date], [cam_id], [campaign], [user_id], [agentName], [username], [provedor_id],[provedor], [tipoLlamada_id],
   (case when tipo = ''amount'' then ''systemTranslated_'' + replace([tipoLLamada],'' '','''') + ''Calls_Count''
      when tipo = ''mins'' then + ''systemTranslated_'' + replace([tipoLLamada],'' '','''') + ''MinBilled_Count''
      when tipo = ''costo'' then + ''systemTranslated_'' + replace([tipoLLamada],'' '','''') + ''Cost_Count''
      when tipo = ''costoIva'' then + ''systemTranslated_'' + replace([tipoLLamada],'' '','''') + ''Tax_Count''
      else tipo end ) as tipoLLamada_Count
   ,convert(varchar,[tipollamada_Count])  as [count]
   , [tipoLLamada] as tipoLlamadaDesp, case when tipo = ''costo'' then convert(int,convert(decimal(10,2),[tipollamada_Count]) ) else 0 end
   , datepart(yyyy,[date]) as [year]
   , datepart(mm,[date]) as [month]
   , datepart(dd,[date]) as [day]
   , datepart(hh,[date]) as [hour]
   , datepart(mi,[date]) as [min]
  from
     (
    select [date], temp.cam_id as cam_id, camps.cam_descripcion as campaign,
     isnull(ccuse.user_id ,0) as user_id, case when ccuse.user_id Is null then ''systemTranslated_NoName''  else  ccuse.Nombres+'' ''+ ccuse.ApellidoPaterno+'' ''+ccuse.ApellidoMaterno end as agentName,
     case when ccuse.Login Is null then ''systemTranslated_NoUserName'' else ccuse.Login end as username,
     temp.provedor_id as provedor_id, prov.descrip as provedor,
     [tipoLlamada_id], [tipoLLamada],[tipoLLamada] as tipoLlamadaDesp,convert(varchar,[amount]) as [amount], convert(varchar,[mins]) as [mins], convert(varchar,[costo]) as [costo], convert(varchar,[costoIva]) as [costoIva]
      from #TempOutCallBilling temp
    inner join ccCamps camps on camps.cam_id = temp.cam_id
    left join ccUsers ccuse on ccuse.User_id = temp.user_id
    inner join cstoprovedor prov on prov.provedor_id = temp.provedor_id
   ) p
  UNPIVOT
     ([tipollamada_Count] for tipo IN
     ([amount], [mins], [costo], [costoIva])
  )AS unpvt

 drop table #TempOutCallBilling
 drop table #cstoTipoLlamadaTemp

end'
		EXEC(@Sql)

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