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

			IF @Option = 4	 -- Update Pin from Campaign per Admin
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
			
			IF @Option = 5	 -- Get Pin from Campaign Ids per Admin
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

			IF @Option = 6	 -- Get Blacklist Ids by Campaign Id
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

			IF @Option = 7	 -- Get RegistryListIds Ids by Campaign Id
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

			IF @Option = 8	 -- Delete RegistryListIds Ids by LoadId
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

			 IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
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
		END