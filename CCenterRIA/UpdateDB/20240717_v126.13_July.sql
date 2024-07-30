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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 13
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
		MetaId INT NULL,
		RemovalDate datetime NULL,
		IdFile varchar(200),
		StatusCW BIT NULL,
		quality INT NULL,
		notes VARCHAR(500) NULL,
		FilePath varchar(1024) NULL,
		IsPendingQuality bit NOT NULL DEFAULT 1
	) 
    end'
	EXEC(@sql)
	
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
						Token varchar(max),
						WAAccountId varchar(30) null,
                        IdApp varchar(30) null
					)
                END;'
    EXEC(@sql);
	
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

	SET @process = 'K020149-Configuración de campaña-Límite máximo de conversaciones en cola al crear campaña WhatsApp salida, add maxLimitQueConversations to contactMeanOutTable Marco Garcia'
	SET @sql = 'IF not exists (SELECT * FROM SYS.columns WHERE name=''maxLimitQueueConversations'' AND OBJECT_ID = OBJECT_ID(''contactMeanOut''))
		begin
			alter table contactMeanOut add maxLimitQueueConversations smallint null
		end'

	EXEC(@sql)

	SET @process = 'K020111 add LoadBySegment to LoadBySegment Marco Garcia'
	SET @sql = 'IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccRIALoading'' and COLUMN_NAME = ''LoadBySegment'')
	BEGIN
		ALTER TABLE ccRIALoading ADD LoadBySegment bit
	END'

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

	SET @process = 'K020149-Configuración de campaña-Límite máximo de conversaciones en cola al crear campaña WhatsApp salida, add new identifiers to relatrionTableColumnIdentifiers table Marco Garcia'
	SET @sql = 'IF NOT EXISTS(SELECT 1 FROM relationTableColumnIdentifiers WHERE Identifiers = ''OUT_WHATS_MAX_LIMIT_QUEUE_CONVERSATIONS'')
	                    BEGIN
	                        insert into relationTableColumnIdentifiers(Identifiers,tableName,colunName)
	                        values(''OUT_WHATS_MAX_LIMIT_QUEUE_CONVERSATIONS'', ''contactMeanOut'', ''maxLimitQueueConversations'')
	                    END'
	EXEC(@sql);

	SET @process = 'K020149-Configuración de campaña-Límite máximo de conversaciones en cola al crear campaña WhatsApp salida, add new identifiers to ccGalateaIdentifiers table Marco Garcia'
	SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''OUT_WHATS_MAX_LIMIT_QUEUE_CONVERSATIONS'')
	                    BEGIN
	                        INSERT INTO dbo.ccGalateaIdentifiers
							(
								Description,
								TagEs,
								TagEn,
								TagPt
							)
							VALUES
							(   ''OUT_WHATS_MAX_LIMIT_QUEUE_CONVERSATIONS'', 
								''Número máximo en espera'',
								''Maximum conversations in queue'',
								''Número máximo na fila''
								)
	                    END'
	EXEC(@sql);


	SET @process = 'K020032-Permiso de usuario plantillas de META permission added to manage meta templates. Marco Garcia'
	SET @sql = 'IF not exists (select 1 from ccPermissions where Description = ''Gestionar plantillas de Meta'' )
	begin
		Insert into ccPermissions values((SELECT MAX(Permissions_id) + 1
		FROM ccPermissions),''Gestionar plantillas de Meta'',''RolesPermissionManageMetaTemp'',0,0,0,''N/A'',1)
	END
	if not exists (select 1 from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = (select Permissions_Id from ccPermissions where Description = ''Gestionar plantillas de Meta''))
	begin
		INSERT INTO ccRoles_Permissions values (1,(select Permissions_Id from ccPermissions where Description = ''Gestionar plantillas de Meta''))
	end'

	EXEC(@sql);

	SET @process = 'K020148-Carga BD WhatsApp salida-Detalle INSERT INTO tableLangueDbLoader tag = description-empty, languageId=0 Marco Garcia'
        SET @sql = '
		if not exists(select tag from tableLangueDbLoader where tag = ''description-empty'' and languageId=0)
		begin
			insert into tableLangueDbLoader (languageId,tag, translate) values (0,''description-empty'',''Teléfono vacío o incompleto'')
		end'
        EXEC(@sql);

SET @process = 'K020148-Carga BD WhatsApp salida-Detalle INSERT INTO tableLangueDbLoader tag = description-empty, languageId=1 Marco Garcia'
        SET @sql = '
		if not exists(select tag from tableLangueDbLoader where tag = ''description-empty'' and languageId=1)
		begin
			insert into tableLangueDbLoader (languageId,tag, translate) values (1,''description-empty'',''Incomplete or missing number'')
		end'
        EXEC(@sql);
SET @process = 'K020148-Carga BD WhatsApp salida-Detalle INSERT INTO tableLangueDbLoader tag = description-empty, languageId=2 Marco Garcia'
        SET @sql = '
		if not exists(select tag from tableLangueDbLoader where tag = ''description-empty'' and languageId=2)
		begin
			insert into tableLangueDbLoader (languageId,tag, translate) values (2,''description-empty'',''Telefone vazio ou incompleto'')
		end'
        EXEC(@sql);

SET @process = 'K020148-Carga BD WhatsApp salida-Detalle INSERT INTO tableLangueDbLoader tag = description-invalid, languageId=0 Marco Garcia'
        SET @sql = '
		if not exists(select tag from tableLangueDbLoader where tag = ''description-invalid'' and languageId=0)
		begin
			insert into tableLangueDbLoader (languageId,tag, translate) values (0,''description-invalid'',''Teléfono inválido'')
		end'
        EXEC(@sql);

SET @process = 'K020148-Carga BD WhatsApp salida-Detalle INSERT INTO tableLangueDbLoader tag = description-invalid, languageId=1 Marco Garcia'
        SET @sql = '
		if not exists(select tag from tableLangueDbLoader where tag = ''description-invalid'' and languageId=1)
		begin
			insert into tableLangueDbLoader (languageId,tag, translate) values (1,''description-invalid'',''Invalid number'')
		end'
        EXEC(@sql);
SET @process = 'K020148-Carga BD WhatsApp salida-Detalle INSERT INTO tableLangueDbLoader tag = description-invalid, languageId=2 Marco Garcia'
        SET @sql = '
		if not exists(select tag from tableLangueDbLoader where tag = ''description-invalid'' and languageId=2)
		begin
			insert into tableLangueDbLoader (languageId,tag, translate) values (2,''description-invalid'',''Telefone inválido'')
		end'
        EXEC(@sql);

SET @process = 'Insert Url para subir archivos'    
    SET @sql='
        IF NOT EXISTS(SELECT 1 FROM ccMetaWhatsAppConfigurations WHERE Id = 2)
        BEGIN
            insert into ccMetaWhatsAppConfigurations (Id,Url,Description)
            values (2,''https://graph.facebook.com/v19.0/WAAcountId/message_templates'',''Url dar de alta plantillas de whatsAppMeta, WAAcountId hace referencia al id de la cuenta'')
        END
    '
    EXEC(@sql)

SET @process = 'Insert Url para dar de alta plantillas'    
    SET @sql='
        IF NOT EXISTS(SELECT 1 FROM ccMetaWhatsAppConfigurations WHERE Id = 3)
        BEGIN
            insert into ccMetaWhatsAppConfigurations (Id,Url,Description)
            values (3,''https://graph.facebook.com/v20.0/'',''Url para envío solicitud de Id de sesión para subir archivos a la API de whatsAppMeta'')
        END
    '
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
			,ISNULL(contact.maxLimitQueueConversations, 99) maxLimitQueueConversations
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
		,maxLimitQueueConversations SMALLINT
		)
		DECLARE @numbers VARCHAR(max)

		SELECT @numbers = COALESCE(@numbers + '''', '''', '''''''') + number
		FROM ccWhatsAppNumbers
		WHERE camp_id = 0
		AND STATUS = 1

		INSERT INTO @AllCampaigns
		EXEC ccsp_RIAConfCamp @adminID
		,@campID

		SELECT 
		dialPrefixMan DialPrefixMan
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
		,RotativeAlgo
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
		,maxLimitQueueConversations MaxLimitQueueConversations
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
		@buttons nvarchar(max) = null,
		@metaStatus varchar(30) = null,
		@FilePath varchar(1024) = null,
		@HistoryLog varchar(max) = null,
		@UserId SMALLINT = 0
	AS
	BEGIN
		IF(@action = 1)
		BEGIN
			;WITH TemplateIsEditable AS (
				SELECT
					tb1.Id,
					CASE 
						WHEN COUNT(*) >= 10 THEN 2
						WHEN MAX(tb1.Date) >= CAST(GETDATE() AS DATE) THEN 1
						ELSE 0
					END AS IsEditable
				FROM (
					SELECT
						gal.Target AS Id,
						CAST(gal.ActivityDate AS DATE) AS Date
					FROM ccGalateaActivityLog gal 
					WHERE gal.OperationId = 122 
					AND gal.ModuleId = 20 
					AND gal.Target = ISNULL(CAST(@whatsAppTemplateID AS VARCHAR(MAX)), gal.target)
					AND CAST(gal.ActivityDate AS DATE) >= DATEADD(DD,-30, CAST(GETDATE() AS DATE))
				) AS tb1
				GROUP BY tb1.Id
			)
			SELECT 
			cmwot.Id 
			,cmwot.TemplateName AS Name
			,cmwot.Status AS Status
			,Category AS Category
			,ISNULL(cmwot.notes, '''' ) AS Notes
			,cmwot.header AS Header
			,Body
			,cmwot.footer AS Footer
			,cmwot.buttons AS Buttons
			,cmwot.LanguageCode
			,cmwot.quality AS Quality
			,cmwot.IsPendingQuality
			,ISNULL(tie.IsEditable, 0) AS IsEditable
			FROM  dbo.ccMetaWAOutboundTemplates cmwot
			LEFT JOIN TemplateIsEditable tie ON tie.Id = CAST(cmwot.Id AS VARCHAR(MAX))
			WHERE cmwot.Id = ISNULL(@whatsAppTemplateID, cmwot.Id)
			AND cmwot.StatusCW = 1
		END
		ELSE IF(@action = 2)
		BEGIN
			SELECT cmwan.MetaId AS Id, cmwan.Number FROM dbo.ccMetaWhatsAppNumbers AS cmwan
			Left JOIN dbo.ccMetaWhatsAppConfigurations AS cmwac
			ON cmwan.MetaId = cmwac.Id
			WHERE cmwan.Status = 1
		END
		ELSE IF(@action = 3)
		BEGIN
			UPDATE ccMetaWAOutboundTemplates SET StatusCW = 0 WHERE Id = @whatsAppTemplateID
			SELECT @@ROWCOUNT;
			RETURN 0;
		END
		ELSE IF(@action = 4) --create
		BEGIN
			insert into ccMetaWAOutboundTemplates (Id, Category,TemplateName,AllowCategoryChange,LanguageCode,Status,header,body,footer,buttons,FilePath)
								values (@Id, @Category,@TemplateName,@AllowCategoryChange,@LanguageCode,@Status,@header,@body,@footer,@buttons,@FilePath)
		END
		ELSE IF(@action = 5) -- Get Template Config By Id
		BEGIN
			SELECT n.WAAccountId, n.Token, c.Url as [Url], t.TemplateName 
			FROM ccMetaWAOutboundTemplates t
			INNER JOIN ccMetaWhatsAppNumbers n on t.MetaId = n.MetaId
			left JOIN ccMetaWhatsAppConfigurations c on c.Id = 2
			WHERE t.Id = @whatsAppTemplateID
			RETURN 0;
		END
		ELSE IF(@action = 6) -- update status to delete
		BEGIN
			DECLARE @newStatus bit = 1;
			IF(@metaStatus = ''DELETED'')
			BEGIN
				SET @newStatus = 0
			END
			UPDATE ccMetaWAOutboundTemplates SET 
			[Status] = @metaStatus, 
			StatusCW = @newStatus,
			RemovalDate = ISNULL(RemovalDate, GETDATE())
			WHERE Id = @whatsAppTemplateID
			AND [StatusCW] = 1;
			SELECT @@ROWCOUNT;
			RETURN 0;
		END
		ELSE IF(@action = 7) -- Get template campaigns associsted
		BEGIN
			SELECT ISNULL(n.Cam_Id,0) as Cam_Id, ISNULL(n.Inbound_Id,0) AS Inbound_Id FROM ccMetaWAOutboundTemplates t
			INNER JOIN ccMetaWhatsAppNumbers n on t.MetaId = n.MetaId
			left JOIN ccMetaWhatsAppConfigurations c on n.MetaId = c.Id
			WHERE t.Id = @whatsAppTemplateID
			RETURN 0;
		END
		ELSE IF (@action = 8) -- update template
		BEGIN
			DECLARE @tableHistoryLog TABLE (Id INT, Value VARCHAR(MAX))
			DECLARE @areaName VARCHAR(50),
					@login VARCHAR(50)

			SELECT
				@areaName = ca.AreaName,
				@login = cu.Login
			FROM ccUsers cu
			INNER JOIN ccRIACat_Areas ca with(nolock) ON cu.IDArea = ca.IDArea
			WHERE cu.User_id = @UserId

			INSERT INTO @tableHistoryLog 
			SELECT tb.Id, tb.Value
			FROM dbo.fn_RIASplitDelimited(@HistoryLog, '',,'') tb


			-- insert into activity log table and update template data
			IF @header IS NULL OR LEN(@header) = 0 AND (SELECT LEN(ISNULL(header,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when header is null or '''' and before update header contains data
			BEGIN
				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
				VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_HEADER'',''COMMON_NONE_O'',''root'')
			END
			IF @footer IS NULL OR LEN(@footer) = 0 AND (SELECT LEN(ISNULL(footer,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when footer is null or '''' and before update footer contains data
			BEGIN
				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
				VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_FOOTER'',''COMMON_NONE_O'',''root'')
			END
			IF @buttons IS NULL OR LEN(@buttons) = 0 AND (SELECT LEN(ISNULL(buttons,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when buttons is null or '''' and before update buttons contains data
			BEGIN
				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
				VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_BUTTONS'',''COMMON_NONE_O'',''root'')
			END
			
			EXEC InsertLogAdminGalatea @action=1, @tableName=''ccMetaWAOutboundTemplates'', @columnNameId=''Id'', @valueId= @Id, @userId= 1
			Create table #ccMetaWAOutboundTemplates 
			(
				columnInfo VARCHAR(255),
				dataInfo VARCHAR(255),
				identifierInfo VARCHAR(255)
			)

			UPDATE ccMetaWAOutboundTemplates
			SET Category = @Category,
				header = @header,
				body = @body,
				footer = @footer,
				buttons = @buttons
			WHERE Id = @Id

			EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccMetaWAOutboundTemplates'', @columnNameId = ''Id'', @valueId = @Id, @userId = 1,  @tableTemp=''#ccMetaWAOutboundTemplates'';

			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
			SELECT
				@areaName,
				GETDATE(),
				@login,
				122,
				20,
				cc.identifierInfo,
				tb1.Value,
				@id
			FROM #ccMetaWAOutboundTemplates cc
			INNER JOIN  @tableHistoryLog  tb1 ON cc.columnInfo = (CASE 
																	WHEN tb1.Id = 1 THEN ''Category''
																	WHEN tb1.Id = 2 THEN ''header'' 
																	WHEN tb1.Id = 3 THEN ''body'' 
																	WHEN tb1.Id = 4 THEN ''footer''
																	WHEN tb1.Id > 4 THEN ''buttons''
																	END)
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
		select WAAccountId, Token,PhoneNumberId,IdApp from ccMetaWhatsAppNumbers with (nolock) where Number=@phoneNumber
		end
		if(@action = 2)
		begin
		 select top (1) Id from ccMetaWAOutboundTemplates with (nolock) where TemplateName=@TemplateName or ( TemplateName=@TemplateName and RemovalDate >= @RemovalDate)
		end
		if(@action = 3)
		begin 
			select Id,Url from ccMetaWhatsAppConfigurations
		end
	end
	'
	EXEC(@sql)

	set @process = 'K020149-Configuración drop sp ccsp_UpdateOutWhatsappConfig MArco Garcia'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_UpdateOutWhatsappConfig'')
    begin
        DROP PROCEDURE ccsp_UpdateOutWhatsappConfig
    end'
	EXEC(@sql)

	set @process = 'K020149-Configuración CREATE ccsp_UpdateOutWhatsappConfig se agrega maxLimitQueueConversations Marco Garcia'
	set @sql = 'create PROCEDURE  [dbo].[ccsp_UpdateOutWhatsappConfig] 
	            @ConexionInfo varchar(400),
	            @outbound_id int,
	            @descripcion varchar(400), 
	            @ConnUser varchar(60),
	            @tNotas int,
	            @closeConversationTime int,
	            @ShowCalifWnd bit,
	            @ExitAssisted bit,
	            @MUTimeOutClient int,
	            @allowFileAttachments bit,
	            @userId SMALLINT, 
	            @idArea SMALLINT, 
	            @isCreating SMALLINT,
		    @maxLimitQueueConversations SMALLINT

	            AS
	            set nocount on
	            IF NOT EXISTS (SELECT camp_id FROM ContactMeanOut WHERE camp_id = @outbound_id) BEGIN

	                INSERT INTO contactMeanOut (meanContactTypeId, name, camp_id, isActive, numMessages,conexionInfo,connUser,closeConversationTime,ConnPass,answerTimeoutClient,allowFileAttachments, maxLimitQueueConversations)
	                VALUES (5, @descripcion, @outbound_id, (select cam_activo  from ccCamps where cam_id = @outbound_id), 3, NULL, NULL, NULL, ''N/A'', NULL, NULL, NULL);

	            END

	                        IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

	                        Create table #contactMeanOutTable 
	                        (
	                            columnInfo VARCHAR(255),
	                            dataInfo VARCHAR(255),
	                            identifierInfo VARCHAR(255)
	                        )

	                        EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @outbound_id, @userId= @userid


	                        UPDATE contactMeanOut SET
	                            conexionInfo = @conexionInfo,
	                            connUser = @connUser,
	                            closeConversationTime = @closeConversationTime,
	                            answerTimeoutClient = @MUTimeOutClient,
	                            allowFileAttachments = @allowFileAttachments,
				    maxLimitQueueConversations = @maxLimitQueueConversations
	                        WHERE camp_id = @outbound_id

	                        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @outbound_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';

	                        DELETE FROM #contactMeanOutTable WHERE dataInfo = '''';

	                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
	                        SELECT 
	                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
	                            getDate(), 
	                            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
	                            46, 
	                            3, 
	                            CMOT.identifierInfo,
	                            CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
	                                CASE
	                                    WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
	                                        CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
	            
	                                    ELSE CMOT.dataInfo END
	                            ELSE '''' END, 
	                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @outbound_id)
	                        FROM #contactMeanOutTable AS CMOT;

	                        EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @outbound_id, @userId = @userid;
	                        IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

	                        UPDATE ccWhatsAppNumbers SET camp_id = @outbound_id WHERE number = @conexionInfo

	            IF EXISTS (SELECT cam_id FROM ccCamps WHERE cam_id = @outbound_id) 
	            BEGIN

	                        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

	                        Create table #ccCampsTable 
	                        (
	                            columnInfo VARCHAR(255),
	                            dataInfo VARCHAR(255),
	                            identifierInfo VARCHAR(255)
	                        )

	                        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @outbound_id, @userId= @userid

	                        UPDATE ccCamps SET cam_tnotas = @tNotas, cam_ShowCalifWnd = @ShowCalifWnd, exitAssisted = @ExitAssisted, CampType = 5 where cam_id = @outbound_id;

	                        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @outbound_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

	                        DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'');

	                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
	                        SELECT 
	                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
	                            getDate(), 
	                            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
	                            46, 
	                            3, 
	                            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
	                                CASE WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN ''OUT_WHATS_EXIT_ASSISTED''
	                                ELSE CCCT.identifierInfo END
	                            ELSE CCCT.identifierInfo END,
	                            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
	                                CASE
	                                    WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'') THEN
	                                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
	            
	                                    ELSE CCCT.dataInfo END
	                            ELSE '''' END, 
	                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @outbound_id)
	                        FROM #ccCampsTable AS CCCT;

	                        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @outbound_id, @userId = @userid;
	                        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

	            END;
	            SELECT @outbound_id;

	            set nocount off'
	exec(@sql)

	set @process = 'K020149-Configuración drop sp [ccsp_RIAUpdateCamConfig] MArco Garcia'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateCamConfig'')
    begin
        DROP PROCEDURE [ccsp_RIAUpdateCamConfig]
    end'
	EXEC(@sql)

	set @process = 'K020149-Configuración CREATE sp [ccsp_RIAUpdateCamConfig] MArco Garcia'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
@cam_id smallint,
@cam_descripcion varchar(40) = null,
@cam_tnotas smallint = null,
@cam_ocupado tinyint = null,
@cam_NoInt_ocupado tinyint = null,
@cam_inter_ocupado smallint = null,
@cam_nocontesto tinyint = null,
@cam_NoInt_nocontesto tinyint = null,
@cam_inter_nocontesto smallint = null,
@cam_fax tinyint = null,
@cam_NoInt_fax tinyint = null,
@cam_inter_fax smallint = null,
@cam_ModoManual tinyint= null,
@ANI varchar(15) = null,
@cam_ShowCalifWnd bit = null,
@cam_StartTimerOnHangUp bit = null,
@editableCallKey bit = null,
@cam_tNoContesta tinyint = null,
@cam_intensive_dialing tinyint = null,
@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
@compliance TinyInt = null,
@cam_inter_graba smallint = null,
@cam_NoInt_graba tinyint = null,
@progDial smallint = null,
@excCallBack Tinyint = null,
@dialOrder Tinyint = null,
@dialPrefix varchar(10) = null,
@dialPrefixMan varchar(10) = null,
@dialPrefixXfe varchar(10) = null,
@listenManualCall bit = null,
@stopRecording bit = null,
@abandonCallback bit = null,
@autoCB smallint = null,
@id_listAni int = null,
@tDialonWrapUp smallint = null,
@quesize smallint=null,
@DNCScrub int=null,
@callerIdDesc varchar(15)=null,
@timeZoneRule int=null,
@callsBySurvey int=null,
@ivrScript int=null,
@surveyPctg int=null,
@call_record tinyint=null,
@dRestrictPlay bit = null,
@leaveRecMessage bit = null,
@manualCallOnChat bit = null,
@callBackSurveyClient bit = null,
@callBackSurveyAgent bit = null,
@funcEspDtmf int =null,
@sipHdrsCfg varchar(255) = null,
@cam_inter_cancelled smallint = null,
@prefijo varchar(max) = null,
@exitAssisted bit = null,
@previewDiscard bit = null,
@rotativeAlgo tinyint = null,
@timesPreview tinyint = null,
@cam_tPreview smallint = null,
@timesDiscard tinyint = null,
@CampType int = null,
@agentCloseConversationTime SMALLINT = NULL,
@adminCloseConversationTime INT = NULL,
@ConexionInfo VARCHAR(400) = NULL,
@allowFileAttachments BIT = NULL,
@selectRotativeANI int = null,
@messagingOrder bit = null,
@autoStart bit = null,
@recordHold bit = null,
@userId                SMALLINT     = NULL, 
@idArea                SMALLINT     = NULL, 
@isCreating            SMALLINT          = NULL,
@module INT = -1,
@maxLimitQueueConversations SMALLINT = NULL
as
set nocount on
DECLARE @timesDiscardActual int = (SELECT timesDiscard FROM ccCamps WHERE cam_id = @cam_id)
DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
    DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

UPDATE ccCamps SET
cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
cam_fax = isnull(@cam_fax,cam_fax),
cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
ANI = isnull(@ANI,ANI),
cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
editableCallKey = isnull(@editableCallKey, editableCallKey),
cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
compliance = isnull(@compliance, compliance),
cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
progDial = isnull(@progDial, progDial),
excCallBack = isnull(@excCallBack,excCallBack),
dialOrder = isnull(@dialOrder, dialOrder),
dialPrefix = isnull(@dialPrefix, dialPrefix),
dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
listenManualCall = isnull(@listenManualCall, listenManualCall),
stopRecording = isnull(@stopRecording, stopRecording),
abandonCallback = isnull(@abandonCallback, abandonCallback),
t_autoCB = isnull(@autoCB,t_autoCB),
id_anilist = isnull(@id_listAni,id_anilist),
tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
cam_maxqueue = isnull(@quesize,cam_maxqueue),
DNCScrub = isnull(@DNCScrub,DNCScrub),
callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
ivrScript = isnull(@ivrScript,ivrScript),
surveyPctg = isnull(@surveyPctg,surveyPctg),
call_record = isnull(@call_record,call_record),
startStopRecording = isnull(@dRestrictPlay, startStopRecording),
leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
prefijo = isnull(@prefijo, prefijo),
exitAssisted = isnull(@exitAssisted, exitAssisted),
previewDiscard = isnull(@previewDiscard, previewDiscard),
rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo),
timesPreview = isnull(@timesPreview, timesPreview),
cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
timesDiscard = isnull(@timesDiscard, timesDiscard),
CampType = (CASE  WHEN @CampType is not null THEN @CampType WHEN @progDial = 2 THEN 6 WHEN @progDial IS NOT NULL AND @progDial <> 2 THEN 0 WHEN CampType is not null THEN CampType ELSE 0 END),
selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
messagingOrder = isnull(@messagingorder, messagingOrder),
autoStart = isnull(@autoStart,autoStart),
recordHold = isnull(@recordHold, recordHold)

Where cam_id = @cam_id

if @callsBySurvey is not null and @ivrScript is not null begin
        
    UPDATE ccCamps SET CampType=case when @callsBySurvey=0 and @ivrScript=0 then 0 else 8 end 
    Where cam_id = @cam_id
end
    

        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

        Create table #ccCampsTable 
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )

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
        
        IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

        IF(@isCreating = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
            
        DELETE FROM #ccCampsTable WHERE columnInfo IN (''startStopRecording'');
        DELETE FROM #ccCampsTable WHERE dataInfo = '''';
            
        IF(@CampType = 6) DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'', ''cam_fDialOnWU'', ''ProgDial'');
        ELSE IF(@CampType = 5 AND @isCreating = 2) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'', ''cam_descripcion'', ''exitAssisted'');
        ELSE IF(@CampType = 5) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'');
        ELSE IF(@CampType = 7) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''messagingOrder'', ''autoStart'', ''rotativeAlgo'', ''id_anilist'', ''cam_descripcion'');
        ELSE DELETE FROM #ccCampsTable WHERE columnInfo IN (''previewDiscard'', ''CampType'', ''cam_fDialOnWU'', ''ProgDial'');

        IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            @operation, 
            @module,
            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
                THEN
                    CASE
                        WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
                            CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
                        WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN 
                            CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
                        WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
                            CASE WHEN @Camptype = 5 THEN ''OUT_MANUAL_DIALING_WHATS'' ELSE CCCT.identifierInfo END
                        ELSE
                            CCCT.identifierInfo
                        END
                ELSE
                ''''
                END,
            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
                CASE 
                    WHEN CCCT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                        CASE WHEN CCCT.dataInfo = ''VOICEMAIL'' 
                            THEN ''COMMON_VOICE_MAIL'' 
                            ELSE 
                                CASE WHEN CCCT.dataInfo IS NOT NULL THEN CCCT.dataInfo ELSE ''T&COMMON_NONE'' END 
                            END
                    WHEN CCCT.identifierInfo = ''OUT_DIALING_ORDER'' THEN 
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_DESCENDING'' ELSE ''COMMON_ASCENDING'' END

                    WHEN CCCT.identifierInfo = ''OUT_SMS_MESSAGING_ORDER'' THEN 
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ASCENDING'' ELSE ''COMMON_DESCENDING'' END

                    WHEN CCCT.identifierInfo = ''OUT_ANSWER_MACHINE_DETC'' THEN 
                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_BASIC'' 
                            WHEN CCCT.dataInfo = 1 THEN ''COMMON_LIGHT''
                            WHEN CCCT.dataInfo = 2 THEN ''COMMON_MODERATE''
                            WHEN CCCT.dataInfo = 3 THEN ''COMMON_HIGH''
                            ELSE ''T&COMMON_NONE'' END

                    WHEN CCCT.identifierInfo = ''OUT_ANI_MODE'' THEN 
                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ANI_LOCAL'' 
                            WHEN CCCT.dataInfo = 1 THEN ''COMMON_ANI_ROTATIVE''
                            WHEN CCCT.dataInfo = 2 THEN ''COMMON_ANI_ROTATIVE_REG''
                            WHEN CCCT.dataInfo = 3 THEN ''COMMON_ANI_ROTATIVE_SMART''
                            ELSE ''T&COMMON_NONE'' END

                    WHEN CCCT.identifierInfo = ''OUT_DIALING_MODE'' THEN 
                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_PREDICTIVE'' 
                            WHEN CCCT.dataInfo = 1 THEN ''COMMON_PROGRESIVE''
                            ELSE ''COMMON_ASSISTED'' END

                    WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
                        CASE WHEN  @CampType = 5 THEN 
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                        ELSE
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_VIA_KEYPAD_LOG''
                                WHEN CCCT.dataInfo = 2 THEN ''COMMON_VIA_CALLS_LOG''
                                WHEN CCCT.dataInfo = 3 THEN ''COMMON_VIA_CALLS_LOG''
                                ELSE ''T&COMMON_NONE'' END
                        END

                    WHEN CCCT.identifierInfo = ''OUT_ANI_LIST'' THEN
                                ISNULL((SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo), CCCT.dataInfo)

                    WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
                    WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
                                                ''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
                                                ''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'') THEN
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                        
                    ELSE CCCT.dataInfo END
            ELSE '''' END, 
            CASE WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
        FROM #ccCampsTable AS CCCT;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
begin
    EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
end

IF (@CampType IS NOT NULL AND @CampType IN (3, 5))
BEGIN
    IF NOT EXISTS(SELECT camp_id FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id)
    BEGIN
        SELECT 0
        RETURN(0)
    END

    IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

    Create table #contactMeanOutTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @cam_id, @userId= @userid

    DECLARE @PrevConexionInfo VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id);

    set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then CASE WHEN @isCreating > 0 AND @PrevConexionInfo <> '''' THEN ''Ninguno'' ELSE '''' END else @ConexionInfo end
    UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
                                            closeConversationTime = CAST(@agentCloseConversationTime AS INT), answerTimeoutClient = @adminCloseConversationTime,
                            allowFileAttachments = @allowFileAttachments,
			    maxLimitQueueConversations = @maxLimitQueueConversations
    WHERE @CampType = meanContactTypeId AND camp_id = @cam_id

        
    IF(@isCreating > 0 AND @module > -1) BEGIN 
        EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';
        IF(@ConexionInfo IS NULL OR @ConexionInfo IN ('''',''0'',''None'',''Ninguno'') AND @PrevConexionInfo <> @ConexionInfo) UPDATE contactMeanOut SET conexionInfo = '''' WHERE @CampType = meanContactTypeId AND camp_id = @cam_id
    END

    DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''conexionInfo'') AND  dataInfo = '''';
    DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''ConnPass'', ''connUser'') ;

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        @operation, 
        @module, 
        CMOT.identifierInfo,
        CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
            CASE
                WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
                    CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                WHEN CMOT.identifierInfo = ''OUT_WHATS_ASSOCIATED_PHONE'' THEN
                    CASE WHEN CMOT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMOT.dataInfo END
                ELSE CMOT.dataInfo END
        ELSE '''' END, 
        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
    FROM #contactMeanOutTable AS CMOT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid;
    IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

    IF @CampType = 5 BEGIN
        update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
        IF(@ConexionInfo <> '''')
        BEGIN 
            UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
        END
    END
END 
DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

IF @cam_ShowCalifWnd = 1
BEGIN
    IF NOT EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @cam_id and tipo = 1)
    BEGIN
        SELECT 0
        RETURN(0)
    END

    UPDATE ccCamps SET
    cam_ShowCalifWnd = ISNULL(@cam_ShowCalifWnd,cam_ShowCalifWnd)
    WHERE cam_id = @cam_id


    IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            @operation, 
            3, 
            ''OUT_SHOW_DISPOSITIONS'',
            CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
    END

    SELECT 1
    RETURN(0)
END

UPDATE ccCamps SET
cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
where cam_id = @cam_id

IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        @operation, 
        3, 
        ''OUT_SHOW_DISPOSITIONS'',
        CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
END

SELECT 2
RETURN(0)

set nocount off'
	EXEC(@sql)

	set @process = 'K020111 drop sp [ccsp_GalateaGetRecordsImportStatus] MArco Garcia'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetRecordsImportStatus'')
    begin
        DROP PROCEDURE [ccsp_GalateaGetRecordsImportStatus]
    end'
	EXEC(@sql)

	set @process = 'K020111 CREATE sp [ccsp_GalateaGetRecordsImportStatus] MArco Garcia'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetRecordsImportStatus]
		-- @Type = 1:Detalle general de carga de registros | 2:Detalle específico de carga de registros | 3:Porcentaje de carga de registros
		@action tinyint, 
		@loadID int = NULL, 
		@userID smallint = NULL

		AS
		declare @today datetime
		select @today =convert(datetime, convert(varchar(11),getdate(),121),121)
		SET nocount ON
		if @action not IN (1,2,3)
		raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)

		if @action=1 -- Detalle general de carga de registros
		BEGIN
		if not exists(SELECT User_id FROM ccUsers WHERE TipoUser_id IN(2,6) AND Status>0 AND User_id=@userID)
		 BEGIN
		  raiserror(''ERROR. invalid user id'', 18, 1)
		  return(0)
		 END

		if exists (select * from ccUsers_Roles where User_id = @userID and Rol_id = (select Rol_id from ccRoles where Level = 7))
			BEGIN
				SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked+isnull(regsNotLoadedCp,0)+ISNULL(recordsNotLoadedPort,0) as regsNotLoaded, state, loadDate	
				FROM ccRIALoading riaLoad
				JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
				WHERE 
				loadDate>=@today and loadType = 0
				ORDER BY riaLoad.loadDate DESC
			END
		else
			BEGIN
				SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked+isnull(regsNotLoadedCp,0)+ISNULL(recordsNotLoadedPort,0) as regsNotLoaded, state, loadDate
		
				FROM ccRIALoading riaLoad
				JOIN ccSupervisorCam superCam ON riaLoad.cam_id = superCam.cam_id
				JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
				WHERE 
				loadDate>=@today AND
				superCam.user_id = @userID
				AND superCam.tipo = 1
				ORDER BY riaLoad.loadDate DESC
			END

		return(0)
		END

		if @action=2 -- Detalle específico de carga de registros
		BEGIN
		if not exists(SELECT load_id FROM ccRIALoading)
		 BEGIN
		  raiserror(''ERROR. invalid template ID'', 18, 1)
		  return(0)
		 END
		  SELECT 
		  crl.regsLoaded
		  ,crl.alreadyLoaded
		  ,crl.regsBlocked
		  ,crl.regsNotLoaded
		  ,crl.telsLoaded
		  ,crl.telsBlocked
		  ,crl.telsNotLoaded
		  ,ISNULL(regsNotLoadedCp,0) as regsNotLoadedCp
		  ,ISNULL(telsNotLoadedCp,0) as telsNotLoadedCp
		  ,ISNULL(recordsNotLoadedPort,0) as recordsNotLoadedPort
		  ,ISNULL(phonesNotLoadedPort, 0) as phonesNotLoadedPort
		  ,ISNULL(LoadBySegment, CAST(0 AS BIT)) as IsSegmentLoad
		  ,cc.CampType
		  FROM dbo.ccRIALoading AS crl
		  JOIN dbo.ccCamps AS cc
		  ON cc.cam_id = crl.cam_id
		  WHERE crl.load_id = @loadID
		  

		END

		if @action=3 -- Porcentaje de carga de registros
		BEGIN
		if not exists(SELECT load_id FROM ccRIALoading)
		 BEGIN
		  raiserror(''ERROR. invalid load ID'', 18, 1)
		  return(0)
		 END

		  SELECT state, pctg
		  FROM ccRIALoading
		  WHERE load_id  = @loadID

		END
		SET nocount off
'
	EXEC(@sql)
	

	 SET @process = 'K020148-Carga BD WhatsApp salida-Detalle DROP SP ccsp_RIALogPhones Marco Garcia'
        SET @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_RIALogPhones'')
		begin
			DROP PROCEDURE ccsp_RIALogPhones;
		end'
        EXEC(@sql);

        SET @process = 'K020148-Carga BD WhatsApp salida-Detalle  CREATE SP ccsp_RIALogPhones Marco Garcia'

        SET @sql = 'CREATE procedure [dbo].[ccsp_RIALogPhones]
		@load_id int,
		@Type smallint,
		@GenCSV bit = 1, -- 0:100 / 1:todos
		@isKolob bit = 0,
		@PageIndex      INT = 0,
		@PageSize       INT = 0,
		@option SMALLINT = NULL
		as
		set nocount ON


		declare @CaseType varchar(2000), @sql nvarchar(MAX), @nType char(5), @MovType SMALLINT, @language int, @LoadBySegment varchar(1)
		SELECT @language = cs.valor FROM dbo.ccSettings AS cs WHERE cs.setting_id = 27;
		declare @PageStart int,@PageEnd int
		SELECT @LoadBySegment = CAST(ISNULL(LoadBySegment,''0'') as varchar) from ccRIALoading where load_id = @load_id
		IF(@option = 0)
		BEGIN
			select CAST(@LoadBySegment as bit) as LoadBySegment
			return 0;
		END

		select @CaseType = '''', @nType = right(''0000''+cast(@Type as varchar(5)), 5)

		if @nType like ''%____1%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov in (0,8)
			''

		if @nType like ''%___1_%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov in(-1,0,8) 
			''

		if @nType like ''%__1__%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov IN (1,0)
			''

		if @nType like ''%_1___%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov IN (1,4) 
			''

		if @nType like ''%1____%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 2 ''

		if @CaseType = '''' and @nType <> 0
			return(0)

		if @nType like ''%____1%''
			select @CaseType = @CaseType + ''  or telefono<>'''''''' and crlp.tipoMov = 0''

		select @PageStart=@PageSize*(@PageIndex-1),@PageEnd=@PageSize*@PageIndex

		IF(@option = 1)
		BEGIN	
			SET @sql = ''SELECT count(*) AS listSize FROM (
		select crlp.load_id
		from ccRIALogPhones AS crlp 
		where crlp.load_id = @load_id and ('' 
		+ ISNULL(STUFF(@CaseType,CHARINDEX(''or'',@CaseType),LEN(''or''),''''),'''') +'')) tmp '' +
		case @GenCSV when 0 then ''WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd'' else '''' end
					--EXEC(@sql);

				Exec sp_executesql @sql
						 , N''@PageStart int,@PageEnd int,@language int,@load_id int''
						 , @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id
					RETURN (0);
				END
				ELSE 
				BEGIN
						IF(@isKolob = 1)
						BEGIN

						declare @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200), @typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
						@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @typeUpdatedRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200), @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max);


						select @typeDescriptionPhoneBlocked=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-num''
						select @typeDescriptionPhoneUpdated=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-num''
						select @typeIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-incorrect-records''
						select @typeBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-records''
						select @typeDescriptionPhoneNotLoaded=translate from tableLangueDbLoader where languageId=@language and tag=''type-not-loaded-num''

						select @typeDescriptionPhoneBlackList=translate from tableLangueDbLoader where languageId=@language and tag=''description-dnc-list''
						select @descriptionIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-incorrect-records''
						select @descriptionBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-blocked-records''
						select @typeUpdatedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-records''
						select @descriptionInternationalPortNotFound=TRANSLATE from tableLangueDbLoader where languageId=@language and tag=''type-camp-no-international-port''


						select @column=translate from tableLangueDbLoader where languageId=@language and tag=''column-file-field''

						select @headerPhone=header_phone,@headerPhone2=header_phone2,@headerPhone3=header_phone3,@headerPhone4=header_phone4 
						,@headerPhone5=header_phone5
						from fileHeadersPhoneLoad where load_id=@load_id
			
							set @CaseType=case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' END
							SET @sql = '';with result as(
							SELECT * FROM (select  
							ROW_NUMBER() OVER(ORDER BY crlp.cal_key ASC) AS RowNum,
							crlp.load_id,
							crlp.cal_key, 
							crlp.telefono AS phone,
							CASE
								WHEN crlp.tipoMov in (1,4)  THEN @typeDescriptionPhoneBlocked  
								WHEN crlp.tipoMov = 2 THEN @typeUpdatedRecords	
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @typeIncorrectRecords
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @typeBlockedRecords
								WHEN crlp.tipoMov in(-1,0) THEN @typeDescriptionPhoneNotLoaded
								WHEN crlp.tipoMov in(8) THEN @descriptionInternationalPortNotFound
								WHEN crlp.keyTranslate is not null THEN isnull(tlan.translate,crlp2.descTipoMov)
							ELSE 
								crlp2.descTipoMov  
							END AS Tipo,
							case when CHARINDEX('''':'''',crlp.motivo)=0 then 0 else
								convert(int,substring(crlp.motivo ,CHARINDEX('''':'''',crlp.motivo)-1 ,1))
							end
							 AS ColumnFile, 
							CASE  WHEN crlp.tipoMov = 2 THEN ''''N/A'''' 
									WHEN crlp.tipoMov in (1,4) THEN @typeDescriptionPhoneBlackList							  
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @descriptionIncorrectRecords
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @descriptionBlockedRecords
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-camp-no-international-port'''') THEN  @descriptionInternationalPortNotFound
									WHEN crlp.keyTranslate is not null THEN tlan.translate 
							ELSE crlp.motivo END AS motivo,
							CAST('' + @LoadBySegment + '' as BIT) AS LoadBySegment
							from ccRIALogPhones AS crlp 
							INNER JOIN dbo.ccRIACATLogPhones AS  crlp2 ON crlp.tipoMov = crlp2.tipoMov
							left join tableLangueDbLoader tlan on tlan.tag=crlp.keyTranslate and tlan.languageId=@language
							where crlp.load_id = @load_id '' 				
							+ @CaseType +'') tmp '' +
							case @GenCSV when 0 then '' WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd '' else '''' end +'' 
							) 
							select  crlp.RowNum,
							crlp.load_id,
							crlp.cal_key, 
							crlp.phone,
							crlp.Tipo,
							case when crlp.ColumnFile=1 then @headerPhone
							when crlp.ColumnFile=2 then @headerPhone2
							when crlp.ColumnFile=3 then @headerPhone3
							when crlp.ColumnFile=4 then @headerPhone4
							when crlp.ColumnFile=5 then @headerPhone5
							else '''''''' end ColumnFile,
							crlp.motivo
							from result crlp ''
			END
			ELSE
			BEGIN
				set @sql = ''select '' + case @GenCSV when 0 then ''top 100 '' else '''' end 
				+ ''load_id, cal_key, telefono, tipoMov, motivo from ccRIALogPhones AS crlp where load_id = @load_id '' 
				+ @CaseType
			END  
			--PRINT(@sql);



			Exec sp_executesql @sql, N''@PageStart int,@PageEnd int,@language int,@load_id int, @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200),
			@typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
			@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200)
			, @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max), @typeUpdatedRecords varchar(200)''
			, @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id,@column=@column,@typeDescriptionPhoneNotLoaded=@typeDescriptionPhoneNotLoaded
			,@typeDescriptionPhoneBlocked=@typeDescriptionPhoneBlocked,@typeDescriptionPhoneUpdated=@typeDescriptionPhoneUpdated,@typeDescriptionPhoneBlackList=@typeDescriptionPhoneBlackList
			,@typeBlockedRecords=@typeBlockedRecords,@typeIncorrectRecords=@typeIncorrectRecords,@descriptionBlockedRecords=@descriptionBlockedRecords,@descriptionIncorrectRecords=@descriptionIncorrectRecords,
			 @descriptionInternationalPortNotFound= @descriptionInternationalPortNotFound 
			,@headerPhone=@headerPhone,@headerPhone2=@headerPhone2,@headerPhone3=@headerPhone3,@headerPhone4=@headerPhone4,@headerPhone5=@headerPhone5,@typeUpdatedRecords=@typeUpdatedRecords
	
		return(0)
		END
		set nocount OFF'
		exec(@sql)
	


	------------------------------------------------Fin Modificar sp-----------------------------------------------------

	        ----------------------------------------------------- BEGIN Gaby ---------------------------------------------------------------




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
	------------------------------------------------Uriel Cabrera Inicio Crear Sp de actualizacion de plantillas por webhook-----------------------------------------------------
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
	------------------------------------------------Uriel Cabrera Fin Crear Sp de actualizacion de plantillas por webhook-----------------------------------------------------
	------------------------------------------------Uriel Cabrera Inicio Crear Tabla para configuraciones de los webhooks-----------------------------------------------------
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
	------------------------------------------------Uriel Cabrera Fin Crear Tabla para configuraciones de los webhooks-----------------------------------------------------
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

	SET @process = 'K020147 - Campañas Whatsapp de Salida en totales - Agentes Se modifica SP para traer los datos solamente de las campañas de whatsApp'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] --exec ccsp_GalateaAdminCampaigns @Option=10, @AdminId=1, @CampType=1, @IsCampaignWhatsApp=1
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
						FROM ccRIACampEspWG A WITH (NOLOCK)
						INNER JOIN wgId ON wgId.IDWG = A.IDWG
							AND A.Tipo = @CampType;
					END;
					ELSE
					BEGIN
						--print ''xxxx Super''
						IF @CampType = 1
						BEGIN
							SELECT DISTINCT CAST(cam_id AS INT) AS Id
							FROM ccCamps WITH (NOLOCK)
							WHERE IDArea IS NOT NULL
						END
						ELSE
						BEGIN
							SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
							FROM ccInbound WITH (NOLOCK)
							WHERE IDArea IS NOT NULL
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

				END;'
	EXEC(@sql);
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

	set @process = 'CW-8638 se borra sp ccsp_SaveStatusAgent'
	set @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_SaveStatusAgent'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_SaveStatusAgent
	END'
	EXEC(@sql)

	set @process = 'CW-8638 se borra sp ccsp_RIAAdmDelRegs'
	set @sql = '	
	CREATE PROCEDURE [dbo].[ccsp_SaveStatusAgent]
		@User_id smallint,
		@TipoStatusAge_id tinyint,
		@TipoNotReady smallint,
		@tStatus float,
		@TipoCall  tinyint,
		@Camp smallint,
		@callout_id int=0,
		@call_id int=0,
		@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
		@tDialog float =0 ,
		@currentStatus int =-2,--NUEVO PARAMETRO PARA LA NUEVA COLUMNA
		@Fecha4 datetime=null,
		@tMusicHold int =0,
		@isTransferEngine bit = 0
		AS

		if @Fecha4 is null set @Fecha4 = getdate()

		if @TipoCall > 0 set @TipoCall = @TipoCall - 1

		 IF @User_id <= 0 OR (@tStatus = 0 AND @TipoStatusAge_id = 30)
				RETURN 0;

		declare @cam_id int,@surveycamId int
		declare @cal_telefono varchar(30)
		declare @cal_key varchar(40)
		declare @inbound_id int
		declare @callBackSurveyClients bit
		declare @cal_whoHung tinyint
		DECLARE @cal_tXfer float,   @cal_tRing float
		declare @cal_tDialog int
		declare @cal_tNotas float
		declare @cal_tNotaOri int
		declare @tMinAVRS smallint
		declare @calInicio datetime
		declare @sumCall float
		declare @cal_manual int 

		set @cal_tNotas =0
		set @cal_tNotaOri=0

		if @TipoStatusAge_id=32 set @tStatus=CONVERT(DECIMAL(10,2), ROUND(@tStatus, 0, 1))

		set @cal_manual =0
		--4 Dialog,6 Notas, 27 Notas Fallida

		 IF @TipoStatusAge_id IN (4, 6, 27) AND @call_id > 0 and @isLogout=1
		BEGIN
		   if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
		   if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas

   
			 if @TipoCall = 0 
			 begin -- BEING IN @TipoCall = 0  ---
				SELECT @calInicio = cal_Xfer,
				@sumCall = cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas,
				@Camp = Inbound_id,
				@cal_tDialog = cal_tDialog,
				@cal_tNotaOri = cal_tNotas,
				@cal_key = cal_Key,
				@inbound_id = inbound_id,
				@cal_telefono = cal_ani,
				@cal_whoHung = cal_whoHung,
				@cal_tXfer = cal_tXfer,
				@cal_tRing = cal_tRing
				FROM ccCallsIN WITH (NOLOCK)
				WHERE cal_id = @call_id
				AND statusCall_id = 13

				IF @cal_tXfer = 0 AND @cal_tRing = 0
				BEGIN
					SELECT @cal_tXfer = CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE @cal_tXfer END,
						@cal_tRing = CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE @cal_tRing END
					FROM ccLogAgentesDia WITH (NOLOCK)
					WHERE User_id = @User_id
						AND callID = @call_id
						AND Tipo = @TipoCall
						AND TipoStatusAge_id IN (5, 9)
				END
				IF @cal_tDialog = 0 AND @tDialog > 0            
				BEGIN
					IF @Fecha4 < DATEADD(ms, (@sumCall + @tDialog + @cal_tNotas) * 1000, @calInicio)
					BEGIN
						SET @tStatus = CASE WHEN @tStatus > 0 THEN @tStatus - 1 ELSE @tStatus END

						IF @TipoStatusAge_id = 4
							SET @tDialog = @tDialog - 1

						IF @TipoStatusAge_id = 6
						BEGIN
							IF @cal_tNotas > 0
								SET @cal_tNotas = @cal_tNotas - 1
							ELSE
								SET @tDialog = @tDialog - 1
						END
					END

					UPDATE ccCallsIN
					WITH (ROWLOCK)

					SET cal_tDialog = @tDialog,
						cal_tNotas = @cal_tNotas,
						cal_tMoh = @tMusicHold,
						cal_tXfer=@cal_tXfer,
						cal_tRing=@cal_tRing
					WHERE cal_id = @call_id
						AND statusCall_id = 13
				END
				----------------------------
				IF @isTransferEngine = 1
				BEGIN 
					DECLARE @minimoDialogo TINYINT

					SELECT @minimoDialogo = valor
					FROM ccSettings
					WHERE setting_id = 13

					IF @cal_tDialog < @minimoDialogo
					BEGIN
						--el status 18 es para llamada cortada con transferencia en Reminder
						EXEC ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id, @nStatus = 18
					END
				END
				-----------------------------
			 END -- END IN @TipoCall = 0  ---
			 Else 
			 begin -- BEING IN @TipoCall = 1  ---
				SELECT @calInicio = cal_inicio,
				@sumCall = cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas,
				@cam_id = cam_id,
				@cal_tDialog = cal_tDialog,
				@cal_tNotaOri = cal_tNotas,
				@cal_tXfer = cal_tXfer,
				@cal_tRing = cal_tRing
				FROM ccoCallsOut WITH (NOLOCK)
				WHERE cal_id = @call_id

				SET @Camp = @cam_id

				if @cal_tXfer=0 and @cal_tRing=0 begin
					SELECT @cal_tXfer = CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE @cal_tXfer END,
					@cal_tRing = CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE @cal_tRing END
					FROM ccLogAgentesDia WITH (NOLOCK)
					WHERE User_id = @User_id
					AND callID = @call_id
					AND Tipo = @TipoCall
					AND TipoStatusAge_id IN (5, 9)

				end

				if @cal_tDialog = 0 and @tDialog>0 begin
					IF @Fecha4 < DATEADD(ss, @sumCall + @tDialog + @cal_tNotas, @calInicio)
						BEGIN
							SET @tStatus = CASE WHEN @tStatus > 0 THEN @tStatus - 1 ELSE @tStatus END

							IF @TipoStatusAge_id = 4
								SET @tDialog = @tDialog - 1
							IF @TipoStatusAge_id = 6
							BEGIN
								IF @cal_tNotas > 0
									SET @cal_tNotas = @cal_tNotas - 1
								ELSE
									SET @tDialog = @tDialog - 1
							END
						END

						UPDATE ccoCallsOut
						WITH (ROWLOCK)
						SET cal_tDialog = @tDialog,
							totalCall_Time = @tDialog,
							cal_tNotas = @cal_tNotas,
							cal_tMoh = @tMusicHold,
							cal_tXfer = @cal_tXfer,
							cal_tRing = @cal_tRing
						WHERE cal_id = @call_id
							AND statusCall_id = 13

				end
				else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
					update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog  
					,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
					where cal_id = @call_id
				else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
					update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas 
					,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
					where cal_id = @call_id 
			 END -- END OUT @TipoCall = 1  ---
    
			select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

			if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1 and @cal_manual<>1 begin
				insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
			end

			if @TipoStatusAge_id in(6,27) begin
			--Valida que el agente no pudo guardar el status antes de desloguear
			if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
				INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
			end
		end --@TipoStatusAge_id IN (4, 6, 27) AND @call_id > 0 and @isLogout=1 --


		IF (@TipoStatusAge_id = 4)
		BEGIN -- 4 = Dialogo
			DECLARE @tStatus3 FLOAT, @Fecha3 DATETIME

			SELECT TOP 1 @tStatus3 = tstatus, @Fecha3 = fecha
			FROM ccLogAgentesDia WITH (NOLOCK)
			WHERE TipoStatusAge_id = 3 AND user_id = @User_id
			ORDER BY fecha DESC

			INSERT INTO ccLogAgentesDia_Dialog (
				User_id,
				Cam_id,
				fecha_Calc_ms,
				tStatus_Dispo,
				fecha_Dispo,
				tStatus_Dialog,
				fecha_Dialog
				)
			SELECT @User_id, cam_id,
				datediff(ms, dateadd(ms, - (@tStatus3 * 1000), @Fecha3), dateadd(ms, - (@tStatus3 * 1000
							), @Fecha4)),
				@tStatus3,
				@Fecha3,
				@tStatus,
				@Fecha4
			FROM cccampsagente
			WHERE user_id = @User_id

			---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
			IF @call_id > 0
			BEGIN
				IF @TipoCall = 0
				BEGIN --IN
					SELECT @surveycamid = isnull(extend.SurveyCamId, 0),
						@callBackSurveyClients = i.callBackSurveyClient
					FROM ccinbound i
					LEFT JOIN ccInboundExtend extend
						ON i.inbound_id = extend.inbound_id
					WHERE i.inbound_id = @inbound_id

					IF @surveycamId > 0
						AND (
							@callBackSurveyClients = 1
							OR @cal_whoHung = 1
							)
					BEGIN
						IF EXISTS (
								SELECT cam_id
								FROM cccamps
								WHERE cam_id = @surveycamid
									AND isnull(callsBySurvey, 0) > 0
									AND isnull(ivrScript, 0) > 0
								)
						BEGIN
							IF (
									SELECT surveyPctg
									FROM ccCamps
									WHERE cam_id = @surveycamid
									) >= rand() * 100
							BEGIN
								INSERT INTO ccoCallsOUTSource (
									cal_Key,
									cam_id,
									cal_telefono,
									cal_status,
									cal_fechaDial
									)
								VALUES (
									right((cast(@call_id AS VARCHAR) + '''' + @cal_Key), 40),
									@surveycamid,
									@cal_telefono,
									0,
									dateadd(mi, 6, getdate())
									)
							END
						END
					END
				END --@TipoCall = 0
				ELSE
				BEGIN --OUT
					SELECT @surveycamId = isnull(surveycamid, 0),
						@callBackSurveyClients = callBackSurveyClient
					FROM cccamps
					WHERE cam_id = @cam_id

					SELECT @cal_key = cal_Key,
						@cam_id = cam_id,
						@cal_telefono = cal_telefono,
						@cal_whoHung = cal_whoHung
					FROM ccoCallsOUT WITH (
							INDEX (IX_ccoCallsOut_11),
							NOLOCK
							)
					WHERE callout_id = @callout_id
						AND statusCall_id = 13
						AND cal_id = @call_id

					IF @surveycamId > 0
						AND (
							@callBackSurveyClients = 1
							OR @cal_whoHung = 1
							)
					BEGIN
						IF (
								SELECT surveyPctg
								FROM ccCamps
								WHERE cam_id = @surveycamId
								) >= rand() * 100
						BEGIN
							INSERT INTO ccoCallsOUTSource (
								cal_Key,
								cam_id,
								cal_telefono,
								cal_status,
								cal_fechaDial
								)
							VALUES (
								right((cast(@call_id AS VARCHAR) + '''' + @cal_Key), 40),
								@surveycamid,
								@cal_telefono,
								0,
								dateadd(mi, 6, getdate())
								)
						END
					END
				END
			END --@callout_id>0
		END --End -- 4 = Dialogo


		IF @isLogout = 0 AND @TipoStatusAge_id = 6
		BEGIN --- BEGIN Insert ccLogAgentesDia @isLogout = 0 AND @TipoStatusAge_id = 6 -----
			--Valida que el ccserver no haya guardado antes el status antes al desloguear
			IF NOT EXISTS (
					SELECT *
					FROM ccLogAgentesDia WITH (NOLOCK)
					WHERE User_id = @User_id
						AND TipoStatusAge_id = 4
						AND fecha BETWEEN dateadd(ss, - 10, @Fecha4) AND @Fecha4
						AND tStatus = @tStatus + 1
					)
			BEGIN
				INSERT ccLogAgentesDia (
					User_id,
					TipoStatusAge_id,
					tStatus,
					fecha,
					IdCampEsp,
					Tipo,
					currentStatus,
					callID
					)
				VALUES (
					@User_id,
					@TipoStatusAge_id,
					@tStatus,
					@Fecha4,
					@Camp,
					@TipoCall,
					@currentStatus,
					@call_id
					)

				IF NOT EXISTS (
						SELECT *
						FROM [ccLogAgentesDiaLast]
						WHERE User_id = @User_id
						)
				BEGIN
					INSERT [ccLogAgentesDiaLast] (
						User_id,
						TipoStatusAge_id,
						tStatus,
						fecha,
						IdCampEsp,
						Tipo,
						currentStatus,
						callID
						)
					VALUES (
						@User_id,
						@TipoStatusAge_id,
						@tStatus,
						@Fecha4,
						@Camp,
						@TipoCall,
						@currentStatus,
						@call_id
						)
				END
				ELSE
				BEGIN
					UPDATE [ccLogAgentesDiaLast]
					SET TipoStatusAge_id = @TipoStatusAge_id,
						tStatus = @tStatus,
						fecha = @Fecha4,
						IdCampEsp = @Camp,
						Tipo = @TipoCall,
						currentStatus = @currentStatus,
						callID = @call_id
					WHERE USER_ID = @User_id
				END
			END
		END --- END Insert ccLogAgentesDia @isLogout = 0 AND @TipoStatusAge_id = 6 -----
		ELSE 
		BEGIN --- BEGIN ELSE DIFF -----
			INSERT ccLogAgentesDia (
				User_id,
				TipoStatusAge_id,
				tStatus,
				fecha,
				IdCampEsp,
				Tipo,
				currentStatus,
				callID
				)
			VALUES (
				@User_id,
				@TipoStatusAge_id,
				@tStatus,
				@Fecha4,
				@Camp,
				@TipoCall,
				@currentStatus,
				@call_id
				)

			IF NOT EXISTS (
					SELECT *
					FROM [ccLogAgentesDiaLast]
					WHERE User_id = @User_id
					)
			BEGIN
				INSERT [ccLogAgentesDiaLast] (
					User_id,
					TipoStatusAge_id,
					tStatus,
					fecha,
					IdCampEsp,
					Tipo,
					currentStatus,
					callID
					)
				VALUES (
					@User_id,
					@TipoStatusAge_id,
					@tStatus,
					@Fecha4,
					@Camp,
					@TipoCall,
					@currentStatus,
					@call_id
					)
			END
			ELSE
			BEGIN
				UPDATE [ccLogAgentesDiaLast]
				SET TipoStatusAge_id = @TipoStatusAge_id,
					tStatus = @tStatus,
					fecha = @Fecha4,
					IdCampEsp = @Camp,
					Tipo = @TipoCall,
					currentStatus = @currentStatus,
					callID = @call_id
				WHERE USER_ID = @User_id
			END
		END --- END ELSE DIFF -----


		IF (@TipoStatusAge_id = 2)
		BEGIN  -- 2 = No Disponible
			INSERT ccLogAgentesNotReady (
				User_id,
				TipoNotReady_id,
				tStatus,
				fecha,
				IdCampEsp,
				Tipo
				)
			VALUES (
				@User_id,
				@TipoNotReady,
				@tStatus,
				@Fecha4,
				@Camp,
				@TipoCall
				)

			---Para Agente RIA: OAYC
			INSERT ccRIALogAgentesNotReady (
				User_id,
				TipoNotReady_id,
				tStatus,
				fecha
				)
			VALUES (
				@User_id,
				@TipoNotReady,
				@tStatus,
				@Fecha4
				)
		END


		-- Actualiza para reporte de tiempos especiales (Boan)
		IF @Camp > 0
		BEGIN
			IF EXISTS (
					SELECT *
					FROM ccLogAgentesDia WITH (
							INDEX (IX_ccLogAgentesDia_5),
							NOLOCK
							)
					WHERE IdCampEsp = 0
						AND user_id = @User_id
					)
			BEGIN
				UPDATE ccLogAgentesDia
				WITH (ROWLOCK)

				SET IdCampEsp = @Camp,
					Tipo = @TipoCall
				WHERE IdCampEsp = 0
					AND user_id = @User_id
			END

			IF EXISTS (
					SELECT *
					FROM ccLogAgentesNotReady WITH (
							INDEX (IX_ccLogAgentesNotReady_4),
							NOLOCK
							)
					WHERE IdCampEsp = 0
						AND user_id = @User_id
					)
			BEGIN
				UPDATE ccLogAgentesNotReady
				WITH (ROWLOCK)

				SET IdCampEsp = @Camp,
					Tipo = @TipoCall
				WHERE IdCampEsp = 0
					AND user_id = @User_id
			END
		END


		IF (
				@TipoStatusAge_id = 34
				AND @call_id > 0
				) -- Dialogo WhatsApp
		BEGIN
			IF @TipoCall = 0
			BEGIN
				UPDATE ccWhatsAppConversations
				SET tChatting = (tChatting + @tStatus)
				WHERE conversationId = @call_id;

				SET @Camp = (
						SELECT inboundId
						FROM ccWhatsAppConversations
						WHERE conversationId = @call_id
						);

				EXEC ccsp_WhatsAppInformation @Option = 2,
					@InboundId = @Camp
			END
			ELSE
			BEGIN
				UPDATE ccWhatsAppConversationsOut
				SET tChatting = (tChatting + @tStatus)
				WHERE conversationId = @call_id;

				SET @Camp = (
						SELECT camId
						FROM ccWhatsAppConversationsOut
						WHERE conversationId = @call_id
						);

				EXEC ccsp_WhatsAppInformationOut @Option = 2,
					@camId = @Camp
			END
		END
'
	EXEC(@sql)
	----------------------------------------------------------- End Rod Salazar -------------------------------------------------------------------------------
	----------------------------------------------------------- Uriel Cabrera  Inicio se agrega la columna reconnect Msg para mensajes despues de desconexion -------------------------------------------------------------------------------
	set @process = 'Add reconnectMsg column to ccUsers'
	set @sql = '
		IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''reconnectMsg'' AND Object_ID = Object_ID(N''dbo.ccUsers''))
		BEGIN
			ALTER TABLE ccUsers ADD reconnectMsg int default 0
		END'
	EXEC(@sql)
	----------------------------------------------------------- Uriel Cabrera  Fin se agrega la columna reconnect Msg para mensajes despues de desconexion -------------------------------------------------------------------------------
	-----------------------------------------------------------BEGIN MACL-----------------------------------------------------
	set @process = 'Insert Create template in ccGalateaOperations'
	set @sql = '
	if not exists(select OperationId from ccGalateaOperations where OperationId=123)
	begin
		insert into ccGalateaOperations (OperationId,OpTagEs,OpTagEn,OpTagPt) values (123,''Eliminar plantilla'',''Delete template'',''Excluir modelo'')
	end'
	EXEC(@sql)

	set @process = 'Insert Create template in ccGalateaOperations'
	set @sql = '
	if not exists(select * from ccGalateaModOpRelation where OperationId=123)
	begin
		insert into ccGalateaModOpRelation (ModuleId, OperationId) values (20,123)
	end'
	EXEC(@sql)


	-----------------------------------------------------------END MACL-------------------------------------------------------

	----------------------------------------------------------- Start Isaac Cortes -------------------------------------------------------------------------------
	SET @process = 'K020020 Delete sp [ccsp_WAOUTGetLogDials]'
	SET @sql = '
		IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_WAOUTGetLogDials'')
		BEGIN
			DROP PROCEDURE dbo.ccsp_WAOUTGetLogDials
		END
	'
	EXEC(@sql)

	SET @process = 'K020020 Create sp ccsp_WAOUTGetLogDials'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_WAOUTGetLogDials]
		@Action				INT,
		@CamId				INT,
		@ClientId			VARCHAR(50),
		@ConversationId		INT = NULL,
		@MetaId				VARCHAR(1000) = NULL
		AS
		BEGIN

			IF @Action = 1 -- get conversation in log dials
			BEGIN
				DECLARE @InitialTime DATETIME
				SET @InitialTime = DATEADD(HH, -23, GETDATE())
				SELECT TOP(1)
					cwld.MetaId AS MetaID
				FROM ccoWhatsLogDials cwld WITH(NOLOCK)
				WHERE cwld.CamId = @CamID 
				AND cwld.PhoneClient = @ClientId
				AND cwld.TimeSpam >= @InitialTime
			END
			ELSE IF @Action = 2
			BEGIN
				UPDATE ccoWhatsLogDials SET ConversationId = @ConversationId WHERE MetaId = @MetaId
			END
		END
	'
	EXEC(@sql)
	SET @process = 'WhatsApp Masivo - Drop SP ccsp_WhatsAppInformationOut'
	SET @sql = '
	    if exists (select * from sys.procedures where name = N''ccsp_WhatsAppInformationOut'')
	    begin
	        DROP PROCEDURE ccsp_WhatsAppInformationOut;
	    end'
	EXEC(@sql);

	SET @process = 'WhatsApp Masivo - Create SP ccsp_WhatsAppInformationOut'	
	SET @sql='
		CREATE PROCEDURE [dbo].[ccsp_WhatsAppInformationOut]
		@Option SMALLINT,
		@camId SMALLINT = 0,
		@ConversationId INT = 0,
		@AgentsAvailables INT = 0,
		@IncreaseDecreaseAgent BIT = NULL

		AS
		SET NOCOUNT ON
		IF @camId>0 and NOT EXISTS (SELECT * FROM ccCamps WHERE cam_Id = @camId AND CampType = 5) BEGIN
			print (''Camp Is Not WhatsApp'')
			return(-1);
		End

		
			
		DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
		--set @Today SMALLDATETIME = ''2022-03-24''
		IF @Option = 0 BEGIN-- Reset TABLES
			TRUNCATE TABLE ccWAConversationsResult
			TRUNCATE table ccWAOperatingSummaryOut;
			TRUNCATE TABLE ccWAAverageConversationsOut;
			TRUNCATE TABLE ccLastMessageAgentByConversationOut;
		END    
		else IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
		BEGIN
			IF EXISTS (SELECT * FROM ccWAAverageConversationsOut
						WHERE CamId = @camId
						AND (LastUpdate IS NULL
						OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
						OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
			BEGIN
				-------------------------- ----------------------- Variable Declaration ---------------------------------------------------

				DECLARE @AverageConversationTime INT = 0;
				DECLARE @AverageDialogTime INT = 0;
				DECLARE @AverageWaitingTime INT = 0;
				DECLARE @MaximumWaitingTime INT = 0;
				DECLARE @DefaultValue INT = 2
				

				SET @DefaultValue = @DefaultValue * 60;
				DECLARE @LessThanDefault INT = 0;
				DECLARE @ReceivedConversations INT = 0;
				DECLARE @ServiceLevel SMALLINT = 0;

				--------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

				SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
						@AverageDialogTime = ROUND(AVG(tChatting), 4),
						@AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
						@MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
						@ReceivedConversations = COUNT(conversationDate),
						@LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
				FROM ccWhatsAppConversationsOut with(nolock) WHERE camId = @camId
				AND requestDate >= @Today

				SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

				----------------------------------------------------- Update table --------------------------------------------------------

				IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE camId = @camId)
				BEGIN
					UPDATE ccWAAverageConversationsOut
					SET AverageConversationTime = @AverageConversationTime,
						AverageDialogTime = @AverageDialogTime,
						AverageWaitingTime = @AverageWaitingTime,
						MaximumWaitingTime = @MaximumWaitingTime,
						ServiceLevel = @ServiceLevel,
						StatusUpdate = 0,
						LastUpdate = GETDATE()
					WHERE CamId = @camId
				END
				ELSE
				BEGIN
					INSERT INTO ccWAAverageConversationsOut (CamId, AverageConversationTime, AverageDialogTime,
															AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
					VALUES(@camId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
							@ServiceLevel, 0 , GETDATE())
				END
			END
			--------------------------------- Results -----------------------------------

			if exists (select * from ccWAOperatingSummaryOut with(nolock) where CamId=@camId
						and (OnQueue<0 or Assigned<0)
						) begin
						
					set @Today =convert(date,getdate(),121)

					;with waOperationSummary as(
					select 
					CamId
					,count(case when finishedBy=1 then 1 end) Attended
					,count(case when onQueue=1 and finishedBy=0 then 1 end) onQueue
					,count(case when finishedBy=0 and agentId>0 then 1 end) Assigned
					,count(*) Request
					,count(case when finishedBy=2 then 1 end) EndedBySystem
					from ccWhatsAppConversationsOut with(nolock)
					where camId = @camId and requestDate>=@Today
					group by CamId
					)
					update A 
					set A.Attended=B.Attended, A.Assigned=B.Assigned
					
					,A.Request=B.Request,A.EndedBySystem=B.EndedBySystem
					from ccWAOperatingSummaryOut A 
					inner join waOperationSummary B on A.CamId=B.CamId
			end

			SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
					ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
					ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
					ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
					ISNULL(ServiceLevel, 0) AS ServiceLevel,
					ISNULL(Attended, 0) AS Attended,
					ISNULL(Assigned, 0) AS Assigned,
					ISNULL(OnQueue, 0) AS OnQueue,
					ISNULL(EndedBySystem, 0) AS EndedBySystem,
					ISNULL(Available, 0) AS Available,
					ISNULL(Request, 0) AS Request
			FROM ccWAAverageConversationsOut conv
			RIGHT JOIN ccWAOperatingSummaryOut summary ON conv.CamId = summary.camId
			WHERE conv.CamId = @camId OR summary.camId = @camId
		END
		else IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
						-- Average Queue/Waiting Time, and Service Level)
		BEGIN
			IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE CamId = @camId)
				BEGIN
					UPDATE ccWAAverageConversationsOut SET StatusUpdate = 1
					WHERE CamId = @camId
				END
				ELSE
				BEGIN
					INSERT INTO ccWAAverageConversationsOut (CamId, StatusUpdate)
					VALUES(@camId, 1)
				END
		END
		else IF @Option = 3 -- Save time from accepted conversation by agent
		BEGIN
			IF @ConversationId IS NOT NULL
			BEGIN
				UPDATE ccWhatsAppConversationsOut SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
				--Save Conversation Assigned
				SELECT @camId = camId FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;
				UPDATE ccWAOperatingSummaryOut SET Assigned = (Assigned + 1) WHERE camId = @camId
				
			END
		END
		else IF @Option = 4 -- Get Disposition Information
		BEGIN
		declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
		select @nIdioma = case valor when 0 then ''Sin calificación'' else ''No disposition'' end
		from ccsettings where setting_id = 27 -- 0esp
		SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
				ISNULL(disposition.calif_id, 0) AS DispositionId,
				COUNT(whatsConv.disposition) AS Total,
				ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
				COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
		FROM ccWhatsAppConversationsOut whatsConv with(nolock)
		LEFT JOIN ccTipoCalifOUT disposition ON disposition.calif_id = whatsConv.disposition
		WHERE camId = @camId AND assignDate >= @Today
			and whatsConv.conversationStatus != 2
		GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
		END
		else IF @Option = 5 -- Get Subdisposition Information
		BEGIN
			SELECT relation.calif_id AS DispositionId,
					subDispositions.califSubDesc AS SubDispositionsName,
					COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
			FROM cctipoSubCalifRel relation
			INNER JOIN ccTipoCalifSubOUT subDispositions ON subDispositions.califSub_id = relation.califSub_id
			INNER JOIN ccWhatsAppConversationsOut whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
			WHERE whatsConv.camId = @camId AND
					whatsConv.assignDate >= @Today AND
					relation.tipoSubRel = 0
			GROUP BY subDispositions.califSubDesc, relation.calif_id
		END
		ELSE IF @Option = 6 -- Agents Availables
		BEGIN
			IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId)
				BEGIN
					INSERT INTO ccWAOperatingSummaryOut (camId, Available) VALUES (@camId, @AgentsAvailables);
				END
			ELSE
				BEGIN
					UPDATE ccWAOperatingSummaryOut SET Available = @AgentsAvailables WHERE camId = @camId
				END
		END

		ELSE IF @Option = 7 -- Whats Conversations Results
		BEGIN
			SELECT ISNULL(SentMsg, 0) AS SentMsg,
					ISNULL(Delivered, 0) AS Delivered,
					ISNULL(NotDelivered, 0) AS NotDelivered,
					ISNULL(ReadMsg, 0) AS ReadMsg,
					ISNULL(NotSupported, 0) AS NotSupported
			FROM ccWAConversationsResult
			WHERE camId = @camId
		END

		ELSE IF @Option = 8 -- whats outbound conversations
		BEGIN
			DECLARE @ActualDay DATE = GETDATE()

			SELECT -- active
				COUNT(cco.camId) AS Active,
				0 AS Queued,
				0 AS FinishedAgent,
				0 AS FinishedSystem
			FROM ccWhatsAppConversationsOut cco WITH(NOLOCK)
			WHERE cco.conversationStatus NOT IN (10, 11, 17, 18) AND cco.camId = @camId AND CAST(cco.conversationDate AS DATE) = @ActualDay
			GROUP BY cco.camId
			UNION 
			SELECT -- queued
				0 AS Active,
				COUNT(cco.camId) AS Queued, 
				0 AS FinishedAgent,
				0 AS FinishedSystem
			FROM ccWhatsAppConversationsOut cco WITH(NOLOCK)
			WHERE cco.conversationStatus = 1 AND cco.camId = @camId AND CAST(cco.conversationDate AS DATE) = @ActualDay
			GROUP BY cco.camId
			UNION
			SELECT -- finished by agent
				0 AS Active,
				0 AS Queued, 
				COUNT(cco.camId) AS FinishedAgent,
				0 AS FinishedSystem
			FROM ccWhatsAppConversationsOut cco WITH(NOLOCK)
			WHERE cco.conversationStatus = 11 AND cco.camId = @camId AND CAST(cco.conversationDate AS DATE) = @ActualDay
			GROUP BY cco.camId
			UNION
			SELECT -- finished by system
				0 AS Active,
				0 AS Queued, 
				0 AS FinishedAgent,
				COUNT(cco.camId) AS FinishedSystem 
			FROM ccWhatsAppConversationsOut cco WITH(NOLOCK)
			WHERE cco.conversationStatus = 10 AND cco.camId = @camId AND CAST(cco.conversationDate AS DATE) = @ActualDay
			GROUP BY cco.camId
		END
	'
	EXEC(@sql)

	SET @process = 'DEV2-577 K02118 Operation 122'
	SET @sql = '
		IF NOT EXISTS (SELECT OperationId FROM ccGalateaOperations WHERE OperationId = 122)
		BEGIN
			INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPT) VALUES (122, ''Editar plantilla'', ''Edit template'', ''Editar modelo'')
		END
	'
	EXEC(@sql)
	SET @process = 'DEV2-577 K02118 Identifiers'
	SET @sql = '
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&EDIT_TEMPLATE_CATEGORY'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&EDIT_TEMPLATE_CATEGORY'',''Categoría'',''Category'',''Categoria'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&EDIT_TEMPLATE_HEADER'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&EDIT_TEMPLATE_HEADER'',''Encabezado'',''Header'',''Cabeçalho'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&EDIT_TEMPLATE_BODY'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&EDIT_TEMPLATE_BODY'',''Cuerpo'',''Body'',''Corpo'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&EDIT_TEMPLATE_FOOTER'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&EDIT_TEMPLATE_FOOTER'',''Pie de página'',''Footer'',''Rodapé'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&EDIT_TEMPLATE_BUTTONS'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&EDIT_TEMPLATE_BUTTONS'',''Botones'',''Buttons'',''Botões'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&META_CATEGORY_MARKETING'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&META_CATEGORY_MARKETING'',''Marketing'',''Marketing'',''Marketing'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&META_CATEGORY_UTILITY'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&META_CATEGORY_UTILITY'',''Utilidad'',''Utility'',''Utilidade'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&META_HEADER_TEXT'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&META_HEADER_TEXT'',''Texto'',''Text'',''Texto'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&META_HEADER_MEDIA'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&META_HEADER_MEDIA'',''Contenido multimedia'',''Media'',''Mídia'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&META_HEADER_LOCATION'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&META_HEADER_LOCATION'',''Ubicación'',''Location'',''Localização'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&META_BUTTON_PHONENUMBER'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&META_BUTTON_PHONENUMBER'',''de teléfono'',''phone number button'',''de telefone'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&META_BUTTON_URL'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&META_BUTTON_URL'',''de URL'',''URL button(s)'',''de URL'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&META_BUTTON_QUICKREPLY'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&META_BUTTON_QUICKREPLY'',''de respuesta rápida'',''quick reply button(s)'',''de resposta rápida'')
		END
		IF NOT EXISTS (SELECT Description FROM ccGalateaIdentifiers WHERE Description = ''T&META_BUTTON_COPYCODE'')
		BEGIN
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) VALUES (''T&META_BUTTON_COPYCODE'',''de copiar código'',''copy code button'',''de copiar código'')
		END

		IF NOT EXISTS (SELECT Identifiers FROM relationTableColumnIdentifiers WHERE Identifiers = ''T&EDIT_TEMPLATE_CATEGORY'')
		BEGIN
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) VALUES (''T&EDIT_TEMPLATE_CATEGORY'',''ccMetaWAOutboundTemplates'',''Category'')
		END
		IF NOT EXISTS (SELECT Identifiers FROM relationTableColumnIdentifiers WHERE Identifiers = ''T&EDIT_TEMPLATE_HEADER'')
		BEGIN
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) VALUES (''T&EDIT_TEMPLATE_HEADER'',''ccMetaWAOutboundTemplates'',''header'')
		END
		IF NOT EXISTS (SELECT Identifiers FROM relationTableColumnIdentifiers WHERE Identifiers = ''T&EDIT_TEMPLATE_BODY'')
		BEGIN
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) VALUES (''T&EDIT_TEMPLATE_BODY'',''ccMetaWAOutboundTemplates'',''body'')
		END
		IF NOT EXISTS (SELECT Identifiers FROM relationTableColumnIdentifiers WHERE Identifiers = ''T&EDIT_TEMPLATE_FOOTER'')
		BEGIN
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) VALUES (''T&EDIT_TEMPLATE_FOOTER'',''ccMetaWAOutboundTemplates'',''footer'')
		END
		IF NOT EXISTS (SELECT Identifiers FROM relationTableColumnIdentifiers WHERE Identifiers = ''T&EDIT_TEMPLATE_BUTTONS'')
		BEGIN
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) VALUES (''T&EDIT_TEMPLATE_BUTTONS'',''ccMetaWAOutboundTemplates'',''buttons'')
		END
	'
	EXEC(@sql)
	SET @process = 'DEV2-576 K02118 Delete scalar fuction GetMetaButtonTemplateHistory'
	SET @sql = '
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''dbo.GetMetaButtonTemplateHistory'') AND type IN (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
	BEGIN
		DROP FUNCTION dbo.GetMetaButtonTemplateHistory
	END'
	EXEC(@sql)
	SET @process = 'DEV2-576 K02118 Create scalar fuction GetMetaButtonTemplateHistory'
	SET @sql = '
		IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''dbo.GetMetaButtonTemplateHistory'') AND type IN (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
		BEGIN
			CREATE FUNCTION [dbo].[GetMetaButtonTemplateHistory] (@buttons VARCHAR(MAX), @lang INT)
			RETURNS VARCHAR (MAX)
			AS
			BEGIN

				DECLARE @stringFormated VARCHAR(MAX) = '''';

				WITH ButtonParts AS (
					SELECT 
						tb1.Id, 
						tb3.Value
					FROM dbo.fn_RIASplitDelimited(@buttons, '','') AS tb1
					CROSS APPLY dbo.fn_RIASplitDelimited(tb1.Value, ''-'') AS tb3
				),
				TranslatedButtons AS (
					SELECT 
						CASE 
							WHEN cgi.Description IS NULL THEN bp.Value 
							ELSE 
								CASE 
									WHEN @lang = 0 THEN cgi.TagEs 
									WHEN @lang = 2 THEN cgi.TagPt 
									ELSE cgi.TagEn 
								END 
						END AS Value,
						ROW_NUMBER() OVER (ORDER BY bp.Id) AS rn
					FROM ButtonParts bp
					LEFT JOIN ccGalateaIdentifiers cgi ON cgi.Description = bp.Value
				)
				SELECT 
				@stringFormated = STUFF(
					(SELECT 
						CASE 
							WHEN rn % 2 = 1 THEN Value 
							ELSE '' '' + Value + '', '' 
						END
					FROM TranslatedButtons
					FOR XML PATH(''''), TYPE
					).value(''.'', ''VARCHAR(MAX)'')
				, 1, 0, '''');

				IF RIGHT(@stringFormated, 2) = '', ''
				BEGIN
					SET @stringFormated = LEFT(@stringFormated, LEN(@stringFormated) - 1);
				END

				RETURN @stringFormated
			END
		END
	'
	SET @process = 'K02118 delete sp ccsp_GalateaChangeHistory'
	SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_GalateaChangeHistory'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_GalateaChangeHistory
	END'
	EXEC(@sql)

	set @process = 'K02118 create sp ccsp_GalateaChangeHistory'
	set @sql = '
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
					''WHEN L.Identifier<>'''''''' AND L.Identifier = ''''T&EDIT_TEMPLATE_BUTTONS'''' THEN dbo.GetMetaButtonTemplateHistory(L.value,''+CAST(@lang AS VARCHAR(5))+'')''+
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


    SET NOCOUNT OFF'
	EXEC(@sql)


	-----------------------------------------------------------  End Isaac Cortes  -------------------------------------------------------------------------------
	
	----------------------------------------------------------- Start Carlos Eduardo Muñoz -------------------------------------------------------------------------------
	set @process = 'DEV1-600 Se actualizan procedimientos para el despliegue de números meta en campañas de entrada y salida, así como el enlace de números al guardar ajustes.'

	set @sql = '
	ALTER PROCEDURE [dbo].[ccsp_MultimediaConfigurations] 
				@Option AS SMALLINT,
				@ServiceType AS SMALLINT = 0,
				@Number AS VARCHAR(25) = '''',
				@Id AS INT = 0,
				@CamType AS SMALLINT = 0
				AS
				BEGIN
				    SET NOCOUNT ON;
					BEGIN
				    IF(@Option = 1) -- Get Vonage Configurations depending the Service Type and number 
						BEGIN
							SELECT config.applicationId AS ApplicationId,
								   config.secretKey AS SecretKey,
								   config.messagesUrl AS MessagesUrl
							FROM ccVonageConfigurations config
							INNER JOIN ccWhatsAppNumbers numbers ON config.vonageId = numbers.vonageId 
							AND numbers.number = @Number 
							AND config.serviceType = @ServiceType   -- 5 = WhatsApp
						END 

					IF(@Option = 2) -- Get WhatsApp registered numbers 
						BEGIN
							SELECT number AS AvailableNumbers FROM ccWhatsAppNumbers Numbers 
							INNER JOIN ccVonageConfigurations Configurations 
							ON Numbers.vonageId = Configurations.vonageId 
							AND Numbers.inboundId = 0 
							AND Numbers.status = 1 
							AND Configurations.serviceType = 5
						END 
					IF(@Option = 3) -- Get WhatsApp registered numbers Outbound
						BEGIN
							SELECT number AvailableNumbers
							FROM ccWhatsAppNumbers Numbers 
							INNER JOIN ccVonageConfigurations Configurations 
							ON Numbers.vonageId = Configurations.vonageId 
							AND Numbers.camp_id = 0 
							AND Numbers.status = 1 
							AND Configurations.serviceType = 5
							UNION
							SELECT number FROM ccMetaWhatsAppNumbers
							WHERE Cam_Id = 0
							AND STATUS = 1
						END
					IF(@Option = 4) -- Get associated whatsapp number
						BEGIN
							IF (@CamType = 0) BEGIN
								SELECT @Number = number from ccWhatsAppNumbers WHERE inboundId = @Id
							END
							ELSE BEGIN
								SELECT @Number = number from ccWhatsAppNumbers WHERE camp_id = @Id
							END
							SELECT ISNULL(@Number, '''') as number
						END
					END
				END
	'
	EXEC (@sql)

	set @sql = '
		ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateWhatsAppConfiguration]
		        @inboundId        smallint,
		        @frame          smallint  = null,
		        @description      varchar(50) = null,
		        @mediaType        tinyint   = null,
		        @status         smallint  = null,
		        @number         varchar(400)= null,
		        @maxAnswerTime      int   = null,
		        @muTimeOutClient    int     = null,
		        @tNotas         int     = null,
		        @exitWrapUpDisposition  bit     = null,
		        @showCalifWnd     bit     = null,
		        @allowFileAttachments bit    = null,
				@userId 				smallint	= null,
				@module			int = -1

		      AS
		      BEGIN
		        SET NOCOUNT ON;
		        DECLARE @graph_id smallint

		        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inboundId, @userId= @userId

		        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

		        Create table #ccInboundTable 
		        (
		            columnInfo VARCHAR(255),
		            dataInfo VARCHAR(255),
		            identifierInfo VARCHAR(255)
		        )
		    
		        DECLARE @PrevDesc VARCHAR(MAX) = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @inboundId);

		        UPDATE ccInbound SET
		          descripcion = ISNULL(@description, descripcion),
		          chat = ISNULL(@mediaType, chat),
		          Status = ISNULL(@status, Status),
		          tNotas = ISNULL(@tNotas, tNotas),
		          ExitWrapUpDisposition = ISNULL(@exitWrapUpDisposition, ExitWrapUpDisposition)
		        WHERE Inbound_id = @inboundId

				IF(@module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#ccInboundTable'';	

		        DELETE FROM #ccInboundTable WHERE columnInfo IN (''tel_maxwait'', ''tel_maxqueue'', ''tel_outservice'', ''tel_noct'');

		        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		        SELECT 
		            (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
		            getDate(), 
		            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
		            53, 
					@module,
		            CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
		                CASE WHEN @mediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
		            ELSE
		                CCIT.identifierInfo
		            END,
		            CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
		                CASE 
		                    WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_WRAP_ON_DIPOSITION_WHATS'') THEN
		                        CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
		                    ELSE CCIT.dataInfo END
		            ELSE '''' END, 
		            CASE WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN @PrevDesc ELSE (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId) END
		        FROM #ccInboundTable AS CCIT;

		        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId;

		        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

		        DECLARE @descUpdate varchar(50)
		        DECLARE @statusCCInbound smallint
		        select @descUpdate = ISNULL(@description, descripcion), @statusCCInbound = status from ccInbound where Inbound_id =@inboundId

		        IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId=@inboundId) 
		          BEGIN
		              INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) 
		          values (5, @descUpdate, @inboundId, @statusCCInbound);
		          END

		        IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inboundId) 
		          BEGIN
		          DECLARE @PrevConexion VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanIn WHERE inboundId = @inboundId);
		          
				  set @number = case when  @number is null or @number in('''',''0'', ''Ninguno'') then ''Ninguno'' else @number end

		          EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanIn'', @columnNameId=''inboundId'', @valueId= @inboundId, @userId= @userId

		            IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

		            Create table #contactMeanInTable 
		            (
		                columnInfo VARCHAR(255),
		                dataInfo VARCHAR(255),
		                identifierInfo VARCHAR(255)
		            )


		          UPDATE contactMeanIn set name=@descUpdate, conexionInfo=ISNULL(@number, conexionInfo)
		          ,connUser=ISNULL(@number, connUser)
		          ,ConnPass=ISNULL(@number, ConnPass) 
		          ,closeConversationTime = ISNULL(@maxAnswerTime, closeConversationTime),
		          answerTimeoutClient = ISNULL(@muTimeOutClient, answerTimeoutClient),
		          allowFileAttachments = ISNULL(@allowFileAttachments, allowFileAttachments)
		          where inboundId = @inboundId;

				IF(@module > -1) BEGIN
		        EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#contactMeanInTable'';  
				END

		        IF(@number=''Ninguno'' AND @PrevConexion='''')UPDATE contactMeanIn SET conexionInfo = '''' WHERE inboundId = @inboundId;
		        DELETE FROM #contactMeanInTable WHERE columnInfo IN (''name'',''connUser'',''ConnPass'');

		            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		            SELECT 
		                (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
		                getDate(), 
		                (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
		                53, 
						@module, 
		                CMIT.identifierInfo,
		                CASE WHEN CMIT.identifierInfo IS NOT NULL AND CMIT.identifierInfo <> '''' THEN
		                    CASE
		                        WHEN CMIT.identifierInfo IN (''IN_ATTACH_FILES_WHATS'') THEN
		                            CASE WHEN CMIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
		                        WHEN CMIT.identifierInfo IN (''IN_ASSOCIATED_PHONE_WHATS'') THEN
		                            CASE WHEN CMIT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMIT.dataInfo END
		                        ELSE CMIT.dataInfo END
		                ELSE '''' END, 
		                (SELECT [name] FROM contactMeanIn WHERE inboundId = @inboundId)
		            FROM #contactMeanInTable AS CMIT;

		            EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inboundId, @userId = @userId;

		            IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

		          update ccWhatsAppNumbers set inboundId=0 where inboundId=@inboundId
				  update ccMetaWhatsAppNumbers set Inbound_Id=0 where Inbound_Id=@inboundId

		          if @number <> '''' begin
					if EXISTS (SELECT number FROM ccWhatsAppNumbers WHERE number = @number)
						update ccWhatsAppNumbers set inboundId=@inboundId where inboundId=0 and number=@number
					if EXISTS (SELECT number FROM ccMetaWhatsAppNumbers WHERE number = @number)
						UPDATE ccMetaWhatsAppNumbers SET Inbound_Id = @inboundId WHERE Inbound_Id = 0 and number = @number
		          end

		          END

		        IF @frame IS NOT NULL
		        BEGIN
		          SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
		          UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId

		          INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		          SELECT 
		                (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
		                getDate(), 
		                (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
		                53, 
		                3,
		                '''',
		                ''IN_CALL_EDIT_ICON'', 
		                (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
		        END

		        DECLARE @prevCalif BIT = (SELECT [ShowCalifWnd] FROM ccInbound WHERE inbound_id = @inboundId);

		        IF @showCalifWnd = 1
		          BEGIN
		          IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
		              BEGIN

		            UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd)
		                  WHERE inbound_id = @inboundId

		            IF(@prevCalif <> @showCalifWnd) BEGIN
		                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		                SELECT 
		                    (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
		                    getDate(), 
		                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
		                    53, 
		                    3,
		                    ''IN_SHOW_DISPOSITIONS'',
		                    CASE WHEN (SELECT [ShowCalifWnd] FROM ccInbound WHERE inbound_id = @inboundId) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END,
		                    (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
		            END

		            SELECT 1 [Result]
		            RETURN(0)
		              END

		              SELECT -1 [Result]
		              RETURN(0)
		           END
		           ELSE
		         BEGIN
		          UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;

		          IF(@prevCalif <> @showCalifWnd) BEGIN
		                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		                SELECT 
		                    (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
		                    getDate(), 
		                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
		                    53, 
		                    3,
		                    ''IN_SHOW_DISPOSITIONS'',
		                    CASE WHEN (SELECT [ShowCalifWnd] FROM ccInbound WHERE inbound_id = @inboundId) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END,
		                    (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
		            END
		         END

		         SELECT 1 [Result]
		         RETURN(0)

		        SET NOCOUNT OFF;
		      END
	'
	EXEC(@sql)

	set @sql = '
	ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
	@cam_id smallint,
	@cam_descripcion varchar(40) = null,
	@cam_tnotas smallint = null,
	@cam_ocupado tinyint = null,
	@cam_NoInt_ocupado tinyint = null,
	@cam_inter_ocupado smallint = null,
	@cam_nocontesto tinyint = null,
	@cam_NoInt_nocontesto tinyint = null,
	@cam_inter_nocontesto smallint = null,
	@cam_fax tinyint = null,
	@cam_NoInt_fax tinyint = null,
	@cam_inter_fax smallint = null,
	@cam_ModoManual tinyint= null,
	@ANI varchar(15) = null,
	@cam_ShowCalifWnd bit = null,
	@cam_StartTimerOnHangUp bit = null,
	@editableCallKey bit = null,
	@cam_tNoContesta tinyint = null,
	@cam_intensive_dialing tinyint = null,
	@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
	@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
	@compliance TinyInt = null,
	@cam_inter_graba smallint = null,
	@cam_NoInt_graba tinyint = null,
	@progDial smallint = null,
	@excCallBack Tinyint = null,
	@dialOrder Tinyint = null,
	@dialPrefix varchar(10) = null,
	@dialPrefixMan varchar(10) = null,
	@dialPrefixXfe varchar(10) = null,
	@listenManualCall bit = null,
	@stopRecording bit = null,
	@abandonCallback bit = null,
	@autoCB smallint = null,
	@id_listAni int = null,
	@tDialonWrapUp smallint = null,
	@quesize smallint=null,
	@DNCScrub int=null,
	@callerIdDesc varchar(15)=null,
	@timeZoneRule int=null,
	@callsBySurvey int=null,
	@ivrScript int=null,
	@surveyPctg int=null,
	@call_record tinyint=null,
	@dRestrictPlay bit = null,
	@leaveRecMessage bit = null,
	@manualCallOnChat bit = null,
	@callBackSurveyClient bit = null,
	@callBackSurveyAgent bit = null,
	@funcEspDtmf int =null,
	@sipHdrsCfg varchar(255) = null,
	@cam_inter_cancelled smallint = null,
	@prefijo varchar(max) = null,
	@exitAssisted bit = null,
	@previewDiscard bit = null,
	@rotativeAlgo tinyint = null,
	@timesPreview tinyint = null,
	@cam_tPreview smallint = null,
	@timesDiscard tinyint = null,
	@CampType int = null,
	@agentCloseConversationTime SMALLINT = NULL,
	@adminCloseConversationTime INT = NULL,
	@ConexionInfo VARCHAR(400) = NULL,
	@allowFileAttachments BIT = NULL,
	@selectRotativeANI int = null,
	@messagingOrder bit = null,
	@autoStart bit = null,
	@recordHold bit = null,
	@userId                SMALLINT     = NULL, 
	@idArea                SMALLINT     = NULL, 
	@isCreating            SMALLINT          = NULL,
	@module INT = -1,
	@maxLimitQueueConversations SMALLINT = NULL
	as
	set nocount on
	DECLARE @timesDiscardActual int = (SELECT timesDiscard FROM ccCamps WHERE cam_id = @cam_id)
	DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
		DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
		EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

	UPDATE ccCamps SET
		cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
		cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
		cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
		cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
		cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
		cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
		cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
		cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
		cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
		cam_fax = isnull(@cam_fax,cam_fax),
		cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
		cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
		cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
		ANI = isnull(@ANI,ANI),
		cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
		editableCallKey = isnull(@editableCallKey, editableCallKey),
		cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
		iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
		detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
		detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
		compliance = isnull(@compliance, compliance),
		cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
		cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
		cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
		progDial = isnull(@progDial, progDial),
		excCallBack = isnull(@excCallBack,excCallBack),
		dialOrder = isnull(@dialOrder, dialOrder),
		dialPrefix = isnull(@dialPrefix, dialPrefix),
		dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
		dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
		listenManualCall = isnull(@listenManualCall, listenManualCall),
		stopRecording = isnull(@stopRecording, stopRecording),
		abandonCallback = isnull(@abandonCallback, abandonCallback),
		t_autoCB = isnull(@autoCB,t_autoCB),
		id_anilist = isnull(@id_listAni,id_anilist),
		tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
		cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
		cam_maxqueue = isnull(@quesize,cam_maxqueue),
		DNCScrub = isnull(@DNCScrub,DNCScrub),
		callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
		timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
		callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
		ivrScript = isnull(@ivrScript,ivrScript),
		surveyPctg = isnull(@surveyPctg,surveyPctg),
		call_record = isnull(@call_record,call_record),
		startStopRecording = isnull(@dRestrictPlay, startStopRecording),
		leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
		manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
		callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
		callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
		funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
		sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
		prefijo = isnull(@prefijo, prefijo),
		exitAssisted = isnull(@exitAssisted, exitAssisted),
		previewDiscard = isnull(@previewDiscard, previewDiscard),
		rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo),
		timesPreview = isnull(@timesPreview, timesPreview),
		cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
		timesDiscard = isnull(@timesDiscard, timesDiscard),
		CampType = (CASE WHEN @callsBySurvey is not null AND @ivrScript is not null THEN
						CASE WHEN @callsBySurvey=0 and @ivrScript=0 THEN 0 
							ELSE 8 
						END
					WHEN @CampType is not null THEN @CampType 
					WHEN @progDial = 2 THEN 6 
					WHEN @progDial IS NOT NULL AND @progDial <> 2 THEN 0 
					WHEN CampType is not null THEN CampType ELSE 0 END),
		selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
		messagingOrder = isnull(@messagingorder, messagingOrder),
		autoStart = isnull(@autoStart,autoStart),
		recordHold = isnull(@recordHold, recordHold)

		Where cam_id = @cam_id

			IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

			Create table #ccCampsTable 
			(
				columnInfo VARCHAR(255),
				dataInfo VARCHAR(255),
				identifierInfo VARCHAR(255)
			)

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
			
			IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

			IF(@isCreating = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
				
			DELETE FROM #ccCampsTable WHERE columnInfo IN (''startStopRecording'');
			DELETE FROM #ccCampsTable WHERE dataInfo = '''';
				
			IF(@CampType = 6) DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'', ''cam_fDialOnWU'', ''ProgDial'');
			ELSE IF(@CampType = 5 AND @isCreating = 2) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'', ''cam_descripcion'', ''exitAssisted'');
			ELSE IF(@CampType = 5) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'');
			ELSE IF(@CampType = 7) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''messagingOrder'', ''autoStart'', ''rotativeAlgo'', ''id_anilist'', ''cam_descripcion'');
			ELSE DELETE FROM #ccCampsTable WHERE columnInfo IN (''previewDiscard'', ''CampType'', ''cam_fDialOnWU'', ''ProgDial'');

			IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			SELECT 
				(SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
				getDate(), 
				(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				@operation, 
				@module,
				CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
					THEN
						CASE
							WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
								CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
							WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN 
								CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
							WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
								CASE WHEN @Camptype = 5 THEN ''OUT_MANUAL_DIALING_WHATS'' ELSE CCCT.identifierInfo END
							ELSE
								CCCT.identifierInfo
							END
					ELSE
					''''
					END,
				CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
					CASE 
						WHEN CCCT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
							CASE WHEN CCCT.dataInfo = ''VOICEMAIL'' 
								THEN ''COMMON_VOICE_MAIL'' 
								ELSE 
									CASE WHEN CCCT.dataInfo IS NOT NULL THEN CCCT.dataInfo ELSE ''T&COMMON_NONE'' END 
								END
						WHEN CCCT.identifierInfo = ''OUT_DIALING_ORDER'' THEN 
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_DESCENDING'' ELSE ''COMMON_ASCENDING'' END

						WHEN CCCT.identifierInfo = ''OUT_SMS_MESSAGING_ORDER'' THEN 
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ASCENDING'' ELSE ''COMMON_DESCENDING'' END

						WHEN CCCT.identifierInfo = ''OUT_ANSWER_MACHINE_DETC'' THEN 
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_BASIC'' 
								WHEN CCCT.dataInfo = 1 THEN ''COMMON_LIGHT''
								WHEN CCCT.dataInfo = 2 THEN ''COMMON_MODERATE''
								WHEN CCCT.dataInfo = 3 THEN ''COMMON_HIGH''
								ELSE ''T&COMMON_NONE'' END

						WHEN CCCT.identifierInfo = ''OUT_ANI_MODE'' THEN 
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ANI_LOCAL'' 
								WHEN CCCT.dataInfo = 1 THEN ''COMMON_ANI_ROTATIVE''
								WHEN CCCT.dataInfo = 2 THEN ''COMMON_ANI_ROTATIVE_REG''
								WHEN CCCT.dataInfo = 3 THEN ''COMMON_ANI_ROTATIVE_SMART''
								ELSE ''T&COMMON_NONE'' END

						WHEN CCCT.identifierInfo = ''OUT_DIALING_MODE'' THEN 
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_PREDICTIVE'' 
								WHEN CCCT.dataInfo = 1 THEN ''COMMON_PROGRESIVE''
								ELSE ''COMMON_ASSISTED'' END

						WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
							CASE WHEN  @CampType = 5 THEN 
								CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
							ELSE
								CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_VIA_KEYPAD_LOG''
									WHEN CCCT.dataInfo = 2 THEN ''COMMON_VIA_CALLS_LOG''
									WHEN CCCT.dataInfo = 3 THEN ''COMMON_VIA_CALLS_LOG''
									ELSE ''T&COMMON_NONE'' END
							END

						WHEN CCCT.identifierInfo = ''OUT_ANI_LIST'' THEN
									ISNULL((SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo), CCCT.dataInfo)

						WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
						WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
													''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
													''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'') THEN
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
							
						ELSE CCCT.dataInfo END
				ELSE '''' END, 
				CASE WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
			FROM #ccCampsTable AS CCCT;

			EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
			IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

	if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
	begin
		EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
	end

	IF (@CampType IS NOT NULL AND @CampType IN (3, 5))
	BEGIN
		IF NOT EXISTS(SELECT camp_id FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id)
		BEGIN
			SELECT 0
			RETURN(0)
		END

		IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

		Create table #contactMeanOutTable 
		(
			columnInfo VARCHAR(255),
			dataInfo VARCHAR(255),
			identifierInfo VARCHAR(255)
		)

		EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @cam_id, @userId= @userid

		DECLARE @PrevConexionInfo VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id);

		set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then CASE WHEN @isCreating > 0 AND @PrevConexionInfo <> '''' THEN ''Ninguno'' ELSE '''' END else @ConexionInfo end
		UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
												closeConversationTime = CAST(@agentCloseConversationTime AS INT), answerTimeoutClient = @adminCloseConversationTime,
								allowFileAttachments = @allowFileAttachments,
					maxLimitQueueConversations = @maxLimitQueueConversations
		WHERE @CampType = meanContactTypeId AND camp_id = @cam_id

			
		IF(@isCreating > 0 AND @module > -1) BEGIN 
			EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';
			IF(@ConexionInfo IS NULL OR @ConexionInfo IN ('''',''0'',''None'',''Ninguno'') AND @PrevConexionInfo <> @ConexionInfo) UPDATE contactMeanOut SET conexionInfo = '''' WHERE @CampType = meanContactTypeId AND camp_id = @cam_id
		END

		DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''conexionInfo'') AND  dataInfo = '''';
		DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''ConnPass'', ''connUser'') ;

		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		SELECT 
			(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
			getDate(), 
			(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
			@operation, 
			@module, 
			CMOT.identifierInfo,
			CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
				CASE
					WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
						CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
					WHEN CMOT.identifierInfo = ''OUT_WHATS_ASSOCIATED_PHONE'' THEN
						CASE WHEN CMOT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMOT.dataInfo END
					ELSE CMOT.dataInfo END
			ELSE '''' END, 
			(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
		FROM #contactMeanOutTable AS CMOT;

		EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid;
		IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

		IF @CampType = 5 BEGIN
			update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
			update ccMetaWhatsAppNumbers set Cam_Id=0 where Cam_Id=@cam_id

			IF(@ConexionInfo <> '''')
			BEGIN
				IF EXISTS (SELECT number FROM ccWhatsAppNumbers WHERE number = @ConexionInfo)
					UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
				IF EXISTS (SELECT number FROM ccMetaWhatsAppNumbers WHERE number = @ConexionInfo)
					UPDATE ccMetaWhatsAppNumbers SET Cam_Id = @cam_id WHERE number = @ConexionInfo
			END
		END
	END 
	DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

	IF @cam_ShowCalifWnd = 1
	BEGIN
		IF NOT EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @cam_id and tipo = 1)
		BEGIN
			SELECT 0
			RETURN(0)
		END

		UPDATE ccCamps SET
		cam_ShowCalifWnd = ISNULL(@cam_ShowCalifWnd,cam_ShowCalifWnd)
		WHERE cam_id = @cam_id


		IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			SELECT 
				(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
				getDate(), 
				(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				@operation, 
				3, 
				''OUT_SHOW_DISPOSITIONS'',
				CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
				(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
		END

		SELECT 1
		RETURN(0)
	END

	UPDATE ccCamps SET
	cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
	where cam_id = @cam_id

	IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		SELECT 
			(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
			getDate(), 
			(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
			@operation, 
			3, 
			''OUT_SHOW_DISPOSITIONS'',
			CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
			(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
	END

	SELECT 2
	RETURN(0)

	set nocount off
	'
	EXEC (@sql)

	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
					@command int,
					@inboundId int
					AS
					BEGIN

					SET NOCOUNT ON;

					if @command=0
					begin
					select descripcion from ccInbound where Inbound_id = @inboundId
					end
					if @command=1 -- Voice campaign
					begin
						select 
						A.Inbound_id [InboundId],
						A.descripcion [Description],
						A.chat [MediaType],
						A.Status,
						isnull(gra.graphic_id,1) [Frame],
						A.tNotas,
						A.tMaxWaitCall,
						A.nMaxQue,
						A.tel_maxwait,
						A.tel_maxqueue,
						A.tel_outservice,
						A.tel_noct,
						A.ShowCalifWnd,
						A.editableCallKey [EditableCallKey],
						A.queuePosition [QueuePosition],
						A.tMaxQueueCallBack,
						A.stopRecording [StopRecording],
						A.dialPrefixOverflow [DialPrefixOverflow],
						AE.SurveyCamId [SurveyCamId],
						isnull(A.callerIdDesc, '''') [CallerIdDesc],
						isnull(A.startStopRecording,0) [StartStopRecording],
						case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then A.callBackSurveyAgent  else cast(0 as bit) end [CallBackSurveyAgent],
						case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then A.callBackSurveyClient else cast(0 as bit) end [CallBackSurveyClient],
						case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then cast(1 as bit) else cast(0 as bit) end [IsRelationSurvey],
						isnull(A.editableDtmf,0) [EditableDtmf],
						isnull(A.addDataCallBackReminder,0) [AddDataCallBackReminder],
						isnull(A.recordHold, 0) [RecordHold],
						isnull(AE.RecordCalls, 1) [RecordCalls],
						isnull(A.EditableContactData, 0) [EditableContactData]
						from ccInbound A
						left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
						left join ccInboundExtend AE on AE.Inbound_id = @inboundId
						left join ccCamps C on C.cam_id=A.cam_id
						where A.Inbound_id=@inboundId
					end
					if @command=2 -- WhatsApp campaign
					begin
						declare @numbers varchar(max)
						select @numbers=COALESCE(@numbers + '','', '''') + number from ccWhatsAppNumbers where inboundId = 0 and status = 1
						select @numbers=COALESCE(@numbers + '','', '''') + number from ccMetaWhatsAppNumbers where Inbound_Id = 0 and status = 1

						select i.Inbound_id [InboundId], i.descripcion [Description], i.chat [MediaType], i.Status, isnull(g.graphic_id,1) [Frame],
						ISNULL(c.conexionInfo,'''') [Number],
						ISNULL(@numbers,'''') [FreeNumbersStr],
						CAST(ISNULL(c.closeConversationTime, 0) AS INT) [MaxAnswerTime],
						ISNULL(c.answerTimeoutClient, 30) [MUTimeOutClient],
						ISNULL(c.allowFileAttachments, 0) [AllowFileAttachments],
						i.tNotas [tNotas],
						i.ExitWrapUpDisposition,
						i.ShowCalifWnd
						from ccInbound i left join ccRIAInboundGraph g on i.Inbound_id = g.Inbound_id
						left join contactMeanIn c on i.Inbound_id = c.inboundId and i.chat = 5 and c.meanContactTypeId = 5
						where i.Inbound_id=@inboundId
					end
					if @command=3 -- Email campaign
					begin
						select 
						A.Inbound_id [InboundId],
						A.descripcion [Description],
						A.chat [MediaType],
						A.Status,
						isnull(gra.graphic_id,1) [Frame],
						A.tNotas,
						A.ShowCalifWnd,
						C.conexionInfo [ConnInfo],
						C.connUser  [ConnUserName],
						C.ConnPass [ConnPwd],
						C.isActive [IsActive],
						C.timeAlertMessage,
						C.closeConversationTime [CloseConversationTime],
						C.answerTimeOut [AnswerTimeOut],
						C.name [SenderName]
						from ccInbound A
						left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
						left join contactMeanIn C on A.Inbound_id = C.inboundId and C.meanContactTypeId=1
						where A.Inbound_id=@inboundId
					end
					if @command=4 -- Chat campaign
					begin
						select 
						i.Inbound_id [InboundId],
						i.descripcion [Description],
						i.chat [MediaType],
						i.Status,
						isnull(ig.graphic_id,1) [Frame],
						i.tNotas,
						i.ShowCalifWnd,
						i.inactiveChatTime [InactiveChatTime],
						i.chatDomain [ChatDomain],
						i.chatTimeOverflow [ChatTimeOverflow],
						i.chatQueueOverflow [ChatQueueOverflow]
						from ccInbound i
						left join ccRIAInboundGraph ig on ig.Inbound_id=i.Inbound_id
						where i.Inbound_id =@inboundId
					end

					RETURN(0)

					SET NOCOUNT OFF;    
					END
	'
	EXEC (@sql)
	----------------------------------------------------------- End Carlos Muñoz -------------------------------------------------------------------------------
	----------------------------------------------------------- Start Jonathan Ramírez -------------------------------------------------------------------------
	set @process = 'Modify SP ccsp_WhatsAppInformationOut, se modifica valor de retorno Sin calificación'
	set @sql = '
	ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformationOut]
	@Option SMALLINT,
	@camId SMALLINT = 0,
	@ConversationId INT = 0,
	@AgentsAvailables INT = 0,
	@IncreaseDecreaseAgent BIT = NULL

	AS
	SET NOCOUNT ON
	IF @camId>0 and NOT EXISTS (SELECT * FROM ccCamps WHERE cam_Id = @camId AND CampType = 5) BEGIN
	    print (''Camp Is Not WhatsApp'')
	    return(-1);
	End

	 
	      
	DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
	--set @Today SMALLDATETIME = ''2022-03-24''
	IF @Option = 0 BEGIN-- Reset TABLES
	    TRUNCATE TABLE ccWAConversationsResult
	    TRUNCATE table ccWAOperatingSummaryOut;
	    TRUNCATE TABLE ccWAAverageConversationsOut;
	    TRUNCATE TABLE ccLastMessageAgentByConversationOut;
	END    
	else IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
	BEGIN
	    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut
	                WHERE CamId = @camId
	                AND (LastUpdate IS NULL
	                OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
	                OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
	    BEGIN
	        -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

	        DECLARE @AverageConversationTime INT = 0;
	        DECLARE @AverageDialogTime INT = 0;
	        DECLARE @AverageWaitingTime INT = 0;
	        DECLARE @MaximumWaitingTime INT = 0;
	        DECLARE @DefaultValue INT = 2
	        

	        SET @DefaultValue = @DefaultValue * 60;
	        DECLARE @LessThanDefault INT = 0;
	        DECLARE @ReceivedConversations INT = 0;
	        DECLARE @ServiceLevel SMALLINT = 0;

	        --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

	        SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
	                @AverageDialogTime = ROUND(AVG(tChatting), 4),
	                @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
	                @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
	                @ReceivedConversations = COUNT(conversationDate),
	                @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
	        FROM ccWhatsAppConversationsOut with(nolock) WHERE camId = @camId
	        AND requestDate >= @Today

	        SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

	        ----------------------------------------------------- Update table --------------------------------------------------------

	        IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE camId = @camId)
	        BEGIN
	            UPDATE ccWAAverageConversationsOut
	            SET AverageConversationTime = @AverageConversationTime,
	                AverageDialogTime = @AverageDialogTime,
	                AverageWaitingTime = @AverageWaitingTime,
	                MaximumWaitingTime = @MaximumWaitingTime,
	                ServiceLevel = @ServiceLevel,
	                StatusUpdate = 0,
	                LastUpdate = GETDATE()
	            WHERE CamId = @camId
	        END
	        ELSE
	        BEGIN
	            INSERT INTO ccWAAverageConversationsOut (CamId, AverageConversationTime, AverageDialogTime,
	                                                    AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
	            VALUES(@camId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
	                    @ServiceLevel, 0 , GETDATE())
	        END
	    END
	    --------------------------------- Results -----------------------------------

	    if exists (select * from ccWAOperatingSummaryOut with(nolock) where CamId=@camId
	                and (OnQueue<0 or Assigned<0)
	                ) begin
	                
	            set @Today =convert(date,getdate(),121)

	            ;with waOperationSummary as(
	            select 
	            CamId
	            ,count(case when finishedBy=1 then 1 end) Attended
	            ,count(case when onQueue=1 and finishedBy=0 then 1 end) onQueue
	            ,count(case when finishedBy=0 and agentId>0 then 1 end) Assigned
	            ,count(*) Request
	            ,count(case when finishedBy=2 then 1 end) EndedBySystem
	            from ccWhatsAppConversationsOut with(nolock)
	            where camId = @camId and requestDate>=@Today
	            group by CamId
	            )
	            update A 
	            set A.Attended=B.Attended, A.Assigned=B.Assigned
	            
	            ,A.Request=B.Request,A.EndedBySystem=B.EndedBySystem
	            from ccWAOperatingSummaryOut A 
	            inner join waOperationSummary B on A.CamId=B.CamId
	    end

	    SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
	            ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
	            ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
	            ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
	            ISNULL(ServiceLevel, 0) AS ServiceLevel,
	            ISNULL(Attended, 0) AS Attended,
	            ISNULL(Assigned, 0) AS Assigned,
	            ISNULL(OnQueue, 0) AS OnQueue,
	            ISNULL(EndedBySystem, 0) AS EndedBySystem,
	            ISNULL(Available, 0) AS Available,
	            ISNULL(Request, 0) AS Request
	    FROM ccWAAverageConversationsOut conv
	    RIGHT JOIN ccWAOperatingSummaryOut summary ON conv.CamId = summary.camId
	    WHERE conv.CamId = @camId OR summary.camId = @camId
	END
	else IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
	                -- Average Queue/Waiting Time, and Service Level)
	BEGIN
	    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE CamId = @camId)
	        BEGIN
	            UPDATE ccWAAverageConversationsOut SET StatusUpdate = 1
	            WHERE CamId = @camId
	        END
	        ELSE
	        BEGIN
	            INSERT INTO ccWAAverageConversationsOut (CamId, StatusUpdate)
	            VALUES(@camId, 1)
	        END
	END
	else IF @Option = 3 -- Save time from accepted conversation by agent
	BEGIN
	    IF @ConversationId IS NOT NULL
	    BEGIN
	        UPDATE ccWhatsAppConversationsOut SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
	        --Save Conversation Assigned
	        SELECT @camId = camId FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;
	        UPDATE ccWAOperatingSummaryOut SET Assigned = (Assigned + 1) WHERE camId = @camId
	        
	    END
	END
	else IF @Option = 4 -- Get Disposition Information
	BEGIN
	declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
	select @nIdioma = case valor when 0 then ''Sin calificación'' else ''No disposition'' end
	from ccsettings where setting_id = 27 -- 0esp
	SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
	        ISNULL(disposition.calif_id, 0) AS DispositionId,
	        COUNT(whatsConv.disposition) AS Total,
	        ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
	        COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
	FROM ccWhatsAppConversationsOut whatsConv with(nolock)
	LEFT JOIN ccTipoCalifOUT disposition ON disposition.calif_id = whatsConv.disposition
	WHERE camId = @camId AND assignDate >= @Today
	    and whatsConv.conversationStatus != 2
	GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
	END
	else IF @Option = 5 -- Get Subdisposition Information
	BEGIN
	    SELECT relation.calif_id AS DispositionId,
	            subDispositions.califSubDesc AS SubDispositionsName,
	            COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
	    FROM cctipoSubCalifRel relation
	    INNER JOIN ccTipoCalifSubOUT subDispositions ON subDispositions.califSub_id = relation.califSub_id
	    INNER JOIN ccWhatsAppConversationsOut whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
	    WHERE whatsConv.camId = @camId AND
	            whatsConv.assignDate >= @Today AND
	            relation.tipoSubRel = 0
	    GROUP BY subDispositions.califSubDesc, relation.calif_id
	END
	ELSE IF @Option = 6 -- Agents Availables
	BEGIN
	    IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId)
	        BEGIN
	            INSERT INTO ccWAOperatingSummaryOut (camId, Available) VALUES (@camId, @AgentsAvailables);
	        END
	    ELSE
	        BEGIN
	            UPDATE ccWAOperatingSummaryOut SET Available = @AgentsAvailables WHERE camId = @camId
	        END
	END

	ELSE IF @Option = 7 -- Whats Conversations Results
	BEGIN
	    SELECT ISNULL(SentMsg, 0) AS SentMsg,
	            ISNULL(Delivered, 0) AS Delivered,
	            ISNULL(NotDelivered, 0) AS NotDelivered,
	            ISNULL(ReadMsg, 0) AS ReadMsg,
	            ISNULL(NotSupported, 0) AS NotSupported
	    FROM ccWAConversationsResult
	    WHERE camId = @camId
	END
	    
	SET NOCOUNT OFF'
	EXEC(@sql)

	----------------------------------------------------------- End Jonathan Ramírez ---------------------------------------------------------------------------
------------------------------------------------------------ Gaby K064034 --------------------------------------------------------------------------------
	SET @process = 'WhatsApp Masivo - New column Max Whats Out'	
	SET @sql='
	if not exists (select * from sys.columns where name = N''maxWhatsOut'' and Object_ID = Object_ID(N''ccRIACat_Areas''))
    begin
        alter table ccRIACat_Areas add maxWhatsOut tinyint default(3)
    end
	'
	EXEC(@sql)

	SET @process = 'WhatsApp Masivo - Delete SP ccsp_RIA_ABCAreas'	
	SET @sql='
	if exists (select * from sys.procedures where name = N''ccsp_RIA_ABCAreas'')
    begin
        DROP PROCEDURE ccsp_RIA_ABCAreas;
    end
	'
	EXEC(@sql)

	SET @process = 'WhatsApp Masivo - Create SP ccsp_RIA_ABCAreas'	
	SET @sql='
	CREATE PROCEDURE ccsp_RIA_ABCAreas
@option smallint,
@IDArea smallint,
@Descripcion varchar(40),
@maxMails smallint = 3, 
@maxChats smallint = 3,
@maxTweets smallint = 3,
@maxWhats smallint = 3,
@maxWhatsOut smallint = 3,
@defCampaing smallint = NULL, 
@isKolob bit = 0,
@toolsTransfer bit = 0
AS

set nocount on



if @option = 1 begin --Selected Area
 Select a.IDArea, AreaName, isnull(a.maxChats,0) as maxChats, isnull(maxMails,3) maxMails,
 isnull(users,0) users, isnull(admins,0) admins,
 isnull(camps,0) camps, isnull(acds,0) acds  ,isnull(a.maxTweets,3) as maxTweets,isnull(a.maxWhats,3) as maxWhats,
 isnull(a.maxWhatsOut,3) as maxWhatsOut, ToolsTransfer
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
	Insert into ccRIACat_Areas (AreaName,maxMails,maxChats,maxTweets,maxWhats,maxWhatsOut,defCampaing,CreateDate,ToolsTransfer) values (@Descripcion,@maxMails,@maxChats,@maxTweets,@maxWhats,@maxWhatsOut,@defCampaing,Getdate(),@toolsTransfer)
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
	EXEC(@sql)

	SET @process = 'WhatsApp Masivo - Delete SP ccsp_GalateaAreas'	
	SET @sql='
		if exists (select * from sys.procedures where name = N''ccsp_GalateaAreas'')
    begin
        DROP PROCEDURE ccsp_GalateaAreas;
    end
	'
	EXEC(@sql)

	SET @process = 'WhatsApp Masivo - Create SP ccsp_GalateaAreas'	
	SET @sql='
		create procedure ccsp_GalateaAreas 
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
    @toolsTransfer tinyint = NULL,
	@maxWhats smallint = 3,
	@maxWhatsOut smallint = 3
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
			a.maxWhats Whats,
			a.maxWhatsOut WhatsOut,
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
            maxTweets tinyint,
			maxWhats tinyint,
			maxWhatsOut tinyint,
            toolsTransfer tinyint
        )
        insert into #Areas
        EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@defCampaing=@defCampaing, @isKolob=1,@maxWhats=@maxWhats, @maxWhatsOut=@maxWhatsOut
        select a.*,rca.CreateDate,Isnull(rca.defCampaing,0) as defCampaing
        from #Areas a
        inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea

        IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
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
            @toolsTransfer=@toolsTransfer,
			@maxWhats=@maxWhats,
			@maxWhatsOut=@maxWhatsOut
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

                update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),maxWhats=isnull(@maxWhats,maxWhats),maxWhatsOut=isnull(@maxWhatsOut,maxWhatsOut),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=case when @toolsTransfer = 3 then ToolsTransfer else @toolsTransfer end where IDArea=@IDArea

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
                            WHEN AT.identifierInfo = ''T&SET_TOOLSTRANSFER'' THEN
                                CASE
                                    WHEN @toolsTransfer = 1 THEN ''COMMON_ENABLED''
                                    ELSE ''COMMON_DISABLED'' END
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
	EXEC(@sql)

	SET @process = 'WhatsApp Masivo - Delete SP ccsp_Multimedia2'	
	SET @sql='
		if exists (select * from sys.procedures where name = N''ccsp_Multimedia2'')
    begin
        DROP PROCEDURE ccsp_Multimedia2;
    end
	'
	EXEC(@sql)

	SET @process = 'WhatsApp Masivo - Create SP ccsp_Multimedia2'	
	SET @sql='
		CREATE PROCEDURE ccsp_Multimedia2 @action INT, @inboundId INT = NULL, @userId INT = NULL
, @senderId INT = NULL,@camType bit=0
,@multimediaType int =null
AS
BEGIN
	SET NOCOUNT ON;

	IF @action = 1
	BEGIN --Lista Cam Or  ACD
		if @camType=0 begin		
			SELECT DISTINCT A.inbound_id AS Id, A.chat AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets,
			cast(isnull(C.maxWhats, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId
			FROM ccInbound A
			INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
			WHERE (@inboundId IS NULL OR @inboundId = A.Inbound_id)
			and (@multimediaType is null or @multimediaType =-1 or A.chat=@multimediaType)
		end
		else begin
			SELECT DISTINCT A.cam_id AS Id,convert(tinyint, case when A.CampType =5  then A.CampType else 1 end) AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets,
			cast(isnull(C.maxWhatsOut, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId
			FROM ccCamps A
			INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
			WHERE (@inboundId IS NULL OR @inboundId = A.cam_id)
			and (@multimediaType is null or @multimediaType =-1 or A.CampType=@multimediaType)
		end
	END
	ELSE IF @action = 2
	BEGIN --Lista Agentes
		if @camType=0 begin
			SELECT DISTINCT A.User_id AS [Id], C.idCampEsp AcdId, isnull(skill, 8) Skill
			FROM ccRIAWorkGroupUsers A
			INNER JOIN ccusers B ON A.User_id = B.User_id
			INNER JOIN ccRIACampEspWG C ON C.IDWG = A.IDWG -- AND C.Tipo = 0
			INNER JOIN ccInbound D ON C.idCampEsp = D.inbound_id  and D.IDArea is not null
			LEFT JOIN ccskills S ON S.inbound_id = D.inbound_id AND S.user_id = B.user_id
			WHERE B.TipoUser_id = 1 AND (@userId IS NULL OR @userId = A.User_id)
			and (@multimediaType is null or @multimediaType =-1 or D.chat=@multimediaType)
			ORDER BY A.User_id
		end
		else begin
			SELECT DISTINCT A.User_id AS [Id], C.idCampEsp AcdId, isnull(skill, 8) Skill
			FROM ccRIAWorkGroupUsers A
			INNER JOIN ccusers B ON A.User_id = B.User_id
			INNER JOIN ccRIACampEspWG C ON C.IDWG = A.IDWG -- AND C.Tipo = 0
			INNER JOIN ccCamps D ON C.idCampEsp = D.cam_id  and D.IDArea is not null
			LEFT JOIN ccskills S ON S.inbound_id = D.cam_id AND S.user_id = B.user_id
			WHERE B.TipoUser_id = 1 AND (@userId IS NULL OR @userId = A.User_id)
			and (@multimediaType is null or @multimediaType =-1 or D.CampType=@multimediaType)
			ORDER BY A.User_id
		end
	END
	ELSE IF @action = 3
	BEGIN --List Sender Mail
		SELECT A.contactMeanOutId AS Id, ISNULL(R.inboundId, 0) AS AcdId, A.isActive AS IsActive
		FROM contactMeanOut A
		LEFT JOIN relationContactMeanOutInbound R ON A.contactMeanOutId = R.contactMeanOutId
		WHERE (@senderId IS NULL OR @senderId = A.contactMeanOutId) and A.meanContactTypeId = 1
	END
	ELSE IF @action = 4
	BEGIN --List ACD Whatsapp
		if @camType=0 begin
			SELECT cast(Inbound_id as int) AS Id
			FROM ccInbound
			WHERE chat=5
		end
		else begin
			SELECT cast(cam_id as int) AS Id
			FROM ccCamps
			WHERE CampType = 5
		end
	END
END
	'
	EXEC(@sql)

	set @process = 'DEV2 Whatsapp conversations by agent identifier (In)'
	set @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description=''OUT_WHATS_ASSIGN_SAME_AGENT'')
	begin 
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) 
		values (''T$WHATSAPP_CONVO_BY_AGENT'',''Conversaciones de WhatsApp de entrada por agente'',''Inbound WhatsApp conversations per agent'',''Conversas de WhatsApp de entrada por agente'')
	end'
	EXEC(@sql)

	set @process = 'DEV2 Whatsapp conversations by agent identifier (Out)'
	set @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description=''OUT_WHATS_ASSIGN_SAME_AGENT'')
	begin 
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) 
		values (''T$WHATSAPP_OUT_CONVO_BY_AGENT'',''Conversaciones de WhatsApp de salida por agente'',''Outbound WhatsApp conversations per agent'',''Conversas de WhatsApp de saída por agente'')
	end'
	EXEC(@sql)

	set @process = 'DEV2 Whatsapp Conversations log period Identifier '
	set @sql = '
	if not exists(select Description from ccGalateaIdentifiers where Description=''OUT_WHATS_ASSIGN_SAME_AGENT'')
	begin 
		insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) 
		values (''T$WA_CONVERSATION_LOG'',''Tiempo de historial de conversaciones (días)'',''Conversations log period (days)'',''Tempo de histórico de conversas (dias)'')
	end'
	EXEC(@sql)

------------------------------------------------------------ Ivan Martin CW-8618 --------------------------------------------------------------------------------
	set @process = 'CW-8618 Se agrega un el siguiente índice a la tabla smsoutSourceMessage para mejorar el rendimiento del SP ccsp_OUTGetNewJobsSMS'
	set @sql = 'IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N''IX_smsoutSourceMessage_smsout_id'' AND object_id = OBJECT_ID(N''smsoutSourceMessage''))
				BEGIN
					CREATE NONCLUSTERED INDEX IX_smsoutSourceMessage_smsout_id ON smsoutSourceMessage (smsout_id);
				END'
	EXEC(@sql)
------------------------------------------------------------ End Ivan Martin CW-8618 --------------------------------------------------------------------------------

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
