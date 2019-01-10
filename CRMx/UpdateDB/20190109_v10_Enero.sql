/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus GAllardo
Date: 2017/08/10
Description: 
********************************************************************************************

   Se modifican el SPs CRMxUploader


Database: CW_CRMx
Required version: 7

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it

*/

SET NOCOUNT ON

DECLARE @VERSION INT
DECLARE @ACTUALVERSION INT
DECLARE @SQL VARCHAR(MAX)
DECLARE @ERRORGENERATED VARCHAR(MAX)
DECLARE @PROCESS VARCHAR(MAX)

/* VERSION TO RELEASE (USE THE VERSION OF YOUR OWN DATABSE)*/
SET @VERSION = 10

/* ACTUAL VERSION (USE YOUR OWN SCRIPT TO DO IT) */
SET @ACTUALVERSION =  (SELECT VALUE FROM SETTINGS WHERE ID = 1)

IF @ACTUALVERSION in( @VERSION - 1, @VERSION )
  BEGIN
    BEGIN TRAN
    BEGIN TRY

  /* START SCRIPT RELEASE */
    
  
    set @process = 'Alter SP CRMxABCTemplates' 
	set @Sql= 'ALTER PROCEDURE [dbo].[CRMxABCTemplates]
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
	IF not exists( SELECT * FROM dbo.CRMxTemplates WITH(NOLOCK) WHERE id = @templateId) BEGIN
		SELECT -1 --''No existe el template
	END
	ELSE BEGIN		
		UPDATE CRMxTemplates WITH(ROWLOCK) SET name= isnull(@templateName,name),description=ISNULL(@templateDescription,description)
		,isActive=ISNULL(@isActive,isActive)
		,displayData=ISNULL(@displayData,displayData)
		,dataSavingModality=ISNULL(@dataSavingModality,dataSavingModality)
		,dataKeyType=ISNULL(@dataKeyType,dataKeyType)
		,servicesType=ISNULL(@servicesType,servicesType)
		,servicesRelation=ISNULL(@templateServicesRelation,servicesRelation)
		WHERE Id=@templateId

		SELECT 1
END

--	GET tabSheets ordered
 IF @option = 5
	IF not exists( SELECT * FROM CRMxTabSheets WITH(NOLOCK) WHERE templateId = @templateId) BEGIN
		SELECT -1 --''No tiene tabSheets
	END
	ELSE BEGIN
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
	IF not exists( SELECT id FROM dbo.CRMxTemplates WITH(NOLOCK) WHERE id = @templateId and hasBeenLogicDeleted = 0) BEGIN
		SELECT -1 --''No existe el template
	END
	ELSE BEGIN
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
    EXEC(@Sql)


      set @process = 'CW-2495 -- Alter SP CRMxAgent'
	set @Sql= 'ALTER PROCEDURE [dbo].[CRMxAgent] 
@option INT = 0,    -- Type of Action/proceess to perform
@serviceType VARCHAR(50) = NULL,  -- Type of invoker service
@servicesType VARCHAR(50) = NULL,  -- Type of service associated, catalog
@serviceSource VARCHAR(50) = NULL,  -- The invoker serviceSource
@callType INT = NULL,     -- Call Type, ACD or CAMP
@callTypeId INT= NULL,     -- Call identifier, camp #1 or acd#2
@dnis BIGINT = NULL,       -- Dnis, i.e. 2099
@templateId INT = NULL,     -- Template id''s
@tabSheetIndex INT = NULL,    -- TabSheet id''s
@componentId VARCHAR(100) = NULL,  -- Component id''s
@bindingType VARCHAR(100) = NULL,   -- Type of binding to perform
@dataValue VARCHAR(MAX) = NULL,   -- Component stored value
@dataKeyType VARCHAR(50) = NULL,   -- DataKey
@dataKeyValue VARCHAR(MAX) = NULL,   -- DataKey
@destinySourceValue VARCHAR(MAX) = NULL, -- Client client serviceSource destiny or origin, as source to return operation.
@crmxRecordId INT = NULL,
@dateValue dateTime = NULL                --Record date
AS


DECLARE @SQL nVARCHAR(MAX), @parameterDefinition nvarchar(200)
DECLARE @currentDataTemplateTable VARCHAR(100)
DECLARE @templateIdString VARCHAR(100)
declare @id int

set @templateIdString=CAST(@templateId AS VARCHAR(100))

BEGIN
 SET NOCOUNT ON;

 -- Insert statements for procedure here
 /* READ

  Valid Template
  -- serviceType,
   -- call :: callId, callType, dnis
   -- sms ::
   -- email ::
   */
 IF @option = 1 BEGIN  
	IF @serviceType LIKE ''call%'' BEGIN-- CALL    
		set @parameterDefinition=''@id int,@servicesType varchar(50),@dnis int''     
		IF @callType = 0 BEGIN -- CALL::Campaign 
			set @id = @callTypeId
			set @sql=''IF exists(SELECT id FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''''%''''+@servicesType+''''%'''' and [hasBeenLogicDeleted] = 0
	AND servicesRelation.exist(''''/servicesRelation/call/Campaign[@id=sql:variable("@id")]'''') = 1 )
BEGIN
	SELECT * FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''''%''''+@servicesType+''''%'''' and [hasBeenLogicDeleted] = 0
	AND servicesRelation.exist(''''/servicesRelation/call/Campaign[@id=sql:variable("@id")]'''') = 1
END
ELSE BEGIN
	SELECT -1.1
END''		
		END
		ELSE IF @dnis<>0 BEGIN-- CALL::ACD      		 
			set @id = @dnis
			set @sql=''IF exists(SELECT id FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''''%''''+@servicesType+''''%'''' and [hasBeenLogicDeleted] = 0
	AND servicesRelation.exist(''''/servicesRelation/call/ACD[@dnis=sql:variable("@dnis")]'''') = 1 )
BEGIN
	SELECT * FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''''%''''+@servicesType+''''%'''' and [hasBeenLogicDeleted] = 0
	AND servicesRelation.exist(''''/servicesRelation/call/ACD[@dnis=sql:variable("@dnis")]'''') = 1
END
ELSE IF exists(SELECT id FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''''%''''+@servicesType+''''%'''' and [hasBeenLogicDeleted] = 0
	AND servicesRelation.exist(''''/servicesRelation/call/ACD[@id=sql:variable("@id")]'''') = 1 )
BEGIN
	SELECT * FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''''%''''+@servicesType+''''%'''' and [hasBeenLogicDeleted] = 0
	AND servicesRelation.exist(''''/servicesRelation/call/ACD[@id=sql:variable("@id")]'''') = 1
END
ELSE BEGIN
	SELECT -1.2
END''		
		end	  
		ELSE BEGIN
			set @id = @callTypeId
			set @sql=''IF exists(SELECT id FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''''%''''+@servicesType+''''%'''' and [hasBeenLogicDeleted] = 0
	AND servicesRelation.exist(''''/servicesRelation/call/ACD[@id=sql:variable("@id")]'''') = 1 )
BEGIN
	SELECT * FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''''%''''+@servicesType+''''%'''' and [hasBeenLogicDeleted] = 0
	AND servicesRelation.exist(''''/servicesRelation/call/ACD[@id=sql:variable("@id")]'''') = 1
END
ELSE BEGIN
	SELECT -1.2
END''		
	  END		
	EXECUTE sp_executesql  @sql, @parameterDefinition,@servicesType=@servicesType,@id=@id,@dnis=@dnis
	print(@sql)
	END
END ---- @option = 1
 /* READ

  @CRMxTabSheets

  Gets the TabSheets associated to ''X'' templateId
 */
 else IF @option = 2 BEGIN
   if not exists (SELECT [templateId] FROM CRMxTabSheets WITH(NOLOCK) WHERE [templateId] = @templateId) begin -- NO TEMPLATE HAS VALID DATA    
		SELECT N''-2.1''
	END
   ELSE BEGIN
		SELECT * FROM CRMxTabSheets WITH(NOLOCK) WHERE [templateId] = @templateId ORDER BY [tabSheetIndex] ASC
	END
 END ---- @option = 2

 /* READ
  @ CRMxData''N''
  Gets the CRMxRecord that best matches
 */
 else IF @option=3  BEGIN
	IF @templateId IS NOT NULL  BEGIN
		SET @currentDataTemplateTable = ''CRMxData'' + @templateIdString
		set @parameterDefinition=''@dataKeyValue varchar(max),@destinySourceValue varchar(max)''
		IF exists(SELECT * FROM SYS.TABLES WHERE [NAME] = @currentDataTemplateTable) BEGIN
			SET @SQL = ''SELECT TOP 1 * FROM [dbo].['' + @currentDataTemplateTable + ''] WITH(NOLOCK)''

			IF @dataKeyValue IS NOT NULL SET @SQL = @SQL + '' WHERE [dataKeyValue]= @dataKeyValue ''
			ELSE SET @SQL = @SQL + '' WHERE [destinySourceValue]= @destinySourceValue''

			SET @SQL = @SQL + '' AND [hasBeenLogicDeleted] = 0 ORDER BY [dateValue] DESC''       
			EXECUTE sp_executesql  @sql, @parameterDefinition,@dataKeyValue=@dataKeyValue,@destinySourceValue=@destinySourceValue
		END
		ELSE SELECT N''-3.1''
	END
   ELSE SELECT N''-3.2''
   return (0);
END ---- @option = 3

 /* READ
  @ CRMxRawData''N''
  Gets the CRMxRecord components using the crmxRecordId
 */
 else IF @option=4   BEGIN
   IF @templateId IS NOT NULL  BEGIN
     set @parameterDefinition=''@crmxRecordId int''
     SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + @templateIdString + '']''
     SET @SQL = ''SELECT * FROM '' + @currentDataTemplateTable  + '' WITH(NOLOCK)
     WHERE [crmxRecordId]=@crmxRecordId
     ORDER BY [tabSheetIndex] ASC, [componentId] ASC''     
     EXECUTE sp_executesql  @sql, @parameterDefinition,@crmxRecordId=@crmxRecordId
   END
   ELSE SELECT N''-4.1''
  return 0;
END
 /*CREATE
  CRMxData''N''
  CRMxRawData''N''
  The CRMxData''n'' and CRMxRawData tables if not created yet,
  and sets to true(1) the hasSavedData property over the CRMxTemplates row relation
  */
 else IF @option = 5 BEGIN
   IF exists (SELECT [hasSavedData] FROM CRMxTemplates WITH(ROWLOCK) WHERE [id] = @templateId) BEGIN
     UPDATE CRMxTemplates WITH(ROWLOCK) SET [hasSavedData] = 1  WHERE [id] = @templateId
   END
   SET @currentDataTemplateTable = ''CRMxData'' + @templateIdString

   IF not exists(SELECT name FROM SYS.TABLES WHERE [NAME] = @currentDataTemplateTable)  BEGIN
     SET @SQL = ''CREATE TABLE [dbo].['' +  @currentDataTemplateTable + '']  (
      [crmxRecordId] [int] IDENTITY(1,1) NOT NULL,
      [serviceSource] [varchar](50) NULL,
      [dataKeyValue] [varchar](100) NULL,
      [destinySourceValue] [varchar](100) NULL,
      [dateValue] [datetime] NOT NULL,
      [hasBeenLogicDeleted] [bit] NOT NULL,
    [callData] [xml] NULL,
     CONSTRAINT [PK_''+@currentDataTemplateTable+''] PRIMARY KEY CLUSTERED
     (
      [crmxRecordId] ASC
     )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
     )'' +
     ''ALTER TABLE '' + @currentDataTemplateTable +
     '' ADD CONSTRAINT [DF_CRMxData'' + @templateIdString +
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

     SET ANSI_PADDING ON ''

    -- PRINT(@SQL)
     EXEC(@SQL)
	END

   SET @currentDataTemplateTable = ''CRMxRawData'' + @templateIdString
   IF not exists(SELECT [NAME] FROM SYS.TABLES WHERE [NAME] = @currentDataTemplateTable) BEGIN
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

		 ALTER TABLE [dbo].[''+@currentDataTemplateTable+''] ADD  CONSTRAINT [DF__CRMxRawDa__dataV_''+@templateIdString+'']  DEFAULT ('''' '''') FOR [dataValue]''
		EXEC(@SQL)

		exec [CRMxAgent] @option=19, @templateId=@templateId
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
 else IF @option = 6 BEGIN
   IF @templateId IS NOT NULL BEGIN
     SET @currentDataTemplateTable = ''[dbo].[CRMxData'' + @templateIdString + '']''

	 set @parameterDefinition=''@dataKeyValue varchar(max),@destinySourceValue varchar(max),@crmxRecordId int,@serviceSource VARCHAR(50)''
     SET @SQL = ''IF EXISTS( SELECT [crmxRecordId] FROM '' + @currentDataTemplateTable + '' WITH(NOLOCK)
WHERE [crmxRecordId] = @crmxRecordId) BEGIN
	UPDATE '' + @currentDataTemplateTable + '' WITH(ROWLOCK)
    SET [dateValue] = GETDATE(), [dataKeyValue] = @dataKeyValue, [destinySourceValue]=@destinySourceValue
    WHERE [crmxRecordId] = @crmxRecordId
	
	SELECT [crmxRecordId] AS [CRMxRecord_Id_Result] FROM '' + @currentDataTemplateTable + '' WITH(NOLOCK)
    WHERE [dataKeyValue] = @dataKeyValue
END
	ELSE BEGIN
       INSERT INTO '' + @currentDataTemplateTable + '' (serviceSource, dataKeyValue, destinySourceValue, hasBeenLogicDeleted)
       VALUES (@serviceSource , @dataKeyValue , @destinySourceValue , 0 )
       SELECT SCOPE_IDENTITY() AS [CRMxRecord_Id_Result]
END''
    EXECUTE sp_executesql  @sql, @parameterDefinition,@dataKeyValue =@dataKeyValue,@serviceSource =@serviceSource,@destinySourceValue=@destinySourceValue,@crmxRecordId=@crmxRecordId
	END
END
 /* DELETE
  CRMxRecordId CRMxRawData''N''
  Obliterate*/
 else IF @option = 7 BEGIN
   IF @templateId IS NOT NULL BEGIN
	 set @parameterDefinition=''@crmxRecordId int''
     SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + @templateIdString + '']''

     SET @SQL = ''DELETE '' + @currentDataTemplateTable +''  WITH(NOLOCK) WHERE [crmxRecordId] = @crmxRecordId

     SELECT COUNT ([crmxRecordId]) FROM '' + @currentDataTemplateTable + ''  WITH(NOLOCK) WHERE [crmxRecordId] = @crmxRecordId''     
     EXECUTE sp_executesql  @sql, @parameterDefinition, @crmxRecordId=@crmxRecordId
	END
END
 /*CREATE
  CRMxData''N''
  CRMxRawData''N''
  The CRMxData''n'' and CRMxRawData tables if not created yet,
  and sets to true(1) the hasSavedData property over the CRMxTemplates row relation
*/
else IF @option = 8 BEGIN
	IF @templateId IS NOT NULL BEGIN		
		SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + @templateIdString + '']''
		
		set @parameterDefinition=''@crmxRecordId int,@tabSheetIndex int,@componentId varchar(100),@bindingType varchar(100),@dataValue varchar(max)''
		SET @SQL = ''IF EXISTS( SELECT [crmxRecordId] FROM '' + @currentDataTemplateTable + ''  WITH(NOLOCK)
WHERE [crmxRecordId] = @crmxRecordId AND [tabSheetIndex] = @tabSheetIndex AND [componentId] = @componentId)  BEGIN
	UPDATE '' + @currentDataTemplateTable + ''  WITH(ROWLOCK) SET [bindingType] = @bindingType , [dataValue] = @dataValue 
    WHERE [crmxRecordId] = @crmxRecordId AND [tabSheetIndex] = @tabSheetIndex AND [componentId] = @componentId
END
	ELSE BEGIN
       INSERT INTO '' + @currentDataTemplateTable + '' (crmxRecordId, tabSheetIndex, componentId, bindingType, dataValue)
       VALUES (@crmxRecordId ,@tabSheetIndex,@componentId,@bindingType,@dataValue)
   END

SELECT TOP 1 [crmxRecordId] FROM '' + @currentDataTemplateTable + '' WITH(NOLOCK)
WHERE [crmxRecordId] = @crmxRecordId AND [tabSheetIndex] = @tabSheetIndex AND [componentId] = @componentId''
     
		EXECUTE sp_executesql  @sql, @parameterDefinition,@crmxRecordId=@crmxRecordId,@tabSheetIndex =@tabSheetIndex,@componentId=@componentId,
		@bindingType=@bindingType,@dataValue=@dataValue
    END
END
 /* READ
  @ CRMxRawData''N''
  Gets the likelable CRMxRecord components that matches over dataValues
 */
else IF @option = 9 BEGIN
   IF @templateId IS NOT NULL BEGIN
     SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + @templateIdString + '']''
	 set @parameterDefinition=''@tabSheetIndex int,@componentId varchar(100),@dataValue varchar(max)''

     SET @SQL = ''SELECT TOP 51 * FROM '' + @currentDataTemplateTable  + '' WITH(NOLOCK)
	 WHERE [componentId] = @componentId AND [tabSheetIndex] = @tabSheetIndex AND [dataValue] LIKE ''''%''''@datavalue''''%''''
     ORDER BY [crmxRecordId] ASC, [tabSheetIndex] ASC, [componentId] ASC''
     
     EXECUTE sp_executesql  @sql, @parameterDefinition,@tabSheetIndex =@tabSheetIndex,@componentId=@componentId,@dataValue=@dataValue
	END
	ELSE SELECT N''-9.1''
END
 /* READ
  @ CRMxData''N''
  Gets the crmxRecord using the crmxRecordId
 */
 else IF @option = 10 BEGIN
	IF @templateId IS NOT NULL    BEGIN
		SET @currentDataTemplateTable = ''[dbo].[CRMxData'' + @templateIdString + '']''
		set @parameterDefinition=''@crmxRecordId int''
		SET @SQL = ''SELECT * FROM '' + @currentDataTemplateTable  + '' WITH(NOLOCK) WHERE [crmxRecordId] = @crmxRecordId''     
		EXECUTE sp_executesql  @sql, @parameterDefinition,@crmxRecordId=@crmxRecordId
	END
   ELSE SELECT N''-10.1''
END

else IF @option = 11 BEGIN--Update/insert values into CRMxView
   declare @componentColumn nvarchar(max)
   select @componentColumn= tabsheet.comp.value(''(@headerIndex)'',''varchar(max)'') from crmxtabsheets WITH(NOLOCK)
   cross apply crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)
   where templateid=@templateId and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null 
   AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') is not null
   and tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') = ''true'' and tabsheet.comp.value(''(@id)'',''varchar(max)'') = @componentId
   
   set @parameterDefinition=''@destinySourceValue varchar(max),@dateValue datetime, @crmxRecordId int,@templateID  int''

   IF EXISTS (SELECT TOP 1 * FROM CRMxView WITH(NOLOCK) where recordId=@crmxRecordId AND templateId=@templateID) BEGIN --Update     
	set @sql= ''update [dbo].[CRMxView] WITH(ROWLOCK) set source = @destinySourceValue, date = @dateValue, data'' + @componentColumn +'' = @dataValue 
	WHERE recordId = @crmxRecordId and templateId = @templateID ''		
   END
   ELSE  BEGIN--Insert    
     set @sql= ''INSERT INTO CRMxVIew ([recordId],[templateId],[date],[source],[data''+ @componentColumn +'']) 
	 SELECT crmxRecordId as recordId, @templateId as templateId, dateValue as date, destinySourceValue as source, @dataValue data''+ @componentColumn +''
     from [dbo].[CRMxData''+ CAST(@templateId as varchar(max)) +''] where crmxRecordId =@crmxRecordId ''          
    END
	EXECUTE sp_executesql  @sql, @parameterDefinition,@destinySourceValue =@destinySourceValue,@dataValue=@dataValue,@crmxRecordId=@crmxRecordId,@templateID=@templateID 
	select 1
END
 /* CREATE / UPDATE
  @CRMxRawData''N''
  Creates the record component value if it does not exists, else update it
 */
else IF @option = 12 BEGIN
   IF @templateId IS NOT NULL BEGIN		
		SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + @templateIdString + '']''
		set @parameterDefinition=''@crmxRecordId int, @tabSheetIndex int,@componentId varchar(100),@bindingType varchar(100),@dataValue varchar(max)''
		SET @SQL = ''IF exists( SELECT crmxRecordId FROM '' + @currentDataTemplateTable + '' WITH(NOLOCK)
	WHERE crmxRecordId = @crmxRecordId AND tabSheetIndex = @tabSheetIndex AND componentId = @componentId) BEGIN
	UPDATE '' + @currentDataTemplateTable + '' WITH(ROWLOCK) SET bindingType = @bindingType, dataValue = @dataValue
	WHERE crmxRecordId = @crmxRecordId AND tabSheetIndex = @tabSheetIndex AND componentId = @componentId
END
ELSE BEGIN
       INSERT INTO '' + @currentDataTemplateTable + ''(crmxRecordId, tabSheetIndex, componentId, bindingType, dataValue)
       VALUES (@crmxRecordId,@tabSheetIndex, @componentId, @bindingType, @dataValue)
END
SELECT 1''     
     EXECUTE sp_executesql  @sql, @parameterDefinition,@crmxRecordId=@crmxRecordId,@tabSheetIndex=@tabSheetIndex,@componentId=@componentId,@bindingType=@bindingType,@dataValue=@dataValue 
    END
END
  /*
   Check if the dataKeyValue already exists
  */

else  IF @option = 13 BEGIN
   SET @currentDataTemplateTable = ''[dbo].[CRMxData'' + @templateIdString + '']''
   set @parameterDefinition=''@dataKeyValue varchar(max)''
   SET @SQL = ''SELECT COUNT(DISTINCT([dataKeyValue])) AS [CheckNorris] FROM '' + @currentDataTemplateTable
   + '' WITH(NOLOCK) WHERE [dataKeyValue] = @dataKeyValue''
   EXECUTE sp_executesql  @sql, @parameterDefinition,@dataKeyValue=@dataKeyValue
END
  /*
   Return a datakeyValue created by the templateID +  + crmxRecordId for inbound calls
  */
else IF @option=14  BEGIN
   SET @currentDataTemplateTable = ''[dbo].[CRMxData'' + CAST(@templateId  AS VARCHAR(100)) + '']''
   set @parameterDefinition=''@serviceSource varchar(50),@destinySourceValue varchar(max)''
   SET @SQL =''DECLARE @ObjectID int
      BEGIN
      INSERT INTO '' + @currentDataTemplateTable + '' (serviceSource, destinySourceValue, hasBeenLogicDeleted)
       VALUES (@serviceSource,@destinySourceValue, 0 )
      SET @ObjectID = SCOPE_IDENTITY()
      UPDATE ''+ @currentDataTemplateTable +'' WITH(ROWLOCK) SET dataKeyValue = ''''''+CAST(@templateId  AS VARCHAR(100)) + '':'' +'''''' + CAST(@ObjectID  AS VARCHAR(100))
      OUTPUT INSERTED.* where crmxRecordId = @ObjectID
      END''
   EXECUTE sp_executesql  @sql, @parameterDefinition,@serviceSource=@serviceSource,@destinySourceValue=@destinySourceValue
  END

  /*
   Delete record from CRMxData
  */

else  IF @option=15  BEGIN
   SET @currentDataTemplateTable = ''[dbo].[CRMxData'' + CAST(@templateId  AS VARCHAR(100)) + '']''
   set @parameterDefinition=''@crmxRecordId int''
   SET @SQL =''Delete from '' + @currentDataTemplateTable + '' WITH(NOLOCK) where crmxRecordId = @crmxRecordId''
   EXECUTE sp_executesql  @sql, @parameterDefinition,@serviceSource=@serviceSource,@crmxRecordId=@crmxRecordId
   SELECT 1
   EXEC(@SQL)
 END
  /* READ
   Template by ID
   */
else  IF @option = 16 BEGIN
    SELECT * FROM CRMxTemplates WITH(NOLOCK) WHERE id = @templateId
END

else  IF @option =17   BEGIN
    SET @currentDataTemplateTable = ''[dbo].[CRMxRawView'' + @templateIdString + '']''
    SET @sql=''select * from '' +@currentDataTemplateTable + '' WITH(NOLOCK)  where ''+ cast (@componentId as VARCHAR(MAX))+ '' like ''''%'' + cast (@dataValue as VARCHAR(MAX)) +''%'''';''
   exec( @sql)
END

  /* UPDATE
    Updates the specified row at CRMxRawDataN*/
else  IF @option = 18  BEGIN
    SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + @templateIdString + '']''
	set @parameterDefinition=''@crmxRecordId int,@tabSheetIndex int,@componentId varchar(100),@bindingType varchar(100),@dataValue varchar(max)''
    SET @SQL = ''IF exists(SELECT crmxRecordId FROM '' + @currentDataTemplateTable + ''
WITH(NOLOCK) WHERE [crmxRecordId] = @crmxRecordId AND [tabSheetIndex] = @tabSheetIndex AND [componentId] = @componentId) BEGIN
	UPDATE '' + @currentDataTemplateTable +''  WITH(ROWLOCK)
	SET [bindingType] = @bindingType,	[dataValue] = @dataValue
	WHERE [crmxRecordId] = @crmxRecordId AND [tabSheetIndex] = @tabSheetIndex AND [componentId] = @componentId 
END
ELSE BEGIN
	INSERT '' + @currentDataTemplateTable + '' VALUES(@crmxRecordId, @tabSheetIndex, @componentId, @bindingType,@dataValue)
END''
    EXECUTE sp_executesql  @sql, @parameterDefinition,@crmxRecordId=@crmxRecordId,@tabSheetIndex=@tabSheetIndex,@componentId=@componentId,@bindingType =@bindingType,@dataValue=@dataValue
END

else  IF @option=19 BEGIN
    SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + @templateIdString + '']''
	set @parameterDefinition=''@templateId int''
    SET @SQL= ''INSERT INTO ''+ @currentDataTemplateTable +''
       SELECT 0 as crmxRecordId,
         crmxtabsheets.tabSheetIndex as tabSheetIndex,
         tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') AS componentId,
         0 as bindingType, '''''''' as dataValue
       FROM crmxtabsheets WITH(NOLOCK)
       CROSS APPLY crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
       WHERE templateid=@templateId and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') IS NOT NULL
       and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') not like ''''label%''''''
    EXECUTE sp_executesql  @sql, @parameterDefinition,@templateId=@templateId

    EXEC GetCRMInfo @action = 3, @crmTemplateId =  @templateId
    EXEC GetCRMInfo @action = 8, @crmTemplateId =  @templateId
    SET @SQL=''delete from ''+@currentDataTemplateTable +'' where crmxRecordId=0''
    EXEC(@SQL)
END

   /* INSERT
    Insert new row at CRMxDataN*/
else IF @option =20   BEGIN
	IF @templateId IS NOT NULL  BEGIN
		set @parameterDefinition=''@serviceSource varchar(50),@dataKeyValue varchar(100),@destinySourceValue varchar(max)''
		SET @currentDataTemplateTable = ''CRMxData'' + @templateIdString
		if @destinySourceValue is null set @destinySourceValue=''''
		IF exists(SELECT * FROM SYS.TABLES WHERE [NAME] = @currentDataTemplateTable) BEGIN
			SET @SQL = ''INSERT INTO '' + @currentDataTemplateTable + '' (serviceSource, dataKeyValue, destinySourceValue,hasBeenLogicDeleted)      
VALUES (@serviceSource,@dataKeyValue,@destinySourceValue,@destinySourceValue,0)      
       SELECT SCOPE_IDENTITY() AS CRMxRecord_Id_Result''
       EXECUTE sp_executesql  @sql, @parameterDefinition,@serviceSource=@serviceSource,@dataKeyValue=@dataKeyValue,@destinySourceValue=@destinySourceValue
    END
  END
END

else if @option=21 begin

  declare @xml xml  
  declare @countTabSheet int
  declare @i int
  declare @tab table(tabsheetindex int, id varchar(max),relationId varchar(max))
  set @i=0

  select @countTabSheet=count(*) from CRMxTabSheets where [templateId]= @templateId

  while @i <@countTabSheet begin

    declare @ids varchar(max)   
    declare @RelationIds varchar(max)

    set @ids =''''
    set @RelationIds=''''

    SELECT @xml =tabSheetXml  FROM CRMxTabSheets WITH(NOLOCK) 
    WHERE [templateId] = @templateId  and tabSheetIndex =@i 
      
    insert into @tab
    select @i, Tbl.textInput.value(''(./@id)[1]'', ''varchar(max)''), 
     Tbl.textInput.value(''(./@relationGroup)[1]'', ''varchar(max)'')    
    from   @xml.nodes(''//tabSheet/textInput'') as Tbl(textInput)
    where Tbl.textInput.value(''(./@relationGroup)[1]'', ''varchar(max)'')<>''''  
  
    set @i=@i+1
  end
  select * from @tab
end

END'
    EXEC(@Sql)


     set @process = 'CW-2495 -- Alter SP saveMyCRMxRecord'
	set @Sql= 'ALTER PROCEDURE [dbo].[saveMyCRMxRecord]  
@crmxRecord XML,  
@crmxCallData varchar(max) = null  
AS  BEGIN  
    
    SET NOCOUNT ON;  
  
    IF @crmxRecord IS NULL  
     SELECT -9991  
  
    DECLARE @templateID INT,  
      @dataTName NVARCHAR(50),  
      @rawDTName NVARCHAR(50),  
      @crmxRecId INT,  
      @sql NVARCHAR(MAX),
	  @parameterDefinition nvarchar(200)
  
    create TABLE #tempTable(  
       tabSheetIndex INT not NULL,  
       componentId VARCHAR(100) NOT NULL,         
       dataValue VARCHAR(2000) Not NULL,
	   primary key( tabSheetIndex, componentId)
    )  
  
    DECLARE @compTable TABLE (
	componentId varchar(100) NOT NULL,
	 primary key( componentId))  
      
    SELECT @templateID = @crmxRecord.value(''(/Template/@id)[1]'',''INT'')  
    SELECT @crmxRecID = @crmxRecord.value(''(/Template/crmxRecord/@id)[1]'',''INT'')  
  
  
    INSERT @compTable  
     SELECT tabsheet.comp.value(''(@id)'',''varchar(max)'') AS ''componentId''  FROM crmxtabsheets WITH(NOLOCK)  
     CROSS APPLY crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)  
     WHERE templateid = @templateID and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') IS NOT NULL       
  
    SET @dataTName = N''CRMxData'' + CAST(@templateID AS NVARCHAR(10))  
    SET @rawDTName = N''CRMxRawData'' + CAST(@templateID AS NVARCHAR(10))  
  
    -- Pre-save the obtained xml data unto table form  
    INSERT #tempTable  
     SELECT tabSheet.value(''@index'', ''INT'') AS tabSheetIndex,  
        component.value(''@id'', ''NVARCHAR(100)'') AS componentId,  
        component.value(''@value'', ''NVARCHAR(2000)'') AS dataValue  
     FROM  @crmxRecord.nodes(''Template/tabSheets/tabSheet'') AS TabSheets(tabSheet)  
     OUTER APPLY TabSheets.tabSheet.nodes(''node()'') AS Components(component)  
     WHERE component.value(''@id'', ''NVARCHAR(100)'') IN (SELECT componentId FROM @compTable)  
  	
	set @parameterDefinition =N''@crmxRecID int,@crmxCallData varchar(max)''
	set @sql=''update A set A.dataValue=B.dataValue from [dbo].[''+@rawDTName+''] A 
	left join #tempTable B on B.componentId=A.componentId and B.tabSheetIndex=A.tabSheetIndex
	where A.crmxRecordId=@crmxRecId and B.componentId is not null	
	
	insert into [''+@rawDTName+''] 
	select  @crmxRecID as crmxRecordId,A.tabSheetIndex,A.componentId,''''none'''' as bindingType,A.dataValue
	 from  #tempTable A 
	left join [dbo].[''+@rawDTName+'']B on B.componentId=A.componentId and B.tabSheetIndex=A.tabSheetIndex and B.crmxRecordId=@crmxRecId
	where B.componentId is null

	UPDATE ['' + @dataTName + ''] WITH(ROWLOCK) SET [dateValue] = GETDATE(),calldata=@crmxCallData WHERE [crmxRecordId] = @crmxRecId''
          
    EXECUTE sp_executesql  @sql, @parameterDefinition, @crmxRecId=@crmxRecId,@crmxCallData=@crmxCallData
	--print(@sql)
  
	drop table #tempTable
END'
    EXEC(@Sql)




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


