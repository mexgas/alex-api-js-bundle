/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio Chagolla
Date: 2024/09/30
Description: Release 126.20241218.0.0
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
SET @version = 127 --**********actualizar a 124 sin fix
SET @versionfix = 0
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
        ------------------------------------------- BEGIN Isaac ----------------------------------------
        SET @process = 'CW-9079 DROP PROCEDURE ccsp_ConversationWASaveOut'
        SET @sql = '
        if exists (select * from sys.procedures where name = N''ccsp_ConversationWASaveOut'')
        begin
            DROP PROCEDURE ccsp_ConversationWASaveOut
        end'
        EXEC(@sql)

        SET @process = 'CW-9079 CREATE PROCEDURE ccsp_ConversationWASaveOut'
        SET @sql = '
CREATE PROCEDURE ccsp_ConversationWASaveOut @action             INT
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
	ELSE IF @messageStatus = ''rejected'' OR @messageStatus = ''error'' OR @messageStatus = ''hostError'' OR @messageStatus = ''clientError''
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
END;    
        '
        EXEC(@sql)

		SET @process = 'TT14496-Outbound-Inicio lento DROP PROCEDURE ccsp_CampHorario'
		SET @sql = '
		IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = N''ccsp_CampHorario'')
		BEGIN
			DROP PROCEDURE ccsp_CampHorario;
		END'
		EXEC(@sql)

		SET @process = 'TT14496-Outbound-Inicio lento CREATE PROCEDURE ccsp_CampHorario'
		SET @sql = '
CREATE PROCEDURE ccsp_CampHorario
@campId as int=null
AS
declare @horaUniversal datetime
declare @isShudulerLey bit, @valueShudulerLey varchar(max),@hourStart int,@hourEnd int,@minStart int,@minEnd int
declare @shourStart varchar(max),@shourEnd varchar(max),@revHorario bit
select @revHorario=valor from ccsettings where setting_id = 112
select @valueShudulerLey = valor from ccsettings where setting_id=166
select @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)) as int),@valueShudulerLey=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
if @valueShudulerLey='''' begin
 set @valueShudulerLey=''0|07:00|22:00''
 update ccsettings set valor=@valueShudulerLey where setting_id=166
end
if @isShudulerLey = 1 begin
 select @shourStart=substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)),@shourEnd=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
 select @hourStart=substring(@shourStart, 0, charindex('':'',@shourStart)),@minStart=substring(@shourStart, charindex('':'',@shourStart) + 1, len(@shourStart))
 select @hourEnd=substring(@shourEnd, 0, charindex('':'',@shourEnd)),@minEnd=substring(@shourEnd, charindex('':'',@shourEnd) + 1, len(@shourEnd))
end
else begin
 select @hourStart=0,@minStart=0,@hourEnd=23,@minEnd=59
end
SET DATEFIRST 1
set @horaUniversal = getutcdate()
select c.cam_id, h.horario_id,Descripcion, c.cam_tNoContesta,  -- Correccion del ticket TT14496
 case when HoraInicio>@hourStart then HoraInicio else @hourStart end HoraInicio,
 case when (horaInicio>@hourStart or (horaInicio=@hourStart and MinInicio>=@minStart) ) then MinInicio  else @minStart end MinInicio,
 case when horaFin<@hourEnd then horaFin else @hourEnd end HoraFin,
 case when ((horaFin < @hourEnd or (horaFin=@hourEnd and MinFin<=@minEnd) )) then MinFin  else @minEnd end MinFin,
 Lunes,Martes,Miercoles,Jueves,Viernes,Sabado,Domingo
 into #tempCampLaw
 from cchorarios h
 inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on h.horario_id = ccCampsHorarios.horario_id --and 
 inner join ccCamps c on c.cam_id=ccCampsHorarios.cam_id 
 where (@campId is null or @campId=0 ) or ccCampsHorarios.cam_id = @campId
select distinct cam_id, horario_id,HoraInicio,MinInicio,horaFin,MinFin into #tempCampLaw2 from
(
 select tz_id,
 dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
 datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora,
 datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
 datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
 from ccTimeZones
)zonas
inner join #tempCampLaw on
(
 (
  hora > HoraInicio OR  (hora = HoraInicio AND minuto >= MinInicio)
 )
 AND
 (
  hora < HoraFin  OR  (hora = HoraFin AND minuto <= (MinFin-cam_tNoContesta) )  -- Correccion del ticket TT14496
 )
 AND
 (
  Lunes  = dia or
  Martes *2 = dia or
  Miercoles*3 = dia or
  Jueves*4 = dia or
  Viernes*5 = dia or
  Sabado*6 = dia or
  domingo*7 = dia
 )
)
select distinct #tempCampLaw2.cam_id, #tempCampLaw2.horario_id id,
(HoraInicio*3600)+(MinInicio*60) ini,
(HoraFin*3600)+(MinFin*60) fin,
(case when HoraInicio<10 then ''0''+convert(varchar(2),HoraInicio) else convert(varchar(2),HoraInicio) end) + '':'' + (case when MinInicio<10 then ''0''+convert(varchar(2),MinInicio) else convert(varchar(2),MinInicio) end ) as HoraInicio ,
(case when HoraFin<10 then ''0''+convert(varchar(2),HoraFin) else convert(varchar(2),HoraFin) end) + '':'' + (case when MinFin<10 then ''0''+convert(varchar(2),MinFin) else convert(varchar(2),MinFin) end ) as HoraFin
into #tempCamp from #tempCampLaw2
;WITH tempCamp AS (
    SELECT DISTINCT #tempCampLaw2.cam_id, #tempCampLaw2.horario_id AS id,
        (HoraInicio * 3600) + (MinInicio * 60) AS ini,
        (HoraFin * 3600) + (MinFin * 60) AS fin,
        RIGHT(''0'' + CONVERT(VARCHAR(2), HoraInicio), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), MinInicio), 2) AS HoraInicio,
        RIGHT(''0'' + CONVERT(VARCHAR(2), HoraFin), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), MinFin), 2) AS HoraFin
    FROM #tempCampLaw2
),
OrderedIntervals AS (
    SELECT 
        cam_id,
        ini,
        fin,
        ROW_NUMBER() OVER (PARTITION BY cam_id ORDER BY ini) AS RowNum
    FROM tempCamp
),
MergedIntervals AS (
    SELECT 
        o1.cam_id,
        o1.ini,
        MAX(o2.fin) AS fin
    FROM OrderedIntervals o1
    LEFT JOIN OrderedIntervals o2
        ON o1.cam_id = o2.cam_id
        AND o2.ini <= o1.fin -- Verifica si los intervalos se solapan
    GROUP BY o1.cam_id, o1.ini
),
CleanedIntervals AS (
    SELECT 
        cam_id,
        ini,
        fin
    FROM (
        SELECT 
            cam_id,
            ini,
            fin,
            LAG(fin) OVER (PARTITION BY cam_id ORDER BY ini) AS PrevFin
        FROM MergedIntervals
    ) t
    WHERE PrevFin IS NULL OR ini > PrevFin -- Elimina duplicados y solapamientos residuales
)
SELECT 
    ci.cam_id,
    ci.ini,
    ci.fin,
    RIGHT(''0'' + CONVERT(VARCHAR(2), ci.ini / 3600), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), (ci.ini % 3600) / 60), 2) AS HoraInicio,
    RIGHT(''0'' + CONVERT(VARCHAR(2), ci.fin / 3600), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), (ci.fin % 3600) / 60), 2) AS HoraFin,
	c.cam_tNoContesta AS timeMaxContestacion  -- Correccion del ticket TT14496
FROM CleanedIntervals ci
INNER JOIN ccCamps c ON c.cam_id = ci.cam_id  -- Correccion del ticket TT14496
ORDER BY cam_id, ini;
drop table #tempCamp
drop table #tempCampLaw
drop table #tempCampLaw2
'
		EXEC(@sql)



        -------------------------------------------  END Isaac  ----------------------------------------

        -------------------------------------------  BEGIN David  ----------------------------------------
		SET @process = 'creación de índice IX_ccListaNegra_telefono_idtipolistapara tabla ccListaNegra'
        SET @sql = '
        IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = ''IX_ccListaNegra_telefono_idtipolista'' AND object_id = OBJECT_ID(''ccListaNegra''))
		BEGIN
			CREATE NONCLUSTERED INDEX IX_ccListaNegra_telefono_idtipolista
			ON ccListaNegra (idtipolista, telefono)
			INCLUDE (calKey);
		END'
        EXEC(@sql)

		SET @process = 'creación de índice IX_ccHistorialListaNegra_telefono_idtipolista tabla ccHistorialListaNegra'
        SET @sql = '
        IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = ''IX_ccHistorialListaNegra_telefono_idtipolista'' AND object_id = OBJECT_ID(''ccHistorialListaNegra''))
		BEGIN
			CREATE NONCLUSTERED INDEX IX_ccHistorialListaNegra_telefono_idtipolista
			ON ccHistorialListaNegra (idtipolista, telefono, idtipomov)
			INCLUDE (fecha);
		END'
        EXEC(@sql)

		SET @process = 'DROP PROCEDURE ccsp_GalateaAdminBlackListPhones'
        SET @sql = '
        if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminBlackListPhones'')
        begin
            DROP PROCEDURE ccsp_GalateaAdminBlackListPhones
        end'
        EXEC(@sql)

		SET @process = 'optimización de SP ccsp_GalateaAdminBlackListPhones'
        SET @sql = '
        CREATE PROCEDURE [dbo].[ccsp_GalateaAdminBlackListPhones]
			@type TINYINT,
			@idBlackList INT
		AS
		BEGIN
			SET NOCOUNT ON;
    
			IF(@type = 1)
			BEGIN
				;WITH PhoneCTE AS (
					SELECT 
						cln.telefono,
						cln.calKey,
						MAX(chln.fecha) AS fecha,
						COUNT(*) OVER (PARTITION BY cln.telefono) AS phone_count
					FROM dbo.ccListaNegra cln
					INNER JOIN dbo.ccHistorialListaNegra chln ON 
						chln.telefono = cln.telefono
						AND chln.idtipolista = cln.idtipolista
					WHERE 
						cln.idtipolista = @idBlackList
						AND chln.idtipolista = @idBlackList
						AND chln.idtipomov IN (1,7)
					GROUP BY 
						cln.telefono,
						cln.calKey
				)
				SELECT 
					p.telefono,
					ISNULL(
						CASE 
							WHEN p.phone_count > 1 THEN 
								(SELECT TOP 1 calKey 
								 FROM PhoneCTE 
								 WHERE telefono = p.telefono 
								 ORDER BY fecha ASC)
							ELSE p.calKey
						END, 
					'''') AS calKey,
					p.fecha
				FROM PhoneCTE p
				GROUP BY 
					p.telefono,
					p.calKey,
					p.fecha,
					p.phone_count
				ORDER BY 
					p.fecha DESC;
			END;
		END;'
        EXEC(@sql)

    SET @process = 'CW-9166 DROP PROCEDURE ccsp_WhatsAppConversationHistory'
    SET @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_WhatsAppConversationHistory'')
    begin
        DROP PROCEDURE ccsp_WhatsAppConversationHistory
    end'
    EXEC(@sql)

    SET @process = 'CW-9166 Se revisa si el mensaje´tiene tipo error al abrir conversación para que no se muetre en historial de agente'
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
		  AND wg.Tipo = (CASE 
							WHEN ((@InboundIdsLst IS NULL OR @InboundIdsLst = '''') AND (@OutboundIdsLst IS NULL OR @OutboundIdsLst = '''') AND (ISNULL(@ClientNumbersLst, '''') <> ''''))
							THEN wg.Tipo
							ELSE @CampType
						END)
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
			AND NOT (
				c.conversationStatus = 18
				AND EXISTS (  
					SELECT 1 
					FROM ccWAMessagesConversationsOut mo 
					WHERE mo.conversationId = c.ConversationId 
					GROUP BY mo.conversationId 
					HAVING COUNT(*) = 1 AND MAX(mo.messageStatus) = ''error''
				)
			)
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
				ci.descripcion AS CamName,
				c.phoneACD as CamNumber,
				g.graphic_id AS GraphicId,
				c.clientId AS ClientNumber,
				m.content AS MessageContent,
				m.typeMessage AS MessageType,
				m.TimeStampMessage AS LastMessageTimestamp,
				''Inbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn    
			FROM ccWhatsAppConversations c
			LEFT JOIN ccRIAInboundGraph g ON g.inbound_id = c.InboundId
			LEFT JOIN ccWAMessagesConversations m ON m.conversationId = c.ConversationId
			LEFT JOIN ccinbound ci ON ci.inbound_id = c.inboundid
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
				ca.cam_descripcion AS CamName,
				c.phoneCamp AS CamNumber,
				g.graphic_id AS GraphicId,
				c.clientId AS ClientNumber,
				m.content AS MessageContent,
				m.typeMessage AS MessageType,
				m.TimeStampMessage AS LastMessageTimestamp,
				''Outbound'' AS CampType,
				ROW_NUMBER() OVER (PARTITION BY c.ConversationId ORDER BY m.TimeStampMessage DESC) AS rn  
			FROM ccWhatsAppConversationsOut c
			LEFT JOIN ccRIACampsGraph g ON g.cam_id = c.camId
			LEFT JOIN ccWAMessagesConversationsOut m ON m.conversationId = c.ConversationId
			LEFT JOIN ccCamps ca ON ca.cam_Id = c.camid
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
				CamName,
				GraphicId,
				ClientNumber,
				MessageContent,
				MessageType,
				LastMessageTimestamp,
				CampType
			FROM LatestInboundMessages
			WHERE rn = 1
        
			UNION ALL
        
			SELECT 
				ConversationId,
				CampaignId,
				CamNumber,
				CamName,
				GraphicId,
				ClientNumber,
				MessageContent,
				MessageType,
				LastMessageTimestamp,
				CampType
			FROM LatestOutboundMessages
			WHERE rn = 1
		)

		SELECT conversationId AS ConversationId,
			   CampaignId AS CamId,
			   CamNumber AS CamNumber,
			   CamName AS CamName,
			   CAST(GraphicId AS SMALLINT) AS Frame,
			   ClientNumber AS ClientNumber,
			   MessageContent AS MessageContent,
			   MessageType AS MessageType,
			   CampType AS CamType,
			   LastMessageTimestamp AS LastMessageDateTime,
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
				SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversations WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(HOUR, -24, GETDATE());

				IF @ConversationCount >= @MaxWhatsAllowed
				BEGIN
					SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationResponse;
					RETURN(0);
				END
				SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
				RETURN(0);
			END
			ELSE 
			BEGIN
				SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
				RETURN(0);
			END
		END

		IF @CamType = 1
		BEGIN
			IF EXISTS (SELECT 1 FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @CamNumber AND ClientNumber = @ClientNumber AND @ActualTime <= DATEADD(HOUR, 24, FirstMessageDateFromAgent)) 
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM ccmetawhatsAppNumbers WHERE Number = @CamNumber AND Cam_Id = @CamId)  
				BEGIN
					SELECT ''CAMPAIGN_NUMBER_CHANGED'' AS ReopenConversationResponse;
					RETURN(0);
				END

				SELECT @MaxWhatsAllowed = a.maxWhatsOut FROM cccamps c INNER JOIN ccriacat_Areas a ON c.IDArea = a.IDArea WHERE c.cam_id = @CamId;
				SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversationsOut WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(HOUR, -24, GETDATE());

				IF @ConversationCount >= @MaxWhatsAllowed
				BEGIN
					SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationResponse;
					RETURN(0);
				END
				SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
				RETURN(0);
			END
			ELSE 
			BEGIN
				SELECT ''ENABLE_REOPEN_BUTTON'' AS ReopenConversationResponse;
				RETURN(0);
			END
		END
	END

		DECLARE @ConvId int;

	IF @Option = 9 -- Verificación al reabrir conversación
	BEGIN 
		DECLARE @ConversationWithinWindowTime BIT = 0;
		DECLARE @ReopenConversationButtonResponse VARCHAR(50);
		DECLARE @AgentName varchar(50);
		DECLARE @TimeThreshold DATETIME;
		SET @TimeThreshold = DATEADD(hour, -23, GETDATE());


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
			SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversations WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(hour, -24, GETDATE());

			IF @ConversationCount >= @MaxWhatsAllowed
			BEGIN
				SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationButtonResponse;
				RETURN(0);
			END

			IF @ReopenConversationButtonResponse = ''REOPEN_CONVERSATION_WITH_TEMPLATE''
			BEGIN
				IF EXISTS (SELECT 1 FROM ccoWhatsLogDials WITH (NOLOCK, INDEX(IX_TimeSpam_PhoneClient_PhoneWa)) WHERE TimeSpam >= @TimeThreshold AND PhoneWa = @CamNumber AND PhoneClient = @ClientNumber AND answered = 0)
				BEGIN
					SELECT ''CONVERSATION_SENT_IN_BULK_IN_COURSE'' AS ReopenConversationButtonResponse,
									   ''N/A'' AS AgentName;
					RETURN(0);
				END
			END

			SELECT @ReopenConversationButtonResponse AS ReopenConversationButtonResponse, ''N/A'' AS AgentName;
			RETURN(0);
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

			IF EXISTS (SELECT 1 FROM ccoWhatsLogDials WITH (NOLOCK, INDEX(IX_TimeSpam_PhoneClient_PhoneWa)) WHERE TimeSpam >= @TimeThreshold AND PhoneWa = @CamNumber AND PhoneClient = @ClientNumber AND answered = 0)
			BEGIN
				SELECT ''CONVERSATION_SENT_IN_BULK_IN_COURSE'' AS ReopenConversationButtonResponse,
				''N/A'' AS AgentName;
				RETURN(0);
			END

			SELECT @MaxWhatsAllowed = a.maxWhatsOut FROM cccamps c INNER JOIN ccriacat_Areas a ON c.IDArea = a.IDArea WHERE c.cam_id = @CamId;
			SELECT @ConversationCount = COUNT(*) FROM ccwhatsappconversationsOut WHERE agentID = @AgentId AND conversationStatus = 2 AND requestDate >= DATEADD(hour, -24, GETDATE());

			IF @ConversationCount >= @MaxWhatsAllowed
			BEGIN
				SELECT ''MAX_LIMIT_CONVERSATION_ALLOWED'' AS ReopenConversationButtonResponse;
				RETURN(0);
			END

			SELECT @ReopenConversationButtonResponse AS ReopenConversationButtonResponse, ''N/A'' AS AgentName;
			RETURN(0);
		END
	END 

	IF @Option = 10 -- Creación de conversationId de entrada 
	BEGIN 
		EXEC ccsp_ConversationWASave @action=1, @phoneacd=@CamNumber, @clientid= @ClientNumber, @inboundid=@CamId, @agentId = @agentId, @IsReopenedConversation = 1, @conversationstatus=2

	END 

	IF @Option = 11 -- Creación de conversationId de salida
	BEGIN
		EXEC ccsp_ConversationOutWASave @action=1, @phoneCamp=@CamNumber, @clientid= @ClientNumber, @campId=@CamId, @agentId = @agentId, @conversationstatus=2
	END'
    EXEC(@sql)

	SET @process = 'CW-9242 DROP PROCEDURE ccsp_GalateaAreas'
    SET @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_GalateaAreas'')
    begin
        DROP PROCEDURE ccsp_GalateaAreas
    end'
    EXEC(@sql)

    SET @process = 'CW-9242 Se crea tabla temporal #CCAreasTable para insertar los registros que se insertarán en el log de actividad'
    SET @sql = '
		CREATE procedure [dbo].[ccsp_GalateaAreas] 
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
            END --  exec ccsp_GalateaAreas @option=5,@IDArea=1,@Descripcion=NULL,@maxMails=NULL,@maxChats=NULL,@maxWhats=NULL,@maxWhatsOut=NULL,@callWhileChat=1,@callWhileEmail=1,@callWhileWhatsAppIn=0,@callWhileWhatsAppOut=0,@defCampaing=NULL,@movesfromArea=0,@userId=17,@toolsTransfer=3;
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

						CREATE TABLE #CCAreasTable 
					(
						columnInfo VARCHAR(255),
						dataInfo VARCHAR(255),
						identifierInfo VARCHAR(255)
					);  

                    update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),maxWhats=isnull(@maxWhats,maxWhats),maxWhatsOut=isnull(@maxWhatsOut,maxWhatsOut),callWhileChat=isnull(@callWhileChat,callWhileChat),callWhileEmail=isnull(@callWhileEmail,callWhileEmail),callWhileWhatsAppIn=isnull(@callWhileWhatsAppIn,callWhileWhatsAppIn),callWhileWhatsAppOut=isnull(@callWhileWhatsAppOut,callWhileWhatsAppOut),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=case when @toolsTransfer = 3 then ToolsTransfer else @toolsTransfer end where IDArea=@IDArea

                   EXEC InsertLogAdminGalatea @action=2, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId, @tableTemp=''#CCAreasTable'';

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
                    FROM #CCAreasTable AS AT;

                    EXEC InsertLogAdminGalatea @action=3, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

					IF OBJECT_ID(N''tempdb..#CCUsersTable'') IS NOT NULL DROP TABLE #CCUsersTable

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


	SET @process = 'CW-9242 DROP PROCEDURE InsertLogAdminGalatea'
    SET @sql = '
    if exists (select * from sys.procedures where name = N''InsertLogAdminGalatea'')
    begin
        DROP PROCEDURE InsertLogAdminGalatea
    end'
    EXEC(@sql)

    SET @process = 'CW-9242 Se quita reinserción de registros innecesarios en tabla para evitar duplicidad de registros en historial de actividad'
    SET @sql = '
	CREATE PROCEDURE [dbo].[InsertLogAdminGalatea]
    @action INT,
    @tableName VARCHAR(255),
    @columnNameId VARCHAR(255),
    @valueId VARCHAR(255),
    @userId INT,
    @tableTemp VARCHAR(255) = NULL
	AS
	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX);
	DECLARE @tableNameTmp VARCHAR(255) = ''##'' + @tableName + ''_'' + CONVERT(VARCHAR(10), @userId);

	IF @action = 1
	BEGIN
		SET @sql = ''IF OBJECT_ID(N''''tempdb..'' + @tableNameTmp + '''''') IS NOT NULL DROP TABLE '' + @tableNameTmp + '';
					SELECT * INTO '' + @tableNameTmp + '' FROM '' + @tableName + '' WHERE '' + @columnNameId + '' = '' + @valueId;
		EXEC(@sql);
	END
	ELSE IF @action = 2
	BEGIN
		DECLARE @columns NVARCHAR(MAX) = '''';
		DECLARE @conditions NVARCHAR(MAX) = '''';
		DECLARE @caseStatements NVARCHAR(MAX) = '''';
		DECLARE @batchSize INT = 10;
		DECLARE @counter INT = 0;
		DECLARE @emtpy VARCHAR(2) = '''';

		DECLARE @BatchColumns TABLE (
			name NVARCHAR(128),
			batch_id INT
		);

		INSERT INTO @BatchColumns (name, batch_id)
		SELECT 
			name,
			(ROW_NUMBER() OVER (ORDER BY column_id) - 1) / @batchSize AS batch_id
		FROM sys.columns
		WHERE object_id = OBJECT_ID(@tableName)
		  AND name <> @columnNameId
		  AND name <> ''rowguid'';

		DECLARE @BatchIds TABLE (
			batch_id INT PRIMARY KEY
		);

		INSERT INTO @BatchIds
		SELECT DISTINCT batch_id FROM @BatchColumns;

		DECLARE @batch_id INT = 0;

		WHILE EXISTS (SELECT 1 FROM @BatchIds WHERE batch_id = @batch_id)
		BEGIN
			SET @caseStatements = '''';
			SET @conditions = '''';

			SELECT @caseStatements = @caseStatements + 
				''SELECT '''''' + name + '''''' AS columnInfo, CONVERT(VARCHAR(300), A.'' + QUOTENAME(name) + '') AS dataInfo '' +
				''FROM '' + @tableName + '' AS A '' +
				''FULL OUTER JOIN '' + @tableNameTmp + '' AS B ON A.'' + QUOTENAME(@columnNameId) + '' = B.'' + QUOTENAME(@columnNameId) + '' '' +
				''WHERE A.'' + QUOTENAME(name) + '' <> B.'' + QUOTENAME(name) + '' UNION ALL ''
			FROM @BatchColumns
			WHERE batch_id = @batch_id;

			SET @caseStatements = LEFT(@caseStatements, LEN(@caseStatements) - LEN('' UNION ALL ''));
        
			IF @caseStatements <> ''''
			BEGIN
				SET @sql = ''INSERT INTO '' + @tableTemp + '' (columnInfo, dataInfo)
							'' + @caseStatements;
				EXEC sp_executesql @sql;
			END

			SET @batch_id = @batch_id + 1;
		END

		SET @sql = ''
		IF OBJECT_ID(''''tempdb..#Temp2'''') IS NOT NULL DROP TABLE #Temp2;

		SELECT DISTINCT A.columnInfo, A.dataInfo, ISNULL(B.Identifiers, '''''' + @emtpy + '''''') AS identifierInfo
		INTO #Temp2
		FROM '' + @tableTemp + '' A
		LEFT JOIN relationTableColumnIdentifiers B
		  ON A.columnInfo = B.colunName
		 AND B.tableName = '''''' + @tableName + '''''';

		TRUNCATE TABLE '' + @tableTemp + '';

		INSERT INTO '' + @tableTemp + '' (columnInfo, dataInfo, identifierInfo)
		SELECT columnInfo, dataInfo, identifierInfo FROM #Temp2;

		DROP TABLE #Temp2;
		'';
		EXEC sp_executesql @sql, N''@emtpy VARCHAR(2)'', @emtpy = @emtpy;
	END
	ELSE IF @action = 3
	BEGIN
		SET @sql = ''IF OBJECT_ID(N''''tempdb..'' + @tableNameTmp + '''''') IS NOT NULL DROP TABLE '' + @tableNameTmp;
		EXEC(@sql);
	END'
    EXEC(@sql)
		-------------------------------------------  END David  ------------------------------------------

SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccCamps_IA'
        SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccCamps_IA'' and parent_id = OBJECT_ID(N''ccCamps''))
begin      
        drop trigger [tg_ccCamps_IA]    
end';
        EXEC(@sql);

        SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccoCallsOutSource_IA'
        SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccoCallsOutSource_IA'' and parent_id = OBJECT_ID(N''ccoCallsOutSource''))
begin 
        drop trigger [tg_ccoCallsOutSource_IA]    
end';
        EXEC(@sql);

        SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccoCallsOut_IA'
        SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccoCallsOut_IA'' and parent_id = OBJECT_ID(N''ccoCallsOut''))
begin      
        drop trigger [tg_ccoCallsOut_IA]    
end';
        EXEC(@sql);

        SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccoLogDials_IA'
        SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccoLogDials_IA'' and parent_id = OBJECT_ID(N''ccoLogDials''))
begin 
        drop trigger [tg_ccoLogDials_IA]    
end';
        EXEC(@sql);

        SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccUsersTmp_IA'
        SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccUsersTmp_IA'' and parent_id = OBJECT_ID(N''ccUsers''))
begin 
        drop trigger [tg_ccUsersTmp_IA]    
end
';
        EXEC(@sql);

        SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccRIALoading_IA'
        SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccRIALoading_IA'' and parent_id = OBJECT_ID(N''ccRIALoading''))
begin 
        drop trigger [tg_ccRIALoading_IA]    
end
';
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
