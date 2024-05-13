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
--SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 6
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
    	

	



	-----------------------------------------------Frida Orta Begin ----------------------------------------------------------------------------------
	set @process = 'DEV2-476 K020029 Setting 272 '
	set @sql = '
	if not exists(select setting_id from ccSettings2 where setting_id = 272)
	begin
		insert into ccSettings2 (setting_id,valor,status,descripcion,Tipo,detalle,description) values (272,''3|90'',1, ''Reintentos para envío de mensajes de WhatsApp |Intervalo de reintentos'',''GRL'',''Reintentos para envío de mensajes WhatsApp (default: 3, max: 10) | Intervalo de reintentos para envío de plantillas WhatsApp (default: 90 s, min: 1 s)'',''Retries for WhatsApp outgoing messages (default: 3, max: 10) | Retry interval for WhatsApp templates (default: 90 s, min: 1 s)'')
	end
	'
	EXEC(@sql)

	set @process = 'Drop SP ccsp_GalateaDeleteCampaignAndACD '
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GalateaDeleteCampaignAndACD'')
    begin
        DROP PROCEDURE ccsp_AgentDataACD;
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

	set @process = 'DEV2-406 K020138 Add column AssignConversationSameAgent'
	set @sql = '
	if not exists (select * from sys.columns where name = N''AssignConversationSameAgent'' and Object_ID = Object_ID(N''ccCampsExtend''))
    begin
        alter table ccCampsExtend add  AssignConversationSameAgent bit null
    end'
	EXEC(@sql)

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
			''
		DECLARE @camByUser TABLE (
			camId INT PRIMARY KEY
			,isCheck BIT
			''
		DECLARE @camId INT
			,@id INT;
		DEClARE @intenationalDialingPorts bit;
		declare @tempInternationalCode int
 
		if((select COUNT(*'' from ( select  top 1 IdCode from ccoDialers ccoDial inner join ccoDialerCamp ccoDialCamp on ccoDialCamp.dialer_id = ccoDial.dialer_id where ccoDialCamp.cam_id = @campID and ccoDial.DialingType=0  '' result '' > 0''
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
				''
		BEGIN
			INSERT INTO @camByUser
			SELECT *
				,0
			FROM dbo.fGet_CampAcd_Area(@User_id, 1'' B
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
					''
				AND (
					@campID IS NULL
					OR cam_id = @campID
					''
		END

		WHILE EXISTS (
				SELECT *
				FROM @camByUser
				WHERE isCheck = 0
				''
		BEGIN
			SELECT TOP 1 @camId = camId
			FROM @camByUser
			WHERE isCheck = 0

			IF EXISTS (
					SELECT cam_id
					FROM ccoCallsOut
					WHERE cam_id = @camId
					''
			BEGIN
				INSERT INTO @tableExistsRec
				VALUES (
					@camId
					,1
					''
			END
			ELSE
			BEGIN
				INSERT INTO @tableExistsRec
				VALUES (
					@camId
					,0
					''
			END

			UPDATE @camByUser
			SET isCheck = 1
			WHERE camId = @camId
		END

		SELECT a1.cam_id
			,cam_Descripcion
			,cam_tNotas
			,cast(cam_ocupado AS INT'' AS cam_ocupado
			,cam_noInt_ocupado
			,cam_inter_ocupado
			,cast(cam_nocontesto AS INT'' AS cam_nocontesto
			,cam_noInt_nocontesto
			,cam_inter_nocontesto
			,cast(cam_fax AS INT'' AS cam_fax
			,cam_noInt_fax
			,cam_inter_fax
			,cast(cam_modomanual AS INT'' AS cam_modomanual
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
			,cast(progDial AS TINYINT'' progDial
			,cast(excCallBack AS TINYINT'' excCallBack
			,dialOrder
			,dialPrefix
			,dialPrefixMan
			,dialPrefixXfe
			,listenManualCall
			,stopRecording
			,cast(abandonCallback AS TINYINT'' abandonCallback
			,a3.frame
			,a1.t_autoCB
			,a1.id_anilist
			,a1.tDialonWrapUp
			,dbo.fn_viewMode(@User_id, 10'' viewMode
			,cam_maxqueue AS queSize
			,DNCScrub
			,callerIdDesc
			,timeZoneRule
			,callsBySurvey
			,ivrScript
			,surveyPctg
			,isnull(a1.call_record, 1'' AS call_record
			,cast(startStopRecording AS TINYINT'' startStopRecording
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
			,isnull(a1.funcEspDtmf, 0''
			,isnull(sipHdrFormat, '''' sipHdrFormat
			,cam_inter_cancelled
			,prefijo
			,enbleprefix = CASE 
				WHEN existRec = 0
					THEN 1
				ELSE 0
				END
			,isnull(exitAssisted, 0'' exitAssisted
			,isnull(previewDiscard, 0'' PreviewDiscard	
			,isnull(CampType, 0'' CampType
			,isnull(contact.conexionInfo, '''' conexionInfo
			,isnull(contact.connUser, '''' connUser
			,isnull(contact.closeConversationTime, 0'' closeConversationTime
			,isnull(contact.answerTimeoutClient, 0'' answerTimeoutClient
			,isnull(contact.allowFileAttachments, 0'' allowFileAttachments
			,isnull(selectRotativeANI, 0'' selectRotativeANI
			,ISNULL(rotativeAlgo, 0'' rotativeAlgo
			,isnull(autoStart, 0'' autoStart
			,isnull(messagingOrder, 0'' messagingOrder
			,ISNULL(cam_tPreview, 0'' AS CamTPreview
			,ISNULL(timesPreview, 0'' AS TimesPreview
			,isnull(timesDiscard, 0'' TimesDiscard
			,ISNULL(recordHold, 0'' recordHold
			,isnull(campsExtention.zipCodeSchedule, 0'' ZipCodeSchedule
			,isnull(campsExtention.RecordCalls, 1'' RecordCalls
			,isnull(campsExtention.simultaneousRecs, 1'' simultaneousRecs
			,isnull(campsExtention.EditableContactData, 0'' EditableContactData
			,@intenationalDialingPorts intenationalDialingPorts 
			,isnull(campsExtention.AssignConversationSameAgent, 0'' AssignConversationSameAgent
		FROM ccCamps a1
		INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id''
		INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id''
		INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
		LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
		LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
		ORDER BY cam_descripcion

		RETURN (0''

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

	

	-------------------------------------------------- Frida Orta End -----------------------------------------------------------------------------------
 	
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
