/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/10/02
Description:

Database: CCenterRia
Required version: 122.22

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
SET @version = 122 --**********actualizar a 122 sin fix
SET @versionfix = 23
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 22
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-4458 setting cola espera'
		set @sql = 'if not exists(select setting_id from ccsettings where setting_id=225)
			begin
			insert ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values (225, 1, ''Configuracion de reproduccion de la cola de espera'', 1, ''GRL'', ''0:Reproducir solo callback, 1:Reproducir tiempo de espera y callback'', ''0:Play callback message only 1:Play EWT and callback message'', 1, ''^[0-1]$'')
			end
		'
		EXEC(@sql)

		set @process = 'CW-4320 ADD COLUMN THEME'
		set @sql = 'if not exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = ''theme'' and TABLE_NAME = ''ccUsers'') begin
					ALTER TABLE ccUsers
        			ADD theme SMALLINT NULL
 					CONSTRAINT C_ccusers_theme
    				DEFAULT (0)
					WITH VALUES
		end
		'
		EXEC(@sql)

		set @process = 'CW-4320 CREATE PROCEDURE ccsp_GalateaUserInfoManagemen'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUserInfoManagement'')
			    begin
			        DROP PROCEDURE ccsp_GalateaUserInfoManagement;
			    end'
		EXEC(@sql)

set @process = 'CW-4320 CREATE PROCEDURE ccsp_GalateaUserInfoManagement'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaUserInfoManagement] @Option AS SMALLINT,  
											  @UserId AS INT = 0, 
											  @Theme AS SMALLINT = 0--[dbo].[ccsp_GalateaUserInfo] 1, 3, 1
AS
BEGIN
	set nocount on
	IF @Option = 1	 -- Update user theme
		BEGIN
			IF @UserId IS NOT NULL AND @theme IS NOT NULL
				BEGIN
					UPDATE ccusers SET theme=@Theme
					WHERE User_id = @UserId;

				END
			ELSE
				BEGIN
					raiserror(''ERROR. El usuario no existe'', 18, 1)
				END	
		END
END		
'
EXEC(@sql)


set @process = 'CW-4320 ALTER SP ccsp_GalateaAdminLogin'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminLogin] @Login       VARCHAR(20) = '''', 
                                               @Password    VARCHAR(40) = '''', 
                                               @PasswordLwC VARCHAR(40) = NULL, 
                                               @IPAddress   VARCHAR(20) = '''', 
                                               @adminId     INT         = 0
AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @LoginOK BIT= 0, @PswdOK BIT= 0, @User_id SMALLINT, @Nombre VARCHAR(100), @ADMServer VARCHAR(300), @AreaId SMALLINT, @ViewAvrs INT, @changeRecDisposition INT, @PasswordExpired INT= 0, @UsernameMatch BIT= 1, @UserBlocked BIT= 0, @LastPasswordChange DATETIME, @Ext VARCHAR(80), @ViewAgents BIT= 0, @Theme smallint = 0;
        CREATE TABLE #temp
        (LoginOK              INT, 
         PswdOK               INT, 
         User_id              SMALLINT, 
         Nombre               VARCHAR(100), 
         ADMServer            VARCHAR(300), 
         AreaId               SMALLINT, 
         ViewAvrs             INT, 
         changeRecDisposition INT, 
         LastPasswordchange   INT
        );
        INSERT INTO #temp
        EXEC ccsp_RIAADMChecaLogin 
             @Login, 
             @Password, 
             @PasswordLwC, 
             @adminId;
        SELECT @LoginOK = LoginOK, 
               @PswdOK = PswdOK, 
               @Nombre = Nombre, 
               @ADMServer = ADMServer, 
               @AreaId = AreaId, 
               @ViewAvrs = ViewAvrs, 
               @changeRecDisposition = changeRecDisposition, 
               @PasswordExpired = LastPasswordchange
        FROM #temp;
        IF @LoginOK = 1
            BEGIN
                SELECT @User_id = User_id, 
                       @ViewAgents = viewAgents,
					   @Theme = theme
                FROM ccUsers
                WHERE Login = @Login;
                DECLARE @LastLoginAttempt DATETIME, @LoginAttempts INT, @MaxAttemptsAllow INT, @TimeBloqued INT, @TimeFromLastAttempt INT;
                SELECT @LastLoginAttempt = LastLoginAttempt, 
                       @LoginAttempts = LoginAttempts, 
                       @LastPasswordChange = LastPasswordChange
                FROM ccUsers
                WHERE User_id = @User_id;
                SELECT @MaxAttemptsAllow = valor
                FROM ccSettings
                WHERE setting_id = 198;
                SELECT @TimeBloqued = valor
                FROM ccSettings
                WHERE setting_id = 197;
                SELECT @TimeFromLastAttempt = DATEDIFF(MINUTE, @LastLoginAttempt, GETDATE());
                IF @LoginAttempts > @MaxAttemptsAllow
                    BEGIN
                        SET @LoginAttempts = 0;
                        UPDATE ccUsers
                          SET 
                              LoginAttempts = 0, 
                              LastLoginAttempt = GETDATE()
                        WHERE User_id = @User_id;
                END;
                IF(@LoginAttempts >= @MaxAttemptsAllow
                   AND @TimeFromLastAttempt < @TimeBloqued)
                    BEGIN
                        SET @UserBlocked = 1;
                END;

                --Checks Username match case sensitive    
                IF CAST(@Login AS VARBINARY(200)) <>
                (
                    SELECT CAST(LOGIN AS VARBINARY(200))
                    FROM ccUsers
                    WHERE User_id = @User_id
                )
                    BEGIN
                        SET @UsernameMatch = 0;
                END;

                --Increments attemps if error
                IF @UserBlocked = 0
                   AND (@UsernameMatch = 0
                        OR @PswdOK = 0)
                    BEGIN
                        UPDATE ccUsers
                          SET 
                              LoginAttempts = @LoginAttempts + 1, 
                              LastLoginAttempt = GETDATE(), 
                              onLine = 0
                        WHERE User_id = @User_id;
                END;

                --Sets to default to try another attempt
                DECLARE @ExpirationTime INT;
                SELECT @ExpirationTime = valor
                FROM ccSettings
                WHERE setting_id = 29;
                SELECT @PasswordExpired = (CASE
                                               WHEN DATEDIFF(DAY, LastPasswordChange, GETDATE()) > @ExpirationTime
                                                    AND @ExpirationTime > 0
                                               THEN 1
                                               ELSE 0
                                           END)
                FROM ccUsers;
                IF @UserBlocked = 0
                   AND @UsernameMatch = 1
                   AND @PswdOK = 1
                   AND @PasswordExpired = 0
                    BEGIN
                        UPDATE ccUsers
                          SET 
                              LoginAttempts = 0, 
                              LastLoginAttempt = GETDATE(), 
                              onLine = 1
                        WHERE User_id = @User_id;
                END;
                SELECT @Ext = dbo.fn_Ext_X_ip(@IPAddress);
                
				DECLARE @WorkGroup VARCHAR(MAX);
                SELECT @WorkGroup = COALESCE(@WorkGroup + ''|'' + CAST(IDWG AS VARCHAR(MAX)), CAST(IDWG AS VARCHAR(MAX)))
                FROM ccRIAWorkGroupUsers
                WHERE User_id = @User_id;
        END;
        SELECT @LoginOK UserExists, 
               @UserBlocked UserBlocked, 
               @UsernameMatch UsernameMatch, 
               @PswdOK PasswordMatch, 
               CAST(@PasswordExpired AS BIT) PasswordExpired, 
               @User_id UserID, 
               @Nombre Name, 
               @ADMServer ADMServer, 
               @AreaId AreaId, 
               @ViewAvrs ViewAvrs, 
               @changeRecDisposition ChangeRecDisposition, 
               @Ext Ext, 
               isnull(@ViewAgents,0) ViewAgents,
			   ISNULL(@WorkGroup, 0) WorkGroup,
			   ISNULL(@Theme, 0) Theme;
    END;
'
		EXEC(@sql)

		set @process = 'CW-4451 ALTER PROCEDURE ccsp_MailSave'
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
    --insert into [attached](messageId,pathFile,isUser) values(@messageId,@pathFile,@isUser)
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
		max(B.[date]) MsgTimestamp
    from conversation A
    inner join message B  on A.conversationId = B.conversationId
    inner join ccinbound C on A.inboundid= C.inbound_id
    left join ccUsers D on B.userId = D.User_id
    inner join contactMeanIn E on E.inboundId=C.Inbound_id   and E.meanContactTypeId=@meanContactTypeId
	inner join ccRIAinboundGraph F on C.Inbound_id = F.Inbound_id
	inner join ccRIAGraphics G on F.graphic_id = g.graphic_id
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

END'
		EXEC(@sql)

		set @process = 'CW-4279 ALTER PROCEDURE ccspAgent_GetLastCalls'
		set @sql = 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
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
            SELECT TOP 10 c.cal_id AS id, 
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
                  AND cal_inicio > DATEADD(hh, -3, GETDATE())
            ORDER BY c.cal_inicio DESC
     INSERT INTO @lastCallAgt
            SELECT TOP 10 c.cal_id AS id, 
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
                  AND cal_inicio > DATEADD(hh, -3, GETDATE())
            ORDER BY c.cal_inicio DESC
     SELECT *
     FROM @lastCallAgt
     ORDER BY hora DESC
     SET NOCOUNT OFF'
		EXEC(@sql)
		

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		-- exec ccsp_getVersion 'BD', @version
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
