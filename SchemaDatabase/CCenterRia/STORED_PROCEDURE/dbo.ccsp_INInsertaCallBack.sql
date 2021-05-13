CREATE PROCEDURE [dbo].[ccsp_INInsertaCallBack]
	@cal_key varchar(40) ='',
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

	if isnull(@cal_key,'') = ''
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

		update ccoCallsOutSource set cal_status = '2',cal_telefono=@cal_telefono where cal_key = @cal_key and cam_id = @cam_id

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
		values (@cal_key,@cam_id,@cal_telefono,@FechaOriginal,@dato1,@dato2,@dato3,@dato4,@dato5,'2')

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
		insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),'1',@cam_id

	return(0)
	set nocount off