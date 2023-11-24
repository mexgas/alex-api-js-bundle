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
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 45
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

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

	-----------------------------------------------------BEGIN JCL ----------------------------------------------------------------
	SET @process = 'KR105000 agregar columna ToolsTransfer'
	SET @sql = 'if not exists (select * from sys.columns where name = N''ToolsTransfer'' and Object_ID = Object_ID(N''ccRIACat_Areas''))
		begin
			alter table ccRIACat_Areas add ToolsTransfer bit not null default 0
		end'
	EXEC(@sql);

	SET @process = 'KR105000 agregar columna ToolsTransfer en cosultas de campañas in/out'
	SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
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
							RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
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
							RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
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
							CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
							isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
							camps.cam_procesando IsStarted, 
							ISNULL(a.AreaName, '''') AS Area, 
							CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
							CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
							ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
							ToolsTransfer
							FROM ccCamps camps
							LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
							LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
							LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
							WHERE camps.cam_id = @Id
							ORDER BY camps.cam_descripcion ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
					END;
			END;
			IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
							CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, 
							ISNULL(a.AreaName, '''') AS Area, 
							CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType,
							ToolsTransfer
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
					RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
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
					RAISERROR(''ERROR. La campañas o administrador no existen'', 18, 1);
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
					RAISERROR(''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
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
					RAISERROR(''ERROR. No existe una campaña con el id especificado'', 18, 1);
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
	DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY(id));
	DECLARE @AgentsList TABLE(id INT, PRIMARY KEY(id));
	DECLARE @tmpCamAgent TABLE(camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY(camId, userId));
	DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT );
	DECLARE @CurrentStatus TABLE(userId INT, CurrentState INT, IdCampEsp INT, camType INT);
	DECLARE @campDataTotal TABLE(camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY(camId));

	INSERT INTO @AdminWorkgroups SELECT DISTINCT IDWG
	FROM ccRIAWorkGroupUsers WG, 
		ccUsers_Roles R
	WHERE WG.User_id = @AdminId
	OR (R.User_id = @AdminId
	AND R.Rol_id = 7);
					        
	INSERT INTO @AgentsList SELECT DISTINCT A.User_id
	FROM ccRIAWorkGroupUsers A
	INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
	INNER JOIN ccUsers C ON A.User_id = C.User_id 
	AND C.TipoUser_id = 1
	ORDER BY A.User_id;

					INSERT INTO @tmpCamAgent SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id,
	CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
	FROM ccRIACampEspWG campPerWg
	INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
	INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
	INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
	left JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp and @CampType = 0
	left JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp and @CampType = 1
	where C.TipoUser_id = 1
	AND campPerWg.Tipo = @CampType
	AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
					  
	;WITH lastState AS (
	SELECT A.user_id, MAX(A.fecha) AS fecha
	FROM ccLogAgentesDia A
	INNER JOIN @AgentsList B ON A.User_id = B.id
	WHERE fecha >= @date
	GROUP BY user_id)

	INSERT INTO @CurrentStatus 
	SELECT B.User_id,
	CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS currentStatus,
	B.IdCampEsp,
	B.Tipo
	FROM lastState A
	INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
	AND A.fecha = B.fecha;

	IF @Id = 0 AND @CampType = 0 
	BEGIN
	DELETE FROM @tmpCamAgent WHERE multimediaType = 5
	END

	DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;
	IF @CampType = 1 BEGIN
	SELECT @MultimediaType = meanContactTypeId FROM contactMeanOut WHERE camp_id = @Id
	END
	ELSE BEGIN
		SELECT @chatType = ci.chat FROM dbo.ccInbound AS ci WHERE ci.Inbound_id = @Id;
		SELECT @MultimediaType = meanContactTypeId FROM contactMeanIn WHERE inboundId = @Id
	END 

	IF(@chatType = 1)
	BEGIN
		SET @MultimediaType = 1
	END
			
	DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN ''23'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes
			
	INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
	(CASE 
		WHEN @chatType = 1 THEN 
		CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'',''))  THEN @CampType 
		ELSE 
		CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN @CampType 
		ELSE null 
		END END END) AS isCampDialog, B.camType
	FROM @tmpCamAgent A
	INNER JOIN @CurrentStatus B ON A.userId = B.userId
	WHERE (@Id = 0 or A.camId = @Id)

	IF @CampType = 1
	BEGIN
	;with  campDataTotal as(
		select camId,count(*) total from @tmpCamAgent A group by camId
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
	END
	ELSE
	BEGIN    
	;with  campDataTotal as(
		select camId,count(*) total from @tmpCamAgent A group by camId
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
	END

	;WITH stateCamp AS(
	SELECT A.CampId,
	count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
	count(CASE WHEN A.CurrentState NOT IN(-2, -1, 0, 3, 4, 5, 6, 9, 30, 34) THEN 1 
			WHEN A.CurrentState IN (6, 34, 4) AND (A.CampId != C.IdCampEsp OR A.campType != @CampType) THEN 1 ELSE NULL END) AS notReady,
	COUNT(isCampDialog) AS dialog, 
	COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected 
	FROM @AgentStatus A
	INNER JOIN @CurrentStatus C ON A.userId = C.userId
	GROUP BY A.CampId
	)

	SELECT 
	A.camId,
	A.campName,
	A.Total,
		ISNULL(B.ready, 0) AS Ready,
	ISNULL(B.notReady, 0 ) AS NotReady, 
	ISNULL(B.dialog, 0) AS Dialog,
	CASE WHEN B.disconnected IS NULL THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END Disconnected,
	A.Area
	FROM @campDataTotal A
	LEFT JOIN stateCamp B ON A.camId = B.CampId
	ORDER BY A.campName

		RETURN 0;
	END;
	IF @Option = 11  -- Get Campaigns Ids List Per Workgroup and Campaign Type
		BEGIN                
			IF Not EXISTS
			(
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
						AND Rol_id = 7
			)
				BEGIN
		print ''xxxx SIn Super''
					;WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS Id
							FROM ccRIACampEspWG A (NOLOCK)
								INNER JOIN wgId ON wgId.IDWG = A.IDWG
													AND A.Tipo = @CampType;
			END;
			ELSE
				BEGIN
		--print ''xxxx Super''
		IF @CampType = 1
		BEGIN
			SELECT DISTINCT 
				CAST(cam_id AS INT) AS Id
						FROM ccCamps (NOLOCK) where IDArea IS NOT NULL
		END
		ELSE
		BEGIN 
			SELECT DISTINCT 
				CAST(Inbound_id AS INT) AS Id
						FROM ccInbound (NOLOCK) where IDArea IS NOT NULL
		END
			END;
			RETURN 0;
	END;
	IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
		BEGIN
			IF @CampType = 1 -- Campaigns Out
				BEGIN
					SELECT DISTINCT 
					CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
					isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
					camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
					CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
					ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
					FROM ccCamps camps (NOLOCK)
					INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
					INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
					INNER JOIN ccCampsExtend extended (NOLOCK) ON camps.cam_id = extended.cam_id
					--WHERE camps.cam_id = @Id
					ORDER BY camps.cam_descripcion ASC;
			END;
			ELSE
				BEGIN
					SELECT DISTINCT 
											CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId, inb.chat AS InboundType, 0 as OutboundType
					FROM ccInbound inb (NOLOCK)
							INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
							INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = inb.IDArea
							ORDER BY inb.descripcion ASC;
			END;
			RETURN 0;
	END;
	IF @Option = 13
	BEGIN
		BEGIN                
			IF NOT EXISTS
			(
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
						AND Rol_id = 7
			)
				BEGIN
					IF @CampType = 1
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,CAST(-1 AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 1
									INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id;
						END
					ELSE
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A (NOLOCK)
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 0
									INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id 
									AND ((@multi_type is null AND cci.chat = @InboundType)
										OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
						END
			END;
			ELSE
				BEGIN
				IF @CampType = 1
					BEGIN
						SELECT DISTINCT 
								CAST(cam_id AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,-1 AS RelatedCampId
						FROM ccCamps NOLOCK where IDArea = @AreaId
					END
				ELSE
					BEGIN 
						SELECT DISTINCT 
								CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
						FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
						AND ((@multi_type is null AND cci.chat = @InboundType)
							OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

					END
			END;
			RETURN 0;
		END;
	END;

	IF @Option = 14
		BEGIN
			IF NOT EXISTS
			(
					SELECT *
					FROM ccUsers_Roles NOLOCK
					WHERE User_id = @AdminId
							AND Rol_id = 7
			)
				BEGIN
					WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
							FROM ccRIACampEspWG A (NOLOCK)
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
	IF @Option = 15
		BEGIN
			SELECT DISTINCT 
			CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
			FROM ccInbound NOLOCK where cam_id = @Id
		END
END;
	
	'
	EXEC(@sql);	

	SET @process = 'KR105000 modificar SP para insercion'
	SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
@option smallint,
@IDArea smallint,
@Descripcion varchar(40),
@maxMails smallint = 3, 
@maxChats smallint = 3,
@maxTweets smallint = 3,
@defCampaing smallint = NULL, 
@isKolob bit = 0,
@toolsTransfer bit = 0
AS

set nocount on



if @option = 1 begin --Selected Area
 Select a.IDArea, AreaName, isnull(a.maxChats,0) as maxChats, isnull(maxMails,3) maxMails,
 isnull(users,0) users, isnull(admins,0) admins,
 isnull(camps,0) camps, isnull(acds,0) acds  ,isnull(a.maxTweets,3) as maxTweets
 from ccRIACat_Areas a (nolock)
 left join (select IDArea , MAX(isnull(maxChats,0)) as maxChats from ccInbound GROUP BY IDArea) b on a.IDArea = b.IDArea
 left join (select IDArea,count(case when TipoUser_id = 1 AND (@isKolob = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= 60)  then 1 else null end) users, count(case when TipoUser_id > 1 AND (@isKolob = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= 60) then 1 else null end) admins from ccusers (nolock) where isnull(IDArea,0)=case isnull(0,0) when 0 then isnull(IDArea,0) else 0 end group by IDArea) userswg on userswg.IDArea=a.IDArea
 left join (select IDArea,count(*) acds from ccinbound (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) acdswg on acdswg.IDArea=a.IDArea
 left join (select IDArea,count(*) camps from cccamps (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) campswg on campswg.IDArea=a.IDArea
 where StatusArea=1 and isnull(a.IDArea,0)=case isnull(@IDArea,0)
 when 0 then isnull(a.IDArea,0) else @IDArea end
 order by AreaName
 return(0)
end
else if @option=2 begin --Insert Area
	 if exists(select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion) begin
	  select -1 as result,-1 as idAreas--, Nombre en Uso
	  return(0)
	 end
	Insert into ccRIACat_Areas (AreaName,maxMails,maxChats,maxTweets,defCampaing,CreateDate,ToolsTransfer) values (@Descripcion,@maxMails,@maxChats,@maxTweets,@defCampaing,Getdate(),@toolsTransfer)
	select 1 as result, scope_identity() as idAreas--, Area Insertada
	return(0)
end
else if @option=3 begin--Update Area
	if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
		Update ccRIACat_Areas set AreaName=@Descripcion,maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,defCampaing=@defCampaing where IDArea=@IDArea
	else
		Update ccRIACat_Areas set maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,defCampaing=@defCampaing where IDArea=@IDArea

	if (select max(maxChats) as maxChats from ccinbound where IDArea=@IDArea) <> @maxChats
		Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
 return(0)
end

else if @option=4 begin --Delete Area
 if (exists(select IDArea from ccUsers where IDArea=@IDArea) or exists(select IDArea from ccCamps where IDArea = @IDArea)
  or exists(select IDArea from ccInbound where IDArea=@IDArea)) and (select valor from ccSettings where setting_id=95)<>1
 begin
  select -1
  return(0)
 end

	declare @DWorkGroups as varchar(500)

	 insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
	 select user_id,cam_id,prioridad,skill,rel_id,IDWG
	 from ccCampsAgente
	 where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
	 select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
	 from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
	 Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
	 select user_id,cam_id,tipo,IDWG,monitored
	 from ccSupervisorCam
	 where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
	 delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
	 delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
	 where cam_id in (select cam_id from ccCamps where IDArea=@IDArea))

	 Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)
	 Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)

	 Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
	 Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
	 Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)

	 select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea=@IDArea
	 Delete from ccRIAAreaWorkGroup where IDArea=@IDArea

	 if (select valor from ccSettings where setting_id=95)=1
	 begin
	  Update ccInbound set IDArea=NULL, status=0 where IDArea=@IDArea
	  Update ccCamps set IDArea=NULL where IDArea=@IDArea
	  Update ccUsers set IDArea=NULL where IDArea=@IDArea
	 end

	 Update ccRIACat_Areas set StatusArea=0 where IDArea=@IDArea

	 select @DWorkGroups

 return(0)
end
else if @option=5 begin -- Select Areas Campaings and show its default Campaing 
	select A.IDArea as IDArea, C.cam_id as campID, C.cam_descripcion as campName,
	case when A.defCampaing=C.cam_id then 1 else 0 end as isDefault
	from ccRIACat_Areas A (nolock)
	inner join ccCamps C on A.IDArea=C.IDArea
	order by IDArea asc, isDefault desc, campName
	return(0)
 end    
    '
	EXEC(@sql);       

	SET @process = 'KR105000 insertar y modificar setting transferencia'
	SET @sql = '
ALTER procedure [dbo].[ccsp_GalateaAreas] 
    @option int = 2,
    @IDArea smallint = 0,
    @Descripcion varchar(40) = NULL,
    @maxMails smallint = 3,
    @maxChats smallint = 3,
    @maxTweets smallint = 3,
    @defCampaing smallint = 0,
    @movesfromArea bit = 0,
    @userId int = NULL,
    @groupAreas varchar (MAX) = NULL,
	@toolsTransfer bit = 0
AS

SET NOCOUNT ON;
    
    declare @opt int = @option -1
    
    DECLARE @userLogin as varchar(40);
    SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @userId);

    if @option = 1 --Superuser info
    begin
        create table #campsIds(
            id int,
            cadena varchar(max)
        )
            
        declare @sql varchar(max),@idPivots varchar(max),@idConcat varchar(max)
            
        set @idPivots =''''
        set @idConcat=''''
            
        select @idPivots=@idPivots+Id+'','',
            @idConcat=@idConcat+''case when ''+id+'' is not null then convert(varchar(max),''+ id+'') + '''','''' else '''''''' end + 
            ''
            from (
            select distinct ''[''+convert(varchar(max),cam_id)+'']'' as Id from ccCamps   
            )x
            
        set @idPivots =SUBSTRING(@idPivots,0,len(@idPivots))
        set @idConcat =SUBSTRING(@idConcat,0,len(@idConcat)-7)
            
        set @sql=''
            select IDArea,''+@idConcat+'' from 
            (   select IDArea, cam_id from ccCamps) as T
            PIVOT (
            max(cam_id) for cam_id in (''+@idPivots+'') ) as P''

        insert into #campsIds
        exec(@sql)
            
        select a.IDArea Id, 
            a.AreaName Name, 
            a.StatusArea Status, 
            a.maxMails Mails, 
            a.maxChats Chats, 
            a.maxTweets Tweets, 
            a.CreateDate as CreateDate,         
            ISNULL(b.cadena, 0) as CampaignIds  
        from ccRIACat_Areas a --Falta el datetime 
        left join #campsIds b on a.IDArea = b.id

        drop table #campsIds
    end
    if @option = 2 -- Select de las areas
    begin
        IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
        Create table #Areas(
            IDArea smallint,
            AreaName varchar(MAX),
            maxChats tinyint ,
            maxMails tinyint ,
            users int,
            admins int,
            camps int,
            acds int,
            maxTweets tinyint
        )
        insert into #Areas
        EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@defCampaing=@defCampaing, @isKolob=1
        select a.*,rca.CreateDate,Isnull(rca.defCampaing,0) as defCampaing
        from #Areas a
        inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea
    end
    if @option = 3 -- Insert new area
    begin
    IF OBJECT_ID(''tempdb..#InsertAreas'') IS NOT NULL DROP TABLE #InsertAreas;
        Create table #InsertAreas(
            result int,
            idAreas decimal
        )
        insert into #InsertAreas
        EXEC ccsp_RIA_ABCAreas 
            @option = @opt,
            @IDArea=@IDArea,
            @Descripcion=@Descripcion,
            @maxMails=@maxMails,
            @maxChats=@maxChats,
            @maxTweets=@maxTweets,
            @defCampaing=@defCampaing,
			@toolsTransfer=@toolsTransfer
        if (select result from #InsertAreas) = 1
            begin

                --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD AL CREAR UN AREA
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@Descripcion, getDate(), @userLogin, 17, 3, '''', '''', @Descripcion);

                if(@movesfromArea = 1) begin
                    Update ccUsers set IDArea = (select idAreas from #InsertAreas), status = 1 where User_id = @userId
                end
            end
        Select * from #InsertAreas
    end
    if @option = 4 -- Delete Areas
    begin
        IF OBJECT_ID(''tempdb..#AreasDelete'') IS NOT NULL DROP TABLE #AreasDelete;
        SELECT value As IDArea into #AreasDelete FROM fn_RIASplitDelimited(@groupAreas, '','')
        
        
        if (exists(select IDArea from ccUsers where IDArea=(Select top 1 IDArea from #AreasDelete)) or exists(select IDArea from ccCamps where IDArea = (Select top 1 IDArea from #AreasDelete))
          or exists(select IDArea from ccInbound where IDArea=(Select top 1 IDArea from #AreasDelete))) and (select valor from ccSettings where setting_id=95)<>1
        BEGIN
            Select -1 as result
        END
        ELSE
        BEGIN
            declare @DWorkGroups as varchar(500)
            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
            select user_id,cam_id,prioridad,skill,rel_id,IDWG
            from ccCampsAgente
            where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
            select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
            from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))
            Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
            select user_id,cam_id,tipo,IDWG,monitored
            from ccSupervisorCam
            where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
            delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
            delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
            where cam_id in (select cam_id from ccCamps where IDArea in (Select IDArea from #AreasDelete)))

            Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))
            Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))

            Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
            Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
            Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))

            select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)
            Delete from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)

            if (select valor from ccSettings where setting_id=95)=1
            begin
            Update ccInbound set IDArea=NULL, status=0 where IDArea in (Select IDArea from #AreasDelete)
            Update ccCamps set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
            Update ccUsers set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
            end

            Update ccRIACat_Areas set StatusArea=0 where IDArea in (Select IDArea from #AreasDelete)

            --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA AREA ELIMINADA
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT AreaName, getDate(), @userLogin, 19, 3, '''', '''', AreaName
            FROM ccRIACat_Areas 
            WHERE IDArea in (Select IDArea from #AreasDelete);

            select 1 as result
        END
    end
    if @option = 5 -- update Areas
    begin
        if exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion and IDArea <> @IDArea)
            begin
                select -1 as result
                return
            end
        else
            begin

                --INICIO - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

                DECLARE @PrevDescription AS VARCHAR(50);
                DECLARE @SelectedArea AS VARCHAR(10) = CAST(@IDArea AS varchar(10));

                SELECT @PrevDescription = AreaName
                FROM ccRIACat_Areas 
                WHERE IDArea = @IDArea;

                EXEC InsertLogAdminGalatea @action=1, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                DECLARE @AreasTable TABLE 
                (
                    columnInfo VARCHAR(255),
                    dataInfo VARCHAR(255),
                    identifierInfo VARCHAR(255)
                )

                update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=isnull(@toolsTransfer, 0) where IDArea=@IDArea

                INSERT INTO @AreasTable EXEC InsertLogAdminGalatea @action=2, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId;

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT 
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                    ELSE '''' END,
                    getDate(), 
                    @userLogin, 
                    18, 
                    3, 
                    AT.identifierInfo,
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @Descripcion
                            WHEN AT.identifierInfo = ''T&SET_CAMPAIGN'' THEN 
                                CASE 
                                    WHEN @defCampaing IS NOT NULL AND @defCampaing <> 0 THEN
                                        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @defCampaing)
                                    ELSE ''T&COMMON_NONE'' END
                            ELSE AT.dataInfo END
                    ELSE '''' END, 
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                    ELSE '''' END
                FROM @AreasTable AS AT;

                EXEC InsertLogAdminGalatea @action=3, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                --FIN - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

            end
        if @maxChats is not null
            begin
                Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
            end
        if @movesfromArea = 1
        Begin
            Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @userId
        End
        select 1 as result
    end
SET NOCOUNT ON;
    '
	EXEC(@sql);

	SET @process = 'KR105000 se agrega columna toolsTransfer a consulta'
	SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
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
							RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
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
							RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
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
							CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
							isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
							camps.cam_procesando IsStarted, 
							ISNULL(a.AreaName, '''') AS Area, 
							CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
							CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
							ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
							ToolsTransfer
							FROM ccCamps camps
							LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
							LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
							LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
							WHERE camps.cam_id = @Id
							ORDER BY camps.cam_descripcion ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
					END;
			END;
			IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
							CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, 
							ISNULL(a.AreaName, '''') AS Area, 
							CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType,
							ToolsTransfer
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
					RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
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
					RAISERROR(''ERROR. La campañas o administrador no existen'', 18, 1);
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
					RAISERROR(''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
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
					RAISERROR(''ERROR. No existe una campaña con el id especificado'', 18, 1);
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
	DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY(id));
	DECLARE @AgentsList TABLE(id INT, PRIMARY KEY(id));
	DECLARE @tmpCamAgent TABLE(camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY(camId, userId));
	DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT );
	DECLARE @CurrentStatus TABLE(userId INT, CurrentState INT, IdCampEsp INT, camType INT);
	DECLARE @campDataTotal TABLE(camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY(camId));

	INSERT INTO @AdminWorkgroups SELECT DISTINCT IDWG
	FROM ccRIAWorkGroupUsers WG, 
		ccUsers_Roles R
	WHERE WG.User_id = @AdminId
	OR (R.User_id = @AdminId
	AND R.Rol_id = 7);
					        
	INSERT INTO @AgentsList SELECT DISTINCT A.User_id
	FROM ccRIAWorkGroupUsers A
	INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
	INNER JOIN ccUsers C ON A.User_id = C.User_id 
	AND C.TipoUser_id = 1
	ORDER BY A.User_id;

					INSERT INTO @tmpCamAgent SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id,
	CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
	FROM ccRIACampEspWG campPerWg
	INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
	INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
	INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
	left JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp and @CampType = 0
	left JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp and @CampType = 1
	where C.TipoUser_id = 1
	AND campPerWg.Tipo = @CampType
	AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
					  
	;WITH lastState AS (
	SELECT A.user_id, MAX(A.fecha) AS fecha
	FROM ccLogAgentesDia A
	INNER JOIN @AgentsList B ON A.User_id = B.id
	WHERE fecha >= @date
	GROUP BY user_id)

	INSERT INTO @CurrentStatus 
	SELECT B.User_id,
	CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS currentStatus,
	B.IdCampEsp,
	B.Tipo
	FROM lastState A
	INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
	AND A.fecha = B.fecha;

	IF @Id = 0 AND @CampType = 0 
	BEGIN
	DELETE FROM @tmpCamAgent WHERE multimediaType = 5
	END

	DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;
	IF @CampType = 1 BEGIN
	SELECT @MultimediaType = meanContactTypeId FROM contactMeanOut WHERE camp_id = @Id
	END
	ELSE BEGIN
		SELECT @chatType = ci.chat FROM dbo.ccInbound AS ci WHERE ci.Inbound_id = @Id;
		SELECT @MultimediaType = meanContactTypeId FROM contactMeanIn WHERE inboundId = @Id
	END 

	IF(@chatType = 1)
	BEGIN
		SET @MultimediaType = 1
	END
			
	DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN ''23'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes
			
	INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
	(CASE 
		WHEN @chatType = 1 THEN 
		CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'',''))  THEN @CampType 
		ELSE 
		CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN @CampType 
		ELSE null 
		END END END) AS isCampDialog, B.camType
	FROM @tmpCamAgent A
	INNER JOIN @CurrentStatus B ON A.userId = B.userId
	WHERE (@Id = 0 or A.camId = @Id)

	IF @CampType = 1
	BEGIN
	;with  campDataTotal as(
		select camId,count(*) total from @tmpCamAgent A group by camId
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
	END
	ELSE
	BEGIN    
	;with  campDataTotal as(
		select camId,count(*) total from @tmpCamAgent A group by camId
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
	END

	;WITH stateCamp AS(
	SELECT A.CampId,
	count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
	count(CASE WHEN A.CurrentState NOT IN(-2, -1, 0, 3, 4, 5, 6, 9, 30, 34) THEN 1 
			WHEN A.CurrentState IN (6, 34, 4) AND (A.CampId != C.IdCampEsp OR A.campType != @CampType) THEN 1 ELSE NULL END) AS notReady,
	COUNT(isCampDialog) AS dialog, 
	COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected 
	FROM @AgentStatus A
	INNER JOIN @CurrentStatus C ON A.userId = C.userId
	GROUP BY A.CampId
	)

	SELECT 
	A.camId,
	A.campName,
	A.Total,
		ISNULL(B.ready, 0) AS Ready,
	ISNULL(B.notReady, 0 ) AS NotReady, 
	ISNULL(B.dialog, 0) AS Dialog,
	CASE WHEN B.disconnected IS NULL THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END Disconnected,
	A.Area
	FROM @campDataTotal A
	LEFT JOIN stateCamp B ON A.camId = B.CampId
	ORDER BY A.campName

		RETURN 0;
	END;
	IF @Option = 11  -- Get Campaigns Ids List Per Workgroup and Campaign Type
		BEGIN                
			IF Not EXISTS
			(
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
						AND Rol_id = 7
			)
				BEGIN
		print ''xxxx SIn Super''
					;WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS Id
							FROM ccRIACampEspWG A (NOLOCK)
								INNER JOIN wgId ON wgId.IDWG = A.IDWG
													AND A.Tipo = @CampType;
			END;
			ELSE
				BEGIN
		--print ''xxxx Super''
		IF @CampType = 1
		BEGIN
			SELECT DISTINCT 
				CAST(cam_id AS INT) AS Id
						FROM ccCamps (NOLOCK) where IDArea IS NOT NULL
		END
		ELSE
		BEGIN 
			SELECT DISTINCT 
				CAST(Inbound_id AS INT) AS Id
						FROM ccInbound (NOLOCK) where IDArea IS NOT NULL
		END
			END;
			RETURN 0;
	END;
	IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
		BEGIN
			IF @CampType = 1 -- Campaigns Out
				BEGIN
					SELECT DISTINCT 
					CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
					isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
					camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
					CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
					ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
					FROM ccCamps camps (NOLOCK)
					INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
					INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
					INNER JOIN ccCampsExtend extended (NOLOCK) ON camps.cam_id = extended.cam_id
					--WHERE camps.cam_id = @Id
					ORDER BY camps.cam_descripcion ASC;
			END;
			ELSE
				BEGIN
					SELECT DISTINCT 
											CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId, inb.chat AS InboundType, 0 as OutboundType
					FROM ccInbound inb (NOLOCK)
							INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
							INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = inb.IDArea
							ORDER BY inb.descripcion ASC;
			END;
			RETURN 0;
	END;
	IF @Option = 13
	BEGIN
		BEGIN                
			IF NOT EXISTS
			(
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
						AND Rol_id = 7
			)
				BEGIN
					IF @CampType = 1
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,CAST(-1 AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 1
									INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id;
						END
					ELSE
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A (NOLOCK)
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 0
									INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id 
									AND ((@multi_type is null AND cci.chat = @InboundType)
										OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
						END
			END;
			ELSE
				BEGIN
				IF @CampType = 1
					BEGIN
						SELECT DISTINCT 
								CAST(cam_id AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,-1 AS RelatedCampId
						FROM ccCamps NOLOCK where IDArea = @AreaId
					END
				ELSE
					BEGIN 
						SELECT DISTINCT 
								CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
						FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
						AND ((@multi_type is null AND cci.chat = @InboundType)
							OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

					END
			END;
			RETURN 0;
		END;
	END;

	IF @Option = 14
		BEGIN
			IF NOT EXISTS
			(
					SELECT *
					FROM ccUsers_Roles NOLOCK
					WHERE User_id = @AdminId
							AND Rol_id = 7
			)
				BEGIN
					WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
							FROM ccRIACampEspWG A (NOLOCK)
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
	IF @Option = 15
		BEGIN
			SELECT DISTINCT 
			CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
			FROM ccInbound NOLOCK where cam_id = @Id
		END
END;
    '
	EXEC(@sql);

	-----------------------------------------------------END JCL ----------------------------------------------------------------



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
