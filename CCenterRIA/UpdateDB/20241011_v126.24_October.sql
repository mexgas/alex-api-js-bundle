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

		SET @process = 'Alter SP ccsp_MultimediaCommon'
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
				   @isMeta AS IsMeta
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
    @SplitOn NVARCHAR(20)
)
RETURNS @RtnValue TABLE (
    Id INT IDENTITY(1,1),
    Value NVARCHAR(MAX)
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

    ----------------------------------------------------------- Begin Luis Miguel Zamora Nuñez 125.20231211.0.19-------------------------------------------------------------------------


    SET @process = 'DEV2-683 - drop sp ccsp_GalateaCreateUser'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_GalateaCreateUser'')
    BEGIN
        DROP PROCEDURE ccsp_GalateaCreateUser;
    END
    '
	EXEC(@sql)

	SET @process = 'DEV2-683 - create sp ccsp_GalateaCreateUser'
	SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaCreateUser]
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
        select -1 as ResponseCode--,''Login en Uso''
        return(0)
    end

    if exists(select Login from ccUsers_Consulta where Login = @Login)
    begin
        select -4 as ResponseCode -- ''Login en Uso aunque el usuario ya se halla borrado de la base de datos'' -- quiza falta la validacion cuando el usuario ya se ha borrado pero mediante borrado logico
        return(0)
    end

    if exists(select Nombres from ccUsers where Nombres=@Nombres
    and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
    begin
        select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
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

		set @process = 'Alter sp ccsp_GalateaUpdateUser'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateUser]
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
