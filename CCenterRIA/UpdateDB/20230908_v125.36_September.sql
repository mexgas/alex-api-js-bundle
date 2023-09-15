/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K053000

Database: CCenterRia
Required version: 125.36

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
SET @versionfix = 36
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

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

	---------------------------------------BEGIN JCL---------------------------------------------------------
	SET @process = 'INSERT SETTING 251'
	SET @sql = 'IF NOT EXISTS (SELECT setting_id from ccSettings where setting_id = 251) 
				BEGIN

				INSERT INTO [dbo].[ccSettings]
						   ([setting_id]
						   ,[valor]
						   ,[descripcion]
						   ,[Status]
						   ,[Tipo]
						   ,[detalle]
						   ,[description])
					 VALUES
						   (251
						   ,5
						   ,''Registros máximos asignados por agente Vista Previa''
						   ,1
						   ,''AGT''
						   ,''Cantidad máxima de registros de vista previa que pueden ser asignados a un agente cuando está atendiendo más de una campaña de vista previa''
						   ,''Maximum record preview indicator that can be assigned to an agent serving multiple preview campaigns'')

				END
	'
	EXEC(@sql)


		SET @process = 'GET SETTING 251'
	SET @sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
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
		declare @camSurvey INT, @campType INT;
		select @camSurvey = 0
		DECLARE @iZonasTable TABLE (value int)
		declare @maxRecs varchar(3) = 0

		select @maxRecs = valor from ccsettings (nolock) where setting_id = 251 and Status = 1		
		select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0;
		SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id =  @CAMPID;

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
		--Checamos si la campaña tiene horarios configurados
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
		name_agent varchar(max),
		SimultaneousRecs int
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
		set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' END
        
		IF(@campType = 7)
		BEGIN
			set @isVerano = ''W.iTimeZone'' + case @bIsDaylight when 1 then ''_summer'' else '''' END
		END


		if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
		begin

					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';

					IF(@campType = 7)
					BEGIN
						select @sql=@sql+nchar(13)+ ''SELECT W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial, W.user_id,''
						+@isVerano+'',''
						+@isVerano+''2,''
						+@isVerano+''3,''
						+@isVerano+''4,''
						+@isVerano+''5,
						W.list_id, isNull(R.sequence,0) as sequence,
						sos.callkey+''''~''''+rtrim(data1)+''''~''''+rtrim(data2)+''''~''''+rtrim(data3)+''''~''''+rtrim(data4)+''''~''''+rtrim(data5) calkey, 0 AS nDescartes,
						isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, 0 SimultaneousRecs
						FROM smsWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
						left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
						left join ccUsers us (nolock) on us.User_id=w.user_id
						WHERE W.sms_status=1 -- CallBacks
						and W.sms_dateDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
						and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
						and (
							  ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''=0) or
							  ((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2=0) or
							  ((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3=0) or
							  ((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4=0) or
							  ((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5=0)
						)
						and isnull(R.status,2) = 2
						order by priority_cb desc, W.sms_dateDial ''  + @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
					END
					ELSE
					BEGIN
						select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
						+@isVerano+'',''
						+@isVerano+''2,''
						+@isVerano+''3,''
						+@isVerano+''4,''
						+@isVerano+''5,
						W.list_id, isNull(R.sequence,0) as sequence,
						cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
						isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs
						FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
						left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
						left join ccUsers us (nolock) on us.User_id=w.user_id
						left join ccCampsExtend ce on ce.cam_id=W.cam_id
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
					END
					
		end -- TOMA EN CUENTA LOS CALLBACKS

		if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
		begin
					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar );

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';

					IF(@campType = 7)
					BEGIN
						select @sql=@sql+nchar(13)+ ''SELECT W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial, W.user_id,''
						+@isVerano+'',''
						+@isVerano+''2,''
						+@isVerano+''3,''
						+@isVerano+''4,''
						+@isVerano+''5,
						W.list_id, isNull(R.sequence,0) as sequence,
						sos.callkey+''''~''''+rtrim(data1)+''''~''''+rtrim(data2)+''''~''''+rtrim(data3)+''''~''''+rtrim(data4)+''''~''''+rtrim(data5) calkey, 0 AS nDescartes,
						isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, 0 SimultaneousRecs
						FROM smsWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
						left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
						left join ccUsers us (nolock) on us.User_id=w.user_id
						WHERE W.sms_status=0 -- Nuevas
						and W.sms_dateDial < dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
						and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
						and (
							  ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''=0) or
							   ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2=0) or
							   ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3=0) or
							   ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4=0) or
							   ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5=0)
						)
						and isnull(R.status,2) = 2
						order by R.sequence, W.sms_dateDial ''+ @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc
					END
					ELSE
					BEGIN
						select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
						+@isVerano+'',''
						+@isVerano+''2,''
						+@isVerano+''3,''
						+@isVerano+''4,''
						+@isVerano+''5,
						W.list_id, isNull(R.sequence,0) as sequence,
						cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
						isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs
						FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
						left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
						left join ccUsers us (nolock) on us.User_id=w.user_id
						left join ccCampsExtend ce on ce.cam_id=W.cam_id
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
					END

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
					isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					left join ccUsers us (nolock) on us.User_id=w.user_id
					left join ccCampsExtend ce on ce.cam_id=W.cam_id
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

			select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
			user_id, tz, tz2, tz3, tz4, tz5,
			case when tz is null then '''''''' else cal_telefono end as tel,
			case when tz2 is null then '''''''' else cal_telefono end as tel2,
			case when tz3 is null then '''''''' else cal_telefono end as tel3,
			case when tz4 is null then '''''''' else cal_telefono end as tel4,
			case when tz5 is null then '''''''' else cal_telefono end as tel5,
			NULL as dialOrder, list_id, sequence, calkey,
			0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent, SimultaneousRecs,'' + @maxRecs + '' maxRecs
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

		return(0)
	'
	EXEC(@sql)


	---------------------------------------END JCL---------------------------------------------------------
	
	SET @process = 'DEV2-253 se agrega tradcucción (cancelada en diálogo) a la tabla ccTypeProcessPreview '
	SET @sql = '
	if not exists(select typeProcess_id from ccTypeProcessPreview where typeProcess_id = 13)
		begin
			insert into ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (13, ''CancelledByEngaged'',''systemTranslated_CancelledByEngaged'')
		end'
	EXEC(@sql)

	SET @process = 'DEV2-253 se agrega tradcucción (cancelada) a la tabla ccTypeProcessPreview '
	SET @sql = '
	if not exists(select typeProcess_id from ccTypeProcessPreview where typeProcess_id = 14)
		begin
			insert into ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (14, ''Cancelled'',''systemTranslated_Cancelled'')
		end'
	EXEC(@sql)

	SET @process = 'DEV2-253 DROP PROCEDURE ccsp_GetPreviewHistory '
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GetPreviewHistory'')
    begin
        DROP PROCEDURE ccsp_GetPreviewHistory;
    end'
	EXEC(@sql)
	
	SET @process = 'DEV2-253 CREATE PROCEDURE ccsp_GetPreviewHistory '
	SET @sql = '
	CREATE Proc [dbo].[ccsp_GetPreviewHistory]( @callOut_Id int ,@initialRow smallint,@finalRow smallint)
		AS
		declare @initialDate datetime, @finalDate datetime
		set @finalDate= GETDATE()
		set @initialDate = (select DATEDIFF(day,30,@finalDate))

		declare @temTable table (callOut_id int, dialResult varchar(50),disposition varchar(100),date datetime)
		insert into @temTable 
					select co.callout_id as callOut_id, 
					trd.descTranslate dialResult,
					ISNULL( tco.Description,'''') as calificacion,
					ld.fecha as fecha
					from ccoCallsOut co 
					left join ccoLogDials ld on co.callout_id = ld.callout_id
					left join cctipoResultadoDial trd ON ld.tipoResDial_id = trd.tiporesdial_id
					LEFT JOIN cctipocalifout tco ON tco.calif_id = co.calif_id
					where co.callout_id = @callOut_Id and co.cal_id = ld.cal_id  and ld.fecha >= @initialDate and ld.fecha <=@finalDate and ld.tipoResDial_id != 13  and (ld.tipoResDial_id != 14 and ld.canceledNoAgents=1)
					and cast(co.cal_Inicio as varchar) = cast(ld.fecha as varchar)

					union 
					select rppr.callout_id,
					tpp.descripcion,
					'''',
					rppr.reg_date
					from RegProcessPreviewRecord rppr
					join ccTypeProcessPreview tpp on rppr.process= tpp.typeProcess_id
					where rppr.process NOT IN (1,5,7,14) and rppr.callout_id = @callOut_Id and rppr.reg_date >= @initialDate and rppr.reg_date <=@finalDate
			

		SELECT  * FROM    
				( SELECT    ROW_NUMBER() OVER ( ORDER BY date ) AS RowNum, *
				  FROM      @temTable 
				) AS RowConstrainedResult
		WHERE   RowNum >= @initialRow
			AND RowNum <= @finalRow 
		ORDER BY RowNum	'
	EXEC(@sql)
	
	--------------------------------------------------------------------START HL----------------------------------------------------------------------------------------
	SET @process = 'DEV2-216-Drop SP ccsp_RegProcessPreviewRecord'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_RegProcessPreviewRecord'')
			BEGIN
				DROP PROCEDURE [dbo].[ccsp_RegProcessPreviewRecord]
			END'
	EXEC(@sql)

	SET @process = 'DEV2-216-Create SP ccsp_RegProcessPreviewRecord'
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

			IF ((@process=1 OR @process=16 or @process=15) AND @result_callout_id > 0)
			BEGIN
				DELETE ccoWorkingTable WHERE callout_id = @callout_id
			END

			IF (@process=16 or @process=15)
			BEGIN
				select 1 ''value''
				return
			END

			IF (@process NOT IN (1, 7, 13))
			BEGIN
			DECLARE @first_date DATETIME = DATEADD(hh, 00, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
				if(
					(SELECT COUNT(process) FROM RegProcessPreviewRecord 
					WHERE reg_date BETWEEN @first_date AND @insert_date
					and (process = 5) 
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

			IF (@process NOT IN (1, 5, 7, 8, 13))
			BEGIN
				update ccoWorkingTable set timesDiscard+=1 where callout_id=@callout_id
			END

			IF (@result_callout_id > 0 or @process in (4, 5, 7, 13))
			BEGIN
				INSERT INTO RegProcessPreviewRecord(userId,process,callout_id,camId,reg_date,tPreview,callID) VALUES (@agent_id,@process_insert,@callout_id,@camId,@insert_date,@previewTime,@callId)
			END

			CREATE TABLE #result (result INT);
			INSERT INTO #result
			exec ccsp_CheckTimesDiscard @action=1,@camId=@camId, @calloutId=@callout_id
			select @result_maxtimesdiscard=result from #result
			DROP TABLE #result

			select case when @result_maxtimespreview = 1 or @result_maxtimesdiscard = 1 then 1 else 0 end as ''value'''
	EXEC(@sql)

	SET @process = 'DEV2-253 DROP PROCEDURE ccsp_AgentSetCallStatus '
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_AgentSetCallStatus'')
    begin
        DROP PROCEDURE ccsp_AgentSetCallStatus;
    end'
	EXEC(@sql)

	SET @process = 'DEV2-253 CREATE PROCEDURE ccsp_AgentSetCallStatus - no eliminar en WT cuando camp = Preview(6)'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_AgentSetCallStatus] 
		@callout_id INT, 
		@cal_id     INT, 
		@TipoCall   TINYINT, -- 1= IN,  2=Out
		@TipoMov    TINYINT, -- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
		@cal_tXfer  TINYINT    = 0, 
		@cal_tring  SMALLINT   = 0, 
		@user_id    SMALLINT   = 0, 
		@extension  VARCHAR(5) = '''', 
		@isChatCall BIT        = 0
	AS
		 SET NOCOUNT ON
		 DECLARE @RecicleSIC TINYINT

		 SELECT @RecicleSIC = ISNULL(valor, 0)
		 FROM ccSettings
		 WHERE setting_id = 60

		 DECLARE @ANI_x VARCHAR(19)
		 DECLARE @cal_inicio DATETIME
		 DECLARE @callout_id_IN INT
		 DECLARE @cal_key VARCHAR(20)
		 DECLARE @cam_id INT
		 DECLARE @cal_telefono VARCHAR(30)
		 DECLARE @surveycamid INT
		 DECLARE @inbound_id INT
		 IF @TipoMov = 4 OR @TipoMov = 14 -- DIALOG OnDialog
			 BEGIN
				 IF @TipoCall = 2
					 BEGIN
						 IF @TipoMov = 4
							 BEGIN
								 UPDATE ccoCallsOUT WITH(ROWLOCK)
								   SET cal_Inicio = GETDATE(), 
									   statusCall_id = 13, 
									   cal_manual = CASE
														WHEN @isChatCall = 1
														THEN 3
														ELSE cal_manual
													END
								 WHERE cal_id = @cal_id
						 END
							 ELSE
							 IF @TipoMov = 14
								 UPDATE ccoCallsOUT WITH(ROWLOCK)
								   SET statusCall_id = 13, 
									   cal_tRing = @cal_tring, 
									   user_id = case when user_id=0 and @user_id>0 then @user_id else user_id end, 
									   cal_extension = case when cal_extension=0 and @extension>0 then @extension else cal_extension end
								 WHERE cal_id = @cal_id
						SELECT @cam_id=cam_id FROM ccoWorkingTable nolock WHERE callout_id = @callout_id
						IF @RecicleSIC = 0 AND (SELECT campType FROM ccCamps WHERE cam_id = @cam_id) != 6
						BEGIN
							DELETE ccoWorkingTable WITH(ROWLOCK) WHERE callout_id = @callout_id
							DELETE ccoCallPriorityOrder WITH(ROWLOCK) WHERE callout_id = @callout_id
						END
						 UPDATE ccoCallBacks
						   SET [status] = 1, 
							   schedulerStatus = 1, 
							   cal_fcallback = cal_inicio
						 FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
						 WHERE a.callout_id = b.callout_id
							   AND b.callout_id = @callout_id
							   AND b.cal_id = @cal_id
							   AND [status] = 0
							   AND statusCall_id = 13

						 -- calcula el costo de la llamada
						 EXEC ccsp_CstoCalculaCosto @cal_id

						 RETURN(0)
				 END
				 IF @TipoMov = 4
					 UPDATE ccCallsIN WITH(ROWLOCK)
					   SET statusCall_id = 13
					 WHERE cal_id = @cal_id

					 ELSE
					 IF @TipoMov = 14
						 UPDATE ccCallsIN WITH(ROWLOCK)
						   SET statusCall_id = 13, 
							   cal_tRing = @cal_tring, 
							   user_id = case when user_id=0 and @user_id>0 then @user_id else user_id end, 
							   cal_extension = case when cal_extension=0 and @extension>0 then @extension else cal_extension end
						 WHERE cal_id = @cal_id

				 -- Elimina callback generado por abandono
				 SELECT @ANI_x = cal_ani, 
						@cal_inicio = cal_inicio
				 FROM cccallsin WITH (INDEX(PK_ccCallsIn))
				 WHERE cal_id = @cal_id

				 SELECT @callout_id_IN = callout_id
				 FROM ccRIAUpdateCallBack_Abandon
				 WHERE cal_ani = @ANI_x

				 UPDATE ccoCallBacks WITH(ROWLOCK)
				   SET [status] = 1, 
					   schedulerStatus = 1, 
					   cal_fcallback = @cal_inicio
				 WHERE callout_id = @callout_id_IN
					   AND [status] = 0

				 DELETE ccoWorkingTable WITH(ROWLOCK)
				 WHERE callout_id IN
				 (
					 SELECT DISTINCT
							(callout_id)
					 FROM ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
					 WHERE cal_ani = @ANI_x
				 )

				 DELETE ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
				 WHERE cal_ANI = @ANI_x

				 RETURN(0)
		 END
		 IF @TipoMov = 7 --OTHER OFFHook_OnXfer
			 BEGIN
				 IF @cal_id <= 0
					 RETURN(0)
				 IF @TipoCall = 2
					 BEGIN
						 UPDATE ccoCallsOUT WITH(ROWLOCK)
						   SET statusCall_id = 16
						 WHERE cal_id = @cal_id
						 -- calcula el costo de la llamada

						 UPDATE ccoCallBacks
						   SET [status] = 2, 
							   schedulerStatus = 1, 
							   cal_fcallback = cal_inicio
						 FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
						 WHERE a.callout_id = b.callout_id
							   AND b.callout_id = @callout_id
							   AND b.cal_id = @cal_id
							   AND [status] = 0
							   AND statusCall_id = 16

						 EXEC ccsp_CstoCalculaCosto 
							  @cal_id

						 RETURN(0)
				 END
				 UPDATE ccCallsIN WITH(ROWLOCK)
				   SET statusCall_id = 16
				 WHERE cal_id = @cal_id

				 SELECT @ANI_x = cal_ani, 
						@cal_inicio = cal_inicio
				 FROM cccallsin WITH (INDEX(PK_ccCallsIn))
				 WHERE cal_id = @cal_id

				 SELECT @callout_id_IN
				 FROM ccRIAUpdateCallBack_Abandon
				 WHERE cal_ani = @ANI_x

				 UPDATE ccoCallBacks WITH(ROWLOCK)
				   SET [status] = 2, 
					   schedulerStatus = 1, 
					   cal_fcallback = @cal_inicio
				 WHERE callout_id = @callout_id_IN
					   AND [status] = 0

				 RETURN(0)
		 END
		 IF @TipoMov = 9 --RING CallNoAnswered
			 BEGIN
				 IF @TipoCall = 2
					 BEGIN
						 UPDATE ccoCallsOUT WITH(ROWLOCK)
						   SET statusCall_id = 15, 
							   cal_tXFer = @cal_txFer, 
							   cal_tRing = @cal_tring
						 WHERE cal_id = @cal_id

						 -- calcula el costo de la llamada

						 UPDATE ccoCallBacks
						   SET [status] = 2, 
							   schedulerStatus = 1, 
							   cal_fcallback = cal_inicio
						 FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
						 WHERE a.callout_id = b.callout_id
							   AND b.callout_id = @callout_id
							   AND b.cal_id = @cal_id
							   AND [status] = 0
							   AND statusCall_id = 15

						 EXEC ccsp_CstoCalculaCosto @cal_id
				 END

				 UPDATE ccCallsIN WITH(ROWLOCK)
				   SET statusCall_id = 15, 
					   cal_tXFer = @cal_txFer, 
					   cal_tRing = @cal_tring
				 WHERE cal_id = @cal_id

				 SELECT @ANI_x = cal_ani, 
						@cal_inicio = cal_inicio
				 FROM cccallsin WITH (INDEX(PK_ccCallsIn))
				 WHERE cal_id = @cal_id

				 SELECT @callout_id_IN
				 FROM ccRIAUpdateCallBack_Abandon
				 WHERE cal_ani = @ANI_x

				 UPDATE ccoCallBacks WITH(ROWLOCK)
				   SET [status] = 2, 
					   schedulerStatus = 1, 
					   cal_fcallback = @cal_inicio
				 WHERE callout_id = @callout_id_IN
					   AND [status] = 0

				 RETURN(0)
		 END
		 SET NOCOUNT OFF'
	EXEC(@sql)

	SET @process = 'DEV2-253 DROP PROCEDURE ccsp_GalateaGetPreviewData '
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GalateaGetPreviewData'')
    begin
        DROP PROCEDURE ccsp_GalateaGetPreviewData;
    end'
	EXEC(@sql)

	SET @process = 'DEV2-253 CREATE PROCEDURE ccsp_GalateaGetPreviewData - nolock'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaGetPreviewData]
        @option int = null,
		@callout_id int = null,
        @user_id smallint = null

        AS
        set nocount on

		if(@option = 1 or @option is null)
		begin
			declare @typePreview varchar = null

			select @typePreview= valor from ccSettings (nolock)
			where setting_id=248 and Status=1

			select ''previewData''=
			 case when U.AllowDeleteRecord=1 then ''true'' else ''false'' end +''~''+
			 ISNULL(P.Headers,'''')+''~''+
			 ISNULL(O.Dato1,'''')+''~''+
			 ISNULL(O.Dato2,'''')+''~''+
			 ISNULL(O.Dato3,'''')+''~''+
			 ISNULL(O.Dato4,'''')+''~''+
			 ISNULL(O.Dato5,'''')+''~''+
			 ISNULL(P.Dato6,'''')+''~''+
			 ISNULL(P.Dato7,'''')+''~''+
			 ISNULL(P.Dato8,'''')+''~''+
			 ISNULL(P.Dato9,'''')+''~''+
			 ISNULL(P.Dato10,'''')+''~''+
			 ISNULL(P.Dato11,'''')+''~''+
			 ISNULL(P.Dato12,'''')+''~''+
			 ISNULL(P.Dato13,'''')+''~''+
			 ISNULL(P.Dato14,'''')+''~''+
			 ISNULL(P.Dato15,'''')+''~''+
			 ISNULL(O.cal_telefono2,'''')+''~''+
			 ISNULL(O.cal_telefono3,'''')+''~''+
			 ISNULL(O.cal_telefono4,'''')+''~''+
			 ISNULL(O.cal_telefono5,'''')+''~''+
			 ISNULL(cast(O.cal_Key as varchar),'''')+''~''+
			 ISNULL(cast(O.cal_telefono as varchar),'''')+''~''+
			 @typePreview+''~'',
			 C.previewDiscard
				   from ccoCallsOutSource O (nolock)
			INNER JOIN ccoCallsPreviewData P (nolock) on O.cal_Key=P.Cal_key and O.cam_id=P.cam_id
			INNER JOIN ccCamps C (nolock) on P.cam_id = C.cam_id
			JOIN ccUsers U (nolock) on U.TipoUser_id=1
			Where callout_id=@callout_id and U.User_id=@user_id
		end

		if(@option = 2)
		begin
			select COUNT(*) from ccoCallsOutSource nolock where callout_id = @callout_id
		end
        set nocount off'
	EXEC(@sql)

	SET @process = 'DEV2-253 DROP PROCEDURE ccsp_OUTUpdateDialJob '
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_OUTUpdateDialJob'')
    begin
        DROP PROCEDURE ccsp_OUTUpdateDialJob;
    end'
	EXEC(@sql)

	SET @process = 'DEV2-253 CREATE PROCEDURE ccsp_OUTUpdateDialJob - CONTESTA no eliminar en WT cuando camp = Preview(6)'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
		@callout_id     INT,
		@CallResultDial TINYINT,
		@isTCPA         BIT     = 0
		AS
			 SET NOCOUNT ON

		/*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
		++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine	*/

			 DECLARE @nOcupado TINYINT, @nNoContesta TINYINT, @nFax TINYINT, @nContestadora TINYINT
			 DECLARE @nShortCall TINYINT, @nOtro TINYINT, @cam_NoInt_ocupado TINYINT, @cam_NoInt_graba TINYINT
			 DECLARE @cam_ocupado SMALLINT, @cam_inter_ocupado SMALLINT, @cam_nocontesto SMALLINT
			 DECLARE @cam_graba SMALLINT, @cam_inter_graba SMALLINT, @cam_inter_nocontesto SMALLINT
			 DECLARE @cam_fax SMALLINT, @cam_inter_fax SMALLINT
			 DECLARE @DateNextDial SMALLDATETIME, @DateNewDial SMALLDATETIME, @cam_id SMALLINT
			 DECLARE @ExisteWT TINYINT, @cam_NoInt_fax TINYINT, @cam_NoInt_nocontesto TINYINT, @cal_status TINYINT
			 DECLARE @sSQL NVARCHAR(MAX), @Telefono VARCHAR(15), @prioridadLlamada CHAR(8)

			 SELECT @cam_id = cam_id,
					@nOcupado = ISNULL(nOcupado, 0),
					@nNoContesta = ISNULL(nNoContesta, 0),
					@nFax = ISNULL(nFax, 0),
					@nContestadora = ISNULL(nContestadora, 0),
					@nShortCall = ISNULL(nShortCall, 0),
					@nOtro = ISNULL(nOtro, 0),
					@DateNextDial = cal_fechaDial
			 FROM ccoWorkingTable with(nolock)
			 WHERE callout_id = @callout_id

			 SELECT @ExisteWT = CASE WHEN @cam_id IS NOT NULL THEN 1 ELSE 0 END
			 SELECT @cal_status = CASE WHEN @isTCPA = 1 THEN 0 ELSE 1 END--si esta en modo TCPA no gene|rar callbacks

			 IF @CallResultDial = 20 BEGIN-- CONTACTADO
				EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
				RETURN(0)
			 END
			 else IF @CallResultDial = 1 BEGIN-- CONTESTO
				IF @isTCPA = 1 BEGIN
						UPDATE ccoWorkingTable with(rowlock) SET cal_status = @cal_status WHERE callout_id = @callout_id
				END
				ELSE BEGIN
					IF (SELECT campType FROM ccCamps WHERE cam_id = @cam_id) = 6
						RETURN(0)
					IF (SELECT abandonCallback FROM ccCamps WHERE cam_id = @cam_id) = 1
						BEGIN
							EXEC ccsp_OUTCancelDialJOB @callout_id,1,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
					END
					ELSE BEGIN
						EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
					END
				END
				RETURN(0)
			 END
			 ELSE IF @CallResultDial IN(2, 12) BEGIN -- OCUPADO
				SELECT @cam_ocupado = cam_ocupado,
					@cam_inter_ocupado = cam_inter_ocupado,
					@cam_NoInt_ocupado = cam_NoInt_ocupado,
					@nOcupado = @nOcupado + 1
				FROM ccCamps
				WHERE cam_id = @cam_id

					IF @cam_ocupado = 1 BEGIN -- Opcion Ocupado HABILITADA
						IF @nOcupado > @cam_NoInt_ocupado OR @nShortCall > 4 BEGIN
							EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
							RETURN(0)
						END


						SELECT @prioridadLlamada=priorityCall FROM ccoCallPriorityOrder with(nolock) WHERE callout_id = @callout_id
						IF @prioridadLlamada is null BEGIN
							SELECT @prioridadLlamada = Prioridad FROM ccCampsPrioridadTel with(nolock) WHERE cam_id = @cam_id
							INSERT INTO ccoCallPriorityOrder VALUES (@callout_id,@prioridadLlamada)
						END

						-- Change priority and obtain the next telephone
						UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1	ELSE nNoContesta END
						WHERE callout_id = @callout_id


						set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
						UPDATE ccoCallPriorityOrder with(rowlock) SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

						SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
						+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
						+ CAST(@callout_id AS VARCHAR(15))

						EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

						SELECT @DateNewDial = DATEADD(mi, @cam_inter_ocupado, GETDATE())

						-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
						IF @DateNewDial > @DateNextDial BEGIN	-- Nueva fecha de Call BACk
							UPDATE ccoWorkingTable with(rowlock) SET nOcupado = @nOcupado, cal_fechaDial = @DateNewDial, cal_status = @cal_status
							WHERE callout_id = @callout_id
							RETURN(0)
						END
						-- Mantiene la fecha de Call BACK
						UPDATE ccoWorkingTable with(rowlock) SET nOcupado = @nOcupado, cal_status = @cal_status, cal_telefono = @Telefono
						WHERE callout_id = @callout_id
						RETURN(0)
					END

					-- ELSE: Opcion Ocupado DESHABILITADA
					EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
					RETURN(0)
				 END
				 ELSE IF @CallResultDial IN(3, 5, 8) BEGIN-- NO CONTESTA
					--select NO Contesta
					SELECT @cam_nocontesto = cam_nocontesto,
						@cam_inter_nocontesto = cam_inter_nocontesto,
						@cam_NoInt_nocontesto = cam_NoInt_nocontesto,
						@nNoContesta = @nNoContesta + 1
					FROM ccCamps
					WHERE cam_id = @cam_id

					IF @cam_nocontesto = 1 BEGIN-- Opcion NoContesta HABILITADA
						IF @nNoContesta > @cam_NoInt_nocontesto OR @nShortCall > 4 BEGIN --select No Contesta Habilitada
							EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
							RETURN(0)
						END

						SELECT @prioridadLlamada=priorityCall FROM ccoCallPriorityOrder with(nolock) WHERE callout_id = @callout_id
						IF @prioridadLlamada is null BEGIN
							SELECT @prioridadLlamada = Prioridad FROM ccCampsPrioridadTel with(nolock) WHERE cam_id = @cam_id
							INSERT INTO ccoCallPriorityOrder VALUES (@callout_id,@prioridadLlamada)
						END

						-- Change priority and obtain the next telephone
						UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1
						ELSE nNoContesta END
						WHERE callout_id = @callout_id


						set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
						UPDATE ccoCallPriorityOrder with(rowlock) SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

						SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
						+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
						+ CAST(@callout_id AS VARCHAR(15))

						EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

						SELECT @DateNewDial = DATEADD(mi, @cam_inter_nocontesto, GETDATE())

						UPDATE ccoWorkingTable with(rowlock) SET nNoContesta = @nNoContesta, cal_status = @cal_status, cal_telefono = @Telefono,
							cal_fechaDial = CASE
												WHEN @DateNewDial > @DateNextDial
												THEN @DateNewDial
												ELSE cal_fechaDial
											END
						WHERE callout_id = @callout_id
						RETURN(0)
					END

					-- Opcion NoContesta DESHABILITADA
					EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
					RETURN(0)
				END
			ELSE IF @CallResultDial = 4 BEGIN-- Fax/Modem
				SELECT @cam_fax = cam_fax,
					@cam_inter_fax = cam_inter_fax,
					@cam_NoInt_fax = cam_NoInt_fax,
					@nFax = @nFax + 1
				FROM ccCamps
				WHERE cam_id = @cam_id

				IF @cam_fax = 1 BEGIN-- Opcion Fax/Modem HABILITADA
						IF @nFax > @cam_NoInt_fax OR @nShortCall > 4 BEGIN
							EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
							RETURN(0)
						END

						SELECT @prioridadLlamada=priorityCall FROM ccoCallPriorityOrder with(nolock) WHERE callout_id = @callout_id
						IF @prioridadLlamada is null BEGIN
							SELECT @prioridadLlamada = Prioridad FROM ccCampsPrioridadTel with(nolock) WHERE cam_id = @cam_id
							INSERT INTO ccoCallPriorityOrder VALUES (@callout_id,@prioridadLlamada)
						END

						-- Change priority and obtain the next telephone
						UPDATE ccoCallsOutSource with(rowlock) SET nFax = CASE WHEN nFax < 255 THEN ISNULL(nFax, 0) + 1 ELSE nFax END
						WHERE callout_id = @callout_id

						set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
						UPDATE ccoCallPriorityOrder with(rowlock)  SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

						SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
						+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
						+ CAST(@callout_id AS VARCHAR(15))

						EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

						SELECT @DateNewDial = DATEADD(mi, @cam_inter_fax, GETDATE())

						-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
						UPDATE ccoWorkingTable with(rowlock) SET nFax = @nFax, cal_status = @cal_status, cal_telefono = @Telefono,
							cal_fechaDial = CASE
												WHEN @DateNewDial > @DateNextDial
												THEN @DateNewDial
												ELSE cal_fechaDial
											END
						WHERE callout_id = @callout_id
						RETURN(0)
				END

				-- Opcion Fax/Modem DESHABILITADA
				EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
				RETURN(0)
			END
			ELSE IF @CallResultDial = 11 BEGIN-- Maquina Contestadora
				SELECT @cam_graba = cam_graba,
					@cam_inter_graba = cam_inter_graba,
					@cam_NoInt_graba = cam_NoInt_graba,
					@nContestadora = @nContestadora + 1
				FROM ccCamps
				WHERE cam_id = @cam_id

				IF @cam_graba = 1 BEGIN-- Opcion Maquina Contestadora HABILITADA
					IF @nContestadora > @cam_NoInt_graba OR @nShortCall > 4 BEGIN
						EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
						RETURN(0)
					END

					SELECT @prioridadLlamada=priorityCall FROM ccoCallPriorityOrder with(nolock) WHERE callout_id = @callout_id
					IF @prioridadLlamada is null BEGIN
						SELECT @prioridadLlamada = Prioridad FROM ccCampsPrioridadTel with(nolock) WHERE cam_id = @cam_id
						INSERT INTO ccoCallPriorityOrder VALUES (@callout_id,@prioridadLlamada)
					END

					-- Change priority and obtain the next telephone
					UPDATE ccoCallsOutSource with(rowlock) SET nContestadora = CASE WHEN nContestadora < 255 THEN ISNULL(nContestadora, 0) + 1 ELSE nContestadora END
					WHERE callout_id = @callout_id

					set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
					UPDATE ccoCallPriorityOrder with(rowlock) SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

					SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
					+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
					+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
					+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
					+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
					+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
					+ CAST(@callout_id AS VARCHAR(15))

					EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

					SELECT @DateNewDial = DATEADD(mi, @cam_inter_graba, GETDATE())

					-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
					UPDATE ccoWorkingTable with(rowlock) SET nContestadora = @nContestadora, cal_status = @cal_status, cal_telefono = @Telefono,
						cal_fechaDial = CASE
											WHEN @DateNewDial > @DateNextDial
											THEN @DateNewDial
											ELSE cal_fechaDial
										END
					WHERE callout_id = @callout_id
					RETURN(0)
				END

				-- Opcion Maquina Contestadora DESHABILITADA
				EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
				RETURN(0)
			END
			ELSE IF @CallResultDial IN(10, 90) BEGIN--No Dial Tone, otros, NoService
				EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
				RETURN(0)
			END
			ELSE IF @CallResultDial > 13 AND @CallResultDial <> 51   BEGIN--Dial Result not register
			   EXEC ccsp_OUTUpdateDialJob @callout_id = @callout_id, @CallResultDial = 8, @isTCPA = @isTCPA
			END

		RETURN(0)
		SET NOCOUNT OFF'
	EXEC(@sql)

	SET @process = 'DEV2-253 DROP FUNCTION fn_getDialingMode'
	SET @sql = '
	IF EXISTS ( SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[fn_getDialingMode]'')
		AND type IN (N''FN'', N''IF'', N''TF'', N''FS'', N''FT'') )
    begin
        DROP FUNCTION [dbo].[fn_getDialingMode];
    end'
	EXEC(@sql)

	SET @process = 'DEV2-253 CREATE FUNCTION fn_getDialingMode - reestablecer Preview (256)'
	SET @sql = '
		CREATE FUNCTION [dbo].[fn_getDialingMode](@call_id int, @TipoDialingMode tinyint, @logDial_id int, @cam_id int)
		returns nvarchar(9)
		as
		begin
			declare @valor nvarchar(9), @calif_id smallint, @califSub_id smallint, @cal_manual tinyint, @keepDial char(1), @cal_odbc bit
			set @keepDial=''0''

			-- En el caso de que no cuente con cal_id, se debe contar con logDial_id, por lo cual se busca el registro
			if @call_id is null
			 begin
				select top 1 @call_id=o.cal_id from ccoLogDials l with(nolock,index(PK_ccoLogDials)) join ccocallsout o with(nolock,index(IX_ccoCallsOut_2))
					on l.callout_id = o.callout_id and l.Puerto = o.cal_puerto
				where l.logDial_id = @logDial_id and l.fecha between convert(varchar(19), dateadd(minute, -5, o.cal_inicio), 121)
				and convert(varchar(19), dateadd(minute, 5, o.cal_inicio), 121)
				order by datediff(ss, l.fecha, o.cal_inicio) asc -- en caso de tener mas de uno, toma el que tenga menor diferencia en tiempo
			 end

			if @cam_id is null
			 begin
				select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual, @cam_id=cam_id, @cal_odbc = cal_odbc
				from ccocallsout O with(nolock,index(PK_ccoCallsOut))
				where O.cal_id = @call_id
			 end
			else
			 begin
				select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual, @cal_odbc = cal_odbc
				from ccocallsout O with(nolock,index(PK_ccoCallsOut))
				where O.cal_id = @call_id
			 end

			select @valor=isnull((select case when campType=6 then ''100'' when progDial=2 then ''010'' when progDial=1 then ''001'' else ''000'' end + cast(iTipoDial as char(1)) + cast(abandonCallback as char(1))
			 + cast(excCallback as char(1)) from cccamps where cam_id=@cam_id), ''000000'')

			if ((select keepDial from ccTipoCalifOUT where calif_id = @calif_id)=1
			or (select keepDial from ccTipoCalifSubOUT where califSub_id = @califSub_id)=1)
				set @keepDial=''1''

			select @valor = @valor + @keepDial + case @cal_manual when 1 then ''10'' when 2 then ''01'' else ''00'' end
		
			  select @valor=substring(@valor, 1, 3) +
			  case @TipoDialingMode when 6 then ''1'' else substring(@valor, 4, 1) end + substring(@valor, 5, 2) +
			  case @TipoDialingMode when 3 then ''1'' else substring(@valor, 7, 1) end + substring(@valor, 8, 2)
		  
		 return @valor
		end'
	EXEC(@sql)

	SET @process = 'DEV2-253 Remove Duplicates ccoCallsPreviewData'
	SET @sql = '
		WITH cte AS (SELECT cal_key,cam_id,TotalData,ROW_NUMBER() OVER (PARTITION BY cal_key,cam_id,TotalData ORDER BY TotalData desc) rownum FROM ccoCallsPreviewData NOLOCK)
		DELETE FROM cte WHERE rownum>1'
	EXEC(@sql)

	SET @process = 'DEV2-253 DROP PK ccoCallsPreviewData'
	SET @sql = '
		IF (SELECT OBJECTPROPERTY(OBJECT_ID(''PK_ccoCallsPreviewData_cam_id_cal_Key''), ''IsPrimaryKey'')) IS NOT NULL
		BEGIN
			ALTER TABLE ccoCallsPreviewData DROP CONSTRAINT PK_ccoCallsPreviewData_cam_id_cal_Key; 
		END'
	EXEC(@sql)

	SET @process = 'DEV2-253 ADD PK ccoCallsPreviewData '
	SET @sql = '
		ALTER TABLE ccoCallsPreviewData ADD CONSTRAINT PK_ccoCallsPreviewData_cam_id_cal_Key PRIMARY KEY CLUSTERED (cam_id,cal_Key);'
	EXEC(@sql)

	SET @process = 'DEV2-216-Drop SP ccsp_RIACampsManualCall'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_RIACampsManualCall'')
			BEGIN
				DROP PROCEDURE [dbo].[ccsp_RIACampsManualCall]
			END'
	EXEC(@sql)

	SET @process = 'DEV2-216-CREATE ccsp_RIACampsManualCall'
    SET @sql = '-- Se crearon las variables @IdArea y @DialogMode, se llenaron respectivamente
			-- Se hicieron dos validaciones en la línea 32
			-- una para evitar que solo se contemplen las llamadas manuales en el select
			-- otra para que cuando el agente está en modo campañas preview, se muestren las campañas de tipo preview

			CREATE PROCEDURE [dbo].[ccsp_RIACampsManualCall]
			@option int,
			@UserID int = 0,
			@onChat int = 0,
			@campId int = 0
			AS
			set nocount on

			if(@option = 1)
			begin
				if (@onChat = 0)
				begin
					declare @mod smallint
					declare @IdArea smallint
					declare @DialingMode tinyint

					select @IdArea = IDArea, @DialingMode = DialingMode from ccUsers where User_id = @UserID

					select @mod = defCampaing from ccRIACat_Areas A
					where A.IDArea = @IdArea 

					select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [isDefault],  g.graphic_id, c.cam_ModoManual, 
					isnull(c.selectRotativeANI, 0) selectRotativeANI
					, isnull(c.CampType,0) as CampType,
					CASE WHEN @DialingMode = 1 THEN (select count(1) from ccoWorkingTable nolock where cam_id = c.cam_id) ELSE 0 END AS countJobs,
					isnull(c.timesPreview, 0) timesPreview
					from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
					join ccRIACampsGraph g ON g.cam_id = c.cam_id
					where ca.user_id = @UserID and cam_ModoManual = case when @DialingMode = 1 OR (@DialingMode = 0 AND cam_ModoManual in (1,3)) then cam_ModoManual else -1 end AND CampType = CASE WHEN @DialingMode = 1 THEN 6 ELSE CampType END
					order by cam_descripcion
				end
				else 
				begin 
					select distinct c.cam_id, c.cam_descripcion,  g.graphic_id,  c.cam_ModoManual
					, isnull(c.CampType,0) as CampType
					from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id

					join ccRIACampsGraph g ON g.cam_id = c.cam_id
					where ca.user_id = @UserID and manualCallOnChat = 1
					order by cam_descripcion
					SET NOCOUNT OFF;
				end
			end

			if(@option = 2)
			begin
				declare @aniList int 
				declare @rotativeAniListId int
				select @aniList = id_anilist, @rotativeAniListId  = rotativeAlgo from ccCamps where cam_id = @campId

				if @rotativeAniListId >0 begin
					select telAni from ccRotativeANIListDetail where id_RAniList = @aniList
				end
				else begin
					select top 0 '''' telAni 
				end					
			end'
	EXEC(@sql)

	SET @process = 'DEV2-223-Init AllowSelectCamp'
    SET @sql = 'UPDATE ccusers SET AllowSelectCamp=0 WHERE AllowSelectCamp IS NULL'
	EXEC(@sql)

	SET @process = 'DEV2-223-Check default constraint AllowSelectCamp'
    SET @sql = 'IF EXISTS(SELECT 
			OBJECT_NAME(OBJECT_ID) AS NameofConstraint
				,SCHEMA_NAME(schema_id) AS SchemaName
				,OBJECT_NAME(parent_object_id) AS TableName
				,type_desc AS ConstraintType
			FROM sys.objects
			WHERE type_desc LIKE ''%CONSTRAINT''
				AND OBJECT_NAME(OBJECT_ID)=''DF_ccUsers_AllowSelectCamp'')
		BEGIN
			ALTER TABLE ccusers DROP DF_ccUsers_AllowSelectCamp
		END'
	EXEC(@sql)

	SET @process = 'DEV2-223-Create default constraint AllowSelectCamp'
    SET @sql = 'ALTER TABLE ccusers ADD CONSTRAINT DF_ccUsers_AllowSelectCamp DEFAULT 0 FOR AllowSelectCamp;'
	EXEC(@sql)

	SET @process = 'DEV2-223-Drop function GetHourLaw'
    SET @sql = 'If EXISTS (select * from sysobjects where name = ''GetHourLaw'')
		begin
			drop function dbo.GetHourLaw
		end'
	EXEC(@sql)

	SET @process = 'DEV2-223-Create function GetHourLaw'
    SET @sql = 'CREATE FUNCTION GetHourLaw ()
		returns @t TABLE (hourStart tinyint, minStart tinyint, hourEnd tinyint, minEnd tinyint)  AS
		begin
			DECLARE @isShudulerLey BIT
			DECLARE @valueShudulerLey VARCHAR(max), @hourStart INT, @hourEnd INT, @minStart INT, @minEnd INT
			DECLARE @shourStart VARCHAR(max), @shourEnd VARCHAR(max)

			SELECT @valueShudulerLey = valor
			FROM ccsettings
			WHERE setting_id = 166

			SELECT @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex(''|'', @valueShudulerLey)) AS INT), @valueShudulerLey = substring(
					@valueShudulerLey, charindex(''|'', @valueShudulerLey) + 1, len(@valueShudulerLey))

			IF @valueShudulerLey = ''''
			BEGIN
				SET @valueShudulerLey = ''0|07:00|22:00''
			END

			IF @isShudulerLey = 1
			BEGIN
				SELECT @shourStart = substring(@valueShudulerLey, 0, charindex(''|'', @valueShudulerLey)), 
				@shourEnd = substring(@valueShudulerLey, charindex(''|'', 
							@valueShudulerLey) + 1, len(@valueShudulerLey))

				SELECT @hourStart = substring(@shourStart, 0, charindex('':'', @shourStart)), 
				@minStart = substring(@shourStart, charindex('':'', @shourStart) + 1, len(
							@shourStart))

				SELECT @hourEnd = substring(@shourEnd, 0, charindex('':'', @shourEnd)), 
				@minEnd = substring(@shourEnd, charindex('':'', @shourEnd) + 1, len(@shourEnd))
			END
			ELSE
			BEGIN
				SELECT @hourStart = 0, @minStart = 0, @hourEnd = 23, @minEnd = 59
			END

			INSERT @t
			SELECT @hourStart as hourStart, @minStart as minStart, @hourEnd as hourEnd, @minEnd minEnd

			return
		end'
	EXEC(@sql)

	SET @process = 'DEV2-216-Drop SP ccsp_OUTcheckTimeZone'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_OUTcheckTimeZone'')
			BEGIN
				DROP PROCEDURE [dbo].[ccsp_OUTcheckTimeZone]
			END'
	EXEC(@sql)

	SET @process = 'DEV2-216-Create SP ccsp_OUTcheckTimeZone'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_OUTcheckTimeZone] @cam_id AS INT,@isReturnSelect bit=1
			AS
			SET NOCOUNT ON

			DECLARE @horaUniversal DATETIME, @revHorario BIT, @isShudulerLey BIT, @dateNow DATETIME
			DECLARE @hourStart INT, @hourEnd INT, @minStart INT, @minEnd INT
			DECLARE @timeMaxContestacion INT, @campType INT;

			SET @timeMaxContestacion = 60

			SELECT @revHorario = valor
			FROM ccsettings
			WHERE setting_id = 112

			SELECT @timeMaxContestacion = (cam_tNoContesta * 2)
			FROM cccamps
			WHERE cam_id = @cam_id

			SET @timeMaxContestacion = CEILING(cast(@timeMaxContestacion AS DECIMAL(10, 2)) / cast(60 AS DECIMAL(10, 2)))

			SELECT @hourStart = hourStart, @minStart = minStart, @hourEnd = hourEnd, @minEnd = minEnd from dbo.GetHourLaw()

			SELECT @campType = CampType
			FROM ccCamps
			WHERE cam_id = @cam_id;

			SET DATEFIRST 1
			SET @horaUniversal = getutcdate()
			SET @dateNow = getdate()
			declare @iZonas int
			-- Si la campaña no tiene horarios asignados, marcar todas las zonas
			IF @revHorario = 0
			BEGIN
				IF NOT EXISTS (
						SELECT cam_id
						FROM ccCampsHorarios WITH (INDEX (IX_ccCampsHorarios))
						WHERE cam_id = @cam_id
						)
				BEGIN
					SELECT @iZonas=sum(DISTINCT tz_id)
					FROM (
						SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha, 
						datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora, 
						datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto, 
						datepart(dw, dateadd(mi, tz_offset * 60, @horaUniversal)) AS dia
						FROM ccTimeZones
						) zonas
					WHERE (
							hora > @hourStart OR ( hora = @hourStart AND minuto >= @minStart)
							)
						AND (
							hora < @hourEnd OR ( hora = @hourEnd AND minuto <= @minEnd)
							)

				if @isReturnSelect=1 begin
					select @iZonas as iZonas
				end
				return @iZonas
				END
			END

			IF @campType <> 7
			BEGIN
	
				WITH sch
					AS (
						SELECT HoraInicio, MinInicio, HoraFin, MinFin, Lunes, Martes, Miercoles, Jueves, Viernes, Sabado, Domingo
						FROM cchorarios h
						INNER JOIN ccCampsHorarios WITH (INDEX (IX_ccCampsHorarios)) ON h.horario_id = ccCampsHorarios.horario_id
						AND ccCampsHorarios.cam_id = @cam_id
						), daysch
					AS (
						SELECT CASE WHEN HoraInicio > @hourStart THEN HoraInicio ELSE @hourStart END HoraInicio
						, CASE WHEN (horaInicio > @hourStart OR (horaInicio = @hourStart AND MinInicio >= @minStart	)
										) THEN MinInicio ELSE @minStart END MinInicio
						, CASE WHEN horaFin < @hourEnd THEN horaFin ELSE @hourEnd END HoraFin
						, CASE WHEN ((	horaFin < @hourEnd OR (	horaFin = @hourEnd AND MinFin <= @minEnd))
										) THEN MinFin ELSE @minEnd END MinFin, Lunes, Martes, Miercoles, Jueves, Viernes, Sabado, Domingo
						FROM sch
						), zonas
					AS (
						SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha
						, datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora
						, datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto
						, datepart(dw, dateadd(mi, tz_offset * 60, @horaUniversal)) AS dia
						FROM ccTimeZones
						)
					SELECT @iZonas=isnull(sum(DISTINCT B.tz_id), 0)
					FROM daysch A
					INNER JOIN zonas B ON (
							hora > HoraInicio OR ( hora = HoraInicio AND minuto >= MinInicio)
							)
						AND (
							hora < HoraFin OR (hora = HoraFin AND minuto <= (MinFin - @timeMaxContestacion))
							)
						AND (
							Lunes = dia
							OR Martes * 2 = dia
							OR Miercoles * 3 = dia
							OR Jueves * 4 = dia
							OR Viernes * 5 = dia
							OR Sabado * 6 = dia
							OR domingo * 7 = dia
							)

				if @isReturnSelect=1 begin
					select @iZonas as iZonas
				end
				return @iZonas
			END
			ELSE
			BEGIN
					;

				WITH sch
				AS (
					SELECT DATEPART(hh, idate) AS HoraInicio, DATEPART(mi, iDate) AS MinInicio, 
					DATEPART(hh, fdate) HoraFin, DATEPART(mi, fdate) MinFin
					FROM ccSmsSchedules
					WHERE cam_id = @cam_id
						AND @dateNow BETWEEN iDate AND fDate
					), daysch
				AS (
					SELECT CASE WHEN HoraInicio > @hourStart THEN HoraInicio ELSE @hourStart END HoraInicio
					, CASE WHEN (horaInicio > @hourStart OR (horaInicio = @hourStart AND MinInicio >= @minStart	)
									) THEN MinInicio ELSE @minStart END MinInicio
					, CASE WHEN horaFin < @hourEnd THEN horaFin ELSE @hourEnd END HoraFin
					, CASE WHEN ((	horaFin < @hourEnd OR (	horaFin = @hourEnd AND MinFin <= @minEnd))
									) THEN MinFin ELSE @minEnd END MinFin
					FROM sch
					), zonas
				AS (
					SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha
					, datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora
					, datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto
					FROM ccTimeZones
					)
				SELECT @iZonas=isnull(sum(DISTINCT B.tz_id), 0)
				FROM daysch A
				INNER JOIN zonas B ON (
						hora > HoraInicio OR ( hora = HoraInicio AND minuto >= MinInicio)
						)
					AND (
						hora < HoraFin OR (hora = HoraFin AND minuto <= (MinFin - @timeMaxContestacion))
						)

				if @isReturnSelect=1 begin
					select @iZonas as iZonas
				end
				return @iZonas
			END'
	EXEC(@sql)
	---------------------------------------------------------------------END HL-----------------------------------------------------------------------------------------

	---------------------------------------BEGIN Enrique Ruiz---------------------------------------------------------

	SET @process = 'fix/TT6327 CW-TT6327 ALTER SP ccsp_RIAUpdateCamConfig no actualizar cam_ShowCalifWnd y terminar si no tiene calificaciones asignadas, de lo contrario actualiza con normalidad'
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
	@cam_id smallint,
	@cam_descripcion varchar(40) = null,
	@cam_tnotas smallint = null,
	@cam_ocupado tinyint = null,
	@cam_NoInt_ocupado tinyint = null,
	@cam_inter_ocupado smallint = null,
	@cam_nocontesto tinyint = null,
	@cam_NoInt_nocontesto tinyint = null,
	@cam_inter_nocontesto smallint = null,
	@cam_fax tinyint = null,
	@cam_NoInt_fax tinyint = null,
	@cam_inter_fax smallint = null,
	@cam_ModoManual tinyint= null,
	@ANI varchar(15) = null,
	@cam_ShowCalifWnd bit = null,
	@cam_StartTimerOnHangUp bit = null,
	@editableCallKey bit = null,
	@cam_tNoContesta tinyint = null,
	@cam_intensive_dialing tinyint = null,
	@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
	@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
	@compliance TinyInt = null,
	@cam_inter_graba smallint = null,
	@cam_NoInt_graba tinyint = null,
	@progDial smallint = null,
	@excCallBack Tinyint = null,
	@dialOrder Tinyint = null,
	@dialPrefix varchar(10) = null,
	@dialPrefixMan varchar(10) = null,
	@dialPrefixXfe varchar(10) = null,
	@listenManualCall bit = null,
	@stopRecording bit = null,
	@abandonCallback bit = null,
	@autoCB smallint = null,
	@id_listAni int = null,
	@tDialonWrapUp smallint = null,
	@quesize smallint=null,
	@DNCScrub int=null,
	@callerIdDesc varchar(15)=null,
	@timeZoneRule int=null,
	@callsBySurvey int=null,
	@ivrScript int=null,
	@surveyPctg int=null,
	@call_record tinyint=null,
	@dRestrictPlay bit = null,
	@leaveRecMessage bit = null,
	@manualCallOnChat bit = null,
	@callBackSurveyClient bit = null,
	@callBackSurveyAgent bit = null,
	@funcEspDtmf int =null,
	@sipHdrsCfg varchar(255) = null,
	@cam_inter_cancelled smallint = null,
	@prefijo varchar(max) = null,
	@exitAssisted bit = null,
	@previewDiscard bit = null,
	@rotativeAlgo tinyint = null,
	@timesPreview tinyint = null,
	@cam_tPreview smallint = null,
	@timesDiscard tinyint = null,
	@CampType int = null,
	@agentCloseConversationTime SMALLINT = NULL,
	@adminCloseConversationTime INT = NULL,
	@ConexionInfo VARCHAR(400) = NULL,
	@allowFileAttachments BIT = NULL,
	@selectRotativeANI int = null,
	@messagingOrder bit = null,
	@autoStart bit = null,
	@recordHold bit = null,
	@userId                SMALLINT     = NULL, 
	@idArea                SMALLINT     = NULL, 
	@isCreating            SMALLINT          = NULL,
	@module INT = -1
	as
	set nocount on
	DECLARE @timesDiscardActual int = (SELECT timesDiscard FROM ccCamps WHERE cam_id = @cam_id)
	DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
		DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
		EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

	UPDATE ccCamps SET
	cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
	cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
	cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
	cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
	cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
	cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
	cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
	cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
	cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
	cam_fax = isnull(@cam_fax,cam_fax),
	cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
	cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
	cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
	ANI = isnull(@ANI,ANI),
	cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
	editableCallKey = isnull(@editableCallKey, editableCallKey),
	cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
	iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
	detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
	detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
	compliance = isnull(@compliance, compliance),
	cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
	cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
	cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
	progDial = isnull(@progDial, progDial),
	excCallBack = isnull(@excCallBack,excCallBack),
	dialOrder = isnull(@dialOrder, dialOrder),
	dialPrefix = isnull(@dialPrefix, dialPrefix),
	dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
	dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
	listenManualCall = isnull(@listenManualCall, listenManualCall),
	stopRecording = isnull(@stopRecording, stopRecording),
	abandonCallback = isnull(@abandonCallback, abandonCallback),
	t_autoCB = isnull(@autoCB,t_autoCB),
	id_anilist = isnull(@id_listAni,id_anilist),
	tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
	cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
	cam_maxqueue = isnull(@quesize,cam_maxqueue),
	DNCScrub = isnull(@DNCScrub,DNCScrub),
	callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
	timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
	callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
	ivrScript = isnull(@ivrScript,ivrScript),
	surveyPctg = isnull(@surveyPctg,surveyPctg),
	call_record = isnull(@call_record,call_record),
	startStopRecording = isnull(@dRestrictPlay, startStopRecording),
	leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
	manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
	callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
	callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
	funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
	sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
	prefijo = isnull(@prefijo, prefijo),
	exitAssisted = isnull(@exitAssisted, exitAssisted),
	previewDiscard = isnull(@previewDiscard, previewDiscard),
	rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo),
	timesPreview = isnull(@timesPreview, timesPreview),
	cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
	timesDiscard = isnull(@timesDiscard, timesDiscard),
	CampType = (CASE  WHEN @CampType is not null THEN @CampType WHEN @progDial = 2 THEN 6 WHEN @progDial IS NOT NULL AND @progDial <> 2 THEN 0 WHEN CampType is not null THEN CampType ELSE 0 END),
	selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
	messagingOrder = isnull(@messagingorder, messagingOrder),
	autoStart = isnull(@autoStart,autoStart),
	recordHold = isnull(@recordHold, recordHold)

	Where cam_id = @cam_id

			IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

			Create table #ccCampsTable 
			(
				columnInfo VARCHAR(255),
				dataInfo VARCHAR(255),
				identifierInfo VARCHAR(255)
			)

			DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
																		CASE 
																			WHEN @Camptype = 6  THEN 44
																			WHEN @Camptype = 5  THEN 46
																			WHEN @Camptype = 4  THEN 48
																			WHEN @Camptype = 7  THEN 50
																			ELSE 42 END
																	ELSE 
																		CASE 
																			WHEN @Camptype = 6  THEN 55
																			WHEN @Camptype = 5  THEN 56
																			WHEN @Camptype = 4  THEN 57
																			WHEN @Camptype = 7  THEN 58
																			ELSE 54 END
																	END;
		
			IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

			IF(@isCreating = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
			
			DELETE FROM #ccCampsTable WHERE columnInfo IN (''startStopRecording'');
			DELETE FROM #ccCampsTable WHERE dataInfo = '''''''';
			
			IF(@CampType = 6) DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'', ''cam_fDialOnWU'', ''ProgDial'');
			ELSE IF(@CampType = 5 AND @isCreating = 2) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'', ''cam_descripcion'', ''exitAssisted'');
			ELSE IF(@CampType = 5) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'');
			ELSE IF(@CampType = 7) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''messagingOrder'', ''autoStart'', ''rotativeAlgo'', ''id_anilist'', ''cam_descripcion'');
			ELSE DELETE FROM #ccCampsTable WHERE columnInfo IN (''previewDiscard'', ''CampType'', ''cam_fDialOnWU'', ''ProgDial'');

			IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			SELECT 
				(SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
				getDate(), 
				(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				@operation, 
				@module,
				CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
					THEN
						CASE
							WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
								CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
							WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN 
								CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
							WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
								CASE WHEN @Camptype = 5 THEN ''OUT_MANUAL_DIALING_WHATS'' ELSE CCCT.identifierInfo END
							ELSE
								CCCT.identifierInfo
							END
					ELSE
					''''
					END,
				CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
					CASE 
						WHEN CCCT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
							CASE WHEN CCCT.dataInfo = ''VOICEMAIL'' 
								THEN ''COMMON_VOICE_MAIL'' 
								ELSE 
									CASE WHEN CCCT.dataInfo IS NOT NULL THEN CCCT.dataInfo ELSE ''T&COMMON_NONE'' END 
								END
						WHEN CCCT.identifierInfo = ''OUT_DIALING_ORDER'' THEN 
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_DESCENDING'' ELSE ''COMMON_ASCENDING'' END

						WHEN CCCT.identifierInfo = ''OUT_SMS_MESSAGING_ORDER'' THEN 
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ASCENDING'' ELSE ''COMMON_DESCENDING'' END

						WHEN CCCT.identifierInfo = ''OUT_ANSWER_MACHINE_DETC'' THEN 
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_BASIC'' 
								WHEN CCCT.dataInfo = 1 THEN ''COMMON_LIGHT''
								WHEN CCCT.dataInfo = 2 THEN ''COMMON_MODERATE''
								WHEN CCCT.dataInfo = 3 THEN ''COMMON_HIGH''
								ELSE ''T&COMMON_NONE'' END

						WHEN CCCT.identifierInfo = ''OUT_ANI_MODE'' THEN 
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ANI_LOCAL'' 
								WHEN CCCT.dataInfo = 1 THEN ''COMMON_ANI_ROTATIVE''
								WHEN CCCT.dataInfo = 2 THEN ''COMMON_ANI_ROTATIVE_REG''
								WHEN CCCT.dataInfo = 3 THEN ''COMMON_ANI_ROTATIVE_SMART''
								ELSE ''T&COMMON_NONE'' END

						WHEN CCCT.identifierInfo = ''OUT_DIALING_MODE'' THEN 
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_PREDICTIVE'' 
								WHEN CCCT.dataInfo = 1 THEN ''COMMON_PROGRESIVE''
								ELSE ''COMMON_ASSISTED'' END

						WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
							CASE WHEN  @CampType = 5 THEN 
								CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
							ELSE
								CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_VIA_KEYPAD_LOG''
									WHEN CCCT.dataInfo = 2 THEN ''COMMON_VIA_CALLS_LOG''
									WHEN CCCT.dataInfo = 3 THEN ''COMMON_VIA_CALLS_LOG''
									ELSE ''T&COMMON_NONE'' END
							END

						WHEN CCCT.identifierInfo = ''OUT_ANI_LIST'' THEN
									ISNULL((SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo), CCCT.dataInfo)

						WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
						WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
													''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
													''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'') THEN
							CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
						
						ELSE CCCT.dataInfo END
				ELSE '''' END, 
				CASE WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
			FROM #ccCampsTable AS CCCT;

			EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
			IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

	if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
	begin
		EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
	end

	IF (@CampType IS NOT NULL AND @CampType IN (3, 5))
	BEGIN
		IF NOT EXISTS(SELECT camp_id FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id)
		BEGIN
			SELECT 0
			RETURN(0)
		END

		IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

		Create table #contactMeanOutTable 
		(
			columnInfo VARCHAR(255),
			dataInfo VARCHAR(255),
			identifierInfo VARCHAR(255)
		)

		EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @cam_id, @userId= @userid

		DECLARE @PrevConexionInfo VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id);

		set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then CASE WHEN @isCreating > 0 AND @PrevConexionInfo <> '''' THEN ''Ninguno'' ELSE '''' END else @ConexionInfo end
		UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
												closeConversationTime = CAST(@agentCloseConversationTime AS INT), answerTimeoutClient = @adminCloseConversationTime,
								allowFileAttachments = @allowFileAttachments
		WHERE @CampType = meanContactTypeId AND camp_id = @cam_id

		
		IF(@isCreating > 0 AND @module > -1) BEGIN 
			EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';
			IF(@ConexionInfo IS NULL OR @ConexionInfo IN ('''',''0'',''None'',''Ninguno'') AND @PrevConexionInfo <> @ConexionInfo) UPDATE contactMeanOut SET conexionInfo = '''' WHERE @CampType = meanContactTypeId AND camp_id = @cam_id
		END

		DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''conexionInfo'') AND  dataInfo = '''''''';
		DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''ConnPass'', ''connUser'') ;

		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		SELECT 
			(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
			getDate(), 
			(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
			@operation, 
			@module, 
			CMOT.identifierInfo,
			CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
				CASE
					WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
						CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
					WHEN CMOT.identifierInfo = ''OUT_WHATS_ASSOCIATED_PHONE'' THEN
						CASE WHEN CMOT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMOT.dataInfo END
					ELSE CMOT.dataInfo END
			ELSE '''' END, 
			(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
		FROM #contactMeanOutTable AS CMOT;

		EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid;
		IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

		IF @CampType = 5 BEGIN
			update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
			IF(@ConexionInfo <> '''')
			BEGIN 
				UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
			END
		END
	END 
	DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

	IF @cam_ShowCalifWnd = 1
	BEGIN
		IF NOT EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @cam_id and tipo = 1)
		BEGIN
			SELECT 0
			RETURN(0)
		END

		UPDATE ccCamps SET
		cam_ShowCalifWnd = ISNULL(@cam_ShowCalifWnd,cam_ShowCalifWnd)
		WHERE cam_id = @cam_id


		IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
			INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			SELECT 
				(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
				getDate(), 
				(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				@operation, 
				3, 
				''OUT_SHOW_DISPOSITIONS'',
				CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
				(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
		END

		SELECT 1
		RETURN(0)
	END

	UPDATE ccCamps SET
	cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
	where cam_id = @cam_id

	IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		SELECT 
			(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
			getDate(), 
			(SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
			@operation, 
			3, 
			''OUT_SHOW_DISPOSITIONS'',
			CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
			(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
	END

	SELECT 2
	RETURN(0)

	set nocount off'
	EXEC(@sql)
	---------------------------------------END Enrique Ruiz-----------------------------------------------------------
	
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