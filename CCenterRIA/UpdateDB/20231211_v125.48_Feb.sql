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
    ---------------------------------- Begin fix/125.20231211.0.10 ----------------------------------
     SET @process = 'Alter SP CofetelActions'
     SET @sql = 'ALTER PROCEDURE [dbo].[CofetelActions]
@type tinyint
as
if @type = 1
begin
    truncate table SeriesTmp
end
        
if @type = 2
begin
    if exists(select * from SeriesTmp) begin
        truncate table Series
    end
end'
     EXEC(@sql);

      SET @process = 'ALTER Sp CofetelUpdateData Add Transaction'
     SET @sql = 'ALTER PROCEDURE [dbo].[CofetelUpdateData]
@type tinyint
as
if @type = 1
begin

    BEGIN TRAN  
        exec CofetelActions @type=2     
        if not exists(select * from Series) begin
            insert into Series
            select * from SeriesTmp
        end     
    COMMIT TRAN
end'
     EXEC(@sql);
    
---------------------------------- Begin fix/125.20231211.0.10 ----------------------------------
------------------------ BEGIN  CW-8389 Error al consultar el finder por día y rango de fechas no se muestra información Marco Garcia -----------------------------
set @process = 'CW-8389 Error al consultar el finder por día y rango de fechas no se muestra información delete sp ccsp_BaseXmngr'
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_BaseXmngr'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_BaseXmngr]
        END'
EXEC(@sql)

SET @process = 'CW-8389 Error al consultar el finder por día y rango de fechas no se muestra información, se modifica el @action'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@ids varchar(max)=null,
@name varchar(25) = NULL,
@top int = 0,
@dateIni datetime =null,
@dateEnd datetime =null,
@dateStart dateTime= null,
@userId int = 0,
@node varchar(10) = null,
@grabIds varchar(4000) = null
AS

declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
declare @filterWg varchar(max)
declare @len int
declare @tipo int
declare @serviceId varchar(10)

set @sql = ''''

select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=@option 

if @action in (1,6) begin --obtiene los nodos a insertar en BX
    if @action = 1 set @status =0
    else if @action = 6 set @status = 2

    if @option <>2 begin

    declare @auxTag nvarchar(10)
                            
    select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02''
    else ''@CDATE''   end
    set @parameterDefinition =N''@status int, @top int,@option int''
    set @sql=''declare @basexName varchar(max)
select @basexName=Xname from ccBaseXDB where serviceId=@option and isFull=0;
    with node ( ''+@columnId+ '',xmlString,dateNode)
    AS(
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableName + '' A with(rowlock)
        where A.status =@status
        union
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableNameHistory + '' A with(rowlock)
        where A.status =@status  
    )

    select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
    left join ccBaseXDB baseX on baseX.serviceId= @option and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
    order by baseX.Xname''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top,@option=@option
    end
end
else if @action in (2,7) begin--actualiza los nodos insertados en BX
    if @action = 2 set @status =0
    else if @action = 7 set @status = 2

    set @parameterDefinition =N''@status int''

    set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    select @tableName,@columnId,@ids,@sql
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
    set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status

end
else if @action = 3 --trae el nombre de la base de datos en BX
begin
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
    insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
end
else if @action = 5 begin --obtener servicios disponibles    
    select id, ref  from ccFinderServices where isActive=1
end
else if @action = 8 begin--trae la lista de las bases para la busqueda
    select Xname from ccBaseXDB where serviceId = @option
    and (

    @dateIni between dateStart and dateEnd
    or @dateEnd between dateStart and dateEnd
    or dateStart between @dateIni and @dateEnd
    )
    union
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
    and (
        dateStart between @dateIni and @dateEnd
        or @dateIni>=dateStart

    )
end
else if @action = 9 begin--Cierra la base datos
    update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()), dateStart=isnull(@dateStart,dateStart) where serviceId= @option and  isfull = 0 and dateEnd is null
    and Xname=@name
end

else if @action = 10 begin
    
    set @tipo = CASE WHEN @node = ''R06'' THEN 1 ELSE 0 END
    set @filterWg=''''
    if @node is null or @node = ''R02''
    begin
        select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId
                        
    end
    else
    begin
    
    set @serviceId = (select convert(varchar(10), id) from ccFinderServices where ref = @node)
    select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+@serviceId+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId and WGCam.Tipo=@tipo
    end


    set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
    select SUBSTRING(@filterWg,0, @len)
    end


else if @action = 11 begin--trae el nombre de la base de datos en BX

    set @sql=''
    declare @dateStart datetime
    set @dateStart= convert(datetime,convert(varchar(10),getdate(),121))
    SELECT isnull(min(dateIn),@dateStart) as node FROM ''+@tableName+'' where status = 0  ''
    EXECUTE sp_executesql  @sql

end

else if @action = 13 begin
    set @sql = ''''
    select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=5 
    select @tableName,@tableNameHistory,@columnId
    set @sql=''
    ;
    with duplicateIds as(
    select ''+@columnId+'',dateIn from ''+@tableName+'' where ''+@columnId+'' in(''+@grabIds+'')
    union
    select ''+@columnId+'',dateIn from ''+@tableNameHistory+'' where ''+@columnId+'' in(''+@grabIds+'')
    )

    select A.''+@columnId+'' as Id,min(B.Xname) Xname from duplicateIds A
    inner join ccbasexDB B on B.serviceId=2 and( A.dateIn between B.dateStart and B.dateEnd or A.dateIn>= B.dateStart)
    group by A.''+@columnId+'',A.dateIn
    Having count(*)>1
    order by Xname
    ''
    exec (@sql)

end

else if @action = 14 begin
    declare @CidNameOut varchar(100),@CidNameIn varchar(100)
    declare @filterCamId varchar(max), @filterInboundId varchar(max);
    declare @campType int
    declare @cidOut varchar(max)=''''
    declare @cidin varchar(max)=''''

    set @filterWg=''''
    if @node is null begin
        set @node=''R02''
    end

    set @CidNameOut=''$CID_OUT_''+@node
    set @CidNameIn=''$CID_In_''+@node

    set @filterCamId=''''
    

    if @node = ''R02''
    begin
        select @filterCamId=@filterCamId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
        from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        inner join ccCamps c on c.cam_id=WGCam.IdCampEsp and c.CampType not in(5,7)
        where Wguser.User_id=@userId and WGCam.Tipo=1                               
    end
    else if @node = ''R05''
    begin       
        select @filterCamId=@filterCamId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
        from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        inner join ccCamps c on c.cam_id=WGCam.IdCampEsp and c.CampType =5
        where Wguser.User_id=@userId and WGCam.Tipo=1                       
    end

    if @filterCamId<>'''' begin
        if @node in( ''R02'',''R05'') begin
            set @filterWg=''let ''+@CidNameOut+'':=(''
        end

        set @filterCamId=SUBSTRING(@filterCamId,0,len(@filterCamId))
        set @filterCamId=@filterCamId+'')''+char(10)    

        set @filterWg=@filterWg+@filterCamId
    end 
        
    set @tipo = case when @node in(''R01'',''R02'',''R03'',''R04'') then 1  
        when @node =''R05'' then 5 
        when @node =''R06'' then 6 
        else 0 end -- revisar ccsp_CreateNodeMultimedia CTYPE

    set @campType = case when @node =''R01'' then 1 
        when @node =''R02'' then 0
        when @node =''R03'' then 3
        when @node =''R04'' then 4
        when @node =''R05'' then 5
        when @node =''R06'' then 6 else 0 end

    SET @filterInboundId= ''''
            
    select @filterInboundId=@filterInboundId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
    from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        inner join ccInbound c on c.Inbound_id=WGCam.IdCampEsp and c.chat =@campType
        where Wguser.User_id=@userId and WGCam.Tipo=0
    
    if @filterInboundId<>'''' begin
        set @filterInboundId=SUBSTRING(@filterInboundId,0,len(@filterInboundId))
        set @filterInboundId=@filterInboundId+'')''+char(10)    

        set @filterWg=@filterWg+''let ''+@CidNameIn+'':=(''+@filterInboundId
    end
    
    if @node = ''R02'' BEGIN
        IF(@filterCamId <> '''')
        BEGIN
            SET @cidOut=''(exists(index-of(''+@CidNameOut+'',@CID)) and @CType=2)''
        END
    end
    else if @node = ''R06'' begin
        set @cidOut=''(exists(index-of(''+@CidNameOut+'',@CID)) and @CType=6)''
    end
    if @node not in(''R05'') BEGIN
        IF(@filterInboundId <> '''')
        BEGIN
            set @cidin=''(exists(index-of(''+@CidNameIn+'',@CID)) and @CType=''+ convert(varchar(max), @tipo)+'')''
        END
    end
    
    select @filterWg as VarCamInOut,@cidOut as CidOut,@cidin as CidIn
end
else if @action = 15 begin --Saber si hacer busqueda en basex
  select @tableName=tableName,@tableNameHistory=tableNameHistory from ccFinderServices where ref=@node
  if @node=''R02'' begin
    select 1
    return(0)
  end

  set @sql=''if exists(select * from ''+@tableName+'') begin
        select 1
    end
    else if exists(select * from ''+@tableNameHistory+'') begin
        select 1
    end
    select 0''
    exec (@sql)
    
end'

EXEC(@sql)

------------------------ END  CW-8389 Error al consultar el finder por día y rango de fechas no se muestra información Marco Garcia -----------------------------
               
----------------------------------------------------------------------------------- BEGIN Ivan Martin Fix Numeros Duplicados WhatsApp --------------------------------------------------------------------------

     SET @process = 'Drop procedure ccsp_MultimediaCommon'
     SET @sql = 'if exists (select 1 from sys.procedures where name = N''ccsp_MultimediaCommon'')
                begin
                    DROP PROCEDURE ccsp_MultimediaCommon;
                end'
     EXEC(@sql);


     SET @process = 'Se modifica action 1 para que tome el campo de Phone de ccWhatsAppNumbers en lugar de contactMeanIn, homologando esto con el accion 0'
     SET @sql = '
                    CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon]
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
                        c.IsAgentLoggingOut AS IsAgentLoggingOut
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
                            c.agentId AS AgentId
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
                            DECLARE @mensajes TABLE(idMessage VARCHAR(100));
                            DECLARE @tmpMessageConversations TABLE(
                                    [messageId] VARCHAR(75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
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

     ----------------------------------------------------------------------------------- END Ivan Martin Fix Numeros Duplicados WhatsApp --------------------------------------------------------------------------


	 ----------------------------------------------------------------------------------- BEGIN Marco García --------------------------------------------------------------------------
	 

--------------- TT9016-AdminKolob-Eroor en listas negras ---------

SET @process = 'TT9016-AdminKolob-Eroor en listas negras eliminar función Completa si existe'
		SET @sql = 'IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N''[dbo].[Completa]'')
                  AND type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
			BEGIN
			  DROP FUNCTION [dbo].[Completa]
			END'
		EXEC(@sql)

SET @process = 'TT9016-AdminKolob-Eroor en listas negras crea función Completa si existe, se modificó el apartado de Guatemala'
		SET @sql = 'CREATE FUNCTION [dbo].[Completa] (@phone VARCHAR(32), @pais VARCHAR(2) = '''', @cldLocal VARCHAR(5) = '''')
RETURNS VARCHAR(32)
AS
BEGIN
	DECLARE @resultado VARCHAR(32)
	DECLARE @ld VARCHAR(7)
	DECLARE @isLocal BIT
	IF @pais = ''''
	BEGIN
		SELECT @pais = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 104
	END
	IF @cldLocal = ''''
	BEGIN
		SELECT @cldLocal = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 17
	END
	SELECT @phone = dbo.limpia(@phone)
	SELECT @resultado = @phone
	DECLARE @lenPhone INT, @lenLd INT
	SET @lenPhone = len(@resultado)
	SET @lenLd = len(@cldLocal)
	IF @pais = 1
	BEGIN --Empieza Mexico 		
		IF @lenPhone < 10
		BEGIN
			RETURN ''E_NV_Longitud'';
		END
		IF @lenPhone = 12 AND left(@phone, 2) <> ''01''
		BEGIN
			RETURN ''E_NV_Longitud'';
		END
		IF @lenPhone = 13 AND left(@phone, 3) NOT IN (''044'', ''045'')
		BEGIN
			RETURN ''E_NV_Longitud'';
		END
		SET @resultado = right(@resultado, 10)
		SET @isLocal = 0
		DECLARE @specialDialPlan TINYINT
		SELECT @specialDialPlan = valor
		FROM ccsettings WITH (NOLOCK)
		WHERE setting_id = 195
		IF EXISTS (
				SELECT TOP 1 area
				FROM ccRiaArecode NOLOCK
				WHERE area = left(@resultado, 3)
				)
			SELECT @ld = left(@resultado, 3), @isLocal = 1
		ELSE IF EXISTS (
				SELECT TOP 1 area
				FROM ccRiaArecode NOLOCK
				WHERE area = left(@resultado, 2)
				)
			SELECT @ld = left(@resultado, 2), @isLocal = 1
		ELSE
		BEGIN
			SET @ld = @cldLocal
			IF left(@resultado, len(@ld)) = @ld
			BEGIN
				SET @isLocal = 1
			END
		END
		SET @lenLd = len(@ld)
		IF @specialDialPlan = 1
		BEGIN
			--Number local 10 digit
			--Number LD 12 digit
			--Number Cell 13 digit
			SELECT @resultado = CASE WHEN @lenPhone = 10 THEN CASE WHEN @isLocal = 1 THEN @resultado ELSE ''01'' + @resultado END --10 Dig Local, LD
					WHEN @lenPhone = 12 THEN CASE WHEN @isLocal = 1 THEN @resultado ELSE @phone END --12 Dig Local, LD
					WHEN @lenPhone = 13 THEN CASE WHEN @isLocal = 1 THEN ''044'' + @resultado ELSE ''045'' + @resultado END --13 Dig Local, LD
					ELSE ''E_NV_Longitud'' END --Other Long
		END
		ELSE IF @specialDialPlan = 0
		BEGIN
			--Number local 7 o 8 digit
			--Number LD 12 digit
			--Number Cell 13 digit
			SELECT @resultado = CASE WHEN @lenPhone = 10 THEN CASE WHEN @isLocal = 1 THEN right(@resultado, 10 - @lenLd) ELSE ''01'' + @resultado END --10 Dig Local, LD
					WHEN @lenPhone = 12 THEN CASE WHEN @isLocal = 1 THEN right(@resultado, 10 - @lenLd) ELSE @phone END --12 Dig Local, LD							
					WHEN @lenPhone = 13 THEN CASE WHEN @isLocal = 1 THEN ''044'' + @resultado ELSE ''045'' + @resultado END --13 Dig Local, LD
					ELSE ''E_NV_Longitud'' END
		END
		--Termina Mexico
		RETURN @resultado
	END
	ELSE IF @pais = 2
	BEGIN -- Empieza Argentina
		SELECT @resultado = CASE WHEN (@lenPhone = 7 AND @lenLd = 3) OR (@lenPhone = 6 AND @lenLd = 4) THEN @resultado
						-- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
						-- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
				WHEN @lenPhone = 8 THEN CASE WHEN @lenLd = 4 THEN CASE WHEN left(@resultado, 2) = ''15'' THEN @resultado END ELSE CASE WHEN @lenLd = 2 THEN @resultado END END
						-- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
				WHEN @lenPhone = 9 THEN CASE WHEN left(@resultado, 2) = ''15'' THEN @resultado ELSE ''E_NV_Cel'' END
						-- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
						-- Si es diferente se le agrega un 0 para llamadas de larga distancia
				WHEN @lenPhone = 10 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE CASE WHEN left(@resultado, 2) = ''15'' THEN @resultado ELSE ''0'' + @resultado END END
						-- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
						-- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
				WHEN @lenPhone = 11 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE @resultado END ELSE ''E_NV_LD'' END
						-- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
						-- si no es local se le agrega el 0 y se marca el numero
				WHEN @lenPhone = 12 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN CASE WHEN substring(@resultado, @lenLd + 1, 2) = ''15'' THEN right(@resultado, 12 - @lenLd) ELSE ''E_NV_Cel'' END ELSE ''0'' + @resultado END
						-- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
				WHEN @lenPhone = 13 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN substring(@resultado, @lenLd + 2, 12 - @lenLd) ELSE @resultado END ELSE ''E_NV_Cel'' END ELSE ''E_NV_Longitud'' END
		--Termina Argentina
		RETURN @resultado
	END
	ELSE IF @pais = 3
	BEGIN --Empieza colombia
		SELECT @resultado = CASE 
				--Si son 7 digitos, se regresa igual
				WHEN @lenPhone = 7 THEN @resultado
						--Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
				WHEN @lenPhone = 8 THEN CASE WHEN left(@resultado, 1) = @cldLocal THEN right(@resultado, 7) ELSE @resultado END
						-- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
				WHEN @lenPhone = 10 THEN CASE WHEN left(@resultado, 3) IN (''300'', ''301'', ''302'', ''303'', ''304'', ''305'', ''310'', ''311'', ''312'', ''313'', ''314'', ''315'', ''316'', ''317'', ''318'', ''319'', ''320'') THEN ''0'' + @resultado ELSE ''E_NV_Cel'' END
						--Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
						--prefijo de celular
				WHEN @lenPhone = 11 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 2, 3) IN (''300'', ''301'', ''302'', ''303'', ''304'', ''305'', ''310'', ''311'', ''312'', ''313'', ''314'', ''315'', ''316'', ''317'', ''318'', ''319'', ''320'') THEN @resultado ELSE ''E_NV_Cel'' END ELSE ''E_NV_Cel'' END ELSE ''E_NV_Longitud'' END
		-- Termina Colombia
		RETURN @resultado
	END
	ELSE IF @pais = 4
	BEGIN --Empieza USA
		SELECT @resultado = CASE @lenPhone WHEN 3 THEN CASE @resultado WHEN ''911'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 7 THEN @resultado WHEN 10 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE ''1'' + @resultado END WHEN 11 THEN CASE WHEN left(@resultado, 1) = ''1'' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE @resultado END ELSE ''E_NV_LD'' END ELSE ''E_NV_Longitud'' END
		--Termina USA
		RETURN @resultado
	END
	ELSE IF @pais = 5
	BEGIN --5:Chile
		SELECT @resultado = CASE @lenPhone WHEN 6 THEN @resultado WHEN 7 THEN @resultado
						-- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
				WHEN 8 THEN CASE WHEN @cldLocal = left(@resultado, @lenLd) THEN right(@resultado, 8 - @lenLd) ELSE CASE WHEN left(@resultado, 1) IN (8, 9) THEN ''09'' + @resultado ELSE CASE WHEN left(@resultado, 1) = ''6'' THEN CASE WHEN left(@resultado, 2) IN (61, 63, 64, 65, 67) THEN @resultado ELSE ''09'' + @resultado END ELSE CASE WHEN left(@resultado, 1) = ''7'' THEN CASE WHEN left(@resultado, 2) IN (71, 72, 73, 75) THEN @resultado ELSE ''09'' + @resultado END ELSE @resultado END END END END
						-- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
						-- de telefonia voIp se le agrega el 0 al inicio
				WHEN 9 THEN CASE WHEN @cldLocal = left(@resultado, 2) THEN right(@resultado, 7) ELSE CASE WHEN left(@resultado, 2) IN (41, 32, 65) THEN @resultado ELSE CASE WHEN left(@resultado, 2) = ''44'' THEN ''0'' + @resultado ELSE CASE WHEN left(@resultado, 1) = ''9'' AND substring(@resultado, 2, 1) IN (6, 7, 8, 9) THEN ''0'' + @resultado ELSE ''E_NV_Longitud'' END END END END WHEN 10 THEN CASE WHEN left(@resultado, 2) = ''09'' THEN @resultado ELSE ''E_NV_Cel'' END ELSE ''E_NV_Longitud'' END
		-- Termina Chile
		RETURN @resultado
	END
	IF @pais = 6
	BEGIN -- Venezuela
		SELECT @resultado = CASE @lenPhone WHEN 7 THEN @resultado WHEN 10 THEN ''0'' + @resultado WHEN 11 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN @resultado ELSE ''E_NV_Longitud'' END ELSE ''E_NV_Longitud'' END
		RETURN @resultado
	END
			--Termina Venezuela
	ELSE IF @pais = 7
	BEGIN --7: Reino Unido
		SELECT @resultado = CASE @lenPhone WHEN 11 THEN CASE left(@resultado, 1) WHEN ''0'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 10 THEN CASE left(@resultado, 1) WHEN ''0'' THEN @resultado ELSE ''0'' + @resultado END WHEN 9 THEN CASE WHEN left(@resultado, 1) <> ''0'' THEN ''0'' + @resultado ELSE ''E_NV_Longitud'' END WHEN 8 THEN CASE WHEN substring(@resultado, 1, 2) = ''08'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 7 THEN CASE WHEN left(@resultado, 1) = ''8'' THEN ''0'' + @resultado ELSE ''E_NV_Longitud'' END ELSE ''E_NV_Longitud'' END
		RETURN @resultado
	END
			-- Termina UK
	ELSE IF @pais = 8
	BEGIN -- arabia saudita
		SELECT @resultado = CASE @lenPhone WHEN 7 THEN @resultado WHEN 8 THEN CASE substring(@resultado, 1, 1) WHEN @cldLocal THEN right(@resultado, 7) ELSE ''0'' + @resultado END WHEN 9 THEN CASE substring(@resultado, 1, 1) WHEN ''5'' THEN ''0'' + @resultado WHEN ''0'' THEN CASE substring(@resultado, 2, 1) WHEN @cldLocal THEN right(@resultado, 7) ELSE @resultado END ELSE ''E_NV_Longitud'' END WHEN 10 THEN CASE substring(@resultado, 2, 1) WHEN ''5'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 11 THEN CASE substring(@resultado, 2, 1) WHEN ''8'' THEN CASE substring(@resultado, 3, 3) WHEN ''111'' THEN @resultado ELSE ''E_NV_Longitud'' END ELSE CASE WHEN substring(@resultado, 3, 3) = ''510'' OR substring(@resultado, 3, 3) = ''511'' THEN @resultado ELSE ''E_NV_Longitud'' END END WHEN 13 THEN @resultado ELSE ''E_NV_Longitud'' END
		RETURN @resultado
	END -- arabia saudita
	ELSE IF @pais = 9
	BEGIN --Australia
		SELECT @resultado = CASE @lenPhone WHEN 8 THEN
						/*case when exists (select AreaCode
              from SeriesAU
              where convert(int,LD) = convert(int,@cldLocal)
              and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then*/
						CASE substring(@resultado, 1, 4) WHEN ''5550'' THEN ''E_NV_LD'' ELSE @cldLocal + @resultado END
						/*else case when exists (select AreaCode
              from SeriesAU
              where convert(int,LD) = convert(int,''04'')
              and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then
    ''04'' +  @resultado
    else ''E_NV_Cel'' end end*/
				WHEN 9 THEN CASE WHEN left(@resultado, 1) <> ''0'' THEN CASE substring(@resultado, 2, 4) WHEN ''5550'' THEN ''E_NV_LD'' ELSE ''0'' + @resultado END ELSE ''E_NV_LD'' END WHEN 10 THEN CASE substring(@resultado, 3, 4) WHEN ''5550'' THEN ''E_NV_LD'' ELSE @resultado END ELSE ''E_NV_Longitud'' END
		RETURN @resultado
	END
	ELSE IF @pais = 10
	BEGIN --Brasil
		SELECT @resultado = CASE @lenPhone
				--llamada local fijo o celular
				WHEN 8 THEN @resultado WHEN 9 THEN @resultado WHEN 10 THEN -- Numero nacional
						CASE WHEN left(@resultado, 2) = @cldLocal THEN right(@resultado, 8) ELSE @resultado END WHEN 11 THEN -- Este caso solomente es para numero celular
						CASE WHEN left(@resultado, 2) = @cldLocal THEN right(@resultado, 9) ELSE @resultado END WHEN 12 THEN -- llamadas por cobrar local
						CASE WHEN (left(@resultado, 4) = ''9090'') THEN right(@resultado, 8) ELSE ''E_NV_PC'' END WHEN 13 THEN CASE WHEN left(@resultado, 4) = ''9090'' THEN right(@resultado, 9) -- llamadas por cobrar local celular
							WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 4, 2) = @cldLocal THEN right(@resultado, 8) ELSE right(@resultado, 10) END -- llamadas de LDN
							ELSE ''E_NV_Longitud'' END WHEN 14 THEN CASE WHEN left(@resultado, 2) = ''90'' THEN -- llamadas por cobrar larga distancia
									CASE WHEN substring(@resultado, 5, 2) = @cldLocal THEN right(@resultado, 8) ELSE right(@resultado, 11) END WHEN left(@resultado, 1) = ''0'' THEN --llamada larga distancia a celular
									CASE WHEN substring(@resultado, 4, 2) = @cldLocal THEN right(@resultado, 9) ELSE right(@resultado, 11) END ELSE ''E_NV_Longitud'' END WHEN 15 THEN CASE WHEN left(@resultado, 2) = ''90'' THEN -- Llamadas por cobrar a celular LD
									CASE WHEN substring(@resultado, 5, 2) = @cldLocal THEN right(@resultado, 9) ELSE right(@resultado, 11) END ELSE ''E_NV_Longitud'' END ELSE ''E_NV_Longitud'' END
		RETURN @resultado
	END
	ELSE IF @pais = 11
	BEGIN --Guatemala
		if @lenPhone <> 8 BEGIN
			SELECT @resultado = ''E_NV_Longitud''
		END
		ELSE IF CHARINDEX(substring(@resultado, 1, 1), ''2,3,4,5,6,7,8,9'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END		
		RETURN @resultado
	END
	ELSE IF @pais = 12
	BEGIN --Costa Rica
		IF @lenPhone = 8 AND charindex(substring(@resultado, 1, 1), ''2,3,4,5,6,7,8'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END
		ELSE IF @lenPhone = 10 AND charindex(substring(@resultado, 1, 3), ''800,900,905'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END
		ELSE IF charindex(substring(@resultado, 1, 2), ''00,08'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END
		RETURN @resultado
	END
	ELSE IF @pais = 13
	BEGIN --Salvador
		IF @lenPhone = 8 AND charindex(substring(@resultado, 1, 1), ''2,6,7'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END
		ELSE IF charindex(substring(@resultado, 1, 2), ''00'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END
		RETURN @resultado
	END
	ELSE IF @pais = 14
	BEGIN --Spain
		IF @lenPhone = 9 AND charindex(substring(@resultado, 1, 1), ''5,6,7,8,9'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END
		ELSE IF charindex(substring(@resultado, 1, 2), ''00'') <= 0
		BEGIN
			SELECT @resultado = ''E_'' + @resultado
		END
		RETURN @resultado
	END
	ELSE IF @pais = 15
	BEGIN --Peru
		SELECT @resultado = CASE WHEN (@lenPhone = 7 AND @lenLd = 1) OR (@lenPhone = 6 AND @lenLd = 2) THEN @resultado WHEN @lenPhone = 8 THEN CASE WHEN substring(@resultado, 1, @lenLd) = @cldLocal THEN right(@resultado, 8 - @lenLd) ELSE ''0'' + @resultado END WHEN @lenPhone = 9 THEN CASE WHEN left(@resultado, 1) = ''0'' AND substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 8 - @lenLd) ELSE @resultado END ELSE ''E_NV_Longitud'' END
		RETURN @resultado
	END --Termina Peru
	ELSE IF @pais = 16
	BEGIN --Panama
		SELECT @resultado = CASE WHEN (@lenPhone = 7) THEN CASE WHEN substring(@resultado, 1, 1) IN (''2'', ''3'', ''4'', ''5'', ''7'', ''9'') THEN @resultado ELSE ''E_'' + @resultado END WHEN (@lenPhone = 8) THEN CASE WHEN substring(@resultado, 1, 1) = ''6'' THEN @resultado ELSE ''E_'' + @resultado END ELSE CASE WHEN substring(@resultado, 1, 2) = ''00'' THEN @resultado ELSE ''E_'' + @resultado END END
		RETURN @resultado
	END
	-- Termina
	RETURN @resultado
END'
		EXEC(@sql)

		


SET @process = 'TT9016-AdminKolob-Eroor en listas negras eliminar sp ccsp_InsertDNCList si existe'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_InsertDNCList'')
			BEGIN
				DROP PROCEDURE ccsp_InsertDNCList
			END'
		EXEC(@sql)

SET @process = 'TT9016-AdminKolob-Eroor en listas negras crear sp ccsp_InsertDNCList,  se modifico para el proceso de insertar telefono indivual para lista negra'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30)=null,
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL

AS

Set nocount on


declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)
,@tel10 as varchar(30),@tel11 as varchar(30), @sqlcmd nvarchar(max), @tmpTableName varchar(40), @sqlcmd_replace nvarchar(max),
@dropTmpPhone varchar(max) = null

SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));

if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificación
BEGIN
	IF EXISTS (SELECT * from ccListaNegra where idtipolista = @ln_id and telefono = @telephone and HashKey = dbo.hashList(@calKey)) begin
		RETURN 0;
	end

	set @tmpTableName = ''TMP_BLACKLIST_'' + @telephone;
	SET @dropTmpPhone = ''if exists (select * from sys.tables where name = N'''''' + @tmpTableName + '''''') drop table '' + @tmpTableName;

	SET @sqlcmd = ''CREATE TABLE '' + @tmpTableName + ''(
	[phoneNumber] VARCHAR(30),
	[calKey] VARCHAR(40)); 

	INSERT INTO '' + @tmpTableName + ''(phoneNumber, calKey) values(@telephone,@calKey );
	'';
	EXEC (@dropTmpPhone);	
	EXEC sp_executesql @sqlcmd, N''@telephone varchar(40), @calKey VARCHAR(40)'', @telephone,@calKey;
END


select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

SET @sqlcmd =  ''
UPDATE '' + @tmpTableName + '' SET phoneNumber = dbo.completa(phoneNumber, @pais, @ld);
DELETE '' + @tmpTableName + '' WHERE phoneNumber like ''''%E%'''';

INSERT INTO cclistanegra(telefono,idtipolista,HashKey, calKey)
SELECT phoneNumber, @ln_id as idtipolista, dbo.hashList(calKey) as HashKey, calkey 
FROM '' + @tmpTableName + '';

INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
SELECT phoneNumber as telefono, 7 as idtipomov, @ln_id as idtipolista 
FROM '' + @tmpTableName + '';''

EXEC sp_executesql @sqlcmd, N''@pais varchar(2), @ld VARCHAR(5),@ln_id int'', @pais, @ld,@ln_id;

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall


CREATE TABLE [dbo].[#mycamps] (	[campsid] [int] NULL)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id and B.CampType not in(7,5)


CREATE TABLE [dbo].[#myprincipaltempCall](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltempCall]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltempCall]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltempCall]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltempCall]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltempCall]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltempCall]([cal_telefono5]) 

CREATE TABLE [dbo].[#helpTempCall](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE TABLE [dbo].[#mytempCall](
	[callout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempCall]([callout_id]) 

declare @fech datetime = getdate()-30
	SET @sqlcmd = ''
	insert into [#helpTempCall]
	SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
	FROM [ccoCallsOutSource] as a with(nolock)
	inner join #mycamps as b  on a.cam_id = b.campsid
	inner join '' + @tmpTableName +'' t on 
	t.phoneNumber IN ([SPACE_TEL]) 	AND t.calKey IS NULL
	where  cal_fechadial > getdate()-30
	''
	
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono'')	
	EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;
	
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono2'')	
	EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono3'')	
	EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono4'')	
	EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono5'')
	EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

	

	SET @sqlcmd = ''insert into [#helpTempCall]
	SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
	FROM [ccoCallsOutSource] as a with(nolock)
	inner join #mycamps as b  on a.cam_id = b.campsid
	inner join '' + @tmpTableName +'' t on a.cal_Key=t.calKey
	where cal_fechadial > getdate()-30;
	'';
	
	EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

	INSERT INTO #myprincipaltempCall
	SELECT * FROM #helpTempCall
	GROUP BY callout_id, cam_id, tipomov, idtipolista, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5

if EXISTS (select * from #myprincipaltempCall)
begin
	declare @column nvarchar(max), @sql nvarchar(max)
	,@sqlDeleteWorking nvarchar(max)
	,@sqlUpdateWorking nvarchar(max)
	,@sqlCaseWorking nvarchar(max)
	,@params nvarchar(max)
	,@phoneEmpty varchar(1)
	,@sqlWithReplace nvarchar(max)

	set @phoneEmpty=''''
	set @column=''cal_telefono''
	set @params=''@phoneEmpty varchar(1),@fech datetime''
	set @sqlDeleteWorking=''and cs.cal_telefono2=@phoneEmpty
	and cs.cal_telefono3=@phoneEmpty
	and cs.cal_telefono4=@phoneEmpty
	and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono2<>@phoneEmpty then cs.cal_telefono2 
	when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
	when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
	when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
	else @phoneEmpty end ''

	set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
	update wt 
	set cal_telefono = CASE_UPDATE_WT
	from ccoCallsOutSource cs 
	inner join ccoWOrkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytempCall t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > @fech and cs.COLUMN_CHECK= wt.cal_telefono''

	set @sql=''
insert #mytempCall
select callout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempCall] as a with(nolock)
inner join '' + @tmpTableName + '' t on
t.phoneNumber = COLUMN_CHECK
where COLUMN_CHECK<>@phoneEmpty


if EXISTS (select * from #mytempCall)
begin		
	-- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
	delete wt with(rowlock)
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytempCall t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > @fech and
	cs.COLUMN_CHECK = wt.cal_telefono
	AND_DELETE_WT

	UPDATE_SMS_WT_QUERY

	--insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytempCall where [telefono]<>@phoneEmpty

	-- Eliminamos el telefono1 de CS
	update ccoCallsOutSource 
	set COLUMN_CHECK = @phoneEmpty
	from ccoCallsOutSource cs 
	inner join #mytempCall t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > @fech		

	truncate table #mytempCall
end''

	
	/******************/
	/*** Telefono 1 ***/
	/******************/
	
	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	print(@sqlWithReplace)	
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	

	/******************/
	/*** Telefono 2 ***/
	/******************/
	set @column=''cal_telefono2''
	
	set @sqlDeleteWorking='' and cs.cal_telefono3=@phoneEmpty
		and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
		when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	

	/******************/
	/*** Telefono 3 ***/
	/******************/
	set @column=''cal_telefono3''
	
	set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	
	
	/******************/
	/*** Telefono 4 ***/
	/******************/	
	
	set @column=''cal_telefono4''
	
	set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	
	
	/******************/
	/*** Telefono 5 ***/
	/******************/

	set @column=''cal_telefono5''	
	set @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty''	
	set @sqlCaseWorking=''''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	

end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall
IF @dropTmpPhone IS NOT NULL EXEC (@dropTmpPhone);'
		EXEC(@sql)

SET @process = 'TT9016-AdminKolob-Eroor en listas negras eliminar sp ccsp_GalateaAdminUploadBLst si existe'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAdminUploadBLst'')
			BEGIN
				DROP PROCEDURE ccsp_GalateaAdminUploadBLst
			END'
		EXEC(@sql)

SET @process = 'TT9016-AdminKolob-Eroor en listas negras crear sp ccsp_GalateaAdminUploadBLst,  se modifico para el proceso de eliminar telefono indivual'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminUploadBLst]  @command TINYINT, @telephone VARCHAR(20) = 0, @idtipolista INT, @calKey AS VARCHAR(40) = NULL, @isKolob bit=0
AS
DECLARE @hashCalKey BIGINT, @hashPhone BIGINT

SELECT @hashPhone = dbo.hashPhone(@telephone)

IF @calKey IS NOT NULL
BEGIN
    SELECT @hashCalKey = dbo.hashList(@calKey)
END
        
IF @hashCalKey IS NULL
BEGIN
    IF @command IN (1, 4) --LookForNumber 
    AND EXISTS (
        SELECT idtipolista
        FROM cclistanegra
        WHERE Hashtel = @hashPhone AND (HashKey IS NULL OR HashKey = 0) AND idtipolista = @idtipolista
        )
    BEGIN
    SELECT 1

    RETURN (0)
    END
END
ELSE
        
BEGIN
    IF @command IN (1, 4) --LookForNumber 
    AND EXISTS (
        SELECT idtipolista
        FROM cclistanegra
        WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
        )
    BEGIN
    SELECT 1

    RETURN (0)
    END
END
        
IF @command = 1 --Insert Number
BEGIN
    EXEC ccsp_InsertDNCList @telephone, @idtipolista, @hashCalKey, @calKey
    --print  @telephone
    INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
    VALUES (@telephone, 1, @idtipolista)

    SELECT 200
END

IF @command = 2 --Delete Number
BEGIN
    --Check if phone number exists
    IF EXISTS(SELECT cln.Hashtel FROM dbo.ccListaNegra AS cln WHERE cln.Hashtel = @hashPhone AND cln.idtipolista = @idtipolista)
    BEGIN
            IF @hashCalKey IS NULL OR @hashCalKey = 0
            BEGIN
            --Check if request is from kolob or xion
            IF(@isKolob = 1)
            BEGIN
                --Check if phone number has calKey assigned
                SELECT @hashCalKey = cln.HashKey FROM dbo.ccListaNegra AS cln WHERE cln.Hashtel = @hashPhone AND cln.idtipolista = @idtipolista
                IF (@hashCalKey > 0)
                BEGIN
                    SELECT CAST(-1 AS INT) --Phone number need a calkey to delete it
                END
                ELSE
                BEGIN
                    INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
                    VALUES (@telephone, 5, @idtipolista)

                    DELETE
                    FROM cclistanegra
                    WHERE Hashtel = @hashPhone AND (HashKey IS NULL OR HashKey = 0) AND idtipolista = @idtipolista;
                    SELECT CAST(1 AS INT)
                END
            END
            ELSE
            BEGIN
                INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
                VALUES (@telephone, 5, @idtipolista)

                DELETE
                FROM cclistanegra
                WHERE Hashtel = @hashPhone AND (HashKey IS NULL OR HashKey = 0) AND idtipolista = @idtipolista
            END
            END
            ELSE
            BEGIN
            --Check if phone with calKey exist
            IF NOT EXISTS (SELECT cln.HashKey FROM dbo.ccListaNegra AS cln WHERE cln.HashKey = @hashCalKey AND cln.idtipolista = @idtipolista)
            BEGIN
                SELECT CAST(-4 AS INT) --Phone Number with calKey not exist
            END
            ELSE
            BEGIN
                INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
                VALUES (@telephone, 5, @idtipolista)

                DELETE
                FROM cclistanegra
                WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
                IF(@isKolob = 1)
                BEGIN
                    SELECT CAST(1 AS INT)
                END
            END
            END
    END
    ELSE
    BEGIN
        SELECT CAST(-3 AS INT) --Phone Number not exist
    END
    RETURN (0)
END

IF @command = 3 --Reemplaza
BEGIN
    INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
    SELECT telefono, 4, @idtipolista
    FROM cclistanegra
    WHERE idtipolista = @idtipolista

    DELETE
    FROM cclistanegra
    WHERE idtipolista = @idtipolista

    RETURN (0)
END

IF @command = 5 --Delete by idtipolista
BEGIN
    UPDATE ccTiposListaNegra
    SET STATUS = 0
    WHERE idtipolista = @idtipolista

    DELETE ccAgendaListaNegra
    WHERE idagenda IN (
        SELECT idagenda
        FROM ccAgenda_TipolistaNegra
        WHERE idtipolista = @idtipolista
        )

    DELETE ccAgenda_TipolistaNegra
    WHERE idtipolista = @idtipolista

    DELETE cccalifblacklist
    WHERE idtipolista = @idtipolista

    DELETE Camplistanegra
    WHERE idtipolista = @idtipolista    

    INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
    
    SELECT  telefono,5,Hashtel
    FROM ccListaNegra
    WHERE idtipolista = @idtipolista

    
    DELETE
    FROM cclistanegra
    WHERE idtipolista = @idtipolista


    RETURN (0)
END

SET NOCOUNT OFF'
		EXEC(@sql)
------------------------------------ TT9016-AdminKolob-Eroor en listas negras ----------------------------


------------------------------------ CW-8394 Permiso para hacer llamadas Manual en el agente ----------------------------

SET @process = 'CW-8394 Permiso para hacer llamadas Manual en el agente, se elimina el sp ccsp_RIAAgentGetDialMask, si existe '
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIAAgentGetDialMask'')
			BEGIN
				DROP PROCEDURE ccsp_RIAAgentGetDialMask
			END'
		EXEC(@sql)

SET @process = 'CW-8394 Permiso para hacer llamadas Manual en el agente, se modifico para que tome el plan 2, donde los números son de 10 digitos para México'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
@user_id integer,
@tel varchar(15)
AS
declare @mask integer, @idioma integer, @value integer, @lada integer
declare @country as tinyint

set @value = 0
select @mask = isnull(dialmask,7) from ccusers where user_id=@user_id
select @country = valor from ccsettings where setting_id = 104

if @mask=0 begin
    select @value Response
    return
end

-- Restricciones por pais 1:Mexico 2:Argentina 3:Colombia 4:USA 5:Chile 6:Venezuela 7:uk 8:Arabia Saudita, 9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador
if @country = 1
    begin

    DECLARE @specialDialPlan TINYINT, @phoneType TINYINT
    SELECT @specialDialPlan = valor, @phoneType = 0
    FROM ccsettings WITH (NOLOCK)
    WHERE setting_id = 195

    if @specialDialPlan = 2 select @phoneType=dbo.fnGetTipoLlamada(@tel)

    --Restringe celulares
    if (@mask & 1)>0
        begin
        if ((left(ltrim(rtrim(@tel)),3) = ''044'' Or left(ltrim(rtrim(@tel)),3) = ''045'') and len(ltrim(rtrim(@tel))) = 13) or (@specialDialPlan = 2 and (@phoneType=3 or @phoneType=4))
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if ((left(ltrim(rtrim(@tel)),2) = ''01'') and len(ltrim(rtrim(@tel))) = 12) or (@specialDialPlan = 2 and @phoneType=2)
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            if (Len(@lada) + Len(ltrim(rtrim(@tel))) = 10 and @specialDialPlan = 0) or (@specialDialPlan = 2 and @phoneType=1)
                begin
                set @value = 6
                end
            end
        end
    end

-- Argentina
if @country = 2
    begin
    --Restringe celulares
    if ((@mask & 1) > 0)
        begin
        if (left(@tel,2)=''15'') or (len(@tel)>=13 and substring(@tel,1,1)=''0'' and
            (substring(@tel,4,2)=''15'' or substring(@tel,5,2)=''15'' or substring(@tel,3,2)=''15''))
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if ((left(ltrim(rtrim(@tel)),2) =''0'') and len(ltrim(rtrim(@tel))) = 11)
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask&4)>0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
                begin
                set @value=6
                end
            end
        end
    end

if @country = 3 --Colombia
    begin
    --Restringe Celulares
    if ((@mask & 1) > 0)
        begin
        if len(@tel) > 8
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if len(@tel) = 8 or left(@tel,1) = ''0''
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
                begin
                set @value = 6
                end
            end
        end
    end

if @country = 4 --USA
    begin
    --Restringe larga distancia usa
    if ((@mask & 2) > 0)
        begin
        if len(ltrim(rtrim(@tel))) >= 11  and (left(ltrim(rtrim(@tel)),1) = ''1'')
            begin
            set @value = 5
            end
        end

    --Restringe locales usa
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            --if Len(ltrim(rtrim(@tel))) = 7
            if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
                begin
                set @value = 6
            end
            end
        end
    end

--Chile
if @country = 5
    begin

        --Restringe Celulares
    if ((@mask & 1) > 0)
        begin
        if len(@tel) >= 10 and left(@tel,2) = ''09''
            begin
            set @value = 4
            end
        end

        --Restringe Locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            if Len(@tel) in (6,7)
                begin
                set @value = 6
                end
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if len(@tel) >= 8 and len(@tel) < 10
                begin
                set @value = 5
                end
            end
        end
    end

--Venezuela
if @country = 6
begin
        --Restringe Celulares
    if ((@mask & 1) > 0)
        begin
        if len(@tel) >= 10 and left(@tel,2) = ''04''
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if len(@tel) >= 10 and left(@tel,1) = ''0''
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
                begin
                set @value = 6
                end
            end
        end

end

--United Kingdom
if @country = 7
begin
        --Restringe Celulares
    if ((@mask & 1) > 0)
        begin
        if (len(@tel) >= 9) and left(@tel,2) = ''07''
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if len(@tel) >= 9 and left(@tel,1) = ''0''
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            if len(@tel) >= 9 and left(@tel,1) <> ''0''
                begin
                set @value = 6
                end
            end
        end

end

--arabia saudita
if @country = 8
begin

    --Restringe celulares
    if (@mask & 1)>0
        begin
        if (left(ltrim(rtrim(@tel)),2) = ''05'' and len(ltrim(rtrim(@tel))) = 10 )
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if ( left(ltrim(rtrim(@tel)),2) <> ''05'' and len(ltrim(rtrim(@tel))) in (11, 9))
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
                begin
                set @value = 6
                end
            end
        end
end

--Australia
if @country = 9
begin

    --Restringe celulares
    if (@mask & 1)>0
        begin
        if (left(ltrim(rtrim(@tel)),2) = ''04'' and len(ltrim(rtrim(@tel))) = 10)
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if ( left(ltrim(rtrim(@tel)),2) <> ''04'' and len(ltrim(rtrim(@tel))) = 10)
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            if ((Len(ltrim(rtrim(@tel))) = 8) or
                (''0'' + left(ltrim(rtrim(@tel)),1) = @lada and Len(ltrim(rtrim(@tel))) = 9) or
                (left(ltrim(rtrim(@tel)),2) = @lada and Len(ltrim(rtrim(@tel))) = 10))
                begin
                set @value = 6
                end
            end
        end
end

--Brasil
if @country = 10
    begin
        declare @lon int
        --Restringe celulares
        if (@mask & 1)>0
        begin
            set @tel=ltrim(rtrim(@tel))
            set @lon=len(@tel)
            if
                (@lon in(7,8) and left(@tel,1) in (''6'',''7'',''8'',''9'') )
                or (@lon=9 and left(@tel,1) = ''9'' )
                or (@lon=10 and substring(@tel,3,1) in (''6'',''7'',''8'',''9'') )
                or (@lon=11 and substring(@tel,3,1) = ''9'')
                --or (@lon=12 and substring(@tel,5,1) in (''6'',''7'',''8'',''9'') )
                --or (@lon=13 and substring(@tel,5,1) = ''9'' )
                --or (@lon=13 and substring(@tel,5,1) = ''9'' )
                begin
                    set @value = 4
                end
        end

        --Restringe larga distancia
        if(@value=0)
        begin
            if ((@mask & 2) > 0)
            begin
                select @lada=valor from ccSettings WHERE setting_id=17
                set @tel=ltrim(rtrim(@tel))
                set @lon=len(@tel)
                if  @lon>=10 and left(@tel,2) <> @lada
                begin
                    set @value = 5
                end
            end
        end
        --Restringe locales
        if(@value=0)
        begin
            if ((@mask & 4) > 0)
            begin
                select @lada=valor from ccSettings WHERE setting_id=17
                set @tel=ltrim(rtrim(@tel))
                set @lon=len(@tel)
                if @lon in (7,8,9) or (@lon in (10,11) and left(@tel,2)= @lada)
                begin
                    set @value = 6
                end
            end
        end

        --Restringe por cobrar
        if(@value=0)
        begin
            declare @llamadasPorCobrar varchar(4);
            select @llamadasPorCobrar= valor from ccSettings where setting_id=126
            set @tel=ltrim(rtrim(@tel))
            set @lon=len(@tel)
            if @lon >= 12 and  left(@tel,2) = ''90'' and @llamadasPorCobrar=''0''
            begin
                set @value = 10 -- pone para llamadas por cobrar
            end
        end

    end -- Termina Brasil


--Guatemala
if @country = 11
    begin
        --Restringe celulares
        if (@mask & 1)>0
        begin
            set @tel=ltrim(rtrim(@tel))
            if charindex(substring(@tel,1,1),''3,4,5'') > 0
                set @value = 4
        end

        --Restringe locales
        if(@value=0)
        begin
            if ((@mask & 4) > 0)
            begin
                set @tel=ltrim(rtrim(@tel))
                if charindex(substring(@tel,1,1),''2,6,7'') > 0
                    set @value = 6
            end
        end

    end -- Termina Guatemala

--Costa Rica
if @country = 12
    begin
        --Restringe celulares
        if (@mask & 1)>0
        begin
            set @tel=ltrim(rtrim(@tel))
            if charindex(substring(@tel,1,1),''5,6,7,8'') > 0
                set @value = 4
        end

        --Restringe locales
        if(@value=0)
        begin
            if ((@mask & 4) > 0)
            begin
                set @tel=ltrim(rtrim(@tel))
                if charindex(substring(@tel,1,1),''2,3,4'') > 0
                    set @value = 6
            end
        end

    end -- Termina Costa Rica

--Salvador
if @country = 13
    begin
        --Restringe celulares
        if (@mask & 1)>0
        begin
            set @tel=ltrim(rtrim(@tel))
            if charindex(substring(@tel,1,1),''6,7'') > 0
                set @value = 4
        end

        --Restringe locales
        if(@value=0)
        begin
            if ((@mask & 4) > 0)
            begin
                set @tel=ltrim(rtrim(@tel))
                if charindex(substring(@tel,1,1),''2'') > 0
                    set @value = 6
            end
        end

    end -- Termina Salvador

--Spain
if @country = 14
    begin
        --Restringe celulares
        if (@mask & 1)>0
        begin
            set @tel=ltrim(rtrim(@tel))
            if charindex(substring(@tel,1,1),''6,7'') > 0
                set @value = 4
        end

        --Restringe locales
        if(@value=0)
        begin
            if ((@mask & 4) > 0)
            begin
                set @tel=ltrim(rtrim(@tel))
                if charindex(substring(@tel,1,1),''8,9'') > 0
                    set @value = 6
            end
        end

    end -- Termina Spain

select @value Response'
		EXEC(@sql)
------------------------------------ CW-8394 Permiso para hacer llamadas Manual en el agente ----------------------------
---------------------------------------- BEGIN fix/125.20231211.011 -------------------------------------------------
    SET @process = 'Alter SP ccsp_GetInfoDash Se cambia el decimal(5,2) a decimal(10,2)'
    SET @sql = 'ALTER procedure [dbo].[ccsp_GetInfoDash]
@CampId as smallint
as
set nocount on              
declare @upd_date as datetime
declare @cps  as int 
declare @today datetime

select @cps = [valor] from ccSettings  where setting_id=238
select
    @upd_date = date_update
from ccCampsInfo with(nolock) where cam_id = @CampId

set @today=convert(date,getdate(),121)

if @upd_date is null begin
    insert into ccCampsInfo(cam_id,contact_reg,dial_retries,date_update,calls_per_second)
    values(@CampId,0,0,getdate(),@cps)

    set @upd_date=@today
end

if (datediff(ss, @upd_date, getdate()) > 300) begin
    if not exists(select cam_id from ccocallsout with(nolock)
    where cam_id=@CampId and statuscall_id=13 and cal_inicio>= @today)
    begin
        update ccCampsInfo
            set contact_reg=0, dial_retries=0, date_update = getdate(), calls_per_second=@cps
        where cam_id = @CampId      
    end else
    begin

        declare @vop1 decimal(12,2)
        declare @vop2 decimal(12,2)
        declare @vop3 decimal(12,2)
        declare @vop4 decimal(12,2)

        select @vop1 = count(distinct(callout_id)) from ccocallsout with(nolock)
        where cam_id = @CampId and statuscall_id=13 and cal_inicio>= @today
        group by cam_id
        select @vop2 = count(distinct(callout_id)), @vop4 = count(distinct telefono) from ccoLogDials with(nolock) 
        where cam_id = @CampId and fecha >= @today
        group by cam_id
        select @vop3 = count(distinct telefono) from ccoLogDials with(nolock) 
        where cam_id = @CampId and fecha >= @today
        group by cam_id having count(1) > 1
        
        if @vop2 is null 
            set @vop2=0

        if @vop4 is null 
            set @vop4=0     
        
        update ccCampsInfo set
             contact_reg=isnull( case when @vop2=0 then 0 else (@vop1/@vop2)*100 end,0)
            , dial_retries=isnull(case when @vop4=0 then 0 else(@vop3/@vop4)*100 end,0)
            , date_update=getdate()
    end
end

select
cam_id, contact_reg, dial_retries, date_update, calls_per_second
from ccCampsInfo
where cam_id = @CampId


set nocount off'
    EXEC(@sql);

    SET @process = 'Alter Sp ccsp_RIA_ABCAgents se agrega delete from ccUsers_Roles where User_id=@UserId'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
@option smallint,
@UserId int,
@Login varchar(40)='''',
@Nombres varchar(25)=null,
@ApellidoPaterno varchar(25)='''',
@ApellidoMaterno varchar(25)='''',
@Password varchar(33)='''',
@Sexo bit=null,
@canChangeStatus bit=null,
@AreaId int=null,
@UserType tinyint=1,
@IDWG int=0,
@DeleteUsers int=1,
@inOut int=null,
@IDCampEsp int=null,
@multipleUsers varchar(1000)=null
as
set nocount on

if @option=0--All Users
  begin
  select User_id,Login,ISnull(AREas.AreaName,'''')as AreaName

from ccusers as users with(nolock)
    left join ccRIACat_Areas as areas with(nolock)
    on users.IDArea=areas.IDArea
  return(0)
  end

if @option=1--selected User
  begin
  select User_id,Login,Nombres,isnull(apellidoPaterno,''''),
    isnull(ApellidoMaterno,''''),Sexo,canChangeStatus,isnull(IDArea,0),tipouser_id
  from ccusers where User_id=@UserId
  order by IDArea,Nombres,ApellidoPaterno,User_id
  return(0)
  end

if @option=2--insert
  begin
  if exists(select Login from ccUsers where Login=@Login)
    begin
    select -1--,''Login en Uso''
    return(0)
    end

  if exists(select Login from ccUsers_Consulta where Login = @Login)
  begin
    select -4 -- ''Login habia estado en Uso''
    return(0)
  end

  if exists(select Nombres from ccUsers where Nombres=@Nombres
  and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
    begin
    select -2--,''Nombre en Uso''
    return(0)
    end

IF( select isnull(max(user_id),0) from ccusers) > 32700
BEGIN
  set @UserId = null
  SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
  LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
  INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
  FROM ccusers) AS w ON w.recID = d.recID

  if @UserId is null
  begin
    select -2--insert Error
    return(0)
  end

  set identity_insert ccusers on
  insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
    Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
  select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
    1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
  set identity_insert ccusers off

  delete ccMenuUser where id_User = @UserId
  delete ccRIAUserRole where user_id = @UserId

  exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

END
ELSE
BEGIN
  insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
    Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
  select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
    1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

  if @@rowcount=1
    select @UserId=scope_identity()
  else
    begin
    select -2--insert Error
    return(0)
    end
END
  insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
  insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
  insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
  --Menu para roles RepotsRia
  exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

  select @UserId,'' Usuario '' + @Login + '' Dado de Alta''
  return(0)
  end

if @option=3--Update
  begin
  if @Login='''' and @Password <> ''''
    begin
    Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId
    return(0)
    end

  Update ccUsers
  set Login= case when @Login <> '''' then @Login else Login end,
  Nombres=@Nombres,
  ApellidoPaterno=@ApellidoPaterno,ApellidoMaterno=@ApellidoMaterno,
  Password=case when @Password <> '''' then @Password else Password end,
  Sexo=@Sexo,canChangeStatus=@canChangeStatus
  where User_id=@UserId
  return(0)
  end

if @option=4--Delete
  begin
  delete from ccSkills where user_id =@UserId
  delete from ccMenu_ViewsUser where user_id =@UserId
  delete from dbo.ccRIAWorkGroupUsers where user_id =@UserId
  delete from ccRIAAgentsPermissions where AgentId=@UserId
  delete from ccUsers_Roles where User_id=@UserId
  delete from ccUsers where user_id=@UserId
  return(0)
  end

declare @Type tinyint, @users int,@sql varchar(8000), @NinOut nvarchar(10)

if @option=5--insert Agente-Supervisor in WorkGroup
  begin
  select @Type=TipoUser_id from ccUsers where User_id=@UserId

  if @Type not in(1,2,6)
    return(0)

  if @Type=1 and((select count(User_id)from ccRIAWorkGroupUsers where User_id=@UserId)>=(select valor from ccSettings where setting_id=63))
    begin
    select 3
    return(0)
    end

  if exists(select @UserId from ccRIAWorkGroupUsers where User_id=@UserId and IDWG=@IDWG)
    begin
    select 1
    return(0)
    end

  insert into ccRIAWorkGroupUsers(IDWG,User_id)values(@IDWG,@UserId)

  if @Type=1
    begin

    if @IDWG is null or @IDWG = 0
      begin
      select 28
      return(0)
      end
    insert into cccampsAgente(user_id,cam_id,prioridad,skill,IDWG)

    select @UserId,idCampEsp,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
    from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
      and idCampEsp not in(select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

    insert into ccinboundAgentes(User_id,Inbound_id,cli_id,prioridad,skill,IDWG)
    select @UserId,idCampEsp,0,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
    from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
      and idCampEsp not in(select inbound_id from ccinboundAgentes where user_id=@UserId and IDWG=@IDWG)

    return(0)
    end

--else @Type=2 or @Type=6--Supervisor
  insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
  select @UserId,idCampEsp,0,@IDWG
  from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
    and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

  insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
  select @UserId,idCampEsp,1,@IDWG
  from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
    and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
  return(0)
  end

if @option=6--Delete Agent-Supervisor from WorkGroup
  begin
  if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)=0
    select @UserId = @multipleUsers

        else if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)>0
          select @UserId = cast(substring(@multipleUsers, 1,
          CHARINDEX('','', @multipleUsers)-1) as int)

    select @Type=case when @UserType <> 0 then @UserType else TipoUser_id end,
    @multipleUsers=isnull(@multipleUsers,cast(@Userid as varchar(10)))
  from ccUsers where User_id=@UserId

  Declare @sqlDelete nvarchar(4000)
  if @Type in(1,2,6)--1:Agente / 2,6:Supervisor
    begin
    set @sqlDelete=N''Delete from '' + case @Type when 1 then ''cccampsagente where '' else ''ccSupervisorCam where tipo=0 and '' end
    + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
    + '' Delete from '' + case @Type when 1 then ''ccinboundagentes where '' else ''ccSupervisorCam where tipo=1 and '' end
    + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
    exec(@sqlDelete)
    end

  if isnull(@UserId, 0) = 0 or isnull(@multipleUsers, ''0'') = ''0''
    begin
    select -9 -- Se ingreso mal el id del usuario
    --delete ccinboundagentes where idwg=@IDWG
    --delete cccampsagente where idwg=@IDWG
    --delete ccSupervisorCam where idwg=@IDWG
    end

  if @DeleteUsers=1
    Delete ccRIAWorkGroupUsers where IDWG=@IDWG and User_id=@UserId

  return(0)
  end

if @option=7--Delete Agent from WorkGroup
  begin
  select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end
  set @sql=''delete '' + case @NinOut when ''1'' then ''ccCampsAgente'' else ''ccInboundAgentes'' end +
    '' where user_id in('' + isnull(@multipleUsers, ''0'') +'') and '' + case @NinOut when ''1'' then ''cam_id'' else ''inbound_id'' end +
    ''='' + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' + cast(@IDWG as varchar(10)) +
    '' delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
  exec(@sql)
  --update preview permission
  set @sql = ''update ccusers set 
      AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
      DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
      select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
      where progDial=3 and user_id in ('' + isnull(@multipleUsers, ''0'') +'') group by user_id)c on us.User_id=c.user_id
      where us.user_id in ('' + isnull(@multipleUsers, ''0'') +'')''
  exec(@sql)
return(0)
  end

if @option=8--Delete Supervisor from WorkGroup
  begin
  select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end

        set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and user_id in('' + isnull(@multipleUsers, ''0'') + '') and cam_id=''
          + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' +cast(@IDWG as varchar(10)) + ''
          delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
        exec(@sql)

  set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and cam_id='' + cast(@IDCampEsp as varchar(10)) + ''and '' +
    ''user_id in ('' + isnull(@multipleUsers, ''0'') + '') and IDWG='' + cast(@IDWG as varchar(10))
  exec(@sql)
  return(0)
  end

if @option=9
  begin

  update ccusers set NotReadyRestricted=@canChangeStatus where [User_id]=@UserId

select Login from ccUsers where [User_id]=@UserId
  return(0)
  end
set nocount off'
    EXEC(@sql);


    SET @process = 'Alter SP ccsp_RIAUpdateCamConfigExtend se valida @recordCalls es nulo y el el valor tabla es nullo se pone 1'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
    @cam_id smallint,
    @zipCodeSchedule BIT = NULL,
    @userId SMALLINT = NULL,
    @idArea SMALLINT = NULL, 
    @isCreating SMALLINT = NULL,
    @simultaneousRecs SMALLINT = NULL,
    @module INT = -1,
    @recordCalls tinyint = 1,
    @editableContactData BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @country INT = (select valor from ccSettings where setting_id = 104); 
    DECLARE @excludeIdentifier VARCHAR(255) = CASE WHEN @country = 4 THEN ''COMMON_INTERNATIONAL_RECORD_CALLS'' ELSE ''COMMON_USA_RECORD_CALLS'' END;
    if exists(select * from ccCampsExtend where cam_id=@cam_id) begin

        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCampsExtend'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

        Create table #ccCampsExtendTable 
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )

        DECLARE @Camptype INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @cam_id);
        DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
                                                                    CASE 
                                                                        WHEN @Camptype = 6  THEN 44
                                                                        WHEN @Camptype = 5  THEN 46
                                                                        WHEN @Camptype = 4  THEN 48
                                                                        WHEN @Camptype = 7  THEN 50
                                                                        ELSE 42 END
                                                                ELSE 
                                                                    CASE 
                                                                        WHEN @Camptype = 6  THEN 55
                                                                        WHEN @Camptype = 5  THEN 56
                                                                        WHEN @Camptype = 4  THEN 57
                                                                        WHEN @Camptype = 7  THEN 58
                                                                        ELSE 54 END
                                                                END;

        
        UPDATE ccCampsExtend SET
            zipCodeSchedule = isnull(@zipCodeSchedule,zipCodeSchedule),
            simultaneousRecs = isnull(@simultaneousRecs,simultaneousRecs),
            RecordCalls = case when @recordCalls is null and RecordCalls is null then 1 else  ISNULL(@recordCalls, RecordCalls) end,
            EditableContactData = isnull(@editableContactData,EditableContactData)
        Where cam_id = @cam_id  

        select @recordCalls =RecordCalls from ccCampsExtend Where cam_id = @cam_id  


        IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsExtendTable'';

        IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            @operation, 
            @module, 
            CCCE.identifierInfo,
            CASE WHEN CCCE.identifierInfo IS NOT NULL AND CCCE.identifierInfo <> '''' THEN
                CASE 
                    WHEN CCCE.identifierInfo IN (''SETTINGS_CHANGED_AREAS_ZIP'', ''COMMON_INTERNATIONAL_RECORD_CALLS'', ''EDIT_CALL_DATASET'') THEN
                        CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    WHEN CCCE.identifierInfo IN (''COMMON_USA_RECORD_CALLS'') THEN
                        CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_USA_RECORD_CALLS_MODE_ALL''
                            WHEN CCCE.dataInfo = 2 THEN ''COMMON_USA_RECORD_CALLS_MODE_AUTH''
                            WHEN CCCE.dataInfo = 4 THEN ''COMMON_USA_RECORD_CALLS_MODE_NOAUTH''
                            ELSE ''COMMON_DISABLED'' END
                    ELSE CCCE.dataInfo END
            ELSE '''' END,
            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
        FROM #ccCampsExtendTable AS CCCE where CCCE.identifierInfo != @excludeIdentifier;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
        IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable

    end
    else begin
        INSERT INTO ccCampsExtend(cam_id,zipCodeSchedule,SimultaneousRecs, RecordCalls, EditableContactData) values (@cam_id,@zipCodeSchedule,@simultaneousRecs, @recordCalls, @editableContactData)
    end

    update ccCamps set call_record = @recordCalls where cam_id = @cam_id

    set nocount off
END'
    EXEC(@sql);

    SET @process = ''
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_UnassignedElementsInAreas]   
@Action INT,   
@AreaId INT = 0,
@Ids VARCHAR(max) = ''''
AS    
BEGIN
    DECLARE @IdsTemp TABLE (Id INT);
    DECLARE @RestTable TABLE (Id INT);


    DECLARE @Id VARCHAR(max);
    DECLARE @Result VARCHAR(max);
    INSERT INTO @IdsTemp(Id)
    SELECT cast(VALUE as int) FROM dbo.fn_RIASplitDelimited(@Ids,'','')

    set @Result=''''
    -- Return results 
    IF @Action IN (0, 3, 6) -- User names 
    BEGIN 
        SELECT @Result=@Result+ 
        case when login is not null then login+'','' else '''' end  --AS ElementNames
        FROM @IdsTemp ids
        INNER JOIN ccUsers users ON users.User_id = ids.Id  
    END

   else IF @Action IN (1, 4, 7) -- Campaign names
    BEGIN 
        
        SELECT  @Result=@Result+ 
        case when cam_descripcion is not null then cam_descripcion+'','' else '''' end  --AS ElementNames       
        FROM @IdsTemp ids
        INNER JOIN ccCamps campaign ON campaign.cam_id = ids.Id
    END

   else IF @Action IN (2, 5, 8) -- Acd names
    BEGIN 
        SELECT @Result=@Result+ 
        case when descripcion is not null then descripcion+'','' else '''' end  --AS ElementNames       
        FROM @IdsTemp ids
        INNER JOIN ccInbound acd ON acd.Inbound_id = ids.Id
    END
    -------------------------------------------------------
    IF @Action = 0 -- Assign Users to Unassigned area 
    BEGIN
        UPDATE ccUsers
        SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END,
            status = 1
        FROM @IdsTemp ids
        WHERE ccUsers.User_id = ids.Id
        AND NOT EXISTS (SELECT 1 FROM ccUsers WHERE IDArea = @AreaId AND User_id = ids.Id)
    END

   else IF @Action = 1 -- Assign Users to Campaigns area 
    BEGIN
        UPDATE ccCamps
        SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END
        FROM @IdsTemp ids
        WHERE ccCamps.cam_id = ids.Id
        AND NOT EXISTS (SELECT 1 FROM ccCamps WHERE IDArea = @AreaId AND cam_id = ids.Id)
    END

   else IF @Action = 2 -- Assign Users to Acds area 
    BEGIN       
        UPDATE ccInbound
        SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END,
            status = 1
        FROM @IdsTemp ids
        WHERE ccInbound.Inbound_id = ids.Id
        AND NOT EXISTS (SELECT 1 FROM ccInbound WHERE IDArea = @AreaId AND Inbound_Id = ids.Id)
    END

    IF @Action in (3, 4, 5, 6, 7, 8)
    BEGIN       

        SET @Id = ''0''
        WHILE EXISTS( SELECT Id FROM @IdsTemp ) 
        BEGIN
            SELECT TOP 1 @Id =Id FROM @IdsTemp 

            IF @Action = 3 -- Unassign Users from area 
            BEGIN
                EXEC ccsp_RIAManageAreas @option = 2, @DeleteUserId = @Id
            END

            IF @Action = 4 -- Unassign Campaigns from area 
            BEGIN
                DECLARE @TempResult INT;
                EXEC @TempResult = ccsp_RIAManageAreas @option=4, @DeleteCamId = @Id;
                IF @TempResult = -4 
                BEGIN
                    SET @Result = ''-1'';
                END
            END 

            IF @Action = 5 -- Unassign Acds from area 
            BEGIN
                insert into @RestTable
                EXEC ccsp_RIAManageAreas @option = 6, @DeleteACDGroupId = @Id
            END

            IF @Action = 6 -- Delete Users from area 
            BEGIN
                EXEC ccsp_RIA_ABCAgents @option=4, @UserId = @Id, @Login = '''', @Nombres='''',@ApellidoPaterno='''',@ApellidoMaterno='''',@Password='''',@Sexo=0,@canChangeStatus=0,@AreaId=0,@UserType=0,@IDWG=0
            END

            IF @Action = 7 -- Delete Campaigns from area 
            BEGIN
                EXEC ccsp_RIA_ABCCamps @option = 4, @UserId = 0, @Descripcion = '''', @Cam_id = @Id, @Activa = 0, @IDArea = 0, @frame = 0
                delete ccCamps with(rowlock) where cam_id = @Id
                delete ccCampsExtend with(rowlock) where cam_id = @Id
                delete from ccoDialerCamp where cam_id = @Id --Elimina los puertos
            END

            IF @Action = 8 -- Delete Acds from area 
            BEGIN
                EXEC ccsp_RIA_ABCACDGroups @option = 4, @UserId = 0, @Descripcion = '''', @Inbound_id = @Id, @IDArea = 0, @frame = 0
                delete ccInbound with(rowlock) where Inbound_id = @Id
                delete ccInboundExtend with(rowlock) where Inbound_Id = @Id
            END

            DELETE FROM @IdsTemp WHERE Id = @Id
        END
    END

    if @Result<>'''' begin
        set @Result= substring(@Result,1,len(@Result)-1)
    end

    SELECT @Result
END'
    EXEC(@sql);

    SET @process = 'Alter Sp ccsp_GalateaAdminRotativeANI se agrega cast smallint id_RAniList'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminRotativeANI]
    @type SMALLINT,
    @idArea SMALLINT = NULL,
    @descriptionList VARCHAR(50) = NULL,
    @id_RAniList SMALLINT = NULL,
    @PageIndex      INT = 0,
    @PageSize       INT = 0,
    @UserId         SMALLINT = 0

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

END'
    EXEC(@sql);

    SET @process = 'Alter SP ccspAgent_GetLastCalls Correcion para no tomar el tiempo Hold'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
AS
SET NOCOUNT ON;
DECLARE @lastCallAgt TABLE(id           INT NOT NULL
                        , tipo         VARCHAR(10) NOT NULL
                        , Hora         DATETIME NOT NULL --VARCHAR(19) NOT NULL, 
                        , Telefono     VARCHAR(55) NOT NULL
                        , EspCamp      VARCHAR(55) NOT NULL
                        , Calificacion VARCHAR(150)
                        , Duracion     VARCHAR(10) NOT NULL
                        , CallBack     DATETIME
                        , cal_key      VARCHAR(40)
                        , IDCampEsp    SMALLINT NOT NULL
                        , prefijo      VARCHAR(255) NULL
                        , GraphicID    INT
                        , CamManualMode INT
                        , SelectRotativeANI INT
                        , PRIMARY KEY(id,tipo)
);

DECLARE @pais TINYINT;
DECLARE @maxHours SMALLINT;
DECLARE @topRows INT;
DECLARE @setting VARCHAR(6);
DECLARE @hidePhone BIT;
DECLARE @dateStart DATETIME;

SET @hidePhone = 1;

SELECT @setting = valor FROM ccSettings WHERE setting_id = 255;

SET @maxHours = CAST(SUBSTRING(@setting, 1, (SELECT PATINDEX(''%|%'', @setting)) - 1) AS SMALLINT);
SET @topRows = CAST(SUBSTRING(@setting, (SELECT PATINDEX(''%|%'', @setting)) + 1, LEN(@setting)) AS INT);

IF @maxHours = 0
BEGIN
    SELECT Id
        , tipo
        , (CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) AS Hora
        , Telefono
        , EspCamp
        , Calificacion
        , CallBack
        , Duracion
        , '''' AS CallBack
        , cal_key
        , IDCampEsp
        , prefijo
        , GraphicID
        , SelectRotativeANI
        , @hidePhone AS HidePhone FROM @lastCallAgt;

    RETURN 0;
END;

SELECT @pais = valor FROM ccSettings WHERE setting_id = 104;

SELECT @hidePhone = CASE WHEN valor = ''0''
                    THEN 0 ELSE 1
                    END FROM ccSettings WHERE setting_id = 223;

IF @topRows = 0
BEGIN
    SET @topRows = 10000;
END;

SET @dateStart = DATEADD(hh, -@maxHours, GETDATE());

WITH timeTransfer
    AS (SELECT cal_id
            , tipo
            , SUM(tAntesXfer) AS tAntesXfer
            , SUM(tDespuesXfer) AS tDespuesXfer FROM ccLogTransfers
        WHERE fechaFin > @dateStart
        GROUP BY cal_id
                , tipo)

    INSERT INTO @lastCallAgt
            ---Insert OUT
            SELECT TOP (@topRows) c.cal_id AS id
                                , ''OUT'' AS Tipo
                                , cal_inicio
                                , cal_telefono AS Telefono
                                , cam_descripcion AS EspCamp
                                , ISNULL(cal.Description, '''') AS Calificacion
                                , CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - case when ccCamps.recordHold=1 then 0 else cal_tMoh end 
                                + CASE WHEN stopRecording = 0
                                                                                        THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                        END, 0), 114) AS Duracion
                                , cal_fcallback AS CallBack
                                , cal_key
                                , c.cam_id AS IDCampEsp
                                , ISNULL(ccCamps.prefijo, '''') Prefijo
                                , graph.graphic_id GraphicID
                                , cam_ModoManual as CamManualMode 
                                , ISNULL(selectRotativeANI, 0) as SelectRotativeANI FROM ccoCallsOut c
                                                                INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
                                                                LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
                                                                LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
                                                                LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                            AND t.tipo = 2
            WHERE user_id = @user_id
                AND cal_inicio > @dateStart
            UNION
            --- IN
            SELECT TOP (@topRows) c.cal_id AS id
                                , ''IN'' AS Tipo
                                , cal_inicio
                                , cal_ani AS Telefono
                                , descripcion AS EspCamp
                                , ISNULL(cal.Description, '''') AS Calificacion
                                , CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - case when ccInbound.recordHold=1 then 0 else cal_tMoh end  
                                + CASE WHEN stopRecording = 0
                                                                                                THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                                END, 0), 108) Duracion
                                , NULL AS CallBack
                                , cal_key
                                , c.inbound_id AS IDCampEsp
                                , ISNULL(ccInbound.prefijo, '''') Prefijo
                                , graph.graphic_id GraphicID
                                , '''' as CamManualMode 
                                , 0 as SelectRotativeANI FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
                                                              inner JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
                                                                INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
                                                                LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
                                                                LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                            AND t.tipo = 1
            WHERE user_id = @user_id
                AND cal_inicio > @dateStart;

SELECT Id
    , tipo
    , CASE WHEN @pais = 4
    THEN(CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) ELSE(CONVERT(VARCHAR(10), Hora, 103) + '' '' + CONVERT(VARCHAR(8), Hora, 14))
    END AS Hora
    , Telefono
    , EspCamp
    , Calificacion
    , ISNULL(CONVERT(VARCHAR(16), CallBack, 121), '''') AS CallBack
    , Duracion
    , CallBack
    , cal_key
    , IDCampEsp
    , prefijo
    , GraphicID
    , @hidePhone AS HidePhone 
    , CamManualMode 
    , SelectRotativeANI FROM @lastCallAgt
ORDER BY hora DESC;
SET NOCOUNT OFF;'
    EXEC(@sql);

    SET @process = 'Alter ccsp_AvrsSyncronization para cambiar la duration cuando se graba el hold'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization] @action SMALLINT, @maxRecordsToTransfer INT = 10, @id INT = 0
AS
SET NOCOUNT ON

IF @action = 1
BEGIN
    DECLARE @countrId INT

    SET @countrId = 1

    SELECT @countrId = valor
    FROM ccSettings
    WHERE setting_id = 104;

    WITH callsIn
    AS (
        SELECT TOP (@maxRecordsToTransfer) 
        calls.cal_id, user_id, calls.Inbound_id, calls.calif_id 
        , cast(cal_extension AS INT) AS cal_extension, cal_inicio, cal_ANI AS phone
        , isnull(cal_tDialog - case when ccInbound.recordHold=1 then 0 else cal_tMoh end , 0) 
        + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration
        , cal_key, 0 AS cal_manual, cal_puerto
        , calls.dni_id, fvalida, cal_whohung
        , isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id
        , CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh
        , dateadd(ss, isnull(cal_tDialog, 0), cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, ccInbound.prefijo
        
        , convert(bit, case when isnull(calls.file_moved,1)=2 then 0 else 1 end)  AS isCallRecord
        , isnull(dni.dni_numero, '''') AS DNIS, dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG
        
        FROM ccCallsIn  AS  calls   with(nolock)
        INNER JOIN ccInbound ON ccInbound.Inbound_id = calls.Inbound_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id    AND avrs.tipo = 0
        LEFT JOIN ccDNIS dni ON dni.dni_id = calls.dni_id
        left join ccInboundExtend inbExt on inbExt.Inbound_id=calls.Inbound_id
        LEFT JOIN (
            SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers
            WHERE tipo = 1
            GROUP BY cal_id, tipo
            ) trans ON calls.cal_id = trans.cal_id
        WHERE calls.User_id > 0
        ), callsOut
    AS (
        SELECT TOP (@maxRecordsToTransfer) 
        calls.cal_id AS CallId, user_id AS UserId, calls.cam_id AS camAcdId
        , cast(calls.calif_id AS SMALLINT) AS califId, cast(cal_extension AS INT) AS extension, cal_inicio, cal_telefono
        , isnull(cal_tDialog - case when camps.recordHold=1 then 0 else cal_tMoh end , 0) + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration
        , cal_key, cal_manual, cal_puerto, 0 AS dni_id, fvalida, cal_whohung
        , isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id
        , CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh
        , dateadd(ss, isnull(cal_tDialog, 0), cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, camps.prefijo
        
        , convert(bit, case when isnull(calls.file_moved,1)=2 then 0 else 1 end)  AS isCallRecord
        , '''' AS DNIS, dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG
        FROM ccoCallsOut AS calls with(nolock)
        INNER JOIN ccCamps camps ON camps.cam_id = calls.cam_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 1
        LEFT JOIN (
            SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers
            WHERE tipo = 2
            GROUP BY cal_id, tipo
            ) trans ON calls.cal_id = trans.cal_id
        WHERE calls.User_id > 0
        )

        select * from callsIn
        union 
        select * from callsOut
        
END
ELSE IF @action = 2
BEGIN
    DELETE
    FROM ccAVRSTransfer
    WHERE id = @id
END
'
    EXEC(@sql);

    SET @process = ''
    SET @sql = ''
    EXEC(@sql);

---------------------------------------- BEGIN fix/125.20231211.011 -------------------------------------------------

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
