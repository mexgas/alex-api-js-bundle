/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2024/06/13
Description: K064000
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
SET @versionfix = 18
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
    	
------------------------------------------------- Empieza David Medina ----------------------------------------------------------------------------------
---------------------------------------- K020116 | K020052 | K020053 | K020054 --------------------------------------------------------------------------
-------------------------------------------------------- Tablas -----------------------------------------------------------------------------------------
SET @process = 'K020052 Se añade columna answered para saber si ese template de envio masivo ya ha sido contestado'
SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''answered'' AND Object_ID = Object_ID(N''dbo.ccoWhatsLogDials''))
	BEGIN
		ALTER TABLE ccoWhatsLogDials ADD answered BIT NOT NULL DEFAULT 0;
	END'
EXEC(@sql)

SET @process = 'K020116 Se añade columna Category para saber la categoria del template enviado'
SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''Category'' AND Object_ID = Object_ID(N''dbo.ccWhatsAppGlobalIds''))
	BEGIN
		ALTER TABLE ccWhatsAppGlobalIds ADD Category varchar(50)
	END'
EXEC(@sql)

SET @process = 'K064019-Estados canal WhatsApp salida column alter type to varchar(35)'
SET @sql = '
    if EXISTS(select column_name from information_schema.columns  where table_name = ''messageStatus'' AND column_name = ''name'')
    BEGIN
        ALTER TABLE dbo.messageStatus ALTER COLUMN name VARCHAR(35)
    END'
EXEC(@sql)

SET @process = ' K064019-Estados canal WhatsApp salida 
			   - Se inserta registro en tabla messageStatus para estado cuando se termina la conversación exceder tiemp de respuesta por parte del agente '
SET @sql = '
	IF NOT EXISTS(select 1 from messageStatus where name = ''Unassigned due to agent timeout'')
	BEGIN
		INSERT INTO dbo.messageStatus (name, description, isFinished) VALUES (''Unassigned due to agent timeout'',  ''unassigned for exceeding the maximum response time'', 0) 
	END'
EXEC(@sql)

SET @process = 'K020116 Se inserta registro en tabla messageStatus para estado nuevo cuando se envian templates de manera masiva'
SET @sql = '
	IF NOT EXISTS(select 1 from messageStatus where name = ''Sent in bulk'')
	BEGIN
		INSERT INTO dbo.messageStatus (name, description, isFinished) VALUES (''Sent in bulk'',  ''Message sent in bulk, not replied'', 1) 
	END'
EXEC(@sql)
-------------------------------------------------- Stored Procedures ------------------------------------------------------------------------------------
---------------------------------------- K020116 | K020052 | K020053 | K020054 --------------------------------------------------------------------------
SET @process = 'Se elimina SP ccsp_ConversationWASaveOut'
SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ConversationWASaveOut'')
			begin
				DROP PROCEDURE ccsp_ConversationWASaveOut;
			end'
EXEC(@sql)

SET @process = ' K020116 | K020052 | K020053 | K020054 David Medina 
			   - Se modifica SP ccsp_ConversationWASaveOut añadiendo variable , @ConvId = NULL OUTPUT s
			   - Se modifica action 1 para añadirle el valor de la conversación creada a @ConvId
			   - Se modifica Action 12 para que no cargue conversasiones con status 19 y 20 al iniciar Multimedia que son conversaciones con estatus de envio masivo'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_ConversationWASaveOut] 
	  @action             INT
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
			exec ccsp_ConversationWASaveOut @action=16,@messageStatus=@messageStatus,@conversationId=@conversationId
        
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
			exec ccsp_ConversationWASaveOut @action=16,@messageStatus=@messageStatus,@conversationId=@conversationId
        
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
		else if @messageStatus=''rejected'' begin
			update ccWAConversationsResult set SentMsg= SentMsg-1,NotDelivered=NotDelivered+1
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

SET @process = ' K020116 David Medina 
			   - Se crea SP ccsp_createMessageAndGlobalId para que al momento que el outbound de WhatsApp haga el envio masivo se cree una nueva 
				 conversación, se guarde el mensaje y se cree su Id global'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_createMessageAndGlobalId] 
	@Type INT,
    @Messages VARCHAR(MAX)
    
	AS
	BEGIN
		SET NOCOUNT ON;

		IF @Type = 1
		BEGIN
			DECLARE @SplitResults TABLE (Id INT, Value NVARCHAR(255))
			INSERT INTO @SplitResults
			SELECT Id, Value FROM dbo.fn_RIASplitDelimited(@Messages, '','')

			DECLARE @CamId VARCHAR(7)
			DECLARE @PhoneClient VARCHAR(15)
			DECLARE @PhoneWa VARCHAR(15)
			DECLARE @MetaId VARCHAR(150)
			DECLARE @TimeStamp varchar (50)
			DECLARE @TimeStampUTC varchar (50)
			DECLARE @TemplateCategory varchar(50);
			DECLARE @TemplateContent varchar(1000);
			DECLARE @ConvId int
	
			DECLARE @CurrentId INT = 1
			DECLARE @RowCount INT

			SELECT @RowCount = COUNT(*) FROM @SplitResults 

			WHILE @CurrentId <= @RowCount
			BEGIN

				SELECT @MetaId = Value FROM @SplitResults WHERE Id = @CurrentId 

				SELECT  @TemplateCategory = Category, @TemplateContent = SUBSTRING(mwat.body, CHARINDEX(''"text":"'', mwat.body) + 8, CHARINDEX(''"}'', mwat.body) - (CHARINDEX(''"text":"'', mwat.body) + 8)),
					@CamId = wld.CamId, @PhoneClient = PhoneClient, @PhoneWa = PhoneWa, @TimeStamp = TimeSpam,
					@TimeStampUTC = CONVERT(varchar(23), DATEADD(HOUR, -tz.tz_offset, wld.TimeSpam), 121) 
					FROM ccoWhatsLogDials wld
					JOIN ccWhatsAppOutSource waos ON wld.WaOutId = waos.WAOut_Id
					JOIN ccMetaWAOutboundTemplates mwat ON waos.TemplateId = mwat.Id
					JOIN ccTimeZones tz ON tz.tz_id = waos.TimeZone
					WHERE wld.MetaId = @MetaId;

				EXEC ccsp_ConversationWASaveOut @action = 1, @camId = @CamId, @phoneCam = @PhoneWa, @clientId = @PhoneClient, @conversationStatus = 20, @ConvId = @ConvId OUTPUT;

				EXEC ccsp_ConversationWASaveOut @action = 4, @messageId = @MetaId, @messageIdUi = 0, @clientNum = @PhoneClient, @vonageNum = @PhoneWa, @typeMessage = ''template'', 
				@content = @TemplateContent, @conversationId = @ConvId,  @timeStampMessage = @TimeStamp, @timeStampMessageUTC = @TimeStampUTC, @originType = ''Admin''

				update ccoWhatsLogDials set conversationId = @convId where MetaId = @MetaId

				EXEC ccsp_WhatsAppGlobalIds  @ConversationType =1, @ConversationId = @ConvId, @MessageId = @MetaId, @AssociatedNumber= @PhoneWa, @ClientNumber= @PhoneClient, @TemplateCategory = @TemplateCategory

				SET @CurrentId = @CurrentId + 1
			END  
		END
	END'
EXEC(@sql)

SET @process = ' K020052 | K020053 | K020054 David Medina 
			   - Se crea SP ccsp_OutboundConversationResponseExceeded para verificar si el cliente ha respondido en menos de 23 horas el mensaje de planmtilla'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_OutboundConversationResponseExceeded] 
    @conversationId INT
	AS
	BEGIN
		IF EXISTS (
			SELECT 1
			FROM ccowhatslogdials cwd
			JOIN ccWhatsAppConversationsOut cwc ON cwd.conversationId = cwc.conversationId
			WHERE cwd.conversationId = @conversationId AND cwd.timeSpam <= DATEADD(Hour, -23, GETDATE())
		)
		BEGIN
			SELECT CAST(1 AS BIT) AS result;
			return
		END
		ELSE
		BEGIN
			SELECT CAST(0 AS BIT) AS result;
			return
		END
	END;'
EXEC(@sql)

SET @process = 'Se elimina SP ccsp_WAOUTGetLogDials'
SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_WAOUTGetLogDials'')
			begin
				DROP PROCEDURE ccsp_WAOUTGetLogDials;
			end'
EXEC(@sql)

SET @process = ' K020052 | K020053 | K020054 David Medina 
			   - Se modifica SP ccsp_WAOUTGetLogDials añadiendo variables @CamNumber, @ConversationId, @MetaId
			   - Se modifica action 1 para que tome también en cuanta el número de whatsApp de la campaña, que solamente verifique el último registro en donde
			     coincidan el numerp de la campaña y del cliente y que verifique si esta ya ha sido respondido
			   - Se crea Action 2 para obtrener el texto de las plantilla buscando en tabla de registrsos ccoWhatsLogDials'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_WAOUTGetLogDials]
	@Action				INT,
	@CamId				INT = NULL,
	@CamNumber			VARCHAR(50) = NULL,
	@ClientId			VARCHAR(50) = NULL,
	@ConversationId		INT = NULL,
	@MetaId				VARCHAR(1000) = NULL
	AS
	BEGIN

		DECLARE @LastMetaId VARCHAR(1000);
		DECLARE @Answered BIT;

		IF @Action = 1 -- Verifica para el último registro guardado en ccowhatslogdials si han pasado menos de 24 horas desde su envio 
		BEGIN
			DECLARE @InitialTime DATETIME;       
			DECLARE @LastConversationId BIGINT; 
			DECLARE @ConvId INT; 
        
			SET @InitialTime = DATEADD(HH, -24, GETDATE());

			SELECT TOP(1) @LastMetaId = cwld.MetaId, @LastConversationId = cwld.ConversationId,@Answered = cwld.answered, @ConvId = cwld.conversationId
			FROM ccoWhatsLogDials cwld WITH(NOLOCK)
			WHERE cwld.CamId = @CamID 
			AND cwld.PhoneWa = @CamNumber
			AND cwld.PhoneClient = @ClientId
			AND cwld.TimeSpam >= @InitialTime  
			ORDER BY cwld.TimeSpam DESC;

			IF @Answered = 0 
			BEGIN

				update ccowhatslogdials set answered = 1 where metaid = @LastMetaId
				update ccWhatsAppConversationsOut set conversationStatus = 1 where conversationId = @ConvId

				SELECT @LastMetaId AS MetaId, 
						@LastConversationId AS ConversationId;
			END
			ELSE
			BEGIN
				SELECT '''' AS MetaId, 
						CAST(0 AS BIGINT) AS ConversationId;
			END
		END

		ELSE IF @Action = 2 -- Obtiene el texto del mensaje de plantilla enviado masivamente
		BEGIN
			SELECT wld.timeSpam as TimeStamp, SUBSTRING(mwat.body, CHARINDEX(''"text":"'', mwat.body) + 8, CHARINDEX(''"}'', mwat.body) - (CHARINDEX(''"text":"'', mwat.body) + 8)) as Content, wld.CamId as CamId 
			FROM ccoWhatsLogDials wld 
			JOIN ccWhatsAppOutSource waos ON wld.WaOutId = waos.WAOut_Id
			JOIN ccMetaWAOutboundTemplates mwat ON waos.TemplateId = mwat.Id WHERE wld.MetaId = @MetaId; 
		END
	END '
EXEC(@sql)

SET @process = 'Se elimina SP ccsp_RIAChatACDSchedule'
SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAChatACDSchedule'')
			begin
				DROP PROCEDURE ccsp_RIAChatACDSchedule;
			end'
EXEC(@sql)

SET @process = ' K020052 | K020053  David Medina 
			   - Se modifica SP ccsp_RIAChatACDSchedule agregando @Option = 2 para que verifique si la campaña de salida esta dentro de horario para poder enviar respuesta de cliente a Agente'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_RIAChatACDSchedule]
	@Option     AS SMALLINT,
	@Inbound_Id AS INT = 0,
	@Outbound_Id AS INT = 0
	AS
	SET NOCOUNT ON
	SET DATEFIRST 1

	declare @today  datetime
	declare @day    smallint
	declare @hour   smallint
	declare @minute smallint  
	declare @total  smallint 

	--Inbound campaigns
	IF @Option = 1 -- Schedule
	BEGIN

	select @today =  getdate()
	select @day = datepart(dw,@today), @hour = datepart(hh,@today), @minute = datepart(mi,@today)

	if ( @day=1 )	--LUNES
	begin
		select @total = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND LUNES = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	if @day=2	--MARTES
	begin
		select @total = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND MARTES = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	if @day=3	--MIERCOLES
	begin
		select @total = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND MIERCOLES = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	if @day=4	--JUEVES
	begin
		select @total = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND JUEVES = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	if @day=5	--VIERNES
	begin
		select @total = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND VIERNES = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	if @day=6	--SABADO
	begin
		select @total = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND SABADO = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	if @day=7	--DOMINGO
	begin
		select @total = count(*)
		from ccInbound I join ccInboundHorarios IH
		on I.Inbound_id = IH.Inbound_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.Inbound_id = @inbound_id
		AND DOMINGO = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	select @total as ''ValidACDSchedules''
	END

	--Outbound campaigns
	IF @Option = 2 -- Schedule
	BEGIN

	select @today =  getdate()
	select @day = datepart(dw,@today), @hour = datepart(hh,@today), @minute = datepart(mi,@today)

	if ( @day=1 )	--LUNES
	begin
		select @total = count(*)
		from ccCamps I join ccCampsHorarios IH  
		on I.cam_id = IH.cam_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.cam_id = @Outbound_Id
		AND LUNES = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	if @day=2	--MARTES
	begin
		select @total = count(*)
		from ccCamps I join ccCampsHorarios IH
		on I.cam_id = IH.cam_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.cam_id = @Outbound_Id
		AND MARTES = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	if @day=3	--MIERCOLES
	begin
		select @total = count(*)
		from ccCamps I join ccCampsHorarios IH
		on I.cam_id = IH.cam_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.cam_id = @Outbound_Id
		AND MIERCOLES = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	if @day=4	--JUEVES
	begin
		select @total = count(*)
		from ccCamps I join ccCampsHorarios IH
		on I.cam_id = IH.cam_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.cam_id = @Outbound_Id
		AND JUEVES = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	if @day=5	--VIERNES
	begin
		select @total = count(*)
		from ccCamps I join ccCampsHorarios IH
		on I.cam_id = IH.cam_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.cam_id = @Outbound_Id
		AND VIERNES = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	if @day=6	--SABADO
	begin
		select @total = count(*)
		from ccCamps I join ccCampsHorarios IH
		on I.cam_id = IH.cam_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.cam_id = @Outbound_Id
		AND SABADO = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	if @day=7	--DOMINGO
	begin
		select @total = count(*)
		from ccCamps I join ccCampsHorarios IH
		on I.cam_id = IH.cam_id
		join ccHorarios H on IH.horario_id = H.Horario_id
		Where I.cam_id = @Outbound_Id
		AND DOMINGO = 1
		AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
		AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
	end
	select @total as ''ValidCamSchedules''
	END

	SET NOCOUNT OFF'
EXEC(@sql)

SET @process = 'Se elimina SP ccsp_WhatsAppGlobalIds'
SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_WhatsAppGlobalIds'')
			begin
				DROP PROCEDURE ccsp_WhatsAppGlobalIds;
			end'
EXEC(@sql)

SET @process = ' K020116 David Medina 
			   - Se modifica SP ccsp_WhatsAppGlobalIds para que verifique si debe crear o no un nuevo Id global para los mensajes de conversaciones de salida enviados manualmente
			   - TemplateCategory varchar(30) = '''''

SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_WhatsAppGlobalIds]  
        @ConversationType TINYINT = -1,
        @ConversationId INT = 0,
        @MessageId VARCHAR(MAX) = '''',
        @AssociatedNumber VARCHAR (30), 
        @ClientNumber VARCHAR(30),
		@TemplateCategory varchar(30) = ''''
		AS  
		SET NOCOUNT ON;  

			IF @ConversationType = 0 AND NOT EXISTS(SELECT 1 FROM ccWhatsAppConversations WHERE conversationId = @ConversationId)
			BEGIN
				RAISERROR(''ERROR. No existe una conversación de entrada con el id especificado'', 18, 1);
				RETURN(0);
			END;
			ELSE IF @ConversationType = 1 AND NOT EXISTS(SELECT * FROM ccWhatsAppConversationsOut WHERE conversationId = @ConversationId)
			BEGIN
				RAISERROR(''ERROR. No existe una conversación de salida con el id especificado'', 18, 1);
				RETURN(0);
			END;
			ELSE
			BEGIN
				DECLARE @originType VARCHAR(20) = '''';
				DECLARE @firstMessageDateFromAgent DATETIME = NULL;
				DECLARE @messageStatus VARCHAR(20) = '''';
				DECLARE @firstMessageConversationIdFromAgent INT = NULL;
				DECLARE @firstMessageConversationTypeFromAgent TINYINT = NULL;
				DECLARE @isBilled BIT = 0;

				IF @ConversationType = 0 
				BEGIN
					SET @originType = (SELECT originType FROM ccWAMessagesConversations WHERE messageId = @MessageId);
					SELECT @firstMessageDateFromAgent = timeStampMessage, @messageStatus = messageStatus
					FROM ccWAMessagesConversations
					WHERE messageId = @MessageId AND @originType IN (''Agent'', ''Admin'');
				END;
				ELSE 
				BEGIN
					SET @originType = (SELECT originType FROM ccWAMessagesConversationsOut WHERE messageId = @MessageId);
					SELECT @firstMessageDateFromAgent = timeStampMessage, @messageStatus = messageStatus
					FROM ccWAMessagesConversationsOut
					WHERE messageId = @MessageId AND @originType IN (''Agent'', ''Admin'');
				END;

				DECLARE @globalId INT

				IF @TemplateCategory IS NOT NULL
				BEGIN
					SELECT @globalId = MAX(GlobalId) FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @AssociatedNumber AND ClientNumber = @ClientNumber AND Category = @TemplateCategory;
				END
				ELSE
				BEGIN
					SELECT @globalId = MAX(GlobalId) FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @AssociatedNumber AND ClientNumber = @ClientNumber AND Category IS NULL;
				END

				IF @originType = ''Agent'' AND @messageStatus NOT IN(''rejected'', ''undeliverable'', ''submitted'')
				BEGIN
					SET @firstMessageConversationIdFromAgent = @ConversationId;
					SET @firstMessageConversationTypeFromAgent = @ConversationType;
					SET @isBilled = 1;
				END
				ELSE
				BEGIN
					SET @firstMessageDateFromAgent = NULL
				END

				IF @globalId IS NULL
				BEGIN
					INSERT INTO ccWhatsAppGlobalIds (AssociatedNumber, ClientNumber, FirstMessageDateFromAgent, FirstMessageConversationIdFromAgent, FirstMessageConversationTypeFromAgent, IsBilled, Category)
					VALUES (@AssociatedNumber, @ClientNumber, @firstMessageDateFromAgent, @firstMessageConversationIdFromAgent, @firstMessageConversationTypeFromAgent, @isBilled, @TemplateCategory);

					SET @globalId = SCOPE_IDENTITY();
				END

				DECLARE @TempFirstMessageDate DATETIME = (SELECT FirstMessageDateFromAgent FROM ccWhatsAppGlobalIds WHERE GlobalId = @globalId);
                        
				--Update if message status changes
				IF @originType IN (''Agent'', ''Admin'') AND @messageStatus NOT IN(''rejected'', ''undeliverable'', ''submitted'') AND @globalId IS NOT NULL
				BEGIN
					UPDATE ccWhatsAppGlobalIds SET IsBilled = 1 WHERE GlobalId = @globalId
				END

				IF DATEDIFF(HOUR, @TempFirstMessageDate, GETDATE()) >= 24 
				BEGIN 
					INSERT INTO ccWhatsAppGlobalIds (AssociatedNumber, ClientNumber, FirstMessageDateFromAgent, FirstMessageConversationIdFromAgent, FirstMessageConversationTypeFromAgent, IsBilled, Category)
					VALUES (@AssociatedNumber, @ClientNumber, @firstMessageDateFromAgent, @firstMessageConversationIdFromAgent, @firstMessageConversationTypeFromAgent, @isBilled, @TemplateCategory);

					SET @globalId = SCOPE_IDENTITY();   
				END

				-- If the message is from agent update the date 
				IF @originType = ''Agent'' AND @TempFirstMessageDate IS NULL
				BEGIN
					UPDATE ccWhatsAppGlobalIds SET FirstMessageDateFromAgent = @firstMessageDateFromAgent,
													FirstMessageConversationIdFromAgent =  @ConversationId,
													FirstMessageConversationTypeFromAgent = @ConversationType,
													IsBilled = @isBilled
					WHERE GlobalId = @globalId;
				END
				-- Insert into ccWhatsAppGlobalIdsRelationship
				IF @globalId != 0 AND NOT EXISTS(SELECT GlobalId FROM ccWhatsAppGlobalIdsRelationship WHERE GlobalId = @globalId AND ConversationId = @ConversationId AND @ConversationType = ConversationType)
				BEGIN
					INSERT INTO ccWhatsAppGlobalIdsRelationship(GlobalId, ConversationId, ConversationType)
					VALUES (@globalId, @ConversationId, @ConversationType)
				END

				select @globalId as globalId

				RETURN(@globalId)
        
			END
			SET NOCOUNT OFF'
EXEC(@sql)

SET @process = 'Se elimina SP ccsp_WhatsAppOutboundTemplates'
SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_WhatsAppOutboundTemplates'')
			begin
				DROP PROCEDURE ccsp_WhatsAppOutboundTemplates;
			end'
EXEC(@sql)

SET @process = ' K020116 David Medina 
			   - Se modifica SP ccsp_WhatsAppOutboundTemplates añadiendo @Action = 2 para obtener la categoría de template'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_WhatsAppOutboundTemplates]
						@Action SMALLINT, 
						@TemplateName VARCHAR(500) = '''' ,
						@isMeta int=0,
						@ConversationId INT = 0
						AS  
						SET NOCOUNT ON;  
						IF @Action = 0  -- Get all template information
						BEGIN	
							SELECT TemplateName, LanguageCode, Type, Format, Body FROM ccWhatsAppOutboundTemplates WHERE TemplateName = @TemplateName
						END
						IF @Action = 1  -- Get template body 
						BEGIN
							if @isMeta =0 begin
								SELECT Body FROM ccWhatsAppOutboundTemplates WHERE TemplateName = @TemplateName
							end
							else begin
								select header, Body,footer from ccMetaWAOutboundTemplates WHERE TemplateName = @TemplateName 
							end
						END
					
						IF @Action = 2  -- Get category from ccWhatsAppGlobalIds
						BEGIN
							SELECT UPPER(wagi.Category) AS Category
							FROM ccWhatsAppGlobalIds wagi
							INNER JOIN ccWhatsAppGlobalIdsRelationship wagir ON wagi.GlobalId = wagir.GlobalId
							WHERE wagir.ConversationId = @ConversationId AND wagir.ConversationType = 1;
						END

						SET NOCOUNT OFF '
EXEC(@sql)
-------------------------------------------------- Termina David Medina ----------------------------------------------------------------------------------
-------------------------------------------------- BEGIN Marco García  ----------------------------------------------------------------------------------------
-------------------------------------------------- | K064016-Estados canal Chat | 

SET @process = 'K064016-Estados canal Chat se crea la tabla ccChatCauseFinished'
SET @sql = 'IF NOT EXISTS (SELECT *
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = ''dbo'' AND TABLE_NAME = ''ccChatCauseFinished'')
BEGIN
    CREATE TABLE ccChatCauseFinished(
        CauseFinishedId INT NOT NULL PRIMARY KEY,
        [OpTagEs] [VARCHAR](250) NOT NULL,
        [OpTagEn] [VARCHAR](250) NOT NULL,
        [OpTagPt] [VARCHAR](250) NOT NULL
    )
END'
EXEC(@sql)

SET @process = 'K064016-Estados canal Chat se agrega la columna causeFinishedId a la tabla ccRIAChats '
SET @sql = 'IF NOT EXISTS(SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME = ''causeFinishedId'' AND TABLE_NAME = ''ccRIAChats'')
BEGIN
    ALTER TABLE ccRIAChats ADD causeFinishedId INT NULL
END'
EXEC(@sql)


SET @process = 'K064016-Estados canal Chat se inserta un registro a la tabla ccRIAChatStatus '
SET @sql = 'IF NOT EXISTS( SELECT * FROM ccRIAChatStatus WHERE Description = ''UnassignedDueToFailure'')
BEGIN
    INSERT INTO dbo.ccRIAChatStatus
    (
        description
    )
    VALUES
    (   ''UnassignedDueToFailure''
        )
END'

EXEC(@sql)

SET @process = 'K064016-Estados canal Chat se agrega un registro a la tabla ccChatCauseFinished'
SET @sql = 'IF NOT EXISTS(SELECT * FROM dbo.ccChatCauseFinished AS cccf WHERE cccf.CauseFinishedId = 1)  
BEGIN
    INSERT INTO dbo.ccChatCauseFinished
    (
        CauseFinishedId,
        OpTagEs,
        OpTagEn,
        OpTagPt
    )
    VALUES
    (   1,  -- CauseFinishedId - int
        ''Finalizada por inactividad'', -- OpTagEs - varchar(250)
        ''Finished by timeout'', -- OpTagEn - varchar(250)
        ''Encerrada por inatividade''  -- OpTagPt - varchar(250)
    )
END'
EXEC(@sql)

SET @process = 'K064019-Estados canal WhatsApp salida Se elimina SP ccsp_MultimediaCommon'
SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_MultimediaCommon'')
			begin
				DROP PROCEDURE ccsp_MultimediaCommon;
			end'
EXEC(@sql)

SET @process = 'K064019-Estados canal WhatsApp salida se modifica el @option = 2, el c.conversationDate AS ConversationDate, línea 1161 y 1197'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon]
@Option AS SMALLINT,
@inboundId AS SMALLINT = 0,
@conversationId AS INT = 0,
@ServiceType AS SMALLINT = 0,
@status as SMALLINT =0,
@messagesList as varchar(max) = '''',
@agentId AS SMALLINT = 0,
@CampType bit =0
AS
BEGIN
    SET NOCOUNT ON;

    IF @Option = 0 --  Obtener lista de configuraciones de campañas
    BEGIN
        SELECT CAST(campaign.cam_id AS INT) AS Id,
               campaign.cam_descripcion AS [Name],
               ISNULL(configuration.number, '''') AS Phone,
               CAST(graphics.graphic_id AS INT) AS GraphicId,
               0 AS isMeta
        FROM ccCamps campaign 
        INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
        INNER JOIN ccWhatsAppNumbers configuration ON campaign.cam_id = configuration.camp_id
        WHERE configuration.status != 0 AND campaign.CampType = 5

        UNION ALL

        SELECT CAST(campaign.cam_id AS INT) AS Id, -- Meta WhatsApp
               campaign.cam_descripcion AS [Name],
               ISNULL(configuration.number, '''') AS Phone,
               CAST(graphics.graphic_id AS INT) AS GraphicId,
               1 AS isMeta
        FROM ccCamps campaign 
        INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
        INNER JOIN ccMetaWhatsAppNumbers configuration ON campaign.cam_id = configuration.Cam_Id
        WHERE configuration.status != 0 AND campaign.CampType = 5   
                                                            
    END

    ELSE IF @Option = 1 -- Obtener lista de configuraciones de ACDs
    BEGIN
        SELECT CAST(inbound.Inbound_id AS INT) AS Id,
               inbound.descripcion AS [Name],
               ISNULL(numbers.number, '''') AS Phone,
               CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
               inbound.tNotas AS WrapUpTime,
               CAST(graphics.graphic_id AS INT) AS GraphicId,
               0 AS isMeta
        FROM ccInbound inbound
        INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
        INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
        INNER JOIN ccWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.inboundId  
        WHERE inbound.Status != 0 AND configuration.meanContactTypeId = 5 AND numbers.status != 0 

        UNION ALL

        SELECT CAST(inbound.Inbound_id AS INT) AS Id, -- Meta WhatsApp
               inbound.descripcion AS [Name],
               ISNULL(numbers.number, '''') AS Phone,
               CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
               inbound.tNotas AS WrapUpTime,
               CAST(graphics.graphic_id AS INT) AS GraphicId,
               1 AS isMeta
        FROM ccInbound inbound
        INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
        INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
        INNER JOIN ccMetaWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.Inbound_Id
        WHERE inbound.Status != 0 AND configuration.meanContactTypeId = 5 AND numbers.status != 0 
                                                            
    END

     ELSE IF(@Option = 2)
    BEGIN
        DECLARE @OldAgentId INT = 0
        DECLARE @OldConversationId INT = 0

        IF @CampType = 0 BEGIN -- ACD
            SELECT @OldAgentId = conv.agentId,
                   @OldConversationId = rel.conversationIdBefore
            FROM ccWhatsAppConversationsRelationship rel 
            RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
            WHERE rel.conversationIdAfter = @conversationId

            SELECT CAST(i.chat AS int) AS ServiceType,
                   CAST(c.conversationId AS int) AS ConversationID,
                   c.clientId AS ClientId,
                   cm.conexionInfo AS [To],
                   CAST(i.Inbound_id AS int) AS ACDId,
                   i.descripcion AS ACDName,
                   CAST(g.graphic_id AS int) AS ACDGraphicId,
                   CAST(cm.closeConversationTime AS int) AS [TimeOut],
                   CAST(cm.answerTimeOut AS int) AS [TimeOutWarning],
                   i.ExitWrapUpDisposition AS [ExitWrapUpDisposition],
                   i.tNotas AS [WrapUpTime],
                   i.ShowCalifWnd,
                   CAST(ISNULL(answerTimeoutClient, 30) AS int) AS [AnswerTimeoutClient],
                   ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS [SecTimeOutLastMessageAgent],
                   ISNULL(permission.AllowUnassign, 0) AS AllowUnassign,
                   ISNULL(permission.AllowSpam, 0) AS AllowSpam,
                   ISNULL(@OldAgentId, 0) AS OldAgentId,
                   ISNULL(@OldConversationId, 0) AS OldConversationId,
                   c.agentId AS AgentId,
                   ISNULL(c.IsAgentLoggingOut, 0) AS IsAgentLoggingOut,
                   ISNULL(cm.allowFileAttachments, 0) AS AllowFileAttachments,
				   c.conversationDate AS ConversationDate
            FROM ccWhatsAppConversations c
            LEFT JOIN ccInbound i ON c.inboundId = i.Inbound_id 
            LEFT JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId    
            LEFT JOIN ccRIAInboundGraph g ON g.Inbound_id = i.Inbound_id
            LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
            LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
            WHERE c.conversationId = @conversationId

        END ELSE BEGIN -- Campaña
            SELECT @OldAgentId = conv.agentId,
                   @OldConversationId = rel.conversationIdBefore
            FROM ccWhatsAppConversationsRelationshipOut rel 
            RIGHT JOIN ccWhatsAppConversationsOut conv ON conv.conversationId = rel.conversationIdBefore
            WHERE rel.conversationIdAfter = @conversationId

            SELECT CAST(i.CampType AS int) AS ServiceType,
                   CAST(c.conversationId AS int) AS ConversationID,
                   c.clientId AS ClientId,
                   c.phoneCamp AS [To],
                   CAST(i.cam_id AS int) AS ACDId,
                   i.cam_descripcion AS ACDName,
                   CAST(g.graphic_id AS int) AS ACDGraphicId,
                   CAST(cm.closeConversationTime AS int) AS [TimeOut],
                   CAST(cm.answerTimeoutClient AS int) AS [TimeOutWarning],
                   i.exitAssisted AS [ExitWrapUpDisposition],              
                   CAST(i.cam_tnotas AS int) AS [WrapUpTime],
                   i.cam_ShowCalifWnd AS ShowCalifWnd, 
                   CAST(ISNULL(answerTimeoutClient, 30) AS int) AS [AnswerTimeoutClient],
                   ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS [SecTimeOutLastMessageAgent],
                   ISNULL(permission.AllowUnassign, 0) AS AllowUnassign,
                   ISNULL(permission.AllowSpam, 0) AS AllowSpam,
                   ISNULL(@OldAgentId, 0) AS OldAgentId,
                   ISNULL(@OldConversationId, 0) AS OldConversationId,
                   c.agentId AS AgentId,
                   ISNULL(cm.allowFileAttachments, 0) AS AllowFileAttachments,
				   c.conversationDate AS ConversationDate
            FROM ccWhatsAppConversationsOut c
            LEFT JOIN ccCamps i ON c.camId = i.cam_id 
            LEFT JOIN contactMeanOut cm ON c.camId = cm.camp_id
            LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
            LEFT JOIN ccLastMessageAgentByConversationOut lm ON lm.conversationId = c.conversationId
            LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
            WHERE c.conversationId = @conversationId
        END
    END
    
     ELSE IF(@Option = 3)
    BEGIN
        IF @CampType = 0 BEGIN -- ACD
            SELECT CAST(inbound.Inbound_id AS INT) AS Id,
                   inbound.descripcion AS Name,
                   ISNULL(configuration.conexionInfo, '''') AS Phone,
                   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                   inbound.tNotas AS WrapUpTime,
                   CAST(ISNULL(graphics.graphic_id, 1) AS INT) AS GraphicId,
                   0 AS isMeta
            FROM ccInbound inbound
            INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
            INNER JOIN ccWhatsAppNumbers von ON von.inboundId = inbound.Inbound_id
            INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
            WHERE inbound.Inbound_id = @inboundId

            UNION ALL

            SELECT CAST(inbound.Inbound_id AS INT) AS Id, -- Meta WhatsApp
                   inbound.descripcion AS [Name],
                   ISNULL(numbers.number, '''') AS Phone,
                   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                   inbound.tNotas AS WrapUpTime,
                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                   1 AS isMeta
            FROM ccInbound inbound
            INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
            INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
            INNER JOIN ccMetaWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.Inbound_Id 
            WHERE inbound.Inbound_id = @inboundId       
        END ELSE BEGIN
            SELECT CAST(campaign.cam_id AS INT) AS Id,
                   campaign.cam_descripcion AS [Name],
                   ISNULL(configuration.conexionInfo, '''') AS Phone,
                   CAST(ISNULL(configuration.answerTimeoutClient, 0) AS int) AS TimeOut,
                   CAST(campaign.cam_tnotas AS int) AS WrapUpTime,
                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                   0 AS isMeta
            FROM ccCamps campaign
            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
            INNER JOIN ccWhatsAppNumbers von ON von.camp_id = campaign.cam_id
            INNER JOIN contactMeanOut configuration ON campaign.cam_id = configuration.camp_id 
            WHERE campaign.cam_id = @inboundId

            UNION ALL

            SELECT CAST(campaign.cam_id AS INT) AS Id, -- Meta WhatsApp
                   campaign.cam_descripcion AS [Name],
                   ISNULL(configuration.number, '''') AS Phone,
                   CAST(ISNULL(configurationOut.answerTimeoutClient, 0) AS int) AS TimeOut,
                   CAST(campaign.cam_tnotas AS int) AS WrapUpTime,
                   CAST(graphics.graphic_id AS INT) AS GraphicId,
                   1 AS isMeta
            FROM ccCamps campaign 
            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
            INNER JOIN ccMetaWhatsAppNumbers configuration ON campaign.cam_id = configuration.Cam_Id
            INNER JOIN contactMeanOut configurationOut ON (campaign.cam_id = configurationOut.camp_id AND campaign.cam_id = @inboundId)
            WHERE campaign.cam_id = @inboundId
        END
    END

    ELSE IF(@Option = 4)
    Begin
        DECLARE @pathFile AS VARCHAR(MAX);
        DECLARE @filetype AS VARCHAR(5);
        DECLARE @mensajes TABLE(idMessage VARCHAR(150));
        DECLARE @tmpMessageConversations TABLE(
            [messageId] VARCHAR(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
            [conversationId] INT NOT NULL,
            [timeStampMessage] DATETIME NOT NULL,
            [originType] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
            [price] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
            [messageIdUi] INT NULL,
            [currency] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [typeMessage] VARCHAR(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [content] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [clientNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [vonageNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            [timeStampMessageUTC] DATETIME NULL,
            [messageStatus] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
        );


       INSERT INTO @mensajes
       SELECT value FROM dbo.fn_RIASplitDelimited(@messagesList, '','');

                                                        
      IF (@CampType = 0)
        BEGIN
            INSERT INTO @tmpMessageConversations (messageId, conversationId, timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus)
            SELECT messageId, conversationId, timeStampMessageUTC AS timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus
            FROM ccWAMessagesConversations 
            WHERE messageId IN (SELECT idMessage FROM @mensajes);
        END
        IF (@CampType = 1)
        BEGIN
            INSERT INTO @tmpMessageConversations (messageId, conversationId, timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus)
            SELECT messageId, conversationId, timeStampMessageUTC AS timeStampMessage, originType, price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC, messageStatus
            FROM ccWAMessagesConversationsOut 
            WHERE messageId IN (SELECT idMessage FROM @mensajes);
        END

        SELECT @pathFile = valor FROM ccSettings WHERE setting_id = 230;

        SELECT
            messageId AS MessageId,
            messageStatus AS Status,
            originType AS Origin,
            CASE 
                WHEN originType = ''Client'' THEN 3
                WHEN originType = ''Agent'' THEN 2
                WHEN originType = ''Admin'' THEN 1
                ELSE 0 
            END AS OriginType,
            timeStampMessage AS [Timestamp],
            CASE 
                WHEN typeMessage IN (''text'', ''template'', ''image'', ''video'') THEN content 
                ELSE '''' 
            END AS Content,
            typeMessage AS Type,
            CASE 
                WHEN typeMessage IN (''file'', ''image'', ''video'') THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 1), '':'') WHERE id = 2)
                WHEN typeMessage NOT IN (''text'', ''location'', ''file'', ''template'', ''image'', ''video'') THEN content
                ELSE '''' 
            END AS Caption,
            CASE 
                WHEN originType = ''Client'' THEN 
                    CASE
                        WHEN typeMessage = ''text'' OR typeMessage = ''location'' OR (typeMessage = ''file'' AND (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 2), '':'') WHERE id = 2) = '''') THEN ''''
                        ELSE @pathFile + char(92) + CASE WHEN @CampType = 0 THEN ''INBOUND'' ELSE ''OUTBOUND'' END + char(92) + CAST(conversationId / 1000 AS VARCHAR(30)) + char(92) + CAST(conversationId AS VARCHAR(20)) + char(92) + typeMessage + char(92) + messageId + 
                            CASE
                                WHEN typeMessage = ''video'' THEN ''.mp4''
                                WHEN typeMessage = ''image'' THEN ''.jpg''
                                WHEN typeMessage = ''audio'' THEN ''.mp3''
                                WHEN typeMessage = ''file'' THEN (SELECT SUBSTRING(content, LEN(content) - CHARINDEX(''.'', REVERSE(content)) + 1, LEN(content)))
                                ELSE '''' 
                            END
                    END
                ELSE 
                    CASE
                        WHEN typeMessage = ''text'' OR typeMessage = ''location'' OR typeMessage = ''template'' THEN ''''
                        ELSE content
                    END
            END AS [Url],
            CASE 
                WHEN typeMessage = ''file'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 3), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [FileSize],
            CASE 
                WHEN typeMessage = ''file'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 4), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [FileName],
            CASE 
                WHEN typeMessage = ''location'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 1), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [Address],
            CASE 
                WHEN typeMessage = ''location'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 2), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [Lat],
            CASE 
                WHEN typeMessage = ''location'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 3), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [Long],
            CASE 
                WHEN typeMessage = ''location'' THEN (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 4), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [Name],
            CASE 
                WHEN typeMessage = ''location'' THEN ''https://www.google.com/maps/search/'' + (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 2), '':'') WHERE id = 2) + '','' + (SELECT value FROM dbo.fn_RIASplitDelimited((SELECT value FROM dbo.fn_RIASplitDelimited(content, ''|'') WHERE id = 3), '':'') WHERE id = 2)
                ELSE '''' 
            END AS [LocationURL]
        FROM @tmpMessageConversations
        ORDER BY Timestamp ASC;
    END
                                                                            
    ELSE IF(@Option = 5)
    BEGIN
        if @CampType =0 begin
            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
                FROM contactMeanIn
            WHERE inboundId = @inboundId
        end 
        else begin
            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
                FROM contactMeanOut
            WHERE camp_id = @inboundId
        end 
    END
    ELSE IF(@Option = 6)
    BEGIN
        SELECT [Login] AS ''OriginName''
            FROM [ccUsers]
        WHERE [User_id] = @agentId
    END
END'
EXEC(@sql)

SET @process = 'K064019-Estados canal WhatsApp salida Se elimina SP ccsp_RIAInsertChat'
SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAInsertChat'')
			begin
				DROP PROCEDURE ccsp_RIAInsertChat;
			end'
EXEC(@sql)

SET @process = 'K064019-Estados canal WhatsApp salida se modifica  agrega el @action 8 y 9 línea 1485 - 1494'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAInsertChat]
@action int,
@inboundId smallint = 0,
@idArea INT = NULL,
@domain varchar(50) = '''',
@session varchar(50) = '''',
@tTimeout smallint = 0,
@chatId int = 0,
@status tinyInt = 0,
@userId smallint = 0,
@finished tinyInt = 0,
@chattingTime int = 0,
@startTime datetime = null,
@clientName varchar(50) = '''',
@firstMessage int = 0,
@firstMessageTime datetime = null,
@crmNode xml = null,
@supervisor varchar(100) =null,
@template varchar (100)= null,
@ScoreTemplate int = NULL,
@causeFinishedId INT = NULL
AS

declare @xml xml
declare @sql nvarchar(2000)

if @action = 1 begin -- Inserta nuevo chat request /*comentario: se recomienda hacer la busqueda del userid del CRM en esta action*/
       insert into ccRIAChats (domain,session,chatStatus,requestDate,inboundId,clientName)
       values(@domain,@session,@status,getDate(),0,@clientName)
       set @chatId = scope_identity()
       select @chatId
end

else if @action = 2 begin -- Save Initial Info
update ccRIAChats set inboundId = @inboundId, chatStatus = @status, userId = case when @userId = 0 then userId else @userId end, tTimeout = @tTimeout where chatId = @chatId
end

else if @action = 3 begin -- Update Status
update ccRIAChats set chatStatus = @status where chatId = @chatId
end

else if @action = 4 begin -- Save Final Status
if @firstMessage = 0
       begin
             update ccRIAChats set finishedBy = @finished, userID =case when @userId = 0 then userId else @userId end where chatId = @chatId
       end
else
       begin
             update ccRIAChats set finishedBy = @finished, firstMessageTime  = @firstMessageTime where chatId = @chatId
       end
end

else if @action in (5,6) begin -- Save Chatting Time /*comentario: la insercion del nodo (registro final para el finder) se recomiendo en esta action, no olvidar validar status = 4, finishedby != null y validar los tiempos para garantizar el dato final */
       if @action = 5 begin
             update ccRIAChats set tChatting = @chattingTime, userId = case when @userId = 0 then userId else @userId END WHERE chatId = @chatId
       end

       if @action = 6 begin
            update ccRIAChats set userId = case when @userId = 0 then userId else @userId end  where chatId = @chatId
       end
       
       exec ccsp_CreateNodeMultimedia @conversationId=@chatId, @type=1,@supervisor=@supervisor,@template =@template,@ScoreTemplate=@ScoreTemplate
      
end
else if(@action = 7) -- Se añadio al cambio
begin 
    if @chatId > 0
    begin
        UPDATE dbo.ccRIAChats SET chatDate = GETDATE() WHERE chatId = @chatId
    end
END
ELSE if(@action = 8) -- Se añadio al cambio
BEGIN 
    UPDATE dbo.ccRIAChats SET causeFinishedId = @causeFinishedId  WHERE chatId = @chatId
END
ELSE IF(@action = 9) -- Se realiza para consultar la configuracón de areas
BEGIN
    SELECT crca.callWhileChat, crca.callWhileEmail, crca.CallWhileWhatsAppIn, crca.CallWhileWhatsAppOut FROM dbo.ccRIACampEspWG AS crcew INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg 
    ON crawg.IDWG = crcew.IDWG INNER JOIN dbo.ccRIACat_Areas AS crca ON crca.IDArea = crawg.IDArea
    WHERE crcew.Tipo = 1 AND crcew.IdCampEsp = @inboundId GROUP by crca.IDArea, crca.callWhileChat, crca.callWhileEmail, crca.CallWhileWhatsAppIn, crca.CallWhileWhatsAppOut;
END'
EXEC(@sql)


SET @process = 'K064019-Estados canal WhatsApp salida Se elimina SP ccsp_GalateaAreas'
SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAreas'')
			begin
				DROP PROCEDURE ccsp_GalateaAreas;
			end'
EXEC(@sql)

SET @process = 'K064019-Estados canal WhatsApp salida se agrega el @option 6 y 7 línea 1809 - 1831'
SET @sql = 'CREATE procedure [dbo].[ccsp_GalateaAreas] 
        @option int = 2,
        @IDArea smallint = 0,
        @Descripcion varchar(40) = NULL,
        @maxMails smallint = 3,
        @maxChats smallint = 3,
        @maxTweets smallint = 3,
        @maxWhats smallint = 3,
        @maxWhatsOut smallint = 3,
        @callWhileChat bit = 0,
        @callWhileEmail bit = 0,
        @callWhileTwitter bit = 0,
        @CallWhileWhatsAppIn bit = 0,
        @CallWhileWhatsAppOut bit = 0,
        @defCampaing smallint = 0,
        @movesfromArea bit = 0,
        @userId int = NULL,
        @groupAreas varchar (MAX) = NULL,
        @toolsTransfer tinyint = NULL 
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
                a.callWhileChat callChat,
                a.callWhileEmail callEmail,
                a.CallWhileWhatsAppIn callWhatsIn,
                a.CallWhileWhatsAppOut callWhatsOut,
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
                maxWhats tinyint ,
                maxWhatsOut tinyint ,
                callWhileChat bit, 
                callWhileEmail bit,
                CallWhileWhatsAppIn bit,
                CallWhileWhatsAppOut bit,
                users int,
                admins int,
                camps int,
                acds int,
                maxTweets tinyint,
                toolsTransfer tinyint
            )
            insert into #Areas
            EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@maxWhats=@maxWhats,@maxWhatsOut=@maxWhatsOut,@callWhileChat=@callWhileChat,@callWhileEmail=@callWhileEmail,@callWhileWhatsAppIn=@callWhileWhatsAppIn,@callWhileWhatsAppOut=@callWhileWhatsAppOut,@defCampaing=@defCampaing, @isKolob=1
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
                @maxWhats=@maxWhats,
                @maxWhatsOut=@maxWhatsOut,
                @callWhileChat=@callWhileChat,
                @callWhileEmail=@callWhileEmail,
                @callWhileWhatsAppIn=@callWhileWhatsAppIn,
                @callWhileWhatsAppOut=@callWhileWhatsAppOut,
                @defCampaing=@defCampaing,
                @toolsTransfer=@toolsTransfer
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

                    update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),maxWhats=isnull(@maxWhats,maxWhats),maxWhatsOut=isnull(@maxWhatsOut,maxWhatsOut),callWhileChat=isnull(@callWhileChat,callWhileChat),callWhileEmail=isnull(@callWhileEmail,callWhileEmail),callWhileWhatsAppIn=isnull(@callWhileWhatsAppIn,callWhileWhatsAppIn),callWhileWhatsAppOut=isnull(@callWhileWhatsAppOut,callWhileWhatsAppOut),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=case when @toolsTransfer = 3 then ToolsTransfer else @toolsTransfer end where IDArea=@IDArea

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
                                when at.identifierInfo = ''T&SET_CALL_WHILE_CHAT'' then 
                                    case 
                                        when @callWhileChat = 1 then ''COMMON_ENABLED''
                                        else ''COMMON_DISABLED'' end
                                when at.identifierInfo = ''T&SET_CALL_WHILE_EMAIL'' then 
                                    case 
                                        when @callWhileEmail = 1 then ''COMMON_ENABLED''
                                            else ''COMMON_DISABLED'' end
                when at.identifierInfo = ''T&SET_CALL_WHILE_WHATSAPP_IN'' then 
                        case 
                        when @CallWhileWhatsAppIn = 1 then ''COMMON_ENABLED''
                            else ''COMMON_DISABLED'' end
                when at.identifierInfo = ''T&SET_CALL_WHILE_WHATSAPP_OUT'' then 
                    case 
                    when @CallWhileWhatsAppOut= 1 then ''COMMON_ENABLED''
                        else ''COMMON_DISABLED'' end

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
        END
        IF @option = 6 -- get configAreaMultimedia by userId
        BEGIN
            SELECT 
            crca.callWhileChat
            , crca.callWhileEmail
            , crca.CallWhileWhatsAppIn
            , crca.CallWhileWhatsAppOut
            FROM  
            dbo.ccRIAWorkGroupUsers AS crwgu INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg 
            ON crawg.IDWG = crwgu.IDWG INNER JOIN dbo.ccRIACat_Areas AS crca 
            ON crca.IDArea = crawg.IDArea WHERE crwgu.User_id = @userId 
            GROUP BY crca.IDArea, crca.callWhileChat, crca.callWhileEmail, crca.CallWhileWhatsAppIn, crca.CallWhileWhatsAppOut

            RETURN (0)
        END
        IF(@option = 7) -- get area campaign relation by areaId
        BEGIN
            SELECT crcew.IdCampEsp, crawg.IDArea FROM dbo.ccRIACampEspWG AS crcew 
                                    INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg
                                    ON crawg.IDWG = crcew.IDWG
                                    WHERE crcew.Tipo = 1 AND crawg.IDArea = @idArea
            RETURN (0)
        END
        
        
    SET NOCOUNT ON;'
    EXEC(@sql)

    SET @process = 'K064019-Estados canal WhatsApp salida Se elimina SP ccsp_ConversationWASave'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ConversationWASave'')
				begin
					DROP PROCEDURE ccsp_ConversationWASave;
				end'
	EXEC(@sql)

	SET @process = 'K064019-Estados canal WhatsApp salida se modifica el @action = 12 se agrega el conversationStatus 19 en el not in, en la línea 2166 '
	SET @sql = ' CREATE PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
        , @conversationId     INT         = 0
        , @inboundId          SMALLINT    = NULL
        , @phoneACD           VARCHAR(50) = NULL
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
        AS
        BEGIN
            DECLARE @isEndConversation BIT;
            DECLARE @meanContactTypeId SMALLINT;
            DECLARE @conversationIdNew INT;
            SET @meanContactTypeId = 1;
            SET NOCOUNT ON;

            IF @action = 1
            BEGIN --new Conversation
                IF NOT EXISTS
        (SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock)
                                WHERE A.conversationId = @conversationId
                                )
                BEGIN
                    INSERT INTO [ccWhatsAppConversations]
                    (inboundId
                    , phoneACD
                    , clientId
                    , conversationStatus
                    , tChatting
                    , tWrapUp
                    , finishedBy
                    , onQueue
                    , tQueue
                    , tTimeout
                    , disposition
                    , subDisposition
                    , agentId
                    )
                    VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

                    IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId) BEGIN
                        SELECT @conversationId = SCOPE_IDENTITY();
                        SELECT @conversationId AS ConversationId;
                    END
                    ELSE BEGIN

                        declare @conversationIdTemporal     INT;
                        SELECT @conversationIdTemporal = SCOPE_IDENTITY();
                        EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
                        SELECT 0 AS ConversationId;
                    END;

                    --Save new request
                    IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
                        BEGIN
                            INSERT INTO ccWAOperatingSummary (InboundId, Request) VALUES (@inboundId, 1);
                        END
                    ELSE
                        BEGIN
                            UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
                        END
                    RETURN(0);
                END
                ELSE
                BEGIN
                    DECLARE @conversationStatusTemp INT = @conversationStatus;
                    IF @conversationStatus in(17,18) BEGIN
                        SET @conversationStatusTemp = 1
                    END

                    DECLARE @RequestDate DATETIME = NULL;
                    SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversations WITH(NOLOCK) WHERE conversationId = @conversationId;

                        INSERT INTO [ccWhatsAppConversations]
                    (inboundId
                    , phoneACD
                    , clientId
                    , conversationStatus
                    , tChatting
                    , tWrapUp
                    , finishedBy
                    , onQueue
                    , tQueue
                    , tTimeout
                    , disposition
                    , subDisposition
                    , agentId
                    , requestDate
                    )
                    VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
                    SELECT @conversationIdNew = SCOPE_IDENTITY();

                    INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
                                                                        , conversationIdAfter)
                        VALUES (@conversationId, @conversationIdNew);
                    --Save new request by reassign
        UPDATE ccWAOperatingSummary SET Request = (Request + 1), Assigned = (Assigned - 1),EndedBySystem=EndedBySystem+1
        WHERE InboundId = @inboundId

                EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

        SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship with(nolock) where conversationIdBefore = @conversationId;
                RETURN(0);
            END;
        END;

        ELSE IF @action = 2
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

            UPDATE ccWhatsAppConversations
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
                exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

            IF @conversationStatus in(4,10,11,13,17,18) BEGIN
                    DECLARE @conversationDateTemp INT;
                    select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
                    from ccWhatsAppConversations with(nolock) where conversationId = @conversationId;

                    IF @conversationStatus = 13 BEGIN
                        IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
                            INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
                        END
                    END
                    ELSE IF @conversationStatus in(4,10,17,18) BEGIN --Save conversation Ended by system
                        IF @conversationDateTemp > 0 BEGIN
                            UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
                        END
                        ELSE BEGIN
                                UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1) WHERE InboundId = @inboundId
                        END
                    END
                    ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
                        UPDATE ccWAOperatingSummary SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
                    END
                END
                update @TablaTemp set status=1 where conversationId=@conversationIdTemp
            END

        END;

        ELSE IF @action = 3
        BEGIN --save conversation Status
        UPDATE ccWhatsAppConversations SET conversationStatus = @conversationStatus
            WHERE conversationId = @conversationId;
        END;

        ELSE IF @action = 4 BEGIN --save messages from conversation
        IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock) WHERE A.conversationId=@conversationId)
                AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
            BEGIN
                IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
                    (SELECT messageIdUi
                        FROM ccWAMessagesConversations
                        WHERE originType IN (''Agent'', ''Admin'')
                        AND conversationId = @conversationId)
                    BEGIN
                        UPDATE ccWhatsAppConversations
                            SET FirstMessageAgent = @timeStampMessage
                            WHERE conversationId = @conversationId;
                    END

                INSERT INTO [ccWAMessagesConversations](
                                                    messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
                                                    (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
                SELECT @messageId=SCOPE_IDENTITY()
                SELECT @messageId as MessageId
                RETURN (0)
            END
            ELSE BEGIN
                SELECT 0 AS MessageId
                RETURN (0)
            END
        END;

            IF @action = 5
            BEGIN --save onQueue
                UPDATE ccWhatsAppConversations
                        SET onQueue = 1,
                        conversationStatus = @conversationStatus
                WHERE conversationId = @conversationId;
        SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
                UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
            END;

        ELSE IF @action = 6
        BEGIN --save agent, assigdate and tqueue
            declare @agentIdTmp int
            SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A with(nolock) where A.conversationId = @conversationId

            IF (@agentIdTmp is null or @agentIdTmp=0)
            BEGIN
                UPDATE ccWhatsAppConversations
                        SET agentId = @agentId,
                        assignDate = getdate(),
                        conversationStatus = @conversationStatus
                        ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
                WHERE conversationId = @conversationId;

                SELECT @conversationId as conversationId
        SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
        declare @onQueueInt int

            IF @onQueue = 1 BEGIN
                UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1),@onQueueInt =OnQueue WHERE InboundId = @inboundId
                if @onQueueInt<=0 or exists(select * from ccWAOperatingSummary WHERE InboundId = @inboundId and OnQueue<0)begin

                    select          
                    @onQueueInt=count(case when onQueue =1 then 1 end)
                    from ccWhatsAppConversations with(nolock)
                    where inboundId= @inboundId
                    and requestDate>=convert(date,getdate(),121)

                    UPDATE ccWAOperatingSummary SET OnQueue = @onQueueInt WHERE InboundId = @inboundId

                end

            END
            END
        END;

        ELSE IF @action = 7
            BEGIN --update price message
                UPDATE ccWAMessagesConversations
                        SET price = @price,
                            currency = @currency
                WHERE messageId = @messageId;
            END;

        ELSE IF @action = 8
            BEGIN --update status message
                IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
                    UPDATE ccWAMessagesConversations
                            SET messageStatus = @messageStatus
                    WHERE messageId = @messageId;
                END;
            END;

        ELSE IF @action = 9
            BEGIN --Save last message time by conversationID
                IF not exists(SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) BEGIN
                    INSERT INTO ccLastMessageAgentByConversation (conversationId,timeStampLastMessageAgent) VALUES (@conversationId,getDate())
                END;
                ELSE
                    BEGIN
                        UPDATE ccLastMessageAgentByConversation
                            SET timeStampLastMessageAgent = getDate()
                        WHERE conversationId = @conversationId;
                    END;
            END;

        ELSE IF @action = 10
            BEGIN --drop and insert register by conversationID
                DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
            END;

        ELSE IF @action = 11
            BEGIN --register desconnection agent by conversationID
                UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
            END;

        ELSE IF @action = 12
            BEGIN --Obtain conversationsWA post MCS reset

                declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
                UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

                declare @from as datetime;-- = ''01-07-2022'';
                select @from = convert(datetime,convert(varchar(11),getdate()))
                set @from=DATEADD(dd,-1,@from);
                    select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
                    ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
                    from ccWhatsAppConversations A with(nolock)
                    left join ccWAMessagesConversations B on A.conversationId = B.conversationId
                    left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp
                    where A.requestDate >= @from 
                        and A.conversationStatus not in (4, 10, 11, 13, 17, 18, 19)
                    order by agentId desc, requestDate,timeStampMessage, inboundId, clientId 
            END;
        ELSE IF @action = 13
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
                    Inner join contactMeanIn C
                    ON A.idCampEsp = C.inboundId
                    where A.IDWG = 1 and A.Tipo = 0
                    AND C.meanContactTypeId = 5
                )

                select DISTINCT A.User_Id from agents A
                left join usersByCampigns B on A.User_Id = B.User_Id
            END;

        ELSE IF @action = 14
            BEGIN --register desconnection MCS
                INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
            END;

        ELSE IF @action = 15
            BEGIN --update content message
                IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
                    UPDATE ccWAMessagesConversations
                            SET content = @content
                    WHERE messageId = @messageId;
                END;
            END;

        ELSE IF @action = 16
            BEGIN --update agent status for reassigning error message
                    UPDATE ccWhatsAppConversations
                    SET IsAgentLoggingOut = @IsAgentLoggingOut
                    WHERE conversationId = @conversationId;
            END;

        ELSE IF @action = 18 BEGIN
                DECLARE @dateNow DATETIME;
                SET @dateNow = DATEADD(HOUR, -23, GETDATE());

                UPDATE ccWhatsAppConversations
                SET finishedBy = 2, conversationStatus=17
                WHERE finishedBy = 0 AND requestDate <= @dateNow    
            END;
        END;'
        EXEC(@sql)
------------------------------------------------- END Marco García ------------------------------------------------------------------------------------------------

------------------------------------------------- Start MACL ------------------------------------------------------------------------------------------------
	SET @process = 'K020156-Se agrega opcion 9'
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformationOut]
    @Option SMALLINT,
    @camId SMALLINT = 0,
    @ConversationId INT = 0,
    @AgentsAvailables INT = 0,
    @IncreaseDecreaseAgent BIT = NULL,
	@AdminId int = 0

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
    select @nIdioma = case valor 
        when 0 then ''Sin calificación'' 
        when 2 then ''Sem classificação''
        else ''No disposition'' end
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

        SELECT
            COUNT(CASE WHEN cco.conversationStatus NOT IN (10,11,17,18) THEN 1 ELSE NULL END) Active,
            COUNT(CASE WHEN conversationStatus = 1 THEN 1 ELSE null END) Queued,
            COUNT(CASE WHEN conversationStatus = 11 THEN 1 ELSE null END) FinishedAgent,
            COUNT(CASE WHEN conversationStatus = 10 THEN 1 ELSE null END) FinishedSystem
        FROM ccWhatsAppConversationsOut cco WITH(NOLOCK)
        WHERE cco.camId = @camId AND CAST(cco.conversationDate AS DATE) = @ActualDay
    END
	IF @Option = 9
	BEGIN
		DECLARE @campsIds TABLE(camid smallint)
		INSERT INTO @campsIds
		exec ccsp_GalateaAdminCampaigns @Option = 11, @CampType = 1, @AdminId = @AdminId, @IsWhatsAppCampaign=1


		SELECT 
			waco.camid,
			SUM(CASE WHEN messageStatus = ''sent'' OR messageStatus = ''submitted'' THEN 1 ELSE 0 END) AS SentMsg,
			SUM(CASE WHEN messageStatus = ''delivered'' THEN 1 ELSE 0 END) AS Delivered,
			SUM(CASE WHEN messageStatus = ''read'' THEN 1 ELSE 0 END) AS ReadMsg,
			SUM(CASE WHEN messageStatus = ''rejected'' OR messageStatus = ''failed'' THEN 1 ELSE 0 END) AS [NotDelivered],
			SUM(CASE WHEN messageStatus = ''N/A'' THEN 1 ELSE 0 END) AS NA
		FROM 
			ccWhatsAppConversationsOut waco
			INNER JOIN @campsIds c on c.camid = waco.camId 
			INNER JOIN ccWAMessagesConversationsOut wamco
			ON waco.conversationId = wamco.conversationId
			WHERE wamco.timeStampMessage > @Today
			AND wamco.originType <> ''Client''
		GROUP BY 
			waco.camid
		ORDER BY 
			waco.camid;
	END
        
    SET NOCOUNT OFF
    '
	EXEC(@sql)

	SET @process = 'K020139-Se agrega columna para saber si la conversacion ya fue asignada'
	SET @sql = 'IF NOT EXISTS (
	  SELECT * 
	  FROM   sys.columns 
	  WHERE  object_id = OBJECT_ID(N''[dbo].[ccowhatslogdials]'') 
			 AND name = ''ASSIGNED''
	)
	BEGIN
		ALTER TABLE ccowhatslogdials ADD
		ASSIGNED BIT DEFAULT 0;
	END'
	EXEC(@sql)

	SET @process = 'K020139- Se modifica para obtener la columna AssignSameAgent'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_Multimedia2] @action INT, @inboundId INT = NULL, @userId INT = NULL
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
END
	'
	EXEC(@sql)

	SET @process = 'K020139 - se elimina el sp si existe'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_WAGetPreviousAgentToReassign'')
				begin
					DROP PROCEDURE ccsp_WAGetPreviousAgentToReassign;
				end'
	EXEC(@sql)

	SET @process = 'K020139- se crea sp para obtener el ultimo agente que atendio al cliente'
	SET @sql = 'CREATE PROCEDURE ccsp_WAGetPreviousAgentToReassign
 @Action int, @CamId int, @ClientId VARCHAR(20)
 AS
 BEGIN
 SET NOCOUNT ON;

	IF @Action = 1
	BEGIN
		DECLARE @InitialTime DATETIME;
		DECLARE @PreviousAgentID int = 0;
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
	
 END'
	EXEC(@sql)



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
