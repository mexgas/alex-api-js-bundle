/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K053000

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
SET @versionfix = 40
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

	-----------------------------------------------------BEGIN JCL -----------------------------------------------------------------

		SET @process = 'CW-7958 Historial movimientos calificaciones'
		SET @Sql = 'if not exists (select * from ccGalateaOperations where OperationId=78)
    begin
		insert into ccGalateaOperations(OpTagEs, OpTagEn, OpTagPt, OperationId)
		values(''Editar calificación de salida'', ''Edit outbound disposition'', ''Editar classificação de saída'', 78)
  	end'

		EXEC (@Sql)
	-----------------------------------------------------END JCL -----------------------------------------------------------------s

	-----------------------------------------------------BEGIN KR089000 Notificación recepción y finalización de llamada -----------------------------------------------------------------
	
	SET @process = 'KR089000 Alter Table Add Column ccAgentMsgRelationFiles.MsgType';
	SET @sql = 'IF NOT EXISTS( SELECT * FROM sys.columns WHERE name = N''MsgType'' AND Object_ID = Object_ID(N''ccAgentMsgRelationFiles''))
BEGIN
	ALTER TABLE ccAgentMsgRelationFiles ADD MsgType TINYINT;
END';
	EXEC (@sql);

	SET @process = 'KR089000 Alter Table Add Column ccAgentMsgFiles.idArea';
	SET @sql = 'IF NOT EXISTS( SELECT * FROM sys.columns WHERE name = N''idArea'' AND Object_ID = Object_ID(N''ccAgentMsgFiles''))
BEGIN
	ALTER TABLE ccAgentMsgFiles ADD idArea SMALLINT NOT NULL DEFAULT(-1);
END';
	EXEC (@sql);

	SET @process = 'KR089000 Alter Table Add Column ccAgentMsgFiles.messageType';
	SET @sql = 'IF NOT EXISTS( SELECT * FROM sys.columns WHERE name = N''messageType'' AND Object_ID = Object_ID(N''ccAgentMsgFiles''))
BEGIN
	ALTER TABLE ccAgentMsgFiles ADD messageType tinyint NOT NULL DEFAULT(-1);
END';
	EXEC (@sql);

	SET @process = 'KR089000 Add relationTableColumnIdentifiers and ccGalateaOperations (80,81,82,83,84,85,86,87,88,89)';
	SET @sql = 'IF NOT EXISTS( SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = N''COMMON_RELATION_MSG_AGENT'')
BEGIN
	INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) 
	VALUES (''COMMON_RELATION_MSG_AGENT'',''ccAgentMsgRelationFiles'',''CamId'');
END

IF NOT EXISTS( SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = N''COMMON_MSG_AGENT_NAME'')
BEGIN
	INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) 
	VALUES (''COMMON_MSG_AGENT_NAME'',''ccAgentMsgFiles'',''msgName'');
END

IF NOT EXISTS( SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = N''COMMON_MSG_AGENT_DESCRIPTION'')
BEGIN
	INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) 
	VALUES (''COMMON_MSG_AGENT_DESCRIPTION'',''ccAgentMsgFiles'',''Description'');
END

IF NOT EXISTS( SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = N''COMMON_MSG_AGENT_FILE'')
BEGIN
	INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) 
	VALUES (''COMMON_MSG_AGENT_FILE'',''ccAgentMsgFiles'',''msgFile'');
END

IF NOT EXISTS( SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = N''COMMON_MSG_AGENT_GLOBAL'')
BEGIN
	INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName) 
	VALUES (''COMMON_MSG_AGENT_GLOBAL'',''ccAgentMsgFiles'',''idArea'');
END

IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''COMMON_MSG_AGENT_NAME'')
	BEGIN
		INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
		VALUES (''COMMON_MSG_AGENT_NAME'',''Nombre'',''Name'',''Nome'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''COMMON_MSG_AGENT_DESCRIPTION'')
	BEGIN
		INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
		VALUES (''COMMON_MSG_AGENT_DESCRIPTION'',''Descripción'',''Description'',''Descrição'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''COMMON_MSG_AGENT_FILE'')
	BEGIN
		INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
		VALUES (''COMMON_MSG_AGENT_FILE'',''Archivo'',''File'',''Arquivo'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''COMMON_MSG_AGENT_GLOBAL'')
	BEGIN
		INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
		VALUES (''COMMON_MSG_AGENT_GLOBAL'',''Global'',''Global'',''Global'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''COMMON_RELATION_MSG_AGENT'')
	BEGIN
		INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
		VALUES (''COMMON_RELATION_MSG_AGENT'',''Llamada nueva'',''New call'',''Chamada nova'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaIdentifiers WHERE Description = N''COMMON_RELATION_MSG_AGENT_HANG_UP'')
	BEGIN
		INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
		VALUES (''COMMON_RELATION_MSG_AGENT_HANG_UP'',''Llamada finalizada'',''Finished call'',''Chamada encerrada'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 80)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
		VALUES (80,''Asignar audio de salida'',''Assign outbound audio'',''Atribuir áudio de saída'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 81)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
		VALUES (81,''Desasignar audio de salida'',''Unassign outbound audio'',''Cancelar atribuição de áudio de saída'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 82)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
		VALUES (82,''Crear audio (llamada nueva)'',''Create audio (New call)'',''Criar áudio (Chamada nova)'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 83)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
		VALUES (83,''Editar audio (llamada nueva)'',''Edit audio (New call)'',''Editar áudio (Chamada nova)'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 84)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
		VALUES (84,''Eliminar audio (llamada nueva)'',''Delete audio (New call)'',''Excluir áudio (Chamada nova)'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 85)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
		VALUES (85,''Crear audio (Llamada finalizada)'',''Create audio (Finished call)'',''Criar áudio (Chamada encerrada)'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 86)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
		VALUES (86,''Editar audio (Llamada finalizada)'',''Edit audio (Finished call)'',''Editar áudio (Chamada encerrada)'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 87)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
		VALUES (87,''Eliminar audio (Llamada finalizada)'',''Delete audio (Finished call)'',''Excluir áudio (Chamada encerrada)'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 88)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
		VALUES (88,''Asignar audio de entrada'',''Assign inbound audio'',''Atribuir áudio de entrada'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 89)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
		VALUES (89,''Desasignar audio de entrada'',''Unassign inbound audio'',''Cancelar atribuição de áudio de entrada'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaModules WHERE ModuleId = 10)
	BEGIN
		INSERT INTO ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt) 
		VALUES (10,''Mensajes automáticos'',''Automatic messages'',''Mensagens automáticas'');
	END

IF NOT EXISTS( SELECT * FROM ccGalateaModOpRelation WHERE OperationId = 80)
	BEGIN
		INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) 
		VALUES (10,80);
	END

IF NOT EXISTS( SELECT * FROM ccGalateaModOpRelation WHERE OperationId = 81)
	BEGIN
		INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) 
		VALUES (10,81);
	END

IF NOT EXISTS( SELECT * FROM ccGalateaModOpRelation WHERE OperationId = 82)
	BEGIN
		INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) 
		VALUES (10,82);
	END

IF NOT EXISTS( SELECT * FROM ccGalateaModOpRelation WHERE OperationId = 83)
	BEGIN
		INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) 
		VALUES (10,83);
	END

IF NOT EXISTS( SELECT * FROM ccGalateaModOpRelation WHERE OperationId = 84)
	BEGIN
		INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) 
		VALUES (10,84);
	END

IF NOT EXISTS( SELECT * FROM ccGalateaModOpRelation WHERE OperationId = 85)
	BEGIN
		INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) 
		VALUES (10,85);
	END

IF NOT EXISTS( SELECT * FROM ccGalateaModOpRelation WHERE OperationId = 86)
	BEGIN
		INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) 
		VALUES (10,86);
	END

IF NOT EXISTS( SELECT * FROM ccGalateaModOpRelation WHERE OperationId = 87)
	BEGIN
		INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) 
		VALUES (10,87);
	END

IF NOT EXISTS( SELECT * FROM ccGalateaModOpRelation WHERE OperationId = 88)
	BEGIN
		INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) 
		VALUES (10,88);
	END

IF NOT EXISTS( SELECT * FROM ccGalateaModOpRelation WHERE OperationId = 89)
	BEGIN
		INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) 
		VALUES (10,89);
	END
';
	EXEC (@sql);

	SET @process = 'KR089000 insert ccTipoMsgs (17,18,19) ';
	SET @sql = 'if not exists(select * from ccTipoMsgs where tipomsg_id=17) begin
    insert into ccTipoMsgs values(17,''Agent message when call starts'',''Agent message when call starts'')
end

if not exists(select * from ccTipoMsgs where tipomsg_id=18) begin
    insert into ccTipoMsgs values(18,''Agent message when call finally'',''Agent message when call finally'')
end

if not exists(select * from ccTipoMsgs where tipomsg_id=19) begin
    insert into ccTipoMsgs values(19,''Agent message when inbound call finally'',''Agent message when inbound call finally'')
end';
	EXEC (@sql);


	SET @process = 'KR089000 Alter SP ccsp_GalateaAgentAutomaticMessages @action = 1 add IdArea,MessageType,@action = 2 insert , @idArea, @messageType,@action = 4 if add where and MsgType = @messageType, ccAgentMsgRelationFiles, @action=12,13 add new action';
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAgentAutomaticMessages] 
@action as tinyint,
@msgName as varchar(40) = '''',
@msgFile as varchar(100) = null,
@Description as varchar(40) = '''',
@duration as int = -1,
@CampType tinyint = 0,
@msgIdLst varchar(8000) = null,
@camId int =null,
@MsgId int = null,
	@userId smallint = NULL,
	@idArea smallint = NULL,
	@messageType tinyint = NULL
AS
BEGIN
SET NOCOUNT ON
declare @tableMsgId table(MsgId int not null)
declare @campName varchar(70)
	declare @idCampUnassign int
	DECLARE @operation INT

	if @action in (3,7) begin --Assin/Unassign
        if @CampType=0
                select @campName =descripcion from ccInbound where Inbound_id=@camId
        else
                select @campName =cam_descripcion from ccCamps where cam_id=@camId
end

if @action = 1  -- GET_AUDIO_CATALOG
begin
        select ISNULL(msgName, msgFile) [MsgName], [Description] [MsgDescription], [MsgFile] [MsgFile], [MsgId] [MsgId], [idArea][IdArea], [messageType][MessageType] from ccAgentMsgFiles where idArea in (-1, @idArea)        
        return (0)
end
else if @action = 2 --CREATE_NEW_MSG
begin
        if EXISTS(select msgName from ccAgentMsgFiles where msgName=@msgName)
				begin
						select -1 as result
				end
        else
				begin
						insert into ccAgentMsgFiles (msgFile, [Description], Duration, msgName, idArea, messageType) 
						values (@msgFile, @Description, @duration, @msgName, @idArea, @messageType)
						select cast(@@identity as int) result              
        end 

end 
else IF @action = 3 -- Assing
begin   
        if not exists(select MsgId from ccAgentMsgFiles where MsgId=@MsgId)
        begin
                select ''0'' as result
                return(0)
        end

        if exists(select MsgId from [ccAgentMsgRelationFiles] where CamId=@camId and CamType=@CampType and MsgType = @messageType)
        begin
                select ''-1'' as result
                return(0)
        end

        insert into ccAgentMsgRelationFiles (MsgId, CamId, CamType, MsgType) values(@MsgId,@camId,@CampType,@messageType)

        select @campName

end

else IF @action = 4 -- GET_CAMP_MESSAGES_RELATION
begin   
        select MsgId from [ccAgentMsgRelationFiles] where CamId=@camId and CamType=@CampType and MsgType = @messageType          
end
else IF @action = 5 -- DELETE_AUDIO_MSG
begin

        insert into @tableMsgId
        select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')

        if exists(select A.MsgId from [ccAgentMsgRelationFiles] A 
                          inner join @tableMsgId B on A.MsgId=B.MsgId
        )
        begin
                select 0 as result
                return(0)
        end

         delete A from ccAgentMsgFiles A 
         inner join @tableMsgId B on A.MsgId=B.MsgId
         
         select 1 as result  
         return(0)
end
        
else if @action = 6 --EDIT_AUDIO_MSG
BEGIN    
        update ccAgentMsgFiles set [Description] = isnull(@Description,[Description]), MsgName = isnull(@msgName,MsgName),
        MsgFile = isnull(@msgFile,MsgFile), Duration=case when @duration is null or @duration<=0 then Duration else @duration end,
			idArea = isnull(@idArea, idArea)
        where MsgId = @MsgId    
END
else IF @action = 7 -- UnAssing
begin           
        if not exists(select MsgId from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType and MsgType = @messageType)
        begin
                select ''-1'' as result
                return(0)
        end
			else begin
				select @idCampUnassign =CamId from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType and MsgType = @messageType
			end

        delete from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType 
        select @campName
end

else IF @action = 8 -- list fileName
begin                           
        insert into @tableMsgId
        select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')
        
        select A.MsgFile from ccAgentMsgFiles A 
                          inner join @tableMsgId B on A.MsgId=B.MsgId
end
else IF @action = 9 -- Relation CampIn and MsgFile
begin                           
        select A.CamId,B.MsgFile,B.Duration from [ccAgentMsgRelationFiles] A
        inner join ccAgentMsgFiles B on A.MsgId=B.MsgId
        where CamType=@CampType 

end
else IF @action = 10 -- Relation CampIn and MsgFile
begin
        select MsgId,MsgFile ,Duration from ccAgentMsgFiles where MsgId=@MsgId

END
ELSE IF @action = 11 -- Relation Campaign and Audio Msg
	BEGIN
			(select CC.cam_id as Camp_Id, Camp_Type = 1,ISNULL(cam_descripcion,'''''''') as [Name], Graphics.frame as Frame, Type = ISNULL(IM.MsgType ,17), ISNULL(CC.IDArea,0) as IdArea, ISNULL(AREas.AreaName,'''') as AreaName
			from ccCamps as CC with(nolock) 
			left join ccRIACat_Areas as AREas with(nolock) on CC.IDArea = AREas.IDArea
			inner join ccRIACampsGraph as CampsGraph on CC.cam_id = CampsGraph.cam_id
			inner join ccRIAGraphics as Graphics on Graphics.graphic_id = CampsGraph.graphic_id
			inner join ccAgentMsgRelationFiles IM on IM.CamId = CC.cam_id
			Where IM.MsgId = @MsgId and IM.CamType = 1) 
				UNION
			(select IC.Inbound_id as Camp_Id, Camp_Type = 0,ISNULL(descripcion,'''''''') as [Name], Graphics.frame as Frame, Type = ISNULL(IM.MsgType ,16), ISNULL(IC.IDArea,0) as IdArea, ISNULL(AREas.AreaName,'''') as AreaName
			from ccInbound as IC with(nolock) 
			left join ccRIACat_Areas as AREas with(nolock) on IC.IDArea = AREas.IDArea
			inner join ccRIAInboundGraph as CampsGraph on IC.Inbound_id = CampsGraph.Inbound_id
			inner join ccRIAGraphics as Graphics on Graphics.graphic_id = CampsGraph.graphic_id
			inner join ccAgentMsgRelationFiles IM on IM.CamId = IC.Inbound_id
			Where IM.MsgId = @MsgId and IM.CamType = 0)
	END
	else IF @action = 12 -- list MsgName
begin                           
        insert into @tableMsgId
        select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')
        
        select A.MsgName from ccAgentMsgFiles A 
                          inner join @tableMsgId B on A.MsgId=B.MsgId
end
	else IF @action = 13 -- getAudioInformation
begin                           
        select [MsgName] [MsgName], [Description] [MsgDescription], [MsgFile] [MsgFile], [idArea][IdArea] from ccAgentMsgFiles where MsgId = @MsgId
end
	
END';
	EXEC (@sql);
-----------------------------------------------------END KR089000 Notificación recepción y finalización de llamada -----------------------------------------------------------------
-- BEGIN CW-8113 -----------------------------------------------------------------

	SET @process = 'CW-8113 Drop proc ccsp_AgentGetCalificaciones'
	SET @sql = 'IF EXISTS(SELECT * FROM sys.procedures WHERE name = N''ccsp_AgentGetCalificaciones'')
			    BEGIN
			        DROP PROCEDURE ccsp_AgentGetCalificaciones;
			    END'
	EXEC(@sql)

	SET @process = 'CW-8113 Create procedure ccsp_AgentGetCalificaciones, se agrega orden por descripción en campañas de salida)';
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_AgentGetCalificaciones] @inOut  TINYINT
                                                    ,

/**********
0 in, 1 out
**********/

                                                    @cam_id INT, 
                                                    @isXml  BIT     = 1
AS
     SET NOCOUNT ON;
     DECLARE @sql NVARCHAR(MAX);
     IF @inOut = 0
         BEGIN
             IF EXISTS
             (
                 SELECT calif.calif_id
                 FROM ccTipoCalif AS calif
                      JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
                      LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id
                                                            AND rel.tipoSubRel = 1
                      LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
                 WHERE cam_id = @cam_id
                       AND tipo = @inOut
             )
                 BEGIN
                     DECLARE @relationCamId INT;
                     SELECT @relationCamId = cam_id
                     FROM ccInbound
                     WHERE Inbound_id = @cam_id;
                     IF @relationCamId IS NULL
                         BEGIN
                             SET @relationCamId = 0
                     END;
                     SET @sql = '';WITH disposition
    AS (SELECT DISTINCT
             1 AS tag,NULL AS parent,calif.calif_id AS "selection!1!id",calif.Description AS "selection!1!string",calif.orden AS "selection!1!califorden",
			 ISNULL(calif.EndConversation,0) AS "selection!1!endConversation",NULL AS "subSelection!2!id",
			 NULL AS "subSelection!2!string",NULL AS "subSelection!2!orden",NULL AS "subSelection!2!endConversation",
			 ISNULL(calif.CanReprogram,0) AS "selection!1!canReprogram",NULL AS "subSelection!2!canReprogram"
        FROM ccTipoCalif AS calif
        INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND camp.cam_id = @cam_id AND camp.tipo = @inOut
        LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 1
        LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
        WHERE calif.CanReprogram = 0 OR calif.CanReprogram = 1 AND @relationCamId > 0
        UNION
        SELECT DISTINCT
             2 AS tag,1 AS parent,calif.calif_id AS "selection!1!id",NULL AS "selection!1!string",calif.orden AS "selection!1!califorden",
			 ISNULL(calif.EndConversation,0) AS "selection!1!endConversation",sb.califsub_id AS "subSelection!2!id",
			 sb.califSubDesc AS "subSelection!2!string",CAST(sb.orden AS INT) AS "subSelection!2!orden",
			 ISNULL(sb.EndConversation,0) AS "subSelection!2!endConversation",NULL AS "selection!1!canReprogram",ISNULL(sb.CanReprogram,0) AS "subSelection!2!canReprogram"
        FROM ccTipoCalif AS calif
        INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND camp.cam_id = @cam_id AND camp.tipo = @inOut
        LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 1
        LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
        WHERE sb.califsub_id IS NOT NULL AND (sb.CanReprogram = 0 OR sb.CanReprogram = 1 AND @relationCamId > 0))
'';
                     IF @isXml = 1
                         BEGIN
                             SET @sql = @sql + ''select * from disposition
               order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type'';
                     END;
                     ELSE
                         BEGIN
                             SET @sql = @sql + ''select 
tag as Tag, isnull(parent,0) as Parent, "selection!1!id" as Id,isnull("selection!1!string",'''''''') as Description,
cast("selection!1!califorden" as int) as Orden, 
"selection!1!endConversation" EndConversation, isnull("subSelection!2!id",0) as SubId,
isnull("subSelection!2!string",'''''''') as SubDescription, 
cast(isnull("subSelection!2!orden",0) as int) as SubOrden,   
--CAST(  ROW_NUMBER() OVER(PARTITION BY parent ORDER BY "subSelection!2!orden" ASC) as INT) AS SubOrden,
isnull("subSelection!2!endConversation",0) as SubEndConversation, 
isnull("selection!1!canReprogram",0) as CanReprogram,isnull("subSelection!2!canReprogram",0) as SubCanReprogram
FROM disposition'';
                     END;
                              PRINT @sql

                     EXEC sp_executesql 
                          @sql, 
                          N''@cam_id int, @InOut tinyint,@relationCamId int'', 
                          @cam_id, 
                          @inOut, 
                          @relationCamId;
             END;
             RETURN 0;
     END;
     ELSE
         BEGIN
             IF @inOut = 1
                 BEGIN
                     IF EXISTS
                     (
                         SELECT calif.calif_id
                         FROM ccTipoCalifOUT AS calif
                              JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
                              LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id
                                                                    AND rel.tipoSubRel = 0
                              LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
                         WHERE cam_id = @cam_id
                               AND tipo = @inOut
                     )
                         BEGIN
                             SET @sql = '';WITH disposition
AS (SELECT DISTINCT
       1 AS tag,NULL AS parent,calif.calif_id AS "selection!1!id",calif.Description AS "selection!1!string",calif.keepDial AS "selection!1!keepOnDial",
	   calif.orden AS "selection!1!califorden",ISNULL(calif.finishPreview,0) AS "selection!1!finishPreview",ISNULL(calif.finishRecordPreview,0) AS "selection!1!finishRecordPreview",NULL AS "subSelection!2!id",NULL AS "subSelection!2!string",NULL AS "subSelection!2!keepOnDial",
	   NULL AS "subSelection!2!orden",ISNULL(calif.CanReprogram,0) AS "selection!1!canReprogram",NULL AS "subSelection!2!canReprogram"
    FROM ccTipoCalifOUT AS calif
    INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
    LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 0
    LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
    WHERE cam_id = @cam_id AND tipo = @inOut
    UNION
    SELECT DISTINCT
       2 AS tag,1 AS parent,calif.calif_id AS "selection!1!id",NULL AS "selection!1!string",NULL AS "selection!1!keepOnDial",calif.orden AS "selection!1!califorden",ISNULL(calif.finishPreview,0) AS
       "selection!1!finishPreview", ISNULL(calif.finishRecordPreview,0) AS "selection!1!finishRecordPreview", sb.califsub_id AS "subSelection!2!id",sb.califSubDesc AS "subSelection!2!string", 
	   sb.keepDial AS "subSelection!2!keepOnDial",CAST(sb.orden AS INT) AS "subSelection!2!orden",NULL AS"selection!1!canReprogram",
	   ISNULL(sb.CanReprogram,0) AS "subSelection!2!canReprogram"
    FROM ccTipoCalifOUT AS calif
    INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
    LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 0
    LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
    WHERE cam_id = @cam_id AND tipo = @inOut AND sb.califsub_id IS NOT NULL)
'';
                             IF @isXml = 1
                                 BEGIN
                                     SET @sql = @sql + ''select * from disposition
               order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type'';
                             END;
                             ELSE
                                 BEGIN
                                     SET @sql = @sql + ''SELECT tag AS Tag,ISNULL(parent,0) AS Parent,"selection!1!id" AS Id,ISNULL("selection!1!string",'''''''') AS Description,
    ISNULL("selection!1!keepOnDial",'''''''') AS KeepOnDial,
    --"selection!1!califorden" AS Orden,
    CAST(  ROW_NUMBER() OVER(ORDER BY "selection!1!califorden" ASC, "selection!1!string" ASC) as int) AS Orden,
    "selection!1!finishPreview" AS
    FinishPreview,
	"selection!1!finishRecordPreview" AS
    FinishRecordPreview,
	ISNULL("subSelection!2!id",0) AS SubId,ISNULL("subSelection!2!string",'''''''') AS SubDescription
    ,ISNULL("subSelection!2!keepOnDial",0) AS SubKeepOnDial,
    ISNULL("subSelection!2!orden",0) AS SubOrden,    
    ISNULL("selection!1!canReprogram",0) AS CanReprogram,ISNULL("subSelection!2!canReprogram",0) AS SubCanReprogram
    FROM disposition'';
                             END;
                             -- PRINT @sql

                             EXEC sp_executesql 
                                  @sql, 
                                  N''@cam_id int, @InOut int'', 
                                  @cam_id, 
                                  @inOut;
                     END;
                     RETURN 0;
             END;
             ELSE
                 BEGIN
                     IF @inOut = 10
                         BEGIN
                             SELECT DISTINCT 
                                    S.califSub_id, S.califSubDesc, orden
                             FROM cctipoSubCalifRel AS R
                                  JOIN cctipoCalifSub AS S ON R.califSub_id = S.califSub_id
                             WHERE R.tipoSubRel = 1
                                   AND S.califSub_Status = 1
                                   AND R.calif_id = @cam_id
                                    ORDER BY S.orden, S.califSubDesc;
                             RETURN 0;
                     END;
                     ELSE
                         BEGIN
                             IF @inOut = 11
                                 BEGIN
                                     SELECT DISTINCT 
                                            S.califSub_id, S.califSubDesc, orden
                                     FROM cctipoSubCalifRel AS R
                                          JOIN cctipoCalifSubOut AS S ON R.califSub_id = S.califSub_id
                                     WHERE R.tipoSubRel = 0
                                           AND S.califSubOut_Status = 1
                                           AND R.calif_id = @cam_id
                                            ORDER BY S.orden, S.califSubDesc;
                                     RETURN 0;
                             END;
                     END;
             END;
     END;
     SET NOCOUNT OFF;';
	EXEC (@sql);

	-- END CW-8113 -----------------------------------------------------------------

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