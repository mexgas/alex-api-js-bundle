/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/05/06
Description:

Database: CCenterRia
Required version: 122.17

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
SET @versionfix = 18
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 17
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-4083 Mostrar número de llamadas atendidas y canceladas'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetCampaignOutDialingStats'')
	    begin
	        DROP PROCEDURE ccsp_GalateaGetCampaignOutDialingStats;
	    end'
		EXEC(@sql)

		set @process = 'CW-4083 Mostrar número de llamadas atendidas y canceladas'
		set @sql='
			CREATE PROCEDURE [dbo].[ccsp_GalateaGetCampaignOutDialingStats]
			@Tipo as tinyint=0,
			@cam_id as smallint = 0,
			@sup_id as smallint=0
			AS
			BEGIN

				DECLARE @table TABLE
					 (cam_id SMALLINT, 
					  Calls INT,
					  Answer INT,
					  Busy INT,
					  NoAnswer INT,
					  Fax INT,
					  NoService INT,
					  Other INT,
					  Canceled INT,
					  Machine INT,
					  NoTone INT,
					  Congestion INT,
					  Abandon INT
					  PRIMARY KEY(cam_id)
					 );
					 
			    INSERT INTO @table
			    	EXEC ccsp_OUTGetCallsInfo_AllCamps @Tipo, @cam_id, @sup_id

					select L.*, (L.Attended-L.Xfer) AS Assigned
					
					from
					(

						select A.*, C.Xfer,
						((A.Abandon *100.0)/ A.Answer) as AbandonRate,
						(A.Answer - A.Abandon - A.Canceled) as Attended
						
						from @table as A

						left join(
							select ccC.cam_id, ccC.aggressionFactor
							from ccCamps as ccC
						)B ON A.cam_id = B.cam_id

						left join(
							select Cco.cam_id, COUNT(CASE WHEN Cco.statusCall_id >= 10 THEN 1 END) AS  Xfer
							from ccoCallsOut  as cco
							right join (
								select distinct supCam.cam_id from ccSupervisorCam supCam where user_id=@sup_id
							) D ON Cco.cam_id = D.cam_id
							Where cal_Inicio >  convert(smalldatetime, convert(varchar(11), getdate() ), 101)
							group by Cco.cam_id
						)C ON A.cam_id = C.cam_id

					)L

			END
		'
		EXEC(@sql)	


		set @process = 'CW-4123,CW-4124 Alter procedure ccsp_MailSave'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_MailSave]
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

END'
		EXEC(@sql)

		

----------------------------------------------------------------------------------------------------------

		set @process = 'CW-4082 If there are role tables remove'
		set @sql='
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = ''BASE TABLE''
          AND TABLE_NAME = ''ccUsers_Roles''
)
    BEGIN
        DROP TABLE [dbo].[ccUsers_Roles]
END
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = ''BASE TABLE''
          AND TABLE_NAME = ''ccRoles_Permissions''
)
    BEGIN
        DROP TABLE [dbo].[ccRoles_Permissions]
END

IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = ''BASE TABLE''
          AND TABLE_NAME = ''ccPermissions''
)
    BEGIN
        DROP TABLE [dbo].[ccPermissions]
END
IF EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = ''BASE TABLE''
          AND TABLE_NAME = ''ccRoles''
)
    BEGIN
        DROP TABLE [dbo].[ccRoles]
END'
		EXEC(@sql)

		set @process = 'CW-4082 Create table ccRoles'
		set @sql='CREATE TABLE [dbo].[ccRoles](
	[Rol_id] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NULL,
	[KeyJson] [varchar](250) NULL,
	[CreateDate] [datetime] NULL,
	[Active] [bit] NULL,
	[Rowguid] [uniqueidentifier] ROWGUIDCOL  NULL,
	[Level] [smallint] NULL,
 CONSTRAINT [PK_ccRoles] PRIMARY KEY CLUSTERED 
(
	[Rol_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
ALTER TABLE [dbo].[ccRoles] ADD  CONSTRAINT [DF_ccRoles_Rowguid]  DEFAULT (newid()) FOR [Rowguid]'
		EXEC(@sql)

		set @process = 'CW-4082 Create table ccPermission'
		set @sql='CREATE TABLE [dbo].[ccPermissions](
	[Permissions_Id] [int] NOT NULL,
	[Description] [varchar](250) NULL,
	[KeyJson] [varchar](250) NULL,
	[Parent] [smallint] NULL,
	[Type] [smallint] NULL,
	[OrderGrl] [smallint] NULL,
	[Release] [varchar](max) NULL,
	[Active] [bit] NULL,
	[Rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
 CONSTRAINT [PK_ccPermisos] PRIMARY KEY CLUSTERED 
(
	[Permissions_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE [dbo].[ccPermissions] ADD  CONSTRAINT [DF_ccPermissions_Type]  DEFAULT ((1)) FOR [Type]
ALTER TABLE [dbo].[ccPermissions] ADD  CONSTRAINT [DF__ccPermissions__OrderGrl__7F01C5FD]  DEFAULT ((1)) FOR [OrderGrl]
ALTER TABLE [dbo].[ccPermissions] ADD  DEFAULT ('') FOR [Release]
ALTER TABLE [dbo].[ccPermissions] ADD  CONSTRAINT [DF_ccPermissions_Rowguid]  DEFAULT (newid()) FOR [Rowguid]


'
		EXEC(@sql)

		set @process = 'CW-4082 Create table ccUsers_Roles'
		set @sql='CREATE TABLE [dbo].[ccUsers_Roles](
	[User_id] [smallint] NOT NULL,
	[Rol_id] [int] NOT NULL
	CONSTRAINT [FK_ccUsers_Roles_ccRoles]
		FOREIGN KEY([Rol_id]) REFERENCES [dbo].[ccRoles] ([Rol_id]),
	CONSTRAINT [FK_ccUsers_Roles_ccUsers]
		FOREIGN KEY([User_id]) REFERENCES [dbo].[ccUsers] ([User_id])
) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [Index_Users_Roles] ON [dbo].[ccUsers_Roles]
(
	[User_id] ASC,
	[Rol_id] ASC
)'
		EXEC(@sql)

		set @process = 'CW-4082 Create table ccRoles_Permissions'
		set @sql='CREATE TABLE [dbo].[ccRoles_Permissions](
	[Rol_Id] [int] NOT NULL,
	[Permissions_Id] [int] NOT NULL
	CONSTRAINT [FK_ccRoles_Permissions_ccRoles]
      FOREIGN KEY ([Rol_Id]) REFERENCES [dbo].[ccRoles] ([Rol_Id]),
	CONSTRAINT [FK_ccRoles_Permissions_ccPermissions] 
	  FOREIGN KEY([Permissions_Id]) REFERENCES [dbo].[ccPermissions] ([Permissions_Id])
)

CREATE UNIQUE NONCLUSTERED INDEX [Index_Roles_Permissions] ON [dbo].[ccRoles_Permissions]
(
	[Rol_Id] ASC,
	[Permissions_Id] ASC
)'
		EXEC(@sql)

		set @process = 'CW-4082 Insert into  ccRoles and ccPermissions tables'
		set @sql='insert into ccroles values (''Root'',''translate_root'',GetDate(),1,NEWID(),1)
insert into ccroles values (''Admin'',''translate_admin'',GetDate(),1,NEWID(),2)
insert into ccroles values (''Supervisor'',''translate_supervisor'',GetDate(),1,NEWID(),3)
insert into ccroles values (''Monitor'',''translate_monitor'',GetDate(),1,NEWID(),4)

insert into ccPermissions values(10001,''Iniciar y detener campañas|Start and stop Campaign'',''translate_start_stop_camp'',0,0,0,''N/A'',1,NEWID())
insert into ccPermissions values(10002,''Carga de base de datos|Data Import'',''translate_data_import'',9,1,26,''644f3f9a7013f33219aae30ca25565240c0234b9a50a88494c16bb33bf9d3303b9cccff75b50ddb09b2242c5b3dbaf78'',1,NEWID())
insert into ccPermissions values(10003,''Sólo Monitoreo|Only Monitoring'',''translate_monitoring'',0,0,0,''N/A'',1,NEWID())
insert into ccPermissions values(10004,''CenterScript|CenterScript'',''translate_centerScript'',0,0,0,''N/A'',1,NEWID())'
		EXEC(@sql)

		set @process = 'CW-4083 if exists sp ccsp_GalateaAdminRolesManagement drop '
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminRolesManagement'')
	    begin
	        DROP PROCEDURE ccsp_GalateaAdminRolesManagement;
	    end'
		EXEC(@sql)

		set @process = 'CW-4082 Create sp ccsp_GalateaAdminRolesManagement'
		set @sql='---- =============================================
---- Author:		ulises Espinosa
---- Create date: 15/05/2020
---- Description:	Role management and permissions in galatea Admin
---- =============================================
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminRolesManagement]
	@action SMALLINT,
	@User_id VARCHAR(MAX)= '''',
	@subaction VARCHAR(50)= '''',
	@description VARCHAR(250)= '''',
	@keyJson VARCHAR(250)= '''',
	@active BIT= 1,
	@Roles_id VARCHAR(MAX)= '''',
	@Permissions_Id VARCHAR(MAX)= '''',
	@menus_id VARCHAR(250)= ''''
AS
--DECLARE
--	@action SMALLINT = 4,
--	@User_id VARCHAR(MAX) = ''2'',
--	@subaction VARCHAR(50)= '''',
--	@description VARCHAR(250)= ''aa'',
--	@keyJson VARCHAR(250)= '''',
--	@active BIT= 1,
--	@Roles_id VARCHAR(50)= ''1070'',
--	@Permissions_Id VARCHAR(MAX)= ''1,2'',
--	@menus_id VARCHAR(250)= ''''
BEGIN TRY
    BEGIN TRANSACTION-- Inicia el bloque de la transaccion
	DECLARE @resultado int
	DECLARE @returnValue SMALLINT
    BEGIN
	 IF @action = 1 -- @subaction = Permissions Show permissions aviables -- @subaction = Permissions Show Roles aviables -- @subaction = Permissions Show Users aviables
        BEGIN
        IF @subaction = ''Permissions''
            BEGIN
                SELECT Permissions_Id, 
                       KeyJson, 
                       Parent, 
                       Type, 
                       OrderGrl
                FROM ccPermissions
                ORDER BY OrderGrl, 
                         Parent
        END
        IF @subaction = ''Roles''
            BEGIN
                SELECT r.Rol_id AS RolId, 
                       r.KeyJson, 
                       r.Description,
					   r.Level,
                       CONVERT(VARCHAR(10), r.CreateDate, 103) AS CreateDate,
                       CASE
                           WHEN ur.Rol_id IS NOT NULL
                           THEN 1
                           ELSE 0
                       END AS State,
					   STUFF(
								(SELECT '', '' + CAST(ur.User_id AS varchar)
								FROM ccUsers_Roles ur
								INNER JOIN ccRoles C ON ur.Rol_id = C.Rol_id
								WHERE c.Rol_id = r.Rol_id
								FOR XML PATH ('''')),
							1,2,'''')As Users_Ids,
						STUFF(
								(SELECT '', '' + CAST(pr.Permissions_Id AS varchar)
								FROM ccRoles_Permissions pr
								INNER JOIN ccRoles C ON pr.Rol_id = C.Rol_id
								WHERE c.Rol_id = r.Rol_id
								FOR XML PATH ('''')),
							1,2,'''')As Permissions_ids
                FROM ccRoles r
                     LEFT JOIN ccUsers_Roles ur WITH(NOLOCK) ON r.Rol_id = ur.Rol_id
                                                                AND ur.User_id = @User_id
        END
        IF @subaction = ''Users''
            BEGIN
                SELECT User_id, 
                       Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno AS Names
                FROM ccUsers
                WHERE TipoUser_id = 2 AND User_id > 1
        END
    END
	END
    IF @action = 2 -- Show relationship between role and user permissions
        BEGIN
            SELECT p.Permissions_id, 
                   Parent, 
                   Type, 
                   OrderGrl
            FROM ccUsers_Roles ur
                 INNER JOIN ccRoles r WITH(NOLOCK) ON r.Rol_id = ur.Rol_id
                 INNER JOIN ccRoles_Permissions rp WITH(NOLOCK) ON rp.Rol_Id = ur.Rol_id
                 INNER JOIN ccPermissions p WITH(NOLOCK) ON p.Permissions_id = rp.Permissions_id
            WHERE ur.User_Id = @User_id
                  AND r.Active = 1
                  AND p.Active = 1
    END
    IF @action = 3 -- assign roles to user
        BEGIN
            IF OBJECT_ID(''tempdb..#Users_Ids'') IS NOT NULL DROP TABLE #Users_Ids
			IF OBJECT_ID(''tempdb..#Users_split'') IS NOT NULL DROP TABLE #Users_split
			IF OBJECT_ID(''tempdb..#Roles_split'') IS NOT NULL DROP TABLE #Roles_split
			
			SELECT value
			INTO #Users_split
			FROM fn_RIASplitDelimited(@User_id, '','')

			SELECT value
			INTO #Roles_split
			FROM fn_RIASplitDelimited(@Roles_id, '','')

			SELECT DISTINCT(User_id)
			INTO #Users_Ids
			FROM ccUsers_Roles
			WHERE User_id in (SELECT value FROM #Users_split)


            IF EXISTS( select top 1 * from #Users_Ids)
                BEGIN
                    DELETE ccUsers_Roles
                    WHERE User_id IN (select * from #Users_Ids)
				END
			IF @Roles_id <> ''''
			BEGIN
				INSERT INTO ccUsers_Roles
				select a.value User_id,b.value as Rol_id from #Users_split a
				CROSS JOIN #Roles_split b

			END
			SET @returnValue = (select top 1 * from  #Users_split)
    END
    IF @action = 4 -- Delete Roles
        BEGIN
            IF OBJECT_ID(''tempdb..#roles_permissions'') IS NOT NULL DROP TABLE #roles_permissions
			IF OBJECT_ID(''tempdb..#Users_Roles'') IS NOT NULL DROP TABLE #Users_Roles

			SELECT DISTINCT(Rol_id)
			INTO #roles_permissions
				FROM ccroles_permissions a
						INNER JOIN
				(
					SELECT value
					FROM fn_RIASplitDelimited(@Roles_id, '','')
				) b ON b.value = a.Rol_Id

			SELECT  DISTINCT(value) AS Rol_id
			INTO #Users_Roles
			FROM fn_RIASplitDelimited(@Roles_id, '','') a
					INNER JOIN ccUsers_Roles b ON b.Rol_id = a.Value
			WHERE b.Rol_id IS NOT NULL
			IF EXISTS(SELECT TOP 1 * FROM #roles_permissions)
			BEGIN
				--select * from #roles_permissions
				DELETE ccroles_permissions WHERE Rol_id in (select Rol_id from #roles_permissions )
				SET @returnValue = 1
			END
			IF EXISTS(SELECT TOP 1 * FROM #Users_Roles)
			BEGIN
				--select * from #Users_Roles
				DELETE ccUsers_Roles WHERE Rol_id in (select Rol_id from #Users_Roles )
				SET @returnValue = 1
			END
			IF EXISTS(select top 1 Rol_id from ccRoles where Rol_id in (SELECT  DISTINCT(value) FROM fn_RIASplitDelimited(@Roles_id, '','')))
			BEGIN
				--select * from ccRoles where Rol_id in (SELECT  DISTINCT(value) FROM fn_RIASplitDelimited(@Roles_id, '',''))
				DELETE ccRoles WHERE Rol_id in (SELECT  DISTINCT(value) FROM fn_RIASplitDelimited(@Roles_id, '',''))
				SET @returnValue = 1
			END
		END
    IF @action = 5 -- New Role
        BEGIN
            IF @menus_id <> ''''
               OR @Permissions_Id <> ''''
                BEGIN
                    DECLARE @exists BIT
                    SET @returnValue = 0
                    SET @exists = 1

					/*IF @menus_id <> '''' --Check if role with same menus exists
						BEGIN
							Para cuando esten los menus
						END*/

                    IF @Permissions_Id <> ''''
                       AND @exists = 1 --Check if role with same permissions exists
                        BEGIN
                            IF NOT EXISTS
                            (
                                SELECT c.Rol_Id
                                FROM ccroles_permissions a
                                     INNER JOIN
                                (
                                    SELECT value
                                    FROM fn_RIASplitDelimited(@Permissions_Id, '','')
                                ) b ON b.value = a.Permissions_Id
                                     INNER JOIN
                                (
                                    SELECT Rol_id, 
                                           COUNT(*) AS contador
                                    FROM ccRoles_Permissions
                                    GROUP BY Rol_Id
                                ) AS c ON c.Rol_id = a.Rol_id
                                     INNER JOIN
                                (
                                    SELECT COUNT(*) AS contador
                                    FROM fn_RIASplitDelimited(@Permissions_Id, '','')
                                ) d ON d.contador = c.contador
                                GROUP BY c.Rol_Id
                                HAVING COUNT(*) =
                                (
                                    SELECT COUNT(*) AS contador
                                    FROM fn_RIASplitDelimited(@Permissions_Id, '','')
                                )
                            )
                                SET @exists = 0
                    END
                    IF @exists = 0 -- IF not exist role with same menus and permissions create
                        BEGIN
                            SELECT @exists = COUNT(*)
                            FROM ccRoles
                            WHERE Description = @description
                            IF @exists = 0
                                BEGIN
                                    DECLARE @newRoleId INT
                                    INSERT INTO ccroles
                                    (Description, 
                                     KeyJson, 
                                     CreateDate, 
                                     Rowguid, 
                                     Active,
									 Level
                                    )
                                    VALUES
                                    (@description, 
                                     @keyJson, 
                                     GETDATE(), 
                                     NEWID(), 
                                     @active,
									 1001
                                    )
                                    SELECT @newRoleId = SCOPE_IDENTITY()
                                    IF @Permissions_Id <> ''''
                                        BEGIN
                                            INSERT INTO ccroles_permissions
                                                   SELECT @newRoleId, 
                                                          value
                                                   FROM fn_RIASplitDelimited(@Permissions_Id, '','') AS a
                                                        INNER JOIN ccPermissions b ON a.value = b.Permissions_Id
                                                   GROUP BY value
                                    END
                                    SET @returnValue = @newRoleId --  if new role was created return Role_id
                            END
                                ELSE
                                BEGIN
                                    SET @returnValue = -1
                            END-- else if role name exists, return -1
                    END
                    --SELECT @returnValue --  else if exists role with same menus & permissions, return 0
            END
    END
    COMMIT TRANSACTION
    -- Indica que la operación se efectuo correctamente
    SELECT @returnValue
END TRY

/* Manejo de error de la transacción */

BEGIN CATCH
	SET @returnValue = -1
    SELECT @returnValue
    ROLLBACK TRANSACTION
END CATCH'
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
