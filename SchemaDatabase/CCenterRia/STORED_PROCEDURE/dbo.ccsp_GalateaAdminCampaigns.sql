CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS      SMALLINT, 
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
                                RAISERROR('ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado', 18, 1);
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
                                RAISERROR('ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado', 18, 1);
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
                                RAISERROR('ERROR. No existe campa?as de salida con el id especificado', 18, 1);
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
                                RAISERROR('ERROR. No existe campa?as de entrada con el id especificado', 18, 1);
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
                        RAISERROR('ERROR. No existe la campa?as de entrada con el id especificado', 18, 1);
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
                        RAISERROR('ERROR. La campa?as o administrador no existen', 18, 1);
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
                        RAISERROR('ERROR. El administrador con el id seleccionado no existe', 18, 1);
                END;
                RETURN 0;
        END;
        IF @Option = 6   -- Get Blacklist Ids by Campaign Id
            BEGIN
                IF @Id IS NOT NULL
                    BEGIN
                        DECLARE @BlackListIds VARCHAR(MAX);
                        SELECT @BlackListIds = COALESCE(@BlackListIds + '|' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
                        FROM Camplistanegra
                        WHERE cam_id = @Id
                              AND STATUS = 1;
                        SELECT ISNULL(@BlackListIds, '0') AS BlackListIds;
                END;
                ELSE
                    BEGIN
                        RAISERROR('ERROR. La campa?as con el id seleccionado no existe', 18, 1);
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
                        RAISERROR('ERROR. No existe una campa?a con el id especificado', 18, 1);
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
                              cal_status = '5'
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
                        RAISERROR('ERROR. No existe una carga el id especificado', 18, 1);
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
    END;