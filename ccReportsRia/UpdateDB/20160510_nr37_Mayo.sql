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


		set @process = 'VALIDATE PROCEDURE -------- ccspRepIVRSurveys'
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

		set @process = 'Update tfocus valueo (0)'
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
		set @Sql= 'if not exists(select * from ReportsTotals where id = 6050) begin
insert into ReportsTotals values (6050, '')
end'
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

		set @process = 'CREATE Index -- RepOutDispositionsContacOwner.IX_RepOutDispositionsContacOwner'
		set @sql='if exists (select * from sys.indexes where name = N''IX_RepOutDispositionsContacOwner'' and object_id = OBJECT_ID(N''RepOutDispositionsContacOwner''))
	    begin
	        CREATE NONCLUSTERED INDEX [IX_RepOutDispositionsContacOwner] ON [dbo].[RepOutDispositionsContacOwner]
			(
				[date] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	    end'
    EXEC(@sql)

    	set @process = 'CREATE Index -- RepSpececialAbndCamp.IX_RepOutDispositionsContacOwner'
		set @sql='if exists (select * from sys.indexes where name = N''IX_RepSpececialAbndCamp'' and object_id = OBJECT_ID(N''RepSpececialAbndCamp''))
		    begin
		        CREATE NONCLUSTERED INDEX [IX_RepSpececialAbndCamp] ON [dbo].[RepSpececialAbndCamp]
		(
			[date] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
		    end'

		EXEC(@sql)


		set @process = 'UPDATE -------- PivotReports'
		set @Sql= 'update PivotReports set isGroupPivot = 1'
		EXEC(@Sql)

		set @process = 'INSERT -------- PivotReports'
		set @Sql= 'if not exists(select * from PivotReports where id = 6050)
		begin
			insert into PivotReports values (6050, ''question_Count'', ''date|userId|login|scriptId|surveyId|survey|calId|calKey|campaignId|inboundId|campACDDescription|year|month|day|hour|minutes'', ''max'', 0)
		end'
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
		set @Sql= 'if not exists(select * from Filters where id in (28,29)) begin
insert into Filters values(28, ''agent'', 26, ''Agents'', ''Agent'')
insert into Filters values(29, ''survey'', 27, ''Surveys'', ''Survey'')
end'
		EXEC(@Sql)

		set @process = 'INSERT -------- ReportsFilters---Revisar Raul'
		set @Sql= 'if not exists(select * from ReportsFilters where id = 6050) begin
insert into ReportsFilters values(''IVR Surveys'', ''acds'', ''6050'')
insert into ReportsFilters values(''IVR Surveys'', ''campaigns'', ''6050'')
insert into ReportsFilters values(''IVR Surveys'', ''agent'', ''6050'')
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
  select 
  convert(datetime,convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121) as [date],
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
  case when sa.answerId is null and isnull(ivro.selectedOption,'''') ='''' then ''systemTranslated_No_Option''
    when sa.answerId is null then ivro.selectedOption 
    when sa.answerId is not null and ivro.selectedOption = convert(varchar(5),sa.digit) then sa.description
    when sa.answerId is not null and isnull(ivro.selectedOption,'''') ='''' then ''systemTranslated_No_Option''
  else ''systemTranslated_Invalid'' end as ''Count'',
  datepart(yy,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [year],
  datepart(MM,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [month],
  datepart(DD,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [day],
  datepart(HH,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [hour],
  datepart(MI,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [minutes]
  from ccCallsIn cci with(nolock)
  inner join IVROptions ivro on cci.IVR_id = ivro.IVR_id
  inner join ccUsers ccu on cci.User_id = ccu.User_id
  inner join ccInbound ccin on cci.Inbound_id = ccin.Inbound_id
  left join Survey s on ivro.IVR_id = s.scriptId
  left join relationQuestionAnswer rqa on s.surveyId = rqa.surveyId
  left join SurveyQuestion sq on ivro.questionId = sq.questionId
  left join SurveyAnswer sa on rqa.answerId = sa.answerId
  where cal_inicio between @from and @to

  union all

  select
  convert(datetime,convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121) as [date],
  isnull(cco.User_id, 0) as ''userId'',
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
  case when sa.answerId is null then ivro.selectedOption 
    when sa.answerId is not null and ivro.selectedOption = convert(varchar(5),sa.digit) then sa.description
    when sa.answerId is not null and isnull(ivro.selectedOption,'''') ='''' then ''systemTranslated_No_Option''
  else ''systemTranslated_Invalid'' end as ''Count'',
  datepart(yy,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [year],
  datepart(MM,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [month],
  datepart(DD,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [day],
  datepart(HH,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [hour],
  datepart(MI,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [minutes]
  from ccoCallsOut cco with(nolock)
  inner join IVROptions ivro on cco.cal_id = ivro.cal_id
  inner join ccUsers ccu on cco.User_id = ccu.User_id
  inner join ccCamps ccc on cco.cam_id = ccc.cam_id
  left join Survey s on ivro.IVR_id = s.scriptId
  left join relationQuestionAnswer rqa on s.surveyId = rqa.surveyId
  left join SurveyQuestion sq on ivro.questionId = sq.questionId
  left join SurveyAnswer sa on rqa.answerId = sa.answerId
  where cal_inicio between @from and @to
)surveys 

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
		COUNT(CASE WHEN(statuscall_id in(11,15,16))THEN cal_id ELSE NULL END) abandonedCalls,
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
		set @Sql= 'Alter PROCEDURE [dbo].[ccspRepCatalogos]
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
if @type = 26
begin
select User_id as id, [Login] as description, ''userId'' as dbcolumn
from ccUsers
where TipoUser_id = 1
order by [Login]
end

--Survey
if @type = 27
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


		set @process = ''
		set @Sql= ''
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