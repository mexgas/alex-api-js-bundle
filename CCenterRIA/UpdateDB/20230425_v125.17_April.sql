/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 17
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion  and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN

	BEGIN TRY
		-------------------------------------------- BEGIN MARCO GARCIA CW-7905 Registros a Marcar No toma los registros activos correctos------------------------------
		SET @process = 'KR078000-Dashboard campaña de salida-Mostrar registro en estado Procesando delete store procedure [ccsp_OUTGetNewJobs]'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_OUTGetNewJobs'')
		BEGIN
			DROP PROCEDURE ccsp_OUTGetNewJobs
		END'
	EXEC(@sql)

	SET @process = 'KR078000-Dashboard campaña de salida-Mostrar registro en estado Procesando create store procedure [ccsp_OUTGetNewJobs]';
	SET @sql = 'CREATE procedure [dbo].[ccsp_OUTGetNewJobs]
		@CAMPID int,
		@test int=0,
		@nAgentsLogin int=1,
		@iZonas int = NULL,
		@isDashboardApi BIT = 0
		as
		--set nocount on
		declare @total int
		declare @topCount smallint, @bIsDaylight bit, @revHorario bit
		declare @country_id int, @TipoJobs int
		--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
		declare @sql varchar(MAX), @Order_Asc_Desc char(4)
		declare @camSurvey int
		select @camSurvey = 0
		DECLARE @iZonasTable TABLE (value int)

		select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

		-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
		SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
		select @revHorario=valor from ccsettings where setting_id = 112
		-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
		SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
		SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

		SET DATEFIRST 1
		--Checamos si es horario de verano
		select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

		if @iZonas is null begin

			  INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
			  select @iZonas=value from @iZonasTable
		--Checamos si la campaÃ±a tiene horarios configurados
			  if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
			  begin
						  if @iZonas = 0 begin
								SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
								return
						  end
			  end
			  else begin
					if @camSurvey > 0
						  begin
								SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
								return
						  end
			  end
		end

		set @sql=''CREATE TABLE #NEW_JOBS
		(callout_id int,
			  cam_id int,
			  cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
			  cal_status tinyint,
			  cal_fechaDial datetime,
			  user_id int,
			  tz int,
		tz2 int,
		tz3 int,
		tz4 int,
		tz5 int,
		list_id int,
		sequence smallint,
		calkey varchar(max),
		nDescartes int,
		name_agent varchar(max)
		)''


		-- 0=Ambas, 1=CallBacks, 2=Nuevas
		select @topCount=valor from ccSettings where setting_id=94

		if isnull(@topCount,0)=0
		select @topCount=case when @nAgentsLogin<3 then 30
			  when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
			  when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
			  when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
			  when @nAgentsLogin>=16 then 240 else 20 end

		select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

		declare @isVerano varchar(max)
		set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

		if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
		begin

					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
					+@isVerano+'',''
					+@isVerano+''2,''
					+@isVerano+''3,''
					+@isVerano+''4,''
					+@isVerano+''5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
					isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					left join ccUsers us (nolock) on us.User_id=w.user_id
					WHERE W.cal_status=1 -- CallBacks
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
					and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
					and (
						  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
						  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
						  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
						  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
						  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
					)
					and isnull(R.status,2) = 2
					order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
					
					--select @sql
		end -- TOMA EN CUENTA LOS CALLBACKS

		if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
		begin
					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
					+@isVerano+'',''
					+@isVerano+''2,''
					+@isVerano+''3,''
					+@isVerano+''4,''
					+@isVerano+''5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
					isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					left join ccUsers us (nolock) on us.User_id=w.user_id
					WHERE W.cal_status=0 -- Nuevas
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
					and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
					and (
						  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
					)
					and isnull(R.status,2) = 2
					order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc

		end -- TOMA EN CUENTA LAS NUEVAS
		----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
		select @sql=@sql+nchar(13)+ ''SET rowcount 0''
		if @Test=0
			  begin
					select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
					WHERE callout_id in(select callout_id from #NEW_JOBS)''
		end

		if @Test = 2
		begin
			  select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
			  declare @nSQL nvarchar(4000)
			  set @nSQL=cast(@sql as nvarchar(4000))
			  exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
			  return(@total)
		end
		else
		BEGIN
			IF(@isDashboardApi = 1)
			BEGIN
					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
					+@isVerano+'',''
					+@isVerano+''2,''
					+@isVerano+''3,''
					+@isVerano+''4,''
					+@isVerano+''5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
					isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					left join ccUsers us (nolock) on us.User_id=w.user_id
					WHERE W.cal_status= 2 -- Procesando
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
					and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
					and (
						  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
					)
					and isnull(R.status,2) = 2
					order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
					 -- TOMA EN CUENTA LOS REGISTROS PROCESANDOSE
			END

			select @sql=@sql+nchar(13)+ ''SET rowcount 0''


			select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
			user_id, tz, tz2, tz3, tz4, tz5,
			case when tz is null then '''''''' else cal_telefono end as tel,
			case when tz2 is null then '''''''' else cal_telefono end as tel2,
			case when tz3 is null then '''''''' else cal_telefono end as tel3,
			case when tz4 is null then '''''''' else cal_telefono end as tel4,
			case when tz5 is null then '''''''' else cal_telefono end as tel5,
			NULL as dialOrder, list_id, sequence, calkey,
			0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent
			FROM #NEW_JOBS where len(cal_telefono)>0

			---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
			declare @regval int
			SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
			exec ccsp_GetCampsNvosCB @cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + '',@Tipo=0,@user_id =0
			''
		end

		set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
		--print (@sql)
		exec(@sql)

		return(0)';
		EXEC(@sql);


		-------------------------------------------- END MARCO GARCIA KR078000-Dashboard campaña de salida-Mostrar registro en estado Procesando------------------------------
		
		-------------------------------------------- BEGIN HUGO LONGORIA DEV2-213_Fix_Preview ------------------------------
		SET @process = 'DEV2-213_Fix_Preview - Delete store procedure [ccsp_RegProcessPreviewRecord]'
		SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RegProcessPreviewRecord'')
			BEGIN
				DROP PROCEDURE ccsp_RegProcessPreviewRecord
			END'
		EXEC(@sql)

		SET @process = 'DEV2-213_Fix_Preview - Create store procedure [ccsp_RegProcessPreviewRecord]';
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RegProcessPreviewRecord](
			@process smallint,
			@callout_id int,
			@agent_id smallint,
			@camId int,
			@previewTime smallint,
			@callId int)
			AS
			DECLARE @result_callout_id INT
			DECLARE @result_maxtimespreview INT = 0
			DECLARE @result_maxtimesdiscard INT = 0
			DECLARE @insert_date DATETIME = SYSDATETIME()
			DECLARE @process_insert int =  @process

			if(exists(select top 1 1 from ccoWorkingTable nolock where callout_id = @callout_id)) begin
				set @result_callout_id =1
			end

			IF (@process=1 AND @result_callout_id > 0)
			BEGIN
				DELETE ccoWorkingTable WHERE callout_id = @callout_id
			END

			IF (@process NOT IN (1, 7))
			BEGIN
			DECLARE @first_date DATETIME = DATEADD(hh, 00, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
				if(
					(SELECT COUNT(process) FROM RegProcessPreviewRecord 
					WHERE reg_date BETWEEN @first_date AND @insert_date
					and (process != 1 AND process != 7 AND process != 9) 
					and (callout_id=@callout_id)
					)
					>=
					(SELECT timesPreview FROM ccCamps WHERE cam_id = @camId)
					)
				begin
						set @result_maxtimespreview = 1
						set @process_insert = 8
						DELETE ccoWorkingTable WHERE callout_id = @callout_id
				end
			END

			IF (@process NOT IN (1, 7, 8))
			BEGIN
				update ccoWorkingTable set timesDiscard+=1 where callout_id=@callout_id
			END

			IF (@result_callout_id > 0 or @process in (4,7))
			BEGIN
				INSERT INTO RegProcessPreviewRecord(userId,process,callout_id,camId,reg_date,tPreview, callID) VALUES (@agent_id,@process_insert,@callout_id,@camId,@insert_date,@previewTime,@callId)
			END

			CREATE TABLE #result (result INT);
			INSERT INTO #result
			exec ccsp_CheckTimesDiscard @action=1,@camId=@camId, @calloutId=@callout_id
			select @result_maxtimesdiscard=result from #result
			DROP TABLE #result

			select case when @result_maxtimespreview = 1 or @result_maxtimesdiscard = 1 then 1 else 0 end as ''value'''
		EXEC(@sql);
		-------------------------------------------- END MARCO GARCIA DEV2-213_Fix_Preview------------------------------

		
-------------------------------------------- Daniel Hernandez CW-7873 ------------------------------
	SET @process = 'Delete stored procedure if it exists'
	SET @sql = 'if exists (select * from sys.procedures where name =''ccsp_GalateaGetCampsNvosCB'')
				begin
					DROP PROCEDURE ccsp_GalateaGetCampsNvosCB
				end'
	EXEC(@sql)

	SET @process = 'Create SP ccsp_GalateaGetCampsNvosCB FIX-Set a default value to the Overraltotalnew column when the value is null and prevent it from being zero when there are records in the campaign'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetCampsNvosCB]
	@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
	@regval int =0, @tcpa int=0
	as

	declare @TipoJobs as int, @isExecOutbound bit

	set @isExecOutbound= case when @regval=0 then 0 else 1 end

	-- Actualiza todas las camps
	if @Tipo in (1,2) begin

		declare @id AS INTEGER

		CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
		CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime)

		create table #temccocallsoutsource (cam_id int,Pend  int)

		create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

		if @cam_id = 0 begin
			if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
				select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
				from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
				where user_id = @user_id and tipo = 1
			end
			else begin
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
				select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
				from ccCamps cam (nolock)
			end
		end
		else begin
			if @Tipo = 2
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
				select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
				from ccCamps cam with(nolock) 
				where cam.cam_id = @cam_id
			else
				if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
					insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
					select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
					from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
					where user_id = @user_id and tipo = 1
				end
				else begin
					insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
					select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
					from ccCamps cam (nolock) 
					where cam_activo=1 
				end
		end



		insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate)
		select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate) from(
		select A.*,dateUpdate from #Tcamps A
		left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
		where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null)X
		group by cam_id


		
		if (select count(*) from #Tcamps2)>0 begin

			insert into #temccocallsoutsource(cam_id,Pend)
			SELECT ccos.cam_id, count(ccos.cam_id) as Pend
			FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
			join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
			WHERE cal_status in(0, 7)
			GROUP BY ccos.cam_id

			insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
			SELECT A.cam_id,
			count(case cal_status when 0 then 1 else null end) as New,
			count(case cal_status when 1 then 1 else null end) as Cb,
			count(case cal_status when 2 then 1 else null end) as Pro,
			count(case cal_status when 3 then 1 else null end) as Fin
			FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
			join #Tcamps2 B on A.cam_id = B.cam_id
			GROUP BY A.cam_id	

		
			if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
			update #Tcamps2 set status =1,cantidad=0  where cam_id = @cam_id
			end
			else begin
				While exists(select * from #Tcamps2 where status = 0 and ( datediff(ss,dateUpdate,getdate())>60 or dateUpdate is null))  Begin
					set rowcount 1
					select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
					set rowcount 0
					EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
					update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
				end
			end

			declare @TotalNew table(
					cam_id int primary key,
					OverallTotalNew int 
				)
			

			begin Tran updateccCampsNvosCB

				insert into @TotalNew
				select CampNvosCB.id,isnull(CampNvosCB.OverallTotalNew,CampNvosCB.new)  from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
				where CampNvosCB.id = tcamp.cam_id

				delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
				where CampNvosCB.id = tcamp.cam_id

				INSERT into ccCampsNvosCB 
				SELECT cams.cam_id, cams.cam_descripcion,
				isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
				isNull(cs.Pend,0) as pend,
				isNull(wt.Pro,0) as pro,
				isNull(cams.procesando,0) cam_procesando,
				isNull(cams.cam_tipojobs,0) cam_tipojobs,
				isNull(wt.Fin,0) Fin,
				isNull(cams.cantidad,0) cantidad,
				getdate(),
				--isnull(T.OverallTotalNew,0)  as OverallTotalNew
				isnull(
				case T.OverallTotalNew
				when 0 then 
					case cams.cam_tipojobs
					when 0 then wt.New + wt.Cb
					when 1 then wt.Cb
					else wt.New end 
				else T.OverallTotalNew end
				,0)  as OverallTotalNew
				FROM #Tcamps2 cams with(nolock)
				LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
				LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
				LEFT JOIN @TotalNew  T on T.cam_id = cams.cam_id

			COMMIT TRAN updateccCampsNvosCB
		end

		if @isExecOutbound = 0 begin

		if @Tipo = 2 begin
			-- devuelve resultado de la taba, solo las camps del usuario
			SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, 
			isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor, OverallTotalNew
			FROM #Tcamps tcam
			left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
			LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
			inner join cccamps cc (nolock) on res.id=cc.cam_id
		end
		else 
			SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,
			cc.aggressionFactor, OverallTotalNew
			FROM ccCampsNvosCB res (nolock)
			LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
			inner join cccamps cc (nolock) on res.id=cc.cam_id
			WHERE res.id = @cam_id
		end

		drop table #Tcamps
		drop table #Tcamps2
		drop table #temccocallsoutsource
		drop table #temWorkinTable

		return(0)

	end'
	EXEC(@sql)
-------------------------------------------------------------------------------------------------------
		
		----------------------------------------------------------------------------------------------------------------------------
		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
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


