/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/03/06
Description:

Database: CCenterRia
Required version: 122.14

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

IF @actualVersion = @version AND @actualVersionFix >= 15
BEGIN
    BEGIN TRAN

    BEGIN TRY

        set @process = 'Se registra reporte Agent Summary en BD'
        set @sql='
        if not exists(select * from ccMenus where menu_id=2100) begin
            insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release) values
            (2100,''Resumen de agente|Agent summary'',2000, ''B'', 2, 3, '''', ''875116a11e987ae3b690eedb9cfea927a96b85c266832a3760107db8e5817f901fe9324fde95cb986465c3399ea18173'')
        end 
            '
        EXEC(@sql)


         set @process = 'CW-3916 DROP PROCEDURE ccsp_GalateaAdminGetAgentCounters Obtener información de estados del agente por camp Drop if exists ccsp_GalateaAdminGetAgentCounters'
        set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminGetAgentCounters'')
        begin
            DROP PROCEDURE ccsp_GalateaAdminGetAgentCounters;
        end'
        exec (@sql)

         set @process = 'CW-3916 CREATE PROCEDURE ccsp_GalateaAdminGetAgentCounters Obtener información de estados del agente por camp 
                        Se agrega accion 6 para regresar el estado actual del agente'
        set @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS     INT, 
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
        SELECT User_id,max(fecha) as fecha from ccLogAgentesDia where fecha>=convert(datetime,convert(varchar(10),getdate(),121)) group by User_id
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
    SET NOCOUNT ON;'
        exec (@sql)
        
        
        set @process = 'CW-4001 Alter procedure ccsp_MailSave'
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
@top int=30
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
    where A.meanContactTypeId = 1 --and (@inboundId is null or A.inboundId=3)
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

    SELECT @existAttached = case when count(*)>0 then 1 else 0 end
    from attached where messageId in (select messageId from message where conversationId=@conversationId)

    select max(B.messageId) as MessageID, cast(max(A.inboundid) as int) as InboundID, max(A.conversationid) as ConversationID,
        max(A.mailClient) as ClientEmail, min(B.[date]) as [Date], @existAttached isAttached, max(C.descripcion) as ACDName,
        max(B.tSend) as tSend, max(D.Nombres+'' ''+D.ApellidoPaterno+'' ''+D.ApellidoMaterno) as NameAgent,
        cast(max(E.timeAlertMessage) as int) tAlertMessage, cast(max(E.answerTimeOut) as int) tAnswerTimeOut, max(C.tNotas) as tWrapUp,
        max(A.mailInbound) as InboundEmail, isnull(max(E.name), '''') as SenderName, cast(max(F.graphic_id) as int) as ACDGraphicID
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

END'
        exec (@sql)
        
        set @process = 'CW-3908 Alter SP ccsp_RIAManageAreas'
        set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAManageAreas]
@option tinyint,
@IDArea smallint = 0,
@InsertUserId smallint =null,
@DeleteUserId varchar(255)=null,
@InsertCamId smallint=null,
@DeleteCamId smallint=null,
@InsertACDGroupId smallint=null,
@DeleteACDGroupId smallint=null
as
set nocount on

if @option = 1 -- Insert User Area
    begin
    if not exists(select IDArea from ccUsers where IDArea = @IDArea AND User_id = @InsertUserId)
        begin
        Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @InsertUserId
        return(0)
        end 
                     
    select 1
    return(0)
    end

if @option = 3 -- Insert camp area
    begin
    if not exists(select IDArea from ccCamps where IDArea = @IDArea and cam_id = @InsertCamId)
        begin
        Update ccCamps set IDArea = case @IDArea when 0 then null else @IDArea end
        where cam_id = @InsertCamId
        return(0)
        end

    select 1
    return(0)
    end

if @option = 4 begin-- Delete camp area
    

    --Si existe una campaña relacionada con el grupo
    if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
        select -4
        return(0)    
    end

    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId
                 
    delete from ccCampsAgente where cam_id = @DeleteCamId   

    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1    

    delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
    delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1  
    delete from ccoWorkingTable where cam_id = @DeleteCamId
    
    Update ccCamps set IDArea= null where cam_id=@DeleteCamId--, cam_activo = 0 
    return(0)
    end

if @option = 5 -- Insert ACDGroup area
    begin
    if not exists(select IDArea from ccInbound where IDArea = @IDArea and Inbound_Id = @InsertACDGroupId)
        begin
        Update ccInbound set IDArea = @IDArea, status = 1 where Inbound_id = @InsertACDGroupId
        return(0)
        end

    select 1
    return(0)
    end

if @option = 6 -- Delete ACDGroup area
    begin
        insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

    delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
    delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId

    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId and A.tipo = 0

    delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
    delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
    delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

    Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId
    select 1
    return(0)
    end

if @option in (2, 9, 10, 11)
    begin
        declare @Type tinyint
    select @Type = TipoUser_id from ccUsers where User_id = @DeleteUserId
                    
    if @option in (2, 10, 11) -- Delete User area
        begin
        if @Type = 1 -- Agente
            begin

            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
            insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

            delete from ccCampsAgente where user_id = @DeleteUserId
            delete from ccInboundAgentes where user_id = @DeleteUserId

            if @option = 11
                begin
                    select IDWG, User_id into #WorkGroupUsers from ccRIAWorkGroupUsers where user_id = @DeleteUserId

                    delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
                                    
                    select * from #WorkGroupUsers
                    drop table #WorkGroupUsers
                                    
                    return(0)
                end
            end

        else if @Type in (2, 6) -- Supervisor
        begin
            insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
            delete from ccSupervisorCam where user_id = @DeleteUserId
        end

        delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
                        
        if @option=2
            begin
            update ccPosicion set user_id = 0 where user_id = @DeleteUserId
            update ccUsers set IDArea = null where user_id = @DeleteUserId  
            end
        return(0)
    end

    declare @UserWG varchar(100)
    -- @option = 9 -- Delete User area and get his workgroups

    select @UserWG = IDWG from ccRIAWorkGroupUsers where user_id = @DeleteUserId

    if @Type = 1 -- Agente
        begin
        insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG   from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
        insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

        delete from ccCampsAgente where user_id = @DeleteUserId
        delete from ccInboundAgentes where user_id = @DeleteUserId
        end

    if @Type in (2, 6) -- Supervisor
        begin
        insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId

        delete from ccSupervisorCam where user_id = @DeleteUserId
        delete from ccMenuUser where id_User = @DeleteUserId
        end

    delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
    update ccPosicion set user_id = 0 where user_id = @DeleteUserId
                    
    if @option <> 11
        update ccUsers set IDArea = null where user_id = @DeleteUserId
                    
    select @UserWG, @Type
    return(0)
    end

declare @AllWG varchar(400), @CurrentWG varchar(400), @AreaDescripcion varchar(40)

if @option = 7 begin-- Delete camp area
    
    if exists(select cam_id from ccInbound where cam_id=@DeleteCamId) begin
    
        ---Borra las calificacion con reprogramacion
        delete ccCalifCamp from ccInbound A 
        inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
        inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
        where A.cam_id=@DeleteCamId
        ---Borra las subcalificacion con reprogramacion
        delete rel from ccInbound A 
        inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
        inner join ccTipoCalif C on B.calif_id=C.calif_id 
        inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
        inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
        where A.cam_id=@DeleteCamId and sb.canReprogram=1
    
        update ccInbound set cam_id = null where cam_id=@DeleteCamId                
         
    end

    select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId

    delete from ccCampsAgente where cam_id = @DeleteCamId
    insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1

    delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
    delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1
    
    delete from ccoWorkingTable where cam_id = @DeleteCamId  

    select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

    select @AreaDescripcion = area.AreaName
    from ccCamps as camp with(nolock)inner join ccRIACat_Areas as area 
        with(nolock) on camp.IDArea = area.IDArea
    where camp.cam_id = @DeleteCamId
    Update ccCamps set IDArea = null where cam_id = @DeleteCamId

    If @CurrentWG is null
        set @CurrentWG = 0

    If @AllWG is null
        set @AllWG = 0

    select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
    return(0)
    end

if @option = 8 --Delete ACDGroup area
    begin
    if (select cam_id from ccInbound where Inbound_id = @DeleteACDGroupId) is not null
    begin
        update ccInbound set cam_id = null where Inbound_id = @DeleteACDGroupId
    end

    select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

    insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

    delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
    delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId

    insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId 

    delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
    delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
    delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

    select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
    from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

    select @AreaDescripcion = area.AreaName
    from ccInbound as ACD with(nolock) inner join ccRIACat_Areas as area 
        with(nolock) on ACD.IDArea = area.IDArea
    where ACD.Inbound_id = @DeleteACDGroupId
    Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId

    If @CurrentWG is null
        set @CurrentWG = 0

    If @AllWG is null
        set @AllWG = 0

    select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
    
    if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId=@DeleteACDGroupId)--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
    begin
        DECLARE @TwitterResult table(--Se declaro por que el SP ccsp_MailAdminAccount regresa una consulta.  
        result int,  
        operation varchar(30));
        insert @TwitterResult
        EXEC [dbo].[ccsp_MailAdminAccount] @action = 22,@meanContactTypeId = 2, @inboundId = @DeleteACDGroupId--se ejecutara el SP para desasociar la cuenta de mail
    end
    if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId=@DeleteACDGroupId)--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
    begin
        update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId = @DeleteACDGroupId and meanContactTypeId=1
    end
    update ccinbound set chatDomain = '''' where inbound_id = @DeleteACDGroupId--para desasociar el dominio del chat
    return(0)
    end

return(0)
set nocount off'
        EXEC(@sql)


        set @process = 'CW-4201 Alter SP ccsp_RIAConfEspec'
        set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
@User_id int
AS
set nocount on
/****
Conexion Info Email In
  protocol|server|ssl|port|cleanMail|revisionTime
Conexion Info Email Out
  serverOut|portOut|tls|sslOut
Conexion Info Twitter
  usuarioID|token|tokenSecret|time|daysTwitterRecord
***/
select  A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat mode, A.inactiveChatTime, A.maxChats, isnull(A.chatDomain,'''') chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
isnull(A.startStopRecording,0) startStopRecording
,isnull(B.name,'''') as nameMail,isnull(B.conexionInfo,'''') as conexionInfo,isnull(B.connUser,'''') as connUser,
isnull(B.ConnPass,'''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage,
isnull(B.IsActive,0) as Active, isnull(B.answerTimeOut,0) as answerTimeOut,
case when A.cam_id > 0   and C.callsBySurvey>0 then A.callBackSurveyAgent else 0 end callBackSurveyAgent,
case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyClient else 0 end callBackSurveyClient,
case when A.cam_id > 0  and C.callsBySurvey>0 then 1 else 0 end isRelationSurvey,
isnull(A.agts_notavailable,'''') as agts_notavailable,
isnull(nameTwitter,'''') nameTwitter,isnull(userTwitter,'''') userTwitter,isnull(numMessagesTwitter,3) numMessagesTwitter,
isnull(timeAlertMessageTwitter,10) timeAlertMessageTwitter,isnull(ActiveTwitter,0) ActiveTwitter,isnull(answerTimeOutTwitter,10) answerTimeOutTwitter,
--usuarioID|token|tokenSecret|time|daysTwitterRecord
isnull(conexionInfoTwitter,''usuarioID|token|tokenSecret|1|0'') conexionInfoTwitter
,isnull(closeConversationTimeTwitter,3) closeConversationTimeTwitter,isnull(closeConversationTime,3) closeConversationTimeEmail
,isnull(A.editableDtmf,0) as editableDtmf
,isnull(gra.graphic_id,1) as frame
,isnull(A.prefijo,'''') as prefijo
,isnull(A.addDataCallBackReminder,0) as addDataCallBackReminder
,isnull(Conv.hasMessage,0) as hasMessageMail
from ccInbound A
left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
left join ContactMeanIn B on A.inbound_id=B.inboundId and B.meanContactTypeId=1
left join ccCamps C on C.cam_id=A.cam_id
left join(

select GP.inboundId,case when count(*)>0 then 1 else 0 end hasMessage 
 from (
  select A.inboundId, A.conversationId, max(B.messageId) messageId  from conversation A 
  inner join message B  on A.conversationId = B.conversationId  where A.isFinished=0
    GROUP BY A.inboundId,A.conversationId
  ) GP
inner join message M on GP.messageId=M.messageId and messageStatusId not in(6,10,11,12,13)
group by inboundId

)  Conv on Conv.inboundId=A.inbound_id

left join (
select D.inboundId,
D.name as nameTwitter,D.connUser as userTwitter,D.numMessages as numMessagesTwitter,
D.timeAlertMessage as timeAlertMessageTwitter,
D.IsActive as ActiveTwitter, D.answerTimeOut as answerTimeOutTwitter,D.conexionInfo as conexionInfoTwitter,
closeConversationTime as  closeConversationTimeTwitter
from ContactMeanIn D
where D.meanContactTypeId=2) D on A.Inbound_id=D.inboundId
where A.inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 4))
return(0)
set nocount off
'
        EXEC(@sql)

        set @process = 'CW-4038 Alter SP ccsp_DLRSaveDialResult'
        set @sql='ALTER PROCEDURE dbo.ccsp_DLRSaveDialResult 
                @callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
                @tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
                @canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '''', @cal_key VARCHAR(20)= '''', @call_TS VARCHAR(15)=
                ''''
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tNow AS DATETIME, @RecicleSIC TINYINT;
    DECLARE @logDial_id INT;
    DECLARE @tAnswerBitFinal AS DATETIME;

    SELECT @RecicleSIC = ISNULL(valor, 0)
    FROM ccSettings
    WHERE setting_id = 60;

    SELECT @tNow = GETDATE();

    SELECT @tAnswerBitFinal = DATEADD(ss, -@tAnswerBit, @tNow);

    IF @call_id > 0 AND 
       @tipoResDial_id = 1
    BEGIN
        INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
        TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id )
               SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy,
               ''00000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.
               fnGetTipoLlamada( @Telefono );
    END;
         ELSE
    BEGIN
        INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
        TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id )
               SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy,
               ''00000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(
               @Telefono );
    END;

    SELECT @logDial_id = SCOPE_IDENTITY();

    IF @RecicleSIC = 1
    BEGIN
        UPDATE ccoWorkingTable WITH(ROWLOCK)
          SET tipoResDial_id = @tipoResDial_id
        WHERE callout_id = @callout_id;
    END;

    SELECT @logDial_id;

    -- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
    IF @call_id > 0 AND 
       @tipoResDial_id = 1
    BEGIN
        UPDATE ccoCallsOut WITH(ROWLOCK)
          SET cal_puerto = @Puerto, cal_manual = CASE
                                                 WHEN cal_manual = 1 THEN 2
                                                      ELSE cal_manual
                                                 END
        WHERE cal_id = @call_id AND 
              cal_puerto = 0;

        EXEC ccsp_CstoCalculaCosto @call_id;

        IF @cal_key = ''''
        BEGIN
            SELECT @cal_key = cal_key
            FROM ccoCallsOutSource WITH(NOLOCK)
            WHERE @callout_id = callout_id;

            UPDATE ccologdials WITH(ROWLOCK)
              SET cal_key = @cal_key
            WHERE logDial_id = @logDial_id;
        END;
    END;

    -- inserta informacion para reportes de workgroup
    INSERT INTO ccRIAWorkGroup_logDial_id( IDWG, logDial_id, cam_id, TIMESTAMP )
           SELECT IDWG, @logDial_id, IdCampEsp, GETDATE()
           FROM ccRIACampEspWG
           WHERE tipo = 1 AND 
                 IdCampEsp = @cam_id;

    -- Guarda configuracion de TipoDialingMode
    UPDATE ccoLogDials WITH(ROWLOCK)
      SET TipoDialingMode = dbo.fn_getDialingMode( @call_id, 0, @logDial_id, @cam_id )
    WHERE logDial_id = @logDial_id;
    SET NOCOUNT OFF;
END;'
        EXEC(@sql)
        
        SET @process = 'CW-3957 Registrar reporte en ccMenus'
SET @sql = '
if not exists(select * from ccMenus where menu_id = 4260) begin
    insert into ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release) values (4260, ''Llamadas de salida Intervalos|Outbound Calls Intervals'', 4000, ''B'', 4, 3, '''',''7651cad7f793d912a0ee0b08f3f931296bcf3d27ae4e71bfcfb00c19a95535b66135ea334e3e95860576d463de30ee75907aac1eb3a31510e467cc3a2cdaa7ed'')
end
'
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
