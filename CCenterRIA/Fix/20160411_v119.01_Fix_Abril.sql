/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Perez
Date: 2016/04/11
Description:

Alter SP -- ccsp_MailAdminAccount
Alter SP -- ccsp_MailInitialStatistics
Alter SP -- ccsp_MailSave
Alter SP -- ccsp_Multimedia
Alter SP -- ccsp_NetworkSocialAdminAccount
Alter SP -- ccsp_RIAConfEspec
Alter SP -- ccsp_TwitterInitialStatistics
Alter SP -- ccsp_TwitterSave
Alter SP -- ccsp_MailAdminAccount
Alter SP -- ccsp_MailAdminAccount

Database: CCenterRia
Required version: 119.01

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
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 118 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 118 sin fix
set @versionfix = 2
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and @actualVersionFix = @versionfix-1
	begin
		begin tran
		begin try



		set @process = 'Alter SP -- ccsp_MailAdminAccount'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_MailAdminAccount]
@action int,
@meanContactTypeId smallint = 1,
@contactMeanId int=0,
@name	varchar(30)=null,
@conexionInfo	varchar(255)=null,
@inboundId	int=0,
@connUser	varchar(60)=null,
@ConnPass	varchar(30)=null,
@numMessages	tinyint=null,
@timeAlertMessage	tinyint=null,
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
else if @action = 2 begin -- carga la relacion de especialidades y cuentas de email de entrada
	select A.inboundId,A.conexionInfo,A.connUser,A.connPass, A.isActive
		from ContactMeanIn A
			inner join ccInbound B on A.inboundId=B.Inbound_Id
		where meanContactTypeId = @meanContactTypeId and B.Status=1 and A.isActive=1
end
else if @action = 3 begin	--
	select name,conexionInfo,connUser,ConnPass,numMessages,timeAlertMessage,answerTimeOut from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 4 begin--insert or update relation mail whit ACD by in
	---Es necesario cambiar [ccsp_NetworkSocialAdminAccount] por que tambien se ocupa aqui
	DECLARE @tableConexionInfo TABLE(  id int, value varchar(255))
	if @connUser='''' 	set @connUser=''nuxiba@nuxiba.com''
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
	select conexionInfo,connUser,connPass
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
else if @action = 10 begin	--insert relation mail out and ACD
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
--	update ccRIACat_Areas set maxMails = @maxMails where IDArea=@idArea
--end
else if @action = 17 begin	--
	select A.conexionInfo,A.connUser,A.connPass,A.isActive from ContactMeanIn A where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
End
else if @action = 18 begin	--Carga cuentas de salida
	select A.contactMeanOutId,A.conexionInfo,A.connUser,A.connPass,isActive from contactMeanOut A where isActive=1
end
else if @action = 19 begin	 --relation MailOut and ACD
	select contactMeanOutId,inboundId from relationContactMeanOutInbound where inboundId = @inboundId or @inboundId = 0 order by inboundId
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
END'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_MailInitialStatistics'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_MailInitialStatistics]
@inboundId int=0,
@Option AS SMALLINT=0,
@User_id AS SMALLINT=0
AS
BEGIN

SET NOCOUNT ON;

if(@Option=0)
begin
	select
	count(*) received,
	count(case when messageStatusId = 1 then 1 else null end) pending,
	count(case when messageStatusId in (2,3) then 1 else null end) assigned,
	count(case when messageStatusId = 4 then 1 else null end) unassigned,
	count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
	count(case when messageStatusId = 7 then 1 else null end) rejected,
	count(case when messageStatusId = 8 then 1 else null end) programFwd,
	count(case when messageStatusId = 9 then 1 else null end) forwarding,
	count(case when messageStatusId in (10,11) then 1 else null end) closed,
	count(case when messageStatusId = 3 then 1 else null end) active,
	isnull(AVG(B.twait + B.tretention + B.tresponse),0) avgtAtention,
	isnull(AVG(B.twait),0) avgtWait,
	isnull(MAX(B.twait),0) maxtWait
	from conversation A
	inner join message B on A.conversationId=b.conversationId
	where inboundId= @inboundId
	and ( messageStatusId in (1,4) or [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121) )
end
if @Option = 1
BEGIN

	select
	count(*) received,
	count(case when messageStatusId = 1 then 1 else null end) pending,
	count(case when messageStatusId in (2,3) then 1 else null end) assigned,
	count(case when messageStatusId = 4 then 1 else null end) unassigned,
	count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
	count(case when messageStatusId = 7 then 1 else null end) rejected,
	count(case when messageStatusId = 8 then 1 else null end) programFwd,
	count(case when messageStatusId = 9 then 1 else null end) forwarding,
	count(case when messageStatusId in (10,11) then 1 else null end) closed,
	count(case when messageStatusId = 3 then 1 else null end) active ,
	isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
	isnull(AVG(msg.twait),0) avgtWait,
	isnull(MAX(msg.twait),0) maxtWait,
	InboundId inboundId
	from message msg (nolock) join conversation con (nolock) on con.conversationId=msg.conversationId
	where inboundId in (select inbound_id from ccInbound where inbound_id in (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0) and chat = 3)
	and ( messageStatusId in (1,4) or [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121) )
	GROUP BY InboundId
	END
END'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_MailSave'
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
@mailClient varchar(60)= null,
@mailACD varchar(60)= null,
@isSender bit=0,
@isUser bit = 0,
@info varchar(255)=null,
@dispositionId smallint=0,
@subDispositionId smallint=0,
@tWrapUp int =0,
@tRetention int = 0,

---Finder
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0
AS
BEGIN


declare @isEndConversation bit
declare @meanContactTypeId smallint
declare @xmlnode xml
declare @existAttached bit, @numInteracion smallint

set @meanContactTypeId = 1
SET NOCOUNT ON;

if @action = 1 begin --find uid ConversationMail
  select count(*) from messageMail where [uid]=@uid
  return (0)
end
else if @action = 2 BEGIN --new Conversation
if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin
	insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)
	select @conversationId=SCOPE_IDENTITY()
	insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,0,@date,@messageStatusId)
	select @messageId=SCOPE_IDENTITY()
	insert into [messageMail](messageId,[uid]) values (@messageId,@uid)
	select @conversationId as conversationId,@messageId as messageId,0 as lastUserId
	return (0)
end
else begin
	select 0 as conversationId,0 as messageId,0 as lastUserId
	return (0)
end
END
else if @action = 3 BEGIN --new Messages
	if @date is null set @date=getdate()
	if @mailACD is null	select @mailACD=mailInbound from conversation where conversationId=@conversationId
	if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin
		update [conversation] set info=@info where conversationId=@conversationId
		insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,@userId,@date,@messageStatusId)
		select @messageId=SCOPE_IDENTITY()
	end
else begin
	select 0 as conversationId,0 as messageId,0 as lastUserId
	return (0)
end

	if @uid is null --for outbound messages
		select @uid = dbo.md5(cast(@conversationId as varchar(10)) + ''_'' + cast(@messageId as varchar(10)))

	insert into [messageMail](messageId,[uid]) values (@messageId,@uid)

	--Finder
	select @existAttached =case when count(*)>0 then 1 else 0 end  from attached where messageId in (select messageId from message where conversationId=@conversationId)
	select @numInteracion = count(*) from message where conversationId=@conversationId
    exec ccsp_CreateNodeMail @conversationId, @xml = @xmlnode OUTPUT

	if not exists(select * from ccEmailNode where emailId=@conversationId) begin
		insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
	end
	else begin
		update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
	end
	select @conversationId as conversationId,@messageId as messageId,0 as lastUserId

END
else if @action = 4 BEGIN --new attachment
	insert into [attached](messageId,pathFile,isUser) values(@messageId,@pathFile,@isUser)
	select SCOPE_IDENTITY() as attachedId
END
else if @action = 5 BEGIN --Correos por contestar Status DOWNLOAD,Assigned,READ,UnaSSIGNED
	select A.conversationId,B.userId,A.mailClient,A.mailInbound,A.info,B.messageStatusId,max(B.messageId) as messageId
	from conversation A inner join message B on A.conversationId = B.conversationId
	where A.inboundId = @inboundId and B.messageStatusId in(1,2,3,4) and meanContactTypeId = @meanContactTypeId
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

	--Status Answered or Send Generate Node BaseX
	if @messageStatusId in(5,6)  begin
		exec ccsp_CreateNodeMail @conversationId, @xml = @xmlnode OUTPUT
			if not exists(select * from ccEmailNode where emailId=@conversationId) begin
			insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
		end
		else begin
			update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
			end
	end
	--Status Send
	if @messageStatusId=6  begin
		select @isEndConversation=isFinished from conversation where conversationId=@conversationId
		if @isEndConversation = 1 set @messageStatusId=11--Close conversation by Agent
		update [message] set tSend=getdate() where messageId=@messageId
	end
	--Answered,Send,CLose Conversation system or agent
	if @messageStatusId in (5,6,10,11)  begin
	exec ccsp_CreateNodeMail @conversationId, @xml = @xmlnode OUTPUT
		if not exists(select * from ccEmailNode where emailId=@conversationId) begin
		insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
	end
	else begin
		update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
		end
	end
	update [message] set messageStatusId=@messageStatusId where messageId=@messageId
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
	if isnull(@conversationId,0) = 0
		select pathFile,isUser from attached where messageId=@messageId and isUser=@isUser
	else
	select pathFile,isUser from attached A
	inner join message B on A.messageId=B.messageId and B.conversationId=@conversationId
	where B.conversationId=@conversationId
END
else if @action = 10 BEGIN --Correos por enviar
	select A.conversationId,max(B.messageId) as messageId,B.userId,A.inboundId,A.mailInbound
	from conversation A
	inner join message B on A.conversationId = B.conversationId
	where B.messageStatusId in(5,7,8,9) and A.meanContactTypeId = 1 and isSender=1
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
		max(E.connUser) as MailInbound, isnull(max(E.name), '''') as name
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
else if @action = 17 begin
	exec ccsp_CreateNodeMail @conversationId=@conversationId, @xml = @xmlnode OUTPUT,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate
	if not exists(select * from ccEmailNode where emailId=@conversationId) begin
		select @conversationId
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
	where inboundId=@inboundId
end
END'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_Multimedia'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_Multimedia]
@action int,@inboundId tinyint=0,@userId int =0,@meanContactTypeId tinyint = 1
AS
BEGIN

SET NOCOUNT ON;

if @action = 1 begin --Cuentas acd por tipo

	if @inboundId=0 begin
		select distinct A.inbound_id,A.chat as mode,cast(A.status as bit) [status],cast(isnull(b.isActive,0) as bit) isActive,cast(isnull(B.numMessages,3) as int) numMessages,
			case A.chat when 0 then ''call'' when 1 then ''chat'' when 2 then ''call and chat'' when 3 then ''mail'' when 4 then ''twitter'' else ''multimedia'' end  as typeMedia
			,A.IDArea
			from ccInbound A
			left join ContactMeanIn B on B.inboundId =  A.inbound_id and A.chat = case when @meanContactTypeId =1 then 3 when  @meanContactTypeId =2 then 4 else -1 end
			where isnull(A.IDArea,0)> 0 and B.meanContactTypeId=@meanContactTypeId
	end
	else begin
		select A.inbound_id,A.chat as mode,cast(A.status as bit) [status],cast(isnull(b.isActive,0) as bit) isActive,cast(isnull(B.numMessages,3) as int) numMessages,
			case A.chat when 0 then ''call'' when 1 then ''chat'' when 2 then ''call and chat'' when 3 then ''mail'' when 4 then ''twitter'' else ''multimedia'' end  as typeMedia,
			A.IDArea
			from ccInbound A
			left join ContactMeanIn B on B.inboundId =  A.inbound_id and A.chat = case when @meanContactTypeId =1 then 3 when  @meanContactTypeId =2 then 4 else -1 end
			where A.inbound_id = @inboundId and B.meanContactTypeId=@meanContactTypeId

	end
end
else if @action = 2 begin --Relacion entre agenetes y acd
	if @inboundId=0 and @userId = 0 begin --- Carga todas las relaciones
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
		order by  C.idCampEsp
	end
	else if @inboundId>0 and @userId = 0 begin
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and D.Inbound_id=@inboundId and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
		order by  C.idCampEsp
	end
	else if @inboundId=0 and @userId > 0 begin
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and B.User_id=@userId and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
		order by  C.idCampEsp
	end
end
else if @action =3 begin -- Cargar relacion de agentes
	if	@userId is null or @userId=0 begin
		select user_id,Login,isnull(maxmails,3) maxMails from ccusers us (nolock)
			left join ccriacat_areas area (nolock) on area.idarea=us.idarea where TipoUser_id=1
	end
	else begin
	select user_id,Login,isnull(maxmails,3) maxMails from ccusers us (nolock)
			left join ccriacat_areas area (nolock) on area.idarea=us.idarea
			where TipoUser_id=1 and  us.User_id=@userId
	end
end
END'
		EXEC(@sql)


		set @process = ''
		set @sql=''
		EXEC(@sql)

		set @process = ''
		set @sql=''
		EXEC(@sql)

		set @process = ''
		set @sql=''
		EXEC(@sql)

		set @process = ''
		set @sql=''
		EXEC(@sql)

		set @process = ''
		set @sql=''
		EXEC(@sql)



		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		--exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ''', version to release: ''' + cast(@version as varchar(5))
	end

set nocount off