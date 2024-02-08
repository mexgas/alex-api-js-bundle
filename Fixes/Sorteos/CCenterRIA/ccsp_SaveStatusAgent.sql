USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_SaveStatusAgent]    Script Date: 22/01/2024 06:30:07 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus float,
@TipoCall  tinyint,
@Camp smallint,
--@isTransferSurvey bit=0, --0 Callback, 1 Realiza Transferencia inmediata
@callout_id int=0,
@call_id int=0,
@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog int =0 ,
@currentStatus int =-2,--NUEVO PARÁMETRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null,
@tMusicHold int =0,
@isTransferEngine bit = 0
AS

if @Fecha4 is null set @Fecha4 = getdate()
if @TipoCall > 0 set @TipoCall = @TipoCall - 1

if (@User_id <= 0 ) begin
	return (0)
end

declare @cam_id int,@surveycamId int
declare @cal_telefono varchar(30)
declare @cal_key varchar(40)
declare @inbound_id int
declare @callBackSurveyClients bit
declare @cal_whoHung tinyint
declare @cal_tDialog int
declare @cal_tNotas int
declare @cal_tNotaOri int
declare @tMinAVRS smallint
declare @calInicio datetime
declare @sumCall int
declare @cal_manual int 

set @cal_tNotas =0
set @cal_tNotaOri=0

if @TipoStatusAge_id=32 set @tStatus=CONVERT(DECIMAL(10,2), ROUND(@tStatus, 0, 1))
--4 Dialog,6 Notas, 27 Notas Fallida
if @TipoStatusAge_id in (4,6,27) and @call_id>0 begin
if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


set @cal_manual =0

	

if @TipoCall = 0 begin --IN	
	if @isLogout=1 begin
		select @calInicio=cal_Xfer,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas, @Camp=Inbound_id, @cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas, @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
		from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13

		if @cal_tDialog = 0 and @tDialog >0  and @isLogout=1  begin
		if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
		set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
		if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
		if @TipoStatusAge_id=6  begin
			if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
			else  set @tDialog=@tDialog-1
		end
		end
		update ccCallsIN with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
	end	
end
end
else begin --OUT	
	if @isLogout=1 begin
		select @calInicio=cal_inicio,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,
		@cam_id = cam_id,@cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas from ccoCallsOut with(nolock) where cal_id = @call_id
		set @Camp=@cam_id

		if @cal_tDialog = 0 and @tDialog>0 begin
			if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
				set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
				if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
				if @TipoStatusAge_id=6  begin
					if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
					else  set @tDialog=@tDialog-1
				end
			end
			update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog, cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
		end
		else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
			update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog  where cal_id = @call_id
		else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
			update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas where cal_id = @call_id
	end
end

if @isLogout=1 begin
	select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65
	if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @cal_manual<>1 begin
		insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
	end
	if @TipoStatusAge_id in(6,27)begin
		--Valida que el agente no pudo guardar el status antes de desloguear
		if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
			INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
		end
	end
end

if (@TipoStatusAge_id=4) begin-- 4 = Dialogo

	declare @tStatus3 int, @Fecha3 datetime
	select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia with(nolock) where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
	insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
	select @User_id, cam_id, datediff(ms, dateadd(ss, -@tStatus3, @Fecha3), dateadd(ss, -@tStatus, @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
	from cccampsagente where user_id = @User_id
	---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
	if @call_id>0 begin
		if @TipoCall = 0 begin --IN			
			select @surveycamid = isnull(cam_id,0),@callBackSurveyClients = callBackSurveyClient  from ccinbound where inbound_id = @inbound_id
			if @surveycamId>0  and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
				if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0) begin
					if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100 begin
						insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
						values(right((cast(@call_id as varchar) + '' + @cal_Key),40),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()) )
					end
				end
			end
	end --@TipoCall = 0
	else begin  --OUT		
		select @surveycamId = isnull(surveycamid,0),@callBackSurveyClients= callBackSurveyClient from cccamps where cam_id = @cam_id
		select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono,@cal_whoHung=cal_whoHung
		from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
		where callout_id = @callout_id and statusCall_id = 13 and cal_id = @call_id

		if @surveycamId>0 and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
			if (select surveyPctg from ccCamps where cam_id = @surveycamId) >= rand() *100 begin
				insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
				values(right((cast(@call_id as varchar) + '' + @cal_Key),40),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()))
			end
		end
	end
	end--@isTransferSurvey = 0 and @callout_id>0
end --End -- 4 = Dialogo

if @TipoCall = 0 and @isLogout = 1  and @isTransferEngine = 1 begin --IN
	declare @minimoDialogo tinyint 
	select  @minimoDialogo = valor from ccSettings where setting_id = 13
	if @cal_tDialog < @minimoDialogo begin
		--el status 18 es para llamada cortada con transferencia en Reminder
		exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id, @nStatus = 18
	end
end 

if @TipoStatusAge_id =6  and @isLogout=0 begin
	--Valida que el ccserver no haya guardado antes el status antes al desloguear
	if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-10,@Fecha4) and @Fecha4 and tStatus = @tStatus+1)
		INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )
	end
else begin
	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )
end

if ( @TipoStatusAge_id = 2 )  begin -- 2 = No Disponible 
	INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
	VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )
	---Para Agente RIA: OAYC
	INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
	VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )
end

if @Camp > 0 begin ----Actualiza para reporte de tiempos especiales (Boan)
	if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock) where IdCampEsp = 0 and user_id = @User_id) begin
		update ccLogAgentesDia with(rowlock) set IdCampEsp = @Camp, Tipo = @TipoCall where IdCampEsp = 0 and user_id = @User_id
    end

	if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock) where IdCampEsp = 0 and user_id = @User_id) begin
		update ccLogAgentesNotReady with(rowlock) set IdCampEsp = @Camp, Tipo = @TipoCall where IdCampEsp = 0 and user_id = @User_id
    end
end

if ( @TipoStatusAge_id = 34  and @call_id > 0) begin-- Dialogo WhatsApp
    update ccWhatsAppConversations set tChatting = (tChatting + @tStatus) where conversationId = @call_id;
    select @Camp=inboundId from ccWhatsAppConversations  where conversationId = @call_id
    EXEC ccsp_WhatsAppInformation @Option = 2, @InboundId = @Camp
end
        