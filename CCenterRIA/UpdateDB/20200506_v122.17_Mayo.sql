/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/05/06
Description:

Database: CCenterRia
Required version: 122.17

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
SET @version = 122 --**********actualizar a 122 sin fix
SET @versionfix = 17
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 16
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-4065 Crear Setting para uso de Medios Unificados'
		set @sql='IF not exists (SELECT * FROM ccSettings WHERE setting_id = 220)
				insert into ccSettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
				Values(220,''0'',''Mostrar icono para medios unificados'',1,''AGT'',''0:Oculta icono para medios unificados, 1:Muestra icono para medios unificados'',''Shows multimedia icon'',0,''^[0-1]$'')	'
		EXEC(@sql)

		set @process = 'CW-4009 Campañas se siguen mostrando aunque el Admin ya no esté asociado a WG'
		set @sql='
			
				ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS SMALLINT, 
																   @CampType AS SMALLINT = 0, 
																   @WorkgroupId AS INT = 0, 
																   @Id AS INT = 0,
																   @AdminId AS SMALLINT = 0, 
																   @PinUpdate AS SMALLINT = 0, 
																   @LoadId AS INT = 0
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
								raiserror(''ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado'', 18, 1)
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
								raiserror(''ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado'', 18, 1)
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
												rel.cam_id AS Id, 
												camps.cam_descripcion AS Name, 
												CAST(graph.graphic_id AS INT) AS Frame, 
												CAST(rel.tipo AS SMALLINT) AS Type,
												cam_procesando IsStarted
											FROM ccSupervisorCam rel
												LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
												LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
											WHERE rel.cam_id = @Id AND rel.tipo = 1
											ORDER BY camps.cam_descripcion ASC;
										END
									ELSE
									BEGIN
										raiserror(''ERROR. No existe campa?as de salida con el id especificado'', 18, 1)
									END	
								END
							IF @CampType = 0 -- Campaigns In (ACD)
								BEGIN
									IF @Id IS NOT NULL
										BEGIN
											SELECT DISTINCT 
												rel.cam_id AS Id, 
												inbound.descripcion AS Name, 
												CAST(graph.graphic_id AS INT) AS Frame,
												0 Pin, 
												CAST(rel.tipo AS SMALLINT) AS Type,
												CAST(0 AS BIT) IsStarted
											FROM ccSupervisorCam rel
												LEFT JOIN ccInbound inbound ON inbound.Inbound_id = rel.cam_id
												LEFT JOIN ccRIAInboundGraph graph ON inbound.Inbound_id = graph.Inbound_id
											WHERE rel.cam_id = @Id AND rel.tipo = 0
											ORDER BY inbound.descripcion ASC;
										END
									ELSE
										BEGIN
											raiserror(''ERROR. No existe campa?as de entrada con el id especificado'', 18, 1)
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
									raiserror(''ERROR. No existe la campa?as de entrada con el id especificado'', 18, 1)
								END	
						END

					IF @Option = 4	 -- Update Pin from Campaign per Admin
						BEGIN
							IF @Id IS NOT NULL AND @AdminId IS NOT NULL
								BEGIN
									IF @PinUpdate = 1
										BEGIN
											INSERT INTO PinedCampaigns (CampId, AdminId)
												   VALUES (@Id, @AdminId);
										END;
									IF @PinUpdate = 0
										BEGIN
											DELETE FROM PinedCampaigns
											WHERE CampId = @Id AND AdminId = @AdminId;
										END;
								END
							ELSE
								BEGIN
									raiserror(''ERROR. La campa?as o administrador no existen'', 18, 1)
								END	
						END
					
					IF @Option = 5	 -- Get Pin from Campaign Ids per Admin
						BEGIN
							IF @AdminId IS NOT NULL
								BEGIN
									SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId
									ORDER BY Id ASC
								END
							ELSE
								BEGIN
									raiserror(''ERROR. El administrador con el id seleccionado no existe'', 18, 1)
								END	
						END

					IF @Option = 6	 -- Get Blacklist Ids by Campaign Id
					BEGIN
						IF @Id IS NOT NULL
							BEGIN
					            DECLARE @BlackListIds VARCHAR(MAX);
					            SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
					            FROM Camplistanegra
					            WHERE cam_id = @Id AND STATUS = 1;
					            SELECT isnull(@BlackListIds,''0'') AS BlackListIds;
							END
						ELSE
							BEGIN
								raiserror(''ERROR. La campa?as con el id seleccionado no existe'', 18, 1)
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
								raiserror(''ERROR. No existe una campa?a con el id especificado'', 18, 1)			
							END	
					END

					IF @Option = 8	 -- Delete RegistryListIds Ids by LoadId
					BEGIN
						IF (@LoadId IS NOT NULL AND EXISTS(SELECT * FROM ccRIARegistryLists WHERE list_id = @loadID and status <> 0))
							BEGIN
								UPDATE ccoCallsOutSource SET cal_status = ''5'' WHERE list_id = @loadID
								DELETE FROM ccoWorkingTable WHERE list_id = @LoadId 
								exec ccsp_RIARegistryLists @action=6, @list_id = @LoadId 
							END
						ELSE
							BEGIN
								--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
								raiserror(''ERROR. No existe una carga el id especificado'', 18, 1)
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

		'
		EXEC(@sql)

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		-- exec ccsp_getVersion 'BD', @version
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
