/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

Database: CCenterRia
Required version: 123.27

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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 15
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	------------------------------------------------------------- KR022021 Lista ANI Rotativo---------------------------------------------------

		SET @process = 'KR022021,KR022023_Listas_ANI_Rotativo Alter procedure ccsp_GalateaAdminRotativeANI'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminRotativeANI]
			@type SMALLINT,
			@idArea SMALLINT = NULL,
			@descriptionList VARCHAR(50) = NULL,
			@id_RAniList SMALLINT = NULL,
			@PageIndex      INT = 0,
			@PageSize       INT = 0,
			@UserId			SMALLINT = 0

		AS
		BEGIN
			SET NOCOUNT ON;

			IF (@type = 1) -- Read Rotative ANI List Catalog
			BEGIN
				SELECT cral.id_RAniList,
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
						id_RAniList,
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
				SELECT cral.id_RAniList,
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
					UPDATE ccRIALoading SET [state] = 4 WHERE loadType = 2 AND [state] < 3
				END
				UPDATE ccRIALoading SET [state] = 4
				WHERE loadType = 2 AND [state] < 3 AND userID = @UserId 
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

		END';

		EXEC(@sql);

		------------------------------------------------------------- KR022021 Lista ANI Rotativo---------------------------------------------------

		------------------------------------------------------------- MERGER BIG RELEASE ---------------------------------------------------
	set @process = 'Reinicio MCS se altera sp ccsp_ConversationWASave (se quito option 7)'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformation]
    @Option SMALLINT,
    @InboundId SMALLINT = 0,
    @ConversationId INT = 0,
    @AgentsAvailables INT = 0,
    @IncreaseDecreaseAgent BIT = NULL

    AS
    SET NOCOUNT ON

    IF @InboundId IS NOT NULL BEGIN
        IF EXISTS (SELECT * FROM ccInbound WHERE Inbound_id = @InboundId AND chat = 5) BEGIN
            DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
            --DECLARE @Today SMALLDATETIME = ''2022-03-24''
            IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
                BEGIN
                    IF EXISTS (SELECT * FROM ccWAAverageConversations
                               WHERE InboundId = @InboundId
                               AND (LastUpdate IS NULL
                               OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                               OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
                    BEGIN
                        -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

                        DECLARE @AverageConversationTime INT = 0;
                        DECLARE @AverageDialogTime INT = 0;
                        DECLARE @AverageWaitingTime INT = 0;
                        DECLARE @MaximumWaitingTime INT = 0;
                        DECLARE @DefaultValue INT = (SELECT CASE 
															WHEN defaultServiceLevelParameter IS NULL THEN 2 
															WHEN defaultServiceLevelParameter = 0 THEN 2
															ELSE defaultServiceLevelParameter END
														FROM contactMeanIn WHERE inboundId = @InboundId);
                        SET @DefaultValue = @DefaultValue * 60;
                        DECLARE @LessThanDefault INT = 0;
                        DECLARE @ReceivedConversations INT = 0;
                        DECLARE @ServiceLevel SMALLINT = 0;

                        --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

                        SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
                               @AverageDialogTime = ROUND(AVG(tChatting), 4),
                               @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
                               @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
                               @ReceivedConversations = COUNT(conversationDate),
                               @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
                        FROM ccWhatsAppConversations WHERE inboundId = @InboundId
                        AND requestDate >= @Today

                        SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

                        ----------------------------------------------------- Update table --------------------------------------------------------

                        IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
                        BEGIN
                            UPDATE ccWAAverageConversations
                            SET AverageConversationTime = @AverageConversationTime,
                                AverageDialogTime = @AverageDialogTime,
                                AverageWaitingTime = @AverageWaitingTime,
                                MaximumWaitingTime = @MaximumWaitingTime,
                                ServiceLevel = @ServiceLevel,
                                StatusUpdate = 0,
                                LastUpdate = GETDATE()
                            WHERE InboundId = @InboundId
                        END
                        ELSE
                        BEGIN
                            INSERT INTO ccWAAverageConversations (InboundId, AverageConversationTime, AverageDialogTime,
                                                                  AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
                            VALUES(@InboundId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                                   @ServiceLevel, 0 , GETDATE())
                        END
                    END
                    --------------------------------- Results -----------------------------------

                    SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
                           ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
                           ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
                           ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
                           ISNULL(ServiceLevel, 0) AS ServiceLevel,
                           ISNULL(Attended, 0) AS Attended,
                           ISNULL(Assigned, 0) AS Assigned,
                           ISNULL(OnQueue, 0) AS OnQueue,
                           ISNULL(EndedBySystem, 0) AS EndedBySystem,
                           ISNULL(Available, 0) AS Available,
                           ISNULL(Request, 0) AS Request
                    FROM ccWAAverageConversations conv
                    RIGHT JOIN ccWAOperatingSummary summary ON conv.InboundId = summary.InboundId
                    WHERE conv.inboundId = @InboundId OR summary.InboundId = @InboundId
                END
            IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
                           -- Average Queue/Waiting Time, and Service Level)
            BEGIN
                IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
                    BEGIN
                        UPDATE ccWAAverageConversations SET StatusUpdate = 1
                        WHERE InboundId = @InboundId
                    END
                    ELSE
                    BEGIN
                        INSERT INTO ccWAAverageConversations (InboundId, StatusUpdate)
                        VALUES(@InboundId, 1)
                    END
            END
            IF @Option = 3 -- Save time from accepted conversation by agent
            BEGIN
                IF @ConversationId IS NOT NULL
                BEGIN
                    UPDATE ccWhatsAppConversations SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
                    --Save Conversation Assigned
                    SELECT @inboundId = inboundId FROM ccWhatsAppConversations where conversationId=@conversationId;
                    UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE InboundId = @inboundId
                    --EXEC ccsp_WhatsAppOperatingSummary @Option = 2, @InboundId = @CampIdTemp;
                END
            END
            IF @Option = 4 -- Get Disposition Information
            BEGIN
				declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
				select @nIdioma = case valor when 0 then ''Sin calificación'' else ''No disposition'' end
				from ccsettings where setting_id = 27 -- 0esp
				SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
						ISNULL(disposition.calif_id, 0) AS DispositionId,
						COUNT(whatsConv.disposition) AS Total,
						ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
						COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
				FROM ccWhatsAppConversations whatsConv
				LEFT JOIN cctipocalif disposition ON disposition.calif_id = whatsConv.disposition
				WHERE inboundId = @InboundId AND assignDate >= @Today
					and whatsConv.conversationStatus != 2
				GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
            END
            IF @Option = 5 -- Get Subdisposition Information
            BEGIN
                SELECT relation.calif_id AS DispositionId,
                       subDispositions.califSubDesc AS SubDispositionsName,
                       COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
                FROM cctipoSubCalifRel relation
                INNER JOIN ccTipoCalifSub subDispositions ON subDispositions.califSub_id = relation.califSub_id
                INNER JOIN ccWhatsAppConversations whatsConv ON whatsConv.subDisposition = subDispositions.califSub_id
                WHERE whatsConv.inboundId = @InboundId AND
                      whatsConv.assignDate >= @Today AND
                      relation.tipoSubRel = 1
                GROUP BY subDispositions.califSubDesc, relation.calif_id
            END
            IF @Option = 6 -- Agents Availables
            BEGIN
                IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @InboundId)
                    BEGIN
                        INSERT INTO ccWAOperatingSummary (InboundId, Available) VALUES (@InboundId, @AgentsAvailables);
                    END
                ELSE
                    BEGIN
                        UPDATE ccWAOperatingSummary SET Available = @AgentsAvailables WHERE InboundId = @InboundId
                    END
            END

        END
    END
    IF @Option = 0 BEGIN-- Reset TABLES
        TRUNCATE TABLE ccWAOperatingSummary;
        TRUNCATE TABLE ccWAAverageConversations;
        TRUNCATE TABLE ccLastMessageAgentByConversation;
    END
    RETURN(0)
    SET NOCOUNT OFF'
	EXEC(@sql)



	set @process = 'DEV1-81 Alter SP ccsp_GalateaAdminCampaigns Correcion Option=10 para tomar encuneta salida y entrada, K020002 Crear campaña WhatsApp Out ccsp_GalateaAdminCampaigns'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS      SMALLINT, 
                                       @CampType AS    SMALLINT = 0, 
                                       @WorkgroupId AS INT      = 0, 
                                       @Id AS          INT      = 0, 
                                       @AdminId AS     SMALLINT = 0, 
                                       @PinUpdate AS   SMALLINT = 0, 
                                       @LoadId AS      INT      = 0, 
                                               @Type AS        SMALLINT = 0,
                                               @InboundType    SMALLINT = 0,
                                               @AreaId         SMALLINT = 0,
                                               @multi_type     varchar(max) = null
AS
BEGIN
    SET NOCOUNT ON;
    IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                        BEGIN
                            SELECT CAST(IdCampEsp AS INT) AS Id
                            FROM ccRIACampEspWG
                            WHERE IDWG = @WorkgroupId
                                  AND Tipo = 1
                                   ORDER BY IdCampEsp ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
                    END;
            END;
            IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                        BEGIN
                            SELECT CAST(IdCampEsp AS INT) AS Id
                            FROM ccRIACampEspWG
                            WHERE IDWG = @WorkgroupId
                                  AND Tipo = 0
                                   ORDER BY IdCampEsp ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
                    END;
            END;
            RETURN 0;
    END;
    IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            SELECT DISTINCT 
                                   CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
                                                            CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.chat,0) as OutboundType
                            FROM ccCamps camps
                                 LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                                 LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
                            WHERE camps.cam_id = @Id
                                   ORDER BY camps.cam_descripcion ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
                    END;
            END;
            IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            SELECT DISTINCT 
                                                    CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType, 0 as OutboundType
                            FROM ccInbound inb
                                 LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                                 LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                            WHERE inb.Inbound_id = @Id
                                   ORDER BY inb.descripcion ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe campañas de entrada con el id especificado'', 18, 1);
                    END;
            END;
            RETURN 0;
    END;
    IF @Option = 3   -- Update OverallTotalNew By Campaign
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    UPDATE ccCampsNvosCB
                      SET 
                          OverallTotalNew = ccCampsNvosCB.new
                    WHERE id = @Id;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 4   -- Update Pin from Campaign per Admin
        BEGIN
            IF @Id IS NOT NULL
               AND @AdminId IS NOT NULL
                BEGIN
                    IF @PinUpdate = 1
                        BEGIN
                            INSERT INTO PinedCampaigns(CampId, AdminId, Type)
                        VALUES(@Id, @AdminId, @Type);
                    END;
                    IF @PinUpdate = 0
                        BEGIN
                            DELETE FROM PinedCampaigns
                            WHERE CampId = @Id
                                  AND AdminId = @AdminId
                                  AND Type = @Type;
                    END;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. La campañas o administrador no existen'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 5   -- Get Pin from Campaign Ids per Admin
        BEGIN
            IF @AdminId IS NOT NULL
                BEGIN
                    SELECT CampId AS Id
                    FROM PinedCampaigns
                    WHERE AdminId = @AdminId
                          AND Type = @Type
                           ORDER BY Id ASC;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 6   -- Get Blacklist Ids by Campaign Id
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    DECLARE @BlackListIds VARCHAR(MAX);
                    SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
                    FROM Camplistanegra
                    WHERE cam_id = @Id
                          AND STATUS = 1;
                    SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
        BEGIN
            IF(@Id IS NOT NULL
               AND EXISTS
            (
                SELECT *
                FROM cccamps
                WHERE cam_id = @Id
            ))
                BEGIN
                    SELECT TOP 1 list_id
                    FROM ccRIARegistryLists
                    WHERE cam_id = @Id
                          AND STATUS = 2
                           ORDER BY list_id DESC;
            END;
            ELSE
                BEGIN
                    --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                    RAISERROR(''ERROR. No existe una campa?a con el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
        BEGIN
            IF(@LoadId IS NOT NULL
               AND EXISTS
            (
                SELECT *
                FROM ccRIARegistryLists
                WHERE list_id = @loadID
                      AND STATUS <> 0
            ))
                BEGIN
                    UPDATE ccoCallsOutSource
                      SET 
                          cal_status = ''5''
                    WHERE list_id = @loadID;
                    DELETE FROM ccoWorkingTable
                    WHERE list_id = @LoadId;
                    EXEC ccsp_RIARegistryLists 
                         @action = 6, 
                         @list_id = @LoadId;
            END;
            ELSE
                BEGIN
                    --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                    RAISERROR(''ERROR. No existe una carga el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
        BEGIN
            DECLARE @table TABLE
            (camId    INT, 
             campType TINYINT, 
             PRIMARY KEY(camId, campType)
            );
            INSERT INTO @table
                   SELECT DISTINCT 
                          IdCampEsp, Tipo
                   FROM ccRIACampEspWG wg
                   WHERE wg.IDWG IN
                   (
                       SELECT IDWG
                       FROM ccRIAWorkGroupUsers
                       WHERE IDWG <> @WorkgroupId
                             AND User_id = @AdminId
                   );
            SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
            FROM @table A
                 RIGHT JOIN
            (
                SELECT wg.IdCampEsp, wg.Tipo
                FROM ccRIACampEspWG wg
                WHERE wg.IDWG = @WorkgroupId
            ) B ON A.camId = B.IdCampEsp
                   AND A.campType = B.Tipo
            WHERE A.camId IS NULL
                   ORDER BY IdCampEsp;
            RETURN 0;
    END;
    IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type
    BEGIN
  DECLARE @date DATETIME= CONVERT(DATE, DATEADD(hh, -3, GETDATE()));
  DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY(id));
  DECLARE @AgentsList TABLE(id INT, PRIMARY KEY(id));
  DECLARE @tmpCamAgent TABLE(camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY(camId, userId));
  DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT);
  DECLARE @CurrentStatus TABLE(userId INT, CurrentState INT, IdCampEsp INT, camType INT);
  DECLARE @campDataTotal TABLE(camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY(camId));

  INSERT INTO @AdminWorkgroups SELECT DISTINCT IDWG
  FROM ccRIAWorkGroupUsers WG, 
     ccUsers_Roles R
  WHERE WG.User_id = @AdminId
  OR (R.User_id = @AdminId
  AND R.Rol_id = 7);
        
  INSERT INTO @AgentsList SELECT DISTINCT A.User_id
  FROM ccRIAWorkGroupUsers A
  INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
  INNER JOIN ccUsers C ON A.User_id = C.User_id 
  AND C.TipoUser_id = 1
    ORDER BY A.User_id;

                    INSERT INTO @tmpCamAgent SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id,
  CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
  FROM ccRIACampEspWG campPerWg
  INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
  INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
  INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
  left JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp and @CampType = 0
  left JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp and @CampType = 1
  where C.TipoUser_id = 1
  AND campPerWg.Tipo = @CampType
  AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
  
  WITH lastState AS (
  SELECT A.user_id, MAX(A.fecha) AS fecha
  FROM ccLogAgentesDia A
  INNER JOIN @AgentsList B ON A.User_id = B.id
  WHERE fecha >= @date
  GROUP BY user_id)

    INSERT INTO @CurrentStatus 
  SELECT B.User_id,
  CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS currentStatus,
  B.IdCampEsp,
  B.Tipo
  FROM lastState A
  INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
  AND A.fecha = B.fecha;

  IF @Id = 0 AND @CampType = 0 
  BEGIN
    DELETE FROM @tmpCamAgent WHERE multimediaType = 5
  END

  DECLARE @MultimediaType SMALLINT = (SELECT CASE WHEN @CampType = 1 THEN -1 ELSE meanContactTypeId END
                    FROM contactMeanIn WHERE inboundId = @Id)

  DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes

  INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
  (CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType
   THEN @CampType ELSE null END) AS isCampDialog 
  FROM @tmpCamAgent A
  INNER JOIN @CurrentStatus B ON A.userId = B.userId
  WHERE (@Id = 0 or A.camId = @Id)

  IF @CampType = 1
    BEGIN
    ;with  campDataTotal as(
      select camId,count(*) total from @tmpCamAgent A group by camId
    )

    insert into @campDataTotal
    select 
      A.camId,
      B.cam_descripcion as campName 
      ,A.Total
      ,C.AreaName as Area
      from campDataTotal A
      INNER JOIN ccCamps B ON A.camId= B.cam_id 
      INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END
  ELSE
    BEGIN    
    ;with  campDataTotal as(
      select camId,count(*) total from @tmpCamAgent A group by camId
    )

    insert into @campDataTotal
    select 
      A.camId,
      B.descripcion as campName 
      ,A.Total
      ,C.AreaName as Area
      from campDataTotal A
        INNER JOIN ccInbound B ON A.camId = B.Inbound_id 
      INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END 


  ;WITH stateCamp AS(
    SELECT A.CampId,
    count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
    count(CASE WHEN A.CurrentState NOT IN(-2, -1, 0, 3, 4, 5, 6, 9, 30, 34) THEN 1 
           WHEN A.CurrentState IN (6, 34) AND A.CampId != C.IdCampEsp THEN 1 ELSE NULL END) AS notReady,
    COUNT(isCampDialog) AS dialog,
    COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected 
    FROM @AgentStatus A
    INNER JOIN @CurrentStatus C ON A.userId = C.userId
    GROUP BY A.CampId
  )

  SELECT 
    A.camId,
    A.campName,
    A.Total,
      ISNULL(B.ready, 0) AS Ready,
    ISNULL(B.notReady, 0 ) AS NotReady, 
    ISNULL(B.dialog, 0) AS Dialog,
    CASE WHEN B.disconnected IS NULL THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END Disconnected,
    A.Area
  FROM @campDataTotal A
  LEFT JOIN stateCamp B ON A.camId = B.CampId
  ORDER BY A.campName

        RETURN 0;
    END;
    IF @Option = 11  -- Get Campaigns Ids List Per Workgroup and Campaign Type
        BEGIN                
            IF Not EXISTS
            (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                      AND Rol_id = 7
            )
                BEGIN
        print ''xxxx SIn Super''
                    ;WITH wgId
                         AS (SELECT IDWG
                             FROM ccRIAWorkGroupUsers NOLOCK
                             WHERE user_id = @AdminId)
                         SELECT DISTINCT 
                                CAST(IdCampEsp AS INT) AS Id
                         FROM ccRIACampEspWG A (NOLOCK)
                              INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                 AND A.Tipo = @CampType;
            END;
            ELSE
                BEGIN
      --print ''xxxx Super''
      IF @CampType = 1
        BEGIN
          SELECT DISTINCT 
               CAST(cam_id AS INT) AS Id
                        FROM ccCamps (NOLOCK) where IDArea IS NOT NULL
        END
      ELSE
        BEGIN 
          SELECT DISTINCT 
               CAST(Inbound_id AS INT) AS Id
                        FROM ccInbound (NOLOCK) where IDArea IS NOT NULL
        END
            END;
            RETURN 0;
    END;
    IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    SELECT DISTINCT 
                           CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
                                            CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.chat,0) as OutboundType
                    FROM ccCamps camps (NOLOCK)
                         INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
                         INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
                           --WHERE camps.cam_id = @Id
                           ORDER BY camps.cam_descripcion ASC;
            END;
            ELSE
                BEGIN
                    SELECT DISTINCT 
                                            CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType, 0 as OutboundType
                    FROM ccInbound inb (NOLOCK)
                         INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
                         INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = inb.IDArea
                           ORDER BY inb.descripcion ASC;
            END;
            RETURN 0;
    END;
    IF @Option = 13
    BEGIN
        BEGIN                
            IF NOT EXISTS
            (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                        AND Rol_id = 7
            )
                BEGIN
                    IF @CampType = 1
                        BEGIN
                            WITH wgId
                                AS (SELECT IDWG
                                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,CAST(-1 AS INT) AS RelatedCampId
                                FROM ccRIACampEspWG A
                                    INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                        AND A.Tipo = 1
                                    INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id;
                        END
                    ELSE
                        BEGIN
                            WITH wgId
                                AS (SELECT IDWG
                                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                                FROM ccRIACampEspWG A (NOLOCK)
                                    INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                        AND A.Tipo = 0
                                    INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id 
                                    AND ((@multi_type is null AND cci.chat = @InboundType)
                                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
                        END
            END;
            ELSE
                BEGIN
                IF @CampType = 1
                    BEGIN
                        SELECT DISTINCT 
                                CAST(cam_id AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,-1 AS RelatedCampId
                        FROM ccCamps NOLOCK where IDArea = @AreaId
                    END
                ELSE
                    BEGIN 
                        SELECT DISTINCT 
                                CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                        FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
                        AND ((@multi_type is null AND cci.chat = @InboundType)
                            OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

                    END
            END;
            RETURN 0;
        END;
    END;

    IF @Option = 14
        BEGIN
            IF NOT EXISTS
            (
                    SELECT *
                    FROM ccUsers_Roles NOLOCK
                    WHERE User_id = @AdminId
                            AND Rol_id = 7
            )
                BEGIN
                    WITH wgId
                            AS (SELECT IDWG
                                FROM ccRIAWorkGroupUsers NOLOCK
                                WHERE user_id = @AdminId)
                            SELECT DISTINCT 
                                CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                            FROM ccRIACampEspWG A (NOLOCK)
                                INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                    AND A.Tipo = 0
                                INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND isnull(cci.cam_id,-1) = -1
                                AND ((@multi_type is null AND cci.chat = @InboundType)
                                    OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

                END
            ELSE
                BEGIN
                    SELECT DISTINCT 
                    CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                    FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND isnull(cam_id,-1) = -1
                    AND ((@multi_type is null AND cci.chat = @InboundType)
                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

                END
        END
    IF @Option = 15
        BEGIN
            SELECT DISTINCT 
            CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
            FROM ccInbound NOLOCK where cam_id = @Id
        END
                    END;'
    EXEC(@sql) 

		------------------------------------------------------------- MERGER BIG RELEASE ---------------------------------------------------



		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END

