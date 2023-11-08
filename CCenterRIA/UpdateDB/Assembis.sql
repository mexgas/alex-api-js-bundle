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
SET @versionfix = 43
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

	
---------------------------------------Begin Jesus Gallardo hotfix/125.20230719.0.10-----------------------------------------------------------
	SET @process = 'DEV1-444 Asembis Alter SP AgentCheckCampsActive se agerga valicacion si es null @idArea';
	SET @sql = 'ALTER PROCEDURE [dbo].[AgentCheckCampsActive]
@cam_id as smallint,
@user_id as smallint,
@forceManualCall as tinyint = 0
AS

declare @isValidCall as int
declare @timeZoneRule as int
declare @idArea as int

select @isValidCall = count(*)from ccCampsAgente with(nolock) where cam_id = @cam_id and user_id = @user_id
select @idArea = IDArea from ccCamps with(nolock) where cam_id = @cam_id
select @timeZoneRule = 0
if @idArea is not NULL
begin
	select @isValidCall = cam_ModoManual, @timeZoneRule = timeZoneRule, @idArea = 1
	from ccCamps with(nolock) where cam_id = @cam_id
	end

	else if @idArea is null
	begin
	select  @isValidCall = cam_ModoManual, @timeZoneRule = timeZoneRule, @idArea = 0
	from ccCamps with(nolock) where cam_id = @cam_id
	end

select @isValidCall as Validation, @timeZoneRule as TimeZoneRule, isnull(@idArea,0) as Active';
	EXEC(@sql);

	SET @process = 'DEV1-444 Asembis Alter SP ccsp_GalateaAdminCampaigns IF @Option = 12 left JOIN ccCampsExtend extended (NOLOCK) ON camps.cam_id = extended.cam_id';
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
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
							ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
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
							CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType
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
					left JOIN ccCampsExtend extended (NOLOCK) ON camps.cam_id = extended.cam_id
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
';
	EXEC(@sql);

	SET @process = 'DEV1-444 Asembis Alter SP ccsp_LoadGraphics se cambia inner a left join ccCampsExtend a4 on (a1.cam_id = a4.cam_id)';
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_LoadGraphics]
@Id as smallint,
@callType as smallint,
@UserId as smallint,
@phone varchar(50)=null
AS
BEGIN
        
    SET NOCOUNT ON  
    DECLARE @realValue int      
    exec @realValue= ccsp_AgentGetStartStopPermission @age_id=@UserId, @cam_id=@Id, @call_type=@callType,@phone=@phone
    
    if (@callType=1)
    begin
        DECLARE @canReprogram bit  
        create table #canReprogram (canReprogram bit)
        insert into #canReprogram
        exec ccsp_AgentGetCampReprogramData @Id, @callType
        select @canReprogram = canReprogram from #canReprogram
        drop table #canReprogram

        select a1.Inbound_id id, a2.descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey, 0 as leaveRecMessage , a2.EditableContactData,
        case when isnull(a4.callsBySurvey,0) > 0 then 1 else 0 end isRelationSurvey ,
        isnull(a2.callBackSurveyAgent,1) callBackSurveyAgent,isnull(a2.callBackSurveyClient,1) callBackSurveyClient,
        a2.ShowCalifWnd as ShowDisposition,
        isnull(a2.startStopRecording,0) as StartStopRecording,
        @realValue as IsStartStopRecording,
        isnull(a2.editableDtmf, 0) as isEditDtmf,
        @canReprogram  CanReprogram
        from ccRIAInboundGraph a1 
        inner join ccInbound a2 on (a1.inbound_id=a2.inbound_id)
         inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id) 
         left join ccCamps a4 on a4.cam_id=a2.cam_id  where a1.inbound_id=@Id and type_id in(1,2,3) order by type_id        
     end    
     else
     begin
        select a1.cam_id Id, a2.cam_descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey,
        case when msgFile <> '''' and leaveRecMessage = 1 then 1 else 0 end as leaveRecMessage, 
        case when isnull(a2.surveyCamId,0) >0 then 1 else 0 end isRelationSurvey ,
        a2.cam_ShowCalifWnd as ShowDisposition,
        a2.callBackSurveyAgent,a2.callBackSurveyClient,
        isnull(a2.startStopRecording,0) as StartStopRecording,
        @realValue as IsStartStopRecording,
        ISNULL( a4.EditableContactData,0) as EditableContactData
        from ccRIACampsGraph a1 
        inner join ccCamps a2 on (a1.cam_id=a2.cam_id)
        inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id)
        left join ccCampsExtend a4 on (a1.cam_id = a4.cam_id)
        left outer join (select top 1 M.cam_id, coalesce(msgFile+'''','''','''') as msgFile 
        from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id 
        where M.cam_id = @Id and type = 8) b 
        on (a2.cam_id = b.cam_id) 
        where a1.cam_id=@Id and type_id in(1,2,3) order by type_id
     end    
END
	';
	EXEC(@sql);

	SET @process = 'DEV1-444 Asembis Alter SP ccsp_RIAACDCallParams se cambia para dar un valor fijo @RecordCalls';
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAACDCallParams]
@option int,
@campId int = 0
AS
BEGIN
	SET NOCOUNT ON;
declare @RecordCalls tinyint
set @RecordCalls=0
if(@option = 1)
begin
	select @RecordCalls= RecordCalls from ccInboundExtend where Inbound_id = @campId				
end

else if(@option = 2)
begin
	select @RecordCalls= RecordCalls from ccCampsExtend where cam_id = @campId				
end
select @RecordCalls RecordCalls

	SET NOCOUNT OFF;
END';
	EXEC(@sql);


	SET @process = 'DEV1-444 Asembis Alter SP ccspAgent_GetLastCalls tabla temporal @lastCallAgt se cambia PRIMARY KEY(id,tipo) por que se puede repetir';
	SET @sql = 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
AS
SET NOCOUNT ON;
DECLARE @lastCallAgt TABLE(id           INT NOT NULL
						, tipo         VARCHAR(10) NOT NULL
						, Hora         DATETIME NOT NULL --VARCHAR(19) NOT NULL, 
						, Telefono     VARCHAR(55) NOT NULL
						, EspCamp      VARCHAR(55) NOT NULL
                        , Calificacion VARCHAR(150)
						, Duracion     VARCHAR(10) NOT NULL
						, CallBack     DATETIME
						, cal_key      VARCHAR(40)
						, IDCampEsp    SMALLINT NOT NULL
						, prefijo      VARCHAR(255) NULL
						, GraphicID    INT
						, CamManualMode INT
						, SelectRotativeANI INT
						, PRIMARY KEY(id,tipo)
);

DECLARE @pais TINYINT;
DECLARE @maxHours SMALLINT;
DECLARE @topRows INT;
DECLARE @setting VARCHAR(6);
DECLARE @hidePhone BIT;
DECLARE @dateStart DATETIME;

SET @hidePhone = 1;

SELECT @setting = valor FROM ccSettings WHERE setting_id = 255;

SET @maxHours = CAST(SUBSTRING(@setting, 1, (SELECT PATINDEX(''%|%'', @setting)) - 1) AS SMALLINT);
SET @topRows = CAST(SUBSTRING(@setting, (SELECT PATINDEX(''%|%'', @setting)) + 1, LEN(@setting)) AS INT);

IF @maxHours = 0
BEGIN
	SELECT Id
		, tipo
		, (CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) AS Hora
		, Telefono
		, EspCamp
		, Calificacion
		, CallBack
		, Duracion
		, '''' AS CallBack
		, cal_key
		, IDCampEsp
		, prefijo
		, GraphicID
		, SelectRotativeANI
		, @hidePhone AS HidePhone FROM @lastCallAgt;

	RETURN 0;
END;

SELECT @pais = valor FROM ccSettings WHERE setting_id = 104;

SELECT @hidePhone = CASE WHEN valor = ''0''
					THEN 0 ELSE 1
					END FROM ccSettings WHERE setting_id = 223;

IF @topRows = 0
BEGIN
	SET @topRows = 10000;
END;

SET @dateStart = DATEADD(hh, -@maxHours, GETDATE());

WITH timeTransfer
	AS (SELECT cal_id
			, tipo
			, SUM(tAntesXfer) AS tAntesXfer
			, SUM(tDespuesXfer) AS tDespuesXfer FROM ccLogTransfers
		WHERE fechaFin > @dateStart
		GROUP BY cal_id
				, tipo)

	INSERT INTO @lastCallAgt
			---Insert OUT
			SELECT TOP (@topRows) c.cal_id AS id
								, ''OUT'' AS Tipo
								, cal_inicio
								, cal_telefono AS Telefono
								, cam_descripcion AS EspCamp
								, ISNULL(cal.Description, '''') AS Calificacion
								, CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
																						THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
																						END, 0), 114) AS Duracion
								, cal_fcallback AS CallBack
								, cal_key
								, c.cam_id AS IDCampEsp
								, ISNULL(ccCamps.prefijo, '''') Prefijo
								, graph.graphic_id GraphicID
								, cam_ModoManual as CamManualMode 
								, ISNULL(selectRotativeANI, 0) as SelectRotativeANI FROM ccoCallsOut c
																INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
																LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
																LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
																LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
																							AND t.tipo = 2
			WHERE user_id = @user_id
				AND cal_inicio > @dateStart
			UNION
			--- IN
			SELECT TOP (@topRows) c.cal_id AS id
								, ''IN'' AS Tipo
								, cal_inicio
								, cal_ani AS Telefono
								, descripcion AS EspCamp
								, ISNULL(cal.Description, '''') AS Calificacion
								, CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
																								THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
																								END, 0), 108) Duracion
								, NULL AS CallBack
								, cal_key
								, c.inbound_id AS IDCampEsp
								, ISNULL(ccInbound.prefijo, '''') Prefijo
								, graph.graphic_id GraphicID
								, '''' as CamManualMode 
								, 0 as SelectRotativeANI FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
																JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
																INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
																LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
																LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
																							AND t.tipo = 1
			WHERE user_id = @user_id
				AND cal_inicio > @dateStart;

SELECT Id
	, tipo
	, CASE WHEN @pais = 4
	THEN(CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) ELSE(CONVERT(VARCHAR(10), Hora, 103) + '' '' + CONVERT(VARCHAR(8), Hora, 14))
	END AS Hora
	, Telefono
	, EspCamp
	, Calificacion
	, ISNULL(CONVERT(VARCHAR(16), CallBack, 121), '''') AS CallBack
	, Duracion
	, CallBack
	, cal_key
	, IDCampEsp
	, prefijo
	, GraphicID
	, @hidePhone AS HidePhone 
	, CamManualMode 
	, SelectRotativeANI FROM @lastCallAgt
ORDER BY hora DESC;
SET NOCOUNT OFF;
		';
	EXEC(@sql);


	---------------------------------------End Jesus Gallardo hotfix/125.20230719.0.10-----------------------------------------------------------

	/* End script release */
	/* Upgrade database version (first and the last number of setting 77) */
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