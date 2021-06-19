CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS SMALLINT, 
                                                        @CampType AS SMALLINT = 0, 
                                                        @WorkgroupId AS INT = 0, 
                                                        @Id AS INT = 0,
                                                        @AdminId AS SMALLINT = 0, 
                                                        @PinUpdate AS SMALLINT = 0, 
                                                        @LoadId AS INT = 0,
                                                        @Type AS SMALLINT = 0
            AS
            BEGIN
            set nocount on
            IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type 
            BEGIN
                IF @CampType = 1 -- Campaigns Out 
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                    BEGIN
                        SELECT CAST(IdCampEsp AS INT) AS Id 
                        FROM ccRIACampEspWG 
                        WHERE IDWG = @WorkgroupId AND Tipo=1
                        ORDER BY IdCampEsp ASC
                    END
                    ELSE
                    BEGIN
                        raiserror('ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado', 18, 1)
                    END 
                END
                IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                    BEGIN
                        SELECT CAST(IdCampEsp AS INT) AS Id 
                        FROM ccRIACampEspWG 
                        WHERE IDWG = @WorkgroupId AND Tipo=0
                        ORDER BY IdCampEsp ASC
                    END
                    ELSE
                    BEGIN
                        raiserror('ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado', 18, 1)
                    END 
                END
            END
                    
            IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id 
                BEGIN
                    IF @CampType = 1 -- Campaigns Out 
                        BEGIN
                            IF @Id IS NOT NULL
                                BEGIN
                                    SELECT DISTINCT 
                                        camps.cam_id AS Id, 
                                        camps.cam_descripcion AS Name, 
                                        CAST(graph.graphic_id AS INT) AS Frame, 
                                        CAST(1 AS SMALLINT) AS Type,
                                        camps.cam_procesando IsStarted,
                                        a.AreaName as Area
                                    FROM ccCamps camps 
                                    LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                                    left join ccRIACat_Areas a on a.IDArea = camps.IDArea
                                    WHERE camps.cam_id = @Id 
                                    ORDER BY camps.cam_descripcion ASC;
                                END
                            ELSE
                            BEGIN
                                raiserror('ERROR. No existe campa?as de salida con el id especificado', 18, 1)
                            END 
                        END
                    IF @CampType = 0 -- Campaigns In (ACD)
                        BEGIN
                            IF @Id IS NOT NULL
                                BEGIN
                                    SELECT DISTINCT 
                                        inb.Inbound_id AS Id, 
                                        inb.descripcion AS Name, 
                                        CAST(graph.graphic_id AS INT) AS Frame,
                                        CAST(0 AS SMALLINT) AS Type,
                                        CAST(inb.Status AS BIT) IsStarted,
                                        a.AreaName AS Area,
                                        inb.chat AS InboundType
                                    FROM ccInbound inb
                                    LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                                    left join ccRIACat_Areas a on a.IDArea = inb.IDArea
                                    WHERE inb.Inbound_id = @Id 
                                    ORDER BY inb.descripcion ASC;
                                END
                            ELSE
                                BEGIN
                                    raiserror('ERROR. No existe campa?as de entrada con el id especificado', 18, 1)
                                END 
                        END
                END

            IF @Option = 3   -- Update OverallTotalNew By Campaign 
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            UPDATE ccCampsNvosCB SET OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id
                        END
                    ELSE
                        BEGIN
                            raiserror('ERROR. No existe la campa?as de entrada con el id especificado', 18, 1)
                        END 
                END

            IF @Option = 4   -- Update Pin from Campaign per Admin
                BEGIN
                    IF @Id IS NOT NULL AND @AdminId IS NOT NULL
                        BEGIN
                            IF @PinUpdate = 1
                                BEGIN
                                    INSERT INTO PinedCampaigns (CampId, AdminId, Type)
                                            VALUES (@Id, @AdminId, @Type);
                                END;
                            IF @PinUpdate = 0
                                BEGIN
                                    DELETE FROM PinedCampaigns
                                    WHERE CampId = @Id AND AdminId = @AdminId AND Type = @Type;
                                END;
                        END
                    ELSE
                        BEGIN
                            raiserror('ERROR. La campa?as o administrador no existen', 18, 1)
                        END 
                END
                    
            IF @Option = 5   -- Get Pin from Campaign Ids per Admin
                BEGIN
                    IF @AdminId IS NOT NULL
                        BEGIN
                            SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
                            ORDER BY Id ASC
                        END
                    ELSE
                        BEGIN
                            raiserror('ERROR. El administrador con el id seleccionado no existe', 18, 1)
                        END 
                END

            IF @Option = 6   -- Get Blacklist Ids by Campaign Id
            BEGIN
                IF @Id IS NOT NULL
                    BEGIN
                        DECLARE @BlackListIds VARCHAR(MAX);
                        SELECT @BlackListIds = COALESCE(@BlackListIds + '|' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
                        FROM Camplistanegra
                        WHERE cam_id = @Id AND STATUS = 1;
                        SELECT isnull(@BlackListIds,'0') AS BlackListIds;
                    END
                ELSE
                    BEGIN
                        raiserror('ERROR. La campa?as con el id seleccionado no existe', 18, 1)
                    END 
            END

            IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
            BEGIN
                IF (@Id IS NOT NULL AND EXISTS(SELECT * FROM cccamps WHERE cam_id = @Id))
                    BEGIN
                        SELECT TOP 1 list_id FROM ccRIARegistryLists WHERE cam_id = @Id AND status = 2 ORDER BY list_id DESC
                    END
                ELSE
                    BEGIN
                        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                        raiserror('ERROR. No existe una campa?a con el id especificado', 18, 1)           
                    END 
            END

            IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
            BEGIN
                IF (@LoadId IS NOT NULL AND EXISTS(SELECT * FROM ccRIARegistryLists WHERE list_id = @loadID and status <> 0))
                    BEGIN
                        UPDATE ccoCallsOutSource SET cal_status = '5' WHERE list_id = @loadID
                        DELETE FROM ccoWorkingTable WHERE list_id = @LoadId 
                        exec ccsp_RIARegistryLists @action=6, @list_id = @LoadId 
                    END
                ELSE
                    BEGIN
                        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                        raiserror('ERROR. No existe una carga el id especificado', 18, 1)
                    END     
            END

            IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
                    BEGIN
                        DECLARE @table TABLE
                        (camId    INT, 
                        campType TINYINT,
                        PRIMARY KEY(camId, campType)
                        );
                        INSERT INTO @table
                            SELECT DISTINCT 
                                    IdCampEsp, 
                                    Tipo
                            FROM ccRIACampEspWG wg
                            WHERE wg.IDWG IN
                            (
                                SELECT IDWG
                                FROM ccRIAWorkGroupUsers
                                WHERE IDWG <> @WorkgroupId
                                AND User_id = @AdminId
                            );
                        SELECT CAST(B.IdCampEsp AS INT) AS Id, 
                            B.Tipo AS Type
                        FROM @table A
                            RIGHT JOIN
                        (
                            SELECT wg.IdCampEsp, 
                                wg.Tipo
                            FROM ccRIACampEspWG wg
                            WHERE wg.IDWG = @WorkgroupId
                        ) B ON A.camId = B.IdCampEsp
                            AND A.campType = B.Tipo
                        WHERE A.camId IS NULL
                        ORDER BY IdCampEsp;
                END;
            IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type 
                BEGIN
                    DECLARE @date datetime = CONVERT(DATE, DATEADD(hh, -3, GETDATE()))
                    DECLARE @Wg TABLE(id INT, PRIMARY KEY(id));
                    DECLARE @tmpAgent TABLE(id INT, PRIMARY KEY(id));
                    DECLARE @tmpCamAgent TABLE(camId INT, userId INT, PRIMARY KEY( camId, userId ));
                    DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT);
                    DECLARE @AgentStatusWithTotals TABLE(CampName VARCHAR(MAX), Total INT, Ready INT, NotReady INT, Dialog INT, Area VARCHAR(MAX));

                    INSERT INTO @Wg
                            SELECT DISTINCT IDWG FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
                             WHERE WG.User_id = @AdminId OR
                                  (R.User_id = @AdminId
                                    AND R.Rol_id = 7);

                    INSERT INTO @tmpAgent
                            SELECT DISTINCT  A.User_id FROM ccRIAWorkGroupUsers A
                            INNER JOIN @Wg B ON A.IDWG=B.id
                            INNER JOIN ccUsers C ON A.User_id=C.User_id AND C.TipoUser_id=1  
                            ORDER BY A.User_id;

                    INSERT INTO @tmpCamAgent
                            SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id FROM ccRIACampEspWG campPerWg
                            INNER JOIN @Wg wg ON wg.Id=campPerWg.IDWG
                            INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG=wg.id 
                            INNER JOIN ccUsers C ON wgUser.User_id=C.User_id AND C.TipoUser_id=1
                            WHERE campPerWg.Tipo = @CampType;

                    WITH lastState
                            AS ( SELECT A.user_id,  MAX( A.fecha ) AS fecha
                                FROM ccLogAgentesDia A
                                INNER JOIN @tmpAgent B ON A.User_id=B.id
                                WHERE fecha>= @date
                                GROUP BY user_id )


                            INSERT INTO @AgentStatus
                                SELECT A.camId,  A.userId, 
                                ISNULL( B.currentStatus, 0 ) currentStatus,
                                CASE WHEN B.IdCampEsp=A.camId AND B.Tipo = @CampType AND B.currentStatus IN( 4, 5, 6, 9 ) THEN 1 ELSE NULL END AS isCampDialog
                                FROM @tmpCamAgent A
                                LEFT JOIN
                                (
                                    SELECT B.User_id, 
                                            B.currentStatus, 
                                            B.IdCampEsp, 
                                            B.Tipo
                                    FROM lastState A
                                    INNER JOIN
                                    ccLogAgentesDia B
                                    ON A.User_id=B.User_id
                                        AND A.fecha=B.fecha
                                ) B
                                ON A.userId=B.User_id;

                    IF @CampType = 1
                        BEGIN
                            IF @Id <> 0
                                INSERT INTO @AgentStatusWithTotals
                                SELECT  B.cam_descripcion,
                                        COUNT( CurrentState ) as total,
                                        COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ) as ready, 
                                        COUNT( CASE WHEN CurrentState NOT IN( 3, 4, 5, 6, 9 )  THEN 1 ELSE NULL END) 
                                        + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
                                    
                                        as notReady,
                                        COUNT( isCampDialog ) as dialog,  
                                        C.AreaName
                                FROM @AgentStatus A
                                INNER JOIN ccCamps B on A.CampId=B.cam_id
                                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                                WHERE A.CampId = @Id
                                GROUP BY B.cam_descripcion, CampId, C.AreaName
                            ELSE
                                INSERT INTO @AgentStatusWithTotals
                                SELECT  B.cam_descripcion,
                                        COUNT( CurrentState ) as total,
                                        COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ) as ready, 
                                        COUNT( CASE WHEN CurrentState NOT IN( 3, 4, 5, 6, 9 )  THEN 1 ELSE NULL END) 
                                        + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
                                    
                                        as notReady,
                                        COUNT( isCampDialog ) as dialog,  
                                        C.AreaName
                                FROM @AgentStatus A
                                INNER JOIN ccCamps B on A.CampId=B.cam_id
                                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                                GROUP BY B.cam_descripcion, CampId, C.AreaName
                        END 
                    ELSE 
                        BEGIN 
                            IF @Id <> 0
                                INSERT INTO @AgentStatusWithTotals
                                SELECT  B.descripcion,
                                        COUNT( CurrentState ),
                                        COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ), 
                                        COUNT( CASE WHEN CurrentState NOT IN(3, 4, 5, 6, 9 ) THEN 1 ELSE NULL END)
                                        + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
                                        ,
                                        COUNT( isCampDialog ), 
                                        C.AreaName
                                FROM @AgentStatus A
                                INNER JOIN ccInbound B on A.CampId = B.Inbound_id  
                                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                                WHERE A.CampId = @Id
                                GROUP BY  B.descripcion, CampId , C.AreaName
                            ELSE
                                INSERT INTO @AgentStatusWithTotals
                                SELECT  B.descripcion,
                                        COUNT( CurrentState ),
                                        COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ), 
                                        COUNT( CASE WHEN CurrentState NOT IN(3, 4, 5, 6, 9 ) THEN 1 ELSE NULL END)
                                        + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
                                        ,
                                        COUNT( isCampDialog ), 
                                        C.AreaName
                                FROM @AgentStatus A
                                INNER JOIN ccInbound B on A.CampId = B.Inbound_id  
                                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                                    WHERE B.chat = 0
                                GROUP BY  B.descripcion, CampId , C.AreaName
                        END 
                             
                            
                    SELECT * FROM @AgentStatusWithTotals
                    ORDER BY CampName
                END;

            END