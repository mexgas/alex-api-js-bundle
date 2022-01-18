CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon]
		@Option AS SMALLINT,
		@inboundId AS SMALLINT = 0,
		@conversationId AS INT = 0,
		@ServiceType AS SMALLINT = 0,
		@status as SMALLINT =0,
		@messagesList as varchar(max) = ''
		AS
		BEGIN
		    SET NOCOUNT ON;

		    IF(@Option = 1)
				BEGIN

					 SELECT --inbound.chat AS ServiceType,
					   CAST(inbound.Inbound_id AS INT) AS ACDId,
					   inbound.descripcion AS ACDName,
					   ISNULL(configuration.conexionInfo, '') AS PhoneACD,
					   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
					   inbound.tNotas AS WrapUpTime

					   FROM  ccInbound inbound
					   INNER JOIN  contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId
				END

			IF(@Option = 2)
				BEGIN
					SELECT
						cast(i.chat as int) AS ServiceType,
						cast(c.conversationId as int) as ConversationID,
						c.clientId as ClientId,
						cm.conexionInfo as [To],
						cast(i.Inbound_id as int) as ACDId,
						i.descripcion as ACDName,
						cast(g.graphic_id as int) as ACDGraphicId,
						cast(cm.closeConversationTime as int) as [TimeOut],
						cast(cm.answerTimeOut as int) as [TimeOutWarning],
						i.ExitWrapUpDisposition as [ExitWrapUpDisposition],
						i.tNotas as [WrapUpTime],
						i.ShowCalifWnd,
						cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient]
					FROM  ccInbound i
						INNER JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId
						INNER JOIN ccWhatsAppConversations c ON (c.inboundId = i.Inbound_id and c.conversationId = @conversationId)
						INNER JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
					WHERE i.chat = @ServiceType and i.Inbound_id = @inboundId
				END
			IF(@Option = 3)
				BEGIN
					 SELECT
					   CAST(inbound.Inbound_id AS INT) AS ACDId,
					   inbound.descripcion AS ACDName,
					   ISNULL(configuration.conexionInfo, '') AS PhoneACD,
					   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
					   inbound.tNotas AS WrapUpTime

					   FROM  ccInbound inbound
					   INNER JOIN  contactMeanIn configuration ON (inbound.Inbound_id = configuration.inboundId and inbound.Inbound_id = @inboundId)
				END
			IF(@Option = 4)
			Begin

				declare @pathFile as varchar(max)
				declare @filetype as varchar(5)
				DECLARE @mensajes TABLE(idMessage VARCHAR(100));

				insert into @mensajes
				select value from dbo.fn_RIASplitDelimited(@messagesList,',')


				select @pathFile = valor from ccSettings where setting_id=230
				select
					messageId as MessageId,
					messageStatus as Status,
					originType as Origin,
					case when originType ='Client' then 3
						 when originType ='Agent' then 2
						 when originType ='Admin' then 1
					else 0 end as OriginType,
					timeStampMessage as [Timestamp],
					case when typeMessage <> 'text'  then '' else content end as Content,
					typeMessage as Type,
					case when typeMessage not in( 'text' ,'location') then content else '' end as Caption,
					case when typeMessage = 'text' or typeMessage = 'location' then '' else @pathFile +char(92)+cast(conversationId/1000 as varchar(30))+char(92)+cast(conversationId as varchar(20))+char(92)+ typeMessage + char(92)+ messageId +'.'+
					case
						when typeMessage = 'video' then 'mp4'
						when typeMessage = 'image' then 'jpg'
						when typeMessage = 'audio' then 'mp3'
						when typeMessage = 'file' then (select substring(content, CHARINDEX('.',content)+1, len(content)))
						else '' end
					end as [Url],
					case when typeMessage = 'location'
					then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,'|') where id = 1),':') where id=2) else '' end as [Address],
					case when typeMessage = 'location'
					then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,'|') where id = 2),':') where id=2) else '' end as [Lat],
					case when typeMessage = 'location'
					then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,'|') where id = 3),':') where id=2) else '' end as [Long],
					case when typeMessage = 'location'
					then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,'|') where id = 4),':') where id=2) else '' end as [Name],
					case when typeMessage = 'location'
					then 'https://www.google.com/maps/search/' + (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,'|') where id = 2),':') where id=2) + ',' +
						(select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,'|') where id = 3),':') where id=2) else '' end as [LocationURL]
				 from ccWAMessagesConversations where messageId in (select idMessage from @mensajes)
				 order by Timestamp asc

			End
			
			IF(@Option = 5)
			BEGIN
				SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
				 FROM contactMeanIn
				WHERE inboundId = @inboundId
			END
		END