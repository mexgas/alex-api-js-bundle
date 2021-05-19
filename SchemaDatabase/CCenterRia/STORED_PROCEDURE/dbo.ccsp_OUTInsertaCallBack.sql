CREATE PROCEDURE [dbo].[ccsp_OUTInsertaCallBack]
	@cal_id int,
	@Telefono varchar(15),
	@Camp smallint,
	@FechaDial smalldatetime,
	@callout_id int=0,
	@TelReprograma smallint=-1,
	@user_id int=0,
	@cal_Key varchar(40)='',
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
		  select @emptyPhoneMsg = case valor when 0 then 'El teléfono no puede ser nulo o vacío' else 'Phone number can not be null or empty' end from ccsettings where setting_id = 27

		  if charIndex('E_NV',@phoneCompleted) > 0
				set @phoneCompleted = @Telefono
				if @phoneCompleted = ''
				begin
					  raiserror(@emptyPhoneMsg, 18, 1)
				end

		 select @tel2=cal_telefono2,@tel3=cal_telefono3,@tel4=cal_telefono4,@tel5=cal_Telefono5,@cal_Key=cal_key
		 from ccoCallsoutSource where callout_id=@callout_id

		  select @TelReprograma=case when isnull(@tel4,'')='' then 4 when isnull(@tel3,'')='' then 3     when isnull(@tel2,'')='' then 2 else 5 end

		  select @sSQL='update ccoCallsOutSource set cal_telefono'+cast(@TelReprograma as varchar(1))+'='''+@phoneCompleted+''''
		  +',cal_status=2,iZonaHoraria'+cast(@TelReprograma as varchar(1))+'= '+cast(@idZone as varchar(10))+', iZonaHoraria_Verano'+cast(@TelReprograma as varchar(1))+'= '+cast(@idZoneDaylight as varchar(10))+' where callout_id='+cast(@callout_id as varchar(10))
		  exec(@sSQL)
	END

	ELSE--@>0 telefono ya existente
	BEGIN
		  update ccoCallsOutSource set cal_status=2
		  where callout_id=@callout_id

		  select @sSQL= N'select @outA=cal_key, @outB=izonahoraria' +replace( cast( @TelReprograma as varchar(1)), '1', '' )+', @outC=izonahoraria_verano'+replace( cast( @TelReprograma as varchar(1)), '1', '' )+', @outD= rtrim(left(ltrim(cal_telefono + ''        ''
				+ cal_telefono2 + ''         ''
				+ cal_telefono3 + ''         ''
				+ cal_telefono4 + ''         ''
				+ cal_telefono5 + ''         ''),13)) from ccoCallsOutSource where callout_id = ' +cast(@callout_id as varchar)
		  exec sp_executesql @sSQL, N'@outA varchar(33) OUTPUT, @outB int OUTPUT, @outC int OUTPUT, @outD varchar(19) OUTPUT', @outA=@cal_Key OUTPUT, @outB=@idZone OUTPUT, @outC=@idZoneDaylight OUTPUT, @outD=@Telefono OUTPUT
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
		  insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),'1',@Camp

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

	set nocount off