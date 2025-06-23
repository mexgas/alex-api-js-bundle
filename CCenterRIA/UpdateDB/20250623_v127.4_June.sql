/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio Chagolla
Date: 2025/06/23
Description: Release 127.20250623.0.0
Database: CCenterRia
Required version: 127.2
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
SET @version = 127 --**********actualizar a 124 sin fix
SET @versionfix = 4
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

    ---------------------- BEGIN Carlos Muñoz ----------------------

    SET @process = 'K0700118 - Creating a new table to store virtual agent voice data'
	SET @Sql='
		if  not exists(SELECT * FROM sysobjects WHERE name=''ccVirtualAgentVoices'') 
	
		begin 

            CREATE TABLE ccVirtualAgentVoices (
                ID INT IDENTITY(1,1) PRIMARY KEY,
                Name VARCHAR(100) NOT NULL,
                Gender VARCHAR(30) CHECK (gender IN (''Male'',''Female'')),
                FileName VARCHAR(500),
                IsDefault BIT DEFAULT 0,
                CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
            );
		end
		'	
	EXEC(@Sql)

    SET @process = 'K0700118 - Inserting default virtual agent voice records'
	SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccVirtualAgentVoices WHERE ID = 1)
	BEGIN
        INSERT INTO ccVirtualAgentVoices (Name, Gender, FileName, IsDefault) VALUES(''Alma'', ''Female'', ''Alma.mp3'', 1);
	END'
    EXEC(@sql)

	SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccVirtualAgentVoices WHERE ID = 2)
	BEGIN
        INSERT INTO ccVirtualAgentVoices (Name, Gender, FileName, IsDefault) VALUES(''Luis'', ''Male'', ''Luis.mp3'', 0);
	END'
    EXEC(@sql)


    SET @process = 'Adding two new columns to support new transfer types in AI Campaigns'
    SET @sql = '
            IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''idForSuccessfulTransaction'' AND Object_ID = Object_ID(N''ccInbound''))
            BEGIN
                ALTER TABLE ccInbound ADD idForSuccessfulTransaction SMALLINT
            END

            IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''idForNonComprehension'' AND Object_ID = Object_ID(N''ccInbound''))
            BEGIN
                ALTER TABLE ccInbound ADD idForNonComprehension SMALLINT
            END'
    EXEC(@sql)

    SET @process = 'K070066 - Adding option 19 to bring inbound campaigns from a certain workgroup or area and associated to the IA Campaign.'

    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_GalateaAdminCampaigns'')
        BEGIN
            DROP PROCEDURE dbo.ccsp_GalateaAdminCampaigns
        END'
    EXEC(@sql);


    SET @sql = '
    CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns]
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
					@IsWhatsAppCampaign  bit = 0,
					@groupList as varchar (MAX) = NULL,
					@CampId AS      SMALLINT = 0
					AS
					BEGIN
						SET NOCOUNT ON;
					IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type     
						IF @WorkgroupId IS NOT NULL BEGIN
							SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId
							ORDER BY IdCampEsp ASC;
						END;
						ELSE BEGIN
							RAISERROR(''ERROR. No existe una lista de campañas con el id de grupo de trabajo especificado'', 18, 1);
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
								CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10  ELSE isnull(camps.CampType,0) END as OutboundType,
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

					ELSE IF @option = 10 BEGIN -- Get Agents States with totals per campaign by admin id and campaign type **********************
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
							camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), NumberOfVirtualAgents INT, PRIMARY KEY (camId
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
							INSERT INTO @tmpCamAgent --Obtiene las relaciones entre agentes y campañas
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
								AND (camps.CampType = 5 or inbound.chat = 5)
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
							WHERE multimediaType = 0
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
							SELECT A.camId, B.cam_descripcion AS campName, A.Total, C.AreaName AS Area, ISNULL(va.concurrentSessionsLimit,0) as NumberOfVirtualAgents 
							FROM campDataTotal A
							INNER JOIN ccCamps B ON A.camId = B.cam_id
							INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                            LEFT JOIN ccVirtualAgent va ON B.cam_id = va.idCampaign AND va.campType = 1
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
							SELECT A.camId, B.descripcion AS campName, A.Total, C.AreaName AS Area, 0 as NumberOfVirtualAgents 
							FROM campDataTotal A
							INNER JOIN ccInbound B ON A.camId = B.Inbound_id
							INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
						END;

						WITH stateCamp
						AS (
							SELECT A.CampId, count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready, 
								count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34, 37
												) THEN 1 WHEN A.CurrentState IN (6, 4
												)
											AND (
												A.CampId != C.IdCampEsp
												OR A.campType != @CampType
												) THEN 1 ELSE NULL END) AS notReady,
												COUNT(CASE WHEN A.isCampDialog = 1 OR A.CurrentState = 34 THEN 1 ELSE NULL END) AS dialog, 
												COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected,
						COUNT(CASE WHEN A.CurrentState = 37 THEN 1 ELSE NULL END) AS auxiliaryReady
							FROM @AgentStatus A
							INNER JOIN @CurrentStatus C ON A.userId = C.userId
							GROUP BY A.CampId
							)
						SELECT A.camId, A.campName, (A.Total + A.NumberOfVirtualAgents) AS Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady, 
								0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL 
									THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady - B.auxiliaryReady END 
							Disconnected, ISNULL(B.auxiliaryReady, 0) AS AuxiliaryReady, A.NumberOfVirtualAgents ,A.Area
						FROM @campDataTotal A
						LEFT JOIN stateCamp B ON A.camId = B.CampId
						ORDER BY A.campName

						RETURN 0;
					END; -- *****************************************************************************************
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
										CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10 ELSE isnull(camps.CampType,0) END as OutboundType,
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
								FROM ccInbound NOLOCK where cam_id = @Id and chat IN (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))
					END
					ELSE IF  @Option=16
					begin
						DECLARE @from DATETIME = CAST(GETDATE() AS DATE);
						DECLARE @to DATETIME = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, @from));
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
								from ccCamps c with (nolock)
								inner join @camps id on c.cam_id = id.cam_id
								inner join ccRIACat_Areas area on area.IDArea = c.IDArea
								group by area.AreaName, c.cam_id, c.cam_descripcion
								)
								,
								currentConversationWa as (
								select conversationId, camId, assignDate, onQueue,finishedBy
								,case when conversationStatus = 2 then 1 else 0 end as assigned
								from ccWhatsAppConversationsOut with (nolock)
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
					ELSE IF @Option = 17 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
							IF @groupList IS NOT NULL BEGIN
								IF OBJECT_ID(''tempdb..#WGDelete'') IS NOT NULL DROP TABLE #WGDelete;
								SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, '','')
								SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type, IDWG AS IdWg FROM ccRIACampEspWG WHERE IDWG in (select IDwg from #WGDelete)
								ORDER BY IdCampEsp ASC;
							END;
							ELSE BEGIN
								RAISERROR(''ERROR. No existe una lista de campañas con los ids de grupo de trabajo especificados'', 18, 1);
							END;
							RETURN 0;
						END;

					ELSE IF @Option = 18 BEGIN -- Validar si la campaña fue eliminada del area 
							DECLARE @activo INT;

							IF @CampType = 0 BEGIN
								SELECT @activo = ISNULL(IDArea, 0) 
								FROM ccInbound
								WHERE Inbound_id = @Id;
							END; 

							ELSE BEGIN
							    SELECT @activo = ISNULL(IDArea, 0) 
								FROM ccCamps 
								WHERE cam_id = @Id;
							END;

							SELECT @activo;
						END;

					ELSE IF @Option = 19
						BEGIN

							DECLARE @SuccessId INT, @NonComprehensionId INT;
							DECLARE @IsSuperUser BIT = 0;
							DECLARE @wgId TABLE (IDWG INT);

							IF EXISTS (SELECT * FROM ccUsers_Roles NOLOCK WHERE User_id = @AdminId AND Rol_id = 7)
							BEGIN
								SET @IsSuperUser = 1;
							END
							ELSE
							BEGIN
								INSERT INTO @wgId (IDWG)
								SELECT IDWG
								FROM ccRIAWorkGroupUsers WITH (NOLOCK)
								WHERE user_id = @AdminId;
							END

							SELECT 
								@SuccessId = ISNULL(idForSuccessfulTransaction, -1),
								@NonComprehensionId = ISNULL(idForNonComprehension, -1)
							FROM ccInbound WITH (NOLOCK)
							WHERE Inbound_id = @CampId;

							WITH MainCampaigns AS (
								SELECT 
									CAST(cci.Inbound_id AS INT) AS CampId,
									cci.descripcion AS Description,
									ISNULL(cci.IDArea, -1) AS AreaID,
									CAST(cci.chat AS SMALLINT) AS CampaignType,
									CAST(0 AS BIT) AS IsSuccessTransfer,
									CAST(0 AS BIT) AS IsNonComprehensionTransfer
								FROM ccInbound cci WITH (NOLOCK)
								WHERE 
								(
									-- Superusuario: por Área
									(@IsSuperUser = 1 AND cci.IDArea = @AreaId)
									OR
									-- Usuario normal: por Workgroup
									(@IsSuperUser = 0 AND EXISTS (
										SELECT 1 FROM ccRIACampEspWG A WITH (NOLOCK)
										INNER JOIN @wgId wg ON wg.IDWG = A.IDWG
										WHERE A.Tipo = 0 AND A.IdCampEsp = cci.Inbound_id
									))
								)
								AND cci.chat = 0
								AND cci.IDArea = @AreaId
							),
							ReferencedCampaigns AS (
								SELECT 
									CAST(cci.Inbound_id AS INT) AS CampId,
									cci.descripcion AS Description,
									ISNULL(cci.IDArea, -1) AS AreaID,
									CAST(cci.chat AS SMALLINT) AS CampaignType,
									CASE WHEN cci.Inbound_id = @SuccessId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsSuccessTransfer,
									CASE WHEN cci.Inbound_id = @NonComprehensionId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsNonComprehensionTransfer
								FROM ccInbound cci WITH (NOLOCK)
								WHERE cci.Inbound_id IN (@SuccessId, @NonComprehensionId)
							)

							SELECT * FROM ReferencedCampaigns
							UNION ALL
							SELECT m.*
							FROM MainCampaigns m
							LEFT JOIN ReferencedCampaigns r
							  ON m.CampId = r.CampId
							WHERE r.CampId IS NULL;
						END;
					END;
    
    '
    EXEC(@Sql)

    SET @process = 'K070066 - Including new identifiers for the new transfer types'

	SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''ASSOCIATED_CAMP_XFER_IA'')
	BEGIN
        INSERT INTO ccGalateaIdentifiers VALUES (''ASSOCIATED_CAMP_XFER_IA'', ''Campaña asociada (transferencia a agentes humanos)'', ''Associated campaign (live agent transfer)'', ''Campanha associada (transferência para agentes humanos)'')
	END'
    EXEC(@sql)

    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''ASSOCIATED_CAMP_SUCCESSFUL_TRANSACTION'')
	BEGIN
        INSERT INTO ccGalateaIdentifiers VALUES (''ASSOCIATED_CAMP_SUCCESSFUL_TRANSACTION'', ''Campaña asociada (transferencia por gestión exitosa)'', ''Associated campaign (successful interaction transfer)'', ''Campanha associada (transferência de interação bem‑sucedida)'')
	END'
    EXEC(@sql)


    SET @process = 'K070066 - Adding a new option to associate new transfer types.'

    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_GalateaAdminInbound'')
        BEGIN
            DROP PROCEDURE dbo.ccsp_GalateaAdminInbound
        END'
    EXEC(@sql);

    SET @sql = '
    CREATE PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                            @InboundId AS SMALLINT = 0,
											@User_id AS SMALLINT = 0,
											@OutboundID AS SMALLINT = 0,
											@multi_cam as varchar(max) = null,
											@Module AS SMALLINT = 13,
											@Type AS SMALLINT = 0,
											@HistoryAction AS SMALLINT = 1,
											@AreaId AS SMALLINT = 0,
											@NonComprehensionId AS SMALLINT = -1,
											@SuccessfulTransactionCampaignId AS SMALLINT = -1,
											@CallBackCampaignId AS SMALLINT = -1,
											@IsEditing AS BIT = 0
		AS
		BEGIN
			set nocount on;

			DECLARE @idArea SMALLINT = NULL;
			DECLARE @operation INT = -1;
			DECLARE @mediaType INT = 0;

			IF(@Option IN (5, 6)) BEGIN
				IF(@Module IS NOT NULL AND @Module <> 13) BEGIN
				
					IF(@Type = 0)BEGIN
						
						IF(@multi_cam is not null) BEGIN
							SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
						END ELSE BEGIN
							SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id = @InboundId)
						END

						SET @operation = CASE WHEN @HistoryAction = 1 THEN 
																			CASE 
																					WHEN @mediaType = 1  THEN 63
																					WHEN @mediaType = 5  THEN 40
																					ELSE 60 END
																	  ELSE 
																			CASE 
																					WHEN @mediaType = 1  THEN 64
																					WHEN @mediaType = 5  THEN 53
																					ELSE 52 END
																	  END;
					END ELSE BEGIN

						SET @mediaType = (SELECT [CampType] FROM ccCamps WHERE cam_id = @OutboundID)

						SET @operation = CASE WHEN @HistoryAction = 1 THEN 
																			CASE 
																					WHEN @mediaType = 6  THEN 44
																					WHEN @mediaType = 5  THEN 46
																					WHEN @mediaType = 9  THEN 48
																					WHEN @mediaType = 7  THEN 50
																					ELSE 42 END
																	   ELSE 
																			CASE 
																					WHEN @mediaType = 6  THEN 55
																					WHEN @mediaType = 5  THEN 56
																					WHEN @mediaType = 9  THEN 57
																					WHEN @mediaType = 7  THEN 58
																					ELSE 54 END
																	    END;
					END

				END ELSE BEGIN
					SET @operation = CASE WHEN @Option = 5 THEN 93 ELSE 94 END;
				END
			END

			if(@Option = 1) -- Por campaña 
			begin
			    select 
			        ISNULL(count (*), 0) as Calls,
			        ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
			        ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
			        ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
			        ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
			        ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
			        ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
			        ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
			        ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
			        ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
			        THEN 1 ELSE NULL END), 0) AS Other
			    from ccCallsIn a (nolock)
			    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId

			end

			if(@Option = 2) -- Todas las campañas 
			begin
			    select 
					inbound.Inbound_id as IDEspec,
					inbound.descripcion as Name,
			        ISNULL(count (*), 0) as Calls,
			        ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
			        ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
			        ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
			        ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
			        ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
			        ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
			        ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
			        ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
			        ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
			        THEN 1 ELSE NULL END), 0) AS Other
			    from ccCallsIn a (nolock)
				left join ccInbound inbound on a.inbound_id = inbound.Inbound_id
			    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) 
				group by inbound.Inbound_id, inbound.descripcion
			end

			if(@Option = 3) -- Obtiene los datos de las llamadas de todos los ACD, datos que se muestran en el tablero de información del administrador 
			begin
				SELECT 
					a.inbound_id, calls = ISNULL(COUNT(*), 0), -- calls
					Dialogs = ISNULL(COUNT (CASE WHEN statusCall_id = 13 THEN 1 ELSE NULL END), 0), -- Answered
					DlgsAveTime =CONVERT(int, ISNULL(SUM (CASE WHEN statusCall_id = 13 THEN cal_tDialog + cal_tNotas ELSE 0 END), 0)),
					QueueAveTime =ISNULL( avg( CASE WHEN cal_que > 0 THEN cal_tWait ELSE NULL END), 0) ,
					abandon = ISNULL(COUNT(CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0), -- Abandoned
					OverFlowQueue = ISNULL(COUNT (CASE WHEN statusCall_id =8 THEN 1 ELSE NULL END), 0),
					OverFlowTimeOut = ISNULL(COUNT (CASE WHEN statusCall_id =7 THEN 1 ELSE NULL END), 0), -- OverFlowQueue+OverFlowTimeOut = not answered
					outOfSchedule = ISNULL(COUNT (CASE WHEN statusCall_id =2 THEN 1 ELSE NULL END), 0), -- fuera de horario
					outOfService = ISNULL(COUNT (CASE WHEN statusCall_id =3 THEN 1 ELSE NULL END), 0), -- fuera de servicio
					noAgentsLoggedIn = ISNULL(COUNT (CASE WHEN statusCall_id =4 THEN 1 ELSE NULL END), 0), -- sin agentes firmados
					assigned = ISNULL(COUNT (CASE WHEN statusCall_id =11 THEN 1 ELSE NULL END), 0), -- asignada
					--assignedAndNotAnswered = ISNULL(COUNT (CASE WHEN statusCall_id =15 THEN 1 ELSE NULL END), 0), -- asignada y no contestada
					--assignedAndTookLine = ISNULL(COUNT (CASE WHEN statusCall_id =16 THEN 1 ELSE NULL END), 0), -- asignada y toma linea
					callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0)
					--onQueue = ISNULL(COUNT(CASE WHEN statusCall_id = 5 THEN 1 ELSE NULL END), 0)
					--initCalls = CAST(ISNULL(COUNT(CASE WHEN statusCall_id = 1 THEN 1 ELSE NULL END), 0) AS varchar(7))+''|''+
					--			ISNULL((SELECT STUFF((SELECT ''|'' + cast(ci.cal_id AS varchar(7))
					--			FROM ccCallsin ci (nolock) WHERE cal_inicio > dateadd(mi,-5,getdate()) AND ci.inbound_id=a.inbound_id
					--			FOR XML PATH('''')) ,1,1,'''')),''0'')
				FROM ccCallsIn a (nolock)
				WHERE cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
						--and a.inbound_id in (select cam_id from ccSupervisorCam where user_id = @User_id and tipo = 0)
				GROUP BY a.inbound_id
			--	SET nocount off
			--	return(0)
			end

			if(@Option = 4) -- Carga los ACD del administrador mandado
			begin
				SELECT cam_id 
				FROM ccSupervisorCam  nolock
				WHERE user_id = @User_id and tipo = 0
				SET nocount off
				return(0)
			end

			IF(@Option = 5) -- Relate the inbound campaign with the outbound campaign
			BEGIN
				IF(@idArea IS NULL OR @idArea = -1) SET @idArea = 
					CASE WHEN @Type = 0 
						THEN 
							CASE WHEN @multi_cam IS NULL
								THEN (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @InboundID) 
								ELSE (SELECT [IDArea] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
								END
						ELSE (SELECT [IDArea] FROM ccCamps WHERE cam_id = @OutboundID)
						END

				IF(@multi_cam is not null)
				BEGIN
					UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id IN (
						SELECT value from dbo.fn_RIASplitDelimited(@multi_cam,'',''))

					IF (@multi_cam <> '''' )
					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
					SELECT
						(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
						getDate(), 
						(SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
						@operation,
						@Module,
						CASE WHEN @Module = 13 THEN '''' ELSE ''ASSOCIATED_CAMP_CALLBACK'' END,
						CASE WHEN @Type = 0 THEN
												(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @OutboundID)
											ELSE 
												(SELECT [descripcion] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
											END,
						CASE WHEN @Type = 0 THEN
												(SELECT [descripcion] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
											ELSE 
												(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @OutboundID)
											END

					SELECT 1;
					RETURN 1;
				END
				IF((SELECT ISNULL(cam_id,-1) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId) != -1)
					BEGIN
						SELECT -1;
						RETURN -1;
					END;
				ELSE
					BEGIN
						UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id = @InboundID;
							
						IF(@Type <> 1 AND @InboundID <> 0)
						INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
						SELECT
							(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
							getDate(), 
							(SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
							@operation,
							@Module,
							CASE WHEN @Module = 13 THEN '''' ELSE ''ASSOCIATED_CAMP_CALLBACK'' END,
							(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [cam_id] FROM ccInbound WHERE Inbound_id = @InboundID)),
							(SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @InboundID)

						SELECT 1;
						RETURN 1;
					END;
			END;        
			IF(@Option = 6) -- Delete the relation between inbound and outbound campaigns
			BEGIN

			IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @InboundID)
							
				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
				SELECT
					(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
					getDate(), 
					(SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
					@operation,
					@Module,
					CASE WHEN @Module = 13 THEN '''' ELSE ''DISASSOCIATED_CAMP_CALLBACK'' END,
					(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [cam_id] FROM ccInbound WHERE Inbound_id = @InboundID)),
					(SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @InboundID)

				UPDATE ccInbound SET cam_id = null WHERE Inbound_id = @InboundId;
				SELECT 1;
				RETURN 1;
			END;
			IF(@Option = 7) -- Check if the inbound Campaign is related
			BEGIN
				SELECT CAST(ISNULL(cam_id,-1) AS INT) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId;
			END
			IF(@Option = 8) -- Delete the relation between inbound campaings which are related to outdbound campaign
			BEGIN
				UPDATE ccInbound SET cam_id = null WHERE cam_id = @OutboundID;
				SELECT 1;
				RETURN 1;
			END
			IF(@Option = 9)
			BEGIN
				SET @Module = 3 --Corresponds to "Area", reference in ccGalateaModules
				SET @operation = CASE @IsEditing WHEN 1 THEN 138 ELSE 137 END -- Corresponds to edition and creation, reference ccGalateaOperations

				DECLARE @CurrentNonComprehensionId SMALLINT, 
						@CurrentCallbackId SMALLINT, 
						@CurrentSuccessfullTransactionId SMALLINT,
						@UserName VARCHAR(40),
						@AreaName VARCHAR(50),
						@CampaignName VARCHAR(40)

				SELECT @AreaName = AreaName  FROM ccRIACat_Areas WHERE IDArea = @AreaId
				SELECT @UserName = Login FROM ccUsers WHERE User_id = @User_id

				SELECT 
					@CurrentNonComprehensionId = ISNULL( idForNonComprehension , -1 ),
					@CurrentCallbackId = ISNULL( cam_id, -1 ),
					@CurrentSuccessfullTransactionId = ISNULL( idForSuccessfulTransaction, -1),
					@CampaignName = descripcion
				FROM ccInbound WHERE Inbound_id = @InboundId

				IF @CurrentCallbackId <> @CallBackCampaignId AND @CallBackCampaignId <> -1
				BEGIN
					UPDATE ccInbound
					SET cam_id = @CallBackCampaignId
					WHERE Inbound_id = @InboundId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@AreaName, 
							GETDATE(), 
							@UserName, 
							@operation, 
							@Module, 
							''ASSOCIATED_CAMP_CALLBACK'', 
							CASE @CallBackCampaignId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT cam_descripcion FROM ccCamps WHERE cam_id = @CallBackCampaignId) END,
							@CampaignName)
				END

				IF @CurrentNonComprehensionId <> @NonComprehensionId AND @NonComprehensionId <> -1
				BEGIN
					UPDATE ccInbound
					SET idForNonComprehension = @NonComprehensionId
					WHERE Inbound_id = @InboundId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@AreaName, 
							GETDATE(), 
							@UserName, 
							@operation, 
							@Module, 
							''ASSOCIATED_CAMP_XFER_IA'', 
							CASE @NonComprehensionId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT descripcion FROM ccInbound WHERE Inbound_id = @NonComprehensionId) END,
							@CampaignName)
				END

				IF @CurrentSuccessfullTransactionId <> @SuccessfulTransactionCampaignId AND @SuccessfulTransactionCampaignId <> -1
				BEGIN
					UPDATE ccInbound
					SET idForSuccessfulTransaction = @SuccessfulTransactionCampaignId
					WHERE Inbound_id = @InboundId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@AreaName, 
							GETDATE(), 
							@UserName, 
							@operation, 
							@Module, 
							''ASSOCIATED_CAMP_SUCCESSFUL_TRANSACTION'', 
							CASE @SuccessfulTransactionCampaignId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT descripcion FROM ccInbound WHERE Inbound_id = @SuccessfulTransactionCampaignId) END,
							@CampaignName)
				END

				SELECT 1
			END
		END
    '
    EXEC(@sql);



    ----------------------- END Carlos Muñoz -----------------------

	   


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
