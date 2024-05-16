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
SET @versionfix = 41
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
	
	SET @process = 'KR089000 DROP ccAgentMsgRelationFiles';
	SET @sql = 'if exists(select * from sys.tables where name=''ccAgentMsgRelationFiles'') begin
					DROP TABLE [dbo].[ccAgentMsgRelationFiles]
				end';
	EXEC (@sql);

	SET @process = 'KR089000 CREATE ccAgentMsgRelationFiles add column PK MsgType';
	SET @sql = 'if not exists(select * from sys.tables where name=''ccAgentMsgRelationFiles'') begin
					CREATE TABLE [dbo].[ccAgentMsgRelationFiles](
						[MsgId] [int] NOT NULL FOREIGN KEY REFERENCES ccAgentMsgFiles(MsgId),
						[CamId] [int] NOT NULL,
						[CamType] [tinyint] NOT NULL,
						[MsgType] [tinyint],
						primary key([MsgId],[CamId],[CamType],[MsgType])  
						)       
					end';
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
	ALTER TABLE ccAgentMsgFiles ADD messageType tinyint NOT NULL DEFAULT(0);
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

        delete from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType and MsgType = @messageType
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

	---------------------------------------Begin Jesus Gallardo hotfix/125.20230719.0.7-----------------------------------------------------------
	SET @process = 'CW-8077 Alter SP ccsp_InsertDNCList se agrega validacion para no insertar telefonos vacios select * from #mytempCall where [telefono]<>@phoneEmpty'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL
WITH RECOMPILE
AS


declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)
,@tel10 as varchar(30),@tel11 as varchar(30)

insert into cclistanegra(telefono,idtipolista,HashKey, calKey) values(@telephone, @ln_id,@hashCalKey, @calKey)

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall


CREATE TABLE [dbo].[#mycamps] (	[campsid] [int] NULL)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id and B.CampType not in(7,5)

CREATE TABLE [dbo].[#myprincipaltempCall](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltempCall]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltempCall]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltempCall]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltempCall]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltempCall]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltempCall]([cal_telefono5]) 

CREATE TABLE [dbo].[#mytempCall](
	[callout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempCall]([callout_id]) 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @tel = dbo.completa(@telephone, @pais, @ld)

set @tel10=RIGHT(@tel,10)
set @tel11=RIGHT(@tel,11)

declare @fech datetime = getdate()-30
if @hashCalKey is not null and @hashCalKey > 0
begin

	insert into [#myprincipaltempCall] 
	SELECT a.callout_id as callout_id, a.cam_id,3,@ln_id as idtipolista , a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
	FROM [ccoCallsOutSource] as a, #mycamps as b with(nolock) 
	WHERE a.cam_id = b.campsid 
	AND dbo.hashList(cal_Key) = @hashCalKey and  cal_fechadial > @fech  
end
else begin
	insert into [#myprincipaltempCall]
	SELECT a.callout_id as callout_id, a.cam_id,''3'',cast(@ln_id as nvarchar) as idtipolista , a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
	FROM [ccoCallsOutSource] as a, #mycamps as b with(nolock) 
	WHERE a.cam_id = b.campsid	
	and (@tel  IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) 
	or @tel10 IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) 
	or @tel11 IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5])) 
	and  cal_fechadial > @fech  
end


if EXISTS (select * from #myprincipaltempCall)
begin
	declare @column nvarchar(max), @sql nvarchar(max)
	,@sqlDeleteWorking nvarchar(max)
	,@sqlUpdateWorking nvarchar(max)
	,@sqlCaseWorking nvarchar(max)
	,@params nvarchar(max)
	,@phoneEmpty varchar(1)
	,@sqlWithReplace nvarchar(max)

	set @phoneEmpty=''''
	set @column=''cal_telefono''
	set @params=''@tel varchar(30),@tel10 varchar(30),@tel11 varchar(30),@phoneEmpty varchar(1),@fech datetime''
	set @sqlDeleteWorking=''and cs.cal_telefono2=@phoneEmpty
	and cs.cal_telefono3=@phoneEmpty
	and cs.cal_telefono4=@phoneEmpty
	and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono2<>@phoneEmpty then cs.cal_telefono2 
	when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
	when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
	when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
	else @phoneEmpty end ''

	set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
	update wt 
	set cal_telefono = CASE_UPDATE_WT
	from ccoCallsOutSource cs 
	inner join ccoWOrkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytempCall t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > @fech and cs.COLUMN_CHECK= wt.cal_telefono''

	set @sql=''insert #mytempCall
select callout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempCall] with(nolock)
where cal_telefono in(@tel,@tel10,@tel11)

if EXISTS (select * from #mytempCall)
begin		
	-- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
	delete wt with(rowlock)
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytempCall t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > @fech and
	cs.COLUMN_CHECK = wt.cal_telefono
	AND_DELETE_WT

	UPDATE_SMS_WT_QUERY

	--insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytempCall where [telefono]<>@phoneEmpty

	-- Eliminamos el telefono1 de CS
	update ccoCallsOutSource 
	set COLUMN_CHECK = @phoneEmpty
	from ccoCallsOutSource cs 
	inner join #mytempCall t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > @fech		

	truncate table #mytempCall
end''

	
	/******************/
	/*** Telefono 1 ***/
	/******************/
	
	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)	
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech	

	/******************/
	/*** Telefono 2 ***/
	/******************/
	set @column=''cal_telefono2''
	
	set @sqlDeleteWorking='' and cs.cal_telefono3=@phoneEmpty
		and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
		when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech

	/******************/
	/*** Telefono 3 ***/
	/******************/
	set @column=''cal_telefono3''
	
	set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech
	
	/******************/
	/*** Telefono 4 ***/
	/******************/	
	
	set @column=''cal_telefono4''
	
	set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech
	
	/******************/
	/*** Telefono 5 ***/
	/******************/

	set @column=''cal_telefono5''	
	set @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty''	
	set @sqlCaseWorking=''''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech

end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall'
	EXEC(@sql)

	SET @process = 'DEV1-436 Alter SP CofetelActions se valida @type = 2 que no este vacia para truncate table Series'
	SET @sql = 'ALTER PROCEDURE [dbo].[CofetelActions]
@type tinyint
as
if @type = 1
begin
	truncate table SeriesTmp
end
		
if @type = 2
begin
	if exists(select * from SeriesTmp) begin
		truncate table Series
	end
end
		
declare @ret bit
set @ret = 1
		
select @ret'
	EXEC(@sql)

	SET @process = 'DEV1-436 Alter SP CofetelUpdateData Valida que este vacia Series para insertar los registros @type = 1'
	SET @sql = 'ALTER PROCEDURE [dbo].[CofetelUpdateData]
@type tinyint
as
if @type = 1
begin
	if not exists(select * from Series) begin
		insert into Series
		select * from SeriesTmp
	end
end
		
declare @ret bit
set @ret = 1
		
select @ret'
	EXEC(@sql)
	
	---------------------------------------END Jesus Gallardo hotfix/125.20230719.0.7-----------------------------------------------------------
	---------------------------------------Begin Ivan Martin hotfix/125.20230719.0.7-----------------------------------------------------------
	SET @process = 'Se quita procedure ccspOutboundSmsMessage'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspOutboundSmsMessage'')
				BEGIN
				    DROP PROCEDURE ccspOutboundSmsMessage;
				END'
	EXEC(@sql)

	SET @process = 'Se agrega action 9 para revertir el status de mensajes que no se procesaron bien'
	SET @sql = 'CREATE procedure [dbo].[ccspOutboundSmsMessage] 
@action int,
@camId int = null,
@SentMsg int=null,
@smsoutIds varchar(max)=null,
@SystemApiId varchar(100)=null,
@statusSystemsId int =null,
@InsufficientBalance int=null,
@date datetime =null
as
declare @sql varchar(max)
if @action=1 begin
	select cast(cam_id as int) as CamId,cam_descripcion as [Name],cam_procesando as [Start] 
	from ccCamps where CampType=7 and IDArea is not null and( @camId is null or cam_id=@camId)
end
else if @action=2 begin
	select tz_offset from ccTimeZones ORDER BY tz_id
end
else if @action=3 begin
	select cast(camId as int) CamId,SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected 
	from ccSmsConversationsResult where ( @camId is null or camId=@camId)
end
else if @action=4 begin
	truncate table ccSmsConversationsResult
end
else if @action=5 begin
	if not exists(select * from ccSmsConversationsResult where camId=@camId) begin
		insert into ccSmsConversationsResult(camId,SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,InsufficientBalance)
		values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance)
	end
	else begin
		update ccSmsConversationsResult set SentMsg=SentMsg+@SentMsg 
		,InsufficientBalance=InsufficientBalance+@InsufficientBalance
		where camId=@camId
	end
end
else if @action=6 begin	
	set @sql=''declare @listCamId table(camId int,status bit)

declare @camId int
insert into @listCamId
select distinct cam_id,0 from smsWorkingTable with(nolock) where smsout_id in(''+@smsoutIds+'')

while exists(select * from @listCamId where status=0)begin
	select top 1 @camId=CamId from @listCamId where status=0
	
	exec ccsp_GalateaGetCampsNvosCB @cam_id=@camId,@Tipo=2,@regval=1
	update @listCamId set status=1 where status=0 and @camId=CamId 
end
delete from smsWorkingTable where smsout_id in(''+@smsoutIds+'')
	''
	exec (@sql)
end
else if @action=7 begin
	declare @statusSystemsIdOld int
	declare @ccSmsConversationsResult table(camId int,statusSystemsId int,description varchar(255), value int)
	select top(1) @camId =cam_id,@statusSystemsIdOld=statusSystemsId from smsccoLogDial with(nolock) where SystemApiId=@SystemApiId
	update smsccoLogDial set statusSystemsId=@statusSystemsId where SystemApiId=@SystemApiId
	
	insert into @ccSmsConversationsResult
	select camId, ROW_NUMBER() OVER(ORDER BY camId ASC)-1 AS statusSystemsId, description,value
	from ccSmsConversationsResult
	unpivot
	(
		value
		for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,InsufficientBalance)
	) unpiv
	where camId= @camId

	update @ccSmsConversationsResult set value =case when value>0 then value-1 else 0 end where statusSystemsId=@statusSystemsIdOld
	update @ccSmsConversationsResult set value =value+1 where statusSystemsId=@statusSystemsId
	
	;with res as(
	select * from 
	(
		select camId, description, value
		from @ccSmsConversationsResult 
	) src
	pivot
	(
	sum(value)
	for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,InsufficientBalance)
	) piv
	)

	update B 
	set B.SentMsg=A.SentMsg
	,B.Delivered=A.Delivered
	,B.NotDelivered=A.NotDelivered
	,B.RecipientRejected=A.RecipientRejected
	,B.CarrierRejected=A.CarrierRejected
	,B.InsufficientBalance=A.InsufficientBalance
	from
	res A
	inner join ccSmsConversationsResult B on A.camId=B.camId
end
else if @action=8 begin
	update smsccoLogDial set Bill=0.70 where smsDate>=@date and statusSystemsId not in(4,5)
end
else if @action=9 begin
	CREATE TABLE #TempSmsOutIds (
    smsout_id INT
	);

	INSERT INTO #TempSmsOutIds (smsout_id)
	SELECT DISTINCT wt.smsout_id
	FROM smsWorkingTable wt
	JOIN smsOutSource os ON wt.smsout_id = os.smsout_id
	LEFT JOIN smsccoLogDial cco ON wt.smsout_id = cco.smsout_id
	WHERE wt.sms_status IN(1,2) 
	AND cco.smsout_id IS NULL;

	UPDATE wt
	SET wt.sms_status = 0
	FROM smsWorkingTable wt
	JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

	DROP TABLE #TempSmsOutIds;
end'
	EXEC(@sql)
	---------------------------------------End Ivan Martin hotfix/125.20230719.0.7-----------------------------------------------------------



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