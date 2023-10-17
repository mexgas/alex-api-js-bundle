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
        if not exists(select MsgId from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType)
        begin
                select ''-1'' as result
                return(0)
        end
			else begin
				select @idCampUnassign =CamId from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType
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

	

	SET @process = 'KR089000 ';
	SET @sql = '';
	EXEC (@sql);

	SET @process = 'KR089000 ';
	SET @sql = '';
	EXEC (@sql);

	SET @process = 'KR089000 ';
	SET @sql = '';
	EXEC (@sql);

	SET @process = 'KR089000 ';
	SET @sql = '';
	EXEC (@sql);

	SET @process = 'KR089000 ';
	SET @sql = '';
	EXEC (@sql);

	SET @process = 'KR089000 ';
	SET @sql = '';
	EXEC (@sql);

	SET @process = 'KR089000 ';
	SET @sql = '';
	EXEC (@sql);

	SET @process = 'KR089000 ';
	SET @sql = '';
	EXEC (@sql);

	-----------------------------------------------------END KR089000 Notificación recepción y finalización de llamada -----------------------------------------------------------------

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