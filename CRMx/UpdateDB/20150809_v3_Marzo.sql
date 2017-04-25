/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Castillo
Date: 2014/20/04
Description:
	create table -- LoadingTemplateRelationships
	CREATE TABLE -- PropertiesByTemplate


	ALTER TABLE -- PropertiesByTemplate CONSTRAINT DF__Propertie__count__0F624AF8
	ALTER TABLE PropertiesByTemplate -- FOREIGN KEY
	ALTER TABLE PropertiesByTemplate -- CONSTRAINT
	ALTER TABLE -- LoadingTemplateRelationships
	ALTER TABLE -- LoadingTemplateRelationships -- CONSTRAINT DF_LoadingTemplateRelationships_logicDeleted
	ALTER TABLE -- LoadingTemplateRelationships -- CONSTRAINT FK_LoadingTemplateRelationships_CRMxTemplates

	exec sys.sp_addextendedproperty -- MS_Description


Database: CCenterRIA
Required version: 2

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 3

/* Actual version (use your own script to do it) */
select @actualVersion=value from  settings where id=1

if @actualVersion = @version - 1
	begin
		begin tran
		begin try


		set @process = 'CREATE TABLE -- LoadingTemplateRelationships'
		set @sql='if not exists (select * from sys.tables where name = N''LoadingTemplateRelationships'')
		CREATE TABLE [dbo].[LoadingTemplateRelationships](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[crmxTemplateId] [int] NOT NULL,
	[name] [nvarchar](141) NOT NULL,
	[lastUsage] [datetime] NOT NULL,
	[loadId] [int] NOT NULL,
	[loadType] [tinyint] NOT NULL,
	[crmxRelation] [xml] NOT NULL,
	[cwxRelation] [xml] NULL,
	[logicDeleted] [bit] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]'
	EXEC(@sql)


		set @process = 'CREATE TABLE -- PropertiesByTemplate'
		set @sql='if not exists (select * from sys.tables where name = N''PropertiesByTemplate'')
		CREATE TABLE [dbo].[PropertiesByTemplate](
	[idTemplate] [int] NOT NULL,
	[countIds] [xml] NOT NULL,
 CONSTRAINT [PK__PropertiesByTemp__0E6E26BF] PRIMARY KEY CLUSTERED
(
	[idTemplate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]'
	EXEC(@sql)

	set @process = 'CREATE TABLE -- AgentsTemplateConfigurationDisplayer'
	set @sql='	IF object_id(''AgentsTemplateConfigurationDisplayer'', ''U'') IS NULL
BEGIN
	CREATE TABLE [dbo].[AgentsTemplateConfigurationDisplayer]
	(
		[templateId] [int] NOT NULL,
		[agentId] [int] NOT NULL,
		[templatePosition] [nvarchar] (50) NOT NULL,
		[templateSize] [nvarchar] (50) NOT NULL
	) ON [PRIMARY]
END'
	EXEC(@sql)

		set @process = 'ALTER TABLE -- PropertiesByTemplate DROP CONSTRAINT [DF__Propertie__count__0F624AF8]'
		set @sql='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF__Propertie__count__0F624AF8'')
			ALTER TABLE [dbo].[PropertiesByTemplate] DROP CONSTRAINT [DF__Propertie__count__0F624AF8]'
		EXEC(@sql)



		set @process = 'ALTER TABLE -- PropertiesByTemplate CONSTRAINT DF__Propertie__count__0F624AF8'
		set @sql='if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF__Propertie__count__0F624AF8'')
	begin
		ALTER TABLE [dbo].[PropertiesByTemplate] ADD  CONSTRAINT [DF__Propertie__count__0F624AF8]  DEFAULT (''<CountIDComponents>
		<label id="1"/>
		<textInput id="1"/>
		<numeric id="1"/>
		<time id="1"/>
		<textArea id="1"/>
		<comboBox id="1"/>
		<calendar id="1"/>
		<image id="1"/>
		<checkBox id="1"/>
		<radioButton id="1"/>
		</CountIDComponents>'') FOR [countIds]
	end'
	EXEC(@sql)

		set @process = 'ALTER TABLE PropertiesByTemplate -- FOREIGN KEY'
		set @sql='if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''fk_idTemplate'')
	begin
		ALTER TABLE [dbo].[PropertiesByTemplate]  WITH CHECK ADD  CONSTRAINT [fk_idTemplate] FOREIGN KEY([idTemplate])
REFERENCES [dbo].[CRMxTemplates] ([id])
ON DELETE CASCADE
	end'
	EXEC(@sql)

		set @process = 'ALTER TABLE -- LoadingTemplateRelationships ADD COLUMN'
		set @sql='
		if not exists(select * from sys.columns
            where Name = N''usingHeaders'' and Object_ID = Object_ID(N''LoadingTemplateRelationships''))
		begin
		    ALTER TABLE [dbo].[LoadingTemplateRelationships] ADD  usingHeaders BIT NOT NULL
		end'
	EXEC(@sql)

		set @process = 'ALTER TABLE PropertiesByTemplate -- CONSTRAINT fk_idTemplate'
		set @sql='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''fk_idTemplate'')
	begin
		ALTER TABLE [dbo].[PropertiesByTemplate] CHECK CONSTRAINT [fk_idTemplate]
	end'
	EXEC(@sql)

		set @process = 'ALTER TABLE -- LoadingTemplateRelationships ADD  CONSTRAINT [DF_Table_2_lastUsage]'
		set @sql='if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_Table_2_lastUsage'')
	begin
		ALTER TABLE [dbo].[LoadingTemplateRelationships] ADD  CONSTRAINT [DF_Table_2_lastUsage]  DEFAULT (getdate()) FOR [lastUsage]
	end'
	EXEC(@sql)


		set @process = 'ALTER TABLE -- LoadingTemplateRelationships -- CONSTRAINT DF_LoadingTemplateRelationships_logicDeleted'
		set @sql='if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_LoadingTemplateRelationships_logicDeleted'')
	begin
		ALTER TABLE [dbo].[LoadingTemplateRelationships] ADD  CONSTRAINT [DF_LoadingTemplateRelationships_logicDeleted]  DEFAULT ((0)) FOR [logicDeleted]
		end'
	EXEC(@sql)


		set @process = 'ALTER TABLE -- LoadingTemplateRelationships ADD  CONSTRAINT [FK_LoadingTemplateRelationships_CRMxTemplates]'
		set @sql='if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''FK_LoadingTemplateRelationships_CRMxTemplates'')
	begin
		ALTER TABLE [dbo].[LoadingTemplateRelationships]  WITH CHECK ADD  CONSTRAINT [FK_LoadingTemplateRelationships_CRMxTemplates] FOREIGN KEY([crmxTemplateId])
		REFERENCES [dbo].[CRMxTemplates] ([id])
		ON DELETE CASCADE
	END'
	EXEC(@sql)


	set @process = 'Drop stored -- mainAgentsTemplateConfigurationDisplayer'
	set @sql='if exists (select * from sys.procedures where name = N''mainAgentsTemplateConfigurationDisplayer'') drop PROCEDURE [mainAgentsTemplateConfigurationDisplayer]'
 	EXEC(@sql)

 	set @process = 'Drop stored -- CRMxAgent'
	set @sql='if exists (select * from sys.procedures where name = N''CRMxAgent'') drop PROCEDURE [CRMxAgent]'
 	EXEC(@sql)

 	set @process = 'Drop stored -- GetCRMInfo'
	set @sql='if exists (select * from sys.procedures where name = N''GetCRMInfo'') drop PROCEDURE [GetCRMInfo]'
 	EXEC(@sql)

 	set @process = 'CREATE STORE PROCEDURE -- GetCRMInfo'
	set @sql='CREATE PROCEDURE [dbo].[GetCRMInfo]
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
		select * from crmxtemplates WITH(NOLOCK)
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
			from  (select distinct componentId  from CRMxRawData'' + @crmTemplateId + ''
			where componentId  in (
			select  tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') as ''''commponentId''''  from crmxtabsheets WITH(NOLOCK)
			cross apply crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
			where templateid='' + @crmTemplateId + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') is not null AND tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') is not null
			and tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') = ''''true'''')
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

			exec( @query )''

		exec( @query)
		end

	end

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
			where templateid='' + @crmTemplateId + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') is not null AND tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') is not null) T1_descriptionN


			select @pivot1_descriptionT = coalesce(@pivot1_descriptionT + '''','''','''''''','''''''''''''''') + QuoteName(componentId)
			from  (select distinct componentId  from CRMxRawData'' + @crmTemplateId + '' WITH(NOLOCK)
			where componentId  in (
			select  tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') as ''''commponentId''''  from crmxtabsheets WITH(NOLOCK)
			cross apply crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
			where templateid='' + @crmTemplateId + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') is not null AND tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') is not null)) T1_descriptionT

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

		exec(@query)
 end

end'
 	EXEC(@sql)


 	set @process = 'CREATE STORE PROCEDURE -- mainAgentsTemplateConfigurationDisplayer'
	set @sql='CREATE PROCEDURE [dbo].[mainAgentsTemplateConfigurationDisplayer]
	-- Add the parameters for the stored procedure here
	@option INT,
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
	IF @option = 0
		BEGIN
			SELECT ''mainAgentsTemplateConfigurationDisplayer v'' + CAST(@version AS NVARCHAR(10))
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
	EXEC(@sql)

	set @process = 'CREATE stored -- CRMxAgent'
	set @sql='CREATE PROCEDURE [dbo].[CRMxAgent]
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
 	EXEC(@sql)

	set @process = 'ALTER STORE PROCEDURE -- CRMxUploader'
	set @sql='-- =============================================
-- Author:		<Mish Alegría., Miguel Cast>
-- Create date: <11-Mar-2015>
-- Description:	<Hold every DBLoader operation. Also includes the CRUD for the LoadingTemplateRelationships table.>
-- =============================================
ALTER PROCEDURE [dbo].[CRMxUploader]
	-- Add the parameters for the stored procedure here
	@option INT,				-- Type of Action/proceess to perform
	@templateId INT = null,       -- Template id
	@dataKeyCollection VARCHAR(MAX) = null, -- Collection of dataKeys. ''datakey1'',''datakey2'',...,''datakeyn''
	@componentIdCollection VARCHAR(MAX) = null, -- Collection of componentId''s. ''textInpu1'', ''texTinput2'',....,''numeric1''
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


END'
		EXEC(@sql)

		set @process = 'ALTER STORE PROCEDURE -- sp_getVersion'
		set @sql='-- =============================================
-- Author:		<Miguel Cast>
-- Create date: <2015-FEB-10>
-- Description:	<Get''s the CRMx version>
-- =============================================
ALTER PROCEDURE [dbo].[sp_getVersion]
	-- Add the parameters for the stored procedure here
	@directive NVARCHAR(4) = NULL
AS
BEGIN
	IF @directive NOT IN ( ''ALL'', ''BD'', ''ADM'', ''AGT'', ''RPT'') AND @directive IS NOT NULL
		BEGIN
			SELECT ''Version module not suitable.''
		END
	ELSE
		BEGIN
			SELECT value AS [DB Version] FROM settings WHERE id = 1

			--SELECT CASE @directive
			--			WHEN ''ALL'' THEN @mVersion
			--			WHEN ''BD'' THEN @mVersion
			--			WHEN ''ADM'' THEN @mVersion
			--			WHEN ''AGT'' THEN @mVersion
			--			WHEN ''RPT'' THEN @mVersion
			--		END
		END
END'
		EXEC(@sql)

	set @process = 'ALTER STORE PROCEDURE -- CRMxABCTemplates'
	set @sql='ALTER PROCEDURE [dbo].[CRMxABCTemplates]
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
		If exists (select * from CRMxtemplates where id=@templateId and hasSavedData=0)
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
			If exists (select * from CRMxtemplates where id=@templateId and hasSavedData=0)
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
		EXEC(@sql)


	set @process = 'exec sys.sp_addextendedproperty -- MS_Description'
	set @sql='EXEC sys.sp_addextendedproperty @name=N''MS_Description'', @value=N''Matches the TemplateID over the loader data'' , @level0type=N''SCHEMA'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''LoadingTemplateRelationships'', @level2type=N''CONSTRAINT'',@level2name=N''FK_LoadingTemplateRelationships_CRMxTemplates'''
	EXEC(@sql)


			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			UPDATE settings SET value=@version WHERE id= 1

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