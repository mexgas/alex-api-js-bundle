CREATE PROCEDURE [dbo].[ccspADMaddConversationTweet]
		@action int,
		@inboundId int = null,
		@clientId varchar(255)= null,
		@isFinished bit = 0,
		@screenNameClient varchar(100) = null,
		@screenNameInbound varchar(100) = null,
		@meanContactTypeId smallint = null,
		@twitId varchar(255) = null,
		@conversationId bigint = null,
		@date datetime=null,
		@replayId varchar(255)=null,
		@tipoTwitId tinyint=1,
		@messageId bigint = null,
		@dispositionId smallint=0,
		@subDispositionId smallint=0,
		@tWrapUp int =0

		as
		set nocount on

		declare @ninteration int ,@messageOutTwitterId bigint
		declare @userId int
		declare @isEndConversation bit


		if @action = 1 begin --Revisa que exista la conversacion
			select @conversationId =  isnull(max(conversationTwitterId),0) from conversationTwitter where isFinished = 0 and meanContactTypeId = 2 and ClientId = @clientId and inboundId=@inboundId
			if @conversationId = 0
				select cast(0 as bigint) as Id
			else begin
				declare @closeConversation tinyint
				declare @tRsponse datetime
				select @tRsponse = isnull(max(tSend),getdate()) from messageOutTwitter where conversationTwitterId = @conversationId
				select @closeConversation = closeConversationTime from contactMeanIn where inboundId=@inboundId
				 if datediff(dd,getdate(),@tRsponse ) > @closeConversation
					select  cast(0 as bigint)  as Id
				else
					select @conversationId as Id
			end
		    return 0
		end
		else if @action = 2 begin --Nueva conversacion y mensaje entrada y salida
		    --agregar tabla de messagetwit fecha de descarga
			if @replayId is null or @replayId=''
				set @replayId= '0'
		    insert into conversationTwitter (inboundId,ClientId,isFinished,screenNameClient,screenNameInbound,meanContactTypeId,replayId)
		    values(@inboundId,@clientId,@isFinished,@screenNameClient,@screenNameInbound,@meanContactTypeId,@replayId)
		    set  @conversationId  = SCOPE_IDENTITY()
			insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
			set @messageId=SCOPE_IDENTITY()
			insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
			values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)
		    select 0 as LastUserId,@conversationId as Id, @messageId as MessageId
		    return 0
		end
		else if @action = 3 begin --Nuevo mensaje Entrada
			---Revisa que no se contesto el twitt
			select @messageOutTwitterId=max(A.messageOutTwitterId),@ninteration= count(B.messageInTwitterId)
			from messageOutTwitter A inner join messageInTwitter B on A.conversationTwitterId=B.conversationTwitterId
			where A.conversationTwitterId=@conversationId and A.messageStatusId not in (5,6,7,8,9,10,11)

			insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
			set @messageId=SCOPE_IDENTITY()

			if  @messageOutTwitterId is null begin
				insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
				values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)
				set @messageOutTwitterId=SCOPE_IDENTITY()
			end
			else begin
				update messageOutTwitter set messageInTwitterIdEnd=@messageId,[date]=@date,ninteration=@ninteration
				where messageOutTwitterId=@messageOutTwitterId
			end
			select @userId = userId  from messageOutTwitter with(nolock) where messageOutTwitterId=@messageOutTwitterId
			select @userId as LastUserId,@conversationId as Id, @messageId as MessageId
			return 0
		end
		else if @action = 4 begin --Obtiene el maximo messageOutTwitterId por conversacion
		    select @messageOutTwitterId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId
			select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
			select @messageOutTwitterId as messageOutTwitterId,@replayId as replayId
			return 0
		end
		else if @action = 5 begin --Ultimo mensaje en por ACD
		    select cast(isnull(max(twitId),0)as bigint) as Id, max(date) as Date from messageInTwitter as A
			inner join conversationTwitter as B on A.conversationTwitterId=B.conversationTwitterId
			where B.inboundId=@inboundId
			return 0
		end
		else if @action = 6 begin --Obtiene conversación dependiendo del replayId
			select @conversationId=conversationTwitterId  from messageOutTwitter where twitId=@replayId
			if @conversationId is not null begin
				select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
			end
			else begin
				select 0 as conversationId,'0' as replayId
			end
			select @conversationId as conversationId,@replayId as replayId
			return 0
		end

		set nocount off