CREATE PROCEDURE [dbo].[CRMxAgent] 
@option INT = 0,    -- Type of Action/proceess to perform
@serviceType VARCHAR(50) = NULL,  -- Type of invoker service
@servicesType VARCHAR(50) = NULL,  -- Type of service associated, catalog
@serviceSource VARCHAR(50) = NULL,  -- The invoker serviceSource
@callType INT = NULL,     -- Call Type, ACD or CAMP
@callTypeId INT= NULL,     -- Call identifier, camp #1 or acd#2
@dnis BIGINT = NULL,       -- Dnis, i.e. 2099
@templateId INT = NULL,     -- Template id's
@tabSheetIndex INT = NULL,    -- TabSheet id's
@componentId VARCHAR(100) = NULL,  -- Component id's
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
declare @id bigint

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
  IF @serviceType LIKE 'call%' BEGIN-- CALL    
    set @parameterDefinition='@id bigint,@servicesType varchar(50),@dnis bigint,@callTypeId INT'     
    IF @callType = 0 BEGIN -- CALL::Campaign 
      set @id = @callTypeId
      set @sql='IF exists(SELECT id FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''%''+@servicesType+''%'' and [hasBeenLogicDeleted] = 0
  AND servicesRelation.exist(''/servicesRelation/call/Campaign[@id=sql:variable("@id")]'') = 1 )
BEGIN
  SELECT * FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''%''+@servicesType+''%'' and [hasBeenLogicDeleted] = 0
  AND servicesRelation.exist(''/servicesRelation/call/Campaign[@id=sql:variable("@id")]'') = 1
END
ELSE BEGIN
  SELECT -1.1
END'   
    END
    ELSE IF @dnis<>0 BEGIN-- CALL::ACD           
      set @id = @dnis
      set @sql='IF exists(SELECT id FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''%''+@servicesType+''%'' and [hasBeenLogicDeleted] = 0
  AND servicesRelation.exist(''/servicesRelation/call/ACD[@dnis=sql:variable("@dnis")]'') = 1 )
BEGIN
  SELECT * FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''%''+@servicesType+''%'' and [hasBeenLogicDeleted] = 0
  AND servicesRelation.exist(''/servicesRelation/call/ACD[@dnis=sql:variable("@dnis")]'') = 1
  AND servicesRelation.exist(''/servicesRelation/call/ACD[@id=sql:variable("@callTypeId")]'') = 1
END
ELSE IF exists(SELECT id FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''%''+@servicesType+''%'' and [hasBeenLogicDeleted] = 0
  AND servicesRelation.exist(''/servicesRelation/call/ACD[@id=sql:variable("@id")]'') = 1 )
BEGIN
  SELECT * FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''%''+@servicesType+''%'' and [hasBeenLogicDeleted] = 0
  AND servicesRelation.exist(''/servicesRelation/call/ACD[@id=sql:variable("@id")]'') = 1
END
ELSE BEGIN
  SELECT -1.2
END'   
    end   
    ELSE BEGIN
      set @id = @callTypeId
      set @sql='IF exists(SELECT id FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''%''+@servicesType+''%'' and [hasBeenLogicDeleted] = 0
  AND servicesRelation.exist(''/servicesRelation/call/ACD[@id=sql:variable("@id")]'') = 1 )
BEGIN
  SELECT * FROM CRMxTemplates WITH(NOLOCK) WHERE [servicesType] like ''%''+@servicesType+''%'' and [hasBeenLogicDeleted] = 0
  AND servicesRelation.exist(''/servicesRelation/call/ACD[@id=sql:variable("@id")]'') = 1
END
ELSE BEGIN
  SELECT -1.2
END'   
    END   
  EXECUTE sp_executesql  @sql, @parameterDefinition,@servicesType=@servicesType,@id=@id,@dnis=@dnis,@callTypeId=@callTypeId
  print(@sql)
  END
END ---- @option = 1
 /* READ

  @CRMxTabSheets

  Gets the TabSheets associated to 'X' templateId
 */
 else IF @option = 2 BEGIN
   if not exists (SELECT [templateId] FROM CRMxTabSheets WITH(NOLOCK) WHERE [templateId] = @templateId) begin -- NO TEMPLATE HAS VALID DATA    
    SELECT N'-2.1'
  END
   ELSE BEGIN
    SELECT * FROM CRMxTabSheets WITH(NOLOCK) WHERE [templateId] = @templateId ORDER BY [tabSheetIndex] ASC
  END
 END ---- @option = 2

 /* READ
  @ CRMxData'N'
  Gets the CRMxRecord that best matches
 */
 else IF @option=3  BEGIN
  IF @templateId IS NOT NULL  BEGIN
    SET @currentDataTemplateTable = 'CRMxData' + @templateIdString
    set @parameterDefinition='@dataKeyValue varchar(max),@destinySourceValue varchar(max)'
    IF exists(SELECT * FROM SYS.TABLES WHERE [NAME] = @currentDataTemplateTable) BEGIN
      SET @SQL = 'SELECT TOP 1 * FROM [dbo].[' + @currentDataTemplateTable + '] WITH(NOLOCK)'

      IF @dataKeyValue IS NOT NULL SET @SQL = @SQL + ' WHERE [dataKeyValue]= @dataKeyValue '
      ELSE SET @SQL = @SQL + ' WHERE [destinySourceValue]= @destinySourceValue'

      SET @SQL = @SQL + ' AND [hasBeenLogicDeleted] = 0 ORDER BY [dateValue] DESC'       
      EXECUTE sp_executesql  @sql, @parameterDefinition,@dataKeyValue=@dataKeyValue,@destinySourceValue=@destinySourceValue
    END
    ELSE SELECT N'-3.1'
  END
   ELSE SELECT N'-3.2'
   return (0);
END ---- @option = 3

 /* READ
  @ CRMxRawData'N'
  Gets the CRMxRecord components using the crmxRecordId
 */
 else IF @option=4   BEGIN
   IF @templateId IS NOT NULL  BEGIN
     set @parameterDefinition='@crmxRecordId int'
     SET @currentDataTemplateTable = '[dbo].[CRMxRawData' + @templateIdString + ']'
     SET @SQL = 'SELECT * FROM ' + @currentDataTemplateTable  + ' WITH(NOLOCK)
     WHERE [crmxRecordId]=@crmxRecordId
     ORDER BY [tabSheetIndex] ASC, [componentId] ASC'     
     EXECUTE sp_executesql  @sql, @parameterDefinition,@crmxRecordId=@crmxRecordId
   END
   ELSE SELECT N'-4.1'
  return 0;
END
 /*CREATE
  CRMxData'N'
  CRMxRawData'N'
  The CRMxData'n' and CRMxRawData tables if not created yet,
  and sets to true(1) the hasSavedData property over the CRMxTemplates row relation
  */
 else IF @option = 5 BEGIN
   IF exists (SELECT [hasSavedData] FROM CRMxTemplates WITH(ROWLOCK) WHERE [id] = @templateId) BEGIN
     UPDATE CRMxTemplates WITH(ROWLOCK) SET [hasSavedData] = 1  WHERE [id] = @templateId
   END
   SET @currentDataTemplateTable = 'CRMxData' + @templateIdString

   IF not exists(SELECT name FROM SYS.TABLES WHERE [NAME] = @currentDataTemplateTable)  BEGIN
     SET @SQL = 'CREATE TABLE [dbo].[' +  @currentDataTemplateTable + ']  (
      [crmxRecordId] [int] IDENTITY(1,1) NOT NULL,
      [serviceSource] [varchar](50) NULL,
      [dataKeyValue] [varchar](100) NULL,
      [destinySourceValue] [varchar](100) NULL,
      [dateValue] [datetime] NOT NULL,
      [hasBeenLogicDeleted] [bit] NOT NULL,
    [callData] [xml] NULL,
     CONSTRAINT [PK_'+@currentDataTemplateTable+'] PRIMARY KEY CLUSTERED
     (
      [crmxRecordId] ASC
     )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
     )' +
     'ALTER TABLE ' + @currentDataTemplateTable +
     ' ADD CONSTRAINT [DF_CRMxData' + @templateIdString +
     '_dateValue] DEFAULT (GETDATE()) FOR [dateValue]

     CREATE NONCLUSTERED INDEX [IX_'+@currentDataTemplateTable+'_1] ON [dbo].['+@currentDataTemplateTable+']
     (
      [serviceSource] ASC,
      [dataKeyValue] DESC,
      [hasBeenLogicDeleted] ASC
     )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

     SET ANSI_PADDING ON

     CREATE NONCLUSTERED INDEX [IX_'+@currentDataTemplateTable+'_2] ON [dbo].['+@currentDataTemplateTable+']
     (
      [serviceSource] ASC,
      [destinySourceValue] ASC,
      [hasBeenLogicDeleted] ASC
     )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

     SET ANSI_PADDING ON

     CREATE NONCLUSTERED INDEX [IX_'+@currentDataTemplateTable+'_3] ON [dbo].['+@currentDataTemplateTable+']
     (
      [dataKeyValue] ASC
     )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

     SET ANSI_PADDING ON '

    -- PRINT(@SQL)
     EXEC(@SQL)
  END

   SET @currentDataTemplateTable = 'CRMxRawData' + @templateIdString
   IF not exists(SELECT [NAME] FROM SYS.TABLES WHERE [NAME] = @currentDataTemplateTable) BEGIN
     SET @SQL = 'CREATE TABLE  [dbo].[' +  @currentDataTemplateTable + ']
      (
       [crmxRecordId] [int] NOT NULL,
       [tabSheetIndex] [int] NULL,
       [componentId] [varchar](100),
       [bindingType] [varchar](100) NULL,
       [dataValue] [varchar](max),
     CONSTRAINT [PK_'+@currentDataTemplateTable+'] PRIMARY KEY CLUSTERED
     (
      [crmxRecordId] ASC,
      [componentId] ASC
     )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

     ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

    CREATE NONCLUSTERED INDEX [IX_'+@currentDataTemplateTable+'_1] ON [dbo].['+@currentDataTemplateTable+']
     (
      [crmxRecordId] ASC,
      [tabSheetIndex] ASC,
      [componentId] ASC
     )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

     SET ANSI_PADDING ON

     CREATE NONCLUSTERED INDEX [IX_'+@currentDataTemplateTable+'_2] ON [dbo].['+@currentDataTemplateTable+']
     (
      [tabSheetIndex] ASC,
      [componentId] ASC
     )

     ALTER TABLE [dbo].['+@currentDataTemplateTable+'] ADD  CONSTRAINT [DF__CRMxRawDa__dataV_'+@templateIdString+']  DEFAULT ('' '') FOR [dataValue]'
    EXEC(@SQL)

    exec [CRMxAgent] @option=19, @templateId=@templateId
    END

   SELECT [id], [hasSavedData] FROM CRMxTemplates WITH(NOLOCK) WHERE [id] = @templateId
END
 /*CREATE
  Records
  CRMxData'N'
  CRMxRawData'N'
  The CRMxData'N' and CRMxRawData'N' tables if not created yet,
  and sets to true(1) the hasSavedData property over the CRMxTemplates row relation
  */
 else IF @option = 6 BEGIN
   IF @templateId IS NOT NULL BEGIN
     SET @currentDataTemplateTable = '[dbo].[CRMxData' + @templateIdString + ']'

   set @parameterDefinition='@dataKeyValue varchar(max),@destinySourceValue varchar(max),@crmxRecordId int,@serviceSource VARCHAR(50)'
     SET @SQL = 'IF EXISTS( SELECT [crmxRecordId] FROM ' + @currentDataTemplateTable + ' WITH(NOLOCK)
WHERE [crmxRecordId] = @crmxRecordId) BEGIN
  UPDATE ' + @currentDataTemplateTable + ' WITH(ROWLOCK)
    SET [dateValue] = GETDATE(), [dataKeyValue] = @dataKeyValue, [destinySourceValue]=@destinySourceValue
    WHERE [crmxRecordId] = @crmxRecordId
  
  SELECT [crmxRecordId] AS [CRMxRecord_Id_Result] FROM ' + @currentDataTemplateTable + ' WITH(NOLOCK)
    WHERE [dataKeyValue] = @dataKeyValue
END
  ELSE BEGIN
       INSERT INTO ' + @currentDataTemplateTable + ' (serviceSource, dataKeyValue, destinySourceValue, hasBeenLogicDeleted)
       VALUES (@serviceSource , @dataKeyValue , @destinySourceValue , 0 )
       SELECT SCOPE_IDENTITY() AS [CRMxRecord_Id_Result]
END'
    EXECUTE sp_executesql  @sql, @parameterDefinition,@dataKeyValue =@dataKeyValue,@serviceSource =@serviceSource,@destinySourceValue=@destinySourceValue,@crmxRecordId=@crmxRecordId
  END
END
 /* DELETE
  CRMxRecordId CRMxRawData'N'
  Obliterate*/
 else IF @option = 7 BEGIN
   IF @templateId IS NOT NULL BEGIN
   set @parameterDefinition='@crmxRecordId int'
     SET @currentDataTemplateTable = '[dbo].[CRMxRawData' + @templateIdString + ']'

     SET @SQL = 'DELETE ' + @currentDataTemplateTable +'  WITH(NOLOCK) WHERE [crmxRecordId] = @crmxRecordId

     SELECT COUNT ([crmxRecordId]) FROM ' + @currentDataTemplateTable + '  WITH(NOLOCK) WHERE [crmxRecordId] = @crmxRecordId'     
     EXECUTE sp_executesql  @sql, @parameterDefinition, @crmxRecordId=@crmxRecordId
  END
END
 /*CREATE
  CRMxData'N'
  CRMxRawData'N'
  The CRMxData'n' and CRMxRawData tables if not created yet,
  and sets to true(1) the hasSavedData property over the CRMxTemplates row relation
*/
else IF @option = 8 BEGIN
  IF @templateId IS NOT NULL BEGIN    
    SET @currentDataTemplateTable = '[dbo].[CRMxRawData' + @templateIdString + ']'
    
    set @parameterDefinition='@crmxRecordId int,@tabSheetIndex int,@componentId varchar(100),@bindingType varchar(100),@dataValue varchar(max)'
    SET @SQL = 'IF EXISTS( SELECT [crmxRecordId] FROM ' + @currentDataTemplateTable + '  WITH(NOLOCK)
WHERE [crmxRecordId] = @crmxRecordId AND [tabSheetIndex] = @tabSheetIndex AND [componentId] = @componentId)  BEGIN
  UPDATE ' + @currentDataTemplateTable + '  WITH(ROWLOCK) SET [bindingType] = @bindingType , [dataValue] = @dataValue 
    WHERE [crmxRecordId] = @crmxRecordId AND [tabSheetIndex] = @tabSheetIndex AND [componentId] = @componentId
END
  ELSE BEGIN
       INSERT INTO ' + @currentDataTemplateTable + ' (crmxRecordId, tabSheetIndex, componentId, bindingType, dataValue)
       VALUES (@crmxRecordId ,@tabSheetIndex,@componentId,@bindingType,@dataValue)
   END

SELECT TOP 1 [crmxRecordId] FROM ' + @currentDataTemplateTable + ' WITH(NOLOCK)
WHERE [crmxRecordId] = @crmxRecordId AND [tabSheetIndex] = @tabSheetIndex AND [componentId] = @componentId'
     
    EXECUTE sp_executesql  @sql, @parameterDefinition,@crmxRecordId=@crmxRecordId,@tabSheetIndex =@tabSheetIndex,@componentId=@componentId,
    @bindingType=@bindingType,@dataValue=@dataValue
    END
END
 /* READ
  @ CRMxRawData'N'
  Gets the likelable CRMxRecord components that matches over dataValues
 */
else IF @option = 9 BEGIN
   IF @templateId IS NOT NULL BEGIN
     SET @currentDataTemplateTable = '[dbo].[CRMxRawData' + @templateIdString + ']'
   set @parameterDefinition='@tabSheetIndex int,@componentId varchar(100),@dataValue varchar(max)'

     SET @SQL = 'SELECT TOP 51 * FROM ' + @currentDataTemplateTable  + ' WITH(NOLOCK)
   WHERE [componentId] = @componentId AND [tabSheetIndex] = @tabSheetIndex AND [dataValue] LIKE ''%''@datavalue''%''
     ORDER BY [crmxRecordId] ASC, [tabSheetIndex] ASC, [componentId] ASC'
     
     EXECUTE sp_executesql  @sql, @parameterDefinition,@tabSheetIndex =@tabSheetIndex,@componentId=@componentId,@dataValue=@dataValue
  END
  ELSE SELECT N'-9.1'
END
 /* READ
  @ CRMxData'N'
  Gets the crmxRecord using the crmxRecordId
 */
 else IF @option = 10 BEGIN
  IF @templateId IS NOT NULL    BEGIN
    SET @currentDataTemplateTable = '[dbo].[CRMxData' + @templateIdString + ']'
    set @parameterDefinition='@crmxRecordId int'
    SET @SQL = 'SELECT * FROM ' + @currentDataTemplateTable  + ' WITH(NOLOCK) WHERE [crmxRecordId] = @crmxRecordId'     
    EXECUTE sp_executesql  @sql, @parameterDefinition,@crmxRecordId=@crmxRecordId
  END
   ELSE SELECT N'-10.1'
END

else IF @option = 11 BEGIN--Update/insert values into CRMxView
   declare @componentColumn nvarchar(max)
   select @componentColumn= tabsheet.comp.value('(@headerIndex)','varchar(max)') from crmxtabsheets WITH(NOLOCK)
   cross apply crmxtabsheets.tabsheetxml.nodes('/tabSheet/*')  tabsheet(comp)
   where templateid=@templateId and tabsheet.comp.value('(@id)','varchar(max)') is not null 
   AND tabsheet.comp.value('(@reportable)', 'varchar(max)') is not null
   and tabsheet.comp.value('(@reportable)', 'varchar(max)') = 'true' and tabsheet.comp.value('(@id)','varchar(max)') = @componentId
   
   set @parameterDefinition='@destinySourceValue varchar(max),@dateValue datetime, @crmxRecordId int,@templateID  int'

   IF EXISTS (SELECT TOP 1 * FROM CRMxView WITH(NOLOCK) where recordId=@crmxRecordId AND templateId=@templateID) BEGIN --Update     
  set @sql= 'update [dbo].[CRMxView] WITH(ROWLOCK) set source = @destinySourceValue, date = @dateValue, data' + @componentColumn +' = @dataValue 
  WHERE recordId = @crmxRecordId and templateId = @templateID '    
   END
   ELSE  BEGIN--Insert    
     set @sql= 'INSERT INTO CRMxVIew ([recordId],[templateId],[date],[source],[data'+ @componentColumn +']) 
   SELECT crmxRecordId as recordId, @templateId as templateId, dateValue as date, destinySourceValue as source, @dataValue data'+ @componentColumn +'
     from [dbo].[CRMxData'+ CAST(@templateId as varchar(max)) +'] where crmxRecordId =@crmxRecordId '          
    END
  EXECUTE sp_executesql  @sql, @parameterDefinition,@destinySourceValue =@destinySourceValue,@dataValue=@dataValue,@crmxRecordId=@crmxRecordId,@templateID=@templateID 
  select 1
END
 /* CREATE / UPDATE
  @CRMxRawData'N'
  Creates the record component value if it does not exists, else update it
 */
else IF @option = 12 BEGIN
   IF @templateId IS NOT NULL BEGIN   
    SET @currentDataTemplateTable = '[dbo].[CRMxRawData' + @templateIdString + ']'
    set @parameterDefinition='@crmxRecordId int, @tabSheetIndex int,@componentId varchar(100),@bindingType varchar(100),@dataValue varchar(max)'
    SET @SQL = 'IF exists( SELECT crmxRecordId FROM ' + @currentDataTemplateTable + ' WITH(NOLOCK)
  WHERE crmxRecordId = @crmxRecordId AND tabSheetIndex = @tabSheetIndex AND componentId = @componentId) BEGIN
  UPDATE ' + @currentDataTemplateTable + ' WITH(ROWLOCK) SET bindingType = @bindingType, dataValue = @dataValue
  WHERE crmxRecordId = @crmxRecordId AND tabSheetIndex = @tabSheetIndex AND componentId = @componentId
END
ELSE BEGIN
       INSERT INTO ' + @currentDataTemplateTable + '(crmxRecordId, tabSheetIndex, componentId, bindingType, dataValue)
       VALUES (@crmxRecordId,@tabSheetIndex, @componentId, @bindingType, @dataValue)
END
SELECT 1'     
     EXECUTE sp_executesql  @sql, @parameterDefinition,@crmxRecordId=@crmxRecordId,@tabSheetIndex=@tabSheetIndex,@componentId=@componentId,@bindingType=@bindingType,@dataValue=@dataValue 
    END
END
  /*
   Check if the dataKeyValue already exists
  */

else  IF @option = 13 BEGIN
   SET @currentDataTemplateTable = '[dbo].[CRMxData' + @templateIdString + ']'
   set @parameterDefinition='@dataKeyValue varchar(max)'
   SET @SQL = 'SELECT COUNT(DISTINCT([dataKeyValue])) AS [CheckNorris] FROM ' + @currentDataTemplateTable
   + ' WITH(NOLOCK) WHERE [dataKeyValue] = @dataKeyValue'
   EXECUTE sp_executesql  @sql, @parameterDefinition,@dataKeyValue=@dataKeyValue
END
  /*
   Return a datakeyValue created by the templateID +  + crmxRecordId for inbound calls
  */
else IF @option=14  BEGIN
   SET @currentDataTemplateTable = '[dbo].[CRMxData' + CAST(@templateId  AS VARCHAR(100)) + ']'
   set @parameterDefinition='@serviceSource varchar(50),@destinySourceValue varchar(max)'
   SET @SQL ='DECLARE @ObjectID int
      BEGIN
      INSERT INTO ' + @currentDataTemplateTable + ' (serviceSource, destinySourceValue, hasBeenLogicDeleted)
       VALUES (@serviceSource,@destinySourceValue, 0 )
      SET @ObjectID = SCOPE_IDENTITY()
      UPDATE '+ @currentDataTemplateTable +' WITH(ROWLOCK) SET dataKeyValue = '''+CAST(@templateId  AS VARCHAR(100)) + ':' +''' + CAST(@ObjectID  AS VARCHAR(100))
      OUTPUT INSERTED.* where crmxRecordId = @ObjectID
      END'
   EXECUTE sp_executesql  @sql, @parameterDefinition,@serviceSource=@serviceSource,@destinySourceValue=@destinySourceValue
  END

  /*
   Delete record from CRMxData
  */

else  IF @option=15  BEGIN
   SET @currentDataTemplateTable = '[dbo].[CRMxData' + CAST(@templateId  AS VARCHAR(100)) + ']'
   set @parameterDefinition='@crmxRecordId int'
   SET @SQL ='Delete from ' + @currentDataTemplateTable + ' WITH(NOLOCK) where crmxRecordId = @crmxRecordId'
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
    SET @currentDataTemplateTable = '[dbo].[CRMxRawView' + @templateIdString + ']'
    SET @sql='select * from ' +@currentDataTemplateTable + ' WITH(NOLOCK)  where '+ cast (@componentId as VARCHAR(MAX))+ ' like ''%' + cast (@dataValue as VARCHAR(MAX)) +'%'';'
   exec( @sql)
END

  /* UPDATE
    Updates the specified row at CRMxRawDataN*/
else  IF @option = 18  BEGIN
    SET @currentDataTemplateTable = '[dbo].[CRMxRawData' + @templateIdString + ']'
  set @parameterDefinition='@crmxRecordId int,@tabSheetIndex int,@componentId varchar(100),@bindingType varchar(100),@dataValue varchar(max)'
    SET @SQL = 'IF exists(SELECT crmxRecordId FROM ' + @currentDataTemplateTable + '
WITH(NOLOCK) WHERE [crmxRecordId] = @crmxRecordId AND [tabSheetIndex] = @tabSheetIndex AND [componentId] = @componentId) BEGIN
  UPDATE ' + @currentDataTemplateTable +'  WITH(ROWLOCK)
  SET [bindingType] = @bindingType, [dataValue] = @dataValue
  WHERE [crmxRecordId] = @crmxRecordId AND [tabSheetIndex] = @tabSheetIndex AND [componentId] = @componentId 
END
ELSE BEGIN
  INSERT ' + @currentDataTemplateTable + ' VALUES(@crmxRecordId, @tabSheetIndex, @componentId, @bindingType,@dataValue)
END'
    EXECUTE sp_executesql  @sql, @parameterDefinition,@crmxRecordId=@crmxRecordId,@tabSheetIndex=@tabSheetIndex,@componentId=@componentId,@bindingType =@bindingType,@dataValue=@dataValue
END

else  IF @option=19 BEGIN
    SET @currentDataTemplateTable = '[dbo].[CRMxRawData' + @templateIdString + ']'
  set @parameterDefinition='@templateId int'
    SET @SQL= 'INSERT INTO '+ @currentDataTemplateTable +'
       SELECT 0 as crmxRecordId,
         crmxtabsheets.tabSheetIndex as tabSheetIndex,
         tabsheet.comp.value(''(@id)'',''varchar(max)'') AS componentId,
         0 as bindingType, '''' as dataValue
       FROM crmxtabsheets WITH(NOLOCK)
       CROSS APPLY crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)
       WHERE templateid=@templateId and tabsheet.comp.value(''(@id)'',''varchar(max)'') IS NOT NULL
       and tabsheet.comp.value(''(@id)'',''varchar(max)'') not like ''label%'''
    EXECUTE sp_executesql  @sql, @parameterDefinition,@templateId=@templateId

    EXEC GetCRMInfo @action = 3, @crmTemplateId =  @templateId
    EXEC GetCRMInfo @action = 8, @crmTemplateId =  @templateId
    SET @SQL='delete from '+@currentDataTemplateTable +' where crmxRecordId=0'
    EXEC(@SQL)
END

   /* INSERT
    Insert new row at CRMxDataN*/
else IF @option =20   BEGIN
  IF @templateId IS NOT NULL  BEGIN
    set @parameterDefinition='@serviceSource varchar(50),@dataKeyValue varchar(100),@destinySourceValue varchar(max)'
    SET @currentDataTemplateTable = 'CRMxData' + @templateIdString
    if @destinySourceValue is null set @destinySourceValue=''
    IF exists(SELECT * FROM SYS.TABLES WHERE [NAME] = @currentDataTemplateTable) BEGIN
      SET @SQL = '
INSERT INTO ' + @currentDataTemplateTable + ' (serviceSource, dataKeyValue, destinySourceValue,hasBeenLogicDeleted)      
                     VALUES (@serviceSource,@dataKeyValue,@destinySourceValue,0)      
       SELECT SCOPE_IDENTITY() AS CRMxRecord_Id_Result'
     print (@sql)
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

    set @ids =''
    set @RelationIds=''

    SELECT @xml =tabSheetXml  FROM CRMxTabSheets WITH(NOLOCK) 
    WHERE [templateId] = @templateId  and tabSheetIndex =@i 
      
    insert into @tab
    select @i, Tbl.textInput.value('(./@id)[1]', 'varchar(max)'), 
     Tbl.textInput.value('(./@relationGroup)[1]', 'varchar(max)')    
    from   @xml.nodes('//tabSheet/textInput') as Tbl(textInput)
    where Tbl.textInput.value('(./@relationGroup)[1]', 'varchar(max)')<>''  
  
    set @i=@i+1
  end
  select * from @tab
end

END