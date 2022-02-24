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
SET @version = 123 --**********actualizar a 123 sin fix
SET @versionfix = 28
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

	set @process = 'CW-6363 ccposicion.Ip'
    set @sql = 'ALTER TABLE ccposicion ALTER COLUMN [IP] varchar(50);'
    EXEC(@sql)

    set @process = 'CW-6363 insert setting_id 232'
    set @sql = 'if not exists(select * from ccSettings where setting_id=232) begin
	insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values(232,''1'',''Asiganar todos los puertos de marcacion al crear campañas'',1,''GRL'',''Valor (1) Inserta todos los puertos por campaña ccoDialerCamp, (0) no llena la tabla''
	,''Value (1) Inserts all ports per ccoDialerCamp campaign, (0) does not fill the table'',1,''^\d{1,2}$'')
end
'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_AgentGetCalificaciones'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentGetCalificaciones] @inOut  TINYINT
                                                    ,

/**********
0 in, 1 out
**********/

                                                    @cam_id INT, 
                                                    @isXml  BIT     = 1
AS
     SET NOCOUNT ON;
     DECLARE @sql NVARCHAR(MAX);
     IF @inOut = 0
         BEGIN
             IF EXISTS
             (
                 SELECT calif.calif_id
                 FROM ccTipoCalif AS calif
                      JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
                      LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id
                                                            AND rel.tipoSubRel = 1
                      LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
                 WHERE cam_id = @cam_id
                       AND tipo = @inOut
             )
                 BEGIN
                     DECLARE @relationCamId INT;
                     SELECT @relationCamId = cam_id
                     FROM ccInbound
                     WHERE Inbound_id = @cam_id;
                     IF @relationCamId IS NULL
                         BEGIN
                             SET @relationCamId = 0
                     END;
                     SET @sql = '';WITH disposition
    AS (SELECT DISTINCT
             1 AS tag,NULL AS parent,calif.calif_id AS "selection!1!id",calif.Description AS "selection!1!string",calif.orden AS "selection!1!califorden",
			 ISNULL(calif.EndConversation,0) AS "selection!1!endConversation",NULL AS "subSelection!2!id",
			 NULL AS "subSelection!2!string",NULL AS "subSelection!2!orden",NULL AS "subSelection!2!endConversation",
			 ISNULL(calif.CanReprogram,0) AS "selection!1!canReprogram",NULL AS "subSelection!2!canReprogram"
        FROM ccTipoCalif AS calif
        INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND camp.cam_id = @cam_id AND camp.tipo = @inOut
        LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 1
        LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
        WHERE calif.CanReprogram = 0 OR calif.CanReprogram = 1 AND @relationCamId > 0
        UNION
        SELECT DISTINCT
             2 AS tag,1 AS parent,calif.calif_id AS "selection!1!id",NULL AS "selection!1!string",calif.orden AS "selection!1!califorden",
			 ISNULL(calif.EndConversation,0) AS "selection!1!endConversation",sb.califsub_id AS "subSelection!2!id",
			 sb.califSubDesc AS "subSelection!2!string",CAST(sb.orden AS INT) AS "subSelection!2!orden",
			 ISNULL(sb.EndConversation,0) AS "subSelection!2!endConversation",NULL AS "selection!1!canReprogram",ISNULL(sb.CanReprogram,0) AS "subSelection!2!canReprogram"
        FROM ccTipoCalif AS calif
        INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND camp.cam_id = @cam_id AND camp.tipo = @inOut
        LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 1
        LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
        WHERE sb.califsub_id IS NOT NULL AND (sb.CanReprogram = 0 OR sb.CanReprogram = 1 AND @relationCamId > 0))
'';
                     IF @isXml = 1
                         BEGIN
                             SET @sql = @sql + ''select * from disposition
               order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type'';
                     END;
                     ELSE
                         BEGIN
                             SET @sql = @sql + ''select 
tag as Tag, isnull(parent,0) as Parent, "selection!1!id" as Id,isnull("selection!1!string",'''''''') as Description,
cast("selection!1!califorden" as int) as Orden, 
"selection!1!endConversation" EndConversation, isnull("subSelection!2!id",0) as SubId,
isnull("subSelection!2!string",'''''''') as SubDescription, 
cast(isnull("subSelection!2!orden",0) as int) as SubOrden,   
--CAST(  ROW_NUMBER() OVER(PARTITION BY parent ORDER BY "subSelection!2!orden" ASC) as INT) AS SubOrden,
isnull("subSelection!2!endConversation",0) as SubEndConversation, 
isnull("selection!1!canReprogram",0) as CanReprogram,isnull("subSelection!2!canReprogram",0) as SubCanReprogram
FROM disposition'';
                     END;
                              PRINT @sql

                     EXEC sp_executesql 
                          @sql, 
                          N''@cam_id int, @InOut tinyint,@relationCamId int'', 
                          @cam_id, 
                          @inOut, 
                          @relationCamId;
             END;
             RETURN 0;
     END;
     ELSE
         BEGIN
             IF @inOut = 1
                 BEGIN
                     IF EXISTS
                     (
                         SELECT calif.calif_id
                         FROM ccTipoCalifOUT AS calif
                              JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
                              LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id
                                                                    AND rel.tipoSubRel = 0
                              LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
                         WHERE cam_id = @cam_id
                               AND tipo = @inOut
                     )
                         BEGIN
                             SET @sql = '';WITH disposition
AS (SELECT DISTINCT
       1 AS tag,NULL AS parent,calif.calif_id AS "selection!1!id",calif.Description AS "selection!1!string",calif.keepDial AS "selection!1!keepOnDial",
	   calif.orden AS "selection!1!califorden",ISNULL(calif.finishPreview,0)
       AS "selection!1!finishPreview",NULL AS "subSelection!2!id",NULL AS "subSelection!2!string",NULL AS "subSelection!2!keepOnDial",
	   NULL AS "subSelection!2!orden",ISNULL(calif.CanReprogram,0) AS "selection!1!canReprogram",NULL AS "subSelection!2!canReprogram"
    FROM ccTipoCalifOUT AS calif
    INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
    LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 0
    LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
    WHERE cam_id = @cam_id AND tipo = @inOut
    UNION
    SELECT DISTINCT
       2 AS tag,1 AS parent,calif.calif_id AS "selection!1!id",NULL AS "selection!1!string",NULL AS "selection!1!keepOnDial",calif.orden AS "selection!1!califorden",ISNULL(calif.finishPreview,0) AS
       "selection!1!finishPreview",sb.califsub_id AS "subSelection!2!id",sb.califSubDesc AS "subSelection!2!string", 
	   sb.keepDial AS "subSelection!2!keepOnDial",CAST(sb.orden AS INT) AS "subSelection!2!orden",NULL AS"selection!1!canReprogram",
	   ISNULL(sb.CanReprogram,0) AS "subSelection!2!canReprogram"
    FROM ccTipoCalifOUT AS calif
    INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
    LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 0
    LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
    WHERE cam_id = @cam_id AND tipo = @inOut AND sb.califsub_id IS NOT NULL)
'';
                             IF @isXml = 1
                                 BEGIN
                                     SET @sql = @sql + ''select * from disposition
               order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type'';
                             END;
                             ELSE
                                 BEGIN
                                     SET @sql = @sql + ''SELECT tag AS Tag,ISNULL(parent,0) AS Parent,"selection!1!id" AS Id,ISNULL("selection!1!string",'''''''') AS Description,
    ISNULL("selection!1!keepOnDial",'''''''') AS KeepOnDial,
    --"selection!1!califorden" AS Orden,
    CAST(  ROW_NUMBER() OVER(ORDER BY "selection!1!califorden" ASC) as int) AS Orden,
    "selection!1!finishPreview" AS
    FinishPreview,ISNULL("subSelection!2!id",0) AS SubId,ISNULL("subSelection!2!string",'''''''') AS SubDescription
    ,ISNULL("subSelection!2!keepOnDial",0) AS SubKeepOnDial,
    ISNULL("subSelection!2!orden",0) AS SubOrden,    
    ISNULL("selection!1!canReprogram",0) AS CanReprogram,ISNULL("subSelection!2!canReprogram",0) AS SubCanReprogram
    FROM disposition'';
                             END;
                             -- PRINT @sql

                             EXEC sp_executesql 
                                  @sql, 
                                  N''@cam_id int, @InOut int'', 
                                  @cam_id, 
                                  @inOut;
                     END;
                     RETURN 0;
             END;
             ELSE
                 BEGIN
                     IF @inOut = 10
                         BEGIN
                             SELECT DISTINCT 
                                    S.califSub_id, S.califSubDesc, orden
                             FROM cctipoSubCalifRel AS R
                                  JOIN cctipoCalifSub AS S ON R.califSub_id = S.califSub_id
                             WHERE R.tipoSubRel = 1
                                   AND S.califSub_Status = 1
                                   AND R.calif_id = @cam_id
                                    ORDER BY S.orden, S.califSubDesc;
                             RETURN 0;
                     END;
                     ELSE
                         BEGIN
                             IF @inOut = 11
                                 BEGIN
                                     SELECT DISTINCT 
                                            S.califSub_id, S.califSubDesc, orden
                                     FROM cctipoSubCalifRel AS R
                                          JOIN cctipoCalifSubOut AS S ON R.califSub_id = S.califSub_id
                                     WHERE R.tipoSubRel = 0
                                           AND S.califSubOut_Status = 1
                                           AND R.calif_id = @cam_id
                                            ORDER BY S.orden, S.califSubDesc;
                                     RETURN 0;
                             END;
                     END;
             END;
     END;
     SET NOCOUNT OFF;'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_GalateaAdminCampaigns'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS      SMALLINT, 
                                                   @CampType AS    SMALLINT = 0, 
                                                   @WorkgroupId AS INT      = 0, 
                                                   @Id AS          INT      = 0, 
                                                   @AdminId AS     SMALLINT = 0, 
                                                   @PinUpdate AS   SMALLINT = 0, 
                                                   @LoadId AS      INT      = 0, 
                                                   @Type AS        SMALLINT = 0
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
                                RAISERROR(''ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado'', 18, 1);
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
                                RAISERROR(''ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado'', 18, 1);
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
                                       CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, CAST(graph.graphic_id AS INT) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area
                                FROM ccCamps camps
                                     LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                                     LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
                                WHERE camps.cam_id = @Id
                                       ORDER BY camps.cam_descripcion ASC;
                        END;
                        ELSE
                            BEGIN
                                RAISERROR(''ERROR. No existe campa?as de salida con el id especificado'', 18, 1);
                        END;
                END;
                IF @CampType = 0 -- Campaigns In (ACD)
                    BEGIN
                        IF @Id IS NOT NULL
                            BEGIN
                                SELECT DISTINCT 
                                       CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, CAST(graph.graphic_id AS INT) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
                                FROM ccInbound inb
                                     LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                                     LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                                WHERE inb.Inbound_id = @Id
                                       ORDER BY inb.descripcion ASC;
                        END;
                        ELSE
                            BEGIN
                                RAISERROR(''ERROR. No existe campa?as de entrada con el id especificado'', 18, 1);
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
                        RAISERROR(''ERROR. No existe la campa?as de entrada con el id especificado'', 18, 1);
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
                        RAISERROR(''ERROR. La campa?as o administrador no existen'', 18, 1);
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
                        RAISERROR(''ERROR. La campa?as con el id seleccionado no existe'', 18, 1);
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
DECLARE @Wg TABLE
(id INT, 
 PRIMARY KEY(id)
);
DECLARE @tmpAgent TABLE
(id INT, 
 PRIMARY KEY(id)
);
DECLARE @tmpCamAgent TABLE
(camId  INT, 
 userId INT, 
 PRIMARY KEY(camId, userId)
);
DECLARE @AgentStatus TABLE
(CampId       SMALLINT, 
 userId       INT, 
 CurrentState INT, 
 isCampDialog BIT
);
DECLARE @CurrentStatus TABLE
(userId       INT, 
 CurrentState INT, 
 IdCampEsp    INT, 
 camType      INT
);
DECLARE @campDataTotal TABLE
(camId int,
  CampName VARCHAR(500),
 Total    INT,
 Area varchar(100)
 primary key (camId)
);
INSERT INTO @Wg
       SELECT DISTINCT 
              IDWG
       FROM ccRIAWorkGroupUsers WG, 
            ccUsers_Roles R
       WHERE WG.User_id = @AdminId
             OR (R.User_id = @AdminId
                 AND R.Rol_id = 7);
INSERT INTO @tmpAgent
       SELECT DISTINCT 
              A.User_id
       FROM ccRIAWorkGroupUsers A
            INNER JOIN @Wg B ON A.IDWG = B.id
            INNER JOIN ccUsers C ON A.User_id = C.User_id
                                    AND C.TipoUser_id = 1
              ORDER BY A.User_id;
INSERT INTO @tmpCamAgent
       SELECT DISTINCT 
              campPerWg.IdCampEsp, wgUser.User_id
       FROM ccRIACampEspWG campPerWg
            INNER JOIN @Wg wg ON wg.Id = campPerWg.IDWG
            INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
            INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
                                    AND C.TipoUser_id = 1
       WHERE campPerWg.Tipo = @CampType;



WITH lastState
     AS (SELECT A.user_id, MAX(A.fecha) AS fecha
         FROM ccLogAgentesDia A
              INNER JOIN @tmpAgent B ON A.User_id = B.id
         WHERE fecha >= @date
         GROUP BY user_id)
     INSERT INTO @CurrentStatus
            SELECT B.User_id,
                     CASE
                         WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus
                     END AS currentStatus, B.IdCampEsp, B.Tipo
            FROM lastState A
                 INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
                                                 AND A.fecha = B.fecha;


	
	insert into @AgentStatus
	select A.camId,A.userId,B.CurrentState,
	(case when B.CurrentState in( 4, 5, 6, 9) and B.IdCampEsp=A.camId and B.camType=1 then @CampType else null end)  as isCampDialog 
	from @tmpCamAgent A
	inner join @CurrentStatus B on A.userId=B.userId
	where (@Id=0 or A.camId=@Id)

IF @CampType = 1
    BEGIN
	;with  campDataTotal as(
		select camId,count(*) total from @tmpCamAgent A	group by camId
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
	End
else begin    
	;with  campDataTotal as(
		select camId,count(*) total from @tmpCamAgent A	group by camId
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
End	

	
	;with   stateCamp as(

		SELECT A.CampId,
		count(case when A.CurrentState =3 then 1 else null end) as ready,
		count(case when  A.CurrentState NOT IN(3, 4, 5, 6, 9) then 1 else null end) as notReady,
		COUNT(isCampDialog) AS dialog	
		FROM @AgentStatus A
		GROUP BY A.CampId
	)


	select 
	A.camId,
	A.campName,A.Total
	,isnull(B.ready,0) as Ready
	,case when B.notReady is null then  A.Total else  A.Total-B.ready-B.dialog end as NotReady
	
	,isnull(B.dialog,0) as Dialog
	,A.Area
	
	from @campDataTotal A
	left join stateCamp B on A.camId=B.CampId
	order by A.campName
	


                RETURN 0;
        END;
        IF @Option = 11  -- Get Campaigns Ids List Per Workgroup and Campaign Type
            BEGIN                
                IF Not EXISTS
                (
                    SELECT *
                    FROM ccUsers_Roles
                    WHERE User_id = @AdminId
                          AND Rol_id = 7
                )
                    BEGIN
                        WITH wgId
                             AS (SELECT IDWG
                                 FROM ccRIAWorkGroupUsers
                                 WHERE user_id = @AdminId)
                             SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS Id
                             FROM ccRIACampEspWG A
                                  INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                     AND A.Tipo = @CampType;
                END;
                ELSE
                    BEGIN
                        SELECT DISTINCT 
                               CAST(IdCampEsp AS INT) AS Id
                        FROM ccRIACampEspWG A
                             INNER JOIN ccCamps B ON A.IdCampEsp = B.cam_id
                                                     AND A.Tipo = @CampType;
                END;
                RETURN 0;
        END;
        IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
            BEGIN
                IF @CampType = 1 -- Campaigns Out
                    BEGIN
                        SELECT DISTINCT 
                               CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, CAST(graph.graphic_id AS INT) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area
                        FROM ccCamps camps
                             INNER JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                             INNER JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
                               --WHERE camps.cam_id = @Id
                               ORDER BY camps.cam_descripcion ASC;
                END;
                ELSE
                    BEGIN
                        SELECT DISTINCT 
                               CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, CAST(graph.graphic_id AS INT) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
                        FROM ccInbound inb
                             INNER JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                             INNER JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                               ORDER BY inb.descripcion ASC;
                END;
                RETURN 0;
        END;
    END;'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_GalateaAdminGetAgentCounters'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS      INT, 
                                                          @sup_id AS    INT          = 0, 
                                                          @agent_id AS  INT          = 0, 
                                                          @WG AS        INT          = 0, 
                                                          @AgentsIds AS VARCHAR(MAX) = '''', 
                                                          @campId AS    INT          = 0, 
                                                          @CampType AS  SMALLINT     = 1
AS
     SET NOCOUNT ON;
     DECLARE @dateStart DATETIME;
     IF @type = 1
         BEGIN
             WITH TableUserAgent(userId)
                  AS (SELECT DISTINCT 
                             wgAgt.User_id AS Id --,usr.login 
                      FROM ccriaworkgroupusers wgAdmin
                           INNER JOIN ccriaworkgroupusers wgAgt ON wgAdmin.IDWG = wgAgt.IDWG
                           INNER JOIN ccUsers usr ON usr.User_id = wgAgt.User_id
                                                     AND usr.TipoUser_id = 1
                      WHERE wgAdmin.User_id = @sup_id)
                  SELECT CAST(a.User_id AS INT) Id, a.login AS Username, a.Nombres + '' '' + a.ApellidoPaterno + '' '' + a.ApellidoMaterno AS Name
                  FROM ccusers a(NOLOCK)--, ccGenViewRelsSupsAgent b
                       INNER JOIN TableUserAgent b ON a.User_id = b.userId
                         ORDER BY a.Login ASC;
             RETURN 0;
     END;
     IF @type = 2
         BEGIN
             SELECT CAST(u.User_id AS INT) Id, Login Username, Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno Name,
                                                                                                                       CASE WHEN p.publicIp IS NULL
                                                                                                                                 OR p.publicIp = '''' THEN ''000.000.000.000''
                                                                                                                       ELSE p.publicIp
                                                                                                                       END IP
             FROM ccUsers u
                  LEFT JOIN ccPosicion p ON p.user_id = @agent_id
             WHERE u.User_id = @agent_id;
             RETURN 0;
     END;
     IF @type = 3 --Agents by supervisor and WG
         BEGIN
             DECLARE @table2 TABLE(userId INT PRIMARY KEY NOT NULL);
             INSERT INTO @table2
                    SELECT DISTINCT 
                           wg.User_id
                    FROM ccRIAWorkGroupUsers wg
                         LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                    WHERE us.TipoUser_id = 1
                          AND wg.IDWG IN
                    (
                        SELECT IDWG
                        FROM ccRIAWorkGroupUsers
                        WHERE User_id = @sup_id
                              AND IDWG <> @WG
                    );
             SELECT CAST(B.User_id AS INT) AS Id
             FROM @table2 A
                  RIGHT JOIN
             (
                 SELECT DISTINCT 
                        wg.User_id
                 FROM ccRIAWorkGroupUsers wg
                      LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                 WHERE wg.IDWG = @WG
                       AND us.TipoUser_id = 1
             ) B ON A.userId = B.User_id
             WHERE A.userId IS NULL;
             RETURN 0;
     END;
     IF @type = 4 --Agents IDs by WG
         BEGIN
             SELECT CAST(wg.User_id AS INT) Id
             FROM ccRIAWorkGroupUsers wg
                  JOIN CCUsers u ON u.user_id = wg.user_id
                                    AND u.TipoUser_id = 1
             WHERE IDWG = @WG;
             RETURN 0;
     END;
     IF @type = 5 --Agents IDs by Campaign
         BEGIN
             SELECT DISTINCT
                    (CAST(U.User_id AS INT)) Id
             FROM ccRIACampEspWG camp
                  JOIN ccRIAWorkGroupUsers wg ON camp.IDWG = wg.IDWG
                  JOIN ccUsers U ON U.User_id = WG.User_id
                                    AND U.TipoUser_id = 1
             WHERE IdCampEsp = @campId
                   AND TIPO = @CampType;
             RETURN 0;
     END;
     IF @type = 6 -- Get Agent current state
         BEGIN
             WITH UserMaxFecha(User_id, fecha)
                  AS (SELECT User_id, MAX(fecha) AS fecha
                      FROM ccLogAgentesDia
                      WHERE fecha >= CONVERT(DATE, GETDATE())
                      GROUP BY User_id)
                  SELECT CASE WHEN CurrentState.currentStatus IS NULL
                                   OR CurrentState.currentStatus < 0 THEN 0
                         ELSE CAST(CurrentState.currentStatus AS INT)
                         END CurrentState
                  FROM ccUsers u
                       LEFT JOIN
                  (
                      SELECT A.User_id, B.currentStatus
                      FROM UserMaxFecha A
                           INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
                                                           AND A.fecha = B.fecha
                  ) CurrentState ON u.User_id = CurrentState.User_id
                  WHERE u.TipoUser_id = 1
                        AND u.User_id = @agent_id;
             RETURN 0;
     END;
     IF @type = 7 -- Get superuser id''s except root
         BEGIN
             DECLARE @superuserId AS INT;
             SET @superuserId =
             (
                 SELECT Rol_id
                 FROM ccRoles
                 WHERE Level = 7
             ); -- obtenemos el id del rol superusuario

             SELECT CAST(cr.User_id AS INT) User_id
             FROM ccUsers_Roles cr
             WHERE Rol_id = @superuserId
                   --AND cr.User_id NOT IN(1);
             RETURN 0;
     END;
     IF @type = 8 -- Get all Agent''s ID, Login and Full Names related to a workgroup
         BEGIN
             SET @dateStart = CONVERT(DATE, GETDATE());
             WITH lastState
                  AS (SELECT user_id, MAX(fecha) dateStart
                      FROM ccLogAgentesDia WITH(NOLOCK)
                      WHERE fecha > @dateStart
                      GROUP BY user_id),
                  wgAgt
                  AS (SELECT DISTINCT 
                             A.User_id, us.Login Username, --se agrega distinct porque el agente si puede estar en dos grupos de trabajo diferentes
                             us.Nombres + '' '' + us.ApellidoPaterno + '' '' + us.ApellidoMaterno Name
                      FROM ccRIAWorkGroupUsers A
                           INNER JOIN ccusers us ON A.User_id = us.User_id
                      WHERE IDWG = @WG
                            AND us.TipoUser_id = 1)
                  SELECT CONVERT(INT, us.User_id) AS Id, us.Username AS Username, us.Name, LastStateId = CASE WHEN B.currentStatus IS NULL
                                                                                                                   OR B.currentStatus < 0 THEN 0
                                                                                                         ELSE B.currentStatus
                                                                                                         END
                  FROM wgAgt us
                       LEFT JOIN lastState A ON A.User_id = us.User_id
                       LEFT JOIN ccLogAgentesDia B ON A.User_id = B.User_id
                                                      AND A.dateStart = B.fecha;
             RETURN 0;
     END;
     ELSE
         IF @type = 9 -- GET AGENT IP
             BEGIN
                 SELECT publicIp
                 FROM ccPosicion
                 WHERE user_id = @agent_id;
                 RETURN 0;
         END;
         ELSE
             IF @type = 10 -- GET ONLINE AGENTS IP
                 BEGIN
                     SELECT CAST(user_id AS INT) AgentId, publicIp Ip
                     FROM ccPosicion
                     WHERE user_id <> 0;
                     RETURN 0;
             END;
     IF @type = 11
         BEGIN
             WITH UserMaxFecha(User_id, fecha)
                  AS (SELECT User_id, MAX(fecha) AS fecha
                      FROM ccLogAgentesDia
                      WHERE fecha >= CONVERT(DATE, GETDATE())
                      GROUP BY User_id)
                  SELECT CAST(u.User_id AS INT) AS UserId,
                                                   CASE WHEN CurrentState.currentStatus IS NULL
                                                             OR CurrentState.currentStatus < 0 THEN 0
                                                   ELSE CAST(CurrentState.currentStatus AS INT)
                                                   END CurrentState
                  FROM ccUsers u
                       LEFT JOIN
                  (
                      SELECT A.User_id, B.currentStatus
                      FROM UserMaxFecha A
                           INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
                                                           AND A.fecha = B.fecha
                  ) CurrentState ON u.User_id = CurrentState.User_id
                  WHERE u.TipoUser_id = 1
                        AND u.User_id IN
                  (
                      SELECT value
                      FROM dbo.fn_RIASplitDelimited(@AgentsIds, '','')
                  );
             RETURN 0;
     END;
     IF @type = 12
         BEGIN
             SET @dateStart = CONVERT(DATE, GETDATE());
             WITH lastState
                  AS (SELECT user_id, MAX(fecha) dateStart
                      FROM ccLogAgentesDia WITH(NOLOCK)
                      WHERE fecha > @dateStart
                      GROUP BY user_id),
                  currentState
                  AS (SELECT A.User_id,
                               CASE WHEN B.currentStatus IS NULL
                                         OR B.currentStatus < 0 THEN 0
                               ELSE B.currentStatus
                               END AS LastStateId
                      FROM lastState A
                           INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
                                                           AND A.dateStart = B.fecha)
                  SELECT CONVERT(INT, us.User_id) AS Id, us.Login Username, --se agrega distinct porque el agente si puede estar en dos grupos de trabajo diferentes
                  us.Nombres + '' '' + us.ApellidoPaterno + '' '' + us.ApellidoMaterno AS Name, ISNULL(B.LastStateId, 0) LastStateId
				  ,isnull(c.publicIp,''0.0.0.0'') as [Ip]
                  FROM ccusers us
                       LEFT JOIN currentState B ON us.User_id = B.User_id
					   left join ccposicion C on C.user_id=us.user_id
                  WHERE us.TipoUser_id = 1;
             RETURN 0;
     END;
     SET NOCOUNT ON;'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_GalateaAdminLogin'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminLogin] @Login       VARCHAR(40) = '''', 
                                               @Password    VARCHAR(40) = '''', 
                                               @PasswordLwC VARCHAR(40) = NULL, 
                                               @IPAddress   VARCHAR(20) = '''', 
                                               @adminId     INT         = 0
AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @LoginOK BIT= 0, @PswdOK BIT= 0, @User_id SMALLINT, @Nombre VARCHAR(100), @ADMServer VARCHAR(300), @AreaId SMALLINT, @ViewAvrs INT, @changeRecDisposition INT, @PasswordExpired INT= 0, @UsernameMatch BIT= 1, @UserBlocked BIT= 0, @LastPasswordChange DATETIME, @Ext VARCHAR(80), @ViewAgents BIT= 0, @Theme SMALLINT= 0;
        CREATE TABLE #temp
        (LoginOK              INT, 
         PswdOK               INT, 
         User_id              SMALLINT, 
         Nombre               VARCHAR(100), 
         ADMServer            VARCHAR(300), 
         AreaId               SMALLINT, 
         ViewAvrs             INT, 
         changeRecDisposition INT, 
         LastPasswordchange   INT
        );
        INSERT INTO #temp
        EXEC ccsp_RIAADMChecaLogin 
             @Login, 
             @Password, 
             @PasswordLwC, 
             @adminId,
			 1;
        SELECT @LoginOK = LoginOK, @PswdOK = PswdOK, @Nombre = Nombre, @ADMServer = ADMServer, @AreaId = AreaId, @ViewAvrs = ViewAvrs, @changeRecDisposition = changeRecDisposition, @PasswordExpired = LastPasswordchange
        FROM #temp;
        IF @LoginOK = 1
            BEGIN
                SELECT @User_id = User_id, @ViewAgents = viewAgents, @Theme = theme
                FROM ccUsers
                WHERE Login = @Login;
                DECLARE @LastLoginAttempt DATETIME, @LoginAttempts INT, @MaxAttemptsAllow INT, @TimeBloqued INT, @TimeFromLastAttempt INT;
                SELECT @LastLoginAttempt = LastLoginAttempt, @LoginAttempts = LoginAttempts, @LastPasswordChange = LastPasswordChange
                FROM ccUsers
                WHERE User_id = @User_id;
                SELECT @MaxAttemptsAllow = valor
                FROM ccSettings
                WHERE setting_id = 198;
                SELECT @TimeBloqued = valor
                FROM ccSettings
                WHERE setting_id = 197;
                SELECT @TimeFromLastAttempt = DATEDIFF(MINUTE, @LastLoginAttempt, GETDATE());
                IF @LoginAttempts > @MaxAttemptsAllow
                    BEGIN
                        SET @LoginAttempts = 0;
                        UPDATE ccUsers
                          SET 
                              LoginAttempts = 0, 
                              LastLoginAttempt = GETDATE()
                        WHERE User_id = @User_id;
                END;
                IF(@LoginAttempts >= @MaxAttemptsAllow
                   AND @TimeFromLastAttempt < @TimeBloqued)
                    BEGIN
                        SET @UserBlocked = 1;
                END;

                --Checks Username match case sensitive    
                IF CAST(@Login AS VARBINARY(200)) <>
                (
                    SELECT CAST(LOGIN AS VARBINARY(200))
                    FROM ccUsers
                    WHERE User_id = @User_id
                )
                    BEGIN
                        SET @UsernameMatch = 0;
                END;

                --Increments attemps if error
                IF @UserBlocked = 0
                   AND (@UsernameMatch = 0
                        OR @PswdOK = 0)
                    BEGIN
                        UPDATE ccUsers
                          SET 
                              LoginAttempts = @LoginAttempts + 1, 
                              LastLoginAttempt = GETDATE(), 
                              onLine = 0
                        WHERE User_id = @User_id;
                END;

                --Sets to default to try another attempt
                DECLARE @ExpirationTime INT;
                SELECT @ExpirationTime = valor
                FROM ccSettings
                WHERE setting_id = 29;
                SELECT @PasswordExpired = (CASE
                                               WHEN DATEDIFF(DAY, LastPasswordChange, GETDATE()) > @ExpirationTime
                                                    AND @ExpirationTime > 0 THEN 1 ELSE 0
                                           END)
                FROM ccUsers;
                IF @UserBlocked = 0
                   AND @UsernameMatch = 1
                   AND @PswdOK = 1
                   AND @PasswordExpired = 0
                    BEGIN
                        UPDATE ccUsers
                          SET 
                              LoginAttempts = 0, 
                              LastLoginAttempt = GETDATE(), 
                              onLine = 1
                        WHERE User_id = @User_id;
                END;
                SELECT @Ext = dbo.fn_Ext_X_ip(@IPAddress);
                DECLARE @WorkGroup VARCHAR(MAX);
                SELECT @WorkGroup = COALESCE(@WorkGroup + ''|'' + CAST(IDWG AS VARCHAR(MAX)), CAST(IDWG AS VARCHAR(MAX)))
                FROM ccRIAWorkGroupUsers
                WHERE User_id = @User_id;
                DECLARE @Roles VARCHAR(MAX);
                SELECT @Roles = STUFF(
                (
                    SELECT '', '' + CAST(ur.Rol_id AS VARCHAR)
                    FROM ccUsers_Roles ur
                    WHERE User_id = @User_id FOR XML PATH('''')
                ), 1, 2, '''');
        END;
        SELECT @LoginOK UserExists, @UserBlocked UserBlocked, @UsernameMatch UsernameMatch, @PswdOK PasswordMatch, CAST(@PasswordExpired AS BIT) PasswordExpired, @User_id UserID, @Nombre Name, @ADMServer ADMServer, @AreaId AreaId, @ViewAvrs ViewAvrs, @changeRecDisposition ChangeRecDisposition, @Ext Ext, ISNULL(@ViewAgents, 0) ViewAgents, ISNULL(@WorkGroup, 0) WorkGroup, ISNULL(@Theme, 0) Theme, ISNULL(@Roles, 0) Roles;
    END;'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_GalateaAdminPortsManagement'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminPortsManagement]
@action SMALLINT,
@dialer_id INT = 0,
@cam_id SMALLINT = 0,
@list_dialier_id varchar(max) =''''
AS
SET NOCOUNT ON;
DECLARE @transtate BIT
IF @@TRANCOUNT = 0
BEGIN
	SET @transtate = 1
BEGIN TRANSACTION transtate
END
BEGIN TRY
	IF @action = 1 --return all ports
	BEGIN
		SELECT Dialers.dialer_id AS DialerId, Dialers.Descripcion AS PortDescription, Provedor.Descrip AS ProviderDescription, Dialers.Puerto
		FROM [CCenterRIA].[dbo].[ccoDialers] AS Dialers INNER JOIN [CCenterRIA].[dbo].[cstoProvedor] AS Provedor 
		ON Dialers.provedor_id = Provedor.provedor_id
	END;
	IF @action = 2 --return ports for camp
	BEGIN
		SELECT dialer_id AS DialerId, cam_id AS CampId FROM [CCenterRIA].[dbo].[ccoDialerCamp] ORDER BY cam_id
	END;
	IF @action = 3 --insert port
	BEGIN
		IF @list_dialier_id = ''''
		BEGIN
			IF NOT EXISTS (SELECT dialer_id, cam_id FROM [CCenterRIA].[dbo].[ccoDialerCamp]
				WHERE dialer_id=@dialer_id AND cam_id=@cam_id)
			BEGIN
				INSERT INTO [CCenterRIA].[dbo].[ccoDialerCamp](dialer_id, cam_id) VALUES (@dialer_id, @cam_id)
			END;
		END
		ELSE
		BEGIN
		   INSERT INTO [CCenterRIA].[dbo].[ccoDialerCamp](dialer_id, cam_id)
			Select dialer_id,@cam_id from ccoDialers where dialer_id not in (SELECT dialer_id FROM [CCenterRIA].[dbo].[ccoDialerCamp]
				WHERE dialer_id in (select Value FROM fn_RIASplitDelimited(@list_dialier_id, '','') where [value] > 0) AND cam_id=@cam_id) and
				 dialer_id in (select Value FROM fn_RIASplitDelimited(@list_dialier_id, '',''))
		END;
	END;
	IF @action = 4 --delete port
	BEGIN
		IF @list_dialier_id = ''''
			DELETE FROM [CCenterRIA].[dbo].[ccoDialerCamp] WITH(ROWLOCK) WHERE cam_id = @cam_id AND dialer_id = @dialer_id
		ELSE
		BEGIN
			DELETE FROM [CCenterRIA].[dbo].[ccoDialerCamp] WITH(ROWLOCK) WHERE cam_id = @cam_id AND dialer_id in (select Value FROM fn_RIASplitDelimited(@list_dialier_id, '','') where [value] > 0)
		END;
	END;

	IF @action = 5 --return ports for single camp
	BEGIN
		SELECT dialer_id AS DialerId, cam_id AS CampId FROM [CCenterRIA].[dbo].[ccoDialerCamp] WHERE cam_id = @cam_id ORDER BY cam_id
	END;

	IF @transtate = 1 AND XACT_STATE() = 1
	BEGIN
		COMMIT TRANSACTION transtate
	END;
END TRY
BEGIN CATCH
DECLARE @error INT, @message VARCHAR(4000), @xstate INT;
SELECT @error = ERROR_NUMBER(), @message = ERROR_MESSAGE(), @xstate = XACT_STATE();
IF @xstate = -1
	ROLLBACK;
IF @xstate = 1
	ROLLBACK
IF @xstate = 1
	ROLLBACK TRANSACTION ccsp_GalateaAdminPortsManagement;
RAISERROR (''ccsp_GalateaAdminPortsManagement: %d: %s'', 16, 1, @error, @message) ;
END CATCH;'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_GalateaGetOutboundConfiguration'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
@adminID int,
@campID int
AS
BEGIN

	declare @AllCampaigns table 
	(cam_id smallint, cam_Descripcion varchar(40), cam_tNotas smallint, cam_ocupado smallint,cam_noInt_ocupado smallint, cam_inter_ocupado smallint,
	cam_nocontesto smallint, cam_noInt_nocontesto smallint, cam_inter_nocontesto smallint, cam_fax smallint, cam_noInt_fax smallint, cam_inter_fax smallint,
	cam_modomanual smallint, ANI varchar(15), cam_ShowCalifWnd bit, cam_StartTimerOnHangUp bit, editableCallKey bit, cam_tNoContesta smallint, iTipoDial smallint,
	detectAnswerMachine smallint,detectVoiceMail smallint, compliance smallint, cam_inter_graba smallint, cam_noint_graba smallint, progDial smallint, excCallBack smallint, dialOrder smallint,
	dialPrefix varchar(10),dialPrefixMan varchar(10), dialPrefixXfe varchar(10),listenManualCall bit,  stopRecording bit,abandonCallback bit, frame smallint,
	t_autoCB smallint, id_anilist int, tDialonWrapUp smallint, viewMode tinyint, queSize smallint, DNCScrub int, callerIdDesc varchar (15), timeZoneRule int,
	callsBySurvey int, ivrScript int, surveyPctg int,call_record smallint,startStopRecording bit,  leaveRecMessage  bit, manualCallOnChat bit, 
	callBackSurveyAgent bit, callBackSurveyClient bit, isRelationSurvey bit, funcEspDtmf int,  sipHdrFormat varchar(255), cam_inter_cancelled smallint, 
	prefijo varchar(40),enbleprefix bit,exitAssisted bit )
	 
		INSERT INTO @AllCampaigns EXEC ccsp_RIAConfCamp @adminID, @campID

		SELECT dialPrefixMan DialPrefixMan, dialPrefixXfe DialPrefixXfe, listenManualCall  ListenManualCall, stopRecording StopRecording, abandonCallback AbandonCallBack,
		t_autoCB AutoCB,id_anilist IdIstANI,tDialonWrapUp TDialOnWrapup, queSize Quesize, DNCScrub, callerIdDesc CallerIdDesc, timeZoneRule TimeZoneRule,callsBySurvey CallsBySurvey,
		ivrScript IvrScript, surveyPctg SurveyPctg, call_record CallRecord,startStopRecording StartStopRecording, leaveRecMessage LeaveRecMessage,manualCallOnChat ManualCallOnChat,
		callBackSurveyClient CallBackSurveyClient, callBackSurveyAgent CallBackSurveyAgent, funcEspDtmf FuncEspDtmf,sipHdrFormat SipHdrsCfg, dialPrefix DialPrefix,
		prefijo Prefix, dialOrder DialOrder, progDial ProgDial, cam_Descripcion CamDescription, cam_tNotas CamTnotas, cam_ocupado CamBusy, cam_noInt_ocupado CamNoIntBusy,
		cam_inter_ocupado CamInterBusy,cam_nocontesto CamNoAnswer, cam_noInt_nocontesto CamNoIntNoAnswer,cam_inter_nocontesto CamInterNoAnswer, (cam_inter_cancelled/60) CamInterCancelled,
		cam_fax CamFax, cam_noInt_fax CamNoIntFax,cam_inter_fax CamInterFax, cam_modomanual CamModoManual,ANI ,cam_StartTimerOnHangUp CamStartTimerOnHangUp,
		editableCallKey EditableCallKey, cam_tNoContesta CamTNoAnswer, iTipoDial  CamIntensiveDialing, detectAnswerMachine DetectAnswerMachine, detectVoiceMail DetectVoiceMail, 
		compliance Compliance, cam_inter_graba CamInterRecord,cam_noint_graba CamNoIntRecord,excCallBack ExcCallBack, cam_ShowCalifWnd CamShowCalifWnd, frame Frame, exitAssisted ExitAssistedDialMode
		from @AllCampaigns WHERE cam_id = @campID
END'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_GalateaGetTodaySessionTime'
set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetTodaySessionTime]
AS
BEGIN
declare @dateStart date
set @dateStart=CONVERT(date, GETDATE())
	;with t as(
	select A.User_id,A.fecha login,S.fecha logout, DATEDIFF(ss,A.fecha,S.fecha) tlog
	from (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha
	from ccLogLogin a with(nolock) where fecha>=@dateStart
	)A
	left join (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha from ccLogLogin a with(nolock)  
	where  fecha>=@dateStart
	) S
	on A.Fila=S.Fila-1 and A.User_id=S.User_id and A.TipoMov=1 and S.TipoMov=0
	where A.TipoMov=1
	)
	select CAST(user_id AS INT) AgentId,max(login) LastLogin, Isnull(sum(tlog), 0) TLoggedIn from t group by user_id
END'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_GalateaUpdateVoiceConfiguration'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateVoiceConfiguration]
	@inboundId				smallint,
	@frame					smallint	= null,
	@description			varchar(50) = null,
	@mediaType				tinyint		= null,
	@status					smallint	= null,
	@tNotas					int			= null,
	@tMaxWaitCall			smallint	= null,
	@nMaxQue				smallint	= null,
	@tel_maxwait			varchar(15) = null,
	@tel_maxqueue			varchar(15) = null,
	@tel_outservice			varchar(15) = null,
	@tel_noct				varchar(15) = null,
	@showCalifWnd			bit			= null,
	@editableCallKey		bit			= null,
	@queuePosition			bit			= null,
	@tMaxQueueCallBack		smallint	= null,
	@stopRecording			bit			= null,
	@dialPrefixOverflow		varchar(10) = null,
	@callerIdDesc			varchar(15) = null,
	@startStopRecording		bit			= null,
	@callBackSurveyAgent	bit			= null,
	@callBackSurveyClient	bit			= null,
	@editableDtmf			bit			= null,
	@addDataCallBackReminder bit		= null
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @graph_id smallint

	UPDATE ccInbound SET
		descripcion = ISNULL(@description, descripcion),
		chat = ISNULL(@mediaType, chat),
		Status = ISNULL(@status, Status),
		tNotas = ISNULL(@tNotas, tNotas),
		tMaxWaitCall = ISNULL(@tMaxWaitCall, tMaxWaitCall),
		nMaxQue = ISNULL(@nMaxQue, nMaxQue),
		tel_maxwait = ISNULL(@tel_maxwait, tel_maxwait),
		tel_maxqueue = ISNULL(@tel_maxqueue, tel_maxqueue),
		tel_outservice = ISNULL(@tel_outservice, tel_outservice),
		tel_noct = ISNULL(@tel_noct, tel_noct),
		bnocturno = CASE WHEN ISNULL(@tel_noct, 0) = ''0'' OR @tel_noct = '''' THEN ''0'' ELSE ''1'' END,
		editableCallKey = ISNULL(@editableCallKey, editableCallKey),
		queuePosition = ISNULL(@queuePosition, queuePosition),
		tMaxQueueCallBack = ISNULL(@tMaxQueueCallBack, tMaxQueueCallBack),
		stopRecording = ISNULL(@stopRecording, stopRecording),
		dialPrefixOverflow = ISNULL(@dialPrefixOverflow, dialPrefixOverflow),
		callerIdDesc = ISNULL(@callerIdDesc, callerIdDesc),
		startStopRecording = ISNULL(@startStopRecording, startStopRecording),
		callBackSurveyAgent = ISNULL(@callBackSurveyAgent, callBackSurveyAgent),
		callBackSurveyClient = ISNULL(@callBackSurveyClient, callBackSurveyClient),
		editableDtmf = ISNULL(@editableDtmf, editableDtmf),
		addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder)
	WHERE Inbound_id = @inboundId

	IF @frame IS NOT NULL
	BEGIN
		SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
		UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId
	END

	IF @showCalifWnd = 1
    BEGIN
		IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
        BEGIN
			UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd)
            WHERE inbound_id = @inboundId
			SELECT 1 [Result]
			RETURN(0)
        END

        SELECT -1 [Result]
        RETURN(0)
     END
     ELSE
	 BEGIN
		UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;
	 END

	SELECT 1 [Result]
	RETURN(0);

	SET NOCOUNT OFF;
END'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_OUTGetCallsInfo_AllCamps'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTGetCallsInfo_AllCamps]
@Tipo as tinyint= 1,
@cam_id as smallint = 0,
@sup_id as smallint= 0
AS

declare @mToday as smalldatetime
		
select @mToday = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
if @Tipo = 0
begin
	SELECT cam_id, cam_descripcion, 0 AS pContesta, 0 AS pOcupado, 0 AS pNoContesta, 0 AS pFaxModem, 0
AS pNoService, 0 AS Marcaciones, 0 AS Contestan, 0 AS Ocupado, 0 AS NoContesta, 0 AS FaxModem, 0 AS
NoService
FROM ccCamps
       ORDER BY cam_id;
end

else if @Tipo = 1
begin
	select L.cam_id, L.Campana,
	((L.Contestan*100)/ L.Marcaciones) as pContesta,
	((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
	((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
	((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
	((L.NoService*100)/ L.Marcaciones) as pNoService,
	L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
	,L.Otro,L.Cancelado,L.buzon,L.NoDialTone,L.congestion
	,isnull(Assigned,0) As Assigned,isnull(Attended,0) As Attended
	from (
	select cam_id, '''' as Campana,
	count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
	count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
	count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
	count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
	count(case tipoResDial_id when 10 then 1 else null end) as NoService,
	count(*) as Marcaciones
	,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Otro
	,count(case tipoResDial_id when 13 then 1 else null end) as Cancelado
	,count(case tipoResDial_id when 11 then 1 else null end) as buzon
	,count(case tipoResDial_id when 5 then 1 else null end) as NoDialTone
	,count(case tipoResDial_id when 12 then 1 else null end) as congestion

	from ccoLogDials with(nolock)
	Where fecha >  @mToday
	group by cam_id
	) L 
	left join (select 
	cam_id
	,count(case statuscall_id when 6 then 1 else null end) as Abandon
	,count(*) as Contesta
	,count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned]
	,count(case statuscall_id when 13 then 1 else null end) as [Attended]
	from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
	where cal_Inicio > @mToday
	group by cam_id) callsOut on L.cam_id = callsOut.cam_id
		  
	order by Campana

end

else if @Tipo = 2
begin
	select cam_id, L.Campana,
	((L.Contestan*100)/ L.Marcaciones) as pContesta,
	((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
	((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
	((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
	((L.NoService*100)/ L.Marcaciones) as pNoService,
	L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
	from (
	select C.cam_id as cam_id, cam_descripcion as Campana,
	count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
	count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
	count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
	count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
	count(case tipoResDial_id when 10 then 1 else null end) as NoService,
	count(*) as Marcaciones
	from ccoLogDials L with(nolock)
	inner join ccCamps C on L.cam_id=C.cam_id
	Where fecha >  @mToday
	group by C.cam_id, cam_descripcion
	) L order by Campana
end

else if @Tipo = 3 --Busqueda por campa?a
begin
	select L.cam_id,
	L.Calls, L.Answer, L.Busy, L.NoAnswer, L.Fax, L.NoService
	,L.Other,L.Canceled,L.Machine,L.NoTone,L.Congestion, isnull(callsOut.Abandon,0) as Abandon
	from (
	select cam_id,
	count(case tipoResDial_id when 1 then 1 else null end) as Answer,
	count(case tipoResDial_id when 2 then 1 else null end) as Busy,
	count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
	count(case tipoResDial_id when 4 then 1 else null end) as Fax,
	count(case tipoResDial_id when 10 then 1 else null end) as NoService,
	count(*) as Calls
	,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
	,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
	,count(case tipoResDial_id when 11 then 1 else null end) as Machine
	,count(case tipoResDial_id when 5 then 1 else null end) as NoTone
	,count(case tipoResDial_id when 12 then 1 else null end) as Congestion

	from ccoLogDials with(nolock)
	Where cam_id = @cam_id
	and fecha >  @mToday
	group by cam_id
	) L 
	left join (select 
	cam_id,
	count(case statuscall_id when 6 then 1 else null end) as Abandon,
	count(*) as Contesta    
	from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
	where cal_Inicio > @mToday
	group by cam_id) callsOut on L.cam_id = callsOut.cam_id

end

else if @Tipo = 4-- Busqueda por campa?as asociadas a admin
begin
	select L.cam_id,
	L.Calls, L.Answer, L.Busy, L.NoAnswer, L.Fax, L.NoService
	,L.Other,L.Canceled,L.Machine,L.NoTone,L.Congestion, isnull(callsOut.Abandon,0) as Abandon
	,isnull(Assigned,0) As Assigned,isnull(Attended,0) As Attended
	from (
	select logDials.cam_id,
	count(case tipoResDial_id when 1 then 1 else null end) as Answer,
	count(case tipoResDial_id when 2 then 1 else null end) as Busy,
	count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
	count(case tipoResDial_id when 4 then 1 else null end) as Fax, 
	count(case tipoResDial_id when 10 then 1 else null end) as NoService,
	count(*) as Calls
	,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
	,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
	,count(case tipoResDial_id when 11 then 1 else null end) as Machine
	,count(case tipoResDial_id when 5 then 1 else null end) as NoTone
	,count(case tipoResDial_id when 12 then 1 else null end) as Congestion
	from ccoLogDials logDials with(nolock)
	right join (select distinct cam_id from ccSupervisorCam supCam where user_id=@sup_id) B ON logDials.cam_id = B.cam_id
	Where fecha >  @mToday
	group by logDials.cam_id
	) L 
	left join (select 
	cam_id
	,count(case statuscall_id when 6 then 1 else null end) as Abandon
	,count(*) as Contesta
	,count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned]
	,count(case statuscall_id when 13 then 1 else null end) as [Attended]
	from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
	where cal_Inicio > @mToday
	group by cam_id) callsOut on L.cam_id = callsOut.cam_id
	order by L.cam_id
end
else if @Tipo = 5-- lista campañas
begin
;with callResult as(
select logDials.cam_id,
	count(*) as Calls,
	count(case tipoResDial_id when 1 then 1 else null end) as Answer,
	count(case tipoResDial_id when 2 then 1 else null end) as Busy,
	count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer		    
	,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
	,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
	,count(case tipoResDial_id when 11 then 1 else null end) as Machine		    
	from ccoLogDials logDials with(nolock)		  
	Where fecha >  @mToday
	group by logDials.cam_id
),callData as(
select 
	cam_id		    		    
	,count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned]
	,count(case statuscall_id when 13 then 1 else null end) as [Attended]
	from ccoCallsOut with(nolock)
	where cal_Inicio > @mToday
	group by cam_id
)

select  cast(L.cam_id as int) as Id,
	C.cam_descripcion as CampName,
	L.Calls, L.Answer,L.NoAnswer,isnull(Attended,0) As Attended , 
	L.Canceled
	,isnull(Assigned,0) As Assigned
	,c.aggressionFactor as AggressionFactor
	,L.Busy
	,L.Machine
	,isnull(Other,0) as Other
	,area.AreaName as Area
	from callResult as L 
	inner join ccCamps C on L.cam_id=C.cam_id
	inner join ccRIACat_Areas area on area.IDArea=c.IDArea
	left join callData callsOut on L.cam_id = callsOut.cam_id
	
	order by L.cam_id

end
'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_RIA_ABCCamps'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
@option smallint,
@UserId int = null,
@Descripcion varchar(40) = null,
@Cam_id varchar(1000),
@Activa tinyint = null,
@IDArea smallint = null,
@frame tinyint = null, 
@MirrorInbound_Id smallint = null,
@Prefijo varchar(40) = null
as
set nocount on

if @option = 0
	begin
		select cam_id,ISNULL(cam_descripcion,'''''''') as cam_descripcion,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
		from ccCamps as CAMP with(nolock) 
		left join ccRIACat_Areas as AREas with(nolock) on CAMP.IDArea = AREas.IDArea
		return(0)
	end

if @option = 1 -- select Camp
	begin
		select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0) as Area_Id,
		prefijo as Prefijo
		from ccCamps a1 with(nolock) 
		inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
		return(0)
	end

if @option = 4 --Delete
	begin
		if exists (select inbound_id from ccInbound with(nolock) where cam_id = @Cam_id)
		begin
		declare @error varchar(70)
		Select @error=case valor when 0 then ''No es posible eliminar la campaña, esta asociada a una especialidad''
			else ''Campaign can not be deleted, it has an association with an ACD'' end
		from ccsettings with(nolock) where setting_id = 27
		raiserror (@error,18,1)		
		return(0)
		end

		delete ccCampsHorarios with(rowlock) where cam_id = @Cam_id
		insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id) Values(@Cam_id, 5, 0, 0, @UserId)
		Delete ccCalifCamp with(rowlock) where cam_id = @Cam_id and tipo = 1
		Delete ccRIACampsGraph with(rowlock) where cam_id = @Cam_id
		delete ccHistorialListaNegra with(rowlock) where cam_id = @Cam_id
		delete ccRIARegistryLists with(rowlock) where cam_id = @Cam_id	
		return(0)
	end

if @option = 2 --Insert
	begin
	declare @new_cam_id smallint
	declare @isAssingPortbyCam bit


	if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
		begin
		select -1 --, ''Nombre en Uso''
		return(0)  
		end

	-- ODC: la campaña siempre esta activa
	set @Activa = 1
	declare @pref int
	select  @pref = valor from ccSettings where setting_id = 201
	if (@pref = 0)
		set @Prefijo = ''''


	Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd,prefijo)
	select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
	case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end,@Prefijo

	if @@rowcount = 1
	select @new_cam_id = scope_identity()

	else
		begin
		select -2 --, ''Error al crear campaña''
		return(0)
		end

	if isnull(@MirrorInbound_Id, 0)<>0
		begin
		if not exists(select inbound_id from ccInbound with(nolock) where inbound_id=@MirrorInbound_Id)
			begin
			select -3 -- Error al asignar campaña a ACD, el ACD no existe o no pertenece a la misma area
			return(0)
			end

		update ccinbound with(rowlock) set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
		update cccamps with(rowlock) set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
		end
	set @isAssingPortbyCam=1

	select @isAssingPortbyCam=valor from ccSettings where setting_id=232

	if @isAssingPortbyCam=1 begin
		insert into ccoDialerCamp (dialer_id, cam_id) 
		select dialer_id, @new_cam_id from ccoDialers with(nolock) where status = 1
	end

	insert into ccCalifCamp (calif_id, cam_id, tipo) 
	select calif_id, @new_cam_id, 1 from ccTipoCalifOUT with(nolock) where CalifOut_Status = 1

	update ccCamps set keepDial=dbo.fn_keepDial_Camps(@new_cam_id) where cam_id=@new_cam_id

	If not exists (select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		begin
		insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
		end

	insert into ccRIACampsGraph (cam_id, graphic_id)
	select @new_cam_id, graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock)  where frame = @frame and type_id = 1

	--inserta la lista negra por default
	if (select valor from ccsettings with(nolock) where setting_id=152)=''1''
	begin
		declare @tempId as int
		DECLARE @dnclId TABLE 
		(
			id int 
		);
		insert into @dnclId
		exec dbo.ccsp_RIACATBList null, null, 5
		select @tempId=id from @dnclId;
		exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
	end

	select @new_cam_id
	return(0)
	end

if @option = 3 -- Update
	begin
		if not exists(select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		insert into ccRIAGraphics (frame,type_id) values (@frame,1)

		Update ccCamps with(rowlock) set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

		update ccRIACampsGraph with(rowlock)
		set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		where cam_id = @Cam_id

		return(0)
	end

	if @option = 5 --Obtener relaciones de campañas - campañas
	begin
		if not exists (select cam_id from ccCamps with(nolock) where cam_id = @Cam_id) or
		(@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
		not exists (select cam_id from ccCamps with(nolock) where cam_id=@descripcion))
		begin
		select -3 -- Campaña invalida
		return(0)
		end
				
	if @descripcion=0
		set @descripcion = null

	update ccCamps with(rowlock) set surveyCamId = @descripcion where cam_id = @Cam_id
	if @@rowcount=0
		select -4 -- Error al actualizar
					
	else
		begin
		delete cccalifcamp with(rowlock) where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

		end

	return(0)
	end

if @option = 6
	begin
		select cam_id, isnull(surveycamid,0)
		from cccamps with(index(PK_ccCamps),nolock)
		where cam_id = @Cam_id
		return(0)
	end

if @option = 7 -- Checa si la campaña no tiene grabaciones y se puede modificar el prefijo
	begin	
		select count(*) as Grabaciones from ccoCallsOut where cam_id = @Cam_id
		--select 0 as Grabaciones	
	end

if @option = 8 -- Checa si la campaña tiene asignada una campaña tipo encuesta
	begin	
		SELECT CAST(CASE WHEN  isnull(surveycamid,0) != 0 THEN 1 ELSE 0 END AS bit)
		from cccamps with(index(PK_ccCamps),nolock)
		where cam_id = @Cam_id
		return(0)
	end

return(0)
set nocount off'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_RIAADMAutoInicio'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAADMAutoInicio]
    @cam_id smallint,
    @AutoInicio bit = 0,
    @tipoRegistros  tinyint = 0,
    @delaCampana    int = 0,
    @condicion  tinyint = 0,
    @numero int = 0,
    @AutoInicioHora bit = 0,
    @hora   smalldatetime = ''01/01/1900'',
    @type tinyint,
    @tipoRegistros2 tinyint = NULL,
    @condicion2 tinyint = NULL,
    @numero2 int = NULL,
    @camps varchar(max) = NULL
AS

IF @Type = 1
begin
    select AutoInicio, tipoRegistros, delaCampana, condicion, numero, AutoInicioHora, hora, tipoRegistros2, condicion2, numero2
    from ccCampsAutoInicio
    where cam_id = @cam_id
end

IF @Type = 2
Begin
    UPDATE ccCampsAutoInicio SET AutoInicio= @AutoInicio, AutoInicioHora = @AutoInicioHora
    WHERE cam_id=@cam_id

    IF @AutoInicio = 1
    begin
        UPDATE ccCampsAutoInicio SET tipoRegistros = @tipoRegistros, delaCampana = @delaCampana, condicion = @condicion, numero = @numero,  tipoRegistros2 = @tipoRegistros2, condicion2 = @condicion2, numero2 = @numero2
        WHERE cam_id=@cam_id
    end

    IF @AutoInicioHora = 1
    begin
        UPDATE ccCampsAutoInicio SET hora = @hora
        WHERE cam_id=@cam_id
    end
end

IF @Type = 3
Begin
    Insert into ccCampsAutoInicio (cam_id, hora) values(@cam_id, getdate())
End

IF @Type = 4
Begin
    declare @Camps_Ids table (id int primary key not null)

    if @cam_id is null
        begin
        insert into @Camps_Ids
        select value from dbo.fn_RIASplitDelimited (@camps, '','')
        end
    else
        begin
        insert into @Camps_Ids
        select @cam_id
        end

    IF @AutoInicio = 1
    begin
        UPDATE ccCampsAutoInicio SET tipoRegistros = @tipoRegistros, delaCampana = @delaCampana, condicion = @condicion, numero = @numero,  tipoRegistros2 = @tipoRegistros2, condicion2 = @condicion2, numero2 = @numero2, AutoInicio=0
        WHERE cam_id in (select id from @Camps_Ids)

        select 1
    end

    IF @AutoInicioHora = 1
    begin
        UPDATE ccCampsAutoInicio SET hora = @hora, AutoInicioHora=0
        WHERE cam_id in (select id from @Camps_Ids)

        select 1
    end
end'
    EXEC(@sql)

    set @process = 'CW-6363 Alter Sp ccsp_RIAADMChecaLogin	'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAADMChecaLogin] @Login            VARCHAR(40) = '''', 
                                              @Password         VARCHAR(40) = '''', 
                                              @PasswordLwC      VARCHAR(40) = NULL, 
                                              @adminId          INT         = 0, 
                                              @isChangePassword BIT         = 0
AS
     SET NOCOUNT ON;
     DECLARE @x INT;
     SET @x = 1;
     IF @adminId <> 0
         BEGIN
             UPDATE ccUsers
               SET 
                   onLine = 0
             WHERE User_id = @adminId;
             RETURN(0);
     END;
     DECLARE @UserID SMALLINT;
     --****
     DECLARE @TipoUser_idx INT;
     DECLARE @ver INT;
     DECLARE @changeRecDisposition INT;
     SET @ver = 0;
     SET @changeRecDisposition = 0;

     --****
     SELECT @UserID = User_id, @TipoUser_idx = TipoUser_id
     FROM ccUsers
     WHERE Login = @Login
           AND TipoUser_id IN(2, 6)
     AND STATUS > 0;
     IF(@TipoUser_idx = 2
        OR @TipoUser_idx = 6)
         BEGIN
             IF EXISTS
             (
                 SELECT *
                 FROM ccRIAUsr_AdminPermissions
                 WHERE User_id = @UserID
                       AND per_id IN(2, 6)
             )
                 BEGIN
                     SET @ver = 1;
             END;
             IF EXISTS
             (
                 SELECT *
                 FROM ccRIAUsr_AdminPermissions
                 WHERE User_id = @UserID
                       AND per_id = 7
             )
                 BEGIN
                     SET @changeRecDisposition = 1;
             END;
     END;
     IF NOT EXISTS
     (
         SELECT Login
         FROM ccUsers
         WHERE User_id = @UserID
               AND (Password = @Password
                    OR Password = dbo.md5(@password)
         OR dbo.md5(Password) = @Password
         OR Password = @PasswordLwC
         OR Password = dbo.md5(@PasswordLwC)
     OR dbo.md5(Password) = @PasswordLwC)
     )
         BEGIN             
             SELECT CASE
                        WHEN @UserID IS NULL THEN 0 ELSE 1
                    END ''LoginOK'', 0 ''PswdOK'', 0 ''UserID'', 0 ''Nombre'', 0 ''ADMServer'', 0 ''AreaId'', 0 ''viewavrs'', 0 ''changeRecDisposition'', 0 ''LastPasswordchange'';
             RETURN(0);
     END;
     IF @isChangePassword = 1
         BEGIN
             UPDATE ccUsers
               SET 
                   Password = ISNULL(@PasswordLwC, Password)
             WHERE User_id = @UserID
                   AND Password <> @PasswordLwC;
     END;
     UPDATE ccUsers
       SET 
           onLine = 1
     WHERE User_id = @UserID;
     SELECT 1 ''LoginOK'', 1 ''PswdOK'', User_id ''UserID'', Nombres + '' '' + ISNULL(ApellidoPaterno, '''') + '' '' + ISNULL(ApellidoMaterno, '''') ''Nombre'',
     (
         SELECT valor
         FROM ccSettings
         WHERE setting_id = 8
     ) [ADMServer], ISNULL(IDArea, 0) ''AreaId'', @ver ''ViewAvrs'', @changeRecDisposition ''changeRecDisposition'',
                                                                                       CASE
                                                                                           WHEN DATEDIFF(DAY, LastPasswordChange, GETDATE()) > 30 THEN 1 ELSE 0
                                                                                       END ''LastPasswordchange''
     FROM ccUsers
     WHERE User_id = @UserID;
     
     RETURN(0);
     SET NOCOUNT OFF;'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_RIAADMGetCalifDayForced'
    set @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIAADMGetCalifDayForced]
@type smallint,
@cam_id smallint,
@calif_id smallint = null
AS 
set nocount on
create table #CalifTemp (id int identity,
tipo integer, 
Cam_id varchar(50), 
Calificacion varchar(60), 
subCalificacion varchar(60) null,
calif_id smallint null,
Total int,
GraphColor varchar(15)) 

declare @today datetime
set @today = convert(datetime, convert (varchar(11), getdate(), 101))
--set @today =convert(datetime, convert (varchar(11), ''2015-10-01 17:50:20.470'', 101))

-- Seleccion de idioma -- 
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
from ccsettings where setting_id = 27 -- 0esp

select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
from ccsettings where setting_id = 27 -- 0 esp

if @type=0 
insert into #CalifTemp 
select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13
		then case when description is not null 
					then description 
					else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
					end
else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
end end as Calificacion,
case when count(co.califSub_id) > 0 then 1 else 0 end as Subcalificacion,co.calif_id as calif_id,count(*) cantidad,
ISNULL(GraphColor,''1DB4E2'') GraphColor
from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
left join ccTipoCalifSubOUT tcsout on co.califSub_id = tcsout.califSub_id
left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
left join ccCamps ci on ci.cam_id = co.cam_id 
where co.cal_inicio > @today
and co.cam_id = @cam_id
group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id,GraphColor



if @type=1 
insert into #CalifTemp 
select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
else @nIdioma-- substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
end as Calificacion,count(ci.califSub_id) as subCalificacion,ci.calif_id,count(*)  as total,
ISNULL(GraphColor,''1DB4E2'') GraphColor
from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) 
left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
left join ccInbound cci on cci.inbound_id = ci.inbound_id 
where ci.cal_inicio > @today
and ci.inbound_id = @cam_id
and statuscall_id = 13 
group by description, cci.inbound_id,ci.califSub_id,ci.calif_id,GraphColor



-- Se corrigio suma de totales -- 
Alter table #CalifTemp add iTotal4Campaign int null

if (select valor from ccSettings where setting_id = 78) = 0
update #CalifTemp set iTotal4Campaign = 0

else	
update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
from (select cam_id, sum(A.Total) iTotal4Campaign
from #CalifTemp A group by cam_id) t join #CalifTemp c
on t.cam_id = c.cam_id

if @type=1 
select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total, GraphColor from (
	select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
	 else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	 end as Calificacion,0 as subCalificacion ,0 as calif_id,count(disposition) as Total,ISNULL(GraphColor,''1DB4E2'') GraphColor--,0 as iTotal4Campaign
	from ccriachats a left join ccTipoCalif b 
	on a.disposition=b.calif_id 
	where a.chatDate > @today
	and a.inboundId = @cam_id
	group by inboundId, Description, GraphColor
	
	union all
	
	
	select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	then calificacion 
	else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
	end as Calificacion,
	case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor  --iTotal4Campaign -- para ver total por campaña
	from #CalifTemp 
	group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	then calificacion 
	else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
	end, Cam_id,calif_id, iTotal4Campaign, GraphColor
)  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id,GraphColor order by tipo,cam_id 
if @type=0 

select tipo as Type,Cam_id as CampId,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
then calificacion 
else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
end as Calification,subCalificacion as SubCalificationQuantity, calif_id as CalificationId,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor -- , iTotal4Campaign -- para ver total por campaña
from #CalifTemp 
group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
then calificacion 
else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
end, Cam_id,subCalificacion, calif_id, iTotal4Campaign, GraphColor



if @type = 3 begin -----entrada acd''s
	select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
	else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	end as Calificacion,isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(*) as totales 
	from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
	left join ccInbound cci on cci.inbound_id = ci.inbound_id 
	left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
	where ci.cal_inicio > @today
	and ci.inbound_id = @cam_id
	and statuscall_id = 13 
	and ci.calif_id = @calif_id
	group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id 
end

if @type = 4 begin --salida campañas
		select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
			then case when description is not null 
						then description 
						else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
						end
	else case when sll.descripcion is not null 
	then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	end end as Calificacion,isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad 
	from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
	left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
	left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
	left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
	left join ccCamps ci on ci.cam_id = co.cam_id 
	where co.cal_inicio > @today
	and co.cam_id = @cam_id
	group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
end 
 

drop table #CalifTemp 
set nocount off'
    EXEC(@sql)

    set @process = 'CW-6363 Alter SP ccsp_RIAConfCamp'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
@User_id smallint,
@campID int =null
AS
set nocount on
declare @tableExistsRec table (camId int primary key,existRec bit)
declare @camByUser table (camId int primary key,isCheck bit)
declare @camId int,@id int;

IF Not EXISTS
    (
        SELECT *
        FROM ccUsers_Roles
        WHERE User_id = @User_id
                AND Rol_id = 7
    )begin
	insert into @camByUser 
	select *,0 from dbo.fGet_CampAcd_Area (@User_id, 1) B 
	where @campID is null or cam_id=@campID
end
else begin
	insert into @camByUser 
	select cam_id,0 from ccCamps 
	where (IDArea>0 or IDArea is null)
	and (@campID is null or cam_id=@campID)
end


while exists(select * from @camByUser where isCheck=0)
begin
	select top 1 @camId=camId  from @camByUser where isCheck=0 
	if exists(select cam_id from ccoCallsOut where cam_id=@camId) begin
		insert into @tableExistsRec values(@camId,1)
	end
	else begin
		insert into @tableExistsRec values(@camId,0)
	end

	update  @camByUser  set isCheck=1 where camId=@camId
end


			

select a1.cam_id, cam_Descripcion
, cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
, cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
, cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
, detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
, cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
, stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, 
cam_maxqueue as queSize,
DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
	,cast (startStopRecording as tinyint)startStopRecording, leaveRecMessage, manualCallOnChat
,callBackSurveyAgent,callBackSurveyClient,case when surveycamid is null or surveycamid = 0 then 0 else 1 end isRelationSurvey,isnull(a1.funcEspDtmf,0)
,isnull(sipHdrFormat, '''') sipHdrFormat
,cam_inter_cancelled
,prefijo,	enbleprefix = case when existRec = 0 then 1 else 0 end,
isnull(exitAssisted, 0) exitAssisted
from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
inner join @tableExistsRec a4 on a1.cam_id=a4.camId
--where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
order by cam_descripcion
return(0)
set nocount off'
    EXEC(@sql)

	set @process = 'CW-6363 Alter SP ccspGalatea_Finder'
    set @sql = 'ALTER PROCEDURE [dbo].[ccspGalatea_Finder] @action         INT, 
                                           @userId         INT    = 0, 
                                           @conversationId BIGINT = 0,
                                           @isSuperUser bit=0
AS
     IF @action = 1
         BEGIN--trae el nombre de la base de datos en BX
            if @isSuperUser =0 begin

                 SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, c.cam_descripcion AS label
                 FROM ccRIAWorkGroupUsers Wguser
                      INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                      INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
                                              AND WGCam.Tipo = 1
                 WHERE Wguser.User_id = @userId
                 UNION
                 SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value], CAST(WGCam.Tipo AS INT) + 1 AS callType, inb.descripcion AS label
                 FROM ccRIAWorkGroupUsers Wguser
                      INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                      INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
                                                  AND WGCam.Tipo = 0
                 WHERE Wguser.User_id = @userId;
             end
             else begin
                SELECT CAST(c.cam_id AS INT) AS [Value], CAST(2 AS INT) AS callType, c.cam_descripcion AS label FROM ccCamps c
                UNION
                SELECT CAST(inb.Inbound_id AS INT) AS [Value], CAST(1 AS INT) AS callType, inb.descripcion AS label FROM ccInbound inb;
             end
             RETURN 0;
     END;
     IF @action = 2
         BEGIN
         if @isSuperUser =0 begin
             WITH WgId
                  AS (SELECT IDWG
                      FROM ccRIAWorkGroupUsers Wguser
                      WHERE Wguser.User_id = @userId)
                  SELECT DISTINCT 
                         CAST(Wguser.User_id AS INT) AS [Value], ccUsers.Login AS label
                  FROM ccRIAWorkGroupUsers Wguser
                       INNER JOIN WgId ON Wguser.IDWG = WgId.IDWG
                       INNER JOIN ccUsers ON ccUsers.User_id = Wguser.User_id
                                             AND TipoUser_id = 1;
        end
        else begin
             select CAST(ccUsers.User_id AS INT) AS [Value], ccUsers.Login AS label
             from ccUsers where TipoUser_id = 1;
        end
             RETURN 0;
     END;
     IF @action = 3
         BEGIN--Informacion de la conversacion de whatsApp
             SELECT A.ConversationID, A.inboundId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneACD AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID
             FROM ccWhatsAppConversations A
                  LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
                  LEFT JOIN ccRIAInboundGraph graph ON graph.Inbound_id = A.inboundId
             WHERE A.conversationId = @conversationId;
             RETURN 0;
     END;

     IF @action = 3
         BEGIN--Informacion de la conversacion de whatsApp
             SELECT A.ConversationID, A.inboundId AS AcdId, ISNULL(graph.graphic_id, 1) AS GraphicId, A.phoneACD AS PhoneAcd, A.clientId AS PhoneClient, ISNULL(B.descripcion, ''N/A'') AS AcdName, ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition, ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition, ISNULL(conversationDate, requestDate) DateStart, ISNULL(A.agentId, 0) AgentID
             FROM ccWhatsAppConversations A
                  LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
                  LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                  LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
                  LEFT JOIN ccRIAInboundGraph graph ON graph.Inbound_id = A.inboundId
             WHERE A.conversationId = @conversationId;
             RETURN 0;
     END;'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar nds'
    set @sql = 'update ccPermissions set Description=''Gestionar tipos de no disponible'', KeyJson=''RolesPermissionUnavailableManagement'' where Permissions_Id=10009'
    EXEC(@sql)

    set @process = 'CW-Roles gestionar permisos de agente'
    set @sql = 'update ccPermissions set Description=''Gestionar permisos de agente'', KeyJson=''RolesPermissionAgtPermissionsManagement'' where Permissions_Id=10010'
    EXEC(@sql)

	
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


