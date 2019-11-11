CREATE PROCEDURE [dbo].[ccsp_GalateaLoadCamps] @option    SMALLINT, 
                                              @Sup       SMALLINT     = NULL, 
                                              @TypeCamp  SMALLINT     = NULL, 
                                              @CamId     SMALLINT     = NULL, 
                                              @PinUpdate SMALLINT     = NULL, 
                                              @Wg        SMALLINT     = NULL, 
                                              @WgList    VARCHAR(256) = NULL
AS
     SET NOCOUNT ON;
     DECLARE @AreaId SMALLINT;
     SELECT @AreaId = IDArea
     FROM ccUsers
     WHERE User_id = @Sup;
     IF @option = 1 -- Get Camps
         BEGIN
             IF @TypeCamp = 1 -- Campañas salida por Supervisor
                 SELECT DISTINCT 
                        rel.cam_id, 
                        camps.cam_descripcion, 
                        graph.graphic_id AS Frame,
                        CASE
                            WHEN(ISNULL(pin.Cam_Id, 0)) >= 1
                            THEN 1
                            ELSE 0
                        END AS Pin, 
                        camps.DNCScrub,
						cam_procesando IsStarted
                 FROM ccSupervisorCam rel
                      LEFT JOIN PinCampaings pin ON rel.user_id = pin.Sup_Id
                                                    AND rel.cam_id = pin.Cam_Id
                      LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
                      LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                 WHERE rel.user_id = @Sup
                       AND rel.tipo = 1
                 ORDER BY camps.cam_descripcion ASC;
             IF @TypeCamp = 2 -- Campañas entrada por Supervisor (ACDs)
                 BEGIN
                     SELECT CAST(inbound.Inbound_id AS INT) AS Cam_id, 
                            inbound.descripcion AS Cam_descripcion, 
                            graph.graphic_id AS Frame, 
                            0  Pin,
							0 DNCScrub,
							CAST(0 AS BIT) IsStarted
                     FROM ccInbound inbound
                          LEFT JOIN ccRIAinboundGraph graph ON inbound.Inbound_id = graph.Inbound_id
                          LEFT JOIN ccSupervisorCam supCam ON inbound.Inbound_id = supCam.cam_id
                     WHERE supCam.user_id = @Sup
                           AND tipo = 0
                     ORDER BY inbound.descripcion ASC;
             END;
     END;
     IF @option = 2 -- update Pin campaing
         BEGIN
             IF @PinUpdate = 1
                 BEGIN
                     INSERT INTO PinCampaings
                     (Cam_Id, 
                      Sup_Id
                     )
                     VALUES
                     (@CamId, 
                      @Sup
                     );
             END;
                 ELSE
                 IF @PinUpdate = 0
                     BEGIN
                         DELETE FROM PinCampaings
                         WHERE Cam_Id = @CamId
                               AND Sup_Id = @Sup;
                 END;
     END;
     IF @option = 3  --Get campaign info 
         BEGIN
             SELECT DISTINCT 
                    rel.cam_id, 
                    camps.cam_descripcion, 
                    graph.graphic_id AS Frame,
                    CASE
                        WHEN(ISNULL(pin.Cam_Id, 0)) >= 1
                        THEN 1
                        ELSE 0
                    END AS Pin, 
                    camps.DNCScrub,
					cam_procesando IsStarted
             FROM ccSupervisorCam rel
                  LEFT JOIN PinCampaings pin ON rel.user_id = pin.Sup_Id
                                                AND rel.cam_id = pin.Cam_Id
                  LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
                  LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
             WHERE rel.user_id = @Sup
                   AND rel.cam_id = @CamId AND rel.tipo = @TypeCamp;
     END;
     IF @option = 4 -- Get Campaigns by Supervisor, Wg and type
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
                        WHERE User_id = @Sup
                              AND IDWG <> @WG
                    );
             SELECT CAST(B.IdCampEsp AS INT) AS Cam_id, 
                    CAST(B.Tipo AS INT) AS Type
             FROM @table A
                  RIGHT JOIN
             (
                 SELECT wg.IdCampEsp, 
                        wg.Tipo
                 FROM ccRIACampEspWG wg
                 WHERE wg.IDWG = @WG
             ) B ON A.camId = B.IdCampEsp
                    AND A.campType = B.Tipo
             WHERE A.camId IS NULL
             ORDER BY IdCampEsp;
     END;
     IF @option = 5 -- Get Campaigns by Supervisor, Wgs and type
         BEGIN
             SELECT COUNT(IdCampEsp)
             FROM ccRIACampEspWG
             WHERE IDWG IN
             (
                 SELECT Value
                 FROM dbo.fn_RIASplitDelimited(@WgList, '|')
             )
             AND Tipo = 1
             AND IdCampEsp = @CamId;
     END; 
	 IF @option = 6 -- Get Blacklist Ids by Campaign Id
	         BEGIN
	             DECLARE @BlackListIds VARCHAR(MAX);
	             SELECT @BlackListIds = COALESCE(@BlackListIds + '|' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
	             FROM Camplistanegra
	             WHERE cam_id = @CamId
	                   AND STATUS = 1;
	             SELECT isnull(@BlackListIds,'0') AS BlackListIds;
	     END;