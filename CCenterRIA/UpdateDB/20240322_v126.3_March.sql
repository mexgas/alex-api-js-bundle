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
SET @versionfix = 3
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
        ----------------------------------------------------- BEGIN Frida Orta----------------------------------------------------------------
SET @process = 'DEV2-405 update tableLangueDbLoader'
SET @sql = '
		if  exists(select tag from tableLangueDbLoader where tag = ''type-camp-no-international-port'' and languageId=0)
		begin
			update tableLangueDbLoader set translate=''Puerto de marcación no encontrado'' where tag = ''type-camp-no-international-port'' and languageId=0
		end
		'
EXEC(@sql);
SET @process = 'DEV2-405 update tableLangueDbLoader'
SET @sql = '
	if  exists(select tag from tableLangueDbLoader where tag = ''type-camp-no-international-port'' and languageId=1)
		begin
			update tableLangueDbLoader set translate=''Dialing port not found'' where tag = ''type-camp-no-international-port'' and languageId=1
		end'
EXEC(@sql);
SET @process = 'DEV2-405 update tableLangueDbLoader'
SET @sql = '
	if  exists(select tag from tableLangueDbLoader where tag = ''type-camp-no-international-port'' and languageId=2)
		begin
			update  tableLangueDbLoader set translate= ''Porta de discagem não encontrada''  where tag = ''type-camp-no-international-port'' and languageId=2
		end'
EXEC(@sql);
        ----------------------------------------------------- END Frida Orta----------------------------------------------------------------
        ----------------------------------------------------- BEGIN JCL----------------------------------------------------------------
SET @process = 'CW-831 Drop SP ccsp_GetDialingCodesByCamp'
SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GetDialingCodesByCamp'')
    begin
        DROP PROCEDURE ccsp_GetDialingCodesByCamp;
    end
	'
EXEC(@sql);
SET @process = 'CW-831 Create SP ccsp_GetDialingCodesByCamp'
SET @sql = '
CREATE PROCEDURE ccsp_GetDialingCodesByCamp
@cam_id int
as
begin
	select distinct isnull(id, 0) as id, isnull(Code, 0 ) as Code from ccoDialers a
	inner join ccoDialerCamp b on a.dialer_id = b.dialer_id
	left join CodesInterDialing c on a.IdCode = c.id
	where a.DialingType = 0 and b.cam_id = @cam_id 
end'

EXEC(@sql);
SET @process = 'CW-831 change type bool to int'
SET @sql = '
ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
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
tz5_tmp int
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
                cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5											
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
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5
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
	0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent, SimultaneousRecs,'' + @maxRecs + '' maxRecs, international
	FROM #NEW_JOBS where len(cal_telefono)>0
	---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
	declare @regval int
	SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
	
	''
end
set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print (@sql)
exec(@sql)
return(0)
	'
EXEC(@sql);
SET @process = 'CW-8305 se modifica update para planchar dialingType'
SET @sql = '
                    ALTER PROCEDURE [dbo].[ccsp_GalateaDialer]
                    @Description varchar(40)='''',
                    @DialerId int = 0,
                    @PortNumber int = 0,
                    @Status varchar(1)='''',
                    @action smallint=0,
                    @Provider smallint=0,
                    @XferType smallint=0,
                    @PortEnd int = 0,
                    @CampId smallint = 0,
                    @dialer_ids varchar(2000)='''',
                    @DialingType tinyint = 0,
                    @idDialingCode int = 0
                    AS
                    set nocount on
                    if @action=1
                    begin
                        select provedor_id as ProviderId, descrip as ProviderName  from cstoProvedor
                    end
                    if @action=2 --Insert
                    begin
                        create table #tempPortTable( portId int primary key)
                        if @PortEnd>0 begin
                            begin transaction
                                while @PortNumber<=@portEnd begin
                                insert into #tempPortTable values(@PortNumber)
                                set @PortNumber=@PortNumber+1
                                end
                            commit transaction
                        end
                        else begin
                            insert into #tempPortTable values(@PortNumber)
                        end
                        
                        if exists(select Puerto from ccoDialers where Puerto in (select portId from #tempPortTable))
                        begin
                            drop table #tempPortTable
                            select -1 as ResponseCode
                            return(0)
                        end
                        Insert ccoDialers (Descripcion, Puerto, Status, provedor_id, xfertype, DialingType, IdCode) 
                        Select @Description+''_''+CAST(portId as varchar(5)), portId, @Status, @Provider, @XferType, case @DialingType when 2 then 0 else @DialingType end, @idDialingCode from #tempPortTable t
                        select 200 as ResponseCode, dialer_id as DialerId, Descripcion as PortDescription, 
                        p.descrip as ProviderDescription, Puerto, XferType, DialingType, IdCode as DialingCode
                        from ccoDialers d
                        inner join cstoProvedor p on p.provedor_id=d.provedor_id
                        where Puerto in (select portId from #tempPortTable)
                        drop table #tempPortTable
                    end
                    if @action=3 --Update
                    begin
                        if exists(select Puerto from ccoDialers where Puerto=@PortNumber and dialer_id <> @DialerId)
                        begin
                            select -1 as ResponseCode ---Port already exists
                            return(0)
                        end
                        Update ccoDialers set Descripcion=case @Description when '''' then Descripcion else @Description+''_''+cast(@PortNumber as varchar(5)) end,
                        Puerto=case @PortNumber when '''' then Puerto else @PortNumber end, Status=case @Status when '''' then Status else @status end,
                        provedor_id=case @Provider when '''' then provedor_id else @Provider end,
                        xfertype = case @XferType when 0 then xfertype else @XferType end,
                        DialingType = case when @DialingType = 0 then DialingType when @DialingType = 2 then 0 else @DialingType end,
                        IdCode = case when @DialingType = 1 then 0 when @idDialingCode != IdCode then @idDialingCode else IdCode end
                        where Dialer_id=cast(@DialerId as int)
                        
                        select 200 as ResponseCode, dialer_id as DialerId, Descripcion as PortDescription, 
                        p.descrip as ProviderDescription, Puerto, XferType, DialingType, case when DialingType = 1 then 0 else IdCode end as DialingCode
                        from ccoDialers d
                        inner join cstoProvedor p on p.provedor_id=d.provedor_id
                        where dialer_id=@DialerId
                    end
                    if @action=4 --Delete
                    begin
                        if exists(select Dialer_id from ccoDialerCamp where
                            Dialer_id in (select Value from dbo.fn_RIASplitDelimited (@dialer_ids, '','')))
                        begin
                            select -2 as ResponseCode --Existe alguna campaña que esta utilizando este dialer
                            return(0)
                        end
                        declare @portsDelete table(DialerId int, Port int,PortDescription varchar(15))
                        insert @portsDelete (DialerId,Port,PortDescription)
                        select Value, Puerto,Descripcion from dbo.fn_RIASplitDelimited (@dialer_ids, '','') 
                        inner join ccoDialers on dialer_id=Value
                        delete from ccoDialers Where Dialer_id in (select DialerId from @portsDelete)
                        
                        select 200 as ResponseCode, DialerId, PortDescription
                        from @portsDelete
                    end
                    if @action=5 --Ports Info
                    begin
                        select dc.cam_id as CampId, c.cam_descripcion as CampName, graphic_id as Frame, c.IDArea, a.AreaName
                        from ccoDialerCamp dc
                        inner join ccCamps c on c.cam_id=dc.cam_id
                        inner join ccRIACat_Areas a on a.IDArea=c.IDArea
                        inner join ccRIACampsGraph cg on c.cam_id=cg.cam_id
                        where dc.dialer_id=@DialerId
                        return(0)
                    end
                    set nocount off
	'

EXEC(@sql)

	SET @process = 'Drop SP GetInterDialing'
SET @sql = '
	if exists (select * from sys.procedures where name = N''GetInterDialing'')
    begin
        DROP PROCEDURE GetInterDialing;
    end
	'
EXEC(@sql);

EXEC(@sql);
SET @process = 'CW-8305 Agregar opcion todos los paises'
SET @sql = '
                    CREATE PROCEDURE GetInterDialing
                    AS
                    BEGIN
                    declare @language tinyint
                    select @language = valor from ccSettings nolock where setting_id = 27
                    select 
                    0 as id
                    , case
                        when @language = 0 then ''Todos los países''
                        when @language = 1 then ''All countries''
                        else ''Todos os países'' end description
                    , ''0'' Code
					union
                    select 
                    id
                    , case
                        when @language = 0 then ES
                        when @language = 1 then EN
                        else PT end description
                    , Code 
                    from CodesInterDialing nolock
                    END
	'

EXEC(@sql);
set @process = 'Se agrega tabla de areasCode'
set @sql='IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = N''AreaCode'') BEGIN
CREATE TABLE AreaCode (
    IdArea INT,
    IdCode INT,
    Estado VARCHAR(100),
    Numero INT
);
INSERT INTO AreaCode (IdArea, IdCode, Estado, Numero)
VALUES
(1, 1, ''Alabama'', 205),
(2, 1, ''Alabama'', 251),
(3, 1, ''Alabama'', 256),
(4, 1, ''Alabama'', 334),
(5, 1, ''Alaska'', 907),
(6, 1, ''Arizona'', 480),
(7, 1, ''Arizona'', 520),
(8, 1, ''Arizona'', 602),
(9, 1, ''Arizona'', 623),
(10, 1, ''Arizona'', 928),
(11, 1, ''Arkansas'', 479),
(12, 1, ''Arkansas'', 501),
(13, 1, ''Arkansas'', 870),
(14, 1, ''California'', 209),
(15, 1, ''California'', 213),
(16, 1, ''California'', 310),
(17, 1, ''California'', 323),
(18, 1, ''California'', 408),
(19, 1, ''California'', 415),
(20, 1, ''California'', 510),
(21, 1, ''California'', 530),
(22, 1, ''California'', 559),
(23, 1, ''California'', 562),
(24, 1, ''California'', 619),
(25, 1, ''California'', 626),
(26, 1, ''California'', 650),
(27, 1, ''California'', 661),
(28, 1, ''California'', 707),
(29, 1, ''California'', 714),
(30, 1, ''California'', 760),
(31, 1, ''California'', 805),
(32, 1, ''California'', 818),
(33, 1, ''California'', 831),
(34, 1, ''California'', 858),
(35, 1, ''California'', 909),
(36, 1, ''California'', 916),
(37, 1, ''California'', 925),
(38, 1, ''California'', 949),
(39, 1, ''California'', 951),
(40, 1, ''Colorado'', 303),
(41, 1, ''Colorado'', 719),
(42, 1, ''Colorado'', 720),
(43, 1, ''Colorado'', 970),
(44, 1, ''Connecticut'', 203),
(45, 1, ''Connecticut'', 860),
(46, 1, ''Delaware'', 302),
(47, 1, ''Florida'', 239),
(48, 1, ''Florida'', 305),
(49, 1, ''Florida'', 321),
(50, 1, ''Florida'', 352),
(51, 1, ''Florida'', 386),
(52, 1, ''Florida'', 407),
(53, 1, ''Florida'', 561),
(54, 1, ''Florida'', 727),
(55, 1, ''Florida'', 754),
(56, 1, ''Florida'', 772),
(57, 1, ''Florida'', 813),
(58, 1, ''Florida'', 850),
(59, 1, ''Florida'', 863),
(60, 1, ''Florida'', 904),
(61, 1, ''Florida'', 941),
(62, 1, ''Florida'', 954),
(63, 1, ''Georgia'', 229),
(64, 1, ''Georgia'', 404),
(65, 1, ''Georgia'', 470),
(66, 1, ''Georgia'', 478),
(67, 1, ''Georgia'', 678),
(68, 1, ''Georgia'', 706),
(69, 1, ''Georgia'', 762),
(70, 1, ''Georgia'', 770),
(71, 1, ''Georgia'', 912),
(72, 1, ''Hawai'', 808),
(73, 1, ''Idaho'', 208),
(74, 1, ''Illinois'', 217),
(75, 1, ''Illinois'', 224),
(76, 1, ''Illinois'', 309),
(77, 1, ''Illinois'', 312),
(78, 1, ''Illinois'', 331),
(79, 1, ''Illinois'', 618),
(80, 1, ''Illinois'', 630),
(81, 1, ''Illinois'', 708),
(82, 1, ''Illinois'', 773),
(83, 1, ''Illinois'', 815),
(84, 1, ''Illinois'', 847),
(85, 1, ''Indiana'', 219),
(86, 1, ''Indiana'', 260),
(87, 1, ''Indiana'', 317),
(88, 1, ''Indiana'', 574),
(89, 1, ''Indiana'', 765),
(90, 1, ''Indiana'', 812),
(91, 1, ''Iowa'', 319),
(92, 1, ''Iowa'', 515),
(93, 1, ''Iowa'', 563),
(94, 1, ''Iowa'', 641),
(95, 1, ''Iowa'', 712),
(96, 1, ''Kansas'', 316),
(97, 1, ''Kansas'', 620),
(98, 1, ''Kansas'', 785),
(99, 1, ''Kansas'', 913),
(100, 1, ''Kentucky'', 270),
(101, 1, ''Kentucky'', 502),
(102, 1, ''Kentucky'', 606),
(103, 1, ''Kentucky'', 859),
(104, 1, ''Louisiana'', 225),
(105, 1, ''Louisiana'', 318),
(106, 1, ''Louisiana'', 337),
(107, 1, ''Louisiana'', 504),
(108, 1, ''Louisiana'', 985),
(109, 1, ''Maine'', 207),
(110, 1, ''Maryland'', 240),
(111, 1, ''Maryland'', 301),
(112, 1, ''Maryland'', 410),
(113, 1, ''Maryland'', 443),
(114, 1, ''Massachusetts'', 339),
(115, 1, ''Massachusetts'', 351),
(116, 1, ''Massachusetts'', 413),
(117, 1, ''Massachusetts'', 508),
(118, 1, ''Massachusetts'', 617),
(119, 1, ''Massachusetts'', 774),
(120, 1, ''Massachusetts'', 781),
(121, 1, ''Massachusetts'', 857),
(122, 1, ''Massachusetts'', 978),
(123, 1, ''Michigan'', 231),
(124, 1, ''Michigan'', 248),
(125, 1, ''Michigan'', 269),
(126, 1, ''Michigan'', 313),
(127, 1, ''Michigan'', 517),
(128, 1, ''Michigan'', 586),
(129, 1, ''Michigan'', 616),
(130, 1, ''Michigan'', 734),
(131, 1, ''Michigan'', 810),
(132, 1, ''Michigan'', 906),
(133, 1, ''Michigan'', 947),
(134, 1, ''Michigan'', 989),
(135, 1, ''Minnesota'', 218),
(136, 1, ''Minnesota'', 320),
(137, 1, ''Minnesota'', 507),
(138, 1, ''Minnesota'', 612),
(139, 1, ''Minnesota'', 651),
(140, 1, ''Minnesota'', 763),
(141, 1, ''Minnesota'', 952),
(142, 1, ''Mississippi'', 228),
(143, 1, ''Mississippi'', 601),
(144, 1, ''Mississippi'', 662),
(145, 1, ''Mississippi'', 769),
(146, 1, ''Missouri'', 314),
(147, 1, ''Missouri'', 417),
(148, 1, ''Missouri'', 573),
(149, 1, ''Missouri'', 636),
(150, 1, ''Missouri'', 660),
(151, 1, ''Missouri'', 816),
(152, 1, ''Montana'', 406),
(153, 1, ''Nebraska'', 308),
(154, 1, ''Nebraska'', 402),
(155, 1, ''Nevada'', 702),
(156, 1, ''Nevada'', 725),
(157, 1, ''Nevada'', 775),
(158, 1, ''New Hampshire'', 603),
(159, 1, ''New Jersey'', 201),
(160, 1, ''New Jersey'', 551),
(161, 1, ''New Jersey'', 609),
(162, 1, ''New Jersey'', 732),
(163, 1, ''New Jersey'', 848),
(164, 1, ''New Jersey'', 856),
(165, 1, ''New Jersey'', 862),
(166, 1, ''New Jersey'', 908),
(167, 1, ''New Jersey'', 973),
(168, 1, ''New Mexico'', 505),
(169, 1, ''New Mexico'', 575),
(170, 1, ''New York'', 212),
(171, 1, ''New York'', 315),
(172, 1, ''New York'', 347),
(173, 1, ''New York'', 516),
(174, 1, ''New York'', 518),
(175, 1, ''New York'', 585),
(176, 1, ''New York'', 607),
(177, 1, ''New York'', 631),
(178, 1, ''New York'', 646),
(179, 1, ''New York'', 716),
(180, 1, ''New York'', 718),
(181, 1, ''New York'', 845),
(182, 1, ''New York'', 914),
(183, 1, ''New York'', 917),
(184, 1, ''New York'', 929),
(185, 1, ''North Carolina'', 252),
(186, 1, ''North Carolina'', 336),
(187, 1, ''North Carolina'', 704),
(188, 1, ''North Carolina'', 828),
(189, 1, ''North Carolina'', 910),
(190, 1, ''North Carolina'', 919),
(191, 1, ''North Carolina'', 980),
(192, 1, ''North Carolina'', 984),
(193, 1, ''North Dakota'', 701),
(194, 1, ''Ohio'', 216),
(195, 1, ''Ohio'', 234),
(196, 1, ''Ohio'', 330),
(197, 1, ''Ohio'', 419),
(198, 1, ''Ohio'', 440),
(199, 1, ''Ohio'', 513),
(200, 1, ''Ohio'', 614),
(201, 1, ''Ohio'', 740),
(202, 1, ''Ohio'', 937),
(203, 1, ''Oklahoma'', 405),
(204, 1, ''Oklahoma'', 539),
(205, 1, ''Oklahoma'', 580),
(206, 1, ''Oklahoma'', 918),
(207, 1, ''Oregon'', 503),
(208, 1, ''Oregon'', 541),
(209, 1, ''Oregon'', 971),
(210, 1, ''Pennsylvania'', 215),
(211, 1, ''Pennsylvania'', 267),
(212, 1, ''Pennsylvania'', 412),
(213, 1, ''Pennsylvania'', 484),
(214, 1, ''Pennsylvania'', 570),
(215, 1, ''Pennsylvania'', 610),
(216, 1, ''Pennsylvania'', 717),
(217, 1, ''Pennsylvania'', 724),
(218, 1, ''Pennsylvania'', 814),
(219, 1, ''Pennsylvania'', 878),
(220, 1, ''Rhode Island'', 401),
(221, 1, ''South Carolina'', 803),
(222, 1, ''South Carolina'', 843),
(223, 1, ''South Carolina'', 864),
(224, 1, ''South Dakota'', 605),
(225, 1, ''Tennessee'', 423),
(226, 1, ''Tennessee'', 615),
(227, 1, ''Tennessee'', 731),
(228, 1, ''Tennessee'', 865),
(229, 1, ''Tennessee'', 901),
(230, 1, ''Tennessee'', 931),
(231, 1, ''Texas'', 210),
(232, 1, ''Texas'', 214),
(233, 1, ''Texas'', 254),
(234, 1, ''Texas'', 281),
(235, 1, ''Texas'', 325),
(236, 1, ''Texas'', 346),
(237, 1, ''Texas'', 361),
(238, 1, ''Texas'', 409),
(239, 1, ''Texas'', 469),
(240, 1, ''Texas'', 512),
(241, 1, ''Texas'', 682),
(242, 1, ''Texas'', 713),
(243, 1, ''Texas'', 806),
(244, 1, ''Texas'', 817),
(245, 1, ''Texas'', 830),
(246, 1, ''Texas'', 832),
(247, 1, ''Texas'', 903),
(248, 1, ''Texas'', 915),
(249, 1, ''Texas'', 936),
(250, 1, ''Texas'', 940),
(251, 1, ''Texas'', 956),
(252, 1, ''Texas'', 972),
(253, 1, ''Texas'', 979),
(254, 1, ''Utah'', 385),
(255, 1, ''Utah'', 435),
(256, 1, ''Utah'', 801),
(257, 1, ''Vermont'', 802),
(258, 1, ''Virginia'', 276),
(259, 1, ''Virginia'', 434),
(260, 1, ''Virginia'', 540),
(261, 1, ''Virginia'', 571),
(262, 1, ''Virginia'', 703),
(263, 1, ''Virginia'', 757),
(264, 1, ''Virginia'', 804),
(265, 1, ''Washington'', 206),
(266, 1, ''Washington'', 253),
(267, 1, ''Washington'', 360),
(268, 1, ''Washington'', 425),
(269, 1, ''Washington'', 509),
(270, 1, ''Washington'', 564),
(271, 1, ''West Virginia'', 304),
(272, 1, ''Wisconsin'', 262),
(273, 1, ''Wisconsin'', 414),
(274, 1, ''Wisconsin'', 608),
(275, 1, ''Wisconsin'', 715),
(276, 1, ''Wisconsin'', 920),
(277, 1, ''Wyoming'', 307),
(278, 7, ''Alberta'', 368),
(279, 7, ''Alberta'', 403),
(280, 7, ''Alberta'', 587),
(281, 7, ''Alberta'', 780),
(282, 7, ''Alberta'', 825),
(283, 7, ''British Columbia'', 250),
(284, 7, ''British Columbia'', 778),
(285, 7, ''British Columbia'', 236),
(286, 7, ''British Columbia'', 604),
(287, 7, ''British Columbia'', 672),
(288, 7, ''Manitoba'', 204),
(289, 7, ''Manitoba'', 431),
(290, 7, ''Manitoba'', 584),
(291, 7, ''New Brunswick'', 506),
(292, 7, ''Newfoundland'', 709),
(293, 7, ''Northwest Territories'', 867),
(294, 7, ''Nova Scotia'', 902),
(295, 7, ''Nova Scotia'', 782),
(296, 7, ''Nunavut'', 867),
(297, 7, ''Ontario'', 249),
(298, 7, ''Ontario'', 613),
(299, 7, ''Ontario'', 683),
(300, 7, ''Ontario'', 753),
(301, 7, ''Ontario'', 807),
(302, 7, ''Ontario'', 343),
(303, 7, ''Ontario'', 519),
(304, 7, ''Ontario'', 705),
(305, 7, ''Ontario'', 226),
(306, 7, ''Ontario'', 437),
(307, 7, ''Ontario'', 548),
(308, 7, ''Ontario'', 647),
(309, 7, ''Ontario'', 905),
(310, 7, ''Ontario'', 289),
(311, 7, ''Ontario'', 365),
(312, 7, ''Ontario'', 416),
(313, 7, ''Ontario'', 742),
(314, 7, ''Prince Edward Island'', 782),
(315, 7, ''Prince Edward Island'', 902),
(316, 7, ''Quebec'', 367),
(317, 7, ''Quebec'', 418),
(318, 7, ''Quebec'', 450),
(319, 7, ''Quebec'', 514),
(320, 7, ''Quebec'', 581),
(321, 7, ''Quebec'', 873),
(322, 7, ''Quebec'', 468),
(323, 7, ''Quebec'', 819),
(324, 7, ''Quebec'', 263),
(325, 7, ''Quebec'', 354),
(326, 7, ''Quebec'', 438),
(327, 7, ''Quebec'', 579),
(328, 7, ''Saskatchewan'', 306),
(329, 7, ''Saskatchewan'', 639),
(330, 7, ''Saskatchewan'', 474),
(331, 7, ''Yukon'', 867),
(332, 6, ''Puerto Rico'', 787),
(333, 6, ''Puerto Rico'', 939),
(334, 17, ''Jamaica'', 658),
(335, 17, ''Jamaica'', 876),
(336, 23, ''República Dominicana'', 809),
(337, 23, ''República Dominicana'', 829),
(338, 23, ''República Dominicana'', 849);
			END'
EXEC(@sql)
 
         ----------------------------------------------------- END JCL----------------------------------------------------------------
		 		         ------------------------------------------------------ BEGIN Gaby------------------------------------------------------------------------------
SET @process = 'Drop SP ccsp_RIAConfCamp'
SET @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_RIAConfCamp'')
    begin
        DROP PROCEDURE ccsp_RIAConfCamp;
    end
    '
EXEC(@sql);
SET @process = 'Create SP ccsp_RIAConfCamp'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT, @campID INT = NULL
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
EXEC(@sql);
 
 SET @process = 'Drop SP ccsp_GalateaGetOutboundConfiguration'
SET @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_GalateaGetOutboundConfiguration'')
    begin
        DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
    end
    '
EXEC(@sql);
SET @process = 'Create SP ccsp_GalateaGetOutboundConfiguration'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT
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
        )
        DECLARE @numbers VARCHAR(max)
        SELECT @numbers = COALESCE(@numbers + '''', '''', '''''''') + number
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
        FROM @AllCampaigns
        WHERE cam_id = @campID
        END
'
EXEC(@sql);
SET @process = 'Alter table ccoCallsOutSource alter column international'
SET @sql = '
    if EXISTS(
        select column_name
        from information_schema.columns  
        where table_name = ''ccoCallsOutSource'' AND column_name = ''international''
        AND DATA_TYPE = ''bit''
    )
    BEGIN
        alter table ccoCallsOutSource alter column international int
    END'
EXEC(@sql)
------------------------------------------------------------------------------ END Gaby -------------------------------------------------------------------

 
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
