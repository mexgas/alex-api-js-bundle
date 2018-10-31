/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Daniel Vega
Date: 2018/10/29
Description:
	CW-2257
Database: CCenterRia
Required version: 120.34

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120--**********actualizar a 120 sin fix
set @versionfix = 34
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;


if  @actualVersion = @version and  @actualVersionFix = 34
	begin
		begin tran
		begin try

	   set @process = 'CW-2428 Alter Lenght Column conversation.mailClient'
       set @Sql= 'alter table conversation alter column mailClient varchar(255) not null'
       EXEC(@Sql)

       set @process = 'CW-2428 Alter SP ccsp_CreateNodeMultimedia'
       set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_CreateNodeMultimedia]
@conversationId bigint,
@xml xml OUTPUT,
@supervisor varchar(255)='''',
@template varchar (255)='''',
@ScoreTemplate int=0,
@type int =1--1 EMAIL , 2 Twitter
AS
BEGIN
declare @info varchar(255)
declare @infoEscape varchar(max)
declare @charEscape varchar(255),@charReplace varchar(max)
set @charEscape=''"|''''''''|<|>|&''
set @charReplace=''&quot;|&apos;|&lt;|&gt;|&amp;''

declare @existAttached bit,@numInteracion smallint
if @type=0 begin--CHAT

    select @xml = convert(xml,''<R01 CDATE="''+rtrim(ltrim(convert(varchar(23), isNull(chatDate,requestDate), 126))) +
    ''" C01="''+convert(varchar(max),chatId) +
    ''" C02="''+convert(varchar(max),isnull(ccinbound.descripcion,'''')) +
    ''" C03="''+convert(varchar(max),domain) +
    ''" C04="''+convert(varchar(max), Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno ) +
    ''" C05="''+convert(varchar(max),tchatting) +
    ''" C06="''+convert(varchar(max),isnull(cctipocalif.[Description],''N/A'')) +
    ''" C07="''+convert(varchar(max),isnull(cctipocalifsub.califSubdesc,''N/A'')) +
    ''" C08="''+convert(varchar(max),clientname) +
    ''" C09="''+rtrim(ltrim(convert(varchar(23), chatDate, 126))) +
    ''" C10="''+convert(varchar(max),isnull(@supervisor,'''') ) +
    ''" C11="''+convert(varchar(max),isnull(@template,'''') )  +
    ''" C12="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +
    ''" C13="''+convert(varchar(max),isnull(ccusers.[Login],'''')) + ''"/>'')
    from ccRIAChats
    left outer join ccinbound on ccinbound.inbound_id = ccRIAChats.inboundid
    left outer join ccusers on ccusers.user_id = ccRIAChats.userid
    left outer join cctipocalif on cctipocalif.calif_id = ccRIAChats.disposition
    left outer join cctipocalifsub on cctipocalifsub.califsub_id = ccRIAChats.subdisposition and ccRIAChats.subdisposition <> 0
    where chatId = @conversationId and chatStatus = 4 and requestDate is not null and chatDate is not null

end
else if @type=1 begin--EMAIL
    SELECT @existAttached = case when count(*)>0 then 1 else 0 end
    from attached where messageId in (select messageId from message where conversationId=@conversationId)
    select @numInteracion = count(*) from message where conversationId=@conversationId
    --Replaza los caracteres por los comunes
    select @info=info from conversation where conversationId=@conversationId
    select @info=replace(@info,A.Value,B.Value) from dbo.fn_RIASplitDelimited(@charEscape,''|'') A
    inner join dbo.fn_RIASplitDelimited(@charReplace,''|'') B on A.Id=B.Id


    select @xml = convert(xml,''<R03 CDATE="''+ rtrim(ltrim(convert(varchar(23), isnull(max(b.tsend), getdate()), 126))) +
    ''" C01="''+ convert(varchar(max),a.conversationId) +
    ''" C02="''+ rtrim(ltrim(convert(varchar(23), isnull(max(b.tsend), getdate()), 126))) +
    ''" C03="''+ convert(varchar(max),max(c.descripcion)) +
    ''" C04="''+ convert(varchar,max(isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno,''''))) +
    ''" C05="''+ convert(varchar,max(isnull(cctipocalif.[Description],''N/A''))) +
    ''" C06="''+ convert(varchar,max(replace(replace(a.mailClient,''<'','' ''),''>'','' ''))) +
    ''" C07="''+ convert(varchar(max),sum(b.tRetention+b.tResponse+b.tWrapup)) +
    ''" C08="''+ convert(varchar(max),min(isnull(@info,''''))) +
    ''" C09="''+ convert(varchar(max),max(b.messageStatusid) ) +''" C10="''+  convert(varchar(max), isnull(@numInteracion,0)) +
    ''" C11="''+ convert(varchar(max),@existAttached) +''" C12="''+ convert(varchar(max),isnull(@supervisor,'''') ) +
    ''" C13="''+ convert(varchar(max),isnull(@template,'''') )  +''" C14="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +
    ''" C15="''+ convert(varchar,max(isnull(cctipocalifsub.califSubdesc,''N/A''))) +
    ''" C16="''+ convert(varchar(max),isnull(max(d.[Login]),'''')) + ''"/>'')
    from conversation a
    inner join message b on a.conversationid=b.conversationid
    left outer join ccinbound c on c.inbound_id = a.inboundid
    left outer join ccusers d on d.user_id = b.userid
    left outer join relationmessageDisposition e on e.messageId=b.messageId
    left outer join cctipocalif on cctipocalif.calif_id = e.dispositionId
    left outer join cctipocalifsub on cctipocalifsub.califsub_id = e.subdispositionId and e.subdispositionId <> 0
    where a.conversationId=@conversationId
    group by a.conversationId,a.inboundid

end
else if @type=2 begin--Twitter
    select @numInteracion = sum(ninteration) from messageOutTwitter where conversationTwitterId=@conversationId

    select @xml = convert(xml,''<R04 CDATE="''+rtrim(ltrim(convert(varchar(23), min(b.date), 126))) +
    ''" C01="''+convert(varchar(max),a.conversationTwitterId) +
    ''" C02="''+rtrim(ltrim(convert(varchar(23), min(b.date), 126))) +
    ''" C03="''+convert(varchar(max),max(c.descripcion)) +
    ''" C04="''+ convert(varchar,max(isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno,''''))) +
    ''" C05="''+convert(varchar,max(isnull(cctipocalif.[Description],''N/A''))) +
    ''" C06="''+ max(a.screenNameClient) +
    ''" C07="''+convert(varchar(max),sum(b.tRetention+b.tResponse+b.tWrapup)) +
    ''" C08="''+ max(a.screenNameInbound) +
    ''" C09="''+convert(varchar(max),max(b.messageStatusid) ) +
    ''" C10="''+  convert(varchar(max), isnull(@numInteracion,0)) +
    ''" C11="''+ convert(varchar(max),isnull(@supervisor,'''') ) +
    ''" C12="''+convert(varchar(max),isnull(@template,''''))  +
    ''" C13="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +
    ''" C14="''+ convert(varchar,max(isnull(cctipocalifsub.califSubdesc,''N/A''))) +
    ''" C15="''+convert(varchar(max),isnull(max(d.[Login]),'''')) + ''"/>'')
    from conversationTwitter a
    inner join messageOutTwitter b on a.conversationTwitterId=b.conversationTwitterId
    left outer join ccinbound c on c.inbound_id = a.inboundid
    left outer join ccusers d on d.user_id = b.userid
    left outer join relationMessageDispositionTwit e on e.messageOutTwitterId=b.messageOutTwitterId
    left outer join cctipocalif on cctipocalif.calif_id = e.dispositionId
    left outer join cctipocalifsub on cctipocalifsub.califsub_id = e.subdispositionId and e.subdispositionId <> 0
    where a.conversationTwitterId=@conversationId
    group by a.conversationTwitterId,a.inboundid
end

END'
       EXEC(@Sql)

		set @process = 'CW-2428 Alter SP ccsp_MailSave'
        set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_MailSave]
@action int,
@uid varchar(max)=null,
@date datetime=null,
@conversationId int=0,
@inboundId smallint=null,
@userId smallint=0,
@messageStatusId int=null,
@isInbox bit=1,
@messageId int =null,
@timeAtt int = 0,
@pathFile varchar(255)= null,
@mailClient varchar(60)= null,
@mailACD varchar(60)= null,
@isSender bit=0,
@isUser bit = 0,
@info varchar(255)=null,
@dispositionId smallint=0,
@subDispositionId smallint=0,
@tWrapUp int =0,
@tRetention int = 0,
@email varchar(255) = null,
---Finder
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0
AS
BEGIN


declare @isEndConversation bit
declare @meanContactTypeId smallint
declare @xmlnode xml
declare @existAttached bit, @numInteracion smallint
declare @ids varchar(max)

set @meanContactTypeId = 1
SET NOCOUNT ON;

if @action = 1 begin --find uid ConversationMail
if not exists(select A.uid,C.mailInbound from messageMail A 
    inner join [message] B on A.messageId=B.messageId
    inner join [conversation] C on C.conversationId=B.conversationId
    where A.[uid]=@uid and C.mailInbound=@mailACD) 
    select 0
else select 1
  return (0)
end
else if @action = 2 BEGIN --new Conversation
    if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin
        insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)
        select @conversationId=SCOPE_IDENTITY()
        insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,0,@date,@messageStatusId)
        select @messageId=SCOPE_IDENTITY()
        insert into [messageMail](messageId,[uid]) values (@messageId,@uid)
        select @conversationId as ConversationId,@messageId as MessageId,0 as LastUserId
        return (0)
    end
    else begin
        select 0 as ConversationId,0 as MessageId,0 as LastUserId
        return (0)
    end
END
else if @action = 3 BEGIN --new Messages
    if @date is null set @date=getdate()
    if @mailACD is null select @mailACD=mailInbound from conversation where conversationId=@conversationId
    if not exists(select * from [conversation] where conversationId=@conversationId) begin --si el id conversacion no existe
        insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)
        select @conversationId=SCOPE_IDENTITY()
    end

    if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin     
        insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,@userId,@date,@messageStatusId)
        select @messageId=SCOPE_IDENTITY()
    end
    else begin
        select 0 as ConversationId,0 as MessageId,0 as LastUserId
        return (0)
    end

    if @uid is null --for outbound messages
        select @uid = dbo.md5(cast(@conversationId as varchar(10)) + ''_'' + cast(@messageId as varchar(10)))

    insert into [messageMail](messageId,[uid]) values (@messageId,@uid)

    --Finder
    select @existAttached =case when count(*)>0 then 1 else 0 end  from attached where messageId in (select messageId from message where conversationId=@conversationId)
    select @numInteracion = count(*) from message where conversationId=@conversationId
    --Actualiza un nodo del finder
    exec ccsp_CreateNodeMultimedia @type=1, @conversationId=@conversationId, @xml = @xmlnode OUTPUT
    if not exists(select * from ccEmailNode where emailId=@conversationId) begin
        insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
    end
    else begin
        update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
    end
    select @conversationId as ConversationId,@messageId as MessageId,0 as LastUserId

END
else if @action = 4 BEGIN --new attachment
    insert into [attached](messageId,pathFile,isUser) values(@messageId,@pathFile,@isUser)
    select SCOPE_IDENTITY() as attachedId
END
else if @action = 5 BEGIN --Correos por contestar Status DOWNLOAD,Assigned,READ,UnaSSIGNED
    select A.conversationId,B.userId,A.mailClient,A.mailInbound,A.info,B.messageStatusId,max(B.messageId) as messageId
    from conversation A inner join message B on A.conversationId = B.conversationId
    where A.inboundId = @inboundId and B.messageStatusId in(1,2,3,4) and meanContactTypeId = @meanContactTypeId
    and A.isFinished=0
    GROUP BY A.conversationId,A.inboundId,A.info,A.mailClient,A.mailInbound,B.messageStatusId,B.userId
END
else if @action = 6 BEGIN --update Time Attention, Retencion
    select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
    update [message] set tResponse=@timeAtt,tRetention=@tRetention,isSender=@isSender,messageStatusId=@messageStatusId,userId=@userId where messageId=@messageId
END
else if @action = 7 BEGIN --Cambia el status del mensaje
    select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
    --Status Read
    if @messageStatusId=3  update [message] set tWait=DATEDIFF(ss,isnull(tQueue,getdate()), getdate()) where messageId=@messageId

    --Status Send
    if @messageStatusId=6  begin
        select @isEndConversation=isFinished from conversation where conversationId=@conversationId
        if @isEndConversation = 1 set @messageStatusId=11--Close conversation by Agent
        update [message] set tSend=getdate() where messageId=@messageId
    end
    update [message] set messageStatusId=@messageStatusId where messageId=@messageId

    --Answered,Send,CLose Conversation system or agent
    if @messageStatusId in (5,6,10,11)  begin
        exec ccsp_CreateNodeMultimedia @type=1, @conversationId=@conversationId, @xml = @xmlnode OUTPUT
        if exists(select * from ccEmailNodeHistory where emailId=@conversationId) begin
            update ccEmailNodeHistory set node=@xmlnode,status=2 where emailId=@conversationId
        end
        else if exists(select * from ccEmailNode where emailId=@conversationId) begin
            update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
        end
        else begin
            insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
        end
    end

END
else if @action = 8 BEGIN --info del ultimo correo
    select messageId,GP.inboundId,C.connUser mailInbound,mailClient,mediaType,messageStatusId,info,I.descripcion,IG.graphic_id,I.tNotas,isnull(C.answerTimeOut,10) tTimeOut,C.timeAlertMessage tAlert
    from (
        select max(B.messageId) messageId,A.inboundId,A.mailClient, case A.meanContactTypeId when 1 then 3 else -1 end mediaType, B.messageStatusId, max(A.info) info
        from conversation A inner join message B  on A.conversationId = B.conversationId  where A.conversationId=@conversationId  GROUP BY A.inboundId,A.mailClient, A.meanContactTypeId, B.messageStatusId, B.userId) GP
    inner join contactMeanIn C on C.inboundId=GP.inboundId
    inner join ccInbound I on I.Inbound_id=GP.inboundId
    inner join ccRIAInboundGraph IG on IG.Inbound_id=GP.inboundId
END
else if @action = 9 BEGIN --carga adjuntos del ultimo mensaje
    if @conversationId is null or @conversationId=0 begin
        set @conversationId=0
        select @conversationId=conversationId from message where messageId=@messageId 
    end
    
    select pathFile,isUser from attached A
    inner join message B on A.messageId=B.messageId and B.conversationId=@conversationId
    where B.conversationId=@conversationId
END
else if @action = 10 BEGIN --Correos por enviar
    select A.conversationId,max(B.messageId) as messageId,B.userId,A.inboundId,A.mailInbound
    from conversation A
    inner join message B on A.conversationId = B.conversationId
    where B.messageStatusId in(5,7,8,9) and A.meanContactTypeId = 1
    GROUP BY A.conversationId,A.inboundId,A.info,A.mailClient,A.mailInbound,B.messageStatusId,B.userId
END

else if @action = 11 BEGIN --Califica el mensaje y pone el tiempo Notas
    if @subDispositionId <> 0 begin
        select @isEndConversation=isnull(EndConversation,0) from ccTipoCalifSub where califSub_id=@subDispositionId
    end
    else begin
        select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@dispositionId
    end
    if not exists(select * from relationMessageDisposition where messageId=@messageId) begin
        insert into relationMessageDisposition(messageId,dispositionId,subDispositionId) values(@messageId,@dispositionId,@subDispositionId)
    end
    else begin
        update relationMessageDisposition set dispositionId=@dispositionId,subDispositionId=@subDispositionId where messageId=@messageId
    end
        update message set tWrapUp=@tWrapUp where messageId=@messageId
        if @isEndConversation = 1 begin
        select @conversationId=conversationId from [message] where messageId=@messageId
        update conversation set isFinished=@isEndConversation where conversationId=@conversationId
    end
END
else if @action = 12 begin --Tiempo de cola
    select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
    update [message] set tQueue=getdate(),userId=@userId where messageId=@messageId
end
else if @action = 13 BEGIN  -- desasignar
    if @messageId = 0 begin
        insert into [messageUnAssigned](messageId,userId,[time],isLogout)
        select messageId,userId,datediff(ss,tQueue,getdate()) as [time],1 as isLogout from [message] where userId=@userId and messageStatusId in (2,3)
        update [message] set tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0 where userId=@userId and messageStatusId in (2,3)
    end
    else begin
        insert into [messageUnAssigned](messageId,userId,[time],isLogout)
        select messageId,userId,datediff(ss,tQueue,getdate()) as [time],0 as isLogout from [message] where userId=@userId and messageId=@messageId and messageStatusId in (2,3)
        update [message] set tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0 where userId=@userId and messageId=@messageId and messageStatusId in (2,3)
    end
end
else if @action = 14 begin
 update [message] set @messageStatusId=1,tQueue=null,userId=0,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0  where messageStatusId in(2,3)
end
else if @action = 15 begin
    SELECT @existAttached = case when count(*)>0 then 1 else 0 end
    from attached where messageId in (select messageId from message where conversationId=@conversationId)

    select max(messageid) as messageid,max(A.inboundid) as inboundid,max(a.conversationid) as conversationid,
        max(mailClient) as mailClient, min([date]) as [date], @existAttached isAttached, max(C.descripcion) as descripcion,
        max(B.tSend) as tSend, max(D.Nombres+'' ''+D.ApellidoPaterno+'' ''+D.ApellidoMaterno) as nameAgent,
        max(E.timeAlertMessage) timeAlertMessage ,max( E.answerTimeOut) answerTimeOut, max(C.tNotas) as tNotas,
        max(A.mailInbound) as MailInbound, isnull(max(E.name), '''') as name
    from conversation A
    inner join message B  on A.conversationId = B.conversationId
    inner join ccinbound C on A.inboundid= C.inbound_id
    left join ccUsers D on B.userId = D.User_id
    inner join contactMeanIn E on E.inboundId=C.Inbound_id   and E.meanContactTypeId=@meanContactTypeId
    where A.conversationId=@conversationId

end
else if @action = 16 begin
    select A.inboundid,B.messageid,a.conversationid,c.pathFile
    from conversation A
    inner join message B  on A.conversationId = B.conversationId
    inner join attached C on B.messageid= C.messageid
    where A.conversationId=@conversationId
end
else if @action = 17 begin --Asignar una evluacion
    exec ccsp_CreateNodeMultimedia @type=1, @conversationId=@conversationId, @xml = @xmlnode OUTPUT,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate
    if not exists(select * from ccEmailNode where emailId=@conversationId) begin
        insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
    end
    else begin
        update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
    end
end
else if @action = 18 begin --cerrar conversacion por tiempo
    if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date)
    if @conversationId = 0
        select 0
    else begin
        declare @closeConversation tinyint
        declare @tRsponse datetime
        select @tRsponse = isnull(max(tSend), getdate()) from message where messageId = @conversationId
        select @closeConversation = closeConversationTime from contactMeanIn
         if datediff(dd,getdate(),@tRsponse ) > @closeConversation
            select 0
        else
            select @conversationId
        end
    return 0
end
else if @action = 19 begin
    select isnull(max(C.Uid),0) [maxUid] from conversation A
    inner join message B on A.conversationId=B.conversationId
    inner join messageMail C on C.messageId=B.MessageId
    where inboundId=@inboundId and mailInbound=@mailACD
end
else if @action = 20 begin
    if @messageId is null begin
        select @ids=COALESCE(@ids + '','', '''') + cast(messageId as varchar(max))  from message where conversationId=@conversationId
        select @inboundId=inboundId from conversation where conversationId=@conversationId
        select @ids as ids,@inboundId as inboundId
    end
    else begin
        select case when count(*)>0 then 1 else 0 end  from attached where messageId=@messageId
    end
end
else if @action = 21 begin
    declare @isFinished bit
    set @isFinished = 0

    select @isFinished=isFinished from conversation where conversationId=@conversationId
    select @isFinished
end

else if @action = 22 begin
   
   declare @correo varchar(255)
   select  @correo = mailClient from conversation where conversationId = @conversationId
  insert into emailSpam (inboundId,agentId,conversationId,correo,fecha) values (@inboundId,@userId,@conversationId,@correo,getDate())   

   update Conversation set isFinished = 1 where mailClient = @correo
   update message set messageStatusId = 13 where messageId = @messageId

   select distinct conversationId,inboundId from emailSpam where correo = @correo

end

else if @action = 23 begin      
   if exists (select  * from emailSpam where correo like ''%''+@email+''%'') begin
        select 1
   end
   else begin
        select 0 
   end
end

END'
    EXEC(@Sql)  	

		 
		/* End script release */

		/* Upgrade database version (use your own script to do it) */		
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end