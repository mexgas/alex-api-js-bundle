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

		SET @process = 'Alter SP ccsp_ConversationWASave action 6 to save @IsTransfered'
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

		SET @process = 'Alter SP ccsp_ConversationWASaveOut action 6 to save @IsTransfered'
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
