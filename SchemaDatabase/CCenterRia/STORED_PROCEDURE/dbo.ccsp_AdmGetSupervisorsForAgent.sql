CREATE PROCEDURE  [dbo].[ccsp_AdmGetSupervisorsForAgent]
@chat_id int,@action int =1

AS
BEGIN

	SET NOCOUNT ON;

	declare @age_id int
	declare @conversationId int

	if @action=1 begin --Chat
		select @age_id = userId from ccRIAChats where chatId=@chat_id
	end
	else if @action =3 begin--Mail
		
		select @conversationId=conversationId from message where messageId=@chat_id
		select @chat_id=max(messageId) from message where conversationId=@conversationId and userId>0 
		select @age_id=userId from message where messageId=@chat_id
	end

	select distinct a1.user_id as agt, a5.user_id as sup, a5.login, a5.Nombres, a5.ApellidoPaterno, a5.ApellidoMaterno from ccusers a1 
	inner join ccriaworkgroupusers a2 on (a1.user_id=a2.user_id and tipouser_id=1)
	inner join 
	(select a3.user_id, a4.IDWG, a3.login, a3.Nombres, a3.ApellidoPaterno,a3.ApellidoMaterno  from ccusers a3 
	inner join ccriaworkgroupusers a4 on (a3.user_id=a4.user_id and (tipouser_id=2 or tipouser_id=6))) a5 on (a2.IDWG=a5.IDWG)
	where a1.user_id = @age_id
	order by a1.user_id,a5.user_id	
END