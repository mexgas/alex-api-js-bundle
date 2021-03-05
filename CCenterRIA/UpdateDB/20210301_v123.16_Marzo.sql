/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/03/01
Description:

Database: CCenterRia
Required version: 123.14

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 16
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-4890 Alter procedure ccsp_MailAdminAccount'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_MailAdminAccount]
@action int,
@meanContactTypeId smallint = 1,
@contactMeanId int=0,
@name   varchar(30)=null,
@conexionInfo   varchar(255)=null,
@inboundId  int=0,
@connUser   varchar(60)=null,
@ConnPass   varchar(30)=null,
@numMessages    tinyint=null,
@timeAlertMessage   tinyint=null,
@isActive bit =null,
@UserId int =null,
@idArea smallint =null,
@maxMails tinyint =3,
@answerTimeOut tinyint=null,
@revisionTime varchar(10)=null,
@daysTwitterRecord varchar(10)=null,
@closeConversationTime varchar(10)=null
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;
/****
Conexion Info Email In
    protocol|server|ssl|port|cleanMail|revisionTime
Conexion Info Email Out
    serverOut|portOut|tls|sslOut
Conexion Info Twitter
    usuarioID|token|tokenSecret|time|daysTwitterRecord
***/


declare @isActiveMail bit
set @isActiveMail=0

if @action = 1 begin --checha si esta activo el servicio
    select @isActiveMail = valor from ccSettings where setting_id=152
    if @isActiveMail = 1 begin
        select @isActiveMail=(case when isActive = 1 and @isActiveMail = 1 then 1 else 0 end) from meanContactType where meanContactTypeId = 1
    end
    select @isActiveMail as isActiveMail
    return (0)
end
else if @action = 2 begin --Obsoleto para email - actualizado en case 23
    select A.inboundId as IdIn,A.conexionInfo as ConexionInfo,A.connUser as [Username],A.connPass as [Password], A.isActive as IsActive
        from ContactMeanIn A
            inner join ccInbound B on A.inboundId=B.Inbound_Id
        where meanContactTypeId = @meanContactTypeId and B.Status=1 and A.isActive=1
end
else if @action = 3 begin   --
    select name,conexionInfo,connUser,ConnPass,numMessages,timeAlertMessage,answerTimeOut from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 4 begin--insert or update relation mail whit ACD by in
    ---Es necesario cambiar [ccsp_NetworkSocialAdminAccount] por que tambien se ocupa aqui
    DECLARE @tableConexionInfo TABLE(  id int, value varchar(255))
    if @connUser=''''   set @connUser=''nuxiba@nuxiba.com''
    if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
        if not exists(select * from ContactMeanIn where connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin
        if @name is null set @name=''''
        if @conexionInfo is null and @meanContactTypeId=1  set @conexionInfo=''''
        if @connUser is null set @connUser=''''
        if @connPass is null set @connPass=''''
        if @numMessages is null set @numMessages=3
        if @timeAlertMessage is null set @timeAlertMessage=5
        if @isActive is null set @isActive=0
        if @answerTimeOut is null set @answerTimeOut=0
        if @closeConversationTime is null set @closeConversationTime=3

        --Twitter deja los token
        --conexion Info usuarioID|token|tokenSecret|time|daysTwitterRecord
        if @meanContactTypeId= 2 begin

            if @conexionInfo is null begin
                set @conexionInfo=''usuarioID|token|tokenSecret''
                set @revisionTime=isnull(@revisionTime,''1'')
                set @daysTwitterRecord=isnull(@daysTwitterRecord,''0'')
            end
            else begin
            select @conexionInfo
                insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
                set @conexionInfo=null

                SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

                SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
                SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
            end
            set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
        end



        insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut,closeConversationTime)
                values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut,@closeConversationTime)
        select 1,''insert''
    end
        else select -1,''insert''
    end
    else begin
        if not exists(select * from ContactMeanIn where inboundId<>@inboundId and connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin

            select @name=isnull(@name,name), @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
                @numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
                @answerTimeOut= isnull(@answerTimeOut,answerTimeOut),@closeConversationTime=isnull(@closeConversationTime,closeConversationTime)
            from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId


            --Twitter deja los token
            if @meanContactTypeId= 2 begin
                --usuarioID|token|tokenSecret|time|daysTwitterRecord
                insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
                set @conexionInfo=null

                SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

                SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
                SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
                set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
            end


            update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
                numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut,
                closeConversationTime=@closeConversationTime
                where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
            select 1,''update''
        end
        else select -1,''update''
    end
    return (0)
end

else if @action = 5 begin--parameters check conection Mail In
    select conexionInfo,connUser,connPass from ContactMeanIn with(nolock) where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 6 begin--parameters check conection Mail Out
    select conexionInfo as ConexionInfo,connUser as UserName,connPass as Password, isActive as IsActive, contactMeanOutId as IdOut
        from ContactMeanOut with(nolock) where contactMeanOutId  = @contactMeanId
end
else if @action = 7 begin--list mail out by ACD
    select A.contactMeanOutId,A.name, A.conexionInfo,A.connUser,A.connPass,A.isActive
        from ContactMeanOut A with(nolock)

end
else if @action = 8 begin--insert account mail out
    if not exists(select * from ContactMeanOut where connUser=@connUser) begin
        insert into ContactMeanOut (meanContactTypeId,name,conexionInfo,connUser,ConnPass,isActive)
            values (@meanContactTypeId,@name,@conexionInfo,@connUser,@connPass,@isActive)
        select 1
        return(0)
    end
    else select -1
end
else if @action = 9 begin--update account mail out
    if not exists(select * from ContactMeanOut where contactMeanOutId <> @contactMeanId  and connUser=@connUser) begin

        select  @meanContactTypeId=isnull(@meanContactTypeId,meanContactTypeId),@name=isnull(@name,name),
            @conexionInfo=isnull(@conexionInfo,conexionInfo),@connUser=isnull(@connUser,connUser),
            @connPass=isnull(@connPass,ConnPass),@isActive=isnull(@isActive,isActive)
            from ContactMeanOut where contactMeanOutId = @contactMeanId

        update ContactMeanOut set meanContactTypeId=@meanContactTypeId,name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,isActive=@isActive
         where contactMeanOutId = @contactMeanId
         select 1,''update ''
    end
    else select -1
end
else if @action = 10 begin  --insert relation mail out and ACD
    if not exists(select * from relationContactMeanOutInbound where contactMeanOutId=@contactMeanId) begin
        insert into relationContactMeanOutInbound(contactMeanOutId,inboundId) values (@contactMeanId,@inboundId)
    end
end
else if @action = 11 begin --delete relation mail out and ACD
    delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId and inboundId=@inboundId
end
else if @action = 12 begin --delete mail out
    delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId
    delete ContactMeanOut where contactMeanOutId=@contactMeanId
end
else if @action = 13 begin --delete mail out
    if not exists(select * from ContactMeanOut where contactMeanOutId=@contactMeanId) begin
        update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
        select 1
    end
    else select -1
end
else if @action = 14 begin
    select * from relationContactMeanOutInbound
end
else if @action = 15 begin
    select * from relationContactMeanOutInbound where inboundId=@inboundId
end
--else if @action = 16 begin
--  update ccRIACat_Areas set maxMails = @maxMails where IDArea=@idArea
--end
else if @action = 17 begin  --
    select A.conexionInfo as ConexionInfo,A.connUser as UserName,A.connPass as Password,A.isActive as IsActive,inboundId as IdIn  from ContactMeanIn A where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
End
else if @action = 18 begin   --Obsoleto para email - actualizado en case 24
    select A.contactMeanOutId as IdOut,A.conexionInfo as ConexionInfo ,A.connUser as UserName,A.connPass as [Password],isActive as IsActive from contactMeanOut A where isActive=1
end
else if @action = 19 begin   --relation MailOut and ACD
    select contactMeanOutId as Id,inboundId as AcdId from relationContactMeanOutInbound where inboundId = @inboundId or @inboundId = 0 order by inboundId
end
else if @action = 20 begin --relation MailOut and ACD
    select B.inboundId,A.conexionInfo,A.connUser,A.connPass
    from ContactMeanOut A
    inner join relationContactMeanOutInbound B on B.contactMeanOutId=A.contactMeanOutId
    where B.inboundId = @inboundId or @inboundId = 0
end
else if @action = 21 begin --relation MailOut and ACD
    update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
end
else if @action = 22 begin --Update type
    if @meanContactTypeId = 2 --Twitter
        set @conexionInfo=''usuarioID|token|tokenSecret|1|0''
    else
        set @conexionInfo=''''
    update ContactMeanIn set name = '''', conexionInfo = @conexionInfo, connUser = '''', isActive = 0 where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
    select 1,''unAssigned''
end
else if @action = 23 begin -- carga la relacion de especialidades y cuentas de email de entrada
		 select A.inboundId as IdIn,A.conexionInfo as ConexionInfo,A.connUser as [Username],A.connPass as [Password], A.isActive as IsActive,
		cast(case when A.inboundId = C.inboundId then 1 else 0 end as bit) as IsAzure,
		tenantId [TenantId], clientId [ClientId], clientSecret [ClientSecret], instance [Instance], apiUrl [ApiUrl]
        from ContactMeanIn A inner join ccInbound B on A.inboundId=B.Inbound_Id
		left join contactMeanInAzure C on B.Inbound_id = C.inboundId
        where meanContactTypeId = @meanContactTypeId and B.Status=1 and A.isActive=1
end
else if @action = 24  begin  --Carga cuentas de salida
 	select A.contactMeanOutId as IdOut,A.conexionInfo as ConexionInfo ,A.connUser as UserName,A.connPass as [Password],isActive as IsActive, 
	cast(case when A.contactMeanOutId = B.contactMeanOutId then 1 else 0 end as bit) as IsAzure,
	tenantId [TenantId], clientId [ClientId], clientSecret [ClientSecret], instance [Instance], apiUrl [ApiUrl]
	from contactMeanOut A left join contactMeanOutAzure B on A.contactMeanOutId = B.contactMeanOutId
	where isActive=1
end
END'
	exec (@sql)


	set @process = 'CW-4890 Alter procedure ccsp_MailSave'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_MailSave]
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
@mailClient varchar(255)= null,
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
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0,
@top int=30,

---Embedded images
@contentId varchar(255)=null,
@isEmbedded bit = null
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
	insert into [attached](messageId,pathFile,isUser,contentId,isEmbedded) values(@messageId,@pathFile,@isUser,@contentId,@isEmbedded)
    select SCOPE_IDENTITY() as attachedId
END
else if @action = 5 BEGIN --Correos por contestar Status DOWNLOAD,Assigned,READ,UnaSSIGNED   
	select top(@top) A.conversationId,B.userId,A.mailClient,A.mailInbound,A.info,B.messageStatusId,B.messageId from (
	select A.conversationId,max(A.mailClient) as mailClient ,max(A.mailInbound) as mailInbound,min(A.info) as info,
		max(B.messageId) as messageId from conversation  A 
	inner join message B on A.conversationId = B.conversationId
	where A.inboundId = @inboundId and A.isFinished=0 and meanContactTypeId = @meanContactTypeId
	group by A.conversationId
	) A 
	inner join message B on A.conversationId = B.conversationId and A.messageId = B.messageId
	where B.messageStatusId in(1,2,3,4)

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
        if  exists(select * from ccEmailNode where emailId=@conversationId) begin
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
    
    select pathFile as NameFile,isUser from attached A
    inner join message B on A.messageId=B.messageId and B.conversationId=@conversationId
    where B.conversationId=@conversationId
END
else if @action = 10 BEGIN --Correos por enviar
    select A.conversationId as ConversationId,B.messageId as MessageId,B.userId as AgentId,A.inboundId as AcdId,A.mailInbound as MailInbound
	 from (
	select A.inboundId,A.conversationId as ConversationId,max(B.messageId) as MessageId,A.mailInbound   from conversation A 
	inner join message B on A.conversationId = B.conversationId
	where A.meanContactTypeId = 1 and A.inboundId = @inboundId
	GROUP BY A.conversationId,A.inboundId,A.mailInbound 
	) A
	inner join message B on A.MessageId = B.messageId
	where B.messageStatusId in(5,7,8,9) 
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

    select max(B.messageId) as MessageID, cast(max(A.inboundid) as int) as InboundID, max(A.conversationid) as ConversationID,
        max(A.mailClient) as ClientEmail, min(B.[date]) as [Date], @existAttached isAttached, max(C.descripcion) as ACDName,
        max(B.tSend) as tSend, max(D.Nombres+'' ''+D.ApellidoPaterno+'' ''+D.ApellidoMaterno) as NameAgent,
        cast(max(E.timeAlertMessage) as int) tAlertMessage, cast(max(E.answerTimeOut) as int) tAnswerTimeOut, max(C.tNotas) as tWrapUp,
        max(A.mailInbound) as InboundEmail, isnull(max(E.name), '''') as SenderName, cast(max(F.graphic_id) as int) as ACDGraphicID,
		max(B.[date]) MsgTimestamp, cast(max(case when C.inbound_id = H.inboundId then 1 else 0 end) as bit) as IsAzure
    from conversation A
    inner join message B  on A.conversationId = B.conversationId
    inner join ccinbound C on A.inboundid= C.inbound_id
    left join ccUsers D on B.userId = D.User_id
    inner join contactMeanIn E on E.inboundId=C.Inbound_id and E.meanContactTypeId=@meanContactTypeId
	inner join ccRIAinboundGraph F on C.Inbound_id = F.Inbound_id
	inner join ccRIAGraphics G on F.graphic_id = g.graphic_id
	left join contactMeanInAzure H on C.Inbound_id = H.inboundId
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

   select distinct conversationId as ConversationId,inboundId as AcdId from emailSpam where correo = @correo

end
else if @action = 23 begin      
   if exists (select  * from emailSpam where correo like ''%''+@email+''%'') begin
        select 1
   end
   else begin
        select 0 
   end
end
else if @action = 24 begin      
	select count(*) as [Amount] from attached A inner join message B on A.messageId=B.messageId 
	where A.messageId = @messageId and isEmbedded = 1
end
else if @action = 25 begin      
	select pathFile as NameFile from attached A inner join message B on A.messageId=B.messageId 
	where A.messageId = @messageId and contentId = @contentId and isEmbedded = 1
end
else if @action = 26 begin      -- Discard Email
	update conversation set isFinished = 1 where conversationId = @conversationId
	update message set messageStatusId = 14, userId = @userId where messageId = @messageId
end
else if @action = 27 begin
	select count(*) as [Amount] 
	from attached nolock where messageId in (select messageId from message nolock where conversationId=@conversationId)
end
else if @action = 28 begin --carga adjuntos del ultimo mensaje para cuentas Azure
    if @conversationId is null or @conversationId=0 begin
        set @conversationId=0
        select @conversationId=conversationId from message where messageId=@messageId 
    end
    
    select pathFile as NameFile, contentId [ContentId], isEmbedded [IsEmbedded] from attached A
    inner join message B on A.messageId=B.messageId and B.conversationId=@conversationId
    where B.conversationId=@conversationId
end

END'
	exec (@sql)

	set @process = 'CW-4987 grabacion con cal_tDialog=0'
	set @sql = 'DECLARE @dateStart DATETIME,@tMinAVRS SMALLINT;

SELECT @tMinAVRS = valor FROM ccSettings WHERE setting_id = 65;
IF @tMinAVRS IS NULL SET @tMinAVRS = 5;

DECLARE @tmpCallIn TABLE
(userId      INT, 
 inboundId   INT, 
 callId      INT, 
 calTXfer    INT, 
 calTRinging INT, 
 calTDialog  INT, 
 calTWrapup  INT
);

select @dateStart=convert(date,min(cal_Inicio)) from cccallsin

INSERT INTO @tmpCallIn
       SELECT User_id, 
              IdCampEsp, 
              callID, 
              ISNULL([5], 0) AS calXfer, 
              ISNULL([9], 0) AS calRinging, 
              ISNULL([4], 0) calDialog, 
              ISNULL([6], 0) calWrapup
       FROM
       (
           SELECT a.User_id, 
                  a.TipoStatusAge_id, 
                  a.tStatus, 
                  a.IdCampEsp, 
                  a.callID
           FROM ccLogAgentesDia a
                INNER JOIN ccTipoStatusAgente b ON a.TipoStatusAge_id = b.TipoStatusAge_id
           WHERE a.fecha > @dateStart
                 AND callID IN
           (
               SELECT a.cal_id
               FROM cccallsin a
               WHERE cal_tDialog = 0
                     AND cal_Inicio > @dateStart
                     AND a.statusCall_id = 13
           )
                 AND a.TipoStatusAge_id IN(4, 5, 6, 9)
                AND a.Tipo = 0
       ) calldata PIVOT(MAX(tStatus) FOR TipoStatusAge_id IN([5], 
                                                             [9], 
                                                             [4], 
                                                             [6])) piv;
INSERT INTO ccAVRSTransfer
(cal_id, 
 tipo
)
       SELECT A.callId, 
              0 AS callType
       FROM @tmpCallIn A
            LEFT JOIN ccAVRSTransfer B ON a.callId = B.cal_id
                                          AND b.tipo = 0
       WHERE b.cal_id IS NULL
             AND A.calTDialog >= @tMinAVRS;
UPDATE B
  SET 
      B.cal_tXfer = A.calTXfer, 
      B.cal_tRing = A.calTRinging, 
      B.cal_tDialog = A.calTDialog, 
      B.cal_tNotas = A.calTWrapup
FROM @tmpCallIn A
     INNER JOIN cccallsin B ON A.callId = B.cal_id;
-------------------------------------------- SALIDA --------------------------------------------
select @dateStart=convert(date,min(cal_Inicio)) from ccoCallsOut

DECLARE @tmpCallOut TABLE
(userId      INT, 
 inboundId   INT, 
 callId      INT, 
 calTXfer    INT, 
 calTRinging INT, 
 calTDialog  INT, 
 calTWrapup  INT
);

insert into @tmpCallOut
SELECT User_id, 
       IdCampEsp, 
       callID, 
       ISNULL([5], 0) AS calXfer, 
       ISNULL([9], 0) AS calRinging, 
       ISNULL([4], 0) calDialog, 
       ISNULL([6], 0) calWrapup
FROM
(
    SELECT a.User_id, 
           a.TipoStatusAge_id, 
           a.tStatus, 
           a.IdCampEsp, 
           a.callID
    FROM ccLogAgentesDia a
         INNER JOIN ccTipoStatusAgente b ON a.TipoStatusAge_id = b.TipoStatusAge_id
    WHERE a.fecha > @dateStart
          AND callID IN
    (
        SELECT a.cal_id
        FROM ccoCallsOut a
        WHERE cal_tDialog = 0
              AND cal_Inicio > @dateStart
              AND a.statusCall_id = 13
    )
          AND a.TipoStatusAge_id IN(4, 5, 6, 9)
         AND a.Tipo = 1
) calldata PIVOT(MAX(tStatus) FOR TipoStatusAge_id IN([5], 
                                                      [9], 
                                                      [4], 
                                                      [6])) piv;

INSERT INTO ccAVRSTransfer(cal_id,  tipo)
       SELECT A.callId, 
              1 AS callType
       FROM @tmpCallOut A
            LEFT JOIN ccAVRSTransfer B ON a.callId = B.cal_id AND b.tipo = 1
       WHERE b.cal_id IS NULL AND A.calTDialog >= @tMinAVRS;


UPDATE B
  SET 
      B.cal_tXfer = A.calTXfer, 
      B.cal_tRing = A.calTRinging, 
      B.cal_tDialog = A.calTDialog, 
      B.cal_tNotas = A.calTWrapup
FROM @tmpCallOut A
     INNER JOIN ccoCallsOut B ON A.callId = B.cal_id;

'
	exec (@sql)

	set @process = 'CW-4936 Agregar nueva columna a tabla cctiposlistanegra'
	set @sql = 'if not exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = ''DateCreation'' and TABLE_NAME = ''cctiposlistanegra'') begin
            ALTER TABLE cctiposlistanegra ADD DateCreation datetime 
			end'
	exec (@sql)

	set @process = 'CW-4936 se quita el sp ccsp_GalateaAdminBlacklistCatalog si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminBlacklistCatalog'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminBlacklistCatalog;
            end'
        EXEC(@sql)

	set @process = 'CW-4936 se agrega sp ccsp_GalateaAdminBlacklistCatalog'
	set @sql = '          CREATE PROCEDURE ccsp_GalateaAdminBlacklistCatalog
@BLID smallint,
@name varchar(50),
@Type tinyint 
AS
set nocount on
if @Type=1-- Read black lists
 begin
	Select idtipolista AS ID, tipolista AS TIPO , DateCreation as DateCreation 
	from cctiposlistanegra where idtipolista = case isnull(@BLID,0) when 0 then idtipolista else @BLID end
	and Status= 1 order by 2
	return(0)
 end

If @Type=2 --Create black list
 begin
 DECLARE @newBlackListId INT= -1 --Nombre en Uso
	if not exists(select tipolista from cctiposlistanegra where tipolista=@name)
		begin
			insert into cctiposlistanegra (tipolista,DateCreation) values(@name, SYSDATETIME())
			SELECT @newBlackListId = SCOPE_IDENTITY() 
		end
	SELECT @newBlackListId as ReturnValue
	return(0)
 end

if @Type=4-- update 
 begin
 if not exists(select tipolista from cctiposlistanegra where tipolista=@name)
		begin
			update cctiposlistanegra set tipolista=@name where idtipolista= @BLID
			SELECT 200 as ReturnValue
		end
		else
			SELECT -1 as ReturnValue --Nombre en uso
 return(0)
 end

if @Type=5 --obtiene el id de lista llamada defaultList/General
	begin
		declare @dnclid as int
		set @dnclid = 0;

		select @dnclid = idtipolista from cctiposlistanegra where Tipolista = ''defaultList/General''
		select @dnclid
		return(0)
	end

set nocount off

'
	exec (@sql)

		set @process = 'CW-4936 Alter en sp ccsp_RIACATBList que maneja el catalog de listas negras en xion'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIACATBList]
@BLID smallint,
@name varchar(50),
@Type tinyint 
AS
set nocount on
if @Type=1
 begin
	Select idtipolista AS ID, tipolista AS TIPO 
	from cctiposlistanegra where idtipolista = case isnull(@BLID,0) when 0 then idtipolista else @BLID end
	and Status= 1 order by 2
	return(0)
 end

If @Type=2
 begin
	if exists(select tipolista from cctiposlistanegra where tipolista=@name)
		select 1, ''Nombre en Uso''
	else	
		insert into cctiposlistanegra (tipolista,DateCreation) values(@name, SYSDATETIME())
	return(0)
 end

if @Type=4
 begin
	update cctiposlistanegra set tipolista=@name where idtipolista= @BLID
 end

if @Type=5
	begin
		declare @dnclid as int
		set @dnclid = 0;

		select @dnclid = idtipolista from cctiposlistanegra where Tipolista = ''defaultList/General''
		select @dnclid
		return(0)
		end
set nocount off'
        EXEC(@sql)

        set @process = 'CW-4897 se modifica sp ccsp_GalateaGetRecordsImportStatus'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetRecordsImportStatus]
                  -- @Type = 1:Detalle general de carga de registros | 2:Detalle específico de carga de registros | 3:Porcentaje de carga de registros
                  @action tinyint, 
                  @loadID int = NULL, 
                  @userID smallint = NULL

                  AS
                  declare @today datetime
                  select @today =convert(datetime, convert(varchar(11),getdate(),121),121)
                  SET nocount ON
                  if @action not IN (1,2,3)
                    raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)

                  if @action=1 -- Detalle general de carga de registros
                   BEGIN
                    if not exists(SELECT User_id FROM ccUsers WHERE TipoUser_id IN(2,6) AND Status>0 AND User_id=@userID)
                     BEGIN
                      raiserror(''ERROR. invalid user id'', 18, 1)
                      return(0)
                     END
                    
                    if exists (select * from ccUsers_Roles where User_id = @userID and Rol_id = (select Rol_id from ccRoles where Level = 7))
                        BEGIN
                            SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked as regsNotLoaded, state, loadDate
                            FROM ccRIALoading riaLoad
                            JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
                            WHERE 
                            loadDate>=@today
                            ORDER BY riaLoad.loadDate DESC
                        END
                    else
                        BEGIN
                            SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked as regsNotLoaded, state, loadDate
                            FROM ccRIALoading riaLoad
                            JOIN ccSupervisorCam superCam ON riaLoad.cam_id = superCam.cam_id
                            JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
                            WHERE 
                            loadDate>=@today AND
                            superCam.user_id = @userID
                            AND superCam.tipo = 1
                            ORDER BY riaLoad.loadDate DESC
                        END

                    return(0)
                   END

                  if @action=2 -- Detalle específico de carga de registros
                   BEGIN
                    if not exists(SELECT load_id FROM ccRIALoading)
                     BEGIN
                      raiserror(''ERROR. invalid template ID'', 18, 1)
                      return(0)
                     END

                      SELECT regsLoaded, alreadyLoaded, regsBlocked, regsNotLoaded,
                             telsLoaded, telsBlocked, telsNotLoaded
                      FROM ccRIALoading
                      WHERE load_id  = @loadID
                   
                   END

                  if @action=3 -- Porcentaje de carga de registros
                   BEGIN
                    if not exists(SELECT load_id FROM ccRIALoading)
                     BEGIN
                      raiserror(''ERROR. invalid load ID'', 18, 1)
                      return(0)
                     END

                      SELECT state, pctg
                      FROM ccRIALoading
                      WHERE load_id  = @loadID

                   END
                  SET nocount off'
    exec (@sql)
		
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
