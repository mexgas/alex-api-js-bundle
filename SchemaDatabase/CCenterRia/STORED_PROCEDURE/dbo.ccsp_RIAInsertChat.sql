CREATE PROCEDURE [dbo].[ccsp_RIAInsertChat]
@action int,
@inboundId smallint = 0,
@domain varchar(50) = '',
@session varchar(50) = '',
@tTimeout smallint = 0,
@chatId int = 0,
@status tinyInt = 0,
@userId smallint = 0,
@finished tinyInt = 0,
@chattingTime int = 0,
@startTime datetime = null,
@clientName varchar(50) = '',
@firstMessage int = 0,
@firstMessageTime datetime = null,
@crmNode xml = null,
@supervisor varchar(100) =null,
@template varchar (100)= null,
@ScoreTemplate int = null
AS

declare @xml xml
declare @sql nvarchar(2000)

if @action = 1 begin -- Inserta nuevo chat request /*comentario: se recomienda hacer la busqueda del userid del CRM en esta action*/
       insert into ccRIAChats (domain,session,chatStatus,requestDate,inboundId,clientName)
       values(@domain,@session,@status,getDate(),0,@clientName)
       set @chatId = scope_identity()
       select @chatId
end

else if @action = 2 begin -- Save Initial Info
update ccRIAChats set inboundId = @inboundId, chatStatus = @status, userId = @userId, tTimeout = @tTimeout where chatId = @chatId
end

else if @action = 3 begin -- Update Status
update ccRIAChats set chatStatus = @status where chatId = @chatId
end

else if @action = 4 begin -- Save Final Status
if @firstMessage = 0
       begin
             update ccRIAChats set finishedBy = @finished where chatId = @chatId
       end
else
       begin
             update ccRIAChats set finishedBy = @finished, firstMessageTime  = @firstMessageTime where chatId = @chatId
       end
end

else if @action in (5,6) begin -- Save Chatting Time /*comentario: la insercion del nodo (registro final para el finder) se recomiendo en esta action, no olvidar validar status = 4, finishedby != null y validar los tiempos para garantizar el dato final */
       if @action = 5 begin
             update ccRIAChats set tChatting = @chattingTime, chatDate = @startTime where chatId = @chatId
       end
	   set @crmNode = null

	   exec ccsp_CreateNodeMultimedia @conversationId=@chatId, @type=0,@xml=@xml OUTPUT,@supervisor=@supervisor,@template =@template,@ScoreTemplate=@ScoreTemplate

       if @xml is not null
       begin
             select @crmNode = node from ccCRMNodes where chatId = @chatId
             if @crmNode is not null
             begin
                    set @sql = N' set @xml.modify(''insert'++CONVERT(NVARCHAR(2000),@crmNode)+' into(/R01)[1]'') '
                    execute sp_executesql @sql,N'@xml XML Output,@crmNode XML',@xml OUTPUT,@crmNode
             end

             if not exists(select * from ccChatsNode where chatId=@chatId) begin ---insert finder
                insert into ccChatsNode (chatId,node, dateIn,[status]) values (@chatId,@xml, getdate(),0)
             end
             else begin ---update finder
				update ccChatsNode set [status] = 2, node =@xml  where chatId = @chatId
                --select @chatId
             end
       end
end