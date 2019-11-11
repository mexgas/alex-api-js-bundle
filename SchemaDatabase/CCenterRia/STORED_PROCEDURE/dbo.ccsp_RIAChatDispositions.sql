CREATE PROCEDURE [dbo].[ccsp_RIAChatDispositions]
@action smallint,
@chatId smallint,
@disposition smallint,
@subDisposition smallint,
@wrapUpTime smallint =0
as

if @action = 1 begin

update ccRIAChats set disposition = @disposition, subDisposition = @subDisposition, tWrapUp=@wrapUpTime where chatId = @chatId
declare @crmNode xml 
declare @xml xml
declare @sql nvarchar(2000)
set @crmNode = null

     exec ccsp_CreateNodeMultimedia @conversationId=@chatId, @type=0,@xml=@xml OUTPUT,@supervisor='',@template ='',@ScoreTemplate=''

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