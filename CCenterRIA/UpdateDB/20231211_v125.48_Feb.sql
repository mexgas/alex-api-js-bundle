/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 02/02/2024
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
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 48
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

        -----------------------------------------------------BEGIN TT8053 Enrique Ruiz ----------------------------------------------------------------

        SET @process = 'TT8053 Create ccLogAgentesDiaViewLast for better access to last status by agent'
        SET @sql = 'IF NOT EXISTS(SELECT * FROM sys.views WHERE name=''ccLogAgentesDiaViewLast'')
                    BEGIN
                    EXEC(''
                        CREATE VIEW ccLogAgentesDiaViewLast AS
                        SELECT TOP 1 WITH TIES
                        User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus, callId
                        FROM ccLogAgentesDia
                        ORDER BY
                        ROW_NUMBER() OVER (PARTITION BY user_Id ORDER BY fecha DESC);
                    '');
                    END;'
        EXEC(@sql);
        
        SET @process = 'TT8053 Modify consult of last agent state and add a condition for dialog column'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
        @Option AS      SMALLINT, 
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
        IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
                
            IF @CampType = 1 BEGIN-- Campaigns Out
                
            IF @WorkgroupId IS NOT NULL BEGIN
                SELECT CAST(IdCampEsp AS INT) AS Id FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId AND Tipo = 1
                ORDER BY IdCampEsp ASC;
            END;
            ELSE BEGIN
                RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
            END;
        END;
            IF @CampType = 0 BEGIN-- Campaigns In (ACD)
                IF @WorkgroupId IS NOT NULL BEGIN
                    SELECT CAST(IdCampEsp AS INT) AS Id FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId AND Tipo = 0
                    ORDER BY IdCampEsp ASC;
                END;
                ELSE
                BEGIN
                    RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
                END;
            END;
            RETURN 0;
        END;
        IF @Option = 2 BEGIN-- Get Campaign complete information per Campaign Type and Campaign Id      
            IF @CampType = 1 BEGIN-- Campaigns Out      
                IF @Id IS NOT NULL BEGIN
                    SELECT DISTINCT 
                    CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
                    isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
                    camps.cam_procesando IsStarted, 
                    ISNULL(a.AreaName, '''') AS Area, 
                    CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
                    CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
                    CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 ELSE isnull(camps.CampType,0) END as OutboundType,
                    ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
                    a.ToolsTransfer         
                    FROM ccCamps camps
                    LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                    LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
                    LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
                    WHERE camps.cam_id = @Id
                    ORDER BY camps.cam_descripcion ASC;
                END;
                ELSE BEGIN
                    RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
                END;
            END;
            ELSE IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            SELECT DISTINCT 
                            CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, 
                            ISNULL(a.AreaName, '''') AS Area, 
                                    CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType,
                                    a.ToolsTransfer
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
        ELSE IF @Option = 3  BEGIN -- Update OverallTotalNew By Campaign

            IF @Id IS NOT NULL BEGIN
                UPDATE ccCampsNvosCB SET  OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id;
            END;
            ELSE BEGIN
                RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
            END;
            RETURN 0;
        END;
        ELSE IF @Option = 4 -- Update Pin from Campaign per Admin
        BEGIN
            IF @Id IS NOT NULL
                AND @AdminId IS NOT NULL
            BEGIN
                IF @PinUpdate = 1
                BEGIN
                    INSERT INTO PinedCampaigns (CampId, AdminId, Type)
                    VALUES (@Id, @AdminId, @Type);
                END;

                IF @PinUpdate = 0
                BEGIN
                    DELETE
                    FROM PinedCampaigns
                    WHERE CampId = @Id
                        AND AdminId = @AdminId
                        AND Type = @Type;
                END;
            END;
            ELSE
            BEGIN
                RAISERROR (''ERROR. La campañas o administrador no existen'', 18, 1
                        );
            END;

            RETURN 0;
        END;

        ELSE IF @Option = 5 BEGIN  -- Get Pin from Campaign Ids per Admin       
            IF @AdminId IS NOT NULL BEGIN
                SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
                ORDER BY Id ASC;
            END;
            ELSE BEGIN
                RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
            END;
            RETURN 0;
        END;
        ELSE IF @Option = 6 -- Get Blacklist Ids by Campaign Id
        BEGIN
            IF @Id IS NOT NULL
            BEGIN
                DECLARE @BlackListIds VARCHAR(MAX);

                SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR
                            (MAX)), CAST(idtipolista AS VARCHAR(MAX)))
                FROM Camplistanegra
                WHERE cam_id = @Id
                    AND STATUS = 1;

                SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
            END;
            ELSE
            BEGIN
                RAISERROR (''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
            END;

            RETURN 0;
        END;
            
        ELSE IF @Option = 7 -- Get RegistryListIds Ids by Campaign Id
        BEGIN
            IF (
                    @Id IS NOT NULL
                    AND EXISTS (
                        SELECT *
                        FROM cccamps
                        WHERE cam_id = @Id
                        )
                    )
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
                RAISERROR (''ERROR. No existe una campaña con el id especificado'', 18, 1);
            END;

            RETURN 0;
        END;

        ELSE IF @Option = 8 -- Delete RegistryListIds Ids by LoadId
        BEGIN
            IF (
                    @LoadId IS NOT NULL
                    AND EXISTS (
                        SELECT *
                        FROM ccRIARegistryLists
                        WHERE list_id = @loadID
                            AND STATUS <> 0
                        )
                    )
            BEGIN
                UPDATE ccoCallsOutSource
                SET cal_status = ''5''
                WHERE list_id = @loadID;

                DELETE
                FROM ccoWorkingTable
                WHERE list_id = @LoadId;

                EXEC ccsp_RIARegistryLists @action = 6, @list_id = @LoadId;
            END;
            ELSE
            BEGIN
                --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                RAISERROR (''ERROR. No existe una carga el id especificado'', 18, 1);
            END;

            RETURN 0;
        END;

        ELSE IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
        BEGIN
            DECLARE @table TABLE (camId INT, campType TINYINT, PRIMARY KEY (camId, campType)
                );

            INSERT INTO @table
            SELECT DISTINCT IdCampEsp, Tipo
            FROM ccRIACampEspWG wg
            WHERE wg.IDWG IN (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers
                    WHERE IDWG <> @WorkgroupId
                        AND User_id = @AdminId
                    );

            SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
            FROM @table A
            RIGHT JOIN (
                SELECT wg.IdCampEsp, wg.Tipo
                FROM ccRIACampEspWG wg
                WHERE wg.IDWG = @WorkgroupId
                ) B ON A.camId = B.IdCampEsp
                AND A.campType = B.Tipo
            WHERE A.camId IS NULL
            ORDER BY IdCampEsp;

            RETURN 0;
        END;

        ELSE IF @option = 10 BEGIN -- Get Agents States with totals per campaign by admin id and campaign type
            DECLARE @date DATETIME = CONVERT(DATE, DATEADD(hh, - 3, GETDATE()));
            DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY (id));
            DECLARE @AgentsList TABLE (id INT, PRIMARY KEY (id));
            DECLARE @tmpCamAgent TABLE (
                camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY (camId, userId
                    )
                );
            DECLARE @AgentStatus TABLE (CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT
                );
            DECLARE @CurrentStatus TABLE (userId INT, CurrentState INT, IdCampEsp INT, camType INT
                );
            DECLARE @campDataTotal TABLE (
                camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY (camId
                    )
                );

            INSERT INTO @AdminWorkgroups
            SELECT DISTINCT IDWG
            FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
            WHERE WG.User_id = @AdminId
                OR (
                    R.User_id = @AdminId
                    AND R.Rol_id = 7
                    );

            INSERT INTO @AgentsList
            SELECT DISTINCT A.User_id
            FROM ccRIAWorkGroupUsers A
            INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
            INNER JOIN ccUsers C ON A.User_id = C.User_id
                AND C.TipoUser_id = 1
            ORDER BY A.User_id;

            INSERT INTO @tmpCamAgent
            SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
                        AND @CampType = 0 THEN inbound.chat ELSE NULL END
            FROM ccRIACampEspWG campPerWg
            INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
            INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
            INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
            LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
                AND @CampType = 0
            LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
                AND @CampType = 1
            WHERE C.TipoUser_id = 1
                AND campPerWg.Tipo = @CampType
                AND (
                    @Id = 0
                    OR campPerWg.IdCampEsp = @Id
                    );;

            WITH lastState
            AS (
                SELECT A.user_id, MAX(A.fecha) AS fecha
                FROM ccLogAgentesDiaViewLast A
                INNER JOIN @AgentsList B ON A.User_id = B.id
                WHERE fecha >= @date
                GROUP BY user_id
                )
            INSERT INTO @CurrentStatus
            SELECT B.User_id, CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS 
                currentStatus, B.IdCampEsp, B.Tipo
            FROM lastState A
            INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
                AND A.fecha = B.fecha;

            IF @Id = 0
                AND @CampType = 0
            BEGIN
                DELETE
                FROM @tmpCamAgent
                WHERE multimediaType = 5
            END

            DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;

            IF @CampType = 1
            BEGIN
                SELECT @MultimediaType = meanContactTypeId
                FROM contactMeanOut
                WHERE camp_id = @Id
            END
            ELSE
            BEGIN
                SELECT @chatType = ci.chat
                FROM dbo.ccInbound AS ci
                WHERE ci.Inbound_id = @Id;

                SELECT @MultimediaType = meanContactTypeId
                FROM contactMeanIn
                WHERE inboundId = @Id
            END

            IF (@chatType = 1)
            BEGIN
                SET @MultimediaType = 1
            END

            DECLARE @StateIds VARCHAR(100) = (
                    SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN 
                                    ''23'' ELSE ''4,5,6,9'' END
                    ) -- Add more for multimediaTypes

			;with stateDialog as(
			SELECT cast(value as int) as CurrentState FROM dbo.fn_RIASplitDelimited(@StateIds,'','')
	)
            INSERT INTO @AgentStatus
            SELECT A.camId, A.userId, B.CurrentState,
			(CASE
				WHEN @chatType = 1 THEN
					CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) THEN 1 ELSE 0 END
				ELSE
					CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN 1 ELSE 0
                END
			END) AS isCampDialog, B.camType

            FROM @tmpCamAgent A
            INNER JOIN @CurrentStatus B ON A.userId = B.userId
            WHERE (
                    @Id = 0
                    OR A.camId = @Id
                    )

            IF @CampType = 1
            BEGIN
                    ;

                WITH campDataTotal
                AS (
                    SELECT camId, count(*) total
                    FROM @tmpCamAgent A
                    GROUP BY camId
                    )
                INSERT INTO @campDataTotal
                SELECT A.camId, B.cam_descripcion AS campName, A.Total, C.AreaName AS Area
                FROM campDataTotal A
                INNER JOIN ccCamps B ON A.camId = B.cam_id
                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
            END
            ELSE
            BEGIN
                    ;

                WITH campDataTotal
                AS (
                    SELECT camId, count(*) total
                    FROM @tmpCamAgent A
                    GROUP BY camId
                    )
                INSERT INTO @campDataTotal
                SELECT A.camId, B.descripcion AS campName, A.Total, C.AreaName AS Area
                FROM campDataTotal A
                INNER JOIN ccInbound B ON A.camId = B.Inbound_id
                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
            END;

            WITH stateCamp
            AS (
                SELECT A.CampId, count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready, 
                    count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34
                                    ) THEN 1 WHEN A.CurrentState IN (6, 34, 4
                                    )
                                AND (
                                    A.CampId != C.IdCampEsp
                                    OR A.campType != @CampType
                                    ) THEN 1 ELSE NULL END) AS notReady,
                                    COUNT(CASE WHEN A.isCampDialog = 1 THEN 1 ELSE NULL END) AS dialog, 
                                    COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected
                FROM @AgentStatus A
                INNER JOIN @CurrentStatus C ON A.userId = C.userId
                GROUP BY A.CampId
                )
            SELECT A.camId, A.campName, A.Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady, 
                    0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL 
                        THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END 
                Disconnected, A.Area
            FROM @campDataTotal A
            LEFT JOIN stateCamp B ON A.camId = B.CampId
            ORDER BY A.campName

            RETURN 0;
        END;
        ELSE IF @Option = 11 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
            IF NOT EXISTS (
                    SELECT *
                    FROM ccUsers_Roles WITH (NOLOCK)
                    WHERE User_id = @AdminId
                        AND Rol_id = 7
                    )
            BEGIN
                --print ''xxxx SIn Super''
                    ;

                WITH wgId
                AS (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers WITH (NOLOCK)
                    WHERE user_id = @AdminId
                    )
                SELECT DISTINCT CAST(IdCampEsp AS INT) AS Id
                FROM ccRIACampEspWG A WITH (NOLOCK)
                INNER JOIN wgId ON wgId.IDWG = A.IDWG
                    AND A.Tipo = @CampType;
            END;
            ELSE
            BEGIN
                --print ''xxxx Super''
                IF @CampType = 1
                BEGIN
                    SELECT DISTINCT CAST(cam_id AS INT) AS Id
                    FROM ccCamps WITH (NOLOCK)
                    WHERE IDArea IS NOT NULL
                END
                ELSE
                BEGIN
                    SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
                    FROM ccInbound WITH (NOLOCK)
                    WHERE IDArea IS NOT NULL
                END
            END;

            RETURN 0;
        END;

        ELSE IF @Option = 12 BEGIN-- Get All Campaigns complete information per Campaign Type and Campaign Id
            IF @CampType = 1 -- Campaigns Out
            BEGIN
                            SELECT DISTINCT 
                            CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
                            isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
                            camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
                            CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, 
                            CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 ELSE isnull(camps.CampType,0) END as OutboundType,
                            ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
                FROM ccCamps camps(NOLOCK)
                INNER JOIN ccRIACampsGraph graph(NOLOCK) ON camps.cam_id = graph.cam_id
                INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = camps.IDArea
                LEFT JOIN ccCampsExtend extended(NOLOCK) ON camps.cam_id = extended.cam_id
                ORDER BY camps.cam_descripcion ASC;
            END;
            ELSE
            BEGIN
                SELECT DISTINCT CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, isnull
                    (CAST(graph.graphic_id AS INT), 1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(
                        inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea AS INT) AS 
                    AreaId, inb.chat AS InboundType, 0 AS OutboundType
                FROM ccInbound inb(NOLOCK)
                                    INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
                INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = inb.IDArea
                ORDER BY inb.descripcion ASC;
            END;

            RETURN 0;
        END;

        ELSE IF @Option = 13
        BEGIN
            BEGIN
                IF NOT EXISTS (
                        SELECT *
                        FROM ccUsers_Roles NOLOCK
                        WHERE User_id = @AdminId
                            AND Rol_id = 7
                        )
                BEGIN
                    IF @CampType = 1
                    BEGIN
                        WITH wgId
                        AS (
                            SELECT IDWG
                            FROM ccRIAWorkGroupUsers NOLOCK
                                            WHERE user_id = @AdminId)
                                        SELECT DISTINCT 
                                            CAST(IdCampEsp AS INT) AS CampId,
                                            cam_descripcion AS Description,
                                            isnull(IDArea, -1) AS AreaID,
                                            CAST(-1 AS SMALLINT) AS CampaignType,
                                            CAST(-1 AS INT) AS RelatedCampId,
                                            CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN CampType ELSE 8 END AS INT) AS Channel,
                                            CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
                                            CAST(1 AS INT) As CampType
                        FROM ccRIACampEspWG A
                        INNER JOIN wgId ON wgId.IDWG = A.IDWG
                            AND A.Tipo = 1
                                            INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id
                                            LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
                    END
                    ELSE
                    BEGIN
                        WITH wgId
                        AS (
                            SELECT IDWG
                            FROM ccRIAWorkGroupUsers NOLOCK
                                            WHERE user_id = @AdminId)
                                        SELECT DISTINCT 
                                            CAST(IdCampEsp AS INT) AS CampId,
                                            descripcion AS Description,
                                            isnull(IDArea, -1) AS AreaID,
                                            CAST(chat AS SMALLINT) AS CampaignType,
                                            CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                            CAST(chat AS INT) AS Channel,
                                            CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                            CAST(0 AS INT) As CampType
                        FROM ccRIACampEspWG A(NOLOCK)
                        INNER JOIN wgId ON wgId.IDWG = A.IDWG
                            AND A.Tipo = 0
                        INNER JOIN ccInbound cci(NOLOCK) ON A.IdCampEsp = cci.Inbound_id
                                            LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                                            LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                                            AND ((@multi_type is null AND cci.chat = @InboundType)
                                                OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
                    END
                END;
                ELSE
                BEGIN
                    IF @CampType = 1
                    BEGIN
                                SELECT DISTINCT 
                                        CAST(ccc.cam_id AS INT) AS CampId,
                                        cam_descripcion AS Description,
                                        isnull(IDArea, -1) AS AreaID,
                                        CAST(-1 AS SMALLINT) AS CampaignType,
                                        -1 AS RelatedCampId,
                                        CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN CampType ELSE 8 END AS INT) AS Channel,
                                        CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
                                        CAST(1 AS INT) As CampType
                                FROM ccCamps AS ccc (NOLOCK) 
                                    LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
                                where IDArea = @AreaId
                    END
                    ELSE
                    BEGIN
                                SELECT DISTINCT 
                                        CAST(cci.Inbound_id AS INT) AS CampId,
                                        descripcion AS Description,
                                        isnull(IDArea, -1) AS AreaID,
                                        CAST(chat AS SMALLINT) AS CampaignType,
                                        CAST(chat AS INT) AS Channel,
                                        CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                        CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                        CAST(0 AS INT) As CampType
                        FROM ccInbound cci(NOLOCK)
                                    LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                                    LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                                where IDArea = @AreaId
                                AND ((@multi_type is null AND cci.chat = @InboundType)
                                    OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

                    END
                END;

                RETURN 0;
            END;
        END;
        ELSE IF @Option = 14
        BEGIN
            IF NOT EXISTS (
                    SELECT *
                    FROM ccUsers_Roles NOLOCK
                    WHERE User_id = @AdminId
                        AND Rol_id = 7
                    )
            BEGIN
                WITH wgId
                AS (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers NOLOCK
                                        WHERE user_id = @AdminId)
                                    SELECT DISTINCT 
                                        CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                FROM ccRIACampEspWG A(NOLOCK)
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

        ELSE IF @Option = 15
        BEGIN
                    SELECT DISTINCT 
                    CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                    FROM ccInbound NOLOCK where cam_id = @Id
        END

        END;
        '
        EXEC(@sql);


        ----------------------------------------------------- END TT8053 Enrique Ruiz  ----------------------------------------------------------------

		--------------------------------------------------- START DEV2-380 Hugo Longoria -------------------------------------------------------------

		set @process = 'DROP FUNCTION fn_getSIPHeaderCfg'
        set @sql = 'IF EXISTS (SELECT 1 FROM sys.objects 
                       WHERE Name = ''fn_getSIPHeaderCfg'' 
                         AND Type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
            BEGIN
                DROP FUNCTION dbo.fn_getSIPHeaderCfg
            END'
        EXEC(@sql)

        set @process = 'CREATE FUNCTION fn_getSIPHeaderCfg'
		set @sql = 'CREATE function [dbo].[fn_getSIPHeaderCfg](@callout_id int, @format varchar(500))
			returns varchar(500)
			as
			begin
				declare @result varchar(500)
				DECLARE @col varchar(MAX);
				SELECT @col = coalesce(@col,'''')+case when charindex(value,@format)>0 then value else '''' end
				FROM dbo.fn_RIASplitDelimited(''_CAMID_|_KEY_|_D1_|_D2_|_D3_|_D4_|_D5_|_CALLOUT_'',''|'')
				if len(isnull(@col,'''')) = 0 return isnull(@format,'''')

				SELECT 
					@result = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@format,''_CAMID_'',cast(cam_id as varchar(5))),''_KEY_'',cal_Key),''_D1_'',Dato1),''_D2_'',Dato2),''_D3_'',Dato3),''_D4_'',Dato4),''_D5_'',Dato5),''_CALLOUT_'',cast(@callout_id as varchar(10)))
				FROM ccocallsoutsource nolock where callout_id=@callout_id

				return isnull(@result,'''')
			end'
		EXEC(@sql)

		---------------------------------------------------- END DEV2-380 Hugo Longoria --------------------------------------------------------------

        set @process = 'Alter SP ccsp_OUTGetNewJobs se modifica la linea exec @iZonas=ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0'
        set @sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID int,
@test int=0,
@nAgentsLogin int=1,
@iZonas int = NULL,
@isDashboardApi BIT = 0
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @sql varchar(MAX), @Order_Asc_Desc char(4)
declare @camSurvey INT, @campType INT;
select @camSurvey = 0
DECLARE @iZonasTable TABLE (value int)
declare @maxRecs varchar(3) = 0

select @maxRecs = valor from ccsettings (nolock) where setting_id = 251 and Status = 1      
select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0;
SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id =  @CAMPID;

-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

if @iZonas is null begin

        exec @iZonas=ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0              
--Checamos si la campaña tiene horarios configurados
        if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
        begin
                    if @iZonas = 0 begin
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                    end
        end
        else begin
            if @camSurvey > 0
                    begin
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                    end
        end
end

set @sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
        cam_id int,
        cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
        cal_status tinyint,
        cal_fechaDial datetime,
        user_id int,
        tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint,
calkey varchar(max),
nDescartes int,
name_agent varchar(max),
SimultaneousRecs int,
tz_tmp int,
tz2_tmp int,
tz3_tmp int,
tz4_tmp int,
tz5_tmp int
)''


-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
select @topCount=case when @nAgentsLogin<3 then 30
        when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
        when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
        when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
        when @nAgentsLogin>=16 then 240 else 20 end

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

declare @isVerano varchar(max)
set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' END
        
IF(@campType = 7)
BEGIN
    set @isVerano = ''W.iTimeZone'' + case @bIsDaylight when 1 then ''_summer'' else '''' END
END


if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin

            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';

            IF(@campType = 7)
            BEGIN
                select @sql=@sql+nchar(13)+ ''SELECT W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial, W.user_id,''
                +@isVerano+'',''
                +@isVerano+''2,''
                +@isVerano+''3,''
                +@isVerano+''4,''
                +@isVerano+''5,
                W.list_id, isNull(R.sequence,0) as sequence,
                sos.callkey+''''~''''+rtrim(data1)+''''~''''+rtrim(data2)+''''~''''+rtrim(data3)+''''~''''+rtrim(data4)+''''~''''+rtrim(data5) calkey, 0 AS nDescartes,
                isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, 0 SimultaneousRecs,
                sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+'',
                sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2 ,
                sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3 ,
                sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4 ,
                sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5
                FROM smsWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
                left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
                left join ccUsers us (nolock) on us.User_id=w.user_id
                WHERE W.sms_status=1 -- CallBacks
                and W.sms_dateDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
                and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
                and (
                        ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''=0) or
                        ((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2=0) or
                        ((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3=0) or
                        ((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4=0) or
                        ((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5=0)
                )
                and isnull(R.status,2) = 2
                order by priority_cb desc, W.sms_dateDial ''  + @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
            END
            ELSE
            BEGIN
                select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
                +@isVerano+'',''
                +@isVerano+''2,''
                +@isVerano+''3,''
                +@isVerano+''4,''
                +@isVerano+''5,
                W.list_id, isNull(R.sequence,0) as sequence,
                cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
                isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs,
                cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
                cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
                cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
                cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
                cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5
                FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
                left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
                left join ccUsers us (nolock) on us.User_id=w.user_id
                left join ccCampsExtend ce on ce.cam_id=W.cam_id
                WHERE W.cal_status=1 -- CallBacks
                and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
                and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
                and (
                        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
                )
                and isnull(R.status,2) = 2
                order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
            END
                    
end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar );

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';

            IF(@campType = 7)
            BEGIN
                select @sql=@sql+nchar(13)+ ''SELECT W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial, W.user_id,''
                +@isVerano+'',''
                +@isVerano+''2,''
                +@isVerano+''3,''
                +@isVerano+''4,''
                +@isVerano+''5,
                W.list_id, isNull(R.sequence,0) as sequence,
                sos.callkey+''''~''''+rtrim(data1)+''''~''''+rtrim(data2)+''''~''''+rtrim(data3)+''''~''''+rtrim(data4)+''''~''''+rtrim(data5) calkey, 0 AS nDescartes,
                isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, 0 SimultaneousRecs,
                sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+'',
                sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2 ,
                sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3 ,
                sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4 ,
                sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5
                FROM smsWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
                left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
                left join ccUsers us (nolock) on us.User_id=w.user_id
                WHERE W.sms_status=0 -- Nuevas
                and W.sms_dateDial < dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
                and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
                and (
                        ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''=0) or
                        ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2=0) or
                        ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3=0) or
                        ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4=0) or
                        ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5=0)
                )
                and isnull(R.status,2) = 2
                order by R.sequence, W.sms_dateDial ''+ @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc
            END
            ELSE
            BEGIN
                select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
                +@isVerano+'',''
                +@isVerano+''2,''
                +@isVerano+''3,''
                +@isVerano+''4,''
                +@isVerano+''5,
                W.list_id, isNull(R.sequence,0) as sequence,
                cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
                isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs,
                cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
                cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
                cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
                cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
                cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5
                FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
                left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
                left join ccUsers us (nolock) on us.User_id=w.user_id
                left join ccCampsExtend ce on ce.cam_id=W.cam_id
                WHERE W.cal_status=0 -- Nuevas
                and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
                and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
                and (
                        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
                or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
                )
                and isnull(R.status,2) = 2
                order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
            END

end -- TOMA EN CUENTA LAS NUEVAS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @sql=@sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
        begin
            select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
            WHERE callout_id in(select callout_id from #NEW_JOBS)''
end

if @Test = 2
begin
        select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
        declare @nSQL nvarchar(4000)
        set @nSQL=cast(@sql as nvarchar(4000))
        exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
        return(@total)
end
else
BEGIN
    IF(@isDashboardApi = 1)
    BEGIN
            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,
            W.list_id, isNull(R.sequence,0) as sequence,
            cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
            isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs,
            cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
            cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
            cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
            cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
            cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
            left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
            left join ccUsers us (nolock) on us.User_id=w.user_id
            left join ccCampsExtend ce on ce.cam_id=W.cam_id
            WHERE W.cal_status= 2 -- Procesando
            and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
            and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                    ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
                -- TOMA EN CUENTA LOS REGISTROS PROCESANDOSE
    END

    select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,
    case when tz>0  then tz  else tz_tmp end as tz,
    case when tz2>0 then tz2 else tz2_tmp end as tz2,
    case when tz3>0 then tz3 else tz3_tmp end as tz3,
    case when tz4>0 then tz4 else tz4_tmp end as tz4,
    case when tz5>0 then tz5 else tz5_tmp end as tz5,
    case when tz is null then '''''''' else cal_telefono end as tel,
    case when tz2 is null then '''''''' else cal_telefono end as tel2,
    case when tz3 is null then '''''''' else cal_telefono end as tel3,
    case when tz4 is null then '''''''' else cal_telefono end as tel4,
    case when tz5 is null then '''''''' else cal_telefono end as tel5,
    NULL as dialOrder, list_id, sequence, calkey,
    0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent, SimultaneousRecs,'' + @maxRecs + '' maxRecs
    FROM #NEW_JOBS where len(cal_telefono)>0

    ---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
    declare @regval int
    SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0    
    ''
end

set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print (@sql)
exec(@sql)

return(0)
    '
        EXEC(@sql)


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
