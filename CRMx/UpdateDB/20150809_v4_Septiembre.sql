/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Castillo
Date: 2015/06/09
Description: CWX-CW_CRMx

	 Se modifica el SP sp_getVersion
	 Se modifica el SP saveMyCRMxRecord
	 Se modifica el SP saveMyCRMxRecord
	 Se modifica el SP CRMxUploader
	 Se modifica el SP GetCRMInfo
	 Se modifica el SP CRMxABCTemplates
	 Se modifica el SP CRMxAgent


Database: CW_CRMx
Required version: 3

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it


    Open DBDiff 0.9.0.0
    http://opendbiff.codeplex.com/

    Script created by i5\MCast on 22/05/2015 at 01:28:46 p. m..

    Created on:  I5
    Source:      cw_crmx on 192.168.1.99
    Destination: CW_CRMx on 192.168.1.77
*/

SET NOCOUNT ON

DECLARE @VERSION INT
DECLARE @ACTUALVERSION INT
DECLARE @SQL VARCHAR(MAX)
DECLARE @ERRORGENERATED VARCHAR(MAX)
DECLARE @PROCESS VARCHAR(MAX)

/* VERSION TO RELEASE (USE THE VERSION OF YOUR OWN DATABSE)*/
SET @VERSION = 4

/* ACTUAL VERSION (USE YOUR OWN SCRIPT TO DO IT) */
SET @ACTUALVERSION =  (SELECT VALUE FROM SETTINGS WHERE ID = 1)

IF @ACTUALVERSION = @VERSION - 1
	BEGIN
		BEGIN TRAN
		BEGIN TRY

	/* START SCRIPT RELEASE */

SET @PROCESS = ' DROP CONSTRAINT --- [FK__CRMxTabSh__templ__2A4B4B5E]'
SET @SQL='IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N''FK__CRMxTabSh__templ__2A4B4B5E'') AND OBJECTPROPERTY(id, N''IsConstraint'') = 1)
ALTER TABLE [dbo].[CRMxTabSheets] DROP CONSTRAINT [FK__CRMxTabSh__templ__2A4B4B5E]
'
EXEC(@SQL)

SET @PROCESS = 'DROP CONSTRAINT  -- [FK_LoadingTemplateRelationships_CRMxTemplates]'
SET @SQL='IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N''FK_LoadingTemplateRelationships_CRMxTemplates'') AND OBJECTPROPERTY(id, N''IsConstraint'') = 1)
ALTER TABLE [dbo].[LoadingTemplateRelationships] DROP CONSTRAINT [FK_LoadingTemplateRelationships_CRMxTemplates]'
EXEC(@SQL)

SET @PROCESS = 'DROP CONSTRAINT -- [fk_idTemplate]'
SET @SQL='IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N''fk_idTemplate'') AND OBJECTPROPERTY(id, N''IsConstraint'') = 1)
ALTER TABLE [dbo].[PropertiesByTemplate] DROP CONSTRAINT [fk_idTemplate]'
EXEC(@SQL)

SET @PROCESS = 'DROP INDEX [IX_CRMxTemplates_1] ON [dbo].[CRMxTemplates]'
SET @SQL='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''IX_CRMxTemplates_1'')
	begin
		DROP INDEX [IX_CRMxTemplates_1] ON [dbo].[CRMxTemplates]
	end'
EXEC(@SQL)

SET @PROCESS = 'DROP INDEX [IX_CRMxTemplates_2] ON [dbo].[CRMxTemplates]'
SET @SQL='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''IX_CRMxTemplates_2'')
	begin
		DROP INDEX [IX_CRMxTemplates_2] ON [dbo].[CRMxTemplates]
	end'
EXEC(@SQL)

SET @PROCESS = 'DROP INDEX [IX_CRMxTemplates_3] ON [dbo].[CRMxTemplates]'
SET @SQL='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''IX_CRMxTemplates_3'')
	begin
		DROP INDEX [IX_CRMxTemplates_3] ON [dbo].[CRMxTemplates]
	end'
EXEC(@SQL)

SET @PROCESS = 'DROP INDEX [IX_CRMxTemplates_4] ON [dbo].[CRMxTemplates]'
SET @SQL='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''IX_CRMxTemplates_4'')
	begin
		DROP INDEX [IX_CRMxTemplates_4] ON [dbo].[CRMxTemplates]
	end'
EXEC(@SQL)

SET @PROCESS = 'DROP INDEX [IX_CRMxTemplates_5] ON [dbo].[CRMxTemplates]'
SET @SQL='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''IX_CRMxTemplates_5'')
	begin
		DROP INDEX [IX_CRMxTemplates_5] ON [dbo].[CRMxTemplates]
	end'
EXEC(@SQL)

SET @PROCESS = ''
SET @SQL=''
EXEC(@SQL)

SET @PROCESS = 'Create table -- CRMxTemplates_E7A2926F'
SET @SQL='if not exists (select * from sys.tables where name = N''CRMxTemplates_E7A2926F'')
	begin		
	CREATE TABLE [dbo].[CRMxTemplates_E7A2926F] (
	[id] int IDENTITY(1, 1) NOT NULL,
	[name] nvarchar(100) NOT NULL,
	[description] nvarchar(MAX) NOT NULL,
	[isActive] bit DEFAULT(0) NOT NULL,
	[displayData] bit DEFAULT(0) NOT NULL,
	[dataSavingModality] nvarchar(50) NOT NULL,
	[dataKeyType] nvarchar(50) NOT NULL,
	[servicesType] nvarchar(50) DEFAULT(N''none'') NOT NULL,
	[servicesRelation] xml DEFAULT(''<servicesRelation><call/></servicesRelation>'') NOT NULL,
	[hasSavedData] bit DEFAULT(0) NOT NULL,
	[hasBeenLogicDeleted] bit DEFAULT(0) NOT NULL,
	[isLoadingData] bit DEFAULT(N''0'') NULL
)
end'
EXEC(@SQL)

SET @PROCESS = 'ADD CONSTRAINT [tmp_PK_CRMxTemplates] -- CRMxTemplates_E7A2926F'
SET @SQL='if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''tmp_PK_CRMxTemplates'')
	begin
		ALTER TABLE [dbo].[CRMxTemplates_E7A2926F] ADD CONSTRAINT [tmp_PK_CRMxTemplates] PRIMARY KEY CLUSTERED ([id] ASC)
	end'
EXEC(@SQL)

SET @PROCESS = 'Save previous templates into new table'
SET @SQL='SET IDENTITY_INSERT [dbo].[CRMxTemplates_E7A2926F] ON
INSERT INTO [dbo].[CRMxTemplates_E7A2926F] ([id] , [name] , [description] , [isActive] , [displayData] , [dataSavingModality] , [dataKeyType] , [servicesType] , [servicesRelation] , [hasSavedData] , [hasBeenLogicDeleted] , [isLoadingData] )
SELECT [id] , [name] , [description] , [isActive] , [displayData] , [dataSavingModality] , [dataKeyType] , [servicesType] , [servicesRelation] , [hasSavedData] , [hasBeenLogicDeleted] , 0 FROM [dbo].[CRMxTemplates]
SET IDENTITY_INSERT  [dbo].[CRMxTemplates_E7A2926F] OFF'
EXEC(@SQL)

SET @PROCESS = 'DROP TABLE [dbo].[CRMxTemplates]'
SET @SQL='if exists (select * from sys.tables where name = N''CRMxTemplates'') DROP TABLE [dbo].[CRMxTemplates]'
EXEC(@SQL)


SET @PROCESS = 'sp_rename CRMxTemplates_E7A2926F -- CRMxTemplates'
SET @SQL='sp_rename ''dbo.CRMxTemplates_E7A2926F'', ''CRMxTemplates'', ''OBJECT'''
EXEC(@SQL)

SET @PROCESS = 'sp_rename tmp_PK_CRMxTemplates -- PK_CRMxTemplates'
SET @SQL='sp_rename ''dbo.tmp_PK_CRMxTemplates'', ''PK_CRMxTemplates'', ''OBJECT'''
EXEC(@SQL)

SET @PROCESS = 'CREATE INDEX [IX_CRMxTemplates_1] ON [dbo].[CRMxTemplates]'
SET @SQL='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''IX_CRMxTemplates_1'')
	begin
		CREATE NONCLUSTERED INDEX [IX_CRMxTemplates_1] ON [dbo].[CRMxTemplates] ([hasBeenLogicDeleted]) WITH FILLFACTOR = 100
	end'
EXEC(@SQL)

SET @PROCESS = 'CREATE INDEX [IX_CRMxTemplates_2] ON [dbo].[CRMxTemplates]'
SET @SQL='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''IX_CRMxTemplates_2'')
	begin
		CREATE NONCLUSTERED INDEX [IX_CRMxTemplates_2] ON [dbo].[CRMxTemplates] ([id], [hasBeenLogicDeleted]) WITH FILLFACTOR = 100
	end'
EXEC(@SQL)

SET @PROCESS = 'CREATE INDEX [IX_CRMxTemplates_3] ON [dbo].[CRMxTemplates]'
SET @SQL='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''IX_CRMxTemplates_3'')
	begin
		CREATE NONCLUSTERED INDEX [IX_CRMxTemplates_3] ON [dbo].[CRMxTemplates] ([id], [hasSavedData]) WITH FILLFACTOR = 100 
	end'
EXEC(@SQL)

SET @PROCESS = 'CREATE INDEX [IX_CRMxTemplates_4] ON [dbo].[CRMxTemplates]'
SET @SQL='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''IX_CRMxTemplates_4'')
	begin
		CREATE NONCLUSTERED INDEX [IX_CRMxTemplates_4] ON [dbo].[CRMxTemplates] ([servicesType], [hasBeenLogicDeleted]) WITH FILLFACTOR = 100 
	end'
EXEC(@SQL)

SET @PROCESS = 'CREATE INDEX [IX_CRMxTemplates_5] ON [dbo].[CRMxTemplates]'
SET @SQL='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''IX_CRMxTemplates_5'')
	begin
		CREATE NONCLUSTERED INDEX [IX_CRMxTemplates_5] ON [dbo].[CRMxTemplates] ([hasBeenLogicDeleted], [hasSavedData]) WITH FILLFACTOR = 100 
	end'
EXEC(@SQL)

SET @PROCESS = 'ADD CONSTRAINT [FK__CRMxTabSh__templ__2A4B4B5E] CRMxTabSheets'
SET @SQL='IF NOT EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N''[FK__CRMxTabSh__templ__2A4B4B5E]'') AND OBJECTPROPERTY(id, N''IsForeignKey'') = 1)
ALTER TABLE [dbo].[CRMxTabSheets] ADD CONSTRAINT [FK__CRMxTabSh__templ__2A4B4B5E] FOREIGN KEY ([templateId]) REFERENCES [dbo].[CRMxTemplates] ([id]) ON DELETE CASCADE '
EXEC(@SQL)

SET @PROCESS = 'ADD CONSTRAINT [FK_LoadingTemplateRelationships_CRMxTemplates] -- LoadingTemplateRelationships'
SET @SQL='IF NOT EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N''[FK_LoadingTemplateRelationships_CRMxTemplates]'') AND OBJECTPROPERTY(id, N''IsForeignKey'') = 1)
ALTER TABLE [dbo].[LoadingTemplateRelationships] ADD CONSTRAINT [FK_LoadingTemplateRelationships_CRMxTemplates] FOREIGN KEY ([crmxTemplateId]) REFERENCES [dbo].[CRMxTemplates] ([id]) ON DELETE CASCADE '
EXEC(@SQL)

SET @PROCESS = 'ADD CONSTRAINT [fk_idTemplate] -- PropertiesByTemplate'
SET @SQL='IF NOT EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N''[fk_idTemplate]'') AND OBJECTPROPERTY(id, N''IsForeignKey'') = 1)
ALTER TABLE [dbo].[PropertiesByTemplate] ADD CONSTRAINT [fk_idTemplate] FOREIGN KEY ([idTemplate]) REFERENCES [dbo].[CRMxTemplates] ([id]) ON DELETE CASCADE '
EXEC(@SQL)

SET @PROCESS = 'ALTER PROCEDURE [dbo].[GetCRMInfo]'
SET @SQL='-- =============================================
-- Author:		<El Mish>
-- Create date: <9-FEB-2015>
-- Description:	<View construction for reports>
-- =============================================
ALTER PROCEDURE [dbo].[GetCRMInfo]
@action tinyint,
@crmTemplateId nvarchar(100) = null

AS

DECLARE @SQL VARCHAR(MAX)
DECLARE @currentDataTemplateTable VARCHAR(100)

declare @pivot1_descriptionT nvarchar(max)
declare @pivot1_descriptionN nvarchar(max)
declare @query nvarchar(max)


begin
	if @action = 0 begin -- Get all templates
		select id,name as [description], servicesRelation, ''templateCRMId'' as dbColumn  from CRMxTemplates WITH(NOLOCK) where hasBeenLogicDeleted = 0 and hasSavedData = 1
	end

	if @action = 1 begin -- Get Fields Table
		select tabSheetXML from [CRMxTabSheets] WITH(NOLOCK) where templateId=@crmTemplateId
	end
	if @action = 2 begin -- Get services Relation
	    --select * from crmxdata48
		set @query = ''select distinct serviceSource from crmxData'' + @crmTemplateId +'' WITH(NOLOCK)''
		exec(@query)
		--select servicesRelation from [CRMxTemplates] where id=@crmTemplateId
	end

	if @action = 3 begin -- Pivot Info
		begin
		set @query=''declare @pivot1_descriptionT nvarchar(max)
			declare @pivot1_descriptionN nvarchar(max)
			declare @query nvarchar(max)
			declare @view_statement nvarchar(10)
			select @pivot1_descriptionN = coalesce(@pivot1_descriptionN + '''','''', '''''''') + ''''isnull(MAX('''' + QuoteName(componentId) + ''''),'''''''''''''''') AS '''' + QuoteName(componentHeader)
			from (
			select  tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') as ''''componentId'''',tabsheet.comp.value(''''(@headerLabel)'''',''''varchar(max)'''') as ''''componentHeader'''' from crmxtabsheets WITH(NOLOCK)
			cross apply crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
			where templateid='' + @crmTemplateId + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') is not null AND tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') is not null
			and tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') = ''''true''''
			) T1_descriptionN


			select @pivot1_descriptionT = coalesce(@pivot1_descriptionT + '''','''','''''''','''''''''''''''') + QuoteName(componentId)
			from  (select  tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') as ''''componentId'''',tabsheet.comp.value(''''(@headerLabel)'''',''''varchar(max)'''') as ''''componentHeader'''' from crmxtabsheets WITH(NOLOCK)
			cross apply crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
			where templateid='' + @crmTemplateId + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') is not null AND tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') is not null
			and tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') = ''''true''''
						) T1_descriptionT

			IF EXISTS(SELECT * FROM sys.views WHERE name = ''''CRMxView''+ @crmTemplateId + '''''')
			BEGIN
				SET @view_statement = ''''ALTER''''
			END
			ELSE
			BEGIN
				SET @view_statement = ''''CREATE''''
			END


			set @query = @view_statement + '''' VIEW CRMxView'' + @crmTemplateId + '' as select a.dateValue as crmx_Date ,a.serviceSource as crmxSource,  '''' + @pivot1_descriptionN + ''''
			from (select crmxRecordId as RowID,dataValue,componentId from CRMxRawData'' + @crmTemplateId + '' WITH(NOLOCK)) as P
			pivot (max(dataValue) for componentId in ('''' + @pivot1_descriptionT + ''''))  as PV_descriptionT, CRMxData'' + @crmTemplateId + '' a
			where a.crmxRecordId = RowID
			group by [RowID], a.serviceSource, a.dateValue''''

			EXEC( @query )''

			IF(SELECT hasSavedData FROM crmxtemplates WHERE id = @crmTemplateId) = 1
			BEGIN
				EXEC( @query)
			END
		END

	END

	if @action = 4 begin -- Creating Views unused
		begin
		set @query=''
			IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N''''RepCRMXView''+ @crmTemplateId + '''''') AND type = (N''''U'''')) DROP TABLE RepCRMXView'' + @crmTemplateId
			exec ( @query)
			set @query=''
			       create table RepCRMXView'' + @crmTemplateId +''(date datetime,Source varchar(10))   ''

				   -- Create indexes

		    exec ( @query)
		end

	end
	if @action = 5 begin -- get headers
		select templateid as templateId,tabsheetindex as tabSheetIndex,tabsheet.comp.value(''(@headerLabel)'',''varchar(max)'') as ''header'', ''data'' + tabsheet.comp.value(''(@headerIndex)'',''varchar(max)'') as ''dataColumn''  from crmxtabsheets
		cross apply crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)
		where templateid=@crmTemplateId and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') is not null
		and tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') = ''true''


		--select tabSheetIndex, header,dataColumn from RepCRMxHeaders where templateId = @crmTemplateId;
	end
	if @action = 6 begin -- get Number of values
		select count(templateid) from crmxtabsheets WITH(NOLOCK)
		cross apply crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)
		where templateid=@crmTemplateId and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') is not null
		and tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') = ''true''

	end
	if @action = 7 begin --Get Components for graphs
		select templateid as templateId,tabsheetindex as tabSheetIndex, tabsheet.comp.value(''local-name(.)[1]'', ''VARCHAR(MAX)'') AS ParentNodeName,tabsheet.comp.value(''(@headerLabel)'',''varchar(max)'') as ''header'', ''data'' + tabsheet.comp.value(''(@headerIndex)'',''varchar(max)'') as ''dataColumn''  from crmxtabsheets WITH(NOLOCK)
		CROSS APPLY crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)
		where templateid = @crmTemplateId and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') is not null
		AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') = ''true''
		AND (tabsheet.comp.value(''local-name(.)[1]'', ''VARCHAR(MAX)'')= ''ComboBox'' OR tabsheet.comp.value(''local-name(.)[1]'', ''VARCHAR(MAX)'')= ''checkBoxGroup'' OR tabsheet.comp.value(''local-name(.)[1]'', ''VARCHAR(MAX)'')= ''radioButtonGroup'')
 end
 if @action=8
 begin
 set @query=''declare @pivot1_descriptionT nvarchar(max)
			declare @pivot1_descriptionN nvarchar(max)
			declare @query nvarchar(max)
			declare @view_statement nvarchar(10)
			select @pivot1_descriptionN = coalesce(@pivot1_descriptionN + '''','''', '''''''') + ''''isnull(MAX('''' + QuoteName(componentId) + ''''),'''''''''''''''') AS '''' + QuoteName(componentHeader)
			from (
			select  tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') as ''''componentId'''',tabsheet.comp.value(''''(@headerLabel)'''',''''varchar(max)'''') as ''''componentHeader'''' from crmxtabsheets WITH(NOLOCK)
			cross apply crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
			where templateid='' + @crmTemplateId + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') is not null  AND tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') is not null) T1_descriptionN


			select @pivot1_descriptionT = coalesce(@pivot1_descriptionT + '''','''','''''''','''''''''''''''') + QuoteName(componentId)
			from  (select  tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') as ''''componentId'''',tabsheet.comp.value(''''(@headerLabel)'''',''''varchar(max)'''') as ''''componentHeader'''' from crmxtabsheets WITH(NOLOCK)
			cross apply crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
			where templateid='' + @crmTemplateId + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') is not null AND tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') is not null
			) T1_descriptionT

			IF EXISTS(SELECT * FROM sys.views WHERE name = ''''CRMxRawView''+ @crmTemplateId + '''''')
			BEGIN
				SET @view_statement = ''''ALTER''''
			END
			ELSE
			BEGIN
				SET @view_statement = ''''CREATE''''
			END


			set @query = @view_statement + '''' VIEW CRMxRawView'' + @crmTemplateId + '' as select a.crmxRecordId as crmxRecordId ,  '''' + @pivot1_descriptionN + ''''
			from (select crmxRecordId as RowID,dataValue,componentId from CRMxRawData'' + @crmTemplateId + '' WITH(NOLOCK)) as P
			pivot (max(dataValue) for componentId in ('''' + @pivot1_descriptionT + ''''))  as PV_descriptionT, CRMxData'' + @crmTemplateId + '' a
			where a.crmxRecordId = RowID
			group by [RowID], a.serviceSource, a.crmxRecordId''''

			exec( @query )''
			IF(SELECT hasSavedData FROM crmxtemplates WHERE id = @crmTemplateId) = 1
			BEGIN
				EXEC( @query)
			END
 end

end'
EXEC(@SQL)

SET @PROCESS = 'Alter SP -- CRMxABCTemplates'
SET @SQL='-- =============================================
-- Author:		<Deivid V., ElMish, Rod A., Miguel Cast>
-- Create date: <23-APR-2014>
-- Description:	<Hold every agent operation>
-- =============================================
ALTER PROCEDURE [dbo].[CRMxABCTemplates]
	-- Add the parameters for the stored procedure here
    @option int = 0,

    -- Templates
	@templateId int = NULL,
	@templateName VARCHAR(100) = NULL,
	@templateDescription VARCHAR(MAX) = NULL,
	@isActive bit =NULL,
	@displayData bit =NULL,
	@dataSavingModality varchar(50) =NULL,
	@dataKeyType varchar(50)=null,
	@servicesType varchar(50)=NULL,
	@templateServicesRelation xml= NULL,
	@hasSavedData bit =NULL,
	@hasBeenLogicDeleted bit =NULL,
	--tabSheets
	@tabSheetId int = NULL,
	@tabSheetsXml xml = NULL,
	@xmlCountsId xml = NULL,
	@dataKey VARCHAR(50) = NULL,
	@query nvarchar(max) = NULL

AS
	DECLARE @new_template_id int
	DECLARE @tabSheeter VARCHAR(100)
BEGIN

-- GET ALL templates
IF @option = 2
	IF ( SELECT COUNT(id) FROM CRMxTemplates WITH(NOLOCK) WHERE hasBeenLogicDeleted=0) = 0
		BEGIN
			SELECT -1 --''No hay templates
		END
	ELSE
	  BEGIN
		SELECT * FROM dbo.CRMxTemplates WITH(NOLOCK) WHERE hasBeenLogicDeleted=0
	  END

-- CREATE template
IF @option = 3
	BEGIN
		   INSERT INTO dbo.CRMxTemplates (name, description,isActive,displayData,dataSavingModality,dataKeyType,servicesType,servicesRelation,hasSavedData,hasBeenLogicDeleted)
		   VALUES (@templateName,@templateDescription,@isActive,@displayData,@dataSavingModality,@dataKeyType,@servicesType, @templateServicesRelation,@hasSavedData,@hasBeenLogicDeleted)

			SELECT @new_template_id = scope_identity()
			SELECT @new_template_id
	END

-- UPDATE template
IF @option = 4
	IF ( SELECT COUNT(*) FROM dbo.CRMxTemplates WITH(NOLOCK) WHERE id = @templateId) = 0
		BEGIN
			SELECT -1 --''No existe el template
		END
	ELSE
		BEGIN
		DECLARE @Sql VARCHAR(max)
		DECLARE @band bit

		SET @Sql=''UPDATE CRMxTemplates WITH(ROWLOCK) SET''
		SET @band=0

		IF (@templateName IS NOT NULL)
			BEGIN
				IF @band = 0 -- Si la bandera es 0 es el primer valor (No ponemos ,)
					BEGIN
						SET @Sql = @Sql + '' name= ''+ ''''''''+ CAST(@templateName AS VARCHAR)  +''''''''
						SET @band=1
					END
				ELSE
					BEGIN
						SET @Sql = @Sql + '',name= ''+ ''''''''+ CAST(@templateName AS VARCHAR)  +''''''''
					END
			END

		IF @templateDescription IS NOT NULL
				BEGIN
				IF @band = 0
					BEGIN
						 SET @Sql = @Sql + '' description= ''+ ''''''''+ CAST(@templateDescription AS VARCHAR)  +''''''''
						 SET @band=1
					END
				ELSE
					BEGIN
						SET @Sql = @Sql + '',description= ''+ ''''''''+ CAST(@templateDescription AS VARCHAR)  +''''''''
					END
		END

		IF @isActive IS NOT NULL
			BEGIN
				IF @band=0
					BEGIN
						SET @Sql=@Sql+'' isActive= ''+ ''''''''+ CAST(@isActive AS VARCHAR)  +''''''''
						SET  @band=1
					END
				ELSE
					BEGIN
						SET @Sql = @Sql + '',isActive= ''+ ''''''''+ CAST(@isActive AS VARCHAR)  +''''''''
					END
				END

		IF @displayData IS NOT NULL
			BEGIN
				IF @band=0
					BEGIN
						SET @Sql=@Sql+'' displayData= ''+ ''''''''+ CAST(@displayData AS VARCHAR)  +''''''''
						SET  @band=1
					END
				ELSE
					BEGIN
						SET @Sql = @Sql + '', displayData= ''+ ''''''''+ CAST(@displayData AS VARCHAR)  +''''''''
					END
				END

			IF @dataSavingModality IS NOT NULL
			BEGIN
				IF @band=0
					BEGIN
						SET @Sql=@Sql+'' dataSavingModality= ''+ ''''''''+ CAST(@dataSavingModality AS VARCHAR)  +''''''''
						SET  @band=1
					END
				ELSE
					BEGIN
						SET @Sql = @Sql + '', dataSavingModality= ''+ ''''''''+ CAST(@dataSavingModality AS VARCHAR)  +''''''''
					END
				END

			IF @dataKeyType IS NOT NULL
			BEGIN
				IF @band=0
					BEGIN
						SET @Sql=@Sql+'' dataKeyType= ''+ ''''''''+ CAST(@dataKeyType AS VARCHAR)  +''''''''
						SET  @band=1
					END
				ELSE
					BEGIN
						SET @Sql = @Sql + '', dataKeyType= ''+ ''''''''+ CAST(@dataKeyType AS VARCHAR)  +''''''''
					END
				END

		IF @servicesType IS NOT NULL
			BEGIN
				IF @band=0
					BEGIN
						SET @Sql=@Sql+'' servicesType= ''+ ''''''''+ CAST(@servicesType AS VARCHAR)  +''''''''
						SET  @band=1
					END
				ELSE
					BEGIN
						SET @Sql = @Sql + '', servicesType= ''+ ''''''''+ CAST(@servicesType AS VARCHAR)  +''''''''
					END
				END

		IF @templateServicesRelation IS NOT NULL
			BEGIN
				IF @band=0
					BEGIN
						SET @Sql=@Sql+'' servicesRelation= ''+ ''''''''+ CAST(@templateServicesRelation AS VARCHAR(MAX))  +''''''''
						SET  @band=1
					END
				ELSE
					BEGIN
						SET @Sql = @Sql + '', servicesRelation= ''+ ''''''''+ CAST(@templateServicesRelation AS VARCHAR(MAX))  +''''''''
					END
				END

		SET @Sql = @Sql + '' WHERE Id='' + CAST(@templateId AS VARCHAR)

		--SELECT @Sql
		EXEC(@Sql)

			SELECT 1
		END

--	GET tabSheets ordered
 IF @option = 5
	IF ( SELECT COUNT(*) FROM CRMxTabSheets WITH(NOLOCK) WHERE templateId = @templateId) = 0
		BEGIN
			SELECT -1 --''No tiene tabSheets
		END
	ELSE
	  BEGIN
		SELECT CRMxTemplates.id,
		CRMxTemplates.name,
		CRMxTemplates.description,
		CRMxTemplates.isActive,
		CRMxTemplates.displayData,
		CRMxTemplates.dataSavingModality,
		CRMxTemplates.dataKeyType,
		CRMxTemplates.servicesType,
		CRMxTemplates.servicesRelation,
		CRMxTemplates.hasSavedData,
		CRMxTemplates.hasBeenLogicDeleted,
		CRMxTemplates.isLoadingData,
		PropertiesByTemplate.CountIds,
		CRMxTabSheets.tabSheetIndex,
		CRMxTabSheets.tabSheetXml
		FROM CRMxTemplates INNER JOIN CRMxTabSheets ON CRMxTemplates.id=CRMxTabSheets.templateId
		INNER JOIN PropertiesByTemplate ON CRMxTabSheets.templateId=PropertiesByTemplate.idTemplate
		where CRMxTemplates.id=@templateId
		ORDER BY CRMxTabSheets.tabSheetIndex ASC
	  END

-- DELETE template WITH IT''S tabSheets USING id
 IF @option = 6

	IF ( SELECT COUNT(id) FROM dbo.CRMxTemplates WITH(NOLOCK) WHERE id = @templateId and hasBeenLogicDeleted = 0) = 0
		BEGIN
			SELECT -1 --''No existe el template
		END
	ELSE
	BEGIN
		IF ( SELECT COUNT(id) FROM dbo.CRMxTemplates WITH(NOLOCK) WHERE id = @templateId and hasSavedData = 1) = 1
		BEGIN  -- Tiene datos guardados
			UPDATE  dbo.CRMxTemplates WITH(ROWLOCK) SET hasBeenLogicDeleted = 1 WHERE id = @templateId
			SELECT 1
		END
		ELSE -- No tiene datos, borramos la tabla CRMxData
		BEGIN
				DELETE FROM dbo.CRMxTemplates WHERE id = @templateId
				IF EXISTS( SELECT * FROM sysobjects WHERE name=''CRMxData'' + CAST(@templateId AS VARCHAR(MAX))  + '''')
				BEGIN
					DECLARE @droppableTable AS VARCHAR(MAX)
					SET @droppableTable = ''DROP TABLE [CRMxData'' + CAST(@templateId AS VARCHAR(MAX))  + '']''
					EXEC(@droppableTable)
				END
				SELECT 1
		END
	END

-- CREATE a tabSheet
IF @option = 7
	BEGIN
		If exists (select * from CRMxtemplates where id=@templateId)-- and hasSavedData=0)
		BEGIN
			insert into dbo.CRMxTabSheets (templateId, tabSheetIndex,tabSheetXml) VALUES (@templateId,@tabSheetId,@tabSheetsXml)

			IF ( SELECT COUNT(idTemplate) FROM dbo.PropertiesByTemplate WITH(NOLOCK) WHERE idTemplate = @templateId) = 0
			BEGIN
				insert into dbo.PropertiesByTemplate (idTemplate,countIds) VALUES (@templateId,@xmlCountsId)
			END
			ELSE
			BEGIN
				UPDATE PropertiesByTemplate SET countIds=@xmlCountsId WHERE idTemplate=@templateId
			END
		END
	END

-- get hasSavedData By Template
IF @option = 8
 IF ( SELECT COUNT(*) FROM CRMxTemplates WITH(NOLOCK) WHERE id =  @templateId AND hasBeenLogicDeleted=0) = 0
		BEGIN
			SELECT -1
		END
	ELSE
	  BEGIN
		SELECT hasSavedData FROM dbo.CRMxTemplates WHERE id =  @templateId
	  END

 -- DELETE all tabSheets OF ''x'' template, se ocupa para la insercin de los tab de una nueva platilla
  IF @option = 9
		BEGIN
			If exists (select * from CRMxtemplates where id=@templateId)-- and hasSavedData=0)
				delete from CRMxTabSheets where templateId=@templateId
		END

-- duplicate template
IF @option = 11
		BEGIN
		-- Insercion en tabla CRMxTemplate
			DECLARE @countCopy varchar(15)

			set @countCopy= (SELECT
				count(id)
				FROM CRMxTemplates WITH(NOLOCK) where name like ( SELECT name FROM CRMxTemplates WITH(NOLOCK) where id=@templateId)+''%''  and hasBeenLogicDeleted<>1)

			set @countCopy=''(''+@countCopy+'')''

			INSERT INTO dbo.CRMxTemplates (
				name,
				description,
				displayData,
				dataSavingModality,
				dataKeyType)
			SELECT
				name+'' ''+@countCopy,
				description,
				displayData,
				dataSavingModality,
				dataKeyType
				FROM CRMxTemplates WITH(NOLOCK)  where id=@templateId

			SET @new_template_id = scope_identity()

		--- Insercion de tabSheets

			INSERT INTO dbo.CRMxTabSheets (
				templateId,
				tabSheetIndex,
				tabSheetXml
				)
			SELECT
				@new_template_id,
				tabSheetIndex,
				tabSheetXml
				FROM CRMxTabSheets WITH(NOLOCK) where templateId=@templateId

			INSERT INTO dbo.PropertiesByTemplate (idTemplate,countIds)
			SELECT @new_template_id,countIds FROM PropertiesByTemplate WHERE idTemplate=@templateId

			SELECT * FROM crmxTemplates WITH(NOLOCK) WHERE id=@new_template_id

		END
IF @option = 12 -- Delete non existing components*
	BEGIN
		/*
		DECLARE @componentDescription nvarchar(max)

		SELECT @componentDescription = COALESCE(@componentDescription + '','','''','''') + '''''''' + componentId + '''''''' FROM(
		SELECT tabsheet.comp.value(''(@id)'',''varchar(max)'') AS ''componentId''  FROM crmxtabsheets WITH(NOLOCK)
		CROSS APPLY crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)
		WHERE templateid = @templateId and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') is not null
		) T1_descriptionT
		*/*/

		--DECLARE @SQL VARCHAR(max)
		If EXISTS (SELECT * FROM CRMxtemplates WHERE id=@templateId AND hasSavedData=1)
		BEGIN
		--	SET @SQL = ''DELETE FROM CRMxRawData'' + CONVERT(VARCHAR(MAX), @templateId) + '' WHERE componentId NOT IN ('' + @componentDescription + '')''
		--	EXEC(@SQL)
			--Update Views
			EXEC getCRMInfo @action = 3,@crmTemplateId = @templateId
			EXEC getCRMInfo @action = 8,@crmTemplateId = @templateId

		END

	END

--if @option = 12 -- Ensure CRMxView Structure
--	BEGIN
--		declare @nTemplateColumns int
--		declare @nViewColumns int
--		declare @dataColumn int
--		select @nViewColumns =  COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = ''CRMxView''  and SUBSTRING(COLUMN_NAME,0,5) = ''data''

--		IF NOT EXISTS(select * FROM INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = ''CRMxView''  and SUBSTRING(COLUMN_NAME,0,5) = ''data'')
--			BEGIN
--				set @dataColumn=0
--			END
--		ELSE
--			BEGIN
--				set @dataColumn=@nViewColumns
--		END

--		select @nTemplateColumns = COUNT(templateId)  from crmxtabsheets
--		cross apply crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)
--		where templateid = @templateId and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') is not null
--		and tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') = ''true''
--		WHILE (@nTemplateColumns > @dataColumn)
--			BEGIN
--				set @dataColumn= @dataColumn+ 1
--				set @query=''ALTER TABLE CRMxView
--					ADD data'' + CAST(@dataColumn as nvarchar(max)) + '' nvarchar(max) NULL'' --DEFAULT ''''''''''
--				exec(@query)

--			END
--	END

END'
EXEC(@SQL)

SET @PROCESS = 'ALTER PROCEDURE [dbo].[CRMxAgent]'
SET @SQL='-- =============================================
-- Author:		<Miguel Cast, Deivid V.>
-- Create date: <23-APR-2014>
-- Description:	<Hold every agent operation>
-- =============================================
ALTER PROCEDURE [dbo].[CRMxAgent]
	-- Add the parameters for the stored procedure here
	@option INT = 0,				-- Type of Action/proceess to perform
    @serviceType VARCHAR(50) = NULL,		-- Type of invoker service
    @servicesType VARCHAR(50) = NULL,		-- Type of service associated, catalog
    @serviceSource VARCHAR(50) = NULL,		-- The invoker serviceSource
	@callType INT = NULL,					-- Call Type, ACD or CAMP
	@callTypeId INT= NULL,					-- Call identifier, camp #1 or acd#2
	@dnis INT = NULL, 						-- Dnis, i.e. 2099
	@templateId INT = NULL,					-- Template id''s
	@tabSheetIndex INT = NULL,				-- TabSheet id''s
	@componentId VARCHAR(100) = NULL,		-- Component id''s
	@bindingType VARCHAR(100) = NULL, 		-- Type of binding to perform
	@dataValue VARCHAR(MAX) = NULL,			-- Component stored value
	@dataKeyType VARCHAR(50) = NULL,			-- DataKey
	@dataKeyValue VARCHAR(MAX) = NULL,			-- DataKey
	@destinySourceValue VARCHAR(MAX) = NULL,	-- Client client serviceSource destiny or origin, as source to return operation.
	@crmxRecordId INT = NULL,
	@dateValue dateTime = NULL                --Record date
AS


DECLARE @SQL VARCHAR(MAX)
DECLARE @currentDataTemplateTable VARCHAR(100)
DECLARE @searchPattern VARCHAR(MAX)


BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here


	/*	READ

		Valid Template
		-- serviceType,
			-- call :: callId, callType, dnis
			-- sms ::
			-- email ::
			*/
	IF @option = 1
		BEGIN
			IF @serviceType LIKE ''%call%''-- CALL
				BEGIN
					IF @callType = 0 -- CALL::Campaign
						BEGIN
							SET @SQL = ''IF (
								SELECT COUNT([id])
								FROM CRMxTemplates WITH(NOLOCK)
								WHERE [servicesType]
								LIKE '' + '''''''' + ''%'' + @servicesType + ''%'' + '''''''' + ''
								AND servicesRelation.exist('' + '''''''' + ''/servicesRelation/call/Campaign[@id='' + CAST(@callTypeId AS VARCHAR(50)) + '']'' + '''''''' + '') = 1 AND
								[hasBeenLogicDeleted] = 0
								) = 1
								BEGIN
									SELECT *
									FROM CRMxTemplates WITH(NOLOCK)
									WHERE [servicesType]
									LIKE '' + '''''''' + ''%'' + @servicesType + ''%'' + '''''''' + ''
									AND servicesRelation.exist('' + '''''''' + ''/servicesRelation/call/Campaign[@id='' + CAST(@callTypeId AS VARCHAR(50)) + '']'' + '''''''' + '') = 1
									AND [hasBeenLogicDeleted] = 0
								END
							 ELSE
								BEGIN
									SELECT N''+''''''''+''-1.1''+''''''''+''
								END''
						END

					ELSE -- CALL::ACD
						BEGIN
							SET @SQL = ''IF (
								SELECT COUNT([id])
								FROM CRMxTemplates WITH(NOLOCK)
								WHERE [servicesType]
								LIKE '' + '''''''' + ''%'' + @servicesType + ''%'' + '''''''' + ''
								AND servicesRelation.exist('' + '''''''' + ''/servicesRelation/call/ACD[@dnis='' + CAST(@dnis AS VARCHAR(50)) + '']'' + '''''''' + '') = 1
								AND [hasBeenLogicDeleted] = 0
								) = 1
								BEGIN
									SELECT * FROM CRMxTemplates WITH(NOLOCK)
									WHERE [servicesType]  LIKE '' + '''''''' + ''%'' + @servicesType + ''%'' + '''''''' + ''
									AND servicesRelation.exist('' + '''''''' + ''/servicesRelation/call/ACD[@dnis='' + CAST(@dnis AS VARCHAR(50)) + '']'' + '''''''' + '') = 1
									AND [hasBeenLogicDeleted] = 0
								END
							 ELSE
								BEGIN
									SELECT N''+''''''''+''-1.2''+''''''''+''
								END''
						END
					PRINT(@SQL)
					EXEC(@SQL)
				END
			END



	/* READ

		@CRMxTabSheets

		Gets the TabSheets associated to ''X'' templateId
	*/
	IF @option = 2
		BEGIN
			IF (SELECT TOP 1 [templateId] FROM CRMxTabSheets WITH(NOLOCK) WHERE [templateId] = @templateId) <> @templateId  -- NO TEMPLATE HAS VALID DATA
				BEGIN
					SELECT N''-2.1''
				END
			ELSE
				BEGIN
					SELECT * FROM CRMxTabSheets WITH(NOLOCK) WHERE [templateId] = @templateId ORDER BY [tabSheetIndex] ASC
				END
		END




	/* READ

		@ CRMxData''N''

		Gets the CRMxRecord that best matches
	*/
	IF @option=3
		BEGIN
			IF @templateId IS NOT NULL
				BEGIN
					SET @currentDataTemplateTable = ''CRMxData'' + CAST(@templateId AS VARCHAR(100))
					IF (SELECT COUNT(*) FROM SYS.TABLES WHERE [NAME] = @currentDataTemplateTable) = 1
						BEGIN
							SET @SQL = ''SELECT TOP 1 * FROM [dbo].['' + @currentDataTemplateTable + ''] WITH(NOLOCK)''

							IF(@dataKeyValue IS NOT NULL)
								BEGIN
									SET @SQL = @SQL + '' WHERE [dataKeyValue]='' + '''''''' +  @dataKeyValue + ''''''''
								END
							ELSE
								BEGIN
									SET @SQL = @SQL + '' WHERE [destinySourceValue]='' + '''''''' +  @destinySourceValue + ''''''''
								END
							SET @SQL = @SQL + '' AND [serviceSource] LIKE '' + '''''''' + ''%'' + @serviceSource + ''%'' + '''''''' + ''
							 AND [hasBeenLogicDeleted] = 0
							 ORDER BY [dateValue] DESC''

							PRINT(@SQL)
							EXEC(@SQL)
						END
					ELSE
						BEGIN
							SELECT N''-3.1''
						END
				END
			ELSE
				SELECT N''-3.2''
		END




	/* READ

		@ CRMxRawData''N''

		Gets the CRMxRecord components using the crmxRecordId
	*/
	IF @option=4
		BEGIN
			IF @templateId IS NOT NULL
				BEGIN
					SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + CAST(@templateId AS VARCHAR(100)) + '']''
					SET @SQL = ''SELECT * FROM '' + @currentDataTemplateTable  + '' WITH(NOLOCK)
					WHERE [crmxRecordId]='' + CAST(@crmxRecordId AS VARCHAR(MAX))  + ''
					ORDER BY [tabSheetIndex] ASC, [componentId] ASC''

					PRINT(@SQL)
					EXEC(@SQL)
				END
			ELSE
				SELECT N''-4.1''
		END


	/*CREATE

		CRMxData''N''
		CRMxRawData''N''

		The CRMxData''n'' and CRMxRawData tables if not created yet,
		and sets to true(1) the hasSavedData property over the CRMxTemplates row relation
		*/
	IF @option = 5
		BEGIN
			IF (SELECT [hasSavedData] FROM CRMxTemplates WITH(ROWLOCK) WHERE [id] = @templateId) = 0
				BEGIN
					UPDATE CRMxTemplates WITH(ROWLOCK)
					SET [hasSavedData] = 1
					WHERE [id] = @templateId
				END

			SET @currentDataTemplateTable = ''CRMxData'' + CAST(@templateId AS VARCHAR(100))

			IF (SELECT COUNT([NAME]) FROM SYS.TABLES WHERE [NAME] = @currentDataTemplateTable) = 0
				BEGIN
					SET @SQL = ''CREATE TABLE [dbo].['' +  @currentDataTemplateTable + '']
					 (
						[crmxRecordId] [int] IDENTITY(1,1) NOT NULL,
						[serviceSource] [varchar](50) NULL,
						[dataKeyValue] [varchar](100) NULL,
						[destinySourceValue] [varchar](100) NULL,
						[dateValue] [datetime] NOT NULL,
						[hasBeenLogicDeleted] [bit] NOT NULL,
					CONSTRAINT [PK_''+@currentDataTemplateTable+''] PRIMARY KEY CLUSTERED
					(
						[crmxRecordId] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
					)'' +
					''ALTER TABLE '' + @currentDataTemplateTable +
					'' ADD CONSTRAINT [DF_CRMxData'' + CAST(@templateId AS VARCHAR(100)) +
					''_dateValue] DEFAULT (GETDATE()) FOR [dateValue]



					CREATE NONCLUSTERED INDEX [IX_''+@currentDataTemplateTable+''_1] ON [dbo].[''+@currentDataTemplateTable+'']
					(
						[serviceSource] ASC,
						[dataKeyValue] DESC,
						[hasBeenLogicDeleted] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

					SET ANSI_PADDING ON


					CREATE NONCLUSTERED INDEX [IX_''+@currentDataTemplateTable+''_2] ON [dbo].[''+@currentDataTemplateTable+'']
					(
						[serviceSource] ASC,
						[destinySourceValue] ASC,
						[hasBeenLogicDeleted] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

					SET ANSI_PADDING ON


					CREATE NONCLUSTERED INDEX [IX_''+@currentDataTemplateTable+''_3] ON [dbo].[''+@currentDataTemplateTable+'']
					(
						[dataKeyValue] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

					SET ANSI_PADDING ON
					''

					PRINT(@SQL)
					EXEC(@SQL)
				END

			SET @currentDataTemplateTable = ''CRMxRawData'' + CAST(@templateId AS VARCHAR(100))
			IF (SELECT COUNT([NAME]) FROM SYS.TABLES WHERE [NAME] = @currentDataTemplateTable) = 0
				BEGIN
					SET @SQL = ''CREATE TABLE  [dbo].['' +  @currentDataTemplateTable + '']
					 (
							[crmxRecordId] [int] NOT NULL,
							[tabSheetIndex] [int] NULL,
							[componentId] [varchar](100),
							[bindingType] [varchar](100) NULL,
							[dataValue] [varchar](max),
					CONSTRAINT [PK_''+@currentDataTemplateTable+''] PRIMARY KEY CLUSTERED
					(
						[crmxRecordId] ASC,
						[componentId] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

					) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]




					CREATE NONCLUSTERED INDEX [IX_''+@currentDataTemplateTable+''_1] ON [dbo].[''+@currentDataTemplateTable+'']
					(
						[crmxRecordId] ASC,
						[tabSheetIndex] ASC,
						[componentId] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

					SET ANSI_PADDING ON


					CREATE NONCLUSTERED INDEX [IX_''+@currentDataTemplateTable+''_2] ON [dbo].[''+@currentDataTemplateTable+'']
					(
						[tabSheetIndex] ASC,
						[componentId] ASC
					)

					ALTER TABLE [dbo].[''+@currentDataTemplateTable+''] ADD  CONSTRAINT [DF__CRMxRawDa__dataV_''+CAST(@templateId AS VARCHAR(100))+'']  DEFAULT ('''' '''') FOR [dataValue]

					''
					EXEC(@SQL)

					SET @SQL ='' exec [CRMxAgent] @option=19, @templateId=''+CAST(@templateId AS VARCHAR(100)) +''''
					EXEC(@SQL)
				END

			SELECT [id], [hasSavedData] FROM CRMxTemplates WITH(NOLOCK) WHERE [id] = @templateId
		END



	/*CREATE

		Records

		CRMxData''N''
		CRMxRawData''N''

		The CRMxData''N'' and CRMxRawData''N'' tables if not created yet,
		and sets to true(1) the hasSavedData property over the CRMxTemplates row relation
		*/
	IF @option = 6
		BEGIN
			IF @templateId IS NOT NULL
				BEGIN
					SET @currentDataTemplateTable = ''[dbo].[CRMxData'' + CAST(@templateId AS VARCHAR(100)) + '']''

					SET @SQL = ''IF EXISTS(
						SELECT TOP 1 [crmxRecordId]
						FROM '' + @currentDataTemplateTable + '' WITH(NOLOCK)
						WHERE [crmxRecordId] = '' + CAST(@crmxRecordId AS VARCHAR(100)) + ''
						)
						BEGIN
							UPDATE '' + @currentDataTemplateTable + '' WITH(ROWLOCK)
							SET [dateValue] = GETDATE(), [dataKeyValue] = ''+ '''''''' + @dataKeyValue + '''''''' +'', [destinySourceValue]='' + '''''''' + @destinySourceValue + '''''''' + ''
							WHERE [crmxRecordId] = '' + CAST(@crmxRecordId AS VARCHAR(100)) + ''

							SELECT [crmxRecordId] AS ['' + '''''''' + ''CRMxRecord_Id_Result'' + '''''''' + '']
							FROM '' + @currentDataTemplateTable + '' WITH(NOLOCK)
							WHERE [dataKeyValue] = '' + '''''''' + @dataKeyValue + '''''''' + ''
						END
					ELSE
						BEGIN
							INSERT INTO '' + @currentDataTemplateTable + '' (serviceSource, dataKeyValue, destinySourceValue, hasBeenLogicDeleted)
							VALUES ('' + '''''''' + @serviceSource + '''''''' + '', '' + '''''''' + @dataKeyValue + '''''''' + '', '' + '''''''' + @destinySourceValue + '''''''' + '', 0 )
							SELECT SCOPE_IDENTITY() AS ['' + '''''''' + ''CRMxRecord_Id_Result'' + '''''''' + '']
						END''
					PRINT(@SQL)
					EXEC(@SQL)
				END
		END


	/* DELETE

		CRMxRecordId CRMxRawData''N''

		Obliterate*/
	IF @option = 7
		BEGIN
			IF @templateId IS NOT NULL
				BEGIN
					SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + CAST(@templateId AS VARCHAR(100)) + '']''

					SET @SQL = ''DELETE '' + @currentDataTemplateTable +''  WITH(NOLOCK)
					WHERE [crmxRecordId] = '' + CAST(@crmxRecordId AS VARCHAR(MAX)) + ''
					SELECT COUNT ([crmxRecordId])
					FROM '' + @currentDataTemplateTable + ''  WITH(NOLOCK)
					WHERE [crmxRecordId] = '' + CAST(@crmxRecordId AS VARCHAR(MAX))
					PRINT(@SQL)
					EXEC(@SQL)
				END
		END


	/*CREATE

		CRMxData''N''
		CRMxRawData''N''

		The CRMxData''n'' and CRMxRawData tables if not created yet,
		and sets to true(1) the hasSavedData property over the CRMxTemplates row relation
		*/
	IF @option = 8
		BEGIN
			IF @templateId IS NOT NULL
				BEGIN
					SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + CAST(@templateId AS VARCHAR(100)) + '']''

					SET @SQL = ''IF EXISTS(
						SELECT TOP 1 [crmxRecordId]
						FROM '' + @currentDataTemplateTable + ''  WITH(NOLOCK)
						WHERE [crmxRecordId] = '' + CAST(@crmxRecordId AS VARCHAR(MAX)) + ''
						AND [tabSheetIndex] = '' + ''''''''  + CAST(@tabSheetIndex AS VARCHAR(MAX)) + '''''''' + ''
						AND [componentId] = '' + ''''''''  + @componentId + '''''''' + ''
						)
						BEGIN
							UPDATE '' + @currentDataTemplateTable + ''  WITH(ROWLOCK)
							SET [bindingType] = '' + '''''''' + @bindingType + '''''''' + '',
							[dataValue] = '' + '''''''' + @dataValue + '''''''' + ''
							WHERE [crmxRecordId] = '' + CAST(@crmxRecordId AS VARCHAR(MAX)) + ''
							AND [tabSheetIndex] = '' + ''''''''  + CAST(@tabSheetIndex AS VARCHAR(MAX))  + '''''''' + ''
							AND [componentId] = '' + ''''''''  + @componentId + '''''''' + ''
						END
					ELSE
						BEGIN
							INSERT INTO '' + @currentDataTemplateTable + '' (crmxRecordId, tabSheetIndex, componentId, bindingType, dataValue)
							VALUES ('' +
								CAST(@crmxRecordId AS VARCHAR(MAX)) + '', '' +
								CAST(@tabSheetIndex AS VARCHAR(MAX))  + '', '' +
								'''''''' + @componentId + '''''''' + '', '' +
								'''''''' + @bindingType + '''''''' + '', '' +
								'''''''' + @dataValue + '''''''' +
								'' )
						END

					SELECT TOP 1 [crmxRecordId]
					FROM '' + @currentDataTemplateTable + '' WITH(NOLOCK)
					WHERE [crmxRecordId] = '' + '''''''' + CAST(@crmxRecordId AS VARCHAR(MAX)) + '''''''' + ''
					AND [tabSheetIndex] = '' + ''''''''  + CAST(@tabSheetIndex AS VARCHAR(MAX))  + '''''''' + ''
					AND [componentId] = '' + ''''''''  + @componentId + ''''''''
					PRINT(@SQL)
					EXEC(@SQL)
				END
		END


	/* READ

		@ CRMxRawData''N''


		Gets the likelable CRMxRecord components that matches over dataValues
	*/
	IF @option = 9
		BEGIN
			IF @templateId IS NOT NULL
				BEGIN
					SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + CAST(@templateId AS VARCHAR(100)) + '']''
					SET @SQL = ''SELECT TOP 51 * FROM '' + @currentDataTemplateTable  + '' WITH(NOLOCK)
					WHERE [componentId] = '' + '''''''' + @componentId + '''''''' + ''
					AND [tabSheetIndex] = '' + '''''''' + CAST(@tabSheetIndex as VARCHAR(100)) +  '''''''' + ''
					AND [dataValue] LIKE '' + '''''''' + ''%'' + @datavalue + ''%'' + + '''''''' + ''
					ORDER BY [crmxRecordId] ASC, [tabSheetIndex] ASC, [componentId] ASC''

					PRINT(@SQL)
					EXEC(@SQL)
				END
			ELSE
				SELECT N''-9.1''
		END


	/* READ

		@ CRMxData''N''


		Gets the crmxRecord using the crmxRecordId
	*/
	IF @option = 10
		BEGIN
			IF @templateId IS NOT NULL
				BEGIN
					SET @currentDataTemplateTable = ''[dbo].[CRMxData'' + CAST(@templateId AS VARCHAR(100)) + '']''
					SET @SQL = ''SELECT * FROM '' + @currentDataTemplateTable  + '' WITH(NOLOCK)
					WHERE [crmxRecordId] = '' + CAST(@crmxRecordId as VARCHAR(100))

					PRINT(@SQL)
					EXEC(@SQL)
				END
			ELSE
				SELECT N''-10.1''
		END


	IF @option = 11 --Update/insert values into CRMxView
		BEGIN
			declare @componentColumn nvarchar(max)
			select @componentColumn= tabsheet.comp.value(''(@headerIndex)'',''varchar(max)'') from crmxtabsheets WITH(NOLOCK)
				cross apply crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)
				where templateid=@templateId and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') is not null
				and tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') = ''true'' and tabsheet.comp.value(''(@id)'',''varchar(max)'') = @componentId

			IF EXISTS (SELECT TOP 1* FROM CRMxView WITH(NOLOCK) where recordId=@crmxRecordId AND templateId=@templateID)
				BEGIN --Update

					--select @dateValue = dateValue from [dbo].[CRMxData15] where crmxRecordId = @crmxRecordId
					set @sql= ''update [dbo].[CRMxView] WITH(ROWLOCK) set source = '''''' + @destinySourceValue + '''''', date = '''''' + CAST(@dateValue as varchar(max)) +
					'''''', data'' + @componentColumn +'' = '''''' + @dataValue + '''''' WHERE recordId = '' + CAST(@crmxRecordId as varchar(max)) +'' and templateId = '' +
					CAST(@templateID as varchar(max))
					exec (@sql)
					select 1
				END
			ELSE  --Insert
				BEGIN
					set @sql= ''INSERT INTO CRMxVIew ([recordId],[templateId],[date],[source],[data''+ @componentColumn +'']) SELECT crmxRecordId as recordId,
					'' + CAST(@templateId as varchar(max)) + '' as templateId, dateValue as date, destinySourceValue as source, '''''' + @dataValue +'''''' as data''+ @componentColumn +''
					from [dbo].[CRMxData''+ CAST(@templateId as varchar(max)) +''] where crmxRecordId ='' + CAST(@crmxRecordId as varchar(max))
					exec (@sql)
					select 1
				END
		END



	/*	CREATE / UPDATE

		@CRMxRawData''N''

		Creates the record component value if it does not exists, else update it
	*/
	IF @option = 12
		BEGIN

			IF @templateId IS NOT NULL
				BEGIN

					SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + CAST(@templateId AS VARCHAR(100)) + '']''

					SET @SQL = ''
					IF (
						SELECT COUNT(crmxRecordId)
						FROM '' + @currentDataTemplateTable + '' WITH(NOLOCK)
						WHERE crmxRecordId = '' + CAST(@crmxRecordId AS VARCHAR)+ ''
						AND tabSheetIndex = '' + CAST(@tabSheetIndex AS VARCHAR) + ''
						AND componentId = '' + '''''''' + @componentId + '''''''' + ''
						) > 0
						BEGIN
							UPDATE '' + @currentDataTemplateTable + '' WITH(ROWLOCK)
							SET bindingType = '' + '''''''' + @bindingType + '''''''' + '',
							dataValue = '' + '''''''' + @dataValue + '''''''' + ''
							WHERE crmxRecordId = '' + CAST(@crmxRecordId AS VARCHAR) + ''
							AND tabSheetIndex = '' + CAST(@tabSheetIndex AS VARCHAR) + ''
							AND componentId = '' + '''''''' + @componentId + '''''''' + ''
						END
					ELSE
						BEGIN
							INSERT INTO '' + @currentDataTemplateTable + ''
							(crmxRecordId, tabSheetIndex, componentId, bindingType, dataValue)
							VALUES ('' + CAST(@crmxRecordId AS VARCHAR) + '',
							'' + CAST(@tabSheetIndex AS VARCHAR) + '',
							'' + '''''''' + @componentId + '''''''' + '',
							'' + '''''''' + @bindingType + '''''''' + '',
							'' + '''''''' + @dataValue + '''''''' + '')
						END
					SELECT 1''

					PRINT(@SQL)
					EXEC(@SQL)
				END
		END

		/*
			Check if the dataKeyValue already exists
		*/

		IF @option = 13
		BEGIN
			SET @currentDataTemplateTable = ''[dbo].[CRMxData'' + CAST(@templateId AS VARCHAR(100)) + '']''
			SET @SQL = ''SELECT COUNT(DISTINCT([dataKeyValue])) AS [CheckNorris]''
			SET @SQL = @SQL + '' FROM '' + @currentDataTemplateTable
			SET @SQL = @SQL + '' WITH(NOLOCK) WHERE [dataKeyValue] = '' + '''''''' + @dataKeyValue + ''''''''
			EXEC(@SQL)
		END

		/*
			Return a datakeyValue created by the templateID +  + crmxRecordId for inbound calls
		*/

		IF @option=14
		BEGIN
			SET @currentDataTemplateTable = ''[dbo].[CRMxData'' + CAST(@templateId  AS VARCHAR(100)) + '']''
			SET @SQL =''DECLARE @ObjectID int
						BEGIN
						INSERT INTO '' + @currentDataTemplateTable + '' (serviceSource, destinySourceValue, hasBeenLogicDeleted)
							VALUES ('' + '''''''' + @serviceSource + '''''''' + '', '' + '''''''' + @destinySourceValue + '''''''' + '', 0 )
						SET @ObjectID = SCOPE_IDENTITY()
						UPDATE ''+ @currentDataTemplateTable +'' WITH(ROWLOCK) SET dataKeyValue = ''''''+CAST(@templateId  AS VARCHAR(100)) + '':'' +'''''' + CAST(@ObjectID  AS VARCHAR(100))
						OUTPUT INSERTED.* where crmxRecordId = @ObjectID
						END''
			EXEC(@SQL)
		END

		/*
			Delete record from CRMxData
		*/

		IF @option=15
		BEGIN
			SET @currentDataTemplateTable = ''[dbo].[CRMxData'' + CAST(@templateId  AS VARCHAR(100)) + '']''
			SET @SQL =''Delete from '' + @currentDataTemplateTable + '' WITH(NOLOCK) where crmxRecordId = '' +CAST(@crmxRecordId  AS VARCHAR(100))
			SELECT 1
			EXEC(@SQL)
		END


		/* READ

			Template by ID
			*/
		IF @option = 16
			BEGIN
				SELECT * FROM CRMxTemplates WITH(NOLOCK) WHERE id = @templateId
			END

		IF @option =17
			BEGIN
				SET @currentDataTemplateTable = ''[dbo].[CRMxRawView'' + CAST(@templateId AS VARCHAR(100)) + '']''
				SET @sql=''select * from '' +@currentDataTemplateTable + '' WITH(NOLOCK)  where ''+ cast (@componentId as VARCHAR(MAX))+ '' like ''''%'' + cast (@dataValue as VARCHAR(MAX)) +''%'''';''
			exec( @sql)
			END

		/* UPDATE
				Updates the specified row at CRMxRawDataN*/
		IF @option = 18
			BEGIN
				SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + CAST(@templateId AS VARCHAR(100)) + '']''
				SET @SQL = ''
					IF (
						SELECT COUNT(crmxRecordId)
						FROM '' + @currentDataTemplateTable + ''
						WITH(NOLOCK)
						WHERE [crmxRecordId] = '' + CAST(@crmxRecordId AS VARCHAR(100)) + ''
						AND [tabSheetIndex] = '' +CAST(@tabSheetIndex AS VARCHAR(10)) + ''
						AND [componentId] = N'' + '''''''' + CAST(@componentId AS VARCHAR(50)) +'''''''' + ''
						) > 0
						BEGIN
							UPDATE '' + @currentDataTemplateTable + ''
							WITH(ROWLOCK)
							SET	[bindingType] = '' + '''''''' +  CAST(@bindingType AS VARCHAR(100)) + '''''''' + '',
								[dataValue] = '' + '''''''' +  CAST(@dataValue AS VARCHAR(2000)) + '''''''' +  ''
							WHERE [crmxRecordId] = '' + CAST(@crmxRecordId AS VARCHAR(100)) + ''
							AND [tabSheetIndex] = '' + CAST(@tabSheetIndex AS VARCHAR(10)) + ''
							AND [componentId] = '' + '''''''' +  CAST(@componentId AS VARCHAR(50)) + '''''''' + ''
						END
					ELSE
						BEGIN
							INSERT '' + @currentDataTemplateTable + ''
							VALUES('' + CAST(@crmxRecordId AS VARCHAR(100)) +
							'', '' + CAST(@tabSheetIndex AS VARCHAR(10)) +
							'', N'' + '''''''' + CAST(@componentId AS VARCHAR(100)) + '''''''' +
							'', N'' + '''''''' +  CAST(@bindingType AS VARCHAR(100)) + '''''''' +
							'', N'' + '''''''' +  CAST(@dataValue AS VARCHAR(2000)) + '''''''' + '')
						END''
				PRINT(@SQL)
				EXEC(@SQL)
				--SELECT (@SQL) AS ''SQL''
			END

			IF @option=19
			BEGIN
				SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + CAST(@templateId AS VARCHAR(100)) + '']''
				SET @SQL=	''INSERT INTO ''+ @currentDataTemplateTable +''
							SELECT	0 as crmxRecordId,
									crmxtabsheets.tabSheetIndex as tabSheetIndex,
									tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') AS componentId,
									0 as bindingType, '''''''' as dataValue
							FROM crmxtabsheets WITH(NOLOCK)
							CROSS APPLY crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
							WHERE templateid='' + CAST(@templateId AS VARCHAR(100)) + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') IS NOT NULL
							and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') not like ''''label%''''''
				EXEC(@SQL)
				EXEC GetCRMInfo @action = 3, @crmTemplateId =  @templateId
				EXEC GetCRMInfo @action = 8, @crmTemplateId =  @templateId
				SET @SQL=''delete from ''+@currentDataTemplateTable +'' where crmxRecordId=0''
				EXEC(@SQL)
			END
END'
EXEC(@SQL)

SET @PROCESS = 'ALTER PROCEDURE [dbo].[CRMxUploader]'
SET @SQL='-- =============================================
-- Author:		<Mish Alegr?a., Miguel Cast>
-- Create date: <11-Mar-2015>
-- Description:	<Hold every DBLoader operation. Also includes the CRUD for the LoadingTemplateRelationships table.>
-- =============================================
ALTER PROCEDURE [dbo].[CRMxUploader]
	-- Add the parameters for the stored procedure here
	@option INT,				-- Type of Action/proceess to perform
	@templateId INT = null,       -- Template id
	@dataKeyCollection VARCHAR(MAX) = null, -- Collection of dataKeys. ''datakey1'',''datakey2'',...,''datakeyn''
	@componentIdCollection VARCHAR(MAX) = null, -- Collection of componentId''s. ''textInpu1'', ''texTinput2'',....,''numeric1''
	@isLoading BIT = NULL,
	-- LoadingTemplateRelationships
	@loadTempRelId INT = NULL,
	@loadName NVARCHAR(141) = NULL,
	@loadId INT = NULL,
	@loadType TINYINT = 0,
	@crmxRelation XML = NULL,
	@cwxRelation XML = NULL,
	@isUsingHeaders BIT = NULL

AS

DECLARE @SQL VARCHAR(MAX)
DECLARE @currentDataTemplateTable VARCHAR(100)
DECLARE @searchPattern VARCHAR(MAX)

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Get Record Id by cal_key
	IF @option = 1
	BEGIN
		IF (LEN(@dataKeyCollection) = 0	or @dataKeyCollection IS NULL)
		BEGIN
		  SELECT -1
		END
		ELSE
		BEGIN
			SET @SQL = ''SELECT crmxRecordId, dataKeyValue FROM crmxdata'' + CAST(@templateId AS VARCHAR(100))
			+ '' Where dataKeyValue in ('' + @dataKeyCollection + '')''
			EXEC(@SQL)
		END


	END

	-- Delete by cal_key (bulkdelete)
	IF @option = 2
	BEGIN
		IF ((LEN(@dataKeyCollection) = 0	or @dataKeyCollection IS NULL) and
			(LEN(@componentIdCollection) = 0	or @componentIdCollection IS NULL) )
		BEGIN
		  SELECT -1
		END
		ELSE
		BEGIN
			SET @SQL = ''DELETE FROM crmxRawdata'' + CAST(@templateId AS VARCHAR(100))
			+ '' Where crmxRecordId in (SELECT crmxRecordId FROM crmxData''+ CAST(@TemplateId as VARCHAR(100)) + '' WHERE dataKeyValue IN (''  + @dataKeyCollection + '')) and
				componentId in ('' + @componentIdCollection + '')''
			EXEC(@SQL)
		END
	END


	-- Update CRMxData (set Date)
	IF @option = 3
	BEGIN
		IF (LEN(@dataKeyCollection) = 0	or @dataKeyCollection IS NULL)
		BEGIN
		  SELECT -3
		END
		ELSE
		BEGIN
			SET @SQL = ''Update crmxdata'' + CAST(@templateId AS VARCHAR(100))
			+ '' set dateValue = GETDATE() where dataKeyValue in ('' + @dataKeyCollection + '')''
			exec (@SQL)
		END
	END

IF @option = 4
	BEGIN
		IF(@templateID is NULL or @templateId = 0)
		BEGIN
			SELECT -1
		END
		ELSE
		BEGIN
			SET @SQL = ''SELECT  tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') AS ''''componentId'''', crmxtabsheets.tabSheetIndex as ''''tabSheetIndex'''' FROM crmxtabsheets WITH(NOLOCK)
			CROSS APPLY crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
			WHERE templateid='' + CAST(@templateId AS VARCHAR(100))  + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') IS NOT NULL and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') not in(''+ @componentIdCollection +'')''
			EXEC(@SQL)

		END

  END

IF @option = 5
	BEGIN
		SELECT COUNT([NAME]) FROM SYS.TABLES WHERE [NAME] = ''CRMxData'' + CAST(@templateId AS VARCHAR(100)) or [NAME]= ''CRMxRawData'' + CAST(@templateId AS VARCHAR(100));
	END


/** ***************************************************************************
	LoadingTemplateRelationships
* ****************************************************************************/

/*	CREATE
		Create a new relationship.
*/
IF @option = 6
	BEGIN
		IF @templateID IS NULL
		OR	@loadName IS NULL
		OR	@loadID IS NULL
		OR	@loadType IS NULL
		OR	@crmxRelation IS NULL
		OR	@cwxRelation IS NULL
			BEGIN
				SELECT ''-6 : A parameter is not provided or is null (templateID, loadName, loadID, loadType, crmxRelation, cwxRelation).''
			END
		INSERT INTO LoadingTemplateRelationships (crmxTemplateId, name, lastUsage, loadId, loadType, crmxRelation, cwxRelation, usingHeaders)
		VALUES (@templateID, @loadName, GETDATE(), @loadId, @loadType, @crmxRelation, @cwxRelation, @isUsingHeaders)
	END

/*	READ
		Get all the relationships for a specified template. And orders it by date.
*/
IF @option = 7
	BEGIN
		IF @templateID IS NULL
			BEGIN
				SELECT ''-7 : TemplateID not provided or is null.''
			END
		ELSE
			BEGIN
				SELECT id, crmxTemplateId,name,lastUsage,usingHeaders
				FROM LoadingTemplateRelationships
				WITH(NOLOCK)
				WHERE crmxTemplateId = @templateID
				AND logicDeleted = 0
				ORDER BY lastUsage DESC
			END
	END

/*	UPDATE
		Update a specified loadingTemplateRelationship.
*/
IF @option = 8
	BEGIN
		IF @loadTempRelId = NULL
			BEGIN
				SELECT ''-8 : loadTempRelId not provided or is null''
			END
		ELSE
			BEGIN
				SET @SQL = ''
				UPDATE LoadingTemplateRelationships
				SET lastUsage = GETDATE()''
				IF @loadName IS NOT NULL
					BEGIN
						SET @SQL = @SQL + '', name = '' + '''''''' + CAST(@loadName AS NVARCHAR(141)) + ''''''''
					END
				IF @loadID IS NOT NULL
					BEGIN
						SET @SQL = @SQL + '', loadID = '' + CAST(@loadId AS NVARCHAR(100))
					END
				IF @loadType IS NOT NULL
					BEGIN
						SET @SQL = @SQL + '', loadType = '' + CAST(@loadType AS NVARCHAR(10))
					END
				IF @crmxRelation IS NOT NULL
					BEGIN
						SET @SQL = @SQL + '', crmxRelation = N'' + '''''''' + CAST(@crmxRelation AS NVARCHAR(MAX)) + ''''''''
					END
				IF @cwxRelation IS NOT NULL
					BEGIN
						SET @SQL = @SQL + '', cwxRelation = N'' + '''''''' + CAST(@cwxRelation AS NVARCHAR(MAX)) + ''''''''
					END
				IF @isUsingHeaders IS NOT NULL
					BEGIN
						SET @SQL = @SQL + '', usingHeaders = N'' + '''''''' + CAST(@isUsingHeaders AS NVARCHAR(MAX)) + ''''''''
					END
				 SET @SQL = @SQL + ''
				 WHERE id = '' + CAST(@loadTempRelId AS NVARCHAR(MAX))
				PRINT(@SQL)
				EXEC(@SQL)
			END

	END

/*	DELETE
		Sets a relationship as unreachable
*/
IF @option = 9
	BEGIN
		IF @templateId IS NULL
			BEGIN
				SELECT ''-9 : TemplateID is not provided or null.''
			END
		ELSE
			UPDATE LoadingTemplateRelationships
			SET logicDeleted = 1
			WHERE id = @templateID
	END

 /*  READ
		Select a
 */
 IF @option = 10
	BEGIN
		IF @loadID IS NULL
			BEGIN
				SELECT ''-10 : LoadID is not provided or null.''
			END
		ELSE
			BEGIN
				SELECT *
				FROM LoadingTemplateRelationships
				WITH(NOLOCK)
				WHERE id = @loadID
			END
	END


END

/** ***************************************************************************
	Mich uploader changes
* ****************************************************************************/

IF @option = 11
	BEGIN
		UPDATE CRMxTemplates SET isLoadingData = @isLoading WHERE id = @templateId
	END'
EXEC(@SQL)


SET @PROCESS = 'ALTER PROCEDURE [dbo].[mainAgentsTemplateConfigurationDisplayer]'
SET @SQL='-- =============================================
-- Author:		<Castillo>
-- Create date: <15/APR/2015>
-- Description:	<Handles the agent''s last position and size of the displaying template.>
-- =============================================
ALTER PROCEDURE [dbo].[mainAgentsTemplateConfigurationDisplayer]
	-- Add the parameters for the stored procedure here
	@option INT = NULL,
	@templateId INT = NULL,
	@agentId INT = NULL,
	@templatePosition NVARCHAR(50) = NULL,
	@templateSize NVARCHAR(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @version TINYINT,
			@sql NVARCHAR(MAX)
	SET  @version = 1

    -- Returns the current SP version.
	IF @option = 0 OR @option IS NULL
		BEGIN
			SET @SQL = ''mainAgentsTemplateConfigurationDisplayer v'' + CAST(@version AS NVARCHAR(10)) + ''
			''
			SET @SQL = @SQL +  ''	1) ENSURE DATA (templateId, agentId, templatePosition, templateSize) 
			''
			SET @SQL = @SQL +  ''	2) UPDATE (templateId, agentId, templatePosition, templateSize)
			''
			SET @SQL = @SQL +  ''	3) READ
			''
			SET @SQL = @SQL +  ''	4) DELETE
			''
			SET @SQL = @SQL +  ''	9990)	RESET''

			PRINT @SQL
		END

	/* CREATE/UPDATE
		
			Ensures the data at a row.
	*/
	IF @option = 1
		BEGIN
			IF	(
					SELECT COUNT(templateId)
					FROM AgentsTemplateConfigurationDisplayer
					WITH(NOLOCK)
					WHERE templateId = @templateID
					AND agentId = @agentId
					--AND templatePosition = @templatePosition
					--AND templateSize = @templateSize
				) = 0
				BEGIN
					INSERT INTO AgentsTemplateConfigurationDisplayer(templateId, agentId, templatePosition, templateSize)
					VALUES (@templateId, @agentId, @templatePosition, @templateSize)
					SELECT ''1''
				END
			ELSE
				BEGIN
					SET @sql =  ''mainAgentsTemplateConfigurationDisplayer 
							@option = 2, 
							@templateId = '' + CAST(@templateId AS VARCHAR(10)) + '',
							@agentId = '' + CAST(@agentId AS VARCHAR(10)) + '',
							@templatePosition = N'' + '''''''' + @templatePosition + '''''''' + '',
							@templateSize = N'' + '''''''' + @templateSize + ''''''''
					EXEC(@sql)
					--PRINT(@sql)
				END
		END

	/*	UPDATE
			
			Updates the row with the provided data.
	*/
	IF @option = 2
		BEGIN
			IF	(
					SELECT COUNT(templateId)
					FROM AgentsTemplateConfigurationDisplayer
					WITH(NOLOCK)
					WHERE templateId = @templateID
					AND agentId = @agentId
				) = 1
				BEGIN
					UPDATE AgentsTemplateConfigurationDisplayer
					WITH(ROWLOCK)
					SET templatePosition = @templatePosition,
						templateSize = @templateSize
					WHERE	templateId = @templateId
						AND agentId = @agentId

					SELECT ''2''
				END
			ELSE
				BEGIN
					SELECT ''-2''
				END
		END

	/*	READ
		
			Gets the agent''s conf data. 
			FULL table, only per TEMPLATE, or AGENT/TEMPLATE			
	*/
	IF @option = 3
		BEGIN
			IF	@agentId IS NOT NULL AND @templateId IS NOT NULL
				BEGIN
					SELECT *
					FROM AgentsTemplateConfigurationDisplayer
					WITH(NOLOCK)
					WHERE agentId = @agentId
					AND	templateId = @templateId
					ORDER BY templateId ASC, agentId ASC
				END
			ELSE
				BEGIN
					IF @templateID IS NOT NULL
						BEGIN
							SELECT *
							FROM AgentsTemplateConfigurationDisplayer
							WITH(NOLOCK)
							WHERE templateId = @templateId
							ORDER BY templateId
						END
					ELSE
						IF @agentID IS NOT NULL
							BEGIN
								SELECT *
								FROM AgentsTemplateConfigurationDisplayer
								WITH(NOLOCK)
								WHERE agentId = @agentId
								ORDER BY agentId
							END
						ELSE
							BEGIN
								SELECT *
								FROM AgentsTemplateConfigurationDisplayer
								WITH(NOLOCK)
								ORDER BY templateId ASC, agentId ASC
							END
				END
		END

	/*	DELETE
		
			Deletes the provided data.
	*/
	IF @option = 4
		BEGIN
			IF @agentId IS NULL AND @templateId IS NULL
				BEGIN
					SELECT ''-4''
				END
			ELSE
				BEGIN
					IF	@agentId IS NOT NULL AND @templateId IS NOT NULL
						BEGIN
							DELETE AgentsTemplateConfigurationDisplayer
							WHERE agentId = @agentId
							AND	templateId = @templateId
						END
					ELSE
						BEGIN
							IF @templateID IS NOT NULL
								BEGIN
									DELETE AgentsTemplateConfigurationDisplayer
									WHERE templateId = @templateId
								END
							ELSE
								IF @agentId IS NOT NULL
									BEGIN
										DELETE AgentsTemplateConfigurationDisplayer
										WHERE agentId = @agentId
									END
						END
					
					SELECT ''4''
				END
		END





	/*	************
	*	WARNING - RESET
	***************/
	IF @option = 9990
		BEGIN
			TRUNCATE TABLE AgentsTemplateConfigurationDisplayer
		END
END'
EXEC(@SQL)

SET @PROCESS = 'ALTER PROCEDURE [dbo].[saveMyCRMxRecord]'
SET @SQL='-- =============================================
-- Author:		<Castillo>
-- Create date: <2015-MAR-13>
-- Description:	<Nicely saves the CRMxRecord>
-- =============================================
ALTER PROCEDURE [dbo].[saveMyCRMxRecord]
	@crmxRecord XML
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @crmxRecord IS NULL
		SELECT -9991

	DECLARE @templateID INT,
			@dataTName NVARCHAR(50),
			@rawDTName NVARCHAR(50),
			@crmxRecId INT,
			@SQL NVARCHAR(MAX),
			@CRI INT,
			@TIX INT,
			@CID VARCHAR(100),
			@BT VARCHAR(100),
			@DV VARCHAR(2000)

	DECLARE @tempTable TABLE (
				CRI INT NOT NULL,
				TIX INT NULL,
				CID VARCHAR(100) NOT NULL,
				BT VARCHAR(100) NULL,
				DV VARCHAR(2000) NULL
			)

	DECLARE @compTable TABLE (
				componentId varchar(100) NOT NULL
	)

	


	DECLARE cRunner CURSOR FOR
		SELECT CRI, TIX, CID, BT, DV FROM @tempTable

	SELECT @templateID = @crmxRecord.value(''(/Template/@id)[1]'',''INT'')
	SELECT @crmxRecID = @crmxRecord.value(''(/Template/crmxRecord/@id)[1]'',''INT'')


	INSERT @compTable
		SELECT tabsheet.comp.value(''(@id)'',''varchar(max)'') AS ''componentId''  FROM crmxtabsheets WITH(NOLOCK)
		CROSS APPLY crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)
		WHERE templateid = @templateID and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') IS NOT NULL




	SET @dataTName = N''CRMxData'' + CAST(@templateID AS NVARCHAR(10))
	SET @rawDTName = N''CRMxRawData'' + CAST(@templateID AS NVARCHAR(10))

	-- Pre-save the obtained xml data unto table form
	INSERT @tempTable
		SELECT		@crmxRecID AS CRI,
					tabSheet.value(''@index'', ''INT'') AS TSI,
					component.value(''@id'', ''NVARCHAR(100)'') AS CID,
					''none'' AS BT,
					component.value(''@value'', ''NVARCHAR(2000)'') AS DV
		FROM		@crmxRecord.nodes(''Template/tabSheets/tabSheet'') AS TabSheets(tabSheet)
		OUTER APPLY	TabSheets.tabSheet.nodes(''node()'') AS Components(component)
		WHERE component.value(''@id'', ''NVARCHAR(100)'') IN (SELECT componentId FROM @compTable)

	OPEN cRunner
	FETCH cRunner INTO @CRI, @TIX, @CID, @BT, @DV

	EXEC [dbo].[CRMxAgent]	@option = 18,
							@templateId = @templateId,
							@crmxRecordID = @CRI,
							@tabSheetIndex = @TIX,
							@componentId = @CID,
							@bindingType = @BT,
							@dataValue = @DV

	WHILE(@@FETCH_STATUS = 0)
		BEGIN
			FETCH cRunner INTO @CRI, @TIX, @CID, @BT, @DV
			EXEC [dbo].[CRMxAgent]	@option = 18,
							@templateId = @templateId,
							@crmxRecordID = @CRI,
							@tabSheetIndex = @TIX,
							@componentId = @CID,
							@bindingType = @BT,
							@dataValue = @DV
		END

	CLOSE cRunner
	DEALLOCATE cRunner

	-- Lastly, we update the record date
	SET @SQL = ''UPDATE ['' + @dataTName + ''] WITH(ROWLOCK) SET [dateValue] = GETDATE() WHERE [crmxRecordId] = '' + CAST(@crmxRecID AS NVARCHAR(10))
	EXEC(@SQL)

END
'
EXEC(@SQL)

SET @PROCESS = 'ALTER PROCEDURE [dbo].[sp_getSetting]'
SET @SQL='-- =============================================
-- Author:		<Deivid V>
-- Create date: <2015-March-23>
-- Description:	<Get''s the value of the setting>
-- =============================================
ALTER PROCEDURE [dbo].[sp_getSetting]
	-- Add the parameters for the stored procedure here
	@idSetting int = 1,
	@option int = 1
AS
BEGIN
	-- Search by id
	IF @option = 1
		BEGIN
			Select value from [dbo].[settings] where id = @idSetting;
		END
END

'
EXEC(@SQL)

SET @PROCESS = 'ALTER PROCEDURE [dbo].[sp_getVersion]'
SET @SQL='-- =============================================
-- Author:		<Miguel Cast>
-- Create date: <2015-FEB-10>
-- Description:	<Get''s the CRMx version>
-- =============================================
ALTER PROCEDURE [dbo].[sp_getVersion]
	-- Add the parameters for the stored procedure here
	@directive NVARCHAR(4) = NULL,
	@Version int = 0 output
AS
BEGIN
	IF @directive NOT IN ( ''ALL'', ''BD'', ''ADM'', ''AGT'', ''RPT'') AND @directive IS NOT NULL
		BEGIN
			SELECT ''Version module not suitable.''
			return (0)
		END
	ELSE
		BEGIN
		if isnull(@Version, 0) = 0
			begin
				SELECT @Version=cast(value as int) FROM settings WHERE id = 1
				select @version Version
				return(@version)
		END
		else begin
			declare @versionActual  int
			SELECT @versionActual=cast(value as int)  FROM settings WHERE id = 1
			if @Version<=@versionActual begin
				select ''-3'' ID, ''ERROR. Invalid Version for  ''+@directive + ''. Current Version: '' +@versionActual
			return (0)
			end
			else begin
				update settings set value = @Version where id = 1
			end
		end
	END
END
'
EXEC(@SQL)



	/* END SCRIPT RELEASE */

		/* UPGRADE DATABASE VERSION (USE YOUR OWN SCRIPT TO DO IT) */
		UPDATE SETTINGS SET VALUE = @VERSION WHERE ID = 1

		COMMIT TRAN
		END TRY

		BEGIN CATCH

			/* ERROR GENERATED BASED ON SINTAX */
			SELECT @ERRORGENERATED = 'DB SCRIPT VERSION: ' + CAST(@VERSION AS NVARCHAR) +
			' ERROR PROCESS: ' + @PROCESS +
			' LINE: ' + CAST(ERROR_LINE() AS NVARCHAR) +
			' NUMBER: ' + CAST(@@ERROR AS NVARCHAR) +
			' MESSAGE: ' + ERROR_MESSAGE()
			RAISERROR(@ERRORGENERATED, 11, 1)

		ROLLBACK TRAN
		END CATCH
	END
ELSE
	BEGIN
		/* ERROR GENERATED BASED ON DATABASE VERSION */
		SELECT 'INCORRECT DATABASE VERSION, ACTUAL VERSION: ' + CAST(@ACTUALVERSION AS VARCHAR(5)) + ', VERSION TO RELEASE: ' + CAST(@VERSION AS VARCHAR(5))
	END

SET NOCOUNT OFF


