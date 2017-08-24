/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2016/01/05
Description: CWX-CW_CRMx
********************************************************************************************

	 Se modifica el SP CRMxAgent


Database: CW_CRMx
Required version: 5

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it

*/

SET NOCOUNT ON

DECLARE @VERSION INT
DECLARE @ACTUALVERSION INT
DECLARE @SQL VARCHAR(MAX)
DECLARE @ERRORGENERATED VARCHAR(MAX)
DECLARE @PROCESS VARCHAR(MAX)

/* VERSION TO RELEASE (USE THE VERSION OF YOUR OWN DATABSE)*/
SET @VERSION = 6

/* ACTUAL VERSION (USE YOUR OWN SCRIPT TO DO IT) */
SET @ACTUALVERSION =  (SELECT VALUE FROM SETTINGS WHERE ID = 1)

IF @ACTUALVERSION = @VERSION - 1
	BEGIN
		BEGIN TRAN
		BEGIN TRY

	/* START SCRIPT RELEASE */

		set @process = 'validate if exists procedure [dbo].[saveMyCRMxRecord]'
    set @Sql= 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''saveMyCRMxRecord'') DROP PROCEDURE saveMyCRMxRecord'
    EXEC(@sql)

    set @process = 'create PROCEDURE [dbo].[saveMyCRMxRecord]'
    set @Sql= 'create PROCEDURE [dbo].[saveMyCRMxRecord]  
    @crmxRecord XML,  
    @crmxCallData varchar(max) = null  
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
     SELECT  @crmxRecID AS CRI,  
        tabSheet.value(''@index'', ''INT'') AS TSI,  
        component.value(''@id'', ''NVARCHAR(100)'') AS CID,  
        ''none'' AS BT,  
        component.value(''@value'', ''NVARCHAR(2000)'') AS DV  
     FROM  @crmxRecord.nodes(''Template/tabSheets/tabSheet'') AS TabSheets(tabSheet)  
     OUTER APPLY TabSheets.tabSheet.nodes(''node()'') AS Components(component)  
     WHERE component.value(''@id'', ''NVARCHAR(100)'') IN (SELECT componentId FROM @compTable)  
  
    OPEN cRunner  
    FETCH cRunner INTO @CRI, @TIX, @CID, @BT, @DV  
  
    EXEC [dbo].[CRMxAgent] @option = 18,  
          @templateId = @templateId,  
          @crmxRecordID = @CRI,  
          @tabSheetIndex = @TIX,  
          @componentId = @CID,  
          @bindingType = @BT,  
          @dataValue = @DV  
  
    WHILE(@@FETCH_STATUS = 0)  
     BEGIN  
      FETCH cRunner INTO @CRI, @TIX, @CID, @BT, @DV  
      EXEC [dbo].[CRMxAgent] @option = 18,  
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
    if exists(SELECT top 1 * FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = ''callData'' AND TABLE_NAME = @dataTName)  
     SET @SQL = ''UPDATE ['' + @dataTName + ''] WITH(ROWLOCK) SET [dateValue] = GETDATE(), callData=convert(xml,'''''' + @crmxCallData + '''''') WHERE [crmxRecordId] = '' + CAST(@crmxRecID AS NVARCHAR(10))  
    else  
     SET @SQL = ''UPDATE ['' + @dataTName + ''] WITH(ROWLOCK) SET [dateValue] = GETDATE() WHERE [crmxRecordId] = '' + CAST(@crmxRecID AS NVARCHAR(10))  
    EXEC(@SQL)  
  
   END'
    EXEC(@sql)



    set @process = 'ALTER SP -- CRMxAgent'
    set @Sql= 'ALTER PROCEDURE [dbo].[CRMxAgent]
 -- Add the parameters for the stored procedure here
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


DECLARE @SQL VARCHAR(MAX)
DECLARE @currentDataTemplateTable VARCHAR(100)
DECLARE @searchPattern VARCHAR(MAX)


BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

    -- Insert statements for procedure here


 /* READ

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
  IF  @dnis<>0
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
     IF (
     SELECT COUNT([id])
     FROM CRMxTemplates WITH(NOLOCK)
     WHERE [servicesType]
     LIKE '' + '''''''' + ''%'' + @servicesType + ''%'' + '''''''' + ''
     AND servicesRelation.exist('' + '''''''' + ''/servicesRelation/call/ACD[@id='' + CAST(@callTypeId AS VARCHAR(50)) + '']'' + '''''''' + '') = 1
     AND [hasBeenLogicDeleted] = 0
     ) = 1
     BEGIN
      SELECT * FROM CRMxTemplates WITH(NOLOCK)
      WHERE [servicesType]  LIKE '' + '''''''' + ''%'' + @servicesType + ''%'' + '''''''' + ''
      AND servicesRelation.exist('' + '''''''' + ''/servicesRelation/call/ACD[@id='' + CAST(@callTypeId AS VARCHAR(50)) + '']'' + '''''''' + '') = 1
      AND [hasBeenLogicDeleted] = 0
     END
     ELSE
     BEGIN
      SELECT N''+''''''''+''-1.2''+''''''''+''
     END
    END''
   END
  ELSE
   BEGIN
      SET @SQL = ''IF (
    SELECT COUNT([id])
    FROM CRMxTemplates WITH(NOLOCK)
    WHERE [servicesType]
    LIKE '' + '''''''' + ''%'' + @servicesType + ''%'' + '''''''' + ''
    AND servicesRelation.exist('' + '''''''' + ''/servicesRelation/call/ACD[@id='' + CAST(@callTypeId AS VARCHAR(50)) + '']'' + '''''''' + '') = 1
    AND [hasBeenLogicDeleted] = 0
    ) = 1
    BEGIN
     SELECT * FROM CRMxTemplates WITH(NOLOCK)
     WHERE [servicesType]  LIKE '' + '''''''' + ''%'' + @servicesType + ''%'' + '''''''' + ''
     AND servicesRelation.exist('' + '''''''' + ''/servicesRelation/call/ACD[@id='' + CAST(@callTypeId AS VARCHAR(50)) + '']'' + '''''''' + '') = 1
     AND [hasBeenLogicDeleted] = 0
    END
    ELSE
    BEGIN
     SELECT N''+''''''''+''-1.2''+''''''''+''
    END''
   END
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
 else IF @option=3  BEGIN
  IF @templateId IS NOT NULL  BEGIN
    SET @currentDataTemplateTable = ''CRMxData'' + CAST(@templateId AS VARCHAR(100))
    IF exists(SELECT * FROM SYS.TABLES WHERE [NAME] = @currentDataTemplateTable)    BEGIN
      SET @SQL = ''SELECT TOP 1 * FROM [dbo].['' + @currentDataTemplateTable + ''] WITH(NOLOCK)''

     IF @dataKeyValue IS NOT NULL SET @SQL = @SQL + '' WHERE [dataKeyValue]='' + '''''''' +  @dataKeyValue + ''''''''
       ELSE SET @SQL = @SQL + '' WHERE [destinySourceValue]='' + '''''''' +  @destinySourceValue + ''''''''

       SET @SQL = @SQL + '' AND [hasBeenLogicDeleted] = 0  ''-- AND [serviceSource] LIKE '' + '''''''' + ''%'' + @serviceSource + ''%'' + '''''''' + ''
       +'' ORDER BY [dateValue] DESC''

       --PRINT(@SQL)
       EXEC(@SQL)
      END
     ELSE SELECT N''-3.1''

   END
   ELSE SELECT N''-3.2''
   return (0);
END




 /* READ

  @ CRMxRawData''N''

  Gets the CRMxRecord components using the crmxRecordId
 */
 else IF @option=4   BEGIN
   IF @templateId IS NOT NULL  BEGIN
     SET @currentDataTemplateTable = ''[dbo].[CRMxRawData'' + CAST(@templateId AS VARCHAR(100)) + '']''
     SET @SQL = ''SELECT * FROM '' + @currentDataTemplateTable  + '' WITH(NOLOCK)
     WHERE [crmxRecordId]='' + CAST(@crmxRecordId AS VARCHAR(MAX))  + ''
     ORDER BY [tabSheetIndex] ASC, [componentId] ASC''

     --PRINT(@SQL)
     EXEC(@SQL)
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
    [callData] [xml] NULL,
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
    where templateid=@templateId and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') is not null      and tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') = ''true'' and tabsheet.comp.value(''(@id)'',''varchar(max)'') = @componentId

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



 /* CREATE / UPDATE

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
       SET [bindingType] = '' + '''''''' +  CAST(@bindingType AS VARCHAR(100)) + '''''''' + '',
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
    SET @SQL= ''INSERT INTO ''+ @currentDataTemplateTable +''
       SELECT 0 as crmxRecordId,
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
    EXEC(@Sql)




	/* END SCRIPT RELEASE */

		/* UPGRADE DATABASE VERSION (USE YOUR OWN SCRIPT TO DO IT) */
		--UPDATE SETTINGS SET VALUE = @VERSION WHERE ID = 1

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


