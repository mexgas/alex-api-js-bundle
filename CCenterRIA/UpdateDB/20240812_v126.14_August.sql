/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2023/07/04
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
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */--
SET @version = 127 --**********actualizar a 124 sin fix
SET @versionfix = 14
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
--declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end
--IF @version > @actualVersion 
--BEGIN 
--    SET @actualVersionFix = 0
--    select @version,@actualVersion,@versioMajer
--END
IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY
	------------------------------------------------Begin Frida
	set @process = 'DROP PROCEDURE ccsp_GalateaAdminCampaigns'
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminCampaigns'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminCampaigns;
    end
	'
	EXEC(@sql)

	set @process = 'CREATE PROCEDURE ccsp_GalateaAdminCampaigns, add proccess 16 '
	set @sql = '
	
CREATE PROCEDURE ccsp_GalateaAdminCampaigns
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
				@multi_type     varchar(max) = null,
				@IsWhatsAppCampaign  bit = 0
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

					IF @IsWhatsAppCampaign  = 1
					BEGIN
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
							AND camps.CampType = 5
							AND campPerWg.Tipo = @CampType
							AND (
								@Id = 0
								OR campPerWg.IdCampEsp = @Id
								);
					END
					ELSE
					BEGIN
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
								);
					END;

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
							count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34, 37
											) THEN 1 WHEN A.CurrentState IN (6, 34, 4
											)
										AND (
											A.CampId != C.IdCampEsp
											OR A.campType != @CampType
											) THEN 1 ELSE NULL END) AS notReady,
											COUNT(CASE WHEN A.isCampDialog = 1 THEN 1 ELSE NULL END) AS dialog, 
											COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected,
					COUNT(CASE WHEN A.CurrentState = 37 THEN 1 ELSE NULL END) AS auxiliaryReady
						FROM @AgentStatus A
						INNER JOIN @CurrentStatus C ON A.userId = C.userId
						GROUP BY A.CampId
						)
					SELECT A.camId, A.campName, A.Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady, 
							0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL 
								THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady - B.auxiliaryReady END 
						Disconnected, ISNULL(B.auxiliaryReady, 0) AS AuxiliaryReady,A.Area
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
						INTO #tempIds
						FROM ccRIACampEspWG A WITH (NOLOCK)
						INNER JOIN wgId ON wgId.IDWG = A.IDWG
							AND A.Tipo = @CampType;
	
						IF(@CampType = 1)
						BEGIN
							SELECT Id FROM #tempIds ids
							INNER JOIN ccCamps c on c.cam_id = ids.Id
							WHERE (c.CampType = 5 AND @IsWhatsAppCampaign = 1) 
							OR (c.CampType <> 5 AND @IsWhatsAppCampaign = 0)
						END
						ELSE
						BEGIN
							SELECT Id FROM #tempIds ids
							INNER JOIN ccInbound c on c.Inbound_id = ids.Id
							WHERE (c.chat = 5 AND @IsWhatsAppCampaign = 1) 
							OR (c.chat <> 5 AND @IsWhatsAppCampaign = 0)
						END
						DROP TABLE #tempIds
					END;
					ELSE
					BEGIN
						--print ''xxxx Super''
						IF @CampType = 1
						BEGIN
							SELECT DISTINCT CAST(cam_id AS INT) AS Id
							FROM ccCamps WITH (NOLOCK)
							WHERE IDArea IS NOT NULL
							AND(CampType = 5 AND @IsWhatsAppCampaign = 1) 
							OR (CampType <> 5 AND @IsWhatsAppCampaign = 0)
						END
						ELSE
						BEGIN
							SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
							FROM ccInbound WITH (NOLOCK)
							WHERE IDArea IS NOT NULL
							AND (chat = 5 AND @IsWhatsAppCampaign = 1) 
							OR (chat <> 5 AND @IsWhatsAppCampaign = 0)
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
				ELSE IF  @Option=16
				begin
					declare @from datetime = DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0);
					declare @to datetime = DATEADD(second, -1, DATEADD(day, DATEDIFF(day, 0, GETDATE()) + 1, 0));
					select @AreaId = IDArea from ccUsers where User_id = @Id
					declare @camps table (cam_id int)
					insert @camps	select cam_id  FROM  dbo.fGet_CampAcd_Area(@Id,5) group by cam_id
					if((select SUM(cam_id) from @camps) IS NULL)
						begin
							select '''' as CampName
							,0 as Conversations
							,0 as Assign
							,0 as OnQueu
							,0 AS FinishedBySystem
							,0 AS FinishedByAgent
							,'''' as AreaName
							,0 as IsAssignedCamps
						end
					else
						begin
							;with camDesc as(
							select 
							c.cam_id as cam_id
							,cam_descripcion as cam_desc
							,area.AreaName
							from ccCamps c
							inner join @camps id on c.cam_id = id.cam_id
							inner join ccRIACat_Areas area on area.IDArea = c.IDArea
							group by area.AreaName, c.cam_id, c.cam_descripcion
							)
							,
							currentConversationWa as (
							select conversationId, camId, assignDate, onQueue,finishedBy
							,case when conversationStatus = 2 then 1 else 0 end as assigned
							from ccWhatsAppConversationsOut
							where assignDate >= @from and assignDate <= @to
							)
							select 
							b.cam_desc as CampName
							,COALESCE(COUNT(ccw.conversationId), 0) AS Conversations
							,COALESCE(SUM(ccw.assigned), 0) AS Assign
							,COALESCE(count(ccw.onQueue),0) as OnQueu
							,SUM(CASE WHEN ccw.finishedBy = 1 THEN 1 ELSE 0 END) AS FinishedBySystem
							,SUM(CASE WHEN ccw.finishedBy = 2 THEN 1 ELSE 0 END) AS FinishedByAgent
							,b.AreaName as AreaName
							,1 as IsAssignedCamps
							from camDesc b
							left join currentConversationWa ccw on ccw.camId = b.cam_id
							group by b.cam_id, b.cam_desc, b.AreaName
						end
					end

				END;
	'
	EXEC(@sql)

	set @process = ' drop function fGet_CampAcd_Area '
	set @sql = '
	if exists (select * from sys.objects where object_id = OBJECT_ID(N''fGet_CampAcd_Area'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    begin
       drop function fGet_CampAcd_Area
    end
	'
	EXEC(@sql)

	set @process = 'create function fGet_CampAcd_Area add @tipo=5 '
	set @sql = '
	CREATE function fGet_CampAcd_Area (@user int, @tipo int)
returns @camps table (cam_id int)
as
begin
if (select login from ccusers where user_id=@user) = ''root''
      set @user=0
--solo se corrigio para el usuario root
if @tipo = 3 and @user =0
	set @tipo = 1
if @tipo = 4 and @user =0
	set @tipo = 2

if @tipo = 1 begin
      insert @camps select distinct c.cam_id 
      from ccusers u join ccCamps c on u.IDArea = c.IDArea 
      where isnull(u.user_id, 0) = case when @user>0 then @user else isnull(u.user_id, 0) end
      end

else if @tipo = 2 begin
      insert @camps select distinct c.Inbound_id 
      from ccusers u join ccinbound c on u.IDArea = c.IDArea 
      where isnull(u.user_id, 0) = case when @user>0 then @user else isnull(u.user_id, 0) end
      end
if @tipo = 3 begin --Solo trae los seleccionados en el wg
      insert @camps select distinct wgCamAcd.IdCampEsp
      from ccusers u with(nolock)
	  inner join ccCamps c with(nolock) on u.IDArea = c.IDArea
	  inner join ccRIAWorkGroupUsers wg with(index(IX_ccRIAWorkGroupUsers_I),nolock) on wg.User_id=u.User_id
	  inner join ccRIACampEspWG wgCamAcd with(index(IX_ccRIACampEspWG_2),nolock) on wgCamAcd.IDWG=wg.IDWG and tipo=1
      where u.User_id=@user
      end

else if @tipo = 4 begin --Solo trae los seleccionados en el wg
      insert @camps select distinct wgCamAcd.IdCampEsp cam_id from ccUsers u with(nolock)   
	  inner join ccInbound c with(nolock) on c.IDArea= c.IDArea
      inner join ccRIAWorkGroupUsers wg with(index(IX_ccRIAWorkGroupUsers_I),nolock) on wg.User_id=u.User_id
      inner join ccRIACampEspWG wgCamAcd with(index(IX_ccRIACampEspWG_2),nolock) on wgCamAcd.IDWG=wg.IDWG and tipo=0      
      where u.User_id=@user 
      end
else if @tipo = 5 begin --Seleccionados en el wg y que son campañas de whatsApp de salida
	insert @camps select  IdCampEsp from ccRIAWorkGroupUsers wgu
	inner join ccRIACampEspWG wgc on wgc.IDWG = wgu.IDWG
	inner join ccCamps c on c.cam_id = wgc.IdCampEsp
	where User_id=@user and c.CampType=5
    end
return
end
	'
	EXEC(@sql)
	set @process = 'create table ccRecordingsDownload '
	set @sql = '
	if not exists (select * from sys.tables where name = N''ccRecordingsDownload'')
    begin
        CREATE TABLE ccRecordingsDownload (
		date DATETIME NOT NULL,
		adminId int,
		grab_Id BIGINT,
		cam_id int,
		CampType smallint
		)
    end
	'
	EXEC(@sql)

	set @process = 'insert into ccMenus menu_id=7230'
	set @sql = '
	if not exists(select menu_id from ccMenus where menu_id = 7230)
	begin
		insert into ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF,release) values (7230,''Descarga de grabaciones|Recordings Download'',7000,''B'',11,3,'''','''')
	end
	'
	EXEC(@sql)

	
	set @process = ' '
	set @sql = '
	
	'
	EXEC(@sql)
	------------------------------------------------END Frida
	    


        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        /* Error generated based on sintax */ 
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR)  + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()
        RAISERROR (@errorGenerated, 11, 1)
        ROLLBACK TRAN
    END CATCH
END 
