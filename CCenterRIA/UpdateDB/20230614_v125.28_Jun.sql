/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @versionfix = 28
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
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

	------------------------------------------ Begin Rod Salazar ------------------------------------------------------

	
SET @process = 'K054000 Insert module Unavailable options by campaign in ccGalateaModules'
SET @sql = '
	IF not exists (select * from ccGalateaModules where ModuleId = 8)
	BEGIN
		insert into ccGalateaModules(ModuleId, MTagEs, MTagEn, MTagPt) values (8, ''Estados de No disponible por campaña'', ''Unavailable options by campaign'', ''Tipos de Não disponível por campanha'')
	END
'
EXEC(@sql)

SET @process = 'K054000 Insert operation Assign unavailable option in ccGalateaOperations'
SET @sql = '
	IF not exists (select * from ccGalateaOperations where OperationId = 70)
	BEGIN
		insert into ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt) values (70, ''Asignar estado No disponible'', ''Assign unavailable option'', ''Atribuir tipo de Não disponível'')
	END
'
EXEC(@sql)

SET @process = 'K054000 Insert operation Unassign unavailable option in ccGalateaOperations'
SET @sql = '
	IF not exists (select * from ccGalateaOperations where OperationId = 71)
	BEGIN
		insert into ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt) values (71, ''Desasignar estado No disponible'', ''Unassign unavailable option'', ''Cancelar atribuição de tipo de Não disponível'') 
	END
'
EXEC(@sql)

SET @process = 'K054000 Insert relation moduleId = 8, OperationId = 70 in ccGalateaModOpRelation'
SET @sql = '
	IF not exists (select * from ccGalateaModOpRelation where moduleId = 8 and OperationId = 70)
	BEGIN
		insert into ccGalateaModOpRelation values (8, 70)
	END
'
EXEC(@sql)

SET @process = 'K054000 Insert relation moduleId = 8, OperationId = 71 in ccGalateaModOpRelation'
SET @sql = '
	IF not exists (select * from ccGalateaModOpRelation where moduleId = 8 and OperationId = 71)
	BEGIN
		insert into ccGalateaModOpRelation values (8, 71)
	END
'
EXEC(@sql)

SET @process = 'K054000 Drop procedure ccsp_GalateaUnavailableByCamp'
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaUnavailableByCamp'')
	BEGIN
		DROP PROCEDURE ccsp_GalateaUnavailableByCamp
	END
'
EXEC(@sql)

SET @process = 'K054000 Create procedure ccsp_GalateaUnavailableByCamp '
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_GalateaUnavailableByCamp]
	@action int,
	@cam_id int = null,
	@type int = null,
	@nd_ids varchar(max) = null,
	@nd_id int = null

	AS
	SET NOCOUNT ON

	IF @action = 1
	BEGIN
		if (@type = 0)
		begin
			select TipoNotReady_id from ccUnavailableRelation
			left outer join ccTipoNotReady on (idUnavailable = TipoNotReady_id)
			left outer join ccInbound on (idCampACD = inbound_id)
			where type = @type
			and idCampACD = @cam_id
		end

		else
		begin
			select TipoNotReady_id from ccUnavailableRelation
			left outer join ccTipoNotReady on (idUnavailable = TipoNotReady_id)
			left outer join ccCamps on (idCampACD = cam_id)
			where type = @type
			and idCampACD = @cam_id
		end
	END

	ELSE IF @action = 2
	BEGIN

		if not exists( select TipoNotReady_id from ccTipoNotReady where TipoNotReady_id in (select value from dbo.fn_RIASplitDelimited(@nd_ids, '','')) and StatusTipoNotReady = 1)
		begin 
			select CAST(-3 AS INT) --, ND ids not exist
			return(0)
		end

		if not exists (select * from ccUnavailableRelation where @cam_id = idCampACD and @type = type and idUnavailable in (select value from dbo.fn_RIASplitDelimited(@nd_ids, '','')))
		begin
			insert ccUnavailableRelation (idUnavailable, idCampACD, [type])
			select TipoNotReady_id idUnavailable, @cam_id, @type from ccTipoNotReady where TipoNotReady_id in (select value from dbo.fn_RIASplitDelimited(@nd_ids, '','')) 
			and CAST(TipoNotReady_id as char(5)) + ''-'' + CAST(@cam_id as CHAR(5)) + ''-'' + CAST(@type as CHAR(5)) not in (select cast(idUnavailable as CHAR(5)) + ''-'' + cast(idCampACD as CHAR(5)) + ''-'' + CAST(type as CHAR(5)) from ccUnavailableRelation)

			
			select CAST(1 AS INT) -- to notify to UI that everything was Ok
			return(0)
		end
	END

	ELSE IF @action = 3
	BEGIN 

		if not exists( select TipoNotReady_id from ccTipoNotReady where TipoNotReady_id in (select value from dbo.fn_RIASplitDelimited(@nd_ids, '','')) and StatusTipoNotReady = 1)
		begin 
			select CAST(-3 AS INT) --, ''ND ids not exist''
			return(0)
		end

		IF exists (select * from ccUnavailableRelation where @cam_id = idCampACD and @type = type and idUnavailable in (select value from dbo.fn_RIASplitDelimited(@nd_ids, '','')))
		BEGIN
			delete from ccUnavailableRelation where [idCampACD] = @cam_id and [type] = @type and [idUnavailable] in (select value from fn_RIASplitDelimited (@nd_ids, '',''))
			select CAST(1 AS INT) --, ''correct unassing''
			return(0)
		END
		ELSE
		BEGIN
			select CAST(-1 AS INT) --, ''relation does not exist''
			return(0)
		END
	END

	SET NOCOUNT OFF
'
EXEC(@sql)

SET @process = 'K054000 Drop procedure ccsp_GalateaAdminCampaigns'
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAdminCampaigns'')
	BEGIN
		DROP PROCEDURE ccsp_GalateaAdminCampaigns
	END
'
EXEC(@sql)

SET @process = 'K054000 Create procedure ccsp_GalateaAdminCampaigns'
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
								camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(camps.IDArea AS INT) as AreaId,
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
								CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(inb.IDArea AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType
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
EXEC(@sql)

SET @process = 'K054000 Drop procedure ccsp_GalateaChangeHistory'
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaChangeHistory'')
	BEGIN
		DROP PROCEDURE ccsp_GalateaChangeHistory
	END
'
EXEC(@sql)

SET @process = 'K054000 Create procedure ccsp_GalateaChangeHistory'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_GalateaChangeHistory]
    @option TINYINT,
    @loginLst VARCHAR(max) = NULL,
    @moduleWithOperation varchar(max) = NULL,
    @operationDateIni SMALLDATETIME = NULL,
    @operationDateFin SMALLDATETIME = NULL,
    @top INT = 0
    AS
    SET NOCOUNT ON

    DECLARE @lang TINYINT

    SELECT @lang = valor
    FROM ccsettings
    WHERE setting_id = 27

    IF @option = 1 -- Catalogo de modulos
    BEGIN
        WITH Catalog AS(
        SELECT m.ModuleId as module_id, o.OperationId as operationType, 
        CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS mDescripcion, 
        CASE @lang WHEN 0 THEN OpTagEs WHEN 2 THEN OpTagPt ELSE OpTagEn END AS oDescripcion
        FROM ccGalateaOperations o WITH (INDEX (IX_ccGalateaOperations_Op))
        JOIN ccGalateaModOpRelation r ON o.OperationId = r.OperationId
        JOIN ccGalateaModules m WITH (INDEX (IX_ccGalateaModules_Mod)) ON r.ModuleId = m.ModuleId --WITH (INDEX (IX_ccGalateaModules_Mod))

        UNION

        SELECT 0, - 1, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, '' - ''
		
        UNION

        SELECT 0, 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END

        UNION

        SELECT ModuleId as module_id, 0, CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS descripcion, 
        CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
        FROM ccGalateaModules WITH (INDEX (IX_ccGalateaModules_Mod))

        UNION

        SELECT ModuleId as module_id, - 1 , CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS descripcion, '' - ''
        FROM ccGalateaModules WITH (INDEX (IX_ccGalateaModules_Mod)))

        SELECT module_id,operationType,mDescripcion,oDescripcion 
        FROM Catalog
        ORDER BY mDescripcion, oDescripcion

        RETURN (0)
    END

    IF @option = 2 -- Muestra informacion por filtros
    BEGIN

        declare @sql as nvarchar(max)
        DECLARE @table TABLE(id int,value varchar(max))
        declare @id int
        declare @moduleId varchar(max)
        declare @operationLst varchar(max)
        declare @query varchar(max) = '' and (''
        declare @value varchar(max)
        declare @first int = 1
        declare @pos int

        insert into @table select * from dbo.fn_RIASplitDelimited(cast(isnull(@moduleWithOperation,'''') as varchar(max)), '','')
        while exists(select * from @table)
        begin
            select top 1 @id = id, @value = value from @table
            set @pos = charindex('':'', @value)
            if(@pos <> 0)
            begin
                set @moduleId = substring(@value, 1, @pos-1)
                set @operationLst = replace(substring(@value, @pos+1, len(@value)), ''-'', '','')
                if(@first = 1)
                begin
                    set @query = @query + ''l.moduleId='' + @moduleId + '' and l.operationId in ('' + @operationLst + '')''
                    set @first = 0
                end
                else
                begin
                    set @query = @query + '' or l.moduleId='' + @moduleId + '' and l.operationId in ('' + @operationLst + '')''
                end
            end

            delete @table where id = @id
        end
        set @query = @query + '')''


        SET ROWCOUNT @top

        set @sql =
        ''DECLARE @tableLogin TABLE(id int,value varchar(255))
        insert into @tableLogin  select * from dbo.fn_RIASplitDelimited('''''' + cast(isnull(@loginLst,'''') as varchar(max)) + '''''','''','''')

        SELECT L.LogId as log_id, L.Area as areaName, L.ActivityDate as operationDate,
        CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN O.OpTagEs WHEN 2 THEN O.OpTagPt ELSE O.OpTagEn END operationType,
        L.LOGIN,
        CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN M.MTagEs WHEN 2 THEN M.MTagPt ELSE M.MTagEn END module_id,
        CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target,
        CASE WHEN i.description IS NULL THEN L.Identifier ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN i.TagEs WHEN 2 THEN i.TagPt ELSE i.TagEn END END +
        CASE WHEN L.Identifier<>'''''''' AND L.Value<>'''''''' THEN '''': '''' ELSE '''''''' END +

        CASE WHEN V.description IS NULL 
            THEN 
                CASE 
                    WHEN L.Identifier<>'''''''' AND (L.Identifier LIKE ''''COMMON_DELETE_SCHEDULE%'''' OR L.Identifier LIKE ''''COMMON_ADD_SCHEDULE%'''' OR L.Identifier LIKE ''''COMMON_DATE%'''')
                        THEN dbo.GetDateByLangHistory(L.value,''+cast(@lang as varchar(5)) +'')''+
                    ''WHEN L.Identifier<>'''''''' AND L.Identifier = ''''OUT_SIP_IDENTIFIER'''' THEN dbo.GetSipLangHistory(L.value,''+cast(@lang as varchar(5)) +'')''+
            ''ELSE L.value END
            ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN v.TagEs WHEN 2 THEN v.TagPt ELSE v.TagEn END END AS value

        FROM ccGalateaActivityLog L
        JOIN ccGalateaModules M WITH (INDEX (IX_ccGalateaModules_Mod)) ON L.ModuleId = M.ModuleId
        JOIN ccGalateaOperations O WITH (INDEX (IX_ccGalateaOperations_Op)) ON L.OperationId = O.OperationId
        LEFT JOIN targetRecord t ON t.targetT = L.target
        LEFT JOIN ccGalateaIdentifiers i ON i.Description = L.Identifier
        LEFT JOIN ccGalateaIdentifiers v ON v.Description = L.Value
        LEFT JOIN ccUsers CU ON CU.Login = L.login
        WHERE 1=1 
        AND
        CU.TipoUser_id = 2''
        +
        case isnull(@loginLst, '''') when '''' then '''' else
        '' AND L.LOGIN in (select value from @tableLogin) ''
        END
        +
        case isnull(@moduleWithOperation, '''') when '''' then '''' else
        @query
        end
        + case ISNULL(@operationDateIni, '''') when '''' then '''' else
        ''AND L.ActivityDate >= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull('''''' + convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, -1, '''''' + convert(varchar(19), @operationDateIni, 121) + '''''') ELSE L.ActivityDate END ''
        + '' AND L.ActivityDate <= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull(''''''+ convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, 1, '''''' + convert(varchar(19), @operationDateFin, 121) + '''''') ELSE L.ActivityDate END''
        end
        +
        '' ORDER BY L.ActivityDate DESC''
        execute sp_executesql @sql
        --print @sql
    END


    SET NOCOUNT OFF
'
EXEC(@sql)

SET @process = 'K054000 Drop procedure ccsp_GalateaUnavailableStates'
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaUnavailableStates'')
	BEGIN
		DROP PROCEDURE ccsp_GalateaUnavailableStates
	END
'
EXEC(@sql)

SET @process = 'K054000 Create procedure ccsp_GalateaUnavailableStates'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_GalateaUnavailableStates]
	@NotReady_id smallint = null,
	@Description varchar(30)='''',
	@Acc_Time int = null,
	@Intervals int = null,
	@Pass_Supv tinyint = null,
	@NextStatus int = null,
	@Frame smallint = null,
	@Type varchar(1)='''',
	@IsSupv int = null,
	@NotReady_ids varchar(max)=''''
	AS
	set nocount on
	DECLARE @sql nvarchar(4000), @graph nvarchar(1000), @id smallint, @newGraph smallint

		if @Type = 1 -- LOAD
			begin
				SELECT distinct a1.TipoNotReady_id as NotReady_Id, a1.Descripcion as Description, a1.Time_Acum as Acc_Time, a1.Time_xEv as Intervals, 
				cast(a1.Pas_Sup as bit) Pass_Supv, a1.NextStatus, frame as Frame, cast(a1.IsSup as bit) IsSupv
				FROM ccTipoNotReady a1 
				inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
				inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
				where a1.StatusTipoNotReady=1
				order by 2
			end

		If @Type=2 -- INSERT
		 begin
			if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Description)
			 begin		
				select -1
				return(0)
			 end
			if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=0 and Descripcion=@Description)
				begin		
					select @id=TipoNotReady_id from ccTipoNotReady where Descripcion=@Description
					update ccTipoNotReady set 
					Time_acum=@Acc_Time,
					Time_xEv=@Intervals,
					Pas_Sup=@Pass_Supv,
					NextStatus=@NextStatus,
					IsSup=@IsSupv,
					StatusTipoNotReady=1
					where Descripcion=@Description
					If not exists(select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
						Begin
							insert into ccRIAGraphics (frame, type_id) select @Frame,4
						End
				
					insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
					select cast(@id as int)
					return(0)		
				end
			If not exists(select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
			 Begin
				insert into ccRIAGraphics (frame, type_id) select @Frame,4
			 End

			insert ccTipoNotReady (Descripcion, Time_Acum, Time_xEv, Pas_Sup, NextStatus, IsSup, StatusTipoNotReady) 
			select @Description, @Acc_Time, @Intervals, @Pass_Supv, @NextStatus, @IsSupv,1
			select @id=SCOPE_IDENTITY()
			insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
			select cast(@id as int)
		 end

		If @Type=3 -- DELETE
		 begin
			 declare @NDs_Ids table (id int primary key not null)

			if @NotReady_id is null
			 begin
				insert into @NDs_Ids
				select value from dbo.fn_RIASplitDelimited (@NotReady_ids, '','')
			 end
			else
			 begin
				insert into @NDs_Ids
				select @NotReady_id
			 end

			exec ccsp_AdminNotready 3,0,@NotReady_id,0, @NotReady_ids
			delete ccRIANotReadyGraph where tipoNotReady_id in (select id from @NDs_Ids)
			delete from ccUnavailableRelation where idUnavailable in (select id from @NDs_Ids)
			update ccTipoNotReady set StatusTipoNotReady=0 where tipoNotReady_id in (select id from @NDs_Ids)
			update ccTipoNotReady set NextStatus=-1 where NextStatus in (select id from @NDs_Ids)
		
			select cast(id as smallint) NotReady_Id, 0 as Related from @NDs_Ids
		 end

		if(@Type=4) --UPDATE
		 begin

			if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Description and TipoNotReady_id not in (@NotReady_id))
			 begin		
				select -1
				return(0)
			 end

			update ccTipoNotReady set 
			 Descripcion=case @Description when '''' then Descripcion else @Description end,
			 Time_Acum=ISNULL(@Acc_Time,Time_Acum),
			 Time_xEv=ISNULL(@Intervals,Time_xEv),
			 Pas_Sup=ISNULL(@Pass_Supv,Pas_Sup), 
			 NextStatus=ISNULL(@NextStatus,NextStatus), 
			 IsSup=ISNULL(@IsSupv,IsSup)
			where TipoNotReady_id=@NotReady_id

			IF ISNULL(@Frame,'''') not in('''')
			 BEGIN
				If not exists (select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
				 begin
					insert into ccRIAGraphics (frame, type_id) select @Frame,4
				 end

				select @graph = graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
				update ccRIANotReadyGraph set graphic_id=cast(@graph as smallint) where TipoNotReady_id=cast(@NotReady_id as tinyint)
			 END
			 select 1
		 end

		if @Type = 5
		 begin
			select cast(NextStatus as smallint) NotReady_Id, cast(TipoNotReady_id as int) Related
			from ccTipoNotReady 
			where StatusTipoNotReady=1 and NextStatus in (select value from dbo.fn_RIASplitDelimited (@NotReady_ids, '',''))
		 end

	set nocount off
'
EXEC(@sql)
	
	------------------------------------------- End Rod Salazar -------------------------------------------------------
	
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
