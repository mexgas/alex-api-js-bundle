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
SET @versionfix = 18
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
-------------------------------------------- BEGIN MARCO GARCIA DEV3-345 proceso para guardar los registros nuevos en la tabla smsWorkingTable------------------------------

SET @process = 'K042008-Carga BD SMS-Generar plantilla delete index IX_smsOutSource_1 in smsOutSource';
SET @sql = 'IF EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_smsOutSource_1'' AND object_id = OBJECT_ID(''smsOutSource''))
		BEGIN
			DROP INDEX IX_smsOutSource_1 ON dbo.smsOutSource
		END';
EXEC (@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla delete create IX_smsOutSource_1 in smsOutSource';
SET @sql = 'CREATE NONCLUSTERED INDEX [IX_smsOutSource_1] ON [dbo].[smsOutSource]
			(
				[cam_id] ASC,
				[sms_status] ASC
			)';
EXEC (@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla delete index IX_smsOutSource_2 in smsOutSource';
SET @sql = 'IF EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_smsOutSource_2'' AND object_id = OBJECT_ID(''smsOutSource''))
		BEGIN
			DROP INDEX IX_smsOutSource_2 ON dbo.smsOutSource
		END';
EXEC (@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla delete create IX_smsOutSource_2 in smsOutSource';
SET @sql = 'CREATE NONCLUSTERED INDEX [IX_smsOutSource_2] ON [dbo].[smsOutSource]
			(
				[callkey] ASC,
				[cam_id] ASC,
				[sms_status] ASC
			)';
EXEC (@sql);


SET @process = 'K042008-Carga BD SMS-Generar plantilla delete index IX_smsWorkingTable_1 in smsWorkingTable';
SET @sql = 'IF EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_smsWorkingTable_1'' AND object_id = OBJECT_ID(''smsWorkingTable''))
		BEGIN
			DROP INDEX IX_smsWorkingTable_1 ON dbo.smsWorkingTable
		END';
EXEC (@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla delete create IX_smsWorkingTable_1 in smsWorkingTable';
SET @sql = 'CREATE NONCLUSTERED INDEX [IX_smsWorkingTable_1] ON [dbo].[smsWorkingTable]
			(
				[cam_id] ASC
			)';
EXEC (@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla delete index IX_smsWorkingTable_2 in smsWorkingTable';
SET @sql = 'IF EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_smsWorkingTable_2'' AND object_id = OBJECT_ID(''smsWorkingTable''))
		BEGIN
			DROP INDEX IX_smsWorkingTable_2 ON dbo.smsWorkingTable
		END';
EXEC (@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla delete create IX_smsWorkingTable_2] in smsWorkingTable';
SET @sql = 'CREATE NONCLUSTERED INDEX [IX_smsWorkingTable_2] ON [dbo].[smsWorkingTable]
			(
				[cal_keyw] ASC,
				[cam_id] ASC,
				[sms_status] ASC
			)';
EXEC (@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla delete store procedure [ccsp_OUTGetNewJobs]'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_OUTGetNewJobs'')
		BEGIN
			DROP PROCEDURE ccsp_OUTGetNewJobs
		END'
EXEC(@sql)

SET @process = 'K042008-Carga BD SMS-Generar plantilla  create store procedure [ccsp_OUTGetNewJobs]';
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
		declare @camSurvey INT, @campType INT;
		select @camSurvey = 0
		DECLARE @iZonasTable TABLE (value int)

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
						isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
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
						isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
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

		return(0)'
EXEC (@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla delete store procedure [ccsp_GalateaGetCampsNvosCB]'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaGetCampsNvosCB'')
		BEGIN
			DROP PROCEDURE ccsp_GalateaGetCampsNvosCB
		END'
EXEC(@sql)

SET @process = 'K042008-Carga BD SMS-Generar plantilla  create store procedure [ccsp_GalateaGetCampsNvosCB]';
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0, @tcpa int=0
as
set nocount on

declare @TipoJobs as int, @isExecOutbound bit

set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

	declare @id AS INTEGER, @campType INT;

	CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
	CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime)

	create table #tempoutsource (cam_id int,Pend  int)

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

	SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @cam_id;


	if (select count(*) from #Tcamps2)>0 BEGIN

			insert into #tempoutsource(cam_id,Pend)
			SELECT sos.cam_id, count(sos.cam_id) as Pend
			FROM dbo.smsOutSource AS sos  with(index(IX_smsOutSource_1),nolock)
			join #Tcamps2 tcam on sos.cam_id = tcam.cam_id
			WHERE sos.sms_status in(0, 7)
			GROUP BY sos.cam_id

			insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
			SELECT swt.cam_id,
			count(case swt.sms_status when 0 then 1 else null end) as New,
			count(case swt.sms_status when 1 then 1 else null end) as Cb,
			count(case swt.sms_status when 2 then 1 else null end) as Pro,
			count(case swt.sms_status when 3 then 1 else null end) as Fin
			FROM dbo.smsWorkingTable AS swt  with(index(IX_smsWorkingTable_1),nolock)
			join #Tcamps2 B on swt.cam_id = B.cam_id
			GROUP BY swt.cam_id	

			insert into #tempoutsource(cam_id,Pend)
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
		--END
		
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
			LEFT JOIN #tempoutsource cs on cams.cam_id = cs.cam_id
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
	drop table #tempoutsource
	drop table #temWorkinTable

	return(0)

end

set nocount off'
EXEC (@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla delete store procedure [ccsp_RIAOUTInsertNewJOBS_WT_Camp]'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIAOUTInsertNewJOBS_WT_Camp'')
		BEGIN
			DROP PROCEDURE ccsp_RIAOUTInsertNewJOBS_WT_Camp
		END'
EXEC(@sql)

SET @process = 'K042008-Carga BD SMS-Generar plantilla  create store procedure [ccsp_RIAOUTInsertNewJOBS_WT_Camp]';
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000
	AS
	SET NOCOUNT ON

	DECLARE @prioridad VARCHAR(8)
	DECLARE @batchsizeIni AS INT
	DECLARE @batchsizeFin AS INT
	DECLARE @rango AS DECIMAL
	DECLARE @rowstoInsert AS INT
	DECLARE @campType AS INT
   

	SET @rowstoInsert = 0
	SET @batchsizeIni = 0
	SET @batchsizeFin = 0
	SET @rango = 0.00

	IF @top < 3000
		BEGIN
			SET @top = 3000
		END

	SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
	FROM ccCampsPrioridadTel WITH (NOLOCK)
	WHERE cam_id = @camp_id

	SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @camp_id;

	DELETE ccUploadTemporal
	WHERE cam_id = @camp_id

	IF(@campType = 7)
	BEGIN
			CREATE TABLE #tempsmsOutSource (Id INT PRIMARY KEY identity, smsout_id INT, cam_id INT, sms_phoneNumber VARCHAR(19), sms_status TINYINT, sms_dateDial DATETIME, cal_keyw VARCHAR(40), iTimeZone INT, iTimeZone_summer INT, iTimeZone2 INT, iTimeZone_summer2 INT, iTimeZone3 INT, iTimeZone_summer3 INT, iTimeZone4 INT, iTimeZone_summer4 INT, iTimeZone5 INT, iTimeZone_summer5 INT, list_id INT)

			CREATE NONCLUSTERED INDEX [IX_TempSMSO] ON [dbo].[#tempsmsOutSource] ([Id] ASC)
				WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

			CREATE TABLE #smsoutIdSource (smsout_id INT NOT NULL PRIMARY KEY)

			CREATE TABLE #smsoutIdSource2 (smsout_id INT NOT NULL PRIMARY KEY)

			INSERT INTO #smsoutIdSource
			SELECT top(@top) sos.smsout_id
			FROM dbo.smsOutSource AS sos  WITH (INDEX (IX_smsOutSource_2), NOLOCK)
			inner join dbo.smsWorkingTable AS swt WITH (INDEX (IX_smsWorkingTable_2), NOLOCK) 
			on sos.callkey = swt.cal_keyw AND sos.cam_id = swt.cam_id 
			WHERE sos.cam_id = @camp_id and sos.sms_status IN (0, 7) AND swt.sms_status <= 2

			UNION

			SELECT top(@top) swt2.smsout_id
			FROM dbo.smsOutSource AS sos2 WITH (INDEX (IX_smsOutSource_2), NOLOCK)
			inner join dbo.smsWorkingTable AS swt2 (NOLOCK)on sos2.smsout_id = swt2.smsout_id 
			WHERE sos2.cam_id = @camp_id AND (sos2.sms_status < 2 OR sos2.sms_status = 7)

			INSERT INTO #smsoutIdSource2
			SELECT top(@top) sos.smsout_id
			FROM dbo.smsOutSource AS sos WITH (INDEX (IX_smsOutSource_1), NOLOCK)
			WHERE sos.sms_status IN (0, 1, 7) AND cam_id = @camp_id

			INSERT #tempsmsOutSource(smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, cal_keyw, iTimeZone, 
			iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4,
			 iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id)
			SELECT TOP(@top) smsout_id, cam_id, RTRIM(LEFT(LTRIM(sms_phoneNumber + ''        '' + sms_phoneNumber2 + ''         '' 
			+ sms_phoneNumber3 + ''         '' + sms_phoneNumber4 + ''         '' + sms_phoneNumber5 + ''         ''), 13)) AS sms_phoneNumber,
			 CASE sms_status WHEN 7 THEN 1 ELSE sms_status END sms_status, sms_dateDial, callkey, 
			 CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone ELSE NULL END iTimeZone,
			  CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone_summer ELSE NULL END iTimeZone_summer, 
			  CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone2 ELSE NULL END iTimeZone2,
			   CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone_summer2 ELSE NULL END iTimeZone_summer2, 
			   CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone3 ELSE NULL END iTimeZone3, 
			   CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone_summer3 ELSE NULL END iTimeZone_summer3,
				CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone4 ELSE NULL END iTimeZone4, 
				CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone_summer4 ELSE NULL END iTimeZone_summer4, 
				CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone5 ELSE NULL END iTimeZone5, 
				CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone_summer5 ELSE 
						NULL END iTimeZone_summer5, list_id
			FROM dbo.smsOutSource  WITH (INDEX (IX_smsOutSource_1), NOLOCK)
			WHERE cam_id = @camp_id AND (sms_status < 2 OR sms_status = 7) 

			SELECT @rowstoInsert = COUNT(*) FROM #tempsmsOutSource AS tos;

			
			IF EXISTS(SELECT * FROM #tempsmsOutSource)
			BEGIN
				SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
				FROM #tempsmsOutSource  WITH (NOLOCK)

				SET @batchsizeFin = @batchsizeFin + @rango

				WHILE 1 = 1
				BEGIN
					-- Nuevos Jobs
					INSERT INTO dbo.smsWorkingTable
					WITH (TABLOCKX) (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id)
					SELECT smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, 0, 0 ,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id
					FROM #tempsmsOutSource 
					WHERE id > @batchsizeIni AND id <= @batchsizeFin

					IF @batchsizeFin > @rowstoInsert
						BREAK
					ELSE
					BEGIN
						SET @batchsizeIni = @batchsizeIni + @rango
						SET @batchsizeFin = @batchsizeFin + @rango
					END
				END

				UPDATE dbo.smsOutSource
				SET sms_status = 2
				FROM dbo.smsOutSource AS sos WITH (NOLOCK), #smsoutIdSource2  cis3 WITH (NOLOCK)
				WHERE sos.smsout_id = cis3.smsout_id
			END

			DROP TABLE #smsoutIdSource

			DROP TABLE #smsoutIdSource2

			DROP TABLE #tempsmsOutSource
	END
	ELSE
	BEGIN
			CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT)

			CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
				WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

			CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

			CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

			INSERT INTO #calloutIdSource
			SELECT top(@top) cs.callout_id
			FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_15), NOLOCK)
			inner join ccoWorkingTable wt WITH (INDEX (IX_ccoWorkingTable_15), NOLOCK) 
			on cs.callout_id = wt.callout_id AND cs.cam_id = wt.cam_id 
			WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

			UNION

			SELECT top(@top) Cout.callout_id
			FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
			inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id 
			WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)
	

			INSERT INTO #calloutIdSource2
			SELECT top(@top) callout_id
			FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
			WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

			IF exists(SELECT * FROM #calloutIdSource) 
			BEGIN
				UPDATE ccoCallBacks
				SET [status] = 6, schedulerStatus = 1
				WHERE callout_id IN (
						SELECT callout_id
						FROM #calloutIdSource cis
						)

				UPDATE ccoCallsOutSource
				SET cal_Status = 4
				WHERE callout_id IN (
						SELECT callout_id
						FROM #calloutIdSource cis
						)
			END

			INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
			iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
			 iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
			SELECT TOP(@top) callout_id, cam_id, CASE WHEN ISNULL(recycleType, 1) = 0 THEN 
			CASE 
				WHEN recyclePhone = 1 THEN cal_telefono
				WHEN recyclePhone = 2 THEN cal_telefono2
				WHEN recyclePhone = 3 THEN cal_telefono3
				WHEN recyclePhone = 4 THEN cal_telefono4
				else cal_telefono5
			END
			ELSE rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         '' 
				+ cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13)) 
			END AS cal_telefono,
			 CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key, 
			 CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
			  CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
			  CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
			   CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
			   CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
			   CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
				CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
				CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
				CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
				CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE 
						NULL END iZonaHoraria_verano5, list_id
			FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
			WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7) /*AND CONVERT(VARCHAR(10),cal_fechaDial, 103) >= CONVERT(VARCHAR(10), GETDATE(), 103)*/

			SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

			IF EXISTS(SELECT * FROM #tempCallsOutSource)
			BEGIN
				SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
				FROM #tempCallsOutSource WITH (NOLOCK)

				SET @batchsizeFin = @batchsizeFin + @rango

				WHILE 1 = 1
				BEGIN
					-- Nuevos Jobs
					INSERT INTO ccoWorkingTable
					WITH (TABLOCKX) (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
					SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
					FROM #tempCallsOutSource
					WHERE id > @batchsizeIni AND id <= @batchsizeFin

					IF @batchsizeFin > @rowstoInsert
						BREAK
					ELSE
					BEGIN
						SET @batchsizeIni = @batchsizeIni + @rango
						SET @batchsizeFin = @batchsizeFin + @rango
					END
				END

				UPDATE ccoCallsOutSource
				SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
				FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
				WHERE co.callout_id = cis3.callout_id
			END

			DROP TABLE #calloutIdSource

			DROP TABLE #calloutIdSource2

			DROP TABLE #tempCallsOutSource
	END

	UPDATE ccCampsNvosCB
	SET dateUpdate = NULL
	WHERE id = @camp_id

	SET NOCOUNT OFF'
EXEC (@sql);
-------------------------------------------- END MARCO GARCIA DEV3-345 proceso para guardar los registros nuevos en la tabla smsWorkingTable------------------------------
SET @process = 'Insert into ccMenus menu_id 13000'
	SET @sql = '
	if not exists(select menu_id from ccMenus where menu_id = 13000)
			begin
			insert into ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF,release) values (13000,''SMS|SMS'',13000,''A'',12,3,'''',''d108a7f110b9d54d296cb729b6e11f92'')
			end'
	EXEC(@sql)

	SET @process = 'Insert into ccMenus menu_id 13010'
	SET @sql = '
	if not exists(select menu_id from ccMenus where menu_id = 13010)
			begin
			insert into ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF,release) values (13010,''Detalle de mensajes recibidos|Received Messages Detail'',13000,''B'',12,3,'''',''c52ae15116ddecd653ac7b2f660e4c46032ff614b634f1915e0f7f212a52943a83df5bf0619d99a3a303031a13230ee885b38c3701c2d075cf6f9099d22a0af8'')
			end'
	EXEC(@sql)

	SET @process = 'Insert into ccMenus menu_id 13020'
	SET @sql = '
	if not exists(select menu_id from ccMenus where menu_id = 13020)
			begin
			insert into ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF,release) values (13020,''Detalle de mensajes enviados|Sent Messages Detail'',13000,''B'',12,3,'''',''c52ae15116ddecd653ac7b2f660e4c4687844bcbc5259b1f9ad3fde279181a449ed8f11ad1596ecc4311c4471dff08146fcd2fb13f94e5c06032e70312406c2c'')
			end'
	EXEC(@sql)

	SET @process = 'Insert into ccMenuUser 13000'
	SET @sql = '
	if not exists(select * from ccMenuUser where id_Menu= 13000 and id_User=1)
	begin 
		insert into ccMenuUser (id_User,id_Menu,type)  values(1,13000,3)
	end'
	EXEC(@sql)

	SET @process = 'Insert into ccMenuUser 13010'
	SET @sql = '
	if not exists(select * from ccMenuUser where id_Menu= 13010 and id_User=1)
	begin 
		insert into ccMenuUser (id_User,id_Menu,type)  values(1,13010,3)
	end'
	EXEC(@sql)

	SET @process = 'Insert into ccMenuUser 13020'
	SET @sql = '
	if not exists(select * from ccMenuUser where id_Menu= 13020 and id_User=1)
	begin 
		insert into ccMenuUser (id_User,id_Menu,type)  values(1,13020,3)
	end'
	EXEC(@sql)


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


