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

    SET @process = 'DROP usp_SetObjectDescription'
    SET @sql = 'if exists (select * from sys.procedures where name = N''usp_SetObjectDescription'')
    begin
            DROP PROCEDURE usp_SetObjectDescription;
    end'
    exec (@sql)

    SET @process = 'DROP usp_SetColumnDescription'
    SET @sql = 'if exists (select * from sys.procedures where name = N''usp_SetColumnDescription'')
    begin
            DROP PROCEDURE usp_SetColumnDescription;
    end'
    exec (@sql)

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
    
    SET @process = 'CREATE PROCEDURE dbo.usp_SetObjectDescription'
    SET @sql = 'CREATE PROCEDURE dbo.usp_SetObjectDescription
(
    @SchemaName  SYSNAME,
    @ObjectName  SYSNAME,
    @Description NVARCHAR(4000)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Level1Type VARCHAR(30);

    SELECT @Level1Type = CASE o.[type]
        WHEN ''U''  THEN ''TABLE''
        WHEN ''V''  THEN ''VIEW''
        WHEN ''P''  THEN ''PROCEDURE''
        WHEN ''FN'' THEN ''FUNCTION''
        WHEN ''IF'' THEN ''FUNCTION''
        WHEN ''TF'' THEN ''FUNCTION''
        ELSE NULL
    END
    FROM sys.objects o
    INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = @SchemaName
      AND o.name = @ObjectName;

    IF @Level1Type IS NULL
    BEGIN
        PRINT CONCAT(''Objeto no encontrado o no soportado: '', @SchemaName, ''.'', @ObjectName);
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM sys.extended_properties ep
        INNER JOIN sys.objects o ON ep.major_id = o.object_id
        INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE ep.name = N''MS_Description''
          AND s.name = @SchemaName
          AND o.name = @ObjectName
          AND ep.minor_id = 0
    )
    BEGIN
        EXEC sys.sp_updateextendedproperty
            @name = N''MS_Description'',
            @value = @Description,
            @level0type = N''SCHEMA'', @level0name = @SchemaName,
            @level1type = @Level1Type, @level1name = @ObjectName;
    END
    ELSE
    BEGIN
        EXEC sys.sp_addextendedproperty
            @name = N''MS_Description'',
            @value = @Description,
            @level0type = N''SCHEMA'', @level0name = @SchemaName,
            @level1type = @Level1Type, @level1name = @ObjectName;
    END
END;'
    exec (@sql)

     SET @process = 'CREATE PROCEDURE dbo.usp_SetColumnDescription'
    SET @sql = 'CREATE PROCEDURE dbo.usp_SetColumnDescription
(
    @SchemaName  SYSNAME,
    @ObjectName  SYSNAME,
    @ColumnName  SYSNAME,
    @Description NVARCHAR(4000)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Level1Type VARCHAR(30);

    SELECT @Level1Type = CASE o.[type]
        WHEN ''U'' THEN ''TABLE''
        WHEN ''V'' THEN ''VIEW''
        ELSE NULL
    END
    FROM sys.objects o
    INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = @SchemaName
      AND o.name = @ObjectName;

    IF @Level1Type IS NULL
    BEGIN
        PRINT CONCAT(''Objeto no encontrado/no es tabla o vista: '', @SchemaName, ''.'', @ObjectName);
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.objects o
        INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
        INNER JOIN sys.columns c ON c.object_id = o.object_id
        WHERE s.name = @SchemaName
          AND o.name = @ObjectName
          AND c.name = @ColumnName
    )
    BEGIN
        PRINT CONCAT(''Columna no encontrada: '', @SchemaName, ''.'', @ObjectName, ''.'', @ColumnName);
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM sys.extended_properties ep
        INNER JOIN sys.objects o ON ep.major_id = o.object_id
        INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
        INNER JOIN sys.columns c ON c.object_id = o.object_id AND c.column_id = ep.minor_id
        WHERE ep.name = N''MS_Description''
          AND s.name = @SchemaName
          AND o.name = @ObjectName
          AND c.name = @ColumnName
    )
    BEGIN
        EXEC sys.sp_updateextendedproperty
            @name = N''MS_Description'',
            @value = @Description,
            @level0type = N''SCHEMA'', @level0name = @SchemaName,
            @level1type = @Level1Type, @level1name = @ObjectName,
            @level2type = N''COLUMN'', @level2name = @ColumnName;
    END
    ELSE
    BEGIN
        EXEC sys.sp_addextendedproperty
            @name = N''MS_Description'',
            @value = @Description,
            @level0type = N''SCHEMA'', @level0name = @SchemaName,
            @level1type = @Level1Type, @level1name = @ObjectName,
            @level2type = N''COLUMN'', @level2name = @ColumnName;
    END
END;'
    exec (@sql)

    SET @process = 'Descripciones de objetos'
    SET @sql = 'EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccMenus'', @Description=N''Menus para reportes'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccRIACat_Areas'', @Description=N''Catalogo de areas.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @Description=N''Usuarios que se van dando de alta en el sistema, ya sean Administradores o Agentes.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @Description=N''Campañas de entrada(Voz, IA, Chat, Email).'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccinboundagentes'', @Description=N''Relaciones de los agentes y campañas de entrada.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @Description=N''Campañas de salida (Voz, IA, SMS , Vista previa, voz)'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''cccampsExtend'', @Description=N''Configuraciones de campaña de salida extras.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccCampsAgente'', @Description=N''Relaciones de los agentes y campañas de salida.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalif'', @Description=N''Catalogo de calificaciones configuradas en el sistema para campañas de entrada.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifout'', @Description=N''Catalogo de calificaciones configuradas en el sistema para campañas de salida.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsub'', @Description=N''Catalogo de sub-calificaciones de campañas de entrada'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccCalifCamp'', @Description=N''Relacionar las calificaciones con las campañas de salida'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsubout'', @Description=N''Catalogo para las sub-calificaciones de campañas de salida'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccBaseXDB'', @Description=N''Tabla para guardar la información de las bases dadas de alta en BaseXServer'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccFinderServices'', @Description=N''Tabla donde se guarda los servicios y la relación con el nombre del nodo'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''cctiponotready'', @Description=N''Catalogo de no disponible dados de alta en el sistema.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccTipoStatusAgente'', @Description=N''Catalogo estados de los agentes y su definicion'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''messageStatus'', @Description=N''Catalogo para los mensajes de email, twitter, WhatsApp'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccPosicion'', @Description=N''Catalogo de extensiones de los agentes.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccriacat_workgroup'', @Description=N''Catalogo de grupos de Trabajo que se dan de alta en el sistema.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia'', @Description=N''En esta tabla se registran los cambios de estado de todos los agentes.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia_Dialog'', @Description=N''Registra tiempo de disponible y dialogo.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccriaareaworkgroup'', @Description=N''Relaciones entre Áreas y Grupos de Trabajo.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''cclogagentesnotready'', @Description=N''En esta tabla se registran los estados de No Disponible de todos los agentes.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccloglogin'', @Description=N''Guarda el inicio de sesion y finalizacion de sesion de los agentes'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccriaworkgroupusers'', @Description=N''Relacion de grupos de trabajo y usuarios.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @Description=N''Tabla para algunas configuracion de campañas de entrada y salida para los multimedios'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccSettings2'', @Description=N''Tabla de configuracion generales.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccoCallsOutData'', @Description=N''Relacion con la llamada transferida al agente y los datos 1-5.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccoLogDialsData'', @Description=N''Relacion con intento de marcacion con datos 1-5.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccoCallsOut'', @Description=N''En esta tabla se almacenan solo los registros contactados (o llamadas contestadas) cuando se realizan por medio del predictivo, si una llamada es realizada de forma manual aunque no se conteste se almacena en esta tabla.'';

EXEC dbo.usp_SetObjectDescription @SchemaName=N''dbo'', @ObjectName=N''ccGalateaModulesyccGalateaOperations'', @Description=N''Kolob - Etiquetas Desarrollo(CW)'';


/* Descripciones de columnas */
EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccMenus'', @ColumnName=N''menu_id'', @Description=N''Id del menú. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccMenus'', @ColumnName=N''menu_descrip'', @Description=N''Descripción del menú. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccMenus'', @ColumnName=N''parent'', @Description=N''Padre del menú al que va a pertenecer. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccMenus'', @ColumnName=N''Nivel'', @Description=N''Nivel de opción que se presentara en el menú. Tipo documentado: char.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccMenus'', @ColumnName=N''ordengral'', @Description=N''Orden en que se presentara el menú. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccMenus'', @ColumnName=N''type'', @Description=N''Define para asignar menú 1. Sitio de Administrador 2. Sitio de CCreports 3. Sitio de CCreportsRIA. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccMenus'', @ColumnName=N''HelpSWF'', @Description=N''Inhabilitar. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccRIACat_Areas'', @ColumnName=N''IDArea'', @Description=N''Identificador del Área, consecutivo y único. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccRIACat_Areas'', @ColumnName=N''AreaName'', @Description=N''Nombre del área. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccRIACat_Areas'', @ColumnName=N''StatusArea'', @Description=N''Status del área activo o inactivo. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccRIACat_Areas'', @ColumnName=N''maxMails'', @Description=N''Máximo número de mails. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccRIACat_Areas'', @ColumnName=N''maxChats'', @Description=N''Máximo número de chats. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccRIACat_Areas'', @ColumnName=N''maxTweets'', @Description=N''Máximo número de tweets. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccRIACat_Areas'', @ColumnName=N''defCampaing'', @Description=N''Campaña default para llamada manual. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccRIACat_Areas'', @ColumnName=N''CreateDate'', @Description=N''Fecha de creacion de la campaña. Tipo documentado: datetime.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccRIACat_Areas'', @ColumnName=N''maxWhats'', @Description=N''Máximo número de WhatsApp. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''User_id'', @Description=N''Identificador único de usuario, auto numérico. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''Login'', @Description=N''Login o nombre de usuario con el que se firman al sistema, ya sea agente o administrador. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''Nombres'', @Description=N''Nombre del usuario.. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''ApellidoPaterno'', @Description=N''Apellido paterno del usuario.. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''ApellidoMaterno'', @Description=N''Apellido materno del usuario.. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''TipoStatusAge_id'', @Description=N''Estado del agente, referirse a ccTipoStatusAgente.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''Password'', @Description=N''Contraseña del usuario.. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''TipoUser_id'', @Description=N''Perfil del usuario, referirse a la tabla ccTipoUser.. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''Status'', @Description=N''Estado del usuario 1 activado 0 desactivado.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''TipoLLamadas'', @Description=N''Qué tipo de llamadas puede recibir el agente (CW4): 1 Inbound 2 Outbound 3 Ambas. Para CW (V, Xion) siempre es 3. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''Sexo'', @Description=N''Sexo del usuario, true hombre, false mujer. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''filter'', @Description=N''Inhabilitar.. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''CanChangeStatus'', @Description=N''Permite si el agente se puede poner en estado No Disponible en Outbound. True permite, False no. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''fCreate'', @Description=N''Fecha y hora de cuando se creó el usuario. Tipo documentado: smalldatetime.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''DialMask'', @Description=N''Para restringir llamadas (celular, local, lada). Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''XferMask'', @Description=N''Para permitir transferencia. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''LastPasswordChange'', @Description=N''Fecha en la cual el usuario cambio por última vez su contraseña. Tipo documentado: smalldatetime.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''IDArea'', @Description=N''Id del área. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''NotReadyRestricted'', @Description=N''Habilitar opciones de No Disponible durante la llamada de salida (Agente). Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''XferAgents'', @Description=N''Permiso recibir transferencias. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''viewAgents'', @Description=N''Permiso del admin para solo monitoreo. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''onLine'', @Description=N''Revisa si la conexión de socket sigue viva en los Administradores. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''startStopRecording'', @Description=N''Permiso para iniciar o detener grabaciones. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccUsers'', @ColumnName=N''reconnectMsg'', @Description=N''Códi de mensaje de error para reconexión del agente. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''cli_id'', @Description=N''Identificador del cliente al que se asoció la especialidad. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''Inbound_id'', @Description=N''Identificador de la Campaña de entrada. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''Status'', @Description=N''Estado de la campaña de entrada, 1. activa 2. inhabilitar. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''dnis'', @Description=N''Inhabilitar.. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''standby'', @Description=N''Inhabilitar.. Tipo documentado: sm.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''tNotas'', @Description=N''Tiempo de notas de la especialidad, en segundos. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''tMaxWaitCall'', @Description=N''Tiempo máximo de una llamada en cola de espera antes de ser desbordada, en segundos.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''nMaxQue'', @Description=N''Número máximo de llamadas en cola de espera antes de ser desbordadas.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''Msg_id'', @Description=N''Inhabilitar. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''tel_maxwait'', @Description=N''Teléfono al cual se transferirán las llamadas por desborde de tiempo máximo de espera.. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''tel_maxqueue'', @Description=N''Teléfono al cual se transferirán las llamadas por desborde de número máximo de llamadas en cola de espera.. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''tel_outservice'', @Description=N''Teléfono al cual se transferirán las llamadas que entren a la especialidad al estar desactivada o fuera de servicio.. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''tel_noct'', @Description=N''Teléfono al cual se transferirán las llamadas que entren en la especialidad al estar fuera de horario.. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''bnocturno'', @Description=N''Inhabilitar. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''tMaxQueueCallBack'', @Description=N''Tiempo maximo para generar callback. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''stopRecording'', @Description=N''Permiso para detener grabaciones. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''DialPrefixOverflow'', @Description=N''Prefijo al numero a marcar cuando se realiza desborde. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''OpriorityT'', @Description=N''Inhabilitar. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''callerIdDesc'', @Description=N''Personaliza el callerId para desbode a numeros extenos. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''chat'', @Description=N''Modos de ACD 0 Llamadas 2 Inhabilitada 1 Chat 3 Email 4 Twitter 5 WhatsApp. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''inactiveChatTime'', @Description=N''Tiempo para cerrar el chat. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''maxChats'', @Description=N''Máximo numero de chats por Agente. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''chatDomain'', @Description=N''Dominio del chat para diferenciarlos de otros ACD. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''chatQueueOverflow'', @Description=N''Numero Máximo en la cola para desbordar el Chat. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''chatTimeOverflow'', @Description=N''Tiempo máximo desbordar el chat. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''startStopRecording'', @Description=N''Permiso para iniciar o detener grabación. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''callBackSurveyAgent'', @Description=N''Permiso para desbordar al IVR después de colgar la llamada. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''callBackSurveyClient'', @Description=N''Permiso para generar callback para contestar encuentra. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinbound'', @ColumnName=N''editableDtmf'', @Description=N''Permiso para poder enviar varios DTMF. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinboundagentes'', @ColumnName=N''User_id'', @Description=N''Identificador del usuario.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinboundagentes'', @ColumnName=N''Inbound_id'', @Description=N''Identificador de la especialidad.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinboundagentes'', @ColumnName=N''cli_id'', @Description=N''Identificador del cliente al que está asociado la especialidad.. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinboundagentes'', @ColumnName=N''prioridad'', @Description=N''Prioridad con la que se asignarán las llamadas al agente.. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinboundagentes'', @ColumnName=N''skill'', @Description=N''Identificador del Skill que se le asignó al agente. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinboundagentes'', @ColumnName=N''rel_id'', @Description=N''Clave Primaria. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccinboundagentes'', @ColumnName=N''IDWG'', @Description=N''Identificador del grupo de trabajo la cual pertenece la especialidad y los agentes.. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_id'', @Description=N''Identificador de la Campaña salida, auto numérico y único.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cli_id'', @Description=N''Identificador del cliente al que está asociada la campaña salida.. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_descripcion'', @Description=N''Nombre de la campaña.. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_activo'', @Description=N''Indica si la campaña está activa (1) o deshabilitada (0). Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_ModoManual'', @Description=N''Indica si se permiten llamadas manuales, 0 deshabilitar, 1 Via Teclado e historial, 2 Via Historial de llamadas, 3 Via teclado. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_modpredictivo'', @Description=N''Indica si se realizará marcación predictiva en la campaña, 1 habilitar, 0 deshabilitar.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_TipoJobs'', @Description=N''Qué tipo de registro se marcaran mediante el predictivo; 2 nuevos, 1 callbacks, 0 ambos.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_tNoContesta'', @Description=N''Tiempo en segundos que se esperará respuesta a cada llamada antes de calificarla como "No contesta". Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_SortColumns'', @Description=N''Inhabilitar.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_ocupado'', @Description=N''Bandera para reintentar llamada en caso de que este ocupado el número, 1 habilitar, 0 deshabilitar.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_nocontesto'', @Description=N''Bandera para reintentar llamada en caso de que no conteste el número, 1 habilitar, 0 deshabilitar.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_graba'', @Description=N''Bandera que indica si está habilitada la opción de maquina contestadora, 1 habilitar, 0 inhabilitar.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_fax'', @Description=N''Bandera que indica si está habilitada la opción de fax/modem, 1 habilitar, 0 inhabilitar.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_callratio'', @Description=N''Inhabilitar.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_inter_ocupado'', @Description=N''Intervalo de tiempo en segundos que esperara entre cada remarcado por ocupado.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_inter_nocontesto'', @Description=N''Intervalo de tiempo en segundos que esperará entre cada remarcado por no contesta.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_inter_graba'', @Description=N''Intervalo de tiempo en segundos que esperará entre cada remarcado al contestar una grabadora.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_inter_fax'', @Description=N''Intervalo de tiempo en segundos que esperará entre cada remarcado al contestar un fax.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_NoInt_ocupado'', @Description=N''Número de intentos de remarcado si la llamada dio como resultado ocupado.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_NoInt_nocontesto'', @Description=N''Número de intentos de remarcado si la llamada no fue contestada.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_NoInt_graba'', @Description=N''Número de intentos de remarcado si la llamada fue contestada por una grabadora.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_NoInt_fax'', @Description=N''Número de intentos de remarcado si la llamada fue contestada por un fax.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_procesando'', @Description=N''Indica si la campaña está iniciada (1) o si está detenida (0). Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_MaxDlrXage'', @Description=N''Número máximo de Díalers por agente para la marcación predictiva.. Tipo documentado: decimal.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''ani'', @Description=N''Ani que se mostrará en el identificador de llamadas del cliente al recibir la llamada del CallCenter, para poder utilizar esta función se depende si es soportado por el carrier. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''IDArea'', @Description=N''Clave del área de trabajo. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''EditableCallKey'', @Description=N''Editar el callkey 0 no lo permite editar y 1 lo permite editar. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''iTipoDial'', @Description=N''Marcación Intensiva. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''detectAnswerMachine'', @Description=N''Detección Maquina contestadora, lo hace después de haberse contestado la llamada (humano/maquina) 0 No detecta 1 Rápida 2 Ligera 3 Exacta -1 Deshabilita CPA. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''detectVoiceMail'', @Description=N''Detección de buzón de voz, aplica antes de que se conteste la llamada (buzón),. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''compliance'', @Description=N''Solo se habilita para USA para el huso de horarios. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''progDial'', @Description=N''función para habilitar la marcacion progresiva, selectiva o des-habilitar ambas.(Función para encuesta) 0 deshabilitado 1 progresiva 2 selectiva 3 vista previa. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''excCallBack'', @Description=N''Call Back exclusivo por agente. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''keepDial'', @Description=N''Seguir marcando 0 Inhabilitar y habilitado. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''aggressionFactor'', @Description=N''Detecta voicemail 0 desactivado y 1 activado. Tipo documentado: float.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''DialOrder'', @Description=N''Habilitar Compliance. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''DialPrefix'', @Description=N''Marcación Progresiva. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''listenManualCall'', @Description=N''Call back Exclusivo. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''stopRecording'', @Description=N''Permiso para detener grabacion. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''abandonCallback'', @Description=N''Ascendente. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''t_autoCB'', @Description=N''Descendente. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''id_anilist'', @Description=N''Prefijo de marcación (Predictivo). Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''DialPrefixMan'', @Description=N''Activa cuando se está escuchando una llamada desde el administrador se siga monitoreando las llamadas manuales.. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''DialPrefixXfe'', @Description=N''Permitir pausar y continuar grabación. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''tDialonWrapUp'', @Description=N''Reprogramar evento fallido. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''cam_maxqueue'', @Description=N''Asocia un lista de Ani para enmascarar partir de la lada de marcación. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''DNCScrub'', @Description=N''Prefijo de marcación(Manual). Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''callerIdDesc'', @Description=N''Prefijo de marcación(Transferencia). Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''timeZoneRule'', @Description=N''Marcar antes de que termine el tiempo de notas. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''surveyCamId'', @Description=N''Id de campaña para asociar una campaña normal a una encuesta. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''callsBySurvey'', @Description=N''Personalizar ID de llamada. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''ivrScript'', @Description=N''Habilita si valida el número telefónico en llamadas manuales. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''surveyPctg'', @Description=N''Porcentaje de llamadas de encuesta que se van a realizar. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''call_record'', @Description=N''Tipo de campaña. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''startStopRecording'', @Description=N''Habilitar opcion de detener y continuar grabación del lado del agente. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''leaveRecMessage'', @Description=N''Habilitar la opcion de dejar (en el agente) mensaje en maquina contestadora. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''manualCallOnChat'', @Description=N''Id del Script del IVR donde va comenzar cuando está en modo encuesta. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''callBackSurveyAgent'', @Description=N''Porcentaje de llamadas que se realizara cuando esta modo encuesta. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''callBackSurveyClient'', @Description=N''Permiso para no grabar las llamadas esta solo habilitado para USA. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''funcEspDtmf'', @Description=N''Permiso para iniciar o detener la grabación de la llamada. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''prefijo'', @Description=N''Este sirve para poder poner subfijo en las grabaciones. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''holdCall'', @Description=N''Saber si debe grabar. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''CampType'', @Description=N''0 Voz 2 4 IA 5 WhatsApp 6 Vista Previa 7 Campaña SMS. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccamps'', @ColumnName=N''recordHold'', @Description=N''1 graba hold de las llamadas, 0 no graba el hold. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccampsExtend'', @ColumnName=N''Cam_id'', @Description=N''Habilitar opción de asignar la conversación de WhatsApp de salida al agente que previamente la atendió. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccampsExtend'', @ColumnName=N''ZipCodeSchedule'', @Description=N''Validar zona horaria por códi postal. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccampsExtend'', @ColumnName=N''cam_DiasMax'', @Description=N''Parámetro que permite configurar la cantidad de días máximos que el agente puede buscar de histórico de una conversación. K020140-Cantidad de días máximos a buscar por conversación WhatsApp de salida en histórico - Documentación por Producto - Playbook - Confluence (atlassian.net). Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccampsExtend'', @ColumnName=N''EditableContactData'', @Description=N''Poder editar los datos. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cccampsExtend'', @ColumnName=N''AssignConversationSameAgent'', @Description=N''Habilitar opción de asignar la conversación de WhatsApp de salida al agente que previamente la atendió. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccCampsAgente'', @ColumnName=N''user_id'', @Description=N''Identificador único del agente, referirse a ccUsers.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccCampsAgente'', @ColumnName=N''cam_id'', @Description=N''Identificador único de la campaña, referirse a ccCamps.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccCampsAgente'', @ColumnName=N''prioridad'', @Description=N''Prioridad configurada al agente desde el administrador.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccCampsAgente'', @ColumnName=N''skill'', @Description=N''Skill configurador al agente desde el administrador.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccCampsAgente'', @ColumnName=N''rel_id'', @Description=N''Identificador único y auto numérico de la relación. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccCampsAgente'', @ColumnName=N''IDWG'', @Description=N''Identificador único del grupo de trabajo a la que pertenece la relación.. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalif'', @ColumnName=N''calif_id'', @Description=N''Identificador de la calificación campañas de entrada. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalif'', @ColumnName=N''Description'', @Description=N''Nombre de la calificación. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalif'', @ColumnName=N''orden'', @Description=N''Orden en el que aparecerán las calificaciones en el combo box del agente. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalif'', @ColumnName=N''CanReprogram'', @Description=N''Si puede seguir marcando. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalif'', @ColumnName=N''Calif_Status'', @Description=N''Estatus de la calificación 0 desactivado y 1 activado. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalif'', @ColumnName=N''EndConversation'', @Description=N''Conversaciones finalizada (1). Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifout'', @ColumnName=N''calif_id'', @Description=N''Identificador de la calificación campañas de salida. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifout'', @ColumnName=N''Description'', @Description=N''Nombre de la calificación. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifout'', @ColumnName=N''autoTime'', @Description=N''Inhabilitar.. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifout'', @ColumnName=N''CanReprogram'', @Description=N''Habilita la opción de reprogramar, 1 habilitado, 0 inhabilitar. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifout'', @ColumnName=N''orden'', @Description=N''Especifica el orden en que aparecerán las calificaciones en la lista del agente. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifout'', @ColumnName=N''idTipoLista'', @Description=N''Utilizado en versiones anteriores a CenterWareV. Tipo de lista negra, para los casos en que se desea que por medio de caificacion se pase a lista negra el número marcado. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifout'', @ColumnName=N''CalifOut_Status'', @Description=N''Estatus de la subcalificacion 0 desactivado y 1 activado. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifout'', @ColumnName=N''keepDial'', @Description=N''Seguir marcando. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifout'', @ColumnName=N''autoCallback'', @Description=N''SI el sistema genera un callback automático. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifout'', @ColumnName=N''contactOwner'', @Description=N''Para agregar reporte si contabilizara. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifout'', @ColumnName=N''finishPreview'', @Description=N''permiso para que cuando la campaña este en modo selectivo permita regresar al agente a Disponible.. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsub'', @ColumnName=N''califSub_id'', @Description=N''Identificador de subcalificación campañas de entrada. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsub'', @ColumnName=N''califSubDesc'', @Description=N''Nombre de la subcalificación. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsub'', @ColumnName=N''orden'', @Description=N''Orden en la que se visualizara la subcalificacion. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsub'', @ColumnName=N''canReprogram'', @Description=N''SI se puede realizar reprogramación. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsub'', @ColumnName=N''califSub_Status'', @Description=N''Estatus de la subcalificacion 0 desactivado y 1 activado. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsub'', @ColumnName=N''EndConversation'', @Description=N''Función para Email y Twitter para definir si la conversación se terminó o sigue abierta. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsubout'', @ColumnName=N''califSub_id'', @Description=N''IIdentificador de subcalificación campañas de salida. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsubout'', @ColumnName=N''califSubDesc'', @Description=N''Nombre de la subcalificacion. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsubout'', @ColumnName=N''canReprogram'', @Description=N''SI se puede realizar reprogramación. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsubout'', @ColumnName=N''orden'', @Description=N''Orden en la que se presentara la subcalificacion. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsubout'', @ColumnName=N''idTipoLista'', @Description=N''Inhablitar. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsubout'', @ColumnName=N''califSubOut_Status'', @Description=N''Si está habilitada para usar en el calificaciones del agente. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsubout'', @ColumnName=N''keepDial'', @Description=N''Seguir marcando. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsubout'', @ColumnName=N''autoCallback'', @Description=N''Que se programa la llamada de manera automática para callback. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctipocalifsubout'', @ColumnName=N''contactOwner'', @Description=N''Si pondrá en un reporte agrupación por calificación. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccCalifCamp'', @ColumnName=N''calif_id'', @Description=N''Identificador único de la calificación referirse a ccTipoCalif y ccTipoCalifOut. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccCalifCamp'', @ColumnName=N''cam_id'', @Description=N''Identificador único de la campaña o de la especialidad, referirse a ccCamps y ccInbound.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccCalifCamp'', @ColumnName=N''tipo'', @Description=N''Si es 0, la relación es de una especialidad, si es 1 la relación es de campaña.. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccBaseXDB'', @ColumnName=N''id'', @Description=N''Identificador de la tabla. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccBaseXDB'', @ColumnName=N''serviceId'', @Description=N''ccFinderServices.id. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccBaseXDB'', @ColumnName=N''dateStart'', @Description=N''Fecha de creación de la base. Tipo documentado: datetime.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccBaseXDB'', @ColumnName=N''dateEnd'', @Description=N''Fechar de cierre de la base. Tipo documentado: datetime.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccBaseXDB'', @ColumnName=N''Xname'', @Description=N''Nombre de la base de datos de base x. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccBaseXDB'', @ColumnName=N''isFull'', @Description=N''Indica si la base de datos está llena para crear una nueva. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccFinderServices'', @ColumnName=N''id'', @Description=N''Identificador de la tabla. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccFinderServices'', @ColumnName=N''name'', @Description=N''Nombre del servicio. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccFinderServices'', @ColumnName=N''ref'', @Description=N''Nombre del nodo (R01,R02,…). Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccFinderServices'', @ColumnName=N''tableName'', @Description=N''Nombre de la tabla que guardara la información de los nodos. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccFinderServices'', @ColumnName=N''tableNameHistory'', @Description=N''Nombre de la tabla que guardara la información de los nodos históricos. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccFinderServices'', @ColumnName=N''columnId'', @Description=N''Nombre de la columna que se identifica en la tablas para. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccFinderServices'', @ColumnName=N''isActive'', @Description=N''Revisa si el servicio esta activo. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''messageStatus'', @ColumnName=N''messageStatusId'', @Description=N''Identificador de la tabla. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''messageStatus'', @ColumnName=N''name'', @Description=N''Nombre del estado. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''messageStatus'', @ColumnName=N''description'', @Description=N''Descripción del estado. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''messageStatus'', @ColumnName=N''isFinished'', @Description=N''Si la conversacion es finalizada (solo email). Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccTipoStatusAgente'', @ColumnName=N''TipoStatusAge_id'', @Description=N''Identificador de la tabla. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctiponotready'', @ColumnName=N''TipoNotReady_id'', @Description=N''Identificador del tipo de no disponible, auto numérico y único. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctiponotready'', @ColumnName=N''Time_Acum'', @Description=N''Tiempo máximo acumulado del tipo de no disponible, en segundos.. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctiponotready'', @ColumnName=N''Time_xEv'', @Description=N''Tiempo máximo por evento, en segundos. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctiponotready'', @ColumnName=N''Pas_Sup'', @Description=N''Indica si el tipo de no disponible requerirá contraseña de supervisor, 1 activado, 0 inhabilitar.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctiponotready'', @ColumnName=N''NextStatus'', @Description=N''Especifica el siguiente estado al que pasará el agente al terminarse el tiempo por evento o acumulado, -1 Disponible, >0 Identificador del siguiente tipo no disponible.. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctiponotready'', @ColumnName=N''IsSup'', @Description=N''Si requiere que se ponga contraseña de administrador. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cctiponotready'', @ColumnName=N''StatusTipoNotReady'', @Description=N''Status de tipo no disponible. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccPosicion'', @ColumnName=N''pos_id'', @Description=N''Id de la posición. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccPosicion'', @ColumnName=N''Computer'', @Description=N''Nombre de la computadora. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccPosicion'', @ColumnName=N''ext_id'', @Description=N''Id de la extensión. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccPosicion'', @ColumnName=N''user_id'', @Description=N''Id del usuario. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccPosicion'', @ColumnName=N''Status'', @Description=N''Status de la posición. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccPosicion'', @ColumnName=N''tipoConexion'', @Description=N''0 Ip 1 Live Connect. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccPosicion'', @ColumnName=N''IP'', @Description=N''Ip de la maquina. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccriacat_workgroup'', @ColumnName=N''IDWG'', @Description=N''Identificador de la tabla. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccriacat_workgroup'', @ColumnName=N''WGName'', @Description=N''Nombre del Grupo de Trabajo. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccriacat_workgroup'', @ColumnName=N''StatusWorkGroup'', @Description=N''Grupo de trabajo activo. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccriaareaworkgroup'', @ColumnName=N''IDWG'', @Description=N''ccriacat_workgroup.IDWG. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccriaareaworkgroup'', @ColumnName=N''IDArea'', @Description=N''Identificador del Área. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia'', @ColumnName=N''User_id'', @Description=N''Identificador único del agente, referirse a ccUsers.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia'', @ColumnName=N''TipoStatusAge_id'', @Description=N''Identificador del estado del agente, referirse a ccTipoStatusAgente.. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia'', @ColumnName=N''tStatus'', @Description=N''Tiempo en segundos que el agente estuvo en ese estado. Tipo documentado: float.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia'', @ColumnName=N''fecha'', @Description=N''Fecha hora en la cual el agente cambió al siguiente estado.. Tipo documentado: datetime.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia'', @ColumnName=N''IdCampEsp'', @Description=N''Id de la campaña o especialidad. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia'', @ColumnName=N''Tipo'', @Description=N''Tipo. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia'', @ColumnName=N''currentStatus'', @Description=N''El estado que está actualmente el agente. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia'', @ColumnName=N''callID'', @Description=N''Id de la llamada. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia_Dialog'', @ColumnName=N''Log_DialId'', @Description=N''Identificador único de la tabla. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia_Dialog'', @ColumnName=N''User_id'', @Description=N''Identificador único del agente, referirse a ccUsers.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia_Dialog'', @ColumnName=N''Cam_id'', @Description=N''Identificador de campañas. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia_Dialog'', @ColumnName=N''fecha_Calc_ms'', @Description=N''Tiempo en milisegundos. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia_Dialog'', @ColumnName=N''tStatus_Dispo'', @Description=N''Tiempo en segundos de disponible. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia_Dialog'', @ColumnName=N''fecha_Dispo'', @Description=N''Fecha del Tiempo Disponible. Tipo documentado: datetime.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia_Dialog'', @ColumnName=N''tStatus_Dialog'', @Description=N''Tiempo en segundos en dialo. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccLogAgentesDia_Dialog'', @ColumnName=N''fecha_Dialog'', @Description=N''Fecha del Tiempo Dialo. Tipo documentado: datetime.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cclogagentesnotready'', @ColumnName=N''User_id'', @Description=N''Identificador único del agente, referirse a ccUsers.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cclogagentesnotready'', @ColumnName=N''TipoNotReady_id'', @Description=N''Identificador único del tipo de no disponible, referirse a ccTipoNotReady. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cclogagentesnotready'', @ColumnName=N''tStatus'', @Description=N''Tiempo en segundos que duró el agente en estado no disponible.. Tipo documentado: float.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cclogagentesnotready'', @ColumnName=N''fecha'', @Description=N''Fecha hora en la cual el agente salió del estado no disponible.. Tipo documentado: datetime.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cclogagentesnotready'', @ColumnName=N''separado'', @Description=N''Bandera que indica cuando un evento No disponible estuvo en horas diferentes (1), cuando el tipo no disponible estuvo en la misma hora tiene valor de (0). Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cclogagentesnotready'', @ColumnName=N''IdCampEsp'', @Description=N''Id de la campaña o ACD. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''cclogagentesnotready'', @ColumnName=N''Tipo'', @Description=N''Tipo. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccloglogin'', @ColumnName=N''User_id'', @Description=N''Identificador único del agente, referirse a ccUsers.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccloglogin'', @ColumnName=N''Extension'', @Description=N''Número de extensión en la cual se encuentra el agente, en caso de ser IP, es el identificador de la posición, referirse a ccPosicion.. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccloglogin'', @ColumnName=N''TipoMov'', @Description=N''Tipo de movimiento que realizó, 1 inicio de sesión, 0 cierre de sesión. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccloglogin'', @ColumnName=N''fecha'', @Description=N''Fecha hora en la cual se realizó el movimiento.. Tipo documentado: datetime.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccriaworkgroupusers'', @ColumnName=N''IDWG'', @Description=N''Identificador del grupo de trabajo, referirse a ccriacat_workgroup.IDWG. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccriaworkgroupusers'', @ColumnName=N''User_id'', @Description=N''Identificador único del agente, referirse a ccUsers.. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''meanContactTypeId'', @Description=N''Identificador de la tabla. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''name'', @Description=N''Nombre de la conexión. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''conexionInfo'', @Description=N''Datos de la conexión. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''inboundId'', @Description=N''ccinbound.Inbound_id. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''connUser'', @Description=N''Nombre usuario. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''ConnPass'', @Description=N''Contraseña. Tipo documentado: varchar.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''numMessages'', @Description=N''Numero de mensajes. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''timeAlertMessage'', @Description=N''Tiempo para salir una alerta (email). Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''answerTimeOut'', @Description=N''Tiempo cerrar conversación( Email y Twitter). Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''isActive'', @Description=N''Si esta activo la cuenta. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''closeConversationTime'', @Description=N''Tiempo para cerrar la conversación. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''answerTimeoutClient'', @Description=N''Tiempo para cerrar conversación si el cliente no contesta. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''defaultServiceLevelParameter'', @Description=N''Modo de medir el nivel de servicio. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''contactMeanIn'', @ColumnName=N''allowFileAttachments'', @Description=N''Si tiene permitido envió de Archivos adjuntos. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccSettings2'', @ColumnName=N''setting_id'', @Description=N''Identificador único referente al setting. Tipo documentado: smallint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccSettings2'', @ColumnName=N''valor'', @Description=N''Valor del setting. Tipo documentado: varchar(300).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccSettings2'', @ColumnName=N''Status'', @Description=N''Status. Tipo documentado: tinyint.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccSettings2'', @ColumnName=N''Tipo'', @Description=N''Tipo de setting GRL: General, ADM: Administrador, AGT: Agente. Tipo documentado: varchar(3).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccSettings2'', @ColumnName=N''detalle'', @Description=N''Detalle del setting. Tipo documentado: varchar(600).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccSettings2'', @ColumnName=N''description'', @Description=N''Descripción del setting en inglés. Tipo documentado: varchar(600).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccSettings2'', @ColumnName=N''bLoadSettings'', @Description=N''Para saber si lo carga el admin. Tipo documentado: bit.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccSettings2'', @ColumnName=N''validate'', @Description=N''No se ocupa en Kolob. Tipo documentado: varchar(255).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoCallsOutData'', @ColumnName=N''cal_id'', @Description=N''Identificador único referente, viene de la tabla ccoCallsOut. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoCallsOutData'', @ColumnName=N''callout_id'', @Description=N''Id del registro marcado, viene de la tabla ccoCallsOutSource. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoCallsOutData'', @ColumnName=N''Data1'', @Description=N''Dato 1 del registro marcado. Tipo documentado: varchar(255).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoCallsOutData'', @ColumnName=N''Data2'', @Description=N''Dato 1 del registro marcado. Tipo documentado: varchar(255).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoCallsOutData'', @ColumnName=N''Data3'', @Description=N''Dato 1 del registro marcado. Tipo documentado: varchar(255).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoCallsOutData'', @ColumnName=N''Data4'', @Description=N''Dato 1 del registro marcado. Tipo documentado: varchar(255).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoCallsOutData'', @ColumnName=N''Data5'', @Description=N''Dato 1 del registro marcado. Tipo documentado: varchar(255).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoCallsOutData'', @ColumnName=N''callDate'', @Description=N''Fecha de marcación. Tipo documentado: datetime.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoLogDialsData'', @ColumnName=N''logDial_id'', @Description=N''Identificador único referente, viene de la tabla ccoLogDials. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoLogDialsData'', @ColumnName=N''callout_id'', @Description=N''Id del registro marcado, viene de la tabla ccoCallsOutSource. Tipo documentado: int.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoLogDialsData'', @ColumnName=N''Data1'', @Description=N''Dato 1 del registro marcado. Tipo documentado: varchar(255).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoLogDialsData'', @ColumnName=N''Data2'', @Description=N''Dato 1 del registro marcado. Tipo documentado: varchar(255).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoLogDialsData'', @ColumnName=N''Data3'', @Description=N''Dato 1 del registro marcado. Tipo documentado: varchar(255).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoLogDialsData'', @ColumnName=N''Data4'', @Description=N''Dato 1 del registro marcado. Tipo documentado: varchar(255).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoLogDialsData'', @ColumnName=N''Data5'', @Description=N''Dato 1 del registro marcado. Tipo documentado: varchar(255).'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoLogDialsData'', @ColumnName=N''callDate'', @Description=N''Fecha de marcación. Tipo documentado: datetime.'';

EXEC dbo.usp_SetColumnDescription @SchemaName=N''dbo'', @ObjectName=N''ccoCallsOut'', @ColumnName=N''cal_whoHung'', @Description=N''Los valores más actuales se encuentran en el telephony y son los siguientes: 0 Cliente 1 Agente 2 Encuesta 3 Agente de IA 4 Transferencia a campaña de entrada En versiones anteriores, usando engine 0 Cliente 1 Agente 3 Agente y lo manda a encuesta. Tipo documentado: smallint.'';
'
    exec (@sql)
    

    SET @process = 'Descripciones de tablas Finder'
    SET @sql = '

EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @Description = N''Tabla de conversaciones de chat para campañas de entrada. Contiene datos de campaña, dominio, usuario, sesión, estatus, tiempos de chat/notas/cola, calificación, subcalificación, fecha y cliente.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachatstatus'',
    @Description = N''Catálo de estados de conversación de chat. Define el identificador y la descripción del estatus usado por las conversaciones.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccChatsNode'',
    @Description = N''Tabla para almacenar nodos XML de conversaciones de chat que serán enviados a BaseXServer. Incluye fechas de creación, salida y estado de envío.'';

EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccEmailNode'',
    @Description = N''Tabla para almacenar nodos XML de conversaciones de chat que serán enviados a BaseXServer. Incluye fechas de creación, salida y estado de envío.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccChatsNodeHistory'',
    @Description = N''Tabla histórica para almacenar nodos XML de conversaciones de chat enviados a BaseXServer cuando ya no corresponden al día actual.'';

'
    exec (@sql)


    SET @process = 'Descripciones de tablas voz'
    SET @sql = 'EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @Description = N''Tabla de trabajo para registros de marcación de salida en proceso. Contiene teléfono, campaña, estatus, intentos, usuario asignado y datos de zona horaria.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cctipoResultadoDial'',
    @Description = N''Catálo de resultados de marcación utilizados para clasificar el resultado obtenido al marcar un teléfono.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccstatusllamada'',
    @Description = N''Catálo de estados de llamada cuando una llamada entra, espera, se asigna, se atiende, se abandona, se desborda o se cancela.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstotarifa'',
    @Description = N''Tabla de tarifas telefónicas cargadas al sistema para reportes de costos. Define costo de primer minuto y minuto adicional por proveedor y tipo de llamada.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''telefonosConferencia'',
    @Description = N''Catálo de teléfonos configurados para conferencia.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''telefonosTransferencia'',
    @Description = N''Catálo de teléfonos configurados para transferencia.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @Description = N''Tabla transaccional de llamadas de entrada. Almacena ANI, DNIS, inbound, usuario, estado, calificación, tiempos operativos, grabación y datos de colgado.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVRCallsIn'',
    @Description = N''Tabla de llamadas de entrada que pasaron por IVR. Registra IVR, ANI, DNIS, fecha, llamada relacionada y tiempo total dentro del IVR.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVROptions'',
    @Description = N''Tabla de opciones seleccionadas dentro del IVR. Registra opción seleccionada, fecha, tipo de guardado, pregunta, encuesta y llamada relacionada.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVRStructure'',
    @Description = N''Tabla de estructura del IVR. Define rutas o niveles del flujo IVR separados por comas y etiquetas usadas para reporteo.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccdnis'',
    @Description = N''Catálo de DNIS/DID de entrada. Contiene número DID, tipo, identificador, configuración y estatus de bloqueo o habilitación.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstotipollamada'',
    @Description = N''Catálo de tipos de llamada utilizado para clasificación y costeo telefónico por proveedor, prefijo, longitud y país.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstoProvedor'',
    @Description = N''Catálo de proveedores de telefonía dados de alta en el sistema. Incluye descripción, prefijo y códis de carrier.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @Description = N''Tabla origen de registros cargados a campañas de salida o marcación manual. Contiene teléfonos, datos personalizados, estatus, intentos, callback y zona horaria.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @Description = N''Tabla transaccional de llamadas de salida contactadas o manuales. Almacena agente asignado, campaña, calificación, estado, tiempos de llamada, costos, proveedor y grabación.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoDialers'',
    @Description = N''Tabla de dialers o puertos de telefonía configurados. Incluye descripción, puerto, extensión, estatus, proveedor y tipo de transferencia.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @Description = N''Tabla de bitácora de marcaciones realizadas por NuxibaEngine, tanto manuales como predictivas. Guarda resultado de marcación, teléfono, puerto, campaña, tiempos y causa de desconexión.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cccallsreject'',
    @Description = N''Tabla de llamadas rechazadas o no procesadas. Registra ANI, DNIS, puerto, fecha de llamada, inbound y llamada relacionada.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccLogtransfers'',
    @Description = N''Tabla de bitácora de transferencias de llamadas. Registra tipo, modo, destino, tiempos antes y después de transferir, fecha de fin y llamada relacionada.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallbacks'',
    @Description = N''Tabla de callbacks de campañas de salida. Registra campaña, usuario, teléfonos, call key, fechas de callback manual o automático, estatus y scheduler status.'';

'
    exec (@sql)
    

    SET @process = 'Descripciones de columnas de voz'
    SET @sql = 'EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''callout_id'',
    @Description = N''Identificador del registro de marcación de salida.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''cal_telefono'',
    @Description = N''Teléfono principal a marcar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''cal_keyw'',
    @Description = N''Id del registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''intentos'',
    @Description = N''Sin descripción funcional definida en el PDF.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''nTryingContact'',
    @Description = N''Sin descripción funcional definida en el PDF.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''cam_id'',
    @Description = N''Identificador de campaña.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''cal_fechaDial'',
    @Description = N''Fecha programada o de marcación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''cal_status'',
    @Description = N''Estatus del registro: 0 Nuevos, 1 Callback, 2 Procesando.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''user_id'',
    @Description = N''Identificador del usuario asignado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''prioridad_cb'',
    @Description = N''Prioridad del callback.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''nOcupado'',
    @Description = N''Contador de intentos con resultado ocupado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''nNoContesta'',
    @Description = N''Contador de intentos sin contestación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''nFax'',
    @Description = N''Contador de intentos detectados como fax.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''nContestadora'',
    @Description = N''Contador de intentos contestados por contestadora.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''nShortCall'',
    @Description = N''Contador de llamadas cortas.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''nOtro'',
    @Description = N''Contador de resultados tipo Otro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''iZonaHoraria'',
    @Description = N''Zona horaria del registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''calif_id'',
    @Description = N''Identificador de calificación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''tipoResDial_id'',
    @Description = N''Identificador del resultado de marcación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''iZonaHoraria_verano'',
    @Description = N''Zona horaria de verano.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''iZonaHoraria2'',
    @Description = N''Segunda zona horaria del registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''iZonaHoraria_verano2'',
    @Description = N''Segunda zona horaria de verano.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''iZonaHoraria3'',
    @Description = N''Tercera zona horaria del registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''iZonaHoraria_verano3'',
    @Description = N''Tercera zona horaria de verano.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''iZonaHoraria4'',
    @Description = N''Cuarta zona horaria del registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''iZonaHoraria_verano4'',
    @Description = N''Cuarta zona horaria de verano.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''iZonaHoraria5'',
    @Description = N''Quinta zona horaria del registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''iZonaHoraria_verano5'',
    @Description = N''Quinta zona horaria de verano.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''list_id'',
    @Description = N''Identificador de lista.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''nDescartes'',
    @Description = N''Número de descartes.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''id_RAniList'',
    @Description = N''Identificador de lista de ANI rotativo.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''ani_idx'',
    @Description = N''Índice o referencia de ANI.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWorkingTable'',
    @ColumnName = N''timesDiscard'',
    @Description = N''Número de veces descartado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cctipoResultadoDial'',
    @ColumnName = N''tipoResDial_id'',
    @Description = N''Identificador único del resultado de marcación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cctipoResultadoDial'',
    @ColumnName = N''descripcion'',
    @Description = N''Descripción del resultado de marcación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccstatusllamada'',
    @ColumnName = N''statusCall_id'',
    @Description = N''Identificador único del estado de la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccstatusllamada'',
    @ColumnName = N''descripcion'',
    @Description = N''Descripción del estado de la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccstatusllamada'',
    @ColumnName = N''inAbandonConfig'',
    @Description = N''Indica si el estado de llamada se utilizará para realizar callback por abandono.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstotarifa'',
    @ColumnName = N''provedor_id'',
    @Description = N''Identificador del proveedor.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstotarifa'',
    @ColumnName = N''tipoLlamada_id'',
    @Description = N''Tipo de llamada de entrada o salida.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstotarifa'',
    @ColumnName = N''minutoUno'',
    @Description = N''Costo del primer minuto.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstotarifa'',
    @ColumnName = N''minutoAdicional'',
    @Description = N''Costo por minuto adicional.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''telefonosConferencia'',
    @ColumnName = N''numcon_id'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''telefonosConferencia'',
    @ColumnName = N''nombre'',
    @Description = N''Nombre.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''telefonosConferencia'',
    @ColumnName = N''tel'',
    @Description = N''Teléfono.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''telefonosTransferencia'',
    @ColumnName = N''numtra_id'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''telefonosTransferencia'',
    @ColumnName = N''nombre'',
    @Description = N''Nombre.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''telefonosTransferencia'',
    @ColumnName = N''tel'',
    @Description = N''Teléfono.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_id'',
    @Description = N''Identificador único de la llamada de entrada, autoincremental.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''dni_id'',
    @Description = N''Identificador de DNIS por el cual entró la llamada; si no existe alta, usa 0.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_ANI'',
    @Description = N''Identificador de llamadas; número telefónico desde el cual se generó la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_puerto'',
    @Description = N''Identificador del puerto por el cual entró la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''Inbound_id'',
    @Description = N''Identificador único de la especialidad a la que se asignó la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''User_id'',
    @Description = N''Identificador único del usuario que atendió la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_extension'',
    @Description = N''Número de extensión del agente a la que se transfirió la llamada; en IP puede representar la posición.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_colgada'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_Key'',
    @Description = N''Cuando una llamada es transferida a una especialidad, contiene el cal_id o callout_id de la llamada origen.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''statusCall_id'',
    @Description = N''Identificador del estado de la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''calif_id'',
    @Description = N''Identificador de la calificación asignada a la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_que'',
    @Description = N''Indica si la llamada estuvo en cola de espera: 1 entró a cola, 0 no entró.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_tDialog'',
    @Description = N''Segundos que la llamada estuvo en diálo.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_tNotas'',
    @Description = N''Segundos que la llamada estuvo en estado Notas.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_tWait'',
    @Description = N''Segundos que la llamada estuvo en cola de espera.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_tXfer'',
    @Description = N''Segundos que la llamada estuvo en transferencia; para posiciones IP normalmente es 0.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_tCall'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_tRing'',
    @Description = N''Tiempo que estuvo timbrando la llamada antes de ser contestada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_Xfer'',
    @Description = N''Fecha y hora en la cual la llamada se transfirió a un agente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_Inicio'',
    @Description = N''Fecha y hora en la cual la llamada fue contestada por el sistema.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_Opciones'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_origin_id'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''rec_grabId'',
    @Description = N''Identificador del archivo de grabación de la llamada; utilizado en una versión anterior de integración con AVRS.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''rec_fechaInicio'',
    @Description = N''Fecha y hora en la cual se iniciaba la grabación; utilizado en integración anterior con AVRS.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''rec_duracion'',
    @Description = N''Duración de la grabación de la llamada; utilizado en integración anterior con AVRS.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''fvalida'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_tMoh'',
    @Description = N''Segundos que la llamada estuvo retenida o en espera por el agente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''cal_whoHung'',
    @Description = N''Indica quién colgó la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''califSub_id'',
    @Description = N''Identificador de la subcalificación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''IVR_id'',
    @Description = N''Identificador del IVR.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccCallsIn'',
    @ColumnName = N''file_moved'',
    @Description = N''Indica si el archivo de grabación se encuentra local, remoto o no se grabó: 0 Local, 1 Remoto, 2 No se grabó.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVRCallsIn'',
    @ColumnName = N''IVR_id'',
    @Description = N''Identificador del IVR.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVRCallsIn'',
    @ColumnName = N''cal_ani'',
    @Description = N''ANI.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVRCallsIn'',
    @ColumnName = N''date'',
    @Description = N''Fecha.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVRCallsIn'',
    @ColumnName = N''dnis'',
    @Description = N''Descripción de DNIS.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVRCallsIn'',
    @ColumnName = N''callout_id'',
    @Description = N''Id de llamada; puede ser de salida o de entrada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVRCallsIn'',
    @ColumnName = N''tincall'',
    @Description = N''Tiempo total que duró el IVR.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVROptions'',
    @ColumnName = N''IVR_id'',
    @Description = N''Identificador del IVR.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVROptions'',
    @ColumnName = N''selectedOption'',
    @Description = N''Opción seleccionada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVROptions'',
    @ColumnName = N''date'',
    @Description = N''Fecha.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVROptions'',
    @ColumnName = N''saveType'',
    @Description = N''Modo de guardado: 0 No guarda dígito, 1 Guarda menú o un dígito, 2 Guarda conjunto de dígitos.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVROptions'',
    @ColumnName = N''questionId'',
    @Description = N''Identificador de la pregunta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVROptions'',
    @ColumnName = N''surveyId'',
    @Description = N''Identificador de la encuesta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVROptions'',
    @ColumnName = N''cal_id'',
    @Description = N''Identificador de llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVRStructure'',
    @ColumnName = N''IdScript'',
    @Description = N''Identificador del IVR.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVRStructure'',
    @ColumnName = N''Level'',
    @Description = N''Camino para diferenciar el flujo del IVR; los dígitos deben ir separados por comas.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''IVRStructure'',
    @ColumnName = N''Description'',
    @Description = N''Etiqueta usada para generar el reporte.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccdnis'',
    @ColumnName = N''dni_id'',
    @Description = N''Identificador de DID, autoincremental y único.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccdnis'',
    @ColumnName = N''dni_numero'',
    @Description = N''Número de DID.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccdnis'',
    @ColumnName = N''dni_tipo'',
    @Description = N''Tipo de DID; valor default 2.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccdnis'',
    @ColumnName = N''tipodni_id'',
    @Description = N''Tipo de ID del DID; valor default 1.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccdnis'',
    @ColumnName = N''dni_tpoMaxEspera'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccdnis'',
    @ColumnName = N''dni_Descripcion'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccdnis'',
    @ColumnName = N''dni_Status'',
    @Description = N''Estatus del DNIS: habilitado o inhabilitado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccdnis'',
    @ColumnName = N''dni_isBlock'',
    @Description = N''Estatus de bloqueo del DNIS.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstotipollamada'',
    @ColumnName = N''country_id'',
    @Description = N''Identificador del proveedor.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstotipollamada'',
    @ColumnName = N''tipoLlamada_id'',
    @Description = N''Identificador del tipo de llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstotipollamada'',
    @ColumnName = N''descrip'',
    @Description = N''Descripción del tipo de llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstotipollamada'',
    @ColumnName = N''prefijo'',
    @Description = N''Prefijo asociado al tipo de llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstotipollamada'',
    @ColumnName = N''longitud'',
    @Description = N''Tamaños aceptados para diferenciar los tipos de llamadas, separados por ''''|''''.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstoprovedor'',
    @ColumnName = N''provedor_id'',
    @Description = N''Identificador del proveedor, autoincremental y único.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstoprovedor'',
    @ColumnName = N''descrip'',
    @Description = N''Nombre del proveedor.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstoprovedor'',
    @ColumnName = N''prefix'',
    @Description = N''Prefijo de marcación por proveedor.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cstoprovedor'',
    @ColumnName = N''codiCarrierBR'',
    @Description = N''Códis de marcación para proveedores de Brasil.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''callout_id'',
    @Description = N''Identificador único del registro cargado a una campaña.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''cal_Key'',
    @Description = N''Referencia asignada por el usuario al realizar la carga de registros.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''cam_id'',
    @Description = N''Identificador o referencia de campaña asignada en la carga de registros.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''cal_telefono'',
    @Description = N''Teléfono principal.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''cal_telefono2'',
    @Description = N''Segundo teléfono opcional.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''cal_telefono3'',
    @Description = N''Tercer teléfono opcional.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''cal_telefono4'',
    @Description = N''Cuarto teléfono opcional.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''cal_telefono5'',
    @Description = N''Quinto teléfono opcional.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''cal_callback'',
    @Description = N''Callback.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''cal_status'',
    @Description = N''Estatus de llamada: 0 nuevos, 1 callback, 2 progreso, 3 finalizados, 4 working table, 5 posible eliminación, 6 llamada manual, 7 no definido en PDF.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''cal_intentos'',
    @Description = N''Número de intentos.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''user_id'',
    @Description = N''Identificador del usuario.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''cal_fechaDial'',
    @Description = N''Fecha utilizada para tomar el callback; se establece durante la carga de base de datos.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''nOcupado'',
    @Description = N''Número de teléfonos ocupados.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''nNoContesta'',
    @Description = N''Número de teléfonos no contestados.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''nFax'',
    @Description = N''Número de teléfonos detectados como fax.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''nContestadora'',
    @Description = N''Número de teléfonos contestados por contestadora.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''nShortCall'',
    @Description = N''Número de llamadas cortas definido a partir de un setting.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''nOtro'',
    @Description = N''Número de resultados tipo Otro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''Dato1'',
    @Description = N''Dato 1.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''Dato2'',
    @Description = N''Dato 2.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''Dato3'',
    @Description = N''Dato 3.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''Dato4'',
    @Description = N''Dato 4.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''Dato5'',
    @Description = N''Dato 5.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''last_Dialed'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''Dial_tels'',
    @Description = N''Orden de marcación de teléfonos: cal_telefono, cal_telefono2, etc.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''iZonaHoraria'',
    @Description = N''Zona horaria a la que se marca.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''iZonaHoraria_verano'',
    @Description = N''Zona horaria a la que se marca en verano.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''iZonaHoraria2'',
    @Description = N''Segunda zona horaria.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''iZonaHoraria_verano2'',
    @Description = N''Segunda zona horaria de verano.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''iZonaHoraria3'',
    @Description = N''Tercera zona horaria.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''iZonaHoraria_verano3'',
    @Description = N''Tercera zona horaria de verano.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''iZonaHoraria4'',
    @Description = N''Cuarta zona horaria.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''iZonaHoraria_verano4'',
    @Description = N''Cuarta zona horaria de verano.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''iZonaHoraria5'',
    @Description = N''Quinta zona horaria.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''iZonaHoraria_verano5'',
    @Description = N''Quinta zona horaria de verano.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''list_id'',
    @Description = N''Identificador para asociar la carga de base de datos.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''Region'',
    @Description = N''Región.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''file_moved'',
    @Description = N''Indica si el archivo de grabación se encuentra en repositorio remoto o local del engine.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOutSource'',
    @ColumnName = N''international'',
    @Description = N''Indica si el registro debe ser marcado por un puerto internacional.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_id'',
    @Description = N''Identificador del registro contactado, único y autoincremental.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''callout_id'',
    @Description = N''Identificador del registro único y autoincremental según el orden de carga a campaña.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_telefono'',
    @Description = N''Número telefónico tal cual fue marcado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_puerto'',
    @Description = N''Identificador único del puerto por el cual se realizó la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cam_id'',
    @Description = N''Identificador único de la campaña a la cual pertenece el registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''User_id'',
    @Description = N''Identificador único del agente al cual fue asignada la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_extension'',
    @Description = N''Número de extensión del agente a quien se transfirió la llamada; si es negativo indica posición IP.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_colgada'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_Key'',
    @Description = N''Identificador del registro especificado por el usuario durante la carga.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''statusCall_id'',
    @Description = N''Identificador del estado de la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''calif_id'',
    @Description = N''Identificador de la calificación asignada a la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_que'',
    @Description = N''Tiempo o indicador de cola de espera.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_tDialog'',
    @Description = N''Segundos que duró la llamada en estado de diálo.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_tNotas'',
    @Description = N''Segundos que duró la llamada en estado de notas.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_tXfer'',
    @Description = N''Segundos que duró la llamada en transferencia; cuando es IP suele ser casi nulo.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_tRing'',
    @Description = N''Segundos que duró la llamada en estado de timbrado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_Inicio'',
    @Description = N''Fecha y hora en la cual la llamada entró en estado de diálo.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_fcallback'',
    @Description = N''Fecha y hora en la cual se programó la llamada para volver a marcarse.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_manual'',
    @Description = N''Indica el tipo de llamada: 0 predictivo, 1 manual no contestada, 2 manual contestada, 3 manual transferencia de chat.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_tDialogDialer'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_tLineBusy'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''costo'',
    @Description = N''Costo de la llamada; requiere costos por tipo de llamada del carrier asignado a los puertos de la campaña.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''provedor_id'',
    @Description = N''Identificador del proveedor de telefonía asignado al puerto por donde se realizó la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''tipoLlamada_id'',
    @Description = N''Identificador del tipo de llamada al cual pertenece el registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''rec_grabId'',
    @Description = N''Identificador del archivo de grabación vinculado a TREC_GRABACION en CCRecorderV2; usado anteriormente para integración AVRS.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''rec_fechaInicio'',
    @Description = N''Fecha y hora de inicio de grabación; campo usado en versiones anteriores de integración AVRS.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''rec_duracion'',
    @Description = N''Segundos de duración de la grabación; campo usado en versiones anteriores de integración AVRS.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''fvalida'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_tMoh'',
    @Description = N''Tiempo que la llamada estuvo retenida por el agente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_whoHung'',
    @Description = N''Participante que colgó la llamada: 0 remoto/cliente, 1 agente, 2 transferida a encuesta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''tConnTime'',
    @Description = N''Tiempo de conexión cuando se usa Live Connect.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''tBridgeTime'',
    @Description = N''Tiempo de timbrado cuando se usa Live Connect.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''cal_twait'',
    @Description = N''Tiempo en segundos antes de hacer la transferencia al agente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallsOut'',
    @ColumnName = N''califSub_id'',
    @Description = N''Subcalificación relacionada con cctipocalifsubout.califSub_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoDialers'',
    @ColumnName = N''Dialer_id'',
    @Description = N''Identificador del dialer.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoDialers'',
    @ColumnName = N''Descripcion'',
    @Description = N''Descripción del dialer.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoDialers'',
    @ColumnName = N''Puerto'',
    @Description = N''Número del puerto.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoDialers'',
    @ColumnName = N''Extension'',
    @Description = N''Extensión.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoDialers'',
    @ColumnName = N''Status'',
    @Description = N''Estatus del puerto: 1 activo, 0 inactivo.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoDialers'',
    @ColumnName = N''provedor_id'',
    @Description = N''Identificador del proveedor.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoDialers'',
    @ColumnName = N''XferType'',
    @Description = N''Tipo de transferencia: 1 Interna, 2 Externa, 3 Ambos.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''logDial_id'',
    @Description = N''Identificador único de la llamada, autoincremental.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''callout_id'',
    @Description = N''Identificador único del registro al que pertenece la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''cam_id'',
    @Description = N''Identificador único de la campaña a la que pertenece la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''tipoResDial_id'',
    @Description = N''Identificador del resultado de marcación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''Telefono'',
    @Description = N''Número telefónico marcado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''Puerto'',
    @Description = N''Identificador del puerto por el cual se realizó la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''fecha'',
    @Description = N''Fecha y hora en la cual se inició la marcación del teléfono.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''tDialing'',
    @Description = N''Tiempo que estuvo timbrando la llamada antes de obtener un resultado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''tBusy'',
    @Description = N''Inhabilitar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''answerbit'',
    @Description = N''Indica si la llamada fue contestada: 1 contestada, 0 cualquier otro resultado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''TipoDialingMode'',
    @Description = N''Contiene reintentos, callback, llamada efectiva y marca de tipo selectiva.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''cal_id'',
    @Description = N''Identificador de llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''tAnswerBit'',
    @Description = N''Indica si la llamada fue cobrada por el carrier.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''canceledNoAgents'',
    @Description = N''Indica que la llamada se canceló por falta de agentes disponibles y debe reintentarse cuando haya agentes.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''disconnectCause'',
    @Description = N''Causa de error almacenada como Otro, a partir de respuestas SIP.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoLogDials'',
    @ColumnName = N''cal_key'',
    @Description = N''Valor proporcionado por el cliente para identificar el registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cccallsreject'',
    @ColumnName = N''cal_id'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cccallsreject'',
    @ColumnName = N''ani'',
    @Description = N''Número ANI.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cccallsreject'',
    @ColumnName = N''dnis'',
    @Description = N''Número DNIS.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cccallsreject'',
    @ColumnName = N''puerto'',
    @Description = N''Número de puerto.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cccallsreject'',
    @ColumnName = N''cal_inicio'',
    @Description = N''Fecha en la cual se realiza la llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''cccallsreject'',
    @ColumnName = N''Inbound_id'',
    @Description = N''Clave de inbound.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccLogtransfers'',
    @ColumnName = N''cal_id'',
    @Description = N''Identificador de llamada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccLogtransfers'',
    @ColumnName = N''tipo'',
    @Description = N''Tipo de transferencia: 1 ACD, 2 Campaña.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccLogtransfers'',
    @ColumnName = N''modo'',
    @Description = N''Modo de transferencia: 0 ciega, 1 agente, 2 grupo ACD, 3 conferencia, 4 supervisada, 5 desborde, 6 asistida, 7 callback press 8.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccLogtransfers'',
    @ColumnName = N''destino'',
    @Description = N''Destino de la transferencia.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccLogtransfers'',
    @ColumnName = N''tAntesXfer'',
    @Description = N''Tiempo antes de transferir.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccLogtransfers'',
    @ColumnName = N''tDespuesXfer'',
    @Description = N''Tiempo después de transferir.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccLogtransfers'',
    @ColumnName = N''fechaFin'',
    @Description = N''Fecha en que terminó la transferencia.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallbacks'',
    @ColumnName = N''callout_id'',
    @Description = N''Clave primaria del registro en ccoCallsOutSource.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallbacks'',
    @ColumnName = N''user_id'',
    @Description = N''Clave primaria de usuario en ccUsers.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallbacks'',
    @ColumnName = N''cam_id'',
    @Description = N''Clave primaria de campaña en ccCamps.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallbacks'',
    @ColumnName = N''cal_key'',
    @Description = N''Id de registro del cliente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallbacks'',
    @ColumnName = N''cal_telefono'',
    @Description = N''Teléfono.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallbacks'',
    @ColumnName = N''cal_telCB'',
    @Description = N''Teléfono en callback.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallbacks'',
    @ColumnName = N''cal_fecha'',
    @Description = N''Fecha del callback.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallbacks'',
    @ColumnName = N''cal_fusercallback'',
    @Description = N''Fecha en que el agente realiza un callback manual.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallbacks'',
    @ColumnName = N''cal_fcallback'',
    @Description = N''Fecha en que el sistema realiza un callback automático.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallbacks'',
    @ColumnName = N''status'',
    @Description = N''Estatus: 1 registros nuevos, 2 Ring/CallNoAnswered, 3 reciclado, 6 reciclado callback admin.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoCallbacks'',
    @ColumnName = N''schedulerStatus'',
    @Description = N''Estatus del scheduler: 1 nuevo registro; usado por jobs CW.'';

'
    exec (@sql)

    SET @process = 'Descripciones columnas chat'
    SET @sql = 'EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''chatId'',
    @Description = N''Identificador del chat.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''inboundId'',
    @Description = N''Identificador de la tabla ccinbound.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''domain'',
    @Description = N''Dominio para identificar el chat.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''userId'',
    @Description = N''Identificador de ccUsers.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''session'',
    @Description = N''Sesión de chat.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''chatStatus'',
    @Description = N''Estatus del chat.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''tChatting'',
    @Description = N''Tiempo de chat.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''tWrapUp'',
    @Description = N''Tiempo de notas.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''requestDate'',
    @Description = N''Fecha de solicitud de chat.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''finishedBy'',
    @Description = N''Indica por quién fue terminada la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''onQueue'',
    @Description = N''Indica si el chat estuvo en cola o tiempo de espera.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''tQueue'',
    @Description = N''Tiempo máximo de llamadas o conversaciones en espera.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''tTimeout'',
    @Description = N''Tiempo para terminar la conversación si alguno de los dos participantes no envía mensajes.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''disposition'',
    @Description = N''Calificación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''subDisposition'',
    @Description = N''Subcalificación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''chatDate'',
    @Description = N''Fecha del chat.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''clientName'',
    @Description = N''Nombre del cliente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachats'',
    @ColumnName = N''firstMessageTime'',
    @Description = N''Fecha en que llega el primer mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachatstatus'',
    @ColumnName = N''id'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccriachatstatus'',
    @ColumnName = N''description'',
    @Description = N''Descripción del estatus del chat.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccChatsNode'',
    @ColumnName = N''chatId'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccChatsNode'',
    @ColumnName = N''node'',
    @Description = N''Archivo XML que se pasará a BaseXServer.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccChatsNode'',
    @ColumnName = N''dateIn'',
    @Description = N''Fecha de creación del registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccChatsNode'',
    @ColumnName = N''dateOut'',
    @Description = N''Fecha en que se pasó a la base del servidor.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccChatsNode'',
    @ColumnName = N''status'',
    @Description = N''Estado de paso de información a BaseXServer.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccChatsNodeHistory'',
    @ColumnName = N''chatId'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccChatsNodeHistory'',
    @ColumnName = N''node'',
    @Description = N''Archivo XML que se pasará a BaseXServer.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccChatsNodeHistory'',
    @ColumnName = N''dateIn'',
    @Description = N''Fecha de creación del registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccChatsNodeHistory'',
    @ColumnName = N''dateOut'',
    @Description = N''Fecha en que se pasó a la base del servidor.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccChatsNodeHistory'',
    @ColumnName = N''status'',
    @Description = N''Estado de paso de información a BaseXServer.'';

'
    exec (@sql)
    

    SET @process = 'Descripciones columnas whatsapp'
    SET @sql = 'EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppConfigurations'',
    @Description = N''Tabla para registrar las URLs de Meta usadas para envío de mensajes y gestión de plantillas.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWebhooksConfigurations'',
    @Description = N''Tabla para registrar la configuración de webhooks de Meta WhatsApp.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppNumber'',
    @Description = N''Tabla para registrar números configurados en Meta, relacionarlos con campañas y definir datos de envío de mensajes y gestión de plantillas.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @Description = N''Tabla para registrar plantillas dadas de alta en Meta WhatsApp.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutSource'',
    @Description = N''Tabla para almacenar registros cargados para envío de mensajes WhatsApp.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWaWorkingTable'',
    @Description = N''Tabla de trabajo donde se guardan datos de registros cargados que serán tomados por el outbound de WhatsApp.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @Description = N''Tabla donde se registran los mensajes de WhatsApp enviados.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccVonageConfigurations'',
    @Description = N''Tabla para configuración de números de WhatsApp usados para conectar con CenterWare mediante Vonage.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNumbers'',
    @Description = N''Tabla de números dados de alta en Vonage y su relación con campañas de entrada o salida tipo WhatsApp.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppSpam'',
    @Description = N''Tabla para registrar números de clientes marcados como spam por campaña.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsentMessages'',
    @Description = N''Tabla de mensajes que no se enviaron desde WhatsWebApi a Multimedia Commons.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetMessagesMCSbyWebApi'',
    @Description = N''Tabla para mensajes retenidos cuando se pierde la comunicación de Multimedia Commons hacia la WebApi.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetStatusMessages'',
    @Description = N''Tabla para estados de mensajes que no se enviaron desde WhatsWebApi a Multimedia Commons.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @Description = N''Tabla de conversaciones de WhatsApp de entrada.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @Description = N''Tabla de mensajes asociados a conversaciones de WhatsApp de entrada.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversations'',
    @Description = N''Tabla de métricas promedio de conversaciones de WhatsApp de entrada para dashboard.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAConversationsResult'',
    @Description = N''Tabla de resultados agregados de mensajes de WhatsApp por campaña.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsRelationship'',
    @Description = N''Tabla de relación entre conversaciones de WhatsApp de entrada anteriores y siguientes.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNode'',
    @Description = N''Tabla para guardar nodos de WhatsApp de entrada que se pasarán a BaseXServer.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeHistory'',
    @Description = N''Tabla histórica para guardar nodos de WhatsApp de entrada que se pasarán a BaseXServer.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @Description = N''Tabla de conversaciones de WhatsApp de salida.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @Description = N''Tabla de mensajes asociados a conversaciones de WhatsApp de salida.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversationsOut'',
    @Description = N''Tabla de métricas promedio de conversaciones de WhatsApp de salida para dashboard.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsRelationshipOut'',
    @Description = N''Tabla de relación entre conversaciones de WhatsApp de salida anteriores y siguientes.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutboundTemplates'',
    @Description = N''Tabla de plantillas WhatsApp dadas de alta en CenterWare y validadas por Meta.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutNode'',
    @Description = N''Tabla para guardar nodos de WhatsApp de salida que se pasarán a BaseXServer.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutNodeHistory'',
    @Description = N''Tabla histórica para guardar nodos de WhatsApp de salida que se pasarán a BaseXServer.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppGlobalIds'',
    @Description = N''Tabla para agrupar conversaciones WhatsApp facturables por número asociado y cliente.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppGlobalIdsRelationship'',
    @Description = N''Tabla de relación entre GlobalId y conversaciones WhatsApp.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeOut'',
    @Description = N''Tabla para guardar nodos de WhatsApp de salida que se pasarán a BaseXServer.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeHistoryOut'',
    @Description = N''Tabla histórica para guardar nodos de WhatsApp de salida que se pasarán a BaseXServer.'';

EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccAVRSTransfer'',
    @Description = N''Relacion de registros llamadas de entrada y salida con el cal_id para pasar al finder.'';    

'
    exec (@sql)

    SET @process = 'Descripciones columnas whatsapp'
    SET @sql = 'EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppConfigurations'',
    @ColumnName = N''Id'',
    @Description = N''Identificador de la URL.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppConfigurations'',
    @ColumnName = N''Url'',
    @Description = N''URL de Meta para envío de mensajes o gestión de plantillas.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppConfigurations'',
    @ColumnName = N''Description'',
    @Description = N''Descripción de la URL.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWebhooksConfigurations'',
    @ColumnName = N''Id'',
    @Description = N''Identificador del webhook.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWebhooksConfigurations'',
    @ColumnName = N''Controller'',
    @Description = N''Módulo/Action donde se recibirá la información del webhook.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWebhooksConfigurations'',
    @ColumnName = N''Token'',
    @Description = N''Token del webhook.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppNumber'',
    @ColumnName = N''MetaId'',
    @Description = N''Identificador del número de teléfono.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppNumber'',
    @ColumnName = N''Number'',
    @Description = N''Número de teléfono dado de alta en Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppNumber'',
    @ColumnName = N''Status'',
    @Description = N''Estado del número de teléfono.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppNumber'',
    @ColumnName = N''Inbound_Id'',
    @Description = N''Identificador de campaña de entrada relacionada con ccInbound.Inbound_Id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppNumber'',
    @ColumnName = N''Cam_Id'',
    @Description = N''Identificador de campaña de salida relacionada con ccCamps.Cam_Id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppNumber'',
    @ColumnName = N''PhoneNumberId'',
    @Description = N''Identificador de número de teléfono en Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppNumber'',
    @ColumnName = N''Token'',
    @Description = N''Token de acceso de Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppNumber'',
    @ColumnName = N''WaAccountId'',
    @Description = N''Identificador de la cuenta de WhatsApp en Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWhatsAppNumber'',
    @ColumnName = N''IdApp'',
    @Description = N''Identificador de la aplicación en Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''Id'',
    @Description = N''Identificador de la plantilla en Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''Catery'',
    @Description = N''Catería de la plantilla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''TemplateName'',
    @Description = N''Nombre de la plantilla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''AllowCateryChange'',
    @Description = N''Permite que Meta cambie la catería de la plantilla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''LanguageCode'',
    @Description = N''Idioma de la plantilla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''Status'',
    @Description = N''Estado de la plantilla en Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''Header'',
    @Description = N''Encabezado de la plantilla en formato JSON.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''Body'',
    @Description = N''Cuerpo del mensaje en formato JSON.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''Footer'',
    @Description = N''Pie de la plantilla en formato JSON.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''Buttons'',
    @Description = N''Botones de la plantilla en formato JSON.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''MetaId'',
    @Description = N''Identificador del número de teléfono relacionado con ccMetaWhatsAppNumbers.MetaId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''RemovalDate'',
    @Description = N''Fecha de eliminación de la plantilla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''StatusCW'',
    @Description = N''Estado de la plantilla en el sistema: 1 activa, 0 inactiva.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''Quality'',
    @Description = N''Calidad de la plantilla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''Notes'',
    @Description = N''Razón de rechazo de la plantilla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWaOutboundTemplates'',
    @ColumnName = N''FilePath'',
    @Description = N''Ruta del servidor donde se guarda el archivo.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutSource'',
    @ColumnName = N''WAOutId'',
    @Description = N''Identificador del registro en la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutSource'',
    @ColumnName = N''CallKey'',
    @Description = N''Identificador del registro seleccionado en las variables.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutSource'',
    @ColumnName = N''CamId'',
    @Description = N''Identificador de la campaña.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutSource'',
    @ColumnName = N''PhoneNumber'',
    @Description = N''Número de teléfono del destinatario.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutSource'',
    @ColumnName = N''Status'',
    @Description = N''Estado del registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutSource'',
    @ColumnName = N''TimeZone'',
    @Description = N''Zona horaria.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutSource'',
    @ColumnName = N''TimeZone_summer'',
    @Description = N''Zona horaria de verano.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutSource'',
    @ColumnName = N''ListId'',
    @Description = N''Identificador de la lista a la que pertenece el registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutSource'',
    @ColumnName = N''UserId'',
    @Description = N''Identificador del usuario que realizó la carga.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutSource'',
    @ColumnName = N''TamplateId'',
    @Description = N''Identificador de la plantilla relacionada con ccMetaWaOutboundTemplates.Id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutSource'',
    @ColumnName = N''ComponentJson'',
    @Description = N''Mensaje en formato JSON.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWaWorkingTable'',
    @ColumnName = N''WAOutId'',
    @Description = N''Identificador del registro relacionado con ccWhatsAppSource.WAOutId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWaWorkingTable'',
    @ColumnName = N''CallKey'',
    @Description = N''Identificador del registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWaWorkingTable'',
    @ColumnName = N''CamId'',
    @Description = N''Identificador de campaña.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWaWorkingTable'',
    @ColumnName = N''PhoneNumber'',
    @Description = N''Número de teléfono del destinatario.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWaWorkingTable'',
    @ColumnName = N''WaStatus'',
    @Description = N''Estado del registro: 0 nuevo, 1 procesado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWaWorkingTable'',
    @ColumnName = N''TimeZone'',
    @Description = N''Zona horaria.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWaWorkingTable'',
    @ColumnName = N''TimeZone_Summer'',
    @Description = N''Zona horaria de verano.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWaWorkingTable'',
    @ColumnName = N''DateDial'',
    @Description = N''Fecha de carga del registro.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWaWorkingTable'',
    @ColumnName = N''UserId'',
    @Description = N''Identificador del usuario que realizó la carga.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''MetaId'',
    @Description = N''Identificador del mensaje o registro en Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''WaOutId'',
    @Description = N''Identificador del registro relacionado con ccWhatsAppSource.WAOutId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''CamId'',
    @Description = N''Identificador de campaña.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''RegistryClient'',
    @Description = N''CallKey del cliente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''PhoneClient'',
    @Description = N''Número de teléfono destino.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''PhoneWa'',
    @Description = N''Número de teléfono de WhatsApp remitente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''Type'',
    @Description = N''Tipo de mensaje: Manual o Template.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''Contented'',
    @Description = N''Mensaje enviado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''Bill'',
    @Description = N''Costo del mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''TimeSpan'',
    @Description = N''Fecha de envío.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''ConversationId'',
    @Description = N''Identificador de la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''ErrorCode'',
    @Description = N''Códi de error.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''ErrorMessage'',
    @Description = N''Mensaje de error.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccoWhatsLogDials'',
    @ColumnName = N''Status'',
    @Description = N''Estado del mensaje en Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccVonageConfigurations'',
    @ColumnName = N''vonageId'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccVonageConfigurations'',
    @ColumnName = N''serviceType'',
    @Description = N''Tipo de servicio; actualmente solo se usa WhatsApp (5).'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccVonageConfigurations'',
    @ColumnName = N''applicationId'',
    @Description = N''Identificador de aplicación dado de alta en Vonage.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccVonageConfigurations'',
    @ColumnName = N''secretKey'',
    @Description = N''Clave única por cuenta dada de alta en Vonage.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccVonageConfigurations'',
    @ColumnName = N''messagesUrl'',
    @Description = N''URL donde se envían los mensajes del agente al cliente; por default https://api.nexmo.com/v0.1/messages.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNumbers'',
    @ColumnName = N''vonageId'',
    @Description = N''Identificador de configuración Vonage relacionado con ccVonageConfigurations.vonageId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNumbers'',
    @ColumnName = N''number'',
    @Description = N''Número de WhatsApp dado de alta en Vonage.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNumbers'',
    @ColumnName = N''inboundId'',
    @Description = N''Identificador de campaña de entrada relacionado con ccinbound.Inbound_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNumbers'',
    @ColumnName = N''status'',
    @Description = N''Indica si está activa la cuenta de Vonage.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNumbers'',
    @ColumnName = N''camp_id'',
    @Description = N''Identificador de campaña de salida relacionado con cccamps.cam_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppSpam'',
    @ColumnName = N''WhatsAppSpamId'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppSpam'',
    @ColumnName = N''InboundId'',
    @Description = N''Identificador de campaña de entrada relacionado con ccInbound.Inbound_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppSpam'',
    @ColumnName = N''AgentId'',
    @Description = N''Identificador del agente relacionado con ccUsers.User_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppSpam'',
    @ColumnName = N''ConversationId'',
    @Description = N''Identificador de conversación relacionado con ccWhatsAppConversations.conversationId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppSpam'',
    @ColumnName = N''Fecha'',
    @Description = N''Fecha cuando se colocó el número como spam.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppSpam'',
    @ColumnName = N''NumberClient'',
    @Description = N''Número de WhatsApp del cliente colocado en spam.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsentMessages'',
    @ColumnName = N''Message_uuid'',
    @Description = N''Identificador de Vonage para el mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsentMessages'',
    @ColumnName = N''ClientNumber'',
    @Description = N''Número del cliente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsentMessages'',
    @ColumnName = N''VonageNumber'',
    @Description = N''Número dado de alta en Vonage.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsentMessages'',
    @ColumnName = N''Timestamp'',
    @Description = N''Fecha del mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsentMessages'',
    @ColumnName = N''MessageType'',
    @Description = N''Tipo de mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsentMessages'',
    @ColumnName = N''Content'',
    @Description = N''JSON con la información que se reenviará.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetMessagesMCSbyWebApi'',
    @ColumnName = N''Id'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetMessagesMCSbyWebApi'',
    @ColumnName = N''Content'',
    @Description = N''JSON del mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetStatusMessages'',
    @ColumnName = N''Message_uuid'',
    @Description = N''Identificador de Vonage para el mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetStatusMessages'',
    @ColumnName = N''ClientNumber'',
    @Description = N''Número del cliente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetStatusMessages'',
    @ColumnName = N''VonageNumber'',
    @Description = N''Número dado de alta en Vonage.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetStatusMessages'',
    @ColumnName = N''Timestamp'',
    @Description = N''Fecha del mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetStatusMessages'',
    @ColumnName = N''MessageType'',
    @Description = N''Tipo de mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetStatusMessages'',
    @ColumnName = N''Status'',
    @Description = N''Estado del mensaje: delivered, submited, N/A o rejected.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetStatusMessages'',
    @ColumnName = N''Currency'',
    @Description = N''Tipo de moneda.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetStatusMessages'',
    @ColumnName = N''Price'',
    @Description = N''Costo del mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetStatusMessages'',
    @ColumnName = N''Client_ref'',
    @Description = N''Referencia del envío del mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppUnsetStatusMessages'',
    @ColumnName = N''Content'',
    @Description = N''Mensaje que se enviará a Multimedia WebApi.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''conversationId'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''inboundId'',
    @Description = N''Identificador de campaña de entrada relacionado con ccInbound.Inbound_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''phoneACD'',
    @Description = N''Teléfono asociado de WhatsApp.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''clientId'',
    @Description = N''Teléfono del cliente que envía el mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''conversationStatus'',
    @Description = N''Estado de la conversación relacionado con messageStatus.messageStatusId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''tChatting'',
    @Description = N''Tiempo en que el agente está en diálo de WhatsApp o escribiendo.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''tConversation'',
    @Description = N''Tiempo total desde que se responde hasta que termina la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''tWrapUp'',
    @Description = N''Tiempo de notas.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''requestDate'',
    @Description = N''Fecha en que llegó el mensaje al sistema para entrada o fecha de creación para salida.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''finishedBy'',
    @Description = N''Indica quién finalizó la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''onQueue'',
    @Description = N''Indica si entró en cola de espera.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''tQueue'',
    @Description = N''Tiempo que duró en cola, en segundos.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''tTimeout'',
    @Description = N''Tiempo en que terminó la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''disposition'',
    @Description = N''Calificación relacionada con Cctipocalif.calif_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''subDisposition'',
    @Description = N''Subcalificación relacionada con cctipocalifsub.califSub_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''conversationDate'',
    @Description = N''Fecha desde que se responde a la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''assignDate'',
    @Description = N''Fecha desde que se asigna al agente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''agentId'',
    @Description = N''Identificador del agente relacionado con ccUsers.User_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''FirstMessageAgent'',
    @Description = N''Fecha de envío del primer mensaje del agente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversations'',
    @ColumnName = N''IsAgentLogginut'',
    @Description = N''Indica si el agente se desconecta y aún tiene conversaciones; se usa para reasignación de mensajes.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''messageId'',
    @Description = N''Identificador de los mensajes.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''conversationId'',
    @Description = N''Identificador de conversación relacionado con ccWhatsAppConversations.conversationId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''timeStampMessage'',
    @Description = N''Fecha en que se envió el mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''originType'',
    @Description = N''Origen del mensaje: Agent o Client.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''price'',
    @Description = N''Costo del envío por mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''messageIdUi'',
    @Description = N''Identificador para la interfaz del agente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''currency'',
    @Description = N''Tipo de moneda para el precio.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''typeMessage'',
    @Description = N''Tipo de mensaje enviado: text, image, audio, file o template.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''content'',
    @Description = N''Mensaje enviado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''clientNum'',
    @Description = N''Número del cliente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''vonageNum'',
    @Description = N''Número asociado a la campaña de entrada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''timeStampMessageUTC'',
    @Description = N''Fecha en que se envió el mensaje en UTC.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversations'',
    @ColumnName = N''messageStatus'',
    @Description = N''Estado del mensaje: delivered, submited, N/A, rejected o read.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversations'',
    @ColumnName = N''InboundId'',
    @Description = N''Identificador de campaña de entrada relacionado con ccInbound.Inbound_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversations'',
    @ColumnName = N''AverageConversationTime'',
    @Description = N''Tiempo promedio de las conversaciones.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversations'',
    @ColumnName = N''AverageDialogTime'',
    @Description = N''Tiempo promedio de diálo.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversations'',
    @ColumnName = N''AverageWaitingTime'',
    @Description = N''Tiempo promedio en cola de espera.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversations'',
    @ColumnName = N''MaximumWaitingTime'',
    @Description = N''Máximo tiempo de espera en cola.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversations'',
    @ColumnName = N''ServiceLevel'',
    @Description = N''Nivel de servicio.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversations'',
    @ColumnName = N''StatusUpdate'',
    @Description = N''Indica si debe actualizarse la información para el dashboard.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversations'',
    @ColumnName = N''LastUpdate'',
    @Description = N''Fecha de la última actualización.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAConversationsResult'',
    @ColumnName = N''camId'',
    @Description = N''Identificador de campaña relacionado con ccInbound.Inbound_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAConversationsResult'',
    @ColumnName = N''SentMsg'',
    @Description = N''Cantidad de mensajes enviados.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAConversationsResult'',
    @ColumnName = N''Delivered'',
    @Description = N''Cantidad de mensajes entregados.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAConversationsResult'',
    @ColumnName = N''NotDelivered'',
    @Description = N''Cantidad de mensajes no entregados.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAConversationsResult'',
    @ColumnName = N''ReadMsg'',
    @Description = N''Cantidad de mensajes leídos.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAConversationsResult'',
    @ColumnName = N''NotSupported'',
    @Description = N''Cantidad de mensajes no soportados.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsRelationship'',
    @ColumnName = N''relationshipId'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsRelationship'',
    @ColumnName = N''conversationIdBefore'',
    @Description = N''Identificador de conversación anterior relacionado con ccWhatsAppConversations.conversationId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsRelationship'',
    @ColumnName = N''conversationIdAfter'',
    @Description = N''Identificador de conversación siguiente relacionado con ccWhatsAppConversations.conversationId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''conversationId'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''camId'',
    @Description = N''Identificador de campaña relacionado con cccamps.cam_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''phoneCamp'',
    @Description = N''Teléfono asociado de WhatsApp.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''clientId'',
    @Description = N''Teléfono del cliente que envía el mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''conversationStatus'',
    @Description = N''Estado de la conversación relacionado con messageStatus.messageStatusId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''tChatting'',
    @Description = N''Tiempo en que el agente está en diálo de WhatsApp o escribiendo.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''tConversation'',
    @Description = N''Tiempo total desde que se responde hasta que termina la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''tWrapUp'',
    @Description = N''Tiempo de notas.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''requestDate'',
    @Description = N''Fecha en que inició la conversación en el agente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''finishedBy'',
    @Description = N''Indica quién finalizó la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''onQueue'',
    @Description = N''Indica si entró en cola de espera.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''tQueue'',
    @Description = N''Tiempo que duró en cola, en segundos.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''tTimeout'',
    @Description = N''Tiempo en que terminó la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''disposition'',
    @Description = N''Calificación relacionada con Cctipocalif.calif_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''subDisposition'',
    @Description = N''Subcalificación relacionada con cctipocalifsub.califSub_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''conversationDate'',
    @Description = N''Fecha desde que se responde a la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''assignDate'',
    @Description = N''Fecha desde que se asigna al agente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''agentId'',
    @Description = N''Identificador del agente relacionado con ccUsers.User_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsOut'',
    @ColumnName = N''FirstMessageAgent'',
    @Description = N''Fecha de envío del primer mensaje del agente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''messageId'',
    @Description = N''Identificador de los mensajes.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''conversationId'',
    @Description = N''Identificador de conversación relacionado con ccWhatsAppConversationsOut.conversationId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''timeStampMessage'',
    @Description = N''Fecha en que se envió el mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''originType'',
    @Description = N''Origen del mensaje: Agent o Client.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''price'',
    @Description = N''Costo del envío por mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''messageIdUi'',
    @Description = N''Identificador para la interfaz del agente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''currency'',
    @Description = N''Tipo de moneda para el precio.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''typeMessage'',
    @Description = N''Tipo de mensaje enviado: text, image, audio, file o template.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''content'',
    @Description = N''Mensaje enviado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''clientNum'',
    @Description = N''Número del cliente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''vonageNum'',
    @Description = N''Número asociado a la campaña de entrada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''timeStampMessageUTC'',
    @Description = N''Fecha en que se envió el mensaje en UTC.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAMessagesConversationsOut'',
    @ColumnName = N''messageStatus'',
    @Description = N''Estado del mensaje: delivered, submited, N/A, rejected o read.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversationsOut'',
    @ColumnName = N''CamId'',
    @Description = N''Identificador de campaña relacionado con cccamps.cam_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversationsOut'',
    @ColumnName = N''AverageConversationTime'',
    @Description = N''Tiempo promedio de las conversaciones.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversationsOut'',
    @ColumnName = N''AverageDialogTime'',
    @Description = N''Tiempo promedio de diálo.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversationsOut'',
    @ColumnName = N''AverageWaitingTime'',
    @Description = N''Tiempo promedio en cola de espera.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversationsOut'',
    @ColumnName = N''MaximumWaitingTime'',
    @Description = N''Máximo tiempo de espera en cola.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversationsOut'',
    @ColumnName = N''ServiceLevel'',
    @Description = N''Nivel de servicio.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversationsOut'',
    @ColumnName = N''StatusUpdate'',
    @Description = N''Indica si debe actualizarse la información para el dashboard.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWAAverageConversationsOut'',
    @ColumnName = N''LastUpdate'',
    @Description = N''Fecha de la última actualización.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsRelationshipOut'',
    @ColumnName = N''relationshipId'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsRelationshipOut'',
    @ColumnName = N''conversationIdBefore'',
    @Description = N''Identificador de conversación anterior relacionado con ccWhatsAppConversationsOut.conversationId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppConversationsRelationshipOut'',
    @ColumnName = N''conversationIdAfter'',
    @Description = N''Identificador de conversación siguiente relacionado con ccWhatsAppConversationsOut.conversationId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutboundTemplates'',
    @ColumnName = N''TemplateId'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutboundTemplates'',
    @ColumnName = N''Catery'',
    @Description = N''Tipo de plantilla dada de alta en Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutboundTemplates'',
    @ColumnName = N''TemplateName'',
    @Description = N''Nombre de la plantilla dada de alta en Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutboundTemplates'',
    @ColumnName = N''LanguageCode'',
    @Description = N''Idioma dado de alta en Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutboundTemplates'',
    @ColumnName = N''Status'',
    @Description = N''Indica si la plantilla está activa en CenterWare.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutboundTemplates'',
    @ColumnName = N''AsociatedNumber'',
    @Description = N''Número asociado a la plantilla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutboundTemplates'',
    @ColumnName = N''Type'',
    @Description = N''Tipo de mensaje dado de alta; actualmente BODY.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutboundTemplates'',
    @ColumnName = N''Format'',
    @Description = N''Formato del mensaje; actualmente TEXT.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutboundTemplates'',
    @ColumnName = N''Body'',
    @Description = N''Mensaje que se enviará al cliente para vista previa del agente; debe coincidir con Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppGlobalIds'',
    @ColumnName = N''GlobalId'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppGlobalIds'',
    @ColumnName = N''AssociatedNumber'',
    @Description = N''Teléfono asociado a la campaña.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppGlobalIds'',
    @ColumnName = N''ClientNumber'',
    @Description = N''Teléfono del cliente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppGlobalIds'',
    @ColumnName = N''FirstMessageDateFromAgent'',
    @Description = N''Fecha del primer mensaje del agente a cobrar.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppGlobalIds'',
    @ColumnName = N''FirstMessageConversationIdFromAgent'',
    @Description = N''Identificador de conversación del primer mensaje del agente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppGlobalIds'',
    @ColumnName = N''FirstMessageConversationTypeFromAgent'',
    @Description = N''Tipo de conversación del primer mensaje del agente: entrada o salida.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppGlobalIds'',
    @ColumnName = N''IsBilled'',
    @Description = N''Indica si la conversación fue cobrada: 1 cobrada.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppGlobalIdsRelationship'',
    @ColumnName = N''GlobalId'',
    @Description = N''Identificador global relacionado con ccWhatsAppGlobalIds.GlobalId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppGlobalIdsRelationship'',
    @ColumnName = N''ConversationId'',
    @Description = N''Identificador de conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppGlobalIdsRelationship'',
    @ColumnName = N''ConversationType'',
    @Description = N''Tipo de conversación: entrada o salida.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNode'',
    @ColumnName = N''conversationId'',
    @Description = N''Identificador de la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNode'',
    @ColumnName = N''node'',
    @Description = N''Archivo XML o nodo que se pasará a BaseXServer/Finder.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNode'',
    @ColumnName = N''dateIn'',
    @Description = N''Fecha de creación del registro o conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNode'',
    @ColumnName = N''dateOut'',
    @Description = N''Fecha en que se pasó a la base del servidor o BaseX.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNode'',
    @ColumnName = N''status'',
    @Description = N''Estado de paso de información a BaseXServer: 0 nuevo, 1 insertado, 2 reemplazar, 3 actualizado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeHistory'',
    @ColumnName = N''conversationId'',
    @Description = N''Identificador de la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeHistory'',
    @ColumnName = N''node'',
    @Description = N''Archivo XML o nodo que se pasará a BaseXServer/Finder.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeHistory'',
    @ColumnName = N''dateIn'',
    @Description = N''Fecha de creación del registro o conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeHistory'',
    @ColumnName = N''dateOut'',
    @Description = N''Fecha en que se pasó a la base del servidor o BaseX.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeHistory'',
    @ColumnName = N''status'',
    @Description = N''Estado de paso de información a BaseXServer: 0 nuevo, 1 insertado, 2 reemplazar, 3 actualizado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutNode'',
    @ColumnName = N''conversationId'',
    @Description = N''Identificador de la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutNode'',
    @ColumnName = N''node'',
    @Description = N''Archivo XML o nodo que se pasará a BaseXServer/Finder.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutNode'',
    @ColumnName = N''dateIn'',
    @Description = N''Fecha de creación del registro o conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutNode'',
    @ColumnName = N''dateOut'',
    @Description = N''Fecha en que se pasó a la base del servidor o BaseX.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutNode'',
    @ColumnName = N''status'',
    @Description = N''Estado de paso de información a BaseXServer: 0 nuevo, 1 insertado, 2 reemplazar, 3 actualizado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutNodeHistory'',
    @ColumnName = N''conversationId'',
    @Description = N''Identificador de la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutNodeHistory'',
    @ColumnName = N''node'',
    @Description = N''Archivo XML o nodo que se pasará a BaseXServer/Finder.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutNodeHistory'',
    @ColumnName = N''dateIn'',
    @Description = N''Fecha de creación del registro o conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutNodeHistory'',
    @ColumnName = N''dateOut'',
    @Description = N''Fecha en que se pasó a la base del servidor o BaseX.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppOutNodeHistory'',
    @ColumnName = N''status'',
    @Description = N''Estado de paso de información a BaseXServer: 0 nuevo, 1 insertado, 2 reemplazar, 3 actualizado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeOut'',
    @ColumnName = N''conversationId'',
    @Description = N''Identificador de la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeOut'',
    @ColumnName = N''node'',
    @Description = N''Archivo XML o nodo que se pasará a BaseXServer/Finder.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeOut'',
    @ColumnName = N''dateIn'',
    @Description = N''Fecha de creación del registro o conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeOut'',
    @ColumnName = N''dateOut'',
    @Description = N''Fecha en que se pasó a la base del servidor o BaseX.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeOut'',
    @ColumnName = N''status'',
    @Description = N''Estado de paso de información a BaseXServer: 0 nuevo, 1 insertado, 2 reemplazar, 3 actualizado.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeHistoryOut'',
    @ColumnName = N''conversationId'',
    @Description = N''Identificador de la conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeHistoryOut'',
    @ColumnName = N''node'',
    @Description = N''Archivo XML o nodo que se pasará a BaseXServer/Finder.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeHistoryOut'',
    @ColumnName = N''dateIn'',
    @Description = N''Fecha de creación del registro o conversación.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeHistoryOut'',
    @ColumnName = N''dateOut'',
    @Description = N''Fecha en que se pasó a la base del servidor o BaseX.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccWhatsAppNodeHistoryOut'',
    @ColumnName = N''status'',
    @Description = N''Estado de paso de información a BaseXServer: 0 nuevo, 1 insertado, 2 reemplazar, 3 actualizado.'';

'
    exec (@sql)
    

    SET @process = 'Descripciones tablas sms'
    SET @sql = 'EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @Description = N''Tabla fuente de registros SMS cargados para envío. Contiene teléfonos destino, estatus, intentos, campaña, usuario, datos adicionales, zonas horarias, lista, región y localidad.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsoutSourceMessage'',
    @Description = N''Tabla que almacena el mensaje asociado a un registro de smsOutSource que será enviado al teléfono del cliente.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @Description = N''Tabla de trabajo de SMS usada por el proceso de envío outbound. Contiene registros pendientes/procesando con teléfono, campaña, fecha de envío, estatus, usuario, zona horaria y datos de lista.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsccoLogDial'',
    @Description = N''Tabla de bitácora de envíos SMS. Registra teléfono, fecha de envío, identificadores de trazabilidad, resultado del envío, costo y proveedor.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccSmsSchedules'',
    @Description = N''Tabla de horarios de envío SMS por campaña. Define fecha inicial y final del horario asociado a una campaña.'';


EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccSmsConversationsResult'',
    @Description = N''Tabla de resultados agregados diarios de mensajes SMS por campaña: enviados, entregados, no entregados y rechazos.'';

'
    exec (@sql)    



    SET @process = 'Descripciones columnas sms'
    SET @sql = 'EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''smsout_id'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''callkey'',
    @Description = N''Id del registro del cliente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''cam_id'',
    @Description = N''Identificador de campaña relacionado con ccCamps.CamId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''sms_phoneNumber'',
    @Description = N''Número al cual se enviará el mensaje; actualmente se envía al primer número válido.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''sms_phoneNumber2'',
    @Description = N''Segundo número opcional al cual se puede enviar el mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''sms_phoneNumber3'',
    @Description = N''Tercer número opcional al cual se puede enviar el mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''sms_phoneNumber4'',
    @Description = N''Cuarto número opcional al cual se puede enviar el mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''sms_phoneNumber5'',
    @Description = N''Quinto número opcional al cual se puede enviar el mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''sms_status'',
    @Description = N''Estatus del registro SMS: 0 nuevos, 2 progreso, 3 finalizados.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''sms_attemps'',
    @Description = N''Número de intentos.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''user_id'',
    @Description = N''Identificador de usuario relacionado con ccUsers.userId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''sms_dateDial'',
    @Description = N''Fecha en la que se realizará el envío del mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''data1'',
    @Description = N''Dato 1.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''data2'',
    @Description = N''Dato 2.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''data3'',
    @Description = N''Dato 3.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''data4'',
    @Description = N''Dato 4.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''data5'',
    @Description = N''Dato 5.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''dial_tels'',
    @Description = N''Orden de marcación/envío: sms_phoneNumber, sms_phoneNumber2, etc.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''iTimeZone'',
    @Description = N''Zona horaria a la que se marca; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''iTimeZone_summer'',
    @Description = N''Zona horaria de verano; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''iTimeZone2'',
    @Description = N''Segunda zona horaria a la que se marca; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''iTimeZone_summer2'',
    @Description = N''Segunda zona horaria de verano; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''iTimeZone3'',
    @Description = N''Tercera zona horaria a la que se marca; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''iTimeZone_summer3'',
    @Description = N''Tercera zona horaria de verano; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''iTimeZone4'',
    @Description = N''Cuarta zona horaria a la que se marca; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''iTimeZone_summer4'',
    @Description = N''Cuarta zona horaria de verano; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''iTimeZone5'',
    @Description = N''Quinta zona horaria a la que se marca; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''iTimeZone_summer5'',
    @Description = N''Quinta zona horaria de verano; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''list_id'',
    @Description = N''Identificador para asociar la carga de base de datos; relacionado con ccRIARegistryLists.list_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''Region'',
    @Description = N''Región; solo aplica para México.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsOutSource'',
    @ColumnName = N''Localidad'',
    @Description = N''Localidad/Municipio; solo aplica para México.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsoutSourceMessage'',
    @ColumnName = N''smsoutSourceMessage_id'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsoutSourceMessage'',
    @ColumnName = N''smsout_id'',
    @Description = N''Identificador del registro relacionado con smsOutSource.smsout_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsoutSourceMessage'',
    @ColumnName = N''message'',
    @Description = N''Mensaje que será enviado al teléfono del cliente.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''smsout_id'',
    @Description = N''Identificador del registro relacionado con smsOutSource.smsout_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''sms_phoneNumber'',
    @Description = N''Teléfono al que se enviará el mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''cal_keyw'',
    @Description = N''Identificador del registro relacionado con smsOutSource.callkey.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''attemps'',
    @Description = N''Número de intentos.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''cam_id'',
    @Description = N''Identificador de campaña relacionado con ccCamps.CamId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''sms_dateDial'',
    @Description = N''Fecha en la que se realizará el envío del mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''sms_status'',
    @Description = N''Estatus del mensaje cuando es tomado por cw-outbound-send-sms: 0 nuevos, 1 callback no funcional, 2 procesando.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''priority_cb'',
    @Description = N''Prioridad para el envío/reenvío; actualmente no se usa.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''user_id'',
    @Description = N''Identificador de usuario relacionado con ccUsers.userId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''iTimeZone'',
    @Description = N''Zona horaria a la que se marca; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''iTimeZone_summer'',
    @Description = N''Zona horaria de verano; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''iTimeZone2'',
    @Description = N''Segunda zona horaria a la que se marca; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''iTimeZone_summer2'',
    @Description = N''Segunda zona horaria de verano; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''iTimeZone3'',
    @Description = N''Tercera zona horaria a la que se marca; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''iTimeZone_summer3'',
    @Description = N''Tercera zona horaria de verano; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''iTimeZone4'',
    @Description = N''Cuarta zona horaria a la que se marca; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''iTimeZone_summer4'',
    @Description = N''Cuarta zona horaria de verano; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''iTimeZone5'',
    @Description = N''Quinta zona horaria a la que se marca; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''iTimeZone_summer5'',
    @Description = N''Quinta zona horaria de verano; relacionada con ccTimeZones.tz_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''list_id'',
    @Description = N''Identificador para asociar la carga de base de datos; relacionado con ccRIARegistryLists.list_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''id_RAniList'',
    @Description = N''Identificador de lista ANI rotativa; sin descripción funcional adicional en el documento.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsWorkingTable'',
    @ColumnName = N''ani_idx'',
    @Description = N''Índice ANI; sin descripción funcional adicional en el documento.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsccoLogDial'',
    @ColumnName = N''logId'',
    @Description = N''Identificador de la tabla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsccoLogDial'',
    @ColumnName = N''smsout_id'',
    @Description = N''Identificador del registro relacionado con smsOutSource.smsout_id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsccoLogDial'',
    @ColumnName = N''cam_id'',
    @Description = N''Identificador de campaña relacionado con ccCamps.CamId.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsccoLogDial'',
    @ColumnName = N''phone'',
    @Description = N''Teléfono al que se envió el mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsccoLogDial'',
    @ColumnName = N''smsDate'',
    @Description = N''Fecha del envío.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsccoLogDial'',
    @ColumnName = N''registryClient'',
    @Description = N''Identificador del registro relacionado con smsOutSource.callkey.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsccoLogDial'',
    @ColumnName = N''SystemApiId'',
    @Description = N''Identificador del sistema BackBone para trazar los mensajes.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsccoLogDial'',
    @ColumnName = N''statusSystemsId'',
    @Description = N''Resultado del envío del mensaje: 0 enviado, 1 entregado, 2 no entregado, 3 rechazado por destinatario, 4 rechazado por proveedor, 5 no enviado por falta de servicio.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsccoLogDial'',
    @ColumnName = N''Bill'',
    @Description = N''Costo del mensaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''smsccoLogDial'',
    @ColumnName = N''ProviderId'',
    @Description = N''Identificador del proveedor que envió el mensaje; actualmente no se recibe este valor y se propone cambiarlo.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccSmsSchedules'',
    @ColumnName = N''cam_id'',
    @Description = N''Identificador de campaña relacionado con ccCamps.Cam_Id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccSmsSchedules'',
    @ColumnName = N''iDate'',
    @Description = N''Fecha de inicio del horario.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccSmsSchedules'',
    @ColumnName = N''fDate'',
    @Description = N''Fecha fin del horario.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccSmsConversationsResult'',
    @ColumnName = N''camId'',
    @Description = N''Identificador de campaña relacionado con ccCamps.Cam_Id.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccSmsConversationsResult'',
    @ColumnName = N''SentMsg'',
    @Description = N''Número de mensajes enviados del día.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccSmsConversationsResult'',
    @ColumnName = N''Delivered'',
    @Description = N''Número de mensajes entregados del día.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccSmsConversationsResult'',
    @ColumnName = N''NotDelivered'',
    @Description = N''Número de mensajes no entregados del día.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccSmsConversationsResult'',
    @ColumnName = N''RecipientRejected'',
    @Description = N''Número de mensajes rechazados por SMSBackBone.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccSmsConversationsResult'',
    @ColumnName = N''CarrierRejected'',
    @Description = N''Número de mensajes rechazados por el carrier.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccSmsConversationsResult'',
    @ColumnName = N''InsufficientBalance'',
    @Description = N''Número de mensajes que no se enviaron por falta de saldo para enviar todos los mensajes cargados.'';

'
    exec (@sql)
    

    SET @process = 'Descripciones Tablas y columnas WhatsApp'
    SET @sql = 'EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWAOutboundTemplates'',
    @Description = N''Tabla donde se guarda la información de plantillas WhatsApp de salida asignadas por Meta, incluyendo categoría, nombre, lenguaje, estatus y componentes JSON.'';

    EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWAOutboundTemplates'',
    @ColumnName = N''Id'',
    @Description = N''Id de plantilla asignado por Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWAOutboundTemplates'',
    @ColumnName = N''Catery'',
    @Description = N''Catería de plantilla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWAOutboundTemplates'',
    @ColumnName = N''TemplateName'',
    @Description = N''Nombre de plantilla.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWAOutboundTemplates'',
    @ColumnName = N''AllowCateryChange'',
    @Description = N''Parámetro que indica si se permite que Meta cambie la catería.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWAOutboundTemplates'',
    @ColumnName = N''LanguageCode'',
    @Description = N''Códi de lenguaje.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWAOutboundTemplates'',
    @ColumnName = N''Status'',
    @Description = N''Estatus asignado por Meta.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWAOutboundTemplates'',
    @ColumnName = N''header'',
    @Description = N''Datos del header en formato JSON.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWAOutboundTemplates'',
    @ColumnName = N''body'',
    @Description = N''Datos del body en formato JSON.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWAOutboundTemplates'',
    @ColumnName = N''footer'',
    @Description = N''Datos del footer en formato JSON.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWAOutboundTemplates'',
    @ColumnName = N''buttons'',
    @Description = N''Datos de los botones en formato JSON.'';


EXEC dbo.usp_SetColumnDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''ccMetaWAOutboundTemplates'',
    @ColumnName = N''RemovalDate'',
    @Description = N''Fecha de eliminación de plantilla.'';


'
    exec (@sql)

    
    SET @process = 'ALTER Procedure [dbo].[ccsp_CleanNodeBaseX] @option = 4 delete'
    SET @sql = 'ALTER Procedure [dbo].[ccsp_CleanNodeBaseX]

@option int
AS
BEGIN

    declare @percentage int,@setting int
    declare @top int
    declare @table table(id bigint primary key,node xml not null,dateStart datetime, status tinyint not null)
    declare @tableNotExists table(id bigint primary key)

    set @percentage=20 --porcentaje de registros que se pasaran esta en funcion del setting 188

    select  @setting  = valor from ccSettings where setting_id = 188
    if @setting is null set @setting = 40000
    set @top=@setting/@percentage
    
    if @option = 1 begin
        
            insert into @table
            select top (@top)  A.chatId, A.node,A.dateIn, status from ccChatsNode A with(nolock) where A.status in(1,3) order by chatId
        
            insert into @tableNotExists
            select A.id from  @table A 
            left join ccChatsNodeHistory  B with(nolock)  on B.chatId=A.id 
            where B.chatId is null
        
            insert into ccChatsNodeHistory(chatId,node,dateIn,status)       
            select  A.id,A.node,A.dateStart,A.status from @table A
            inner join @tableNotExists B on A.id=B.id

            delete from ccChatsNode where chatId in(select id from @table)

    end
    else if @option = 3  begin
    
        insert into @table
        select top (@top)  A.emailId, A.node,A.dateIn,status from ccEmailNode A with(nolock) where A.status in(1,3) order by emailId
        
        insert into @tableNotExists
        select A.id from  @table A 
        left join ccEmailNodeHistory  B with(nolock)  on B.emailId=A.id 
        where B.emailId is null
        
        insert into ccEmailNodeHistory(emailId,node,dateIn,status)      
        select  A.id,A.node,A.dateStart,A.status from @table A
        inner join @tableNotExists B on A.id=B.id

        delete from ccEmailNode where emailId in(select id from @table)
    end
        
END'
    exec (@sql)

    
    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_CreateNodeMultimedia] @type = 4'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_CreateNodeMultimedia] @conversationId BIGINT
                    , @supervisor     VARCHAR(255) = ''''
                    , @template       VARCHAR(255) = ''''
                    , @ScoreTemplate  INT          = 0
                    , @type           INT
AS
BEGIN

DECLARE @xml XML, @dateStart DATETIME, @DispXML XML, @SubXML XML;
DECLARE @info VARCHAR(255);
DECLARE @infoEscape VARCHAR(MAX);
DECLARE @disp varchar(255);
declare @subdisp varchar(255);
DECLARE @charEscape VARCHAR(255), @charReplace VARCHAR(MAX);
SET @charEscape = ''"|''''''''|<|>|&'';
SET @charReplace = ''&quot;|&apos;|&lt;|&gt;|&amp;'';

DECLARE @existAttached BIT, @numInteracion SMALLINT;
IF @type = 1
BEGIN--CHAT

    select @disp = Description from ccRIAChats c left join ccTipoCalif b on c.disposition = b.calif_id where c.chatId = @conversationId
    select @subdisp = califSubDesc from ccRIAChats c left join ccTipoCalifSub b on c.subDisposition = b.califSub_id and c.subdisposition <> 0 where c.chatId = @conversationId

    SET @DispXML = (
        SELECT ''" C06="'' + @disp
        FOR XML PATH('''')
    );

    SET @SubXML = (
        SELECT ''" C07="'' + @subdisp
        FOR XML PATH('''')
    );

    SELECT @xml = CONVERT(XML, ''<R01 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126)))
        + ''" CID="'' + CONVERT(VARCHAR(MAX), ccRIAChats.inboundid)
    + ''" CType="1''
    + ''" C01="'' + CONVERT(VARCHAR(MAX), chatId)
    + ''" C02="'' + CONVERT(VARCHAR(MAX), ISNULL(ccinbound.descripcion, ''''))
    + ''" C03="'' + CONVERT(VARCHAR(MAX), domain)
    + ''" C04="'' + CONVERT(VARCHAR(MAX), ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A''))
    + ''" C05="'' + CONVERT(VARCHAR(MAX), tchatting)
    + ISNULL(CAST(@DispXML as varchar(MAX)), ''N/A'')
    + ISNULL(CAST(@SubXML as varchar(MAX)), ''N/A'')
    + ''" C08="'' + CONVERT(VARCHAR(MAX), clientname)
    + ''" C09="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126)))
    + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, ''''))
    + ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, ''''))
    + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0))
    + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(ccusers.[Login], ''''))
    + ''"/>'')
            , @dateStart = ISNULL(chatDate, requestDate) FROM ccRIAChats
                                                            LEFT OUTER JOIN ccinbound ON ccinbound.inbound_id = ccRIAChats.inboundid
                                                            LEFT OUTER JOIN ccusers ON ccusers.user_id = ccRIAChats.userid
    WHERE chatId = @conversationId
            AND chatStatus = 4

END;
ELSE IF @type = 3
BEGIN--EMAIL
    SELECT @existAttached = CASE WHEN COUNT(*) > 0
                            THEN 1 ELSE 0
                            END FROM attached
    WHERE messageId IN(SELECT messageId FROM message WHERE conversationId = @conversationId);
    SELECT @numInteracion = COUNT(*) FROM message WHERE conversationId = @conversationId;
    --Replaza los caracteres por los comunes
    SELECT @info = info FROM conversation WHERE conversationId = @conversationId;
    SELECT @info = replace(@info, A.Value, B.Value) FROM dbo.fn_RIASplitDelimited(@charEscape, ''|'') A
                                                            INNER JOIN dbo.fn_RIASplitDelimited(@charReplace, ''|'') B ON A.Id = B.Id;

    select @disp = t.Description, @subdisp = ts.califSubDesc
    from conversation c
    left join message m on c.conversationId = m.conversationId
    left join relationMessageDisposition r on m.messageId = r.messageId
    left join ccTipoCalif t on r.dispositionId = t.calif_id
    left join ccTipoCalifSub ts on r.subDispositionId = ts.califSub_id and r.subdispositionId <> 0
    where c.conversationId = @conversationId

    SET @DispXML = (
        SELECT ''" C05="'' + @disp
        FOR XML PATH('''')
    );

    SET @SubXML = (
        SELECT ''" C15="'' + @subdisp
        FOR XML PATH('''')
    );

    SELECT @xml = CONVERT(XML, ''<R03 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126)))
        + ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid)
    + ''" CType="1''
    + ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationId)
    + ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126)))
    + ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion))
    + ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, '''')))
    + ISNULL(CAST(@DispXML as varchar(MAX)), ''N/A'')
    + ''" C06="'' + CONVERT(VARCHAR, MAX(replace(replace(a.mailClient, ''<'', '' ''), ''>'', '' '')))
    + ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup))
    + ''" C08="'' + CONVERT(VARCHAR(MAX), MIN(ISNULL(@info, '''')))
    + ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid))
    + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0))
    + ''" C11="'' + CONVERT(VARCHAR(MAX), @existAttached)
    + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, ''''))
    + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, ''''))
    + ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0))
    + ISNULL(CAST(@SubXML as varchar(MAX)), ''N/A'')
    + ''" C16="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), ''''))
    + ''"/>'')
            , @dateStart = ISNULL(MAX(b.tsend), GETDATE()) FROM conversation a
                                                                INNER JOIN message b ON a.conversationid = b.conversationid
                                                                LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
                                                                LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
    WHERE a.conversationId = @conversationId
    GROUP BY a.conversationId
            , a.inboundid;

END;
ELSE IF @type = 5 BEGIN --WhatsApp In

    select @disp = Description from ccWhatsAppConversations c left join ccTipoCalif b on c.disposition = b.calif_id where c.conversationId = @conversationId
    select @subdisp = califSubDesc from ccWhatsAppConversations c left join ccTipoCalifSub b on c.subDisposition = b.califSub_id where c.conversationId = @conversationId

    --select * from ccWhatsAppConversations

    SET @DispXML = (
        SELECT ''" C07="'' + @disp
        FOR XML PATH('''')
    );

    SET @SubXML = (
        SELECT ''" C08="'' + @subdisp
        FOR XML PATH('''')
    );

    SELECT @xml = CONVERT(XML, ''<R05 CDATE="'' + CONVERT(VARCHAR(23), ISNULL(conversationDate, requestDate), 126)
        + ''" CID="'' + CONVERT(VARCHAR(MAX), A.inboundid)
    + ''" CType="5''
    + ''" C01="'' + CONVERT(VARCHAR(MAX), A.conversationId)
    + ''" C02="'' + ISNULL(inbound.descripcion, '''')
    + ''" C03="'' + ISNULL(ccusers.[Login], '''')
    + ''" C04="'' + ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'')
    + ''" C05="'' + clientId
    + ''" C06="'' + CONVERT(VARCHAR(MAX), tConversation)
    + ISNULL(CAST(@DispXML as varchar(MAX)), ''N/A'')
    + ISNULL(CAST(@SubXML as varchar(MAX)), ''N/A'')
    + ''" C09="'' + CONVERT(VARCHAR(MAX), A.agentId)
    + ''" C10="'' + phoneACD
    + ''" C11="'' + CONVERT(VARCHAR(MAX), A.agentId)
    + ''" C12="'' + ISNULL(@supervisor, '''')
    + ''" C13="'' + ISNULL(@template, '''')
    + ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0))
    + ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(A.disposition, 0))
    + ''"/>'')
            , @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversations A
                                                                    LEFT OUTER JOIN ccinbound inbound ON inbound.inbound_id = A.inboundid
                                                                    LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId
    WHERE A.conversationId = @conversationId;

END;
ELSE IF @type = 6 BEGIN --WhatsApp Out

    select @disp = Description from ccWhatsAppConversationsOut c left join ccTipoCalifOUT b on c.disposition = b.calif_id where c.conversationId = @conversationId
    select @subdisp = califSubDesc from ccWhatsAppConversationsOut c left join ccTipoCalifSubOUT b on c.subDisposition = b.califSub_id where c.conversationId = @conversationId

    SET @DispXML = (
        SELECT ''" C07="'' + @disp
        FOR XML PATH('''')
    );

    SET @SubXML = (
        SELECT ''" C08="'' + @subdisp
        FOR XML PATH('''')
    );

    SELECT @xml = CONVERT(XML, ''<R06 CDATE="'' + CONVERT(VARCHAR(23), ISNULL(conversationDate, requestDate), 126)
        + ''" CID="'' + CONVERT(VARCHAR(MAX), A.camId)
    + ''" CType="6''
    + ''" C01="'' + CONVERT(VARCHAR(MAX), A.conversationId)
    + ''" C02="'' + ISNULL(c.cam_descripcion, '''')
    + ''" C03="'' + ISNULL(ccusers.[Login], '''')
    + ''" C04="'' + ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'')
    + ''" C05="'' + clientId
    + ''" C06="'' + CONVERT(VARCHAR(MAX), isnull(tConversation,0))
    + ISNULL(CAST(@DispXML as varchar(MAX)), ''N/A'')
    + ISNULL(CAST(@SubXML as varchar(MAX)), ''N/A'')
    + ''" C09="'' + CONVERT(VARCHAR(MAX), A.agentId)
    + ''" C10="'' + phoneCamp
    + ''" C11="'' + CONVERT(VARCHAR(MAX), A.agentId)
    + ''" C12="'' + ISNULL(@supervisor, '''')
    + ''" C13="'' + ISNULL(@template, '''')
    + ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0))
    + ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(A.disposition, 0))
    + ''"/>'')
            , @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversationsOut A
                                                                    LEFT OUTER JOIN ccCamps c ON c.cam_id=A.camId
                                                                    LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId
    WHERE A.conversationId = @conversationId;

END;

DECLARE @sql NVARCHAR(MAX), @tableName NVARCHAR(MAX), @columnId NVARCHAR(MAX), @tableNameHistory NVARCHAR(MAX);
DECLARE @parameterDefinition NVARCHAR(MAX);

SELECT @tableName = tableName
        , @tableNameHistory = tableNameHistory
        , @columnId = columnId FROM ccFinderServices
WHERE id =  @type;

SET @parameterDefinition = N''@conversationId bigint,@xml xml,@dateStart datetime'';

IF @xml IS NOT NULL
BEGIN

    SET @sql = ''IF EXISTS(SELECT * FROM '' + @tableNameHistory + '' WHERE ''+@columnId+'' = @conversationId)
    BEGIN
        UPDATE '' + @tableNameHistory + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
    END
    else IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
    BEGIN
        UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
    END
    else begin
        INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, 0);
    end
    '';

END
else begin
        SET @sql ='' IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
    BEGIN
        UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = -1 WHERE ''+@columnId+'' = @conversationId;
    END
    else begin
        INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, -1);
    end '';
end


    EXECUTE sp_executesql
            @sql
            , @parameterDefinition
            , @conversationId = @conversationId
            , @xml = @xml
            , @dateStart = @dateStart;

END;'
    exec (@sql)
    

    SET @process = 'ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]'
    SET @sql = 'ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]
@type smallint = null,
@inbound_id smallint = null,
@calif_id smallint = null,
@cam_id smallint = NULL,
@isKolob BIT = 0
AS
set nocount on
create table #CalifTemp (
id int identity,
tipo integer,
Cam_id varchar(60),
Calificacion varchar(60),
subCalificacion varchar(60) null,
calif_id smallint null,
Total int,
iTotal4Campaign int null)

declare @typeACD smallint --= 0
declare @today datetime
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)

set @today = convert(datetime, convert (varchar(11), getdate(), 101))
select @typeACD = chat from ccInbound  where Inbound_id = @inbound_id


select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end,
@nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
from ccsettings where setting_id = 27 -- 0 esp

---------------OUT ----------------------------
if @type=0 begin
    insert into #CalifTemp
    select 0 as tipo,co.cam_id as cam_id,
    case when co.statuscall_id = 13
        then case when description is not null
        then description else @nIdioma end
    else case when sll.descripcion is not null then ''cw:'' + sll.descripcion
    else ''cw:'' + @nIdioma
    end end as Calificacion
    ,0 as subCalificaion,
    co.calif_id,count(*) cantidad,0 as iTotal4Campaign
    from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
    left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
    left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
    left join ccCamps ci on ci.cam_id = co.cam_id
    where co.cal_inicio > @today
    group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id

    select tipo,Cam_id, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end as Calificacion,
    case when count(subCalificacion)>0 then 1 else 0 end subCalificacion, calif_id,sum(Total) as Total
    from #CalifTemp
    group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end, Cam_id, iTotal4Campaign,calif_id

end
---------------IN ----------------------------
else if @type = 1 begin

    if @typeACD = 0 begin  --Calls
    insert into #CalifTemp
    select @typeACD as tipo,cci.inbound_id as cam_id, description as Calificacion
            ,case when count(ci.califSub_id) >0 then 1 else 0 end as subCalificacion,ci.calif_id
            ,count(*) as total,0 as iTotal4Campaign
            from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
            left join ccTipoCalif ca on ci.calif_id = ca.calif_id
            left join ccInbound cci on cci.inbound_id = ci.inbound_id
            left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
            where ci.cal_inicio > @today and statuscall_id = 13 and cci.Inbound_id=@inbound_id
            group by description, cci.inbound_id,ci.calif_id

    if (select valor from ccSettings where setting_id = 78) = 0 begin
        update #CalifTemp set iTotal4Campaign = 0
    end
    else begin
    update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign
        from (
            select cam_id, sum(A.Total) iTotal4Campaign from #CalifTemp A group by cam_id) t
        inner join #CalifTemp c on t.cam_id = c.cam_id
    end
    end
    else if @typeACD = 1 begin--Chats
    insert into #CalifTemp(tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
    select @typeACD as tipo, inboundId as Cam_id, [description] as Calificacion,
            case when sum(case when a.subDisposition = 0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
            a.disposition as calif_id, count(disposition) as Total
            from ccriachats a
            left join ccTipoCalif b on a.disposition=b.calif_id
        where a.chatDate > @today and
        a.chatStatus=4 and a.inboundId=@inbound_id
    group by inboundId, [description],disposition
    end
    else if @typeACD = 3 begin ---Mail
    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
    select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
    case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
    relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
    from conversation conver
    inner join message mess on mess.conversationId = conver.conversationId
    left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
    where mess.date > @today and
    conver.inboundId=@inbound_id and mess.messageStatusId >= 5
    group by conver.inboundId,relmesdis.dispositionId,disp.Description

    end
   
    select camtemp.tipo,camtemp.cam_id,
    case when tipcal.Description is not null then tipcal.Description else @nIdioma end as Calificacion,
    camtemp.subcalificacion,camtemp.calif_id,camtemp.total
    from #CalifTemp camtemp
    left join ccTipoCalif tipcal on camtemp.calif_id =  tipcal.calif_id
end
-------------------SUBCALIFICACIONES IN-------------------
else if @type = 2 BEGIN
    if @typeACD = 0 begin --Calls
        exec ccspSaveDispositionResult @action=7,@callType=0,@camId=@inbound_id,@dispotitionId=@calif_id        
    end
    else if @typeACD = 1 
    BEGIN --Chat
        IF(@isKolob = 1)
        BEGIN
            select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
            isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName, count(ctcs.califSubDesc) as Quantity,
            ctcs.califSub_id AS Id
            from ccriachats a
            left join ccTipoCalif b on a.disposition=b.calif_id
            left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
            where a.chatDate > @today and
            a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id AND ctcs.califSub_id IS NOT NULL
            group by inboundId, [description],ctcs.califSubDesc, ctcs.califSub_id
        END
        ELSE
        BEGIN
            select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
            isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
            from ccriachats a
            left join ccTipoCalif b on a.disposition=b.calif_id
            left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
            where a.chatDate > @today and
            a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id
            group by inboundId, [description],ctcs.califSubDesc
        END
    end
    else if @typeACD = 3 begin --Mail
    select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
    isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
    from conversation conver
    inner join message mess on mess.conversationId = conver.conversationId
    left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
    left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
    left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
    where mess.date > @today and
    mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
    group by conver.inboundId,disp.Description,subDisp.califSubDesc


    end
    

end
-------------------SUBCALIFICACIONES OUT-------------------
else if @type = 4 begin     
    exec ccspSaveDispositionResult @action=7,@callType=1,@camId=@inbound_id,@dispotitionId=@calif_id
end

drop table #CalifTemp
set nocount off
'
    exec (@sql)

    SET @process = 'ALTER procedure [dbo].[ccsp_RIAtmpChart] Delte Twitter'
    SET @sql = 'ALTER procedure [dbo].[ccsp_RIAtmpChart]
@inbound_id smallint = NULL,
@graphicType smallint = NULL
as
SET NOCOUNT ON

declare @DT as int
select @DT = valor from ccsettings where setting_id = 12

Declare @Times Table (
    StartDate datetime not null,
    EndDate datetime not null,
    [timestamp] varchar(5) not null)

Declare @Start DateTime
Declare @End Datetime
Declare @descripcion varchar(50)

declare @DTChat as int
select @DTChat = valor from ccsettings where setting_id = 141

if @graphicType = 1 --Call
begin
    declare @Fecha smalldatetime, @FechaW smalldatetime

    select @Fecha=convert(varchar(10), getdate(), 121)

    if exists(select cal_Inicio from cccallsin_tmpChart where cal_inicio < @Fecha)  truncate table cccallsin_tmpChart

    delete cccallsin_tmpChart where inbound_id = @inbound_id and cal_inicio >= @Fecha
    select @FechaW=@Fecha

     while @FechaW <= convert(varchar(15), getdate(), 121)+''0:00'' begin
        if exists(Select SL.inbound_id from (select NS.inbound_id, @fechaW cal_inicio, sum(NS.LCt) LCt,  sum(NS.LAt) LAt,  sum(NS.LS) LS,  sum(NS.LA) LA,  sum(NS.LDt) LDt,
            sum(NS.LDc) LDc, sum(NS.LC) LC, sum(NS.LNC) LNC, sum(NS.LP) LP, @DT DyTrh
            from (Select @inbound_id inbound_id, @fechaW cal_inicio,
            ISNULL(count(CASE WHEN(statuscall_id in(13))and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LCt,
            ISNULL(count(CASE WHEN(statuscall_id=6)and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LAt,
            ISNULL(count(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0)AS LS,
            ISNULL(count(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0)AS LA,
            ISNULL(count(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0)AS LDt,
            ISNULL(count(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0)AS LDc,
            ISNULL(count(CASE WHEN(statuscall_id in(13))THEN 1 ELSE NULL END),0)AS LC,
            ISNULL(count(CASE WHEN(statuscall_id=15)THEN 1 ELSE NULL END),0)AS LNC,
            ISNULL(count(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0)AS LP
            from cccallsin where inbound_id=@inbound_id and cal_inicio between @Fecha and @FechaW and statuscall_id IN(4,6,7,8,11,13,15,16)
            group by convert(varchar(15), cal_inicio, 121)+''0:00'') as NS group by NS.inbound_id) as SL)
       begin
           insert into cccallsin_tmpChart (inbound_id, cal_Inicio, LCt, LAt, LS, LA, LDt, LDc, LC, LNC, LP, DT, NS)
            select SL.* ,case when (LC+LA+LS+LDt+LDc+LNC+LP) = 0 then ''1'' else cast((cast((LCt+LAt) as float)/cast((LC+LA+LS+LDt+LDc+LNC+LP)
                as float))*100 as decimal(18,2))end ServN
                    from (select NS.inbound_id, @fechaW cal_inicio, sum(NS.LCt) LCt,  sum(NS.LAt) LAt,  sum(NS.LS) LS,  sum(NS.LA) LA,  sum(NS.LDt) LDt,
                sum(NS.LDc) LDc, sum(NS.LC) LC, sum(NS.LNC) LNC, sum(NS.LP) LP, @DT DyTrh
                    from (Select @inbound_id inbound_id, @fechaW cal_inicio,
                        ISNULL(count(CASE WHEN(statuscall_id in(13))and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LCt,
                        ISNULL(count(CASE WHEN(statuscall_id=6)and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LAt,
                        ISNULL(count(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0)AS LS,
                        ISNULL(count(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0)AS LA,
                        ISNULL(count(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0)AS LDt,
                        ISNULL(count(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0)AS LDc,
                        ISNULL(count(CASE WHEN(statuscall_id in(13))THEN 1 ELSE NULL END),0)AS LC,
                        ISNULL(count(CASE WHEN(statuscall_id=15)THEN 1 ELSE NULL END),0)AS LNC,
                        ISNULL(count(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0)AS LP
                    from cccallsin where inbound_id=@inbound_id and cal_inicio between @Fecha and @FechaW and statuscall_id IN(4,6,7,8,11,13,15,16)
                group by convert(varchar(15), cal_inicio, 121)+''0:00'') as NS group by NS.inbound_id) as SL
       end

        else begin
            insert into cccallsin_tmpChart (inbound_id, cal_Inicio, LCt, LAt, LS, LA, LDt, LDc, LC, LNC, LP, DT, NS)
            Select @inbound_id, @FechaW, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        end

      select @FechaW=dateadd(minute, 10, @FechaW)
     end

    if not exists(select d.descripcion from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart)) join (select c.inbound_id, i.descripcion, c.NS, convert(varchar(5), max(c.cal_inicio), 108) timestamp
        from cccallsin_tmpChart c join ccinbound i on c.inbound_id = i.inbound_id
        where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id
        group by c.inbound_id, i.descripcion, c.NS) D on c.inbound_id = d.inbound_id
        where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id)
    begin
        raiserror(''without ACD Group information  '', 18, 1)
        return(0)
    end

 select * from
    (select top 20 @inbound_id inbound_id, d.descripcion, d.NS LastNS, convert(varchar(5), c.cal_inicio, 108) timestamp, c.NS
        from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart))
    inner join
    (select top 1 c.inbound_id, i.descripcion, c.NS, convert(varchar(5), max(c.cal_inicio), 108) timestamp
        from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart)) join ccinbound i on c.inbound_id = i.inbound_id
        where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id
  --and c.cal_inicio < convert(varchar(15), getdate(), 121)+''0:00''
        group by c.inbound_id, i.descripcion, c.NS order by timestamp desc) D on c.inbound_id = d.inbound_id
    where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id
  --and c.cal_inicio < convert(varchar(15), getdate(), 121)+''0:00''
 order by 4 desc) as chart order by 4
 return(0)
end

if @graphicType in(2,3,4) begin--Init tabla timer

    set @End = getdate()
    set @Start = convert(varchar(15),dateadd(minute, -200, @end),121) + ''0:00''

    while @Start < @End begin
        insert @Times(StartDate, EndDate, [timestamp]) values(@Start, DateAdd(minute, 10, @Start), convert(varchar(5), convert(datetime,@Start), 108))
        set @Start = DateAdd(minute, 10, @Start)
    end

    select @descripcion = descripcion  from ccinbound where inbound_id = @inbound_id

    create table #MultimediaSummary(
        inboundId smallint not null,
        descripcion varchar(50) not null,
        LastNS decimal(10,2) not null,
        [timestamp] varchar(5) not null,
        NS decimal(10,2) not null
    )

    create table #MultimediaChart(
        inboundId smallint not null,
        descripcion varchar(50) not null,
        LastNS decimal(10,2) not null,
        [timestamp] varchar(5) not null,
        NS decimal(10,2) not null
    )


end

if @graphicType = 2 begin --CHAT
    insert into #MultimediaSummary
     select inboundId, descripcion, 0.00 as LastNS,
     convert(varchar(5), convert(datetime,Date), 108) [timestamp],
     convert(decimal(10,2),convert(float,[Connected]) / convert(float, Total) * 100.00) as NS
     from
         (select inboundId, descripcion, Date,
         sum([Connected>DT]) as [Connected],
         sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as NotConnected,
         sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as Total
         from (
             select inboundId, descripcion, convert(varchar(15), chatDate, 121)+''0:00'' as Date,
             ISNULL(count(CASE WHEN chatstatus = 4 and tChatting >= @DTChat THEN 1 ELSE NULL END),0)AS [Connected>DT],
             ISNULL(count(CASE WHEN chatstatus = 4 and tChatting < @DTChat THEN 1 ELSE NULL END),0)AS [Connected<DT],
             ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
             ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
             ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
             ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
             ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
             from ccRIAChats a
             right outer join @times b on (chatDate >= StartDate and chatDate < EndDate)
             left outer join ccInbound c on (inboundId = inbound_id)
             where inboundId = @inbound_id and chatStatus in (3,4,7,9,10,11) and chatDate is not null
             group by inboundId, descripcion, convert(varchar(15), chatDate, 121)+''0:00'') as ChatDetail
    group by inboundId, descripcion, Date) as ChatSummary

end

else if @graphicType = 3 begin--Email
    insert into #MultimediaSummary
    select  x.inboundId,x.descripcion, 0.00 as LastNS,
    convert(varchar(5), convert(datetime,Date), 108) [timestamp],
    convert(decimal(10,2),convert(float,sent+forwarding+closed) / convert(float, received) * 100.00) as NS
    from
        (select
        inboundId,c.descripcion, convert(varchar(15), msg.date, 121)+''0:00'' as Date,
        count(*) received,
        count(case when messageStatusId in (5,6,1) then 1 else null end) sent,
        count(case when messageStatusId = 9 then 1 else null end) forwarding,
        count(case when messageStatusId in (10,11) then 1 else null end) closed
        from message msg (nolock) join conversation con (nolock) on con.conversationId=msg.conversationId
        right outer join @times b on msg.date >= StartDate and msg.date < EndDate
        left outer join ccInbound c on con.inboundId = c.inbound_id
        where inboundId = @inbound_id
        group by inboundId,c.descripcion, convert(varchar(15), date, 121)+''0:00''
        )x
end

if @graphicType in(2,3,4) begin--Se coloca al final la parte que son iguales todos los servicios multimedia

    insert into #MultimediaChart
     select case when (inboundId is null) then @inbound_id else inboundID end as inboundId,
        case when (descripcion is null) then @descripcion else descripcion end as descripcion,
        case when (LastNS is null) then 0.00 else LastNS end as LastNS,
        case when (a.[timestamp] is null) then b.[timestamp] else a.[timestamp] end as [timestamp],
        case when (NS is null) then 0.00 else NS end as NS
        from #MultimediaSummary a
     full outer join @times b on (a.[timestamp] = b.[timestamp])
     order by b.[timestamp]

     select a.inboundId, a.descripcion, b.NS as LastNS, a.[timestamp], a.NS
     from #MultimediaChart a, #MultimediaChart b
     where convert(varchar(5),dateadd(minute, -10, convert(datetime,a.[timestamp])), 108) = b.[timestamp]
     order by a.[timestamp]


    drop table #MultimediaSummary
    drop table #MultimediaChart
end'
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccspFinderChat]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspFinderChat]
@action int,@ids nvarchar(max)=null

AS
BEGIN

SET NOCOUNT ON

declare @sql nvarchar(max)
if @action = 1 begin
    set @sql=''select chatId,clientName,userId as agentId from ccRIAChats where chatId in(''+@ids+'')''
    exec (@sql)
end
--action 2 es para grabadora
else if @action = 3 begin
    set @sql=''select conv.conversationId,max(msg.messageId) as messageId,conv.mailClient,conv.mailInbound
from conversation conv
inner join message msg on msg.conversationId=conv.conversationId
where conv.conversationId in(''+@ids+'')
group by conv.conversationId,conv.mailClient,conv.mailInbound''
    exec (@sql)
end

--print (@sql)


END '
    exec (@sql)


    SET @process = ' DROP PROCEDURE dbo.ccsp_TwitterInitialStatistics,ccsp_TwitterSave,ccspADMaddConversationTweet'
    SET @sql = '
IF OBJECT_ID(''dbo.ccsp_TwitterInitialStatistics'', ''P'') IS NOT NULL
    DROP PROCEDURE dbo.ccsp_TwitterInitialStatistics;

IF OBJECT_ID(''dbo.ccsp_TwitterSave'', ''P'') IS NOT NULL
    DROP PROCEDURE dbo.ccsp_TwitterSave;

IF OBJECT_ID(''dbo.ccspADMaddConversationTweet'', ''P'') IS NOT NULL
    DROP PROCEDURE dbo.ccspADMaddConversationTweet; '
    exec (@sql)
    

    SET @process = 'DROP TABLE ccPosicion'
    SET @sql = 'IF EXISTS (SELECT * from sys.tables where name = N''ccPosicion'')
	BEGIN
		DROP TABLE ccPosicion
	END' 
    exec (@sql)
	
    SET @process = 'CREATE TABLE ccPosicion'
    SET @sql = 'CREATE TABLE [dbo].[ccPosicion]( [pos_id] [int] NOT NULL, 
	[Computer] [varchar](20) NOT NULL, [ext_id] [smallint] NOT NULL,
	[user_id] [smallint] NOT NULL, [Status] [varchar](8) NOT NULL,
	[tipoConexion] [tinyint] NOT NULL, [IP] [varchar](50) NULL, 
	[publicIp] [varchar](15) NULL, 
	CONSTRAINT [PK_ccPosicion]
	PRIMARY KEY CLUSTERED ( [pos_id] ASC ) ON [PRIMARY] ) ON [PRIMARY]
	ALTER TABLE [dbo].[ccPosicion] ADD CONSTRAINT [DF_ccPosicion_user_id] DEFAULT (0) FOR [user_id]
	ALTER TABLE [dbo].[ccPosicion] ADD CONSTRAINT [DF_ccPosicion_Status] DEFAULT (1) FOR [Status]
	ALTER TABLE [dbo].[ccPosicion] ADD DEFAULT (0) FOR [tipoConexion]
	ALTER TABLE [dbo].[ccPosicion] ADD DEFAULT ('''') FOR [IP]
	ALTER TABLE [dbo].[ccPosicion] WITH NOCHECK ADD CONSTRAINT [FK_ccPosicion_ccMonitorExt] FOREIGN KEY([ext_id]) REFERENCES [dbo].[ccMonitorExt] ([ext_id])
	ALTER TABLE [dbo].[ccPosicion] CHECK CONSTRAINT [FK_ccPosicion_ccMonitorExt]'
    exec (@sql)
    

    SET @process = 'CREATE INDIXES on ccPosicion'
    SET @sql = '
	------------------------------------------------------------
	-- IX_ccPosicion (Computer)
	------------------------------------------------------------
	IF NOT EXISTS (
		SELECT 1 
		FROM sys.indexes 
		WHERE name = ''IX_ccPosicion''
		AND object_id = OBJECT_ID(''dbo.ccPosicion'')
	)
	BEGIN
		CREATE NONCLUSTERED INDEX IX_ccPosicion
		ON dbo.ccPosicion (Computer);
	END

	------------------------------------------------------------
	-- IX_ccPosicion_1 (ext_id)
	------------------------------------------------------------
	IF NOT EXISTS (
		SELECT 1 
		FROM sys.indexes 
		WHERE name = ''IX_ccPosicion_1''
		AND object_id = OBJECT_ID(''dbo.ccPosicion'')
	)
	BEGIN
		CREATE NONCLUSTERED INDEX IX_ccPosicion_1
		ON dbo.ccPosicion (ext_id);
	END

	------------------------------------------------------------
	-- IX_ccPosicion_2 (user_id, Computer)
	------------------------------------------------------------
	IF NOT EXISTS (
		SELECT 1 
		FROM sys.indexes 
		WHERE name = ''IX_ccPosicion_2''
		AND object_id = OBJECT_ID(''dbo.ccPosicion'')
	)
	BEGIN
		CREATE NONCLUSTERED INDEX IX_ccPosicion_2
		ON dbo.ccPosicion (user_id, Computer);
	END

	------------------------------------------------------------
	-- PK_ccPosicion (pos_id)
	------------------------------------------------------------
	IF NOT EXISTS (
		SELECT 1 
		FROM sys.key_constraints 
		WHERE name = ''PK_ccPosicion''
	)
	BEGIN
		ALTER TABLE dbo.ccPosicion
		ADD CONSTRAINT PK_ccPosicion
		PRIMARY KEY CLUSTERED (pos_id);
	END
	'
    exec (@sql)

    SET @process = 'DROP PROCEDURE ccsp_RIAChecaLogin'
    SET @sql = 'IF EXISTS (SELECT * from sys.procedures WHERE name = N''ccsp_RIAChecaLogin'')
        BEGIN
            DROP PROCEDURE dbo.ccsp_RIAChecaLogin;
        END'
    exec (@sql)
    

    SET @process = ''
    SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_RIAChecaLogin]
    @login             VARCHAR(40),
	@password          VARCHAR(40),
	@computer          VARCHAR(20),
	@passwordLwC       VARCHAR(40)=NULL
	AS
    DECLARE @loginOK TINYINT,@pswdOK TINYINT,@compuOK TINYINT,@extenOK TINYINT,@teclaOK TINYINT,@xferAgents TINYINT

    DECLARE @nombre VARCHAR(60),@extension VARCHAR(15),@userID SMALLINT,@cCServer VARCHAR(20),@dialingMode INT

    DECLARE @passwordDb VARCHAR(33)

    DECLARE @crmxActive TINYINT

    DECLARE @passSecure INT

	/*************************
	Para posiciones ip, by ODC
	*************************/

    DECLARE @ext_id INT,@pos_id INT,@isIP BIT,@ipExtension VARCHAR(15)

    DECLARE @tipoConexion SMALLINT

	/***************************************************************
	 Para live connected Tipo de conexion: 0 normal, 1 liveconnected
	***************************************************************/

    SELECT @loginOK=0,@pswdOK=0,@compuOK=0,@extenOK=0,@teclaOK=0,@xferAgents=0,@extension='' '',@userID=0,@nombre='' '',
    @tipoConexion=0,@ipExtension='''',@isIP=0,@cCServer=''127.0.0.1'',@dialingMode=0,@crmxActive=0,@passSecure=0

    SELECT @userID=User_id,@passwordDb=Password FROM ccUsers WITH(NOLOCK) WHERE Login = @login AND STATUS > 0 AND tipoUser_id = 1

    IF @userID > 0
    BEGIN
        SET @loginOK=1
    END

    IF @loginOK = 1 AND (
        @passwordDb = @password OR 
        @passwordDb = dbo.md5(@password) OR 
        dbo.md5(@passwordDb) = @password OR 
        @passwordDb = @passwordLwC OR 
        @passwordDb = dbo.md5(@passwordLwC) OR 
        dbo.md5(@passwordDb) = @passwordLwC)
    BEGIN
        SET @pswdOK=1
    END
    IF @pswdOK = 1 AND NOT EXISTS
                            (
                               SELECT pos_id FROM ccPosicion WITH(NOLOCK)
                               WHERE STATUS = ''1'' AND pos_id=@userID
                            )
    BEGIN
        INSERT INTO ccposicion(pos_id,computer,ext_id,user_id,IP) VALUES(@userID,@computer,0,@userID,@computer)
    END
    ELSE
    BEGIN
        UPDATE ccposicion set computer=@computer,ext_id=0,user_id=@userID,IP=@computer where pos_id=@userID
    END
    SET @compuOK=1
    IF @pswdOK = 1
    BEGIN
        IF EXISTS
               (
                  SELECT Computer
                  FROM ccPosicion AS P
                  JOIN ccMonitorExt AS M ON P.ext_id = M.ext_id
                  WHERE p.STATUS = ''1'' AND M.STATUS = ''1'' AND Computer = @computer
               )
        SET @extenOK=1

        SELECT @extension=Extension,@ext_id=p.ext_id,@pos_id=p.pos_id,@tipoConexion=p.tipoConexion,@isIP=isIP
        FROM ccPosicion AS P
        INNER JOIN ccMonitorExt AS M ON P.ext_id = M.ext_id
        WHERE Computer = @computer

        SELECT @teclaOK=COUNT(*)
        FROM ccTeclaExtensionPuerto AS T
        INNER JOIN ccMonitorExt AS M ON T.ext_id = M.ext_id
        WHERE M.Extension = @extension

        SELECT @nombre=Nombres + '' '' + ISNULL(ApellidoPaterno,'''') + '' '' + ISNULL(ApellidoMaterno,''''),@xferAgents=XferAgents,
        @dialingMode=DialingMode
        FROM ccUsers
        WHERE User_id = @userID

	/******************************************************************************************
	Para posiciones ip, by ODC
	 No verifica ccTeclaExtensionPuerto, @TeclaOK =1
	 Regresa un extension ''virtual''.  Debe ser diferente a cualquiera de ccMonitorExt.Extension
	******************************************************************************************/

        IF @ext_id = 0
        BEGIN
           SELECT @teclaOK=1,@extension=CAST(@pos_id * -1 AS VARCHAR(15))
        END

	/*****************************************************************************************
	-Por OAYC IPExtension, extension, para cuando es posición IP con alguna extension asignada
	*****************************************************************************************/

        ELSE
        IF @ext_id > 0 AND @isIP = 1
        BEGIN
           SELECT @teclaOK=1,@ipExtension=@extension,@extension=CAST(@pos_id * -1 AS VARCHAR(15))
        END

        IF @tipoConexion = 1
        SET @teclaOK=1

        SELECT @cCServer=valor
        FROM ccSettings
        WHERE setting_id = 7

        SELECT @crmxActive=valor
        FROM ccsettings
        WHERE setting_id = 168

        SELECT @passSecure=valor
        FROM ccSettings
        WHERE setting_id = 207

    END

    SELECT @loginOK AS LoginOK,@pswdOK AS PswdOK,@compuOK AS CompuOK,@extenOK AS ExtenOK,@extension AS Extension,@userID AS
    UserID,@nombre AS Nombre,@cCServer AS CCServer,@teclaOK AS TeclaOK,@tipoConexion AS TipoConexion,@ipExtension AS
    ipExtension,@xferAgents AS XferAgents,@crmxActive AS CRMx,@passSecure AS passSecure,@dialingMode AS dialingMode
	'
    exec (@sql)


    SET @process = 'delete from ccMenus Report Twitter'
    SET @sql = 'delete from ccMenus where menu_id in(11000,11010,11020,11030,11040) and type=3'
    exec (@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccsp_OUTInsertaCallBack] #9519'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTInsertaCallBack]
    @cal_id        INT,
    @Telefono      VARCHAR(15),
    @Camp          SMALLINT,
    @FechaDial     SMALLDATETIME,
    @callout_id    INT = 0,
    @TelReprograma SMALLINT = -1,
    @user_id       INT = 0,
    @cal_Key       VARCHAR(40) = '''',
    @isAuto        BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @TelReprograma < 0
        RETURN (0);

    DECLARE @Fecha                SMALLDATETIME,
            @sSQL                 NVARCHAR(MAX),
            @iZonaHoraria         INT,
            @iZonaHoraria_verano  INT,
            @iZonaHoraria2        INT,
            @iZonaHoraria_verano2 INT,
            @iZonaHoraria3        INT,
            @iZonaHoraria_verano3 INT,
            @iZonaHoraria4        INT,
            @iZonaHoraria_verano4 INT,
            @iZonaHoraria5        INT,
            @iZonaHoraria_verano5 INT,
            @idZone               INT,
            @idZoneDaylight       INT,
            @list_id              INT,
            @bIsDaylight          BIT,
            @difference           INT,
            @TelOriginal          VARCHAR(15),
            @FechaOriginal        DATETIME,
            @country_id           VARCHAR(10),
            @ld                   VARCHAR(5);

    SELECT @country_id = valor FROM dbo.ccSettings WITH (NOLOCK) WHERE setting_id = 104;
    SELECT @ld   = valor FROM dbo.ccSettings WITH (NOLOCK) WHERE setting_id = 17;

    SELECT @callout_id   = callout_id,
           @TelOriginal  = cal_telefono,
           @FechaOriginal = cal_Inicio
    FROM dbo.ccoCallsOut
    WHERE cal_id = @cal_id;

    DECLARE @colSuffix  varchar(1) = CAST(@TelReprograma AS varchar(1));

    IF @TelReprograma = 0 -- Otro teléfono
    BEGIN
        DECLARE @tel2           VARCHAR(20),
                @tel3           VARCHAR(20),
                @tel4           VARCHAR(20),
                @tel5           VARCHAR(20),
                @phoneCompleted VARCHAR(20),
                @emptyPhoneMsg  VARCHAR(50);

        SELECT @idZone = dbo.fnGetTimeZone(@Telefono, 0),@idZoneDaylight = dbo.fnGetTimeZone(@Telefono, 1)

        SELECT @phoneCompleted = dbo.Completa(@Telefono, @country_id, @ld);
        SELECT @emptyPhoneMsg  = CASE valor WHEN 0 THEN ''El teléfono no puede ser nulo o vacío'' ELSE ''Phone number can not be null or empty'' END
        FROM dbo.ccSettings WHERE setting_id = 27;

        IF CHARINDEX(''E_NV'', @phoneCompleted) > 0 SET @phoneCompleted = @Telefono;
        IF @phoneCompleted = ''''
        BEGIN
            RAISERROR(@emptyPhoneMsg, 18, 1);
        END

        SELECT @tel2 = cal_telefono2,
               @tel3 = cal_telefono3,
               @tel4 = cal_telefono4,
               @tel5 = cal_telefono5,
               @cal_Key = cal_key
        FROM dbo.ccoCallsOutSource
        WHERE callout_id = @callout_id;

        SELECT @TelReprograma = CASE
                                    WHEN ISNULL(@tel4, '''') = '''' THEN 4
                                    WHEN ISNULL(@tel3, '''') = '''' THEN 3
                                    WHEN ISNULL(@tel2, '''') = '''' THEN 2
                                    ELSE 5
                                END;
        if @colSuffix in(''0'',''1'') set @colSuffix=''''
        SET @sSQL = N''
        UPDATE dbo.ccoCallsOutSource
        SET cal_telefono'' + @colSuffix + N''       = @pPhone
            , cal_status                           = 2
            , iZonaHoraria'' + @colSuffix + N''       = @pIdZone
            , iZonaHoraria_Verano'' + @colSuffix + N'' = @pIdZoneDaylight
        WHERE callout_id = @pCalloutId;
        '';

        EXEC sys.sp_executesql
         @sSQL,
         N''@pPhone varchar(20), @pIdZone int, @pIdZoneDaylight int, @pCalloutId int'',
         @pPhone        = @phoneCompleted,
         @pIdZone       = @idZone,
         @pIdZoneDaylight = @idZoneDaylight,
         @pCalloutId    = @callout_id;

    END
    ELSE -- @TelReprograma > 0 teléfono ya existente
    BEGIN
        UPDATE dbo.ccoCallsOutSource
        SET cal_status = 2
        WHERE callout_id = @callout_id;

        set @colSuffix = CASE WHEN @TelReprograma = 1 THEN N'''' ELSE CONVERT(nvarchar(1), @TelReprograma) END;

        SET @sSQL = N''
        SELECT
            @outA = cal_key,
            @outB = iZonaHoraria'' + @colSuffix + N'',
            @outC = iZonaHoraria_Verano'' + @colSuffix + N'',
            @outD = RTRIM(LEFT(LTRIM(
                       cal_telefono  + N''''         '''' +
                       cal_telefono2 + N''''         '''' +
                       cal_telefono3 + N''''         '''' +
                       cal_telefono4 + N''''         '''' +
                       cal_telefono5 + N''''         ''''
                   ), 13))
        FROM dbo.ccoCallsOutSource
        WHERE callout_id = @pCalloutId;
        '';

        EXEC sys.sp_executesql
             @sSQL,
             N''@pCalloutId int,
               @outA varchar(33) OUTPUT,
               @outB int OUTPUT,
               @outC int OUTPUT,
               @outD varchar(19) OUTPUT'',
             @pCalloutId = @callout_id,
             @outA = @cal_Key OUTPUT,
             @outB = @idZone OUTPUT,
             @outC = @idZoneDaylight OUTPUT,
             @outD = @Telefono OUTPUT;
    END

    -- Para la fecha
    SELECT @bIsDaylight = dbo.fnIsDayLight(@country_id, GETDATE());

    IF @isAuto = 0
        SELECT @difference = dbo.fnGetTimeDifference(CASE WHEN @bIsDaylight = 0 THEN @idZone ELSE @idZoneDaylight END);
    ELSE
        SET @difference = 0;

    SELECT @Fecha = DATEADD(HOUR, @difference, CONVERT(DATETIME, @FechaDial, 101));

    UPDATE dbo.ccoCallsOut
    SET cal_fcallback = @FechaDial
    WHERE cal_id = @cal_id;

    -- Para las estadísticas
    IF EXISTS (SELECT 1 FROM dbo.ccRIAcallbacks WHERE año = YEAR(@Fecha) AND mes = MONTH(@Fecha) AND dia = DAY(@Fecha) AND hora = DATEPART(HOUR, @Fecha) AND cam_id = @Camp)
        UPDATE dbo.ccRIAcallbacks
        SET callbacks = callbacks + 1
        WHERE año = YEAR(@Fecha)
          AND mes = MONTH(@Fecha)
          AND dia = DAY(@Fecha)
          AND hora = DATEPART(HOUR, @Fecha)
          AND cam_id = @Camp;
    ELSE
        INSERT dbo.ccRIAcallbacks
        SELECT YEAR(@Fecha), MONTH(@Fecha), DAY(@Fecha), DATEPART(HOUR, @Fecha), ''1'', @Camp;

    SELECT @iZonaHoraria        = CASE WHEN LEN(cal_telefono)  > 0 THEN iZonaHoraria        ELSE NULL END,
           @iZonaHoraria_verano = CASE WHEN LEN(cal_telefono)  > 0 THEN iZonaHoraria_verano ELSE NULL END,
           @iZonaHoraria2       = CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria2       ELSE NULL END,
           @iZonaHoraria_verano2= CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END,
           @iZonaHoraria3       = CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria3       ELSE NULL END,
           @iZonaHoraria_verano3= CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END,
           @iZonaHoraria4       = CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria4       ELSE NULL END,
           @iZonaHoraria_verano4= CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END,
           @iZonaHoraria5       = CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria5       ELSE NULL END,
           @iZonaHoraria_verano5= CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE NULL END,
           @list_id             = list_id
    FROM dbo.ccoCallsOutSource
    WHERE callout_id = @callout_id;

    IF EXISTS (SELECT 1 FROM dbo.ccoWorkingTable WHERE callout_id = @callout_id)
    BEGIN
        UPDATE dbo.ccoWorkingTable
        SET cal_telefono       = @Telefono,
            cam_id             = @Camp,
            cal_fechaDial      = @Fecha,
            cal_status         = 1,
            nTryingContact     = 3,
            prioridad_cb       = 1,
            [user_id]          = @user_id,
            cal_keyw           = @cal_Key,
            iZonaHoraria       = @iZonaHoraria,
            iZonaHoraria_Verano= @iZonaHoraria_Verano,
            iZonaHoraria2      = @iZonaHoraria2,
            iZonaHoraria_Verano2= @iZonaHoraria_Verano2,
            iZonaHoraria3      = @iZonaHoraria3,
            iZonaHoraria_Verano3= @iZonaHoraria_Verano3,
            iZonaHoraria4      = @iZonaHoraria4,
            iZonaHoraria_Verano4= @iZonaHoraria_Verano4,
            iZonaHoraria5      = @iZonaHoraria5,
            iZonaHoraria_Verano5= @iZonaHoraria_Verano5
        WHERE callout_id = @callout_id;
    END
    ELSE
    BEGIN
        INSERT dbo.ccoWorkingTable
        (
            callout_id, cal_telefono, cam_id, cal_fechaDial, cal_status, nTryingContact, prioridad_cb,
            [user_id], cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2,
            iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5,
            iZonaHoraria_verano5, list_id
        )
        SELECT @callout_id, @Telefono, @Camp, @Fecha, 1, 3, 1,
               @user_id, @cal_Key,
               @iZonaHoraria, @iZonaHoraria_Verano,
               @iZonaHoraria2, @iZonaHoraria_Verano2,
               @iZonaHoraria3, @iZonaHoraria_Verano3,
               @iZonaHoraria4, @iZonaHoraria_Verano4,
               @iZonaHoraria5, @iZonaHoraria_Verano5,
               @list_id;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.ccoCallBacks WITH (NOLOCK) WHERE callout_id = @callout_id)
    BEGIN
        INSERT INTO dbo.ccoCallBacks
        (
            callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus
        )
        VALUES
        (
            @callout_id, @user_id, @Camp, @cal_Key, @TelOriginal, @Telefono, @FechaOriginal, @Fecha, NULL, 0, 1
        );
    END
    ELSE
    BEGIN
        UPDATE dbo.ccoCallBacks
        SET user_id        = @user_id,
            cam_id         = @Camp,
            cal_key        = @cal_Key,
            cal_telefono   = @TelOriginal,
            cal_telCB      = @Telefono,
            cal_fecha      = @FechaOriginal,
            cal_fusercallback = @Fecha,
            cal_fcallback  = NULL,
            status         = 0,
            schedulerStatus = 1
        WHERE callout_id = @callout_id;
    END

    SET NOCOUNT OFF;
END'
    exec (@sql)

    SET @process = '#9333 ALTER PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
@callout_id     INT,
@CallResultDial TINYINT,
@isTCPA         BIT     = 0
AS
BEGIN

    SET NOCOUNT ON

    /*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
    ++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine */

    DECLARE @nOcupado TINYINT, @nNoContesta TINYINT, @nFax TINYINT, @nContestadora TINYINT
    DECLARE @nShortCall TINYINT, @nOtro TINYINT, @cam_NoInt_ocupado TINYINT, @cam_NoInt_graba TINYINT
    DECLARE @cam_ocupado SMALLINT, @cam_inter_ocupado SMALLINT, @cam_nocontesto SMALLINT
    DECLARE @cam_graba SMALLINT, @cam_inter_graba SMALLINT, @cam_inter_nocontesto SMALLINT
    DECLARE @cam_fax SMALLINT, @cam_inter_fax SMALLINT
    DECLARE @DateNextDial DATETIME, @DateNewDial DATETIME, @cam_id SMALLINT
    DECLARE @ExisteWT TINYINT, @cam_NoInt_fax TINYINT, @cam_NoInt_nocontesto TINYINT, @cal_status TINYINT
    DECLARE @sSQL NVARCHAR(MAX), @Telefono VARCHAR(15), @prioridadLlamada CHAR(8)
    DECLARE @ExistePriorityOrder TINYINT

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
    IF @CallResultDial = 1 BEGIN-- CONTESTO
        IF @isTCPA = 1 BEGIN
            UPDATE ccoWorkingTable WITH (ROWLOCK, UPDLOCK) SET cal_status = @cal_status WHERE callout_id = @callout_id
        END
        ELSE
        BEGIN
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
    IF @CallResultDial IN(2, 12) BEGIN -- OCUPADO
        SELECT @cam_ocupado = cam_ocupado,
        @cam_inter_ocupado = cam_inter_ocupado,
        @cam_NoInt_ocupado = cam_NoInt_ocupado,
        @nOcupado = @nOcupado + 1
        FROM ccCamps
        WHERE cam_id = @cam_id

        IF @cam_ocupado = 1
        BEGIN -- Opcion Ocupado HABILITADA
            IF @nOcupado > @cam_NoInt_ocupado OR @nShortCall > 4
            BEGIN
                EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
                RETURN(0)
            END

            exec ccsp_OUTUpdateDialJobCommon @action=1,@callout_id=@callout_id,@cam_id= @cam_id, @prioridadLlamada =@prioridadLlamada OUTPUT

            -- Change priority and obtain the next telephone
            UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1    ELSE nNoContesta END
            WHERE callout_id = @callout_id

            exec ccsp_OUTUpdateDialJobCommon @action=2,@callout_id=@callout_id, @prioridadLlamada =@prioridadLlamada,@Telefono =@Telefono OUTPUT

            SELECT @DateNewDial = DATEADD(mi, @cam_inter_ocupado, GETDATE())

            -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
            IF @DateNewDial > @DateNextDial
            BEGIN   -- Nueva fecha de Call BACk
                UPDATE ccoWorkingTable WITH (ROWLOCK, UPDLOCK) SET nOcupado = @nOcupado, cal_fechaDial = @DateNewDial, cal_status = @cal_status
                WHERE callout_id = @callout_id
                RETURN(0)
            END

            -- Mantiene la fecha de Call BACK
            UPDATE ccoWorkingTable SET nOcupado = @nOcupado, cal_status = @cal_status, cal_telefono = case when @Telefono ='''' then cal_telefono else @Telefono end
            WHERE callout_id = @callout_id
            RETURN(0)
        END

        -- ELSE: Opcion Ocupado DESHABILITADA
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    IF @CallResultDial IN(3, 5, 8) BEGIN-- NO CONTESTA
        --select NO Contesta
        SELECT @cam_nocontesto = cam_nocontesto,
        @cam_inter_nocontesto = cam_inter_nocontesto,
        @cam_NoInt_nocontesto = cam_NoInt_nocontesto,
        @nNoContesta = @nNoContesta + 1
        FROM ccCamps
        WHERE cam_id = @cam_id

        IF @cam_nocontesto = 1
        BEGIN-- Opcion NoContesta HABILITADA
            IF @nNoContesta > @cam_NoInt_nocontesto OR @nShortCall > 4
            BEGIN --select No Contesta Habilitada
                EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                RETURN(0)
            END

            exec ccsp_OUTUpdateDialJobCommon @action=1,@callout_id=@callout_id,@cam_id= @cam_id, @prioridadLlamada =@prioridadLlamada OUTPUT

            -- Change priority and obtain the next telephone
            UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1
            ELSE nNoContesta END
            WHERE callout_id = @callout_id

            exec ccsp_OUTUpdateDialJobCommon @action=2,@callout_id=@callout_id, @prioridadLlamada =@prioridadLlamada,@Telefono =@Telefono OUTPUT

            SELECT @DateNewDial = DATEADD(mi, @cam_inter_nocontesto, GETDATE())

            UPDATE ccoWorkingTable SET nNoContesta = @nNoContesta, cal_status = @cal_status, cal_telefono = case when @Telefono ='''' then cal_telefono else @Telefono end,
            cal_fechaDial = CASE WHEN @DateNewDial > @DateNextDial THEN @DateNewDial ELSE cal_fechaDial END
            WHERE callout_id = @callout_id
            RETURN(0)
        END

        -- Opcion NoContesta DESHABILITADA
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    IF @CallResultDial = 4
    BEGIN-- Fax/Modem
        SELECT @cam_fax = cam_fax,
        @cam_inter_fax = cam_inter_fax,
        @cam_NoInt_fax = cam_NoInt_fax,
        @nFax = @nFax + 1
        FROM ccCamps
        WHERE cam_id = @cam_id

        IF @cam_fax = 1
        BEGIN-- Opcion Fax/Modem HABILITADA
            IF @nFax > @cam_NoInt_fax OR @nShortCall > 4
            BEGIN
                EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                RETURN(0)
            END

            exec ccsp_OUTUpdateDialJobCommon @action=1,@callout_id=@callout_id,@cam_id= @cam_id, @prioridadLlamada =@prioridadLlamada OUTPUT

            -- Change priority and obtain the next telephone
            UPDATE ccoCallsOutSource with(rowlock) SET nFax = CASE WHEN nFax < 255 THEN ISNULL(nFax, 0) + 1 ELSE nFax END
            WHERE callout_id = @callout_id

            exec ccsp_OUTUpdateDialJobCommon @action=2,@callout_id=@callout_id, @prioridadLlamada =@prioridadLlamada,@Telefono =@Telefono OUTPUT

            SELECT @DateNewDial = DATEADD(mi, @cam_inter_fax, GETDATE())

            -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
            UPDATE ccoWorkingTable SET nFax = @nFax, cal_status = @cal_status, cal_telefono = case when @Telefono ='''' then cal_telefono else @Telefono end,
            cal_fechaDial = CASE WHEN @DateNewDial > @DateNextDial  THEN @DateNewDial ELSE cal_fechaDial END
            WHERE callout_id = @callout_id
            RETURN(0)
        END

        -- Opcion Fax/Modem DESHABILITADA
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    IF @CallResultDial = 11
    BEGIN-- Maquina Contestadora
        SELECT @cam_graba = cam_graba,
        @cam_inter_graba = cam_inter_graba,
        @cam_NoInt_graba = cam_NoInt_graba,
        @nContestadora = @nContestadora + 1
        FROM ccCamps
        WHERE cam_id = @cam_id

        IF @cam_graba = 1 BEGIN-- Opcion Maquina Contestadora HABILITADA
            IF @nContestadora > @cam_NoInt_graba OR @nShortCall > 4
            BEGIN
                EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                RETURN(0)
            END

            exec ccsp_OUTUpdateDialJobCommon @action=1,@callout_id=@callout_id,@cam_id= @cam_id, @prioridadLlamada =@prioridadLlamada OUTPUT

            -- Change priority and obtain the next telephone
            UPDATE ccoCallsOutSource with(rowlock) SET nContestadora = CASE WHEN nContestadora < 255 THEN ISNULL(nContestadora, 0) + 1 ELSE nContestadora END
            WHERE callout_id = @callout_id

            exec ccsp_OUTUpdateDialJobCommon @action=2,@callout_id=@callout_id, @prioridadLlamada =@prioridadLlamada,@Telefono =@Telefono OUTPUT

            SELECT @DateNewDial = DATEADD(mi, @cam_inter_graba, GETDATE())

            -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
            UPDATE ccoWorkingTable SET nContestadora = @nContestadora, cal_status = @cal_status, cal_telefono = case when @Telefono ='''' then cal_telefono else @Telefono end,
            cal_fechaDial = CASE WHEN @DateNewDial > @DateNextDial THEN @DateNewDial ELSE cal_fechaDial END
            WHERE callout_id = @callout_id
            RETURN(0)
        END

        -- Opcion Maquina Contestadora DESHABILITADA
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    IF @CallResultDial IN(10, 90)
    BEGIN--No Dial Tone, otros, NoService
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    IF @CallResultDial > 13 AND @CallResultDial <> 51   BEGIN--Dial Result not register
        EXEC ccsp_OUTUpdateDialJob @callout_id = @callout_id, @CallResultDial = 8, @isTCPA = @isTCPA
    END

    RETURN(0)
    SET NOCOUNT OFF
END'
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
