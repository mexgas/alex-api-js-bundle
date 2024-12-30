/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio Chagolla
Date: 2024/09/30
Description: Release 126.20241218.0.0
Database: CCenterRia
Required version: 126.6
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
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 27
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
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end
IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END
IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY

	------------------------------------------- BEGIN IC ----------------------------------------
	SET @process = 'K020042 delete sp ccsp_WhatsAppOutboundTemplates'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_WhatsAppOutboundTemplates'')
    BEGIN
        DROP PROCEDURE ccsp_WhatsAppOutboundTemplates;
    END
    '
	EXEC(@sql)

    SET @process = 'K020042 create sp ccsp_WhatsAppOutboundTemplates'
	SET @sql = '
CREATE PROCEDURE ccsp_WhatsAppOutboundTemplates
@Action SMALLINT, 
@TemplateName VARCHAR(500) = '''',
@isMeta int=0,
@ConversationId INT = 0
AS  
SET NOCOUNT ON;  
IF @Action = 0  -- Get all template information
BEGIN	
	SELECT TemplateName, LanguageCode, Type, Format, Body FROM ccWhatsAppOutboundTemplates WHERE TemplateName = @TemplateName
END
IF @Action = 1  -- Get template body 
BEGIN
	if @isMeta =0 begin
		SELECT Body FROM ccWhatsAppOutboundTemplates WHERE TemplateName = @TemplateName
	end
	else begin
		SELECT
			header AS Header
		   ,body AS Body
		   ,footer AS Footer
		   ,Status AS StatusMeta
		   ,buttons AS Buttons
		   ,headerLink AS HeaderLink
		FROM ccMetaWAOutboundTemplates
		WHERE TemplateName = @TemplateName 
	end
END
					
IF @Action = 2  -- Get category from ccWhatsAppGlobalIds
BEGIN
	SELECT UPPER(wagi.Category) AS Category
	FROM ccWhatsAppGlobalIds wagi
	INNER JOIN ccWhatsAppGlobalIdsRelationship wagir ON wagi.GlobalId = wagir.GlobalId
	WHERE wagir.ConversationId = @ConversationId AND wagir.ConversationType = 1;
END

SET NOCOUNT OFF 
    '
	EXEC(@sql)


    -------------------------------------------- END IC -----------------------------------------

	------------------------------------------- BEGIN DM ----------------------------------------
	SET @process = 'delete sp ccsp_WAOUTGetLogDials'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_WAOUTGetLogDials'')
    BEGIN
        DROP PROCEDURE ccsp_WAOUTGetLogDials;
    END
    '
	EXEC(@sql)

    SET @process = 'Se cambia @Action 2 de como se obtiene la informaación del cuerpo de las plantillas'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_WAOUTGetLogDials]
	@Action				INT,
	@CamId				INT = NULL,
	@CamNumber			VARCHAR(50) = NULL,
	@ClientId			VARCHAR(50) = NULL,
	@ConversationId		INT = NULL,
	@MetaId				VARCHAR(1000) = NULL
	AS
	BEGIN

		DECLARE @LastMetaId VARCHAR(1000);
		DECLARE @Answered BIT;

		IF @Action = 1 -- Verifica para el último registro guardado en ccowhatslogdials si han pasado menos de 24 horas desde su envio 
		BEGIN
			DECLARE @InitialTime DATETIME;       
			DECLARE @LastConversationId BIGINT; 
			DECLARE @ConvId INT; 
        
			SET @InitialTime = DATEADD(HH, -24, GETDATE());

			SELECT TOP(1) @LastMetaId = cwld.MetaId, @LastConversationId = cwld.ConversationId,@Answered = cwld.answered, @ConvId = cwld.conversationId
			FROM ccoWhatsLogDials cwld WITH(NOLOCK)
			WHERE cwld.CamId = @CamID 
			AND cwld.PhoneWa = @CamNumber
			AND cwld.PhoneClient = @ClientId
			AND cwld.TimeSpam >= @InitialTime  
			ORDER BY cwld.TimeSpam DESC;

			IF @Answered = 0 
			BEGIN

				update ccowhatslogdials set answered = 1 where metaid = @LastMetaId
				update ccWhatsAppConversationsOut set conversationStatus = 1 where conversationId = @ConvId

				SELECT @LastMetaId AS MetaId, 
						@LastConversationId AS ConversationId;
			END
			ELSE
			BEGIN
				SELECT '''' AS MetaId, 
						CAST(0 AS BIGINT) AS ConversationId;
			END
		END

		ELSE IF @Action = 2 -- Obtiene el texto del mensaje de plantilla enviado masivamente
		BEGIN
			SELECT wld.timeSpam as TimeStamp, waos.MessageContent as Content, wld.CamId as CamId 
			FROM ccoWhatsLogDials wld 
			JOIN ccWhatsAppOutSource waos ON wld.WaOutId = waos.WAOut_Id
			JOIN ccMetaWAOutboundTemplates mwat ON waos.TemplateId = mwat.Id WHERE wld.MetaId = @MetaId; 
		END
	END'
	EXEC(@sql)


	SET @process = 'Delete SP ccsp_WhatsAppConversationHistory'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_WhatsAppConversationHistory'')
    BEGIN
        DROP PROCEDURE ccsp_WhatsAppConversationHistory;
    END
    '
	EXEC(@sql)

    SET @process = 'Se regresa MessageType en @Option=3  para que la UI sepa que tipo de mensaje es'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_WhatsAppConversationHistory]
    @Option smallint = null,
    @agentId smallint = null,
    @From datetime = null,
    @To datetime = null,
    @InboundIdsLst varchar(max) = null,
    @OutboundIdsLst varchar(max) = null,
    @ClientNumbersLst varchar(max) = null,   
    @MaxConversationHistory smallint = null,
    @ConversationIndex smallint = null,
    @ConversationId int = null,
    @ConversationIds  varchar(max) = null,
    @CamType bit = null,
    @CamId int = null,
    @ActualTime dateTime = null,
    @CamNumber varchar(max) = null,
    @ClientNumber varchar(max) = null,
    @AgentsIdsLst varchar(max) = null,
    @StatusLst varchar(max) = null

	AS
	BEGIN 
		DECLARE @MaxConversationHistoryTime INT = NULL;   
		DECLARE @MaxDaysPerWAConvo INT = NULL;            
		DECLARE @FinalMaxValue INT = NULL; 
		DECLARE @combinedCampsIn VARCHAR(MAX) = ''''
		DECLARE @combinedCampsOut VARCHAR(MAX) = ''''
		DECLARE @combinedInboundNames VARCHAR(MAX) = ''''
		DECLARE @combinedOutboundNames VARCHAR(MAX) = ''''

	IF @Option = 0 -- Obtiene filtros para agente 
	BEGIN   
		SELECT 
			@combinedCampsIn = ISNULL(STUFF((
				SELECT '','' + CAST(i.inbound_id AS VARCHAR)
				FROM ccInboundAgentes ia
				INNER JOIN ccInbound i ON ia.inbound_id = i.inbound_id
				WHERE ia.user_id = @agentId AND i.chat = 5
				FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), ''''),
        
			@combinedInboundNames = ISNULL(STUFF((
				SELECT '','' + i.descripcion
				FROM ccInboundAgentes ia
				INNER JOIN ccInbound i ON ia.inbound_id = i.inbound_id
				WHERE ia.user_id = @agentId AND i.chat = 5
				FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), '''');

		SELECT 
			@combinedCampsOut = ISNULL(STUFF((
				SELECT '','' + CAST(c.cam_id AS VARCHAR)
				FROM ccCampsAgente ca
				INNER JOIN ccCamps c ON ca.cam_id = c.cam_id
				WHERE ca.user_id = @agentId AND c.CampType = 5
				FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), ''''),
        
			@combinedOutboundNames = ISNULL(STUFF((
				SELECT '','' + c.cam_descripcion
				FROM ccCampsAgente ca
				INNER JOIN ccCamps c ON ca.cam_id = c.cam_id
				WHERE ca.user_id = @agentId AND c.CampType = 5
				FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), '''');

		IF @combinedCampsIn IS NOT NULL AND @combinedCampsIn <> ''''
		BEGIN
			IF OBJECT_ID(''tempdb..#TmpInboundIds'') IS NOT NULL DROP TABLE #TmpInboundIds;
			CREATE TABLE #TmpInboundIds (Id INT);
			INSERT INTO #TmpInboundIds (Id)
			SELECT CAST(value AS INT) 
			FROM dbo.fn_RIASplitDelimited(@combinedCampsIn, '','');
			SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
			FROM ccInbound i
			INNER JOIN #TmpInboundIds tmp ON tmp.Id = i.inbound_id;
			IF OBJECT_ID(''tempdb..#TmpInboundIds'') IS NOT NULL DROP TABLE #TmpInboundIds;
		END

		IF @combinedCampsOut IS NOT NULL AND @combinedCampsOut <> ''''
		BEGIN
			IF OBJECT_ID(''tempdb..#TmpOutboundIds'') IS NOT NULL DROP TABLE #TmpOutboundIds;
			CREATE TABLE #TmpOutboundIds (Id INT);
			INSERT INTO #TmpOutboundIds (Id)
			SELECT CAST(value AS INT) 
			FROM dbo.fn_RIASplitDelimited(@combinedCampsOut, '','');
			SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
			FROM contactMeanOut cmo 
			INNER JOIN #TmpOutboundIds tmp ON tmp.Id = cmo.camp_id;
			IF OBJECT_ID(''tempdb..#TmpOutboundIds'') IS NOT NULL DROP TABLE #TmpOutboundIds;
		END

		SET @FinalMaxValue = 
			CASE 
				WHEN @MaxConversationHistoryTime IS NULL THEN ISNULL(@MaxDaysPerWAConvo, 0)
				WHEN @MaxDaysPerWAConvo IS NULL THEN ISNULL(@MaxConversationHistoryTime, 0)
				ELSE CASE 
					WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
					ELSE @MaxDaysPerWAConvo
				END
			END;

		SELECT 
			ISNULL(@combinedCampsIn, '''') AS InboundIdsLst, 
			ISNULL(@combinedInboundNames, '''') AS InboundNamesLst, 
			ISNULL(@combinedCampsOut, '''') AS OutboundIdsLst, 
			ISNULL(@combinedOutboundNames, '''') AS OutboundNamesLst, 
			ISNULL(CAST(@FinalMaxValue AS SMALLINT), 0) AS MaxConversationHistory;
		END 
	END

	IF @Option = 1 -- Obtiene filtros de campañas para admin
	BEGIN
		DECLARE @campsIn VARCHAR(MAX) = ''''
		DECLARE @InboundNames VARCHAR(MAX) = ''''
		DECLARE @OutboundNames VARCHAR(MAX) = ''''
		DECLARE @campsOut VARCHAR(MAX) = ''''

		DECLARE @ClientIds VARCHAR(MAX) = ''''
		DECLARE @count INT
		DECLARE @id INT
		DECLARE @wg INT

		IF OBJECT_ID(''tempdb..#AgentsRelations'') IS NOT NULL 
			DROP TABLE #AgentsRelations;

		SELECT ROW_NUMBER() OVER(ORDER BY idWG ASC) AS Row,
				IDWG, @campsIn AS campsIn, @campsOut AS campsOut, 
				@InboundNames AS InboundNames, @OutboundNames AS OutboundNames
		INTO #AgentsRelations
		FROM ccRIAAreaWorkGroup wg
		WHERE EXISTS (
			SELECT 1 
			FROM ccRIAWorkGroupUsers wgu 
			WHERE wgu.IDWG = wg.IDWG 
				AND wgu.user_id = @agentId
		);

		SELECT @count = COUNT(idWG) FROM #AgentsRelations;
		SET @id = 1;

		WHILE @id <= @count
		BEGIN
			SELECT @wg = idwg FROM #AgentsRelations WHERE Row = @id;

			SET @campsIn = '''';
			SET @campsOut = '''';
			SET @InboundNames = '''';
			SET @OutboundNames = '''';

			SELECT @campsIn = ISNULL(@campsIn + CASE WHEN @campsIn = '''' THEN '''' ELSE '','' END + CONVERT(VARCHAR(12), inbound_id), @campsIn)
			FROM ccInbound i 
			INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = i.Inbound_id
			WHERE wg.IDWG = @wg AND wg.Tipo = 0 and i.chat = 5
			ORDER BY inbound_id;

			SELECT @campsOut = ISNULL(@campsOut + CASE WHEN @campsOut = '''' THEN '''' ELSE '','' END + CONVERT(VARCHAR(12), cam_id), @campsOut)
			FROM ccCamps c 
			INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = c.cam_id
			WHERE wg.IDWG = @wg AND wg.Tipo = 1 and c.CampType = 5
			ORDER BY cam_id;

			SELECT @InboundNames = ISNULL(@InboundNames + CASE WHEN @InboundNames = '''' THEN '''' ELSE '','' END + i.descripcion, @InboundNames)
			FROM ccInbound i
			WHERE i.Inbound_id IN (
				SELECT inbound_id FROM ccInbound 
				INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = i.Inbound_id
				WHERE wg.IDWG = @wg AND wg.Tipo = 0 and i.chat = 5
			)
			ORDER BY i.Inbound_id;

			SELECT @OutboundNames = ISNULL(@OutboundNames + CASE WHEN @OutboundNames = '''' THEN '''' ELSE '','' END + c.cam_descripcion, @OutboundNames)
			FROM ccCamps c
			WHERE c.cam_id IN (
				SELECT cam_id FROM ccCamps 
				INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = c.cam_id
				WHERE wg.IDWG = @wg AND wg.Tipo = 1 and c.CampType = 5
			)
			ORDER BY c.cam_id;

			IF @campsIn IS NOT NULL AND @campsIn <> ''''
				SET @combinedCampsIn = ISNULL(@combinedCampsIn + CASE WHEN @combinedCampsIn = '''' THEN '''' ELSE '','' END + @campsIn, @combinedCampsIn);

			IF @campsOut IS NOT NULL AND @campsOut <> ''''
				SET @combinedCampsOut = ISNULL(@combinedCampsOut + CASE WHEN @combinedCampsOut = '''' THEN '''' ELSE '','' END + @campsOut, @combinedCampsOut);

			IF @InboundNames IS NOT NULL AND @InboundNames <> ''''
				SET @combinedInboundNames = ISNULL(@combinedInboundNames + CASE WHEN @combinedInboundNames = '''' THEN '''' ELSE '','' END + @InboundNames, @combinedInboundNames);

			IF @OutboundNames IS NOT NULL AND @OutboundNames <> ''''
				SET @combinedOutboundNames = ISNULL(@combinedOutboundNames + CASE WHEN @combinedOutboundNames = '''' THEN '''' ELSE '','' END + @OutboundNames, @combinedOutboundNames);

			SET @id = @id + 1;
		END

		IF @combinedCampsIn IS NOT NULL AND @combinedCampsIn <> ''''
		BEGIN
			IF OBJECT_ID(''tempdb..#TmpInboundIds2'') IS NOT NULL DROP TABLE #TmpInboundIds2;

			CREATE TABLE #TmpInboundIds2 (Id INT);
			INSERT INTO #TmpInboundIds2 (Id)
			SELECT CAST(value AS INT) 
			FROM fn_RIASplitDelimited(@combinedCampsIn, '','');

			SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
			FROM ccInbound i
			INNER JOIN #TmpInboundIds2 tmp ON tmp.Id = i.Inbound_id;

			IF OBJECT_ID(''tempdb..#TmpInboundIds2'') IS NOT NULL DROP TABLE #TmpInboundIds2;
		END

		IF @combinedCampsOut IS NOT NULL AND @combinedCampsOut <> ''''
		BEGIN
			IF OBJECT_ID(''tempdb..#TmpOutboundIds2'') IS NOT NULL DROP TABLE #TmpOutboundIds2;

			CREATE TABLE #TmpOutboundIds2 (Id INT);
			INSERT INTO #TmpOutboundIds2 (Id)
			SELECT CAST(value AS INT) 
			FROM fn_RIASplitDelimited(@combinedCampsOut, '','');

			SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
			FROM contactMeanOut cmo 
			INNER JOIN #TmpOutboundIds2 tmp ON tmp.Id = cmo.camp_id;

			IF OBJECT_ID(''tempdb..#TmpOutboundIds2'') IS NOT NULL DROP TABLE #TmpOutboundIds2;
		END

		SET @FinalMaxValue = CASE 
			WHEN @MaxConversationHistoryTime IS NULL THEN @MaxDaysPerWAConvo
			WHEN @MaxDaysPerWAConvo IS NULL THEN @MaxConversationHistoryTime
			ELSE CASE 
				WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
				ELSE @MaxDaysPerWAConvo
			END
		END;

		SELECT 
			@combinedCampsIn AS InboundIdsLst, 
			@combinedInboundNames AS InboundNamesLst, 
			@combinedCampsOut AS OutboundIdsLst, 
			@combinedOutboundNames AS OutboundNamesLst, 
			ISNULL(CAST(@FinalMaxValue AS SMALLINT), 0) AS MaxConversationHistory;

		IF OBJECT_ID(''tempdb..#AgentsRelations'') IS NOT NULL 
			DROP TABLE #AgentsRelations;
		END

	IF @Option = 2 -- Obtiene agentes tomando en cuenta filtros de Inbound, Outbound, o Client Numbers
	BEGIN
		DECLARE @AgentIds VARCHAR(MAX) = '''';
		DECLARE @AgentLogins VARCHAR(MAX) = '''';
		DECLARE @AgentNames VARCHAR(MAX) = '''';
		DECLARE @AgentStatusList VARCHAR(MAX) = '''';
		DECLARE @CampType SMALLINT = 0;
		IF OBJECT_ID(''tempdb..#TmpCampAgentWg'') IS NOT NULL DROP TABLE #TmpCampAgentWg;
		CREATE TABLE #TmpCampAgentWg (Id INT);

		IF @InboundIdsLst IS NOT NULL AND @InboundIdsLst <> ''''
		BEGIN
			INSERT INTO #TmpCampAgentWg (Id)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
		END

		IF @OutboundIdsLst IS NOT NULL AND @OutboundIdsLst <> ''''
		BEGIN
			INSERT INTO #TmpCampAgentWg (Id)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
			SET @CampType = 1;
		END

		IF @ClientNumbersLst IS NOT NULL AND @ClientNumbersLst <> ''''
		BEGIN
			INSERT INTO #TmpCampAgentWg (Id)
			SELECT DISTINCT inboundId
			FROM ccWhatsAppConversations
			WHERE clientId IN (SELECT CAST(value AS BIGINT) FROM fn_RIASplitDelimited(@ClientNumbersLst, '',''));

			INSERT INTO #TmpCampAgentWg (Id)
			SELECT DISTINCT camId
			FROM ccWhatsAppConversationsOut
			WHERE clientId IN (SELECT CAST(value AS BIGINT) FROM fn_RIASplitDelimited(@ClientNumbersLst, '',''));
		END

		;WITH LatestStatus AS (
			SELECT 
				lad.User_id, 
				lad.currentStatus, 
				lad.fecha,
				ROW_NUMBER() OVER (PARTITION BY lad.User_id ORDER BY lad.fecha DESC) AS RowNum
			FROM ccLogAgentesDia lad
		)
		SELECT 
			@AgentIds = ISNULL(@AgentIds + CASE WHEN @AgentIds = '''' THEN '''' ELSE '','' END + CAST(u.User_id AS VARCHAR), ''''),
			@AgentLogins = ISNULL(@AgentLogins + CASE WHEN @AgentLogins = '''' THEN '''' ELSE '','' END + u.Login, ''''),
			@AgentNames = ISNULL(@AgentNames + CASE WHEN @AgentNames = '''' THEN '''' ELSE '','' END + u.Nombres + '' '' + u.ApellidoPaterno + '' '' + ISNULL(u.ApellidoMaterno, ''''), ''''),
			@AgentStatusList = ISNULL(@AgentStatusList + CASE WHEN @AgentStatusList = '''' THEN '''' ELSE '','' END + 
							   ISNULL(CASE WHEN ts.descripcion = ''Disponible'' THEN ''Ready'' ELSE ts.descripcion END, ''Unknown''), '''')
		FROM ccUsers u
		INNER JOIN ccRIAWorkGroupUsers wgu ON u.User_id = wgu.User_id
		INNER JOIN ccRIACampEspWG wg ON wg.IDWG = wgu.IDWG
		LEFT JOIN LatestStatus ls ON u.User_id = ls.User_id AND ls.RowNum = 1
		LEFT JOIN ccTipoStatusAgente ts ON ls.currentStatus = ts.TipoStatusAge_id
		WHERE wg.IdCampEsp IN (SELECT Id FROM #TmpCampAgentWg)
		  AND u.TipoUser_id = 1 
		  AND wg.Tipo = (CASE 
							WHEN ((@InboundIdsLst IS NULL OR @InboundIdsLst = '''') AND (@OutboundIdsLst IS NULL OR @OutboundIdsLst = '''') AND (ISNULL(@ClientNumbersLst, '''') <> ''''))
							THEN wg.Tipo
							ELSE @CampType
						END)
		GROUP BY u.User_id, u.Login, u.Nombres, u.ApellidoPaterno, u.ApellidoMaterno, ts.descripcion;

		SELECT @AgentIds AS AgentIdsList, @AgentLogins AS AgentLoginsList, @AgentNames AS AgentNamesList, @AgentStatusList AS AgentStatusList;

		IF OBJECT_ID(''tempdb..#TmpCampAgentWg'') IS NOT NULL DROP TABLE #TmpCampAgentWg;
	END
	DECLARE @PageSize INT = 10;
	DECLARE @TotalConversations INT = 0;
	DECLARE @Offset INT;

	IF @Option = 3 -- Obtiene paginado de conversaciones de acuerdo a filtros seleccionados para agente 
	BEGIN 
		DECLARE @ClientNumberTable TABLE (ClientNumber BIGINT);
		DECLARE @InboundIdTable TABLE (InboundId INT);
		DECLARE @OutboundIdTable TABLE (OutboundId INT);
    
		IF @ClientNumbersLst IS NOT NULL AND @ClientNumbersLst <> ''''
		BEGIN
			INSERT INTO @ClientNumberTable (ClientNumber)
			SELECT CAST(value AS BIGINT)
			FROM fn_RIASplitDelimited(@ClientNumbersLst, '','');
		END

		IF @InboundIdsLst IS NOT NULL AND @InboundIdsLst <> ''''
		BEGIN
			INSERT INTO @InboundIdTable (InboundId)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
		END

		IF @OutboundIdsLst IS NOT NULL AND @OutboundIdsLst <> ''''
		BEGIN
			INSERT INTO @OutboundIdTable (OutboundId)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
		END

		SELECT 
			@TotalConversations = COUNT(DISTINCT ConversationId)
		FROM (
			SELECT c.ConversationId 
			FROM ccWhatsAppConversations c
			LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
			WHERE c.AgentId = @agentId 
				AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
				AND c.requestDate BETWEEN @From AND @To
				AND m.content IS NOT NULL
				AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
				AND (@InboundIdsLst IS NULL OR c.InboundId IN (SELECT InboundId FROM @InboundIdTable))  
				AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)

			UNION ALL

			SELECT c.ConversationId 
			FROM ccWhatsAppConversationsOut c
			LEFT JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
			WHERE c.AgentId = @agentId 
				AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
				AND c.requestDate BETWEEN @From AND @To
				AND m.content IS NOT NULL
				AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
				AND (@OutboundIdsLst IS NULL OR c.camId IN (SELECT OutboundId FROM @OutboundIdTable))
				AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)
		) AS AllConversations;

		SET @Offset = (@ConversationIndex - 1); 

		DECLARE @RemainingConversations INT = @TotalConversations - @Offset;
		IF @RemainingConversations < @PageSize
			SET @PageSize = @RemainingConversations;

		IF @Offset >= @TotalConversations
		BEGIN
			SELECT TOP 0
				CAST(0 AS INT) AS ConversationId,
				CAST(0 AS INT) AS CamId,
				'''' AS CamNumber,
				CAST(0 AS SMALLINT) AS Frame,
				'''' AS ClientNumber,
				'''' AS MessageContent,
				'''' AS CamType,
				CAST(GETDATE() AS DATETIME) AS LastMessageDateTime,
				@TotalConversations AS ConversationsCount
			WHERE 1 = 0;
			RETURN;
		END

		;WITH LatestInboundMessages AS (
			SELECT 
				c.ConversationId,
				c.InboundId AS CampaignId,
				ci.descripcion AS CamName,
				c.phoneACD as CamNumber,
				g.graphic_id AS GraphicId,
				c.clientId AS ClientNumber,
				m.content AS MessageContent,
				m.typeMessage AS MessageType,
				m.TimeStampMessage AS LastMessageTimestamp,
				''Inbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn    
			FROM ccWhatsAppConversations c
			LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = c.InboundId
			LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
			LEFT JOIN ccinbound ci ON ci.inbound_id = c.inboundid
			WHERE c.AgentId = @agentId 
				AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
				AND c.requestDate BETWEEN @From AND @To
				AND m.content IS NOT NULL
				AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
				AND (@InboundIdsLst IS NULL OR c.InboundId IN (SELECT InboundId FROM @InboundIdTable))
				AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)
		),
    
		LatestOutboundMessages AS (
			SELECT 
				c.ConversationId,
				c.camId AS CampaignId,
				ca.cam_descripcion AS CamName,
				c.phoneCamp AS CamNumber,
				g.graphic_id AS GraphicId,
				c.clientId AS ClientNumber,
				m.content AS MessageContent,
				m.typeMessage AS MessageType,
				m.TimeStampMessage AS LastMessageTimestamp,
				''Outbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn  
			FROM ccWhatsAppConversationsOut c
			LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
			LEFT JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
			LEFT JOIN ccCamps ca ON ca.cam_Id = c.camid
			WHERE c.AgentId = @agentId 
				AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
				AND c.requestDate BETWEEN @From AND @To
				AND m.content IS NOT NULL
				AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
				AND (@OutboundIdsLst IS NULL OR c.camId IN (SELECT OutboundId FROM @OutboundIdTable))
				AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)
		),

		CombinedMessages AS (
			SELECT 
				ConversationId,
				CampaignId,
				CamNumber,
				CamName,
				GraphicId,
				ClientNumber,
				MessageContent,
				MessageType,
				LastMessageTimestamp,
				CampType
			FROM LatestInboundMessages
			WHERE rn = 1
        
			UNION ALL
        
			SELECT 
				ConversationId,
				CampaignId,
				CamNumber,
				CamName,
				GraphicId,
				ClientNumber,
				MessageContent,
				MessageType,
				LastMessageTimestamp,
				CampType
			FROM LatestOutboundMessages
			WHERE rn = 1
		)

		SELECT conversationId AS ConversationId,
			   CampaignId AS CamId,
			   CamNumber AS CamNumber,
			   CamName AS CamName,
			   CAST(GraphicId AS SMALLINT) AS Frame,
			   ClientNumber AS ClientNumber,
			   MessageContent AS MessageContent,
			   MessageType AS MessageType,
			   CampType AS CamType,
			   LastMessageTimestamp AS LastMessageDateTime,
			   @TotalConversations AS ConversationsCount
		FROM CombinedMessages
		ORDER BY LastMessageTimestamp DESC
		OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
	END;

	IF @Option = 4 -- Obtiene paginado de conversaciones de acuerdo a filtros seleccionados para administrador
	BEGIN
		-- Drop and recreate temporary tables
		IF OBJECT_ID(''tempdb..#ClientNumberTable'') IS NOT NULL DROP TABLE #ClientNumberTable;
		CREATE TABLE #ClientNumberTable (ClientNumber BIGINT);

		IF OBJECT_ID(''tempdb..#InboundIdTable'') IS NOT NULL DROP TABLE #InboundIdTable;
		CREATE TABLE #InboundIdTable (InboundId INT);

		IF OBJECT_ID(''tempdb..#OutboundIdTable'') IS NOT NULL DROP TABLE #OutboundIdTable;
		CREATE TABLE #OutboundIdTable (OutboundId INT);

		IF OBJECT_ID(''tempdb..#AgentIdTable'') IS NOT NULL DROP TABLE #AgentIdTable;
		CREATE TABLE #AgentIdTable (AgentId INT);

		IF OBJECT_ID(''tempdb..#StatusTable'') IS NOT NULL DROP TABLE #StatusTable;
		CREATE TABLE #StatusTable (StatusCategory VARCHAR(50));

		IF OBJECT_ID(''tempdb..#StatusIdTable'') IS NOT NULL DROP TABLE #StatusIdTable;
		CREATE TABLE #StatusIdTable (StatusId INT);

		DECLARE @IncludeQueued BIT = 0;

		-- Populate temporary tables based on input parameters
		IF ISNULL(@ClientNumbersLst, '''') <> ''''
		BEGIN
			INSERT INTO #ClientNumberTable (ClientNumber)
			SELECT CAST(value AS BIGINT)
			FROM fn_RIASplitDelimited(@ClientNumbersLst, '','');
		END

		IF ISNULL(@InboundIdsLst, '''') <> ''''
		BEGIN
			INSERT INTO #InboundIdTable (InboundId)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
		END

		IF ISNULL(@OutboundIdsLst, '''') <> ''''
		BEGIN
			INSERT INTO #OutboundIdTable (OutboundId)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
		END

		IF ISNULL(@AgentsIdsLst, '''') <> ''''
		BEGIN
			INSERT INTO #AgentIdTable (AgentId)
			SELECT CAST(value AS INT)
			FROM fn_RIASplitDelimited(@AgentsIdsLst, '','');
		END

		IF ISNULL(@StatusLst, '''') <> ''''
		BEGIN
			INSERT INTO #StatusTable (StatusCategory)
			SELECT LTRIM(RTRIM(value))
			FROM fn_RIASplitDelimited(@StatusLst, '','');
		END

		-- Map status categories to internal Status IDs
		INSERT INTO #StatusIdTable (StatusId)
		SELECT StatusId
		FROM (
			SELECT CASE 
				WHEN StatusCategory = ''active'' THEN messageStatusId
				WHEN StatusCategory = ''pre-assigned'' THEN 21
				WHEN StatusCategory = ''finished'' THEN messageStatusId
				ELSE NULL
			END AS StatusId
			FROM messageStatus
			INNER JOIN #StatusTable ON
				(StatusCategory = ''active'' AND messageStatusId IN (1, 2, 3, 5, 7, 8, 9))
				OR (StatusCategory = ''pre-assigned'' AND messageStatusId = 21)
				OR (StatusCategory = ''finished'' AND messageStatusId IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19))
		) AS MappedStatus
		WHERE StatusId IS NOT NULL;

		IF EXISTS (SELECT 1 FROM #StatusTable WHERE StatusCategory = ''queued'')
		BEGIN
			SET @IncludeQueued = 1;
		END

		-- Calculate total conversations based on filters for Inbound, Outbound, or Client-only cases

		-- Case 1: Inbound Conversations
		IF @InboundIdsLst IS NOT NULL 
		BEGIN
			WITH ConversationsWithMessages AS (
				-- Retrieve all conversations with messages
				SELECT DISTINCT c.ConversationId
				FROM ccWhatsAppConversations c
				INNER JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
				WHERE c.InboundId IN (SELECT InboundId FROM #InboundIdTable)
					AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
					AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
					AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
					OR (@IncludeQueued = 1 AND c.onQueue = 1))
			),
			LinkedConversations AS (
				-- Include conversations linked to ones with messages
				SELECT DISTINCT r.conversationIdAfter AS ConversationId
				FROM ccWhatsAppConversationsRelationship r
				INNER JOIN ConversationsWithMessages cm ON r.conversationIdBefore = cm.ConversationId
			)
			SELECT 
				@TotalConversations = COUNT(DISTINCT c.ConversationId)
			FROM ccWhatsAppConversations c
			WHERE c.ConversationId IN (
				-- Combine conversations with messages and linked conversations
				SELECT ConversationId FROM ConversationsWithMessages
				UNION
				SELECT ConversationId FROM LinkedConversations
			)
			AND c.InboundId IN (SELECT InboundId FROM #InboundIdTable)
			AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
			AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
			AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
			OR (@IncludeQueued = 1 AND c.onQueue = 1));
		END

		-- Case 2: Outbound Conversations
		ELSE IF @OutboundIdsLst IS NOT NULL
		BEGIN
			SELECT  
				@TotalConversations = COUNT(DISTINCT c.ConversationId)
			FROM ccWhatsAppConversationsOut c
			INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
			WHERE c.camId IN (SELECT OutboundId FROM #OutboundIdTable)
				AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND c.onQueue = 1))
		END

		-- Case 3: ClientNumbers only (when both Inbound and Outbound IDs are NULL)
		ELSE IF @ClientNumbersLst IS NOT NULL AND @TotalConversations = 0
		BEGIN
			DECLARE @InboundConversations INT = 0;
			DECLARE @OutboundConversations INT = 0;

			-- Count inbound conversations
			SELECT  
				@InboundConversations = COUNT(DISTINCT whatsIn.ConversationId)
			FROM ccWhatsAppConversations whatsIn
			INNER JOIN ccWAMessagesConversations m ON m.conversationId = whatsIn.ConversationId
			WHERE whatsIn.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatsIn.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR whatsIn.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND whatsIn.onQueue = 1));

			-- Count outbound conversations
			SELECT  
				@OutboundConversations = COUNT(DISTINCT whatOut.ConversationId)
			FROM ccWhatsAppConversationsOut whatOut
			INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = whatOut.ConversationId
			WHERE whatOut.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatOut.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR whatOut.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND whatOut.onQueue = 1));

			-- Sum the inbound and outbound counts
			SET @TotalConversations = @InboundConversations + @OutboundConversations;
		END

		-- Paginate results based on @ConversationIndex
		SET @Offset = ISNULL(@ConversationIndex, 1) - 1;

		IF @ConversationIndex >= @TotalConversations
		BEGIN
			SET @Offset = @TotalConversations - @PageSize;
			IF @Offset < 0 SET @Offset = 0;
		END

		-- Collect unique conversation IDs from Inbound and Outbound messages
		;WITH ExistingConversations AS (
			SELECT ConversationId FROM ccWhatsAppConversations WHERE InboundId IN (SELECT InboundId FROM #InboundIdTable)
			UNION
			SELECT ConversationId FROM ccWhatsAppConversationsOut WHERE camId IN (SELECT OutboundId FROM #OutboundIdTable)
		),
		-- Retrieve paginated conversations for Inbound, Outbound, or Client-only case

		LatestInboundMessages AS (
			SELECT 
				c.ConversationId,
				c.InboundId AS CampaignId,
				COALESCE(g.graphic_id, 0) AS GraphicId,
				COALESCE(c.clientId, '''') AS ClientNumber,
				COALESCE(m.content, '''') AS MessageContent,
				COALESCE(m.typeMessage, '''') AS MessageType,
				COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
				COALESCE(u.Login, '''') AS AgentLogin,
				CASE 
					WHEN c.onQueue = 1 AND c.conversationStatus = 8 THEN ''queued''
					WHEN c.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
					WHEN c.conversationStatus = 21 THEN ''pre-assigned''
					ELSE ''finished''
				END AS ConversationStatus,
				''Inbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
			FROM ccWhatsAppConversations c
			LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
			LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = c.InboundId
			LEFT JOIN ccUsers u ON u.User_id = c.AgentId
			WHERE 
				c.InboundId IN (SELECT InboundId FROM #InboundIdTable)
				AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND c.onQueue = 1))
		),
    
		LatestOutboundMessages AS (
			SELECT 
				c.ConversationId,
				c.camId AS CampaignId,
				COALESCE(g.graphic_id, 0) AS GraphicId,
				COALESCE(c.clientId, '''') AS ClientNumber,
				COALESCE(m.content, '''') AS MessageContent,
				COALESCE(m.typeMessage, '''') AS MessageType,
				COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
				COALESCE(u.Login, '''') AS AgentLogin,
				CASE 
					WHEN c.onQueue = 1 AND c.conversationStatus = 8 THEN ''queued''
					WHEN c.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
					WHEN c.conversationStatus = 21 THEN ''pre-assigned''
					ELSE ''finished''
				END AS ConversationStatus,
				''Outbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
			FROM ccWhatsAppConversationsOut c
			INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
			LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
			LEFT JOIN ccUsers u ON u.User_id = c.AgentId
			WHERE 
				c.camId IN (SELECT OutboundId FROM #OutboundIdTable)
				AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND c.onQueue = 1))
		),
    
		ClientOnlyMessages AS (
			-- Exclude conversations that already exist in ExistingConversations
			SELECT 
				whatsIn.ConversationId,
				whatsIn.InboundId AS CampaignId,
				COALESCE(g.graphic_id, 0) AS GraphicId,
				COALESCE(whatsIn.clientId, '''') AS ClientNumber,
				COALESCE(m.content, '''') AS MessageContent,
				COALESCE(m.typeMessage, '''') AS MessageType,
				COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
				COALESCE(u.Login, '''') AS AgentLogin,
				CASE 
					WHEN whatsIn.onQueue = 1 AND whatsIn.conversationStatus = 8 THEN ''queued''
					WHEN whatsIn.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
					WHEN whatsIn.conversationStatus = 21 THEN ''pre-assigned''
					ELSE ''finished''
				END AS ConversationStatus,
				''Inbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY whatsIn.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
			FROM ccWhatsAppConversations whatsIn
			INNER JOIN ccWAMessagesConversations m ON m.conversationId = whatsIn.ConversationId
			LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = whatsIn.InboundId
			LEFT JOIN ccUsers u ON u.User_id = whatsIn.AgentId
			WHERE 
				whatsIn.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatsIn.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR whatsIn.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND whatsIn.onQueue = 1))
				AND whatsIn.ConversationId NOT IN (SELECT ConversationId FROM ExistingConversations)

			UNION ALL

			SELECT 
				whatOut.ConversationId,
				whatOut.camId AS CampaignId,
				COALESCE(g.graphic_id, 0) AS GraphicId,
				COALESCE(whatOut.clientId, '''') AS ClientNumber,
				COALESCE(m.content, '''') AS MessageContent,
				COALESCE(m.typeMessage, '''') AS MessageType,
				COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
				COALESCE(u.Login, '''') AS AgentLogin,
				CASE 
					WHEN whatOut.onQueue = 1 AND whatOut.conversationStatus = 8 THEN ''queued''
					WHEN whatOut.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
					WHEN whatOut.conversationStatus = 21 THEN ''pre-assigned''
					ELSE ''finished''
				END AS ConversationStatus,
				''Outbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY whatOut.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
			FROM ccWhatsAppConversationsOut whatOut
			INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = whatOut.ConversationId
			LEFT JOIN ccRIACampsGraph g ON g.cam_id = whatOut.camId
			LEFT JOIN ccUsers u ON u.User_id = whatOut.AgentId
			WHERE 
				whatOut.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatOut.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR whatOut.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND whatOut.onQueue = 1))
				AND whatOut.ConversationId NOT IN (SELECT ConversationId FROM ExistingConversations)
		)

		-- Final result
		SELECT 
			CAST(ConversationId AS INT) AS ConversationId,
			CAST(CampaignId AS SMALLINT) AS CamId,
			CAST(GraphicId AS SMALLINT) AS Frame,
			CAST(ClientNumber AS VARCHAR(50)) AS ClientNumber,
			CAST(MessageContent AS VARCHAR(MAX)) AS MessageContent,
			CAST(MessageType AS VARCHAR(MAX)) AS MessageType, 
			CAST(LastMessageTimestamp AS DATETIME) AS LastMessageDateTime,
			CAST(AgentLogin AS VARCHAR(50)) AS AgentLogin,
			CAST(ConversationStatus AS VARCHAR(50)) AS ConversationStatus,
			CAST(CampType AS VARCHAR(50)) AS CamType,
			CAST(@TotalConversations AS INT) AS ConversationsCount
		FROM (
			SELECT * FROM LatestInboundMessages WHERE rn = 1
			UNION ALL
			SELECT * FROM LatestOutboundMessages WHERE rn = 1
			UNION ALL
			SELECT * FROM ClientOnlyMessages WHERE rn = 1
		) AS CombinedMessages
		ORDER BY ConversationId DESC
		OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
	END;
	
	IF @Option = 5 -- Obtiene número máximo de días a buscar por historial cuando se filtra por campañas 
	BEGIN 											
		IF OBJECT_ID(''tempdb..#TmpInboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpInboundIdsCampFilter;

		CREATE TABLE #TmpInboundIdsCampFilter (Id INT);

		INSERT INTO #TmpInboundIdsCampFilter (Id)
		SELECT CAST(value AS INT) 
		FROM fn_RIASplitDelimited(@InboundIdsLst, '','');

		SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
		FROM ccInbound i
		INNER JOIN #TmpInboundIdsCampFilter tmp ON tmp.Id = i.Inbound_id;

		IF OBJECT_ID(''tempdb..#TmpInboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpInboundIdsCampFilter;

		IF OBJECT_ID(''tempdb..#TmpOutboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpOutboundIdsCampFilter;

		CREATE TABLE #TmpOutboundIdsCampFilter (Id INT);

		INSERT INTO #TmpOutboundIdsCampFilter (Id)
		SELECT CAST(value AS INT) 
		FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');

		SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
		FROM contactMeanOut cmo 
		INNER JOIN #TmpOutboundIdsCampFilter tmp ON tmp.Id = cmo.camp_id;

		IF OBJECT_ID(''tempdb..#TmpOutboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpOutboundIdsCampFilter;

		SET @FinalMaxValue = CASE 
			WHEN @MaxConversationHistoryTime IS NULL THEN @MaxDaysPerWAConvo
			WHEN @MaxDaysPerWAConvo IS NULL THEN @MaxConversationHistoryTime
			ELSE CASE 
				WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
				ELSE @MaxDaysPerWAConvo
			END
		END;

		 SELECT CAST(@FinalMaxValue AS SMALLINT) AS MaxConversationHistory;
	END;

	IF @Option = 6 -- Obtener cabecera de varias conversaciones
	BEGIN 
		CREATE TABLE #TmpConversationIds (Id INT);
		INSERT INTO #TmpConversationIds (Id)
		SELECT CAST(value AS INT) 
		FROM fn_RIASplitDelimited(@ConversationIds, '','');

		IF @CamType = 0
		BEGIN 
			SELECT 
				cwc.conversationId AS ConversationId, 
				(CASE WHEN cwc.disposition = 0 THEN ''N/A'' ELSE ctc.Description END) AS Disposition,
				(CASE WHEN cwc.SubDisposition = 0 THEN ''N/A'' ELSE ctcs.califSubDesc END) AS SubDisposition, 
				cwc.inboundId AS CamId, 
				ISNULL(cwc.conversationDate, ''1900-01-01'') AS ConversationDate,
				(CASE 
					WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1)
						OR cwc.conversationStatus IN (1, 2, 3, 5, 7, 8, 9, 21)
						OR cwc.tConversation IS NULL THEN 0
					ELSE cwc.tConversation
				END) AS TConversation,
				0 AS CampType,
				ci.descripcion AS CampName,
				cwc.clientId AS PhoneNumber,
				(CASE 
					WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1) 
						OR cwc.conversationStatus IN (10, 17) 
						OR cu.User_id IS NULL THEN CONVERT(SMALLINT, 0)
					ELSE cu.User_id
				END) AS AgentId,
				(CASE 
					WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1) 
						OR cwc.conversationStatus IN (10, 17) 
						OR cu.User_id IS NULL THEN ''''
					ELSE cu.Nombres
				END) AS AgentName,
				ISNULL(CAST(mwn.Cam_Id AS SMALLINT), 0) AS ReopenWithTemplateOutboundCamId,
				ccc.cam_descripcion AS ReopenWithTemplateOutboundCamName
			FROM ccWhatsAppConversations cwc
			INNER JOIN ccInbound ci ON ci.inbound_id = cwc.inboundId
			LEFT JOIN ccUsers cu ON cu.User_id = cwc.agentId
			INNER JOIN #TmpConversationIds tci ON tci.Id = cwc.conversationId
			LEFT JOIN ccTipoCalif ctc ON ctc.calif_id = cwc.disposition
			LEFT JOIN ccTipoCalifSub ctcs ON ctcs.califSub_id = cwc.subDisposition
			LEFT JOIN ccMetaWhatsAppNumbers mwn ON mwn.Number = cwc.phoneACD
			LEFT JOIN cccamps ccc ON ccc.cam_Id = mwn.Cam_Id 
		END
		ELSE
		BEGIN
			SELECT 
				cwo.conversationId AS ConversationId, 
				(CASE WHEN cwo.disposition = 0 THEN ''N/A'' ELSE ctco.Description END) AS Disposition, 
				(CASE WHEN cwo.SubDisposition = 0 THEN ''N/A'' ELSE ctcso.califSubDesc END) AS SubDisposition,
				cwo.camId AS CamId, 
				ISNULL(cwo.conversationDate, ''1900-01-01'') AS ConversationDate, 
				(CASE 
					WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1)
						OR cwo.conversationStatus IN (1, 2, 3, 5, 7, 8, 9, 21)
						OR cwo.tConversation IS NULL THEN 0
					ELSE cwo.tConversation
				END) AS TConversation,
				1 AS CampType,
				cc.cam_descripcion AS CampName,
				cwo.clientId AS PhoneNumber,
				(CASE 
					WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1) 
						OR cwo.conversationStatus IN (10, 17) 
						OR cu.User_id IS NULL THEN CONVERT(SMALLINT, 0)
					ELSE cu.User_id
				END) AS AgentId,
				(CASE 
					WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1) 
						OR cwo.conversationStatus IN (10, 17) 
						OR cu.User_id IS NULL THEN ''''
					ELSE cu.Nombres
				END) AS AgentName,
				ISNULL(CAST(ccc.Cam_Id AS SMALLINT), 0) AS ReopenWithTemplateOutboundCamId,
				ccc.cam_descripcion AS ReopenWithTemplateOutboundCamName
			FROM ccWhatsAppConversationsOut cwo
			INNER JOIN ccCamps cc ON cc.cam_id = cwo.camId 
			LEFT JOIN ccUsers cu ON cu.User_id = cwo.agentId
			INNER JOIN #TmpConversationIds tci ON tci.Id = cwo.conversationId
			LEFT JOIN ccTipoCalifOUT ctco ON ctco.calif_id = cwo.disposition
			LEFT JOIN ccTipoCalifSubOUT ctcso ON ctcso.califSub_id = cwo.subDisposition
			LEFT JOIN ccMetaWhatsAppNumbers mwn ON mwn.Number = cwo.phoneCamp
			LEFT JOIN ccCamps ccc on ccc.cam_id = mwn.Cam_Id 
		END
	END

		DECLARE @MaxWhatsAllowed INT;
		DECLARE @ConversationCount INT;

	IF @Option = 8 -- Obtiene valor si se reabrirá o no la conversación y si será se reabrirá tipo entrada o salida
	BEGIN 
		IF NOT EXISTS (SELECT 1 FROM ccRIAAgentsPermissions WHERE AgentId = @AgentId AND AllowReopenWAConversation = 1)
		BEGIN
			SELECT ''REOPEN_PERMISSION_DISABLED'' AS ReopenConversationResponse;
			RETURN(0);
		END;

		IF @CamType = 0
		BEGIN
			IF EXISTS (SELECT 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent)) 
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM ccmetawhatsAppNumbers WHERE Number = @CamNumber AND Inbound_Id = @CamId)
				BEGIN
					SELECT ''CAMPAIGN_NUMBER_CHANGED'' AS ReopenConversationResponse;
					RETURN(0);
				END

				SELECT @MaxWhatsAllowed = a.maxWhats FROM ccinbound i INNER JOIN ccriacat_Areas a ON i.IDArea = a.IDArea WHERE i.Inbound_Id = @CamId;
				SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversations WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(HOUR, -24, GETDATE());

				IF @ConversationCount >= @MaxWhatsAllowed
				BEGIN
					SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationResponse;
					RETURN(0);
				END
				SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
				RETURN(0);
			END
			ELSE 
			BEGIN
				SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
				RETURN(0);
			END
		END

		IF @CamType = 1
		BEGIN
			IF EXISTS (SELECT 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent)) 
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM ccmetawhatsAppNumbers WHERE Number = @CamNumber AND Cam_Id = @CamId)  
				BEGIN
					SELECT ''CAMPAIGN_NUMBER_CHANGED'' AS ReopenConversationResponse;
					RETURN(0);
				END

				SELECT @MaxWhatsAllowed = a.maxWhatsOut FROM cccamps c INNER JOIN ccriacat_Areas a ON c.IDArea = a.IDArea WHERE c.cam_id = @CamId;
				SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversationsOut WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(HOUR, -24, GETDATE());

				IF @ConversationCount >= @MaxWhatsAllowed
				BEGIN
					SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationResponse;
					RETURN(0);
				END
				SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
				RETURN(0);
			END
			ELSE 
			BEGIN
				SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
				RETURN(0);
			END
		END
	END

		DECLARE @ConvId int;

	IF @Option = 9 -- Verificación al reabrir conversación
	BEGIN 
		DECLARE @ConversationWithinWindowTime BIT = 0;
		DECLARE @ReopenConversationButtonResponse VARCHAR(50);
		DECLARE @AgentName varchar(50);
		DECLARE @TimeThreshold DATETIME;
		SET @TimeThreshold = DATEADD(hour, -23, GETDATE());


		IF EXISTS (SELECT 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent))
		BEGIN  
			SET @ReopenConversationButtonResponse = ''REOPEN_CONVERSATION'';
		END
		ELSE 
		BEGIN 
			SET @ReopenConversationButtonResponse = ''REOPEN_CONVERSATION_WITH_TEMPLATE'';
		END

		IF @CamType = 0
		BEGIN
			IF EXISTS (SELECT 1 FROM ccWhatsAppConversations WHERE InboundId = @CamId AND phoneACD = @CamNumber AND clientId = @ClientNumber AND conversationStatus = 2 AND (agentId = @agentId OR agentId <> @agentId))
			BEGIN
				SELECT TOP 1 @ConvId = ConversationId FROM ccWhatsAppConversations WHERE InboundId = @CamId  AND phoneACD = @CamNumber  AND clientId = @ClientNumber  AND conversationStatus = 2  AND (agentId = @agentId OR agentId <> @agentId);
				SELECT @AgentName = u.Nombres FROM ccWhatsAppConversations c
												INNER JOIN ccusers u ON c.agentId = u.User_id 
												WHERE c.ConversationId = @ConvId;
				SELECT ''ONGOING_CONVERSATION'' AS ReopenConversationButtonResponse,
									@AgentName AS AgentName;
				RETURN(0);
			END

			SELECT @MaxWhatsAllowed = a.maxWhats FROM ccinbound i INNER JOIN ccriacat_Areas a ON i.IDArea = a.IDArea WHERE i.Inbound_Id = @CamId;
			SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversations WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(hour, -24, GETDATE());

			IF @ConversationCount >= @MaxWhatsAllowed
			BEGIN
				SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationButtonResponse;
				RETURN(0);
			END

			IF @ReopenConversationButtonResponse = ''REOPEN_CONVERSATION_WITH_TEMPLATE''
			BEGIN
				IF EXISTS (SELECT 1 FROM ccoWhatsLogDials WITH (NOLOCK, INDEX(IX_TimeSpam_PhoneClient_PhoneWa)) WHERE TimeSpam >= @TimeThreshold AND PhoneWa = @CamNumber AND PhoneClient = @ClientNumber AND answered = 0)
				BEGIN
					SELECT ''CONVERSATION_SENT_IN_BULK_IN_COURSE'' AS ReopenConversationButtonResponse,
									   ''N/A'' AS AgentName;
					RETURN(0);
				END
			END

			SELECT @ReopenConversationButtonResponse AS ReopenConversationButtonResponse, ''N/A'' AS AgentName;
			RETURN(0);
		END

		IF @CamType = 1
		BEGIN
			IF EXISTS (SELECT 1 FROM ccWhatsAppConversationsOut WHERE camId = @CamId AND phoneCamp = @CamNumber AND clientId = @ClientNumber AND conversationStatus = 2 AND (agentId = @agentId OR agentId <> @agentId))
			BEGIN
				SELECT TOP 1 @ConvId = ConversationId FROM ccWhatsAppConversationsOut WHERE camId = @CamId  AND phoneCamp = @CamNumber  AND clientId = @ClientNumber  AND conversationStatus = 2  AND (agentId = @agentId OR agentId <> @agentId);
				SELECT @AgentName = u.Nombres FROM ccWhatsAppConversationsOut c
											  INNER JOIN ccusers u ON c.agentId = u.User_id 
											  WHERE c.ConversationId = @ConvId;
				SELECT ''ONGOING_CONVERSATION'' AS ReopenConversationButtonResponse,
								   @AgentName AS AgentName;
				RETURN(0);
			END

			IF EXISTS (SELECT 1 FROM ccoWhatsLogDials WITH (NOLOCK, INDEX(IX_TimeSpam_PhoneClient_PhoneWa)) WHERE TimeSpam >= @TimeThreshold AND PhoneWa = @CamNumber AND PhoneClient = @ClientNumber AND answered = 0)
			BEGIN
				SELECT ''CONVERSATION_SENT_IN_BULK_IN_COURSE'' AS ReopenConversationButtonResponse,
				''N/A'' AS AgentName;
				RETURN(0);
			END

			SELECT @MaxWhatsAllowed = a.maxWhatsOut FROM cccamps c INNER JOIN ccriacat_Areas a ON c.IDArea = a.IDArea WHERE c.cam_id = @CamId;
			SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversationsOut WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(hour, -24, GETDATE());

			IF @ConversationCount >= @MaxWhatsAllowed
			BEGIN
				SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationButtonResponse;
				RETURN(0);
			END

			SELECT @ReopenConversationButtonResponse AS ReopenConversationButtonResponse, ''N/A'' AS AgentName;
			RETURN(0);
		END
	END 

	IF @Option = 10 -- Creación de conversationId de entrada 
	BEGIN 
		EXEC ccsp_ConversationWASave @action=1, @phoneacd=@CamNumber, @clientid= @ClientNumber, @inboundid=@CamId, @agentId = @agentId, @IsReopenedConversation = 1, @conversationstatus=2

	END 

	IF @Option = 11 -- Creación de conversationId de salida
	BEGIN
		EXEC ccsp_ConversationOutWASave @action=1, @phoneCamp=@CamNumber, @clientid= @ClientNumber, @campId=@CamId, @agentId = @agentId, @conversationstatus=2
	END'
	EXEC(@sql)


	SET @process = 'delete sp ccsp_WhatsAppGlobalIds'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_WhatsAppGlobalIds'')
    BEGIN
        DROP PROCEDURE ccsp_WhatsAppGlobalIds;
    END
    '
	EXEC(@sql)

    SET @process = 'Actualización de campos cuando se hace envio masivo'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_WhatsAppGlobalIds]  
        @ConversationType TINYINT = -1,
        @ConversationId INT = 0,
        @MessageId VARCHAR(MAX) = '''',
        @AssociatedNumber VARCHAR (30), 
        @ClientNumber VARCHAR(30),
		@TemplateCategory varchar(30) = ''''
		AS  
		SET NOCOUNT ON;  

			IF @ConversationType = 0 AND NOT EXISTS(SELECT 1 FROM ccWhatsAppConversations WHERE conversationId = @ConversationId)
			BEGIN
				RAISERROR(''ERROR. No existe una conversación de entrada con el id especificado'', 18, 1);
				RETURN(0);
			END;
			ELSE IF @ConversationType = 1 AND NOT EXISTS(SELECT * FROM ccWhatsAppConversationsOut WHERE conversationId = @ConversationId)
			BEGIN
				RAISERROR(''ERROR. No existe una conversación de salida con el id especificado'', 18, 1);
				RETURN(0);
			END;
			ELSE
			BEGIN
				DECLARE @originType VARCHAR(20) = '''';
				DECLARE @firstMessageDateFromAgent DATETIME = NULL;
				DECLARE @messageStatus VARCHAR(20) = '''';
				DECLARE @firstMessageConversationIdFromAgent INT = NULL;
				DECLARE @firstMessageConversationTypeFromAgent TINYINT = NULL;
				DECLARE @isBilled BIT = 0;

				IF @ConversationType = 0 
				BEGIN
					SET @originType = (SELECT originType FROM ccWAMessagesConversations WHERE messageId = @MessageId);
					SELECT @firstMessageDateFromAgent = timeStampMessage, @messageStatus = messageStatus
					FROM ccWAMessagesConversations
					WHERE messageId = @MessageId AND @originType IN (''Agent'', ''Admin'');
				END;
				ELSE 
				BEGIN
					SET @originType = (SELECT originType FROM ccWAMessagesConversationsOut WHERE messageId = @MessageId);
					SELECT @firstMessageDateFromAgent = timeStampMessage, @messageStatus = messageStatus
					FROM ccWAMessagesConversationsOut
					WHERE messageId = @MessageId AND @originType IN (''Agent'', ''Admin'');
				END;

				DECLARE @globalId INT

				IF @TemplateCategory IS NOT NULL
				BEGIN
					SELECT @globalId = MAX(GlobalId) FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @AssociatedNumber AND ClientNumber = @ClientNumber AND Category = @TemplateCategory;
				END
				ELSE
				BEGIN
					SELECT @globalId = MAX(GlobalId) FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @AssociatedNumber AND ClientNumber = @ClientNumber AND Category IS NULL;
				END

				IF @originType IN (''Agent'', ''Admin'') AND @messageStatus NOT IN(''rejected'', ''undeliverable'', ''submitted'')
				BEGIN
					SET @firstMessageConversationIdFromAgent = @ConversationId;
					SET @firstMessageConversationTypeFromAgent = @ConversationType;
					SET @isBilled = 1;
				END
				ELSE
				BEGIN
					SET @firstMessageDateFromAgent = NULL
				END

				IF @globalId IS NULL
				BEGIN
					INSERT INTO ccWhatsAppGlobalIds (AssociatedNumber, ClientNumber, FirstMessageDateFromAgent, FirstMessageConversationIdFromAgent, FirstMessageConversationTypeFromAgent, IsBilled, Category)
					VALUES (@AssociatedNumber, @ClientNumber, @firstMessageDateFromAgent, @firstMessageConversationIdFromAgent, @firstMessageConversationTypeFromAgent, @isBilled, @TemplateCategory);

					SET @globalId = SCOPE_IDENTITY();
				END

				DECLARE @TempFirstMessageDate DATETIME = (SELECT FirstMessageDateFromAgent FROM ccWhatsAppGlobalIds WHERE GlobalId = @globalId);
                        
				--Update if message status changes
				IF @originType IN (''Agent'', ''Admin'') AND @messageStatus NOT IN(''rejected'', ''undeliverable'', ''submitted'') AND @globalId IS NOT NULL
				BEGIN
					UPDATE ccWhatsAppGlobalIds SET IsBilled = 1 WHERE GlobalId = @globalId
				END

				IF DATEDIFF(HOUR, @TempFirstMessageDate, GETDATE()) >= 24 
				BEGIN 
					INSERT INTO ccWhatsAppGlobalIds (AssociatedNumber, ClientNumber, FirstMessageDateFromAgent, FirstMessageConversationIdFromAgent, FirstMessageConversationTypeFromAgent, IsBilled, Category)
					VALUES (@AssociatedNumber, @ClientNumber, @firstMessageDateFromAgent, @firstMessageConversationIdFromAgent, @firstMessageConversationTypeFromAgent, @isBilled, @TemplateCategory);

					SET @globalId = SCOPE_IDENTITY();   
				END

				-- If the message is from agent update the date 
				IF @originType IN (''Agent'', ''Admin'') AND @TempFirstMessageDate IS NULL
				BEGIN
					UPDATE ccWhatsAppGlobalIds SET FirstMessageDateFromAgent = @firstMessageDateFromAgent,
													FirstMessageConversationIdFromAgent =  @ConversationId,
													FirstMessageConversationTypeFromAgent = @ConversationType,
													IsBilled = @isBilled
					WHERE GlobalId = @globalId;
				END
				-- Insert into ccWhatsAppGlobalIdsRelationship
				IF @globalId != 0 AND NOT EXISTS(SELECT GlobalId FROM ccWhatsAppGlobalIdsRelationship WHERE GlobalId = @globalId AND ConversationId = @ConversationId AND @ConversationType = ConversationType)
				BEGIN
					INSERT INTO ccWhatsAppGlobalIdsRelationship(GlobalId, ConversationId, ConversationType)
					VALUES (@globalId, @ConversationId, @ConversationType)
				END

				select @globalId as globalId

				RETURN(@globalId)
        
			END
			SET NOCOUNT OFF'
	EXEC(@sql)
    -------------------------------------------- END DM -----------------------------------------

--------------------------- Begin Luis Miguel Zamora Nuñez 126.20241226.0.0 ----------------------------------------------------------------------------------------------

SET @process = 'K069003-CW-8946 - ccsp_GalateaUpdateUser - SP Edited, 
Se modifica para solucionar relacion entre InsertLogAdminGalatea y el Historial de Actividad'
SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateUser]
        @UserId int,
        @Login varchar(40),
        @Nombres varchar(45),
        @LastName varchar(45),
        @NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
        @Sexo bit,
        @canChangeStatus bit,
        @AdminId int,
        @AreaId int,
        @NotificationEmail varchar(255)
        as

        Declare @ApellidoMaterno varchar(45)
        Declare @ApellidoPaterno varchar(45)
        Declare @userIdOnDb int
        Declare @LoginOnDb varchar(40)
        --Obtiene el idioma de Centerware
        Declare @lenguageXion varchar
        select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

        set @ApellidoPaterno = @LastName
        set @ApellidoMaterno = @NombreOpcionalExtra

        -- validaciones 
            if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
                begin
                select -5 as ResponseCode--,''el usuario no existe''
                return(0)
                end

          if exists(select Nombres from ccUsers where Nombres=@Nombres
          and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
            begin

                select @userIdOnDb =User_id from ccUsers where Nombres=@Nombres
              and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

                select @LoginOnDb =User_id from ccUsers where Nombres=@Nombres
              and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

              if @UserId <> @userIdOnDb and @Login <> @LoginOnDb
                begin
                    select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
                    return(0)
                end
            end

                --update and insert into activity log a record for each modified property

    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId=@UserId, @userId= @userId

    Update ccUsers set 
    Nombres=@Nombres,
    ApellidoPaterno=@ApellidoPaterno,
    ApellidoMaterno=@ApellidoMaterno,
    Sexo=@Sexo,
    canChangeStatus=@canChangeStatus,
    notificationEmail=@NotificationEmail
    where User_id=@UserId

        CREATE TABLE #CCUsersTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    );

    EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccUsers'', @columnNameId = ''User_id'', @valueId = @UserId, @userId = @userId, @tableTemp=''#CCUsersTable'';

        DELETE FROM #CCUsersTable WHERE identifierInfo IS NULL OR identifierInfo = '''';

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT 
                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId),
                GETDATE(), 
                (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
                CASE WHEN (SELECT [TipoUser_id] FROM ccUsers WHERE User_id = @UserId) = 1 THEN 25 ELSE 32 END, 
                3, 
                ISNULL(CUT.identifierInfo, ''''),  -- Asegura que sea '''' si es NULL
                CASE 
                        WHEN CUT.identifierInfo IS NOT NULL THEN
                                CASE 
                                        WHEN CUT.identifierInfo = ''T&EDIT_GENDER_USER'' THEN CONCAT(CUT.identifierInfo, CASE WHEN CUT.dataInfo = 1 THEN ''_M'' ELSE ''_F'' END)
                                        ELSE CUT.dataInfo 
                                END
                        ELSE '''' 
                END, 
                (SELECT [Login] FROM ccUsers WHERE User_id = @UserId)
        FROM #CCUsersTable AS CUT
        WHERE (CUT.identifierInfo IS NOT NULL AND CUT.identifierInfo <> ''''); -- Filtra las filas sin identifierInfo


    EXEC InsertLogAdminGalatea @action=3, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId = @UserId, @userId = @userId

        IF OBJECT_ID(N''tempdb..#CCUsersTable'') IS NOT NULL DROP TABLE #CCUsersTable

        select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
'
EXEC(@sql);

SET @process = 'K069003-CW-8946 - InsertLogAdminGalatea - SP Edited, 
Se modifica para solucionar problema del Historial de Actividad al Editar Usuario'
SET @sql = '
ALTER procedure [dbo].[InsertLogAdminGalatea]
    @action int 
    ,@tableName VARCHAR(255)
    ,@columnNameId VARCHAR(255)
    ,@valueId VARCHAR(255)
    ,@userId int
    ,@tableTemp varchar(255)=null
AS
SET NOCOUNT ON;

declare @sql nvarchar(max), @sql2 nvarchar(max)
DECLARE @tableNameTmp VARCHAR(255) = ''##''+@tableName+''_''+convert(varchar(10),@userId)

if @action =1 begin --Antes del cambio
    set @sql=''IF OBJECT_ID(N''''tempdb..''+@tableNameTmp+'''''') IS NOT NULL DROP TABLE ''+@tableNameTmp+'' 
    SELECT * INTO ''+@tableNameTmp+'' FROM ''+@tableName+'' WHERE ''+@columnNameId+'' = ''+@valueId
    -- Ejecutar el SQL para crear la tabla temporal
    exec(@sql)
end
else if @action=2 begin
    DECLARE @columns NVARCHAR(MAX) = '''';
    DECLARE @conditions NVARCHAR(MAX) = '''';
    DECLARE @caseStatements NVARCHAR(MAX) = '''';
    DECLARE @batchSize INT = 10; -- Tamaño del bloque de columnas
    DECLARE @counter INT = 0;
    declare @emtpy varchar(2)=''''

    -- Declarar una variable de tipo tabla para almacenar los IDs de cada bloque
    DECLARE @BatchColumns TABLE (
            name NVARCHAR(128),
            batch_id INT
    );

    -- Insertar en @BatchColumns las columnas de la tabla, dividiéndolas en bloques
    INSERT INTO @BatchColumns (name, batch_id)
    SELECT 
            name,
            (ROW_NUMBER() OVER (ORDER BY column_id) - 1) / @batchSize AS batch_id
    FROM 
            sys.columns
    WHERE 
            object_id = OBJECT_ID(@tableName)
            AND name <> @columnNameId  -- Excluir la columna clave primaria
            AND name <> ''rowguid'';  -- Excluir la columna GUID si existe

    -- Insertar batch_ids únicos en la variable de tipo tabla @BatchIds
    DECLARE @BatchIds TABLE (
            batch_id INT PRIMARY KEY
    );

    INSERT INTO @BatchIds
    SELECT DISTINCT batch_id FROM @BatchColumns;

    DECLARE @batch_id INT = 0;

    -- Bucle para procesar cada bloque de columnas
    WHILE EXISTS (SELECT 1 FROM @BatchIds WHERE batch_id = @batch_id)
    BEGIN
        -- Construir las expresiones CASE y las condiciones WHERE para este bloque
        SET @caseStatements = '''';
        SET @conditions = '''';

        -- Construir el CASE y el WHERE para cada columna en el bloque actual
        SELECT 
                @caseStatements = @caseStatements + 
                ''SELECT '''''' + name + '''''' AS columnInfo, CONVERT(VARCHAR(300), A.'' + QUOTENAME(name) + '') AS dataInfo '' +
                ''FROM '' + @tableName + '' AS A '' +
                ''FULL OUTER JOIN '' + @tableNameTmp + '' AS B ON A.'' + QUOTENAME(@columnNameId) + '' = B.'' + QUOTENAME(@columnNameId) + '' '' +
                ''WHERE A.'' + QUOTENAME(name) + '' <> B.'' + QUOTENAME(name) + '' UNION ALL ''
        FROM 
                @BatchColumns
        WHERE 
                batch_id = @batch_id;                   

        -- Construir las condiciones WHERE para el bloque actual
        SELECT @conditions = @conditions + 
        CASE WHEN @conditions = '''' THEN '''' ELSE '' OR '' END +
        ''A.'' + QUOTENAME(name) + '' <> B.'' + QUOTENAME(name)
        FROM 
                @BatchColumns
        WHERE 
                batch_id = @batch_id;

        -- Remover el último UNION ALL sobrante
        SET @caseStatements = LEFT(@caseStatements, LEN(@caseStatements) - LEN('' UNION ALL ''));
        
        -- Construir y ejecutar la consulta para este bloque
        IF @caseStatements <> ''''
        BEGIN
            SET @sql = ''
            INSERT INTO ''+@tableTemp+'' (columnInfo, dataInfo)
            '' + @caseStatements + ''                       
            '';
            -- Ejecutar la consulta dinámica
            EXEC sp_executesql @sql;
        END     

        -- Avanzar al siguiente bloque
        SET @batch_id = @batch_id + 1;
    END

    -- Consultar el resultado final de cambios
    set @sql= 
    ''SELECT distinct A.columnInfo, A.dataInfo, ISNULL(B.Identifiers, @emtpy) as identifierInfo 
    FROM ''+@tableTemp+'' A 
    LEFT JOIN relationTableColumnIdentifiers B 
        ON A.columnInfo = B.colunName 
        AND B.tableName = @tableName'';

    -- Si la tabla temporal existe, insertar los resultados allí
    if @tableTemp is not null and @tableTemp <> '''' begin
        set @sql = ''INSERT INTO '' + @tableTemp + '' '' + @sql
    end

    -- Ejecutar la consulta de inserción
    EXEC sp_executesql @sql, N''@tableName VARCHAR(255), @emtpy VARCHAR(2)'', @tableName = @tableName, @emtpy = @emtpy;

end
else if @action =3 begin
    set @sql=''IF OBJECT_ID(N''''tempdb..''+@tableNameTmp+'''''') IS NOT NULL DROP TABLE ''+@tableNameTmp
    -- Ejecutar la eliminación de la tabla temporal
    exec(@sql)
end
'
EXEC(@sql);
--------------------------- End Luis Miguel Zamora Nuñez 126.20241226.0.0 ----------------------------------------------------------------------------------------------

	
        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()
        RAISERROR (@errorGenerated, 11, 1)
        ROLLBACK TRAN
    END CATCH
END 
