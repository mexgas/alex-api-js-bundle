/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2023/07/04
Description: K089000
Database: CCenterRia
Required version: 126
IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON
DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);
/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */--
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 15
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY
        -------------------------------------------------- Begin Isaac -----------------------------------------------------------------------------------


        SET @process = 'K020118 Editar plantillas para campañas de Whatsapp'
        SET @sql = '
            IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_MetaWAOutboundTemplates'')
            BEGIN
                DROP PROCEDURE ccsp_MetaWAOutboundTemplates;
            END'
        EXEC(@sql)

        SET @process = 'K020118 Editar plantillas para campañas de Whatsapp'
        SET @sql = '
            CREATE PROCEDURE ccsp_MetaWAOutboundTemplates
                @action TINYINT = NULL,
                @whatsAppTemplateID BIGINT = 0,
                @id varchar(200) = NULL,
                @Category varchar(50) = NULL,
                @TemplateName varchar(512) = NULL,
                @AllowCategoryChange tinyint = NULL,
                @LanguageCode varchar(10)= NULL,
                @Status varchar(200)= NULL, 
                @header nvarchar(max)= null,
                @body nvarchar(max) = null,
                @footer nvarchar(max) = null,
                @buttons nvarchar(max) = null,
                @metaStatus varchar(30) = NULL,
                @FilePath varchar(1024) = null,
                @HistoryLog varchar(max) = null,
                @campId SMALLINT = NULL,
                @UserId	SMALLINT = 0,
                @MetaId INT = 0
            AS
            BEGIN
                IF(@action = 1) -- get template by id
                BEGIN
                    SELECT 
                    cmwot.Id 
                    ,cmwot.TemplateName AS Name
                    ,cmwot.Status AS Status
                    ,Category AS Category
                    ,ISNULL(cmwot.notes, '''' ) AS Notes
                    ,cmwot.header AS Header
                    ,Body
                    ,cmwot.footer AS Footer
                    ,cmwot.buttons AS Buttons
                    ,cmwot.LanguageCode
                    ,ISNULL(cmwot.quality,0) AS Quality
                    ,cmwot.IsPendingQuality
                    ,cmwot.FilePath
                    ,cmwot.Status AS Status
                    FROM  dbo.ccMetaWAOutboundTemplates AS cmwot
                    WHERE cmwot.Id = @whatsAppTemplateID
                END
                ELSE IF(@action = 2)
                BEGIN
                    SELECT cmwan.MetaId AS Id, cmwan.Number FROM dbo.ccMetaWhatsAppNumbers AS cmwan
                    Left JOIN dbo.ccMetaWhatsAppConfigurations AS cmwac
                    ON cmwan.MetaId = cmwac.Id
                    WHERE cmwan.Status = 1
                END
                ELSE IF(@action = 3)
                BEGIN
                    UPDATE ccMetaWAOutboundTemplates SET StatusCW = 0 WHERE Id = @whatsAppTemplateID
                    SELECT @@ROWCOUNT;
                    RETURN 0;
                END
                ELSE IF(@action = 4) --create
                BEGIN
                    insert into ccMetaWAOutboundTemplates (Id, Category,TemplateName,AllowCategoryChange,LanguageCode,Status,header,body,footer,buttons,FilePath,MetaId,StatusCW)
                                        values (@Id, @Category,@TemplateName,@AllowCategoryChange,@LanguageCode,@Status,@header,@body,@footer,@buttons,@FilePath,@MetaId,1)
                END
                ELSE IF(@action = 5) -- Get Template Config By Id
                BEGIN
                    SELECT n.WAAccountId, n.Token, c.Url as [Url], t.TemplateName 
                    FROM ccMetaWAOutboundTemplates t
                    INNER JOIN ccMetaWhatsAppNumbers n on t.MetaId = n.MetaId
                    left JOIN ccMetaWhatsAppConfigurations c on c.Id = 2
                    WHERE t.Id = @whatsAppTemplateID
                    RETURN 0;
                END
                ELSE IF(@action = 6) -- update status to delete
                BEGIN
                    DECLARE @newStatus bit = 1;
                    IF(@metaStatus = ''DELETED'')
                    BEGIN
                        SET @newStatus = 0
                    END
                    UPDATE ccMetaWAOutboundTemplates SET 
                    [Status] = @metaStatus, 
                    StatusCW = @newStatus,
                    RemovalDate = ISNULL(RemovalDate, GETDATE())
                    WHERE Id = @whatsAppTemplateID
                    AND [StatusCW] = 1;
                    SELECT @@ROWCOUNT;
                    RETURN 0;
                END
                ELSE IF(@action = 7) -- Get template campaigns associated
                BEGIN
                    SELECT ISNULL(n.Cam_Id,0) as Cam_Id, ISNULL(n.Inbound_Id,0) AS Inbound_Id FROM ccMetaWAOutboundTemplates t
                    INNER JOIN ccMetaWhatsAppNumbers n on t.MetaId = n.MetaId
                    left JOIN ccMetaWhatsAppConfigurations c on n.MetaId = c.Id
                    WHERE t.Id = @whatsAppTemplateID
                    RETURN 0;
                END
                ELSE IF (@action = 8) -- update template
                BEGIN
                    DECLARE @tableHistoryLog TABLE (Id INT, Value VARCHAR(MAX))
                    DECLARE @areaName VARCHAR(50),
                            @login VARCHAR(50)

                    SELECT
                        @areaName = ca.AreaName,
                        @login = cu.Login
                    FROM ccUsers cu
                    INNER JOIN ccRIACat_Areas ca with(nolock) ON cu.IDArea = ca.IDArea
                    WHERE cu.User_id = @UserId

                    INSERT INTO @tableHistoryLog 
                    SELECT tb.Id, tb.Value
                    FROM dbo.fn_RIASplitDelimited(@HistoryLog, '',,'') tb


                    -- insert into activity log table and update template data
                    IF @header IS NULL OR LEN(@header) = 0 AND (SELECT LEN(ISNULL(header,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when header is null or '''' and before update header contains data
                    BEGIN
                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                        VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_HEADER'',''COMMON_NONE_O'',''root'')
                    END
                    IF @footer IS NULL OR LEN(@footer) = 0 AND (SELECT LEN(ISNULL(footer,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when footer is null or '''' and before update footer contains data
                    BEGIN
                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                        VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_FOOTER'',''COMMON_NONE_O'',''root'')
                    END
                    IF @buttons IS NULL OR LEN(@buttons) = 0 AND (SELECT LEN(ISNULL(buttons,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when buttons is null or '''' and before update buttons contains data
                    BEGIN
                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                        VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_BUTTONS'',''COMMON_NONE_O'',''root'')
                    END
                    
                    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccMetaWAOutboundTemplates'', @columnNameId=''Id'', @valueId= @Id, @userId= 1
                    Create table #ccMetaWAOutboundTemplates 
                    (
                        columnInfo VARCHAR(MAX),
                        dataInfo VARCHAR(MAX),
                        identifierInfo VARCHAR(MAX)
                    )

                    UPDATE ccMetaWAOutboundTemplates
                    SET Category = @Category,
                        header = @header,
                        body = @body,
                        footer = @footer,
                        buttons = @buttons,
                        FilePath = @FilePath
                    WHERE Id = @Id

                    EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccMetaWAOutboundTemplates'', @columnNameId = ''Id'', @valueId = @Id, @userId = 1,  @tableTemp=''#ccMetaWAOutboundTemplates'';

                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
                    SELECT
                        @areaName,
                        GETDATE(),
                        @login,
                        122,
                        20,
                        cc.identifierInfo,
                        tb1.Value,
                        @id
                    FROM #ccMetaWAOutboundTemplates cc
                    INNER JOIN  @tableHistoryLog  tb1 ON cc.columnInfo = (CASE 
                                                                            WHEN tb1.Id = 1 THEN ''Category''
                                                                            WHEN tb1.Id = 2 THEN ''header'' 
                                                                            WHEN tb1.Id = 3 THEN ''body'' 
                                                                            WHEN tb1.Id = 4 THEN ''footer''
                                                                            WHEN tb1.Id > 4 THEN ''buttons''
                                                                            END)
                END
                else IF(@action = 9) -- get templates by phone number
                BEGIN
                    ;WITH tb1 as(
                        SELECT
                            gal.Target AS Id,
                            CAST(gal.ActivityDate AS DATE) AS Date
                        FROM ccGalateaActivityLog gal 
                        WHERE gal.OperationId = 122 
                        AND gal.ModuleId = 20 
                        AND CAST(gal.ActivityDate AS DATE) >= DATEADD(DD,-30, CAST(GETDATE() AS DATE))
                    )
                    ,TemplateIsEditable AS (
                        SELECT
                            tb1.Id,
                            CASE WHEN COUNT(*) >= 10 THEN 2 WHEN MAX(tb1.Date) >= CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END AS IsEditable
                        FROM tb1
                        GROUP BY tb1.Id
                    )
                    SELECT 
                    cmwot.Id 
                    ,cmwot.TemplateName AS Name
                    ,cmwot.Status AS Status
                    ,Category AS Category
                    ,ISNULL(cmwot.notes, '''' ) AS Notes
                    ,cmwot.header AS Header
                    ,Body
                    ,cmwot.footer AS Footer
                    ,cmwot.buttons AS Buttons
                    ,cmwot.LanguageCode
                    ,ISNULL(cmwot.quality,0) AS Quality
                    ,cmwot.IsPendingQuality
                    ,ISNULL(tie.IsEditable, 0) AS IsEditable
                    ,cmwot.FilePath
                    FROM  dbo.ccMetaWAOutboundTemplates cmwot
                    LEFT JOIN TemplateIsEditable tie ON tie.Id = CAST(cmwot.Id AS VARCHAR(MAX))
                    WHERE cmwot.MetaId = @whatsAppTemplateID
                    AND cmwot.StatusCW = 1
                END
                ELSE IF(@action = 10) -- Check if an other load is executing for the campaign
                BEGIN
                    SELECT CASE WHEN COUNT(crl.load_id) > 0 THEN CONVERT(BIT , 1) ELSE CONVERT(BIT, 0) END AS IsProcessExecuting FROM dbo.ccRIALoading AS crl
                    WHERE crl.cam_id = @campId AND crl.state IN (0,2) AND crl.loadType = 3;
                END
                ELSE IF(@action = 11) --Check if the campaign was eliminated or desasigned
                BEGIN
                    DECLARE @campaignIsEliminateDesasigned BIT = 0;
                    DECLARE @idAreaNull SMALLINT = 0;

                    SELECT  @idAreaNull = cc.IDArea FROM dbo.ccCamps AS cc WHERE cc.cam_id = @campId

                    IF(@idAreaNull IS NULL)
                    BEGIN
                        SET @campaignIsEliminateDesasigned = 1; --La campaña fue eliminada
                    END

                    IF NOT EXISTS(SELECT TOP 1 crcew.IdCampEsp FROM dbo.ccRIACampEspWG AS crcew INNER JOIN dbo.ccRIAWorkGroupUsers AS crwgu
                    ON crwgu.IDWG = crcew.IDWG
                    WHERE crwgu.User_id = @UserId AND crcew.Tipo = 1 AND crcew.IdCampEsp = @campId)
                    BEGIN 
                        SET @campaignIsEliminateDesasigned = 1; --La campaña fue desasignada del grupo de trabajo
                    END

                    SELECT @campaignIsEliminateDesasigned;
                END
                ELSE IF(@action = 12) --Get new numbers loaded in  ccWhatsAppOutSource 
                BEGIN
                    SELECT cwt.Callkey FROM dbo.ccoWAWorkingTable AS cwt WHERE cwt.CamId = @campId AND cwt.WaStatus = 0
                    UNION
                    SELECT cwaos.CallKey FROM dbo.ccWhatsAppOutSource AS cwaos 
                    WHERE cwaos.camId = @campId AND cwaos.Status = 0
                END
                IF(@action = 13) -- Get templates by campaign number assigned
                BEGIN
                    SELECT 
                    cmwot.Id 
                    ,cmwot.TemplateName AS Name
                    ,cmwot.Status AS Status
                    ,Category AS Category
                    ,ISNULL(cmwot.notes, '''' ) AS Notes
                    ,cmwot.header AS Header
                    ,Body
                    ,cmwot.footer AS Footer
                    ,cmwot.buttons AS Buttons
                    ,cmwot.LanguageCode
                    ,ISNULL(cmwot.quality,0) AS Quality
                    ,cmwot.IsPendingQuality
                    ,cmwot.FilePath
                    FROM  dbo.ccMetaWAOutboundTemplates AS cmwot
                    INNER JOIN dbo.ccMetaWhatsAppNumbers AS cmwan ON 
                    cmwot.MetaId = cmwan.MetaId
                    WHERE cmwot.StatusCW = 1 AND cmwan.Cam_Id = @campId AND cmwot.Status = ''APPROVED''
                END
                ELSE IF (@action = 14) -- check if campaing exists
                BEGIN
                    IF EXISTS(SELECT 1 FROM dbo.ccMetaWAOutboundTemplates cmwot WHERE cmwot.Id = @whatsAppTemplateID)
                        SELECT 1
                    ELSE
                        SELECT 0
                END
            END
            '
        EXEC(@sql)


        --------------------------------------------------- End Isaac ------------------------------------------------------------------------------------


        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        /* Error generated based on sintax */ 
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR)  + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()
        RAISERROR (@errorGenerated, 11, 1)
        ROLLBACK TRAN
    END CATCH
END 
