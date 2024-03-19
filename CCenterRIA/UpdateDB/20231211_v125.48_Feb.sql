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

        SET @process = 'update ccCamps set CampType =0 where CampType is null'
        SET @sql = 'update ccCamps set CampType =0 where CampType is null'
        EXEC(@sql);

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
                                    CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
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
                                CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
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

END;'
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

     SET @process = 'ALTER SP ccsp_WhatsAppGlobalIds select @globalId as globalId'
     SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_WhatsAppGlobalIds]  
        @ConversationType TINYINT = -1,
        @ConversationId INT = 0,
        @MessageId VARCHAR(MAX) = '''',
        @AssociatedNumber VARCHAR (30), 
        @ClientNumber VARCHAR(30)
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
            WHERE messageId = @MessageId AND @originType = ''Agent'';
        END;
        ELSE 
        BEGIN
            SET @originType = (SELECT originType FROM ccWAMessagesConversationsOut WHERE messageId = @MessageId);
            SELECT @firstMessageDateFromAgent = timeStampMessage, @messageStatus = messageStatus
            FROM ccWAMessagesConversationsOut
            WHERE messageId = @MessageId AND @originType = ''Agent'';
        END;

        DECLARE @globalId INT = (SELECT MAX(GlobalId) FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @AssociatedNumber AND ClientNumber = @ClientNumber);

        IF @originType = ''Agent'' AND @messageStatus NOT IN(''rejected'', ''undeliverable'', ''submitted'')
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
            INSERT INTO ccWhatsAppGlobalIds (AssociatedNumber, ClientNumber, FirstMessageDateFromAgent, FirstMessageConversationIdFromAgent, FirstMessageConversationTypeFromAgent, IsBilled)
            VALUES (@AssociatedNumber, @ClientNumber, @firstMessageDateFromAgent, @firstMessageConversationIdFromAgent, @firstMessageConversationTypeFromAgent, @isBilled);

            SET @globalId = SCOPE_IDENTITY();
        END

        DECLARE @TempFirstMessageDate DATETIME = (SELECT FirstMessageDateFromAgent FROM ccWhatsAppGlobalIds WHERE GlobalId = @globalId);
                        
        --Update if message status changes
        IF @originType = ''Agent'' AND @messageStatus NOT IN(''rejected'', ''undeliverable'', ''submitted'') AND @globalId IS NOT NULL
        BEGIN
            UPDATE ccWhatsAppGlobalIds SET IsBilled = 1 WHERE GlobalId = @globalId
        END

        IF DATEDIFF(HOUR, @TempFirstMessageDate, GETDATE()) >= 24 
        BEGIN 
            INSERT INTO ccWhatsAppGlobalIds (AssociatedNumber, ClientNumber, FirstMessageDateFromAgent, FirstMessageConversationIdFromAgent, FirstMessageConversationTypeFromAgent, IsBilled)
            VALUES (@AssociatedNumber, @ClientNumber, @firstMessageDateFromAgent, @firstMessageConversationIdFromAgent, @firstMessageConversationTypeFromAgent, @isBilled);

            SET @globalId = SCOPE_IDENTITY();   
        END

        -- If the message is from agent update the date 
        IF @originType = ''Agent'' AND @TempFirstMessageDate IS NULL
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
     EXEC(@sql);


     SET @process = 'Add Column ccWhatsAppConversationsOut.IsAgentLoggingOut'
        SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''IsAgentLoggingOut'' and Object_ID = Object_ID(N''ccWhatsAppConversationsOut'')) BEGIN
    ALTER TABLE ccWhatsAppConversationsOut ADD IsAgentLoggingOut BIT null
END '
        EXEC(@sql);

        SET @process = 'ALTER SP ccsp_ConversationOutWASave @action = 1 Se revisa si el debe cerrar las conversaciones que fueron mayores a 23 horas'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationOutWASave] 
@action             INT
, @conversationId     INT         = 0
, @campId             INT         = NULL        
, @phoneCamp          VARCHAR(50) = NULL
, @clientId           VARCHAR(25) = NULL
, @conversationStatus SMALLINT    = 0
, @tChatting          FLOAT       = 0
, @tWrapUp            SMALLINT    = 0
, @finishedBy         TINYINT     = 0
, @onQueue            BIT         = NULL
, @tQueue             SMALLINT    = 0
, @tTimeout           INT         = 0
, @disposition        SMALLINT    = 0
, @subDisposition     SMALLINT    = 0
, @agentId            INT         = 0

AS
BEGIN
    SET NOCOUNT ON;
                        
    declare @conversationIdTemporal     INT;

IF @action = 1 BEGIN --new Conversation
    select @phoneCamp= number from ccWhatsAppNumbers where camp_id= @campId
                            
    if @phoneCamp is null or @phoneCamp='''' begin
        select 0 as [ConversationId],0 as [MessageId]
        return(0)
    end
    DECLARE @dateNow DATETIME;
    SET @dateNow = DATEADD(HOUR, -23, GETDATE());


    declare @existsConversationOut bit
    set @existsConversationOut =0
    
    
    if not exists (select * from ccWhatsAppConversationsOut with(nolock) where
    phoneCamp = @phoneCamp and clientId = @clientId and finishedBy=0 AND requestDate <= @dateNow) 
    begin       
        set @existsConversationOut=0
    end 
    else begin
        set @existsConversationOut=1
        UPDATE ccWhatsAppConversationsOut
        SET finishedBy = 2 ,conversationStatus=17
        WHERE finishedBy = 0  AND requestDate <= @dateNow
        and phoneCamp = @phoneCamp and clientId = @clientId
    end
    
    if not exists (select 1 from ccWhatsAppConversationsOut with(nolock) 
        where phoneCamp = @phoneCamp and clientId = @clientId 
        and finishedBy = 0 and requestDate > @dateNow) 
    begin
        set @existsConversationOut=0
    end
    else begin
        set @existsConversationOut=1
    end
    
    if @existsConversationOut=0
    begin
        if not exists (select * from ccWhatsAppConversations with(nolock) where phoneACD = @phoneCamp and clientId = @clientId and DATEDIFF(hh,requestDate,getdate()) <= 23 and finishedBy = 0) 
        begin
            INSERT INTO [ccWhatsAppConversationsOut]
            ([camId] , [phoneCamp], clientId, conversationStatus, tChatting
            , tWrapUp, finishedBy, onQueue, tQueue, requestDate
            , tTimeout, disposition, subDisposition, agentId)
            VALUES(@campId, @phoneCamp, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, 
            @onQueue, @tQueue, GETDATE(), @tTimeout, @disposition, @subDisposition, @agentId);
                        
            SELECT @conversationIdTemporal = SCOPE_IDENTITY();    
            SELECT @conversationIdTemporal AS [ConversationId],0 as [MessageId]
        end
        else begin
            select A.descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, C.Login Username 
            ,B.conversationId as conversationIdExists
            FROM ccInbound A INNER JOIN ccWhatsAppConversations B 
            ON B.clientId = @clientId AND B.finishedBy = 0 and B.inboundId=A.Inbound_id
            INNER JOIN ccUsers C ON B.agentId = C.User_id;
        end  
    end
    else begin
        select A.cam_descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, C.Login Username
        ,B.conversationId as conversationIdExists
        FROM ccCamps A INNER JOIN ccWhatsAppConversationsOut B 
        ON B.clientId = @clientId AND B.finishedBy = 0 and B.camId=A.cam_id
        INNER JOIN ccUsers C ON B.agentId = C.User_id;
    end  
END 
ELSE IF @action = 2 -- Get Outbound Templates
BEGIN
    IF @campId IS NOT NULL
    BEGIN
        DECLARE @AsociatedNumber VARCHAR(30) = (SELECT number from ccWhatsAppNumbers WHERE @campId = camp_id);
        SELECT * FROM ccWhatsAppOutboundTemplates WHERE AsociatedNumber = @AsociatedNumber AND Status = 1;
    END
END
END'
        EXEC(@sql);

    set @process = 'Alter Sp ccsp_ConversationWASave IF @action = 6 Se modifica para agregar with(nolock) y action=18'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
, @conversationId     INT         = 0
, @inboundId          SMALLINT    = NULL
, @phoneACD           VARCHAR(50) = NULL
, @clientId           VARCHAR(25) = NULL
, @conversationStatus SMALLINT    = 0
, @tChatting          FLOAT    = 0
, @tWrapUp            SMALLINT    = 0
, @finishedBy         TINYINT     = 0
, @onQueue            BIT         = NULL
, @tQueue             SMALLINT    = 0
, @tTimeout           INT         = 0
, @disposition        SMALLINT    = 0
, @subDisposition     SMALLINT    = 0
, @agentId            INT         = 0
--VAR MESSAGES
, @messageId          VARCHAR(50) = NULL
, @messageIdUi        INT         = NULL
, @clientNum          VARCHAR(15) = NULL
, @vonageNum          VARCHAR(15) = NULL
, @typeMessage        VARCHAR(25) = ''''
, @content            NVARCHAR(MAX)= NULL
, @timeStampMessage   DATETIME    = NULL
, @timeStampMessageUTC DATETIME   = NULL
, @originType         VARCHAR(15) = NULL
, @currency           VARCHAR(10) = ''-''
, @price              VARCHAR(10) = ''0.00''
, @messageStatus      VARCHAR(15) = ''N/A''
, @listConversationsIds   VARCHAR(MAX) = NULL
, @IsAgentLoggingOut  BIT = 0
AS
BEGIN
    DECLARE @isEndConversation BIT;
    DECLARE @meanContactTypeId SMALLINT;
    DECLARE @conversationIdNew INT;
    SET @meanContactTypeId = 1;
    SET NOCOUNT ON;

IF @action = 1
    BEGIN --new Conversation
        IF NOT EXISTS
            (SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock)
            WHERE A.conversationId = @conversationId
            )
        BEGIN
            INSERT INTO [ccWhatsAppConversations]
            (inboundId
            , phoneACD
            , clientId
            , conversationStatus
            , tChatting
            , tWrapUp
            , finishedBy
            , onQueue
            , tQueue
            , tTimeout
            , disposition
            , subDisposition
            , agentId
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

            IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId) BEGIN
                SELECT @conversationId = SCOPE_IDENTITY();
                SELECT @conversationId AS ConversationId;
            END
            ELSE BEGIN

                declare @conversationIdTemporal     INT;
                SELECT @conversationIdTemporal = SCOPE_IDENTITY();
                EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
                SELECT 0 AS ConversationId;
            END;

            --Save new request
            IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
                BEGIN
                    INSERT INTO ccWAOperatingSummary (InboundId, Request) VALUES (@inboundId, 1);
                END
            ELSE
                BEGIN
                    UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
                END
            RETURN(0);
        END
        ELSE
        BEGIN
            DECLARE @conversationStatusTemp INT = @conversationStatus;
            IF @conversationStatus in(17,18) BEGIN
                SET @conversationStatusTemp = 1
            END
            DECLARE @RequestDate DATETIME = NULL;
            SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversations WITH(NOLOCK) WHERE conversationId = @conversationId;

            INSERT INTO [ccWhatsAppConversations]
            (inboundId
            , phoneACD
            , clientId
            , conversationStatus
            , tChatting
            , tWrapUp
            , finishedBy
            , onQueue
            , tQueue
            , tTimeout
            , disposition
            , subDisposition
            , agentId
            , requestDate
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
            SELECT @conversationIdNew = SCOPE_IDENTITY();

            INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
                                                                , conversationIdAfter)
                VALUES (@conversationId, @conversationIdNew);
            --Save new request by reassign
            UPDATE ccWAOperatingSummary SET Request = (Request + 1)
            WHERE InboundId = @inboundId

        EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

        SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship with(nolock) where conversationIdBefore = @conversationId;
        RETURN(0);
    END;
END;

ELSE IF @action = 2
BEGIN --save conversation Times
    DECLARE @conversationIdTemp INT;
    DECLARE @TablaTemp TABLE (conversationId INT, status bit);

    IF @listConversationsIds IS NOT NULL begin
        INSERT INTO @TablaTemp
        SELECT value,0
        FROM fn_RIASplitDelimited(@listConversationsIds, '','')
        where value is not null and value<>''''
    end
    else begin
        INSERT INTO @TablaTemp values(@conversationId,0)
    end

    UPDATE ccWhatsAppConversations
    SET
    conversationStatus = @conversationStatus
    , finishedBy = case when @conversationStatus in(4,10,17,18) then 2
    when @conversationStatus in(11) then 1
    else 0 end
    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

        WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
    BEGIN
        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

        IF @conversationStatus in(4,10,11,13,17,18) BEGIN
            DECLARE @conversationDateTemp INT;
            select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
            from ccWhatsAppConversations with(nolock) where conversationId = @conversationId;

            IF @conversationStatus = 13 BEGIN
                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
                END
            END
            ELSE IF @conversationStatus in(4,10,17,18) BEGIN --Save conversation Ended by system
                IF @conversationDateTemp > 0 BEGIN
                    UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
                END
                ELSE BEGIN
                        UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1) WHERE InboundId = @inboundId
                END
            END
            ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
                UPDATE ccWAOperatingSummary SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
            END
        END
        update @TablaTemp set status=1 where conversationId=@conversationIdTemp
    END

END;

ELSE IF @action = 3
BEGIN --save conversation Status
    UPDATE ccWhatsAppConversations SET conversationStatus = @conversationStatus
    WHERE conversationId = @conversationId;
END;

ELSE IF @action = 4 BEGIN --save messages from conversation
    IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock) WHERE A.conversationId=@conversationId)
        AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
    BEGIN
        IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
            (SELECT messageIdUi
                FROM ccWAMessagesConversations
                WHERE originType IN (''Agent'', ''Admin'')
                AND conversationId = @conversationId)
            BEGIN
                UPDATE ccWhatsAppConversations
                    SET FirstMessageAgent = @timeStampMessage
                    WHERE conversationId = @conversationId;
            END

        INSERT INTO [ccWAMessagesConversations](
                                            messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
                                            (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
        SELECT @messageId=SCOPE_IDENTITY()
        SELECT @messageId as MessageId
        RETURN (0)
    END
    ELSE BEGIN
        SELECT 0 AS MessageId
        RETURN (0)
    END
END;

    IF @action = 5
    BEGIN --save onQueue
        UPDATE ccWhatsAppConversations
                SET onQueue = 1,
                conversationStatus = @conversationStatus
        WHERE conversationId = @conversationId;
        SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
        UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
    END;

ELSE IF @action = 6
BEGIN --save agent, assigdate and tqueue
    declare @agentIdTmp int
    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A with(nolock) where A.conversationId = @conversationId

    IF (@agentIdTmp is null or @agentIdTmp=0)
    BEGIN
        UPDATE ccWhatsAppConversations
                SET agentId = @agentId,
                assignDate = getdate(),
                conversationStatus = @conversationStatus
                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
        WHERE conversationId = @conversationId;

        SELECT @conversationId as conversationId
    SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
    declare @onQueueInt int

    IF @onQueue = 1 BEGIN
        UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1),@onQueueInt =OnQueue WHERE InboundId = @inboundId
        if @onQueueInt<=0 or exists(select * from ccWAOperatingSummary WHERE InboundId = @inboundId and OnQueue<0)begin

            select          
            @onQueueInt=count(case when onQueue =1 then 1 end)
            from ccWhatsAppConversations with(nolock)
            where inboundId= @inboundId
            and requestDate>=convert(date,getdate(),121)

            UPDATE ccWAOperatingSummary SET OnQueue = @onQueueInt WHERE InboundId = @inboundId

        end

    END
    END
END;

ELSE IF @action = 7
BEGIN --update price message
    UPDATE ccWAMessagesConversations
            SET price = @price,
                currency = @currency
    WHERE messageId = @messageId;
END;

ELSE IF @action = 8
BEGIN --update status message
    IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
        UPDATE ccWAMessagesConversations
                SET messageStatus = @messageStatus
        WHERE messageId = @messageId;
    END;
END;

ELSE IF @action = 9
BEGIN --Save last message time by conversationID
    IF not exists(SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) BEGIN
        INSERT INTO ccLastMessageAgentByConversation (conversationId,timeStampLastMessageAgent) VALUES (@conversationId,getDate())
    END;
    ELSE
        BEGIN
            UPDATE ccLastMessageAgentByConversation
                SET timeStampLastMessageAgent = getDate()
            WHERE conversationId = @conversationId;
        END;
END;

ELSE IF @action = 10
BEGIN --drop and insert register by conversationID
    DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
END;

ELSE IF @action = 11
BEGIN --register desconnection agent by conversationID
    UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
END;

ELSE IF @action = 12
BEGIN --Obtain conversationsWA post MCS reset

    declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
    UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

    declare @from as datetime;-- = ''01-07-2022'';
    select @from = convert(datetime,convert(varchar(11),getdate()))
    set @from=DATEADD(dd,-1,@from);
        select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
        ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
        from ccWhatsAppConversations A with(nolock)
        left join ccWAMessagesConversations B on A.conversationId = B.conversationId
        left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp          
        where A.requestDate >= @from 
            and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
        order by agentId desc, requestDate,timeStampMessage, inboundId, clientId 
END;
ELSE IF @action = 13
BEGIN ---Obtain agents ON STATUS READY
    WITH agents
    AS(
        SELECT c.User_id, c.fecha, c.currentStatus
        FROM ccLogAgentesDia c
        INNER JOIN 
        (
            SELECT User_id, MAX(fecha) max_time
            FROM ccLogAgentesDia with(nolock)
            where fecha>=CONVERT(date,getdate(),121)
            GROUP BY User_id
        ) AS t
        ON c.fecha = t.max_time
        AND c.User_id=t.User_id AND currentStatus in (3,34)
    ), usersByCampigns
    AS (
        select IdCampEsp, User_id from ccRIACampEspWG A
        Inner join ccRIAWorkGroupUsers B
        on A.IDWG = B.IDWG
        Inner join contactMeanIn C
        ON A.idCampEsp = C.inboundId
        where A.IDWG = 1 and A.Tipo = 0
        AND C.meanContactTypeId = 5
    )

    select DISTINCT A.User_Id from agents A
    left join usersByCampigns B on A.User_Id = B.User_Id
END;

ELSE IF @action = 14
BEGIN --register desconnection MCS
    INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
END;

ELSE IF @action = 15
BEGIN --update content message
    IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
        UPDATE ccWAMessagesConversations
                SET content = @content
        WHERE messageId = @messageId;
    END;
END;

ELSE IF @action = 16
BEGIN --update agent status for reassigning error message
    UPDATE ccWhatsAppConversations
    SET IsAgentLoggingOut = @IsAgentLoggingOut
    WHERE conversationId = @conversationId;
END;

ELSE IF @action = 18 BEGIN
    DECLARE @dateNow DATETIME;
    SET @dateNow = DATEADD(HOUR, -23, GETDATE());

    UPDATE ccWhatsAppConversations
    SET finishedBy = 2, conversationStatus=17
    WHERE finishedBy = 0 AND requestDate <= @dateNow    
END;
END;'
    EXEC(@sql)


        SET @process = 'ALTER SP ccsp_ConversationWASaveOut se agrega with(nolock), se valida para el modo finalizar las conversaciones'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASaveOut] @action             INT
, @conversationId     INT         = 0
, @camId          SMALLINT    = NULL
, @phoneCam           VARCHAR(50) = NULL
, @clientId           VARCHAR(25) = NULL
, @conversationStatus SMALLINT    = 0
, @tChatting          FLOAT    = 0
, @tWrapUp            SMALLINT    = 0
, @finishedBy         TINYINT     = 0
, @onQueue            BIT         = NULL
, @tQueue             SMALLINT    = 0
, @tTimeout           INT         = 0
, @disposition        SMALLINT    = 0
, @subDisposition     SMALLINT    = 0
, @agentId            INT         = 0
--VAR MESSAGES
, @messageId          VARCHAR(50) = NULL
, @messageIdUi        INT         = NULL
, @clientNum          VARCHAR(15) = NULL
, @vonageNum          VARCHAR(15) = NULL
, @typeMessage        VARCHAR(25) = ''''
, @content            NVARCHAR(MAX)= NULL
, @timeStampMessage   DATETIME    = NULL
, @timeStampMessageUTC DATETIME   = NULL
, @originType         VARCHAR(15) = NULL
, @currency           VARCHAR(10) = ''-''
, @price              VARCHAR(10) = ''0.00''
, @messageStatus      VARCHAR(15) = ''N/A''
, @listConversationsIds   VARCHAR(MAX) = NULL
, @IsAgentLoggingOut  BIT = 0
AS
BEGIN
    DECLARE @isEndConversation BIT;
    DECLARE @meanContactTypeId SMALLINT;
    DECLARE @conversationIdNew INT;
    SET @meanContactTypeId = 1;
    SET NOCOUNT ON;

IF @action = 1
BEGIN --new Conversation
    IF NOT EXISTS (SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A with(nolock)
    WHERE A.conversationId = @conversationId)
    BEGIN
        INSERT INTO [ccWhatsAppConversationsOut]
        (camId, phoneCamp , clientId, conversationStatus, tChatting , tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId)
        VALUES(@camId, @phoneCam, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

        
        SELECT @conversationId = SCOPE_IDENTITY();
        SELECT @conversationId AS ConversationId;
        
--        Save new request
        IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId) BEGIN
           INSERT INTO ccWAOperatingSummaryOut (camId, Request) VALUES (@camId, 1);
        END
        ELSE BEGIN
            UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1) WHERE camId = @camId
        END
        RETURN(0);
    END
    ELSE BEGIN
        DECLARE @conversationStatusTemp INT = @conversationStatus;
        IF @conversationStatus in(17,18) BEGIN
            SET @conversationStatusTemp = 1
        END

        DECLARE @RequestDate DATETIME = NULL;
        SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversationsOut WITH(NOLOCK) WHERE conversationId = @conversationId;

        INSERT INTO [ccWhatsAppConversationsOut]
            (camId, phoneCamp, clientId, conversationStatus, tChatting, tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId, requestDate)
        VALUES(@camId, @phoneCam, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, 
            @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
        SELECT @conversationIdNew = SCOPE_IDENTITY();

        INSERT INTO ccWhatsAppConversationsRelationshipOut (conversationIdBefore, conversationIdAfter)
        VALUES (@conversationId, @conversationIdNew);
        --Save new request by reassign
        UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1)
        WHERE camId = @camId

    EXEC ccsp_ConversationWASaveOut @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

    SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationshipOut where conversationIdBefore = @conversationId;
    RETURN(0);
END;
END;

else IF @action = 2
BEGIN --save conversation Times
    DECLARE @conversationIdTemp INT;
    DECLARE @TablaTemp TABLE (conversationId INT, status bit);

    IF @listConversationsIds IS NOT NULL begin
        INSERT INTO @TablaTemp
        SELECT value,0
        FROM fn_RIASplitDelimited(@listConversationsIds, '','')
        where value is not null and value<>''''
    end
    else begin
        INSERT INTO @TablaTemp values(@conversationId,0)
    end
    
    UPDATE ccWhatsAppConversationsOut
    SET
    conversationStatus = @conversationStatus
    , finishedBy = case when @conversationStatus in(4,10,17,18) then 2
    when @conversationStatus in(11) then 1
        else 0 end
    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

    WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
    BEGIN
        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=6

        IF @conversationStatus in(4,10,11,13,17,18) BEGIN
            DECLARE @conversationDateTemp INT;
            select @camId = CamId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
            from ccWhatsAppConversationsOut where conversationId = @conversationId;

            IF @conversationStatus = 13 BEGIN
                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam with(nolock) where NumberClient = @clientId) BEGIN
                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@camId, @agentId, @conversationId, @clientId);
                END
            END
            ELSE IF @conversationStatus in(4,10,17,18) BEGIN --Save conversation Ended by system
                IF @conversationDateTemp > 0 BEGIN
                    UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
                END
                ELSE BEGIN
                        UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1) WHERE CamId = @camId
                END
            END
            ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
                UPDATE ccWAOperatingSummaryOut SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
            END
        END
        update @TablaTemp set status=1 where conversationId=@conversationIdTemp
    END

END;

else IF @action = 3
BEGIN --save conversation Status
    UPDATE ccWhatsAppConversationsOut SET conversationStatus = @conversationStatus WHERE conversationId = @conversationId;
END;

else IF @action = 4 BEGIN --save messages from conversation
    IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId)
        AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversationsOut A with(nolock) WHERE A.messageId=@messageId)
    BEGIN
        IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
            (SELECT messageIdUi
                FROM ccWAMessagesConversationsOut
                WHERE originType IN (''Agent'', ''Admin'')
                AND conversationId = @conversationId)
            BEGIN
                UPDATE ccWhatsAppConversationsOut
                    SET FirstMessageAgent = @timeStampMessage
                    WHERE conversationId = @conversationId;
            END

        INSERT INTO [ccWAMessagesConversationsOut](
        messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
        (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
        SELECT @messageId=SCOPE_IDENTITY()
       
       SELECT @camId=camId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId
        if not exists(select * from ccWAConversationsResult where camId=@camId)begin
            insert into ccWAConversationsResult values(@camId,0,0,0,0,0)
        end
        exec ccsp_ConversationWASaveOut @action=16,@messageStatus=@messageStatus,@conversationId=@conversationId
        
         SELECT @messageId as MessageId
        
        RETURN (0)
    END
    ELSE BEGIN
        SELECT 0 AS MessageId
        RETURN (0)
    END
END;

else IF @action = 5
BEGIN --save onQueue
    UPDATE ccWhatsAppConversationsOut
            SET onQueue = 1,
            conversationStatus = @conversationStatus
    WHERE conversationId = @conversationId;
    SELECT @camId = camId FROM ccWhatsAppConversationsOut where conversationId=@conversationId;
    UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue + 1) WHERE camId = @camId
END;

else IF @action = 6
BEGIN --save agent, assigdate and tqueue
    declare @agentIdTmp int
    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversationsOut A with(nolock) where A.conversationId = @conversationId
       
        UPDATE ccWhatsAppConversationsOut
                SET agentId = @agentId,
                assignDate = getdate(),
                conversationStatus = @conversationStatus
                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
        WHERE conversationId = @conversationId;

    SELECT @conversationId as conversationId
    SELECT @camId = camId,  @onQueue = onQueue FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;

    IF @onQueue = 1 BEGIN
     UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue - 1) WHERE camId = @camId   
    END
END;

 Else IF @action = 7
BEGIN --update price message
    UPDATE ccWAMessagesConversationsOut SET price = @price, currency = @currency WHERE messageId = @messageId;
END;
else IF @action = 8
BEGIN --update status message
    IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A with(nolock) 
        WHERE A.messageId=@messageId) <> ''read'' 
    BEGIN
        UPDATE ccWAMessagesConversationsOut
        SET messageStatus = @messageStatus
        WHERE messageId = @messageId;
        exec ccsp_ConversationWASaveOut @action=16,@messageStatus=@messageStatus,@conversationId=@conversationId
        
    END;
END;

else IF @action = 9
BEGIN --Save last message time by conversationID
    IF (SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversationOut A with(nolock) 
        WHERE A.conversationId=@conversationId) IS NULL BEGIN
        INSERT INTO ccLastMessageAgentByConversationOut (conversationId) VALUES (@conversationId)
    END;
    ELSE
        BEGIN
            UPDATE ccLastMessageAgentByConversationOut
                SET timeStampLastMessageAgent = getDate()
            WHERE conversationId = @conversationId;
        END;
END;

else IF @action = 10
BEGIN --drop and insert register by conversationID
    DELETE FROM ccLastMessageAgentByConversationOut WHERE conversationId = @conversationId;
END;

Else IF @action = 11
BEGIN --register desconnection agent by conversationID
    exec ccsp_ConversationWASaveOut @action = 9, @conversationId=@conversationId
END;

else IF @action = 12  BEGIN --Obtain conversationsWA post MCS reset
    declare @disconnectionIdTemp int = (select top 1 disconnectionId from [ccDisconnectionMCSOut] with(nolock) 
    where timeStampConnection is null order by timeStampDisconnection desc);
    UPDATE ccDisconnectionMCSOut SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

    declare @from as datetime;
    select @from = convert(datetime,convert(varchar(11),getdate()))
    set @from=DATEADD(dd,-1,@from);
        select A.conversationId, A.camId as inboundId, A.phoneCamp as phoneACD
        , A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, isnull(A.onQueue,0) onQueue, A.agentId, 
        isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, 
        isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
        ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
        from ccWhatsAppConversationsOut A with(nolock) 
        left join ccWAMessagesConversationsOut B with(nolock) on A.conversationId = B.conversationId
        left join [ccDisconnectionMCSOut] C with(nolock) on C.disconnectionId = @disconnectionIdTemp        
        where A.requestDate >= @from 
            and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
        order by agentId desc, requestDate,timeStampMessage, camId, clientId 
END;
else IF @action = 13
BEGIN ---Obtain agents ON STATUS READY
    WITH agents
    AS(
        SELECT c.User_id, c.fecha, c.currentStatus
        FROM ccLogAgentesDia c
        INNER JOIN 
        (
            SELECT User_id, MAX(fecha) max_time
            FROM ccLogAgentesDia with(nolock)
            where fecha>=CONVERT(date,getdate(),121)
            GROUP BY User_id
        ) AS t
        ON c.fecha = t.max_time
        AND c.User_id=t.User_id AND currentStatus in (3,34)
    ), usersByCampigns
    AS (
        select IdCampEsp, User_id from ccRIACampEspWG A
        Inner join ccRIAWorkGroupUsers B
        on A.IDWG = B.IDWG
        Inner join contactMeanOut C
        ON A.idCampEsp = C.camp_id
        where A.IDWG = 1 and A.Tipo = 1
        AND C.meanContactTypeId = 5
    )

    select DISTINCT A.User_Id from agents A
    left join usersByCampigns B on A.User_Id = B.User_Id
END;

else IF @action = 14
BEGIN --register desconnection MCS
    INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
END;
ELSE IF @action = 15
    BEGIN --update content message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversationsOut
                    SET content = @content
            WHERE messageId = @messageId;
        END;
    END;
ELSE IF @action = 16 BEGIN --update content message
    if @camId is null or @camId=0 begin 
        SELECT @camId=camId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId
    end
                
    if @messageStatus=''submitted'' begin
        update ccWAConversationsResult set SentMsg= SentMsg+1
    end
    else if @messageStatus=''delivered'' begin
        update ccWAConversationsResult set SentMsg= SentMsg-1,Delivered=Delivered+1
    end
    else if @messageStatus=''read'' begin
        update ccWAConversationsResult set Delivered=Delivered-1,ReadMsg=ReadMsg+1
    end
    else if @messageStatus=''rejected'' begin
        update ccWAConversationsResult set SentMsg= SentMsg-1,NotDelivered=NotDelivered+1
    end

    SELECT @messageId as MessageId
END;
ELSE IF @action = 17 BEGIN --update agent status for reassigning error message
    print(''Falata agregar columna'')
    UPDATE ccWhatsAppConversationsOut
    SET IsAgentLoggingOut = @IsAgentLoggingOut
    WHERE conversationId = @conversationId;
END;
ELSE IF @action = 18 BEGIN
    DECLARE @dateNow DATETIME;
    SET @dateNow = DATEADD(HOUR, -23, GETDATE());

    UPDATE ccWhatsAppConversationsOut 
    SET finishedBy = 2, conversationStatus=17
    WHERE finishedBy = 0  AND requestDate <= @dateNow   
END;
END;'
        EXEC(@sql);


        SET @process = 'ALTER SP ccsp_WhatsAppInformation @Option=1 se modifica para poder validar que este no regrese valores negativos'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformation]
@Option SMALLINT,
@InboundId SMALLINT = 0,
@ConversationId INT = 0,
@AgentsAvailables INT = 0,
@IncreaseDecreaseAgent BIT = NULL

AS
SET NOCOUNT ON

IF @Option = 0 BEGIN-- Reset TABLES
    TRUNCATE TABLE ccWAOperatingSummary;
    TRUNCATE TABLE ccWAAverageConversations;
    TRUNCATE TABLE ccLastMessageAgentByConversation;
END


IF @InboundId IS NULL or  
NOT EXISTS (SELECT * FROM ccInbound with(nolock) WHERE Inbound_id = @InboundId AND chat = 5) 
BEGIN
RETURN (-1)
END

    DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
    
IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversations with(nolock)
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

    if exists (select * from ccWAOperatingSummary with(nolock) where Inboundid=@InboundId
    and (OnQueue<0 or Assigned<0)
    ) begin                                
        set @Today =convert(date,getdate(),121)

        ;with waOperationSummary as(
                select 
        inboundId
        --,count(case when finishedBy=1 then 1 end) Attend
        ,count(case when onQueue=1 and finishedBy=0 then 1 end) onQueue
        ,count(case when finishedBy=0 and agentId>0 then 1 end) Assigned
        --,count(*) Request
        --,count(case when finishedBy=2 then 1 end) EndedBySystem
        from ccWhatsAppConversations with(nolock)
        where inboundId=@InboundId
        and requestDate>=@Today
        group by inboundId
        )
        update A 
        set A.OnQueue=B.onQueue, A.Assigned=B.Assigned
        from ccWAOperatingSummary A 
        inner join waOperationSummary B on A.Inboundid=B.inboundId
    end


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
ELSE IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
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
ELSE IF @Option = 3 -- Save time from accepted conversation by agent
    BEGIN
        IF @ConversationId IS NOT NULL
        BEGIN
            UPDATE ccWhatsAppConversations SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
            --Save Conversation Assigned
            SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
            UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE InboundId = @inboundId
            --EXEC ccsp_WhatsAppOperatingSummary @Option = 2, @InboundId = @CampIdTemp;
        END
    END
ELSE IF @Option = 4 -- Get Disposition Information
    BEGIN
        declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
        select @nIdioma = case valor when 0 then ''Sin calificación'' else ''No disposition'' end
        from ccsettings where setting_id = 27 -- 0esp
        SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
                        ISNULL(disposition.calif_id, 0) AS DispositionId,
                        COUNT(whatsConv.disposition) AS Total,
                        ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
                        COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
        FROM ccWhatsAppConversations whatsConv with(nolock) 
        LEFT JOIN cctipocalif disposition ON disposition.calif_id = whatsConv.disposition
        WHERE inboundId = @InboundId AND assignDate >= @Today
                and whatsConv.conversationStatus != 2
        GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
    END
ELSE IF @Option = 5 -- Get Subdisposition Information
    BEGIN
        SELECT relation.calif_id AS DispositionId,
                subDispositions.califSubDesc AS SubDispositionsName,
                COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
        FROM cctipoSubCalifRel relation
        INNER JOIN ccTipoCalifSub subDispositions ON subDispositions.califSub_id = relation.califSub_id
        INNER JOIN ccWhatsAppConversations whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
        WHERE whatsConv.inboundId = @InboundId AND
                whatsConv.assignDate >= @Today AND
                relation.tipoSubRel = 1
        GROUP BY subDispositions.califSubDesc, relation.calif_id
    END
ELSE IF @Option = 6 -- Agents Availables
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

RETURN(0)
SET NOCOUNT OFF'
        EXEC(@sql);
        
        set @process = 'Alter SP ccsp_WhatsAppInformationOut --IF @Option = 0  error nombre ccWAAverageConversationsOut'
        set @sql='ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformationOut]
@Option SMALLINT,
@camId SMALLINT = 0,
@ConversationId INT = 0,
@AgentsAvailables INT = 0,
@IncreaseDecreaseAgent BIT = NULL

AS
SET NOCOUNT ON
IF @camId>0 and NOT EXISTS (SELECT * FROM ccCamps WHERE cam_Id = @camId AND CampType = 5) BEGIN
    print (''Camp Is Not WhatsApp'')
    return(-1);
End

 
      
DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
--set @Today SMALLDATETIME = ''2022-03-24''
IF @Option = 0 BEGIN-- Reset TABLES
    TRUNCATE TABLE ccWAConversationsResult
    TRUNCATE table ccWAOperatingSummaryOut;
    TRUNCATE TABLE ccWAAverageConversationsOut;
    TRUNCATE TABLE ccLastMessageAgentByConversationOut;
END    
else IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut
                WHERE CamId = @camId
                AND (LastUpdate IS NULL
                OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
    BEGIN
        -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

        DECLARE @AverageConversationTime INT = 0;
        DECLARE @AverageDialogTime INT = 0;
        DECLARE @AverageWaitingTime INT = 0;
        DECLARE @MaximumWaitingTime INT = 0;
        DECLARE @DefaultValue INT = 2
        

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
        FROM ccWhatsAppConversationsOut with(nolock) WHERE camId = @camId
        AND requestDate >= @Today

        SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

        ----------------------------------------------------- Update table --------------------------------------------------------

        IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE camId = @camId)
        BEGIN
            UPDATE ccWAAverageConversationsOut
            SET AverageConversationTime = @AverageConversationTime,
                AverageDialogTime = @AverageDialogTime,
                AverageWaitingTime = @AverageWaitingTime,
                MaximumWaitingTime = @MaximumWaitingTime,
                ServiceLevel = @ServiceLevel,
                StatusUpdate = 0,
                LastUpdate = GETDATE()
            WHERE CamId = @camId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversationsOut (CamId, AverageConversationTime, AverageDialogTime,
                                                    AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
            VALUES(@camId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                    @ServiceLevel, 0 , GETDATE())
        END
    END
    --------------------------------- Results -----------------------------------

    if exists (select * from ccWAOperatingSummaryOut with(nolock) where CamId=@camId
                and (OnQueue<0 or Assigned<0)
                ) begin
                
            set @Today =convert(date,getdate(),121)

            ;with waOperationSummary as(
            select 
            CamId
            ,count(case when finishedBy=1 then 1 end) Attended
            ,count(case when onQueue=1 and finishedBy=0 then 1 end) onQueue
            ,count(case when finishedBy=0 and agentId>0 then 1 end) Assigned
            ,count(*) Request
            ,count(case when finishedBy=2 then 1 end) EndedBySystem
            from ccWhatsAppConversationsOut with(nolock)
            where camId = @camId and requestDate>=@Today
            group by CamId
            )
            update A 
            set A.Attended=B.Attended, A.Assigned=B.Assigned
            
            ,A.Request=B.Request,A.EndedBySystem=B.EndedBySystem
            from ccWAOperatingSummaryOut A 
            inner join waOperationSummary B on A.CamId=B.CamId
    end

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
    FROM ccWAAverageConversationsOut conv
    RIGHT JOIN ccWAOperatingSummaryOut summary ON conv.CamId = summary.camId
    WHERE conv.CamId = @camId OR summary.camId = @camId
END
else IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
                -- Average Queue/Waiting Time, and Service Level)
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE CamId = @camId)
        BEGIN
            UPDATE ccWAAverageConversationsOut SET StatusUpdate = 1
            WHERE CamId = @camId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversationsOut (CamId, StatusUpdate)
            VALUES(@camId, 1)
        END
END
else IF @Option = 3 -- Save time from accepted conversation by agent
BEGIN
    IF @ConversationId IS NOT NULL
    BEGIN
        UPDATE ccWhatsAppConversationsOut SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
        --Save Conversation Assigned
        SELECT @camId = camId FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;
        UPDATE ccWAOperatingSummaryOut SET Assigned = (Assigned + 1) WHERE camId = @camId
        
    END
END
else IF @Option = 4 -- Get Disposition Information
BEGIN
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
select @nIdioma = case valor when 0 then ''Sin calificaci?n'' else ''No disposition'' end
from ccsettings where setting_id = 27 -- 0esp
SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
        ISNULL(disposition.calif_id, 0) AS DispositionId,
        COUNT(whatsConv.disposition) AS Total,
        ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
        COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
FROM ccWhatsAppConversationsOut whatsConv with(nolock)
LEFT JOIN ccTipoCalifOUT disposition ON disposition.calif_id = whatsConv.disposition
WHERE camId = @camId AND assignDate >= @Today
    and whatsConv.conversationStatus != 2
GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
END
else IF @Option = 5 -- Get Subdisposition Information
BEGIN
    SELECT relation.calif_id AS DispositionId,
            subDispositions.califSubDesc AS SubDispositionsName,
            COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
    FROM cctipoSubCalifRel relation
    INNER JOIN ccTipoCalifSubOUT subDispositions ON subDispositions.califSub_id = relation.califSub_id
    INNER JOIN ccWhatsAppConversationsOut whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
    WHERE whatsConv.camId = @camId AND
            whatsConv.assignDate >= @Today AND
            relation.tipoSubRel = 0
    GROUP BY subDispositions.califSubDesc, relation.calif_id
END
ELSE IF @Option = 6 -- Agents Availables
BEGIN
    IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId)
        BEGIN
            INSERT INTO ccWAOperatingSummaryOut (camId, Available) VALUES (@camId, @AgentsAvailables);
        END
    ELSE
        BEGIN
            UPDATE ccWAOperatingSummaryOut SET Available = @AgentsAvailables WHERE camId = @camId
        END
END

ELSE IF @Option = 7 -- Whats Conversations Results
BEGIN
    SELECT ISNULL(SentMsg, 0) AS SentMsg,
            ISNULL(Delivered, 0) AS Delivered,
            ISNULL(NotDelivered, 0) AS NotDelivered,
            ISNULL(ReadMsg, 0) AS ReadMsg,
            ISNULL(NotSupported, 0) AS NotSupported
    FROM ccWAConversationsResult
    WHERE camId = @camId
END
    
SET NOCOUNT OFF'
        EXEC(@sql)

     SET @process = ''
     SET @sql = ''
     EXEC(@sql);


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
