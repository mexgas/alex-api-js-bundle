/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author: Raymundo Gonzalez
Date: 2015/02/11
Description: 

	Satisfaction Survey

	Se Eliminan registros de tabla ReportsFiltersRange
	Se Eliminanregistros de tabla ReportsFilters
	Se Eliminan registros de tabla ccMenuUser
	Se Eliminan registros de tabla CCMenus
	Se Eliminan registros de tabla ReportsCharts
	Se Eliminan registros de tabla ReportsFiltersMenus
	Se Eliminan registros de tabla filters
	Se Eliminan registros de Tabla ReportsTotals

	Se Elimina Tabla ccspRepAVRSAgentChat
	Se Elimina Tabla ccspRepAVRSDetailChat
	Se Elimina Tabla ccspRepAVRSQuestion
	Se Elimina Tabla ccspRepAVRSQuestionChat
	Se Elimina Tabla ccspRepAVRSRateChat
	Se Elimina Tabla RepAVRSAgent
	Se Elimina Tabla RepAVRSQuestionDetail
	Se Elimina Tabla RepAVRSRateDetail
	Se Elimina Tabla RepAVRSScores
	Se Elimina Tabla RepAVRSSection
	Se Elimina Tabla RepAVRSSupervisor

	Se Agregar registros a tabla filters
	Se Agregar registros a tabla ReportsCharts
	Se Agregar registros a tabla  ReportsTotals
	Se Agregar registros a tabla ReportsFilters
	Se Agregar registros a tabla ReportsFiltersMenus
	Se Agregar registros a tabla ReportsFiltersRange
	Se Agregar registros a tabla GroupByReports
	Se Agregar registros a tabla DetailReports

	Se agrega columna tipo en RIA_FORMATOS 
	Se agrega columna tipo,tipo_llamada,cam_id en RIA_FORMACALIF
	Se agrega columna video en ria_grabacion
	Se agrega columna video en ria_grabacionConsulta

	Se crea tabla RepAVRSAgent
	Se crea tabla RepAVRSAgentChat
	Se crea tabla RepAVRSDetailChat
	Se crea tabla RepAVRSQuestion
	Se crea tabla RepAVRSQuestionChat
	Se crea tabla RepAVRSQuestionDetail
	Se crea tabla RepAVRSRateChat
	Se crea tabla RepAVRSRateDetail
	Se crea tabla RepAVRSScores
	Se crea tabla RepAVRSSection
	Se crea tabla RepAVRSSupervisor

	Se crea SP ccspRepAVRSAgentChat
	Se crea SP ccspRepAVRSDetailChat
	Se crea SP ccspRepAVRSQuestion
	Se crea SP ccspRepAVRSQuestionChat
	Se crea SP ccspRepAVRSRateChat

	Se actualiza SP ccspRepAVRSAgent
	Se actualiza SP ccspRepAVRSQuestionDetail
	Se actualiza SP ccspRepAVRSRateDetail
	Se actualiza SP ccspRepAVRSSection
	Se actualiza SP ccspRepAVRSSupervisor

Database: ccReportsRia
Required version: 23

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 24

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version-1
	begin
		begin tran
		begin try

		/* Start script release */

		set @process = 'delete CONSTRAINT ReportsFiltersRange'
		set @sql='declare @name nvarchar(max),@sql2 nvarchar(max)
		 if exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''ReportsFiltersRange'' and  c1.[name]=''filtername'') begin 
		 SELECT @name =OBJECT_NAME(f.constraint_object_id) FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''ReportsFiltersRange'' and  c1.[name]=''filtername''
		 set @sql2=''ALTER TABLE ReportsFiltersRange DROP CONSTRAINT ''+@name
		 EXEC(@sql2)
		end'
		EXEC(@sql)

		set @process = 'delete relation ReportsFiltersRange'
		set @sql=' Delete from ReportsFiltersRange where id in (8061,8080,8071,8072,8063,8062)'
		EXEC(@sql)

		set @process = 'delete relation ReportsFilters'
		set @sql=' Delete from ReportsFilters where id in (8061,8080,8071,8072,8063,8062)'
		EXEC(@sql)		

		set @process = 'delete relation ccMenuUser'
		set @sql=' Delete from ccMenuUser where id_menu in (8050,80601,8061,8062,8063,8070,8071,8072,8080)'
		EXEC(@sql)

		set @process = 'delete Menus CCMenus'
		set @sql=' Delete from ccMenus where menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080)'
		EXEC(@sql)

		set @process = 'delete relation ReportsCharts'
		set @sql=' Delete from ReportsCharts where id in (8061,8062,8080)'
		EXEC(@sql)

		set @process = 'delete relation ReportsTotals'
		set @sql=' Delete from ReportsTotals where ID>8040'
		EXEC(@sql)

		
		set @process = 'delete relation ReportsFiltersMenus'
		set @sql=' Delete from ReportsFiltersMenus where idReport in (8061,8062,8063,8071,8072,8080)'
		EXEC(@sql)

		set @process = 'delete relation filters'
		set @sql=' Delete from filters'
		EXEC(@sql)

		set @process = 'ccspRepAVRSAgentChat - Drop if exists'
		set @sql='if exists (select * from sys.procedures where name = N''ccspRepAVRSAgentChat'') DROP PROCEDURE ccspRepAVRSAgentChat'
		EXEC(@sql)

		set @process = 'ccspRepAVRSDetailChat - Drop if exists'
		set @sql='if exists (select * from sys.procedures where name = N''ccspRepAVRSDetailChat'') DROP PROCEDURE ccspRepAVRSDetailChat'
		EXEC(@sql)

		set @process = 'ccspRepAVRSQuestion - Drop if exists'
		set @sql='if exists (select * from sys.procedures where name = N''ccspRepAVRSQuestion'') DROP PROCEDURE ccspRepAVRSQuestion'
		EXEC(@sql)

		set @process = 'ccspRepAVRSQuestionChat - Drop if exists'
		set @sql='if exists (select * from sys.procedures where name = N''ccspRepAVRSQuestionChat'') DROP PROCEDURE ccspRepAVRSQuestionChat'
		EXEC(@sql)

		set @process = 'ccspRepAVRSRateChat - Drop if exists'
		set @sql='if exists (select * from sys.procedures where name = N''ccspRepAVRSRateChat'') DROP PROCEDURE ccspRepAVRSRateChat'
		EXEC(@sql)

		set @process = 'RepAVRSAgent - Drop if exists'
		set @sql='if exists (select * from sys.tables where name = N''RepAVRSAgent'') DROP table RepAVRSAgent'
		EXEC(@sql)

		set @process = 'RepAVRSQuestionDetail - Drop if exists'
		set @sql='if exists (select * from sys.tables where name = N''RepAVRSQuestionDetail'') DROP table RepAVRSQuestionDetail'
		EXEC(@sql)

		set @process = 'RepAVRSRateDetail - Drop if exists'
		set @sql='if exists (select * from sys.tables where name = N''RepAVRSRateDetail'') DROP table RepAVRSRateDetail'
		EXEC(@sql)

		set @process = 'RepAVRSScores - Drop if exists'
		set @sql='if exists (select * from sys.tables where name = N''RepAVRSScores'') DROP table RepAVRSScores'
		EXEC(@sql)

		set @process = 'RepAVRSSection - Drop if exists'
		set @sql='if exists (select * from sys.tables where name = N''RepAVRSSection'') DROP table RepAVRSSection'
		EXEC(@sql)

		set @process = 'RepAVRSSupervisor - Drop if exists'
		set @sql='if exists (select * from sys.tables where name = N''RepAVRSSupervisor'') DROP table RepAVRSSupervisor'
		EXEC(@sql)

		set @process = 'Insert ccSettings'
		set @sql='insert into ccsettings(setting_id,valor,descripcion,Status,tipo) values(34,'''',''IP CRM'',1,''X'')'
		EXEC(@sql)

		set @process = 'Insert values in filters'
		set @sql='insert into filters values (''1'',''acds'',7,''Acds'',''Acd'')
		insert into filters values (''2'',''areas'',4,''Areas'',''Area'')
		insert into filters values (''19'',''avgDisposition'',19,''Avg'',''Avg'')
		insert into filters values (''3'',''calltypes'',14,''CallTypes'',''CallType'')
		insert into filters values (''4'',''campaigns'',1,''Campaigns'',''Campaign'')
		insert into filters values (''6'',''carriers'',0,''Carriers'',''Carrier'')
		insert into filters values (''7'',''dialresults'',2,''DialResults'',''DialResult'')
		insert into filters values (''8'',''dids'',8,''Dids'',''Did'')
		insert into filters values (''18'',''Disposition'',18,''Disposition'',''Disposition'')
		insert into filters values (''9'',''dispositionsIn'',9,''Dispositions'',''Disposition'')
		insert into filters values (''21'',''dispositionsOut'',5,''Dispositions'',''Disposition'')
		insert into filters values (''5'',''providers'',11,''Providers'',''Provider'')
		insert into filters values (''24'',''Questions'',23,''Questions'',''Question'')
		insert into filters values (''25'',''QuestionsChat'',24,''QuestionsChat'',''QuestionChat'')
		insert into filters values (''20'',''score'',20,''score'',''score'')
		insert into filters values (''10'',''subdispositionsIn'',10,''Subdispositions'',''Subdisposition'')
		insert into filters values (''22'',''subdispositionsOut'',21,''Subdispositions'',''Subdisposition'')
		insert into filters values (''23'',''supervisorId'',22,''SupervisorIDs'',''SupervisorID'')
		insert into filters values (''17'',''supervisors'',17,''Supervisors'',''Supervisors'')
		insert into filters values (''16'',''template'',16,''Template'',''Template'')
		insert into filters values (''15'',''templateSection'',15,''TemplateSection'',''TemplateSection'')
		insert into filters values (''11'',''trunks'',13,''Trunks'',''Trunk'')
		insert into filters values (''12'',''unavailables'',12,''Unavailables'',''Unavailable'')
		insert into filters values (''13'',''users'',6,''Users'',''User'')
		insert into filters values (''14'',''workgroups'',3,''WorkGroups'',''WorkGroup'')
		insert into filters values (''26'',''CRMxTemplates'',22,''CRMxTemplates'',''CRMxTemplate'')'
		EXEC(@sql)

		set @process = 'Insert values in ReportsCharts'
		set @sql='insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8061,''Agent'',1,''agentName'','''','''','''',''sum(Dispositions)'',''Total dispositions per Agent by date range'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8061,''Agent'',2,''agentName'',''avgDisposition'','''','''',''avg(avgDisposition)'',''Total dispositions per Agent by date range'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8062,''Supervisor'',1,''Supervisor'','''','''','''',''sum(Dispositions)'',''Total dispositions per Supervisor by date range'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8062,''Supervisor'',2,''avg(avgDisposition)'',''avgDisposition'','''','''',''avg(avgDisposition)'',''Average dispositions'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8063,''Section'',1,''Section'','''','''','''',''sum(Dispositions)'',''Total dispositions per Section by date range'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8063,''Section'',2,''Section'',''avgDisposition'','''','''',''avg(avgDisposition)'',''Total dispositions per Section by date range'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8064,''Questions'',1,''question'','''','''','''',''sum(Dispositions)'',''Total dispositions per Question by date range'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8064,''Questions'',2,''question'',''avgDisposition'','''','''',''avg(avgDisposition)'',''Total dispositions per Question by date range'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8080,''Disposition'',1,''agentName'','''','''','''',''count(agentName)'',''Total dispositions per Agent by date range'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8080,''Disposition'',2,''year|month|day|agentName|Template'',''Disposition'','''','''',''avg(Disposition)'',''Average dispositions'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8081,''Agent'',1,''agentName'','''','''','''',''sum(Dispositions)'',''Total dispositions per Agent by date range'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8081,''Agent'',2,''agentName'',''avgDisposition'','''','''',''avg(avgDisposition)'',''Total dispositions per Agent by date range'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8082,''Questions'',1,''question'','''','''','''',''sum(Dispositions)'',''Total dispositions per Question by date range'',0)
			insert into ReportsCharts (id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime) values (8082,''Questions'',2,''question'',''avgDisposition'','''','''',''avg(avgDisposition)'',''Total dispositions per Question by date range'',0)
		'
		EXEC(@sql)

		set @process = 'Insert values in ReportsTotals'
		set @sql='insert into ReportsTotals values (8061,''avg:avgDisposition'')
			insert into ReportsTotals values (8062,''count:agentName|avg:avgDisposition'')
			insert into ReportsTotals values (8063,''avg:avgDisposition'')
			insert into ReportsTotals values (8064,''avg:avgDisposition'')
			insert into ReportsTotals values (8071,''count:agentName|avg:Disposition'')
			insert into ReportsTotals values (8072,''avg:Disposition2'')
			insert into ReportsTotals values (8080,''count:agentName|avg:Disposition'')
			insert into ReportsTotals values (8081,''count:agentName|avg:avgDisposition'')
			insert into ReportsTotals values (8082,''avg:avgDisposition'')
			insert into ReportsTotals values (8083,''sum:Dispositions|avg:avgDispostion'')
			insert into ReportsTotals values (8084,''count:agentName|sum:Disposition'')
		'
		EXEC(@sql)

		set @process = 'Insert values in ReportsFilters'
		set @sql='insert into ReportsFilters values (''Agent'',''users'',8061)
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

		set @process = 'Insert values in ReportsFiltersMenusvalues'
		set @sql='insert into ReportsFiltersMenus values(8061,''date'')
			insert into ReportsFiltersMenus values(8061,''filterby'')
			insert into ReportsFiltersMenus values(8061,''range'')
			insert into ReportsFiltersMenus values(8062,''date'')
			insert into ReportsFiltersMenus values(8062,''filterby'')
			insert into ReportsFiltersMenus values(8062,''range'')
			insert into ReportsFiltersMenus values(8063,''date'')
			insert into ReportsFiltersMenus values(8063,''filterby'')
			insert into ReportsFiltersMenus values(8063,''range'')
			insert into ReportsFiltersMenus values(8072,''date'')
			insert into ReportsFiltersMenus values(8072,''filterby'')
			insert into ReportsFiltersMenus values(8084,''date'')
			insert into ReportsFiltersMenus values(8071,''date'')
			insert into ReportsFiltersMenus values(8071,''filterby'')
			insert into ReportsFiltersMenus values(8071,''range'')
			insert into ReportsFiltersMenus values(8080,''date'')
			insert into ReportsFiltersMenus values(8080,''filterby'')
			insert into ReportsFiltersMenus values(8080,''range'')
			insert into ReportsFiltersMenus values(8081,''date'')
			insert into ReportsFiltersMenus values(8081,''filterby'')
			insert into ReportsFiltersMenus values(8081,''range'')
			insert into ReportsFiltersMenus values(8061,''groupby'')
			insert into ReportsFiltersMenus values(8081,''groupby'')
			insert into ReportsFiltersMenus values(8062,''groupby'')
			insert into ReportsFiltersMenus values(8063,''groupby'')
			insert into ReportsFiltersMenus values(8084,''filterby'')
			insert into ReportsFiltersMenus values(8083,''date'')
			insert into ReportsFiltersMenus values(8083,''filterby'')
			insert into ReportsFiltersMenus values(8083,''groupby'')
			insert into ReportsFiltersMenus values(8071,''groupby'')
			insert into ReportsFiltersMenus values(8082,''date'')
			insert into ReportsFiltersMenus values(8082,''filterby'')
			insert into ReportsFiltersMenus values(8082,''range'')
			insert into ReportsFiltersMenus values(8082,''groupby'')
			insert into ReportsFiltersMenus values(8064,''date'')
			insert into ReportsFiltersMenus values(8064,''filterby'')
			insert into ReportsFiltersMenus values(8064,''range'')
			insert into ReportsFiltersMenus values(8064,''groupby'')
		'
		EXEC(@sql)

		set @process = 'Insert values in ReportsFiltersRange'
		set @sql='insert into ReportsFiltersRange values (''Agent'',''avgDisposition'',8061)
			insert into ReportsFiltersRange values (''Agent'',''avgDisposition'',8081)
			insert into ReportsFiltersRange values (''Disposition'',''Disposition'',8080)
			insert into ReportsFiltersRange values (''Rate Detail'',''avgDisposition'',8071)
			insert into ReportsFiltersRange values (''RateChat'',''avgDisposition'',8083)
			insert into ReportsFiltersRange values (''RepAVRSQuestion'',''avgDisposition'',8064)
			insert into ReportsFiltersRange values (''RepAVRSQuestionChat'',''avgDisposition'',8082)
			insert into ReportsFiltersRange values (''Section'',''avgDisposition'',8063)
			insert into ReportsFiltersRange values (''Supervisors'',''avgDisposition'',8062)
			'
		EXEC(@sql)

		set @process = 'Insert values in GroupByReports'
		set @sql='insert into GroupByReports values (''8061'',''userId|user|agentName|count(Dispositions):Dispositions|avg(Dispositions):avgDisposition'',''userId|user|agentName'')
		insert into GroupByReports values (''8062'',''supervisorId|supervisorUser|Supervisor|count(Dispositions):Dispositions|avg(Dispositions):avgDisposition'',''supervisorId|supervisorUser|Supervisor'')
		insert into GroupByReports values (''8081'',''userId|user|agentName|count(Dispositions):Dispositions|avg(Dispositions):avgDisposition'',''userId|user|agentName'')
		insert into GroupByReports values (''8063'',''Template|Section|count(distinct idForma):Dispositions|avg(Dispositions):avgDisposition'',''Template|Section'')
		insert into GroupByReports values (''8083'',''user|agentName|templateId|Template|count(distinct formaId):Dispositions|(sum(Dispositions)/count(distinct formaId)):avgDisposition'',''user|agentName|templateId|Template'')
		insert into GroupByReports values (''8071'',''user|agentName|supervisorUser|Supervisor|templateId|Template|count(distinct formaId):Dispositions|(sum(Dispositions)/count(distinct formaId)):avgDisposition'',''user|agentName|supervisorUser|Supervisor|templateId|Template'')
		insert into GroupByReports values (''8082'',''Template|question|count(Dispositions):Dispositions|avg(Dispositions):avgDisposition'',''Template|question'')
		insert into GroupByReports values (''8064'',''Template|Section|question|count(Dispositions):Dispositions|avg(Dispositions):avgDisposition'',''Template|Section|question'')
		'
		EXEC(@sql)

		set @process = 'Insert values in DetailReports'
		set @sql='insert into DetailReports values (''8061'',''userId'',''Dispositions'','''',''date|idMedia|userId|user|agentName|Supervisor|Template|Disposition2|cam_id|campaignAcd|media'')
		insert into DetailReports values (''8062'',''supervisorId'',''Dispositions'','''',''date|idMedia|supervisorUser|Supervisor|userId|user|agentName|Template|Disposition2|cam_id|campaignAcd|media'')
		insert into DetailReports values (''8063'',''sectionId'',''Dispositions'','''',''date|userId|user|agentName|supervisorUser|Supervisor|Template|Section|Disposition2|cam_id|campaignAcd|media'')
		insert into DetailReports values (''8081'',''userId'',''Dispositions'','''',''date|chatId|userId|user|agentName|Template|Disposition2|inboundId|inbound'')
		insert into DetailReports values (''8083'',''userId|templateId'',''Dispositions'','''',''date|chatId|userId|user|agentName|Template|question|answer|Disposition2|inboundId|inbound'')
		insert into DetailReports values (''8071'',''userId|supervisorId|templateId'',''Dispositions'','''',''date|userId|user|agentName|supervisorUser|Supervisor|Template|Section|question|answer|Disposition2|cam_id|campaignAcd|media'')
		insert into DetailReports values (''8082'',''questionId'',''Dispositions'','''',''date|userId|user|agentName|Template|question|Disposition2|inboundId|inbound'')
		insert into DetailReports values (''8064'',''questionId'',''Dispositions'','''',''date|userId|user|agentName|supervisorUser|Supervisor|Template|Section|question|Disposition2|cam_id|campaignAcd|media'')
		'
		EXEC(@sql)

		set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
		set @Sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE [name] = N''MSmerge_tr_altertable'' AND type in (N''TR'') AND is_disabled = 0)
			BEGIN
				DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
			END'

		EXEC(@Sql)

		set @process = 'add colum - RIA_FORMATOS'
		set @sql='if not exists (select * from sys.columns where name = N''tipo'' and Object_ID = Object_ID(N''RIA_FORMATOS''))
		ALTER TABLE RIA_FORMATOS ADD tipo INT NOT NULL DEFAULT 0'
		EXEC(@sql)

		set @process = 'add colum - RIA_FORMACALIF'
		set @sql='if not exists (select * from sys.columns where name = N''tipo'' and Object_ID = Object_ID(N''RIA_FORMACALIF'')) ALTER TABLE RIA_FORMACALIF ADD tipo smallint NOT NULL DEFAULT 0
			if not exists (select * from sys.columns where name = N''tipo_llamada'' and Object_ID = Object_ID(N''RIA_FORMACALIF'')) ALTER TABLE RIA_FORMACALIF ADD tipo_llamada smallint NOT NULL DEFAULT 0
			if not exists (select * from sys.columns where name = N''cam_id'' and Object_ID = Object_ID(N''RIA_FORMACALIF'')) ALTER TABLE RIA_FORMACALIF ADD cam_id smallint NOT NULL DEFAULT 0'
		EXEC(@sql)

		set @process = 'add colum - ria_grabacion'
		set @sql='if not exists (select * from sys.columns where name = N''video'' and Object_ID = Object_ID(N''ria_grabacion''))  ALTER TABLE ria_grabacion ADD video INT NOT NULL DEFAULT 0'
		EXEC(@sql)

		set @process = 'add colum - ria_grabacionConsulta'
		set @sql='if not exists (select * from sys.columns where name = N''video'' and Object_ID = Object_ID(N''ria_grabacionConsulta'')) ALTER TABLE ria_grabacionConsulta ADD video INT NOT NULL DEFAULT 0'
		EXEC(@sql)

		set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
		set @Sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE [name] = N''MSmerge_tr_altertable'' AND type in (N''TR'') AND is_disabled = 1)
			BEGIN 
				ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
			END'

		EXEC(@Sql)

		set @process = 'CREATE TABLE -  RepAVRSAgent'
		set @sql='if not exists (select * from sys.tables where name = N''RepAVRSAgent'')
		begin			
			CREATE TABLE [dbo].[RepAVRSAgent](
			[date] [datetime] NOT NULL,
			[userId] [int] NOT NULL,
			[user] [varchar](50) NOT NULL,
			[agentName] [varchar](50) NOT NULL,
			[Dispositions] [int] NOT NULL,
			[Disposition2] [int] NOT NULL,
			[avgDisposition] [int] NOT NULL,
			[supervisorId] [int] NOT NULL,
			[supervisorUser] [varchar](50) NOT NULL,
			[Supervisor] [varchar](50) NOT NULL,
			[idFormato] [int] NULL,
			[Template] [varchar](50) NULL,
			[idMedia] [int] NULL,
			[media] [varchar](50) NULL,
			[cam_id] [int] NULL,
			[tipoLlamada] [int] NULL,
			[campaignAcd] [varchar](50) NULL,
			[year] [int] NULL,
			[month] [int] NULL,
			[day] [int] NULL,
			[hour] [int] NULL,
			[minutes] [int] NULL
			) ON [PRIMARY]
		end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -  RepAVRSAgentChat'
		set @sql='if not exists (select * from sys.tables where name = N''RepAVRSAgentChat'')
		begin			
			CREATE TABLE [dbo].[RepAVRSAgentChat](
			[date] [datetime] NOT NULL,
			[userId] [int] NOT NULL,
			[user] [varchar](50) NOT NULL,
			[agentName] [varchar](50) NOT NULL,
			[Dispositions] [int] NOT NULL,
			[Disposition2] [int] NOT NULL,
			[avgDisposition] [int] NOT NULL,
			[idFormato] [int] NULL,
			[Template] [varchar](50) NULL,
			[chatId] [int] NULL,
			[inboundId] [int] NULL,
			[inbound] [varchar](50) NULL,
			[year] [int] NULL,
			[month] [int] NULL,
			[day] [int] NULL,
			[hour] [int] NULL,
			[minutes] [int] NULL
			) ON [PRIMARY]
		end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -  RepAVRSDetailChat'
		set @sql='if not exists (select * from sys.tables where name = N''RepAVRSDetailChat'')
		begin			
			CREATE TABLE [dbo].[RepAVRSDetailChat](
			[date] [datetime] NOT NULL,
			[userId] [int] NOT NULL,
			[user] [varchar](50) NOT NULL,
			[agentName] [varchar](50) NOT NULL,
			[templateId] [varchar](50) NULL,
			[Template] [varchar](50) NULL,
			[question] [varchar](100) NULL,
			[answer] [varchar](max) NOT NULL,
			[Disposition2] [int] NOT NULL,
			[inboundId] [int] NULL,
			[inbound] [varchar](50) NULL
			) ON [PRIMARY] 
		end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -  RepAVRSQuestion'
		set @sql='if not exists (select * from sys.tables where name = N''RepAVRSQuestion'')
		begin			
			CREATE TABLE [dbo].[RepAVRSQuestion](
			[date] [datetime] NOT NULL,
			[userId] [int] NOT NULL,
			[user] [varchar](50) NOT NULL,
			[agentName] [varchar](50) NOT NULL,
			[supervisorId] [int] NOT NULL,
			[supervisorUser] [varchar](50) NOT NULL,
			[Supervisor] [varchar](50) NOT NULL,
			[templateId] [int] NOT NULL,
			[Template] [varchar](50) NOT NULL,
			[sectionId] [int] NOT NULL,
			[Section] [varchar](50) NOT NULL,
			[questionId] [int] NOT NULL,
			[question] [varchar](50) NOT NULL,
			[Dispositions] [int] NOT NULL,
			[avgDisposition] [int] NOT NULL,
			[Disposition2] [int] NOT NULL,
			[mediaId] [int] NOT NULL,
			[media] [varchar](50) NULL,
			[cam_id] [int] NULL,
			[campaignAcd] [varchar](50) NULL
			) ON [PRIMARY]
		end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -  RepAVRSQuestionChat'
		set @sql='if not exists (select * from sys.tables where name = N''RepAVRSQuestionChat'')
		begin			
			CREATE TABLE [dbo].[RepAVRSQuestionChat](
			[date] [datetime] NOT NULL,
			[userId] [int] NOT NULL,
			[user] [varchar](50) NOT NULL,
			[agentName] [varchar](50) NOT NULL,
			[templateId] [int] NULL,
			[Template] [varchar](50) NOT NULL,
			[questionId] [int] NULL,
			[question] [varchar](50) NOT NULL,
			[Dispositions] [int] NOT NULL,
			[Disposition2] [int] NOT NULL,
			[avgDisposition] [int] NOT NULL,
			[inboundId] [int] NOT NULL,
			[inbound] [varchar](50) NULL
			) ON [PRIMARY]
		end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -  RepAVRSQuestionDetail'
		set @sql='if not exists (select * from sys.tables where name = N''RepAVRSQuestionDetail'')
		begin			
			CREATE TABLE [dbo].[RepAVRSQuestionDetail](
			[date] [datetime] NOT NULL,
			[userId] [int] NOT NULL,
			[user] [varchar](50) NOT NULL,
			[agentName] [varchar](50) NOT NULL,
			[supervisorUser] [varchar](50) NOT NULL,
			[Supervisor] [varchar](50) NOT NULL,
			[Template] [varchar](50) NOT NULL,
			[Section] [varchar](50) NOT NULL,
			[question] [varchar](50) NOT NULL,
			[answer] [varchar](50) NOT NULL,
			[Disposition2] [int] NOT NULL,
			[media] [varchar](50) NULL,
			[cam_id] [int] NULL,
			[campaignAcd] [varchar](50) NULL
			) ON [PRIMARY]
		end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -  RepAVRSRateChat'
		set @sql='if not exists (select * from sys.tables where name = N''RepAVRSRateChat'')
		begin			
			CREATE TABLE [dbo].[RepAVRSRateChat](
			[date] [datetime] NOT NULL,
			[userId] [int] NOT NULL,
			[user] [varchar](50) NOT NULL,
			[agentName] [varchar](50) NOT NULL,
			[chatId] [int] NOT NULL,
			[templateId] [int] NOT NULL,
			[Template] [varchar](50) NOT NULL,
			[question] [varchar](100) NULL,
			[answer] [varchar](max) NOT NULL,
			[Disposition2] [int] NOT NULL,
			[Dispositions] [int] NOT NULL,
			[avgDisposition] [int] NOT NULL,
			[formaId] [int] NOT NULL,
			[inboundId] [int] NOT NULL,
			[inbound] [varchar](100) NULL,
			[year] [int] NOT NULL,
			[month] [int] NOT NULL,
			[day] [int] NOT NULL,
			[hour] [int] NOT NULL,
			[minutes] [int] NOT NULL
			) ON [PRIMARY]
		end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -  RepAVRSRateDetail'
		set @sql='if not exists (select * from sys.tables where name = N''RepAVRSRateDetail'')
		begin			
			CREATE TABLE [dbo].[RepAVRSRateDetail](
			[date] [datetime] NOT NULL,
			[userId] [int] NOT NULL,
			[user] [varchar](50) NOT NULL,
			[agentName] [varchar](50) NOT NULL,
			[supervisorId] [varchar](50) NOT NULL,
			[supervisorUser] [varchar](50) NOT NULL,
			[Supervisor] [varchar](50) NOT NULL,
			[idMedia] [int] NOT NULL,
			[media] [varchar](50) NOT NULL,
			[templateId] [int] NOT NULL,
			[Template] [varchar](50) NOT NULL,
			[Section] [varchar](100) NULL,
			[question] [varchar](100) NULL,
			[answer] [varchar](max) NOT NULL,
			[Disposition2] [int] NOT NULL,
			[Dispositions] [int] NOT NULL,
			[avgDisposition] [int] NOT NULL,
			[cam_id] [int] NOT NULL,
			[tipoLlamada] [int] NOT NULL,
			[campaignAcd] [varchar](100) NULL,
			[formaId] [int] NOT NULL,
			[year] [int] NOT NULL,
			[month] [int] NOT NULL,
			[day] [int] NOT NULL,
			[hour] [int] NOT NULL,
			[minutes] [int] NOT NULL
			) ON [PRIMARY]
		end'
		EXEC(@sql)
	
		set @process = 'CREATE TABLE -  RepAVRSScores'
		set @sql='if not exists (select * from sys.tables where name = N''RepAVRSScores'')
		begin				
			CREATE TABLE [dbo].[RepAVRSScores](
			[date] [datetime] NOT NULL,
			[userId] [int] NOT NULL,
			[login] [varchar](50) NOT NULL,
			[agentName] [varchar](50) NOT NULL,
			[disposition] [int] NOT NULL,
			[avgDisposition] [float] NOT NULL,
			[year] [int] NOT NULL,
			[month] [int] NOT NULL,
			[day] [int] NOT NULL,
			[hour] [int] NOT NULL,
			[minutes] [int] NOT NULL
			) ON [PRIMARY]
		end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -  RepAVRSSection'
		set @sql='if not exists (select * from sys.tables where name = N''RepAVRSSection'')
		begin				
			CREATE TABLE [dbo].[RepAVRSSection](
			[date] [datetime] NOT NULL,
			[userId] [int] NOT NULL,
			[user] [varchar](50) NOT NULL,
			[agentName] [varchar](50) NOT NULL,
			[supervisorId] [int] NOT NULL,
			[supervisorUser] [varchar](50) NOT NULL,
			[Supervisor] [varchar](50) NOT NULL,
			[templateId] [int] NOT NULL,
			[Template] [varchar](50) NOT NULL,
			[sectionId] [int] NOT NULL,
			[Section] [varchar](50) NOT NULL,
			[Dispositions] [int] NOT NULL,
			[Disposition2] [int] NOT NULL,
			[avgDisposition] [int] NOT NULL,
			[score] [int] NOT NULL,
			[idMedia] [int] NULL,
			[media] [varchar](50) NULL,
			[cam_id] [int] NULL,
			[tipoLlamada] [int] NULL,
			[campaignAcd] [varchar](50) NULL,
			[idForma] [int] NOT NULL,
			[year] [int] NOT NULL,
			[month] [int] NOT NULL,
			[day] [int] NOT NULL,
			[hour] [int] NOT NULL,
			[minutes] [int] NOT NULL
			) ON [PRIMARY]
		end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -  RepAVRSSupervisor'
		set @sql='if not exists (select * from sys.tables where name = N''RepAVRSSupervisor'')
		begin				
			CREATE TABLE [dbo].[RepAVRSSupervisor](
			[date] [datetime] NOT NULL,
			[userId] [int] NOT NULL,
			[user] [varchar](50) NOT NULL,
			[agentName] [varchar](50) NOT NULL,
			[Dispositions] [int] NOT NULL,
			[Disposition2] [int] NOT NULL,
			[avgDisposition] [int] NOT NULL,
			[supervisorId] [int] NOT NULL,
			[supervisorUser] [varchar](50) NOT NULL,
			[Supervisor] [varchar](50) NOT NULL,
			[idFormato] [int] NULL,
			[Template] [varchar](50) NULL,
			[idMedia] [int] NULL,
			[media] [varchar](50) NULL,
			[cam_id] [int] NULL,
			[tipoLlamada] [int] NULL,
			[campaignAcd] [varchar](50) NULL,
			[year] [int] NULL,
			[month] [int] NULL,
			[day] [int] NULL,
			[hour] [int] NULL,
			[minutes] [int] NULL
			) ON [PRIMARY]
		end'
		EXEC(@sql)

		set @process = 'Create SP -- ccspRepAVRSAgentChat'
		if not exists (select * from sys.procedures where name = N'ccspRepAVRSAgentChat')
			set @sql='CREATE PROCEDURE  [dbo].[ccspRepAVRSAgentChat]
				@action as tinyint,
				@from as datetime = null,
				@to as datetime = null
				AS

				if @from is null
					select @from = convert(datetime,convert(varchar(11),getdate()))
				select @to = getdate()

				if @action = 1
				BEGIN

					---Before insert delete first  table dbo.RepAVRSAgent 
					DELETE FROM dbo.RepAVRSAgentChat with(rowlock)
					where date >= @from AND date < @to

					INSERT INTO dbo.RepAVRSAgentChat
					select
						DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS lDate,
						a.User_id AS userId,
						a.Login AS lUser,
						(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agentName, 
						f.total_forma AS Dispositions, 
						f.total_forma AS Disposition2, 
						f.total_forma AS avgDisposition,
						f.id_formato AS idFormato,
						k.nombre AS Template,		
						f.id_chat AS chatId,
						i.Inbound_id AS inboundId,
						i.descripcion AS inbound,	 
						YEAR(f.fecha_calif) AS [year], 
						MONTH(f.fecha_calif) AS [month], 
						DAY(f.fecha_calif) AS [day], 
						CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
						CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
					from dbo.RIA_FORMACALIF_CHAT f
						INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
						INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
												 FROM dbo.RIA_FORMATOS
												 WHERE activo = 1
												 GROUP BY id_formato,nombre) as t 
												 ON t.id_formato= f.id_formato
						INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
						INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
						INNER JOIN ccinbound AS i ON c.inboundId = i.Inbound_id
					WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
					
				END'
		else
			set @sql = ''
		
		EXEC(@sql)

		set @process = 'Create SP -- ccspRepAVRSDetailChat'
		if not exists (select * from sys.procedures where name = N'ccspRepAVRSDetailChat')
			set @sql='CREATE PROCEDURE  [dbo].[ccspRepAVRSDetailChat]
			@action as tinyint,
			@from as datetime = null,
			@to as datetime = null
			AS
			set nocount on

			declare @idioma as tinyint
			select @idioma = valor from ccSettings where setting_id=23


			if @from is null
				select @from = convert(datetime,convert(varchar(11),getdate()))
			select @to = getdate()

			if @action = 1
			BEGIN		
				---Before insert delete first table dbo.RepAVRSQuestionDetail 
				DELETE FROM dbo.RepAVRSDetailChat with(rowlock)
				where date >= @from AND date < @to

				INSERT INTO dbo.RepAVRSDetailChat

					select
					DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
					a.User_id,
					a.Login,
					(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
					t.id_formato,
					t.nombre,
					p.enunciado_pregunta,
					r.etiquetas,
					r.peso as avgDisposition,
					i.Inbound_id AS inboundId,
					i.descripcion AS inbound	
				from RIA_RESULTADOSFORMA_CHAT r
				INNER JOIN dbo.RIA_FORMACALIF_CHAT f ON f.id_forma = r.id_forma
				INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
				INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
										 FROM dbo.RIA_FORMATOS
										 WHERE activo = 1 and tipo=2
										 GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
				INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
				INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
				INNER JOIN ccinbound AS i ON c.inboundId = i.Inbound_id
				WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
				
			set nocount off
			END'
		else
			set @sql = ''
		
		EXEC(@sql)

		set @process = 'Create SP -- ccspRepAVRSQuestion'
		if not exists (select * from sys.procedures where name = N'ccspRepAVRSQuestion')
			set @sql='CREATE PROCEDURE  [dbo].[ccspRepAVRSQuestion]
			@action as tinyint,
			@from as datetime = null,
			@to as datetime = null
			AS
			set nocount on

			declare @idioma as tinyint
			select @idioma = valor from ccSettings where setting_id=23


			if @from is null
				select @from = convert(datetime,convert(varchar(11),getdate()))
			select @to = getdate()

			if @action = 1
			BEGIN		
				---Before insert delete first table dbo.RepAVRSQuestionDetail 
				DELETE FROM dbo.RepAVRSQuestion with(rowlock)
				where date >= @from AND date < @to

				INSERT INTO dbo.RepAVRSQuestion

				select
					DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
					a.User_id,
					a.Login,
					(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
					s.User_id,
					s.Login,
					(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
					t.id_formato,
					t.nombre,
					c.id_concepto,
					c.con_descripcion,
					p.id_pregunta,
					p.enunciado_pregunta,
					r.peso as avgDisposition,
					r.peso as avgDisposition,
					r.peso as avgDisposition,
					f.id_grabacion,
					(case f.tipo 
						when ''1'' then CASE WHEN @idioma = 0 THEN ''Grabaciones'' ELSE ''Recordings'' END 
						when ''2'' then ''Chat''
					end) as Medio,	
					f.cam_id as CamId,
					(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
					 AS Cam	
				from RIA_RESULTADOSFORMA r
				INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
				INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
				INNER JOIN dbo.ccUsers s ON f.id_calificador = s.User_id
				INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
										 FROM dbo.RIA_FORMATOS
										 WHERE activo = 1 and tipo=1
										 GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
				INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
				INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
				left join cccamps AS e ON f.cam_id = e.cam_id
				left join ccinbound AS u ON f.cam_id = u.Inbound_id
				WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
				
			set nocount off
			END'
		else
			set @sql = ''
		
		EXEC(@sql)

		set @process = 'Create SP -- ccspRepAVRSQuestionChat'
		if not exists (select * from sys.procedures where name = N'ccspRepAVRSQuestionChat')
			set @sql='CREATE PROCEDURE  [dbo].[ccspRepAVRSQuestionChat]
				@action as tinyint,
				@from as datetime = null,
				@to as datetime = null
				AS
				set nocount on

				declare @idioma as tinyint
				select @idioma = valor from ccSettings where setting_id=23


				if @from is null
					select @from = convert(datetime,convert(varchar(11),getdate()))
				select @to = getdate()

				if @action = 1
				BEGIN		
					---Before insert delete first table dbo.RepAVRSQuestionDetail 
					DELETE FROM dbo.RepAVRSQuestionChat with(rowlock)
					where date >= @from AND date < @to

					INSERT INTO dbo.RepAVRSQuestionChat

						select
						DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
						a.User_id,
						a.Login,
						(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
						t.id_formato,
						t.nombre,
						p.id_pregunta,
						p.enunciado_pregunta,
						r.peso as avgDisposition,
						r.peso as avgDisposition,
						r.peso as avgDisposition,
						i.Inbound_id AS inboundId,
						i.descripcion AS inbound	
					from RIA_RESULTADOSFORMA_CHAT r
					INNER JOIN dbo.RIA_FORMACALIF_CHAT f ON f.id_forma = r.id_forma
					INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
					INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
											 FROM dbo.RIA_FORMATOS
											 WHERE activo = 1 and tipo=2
											 GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
					INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
					INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
					INNER JOIN ccinbound AS i ON c.inboundId = i.Inbound_id
					WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
					
				set nocount off
				END'
		else
			set @sql = ''
		
		EXEC(@sql)

		set @process = 'Create SP -- ccspRepAVRSRateChat'
		if not exists (select * from sys.procedures where name = N'ccspRepAVRSRateChat')
			set @sql='CREATE PROCEDURE  [dbo].[ccspRepAVRSRateChat]
				@action as tinyint,
				@from as datetime = null,
				@to as datetime = null
				AS

				if @from is null
					select @from = convert(datetime,convert(varchar(11),getdate()))
				select @to = getdate()

				if @action = 1
				BEGIN

					---Before insert delete first  table dbo.RepAVRSAgent 
					DELETE FROM dbo.RepAVRSRateChat with(rowlock)
					where date >= @from AND date < @to

					INSERT INTO dbo.RepAVRSRateChat
					select
						DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS lDate,
						a.User_id AS userId,
						a.Login AS lUser,
						(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agentName, 
						f.id_chat AS chatId,
						f.id_formato AS idFormato,
						k.nombre AS Template,
						p.enunciado_pregunta,
						r.etiquetas,
						r.peso AS Dispositions, 
						r.peso AS Disposition2, 
						r.peso AS avgDisposition,
						f.id_forma,
						u.Inbound_id,
						u.descripcion,		 
						YEAR(f.fecha_calif) AS [year], 
						MONTH(f.fecha_calif) AS [month], 
						DAY(f.fecha_calif) AS [day], 
						CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
						CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
					from dbo.RIA_FORMACALIF_CHAT f
						INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
						INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
												 FROM dbo.RIA_FORMATOS
												 WHERE activo = 1
												 GROUP BY id_formato,nombre) as t 
												 ON t.id_formato= f.id_formato
						INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
						INNER JOIN RIA_RESULTADOSFORMA_CHAT r ON f.id_forma=r.id_forma
						INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
						INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
						INNER JOIN ccinbound AS u ON c.inboundId = u.Inbound_id
					WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
					
				END'
		else
			set @sql = ''
		
		EXEC(@sql)

		set @process = 'alter SP  - ccspRepAVRSAgent'
		if exists (select * from sys.procedures where name = N'ccspRepAVRSAgent')
			set @sql='ALTER PROCEDURE [dbo].[ccspRepAVRSAgent]		
				@action as tinyint,
				@from as datetime = null,
				@to as datetime = null
				AS

				declare @idioma as tinyint
				select @idioma = valor from ccSettings where setting_id=23

				if @from is null
					select @from = convert(datetime,convert(varchar(11),getdate()))
				select @to = getdate()

				if @action = 1
				BEGIN

					---Before insert delete first  table dbo.RepAVRSAgent 
					DELETE FROM dbo.RepAVRSAgent with(rowlock)
					where date >= @from AND date < @to

					INSERT INTO dbo.RepAVRSAgent
					--By Agent		
					select
						DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
						a.User_id,
						a.Login,
						(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
						f.total_forma AS scores, 
						f.total_forma AS scores, 
						f.total_forma AS scores,
						s.User_id,
						s.Login,
						(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
						f.id_formato,
						k.nombre,		
						f.id_grabacion,
						(case f.tipo 
							when ''1'' then CASE WHEN @idioma = 0 THEN ''Grabaciones'' ELSE ''Recordings'' END 
							when ''2'' then ''Chat''
						end) as Medio,	
						f.cam_id as CamId,
						f.tipo_llamada as TipoLlamada,	
						(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
						 AS Cam,		 
						YEAR(f.fecha_calif) AS [year], 
						MONTH(f.fecha_calif) AS [month], 
						DAY(f.fecha_calif) AS [day], 
						CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
						CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
					from dbo.RIA_FORMACALIF f
					INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
					INNER JOIN dbo.ccUsers s ON f.id_calificador = s.User_id
					INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
											 FROM dbo.RIA_FORMATOS 
											 WHERE activo = 1 and tipo=1
											 GROUP BY id_formato,nombre) as t 
											 ON t.id_formato= f.id_formato
					INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
					left join cccamps AS e ON f.cam_id = e.cam_id
					left join ccinbound AS u ON f.cam_id = u.Inbound_id
					WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
				END'
		else
			set @sql = ''

		EXEC(@sql)

		set @process = 'alter SP  - ccspRepAVRSQuestionDetail'
		if exists (select * from sys.procedures where name = N'ccspRepAVRSQuestionDetail')
			set @sql='ALTER PROCEDURE [dbo].[ccspRepAVRSQuestionDetail]
			@action as tinyint,
			@from as datetime = null,
			@to as datetime = null
			AS
			set nocount on

			declare @idioma as tinyint
			select @idioma = valor from ccSettings where setting_id=23


			if @from is null
				select @from = convert(datetime,convert(varchar(11),getdate()))
			select @to = getdate()

			if @action = 1
			BEGIN		
				---Before insert delete first table dbo.RepAVRSQuestionDetail 
				DELETE FROM dbo.RepAVRSQuestionDetail with(rowlock)
				where date >= @from AND date < @to

				INSERT INTO dbo.RepAVRSQuestionDetail

				select
					DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
					a.User_id,
					a.Login,
					(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
					s.Login,
					(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
					t.nombre,
					c.con_descripcion,
					p.enunciado_pregunta,
					r.etiquetas,
					r.peso as avgDisposition,
					(case f.tipo 
						when ''1'' then CASE WHEN @idioma = 0 THEN ''Grabaciones'' ELSE ''Recordings'' END 
						when ''2'' then ''Chat''
					end) as Medio,	
					f.cam_id as CamId,
					(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
					 AS Cam
					--YEAR(f.fecha_calif) AS [year], 
					--MONTH(f.fecha_calif) AS [month], 
					--DAY(f.fecha_calif) AS [day], 
					--CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
					--CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]		
				from RIA_RESULTADOSFORMA r
				INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
				INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
				INNER JOIN dbo.ccUsers s ON f.id_calificador = s.User_id
				INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
										 FROM dbo.RIA_FORMATOS
										 WHERE activo = 1 and tipo=1
										 GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
				INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
				INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
				left join cccamps AS e ON f.cam_id = e.cam_id
				left join ccinbound AS u ON f.cam_id = u.Inbound_id
				WHERE f.fecha_calif >= @from AND f.fecha_calif < @to	

				set nocount off
			END	
			'
		else
			set @sql = ''

		EXEC(@sql)

		set @process = 'alter SP  - ccspRepAVRSRateDetail'
		if exists (select * from sys.procedures where name = N'ccspRepAVRSRateDetail')
			set @sql='ALTER PROCEDURE [dbo].[ccspRepAVRSRateDetail]
			@action as tinyint,
			@from as datetime = null,
			@to as datetime = null
			AS

			declare @idioma as tinyint
			select @idioma = valor from ccSettings where setting_id=23

			if @from is null
				select @from = convert(datetime,convert(varchar(11),getdate()))
			select @to = getdate()

			if @action = 1
			BEGIN
				---Before insert delete first  table dbo.RepAVRRateDetail 
				DELETE FROM dbo.RepAVRSRateDetail with(rowlock)
				where date >= @from AND date < @to

				INSERT INTO dbo.RepAVRSRateDetail

				select
					DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
					a.User_id,
					a.Login,
					(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
					s.User_id,
					s.Login,
					(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
					f.id_grabacion,
					(case f.tipo 
						when ''1'' then CASE WHEN @idioma = 0 THEN ''Grabaciones'' ELSE ''Recordings'' END 
						when ''2'' then ''Chat''
					end) as Medio,
					t.id_formato,
					t.nombre,
					c.con_descripcion,
					p.enunciado_pregunta,
					r.etiquetas,
					r.peso as avgDisposition,	
					r.peso as avgDisposition,	
					r.peso as avgDisposition,
					f.cam_id as CamId,
					f.tipo,
					(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
					 AS Cam,
					r.id_forma,
					YEAR(f.fecha_calif) AS [year], 
					MONTH(f.fecha_calif) AS [month], 
					DAY(f.fecha_calif) AS [day], 
					CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
					CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]		
				from RIA_RESULTADOSFORMA r
				INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
				INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
				INNER JOIN dbo.ccUsers s ON f.id_calificador = s.User_id
				INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
										 FROM dbo.RIA_FORMATOS
										 WHERE activo = 1 and tipo=1
										 GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
				INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
				INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
				left join cccamps AS e ON f.cam_id = e.cam_id
				left join ccinbound AS u ON f.cam_id = u.Inbound_id
				WHERE f.fecha_calif >= @from AND f.fecha_calif < @to

			END
			'
		else
			set @sql = ''

		EXEC(@sql)

		set @process = 'alter SP  - ccspRepAVRSSection'
		if exists (select * from sys.procedures where name = N'ccspRepAVRSSection')
			set @sql='ALTER PROCEDURE [dbo].[ccspRepAVRSSection]
			@action as tinyint,
			@from as datetime = null,
			@to as datetime = null
			AS

			declare @idioma as tinyint
			select @idioma = valor from ccSettings where setting_id=23


			if @from is null
				select @from = convert(datetime,convert(varchar(11),getdate()))
			select @to = getdate()

			if @action = 1
			BEGIN
				---Before insert delete first  table dbo.RepAVRSSection 
				DELETE FROM dbo.RepAVRSSection with(rowlock)
				where date >= @from AND date < @to

				INSERT INTO dbo.RepAVRSSection
				
				select
					DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
					a.User_id,
					a.Login,
					(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
					s.User_id,
					s.Login,
					(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
					f.id_formato,
					t.nombre,
					c.id_concepto,
					c.con_descripcion,
					r.peso AS scores, 
					r.peso as avgDisposition,
					r.peso as avgDisposition,
					r.peso as avgDisposition,
					f.id_grabacion,
					(case f.tipo 
						when ''1'' then CASE WHEN @idioma = 0 THEN ''Grabaciones'' ELSE ''Recordings'' END 
						when ''2'' then ''Chat''
					end) as Medio,	
					f.cam_id as CamId,
					f.tipo_llamada as TipoLlamada,	
					(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
					 AS Cam,
					 f.id_forma,		 
					YEAR(f.fecha_calif) AS [year], 
					MONTH(f.fecha_calif) AS [month], 
					DAY(f.fecha_calif) AS [day], 
					CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
					CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]		
				from RIA_RESULTADOSFORMA r
				INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
				INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
				INNER JOIN dbo.ccUsers s ON f.id_calificador = s.User_id
				INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
										 FROM dbo.RIA_FORMATOS
										 WHERE activo = 1 and tipo=1
										 GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
				INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
				INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
				left join cccamps AS e ON f.cam_id = e.cam_id
				left join ccinbound AS u ON f.cam_id = u.Inbound_id
				WHERE f.fecha_calif >= @from AND f.fecha_calif < @to

				END'
		else
			set @sql = ''

		EXEC(@sql)

		set @process = 'alter SP  - ccspRepAVRSSupervisor'
		if exists (select * from sys.procedures where name = N'ccspRepAVRSSupervisor')
			set @sql='ALTER PROCEDURE [dbo].[ccspRepAVRSSupervisor]
			@action as tinyint,
			@from as datetime = null,
			@to as datetime = null
			AS

			declare @idioma as tinyint
			select @idioma = valor from ccSettings where setting_id=23


			if @from is null
				select @from = convert(datetime,convert(varchar(11),getdate()))
			select @to = getdate()	

			if @action = 1
			BEGIN
				---Before insert delete first  table dbo.RepAVRSSupervisor 
				DELETE FROM dbo.RepAVRSSupervisor with(rowlock) 
				where date >= @from AND date < @to

				INSERT INTO dbo.RepAVRSSupervisor
				--By Supervisor
				select
					DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
					a.User_id,
					a.Login,
					(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
					f.total_forma AS scores, 
					f.total_forma AS scores, 
					f.total_forma AS scores,
					s.User_id,
					s.Login,
					(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
					f.id_formato,
					k.nombre,		
					f.id_grabacion,
					(case f.tipo 
						when ''1'' then CASE WHEN @idioma = 0 THEN ''Grabaciones'' ELSE ''Recordings'' END 
						when ''2'' then ''Chat''
					end) as Medio,	
					f.cam_id as CamId,
					f.tipo_llamada as TipoLlamada,	
					(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END)
					 AS Cam,		 
					YEAR(f.fecha_calif) AS [year], 
					MONTH(f.fecha_calif) AS [month], 
					DAY(f.fecha_calif) AS [day], 
					CAST(DATEPART(hour, f.fecha_calif) as varchar(2)) AS [hour], 
					CAST(DATEPART(minute, f.fecha_calif) as varchar(2)) AS [minute]
				from dbo.RIA_FORMACALIF f
				INNER JOIN dbo.ccUsers a ON f.age_id = a.User_id
				INNER JOIN dbo.ccUsers s ON f.id_calificador = s.User_id
				INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
										 FROM dbo.RIA_FORMATOS
										 WHERE activo = 1
										 GROUP BY id_formato,nombre) as t 
										 ON t.id_formato= f.id_formato
				INNER JOIN dbo.RIA_FORMATOS k ON k.id_formato=f.id_formato
				left join cccamps AS e ON f.cam_id = e.cam_id
				left join ccinbound AS u ON f.cam_id = u.Inbound_id
				WHERE f.fecha_calif >= @from AND f.fecha_calif < @to

			END'
		else
			set @sql = ''

		EXEC(@sql)

		set @process = 'Alter SP - ccspRepCallXfer'
		if exists (select * from sys.procedures where name = N'ccspRepCallXfer')
			set @sql='ALTER PROCEDURE [dbo].[ccspRepCallXfer]
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

					delete RepCallXfer with(rowlock)
					where [date] between @from and @to
					
					insert RepCallXfer select convert(varchar(10),fechafin,121) [date],
					clt.cal_id callid, case when tipo = 1 then ''systemTranslated_inbound'' else ''systemTranslated_outbound'' end CallTypes, 
					isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccusers nolock where user_id = 
					(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') Agent,
					case when modo = 0 then ''systemTranslated_blindXfer'' 
					when modo = 1 then ''systemTranslated_Agent'' 
					when modo = 2 then ''systemTranslated_acd'' 
					when modo = 3 then ''systemTranslated_conference'' 
					when modo = 4 then ''systemTranslated_supXfer'' 
					when modo = 5 then ''systemTranslated_overflow'' end as xfertype,
					case when modo = 0 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
					when modo = 1 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),''systemTranslated_Indefinite'') 
					when modo = 2 then isnull((select descripcion from ccinbound where inbound_id = clt.destino),''systemTranslated_Indefinite'') 
					when modo = 3 then isnull((select nombre from telefonosConferencia where tel = clt.destino),clt.destino) 
					when modo = 4 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
					when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end destination,
					tantesxfer timebeforexfer,
					tdespuesxfer timeafterxfer,
					dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate,
					fechafin as endDate
					from cclogtransfers clt 
					left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
					left join cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1
					WHERE fechafin >= @from and fechafin < @to
				end'
		else
			set @sql = ''

		EXEC(@sql)

		set @process = 'Alter SP -- ccspRepAgentGI'
		if exists (select * from sys.procedures where name = N'ccspRepAgentGI')
			set @sql='ALTER PROCEDURE [dbo].[ccspRepAgentGI]
				@action as tinyint,
				@from as datetime = null,
				@to as datetime = null
				AS
				 
				SET ANSI_WARNINGS off
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
				 
				      declare @starttime datetime
				      declare @number int
				      set @starttime = @from
				      set @number = 0     
				      create table #notReady(
				            [Row] int identity,
				            dateStartDetail datetime,
				            dateEndDetail     datetime,
				            timegroup   datetime,
				            timegroup_next    datetime,
				            User_id     int,
				            timeNotReady int
				      )
				     
				      create table #inboundData(
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
				     
				      create table #outboundData(
				      row int identity,
				      dateStartDetail datetime,
				      dateEndDetail datetime,
				      timegroup datetime,
				      timegroup_next datetime,
				      cam_id int,
				      User_id int,
				      ntotal int,
				      nno_agent int,
				      nxfer int,
				      nabnd_xfer int,
				      nabnd_ring int,
				      nno_answer int,
				      nabnd_dialog int,
				      nanswer int,
				      nlost int,
				      tque int,
				      txfer int,
				      tring int,
				      tdialog int,
				      tnotes int,
				      tresp int,
				      nhangup int,
				      nMoh int,
				      nWHag int,
				      nWHcl int,
				      time_endque datetime,
				      time_ring datetime,
				      time_dialog datetime,
				      time_notes datetime,
				      time_end_call datetime,
				      phone_out varchar(30),
				      cal_id int,
				      cal_puerto int)
				     
				      CREATE TABLE #times(
				      [ID] INT primary key,
				      [Start] DATETIME,
				      [Stop] DATETIME
				      )
				 
				      create nonclustered index ix_times on #times(
				      [Start] DESC,
				      [Stop] DESC
				      )
				      create nonclustered index ix_times2 on #times([Start] DESC)
				 
				      while @number <= (datediff(mi,@starttime,@to)/15)
				      begin
				            insert into #times
				            SELECT [Hour] = @number,
				            StartTime = DATEADD(mi, @number*15, @starttime),
				            EndTime = DATEADD(mi, (@number+1)*15, @StartTime)
				 
				            set @number = @number +1
				      end
				 
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

					insert into #inboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
					SELECT      cal_inicio as dateStartDetail,
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
								between 45 and 59 then  convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas+60),0),cal_inicio) ,121) + '':00:00.000'' end as timegroup_next
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
					         
					insert into #outboundData(dateStartDetail,dateEndDetail,timegroup,timegroup_next,cam_id,User_id,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,tque,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_out,cal_id,cal_puerto)
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
								between 45 and 59 then  convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas + 60),0),cal_Inicio) ,121) + '':00:00.000'' end as timegroup_next 
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
						  group by cal_id,[User_id],cam_id,cal_Inicio,cal_puerto

					delete from #outboundData WHERE timegroup>=@from AND timegroup<@to
						  AND ntotal=0 AND nno_agent=0 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
						  AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
						  AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0       
				               
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
				                    
					drop table #outboundData2         
					
					create table #timeDetailAgent(
					dateStartDetail datetime null,
					dateEndDetail datetime null,
					timegroup varchar(30) null,
					timegroup_next varchar(30) null,
					User_id int null,
					tunknown int null,
					tnot_av int null,
					tav int null,
					tprob int null,
					tother int null,
					nother int null,
					tmanualcall int null
					)

					insert into #timeDetailAgent
					select DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
						  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
								when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
								when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
								when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end) AS timegroup
						  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
								when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
								when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
								when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end) as timegroup_next
								,[User_id]
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
						  convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
								when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
								when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
								when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end)
						  ,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
								when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
								when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
								when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end), [User_id]

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
						  ,ISNULL(nMoh,0) as nMoh,ISNULL(nWHag,0) as nWHag,ISNULL(nWHcl,0) as nWHcl,ISNULL(tmanualcall,0) as tmanualcall
						  ,ISNULL((SELECT top 1 DATEDIFF(ss,login,DATEADD(ss,899,xTimeDetail.timegroup))
										   FROM #sessionTime
										   WHERE [user_id]=xTimeDetail.[user_id]
										   AND login>=xTimeDetail.timegroup 
										   AND login<DATEADD(ss,899,xTimeDetail.timegroup)	
				                           AND logout>=DATEADD(ss,899,xTimeDetail.timegroup)
								),0)AS t1
						  ,ISNULL((SELECT top 1 DATEDIFF(ss,login,logout)
										   FROM #sessionTime
										   WHERE [user_id]=xTimeDetail.[user_id]
										   AND login>=xTimeDetail.timegroup 
										   AND login<DATEADD(ss,899,xTimeDetail.timegroup)	
				                           AND logout<DATEADD(ss,899,xTimeDetail.timegroup)
										   AND login < logout
								),0)AS t2
						  ,ISNULL((SELECT top 1 DATEDIFF(ss,xTimeDetail.timegroup ,logout)
										   FROM #sessionTime
										   WHERE [user_id]=xTimeDetail.[user_id]
										   AND login<xTimeDetail.timegroup 
				                           AND logout<=DATEADD(ss,899,xTimeDetail.timegroup)
										   AND logout>xTimeDetail.timegroup 
								),0)AS t3
						   ,ISNULL((SELECT top 1 DATEDIFF(ss,xTimeDetail.timegroup ,DATEADD(ss,899,xTimeDetail.timegroup))
										   FROM #sessionTime
										   WHERE [user_id]=xTimeDetail.[user_id]
										   AND login<xTimeDetail.timegroup 
				                           AND logout>DATEADD(ss,899,xTimeDetail.timegroup)
								),0)AS t4
						  into #agentInformation
						  from (select min(dateStartDetail) as dateStartDetail,min(dateEndDetail) as dateEndDetail,timegroup,timegroup_next,[User_id]
							 ,sum(tunknown) as tunknown,sum(tnot_av) as tnot_av,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother,sum(nother) as nother, sum(tmanualcall) as tmanualcall
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
				order by  xTimeDetail.[user_id], xTimeDetail.timegroup

					drop table #timeDetailAgent

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
					   
					drop table #notReady2
					               

					select
						ROW_NUMBER() OVER(ORDER BY  CASE WHEN #agentInformation.timegroup IS NOT NULL THEN #agentInformation.timegroup
									WHEN calls.timegroup IS NOT NULL  THEN calls.timegroup ELSE 0 END,CASE WHEN #agentInformation.user_id IS NOT NULL THEN #agentInformation.user_id
									WHEN calls.userId IS NOT NULL THEN calls.userId ELSE - 1 END) AS id
						,dbo.#agentInformation.row as rowAgentInformation
						,isnull(dbo.#notReady.Row,-1) as rowNotReady        
						,rowIn,rowOut,
						calLIdIn,phoneIn,dateStartDetailIn,callIdOut,phoneOut,dateStartDetailOut,                          
						CASE WHEN #agentInformation.timegroup IS NOT NULL THEN #agentInformation.timegroup
							  WHEN calls.timegroup IS NOT NULL  THEN calls.timegroup ELSE 0 END AS date
						,CASE WHEN #agentInformation.user_id IS NOT NULL THEN #agentInformation.user_id
								WHEN calls.userId IS NOT NULL THEN calls.userId ELSE - 1 END AS [userId]
						,u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + nombres as [user] , u.login as [login]
						,isnull(nxfer_in,0) as nxferin, isnull(nanswer_in,0) as nanswerin, isnull(nabnd_xfer_in,0) as nabndxferin
						,isnull(nabnd_ring_in,0) as nabndringin,isnull(nabnd_dlg_in,0) as nabnddlgin,isnull(abnd_a_xfer_in,0) as abndaxferin
						,isnull(nno_answer_in,0) as nnoanswerin,isnull(nlost_in,0) as nlostin,isnull(tdialog_in,0) as tdialogin
						,isnull(tnotes_in,0) as tnotesin,isnull(tring_in,0) as tringin,isnull(txfer_in,0) as txferin
						,isnull(nxfer_out,0) as nxferout,isnull(nanswer_out,0) as nanswerout,isnull(nabnd_xfer_out,0) as nabndxferout
						,isnull(nabnd_ring_out,0) as nabndringout,isnull(nabnd_dlg_out,0) as nabnddlgout,isnull(abnd_a_xfer_out,0) as abndaxferout
						,isnull(nno_answer_out,0) as nnoanswerout,isnull(nlost_out,0) as nlostout,isnull(tdialog_out,0) as tdialogout
						,isnull(tnotes_out,0) as tnotesout,isnull(tring_out,0) as tringout, isnull(txfer_out,0) as txferout
					   
						,ISNULL(dbo.#agentInformation.nother, 0) AS nother
						,ISNULL(dbo.#agentInformation.tunknown, 0) AS tunknown
						,ISNULL(dbo.#agentInformation.tnot_av, 0) AS tnotav
						,ISNULL(dbo.#agentInformation.t1, 0)+ISNULL(dbo.#agentInformation.t2, 0)+ISNULL(dbo.#agentInformation.t3, 0)+ISNULL(dbo.#agentInformation.t4, 0)  AS tlog
						,ISNULL(dbo.#notReady.timeNotReady, 0) AS treq
						,ISNULL(dbo.#agentInformation.tav, 0) AS tav
						,ISNULL(dbo.#agentInformation.tother, 0) + isnull(tmanualcall,0) AS tother
						,ISNULL(dbo.#agentInformation.tprob, 0) AS tprob
					   
						,isnull(nMoh_in,0) as nMohin,isnull(nMoh_out,0) as nMohout,isnull(nWHag_in,0) as nWHagin
						,isnull(nWHag_out,0) as nWHagout,isnull(nWHcl_in,0) as nWHcliin,isnull(nWHcl_out,0) as nWHcliout
						, CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(yy,#agentInformation.timegroup)
									WHEN calls.timegroup IS NOT NULL THEN datepart(yy,calls.timegroup) ELSE 0 END AS [year]
						  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(mm,#agentInformation.timegroup)
									WHEN calls.timegroup IS NOT NULL THEN datepart(mm,calls.timegroup) ELSE 0 END AS [month]
						  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(dd,#agentInformation.timegroup)
									WHEN calls.timegroup IS NOT NULL THEN datepart(dd,calls.timegroup) ELSE 0 END AS [day]
						  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(hh,#agentInformation.timegroup)
									WHEN calls.timegroup IS NOT NULL THEN datepart(hh,calls.timegroup) ELSE 0 END AS [hour]
						  , CASE WHEN #agentInformation.timegroup IS NOT NULL THEN datepart(mi,#agentInformation.timegroup)
									WHEN calls.timegroup IS NOT NULL THEN datepart(mi,calls.timegroup) ELSE 0 END AS [minutes]
					into #tempRepAgentGI
					FROM  dbo.#agentInformation
					LEFT OUTER JOIN dbo.ccusers u ON (#agentInformation.[user_id] = u.[user_id])
					LEFT OUTER JOIN dbo.#notReady ON #agentInformation.[user_id] = dbo.#notReady.[user_id] AND dbo.#notReady.timegroup = dbo.#agentInformation.timegroup
					right join
						(
					   
						select
							  CASE WHEN #inboundData.timegroup IS NOT NULL THEN #inboundData.timegroup
										 WHEN #outboundData.timegroup IS NOT NULL THEN #outboundData.timegroup ELSE NULL END timegroup,
							  CASE WHEN #inboundData.[user_id] IS NOT NULL THEN #inboundData.[user_id]
									  WHEN #outboundData.[user_id] IS NOT NULL THEN #outboundData.[user_id] ELSE NULL END as [userId]
							  ,ISNULL(dbo.#inboundData.row, -1) as rowIn,ISNULL(dbo.#outboundData.row, -1) as rowOut
							  ,ISNULL((dbo.#inboundData.nxfer), 0) AS nxfer_in, ISNULL((dbo.#inboundData.nanswer), 0) AS nanswer_in, ISNULL((dbo.#inboundData.nabnd_xfer), 0) AS nabnd_xfer_in
							  ,ISNULL((dbo.#inboundData.nabnd_ring), 0) AS nabnd_ring_in, ISNULL((dbo.#inboundData.nabnd_dialog), 0) AS nabnd_dlg_in
							  ,ISNULL((dbo.#inboundData.nabnd_xfer), 0) + ISNULL((dbo.#inboundData.nabnd_ring), 0) + ISNULL((dbo.#inboundData.nabnd_dialog), 0) AS abnd_a_xfer_in
							  ,ISNULL((dbo.#inboundData.nno_answer), 0) AS nno_answer_in, ISNULL((dbo.#inboundData.nlost), 0) AS nlost_in, ISNULL((dbo.#inboundData.tdialog), 0) AS tdialog_in
							  ,ISNULL((dbo.#inboundData.tnotes), 0) AS tnotes_in, ISNULL((dbo.#inboundData.tring), 0) AS tring_in, ISNULL((dbo.#inboundData.txfer), 0) AS txfer_in
							  ,ISNULL((dbo.#inboundData.nMoh), 0) AS nMoh_in, ISNULL((dbo.#inboundData.nWHag), 0) AS nWHag_in,ISNULL((dbo.#inboundData.nWHcl), 0) AS nWHcl_in               
							  ,ISNULL((dbo.#outboundData.nxfer), 0) AS nxfer_out, ISNULL((dbo.#outboundData.nanswer), 0) AS nanswer_out, ISNULL((dbo.#outboundData.nabnd_xfer), 0) AS nabnd_xfer_out
							  ,ISNULL((dbo.#outboundData.nabnd_ring), 0) AS nabnd_ring_out, ISNULL((dbo.#outboundData.nabnd_dialog), 0) AS nabnd_dlg_out
							  ,ISNULL((dbo.#outboundData.nabnd_xfer), 0) + ISNULL((dbo.#outboundData.nabnd_ring), 0) + ISNULL((dbo.#outboundData.nabnd_dialog), 0) AS abnd_a_xfer_out
							  ,ISNULL((dbo.#outboundData.nno_answer), 0) AS nno_answer_out, ISNULL((dbo.#outboundData.nlost), 0) AS nlost_out, ISNULL((dbo.#outboundData.tdialog), 0) AS tdialog_out
							  ,ISNULL((dbo.#outboundData.tnotes), 0) AS tnotes_out, ISNULL((dbo.#outboundData.tring), 0) AS tring_out, ISNULL((dbo.#outboundData.txfer), 0) AS txfer_out
							  ,ISNULL((dbo.#outboundData.nMoh), 0) AS nMoh_out, ISNULL((dbo.#outboundData.nWHag), 0) AS nWHag_out,ISNULL((dbo.#outboundData.nWHcl), 0) AS nWHcl_out
							  ,isnull((dbo.#inboundData.cal_id),'''') as callIdIn,isnull((dbo.#inboundData.phone_in),'''') as phoneIn,isnull((dbo.#inboundData.dateStartDetail),'''') as dateStartDetailIn
							  ,isnull((dbo.#outboundData.cal_id),'''') as callIdOut,isnull((dbo.#outboundData.phone_out),'''') as phoneOut,isnull((dbo.#outboundData.dateStartDetail),'''') as dateStartDetailOut
						from #inboundData
						FULL OUTER JOIN #outboundData ON(#inboundData.timegroup=#outboundData.timegroup AND #inboundData.[user_id]=#outboundData.[user_id])       
						)calls on calls.timegroup = #agentInformation.timegroup and #agentInformation.[user_id]=calls.[userid]    
						where #agentInformation.timegroup is not null
				     
				     
				      SELECT 
				      RANK() OVER(PARTITION BY rowAgentInformation ORDER by id) as [rank],
				      ROW_NUMBER() OVER(Order by id) as rowNumber,
				      id
				      into #tempTime
				      FROM #tempRepAgentGI
				      where rowAgentInformation in
				            (select rowAgentInformation from #tempRepAgentGI temp GROUP BY temp.rowAgentInformation HAVING Count(*) > 1 )
				           
				      update t
				            set nother=0,tunknown=0,tnotav=0,tlog=0,tother=0,tprob=0,tav=0
				            from #tempRepAgentGI t
				            inner join #tempTime temp on t.id = temp.id
				            where [rank]>1
				     
				      delete #tempTime
				     
				      insert into #tempTime
				      SELECT 
				      RANK() OVER(PARTITION BY rowNotReady ORDER by id) as [rank],
				      ROW_NUMBER() OVER(Order by id) as rowNumber,
				      id
				      FROM #tempRepAgentGI
				      where rowNotReady in
				            (select rowNotReady from #tempRepAgentGI temp GROUP BY temp.rowNotReady HAVING Count(*) > 1 )   
				                 
				      update t
				            set treq=0
				            from #tempRepAgentGI t
				            inner join #tempTime temp on t.id = temp.id
				            where [rank]>1
				     
				      delete #tempTime
				     
				      insert into #tempTime
				      SELECT 
				      RANK() OVER(PARTITION BY rowIn ORDER by id) as [rank],
				      ROW_NUMBER() OVER(Order by id) as rowNumber,
				      id
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
				     
				      delete from RepAgentGI with(rowlock)
					  where date >= @from AND date < @to
				           
				      insert into RepAgentGI(date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,treq,tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotavg)
				      select
				            date,userId,[user],login,nxferin,nanswerin,nabndxferin,nabndringin,nabnddlgin,abndaxferin,nnoanswerin,nlostin,tdialogin,tnotesin,tringin,txferin,nxferout,nanswerout,nabndxferout,nabndringout,nabnddlgout,abndaxferout,nnoanswerout,nlostout,tdialogout,tnotesout,tringout,txferout,nother,tunknown,tnotav,tlog,treq,tav,tother,tprob,nmohin,nmohout,nwhagin,nwhagout,nwhcliin,nwhcliout,year,month,day,hour,minutes,phonein,dateStartDetailIn,callIdIn,phoneout,dateStartDetailOut,callIdOut,tnotav
				      from #tempRepAgentGI           
				       
					update RepAgentGI
					set tlog = 0
					where date >= @from AND date < @to
					and tdialogout = 0
					and tlog > 0

				      drop table #times
				      drop table #sessionTime
				      drop table #inboundData
				      drop table #outboundData
				      drop table #agentInformation
				      drop table #notReady
				      drop table #tempTime
				      drop table #tempRepAgentGI        
				     
				end'
		else
			set @sql = ''

		EXEC(@sql)

		set @process = 'Add CRMx capabilities to ReportsV2'
		set @sql='IF (SELECT COUNT(*) 
				FROM Filters 
				WHERE [id] = 23) = 0
				BEGIN
					INSERT INTO [dbo].[Filters] ([id],[name],[type],[xmlParentNode],[xmlChildNode]) 
					VALUES (23,''CRMxTemplates'',22,''CRMxTemplates'',''CRMxTemplate'')
				END

			IF (SELECT COUNT(*) 
				FROM FiltersMenus 
				WHERE [name] = ''crmfilters'') = 0
				BEGIN
					INSERT INTO [dbo].[FiltersMenus] ([name]) 
					VALUES (''crmfilters'')
				END

			IF (SELECT COUNT(*) 
				FROM FiltersMenus 
				WHERE [name] = ''crmtemplate'') = 0
				BEGIN
					INSERT INTO [dbo].[FiltersMenus] ([name]) 
					VALUES (''crmtemplate'')
				END

			IF (SELECT COUNT(*) 
				FROM ReportsFilters 
				WHERE  [reportName] = ''General'' AND [filterName] = ''CRMxTemplates''  AND [id] =  9010) = 0
				BEGIN
					INSERT INTO [dbo].[ReportsFilters] ([reportName],[filterName],[id]) 
					VALUES (''General'', ''CRMxTemplates'', 9010)
				END

			IF (SELECT COUNT(*) 
				FROM ReportsFiltersMenus 
				WHERE [idReport] = 9010  AND [filterMenuName] = ''date'') = 0
				BEGIN
					INSERT INTO [dbo].[ReportsFiltersMenus] ([idReport],[filterMenuName]) 
					VALUES(9010,''date'')
				END

			IF (SELECT COUNT(*) 
				FROM ReportsFiltersMenus 
				WHERE [idReport] = 9010 AND [filterMenuName] = ''crmtemplate'') = 0
				BEGIN
					INSERT INTO [dbo].[ReportsFiltersMenus] ([idReport],[filterMenuName]) 
					VALUES(9010,''crmtemplate'')
				END

			IF (SELECT COUNT(*) 
				FROM ReportsFiltersMenus 
				WHERE [idReport] = 9011 AND [filterMenuName] = ''date'') = 0
				BEGIN
					INSERT INTO [dbo].[ReportsFiltersMenus] ([idReport],[filterMenuName]) 
					VALUES(9011,''date'')
				END

			IF (SELECT COUNT(*) 
				FROM ReportsFiltersMenus 
				WHERE [idReport] = 9011 AND [filterMenuName] = ''crmtemplate'') = 0
				BEGIN
					INSERT INTO [dbo].[ReportsFiltersMenus] ([idReport],[filterMenuName]) 
					VALUES(9011,''crmtemplate'')
				END

			IF (SELECT COUNT(*) 
				FROM ReportsFiltersMenus 
				WHERE [idReport] = 9011 AND [filterMenuName] = ''crmfilters'') = 0
				BEGIN
					INSERT INTO [dbo].[ReportsFiltersMenus] ([idReport],[filterMenuName]) 
					VALUES(9011,''crmfilters'')
				END

			IF (SELECT COUNT(*) 
				FROM ReportsTotals 
				WHERE [id] = 9010 AND [totalColumns] = '''') = 0
				BEGIN
					INSERT INTO [dbo].[ReportsTotals] ([id],[totalColumns]) 
					VALUES(9010,'''')
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

/**************************/
/***** GUIDE AND HELP *****/
/**************************/

/* IMPORTANT: Consider objects manipulation in the sequence exposed in order to get consistency in the script, uncommon objects are prior to common ones in case of exist except replication */

/***** Language Reference *****/
/*
DDL (Data Definition Language)
	* Create
	* Drop
	* Alter

DML (Data Manipulation Language)
	* Select
	* Update
	* Delete
	* Insert

Contraint Object Types
	* C = CHECK constraint
	* D = DEFAULT (constraint or stand-alone)
	* F = FOREIGN KEY constraint
	* PK = PRIMARY KEY constraint
	* R = Rule (old-style, stand-alone)
	* UQ = UNIQUE constraint

Function Object Types
	* FN Scalar function
	* IF Inline table-valued function
	* TF Table-valued-function
	* FS Assembly (CLR) scalar-function
	* FT Assembly (CLR) table-valued function
*/

/***** Most common objects *****/
/* 
TABLES
-- When table exists
if exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

-- When table does not exists
if not exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

COLUMNS
-- When column exists
if exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When column does not exists
if not exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

CONSTRAINTS
-- When constraint exists
if exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not exists
if not exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

-- When constraint primariy key 
if exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''yourTableName'') 
	begin
		Use DDL or DML as you need
	end

-- When constraint does not primariy key 
if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''yourTableName'') 
	begin
		Use DDL or DML as you need
	end

-- When constraint does not foreign key 
if exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''yourTableName'' and  c1.[name]=''yourColumnName'')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not foreign key 
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''yourTableName'' and  c1.[name]=''yourColumnName'')
	begin
		Use DDL or DML as you need
	end

INDEXES
-- When index exists
if exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When index does not exists
if not exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

TRIGGERS
-- When trigger exists
if exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When trigger does not exists
if not exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

FUNCTIONS
-- When function exists
if exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

-- When function does not exists
if not exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

STORED PROCEDURES
-- When stored procedure exists
if exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

-- When stored procedure does not exists
if not exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

VIEWS
-- When view exists
if exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

-- When view does not exists
if not exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

JOBS (In this case be careful about what to do)
-- if you want to create, modify or delete use the script below
if exists (select * from msdb.dbo.sysjobs_view where name = N'yourJobName')
	begin
		exec msdb.dbo.sp_delete_job @job_name = N'yourJobName', @delete_unused_schedule=1
	end

-- After that, you could run the script to create the Job despite of being new or being modified
*/

/***** Uncommon objects *****/
/*
DATABASES
-- When database exists
if exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

-- When database does not exists
if not exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

LOGINS
-- When login exists
if exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

-- When login does not exists
if not exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

SERVER ROLES
-- When server role exists
if exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

-- When server role does not exists
if not exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

SCHEMAS
-- When schema exists
if exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

-- When schema does not exists
if not exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

Replication
-- Replication scripts are generated apart so you have to check them and consider the validations implemented on those scripts
	* Publications
	* Subscriptions on publisher
	* Subscriptions
	* Snapshots
*/