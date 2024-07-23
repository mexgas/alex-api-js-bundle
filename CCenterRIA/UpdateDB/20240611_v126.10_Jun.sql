/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2024/07/04
Description: KR140000
Database: CCenterRia
Required version: 126.6
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
SET @versionfix = 10
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
    	
-------------------------------------------------- Begin Rod Salazar -----------------------------------------------------------------------------------

	--------------------------------------- alter table ------------------------------------------
SET @process = 'KR106000 se agrega columna CamCanceled en ccCamps'
SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''CamCanceled'' AND Object_ID = Object_ID(N''dbo.ccCamps''))
	BEGIN
		ALTER TABLE ccCamps ADD CamCanceled INT NULL;
	END'

EXEC(@sql)

SET @process = 'KR106000 se agrega columna CancelAttempts en ccoworkingTable'
SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''CancelAttempts'' AND Object_ID = Object_ID(N''dbo.ccoworkingTable''))
	BEGIN
		ALTER TABLE ccoworkingTable ADD CancelAttempts INT NULL;
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega columna stopRecording en telefonosTransferencia'
SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''stopRecording'' AND Object_ID = Object_ID(N''dbo.telefonosTransferencia''))
	BEGIN
		ALTER TABLE telefonosTransferencia ADD stopRecording bit NULL
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega columna stopRecording en telefonosTransferencia'
SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''stopRecordingAssisted'' AND Object_ID = Object_ID(N''dbo.telefonosTransferencia''))
	BEGIN
		ALTER TABLE telefonosTransferencia ADD stopRecordingAssisted bit NULL
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega columna recordIvr en ccCamps'
SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''recordIvr'' AND Object_ID = Object_ID(N''dbo.ccCamps''))
	BEGIN
		ALTER TABLE ccCamps ADD recordIvr bit NULL
	END'

EXEC(@sql)
--------------------------------------- update table ------------------------------------------
SET @process = 'KR106000 Se actualiza etiqueta de identificador OUT_INTERVAL_CANCELLED'
SET @sql = '
	IF EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''OUT_INTERVAL_CANCELLED'')
	BEGIN
		update ccGalateaIdentifiers set TagEs = ''Intervalo en canceladas (min)'', TagEn = ''Interval on cancelled (min)'', TagPt = ''Intervalo em canceladas (min)'' where Description = ''OUT_INTERVAL_CANCELLED'' 
	END'

EXEC(@sql)

--------------------------------------- Functions ------------------------------------------

SET @process = 'KR141000 Se borra función fnGetStopRecordingValue'
SET @sql = '
	if exists (select * from sys.objects where object_id = OBJECT_ID(N''fnGetStopRecordingValue'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
	begin
		DROP FUNCTION dbo.fnGetStopRecordingValue
	end'

EXEC(@sql)

SET @process = 'KR141000 Se crea función fnGetStopRecordingValue'
SET @sql = '
	CREATE function [dbo].[fnGetStopRecordingValue](@cal_id int, @cam_id int)
	RETURNS int
	AS
	BEGIN
				
	declare @stopRecording int = 0		

	select @stopRecording = stopRecording from ccCamps where cam_id = @cam_id

	if exists (select cal_id from ccLogTransfers where cal_id = @cal_id)
	begin
		declare @phone varchar(50) = '''', @typeTransfer int = 0, @stopDirectory int = 0

		select @phone = destino, @typeTransfer = modo from ccLogTransfers where cal_id = @cal_id

		if exists (select numtra_id from telefonosTransferencia where tel = @phone) and @typeTransfer in (0, 4)
		begin 
			select @stopRecording = case when @typeTransfer = 0 then ISNULL(stopRecording, 1) else ISNULL(stopRecordingAssisted, 1) end from telefonosTransferencia where tel = @phone				
		end
	end
				
	return @stopRecording
	END'

EXEC(@sql)

--------------------------------------- Inserts ------------------------------------------

SET @process = 'KR106000 Se agrega identificador OUT_CANCELED'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''OUT_CANCELED'')
	BEGIN
		insert into ccGalateaIdentifiers values (''OUT_CANCELED'', ''Reintentos en canceladas'', ''Retries on cancelled'', ''Tentativas em canceladas'')
	END'

EXEC(@sql)

SET @process = 'KR106000 Se agrega relación de identificador OUT_CANCELED'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM relationTableColumnIdentifiers WHERE Identifiers = ''OUT_CANCELED'')
	BEGIN
		insert into relationTableColumnIdentifiers values (''OUT_CANCELED'', ''ccCamps'', ''CamCanceled'')
	END'

EXEC(@sql)

SET @process = 'KR141000 Se agrega modulo 21'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaModules WHERE moduleId = 21)
	BEGIN
		insert into ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt) values (21, ''Directorio de transferencia'', ''Transfer list'', ''Catálogo de transferência'')
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega operacion 121'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 121)
	BEGIN
		insert into ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) values (121, ''Configurar número de transferencia'', ''Configure transfer number'', ''Configurar número de transferência'')
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega operacion 119'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 119)
	BEGIN
		insert into ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) values (119, ''Editar número de transferencia'', ''Edit transfer number'', ''Editar número de transferência'')
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega operacion 120'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaOperations WHERE OperationId = 120)
	BEGIN
		insert into ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) values (120, ''Eliminar número de transferencia'', ''Delete transfer number'', ''Excluir número de transferência'')
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega relacion en ccGalateaModOpRelation para el modulo 21'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaModOpRelation WHERE ModuleId = 21)
	BEGIN
		insert into ccGalateaModOpRelation (ModuleId, OperationId) values (21, 121)
		insert into ccGalateaModOpRelation (ModuleId, OperationId) values (21, 119)
		insert into ccGalateaModOpRelation (ModuleId, OperationId) values (21, 120)
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega identificador TRANSFER_LIST_NAME'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''TRANSFER_LIST_NAME'')
	BEGIN
		insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) values (''TRANSFER_LIST_NAME'', ''Nombre'', ''Name'', ''Nome'')
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega identificador TRANSFER_LIST_NUMBER'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''TRANSFER_LIST_NUMBER'')
	BEGIN
		insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) values (''TRANSFER_LIST_NUMBER'', ''Número'', ''Number'', ''Número'')
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega identificador TRANSFER_LIST_CONFERENCE'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''TRANSFER_LIST_CONFERENCE'')
	BEGIN
		insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) values (''TRANSFER_LIST_CONFERENCE'', ''Conferencia'', ''Conference'', ''Conferência'')
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega identificador TRANSFER_LIST_BLIND'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''TRANSFER_LIST_BLIND'')
	BEGIN
		insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) values (''TRANSFER_LIST_BLIND'', ''Grabación en transferencia ciega'', ''Blind transfer recording'', ''Gravação em transferência cega'')
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega identificador TRANSFER_LIST_ASSISTED'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''TRANSFER_LIST_ASSISTED'')
	BEGIN
		insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) values (''TRANSFER_LIST_ASSISTED'', ''Grabación en transferencia asistida'', ''Assisted transfer recording'', ''Gravação em transferência assistida'')
	END'

EXEC(@sql)

SET @process = 'KR141000 se agrega identificador STOP_RECORDING_IVR_TRANSFER'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''STOP_RECORDING_IVR_TRANSFER'')
	BEGIN
		insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) values (''STOP_RECORDING_IVR_TRANSFER'', ''Detener grabación después de transferir a flujo de IVR'', ''Stop recording on transfers to IVR flows'', ''Parar de gravar ao transferir para sistemas IVR'')
	END'

EXEC(@sql)

SET @process = 'KR141000 Se agrega relación de identificador STOP_RECORDING_IVR_TRANSFER'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM relationTableColumnIdentifiers WHERE Identifiers = ''STOP_RECORDING_IVR_TRANSFER'')
	BEGIN
		insert into relationTableColumnIdentifiers values (''STOP_RECORDING_IVR_TRANSFER'', ''ccCamps'', ''recordIvr'')
	END'

EXEC(@sql)

--------------------------------------- SPs ------------------------------------------

SET @process = 'KR106000 se borra sp ccspLoadCampsOutbound'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccspLoadCampsOutbound'')
	BEGIN
		DROP PROCEDURE dbo.ccspLoadCampsOutbound
	END'

EXEC(@sql)

SET @process = 'KR106000 se crea sp ccspLoadCampsOutbound'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccspLoadCampsOutbound] @action int,  @nType INT=0,@agentId int=0
	AS
	declare @sql nvarchar(max)

	if @action= 0 begin

		set @sql=''SELECT cam_id
	,cam_descripcion
	,cam_activo
	,cam_ModoManual
	,cam_modpredictivo
	,cam_callratio
	,cam_procesando
	,convert(VARCHAR(8), cast(cam_maxdlrxage AS FLOAT))
	,cam_fDialOnWU
	,cam_fDialOnDLG
	,cam_tDialAfterWU
	,cam_tDialBeforeReady
	,cam_tDialAfterDLG
	,compliance
	,progDial
	,excCallBack
	,aggressionFactor
	,listenManualCall
	,tDialOnWrapUp
	,callsbySurvey
	,ivrscript
	,cam_tNoContesta
	,cam_inter_cancelled
		''
		set @sql=@sql+'' ,isnull(CampType,0) as CampType''
		set @sql=@sql+'' ,isnull(CamCanceled, 4) as CamCanceled''
	
	
		set @sql=@sql+'' FROM ccCamps NOLOCK ''
		if @nType=2 
			set @sql=@sql+'' WHERE cam_bNew = 2 ''
		else if @nType=3
			set @sql=@sql+'' WHERE cam_bNew in (1,2) ''
		set @sql=@sql+'' ORDER BY cam_descripcion''
		--print(@sql)
		exec (@sql)
	end
	else if @action= 1 begin
		set @sql=''SELECT distinct C.cam_id, C.cam_descripcion, Prioridad, A.Login, A.User_id, Skill
	 from ccCamps C (nolock) join ccCampsAgente CA on C.cam_id = CA.cam_id
	  join ccUsers A (nolock) on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1
	  ''
	  if @nType=2 
			set @sql=@sql+'' and C.cam_bNew=2''
		else if @nType=3
			set @sql=@sql+'' and C.cam_bNew in (1,2)''
		set @sql=@sql+'' order by C.cam_id, CA.Prioridad''
		--print(@sql)
		exec (@sql)
	end
	else if @action= 2 begin
		set @sql=''select distinct A.Login, Prioridad, C.cam_id, Skill
	 from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id
	 join ccUsers A  on A.User_id = CA.User_id and A.TipoUser_id =1 AND A.Status=1
	 Where A.User_id = @agentId
	 order by C.cam_id, CA.Prioridad''
		--print(@sql)
		exec sp_executesql @sql, N''@agentId int'', @agentId
	end'

EXEC(@sql)

SET @process = 'KR106000 se borra sp ccsp_OUTGetNewJobs'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_OUTGetNewJobs'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_OUTGetNewJobs
	END'

EXEC(@sql)

SET @process = 'KR106000 se crea sp ccsp_OUTGetNewJobs'
SET @sql = '
	CREATE procedure [dbo].[ccsp_OUTGetNewJobs]
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
	exec @iZonas=ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0              
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
	SimultaneousRecs int,
	international int,
	tz_tmp int,
	tz2_tmp int,
	tz3_tmp int,
	tz4_tmp int,
	tz5_tmp int,
	cancelAttempts int
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
		isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, 0 SimultaneousRecs,
	0 international,
	sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+'',
					sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2 ,
					sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3 ,
					sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4 ,
					sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5									
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
		isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs, isnull(cs.international, 0) international,
		cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
		cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
		cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
		cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
		cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
		isnull(w.CancelAttempts, 0) as cancelAttempts
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
					isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, 0 SimultaneousRecs, 0 international,
					sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+'',
					sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2 ,
					sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3 ,
					sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4 ,
					sos.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5											
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
					isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs, isnull(cs.international, 0) international,
					cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
					cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
					cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
					cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
					cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
					isnull(w.CancelAttempts, 0) as cancelAttempts
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
				isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs, isnull(cs.international, 0) international,
				cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
				cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
				cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
				cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
				cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5
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
		user_id,
	case when tz>0  then tz  else tz_tmp end as tz,
	case when tz2>0 then tz2 else tz2_tmp end as tz2,
	case when tz3>0 then tz3 else tz3_tmp end as tz3,
	case when tz4>0 then tz4 else tz4_tmp end as tz4,
	case when tz5>0 then tz5 else tz5_tmp end as tz5,							
		case when tz is null then '''''''' else cal_telefono end as tel,
		case when tz2 is null then '''''''' else cal_telefono end as tel2,
		case when tz3 is null then '''''''' else cal_telefono end as tel3,
		case when tz4 is null then '''''''' else cal_telefono end as tel4,
		case when tz5 is null then '''''''' else cal_telefono end as tel5,
		NULL as dialOrder, list_id, sequence, calkey,
		0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent, SimultaneousRecs,'' + @maxRecs + '' maxRecs, international, cancelAttempts
		FROM #NEW_JOBS where len(cal_telefono)>0
		---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
		declare @regval int
		SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
			
		''
	end
	set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
	--print (@sql)
	exec(@sql)
	return(0)'

EXEC(@sql)

SET @process = 'KR141000 se borra sp ccsp_GalateaAdminTransferNumbersCRUD'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_GalateaAdminTransferNumbersCRUD'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_GalateaAdminTransferNumbersCRUD
	END'

EXEC(@sql)

SET @process = 'KR141000 se crea sp ccsp_GalateaAdminTransferNumbersCRUD'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_GalateaAdminTransferNumbersCRUD]
	@Type SMALLINT,
	@IDArea SMALLINT = -1,
	@Name VARCHAR(50) = NULL,
	@Tel VARCHAR(50) = NULL,
	@AllowConference bit = 0,
	@NumTraId SMALLINT = NULL,
	@stopRecording bit = 1,
	@stopRecordingAssisted bit = 1,
	@currentValue bit = 0,
	@login varchar(50) = ''''
			
	AS
			
	declare @nombre_c varchar(50) = ''''
	declare @tel_c varchar(50) = ''''
	declare @allowsConference_c bit = 0
	declare @stopRecording_c bit = 1
	declare	@stopRecordingAssisted_c bit = 1
			
		IF (@type = 1) -- Read Transfer Numbers
		BEGIN
			SELECT telTransfer.numtra_id,
					telTransfer.nombre as [name],
					telTransfer.tel,
					telTransfer.allowsConference,
					telTransfer.IDArea, 
					ISNULL(telTransfer.stopRecording, 1) stopRecording,
					ISNULL(telTransfer.stopRecordingAssisted, 1)	stopRecordingAssisted			   
			FROM dbo.telefonosTransferencia AS telTransfer
			WHERE telTransfer.idArea IN (@IDArea)
			RETURN 0;
		END;

		IF (@type = 2) -- CREATE Transfer Number
		BEGIN
			DECLARE @resultCreate SMALLINT = -1 -- -1:Name in use -2:Number alredy registered
			IF NOT EXISTS(SELECT tel FROM telefonosTransferencia WHERE tel = @Tel)
			BEGIN
				IF NOT EXISTS(SELECT numtra_id FROM telefonosTransferencia WHERE nombre = @Name)
				BEGIN
					INSERT INTO telefonosTransferencia (nombre, tel, IDArea, allowsConference, stopRecording, stopRecordingAssisted) 
					VALUES (@Name, @Tel, @idArea, @AllowConference, @stopRecording, @stopRecordingAssisted)
					SELECT @resultCreate = SCOPE_IDENTITY() 
				END
			END
			ELSE
			BEGIN
				SET @resultCreate = -2
			END
		
			SELECT @resultCreate AS [result]
			RETURN(0)
		END;

		IF (@type = 3) -- UPDATE Transfer Number
		BEGIN
			DECLARE @resultEdit int = -1 -- -1:Name in use -2:Number alredy registered
			IF NOT EXISTS(SELECT tel FROM telefonosTransferencia WHERE tel = @Tel AND numtra_id <> @NumTraId)
			BEGIN
				IF NOT EXISTS(SELECT numtra_id FROM telefonosTransferencia WHERE nombre = @Name AND numtra_id <> @NumTraId)
				BEGIN

					select @nombre_c = nombre, 
							@tel_c = tel, 
							@allowsConference_c = allowsConference, 
							@stopRecording_c = ISNULL(stopRecording, 1), 
							@stopRecordingAssisted_c = ISNULL(stopRecordingAssisted, 0) 
					from telefonosTransferencia 
					WHERE numtra_id = @NumTraId
							
					UPDATE telefonosTransferencia SET
					nombre = @Name, 
					tel = @Tel, 
					IDArea = @IDArea, 
					allowsConference = @AllowConference,
					stopRecording = @stopRecording,
					stopRecordingAssisted = @stopRecordingAssisted
					WHERE numtra_id = @NumTraId

					SELECT @resultEdit = @@ROWCOUNT

					if @resultEdit = 1 
					BEGIN
						declare @area varchar(50) = ''''

						select @area = AreaName 
						from ccUsers a
						left join ccRIACat_Areas b on a.IDArea = b.IDArea
						where Login = @login
								
						if (@nombre_c <> @Name)
						begin	
							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
								values (@area, getDate(), @login, 119, 21, ''TRANSFER_LIST_NAME'', @Name, @Tel)								
						end

						if (@tel_c <> @Tel)
						begin	
							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
								values (@area, getDate(), @login, 119, 21, ''TRANSFER_LIST_NUMBER'', @Tel, @Tel)
						end

						if (@allowsConference_c <> @AllowConference)
						begin	
							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
								values (@area, getDate(), @login, 119, 21, ''TRANSFER_LIST_CONFERENCE'', case when @AllowConference = 1 then ''COMMON_ENABLED'' else ''COMMON_DISABLED'' end, @Tel)
						end

						if (@stopRecording_c <> @stopRecording)
						begin	
							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
								values (@area, getDate(), @login, 119, 21, ''TRANSFER_LIST_BLIND'', case when @stopRecording = 0 then ''COMMON_ENABLED'' else ''COMMON_DISABLED'' end, @Tel)
						end

						if (@stopRecordingAssisted_c <> @stopRecordingAssisted)
						begin	
							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
								values (@area, getDate(), @login, 119, 21, ''TRANSFER_LIST_ASSISTED'', case when @stopRecordingAssisted = 0 then ''COMMON_ENABLED'' else ''COMMON_DISABLED'' end, @Tel)
						end
					END
							

							
				END
			END
			ELSE
			BEGIN
				SET @resultEdit = -2
			END
		
			SELECT @resultEdit AS [result]
			RETURN(0)
		END;
		IF (@type = 4) -- DELETE Transfer Number
		BEGIN
			DELETE FROM telefonosTransferencia WHERE numtra_id = @NumTraId
			SELECT @@ROWCOUNT AS [result]
			RETURN(0)
		END;
		IF (@type = 5) -- UPDATE Transfer Number Conference
		BEGIN
			UPDATE telefonosTransferencia SET allowsConference = @currentValue
			WHERE numtra_id = @NumTraId
			SELECT @@ROWCOUNT AS [result]
			RETURN(0)
		END;
		IF (@type = 6) -- UPDATE Transfer Number Conference
		BEGIN
			UPDATE telefonosTransferencia SET stopRecording = @currentValue
			WHERE numtra_id = @NumTraId
			SELECT @@ROWCOUNT AS [result]
			RETURN(0)
		END;
		IF (@type = 7) -- UPDATE Transfer Number Conference
		BEGIN
			UPDATE telefonosTransferencia SET stopRecordingAssisted = @currentValue
			WHERE numtra_id = @NumTraId
			SELECT @@ROWCOUNT AS [result]
			RETURN(0)
		END;
		IF (@type = 8)
		BEGIN
			IF EXISTS (SELECT * FROM telefonosTransferencia WHERE numtra_id = @NumTraId)
			BEGIN
				select 1
			END
			ELSE
			BEGIN
				select 0
			END
		END'

EXEC(@sql)

SET @process = 'KR141000 se borra sp ccsp_AvrsSyncronization'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_AvrsSyncronization'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_AvrsSyncronization
	END'

EXEC(@sql)

SET @process = 'KR141000 se crea sp ccsp_AvrsSyncronization'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_AvrsSyncronization] @action SMALLINT, @maxRecordsToTransfer INT = 10, @id INT = 0
	AS
	SET NOCOUNT ON

	IF @action = 1
	BEGIN
		DECLARE @countrId INT

		SET @countrId = 1

		SELECT @countrId = valor
		FROM ccSettings
		WHERE setting_id = 104;

		WITH callsIn
		AS (
			SELECT TOP (@maxRecordsToTransfer) 
			calls.cal_id, user_id, calls.Inbound_id, calls.calif_id 
			, cast(cal_extension AS INT) AS cal_extension, cal_inicio, cal_ANI AS phone
			, isnull(cal_tDialog - case when ccInbound.recordHold=1 then 0 else cal_tMoh end , 0) 
			+ CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration
			, cal_key, 0 AS cal_manual, cal_puerto
			, calls.dni_id, fvalida, cal_whohung
			, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id
			, CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh
			, dateadd(ss, isnull(cal_tDialog, 0), cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, ccInbound.prefijo
        
			, convert(bit, case when isnull(calls.file_moved,1)=2 then 0 else 1 end)  AS isCallRecord
			, isnull(dni.dni_numero, '''') AS DNIS, dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG
        
			FROM ccCallsIn  AS  calls   with(nolock)
			INNER JOIN ccInbound ON ccInbound.Inbound_id = calls.Inbound_id
			INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id    AND avrs.tipo = 0
			LEFT JOIN ccDNIS dni ON dni.dni_id = calls.dni_id
			left join ccInboundExtend inbExt on inbExt.Inbound_id=calls.Inbound_id
			LEFT JOIN (
				SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
				FROM ccLogTransfers
				WHERE tipo = 1
				GROUP BY cal_id, tipo
				) trans ON calls.cal_id = trans.cal_id
			WHERE calls.User_id > 0
			), callsOut
		AS (
			SELECT TOP (@maxRecordsToTransfer) 
			calls.cal_id AS CallId, user_id AS UserId, calls.cam_id AS camAcdId
			, cast(calls.calif_id AS SMALLINT) AS califId, cast(cal_extension AS INT) AS extension, cal_inicio, cal_telefono
			, isnull(cal_tDialog - case when camps.recordHold=1 then 0 else cal_tMoh end , 0) + CASE WHEN dbo.fnGetStopRecordingValue(calls.cal_id, calls.cam_id) = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration       
			, cal_key, cal_manual, cal_puerto, 0 AS dni_id, fvalida, cal_whohung
			, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id
			, CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh
			, dateadd(ss, isnull(cal_tDialog, 0), cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, camps.prefijo
        
			, convert(bit, case when isnull(calls.file_moved,1)=2 then 0 else 1 end)  AS isCallRecord
			, '''' AS DNIS, dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG
			FROM ccoCallsOut AS calls with(nolock)
			INNER JOIN ccCamps camps ON camps.cam_id = calls.cam_id
			INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 1
			LEFT JOIN (
				SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
				FROM ccLogTransfers
				WHERE tipo = 2
				GROUP BY cal_id, tipo
				) trans ON calls.cal_id = trans.cal_id
			WHERE calls.User_id > 0
			)

			select * from callsIn
			union 
			select * from callsOut
        
	END
	ELSE IF @action = 2
	BEGIN
		DELETE
		FROM ccAVRSTransfer
		WHERE id = @id
	END
'

EXEC(@sql)

SET @process = 'KR141000 se borra sp ccsp_DLRgetXferInfo'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_DLRgetXferInfo'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_DLRgetXferInfo
	END'

EXEC(@sql)

SET @process = 'KR141000 se crea sp ccsp_DLRgetXferInfo'
SET @sql = '
	CREATE procedure [dbo].[ccsp_DLRgetXferInfo]
	@camEspecId smallint=0,
	@iPortNumber smallint = 0,
	@type smallint,
	@typeTransfer smallint = 0,
	@phone varchar(50) = ''''
	as
	-- @type: 1 transferencia entrada, 2 transferencia salida, 3 desborde (siempre es entrada, con o sin especialidad)
	declare @prefix as varchar(15)
	declare @timeout int
	declare @ani as varchar(32)
	declare @stop int

	set @prefix =''''
	set @timeout = 20
	set @ani = ''''
	set @stop = 0

	-- Prefijo por puerto
	select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )
	-- Prefijo por campaña o especialidad
	if @prefix =''''
		if @type = 2
			select @prefix = dialPrefixXfe from ccCamps where cam_id = @camEspecId
		else
			select @prefix = dialPrefixOverflow from ccInbound where inbound_id= @camEspecId
	-- Prefijo general
	if @prefix ='''' and (@type =1 or @type=2) and ((select cast(valor as int) from ccsettings where setting_id =102) & 4 = 4)
		select @prefix = valor from ccsettings where setting_id =101
	if @prefix ='''' and (@type =3) and ((select cast(valor as int) from ccsettings where setting_id =102) & 8 = 8)
		select @prefix = valor from ccsettings where setting_id =101

	-- Tiempo de marcado
	select @timeout = cast(valor as int) from ccSettings where setting_id = 109

	-- Ani y stopRecord
	if @type = 2
		select @ani = callerIdDesc, @stop = isnull(stopRecording, 0) from ccCamps where cam_id = @camEspecId
	else
		select @ani = callerIdDesc, @stop = stopRecording from ccInbound where inbound_id= @camEspecId

	if (@typeTransfer in (0,4) and @type = 2 and @phone is not null and @phone <> '''')
	begin	
		select @stop = case when @typeTransfer = 0 then isnull(stopRecording, 1) else ISNULL(stopRecordingAssisted, 1) end from telefonosTransferencia where tel = @phone		   
	end

	select @prefix as sDialPrefix, @timeout as tNoContesta, @ani as ani, @stop as stopRecording'


EXEC(@sql)

SET @process = 'LRSV se borra sp ccsp_GalateaGetOutboundConfiguration'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_GalateaGetOutboundConfiguration'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_GalateaGetOutboundConfiguration
	END'

EXEC(@sql)

SET @process = 'LRSV se crea sp ccsp_GalateaGetOutboundConfiguration'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT
	,@campID INT
	AS
	BEGIN
	DECLARE @AllCampaigns TABLE (
	cam_id SMALLINT
	,cam_Descripcion VARCHAR(60)
	,cam_tNotas SMALLINT
	,cam_ocupado SMALLINT
	,cam_noInt_ocupado SMALLINT
	,cam_inter_ocupado SMALLINT
	,cam_nocontesto SMALLINT
	,cam_noInt_nocontesto SMALLINT
	,cam_inter_nocontesto SMALLINT
	,cam_fax SMALLINT
	,cam_noInt_fax SMALLINT
	,cam_inter_fax SMALLINT
	,cam_modomanual SMALLINT
	,ANI VARCHAR(15)
	,cam_ShowCalifWnd BIT
	,cam_StartTimerOnHangUp BIT
	,editableCallKey BIT
	,cam_tNoContesta SMALLINT
	,iTipoDial SMALLINT
	,detectAnswerMachine SMALLINT
	,detectVoiceMail SMALLINT
	,compliance SMALLINT
	,cam_inter_graba SMALLINT
	,cam_noint_graba SMALLINT
	,progDial SMALLINT
	,excCallBack SMALLINT
	,dialOrder SMALLINT
	,dialPrefix VARCHAR(10)
	,dialPrefixMan VARCHAR(10)
	,dialPrefixXfe VARCHAR(10)
	,listenManualCall BIT
	,stopRecording BIT
	,abandonCallback BIT
	,frame SMALLINT
	,t_autoCB SMALLINT
	,id_anilist INT
	,tDialonWrapUp SMALLINT
	,viewMode TINYINT
	,queSize SMALLINT
	,DNCScrub INT
	,callerIdDesc VARCHAR(15)
	,timeZoneRule INT
	,callsBySurvey INT
	,ivrScript INT
	,surveyPctg INT
	,call_record SMALLINT
	,startStopRecording BIT
	,leaveRecMessage BIT
	,manualCallOnChat BIT
	,callBackSurveyAgent BIT
	,callBackSurveyClient BIT
	,isRelationSurvey BIT
	,funcEspDtmf INT
	,sipHdrFormat VARCHAR(255)
	,cam_inter_cancelled SMALLINT
	,prefijo VARCHAR(40)
	,enbleprefix BIT
	,exitAssisted BIT
	,previewDiscard BIT
	,CampType INT
	,conexionInfo VARCHAR(50)
	,connUser VARCHAR(15)
	,closeConversationTime INT
	,answerTimeoutClient INT
	,allowFileAttachments BIT
	,selectRotativeANI INT
	,rotativeAlgo TINYINT
	,autoStart BIT
	,messagingOrder BIT
	,CamTPreview SMALLINT
	,TimesPreview TINYINT
	,timesDiscard TINYINT
	,recordHold BIT
	,zipCodeSchedule BIT
	,RecordCalls tinyint
	,simultaneousRecs smallint
	,EditableContactData bit
	,internationalDialingPortsAssigned bit
	,nationalDialingPortsAssigned bit
	,CamCanceled INT
	,recordIvr BIT
	)
	DECLARE @numbers VARCHAR(max)

	SELECT @numbers = COALESCE(@numbers + '', '', '''') + number
	FROM ccWhatsAppNumbers
	WHERE camp_id = 0
	AND STATUS = 1

	INSERT INTO @AllCampaigns
	EXEC ccsp_RIAConfCamp @adminID
	,@campID

	SELECT dialPrefixMan DialPrefixMan
	,dialPrefixXfe DialPrefixXfe
	,listenManualCall ListenManualCall
	,stopRecording StopRecording
	,abandonCallback AbandonCallBack
	,t_autoCB AutoCB
	,id_anilist IdIstANI
	,tDialonWrapUp TDialOnWrapup
	,queSize Quesize
	,DNCScrub
	,callerIdDesc CallerIdDesc
	,timeZoneRule TimeZoneRule
	,callsBySurvey CallsBySurvey
	,ivrScript IvrScript
	,surveyPctg SurveyPctg
	,call_record CallRecord
	,startStopRecording StartStopRecording
	,leaveRecMessage LeaveRecMessage
	,manualCallOnChat ManualCallOnChat
	,callBackSurveyClient CallBackSurveyClient
	,callBackSurveyAgent CallBackSurveyAgent
	,funcEspDtmf FuncEspDtmf
	,sipHdrFormat SipHdrsCfg
	,dialPrefix DialPrefix
	,prefijo Prefix
	,dialOrder DialOrder
	,progDial ProgDial
	,cam_Descripcion CamDescription
	,cam_tNotas CamTnotas
	,cam_ocupado CamBusy
	,cam_noInt_ocupado CamNoIntBusy
	,cam_inter_ocupado CamInterBusy
	,cam_nocontesto CamNoAnswer
	,cam_noInt_nocontesto CamNoIntNoAnswer
	,cam_inter_nocontesto CamInterNoAnswer
	,(cam_inter_cancelled / 60) CamInterCancelled
	,cam_fax CamFax
	,cam_noInt_fax CamNoIntFax
	,cam_inter_fax CamInterFax
	,cam_modomanual CamModoManual
	,ANI
	,cam_StartTimerOnHangUp CamStartTimerOnHangUp
	,editableCallKey EditableCallKey
	,cam_tNoContesta CamTNoAnswer
	,iTipoDial CamIntensiveDialing
	,detectAnswerMachine DetectAnswerMachine
	,detectVoiceMail DetectVoiceMail
	,compliance Compliance
	,cam_inter_graba CamInterRecord
	,cam_noint_graba CamNoIntRecord
	,excCallBack ExcCallBack
	,cam_ShowCalifWnd CamShowCalifWnd
	,frame Frame
	,exitAssisted ExitAssistedDialMode
	,previewDiscard PreviewDiscard
	,CampType
	,conexionInfo ConexionInfo
	,connUser ConnUser
	,closeConversationTime CloseConversationTime
	,answerTimeoutClient MUTimeOutClient
	,allowFileAttachments AllowFileAttachments
	,CamTPreview
	,CAST(TimesPreview AS SMALLINT) TimesPreview
	,@numbers AS FreeNumbers
	,selectRotativeANI SelectRotativeANIManualCall
	,rotativeAlgo RotativeAlgo
	,autoStart AutoStart
	,messagingOrder MessagingOrder
	,timesDiscard TimesDiscard
	,recordHold RecordHold
	,zipCodeSchedule ZipCodeSchedule
	,RecordCalls RecordCalls
	,simultaneousRecs SimultaneousRecs
	,EditableContactData EditableContactData
	,internationalDialingPortsAssigned internationalDialingPortsAssigned
	,nationalDialingPortsAssigned nationalDialingPortsAssigned
	,CamCanceled CamCanceled
	,recordIvr RecordIvr
	FROM @AllCampaigns
	WHERE cam_id = @campID
	END'

EXEC(@sql)

SET @process = 'LRSV se borra sp ccsp_RIAUpdateCamConfig'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIAUpdateCamConfig'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_RIAUpdateCamConfig
	END'

EXEC(@sql)

SET @process = 'LRSV se crea sp ccsp_RIAUpdateCamConfig'
SET @sql = '

	CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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
	@userId SMALLINT = NULL, 
	@idArea SMALLINT = NULL, 
	@isCreating SMALLINT = NULL,
	@camCanceled int = null,
	@recordIvr bit = null,
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
	recordHold = isnull(@recordHold, recordHold),
	CamCanceled = ISNULL(@camCanceled, CamCanceled),
	recordIvr = isnull(@recordIvr, recordIvr)

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
						
						WHEN CCCT.identifierInfo = ''STOP_RECORDING_IVR_TRANSFER'' THEN
							CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
								
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

SET @process = 'LRSV se borra sp ccsp_RIAConfCamp'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIAConfCamp'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_RIAConfCamp
	END'

EXEC(@sql)

SET @process = 'LRSV se crea sp ccsp_RIAConfCamp'
SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT, @campID INT = NULL
        AS
        SET NOCOUNT ON
        DECLARE @tableExistsRec TABLE (
            camId INT PRIMARY KEY
            ,existRec BIT
            )
        DECLARE @camByUser TABLE (
            camId INT PRIMARY KEY
            ,isCheck BIT
            )
        DECLARE @camId INT
            ,@id INT;
        DEClARE @intenationalDialingPorts bit, @nationalDialingPorts bit;
        declare @tempInternationalCode int
 
        if exists(select IdCode from ccoDialers ccoDial with(nolock) 
        inner join ccoDialerCamp ccoDialCamp with(nolock) on ccoDialCamp.dialer_id = ccoDial.dialer_id 
        where ccoDialCamp.cam_id = @campID and ccoDial.DialingType=0)
        BEGIN
            set @intenationalDialingPorts = 1
        END
        ElSE
        BEGIN
            set @intenationalDialingPorts = 0;
        END
        if exists(select IdCode from ccoDialers ccoDial with(nolock) 
        inner join ccoDialerCamp ccoDialCamp with(nolock) on ccoDialCamp.dialer_id = ccoDial.dialer_id 
        where ccoDialCamp.cam_id = @campID and ccoDial.DialingType=1)
        BEGIN
            set @nationalDialingPorts = 1
        END
        ElSE
        BEGIN
            set @nationalDialingPorts = 0;
        END
        IF NOT EXISTS (
                SELECT *
                FROM ccUsers_Roles
                WHERE User_id = @User_id
                    AND Rol_id = 7
                )
        BEGIN
            INSERT INTO @camByUser
            SELECT *
                ,0
            FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
            WHERE @campID IS NULL
                OR cam_id = @campID
        END
        ELSE
        BEGIN
            INSERT INTO @camByUser
            SELECT cam_id
                ,0
            FROM ccCamps
            WHERE (
                    IDArea > 0
                    OR IDArea IS NULL
                    )
                AND (
                    @campID IS NULL
                    OR cam_id = @campID
                    )
        END
        WHILE EXISTS (
                SELECT *
                FROM @camByUser
                WHERE isCheck = 0
                )
        BEGIN
            SELECT TOP 1 @camId = camId
            FROM @camByUser
            WHERE isCheck = 0
            IF EXISTS (
                    SELECT cam_id
                    FROM ccoCallsOut
                    WHERE cam_id = @camId
                    )
            BEGIN
                INSERT INTO @tableExistsRec
                VALUES (
                    @camId
                    ,1
                    )
            END
            ELSE
            BEGIN
                INSERT INTO @tableExistsRec
                VALUES (
                    @camId
                    ,0
                    )
            END
            UPDATE @camByUser
            SET isCheck = 1
            WHERE camId = @camId
        END
        SELECT a1.cam_id
            ,cam_Descripcion
            ,cam_tNotas
            ,cast(cam_ocupado AS INT) AS cam_ocupado
            ,cam_noInt_ocupado
            ,cam_inter_ocupado
            ,cast(cam_nocontesto AS INT) AS cam_nocontesto
            ,cam_noInt_nocontesto
            ,cam_inter_nocontesto
            ,cast(cam_fax AS INT) AS cam_fax
            ,cam_noInt_fax
            ,cam_inter_fax
            ,cast(cam_modomanual AS INT) AS cam_modomanual
            ,ANI
            ,cam_ShowCalifWnd
            ,cam_StartTimerOnHangUp
            ,editableCallKey
            ,cam_tNoContesta
            ,iTipoDial
            ,detectAnswerMachine
            ,detectVoiceMail
            ,compliance
            ,cam_inter_graba
            ,cam_noint_graba
            ,cast(progDial AS TINYINT) progDial
            ,cast(excCallBack AS TINYINT) excCallBack
            ,dialOrder
            ,dialPrefix
            ,dialPrefixMan
            ,dialPrefixXfe
            ,listenManualCall
            ,stopRecording
            ,cast(abandonCallback AS TINYINT) abandonCallback
            ,a3.frame
            ,a1.t_autoCB
            ,a1.id_anilist
            ,a1.tDialonWrapUp
            ,dbo.fn_viewMode(@User_id, 10) viewMode
            ,cam_maxqueue AS queSize
            ,DNCScrub
            ,callerIdDesc
            ,timeZoneRule
            ,callsBySurvey
            ,ivrScript
            ,surveyPctg
            ,isnull(a1.call_record, 1) AS call_record
            ,cast(startStopRecording AS TINYINT) startStopRecording
            ,leaveRecMessage
            ,manualCallOnChat
            ,callBackSurveyAgent
            ,callBackSurveyClient
            ,CASE 
                WHEN surveycamid IS NULL
                    OR surveycamid = 0
                    THEN 0
                ELSE 1
                END isRelationSurvey
            ,isnull(a1.funcEspDtmf, 0)
            ,isnull(sipHdrFormat, '''') sipHdrFormat
            ,cam_inter_cancelled
            ,prefijo
            ,enbleprefix = CASE 
                WHEN existRec = 0
                    THEN 1
                ELSE 0
                END
            ,isnull(exitAssisted, 0) exitAssisted
            ,isnull(previewDiscard, 0) PreviewDiscard   
            ,isnull(CampType, 0) CampType
            ,isnull(contact.conexionInfo, '''') conexionInfo
            ,isnull(contact.connUser, '''') connUser
            ,isnull(contact.closeConversationTime, 0) closeConversationTime
            ,isnull(contact.answerTimeoutClient, 0) answerTimeoutClient
            ,isnull(contact.allowFileAttachments, 0) allowFileAttachments
            ,isnull(selectRotativeANI, 0) selectRotativeANI
            ,ISNULL(rotativeAlgo, 0) rotativeAlgo
            ,isnull(autoStart, 0) autoStart
            ,isnull(messagingOrder, 0) messagingOrder
            ,ISNULL(cam_tPreview, 0) AS CamTPreview
            ,ISNULL(timesPreview, 0) AS TimesPreview
            ,isnull(timesDiscard, 0) TimesDiscard
            ,ISNULL(recordHold, 0) recordHold
            ,isnull(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule
            ,isnull(campsExtention.RecordCalls, 1) RecordCalls
            ,isnull(campsExtention.simultaneousRecs, 1) simultaneousRecs
            ,isnull(campsExtention.EditableContactData, 0) EditableContactData
            ,@intenationalDialingPorts intenationalDialingPorts 
            ,@nationalDialingPorts nationalDialingPorts
			,ISNULL(CamCanceled, 0) CamCanceled
			,isnull(recordIvr, 1) recordIvr
        FROM ccCamps a1
        INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
        INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
        INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
        LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
        LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
        ORDER BY cam_descripcion
        RETURN (0)
        SET NOCOUNT OFF

'

EXEC(@sql)

SET @process = 'KR141000 se borra sp ccsp_DLRGetDialInfo'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_DLRGetDialInfo'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_DLRGetDialInfo
	END'

EXEC(@sql)

SET @process = 'KR141000 se crea sp ccsp_DLRGetDialInfo'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_DLRGetDialInfo]
	@callout_id int,
	@cam_id smallint=0,
	@iPortNumber smallint = 0
	AS
	set nocount on
	declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
	declare @prefix as varchar(15)
	declare @prefixCalKey as varchar(30)
	declare @tNoContesta as tinyint
	declare @ani as varchar(32)
	declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint, @rotativeAlgo tinyint
	declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
	declare @ivr_script smallint, @surveycamid int
	declare @call_record_cam as tinyint
	declare @pais as tinyint 
	declare @sipHdrFormat varchar(255)
	declare @PrefixRec varchar(40)
	declare @recordHold bit, @recordIvr bit

	set @prefix =''''
	set @tNoContesta = 25
	set @ani=''''
	set @iTipoDial = 0
	set @detectAnswerMachine = 0
	set @detectVoiceMail =1
	set @cam_tnotas = 30
	set @keepDial = 0

	select @pais = valor from ccsettings where setting_id = 104
	select @PrefixRec=ISNULL(prefijo,'''') from ccCamps nolock where cam_id = @cam_id

	-- Mensajes
	select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
	from dbo.fn_ccCamps_SelMessage(@cam_id)

	-- Prefijo por puerto
	select @prefix = prefix from cstoProvedor nolock where provedor_id = (select provedor_id from ccodialers nolock where puerto = @iPortNumber )
	-- Prefijo por campa?a
	if @prefix =''''
		select @prefix = dialPrefix from ccCamps nolock where cam_id = @cam_id
	-- Prefijo general, si es que esta habilitado
	if @prefix ='''' and ((select cast(valor as int) from ccsettings nolock where setting_id =102) & 1 = 1)
		select @prefix = valor from ccsettings nolock where setting_id =101

	select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

	-- Propiedades de campa?a
	select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
	@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
	@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0), @rotativeAlgo=isnull(rotativeAlgo,0), @recordHold=ISNULL(recordHold,0)
	,@PrefixRec=ISNULL(prefijo,''''), @recordIvr=ISNULL(recordIvr,0)
	from ccCamps C (nolock) where C.cam_id=@cam_id

	if @surveycamid > 0
		select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

	--Custom MOH Files
	DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
	SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
	FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

	--Agrega prefijo Marcacion con directo
	declare @mainPrefix varchar(1), @phones varchar(max)
	set @prefixCalKey=''''
	select @mainPrefix = valor from ccSettings where setting_id=202
	declare @tmpccoCallsOutSource table(callout_id int primary key,dialPrefix   varchar(30) null
	,cal_Key    varchar(40)
	,cal_telefono   varchar(30),cal_telefono2   varchar(30),cal_telefono3   varchar(30),cal_telefono4   varchar(30),cal_telefono5   varchar(30)
	,Dato1  varchar(255),Dato2  varchar(255),Dato3  varchar(255),Dato4  varchar(255),Dato5  varchar(255)
	,recyclePhone   smallint,recycleType bit
	)
	insert into @tmpccoCallsOutSource
	select callout_id,dialPrefix,cal_Key,
	cal_telefono,cal_telefono2,cal_telefono3,cal_telefono4,cal_telefono5,
	Dato1,Dato2,Dato3,Dato4,Dato5,
	recyclePhone,recycleType
	FROM ccoCallsOutSource NOLOCK WHERE callout_id=@callout_id 


	SELECT @prefixCalKey=CASE WHEN @mainPrefix=''1'' THEN isnull(dialPrefix,'''') ELSE '''' END,
		@phones=cal_telefono+'';''+cal_telefono2+'';''+cal_telefono3+'';''+cal_telefono4+'';''+cal_telefono5
	FROM @tmpccoCallsOutSource

	if @iPortNumber >= 0 
	begin
		declare @Anis table(id int, pid varchar(2), phone varchar(32), ani varchar(32))

		insert @Anis
		exec ccsp_DLRGetRotativeANI @callout_id=@callout_id,@phones=@phones,@aniList=@lista_id,@algo=@rotativeAlgo

		SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
    
		SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)
		, ISNULL(cpt.Prioridad,''12345NNN'') dial_tels
		, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 1) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE C.cal_telefono  END cal_telefono
		, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 2) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono2 END cal_telefono2
		, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 3) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono3 END cal_telefono3
		, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 4) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono4 END cal_telefono4
		, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 5) AND ISNULL(recycleType, 1) = 0) THEN '''' Else c.cal_telefono5 END cal_telefono5
		, isnull(@message_name, '''') as message_name
		, @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
		, case when anis.p1 <> '''' then anis.p1 else @ani end ani
		, case when anis.p2 <> '''' then anis.p2 else @ani end ani2
		, case when anis.p3 <> '''' then anis.p3 else @ani end ani3
		, case when anis.p4 <> '''' then anis.p4 else @ani end ani4
		, case when anis.p5 <> '''' then anis.p5 else @ani end ani5
		, @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail
		, @cam_tnotas cam_tnotas, @keepDial keepDial
		, isnull(@messageDNCL_name, '''') as messageDNCL_name
		,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record
		,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2
		,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3
		,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4
		,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5
		, isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name
		, isnull(@MohFiles,'''') as mohFiles
		,@ivr_script ivrScript
		,@sipheader data
		,@PrefixRec as Prefijo,
		dbo.GetCarrierByTel(C.cal_telefono) carrier1, 
		dbo.GetCarrierByTel(cal_telefono2) carrier2, 
		dbo.GetCarrierByTel(cal_telefono3) carrier3, 
		dbo.GetCarrierByTel(cal_telefono4) carrier4, 
		dbo.GetCarrierByTel(cal_telefono5) carrier5,
		@recordHold as recordHold,
		@recordIvr as recordIvr 
		FROM @tmpccoCallsOutSource C
		left join ccoCallPriorityOrder cpo on cpo.callout_id = c.callout_id
		left join ccCampsPrioridadTel cpt on cpt.cam_id = @cam_id
		left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
		WHERE C.callout_id = @callout_id
		return
	end 
	set nocount off'

EXEC(@sql)

SET @process = 'KR141000 se borra sp ccsp_DLRgetDialPrefix'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_DLRgetDialPrefix'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_DLRgetDialPrefix
	END'

EXEC(@sql)

SET @process = 'KR141000 se crea sp ccsp_DLRgetDialPrefix'
SET @sql = '
	CREATE procedure [dbo].[ccsp_DLRgetDialPrefix]
	@cam_id smallint=0,
	@iPortNumber smallint = 0,
	@phone varchar(30) = '''',
	@callout_id int = 0
	as
	declare @prefix as varchar(15), @sipheader varchar(500)
	declare @ani as varchar(32)
	declare @pais as tinyint 
	declare @aniglobal varchar(32), @sipHdrFormat varchar(255)
	declare @ivr_script smallint, @surveycamid int
	declare @call_record tinyint, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint
	declare @PrefixRec varchar(40)
	declare @carrier varchar(255)
	declare @recordHold bit, @recordIvr bit

	select @pais = valor from ccsettings with(nolock) where setting_id = 104
	select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

	set @prefix =''''
	-- Prefijo por puerto
	select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

	-- Prefijo por campa?a,
	if @prefix =''''
		select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

	-- Prefijo general
	if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
		select @prefix = valor from ccsettings with(nolock) where setting_id =101

	-- Ani
	set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

	--AnswerMachine Message Files
	DECLARE @MsgFiles VARCHAR(8000) 
	SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile 
	FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

	--Custom MOH Files
	DECLARE @MohFiles VARCHAR(8000) 
	SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
	FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

	select @surveycamid = 0, @ivr_script = 0

	select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta = cam_tNoContesta, @ani = case when @ani = '''' then ani else @ani end
	,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
	,@call_record = dbo.EnableCallRecord(call_record, @pais, @phone), @surveycamid = isnull(surveycamid,0), @recordHold=ISNULL(recordHold,0)
	,@recordIvr=ISNULL(recordIvr,0), @PrefixRec = ISNULL(prefijo,'''')
	from ccCamps NOLOCK where cam_id = @cam_id

	SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)

	if @surveycamid > 0
		select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid


	if @ani = '''' begin 
	set @ani = @aniglobal 
	end 

	 set @carrier = ''''
	 select @carrier = dbo.GetCarrierByTel(@phone)

	select @prefix as sDialPrefix, @tNoContesta as tNoContesta,@ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
	@call_record as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles, @ivr_script ivrScript, @sipheader data
	,@PrefixRec PrefijoRec, @carrier Carrier, @recordHold recordHold, @recordIvr recordIvr'

EXEC(@sql)

SET @process = 'KR106 se borra sp ccsp_OUT_JobsActions'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_OUT_JobsActions'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_OUT_JobsActions
	END'

EXEC(@sql)

SET @process = 'KR106 se crea sp ccsp_OUT_JobsActions'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_OUT_JobsActions]
	@Type SMALLINT,
	@callout_id INT = 0,
	@cam_id int = 0
	
	AS
			
	IF (@type = 1) 
	BEGIN
		update ccoWorkingTable set CancelAttempts = case when CancelAttempts is null then 1 else CancelAttempts + 1 end where callout_id = @callout_id and cam_id = @cam_id		
	END;
'

EXEC(@sql)

	-------------------------------------------------- End Rod Salazar -----------------------------------------------------------------------------------
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
