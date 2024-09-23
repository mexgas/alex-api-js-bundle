/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: David Medina Medina
Date: 2024/09/19
Description: Release 126.20240919.0.0
Database: CCenterRia
Required version: 126.6
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 20
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
    	
		------------------------------------------------- Empeiza David Medina ----------------------------------------------------------------------------------
		------------------------------------------------------- Tablas ------------------------------------------------------------------------------------------
		SET @process = 'k002092 | k002093 Se añade columna AssignConversationSameAgent para saber si la conversación se reasignará al mismo agente'
		SET @sql = '
			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''AssignConversationSameAgent'' AND Object_ID = Object_ID(N''dbo.ccinbound''))
			BEGIN
				ALTER TABLE ccinbound ADD AssignConversationSameAgent BIT DEFAULT 0 WITH VALUES;
			END'
		EXEC(@sql)

		SET @process = 'K002090 Se añade columna ConversationHistoryTime para saber cantidad de días máximos a buscar por conversaciones de WA en histórico '
		SET @sql = '
			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''ConversationHistoryTime'' AND Object_ID = Object_ID(N''dbo.ccinbound''))
			BEGIN
				ALTER TABLE ccinbound ADD ConversationHistoryTime SMALLINT DEFAULT 5 WITH VALUES;
			END'
		EXEC(@sql)

		SET @process = 'K020001 Se añade columna MaximumLimitConversationsInQueue para máximo de conversaciones en cola'
		SET @sql = '
			IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''MaximumLimitConversationsInQueue'' AND Object_ID = Object_ID(N''dbo.ccinbound''))
			BEGIN
				ALTER TABLE ccinbound ADD MaximumLimitConversationsInQueue SMALLINT DEFAULT 99 WITH VALUES;
			END'
		EXEC(@sql)

		SET @process = 'k002092 | k002093 Se insertan identificadores de relación en tabla relationTableColumnIdentifiers para AssignConversationSameAgent'
		SET @sql = '
			IF NOT EXISTS (SELECT 1 FROM relationTableColumnIdentifiers WHERE colunName = ''AssignConversationSameAgent'' AND tableName = ''ccInbound'')
			BEGIN
				INSERT INTO relationTableColumnIdentifiers(identifiers, tableName, colunName)
				VALUES (''IN_WHATS_ASSIGN_SAME_AGENT'', ''ccinbound'', ''AssignConversationSameAgent'');
			END'
		EXEC(@sql)

		SET @process = 'K002090 Se insertan identificadores de relación en tabla relationTableColumnIdentifiers para ConversationHistoryTime'
		SET @sql = '
			IF NOT EXISTS (SELECT 1 FROM relationTableColumnIdentifiers WHERE colunName = ''ConversationHistoryTime'' AND tableName = ''ccInbound'')
			BEGIN
				INSERT INTO relationTableColumnIdentifiers(identifiers, tableName, colunName)
				VALUES (''IN_CONVERSATION_HISTORY_TIME'', ''ccinbound'', ''ConversationHistoryTime'');
			END'
		EXEC(@sql)

		SET @process = 'K020001 Se insertan identificadores de relación en tabla relationTableColumnIdentifiers para MaximumLimitConversationsInQueue'
		SET @sql = '
			IF NOT EXISTS (SELECT 1 FROM relationTableColumnIdentifiers WHERE colunName = ''MaximumLimitConversationsInQueue'' AND tableName = ''ccInbound'')
			BEGIN
				INSERT INTO relationTableColumnIdentifiers(identifiers, tableName, colunName)
				VALUES (''MAXIMUM_LIMIT_CONVERSATIONS_IN_QUEUE'', ''ccinbound'', ''MaximumLimitConversationsInQueue'');
			END'
		EXEC(@sql)

		SET @process = 'k002092 | k002093 Se insertan identificadores de relación en tabla ccGalateaIdentifiers para AssignConversationSameAgent'
		SET @sql = '
			IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''IN_WHATS_ASSIGN_SAME_AGENT'')
			BEGIN
				insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) values (''IN_WHATS_ASSIGN_SAME_AGENT'', ''Asignar contacto al último agente que le atendió'', 
				''Assign contact to the last agent who assisted them'', ''Atribuir contato ao último agente que o atendeu'') 
			END'
		EXEC(@sql)

		SET @process = 'K002090 Se insertan identificadores de relación en tabla ccGalateaIdentifiers para ConversationHistoryTime'
		SET @sql = '
			IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''IN_CONVERSATION_HISTORY_TIME'')
			BEGIN
				insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) values (''IN_CONVERSATION_HISTORY_TIME'', ''Tiempo de historial de conversaciones (días)'', 
				''Conversations log period (days)'', ''Tempo de histórico de conversas (dias)'') 
			END'
		EXEC(@sql)

		SET @process = 'K020001 Se insertan identificadores de relación en tabla ccGalateaIdentifiers para MaximumLimitConversationsInQueue'
		SET @sql = '
			IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''MAXIMUM_LIMIT_CONVERSATIONS_IN_QUEUE'')
			BEGIN
				insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) values (''MAXIMUM_LIMIT_CONVERSATIONS_IN_QUEUE'', ''Número máximo en espera'', 
				''Maximum conversations in queue'', ''Número máximo na fila'') 
			END'
		EXEC(@sql)
		--------------------------------------------------------- SPs -------------------------------------------------------------------------------------------
		SET @process = 'Se elimina SP ccsp_GalateaGetInboundConfiguration'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetInboundConfiguration'')
					begin
						DROP PROCEDURE ccsp_GalateaGetInboundConfiguration;
					end'
		EXEC(@sql)

		SET @process = ' HUs -> k002090 | K002092 | K020001 | K020004 | K020005 
					     Se modifica SP ccsp_GalateaGetInboundConfiguration en el @command=2 para que el AdminWS muestre a
						 la UI AssignConversationSameAgent, ConversationHistoryTime y MaxLimitQueueConversations'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
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
				select @numbers=COALESCE(@numbers + '','', '''') + number from ccWhatsAppNumbers where inboundId is null or inboundId = 0 and status = 1
				select @numbers=COALESCE(@numbers + '','', '''') + number from ccMetaWhatsAppNumbers where Inbound_Id is null or Inbound_Id = 0 and status = 1

				select i.Inbound_id [InboundId], i.descripcion [Description], i.chat [MediaType], i.Status, isnull(g.graphic_id,1) [Frame],
				ISNULL(c.conexionInfo,'''') [Number],
				ISNULL(@numbers,'''') [FreeNumbersStr],
				CAST(ISNULL(c.closeConversationTime, 0) AS INT) [MaxAnswerTime],
				ISNULL(c.answerTimeoutClient, 30) [MUTimeOutClient],
				ISNULL(c.allowFileAttachments, 0) [AllowFileAttachments],
				i.tNotas [tNotas],
				i.ExitWrapUpDisposition,
				i.ShowCalifWnd,
				i.AssignConversationSameAgent,
				i.ConversationHistoryTime,
				i.MaximumLimitConversationsInQueue as MaxLimitQueueConversations
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
			END'
		EXEC (@sql)

		SET @process = 'Se elimina SP ccsp_GalateaUpdateWhatsAppConfiguration'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUpdateWhatsAppConfiguration'')
					begin
						DROP PROCEDURE ccsp_GalateaUpdateWhatsAppConfiguration;
					end'
		EXEC(@sql)

		SET @process = ' HUs -> k002090 | K002092 | K020001 | K020004 | K020005 
						 Se modifica SP ccsp_GalateaUpdateWhatsAppConfiguration agregandole @ConversationHistoryTime, @MaximumLimitConversationsInQueue y @assignConversationSameAgent,
						 para agrega valores y actualizarlos en tabla ccinbound y log de actividad para IN_WHATS_ASSIGN_SAME_AGENT'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaUpdateWhatsAppConfiguration]
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
				@module			int = -1,
				@ConversationHistoryTime SMALLINT = null,
				@MaximumLimitConversationsInQueue SMALLINT = null,
				@assignConversationSameAgent bit = null


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
					ExitWrapUpDisposition = ISNULL(@exitWrapUpDisposition, ExitWrapUpDisposition),
					AssignConversationSameAgent = ISNULL(@assignConversationSameAgent, AssignConversationSameAgent),
					ConversationHistoryTime = ISNULL(@ConversationHistoryTime, ConversationHistoryTime),
					MaximumLimitConversationsInQueue = ISNULL(@MaximumLimitConversationsInQueue, MaximumLimitConversationsInQueue)
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
							WHEN CCIT.identifierInfo = ''IN_WHATS_ASSIGN_SAME_AGENT'' THEN
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
		          
					set @number = case when  @number is null or @number in(''0'', ''Ninguno'') then ''Ninguno'' else @number end

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
				END'
		EXEC (@sql)

		SET @process = 'Se elimina SP ccsp_Multimedia2'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_Multimedia2'')
					begin
						DROP PROCEDURE ccsp_Multimedia2;
					end'
		EXEC(@sql)

		SET @process = ' HU -> k002093 
						 Se modifica SP ccsp_Multimedia2 en el @action = 1 para que guarde AssignSameAgent ene l diccionario del distributor para saber si se debe o no
						 asignar conversación de entrada a último agente que atendió esa conversación'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_Multimedia2] @action INT, @inboundId INT = NULL, @userId INT = NULL
			, @senderId INT = NULL,@camType bit=0
			,@multimediaType int =null
			AS
			BEGIN
				SET NOCOUNT ON;

				IF @action = 1
				BEGIN --Lista Cam Or  ACD
					if @camType=0 begin		
						SELECT DISTINCT A.inbound_id AS Id, A.chat AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets, 
						cast(isnull(C.maxWhats, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId, ISNULL(A.AssignConversationSameAgent, 0) AS AssignSameAgent
						FROM ccInbound A
						INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
						WHERE (@inboundId IS NULL OR @inboundId = A.Inbound_id)
						and (@multimediaType is null or @multimediaType =-1 or A.chat=@multimediaType)
					end
					else begin
						SELECT DISTINCT A.cam_id AS Id,convert(tinyint, case when A.CampType =5  then A.CampType else 1 end) AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets,
						cast(isnull(C.maxWhatsOut, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId, ISNULL(CE.AssignConversationSameAgent, 0) AS AssignSameAgent
						FROM ccCamps A
						INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
						LEFT JOIN ccCampsExtend CE ON CE.cam_id = A.cam_id
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
			END'
		EXEC (@sql)

		SET @process = 'Se elimina SP ccsp_UpdateACDWhatsappConfig'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_UpdateACDWhatsappConfig'')
					begin
						DROP PROCEDURE ccsp_UpdateACDWhatsappConfig;
					end'
		EXEC(@sql)

		SET @process = ' HUs -> k002090 | K002092 | K020001 | K020004 | K020005
						 Se modifica SP ccsp_UpdateACDWhatsappConfig agregandole @ConversationHistoryTime, @MaximumLimitConversationsInQueue y @assignConversationSameAgent,  
						 para agregar valores y actualizarlos en tabla ccinbound y log de actividad para IN_WHATS_ASSIGN_SAME_AGENT'
		SET @sql = '
		CREATE PROCEDURE  [dbo].[ccsp_UpdateACDWhatsappConfig]
			    @ConexionInfo varchar(400),
			    @inbound_id int,
			    @ConnUser varchar(60),
			    @tNotas int,
			    @closeConversationTime tinyint,
			    @ShowCalifWnd bit,
			    @ExitWrapUpDisposition bit,
			    @MUTimeOutClient int,
			    @allowFileAttachments bit,
			    @userId SMALLINT, 
			    @idArea SMALLINT, 
			    @isCreating BIT,
				@ConversationHistoryTime SMALLINT = 5,
				@MaximumLimitConversationsInQueue SMALLINT = 99,
				@AssignConversationSameAgent BIT = 0

			    AS
			    set nocount on
			    IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
			    BEGIN

			        UPDATE contactMeanIn SET ConnPass = ''N/A'', numMessages = 3, timeAlertMessage = 5, answerTimeOut = 10 where inboundId = @inbound_id;

			        EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanIn'', @columnNameId=''inboundId'', @valueId= @inbound_id, @userId= @userid

			        IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

			        Create table #contactMeanInTable 
			        (
			            columnInfo VARCHAR(255),
			            dataInfo VARCHAR(255),
			            identifierInfo VARCHAR(255)
			        )

			        UPDATE contactMeanIn SET conexionInfo = @conexionInfo, connUser = @connUser, closeConversationTime = CAST(@closeConversationTime AS INT), answerTimeoutClient = @MUTimeOutClient, allowFileAttachments = @allowFileAttachments        
			        where inboundId = @inbound_id;

			        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inbound_id, @userId = @userid, @tableTemp=''#contactMeanInTable'';

			        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			        SELECT 
			            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
			            getDate(), 
			            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
			            CASE WHEN @isCreating = 1 THEN 40 ELSE 53 END, 
			            3, 
			            CMIT.identifierInfo,
			            CASE WHEN CMIT.identifierInfo IS NOT NULL AND CMIT.identifierInfo <> '''' THEN
			                CASE
			                    WHEN CMIT.identifierInfo IN (''IN_ATTACH_FILES_WHATS'') THEN
			                        CASE WHEN CMIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
			                    ELSE CMIT.dataInfo END
			            ELSE '''' END, 
			            (SELECT [name] FROM contactMeanIn WHERE inboundId = @inbound_id)
			        FROM #contactMeanInTable AS CMIT;

			        EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inbound_id, @userId = @userid;

			        IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

			        UPDATE ccWhatsAppNumbers SET inboundId = @inbound_id WHERE number = @conexionInfo
					UPDATE ccMetaWhatsAppNumbers SET Inbound_Id = @inbound_id WHERE number = @conexionInfo


			    END;

			    IF EXISTS (SELECT Inbound_id FROM ccInbound WHERE Inbound_id = @inbound_id) 
			    BEGIN
			    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inbound_id, @userId= @userid

			        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

			        Create table #ccInboundTable 
			        (
			            columnInfo VARCHAR(255),
			            dataInfo VARCHAR(255),
			            identifierInfo VARCHAR(255)
			        )

			        UPDATE ccInbound SET tNotas = @tNotas, ShowCalifWnd = @ShowCalifWnd, ExitWrapUpDisposition = @ExitWrapUpDisposition, AssignConversationSameAgent = @AssignConversationSameAgent,
					ConversationHistoryTime = @ConversationHistoryTime , MaximumLimitConversationsInQueue = @MaximumLimitConversationsInQueue where Inbound_id = @inbound_id;

			        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';

			        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			        SELECT 
			            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
			            getDate(), 
			            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
			            40, 
			            3, 
			            CASE 
			                WHEN CCIT.identifierInfo = ''IN_WRAP_UP_TIME'' THEN ''IN_WRAP_UP_TIME_WHATS''
			                WHEN CCIT.identifierInfo = ''IN_SHOW_DISPOSITIONS'' THEN ''IN_SHOW_DISPOSITIONS_WHATS'' 
			                ELSE  CCIT.identifierInfo 
			            END,
			            CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
			                CASE
			                    WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_WRAP_UP_TIME'', ''IN_WRAP_ON_DIPOSITION_WHATS'') THEN 
			                        CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
								WHEN CCIT.identifierInfo = ''IN_WHATS_ASSIGN_SAME_AGENT'' THEN
			                        CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
			                    ELSE CCIT.dataInfo END
			            ELSE '''' END, 
			            (SELECT [name] FROM contactMeanIn WHERE inboundId = @inbound_id)
			        FROM #ccInboundTable AS CCIT;

			        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid;

			        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
			    END;
			    SELECT @inbound_id;
			    return(@inbound_id)

			    set nocount off'
		EXEC (@sql)

		SET @process = 'Se elimina SP ccsp_WAGetPreviousAgentToReassign'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_WAGetPreviousAgentToReassign'')
					begin
						DROP PROCEDURE ccsp_WAGetPreviousAgentToReassign;
					end'
		EXEC(@sql)

		SET @process = 'HUs -> k002093
						Se modifica SP ccsp_WAGetPreviousAgentToReassign para conseguir último agente al que se le asignó conversación 
						con el mismo num de cliente en camapaña de entrada'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_WAGetPreviousAgentToReassign]  
			 @Action int, @CamId int, @ClientId VARCHAR(20) 
			 AS
			 BEGIN
			 SET NOCOUNT ON;

				DECLARE @InitialTime DATETIME;
				DECLARE @PreviousAgentID int = 0;

				IF @Action = 1
				BEGIN
		
					SET @InitialTime = DATEADD(HH, -24, GETDATE());

					IF EXISTS(SELECT TOP 1 PhoneClient FROM ccoWhatsLogDials 
						WHERE CamId = @CamId and PhoneClient = @ClientId
						AND TimeSpam >= @InitialTime AND ASSIGNED = 0)
					BEGIN
						SELECT TOP 1 @PreviousAgentID = agentId	FROM
						(
							SELECT agentId, conversationDate
							FROM ccWhatsAppConversationsOut
							WHERE clientId = @clientid
							AND agentId > 0

							UNION ALL

							SELECT agentId, conversationDate
							FROM ccWhatsAppConversations
							WHERE clientId = @clientid
							AND agentId > 0
						) AS CombinedConversations
						ORDER BY conversationDate DESC;

						UPDATE ccoWhatsLogDials SET ASSIGNED = 1 
						WHERE CamId = @CamId and PhoneClient = @ClientId
						AND TimeSpam >= @InitialTime AND ASSIGNED = 0
					END

					IF @PreviousAgentID IS NULL
					BEGIN
						SELECT @PreviousAgentID = 0;
					END
		 
					SELECT @PreviousAgentID AS previousAgentID;
				END

				IF @Action = 2
				BEGIN

					IF EXISTS(SELECT 1 FROM ccWhatsAppConversations WHERE inboundId = @CamId AND clientId = @ClientId)
					BEGIN

						SELECT TOP 1 @PreviousAgentID = agentId 
						FROM ccWhatsAppConversations 
						WHERE inboundId = @CamId AND clientId = @ClientId
						ORDER BY conversationDate DESC;
					END
		
					IF @PreviousAgentID IS NULL
					BEGIN
						SELECT @PreviousAgentID = 0;
					END

					SELECT @PreviousAgentID AS previousAgentID;
				END
			 END'
		EXEC (@sql)
		------------------------------------------------- Termina David Medina ----------------------------------------------------------------------------------

        ------------------------------------------------- Empieza Leonardo Ramírez ------------------------------------------------------------------------------
		--------------------------------- K020106 - Resultados de envío mensajes de WhatsApp de salida  ---------------------------------------------------------

        SET @process = ' Modificacion del sp ConversationWASaveOut en la action 16 para la obtención de resultados de mensajes de salida en campañas de whatsapp'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASaveOut] @action             INT
, @conversationId     INT         = 0
, @camId          SMALLINT    = NULL
, @phoneCam           VARCHAR(50) = NULL
, @clientId           VARCHAR(25) = NULL
, @conversationStatus SMALLINT    = 0
, @tChatting          FLOAT    = 0
, @tWrapUp            SMALLINT    = 0
, @finishedBy         TINYINT     = 0
, @onQueue            BIT         = NULL
, @tQueue             SMALLINT    = 0
, @tTimeout           INT         = 0
, @disposition        SMALLINT    = 0
, @subDisposition     SMALLINT    = 0
, @agentId            INT         = 0
--VAR MESSAGES
, @messageId          VARCHAR(150) = NULL
, @messageIdUi        INT         = NULL
, @clientNum          VARCHAR(15) = NULL
, @vonageNum          VARCHAR(15) = NULL
, @typeMessage        VARCHAR(25) = ''''
, @content            NVARCHAR(MAX)= NULL
, @timeStampMessage   DATETIME    = NULL
, @timeStampMessageUTC DATETIME   = NULL
, @originType         VARCHAR(15) = NULL
, @currency           VARCHAR(10) = ''-''
, @price              VARCHAR(10) = ''0.00''
, @messageStatus      VARCHAR(15) = ''N/A''
, @listConversationsIds   VARCHAR(MAX) = NULL
, @IsAgentLoggingOut  BIT = 0
, @ConvId             INT = NULL OUTPUT
AS
BEGIN
    DECLARE @isEndConversation BIT;
    DECLARE @meanContactTypeId SMALLINT;
    DECLARE @conversationIdNew INT;
    SET @meanContactTypeId = 1;
    SET NOCOUNT ON;

IF @action = 1
BEGIN --new Conversation
    IF NOT EXISTS (SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A with(nolock)
    WHERE A.conversationId = @conversationId)
    BEGIN
        INSERT INTO [ccWhatsAppConversationsOut]
        (camId, phoneCamp , clientId, conversationStatus, tChatting , tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId)
        VALUES(@camId, @phoneCam, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
        
        
        SELECT @conversationId = SCOPE_IDENTITY();
SELECT @ConvId = @conversationId;
        SELECT @conversationId AS ConversationId;

--        Save new request
        IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId) BEGIN
        INSERT INTO ccWAOperatingSummaryOut (camId, Request) VALUES (@camId, 1);
        END
        ELSE BEGIN
            UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1) WHERE camId = @camId
        END
        RETURN(0);
    END
    ELSE BEGIN
        DECLARE @conversationStatusTemp INT = @conversationStatus;
        IF @conversationStatus in(17,18) BEGIN
            SET @conversationStatusTemp = 1
        END 

        DECLARE @RequestDate DATETIME = NULL;
        SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversationsOut WITH(NOLOCK) WHERE conversationId = @conversationId;

        INSERT INTO [ccWhatsAppConversationsOut]
            (camId, phoneCamp, clientId, conversationStatus, tChatting, tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId, requestDate)
        VALUES(@camId, @phoneCam, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, 
            @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
        SELECT @conversationIdNew = SCOPE_IDENTITY();

        INSERT INTO ccWhatsAppConversationsRelationshipOut (conversationIdBefore, conversationIdAfter)
        VALUES (@conversationId, @conversationIdNew);
        --Save new request by reassign
        UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1), Assigned = (Assigned - 1),EndedBySystem=EndedBySystem+1
        WHERE camId = @camId

    EXEC ccsp_ConversationWASaveOut @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

    SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationshipOut where conversationIdBefore = @conversationId;
SELECT @ConvId = conversationIdAfter FROM ccWhatsAppConversationsRelationshipOut WHERE conversationIdBefore = @conversationId;
    RETURN(0);
END;
END;

else IF @action = 2
BEGIN --save conversation Times
    DECLARE @conversationIdTemp INT;
    DECLARE @TablaTemp TABLE (conversationId INT, status bit);

    IF @listConversationsIds IS NOT NULL begin
        INSERT INTO @TablaTemp
        SELECT value,0
        FROM fn_RIASplitDelimited(@listConversationsIds, '','')
        where value is not null and value<>''''
    end
    else begin
        INSERT INTO @TablaTemp values(@conversationId,0)
    end
    
    UPDATE ccWhatsAppConversationsOut
    SET
    conversationStatus = @conversationStatus
    , finishedBy = case when @conversationStatus in(4,10,17,18) then 2
    when @conversationStatus in(11) then 1
        else 0 end
    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

    WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
    BEGIN
        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=6

        IF @conversationStatus in(4,10,11,13,17,18) BEGIN
            DECLARE @conversationDateTemp INT;
            select @camId = CamId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
            from ccWhatsAppConversationsOut where conversationId = @conversationId;

            IF @conversationStatus = 13 BEGIN
                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam with(nolock) where NumberClient = @clientId) BEGIN
                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@camId, @agentId, @conversationId, @clientId);
                END
            END
            ELSE IF @conversationStatus in(4,10,17,18) BEGIN --Save conversation Ended by system
                IF @conversationDateTemp > 0 BEGIN
                    UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
                END
                ELSE BEGIN
                        UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1) WHERE CamId = @camId
                END
            END
            ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
                UPDATE ccWAOperatingSummaryOut SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
            END
        END
        update @TablaTemp set status=1 where conversationId=@conversationIdTemp
    END

END;

else IF @action = 3
BEGIN --save conversation Status
    UPDATE ccWhatsAppConversationsOut SET conversationStatus = @conversationStatus WHERE conversationId = @conversationId;
END;

else IF @action = 4 BEGIN --save messages from conversation
    IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId)
        AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversationsOut A with(nolock) WHERE A.messageId=@messageId)
    BEGIN
        IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
            (SELECT messageIdUi
                FROM ccWAMessagesConversationsOut
                WHERE originType IN (''Agent'', ''Admin'')
                AND conversationId = @conversationId)
            BEGIN
                UPDATE ccWhatsAppConversationsOut
                    SET FirstMessageAgent = @timeStampMessage
                    WHERE conversationId = @conversationId;
            END

        INSERT INTO [ccWAMessagesConversationsOut](
                                            messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
                                            (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
        SELECT @messageId=SCOPE_IDENTITY()
    
    SELECT @camId=camId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId
        if not exists(select * from ccWAConversationsResult where camId=@camId)begin
            insert into ccWAConversationsResult values(@camId,0,0,0,0,0)
        end
        exec ccsp_ConversationWASaveOut @action=16,@camId=@camId,@messageStatus=@messageStatus,@conversationId=@conversationId,@originType=@originType
        
        SELECT @messageId as MessageId
        
        RETURN (0)
    END
    ELSE BEGIN
        SELECT 0 AS MessageId
        RETURN (0)
    END
END;

else IF @action = 5
BEGIN --save onQueue
    UPDATE ccWhatsAppConversationsOut
            SET onQueue = 1,
            conversationStatus = @conversationStatus
    WHERE conversationId = @conversationId;
    SELECT @camId = camId FROM ccWhatsAppConversationsOut where conversationId=@conversationId;
    UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue + 1) WHERE camId = @camId
END;

else IF @action = 6
BEGIN --save agent, assigdate and tqueue
    declare @agentIdTmp int
    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversationsOut A with(nolock) where A.conversationId = @conversationId
    
        UPDATE ccWhatsAppConversationsOut
                SET agentId = @agentId,
                assignDate = getdate(),
                conversationStatus = @conversationStatus
                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
        WHERE conversationId = @conversationId;

    SELECT @conversationId as conversationId
    SELECT @camId = camId,  @onQueue = onQueue FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;

    IF @onQueue = 1 BEGIN
    UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue - 1) WHERE camId = @camId   
    END
END;

Else IF @action = 7
BEGIN --update price message
    UPDATE ccWAMessagesConversationsOut SET price = @price, currency = @currency WHERE messageId = @messageId;
END;
else IF @action = 8
BEGIN --update status message
    IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A with(nolock) 
        WHERE A.messageId=@messageId) <> ''read'' 
    BEGIN
        UPDATE ccWAMessagesConversationsOut
                SET messageStatus = @messageStatus
        WHERE messageId = @messageId;
        exec ccsp_ConversationWASaveOut @action=16,@camId=@camId,@messageStatus=@messageStatus,@conversationId=@conversationId,@originType=@originType
        
    END;
END;

else IF @action = 9
BEGIN --Save last message time by conversationID
    IF (SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversationOut A with(nolock) 
        WHERE A.conversationId=@conversationId) IS NULL BEGIN
        INSERT INTO ccLastMessageAgentByConversationOut (conversationId) VALUES (@conversationId)
    END;
    ELSE
        BEGIN
            UPDATE ccLastMessageAgentByConversationOut
                SET timeStampLastMessageAgent = getDate()
            WHERE conversationId = @conversationId;
        END;
END;

else IF @action = 10
BEGIN --drop and insert register by conversationID
    DELETE FROM ccLastMessageAgentByConversationOut WHERE conversationId = @conversationId;
END;

Else IF @action = 11
BEGIN --register desconnection agent by conversationID
    exec ccsp_ConversationWASaveOut @action = 9, @conversationId=@conversationId
END;

else IF @action = 12  BEGIN --Obtain conversationsWA post MCS reset
    declare @disconnectionIdTemp int = (select top 1 disconnectionId from [ccDisconnectionMCSOut] with(nolock) 
    where timeStampConnection is null order by timeStampDisconnection desc);
    UPDATE ccDisconnectionMCSOut SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

    declare @from as datetime;
    select @from = convert(datetime,convert(varchar(11),getdate()))
    set @from=DATEADD(dd,-1,@from);
        select A.conversationId, A.camId as inboundId, A.phoneCamp as phoneACD
        , A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, isnull(A.onQueue,0) onQueue, A.agentId, 
        isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, 
        isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
        ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
        from ccWhatsAppConversationsOut A with(nolock) 
        left join ccWAMessagesConversationsOut B with(nolock) on A.conversationId = B.conversationId
        left join [ccDisconnectionMCSOut] C with(nolock) on C.disconnectionId = @disconnectionIdTemp        
        where A.requestDate >= @from 
and A.conversationStatus not in (4, 10, 11, 13, 17, 18, 19, 20)
and A.finishedBy=0
        order by agentId desc, requestDate,timeStampMessage, camId, clientId 
END;
else IF @action = 13
BEGIN ---Obtain agents ON STATUS READY
    WITH agents
    AS(
        SELECT c.User_id, c.fecha, c.currentStatus
        FROM ccLogAgentesDia c
        INNER JOIN 
        (
            SELECT User_id, MAX(fecha) max_time
            FROM ccLogAgentesDia with(nolock)
            where fecha>=CONVERT(date,getdate(),121)
            GROUP BY User_id
        ) AS t
        ON c.fecha = t.max_time
        AND c.User_id=t.User_id AND currentStatus in (3,34)
    ), usersByCampigns
    AS (
        select IdCampEsp, User_id from ccRIACampEspWG A
        Inner join ccRIAWorkGroupUsers B
        on A.IDWG = B.IDWG
        Inner join contactMeanOut C
        ON A.idCampEsp = C.camp_id
        where A.IDWG = 1 and A.Tipo = 1
        AND C.meanContactTypeId = 5
    )

    select DISTINCT A.User_Id from agents A
    left join usersByCampigns B on A.User_Id = B.User_Id
END;

else IF @action = 14
BEGIN --register desconnection MCS
    INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
END;
ELSE IF @action = 15
    BEGIN --update content message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversationsOut
                    SET content = @content
            WHERE messageId = @messageId;
        END;
    END;
ELSE IF @action = 16 BEGIN --update content message

        if @camId is null or @camId=0 begin 
        SELECT @camId=camId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId
        end
                
        if @messageStatus=''submitted'' begin
            update ccWAConversationsResult set SentMsg= SentMsg+1
        end
        else if @messageStatus=''delivered'' begin
            update ccWAConversationsResult set SentMsg= SentMsg-1,Delivered=Delivered+1
        end
        else if @messageStatus=''read'' begin
            update ccWAConversationsResult set Delivered=Delivered-1,ReadMsg=ReadMsg+1
        end
        else if @messageStatus=''rejected'' or @messageStatus=''error'' begin
            update ccWAConversationsResult set SentMsg= SentMsg-1,NotDelivered=NotDelivered+1
        end
        else if (@messageStatus=''N/A'' and @originType!=''Agent'') begin
            update ccWAConversationsResult set SentMsg= SentMsg-1,NotSupported=NotSupported+1
        end
        

        SELECT @messageId as MessageId
    END;
ELSE IF @action = 17 BEGIN --update agent status for reassigning error message
    UPDATE ccWhatsAppConversationsOut
    SET IsAgentLoggingOut = @IsAgentLoggingOut
    WHERE conversationId = @conversationId;
END;
ELSE IF @action = 18 BEGIN
        DECLARE @dateNow DATETIME;
        SET @dateNow = DATEADD(HOUR, -23, GETDATE());

        UPDATE ccWhatsAppConversationsOut 
    SET finishedBy = 2, conversationStatus=17
        WHERE finishedBy = 0  AND requestDate <= @dateNow   
    END;
	ELSE IF @action = 19 select * from ccWhatsAppConversationsOut
	BEGIN 
		UPDATE ccWhatsAppConversationsOut SET assignDate = FirstMessageAgent where conversationId = @conversationId;
	END
END;'

        EXEC(@sql)

----------------------------------------------------------- Termina Leonardo Ramírez -------------------------------------------------------------------------

	SET @process = 'Alter SP ccspOutboundWhatsApp -- Carga Url @action=1 cuando la campaña esta apagaada o prendida'
	SET @sql = 'ALTER procedure [dbo].[ccspOutboundWhatsApp]
@action int,
@camId int = null,
@campType int = null,
@templateName varchar(512)=null
as
if @action=1 begin
declare @Url as varchar(50)
set @Url = (select Url from ccMetaWhatsAppConfigurations where Id=1)

IF @camId IS NULL AND @campType IS NULL
BEGIN
	select 
		distinct 
		cast(c. cam_id as int) as CamId,
		cam_descripcion as [Name],
		1 AS CampType,
		cam_procesando as [Start],
		Number as PhoneNumber, 
		REPLACE(@Url, ''phoneId'', PhoneNumberId) as Url, 
		Token
	from ccCamps c with(nolock)
	left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
	left join  ccCampsHorarios s ON s.cam_id = c.cam_id
	left join ccMetaWhatsAppNumbers wn on wn.cam_id = c.cam_id
	WHERE CampType=5 AND c.IDArea IS NOT NULL
	UNION
	SELECT -- load acd
		DISTINCT 
		CAST(ci.Inbound_id AS INT) AS CamId,
		ci.descripcion AS [Name],
		0 AS CampType,
		CAST(ci.Status AS BIT) AS [Start],
		cmw.Number AS PhoneNumber,
		REPLACE(@Url, ''phoneId'', cmw.PhoneNumberId) AS Url,
		cmw.Token AS Token
	FROM ccInbound ci WITH(NOLOCK)
	LEFT JOIN ccInboundHorarios cih ON cih.Inbound_id = ci.Inbound_id
	LEFT JOIN ccMetaWhatsAppNumbers cmw ON cmw.Inbound_Id = ci.Inbound_id
	WHERE ci.chat = 5  AND ci.IDArea IS NOT NULL
END
ELSE IF @campType IS NOT NULL
BEGIN
	IF @campType = 0
	BEGIN
		SELECT -- load acd
			DISTINCT 
			CAST(ci.Inbound_id AS INT) AS CamId,
			ci.descripcion AS [Name],
			0 AS CampType,
			CAST(ci.Status AS BIT) AS [Start],
			cmw.Number AS PhoneNumber,
			(CASE ci.Status WHEN 0 THEN '''' ELSE REPLACE(@Url, ''phoneId'', cmw.PhoneNumberId) END) AS Url,
			cmw.Token AS Token
		FROM ccInbound ci WITH(NOLOCK)
		LEFT JOIN ccInboundHorarios cih ON cih.Inbound_id = ci.Inbound_id
		LEFT JOIN ccMetaWhatsAppNumbers cmw ON cmw.Inbound_Id = ci.Inbound_id
		WHERE ci.chat = 5  AND ci.IDArea IS NOT NULL AND (@camId IS NULL or @camId=0 OR ci.Inbound_id = @camId)
	END
	ELSE
	BEGIN
		select 
			distinct 
			cast(c. cam_id as int) as CamId,
			cam_descripcion as [Name],
			1 AS CampType,
			cam_procesando as [Start],
			Number as PhoneNumber, 
			case cam_procesando when 0 then '''' else REPLACE(@Url, ''phoneId'', PhoneNumberId) end as Url, 
			Token
		from ccCamps c with(nolock)
		left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
		left join  ccCampsHorarios s ON s.cam_id = c.cam_id
		left join ccMetaWhatsAppNumbers wn on wn.cam_id = c.cam_id
		WHERE CampType=5 AND c.IDArea IS NOT NULL AND(@camId IS NULL or @camId=0 OR c.cam_id = @camId)
	END
END

end
else if @action=2 begin
	select top 1 A.id,A.LanguageCode,B.Number from ccMetaWAOutboundTemplates A
	inner join ccMetawhatsAppNumbers B on B.MetaId=A.MetaId
	where A.TemplateName=@templateName and B.Cam_Id=@camId

end'
	EXEC(@sql)

-------------------------------------------- Begin Ulises --------------------------------------------	

	-- Para insertar o actualizar en ccMenus
	set @process = 'insertar o actualizar ccMenus'
	set @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccMenus WHERE menu_id = 13030)
	BEGIN
		-- Si no existe, realiza el INSERT
		INSERT INTO ccMenus (menu_id, menu_descrip, parent, nivel, ordengral, [type], HelpSWF, release)
		VALUES(13030, ''Detalle de segmentos|Segment detail'',13000, ''B'', 12, 3, '''', ''c3c93fb90d8ed55d317dbbe258f51b6bd5372b73071d1f818f087b264ca99a80a6890def7dd644070e45e7c3e5ce8575'' )
	END
	ELSE
	BEGIN
		-- Si ya existe, realiza el UPDATE
		UPDATE ccMenus
		SET menu_descrip = ''Detalle de segmentos|Segment detail'',
			parent = 13000,
			nivel = ''B'',
			ordengral = 12,
			[type] = 3,
			HelpSWF = '''',
			release = ''c3c93fb90d8ed55d317dbbe258f51b6bd5372b73071d1f818f087b264ca99a80a6890def7dd644070e45e7c3e5ce8575''
		WHERE menu_id = 13030
	END'
	EXEC(@sql)

	set @process = 'Insertar o actualizar relación usuario-menú'
	set @sql = '
	update ccMenus
		set release=''2090e8fccd25cea4ecc5dca31a027f6eb558e6fe9e23d58d7b02544ab0bfbdbf9c255f81245206f27b7210a5bd04d823''
		,menu_descrip=''1|Descarga de grabaciones|Recordings Download'' 
	where menu_id = 7230 '
	EXEC(@sql)

	-- Para insertar o actualizar en ccMenuUser
	set @process = 'Insertar o actualizar relación usuario-menú'
	set @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccMenuUser WHERE id_User = 1 AND id_Menu = 13030)
	BEGIN
		-- Si no existe, realiza el INSERT
		INSERT INTO ccMenuUser(id_User, id_Menu, [type]) 
		VALUES (1, 13030, 3)
	END
	ELSE
	BEGIN
		-- Si ya existe, realiza el UPDATE
		UPDATE ccMenuUser
		SET [type] = 3
		WHERE id_User = 1 AND id_Menu = 13030
	END'
	EXEC(@sql)
------------------------------------------- end Ulises ----------------------------------------------------------

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
