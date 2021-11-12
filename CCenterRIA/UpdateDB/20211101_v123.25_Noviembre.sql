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
