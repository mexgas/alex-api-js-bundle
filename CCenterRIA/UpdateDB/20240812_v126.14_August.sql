/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2023/07/04
Description: K089000
Database: CCenterRia
Required version: 125.37
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
SET @versionfix = 14
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
--- Validacion para cuando pasamos a una nueva version LTS
--declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end
--IF @version > @actualVersion 
--BEGIN 
--    SET @actualVersionFix = 0
--    select @version,@actualVersion,@versioMajer
--END
IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY
		-------------------------- BEGIN Marco García ------------------------------------------------------------
		--------------------------------- K020109 -----------------------------------------------------------------------

			SET @process = 'delete index IX_WASource_1 in ccWhatsAppOutSource';
	SET @sql = 'IF EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_WASource_1'' AND object_id = OBJECT_ID(''ccWhatsAppOutSource''))
			BEGIN
				DROP INDEX IX_WASource_1 ON dbo.ccWhatsAppOutSource
			END';
	EXEC (@sql);

	SET @process = 'create IX_WASource_1 in ccWhatsAppOutSource';
	SET @sql = 'CREATE NONCLUSTERED INDEX [IX_WASource_1] ON [dbo].[ccWhatsAppOutSource]
				(
					[camId] ASC,
					[Status] ASC
				)';
	EXEC (@sql);

		set @process = 'K020109 drop sp ccsp_MetaWAOutboundTemplates'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_MetaWAOutboundTemplates'')
    begin
        DROP PROCEDURE ccsp_MetaWAOutboundTemplates
    end'
	EXEC(@sql)

	set @process = 'K020109 create sp ccsp_MetaWAOutboundTemplates se agregaron los actions 10,11,12 y 13'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_MetaWAOutboundTemplates]
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
	
	declare @target varchar(250)
	declare @tbl table (
		id varchar(250) not null,
		IsEditable int not null
	)
	
	 IF @action in( 1,9) begin
		set @target=CAST(@whatsAppTemplateID AS VARCHAR(250))

        ;WITH tb1 as(
		
		SELECT
			gal.Target AS Id,
			CAST(gal.ActivityDate AS DATE) AS Date
            FROM ccGalateaActivityLog gal 
            WHERE gal.OperationId = 122 
            AND gal.ModuleId = 20 
            AND gal.Target = ISNULL(@target, gal.target)
            AND CAST(gal.ActivityDate AS DATE) >= DATEADD(DD,-30, CAST(GETDATE() AS DATE))
		)
		, TemplateIsEditable AS (
            SELECT
            tb1.Id,
            CASE WHEN COUNT(*) >= 10 THEN 2 WHEN MAX(tb1.Date) >= CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END AS IsEditable
            FROM tb1
            GROUP BY tb1.Id
        )

		insert into @tbl
		select * from TemplateIsEditable
	end
	IF(@action = 1)
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
		,ISNULL(tie.IsEditable, 0) AS IsEditable
		,cmwot.FilePath
		FROM  dbo.ccMetaWAOutboundTemplates AS cmwot
        LEFT JOIN @tbl tie ON tie.Id = CAST(cmwot.Id AS VARCHAR(MAX))
		WHERE cmwot.Id = ISNULL(@whatsAppTemplateID, cmwot.Id)
		AND cmwot.StatusCW = 1
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
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )

        UPDATE ccMetaWAOutboundTemplates
        SET Category = @Category,
            header = @header,
            body = @body,
            footer = @footer,
            buttons = @buttons
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
	else IF(@action = 9) --Selecion de plantillas  por telefono
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
        ,ISNULL(tie.IsEditable, 0) AS IsEditable
		,cmwot.FilePath
        FROM  dbo.ccMetaWAOutboundTemplates cmwot
        LEFT JOIN @tbl tie ON tie.Id = CAST(cmwot.Id AS VARCHAR(MAX))
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
END'
	EXEC(@sql);


	set @process = 'K020109 insert columnas Data1, Data2, Data3, Data4, Data5 and dateDial  in ccWhatsAppOutSource table'
	set @sql = 'IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccWhatsAppOutSource'' and COLUMN_NAME = ''Data1'')
	BEGIN
		ALTER TABLE ccWhatsAppOutSource ADD Data1 VARCHAR(255) NULL
	END
	IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccWhatsAppOutSource'' and COLUMN_NAME = ''Data2'')
	BEGIN
		ALTER TABLE ccWhatsAppOutSource ADD Data2 VARCHAR(255) NULL
	END
	IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccWhatsAppOutSource'' and COLUMN_NAME = ''Data3'')
	BEGIN
		ALTER TABLE ccWhatsAppOutSource ADD Data3 VARCHAR(255) NULL
	END
	IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccWhatsAppOutSource'' and COLUMN_NAME = ''Data4'')
	BEGIN
		ALTER TABLE ccWhatsAppOutSource ADD Data4 VARCHAR(255)
	END
	IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccWhatsAppOutSource'' and COLUMN_NAME = ''Data5'')
	BEGIN
		ALTER TABLE ccWhatsAppOutSource ADD Data5 VARCHAR(255)
	END
	IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccWhatsAppOutSource'' and COLUMN_NAME = ''dateDial'')
	BEGIN
		ALTER TABLE dbo.ccWhatsAppOutSource ADD dateDial DATETIME NOT NULL DEFAULT GETDATE()
	END'
	EXEC(@sql)

		set @process = 'K020109 drop sp ccsp_RIAOUTInsertNewJOBS_WT_Camp'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAOUTInsertNewJOBS_WT_Camp'')
    begin
        DROP PROCEDURE ccsp_RIAOUTInsertNewJOBS_WT_Camp
    end'
	EXEC(@sql)

	set @process = 'K020109 create sp ccsp_RIAOUTInsertNewJOBS_WT_Camp se agregó el código de ELSE IF(@campType = 5) línea 515 a la 587'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000
    AS
    SET NOCOUNT ON

    DECLARE @prioridad VARCHAR(8)
    DECLARE @batchsizeIni AS INT
    DECLARE @batchsizeFin AS INT
    DECLARE @rango AS DECIMAL
    DECLARE @rowstoInsert AS INT
    DECLARE @campType AS INT
    DECLARE @recordsQuantitySetting VARCHAR(8)
    DECLARE @settingValueP1 VARCHAR(25)

    SET @rowstoInsert = 0
    SET @batchsizeIni = 0
    SET @batchsizeFin = 0
    SET @rango = 0.00

    IF EXISTS(SELECT * FROM sys.views WHERE NAME = ''VIEW_SETTINGS'') BEGIN
        SELECT @recordsQuantitySetting = [valor] FROM VIEW_SETTINGS WHERE setting_id = 257;
        IF(@recordsQuantitySetting IS NOT NULL AND @recordsQuantitySetting <> '''') BEGIN
            SELECT @settingValueP1 = SUBSTRING(@recordsQuantitySetting, CHARINDEX(''|'', @recordsQuantitySetting)+1, LEN(@recordsQuantitySetting)),
                   @top = (SUBSTRING(@settingValueP1, 1, CHARINDEX(''|'', @settingValueP1)-1));
        END ELSE SET @top = 3000
    END ELSE SET @top = 3000

    SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
    FROM ccCampsPrioridadTel WITH (NOLOCK)
    WHERE cam_id = @camp_id

    SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @camp_id;

    DELETE ccUploadTemporal
    WHERE cam_id = @camp_id

    IF(@campType = 7)
    BEGIN
            CREATE TABLE #tempsmsOutSource (Id INT PRIMARY KEY identity, smsout_id INT, cam_id INT, sms_phoneNumber VARCHAR(19), sms_status TINYINT, sms_dateDial DATETIME, cal_keyw VARCHAR(40), iTimeZone INT, iTimeZone_summer INT, iTimeZone2 INT, iTimeZone_summer2 INT, iTimeZone3 INT, iTimeZone_summer3 INT, iTimeZone4 INT, iTimeZone_summer4 INT, iTimeZone5 INT, iTimeZone_summer5 INT, list_id INT, sms_dateDialEnd datetime, isSegmentLoad bit)

            CREATE NONCLUSTERED INDEX [IX_TempSMSO] ON [dbo].[#tempsmsOutSource] ([Id] ASC)
                WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

            CREATE TABLE #smsoutIdSource (smsout_id INT NOT NULL PRIMARY KEY)

            CREATE TABLE #smsoutIdSource2 (smsout_id INT NOT NULL PRIMARY KEY)
			--UPDATING TABLES BEFORE LOADING
			DECLARE @date datetime = GETDATE()
			UPDATE smsOutSource SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1
			UPDATE smsWorkingTable SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1

            INSERT INTO #smsoutIdSource
            SELECT top(@top) sos.smsout_id
            FROM dbo.smsOutSource AS sos  WITH (INDEX (IX_smsOutSource_2), NOLOCK)
            inner join dbo.smsWorkingTable AS swt WITH (INDEX (IX_smsWorkingTable_2), NOLOCK) 
            on sos.callkey = swt.cal_keyw AND sos.cam_id = swt.cam_id 
            WHERE sos.cam_id = @camp_id and sos.sms_status IN (0, 7) AND swt.sms_status <= 2

            UNION

            SELECT top(@top) swt2.smsout_id
            FROM dbo.smsOutSource AS sos2 WITH (INDEX (IX_smsOutSource_2), NOLOCK)
            inner join dbo.smsWorkingTable AS swt2 (NOLOCK)on sos2.smsout_id = swt2.smsout_id 
            WHERE sos2.cam_id = @camp_id AND (sos2.sms_status < 2 OR sos2.sms_status = 7)

            INSERT INTO #smsoutIdSource2
            SELECT top(@top) sos.smsout_id
            FROM dbo.smsOutSource AS sos WITH (INDEX (IX_smsOutSource_1), NOLOCK)
            WHERE sos.sms_status IN (0, 1, 7) AND cam_id = @camp_id

            INSERT #tempsmsOutSource(smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, cal_keyw, iTimeZone, 
            iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4,
             iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
            SELECT TOP(@top) smsout_id, cam_id, RTRIM(LEFT(LTRIM(sms_phoneNumber + ''        '' + sms_phoneNumber2 + ''         '' 
            + sms_phoneNumber3 + ''         '' + sms_phoneNumber4 + ''         '' + sms_phoneNumber5 + ''         ''), 13)) AS sms_phoneNumber,
             CASE sms_status WHEN 7 THEN 1 ELSE sms_status END sms_status, sms_dateDial, callkey, 
             CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone ELSE NULL END iTimeZone,
              CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone_summer ELSE NULL END iTimeZone_summer, 
              CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone2 ELSE NULL END iTimeZone2,
               CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone_summer2 ELSE NULL END iTimeZone_summer2, 
               CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone3 ELSE NULL END iTimeZone3, 
               CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone_summer3 ELSE NULL END iTimeZone_summer3,
                CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone4 ELSE NULL END iTimeZone4, 
                CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone_summer4 ELSE NULL END iTimeZone_summer4, 
                CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone5 ELSE NULL END iTimeZone5, 
                CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone_summer5 ELSE 
                        NULL END iTimeZone_summer5, list_id, sms_dateDialEnd, ISNULL(isSegmentLoad, 0)
            FROM dbo.smsOutSource  WITH (INDEX (IX_smsOutSource_1), NOLOCK)
            WHERE cam_id = @camp_id AND (sms_status < 2 OR sms_status = 7) 

            SELECT @rowstoInsert = COUNT(*) FROM #tempsmsOutSource AS tos;

            
            IF EXISTS(SELECT * FROM #tempsmsOutSource)
            BEGIN
                SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
                FROM #tempsmsOutSource  WITH (NOLOCK)

                SET @batchsizeFin = @batchsizeFin + @rango

                WHILE 1 = 1
                BEGIN
                    -- Nuevos Jobs
                    INSERT INTO dbo.smsWorkingTable
                    WITH (TABLOCKX) (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
                    SELECT smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, 0, 0 ,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad
                    FROM #tempsmsOutSource 
                    WHERE id > @batchsizeIni AND id <= @batchsizeFin

                    IF @batchsizeFin > @rowstoInsert
                        BREAK
                    ELSE
                    BEGIN
                        SET @batchsizeIni = @batchsizeIni + @rango
                        SET @batchsizeFin = @batchsizeFin + @rango
                    END
                END

                UPDATE dbo.smsOutSource
                SET sms_status = 2
                FROM dbo.smsOutSource AS sos WITH (NOLOCK), #smsoutIdSource2  cis3 WITH (NOLOCK)
                WHERE sos.smsout_id = cis3.smsout_id
            END

            DROP TABLE #smsoutIdSource

            DROP TABLE #smsoutIdSource2

            DROP TABLE #tempsmsOutSource
    END
	ELSE IF(@campType = 5)
	BEGIN
		CREATE TABLE #tempWhatsAppOutSource (Id INT PRIMARY KEY identity, WAOut_Id INT, CallKey VARCHAR(40), camId INT, PhoneNumber VARCHAR(30), Status INT, TimeZone int, TimeZone_Summer int, List_id INT, User_id SMALLINT, dateDial DATETIME)
		CREATE NONCLUSTERED INDEX [IX_TempWAO] ON [dbo].[#tempWhatsAppOutSource] ([Id] ASC)
                WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

		CREATE TABLE #WAIdSource (WAOut_Id INT NOT NULL PRIMARY KEY)

		INSERT INTO #WAIdSource
		SELECT top(@top) cwaos.WAOut_Id
            FROM dbo.ccWhatsAppOutSource AS cwaos WITH (INDEX (IX_WASource_1), NOLOCK)
            WHERE cwaos.Status IN (0) AND cwaos.camId = @camp_id

		INSERT INTO #tempWhatsAppOutSource
		(
		    WAOut_Id,
		    CallKey,
		    camId,
		    PhoneNumber,
		    Status,
		    TimeZone,
		    TimeZone_Summer,
		    List_id,
		    User_id,
			dateDial
		)
		  SELECT TOP(@top) cwaos.WAOut_Id, cwaos.CallKey,cwaos.camId, RTRIM(LEFT(LTRIM(cwaos.PhoneNumber + ''        '' ), 13)) AS phoneNumber,
             cwaos.Status AS WAStatus,
			 CASE WHEN cwaos.TimeZone = 0 THEN  dbo.fnGetTimeZone(cwaos.PhoneNumber,0) ELSE cwaos.TimeZone END,
			 CASE WHEN cwaos.TimeZone_Summer = 0 THEN  dbo.fnGetTimeZone(cwaos.PhoneNumber,1) ELSE cwaos.TimeZone_Summer END, 
			  list_id, cwaos.User_id, cwaos.dateDial
            FROM dbo.ccWhatsAppOutSource AS cwaos  WITH (INDEX (IX_WASource_1), NOLOCK)
            WHERE cwaos.camId = @camp_id AND (cwaos.Status = 0) 

		SELECT @rowstoInsert = COUNT(*) FROM #tempWhatsAppOutSource AS tos;

		 IF EXISTS(SELECT * FROM #tempWhatsAppOutSource)
            BEGIN
                SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
                FROM #tempWhatsAppOutSource  WITH (NOLOCK)

                SET @batchsizeFin = @batchsizeFin + @rango
				
                WHILE 1 = 1
                BEGIN
                    -- Nuevos Jobs
                    INSERT INTO dbo.ccoWAWorkingTable(WAOut_id, PhoneNumber, Callkey, CamId, WaStatus, dateDial, UserId,TimeZone, TimeZone_Summer)
                    SELECT WAOut_Id, PhoneNumber, CallKey, camId, Status, dateDial , User_id, TimeZone ,TimeZone_Summer
                    FROM #tempWhatsAppOutSource 
                    WHERE id > @batchsizeIni AND id <= @batchsizeFin

                    IF @batchsizeFin > @rowstoInsert
                        BREAK
                    ELSE
                    BEGIN
                        SET @batchsizeIni = @batchsizeIni + @rango
                        SET @batchsizeFin = @batchsizeFin + @rango
                    END
                END

                UPDATE dbo.ccWhatsAppOutSource
                SET 
				Status = 2,
				TimeZone = cis3.TimeZone,
				TimeZone_Summer = cis3.TimeZone_Summer
                FROM dbo.ccWhatsAppOutSource AS cwaos  WITH (NOLOCK), #tempWhatsAppOutSource  cis3 WITH (NOLOCK)
                WHERE cwaos.WAOut_Id = cis3.WAOut_Id
            END

			DROP TABLE #WAIdSource

            DROP TABLE #tempWhatsAppOutSource
	END
    ELSE
    BEGIN
            CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT)

            CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
                WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

            CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

            CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

            INSERT INTO #calloutIdSource
            SELECT top(@top) cs.callout_id
            FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_15), NOLOCK)
            inner join ccoWorkingTable wt WITH (INDEX (IX_ccoWorkingTable_15), NOLOCK) 
            on cs.callout_id = wt.callout_id AND cs.cam_id = wt.cam_id 
            WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

            UNION

            SELECT top(@top) Cout.callout_id
            FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
            inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id 
            WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)
    

            INSERT INTO #calloutIdSource2
            SELECT top(@top) callout_id
            FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
            WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

            IF exists(SELECT * FROM #calloutIdSource) 
            BEGIN
                UPDATE ccoCallBacks
                SET [status] = 6, schedulerStatus = 1
                WHERE callout_id IN (
                        SELECT callout_id
                        FROM #calloutIdSource cis
                        )

                UPDATE ccoCallsOutSource
                SET cal_Status = 4
                WHERE callout_id IN (
                        SELECT callout_id
                        FROM #calloutIdSource cis
                        )
            END

            INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
            iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
             iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
            SELECT TOP(@top) callout_id, cam_id, CASE WHEN ISNULL(recycleType, 1) = 0 THEN 
            CASE 
                WHEN recyclePhone = 1 THEN cal_telefono
                WHEN recyclePhone = 2 THEN cal_telefono2
                WHEN recyclePhone = 3 THEN cal_telefono3
                WHEN recyclePhone = 4 THEN cal_telefono4
                else cal_telefono5
            END
            ELSE rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         '' 
                + cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13)) 
            END AS cal_telefono,
             CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key, 
             CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
              CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
              CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
               CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
               CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
               CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
                CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
                CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
                CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
                CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE 
                        NULL END iZonaHoraria_verano5, list_id
            FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
            WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7) /*AND CONVERT(VARCHAR(10),cal_fechaDial, 103) >= CONVERT(VARCHAR(10), GETDATE(), 103)*/

            SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

            IF EXISTS(SELECT * FROM #tempCallsOutSource)
            BEGIN
                SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
                FROM #tempCallsOutSource WITH (NOLOCK)

                SET @batchsizeFin = @batchsizeFin + @rango

                WHILE 1 = 1
                BEGIN
                    -- Nuevos Jobs
                    INSERT INTO ccoWorkingTable
                    WITH (TABLOCKX) (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
                    SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
                    FROM #tempCallsOutSource
                    WHERE id > @batchsizeIni AND id <= @batchsizeFin

                    IF @batchsizeFin > @rowstoInsert
                        BREAK
                    ELSE
                    BEGIN
                        SET @batchsizeIni = @batchsizeIni + @rango
                        SET @batchsizeFin = @batchsizeFin + @rango
                    END
                END

                UPDATE ccoCallsOutSource
                SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
                FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
                WHERE co.callout_id = cis3.callout_id
            END

            DROP TABLE #calloutIdSource

            DROP TABLE #calloutIdSource2

            DROP TABLE #tempCallsOutSource
    END

    UPDATE ccCampsNvosCB
    SET dateUpdate = NULL
    WHERE id = @camp_id

    SET NOCOUNT OFF'
	EXEC(@sql);


	SET @process = 'K020109 delete function Verifica2'
	SET @sql = ' IF EXISTS (SELECT * FROM   sys.objects WHERE  object_id = OBJECT_ID(N''[dbo].[Verifica2]'')
						AND type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
		BEGIN
			DROP FUNCTION [dbo].[Verifica2];
		END';
	EXEC(@sql);

	set @process = 'K020109 create function Verifica2 en la línea 789 de agregó la validación @isForWhatsapp = 1, para tambien validar si es móvil para whatsapp '
	set @sql = 'CREATE FUNCTION [dbo].[Verifica2] (@tel VARCHAR(32), @pais TINYINT = 0, @cldLocal VARCHAR(7) = '''', @isForSMS bit = 0, @isForWhatsapp BIT = 0)
		RETURNS VARCHAR(32)
		AS
		BEGIN
			DECLARE @ld VARCHAR(7)
			DECLARE @lon TINYINT
			DECLARE @result TINYINT
			DECLARE @mod VARCHAR(10)
			DECLARE @tipo VARCHAR(10)
			DECLARE @Cadena VARCHAR(32)
			DECLARE @isLocal BIT
			declare @serie varchar(10)

			IF (@pais = 0 AND @cldLocal = '''')
			BEGIN
				SELECT @pais = valor
				FROM ccSettings WITH (NOLOCK)
				WHERE setting_id = 104

				SELECT @cldLocal = valor
				FROM ccSettings WITH (NOLOCK)
				WHERE setting_id = 17
			END

			SELECT @tel = dbo.limpia(@tel)

			IF @pais = 1
			BEGIN --Empieza Mexico
				SELECT @lon = len(@tel), @mod = ''''

				IF @lon < 10
				BEGIN
					RETURN ''E_'' + @tel
				END

				SELECT @tel = right(@tel, 10)

				SELECT @lon = len(@tel)

				IF @lon = 10
				BEGIN
					IF EXISTS (
							SELECT TOP 1 cld
							FROM series NOLOCK
							WHERE cld = left(@tel, 3)
							and serie=SUBSTRING(@tel,4,3)
							)
						SELECT @ld = left(@tel, 3),@serie=SUBSTRING(@tel,4,3)
					ELSE IF EXISTS (
							SELECT TOP 1 cld
							FROM series NOLOCK
							WHERE cld = left(@tel, 2)
							and serie=SUBSTRING(@tel,3,4)
							)
						SELECT @ld = left(@tel, 2),@serie=SUBSTRING(@tel,3,4)
					ELSE
						RETURN ''E_'' + @tel

					SELECT TOP 1 @mod = modalidad, @tipo = [TIPO DE RED]
					FROM series NOLOCK
					WHERE cld = @ld AND serie = @serie AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

					IF @mod NOT IN (''FIJO'', ''MPP'', ''CPP'')
					BEGIN
						RETURN ''E_'' + @tel
					END

					IF (@isForSMS = 1 OR @isForWhatsapp = 1 )AND @tipo <> ''MOVIL''
					BEGIN
						RETURN ''E_'' + @tel
					END

					DECLARE @specialDialPlan TINYINT

					SELECT @specialDialPlan = valor
					FROM ccsettings WITH (NOLOCK)
					WHERE setting_id = 195

					IF @specialDialPlan = 2
					BEGIN --Number 10 digits
						RETURN @tel
					END

					SET @isLocal = 0

					IF EXISTS (
							SELECT *
							FROM ccRiaArecode
							WHERE area = @ld
							)
					BEGIN
						SET @isLocal = 1
					END
					ELSE IF @cldLocal = @ld
					BEGIN
						SET @isLocal = 1
					END

					IF @specialDialPlan = 1
					BEGIN
						--Number local 10 digit
						--Number LD 12 digit
						--Number Cell 13 digit
						SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @isLocal = 1 THEN @tel ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN --Local y LD
										CASE WHEN @isLocal = 1 THEN ''044'' + @tel ELSE ''045'' + @tel END END --Celular
					END
					ELSE
					BEGIN
						--Number local 7 o 8 digit
						--Number LD 12 digit
						--Number Cell 13 digit
						SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @isLocal = 1 THEN right(@tel, 10 - len(@ld)) ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN --Local y LD
										CASE WHEN @isLocal = 1 THEN ''044'' + @tel ELSE ''045'' + @tel END END --Celular
					END
				END
				ELSE IF @lon > 0
				BEGIN
					SET @tel = ''E_'' + @tel
				END

				RETURN @tel
			END --Termina Mexico
					--------------------------- Empieza Argentina ---------------------------
			ELSE IF @pais = 2
			BEGIN
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) = ''E''
				BEGIN
					RETURN @tel
				END

				SELECT @lon = len(@tel)

				IF @lon IN (6, 7, 8) AND left(@tel, 2) <> ''15''
				BEGIN
					SET @tel = @cldLocal + @tel
				END

				IF @lon IN (8, 9, 10) AND left(@tel, 2) = ''15''
				BEGIN
					SET @tel = @cldLocal + substring(@tel, 3, @lon - 2)
				END

				--Buscamos el 15
				IF @lon = 13
				BEGIN
					DECLARE @index AS INT

					SELECT @index = charindex(''15'', @tel)

					--El unico caso en el que la lada tiene un 15 es con lada 3715
					IF @index < 2
					BEGIN
						SELECT @tel = ''E_'' + @tel

						RETURN @tel
					END
					ELSE
					BEGIN
						IF substring(@tel, @index - 2, 4) = ''3715''
						BEGIN
							SELECT @ld = ''3715''

							SET @tel = @ld + right(@tel, 6)
						END
						ELSE
						BEGIN
							SELECT @ld = substring(@tel, 2, @index - 2)

							SET @tel = @ld + right(@tel, 13 - (@index + 1))
						END
					END
				END

				SELECT @tel = right(@tel, 10)

				IF len(@tel) = 10
				BEGIN			

					BEGIN
						-- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
						DECLARE @contLD AS INT
						DECLARE @cont AS INT

						SET @contLD = 4

						BuscaLada:

						IF isnull(@ld, '''') = '''' AND @contLD >= 2
						BEGIN
							SELECT @ld = cld
							FROM seriesArg
							WHERE cld = left(@tel, @contLD)

							IF isnull(@ld, '''') = ''''
							BEGIN
								SET @contLD = @contLD - 1

								GOTO BuscaLada
							END
						END
						ELSE
						BEGIN
							IF isnull(@ld, '''') = ''''
							BEGIN
								SELECT @tel = ''E_'' + @tel
							END
						END
					END

					-- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
					BEGIN
						IF len(@ld) = 2
						BEGIN
							SET @cont = 5

							buscaSerie2:

							IF isnull(@serie, '''') = '''' AND @cont >= 4
							BEGIN
								SELECT @serie = serie
								FROM seriesArg
								WHERE cld = @ld AND serie = substring(@tel, 3, @cont)

								IF isnull(@serie, '''') = ''''
								BEGIN
									SET @cont = @cont - 1

									GOTO buscaSerie2
								END
							END
						END
						ELSE
						BEGIN
							IF len(@ld) = 3
							BEGIN
								SET @cont = 4

								buscaSerie3:

								IF isnull(@serie, '''') = '''' AND @cont >= 3
								BEGIN
									SELECT @serie = serie
									FROM seriesArg
									WHERE cld = @ld AND serie = substring(@tel, 4, @cont)

									IF isnull(@serie, '''') = ''''
									BEGIN
										SET @cont = @cont - 1

										GOTO buscaSerie3
									END
								END
							END
							ELSE
							BEGIN
								IF len(@ld) = 4
								BEGIN
									SET @cont = 3

									buscaSerie4:

									IF isnull(@serie, '''') = '''' AND @cont >= 2
									BEGIN
										SELECT @serie = serie
										FROM seriesArg
										WHERE cld = @ld AND serie = substring(@tel, 5, @cont)

										IF isnull(@serie, '''') = ''''
										BEGIN
											SET @cont = @cont - 1

											GOTO buscaSerie4
										END
									END
								END
							END
						END
					END

					SELECT @mod = modalidad
					FROM seriesArg
					WHERE cld = @ld AND serie = @serie AND right(@tel, 10 - len(@ld) - len(@serie)) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

					-- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie			
					IF isNull(@serie, '''') = '''' AND @contLD > 1
					BEGIN
						SET @contLD = len(@ld) - 1
						SET @ld = NULL

						GOTO BuscaLada
					END

					SELECT @tel = CASE WHEN @mod IN (''BASICA'', ''MPP'') THEN CASE WHEN @ld = @cldLocal THEN right(@tel, 10 - len(@ld)) ELSE ''0'' + @tel END WHEN @mod = ''CPP'' THEN CASE WHEN @ld = @cldLocal THEN ''15'' + right(@tel, 10 - len(@ld)) ELSE ''0'' + @ld + ''15'' + right(@tel, 10 - len(@ld)) END ELSE ''E_'' + @tel END
				END
				ELSE
				BEGIN
					IF len(@tel) > 0
					BEGIN
						SELECT @tel = ''E_'' + @tel
					END
				END

				RETURN @tel
			END ------------------ Termina Argentina ------------------
			ELSE IF @pais = 3
			BEGIN --Empieza Colombia
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) = ''E''
				BEGIN
					RETURN @tel
				END

				IF len(@tel) NOT IN (7, 8, 10, 11)
				BEGIN
					RETURN ''E_'' + @tel
				END

				IF len(@tel) = 7
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesCol
							WHERE serie = left(@tel, 4) AND @cldLocal = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF len(@tel) = 8
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesCol
							WHERE serie = substring(@tel, 2, 4) AND left(@tel, 1) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF len(@tel) = 10
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesCol
							WHERE serie = substring(@tel, 5, 3) AND (left(@tel, 3) + ''-'' + substring(@tel, 4, 1)) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF len(@tel) = 11
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesCol
							WHERE serie = substring(@tel, 6, 3) AND (substring(@tel, 2, 3) + ''-'' + substring(@tel, 5, 1)) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END
			END --Termina Colombia

			-- Empieza Chile
			IF @pais = 5
			BEGIN
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) = ''E''
				BEGIN
					RETURN @tel
				END

				IF len(@tel) = 6 AND len(@cldLocal) = 2
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesChi
							WHERE cld = @cldLocal AND left(@tel, 3) = serie AND right(@tel, 3) BETWEEN numeracioninicial AND numeracionFinal
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF len(@tel) = 7
				BEGIN
					IF @cldLocal IN (2, 41, 44, 32)
					BEGIN
						IF EXISTS (
								SELECT serie
								FROM serieschi
								WHERE serie = left(@tel, 4)
								)
						BEGIN
							RETURN @tel
						END
						ELSE
						BEGIN
							IF left(@tel, 3) = ''200'' AND EXISTS (
									SELECT serie
									FROM serieschi
									WHERE serie = left(@tel, 3)
									)
							BEGIN
								RETURN @tel
							END
						END
					END
				END

				IF len(@tel) = 8
				BEGIN
					IF left(@tel, 1) = ''2''
					BEGIN
						IF EXISTS (
								SELECT serie
								FROM serieschi
								WHERE serie = substring(@tel, 2, 4)
								)
						BEGIN
							RETURN @tel
						END
						ELSE
						BEGIN
							IF EXISTS (
									SELECT serie
									FROM serieschi
									WHERE serie = substring(@tel, 2, 5)
									)
							BEGIN
								RETURN @tel
							END
							ELSE
							BEGIN
								RETURN ''E_'' + @tel
							END
						END
					END
					ELSE
					BEGIN
						RETURN @tel
					END
				END

				IF len(@tel) = 10
				BEGIN
					IF left(@tel, 2) = ''09''
					BEGIN
						IF EXISTS (
								SELECT serie
								FROM serieschi
								WHERE cld = substring(@tel, 3, 1) AND serie = substring(@tel, 5, 3)
								)
						BEGIN
							RETURN @tel
						END
						ELSE
						BEGIN
							RETURN ''E_'' + @tel
						END
					END
				END
			END

			--Termina Chile
			IF @pais = 6
			BEGIN --Empieza Venezuela
				SELECT @lon = len(@tel)

				IF @lon = 7
				BEGIN
					SET @tel = @cldLocal + @tel
				END

				SELECT @tel = right(@tel, 10)

				IF len(@tel) = 10
				BEGIN
					SELECT @ld = left(@tel, 3)

					SELECT @mod = tipo
					FROM seriesVen
					WHERE left(@tel, 3) = LD

					IF @mod = ''CPP''
					BEGIN
						IF EXISTS (
								SELECT *
								FROM seriesVen
								WHERE LD = @ld
								)
						BEGIN
							IF @ld = @cldLocal
							BEGIN
								SELECT @tel = right(@tel, 7)
							END
							ELSE
							BEGIN
								SELECT @tel = ''0'' + @tel
							END
						END
						ELSE
						BEGIN
							SELECT @tel = ''E_'' + @tel
						END
					END
					ELSE
					BEGIN
						IF @mod = ''FIJO''
						BEGIN
							IF EXISTS (
									SELECT serie
									FROM seriesVen
									WHERE serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) AND right(@tel, 4) BETWEEN [Inicio] AND [Fin]
									)
							BEGIN
								IF @ld = @cldLocal
								BEGIN
									SELECT @tel = right(@tel, 7)
								END
								ELSE
								BEGIN
									SELECT @tel = ''0'' + @tel
								END
							END
							ELSE
							BEGIN
								SELECT @tel = ''E_'' + @tel
							END
						END
						ELSE
						BEGIN
							SELECT @tel = ''E_'' + @tel
						END
					END
				END
				ELSE
				BEGIN
					IF len(@tel) > 0
					BEGIN
						SELECT @tel = ''E_'' + @tel
					END
				END

				RETURN @tel
			END --Termina Venezuela

			IF @pais = 7
			BEGIN -- Empieza UK
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) = ''E''
				BEGIN -- regresa error por longitud
					RETURN @tel
				END

				SELECT @lon = len(@tel)

				--numeros no geograficos
				IF (left(@tel, 2) IN (''03'', ''07'', ''09'') AND @lon <> 11) OR (left(@tel, 3) IN (''055'', ''056'', ''070'') AND @lon <> 11)
				BEGIN
					RETURN ''E_'' + @tel --error por longitud con lada correcta
				END
				ELSE
				BEGIN
					IF left(@tel, 7) IN (''0845464'') OR left(@tel, 5) = ''07624'' OR left(@tel, 4) IN (''0500'', ''0800'') OR left(@tel, 3) IN (''055'', ''056'', ''070'', ''76'') OR left(@tel, 2) IN (''03'', ''07'', ''08'', ''09'')
					BEGIN
						RETURN @tel;--longitud correcta y numero no geografico
					END
				END

				--numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
				IF (left(@tel, 7) IN (''0159575'', ''0159576'')) OR (left(@tel, 5) IN (''02820'', ''02821'', ''02825'', ''02827'', ''02828'', ''02829'', ''02830'', ''02837'', ''02838'', ''02840'', ''02841'', ''02842'', ''02843'', ''02844'', ''02866'', ''02867'', ''02868'', ''02870'', ''02871'', ''02877'', ''02879'', ''02880'', ''02881'', ''02882'', ''02885'', ''02886'', ''02887'', ''02889'', ''02890'', ''02891'', ''02892'', ''02893'', ''02894'', ''02895'', ''02897'') AND @lon = 11) OR --claves 2xxx tienen formato 4-6
					(left(@tel, 4) IN (''0113'', ''0114'', ''0115'', ''0116'', ''0117'', ''0118'', ''0121'', ''0131'', ''0141'', ''0151'', ''0161'', ''0238'', ''0239'') AND @lon = 11) OR --3-digit area codes have 7-digit subscribers.
					(left(@tel, 3) IN (''020'', ''024'', ''029'') AND @lon = 11)
				BEGIN --2-digit area codes have 8-digit subscribers.
					RETURN @tel;
				END

				--numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
				IF left(@tel, 2) = ''01''
				BEGIN
					SELECT @ld = count(cld)
					FROM seriesuk
					WHERE cld = substring(@tel, 2, 4) --mayor numero de ladas (va primero por ser mas probable)

					IF @ld > 0
					BEGIN
						RETURN @tel;
					END
					ELSE
					BEGIN
						SELECT @ld = count(cld)
						FROM seriesuk
						WHERE cld = substring(@tel, 2, 5) --ladas restantes

						IF @ld > 0
						BEGIN
							RETURN @tel;
						END
					END
				END --si no encontro ni error ni coincidencia entonces esta mal

				RETURN ''E_'' + @tel
			END --Termina UK

			IF @pais = 8
			BEGIN --Empieza Arabia Saudita
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				SELECT @lon = len(@tel)

				IF @lon = 7
				BEGIN
					SET @tel = ''0'' + @cldLocal + @tel
				END

				SELECT @lon = len(@tel)

				IF @lon = 9
				BEGIN
					IF EXISTS (
							SELECT regiones
							FROM seriesSA
							WHERE right(@tel, 4) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 3, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 4 AND left(@tel, 2) = cld
							)
					BEGIN
						IF (substring(@tel, 2, 1) = @cldLocal)
						BEGIN
							RETURN right(@tel, 7)
						END
						ELSE
						BEGIN
							RETURN @tel
						END
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF @lon = 10
				BEGIN
					IF EXISTS (
							SELECT regiones
							FROM seriesSA
							WHERE right(@tel, 4) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 4, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 4 AND left(@tel, 3) = cld
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF @lon = 11
				BEGIN
					IF EXISTS (
							SELECT regiones, *
							FROM seriesSA
							WHERE right(@tel, 6) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 3, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 6 AND left(@tel, 2) = cld
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END
			END --Termina Arabia Saudita

			IF @pais = 9
			BEGIN --Empieza Australia
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				SELECT @lon = len(@tel)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF EXISTS (
							SELECT Regiones
							FROM SeriesAU
							WHERE convert(INT, LD) = convert(INT, substring(@tel, 1, 2)) AND convert(INT, AreaCode) = convert(INT, substring(@tel, 3, 2)) AND convert(INT, substring(@tel, 5, 6)) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END
				ELSE
				BEGIN
					RETURN @tel
				END
			END --Termina Australia

			IF @pais = 10
			BEGIN -- Inicia Brasil
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				SELECT @lon = len(@tel)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF @lon IN (8, 9)
					BEGIN --numero local
						IF EXISTS (
								SELECT Regiones
								FROM seriesBR
								WHERE convert(INT, AreaCode) = convert(INT, @cldLocal) AND convert(INT, @tel) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
								)
						BEGIN
							RETURN @tel
						END
						ELSE
						BEGIN
							RETURN ''E_'' + @tel
						END
					END

					IF @lon IN (10, 11)
					BEGIN --numero nacional
						IF EXISTS (
								SELECT Regiones
								FROM seriesBR
								WHERE convert(INT, AreaCode) = convert(INT, left(@tel, 2)) AND convert(INT, right(@tel, @lon - 2)) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
								)
						BEGIN
							RETURN @tel
						END
						ELSE
						BEGIN
							RETURN ''E_'' + @tel
						END
					END
				END
				ELSE
				BEGIN
					RETURN @tel
				END
			END -- Termina Brasil

			IF @pais = 11
			BEGIN -- Inicia Guatemala
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF EXISTS (
							SELECT zonaGeografica
							FROM seriesGT(NOLOCK)
							WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
							)
						RETURN @tel
					ELSE
						RETURN ''E_'' + @tel
				END
				ELSE
					RETURN @tel
			END -- Termina Guatemala

			IF @pais = 12
			BEGIN -- Inicia Costa Rica
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF len(@tel) = 8
						IF EXISTS (
								SELECT zonaGeografica
								FROM seriesCR(NOLOCK)
								WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					ELSE IF len(@tel) = 10
					BEGIN
						IF EXISTS (
								SELECT zonaGeografica
								FROM seriesCR(NOLOCK)
								WHERE indicativoDestino = substring(@tel, 1, 3) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					END
					ELSE IF charindex(substring(@tel, 1, 2), ''00,08'') <= 0
						RETURN ''E_'' + @tel
					ELSE
						RETURN @tel
				END
			END -- Termina Costa Rica

			IF @pais = 13
			BEGIN -- Inicia Salvador
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF len(@tel) = 8
						IF EXISTS (
								SELECT zonaGeografica
								FROM seriesSV(NOLOCK)
								WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					ELSE IF charindex(substring(@tel, 1, 2), ''00'') <= 0
						RETURN ''E_'' + @tel
					ELSE
						RETURN @tel
				END
			END -- Termina Salvador

			IF @pais = 14
			BEGIN -- Inicia Spain
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF len(@tel) = 9
						IF EXISTS (
								SELECT provincia
								FROM seriesEsp(NOLOCK)
								WHERE indicativo = substring(@tel, 1, 1) AND right(@tel, 8) BETWEEN numInicial AND numFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					ELSE IF charindex(substring(@tel, 1, 2), ''00'') <= 0
						RETURN ''E_'' + @tel
					ELSE
						RETURN @tel
				END
			END -- Termina España

			IF @pais = 15
			BEGIN --Inicia Peru
				SELECT @tel = dbo.Completa(@tel, @pais, @cldLocal)

				SELECT @lon = len(@tel)

				IF @lon BETWEEN 6 AND 7
				BEGIN
					SET @tel = @cldLocal + @tel
				END

				SELECT @tel = right(@tel, 9)

				SELECT @lon = len(@tel)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF @lon = 9
					BEGIN
						IF EXISTS (
								SELECT zonaGeografica
								FROM seriesPE(NOLOCK)
								WHERE left(@tel, 1) = 9 OR substring(@tel, 2, 1) = 1 AND areaNumeracion = 1 AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal OR substring(@tel, 2, 1) <> 1 AND left(@tel, 2) = areaNumeracion AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					END
				END
			END --Termina Peru

			IF @pais = 16
			BEGIN --Panama
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF len(@tel) = 7
					BEGIN -- Local
						IF (substring(@tel, 1, 1) != ''6'')
						BEGIN
							IF EXISTS (
									SELECT zonaGeografica
									FROM seriesPa(NOLOCK)
									WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
									)
								RETURN @tel
							ELSE
								RETURN ''E_'' + @tel
						END
						ELSE
							RETURN ''E_'' + @tel
					END

					IF len(@tel) = 8
					BEGIN --Celular
						IF (substring(@tel, 1, 1) = ''6'')
						BEGIN
							IF EXISTS (
									SELECT zonaGeografica
									FROM seriesPa(NOLOCK)
									WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
									)
								RETURN @tel
							ELSE
								RETURN ''E_'' + @tel
						END
						ELSE
							RETURN ''E_'' + @tel
					END
					ELSE
					BEGIN
						IF charindex(substring(@tel, 1, 2), ''00'') <= 0
							RETURN ''E_'' + @tel
						ELSE
							RETURN @tel
					END
				END
			END

			RETURN @tel
		END'
	EXEC(@sql);

	SET @process = 'K020109 delete function Verifica'
	SET @sql = ' IF EXISTS (SELECT * FROM   sys.objects WHERE  object_id = OBJECT_ID(N''[dbo].[Verifica]'')
						AND type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
		BEGIN
			DROP FUNCTION [dbo].[Verifica];
		END';
	EXEC(@sql);

	set @process = 'K020109 create function Verifica en la función dbo.verifica2 se le agregó el parametro DEFAULT'
	set @sql = 'CREATE FUNCTION [dbo].[Verifica](@tel varchar(32))
		RETURNS varchar(32) AS
		BEGIN
	
			declare @cldLocal varchar(7)
			declare @pais tinyint

			select @pais = valor from ccSettings with(nolock) where setting_id = 104
			select @cldLocal = valor from ccSettings with(nolock) where setting_id = 17

			return dbo.Verifica2(@tel,@pais,@cldLocal,DEFAULT, DEFAULT)

		END'
	EXEC(@sql);

	set @process = 'K020109 drop sp ccspLoadRegistrySegments'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspLoadRegistrySegments'')
    begin
        DROP PROCEDURE ccspLoadRegistrySegments
    end'
	EXEC(@sql)

	set @process = 'K020109 create sp ccspLoadRegistrySegments en donde se ocupa dbo.verifica2 se le agregó un parametro default'
	set @sql = 'CREATE procedure [dbo].[ccspLoadRegistrySegments] 
				@action int,
				@camId int = null,
				@typeTemplate int=2, --1 Segmentos, 2 Plantillas Archivos
				@phone varchar(32)=null,
				@templateId int=null,
				@callKey varchar(60)=null,
				@userId int=0,
				@msg varchar(160)=null,
				@smsout_id int=null,
				@SystemApiId varchar(100)=null,
				@statusSystemsId int=null,
				@dateStart datetime=null,
				@dateEnd datetime=null,
				@segmentIds varchar(max)='''',
				@columns varchar(max)=''*''
				as

				SET NOCOUNT ON;
				SET ANSI_WARNINGS OFF;

				DECLARE @sql VARCHAR(max)
				declare @today date=convert(date,getdate(),121)
				declare @monday datetime


				if @action=1 begin --List Segments
					select SegmentId,Name from ccSmsSegments where IsGlobal=1 or CampaignId=@camId
				end
				else if @action=2 begin  --ListColumnsTable
				    SELECT name
					FROM sys.columns
					WHERE object_id = OBJECT_ID(''SmsRemesasMuñoz'')
					and name like ''TELEFONOS[0-9]%''
				end
				else if @action=3 begin --List Plantillas
				    select TemplateId,Description as Name,MessageTemplate from ccSmsTemplate where Type=@typeTemplate
				end
				else if @action=4 begin
				    Select iDate DateStart,fDate DateEnd from ccSmsSchedules where cam_id=@camId
				end
				else if @action=5 begin
				    select top 1 * from SmsRemesasMuñoz
				end
				else if @action=6 begin
				    SET @columns = ''''
					SELECT @columns = @columns + ''isnull(max(len('' + COLUMN_NAME + '')),0)as '' + COLUMN_NAME + '',''
					FROM INFORMATION_SCHEMA.COLUMNS
					WHERE TABLE_NAME = ''SmsRemesasMuñoz''
					AND DATA_TYPE IN (''varchar'', ''nvarchar'', ''char'', ''nchar'');

					SET @columns = SUBSTRING(@columns, 0, len(@columns))
					SET @sql = ''select '' + @columns + '' from SmsRemesasMuñoz''

					--PRINT (@sql)
					EXEC (@sql)

				end
				else if @action = 7 begin
				    declare @valueInt104 int, @value17 varchar(100), @value247 varchar(100), @valueInt258 int
				    select 
				        @valueInt104 = case when setting_id = 104 then valor else @valueInt104 end,
				        @value17 = case when setting_id = 17 then valor else @value17 end,
				        @value247 = case when setting_id = 247 then valor else @value247 end,
				        @valueInt258 = case when setting_id = 258 then valor else @valueInt258 end
				    from VIEW_SETTINGS 
				    where setting_id in (104, 17, 247, 258)

				    select @phone = dbo.Verifica2(@phone, @valueInt104, @value17, 1, DEFAULT)
				    if LEFT(@phone, 1) = ''E'' begin
				        select -1 as Result, ''is not cellPhone''
				        return -1;
				    end
				    if @valueInt258 <= 0 begin
				        select -2 as Result, ''Credit Sms Zero''
				    end
				    select 1 as Result, @value247 as ApiBackBone, MessageTemplate
				    from ccSmsTemplate 
				    where TemplateId = @templateId
				end
				else if @action=8 begin --smsOutSource
				    insert into smsOutSource (callkey,cam_id,sms_phoneNumber,sms_status,sms_attemps,user_id,sms_dateDial,dial_tels)
					values (@callKey,@camId,@phone,0,0,@userId,getdate(),''12345NNN'')
					select @smsout_id=SCOPE_IDENTITY()

					insert into smsoutSourceMessage(smsout_id,message)
					values(@smsout_id,@msg)

					select @smsout_id as smsoutId
				end
				else if @action=9 begin --smsccoLogDial
					insert into smsccoLogDial (smsout_id,cam_id,phone,smsDate,registryClient,SystemApiId,statusSystemsId,Bill,ProviderId)
					values (@smsout_id,@camId,@phone,getdate(),@callKey,@SystemApiId,@statusSystemsId,
					case when @statusSystemsId=0 then 0.7 else 0 end,0
					)	
				end
				else if @action=10 begin --ChangeSchedule
					delete from ccSmsSchedules where cam_id=@camId
					insert into ccSmsSchedules(cam_id,iDate,fDate) values(@camId,@dateStart,@dateEnd)
				end
				else if @action=11 begin --Carga los registros cargados
					truncate table ccSmsValidateRegistryWeek;
					SELECT @monday= DATEADD(DAY, -(DATEPART(WEEKDAY, @today) + @@DATEFIRST - 2) % 7, CAST(@today AS DATE))
					---------------Revisa la lista de registros es necesario moverlo a otro proceso para que lo tenga en la carga---------------------
					insert into ccSmsValidateRegistryWeek(registryClient,total,totaltoDay,loadRegistry)
					select registryClient,count(*) total,
					count(case when smsDate>=@today  then 1 end) totaltoday,
					0 loadRegistry
					from smsccoLogDial with(nolock)
					where smsDate>=@monday
					group by registryClient

				end
				else if @action in(12,13) begin --Validar Carga

					declare @segmentTable table(id int, status bit, segmentName VARCHAR(10))
					declare @segmentNames varchar(max)
					declare @conditionTable table(conditionId int,smsCondition varchar(max),DailyLimit int,WeeklyLimit int,status bit, SegmentName varchar(255))
					--declare @SmsRemesasId table (credictId int)
					create table #SmsRemesasId(creditId nvarchar(40), TDCT VARCHAR(max))
					create table #SmsRemesasIdTemp(creditId nvarchar(40), TDCT VARCHAR(max))
					create table #functionalState(creditId nvarchar(40), smsSent int)
					declare @FlagB table(credictId int, TDCT VARCHAR(max))
					------------Se obtiene los dias de la semana que han pasado
					DECLARE @lastMonday datetime, @WeekStart datetime;
					DECLARE @DaysFromWeek int, @LastMondaymonth int, @ActualMonth int
					DECLARE @actualDate datetime = getdate()
					SET @lastMonday = DATEADD(DAY, -(DATEPART(WEEKDAY, @actualDate) + 5) % 7, @actualDate);
					--select @lastMonday lastMonday, @actualDate actualDate

					SET @LastMondaymonth = DATEPART(MONTH, @lastMonday);
					SET @ActualMonth = DATEPART(MONTH, @actualDate);

					IF(@ActualMonth = @LastMondaymonth)
					BEGIN
						SELECT @DaysFromWeek = DATEDIFF(DAY, @lastMonday, @actualDate);
					END
					ELSE BEGIN
						SELECT @DaysFromWeek = DATEDIFF(DAY, DATEADD(DAY, 1 - DATEPART(DAY, @actualDate), @actualDate), @actualDate);
					END
					SET @WeekStart = CONVERT(datetime, CONVERT(date, @actualDate-@DaysFromWeek));
					

					--------------------------Comienza validacion--------------

					insert into @segmentTable
					select a.value,0 status, s.Name from dbo.fn_RIASplitDelimited(@segmentIds,'','') a
					inner join ccSmsSegments s on s.segmentId = a.value

					--Condicion para obtener solo los que coincidan con SegmentoMC
					SELECT @segmentNames = COALESCE(@segmentNames + '', '', '''') + QUOTENAME(a.segmentName, '''''''')
					FROM @segmentTable a

					--Tabla con todos los id de la tabla remesa que hacen match con los segmentos
					INSERT INTO #SmsRemesasIdTemp
					SELECT a.credito, a.TDCT from SmsRemesasMuñozDay a 
					INNER JOIN @segmentTable b on a.SegmentoMC = b.segmentName
					--Reseteamos todos los resultados para los segmentos
					UPDATE rmd SET rmd.RESULTADO = '''', rmd.RESULTADO_ID = 0
					FROM SmsRemesasMuñozDay rmd 
					INNER JOIN #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT

					--Actualizamos resultado para FLAG B
					UPDATE rmd SET rmd.RESULTADO = ''FLAG B'', rmd.RESULTADO_ID = 1, rmd.RESULTADO_ENVIO = 0
					FROM SmsRemesasMuñozDay rmd
					inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
					inner join ccSmsSegmentFlagB sfb on rmd.Fila = sfb.Validation
					WHERE rmd.RESULTADO_ID = 0 AND sfb.IsActive = 1

					--Actualizamos resultado para Telefono fijo y telefono no existe
					UPDATE rmd SET 
					rmd.RESULTADO = CASE 
						WHEN dbo.VerifySmsMCA(rmd.TELEFONOS1) = 3 THEN ''NO ES POSIBLE ENVIO, CELUAR NO SE ENCUENTRA EN IFT''
						WHEN dbo.VerifySmsMCA(rmd.TELEFONOS1) = 5 THEN ''TELEFONO FIJO''
						ELSE '''' END,
					rmd.RESULTADO_ID = dbo.VerifySmsMCA(rmd.TELEFONOS1),
					rmd.RESULTADO_ENVIO = 0
					FROM SmsRemesasMuñozDay rmd
					inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
					WHERE rmd.RESULTADO_ID = 0

					--Regla de Estado Funcional para segmento BMX_122
					UPDATE rmd SET rmd.RESULTADO = ''NO SE ENVIA POR REGLA DE ESTADO FUNCIONAL'', rmd.RESULTADO_ID = 4, rmd.RESULTADO_ENVIO = 0
					FROM SmsRemesasMuñozDay rmd
					inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
					WHERE rmd.RESULTADO_ID = 0 AND rmd.SegmentoMC = ''BMX_122''
					AND ESTADO_FUNCIONAL <> ''F''

					INSERT INTO #functionalState
					select rid.creditId, count(rid.creditId) from smsccoLogDial ld
					inner join #SmsRemesasIdTemp rid on rid.TDCT = ld.registryClient
					where ld.smsDate >= @WeekStart
					GROUP BY rid.creditId

					UPDATE rmd SET rmd.RESULTADO = ''NO SE ENVIA POR REGLA DE ESTADO FUNCIONAL'', rmd.RESULTADO_ID = 4, rmd.RESULTADO_ENVIO = 0
					FROM SmsRemesasMuñozDay rmd
					inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
					inner join #functionalState fs on rmd.id_credito = fs.creditId
					WHERE rmd.RESULTADO_ID = 0 AND rmd.SegmentoMC = ''BMX_122''
					AND fs.smsSent >= 3;


					declare @subQuery nvarchar(max)
					
					SELECT @monday= DATEADD(DAY, -(DATEPART(WEEKDAY, @today) + @@DATEFIRST - 2) % 7, CAST(@today AS DATE))
					
					if not exists(select * from ccSmsValidateRegistryWeek)begin
						exec ccspLoadRegistrySegments @action=11
					end
					

					declare @conditionId int,@segmentId int,@SubConditionId int
					declare @conditionWhere varchar(max)
					declare @SubConditionWhere varchar(max),@LogicConector varchar(20)
					declare @DailyLimit int,@WeeklyLimit int
					declare @SegmentName varchar(255)

					DECLARE @Params NVARCHAR(MAX)
					SET @Params = N''@WeeklyLimit int,@DailyLimit int'';
					
				---Lista de @segmentIds
				while exists(select * from @segmentTable where status=0) begin
					select top 1 @segmentId=id from @segmentTable where status=0		
					set @conditionId=0
					-------------------------------- Revisa las condiciones por segmentId --------------------------------
					while exists(select * from ccSmsConditions where SegmentId=@segmentId and ConditionId>@conditionId) begin
						
						SELECT @SegmentName = [Name] from ccSmsSegments where SegmentId = @segmentId

						select top 1
						@DailyLimit=DailyLimit,	@WeeklyLimit=WeeklyLimit,@conditionId=ConditionId,
						@conditionWhere= PrimaryField+LogicOperator
						+case when isnull(ComparisonValue,'''') <>'''' then ComparisonValue else''(''+ ComparisonField end 					
						+case when isnull(ComparisonValue,'''') <>'''' or  isnull(ArithmeticOperator,'''')='''' or isnull(Value,'''')=''''then '''' else isnull(ArithmeticOperator,'''')+isnull(Value,'''') end 
						+case when isnull(ComparisonValue,'''') <>'''' then '''' else'')'' end 
						from ccSmsConditions where SegmentId=@segmentId and ConditionId>@conditionId
						
						set @SubConditionId=0
						while exists(select * from ccSmsSubconditions where ConditionId=@conditionId and SubconditionId>@SubConditionId) 
						begin
						
							select top 1
							@LogicConector=LogicConector,
							@SubConditionId=SubconditionId,
							@SubConditionWhere=
							PrimaryField+LogicOperator
							+case when isnull(ComparisonValue,'''') <>'''' then ComparisonValue else''(''+ ComparisonField end 					
							+case when isnull(ComparisonValue,'''') <>'''' or  isnull(ArithmeticOperator,'''')='''' or isnull(Value,'''')='''' then '''' else isnull(ArithmeticOperator,'''')+isnull(Value,'''') end
							+case when isnull(ComparisonValue,'''') <>'''' then '''' else'')'' end 
							from ccSmsSubconditions where ConditionId=@conditionId and SubconditionId>@SubConditionId

							set @conditionWhere=@conditionWhere+'' ''+ @LogicConector+'' '' +@SubConditionWhere

							
						end
							
						insert into @conditionTable values(@conditionId,@conditionWhere,@DailyLimit,@WeeklyLimit,0, @SegmentName)	
					end 
					-------------------------------- Termina las condiciones por segmentId --------------------------------
					update @segmentTable set status=1 where id=@segmentId
				end
				while exists(select * from @conditionTable where status=0) begin		
					select top 1 
					@conditionId=conditionId, @DailyLimit=DailyLimit, @WeeklyLimit=WeeklyLimit,	@conditionWhere=smsCondition,
					@SegmentName = SegmentName
					from @conditionTable 
					where status=0
					
					set @subQuery= ''select A.id_credito, A.TDCT from SmsRemesasMuñozDay A with(nolock)
					left join ccSmsValidateRegistryWeek B on A.credito=B.registryClient and B.total<@WeeklyLimit and B.totaltoDay<@DailyLimit
					where  SegmentoMC in ('''''' + @SegmentName + '''''') AND RESULTADO_ID = 0 AND '' + @conditionWhere	
					print(@subQuery)
					insert into #SmsRemesasId
					EXEC sp_executesql @subQuery,@Params,@WeeklyLimit,@DailyLimit;
					update @conditionTable set status=1 where @conditionId=conditionId
				end

				--Actualizamos los ids que no coindiden
				UPDATE rmd SET rmd.RESULTADO = ''CUENTA CON T. Celular para envio de sms'' , rmd.RESULTADO_ID = 6
				FROM SmsRemesasMuñozDay rmd
				INNER JOIN #SmsRemesasId rid on rid.TDCT = rmd.TDCT
				WHERE RESULTADO_ID = 0;

				--Actualizamos todo lo que no cumple
				UPDATE rmd SET rmd.RESULTADO = ''NO CUMPLE CON REGLA DE CORTE'' , rmd.RESULTADO_ID = 2, rmd.RESULTADO_ENVIO = 0
				FROM SmsRemesasMuñozDay rmd
				INNER JOIN #SmsRemesasIdTemp rid on rid.TDCT = rmd.TDCT
				WHERE RESULTADO_ID = 0;
					
				if @action=12 begin
					declare @countValidate int,@nonValid int
					select @countValidate=count(1) from SmsRemesasMuñozDay A with(nolock)
					inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID = 6

					select @nonValid=count(1) from SmsRemesasMuñozDay A with(nolock)
					inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID <> 6

					INSERT INTO SmsSegmentsValidationResult(id_credito, credito, TELEFONOS1, TDCT, RESULTADO, RESULTADO_ID, validation_date)
					SELECT A.id_credito, A.credito, TELEFONOS1, A.TDCT, A.RESULTADO, A.RESULTADO_ID, GETDATE() FROM SmsRemesasMuñozDay A
					inner join #SmsRemesasIdTemp b on A.TDCT = b.TDCT

					select @countValidate as ValidRecords,@nonValid as InvalidRecords
				end
				else begin
					DECLARE @tableName VARCHAR(20) = ''TEMPO_''+convert(varchar(10),@camId)
					DECLARE @columnsWithTypes VARCHAR(MAX)
					DECLARE @newColumns VARCHAR(MAX)
					DECLARE @createTable VARCHAR(MAX)
					DECLARE @insertInto VARCHAR(MAX)

					SELECT 
						@columnsWithTypes = COALESCE(@columnsWithTypes + '', '', '''') + 
						QUOTENAME(COLUMN_NAME) + '' '' + DATA_TYPE + 
						CASE 
							WHEN DATA_TYPE IN (''char'', ''varchar'', ''nchar'', ''nvarchar'', ''binary'', ''varbinary'') THEN ''('' + 
								CASE 
									WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN ''MAX'' 
									ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR)
								END + '')''
							WHEN DATA_TYPE IN (''decimal'', ''numeric'') THEN ''('' + CAST(NUMERIC_PRECISION AS VARCHAR) + '','' + CAST(NUMERIC_SCALE AS VARCHAR) + '')''
							ELSE ''''
						END,
						@newColumns = COALESCE(@newColumns + '', '', '''') + QUOTENAME(COLUMN_NAME)
					FROM INFORMATION_SCHEMA.COLUMNS
					WHERE TABLE_NAME = ''SmsRemesasMuñozDay'' AND COLUMN_NAME in (select value from dbo.fn_RIASplitDelimited(@columns,'',''))

					SET @createTable = ''IF EXISTS (SELECT * FROM sys.tables WHERE name = N'''''' + @tableName +'''''')
					BEGIN
						DROP TABLE '' + @tableName + ''
					END
						CREATE TABLE '' + @tableName + '' (
							Record_id INT IDENTITY(1,1) PRIMARY KEY, ActiveRecord BIT DEFAULT(0),PhoneStatus int, callout_id int, DataPhone varchar(100), cal_Key varchar(40), cal_telephone varchar(40) default(''''''''), 
							'' + @columnsWithTypes + '');''
					print(@createTable)
					EXEC (@createTable)
					
					set @sql=''INSERT INTO '' + @tableName + '' (PhoneStatus, callout_id, DataPhone, cal_Key, cal_telephone,'' + @newColumns + '')
					select 0 PhoneStatus,0 callout_id,convert(varchar(100),'''''''') as DataPhone, A.TDCT, TELEFONOS1, ''+@newColumns+''
					from SmsRemesasMuñozDay A with(nolock) inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID = 6''
					print(@sql)
					exec(@sql)
					set @sql = ''IF EXISTS (SELECT * FROM sys.tables WHERE name = N'''''' + @tableName +''_ids'''')
					BEGIN
						DROP TABLE '' + @tableName + ''_ids
					END
					Create table '' + @tableName + ''_ids (Record_id int)'';
					exec(@sql)
				end
				drop table #SmsRemesasId
				drop table #SmsRemesasIdTemp
				drop table #functionalState
				end
				else if @action =14 begin 
					select MessageTemplate from ccSmsTemplate where TemplateId=@templateId
				end

				else if @action =15 begin --Obtener resultados de validación por segmentos

					DECLARE @counter int = 0
					DECLARE @ActualDay DATETIME = GETDATE();
					DECLARE @FirstDayMonth DATETIME = DATEADD(MONTH, DATEDIFF(MONTH, 0, @ActualDay),0)
					DECLARE @DayCounter DATETIME;
					DECLARE @WeekCount int = 0;

					WHILE @counter < DAY(@ActualDay)
					BEGIN
						SET @DayCounter =  DATEADD(DAY, @counter, @FirstDayMonth)
						IF DATEPART(WEEKDAY,@DayCounter) = 2
							SET @WeekCount = @WeekCount + 1
						print @DayCounter
						set @counter = @counter + 1
					END

					IF DATEPART(WEEKDAY, @FirstDayMonth) <> 2 BEGIN
						SET @WeekCount = @WeekCount + 1
					END

					declare @segments table(segmentName VARCHAR(10))

					insert into @segments
					select s.Name from dbo.fn_RIASplitDelimited(@segmentIds,'','') a
					inner join ccSmsSegments s on s.segmentId = a.value

					select	id_credito AS id_credit, credito AS credit, GETDATE() as snapshot_date, MESES_VENCIDOS as expired_month, SEG_CUENTA as seg_account,
							FILA as seg_row, LOCACION as [location], DIA_CORTE as cut_day, SegmentoMC as segment_mc, @WeekCount as [week], DATEPART(WEEKDAY, @ActualDay) week_day,
							TELEFONOS1 as phones1, RESULTADO as result, ISNULL(ESTADO_FUNCIONAL, '''') as functional_state, ISNULL(CORTE_REAL, '''')  as real_cut
					from SmsRemesasMuñozDay rmd
					inner join @segments s on rmd.SegmentoMC = s.segmentName;
					
				end'
	EXEC(@sql);

	set @process = 'K020109 drop sp ccsp_Limpia'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_Limpia'')
    begin
        DROP PROCEDURE ccsp_Limpia
    end'
	EXEC(@sql)

	set @process = 'K020109 create sp ccsp_Limpia en donde se ocupa la función dbo.verifica2 se le agregó un parametro DEFAULT'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_Limpia] @tel VARCHAR(50), @Camp INT = 0, @calKey VARCHAR(20) = ''''
AS
SET NOCOUNT ON

DECLARE @lon TINYINT, @cldLocal VARCHAR(7), @pais VARCHAR(3), @extLen SMALLINT, @specialDialPlan SMALLINT, @validateTel SMALLINT, @ld VARCHAR(7)
DECLARE @checkLd_In_ANILst SMALLINT = 0
/***
 4  as res lista Negra
 2 as res Digitos incorrectos Prefijo Marcacion 01,044,045,001
 3 as res Number notExists
 1 as res Longitud invalida
 0 as res Numero correcto
 
***/
SELECT @tel = dbo.limpia(@tel)

SELECT @lon = len(@tel)

SELECT @pais = valor
FROM ccSettings WITH (NOLOCK)
WHERE setting_id = 104

SELECT @cldLocal = valor
FROM ccSettings WITH (NOLOCK)
WHERE setting_id = 17

SELECT @extLen = valor
FROM ccsettings WITH (NOLOCK)
WHERE setting_id = 108

SELECT @validateTel = valor
FROM ccsettings WITH (NOLOCK)
WHERE setting_id = 206

SELECT @checkLd_In_ANILst = valor FROM ccsettings WITH (NOLOCK) WHERE setting_id = 213


IF @lon > 1
BEGIN

	IF @validateTel = 2
		BEGIN --Setting 206 only validates blacklist
		
			IF (SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList
				RETURN (0)
			END
			SELECT 0 AS res, @tel AS tel

			RETURN (0)
	
	END
	IF @validateTel = 1
	BEGIN --Setting 206 para no validar longitud ni listas negras
		SELECT 0 AS res, @tel AS tel

		RETURN (0)
	END

	IF @extLen = @lon
	BEGIN -- Setting 108 validar el tamaño longitud del telefono
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList

			RETURN (0)
		END

		SELECT 0 AS res, @tel AS tel -- Extension

		RETURN (0)
	END
END

DECLARE @telTemp AS VARCHAR(15)

SELECT @telTemp = @tel

IF @pais = 1
BEGIN ---Mexico
	IF @lon = 3 AND @tel = ''911''
	BEGIN
		SELECT 4 AS res, @tel AS tel --Lista Negra

		RETURN (0)
	END

	IF (@lon < 10)
	BEGIN
		SELECT 1 AS res, @tel AS tel --Longitud invalida

		RETURN (0)
	END

	IF @lon = 12 AND left(@tel, 2) <> ''01'' OR @lon = 13 AND left(@tel, 3) NOT IN (''044'', ''045'') AND left(@tel, 3) <> ''001''
	BEGIN
		SELECT 2 AS res, @tel AS tel --Digitos incorrectos

		RETURN (0)
	END

	IF left(@tel, 3) = ''001''
	BEGIN
		SELECT 0 AS res, @tel AS tel

		RETURN (0)
	END

	SELECT @tel = right(@tel, 10)

	IF (
			SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
			) = 1
	BEGIN
		SELECT 4 AS res, @tel AS tel --blackList

		RETURN (0)
	END
	
	If (@Camp > 0 AND @checkLd_In_ANILst = 1)
	BEGIN
		If(SELECT len(ani) FROM ccCamps WHERE cam_id = @Camp) > 0  --Permitir todos los telefonos a 10 digitos cuando existe un ani configurado en la campana.	
		BEGIN
			SELECT 0 AS res, @tel AS tel	
			RETURN (0)
		END

		IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
				  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
				  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 3))
		BEGIN
			SELECT 0 AS res, @tel AS tel
			RETURN (0)
		END
		ELSE IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
				  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
				  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 2))
		BEGIN
			SELECT 0 AS res, @tel AS tel
			RETURN (0)
		END
	END


	SELECT @tel = dbo.Verifica2(@tel, 1, @cldLocal, DEFAULT, DEFAULT)

	IF LEFT(@tel, 1) = ''E''
	BEGIN
		SELECT 3 AS res, @telTemp AS tel --No encontrado

		RETURN (0)
	END

	SELECT 0 AS res, @tel AS tel

	RETURN (0)
END
ELSE IF @pais = 2
BEGIN --Argentina 
	SET @tel = dbo.completa(@tel, @pais, @cldLocal)

	IF left(@tel, 1) = ''E''
	BEGIN
		SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

		RETURN (0)
	END

	SELECT @tel = dbo.fnClearPhoneArg(@tel)

	IF (len(@tel) = 10 OR len(@cldLocal + @tel) = 10) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos      
	END

	RETURN (0)
END
ELSE IF @pais = 3
BEGIN --Colombia  
	IF @lon < 7 OR @lon = 9 OR (@lon = 10 AND left(@telTemp, 1) <> ''3'') OR (@lon = 11 AND left(@telTemp, 2) <> ''03'')
	BEGIN
		SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

		RETURN (0)
	END

	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (8, 10)) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 4
BEGIN --USA 
	EXEC ccsp_LimpiaUsa @tel, @Camp, @calKey

	RETURN (0)
END
ELSE IF @pais = 5
BEGIN --Chile  
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF len(@tel) IN (8, 9) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 6
BEGIN --Venezuela    
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF len(@tel) = 10 AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 7
BEGIN --Reino Unido
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (9, 10)) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 8
BEGIN --Arabia saudita   
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (9, 10, 11))
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais IN (9, 10, 11, 12, 13, 14, 15, 16)
BEGIN --9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:España 15:Peru, 16: Panama 
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF left(@tel, 1) = ''E''
	BEGIN
		SELECT 1 AS res, @telTemp --Longitud Invalida   
	END
	ELSE IF (
			SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
			) = 1
	BEGIN
		SELECT 4 AS res, @tel AS tel --blackList      
	END
	ELSE
	BEGIN
		SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

		IF left(@tel, 1) = ''E''
		BEGIN
			SELECT 2 AS res, @telTemp --Digitos Incorrectos ??? debe ser numero no existe
		END

		SELECT 0 AS res, @tel AS tel
	END

	RETURN (0)
END'
	EXEC(@sql);

	set @process = 'K020109 drop sp ccsp_WhatsAppLoader'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_WhatsAppLoader'')
    begin
        DROP PROCEDURE ccsp_WhatsAppLoader
    end'
	EXEC(@sql)

	set @process = 'K020109 create sp ccsp_WhatsAppLoader es es un sp nuevo'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_WhatsAppLoader]
	-- Add the parameters for the stored procedure here
	@action TINYINT =NULL,
	@tableTemp VARCHAR(100) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF(@action = 1) -- Get phone loaded with phoneType
	BEGIN

		DECLARE @columnList NVARCHAR(MAX);
		DECLARE @sql NVARCHAR(MAX);

		-- Obtener la lista de columnas excluyendo ''column1''
		SELECT @columnList = STRING_AGG(name, '', '') 
		FROM sys.columns 
		WHERE object_id = OBJECT_ID(@tableTemp) 
		AND name <> ''phoneType'';

		-- Construir la consulta SQL dinámica
		SET @sql = ''
		;WITH CTE AS (
		SELECT  dbo.Verifica2(cal_telephone,1,0,0,1) as phoneType, '' + @columnList + '',
		ROW_NUMBER() OVER (PARTITION BY cal_Key ORDER BY Record_id) AS rn FROM''+ QUOTENAME(@tableTemp) + ''
		)
		SELECT *
		FROM CTE
		WHERE rn = 1
		ORDER BY Record_id ASC
		'';

		-- Ejecutar la consulta dinámica
		EXEC sp_executesql @sql;
	END
END'
	EXEC(@sql);

	set @process = 'K020109 drop sp ccsp_GalateaAdminRotativeANI'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminRotativeANI'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminRotativeANI
    end'
	EXEC(@sql)

	set @process = 'K020109 create sp ccsp_GalateaAdminRotativeANI se añadio el @loadTYpe y se modfico el @type = 10, para que filtre por el @loadType en la línea 2683 y 2685'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminRotativeANI]
			@type SMALLINT,
			@idArea SMALLINT = NULL,
			@descriptionList VARCHAR(50) = NULL,
			@id_RAniList SMALLINT = NULL,
			@PageIndex      INT = 0,
			@PageSize       INT = 0,
			@UserId			SMALLINT = 0,
			@LoadType SMALLINT = 0

		AS
		BEGIN
			SET NOCOUNT ON;

			IF (@type = 1) -- Read Rotative ANI List Catalog
			BEGIN
        SELECT CAST(cral.id_RAniList AS SMALLINT) id_RAniList,
					   cral.description,
					   cral.idArea
				FROM dbo.ccRotativeANIList AS cral
				WHERE cral.idArea IN (@idArea,-1) 
				AND cral.id_RAniList = ISNULL(@id_RAniList, cral.id_RAniList);
				RETURN 0;
			END;
			IF (@type = 2)
			BEGIN
				SELECT * 
				FROM
					(SELECT ROW_NUMBER() OVER(ORDER BY loadDate ASC) AS RowNum,
                CAST(id_RAniList AS SMALLINT) id_RAniList,
						telAni,
						loadDate
					FROM dbo.ccRotativeANIListDetail
					WHERE id_RAniList = @id_RAniList) tmp
				WHERE  tmp.RowNum > @PageSize * (@PageIndex - 1)
				AND tmp.RowNum <= @PageSize * @PageIndex
				RETURN 0;
			END;
			If @type=3 --Create Rotative ANI List
			begin
				declare @newANILstId SMALLINT = -1 --Name in use

				if not exists(select id_RAniList from ccRotativeANIList where description = @descriptionList)
				begin
					insert into ccRotativeANIList (description,idArea) values(@descriptionList, @idArea)
					select @newANILstId = SCOPE_IDENTITY() 
				end

				select @newANILstId as [result]
				return(0)
			end
			If @type=4 --Update Rotative ANI List
			begin
				declare @idAreaOfExistingLst smallint

				select @idAreaOfExistingLst = idArea from ccRotativeANIList where id_RAniList = @id_RAniList
				if(@idAreaOfExistingLst = -1 and @idArea <> @idAreaOfExistingLst)   --Changing from global to particular idArea
				begin
					if exists(select cam_id from ccCamps where IDArea <> @idArea and id_anilist = @id_RAniList and ISNULL(rotativeAlgo, 0) > 0)
					begin
						select -2 as [result] --Cant change idArea cause the ANI list is related to camps on other IDArea
						return(0)
					end
				end

				if exists(select id_RAniList from ccRotativeANIList where [description] = @descriptionList and id_RAniList <> @id_RAniList)
				begin
					SELECT -1 as [result] --Name in use
					return(0)
				end
        
				update ccRotativeANIList set [description] = @descriptionList, idArea = @idArea where id_RAniList = @id_RAniList
				SELECT 1 as [result]
				return(0)
			end
			If @type=5 --Delete Rotative ANI List
			begin
				declare @result int = -2   --ANI list is related to campaign

				if not exists(select cam_id from ccCamps where id_anilist = @id_RAniList and ISNULL(rotativeAlgo, 0) > 0)
				begin
					delete ccRotativeANIListDetail where id_RAniList = @id_RAniList
					delete ccRotativeANIList where id_RAniList = @id_RAniList
					select @result = 1
				end

				select @result as [result]
				return(0)
			END
			IF (@type = 6) -- Read Rotative ANI List By Id
			BEGIN
        SELECT CAST(cral.id_RAniList AS SMALLINT) id_RAniList,
					   cral.description,
					   cral.idArea
				FROM dbo.ccRotativeANIList AS cral
				WHERE cral.id_RAniList = @id_RAniList
				RETURN 0;
			END

			IF (@type = 7) -- Get List size
			BEGIN
				SELECT COUNT(*) AS listSize FROM dbo.ccRotativeANIListDetail WHERE id_RAniList = @id_RAniList
				RETURN 0;
			END
			IF(@type = 8) --Check if exist an other process executing
			BEGIN 
				SELECT CASE WHEN COUNT(crl.load_id) > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS isProcessExecuting FROM dbo.ccRIALoading AS crl
				WHERE crl.cam_id = @id_RAniList AND crl.state IN (0,2) AND crl.loadType = 2;
				RETURN (0);
			END
			IF(@type = 9) --Check if exist a campaign executing
			BEGIN
				SELECT CASE WHEN COUNT(cc.cam_id) > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS isCampaignExecuting   FROM dbo.ccCamps AS cc
				WHERE cc.id_anilist = @id_RAniList AND cc.rotativeAlgo IN (1,2,3)
				AND cc.cam_procesando = 1
				RETURN 0;
			END
			IF(@type = 10) --Update current Rotative ANI List loads to error
			BEGIN
				IF(@UserId = 0)
				BEGIN
            					UPDATE ccRIALoading SET [state] = 4 WHERE loadType = @LoadType AND [state] < 3
				END
				UPDATE ccRIALoading SET [state] = 4
        				WHERE loadType = @LoadType AND [state] < 3 AND userID = @UserId 
				SELECT CASE WHEN @@ROWCOUNT > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS LoadError
				RETURN 0;
			END
			IF(@type = 11) -- Get campaign and area by ani list id
			BEGIN
				SELECT cc.id_anilist, crg.frame, cc.cam_descripcion,crca.AreaName
				FROM dbo.ccCamps AS cc INNER JOIN dbo.ccRIACat_Areas AS crca ON crca.IDArea = cc.IDArea
				INNER JOIN dbo.ccRIACampsGraph AS crcg ON crcg.cam_id = cc.cam_id
				INNER JOIN dbo.ccRIAGraphics AS crg ON crg.graphic_id = crcg.graphic_id
				WHERE cc.id_anilist = @id_RAniList AND cc.rotativeAlgo IN (1,2,3)
			END
		SET NOCOUNT OFF

		END'
	EXEC(@sql);
	-------------------------------- K020109 --------------------
	--------------------------------  K020134, K002089                ---------------------------
	set @process = 'K020134, K002089 drop sp ccsp_MultimediaCommon'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_MultimediaCommon'')
    begin
        DROP PROCEDURE ccsp_MultimediaCommon
    end'
	EXEC(@sql)

	set @process = 'K020134, K002089 create sp ccsp_MultimediaCommon se modificó el @Option 2, en la línea 2808 y 2847'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon]
                    @Option AS SMALLINT,
                    @inboundId AS SMALLINT = 0,
                    @conversationId AS INT = 0,
                    @ServiceType AS SMALLINT = 0,
                    @status as SMALLINT =0,
                    @messagesList as varchar(max) = '''',
                    @agentId AS SMALLINT = 0,
                    @CampType bit =0
                    AS
                    BEGIN
                        SET NOCOUNT ON;

                    IF @Option = 0 --  Get Campaigns Configuration List
                    BEGIN
                            SELECT CAST(campaign.cam_id AS INT) AS Id,
                                    campaign.cam_descripcion AS [Name],
                                    ISNULL(configuration.number, '''') AS Phone,
                                    CAST(graphics.graphic_id AS INT) AS GraphicId
                            FROM  ccCamps campaign 
                            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
                            INNER JOIN  ccWhatsAppNumbers configuration ON campaign.cam_id = configuration.camp_id where configuration.status != 0 AND campaign.CampType = 5
					UNION
					SELECT CAST(campaign.cam_id AS INT) AS Id, -- meta whatsapp
							campaign.cam_descripcion AS [Name],
							ISNULL(configuration.number, '''') AS Phone,
							CAST(graphics.graphic_id AS INT) AS GraphicId
					FROM  ccCamps campaign 
					INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
					INNER JOIN ccMetaWhatsAppNumbers configuration ON campaign.cam_id = configuration.Cam_Id where configuration.status != 0 AND campaign.CampType = 5   
                    END

                    ELSE IF @Option = 1 --  Get Acds Configuration List
                    BEGIN
                                                                
                        SELECT --inbound.chat AS ServiceType,
                        CAST(inbound.Inbound_id AS INT) AS Id,
                        inbound.descripcion AS [Name],
                        ISNULL(numbers.number, '''') AS Phone,
                        CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                        inbound.tNotas AS WrapUpTime,
                        CAST(graphics.graphic_id AS INT) AS GraphicId
                        FROM  ccInbound inbound
                        INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
                        INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
                        INNER JOIN ccWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.inboundId
                        where inbound.Status != 0 AND configuration.meanContactTypeId = 5 and numbers.status != 0 
				UNION
				SELECT -- meta whatsapp
				CAST(inbound.Inbound_id AS INT) AS Id,
				inbound.descripcion AS [Name],
				ISNULL(numbers.number, '''') AS Phone,
				CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
				inbound.tNotas AS WrapUpTime,
				CAST(graphics.graphic_id AS INT) AS GraphicId
				FROM  ccInbound inbound
				INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
				INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
				INNER JOIN ccMetaWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.Inbound_Id
				where inbound.Status != 0 AND configuration.meanContactTypeId = 5 and numbers.status != 0 
                    END

                    ELSE IF(@Option = 2)
                    BEGIN


                        DECLARE @OldAgentId INT = 0
                        DECLARE @OldConversationId INT = 0
                        if @campType =0 begin --ACD
                            SELECT  @OldAgentId = conv.agentId,
                                    @OldConversationId = rel.conversationIdBefore
                            FROM ccWhatsAppConversationsRelationship rel 
                            RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
                            WHERE rel.conversationIdAfter = @conversationId

                        SELECT
                        cast(i.chat as int) AS ServiceType,
                        cast(c.conversationId as int) as ConversationID,
                        c.clientId as ClientId,
                        cm.conexionInfo as [To],
                        cast(i.Inbound_id as int) as ACDId,
                        i.descripcion as ACDName,
                        cast(g.graphic_id as int) as ACDGraphicId,
                        cast(cm.closeConversationTime as int) as [TimeOut],
                        cast(cm.answerTimeOut as int) as [TimeOutWarning],
                        i.ExitWrapUpDisposition as [ExitWrapUpDisposition],
                        i.tNotas as [WrapUpTime],
                        i.ShowCalifWnd,
                        cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient],
                        ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent),0) as [SecTimeOutLastMessageAgent],
                        isnull(permission.AllowUnassign,0) as AllowUnassign,
                        isnull(permission.AllowSpam,0) as AllowSpam,
                        ISNULL(@OldAgentId, 0) AS OldAgentId,
                        ISNULL(@OldConversationId, 0) AS OldConversationId,
                        c.agentId AS AgentId,
                        ISNULL(c.IsAgentLoggingOut,0) AS IsAgentLoggingOut,
						ISNULL(cm.allowFileAttachments,0) AS AllowFileAttachments
                        from ccWhatsAppConversations c
                        left join ccInbound i on c.inboundId = i.Inbound_id 
                        left JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId    
                        LEFT JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
                        LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
                        LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId

                        where c.conversationId = @conversationId

                                                
                        End
                        ELSE BEGIN --Camp
                            SELECT  @OldAgentId = conv.agentId,
                                    @OldConversationId = rel.conversationIdBefore
                            FROM ccWhatsAppConversationsRelationshipOut rel 
                            RIGHT JOIN ccWhatsAppConversationsOut conv ON conv.conversationId = rel.conversationIdBefore
                            WHERE rel.conversationIdAfter = @conversationId

                            SELECT
                            cast(i.CampType as int) AS ServiceType,
                            cast(c.conversationId as int) as ConversationID,
                            c.clientId as ClientId,
                            c.phoneCamp as [To],
                            cast(i.cam_id as int) as ACDId,
                            i.cam_descripcion as ACDName,
                            cast(g.graphic_id as int) as ACDGraphicId,
                            cast(cm.closeConversationTime as int) as [TimeOut],
                            cast(cm.answerTimeoutClient as int) as [TimeOutWarning],
                            i.exitAssisted as [ExitWrapUpDisposition],              
                            cast(i.cam_tnotas as int) [WrapUpTime],
                            i.cam_ShowCalifWnd as ShowCalifWnd, 
                            cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient],
                            ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent),0) as [SecTimeOutLastMessageAgent],
                            isnull(permission.AllowUnassign,0) as AllowUnassign,
                            isnull(permission.AllowSpam,0) as AllowSpam,
                            ISNULL(@OldAgentId, 0) AS OldAgentId,
                            ISNULL(@OldConversationId, 0) AS OldConversationId,
                            c.agentId AS AgentId,
							ISNULL(cm.allowFileAttachments,0) AS AllowFileAttachments
                            FROM  ccWhatsAppConversationsOut c
                            LEFT JOIN  ccCamps i ON c.camId = i.cam_id 
                            LEFT JOIN  contactMeanOut cm  ON c.camId = cm.camp_id
                            LEFT JOIN ccRIACampsGraph g on g.cam_id = c.camId
                            LEFT JOIN ccLastMessageAgentByConversationOut lm ON lm.conversationId = c.conversationId
                            LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId

                            where c.conversationId = @conversationId
                        END
                    END
                    ELSE IF(@Option = 3)
                    BEGIN
                        if @campType =0 begin --ACD
                            SELECT
                            CAST(inbound.Inbound_id AS INT) AS Id,
                            inbound.descripcion AS Name,
                            ISNULL(configuration.conexionInfo, '''') AS Phone,
                            CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                            inbound.tNotas AS WrapUpTime,
                                CAST(graphics.graphic_id AS INT) AS GraphicId
                            FROM  ccInbound inbound
                            INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
                            INNER JOIN  contactMeanIn configuration ON (inbound.Inbound_id = configuration.inboundId and inbound.Inbound_id = @inboundId)
                        end
                        else begin
                        SELECT
                            CAST(campaign.cam_id AS INT) AS Id,
                            campaign.cam_descripcion AS Name,
                            ISNULL(configuration.conexionInfo, '''') AS Phone,
                            CAST(ISNULL(configuration.answerTimeoutClient, 0) AS int) AS TimeOut,
                            cast(campaign.cam_tnotas as int) AS WrapUpTime,
                            CAST(graphics.graphic_id AS INT) AS GraphicId
                            FROM  ccCamps campaign
                            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
                            INNER JOIN  contactMeanOut configuration ON (campaign.cam_id = configuration.camp_id and campaign.cam_id = @inboundId)
                        end
                    END
                    ELSE IF(@Option = 4)
                    Begin
                            declare @pathFile as varchar(max)
                            declare @filetype as varchar(5)
					DECLARE @mensajes TABLE(idMessage VARCHAR(150));
                            DECLARE @tmpMessageConversations TABLE(
							[messageId] VARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
                                ,[conversationId] INT NOT NULL
                                ,[timeStampMessage] DATETIME NOT NULL
                                ,[originType] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
                                ,[price] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
                                ,[messageIdUi] INT NULL
                                ,[currency] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                                ,[typeMessage] VARCHAR(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                                ,[content] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                                ,[clientNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                                ,[vonageNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                                ,[timeStampMessageUTC] DATETIME NULL
                                ,[messageStatus] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                            );

                        insert into @mensajes
                        select value from dbo.fn_RIASplitDelimited(@messagesList,'','')
                                                            
                            if(@CampType = 0)
                            BEGIN
                                INSERT INTO @tmpMessageConversations(messageId, conversationId, timeStampMessage, originType
                                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
                                messageStatus) 
                                select messageId, conversationId,timeStampMessageUTC timeStampMessage, originType
                                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
                                messageStatus
                            
                                FROM ccWAMessagesConversations  where messageId in (select idMessage from @mensajes)
                            END
                            if(@CampType = 1)
                            BEGIN
                                INSERT INTO @tmpMessageConversations(messageId, conversationId, timeStampMessage, originType
                                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
                                messageStatus) 
                                select messageId, conversationId,timeStampMessageUTC timeStampMessage, originType
                                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
                                messageStatus
                                FROM ccWAMessagesConversationsOut  where messageId in (select idMessage from @mensajes)
                            END
                            select @pathFile = valor from ccSettings where setting_id=230
                        select
                            messageId as MessageId,
                            messageStatus as Status,
                            originType as Origin,
                            case when originType =''Client'' then 3
                                    when originType =''Agent'' then 2
                                    when originType =''Admin'' then 1
                            else 0 end as OriginType,
                            timeStampMessage as [Timestamp],
                            case when typeMessage IN (''text'', ''template'')  then content else '''' end as Content,
                            typeMessage as Type,
                            case 
                                    when typeMessage not in( ''text'' ,''location'', ''file'', ''template'') then content
                                    else
                                        case
                                            when typeMessage = ''file'' then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) 
                                                    else '''' end
                                    end as Caption,
                            case 
                                    when originType = ''Client''
                                    then
                                        case
                                                when typeMessage = ''text'' or typeMessage = ''location''
                                                or (typeMessage = ''file'' and (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) = '''' )
                                            then ''''
                                                else char(92)+char(92)+''WhatsApp''+char(92)+char(92)+ CASE WHEN @CampType = 0 THEN ''INBOUND'' ELSE ''OUTBOUND'' END +char(92)+char(92)+cast(conversationId/1000 as varchar(30))+char(92)+char(92)+cast(conversationId as varchar(20))+char(92)+char(92)+ typeMessage + char(92)+char(92)+ messageId +
                                                case
                                                        when typeMessage = ''video'' then ''.mp4''
                                                        when typeMessage = ''image'' then ''.jpg''
                                                        when typeMessage = ''audio'' then ''.mp3''
                                                        when typeMessage = ''file''
                                                        then (select substring(content, LEN(content) - CHARINDEX(''.'',REVERSE(content))+1, len(content)))
                                                    else '''' end
                                        end
                                    else
                                        case
                                            when typeMessage = ''text'' or typeMessage = ''location'' OR typeMessage = ''template''
                                            then ''''
                                            else content
                                    end
                                end as [Url],
                                case when typeMessage = ''file'' 
                                then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2)
                                else '''' end as [FileSize],
                                case when typeMessage = ''file'' 
                                then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2)
                                else '''' end as [FileName],
                            case when typeMessage = ''location''
                            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) else '''' end as [Address],
                            case when typeMessage = ''location''
                            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) else '''' end as [Lat],
                            case when typeMessage = ''location''
                            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [Long],
                            case when typeMessage = ''location''
                            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2) else '''' end as [Name],
                            case when typeMessage = ''location''
                            then ''https://www.google.com/maps/search/'' + (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) + '','' +
                                (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [LocationURL]
                                from @tmpMessageConversations
                            order by Timestamp asc

                    End
                                                                                
                    ELSE IF(@Option = 5)
                    BEGIN
                        if @CampType =0 begin
                            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
                                FROM contactMeanIn
                            WHERE inboundId = @inboundId
                        end 
                        else begin
                            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
                                FROM contactMeanOut
                            WHERE camp_id = @inboundId
                        end 
                    END
                    ELSE IF(@Option = 6)
                    BEGIN
                        SELECT [Login] AS ''OriginName''
                            FROM [CCenterRIA].[dbo].[ccUsers]
                        WHERE [User_id] = @agentId
                    END
               END'
	EXEC(@sql);
		------ K020134, K002089 ---------------
		-------------------------- END Marco García -------------------------------------------------------------------
		---------------------------------------------- GABY ------------------------------------------------------------
		SET @process = 'K020023 Update setting 270'
	SET @sql = ' update ccsettings2 set description=''WhatsApp messages by second (default: 80, max: 1000, min: 1)'' where setting_id=270';
	EXEC(@sql);
	-------------------------------------------------- END GABY --------------------------------------------------------------------

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
