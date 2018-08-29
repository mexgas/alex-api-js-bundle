/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
		
Date: 
Description:

Database: CCenterRia
Required version: 

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

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 22
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 15
	begin
		begin tran
		begin try
			
ALTER TABLE ccStatusLLamada ALTER COLUMN descripcion varchar(50)
	
		set @process = 'CW-'
        set @Sql= '
	    '
        EXEC(@Sql)        
	

		set @process = 'CW-2018 CallBack Reminder alter column ccStatusLlamada'
        set @Sql= '
        ALTER TABLE ccStatusLLamada ALTER COLUMN descripcion varchar(50)
	    '
        EXEC(@Sql)        
	
		set @process = 'CW-2018 CallBack Reminder insert ccStatusLLamada 18'
        set @Sql= '
		if not exists ( select * from ccStatusLLamada where statusCall_id = 18)
		begin
		insert into ccStatusLLamada(statusCall_id,descripcion,inAbandonConfig) values(18,''Colgada en dialogo (Reminder)'',1)---esto es por lo configurado en el setting_id 13
		end
	    '

		set @process = 'CW-2018 CallBack Reminder alter  ccsp_AgentUpdateCallTimes'
	        set @Sql= '
	        ALTER procedure [dbo].[ccsp_AgentUpdateCallTimes]
		@IDCall int,
		@cal_tXfer smallint,
		@cal_tDialog smallint,
		@cal_tNotas smallint,
		@TipoCall tinyint,
		@cal_tRing smallint=0,
		@mtmoh smallint = 0,
		@isChatCall bit = 0,
		@isErroManualCall bit =0,
		@isTransferEngine bit =0
		AS
		set nocount on
		if @IDCall<=0 
		    return(0)

		declare @tMinAVRS smallint
		declare @minimoDialogo tinyint 
		select @minimoDialogo = valor from ccSettings where setting_id = 13


		if @TipoCall=1 --INBOUND
		 begin
		 if @cal_tDialog < @minimoDialogo and @isTransferEngine =1
		 begin
		 --el status 18 es para llamada cortada con transferencia en Reminder
		 exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @IDCall, @nStatus = 18
		 end
		  Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
		  cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
		  cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
		  Where cal_id= @IDCall

		  --Actualizar tiempo total de llamada
		  exec ccsp_EngineLogTransfers 2, @IDCall, @TipoCall, 2, null, @cal_tXfer, @cal_tDialog

		  -- Elimina callback generado por abandono
		  
		  if @isTransferEngine = 0
		  begin
		  Declare @ANI_x varchar(19)
		  select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

		  DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
		  DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
		  end
		 end

		if @TipoCall=2 --OUTBOUND
		 begin
		    Update ccoCallsOUT with(rowlock) Set cal_tXfer=case when @cal_tXfer > 0 then @cal_tXfer else cal_tXfer end, 
		    cal_tDialog=case when @cal_tDialog > 0 then @cal_tDialog else cal_tDialog end, 
		    @cal_tDialog=case when @cal_tDialog > 0 then @cal_tDialog else cal_tDialog end,
		    cal_tNotas=case when @cal_tNotas > 0 then @cal_tNotas else cal_tNotas end, 
		    cal_tMoh=case when @mtmoh > 0 then @mtmoh else cal_tMoh end,
		    cal_tRing=case when @cal_tRing > 0 then @cal_tRing else cal_tRing end, 
		    cal_manual=case when @isChatCall=1 then 3 else cal_manual end,
		    cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end,
		    totalCall_Time=case when totalCall_Time is null then @cal_tDialog else totalCall_Time end 
		    Where cal_id=@IDCall

		    -- calcula el costo de la llamada
		    exec ccsp_CstoCalculaCosto @IDCall

		 end

		select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

		if @cal_tDialog >= @tMinAVRS begin
		    if not exists(select * from ccAVRSTransfer where cal_id=@IDCall and tipo=@TipoCall - 1) begin
		        insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
		    end
		        return(0)
		 end

		set nocount off
	    '
        EXEC(@Sql)        
	
		set @process = 'CW-2018 CallBack Reminder alter ccsp_RIAConfEspec'
        set @Sql= '
        ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
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
case when A.cam_id > 0   and C.callsBySurvey=3 then A.callBackSurveyAgent else 0 end callBackSurveyAgent,
case when A.cam_id > 0  and C.callsBySurvey=3 then A.callBackSurveyClient else 0 end callBackSurveyClient,
case when A.cam_id > 0  and C.callsBySurvey=3 then 1 else 0 end isRelationSurvey,
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
from ccInbound A
left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
left join ContactMeanIn B on A.inbound_id=B.inboundId and B.meanContactTypeId=1
left join ccCamps C on C.cam_id=A.cam_id
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
        EXEC(@Sql)        
	
		set @process = 'CW-2018 CallBack Reminder alter ccsp_RIAUpdateCallBack_Abandon '
        set @Sql= '
ALTER procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]
@cal_id int,
@nStatus tinyint
as
set nocount on
declare @ANI varchar(13), @cam_id int, @inbound_id int, @fechadial varchar(40), @callout_id int, 
 @statuscall_id_Array varchar(1000), @minCallBackAbandon smallint, @pais varchar(2), @ld varchar(5)

declare @lenExt int

select @ANI=C.cal_ANI, @cam_id=I.cam_id, @inbound_id=I.inbound_id, 
@statuscall_id_Array=statuscall_id_Array, @minCallBackAbandon=minCallBackAbandon
from cccallsin C join ccInbound I on I.Inbound_id=C.Inbound_id where cal_id=@cal_id

select @fechadial=convert(varchar(16), dateadd(minute, @minCallBackAbandon, getdate()), 121)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @lenExt = case when valor=''''then 0 else valor end from ccSettings with(nolock) where setting_id = 108
if @nStatus not in (select value from dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','')) or isnull(@cal_id,0)=0
 return(0)
 
if isnull(@cam_id, 0)=0
	return(0)

	
set @ANI =dbo.Limpia(@ANI)
if @lenExt<>len(@ANI)
	select @ANI = dbo.completa(@ANI, @pais, @ld)


if (select substring(@ANI,1,1))= ''E''
	return(0)

if exists (select cal_ANI from ccRIAUpdateCallBack_Abandon where cal_ANI=@ANI)
	return(0)

 begin try
	insert ccRIAUpdateCallBack_Abandon (cal_id, cal_ANI, cam_id, callout_id, inbound_id, minCallBackAbandon)
	select @cal_id, @ANI, @cam_id, @callout_id, @inbound_id, @fechadial
	declare @dato1 varchar (max),  @dato2 varchar (max), @dato3 varchar (max), @dato4 varchar (max), @dato5 varchar (max)
	set @dato1 = ''''	set @dato2 = ''''	set @dato3 = ''''	set @dato4 = ''''	set @dato5 = ''''
	
	select @dato1 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 1''
	select @dato2 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 2''
	select @dato3 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 3''
	select @dato4 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 4''
	select @dato5 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 5''
	

	exec ccsp_INInsertaCallBack @cal_id, @cam_id, @ANI, @fechadial, @dato1,@dato2,@dato3,@dato4,@dato5, 1, 0, 1

	select top 1 @callout_id=callout_id from ccoWorkingTable WITH(INDEX(PK_ccoWorkingTable)) WHERE cal_telefono=@ANI
	select @fechadial=dateadd(minute, minCallBackAbandonXpire, @fechadial) from ccInbound where Inbound_id=@inbound_id
	update ccRIAUpdateCallBack_Abandon set callout_id=@callout_id, minCallBackAbandonXpire=@fechadial where cal_id=@cal_id
	return(0)
 end try

 begin catch
	return(0)
 end catch
set nocount off
	    '
        EXEC(@Sql)        
	
		set @process = 'CW-2018 CallBack Reminder alter ccsp_RIAUpdateEspecConfig '
        set @Sql= '
        ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig]
@inbound_id smallint''
@descripcion varchar(50) = null''
@Status tinyint = null''
@tNotas int = null''
@tMaxWaitCall int = null''
@nMaxQue int = null''
@tel_maxwait varchar(15) = null''
@tel_MaxQueue varchar(15) = null''
@tel_outservice varchar(15) = null''
@tel_noct varchar(15) = null''
@ShowCalifWnd bit = null''
@StartTimerOnHangUp bit = null''
@editableCallKey bit = null''
@queuePosition bit = null''
@tMaxQueueCallBack smallint = null''
@stopRecording bit = null''
@dialPrefixOverflow varchar(10) = null''
@OpriorityT smallint= null''
@callerIdDesc varchar(15) = null''
@chat tinyint = null''
@inactiveChatTime smallint = null''
@maxChats tinyint = null''
@chatDomain varchar(max) = null''
@chatQueue smallint = null''
@chatTime smallint = null''
@dRestrictPlay bit = null''
@callBackSurveyAgent bit = null''
@callBackSurveyClient bit = null''
@agts_notavailable varchar(15) = null''
@editableDtmf bit = null''
@prefijo VARCHAR(max) = null''
@addDataCallBackReminder bit = null
as
set nocount on
UPDATE ccInbound SET
descripcion = isnull(@descripcion''descripcion)''
Status = isnull(@status''status)''
tNotas = isnull(@tNotas''tNotas)''
tMaxWaitCall = isnull(@tMaxWaitCall''tMaxWaitCall)''
nMaxQue = isnull(@nMaxQue''nMaxQue)''
tel_maxwait = isnull(@tel_maxwait''tel_maxwait)''
tel_MaxQueue = isnull(@tel_MaxQueue''tel_MaxQueue)''
tel_outservice = isnull(@tel_outservice''tel_outservice)''
tel_noct = isnull(@tel_noct''tel_noct)''
bnocturno = case when isnull(@tel_noct'''0')='0' or @tel_noct='' then '0' else '1' end''
StartTimerOnHangUp = isnull(@StartTimerOnHangUp''StartTimerOnHangUp)''
editableCallKey = isnull(@editableCallKey''editableCallKey)''
queuePosition = isnull(@queuePosition''queuePosition)''
tMaxQueueCallBack = isnull(@tMaxQueueCallBack''tMaxQueueCallBack)''
stopRecording = isnull(@stopRecording'' stopRecording)''
dialPrefixOverflow = isnull(@dialPrefixOverflow'' dialPrefixOverflow)''
OpriorityT = isnull(@OpriorityT'' OpriorityT)''
callerIdDesc = isnull(@callerIdDesc''callerIdDesc)''
chat = isnull(@chat''chat)''
inactiveChatTime = isnull(@inactiveChatTime''inactiveChatTime)''
maxChats = isnull(@maxChats''maxChats)''
chatQueueOverflow = isnull(@chatQueue''isnull(chatQueueOverflow''15))''
chatTimeOverflow = isnull(@chatTime''isnull(chatTimeOverflow''300))''
startStopRecording = isnull(@dRestrictPlay''startStopRecording)''
callBackSurveyAgent = isnull(@callBackSurveyAgent''callBackSurveyAgent)''
callBackSurveyClient = isnull(@callBackSurveyClient''callBackSurveyClient)''
agts_notavailable = isnull(@agts_notavailable''agts_notavailable)''
editableDtmf = isnull(@editableDtmf''editableDtmf)''
prefijo = isnull(@prefijo''prefijo)''
addDataCallBackReminder = isnull(@addDataCallBackReminder''addDataCallBackReminder)
where inbound_id = @inbound_id


if not exists( select inbound_id from ccinbound where inbound_id <> @inbound_id and chatDomain = @chatDomain and chatDomain <> '') begin
	if @chatDomain is not null begin
		update ccinbound set chatDomain = @chatDomain where inbound_id = @inbound_id
	end
end
else begin
	update ccinbound set chatDomain = '' where inbound_id = @inbound_id
	raiserror('Domain already in another ACD Group'''15''4)
end


if @ShowCalifWnd = 1
begin
If exists(select cam_id from ccCalifCamp where cam_id = @inbound_id and tipo = 0)
	begin
	UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd''ShowCalifWnd)
	where inbound_id = @inbound_id
	select 1
	return(0)
	end

select 0
return(0)
end

else
UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd''ShowCalifWnd)
where inbound_id = @inbound_id
return(0)
set nocount off
        
	    '
        EXEC(@Sql)        
	
		set @process = 'CW-2018 CallBack Reminder alter ccsp_SaveStatusAgent'
        set @Sql= '
ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint''
@TipoStatusAge_id tinyint''
@TipoNotReady tinyint''
@tStatus float''
@TipoCall  tinyint''
@Camp smallint''
--@isTransferSurvey bit=0'' --0 Callback'' 1 Realiza Transferencia inmediata
@callout_id int=0''
@call_id int=0''
@isLogout smallint=0'' --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog int =0 ''
@currentStatus int =-2''--NUEVO PARÁMETRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null''
@tMusicHold int =0''
@isTransferEngine bit = 0
AS

if @Fecha4 is null set @Fecha4 = getdate()

if @TipoCall > 0 set @TipoCall = @TipoCall - 1

if (@User_id > 0 ) begin

	declare @cam_id int''@surveycamId int
	declare @cal_telefono varchar(30)
	declare @cal_key varchar(20)
	declare @inbound_id int
	declare @callBackSurveyClients bit
	declare @cal_whoHung tinyint
	declare @cal_tDialog int
	declare @cal_tNotas int
	declare @cal_tNotaOri int
	declare @tMinAVRS smallint
	declare @calInicio datetime
	declare @sumCall int
	set @cal_tNotas =0
	set @cal_tNotaOri=0
	--4 Dialog''6 Notas'' 27 Notas Fallida
	if @TipoStatusAge_id in (4''6''27) and @call_id>0 begin
		if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
		if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


		if @TipoCall = 0 begin --IN

			select @calInicio=cal_Xfer''@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas'' @Camp=Inbound_id'' @cal_tDialog=cal_tDialog''@cal_tNotaOri=cal_tNotas'' @cal_key = cal_Key'' @inbound_id = inbound_id'' @cal_telefono = cal_ani ''@cal_whoHung=cal_whoHung
						from ccCallsIN with(index(IX_ccCallsIn_6)''nolock) where cal_id = @call_id and statusCall_id = 13

			if @cal_tDialog = 0 and @tDialog >0  and @isLogout=1  begin
				if @Fecha4<DATEADD(ss''@sumCall+@tDialog+@cal_tNotas''@calInicio) begin
					set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
					if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
					if @TipoStatusAge_id=6  begin
						if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
						else  set @tDialog=@tDialog-1
					end
				end
				update ccCallsIN with(rowlock) set cal_tDialog=@tDialog''cal_tNotas=@cal_tNotas''cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
			end
		end
		else begin --OUT
			select @calInicio=cal_inicio''@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas''
			@cam_id = cam_id''@cal_tDialog=cal_tDialog''@cal_tNotaOri=cal_tNotas from ccoCallsOut where cal_id = @call_id
			set @Camp=@cam_id

			if @cal_tDialog = 0 and @tDialog>0 and @isLogout=1  begin
				if @Fecha4<DATEADD(ss''@sumCall+@tDialog+@cal_tNotas''@calInicio) begin
					set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
					if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
					if @TipoStatusAge_id=6  begin
						if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
						else  set @tDialog=@tDialog-1
					end
				end

				update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog'' totalCall_Time=@tDialog'' cal_tNotas=@cal_tNotas''cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
			end
			else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
				update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog'' totalCall_Time=@tDialog  where cal_id = @call_id
			else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
				update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas where cal_id = @call_id
		end

		select @tMinAVRS=isnull(valor''5) from ccSettings where setting_id=65

		if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1
		begin
			insert ccAVRSTransfer (cal_id'' tipo) values (@call_id'' @TipoCall)
		end

		if @TipoStatusAge_id in(6''27)  and @isLogout=1  begin
			--Valida que el agente no pudo guardar el status antes de desloguear
			if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss''-@tDialog-@tStatus-@cal_tNotaOri-2''@Fecha4) and @Fecha4 )
				INSERT ccLogAgentesDia ( User_id'' TipoStatusAge_id'' tStatus'' fecha'' IdCampEsp'' Tipo''currentStatus''callID ) VALUES( @User_id'' 4'' @tDialog'' DATEADD(ss''-@tStatus'' @Fecha4)'' @Camp'' @TipoCall''@TipoStatusAge_id''@call_id )
		end


	end


	if (@TipoStatusAge_id=4) begin-- 4 = Dialogo
		declare @tStatus3 int'' @Fecha3 datetime
		select top 1 @tStatus3=tstatus'' @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
		insert into ccLogAgentesDia_Dialog (User_id''Cam_id''fecha_Calc_ms''tStatus_Dispo''fecha_Dispo''tStatus_Dialog''fecha_Dialog)
		select @User_id'' cam_id'' datediff(ms'' dateadd(ss'' -@tStatus3'' @Fecha3)'' dateadd(ss'' -@tStatus'' @Fecha4))'' @tStatus3'' @Fecha3'' @tStatus'' @Fecha4
		from cccampsagente where user_id = @User_id


		---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
		if @call_id>0 begin
			if @TipoCall = 0 begin --IN

					select @surveycamid = isnull(cam_id''0)''@callBackSurveyClients = callBackSurveyClient  from ccinbound where inbound_id = @inbound_id

					if @surveycamId>0  and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
						if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey''0) > 0 and isnull(ivrScript''0) > 0)
							begin
								if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100
								begin
									insert into ccoCallsOUTSource(cal_Key''cam_id''cal_telefono''cal_status'' cal_fechaDial)
									values(right((cast(@call_id as varchar) + '''' + @cal_Key)''20)''@surveycamid''@cal_telefono''0'' dateadd(mi'' 6'' getdate()) )
								end
							end
					end
			end	--@TipoCall = 0
			else begin	--OUT



				select @surveycamId = isnull(surveycamid''0)''@callBackSurveyClients= callBackSurveyClient from cccamps where cam_id = @cam_id
				select @cal_key = cal_Key'' @cam_id = cam_id'' @cal_telefono = cal_telefono''@cal_whoHung=cal_whoHung
					from ccoCallsOUT with(index(IX_ccoCallsOut_11)''nolock)
					where callout_id = @callout_id and statusCall_id = 13 and cal_id = @call_id

				if @surveycamId>0 and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
					if (select surveyPctg from ccCamps where cam_id = @surveycamId) >= rand() *100
					begin
						insert into ccoCallsOUTSource(cal_Key''cam_id''cal_telefono''cal_status'' cal_fechaDial)
						values(right((cast(@call_id as varchar) + '''' + @cal_Key)''20)''@surveycamid''@cal_telefono''0'' dateadd(mi'' 6'' getdate()))
					end
				end
			end
		end--@isTransferSurvey = 0 and @callout_id>0


	 end

	if @TipoCall = 0 and @isLogout = 1  and @isTransferEngine = 1 begin --IN
			declare @minimoDialogo tinyint 
			select  @minimoDialogo = valor from ccSettings where setting_id = 13
			if @cal_tDialog < @minimoDialogo
				begin
				--el status 18 es para llamada cortada con transferencia en Reminder
				exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id'' @nStatus = 18
		end

	end 

	if @TipoStatusAge_id =6  and @isLogout=0
	begin
			--Valida que el ccserver no haya guardado antes el status antes al desloguear
			if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss''-10''@Fecha4) and @Fecha4 and tStatus = @tStatus+1)
				INSERT ccLogAgentesDia ( User_id'' TipoStatusAge_id'' tStatus'' fecha'' IdCampEsp'' Tipo'' currentStatus''callID)	VALUES( @User_id'' @TipoStatusAge_id'' @tStatus'' @Fecha4'' @Camp'' @TipoCall''@currentStatus''@call_id )
	end
	else
		INSERT ccLogAgentesDia ( User_id'' TipoStatusAge_id'' tStatus'' fecha'' IdCampEsp'' Tipo'' currentStatus''callID)	VALUES( @User_id'' @TipoStatusAge_id'' @tStatus'' @Fecha4'' @Camp'' @TipoCall''@currentStatus''@call_id )

	if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
	begin
		INSERT ccLogAgentesNotReady  ( User_id'' TipoNotReady_id'' tStatus'' fecha'' IdCampEsp'' Tipo )
			VALUES( @User_id'' @TipoNotReady'' @tStatus'' @Fecha4'' @Camp'' @TipoCall )

		---Para Agente RIA: OAYC
		INSERT ccRIALogAgentesNotReady  ( User_id'' TipoNotReady_id'' tStatus'' fecha )
			VALUES( @User_id'' @TipoNotReady'' @tStatus'' @Fecha4 )
	end

	-- Actualiza para reporte de tiempos especiales (Boan)
	if @Camp > 0
		begin
			if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5)''nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesDia with(rowlock)
					set IdCampEsp = @Camp'' Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end

			if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4)''nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesNotReady with(rowlock)
					set IdCampEsp = @Camp'' Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
		end
end
	    '
        EXEC(@Sql)        
				
		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
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
