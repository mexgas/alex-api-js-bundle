/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Carlos Eduardo Muñoz Carbajal
Date: 2025/12/15
Description: Sprint 5 - New features for virtual agents. 
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
    SET @versionfix = 10
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

    ------------------------------------ BEGIN UNION 127.20250905.0.6 -- 127.20251008.0.1 ------------------------------------

	------------------------------------------------ BEGIN JUAN MEDINA ------------------------------------------------
	SET @process = 'Sprint 5 - DELETE PERMISSIONS CENTER SCRIPT '
    SET @sql = '
        IF EXISTS (Select 1 From ccRoles_Permissions where Permissions_Id = 10003)
		BEGIN
			DELETE ccRoles_Permissions  where Permissions_Id = 10003
		END

		IF EXISTS (Select 1 From ccPermissions where Permissions_Id = 10003)
		BEGIN
			DELETE ccPermissions  where Permissions_Id = 10003
		END 
	'
    EXEC(@sql)

		SET @process = 'Sprint 5 - DROP PROCEDURE GetReportMenus'
    SET @sql = '
        If Exists (Select 1 From sys.procedures Where name = N''GetReportMenus'')
        Begin
            DROP PROCEDURE GetReportMenus
        End
	'
    EXEC(@sql)

	SET @process = 'Sprint 5 - CREATE PROCEDURE GetReportMenus - Delete View Menu Email'
    SET @sql = '
		CREATE PROCEDURE [dbo].[GetReportMenus]
		@userId int,
		@activeChat tinyint,
		@activeAVRS tinyint,
		@activeCRM tinyint=0,
		@activeEmail tinyint=0,
		@activeTwitter tinyint=0
		AS
		BEGIN

		select menu_id,
			substring(menu_descrip, charindex(''|'', menu_descrip) + 1, len(menu_descrip)) as menu_descrip,
			nullif(parent,menu_id) as parent,Nivel,ordengral,release
			into #tempCCMenus
			from ccMenus with(nolock)
			where type = 3 
			and menu_id >= 2000 
			and menu_id NOT IN (10010,10020,10030,10040)--Stop showing email menu in reports
			and(
				(menu_id not in (
				3130,3131,3132,3133,3134,3135,3136,
				8050,8060,8061,8062,8063,8070,8071,8072,8080,
				9000,9010,
				10000,10010,10020,10030,10040,
				11000,11010,11020,11030,11040
				))
				or  (@activeChat = 1 and menu_id in (3130,3131,3132,3133,3134,3135,3136))
				or  (@activeAVRS = 1 and menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080) )
				or  (@activeCRM = 1 and menu_id in (9000,9010) )
				or  (@activeEmail = 1 and menu_id in (10000,10010,10020,10030,10040) )
				or (@activeTwitter = 1 and menu_id in (11000,11010,11020,11030,11040))
				)
				order by menu_id


		;WITH ccMenusUserRec(Nivel, menu_descrip, menu_id, ordengral, parent,release)
		AS
		(
			select
				distinct b.Nivel as Nivel,
				b.menu_descrip as menu_descrip,
				b.menu_id as menu_id,
				b.ordengral as ordengral,
				b.parent as parent,b.release
				from #tempCCMenus as b
				inner join ccMenuUser as a with(nolock) on a.id_menu = b.menu_id and a.id_User = @userId and b.menu_id<>b.parent and a.type = 3
			UNION ALL


		--RECURSIViDAD
			select a.Nivel, a.menu_descrip, a.menu_id, a.ordengral, a.parent,a.release
				from #tempCCMenus a inner join ccMenusUserRec b on a.menu_id=b.parent
		)

		select distinct Nivel,menu_descrip,menu_id,ordengral,parent,release into #tempCCMenusUser from ccMenusUserRec order by ordengral,menu_id

		select distinct A.Nivel, A.menu_descrip, A.menu_id, A.ordengral,5 filtersType,A.release,parent from #tempCCMenusUser A
		where  menu_id not in
			(select distinct parent from  #tempCCMenus where Nivel=''C'' and parent not in (select distinct  A.parent from  #tempCCMenusUser A where A.Nivel=''C''))
		order by ordengral,menu_id

		drop table #tempCCMenus
		drop table #tempCCMenusUser

		END
	'
    EXEC(@sql)

	------------------------------------------------ END JUAN MEDINA ------------------------------------------------

	------------------------------------ BEGIN Octavio Ortiz ------------------------------------
	-- ccVirtualAgent
	SET @process = 'AlterTable ccVirtualAgent';
	SET @sql = '
	IF COL_LENGTH(''ccVirtualAgent'', ''OriginalAgentId'') IS NULL
	BEGIN
		ALTER TABLE ccVirtualAgent
			ADD 
				CopiesCount INT NOT NULL DEFAULT(0),
				OriginalAgentId INT NOT NULL DEFAULT(0);
	END
	';
	EXEC(@sql);

	-- insert de valores de operacion para duplicacion 
	SET @process = 'Insert into ccGalateaOperations - Clone Agent';
	SET @sql = '
	IF NOT EXISTS (
		SELECT 1
		FROM ccGalateaOperations
		WHERE OperationId = 174
	)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		VALUES (174, ''Clonar modelo'', ''Clone model'', ''Clonar modelo'');
	END
	';
	EXEC(@sql);

	---------------------------------------END Octavio Ortiz-------------------------------------

    ------------------------------------ BEGIN Carlos Muñoz ------------------------------------

    SET @process = 'Sprint 5 - Added validation of elimination for virtual agent while editing, also, is included a new option for duplication'
    SET @sql = '
        if exists (select * from sys.procedures where name = N''ccsp_VirtualAgents'')
        begin
            DROP PROCEDURE ccsp_VirtualAgents
        end'
    EXEC(@sql)

    SET @sql = ' 
	CREATE PROCEDURE [dbo].[ccsp_VirtualAgents]
	@action INT = 0,

	@idVirtualAgent INT = 0,
	--Creation
	@nameAgent NVARCHAR(255) = NULL,
	@responseTone TINYINT = 0,
	@languageAgent TINYINT = 0,
	@quantumRoleId INT = 0,
	@roleDescription NVARCHAR(30) = '''',
	@responseLength TINYINT = 0,
	@numberOfAgents INT = 0,
	@quantumAgentId NVARCHAR(50) = '''',
	@replyGreeting NVARCHAR(350) = '''',
	@replyFarewell NVARCHAR(350) = '''',
	@replySystemFailure NVARCHAR(350) = '''',
	@replyNoUnderstanding NVARCHAR(350) = '''',
	@statusAgent BIT = NULL,
	@campaignId INT = NULL,
	@mediaType INT = NULL, -- CALLS, WHATSAPP, SMS
	@campType INT = NULL, -- 0 IN - 1 OUT
	@voiceID INT= 0,
	@adminId INT = 0,
	@originalAgentId INT = 0,

	--Definition
	@objective VARCHAR(1200) = NULL,
	@rules VARCHAR(1200) = NULL,
	@instructions VARCHAR(8000) = NULL,
	@variables VARCHAR(500) = NULL,

	-- Masivo
	@virtualAgentIds VARCHAR(600) = NULL
	AS
	BEGIN
		DECLARE @idArea SMALLINT, @userName varchar(40)

		IF @action = 1
		BEGIN
			SELECT
				va.idAgent AS idAgent,
				va.NameAgent AS nombre,
				ISNULL(CAST(va.idCampaign AS INT),0) AS idCampaign,
				ISNULL(va.concurrentSessionsLimit, 0) AS concurrentSessionsLimit,
				CAST(va.StatusAgent AS BIT) AS status,
				CAST(va.mediaType AS INT) as SubType,
				ISNULL(
					CASE 
						WHEN va.CampType = 0 THEN ci.descripcion 
						ELSE co.cam_descripcion
					END, ''N/A''
				) AS campName,
				ISNULL(
					CASE 
						WHEN va.CampType = 0 THEN ci.IDArea -- Campaña de entrada
						ELSE co.IDArea -- Campaña de salida
					END,
				0) AS IDArea,
				CAST(ISNULL(
					CASE 
						WHEN va.CampType = 0 THEN ig.graphic_id -- Icono para entrada
						ELSE og.graphic_id -- Icono para salida
					END, 0
				) AS int) AS campaignGraph,
				CAST(va.CampType AS int) CampType,
				ISNULL(
					CASE 
						WHEN va.CampType = 0 THEN CAST(ci.Status AS BIT) -- Estado de la campaña de entrada
						ELSE CAST(co.cam_procesando AS BIT) -- Estado de la campaña de salida
					END, 0
				) AS IsActiveCampaign, -- Devuelve 1 o 0
				ISNULL(
					CASE 
						WHEN (va.CampType = 0 AND ci.chat = 5) THEN wn.Number
						WHEN (va.CampType = 1 AND co.CampType = 5) THEN wno.Number
						ELSE ''N/A''
					END, ''N/A''
				) AS NumeroAsociado,
				CONVERT(VARCHAR(10), va.createDateAgent, 120) AS FechaCreacion, -- Devuelve como ''YYYY-MM-DD''
				ISNULL(
					CASE 
						WHEN va.latestUpdateDateAgent IS NULL OR va.latestUpdateDateAgent = '''' THEN ''N/A''
						ELSE CONVERT(VARCHAR(10), va.latestUpdateDateAgent, 120) -- Devuelve como ''YYYY-MM-DD''
					END, ''N/A''
				) AS FechaUltimaModificacion, -- Devuelve ''YYYY-MM-DD'' o ''N/A''
				ISNULL(va.voice,1) as Voice,
				va.scriptAgent as ScriptAgent,
				CAST(CASE
					WHEN va.instructions IS NULL OR va.instructions = '''' THEN 0
					ELSE 1
					END AS bit) AS HasInstructions, 
				ISNULL(va.ReplyGreeting, '''') AS ReplyGreeting,
				ISNULL(va.ReplyFarewell, '''') AS ReplyFarewell,
				ISNULL(va.ReplySystemFailure, '''') AS ReplySystemFailure,
				ISNULL(va.ReplyNoUnderstanding, '''') AS ReplyNoUnderstanding,
				ISNULL(va.quantumRoleId, 0) AS QuantumRolId,
				ISNULL(va.responseLength, 0) AS ResponseLength,
				ISNULL(va.responseTone, 0) AS ResponseTone,
				ISNULL(va.roleName, '''') AS RolName,
				ISNULL(va.Language, 0) as Language,
				ISNULL(CopiesCount, 0) As CopiesCount,
				ISNULL(OriginalAgentId, 0) As OriginalAgentId
			FROM dbo.ccVirtualAgent va
			LEFT JOIN dbo.ccInbound ci ON ci.Inbound_id = va.idCampaign AND va.campType = 0
			LEFT JOIN dbo.ccCamps co ON co.cam_id = va.idCampaign AND va.campType = 1
			LEFT JOIN dbo.ccMetaWhatsAppNumbers wn ON wn.Inbound_Id = va.idCampaign AND va.campType = 0 AND mediaType != 0
			LEFT JOIN dbo.ccMetaWhatsAppNumbers wno ON wno.Cam_Id = va.idCampaign AND va.campType = 1 AND mediaType != 0
			LEFT JOIN dbo.ccRIAInboundGraph ig ON ig.Inbound_id = va.idCampaign AND va.campType = 0
			LEFT JOIN dbo.ccRIACampsGraph og ON og.cam_id = va.idCampaign AND va.campType = 1
			WHERE va.wasDeleted = 0
		END

		ELSE IF @action = 2
		BEGIN
			-- We validate the capacity defined in the setting 281 with the received value. 
			DECLARE @TotalOfConcurrentAgents INT, 
					@UsedConcurrentAgents INT

			IF EXISTS(SELECT 1 FROM ccVirtualAgent WHERE nameAgent = @nameAgent and wasDeleted = 0)
			BEGIN
				SELECT ''A virtual agent with the same name already exists'' as Result, 1 as ErrorCode
				RETURN
			END

			SELECT @TotalOfConcurrentAgents = CAST(valor AS int) FROM ccSettings2 WHERE setting_id = 281
			SELECT @UsedConcurrentAgents = ISNULL(SUM(concurrentSessionsLimit), 0) FROM ccVirtualAgent WHERE wasDeleted = 0

			IF((@UsedConcurrentAgents + @numberOfAgents) <= @TotalOfConcurrentAgents)
			BEGIN
				-- Creación de un nuevo agente virtual
				DECLARE @newModelId int;

				INSERT INTO dbo.ccVirtualAgent (
					nameAgent, 
					statusAgent, 
					createDateAgent, 
					latestUpdateDateAgent,
					concurrentSessionsLimit,
					responseTone,
					language,
					quantumAgentId,
					quantumRoleId,
					roleName,
					responseLength,
					ReplyGreeting,
					ReplyFarewell,
					ReplySystemFailure,
					ReplyNoUnderstanding,
					voice
				)
				VALUES (
					@nameAgent, 
					0, 
					GETDATE(),
					GETDATE(),
					@numberOfAgents,
					@responseTone,
					@languageAgent,
					@quantumAgentId,
					@quantumRoleId,
					@roleDescription,
					@responseLength,
					@replyGreeting,
					@replyFarewell,
					@replySystemFailure,
					@replyNoUnderstanding,
					@voiceID
				);

				SET @newModelId = SCOPE_IDENTITY();

				-- Activity History 
			
				SELECT @idArea = IDArea, @userName = Login FROM ccUsers where User_id = @adminId

				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
					SELECT
						(SELECT ISNULL(AreaName, '''') FROM ccRIACat_Areas WHERE IDArea = @idArea),
						getDate(), 
						@userName, 
						169,
						24,
						'''',
						'''',
						@nameAgent

				IF @campaignId = 0
				BEGIN
					SELECT ''Agent created correctly'' AS Result, 0 AS ErrorCode, @newModelId as IdAgent;
					RETURN
				END

				-- Invoke campaign association and return association results
	
				CREATE TABLE #associationResult (Result varchar(100), ErrorCode int, idAgent int, nameAgent varchar(255), idCampaign int, campaignName varchar(40))

				INSERT INTO #associationResult(Result, ErrorCode,idAgent,nameAgent,idCampaign,campaignName)
				EXEC dbo.ccsp_VirtualAgents
						@action=4,@adminId=@adminId, @campType=@campType, @campaignId=@campaignId, @mediaType=@mediaType, @idVirtualAgent=@newModelId;

				SELECT Result, ErrorCode, idAgent as IdAgent FROM #associationResult
				RETURN
			END
			ELSE
			BEGIN
				SELECT ''There are not contracted agents available'' AS Result, 2 AS ErrorCode; 
			END
		END

		ELSE IF @action = 3 -- Elimination of virtual Agent
		BEGIN
			CREATE TABLE #deletedVirtualAgents(idAgent int, agentName varchar(255), quantumAgentId VARCHAR(50))

			UPDATE dbo.ccVirtualAgent
			SET
				idCampaign = 0,
				mediaType = 0,
				concurrentSessionsLimit = 0,
				campType = 0,
				wasDeleted = 1
			OUTPUT deleted.idAgent, deleted.nameAgent, deleted.quantumAgentId INTO #deletedVirtualAgents
			WHERE idAgent IN(SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) AND statusAgent = 0;

			SELECT * FROM #deletedVirtualAgents
		END

		ELSE IF @action = 4 -- Change of associated campaign. Brings the info for Activity history
		BEGIN
			DECLARE @PreviousAgentData AS TABLE(
				idAgent INT,
				nameAgent VARCHAR(255),
				idCampaign SMALLINT,
				camptype TINYINT
			);

			IF(@campaignId <> 0)
			BEGIN
				-- *** VALIDATIONS FOR CAMPAIGN ASSIGNATION ***
				-- Campaign was deleted
				DECLARE @campaignArea AS SMALLINT

				IF @campType = 0
				BEGIN
					SELECT @campaignArea =
						CASE
							WHEN EXISTS (SELECT 1 FROM ccInbound_Consulta WHERE Inbound_id = @campaignId)
								THEN 1
							ELSE 0
						END;
				END
				ELSE IF @campType = 1
				BEGIN
					SELECT @campaignArea =
						CASE
							WHEN EXISTS (SELECT 1 FROM ccCamps_Consulta WHERE cam_id = @campaignId)
								THEN 1
							ELSE 0
						END;
				END

				IF @campaignArea <> 0
				BEGIN
					SELECT ''Campaign was deleted'' AS Result, 3 AS ErrorCode , 0 AS idAgent, '''' as nameAgent, 0 AS idCampaign, '''' AS nameCampaign
					RETURN
				END

					--- Campaign was assigned to another model
				IF EXISTS (SELECT 1 FROM ccVirtualAgent WHERE idAgent != @idVirtualAgent AND idCampaign = @campaignId AND mediaType = @mediaType AND campType = @campType)
				BEGIN
					SELECT ''Campaign has already been assigned'' as Result, 4 AS ErrorCode , 0 AS idAgent, '''' as nameAgent, 0 AS idCampaign, '''' AS nameCampaign;
					RETURN
				END

				--- Campaign doesn''t belong to the same wg than te user
				DECLARE @CampaignIsNotInUserWorkgroup  BIT = 0;

				IF NOT EXISTS (SELECT * FROM ccUsers_Roles NOLOCK WHERE User_id = @AdminId AND Rol_id = 7) -- It''s not a superUser
				BEGIN
					SELECT @CampaignIsNotInUserWorkgroup =
						CASE WHEN NOT EXISTS (
							SELECT 1
							FROM dbo.ccRIAWorkGroupUsers AS userWG
								JOIN dbo.ccRIACampEspWG AS campaignWg ON campaignWg.IDWG = userWG.IDWG
							WHERE userWG.User_id    = @adminId
								AND campaignWg.Tipo       = @campType 
								AND campaignWg.IdCampEsp  = @campaignId
							)
							THEN 1 ELSE 0 END;

					IF @CampaignIsNotInUserWorkgroup = 1
					BEGIN
						SELECT ''Campaign doesn''''t belong to admin workgroups'' as Result, 5 AS ErrorCode , 0 AS idAgent, '''' as nameAgent, 0 AS idCampaign, '''' AS nameCampaign;
						RETURN
					END
				END
			END

			UPDATE ccVirtualAgent SET idCampaign = @campaignId,
										mediaType = @mediaType,
										camptype = @campType,
										latestUpdateDateAgent = GETDATE()
										OUTPUT deleted.idAgent, deleted.nameAgent, deleted.idCampaign, deleted.campType INTO @PreviousAgentData
										WHERE idAgent = @idVirtualAgent
			IF @campaignId <> 0
				BEGIN
					SELECT
						''Campaign changed'' AS Result,
						0 AS ErrorCode,
						va.idAgent,
						va.nameAgent,
						CAST(va.idCampaign as int) idCampaign,
						CASE 
							WHEN @campType = 0 THEN i.descripcion
							ELSE cout.cam_descripcion 
						END AS campaignName
					FROM ccVirtualAgent va
						LEFT JOIN ccInbound i ON va.idCampaign = i.Inbound_id AND @campType = 0
						LEFT JOIN ccCamps cout ON va.idCampaign = cout.cam_id AND @campType = 1
					WHERE va.idAgent = @idVirtualAgent;
				END
			ELSE
				BEGIN
					SELECT
						''Campaign retired'' AS Result,
						0 AS ErrorCode,
						pvd.idAgent,
						pvd.nameAgent,
						CAST(0 as int) idCampaign,
						CASE 
							WHEN pvd.camptype = 0 THEN i.descripcion
							ELSE cout.cam_descripcion 
						END AS campaignName
					FROM @PreviousAgentData pvd
						LEFT JOIN ccInbound i ON pvd.idCampaign = i.Inbound_id AND pvd.camptype = 0
						LEFT JOIN ccCamps cout ON pvd.idCampaign = cout.cam_id AND pvd.camptype = 1
				END

		END

		ELSE IF @action = 5 -- Status change
		BEGIN
			CREATE TABLE #updatedVirtualAgents(idAgent int, nameAgent varchar(255), newStatus BIT)

			UPDATE ccVirtualAgent SET statusAgent = @statusAgent
			OUTPUT inserted.idAgent, inserted.nameAgent, inserted.statusAgent as newStatus INTO #updatedVirtualAgents
			WHERE idAgent IN (SELECT Value FROM fn_RIASplitDelimited(@virtualAgentIds,'','')) and statusAgent != @statusAgent

			SELECT * FROM #updatedVirtualAgents
		END

		ELSE IF @action = 6 --Check if there''s enabled related agent to camp 
		BEGIN
			DECLARE @result bit = 0;

			IF EXISTS (SELECT 1 FROM ccVirtualAgent WHERE idCampaign = @campaignId)
			BEGIN
				SELECT @result = statusAgent from ccVirtualAgent where idCampaign = @campaignId
			END

			select @result
		
		END
		ELSE IF (@action = 7) --- Get virtual agents by campaign id and camptype
		BEGIN
			DECLARE @defaultVoiceId VARCHAR(MAX)
			SELECT @defaultVoiceId = QuantumVoiceId FROM ccVirtualAgentVoices WHERE IsDefault = 1

			SELECT 
			cva.idAgent
			, ISNULL(cva.quantumAgentId,'''') AS QuantumAgentId
			, ISNULL(cva.location,'''') AS Location
			, ISNULL('''','''')  AS ProjectId
			, CASE 
				WHEN cva.voice IS NULL OR cva.voice = '''' THEN @defaultVoiceId
				ELSE ISNULL(cvav.QuantumVoiceId, @defaultVoiceId)
				END AS Voice
			FROM dbo.ccVirtualAgent AS cva
			LEFT JOIN ccVirtualAgentVoices cvav ON cvav.ID = cva.voice
			WHERE cva.idCampaign = @campaignId AND cva.campType = @campType;
		END
		ELSE IF (@action = 8) --- Reload virtual agent association
		BEGIN
			IF (@campType = 0)
				BEGIN 
					SELECT 
					cva.idAgent AS IdAgentVirtual
					,cva.nameAgent AS NameAgentVirtual
					,ISNULL(cva.concurrentSessionsLimit, 0) AS NumberSessions
					,CONVERT(INT, cva.idCampaign) AS IdCampaign
					, cva.campType AS CampType
				FROM ccVirtualAgent cva
				LEFT JOIN ccInbound ci ON cva.idCampaign = ci.Inbound_id AND cva.campType = @campType
				WHERE cva.idAgent = (CASE WHEN @idVirtualAgent = 0 THEN cva.idAgent ELSE @idVirtualAgent END) 
				END
			ELSE 
			BEGIN 
					SELECT 
					cva.idAgent AS IdAgentVirtual
					,cva.nameAgent AS NameAgentVirtual
					,ISNULL(cva.concurrentSessionsLimit, 0) AS NumberSessions
					,CONVERT(INT, cva.idCampaign) AS IdCampaign
					, cva.campType AS CampType
				FROM ccVirtualAgent cva
				LEFT JOIN ccCamps cc ON cva.idCampaign = cc.cam_id AND cva.campType = @campType
				WHERE cva.idAgent = (CASE WHEN @idVirtualAgent = 0 THEN cva.idAgent ELSE @idVirtualAgent END) 
				END
			END
		ELSE IF (@action = 9) --Get FileLocation from ccVirtualAgentVoices
		BEGIN
			select Name, FileName from ccVirtualAgentVoices where ID = @voiceID
		END
		ELSE IF (@action = 10) --Update voice
		BEGIN
			if exists(select * from ccVirtualAgent where idAgent=@idVirtualAgent)
			BEGIN
				update ccVirtualAgent set voice=@voiceID where idAgent=@idVirtualAgent
				select 1
			END
			ELSE BEGIN
				select 0
			END
		END
		ELSE IF(@action = 11) --get voice library
		BEGIN 
			select ID,Name,Gender, FileName, Language from ccVirtualAgentVoices
		END
		ELSE IF(@action = 12) -- get voice info by its Id
		BEGIN
			select QuantumVoiceId from ccVirtualAgentVoices where ID = @voiceID
		END
		ELSE IF (@action = 13) --Register model definition (Objectives, instructions, rules and variables)
		BEGIN
			DECLARE @modifiedModelName VARCHAR(255);

			UPDATE ccVirtualAgent
			SET
				objective   = @objective,
				rules       = @rules,
				instructions = @instructions,
				scriptAgent = @variables,
				latestUpdateDateAgent = GETDATE(),
				statusAgent = CASE WHEN idCampaign <> 0 THEN 1 ELSE 0 END
			WHERE idAgent = @idVirtualAgent;

			IF @@ROWCOUNT = 1
			BEGIN
				SELECT @modifiedModelName = nameAgent
				FROM ccVirtualAgent
				WHERE idAgent = @idVirtualAgent;

				SELECT @idArea = IDArea, @userName = Login FROM ccUsers where User_id = @adminId

				-- ACTIVITY HISTORY REGISTER
				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
					SELECT
						(SELECT ISNULL(AreaName, '''') FROM ccRIACat_Areas WHERE IDArea = @idArea),
						getDate(), 
						@userName, 
						170,
						24,
						''VA_STRUCTURE_CONFIGURATION'',
						'''',
						@modifiedModelName
			
				SELECT 0 AS ErrorCode
			END
			ELSE
			BEGIN
				SELECT 1 AS ErrorCode
			END

		END
		ELSE IF (@action = 14)
		BEGIN
			SELECT
				idAgent As IdAgent,
				nameAgent As Nombre,
				statusAgent As Status,
				ISNULL(concurrentSessionsLimit,0) As concurrentSessionsLimit,
				ISNULL(CAST(idCampaign AS INT),0) As idCampaign,
				ISNULL(CAST(mediaType AS INT),0) As SubType,
				ISNULL(CAST(campType AS INT),0) As campType,
				ISNULL(location,'''') As location,
				ISNULL(quantumAgentId,'''') As QuantumAgentId,
				ISNULL(scriptAgent,'''') As scriptAgent,
				ISNULL(voice,'''') As voice,
				ISNULL(ReplyGreeting,'''') As ReplyGreeting,
				ISNULL(ReplyFarewell,'''')As ReplyFarewell,
				ISNULL(ReplySystemFailure,'''') As ReplySystemFailure,
				ISNULL(ReplyNoUnderstanding,'''') As ReplyNoUnderstanding,
				ISNULL(language,0) As language,
				ISNULL(responseTone,0) As responseTone,
				ISNULL(roleName,'''') As RolName,
				ISNULL(responseLength,0) As responseLength,
				ISNULL(quantumRoleId,0) As quantumRolId,
				ISNULL(objective,'''') As objective,
				ISNULL(rules,'''') As rules,
				ISNULL(instructions,'''') As instructions
			FROM 
				ccVirtualAgent
			WHERE 
				idAgent = @idVirtualAgent
		END
		ELSE IF (@action = 15) -- UPDATE Agent Virtual 
		BEGIN

			-- No deletion validation
			IF NOT EXISTS(SELECT 1 FROM ccVirtualAgent WHERE idAgent = @idVirtualAgent and wasDeleted = 0)
			BEGIN
				SELECT ''The agent was deleted before save the changes.'' AS Result, 7 AS ErrorCode
				RETURN
			END
			-- 

			DECLARE @AreaName  NVARCHAR(200),
					@Login NVARCHAR(200),
					@NameCampaing NVARCHAR(200);

			EXEC InsertLogAdminGalatea @action = 1,
										@tableName = ''ccVirtualAgent'',
										@columnNameId = ''idAgent'',
										@valueId = @idVirtualAgent,
										@userId = @adminId
			CREATE TABLE #ccVirtualAgentTable (
				columnInfo varchar(255),
				dataInfo varchar(255),
				identifierInfo varchar(255)
			)

			UPDATE ccVirtualAgent
			SET
				nameAgent = CASE 
								WHEN @nameAgent IS NOT NULL 
										AND LTRIM(RTRIM(@nameAgent)) <> '''' 
										AND @nameAgent <> nameAgent 
								THEN @nameAgent 
								ELSE nameAgent 
							END,

				latestUpdateDateAgent = GETDATE(),

				responseTone = CASE 
									WHEN @responseTone IS NOT NULL 
										AND @responseTone > 0 
										AND (@responseTone <> responseTone OR responseTone IS NULL)
									THEN @responseTone 
									ELSE responseTone 
								END,

				language = CASE 
									WHEN @languageAgent IS NOT NULL 
										AND (@languageAgent <> language OR language IS NULL)
									THEN @languageAgent 
									ELSE language 
								END,

				concurrentSessionsLimit = CASE 
												WHEN @numberOfAgents IS NOT NULL 
													AND @numberOfAgents > 0 
													AND (@numberOfAgents <> concurrentSessionsLimit OR concurrentSessionsLimit IS NULL)
												THEN @numberOfAgents 
												ELSE concurrentSessionsLimit 
											END,

				responseLength = CASE 
										WHEN @responseLength IS NOT NULL 
											AND @responseLength > 0 
											AND (@responseLength <> responseLength OR responseLength IS NULL)
										THEN @responseLength 
										ELSE responseLength 
									END,

				ReplyGreeting = CASE 
									WHEN @replyGreeting IS NOT NULL 
											AND LTRIM(RTRIM(@replyGreeting)) <> '''' 
											AND (@replyGreeting <> ReplyGreeting OR ReplyGreeting IS NULL)
									THEN @replyGreeting 
									ELSE ReplyGreeting 
								END,

				ReplyFarewell = CASE 
									WHEN @replyFarewell IS NOT NULL 
											AND LTRIM(RTRIM(@replyFarewell)) <> '''' 
											AND (@replyFarewell <> ReplyFarewell OR ReplyFarewell IS NULL)
									THEN @replyFarewell 
									ELSE ReplyFarewell 
								END,

				ReplySystemFailure = CASE 
											WHEN @replySystemFailure IS NOT NULL 
												AND LTRIM(RTRIM(@replySystemFailure)) <> '''' 
												AND (@replySystemFailure <> ReplySystemFailure OR ReplySystemFailure IS NULL)
											THEN @replySystemFailure 
											ELSE ReplySystemFailure 
										END,

				ReplyNoUnderstanding = CASE 
											WHEN @replyNoUnderstanding IS NOT NULL 
												AND LTRIM(RTRIM(@replyNoUnderstanding)) <> '''' 
												AND (@replyNoUnderstanding <> ReplyNoUnderstanding OR ReplyNoUnderstanding IS NULL)
											THEN @replyNoUnderstanding 
											ELSE ReplyNoUnderstanding 
										END,

				voice = CASE 
							WHEN @voiceID IS NOT NULL 
									AND @voiceID > 0 
									AND (@voiceID <> voice OR voice IS NULL)
							THEN @voiceID 
							ELSE voice 
						END
			WHERE idAgent = @idVirtualAgent;

			IF @campaignId IS NOT NULL
			BEGIN
				EXEC dbo.ccsp_VirtualAgents
						@action=4,@adminId=@adminId, @campType=@campType, @campaignId=@campaignId, @mediaType=@mediaType, @idVirtualAgent=@idVirtualAgent;
				IF @campaignId <> 0
				BEGIN
					IF @mediaType = 11
					BEGIN
						SELECT
							@NameCampaing = [descripcion]
						FROM ccInbound
						WHERE inbound_id = @campaignId
					END
					ELSE
						SELECT
							@NameCampaing = cam_descripcion
						FROM ccCamps
						WHERE cam_id = @campaignId
				END
			END

			EXEC InsertLogAdminGalatea @action = 2,
										@tableName = ''ccVirtualAgent'',
										@columnNameId = ''idAgent'',
										@valueId = @idVirtualAgent,
										@userId = @adminId,
										@tableTemp = ''#ccVirtualAgentTable''

			SELECT  @Login = U.[Login],
					@AreaName = A.[AreaName]
			FROM ccUsers AS U
			LEFT JOIN ccRIACat_Areas AS A
				ON A.IDArea = U.IDArea
			WHERE U.User_id = @adminId;

			SELECT @NameAgent = v.nameAgent
			FROM dbo.ccVirtualAgent AS v
			WHERE v.idAgent = @idVirtualAgent;

			;WITH src AS (
				SELECT 
					CCVA.*,
					ROW_NUMBER() OVER (
						PARTITION BY CCVA.identifierInfo 
						ORDER BY CCVA.columnInfo 
					) AS rn
				FROM #ccVirtualAgentTable AS CCVA
			)
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT
				@AreaName,
				GETDATE(),
				@Login,
				171,
				24,
				S.identifierInfo,
				CASE
					WHEN S.identifierInfo IS NOT NULL AND S.identifierInfo <> '''' THEN 
						CASE
							WHEN S.identifierInfo = ''VA_LANGUAGE'' THEN
								CASE S.dataInfo
									WHEN 1 THEN ''VA_ENGLISH_EN''
									WHEN 2 THEN ''VA_PORTUGUESE_PT''
									ELSE ''VA_SPANISH_ES''
								END
							WHEN S.identifierInfo = ''VA_TONE_OF_VOICE'' THEN
								CASE S.dataInfo
									WHEN 1 THEN ''VA_FORTHRIGHT_AND_CONCISE''
									WHEN 2 THEN ''VA_SYMPATHETIC_AND_WARM''
									WHEN 3 THEN ''VA_PERSUASIVE_AND_ACTION_ORIENTED''
									WHEN 4 THEN ''VA_NEUTRAL_AND_OBJECTIVE''
									WHEN 5 THEN ''VA_RELAXED_AND_FRIENDLY''
									ELSE ''VA_NONE_TV''
								END
							WHEN S.identifierInfo = ''VA_RESPONSE_LENGTH'' THEN
								CASE S.dataInfo
									WHEN 1 THEN ''VA_SHORT_RESPONSE''
									WHEN 2 THEN ''VA_MEDIUM_RESPONSE''
									WHEN 3 THEN ''VA_LONG_RESPONSE''
									ELSE ''VA_NONE''
								END
							WHEN S.identifierInfo = ''VA_VIRTUAL_AGENT_CAMPAIGN'' THEN
								CASE S.dataInfo
									WHEN 0 THEN ''VA_NONE'' 
									ELSE @NameCampaing
								END
							WHEN S.identifierInfo = ''VA_VOICE_TYPE'' THEN
								CASE S.dataInfo
									WHEN 1 THEN ''VA_VOICE_FEMALE''
									WHEN 3 THEN ''VA_VOICE_FEMALE''
									WHEN 5 THEN ''VA_VOICE_FEMALE''
									WHEN 2 THEN ''VA_VOICE_MALE''
									WHEN 4 THEN ''VA_VOICE_MALE''
									WHEN 6 THEN ''VA_VOICE_MALE''
									ELSE ''VA_VOICE_MALE''
								END
							WHEN S.identifierInfo = ''VA_SCRIPTED_RESPONSES'' THEN
								''VA_RESPONSES'' 
							ELSE S.dataInfo
						END
					ELSE ''''
				END,
				@NameAgent
			FROM src AS S
			WHERE NULLIF(LTRIM(RTRIM(S.identifierInfo)), '''') IS NOT NULL
				AND NOT (S.identifierInfo = ''VA_SCRIPTED_RESPONSES'' AND S.rn > 1)

		
			EXEC InsertLogAdminGalatea @action = 3,
										@tableName = ''ccVirtualAgent'',
										@columnNameId = ''idAgent'',
										@valueId = @idVirtualAgent,
										@userId = @adminId

			IF OBJECT_ID(N''tempdb..#ccVirtualAgentTable'') IS NOT NULL
			DROP TABLE #ccVirtualAgentTable

			SELECT ''Agent successfully updated'' AS Result, 0 AS ErrorCode, @idVirtualAgent as IdAgent;
		END

		ELSE IF (@action = 16) -- Duplicate virtual agent
		BEGIN
			SET NOCOUNT ON;

			DECLARE @newAgentId INT;

			IF EXISTS(SELECT 1 FROM ccVirtualAgent WHERE nameAgent = @nameAgent and wasDeleted = 0)
			BEGIN
				SELECT ''A virtual agent with the same name already exists'' as Result, 1 as ErrorCode
				RETURN
			END
	
			-- Validación de capacidad (variables con nombres únicos)
			DECLARE @TotalOfConcurrentAgents_16 INT,
					@UsedConcurrentAgents_16   INT;

			SELECT @TotalOfConcurrentAgents_16 = CAST(valor AS INT)
			FROM ccSettings2
			WHERE setting_id = 281;

			SELECT @UsedConcurrentAgents_16 = ISNULL(SUM(concurrentSessionsLimit), 0)
			FROM ccVirtualAgent
			WHERE wasDeleted = 0;

			IF ((@UsedConcurrentAgents_16 + ISNULL(@numberOfAgents,0)) > ISNULL(@TotalOfConcurrentAgents_16,0))
			BEGIN
				SELECT ''There are not contracted agents available'' AS Result, 2 AS ErrorCode;
				RETURN;
			END




			-- Crear el duplicado copiando del original y sobrescribiendo con valores del frontend
			INSERT INTO ccVirtualAgent (
				nameAgent,
				statusAgent,
				createDateAgent,
				latestUpdateDateAgent,
				responseTone,
				language,
				quantumRoleId,
				roleName,
				responseLength,
				quantumAgentId,
				concurrentSessionsLimit,
				voice,
				ReplyGreeting,
				ReplyFarewell,
				ReplySystemFailure,
				ReplyNoUnderstanding,
				objective,
				rules,
				instructions,
				scriptAgent,
				OriginalAgentId,
				CopiesCount,
				wasDeleted,
				idCampaign,
				mediaType,
				campType
			)
			SELECT
				@nameAgent,                    
				0,                             
				GETDATE(),
				GETDATE(),
				@responseTone,                
				@languageAgent,                
				@quantumRoleId,                 
				@roleDescription,                      
				@responseLength,               
				@quantumAgentId,               
				@numberOfAgents,               
				@voiceID,                         
				@ReplyGreeting,                 
				@ReplyFarewell,                
				@ReplySystemFailure,            
				@ReplyNoUnderstanding,         
				objective,                     
				rules,                         
				instructions,                 
				scriptAgent,                   
				@originalAgentId,                       
				0,                             -- Sin copias propias todavía
				0,                             -- No eliminado
				0,                             -- Sin campaña
				0,                             -- Sin mediaType
				0                              -- Sin campType
			FROM ccVirtualAgent
			WHERE idAgent = @originalAgentId;

			SET @newAgentId = SCOPE_IDENTITY();

			IF (@newAgentId IS NULL)
			BEGIN
				SELECT ''Source agent not found'' AS Result, 2 AS ErrorCode, NULL AS IdAgent, @originalAgentId AS OriginalAgentId;
				RETURN;
			END

			-- Actualizar contador del padre
			UPDATE ccVirtualAgent 
			SET CopiesCount = ISNULL(CopiesCount, 0) + 1,
				latestUpdateDateAgent = GETDATE()
			WHERE idAgent = @originalAgentId;

			-- Registrar actividad
			SELECT @idArea = IDArea, @userName = Login 
			FROM ccUsers 
			WHERE User_id = @adminId;

			INSERT INTO ccGalateaActivityLog (
				Area, 
				ActivityDate, 
				Login, 
				OperationId, 
				ModuleId, 
				Identifier, 
				Value, 
				Target
			)
			SELECT
				(SELECT ISNULL(AreaName, '''') FROM ccRIACat_Areas WHERE IDArea = @idArea),
				GETDATE(), 
				@userName, 
				174,
				24,
				'''',
				'''',
				@nameAgent;

			-- Retornar resultado
			SELECT ''Agent duplicated successfully'' AS Result,
					0 AS ErrorCode,
					@newAgentId AS IdAgent,
					@originalAgentId AS OriginalAgentId;
		END
	END	    
    '
    EXEC(@sql)
    ------------------------------------ END Carlos Muñoz ------------------------------------

	
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
