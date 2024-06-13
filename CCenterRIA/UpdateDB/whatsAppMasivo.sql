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
SET @versionfix = 1
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
	-----------------------------------------------Inicio Crear tablas ----------------------------------------------------------------------------------
	set @process = 'Create table ccMetaWAOutboundTemplates '
	set @sql = '
	if not exists (select * from sys.tables where name = N''ccMetaWAOutboundTemplates'')
    begin

	CREATE TABLE ccMetaWAOutboundTemplates(
		Id bigint,
		Category varchar(100) NULL,
		TemplateName varchar(512) NOT NULL,
		AllowCategoryChange bit NULL,
		LanguageCode varchar(30) NULL,
		Status varchar(30) NULL,
		header nvarchar(max) NULL,
		body nvarchar(max) NULL,
		footer nvarchar(max) NULL,
		buttons nvarchar(max) NULL,
		RemovalDate datetime NULL,
		IdFile varchar(200),
		IsPendingQuality bit NOT NULL DEFAULT 1
	) 
    end'
	EXEC(@sql)
	-----------------------------------------------Fin Crear tablas ----------------------------------------------------------------------------------
	------------------------------------------------Inicio Agregar columnas---------------------------------------------------------------------------
	set @process = 'DEV2-476 K020029 Setting 272 '
	set @sql = '
	if not exists(select setting_id from ccSettings2 where setting_id = 272)
	begin
		insert into ccSettings2 (setting_id,valor,status,descripcion,Tipo,detalle,description) values (272,''3|90'',1, ''Reintentos para envío de mensajes de WhatsApp |Intervalo de reintentos'',''GRL'',''Reintentos para envío de mensajes WhatsApp (default: 3, max: 10) | Intervalo de reintentos para envío de plantillas WhatsApp (default: 90 s, min: 1 s)'',''Retries for WhatsApp outgoing messages (default: 3, max: 10) | Retry interval for WhatsApp templates (default: 90 s, min: 1 s)'')
	end
	'
	EXEC(@sql)

	set @process = 'DEV2-406 K020138 Add column AssignConversationSameAgent'
	set @sql = '
	if not exists (select * from sys.columns where name = N''AssignConversationSameAgent'' and Object_ID = Object_ID(N''ccCampsExtend''))
    begin
        alter table ccCampsExtend add  AssignConversationSameAgent bit null
    end'
	EXEC(@sql)
	------------------------------------------------Fin Agregar columnas---------------------------------------------------------------------------
	-------------------------------------------------Inicio Insertar valores en tablas----------------------------------------------------------------
	set @process = 'DEV2-406 K020138 Configuración asignar al mismo agente'
	set @sql = '
	if not exists(select Identifiers from relationTableColumnIdentifiers where Identifiers = ''OUT_WHATS_ASSIGN_SAME_AGENT'')
	begin
		insert into relationTableColumnIdentifiers (Identifiers,tableName,colunName) values (''OUT_WHATS_ASSIGN_SAME_AGENT'',''ccCampsExtend'',''AssignConversationSameAgent'')
	end'
	EXEC(@sql)

	set @process = 'DEV2-406 K020138 Configuración asignar al mismo agente'
	set @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description=''OUT_WHATS_ASSIGN_SAME_AGENT'')
	begin 
	insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''OUT_WHATS_ASSIGN_SAME_AGENT'',''Asignar contacto al último agente que le atendió'',
	''Assign contact to the last agent who assisted them'',''Atribuir contato ao último agente que o atendeu'')
	end'
	EXEC(@sql)

	set @process = 'Insert module Meta templates in ccGalateaModules '
	set @sql = '
	if not exists(select ModuleId from ccGalateaModules where ModuleId=20)
	begin
		insert into ccGalateaModules (ModuleId,MTagEs,MTagEn,MTagPt) values (20,''Plantillas de Meta'',''Meta templates'',''Modelos de Meta'')
	end
	'
	EXEC(@sql)

	set @process = 'Insert Create template in ccGalateaOperations'
	set @sql = '
	if not exists(select OperationId from ccGalateaOperations where OperationId=113)
	begin
		insert into ccGalateaOperations (OperationId,OpTagEs,OpTagEn,OpTagPt) values (113,''Crear plantilla'',''Create template'',''Criar modelo'')
	end'
	EXEC(@sql)
	------------------------------------------------Fin Insertar valores en tablas----------------------------------------------------------------
	------------------------------------------------Modificar sp-----------------------------------------------------

	set @process = 'Drop SP ccsp_GalateaDeleteCampaignAndACD '
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GalateaDeleteCampaignAndACD'')
    begin
        DROP PROCEDURE ccsp_GalateaDeleteCampaignAndACD;
    end'
	EXEC(@sql)

	set @process = 'Create ccsp_GalateaDeleteCampaignAndACD, campañas de salida de WA, se asigna null a la columna Cam_Id de la tabla ccMetaWhatsAppNumbers '
	set @sql = '
	CREATE PROCEDURE ccsp_GalateaDeleteCampaignAndACD
            @userId           SMALLINT,
            @DeleteCamId      VARCHAR(MAX),
            @DeleteACDGroupId VARCHAR(MAX),
            @moduleId         SMALLINT = 49
        AS
        BEGIN

            IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
				SELECT value As DeleteCamId, c.IDArea AS IDAreaCamp, 1 AS CampTypeCamp, ISNULL(wg.IDWG,0) as IDWG, ISNULL(c.CampType, 0) AS MediaType
                INTO #CampsDelete
                FROM fn_RIASplitDelimited(@DeleteCamId, '','') a
                inner join ccCamps c on  a.value = c.cam_id and c.IDArea IS NOT NULL
                left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=1
            IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
				SELECT value As DeleteACDId, c.IDArea AS IDAreaACD, 0 AS CampTypeACD, ISNULL(wg.IDWG,0) as IDWG, cast(ISNULL(chat, 0) as int) AS MediaType
                INTO #ACDDelete
                FROM fn_RIASplitDelimited(@DeleteACDGroupId, '','') a
                inner join ccInbound c on  a.value = c.Inbound_id and c.IDArea IS NOT NULL
                left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=0

            IF  not Exists (select * from #CampsDelete union select * from #ACDDelete )
            begin
                select ''-1'' AS Result
                return
            end

            IF datalength(@DeleteCamId) > 0
                BEGIN

                if exists(select cam_id from ccInbound where cam_id in (select DeleteCamId from #CampsDelete)) begin
                    --Borra las calificacion con reprogramacion
                    delete ccCalifCamp from ccInbound A
                    inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                    inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
                    where A.cam_id in (select DeleteCamId from #CampsDelete)
                    --Borra las subcalificacion con reprogramacion
                    delete rel from ccInbound A
                    inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                    inner join ccTipoCalif C on B.calif_id=C.calif_id
                    inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
                    inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
                    where A.cam_id in (select DeleteCamId from #CampsDelete) and sb.canReprogram=1

                    update ccInbound set cam_id = null where cam_id in (select DeleteCamId from #CampsDelete)

                end

                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
                select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete)

                delete from ccCampsAgente where cam_id in (select DeleteCamId from #CampsDelete)
                insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
                select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete) and A.tipo = 1

                delete from ccSupervisorCam where cam_id in (select DeleteCamId from #CampsDelete) and tipo = 1
                delete from ccRIACampEspWG where IdCampEsp in (select DeleteCamId from #CampsDelete) and tipo = 1

                IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
                SELECT ca.AreaName,
                       GETDATE() operationDate,
                       27 operationType,
                       (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                       @moduleId module_id,
                       c.cam_descripcion value,
                       ca.AreaName AS target
                INTO #CampLog
                FROM ccRIACat_Areas ca
                Inner join ccCamps c with(nolock) on ca.IDArea = c.IDArea
                WHERE c.cam_id in (select DeleteCamId from #CampsDelete)

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
				SELECT A.AreaName, GETDATE(), (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
				CASE 
					WHEN CampType = 6 THEN 45
					WHEN CampType = 5 THEN 47
					WHEN CampType = 4 THEN 49
					WHEN CampType = 7 THEN 51
				ELSE 43 END, 
				3, 
				'''',
				'''', 
				c.cam_descripcion
				FROM ccRIACat_Areas A INNER JOIN ccCamps c on A.IDArea = c.IDArea
				where c.cam_id in (select DeleteCamId from #CampsDelete)

                Update ccCamps set IDArea = null where cam_id in (select DeleteCamId from #CampsDelete)
        
                update contactMeanOut set name = '''', conexionInfo = '''', connUser = '''', isActive = 0
                where camp_id in (SELECT DeleteCamId FROM #CampsDelete) and meanContactTypeId=5
        
                update ccWhatsAppNumbers set camp_id = 0 where camp_id in (select DeleteCamId from #CampsDelete)

			    update ccMetaWhatsAppNumbers set Cam_Id = null where Cam_Id in (select DeleteCamId from #CampsDelete)
        

            END
            IF datalength(@DeleteACDGroupId) > 0
                BEGIN

                if exists(select top 1 cam_id from ccInbound where Inbound_id in (select DeleteACDId from #ACDDelete))
                begin
                        update ccInbound set cam_id = null where Inbound_id in (select DeleteACDId from #ACDDelete)
                end

                IF OBJECT_ID(''tempdb..#AllWGACD'') IS NOT NULL DROP TABLE #AllWGACD
                SELECT DISTINCT(IDWG)
                INTO #AllWGACD
                FROM ccRIACampEspWG ce
                WHERE IDCampEsp in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

                insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
                select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG
                from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id
                where B.User_id is null and A.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                delete ccInboundHorarios Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
                delete ccInboundMsgs Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
                delete ccInboundDnis where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
                select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG
                from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id
                where B.User_id is null and A.cam_id in (SELECT DeleteACDId FROM #ACDDelete)

                delete ccSupervisorCam where cam_id in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0
                delete ccInboundAgentes where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
                delete ccRIACampEspWG where IdCampEsp  in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0


                IF OBJECT_ID(''tempdb..#ACDLog'') IS NOT NULL DROP TABLE #ACDLog
                SELECT ca.AreaName,
                        GETDATE() operationDate,
                        28 operationType,
                        (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                        @moduleId module_id,
                        i.descripcion value,
                        ca.AreaName AS target
                INTO #ACDLog
                FROM ccRIACat_Areas ca
                inner join ccInbound i with(nolock) on ca.IDArea = i.IDArea
                WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
				SELECT a.AreaName, GETDATE(), (SELECT [Login] FROM ccUsers WHERE User_id = @userId),
				CASE 
					WHEN chat = 5 THEN 41
					WHEN chat = 1 THEN 65
					ELSE 61 END, 
				3, 
				'''', 
				'''', 
				i.descripcion
				FROM ccRIACat_Areas a inner join ccInbound i on a.IDArea = i.IDArea
				WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                Update ccInbound set IDArea = null, status = 0 where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                    begin
                        update ContactMeanIn set name = '''', conexionInfo = ''usuarioID|token|tokenSecret|1|0'', connUser = '''', isActive = 0
                        where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=2
                end
                if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo email asociado al ACD
                    begin
                        update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=1
                end
                update ccinbound set chatDomain = '''' where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)--para desasociar el dominio del chat

                if exists (SELECT inboundId FROM contactMeanIn WHERE inboundId in (select DeleteACDId from #ACDDelete))
                    begin
                        update contactMeanIn set isActive = 0 where inboundId in (select DeleteACDId from #ACDDelete)
                end            
                update ccWhatsAppNumbers set inboundId = 0 where inboundId in (select DeleteACDId from #ACDDelete)
        
            END

            IF datalength(@DeleteCamId) > 0
                Insert into ccRIALog Select * from #CampLog
            IF datalength(@DeleteACDGroupId) > 0
                Insert into ccRIALog Select * from #ACDLog

            SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #CampsDelete
            UNION
            SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #ACDDelete
            IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
            IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
            IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
        END'
	EXEC(@sql)

	set @process = 'Drop ccsp_RIAUpdateCamConfigExtend'
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateCamConfigExtend'')
    begin
        DROP PROCEDURE ccsp_RIAUpdateCamConfigExtend;
    end'
	EXEC(@sql)

	set @process = 'DEV2-406 K020138 CREATE csp_RIAUpdateCamConfigExtend se agrega assignConversationSameAgent'
	set @sql = '
	
	CREATE PROCEDURE ccsp_RIAUpdateCamConfigExtend
					@cam_id smallint,
					@zipCodeSchedule BIT = NULL,
					@userId SMALLINT = NULL,
					@idArea SMALLINT = NULL, 
					@isCreating SMALLINT = NULL,
					@simultaneousRecs SMALLINT = NULL,
					@module INT = -1,
					@recordCalls tinyint = 1,
					@editableContactData BIT = 1,
					@assignConversationSameAgent bit = 0
				AS
				BEGIN
					SET NOCOUNT ON;
					DECLARE @country INT = (select valor from ccSettings where setting_id = 104); 
					DECLARE @excludeIdentifier VARCHAR(255) = CASE WHEN @country = 4 THEN ''COMMON_INTERNATIONAL_RECORD_CALLS'' ELSE ''COMMON_USA_RECORD_CALLS'' END;
					if exists(select * from ccCampsExtend where cam_id=@cam_id) begin

						EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCampsExtend'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

						IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

						Create table #ccCampsExtendTable 
						(
							columnInfo VARCHAR(255),
							dataInfo VARCHAR(255),
							identifierInfo VARCHAR(255)
						)

						DECLARE @Camptype INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @cam_id);
						DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
																					CASE 
																						WHEN @Camptype = 6  THEN 44
																						WHEN @Camptype = 5  THEN 46
																						WHEN @Camptype = 4  THEN 48
																						WHEN @Camptype = 7  THEN 50
																						ELSE 42 END
																				ELSE 
																					CASE 
																						WHEN @Camptype = 6  THEN 55
																						WHEN @Camptype = 5  THEN 56
																						WHEN @Camptype = 4  THEN 57
																						WHEN @Camptype = 7  THEN 58
																						ELSE 54 END
																				END;

						UPDATE ccCampsExtend SET
							zipCodeSchedule = isnull(@zipCodeSchedule,zipCodeSchedule),
							simultaneousRecs = isnull(@simultaneousRecs,simultaneousRecs),
							RecordCalls = ISNULL(@recordCalls, RecordCalls),
							EditableContactData = isnull(@editableContactData,EditableContactData),
							AssignConversationSameAgent = isnull(@assignConversationSameAgent,AssignConversationSameAgent)

						Where cam_id = @cam_id  

						IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsExtendTable'';

						IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

						IF(@isCreating = 1) DELETE FROM #ccCampsExtendTable WHERE identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') and dataInfo = 0

						INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
						SELECT 
							(SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
							getDate(), 
							(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
							@operation, 
							@module, 
							CCCE.identifierInfo,
							CASE WHEN CCCE.identifierInfo IS NOT NULL AND CCCE.identifierInfo <> '''' THEN
								CASE 
									WHEN CCCE.identifierInfo IN (''SETTINGS_CHANGED_AREAS_ZIP'', ''COMMON_INTERNATIONAL_RECORD_CALLS'', ''EDIT_CALL_DATASET'') THEN
										CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
									WHEN @isCreating = 1 THEN
										CASE WHEN CCCE.identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') THEN
											CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' END
											END
									WHEN @isCreating = 2 THEN
										CASE WHEN CCCE.identifierInfo IN (''OUT_WHATS_ASSIGN_SAME_AGENT'') THEN
											CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
											END
									WHEN CCCE.identifierInfo IN (''COMMON_USA_RECORD_CALLS'') THEN
										CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_USA_RECORD_CALLS_MODE_ALL''
											WHEN CCCE.dataInfo = 2 THEN ''COMMON_USA_RECORD_CALLS_MODE_AUTH''
											WHEN CCCE.dataInfo = 4 THEN ''COMMON_USA_RECORD_CALLS_MODE_NOAUTH''
											ELSE ''COMMON_DISABLED'' END
									ELSE CCCE.dataInfo END	
							ELSE '''' END,
							(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
						FROM #ccCampsExtendTable AS CCCE where CCCE.identifierInfo != @excludeIdentifier;

						EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
						IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable

					end
					else begin
						INSERT INTO ccCampsExtend(cam_id,zipCodeSchedule,SimultaneousRecs, RecordCalls, AssignConversationSameAgent) values (@cam_id,@zipCodeSchedule,@simultaneousRecs, @recordCalls, @assignConversationSameAgent)
					end

					update ccCamps set call_record = @recordCalls where cam_id = @cam_id

					set nocount off
				END
	'
	EXEC(@sql)

	set @process = 'DEV2-406 K020138 drop sp ccsp_RIAConfCamp'
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_RIAConfCamp'')
    begin
        DROP PROCEDURE ccsp_RIAConfCamp;
    end'
	EXEC(@sql)

	set @process = 'DEV2-406 K020138 create sp ccsp_RIAConfCamp se agrega assignConversationSameAgent'
	set @sql = '
		CREATE PROCEDURE ccsp_RIAConfCamp @User_id SMALLINT, @campID INT = NULL
		AS
		SET NOCOUNT ON

		DECLARE @tableExistsRec TABLE (
			camId INT PRIMARY KEY
			,existRec BIT
			)
		DECLARE @camByUser TABLE (
			camId INT PRIMARY KEY
			,isCheck BIT
			)
		DECLARE @camId INT
			,@id INT;
		DEClARE @intenationalDialingPorts bit;
		declare @tempInternationalCode int
 
		if((select COUNT(*) from ( select  top 1 IdCode from ccoDialers ccoDial inner join ccoDialerCamp ccoDialCamp on ccoDialCamp.dialer_id = ccoDial.dialer_id where ccoDialCamp.cam_id = @campID and ccoDial.DialingType=0  ) result ) > 0)
		BEGIN
			set @intenationalDialingPorts = 1
		END
		ElSE
		BEGIN
			set @intenationalDialingPorts = 0;
		END

		IF NOT EXISTS (
				SELECT *
				FROM ccUsers_Roles
				WHERE User_id = @User_id
					AND Rol_id = 7
				)
		BEGIN
			INSERT INTO @camByUser
			SELECT *
				,0
			FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
			WHERE @campID IS NULL
				OR cam_id = @campID
		END
		ELSE
		BEGIN
			INSERT INTO @camByUser
			SELECT cam_id
				,0
			FROM ccCamps
			WHERE (
					IDArea > 0
					OR IDArea IS NULL
					)
				AND (
					@campID IS NULL
					OR cam_id = @campID
					)
		END

		WHILE EXISTS (
				SELECT *
				FROM @camByUser
				WHERE isCheck = 0
				)
		BEGIN
			SELECT TOP 1 @camId = camId
			FROM @camByUser
			WHERE isCheck = 0

			IF EXISTS (
					SELECT cam_id
					FROM ccoCallsOut
					WHERE cam_id = @camId
					)
			BEGIN
				INSERT INTO @tableExistsRec
				VALUES (
					@camId
					,1
					)
			END
			ELSE
			BEGIN
				INSERT INTO @tableExistsRec
				VALUES (
					@camId
					,0
					)
			END

			UPDATE @camByUser
			SET isCheck = 1
			WHERE camId = @camId
		END

		SELECT a1.cam_id
			,cam_Descripcion
			,cam_tNotas
			,cast(cam_ocupado AS INT) AS cam_ocupado
			,cam_noInt_ocupado
			,cam_inter_ocupado
			,cast(cam_nocontesto AS INT) AS cam_nocontesto
			,cam_noInt_nocontesto
			,cam_inter_nocontesto
			,cast(cam_fax AS INT) AS cam_fax
			,cam_noInt_fax
			,cam_inter_fax
			,cast(cam_modomanual AS INT) AS cam_modomanual
			,ANI
			,cam_ShowCalifWnd
			,cam_StartTimerOnHangUp
			,editableCallKey
			,cam_tNoContesta
			,iTipoDial
			,detectAnswerMachine
			,detectVoiceMail
			,compliance
			,cam_inter_graba
			,cam_noint_graba
			,cast(progDial AS TINYINT) progDial
			,cast(excCallBack AS TINYINT) excCallBack
			,dialOrder
			,dialPrefix
			,dialPrefixMan
			,dialPrefixXfe
			,listenManualCall
			,stopRecording
			,cast(abandonCallback AS TINYINT) abandonCallback
			,a3.frame
			,a1.t_autoCB
			,a1.id_anilist
			,a1.tDialonWrapUp
			,dbo.fn_viewMode(@User_id, 10) viewMode
			,cam_maxqueue AS queSize
			,DNCScrub
			,callerIdDesc
			,timeZoneRule
			,callsBySurvey
			,ivrScript
			,surveyPctg
			,isnull(a1.call_record, 1) AS call_record
			,cast(startStopRecording AS TINYINT) startStopRecording
			,leaveRecMessage
			,manualCallOnChat
			,callBackSurveyAgent
			,callBackSurveyClient
			,CASE 
				WHEN surveycamid IS NULL
					OR surveycamid = 0
					THEN 0
				ELSE 1
				END isRelationSurvey
			,isnull(a1.funcEspDtmf, 0)
			,isnull(sipHdrFormat,'''' ) sipHdrFormat
			,cam_inter_cancelled
			,prefijo
			,enbleprefix = CASE 
				WHEN existRec = 0
					THEN 1
				ELSE 0
				END
			,isnull(exitAssisted, 0) exitAssisted
			,isnull(previewDiscard, 0) PreviewDiscard	
			,isnull(CampType, 0) CampType
			,isnull(contact.conexionInfo, '''') conexionInfo
			,isnull(contact.connUser,'''' ) connUser
			,isnull(contact.closeConversationTime, 0) closeConversationTime
			,isnull(contact.answerTimeoutClient, 0) answerTimeoutClient
			,isnull(contact.allowFileAttachments, 0) allowFileAttachments
			,isnull(selectRotativeANI, 0) selectRotativeANI
			,ISNULL(rotativeAlgo, 0) rotativeAlgo
			,isnull(autoStart, 0) autoStart
			,isnull(messagingOrder, 0) messagingOrder
			,ISNULL(cam_tPreview, 0) AS CamTPreview
			,ISNULL(timesPreview, 0) AS TimesPreview
			,isnull(timesDiscard, 0) TimesDiscard
			,ISNULL(recordHold, 0) recordHold
			,isnull(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule
			,isnull(campsExtention.RecordCalls, 1) RecordCalls
			,isnull(campsExtention.simultaneousRecs, 1) simultaneousRecs
			,isnull(campsExtention.EditableContactData, 0) EditableContactData
			,@intenationalDialingPorts intenationalDialingPorts 
			,isnull(campsExtention.AssignConversationSameAgent, 0) AssignConversationSameAgent
		FROM ccCamps a1
		INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
		INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
		INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
		LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
		LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
		ORDER BY cam_descripcion

		RETURN (0)

		SET NOCOUNT OFF
		'
	EXEC(@sql)

	set @process = 'DEV2-406 K020138 drop sp ccsp_GalateaGetOutboundConfiguration'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetOutboundConfiguration'')
    begin
        DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
    end'
	EXEC(@sql)

	set @process = 'DEV2-406 K020138 create sp ccsp_GalateaGetOutboundConfiguration se agrega assignConversationSameAgent'
	set @sql = '

		CREATE PROCEDURE ccsp_GalateaGetOutboundConfiguration
		@adminID INT
		,@campID INT
		AS
		BEGIN
		DECLARE @AllCampaigns TABLE (
		cam_id SMALLINT
		,cam_Descripcion VARCHAR(60)
		,cam_tNotas SMALLINT
		,cam_ocupado SMALLINT
		,cam_noInt_ocupado SMALLINT
		,cam_inter_ocupado SMALLINT
		,cam_nocontesto SMALLINT
		,cam_noInt_nocontesto SMALLINT
		,cam_inter_nocontesto SMALLINT
		,cam_fax SMALLINT
		,cam_noInt_fax SMALLINT
		,cam_inter_fax SMALLINT
		,cam_modomanual SMALLINT
		,ANI VARCHAR(15)
		,cam_ShowCalifWnd BIT
		,cam_StartTimerOnHangUp BIT
		,editableCallKey BIT
		,cam_tNoContesta SMALLINT
		,iTipoDial SMALLINT
		,detectAnswerMachine SMALLINT
		,detectVoiceMail SMALLINT
		,compliance SMALLINT
		,cam_inter_graba SMALLINT
		,cam_noint_graba SMALLINT
		,progDial SMALLINT
		,excCallBack SMALLINT
		,dialOrder SMALLINT
		,dialPrefix VARCHAR(10)
		,dialPrefixMan VARCHAR(10)
		,dialPrefixXfe VARCHAR(10)
		,listenManualCall BIT
		,stopRecording BIT
		,abandonCallback BIT
		,frame SMALLINT
		,t_autoCB SMALLINT
		,id_anilist INT
		,tDialonWrapUp SMALLINT
		,viewMode TINYINT
		,queSize SMALLINT
		,DNCScrub INT
		,callerIdDesc VARCHAR(15)
		,timeZoneRule INT
		,callsBySurvey INT
		,ivrScript INT
		,surveyPctg INT
		,call_record SMALLINT
		,startStopRecording BIT
		,leaveRecMessage BIT
		,manualCallOnChat BIT
		,callBackSurveyAgent BIT
		,callBackSurveyClient BIT
		,isRelationSurvey BIT
		,funcEspDtmf INT
		,sipHdrFormat VARCHAR(255)
		,cam_inter_cancelled SMALLINT
		,prefijo VARCHAR(40)
		,enbleprefix BIT
		,exitAssisted BIT
		,previewDiscard BIT
		,CampType INT
		,conexionInfo VARCHAR(50)
		,connUser VARCHAR(15)
		,closeConversationTime INT
		,answerTimeoutClient INT
		,allowFileAttachments BIT
		,selectRotativeANI INT
		,rotativeAlgo TINYINT
		,autoStart BIT
		,messagingOrder BIT
		,CamTPreview SMALLINT
		,TimesPreview TINYINT
		,timesDiscard TINYINT
		,recordHold BIT
		,zipCodeSchedule BIT
		,RecordCalls tinyint
		,simultaneousRecs smallint
		,EditableContactData bit
		,internationalDialingPortsAssigned bit
		,AssignConversationSameAgent bit
		)
		DECLARE @numbers VARCHAR(max)

		SELECT @numbers = COALESCE(@numbers + '''', '''', '''''''') + number
		FROM ccWhatsAppNumbers
		WHERE camp_id = 0
		AND STATUS = 1

		INSERT INTO @AllCampaigns
		EXEC ccsp_RIAConfCamp @adminID
		,@campID

		SELECT dialPrefixMan DialPrefixMan
		,dialPrefixXfe DialPrefixXfe
		,listenManualCall ListenManualCall
		,stopRecording StopRecording
		,abandonCallback AbandonCallBack
		,t_autoCB AutoCB
		,id_anilist IdIstANI
		,tDialonWrapUp TDialOnWrapup
		,queSize Quesize
		,DNCScrub
		,callerIdDesc CallerIdDesc
		,timeZoneRule TimeZoneRule
		,callsBySurvey CallsBySurvey
		,ivrScript IvrScript
		,surveyPctg SurveyPctg
		,call_record CallRecord
		,startStopRecording StartStopRecording
		,leaveRecMessage LeaveRecMessage
		,manualCallOnChat ManualCallOnChat
		,callBackSurveyClient CallBackSurveyClient
		,callBackSurveyAgent CallBackSurveyAgent
		,funcEspDtmf FuncEspDtmf
		,sipHdrFormat SipHdrsCfg
		,dialPrefix DialPrefix
		,prefijo Prefix
		,dialOrder DialOrder
		,progDial ProgDial
		,cam_Descripcion CamDescription
		,cam_tNotas CamTnotas
		,cam_ocupado CamBusy
		,cam_noInt_ocupado CamNoIntBusy
		,cam_inter_ocupado CamInterBusy
		,cam_nocontesto CamNoAnswer
		,cam_noInt_nocontesto CamNoIntNoAnswer
		,cam_inter_nocontesto CamInterNoAnswer
		,(cam_inter_cancelled / 60) CamInterCancelled
		,cam_fax CamFax
		,cam_noInt_fax CamNoIntFax
		,cam_inter_fax CamInterFax
		,cam_modomanual CamModoManual
		,ANI
		,cam_StartTimerOnHangUp CamStartTimerOnHangUp
		,editableCallKey EditableCallKey
		,cam_tNoContesta CamTNoAnswer
		,iTipoDial CamIntensiveDialing
		,detectAnswerMachine DetectAnswerMachine
		,detectVoiceMail DetectVoiceMail
		,compliance Compliance
		,cam_inter_graba CamInterRecord
		,cam_noint_graba CamNoIntRecord
		,excCallBack ExcCallBack
		,cam_ShowCalifWnd CamShowCalifWnd
		,frame Frame
		,exitAssisted ExitAssistedDialMode
		,previewDiscard PreviewDiscard
		,CampType
		,conexionInfo ConexionInfo
		,connUser ConnUser
		,closeConversationTime CloseConversationTime
		,answerTimeoutClient MUTimeOutClient
		,allowFileAttachments AllowFileAttachments
		,CamTPreview
		,CAST(TimesPreview AS SMALLINT) TimesPreview
		,@numbers AS FreeNumbers
		,selectRotativeANI SelectRotativeANIManualCall
		,rotativeAlgo RotativeAlgo
		,autoStart AutoStart
		,messagingOrder MessagingOrder
		,timesDiscard TimesDiscard
		,recordHold RecordHold
		,zipCodeSchedule ZipCodeSchedule
		,RecordCalls RecordCalls
		,simultaneousRecs SimultaneousRecs
		,EditableContactData EditableContactData
		,internationalDialingPortsAssigned internationalDialingPortsAssigned
		,AssignConversationSameAgent AssignConversationSameAgent
		FROM @AllCampaigns
		WHERE cam_id = @campID
		END
			'
	EXEC(@sql)

	set @process = 'DEV2-406 K020138 drop sp ccsp_MetaWAOutboundTemplates'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_MetaWAOutboundTemplates'')
    begin
        DROP PROCEDURE ccsp_MetaWAOutboundTemplates
    end'
	EXEC(@sql)

	set @process = 'DEV2-406 K020138 create sp ccsp_MetaWAOutboundTemplates'
	set @sql = '
		CREATE PROCEDURE [dbo].[ccsp_MetaWAOutboundTemplates]
		@action TINYINT = NULL,
		@whatsAppTemplateID INT = 0,
		@id varchar(200) = NULL,
		@Category varchar(50) = NULL,
		@TemplateName varchar(200) = NULL,
		@AllowCategoryChange tinyint = NULL,
		@LanguageCode varchar(10)= NULL,
		@Status varchar(200)= NULL, 
		@header nvarchar(max)= null,
		@body nvarchar(max) = null,
		@footer nvarchar(max) = null,
		@buttons nvarchar(max) = null
	AS
	BEGIN
		IF(@action = 1)
		BEGIN
		print 1
		END
		ELSE IF(@action = 2)
		BEGIN
		print 2
		END
		ELSE IF(@action = 4) --create
		BEGIN
			insert into ccMetaWAOutboundTemplates (Id, Category,TemplateName,AllowCategoryChange,LanguageCode,Status,header,body,footer,buttons)
								values (@Id, @Category,@TemplateName,@AllowCategoryChange,@LanguageCode,@Status,@header,@body,@footer,@buttons)
		END
	END
   '
	EXEC(@sql);
	
	set @process = 'DEV2-406 K020138 drop sp ccsp_WhatsAppValidationAndConfig'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_WhatsAppValidationAndConfig'')
    begin
        DROP PROCEDURE ccsp_WhatsAppValidationAndConfig
    end'
	EXEC(@sql)

	set @process = 'DEV2-406 K020138 create sp ccsp_WhatsAppValidationAndConfig'
	set @sql = '
	create procedure ccsp_WhatsAppValidationAndConfig
	@action int,
	@camId int=0,
	@phoneNumber varchar(20)='''',
	@TemplateName varchar(512)='''',
	@RemovalDate datetime = null
	as
	begin
		if (@action = 1)
		begin
		 select WAAccountId, Token,PhoneNumberId from ccMetaWhatsAppNumbers with (nolock) where Number=@phoneNumber
		end
		if(@action = 2)
		begin
		 select top (1) Id from ccMetaWAOutboundTemplates with (nolock) where TemplateName=@TemplateName or ( TemplateName=@TemplateName and RemovalDate >= @RemovalDate)
		end
	end
	'
	EXEC(@sql)
	
	


	------------------------------------------------Fin Modificar sp-----------------------------------------------------

	        ----------------------------------------------------- BEGIN Gaby ---------------------------------------------------------------


    SET @process = 'Whatsapp Masivo - Create new table for Url Meta'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ccMetaWhatsAppConfigurations'')
                BEGIN
                    CREATE TABLE ccMetaWhatsAppConfigurations(
						Id int PRIMARY KEY not null,
						Url varchar(150) not null,
						Description varchar(200)
					)
                END;'
    EXEC(@sql);

    SET @process = 'Whatsapp Masivo - Create new table for WhatsApp numbers'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ccMetaWhatsAppNumbers'')
                BEGIN
                    CREATE TABLE ccMetaWhatsAppNumbers
					(
						MetaId int identity(1,1),
						Number varchar(30) PRIMARY KEY not null,
						Status int,
						Inbound_Id smallint FOREIGN KEY(Inbound_id) REFERENCES ccInbound(Inbound_id) null,
						Cam_Id smallint FOREIGN KEY(cam_id) REFERENCES ccCamps(cam_id) null,
						PhoneNumberId varchar(100),
						Token varchar(max)
					)
                END;'
    EXEC(@sql);


    SET @process = 'Whatsapp Masivo - Create new table for Whatsapp messages'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ccWhatsAppOutSource'')
                BEGIN
                    CREATE TABLE ccWhatsAppOutSource(
						WAOut_Id bigint PRIMARY KEY IDENTITY(1,1) NOT NULL,
						CallKey varchar(40) NOT NULL,
						camId int NOT NULL,
						PhoneNumber varchar(30),
						Status int NOT NULL,
						TimeZone int NOT NULL,
						TimeZone_Summer int NOT NULL,
						List_id int NOT NULL,
						User_id smallint NOT NULL,
						TemplateId int NOT NULL,
						componentJson varchar(max) NOT NULL
					)
                END;'
    EXEC(@sql);

    SET @process = 'Whatsapp Masivo - Create new table for WhatsApp messages load'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ccoWAWorkingTable'')
                BEGIN
	                CREATE TABLE ccoWAWorkingTable(
						WAOut_id bigint PRIMARY KEY NOT NULL,
						PhoneNumber varchar(30) NOT NULL,
						Callkey varchar(60) NOT NULL,
						CamId int NOT NULL,
						WaStatus int NOT NULL,
						dateDial datetime NOT NULL,
						UserId int NOT NULL,
						TimeZone int NOT NULL,
						TimeZone_Summer int NOT NULL
					)
                END;'
    EXEC(@sql);

    SET @process = 'Whatsapp Masivo - Create new table for Whatsapp messages log'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ccoWhatsLogDials'')
                BEGIN
                    CREATE TABLE ccoWhatsLogDials(
						MetaId varchar(1000) NOT NULL,
						WaOutId bigint NOT NULL,
						CamId smallint NOT NULL,
						RegistryClient varchar(40) NOT NULL,
						PhoneClient varchar(50) NOT NULL,
						PhoneWa varchar(50) NOT NULL,
						Type varchar(20),
						Contented varchar(1000),
						Bill decimal(10,4) NOT NULL,
						TimeSpam datetime NOT NULL,
						ConversationId bigint,
					 	ErrorCode int,
						ErrorMessage varchar(1000),
						Status varchar(100) NOT NULL
					)
                END;'
    EXEC(@sql);


	SET @process = 'WhatsApp Masivo - Drop SP ccspOutboundWhatsApp'
	SET @sql = '
	    if exists (select * from sys.procedures where name = N''ccspOutboundWhatsApp'')
	    begin
	        DROP PROCEDURE ccspOutboundWhatsApp;
	    end'
	EXEC(@sql);

	SET @process = 'WhatsApp Masivo - Create SP ccspOutboundWhatsApp'	
	SET @sql='
		create procedure ccspOutboundWhatsApp
		@action int,
		@camId int = null
		as
		if @action=1 begin
			declare @Url as varchar(50)
			set @Url = (select Url from ccMetaWhatsAppConfigurations where Id=1)

			select distinct cast(c. cam_id as int) as CamId,cam_descripcion as [Name],cam_procesando as [Start],Number as PhoneNumber, 
			case cam_procesando when 0 then '''' else REPLACE(@Url, ''phoneId'', PhoneNumberId) end as Url, Token
			from ccCamps c with(nolock)
			left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
			left join  ccCampsHorarios s ON s.cam_id = c.cam_id
			left join ccMetaWhatsAppNumbers wn on wn.cam_id = c.cam_id
			WHERE CampType=5 AND c.IDArea IS NOT NULL AND(@camId IS NULL or @camId=0 OR c.cam_id = @camId)
	    end
	'
	EXEC(@sql)

	SET @process = 'WhatsApp Masivo - Drop SP ccsp_WAOUTGetNewJobs'
	SET @sql = '
	    if exists (select * from sys.procedures where name = N''ccsp_WAOUTGetNewJobs'')
	    begin
	        DROP PROCEDURE ccsp_WAOUTGetNewJobs;
	    end'
	EXEC(@sql);

	SET @process = 'WhatsApp Masivo - Create SP ccsp_WAOUTGetNewJobs'	
	SET @sql='
		CREATE PROCEDURE ccsp_WAOUTGetNewJobs
@campId INT,
@action INT=0, --0 select and update, 1 select registry
@topCount INT=80

as
set nocount on
DECLARE @iZonas INT = NULL
DECLARE @bIsDaylight bit, @revHorario bit
DECLARE @country_id INT, @TipoJobs INT

DECLARE @sql nvarchar(MAX), @Order_Asc_Desc char(4)
declare @sqlInsertGeneric nvarchar(MAX)
declare @parameters nvarchar(MAX)
		
-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
SELECT @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@campId
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
SELECT @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

exec @iZonas= ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0

if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
begin
	if @iZonas = 0 begin
		SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
		return
	end
end


IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS

CREATE TABLE #NEW_JOBS (
	WAOutId INT
	,CamId INT
	,Phone VARCHAR(30) collate SQL_Latin1_General_CP1_CI_AS
	,Status TINYINT
	,DateDial DATETIME	
	,Tz1 INT
	,CallKey VARCHAR(40)	
	,Components NVARCHAR(4000)
	)
set @sql=''''

DECLARE @new_calls_date VARCHAR(max) = '''';
		

SELECT @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

DECLARE @isVerano varchar(max)

	set @isVerano = ''W.TimeZone'' + case @bIsDaylight when 1 then ''_summer'' else '''' END

	

	select @sqlInsertGeneric=nchar(13)+ ''INSERT #NEW_JOBS
SELECT top(@topCount) W.waout_id, W.CamId, W.phoneNumber, W.WaStatus,W.dateDial,''
+@isVerano+'',
w.callkey,
wos.componentJson
FROM ccoWAWorkingTable W 
inner join ccWhatsAppOutSource wos (nolock) on wos.waout_id=W.waout_id
WHERE WaStatus in (0)
and W.CamId=@campId
and (
   ( (''+@isVerano+''  & @iZonas)>0 or ''+@isVerano+''=0) 
)
order by W.dateDial ''+ @Order_Asc_Desc +'', waout_id ''+ @Order_Asc_Desc

----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
set @parameters=''@CAMPID int,@topCount int,@iZonas int''		

	
SELECT @sql=@sql+nchar(13)+ ''update ccoWAWorkingTable with (rowlock) SET WaStatus=1 where WAOut_id in(select WaOutId from #NEW_JOBS)''	


		
select @sql=@sql+nchar(13)+ ''SELECT WaOutId, CamId, Phone, Status, DateDial,
Tz1,CallKey as RegistryClient,Components as MessageJson
FROM #NEW_JOBS where len(Phone)>0
''

print (@sql)

exec sp_executesql  @sql,@parameters,
@CAMPID=@CAMPID
,@topCount=@topCount
,@iZonas=@iZonas

IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS

return(0)
	'
	EXEC(@sql)

	SET @process = 'WhatsApp Masivo - Drop SP ccsp_WAOUTResetJobs'
	SET @sql = '
	    if exists (select * from sys.procedures where name = N''ccsp_WAOUTResetJobs'')
	    begin
	        DROP PROCEDURE ccsp_WAOUTResetJobs;
	    end'
	EXEC(@sql);

	SET @process = 'WhatsApp Masivo - Create SP ccsp_WAOUTResetJobs'	
	SET @sql='
		CREATE PROCEDURE ccsp_WAOUTResetJobs
                    @camid AS INT= 0
                    AS
                    BEGIN

                      CREATE TABLE #TempccoLogDials ( 
                        waout_id INT, PRIMARY KEY (waout_id)
                      );
                      DECLARE @today DATETIME;

                      SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);
                      
                      IF @camid = 0
                      BEGIN
                        INSERT INTO #TempccoLogDials
                             SELECT WaOutId
                             FROM ccoWhatsLogDials AS ld WITH(NOLOCK)
                             WHERE TimeSpam >= @today
                             GROUP BY WaOutId;
                      END;
                         ELSE
                        IF @camid > 0
                        BEGIN
                          INSERT INTO #TempccoLogDials
                               SELECT WaOutId
                               FROM ccoWhatsLogDials AS ld WITH(NOLOCK)
                               WHERE CamId = @camid AND 
                                 TimeSpam >= @today
                               GROUP BY WaOutId;
                        END;

                      IF @camid = 0
                      BEGIN
                        -- NUEVAS - Nunca se han marcado
                        UPDATE ccoWAWorkingTable 
                          SET WaStatus = 0
                        WHERE WaStatus = 1;
                      END;
                         ELSE
                      BEGIN  
                        -- NUEVAS - Nunca se han marcado
                        UPDATE ccoWAWorkingTable WITH(ROWLOCK)
                          SET WaStatus = 0
                        WHERE WaStatus = 1 AND 
                            CamId = @camid;
                      END;

                      UPDATE c
                      SET c.cam_procesando = 0
                      FROM ccCamps c
                      WHERE c.cam_id = @camid
                      

                      DROP TABLE #TempccoLogDials;
                    END;
	'
	EXEC(@sql)


	SET @process = 'WhatsApp Masivo - Create SP '	
	SET @sql='
		IF NOT EXISTS(SELECT 1 FROM ccMetaWhatsAppConfigurations WHERE Id = 1)
        BEGIN
            insert into ccMetaWhatsAppConfigurations(Id,Url,Description)
			values (1,''https://graph.facebook.com/v19.0/phoneId/messages'',''Url para envío de mensajes. PhoneId hace referencia al Id de Número de teléfono'')
        END
	'
	EXEC(@sql)



	SET @process = 'Whatsapp Masivo - Add setting for messages per second'
    SET @sql = '
        IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 270)
        BEGIN
            insert into ccSettings2(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
			values (270, 80, ''Mensajes de WhatsApp por segundo (default: 80, max: 1000, min: 1)'', 1, ''GRL'', ''Mensajes de WhatsApp por segundo (default: 80, max: 1000, min: 1)'',''Mensajes de WhatsApp por segundo (default: 80, max: 1000, min: 1)'',0,''.*'')

        END'
    EXEC(@sql);    
    

        

--------------------------------------------------------------------- END Gaby --------------------------------------------------------------------------
	------------------------------------------------Inicio Crear Sp de actualizacion de plantillas por webhook-----------------------------------------------------
	set @process = 'Se elimina ccsp_WhatsappTemplatesStatus si existe'
	set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_WhatsappTemplatesStatus'')begin
					DROP PROCEDURE ccsp_WhatsappTemplatesStatus
				end
	'
	EXEC(@sql)
	
	set @process = 'Se crea sp ccsp_WhatsappTemplatesStatus para actualizar el estado de las plantillas y la calidad mediante los cambios que llegan al webhook'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_WhatsappTemplatesStatus]
						@action as smallint,
						@messageId as bigint = 0,
						@status as varchar(30) = '''',
						@notes as varchar(500) = '''',
						@quality as int = 0

						AS
						IF(@action = 0) begin
							update ccMetaWAOutboundTemplates set Status = @status, notes = @notes where Id = @messageId
						end
						IF(@action = 1) begin
							declare @isPendingQuality bit; 
							select @isPendingQuality=IsPendingQuality from  ccMetaWAOutboundTemplates where Id = @messageId;
							if(@isPendingQuality = 1) update ccMetaWAOutboundTemplates set quality = @quality, IsPendingQuality = 0 where Id = @messageId 
							else update ccMetaWAOutboundTemplates set quality = @quality where Id = @messageId
						end'
	EXEC(@sql)
	------------------------------------------------Fin Crear Sp de actualizacion de plantillas por webhook-----------------------------------------------------
	------------------------------------------------Inicio Crear Tabla para configuraciones de los webhooks-----------------------------------------------------
	set @process = 'Se elimina ccMetaWebhooksConfigurations si existe'
	set @sql = 'IF EXISTS (SELECT * FROM sys.tables WHERE name = N''ccMetaWebhooksConfigurations'') begin
					DROP TABLE ccMetaWebhooksConfigurations
				end
	'
	EXEC(@sql)
	set @process = 'Se crea ccMetaWebhooksConfigurations para guardar los token necesarios'
	set @sql = 'CREATE TABLE ccMetaWebhooksConfigurations (
						Id int NOT NULL,
						Controller varchar(150) NOT NULL,
						Token varchar(max)
					);'
	EXEC(@sql)
	------------------------------------------------Fin Crear Tabla para configuraciones de los webhooks-----------------------------------------------------
	----------------------------------------------------------Begin David------------------------------------------------------------------------------------
	set @process = 'Se actualiza SP para que se tome infromación de tablas ccWhatsAppOutSource y ccoWAWorkingTable'
	set @sql = '
	ALTER PROCEDURE [dbo].[ccsp_GalateaGetCampsNvosCB]
	@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
	@regval int =0, @tcpa int=0
	as
	set nocount on

	declare @TipoJobs as int, @isExecOutbound bit

	set @isExecOutbound= case when @regval=0 then 0 else 1 end

	-- Actualiza todas las camps
	if @Tipo in (1,2) begin

	declare @id AS INTEGER;

	CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,campType INT)
	CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime,campType INT)

	create table #tempoutsource (cam_id int,Pend  int)

	create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

	if @cam_id = 0 begin
		if @user_id > 0 and not exists (select 1 from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
			select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
			,isnull(cam.CampType,0) as CampType
			from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
			where user_id = @user_id and tipo = 1
		end
		else begin
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
			select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
			,isnull(cam.CampType,0) as CampType
			from ccCamps cam (nolock)
		end
	end
	else begin
		if @Tipo = 2
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
			select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
			,isnull(cam.CampType,0) as CampType
			from ccCamps cam with(nolock) 
			where cam.cam_id = @cam_id
		else
			if @user_id > 0 and not exists (select 1 from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
				select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
				,isnull(cam.CampType,0) as CampType
				from ccCamps cam with(nolock) 
				inner join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
				where user_id = @user_id and tipo = 1 and cam.cam_id = @cam_id
			end
			else begin
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
				select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
				,isnull(cam.CampType,0) as CampType
				from ccCamps cam (nolock) 
				where cam_activo=1  and cam.cam_id = @cam_id
			end
	end
    
	;with ccCampsNvosCBTmp as(
	select A.*,dateUpdate from #Tcamps A
	left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
	where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null
	)
	insert into #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate,campType)
	select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate),max(campType) as campType 
	from ccCampsNvosCBTmp
	group by cam_id

	if exists(select 1 from #Tcamps2) BEGIN

		if exists(select 1 from #Tcamps2 where campType=7) BEGIN
			insert into #tempoutsource(cam_id,Pend)
			SELECT sos.cam_id, count(sos.cam_id) as Pend
			FROM dbo.smsOutSource AS sos with(nolock)
			inner join #Tcamps2 tcam on sos.cam_id = tcam.cam_id
			WHERE tcam.campType=7 and sos.sms_status in(0, 7)
			GROUP BY sos.cam_id

			insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
			SELECT swt.cam_id,
			count(case swt.sms_status when 0 then 1 else null end) as New,
			count(case swt.sms_status when 1 then 1 else null end) as Cb,
			count(case swt.sms_status when 2 then 1 else null end) as Pro,
			count(case swt.sms_status when 3 then 1 else null end) as Fin
			FROM dbo.smsWorkingTable AS swt  with(index(IX_smsWorkingTable_1),nolock)
			inner join #Tcamps2 B on swt.cam_id = B.cam_id 
			where B.campType=7
			GROUP BY swt.cam_id 
		end
		if exists(select 1 from #Tcamps2 where campType=5) BEGIN
			insert into #tempoutsource(cam_id,Pend)
			SELECT wos.camid, count(wos.camid) as Pend
			FROM dbo.ccWhatsAppOutSource AS wos with(nolock)
			inner join #Tcamps2 tcam on wos.camid = tcam.cam_id
			WHERE tcam.campType=5 and wos.Status = 0 
			GROUP BY wos.camid  

			insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
			SELECT wwt.camid,
			count(case wwt.WaStatus when 0 then 1 else null end) as New, 0, 0, 0
			FROM dbo.ccoWAWorkingTable AS wwt  
			inner join #Tcamps2 B on wwt.camid = B.cam_id 
			where B.campType=5
			GROUP BY wwt.camid 
		end		    
			insert into #tempoutsource(cam_id,Pend)
			SELECT ccos.cam_id, count(ccos.cam_id) as Pend
			FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
			join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
			WHERE tcam.campType<>7 and tcam.campType<>5 and cal_status in(0, 7)
			GROUP BY ccos.cam_id

			insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
			SELECT A.cam_id,
			count(case cal_status when 0 then 1 else null end) as New,
			count(case cal_status when 1 then 1 else null end) as Cb,
			count(case cal_status when 2 then 1 else null end) as Pro,
			count(case cal_status when 3 then 1 else null end) as Fin
			FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
			inner join #Tcamps2 B on A.cam_id = B.cam_id
			WHERE B.campType<>7 and B.campType<>5
			GROUP BY A.cam_id   
        
		if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
			update #Tcamps2 set status =1,cantidad=0  where cam_id = @cam_id
		end        

		declare @TotalNew table(
			cam_id int primary key,
			OverallTotalNew int 
			)
        


			insert into @TotalNew
		select CampNvosCB.id,max(isnull( CASE WHEN CampNvosCB.OverallTotalNew = 0 THEN NULL ELSE CampNvosCB.OverallTotalNew END,CampNvosCB.new) )
		from ccCampsNvosCB CampNvosCB with(nolock)
		inner join #Tcamps2 tcamp on CampNvosCB.id = tcamp.cam_id
		group by CampNvosCB.id

			delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
			where CampNvosCB.id = tcamp.cam_id

			INSERT into ccCampsNvosCB 
		SELECT distinct cams.cam_id, cams.cam_descripcion,
			isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
			isNull(cs.Pend,0) as pend,
			isNull(wt.Pro,0) as pro,
			isNull(cams.procesando,0) cam_procesando,
			isNull(cams.cam_tipojobs,0) cam_tipojobs,
			isNull(wt.Fin,0) Fin,
			isNull(cams.cantidad,0) cantidad,
			getdate(),
			isnull(T.OverallTotalNew,0)  as OverallTotalNew
			FROM #Tcamps2 cams with(nolock)
			LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
			LEFT JOIN #tempoutsource cs on cams.cam_id = cs.cam_id
			LEFT JOIN @TotalNew  T on T.cam_id = cams.cam_id

	end

	if @isExecOutbound = 0 begin

	if @Tipo = 2 begin
		-- devuelve resultado de la taba, solo las camps del usuario
		SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, 
		isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor, OverallTotalNew
		FROM #Tcamps tcam
		left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
	end
	else 
		SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,
		cc.aggressionFactor, OverallTotalNew
		FROM ccCampsNvosCB res (nolock)
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
		WHERE res.id = @cam_id
	end

	drop table #Tcamps
	drop table #Tcamps2
	drop table #tempoutsource
	drop table #temWorkinTable

	return(0)

	end

	set nocount off'
	EXEC(@sql)
	-----------------------------------------------------------End David-------------------------------------------------------------------------------------

	----------------------------------------------------------- Start Rod Salazar -------------------------------------------------------------------------------

	set @process = 'K020113 se borra sp ccsp_RIAAdmDelRegs'
	set @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIAAdmDelRegs'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_RIAAdmDelRegs
	END'
	EXEC(@sql)

	set @process = 'K020113 se crea sp ccsp_RIAAdmDelRegs'
	set @sql = '
	CREATE PROCEDURE [dbo].[ccsp_RIAAdmDelRegs]
	@tipoDel int, -- 1 Registros Nuevos / 2 Registros CallBack / 3 Registros sin meter a WT / 4 Registros CallBack - Excepto los programados por Agentes
	@cam_id int,
	@phone varchar(30) = '''',
	@calkey varchar(40) = '''',
	@exact bit = 1
	AS

	if @tipoDel = 1 --nuevos
	 begin
		delete ccoWorkingTable where cam_id = @cam_id and cal_status = 0
	 end

	if @tipoDel = 2 --callbacks
	 begin
	
		delete from ccRIAUpdateCallBack_Abandon where callout_id in(select callout_id from ccoWorkingTable with(nolock) where cam_id = @cam_id and cal_status = 1)
		delete ccoWorkingTable where cam_id = @cam_id and cal_status = 1
	 end

	if @tipoDel = 3 -- 3 Registros sin meter a WT
	 begin
		update ccocallsoutsource --with(rowlock)
		set cal_Status = 5 
		where cam_id = @cam_id 
		and cal_status in(0, 7)

		Delete ccUploadTemporal where cam_id = @cam_id
	 end

	if @tipoDel = 4 --callbacks
	 begin
		delete ccoWorkingTable where cam_id = @cam_id and cal_status = 1 and user_id=0
	 end

	if @tipoDel = 5 --callbacks
	 begin
		delete ccoWorkingTable where cam_id = @cam_id and cal_status = 3
	 end

	if @tipoDel = 6 -- Delete a record from a specific campaign containing a specific phone number
	begin   
		delete ccoWorkingTable --with(rowlock) 
		where callout_id in (select callout_id 
								from ccocallsoutsource with(nolock)
								where cam_id = @cam_id 
								and (cal_telefono = @phone or 
										cal_telefono2 = @phone or 
										cal_telefono3 = @phone or 
										cal_telefono4 = @phone or 
										cal_telefono5 = @phone))

		update ccocallsoutsource --with(rowlock)
		set cal_Status = 5 
		where cam_id = @cam_id  and 
			(cal_telefono = @phone or 
			cal_telefono2 = @phone or 
			cal_telefono3 = @phone or 
			cal_telefono4 = @phone or 
			cal_telefono5 = @phone)

	end

	if @tipoDel = 7 -- Delete all the records from a specific campaign
	begin
		delete from ccoWorkingTable where cam_id = @cam_id

		update ccocallsoutsource set cal_Status = 5 where cam_id = @cam_id
	end

	if @tipoDel = 8 --delete records by specific callkey
	 begin
		if @exact = 1
			delete ccoWorkingTable with(rowlock) where cal_keyw = @calkey and cal_status <> 2
		else
			delete ccoWorkingTable with(rowlock) where cal_keyw like ''%'' + @calkey + ''%'' and cal_status <> 2
	 end

	 if @tipoDel = 9 --delete records by specific callkey
	 begin
		delete from ccoWAWorkingTable where CamId = @cam_id and WaStatus = 0		

		select @@rowcount
	end'
	EXEC(@sql)
	----------------------------------------------------------- End Rod Salazar -------------------------------------------------------------------------------


 	
        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        --EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        --EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        /* Error generated based on sintax */ 
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR)  + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()
        RAISERROR (@errorGenerated, 11, 1)
        ROLLBACK TRAN
    END CATCH
END 
