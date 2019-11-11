CREATE PROCEDURE [dbo].[trsp_AdmSaveChatScoresFormaCalif]
@chat_id int,
@id_calificador int,
@id_supervisor int,
@id_formato int,
@total_forma int,
@age_id int,
@version int,
@typeServices tinyint =2

AS

BEGIN

SET NOCOUNT ON;

declare @cam_id int
if @typeServices = 2 begin
	select @cam_id= InboundId from ccriachats where chatId = @chat_id
end
else if @typeServices = 3 begin --Email
	select  @cam_id=min(B.inboundId) from message A
	inner join conversation B on A.conversationId=A.conversationId
	where A.conversationId=@chat_id
end
else if @typeServices = 4 begin --Twitter
	select  @cam_id=min(B.inboundId) from messageOutTwitter A
	inner join conversationTwitter B on A.conversationTwitterId=A.conversationTwitterId
	where A.conversationTwitterId=@chat_id
end

insert RIA_FORMACALIF (fecha_calif,id_calificador,id_supervisor,id_grabacion,id_formato,total_forma,age_id,version, tipo,cam_id)
values (GetDate(),@id_calificador,@id_supervisor,@chat_id,@id_formato,@total_forma,@age_id,@version, @typeServices,@cam_id)

select Scope_Identity()

END