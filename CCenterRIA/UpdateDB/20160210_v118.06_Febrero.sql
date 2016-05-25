/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2014/10/06
Description:


-------
-------
-------
-------
-------
-------
-------


------se agrega script de email





Database: CCenterRia
Required version: 118.05

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

set @version = 118--**********actualizar a 118 sin fix
set @versionfix = 6
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


--update  ccsettings
--set valor = '117.87.81.2'
--where setting_id = 77

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and @actualVersionFix = @versionfix -1
	begin
		begin tran
		begin try


		set @process = 'INSERT -------- ccTipoMovsListaNegra  '
		set @sql='if not exists (select * from ccTipoMovsListaNegra where idtipomov = 9) INSERT INTO ccTipoMovsListaNegra ( movimiento) VALUES (''Agregado por calificacion por ACD'')'
		EXEC(@sql)

		set @process = 'insert into ccSettings -------- '
		set @sql=' if not exists (select * from ccSettings where setting_id = 181)
		insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
	values(181,''0'',	''Mostrar mensaje de error en falla de grabación del engine'',1,''X'',	''Para desactivar la alerta en el Admin se debe poner 0 en el valor'',
	''Prompt error message when engine fails to record calls'',1,''/^[0-1]$/'') '
		EXEC(@sql)

		set @process = 'update ccTipoMovsListaNegra -------- '
		set @sql='update ccTipoMovsListaNegra set movimiento=''Agregado por calificacion por campaña'' where idtipomov=6 '
		EXEC(@sql)


		set @process = 'ALTER procedure [dbo].[ccsp_AgentUpdateCallCALIF] -------- '
		set @sql='ALTER procedure [dbo].[ccsp_AgentUpdateCallCALIF]
@IDCall int,
@calif_id smallint,
@TipoCall smallint,
@Origin int=0,
@cal_key varchar(20)=null,
@callOutId int=0,
@subId smallint=0

as
set nocount on
declare @RecicleSIC tinyint, @Reprogram tinyint, @DateNewDial smalldatetime, @idTipoLista int, @autoCB tinyint, @tel varchar(30), @camp int, @iddncList as int
declare @userid int
select @RecicleSIC=valor FROM ccSettings WHERE setting_id=60
select @RecicleSIC=IsNull(@RecicleSIC, 0)

if @TipoCall=1
 begin
	Update ccCallsIN Set calif_id=@calif_id, cal_origin_id=@Origin, cal_key=isnull(@cal_key, cal_key),
	califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall

	if exists(select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 0 and calif_id=@calif_id)
	 begin
		select @tel=dbo.Completa_ListaNegra(ci.cal_ANI), @iddncList = cbl.idTipoLista

		from ccCallsIN ci with (index (PK_ccCallsIn))
		 join cccalifblacklist as cbl on ci.calif_id=cbl.calif_id
		where ci.cal_id=@idCall and left(dbo.Completa_ListaNegra(ci.cal_ANI),1)<>''E'' and cbl.tipo=0

		if @tel is not null and @iddncList is not null begin
			--insert ccListaNegra
			insert into cclistanegra (telefono, idtipolista) values(@tel,@iddncList)

			insert ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			select dbo.Completa_ListaNegra(ci.cal_ANI), cbl.idTipoLista, ci.cal_id, getdate(), ci.dni_id, 9
			from ccCallsIN ci with (index (PK_ccCallsIn)) join cccalifblacklist cbl on ci.calif_id=cbl.calif_id
			where ci.cal_id=@idCall and left(dbo.Completa_ListaNegra(ci.cal_ANI),1)<>''E'' and cbl.tipo=0
		end
	 end

	return(0)
 end

if @TipoCall=2
 begin
 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @autoCB=autocallback from ccTipoCalifSubout where califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	if @autoCB is null
	 begin
		select @autoCB = autocallback from cctipocalifout where calif_id = @calif_id
	 end

	if @autoCB = 1
	begin
		select @callOutId=callout_id, @camp=cam_id,@userid=user_id from ccocallsout where Cal_id=@IDCall
		select @DateNewDial=dateadd(mi,t_autoCB,getdate()) from cccamps cam where cam.cam_id = @camp

		exec ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
	end

	Update ccoCallsOUT Set calif_id=@calif_id, califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall

	if exists(select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id)
	and not exists (select co.cal_telefono from ccoCallsOut co with (index (PK_ccoCallsOut))
	join ccListaNegra bl on dbo.Completa_ListaNegra(co.cal_telefono)=bl.telefono or co.cal_telefono=bl.telefono where co.cal_id=@idCall
	and bl.idtipolista in (select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id))
	 begin
		select @tel=dbo.Completa_ListaNegra(co.cal_telefono), @iddncList = cbl.idTipoLista
		from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
		where co.cal_id=@idCall and left(dbo.Completa_ListaNegra(co.cal_telefono),1)<>''E'' and cbl.tipo=1


		if @tel is not null and @iddncList is not null begin
			exec ccsp_InsertDNCList @tel, @iddncList

			insert ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			select dbo.Completa_ListaNegra(co.cal_telefono), cbl.idTipoLista, co.cam_id, getdate(), co.callout_id, 6
			from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
			where co.cal_id=@idCall and left(dbo.Completa_ListaNegra(co.cal_telefono),1)<>''E'' and cbl.tipo=1
		end
	 end

	if @RecicleSIC=1
	 begin
	 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
		select @Reprogram=CanReprogram from ccTipoCalifSubout where califSub_Id = @subId

		-- Si no tiene subcalificacion toma la de la calificacion
		if @Reprogram is null
		 begin
			select @Reprogram=CanReprogram from ccTipoCalifOUT where calif_id=@calif_id
		 end

		if @callOutId=0
			select @callOutId=callout_id from ccocallsout where Cal_id=@IDCall

		Update ccoWorkingTable Set calif_id=@calif_id,
		 cal_status=case @Reprogram when 0 then 3 else cal_status end
		Where callout_id=@callOutId

	 end
	declare @keepDial bit
	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @keepDial=keepDial from ccTipoCalifSubout where califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	if @keepDial is null
	 begin
		select @keepDial=keepDial from ccTipoCalifout where calif_id = @calif_id
	 end

	if @keepDial=1
	 begin
		update ccologdials set TipoDialingMode=dbo.fn_getDialingMode(@IDCall, 3, 0, @camp)
		where logDial_id in (select top 1 L.logDial_id from
			ccoLogDials L with(index(IX_ccoLogDials_2), nolock)
			 join ccoCallsOut O with(index(PK_ccoCallsOut), nolock)
			 on L.callout_id = O.callout_id where O.cal_id=@IDCall
			order by L.logDial_id desc)
	 end

	select @keepDial
	return(0)
 end

set nocount off '
		EXEC(@sql)


		set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIACATDialer] -------- '
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIACATDialer]
@Descripcion varchar(40)='''',
@dialer_id varchar(5)='''',
@Port int = 0, -- se cambia tipo de dato
@Status varchar(1)='''',
@Tipo varchar(2),
@carrier_id varchar(5)='''',--by odc
@xfertype smallint=0,
--Variables para insertar varios
@PortIni int = 0,
@PortEnd int = 0,
@sql as nvarchar(1000)='''',
@dialer_ids varchar(2000)=''''

AS
set nocount on
--declare @sql as nvarchar(1000)
--declare @dialer_ids nvarchar(max)


if @Tipo=0 --All Dialers
 begin
	SELECT dialer_id, Descripcion FROM ccoDialers WITH(NOLOCK)
	return(0)
 end

if @Tipo=1 --Query
 begin
	SELECT Puerto, Descripcion, Status, dialer_id, p.descrip, xt.description FROM ccoDialers d
	join cstoProvedor p on p.provedor_id=d.provedor_id
	join ccoxfertype xt on xt.xfertype_id=d.xfertype
	ORDER BY dialer_id
	return(0)
 end

if @Tipo=2 --Insert
 begin
	if @carrier_id=0
	 begin
		select top 1 @carrier_id=provedor_id from cstoProvedor
	 end

	if exists(select Descripcion from ccoDialers where (Descripcion=@Descripcion or Puerto=@Port))
	 begin
		select 1
		return(0)
	 end

	Insert ccoDialers (Descripcion, Puerto, Status, provedor_id, xfertype) Select @Descripcion, @Port, @Status, @carrier_id, @xfertype
	return(0)
 end

if @Tipo=3 --Update
 begin
	if exists(select Descripcion from ccoDialers where Descripcion=@Descripcion and dialer_id <> @Dialer_id)
	 begin
		select 1--, ''Nombre o puerto en Uso''
		return(0)
	 end

	if exists(select Puerto from ccoDialers where Puerto=@Port and dialer_id <> @Dialer_id)
	 begin
		select 1--, ''Nombre o puerto en Uso''
		return(0)
	 end

	Update ccoDialers set Descripcion=case @Descripcion when '''' then Descripcion else @Descripcion end,
	 Puerto=case @Port when '''' then Puerto else @Port end, Status=case @status when '''' then Status else @status end,
	 provedor_id=case @carrier_id when '''' then provedor_id else @carrier_id end,
	 xfertype = case @xfertype when 0 then xfertype else @xfertype end
	where Dialer_id=cast(@dialer_id as int)
	return(0)
 end

if @Tipo=4 --Delete
 begin
	if exists(select Dialer_id from ccoDialerCamp where Dialer_id=@dialer_id)
	 begin
		select 1--, ''Existe alguna campaña que esta utilizando este dialer''
		return(0)
	 end

	delete ccoDialers Where Dialer_id=@dialer_id
	return(0)
 end

if @Tipo=5 --cat. de tipo xfer
begin
	SELECT xfertype_id, description FROM ccoxfertype WITH(NOLOCK)
	return(0)
end

if @Tipo=6 --Insert more than one dialers
begin
	create table #tempPortTable( portId int primary key)
	if @carrier_id=0
		begin
			select top 1 @carrier_id=provedor_id from cstoProvedor
		end

	begin transaction
		while @portIni<=@portEnd begin
		insert into #tempPortTable values(@portIni)
		set @portIni=@portIni+1
		end
	commit transaction

	Insert ccoDialers (Descripcion, Puerto, [Status], provedor_id, xfertype)
	select @Descripcion + cast(A.portId as varchar(10)),A.portId as puerto,@Status,@carrier_id as provedor_id,@xfertype as xfertype
	from #tempPortTable A left join ccoDialers B on A.portId=B.Puerto
	where B.Puerto is null

	drop table #tempPortTable

	return(0)
end

if @Tipo=7 --Delete more than one dialers
begin
	set @sql=''
	if exists(select Dialer_id from ccoDialerCamp where Dialer_id in (''+@dialer_ids+''))
	begin
		select 1--, ''''Existe alguna campaña que esta utilizando este dialer''''
	end
	ELSE delete from ccoDialers where dialer_id in(''+@dialer_ids+'')
	''
	exec (@sql)

	return(0)
end

set nocount off
 '
		EXEC(@sql)


		set @process = 'ALTER procedure [dbo].[ccsp_RIAcalifblacklist] -------- '
		set @sql='ALTER procedure [dbo].[ccsp_RIAcalifblacklist]
@Qualif_id int = null,
@BlackListIds_Insert varchar(1500) = '''',
@BlackListIds_Delete varchar(1500) = '''',
@Type tinyint = 0,
@tipoCampACD tinyint = 1 --1 Campaña, 2 ACD
as
set nocount on
declare @sql nvarchar(max)
if @Type = 0 -- Catalogo de Calificaciones
 begin
	if @tipoCampACD=1 --Campañas
		select calif_id, Description from cctipocalifout where CalifOut_Status = 1
	else --ACDs
		select calif_id, Description from cctipocalif where Calif_Status = 1
	return(0)
 end

else if @Type = 1 -- Muestra listas negras asignadas por calificacion Campañas
 begin
	select b.idtipolista, b.Tipolista
	from cccalifblacklist a with(index(IX_cccalifblacklist)) join ccTiposListaNegra b on a.idtipolista = b.idtipolista
	where a.tipo = @tipoCampACD and a.calif_id = @Qualif_id
	group by b.idtipolista, b.Tipolista
	return(0)
 end

else if @Type = 2 -- Inserta BlackList por calificacion / Elimina BlackList por calificacion Campañas
 begin
	if LEN(@BlackListIds_Insert)>0 begin
		insert into cccalifblacklist(calif_id,idTipoLista,tipo)
		select  @Qualif_id calif_id,B.Value idTipolista, @tipoCampACD tipo from dbo.fn_RIASplitDelimited (@BlackListIds_Insert, '','') B
		left join  cccalifblacklist A on A.idTipoLista=B.value and A.tipo=@tipoCampACD and A.calif_id=@Qualif_id
		where A.idTipoLista is null
	end
	else if LEN(@BlackListIds_Delete)>0 begin
		set @sql= ''delete from cccalifblacklist where tipo ='' + cast(@tipoCampACD  as varchar(10)) + '' and idTipoLista in(''+@BlackListIds_Delete+'')''
		--print(@sql)
		exec(@sql)
	end
	return(0)
 end
set nocount off'
		EXEC(@sql)




		set @process = 'ALTER PROCEDURE [dbo].[ccsp_MailSave] -------- '
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
	update [message] set messageStatusId=@messageStatusId where messageId=@messageId
	--Status Read
	if @messageStatusId=3  update [message] set tWait=DATEDIFF(ss,tQueue, getdate()) where messageId=@messageId
	--Status Send
	if @messageStatusId=6  update [message] set tSend=getdate() where messageId=@messageId
	--Status Answered
if @messageStatusId=5  begin
	exec ccsp_CreateNodeMail @conversationId, @xml = @xmlnode OUTPUT
		if not exists(select * from ccEmailNode where emailId=@conversationId) begin
		insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
	end
	else begin
		update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
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
		select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@subDispositionId
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
--else if @action = 14 begin
-- select 1
--end
else if @action = 15 begin
	SELECT @existAttached = case when count(*)>0 then 1 else 0 end
	from attached where messageId in (select messageId from message where conversationId=@conversationId)
	select messageid,A.inboundid,a.conversationid,mailClient,date,@existAttached isAttached,C.descripcion,
	B.tSend,D.Nombres+'' ''+D.ApellidoPaterno+'' ''+D.ApellidoMaterno,E.timeAlertMessage,E.answerTimeOut,C.tNotas,
	E.connUser as MailInbound, isnull(E.name, '''') as name
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
END '
		EXEC(@sql)


		set @process = 'ALTER PROCEDURE [dbo].[ccsp_Multimedia] -------- '
		set @sql='ALTER PROCEDURE [dbo].[ccsp_Multimedia]
@action int,@inboundId tinyint=0,@userId int =0,@meanContactTypeId tinyint = 1
AS
BEGIN

SET NOCOUNT ON;


if @action = 1 begin --Cuentas acd por tipo

	if @inboundId=0 begin
		select distinct A.inbound_id,A.chat as mode,cast(A.status as bit) [status],cast(isnull(b.isActive,0) as bit) isActive,cast(isnull(B.numMessages,3) as int) numMessages,
			case A.chat when 0 then ''call'' when 1 then ''chat'' when 2 then ''call and chat'' when 3 then ''mail'' when 4 then ''twitter'' else ''multimedia'' end  as typeMedia from ccInbound A
			left join ContactMeanIn B on B.inboundId =  A.inbound_id and A.chat = case when @meanContactTypeId =1 then 3 when  @meanContactTypeId =2 then 4 else -1 end
			where isnull(A.IDArea,0)> 0 and B.meanContactTypeId=@meanContactTypeId
	end
	else begin
		select A.inbound_id,A.chat as mode,cast(A.status as bit) [status],cast(isnull(b.isActive,0) as bit) isActive,cast(isnull(B.numMessages,3) as int) numMessages,
			case A.chat when 0 then ''call'' when 1 then ''chat'' when 2 then ''call and chat'' when 3 then ''mail'' when 4 then ''twitter'' else ''multimedia'' end  as typeMedia from ccInbound A
			left join ContactMeanIn B on B.inboundId =  A.inbound_id and A.chat = case when @meanContactTypeId =1 then 3 when  @meanContactTypeId =2 then 4 else -1 end
			where A.inbound_id = @inboundId and B.meanContactTypeId=@meanContactTypeId

	end
end
else if @action = 2 begin --Relacion entre agenetes y acd
	if @inboundId=0 begin
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
		order by  C.idCampEsp
	end
	else begin
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and D.Inbound_id=@inboundId and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
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
END '
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE -------- [ccsp_BaseXmngr]'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option int = 0,
@idF int = 0,
@idL int = 0,
@idService int = 0,
@name varchar(25) = NULL,
@top varchar(max) = NULL
AS
declare @sql nvarchar(max)
declare @chat int ,@rec int,@email int
set @sql = ''''

if @action = 1 begin --obtiene los nodos a insertar en BX
	if @option = 1 begin
		set @sql = ''select top '' + @top + '' chatId, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ccChatsNode with(rowlock) where status = 0''
		exec(@sql)
	end
end
else if @action = 2 begin--actualiza los nodos insertados en BX
	if @option = 1
		update ccChatsNode with(rowlock) set [status] = 1, dateOut = getDate() where chatId between @idF and @idL and [status] = 0
	else if @option = 3
		update ccEmailNode with(rowlock) set [status] = 1, dateOut = getDate() where emailId between @idF and @idL and [status] = 0

end
else if @action = 3 begin--trae el nombre de la base de datos en BX
	select Xname from ccBaseXDB where serviceId = @option and isFull = 0
end
else if @action = 4 begin--inserta el nombre del xml en BX
	insert into ccBaseXDB (serviceId, dateStart, Xname) values (@option, getDate(), @name)
end
else if @action = 5 begin --obtener servicios disponibles
	select @chat= 0,@rec= 2,@email= 0
	select @chat = case when valor > 1 then 1 else 0 end from ccSettings where setting_id = 145
	select @email = case when valor = 1 then 3 else 0 end from ccSettings where setting_id = 155
	select id, ref 	from ccFinderServices where id in (@chat, @rec, @email)
end
else if @action = 6 begin --obtener valores con status 2
set @sql = ''select top '' + @top + '' chatId,replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ccChatsNode with(rowlock) where status = 2''
	exec(@sql)
end
else if @action = 7 begin--actualiza los nodos insertados en BX
	if @option = 1
		update ccChatsNode with(rowlock) set [status] = 3, dateOut = getDate() where chatId between @idF and @idL and [status] = 2
end

--nota: las acciones 3 y 4 hacerlas para casos dinamicos, (i.e.) si se va controlor por tamaño y asignar un xml nuevo, conusltar Daniel de CW :)'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE ccsp_INInsertaCallBack -------- '
		set @sql='ALTER PROCEDURE [dbo].[ccsp_INInsertaCallBack]
@cal_key varchar(20) =''b'',
@cam_id smallint,
@cal_telefono varchar(19),
@fechadial varchar(17),
@dato1 varchar(255),
@dato2 varchar(255),
@dato3 varchar(255),
@dato4 varchar(255),
@dato5 varchar(255),
@TelReprograma smallint = -1,
@user_id int=0,
@isAuto bit=0
AS
set nocount on
declare @TelOriginal as varchar(15)
declare @FechaOriginal as datetime

if len(@cal_telefono)<=3
	return(0)

if isnull(@cal_key,'''') = ''''
 begin
      -- Generamos cal_key aleatorio para casos de reprogramacion inbound --
      Genera_cal_key:
      select @cal_key = right(newID(), 10)
      if exists (select cal_key from ccoCallsOutSource where cal_key=@cal_key)
            goto Genera_cal_key
 end

declare @bIsDaylight as bit
declare @idioma as int
declare @country_id as varchar(3)

select @country_id = valor from ccsettings where setting_id = 104

select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

declare @difference as int
declare @Fecha smalldatetime, @callout_id int, @iZonaHoraria int,@iZonaHoraria_verano int, @cal_statusTemp tinyint
if @isAuto=0
	select @difference = isNull(dbo.fnGetTimeDifference(dbo.fnGetTimeZone(@cal_telefono,@bIsDaylight)),0)
else
	set @difference = 0
select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))

if exists(select cal_Key, cam_id from ccoCallsOutSource where cal_Key = @cal_key and cam_id =@cam_id)
 begin
	select @callout_id=callout_id,@cal_statusTemp =cal_status,@iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano, @TelOriginal = cal_telefono, @FechaOriginal = cal_fechadial from ccoCallsOutSource where cal_Key = @cal_key and cam_id = @cam_id
	update ccoCallsOutSource set cal_status = ''2'',cal_telefono=@cal_telefono where cal_key = @cal_key and cam_id = @cam_id

	if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
	else
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano)
		select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key,@iZonaHoraria,@iZonaHoraria_verano

		if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
			begin
				insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
				values (@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
			end
		else
			begin
				update ccoCallBacks
				set user_id = @user_id, cam_id = @cam_id, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @cal_telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
				where callout_id = @callout_id
			end
  end

else
 begin
	select @FechaOriginal = getdate()

	insert into ccoCallsOutSource (cal_key,cam_id,cal_telefono,cal_fechadial,Dato1,Dato2,Dato3,Dato4,Dato5,dial_tels,cal_status)
	values (@cal_key,@cam_id,@cal_telefono,@FechaOriginal,@dato1,@dato2,@dato3,@dato4,@dato5,cast(@TelReprograma as char(1))+ replace(''2345NNN'',cast(@TelReprograma as char(1)),''1''),''2'')

	select @TelOriginal = @cal_telefono

	select @callout_id = scope_identity()
	select @iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano from ccocallsoutsource where callout_id=@callout_id

	 if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
	 else
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano)
		select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key,@iZonaHoraria,@iZonaHoraria_verano

		if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
			begin
				insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
				values (@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
			end
		else
			begin
				update ccoCallBacks
				set user_id = @user_id, cam_id = @cam_id, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @cal_telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
				where callout_id = @callout_id
			end
end

if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id)
	update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id
else
	insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@cam_id

return(0)
set nocount off'
		EXEC(@sql)


		set @process = 'ALTER procedure ccsp_OUTInsertaCallBack -------- '
		set @sql='ALTER procedure [dbo].[ccsp_OUTInsertaCallBack]
@cal_id int,
@Telefono varchar(15),
@Camp smallint,
@FechaDial smalldatetime,
@callout_id int=0,
@TelReprograma smallint=-1,
@user_id int=0,
@cal_Key varchar(33)='''',
@isAuto bit=0
as
set nocount on
IF @TelReprograma<0
      return(0)

declare @Fecha smalldatetime, @sSQL nvarchar(max)
declare @iZonaHoraria int,@iZonaHoraria_verano int,@iZonaHoraria2 int, @iZonaHoraria_verano2 int,@iZonaHoraria3 int,@iZonaHoraria_verano3 int,@iZonaHoraria4 int,@iZonaHoraria_verano4 int,@iZonaHoraria5 int,@iZonaHoraria_verano5 int
declare @idZone int, @idZoneDaylight int, @list_id int
declare @bIsDaylight bit, @difference int
declare @TelOriginal varchar(15)
declare @FechaOriginal datetime
declare @pais varchar(2)
declare @ld varchar(5)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

select @callout_id = callout_id, @TelOriginal = cal_telefono, @FechaOriginal = cal_Inicio
from ccocallsout
where Cal_id=@cal_id

IF @TelReprograma=0 --Otro telefono
BEGIN
      declare @tel2 varchar(20), @tel3 varchar(20), @tel4 varchar(20), @tel5 varchar(20)
      declare @phoneCompleted varchar(20)
      declare @emptyPhoneMsg varchar(50)

      select @idZone = dbo.fnGetTimeZone(@Telefono,0)
      select @idZoneDaylight = dbo.fnGetTimeZone(@Telefono,1)
      select @phoneCompleted = dbo.Completa(@Telefono, @pais, @ld)
      select @emptyPhoneMsg = case valor when 0 then ''El teléfono no puede ser nulo o vacío'' else ''Phone number can not be null or empty'' end from ccsettings where setting_id = 27

      if charIndex(''E_NV'',@phoneCompleted) > 0
            set @phoneCompleted = @Telefono
            if @phoneCompleted = ''''
            begin
                  raiserror(@emptyPhoneMsg, 18, 1)
            end

     select @tel2=cal_telefono2,@tel3=cal_telefono3,@tel4=cal_telefono4,@tel5=cal_Telefono5,@cal_Key=cal_key
     from ccoCallsoutSource where callout_id=@callout_id

      select @TelReprograma=case when isnull(@tel4,'''')='''' then 4 when isnull(@tel3,'''')='''' then 3     when isnull(@tel2,'''')='''' then 2 else 5 end

      select @sSQL=''update ccoCallsOutSource set cal_telefono''+cast(@TelReprograma as varchar(1))+''=''''''+@phoneCompleted+''''''''
      +'',cal_status=2,dial_Tels=''''''+cast(@TelReprograma as char(1))+replace(''2345NNN'',cast(@TelReprograma as char(1)),''1'')+''''''''
      +'', iZonaHoraria''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZone as varchar(10))+'', iZonaHoraria_Verano''+cast(@TelReprograma as varchar(1))+''= ''+cast(@idZoneDaylight as varchar(10))+'' where callout_id=''+cast(@callout_id as varchar(10))
      exec(@sSQL)
END

ELSE--@>0 telefono ya existente
BEGIN
      update ccoCallsOutSource set cal_status=2,
      dial_Tels=cast(@TelReprograma as char(1))+ replace(''2345NNN'',cast(@TelReprograma as char(1)),''1'')
      where callout_id=@callout_id

      select @sSQL= N''select @outA=cal_key, @outB=izonahoraria'' +replace( cast( @TelReprograma as varchar(1)), ''1'', '''' )+'', @outC=izonahoraria_verano''+replace( cast( @TelReprograma as varchar(1)), ''1'', '''' )+'', @outD= rtrim(left(ltrim(cal_telefono + ''''        ''''
            + cal_telefono2 + ''''         ''''
            + cal_telefono3 + ''''         ''''
            + cal_telefono4 + ''''         ''''
            + cal_telefono5 + ''''         ''''),13)) from ccoCallsOutSource where callout_id = '' +cast(@callout_id as varchar)
      exec sp_executesql @sSQL, N''@outA varchar(33) OUTPUT, @outB int OUTPUT, @outC int OUTPUT, @outD varchar(19) OUTPUT'', @outA=@cal_Key OUTPUT, @outB=@idZone OUTPUT, @outC=@idZoneDaylight OUTPUT, @outD=@Telefono OUTPUT
END

-- PARA LA FECHA
declare @country_id as int
select @country_id = valor from ccsettings where setting_id = 104
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

if @isAuto=0
	select @difference = dbo.fnGetTimeDifference(case when @bIsDaylight = 0 then @idZone else @idZoneDaylight end)
else
	set @difference = 0
select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))
update ccoCallsOut set cal_fcallback=@FechaDial where cal_id=@cal_id

--PARA LAS ESTADISTICAS
if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha) and mes=month(@Fecha) and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@Camp)
      update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@Camp
else
      insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@Camp

select @iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end, @iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end,
 @iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end, @iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end,
@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end, @iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end,
@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end, @iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end,
@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end, @iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end,
@list_id=list_id
from ccocallsoutsource where callout_id=@callout_id

if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
	begin
		UPDATE ccoWorkingTable SET cal_telefono=@Telefono, cam_id=@Camp,cal_fechaDial=@Fecha,
		cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_Key,
		iZonaHoraria = @iZonaHoraria, iZonaHoraria_Verano = @iZonaHoraria_Verano,
		iZonaHoraria2 = @iZonaHoraria2, iZonaHoraria_Verano2 = @iZonaHoraria_Verano2,
		iZonaHoraria3 = @iZonaHoraria3, iZonaHoraria_Verano3 = @iZonaHoraria_Verano3,
		iZonaHoraria4 = @iZonaHoraria4, iZonaHoraria_Verano4 = @iZonaHoraria_Verano4,
		iZonaHoraria5 = @iZonaHoraria5, iZonaHoraria_Verano5 = @iZonaHoraria_Verano5
		WHERE callout_id=@callout_id
	end
else
	begin
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,
		[user_id],cal_keyw,iZonaHoraria,iZonaHoraria_verano,iZonaHoraria2,iZonaHoraria_verano2,iZonaHoraria3,
		iZonaHoraria_verano3,iZonaHoraria4,iZonaHoraria_verano4,iZonaHoraria5,iZonaHoraria_verano5,list_id)
		select @callout_id,@Telefono,@Camp,@Fecha,1,3,1,
		@user_id,@cal_Key,@iZonaHoraria,@iZonaHoraria_Verano,@iZonaHoraria2,@iZonaHoraria_Verano2,@iZonaHoraria3,
		@iZonaHoraria_Verano3,@iZonaHoraria4,@iZonaHoraria_Verano4,@iZonaHoraria5,@iZonaHoraria_Verano5,@list_id
	end

if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
	begin
		insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
		values (@callout_id,@user_id,@Camp,@cal_key,@TelOriginal,@Telefono,@FechaOriginal,@Fecha,NULL,0,1)
	end
else
	begin
		update ccoCallBacks
		set user_id = @user_id, cam_id = @Camp, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @Telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
		where callout_id = @callout_id
	end

set nocount off '
		EXEC(@sql)


		set @process = 'ALTER procedure ccsp_RIAOUTInsertNewJOBS_WT_Camp -------- '
		set @sql='ALTER procedure [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp]
@camp_id as int,
@reciclar as int = 1
as
set nocount on

create table #tempCallsOutSource(
Id int primary key identity,
callout_id int,
cam_id int,
cal_telefono varchar(19),
cal_status tinyint,
cal_fechaDial datetime,
cal_keyw varchar(20),
iZonaHoraria int,
iZonaHoraria_verano	int,
iZonaHoraria2 int,
iZonaHoraria_verano2 int,
iZonaHoraria3 int,
iZonaHoraria_verano3 int,
iZonaHoraria4 int,
iZonaHoraria_verano4 int,
iZonaHoraria5	int,
iZonaHoraria_verano5 int,
list_id	int
)


declare @prioridad varchar(8)
declare @batchsizeIni as int
declare @batchsizeFin as int
declare @rango as decimal
declare @rowstoInsert as int
set @rowstoInsert = 0
set @batchsizeIni = 0
set @batchsizeFin = 0
set @rango = 0.00

select @prioridad = isnull(Prioridad,''12345NNN'') from ccCampsPrioridadTel with(nolock) where cam_id = @camp_id

Delete ccUploadTemporal with(rowlock)
where cam_id = @camp_id

CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource]
(
	[Id] ASC

)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]


create table #calloutIdSource(
	callout_id int not null primary key
)

create table #calloutIdSource2(
	callout_id int not null primary key
)

insert into #calloutIdSource
select cs.callout_id
from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_15),nolock),
ccoWorkingTable wt with(index(IX_ccoWorkingTable_15),nolock)
where cs.cal_key = wt.cal_keyw
and cs.cam_id = wt.cam_id
and cs.cam_id = @camp_id
and cs.cal_status in(0,7)
and wt.cal_status <= 2
union
select Cout.callout_id
from ccoCallsOutSource Cout with(index(IX_ccoCallsOutSource_16),nolock),
ccoworkingtable Wtab (nolock)
WHERE Cout.callout_id = Wtab.callout_id
and Cout.cam_id = @camp_id
and (COUT.cal_status < 2 or COUT.cal_status = 7)

insert into #calloutIdSource2
	 select callout_id
	 from ccoCallsOutSource with(index(IX_ccoCallsOutSource_11),nolock)
	 WHERE cal_status in (0, 1, 7)
	 and cam_id = @camp_id

if (select count(*) from #calloutIdSource) > 0
begin
update ccoCallBacks with(rowlock)
set [status] = 6, schedulerStatus = 1
where callout_id in (select callout_id from #calloutIdSource cis with(nolock))

update ccoCallsOutSource with(rowlock)
set cal_Status = 4
where callout_id in (select callout_id from #calloutIdSource cis with(nolock))
end


insert #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2,
		iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
	SELECT callout_id, cam_id,
	rtrim(left(ltrim(cal_telefono + ''        ''
			 + cal_telefono2 + ''         ''
			 + cal_telefono3 + ''         ''
			 + cal_telefono4 + ''         ''
			 + cal_telefono5 + ''         ''),13)) as cal_telefono,
	case cal_status when 7 then 1 else cal_status end cal_status, cal_fechaDial, cal_key,
	case when len( cal_telefono ) > 0 then iZonaHoraria else null end iZonaHoraria, case when len( cal_telefono ) > 0 then iZonaHoraria_verano else null end iZonaHoraria_verano,
	case when len( cal_telefono2 ) > 0 then iZonaHoraria2 else null end iZonaHoraria2, case when len( cal_telefono2 ) > 0 then iZonaHoraria_verano2 else null end iZonaHoraria_verano2,
	case when len( cal_telefono3 ) > 0 then iZonaHoraria3 else null end iZonaHoraria3, case when len( cal_telefono3 ) > 0 then iZonaHoraria_verano3 else null end iZonaHoraria_verano3,
	case when len( cal_telefono4 ) > 0 then iZonaHoraria4 else null end iZonaHoraria4, case when len( cal_telefono4 ) > 0 then iZonaHoraria_verano4 else null end iZonaHoraria_verano4,
	case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end iZonaHoraria5, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end iZonaHoraria_verano5,
	list_id
	FROM ccoCallsOutSource with(index(IX_ccoCallsOutSource_17),nolock)
	WHERE cam_id = @camp_id and (cal_status < 2 or cal_status = 7)

   select @rowstoInsert =  COUNT(*) from #tempCallsOutSource


if (select COUNT(*) from #tempCallsOutSource with(nolock)) > 0 begin
	select @rango = isnull(CEILING(CAST((MAX(Id)*1.00)/3 as decimal (10,2))),0.00)
	 from #tempCallsOutSource with(nolock)

	set @batchsizeFin = @batchsizeFin + @rango

	while 1 = 1

	begin
		-- Nuevos Jobs

		insert into ccoWorkingTable with(tablockx)
		(callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2,
			iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)

		select callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2,
			iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
		from #tempCallsOutSource
		where id > @batchsizeIni and id <=@batchsizeFin

		if @batchsizeFin > @rowstoInsert
				break
				 else
						begin
							set @batchsizeIni =  @batchsizeIni + @rango
							set @batchsizeFin  = @batchsizeFin + @rango

						end

	  end



	UPDATE ccoCallsOutSource
		SET cal_status = 2, dial_tels = @prioridad, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
		from ccoCallsOutSource co with(nolock), #calloutIdSource2 cis3 with(nolock)
		where co.callout_id = cis3.callout_id

end

drop table #calloutIdSource
drop table #calloutIdSource2
drop table #tempCallsOutSource

set nocount off '
		EXEC(@sql)

		set @process = 'ALTER SP -------- ccsp_MailAdminAccount'
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
@answerTimeOut tinyint=null
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

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
	select A.inboundId,A.conexionInfo,A.connUser,A.connPass,A.isActive
		from ContactMeanIn A
			inner join ccInbound B on A.inboundId=B.Inbound_Id
		where meanContactTypeId = 1 and B.Status=1 and A.isActive=1
end
else if @action = 3 begin	--
	select name,conexionInfo,connUser,ConnPass,numMessages,timeAlertMessage,answerTimeOut from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 4 begin--insert or update relation mail whit ACD by in
	if @connUser='''' 	set @connUser=''nuxiba@nuxiba.com''
	if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
		if not exists(select * from ContactMeanIn where connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin
		if @name is null set @name=''''
		if @conexionInfo is null set @conexionInfo=''''
		if @connUser is null set @connUser=''''
		if @connPass is null set @connPass=''''
		if @numMessages is null set @numMessages=3
		if @timeAlertMessage is null set @timeAlertMessage=5
		if @isActive is null set @isActive=0
		if @answerTimeOut is null set @answerTimeOut=0

		insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut)
				values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut)
		select 1,''insert''
	end
		else select -1,''insert''
	end
	else begin
		if not exists(select * from ContactMeanIn where inboundId<>@inboundId and connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin
			select @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
				@numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
				@answerTimeOut= isnull(@answerTimeOut,answerTimeOut)
				from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
			update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
				numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut
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
else if @action = 18 begin	--
	select A.contactMeanOutId,A.conexionInfo,A.connUser,A.connPass from contactMeanOut A where isActive=1

end
else if @action = 19 begin	--
	select contactMeanOutId,inboundId from relationContactMeanOutInbound where inboundId = @inboundId or @inboundId = 0 order by inboundId

end
else if @action = 20 begin --relation MailOut and ACD
	select B.inboundId,A.conexionInfo,A.connUser,A.connPass
	from ContactMeanOut A join relationContactMeanOutInbound B
	on B.contactMeanOutId=A.contactMeanOutId
	where B.inboundId = @inboundId or @inboundId = 0
end
else if @action = 21 begin --relation MailOut and ACD
	update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
end
END'
		EXEC(@sql)

		set @process = 'delete old records-------- '
		set @sql='EXEC msdb.dbo.sp_delete_job @job_name=N''CW Delete old records'', @delete_unused_schedule=1
/****** Object:  Job [CW Delete old records]    Script Date: 02/02/2016 11:20:42 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/02/2016 11:20:42 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Delete old records'',
		@enabled=1,
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''No description available.'',
		@category_name=N''[Uncategorized (Local)]'',
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp]    Script Date: 02/02/2016 11:20:42 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=1,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''/***********************************************/
-- Delete Old Records New Version Febrero 2016 --
/***********************************************/
set nocount on

declare @idSqlCmd int
declare @sqlCmd nvarchar(max)
declare @days int

set @idSqlCmd = 0
set @sqlCmd  =''''''''
set @days = 30

create table #sqlCmdDeleteOldRecords(
idSqlCmd int identity primary key,
sqlCmd nvarchar(max) not null,
[status] int not null,
isReplicated bit not null
)

create table #ccoCallsOutSourceIds(
callout_id int not null primary key
)

insert into #ccoCallsOutSourceIds (callout_id)
select callout_id
from ccoCallsOutSource
where cal_fechadial < dateadd(dd, -@days, getdate())

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccBorrardasReciclaje'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccLogCampsAgentesDia'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table cclogInfo'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccUploadTemporal'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogReciclaje where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccPosicionCamps where Fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccPosicionEspecialidad where Fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAlog where operationDate < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRiaChat_log where fecha_chat < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIALogAgentesNotReady where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAWorkGroup_logDial_id where timestamp < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete xxclientehistorial where fechaAct < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccCallsIn where cal_Inicio < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete cccallsreject where cal_inicio < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesDia where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesDia_Dialog where fecha_Dialog < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesNotReady where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogLogin where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogtransfers where fechaFin < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccriachats where chatDate < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAWorkGroup_Calid where timestamp < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ivrcallsin where date < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ivroptions where date < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

/******************************************************************/
/* Delete by date because rows in ccoLogDials > ccoCallsOutSource */
/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoLogDials where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete cchistoriallistanegra from cchistoriallistanegra as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoWorkingTable from ccoWorkingTable as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccocallbacks from ccocallbacks as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoCallsOut from ccoCallsOut as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoLogDials from ccoLogDials as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoCallsOutSource from ccoCallsOutSource as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

while (select count(*) from #sqlCmdDeleteOldRecords where [status] = 0 ) > 0
	begin
		set rowcount 1
			select @idSqlCmd = idSqlCmd, @sqlCmd = SqlCmd from #sqlCmdDeleteOldRecords where [status] = 0 order by idSqlCmd
		set rowcount 0

		exec(@sqlCmd)

		WAITFOR DELAY ''''00:00:01''''

		while(SELECT count(*)
				FROM sys.dm_exec_requests a
				INNER JOIN sys.dm_exec_connections b
				ON a.session_id = b.session_id
				INNER JOIN sys.dm_exec_sessions c
				ON c.session_id = a.session_id
				CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d
				WHERE a.session_id > 50
				AND a.session_id = @@SPID
				and d.text = @sqlCmd) > 0
			begin
				WAITFOR DELAY ''''00:00:01''''
			end

		update #sqlCmdDeleteOldRecords
		set [status] = 1
		where idSqlCmd = @idSqlCmd
	end

drop table #sqlCmdDeleteOldRecords
drop table #ccoCallsOutSourceIds'',
		@database_name=N''CCenterRia'',
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Tuesday, Thursday and Saturday at 3:00 am'',
		@enabled=1,
		@freq_type=8,
		@freq_interval=84,
		@freq_subday_type=1,
		@freq_subday_interval=0,
		@freq_relative_interval=0,
		@freq_recurrence_factor=1,
		@active_start_date=20041022,
		@active_end_date=99991231,
		@active_start_time=10000,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
 '
		EXEC(@sql)


		set @process = 'Job Alter -------- DatabaseCentinella '
		set @sql='IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''DatabaseCentinella'')
EXEC msdb.dbo.sp_delete_job @job_name=N''DatabaseCentinella'', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 02/04/2016 12:39:48 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''DatabaseCentinella'',
		@enabled=1,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''Autor: Raymundo Gonzalez
				Fecha: 2014/10/15
				Descripcion:
					Centinela para monitoreo de performance y mantenimiento de las BD de SQL
				'',
		@category_name=N''[Uncategorized (Local)]'',
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseCentinellaTasks]    Script Date: 02/04/2016 12:39:49 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''DatabaseCentinellaTasks'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''use [master]

				set nocount on

				declare @idDb int
				declare @dbName nvarchar(100)
				declare @dbLog nvarchar(100)
				declare @sql nvarchar(max)
				declare @idIndex int
				declare @tableName nvarchar(100)
				declare @indexName nvarchar(100)
				declare @process int
				declare @firstSunday datetime
				declare @idCmdSql int
				declare @cmdSql nvarchar(max)
				declare @maxTimeSeconds int
				declare @maxTimeSecondsSunday int
				declare @dateExecution datetime

				set @idDb = 0
				set @dbName = ''''''''
				set @dbLog = ''''''''
				set @sql = ''''''''
				set @idIndex = 0
				set @tableName = ''''''''
				set @indexName = ''''''''
				set @process = 1
				set @firstSunday = DATEADD(WEEKDAY,(8-(DATEPART(WEEKDAY,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))))%7,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))
				set @idCmdSql = 0
				set @cmdSql = ''''''''
				set @maxTimeSeconds = 7200
				set @maxTimeSecondsSunday = 14400
				set @dateExecution = getdate()

				if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
					begin
						if exists (select * from sys.tables where name = ''''userDatabases'''')
							drop table userDatabases

						if exists (select * from sys.tables where name = ''''indexMaintenance'''')
							drop table indexMaintenance

						if exists (select * from sys.tables where name = ''''logCentinella'''')
							drop table logCentinella
					end

				if not exists (select * from sys.tables where name = ''''userDatabases'''')
					begin
						create table dbo.userDatabases(
							[idDb] int not null identity primary key,
							[dbName] nvarchar(100) not null,
							[dbLog] nvarchar(100) not null,
							[status] bit not null
						)

						CREATE NONCLUSTERED INDEX [IX_userDatabases1] ON [dbo].[userDatabases]
						(
							[dbName] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

						CREATE NONCLUSTERED INDEX [IX_userDatabases2] ON [dbo].[userDatabases]
						(
							[status] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					end

				if not exists (select * from sys.tables where name = ''''indexMaintenance'''')
					begin
						create table dbo.indexMaintenance(
							[idIndex] int not null identity primary key,
							[dbName] nvarchar(100) not null,
							[tableName] nvarchar(100) not null,
							[indexName] nvarchar(100) not null,
							[indexType] nvarchar(100) not null,
							[indexFragmentation] nvarchar(100) not null,
							[status] bit not null
						)

						CREATE NONCLUSTERED INDEX [IX_indexMaintenance1] ON [dbo].[indexMaintenance]
						(
							[dbName] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

						CREATE NONCLUSTERED INDEX [IX_indexMaintenance2] ON [dbo].[indexMaintenance]
						(
							[tableName] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

						CREATE NONCLUSTERED INDEX [IX_indexMaintenance3] ON [dbo].[indexMaintenance]
						(
							[status] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					end

				if not exists (select * from sys.tables where name = ''''logCentinella'''')
					begin
						create table dbo.logCentinella(
							[idCmdSql] int not null identity primary key,
							[date] datetime not null,
							[cmdSql] nvarchar(max) not null,
							[status] int not null,
							[dateStart] datetime not null,
							[dateEnd] datetime not null,
							[executionTimeSeconds] int not null
						)

						CREATE NONCLUSTERED INDEX [IX_logCentinella1] ON [dbo].[logCentinella]
						(
							[date] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

						CREATE NONCLUSTERED INDEX [IX_logCentinella2] ON [dbo].[logCentinella]
						(
							[status] ASC
						)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					end

				insert into userDatabases
				select db_name(database_id), '''''''', 0
				from sys.master_files
				where state = 0
				and has_dbaccess(db_name(database_id)) = 1
				and db_name(database_id) NOT IN (''''master'''', ''''tempdb'''', ''''model'''', ''''msdb'''', ''''resource'''', ''''distribution'''', ''''reportservice'''', ''''reportservicetempdb'''')
				and type = 0

				update userDatabases
				set [dbLog] = name
				from sys.master_files
				inner join userDatabases on (db_name(database_id) = [dbName] and type = 1)

				while (select count(*) from userDatabases where status = 0) > 0
					begin
						set rowcount 1
							select @idDb = idDb, @dbName = dbName from userDatabases where status = 0 order by idDb
						set rowcount 0

						select @sql = ''''use ['''' + @dbName + '''']

				insert into master.dbo.indexMaintenance
				SELECT '''''''''''' + @dbName + '''''''''''', OBJECT_NAME(ind.OBJECT_ID), ind.name, indexstats.index_type_desc, indexstats.avg_fragmentation_in_percent, 0
				FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats
				INNER JOIN sys.indexes ind ON (ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id and ind.type > 0)
				inner join sysobjects obj on (obj.id = indexstats.object_id and xtype=''''''''U'''''''' and category = 0)
				WHERE indexstats.avg_fragmentation_in_percent > 30
				ORDER BY OBJECT_NAME(ind.OBJECT_ID), ind.name''''

						exec(@sql)

						update userDatabases
						set status = 1
						where idDb = @idDb
					end

				while (select count(*) from indexMaintenance where status = 0) > 0
					begin
						set rowcount 1
							select @idIndex = idIndex, @dbName = dbName, @tableName = tableName, @indexName = indexName from indexMaintenance where status = 0 order by idIndex
						set rowcount 0

						select @sql = ''''use ['''' + @dbName + ''''] ''''

						if @process = 1
								select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REORGANIZE WITH ( LOB_COMPACTION = ON )''''
						else if @process = 2
								select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )''''
						else if @process = 3
								select @sql = @sql + ''''UPDATE STATISTICS [dbo].['''' + @tableName + ''''] WITH FULLSCAN''''

						insert into logCentinella
						select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

						if @process < 3
							update indexMaintenance set status = 1 where idIndex = @idIndex
						else
							update indexMaintenance set status = 1 where dbName = @dbName and tableName = @tableName

						if @process < 3
							begin
								if (select count(*) from indexMaintenance where status = 0) = 0
									begin
										update indexMaintenance
										set status = 0

										set @process = @process + 1
									end
							end
					end

				if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
					begin
						update userDatabases
						set status = 0

						while (select count(*) from userDatabases where status = 0) > 0
							begin
								set rowcount 1
									select @idDb = idDb, @dbName = dbName, @dbLog = dbLog from userDatabases where status = 0 order by idDb
								set rowcount 0

								select @sql = ''''use ['''' + @dbName + ''''] DBCC CHECKDB WITH NO_INFOMSGS''''

								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

								select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKDATABASE(N'''''''''''' + @dbName + '''''''''''', 10, TRUNCATEONLY)''''

								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

								select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKFILE('''''''''''' + @dbLog + '''''''''''',1)''''

								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

								select @sql = ''''use [master]

				DECLARE @currentdate datetime
				declare @date varchar(200)
				declare @rutaBak as nvarchar(2000)

				set @currentdate = CURRENT_TIMESTAMP
				select @date = '''''''''''' + @dbName + ''''_Backup_Centinella_'''''''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''''''.bak''''''''

				create table #RutaBak(
				Value nvarchar(2000) not null,
				Data nvarchar(2000) not null)

				insert into #RutaBak
				EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

				select @rutaBak = Data
				from #RutaBak

				select @rutaBak= @rutaBak + ''''''''\'''''''' + @date

				drop table #RutaBak

				BACKUP DATABASE ['''' + @dbName + ''''] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10''''

								insert into logCentinella
								select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

								update userDatabases
								set status = 1
								where idDb = @idDb
							end

						select @sql = ''''use [master]

				DECLARE @currentdate datetime
				declare @date datetime
				declare @rutaBak as nvarchar(2000)

				set @currentdate = CURRENT_TIMESTAMP
				select @date = dateadd(ww,-3,getdate())

				create table #RutaBak(
				Value nvarchar(2000) not null,
				Data nvarchar(2000) not null)

				insert into #RutaBak
				EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

				select @rutaBak = Data
				from #RutaBak

				EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''''''bak'''''''',@date

				drop table #RutaBak''''

						insert into logCentinella
						select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

					end

				set @dateExecution = getdate()

				while (select count(*) from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate()))) > 0
					begin
						set rowcount 1
							select @idCmdSql = idCmdSql, @cmdSql = cmdSql from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate())) order by idCmdSql
						set rowcount 0

						update logCentinella
						set dateStart = getdate()
						where idCmdSql = @idCmdSql

						exec(@cmdSql)

						WAITFOR DELAY ''''00:00:01''''

						while(SELECT count(*)
								FROM sys.dm_exec_requests a
								INNER JOIN sys.dm_exec_connections b
								ON a.session_id = b.session_id
								INNER JOIN sys.dm_exec_sessions c
								ON c.session_id = a.session_id
								CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d
								WHERE a.session_id > 50
								AND a.session_id = @@SPID
								and d.text = @cmdSql) > 0
							begin
								WAITFOR DELAY ''''00:00:01''''
							end

						if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
							begin
								if((datediff(ss,@dateExecution,getdate())) > @maxTimeSecondsSunday)
									BREAK
							end
						else
							begin
								if((datediff(ss,@dateExecution,getdate())) > @maxTimeSeconds)
									BREAK
							end

						update logCentinella
						set status = 1, dateEnd = getdate(), executionTimeSeconds = datediff(ss,dateStart,getdate())
						where idCmdSql = @idCmdSql
					end

				delete userDatabases
				delete indexMaintenance'',
		@database_name=N''master'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''DatabaseCentinellaSchedule'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=1,
		@freq_subday_interval=0,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20140724,
		@active_end_date=99991231,
		@active_start_time=30000,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		EXEC(@sql)


		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
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