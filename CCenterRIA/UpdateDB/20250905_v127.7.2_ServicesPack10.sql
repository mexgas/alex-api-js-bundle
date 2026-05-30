/*******************************/
/*******************************/
/*
Author: Marco Antonio García
Date: 2025/06/23
Description: Demo/Sprint2
Database: CCenterRia
Required version: 127.2
IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
USE CCenterRIA;

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
    SET @version = 127 --**********actualizar a 124 sin fix
    SET @versionfix = 7
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


	--- BEGIN Services Pack 10 ----------


    SET @process = 'ALTER procedure [dbo].ccsp_OUTGetNewJobs Se agrega los cal_telefono al cal_telefono5'
    SET @sql = 'ALTER procedure [dbo].ccsp_OUTGetNewJobs
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
    phone1 varchar(19),
    phone2 varchar(19),
    phone3 varchar(19),
    phone4 varchar(19),
    phone5 varchar(19),
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

DECLARE @maxCps INT = 30;
DECLARE @nSeconds INT = 25;

--select @topCount=valor from ccSettings where setting_id=94
select @maxCps=valor from ccSettings with(nolock) where setting_id=238

if @maxCps<=0 set @maxCps=30 --

SET @topCount = @maxCps*@nSeconds --se carga para tener registros suficiente por el tiempo que el outbound va buscar registros   

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID
declare @isVerano varchar(max)
set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' END


if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount as varchar )
select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';
    
    select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, cs.cal_telefono,cs.cal_telefono2,cs.cal_telefono3,cs.cal_telefono4,cs.cal_telefono5 ,
    W.cal_status, W.cal_fechaDial, W.user_id,''
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


select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, cs.cal_telefono,cs.cal_telefono2,cs.cal_telefono3,cs.cal_telefono4,cs.cal_telefono5 ,
W.cal_status, W.cal_fechaDial, W.user_id,''
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
SELECT W.callout_id, W.cam_id, W.cal_telefono,cs.cal_telefono,cs.cal_telefono2,cs.cal_telefono3,cs.cal_telefono4,cs.cal_telefono5,
W.cal_status, W.cal_fechaDial, W.user_id,''
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
case when tz is null then '''''''' else phone1 end as tel,
case when tz2 is null then '''''''' else phone2 end as tel2,
case when tz3 is null then '''''''' else phone3 end as tel3,
case when tz4 is null then '''''''' else phone4 end as tel4,
case when tz5 is null then '''''''' else phone5 end as tel5,
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
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_GetCommonNotReadyStates]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GetCommonNotReadyStates]
    @superId INT,
    @agentIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------
    -- 1. Agentes
    ---------------------------------
    DECLARE @AgentIdsTemp TABLE (AgentId INT PRIMARY KEY);

    INSERT INTO @AgentIdsTemp(AgentId)
    SELECT VALUE
    FROM dbo.fn_RIASplitDelimited(@agentIds, '','')
    WHERE VALUE IS NOT NULL;

    DECLARE @agentCount INT = (SELECT COUNT(*) FROM @AgentIdsTemp);

    ---------------------------------
    -- 2. Settings
    ---------------------------------
    DECLARE @TypeSetting INT;
    DECLARE @NotReadybyCampACD INT;
    DECLARE @Setting28 INT;

    SELECT @TypeSetting = valor FROM ccSettings WHERE setting_id = 87;
    SELECT @NotReadybyCampACD = valor FROM ccSettings WHERE setting_id = 135;
    SELECT @Setting28 = valor FROM ccSettings WHERE setting_id = 28;



     

    ---------------------------------
    -- 3. Base con NumEvents y filtro IsSup optimizado
    ---------------------------------
    ;WITH NotReadyBase AS (
        SELECT
            ag.AgentId,
            a1.TipoNotReady_id,
            dbo.NeventsNRdisp(ag.AgentId, a1.TipoNotReady_id, GETDATE()) AS NumEvents,
            a1.IsSup,
            a1.Descripcion,
            a1.Time_Acum,
            a1.Time_xEv,
            a1.Pas_Sup,
            a1.NextStatus,
            g.frame
        FROM @AgentIdsTemp ag
        INNER JOIN ccTipoNotReady a1
            ON a1.TipoNotReady_id > 0
           AND a1.StatusTipoNotReady = 1
           -- Filtrado IsSup según setting87 y setting28
           AND (
                (@TypeSetting = 1 AND a1.IsSup = @Setting28)
                OR (@TypeSetting = 2)
                OR (@TypeSetting = 3 AND a1.IsSup = 1)
                OR (@TypeSetting = 4)
           )
        INNER JOIN ccRIAnotreadyGraph ngr
            ON ngr.TipoNotReady_id = a1.TipoNotReady_id
        INNER JOIN ccRIAGraphics g
            ON g.graphic_id = ngr.graphic_id
        WHERE
            -- Filtrado por campanas solo si setting135 = 1 y TypeSetting = 4
            (
                @NotReadybyCampACD = 0
                OR @TypeSetting <> 4
                OR EXISTS (
                    SELECT 1
                    FROM ccUnavailableRelation ur
                    WHERE ur.idunavailable = a1.TipoNotReady_id
                    AND (
                        (ur.type = 0 AND ur.idCampACD IN (
                            SELECT inbound_id
                            FROM ccInboundAgentes
                            WHERE user_id = ag.AgentId
                        ))
                        OR
                        (ur.type = 1 AND ur.idCampACD IN (
                            SELECT cam_id
                            FROM ccCampsAgente
                            WHERE user_id = ag.AgentId
                        ))
                    )
                )
            )
      UNION
       
           SELECT
                ag.AgentId,
                a1.TipoNotReady_id,
                dbo.NeventsNRdisp(ag.AgentId, a1.TipoNotReady_id, GETDATE()) AS NumEvents,
                a1.IsSup,
                a1.Descripcion,
                a1.Time_Acum,
                a1.Time_xEv,
                a1.Pas_Sup,
                a1.NextStatus,
                a3.frame                       
            FROM 
                ccTipoNotReady a1
            CROSS JOIN @AgentIdsTemp ag 
            INNER JOIN 
                ccRIAnotreadyGraph a2 ON a1.TipoNotReady_id = a2.tiponotready_id
            INNER JOIN 
                ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
            INNER JOIN 
                ccsupervisor_notready snd ON a1.tiponotready_id = snd.tiponotready_id AND snd.user_id = @superId            
            WHERE 
                a1.IsSup=1
                AND a1.StatusTipoNotReady = 1
            
    )

    ---------------------------------
    -- 4. Filtro supervisor (setting87)
    ---------------------------------
    SELECT
        TipoNotReady_id,
        Descripcion,
        Time_Acum,
        Time_xEv,
        Pas_Sup,
        NextStatus,
        frame,
        IsSup,
        CASE 
            WHEN MIN(NumEvents) IS NULL THEN 1
            WHEN MIN(NumEvents) = ''n'' OR MIN(NumEvents) > 0 THEN 1
            ELSE 0
        END AS expiredAttempts
    FROM NotReadyBase nrb
    WHERE
        (
            @TypeSetting <> 4
            OR EXISTS (
                SELECT 1
                FROM ccsupervisor_notready snd
                WHERE snd.TipoNotReady_id = nrb.TipoNotReady_id
                  AND snd.user_id = @superId
            )
        )
    GROUP BY
        TipoNotReady_id,
        Descripcion,
        Time_Acum,
        Time_xEv,
        Pas_Sup,
        NextStatus,
        frame,
        IsSup
    HAVING COUNT(DISTINCT AgentId) = @agentCount
    ORDER BY TipoNotReady_id;

END'
    exec (@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_RIACATNotReadyTypes]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIACATNotReadyTypes]
    @TipoNotReady_id varchar(5)='''',
    @Descripcion varchar(30)='''',
    @Time_Acum varchar(10)='''',
    @Time_xEv varchar(5)='''',
    @Pas_Sup varchar(2)='''',
    @NextStatus varchar(5)='''',
    @graphic_id varchar(5)='''',
    @Type varchar(1)='''',
    @IsSup int = null,
    @super_id as int = null,
    @agent_id as int = null
    AS
    set nocount on
    DECLARE @sql nvarchar(4000), @graph nvarchar(1000), @id smallint, @newGraph smallint
    DECLARE @NotReadybyCampACD INT;
    
    if @Type=0
    begin
        SELECT TipoNotReady_id, Descripcion FROM ccTipoNotReady WITH(NOLOCK) WHERE StatusTipoNotReady=1
        return(0)
    end
    
    if @Type=6 -- LOAD by setting
    begin
        SELECT @Type = valor FROM ccSettings WHERE setting_id = 87;
        SELECT @NotReadybyCampACD = valor FROM ccSettings WHERE setting_id = 135;
        CREATE TABLE #NotReadyData (
            TipoNotReady_id INT,
            NumEvents VARCHAR(6)
        );
        IF (@NotReadybyCampACD = 0)
        BEGIN
            INSERT INTO #NotReadyData (TipoNotReady_id, NumEvents)
            SELECT 
                a1.TipoNotReady_id,
                dbo.NeventsNRdisp(@agent_id, a1.tiponotready_id, GETDATE()) AS NumEvents
            FROM 
                ccTipoNotReady a1
            where a1.StatusTipoNotReady = 1
        END
        ELSE IF (@NotReadybyCampACD = 1)
        BEGIN
            INSERT INTO #NotReadyData (TipoNotReady_id, NumEvents) -- Ticket #7674 
            SELECT 
                t.TipoNotReady_id,
                MAX(t.NumEvents) AS NumEvents
            FROM (
                SELECT 
                    a1.TipoNotReady_id,
                    dbo.NeventsNRdisp(@agent_id, a1.tiponotready_id, GETDATE()) AS NumEvents
                FROM 
                    ccTipoNotReady a1
                INNER JOIN 
                    ccUnavailableRelation a4 ON a4.idunavailable = a1.tiponotready_id
                WHERE 
                    a1.TipoNotReady_id > 0 
                    AND a1.IsSup = 0
                    AND a4.idCampACD IN (
                        SELECT DISTINCT(inbound_id) FROM ccInboundAgentes WHERE user_id = @agent_id
                    )
                    AND a4.type = 0
    
                UNION ALL
    
                SELECT 
                    a1.TipoNotReady_id,
                    dbo.NeventsNRdisp(@agent_id, a1.tiponotready_id, GETDATE()) AS NumEvents
                FROM 
                    ccTipoNotReady a1
                INNER JOIN 
                    ccUnavailableRelation a4 ON a4.idunavailable = a1.tiponotready_id
                WHERE 
                    a1.TipoNotReady_id > 0 
                    AND a1.IsSup = 0
                    AND a4.idCampACD IN (
                        SELECT DISTINCT(cam_id) FROM ccCampsAgente WHERE user_id = @agent_id
                    )
                    AND a4.type = 1

                     
           union  -- Change for TT#7674

           SELECT 
                a1.TipoNotReady_id,
                dbo.NeventsNRdisp(@agent_id, a1.tiponotready_id, GETDATE()) AS NumEvents
            FROM 
                ccTipoNotReady a1
            INNER JOIN 
                ccRIAnotreadyGraph a2 ON a1.tiponotready_id = a2.tiponotready_id
            INNER JOIN 
                ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
            INNER JOIN 
                ccsupervisor_notready snd ON a1.tiponotready_id = snd.tiponotready_id AND snd.user_id = @super_id            
            WHERE 
                a1.IsSup=1
                AND a1.StatusTipoNotReady = 1
            ) t
            GROUP BY 
                t.TipoNotReady_id;
        END
    
        IF @Type = 4 
        BEGIN
            SELECT 
                a1.TipoNotReady_id, 
                a1.Descripcion, 
                a1.Time_Acum, 
                a1.Time_xEv, 
                a1.Pas_Sup, 
                a1.NextStatus, 
                frame, 
                a1.IsSup,
                CASE 
                    WHEN nr.NumEvents IS NULL THEN 1
                    WHEN (nr.NumEvents = ''n'' OR nr.NumEvents > 0) THEN 1 
                    ELSE 0 
                END AS expiredAttempts 
            FROM 
                ccTipoNotReady a1
            INNER JOIN 
                ccRIAnotreadyGraph a2 ON a1.tiponotready_id = a2.tiponotready_id
            INNER JOIN 
                ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
            INNER JOIN 
                ccsupervisor_notready snd ON a1.tiponotready_id = snd.tiponotready_id AND snd.user_id = @super_id
            INNER JOIN 
                #NotReadyData nr ON a1.tiponotready_id = nr.TipoNotReady_id
            WHERE 
                a1.TipoNotReady_id > 0 
                AND a1.StatusTipoNotReady = 1
           

        END
        ELSE 
        BEGIN
            SELECT 
                a1.TipoNotReady_id, 
                a1.Descripcion, 
                a1.Time_Acum, 
                a1.Time_xEv, 
                a1.Pas_Sup, 
                a1.NextStatus, 
                frame, 
                a1.IsSup,
                CASE 
                    WHEN nr.NumEvents IS NULL THEN 1
                    WHEN (nr.NumEvents = ''n'' OR nr.NumEvents > 0) THEN 1 
                    ELSE 0 
                END AS expiredAttempts
            FROM 
                ccTipoNotReady a1
            INNER JOIN 
                ccRIAnotreadyGraph a2 ON a1.tiponotready_id = a2.tiponotready_id
            INNER JOIN 
                ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
            LEFT JOIN 
                #NotReadyData nr ON a1.tiponotready_id = nr.TipoNotReady_id
            WHERE 
                a1.TipoNotReady_id > 0 
                AND a1.IsSup = CASE 
                    WHEN @Type = 1 THEN (SELECT valor FROM ccSettings WHERE setting_id = 28)
                    WHEN @Type = 2 THEN a1.IsSup 
                    ELSE 1 
                END
                AND a1.StatusTipoNotReady = 1;
        END
    
        DROP TABLE #NotReadyData;
        return(0)
    end
    
    if @Type=1 -- LOAD
    begin
        select @NotReadybyCampACD = valor from ccsettings where setting_id = 135
        
        if (@NotReadybyCampACD = 0)
        begin
            SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
            FROM ccTipoNotReady a1 
            inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
            inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
            where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
        end
        else if (@NotReadybyCampACD = 1)
            begin
                SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
                FROM ccTipoNotReady a1 
                inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
                inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
                inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
                where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
                and a4.idCampACD in (select distinct(cam_id) from ccSupervisorCam where user_id = @super_id)
                AND a4.type = 0
                union
                SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
                FROM ccTipoNotReady a1 
                inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
                inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
                inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
                where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
                and a4.idCampACD in (select distinct(cam_id) from ccSupervisorCam where user_id = @super_id)
                AND a4.type = 1
            end
        return(0)
    end
    
    If @Type=2 -- INSERT
    begin
        if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Descripcion)
        begin       
            select 1
            return(0)
        end
        if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=0 and Descripcion=@Descripcion)
            begin       
                select @id=TipoNotReady_id from ccTipoNotReady where Descripcion=@Descripcion
                update ccTipoNotReady set 
                Time_acum=@Time_Acum,
                Time_xEv=@Time_xEv,
                Pas_Sup=@Pas_Sup,
                NextStatus=@NextStatus,
                IsSup=@IsSup,
                StatusTipoNotReady=1
                where Descripcion=@Descripcion
                If not exists(select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
                    Begin
                        insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
                    End
        
                insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
                return(0)       
            end
        If not exists(select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
        Begin
            insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
        End
    
        insert ccTipoNotReady (Descripcion, Time_Acum, Time_xEv, Pas_Sup, NextStatus, IsSup,StatusTipoNotReady) 
        select @Descripcion, @Time_Acum, @Time_xEv, @Pas_Sup, @NextStatus, @IsSup,1
        select @id=SCOPE_IDENTITY()
        insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
        return(0)
    end
    
    If @Type=3 -- DELETE
    begin
        exec ccsp_AdminNotready 3,0,@TipoNotReady_id,0
        delete ccRIANotReadyGraph where tipoNotReady_id = @TipoNotReady_id
        update ccTipoNotReady set StatusTipoNotReady=0 where tipoNotReady_id = @TipoNotReady_id
    end
    
    if(@Type=4) --UPDATE
    begin
    
        if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Descripcion)
        begin       
            select @Descripcion=''''
        end
    
        update ccTipoNotReady set 
        Descripcion=case @Descripcion when '''' then Descripcion else @Descripcion end,
        Time_Acum=case @Time_Acum when '''' then Time_Acum else @Time_Acum end,
        Time_xEv=case @Time_xEv when '''' then Time_xEv else @Time_xEv end,
        Pas_Sup=case @Pas_Sup when '''' then Pas_Sup else @Pas_Sup end,
        NextStatus=case @NextStatus when '''' then NextStatus else @NextStatus end,
        IsSup=ISNULL(@IsSup,IsSup)
        where TipoNotReady_id=@TipoNotReady_id
    
        IF ISNULL(@graphic_id,'''') not in('''')
        BEGIN
            If not exists (select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
            begin
                insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
            end
    
            select @graph = graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
            update ccRIANotReadyGraph set graphic_id=cast(@graph as smallint) where TipoNotReady_id=cast(@TipoNotReady_id as tinyint)
        END
        return(0)
    end
    
    if @Type = 7 -- LOAD
        begin
            SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
            FROM ccTipoNotReady a1 
            inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
            inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
            where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
            return(0)
        end
    
    if @Type = 8 -- Check admin permission
        begin
            select @Type = valor from ccSettings where setting_id = 87
    
            if @Type = 4 begin
                SELECT CAST( count(snd.TipoNotReady_id) AS BIT) AS hasPermission
                FROM ccTipoNotReady a1 
                inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
                inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
                inner join ccsupervisor_notready snd on (a1.tiponotready_id = snd.tiponotready_id and snd.user_id = @super_id)
                where a1.TipoNotReady_id = @TipoNotReady_id 
                and a1.StatusTipoNotReady=1
            end
            else begin
                SELECT CAST(1 AS bit) AS  hasPermission
            end
        end'
    exec (@sql)    

------------------------ BEGIN Giovanni Martinez ------------------------
set @process = 'Se altera fGet_CampAcd_Area para mostrar totales de whatsapp'
set @sql = '
ALTER FUNCTION fGet_CampAcd_Area (@user int, @tipo int)  
RETURNS @camps TABLE (cam_id int)  
AS  
BEGIN  
    IF (SELECT login FROM ccUsers WHERE user_id = @user) = ''root''        
        SET @user = 0  --solo se corrigio para el usuario root  
    
    IF @tipo = 3 AND @user = 0   
        SET @tipo = 1  
    IF @tipo = 4 AND @user = 0   
        SET @tipo = 2    
    
    IF @tipo = 1 BEGIN        
        INSERT @camps SELECT DISTINCT c.cam_id         
        FROM ccUsers u JOIN ccCamps c ON u.IDArea = c.IDArea         
        WHERE ISNULL(u.user_id, 0) = CASE WHEN @user > 0 THEN @user ELSE ISNULL(u.user_id, 0) END        
    END    
    ELSE IF @tipo = 2 BEGIN        
        INSERT @camps SELECT DISTINCT c.Inbound_id         
        FROM ccUsers u JOIN ccInbound c ON u.IDArea = c.IDArea         
        WHERE ISNULL(u.user_id, 0) = CASE WHEN @user > 0 THEN @user ELSE ISNULL(u.user_id, 0) END        
    END  
    
    IF @tipo = 3 BEGIN --Solo trae los seleccionados en el wg        
        INSERT @camps SELECT DISTINCT wgCamAcd.IdCampEsp        
        FROM ccUsers u WITH(NOLOCK)     
        INNER JOIN ccCamps c WITH(NOLOCK) ON u.IDArea = c.IDArea     
        INNER JOIN ccRIAWorkGroupUsers wg WITH(INDEX(IX_ccRIAWorkGroupUsers_I), NOLOCK) ON wg.User_id = u.User_id     
        INNER JOIN ccRIACampEspWG wgCamAcd WITH(INDEX(IX_ccRIACampEspWG_2), NOLOCK) ON wgCamAcd.IDWG = wg.IDWG AND tipo = 1        
        WHERE u.User_id = @user        
    END    
    ELSE IF @tipo = 4 BEGIN --Solo trae los seleccionados en el wg        
        INSERT @camps SELECT DISTINCT wgCamAcd.IdCampEsp cam_id 
        FROM ccUsers u WITH(NOLOCK)        
        INNER JOIN ccInbound c WITH(NOLOCK) ON c.IDArea = c.IDArea        
        INNER JOIN ccRIAWorkGroupUsers wg WITH(INDEX(IX_ccRIAWorkGroupUsers_I), NOLOCK) ON wg.User_id = u.User_id        
        INNER JOIN ccRIACampEspWG wgCamAcd WITH(INDEX(IX_ccRIACampEspWG_2), NOLOCK) ON wgCamAcd.IDWG = wg.IDWG AND tipo = 0              
        WHERE u.User_id = @user         
    END  
    ELSE IF @tipo = 5 BEGIN --Seleccionados en el wg y que son campañas de whatsApp de salida
        IF @user = 0
        BEGIN
            -- root: trae todas las campañas WhatsApp
            INSERT @camps 
            SELECT DISTINCT c.cam_id
            FROM ccCamps c
            WHERE c.CampType = 5
        END
        ELSE
        BEGIN
            -- usuario normal: filtra por workgroup
            INSERT @camps 
            SELECT IdCampEsp 
            FROM ccRIAWorkGroupUsers wgu
            INNER JOIN ccRIACampEspWG wgc ON wgc.IDWG = wgu.IDWG
            INNER JOIN ccCamps c ON c.cam_id = wgc.IdCampEsp
            WHERE wgu.User_id = @user AND c.CampType = 5
        END
    END  
    
    RETURN  
END
'
EXEC(@sql)

set @process = 'Se modifica ccsp_AgentGetEspecialidadesActivas para tomar horarios correctamente'
set @sql = '
ALTER PROCEDURE [dbo].[ccsp_AgentGetEspecialidadesActivas]
    @userID INT,
    @current INT = 0
    AS
    BEGIN
        SET NOCOUNT ON;
        SET DATEFIRST 1; -- Asegura que el primer día de la semana sea lunes

        DECLARE @fecha DATETIME = GETDATE();
        DECLARE @dia SMALLINT = DATEPART(dw, @fecha);
        DECLARE @hora SMALLINT = DATEPART(HOUR, @fecha);
        DECLARE @minuto SMALLINT = DATEPART(MINUTE, @fecha);
        DECLARE @value INT = (SELECT valor FROM ccSettings WHERE setting_id = 191);

        IF @value = 0
        BEGIN
            -- Consulta cuando @value es 0
            SELECT -8 AS inbound_id, ''Survey'' AS name, 1 AS frame
            UNION
            SELECT -1 AS inbound_id, ''IVR'' AS name, 1 AS frame
            UNION
            SELECT inb.inbound_id AS inbound_id, descripcion AS name, graphic.graphic_id AS frame
            FROM ccInbound inb
            LEFT JOIN ccRIAInboundGraph graphic ON inb.Inbound_id = graphic.Inbound_id
            WHERE inb.inbound_id IN (
                SELECT inbound_id
                FROM ccInboundHorarios
                WHERE horario_id IN (
                    SELECT horario_id
                    FROM ccHorarios
                    WHERE (@hora > HoraInicio OR (@hora = HoraInicio AND @minuto >= MinInicio))
                      AND (@hora < HoraFin OR (@hora = HoraFin AND @minuto <= MinFin))
                      AND (
                        (Lunes = 1 AND @dia = 1) OR
                        (Martes = 1 AND @dia = 2) OR
                        (Miercoles = 1 AND @dia = 3) OR
                        (Jueves = 1 AND @dia = 4) OR
                        (Viernes = 1 AND @dia = 5) OR
                        (Sabado = 1 AND @dia = 6) OR
                        (Domingo = 1 AND @dia = 7)
                      )
                )
            )
            AND inb.inbound_id <> @current
            AND status <> 0
            ORDER BY 1;
        END
        ELSE IF @value = 1
        BEGIN
            IF @current <> 0
            BEGIN
                -- Consulta cuando @value es 1 y @current no es 0
                SELECT -1 AS inbound_id, ''IVR'' AS name, 1 AS frame
                UNION
                SELECT inb.inbound_id AS inbound_id, descripcion AS name, graphic.graphic_id AS frame
                FROM ccInbound inb
                LEFT JOIN ccRIAInboundGraph graphic ON inb.Inbound_id = graphic.Inbound_id
                WHERE inb.inbound_id IN (
                    SELECT inbound_id
                    FROM ccInboundHorarios
                    WHERE horario_id IN (
                        SELECT horario_id
                        FROM ccHorarios
                        WHERE (@hora > HoraInicio OR (@hora = HoraInicio AND @minuto >= MinInicio))
                          AND (@hora < HoraFin OR (@hora = HoraFin AND @minuto <= MinFin))
                          AND (
                        (Lunes = 1 AND @dia = 1) OR
                        (Martes = 1 AND @dia = 2) OR
                        (Miercoles = 1 AND @dia = 3) OR
                        (Jueves = 1 AND @dia = 4) OR
                        (Viernes = 1 AND @dia = 5) OR
                        (Sabado = 1 AND @dia = 6) OR
                        (Domingo = 1 AND @dia = 7)
                          )
                    )
                )
                AND inb.inbound_id <> @current
                AND status <> 0
                AND IDArea IN (SELECT cu.IDArea FROM ccUsers cu WHERE cu.User_id = @current)
                ORDER BY 2;
            END
            ELSE
            BEGIN
                -- Consulta cuando @value es 1 y @current es 0
                SELECT -1 AS inbound_id, ''IVR'' AS name, 1 AS frame
                UNION
                SELECT inb.inbound_id AS inbound_id, descripcion AS name, graphic.graphic_id AS frame
                FROM ccInbound inb
                LEFT JOIN ccRIAInboundGraph graphic ON inb.Inbound_id = graphic.Inbound_id
                WHERE inb.inbound_id IN (
                    SELECT inbound_id
                    FROM ccInboundHorarios
                    WHERE horario_id IN (
                        SELECT horario_id
                        FROM ccHorarios
                        WHERE (@hora > HoraInicio OR (@hora = HoraInicio AND @minuto >= MinInicio))
                          AND (@hora < HoraFin OR (@hora = HoraFin AND @minuto <= MinFin))
                          AND (
                        (Lunes = 1 AND @dia = 1) OR
                        (Martes = 1 AND @dia = 2) OR
                        (Miercoles = 1 AND @dia = 3) OR
                        (Jueves = 1 AND @dia = 4) OR
                        (Viernes = 1 AND @dia = 5) OR
                        (Sabado = 1 AND @dia = 6) OR
                        (Domingo = 1 AND @dia = 7)
                          )
                    )
                )
                AND inb.inbound_id <> @current
                AND status <> 0
                AND IDArea IN (SELECT IDArea FROM ccUsers WHERE User_id = @userID)
                ORDER BY 2;
            END
        END
    END
'
EXEC(@sql)
------------------------ END Giovanni Martinez --------------------------

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)    



    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    
    SET @process = ''
    SET @sql = ''
    exec (@sql)

    
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)    



    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    
    SET @process = ''
    SET @sql = ''
    exec (@sql)

    
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)    


     
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    
    SET @process = ''
    SET @sql = ''
    exec (@sql)

    
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)    
    --- END  ----

	
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
