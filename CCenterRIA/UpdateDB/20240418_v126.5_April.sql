/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2023/07/04
Description: K089000
Database: CCenterRia
Required version: 125.37
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 5
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end
IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END
IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY
        ----------------------------------------------------- BEGIN PharmaPronto----------------------------------------------------------------
    SET @process = 'CREATE Sp ccRelationIvrWorkingTable'
	SET @sql = 'if not exists (select * from sys.tables where name = N''ccRelationIvrWorkingTable'')
begin
    Create table ccRelationIvrWorkingTable(IVR_id int not null,callout_id int not null,callFechaDial datetime not null)
end'
	exec(@sql)

	SET @process = 'CREATE Sp ccRelationIvrWorkingTable'
	SET @sql = 'if not exists (select * from sys.tables where name = N''ccLogAgentesDiaLast'')
begin
    CREATE TABLE [dbo].[ccLogAgentesDiaLast]
(
	  [User_id] SMALLINT NOT NULL
	, [TipoStatusAge_id] TINYINT NOT NULL
	, [tStatus] FLOAT NULL
	, [fecha] DATETIME NOT NULL
	, [IdCampEsp] SMALLINT NULL
	, [Tipo] SMALLINT NULL
	, [currentStatus] INT NULL
	, [callID] INT NULL
	, CONSTRAINT [PK__ccLogAgentesDiaLast__206A9DF893323245] PRIMARY KEY ([User_id] ASC)
)


ALTER TABLE [dbo].[ccLogAgentesDiaLast] WITH CHECK ADD CONSTRAINT [FK_ccLogAgentesDiaLast_ccTipoStatusAgente] FOREIGN KEY([TipoStatusAge_id]) REFERENCES [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id])
ALTER TABLE [dbo].[ccLogAgentesDiaLast] CHECK CONSTRAINT [FK_ccLogAgentesDiaLast_ccTipoStatusAgente]

end'
	exec(@sql)

	SET @process = 'Alter SP ccsp_AgentUpdateCallTimes se agrega la eliminacion del callback si ya se realizo el callback'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentUpdateCallTimes]
@IDCall int,
@cal_tXfer float,
@cal_tDialog float,
@cal_tNotas float,
@TipoCall tinyint,
@cal_tRing float=0,
@mtmoh smallint = 0,
@isChatCall bit = 0,
@isErroManualCall bit =0,
@isTransferEngine bit =0
AS
set nocount on
if @IDCall<=0 
    return(0)

declare @tMinAVRS smallint
declare @cal_manual int
declare @minimoDialogo tinyint 
select @minimoDialogo = valor from ccSettings where setting_id = 13

set @cal_manual=0

if @TipoCall=1 begin--INBOUND
  if @cal_tDialog < @minimoDialogo and @isTransferEngine =1 begin
    --el status 18 es para llamada cortada con transferencia en Reminder
    exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @IDCall, @nStatus = 18
  end
  Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, 
    cal_tDialog=case when @cal_tDialog > 0 and @cal_tDialog > cal_tDialog then @cal_tDialog else cal_tDialog end, 
  cal_tNotas=@cal_tNotas, 
  cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
  cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
  Where cal_id= @IDCall

  exec ccspSaveDispositionResult @action=2, @callid=@IDCall,@callType=0,@statusCallId=13


  --Actualizar tiempo total de llamada
  exec ccsp_EngineLogTransfers 2, @IDCall, @TipoCall, 2, null, @cal_tXfer, @cal_tDialog

  -- Elimina callback generado por abandono
  
  if @isTransferEngine = 0  begin
  Declare @ANI_x varchar(19)
  select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

  DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
  DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
  end
end
else if @TipoCall=2 begin--OUTBOUND 
	declare @calloutId int
    Update ccoCallsOUT with(rowlock) Set cal_tXfer=case when @cal_tXfer > 0 then @cal_tXfer else cal_tXfer end, 
    cal_tRing=case when @cal_tRing > 0 then @cal_tRing else cal_tRing end, 
    cal_tDialog=case when @cal_tDialog > 0 and @cal_tDialog > cal_tDialog then @cal_tDialog else cal_tDialog end, 
    
    cal_tNotas=case when @cal_tNotas > 0 then @cal_tNotas else cal_tNotas end, 
    cal_tMoh=case when @mtmoh > 0 then @mtmoh else cal_tMoh end,
    
    cal_manual=case when @isChatCall=1 then 3 else cal_manual end,
    cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end,
    totalCall_Time=case when totalCall_Time is null then @cal_tDialog else totalCall_Time end 
	,@calloutId=callout_id
    Where cal_id=@IDCall

    exec ccspSaveDispositionResult @action=2, @callid=@IDCall,@callType=1,@statusCallId=13
		
	DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE callout_id=@calloutId

    -- calcula el costo de la llamada
    exec ccsp_CstoCalculaCosto @IDCall
  select @cal_manual=cal_manual from ccoCallsOUT with(nolock) Where cal_id=@IDCall

 end

select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

if @cal_tDialog >= @tMinAVRS and @cal_manual<>1
  and not exists(select * from ccAVRSTransfer where cal_id=@IDCall and tipo=@TipoCall - 1) 
  begin 
        insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
end

return(0)
set nocount off'
	exec(@sql)

	SET @process = 'Alter SP ccsp_INInsertaCallBack return callout_id'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_INInsertaCallBack]
	@cal_key varchar(40) ='''',
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
	declare @iZonaHoraria2 int,@iZonaHoraria_verano2 int
	declare @iZonaHoraria3 int,@iZonaHoraria_verano3 int
	declare @iZonaHoraria4 int,@iZonaHoraria_verano4 int
	declare @iZonaHoraria5 int,@iZonaHoraria_verano5 int
	if @isAuto=0
		select @difference = isNull(dbo.fnGetTimeDifference(dbo.fnGetTimeZone(@cal_telefono,@bIsDaylight)),0)
	else
		set @difference = 0
	select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))

	if exists(select cal_Key, cam_id from ccoCallsOutSource where cal_Key = @cal_key and cam_id =@cam_id)
	 begin
		select @callout_id=callout_id,@cal_statusTemp =cal_status,
		@iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end,@iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end, 
		@iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end,@iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end, 
		@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end,@iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end, 
		@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end,@iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end, 
		@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end,@iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end, 
		@TelOriginal = cal_telefono, @FechaOriginal = cal_fechadial from ccoCallsOutSource 
		where cal_Key = @cal_key and cam_id = @cam_id

		update ccoCallsOutSource set cal_status = ''2'',cal_telefono=@cal_telefono where cal_key = @cal_key and cam_id = @cam_id

		if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
			UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
		else
			INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw
			,iZonaHoraria,iZonaHoraria_verano
			,iZonaHoraria2,iZonaHoraria_verano2
			,iZonaHoraria3,iZonaHoraria_verano3
			,iZonaHoraria4,iZonaHoraria_verano4
			,iZonaHoraria5,iZonaHoraria_verano5)
			select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key
			,@iZonaHoraria,@iZonaHoraria_verano
			,@iZonaHoraria2,@iZonaHoraria_verano2
			,@iZonaHoraria3,@iZonaHoraria_verano3
			,@iZonaHoraria4,@iZonaHoraria_verano4
			,@iZonaHoraria5,@iZonaHoraria_verano5

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

		insert into ccoCallsOutSource (cal_key,cam_id,cal_telefono,cal_fechadial,Dato1,Dato2,Dato3,Dato4,Dato5,cal_status)
		values (@cal_key,@cam_id,@cal_telefono,@FechaOriginal,@dato1,@dato2,@dato3,@dato4,@dato5,''2'')

		select @TelOriginal = @cal_telefono

		select @callout_id = scope_identity()
		select @iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano from ccocallsoutsource where callout_id=@callout_id

		select @callout_id=callout_id,
		@iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end,@iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end, 
		@iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end,@iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end, 
		@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end,@iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end, 
		@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end,@iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end, 
		@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end,@iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end
		from ccoCallsOutSource 
		where callout_id=@callout_id


		 if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
			UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
		 else
			INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw
			,iZonaHoraria,iZonaHoraria_verano
			,iZonaHoraria2,iZonaHoraria_verano2
			,iZonaHoraria3,iZonaHoraria_verano3
			,iZonaHoraria4,iZonaHoraria_verano4
			,iZonaHoraria5,iZonaHoraria_verano5)
			select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key
			,@iZonaHoraria,@iZonaHoraria_verano
			,@iZonaHoraria2,@iZonaHoraria_verano2
			,@iZonaHoraria3,@iZonaHoraria_verano3
			,@iZonaHoraria4,@iZonaHoraria_verano4
			,@iZonaHoraria5,@iZonaHoraria_verano5

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

	return(@callout_id)
	set nocount off'
	exec(@sql)

	SET @process = 'Alter SP ccsp_IVRInCalls se agrega parametro @callbackCamId'
	SET @sql = 'ALTER procedure [dbo].[ccsp_IVRInCalls]
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
@callType tinyint = null,
@callbackCamId int =0
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
	if @callout_id > 0 begin
		exec ccsp_EngineLogTransfers 4, @callout_id, 0, 0, null
	end
	if @callbackCamId >0  begin
		EXEC [ccsp_KolobUpdateCallback_AbandonIVR] @idIvr, @callbackCamId
	end
END'
	exec(@sql)

	SET @process = 'Alter SP ccsp_IVRUpdateCallEndNew se agrega @generateCallback'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_IVRUpdateCallEndNew]
@cal_id INT,
@cal_tIVRCallDuration INT,
@statuscal_id TINYINT, 
@cal_opciones VARCHAR(10),
@cal_colgada TINYINT,
@User_id SMALLINT,
@cal_extension VARCHAR(7),
@tWait SMALLINT,
@cbPhone VARCHAR(20),
@generateCallback int=1
AS
SET NOCOUNT ON

if @statuscal_id <>2 begin
	set @generateCallback=1		
end

UPDATE ccCallsIn 
SET statusCall_id = 
	CASE 
		WHEN @statuscal_id IN (2, 3, 4, 7, 8) THEN @statuscal_id 
		ELSE 
			CASE 
				WHEN statusCall_id = 5 THEN 6 
				ELSE statuscall_id 
			END 
	END, 
	user_id = 
	CASE 
		WHEN user_id = 0 AND @User_id > 0 THEN @User_id 
		ELSE user_id 
	END, 
cal_extension = 
	CASE 
		WHEN LEN(cal_extension) = 0 AND LEN(@cal_extension) > 0 THEN @cal_extension 
		ELSE cal_extension 
	END, 
cal_tWait = @tWait, 
cal_final = getdate() 
WHERE cal_id=@cal_id


if @generateCallback=1 begin
	EXEC ccsp_RIAUpdateCallBack_Abandon @cal_id, @statuscal_id, @cbPhone
end	
EXEC ccsp_EngineLogTransfers 2, @cal_id, 2, 2, null, @tWait, @cal_tIVRCallDuration

SET NOCOUNT OFF '
	exec(@sql)

	SET @process = 'Alter Sp ccsp_IVRUpdateCallSetStatus se agrega @generateCallback'
	SET @sql = 'ALTER procedure [dbo].[ccsp_IVRUpdateCallSetStatus]
@cal_id int,
@nStatus tinyint,
@userId int=0,
@generateCallback int=1
as
set nocount on

Update ccCallsIn SET cal_que=case @nStatus when 5 -- En Espera
then 1 else cal_que end, statusCall_id=case when statusCall_id<>13 then @nStatus else statusCall_id end
,User_id= case when @userId >0 and User_id=0  then @userId else User_id end
where cal_id=@cal_id

if @nStatus<>2 begin
	set @generateCallback=1
end

if @generateCallback=1 begin
	exec ccsp_RIAUpdateCallBack_Abandon @cal_id, @nStatus
end

return(0)
set nocount off'
	exec(@sql)

	SET @process = ' DROP PROCEDURE ccsp_KolobUpdateCallback_AbandonIVR'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_KolobUpdateCallback_AbandonIVR'')
    begin
        DROP PROCEDURE ccsp_KolobUpdateCallback_AbandonIVR;
    end'
	exec(@sql)

	SET @process = 'CREATE SP ccsp_KolobUpdateCallback_AbandonIVR'
	SET @sql = 'CREATE procedure [dbo].[ccsp_KolobUpdateCallback_AbandonIVR]
@idIvr int = 0, 
@cam_id int=0   
 as
 set nocount on
 declare @ANI varchar(13), @callFechaDial datetime, @callout_id int
if @cam_id is null or @cam_id=0 begin
	return
end
     
select @ANI= cal_ani from IVRCallsIn with(nolock) where IVR_id=@idIvr
select top 1 @callout_id=callout_id from ccoWorkingTable WITH(nolock) WHERE cal_telefono=@ANI and cam_id=@cam_id

if(@callout_id is not null) begin
	return
end
	
	set @callFechaDial=dateadd(mi,1,GETDATE());

	exec @callout_id = ccsp_INInsertaCallBack @idIvr, @cam_id, @ANI, @callFechaDial, '''','''','''','''','''', 1, 0, 1
	
	insert into ccRelationIvrWorkingTable values(@idIvr,@callout_id,@callFechaDial)
	

 set nocount off'
	exec(@sql)

	

	SET @process = 'Alter SP ccsp_RIAAdmDelRegs se modifica @tipoDel = 2'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAAdmDelRegs]
@tipoDel int, -- 1 Registros Nuevos / 2 Registros CallBack / 3 Registros sin meter a WT / 4 Registros CallBack - Excepto los programados por Agentes
@cam_id int,
@phone varchar(30) = '''',
@calkey varchar(40) = '''',
@exact bit = 1
AS

if @tipoDel = 1 --nuevos
 begin
	delete ccoWorkingTable where cam_id = @cam_id and cal_status = 0
 end

if @tipoDel = 2 --callbacks
 begin
	
	delete from ccRIAUpdateCallBack_Abandon where callout_id in(select callout_id from ccoWorkingTable with(nolock) where cam_id = @cam_id and cal_status = 1)
	delete ccoWorkingTable where cam_id = @cam_id and cal_status = 1
 end

if @tipoDel = 3 -- 3 Registros sin meter a WT
 begin
	update ccocallsoutsource --with(rowlock)
	set cal_Status = 5 
	where cam_id = @cam_id 
	and cal_status in(0, 7)

	Delete ccUploadTemporal where cam_id = @cam_id
 end

if @tipoDel = 4 --callbacks
 begin
	delete ccoWorkingTable where cam_id = @cam_id and cal_status = 1 and user_id=0
 end

if @tipoDel = 5 --callbacks
 begin
	delete ccoWorkingTable where cam_id = @cam_id and cal_status = 3
 end

if @tipoDel = 6 -- Delete a record from a specific campaign containing a specific phone number
begin   
	delete ccoWorkingTable --with(rowlock) 
	where callout_id in (select callout_id 
							from ccocallsoutsource with(nolock)
							where cam_id = @cam_id 
							and (cal_telefono = @phone or 
									cal_telefono2 = @phone or 
									cal_telefono3 = @phone or 
									cal_telefono4 = @phone or 
									cal_telefono5 = @phone))

	update ccocallsoutsource --with(rowlock)
	set cal_Status = 5 
	where cam_id = @cam_id  and 
		(cal_telefono = @phone or 
		cal_telefono2 = @phone or 
		cal_telefono3 = @phone or 
		cal_telefono4 = @phone or 
		cal_telefono5 = @phone)

end

if @tipoDel = 7 -- Delete all the records from a specific campaign
begin
	delete from ccoWorkingTable where cam_id = @cam_id

	update ccocallsoutsource set cal_Status = 5 where cam_id = @cam_id
end

if @tipoDel = 8 --delete records by specific callkey
 begin
	if @exact = 1
		delete ccoWorkingTable with(rowlock) where cal_keyw = @calkey and cal_status <> 2
	else
		delete ccoWorkingTable with(rowlock) where cal_keyw like ''%'' + @calkey + ''%'' and cal_status <> 2
 end'
	exec(@sql)

	SET @process = ''
	SET @sql = 'ALTER procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]
@cal_id int,
@nStatus tinyint,
@cbPhone varchar(20) = NULL
as
set nocount on
declare @ANI varchar(13), @cam_id int, @inbound_id int, @fechadial varchar(40), @callout_id int, 
    @statuscall_id_Array varchar(1000), @minCallBackAbandon smallint, @pais varchar(2), @ld varchar(5), @telFormat tinyint

declare @lenExt int

select @ANI=C.cal_ANI, 
        @cam_id = CASE WHEN @nStatus IN(11,13) AND ((C.cal_whoHung = 2 AND ISNULL(extend.SurveyCamId,0) > 0) OR (C.cal_whoHung = 0 AND ISNULL(i.callBackSurveyClient,0) > 0)) THEN extend.SurveyCamId ELSE I.cam_id END,
        @inbound_id=I.inbound_id, 
@statuscall_id_Array=statuscall_id_Array, @minCallBackAbandon=minCallBackAbandon,@telFormat = I.telFormato
from cccallsin C 
join ccInbound I on I.Inbound_id=C.Inbound_id
left join ccInboundExtend extend on extend.Inbound_id = I.Inbound_id
where cal_id=@cal_id

if @nStatus not in (select value from dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','')) or isnull(@cal_id,0)=0
    return(0)


if datalength(isnull(@cbPhone,'''')) > 0
begin
    set @ANI=@cbPhone
end

select @fechadial=convert(varchar(16), dateadd(minute, @minCallBackAbandon, getdate()), 121)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @lenExt = case when valor=''''then 0 else valor end from ccSettings with(nolock) where setting_id = 108

             
if isnull(@cam_id, 0)=0
    return(0)

              
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
    exec @callout_id= ccsp_INInsertaCallBack @cal_id, @cam_id, @ANI, @fechadial, @dato1,@dato2,@dato3,@dato4,@dato5, 1, 0, 1
	if @callout_id is null or @callout_id=0 begin
		select top 1 @callout_id=callout_id from ccoWorkingTable WITH(INDEX(PK_ccoWorkingTable)) WHERE cal_telefono=@ANI
	end
    select @fechadial=dateadd(minute, minCallBackAbandonXpire, @fechadial) from ccInbound where Inbound_id=@inbound_id
    update ccRIAUpdateCallBack_Abandon set callout_id=@callout_id, minCallBackAbandonXpire=@fechadial where cal_id=@cal_id
    return(0)
    end try

    begin catch
    return(0)
    end catch
set nocount off'
	exec(@sql)

	


	SET @process = 'Alter Sp ccsp_SaveStatusAgent'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
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
@tDialog float =0 ,
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
if (@tStatus = 0 and @TipoStatusAge_id=30 ) begin
	return (0)
end

declare @cam_id int,@surveycamId int
declare @cal_telefono varchar(30)
declare @cal_key varchar(40)
declare @inbound_id int
declare @callBackSurveyClients bit
declare @cal_whoHung tinyint
declare @cal_tXfer float,@cal_tRing float
declare @cal_tDialog float
declare @cal_tNotas float
declare @cal_tNotaOri float

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

if @isLogout=1 begin --Logout
	if @TipoCall = 0 begin --IN	
	
		select @calInicio=cal_Xfer,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas, @Camp=Inbound_id, @cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas, @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
		,@cal_tXfer=cal_tXfer,@cal_tRing=cal_tRing
		from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13

		if @cal_tXfer=0 and @cal_tRing=0 begin
			select @cal_tXfer=case when TipoStatusAge_id=5 then tStatus else @cal_tXfer end
			,@cal_tRing=case when TipoStatusAge_id=9 then tStatus else @cal_tRing end
			from ccLogAgentesDia with(nolock) where User_id=@User_id and callID = @call_id and Tipo=@TipoCall
			and TipoStatusAge_id in(5,9)
		end


		if @cal_tDialog = 0 and @tDialog >0 begin
		if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
		set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
		if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
		if @TipoStatusAge_id=6  begin
			if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
			else  set @tDialog=@tDialog-1
		end
		end
		update ccCallsIN with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold
		,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
		where cal_id = @call_id and statusCall_id = 13		
		----------------------------
		if @TipoCall = 0 and @isTransferEngine = 1 begin --IN
			declare @minimoDialogo tinyint 
			select  @minimoDialogo = valor from ccSettings where setting_id = 13
			if @cal_tDialog < @minimoDialogo begin
				--el status 18 es para llamada cortada con transferencia en Reminder
				exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id, @nStatus = 18
			end
	end	
		-----------------------------
end
end
else begin --OUT	
		declare @calloutId int
		select @calInicio=cal_inicio,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,
		@cam_id = cam_id,@cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas 
		,@cal_tXfer=cal_tXfer,@cal_tRing=cal_tRing
		,@calloutId=@callout_id
		from ccoCallsOut with(nolock) where cal_id = @call_id
		set @Camp=@cam_id

		if @cal_tXfer=0 and @cal_tRing=0 begin
			select @cal_tXfer=case when TipoStatusAge_id=5 then tStatus else @cal_tXfer end
			,@cal_tRing=case when TipoStatusAge_id=9 then tStatus else @cal_tRing end
			from ccLogAgentesDia with(nolock) where User_id=@User_id and callID = @call_id and Tipo=@TipoCall
			and TipoStatusAge_id in(5,9)
		end
		
		if @cal_tDialog = 0 and @tDialog>0 begin
			if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
				set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
				if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
				if @TipoStatusAge_id=6  begin
					if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
					else  set @tDialog=@tDialog-1
				end
			end
			update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog, cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold 
			,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
			where cal_id = @call_id and statusCall_id = 13
		end
		else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
			update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog  
			,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
			where cal_id = @call_id
		else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
			update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas 
			,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
			where cal_id = @call_id		

		delete from ccRIAUpdateCallBack_Abandon with(rowlock) where callout_id= @calloutId
	end
	--- Revisa si tiene que guardar la grabacion para finder
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
end --Logout

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
						values(right((cast(@call_id as varchar) + '''' + @cal_Key),40),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()) )
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
				values(right((cast(@call_id as varchar) + '''' + @cal_Key),40),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()))
			end
		end
	end
	end--@isTransferSurvey = 0 and @callout_id>0
end --End -- 4 = Dialogo


if @isLogout=0 and @TipoStatusAge_id =6  begin
	--Valida que el ccserver no haya guardado antes el status antes al desloguear
	if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-10,@Fecha4) and @Fecha4 and tStatus = @tStatus+1)
		INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )
		if not exists(select  * from [ccLogAgentesDiaLast] where User_id=@User_id) begin
			INSERT [ccLogAgentesDiaLast] ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  
			VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )	
		end
		else begin
			update [ccLogAgentesDiaLast] set TipoStatusAge_id=@TipoStatusAge_id,tStatus=@tStatus, fecha=@Fecha4
			, IdCampEsp=@Camp, Tipo=@TipoCall, currentStatus=@currentStatus,callID=@call_id where USER_ID=@User_id
		end
	end
else begin
	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )
		if not exists(select  * from [ccLogAgentesDiaLast] where User_id=@User_id) begin
			INSERT [ccLogAgentesDiaLast] ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  
			VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )	
		end
		else begin
			update [ccLogAgentesDiaLast] set TipoStatusAge_id=@TipoStatusAge_id,tStatus=@tStatus, fecha=@Fecha4
			, IdCampEsp=@Camp, Tipo=@TipoCall, currentStatus=@currentStatus,callID=@call_id where USER_ID=@User_id
		end
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

if ( @TipoStatusAge_id = 34  and @call_id > 0) -- Dialogo WhatsApp
begin
    if @TipoCall=0 begin
        update ccWhatsAppConversations set tChatting = (tChatting + @tStatus) where conversationId = @call_id;
        set @Camp = (select inboundId from ccWhatsAppConversations  where conversationId = @call_id);
        EXEC ccsp_WhatsAppInformation @Option = 2, @InboundId = @Camp
    end
    else begin
        update ccWhatsAppConversationsOut set tChatting = (tChatting + @tStatus) where conversationId = @call_id;
        set @Camp = (select camId from ccWhatsAppConversationsOut  where conversationId = @call_id);
        EXEC ccsp_WhatsAppInformationOut @Option = 2, @camId = @Camp
    end
end'
	exec(@sql)

	SET @process = ''
	SET @sql = ''
	exec(@sql)

	SET @process = ''
	SET @sql = ''
	exec(@sql)

------------------------------------------------------------------------------ END PharmaPronto -------------------------------------------------------------------

 
        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()
        RAISERROR (@errorGenerated, 11, 1)
        ROLLBACK TRAN
    END CATCH
END 
