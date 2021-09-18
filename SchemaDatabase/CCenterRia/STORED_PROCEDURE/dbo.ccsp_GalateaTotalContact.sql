create PROCEDURE ccsp_GalateaTotalContact
 @option int, 
 @agent_id  int = 0
AS BEGIN
	declare @dateStart datetime
	set @dateStart =convert(date,getdate())

	IF(@option = 1)
	BEGIN
		declare @outbound int = 0 , @inboud int = 0 , @twiter int = 0 , @email int = 0 , @whatsapp int = 0 , @chat int = 0 
		select @outbound = count(cal_id)
			from ccoCallsOut with(nolock) where cal_inicio>@dateStart and User_id = @agent_id and statusCall_id = 13
		select @inboud = count(cal_id)
			from ccCallsIn  with(nolock) where cal_inicio>@dateStart and User_id = @agent_id and statusCall_id = 13
		select @chat = count(chatId)
			from ccRIAChats  with(nolock) where requestDate>@dateStart and userId = @agent_id

		SELECT @agent_id AgentId, @outbound Outbound, @inboud Inbound, @chat Chat, @email Email, @whatsapp Whatsapp, @twiter Twitter
	END
	
	IF(@option = 2)
	BEGIN
		select CAST(User_id as INT) AgentId,count(*) Count,'OUTBOUND' as media from ccoCallsOut with(nolock) where cal_inicio>@dateStart  and statusCall_id = 13 group by User_id
		union
		select CAST(User_id as INT) AgentId, count(*) Count,'INBOUND' from ccCallsIn with(nolock) where cal_inicio>@dateStart and statusCall_id = 13  group by User_id
		union
		select CAST(userId as INT) AgentId, count(*) Count,'CHAT' from ccRIAChats with(nolock) where requestDate>@dateStart and userId>0 group by userId
	END
END