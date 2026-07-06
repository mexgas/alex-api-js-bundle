/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
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
SET @versionfix = 25
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

	 set @process = 'CW-5749 Setting Ubicación del CallCenterSvrDotNet'
     set @sql = 'if not exists(select * from ccSettings where setting_id=20) begin
insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
values(20,''127.0.0.1'',''Ubicación del CallCenterSvrDotNet'',1,''X'',''IP o Hostname del servidor donde se encuentra el CallCenterSvrDotNet'',
''CallCenterSvrDotNet location'',0,''.*'')
end'
    EXEC(@sql)

	set @process = 'CW-5749 ccsp_ccActivityDataQuery - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ccActivityDataQuery'')
            begin
          DROP PROCEDURE ccsp_ccActivityDataQuery;
            end'
    EXEC(@sql)

    set @process = 'CW-5749 '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_ccActivityDataQuery]
@action int,@userId int=0,@camId int=0,@dnisId int=0,@WgId int=0,@tipo int =null
,@camIdOuts varchar(1000)='''',@camIdIns varchar(1000)=''''
AS
set nocount on

declare @valdiate int
declare @packageData varchar(2000)
declare @nTipoCallTotal int
set @packageData =''''
set @valdiate=0
set @nTipoCallTotal=0

if @action=1 begin	
	if exists(select * from cccamps nolock where cam_bNew=1) begin
		set @valdiate=1
		Update ccCamps SET cam_bNew=0 Where cam_bNew=2
		Update ccCamps SET cam_bNew=2 Where cam_bNew=1
	end	
	select @valdiate as isUpdate
end
else if @action=2 begin		
	if exists(select * from cccamps nolock where cam_bNew=3) begin
	set @valdiate=1
		Update ccCamps SET cam_bNew=0 Where cam_bNew=4
		Update ccCamps SET cam_bNew=4 Where cam_bNew=3
	end
	select @valdiate as isUpdate
end
else if @action=3 begin		
SELECT User_id, TipoLlamadas FROM ccUsers WHERE User_ID = @userId
end
else if @action=4 begin	
SELECT A.Login, A.User_id, prioridad, skill, A.TipoLlamadas, C.cam_id, C.cam_descripcion, C.cli_id 
FROM ccCamps C JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id 
JOIN ccUsers A  ON A.User_id = CA.User_id 
AND A.TipoUser_Id =1 AND C.cam_id =  @camId
order by A.Login, A.User_id, CA.prioridad, CA.skill, C.cam_id
end
else if @action=5 begin	
SELECT Login, TipoLlamadas, User_id, password, Nombres +'' ''+ ApellidoPaterno FROM ccUsers nolock WHERE User_id = @userId
end
else if @action=6 begin	
SELECT Inbound_id, descripcion, cli_id FROM ccInbound nolock WHERE Inbound_id =@camId
end
else if @action=7 begin	
SELECT Inbound_id, descripcion, cli_id, tnotas, nMaxQue FROM ccInbound WHERE Inbound_id = @camId
end
else if @action=8 begin	
SELECT dni_id, dni_numero, T.tipodni_id, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join ccTipoDNIS T on D.tipodni_id = T.tipodni_id 
WHERE dni_id = @dnisId and dni_tipo=2
end
else if @action=9 begin	
SELECT dni_id, dni_numero, dni_tipo, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join ccTipoDNIS T on D.tipodni_id=T.tipodni_id 
WHERE dni_id = @dnisId and dni_tipo=2
end
else if @action=10 begin	
SELECT dni_id, dni_numero, D.tipodni_id, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join cctipoDnis TD on D.tipodni_id = TD.tipodni_id
WHERE dni_tipo=2
end
else if @action=11 begin	
SELECT Inbound_id, descripcion, tNotas, nMaxQue FROM ccInbound
end
else if @action = 12 begin 
	; with WgUser AS(
	select 
	WG.IDWG,A.IdCampEsp,A.Tipo from ccRIAWorkGroupUsers WG
	inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
	inner join ccRIACampEspWG A on A.IDWG=WG.IDWG	
	where WG.IDWG<>@WgId
	)
	, wGCamp AS(
	select IDWG, IdCampEsp,Tipo from ccRIACampEspWG A
	where A.IDWG in(select IDWG from WgUser) or A.IDWG=@WgId
	), dataDiferent as
	(
	select distinct	
	convert(varchar, A.IdCampEsp)+''-''+convert(varchar,A.Tipo+1)  
	+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1)) 
	+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))
	as CampAndType
	from wGCamp A
	left join WgUser B on A.IdCampEsp=B.IdCampEsp and A.Tipo=B.Tipo	
	left join ccCampsAgente campAgent on A.IdCampEsp = campAgent.cam_id and A.Tipo=1
	left join ccInboundAgentes inboundAgent on A.IdCampEsp = inboundAgent.inbound_id and A.Tipo=0
	where B.IdCampEsp is null
	)
	select @packageData=CampAndType+'',''+@packageData from dataDiferent	
		
	select  @nTipoCallTotal = A.Tipo+1 +@nTipoCallTotal 
	from ccRIAWorkGroupUsers WG
	inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
	inner join ccRIACampEspWG A on A.IDWG=WG.IDWG	
	where WG.User_id=@userId
	group by A.Tipo 

	select @packageData as packageData, @nTipoCallTotal as nTipoCallTotal

end

else if @action = 13 begin 
	; with WgCamp As(
	select IDWG,IdCampEsp,tipo from ccRIACampEspWG A
	where tipo=@tipo and IdCampEsp=@camId and IDWG<>@WgId
	)
	, WgUserCamp as(
	select C.Login,WGUser.User_id,WgCamp.* from ccRIAWorkGroupUsers WGUser
	inner join WgCamp on WGUser.IDWG=WgCamp.IDWG 
	inner join ccUsers C on WGUser.User_id=C.User_id and C.TipoUser_id=1
	), dataDiferent as(	
	
	select distinct convert(varchar, WG.User_id)
	+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1))
	+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))	CampAndType
	from ccRIAWorkGroupUsers WG	
	inner join ccUsers C on WG.User_id=C.User_id and C.TipoUser_id=1
	left join ccCampsAgente campAgent on campAgent.cam_id =@camId 
	left join ccInboundAgentes inboundAgent on inboundAgent.inbound_id =@camId 
	where Wg.IDWG=@WgId and Wg.User_id not in(select User_id from WgUserCamp)

	)
	select @packageData=CampAndType+'',''+@packageData from dataDiferent

	select @packageData  as packageData
end
else if @action = 14 begin --Delete WG
	; with wgCam as (
	select Value as camId,1 calltype from dbo.fn_RIASplitDelimited(@camIdOuts,'','')
	union
	select Value as camId,0 calltype from dbo.fn_RIASplitDelimited(@camIdIns,'','')
	)
	, relationUser as(

	select campWg.IdCampEsp as camId,campWg.Tipo from ccRIAWorkGroupUsers WG
	inner join ccRIACampEspWG campWg on campWg.IDWG=Wg.IDWG 	
	where WG.User_id=@userId
	)
	, dataDiferent  as
	(	
	select distinct convert(varchar, wgCam.camId)+''-''+convert(varchar,wgCam.callType+1)   as CampAndType
	from wgCam
	left join relationUser A on wgCam.camId=A.camId and wgCam.calltype=A.Tipo
	where A.camId is null
	)

	select @packageData=CampAndType+'',''+@packageData from dataDiferent

	select  @nTipoCallTotal = A.Tipo+1 +@nTipoCallTotal 
	from ccRIAWorkGroupUsers WG
	inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
	inner join ccRIACampEspWG A on A.IDWG=WG.IDWG	
	where WG.User_id=@userId
	group by A.Tipo 

	select @packageData  as packageData, @nTipoCallTotal as nTipoCallTotal
end'
    EXEC(@sql)   

	set @process = 'CW-5882 InCallback ADD Inbound COLUMNS'
    set @sql = 'IF NOT EXISTS(SELECT 1 FROM sys.columns 
						  WHERE Name = N''callBackRetries''
						  AND Object_ID = Object_ID(N''dbo.ccInbound''))
				BEGIN
					alter table ccInbound add callBackRetries tinyint null, callBackCustomPhone tinyint null, callBackCustomKey bit null
				END'
	EXEC(@sql)

	set @process = 'CW-5882 InCallback ADD ccRIACallBack_Queue COLUMNS'
    set @sql = 'IF NOT EXISTS(SELECT 1 FROM sys.columns 
						  WHERE Name = N''retry''
						  AND Object_ID = Object_ID(N''dbo.ccRIACallBack_Queue''))
				BEGIN
					alter table ccRIACallBack_Queue add retry tinyint null, xferDate datetime null
				END'
	EXEC(@sql)

	set @process = 'CW-5882 InCallback ALTER SP ccsp_ccRIACallBack_Queue'
    set @sql = 'ALTER proc [dbo].[ccsp_ccRIACallBack_Queue]
		@Que_id int = null,
		@cal_id int = null,
		@CAL_ANI varchar(15) = null,
		@callout_id int = null,
		@inbound_id int = null,
		@retry tinyint = null,
		@action smallint = null,
		@xfer_date datetime = null,
		@call_key varchar(40) = null
		as
		set nocount on

		if @action = 2 and @Que_id is not null
		begin
			update ccRIACallBack_Queue set xferDate=isnull(@xfer_date,xferDate), status_queue=2 where Que_id=@Que_id
			return(0)
		end

		if @cal_id is null or @CAL_ANI is null or @inbound_id is null
		 begin
			select -1
			return(0)
		 end

		declare @retries smallint, @custom tinyint
		declare @ANI_CB varchar(13)
		declare @pais varchar(2)
		declare @ld varchar(5)

		select @retries=isnull(callBackRetries,0), @custom=isnull(callBackCustomPhone,0) from ccInbound nolock where Inbound_id=@inbound_id

		if @custom=0
		begin
			select @pais = valor from ccSettings with(nolock) where setting_id = 104
			select @ld = valor from ccSettings with(nolock) where setting_id = 17
			select @ANI_CB=dbo.completa(@CAL_ANI, @pais, @ld)
		end
		else
		begin
			select @ANI_CB=@CAL_ANI
		end

		select @retry = count(*)+1 from ccRIACallBack_Queue where cal_id = @cal_id

		insert ccRIACallBack_Queue (cal_id, CAL_ANI, callout_id, inbound_id, status_queue, datestamp, retry)
		select @cal_id, @ANI_CB, @callout_id, @inbound_id, case when @custom & 4 = 4 then 2 else case when @retry>=@retries then 1 else 0 end end, 
			GETDATE(), case when @custom & 4 = 4 then 0 else @retry end

		select @Que_id = SCOPE_IDENTITY()

		if len(@call_key) > 0
		begin
			update ccCallsIn set cal_Key=@call_key where cal_id=@cal_id
		end

		select @Que_id Que_id, @ANI_CB ANI_CB, @retry Retry, @retries Retries

		set nocount off'
    EXEC(@sql)

	set @process = 'CW-5882 InCallback ALTER SP ccsp_EngineLogTransfers'
    set @sql = 'ALTER procedure [dbo].[ccsp_EngineLogTransfers]
		@action as tinyint,
		@cal_id as integer,
		@tipo as tinyint,
		@modo as tinyint,
		@destino as varchar(50),
		@tantes integer = 0,
		@tdespues integer = 0,
		@pbxId tinyint =0,
		@channel int =0
		as
		-- tipo: 1 inbound, 2 outbound
		-- modo: 0 externa ciega, 1 agente, 2 acd, 3 confer, 4 externa supervisada, 5 desborde, 6 supervisada acd, 7 in callback
		 
		declare @totalCall_Time integer
		declare @callout_id int
		declare @xferDate datetime = getdate()
		 
		if @action = 1 begin
			if @modo = 4 begin
			   insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id) 
			   values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, @xferDate, @pbxId, @channel, dbo.fnGetTipoLlamada(@destino) )
			   if @tdespues > 0 begin
					  select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tdespues
					  update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
			   end
			end
			else begin
			   if not exists (select * from ccLogTransfers where cal_id = @cal_id and tipo = @tipo)
				  insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id) 
				  values ( @cal_id, @tipo, @modo, @destino, 0, @tantes, @xferDate, @pbxId, @channel, dbo.fnGetTipoLlamada(@destino) )
		 
			   if @tipo = 2 begin
				  if @modo = 5 begin
					  select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
					  update ccLogTransfers set tDespuesXfer = @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2), tAntesXfer = @tdespues + (select tAntesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)  where cal_id = @cal_id and tipo = 2
				  end
		         
				  if @modo in (0,1,2) begin
					  select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
					  update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
				  end
			   end
			   else begin
				  if @modo = 7 begin
					select @xferDate XferDate
					return(0)
				  end
				  if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
					  select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
					  select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
					  update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
				  end
			   end
			end
			--Valida que no existe y que el tiempo minimo de la grabacion se mayor al establecido para que lo tome el detector de gritos
			if not exists(select * from ccAVRSTransfer where cal_id=@cal_id and tipo= @tipo-1) begin
			declare @tMinAVRS smallint,@cal_tDialog int,@cal_manual int
			set @tMinAVRS=5
			set @cal_manual=0
			select @tMinAVRS=valor from ccSettings where setting_id=65
			if @tipo=2 begin
			   select @cal_tDialog=cal_tDialog,@cal_manual=cal_manual from ccoCallsOut where cal_id=@cal_id
			end
			else begin
			   select @cal_tDialog=cal_tDialog from ccCallsIn where cal_id=@cal_id
			end
		 
			if @cal_tDialog >= @tMinAVRS and @cal_manual<>1 begin
			   insert into ccAVRSTransfer (cal_id,tipo) values(@cal_id,@tipo-1)
			end
			end
		end
		 
		else if @action = 2 begin   
			if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
			   select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
			   update ccLogTransfers set tDespuesXfer = @tdespues + @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)  where cal_id = @cal_id and tipo = 2
			   select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
			   update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
			end
		end
		 
		else if @action = 4 begin
			select @totalCall_Time = ISNULL((select sum(tincall) from IVRCallsIn where callout_id = @cal_id), 0) + ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0)
			update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
		end'
	EXEC(@sql)

    set @process = 'CW-5882 InCallback ALTER SP ccsp_IVRChecaInboundHorario'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_IVRChecaInboundHorario]
		@inbound_id int
		AS
		set nocount on
		declare @fecha datetime
		declare @dia smallint
		declare @hora smallint
		declare @minuto smallint
		declare @Cuantos smallint
		declare @bnocturno smallint
		declare @tel_noct varchar(14)
		declare @tel_maxqueue varchar(14)
		declare @tel_maxwait varchar(14)
		declare @tel_outservice varchar(14)
		declare @tHoldCall int
		declare @OutOFService tinyint
		declare @Active tinyint
		declare @stopRecording bit
		declare @MohFiles varchar(8000)
		declare @ivr_script smallint, @surveycamid int
		declare @callBackCustomPhone tinyint
		declare @callBackCustomKey bit

			SET DATEFIRST 1

			select @fecha =  getdate()
			select @surveycamid = 0, @ivr_script = 0
			select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)
			if ( @dia=1 )     --LUNES
			begin
				  select @Cuantos = count(*)
				  from ccInbound I join ccInboundHorarios IH
				  on I.Inbound_id = IH.Inbound_id
				  join ccHorarios H on IH.horario_id = H.Horario_id
				  Where I.Inbound_id = @inbound_id
				  AND LUNES = 1
				  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
				  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
			end
			if @dia=2   --MARTES
			begin
				  select @Cuantos = count(*)
				  from ccInbound I join ccInboundHorarios IH
				  on I.Inbound_id = IH.Inbound_id
				  join ccHorarios H on IH.horario_id = H.Horario_id
				  Where I.Inbound_id = @inbound_id
				  AND MARTES = 1
				  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
				  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
			end
			if @dia=3   --MIERCOLES
			begin
				  select @Cuantos = count(*)
				  from ccInbound I join ccInboundHorarios IH
				  on I.Inbound_id = IH.Inbound_id
				  join ccHorarios H on IH.horario_id = H.Horario_id
				  Where I.Inbound_id = @inbound_id
				  AND MIERCOLES = 1
				  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
				  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
			end
			if @dia=4   --JUEVES
			begin
				  select @Cuantos = count(*)
				  from ccInbound I join ccInboundHorarios IH
				  on I.Inbound_id = IH.Inbound_id
				  join ccHorarios H on IH.horario_id = H.Horario_id
				  Where I.Inbound_id = @inbound_id
				  AND JUEVES = 1
				  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
				  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
			end
			if @dia=5   --VIERNES
			begin
				  select @Cuantos = count(*)
				  from ccInbound I join ccInboundHorarios IH
				  on I.Inbound_id = IH.Inbound_id
				  join ccHorarios H on IH.horario_id = H.Horario_id
				  Where I.Inbound_id = @inbound_id
				  AND VIERNES = 1
				  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
				  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
			end
			if @dia=6   --SABADO
			begin
				  select @Cuantos = count(*)
				  from ccInbound I join ccInboundHorarios IH
				  on I.Inbound_id = IH.Inbound_id
				  join ccHorarios H on IH.horario_id = H.Horario_id
				  Where I.Inbound_id = @inbound_id
				  AND SABADO = 1
				  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
				  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
			end
			if @dia=7   --DOMINGO
			begin
				  select @Cuantos = count(*)
				  from ccInbound I join ccInboundHorarios IH
				  on I.Inbound_id = IH.Inbound_id
				  join ccHorarios H on IH.horario_id = H.Horario_id
				  Where I.Inbound_id = @inbound_id
				  AND DOMINGO = 1
				  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
				  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
			end

			select @Active=0, @OutOFService=0
			select 
			@Active=case when status=1 then 1 else 0 end, --Activa
			@OutOFService=case when standby=0 then 1 else 0 end , --En operacion
			@tHoldCall = tMaxWaitCall, @bnocturno =bnocturno, @stopRecording=stopRecording, 
			@callBackCustomPhone=callBackCustomPhone, @callBackCustomKey=callBackCustomKey,
			@tel_noct=tel_noct, @tel_maxqueue=tel_maxqueue, @tel_maxwait=tel_maxwait, @tel_outservice=tel_outservice, @surveycamid = isnull(cam_id,0)
			from ccInbound nolock where Inbound_id=@inbound_id

			IF ( @OutOFService =1 AND @Active=1 and (select valor from ccsettings where setting_id = 4) = 1)
			BEGIN
		--        SI ESTA EN SERVICO
				  if @surveycamid > 0
						select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

				  --Custom MOH Files
				  SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
				  FROM ccInboundMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE Inbound_id = @Inbound_ID and TYPE = 15 ORDER BY orden
			END
			ELSE
			BEGIN
				  IF ( @OutOFService = 0 and (select valor from ccsettings where setting_id = 4) = 1)
				  BEGIN -- ESPECIALIDAD NO ACTIVA
						select @Cuantos= -1, @tHoldCall=0, @bnocturno='''', @tel_noct='''', @tel_maxqueue='''', @tel_maxwait='''', @tel_outservice='''', @MohFiles=''''
				  END
				  IF ( @Active = 0 )
				  BEGIN -- ESPECIALIDAD FUERA DE SERVICIO TEMPORAL
						select @Cuantos= -2, @tHoldCall=0, @bnocturno='''', @tel_noct='''', @tel_maxqueue='''', @tel_maxwait='''', @MohFiles=''''
				  END 
			END
			SET DATEFIRST 7

			select ''Cuantos''=@Cuantos, ''tHoldCall''=@tHoldCall, ''bNocturno''=1, ''tel_MaxWait''=@tel_maxwait, ''tel_MaxQueue''=@tel_maxqueue, ''tel_Noct''=@tel_noct, ''tel_outservice''=@tel_outservice, ''stopRecording''=@stopRecording, ''mohFiles''=isnull(@MohFiles,''''), ''ivrScript''=@ivr_script, isnull(@callBackCustomPhone,0) cbCustomPhone, isnull(@callBackCustomKey,0) cbCustomKey
		set nocount off'
    EXEC(@sql)

	set @process = 'CW-5882 InCallback ALTER SP ccsp_IVRUpdateCallEndNew'
    set @sql = 'ALTER procEDURE [dbo].[ccsp_IVRUpdateCallEndNew]
		@cal_id int,
		@cal_tIVRCallDuration smallint,
		@statuscal_id tinyint, 
		-- Aqui solo se Aceptan Edos Terminales 2(Fuera de Horario), 3(Fuera de Servicio), 4(NoAgentesFirmados), 7(TimeOut), 8(DesbordeQue),
		@cal_opciones varchar(10),
		@cal_colgada tinyint,
		@User_id smallint,
		@cal_extension varchar(7),
		@tWait smallint,
		@cbPhone varchar(20)
		AS
		set nocount on



		Update ccCallsIn SET statusCall_id = case when @statuscal_id in (2, 3, 4, 7, 8) then @statuscal_id else case when statusCall_id = 5 then 6 else statuscall_id end end, 
		 user_id= case when user_id=0 and @User_id>0 then @User_id else user_id end, cal_extension= case when cal_extension=0 and @cal_extension>0 then @cal_extension else cal_extension end, cal_tWait=@tWait where cal_id=@cal_id

 

		exec ccsp_RIAUpdateCallBack_Abandon @cal_id, @statuscal_id, @cbPhone

		--Actualizar tiempo total de llamada
		exec ccsp_EngineLogTransfers 2, @cal_id, 2, 2, null, @tWait, @cal_tIVRCallDuration

		set nocount off'
    EXEC(@sql)

	set @process = 'CW-5882 InCallback ALTER SP ccsp_RIAUpdateCallBack_Abandon'
    set @sql = 'ALTER procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]
		@cal_id int,
		@nStatus tinyint,
		@cbPhone varchar(20) = NULL
		as
		set nocount on
		declare @ANI varchar(13), @cam_id int, @inbound_id int, @fechadial varchar(40), @callout_id int, 
		 @statuscall_id_Array varchar(1000), @minCallBackAbandon smallint, @pais varchar(2), @ld varchar(5), @telFormat tinyint

		declare @lenExt int

		select @ANI=C.cal_ANI, @cam_id=I.cam_id, @inbound_id=I.inbound_id, 
		@statuscall_id_Array=statuscall_id_Array, @minCallBackAbandon=minCallBackAbandon,@telFormat = I.telFormato
		from cccallsin C join ccInbound I on I.Inbound_id=C.Inbound_id where cal_id=@cal_id

		if datalength(isnull(@cbPhone,'''')) > 0
		begin
			set @ANI=@cbPhone
		end

		select @fechadial=convert(varchar(16), dateadd(minute, @minCallBackAbandon, getdate()), 121)

		select @pais = valor from ccSettings with(nolock) where setting_id = 104
		select @ld = valor from ccSettings with(nolock) where setting_id = 17
		select @lenExt = case when valor=''''then 0 else valor end from ccSettings with(nolock) where setting_id = 108
		if @nStatus not in (select value from dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','')) or isnull(@cal_id,0)=0
		 return(0)
 
		if isnull(@cam_id, 0)=0
		  return(0)

  
		--set @ANI =dbo.Limpia(@ANI)
		--if @lenExt<>len(@ANI)
		--  select @ANI = dbo.completa(@ANI, @pais, @ld)

		  if @telFormat = 0
		  set @ANI =dbo.Limpia(@ANI)
		  else if @telFormat = 1
		  select @ANI = dbo.completa(@ANI, @pais, @ld)

		if (select substring(@ANI,1,1))= ''E''
		  return(0)

		if exists (select cal_ANI from ccRIAUpdateCallBack_Abandon where cal_ANI=@ANI)
		  return(0)

		 begin try
		  insert ccRIAUpdateCallBack_Abandon (cal_id, cal_ANI, cam_id, callout_id, inbound_id, minCallBackAbandon)
		  select @cal_id, @ANI, @cam_id, @callout_id, @inbound_id, @fechadial
		  declare @dato1 varchar (max),  @dato2 varchar (max), @dato3 varchar (max), @dato4 varchar (max), @dato5 varchar (max)
		  set @dato1 = '''' set @dato2 = '''' set @dato3 = '''' set @dato4 = '''' set @dato5 = ''''
  
		  declare @datosToAgent varchar(max)
		  select @datosToAgent= addDataCallBackReminder from ccInbound where Inbound_id = @inbound_id
  
		  if(@datosToAgent = 1)
		  begin
			select @dato1 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 1''
			select @dato2 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 2''
			select @dato3 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 3''
			select @dato4 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 4''
			select @dato5 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 5''
		  end 
		  exec ccsp_INInsertaCallBack @cal_id, @cam_id, @ANI, @fechadial, @dato1,@dato2,@dato3,@dato4,@dato5, 1, 0, 1

		  select top 1 @callout_id=callout_id from ccoWorkingTable WITH(INDEX(PK_ccoWorkingTable)) WHERE cal_telefono=@ANI
		  select @fechadial=dateadd(minute, minCallBackAbandonXpire, @fechadial) from ccInbound where Inbound_id=@inbound_id
		  update ccRIAUpdateCallBack_Abandon set callout_id=@callout_id, minCallBackAbandonXpire=@fechadial where cal_id=@cal_id
		  return(0)
		 end try

		 begin catch
		  return(0)
		 end catch
		set nocount off'
    EXEC(@sql)

	set @process = 'CW-5944 Admin desconocido'
    set @sql = '
		if not exists(select * from ccTipoStatusAgente nolock where TipoStatusAge_id=33)
		begin
			insert ccTipoStatusAgente values (33, ''Assisted'')
			update ccLogAgentesDia set TipoStatusAge_id=33 where TipoStatusAge_id=28
			delete ccTipoStatusAgente where TipoStatusAge_id=28
		end'
	EXEC(@sql)

	set @process = 'CW-5897 Alter sp ccsp_GalateaChangeHistory'
    set @sql = '
	ALTER PROCEDURE [dbo].[ccsp_GalateaChangeHistory]
	@option TINYINT,
	@loginLst VARCHAR(max) = NULL,
	@moduleWithOperation varchar(max) = NULL,
	@operationDateIni SMALLDATETIME = NULL,
	@operationDateFin SMALLDATETIME = NULL,
	@top INT = 0
	AS
	SET NOCOUNT ON

	DECLARE @lang TINYINT

	SELECT @lang = valor
	FROM ccsettings
	WHERE setting_id = 27

	IF @option = 1 -- Catalogo de modulos
	BEGIN
		WITH Catalog AS(
		SELECT cast(m.module_id as int) module_id, cast(o.operationType as int) operationType, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion) + 1, len(m.descripcion)) END AS mDescripcion, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion) + 1, len(o.descripcion)) END AS oDescripcion
		FROM ccRIALog_Operation o WITH (INDEX (IX_ccRIALog_Operation))
		JOIN ccRIALog_Cat_Relation r ON o.operationType = r.operationType
		JOIN ccRIALog_Module m WITH (INDEX (IX_ccRIALog_Module)) ON r.module_id = m.module_id

		UNION

		SELECT 0, - 1, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, '' - ''

		UNION

		SELECT 0, 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END

		UNION

		SELECT cast(module_id as int) module_id, 0, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
		FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))

		UNION

		SELECT cast(module_id as int) module_id, - 1 , CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, '' - ''
		FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module)))

		SELECT module_id,operationType,mDescripcion,oDescripcion FROM Catalog
		WHERE module_id not in(5,8,14,21,22,25,32,33,36,37,44,53,57,58,59,60,42)
		AND operationType not in(6,15,51,58,36,46,44,45,59,12,8,7,55,54,33)
		ORDER BY mDescripcion, oDescripcion

		RETURN (0)
	END

	IF @option = 2 -- Muestra informacion por filtros
	BEGIN

		declare @sql as nvarchar(max)
		DECLARE @table TABLE(id int,value varchar(max))
		declare @id int
		declare @moduleId varchar(max)
		declare @operationLst varchar(max)
		declare @query varchar(max) = '' and (''
		declare @value varchar(max)
		declare @first int = 1
		declare @pos int

		insert into @table select * from dbo.fn_RIASplitDelimited(cast(isnull(@moduleWithOperation,'''') as varchar(max)), '','')
		while exists(select * from @table)
		begin
			select top 1 @id = id, @value = value from @table
			set @pos = charindex('':'', @value)
			if(@pos <> 0)
			begin
				set @moduleId = substring(@value, 1, @pos-1)
				set @operationLst = replace(substring(@value, @pos+1, len(@value)), ''-'', '','')
				if(@first = 1)
				begin
					set @query = @query + ''l.module_id='' + @moduleId + '' and l.operationType in ('' + @operationLst + '')''
					set @first = 0
				end
				else
				begin
					set @query = @query + '' or l.module_id='' + @moduleId + '' and l.operationType in ('' + @operationLst + '')''
				end
			end

			delete @table where id = @id
		end
		set @query = @query + '')''


		SET ROWCOUNT @top

		set @sql =
		''DECLARE @tableLogin TABLE(id int,value varchar(255))
		insert into @tableLogin  select * from dbo.fn_RIASplitDelimited('''''' + cast(isnull(@loginLst,'''') as varchar(max)) + '''''','''','''')

		SELECT L.log_id, L.areaName, L.operationDate,
		CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''''|'''', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''''|'''', o.descripcion) + 1, len(o.descripcion)) END operationType,
		L.LOGIN,
		CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''''|'''', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''''|'''', m.descripcion) + 1, len(m.descripcion)) END module_id,
		CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target,
		CASE WHEN v.valueT IS NULL THEN L.value ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN v.es WHEN 2 THEN v.pt ELSE v.en END END AS value
		FROM CCRIALOG L
		JOIN ccRIALog_Module M WITH (INDEX (IX_ccRIALog_Module)) ON L.module_id = M.module_id
		JOIN ccRIALog_Operation O WITH (INDEX (IX_ccRIALog_Operation)) ON L.operationType = O.operationType
		LEFT JOIN targetRecord t ON t.targetT = L.target
		LEFT JOIN valueRecord v ON v.valueT = L.value
		LEFT JOIN ccUsers CU ON CU.Login = L.login
		WHERE 1=1 
		AND
		CU.TipoUser_id = 2''
		+
		case isnull(@loginLst, '''') when '''' then '''' else
		'' AND L.LOGIN in (select value from @tableLogin) ''
		END
		+
		case isnull(@moduleWithOperation, '''') when '''' then '''' else
		@query
		end
		+ case ISNULL(@operationDateIni, '''') when '''' then '''' else
		''AND L.operationDate >= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull('''''' + convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, -1, '''''' + convert(varchar(19), @operationDateIni, 121) + '''''') ELSE L.operationDate END ''
		+ '' AND L.operationDate <= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull(''''''+ convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, 1, '''''' + convert(varchar(19), @operationDateFin, 121) + '''''') ELSE L.operationDate END''
		end
		+
		'' ORDER BY L.operationDate DESC''
		execute sp_executesql @sql
		--print @sql
	END


	SET NOCOUNT OFF
		'
	EXEC(@sql)

	set @process = 'CW-5951 Cambios de estado Dialogo WhatsApp'
    set @sql = '
		if not exists(select * from ccTipoStatusAgente nolock where TipoStatusAge_id=34)
		begin
			insert ccTipoStatusAgente values (34, ''Dialogo WhatsApp'')
		end'
	EXEC(@sql)

	set @process = 'No disponibles - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUnavailableStates'')
            begin
          DROP PROCEDURE ccsp_GalateaUnavailableStates;
            end'
    EXEC(@sql)

    set @process = 'No disponibles - Se crea sp'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaUnavailableStates]
@NotReady_id smallint = null,
@Description varchar(30)='''',
@Acc_Time int = null,
@Intervals int = null,
@Pass_Supv tinyint = null,
@NextStatus int = null,
@Frame smallint = null,
@Type varchar(1)='''',
@IsSupv int = null,
@NotReady_ids varchar(max)=''''
AS
set nocount on
DECLARE @sql nvarchar(4000), @graph nvarchar(1000), @id smallint, @newGraph smallint

	if @Type = 1 -- LOAD
		begin
			SELECT distinct a1.TipoNotReady_id as NotReady_Id, a1.Descripcion as Description, a1.Time_Acum as Acc_Time, a1.Time_xEv as Intervals, 
			cast(a1.Pas_Sup as bit) Pass_Supv, a1.NextStatus, frame as Frame, cast(a1.IsSup as bit) IsSupv
			FROM ccTipoNotReady a1 
			inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
			where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id between 0 and 250
			order by 2
		end

	If @Type=2 -- INSERT
	 begin
		if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Description)
		 begin		
			select -1
			return(0)
		 end
		if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=0 and Descripcion=@Description)
			begin		
				select @id=TipoNotReady_id from ccTipoNotReady where Descripcion=@Description
				update ccTipoNotReady set 
				Time_acum=@Acc_Time,
				Time_xEv=@Intervals,
				Pas_Sup=@Pass_Supv,
				NextStatus=@NextStatus,
				IsSup=@IsSupv,
				StatusTipoNotReady=1
				where Descripcion=@Description
				If not exists(select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
					Begin
						insert into ccRIAGraphics (frame, type_id) select @Frame,4
					End
			
				insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
				select cast(@id as int)
				return(0)		
			end
		If not exists(select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
		 Begin
			insert into ccRIAGraphics (frame, type_id) select @Frame,4
		 End

		insert ccTipoNotReady (Descripcion, Time_Acum, Time_xEv, Pas_Sup, NextStatus, IsSup, StatusTipoNotReady) 
		select @Description, @Acc_Time, @Intervals, @Pass_Supv, @NextStatus, @IsSupv,1
		select @id=SCOPE_IDENTITY()
		insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
		select cast(@id as int)
	 end

	If @Type=3 -- DELETE
	 begin
		 declare @NDs_Ids table (id int primary key not null)

		if @NotReady_id is null
		 begin
			insert into @NDs_Ids
			select value from dbo.fn_RIASplitDelimited (@NotReady_ids, '','')
		 end
		else
		 begin
			insert into @NDs_Ids
			select @NotReady_id
		 end

		exec ccsp_AdminNotready 3,0,@NotReady_id,0, @NotReady_ids
		delete ccRIANotReadyGraph where tipoNotReady_id in (select id from @NDs_Ids)
		update ccTipoNotReady set StatusTipoNotReady=0 where tipoNotReady_id in (select id from @NDs_Ids)
		update ccTipoNotReady set NextStatus=-1 where NextStatus in (select id from @NDs_Ids)
	
		select cast(id as smallint) NotReady_Id, 0 as Related from @NDs_Ids
	 end

	if(@Type=4) --UPDATE
	 begin

		if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Description and TipoNotReady_id not in (@NotReady_id))
		 begin		
			select -1
			return(0)
		 end

		update ccTipoNotReady set 
		 Descripcion=case @Description when '''' then Descripcion else @Description end,
		 Time_Acum=ISNULL(@Acc_Time,Time_Acum),
		 Time_xEv=ISNULL(@Intervals,Time_xEv),
		 Pas_Sup=ISNULL(@Pass_Supv,Pas_Sup), 
		 NextStatus=ISNULL(@NextStatus,NextStatus), 
		 IsSup=ISNULL(@IsSupv,IsSup)
		where TipoNotReady_id=@NotReady_id

		IF ISNULL(@Frame,'''') not in('''')
		 BEGIN
			If not exists (select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
			 begin
				insert into ccRIAGraphics (frame, type_id) select @Frame,4
			 end

			select @graph = graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
			update ccRIANotReadyGraph set graphic_id=cast(@graph as smallint) where TipoNotReady_id=cast(@NotReady_id as tinyint)
		 END
		 select 1
	 end

	if @Type = 5
	 begin
		select cast(NextStatus as smallint) NotReady_Id, cast(TipoNotReady_id as int) Related
		from ccTipoNotReady 
		where StatusTipoNotReady=1 and NextStatus in (select value from dbo.fn_RIASplitDelimited (@NotReady_ids, '',''))
	 end

set nocount off'
    EXEC(@sql)

    set @process = 'CW-5351 - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAADMGetCalifDayForced'')
            begin
          DROP PROCEDURE ccsp_RIAADMGetCalifDayForced;
            end'
    EXEC(@sql)

    set @process = 'CW-5351 - Se agrega sp'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAADMGetCalifDayForced]
		@type smallint,
		@cam_id smallint,
		@calif_id smallint = null
		AS 
		set nocount on
		create table #CalifTemp (id int identity,
		tipo integer, 
		Cam_id varchar(50), 
		Calificacion varchar(50), 
		subCalificacion varchar(50) null,
		calif_id smallint null,
		Total int,
		GraphColor varchar(15)) 

		declare @today datetime
		set @today = convert(datetime, convert (varchar(11), getdate(), 101))
		--set @today =convert(datetime, convert (varchar(11), ''2015-10-01 17:50:20.470'', 101))

		-- Seleccion de idioma -- 
		declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
		select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
		from ccsettings where setting_id = 27 -- 0esp

		select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
		from ccsettings where setting_id = 27 -- 0 esp

		if @type=0 
		insert into #CalifTemp 
		select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13
				then case when description is not null 
							then description 
							else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
							end
		else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
		end end as Calificacion,
		case when count(co.califSub_id) > 0 then 1 else 0 end as Subcalificacion,co.calif_id as calif_id,count(*) cantidad,
		ISNULL(GraphColor,''1DB4E2'') GraphColor
		from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
		left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
		left join ccTipoCalifSubOUT tcsout on co.califSub_id = tcsout.califSub_id
		left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
		left join ccCamps ci on ci.cam_id = co.cam_id 
		where co.cal_inicio > @today
		and co.cam_id = @cam_id
		group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id,GraphColor



		if @type=1 
		insert into #CalifTemp 
		select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
		else @nIdioma-- substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
		end as Calificacion,count(ci.califSub_id) as subCalificacion,ci.calif_id,count(*)  as total,
		ISNULL(GraphColor,''1DB4E2'') GraphColor
		from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) 
		left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
		left join ccInbound cci on cci.inbound_id = ci.inbound_id 
		where ci.cal_inicio > @today
		and ci.inbound_id = @cam_id
		and statuscall_id = 13 
		group by description, cci.inbound_id,ci.califSub_id,ci.calif_id,GraphColor



		-- Se corrigio suma de totales -- 
		Alter table #CalifTemp add iTotal4Campaign int null

		if (select valor from ccSettings where setting_id = 78) = 0
		update #CalifTemp set iTotal4Campaign = 0

		else	
		update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
		from (select cam_id, sum(A.Total) iTotal4Campaign
		from #CalifTemp A group by cam_id) t join #CalifTemp c
		on t.cam_id = c.cam_id

		if @type=1 
		select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total, GraphColor from (
			select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
			 else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
			 end as Calificacion,0 as subCalificacion ,0 as calif_id,count(disposition) as Total,ISNULL(GraphColor,''1DB4E2'') GraphColor--,0 as iTotal4Campaign
			from ccriachats a left join ccTipoCalif b 
			on a.disposition=b.calif_id 
			where a.chatDate > @today
			and a.inboundId = @cam_id
			group by inboundId, Description, GraphColor
			
			union all
			
			
			select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
			then calificacion 
			else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
			end as Calificacion,
			case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor  --iTotal4Campaign -- para ver total por campaña
			from #CalifTemp 
			group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
			then calificacion 
			else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
			end, Cam_id,calif_id, iTotal4Campaign, GraphColor
		)  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id,GraphColor order by tipo,cam_id 
		if @type=0 

		select tipo as Type,Cam_id as CampId,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
		then calificacion 
		else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
		end as Calification,subCalificacion as SubCalificationQuantity, calif_id as CalificationId,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor -- , iTotal4Campaign -- para ver total por campaña
		from #CalifTemp 
		group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
		then calificacion 
		else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
		end, Cam_id,subCalificacion, calif_id, iTotal4Campaign, GraphColor



		if @type = 3 begin -----entrada acd''s
			select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
			else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
			end as Calificacion,isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(*) as totales 
			from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
			left join ccInbound cci on cci.inbound_id = ci.inbound_id 
			left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
			where ci.cal_inicio > @today
			and ci.inbound_id = @cam_id
			and statuscall_id = 13 
			and ci.calif_id = @calif_id
			group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id 
		end

		if @type = 4 begin --salida campañas
				select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
					then case when description is not null 
								then description 
								else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
								end
			else case when sll.descripcion is not null 
			then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
			end end as Calificacion,isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad 
			from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
			left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
			left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
			left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
			left join ccCamps ci on ci.cam_id = co.cam_id 
			where co.cal_inicio > @today
			and co.cam_id = @cam_id
			group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
		end 
		 

		drop table #CalifTemp 
		set nocount off'
    EXEC(@sql)

    set @process = 'No disponibles - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_AdminNotready'')
            begin
          DROP PROCEDURE ccsp_AdminNotready;
            end'
    EXEC(@sql)

    set @process = 'No disponibles - se actualiza sp'
    set @sql = 'Create procedure [dbo].[ccsp_AdminNotready]
@Type tinyint,	-- 1:ND x Supervisor/2:actualiza x supervisor/3:Actualiza todo/4:trae ND/5:Trae supervisores
@User_id smallint = null,
@id_ND smallint = null,
@valor bit=1,
@id_NDs varchar(max) = ''''
as
set nocount on

declare @sql as nvarchar(2000)
declare @dato1 as varchar (100)

if @Type not in (1,2,3,4,5)
	raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)

if @Type = 1
 begin

 	if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@User_id)
	 begin
		raiserror(''ERROR. invalid user id'', 18, 1)
		return(0)
	 end

select @dato1 = valor from (select case when valor= 3 then ''nd.issup =1'' when valor = 2 then ''nd.issup = nd.issup and nd.tiponotready_id > 0'' when valor = 4 
	then ''nd.issup = nd.issup and nd.tiponotready_id > 0'' else (select ''nd.tiponotready_id = '' + valor from ccsettings where setting_id = 28) end valor 
	from ccsettings where setting_id =87) as a



	set @sql = ''select nd.tiponotready_id, nd.descripcion , snd.user_id, Nombres + replace('''' ''''+isnull(ApellidoPaterno, '''''''') + '''' ''''+
	isnull(ApellidoMaterno, ''''''''), ''''  '''', '''' '''') Nombre, a3.frame, u.login 
	from cctiponotready nd 
	join ccSupervisor_NotReady snd on (nd.tiponotready_id = snd.tiponotready_id)
	join ccUsers u on (u.user_id = snd.user_id)
	inner join ccRIAnotreadyGraph a2 on (nd.tiponotready_id=a2.tiponotready_id) 
	inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
	where nd.tiponotready_id > 0 and nd.statustiponotready = 1 and snd.user_id = case when '' + convert(varchar(10),@User_id) + '' <> 0 then '''''' 
	+ convert(varchar(10),@User_id) + '''''' else convert(varchar(10),snd.user_id) end
	and '' + @dato1 + '' order by snd.user_id ,nd.tiponotready_id''

exec sp_executesql @sql
--print (@sql)

	return(0)
 end

if @Type = 2
 begin

 	if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@User_id)
	 begin
		raiserror(''ERROR. invalid user id'', 18, 1)
		return(0)
	 end


 	if not exists(select tiponotready_id from cctiponotready where tiponotready_id =@id_ND)
	 begin
		raiserror(''ERROR. invalid notReady id'', 18, 1)
		return(0)
	 end

	if @valor=0
		delete from ccSupervisor_NotReady where user_id = @User_id and tiponotready_id = @id_ND

	else if not exists (select user_id from ccSupervisor_NotReady where user_id = @User_id and tiponotready_id = @id_ND)
		insert ccSupervisor_NotReady select @user_id, @id_ND

	return(0)
 end

if @Type = 3
 begin
	declare @NDs_Ids table (id int primary key not null)

	if @id_ND is null
	 begin
		insert into @NDs_Ids
		select value from dbo.fn_RIASplitDelimited (@id_NDs, '','')
	 end
	else
	 begin
		insert into @NDs_Ids
		select @id_ND
	 end

 	if not exists(select tiponotready_id from cctiponotready where tiponotready_id in (select id from @NDs_Ids))
	 begin
		raiserror(''ERROR. invalid notReady id'', 18, 1)
		return(0)
	 end

	if @valor=0
		delete from ccSupervisor_NotReady where tiponotready_id in (select id from @NDs_Ids)

	else
		insert ccSupervisor_NotReady select u.User_id , nd.tiponotready_id
		from ccUsers u cross join cctipoNotReady nd
		where u.tipouser_id in (2,6) and nd.tiponotready_id in (select id from @NDs_Ids)
		and cast(u.User_id as varchar(10)) + ''|'' + cast(nd.tiponotready_id as varchar(10))
		not in (select cast(User_id as varchar(10)) + ''|'' + cast(tiponotready_id as varchar(10)) 
		from ccSupervisor_NotReady)

	return(0)
 end

if @Type = 4
 begin
	
	select @dato1 = valor from (select case when valor= 3 then ''nd.issup =1'' when valor = 2 then ''nd.issup = nd.issup and nd.tiponotready_id > 0'' when valor = 4 then ''nd.issup = nd.issup and nd.tiponotready_id > 0'' else (select ''nd.tiponotready_id = '' + valor from ccsettings where setting_id = 28) end valor from ccsettings where setting_id =87) as a

	set @sql = ''select nd.tiponotready_id, nd.descripcion, a3.frame from cctiponotready nd 
			inner join ccRIAnotreadyGraph a2 on (nd.tiponotready_id=a2.tiponotready_id) 
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
	where nd.statustiponotready = 1 and '' + @dato1

	exec sp_executesql @sql
	--print (@sql)
	return(0)
 end

if @Type = 5
 begin

	select User_id, Login, Nombres + 
	replace('' ''+isnull(ApellidoPaterno, '''') + '' ''+isnull(ApellidoMaterno, ''''), ''  '', '' '') Nombre
	from ccUsers where tipouser_id in (2,6)
	order by Login
	return(0)

 end

set nocount off'
    EXEC(@sql)
	
	set @process = 'CW-6046 ccsp_MultimediaCommon - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_MultimediaCommon'')
            begin
          DROP PROCEDURE ccsp_MultimediaCommon;
            end'
    EXEC(@sql)

    set @process = 'CW-6046 Se crea SP ccsp_MultimediaCommon'
    set @sql = '
        CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon]
		@Option AS SMALLINT,
		@inboundId AS SMALLINT = 0,
		@conversationId AS INT = 0,
		@ServiceType AS SMALLINT = 0,
		@status as SMALLINT =0,
		@messagesList as varchar(max) = ''''
		AS
		BEGIN
		    SET NOCOUNT ON;

		    IF(@Option = 1)
				BEGIN

					 SELECT --inbound.chat AS ServiceType,
					   CAST(inbound.Inbound_id AS INT) AS ACDId,
					   inbound.descripcion AS ACDName,
					   ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
					   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
					   inbound.tNotas AS WrapUpTime

					   FROM  ccInbound inbound
					   INNER JOIN  contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId
				END

			IF(@Option = 2)
				BEGIN
					SELECT
						cast(i.chat as int) AS ServiceType,
						cast(c.conversationId as int) as ConversationID,
						c.clientId as ClientId,
						cm.conexionInfo as [To],
						cast(i.Inbound_id as int) as ACDId,
						i.descripcion as ACDName,
						cast(g.graphic_id as int) as ACDGraphicId,
						cast(cm.closeConversationTime as int) as [TimeOut],
						cast(cm.answerTimeOut as int) as [TimeOutWarning],
						i.ExitWrapUpDisposition as [ExitWrapUpDisposition],
						i.tNotas as [WrapUpTime],
						i.ShowCalifWnd
					FROM  ccInbound i
						INNER JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId
						INNER JOIN ccWhatsAppConversations c ON (c.inboundId = i.Inbound_id and c.conversationId = @conversationId)
						INNER JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
					WHERE i.chat = @ServiceType and i.Inbound_id = @inboundId
				END
			IF(@Option = 3)
				BEGIN
					 SELECT
					   CAST(inbound.Inbound_id AS INT) AS ACDId,
					   inbound.descripcion AS ACDName,
					   ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
					   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
					   inbound.tNotas AS WrapUpTime

					   FROM  ccInbound inbound
					   INNER JOIN  contactMeanIn configuration ON (inbound.Inbound_id = configuration.inboundId and inbound.Inbound_id = @inboundId)
				END
			IF(@Option = 4)
			Begin

				declare @pathFile as varchar(max)
				declare @filetype as varchar(5)
				DECLARE @mensajes TABLE(idMessage VARCHAR(100));

				insert into @mensajes
				select value from dbo.fn_RIASplitDelimited(@messagesList,'','')


				select @pathFile = valor from ccSettings where setting_id=230
				select
					messageId as MessageId,
					originType as Origin,
					case when originType =''Client'' then 3
						 when originType =''Agent'' then 2
						 when originType =''Admin'' then 1
					else 0 end as OriginType,
					timeStampMessage as [Timestamp],
					case when typeMessage <> ''text''  then '''' else content end as Content,
					typeMessage as Type,
					case when typeMessage not in( ''text'' ,''location'') then content else '''' end as Caption,
					case when typeMessage = ''text'' or typeMessage = ''location'' then '''' else @pathFile +char(92)+cast(conversationId/1000 as varchar(30))+char(92)+cast(conversationId as varchar(20))+char(92)+ typeMessage + char(92)+ messageId +''.''+
					case
						when typeMessage = ''video'' then ''mp4''
						when typeMessage = ''image'' then ''jpg''
						when typeMessage = ''audio'' then ''mp3''
						when typeMessage = ''file'' then (select substring(content, CHARINDEX(''.'',content)+1, len(content)))
						else '''' end
					end as [Url],
					case when typeMessage = ''location''
					then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) else '''' end as [Address],
					case when typeMessage = ''location''
					then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) else '''' end as [Lat],
					case when typeMessage = ''location''
					then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [Long],
					case when typeMessage = ''location''
					then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2) else '''' end as [Name],
					case when typeMessage = ''location''
					then ''https://www.google.com/maps/search/'' + (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) + '','' +
						(select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [LocationURL]
				 from ccWAMessagesConversations where conversationId = @conversationId and messageId in (select idMessage from @mensajes)

			End
		END'
   EXEC(@sql)

   		set @process = 'CW-6076 ccsp_CreateNodeMultimedia - Se quita el SP si ya existe'
	    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_CreateNodeMultimedia'')
	            begin
	          		DROP PROCEDURE ccsp_CreateNodeMultimedia;
	            end'
	    EXEC(@sql)

   		set @process = 'CW-6076 Se crea SP ccsp_CreateNodeMultimedia con cambios para filtro de canal de Whats en Finder'
    	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_CreateNodeMultimedia] @conversationId BIGINT
                                                , @supervisor     VARCHAR(255) = ''''
                                                , @template       VARCHAR(255) = ''''
                                                , @ScoreTemplate  INT          = 0
                                                , @type           INT                                                
					AS
					BEGIN

					    DECLARE @xml XML, @dateStart DATETIME;
					    DECLARE @info VARCHAR(255);
					    DECLARE @infoEscape VARCHAR(MAX);
					    DECLARE @charEscape VARCHAR(255), @charReplace VARCHAR(MAX);
					    SET @charEscape = ''"|''''''''|<|>|&'';
					    SET @charReplace = ''&quot;|&apos;|&lt;|&gt;|&amp;'';

					    DECLARE @existAttached BIT, @numInteracion SMALLINT;
					    IF @type = 1
					    BEGIN--CHAT
					        SELECT @xml = CONVERT(XML, ''<R01 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126))) 
					            + ''" CID="'' + CONVERT(VARCHAR(MAX), ccRIAChats.inboundid) 
					        + ''" CType="1'' 
					        + ''" C01="'' + CONVERT(VARCHAR(MAX), chatId) 
					        + ''" C02="'' + CONVERT(VARCHAR(MAX), ISNULL(ccinbound.descripcion, '''')) 
					        + ''" C03="'' + CONVERT(VARCHAR(MAX), domain) 
					        + ''" C04="'' + CONVERT(VARCHAR(MAX), ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'')) 
					        + ''" C05="'' + CONVERT(VARCHAR(MAX), tchatting) 
					        + ''" C06="'' + CONVERT(VARCHAR(MAX), ISNULL(cctipocalif.[Description], ''N/A'')) 
					        + ''" C07="'' + CONVERT(VARCHAR(MAX), ISNULL(cctipocalifsub.califSubdesc, ''N/A'')) 
					        + ''" C08="'' + CONVERT(VARCHAR(MAX), clientname) 
					        + ''" C09="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126))) 
					        + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
					        + ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
					        + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
					        + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(ccusers.[Login], '''')) 
					        + ''"/>'')
					             , @dateStart = ISNULL(chatDate, requestDate) FROM ccRIAChats
					                                                               LEFT OUTER JOIN ccinbound ON ccinbound.inbound_id = ccRIAChats.inboundid
					                                                               LEFT OUTER JOIN ccusers ON ccusers.user_id = ccRIAChats.userid
					                                                               LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = ccRIAChats.disposition
					                                                               LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = ccRIAChats.subdisposition
					                                                                                                 AND ccRIAChats.subdisposition <> 0
					        WHERE chatId = @conversationId
					              AND chatStatus = 4              

					    END;
					    ELSE
					        IF @type = 3
					        BEGIN--EMAIL
					            SELECT @existAttached = CASE WHEN COUNT(*) > 0
					                                    THEN 1 ELSE 0
					                                    END FROM attached
					            WHERE messageId IN(SELECT messageId FROM message WHERE conversationId = @conversationId);
					            SELECT @numInteracion = COUNT(*) FROM message WHERE conversationId = @conversationId;
					            --Replaza los caracteres por los comunes
					            SELECT @info = info FROM conversation WHERE conversationId = @conversationId;
					            SELECT @info = replace(@info, A.Value, B.Value) FROM dbo.fn_RIASplitDelimited(@charEscape, ''|'') A
					                                                                 INNER JOIN dbo.fn_RIASplitDelimited(@charReplace, ''|'') B ON A.Id = B.Id;

					            SELECT @xml = CONVERT(XML, ''<R03 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126))) 
					                + ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid) 
					            + ''" CType="1'' 
					            + ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationId) 
					            + ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126))) 
					            + ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion)) 
					            + ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''''))) 
					            + ''" C05="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalif.[Description], ''N/A''))) 
					            + ''" C06="'' + CONVERT(VARCHAR, MAX(replace(replace(a.mailClient, ''<'', '' ''), ''>'', '' ''))) 
					            + ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup)) 
					            + ''" C08="'' + CONVERT(VARCHAR(MAX), MIN(ISNULL(@info, ''''))) 
					            + ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid)) 
					            + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0)) 
					            + ''" C11="'' + CONVERT(VARCHAR(MAX), @existAttached) 
					            + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
					            + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
					            + ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
					            + ''" C15="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalifsub.califSubdesc, ''N/A''))) 
					            + ''" C16="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), '''')) 
					            + ''"/>'')
					                 , @dateStart = ISNULL(MAX(b.tsend), GETDATE()) FROM conversation a
					                                                                     INNER JOIN message b ON a.conversationid = b.conversationid
					                                                                     LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
					                                                                     LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
					                                                                     LEFT OUTER JOIN relationmessageDisposition e ON e.messageId = b.messageId
					                                                                     LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = e.dispositionId
					                                                                     LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = e.subdispositionId
					                                                                                                       AND e.subdispositionId <> 0
					            WHERE a.conversationId = @conversationId
					            GROUP BY a.conversationId
					                   , a.inboundid;

					        END;
					        ELSE
					            IF @type = 4
					            BEGIN--Twitter
					                SELECT @numInteracion = SUM(ninteration) FROM messageOutTwitter
					                WHERE conversationTwitterId = @conversationId;

					                SELECT @xml = CONVERT(XML, ''<R04 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126))) 
					                    + ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid) 
					                + ''" CType="1'' 
					                + ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationTwitterId) 
					                + ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126))) 
					                + ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion)) 
					                + ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''''))) 
					                + ''" C05="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalif.[Description], ''N/A''))) 
					                + ''" C06="'' + MAX(a.screenNameClient) 
					                + ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup)) 
					                + ''" C08="'' + MAX(a.screenNameInbound) 
					                + ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid)) 
					                + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0)) 
					                + ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
					                + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
					                + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
					                + ''" C14="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalifsub.califSubdesc, ''N/A''))) 
					                + ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), '''')) 
					                + ''"/>'')
					                     , @dateStart = ISNULL(MIN(b.date), GETDATE()) FROM conversationTwitter a
					                                                                        INNER JOIN messageOutTwitter b ON a.conversationTwitterId = b.conversationTwitterId
					                                                                        LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
					                                                                        LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
					                                                                        LEFT OUTER JOIN relationMessageDispositionTwit e ON e.messageOutTwitterId = b.messageOutTwitterId
					                                                                        LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = e.dispositionId
					                                                                        LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = e.subdispositionId
					                                                                                                          AND e.subdispositionId <> 0
					                WHERE a.conversationTwitterId = @conversationId
					                GROUP BY a.conversationTwitterId
					                       , a.inboundid;
					            END;
					            ELSE
					                IF @type = 5
					                BEGIN --WhatsApp
					                    SELECT @xml = CONVERT(XML, ''<R05 CDATE="'' + CONVERT(VARCHAR(23), ISNULL(conversationDate, requestDate), 126) 
					                        + ''" CID="'' + CONVERT(VARCHAR(MAX), A.inboundid) 
					                    + ''" CType="5'' 
					                    + ''" C01="'' + CONVERT(VARCHAR(MAX), A.conversationId) 
					                    + ''" C02="'' + ISNULL(inbound.descripcion, '''') 
					                    + ''" C03="'' + ISNULL(ccusers.[Login], '''') 
					                    + ''" C04="'' + ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'') 
					                    + ''" C05="'' + clientId 
					                    + ''" C06="'' + CONVERT(VARCHAR(MAX), tChatting) 
					                    + ''" C07="'' + ISNULL(cctipocalif.[Description], ''N/A'') 
					                    + ''" C08="'' + ISNULL(cctipocalifsub.califSubdesc, ''N/A'') 
					                    + ''" C09="'' + CONVERT(VARCHAR(MAX), A.agentId) 
					                    + ''" C10="'' + phoneACD 
					                    + ''" C11="'' + CONVERT(VARCHAR(MAX), A.agentId) 
					                    + ''" C12="'' + ISNULL(@supervisor, '''') 
					                    + ''" C13="'' + ISNULL(@template, '''') 
					                    + ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
					                    + ''"/>'')
					                         , @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversations A
					                                                                                   LEFT OUTER JOIN ccinbound inbound ON inbound.inbound_id = A.inboundid
					                                                                                   LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId
					                                                                                   LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
					                                                                                   LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
					                    WHERE A.conversationId = @conversationId;

					                END;

					    DECLARE @sql NVARCHAR(MAX), @tableName NVARCHAR(MAX), @columnId NVARCHAR(MAX), @tableNameHistory NVARCHAR(MAX);
					    DECLARE @parameterDefinition NVARCHAR(MAX);

					    SELECT @tableName = tableName
					         , @tableNameHistory = tableNameHistory
					         , @columnId = columnId FROM ccFinderServices
					    WHERE id = @type;

						SET @parameterDefinition = N''@conversationId bigint,@xml xml,@dateStart datetime'';

					    IF @xml IS NOT NULL
					    BEGIN        

					        SET @sql = ''IF EXISTS(SELECT * FROM '' + @tableNameHistory + '' WHERE ''+@columnId+'' = @conversationId)
					        BEGIN
					            UPDATE '' + @tableNameHistory + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
					        END
					        else IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
					        BEGIN
					            UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
					        END
					        else begin
					            INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, 0);
					        end     
					        '';
					        
					    END
						else begin
							 SET @sql ='' IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
					        BEGIN
					            UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = -1 WHERE ''+@columnId+'' = @conversationId;
					        END
					        else begin
					            INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, -1);
					        end '';
						end

						 EXECUTE sp_executesql
					                @sql
					              , @parameterDefinition
					              , @conversationId = @conversationId
					              , @xml = @xml
					              , @dateStart = @dateStart;

					END;'
   		EXEC(@sql)

   		set @process = 'CW-6076 ccsp_BaseXmngr - Se quita el SP si ya existe'
	    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_BaseXmngr'')
	            begin
	          		DROP PROCEDURE ccsp_BaseXmngr;
	            end'
	    EXEC(@sql)

   		set @process = 'CW-6076 Se crea SP ccsp_BaseXmngr con cambios para filtro de canal de Whats en Finder'
    	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_BaseXmngr]
					@action int,
					@option tinyint = 0,
					@ids varchar(max)=null,
					@name varchar(25) = NULL,
					@top int = 0,
					@dateIni datetime =null,
					@dateEnd datetime =null,
					@dateStart dateTime= null,
					@userId int = 0,
					@node varchar(10) = null
					AS

					declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
					declare @parameterDefinition nvarchar(max)
					declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
					declare @status tinyint
					set @sql = ''''

					select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=@option 

					if @action in (1,6) begin --obtiene los nodos a insertar en BX
					    if @action = 1 set @status =0
					    else if @action = 6 set @status = 2

					    if @option <>2 begin

					    declare @auxTag nvarchar(10)
					    
					    select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02''
					    else ''@CDATE''   end
					    set @parameterDefinition =N''@status int, @top int,@option int''
					    set @sql=''declare @basexName varchar(max)
					select @basexName=Xname from ccBaseXDB where serviceId=@option and isFull=0;
					    with node ( ''+@columnId+ '',xmlString,dateNode)
					    AS(
					        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
					        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
					        from ''+ @tableName + '' A with(rowlock)
					        where A.status =@status
					        union
					        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
					        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
					        from ''+ @tableNameHistory + '' A with(rowlock)
					        where A.status =@status  
					    )

					    select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
					    left join ccBaseXDB baseX on baseX.serviceId= @option and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
					    order by baseX.Xname''
					    --print(@sql)
					    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top,@option=@option
					    end
					end
					else if @action in (2,7) begin--actualiza los nodos insertados en BX
					    if @action = 2 set @status =0
					    else if @action = 7 set @status = 2

					    set @parameterDefinition =N''@status int''

					    set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
					    select @tableName,@columnId,@ids,@sql
					    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
					    set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
					    --print(@sql)
					    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status

					end
					else if @action = 3 --trae el nombre de la base de datos en BX
					begin
					    select Xname from ccBaseXDB where serviceId = @option and isFull=0
					end
					else if @action = 4 --inserta el nombre del xml en BX
					begin
					    insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
					end
					else if @action = 5 begin --obtener servicios disponibles    
					    select id, ref  from ccFinderServices where isActive=1
					end
					else if @action = 8 begin--trae la lista de las bases para la busqueda
					    select Xname from ccBaseXDB where serviceId = @option
					    and (

					    @dateIni between dateStart and dateEnd
					    or @dateEnd between dateStart and dateEnd
					    or dateStart between @dateIni and @dateEnd
					    )
					    union
					    select Xname from ccBaseXDB where serviceId = @option and isFull=0
					    and (
					        dateStart between @dateIni and @dateEnd
					        or @dateIni>=dateStart

					    )
					end
					else if @action = 9 begin--Cierra la base datos
					       update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()), dateStart=isnull(@dateStart,dateStart) where serviceId= @option and  isfull = 0 and dateEnd is null
					       and Xname=@name
					end

					else if @action = 10 begin
					   declare @filterWg varchar(max)
					    declare @len int
					    set @filterWg=''''
					    if(@node = ''R02'')
					    begin
					        select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
					        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
					        where Wguser.User_id=@userId
					 
					    end
					    else
					    begin
					    declare @serviceId varchar(10)
					    set @serviceId = (select convert(varchar(10), id) from ccFinderServices where ref = @node)
					    select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+@serviceId+'') or '' from ccRIAWorkGroupUsers Wguser
					        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
					        where Wguser.User_id=@userId and WGCam.Tipo=0
					    end


					    set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
					    select SUBSTRING(@filterWg,0, @len)
					    end


					else if @action = 11 begin--trae el nombre de la base de datos en BX

					    set @sql=''
					    declare @dateStart datetime
					    set @dateStart= convert(datetime,convert(varchar(10),getdate(),121))
					    SELECT isnull(min(dateIn),@dateStart) as node FROM ''+@tableName+'' where status = 0  ''
					    EXECUTE sp_executesql  @sql

					end'
   		EXEC(@sql)
    
    
		set @process = 'CW-6013 ccsp_GalateaSettingsById - Se quita el SP si ya existe'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaSettingsById'')
					begin
						DROP PROCEDURE ccsp_GalateaSettingsById;
					end'
		EXEC(@sql)
		
		set @process = 'CW-6013 ccsp_GalateaSettingsById - Se crea el SP'
		
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaSettingsById]
						@Id tinyint = NULL
					AS
					BEGIN

						SET NOCOUNT ON;

						SELECT [setting_id]
								,[valor]
								,[Status]
								,[Tipo]
								,[bLoadSettings]
							FROM [dbo].[ccSettings] WITH(NOLOCK)
							WHERE (@Id IS NULL OR [setting_id]=@Id)

					END'
		EXEC(@sql)

		set @process = 'CW-6053 Reporte IVR Encuestas ADD IVROptions COLUMNS'
    set @sql = 'IF NOT EXISTS(SELECT 1 FROM sys.columns 
						  WHERE Name = N''callType''
						  AND Object_ID = Object_ID(N''dbo.IVROptions''))
				BEGIN
					alter table IVROptions add callType tinyint null
				END'
	EXEC(@sql)

	set @process = 'CW-6053 Reporte IVR Encuestas Fix IVROptions'
    set @sql = 'update IVROptions set callType=2 from IVROptions ivro (nolock) join ccoCallsOut cco (nolock) on cco.cal_Inicio between dateadd(mi,-1,ivro.date) and date and ivro.cal_id=cco.cal_id
		where cal_Inicio>dateadd(m,-1,getdate())
		update IVROptions set callType=1 from IVROptions ivro (nolock) join ccCallsIn cci (nolock) on cci.cal_Inicio between dateadd(mi,-1,ivro.date) and date and ivro.cal_id=cci.cal_id
		where cal_Inicio>dateadd(m,-1,getdate())'
	EXEC(@sql)

	set @process = 'CW-6053 Reporte IVR Encuestas ALTER SP ccsp_IVRInCalls'
    set @sql = 'ALTER procedure [dbo].[ccsp_IVRInCalls]
		@action tinyint = 0 ,
		@ani varchar(30) = null ,
		@idIvr int = 0 ,
		@option varchar(5)= null ,
		@saveType tinyInt = null,
		@dnis varchar(50) = null,
		@name varchar(50) = null,
		@questionId int = 0,
		@surveyId int = 0,
		@calId int = 0,
		@callout_id int = 0,
		@ttotalIVR int = 0,
		@callType tinyint = null
		-- saveType 1 es menu 2 es dato
		-- accion 1 siempre @ani  -> @idIvr
		-- accion 2 siempre @idIvr @opcionDigitada -> nada
		AS
		IF @action = 1
		BEGIN
			IF @ani IS NOT NULL
			BEGIN
				INSERT INTO IVRCallsIn(cal_ani,date,dnis,callout_id) values(@ani,getDate(),isnull(@dnis,''''),@callout_id);
				Select ''ID''=scope_identity()
			END
		END
		ELSE IF @action = 2
		BEGIN
			IF @option IS NOT NULL AND @idIvr IS NOT NULL
			BEGIN
				INSERT INTO IVROptions(IVR_id,selectedOption,date,saveType,name, questionId, surveyId, cal_id, callType) values (@idIvr,@option,getDate(),@saveType,@name,isnull(@questionId,0),isnull(@surveyId,0),isnull(@calId,0),isnull(@callType,0))
				select 0
			END
			ELSE select -1
		END
		ELSE IF @action = 3
		BEGIN
			UPDATE IVRCallsIn set tincall = @ttotalIVR where IVR_id = @idIvr and callout_id = @callout_id
			if @callout_id > 0
				exec ccsp_EngineLogTransfers 4, @callout_id, 0, 0, null
		END'
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


