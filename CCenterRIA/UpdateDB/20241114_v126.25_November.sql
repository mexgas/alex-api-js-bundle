/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: David Medina Medina
Date: 2024/09/30
Description: Release 126.20240930.0.0
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
SET @versionfix = 25
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

	------------------------------------------- BEGIN Ivan Martin K066004 y K066004----------------------------------------
	SET @process = 'K066004 y K066015 Se inserta nuevo status para preasignación de conversaciones'
	SET @sql = '
	IF NOT EXISTS (
		SELECT 1 
		FROM messageStatus 
		WHERE name = ''Preassigned''
	)
	BEGIN
		INSERT INTO messageStatus (name, description, isFinished)
		VALUES (''Preassigned'', ''Preassigned conversation to agent'', 0);
	END'
	EXEC(@sql)
    ------------------------------------------- END Ivan Martin K066004 y K066004----------------------------------------

------------------------------------------- BEGIN MACL K066012 y K066013----------------------------------------
        

        SET @process = 'Alter Tables ccWhatsAppConversationsOut and ccWhatsAppConversations to add IsTransfered'
        SET @sql = 'IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N''IsTransfered''
          AND Object_ID = Object_ID(N''ccWhatsAppConversationsOut''))
BEGIN
    ALTER TABLE ccWhatsAppConversationsOut ADD IsTransfered BIT
END

IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N''IsTransfered''
          AND Object_ID = Object_ID(N''ccWhatsAppConversations''))
BEGIN
    ALTER TABLE ccWhatsAppConversations ADD IsTransfered BIT
END
'
        EXEC(@sql);

		SET @process = 'Alter SP ccsp_ConversationWASave action 6 to save @IsTransfered
						Change in action 5 to update the current conversations in queue'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
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
, @IsTransfered		  BIT = 0
, @IsReopenedConversation BIT =0
AS
BEGIN
	DECLARE @isEndConversation BIT;
	DECLARE @meanContactTypeId SMALLINT;
	DECLARE @conversationIdNew INT;
	SET @meanContactTypeId = 1;
	SET NOCOUNT ON;

	IF @action = 1
	BEGIN 
		IF NOT EXISTS --new Conversation
		(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock)
												WHERE A.conversationId = @conversationId)
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

			IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId) 
				BEGIN
					SELECT @conversationId = SCOPE_IDENTITY();
					IF @IsReopenedConversation = 1
					BEGIN 
						UPDATE ccwhatsappconversations set assignDate = GETDATE() where conversationid = @conversationId
					END 
					SELECT @conversationId AS ConversationId;
				END

			ELSE 
				BEGIN
					declare @conversationIdTemporal     INT;
					SELECT @conversationIdTemporal = SCOPE_IDENTITY();
					EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
					SELECT 0 AS ConversationId;
				END;

			--Save new request
			IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
				BEGIN
					INSERT INTO ccWAOperatingSummary (InboundId, Request, MarkedAsSpam) VALUES (@inboundId, 1, 0);
				END
			ELSE
				BEGIN
					UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
				END
			RETURN(0);
		END

		ELSE -- Reasign conversation
		BEGIN
			DECLARE @conversationStatusTemp INT = @conversationStatus;
			IF @conversationStatus in(17,18) 
				BEGIN
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

			INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore, conversationIdAfter) VALUES (@conversationId, @conversationIdNew);
			--Save new request by reassign
			UPDATE ccWAOperatingSummary SET Request = (Request + 1), Assigned = (Assigned - 1), EndedBySystem = EndedBySystem + 1
			WHERE InboundId = @inboundId

			EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus
	
			SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship with(nolock) where conversationIdBefore = @conversationId;
			RETURN(0);
		END;
END; -- End Action 1

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

	IF @conversationStatus in(4,10,11,13,17,18) BEGIN -- Ending Cases
			DECLARE @conversationDateTemp INT;
			select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
			from ccWhatsAppConversations with(nolock) where conversationId = @conversationId;


			IF @conversationStatus = 13 BEGIN
				UPDATE ccWAOperatingSummary SET MarkedAsSpam = (MarkedAsSpam + 1) where Inboundid = @inboundId
				IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
					UPDATE ccWAOperatingSummary SET Assigned = (Assigned - 1) where Inboundid = @inboundId;
					INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
				END
			END
			ELSE IF @conversationStatus in(4,10,17,18) 
			BEGIN --Save conversation Ended by system
				IF @conversationDateTemp > 0 
				BEGIN
					UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
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

ELSE IF @action = 5
BEGIN --save onQueue
	UPDATE ccWhatsAppConversations
			SET onQueue = 1,
			conversationStatus = @conversationStatus
	WHERE conversationId = @conversationId;
	SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;

	DECLARE @onQueueConversations INT = (SELECT COUNT(CASE WHEN onQueue = 1 AND finishedBy = 0 AND conversationStatus IN (8,9) THEN 1 END) 
											FROM ccWhatsAppConversations WHERE InboundId = @inboundId)
	UPDATE ccWAOperatingSummary SET OnQueue = @onQueueConversations WHERE InboundId = @inboundId
END;

ELSE IF @action = 6
BEGIN --save agent, assigdate and tqueue
			
		--Assigned a queue conversation
	declare @agentIdTmp int
	DECLARE @inboundIdTmp int
	DECLARE @lastStatus int
	SELECT @agentIdTmp = A.agentId, @inboundIdTmp = A.inboundId, @lastStatus = A.conversationStatus FROM ccWhatsAppConversations A with(nolock) where A.conversationId = @conversationId

	IF(@agentId > 0 and @IsTransfered = 1)
	BEGIN
		UPDATE ccWhatsAppConversations
				SET agentId = @agentId,
				conversationStatus = @conversationStatus,
				IsTransfered = @IsTransfered
		WHERE conversationId = @conversationId;
	END

	IF (@agentIdTmp is null or @agentIdTmp=0)
	BEGIN
		UPDATE ccWhatsAppConversations
				SET agentId = @agentId,
				assignDate = getdate(),
				conversationStatus = @conversationStatus,
				tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end,
				IsTransfered = @IsTransfered
		WHERE conversationId = @conversationId;

		SELECT @conversationId as conversationId
		SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
		declare @onQueueInt int
		UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE Inboundid = @inboundId -- It´s assigned
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
		declare @conversationIds table (conversationId	int primary key,phoneACD varchar(50) not null,clientId	varchar(25) not null)

		insert into @conversationIds
		select A.conversationId,A.phoneACD,A.clientId from ccWhatsAppConversations A with(nolock)
		where A.requestDate >= @from 
		and A.finishedBy=0

		;with conversationRepeat as(
			select max(conversationId) conversationId, phoneACD,clientId from @conversationIds 			
			group by phoneACD,clientId Having count(*)>1
		)
		
		update A set A.finishedBy=2
		from ccWhatsAppConversations A
		inner join conversationRepeat R on A.phoneACD=R.phoneACD and A.clientId=R.clientId
		and A.conversationId<>R.conversationId
		where A.requestDate >= @from 
		and A.finishedBy=0



		select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
		,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
		from ccWhatsAppConversations A with(nolock)
		left join ccWAMessagesConversations B on A.conversationId = B.conversationId
		left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp
		where A.requestDate >= @from 
			and A.conversationStatus not in (4, 10, 11, 13, 17, 18, 19)
			and A.finishedBy=0
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
        EXEC(@sql);

		SET @process = 'Alter SP ccsp_ConversationWASaveOut action 6 to save @IsTransfered
		                Change in action 5 to update the current conversations in queue'
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
, @IsTransfered		  BIT = 0
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

ELSE IF @action = 5
BEGIN --save onQueue
	UPDATE ccWhatsAppConversationsOut
			SET onQueue = 1,
			conversationStatus = @conversationStatus
	WHERE conversationId = @conversationId;
	DECLARE @campaignId INT = (SELECT camId FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId);
	
	DECLARE @onQueueConversations INT = (SELECT COUNT(CASE WHEN onQueue = 1 AND finishedBy = 0 AND conversationStatus IN (8,9) THEN 1 END) 
											FROM ccWhatsAppConversationsOut WHERE camId = @campaignId)
	UPDATE ccWAOperatingSummaryOut SET OnQueue = @onQueueConversations WHERE camId = @campaignId
END;

else IF @action = 6
BEGIN --save agent, assigdate and tqueue
	declare @agentIdTmp int
	SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversationsOut A with(nolock) where A.conversationId = @conversationId
				    
	IF(@agentId > 0 and @IsTransfered = 1)
	BEGIN
		UPDATE ccWhatsAppConversationsOut
				SET agentId = @agentId,
				conversationStatus = @conversationStatus,
				IsTransfered = @IsTransfered
		WHERE conversationId = @conversationId;
	END
	ELSE BEGIN
		UPDATE ccWhatsAppConversationsOut
				SET agentId = @agentId,
				assignDate = getdate(),
				conversationStatus = @conversationStatus,
				tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end,
				IsTransfered = @IsTransfered
		WHERE conversationId = @conversationId;
	END
				        

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
	declare @conversationIds table (conversationId	int primary key,phoneCamp varchar(50) not null,clientId	varchar(25) not null)

	insert into @conversationIds
	select A.conversationId,A.phoneCamp,A.clientId from ccWhatsAppConversationsOut A with(nolock)
	where A.requestDate >= @from 
	and A.finishedBy=0

	;with conversationRepeat as(
		select max(conversationId) conversationId, phoneCamp,clientId from @conversationIds 			
		group by phoneCamp,clientId Having count(*)>1
	)

	update A set A.finishedBy=2
	from ccWhatsAppConversationsOut A
	inner join conversationRepeat R on A.phoneCamp=R.phoneCamp and A.clientId=R.clientId
	and A.conversationId<>R.conversationId
	where A.requestDate >= @from 
	and A.finishedBy=0

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
				                
	IF @messageStatus = ''submitted''
	BEGIN
		UPDATE ccWAConversationsResult 
		SET SentMsg = SentMsg + 1;
	END
	ELSE IF @messageStatus = ''delivered''
	BEGIN
		UPDATE ccWAConversationsResult 
		SET SentMsg = CASE WHEN SentMsg > 0 THEN SentMsg - 1 ELSE SentMsg END,
			Delivered = Delivered + 1;
	END
	ELSE IF @messageStatus = ''read''
	BEGIN
		UPDATE ccWAConversationsResult 
		SET Delivered = CASE WHEN Delivered > 0 THEN Delivered - 1 ELSE Delivered END,
			ReadMsg = ReadMsg + 1;
	END
	ELSE IF @messageStatus = ''rejected'' OR @messageStatus = ''error''
	BEGIN
		UPDATE ccWAConversationsResult 
		SET SentMsg = CASE WHEN SentMsg > 0 THEN SentMsg - 1 ELSE SentMsg END,
			NotDelivered = NotDelivered + 1;
	END
	ELSE IF (@messageStatus = ''N/A'' AND @originType != ''Agent'')
	BEGIN
		UPDATE ccWAConversationsResult 
		SET NotSupported = NotSupported + 1;
	END


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
        EXEC(@sql);

		SET @process = 'Alter SP ccsp_MultimediaCommon Option 2 to get value IsTransfered'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_MultimediaCommon]
@Option AS SMALLINT,
@inboundId AS SMALLINT = 0,
@conversationId AS INT = 0,
@ServiceType AS SMALLINT = 0,
@status as SMALLINT =0,
@messagesList as varchar(max) = '''',
@agentId AS SMALLINT = 0,
@CampType bit =0,
@phoneNumber varchar(30)='''',
@campaignNumber VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
	SET @phoneNumber = NULLIF(@phoneNumber, '''');
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
		SET @phoneNumber = NULLIF(@phoneNumber, '''');
        DECLARE @OldAgentId INT = 0
        DECLARE @OldConversationId INT = 0
		DECLARE @isMeta BIT
		
		select @isMeta = CAST(IsMeta AS BIT) from ccAllWhatsAppNumbers with (nolock) where Number=@phoneNumber
		if @isMeta is null begin
			if exists(select * from ccMetaWhatsAppNumbers with (nolock) where Number=@phoneNumber) begin
				set @isMeta=1
			end
			else begin
				set @isMeta=0
			end
		end

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
				   c.conversationDate AS ConversationDate,
				   @isMeta AS IsMeta,
				  ISNULL(c.IsTransfered, cast(0 as bit)) as IsTransfered
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
				   c.conversationDate AS ConversationDate,
				   ISNULL(c.IsTransfered, cast(0 as bit)) as IsTransfered
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
		SELECT
		*
		FROM dbo.fn_GetMessagesByConversationOrMessageId(@CampType, NULL, @messagesList)
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
	ELSE IF(@Option = 7)
    BEGIN
		IF @CampType = 0 BEGIN
        -- No se sabe si se va a implementar
        SELECT -1
        END 
        ELSE BEGIN
			SELECT CAST(ISNULL(maxLimitQueueConversations,99) AS INT) AS MaxLimitQueueConversations 
            FROM contactMeanOut
            WHERE conexionInfo = @campaignNumber
        END 
    END
END'
        EXEC(@sql);
------------------------------------------- END MACL -------------------------------------------------------------
------------------------------------------- BEGIN MAGV K066005 y K066006-------------------------------------------------------------
	SET @process = 'K066005 y K066006- delete store procedure [ccsp_RIALoadAgents]'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIALoadAgents'')
		BEGIN
			DROP PROCEDURE ccsp_RIALoadAgents
		END'
EXEC(@sql)

SET @process = 'K066005 y K066006 CREATE store procedure [ccsp_RIALoadAgents]
Se agregó el @option = 20 para obtener los agentes por id'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIALoadAgents] @option SMALLINT, @AreaId SMALLINT, @Sup SMALLINT, @UserType SMALLINT, @IDWG SMALLINT = NULL, @IDCampACD VARCHAR(max) = NULL, 
@IDUser VARCHAR(max) = NULL
AS
SET NOCOUNT ON

DECLARE @IDArea INT
DECLARE @loginDays INT

SET @loginDays = 0

IF @option IN (1, 7) --1:Todos los agentes/supervisores | 7:UN solo agente/supervisor
BEGIN
	SELECT User_id, LOGIN, TipoLlamadas, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea, 0) IDArea, Sexo
	FROM ccUsers WITH (READPAST)
	WHERE TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS > 0 AND user_id = CASE @option WHEN 7 THEN isnull(@sup, user_id) ELSE user_id END
	ORDER BY IDArea, Nombres, ApellidoPaterno, User_id

	RETURN (0)
END

IF @option = 2 --Agentes/supervisores de un Area
BEGIN
	SELECT User_id, LOGIN, TipoLlamadas, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea, 0) IDArea, Sexo
	FROM ccusers
	WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
	ORDER BY Sexo, Nombres, ApellidoPaterno, User_id

	RETURN (0)
END

IF @option = 3 --Agentes por Supervisor
BEGIN
	SELECT a3.user_id, a3.LOGIN, a3.TipoLlamadas, a3.Nombres + isnull('' '' + a3.ApellidoPaterno, '''') + isnull('' '' + a3.ApellidoMaterno, '''') name, isnull(a3.IDArea, 0) IDArea, a3.Sexo
	FROM ccsupervisorcam a1
	JOIN cccampsagente a2 ON a1.cam_id = a2.cam_id
	JOIN ccusers a3 ON a2.user_id = a3.user_id
	WHERE a1.tipo = ''1'' AND a1.user_id = @Sup AND a3.TipoUser_id = 1 AND a3.STATUS > 0
	
	UNION
	
	SELECT a3.user_id, a3.LOGIN, a3.TipoLlamadas, a3.Nombres + isnull('' '' + a3.ApellidoPaterno, '''') + isnull('' '' + a3.ApellidoMaterno, '''') name, isnull(a3.IDArea, 0) IDArea, a3.Sexo
	FROM ccsupervisorcam a1
	JOIN ccInboundagentes a2 ON a1.cam_id = a2.Inbound_id
	JOIN ccusers a3 ON a2.user_id = a3.user_id
	WHERE a1.tipo = ''0'' AND a1.user_id = @Sup AND a3.TipoUser_id = 1 AND a3.STATUS > 0
	ORDER BY 5, 4, 1

	RETURN (0)
END

IF @option = 4 --Load All Supervisors
BEGIN
	SELECT User_id, LOGIN, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name
	FROM ccUsers
	WHERE TipoUser_id IN (2, 6) AND STATUS > 0

	RETURN (0)
END

IF @option = 5 --Agentes por Supervisor de sus WG
BEGIN
	SELECT @loginDays = valor
	FROM ccSettings
	WHERE setting_id = 211 --Numero dias que cargara las relaciones

	SELECT @IDArea = IDArea
	FROM ccUsers
	WHERE User_id = @Sup

	SELECT User_id, LOGIN, TipoLlamadas, max(name) name, IDArea, Sexo, IP, sum(sumMultimedia) sumMultimedia
	FROM (
		SELECT DISTINCT A.User_id, A.LOGIN, a.TipoLLamadas, A.Nombres + isnull('' '' + A.ApellidoPaterno, '''') + isnull('' '' + A.ApellidoMaterno, '''') name, isnull(A.IDArea, 0) IDArea, A.Sexo, isnull(C.IP, ''0.0.0.0'') IP, (CASE isnull(E.chat, 0) WHEN 3 THEN POWER(2, 0) WHEN 4 THEN POWER(2, 1) ELSE 0 END) AS sumMultimedia --, E.chat mode,E.Inbound_id
		FROM ccUsers A
		INNER JOIN ccRIAWorkGroupUsers B ON A.User_id = B.User_id
		LEFT JOIN ccPosicion C ON C.user_id = A.User_id
		INNER JOIN ccRIACampEspWG D ON D.IDWG = B.IDWG
		LEFT JOIN ccInbound E ON D.IdCampEsp = E.Inbound_id AND E.IDArea = @IDArea
		WHERE A.TipoUser_id = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays) AND B.IDWG IN (
				SELECT IDWG
				FROM ccRIAWorkGroupUsers
				WHERE user_id = @Sup
				)
		) x
	GROUP BY user_id, LOGIN, TipoLlamadas, IDArea, Sexo, IP

	RETURN (0)
END

IF @option = 6 --Agentes por Supervisor de sus WG
BEGIN
	SELECT DISTINCT a1.user_id, a1.LOGIN, a1.TipoLlamadas, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	FROM ccusers a1
	JOIN ccRIAWorkGroupUsers a2 ON a1.user_id = a2.user_id
	WHERE tipouser_id IN (2, 6) AND IDWG IN (
			SELECT IDWG
			FROM ccRIAWorkGroupUsers
			WHERE user_id = @Sup
			)

	RETURN (0)
END

IF @option IN (8, 9) --8:Agentes de un WG | 9:Supervisores de un WG
BEGIN
	DECLARE @wgUsers AS VARCHAR(500)

	SELECT @wgUsers = coalesce(@wgUsers + '','', '''') + CAST(A.user_id AS VARCHAR(40))
	FROM ccRIAWorkGroupUsers A
	JOIN ccUsers B ON A.user_id = B.user_id
	WHERE IDWG = @IDWG AND TipoUser_id = CASE @option WHEN 8 THEN 1 ELSE 2 END

	SELECT @wgUsers wgUsers

	RETURN (0)
END

IF @option = 10 --Todos los agentes/supervisores
BEGIN
	SELECT User_id, LOGIN, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea, 0) IDArea, Sexo
	FROM ccUsers WITH (READPAST)
	WHERE TipoUser_id IN (/*2,*/ 6) AND STATUS > 0
	ORDER BY LOGIN, IDArea, Nombres, ApellidoPaterno, User_id

	RETURN (0)
END

IF @option = 11 -- Agentes por ACD
BEGIN
	SELECT DISTINCT a1.user_id, a1.LOGIN, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name, a1.Sexo, CAST( a2.prioridad AS tinyint ) AS prioridad, a2.skill
	FROM ccusers a1
	JOIN ccInboundAgentes a2 ON a1.user_id = a2.user_id
	WHERE a1.tipouser_id = 1 AND a2.Inbound_id IN (
			SELECT value
			FROM dbo.fn_RIASplitDelimited(@IDCampACD, '','')
			)

	RETURN (0)
END

IF @option = 12 -- Agentes por Camp
BEGIN
	SELECT DISTINCT a1.user_id, a1.LOGIN, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name, a1.Sexo, a2.prioridad, a2.skill
	FROM ccusers a1
	JOIN ccCampsAgente a2 ON a1.user_id = a2.user_id
	WHERE a1.tipouser_id = 1 AND a2.cam_id IN (
			SELECT value
			FROM dbo.fn_RIASplitDelimited(@IDCampACD, '','')
			)

	RETURN (0)
END

IF @option = 13 -- Sups por ACD
BEGIN
	SELECT DISTINCT a1.user_id, a1.LOGIN, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	FROM ccusers a1
	JOIN ccSupervisorCam a2 ON a1.user_id = a2.user_id
	WHERE a1.tipouser_id & 2 = 2 AND tipo = 0 AND a2.cam_id IN (
			SELECT value
			FROM dbo.fn_RIASplitDelimited(@IDCampACD, '','')
			)

	RETURN (0)
END

IF @option = 14 -- Sups por Camp
BEGIN
	SELECT DISTINCT a1.user_id, a1.LOGIN, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	FROM ccusers a1
	JOIN ccSupervisorCam a2 ON a1.user_id = a2.user_id
	WHERE a1.tipouser_id & 2 = 2 AND tipo = 1 AND a2.cam_id IN (
			SELECT value
			FROM dbo.fn_RIASplitDelimited(@IDCampACD, '','')
			)

	RETURN (0)
END

DECLARE @sxML AS VARCHAR(max), @xml AS XML, @action AS INT

IF @option = 15 -- Info Agentes
BEGIN
	SET @action = @option - 9
	SET @xml = cast(''<?xml version="1.0"?> <AgentData/>'' AS XML)

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT 1 AS tag, NULL AS parent, User_id "Agent!1!id", LOGIN "Agent!1!login", Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') "Agent!1!name", Sexo "Agent!1!gender", isnull(IDArea, 0) "Agent!1!areaID"
					FROM ccUsers WITH (READPAST)
					WHERE TipoUser_id = 1 AND STATUS > 0 AND user_id = @sup
					) AS x
				ORDER BY tag, "Agent!1!areaID", "Agent!1!name", "Agent!1!id"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<AgentData/>'')

	SET @xml.modify(''insert element Workgroups {""} as last into (/AgentData/Agent)[1]'')

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT 1 AS tag, NULL AS parent, W.IDWG "Workgroup!1!id", W.WGName "Workgroup!1!description"
					FROM ccRIACat_WorkGroup W
					JOIN ccRIAWorkGroupUsers U ON W.IDWG = U.IDWG
					WHERE user_id = @sup
					) AS x
				ORDER BY tag, "Workgroup!1!description"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<Workgroups/>'')

	SET @xml.modify(''insert element Campaigns {""} as last into (/AgentData/Agent)[1]'')

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT DISTINCT 1 AS tag, NULL AS parent, a1.cam_id "Campaign!1!id", a1.cam_descripcion "Campaign!1!description", a3.frame "Campaign!1!frame", a1.cam_procesando "Campaign!1!processing"
					FROM ccCamps a1
					JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccCampsAgente a4 ON a1.cam_id = a4.cam_id
					WHERE a3.type_id = 1 AND a4.user_id = @Sup
					) AS x
				ORDER BY tag, "Campaign!1!processing", "Campaign!1!description", "Campaign!1!id"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<Campaigns/>'')

	SET @xml.modify(''insert element ACDs {""} as last into (/AgentData/Agent)[1]'')

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT DISTINCT 1 AS tag, NULL AS parent, a1.inbound_id "ACD!1!id", descripcion "ACD!1!description", frame "ACD!1!frame"
					FROM ccinbound a1
					JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccInboundAgentes a4 ON a1.Inbound_id = a4.Inbound_id
					WHERE a3.type_id = 1 AND a4.user_id = @Sup
					) AS x
				ORDER BY tag, "ACD!1!description", "ACD!1!id"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<ACDs/>'')

	SET @xml.modify(''insert element action {""} as last into (/AgentData)[1]'')
	SET @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/AgentData/action)[1]'')

	SELECT @xML

	RETURN (0)
END

IF @option = 16 -- Info Sups
BEGIN
	SET @action = @option - 9
	SET @xml = cast(''<?xml version="1.0"?> <SuperData/>'' AS XML)

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT 1 AS tag, NULL AS parent, User_id "Super!1!id", LOGIN "Super!1!login", Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') "Super!1!name", Sexo "Super!1!gender", isnull(IDArea, 0) "Super!1!areaID"
					FROM ccUsers WITH (READPAST)
					WHERE TipoUser_id & 2 = 2 AND STATUS > 0 AND user_id = @sup
					) AS x
				ORDER BY tag, "Super!1!areaID", "Super!1!name", "Super!1!id"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<SuperData/>'')

	SET @xml.modify(''insert element Workgroups {""} as last into (/SuperData/Super)[1]'')

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT 1 AS tag, NULL AS parent, W.IDWG "Workgroup!1!id", W.WGName "Workgroup!1!description"
					FROM ccRIACat_WorkGroup W
					JOIN ccRIAWorkGroupUsers U ON W.IDWG = U.IDWG
					WHERE user_id = @sup
					) AS x
				ORDER BY tag, "Workgroup!1!description"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<Workgroups/>'')

	SET @xml.modify(''insert element Campaigns {""} as last into (/SuperData/Super)[1]'')

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT DISTINCT 1 AS tag, NULL AS parent, a1.cam_id "Campaign!1!id", a1.cam_descripcion "Campaign!1!description", a3.frame "Campaign!1!frame", a1.cam_procesando "Campaign!1!processing"
					FROM ccCamps a1
					JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccSupervisorCam a4 ON a1.cam_id = a4.cam_id
					WHERE a3.type_id = 1 AND a4.user_id = @Sup AND a4.tipo = 1
					) AS x
				ORDER BY tag, "Campaign!1!processing", "Campaign!1!description", "Campaign!1!id"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<Campaigns/>'')

	SET @xml.modify(''insert element ACDs {""} as last into (/SuperData/Super)[1]'')

	SELECT @sxML = cast((
				SELECT *
				FROM (
					SELECT DISTINCT 1 AS tag, NULL AS parent, a1.inbound_id "ACD!1!id", descripcion "ACD!1!description", frame "ACD!1!frame"
					FROM ccinbound a1
					JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccSupervisorCam a4 ON a1.inbound_id = a4.cam_id
					WHERE a3.type_id = 1 AND a4.user_id = @Sup AND a4.tipo = 0
					) AS x
				ORDER BY tag, "ACD!1!description", "ACD!1!id"
				FOR XML explicit, type
				) AS VARCHAR(max))

	SELECT @xml = dbo.xmlAppend(@xml, @sxML, ''<ACDs/>'')

	SET @xml.modify(''insert element action {""} as last into (/SuperData)[1]'')
	SET @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/SuperData/action)[1]'')

	SELECT @xML

	RETURN (0)
END

IF @option = 17 -- Load all agents
BEGIN
	SELECT @loginDays = valor
	FROM ccSettings
	WHERE setting_id = 211 --Numero dias que cargara las relaciones

	SELECT DISTINCT user_id, LOGIN, TipoLlamadas, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea, 0) IDArea, Sexo, ''0.0.0.0'' IP, 0 AS flagMine
	INTO #allAgents
	FROM ccusers
	WHERE tipouser_id = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)

	SELECT DISTINCT a1.user_id, a1.LOGIN, a1.TipoLlamadas, a1.Nombres + isnull('' '' + a1.ApellidoPaterno, '''') + isnull('' '' + a1.ApellidoMaterno, '''') name, isnull(a1.IDArea, 0) IDArea, Sexo, isnull(IP, ''0.0.0.0'') IP
	INTO #myAgents
	FROM ccusers a1
	JOIN ccRIAWorkGroupUsers a2 ON a1.user_id = a2.user_id
	LEFT JOIN ccPosicion a3 ON a1.user_id = a3.user_id
	JOIN ccRIACampEspWG a4 ON a2.idwg = a4.idwg
	WHERE a1.tipouser_id = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays) AND a2.IDWG IN (
			SELECT IDWG
			FROM ccRIAWorkGroupUsers
			WHERE user_id = @Sup
			)

	UPDATE #allAgents
	SET flagMine = 1
	FROM #allAgents a, #myAgents b
	WHERE a.user_id = b.user_id

	SELECT *
	FROM #allAgents

	DROP TABLE #allAgents

	DROP TABLE #myAgents

	RETURN (0)
END

IF @option = 18 -- View Agents
BEGIN
	SELECT isnull(viewAgents, 0) AS viewAgents
	FROM ccusers
	WHERE tipouser_id = 2 AND user_id = @Sup

	RETURN (0)
END
IF @option = 19 -- Load Just One Supervisor
BEGIN
    SELECT User_id, Login, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') name
    FROM ccUsers
    WHERE TipoUser_id IN (2, 6) AND STATUS > 0 AND User_id = @Sup

    RETURN (0)
END
IF @option = 20 -- Load Agents by user id
BEGIN
	SELECT User_id AS Id, LOGIN AS Login, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') Name
	FROM ccUsers WITH (READPAST)
	WHERE  User_id IN (
			SELECT value
			FROM dbo.fn_RIASplitDelimited(@IDUser, '','')
			)
	ORDER BY LOGIN, Nombres, ApellidoPaterno, User_id

END

SET NOCOUNT OFF'
EXEC(@sql)

SET @process = 'K066005 y K066006 column descripcion alter to varchar(50)'
SET @sql = '
    if EXISTS(select column_name from information_schema.columns  where table_name = ''ccTipoStatusAgente'' AND column_name = ''descripcion'')
    BEGIN
		ALTER TABLE dbo.ccTipoStatusAgente ALTER COLUMN descripcion VARCHAR(50)
    END'
EXEC(@sql)

SET @process = 'K066005 y K066006 - Add Transfer Agent Unified Media to ccTipoStatusAgente table'
SET @sql = '
    declare  @language int;
    select @language = valor from ccSettings where setting_id = 27; 
    declare @descripTransferUnifiedMedia varchar(200);
    if @language = 2 begin
        set @descripTransferUnifiedMedia=''Transferência de agente de mídia unificada''
    end
    else if @language = 0 begin
        set @descripTransferUnifiedMedia=''Transferencia Agente Medios Unificados''
    end
    else begin
        set @descripTransferUnifiedMedia=''Transfer Agent Unified Media''
    end 

    if not exists (select 1 from ccTipoStatusAgente where TipoStatusAge_id = 39)
    begin
        insert into ccTipoStatusAgente values (39, @descripTransferUnifiedMedia)
    end
'

EXEC(@sql)

------------------------------------------- END MAGV -------------------------------------------------------------
------------------------------------------- BEGIN ISAAC CORTES -------------------------------------------------------------	
SET @process = 'K066000 delete sp ccsp_WhatsAppConversationHistory'
SET @sql = '
IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_WhatsAppConversationHistory'')
BEGIN
	DROP PROCEDURE ccsp_WhatsAppConversationHistory
END'
EXEC(@sql)

SET @process = 'K066000 delete sp ccsp_WhatsAppConversationHistory'
SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_WhatsAppConversationHistory]
    @Option smallint = null,
    @agentId smallint = null,
    @From datetime = null,
    @To datetime = null,
    @InboundIdsLst varchar(max) = null,
    @OutboundIdsLst varchar(max) = null,
    @ClientNumbersLst varchar(max) = null,   
    @MaxConversationHistory smallint = null,
    @ConversationIndex smallint = null,
    @ConversationId int = null,
    @ConversationIds  varchar(max) = null,
    @CamType bit = null,
    @CamId int = null,
    @ActualTime dateTime = null,
    @CamNumber varchar(max) = null,
    @ClientNumber varchar(max) = null,
    @AgentsIdsLst varchar(max) = null,
    @StatusLst varchar(max) = null

AS
BEGIN 
    DECLARE @MaxConversationHistoryTime INT = NULL;   
    DECLARE @MaxDaysPerWAConvo INT = NULL;            
    DECLARE @FinalMaxValue INT = NULL; 
	DECLARE @combinedCampsIn VARCHAR(MAX) = ''''
	DECLARE @combinedCampsOut VARCHAR(MAX) = ''''
	DECLARE @combinedInboundNames VARCHAR(MAX) = ''''
	DECLARE @combinedOutboundNames VARCHAR(MAX) = ''''

IF @Option = 0 -- Obtiene filtros para agente 
BEGIN   
    SELECT 
        @combinedCampsIn = ISNULL(STUFF((
            SELECT '','' + CAST(i.inbound_id AS VARCHAR)
            FROM ccInboundAgentes ia
            INNER JOIN ccInbound i ON ia.inbound_id = i.inbound_id
            WHERE ia.user_id = @agentId AND i.chat = 5
            FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), ''''),
        
        @combinedInboundNames = ISNULL(STUFF((
            SELECT '','' + i.descripcion
            FROM ccInboundAgentes ia
            INNER JOIN ccInbound i ON ia.inbound_id = i.inbound_id
            WHERE ia.user_id = @agentId AND i.chat = 5
            FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), '''');

    SELECT 
        @combinedCampsOut = ISNULL(STUFF((
            SELECT '','' + CAST(c.cam_id AS VARCHAR)
            FROM ccCampsAgente ca
            INNER JOIN ccCamps c ON ca.cam_id = c.cam_id
            WHERE ca.user_id = @agentId AND c.CampType = 5
            FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), ''''),
        
        @combinedOutboundNames = ISNULL(STUFF((
            SELECT '','' + c.cam_descripcion
            FROM ccCampsAgente ca
            INNER JOIN ccCamps c ON ca.cam_id = c.cam_id
            WHERE ca.user_id = @agentId AND c.CampType = 5
            FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, ''''), '''');

    IF @combinedCampsIn IS NOT NULL AND @combinedCampsIn <> ''''
    BEGIN
        IF OBJECT_ID(''tempdb..#TmpInboundIds'') IS NOT NULL DROP TABLE #TmpInboundIds;
        CREATE TABLE #TmpInboundIds (Id INT);
        INSERT INTO #TmpInboundIds (Id)
        SELECT CAST(value AS INT) 
        FROM dbo.fn_RIASplitDelimited(@combinedCampsIn, '','');
        SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
        FROM ccInbound i
        INNER JOIN #TmpInboundIds tmp ON tmp.Id = i.inbound_id;
        IF OBJECT_ID(''tempdb..#TmpInboundIds'') IS NOT NULL DROP TABLE #TmpInboundIds;
    END

    IF @combinedCampsOut IS NOT NULL AND @combinedCampsOut <> ''''
    BEGIN
        IF OBJECT_ID(''tempdb..#TmpOutboundIds'') IS NOT NULL DROP TABLE #TmpOutboundIds;
        CREATE TABLE #TmpOutboundIds (Id INT);
        INSERT INTO #TmpOutboundIds (Id)
        SELECT CAST(value AS INT) 
        FROM dbo.fn_RIASplitDelimited(@combinedCampsOut, '','');
        SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
        FROM contactMeanOut cmo 
        INNER JOIN #TmpOutboundIds tmp ON tmp.Id = cmo.camp_id;
        IF OBJECT_ID(''tempdb..#TmpOutboundIds'') IS NOT NULL DROP TABLE #TmpOutboundIds;
    END

    SET @FinalMaxValue = 
        CASE 
            WHEN @MaxConversationHistoryTime IS NULL THEN ISNULL(@MaxDaysPerWAConvo, 0)
            WHEN @MaxDaysPerWAConvo IS NULL THEN ISNULL(@MaxConversationHistoryTime, 0)
            ELSE CASE 
                WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
                ELSE @MaxDaysPerWAConvo
            END
        END;

    SELECT 
        ISNULL(@combinedCampsIn, '''') AS InboundIdsLst, 
        ISNULL(@combinedInboundNames, '''') AS InboundNamesLst, 
        ISNULL(@combinedCampsOut, '''') AS OutboundIdsLst, 
        ISNULL(@combinedOutboundNames, '''') AS OutboundNamesLst, 
        ISNULL(CAST(@FinalMaxValue AS SMALLINT), 0) AS MaxConversationHistory;
	END 
END

IF @Option = 1 -- Obtiene filtros de campañas para admin
BEGIN
	DECLARE @campsIn VARCHAR(MAX) = ''''
	DECLARE @InboundNames VARCHAR(MAX) = ''''
	DECLARE @OutboundNames VARCHAR(MAX) = ''''
	DECLARE @campsOut VARCHAR(MAX) = ''''

	DECLARE @ClientIds VARCHAR(MAX) = ''''
	DECLARE @count INT
	DECLARE @id INT
	DECLARE @wg INT

	IF OBJECT_ID(''tempdb..#AgentsRelations'') IS NOT NULL 
		DROP TABLE #AgentsRelations;

	SELECT ROW_NUMBER() OVER(ORDER BY idWG ASC) AS Row,
			IDWG, @campsIn AS campsIn, @campsOut AS campsOut, 
			@InboundNames AS InboundNames, @OutboundNames AS OutboundNames
	INTO #AgentsRelations
	FROM ccRIAAreaWorkGroup wg
	WHERE EXISTS (
		SELECT 1 
		FROM ccRIAWorkGroupUsers wgu 
		WHERE wgu.IDWG = wg.IDWG 
			AND wgu.user_id = @agentId
	);

	SELECT @count = COUNT(idWG) FROM #AgentsRelations;
	SET @id = 1;

	WHILE @id <= @count
	BEGIN
		SELECT @wg = idwg FROM #AgentsRelations WHERE Row = @id;

		SET @campsIn = '''';
		SET @campsOut = '''';
		SET @InboundNames = '''';
		SET @OutboundNames = '''';

		SELECT @campsIn = ISNULL(@campsIn + CASE WHEN @campsIn = '''' THEN '''' ELSE '','' END + CONVERT(VARCHAR(12), inbound_id), @campsIn)
		FROM ccInbound i 
		INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = i.Inbound_id
		WHERE wg.IDWG = @wg AND wg.Tipo = 0 and i.chat = 5
		ORDER BY inbound_id;

		SELECT @campsOut = ISNULL(@campsOut + CASE WHEN @campsOut = '''' THEN '''' ELSE '','' END + CONVERT(VARCHAR(12), cam_id), @campsOut)
		FROM ccCamps c 
		INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = c.cam_id
		WHERE wg.IDWG = @wg AND wg.Tipo = 1 and c.CampType = 5
		ORDER BY cam_id;

		SELECT @InboundNames = ISNULL(@InboundNames + CASE WHEN @InboundNames = '''' THEN '''' ELSE '','' END + i.descripcion, @InboundNames)
		FROM ccInbound i
		WHERE i.Inbound_id IN (
			SELECT inbound_id FROM ccInbound 
			INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = i.Inbound_id
			WHERE wg.IDWG = @wg AND wg.Tipo = 0 and i.chat = 5
		)
		ORDER BY i.Inbound_id;

		SELECT @OutboundNames = ISNULL(@OutboundNames + CASE WHEN @OutboundNames = '''' THEN '''' ELSE '','' END + c.cam_descripcion, @OutboundNames)
		FROM ccCamps c
		WHERE c.cam_id IN (
			SELECT cam_id FROM ccCamps 
			INNER JOIN ccRIACampEspWG wg ON wg.IdCampEsp = c.cam_id
			WHERE wg.IDWG = @wg AND wg.Tipo = 1 and c.CampType = 5
		)
		ORDER BY c.cam_id;

		IF @campsIn IS NOT NULL AND @campsIn <> ''''
			SET @combinedCampsIn = ISNULL(@combinedCampsIn + CASE WHEN @combinedCampsIn = '''' THEN '''' ELSE '','' END + @campsIn, @combinedCampsIn);

		IF @campsOut IS NOT NULL AND @campsOut <> ''''
			SET @combinedCampsOut = ISNULL(@combinedCampsOut + CASE WHEN @combinedCampsOut = '''' THEN '''' ELSE '','' END + @campsOut, @combinedCampsOut);

		IF @InboundNames IS NOT NULL AND @InboundNames <> ''''
			SET @combinedInboundNames = ISNULL(@combinedInboundNames + CASE WHEN @combinedInboundNames = '''' THEN '''' ELSE '','' END + @InboundNames, @combinedInboundNames);

		IF @OutboundNames IS NOT NULL AND @OutboundNames <> ''''
			SET @combinedOutboundNames = ISNULL(@combinedOutboundNames + CASE WHEN @combinedOutboundNames = '''' THEN '''' ELSE '','' END + @OutboundNames, @combinedOutboundNames);

		SET @id = @id + 1;
	END

	IF @combinedCampsIn IS NOT NULL AND @combinedCampsIn <> ''''
	BEGIN
		IF OBJECT_ID(''tempdb..#TmpInboundIds2'') IS NOT NULL DROP TABLE #TmpInboundIds2;

		CREATE TABLE #TmpInboundIds2 (Id INT);
		INSERT INTO #TmpInboundIds2 (Id)
		SELECT CAST(value AS INT) 
		FROM fn_RIASplitDelimited(@combinedCampsIn, '','');

		SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
		FROM ccInbound i
		INNER JOIN #TmpInboundIds2 tmp ON tmp.Id = i.Inbound_id;

		IF OBJECT_ID(''tempdb..#TmpInboundIds2'') IS NOT NULL DROP TABLE #TmpInboundIds2;
	END

	IF @combinedCampsOut IS NOT NULL AND @combinedCampsOut <> ''''
	BEGIN
		IF OBJECT_ID(''tempdb..#TmpOutboundIds2'') IS NOT NULL DROP TABLE #TmpOutboundIds2;

		CREATE TABLE #TmpOutboundIds2 (Id INT);
		INSERT INTO #TmpOutboundIds2 (Id)
		SELECT CAST(value AS INT) 
		FROM fn_RIASplitDelimited(@combinedCampsOut, '','');

		SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
		FROM contactMeanOut cmo 
		INNER JOIN #TmpOutboundIds2 tmp ON tmp.Id = cmo.camp_id;

		IF OBJECT_ID(''tempdb..#TmpOutboundIds2'') IS NOT NULL DROP TABLE #TmpOutboundIds2;
	END

	SET @FinalMaxValue = CASE 
		WHEN @MaxConversationHistoryTime IS NULL THEN @MaxDaysPerWAConvo
		WHEN @MaxDaysPerWAConvo IS NULL THEN @MaxConversationHistoryTime
		ELSE CASE 
			WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
			ELSE @MaxDaysPerWAConvo
		END
	END;

	SELECT 
		@combinedCampsIn AS InboundIdsLst, 
		@combinedInboundNames AS InboundNamesLst, 
		@combinedCampsOut AS OutboundIdsLst, 
		@combinedOutboundNames AS OutboundNamesLst, 
		ISNULL(CAST(@FinalMaxValue AS SMALLINT), 0) AS MaxConversationHistory;

	IF OBJECT_ID(''tempdb..#AgentsRelations'') IS NOT NULL 
		DROP TABLE #AgentsRelations;
	END

IF @Option = 2 -- Obtiene agentes tomando en cuenta filtros de Inbound, Outbound, o Client Numbers
BEGIN
    DECLARE @AgentIds VARCHAR(MAX) = '''';
    DECLARE @AgentLogins VARCHAR(MAX) = '''';
    DECLARE @AgentNames VARCHAR(MAX) = '''';
    DECLARE @AgentStatusList VARCHAR(MAX) = '''';
	DECLARE @CampType SMALLINT = 0;
    IF OBJECT_ID(''tempdb..#TmpCampAgentWg'') IS NOT NULL DROP TABLE #TmpCampAgentWg;
    CREATE TABLE #TmpCampAgentWg (Id INT);

    IF @InboundIdsLst IS NOT NULL AND @InboundIdsLst <> ''''
    BEGIN
        INSERT INTO #TmpCampAgentWg (Id)
        SELECT CAST(value AS INT)
        FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
    END

    IF @OutboundIdsLst IS NOT NULL AND @OutboundIdsLst <> ''''
    BEGIN
        INSERT INTO #TmpCampAgentWg (Id)
        SELECT CAST(value AS INT)
        FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
		SET @CampType = 1;
    END

    IF @ClientNumbersLst IS NOT NULL AND @ClientNumbersLst <> ''''
    BEGIN
        INSERT INTO #TmpCampAgentWg (Id)
        SELECT DISTINCT inboundId
        FROM ccWhatsAppConversations
        WHERE clientId IN (SELECT CAST(value AS BIGINT) FROM fn_RIASplitDelimited(@ClientNumbersLst, '',''));

        INSERT INTO #TmpCampAgentWg (Id)
        SELECT DISTINCT camId
        FROM ccWhatsAppConversationsOut
        WHERE clientId IN (SELECT CAST(value AS BIGINT) FROM fn_RIASplitDelimited(@ClientNumbersLst, '',''));
    END

    ;WITH LatestStatus AS (
        SELECT 
            lad.User_id, 
            lad.currentStatus, 
            lad.fecha,
            ROW_NUMBER() OVER (PARTITION BY lad.User_id ORDER BY lad.fecha DESC) AS RowNum
        FROM ccLogAgentesDia lad
    )
    SELECT 
        @AgentIds = ISNULL(@AgentIds + CASE WHEN @AgentIds = '''' THEN '''' ELSE '','' END + CAST(u.User_id AS VARCHAR), ''''),
        @AgentLogins = ISNULL(@AgentLogins + CASE WHEN @AgentLogins = '''' THEN '''' ELSE '','' END + u.Login, ''''),
        @AgentNames = ISNULL(@AgentNames + CASE WHEN @AgentNames = '''' THEN '''' ELSE '','' END + u.Nombres + '' '' + u.ApellidoPaterno + '' '' + ISNULL(u.ApellidoMaterno, ''''), ''''),
        @AgentStatusList = ISNULL(@AgentStatusList + CASE WHEN @AgentStatusList = '''' THEN '''' ELSE '','' END + 
						   ISNULL(CASE WHEN ts.descripcion = ''Disponible'' THEN ''Ready'' ELSE ts.descripcion END, ''Unknown''), '''')
    FROM ccUsers u
    INNER JOIN ccRIAWorkGroupUsers wgu ON u.User_id = wgu.User_id
    INNER JOIN ccRIACampEspWG wg ON wg.IDWG = wgu.IDWG
    LEFT JOIN LatestStatus ls ON u.User_id = ls.User_id AND ls.RowNum = 1
    LEFT JOIN ccTipoStatusAgente ts ON ls.currentStatus = ts.TipoStatusAge_id
    WHERE wg.IdCampEsp IN (SELECT Id FROM #TmpCampAgentWg)
      AND u.TipoUser_id = 1 
	  AND wg.Tipo = @CampType
    GROUP BY u.User_id, u.Login, u.Nombres, u.ApellidoPaterno, u.ApellidoMaterno, ts.descripcion;

    SELECT @AgentIds AS AgentIdsList, @AgentLogins AS AgentLoginsList, @AgentNames AS AgentNamesList, @AgentStatusList AS AgentStatusList;

    IF OBJECT_ID(''tempdb..#TmpCampAgentWg'') IS NOT NULL DROP TABLE #TmpCampAgentWg;
END
DECLARE @PageSize INT = 10;
DECLARE @TotalConversations INT = 0;
DECLARE @Offset INT;

IF @Option = 3 -- Obtiene paginado de conversaciones de acuerdo a filtros seleccionados para agente 
BEGIN 
    DECLARE @ClientNumberTable TABLE (ClientNumber BIGINT);
    DECLARE @InboundIdTable TABLE (InboundId INT);
    DECLARE @OutboundIdTable TABLE (OutboundId INT);
    
    IF @ClientNumbersLst IS NOT NULL AND @ClientNumbersLst <> ''''
    BEGIN
        INSERT INTO @ClientNumberTable (ClientNumber)
        SELECT CAST(value AS BIGINT)
        FROM fn_RIASplitDelimited(@ClientNumbersLst, '','');
    END

    IF @InboundIdsLst IS NOT NULL AND @InboundIdsLst <> ''''
    BEGIN
        INSERT INTO @InboundIdTable (InboundId)
        SELECT CAST(value AS INT)
        FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
    END

    IF @OutboundIdsLst IS NOT NULL AND @OutboundIdsLst <> ''''
    BEGIN
        INSERT INTO @OutboundIdTable (OutboundId)
        SELECT CAST(value AS INT)
        FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
    END

    SELECT 
        @TotalConversations = COUNT(DISTINCT ConversationId)
    FROM (
        SELECT c.ConversationId 
        FROM ccWhatsAppConversations c
		LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
        WHERE c.AgentId = @agentId 
            AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
            AND c.requestDate BETWEEN @From AND @To
			AND m.content IS NOT NULL
            AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
            AND (@InboundIdsLst IS NULL OR c.InboundId IN (SELECT InboundId FROM @InboundIdTable))  
            AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)

        UNION ALL

        SELECT c.ConversationId 
        FROM ccWhatsAppConversationsOut c
		LEFT JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
        WHERE c.AgentId = @agentId 
            AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
            AND c.requestDate BETWEEN @From AND @To
			AND m.content IS NOT NULL
            AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
            AND (@OutboundIdsLst IS NULL OR c.camId IN (SELECT OutboundId FROM @OutboundIdTable))
            AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)
    ) AS AllConversations;

    SET @Offset = (@ConversationIndex - 1); 

    DECLARE @RemainingConversations INT = @TotalConversations - @Offset;
    IF @RemainingConversations < @PageSize
        SET @PageSize = @RemainingConversations;

    IF @Offset >= @TotalConversations
    BEGIN
        SELECT TOP 0
            CAST(0 AS INT) AS ConversationId,
            CAST(0 AS INT) AS CamId,
            '''' AS CamNumber,
            CAST(0 AS SMALLINT) AS Frame,
            '''' AS ClientNumber,
            '''' AS MessageContent,
            '''' AS CamType,
            CAST(GETDATE() AS DATETIME) AS LastMessageDateTime,
            @TotalConversations AS ConversationsCount
        WHERE 1 = 0;
        RETURN;
    END

    ;WITH LatestInboundMessages AS (
        SELECT 
            c.ConversationId,
            c.InboundId AS CampaignId,
            c.phoneACD as CamNumber,
            g.graphic_id AS GraphicId,
            c.clientId AS ClientNumber,
            m.content AS MessageContent,
            m.TimeStampMessage AS LastMessageTimestamp,
            ''Inbound'' AS CampType,
            ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
        FROM ccWhatsAppConversations c
        LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = c.InboundId
        LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
        WHERE c.AgentId = @agentId 
            AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
            AND c.requestDate BETWEEN @From AND @To
			AND m.content IS NOT NULL
            AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
            AND (@InboundIdsLst IS NULL OR c.InboundId IN (SELECT InboundId FROM @InboundIdTable))
            AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)
    ),
    
    LatestOutboundMessages AS (
        SELECT 
            c.ConversationId,
            c.camId AS CampaignId,
            c.phoneCamp AS CamNumber,
            g.graphic_id AS GraphicId,
            c.clientId AS ClientNumber,
            m.content AS MessageContent,
            m.TimeStampMessage AS LastMessageTimestamp,
            ''Outbound'' AS CampType,
            ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
        FROM ccWhatsAppConversationsOut c
        LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
        LEFT JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
        WHERE c.AgentId = @agentId 
            AND (c.conversationDate IS NOT NULL OR c.FirstMessageAgent IS NOT NULL)
            AND c.requestDate BETWEEN @From AND @To
			AND m.content IS NOT NULL
            AND (@ClientNumbersLst IS NULL OR c.clientId IN (SELECT ClientNumber FROM @ClientNumberTable))
            AND (@OutboundIdsLst IS NULL OR c.camId IN (SELECT OutboundId FROM @OutboundIdTable))
            AND c.conversationStatus IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19)
    ),

    CombinedMessages AS (
        SELECT 
            ConversationId,
            CampaignId,
            CamNumber,
            GraphicId,
            ClientNumber,
            MessageContent,
            LastMessageTimestamp,
            CampType
        FROM LatestInboundMessages
        WHERE rn = 1
        
        UNION ALL
        
        SELECT 
            ConversationId,
            CampaignId,
            CamNumber,
            GraphicId,
            ClientNumber,
            MessageContent,
            LastMessageTimestamp,
            CampType
        FROM LatestOutboundMessages
        WHERE rn = 1
    )

    SELECT conversationId as ConversationId,
           CampaignId as CamId,
           CamNumber as CamNumber,
           CAST(GraphicId AS SMALLINT) AS Frame,
           ClientNumber as ClientNumber,
           MessageContent as MessageContent,
           CampType AS CamType,
           LastMessageTimestamp as LastMessageDateTime,
           @TotalConversations AS ConversationsCount
    FROM CombinedMessages
    ORDER BY LastMessageTimestamp DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END;

IF @Option = 4 -- Obtiene paginado de conversaciones de acuerdo a filtros seleccionados para administrador
BEGIN
    -- Drop and recreate temporary tables
    IF OBJECT_ID(''tempdb..#ClientNumberTable'') IS NOT NULL DROP TABLE #ClientNumberTable;
    CREATE TABLE #ClientNumberTable (ClientNumber BIGINT);

    IF OBJECT_ID(''tempdb..#InboundIdTable'') IS NOT NULL DROP TABLE #InboundIdTable;
    CREATE TABLE #InboundIdTable (InboundId INT);

    IF OBJECT_ID(''tempdb..#OutboundIdTable'') IS NOT NULL DROP TABLE #OutboundIdTable;
    CREATE TABLE #OutboundIdTable (OutboundId INT);

    IF OBJECT_ID(''tempdb..#AgentIdTable'') IS NOT NULL DROP TABLE #AgentIdTable;
    CREATE TABLE #AgentIdTable (AgentId INT);

    IF OBJECT_ID(''tempdb..#StatusTable'') IS NOT NULL DROP TABLE #StatusTable;
    CREATE TABLE #StatusTable (StatusCategory VARCHAR(50));

    IF OBJECT_ID(''tempdb..#StatusIdTable'') IS NOT NULL DROP TABLE #StatusIdTable;
    CREATE TABLE #StatusIdTable (StatusId INT);

    DECLARE @IncludeQueued BIT = 0;

    -- Populate temporary tables based on input parameters
    IF ISNULL(@ClientNumbersLst, '''') <> ''''
    BEGIN
        INSERT INTO #ClientNumberTable (ClientNumber)
        SELECT CAST(value AS BIGINT)
        FROM fn_RIASplitDelimited(@ClientNumbersLst, '','');
    END

    IF ISNULL(@InboundIdsLst, '''') <> ''''
    BEGIN
        INSERT INTO #InboundIdTable (InboundId)
        SELECT CAST(value AS INT)
        FROM fn_RIASplitDelimited(@InboundIdsLst, '','');
    END

    IF ISNULL(@OutboundIdsLst, '''') <> ''''
    BEGIN
        INSERT INTO #OutboundIdTable (OutboundId)
        SELECT CAST(value AS INT)
        FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');
    END

    IF ISNULL(@AgentsIdsLst, '''') <> ''''
    BEGIN
        INSERT INTO #AgentIdTable (AgentId)
        SELECT CAST(value AS INT)
        FROM fn_RIASplitDelimited(@AgentsIdsLst, '','');
    END

    IF ISNULL(@StatusLst, '''') <> ''''
    BEGIN
        INSERT INTO #StatusTable (StatusCategory)
        SELECT LTRIM(RTRIM(value))
        FROM fn_RIASplitDelimited(@StatusLst, '','');
    END

    -- Map status categories to internal Status IDs
    INSERT INTO #StatusIdTable (StatusId)
    SELECT StatusId
    FROM (
        SELECT CASE 
            WHEN StatusCategory = ''active'' THEN messageStatusId
            WHEN StatusCategory = ''pre-assigned'' THEN 21
            WHEN StatusCategory = ''finished'' THEN messageStatusId
            ELSE NULL
        END AS StatusId
        FROM messageStatus
        INNER JOIN #StatusTable ON
            (StatusCategory = ''active'' AND messageStatusId IN (1, 2, 3, 5, 7, 8, 9))
            OR (StatusCategory = ''pre-assigned'' AND messageStatusId = 21)
            OR (StatusCategory = ''finished'' AND messageStatusId IN (4, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19))
    ) AS MappedStatus
    WHERE StatusId IS NOT NULL;

    IF EXISTS (SELECT 1 FROM #StatusTable WHERE StatusCategory = ''queued'')
    BEGIN
        SET @IncludeQueued = 1;
    END

    -- Calculate total conversations based on filters for Inbound, Outbound, or Client-only cases

    -- Case 1: Inbound Conversations
	IF @InboundIdsLst IS NOT NULL 
	BEGIN
		WITH ConversationsWithMessages AS (
			-- Retrieve all conversations with messages
			SELECT DISTINCT c.ConversationId
			FROM ccWhatsAppConversations c
			INNER JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
			WHERE c.InboundId IN (SELECT InboundId FROM #InboundIdTable)
				AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
				AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
				AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
				OR (@IncludeQueued = 1 AND c.onQueue = 1))
		),
		LinkedConversations AS (
			-- Include conversations linked to ones with messages
			SELECT DISTINCT r.conversationIdAfter AS ConversationId
			FROM ccWhatsAppConversationsRelationship r
			INNER JOIN ConversationsWithMessages cm ON r.conversationIdBefore = cm.ConversationId
		)
		SELECT 
			@TotalConversations = COUNT(DISTINCT c.ConversationId)
		FROM ccWhatsAppConversations c
		WHERE c.ConversationId IN (
			-- Combine conversations with messages and linked conversations
			SELECT ConversationId FROM ConversationsWithMessages
			UNION
			SELECT ConversationId FROM LinkedConversations
		)
		AND c.InboundId IN (SELECT InboundId FROM #InboundIdTable)
		AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
		AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
		AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
		OR (@IncludeQueued = 1 AND c.onQueue = 1));
	END

    -- Case 2: Outbound Conversations
    ELSE IF @OutboundIdsLst IS NOT NULL
    BEGIN
        SELECT  
            @TotalConversations = COUNT(DISTINCT c.ConversationId)
        FROM ccWhatsAppConversationsOut c
        INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
        WHERE c.camId IN (SELECT OutboundId FROM #OutboundIdTable)
            AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
            AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
            AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
            OR (@IncludeQueued = 1 AND c.onQueue = 1))
    END

    -- Case 3: ClientNumbers only (when both Inbound and Outbound IDs are NULL)
    ELSE IF @ClientNumbersLst IS NOT NULL AND @TotalConversations = 0
    BEGIN
        DECLARE @InboundConversations INT = 0;
        DECLARE @OutboundConversations INT = 0;

        -- Count inbound conversations
        SELECT  
            @InboundConversations = COUNT(DISTINCT whatsIn.ConversationId)
        FROM ccWhatsAppConversations whatsIn
        INNER JOIN ccWAMessagesConversations m ON m.conversationId = whatsIn.ConversationId
        WHERE whatsIn.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
            AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatsIn.AgentId IN (SELECT AgentId FROM #AgentIdTable))
            AND ((ISNULL(@StatusLst, '''') = '''' OR whatsIn.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
            OR (@IncludeQueued = 1 AND whatsIn.onQueue = 1));

        -- Count outbound conversations
        SELECT  
            @OutboundConversations = COUNT(DISTINCT whatOut.ConversationId)
        FROM ccWhatsAppConversationsOut whatOut
        INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = whatOut.ConversationId
        WHERE whatOut.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
            AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatOut.AgentId IN (SELECT AgentId FROM #AgentIdTable))
            AND ((ISNULL(@StatusLst, '''') = '''' OR whatOut.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
            OR (@IncludeQueued = 1 AND whatOut.onQueue = 1));

        -- Sum the inbound and outbound counts
        SET @TotalConversations = @InboundConversations + @OutboundConversations;
    END

    -- Paginate results based on @ConversationIndex
    SET @Offset = ISNULL(@ConversationIndex, 1) - 1;

    IF @ConversationIndex >= @TotalConversations
    BEGIN
        SET @Offset = @TotalConversations - @PageSize;
        IF @Offset < 0 SET @Offset = 0;
    END

	-- Collect unique conversation IDs from Inbound and Outbound messages
    ;WITH ExistingConversations AS (
        SELECT ConversationId FROM ccWhatsAppConversations WHERE InboundId IN (SELECT InboundId FROM #InboundIdTable)
        UNION
        SELECT ConversationId FROM ccWhatsAppConversationsOut WHERE camId IN (SELECT OutboundId FROM #OutboundIdTable)
    ),
	-- Retrieve paginated conversations for Inbound, Outbound, or Client-only case

	LatestInboundMessages AS (
        SELECT 
            c.ConversationId,
            c.InboundId AS CampaignId,
            COALESCE(g.graphic_id, 0) AS GraphicId,
            COALESCE(c.clientId, '''') AS ClientNumber,
            COALESCE(m.content, '''') AS MessageContent,
			COALESCE(m.typeMessage, '''') AS MessageType,
            COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
            COALESCE(u.Login, '''') AS AgentLogin,
            CASE 
                WHEN c.onQueue = 1 AND c.conversationStatus = 8 THEN ''queued''
                WHEN c.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
                WHEN c.conversationStatus = 21 THEN ''pre-assigned''
                ELSE ''finished''
            END AS ConversationStatus,
            ''Inbound'' AS CampType,
            ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
        FROM ccWhatsAppConversations c
        LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
        LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = c.InboundId
        LEFT JOIN ccUsers u ON u.User_id = c.AgentId
        WHERE 
            c.InboundId IN (SELECT InboundId FROM #InboundIdTable)
            AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
            AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
            AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
            OR (@IncludeQueued = 1 AND c.onQueue = 1))
    ),
    
	LatestOutboundMessages AS (
		SELECT 
			c.ConversationId,
			c.camId AS CampaignId,
			COALESCE(g.graphic_id, 0) AS GraphicId,
			COALESCE(c.clientId, '''') AS ClientNumber,
			COALESCE(m.content, '''') AS MessageContent,
			COALESCE(m.typeMessage, '''') AS MessageType,
			COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
			COALESCE(u.Login, '''') AS AgentLogin,
			CASE 
				WHEN c.onQueue = 1 AND c.conversationStatus = 8 THEN ''queued''
				WHEN c.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
				WHEN c.conversationStatus = 21 THEN ''pre-assigned''
				ELSE ''finished''
			END AS ConversationStatus,
			''Outbound'' AS CampType,
			ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
		FROM ccWhatsAppConversationsOut c
		INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
		LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
		LEFT JOIN ccUsers u ON u.User_id = c.AgentId
		WHERE 
			c.camId IN (SELECT OutboundId FROM #OutboundIdTable)
			AND (ISNULL(@ClientNumbersLst, '''') = '''' OR c.clientId IN (SELECT ClientNumber FROM #ClientNumberTable))
			AND (ISNULL(@AgentsIdsLst, '''') = '''' OR c.AgentId IN (SELECT AgentId FROM #AgentIdTable))
			AND ((ISNULL(@StatusLst, '''') = '''' OR c.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
			OR (@IncludeQueued = 1 AND c.onQueue = 1))
	),
    
	ClientOnlyMessages AS (
        -- Exclude conversations that already exist in ExistingConversations
        SELECT 
            whatsIn.ConversationId,
            whatsIn.InboundId AS CampaignId,
            COALESCE(g.graphic_id, 0) AS GraphicId,
            COALESCE(whatsIn.clientId, '''') AS ClientNumber,
            COALESCE(m.content, '''') AS MessageContent,
			COALESCE(m.typeMessage, '''') AS MessageType,
            COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
            COALESCE(u.Login, '''') AS AgentLogin,
            CASE 
                WHEN whatsIn.onQueue = 1 AND whatsIn.conversationStatus = 8 THEN ''queued''
                WHEN whatsIn.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
                WHEN whatsIn.conversationStatus = 21 THEN ''pre-assigned''
                ELSE ''finished''
            END AS ConversationStatus,
            ''Inbound'' AS CampType,
            ROW_NUMBER() OVER (PARTITION BY whatsIn.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
        FROM ccWhatsAppConversations whatsIn
        INNER JOIN ccWAMessagesConversations m ON m.conversationId = whatsIn.ConversationId
        LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = whatsIn.InboundId
        LEFT JOIN ccUsers u ON u.User_id = whatsIn.AgentId
        WHERE 
            whatsIn.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
            AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatsIn.AgentId IN (SELECT AgentId FROM #AgentIdTable))
            AND ((ISNULL(@StatusLst, '''') = '''' OR whatsIn.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
            OR (@IncludeQueued = 1 AND whatsIn.onQueue = 1))
            AND whatsIn.ConversationId NOT IN (SELECT ConversationId FROM ExistingConversations)

        UNION ALL

        SELECT 
            whatOut.ConversationId,
            whatOut.camId AS CampaignId,
            COALESCE(g.graphic_id, 0) AS GraphicId,
            COALESCE(whatOut.clientId, '''') AS ClientNumber,
            COALESCE(m.content, '''') AS MessageContent,
			COALESCE(m.typeMessage, '''') AS MessageType,
            COALESCE(CONVERT(VARCHAR, m.TimeStampMessage, 120), '''') AS LastMessageTimestamp,
            COALESCE(u.Login, '''') AS AgentLogin,
            CASE 
                WHEN whatOut.onQueue = 1 AND whatOut.conversationStatus = 8 THEN ''queued''
                WHEN whatOut.conversationStatus IN (1, 2, 3, 5, 7, 8, 9) THEN ''active''
                WHEN whatOut.conversationStatus = 21 THEN ''pre-assigned''
                ELSE ''finished''
            END AS ConversationStatus,
            ''Outbound'' AS CampType,
            ROW_NUMBER() OVER (PARTITION BY whatOut.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn
        FROM ccWhatsAppConversationsOut whatOut
        INNER JOIN ccWAMessagesConversationsOut m ON m.conversationId = whatOut.ConversationId
        LEFT JOIN ccRIACampsGraph g ON g.cam_id = whatOut.camId
        LEFT JOIN ccUsers u ON u.User_id = whatOut.AgentId
        WHERE 
            whatOut.clientId IN (SELECT ClientNumber FROM #ClientNumberTable)
            AND (ISNULL(@AgentsIdsLst, '''') = '''' OR whatOut.AgentId IN (SELECT AgentId FROM #AgentIdTable))
            AND ((ISNULL(@StatusLst, '''') = '''' OR whatOut.conversationStatus IN (SELECT StatusId FROM #StatusIdTable)) 
            OR (@IncludeQueued = 1 AND whatOut.onQueue = 1))
            AND whatOut.ConversationId NOT IN (SELECT ConversationId FROM ExistingConversations)
    )

    -- Final result
    SELECT 
        CAST(ConversationId AS INT) AS ConversationId,
        CAST(CampaignId AS SMALLINT) AS CamId,
        CAST(GraphicId AS SMALLINT) AS Frame,
        CAST(ClientNumber AS VARCHAR(50)) AS ClientNumber,
        CAST(MessageContent AS VARCHAR(MAX)) AS MessageContent,
		CAST(MessageType AS VARCHAR(MAX)) AS MessageType, 
        CAST(LastMessageTimestamp AS DATETIME) AS LastMessageDateTime,
        CAST(AgentLogin AS VARCHAR(50)) AS AgentLogin,
        CAST(ConversationStatus AS VARCHAR(50)) AS ConversationStatus,
        CAST(CampType AS VARCHAR(50)) AS CamType,
        CAST(@TotalConversations AS INT) AS ConversationsCount
    FROM (
        SELECT * FROM LatestInboundMessages WHERE rn = 1
        UNION ALL
        SELECT * FROM LatestOutboundMessages WHERE rn = 1
        UNION ALL
        SELECT * FROM ClientOnlyMessages WHERE rn = 1
    ) AS CombinedMessages
    ORDER BY ConversationId DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
	
IF @Option = 5 -- Obtiene número máximo de días a buscar por historial cuando se filtra por campañas 
BEGIN 											
    IF OBJECT_ID(''tempdb..#TmpInboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpInboundIdsCampFilter;

    CREATE TABLE #TmpInboundIdsCampFilter (Id INT);

    INSERT INTO #TmpInboundIdsCampFilter (Id)
    SELECT CAST(value AS INT) 
    FROM fn_RIASplitDelimited(@InboundIdsLst, '','');

    SELECT @MaxConversationHistoryTime = MAX(i.ConversationHistoryTime)
    FROM ccInbound i
    INNER JOIN #TmpInboundIdsCampFilter tmp ON tmp.Id = i.Inbound_id;

    IF OBJECT_ID(''tempdb..#TmpInboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpInboundIdsCampFilter;

    IF OBJECT_ID(''tempdb..#TmpOutboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpOutboundIdsCampFilter;

    CREATE TABLE #TmpOutboundIdsCampFilter (Id INT);

    INSERT INTO #TmpOutboundIdsCampFilter (Id)
    SELECT CAST(value AS INT) 
    FROM fn_RIASplitDelimited(@OutboundIdsLst, '','');

    SELECT @MaxDaysPerWAConvo = MAX(cmo.MaxDaysPerWAConvo)
    FROM contactMeanOut cmo 
    INNER JOIN #TmpOutboundIdsCampFilter tmp ON tmp.Id = cmo.camp_id;

    IF OBJECT_ID(''tempdb..#TmpOutboundIdsCampFilter'') IS NOT NULL DROP TABLE #TmpOutboundIdsCampFilter;

    SET @FinalMaxValue = CASE 
        WHEN @MaxConversationHistoryTime IS NULL THEN @MaxDaysPerWAConvo
        WHEN @MaxDaysPerWAConvo IS NULL THEN @MaxConversationHistoryTime
        ELSE CASE 
            WHEN @MaxConversationHistoryTime > @MaxDaysPerWAConvo THEN @MaxConversationHistoryTime
            ELSE @MaxDaysPerWAConvo
        END
    END;

     SELECT CAST(@FinalMaxValue AS SMALLINT) AS MaxConversationHistory;
END;

IF @Option = 6 -- Obtener cabecera de varias conversaciones
BEGIN 
    CREATE TABLE #TmpConversationIds (Id INT);
    INSERT INTO #TmpConversationIds (Id)
    SELECT CAST(value AS INT) 
    FROM fn_RIASplitDelimited(@ConversationIds, '','');

    IF @CamType = 0
    BEGIN 
        SELECT 
            cwc.conversationId AS ConversationId, 
            (CASE WHEN cwc.disposition = 0 THEN ''N/A'' ELSE ctc.Description END) AS Disposition,
            (CASE WHEN cwc.SubDisposition = 0 THEN ''N/A'' ELSE ctcs.califSubDesc END) AS SubDisposition, 
            cwc.inboundId AS CamId, 
            ISNULL(cwc.conversationDate, ''1900-01-01'') AS ConversationDate,
            (CASE 
                WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1)
                    OR cwc.conversationStatus IN (1, 2, 3, 5, 7, 8, 9, 21)
                    OR cwc.tConversation IS NULL THEN 0
                ELSE cwc.tConversation
            END) AS TConversation,
            0 AS CampType,
            ci.descripcion AS CampName,
            cwc.clientId AS PhoneNumber,
            (CASE 
                WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1) 
                    OR cwc.conversationStatus IN (10, 17) 
                    OR cu.User_id IS NULL THEN CONVERT(SMALLINT, 0)
                ELSE cu.User_id
            END) AS AgentId,
            (CASE 
                WHEN (cwc.conversationStatus = 8 AND ISNULL(cwc.onQueue, 1) = 1) 
                    OR cwc.conversationStatus IN (10, 17) 
                    OR cu.User_id IS NULL THEN ''''
                ELSE cu.Nombres
            END) AS AgentName,
            ISNULL(CAST(mwn.Cam_Id AS SMALLINT), 0) AS ReopenWithTemplateOutboundCamId,
            ccc.cam_descripcion AS ReopenWithTemplateOutboundCamName
        FROM ccWhatsAppConversations cwc
        INNER JOIN ccInbound ci ON ci.inbound_id = cwc.inboundId
        LEFT JOIN ccUsers cu ON cu.User_id = cwc.agentId
        INNER JOIN #TmpConversationIds tci ON tci.Id = cwc.conversationId
        LEFT JOIN ccTipoCalif ctc ON ctc.calif_id = cwc.disposition
        LEFT JOIN ccTipoCalifSub ctcs ON ctcs.califSub_id = cwc.subDisposition
        LEFT JOIN ccMetaWhatsAppNumbers mwn ON mwn.Number = cwc.phoneACD
        LEFT JOIN cccamps ccc ON ccc.cam_Id = mwn.Cam_Id 
    END
	ELSE
    BEGIN
        SELECT 
            cwo.conversationId AS ConversationId, 
            (CASE WHEN cwo.disposition = 0 THEN ''N/A'' ELSE ctco.Description END) AS Disposition, 
            (CASE WHEN cwo.SubDisposition = 0 THEN ''N/A'' ELSE ctcso.califSubDesc END) AS SubDisposition,
            cwo.camId AS CamId, 
            ISNULL(cwo.conversationDate, ''1900-01-01'') AS ConversationDate, 
            (CASE 
				WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1)
					OR cwo.conversationStatus IN (1, 2, 3, 5, 7, 8, 9, 21)
					OR cwo.tConversation IS NULL THEN 0
				ELSE cwo.tConversation
			END) AS TConversation,
            1 AS CampType,
            cc.cam_descripcion AS CampName,
            cwo.clientId AS PhoneNumber,
            (CASE 
				WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1) 
					OR cwo.conversationStatus IN (10, 17) 
					OR cu.User_id IS NULL THEN CONVERT(SMALLINT, 0)
				ELSE cu.User_id
			END) AS AgentId,
			(CASE 
				WHEN (cwo.conversationStatus = 8 AND ISNULL(cwo.onQueue, 1) = 1) 
					OR cwo.conversationStatus IN (10, 17) 
					OR cu.User_id IS NULL THEN ''''
				ELSE cu.Nombres
			END) AS AgentName,
			ISNULL(CAST(ccc.Cam_Id AS SMALLINT), 0) AS ReopenWithTemplateOutboundCamId,
            ccc.cam_descripcion AS ReopenWithTemplateOutboundCamName
        FROM ccWhatsAppConversationsOut cwo
        INNER JOIN ccCamps cc ON cc.cam_id = cwo.camId 
        LEFT JOIN ccUsers cu ON cu.User_id = cwo.agentId
        INNER JOIN #TmpConversationIds tci ON tci.Id = cwo.conversationId
        LEFT JOIN ccTipoCalifOUT ctco ON ctco.calif_id = cwo.disposition
        LEFT JOIN ccTipoCalifSubOUT ctcso ON ctcso.califSub_id = cwo.subDisposition
		LEFT JOIN ccMetaWhatsAppNumbers mwn ON mwn.Number = cwo.phoneCamp
		LEFT JOIN ccCamps ccc on ccc.cam_id = mwn.Cam_Id 
    END
END

    DECLARE @MaxWhatsAllowed INT;
    DECLARE @ConversationCount INT;

IF @Option = 8 -- Obtiene valor si se reabrirá o no la conversación y si será se reabrirá tipo entrada o salida
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ccRIAAgentsPermissions WHERE AgentId = @AgentId AND AllowReopenWAConversation = 1)
    BEGIN
        SELECT ''REOPEN_PERMISSION_DISABLED'' AS ReopenConversationResponse;
        RETURN(0);
    END;

    IF @CamType = 0
    BEGIN
        IF EXISTS (SELECT 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent)) 
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM ccmetawhatsAppNumbers WHERE Number = @CamNumber AND Inbound_Id = @CamId)
            BEGIN
                SELECT ''CAMPAIGN_NUMBER_CHANGED'' AS ReopenConversationResponse;
                RETURN(0);
            END

            SELECT @MaxWhatsAllowed = a.maxWhats FROM ccinbound i INNER JOIN ccriacat_Areas a ON i.IDArea = a.IDArea WHERE i.Inbound_Id = @CamId;
			SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversations WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(hour, -48, GETDATE());

			IF @ConversationCount >= @MaxWhatsAllowed
			BEGIN
				SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationResponse;
				RETURN(0);
			END
        END

    END
	ELSE 
    BEGIN
        SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
        RETURN(0);
    END

    IF @CamType = 1
    BEGIN
		IF EXISTS (SELECT 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent)) 
        BEGIN
			IF NOT EXISTS (SELECT 1 FROM ccmetawhatsAppNumbers WHERE Number = @CamNumber AND Inbound_Id = @CamId)
			BEGIN
				SELECT ''CAMPAIGN_NUMBER_CHANGED'' AS ReopenConversationResponse;
				RETURN(0);
			END

			SELECT @MaxWhatsAllowed = a.maxWhatsOut FROM cccamps c INNER JOIN ccriacat_Areas a ON c.IDArea = a.IDArea WHERE c.cam_id = @CamId;
			SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversationsOut WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(hour, -48, GETDATE());

			IF @ConversationCount >= @MaxWhatsAllowed
			BEGIN
				SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationResponse;
				RETURN(0);
			END
		END
    END
	ELSE
	BEGIN
		SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
		RETURN(0);
	END
END

	DECLARE @ConvId int;

IF @Option = 9 -- Verificación al reabrir conversación
BEGIN 
    DECLARE @ConversationWithinWindowTime BIT = 0;
    DECLARE @ReopenConversationButtonResponse VARCHAR(50);
    DECLARE @AgentName varchar(50);


	IF EXISTS (SELECT 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent))
	BEGIN  
		SET @ReopenConversationButtonResponse = ''REOPEN_CONVERSATION'';
	END
	ELSE 
	BEGIN 
		SET @ReopenConversationButtonResponse = ''REOPEN_CONVERSATION_WITH_TEMPLATE'';
	END

    IF @CamType = 0
    BEGIN
		IF EXISTS (SELECT 1 FROM ccWhatsAppConversations WHERE InboundId = @CamId AND phoneACD = @CamNumber AND clientId = @ClientNumber AND conversationStatus = 2 AND (agentId = @agentId OR agentId <> @agentId))
		BEGIN
			SELECT TOP 1 @ConvId = ConversationId FROM ccWhatsAppConversations WHERE InboundId = @CamId  AND phoneACD = @CamNumber  AND clientId = @ClientNumber  AND conversationStatus = 2  AND (agentId = @agentId OR agentId <> @agentId);
			SELECT @AgentName = u.Nombres FROM ccWhatsAppConversations c
											INNER JOIN ccusers u ON c.agentId = u.User_id 
											WHERE c.ConversationId = @ConvId;
			SELECT ''ONGOING_CONVERSATION'' AS ReopenConversationButtonResponse,
								@AgentName AS AgentName;
			RETURN(0);
		END

        SELECT @MaxWhatsAllowed = a.maxWhats FROM ccinbound i INNER JOIN ccriacat_Areas a ON i.IDArea = a.IDArea WHERE i.Inbound_Id = @CamId;
		SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversations WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(hour, -48, GETDATE());

		IF @ConversationCount >= @MaxWhatsAllowed
		BEGIN
			SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationButtonResponse;
			RETURN(0);
		END
		ELSE
		BEGIN
			SELECT @ReopenConversationButtonResponse AS ReopenConversationButtonResponse,
										       ''N/A'' AS AgentName;
			RETURN(0);
	END

    END
    IF @CamType = 1
    BEGIN
        IF EXISTS (SELECT 1 FROM ccWhatsAppConversationsOut WHERE camId = @CamId AND phoneCamp = @CamNumber AND clientId = @ClientNumber AND conversationStatus = 2 AND (agentId = @agentId OR agentId <> @agentId))
        BEGIN
			SELECT TOP 1 @ConvId = ConversationId FROM ccWhatsAppConversationsOut WHERE camId = @CamId  AND phoneCamp = @CamNumber  AND clientId = @ClientNumber  AND conversationStatus = 2  AND (agentId = @agentId OR agentId <> @agentId);
			SELECT @AgentName = u.Nombres FROM ccWhatsAppConversationsOut c
										  INNER JOIN ccusers u ON c.agentId = u.User_id 
									      WHERE c.ConversationId = @ConvId;
            SELECT ''ONGOING_CONVERSATION'' AS ReopenConversationButtonResponse,
							   @AgentName AS AgentName;
			RETURN(0);
        END

		SELECT @MaxWhatsAllowed = a.maxWhatsOut FROM cccamps c INNER JOIN ccriacat_Areas a ON c.IDArea = a.IDArea WHERE c.cam_id = @CamId;
		SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversationsOut WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(hour, -48, GETDATE());

		IF @ConversationCount >= @MaxWhatsAllowed
		BEGIN
			SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationButtonResponse;
			RETURN(0);
		END
        ELSE
        BEGIN
            SELECT @ReopenConversationButtonResponse AS ReopenConversationButtonResponse,
									     ''N/A'' AS AgentName;
            RETURN(0);
        END
    END
END 

IF @Option = 10 -- Creación de conversationId de entrada 
BEGIN 
	EXEC ccsp_ConversationWASave @action=1, @phoneacd=@CamNumber, @clientid= @ClientNumber, @inboundid=@CamId, @agentId = @agentId, @IsReopenedConversation = 1, @conversationstatus=2

END 

IF @Option = 11 -- Creación de conversationId de salida
BEGIN
	EXEC ccsp_ConversationOutWASave @action=1, @phoneCamp=@CamNumber, @clientid= @ClientNumber, @campId=@CamId, @agentId = @agentId, @IsReopenedConversation = 1, @conversationstatus=2
END
'

EXEC(@sql)

SET @process = 'delete sp ccspOutboundWhatsApp'
SET @sql = '
IF EXISTS (SELECT * FROM sys.procedures where name= N''ccspOutboundWhatsApp'')
BEGIN
	DROP PROCEDURE ccspOutboundWhatsApp
END'
EXEC(@sql)


SET @process = 'create sp ccspOutboundWhatsApp'
SET @sql = '
CREATE procedure [dbo].[ccspOutboundWhatsApp]
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
		Token,
		CAST(c.IDArea AS int) as AreaId
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
		cmw.Token AS Token,
		CAST(ci.IDArea AS int) as AreaId
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
			REPLACE(@Url, ''phoneId'', cmw.PhoneNumberId) AS Url,
			cmw.Token AS Token,
			CAST(ci.IDArea AS int) as AreaId
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
			REPLACE(@Url, ''phoneId'', PhoneNumberId) as Url, 
			Token,
			CAST(c.IDArea AS int) as AreaId
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

end
'
EXEC(@sql)
-------------------------------------------  END ISAAC CORTES  -------------------------------------------------------------	
------------------------------------------- BEGIN FRIDA ---------------------------------------------------------------------
SET @process = 'CW-8864 add column CreationDate to ccMetaWAOutboundTemplates '
SET @sql = '
if not exists (select * from sys.columns where name = N''CreationDate'' and Object_ID = Object_ID(N''ccMetaWAOutboundTemplates''))
    begin
        alter table ccMetaWAOutboundTemplates add CreationDate datetime null
    end
'
EXEC(@sql)

SET @process = 'CW-8864 drop sp ccsp_MetaWAOutboundTemplates '
SET @sql = '
if exists (select * from sys.procedures where name = N''ccsp_MetaWAOutboundTemplates'')
    begin
		DROP PROCEDURE ccsp_MetaWAOutboundTemplates;
    end
'
EXEC(@sql)

SET @process = 'CW-8864 create sp ccsp_MetaWAOutboundTemplates '
SET @sql = '
CREATE PROCEDURE ccsp_MetaWAOutboundTemplates
@action TINYINT = NULL,
@whatsAppTemplateID BIGINT = 0,
@id varchar(200) = NULL,
@Category varchar(50) = NULL,
@TemplateName varchar(512) = NULL,
@AllowCategoryChange tinyint = NULL,
@LanguageCode varchar(10)= NULL,
@Status varchar(200)= NULL, 
@header nvarchar(max)= null,
@body nvarchar(max) = null,
@footer nvarchar(max) = null,
@buttons nvarchar(max) = null,
@metaStatus varchar(30) = NULL,
@FilePath varchar(1024) = null,
@HistoryLog varchar(max) = null,
@campId SMALLINT = NULL,
@UserId	SMALLINT = 0,
@MetaId INT = 0,
@CreationDate DATETIME = NULL
AS
BEGIN
    IF(@action = 1) -- get template by id
    BEGIN
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
        ,ISNULL(cmwot.quality,0) AS Quality
        ,cmwot.IsPendingQuality
        ,cmwot.FilePath
        ,cmwot.Status AS Status
        FROM  dbo.ccMetaWAOutboundTemplates AS cmwot
        WHERE cmwot.Id = @whatsAppTemplateID
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
        insert into ccMetaWAOutboundTemplates (Id, Category,TemplateName,AllowCategoryChange,LanguageCode,Status,header,body,footer,buttons,FilePath,MetaId,StatusCW,CreationDate)
                            values (@Id, @Category,@TemplateName,@AllowCategoryChange,@LanguageCode,@Status,@header,@body,@footer,@buttons,@FilePath,@MetaId,1,@CreationDate)
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
    ELSE IF(@action = 7) -- Get template campaigns associated
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
        IF (@header IS NULL OR LEN(@header) = 0) AND (SELECT LEN(ISNULL(header,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when header is null or '''' and before update header contains data
        BEGIN
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_HEADER'',''COMMON_NONE_O'',@TemplateName)
        END
        IF (@footer IS NULL OR LEN(@footer) = 0) AND (SELECT LEN(ISNULL(footer,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when footer is null or '''' and before update footer contains data
        BEGIN
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_FOOTER'',''COMMON_NONE_O'',@TemplateName)
        END
        IF (@buttons IS NULL OR LEN(@buttons) = 0) AND (SELECT LEN(ISNULL(buttons,'''')) FROM ccMetaWAOutboundTemplates WHERE Id = @Id) > 0 -- when buttons is null or '''' and before update buttons contains data
        BEGIN
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            VALUES (@areaName, GETDATE(), @login, 122, 20, ''T&EDIT_TEMPLATE_BUTTONS'',''COMMON_NONE_O'',@TemplateName)
        END
        
        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccMetaWAOutboundTemplates'', @columnNameId=''Id'', @valueId= @Id, @userId= 1
        Create table #ccMetaWAOutboundTemplates 
        (
            columnInfo VARCHAR(MAX),
            dataInfo VARCHAR(MAX),
            identifierInfo VARCHAR(MAX)
        )

        UPDATE ccMetaWAOutboundTemplates
        SET Category = @Category,
            header = @header,
            body = @body,
            footer = @footer,
            buttons = @buttons,
            FilePath = @FilePath
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
            @TemplateName
        FROM #ccMetaWAOutboundTemplates cc
        INNER JOIN  @tableHistoryLog  tb1 ON cc.columnInfo = (CASE 
                                                                WHEN tb1.Id = 1 THEN ''Category''
                                                                WHEN tb1.Id = 2 THEN ''header'' 
                                                                WHEN tb1.Id = 3 THEN ''body'' 
                                                                WHEN tb1.Id = 4 THEN ''footer''
                                                                WHEN tb1.Id > 4 THEN ''buttons''
                                                                END)
    END
    else IF(@action = 9) -- get templates by phone number
    BEGIN
        ;WITH tb1 as(
            SELECT
                gal.Target AS TemplateName,
                MAX(gal.ActivityDate) AS Date
            FROM ccGalateaActivityLog gal 
            WHERE gal.OperationId = 122 
            AND gal.ModuleId = 20 
            AND CAST(gal.ActivityDate AS DATE) >= DATEADD(DD,-30, CAST(GETDATE() AS DATE))
            GROUP BY gal.Target, CAST(gal.ActivityDate AS DATE)
        )
        ,TemplateIsEditable AS (
            SELECT
                tb1.TemplateName,
                CASE WHEN COUNT(*) >= 10 THEN 2 WHEN MAX(tb1.Date) >= DATEADD(HOUR, -24, GETDATE()) THEN 1 ELSE 0 END AS IsEditable
            FROM tb1
            GROUP BY tb1.TemplateName
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
        ,ISNULL(cmwot.quality,0) AS Quality
        ,cmwot.IsPendingQuality
        ,ISNULL(tie.IsEditable, 0) AS IsEditable
        ,cmwot.FilePath
		,cmwot.CreationDate
        FROM  dbo.ccMetaWAOutboundTemplates cmwot
        LEFT JOIN TemplateIsEditable tie ON tie.TemplateName = CAST(cmwot.TemplateName AS VARCHAR(MAX))
        WHERE cmwot.MetaId = @whatsAppTemplateID
        AND cmwot.StatusCW = 1
    END
    ELSE IF(@action = 10) -- Check if an other load is executing for the campaign
    BEGIN
        SELECT CASE WHEN COUNT(crl.load_id) > 0 THEN CONVERT(BIT , 1) ELSE CONVERT(BIT, 0) END AS IsProcessExecuting FROM dbo.ccRIALoading AS crl
        WHERE crl.cam_id = @campId AND crl.state IN (0,2) AND crl.loadType = 3;
    END
    ELSE IF(@action = 11) --Check if the campaign was eliminated or desasigned
    BEGIN
        DECLARE @campaignIsEliminateDesasigned BIT = 0;
        DECLARE @idAreaNull SMALLINT = 0;

        SELECT  @idAreaNull = cc.IDArea FROM dbo.ccCamps AS cc WHERE cc.cam_id = @campId

        IF(@idAreaNull IS NULL)
        BEGIN
            SET @campaignIsEliminateDesasigned = 1; --La campaña fue eliminada
        END

        IF NOT EXISTS(SELECT TOP 1 crcew.IdCampEsp FROM dbo.ccRIACampEspWG AS crcew INNER JOIN dbo.ccRIAWorkGroupUsers AS crwgu
        ON crwgu.IDWG = crcew.IDWG
        WHERE crwgu.User_id = @UserId AND crcew.Tipo = 1 AND crcew.IdCampEsp = @campId)
        BEGIN 
            SET @campaignIsEliminateDesasigned = 1; --La campaña fue desasignada del grupo de trabajo
        END

        SELECT @campaignIsEliminateDesasigned;
    END
    ELSE IF(@action = 12) --Get new numbers loaded in  ccWhatsAppOutSource 
    BEGIN
        SELECT cwt.Callkey FROM dbo.ccoWAWorkingTable AS cwt WHERE cwt.CamId = @campId AND cwt.WaStatus = 0
        UNION
        SELECT cwaos.CallKey FROM dbo.ccWhatsAppOutSource AS cwaos 
        WHERE cwaos.camId = @campId AND cwaos.Status = 0
    END
    IF(@action = 13) -- Get templates by campaign number assigned
    BEGIN
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
        ,ISNULL(cmwot.quality,0) AS Quality
        ,cmwot.IsPendingQuality
        ,cmwot.FilePath
		,cmwot.CreationDate
        FROM  dbo.ccMetaWAOutboundTemplates AS cmwot
        INNER JOIN dbo.ccMetaWhatsAppNumbers AS cmwan ON 
        cmwot.MetaId = cmwan.MetaId
        WHERE cmwot.StatusCW = 1 AND cmwan.Cam_Id = @campId AND cmwot.Status = ''APPROVED''
    END
    ELSE IF (@action = 14) -- check if campaing exists
    BEGIN
        IF EXISTS(SELECT 1 FROM dbo.ccMetaWAOutboundTemplates cmwot WHERE cmwot.Id = @whatsAppTemplateID)
            SELECT 1
        ELSE
            SELECT 0
    END
END
'
EXEC(@sql)

		------------------------------------------- BEGIN Ivan Martin K066004 y K066004----------------------------------------

		SET @process = 'K066004 y K066015 Added and conversationStatus in (8,9) in the select of the result'
        SET @sql = '
        ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformation]
        @Option SMALLINT,
        @InboundId SMALLINT = 0,
        @ConversationId INT = 0,
        @AgentsAvailables INT = 0,
        @IncreaseDecreaseAgent BIT = NULL

        AS
        SET NOCOUNT ON

        IF @Option = 0 BEGIN	-- Reset TABLES
            TRUNCATE TABLE ccWAAverageConversations;
            TRUNCATE TABLE ccLastMessageAgentByConversation;
        END


        IF @InboundId IS NULL or  
        NOT EXISTS (SELECT * FROM ccInbound with(nolock) WHERE Inbound_id = @InboundId AND chat = 5) 
        BEGIN
        RETURN (-1)
        END

            DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
            
        IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
        BEGIN
            IF EXISTS (SELECT * FROM ccWAAverageConversations with(nolock)
                        WHERE InboundId = @InboundId
                        AND (LastUpdate IS NULL
                        OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                        OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
            BEGIN
                -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

                DECLARE @AverageConversationTime INT = 0;
                DECLARE @AverageDialogTime INT = 0;
                DECLARE @AverageWaitingTime INT = 0;
                DECLARE @MaximumWaitingTime INT = 0;
                DECLARE @DefaultValue INT = (SELECT CASE 
                        WHEN defaultServiceLevelParameter IS NULL THEN 2 
                        WHEN defaultServiceLevelParameter = 0 THEN 2
                        ELSE defaultServiceLevelParameter END
                FROM contactMeanIn WHERE inboundId = @InboundId);
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
                FROM ccWhatsAppConversations WHERE inboundId = @InboundId
                AND requestDate >= @Today

                SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

                ----------------------------------------------------- Update table --------------------------------------------------------

                IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
                BEGIN
                    UPDATE ccWAAverageConversations
                    SET AverageConversationTime = @AverageConversationTime,
                        AverageDialogTime = @AverageDialogTime,
                        AverageWaitingTime = @AverageWaitingTime,
                        MaximumWaitingTime = @MaximumWaitingTime,
                        ServiceLevel = @ServiceLevel,
                        StatusUpdate = 0,
                        LastUpdate = GETDATE()
                    WHERE InboundId = @InboundId
                END
                ELSE
                BEGIN
                    INSERT INTO ccWAAverageConversations (InboundId, AverageConversationTime, AverageDialogTime,
                                                            AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
                    VALUES(@InboundId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                            @ServiceLevel, 0 , GETDATE())
                END
            END
            --------------------------------- Results -----------------------------------

            if exists (select * from ccWAOperatingSummary with(nolock) where Inboundid=@InboundId
            and (OnQueue<0 or Assigned<0)
            ) begin                                
                set @Today =convert(date,getdate(),121)

                ;with waOperationSummary as(
                        select 
                inboundId
                --,count(case when finishedBy=1 then 1 end) Attend
                ,count(case when onQueue=1 and finishedBy=0 and conversationStatus in (8,9) then 1 end) onQueue
                ,count(case when finishedBy=0 and agentId>0 then 1 end) Assigned
                --,count(*) Request
                --,count(case when finishedBy=2 then 1 end) EndedBySystem
                from ccWhatsAppConversations with(nolock)
                where inboundId=@InboundId
                and requestDate>=@Today
                group by inboundId
                )
                update A 
                set A.OnQueue=B.onQueue, A.Assigned=B.Assigned
                from ccWAOperatingSummary A 
                inner join waOperationSummary B on A.Inboundid=B.inboundId
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
            FROM ccWAAverageConversations conv
            RIGHT JOIN ccWAOperatingSummary summary ON conv.InboundId = summary.InboundId
            WHERE conv.inboundId = @InboundId OR summary.InboundId = @InboundId
        END
        ELSE IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
            -- Average Queue/Waiting Time, and Service Level)
            BEGIN
                IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
                BEGIN
                    UPDATE ccWAAverageConversations SET StatusUpdate = 1
                    WHERE InboundId = @InboundId
                END
                ELSE
                BEGIN
                    INSERT INTO ccWAAverageConversations (InboundId, StatusUpdate)
                    VALUES(@InboundId, 1)
                END
            END
        ELSE IF @Option = 3 -- Save time from accepted conversation by agent
            BEGIN
                IF @ConversationId IS NOT NULL
                BEGIN
                    UPDATE ccWhatsAppConversations SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
                    --Save Conversation Assigned
                    SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
                END
            END
        ELSE IF @Option = 4 -- Get Disposition Information
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
                FROM ccWhatsAppConversations whatsConv with(nolock) 
                LEFT JOIN cctipocalif disposition ON disposition.calif_id = whatsConv.disposition
                WHERE inboundId = @InboundId AND assignDate >= @Today
                        and whatsConv.conversationStatus != 2
                GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
            END
        ELSE IF @Option = 5 -- Get Subdisposition Information
            BEGIN
                SELECT relation.calif_id AS DispositionId,
                        subDispositions.califSubDesc AS SubDispositionsName,
                        COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
                FROM cctipoSubCalifRel relation
                INNER JOIN ccTipoCalifSub subDispositions ON subDispositions.califSub_id = relation.califSub_id
                INNER JOIN ccWhatsAppConversations whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
                WHERE whatsConv.inboundId = @InboundId AND
                        whatsConv.assignDate >= @Today AND
                        relation.tipoSubRel = 1
                GROUP BY subDispositions.califSubDesc, relation.calif_id
            END
        ELSE IF @Option = 6 -- Agents Availables
            BEGIN
            IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @InboundId)
                BEGIN
                    INSERT INTO ccWAOperatingSummary (InboundId, Available) VALUES (@InboundId, @AgentsAvailables);
                END
            ELSE
            BEGIN
                UPDATE ccWAOperatingSummary SET Available = @AgentsAvailables WHERE InboundId = @InboundId
            END
        END
        RETURN(0)
        '
		EXEC(@sql)
		SET @process = 'K066004 y K066015 Same thing as before but for ccsp_WhatsAppInformation. Added and conversationStatus in (8,9)'
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
					,count(case when onQueue=1 and finishedBy=0 and conversationStatus in (8,9) then 1 end) onQueue
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

		------------------------------------------- BEGIN David Medina  K066003----------------------------------------
		SET @process = 'K066003 delete sp ccsp_InboundMultimediaCommon'
		SET @sql = '
		IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_InboundMultimediaCommon'')
		BEGIN
			DROP PROCEDURE ccsp_InboundMultimediaCommon
		END'
		EXEC(@sql)

		SET @process = 'K066003 Se crea SP ccsp_InboundMultimediaCommon para obtener conversación en Multimedia reabierta desde historial de agente'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_InboundMultimediaCommon] 
                    @Action INT,
                    @ConversationId INT = NULL
                    AS
                    BEGIN
                    SET NOCOUNT ON;

                        IF @Action = 1 -- Get Inbound WhatsApp conversation by conversation id
                        BEGIN 
                            DECLARE @ServiceType VARCHAR(20) = ''whatsapp''
                            SELECT conversationId AS ConversationID,
                                   clientId AS ClientId,
                                   phoneACD AS CampaignPhone,
                                   agentId AS AgentId,
                                   @ServiceType AS ServiceType,
                                   requestDate AS InitialTime
                            FROM ccWhatsAppConversations
                            WHERE conversationId = @ConversationId 
                        END
                    END
		'
		EXEC(@sql)

		SET @process = 'K066003 delete sp ccsp_WhatsAppOutboundTemplates'
		SET @sql = '
		IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_WhatsAppOutboundTemplates'')
		BEGIN
			DROP PROCEDURE ccsp_WhatsAppOutboundTemplates
		END'
		EXEC(@sql)

		SET @process = 'K066003 Se Modifica SP ccsp_WhatsAppOutboundTemplates para que rerese tambien variable StatusMeta'
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
									select header, Body,footer, Status as StatusMeta from ccMetaWAOutboundTemplates WHERE TemplateName = @TemplateName 
								end
							END
					
							IF @Action = 2  -- Get category from ccWhatsAppGlobalIds
							BEGIN
								SELECT UPPER(wagi.Category) AS Category
								FROM ccWhatsAppGlobalIds wagi
								INNER JOIN ccWhatsAppGlobalIdsRelationship wagir ON wagi.GlobalId = wagir.GlobalId
								WHERE wagir.ConversationId = @ConversationId AND wagir.ConversationType = 1;
							END

							SET NOCOUNT OFF 
		'
		EXEC(@sql)
		---------------------------------------------  END DAVID MEDINA------------------------------------------------




----------------------------------------------------------- End Luis Miguel Zamora Nuñez -------------------------------------------------------------------------
SET @process = 'landus Alter SP InsertLogAdminGalatea @action=2  Correcion log Campañas '
        SET @sql = 'ALTER procedure [dbo].[InsertLogAdminGalatea]
@action int 
,@tableName VARCHAR(255)
,@columnNameId VARCHAR(255)
,@valueId VARCHAR(255)
,@userId int
,@tableTemp varchar(255)=null
as
SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @sql nvarchar(max),@sql2 nvarchar(max)
DECLARE @tableNameTmp VARCHAR(255) = ''##''+@tableName+''_''+convert(varchar(10),@userId)

if @action =1 begin --Antes del cambio

        set @sql=''IF OBJECT_ID(N''''tempdb..''+@tableNameTmp+'''''') IS NOT NULL DROP TABLE ''+@tableNameTmp+''
        SELECT * INTO ''+@tableNameTmp+'' FROM ''+@tableName+'' WHERE ''+@columnNameId+'' = ''+@valueId
        --print(@sql)
        exec(@sql)

end
else if @action=2 begin
    DECLARE @columns NVARCHAR(MAX) = '''';
        DECLARE @conditions NVARCHAR(MAX) = '''';
        DECLARE @caseStatements NVARCHAR(MAX) = '''';
        DECLARE @batchSize INT = 10; -- Tamaño del bloque de columnas
        DECLARE @counter INT = 0;
        declare @emtpy varchar(2)=''''
        

        -- Declarar una variable de tipo tabla para almacenar los IDs de cada bloque
        DECLARE @BatchColumns TABLE (
                name NVARCHAR(128),
                batch_id INT
        );
        -- Insertar en @BatchColumns las columnas de la tabla, dividiéndolas en bloques
        INSERT INTO @BatchColumns (name, batch_id)
        SELECT 
                name,
                (ROW_NUMBER() OVER (ORDER BY column_id) - 1) / @batchSize AS batch_id
        FROM 
                sys.columns
        WHERE 
                object_id = OBJECT_ID(@tableName)
                AND name <> @columnNameId  -- Excluir la columna clave primaria
                AND name <> ''rowguid'';  -- Excluir la columna clave primaria

        -- Insertar batch_ids únicos en la variable de tipo tabla @BatchIds
        DECLARE @BatchIds TABLE (
                batch_id INT PRIMARY KEY
        );

        INSERT INTO @BatchIds
        SELECT DISTINCT batch_id FROM @BatchColumns;

        DECLARE @batch_id INT = 0;

        -- Bucle para procesar cada bloque de columnas
        WHILE EXISTS (SELECT 1 FROM @BatchIds WHERE batch_id = @batch_id)
        BEGIN
                -- Construir las expresiones CASE y las condiciones WHERE para este bloque
                SET @caseStatements = '''';
                SET @conditions = '''';

                -- Construir el CASE y el WHERE para cada columna en el bloque actual
                SELECT 
                        @caseStatements = @caseStatements + 
                        ''SELECT '''''' + name + '''''' AS columnInfo, CONVERT(VARCHAR(300), A.'' + QUOTENAME(name) + '') AS dataInfo '' +
                        ''FROM '' + @tableName + '' AS A '' +
                        ''FULL OUTER JOIN '' + @tableNameTmp + '' AS B ON A.'' + QUOTENAME(@columnNameId) + '' = B.'' + QUOTENAME(@columnNameId) + '' '' +
                        ''WHERE A.'' + QUOTENAME(name) + '' <> B.'' + QUOTENAME(name) + '' UNION ALL ''
                FROM 
                        @BatchColumns
                WHERE 
                        batch_id = @batch_id;                   

                -- Construir las condiciones WHERE para el bloque actual
                SELECT @conditions = @conditions + 
                CASE WHEN @conditions = '''' THEN '''' ELSE '' OR '' END +
                ''A.'' + QUOTENAME(name) + '' <> B.'' + QUOTENAME(name)
                FROM 
                        @BatchColumns
                WHERE 
                        batch_id = @batch_id;

                -- Remover el último UNION ALL sobrante
                SET @caseStatements = LEFT(@caseStatements, LEN(@caseStatements) - LEN('' UNION ALL ''));
                
                -- Construir y ejecutar la consulta para este bloque
                IF @caseStatements <> ''''
                BEGIN
                        SET @sql = ''
                        INSERT INTO ''+@tableTemp+'' (columnInfo, dataInfo)
                        '' + @caseStatements + ''                       
                        '';

                        --print @sql
                        -- Ejecutar la consulta dinámica
                        EXEC sp_executesql @sql;
                END     

                -- Avanzar al siguiente bloque
                SET @batch_id = @batch_id + 1;
        END


        -- Consultar el resultado final de cambios
        set @sql=
        ''SELECT distinct A.columnInfo,A.dataInfo,isnull(B.Identifiers,@emtpy) as identifierInfo 
        FROM ''+@tableTemp+'' A 
        left join relationTableColumnIdentifiers B on A.columnInfo=B.colunName and B.tableName=@tableName
        ''
        
        if @tableTemp is not null and @tableTemp<>'''' begin
                set @sql= ''insert into ''+@tableTemp +'' ''+ @sql
        end
        print @tableName
        print @sql
        EXEC sp_executesql @sql
        ,N''@tableName varchar(255), @emtpy varchar(2)'',
    @tableName = @tableName,@emtpy=@emtpy

end
else if @action =3 begin
        set @sql=''IF OBJECT_ID(N''''tempdb..''+@tableNameTmp+'''''') IS NOT NULL DROP TABLE ''+@tableNameTmp
        --print(@sql)
        exec(@sql)
end'
        EXEC(@sql);

        SET @process = 'Alter ccsp_AvrsSyncronization para cambiar la duration cuando se graba el hold, se agrega para IsVoicemail y borrado de varios registros'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization]
@action SMALLINT,
@maxRecordsToTransfer INT = 10,
@ids varchar(max)= 0
AS
BEGIN
SET NOCOUNT ON;

IF @action = 1
BEGIN
    DECLARE @countrId INT;
    SET @countrId = 1;

    SELECT @countrId = valor
    FROM ccSettings
    WHERE setting_id = 104;

          -- Declarar la variable tipo tabla
        declare @tempCalls table(
        cal_id INT,
        user_id INT,
        Inbound_id INT,
        calif_id int,
        cal_extension INT,
        cal_inicio DATETIME,
        phone VARCHAR(50),
        duration INT,
        cal_key VARCHAR(50),
        cal_manual int,
        cal_puerto INT,
        dni_id INT,
        fvalida datetime,
        cal_whohung int,
        califSub_id int,
        cal_tMoh INT,
        dateEnd DATETIME,
        callType INT,
        avrsId INT,
        prefijo VARCHAR(20),
        isCallRecord BIT,
        DNIS VARCHAR(50),
        IDWG INT,
        IsVoicemail BIT
    );

        declare @deleteRow table(id int primary key);
        declare @relationCallIdUser table(cal_id int, user_id int);

    WITH callsIn AS (
        SELECT TOP (@maxRecordsToTransfer) 
            calls.cal_id as CallId,
            user_id,
            calls.Inbound_id,
            calls.calif_id,
            CAST(cal_extension AS INT) AS cal_extension,
            cal_inicio,
            cal_ANI AS phone,
            ISNULL(cal_tDialog - CASE WHEN ccInbound.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0) 
            + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
            cal_key,
            0 AS cal_manual,
            cal_puerto,
            calls.dni_id,
            fvalida,
            cal_whohung,
            ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
            CASE 
                WHEN trans.tAntesXfer IS NULL THEN cal_tMoh 
                WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 
                ELSE cal_tMoh - trans.tAntesXfer 
            END AS cal_tMoh,
            DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
            avrs.tipo + 1 AS callType,
            avrs.id AS avrsId,
            ccInbound.prefijo,
            CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
            ISNULL(dni.dni_numero, '''') AS DNIS,
            dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
            0 AS IsVoicemail                        
        FROM ccCallsIn AS calls WITH (NOLOCK)
        INNER JOIN ccInbound ON ccInbound.Inbound_id = calls.Inbound_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 0
        LEFT JOIN ccDNIS dni ON dni.dni_id = calls.dni_id
        LEFT JOIN ccInboundExtend inbExt ON inbExt.Inbound_id = calls.Inbound_id
        LEFT JOIN (
            SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers  with(nolock)
            WHERE tipo = 1 AND modo != 7
            GROUP BY cal_id, tipo
        ) trans ON calls.cal_id = trans.cal_id    
    ),
    callsOut AS (
        SELECT TOP (@maxRecordsToTransfer) 
            calls.cal_id AS CallId,
            user_id AS UserId,
            calls.cam_id AS camAcdId,
            CAST(calls.calif_id AS SMALLINT) AS califId,
            CAST(cal_extension AS INT) AS extension,
            cal_inicio,
            cal_telefono,
            ISNULL(cal_tDialog - CASE WHEN camps.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0) 
            + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
            cal_key,
            cal_manual,
            cal_puerto,
            0 AS dni_id,
            fvalida,
            cal_whohung,
            ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
            CASE 
                WHEN trans.tAntesXfer IS NULL THEN cal_tMoh 
                WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 
                ELSE cal_tMoh - trans.tAntesXfer 
            END AS cal_tMoh,
            DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
            avrs.tipo + 1 AS callType,
            avrs.id AS avrsId,
            camps.prefijo,
            CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
            '''' AS DNIS,
            dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
            CASE WHEN calls.statusCall_id = 19 THEN 1 ELSE 0 END AS IsVoicemail                        
        FROM ccoCallsOut AS calls WITH (NOLOCK)
        INNER JOIN ccCamps camps ON camps.cam_id = calls.cam_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 1
        LEFT JOIN (
            SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers with(nolock)
            WHERE tipo = 2
            GROUP BY cal_id, tipo
        ) trans ON calls.cal_id = trans.cal_id      
    )

    INSERT INTO @tempCalls                
    SELECT * FROM callsIn
    UNION 
    SELECT * FROM callsOut;


    insert into @deleteRow
    select min(avrsId) id
    from @tempCalls
    group by cal_id,callType 
    having count(*)>1
    
    delete from @tempCalls where avrsId in( select id from @deleteRow )
        delete from ccAVRSTransfer where id in( select id from @deleteRow )

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and callType=0)
    BEGIN   
                insert into @relationCallIdUser
                select A.cal_id,aglog.User_id from @tempCalls A
                inner join ccCallsIn B with(nolock) on A.cal_id=B.cal_id and A.callType=0
                inner join ccLogAgentesDia aglog with(nolock) on aglog.callID=B.cal_id and aglog.Tipo=A.callType and aglog.TipoStatusAge_id=4

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join ccCallsIn B with(nolock) on A.cal_id=B.cal_id 

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join @tempCalls B on A.cal_id=B.cal_id and B.callType=0
                
                delete from @relationCallIdUser
        END

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and callType=1 and IsVoicemail =0)
    BEGIN   
                insert into @relationCallIdUser
                select A.cal_id,aglog.User_id from @tempCalls A
                inner join ccoCallsOut B with(nolock) on A.cal_id=B.cal_id and A.callType=1
                inner join ccLogAgentesDia aglog with(nolock) on aglog.callID=B.cal_id and aglog.Tipo=A.callType and aglog.TipoStatusAge_id=4

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join ccoCallsOut B with(nolock) on A.cal_id=B.cal_id 

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join @tempCalls B on A.cal_id=B.cal_id and B.callType=1
        END

     -- Revisar si hay registros con IsVoicemail = 1
    IF EXISTS (SELECT 1 FROM @tempCalls WHERE IsVoicemail = 1)
    BEGIN            
                update A
                set A.duration=B.tDialing
                FROM @tempCalls A
                Inner JOIN ccoLogDials B with(nolock) ON A.cal_id=B.cal_id
        WHERE A.IsVoicemail = 1;
    END

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and IsVoicemail=0)
    BEGIN
                delete A from ccAVRSTransfer A
                inner join @tempCalls t on A.id=t.avrsId 
                where t.user_id=0 and t.IsVoicemail=0
        END
        
    -- Si no hay registros con IsVoicemail, simplemente devolver los resultados de la variable tipo tabla
    SELECT * FROM @tempCalls;
        
END
ELSE IF @action = 2
BEGIN
    Delete A
    from ccAVRSTransfer A
    inner join dbo.fn_RIASplitDelimited(@ids,'','') t on A.id=t.Value
    
END
END;
'
        EXEC(@sql);
SET @process = 'ccsp_GalateaLoadUsersForManagement - SP Edited, Editado para el envio correcto de datos al front.
Se asigna el LastName a @ApellidoPaterno = @LastName, y NombreOpcionalExtra a  @ApellidoMaterno = @NombreOpcionalExtra'
SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
 @option SMALLINT,
 @AreaId SMALLINT = null,
 @UserType INT = null,
 @Username VARCHAR(200)=null,
 @userId INT = 0,
 @groupList VARCHAR(MAX) = null
AS

        --Obtiene el idioma de de Centerware
        Declare @lenguageXion varchar
        select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para espanol, 1 para ingles, 2 para portugues

IF @option = 1 --Agentes/supervisores de un Area
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  ApellidoPaterno as LastName,
  ApellidoMaterno as OptionalExtraName,
  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId,
  notificationEmail
  FROM ccusers
  WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
        AND DATEDIFF(dd, LastLoginAttempt, getdate()) < 60
  ORDER BY LOGIN, Nombres, ApellidoPaterno,Sexo, User_id

  RETURN (0)
END

IF @option = 2 -- obtiene Agente o supervisor en base a su nombre de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  ApellidoPaterno as LastName,
  ApellidoMaterno as OptionalExtraName,
  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId,
  notificationEmail
  FROM ccusers
  WHERE Login=@Username

  RETURN (0)
END

IF @option = 3 -- obtiene Agente o supervisor en base a su ID de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  ApellidoPaterno as LastName,
  ApellidoMaterno as OptionalExtraName,
  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId,
  notificationEmail
  FROM ccusers
  WHERE user_id=@userId

  RETURN (0)
END

IF @option = 4 -- supervisores en Area/Sistema
BEGIN
        DECLARE @Admins TABLE (UserId smallint, Username varchar(50), Names varchar(50), LastName varchar(50), OptionalExtraName varchar(50), AreaId smallint, primary key(UserId))
        INSERT INTO @Admins
        SELECT User_id as UserId,
        LOGIN as Username,
        Nombres as Names,
        ApellidoPaterno as LastName,
        ApellidoMaterno as OptionalExtraName,

        isnull(IDArea, 0) as AreaId
        FROM ccusers
        WHERE TipoUser_id = 2 AND STATUS = 1


        IF NOT EXISTS(SELECT * FROM ccUsers_Roles WHERE User_id=@userId and Rol_id=7) BEGIN
                SELECT UserId, Username, Names, LastName, OptionalExtraName
                FROM @Admins
                WHERE AreaId = (SELECT IDArea FROM ccUsers WHERE User_id=@userId)
                ORDER BY Username, Names, LastName, UserId
        END
        ELSE BEGIN
                SELECT UserId, Username, Names, LastName, OptionalExtraName
                FROM @Admins
                ORDER BY Username, Names, LastName, UserId
        END
        Return(0)
END

IF @option = 5 --Usuarios inactivos por mas de 60 dias por area
BEGIN
        SELECT [User_id] as UserId,
        LOGIN as Username
        FROM CCUSERS WHERE DATEDIFF(dd, LastLoginAttempt, getdate()) >= 60
        AND @AreaId = IDArea
        RETURN 0;
END
IF @option = 6 -- Usuarios inactivos por más de 60 días por grupo de trabajo, correccion del ticket TT13248
BEGIN
        DECLARE @tempTable TABLE (Id INT)

        INSERT INTO @tempTable
        SELECT value FROM fn_RIASplitDelimited(@groupList, '','')


        SELECT 
        CAST(wgu.IDWG AS VARCHAR(10)) AS idwg,
        STUFF((
                SELECT '', '' + CAST(wgu2.User_id AS VARCHAR)
                FROM ccUsers u2
                INNER JOIN ccRIAWorkGroupUsers wgu2 ON wgu2.User_id = u2.User_id
                WHERE wgu2.IDWG = wgu.IDWG
                        AND u2.LastLoginAttempt <= DATEADD(DAY, -60, GETDATE())
                FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''') AS agents
        FROM ccUsers u
        INNER JOIN ccRIAWorkGroupUsers wgu ON wgu.User_id = u.User_id
        WHERE 
               wgu.IDWG IN (SELECT Id FROM @tempTable)
                AND u.LastLoginAttempt <= DATEADD(DAY, -60, GETDATE())
        GROUP BY wgu.IDWG
        ORDER BY wgu.IDWG;
        RETURN 0;

END'
EXEC(@sql)

SET @process = 'ALTER SP ccsp_ccActivityDataQuery @action 12,13,14 cambio @packageData por filas de 8000 caracetres'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ccActivityDataQuery]
@action int,@userId int=0,@camId int=0,@dnisId int=0,@WgId int=0,@tipo int =null
,@camIdOuts varchar(1000)='''',@camIdIns varchar(1000)='''',@userIds varchar(max)=''''
AS
set nocount on

declare @valdiate int
declare @packageData varchar(max)
DECLARE @blockSize INT = 8000; -- Tamaño del bloque.
declare @nTipoCallTotal int
set @packageData =''''
set @valdiate=0
set @nTipoCallTotal=0

if @action=1 begin      
if exists(select * from cccamps nolock where cam_bNew=1) begin
        set @valdiate=1
        Update ccCamps SET cam_bNew=0 Where cam_bNew=2
        Update ccCamps SET cam_bNew=2 Where cam_bNew=1
end     
select @valdiate as isUpdate
end
else if @action=2 begin         
if exists(select * from cccamps nolock where cam_bNew=3) begin
set @valdiate=1
        Update ccCamps SET cam_bNew=0 Where cam_bNew=4
        Update ccCamps SET cam_bNew=4 Where cam_bNew=3
end
select @valdiate as isUpdate
end
else if @action=3 begin         
SELECT User_id, TipoLlamadas FROM ccUsers WHERE User_ID = @userId
end
else if @action=4 begin 
SELECT A.Login, A.User_id, prioridad, skill, A.TipoLlamadas, C.cam_id, C.cam_descripcion, C.cli_id 
FROM ccCamps C JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id 
JOIN ccUsers A  ON A.User_id = CA.User_id 
AND A.TipoUser_Id =1 AND C.cam_id =  @camId
order by A.Login, A.User_id, CA.prioridad, CA.skill, C.cam_id
end
else if @action=5 begin 
SELECT Login, TipoLlamadas, User_id, password, Nombres +'' ''+ ApellidoPaterno FROM ccUsers nolock WHERE User_id = @userId
end
else if @action=6 begin 
SELECT Inbound_id, descripcion, cli_id FROM ccInbound nolock WHERE Inbound_id =@camId
end
else if @action=7 begin 
SELECT Inbound_id, descripcion, cli_id, tnotas, nMaxQue FROM ccInbound WHERE Inbound_id = @camId
end
else if @action=8 begin 
SELECT dni_id, dni_numero, T.tipodni_id, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join ccTipoDNIS T on D.tipodni_id = T.tipodni_id 
WHERE dni_id = @dnisId and dni_tipo=2
end
else if @action=9 begin 
SELECT dni_id, dni_numero, dni_tipo, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join ccTipoDNIS T on D.tipodni_id=T.tipodni_id 
WHERE dni_id = @dnisId and dni_tipo=2
end
else if @action=10 begin        
SELECT dni_id, dni_numero, D.tipodni_id, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join cctipoDnis TD on D.tipodni_id = TD.tipodni_id
WHERE dni_tipo=2
end
else if @action=11 begin        
SELECT Inbound_id, descripcion, tNotas, nMaxQue FROM ccInbound
end
else if @action = 12 begin 
; with WgUser AS(
select 
WG.IDWG,A.IdCampEsp,A.Tipo from ccRIAWorkGroupUsers WG
inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
inner join ccRIACampEspWG A on A.IDWG=WG.IDWG   
where WG.IDWG<>@WgId
)
, wGCamp AS(
select IDWG, IdCampEsp,Tipo from ccRIACampEspWG A
where A.IDWG in(select IDWG from WgUser) or A.IDWG=@WgId
), dataDiferent as
(
select distinct 
convert(varchar, A.IdCampEsp)+''-''+convert(varchar,A.Tipo+1)  
+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1)) 
+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))
as CampAndType
from wGCamp A
left join WgUser B on A.IdCampEsp=B.IdCampEsp and A.Tipo=B.Tipo 
left join ccCampsAgente campAgent on A.IdCampEsp = campAgent.cam_id and A.Tipo=1
left join ccInboundAgentes inboundAgent on A.IdCampEsp = inboundAgent.inbound_id and A.Tipo=0
where B.IdCampEsp is null
)
select @packageData=CampAndType+'',''+@packageData from dataDiferent    

select  @nTipoCallTotal = A.Tipo+1 +@nTipoCallTotal 
from ccRIAWorkGroupUsers WG
inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
inner join ccRIACampEspWG A on A.IDWG=WG.IDWG   
where WG.User_id=@userId
group by A.Tipo                 

;WITH BlockIndices AS (
        SELECT TOP ((LEN(@packageData) + @blockSize - 1) / @blockSize) -- Calcula cuántos bloques son necesarios.
                   (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) * @blockSize + 1 AS StartIndex
        FROM master.dbo.spt_values -- Usamos una tabla auxiliar para generar números.
)
SELECT                  
        convert(varchar(8000), SUBSTRING(@packageData, StartIndex, @blockSize)) AS packageData, @nTipoCallTotal as nTipoCallTotal
FROM BlockIndices
WHERE StartIndex <= LEN(@packageData); -- Asegúrate de no exceder la longitud.


end

else if @action = 13 begin 
; with WgCamp As(
select IDWG,IdCampEsp,tipo from ccRIACampEspWG A
where tipo=@tipo and IdCampEsp=@camId and IDWG<>@WgId
)
, WgUserCamp as(
select C.Login,WGUser.User_id,WgCamp.* from ccRIAWorkGroupUsers WGUser
inner join WgCamp on WGUser.IDWG=WgCamp.IDWG 
inner join ccUsers C on WGUser.User_id=C.User_id and C.TipoUser_id=1
), dataDiferent as(     

select distinct convert(varchar, WG.User_id)
+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1))
+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))        CampAndType
from ccRIAWorkGroupUsers WG     
inner join ccUsers C on WG.User_id=C.User_id and C.TipoUser_id=1
left join ccCampsAgente campAgent on campAgent.user_id=c.User_id
left join ccInboundAgentes inboundAgent on inboundAgent.User_id=c.User_id
where Wg.IDWG=@WgId and Wg.User_id not in(select User_id from WgUserCamp)
)

select @packageData=CampAndType+'',''+@packageData from dataDiferent 

-- Generar un rango de índices para dividir la cadena en bloques.
;WITH BlockIndices AS (
        SELECT TOP ((LEN(@packageData) + @blockSize - 1) / @blockSize) -- Calcula cuántos bloques son necesarios.
                   (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) * @blockSize + 1 AS StartIndex
        FROM master.dbo.spt_values -- Usamos una tabla auxiliar para generar números.
)
SELECT                  
        convert(varchar(8000), SUBSTRING(@packageData, StartIndex, @blockSize)) AS packageData
FROM BlockIndices
WHERE StartIndex <= LEN(@packageData); -- Asegúrate de no exceder la longitud.

end
else if @action = 14 begin --Delete WG
; with wgCam as (
select Value as camId,1 calltype from dbo.fn_RIASplitDelimited(@camIdOuts,'','')
union
select Value as camId,0 calltype from dbo.fn_RIASplitDelimited(@camIdIns,'','')
)
, relationUser as(

select campWg.IdCampEsp as camId,campWg.Tipo from ccRIAWorkGroupUsers WG
inner join ccRIACampEspWG campWg on campWg.IDWG=Wg.IDWG         
where WG.User_id=@userId
)
, dataDiferent  as
(       
select distinct convert(varchar, wgCam.camId)+''-''+convert(varchar,wgCam.callType+1)   as CampAndType
from wgCam
left join relationUser A on wgCam.camId=A.camId and wgCam.calltype=A.Tipo
where A.camId is null
)

select @packageData=CampAndType+'',''+@packageData from dataDiferent

select  @nTipoCallTotal = A.Tipo+1 +@nTipoCallTotal 
from ccRIAWorkGroupUsers WG
inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
inner join ccRIACampEspWG A on A.IDWG=WG.IDWG   
where WG.User_id=@userId
group by A.Tipo 

;WITH BlockIndices AS (
        SELECT TOP ((LEN(@packageData) + @blockSize - 1) / @blockSize) -- Calcula cuántos bloques son necesarios.
                   (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) * @blockSize + 1 AS StartIndex
        FROM master.dbo.spt_values -- Usamos una tabla auxiliar para generar números.
)
SELECT                  
        convert(varchar(8000), SUBSTRING(@packageData, StartIndex, @blockSize)) AS packageData, @nTipoCallTotal as nTipoCallTotal
FROM BlockIndices
WHERE StartIndex <= LEN(@packageData); -- Asegúrate de no exceder la longitud.

end
else if @action = 15 begin 
; with 
tempUserIds as(
        select cast(Value as int) as userId from dbo.fn_RIASplitDelimited(@userIds,'','')
), WgUser AS(
select distinct
u.UserId,
A.IdCampEsp,A.Tipo from ccRIAWorkGroupUsers WG
inner join ccRIACampEspWG A on A.IDWG=WG.IDWG
inner join tempUserIds u on u.userId=WG.User_id
where WG.IDWG<>@WgId
)
, wGCamp AS(
select u.userId, A.IdCampEsp,A.Tipo from ccRIACampEspWG A
cross join tempUserIds u
where A.IDWG=@WgId
)
, campData as(
select wg.* from wGCamp wg
left join WgUser w on wg.userId=w.userId and wg.IdCampEsp=w.IdCampEsp and wg.Tipo=w.Tipo
where w.IdCampEsp is null
)
, dataDiferent as(
select 
convert(varchar, A.userId)+''-''+
convert(varchar, A.IdCampEsp)+''-''+convert(varchar,A.Tipo+1)  
+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1)) 
+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))
as UserIdCampAndType
from campData A
left join ccCampsAgente campAgent on A.IdCampEsp = campAgent.cam_id and A.Tipo=1 and A.userId=campAgent.user_id
left join ccInboundAgentes inboundAgent on A.IdCampEsp = inboundAgent.inbound_id and A.Tipo=0 and A.userId=inboundAgent.user_id
)
select @packageData=UserIdCampAndType+'',''+@packageData from dataDiferent   

;WITH BlockIndices AS (
        SELECT TOP ((LEN(@packageData) + @blockSize - 1) / @blockSize) -- Calcula cuántos bloques son necesarios.
                   (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) * @blockSize + 1 AS StartIndex
        FROM master.dbo.spt_values -- Usamos una tabla auxiliar para generar números.
)
SELECT                  
        convert(varchar(8000), SUBSTRING(@packageData, StartIndex, @blockSize)) AS packageData
FROM BlockIndices
WHERE StartIndex <= LEN(@packageData); -- Asegúrate de no exceder la longitud.


end'
        EXEC(@sql);

set @process = 'Alter SP ccsp_RIAGetCampsNvosCB se quita la opcion ir al job para no tarde ya que no se utiliza ese dato'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0, @tcpa int=0
as
set nocount on

declare @TipoJobs as int,@isExecOutbound bit


set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

declare @id AS INTEGER

CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime)

create table #temccocallsoutsource (cam_id int,Pend  int)

create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

if @cam_id = 0 begin
if @user_id > 0 begin
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
        from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
        where user_id = @user_id and tipo = 1
end
else begin
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
        from ccCamps cam (nolock) join ccSupervisorCam supcam with(nolock) on tipo=1 and cam.cam_id  =  supcam.cam_id
end

end
else begin
if @Tipo = 2
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
        from ccCamps cam with(nolock)
        join ccSupervisorCam supcam with(nolock) on tipo=1 and cam.cam_id  =  supcam.cam_id
        where cam.cam_id = @cam_id
else
        if @user_id > 0 begin
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
        from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
        where user_id = @user_id and tipo = 1
        end
        else begin
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
        from ccCamps cam (nolock) join ccSupervisorCam supcam with(nolock) on tipo = 1 and cam.cam_id  =  supcam.cam_id
        where user_id = @user_id and cam_activo=1
        end
end



insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate)
select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate) from(
select A.*,dateUpdate from #Tcamps A
left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null)X
group by cam_id



if (select count(*) from #Tcamps2)>0 begin

insert into #temccocallsoutsource(cam_id,Pend)
SELECT ccos.cam_id, count(ccos.cam_id) as Pend
FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
WHERE cal_status in(0, 7)
GROUP BY ccos.cam_id

insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
SELECT A.cam_id,
count(case cal_status when 0 then 1 else null end) as New,
count(case cal_status when 1 then 1 else null end) as Cb,
count(case cal_status when 2 then 1 else null end) as Pro,
count(case cal_status when 3 then 1 else null end) as Fin
FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
join #Tcamps2 B on A.cam_id = B.cam_id
GROUP BY A.cam_id       


if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
        update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @cam_id
end       

declare @TotalNew table(
                cam_id int primary key,
                OverallTotalNew int 
        )

begin Tran updateccCampsNvosCB

        insert into @TotalNew
        select CampNvosCB.id,isnull(CampNvosCB.OverallTotalNew,CampNvosCB.new)  from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
        where CampNvosCB.id = tcamp.cam_id

        delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
        where CampNvosCB.id = tcamp.cam_id

        INSERT into ccCampsNvosCB 
        SELECT cams.cam_id, cams.cam_descripcion,
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
        LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
        LEFT JOIN @TotalNew  T on T.cam_id = cams.cam_id

COMMIT TRAN updateccCampsNvosCB
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
drop table #temccocallsoutsource
drop table #temWorkinTable

return(0)

end

set nocount off'
        EXEC(@sql)

  set @process = 'Alter Sp fn_RIASplitDelimited mejora performance'
        set @sql = 'ALTER FUNCTION [dbo].[fn_RIASplitDelimited]
(   
    @List NVARCHAR(max),
    @SplitOn NVARCHAR(3)
)
RETURNS @RtnValue TABLE (
    Id INT IDENTITY(1,1),
    Value NVARCHAR(255)
)
AS
BEGIN
    DECLARE @Pos INT = 1
    DECLARE @NextPos INT
    DECLARE @Fragment NVARCHAR(255)

    IF LEN(@List) = 0  -- Verificar si la lista está vacía y salir
        RETURN

    WHILE @Pos > 0
    BEGIN
        SET @NextPos = CHARINDEX(@SplitOn, @List, @Pos)
        
        IF @NextPos > 0
        BEGIN
            SET @Fragment = SUBSTRING(@List, @Pos, @NextPos - @Pos)
            IF LEN(@Fragment) > 0  -- Solo insertar si el fragmento tiene longitud
            BEGIN
                INSERT INTO @RtnValue (Value)
                VALUES (LTRIM(RTRIM(@Fragment)))
            END
            SET @Pos = @NextPos + 1
        END
        ELSE
        BEGIN
            SET @Fragment = SUBSTRING(@List, @Pos, LEN(@List) - @Pos + 1)
            IF LEN(@Fragment) > 0
            BEGIN
                INSERT INTO @RtnValue (Value)
                VALUES (LTRIM(RTRIM(@Fragment)))
            END
            SET @Pos = 0
        END
    END

    RETURN
END
'
        EXEC(@sql)        

	SET @process = 'update menus 12015,12017,12020,13000 '
    SET @sql = '
update ccMenus 
set release=''e9befc66956d7d9fd76131b32eb489783a31ee84a8ad9fde96e1d89b26627cac8fc4fa52f426845fa98a3f91eb0ff8041e6f05eb13fe339c90f00002d2d06235''
where type=3 and menu_id=12015


update ccMenus 
set release=''accb20a46285ea9856ace61e5e3ffd4582792fe13e066f048a0c3f937dc1daf96bdd2edb9f23d5b4b486f46011c61eb08915ca96b688576ca7a25b2b03170981862172d92a203b6c9051ce2f5670037d''
where type=3 and menu_id=12017


update ccMenus 
set release=''2605c8244920fb599fb936a4bf94521a7284d5e414815e8ef15fa8f6b0040db16a54ce29b02250a22a8cb87c41c6f3b30e3860a31b59d733442bb174a555b7b2''
where type=3 and menu_id=12020

update ccMenus 
set release=''d108a7f110b9d54d296cb729b6e11f92''
where type=3 and menu_id=13000

'
    EXEC(@sql)

--------------------------- End Jesus 125.20231211.0.20 ----------------------------------------------------------------------------------


	
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
