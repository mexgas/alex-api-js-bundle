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
	
	set @process = 'CW-4995 Valida si existe campo AllowChangeDialingMode en ccUsers'
    set @sql = 'IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccUsers'' AND COLUMN_NAME = ''AllowChangeDialingMode'')
	Begin
	ALTER TABLE ccUsers 
	ADD AllowChangeDialingMode bit NOT NULL
	CONSTRAINT DF_ccUsers_ChangeDialingMode DEFAULT 0
	WITH VALUES
	End'
        EXEC(@sql)
	
	set @process = 'CW-4995 Valida si existe SP ccsp_GalateaADMPermisos'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaADMPermisos'')
            begin
          DROP PROCEDURE ccsp_GalateaADMPermisos;
            end'
        EXEC(@sql)

	set @process = 'CW-4995 se agrega sp ccsp_GalateaADMPermisos'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaADMPermisos]
@users_id varchar(255),
@Type int, -- 1.- cambia permiso, 2.- obtiene lista de permisos
@Permit int, -- 1.- AllowChangeDialingMode
@isActive int
AS
set nocount on

If @Type = 1 --1 Update Permission
 begin
	 if @permit = 1   --AllowChangeDialingMode
	   		UPDATE ccUsers SET AllowChangeDialingMode = @isActive where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, '',''))

	 return(0)
 end

if @Type = 2 --Get Permission
begin
	return(0)
end

set nocount off

'
	exec (@sql)
	
		
    set @process = 'CW-4897 Se agrega estado de reconexion en el agente'
    set @sql = 'if not exists(select * from ccTipoStatusAgente where TipoStatusAge_id=30)
insert into ccTipoStatusAgente values(30,''ReconnectKolob'')'
    exec (@sql)

	
   set @process = 'CW-5007 ST_2021_02_585 cuando se tiene mas de una LN asociada a una calificacion solo lo guarda en una de las listas'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF] @IDCall INT, @calif_id SMALLINT, @TipoCall SMALLINT, @Origin INT = 0, @cal_key VARCHAR(20) = NULL, @callOutId INT = 0, @subId SMALLINT = 0
AS
SET NOCOUNT ON

DECLARE @RecicleSIC TINYINT, @Reprogram TINYINT, @DateNewDial SMALLDATETIME, @idTipoLista INT, @autoCB TINYINT, @tel VARCHAR(30), @camp INT, @iddncList AS INT
DECLARE @userid INT

SELECT @RecicleSIC = valor
FROM ccSettings
WHERE setting_id = 60

SELECT @RecicleSIC = IsNull(@RecicleSIC, 0)

DECLARE @hashTel INT
DECLARE @killListID INT = (
		SELECT idtipolista
		FROM ccTiposListaNegra
		WHERE Tipolista = ''default/KillList''
		)
DECLARE @killListSetting INT = (
		SELECT STATUS
		FROM ccSettings
		WHERE setting_id = 215
		)

IF @TipoCall = 1
BEGIN
	UPDATE ccCallsIN
	SET calif_id = @calif_id, cal_origin_id = @Origin, cal_key = isnull(@cal_key, cal_key), califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
	WHERE cal_id = @IDCall

	IF EXISTS (
			SELECT idTipoLista
			FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
			WHERE tipo = 0 AND calif_id = @calif_id
			)
	BEGIN
		SELECT @tel = dbo.Completa_ListaNegra(ci.cal_ANI), @iddncList = cbl.idTipoLista
		FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
		JOIN cccalifblacklist AS cbl ON ci.calif_id = cbl.calif_id
		WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0

		IF @tel IS NOT NULL AND @iddncList IS NOT NULL
		BEGIN
			--insert ccListaNegra
			INSERT INTO cclistanegra (telefono, idtipolista)
			VALUES (@tel, @iddncList)

			--insert cc_killlist
			IF (@killListSetting = 1 AND @iddncList = @killListID) -- verifies if kill list setting is active and if the list_id matches killList id
			BEGIN
				select @hashTel = dbo.hashPhone(@tel)

				IF NOT EXISTS (
						SELECT hashtel
						FROM cc_KillList
						WHERE hashTel = @hashTel
						)
				BEGIN
					INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
					VALUES (@hashTel, @iddncList, GETDATE())
				END
			END

			INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			SELECT dbo.Completa_ListaNegra(ci.cal_ANI), cbl.idTipoLista, ci.Inbound_id, getdate(), ci.dni_id, 6
			FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
			JOIN cccalifblacklist cbl ON ci.calif_id = cbl.calif_id
			WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0
		END
	END

	RETURN (0)
END

IF @TipoCall = 2
BEGIN
	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	SELECT @autoCB = autocallback
	FROM ccTipoCalifSubout
	WHERE califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	IF @autoCB IS NULL
	BEGIN
		SELECT @autoCB = autocallback
		FROM cctipocalifout
		WHERE calif_id = @calif_id
	END

	IF @autoCB = 1
	BEGIN
		SELECT @callOutId = callout_id, @camp = cam_id, @userid = user_id
		FROM ccocallsout
		WHERE Cal_id = @IDCall

		SELECT @DateNewDial = dateadd(mi, t_autoCB, getdate())
		FROM cccamps cam
		WHERE cam.cam_id = @camp

		EXEC ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
	END

	UPDATE ccoCallsOUT
	SET calif_id = @calif_id, califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
	WHERE cal_id = @IDCall

	IF EXISTS (
			SELECT idTipoLista
			FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
			WHERE tipo = 1 AND calif_id = @calif_id
			) AND NOT EXISTS (
			SELECT co.cal_telefono
			FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
			JOIN ccListaNegra bl ON dbo.Completa_ListaNegra(co.cal_telefono) = bl.telefono OR co.cal_telefono = bl.telefono
			WHERE co.cal_id = @idCall AND bl.idtipolista IN (
					SELECT idTipoLista
					FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
					WHERE tipo = 1 AND calif_id = @calif_id
					)
			)
	BEGIN --IF

		CREATE TABLE #NUMANDBL (id int identity,  iddncList int)

		SELECT @tel= co.cal_telefono
		FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
		WHERE co.cal_id = @idCall 

		SET @tel=dbo.Completa_ListaNegra(@tel)

		IF(LEFT(@tel, 1) <> ''E'') begin
			INSERT INTO #NUMANDBL (iddncList) 
			select cbl.idTipoLista from cccalifblacklist cbl  where cbl.calif_id=@calif_id and cbl.tipo = 1
		END

		DECLARE @Count int		
		WHILE (SELECT count(id) from #NUMANDBL) > 0
		BEGIN  --WHILE
			select @Count = count(id) from #NUMANDBL
			SELECT @iddncList = iddncList from #NUMANDBL where id = @Count
			IF @tel IS NOT NULL AND @iddncList IS NOT NULL
			BEGIN--Tel adn iddnclist
				EXEC ccsp_InsertDNCList @tel, @iddncList

				IF (@killListSetting = 1 AND @iddncList = @killListID)
				BEGIN
					select @hashTel = dbo.hashPhone(@tel)

					IF NOT EXISTS (SELECT hashtel FROM cc_KillList WHERE hashTel = @hashTel)
					BEGIN
						INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
						VALUES (@hashTel, @iddncList, GETDATE())
					END
				END

				INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
				SELECT dbo.Completa_ListaNegra(co.cal_telefono), cbl.idTipoLista, co.cam_id, getdate(), co.callout_id, 6
				FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
				JOIN cccalifblacklist cbl ON co.calif_id = cbl.calif_id
				WHERE co.cal_id = @idCall AND left(dbo.Completa_ListaNegra(co.cal_telefono), 1) <> ''E'' AND cbl.tipo = 1
			END --Tel adn iddnclist
			delete from #NUMANDBL where id = @Count
		END --WHILE
		DROP TABLE #NUMANDBL
	END --IF
	IF @RecicleSIC = 1
	BEGIN
		-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
		SELECT @Reprogram = CanReprogram
		FROM ccTipoCalifSubout
		WHERE califSub_Id = @subId

		-- Si no tiene subcalificacion toma la de la calificacion
		IF @Reprogram IS NULL
		BEGIN
			SELECT @Reprogram = CanReprogram
			FROM ccTipoCalifOUT
			WHERE calif_id = @calif_id
		END

		IF @callOutId = 0
			SELECT @callOutId = callout_id
			FROM ccocallsout
			WHERE Cal_id = @IDCall

		UPDATE ccoWorkingTable
		SET calif_id = @calif_id, cal_status = CASE @Reprogram WHEN 0 THEN 3 ELSE cal_status END
		WHERE callout_id = @callOutId
	END

	DECLARE @keepDial BIT
	DECLARE @finishPreview SMALLINT

	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	SELECT @keepDial = keepDial
	FROM ccTipoCalifSubout
	WHERE califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	IF @keepDial IS NULL
	BEGIN
		SELECT @keepDial = keepDial
		FROM ccTipoCalifout
		WHERE calif_id = @calif_id
	END

	SELECT @finishPreview = isnull(finishPreview, 0)
	FROM ccTipoCalifout
	WHERE calif_id = @calif_id

	IF @keepDial = 1
	BEGIN
		UPDATE ccologdials
		SET TipoDialingMode = dbo.fn_getDialingMode(@IDCall, 3, 0, @camp)
		WHERE logDial_id IN (
				SELECT TOP 1 L.logDial_id
				FROM ccoLogDials L WITH (INDEX (IX_ccoLogDials_2), NOLOCK)
				JOIN ccoCallsOut O WITH (INDEX (PK_ccoCallsOut), NOLOCK) ON L.callout_id = O.callout_id
				WHERE O.cal_id = @IDCall
				ORDER BY L.logDial_id DESC
				)
	END

	SELECT @keepDial, @finishPreview

	RETURN (0)
END

SET NOCOUNT OFF
'
    exec (@sql)
    
        set @process = 'Se agregan horarios de verano hasta 2029 -1'
        set @sql = 'delete ccHorarioVerano where country_id = 1 and inicio > ''20210101'''
    	exec (@sql)
    	
    	set @process = 'Se agregan horarios de verano hasta 2029 -3'
	set @sql = 'delete ccHorarioVerano where country_id = 4 and inicio > ''20240101'''
    	exec (@sql)
  
  	set @process = 'Se agregan horarios de verano hasta 2029 -2'
        set @sql = 'insert into [ccHorarioVerano] ([inicio],[fin],[country_id]) values
(''20210404'', ''20211031'', 1),
(''20220403'', ''20221030'', 1),
(''20230402'', ''20231029'', 1),
(''20240407'', ''20241027'', 1),
(''20250406'', ''20251026'', 1),
(''20260405'', ''20261025'', 1),
(''20270404'', ''20271031'', 1),
(''20280402'', ''20281029'', 1),
(''20290401'', ''20291028'', 1),
(''20240310'', ''20241103'', 4),
(''20250309'', ''20251105'', 4),
(''20260308'', ''20261101'', 4),
(''20270307'', ''20271107'', 4),
(''20280305'', ''20281105'', 4),
(''20290304'', ''20291104'', 4);'
    	exec (@sql)
    	
    	set @process = 'Se agregan horarios de verano hasta 2029 -3'
	set @sql = 'delete ccHorarioVeranoUSA where inicio > ''20240101'''
    	exec (@sql)
    	
    	set @process = 'Se agregan horarios de verano hasta 2029 -4'
	set @sql = 'insert into [ccHorarioVeranoUSA] ([inicio],[fin]) values
(''20240310'', ''20241103''),
(''20250309'', ''20251105''),
(''20260308'', ''20261101''),
(''20270307'', ''20271107''),
(''20280305'', ''20281105''),
(''20290304'', ''20291104'');'
    	exec (@sql)

        set @process = 'CW-4989 se cambia limite de llamadas para mostrar en el sp'
        set @sql = '
        ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
AS
     SET NOCOUNT ON
     DECLARE @lastCallAgt TABLE
     (id           INT NOT NULL, 
      tipo         VARCHAR(10) NOT NULL, 
      Hora         VARCHAR(10) NOT NULL, 
      Telefono     VARCHAR(55) NOT NULL, 
      EspCamp      VARCHAR(55) NOT NULL, 
      Calificacion VARCHAR(60), 
      Duracion     VARCHAR(10) NOT NULL, 
      CallBack     VARCHAR(60), 
      cal_key      VARCHAR(20), 
      IDCampEsp    SMALLINT NOT NULL, 
      prefijo      VARCHAR(MAX) NULL, 
      GraphicID    INT,
	  HidePhone	   bit
     )
     INSERT INTO @lastCallAgt
            SELECT c.cal_id AS id, 
                          ''IN'' AS Tipo, 
                          CONVERT(VARCHAR(10), cal_inicio, 108) AS Hora, 
                          cal_ani AS Telefono, 
                          descripcion AS EspCamp, 
                          ISNULL(cal.Description, '''') AS Calificacion, 
                          CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE
                                                                                            WHEN stopRecording = 0
                                                                                            THEN ISNULL(t.tDespuesXfer, 0)
                                                                                            ELSE 0
                                                                                        END, 0), 108) Duracion, 
                          '''' AS CallBack, 
                          cal_key, 
                          c.inbound_id AS IDCampEsp, 
                          ISNULL(ccInbound.prefijo, '''') Prefijo, 
                          graph.graphic_id GraphicID,
						  case when (select valor from ccSettings where setting_id = 223) = ''0'' then 0 else 1 end as HidePhone
            FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
                 JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
                 INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
                 LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
                 LEFT JOIN
            (
                SELECT cal_id, 
                       tipo, 
                       SUM(tAntesXfer) AS tAntesXfer, 
                       SUM(tDespuesXfer) AS tDespuesXfer
                FROM ccLogTransfers
                WHERE tipo = 1
                GROUP BY cal_id, 
                         tipo
            ) AS t ON c.cal_id = t.cal_id
            WHERE user_id = @user_id
                  AND cal_inicio > DATEADD(dd, -1, GETDATE())
            ORDER BY c.cal_inicio DESC
     INSERT INTO @lastCallAgt
            SELECT c.cal_id AS id, 
                          ''OUT'' AS Tipo, 
                          CONVERT(VARCHAR(10), cal_inicio, 108) AS Hora, 
                          cal_telefono AS Telefono, 
                          cam_descripcion AS EspCamp, 
                          ISNULL(cal.Description, '''') AS Calificacion, 
                          CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE
                                                                                       WHEN stopRecording = 0
                                                                                       THEN ISNULL(t.tDespuesXfer, 0)
                                                                                       ELSE 0
                                                                                   END, 0), 114) AS Duracion, 
                          ISNULL(CONVERT(VARCHAR(16), cal_fcallback, 121), '''') AS CallBack, 
                          cal_key, 
                          c.cam_id AS IDCampEsp, 
                          ISNULL(ccCamps.prefijo, '''') Prefijo, 
                          graph.graphic_id GraphicID,
						  case when (select valor from ccSettings where setting_id = 223) = ''0'' then 0 else 1 end as HidePhone
            FROM ccoCallsOut c
                 INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
                 LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
                 LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
                 LEFT JOIN
            (
                SELECT cal_id, 
                       tipo, 
                       SUM(tAntesXfer) AS tAntesXfer, 
                       SUM(tDespuesXfer) AS tDespuesXfer
                FROM ccLogTransfers
                WHERE tipo = 2
                GROUP BY cal_id, 
                         tipo
            ) AS t ON c.cal_id = t.cal_id
            WHERE user_id = @user_id
                  AND cal_inicio > DATEADD(dd, -1, GETDATE())
            ORDER BY c.cal_inicio DESC
     SELECT *
     FROM @lastCallAgt
     ORDER BY hora DESC
     SET NOCOUNT OFF
        '
    	exec (@sql)

        set @process = 'CW-4869-Obtener-datos-de-la-tabla-general se agregan estados y se cambia nombres'
        set @sql = '
            ALTER PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                                         @InboundId AS SMALLINT
            AS
            BEGIN
                set nocount on;

                if(@Option = 1)
                begin
                    select 
                        ISNULL(count (*), 0) as Calls,
                        ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
                        ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
                        ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
                        ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
                        ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
                        ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
                        ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
                        ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
                        ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
                        THEN 1 ELSE NULL END), 0) AS Other
                    from ccCallsIn a (nolock)
                    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId

                end
                
            END'
        EXEC(@sql)

        set @process = 'CW-4869-Obtener-datos-de-la-tabla-general ccsp_GalateaAdminCampaigns se agrega Get Agents States with totals per campaign by admin id and campaign type'
        set @sql = '
            ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS SMALLINT, 
                                                        @CampType AS SMALLINT = 0, 
                                                        @WorkgroupId AS INT = 0, 
                                                        @Id AS INT = 0,
                                                        @AdminId AS SMALLINT = 0, 
                                                        @PinUpdate AS SMALLINT = 0, 
                                                        @LoadId AS INT = 0,
                                                        @Type AS SMALLINT = 0
            AS
            BEGIN
            set nocount on
            IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type 
            BEGIN
                IF @CampType = 1 -- Campaigns Out 
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                    BEGIN
                        SELECT CAST(IdCampEsp AS INT) AS Id 
                        FROM ccRIACampEspWG 
                        WHERE IDWG = @WorkgroupId AND Tipo=1
                        ORDER BY IdCampEsp ASC
                    END
                    ELSE
                    BEGIN
                        raiserror(''ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado'', 18, 1)
                    END 
                END
                IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                    BEGIN
                        SELECT CAST(IdCampEsp AS INT) AS Id 
                        FROM ccRIACampEspWG 
                        WHERE IDWG = @WorkgroupId AND Tipo=0
                        ORDER BY IdCampEsp ASC
                    END
                    ELSE
                    BEGIN
                        raiserror(''ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado'', 18, 1)
                    END 
                END
            END
                    
            IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id 
                BEGIN
                    IF @CampType = 1 -- Campaigns Out 
                        BEGIN
                            IF @Id IS NOT NULL
                                BEGIN
                                    SELECT DISTINCT 
                                        camps.cam_id AS Id, 
                                        camps.cam_descripcion AS Name, 
                                        CAST(graph.graphic_id AS INT) AS Frame, 
                                        CAST(1 AS SMALLINT) AS Type,
                                        camps.cam_procesando IsStarted,
                                        a.AreaName as Area
                                    FROM ccCamps camps 
                                    LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                                    left join ccRIACat_Areas a on a.IDArea = camps.IDArea
                                    WHERE camps.cam_id = @Id 
                                    ORDER BY camps.cam_descripcion ASC;
                                END
                            ELSE
                            BEGIN
                                raiserror(''ERROR. No existe campa?as de salida con el id especificado'', 18, 1)
                            END 
                        END
                    IF @CampType = 0 -- Campaigns In (ACD)
                        BEGIN
                            IF @Id IS NOT NULL
                                BEGIN
                                    SELECT DISTINCT 
                                        inb.Inbound_id AS Id, 
                                        inb.descripcion AS Name, 
                                        CAST(graph.graphic_id AS INT) AS Frame,
                                        CAST(0 AS SMALLINT) AS Type,
                                        CAST(inb.Status AS BIT) IsStarted,
                                        a.AreaName AS Area,
                                        inb.chat AS InboundType
                                    FROM ccInbound inb
                                    LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                                    left join ccRIACat_Areas a on a.IDArea = inb.IDArea
                                    WHERE inb.Inbound_id = @Id 
                                    ORDER BY inb.descripcion ASC;
                                END
                            ELSE
                                BEGIN
                                    raiserror(''ERROR. No existe campa?as de entrada con el id especificado'', 18, 1)
                                END 
                        END
                END

            IF @Option = 3   -- Update OverallTotalNew By Campaign 
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            UPDATE ccCampsNvosCB SET OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id
                        END
                    ELSE
                        BEGIN
                            raiserror(''ERROR. No existe la campa?as de entrada con el id especificado'', 18, 1)
                        END 
                END

            IF @Option = 4   -- Update Pin from Campaign per Admin
                BEGIN
                    IF @Id IS NOT NULL AND @AdminId IS NOT NULL
                        BEGIN
                            IF @PinUpdate = 1
                                BEGIN
                                    INSERT INTO PinedCampaigns (CampId, AdminId, Type)
                                            VALUES (@Id, @AdminId, @Type);
                                END;
                            IF @PinUpdate = 0
                                BEGIN
                                    DELETE FROM PinedCampaigns
                                    WHERE CampId = @Id AND AdminId = @AdminId AND Type = @Type;
                                END;
                        END
                    ELSE
                        BEGIN
                            raiserror(''ERROR. La campa?as o administrador no existen'', 18, 1)
                        END 
                END
                    
            IF @Option = 5   -- Get Pin from Campaign Ids per Admin
                BEGIN
                    IF @AdminId IS NOT NULL
                        BEGIN
                            SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
                            ORDER BY Id ASC
                        END
                    ELSE
                        BEGIN
                            raiserror(''ERROR. El administrador con el id seleccionado no existe'', 18, 1)
                        END 
                END

            IF @Option = 6   -- Get Blacklist Ids by Campaign Id
            BEGIN
                IF @Id IS NOT NULL
                    BEGIN
                        DECLARE @BlackListIds VARCHAR(MAX);
                        SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
                        FROM Camplistanegra
                        WHERE cam_id = @Id AND STATUS = 1;
                        SELECT isnull(@BlackListIds,''0'') AS BlackListIds;
                    END
                ELSE
                    BEGIN
                        raiserror(''ERROR. La campa?as con el id seleccionado no existe'', 18, 1)
                    END 
            END

            IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
            BEGIN
                IF (@Id IS NOT NULL AND EXISTS(SELECT * FROM cccamps WHERE cam_id = @Id))
                    BEGIN
                        SELECT TOP 1 list_id FROM ccRIARegistryLists WHERE cam_id = @Id AND status = 2 ORDER BY list_id DESC
                    END
                ELSE
                    BEGIN
                        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                        raiserror(''ERROR. No existe una campa?a con el id especificado'', 18, 1)           
                    END 
            END

            IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
            BEGIN
                IF (@LoadId IS NOT NULL AND EXISTS(SELECT * FROM ccRIARegistryLists WHERE list_id = @loadID and status <> 0))
                    BEGIN
                        UPDATE ccoCallsOutSource SET cal_status = ''5'' WHERE list_id = @loadID
                        DELETE FROM ccoWorkingTable WHERE list_id = @LoadId 
                        exec ccsp_RIARegistryLists @action=6, @list_id = @LoadId 
                    END
                ELSE
                    BEGIN
                        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                        raiserror(''ERROR. No existe una carga el id especificado'', 18, 1)
                    END     
            END

            IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
                    BEGIN
                        DECLARE @table TABLE
                        (camId    INT, 
                        campType TINYINT,
                        PRIMARY KEY(camId, campType)
                        );
                        INSERT INTO @table
                            SELECT DISTINCT 
                                    IdCampEsp, 
                                    Tipo
                            FROM ccRIACampEspWG wg
                            WHERE wg.IDWG IN
                            (
                                SELECT IDWG
                                FROM ccRIAWorkGroupUsers
                                WHERE IDWG <> @WorkgroupId
                                AND User_id = @AdminId
                            );
                        SELECT CAST(B.IdCampEsp AS INT) AS Id, 
                            B.Tipo AS Type
                        FROM @table A
                            RIGHT JOIN
                        (
                            SELECT wg.IdCampEsp, 
                                wg.Tipo
                            FROM ccRIACampEspWG wg
                            WHERE wg.IDWG = @WorkgroupId
                        ) B ON A.camId = B.IdCampEsp
                            AND A.campType = B.Tipo
                        WHERE A.camId IS NULL
                        ORDER BY IdCampEsp;
                END;
            IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type 
                BEGIN
                    DECLARE @date datetime = CONVERT(DATE, DATEADD(hh, -3, GETDATE()))
                    DECLARE @Wg TABLE(id INT, PRIMARY KEY(id));
                    DECLARE @tmpAgent TABLE(id INT, PRIMARY KEY(id));
                    DECLARE @tmpCamAgent TABLE(camId INT, userId INT, PRIMARY KEY( camId, userId ));
                    DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT);
                    DECLARE @AgentStatusWithTotals TABLE(CampName VARCHAR(MAX), Total INT, Ready INT, NotReady INT, Dialog INT, Area VARCHAR(MAX));

                    INSERT INTO @Wg
                            SELECT DISTINCT IDWG FROM ccRIAWorkGroupUsers WHERE user_id = @AdminId;

                    INSERT INTO @tmpAgent
                            SELECT DISTINCT  A.User_id FROM ccRIAWorkGroupUsers A
                            INNER JOIN @Wg B ON A.IDWG=B.id
                            INNER JOIN ccUsers C ON A.User_id=C.User_id AND C.TipoUser_id=1  
                            ORDER BY A.User_id;

                    INSERT INTO @tmpCamAgent
                            SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id FROM ccRIACampEspWG campPerWg
                            INNER JOIN @Wg wg ON wg.Id=campPerWg.IDWG
                            INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG=wg.id 
                            INNER JOIN ccUsers C ON wgUser.User_id=C.User_id AND C.TipoUser_id=1
                            WHERE campPerWg.Tipo = @CampType;

                    WITH lastState
                            AS ( SELECT A.user_id,  MAX( A.fecha ) AS fecha
                                FROM ccLogAgentesDia A
                                INNER JOIN @tmpAgent B ON A.User_id=B.id
                                WHERE fecha>= @date
                                GROUP BY user_id )


                            INSERT INTO @AgentStatus
                                SELECT A.camId,  A.userId, 
                                ISNULL( B.currentStatus, 0 ) currentStatus,
                                CASE WHEN B.IdCampEsp=A.camId AND B.Tipo = @CampType AND B.currentStatus IN( 4, 5, 6, 9 ) THEN 1 ELSE NULL END AS isCampDialog
                                FROM @tmpCamAgent A
                                LEFT JOIN
                                (
                                    SELECT B.User_id, 
                                            B.currentStatus, 
                                            B.IdCampEsp, 
                                            B.Tipo
                                    FROM lastState A
                                    INNER JOIN
                                    ccLogAgentesDia B
                                    ON A.User_id=B.User_id
                                        AND A.fecha=B.fecha
                                ) B
                                ON A.userId=B.User_id;

                    IF @CampType = 1
                        BEGIN
                            INSERT INTO @AgentStatusWithTotals
                            SELECT  B.cam_descripcion,
                                    COUNT( CurrentState ) as total,
                                    COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ) as ready, 
                                    COUNT( CASE WHEN CurrentState NOT IN( 3, 4, 5, 6, 9 )  THEN 1 ELSE NULL END) 
                                    + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
                                    
                                    as notReady,
                                    COUNT( isCampDialog ) as dialog,  
                                    C.AreaName
                            FROM @AgentStatus A
                            INNER JOIN ccCamps B on A.CampId=B.cam_id
                            INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                            GROUP BY B.cam_descripcion, CampId, C.AreaName
                        END 
                    ELSE 
                        BEGIN 
                            INSERT INTO @AgentStatusWithTotals
                            SELECT  B.descripcion,
                                    COUNT( CurrentState ),
                                    COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ), 
                                    COUNT( CASE WHEN CurrentState NOT IN(3, 4, 5, 6, 9 ) THEN 1 ELSE NULL END)
                                    + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
                                    ,
                                    COUNT( isCampDialog ), 
                                    C.AreaName
                            FROM @AgentStatus A
                            INNER JOIN ccInbound B on A.CampId = B.Inbound_id  
                            INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                            GROUP BY  B.descripcion, CampId , C.AreaName
                        END 
                             
                            
                    SELECT * FROM @AgentStatusWithTotals
                END;

            END'
        EXEC(@sql)

        set @process = 'CW-4869-Obtener-datos-de-la-tabla-general'
        set @sql = '
            ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS     INT, 
                                                            @sup_id AS   INT = 0, 
                                                            @agent_id AS INT = 0, 
                                                            @WG AS       INT = 0,
                                  @campId AS INT = 0
            AS
             SET NOCOUNT ON;
             IF @type = 1
                 BEGIN
                     WITH TableUserAgent(userId)
                          AS (SELECT DISTINCT 
                                   wgAgt.User_id  AS Id --,usr.login 
                              FROM ccriaworkgroupusers wgAdmin
                                   INNER JOIN ccriaworkgroupusers wgAgt ON wgAdmin.IDWG = wgAgt.IDWG
                                   INNER JOIN ccUsers usr ON usr.User_id = wgAgt.User_id
                                                             AND usr.TipoUser_id = 1
                              WHERE wgAdmin.User_id = @sup_id)
                          SELECT CAST(a.User_id AS INT) Id, 
                                 a.login AS Username, 
                                 a.Nombres + '' '' + a.ApellidoPaterno + '' '' + a.ApellidoMaterno AS Name
                          FROM ccusers a(NOLOCK)--, ccGenViewRelsSupsAgent b
                               INNER JOIN TableUserAgent b ON a.User_id = b.userId
                          ORDER BY a.Login ASC;
             END;
             IF @type = 2
                 BEGIN
                     SELECT CAST(User_id AS INT) Id,
                  Login Username, 
                            Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno Name
                     FROM ccUsers
                     WHERE User_id = @agent_id;
             END;
             IF @type = 3 --Agents by supervisor and WG
                 BEGIN
                     DECLARE @table2 TABLE
                     (userId INT
                      PRIMARY KEY NOT NULL
                     );
                     INSERT INTO @table2
                            SELECT DISTINCT 
                                   wg.User_id
                            FROM ccRIAWorkGroupUsers wg
                                 LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                            WHERE us.TipoUser_id = 1
                                  AND wg.IDWG IN
                            (
                                SELECT IDWG
                                FROM ccRIAWorkGroupUsers
                                WHERE User_id = @sup_id
                                      AND IDWG <> @WG
                            );
                     SELECT CAST(B.User_id AS int) AS Id
                     FROM @table2 A
                          RIGHT JOIN
                     (
                         SELECT DISTINCT 
                                wg.User_id
                         FROM ccRIAWorkGroupUsers wg
                              LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                         WHERE wg.IDWG = @WG
                               AND us.TipoUser_id = 1
                     ) B ON A.userId = B.User_id
                     WHERE A.userId IS NULL;
             END;

           IF @type = 4 --Agents IDs by WG
             BEGIN
            SELECT  CAST(wg.User_id AS INT) Id  
            FROM ccRIAWorkGroupUsers wg
            JOIN CCUsers u on u.user_id = wg.user_id AND u.TipoUser_id = 1
            where IDWG = @WG
             END;

           IF @type = 5 --Agents IDs by Campaign
             BEGIN
            SELECT Distinct(CAST(U.User_id AS INT)) Id FROM ccRIACampEspWG camp
            JOIN ccRIAWorkGroupUsers wg ON camp.IDWG = wg.IDWG
            JOIN ccUsers U ON U.User_id = WG.User_id AND U.TipoUser_id = 1
            WHERE IdCampEsp = @campId AND TIPO = 1
             END;

            IF @type = 6 -- Get Agent current state
           BEGIN
            WITH UserMaxFecha(User_id,fecha) as(
              SELECT User_id,max(fecha) as fecha from ccLogAgentesDia where fecha>=convert(date,getdate()) group by User_id
            )

            SELECT CASE WHEN CurrentState.currentStatus is null or  CurrentState.currentStatus<0 
                  then 0 else CAST(CurrentState.currentStatus as int) end CurrentState
            from ccUsers u
            left join 
            (
            select A.User_id,B.currentStatus from UserMaxFecha A 
            inner join ccLogAgentesDia  B on A.User_id=B.User_id and A.fecha=B.fecha
            ) CurrentState on u.User_id=CurrentState.User_id
            where u.TipoUser_id=1 and u.User_id = @agent_id
           END

           IF @type = 7 -- Get superuser id''s except root
           BEGIN
            declare @superuserId as int
            set @superuserId = (select Rol_id from ccRoles where Level = 7) -- obtenemos el id del rol superusuario

            select CAST(cr.User_id AS INT) User_id 
            from ccUsers_Roles cr
            where Rol_id = @superuserId
            and cr.User_id not in (1) 
           END

           IF @type = 8 -- Get all Agent''s ID, Login and Full Names related to a workgroup
           BEGIN
            SELECT DISTINCT 
              Convert(INT,wg.User_id) Id,
              us.Login Username,
              us.Nombres + '' '' + us.ApellidoPaterno + '' '' + us.ApellidoMaterno Name
            FROM ccRIAWorkGroupUsers wg
              LEFT JOIN ccUsers us ON wg.User_id = us.User_id
            WHERE wg.IDWG = @WG
              AND us.TipoUser_id = 1
           END

           SET NOCOUNT ON;'
        EXEC(@sql)

        set @process = 'CW-5028-Se borra sp ccsp_GalateaAdminBlackListCampout si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminBlackListCampout'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminBlackListCampout;
            end'
        EXEC(@sql)


set @process = 'CW-5028-Se Crea el nuevo sp ccsp_GalateaAdminBlackListCampout'
        set @sql = 'CREATE PROCEDURE ccsp_GalateaAdminBlackListCampout-- basandose del sp ccsp_RIABlackListCamp
@Option smallint,
@IDArea smallint = 0,
@CamID SmallInt = 0,
@InsertSchedule_id varchar(max) = ''0'',
@DeleteSchedule_id varchar(max) = ''0''
as

if @Option = 1 -- Asignar listas negras a una campaña de salida
 begin

  if @CamID = 0
   begin
    update Camplistanegra set status = 1 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))

    insert into Camplistanegra (idtipolista, cam_id, status)
    select FN.value, C.cam_id, 1 from ccCamps C, dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','') FN where C.IDArea = @IDArea
    and C.cam_id not in (select CL.cam_id from Camplistanegra CL join dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','') FN
    on CL.idtipolista = FN.value where CL.status = 1)
    return(0)
   end

  update Camplistanegra set status = 1 where cam_id = @CamID
  and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))

  insert into Camplistanegra (idtipolista, cam_id, status)
  select value, @CamID, 1 from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')
    where value not in (select idtipolista from Camplistanegra where cam_id = @CamID and status = 1
    and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')))

  Insert Into ccAgendaListaNegra (campsid,fecharegs,fechaaplicar) values (@CamID,''20100101'',getDate()) -- El 2010 es para que quite registros viejos con base en el cal fecha dial de ccocallsoutsource, principalmente para quitar callbacks de numeros cargados hace mucho tiempo

  declare @idAgenda as int
  select @idAgenda = SCOPE_IDENTITY()

  insert into ccAgenda_TipoListaNegra(idAgenda,idtipolista)
  select @idAgenda, value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')

  select DISTINCT idtipolista as BlacklistIdAssigned from Camplistanegra 
  where cam_id=@CamID and status=1 and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))
 end

if @Option = 2 -- Desasignar listas negras de la campaña de salida @CamID
 begin
  update Camplistanegra set status = 0 where cam_id = @CamID  and idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, '',''))
  return(0)
 end

if @Option = 3 -- Desasignar listas negras de todas las campañas de salida a las que esten asignadas
 begin
 update Camplistanegra set status = 0 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, '',''))
  return(0)
 end

 if @Option = 4 -- trae las listas negras de la campaña de salida indicada en @CamID
 begin
  select cl.cam_id as CampId, ca.cam_descripcion as CampName, cl.idtipolista as BlacklistId, tl.Tipolista as BlacklistName
  from Camplistanegra cl join ccCamps ca on cl.cam_id = ca.cam_id
   join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
  where cl.status = 1 and cl.cam_id = @CamID
  order by 1, 3
  return(0)
 end

set nocount off
'
EXEC(@sql)        

set @process = 'CW-5028-Se borra sp ccsp_GalateaAdminUploadBLst si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminUploadBLst'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminUploadBLst;
            end'
        EXEC(@sql)

set @process = 'CW-5028-Se Crea sp ccsp_GalateaAdminUploadBLst para asignar una numero a una lista negra'
    set @sql = '--GUIANDOSE DEL SP ccsp_RIAUploadBLst
CREATE PROCEDURE ccsp_GalateaAdminUploadBLst  @command TINYINT, @telephone VARCHAR(20) = 0, @idtipolista INT, @calKey AS VARCHAR(20) = NULL
AS

DECLARE @hashCalKey INT, @hashPhone BIGINT

SELECT @hashPhone = dbo.hashPhone(@telephone)

IF @calKey IS NOT NULL
BEGIN
  SELECT @hashCalKey = dbo.hashList(@calKey)
END

IF @hashCalKey IS NULL
BEGIN
  IF @command IN (1, 4) --LookForNumber 
    AND EXISTS (
      SELECT idtipolista
      FROM cclistanegra
      WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista
      )
  BEGIN
    SELECT 1

    RETURN (0)
  END
END
ELSE
BEGIN
  IF @command IN (1, 4) --LookForNumber 
    AND EXISTS (
      SELECT idtipolista
      FROM cclistanegra
      WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
      )
  BEGIN
    SELECT 1

    RETURN (0)
  END
END

IF @command = 1 --Insert Number
BEGIN
  EXEC ccsp_InsertDNCList @telephone, @idtipolista, @hashCalKey

  INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
  VALUES (@telephone, 1, @idtipolista)

  SELECT 200
END

IF @command = 2 --Delete Number
BEGIN
  INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
  VALUES (@telephone, 5, @idtipolista)

  IF @hashCalKey IS NULL
  BEGIN
    DELETE
    FROM cclistanegra
    WHERE Hashtel = @hashPhone AND HashKey IS NULL
  END
  ELSE
  BEGIN
    DELETE
    FROM cclistanegra
    WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey
  END

  RETURN (0)
END

IF @command = 3 --Reemplaza
BEGIN
  INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
  SELECT telefono, 4, @idtipolista
  FROM cclistanegra
  WHERE idtipolista = @idtipolista

  DELETE
  FROM cclistanegra
  WHERE idtipolista = @idtipolista

  RETURN (0)
END

IF @command = 5 --Delete by idtipolista
BEGIN
  UPDATE ccTiposListaNegra
  SET STATUS = 0
  WHERE idtipolista = @idtipolista

  DELETE ccAgendaListaNegra
  WHERE idagenda IN (
      SELECT idagenda
      FROM ccAgenda_TipolistaNegra
      WHERE idtipolista = @idtipolista
      )

  DELETE ccAgenda_TipolistaNegra
  WHERE idtipolista = @idtipolista

  DELETE cccalifblacklist
  WHERE idtipolista = @idtipolista

  DELETE Camplistanegra
  WHERE idtipolista = @idtipolista

  DECLARE @telefono VARCHAR(10)

  WHILE EXISTS (
      SELECT telefono
      FROM ccListaNegra
      WHERE idtipolista = @idtipolista
      )
  BEGIN
    SELECT TOP 1 @hashPhone = Hashtel, @telefono = telefono
    FROM ccListaNegra
    WHERE idtipolista = @idtipolista

    INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
    VALUES (@telefono, 5, @idtipolista)

    DELETE
    FROM cclistanegra
    WHERE Hashtel = @hashPhone AND idtipolista = @idtipolista
  END

  RETURN (0)
END

SET NOCOUNT OFF
'
        EXEC(@sql)  
  
        set @process = 'CW-4869-Obtener-datos-de-la-tabla-general- Se agrega camp de entrada en lista de agentes'
        set @sql = '
            ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS     INT, 
                                                            @sup_id AS   INT = 0, 
                                                            @agent_id AS INT = 0, 
                                                            @WG AS       INT = 0,
                                  @campId AS INT = 0,
                                  @CampType AS SMALLINT = 1
            AS
             SET NOCOUNT ON;
             IF @type = 1
                 BEGIN
                     WITH TableUserAgent(userId)
                          AS (SELECT DISTINCT 
                                   wgAgt.User_id  AS Id --,usr.login 
                              FROM ccriaworkgroupusers wgAdmin
                                   INNER JOIN ccriaworkgroupusers wgAgt ON wgAdmin.IDWG = wgAgt.IDWG
                                   INNER JOIN ccUsers usr ON usr.User_id = wgAgt.User_id
                                                             AND usr.TipoUser_id = 1
                              WHERE wgAdmin.User_id = @sup_id)
                          SELECT CAST(a.User_id AS INT) Id, 
                                 a.login AS Username, 
                                 a.Nombres + '' '' + a.ApellidoPaterno + '' '' + a.ApellidoMaterno AS Name
                          FROM ccusers a(NOLOCK)--, ccGenViewRelsSupsAgent b
                               INNER JOIN TableUserAgent b ON a.User_id = b.userId
                          ORDER BY a.Login ASC;
             END;
             IF @type = 2
                 BEGIN
                     SELECT CAST(User_id AS INT) Id,
                  Login Username, 
                            Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno Name
                     FROM ccUsers
                     WHERE User_id = @agent_id;
             END;
             IF @type = 3 --Agents by supervisor and WG
                 BEGIN
                     DECLARE @table2 TABLE
                     (userId INT
                      PRIMARY KEY NOT NULL
                     );
                     INSERT INTO @table2
                            SELECT DISTINCT 
                                   wg.User_id
                            FROM ccRIAWorkGroupUsers wg
                                 LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                            WHERE us.TipoUser_id = 1
                                  AND wg.IDWG IN
                            (
                                SELECT IDWG
                                FROM ccRIAWorkGroupUsers
                                WHERE User_id = @sup_id
                                      AND IDWG <> @WG
                            );
                     SELECT CAST(B.User_id AS int) AS Id
                     FROM @table2 A
                          RIGHT JOIN
                     (
                         SELECT DISTINCT 
                                wg.User_id
                         FROM ccRIAWorkGroupUsers wg
                              LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                         WHERE wg.IDWG = @WG
                               AND us.TipoUser_id = 1
                     ) B ON A.userId = B.User_id
                     WHERE A.userId IS NULL;
             END;

           IF @type = 4 --Agents IDs by WG
             BEGIN
            SELECT  CAST(wg.User_id AS INT) Id  
            FROM ccRIAWorkGroupUsers wg
            JOIN CCUsers u on u.user_id = wg.user_id AND u.TipoUser_id = 1
            where IDWG = @WG
             END;

           IF @type = 5 --Agents IDs by Campaign
             BEGIN
            SELECT Distinct(CAST(U.User_id AS INT)) Id FROM ccRIACampEspWG camp
            JOIN ccRIAWorkGroupUsers wg ON camp.IDWG = wg.IDWG
            JOIN ccUsers U ON U.User_id = WG.User_id AND U.TipoUser_id = 1
            WHERE IdCampEsp = @campId AND TIPO = @CampType
             END;

            IF @type = 6 -- Get Agent current state
           BEGIN
            WITH UserMaxFecha(User_id,fecha) as(
              SELECT User_id,max(fecha) as fecha from ccLogAgentesDia where fecha>=convert(date,getdate()) group by User_id
            )

            SELECT CASE WHEN CurrentState.currentStatus is null or  CurrentState.currentStatus<0 
                  then 0 else CAST(CurrentState.currentStatus as int) end CurrentState
            from ccUsers u
            left join 
            (
            select A.User_id,B.currentStatus from UserMaxFecha A 
            inner join ccLogAgentesDia  B on A.User_id=B.User_id and A.fecha=B.fecha
            ) CurrentState on u.User_id=CurrentState.User_id
            where u.TipoUser_id=1 and u.User_id = @agent_id
           END

           IF @type = 7 -- Get superuser id''s except root
           BEGIN
            declare @superuserId as int
            set @superuserId = (select Rol_id from ccRoles where Level = 7) -- obtenemos el id del rol superusuario

            select CAST(cr.User_id AS INT) User_id 
            from ccUsers_Roles cr
            where Rol_id = @superuserId
            and cr.User_id not in (1) 
           END

           IF @type = 8 -- Get all Agent''s ID, Login and Full Names related to a workgroup
           BEGIN
            SELECT DISTINCT 
              Convert(INT,wg.User_id) Id,
              us.Login Username,
              us.Nombres + '' '' + us.ApellidoPaterno + '' '' + us.ApellidoMaterno Name
            FROM ccRIAWorkGroupUsers wg
              LEFT JOIN ccUsers us ON wg.User_id = us.User_id
            WHERE wg.IDWG = @WG
              AND us.TipoUser_id = 1
           END

           SET NOCOUNT ON;'
        EXEC(@sql)

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
