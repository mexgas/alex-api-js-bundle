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
SET @versionfix = 24
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
    	
------------------------------------------- BEGIN Isaac ----------------------------------------------------------
        

        SET @process = 'Alter SP ccsp_ConversationOutWASave'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationOutWASave] 
@action             INT
, @conversationId     INT         = 0
, @campId             INT         = NULL        
, @phoneCamp          VARCHAR(50) = NULL
, @clientId           VARCHAR(25) = NULL
, @conversationStatus SMALLINT    = 0
, @tChatting          FLOAT       = 0
, @tWrapUp            SMALLINT    = 0
, @finishedBy         TINYINT     = 0
, @onQueue            BIT         = NULL
, @tQueue             SMALLINT    = 0
, @tTimeout           INT         = 0
, @disposition        SMALLINT    = 0
, @subDisposition     SMALLINT    = 0
, @agentId            INT         = 0

AS
BEGIN
SET NOCOUNT ON;
                        
declare @conversationIdTemporal     INT;
declare @metaId int

IF @action = 1 BEGIN --new Conversation
select @phoneCamp= number from ccWhatsAppNumbers where camp_id= @campId
                            
if @phoneCamp is null or @phoneCamp='''' begin
    select @phoneCamp= number from ccMetawhatsAppNumbers where Cam_Id= @campId
    
end
if @phoneCamp is null or @phoneCamp='''' begin
    select 0 as [ConversationId],0 as [MessageId]
    return(0)
end

DECLARE @dateNow DATETIME;
SET @dateNow = DATEADD(HOUR, -23, GETDATE());


declare @existsConversationOut bit
declare @existsConversation bit
set @existsConversationOut =0
set @existsConversation =0

    
    
if not exists (select * from ccWhatsAppConversationsOut with(nolock) where
phoneCamp = @phoneCamp and clientId = @clientId and finishedBy=0 AND requestDate <= @dateNow) 
begin       
    set @existsConversationOut=0
end 
else begin
    set @existsConversationOut=1
    UPDATE ccWhatsAppConversationsOut
    SET finishedBy = 2 ,conversationStatus=17
    WHERE finishedBy = 0  AND requestDate <= @dateNow
    and phoneCamp = @phoneCamp and clientId = @clientId
end
    
if not exists (select * from ccWhatsAppConversations with(nolock) where
phoneACD = @phoneCamp and clientId = @clientId and finishedBy=0 AND requestDate <= @dateNow) 
begin       
    set @existsConversation=0
end 
else begin
    set @existsConversation=1
    UPDATE ccWhatsAppConversations
    SET finishedBy = 2 ,conversationStatus=17
    WHERE finishedBy = 0  AND requestDate <= @dateNow
    and phoneACD = @phoneCamp and clientId = @clientId
end
    
if not exists (select 1 from ccWhatsAppConversationsOut with(nolock) 
    where phoneCamp = @phoneCamp and clientId = @clientId 
    and finishedBy = 0 and requestDate > @dateNow) 
begin
    set @existsConversationOut=0
end
else begin
    set @existsConversationOut=1
end
    
if not exists (select 1 from ccWhatsAppConversations with(nolock) 
    where phoneACD = @phoneCamp and clientId = @clientId 
    and finishedBy = 0 and requestDate > @dateNow) 
begin
    set @existsConversation=0
end
else begin
    set @existsConversation=1
end
    
if @existsConversationOut=0
begin
    if @existsConversation = 0
    begin
        INSERT INTO [ccWhatsAppConversationsOut]
        ([camId] , [phoneCamp], clientId, conversationStatus, tChatting
        , tWrapUp, finishedBy, onQueue, tQueue, requestDate
        , tTimeout, disposition, subDisposition, agentId)
        VALUES(@campId, @phoneCamp, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, 
        @onQueue, @tQueue, GETDATE(), @tTimeout, @disposition, @subDisposition, @agentId);
                        
        SELECT @conversationIdTemporal = SCOPE_IDENTITY();    
        SELECT @conversationIdTemporal AS [ConversationId],0 as [MessageId]
    end
    else begin
        select A.descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, C.Login Username 
        ,B.conversationId as conversationIdExists
        FROM ccInbound A INNER JOIN ccWhatsAppConversations B WITH(NOLOCK)
        ON B.clientId = @clientId AND B.finishedBy = 0 and B.inboundId=A.Inbound_id
        INNER JOIN ccUsers C ON B.agentId = C.User_id;
    end  
end
else begin
    select A.cam_descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, C.Login Username
    ,B.conversationId as conversationIdExists
    FROM ccCamps A INNER JOIN ccWhatsAppConversationsOut B WITH(NOLOCK)
    ON B.clientId = @clientId AND B.finishedBy = 0 and B.camId=A.cam_id
    INNER JOIN ccUsers C ON B.agentId = C.User_id;
end  
END 
ELSE IF @action = 2 -- Get Outbound Templates
BEGIN
    
    DECLARE @AsociatedNumber VARCHAR(30) 
	SELECT @AsociatedNumber= number from ccWhatsAppNumbers WHERE @campId = camp_id
	if @AsociatedNumber is not null begin
		SELECT cast(TemplateId as bigint),Category,TemplateName,LanguageCode,Status,AsociatedNumber
		,[Type],[Format],Body, 0 IsMeta
		FROM ccWhatsAppOutboundTemplates WHERE AsociatedNumber = @AsociatedNumber AND Status = 1;
	end
	else begin
		SELECT @MetaId= MetaId from ccMetawhatsAppNumbers WHERE Cam_Id= @campId
		SELECT 
		cast(Id as bigint) as TemplateId,Category,TemplateName,LanguageCode as LanguageCode
		,A.StatusCW [Status],B.Number as AsociatedNumber, 1 IsMeta
		,''BODY'' [Type],''TEXT'' [Format],body as Body
		,header,footer
		FROM ccMetaWAOutboundTemplates  A 
		inner join ccMetawhatsAppNumbers B on A.MetaId=B.MetaId
		WHERE A.MetaId = @MetaId AND A.StatusCW = 1
		and A.body NOT LIKE ''%{{%'' 		AND A.body NOT LIKE ''%[[%''
		and A.[Status]=''APPROVED''
		;
	end
    
END
END
'
        EXEC(@sql);

        SET @process = 'Alter SP ccsp_ConversationWASave @action=12 update conversation last'
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

        SET @process = 'Alter SP ccsp_ConversationWASave @action=12 update conversation last'
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

        SET @process = 'Alter SP ccsp_WhatsAppUnsentMessages insert ccWhatsAppUnsentMessages'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_WhatsAppUnsentMessages]
@Option TINYINT = 0, 
@Message_uuid VARCHAR(150) = '''',
@ClientNumber VARCHAR(25) = '''', 
@VonageNumber VARCHAR(25) = '''', 
@Timestamp DATETIME = NULL,
@MessageType VARCHAR(50) = '''', 
@Content VARCHAR(MAX) = '''',
@MessagesList VARCHAR(max) = NULL,
@Status varchar(100)='''',
@Currency varchar(50)=''EUR'',
@Price varchar(14)=''0.0000'',
@Client_ref int=0
AS
SET NOCOUNT ON
if @Timestamp is null 
	set @Timestamp=GETUTCDATE()


IF @Option IS NOT NULL
BEGIN 
    IF  @Option = 0  -- Save Unsent Message
    BEGIN
        IF @Message_uuid IS NOT NULL AND NOT EXISTS (SELECT * FROM ccWhatsAppUnsentMessages WHERE Message_uuid = @Message_uuid)
        BEGIN
            INSERT INTO ccWhatsAppUnsentMessages(Message_uuid, ClientNumber, VonageNumber, Timestamp, MessageType, Content)
            VALUES(@Message_uuid, @ClientNumber, @VonageNumber, @Timestamp, @MessageType, @Content)
            SELECT 1
        END
        ELSE BEGIN SELECT 0 END
    END
    else IF  @Option = 1  -- Get Unsent Messages
    BEGIN
        SELECT TOP 100 *FROM ccWhatsAppUnsentMessages order by ClientNumber,Timestamp
    END
    else  IF  @Option = 2  -- Delete Unsent Message
    BEGIN
        DELETE UnsentMessages FROM ccWhatsAppUnsentMessages UnsentMessages
        INNER JOIN  dbo.fn_RIASplitDelimited(@MessagesList, ''|'') MessagesList
        ON UnsentMessages.Message_uuid = MessagesList.Value
    END
    else IF  @Option = 3  -- 
    BEGIN
        if @Content is not null or @Content<>'''' begin
            INSERT INTO ccWhatsAppUnsetMessagesMCSbyWebApi(Content)         VALUES(@Content)
        end
    END
    else IF  @Option = 4  -- 
    BEGIN
        select TOP 100 * from ccWhatsAppUnsetMessagesMCSbyWebApi
    END

    else IF  @Option = 5  -- 
    BEGIN
        DELETE UnsentMessages FROM ccWhatsAppUnsetMessagesMCSbyWebApi UnsentMessages
        INNER JOIN  dbo.fn_RIASplitDelimited(@MessagesList, ''|'') MessagesList
        ON UnsentMessages.Id = MessagesList.Value
    END
    else IF  @Option = 6  -- Save Unsent Message Status
    BEGIN       
        if NOT EXISTS (SELECT * FROM ccWhatsAppUnsetStatusMessages WHERE Message_uuid = @Message_uuid and Client_ref=@Client_ref) begin
            INSERT INTO ccWhatsAppUnsetStatusMessages(Message_uuid, ClientNumber, VonageNumber, Timestamp, MessageType,
            Status,Currency, Price, Client_ref, Content)
            VALUES(@Message_uuid, @ClientNumber, @VonageNumber, @Timestamp, @MessageType,@Status,@Currency,@Price, @Client_ref ,@Content)           
        end
        else begin
            update ccWhatsAppUnsetStatusMessages
            set Status=@Status,Currency=@Currency,Price=@Price,Timestamp=@Timestamp,Content=@Content
            where Message_uuid=@Message_uuid and Client_ref=@Client_ref
        end
    END
    else IF  @Option = 7  -- Save Unsent Message Status
    BEGIN       
        SELECT top 100 * FROM ccWhatsAppUnsetStatusMessages order by ClientNumber,Timestamp
    END
    else IF  @Option = 8  -- 
    BEGIN
        DELETE UnsentMessages FROM ccWhatsAppUnsetStatusMessages UnsentMessages
        INNER JOIN  dbo.fn_RIASplitDelimited(@MessagesList, ''|'') MessagesList
        ON UnsentMessages.Message_uuid = MessagesList.Value
    END
END

SET NOCOUNT OFF
'
        EXEC(@sql);

--------------------------- End Jesus 125.20231211.0.18 ----------------------------------------------------------------------------------
----------------------------------------------------------- Begin Luis Miguel Zamora Nuñez 125.20231211.0.19-------------------------------------------------------------------------

SET @process = 'K069001, K69003 - ccsp_GalateaCreateUser - SP Edited, Editado para corregir el registro de usuarios (Agentes y Administradores), 
Se asigna el LastName a @ApellidoPaterno = @LastName, y NombreOpcionalExtra a  @ApellidoMaterno = @NombreOpcionalExtra'
SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaCreateUser]
@UserId int,
@Login varchar(40),
@Nombres varchar(45),
@LastName varchar(45),
@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
@Password varchar(200),
@Sexo bit,
@canChangeStatus bit,
@AreaId int,
@UserType tinyint,
@AdminId int,
@NotificationEmail varchar(255)
AS
BEGIN


Declare @ApellidoMaterno varchar(45)
Declare @ApellidoPaterno varchar(45)

--Obtiene el idioma de de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

set @ApellidoPaterno = @LastName
set @ApellidoMaterno = @NombreOpcionalExtra

-- validaciones 
    if exists(select Login from ccUsers where Login=@Login)
    begin
    select -1 as ResponseCode--,Login en Uso
    return(0)
    end

    if exists(select Login from ccUsers_Consulta where Login = @Login)
    begin
    select -4 as ResponseCode -- Login en Uso aunque el usuario ya se halla borrado de la base de datos -- quiza falta la validacion cuando el usuario ya se ha borrado pero mediante borrado logico
    return(0)
    end

    if exists(select Nombres from ccUsers where Nombres=@Nombres
    and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
    begin
    select -2 as ResponseCode--,Nombre completo en Uso-- valida todos los campos de nombre para ver que no existan en la base de datos
    return(0)
    end


--insert
IF( select isnull(max(user_id),0) from ccusers) > 32700
BEGIN
    set @UserId = null
    SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
    LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
    INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
    FROM ccusers) AS w ON w.recID = d.recID

    if @UserId is null
    begin
    select -3 as ResponseCode --Error_when_inserting_user
    return(0)
    end

    set identity_insert ccusers on
        insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id, Status,TipoLLamadas,Sexo,canChangeStatus,IDArea,notificationEmail)
        select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end, @NotificationEmail
    set identity_insert ccusers off

    delete ccMenuUser where id_User = @UserId
    delete ccRIAUserRole where user_id = @UserId

    exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

    --Insert Agent into ccRIAAgentsPermissions
    IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
    BEGIN
    IF NOT EXISTS (SELECT * FROM ccRIAAgentsPermissions WHERE AgentId = @UserId)
    BEGIN 
            INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory, AllowReopenWAConversation, AllowTransferWAConversation)
            VALUES (@UserId, 0, 0, 1, 0, 0)
    END
    END

END
ELSE
BEGIN
    insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
        Status,TipoLLamadas,Sexo,canChangeStatus,IDArea,notificationEmail)
    select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
        1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end, @NotificationEmail

    if @@rowcount=1
    select @UserId=scope_identity()
    else
    begin
    select -2--insert Error
    return(0)
    end

    --INSERT INTO ACTIVITY LOG, CREATE AGENT
    DECLARE @areaName AS VARCHAR(40);
    DECLARE @userLogin AS VARCHAR(40);
    SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId);

    IF(@AreaId <> 0) BEGIN
        SET @areaName = (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId);
    END

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
    VALUES (CASE WHEN @AreaID = 0 THEN NULL ELSE @areaName END, getDate(), @userLogin, CASE WHEN @UserType = 1 THEN 22 ELSE 29 END, 3, '''', '''', @Login);

END
    insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
    insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
    insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
    --Menu para roles RepotsRia
    exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

    --Insert Agent into ccRIAAgentsPermissions
    IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
    BEGIN
    IF NOT EXISTS (SELECT * FROM ccRIAAgentsPermissions WHERE AgentId = @UserId)
    BEGIN 
            INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory, AllowReopenWAConversation, AllowTransferWAConversation)
            VALUES (@UserId, 0, 0, 1, 0, 0)
    END 
END
select 200 as ResponseCode -- indica que se agrego correctamente un nuevo usuario
END
'
EXEC(@sql)


SET @process = 'K069002, K069004 - ccsp_GalateaUpdateUser - SP Edited, 
Se asigna el LastName a @ApellidoPaterno = @LastName, y NombreOpcionalExtra a  @ApellidoMaterno = @NombreOpcionalExtra'
SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateUser]
@UserId int,
@Login varchar(40),
@Nombres varchar(45),
@LastName varchar(45),
@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
@Sexo bit,
@canChangeStatus bit,
@AdminId int,
@AreaId int,
@NotificationEmail varchar(255)
as

Declare @ApellidoMaterno varchar(45)
Declare @ApellidoPaterno varchar(45)
Declare @userIdOnDb int
Declare @LoginOnDb varchar(40)
--Obtiene el idioma de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

set @ApellidoPaterno = @LastName
set @ApellidoMaterno = @NombreOpcionalExtra

-- validaciones 
    if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
        begin
        select -5 as ResponseCode--,''el usuario no existe''
        return(0)
        end

  if exists(select Nombres from ccUsers where Nombres=@Nombres
  and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
    begin

        select @userIdOnDb =User_id from ccUsers where Nombres=@Nombres
      and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

        select @LoginOnDb =User_id from ccUsers where Nombres=@Nombres
      and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

      if @UserId <> @userIdOnDb and @Login <> @LoginOnDb
        begin
            select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
            return(0)
        end
    end

--update and insert into activity log a record for each modified property

    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId=@UserId, @userId= @userId

    Update ccUsers set 
    Nombres=@Nombres,
    ApellidoPaterno=@ApellidoPaterno,
    ApellidoMaterno=@ApellidoMaterno,
    Sexo=@Sexo,
        canChangeStatus=@canChangeStatus,
        notificationEmail=@NotificationEmail
    where User_id=@UserId

    DECLARE @CCUsersTable TABLE 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    INSERT INTO @CCUsersTable EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccUsers'', @columnNameId = ''User_id'', @valueId = @UserId, @userId = @userId;

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
        CASE WHEN (SELECT [TipoUser_id] FROM ccUsers WHERE User_id = @UserId) = 1 THEN 25 ELSE 32 END, 
        3, 
        CUT.identifierInfo,
        CASE WHEN CUT.identifierInfo IS NOT NULL THEN
            CASE 
                WHEN CUT.identifierInfo = ''T&EDIT_GENDER_USER'' THEN CONCAT(CUT.identifierInfo, CASE WHEN CUT.dataInfo = 1 THEN ''_M'' ELSE ''_F'' END)
                ELSE CUT.dataInfo END
        ELSE '''' END, 
        (SELECT [Login] FROM ccUsers WHERE User_id = @UserId)
    FROM @CCUsersTable AS CUT;

    EXEC InsertLogAdminGalatea @action=3, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId = @UserId, @userId = @userId

select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
'
EXEC(@sql)




SET @process = 'ccsp_GalateaLoadUsersForManagement - SP Edited, Editado para el envio correcto de datos al front.
Se asigna el LastName a @ApellidoPaterno = @LastName, y NombreOpcionalExtra a  @ApellidoMaterno = @NombreOpcionalExtra'
SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
 @option SMALLINT,
 @AreaId SMALLINT,
 @UserType INT = null,
 @Username VARCHAR(200)=null,
 @userId INT = 0
as

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
'
EXEC(@sql)
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
                        '' + @caseStatements + '';
                        '';

                        --print @sql
                        -- Ejecutar la consulta dinámica
                        EXEC sp_executesql @sql;
                END
                

                -- Avanzar al siguiente bloque
                SET @batch_id = @batch_id + 1;
        END

        -- Consultar el resultado final de cambios
        set @sql=''SELECT A.columnInfo,A.dataInfo,isnull(B.Identifiers,'''''''') as identifierInfo 
        FROM ''+@tableTemp+'' A 
        left join relationTableColumnIdentifiers B on A.columnInfo=B.colunName''
        
        --print @sql
        EXEC sp_executesql @sql;

end
else if @action =3 begin
        set @sql=''IF OBJECT_ID(N''''tempdb..''+@tableNameTmp+'''''') IS NOT NULL DROP TABLE ''+@tableNameTmp
        --print(@sql)
        exec(@sql)
end
        '
        EXEC(@sql);



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
