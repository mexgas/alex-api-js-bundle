/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.38

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
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 41
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 39
BEGIN
	BEGIN TRAN

	BEGIN TRY



	set @process = 'CW-3396 Aplicar listas negras relacionadas a la campaña'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaLoadCamps] @option    SMALLINT, 
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
	                        camps.DNCScrub
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
	                            0
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
	                    camps.DNCScrub
	             FROM ccSupervisorCam rel
	                  LEFT JOIN PinCampaings pin ON rel.user_id = pin.Sup_Id
	                                                AND rel.cam_id = pin.Cam_Id
	                  LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
	                  LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
	             WHERE rel.user_id = @Sup
	                   AND rel.cam_id = @CamId
	                   AND rel.tipo = @TypeCamp;
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
	                 FROM dbo.fn_RIASplitDelimited(@WgList, ''|'')
	             )
	             AND Tipo = 1
	             AND IdCampEsp = @CamId;
	     END;
	     IF @option = 6 -- Get Blacklist Ids by Campaign Id
	         BEGIN
	             DECLARE @BlackListIds VARCHAR(MAX);
	             SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
	             FROM Camplistanegra
	             WHERE cam_id = @CamId
	                   AND STATUS = 1;
	             SELECT @BlackListIds AS BlackListIds;
	     END;'

	exec (@sql)

	
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
