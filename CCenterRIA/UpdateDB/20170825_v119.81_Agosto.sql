/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Omar Mejía Magos
Date: 2017/08/25
Description:
	se modfiica el SP ccsp_OUTGetNewJobs CW-974 Clicker
	se modifica el SP ccsp_OUTGetNewProviderJobs CW-974 Clicker
	se modifico el SP ccsp_OUTUpdateDialJob CW-974 Clicker
	Se modifica el SP ccsp_OUTcheckTimeZone CW-974 Clicker
	

Database: CCenterRia
Required version: 119.74

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 129 sin fix
set @versionfix = 8
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and (@actualVersionFix = @versionfix - 1 or @actualVersionFix = @versionfix)
	begin
		begin tran
		begin try
		
	---------------- SP1 ccsp_OUTGetNewJobs
    set @process = 'alter ccsp_OUTGetNewJobs -- CW-974-Clicker'
    set @Sql= '

ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID int,
@test int=0,
@nAgentsLogin int=1,
@iZonas int = null
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
calkey varchar(max)
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
			cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
			left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
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
            order by prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)

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
			cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
			left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
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
            order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''

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
begin
      select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5,
case when tz is null then '''''''' else cal_telefono end as tel,
case when tz2 is null then '''''''' else cal_telefono end as tel2,
case when tz3 is null then '''''''' else cal_telefono end as tel3,
case when tz4 is null then '''''''' else cal_telefono end as tel4,
case when tz5 is null then '''''''' else cal_telefono end as tel5,
NULL as dialOrder, list_id, sequence, calkey FROM #NEW_JOBS where len(cal_telefono)>0

---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
declare @regval int
SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
exec ccsp_RIAGetCampsNvosCB @cam_id=1,@Tipo=2,@user_id =0,@regval=@regval
''
end

set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
print (@sql)
exec(@sql)

return(0)
	
	'
	EXEC(@Sql)
	
	---------------- SP2 ccsp_OUTGetNewProviderJobs
    set @process = 'alter ccsp_OUTGetNewProviderJobs -- CW-974-Clicker'
    set @Sql= '

ALTER procedure [dbo].[ccsp_OUTGetNewProviderJobs]
@CAMPID as int,
@test as int=0,
@nAgentsLogin as int=1
as
set nocount on
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @sql varchar(MAX), @Order_Asc_Desc char(4)
declare @camSurvey int
DECLARE @iZonasTable TABLE (value int)

select @camSurvey = 0

select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

-- VALIDAMOS EL PAIS Y LADA CONFIGURADA --
SELECT @country_id =valor FROM ccSettings WHERE setting_id=104
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
		declare @horaUniversal as datetime
		set @horaUniversal=getutcdate()

		if @iZonas = 0 begin
			SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
			return
		end
		end

	else
	begin
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
tel varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel2 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel3 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel4 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel5 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
dialOrder varchar(10),
list_id int,
sequence smallint,
calkey varchar(max)
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
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isnull(R.sequence,0) as sequence,
	couts.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
	FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
	on W.list_id = R.list_id
	left join ccocallsoutsource couts (nolock)
	on W.callout_id = couts.callout_id
	WHERE W.cal_status=1 -- CallBacks
	and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
	and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
	and (
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
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
	order by W.prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
	end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
	begin
	select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

	select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isNull(R.sequence,0) as sequence,
	couts.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
	FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
	on W.list_id = R.list_id
	left join ccocallsoutsource couts (nolock)
	on W.callout_id = couts.callout_id
	WHERE W.cal_status=0 -- Nuevas
	and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
	and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
	and (
		( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
		( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', W.callout_id''

	end -- TOMA EN CUENTA LAS NUEVAS

----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @sql=@sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
	begin
	select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
	WHERE callout_id in(select callout_id from #NEW_JOBS)''
	end

select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5, tel, tel2, tel3, tel4, tel5, dialOrder, list_id, sequence, calkey FROM #NEW_JOBS where len(cal_telefono)>0''

select @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print @sql
exec(@sql)
return(0)	
	
	'
	EXEC(@Sql)

	---------------- SP3 ccsp_OUTUpdateDialJob
    set @process = 'alter ccsp_OUTUpdateDialJob -- CW-974-Clicker'
    set @Sql= '

ALTER PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
@callout_id int,
@CallResultDial tinyint,
@isTCPA bit =0
as
set nocount on
/*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine	*/
declare @nOcupado tinyint, @nNoContesta tinyint, @nFax tinyint, @nContestadora tinyint
declare @nShortCall tinyint, @nOtro tinyint, @cam_NoInt_ocupado tinyint, @cam_NoInt_graba tinyint
declare @cam_ocupado smallint, @cam_inter_ocupado smallint, @cam_nocontesto smallint
declare @cam_graba smallint, @cam_inter_graba smallint, @cam_inter_nocontesto smallint
declare @cam_fax smallint, @cam_inter_fax smallint
declare @DateNextDial smalldatetime, @DateNewDial smalldatetime, @cam_id smallint
declare @ExisteWT tinyint, @cam_NoInt_fax tinyint, @cam_NoInt_nocontesto tinyint,@cal_status tinyint
declare @sSQL nvarchar(max), @Telefono varchar(15)

SELECT @cam_id=cam_id, @nOcupado=IsNull(nOcupado, 0), @nNoContesta=IsNull(nNoContesta,0),
	@nFax=IsNull(nFax, 0), @nContestadora=IsNull(nContestadora, 0),@nShortCall=IsNull(nShortCall,0),
	@nOtro=IsNull(nOtro,0),@DateNextDial=cal_fechaDial
FROM ccoWorkingTable WHERE callout_id = @callout_id

select @ExisteWT=case when @cam_id is not null then 1 else 0 end

select @cal_status= case when @isTCPA=1 then 0 else 1 end--si esta en modo TCPA no generar callbacks

IF @CallResultDial=20 -- CONTACTADO
 BEGIN
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial=1 -- CONTESTO
 BEGIN
IF @isTCPA=1
	BEGIN	
		UPDATE ccoWorkingTable SET cal_status=@cal_status 
		WHERE callout_id = @callout_id
	END
ELSE
	BEGIN
		if (select abandonCallback from ccCamps where cam_id = @cam_id) = 1 begin
		EXEC ccsp_OUTCancelDialJOB @callout_id, 1, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
		end
		else begin
		EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
		end
	END
	return(0)
 END

IF @CallResultDial in (2,12) -- OCUPADO
 BEGIN
	SELECT @cam_ocupado =cam_ocupado, @cam_inter_ocupado=cam_inter_ocupado, @cam_NoInt_ocupado=cam_NoInt_ocupado, @nOcupado= @nOcupado+1
	FROM ccCamps WHERE cam_id=@cam_id
	
	IF @cam_ocupado=1 -- Opcion Ocupado HABILITADA
	 BEGIN
		IF @nOcupado>@cam_NoInt_ocupado or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		-- Change priority and obtain the next telephone
		update ccoCallsOutSource set nNoContesta=case when nNoContesta < 255 then isnull(nNoContesta,0)+1 else nNoContesta end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT
		
		SELECT @DateNewDial=dateadd(mi, @cam_inter_ocupado, getdate())
		-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
		IF @DateNewDial>@DateNextDial
		 BEGIN	-- Nueva fecha de Call BACk
			UPDATE  ccoWorkingTable SET nOcupado=@nOcupado, cal_fechaDial=@DateNewDial, cal_status=@cal_status WHERE callout_id = @callout_id
			return(0)
		 END
			-- Mantiene la fecha de Call BACK
		UPDATE  ccoWorkingTable SET nOcupado=@nOcupado, cal_status=@cal_status, cal_telefono=@Telefono  WHERE callout_id = @callout_id
		return(0)
	 END

-- ELSE: Opcion Ocupado DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
  END

IF @CallResultDial in (3,5,8) -- NO CONTESTA
 BEGIN
	--select NO Contesta
	SELECT @cam_nocontesto =cam_nocontesto, @cam_inter_nocontesto=cam_inter_nocontesto, @cam_NoInt_nocontesto=cam_NoInt_nocontesto, @nNoContesta=@nNoContesta+1
	FROM ccCamps WHERE cam_id=@cam_id

	--SELECT @cam_nocontesto, @cam_inter_nocontesto, @cam_NoInt_nocontesto, @nNoContesta
	IF @cam_nocontesto=1 -- Opcion NoContesta HABILITADA
	 BEGIN
		--select No Contesta Habilitada
		IF @nNoContesta>@cam_NoInt_nocontesto or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		-- Change priority and obtain the next telephone
		update ccoCallsOutSource set nNoContesta=case when nNoContesta < 255 then isnull(nNoContesta,0)+1 else nNoContesta end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT

		SELECT @DateNewDial=dateadd(mi, @cam_inter_nocontesto, getdate())		
		UPDATE ccoWorkingTable SET nNoContesta =@nNoContesta, cal_status=@cal_status, cal_telefono=@Telefono, 
		cal_fechaDial=case when @DateNewDial>@DateNextDial then @DateNewDial else cal_fechaDial end
		WHERE callout_id = @callout_id
		return(0)
	 END

	-- Opcion NoContesta DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial=4 -- Fax/Modem
 BEGIN
	SELECT @cam_fax =cam_fax, @cam_inter_fax=cam_inter_fax, @cam_NoInt_fax=cam_NoInt_fax, @nFax=@nFax +1
	FROM ccCamps WHERE cam_id=@cam_id

	IF @cam_fax=1 -- Opcion Fax/Modem HABILITADA
	 BEGIN
		IF @nFax>@cam_NoInt_fax or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		-- Change priority and obtain the next telephone
		update ccoCallsOutSource set nFax=case when nFax < 255 then isnull(nFax,0)+1 else nFax end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT

		SELECT @DateNewDial=dateadd(mi, @cam_inter_fax, getdate())

		-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
		UPDATE ccoWorkingTable SET nFax =@nFax, cal_status=@cal_status, cal_telefono=@Telefono,
		cal_fechaDial=case when @DateNewDial>@DateNextDial then @DateNewDial else cal_fechaDial end
		WHERE callout_id = @callout_id

		return(0)
	 END

	-- Opcion Fax/Modem DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial=11 -- Maquina Contestadora
 BEGIN
	SELECT @cam_graba =cam_graba, @cam_inter_graba=cam_inter_graba, @cam_NoInt_graba=cam_NoInt_graba, @nContestadora=@nContestadora+1
	FROM ccCamps WHERE cam_id=@cam_id

	IF @cam_graba=1 -- Opcion Maquina Contestadora HABILITADA
	 BEGIN
		IF @nContestadora>@cam_NoInt_graba or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		 -- Change priority and obtain the next telephone
		 update ccoCallsOutSource set nContestadora=case when nContestadora < 255 then isnull(nContestadora,0)+1 else nContestadora end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT

		SELECT @DateNewDial=dateadd(mi, @cam_inter_graba, getdate())

		-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
		UPDATE ccoWorkingTable SET nContestadora =@nContestadora, cal_status=@cal_status, cal_telefono=@Telefono,
		cal_fechaDial= case when @DateNewDial>@DateNextDial then @DateNewDial else cal_fechaDial end
		WHERE callout_id = @callout_id
		return(0)
	 END

	-- Opcion Maquina Contestadora DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial in (10,90) --No Dial Tone, otros, NoService
 BEGIN
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

return(0)
set nocount off	
	
	'
	EXEC(@Sql)    
	
	---------------- SP4 ccsp_OUTcheckTimeZone
    set @process = 'alter ccsp_OUTcheckTimeZone -- CW-974-Clicker'
    set @Sql= '

ALTER procedure [dbo].[ccsp_OUTcheckTimeZone]
@cam_id as int
AS
set nocount on
declare @horaUniversal datetime, @revHorario bit,@isShudulerLey bit
declare @valueShudulerLey varchar(max),@hourStart int,@hourEnd int,@minStart int,@minEnd int
declare @shourStart varchar(max),@shourEnd varchar(max)
declare @timeMaxContestacion int

set @timeMaxContestacion=60

select @revHorario=valor from ccsettings where setting_id = 112
select @valueShudulerLey = valor from ccsettings where setting_id=166
select @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)) as int),@valueShudulerLey=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
select @timeMaxContestacion=(cam_tNoContesta*2) from cccamps where cam_id=@cam_id
set @timeMaxContestacion=CEILING(cast(@timeMaxContestacion as decimal(10,2)) / cast(60 as decimal(10,2)))
if @valueShudulerLey='''' begin
      set @valueShudulerLey=''0|07:00|22:00''
      update ccsettings set valor=@valueShudulerLey where setting_id=166
end
if @isShudulerLey = 1 begin
      select @shourStart=substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)),@shourEnd=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
      select @hourStart=substring(@shourStart, 0, charindex('':'',@shourStart)),@minStart=substring(@shourStart, charindex('':'',@shourStart) + 1, len(@shourStart))
      select @hourEnd=substring(@shourEnd, 0, charindex('':'',@shourEnd)),@minEnd=substring(@shourEnd, charindex('':'',@shourEnd) + 1, len(@shourEnd))
end
else begin
      select @hourStart=0,@minStart=0,@hourEnd=23,@minEnd=59
end

SET DATEFIRST 1
set @horaUniversal = getutcdate()

-- Si la campaña no tiene horarios asignados, marcar todas las zonas
if @revHorario = 0
begin
      if not exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@cam_id)
            begin
                  select sum(distinct tz_id) from (
                  select tz_id,
                        dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
                        datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora,
                        datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
                        datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
                        from ccTimeZones
                  )zonas
                  where (hora > @hourStart or (hora = @hourStart and minuto >= @minStart) )and
                        ( hora < @hourEnd  or (hora = @hourEnd and minuto <= @minEnd) )
            return(0)
            end
end


select h.horario_id,Descripcion,
      case when HoraInicio>@hourStart then HoraInicio else @hourStart end HoraInicio,
      case when (horaInicio>@hourStart or (horaInicio=@hourStart and MinInicio>=@minStart) ) then MinInicio  else @minStart end MinInicio,
      case when horaFin<@hourEnd then horaFin else @hourEnd end HoraFin,
      case when ((horaFin < @hourEnd or (horaFin=@hourEnd and MinFin<=@minEnd) )) then MinFin  else @minEnd end MinFin,
      Lunes,Martes,Miercoles,Jueves,Viernes,Sabado,Domingo  
 into #tempCamp
 from cchorarios h
      inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on h.horario_id = ccCampsHorarios.horario_id and ccCampsHorarios.cam_id = @cam_id    


select isnull(sum( distinct tz_id),0) from
(
      select tz_id,
      dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
      datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora,
      datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
      datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
      from ccTimeZones
)zonas
inner join #tempCamp on
(
      (
            hora > HoraInicio OR  (hora = HoraInicio AND minuto >= MinInicio)
      )
      AND
      (
            hora < HoraFin    OR  (hora = HoraFin AND minuto <= (MinFin-@timeMaxContestacion) )
      )
      AND
      (
            Lunes  = dia or
            Martes *2 = dia or
            Miercoles*3 = dia or
            Jueves*4 = dia or
            Viernes*5 = dia or
            Sabado*6 = dia or
            domingo*7 = dia
      )

)
drop table #tempCamp	
	
	'
	EXEC(@Sql)



    
    set @process = ''
    set @Sql= ''
    EXEC(@Sql)

    set @process = ''
    set @Sql= ''
    EXEC(@Sql)



		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
