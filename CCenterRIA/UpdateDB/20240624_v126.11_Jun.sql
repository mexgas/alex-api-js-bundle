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
SET @versionfix = 11
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
	
---------------------------------------- Begin fix/125.20231211.0.9 fix/125.20231211.0.14 - -------------------------------------------------        

	SET @process = 'Alter SP ccsp_OUTGetNewJobs Merge 125.20241211.0.14 -KR106000 se crea sp ccsp_OUTGetNewJobs'
	SET @sql = 'Alter procedure [dbo].[ccsp_OUTGetNewJobs]
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


if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )
select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';
    
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
											
end -- TOMA EN CUENTA LOS CALLBACKS
if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
	select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar );
	select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';


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
return(0)
'
	EXEC(@sql) 

	SET @process = 'Add Column ccWhatsAppConversationsOut.IsAgentLoggingOut'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''IsAgentLoggingOut'' and Object_ID = Object_ID(N''ccWhatsAppConversationsOut'')) BEGIN
    ALTER TABLE ccWhatsAppConversationsOut ADD IsAgentLoggingOut BIT null
END '
    EXEC(@sql);

    SET @process = 'CW-8394 Permiso para hacer llamadas Manual en el agente, se modifico para que tome el plan 2, donde los números son de 10 digitos para México'
        SET @sql = 'Alter PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
@user_id integer,
@tel varchar(15)
AS
declare @mask integer, @idioma integer, @value integer, @lada integer
declare @country as tinyint

set @value = 0
select @mask = isnull(dialmask,7) from ccusers where user_id=@user_id
select @country = valor from ccsettings where setting_id = 104

if @mask=0 begin
    select @value Response
    return
end

-- Restricciones por pais 1:Mexico 2:Argentina 3:Colombia 4:USA 5:Chile 6:Venezuela 7:uk 8:Arabia Saudita, 9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador
if @country = 1
    begin

    DECLARE @specialDialPlan TINYINT, @phoneType TINYINT
    SELECT @specialDialPlan = valor, @phoneType = 0
    FROM ccsettings WITH (NOLOCK)
    WHERE setting_id = 195

    if @specialDialPlan = 2 select @phoneType=dbo.fnGetTipoLlamada(@tel)

    --Restringe celulares
    if (@mask & 1)>0
        begin
        if ((left(ltrim(rtrim(@tel)),3) = ''044'' Or left(ltrim(rtrim(@tel)),3) = ''045'') and len(ltrim(rtrim(@tel))) = 13) or (@specialDialPlan = 2 and (@phoneType=3 or @phoneType=4))
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if ((left(ltrim(rtrim(@tel)),2) = ''01'') and len(ltrim(rtrim(@tel))) = 12) or (@specialDialPlan = 2 and @phoneType=2)
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            if (Len(@lada) + Len(ltrim(rtrim(@tel))) = 10 and @specialDialPlan = 0) or (@specialDialPlan = 2 and @phoneType=1)
                begin
                set @value = 6
                end
            end
        end
    end

-- Argentina
if @country = 2
    begin
    --Restringe celulares
    if ((@mask & 1) > 0)
        begin
        if (left(@tel,2)=''15'') or (len(@tel)>=13 and substring(@tel,1,1)=''0'' and
            (substring(@tel,4,2)=''15'' or substring(@tel,5,2)=''15'' or substring(@tel,3,2)=''15''))
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if ((left(ltrim(rtrim(@tel)),2) =''0'') and len(ltrim(rtrim(@tel))) = 11)
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask&4)>0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
                begin
                set @value=6
                end
            end
        end
    end

if @country = 3 --Colombia
    begin
    --Restringe Celulares
    if ((@mask & 1) > 0)
        begin
        if len(@tel) > 8
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if len(@tel) = 8 or left(@tel,1) = ''0''
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
                begin
                set @value = 6
                end
            end
        end
    end

if @country = 4 --USA
    begin
    --Restringe larga distancia usa
    if ((@mask & 2) > 0)
        begin
        if len(ltrim(rtrim(@tel))) >= 11  and (left(ltrim(rtrim(@tel)),1) = ''1'')
            begin
            set @value = 5
            end
        end

    --Restringe locales usa
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            --if Len(ltrim(rtrim(@tel))) = 7
            if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
                begin
                set @value = 6
            end
            end
        end
    end

--Chile
if @country = 5
    begin

        --Restringe Celulares
    if ((@mask & 1) > 0)
        begin
        if len(@tel) >= 10 and left(@tel,2) = ''09''
            begin
            set @value = 4
            end
        end

        --Restringe Locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            if Len(@tel) in (6,7)
                begin
                set @value = 6
                end
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if len(@tel) >= 8 and len(@tel) < 10
                begin
                set @value = 5
                end
            end
        end
    end

--Venezuela
if @country = 6
begin
        --Restringe Celulares
    if ((@mask & 1) > 0)
        begin
        if len(@tel) >= 10 and left(@tel,2) = ''04''
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if len(@tel) >= 10 and left(@tel,1) = ''0''
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
                begin
                set @value = 6
                end
            end
        end

end

--United Kingdom
if @country = 7
begin
        --Restringe Celulares
    if ((@mask & 1) > 0)
        begin
        if (len(@tel) >= 9) and left(@tel,2) = ''07''
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if len(@tel) >= 9 and left(@tel,1) = ''0''
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            if len(@tel) >= 9 and left(@tel,1) <> ''0''
                begin
                set @value = 6
                end
            end
        end

end

--arabia saudita
if @country = 8
begin

    --Restringe celulares
    if (@mask & 1)>0
        begin
        if (left(ltrim(rtrim(@tel)),2) = ''05'' and len(ltrim(rtrim(@tel))) = 10 )
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if ( left(ltrim(rtrim(@tel)),2) <> ''05'' and len(ltrim(rtrim(@tel))) in (11, 9))
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
                begin
                set @value = 6
                end
            end
        end
end

--Australia
if @country = 9
begin

    --Restringe celulares
    if (@mask & 1)>0
        begin
        if (left(ltrim(rtrim(@tel)),2) = ''04'' and len(ltrim(rtrim(@tel))) = 10)
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if ( left(ltrim(rtrim(@tel)),2) <> ''04'' and len(ltrim(rtrim(@tel))) = 10)
                begin
                set @value = 5
                end
            end
        end

    --Restringe locales
    if(@value=0)
        begin
        if ((@mask & 4) > 0)
            begin
            select @lada=valor from ccSettings WHERE setting_id=17
            if ((Len(ltrim(rtrim(@tel))) = 8) or
                (''0'' + left(ltrim(rtrim(@tel)),1) = @lada and Len(ltrim(rtrim(@tel))) = 9) or
                (left(ltrim(rtrim(@tel)),2) = @lada and Len(ltrim(rtrim(@tel))) = 10))
                begin
                set @value = 6
                end
            end
        end
end

--Brasil
if @country = 10
    begin
        declare @lon int
        --Restringe celulares
        if (@mask & 1)>0
        begin
            set @tel=ltrim(rtrim(@tel))
            set @lon=len(@tel)
            if
                (@lon in(7,8) and left(@tel,1) in (''6'',''7'',''8'',''9'') )
                or (@lon=9 and left(@tel,1) = ''9'' )
                or (@lon=10 and substring(@tel,3,1) in (''6'',''7'',''8'',''9'') )
                or (@lon=11 and substring(@tel,3,1) = ''9'')
                --or (@lon=12 and substring(@tel,5,1) in (''6'',''7'',''8'',''9'') )
                --or (@lon=13 and substring(@tel,5,1) = ''9'' )
                --or (@lon=13 and substring(@tel,5,1) = ''9'' )
                begin
                    set @value = 4
                end
        end

        --Restringe larga distancia
        if(@value=0)
        begin
            if ((@mask & 2) > 0)
            begin
                select @lada=valor from ccSettings WHERE setting_id=17
                set @tel=ltrim(rtrim(@tel))
                set @lon=len(@tel)
                if  @lon>=10 and left(@tel,2) <> @lada
                begin
                    set @value = 5
                end
            end
        end
        --Restringe locales
        if(@value=0)
        begin
            if ((@mask & 4) > 0)
            begin
                select @lada=valor from ccSettings WHERE setting_id=17
                set @tel=ltrim(rtrim(@tel))
                set @lon=len(@tel)
                if @lon in (7,8,9) or (@lon in (10,11) and left(@tel,2)= @lada)
                begin
                    set @value = 6
                end
            end
        end

        --Restringe por cobrar
        if(@value=0)
        begin
            declare @llamadasPorCobrar varchar(4);
            select @llamadasPorCobrar= valor from ccSettings where setting_id=126
            set @tel=ltrim(rtrim(@tel))
            set @lon=len(@tel)
            if @lon >= 12 and  left(@tel,2) = ''90'' and @llamadasPorCobrar=''0''
            begin
                set @value = 10 -- pone para llamadas por cobrar
            end
        end

    end -- Termina Brasil


--Guatemala
if @country = 11
    begin
        --Restringe celulares
        if (@mask & 1)>0
        begin
            set @tel=ltrim(rtrim(@tel))
            if charindex(substring(@tel,1,1),''3,4,5'') > 0
                set @value = 4
        end

        --Restringe locales
        if(@value=0)
        begin
            if ((@mask & 4) > 0)
            begin
                set @tel=ltrim(rtrim(@tel))
                if charindex(substring(@tel,1,1),''2,6,7'') > 0
                    set @value = 6
            end
        end

    end -- Termina Guatemala

--Costa Rica
if @country = 12
    begin
        --Restringe celulares
        if (@mask & 1)>0
        begin
            set @tel=ltrim(rtrim(@tel))
            if charindex(substring(@tel,1,1),''5,6,7,8'') > 0
                set @value = 4
        end

        --Restringe locales
        if(@value=0)
        begin
            if ((@mask & 4) > 0)
            begin
                set @tel=ltrim(rtrim(@tel))
                if charindex(substring(@tel,1,1),''2,3,4'') > 0
                    set @value = 6
            end
        end

    end -- Termina Costa Rica

--Salvador
if @country = 13
    begin
        --Restringe celulares
        if (@mask & 1)>0
        begin
            set @tel=ltrim(rtrim(@tel))
            if charindex(substring(@tel,1,1),''6,7'') > 0
                set @value = 4
        end

        --Restringe locales
        if(@value=0)
        begin
            if ((@mask & 4) > 0)
            begin
                set @tel=ltrim(rtrim(@tel))
                if charindex(substring(@tel,1,1),''2'') > 0
                    set @value = 6
            end
        end

    end -- Termina Salvador

--Spain
if @country = 14
    begin
        --Restringe celulares
        if (@mask & 1)>0
        begin
            set @tel=ltrim(rtrim(@tel))
            if charindex(substring(@tel,1,1),''6,7'') > 0
                set @value = 4
        end

        --Restringe locales
        if(@value=0)
        begin
            if ((@mask & 4) > 0)
            begin
                set @tel=ltrim(rtrim(@tel))
                if charindex(substring(@tel,1,1),''8,9'') > 0
                    set @value = 6
            end
        end

    end -- Termina Spain

select @value Response'
        EXEC(@sql)

        set @process = 'CW-8341 El Valor de registros contactados no cambia de 0.0% Alter Sp ccsp_GetInfoDash correcion @vop3 cuando es null'
    set @sql='ALTER procedure [dbo].[ccsp_GetInfoDash]
@CampId as smallint
as
set nocount on              
declare @upd_date as datetime
declare @cps  as int 
declare @today datetime

select @cps = [valor] from ccSettings  where setting_id=238
select
    @upd_date = date_update
from ccCampsInfo with(nolock) where cam_id = @CampId

set @today=convert(date,getdate(),121)

if @upd_date is null begin
    insert into ccCampsInfo(cam_id,contact_reg,dial_retries,date_update,calls_per_second)
    values(@CampId,0,0,getdate(),@cps)

    set @upd_date=@today
end

if (datediff(ss, @upd_date, getdate()) > 300) begin
    if not exists(select cam_id from ccocallsout with(nolock)
    where cam_id=@CampId and statuscall_id=13 and cal_inicio>= @today)
    begin
        update ccCampsInfo
            set contact_reg=0, dial_retries=0, date_update = getdate(), calls_per_second=@cps
        where cam_id = @CampId      
    end else
    begin

        declare @vop1 decimal(12,2)
        declare @vop2 decimal(12,2)
        declare @vop3 decimal(12,2)
        declare @vop4 decimal(12,2)

        select @vop1 = count(distinct(callout_id)) from ccocallsout with(nolock)
        where cam_id = @CampId and statuscall_id=13 and cal_inicio>= @today
        group by cam_id
        select @vop2 = count(distinct(callout_id)), @vop4 = count(distinct telefono) from ccoLogDials with(nolock) 
        where cam_id = @CampId and fecha >= @today
        group by cam_id
        select @vop3 = count(distinct telefono) from ccoLogDials with(nolock) 
        where cam_id = @CampId and fecha >= @today
        group by cam_id, Telefono having count(1) > 1
        
                if @vop2 is null 
            set @vop2=0

        if @vop3 is null 
            set @vop3=0
                        
        if @vop4 is null 
            set @vop4=0     
        
        update ccCampsInfo set
             contact_reg=isnull( case when @vop2=0 then 0 else (@vop1/@vop2)*100 end,0)
            , dial_retries=isnull(case when @vop4=0 then 0 else(@vop3/@vop4)*100 end,0)
            , date_update=getdate()
    end
end

select
cam_id, contact_reg, dial_retries, date_update, calls_per_second
from ccCampsInfo
where cam_id = @CampId


set nocount off'
    EXEC(@sql);

    SET @process = 'KR123022 - Habilitar y deshabilitar uso de auxiliares al agente action 10 added to update AuxiliaryRestricted column'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
    @option smallint,
    @UserId int,
    @Login varchar(40)='''',
    @Nombres varchar(25)=null,
    @ApellidoPaterno varchar(25)='''',
    @ApellidoMaterno varchar(25)='''',
    @Password varchar(33)='''',
    @Sexo bit=null,
    @canChangeStatus bit=null,
    @AreaId int=null,
    @UserType tinyint=1,
    @IDWG int=0,
    @DeleteUsers int=1,
    @inOut int=null,
    @IDCampEsp int=null,
    @multipleUsers varchar(1000)=null
    as
    set nocount on

    if @option=0--All Users
      begin
      select User_id,Login,ISnull(AREas.AreaName,'''')as AreaName

    from ccusers as users with(nolock)
        left join ccRIACat_Areas as areas with(nolock)
        on users.IDArea=areas.IDArea
      return(0)
      end

    if @option=1--selected User
      begin
      select User_id,Login,Nombres,isnull(apellidoPaterno,''''),
        isnull(ApellidoMaterno,''''),Sexo,canChangeStatus,isnull(IDArea,0),tipouser_id
      from ccusers where User_id=@UserId
      order by IDArea,Nombres,ApellidoPaterno,User_id
      return(0)
      end

    if @option=2--insert
      begin
      if exists(select Login from ccUsers where Login=@Login)
        begin
        select -1--,''Login en Uso''
        return(0)
        end

      if exists(select Login from ccUsers_Consulta where Login = @Login)
      begin
        select -4 -- ''Login habia estado en Uso''
        return(0)
      end

      if exists(select Nombres from ccUsers where Nombres=@Nombres
      and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
        begin
        select -2--,''Nombre en Uso''
        return(0)
        end

    IF( select isnull(max(user_id),0) from ccusers) > 32700
    BEGIN
      set @UserId = null
      SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
      FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
      LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
      INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
      FROM ccusers) AS w ON w.recID = d.recID

      if @UserId is null
      begin
        select -2--insert Error
        return(0)
      end

      set identity_insert ccusers on
      insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
        Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
      select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
        1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
      set identity_insert ccusers off

      delete ccMenuUser where id_User = @UserId
      delete ccRIAUserRole where user_id = @UserId

      exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

    END
    ELSE
    BEGIN
      insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
        Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
      select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
        1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

      if @@rowcount=1
        select @UserId=scope_identity()
      else
        begin
        select -2--insert Error
        return(0)
        end
    END
      insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
      insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
      insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
      --Menu para roles RepotsRia
      exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

      select @UserId,'' Usuario '' + @Login + '' Dado de Alta''
      return(0)
      end

    if @option=3--Update
      begin
      if @Login='''' and @Password <> ''''
        begin
        Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId
        return(0)
        end

      Update ccUsers
      set Login= case when @Login <> '''' then @Login else Login end,
      Nombres=@Nombres,
      ApellidoPaterno=@ApellidoPaterno,ApellidoMaterno=@ApellidoMaterno,
      Password=case when @Password <> '''' then @Password else Password end,
      Sexo=@Sexo,canChangeStatus=@canChangeStatus
      where User_id=@UserId
      return(0)
      end

    if @option=4--Delete
      begin
      delete from ccSkills where user_id =@UserId
      delete from ccMenu_ViewsUser where user_id =@UserId
      delete from dbo.ccRIAWorkGroupUsers where user_id =@UserId
delete from ccRIAAgentsPermissions where AgentId=@UserId
  delete from ccUsers_Roles where User_id=@UserId
      delete from ccUsers where user_id=@UserId
      return(0)
      end

    declare @Type tinyint, @users int,@sql varchar(8000), @NinOut nvarchar(10)

    if @option=5--insert Agente-Supervisor in WorkGroup
      begin
      select @Type=TipoUser_id from ccUsers where User_id=@UserId

      if @Type not in(1,2,6)
        return(0)

      if @Type=1 and((select count(User_id)from ccRIAWorkGroupUsers where User_id=@UserId)>=(select valor from ccSettings where setting_id=63))
        begin
        select 3
        return(0)
        end

      if exists(select @UserId from ccRIAWorkGroupUsers where User_id=@UserId and IDWG=@IDWG)
        begin
        select 1
        return(0)
        end

      insert into ccRIAWorkGroupUsers(IDWG,User_id)values(@IDWG,@UserId)

      if @Type=1
        begin

        if @IDWG is null or @IDWG = 0
          begin
          select 28
          return(0)
          end
        insert into cccampsAgente(user_id,cam_id,prioridad,skill,IDWG)

        select @UserId,idCampEsp,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
        from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
          and idCampEsp not in(select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

        insert into ccinboundAgentes(User_id,Inbound_id,cli_id,prioridad,skill,IDWG)
        select @UserId,idCampEsp,0,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
        from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
          and idCampEsp not in(select inbound_id from ccinboundAgentes where user_id=@UserId and IDWG=@IDWG)

        return(0)
        end

    --else @Type=2 or @Type=6--Supervisor
      insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
      select @UserId,idCampEsp,0,@IDWG
      from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
        and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

      insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
      select @UserId,idCampEsp,1,@IDWG
      from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
        and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
      return(0)
      end

    if @option=6--Delete Agent-Supervisor from WorkGroup
      begin
      if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)=0
        select @UserId = @multipleUsers

            else if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)>0
              select @UserId = cast(substring(@multipleUsers, 1,
              CHARINDEX('','', @multipleUsers)-1) as int)

        select @Type=case when @UserType <> 0 then @UserType else TipoUser_id end,
        @multipleUsers=isnull(@multipleUsers,cast(@Userid as varchar(10)))
      from ccUsers where User_id=@UserId

      Declare @sqlDelete nvarchar(4000)
      if @Type in(1,2,6)--1:Agente / 2,6:Supervisor
        begin
        set @sqlDelete=N''Delete from '' + case @Type when 1 then ''cccampsagente where '' else ''ccSupervisorCam where tipo=0 and '' end
        + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
        + '' Delete from '' + case @Type when 1 then ''ccinboundagentes where '' else ''ccSupervisorCam where tipo=1 and '' end
        + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
        exec(@sqlDelete)
        end

      if isnull(@UserId, 0) = 0 or isnull(@multipleUsers, ''0'') = ''0''
        begin
        select -9 -- Se ingreso mal el id del usuario
        --delete ccinboundagentes where idwg=@IDWG
        --delete cccampsagente where idwg=@IDWG
        --delete ccSupervisorCam where idwg=@IDWG
        end

      if @DeleteUsers=1
        Delete ccRIAWorkGroupUsers where IDWG=@IDWG and User_id=@UserId

      return(0)
      end

    if @option=7--Delete Agent from WorkGroup
      begin
      select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end
      set @sql=''delete '' + case @NinOut when ''1'' then ''ccCampsAgente'' else ''ccInboundAgentes'' end +
        '' where user_id in('' + isnull(@multipleUsers, ''0'') +'') and '' + case @NinOut when ''1'' then ''cam_id'' else ''inbound_id'' end +
        ''='' + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' + cast(@IDWG as varchar(10)) +
        '' delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
      exec(@sql)
      --update preview permission
      set @sql = ''update ccusers set 
          AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
          DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
          select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
          where progDial=3 and user_id in ('' + isnull(@multipleUsers, ''0'') +'') group by user_id)c on us.User_id=c.user_id
          where us.user_id in ('' + isnull(@multipleUsers, ''0'') +'')''
      exec(@sql)
    return(0)
      end

    if @option=8--Delete Supervisor from WorkGroup
      begin
      select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end

            set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and user_id in('' + isnull(@multipleUsers, ''0'') + '') and cam_id=''
              + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' +cast(@IDWG as varchar(10)) + ''
              delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
            exec(@sql)

      set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and cam_id='' + cast(@IDCampEsp as varchar(10)) + ''and '' +
        ''user_id in ('' + isnull(@multipleUsers, ''0'') + '') and IDWG='' + cast(@IDWG as varchar(10))
      exec(@sql)
      return(0)
      end

    if @option=9
      begin
      update ccusers set NotReadyRestricted=@canChangeStatus where [User_id]=@UserId
	  SELECT Login from ccUsers where [User_id]=@UserId
	  RETURN(0)
	END
    IF @option = 10
	BEGIN	
		UPDATE dbo.ccUsers SET AuxiliaryRestricted=@canChangeStatus WHERE [User_id] = @UserId
		SELECT Login from ccUsers where [User_id]=@UserId
		 RETURN(0)
	END
set nocount off';

EXEC(@sql);

SET @process = 'TT8053 DROP VIEW ccLogAgentesDiaViewLast'
        SET @sql = 'IF EXISTS(SELECT * FROM sys.views WHERE name=''ccLogAgentesDiaViewLast'')
BEGIN
DROP VIEW ccLogAgentesDiaViewLast;
END;'
        EXEC(@sql);

        SET @process = 'TT8053 Create ccLogAgentesDiaViewLast for better access to last status by agent'
        SET @sql = 'CREATE VIEW ccLogAgentesDiaViewLast AS
SELECT User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus, callId
FROM ccLogAgentesDiaLast with(nolock)      ;
                    '
        EXEC(@sql);


        SET @process = 'CW-8389,TT9258 Error al consultar el finder por día y rango de fechas no se muestra información, se modifica el @action'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@ids varchar(max)=null,
@name varchar(25) = NULL,
@top int = 0,
@dateIni datetime =null,
@dateEnd datetime =null,
@dateStart dateTime= null,
@userId int = 0,
@node varchar(10) = null,
@grabIds varchar(4000) = null
AS

declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
declare @filterWg varchar(max)
declare @len int
declare @tipo int
declare @serviceId varchar(10)

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
    order by Xname''
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
    
    set @tipo = CASE WHEN @node = ''R06'' THEN 1 ELSE 0 END
    set @filterWg=''''
    if @node is null or @node = ''R02''
    begin
        select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId
                        
    end
    else
    begin
    
    set @serviceId = (select convert(varchar(10), id) from ccFinderServices where ref = @node)
    select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+@serviceId+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId and WGCam.Tipo=@tipo
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

end

else if @action = 13 begin
    set @sql = ''''
    select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=5 
    select @tableName,@tableNameHistory,@columnId
    set @sql=''
    ;
    with duplicateIds as(
    select ''+@columnId+'',dateIn from ''+@tableName+'' where ''+@columnId+'' in(''+@grabIds+'')
    union
    select ''+@columnId+'',dateIn from ''+@tableNameHistory+'' where ''+@columnId+'' in(''+@grabIds+'')
    )

    select A.''+@columnId+'' as Id,min(B.Xname) Xname from duplicateIds A
    inner join ccbasexDB B on B.serviceId=2 and( A.dateIn between B.dateStart and B.dateEnd or A.dateIn>= B.dateStart)
    group by A.''+@columnId+'',A.dateIn
    Having count(*)>1
    order by Xname
    ''
    exec (@sql)

end

else if @action = 14 begin
    declare @CidNameOut varchar(100),@CidNameIn varchar(100)
    declare @filterCamId varchar(max), @filterInboundId varchar(max);
    declare @campType int
    declare @cidOut varchar(max)=''''
    declare @cidin varchar(max)=''''

    set @filterWg=''''
    if @node is null begin
        set @node=''R02''
    end

    set @CidNameOut=''$CID_OUT_''+@node
    set @CidNameIn=''$CID_In_''+@node

    set @filterCamId=''''
    

    if @node = ''R02''
    begin
        select @filterCamId=@filterCamId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
        from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        inner join ccCamps c on c.cam_id=WGCam.IdCampEsp and c.CampType not in(5,7)
        where Wguser.User_id=@userId and WGCam.Tipo=1                               
    end
    else if @node = ''R05''
    begin       
        select @filterCamId=@filterCamId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
        from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        inner join ccCamps c on c.cam_id=WGCam.IdCampEsp and c.CampType =5
        where Wguser.User_id=@userId and WGCam.Tipo=1                       
    end

    if @filterCamId<>'''' begin
        if @node in( ''R02'',''R05'') begin
            set @filterWg=''let ''+@CidNameOut+'':=(''
        end

        set @filterCamId=SUBSTRING(@filterCamId,0,len(@filterCamId))
        set @filterCamId=@filterCamId+'')''+char(10)    

        set @filterWg=@filterWg+@filterCamId
    end 
        
    set @tipo = case when @node in(''R01'',''R02'',''R03'',''R04'') then 1  
        when @node =''R05'' then 5 
        when @node =''R06'' then 6 
        else 0 end -- revisar ccsp_CreateNodeMultimedia CTYPE

    set @campType = case when @node =''R01'' then 1 
        when @node =''R02'' then 0
        when @node =''R03'' then 3
        when @node =''R04'' then 4
        when @node =''R05'' then 5
        when @node =''R06'' then 6 else 0 end

    SET @filterInboundId= ''''
            
    select @filterInboundId=@filterInboundId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
    from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        inner join ccInbound c on c.Inbound_id=WGCam.IdCampEsp and c.chat =@campType
        where Wguser.User_id=@userId and WGCam.Tipo=0
    
    if @filterInboundId<>'''' begin
        set @filterInboundId=SUBSTRING(@filterInboundId,0,len(@filterInboundId))
        set @filterInboundId=@filterInboundId+'')''+char(10)    

        set @filterWg=@filterWg+''let ''+@CidNameIn+'':=(''+@filterInboundId
    end
    
    if @node = ''R02'' BEGIN
        IF(@filterCamId <> '''')
        BEGIN
            SET @cidOut=''(exists(index-of(''+@CidNameOut+'',@CID)) and @CType=2)''
        END
    end
    else if @node = ''R06'' begin
        set @cidOut=''(exists(index-of(''+@CidNameOut+'',@CID)) and @CType=6)''
    end
    if @node not in(''R05'') BEGIN
        IF(@filterInboundId <> '''')
        BEGIN
            set @cidin=''(exists(index-of(''+@CidNameIn+'',@CID)) and @CType=''+ convert(varchar(max), @tipo)+'')''
        END
    end
    
    select @filterWg as VarCamInOut,@cidOut as CidOut,@cidin as CidIn
end
else if @action = 15 begin --Saber si hacer busqueda en basex
  select @tableName=tableName,@tableNameHistory=tableNameHistory from ccFinderServices where ref=@node
  if @node=''R02'' begin
    select 1
    return(0)
  end

  set @sql=''if exists(select * from ''+@tableName+'') begin
        select 1
    end
    else if exists(select * from ''+@tableNameHistory+'') begin
        select 1
    end
    select 0''
    exec (@sql)
    
end'
    EXEC(@sql);

    set @process = 'Dineria -- alter Table smsccoLogDial add Message'
    set @sql='if not exists (select * from sys.columns where name = N''Message'' and Object_ID = Object_ID(N''smsccoLogDial''))
begin
    alter Table smsccoLogDial add Message varchar(200) null
end
'
    EXEC(@sql)

    set @process = 'Dineria --  Add Column smsccoLogDial.Bill decimal'
    set @sql='if exists (select * from sys.columns c 
inner join sys.types t on c.system_type_id=t.system_type_id
where c.name = N''Bill'' and c.Object_ID = Object_ID(N''smsccoLogDial'')
and t.name=''float''
)
begin
   alter Table smsccoLogDial alter Column Bill decimal(10,2) not null
end'
    EXEC(@sql)

    set @process = 'Alter Sp ccsp_RIAUpdateCamConfig cambios se agrega para validar si @callsBySurvey y @ivrScript para poner de tipo encuesta'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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

if @callsBySurvey is not null and @ivrScript is not null begin
        
    UPDATE ccCamps SET CampType=case when @callsBySurvey=0 and @ivrScript=0 then 0 else 8 end 
    Where cam_id = @cam_id
end
    

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

    SET @process = '1 - JR 1211.0.14 -> SP ccsp_ConversationOutWASave, Valida si la conversación de entrada existe'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationOutWASave] 
@action             INT
, @conversationId     INT         = 0
, @campId             INT         = NULL        
, @phoneCamp          VARCHAR(50) = NULL
, @clientId           VARCHAR(25) = NULL
, @conversationStatus SMALLINT    = 0
, @tChatting          FLOAT       = 0
, @tWrapUp            SMALLINT    = 0
, @finishedBy         TINYINT     = 0
, @onQueue            BIT         = NULL
, @tQueue             SMALLINT    = 0
, @tTimeout           INT         = 0
, @disposition        SMALLINT    = 0
, @subDisposition     SMALLINT    = 0
, @agentId            INT         = 0

AS
BEGIN
    SET NOCOUNT ON;
                        
    declare @conversationIdTemporal     INT;

IF @action = 1 BEGIN --new Conversation
    select @phoneCamp= number from ccWhatsAppNumbers where camp_id= @campId
                            
    if @phoneCamp is null or @phoneCamp='''' begin
        select 0 as [ConversationId],0 as [MessageId]
        return(0)
    end
    DECLARE @dateNow DATETIME;
    SET @dateNow = DATEADD(HOUR, -23, GETDATE());


    declare @existsConversationOut bit
    declare @existsConversation bit
    set @existsConversationOut =0
    set @existsConversation =0

    
    
    if not exists (select * from ccWhatsAppConversationsOut with(nolock) where
    phoneCamp = @phoneCamp and clientId = @clientId and finishedBy=0 AND requestDate <= @dateNow) 
    begin       
        set @existsConversationOut=0
    end 
    else begin
        set @existsConversationOut=1
        UPDATE ccWhatsAppConversationsOut
        SET finishedBy = 2 ,conversationStatus=17
        WHERE finishedBy = 0  AND requestDate <= @dateNow
        and phoneCamp = @phoneCamp and clientId = @clientId
    end
    
    if not exists (select * from ccWhatsAppConversations with(nolock) where
    phoneACD = @phoneCamp and clientId = @clientId and finishedBy=0 AND requestDate <= @dateNow) 
    begin       
        set @existsConversation=0
    end 
    else begin
        set @existsConversation=1
        UPDATE ccWhatsAppConversations
        SET finishedBy = 2 ,conversationStatus=17
        WHERE finishedBy = 0  AND requestDate <= @dateNow
        and phoneACD = @phoneCamp and clientId = @clientId
    end
    
    if not exists (select 1 from ccWhatsAppConversationsOut with(nolock) 
        where phoneCamp = @phoneCamp and clientId = @clientId 
        and finishedBy = 0 and requestDate > @dateNow) 
    begin
        set @existsConversationOut=0
    end
    else begin
        set @existsConversationOut=1
    end
    
    if not exists (select 1 from ccWhatsAppConversations with(nolock) 
        where phoneACD = @phoneCamp and clientId = @clientId 
        and finishedBy = 0 and requestDate > @dateNow) 
    begin
        set @existsConversation=0
    end
    else begin
        set @existsConversation=1
    end
    
    if @existsConversationOut=0
    begin
        if @existsConversation = 0
        begin
            INSERT INTO [ccWhatsAppConversationsOut]
            ([camId] , [phoneCamp], clientId, conversationStatus, tChatting
            , tWrapUp, finishedBy, onQueue, tQueue, requestDate
            , tTimeout, disposition, subDisposition, agentId)
            VALUES(@campId, @phoneCamp, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, 
            @onQueue, @tQueue, GETDATE(), @tTimeout, @disposition, @subDisposition, @agentId);
                        
            SELECT @conversationIdTemporal = SCOPE_IDENTITY();    
            SELECT @conversationIdTemporal AS [ConversationId],0 as [MessageId]
        end
        else begin
            select A.descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, C.Login Username 
            ,B.conversationId as conversationIdExists
            FROM ccInbound A INNER JOIN ccWhatsAppConversations B WITH(NOLOCK)
            ON B.clientId = @clientId AND B.finishedBy = 0 and B.inboundId=A.Inbound_id
            INNER JOIN ccUsers C ON B.agentId = C.User_id;
        end  
    end
    else begin
        select A.cam_descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId, C.Login Username
        ,B.conversationId as conversationIdExists
        FROM ccCamps A INNER JOIN ccWhatsAppConversationsOut B WITH(NOLOCK)
        ON B.clientId = @clientId AND B.finishedBy = 0 and B.camId=A.cam_id
        INNER JOIN ccUsers C ON B.agentId = C.User_id;
    end  
END 
ELSE IF @action = 2 -- Get Outbound Templates
BEGIN
    IF @campId IS NOT NULL
    BEGIN
        DECLARE @AsociatedNumber VARCHAR(30) = (SELECT number from ccWhatsAppNumbers WHERE @campId = camp_id);
        SELECT * FROM ccWhatsAppOutboundTemplates WHERE AsociatedNumber = @AsociatedNumber AND Status = 1;
    END
END
END'
        EXEC(@sql);

        SET @process = '2 - JR 1211.0.14 -> SP ccsp_ConversationWASave, Se agrega update a la info del resumen de whats IN'
        SET @sql = '
        ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
, @conversationId     INT         = 0
, @inboundId          SMALLINT    = NULL
, @phoneACD           VARCHAR(50) = NULL
, @clientId           VARCHAR(25) = NULL
, @conversationStatus SMALLINT    = 0
, @tChatting          FLOAT    = 0
, @tWrapUp            SMALLINT    = 0
, @finishedBy         TINYINT     = 0
, @onQueue            BIT         = NULL
, @tQueue             SMALLINT    = 0
, @tTimeout           INT         = 0
, @disposition        SMALLINT    = 0
, @subDisposition     SMALLINT    = 0
, @agentId            INT         = 0
--VAR MESSAGES
, @messageId          VARCHAR(50) = NULL
, @messageIdUi        INT         = NULL
, @clientNum          VARCHAR(15) = NULL
, @vonageNum          VARCHAR(15) = NULL
, @typeMessage        VARCHAR(25) = ''''
, @content            NVARCHAR(MAX)= NULL
, @timeStampMessage   DATETIME    = NULL
, @timeStampMessageUTC DATETIME   = NULL
, @originType         VARCHAR(15) = NULL
, @currency           VARCHAR(10) = ''-''
, @price              VARCHAR(10) = ''0.00''
, @messageStatus      VARCHAR(15) = ''N/A''
, @listConversationsIds   VARCHAR(MAX) = NULL
, @IsAgentLoggingOut  BIT = 0
AS
BEGIN
    DECLARE @isEndConversation BIT;
    DECLARE @meanContactTypeId SMALLINT;
    DECLARE @conversationIdNew INT;
    SET @meanContactTypeId = 1;
    SET NOCOUNT ON;

    IF @action = 1
    BEGIN --new Conversation
        IF NOT EXISTS
(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock)
                        WHERE A.conversationId = @conversationId
                        )
        BEGIN
            INSERT INTO [ccWhatsAppConversations]
            (inboundId
            , phoneACD
            , clientId
            , conversationStatus
            , tChatting
            , tWrapUp
            , finishedBy
            , onQueue
            , tQueue
            , tTimeout
            , disposition
            , subDisposition
            , agentId
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

            IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId) BEGIN
                SELECT @conversationId = SCOPE_IDENTITY();
                SELECT @conversationId AS ConversationId;
            END
            ELSE BEGIN

                declare @conversationIdTemporal     INT;
                SELECT @conversationIdTemporal = SCOPE_IDENTITY();
                EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
                SELECT 0 AS ConversationId;
            END;

            --Save new request
            IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
                BEGIN
                    INSERT INTO ccWAOperatingSummary (InboundId, Request) VALUES (@inboundId, 1);
                END
            ELSE
                BEGIN
                    UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
                END
            RETURN(0);
        END
        ELSE
        BEGIN
            DECLARE @conversationStatusTemp INT = @conversationStatus;
            IF @conversationStatus in(17,18) BEGIN
                SET @conversationStatusTemp = 1
            END

            DECLARE @RequestDate DATETIME = NULL;
            SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversations WITH(NOLOCK) WHERE conversationId = @conversationId;

                INSERT INTO [ccWhatsAppConversations]
            (inboundId
            , phoneACD
            , clientId
            , conversationStatus
            , tChatting
            , tWrapUp
            , finishedBy
            , onQueue
            , tQueue
            , tTimeout
            , disposition
            , subDisposition
            , agentId
            , requestDate
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
            SELECT @conversationIdNew = SCOPE_IDENTITY();

            INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
                                                                , conversationIdAfter)
                VALUES (@conversationId, @conversationIdNew);
            --Save new request by reassign
UPDATE ccWAOperatingSummary SET Request = (Request + 1), Assigned = (Assigned - 1),EndedBySystem=EndedBySystem+1
WHERE InboundId = @inboundId

        EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship with(nolock) where conversationIdBefore = @conversationId;
        RETURN(0);
    END;
END;

ELSE IF @action = 2
BEGIN --save conversation Times
    DECLARE @conversationIdTemp INT;
    DECLARE @TablaTemp TABLE (conversationId INT, status bit);

    IF @listConversationsIds IS NOT NULL begin
        INSERT INTO @TablaTemp
        SELECT value,0
        FROM fn_RIASplitDelimited(@listConversationsIds, '','')
        where value is not null and value<>''''
    end
    else begin
        INSERT INTO @TablaTemp values(@conversationId,0)
    end

    UPDATE ccWhatsAppConversations
    SET
    conversationStatus = @conversationStatus
    , finishedBy = case when @conversationStatus in(4,10,17,18) then 2
    when @conversationStatus in(11) then 1
    else 0 end
    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

        WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
    BEGIN
        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

    IF @conversationStatus in(4,10,11,13,17,18) BEGIN
            DECLARE @conversationDateTemp INT;
            select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
            from ccWhatsAppConversations with(nolock) where conversationId = @conversationId;

            IF @conversationStatus = 13 BEGIN
                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
                END
            END
            ELSE IF @conversationStatus in(4,10,17,18) BEGIN --Save conversation Ended by system
                IF @conversationDateTemp > 0 BEGIN
                    UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
                END
                ELSE BEGIN
                        UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1) WHERE InboundId = @inboundId
                END
            END
            ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
                UPDATE ccWAOperatingSummary SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
            END
        END
        update @TablaTemp set status=1 where conversationId=@conversationIdTemp
    END

END;

ELSE IF @action = 3
BEGIN --save conversation Status
UPDATE ccWhatsAppConversations SET conversationStatus = @conversationStatus
    WHERE conversationId = @conversationId;
END;

ELSE IF @action = 4 BEGIN --save messages from conversation
IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock) WHERE A.conversationId=@conversationId)
        AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
    BEGIN
        IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
            (SELECT messageIdUi
                FROM ccWAMessagesConversations
                WHERE originType IN (''Agent'', ''Admin'')
                AND conversationId = @conversationId)
            BEGIN
                UPDATE ccWhatsAppConversations
                    SET FirstMessageAgent = @timeStampMessage
                    WHERE conversationId = @conversationId;
            END

        INSERT INTO [ccWAMessagesConversations](
                                            messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
                                            (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
        SELECT @messageId=SCOPE_IDENTITY()
        SELECT @messageId as MessageId
        RETURN (0)
    END
    ELSE BEGIN
        SELECT 0 AS MessageId
        RETURN (0)
    END
END;

    IF @action = 5
    BEGIN --save onQueue
        UPDATE ccWhatsAppConversations
                SET onQueue = 1,
                conversationStatus = @conversationStatus
        WHERE conversationId = @conversationId;
SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
        UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
    END;

ELSE IF @action = 6
BEGIN --save agent, assigdate and tqueue
    declare @agentIdTmp int
    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A with(nolock) where A.conversationId = @conversationId

    IF (@agentIdTmp is null or @agentIdTmp=0)
    BEGIN
        UPDATE ccWhatsAppConversations
                SET agentId = @agentId,
                assignDate = getdate(),
                conversationStatus = @conversationStatus
                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
        WHERE conversationId = @conversationId;

        SELECT @conversationId as conversationId
SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
declare @onQueueInt int

    IF @onQueue = 1 BEGIN
        UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1),@onQueueInt =OnQueue WHERE InboundId = @inboundId
        if @onQueueInt<=0 or exists(select * from ccWAOperatingSummary WHERE InboundId = @inboundId and OnQueue<0)begin

            select          
            @onQueueInt=count(case when onQueue =1 then 1 end)
            from ccWhatsAppConversations with(nolock)
            where inboundId= @inboundId
            and requestDate>=convert(date,getdate(),121)

            UPDATE ccWAOperatingSummary SET OnQueue = @onQueueInt WHERE InboundId = @inboundId

        end

    END
    END
END;

ELSE IF @action = 7
    BEGIN --update price message
        UPDATE ccWAMessagesConversations
                SET price = @price,
                    currency = @currency
        WHERE messageId = @messageId;
    END;

ELSE IF @action = 8
    BEGIN --update status message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversations
                    SET messageStatus = @messageStatus
            WHERE messageId = @messageId;
        END;
    END;

ELSE IF @action = 9
    BEGIN --Save last message time by conversationID
        IF not exists(SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) BEGIN
            INSERT INTO ccLastMessageAgentByConversation (conversationId,timeStampLastMessageAgent) VALUES (@conversationId,getDate())
        END;
        ELSE
            BEGIN
                UPDATE ccLastMessageAgentByConversation
                    SET timeStampLastMessageAgent = getDate()
                WHERE conversationId = @conversationId;
            END;
    END;

ELSE IF @action = 10
    BEGIN --drop and insert register by conversationID
        DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
    END;

ELSE IF @action = 11
    BEGIN --register desconnection agent by conversationID
        UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
    END;

ELSE IF @action = 12
    BEGIN --Obtain conversationsWA post MCS reset

        declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
        UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

        declare @from as datetime;-- = ''01-07-2022'';
        select @from = convert(datetime,convert(varchar(11),getdate()))
        set @from=DATEADD(dd,-1,@from);
            select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
            ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
            from ccWhatsAppConversations A with(nolock)
            left join ccWAMessagesConversations B on A.conversationId = B.conversationId
            left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp
            where A.requestDate >= @from 
                and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
            order by agentId desc, requestDate,timeStampMessage, inboundId, clientId 
    END;
ELSE IF @action = 13
    BEGIN ---Obtain agents ON STATUS READY
        WITH agents
        AS(
            SELECT c.User_id, c.fecha, c.currentStatus
            FROM ccLogAgentesDia c
            INNER JOIN 
            (
                SELECT User_id, MAX(fecha) max_time
                FROM ccLogAgentesDia with(nolock)
                where fecha>=CONVERT(date,getdate(),121)
                GROUP BY User_id
            ) AS t
            ON c.fecha = t.max_time
            AND c.User_id=t.User_id AND currentStatus in (3,34)
        ), usersByCampigns
        AS (
            select IdCampEsp, User_id from ccRIACampEspWG A
            Inner join ccRIAWorkGroupUsers B
            on A.IDWG = B.IDWG
            Inner join contactMeanIn C
            ON A.idCampEsp = C.inboundId
            where A.IDWG = 1 and A.Tipo = 0
            AND C.meanContactTypeId = 5
        )

        select DISTINCT A.User_Id from agents A
        left join usersByCampigns B on A.User_Id = B.User_Id
    END;

ELSE IF @action = 14
    BEGIN --register desconnection MCS
        INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
    END;

ELSE IF @action = 15
    BEGIN --update content message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversations
                    SET content = @content
            WHERE messageId = @messageId;
        END;
    END;

ELSE IF @action = 16
    BEGIN --update agent status for reassigning error message
            UPDATE ccWhatsAppConversations
            SET IsAgentLoggingOut = @IsAgentLoggingOut
            WHERE conversationId = @conversationId;
    END;

ELSE IF @action = 18 BEGIN
        DECLARE @dateNow DATETIME;
        SET @dateNow = DATEADD(HOUR, -23, GETDATE());

        UPDATE ccWhatsAppConversations
        SET finishedBy = 2, conversationStatus=17
        WHERE finishedBy = 0 AND requestDate <= @dateNow    
    END;
END;'
        EXEC(@sql);

        SET @process = '3 - JR 1211.0.14 -> SP ccsp_ConversationWASaveOut, Se agrega update a la info del resumen de whats OUT'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASaveOut] @action             INT
, @conversationId     INT         = 0
, @camId          SMALLINT    = NULL
, @phoneCam           VARCHAR(50) = NULL
, @clientId           VARCHAR(25) = NULL
, @conversationStatus SMALLINT    = 0
, @tChatting          FLOAT    = 0
, @tWrapUp            SMALLINT    = 0
, @finishedBy         TINYINT     = 0
, @onQueue            BIT         = NULL
, @tQueue             SMALLINT    = 0
, @tTimeout           INT         = 0
, @disposition        SMALLINT    = 0
, @subDisposition     SMALLINT    = 0
, @agentId            INT         = 0
--VAR MESSAGES
, @messageId          VARCHAR(50) = NULL
, @messageIdUi        INT         = NULL
, @clientNum          VARCHAR(15) = NULL
, @vonageNum          VARCHAR(15) = NULL
, @typeMessage        VARCHAR(25) = ''''
, @content            NVARCHAR(MAX)= NULL
, @timeStampMessage   DATETIME    = NULL
, @timeStampMessageUTC DATETIME   = NULL
, @originType         VARCHAR(15) = NULL
, @currency           VARCHAR(10) = ''-''
, @price              VARCHAR(10) = ''0.00''
, @messageStatus      VARCHAR(15) = ''N/A''
, @listConversationsIds   VARCHAR(MAX) = NULL
, @IsAgentLoggingOut  BIT = 0
AS
BEGIN
    DECLARE @isEndConversation BIT;
    DECLARE @meanContactTypeId SMALLINT;
    DECLARE @conversationIdNew INT;
    SET @meanContactTypeId = 1;
    SET NOCOUNT ON;

IF @action = 1
BEGIN --new Conversation
    IF NOT EXISTS (SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A with(nolock)
    WHERE A.conversationId = @conversationId)
    BEGIN
        INSERT INTO [ccWhatsAppConversationsOut]
        (camId, phoneCamp , clientId, conversationStatus, tChatting , tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId)
        VALUES(@camId, @phoneCam, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
        
        
        SELECT @conversationId = SCOPE_IDENTITY();
        SELECT @conversationId AS ConversationId;

--        Save new request
        IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId) BEGIN
           INSERT INTO ccWAOperatingSummaryOut (camId, Request) VALUES (@camId, 1);
        END
        ELSE BEGIN
            UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1) WHERE camId = @camId
        END
        RETURN(0);
    END
    ELSE BEGIN
        DECLARE @conversationStatusTemp INT = @conversationStatus;
        IF @conversationStatus in(17,18) BEGIN
            SET @conversationStatusTemp = 1
        END 

        DECLARE @RequestDate DATETIME = NULL;
        SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversationsOut WITH(NOLOCK) WHERE conversationId = @conversationId;

        INSERT INTO [ccWhatsAppConversationsOut]
            (camId, phoneCamp, clientId, conversationStatus, tChatting, tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId, requestDate)
        VALUES(@camId, @phoneCam, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, 
            @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
        SELECT @conversationIdNew = SCOPE_IDENTITY();

        INSERT INTO ccWhatsAppConversationsRelationshipOut (conversationIdBefore, conversationIdAfter)
        VALUES (@conversationId, @conversationIdNew);
        --Save new request by reassign
        UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1), Assigned = (Assigned - 1),EndedBySystem=EndedBySystem+1
        WHERE camId = @camId

    EXEC ccsp_ConversationWASaveOut @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

    SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationshipOut where conversationIdBefore = @conversationId;
    RETURN(0);
END;
END;

else IF @action = 2
BEGIN --save conversation Times
    DECLARE @conversationIdTemp INT;
    DECLARE @TablaTemp TABLE (conversationId INT, status bit);

    IF @listConversationsIds IS NOT NULL begin
        INSERT INTO @TablaTemp
        SELECT value,0
        FROM fn_RIASplitDelimited(@listConversationsIds, '','')
        where value is not null and value<>''''
    end
    else begin
        INSERT INTO @TablaTemp values(@conversationId,0)
    end
    
    UPDATE ccWhatsAppConversationsOut
    SET
    conversationStatus = @conversationStatus
    , finishedBy = case when @conversationStatus in(4,10,17,18) then 2
    when @conversationStatus in(11) then 1
        else 0 end
    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

    WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
    BEGIN
        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=6

        IF @conversationStatus in(4,10,11,13,17,18) BEGIN
            DECLARE @conversationDateTemp INT;
            select @camId = CamId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
            from ccWhatsAppConversationsOut where conversationId = @conversationId;

            IF @conversationStatus = 13 BEGIN
                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam with(nolock) where NumberClient = @clientId) BEGIN
                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@camId, @agentId, @conversationId, @clientId);
                END
            END
            ELSE IF @conversationStatus in(4,10,17,18) BEGIN --Save conversation Ended by system
                IF @conversationDateTemp > 0 BEGIN
                    UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
                END
                ELSE BEGIN
                        UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1) WHERE CamId = @camId
                END
            END
            ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
                UPDATE ccWAOperatingSummaryOut SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
            END
        END
        update @TablaTemp set status=1 where conversationId=@conversationIdTemp
    END

END;

else IF @action = 3
BEGIN --save conversation Status
    UPDATE ccWhatsAppConversationsOut SET conversationStatus = @conversationStatus WHERE conversationId = @conversationId;
END;

else IF @action = 4 BEGIN --save messages from conversation
    IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId)
        AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversationsOut A with(nolock) WHERE A.messageId=@messageId)
    BEGIN
        IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
            (SELECT messageIdUi
                FROM ccWAMessagesConversationsOut
                WHERE originType IN (''Agent'', ''Admin'')
                AND conversationId = @conversationId)
            BEGIN
                UPDATE ccWhatsAppConversationsOut
                    SET FirstMessageAgent = @timeStampMessage
                    WHERE conversationId = @conversationId;
            END

        INSERT INTO [ccWAMessagesConversationsOut](
                                            messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
                                            (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
        SELECT @messageId=SCOPE_IDENTITY()
       
       SELECT @camId=camId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId
        if not exists(select * from ccWAConversationsResult where camId=@camId)begin
            insert into ccWAConversationsResult values(@camId,0,0,0,0,0)
        end
        exec ccsp_ConversationWASaveOut @action=16,@messageStatus=@messageStatus,@conversationId=@conversationId
        
         SELECT @messageId as MessageId
        
        RETURN (0)
    END
    ELSE BEGIN
        SELECT 0 AS MessageId
        RETURN (0)
    END
END;

else IF @action = 5
BEGIN --save onQueue
    UPDATE ccWhatsAppConversationsOut
            SET onQueue = 1,
            conversationStatus = @conversationStatus
    WHERE conversationId = @conversationId;
    SELECT @camId = camId FROM ccWhatsAppConversationsOut where conversationId=@conversationId;
    UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue + 1) WHERE camId = @camId
END;

else IF @action = 6
BEGIN --save agent, assigdate and tqueue
    declare @agentIdTmp int
    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversationsOut A with(nolock) where A.conversationId = @conversationId
       
        UPDATE ccWhatsAppConversationsOut
                SET agentId = @agentId,
                assignDate = getdate(),
                conversationStatus = @conversationStatus
                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
        WHERE conversationId = @conversationId;

    SELECT @conversationId as conversationId
    SELECT @camId = camId,  @onQueue = onQueue FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;

    IF @onQueue = 1 BEGIN
     UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue - 1) WHERE camId = @camId   
    END
END;

 Else IF @action = 7
BEGIN --update price message
    UPDATE ccWAMessagesConversationsOut SET price = @price, currency = @currency WHERE messageId = @messageId;
END;
else IF @action = 8
BEGIN --update status message
    IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A with(nolock) 
        WHERE A.messageId=@messageId) <> ''read'' 
    BEGIN
        UPDATE ccWAMessagesConversationsOut
                SET messageStatus = @messageStatus
        WHERE messageId = @messageId;
        exec ccsp_ConversationWASaveOut @action=16,@messageStatus=@messageStatus,@conversationId=@conversationId
        
    END;
END;

else IF @action = 9
BEGIN --Save last message time by conversationID
    IF (SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversationOut A with(nolock) 
        WHERE A.conversationId=@conversationId) IS NULL BEGIN
        INSERT INTO ccLastMessageAgentByConversationOut (conversationId) VALUES (@conversationId)
    END;
    ELSE
        BEGIN
            UPDATE ccLastMessageAgentByConversationOut
                SET timeStampLastMessageAgent = getDate()
            WHERE conversationId = @conversationId;
        END;
END;

else IF @action = 10
BEGIN --drop and insert register by conversationID
    DELETE FROM ccLastMessageAgentByConversationOut WHERE conversationId = @conversationId;
END;

Else IF @action = 11
BEGIN --register desconnection agent by conversationID
    exec ccsp_ConversationWASaveOut @action = 9, @conversationId=@conversationId
END;

else IF @action = 12  BEGIN --Obtain conversationsWA post MCS reset
    declare @disconnectionIdTemp int = (select top 1 disconnectionId from [ccDisconnectionMCSOut] with(nolock) 
    where timeStampConnection is null order by timeStampDisconnection desc);
    UPDATE ccDisconnectionMCSOut SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

    declare @from as datetime;
    select @from = convert(datetime,convert(varchar(11),getdate()))
    set @from=DATEADD(dd,-1,@from);
        select A.conversationId, A.camId as inboundId, A.phoneCamp as phoneACD
        , A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, isnull(A.onQueue,0) onQueue, A.agentId, 
        isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, 
        isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
        ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
        from ccWhatsAppConversationsOut A with(nolock) 
        left join ccWAMessagesConversationsOut B with(nolock) on A.conversationId = B.conversationId
        left join [ccDisconnectionMCSOut] C with(nolock) on C.disconnectionId = @disconnectionIdTemp        
        where A.requestDate >= @from 
            and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
        order by agentId desc, requestDate,timeStampMessage, camId, clientId 
END;
else IF @action = 13
BEGIN ---Obtain agents ON STATUS READY
    WITH agents
    AS(
        SELECT c.User_id, c.fecha, c.currentStatus
        FROM ccLogAgentesDia c
        INNER JOIN 
        (
            SELECT User_id, MAX(fecha) max_time
            FROM ccLogAgentesDia with(nolock)
            where fecha>=CONVERT(date,getdate(),121)
            GROUP BY User_id
        ) AS t
        ON c.fecha = t.max_time
        AND c.User_id=t.User_id AND currentStatus in (3,34)
    ), usersByCampigns
    AS (
        select IdCampEsp, User_id from ccRIACampEspWG A
        Inner join ccRIAWorkGroupUsers B
        on A.IDWG = B.IDWG
        Inner join contactMeanOut C
        ON A.idCampEsp = C.camp_id
        where A.IDWG = 1 and A.Tipo = 1
        AND C.meanContactTypeId = 5
    )

    select DISTINCT A.User_Id from agents A
    left join usersByCampigns B on A.User_Id = B.User_Id
END;

else IF @action = 14
BEGIN --register desconnection MCS
    INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
END;
ELSE IF @action = 15
    BEGIN --update content message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversationsOut
                    SET content = @content
            WHERE messageId = @messageId;
        END;
    END;
ELSE IF @action = 16 BEGIN --update content message
    if @camId is null or @camId=0 begin 
        SELECT @camId=camId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId
    end
                
    if @messageStatus=''submitted'' begin
        update ccWAConversationsResult set SentMsg= SentMsg+1
    end
    else if @messageStatus=''delivered'' begin
        update ccWAConversationsResult set SentMsg= SentMsg-1,Delivered=Delivered+1
    end
    else if @messageStatus=''read'' begin
        update ccWAConversationsResult set Delivered=Delivered-1,ReadMsg=ReadMsg+1
    end
    else if @messageStatus=''rejected'' begin
        update ccWAConversationsResult set SentMsg= SentMsg-1,NotDelivered=NotDelivered+1
    end

    SELECT @messageId as MessageId
END;
ELSE IF @action = 17 BEGIN --update agent status for reassigning error message
    UPDATE ccWhatsAppConversationsOut
    SET IsAgentLoggingOut = @IsAgentLoggingOut
    WHERE conversationId = @conversationId;
END;
ELSE IF @action = 18 BEGIN
        DECLARE @dateNow DATETIME;
        SET @dateNow = DATEADD(HOUR, -23, GETDATE());

        UPDATE ccWhatsAppConversationsOut 
    SET finishedBy = 2, conversationStatus=17
        WHERE finishedBy = 0  AND requestDate <= @dateNow   
    END;
END;'
        EXEC(@sql);


        set @process = 'Dineria -- alter Table smsccoLogDial add Message'
    set @sql='if not exists (select * from sys.columns where name = N''Message'' and Object_ID = Object_ID(N''smsccoLogDial''))
begin
    alter Table smsccoLogDial add Message varchar(200) null
end
'
    EXEC(@sql)

    set @process = 'Dineria --  Add Column smsccoLogDial.Bill decimal'
    set @sql='if not exists (select * from sys.columns c 
inner join sys.types t on c.system_type_id=t.system_type_id
where c.name = N''Bill'' and c.Object_ID = Object_ID(N''smsccoLogDial'')
and t.name=''float''
)
begin
   alter Table smsccoLogDial alter Column Bill decimal(10,2) not null
end'
    EXEC(@sql)

SET @process = 'Hotfix SMS - Adding indexes'
SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_smsccoLogDial_2'' and object_id = OBJECT_ID(N''smsccoLogDial''))
begin
    CREATE INDEX IX_smsccoLogDial_2 ON smsccoLogDial(smsDate,statusSystemsId);
end'
   EXEC(@sql);

SET @process = 'Hotfix SMS - Create new table for messages without a status update'
        SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''UnchangedStatusSmsMessages'')
BEGIN
    CREATE TABLE UnchangedStatusSmsMessages (
        SystemApiId VARCHAR(100) NOT NULL,
        StatusSystemsId INT NOT NULL
    );
END;'
        EXEC(@sql);

set @process = 'Dineria -- CREATE IX_smsccoLogDial_3 '
    set @sql='if not exists (select * from sys.indexes where name = N''IX_smsccoLogDial_3'' and object_id = OBJECT_ID(N''smsccoLogDial''))
    begin
        CREATE NONCLUSTERED INDEX IX_smsccoLogDial_3
ON [dbo].[smsccoLogDial] ([SystemApiId])
    end
'
    EXEC(@sql)

   	
---------------------------------------- End fix/125.20231211.0.9 fix/125.20231211.0.14 - -------------------------------------------------        


----------------------------------------------------- BEGIN KR134000-SMS Masivo Muñoz, Ivan Martin  ----------------------------------------------------------------
    	SET @process = 'KR134000 Creación de tabla de status de referencia para email de mensajes sms. ';
    	SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N''ccSmsEmailResultStatus'')
                    BEGIN
                        CREATE TABLE ccSmsEmailResultStatus (
                            Id INT PRIMARY KEY IDENTITY(1,1),
                            Name VARCHAR(50) NOT NULL,
                            Description NVARCHAR(MAX) NOT NULL
                        );
                    END';
    	EXEC (@sql);

        SET @process = 'KR134000 Se insertan valores en la tabla';
        SET @sql = 'IF NOT EXISTS (SELECT * FROM ccSmsEmailResultStatus)
                    BEGIN
                        INSERT INTO ccSmsEmailResultStatus (Name, Description)
                        VALUES 
                            (''Success'', ''Message successfully sent''),
                            (''SendEmailError'', ''An error occurred while sending the message''),
                            (''AdminWithoutAssignedEmail'', ''Admin without assigned email''),
                            (''CenterwareWithoutOutboundEmail'', ''Centerware without outbound email'');
                    END;';
        EXEC (@sql);

        SET @process = 'KR134000 Creación de tabla para guardar mensajes';
        SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N''ccSmsResponseMessages'')
                    BEGIN
                        CREATE TABLE ccSmsResponseMessages (
					        Id INT PRIMARY KEY IDENTITY(1,1),
					        Destination VARCHAR(32) NOT NULL,
					        Source VARCHAR(32) NOT NULL,
					        Text NVARCHAR(MAX) NOT NULL,
					        Date DATETIME NOT NULL,
							SystemApiId VARCHAR(100) NOT NULL, 
							EmailAttempts INT NOT NULL DEFAULT 0,
							EmailResultStatus SMALLINT NOT NULL DEFAULT 0,
							CampaignId INT NOT NULL DEFAULT 0,
							SmsOutId INT NOT NULL DEFAULT 0
					    );
                    END';
        EXEC (@sql);

        SET @process = 'KR134000 Se crea índice para SystemApiId';
        SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N''IX_ccSmsResponseMessages_SystemApiId'' AND object_id = OBJECT_ID(N''ccSmsResponseMessages''))
                    BEGIN
                        CREATE INDEX IX_ccSmsResponseMessages_SystemApiId ON ccSmsResponseMessages (SystemApiId);
                    END';
        EXEC (@sql);
		
        SET @process = 'KR134000 Creación de tabla para hacer BulkCopy al terminar procesamiento de correos y actualizar estados.';
        SET @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N''ProcessingSmsClientMessagesEmails'')
                    BEGIN
                        CREATE TABLE ProcessingSmsClientMessagesEmails (
							Destination VARCHAR(32) NOT NULL,
							Source VARCHAR(32) NOT NULL,
							Text NVARCHAR(MAX) NOT NULL,
							Date DATETIME NOT NULL,
							SystemApiId VARCHAR(100) NOT NULL, 
							UserEmail NVARCHAR(255), 
							CampaignId INT DEFAULT 0, 
							EmailAttempts INT NOT NULL DEFAULT 0,
							EmailResultStatus SMALLINT NOT NULL DEFAULT 0,
						);
                    END';
        EXEC (@sql);

        SET @process = 'KR134000 Drop procedure ccspSmsClientsResponse';
        SET @sql = 'IF EXISTS(SELECT * FROM sys.procedures WHERE name = N''ccspSmsClientsResponse'')
                    BEGIN
                      DROP PROCEDURE ccspSmsClientsResponse
                    END';
        EXEC (@sql);

        SET @process = 'KR134000 Se crea procedimiento almacenado ccspSmsClientsResponse';
        SET @sql = 'CREATE PROCEDURE [dbo].[ccspSmsClientsResponse] 
					@Action SMALLINT, 
					@Destination VARCHAR(32) = NULL, 
					@Source VARCHAR(32) = NULL,
					@Text VARCHAR(MAX) = NULL,
					@Date DATETIME = NULL,
					@SystemApiId VARCHAR(100) = NULL,
					@CampaignId INT = 0,
					@SmsOutId INT = 0
					AS

					IF @Action IS NOT NULL BEGIN
					    IF @Action = 0 BEGIN        -- Insert new client message
					        INSERT INTO ccSmsResponseMessages (Destination, Source, Text, Date, SystemApiId, CampaignId, SmsOutId) VALUES (@Destination, @Source, @Text, @Date, @SystemApiId, @CampaignId, @SmsOutId)
					    END

					    IF @Action = 1 BEGIN        -- Get sender email information
					        SELECT valor FROM ccSettings WHERE setting_id = 98
					    END

					    IF @Action = 2 BEGIN        -- Get admin email information
					        SELECT LD.cam_id AS CampaignId, 
								   U.Login AS AdminName,
					               U.notificationEmail AS AdminEmail
					        FROM ccSmsResponseMessages RM
					        INNER JOIN smsccoLogDial LD WITH(NOLOCK) ON LD.registryClient = RM.SystemApiId
					        INNER JOIN ccSupervisorCam SC ON SC.cam_id = LD.cam_id 
					        INNER JOIN ccUsers U ON U.User_id = SC.user_id
					        WHERE RM.EmailResultStatus <> 1     -- Get all non successful email messages
							AND U.notificationEmail IS NOT NULL AND U.notificationEmail <> ''''
					        GROUP BY LD.cam_id, U.Login, U.notificationEmail;
					    END

					    IF @Action = 3 BEGIN        -- Get messages to send an email
					        SELECT  DISTINCT 
									RM.Destination, 
					                RM.Source, 
					                RM.Text, 
					                RM.Date, 
					                RM.SystemApiId, 
					                LD.cam_id AS CampaignId,
					                RM.EmailResultStatus,
					                RM.EmailAttempts
					        FROM ccSmsResponseMessages RM
					        INNER JOIN smsccoLogDial LD WITH(NOLOCK) ON LD.registryClient = RM.SystemApiId
					        WHERE  RM.EmailResultStatus <> 1 AND RM.CampaignId = LD.cam_id AND RM.SmsOutId = LD.smsout_id
					    END

					    IF @Action = 4 BEGIN        -- Update email attempts and status 
					        BEGIN TRY
					        BEGIN TRANSACTION;
								CREATE TABLE #TemporalProcessingSmsClientMessagesEmails
								(
									Destination VARCHAR(32) NOT NULL,
									Source VARCHAR(32) NOT NULL,
									Text NVARCHAR(MAX) NOT NULL,
									Date DATETIME NOT NULL,
									SystemApiId VARCHAR(100) NOT NULL,
									UserEmail NVARCHAR(255),
									CampaignId INT DEFAULT 0,
									EmailAttempts INT NOT NULL DEFAULT 0,
									EmailResultStatus SMALLINT NOT NULL DEFAULT 0
								);

								INSERT INTO #TemporalProcessingSmsClientMessagesEmails
								SELECT * FROM ProcessingSmsClientMessagesEmails;

					            UPDATE ccSmsResponseMessages
					            SET EmailAttempts = PM.EmailAttempts,
					                EmailResultStatus = PM.EmailResultStatus
					            FROM ccSmsResponseMessages RM
					            INNER JOIN #TemporalProcessingSmsClientMessagesEmails PM ON RM.SystemApiId = PM.SystemApiId
								
								DELETE FROM ProcessingSmsClientMessagesEmails
								WHERE SystemApiId IN (SELECT SystemApiId FROM #TemporalProcessingSmsClientMessagesEmails);
					            SELECT @@ROWCOUNT;
								DROP TABLE #TemporalProcessingSmsClientMessagesEmails;

								COMMIT TRANSACTION;
					            
					        END TRY
					        BEGIN CATCH
					            IF @@TRANCOUNT > 0
					                ROLLBACK TRANSACTION;

					            RETURN -1;
					        END CATCH
					    END
					END
					ELSE BEGIN
					    RAISERROR(''Invalid action specified.'', 16, 1);
					    RETURN -1;
					END';
        EXEC (@sql);
        
        ----------------------------------------------------- END KR134000-SMS Masivo Muñoz, Ivan Martin  ----------------------------------------------------------------

        SET @process = 'KR134014 - Se agrega opcion 15 para obtener los resultados de la validacion por segmentos, 
		KR134018 - se guarda el resultado de la validación la tabla SmsSegmentsValidationResult y se agrega poner el resultado de envio en 0 en la misma tabla rmd.RESULTADO_ENVIO = 0';
        SET @sql = 'ALTER procedure [dbo].[ccspLoadRegistrySegments] 
				@action int,
				@camId int = null,
				@typeTemplate int=2, --1 Segmentos, 2 Plantillas Archivos
				@phone varchar(32)=null,
				@templateId int=null,
				@callKey varchar(60)=null,
				@userId int=0,
				@msg varchar(160)=null,
				@smsout_id int=null,
				@SystemApiId varchar(100)=null,
				@statusSystemsId int=null,
				@dateStart datetime=null,
				@dateEnd datetime=null,
				@segmentIds varchar(max)='''',
				@columns varchar(max)=''*''
				as

				SET NOCOUNT ON;
				SET ANSI_WARNINGS OFF;

				DECLARE @sql VARCHAR(max)
				declare @today date=convert(date,getdate(),121)
				declare @monday datetime


				if @action=1 begin --List Segments
					select SegmentId,Name from ccSmsSegments where IsGlobal=1 or CampaignId=@camId
				end
				else if @action=2 begin  --ListColumnsTable
				    SELECT name
					FROM sys.columns
					WHERE object_id = OBJECT_ID(''SmsRemesasMuñoz'')
					and name like ''TELEFONOS[0-9]%''
				end
				else if @action=3 begin --List Plantillas
				    select TemplateId,Description as Name,MessageTemplate from ccSmsTemplate where Type=@typeTemplate
				end
				else if @action=4 begin
				    Select iDate DateStart,fDate DateEnd from ccSmsSchedules where cam_id=@camId
				end
				else if @action=5 begin
				    select top 1 * from SmsRemesasMuñoz
				end
				else if @action=6 begin
				    SET @columns = ''''
					SELECT @columns = @columns + ''isnull(max(len('' + COLUMN_NAME + '')),0)as '' + COLUMN_NAME + '',''
					FROM INFORMATION_SCHEMA.COLUMNS
					WHERE TABLE_NAME = ''SmsRemesasMuñoz''
					AND DATA_TYPE IN (''varchar'', ''nvarchar'', ''char'', ''nchar'');

					SET @columns = SUBSTRING(@columns, 0, len(@columns))
					SET @sql = ''select '' + @columns + '' from SmsRemesasMuñoz''

					--PRINT (@sql)
					EXEC (@sql)

				end
				else if @action = 7 begin
				    declare @valueInt104 int, @value17 varchar(100), @value247 varchar(100), @valueInt258 int
				    select 
				        @valueInt104 = case when setting_id = 104 then valor else @valueInt104 end,
				        @value17 = case when setting_id = 17 then valor else @value17 end,
				        @value247 = case when setting_id = 247 then valor else @value247 end,
				        @valueInt258 = case when setting_id = 258 then valor else @valueInt258 end
				    from VIEW_SETTINGS 
				    where setting_id in (104, 17, 247, 258)

				    select @phone = dbo.Verifica2(@phone, @valueInt104, @value17, 1)
				    if LEFT(@phone, 1) = ''E'' begin
				        select -1 as Result, ''is not cellPhone''
				        return -1;
				    end
				    if @valueInt258 <= 0 begin
				        select -2 as Result, ''Credit Sms Zero''
				    end
				    select 1 as Result, @value247 as ApiBackBone, MessageTemplate
				    from ccSmsTemplate 
				    where TemplateId = @templateId
				end
				else if @action=8 begin --smsOutSource
				    insert into smsOutSource (callkey,cam_id,sms_phoneNumber,sms_status,sms_attemps,user_id,sms_dateDial,dial_tels)
					values (@callKey,@camId,@phone,0,0,@userId,getdate(),''12345NNN'')
					select @smsout_id=SCOPE_IDENTITY()

					insert into smsoutSourceMessage(smsout_id,message)
					values(@smsout_id,@msg)

					select @smsout_id as smsoutId
				end
				else if @action=9 begin --smsccoLogDial
					insert into smsccoLogDial (smsout_id,cam_id,phone,smsDate,registryClient,SystemApiId,statusSystemsId,Bill,ProviderId)
					values (@smsout_id,@camId,@phone,getdate(),@callKey,@SystemApiId,@statusSystemsId,
					case when @statusSystemsId=0 then 0.7 else 0 end,0
					)	
				end
				else if @action=10 begin --ChangeSchedule
					delete from ccSmsSchedules where cam_id=@camId
					insert into ccSmsSchedules(cam_id,iDate,fDate) values(@camId,@dateStart,@dateEnd)
				end
				else if @action=11 begin --Carga los registros cargados
					truncate table ccSmsValidateRegistryWeek;
					SELECT @monday= DATEADD(DAY, -(DATEPART(WEEKDAY, @today) + @@DATEFIRST - 2) % 7, CAST(@today AS DATE))
					---------------Revisa la lista de registros es necesario moverlo a otro proceso para que lo tenga en la carga---------------------
					insert into ccSmsValidateRegistryWeek(registryClient,total,totaltoDay,loadRegistry)
					select registryClient,count(*) total,
					count(case when smsDate>=@today  then 1 end) totaltoday,
					0 loadRegistry
					from smsccoLogDial with(nolock)
					where smsDate>=@monday
					group by registryClient

				end
				else if @action in(12,13) begin --Validar Carga

					declare @segmentTable table(id int, status bit, segmentName VARCHAR(10))
					declare @segmentNames varchar(max)
					declare @conditionTable table(conditionId int,smsCondition varchar(max),DailyLimit int,WeeklyLimit int,status bit, SegmentName varchar(255))
					--declare @SmsRemesasId table (credictId int)
					create table #SmsRemesasId(creditId nvarchar(40), TDCT VARCHAR(max))
					create table #SmsRemesasIdTemp(creditId nvarchar(40), TDCT VARCHAR(max))
					create table #functionalState(creditId nvarchar(40), smsSent int)
					declare @FlagB table(credictId int, TDCT VARCHAR(max))
					------------Se obtiene los dias de la semana que han pasado
					DECLARE @lastMonday datetime, @WeekStart datetime;
					DECLARE @DaysFromWeek int, @LastMondaymonth int, @ActualMonth int
					DECLARE @actualDate datetime = getdate()
					SET @lastMonday = DATEADD(DAY, -(DATEPART(WEEKDAY, @actualDate) + 5) % 7, @actualDate);
					--select @lastMonday lastMonday, @actualDate actualDate

					SET @LastMondaymonth = DATEPART(MONTH, @lastMonday);
					SET @ActualMonth = DATEPART(MONTH, @actualDate);

					IF(@ActualMonth = @LastMondaymonth)
					BEGIN
						SELECT @DaysFromWeek = DATEDIFF(DAY, @lastMonday, @actualDate);
					END
					ELSE BEGIN
						SELECT @DaysFromWeek = DATEDIFF(DAY, DATEADD(DAY, 1 - DATEPART(DAY, @actualDate), @actualDate), @actualDate);
					END
					SET @WeekStart = CONVERT(datetime, CONVERT(date, @actualDate-@DaysFromWeek));
					

					--------------------------Comienza validacion--------------

					insert into @segmentTable
					select a.value,0 status, s.Name from dbo.fn_RIASplitDelimited(@segmentIds,'','') a
					inner join ccSmsSegments s on s.segmentId = a.value

					--Condicion para obtener solo los que coincidan con SegmentoMC
					SELECT @segmentNames = COALESCE(@segmentNames + '', '', '''') + QUOTENAME(a.segmentName, '''''''')
					FROM @segmentTable a

					--Tabla con todos los id de la tabla remesa que hacen match con los segmentos
					INSERT INTO #SmsRemesasIdTemp
					SELECT a.credito, a.TDCT from SmsRemesasMuñozDay a 
					INNER JOIN @segmentTable b on a.SegmentoMC = b.segmentName
					--Reseteamos todos los resultados para los segmentos
					UPDATE rmd SET rmd.RESULTADO = '''', rmd.RESULTADO_ID = 0
					FROM SmsRemesasMuñozDay rmd 
					INNER JOIN #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT

					--Actualizamos resultado para FLAG B
					UPDATE rmd SET rmd.RESULTADO = ''FLAG B'', rmd.RESULTADO_ID = 1, rmd.RESULTADO_ENVIO = 0
					FROM SmsRemesasMuñozDay rmd
					inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
					inner join ccSmsSegmentFlagB sfb on rmd.Fila = sfb.Validation
					WHERE rmd.RESULTADO_ID = 0 AND sfb.IsActive = 1

					--Actualizamos resultado para Telefono fijo y telefono no existe
					UPDATE rmd SET 
					rmd.RESULTADO = CASE 
						WHEN dbo.VerifySmsMCA(rmd.TELEFONOS1) = 3 THEN ''NO ES POSIBLE ENVIO, CELUAR NO SE ENCUENTRA EN IFT''
						WHEN dbo.VerifySmsMCA(rmd.TELEFONOS1) = 5 THEN ''TELEFONO FIJO''
						ELSE '''' END,
					rmd.RESULTADO_ID = dbo.VerifySmsMCA(rmd.TELEFONOS1),
					rmd.RESULTADO_ENVIO = 0
					FROM SmsRemesasMuñozDay rmd
					inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
					WHERE rmd.RESULTADO_ID = 0

					--Regla de Estado Funcional para segmento BMX_122
					UPDATE rmd SET rmd.RESULTADO = ''NO SE ENVIA POR REGLA DE ESTADO FUNCIONAL'', rmd.RESULTADO_ID = 4, rmd.RESULTADO_ENVIO = 0
					FROM SmsRemesasMuñozDay rmd
					inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
					WHERE rmd.RESULTADO_ID = 0 AND rmd.SegmentoMC = ''BMX_122''
					AND ESTADO_FUNCIONAL <> ''F''

					INSERT INTO #functionalState
					select rid.creditId, count(rid.creditId) from smsccoLogDial ld
					inner join #SmsRemesasIdTemp rid on rid.TDCT = ld.registryClient
					where ld.smsDate >= @WeekStart
					GROUP BY rid.creditId

					UPDATE rmd SET rmd.RESULTADO = ''NO SE ENVIA POR REGLA DE ESTADO FUNCIONAL'', rmd.RESULTADO_ID = 4, rmd.RESULTADO_ENVIO = 0
					FROM SmsRemesasMuñozDay rmd
					inner join #SmsRemesasIdTemp rid on rmd.TDCT = rid.TDCT
					inner join #functionalState fs on rmd.id_credito = fs.creditId
					WHERE rmd.RESULTADO_ID = 0 AND rmd.SegmentoMC = ''BMX_122''
					AND fs.smsSent >= 3;


					declare @subQuery nvarchar(max)
					
					SELECT @monday= DATEADD(DAY, -(DATEPART(WEEKDAY, @today) + @@DATEFIRST - 2) % 7, CAST(@today AS DATE))
					
					if not exists(select * from ccSmsValidateRegistryWeek)begin
						exec ccspLoadRegistrySegments @action=11
					end
					

					declare @conditionId int,@segmentId int,@SubConditionId int
					declare @conditionWhere varchar(max)
					declare @SubConditionWhere varchar(max),@LogicConector varchar(20)
					declare @DailyLimit int,@WeeklyLimit int
					declare @SegmentName varchar(255)

					DECLARE @Params NVARCHAR(MAX)
					SET @Params = N''@WeeklyLimit int,@DailyLimit int'';
					
				---Lista de @segmentIds
				while exists(select * from @segmentTable where status=0) begin
					select top 1 @segmentId=id from @segmentTable where status=0		
					set @conditionId=0
					-------------------------------- Revisa las condiciones por segmentId --------------------------------
					while exists(select * from ccSmsConditions where SegmentId=@segmentId and ConditionId>@conditionId) begin
						
						SELECT @SegmentName = [Name] from ccSmsSegments where SegmentId = @segmentId

						select top 1
						@DailyLimit=DailyLimit,	@WeeklyLimit=WeeklyLimit,@conditionId=ConditionId,
						@conditionWhere= PrimaryField+LogicOperator
						+case when isnull(ComparisonValue,'''') <>'''' then ComparisonValue else''(''+ ComparisonField end 					
						+case when isnull(ComparisonValue,'''') <>'''' or  isnull(ArithmeticOperator,'''')='''' or isnull(Value,'''')=''''then '''' else isnull(ArithmeticOperator,'''')+isnull(Value,'''') end 
						+case when isnull(ComparisonValue,'''') <>'''' then '''' else'')'' end 
						from ccSmsConditions where SegmentId=@segmentId and ConditionId>@conditionId
						
						set @SubConditionId=0
						while exists(select * from ccSmsSubconditions where ConditionId=@conditionId and SubconditionId>@SubConditionId) 
						begin
						
							select top 1
							@LogicConector=LogicConector,
							@SubConditionId=SubconditionId,
							@SubConditionWhere=
							PrimaryField+LogicOperator
							+case when isnull(ComparisonValue,'''') <>'''' then ComparisonValue else''(''+ ComparisonField end 					
							+case when isnull(ComparisonValue,'''') <>'''' or  isnull(ArithmeticOperator,'''')='''' or isnull(Value,'''')='''' then '''' else isnull(ArithmeticOperator,'''')+isnull(Value,'''') end
							+case when isnull(ComparisonValue,'''') <>'''' then '''' else'')'' end 
							from ccSmsSubconditions where ConditionId=@conditionId and SubconditionId>@SubConditionId

							set @conditionWhere=@conditionWhere+'' ''+ @LogicConector+'' '' +@SubConditionWhere

							
						end
							
						insert into @conditionTable values(@conditionId,@conditionWhere,@DailyLimit,@WeeklyLimit,0, @SegmentName)	
					end 
					-------------------------------- Termina las condiciones por segmentId --------------------------------
					update @segmentTable set status=1 where id=@segmentId
				end
				while exists(select * from @conditionTable where status=0) begin		
					select top 1 
					@conditionId=conditionId, @DailyLimit=DailyLimit, @WeeklyLimit=WeeklyLimit,	@conditionWhere=smsCondition,
					@SegmentName = SegmentName
					from @conditionTable 
					where status=0
					
					set @subQuery= ''select A.id_credito, A.TDCT from SmsRemesasMuñozDay A with(nolock)
					left join ccSmsValidateRegistryWeek B on A.credito=B.registryClient and B.total<@WeeklyLimit and B.totaltoDay<@DailyLimit
					where  SegmentoMC in ('''''' + @SegmentName + '''''') AND RESULTADO_ID = 0 AND '' + @conditionWhere	
					print(@subQuery)
					insert into #SmsRemesasId
					EXEC sp_executesql @subQuery,@Params,@WeeklyLimit,@DailyLimit;
					update @conditionTable set status=1 where @conditionId=conditionId
				end

				--Actualizamos los ids que no coindiden
				UPDATE rmd SET rmd.RESULTADO = ''CUENTA CON T. Celular para envio de sms'' , rmd.RESULTADO_ID = 6
				FROM SmsRemesasMuñozDay rmd
				INNER JOIN #SmsRemesasId rid on rid.TDCT = rmd.TDCT
				WHERE RESULTADO_ID = 0;

				--Actualizamos todo lo que no cumple
				UPDATE rmd SET rmd.RESULTADO = ''NO CUMPLE CON REGLA DE CORTE'' , rmd.RESULTADO_ID = 2, rmd.RESULTADO_ENVIO = 0
				FROM SmsRemesasMuñozDay rmd
				INNER JOIN #SmsRemesasIdTemp rid on rid.TDCT = rmd.TDCT
				WHERE RESULTADO_ID = 0;
					
				if @action=12 begin
					declare @countValidate int,@nonValid int
					select @countValidate=count(1) from SmsRemesasMuñozDay A with(nolock)
					inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID = 6

					select @nonValid=count(1) from SmsRemesasMuñozDay A with(nolock)
					inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID <> 6

					INSERT INTO SmsSegmentsValidationResult(id_credito, credito, TELEFONOS1, TDCT, RESULTADO, RESULTADO_ID, validation_date)
					SELECT A.id_credito, A.credito, TELEFONOS1, A.TDCT, A.RESULTADO, A.RESULTADO_ID, GETDATE() FROM SmsRemesasMuñozDay A
					inner join #SmsRemesasIdTemp b on A.TDCT = b.TDCT

					select @countValidate as ValidRecords,@nonValid as InvalidRecords
				end
				else begin
					DECLARE @tableName VARCHAR(20) = ''TEMPO_''+convert(varchar(10),@camId)
					DECLARE @columnsWithTypes VARCHAR(MAX)
					DECLARE @newColumns VARCHAR(MAX)
					DECLARE @createTable VARCHAR(MAX)
					DECLARE @insertInto VARCHAR(MAX)

					SELECT 
						@columnsWithTypes = COALESCE(@columnsWithTypes + '', '', '''') + 
						QUOTENAME(COLUMN_NAME) + '' '' + DATA_TYPE + 
						CASE 
							WHEN DATA_TYPE IN (''char'', ''varchar'', ''nchar'', ''nvarchar'', ''binary'', ''varbinary'') THEN ''('' + 
								CASE 
									WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN ''MAX'' 
									ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR)
								END + '')''
							WHEN DATA_TYPE IN (''decimal'', ''numeric'') THEN ''('' + CAST(NUMERIC_PRECISION AS VARCHAR) + '','' + CAST(NUMERIC_SCALE AS VARCHAR) + '')''
							ELSE ''''
						END,
						@newColumns = COALESCE(@newColumns + '', '', '''') + QUOTENAME(COLUMN_NAME)
					FROM INFORMATION_SCHEMA.COLUMNS
					WHERE TABLE_NAME = ''SmsRemesasMuñozDay'' AND COLUMN_NAME in (select value from dbo.fn_RIASplitDelimited(@columns,'',''))

					SET @createTable = ''IF EXISTS (SELECT * FROM sys.tables WHERE name = N'''''' + @tableName +'''''')
					BEGIN
						DROP TABLE '' + @tableName + ''
					END
						CREATE TABLE '' + @tableName + '' (
							Record_id INT IDENTITY(1,1) PRIMARY KEY, ActiveRecord BIT DEFAULT(0),PhoneStatus int, callout_id int, DataPhone varchar(100), cal_Key varchar(40), cal_telephone varchar(40) default(''''''''), 
							'' + @columnsWithTypes + '');''
					print(@createTable)
					EXEC (@createTable)
					
					set @sql=''INSERT INTO '' + @tableName + '' (PhoneStatus, callout_id, DataPhone, cal_Key, cal_telephone,'' + @newColumns + '')
					select 0 PhoneStatus,0 callout_id,convert(varchar(100),'''''''') as DataPhone, A.TDCT, TELEFONOS1, ''+@newColumns+''
					from SmsRemesasMuñozDay A with(nolock) inner join #SmsRemesasIdTemp b on a.TDCT = b.TDCT where a.RESULTADO_ID = 6''
					print(@sql)
					exec(@sql)
					set @sql = ''IF EXISTS (SELECT * FROM sys.tables WHERE name = N'''''' + @tableName +''_ids'''')
					BEGIN
						DROP TABLE '' + @tableName + ''_ids
					END
					Create table '' + @tableName + ''_ids (Record_id int)'';
					exec(@sql)
				end
				drop table #SmsRemesasId
				drop table #SmsRemesasIdTemp
				drop table #functionalState
				end
				else if @action =14 begin 
					select MessageTemplate from ccSmsTemplate where TemplateId=@templateId
				end

				else if @action =15 begin --Obtener resultados de validación por segmentos

					DECLARE @counter int = 0
					DECLARE @ActualDay DATETIME = GETDATE();
					DECLARE @FirstDayMonth DATETIME = DATEADD(MONTH, DATEDIFF(MONTH, 0, @ActualDay),0)
					DECLARE @DayCounter DATETIME;
					DECLARE @WeekCount int = 0;

					WHILE @counter < DAY(@ActualDay)
					BEGIN
						SET @DayCounter =  DATEADD(DAY, @counter, @FirstDayMonth)
						IF DATEPART(WEEKDAY,@DayCounter) = 2
							SET @WeekCount = @WeekCount + 1
						print @DayCounter
						set @counter = @counter + 1
					END

					IF DATEPART(WEEKDAY, @FirstDayMonth) <> 2 BEGIN
						SET @WeekCount = @WeekCount + 1
					END

					declare @segments table(segmentName VARCHAR(10))

					insert into @segments
					select s.Name from dbo.fn_RIASplitDelimited(@segmentIds,'','') a
					inner join ccSmsSegments s on s.segmentId = a.value

					select	id_credito AS id_credit, credito AS credit, GETDATE() as snapshot_date, MESES_VENCIDOS as expired_month, SEG_CUENTA as seg_account,
							FILA as seg_row, LOCACION as [location], DIA_CORTE as cut_day, SegmentoMC as segment_mc, @WeekCount as [week], DATEPART(WEEKDAY, @ActualDay) week_day,
							TELEFONOS1 as phones1, RESULTADO as result, ISNULL(ESTADO_FUNCIONAL, '''') as functional_state, ISNULL(CORTE_REAL, '''')  as real_cut
					from SmsRemesasMuñozDay rmd
					inner join @segments s on rmd.SegmentoMC = s.segmentName;
					
				end';
        EXEC (@sql);

        ------------------------------------------------------BEGIN Ivan Martin Fix CW-8576 ---------------------------------------------------------------------
		SET @process = 'KR134000 Drop procedure ccspOutboundSmsMessage';
        SET @sql = 'IF EXISTS(SELECT * FROM sys.procedures WHERE name = N''ccspOutboundSmsMessage'')
                    BEGIN
                      DROP PROCEDURE ccspOutboundSmsMessage
                    END';
        EXEC (@sql);

        SET @process = 'KR134000 Added acion 13';
        SET @sql = 'CREATE procedure [dbo].[ccspOutboundSmsMessage] 
					@action int,
					@camId int = null,
					@SentMsg int=null,
					@smsoutIds varchar(max)=null,
					@SystemApiId varchar(100)=null,
					@statusSystemsId int =null,
					@InsufficientBalance int=null,
					@date datetime =null,
					@addingCampaign bit = null,
					@statusIds varchar(max)=null
					as
					declare @sql varchar(max)
					if @action=1 begin
					    set @date=getdate()

					    if @addingCampaign = 1 begin
					        select distinct cast(c. cam_id as int) as CamId,
					                        cam_descripcion as [Name],
					                        cam_procesando as [Start],
					                        0 AS MessageQuantity
					        from ccCamps c
					        where CampType=7 and c.IDArea is not null and c.cam_id=@camId
					    end
					    else begin
					        SELECT DISTINCT CAST(c. cam_id AS INT) AS CamId,
					                        cam_descripcion AS Name,
					                        cam_procesando AS Start,
					                        ISNULL((w.new + w.pro),0) AS MessageQuantity
					        FROM ccCamps c
					        LEFT JOIN ccSmsSchedules s ON s.cam_id = c.cam_id
					        LEFT JOIN ccCampsNvosCB  w ON c.cam_id = w.id
					        WHERE CampType=7 AND c.IDArea IS NOT NULL AND(@camId IS NULL or @camId=0 OR c.cam_id = @camId)
					        AND @date BETWEEN dateadd(hh,-12,iDate) AND dateadd(hh,12,fDate)
					    end
					end
					else if @action=2 begin
					    select tz_offset from ccTimeZones ORDER BY tz_id
					end
					else if @action=3 begin
					    select cast(camId as int) CamId,SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected 
					    from ccSmsConversationsResult where ( @camId is null or camId=@camId)
					end
					else if @action=4 begin
					    truncate table ccSmsConversationsResult
					end
					else if @action=5 begin
					    if not exists(select * from ccSmsConversationsResult where camId=@camId) begin
					        insert into ccSmsConversationsResult values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance,0)
					    end
					    else begin
					        update ccSmsConversationsResult set SentMsg=SentMsg+@SentMsg 
					        ,InsufficientBalance=InsufficientBalance+@InsufficientBalance
					        where camId=@camId
					    end
					end
					else if @action=6 begin 
					    set @sql=''delete from smsWorkingTable where smsout_id in(''+@smsoutIds+'')''
					    exec (@sql)
					end
					else if @action=7 begin
					    DECLARE @TemporalProcessingSmsStatusUpdates TABLE(SystemApiId VARCHAR(100) PRIMARY KEY, StatusSystemsId INT, IsCharged BIT)
					    INSERT INTO @TemporalProcessingSmsStatusUpdates
					    SELECT SystemApiId, StatusSystemsId, IsCharged FROM ProcessingSmsStatusUpdates

					    DECLARE @ChargedMessages INT = (SELECT SUM(CASE WHEN IsCharged = 1 THEN 1 ELSE 0 END) FROM @TemporalProcessingSmsStatusUpdates)
					    IF @ChargedMessages <> 0
					    BEGIN
					        UPDATE ccSettings2 WITH(TABLOCK) SET valor = valor - @ChargedMessages WHERE setting_id = 258 AND valor > 0;
					    END

					    DECLARE @UpdatingSmsWorkingTable TABLE(SystemApiId VARCHAR(100) PRIMARY KEY, OldStatusSystemsId INT, NewStatusSystemsId INT, CampaignId INT)
					    INSERT INTO @UpdatingSmsWorkingTable
					    SELECT S.SystemApiId, S.StatusSystemsId, T.StatusSystemsId, S.cam_id FROM smsccoLogDial S WITH(NOLOCK)
					    INNER JOIN @TemporalProcessingSmsStatusUpdates T ON S.SystemApiId = T.SystemApiId
					            
					    ;WITH CTE AS (
					    SELECT
					        CampaignId,
					        COUNT(CASE WHEN NewStatusSystemsId = 0 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 0 THEN 1 END) AS SentMsg,
					        COUNT(CASE WHEN NewStatusSystemsId = 1 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 1 THEN 1 END) AS Delivered,
					        COUNT(CASE WHEN NewStatusSystemsId = 2 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 2 THEN 1 END) AS NotDelivered,
					        COUNT(CASE WHEN NewStatusSystemsId = 3 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 3 THEN 1 END) AS RecipientRejected,
					        COUNT(CASE WHEN NewStatusSystemsId = 4 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 4 THEN 1 END) AS CarrierRejected,
					        COUNT(CASE WHEN NewStatusSystemsId = 5 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 5 THEN 1 END) AS Exception,
					        COUNT(CASE WHEN NewStatusSystemsId = 6 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 6 THEN 1 END) AS InsufficientBalance

					    FROM @UpdatingSmsWorkingTable
					    GROUP BY CampaignId
					    )

					    MERGE INTO ccSmsConversationsResult AS Target
					    USING CTE AS Source ON Target.camId = Source.CampaignId
					    WHEN MATCHED THEN
					        UPDATE SET
					            Target.SentMsg = CASE WHEN (Target.SentMsg + Source.SentMsg) < 0 THEN 0 ELSE (Target.SentMsg + Source.SentMsg) END,
					            Target.Delivered = CASE WHEN (Target.Delivered + Source.Delivered) < 0 THEN 0 ELSE (Target.Delivered + Source.Delivered) END,
					            Target.NotDelivered = CASE WHEN (Target.NotDelivered + Source.NotDelivered) < 0 THEN 0 ELSE (Target.NotDelivered + Source.NotDelivered) END,
					            Target.RecipientRejected = CASE WHEN (Target.RecipientRejected + Source.RecipientRejected) < 0 THEN 0 ELSE (Target.RecipientRejected + Source.RecipientRejected) END,
					            Target.CarrierRejected = CASE WHEN (Target.CarrierRejected + Source.CarrierRejected) < 0 THEN 0 ELSE (Target.CarrierRejected + Source.CarrierRejected) END,
					            Target.Exception = CASE WHEN (Target.Exception + Source.Exception) < 0 THEN 0 ELSE (Target.Exception + Source.Exception) END,
					            Target.InsufficientBalance = CASE WHEN (Target.InsufficientBalance + Source.InsufficientBalance) < 0 THEN 0 ELSE (Target.InsufficientBalance + Source.InsufficientBalance) END

					    WHEN NOT MATCHED BY TARGET THEN
					    INSERT (camId, SentMsg, Delivered, NotDelivered, RecipientRejected, CarrierRejected, Exception, InsufficientBalance)
					    VALUES (Source.CampaignId, Source.SentMsg, Source.Delivered, Source.NotDelivered, Source.RecipientRejected, Source.CarrierRejected, Source.Exception, Source.InsufficientBalance);

					    UPDATE smsccoLogDial SET Bill = (CASE WHEN T.StatusSystemsId IN (0, 1, 2) THEN 0.7 ELSE 0 END),
					                                statusSystemsId = T.StatusSystemsId
					    FROM smsccoLogDial S WITH(NOLOCK)
					    INNER JOIN @TemporalProcessingSmsStatusUpdates T ON T.SystemApiId = S.SystemApiId

					    DELETE FROM ProcessingSmsStatusUpdates 
					    WHERE SystemApiId IN (SELECT SystemApiId FROM @TemporalProcessingSmsStatusUpdates);

						DECLARE @Result INT = @@ROWCOUNT;

						IF (SELECT valor FROM ccSettings2 WHERE setting_id = 268) = 1 BEGIN
							UPDATE MCA SET RESULTADO_ENVIO = S.StatusSystemsId
							FROM SmsRemesasMuñozDay MCA
							INNER JOIN smsccoLogDial S WITH(NOLOCK) ON S.registryClient = MCA.TDCT
						END
					    SELECT @Result;
					end
					else if @action=8 begin
					    update smsccoLogDial set Bill=0.70 where smsDate>=@date and statusSystemsId not in(3,4,5,6)
					end
					else if @action=9 begin
					    CREATE TABLE #TempSmsOutIds (
					    smsout_id INT
					    );

					    INSERT INTO #TempSmsOutIds (smsout_id)
					    SELECT DISTINCT wt.smsout_id
					    FROM smsWorkingTable wt
					    JOIN smsOutSource os WITH(NOLOCK) ON wt.smsout_id = os.smsout_id
					    LEFT JOIN smsccoLogDial cco WITH(NOLOCK) ON wt.smsout_id = cco.smsout_id
					    WHERE wt.cam_id=@camId and wt.sms_status IN(1,2) 
					    AND cco.smsout_id IS NULL;
					            

					    UPDATE wt
					    SET wt.sms_status = 0
					    FROM smsWorkingTable wt WITH(NOLOCK)
					    JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

					    DROP TABLE #TempSmsOutIds;
					end
					else if @action=10 begin
					    SELECT COUNT(*) FROM smsWorkingTable with (NOLOCK) WHERE cam_id = @camId
					end
					else if @action=12 begin
					    IF EXISTS (SELECT 1 FROM ccSmsSchedules WITH (NOLOCK) WHERE cam_id = @camId 
					    AND GETDATE() BETWEEN dateadd(hh,-12,iDate) AND dateadd(hh,12,fDate)
					    )
					    AND EXISTS (SELECT 1 FROM smsWorkingTable WITH (NOLOCK) WHERE cam_id = @camId)
					    BEGIN
					        SELECT CAST(0 AS BIT);
					        RETURN;
					    END
					    ELSE BEGIN
					        UPDATE ccCamps SET cam_procesando = 0 WHERE cam_id = @camId
					        SELECT CAST(1 AS BIT);
					        RETURN;
					    END
					end
					else if @action=13 begin
						BEGIN TRY
						    UPDATE MCA
						    SET RESULTADO_ENVIO = LD.statusSystemsId
						    FROM SmsRemesasMuñozDay MCA
						    INNER JOIN smsccoLogDial LD ON LD.registryClient = MCA.TDCT
						    WHERE MCA.TDCT IN (SELECT value FROM dbo.fn_RIASplitDelimited (@smsoutIds, '',''));

						    SELECT ''1'' AS Result;
						END TRY
						BEGIN CATCH
						    SELECT ''-1'' AS Result;
						END CATCH;
					end';
        EXEC (@sql);


		------------------------------------------------------END Ivan Martin Fix CW-8576---------------------------------------------------------------------

		------------------------------------------------------BEGIN MACL Fix carga segmentos-----------------------------------------------

SET @process = 'KR134015 - Se agrega cambio para obtener si es carga por segmento';
        SET @sql = 'ALTER procedure [dbo].[ccsp_RIALogPhones]
		@load_id int,
		@Type smallint,
		@GenCSV bit = 1, -- 0:100 / 1:todos
		@isKolob bit = 0,
		@PageIndex      INT = 0,
		@PageSize       INT = 0,
		@option SMALLINT = NULL
		as
		set nocount ON

		declare @CaseType varchar(2000), @sql nvarchar(MAX), @nType char(5), @MovType SMALLINT, @language int, @LoadBySegment varchar(1)
		SELECT @language = cs.valor FROM dbo.ccSettings AS cs WHERE cs.setting_id = 27;
		declare @PageStart int,@PageEnd int

		SELECT @LoadBySegment = CAST(ISNULL(LoadBySegment,''0'') as varchar) from ccRIALoading where load_id = @load_id
		IF(@option = 0)
		BEGIN
			select CAST(@LoadBySegment as bit) as LoadBySegment
			return 0;
		END

		select @CaseType = '''', @nType = right(''0000''+cast(@Type as varchar(5)), 5)

		if @nType like ''%____1%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov in (0,8)
			''

		if @nType like ''%___1_%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov in(-1,0,8) 
			''

		if @nType like ''%__1__%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov IN (1) 
			''

		if @nType like ''%_1___%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov IN (1,4) 
			''

		if @nType like ''%1____%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 2 ''

		if @CaseType = '''' and @nType <> 0
			return(0)

		if @nType like ''%____1%''
			select @CaseType = @CaseType + ''  or telefono<>'''''''' and crlp.tipoMov = 0''

		select @PageStart=@PageSize*(@PageIndex-1),@PageEnd=@PageSize*@PageIndex

		IF(@option = 1)
		BEGIN	
			SET @sql = ''SELECT count(*) AS listSize FROM (
		select crlp.load_id
		from ccRIALogPhones AS crlp 
		where crlp.load_id = @load_id'' 
		+ @CaseType +'') tmp '' +
		case @GenCSV when 0 then ''WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd'' else '''' end
					--EXEC(@sql);
			
				Exec sp_executesql @sql
						 , N''@PageStart int,@PageEnd int,@language int,@load_id int''
						 , @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id
					RETURN (0);
				END
				ELSE 
				BEGIN
						IF(@isKolob = 1)
						BEGIN

						declare @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200), @typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
						@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @typeUpdatedRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200), @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max);


						select @typeDescriptionPhoneBlocked=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-num''
						select @typeDescriptionPhoneUpdated=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-num''
						select @typeIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-incorrect-records''
						select @typeBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-records''
						select @typeDescriptionPhoneNotLoaded=translate from tableLangueDbLoader where languageId=@language and tag=''type-not-loaded-num''

						select @typeDescriptionPhoneBlackList=translate from tableLangueDbLoader where languageId=@language and tag=''description-dnc-list''
						select @descriptionIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-incorrect-records''
						select @descriptionBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-blocked-records''
						select @typeUpdatedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-records''
						select @descriptionInternationalPortNotFound=TRANSLATE from tableLangueDbLoader where languageId=@language and tag=''type-camp-no-international-port''


						select @column=translate from tableLangueDbLoader where languageId=@language and tag=''column-file-field''

						select @headerPhone=header_phone,@headerPhone2=header_phone2,@headerPhone3=header_phone3,@headerPhone4=header_phone4 
						,@headerPhone5=header_phone5
						from fileHeadersPhoneLoad where load_id=@load_id
			
							set @CaseType=case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' END
							SET @sql = '';with result as(
							SELECT * FROM (select  
							ROW_NUMBER() OVER(ORDER BY crlp.cal_key ASC) AS RowNum,
							crlp.load_id,
							crlp.cal_key, 
							crlp.telefono AS phone,
							CASE
								WHEN crlp.tipoMov = 2 THEN @typeUpdatedRecords	
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @typeIncorrectRecords
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @typeBlockedRecords
								WHEN crlp.tipoMov in(-1,0) THEN @typeDescriptionPhoneNotLoaded
								WHEN crlp.tipoMov in(8) THEN @descriptionInternationalPortNotFound
								WHEN crlp.tipoMov in (1,4)  THEN @typeDescriptionPhoneBlocked
								WHEN crlp.keyTranslate is not null THEN isnull(tlan.translate,crlp2.descTipoMov)
							ELSE 
								crlp2.descTipoMov  
							END AS Tipo,
							case when CHARINDEX('''':'''',crlp.motivo)=0 then 0 else
								convert(int,substring(crlp.motivo ,CHARINDEX('''':'''',crlp.motivo)-1 ,1))
							end
							 AS ColumnFile, 
							CASE  WHEN crlp.tipoMov = 2 THEN ''''N/A'''' 
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @descriptionIncorrectRecords
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @descriptionBlockedRecords
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-camp-no-international-port'''') THEN  @descriptionInternationalPortNotFound
									WHEN crlp.tipoMov in (1,4) THEN @typeDescriptionPhoneBlackList
									WHEN crlp.keyTranslate is not null THEN tlan.translate 
							ELSE crlp.motivo END AS motivo,
							CAST('' + @LoadBySegment + '' as BIT) AS LoadBySegment
							from ccRIALogPhones AS crlp 
							INNER JOIN dbo.ccRIACATLogPhones AS  crlp2 ON crlp.tipoMov = crlp2.tipoMov
							left join tableLangueDbLoader tlan on tlan.tag=crlp.keyTranslate and tlan.languageId=@language
							where crlp.load_id = @load_id '' 				
							+ @CaseType +'') tmp '' +
							case @GenCSV when 0 then '' WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd '' else '''' end +'' 
							) 
							select  crlp.RowNum,
							crlp.load_id,
							crlp.cal_key, 
							crlp.phone,
							crlp.Tipo,
							case when crlp.ColumnFile=1 then @headerPhone
							when crlp.ColumnFile=2 then @headerPhone2
							when crlp.ColumnFile=3 then @headerPhone3
							when crlp.ColumnFile=4 then @headerPhone4
							when crlp.ColumnFile=5 then @headerPhone5
							else '''''''' end ColumnFile,
							crlp.motivo
							from result crlp ''
			END
			ELSE
			BEGIN
				set @sql = ''select '' + case @GenCSV when 0 then ''top 100 '' else '''' end 
				+ ''load_id, cal_key, telefono, tipoMov, motivo from ccRIALogPhones AS crlp where load_id = @load_id '' 
				+ @CaseType
			END  
			--PRINT(@sql);



			Exec sp_executesql @sql, N''@PageStart int,@PageEnd int,@language int,@load_id int, @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200),
			@typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
			@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200)
			, @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max), @typeUpdatedRecords varchar(200)''
			, @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id,@column=@column,@typeDescriptionPhoneNotLoaded=@typeDescriptionPhoneNotLoaded
			,@typeDescriptionPhoneBlocked=@typeDescriptionPhoneBlocked,@typeDescriptionPhoneUpdated=@typeDescriptionPhoneUpdated,@typeDescriptionPhoneBlackList=@typeDescriptionPhoneBlackList
			,@typeBlockedRecords=@typeBlockedRecords,@typeIncorrectRecords=@typeIncorrectRecords,@descriptionBlockedRecords=@descriptionBlockedRecords,@descriptionIncorrectRecords=@descriptionIncorrectRecords,
			 @descriptionInternationalPortNotFound= @descriptionInternationalPortNotFound 
			,@headerPhone=@headerPhone,@headerPhone2=@headerPhone2,@headerPhone3=@headerPhone3,@headerPhone4=@headerPhone4,@headerPhone5=@headerPhone5,@typeUpdatedRecords=@typeUpdatedRecords
	
		return(0)
		END
		set nocount OFF';
        EXEC (@sql);

		SET @process = 'KR134013 - cambios para obtener solo registros dentro de horario cuando fue carga por segmento';
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000
    AS
    SET NOCOUNT ON

    DECLARE @prioridad VARCHAR(8)
    DECLARE @batchsizeIni AS INT
    DECLARE @batchsizeFin AS INT
    DECLARE @rango AS DECIMAL
    DECLARE @rowstoInsert AS INT
    DECLARE @campType AS INT
    DECLARE @recordsQuantitySetting VARCHAR(8)
    DECLARE @settingValueP1 VARCHAR(25)

    SET @rowstoInsert = 0
    SET @batchsizeIni = 0
    SET @batchsizeFin = 0
    SET @rango = 0.00

    IF EXISTS(SELECT * FROM sys.views WHERE NAME = ''VIEW_SETTINGS'') BEGIN
        SELECT @recordsQuantitySetting = [valor] FROM VIEW_SETTINGS WHERE setting_id = 257;
        IF(@recordsQuantitySetting IS NOT NULL AND @recordsQuantitySetting <> '''') BEGIN
            SELECT @settingValueP1 = SUBSTRING(@recordsQuantitySetting, CHARINDEX(''|'', @recordsQuantitySetting)+1, LEN(@recordsQuantitySetting)),
                   @top = (SUBSTRING(@settingValueP1, 1, CHARINDEX(''|'', @settingValueP1)-1));
        END ELSE SET @top = 3000
    END ELSE SET @top = 3000

    SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
    FROM ccCampsPrioridadTel WITH (NOLOCK)
    WHERE cam_id = @camp_id

    SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @camp_id;

    DELETE ccUploadTemporal
    WHERE cam_id = @camp_id

    IF(@campType = 7)
    BEGIN
            CREATE TABLE #tempsmsOutSource (Id INT PRIMARY KEY identity, smsout_id INT, cam_id INT, sms_phoneNumber VARCHAR(19), sms_status TINYINT, sms_dateDial DATETIME, cal_keyw VARCHAR(40), iTimeZone INT, iTimeZone_summer INT, iTimeZone2 INT, iTimeZone_summer2 INT, iTimeZone3 INT, iTimeZone_summer3 INT, iTimeZone4 INT, iTimeZone_summer4 INT, iTimeZone5 INT, iTimeZone_summer5 INT, list_id INT, sms_dateDialEnd datetime, isSegmentLoad bit)

            CREATE NONCLUSTERED INDEX [IX_TempSMSO] ON [dbo].[#tempsmsOutSource] ([Id] ASC)
                WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

            CREATE TABLE #smsoutIdSource (smsout_id INT NOT NULL PRIMARY KEY)

            CREATE TABLE #smsoutIdSource2 (smsout_id INT NOT NULL PRIMARY KEY)

			--UPDATING TABLES BEFORE LOADING
			DECLARE @date datetime = GETDATE()
			UPDATE smsOutSource SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1
			UPDATE smsWorkingTable SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1

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
             iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
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
                        NULL END iTimeZone_summer5, list_id, sms_dateDialEnd, ISNULL(isSegmentLoad, 0)
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
                    WITH (TABLOCKX) (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
                    SELECT smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, 0, 0 ,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad
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

    SET NOCOUNT OFF
    ';
        EXEC (@sql);
		---------------------------------------------------------END MACL-------------------------------------------------------

		------------------------------------------------------BEGIN Rod Salazar ---------------------------------------------------------------------

		SET @process = 'CW-8588 se borra sp ccsp_RIAUpdateCamConfig'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIAUpdateCamConfig'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_RIAUpdateCamConfig
	END'

EXEC(@sql)

SET @process = 'CW-8588 se crea sp ccsp_RIAUpdateCamConfig'
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
	DECLARE @timesDiscardActual int = -1, @camCanceledActual int = -1, @recordIvrActual int = -1
	
	SELECT @timesDiscardActual = timesDiscard, @camCanceledActual = camcanceled, @recordIvrActual = recordIvr FROM ccCamps WHERE cam_id = @cam_id
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

			IF(@isCreating = 1) 
			BEGIN
				DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
				IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');
				IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
			END

			IF(@isCreating = 2) 
			BEGIN
				IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''recordIvr'') and dataInfo = 1) AND @recordIvrActual is null DELETE FROM #ccCampsTable WHERE columnInfo IN (''recordIvr'');
				IF EXISTS (SELECT 1 FROM #ccCampsTable where columnInfo in (''camCanceled'') and dataInfo = 4) and @camCanceledActual is null DELETE FROM #ccCampsTable WHERE columnInfo IN (''camCanceled'');				
			END
			
					
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

	set nocount off

'

EXEC(@sql)


SET @process = 'CW-8588 se borra sp ccsp_RIAConfCamp'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIAConfCamp'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_RIAConfCamp
	END'

EXEC(@sql)

SET @process = 'CW-8588 se crea sp ccsp_RIAConfCamp'
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
			,ISNULL(CamCanceled, 4) CamCanceled
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

SET @process = 'Corrección sp ccsp_GalateaAdminGetPermissions borrar sp'
SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_GalateaAdminGetPermissions'')
	BEGIN
		DROP PROCEDURE ccsp_GalateaAdminGetPermissions
	END'

EXEC(@sql)

SET @process = 'Corrección sp ccsp_GalateaAdminGetPermissions crear sp'
SET @sql = '

CREATE PROCEDURE ccsp_GalateaAdminGetPermissions
    @user_id varchar(255),
    @Type int
    AS
    set nocount on

    declare @isRoot int;

    if exists (Select Rol_id from ccUsers A join ccUsers_Roles B on A.User_id = B.User_id where A.User_id = @user_id and rol_id = 7) set @isRoot = 1 else set @isRoot = 0;
    print @isRoot

    IF @isRoot = 1
    BEGIN
        Select 
        User_id as AgentId, 
        Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
        1-cast(dialMask & 1 as int) as AllowCellPhoneCalls,
        1-cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
        1-cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
        cast( xfermask as int) as AllowTransferCalls, 
        cast(CanChangeStatus as tinyint) CanChangeStatus,
        cast(XferAgents as tinyint) XferAgents,
        ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
        cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
        ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
        ISNULL(agentsPermissions.AllowUnassign, 0) AS AllowUnassign,
        ISNULL(agentsPermissions.AllowSpam, 0 ) AS AllowSpam,
        ISNULL(agentsPermissions.AllowPlayRecordsOnCallHistory, 0) AS AllowPlayRecordsOnCallHistory,
        cast(AllowDeleteRecord as int) as AgentPermissionDelete,
        AllowMarks as AllowMarks,
        ISNULL(allowSelectCamp,0) as AllowSelectCamp
    from 
        ccUsers users
        left join ccRIAAgentsPermissions agentsPermissions on
        users.User_id = agentsPermissions.AgentId
    where 
       tipoUser_id = 1
    return(0)
    END
    ELSE
    BEGIN
        Select distinct
        A.User_id as AgentId, 
        Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
        1-cast(dialMask & 1 as int) as AllowCellPhoneCalls,
        1-cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
        1-cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
        cast( xfermask as int) as AllowTransferCalls, 
        cast(CanChangeStatus as tinyint) CanChangeStatus,
        cast(XferAgents as tinyint) XferAgents,
        ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
        cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
        ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
        ISNULL(agentsPermissions.AllowUnassign, 0) AS AllowUnassign,
        ISNULL(agentsPermissions.AllowSpam, 0 ) AS AllowSpam,
        ISNULL(agentsPermissions.AllowPlayRecordsOnCallHistory, 0) AS AllowPlayRecordsOnCallHistory,
        cast(AllowDeleteRecord as int) as AgentPermissionDelete,
        AllowMarks as AllowMarks,
        ISNULL(allowSelectCamp,0) as AllowSelectCamp
    from 
        ccUsers A
    join ccRIAWorkGroupUsers B on 
        A.user_id = B.user_id
    left join ccRIAAgentsPermissions agentsPermissions on
        A.User_id = agentsPermissions.AgentId
    where 
        tipoUser_id = 1 and 
        IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
    return(0)
    END
set nocount off
    
	'

EXEC(@sql)


		------------------------------------------------------END Rod Salazar ---------------------------------------------------------------------


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
