/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2016/06/08
Description:

	ADD COlumna ccCampsNvosCB.dateUpdate actualizar las cubetas por campaña en lugar de global ya no se usa el Setting 21
	ALter SP ccsp_RIAGetCampsNvosCB -- Se modifica para actualizar por camapaña se valida que si pasa el valor solo actualiza
	ALTER SP ccsp_OUTGetNewJobs se manda ejecutar el SP ccsp_RIAGetCampsNvosCB para actualizar cubetas cada vez que el outbound pida datos
	ALTER SP -- ccsp_RIAOUTInsertNewJOBS_WT_Camp Se cambia para actualizar un top 2500 registros

Database: CCenterRia
Required version: 119.04

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
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 118 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 120 sin fix
set @versionfix = 5
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

EXEC master..sp_addsrvrolemember @loginame = N'ccUser', @rolename = N'sysadmin'

if @actualVersion = @version and @actualVersionFix = @versionfix-1
	begin
		begin tran
		begin try

		set @process = 'Add Column -- ccCampsNvosCB.dateUpdate'
		set @sql='if not exists (select * from sys.columns where name = N''dateUpdate'' and Object_ID = Object_ID(N''ccCampsNvosCB''))
    ALTER TABLE ccCampsNvosCB ADD dateUpdate datetime'
		EXEC(@sql)

		set @process = 'Alter SP ccsp_RIAGetCampsNvosCB -- Change update '
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0
as
set nocount on

declare @TipoJobs as int,@isExecOutbound bit

--declare  @cam_id integer, @Tipo tinyint, @user_id int,@regval int
--select @cam_id=1,@Tipo=1,@user_id=4,@regval=0

set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2)	begin

	declare @id AS INTEGER

	CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
	CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)

	create table #temccocallsoutsource (cam_id int,Pend  int)

	create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

	if @cam_id = 0 begin
		if @user_id > 0 begin
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
			select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
			from ccCamps cam left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
			where user_id = @user_id and tipo = 1
		end
		else begin
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
			select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
			from ccCamps cam left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
		end

	end
	else begin
		if @Tipo = 2
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
			select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
			from ccCamps cam
			--left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
			where cam.cam_id = @cam_id --and user_id = @user_id and tipo = 1
		else
			insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
				select cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
				from ccCamps
	end



	insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
	select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0 from(
	select A.* from #Tcamps A
	left join ccCampsNvosCB B on A.cam_id=B.id
	where datediff(ss,B.dateUpdate,getdate())>5 or B.dateUpdate is null)X

	group by cam_id


	--Se revisa que por lo menos una campaña se pueda actualizar para realizar el proceso en caso contrario se regresa el valro extablecido
	if (select count(*) from #Tcamps2)>0 begin

		insert into #temccocallsoutsource(cam_id,Pend)
		SELECT ccos.cam_id, count(ccos.cam_id) as Pend
		FROM ccocallsoutsource ccos --with(nolock index(IX_ccoCallsOutSource))
		left join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
		WHERE cal_status in(0, 7)
		GROUP BY ccos.cam_id

		insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
		SELECT A.cam_id,
		count(case cal_status when 0 then 1 else null end) as New,
		count(case cal_status when 1 then 1 else null end) as Cb,
		count(case cal_status when 2 then 1 else null end) as Pro,
		count(case cal_status when 3 then 1 else null end) as Fin
		FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
		inner join #Tcamps2 B on A.cam_id = B.cam_id
		GROUP BY A.cam_id

		--select * from #Tcamps2

		--Se va agregar al ccsp_OUTGetNewJobs cuando lo ejecute el SP Outbound para actualizar de manera seguida si solo es una campaña
		if @regval = 0 and @cam_id >0 and @Tipo =2 begin
			update #Tcamps2	set status =1,cantidad=@regval	where cam_id = @cam_id
		end
		else begin
			While (select count(*) from #Tcamps2 where status = 0) > 0 Begin
				set rowcount 1
				select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
				set rowcount 0
				EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
				update #Tcamps2	set status =1,cantidad=@regval	where cam_id = @id
			end
		end

		begin Tran updateccCampsNvosCB

			delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
			where CampNvosCB.id = tcamp.cam_id

			INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial,dateUpdate)
			SELECT cams.cam_id, cams.cam_descripcion,
			isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
			isNull(cs.Pend,0) as pend,
			isNull(wt.Pro,0) as pro,
			isNull(cams.procesando,0) cam_procesando,
			isNull(cams.cam_tipojobs,0) cam_tipojobs,
			isNull(wt.Fin,0) Fin,
			isNull(tc.cantidad,0) cantidad,
			getdate()
			FROM #Tcamps cams with(nolock)
			LEFT JOIN #temWorkinTable	 wt on cams.cam_id = wt.cam_id
			LEFT JOIN #temccocallsoutsource	cs on cams.cam_id = cs.cam_id
			left join #Tcamps2 tc on (tc.cam_id = cams.cam_id)

		COMMIT TRAN updateccCampsNvosCB
	end

	if @isExecOutbound = 0 begin

		if @Tipo = 2
			-- devuelve resultado de la taba, solo las camps del usuario
			SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, res.st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial
			FROM #Tcamps tcam
			left join  ccCampsNvosCB res  on tcam.cam_id  = res.id
			LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
		else
			SELECT id, campaña, new, cb, pro, pen,st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial
			FROM ccCampsNvosCB res
			LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
			WHERE res.id = @cam_id
	end

	drop table #Tcamps
	drop table #Tcamps2
	drop table #temccocallsoutsource
	drop table #temWorkinTable

	return(0)

end

set nocount off'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_OUTGetNewJobs ADD update Cubetas exec  SP ccsp_RIAGetCampsNvosCB'
		set @sql='ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
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
declare @sql varchar(4000), @Order_Asc_Desc char(4)
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
sequence smallint
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
set @isVerano = ''izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin

            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,
            W.list_id, isNull(R.sequence,0) as sequence
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
            WHERE cal_status=1 -- CallBacks
            and cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
            and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                  ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by prioridad_cb desc, cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)

            --select @sql
end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,
            W.list_id, isNull(R.sequence,0) as sequence
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
            WHERE cal_status=0 -- Nuevas sin Tiempo
            and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                  ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by R.sequence, cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''

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
NULL as dialOrder, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0

---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
declare @regval int
SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
exec ccsp_RIAGetCampsNvosCB @cam_id=1,@Tipo=2,@user_id =0,@regval=@regval
''
end

set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
print (@sql)
exec(@sql)

return(0)'
		EXEC(@sql)

		set @process = 'ALTER SP -- ccsp_RIAOUTInsertNewJOBS_WT_Camp'
		set @sql='ALTER procedure [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp]
@camp_id as int,
@reciclar as int = 1
as
set nocount on

--declare @camp_id int,@reciclar int
--set @camp_id=5
--set @reciclar=1

declare @top int
declare @prioridad varchar(8)

set @top=2000

select @prioridad = isnull(Prioridad,''12345NNN'') from ccCampsPrioridadTel with(nolock) where cam_id = @camp_id

Delete top (@top) ccUploadTemporal with(rowlock) where cam_id = @camp_id

create table #calloutIdSource(callout_id int not null primary key)

create table #calloutIdSource2(callout_id int not null primary key)

create table #calloutIdSource3(callout_id int not null primary key)

insert into #calloutIdSource
select top (@top) cs.callout_id
from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_15),nolock),
ccoWorkingTable wt with(index(IX_ccoWorkingTable_15),nolock)
where cs.cal_key = wt.cal_keyw
and cs.cam_id = wt.cam_id
and cs.cam_id = @camp_id
and cs.cal_status in(0,7)
and wt.cal_status <= 2

insert into #calloutIdSource2
select top (@top) Cout.callout_id
from ccoCallsOutSource Cout with(index(IX_ccoCallsOutSource_16),nolock),
ccoworkingtable Wtab (nolock)
WHERE Cout.callout_id = Wtab.callout_id
and Cout.cam_id = @camp_id
and (COUT.cal_status < 2 or COUT.cal_status = 7)

insert into #calloutIdSource3
select top (@top) callout_id
from ccoCallsOutSource with(index(IX_ccoCallsOutSource_11),nolock)
WHERE cal_status in (0, 1, 7)
and cam_id = @camp_id

if (select count(*) from #calloutIdSource) > 0 begin
	update ccoCallBacks
	set [status] = 6, schedulerStatus = 1
	from ccoCallBacks cb with(index(IX_ccoCallBacks6),nolock), #calloutIdSource cis with(nolock)
	where cb.callout_id = cis.callout_id

	update ccoCallsOutSource
	set cal_Status = 4
	from ccoCallsOutSource cs with(nolock), #calloutIdSource cis with(nolock)
	where cs.callout_id = cis.callout_id
end

if (select count(*) from #calloutIdSource2) > 0 begin
	update ccoCallBacks
	set [status] = 6, schedulerStatus = 1
	from ccoCallBacks cb with(index(IX_ccoCallBacks6),nolock), #calloutIdSource2 csi2 with(nolock)
	where cb.callout_id = csi2.callout_id

	update ccoCallsOutSource
	set cal_Status = 4
	from ccoCallsOutSource Cout with(nolock), #calloutIdSource2 csi2 with(nolock)
	WHERE Cout.callout_id = csi2.callout_id
end

begin transaction insertccoWorkingTable

	Insert ccoWorkingTable with(TABLOCKX)
	--Insert ccoWorkingTable with(PAGLOCK)
	(callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2,
	iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
	SELECT top (@top) A.callout_id, A.cam_id,
	rtrim(left(ltrim(A.cal_telefono + ''        ''
			+ A.cal_telefono2 + ''         ''
			+ A.cal_telefono3 + ''         ''
			+ A.cal_telefono4 + ''         ''
			+ A.cal_telefono5 + ''         ''),13)) as cal_telefono,
	case A.cal_status when 7 then 1 else A.cal_status end cal_status, A.cal_fechaDial, A.cal_key,
	case when len( A.cal_telefono ) > 0 then A.iZonaHoraria else null end iZonaHoraria, case when len( A.cal_telefono ) > 0 then A.iZonaHoraria_verano else null end iZonaHoraria_verano,
	case when len( A.cal_telefono2 ) > 0 then A.iZonaHoraria2 else null end iZonaHoraria2, case when len( A.cal_telefono2 ) > 0 then A.iZonaHoraria_verano2 else null end iZonaHoraria_verano2,
	case when len( A.cal_telefono3 ) > 0 then A.iZonaHoraria3 else null end iZonaHoraria3, case when len( A.cal_telefono3 ) > 0 then A.iZonaHoraria_verano3 else null end iZonaHoraria_verano3,
	case when len( A.cal_telefono4 ) > 0 then A.iZonaHoraria4 else null end iZonaHoraria4, case when len( A.cal_telefono4 ) > 0 then A.iZonaHoraria_verano4 else null end iZonaHoraria_verano4,
	case when len( A.cal_telefono5 ) > 0 then A.iZonaHoraria5 else null end iZonaHoraria5, case when len( A.cal_telefono5 ) > 0 then A.iZonaHoraria_verano5 else null end iZonaHoraria_verano5,
	A.list_id
	FROM ccoCallsOutSource A with(index(IX_ccoCallsOutSource_17),nolock)
	left join ccoWorkingTable  B on A.callout_id=B.callout_id and A.cam_id=b.cam_id
	WHERE A.cam_id = @camp_id
	and (A.cal_status < 2 or A.cal_status = 7) -- Nuevos Jobs
	and B.callout_id is null

commit transaction insertccoWorkingTable

begin transaction insertccoCallBacks

	Insert into ccoCallBacks with(TABLOCKX)
	--Insert into ccoCallBacks with(PAGLOCK)
	(callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
	SELECT top (@top) A.callout_id, A.user_id, A.cam_id, A.cal_key,
	rtrim(left(ltrim(A.cal_telefono + ''        ''
			+ A.cal_telefono2 + ''         ''
			+ A.cal_telefono3 + ''         ''
			+ A.cal_telefono4 + ''         ''
			+ A.cal_telefono5 + ''         ''),13)) as cal_telefono1,
	rtrim(left(ltrim(A.cal_telefono + ''        ''
			+ A.cal_telefono2 + ''         ''
			+ A.cal_telefono3 + ''         ''
			+ A.cal_telefono4 + ''         ''
			+ A.cal_telefono5 + ''         ''),13)) as cal_telefono2,A.cal_fechaDial,A.cal_fechaDial cal_fusercallback,NULL cal_fcallback,0 status,1 schedulerStatus
	FROM ccoCallsOutSource A with(index(IX_ccoCallsOutSource_18),nolock)
	left join ccoWorkingTable  B on A.callout_id=B.callout_id and A.cam_id=b.cam_id
	WHERE A.cam_id = @camp_id
	and (A.cal_status < 2 or A.cal_status = 7) -- Nuevos Jobs
	and B.callout_id is null

commit transaction insertccoCallBacks

begin transaction updateccoCallsOutSource

	UPDATE ccoCallsOutSource
	SET cal_status = 2, dial_tels = @prioridad, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
	from ccoCallsOutSource co with(nolock), #calloutIdSource3 cis3 with(nolock)
	where co.callout_id = cis3.callout_id

commit transaction updateccoCallsOutSource

drop table #calloutIdSource
drop table #calloutIdSource2
drop table #calloutIdSource3

set nocount off'
		EXEC(@sql)

		set @process = 'DROP JOB -- CW Reports Migration Chat'
		set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Reports Migration Chat'')	EXEC msdb.dbo.sp_delete_job @job_name=N''CW Reports Migration Chat'', @delete_unused_schedule=1'
		EXEC(@sql)

		set @process = 'DROP JOB -- NuxibaNewReportsMaintenancePlan'
		set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''NuxibaNewReportsMaintenancePlan'') EXEC msdb.dbo.sp_delete_job @job_name=N''NuxibaNewReportsMaintenancePlan'', @delete_unused_schedule=1'
		EXEC(@sql)

		set @process = 'DROP JOB -- CW AutoStart'
		set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW AutoStart'')	EXEC msdb.dbo.sp_delete_job @job_name=N''CW AutoStart'', @delete_unused_schedule=1'
		EXEC(@sql)

		set @process = 'DROP JOB -- CW Campaign summary'
		set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Campaign summary'')	EXEC msdb.dbo.sp_delete_job @job_name=N''CW Campaign summary'', @delete_unused_schedule=1'
		EXEC(@sql)

		set @process = 'DROP JOB -- CW Reports Migration Chat'
		set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW (AutoStart),(allback/abandoned update),(Campaign summary)'')	EXEC msdb.dbo.sp_delete_job @job_name=N''CW (AutoStart),(allback/abandoned update),(Campaign summary)'', @delete_unused_schedule=1'
		EXEC(@sql)

		set @process = 'DROP JOB -- CW (AutoStart),(Callback/abandoned update),(Campaign summary)'
		set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'') 	EXEC msdb.dbo.sp_delete_job @job_name=N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'', @delete_unused_schedule=1'
		EXEC(@sql)

		set @process = 'DROP JOB -- CW Callback/abandoned update'
		set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Callback/abandoned update'') EXEC msdb.dbo.sp_delete_job @job_name=N''CW Callback/abandoned update'', @delete_unused_schedule=1'
		EXEC(@sql)

		set @process = 'DROP JOB -- AVRS Merge Replication'
		set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''AVRS Merge Replication'') EXEC msdb.dbo.sp_delete_job @job_name=N''AVRS Merge Replication'', @delete_unused_schedule=1'
		EXEC(@sql)

		set @process = 'DROP JOB -- CW Merge Replication'
		set @sql='if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Merge Replication'')	EXEC msdb.dbo.sp_delete_job @job_name=N''CW Merge Replication'', @delete_unused_schedule=1'
		EXEC(@sql)

		set @process = 'CREATE JOB --- AVRS Merge Replication'
		set @sql='USE [msdb]

/****** Object:  Job [AVRS Merge Replication]    Script Date: 14/06/2016 12:28:23 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 14/06/2016 12:28:23 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''AVRS Merge Replication'',
		@enabled=1,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''No description available.'',
		@category_name=N''[Uncategorized (Local)]'',
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [AVRS Merge Replication]    Script Date: 14/06/2016 12:28:23 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''AVRS Merge Replication'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''if exists (select * from migrationAVRS  with (nolock) where id >= 100 and [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) begin
	declare @id int
	declare @publicationName varchar(max)

	select top 1 @id=id, @publicationName=[description] from migrationAVRS  with (nolock) where [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''') and id>= 100 order by id

	if @id > 100 begin
		declare @temp varchar(max)
		declare @jobName varchar(max)
		declare @tempId int
		set @tempId = @id -1

		select @temp = [description] from migrationAVRS  with (nolock) where id = @id-1

		if (select count(*)
			from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
			where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%'''' and runstatus = 2
			and publication = @temp
			) = 0
		begin
			set @id = @id - 1
		end

		if (select count(*)
			from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
			where b.publisher_db = ''''CCenterRia'''' and runstatus in (5,6) and publication = @temp
			) > 0
		begin
			set @id = @id + 1
		end

		if (select [dateStart] from migrationAVRS  with (nolock) where id = @tempId) <> convert(datetime ,''''jan 1 1900'''') begin
				if exists(select * from distribution..MSreplication_monitordata where publication = @temp and agent_type = 1and [status] = 0) begin

				select @jobName = agent_name from distribution..MSreplication_monitordata where publication = @temp and agent_type = 1 and [status] = 0

				create table #jobActivity(
				session_id int null,job_id uniqueidentifier null,
				job_name sysname null, run_requested_date datetime null,
				run_requested_source sysname null, queued_date datetime null,
				start_execution_date datetime null, last_executed_step_id int null,
				last_exectued_step_date datetime null, stop_execution_date datetime null,
				next_scheduled_run_date datetime null, job_history_id int null,
				[message] nvarchar(1024) null, run_status int null,
				operator_id_emailed int null, operator_id_netsent int null,
				operator_id_paged int null)

				insert into #jobActivity exec msdb.dbo.sp_help_jobactivity @job_name = @jobName

				if (select start_execution_date from #jobActivity) is null exec sp_startpublication_snapshot @publication = @temp

				drop table #jobActivity
			end
		end
	end
	if (select [dateStart] from migrationAVRS  with (nolock) where id = @id) = convert(datetime ,''''jan 1 1900'''')  begin
		begin transaction replications
		begin try
			update migrationAVRS with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id - 1 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
			update migrationAVRS with (rowlock) set [dateStart] = getdate() where id = @id
			exec sp_startpublication_snapshot @publication = @publicationName
			commit transaction replications
		end try
		begin catch
			ROLLBACK TRANSACTION replications;
			update migrationAVRS with (rowlock) set [dateStart] = getdate() where id = @id
			update migrationAVRS with (rowlock) set [error] = ERROR_MESSAGE() where id = @id
			update migrationAVRS with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id
		end catch
	end
end
if  exists (select * from migrationAVRS where id = 104 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) begin
	if exists(
	select * from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
		where b.publisher_db = ''''CCenterRia''''
		and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%''''
		and runstatus = 2 and publication = ''''AVRSSettings'''')
	begin
		update migrationAVRS with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 104 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')

	end
end
if not exists (select * from migrationAVRS where id = 104 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) begin
	EXEC msdb.dbo.sp_update_job @job_name=N''''AVRS Merge Replication'''',@enabled = 0
end'',
		@database_name=N''CCenterRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''replication'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=1,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20130625,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		EXEC(@sql)

		set @process = 'CREATE JOB -- CW (AutoStart),(Callback/abandoned update),(Campaign summary)'
		set @sql='USE [msdb]
/****** Object:  Job [CW (AutoStart),(allback/abandoned update),(Campaign summary)]    Script Date: 14/06/2016 01:11:22 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 14/06/2016 01:11:22 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW (AutoStart),(Callback/abandoned update),(Campaign summary)'',
		@enabled=1,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''Se funcioan los jobs CW AutoStart, CW Callback/abandoned update y CW Campaign summary'',
		@category_name=N''[Uncategorized (Local)]'',
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW AutoStart]    Script Date: 14/06/2016 01:11:22 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW AutoStart'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''exec ccsp_OutGenerateAutoinicio'',
		@database_name=N''CCenterRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Callback/abandoned update]    Script Date: 14/06/2016 01:11:22 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Callback/abandoned update'',
		@step_id=2,
		@cmdexec_success_code=0,
		@on_success_action=3,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''declare @callout_id_array varchar(max), @SQL varchar(max)
set @callout_id_array=''''|''''

select @callout_id_array=@callout_id_array+coalesce('''',''''+cast(callout_id as varchar(10)), @callout_id_array, '''''''')
from ccRIAUpdateCallBack_Abandon where minCallBackAbandonXpire < getdate()

if len(@callout_id_array)>1
 begin
	select @callout_id_array=replace(@callout_id_array, ''''|,'''', '''''''')

	set @SQL=''''delete ccoWorkingTable with(rowlock) where callout_id in (''''+@callout_id_array+'''')''''
	exec(@SQL)

	set @SQL=''''delete ccRIAUpdateCallBack_Abandon with(rowlock) where callout_id in (''''+@callout_id_array+'''')''''
	exec(@SQL)

	set @SQL=''''update ccoCallBacks with(rowlock) set [status] = 4, schedulerStatus = 1 where callout_id in (''''+@callout_id_array+'''') and [status] = 0''''
	exec(@SQL)
 end'',
		@database_name=N''CCenterRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Campaign summary]    Script Date: 14/06/2016 01:11:22 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Campaign summary'',
		@step_id=3,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''exec ccsp_RIAGetCampsNvosCB 0,2,0'',
		@database_name=N''CCenterRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CW Commons Tasj'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=30,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20151022,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		EXEC(@sql)

		set @process = 'CREATE JOB -- CW Merge Replication'
		set @sql='USE [msdb]
/****** Object:  Job [CW Merge Replication]    Script Date: 14/06/2016 12:34:55 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 14/06/2016 12:34:55 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Merge Replication'',
		@enabled=1,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''No description available.'',
		@category_name=N''[Uncategorized (Local)]'',
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Merge Replication]    Script Date: 14/06/2016 12:34:56 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Merge Replication'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''if (select count(*) from migration  with (nolock) where id >= 100 and [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) > 0
	begin
		declare @id int
		declare @publicationName varchar(max)

		select top 1 @id=id, @publicationName=[description] from migration  with (nolock) where [dateStart] = convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''') and id>= 100 order by id

		if @id > 100
			begin
				declare @temp varchar(max)
				declare @jobName varchar(max)
				declare @tempId int
				set @tempId = @id -1

				select @temp = [description] from migration  with (nolock) where id = @id-1

				if (select count(*)
				from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
				where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%'''' and runstatus = 2
				and publication = @temp) = 0
				begin
					set @id = @id - 1
				end

				if (select count(*)
				from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
				where b.publisher_db = ''''CCenterRia'''' and runstatus in (5,6)
				and publication = @temp) > 0
				begin
					set @id = @id + 1
				end

				if (select [dateStart] from migration  with (nolock) where id = @tempId) <> convert(datetime ,''''jan 1 1900'''')
				begin
					if exists(select *
							  from distribution..MSreplication_monitordata
							  where publication = @temp
							  and agent_type = 1
							  and [status] = 0)
						begin
							select @jobName = agent_name
							from distribution..MSreplication_monitordata
							where publication = @temp
							and agent_type = 1
							and [status] = 0

							create table #jobActivity(
							session_id int null,
							job_id uniqueidentifier null,
							job_name sysname null,
							run_requested_date datetime null,
							run_requested_source sysname null,
							queued_date datetime null,
							start_execution_date datetime null,
							last_executed_step_id int null,
							last_exectued_step_date datetime null,
							stop_execution_date datetime null,
							next_scheduled_run_date datetime null,
							job_history_id int null,
							[message] nvarchar(1024) null,
							run_status int null,
							operator_id_emailed int null,
							operator_id_netsent int null,
							operator_id_paged int null
							)

							insert into #jobActivity
								exec msdb.dbo.sp_help_jobactivity @job_name = @jobName

							if (select start_execution_date from #jobActivity) is null
								begin
									exec sp_startpublication_snapshot @publication = @temp
								end

							drop table #jobActivity
						end
				end
			end
		if (select [dateStart] from migration  with (nolock) where id = @id) = convert(datetime ,''''jan 1 1900'''')
		begin
			begin transaction replications
			begin try
				update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id - 1 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
				update migration with (rowlock) set [dateStart] = getdate() where id = @id
				exec sp_startpublication_snapshot @publication = @publicationName
				commit transaction replications
			end try
			begin catch
				ROLLBACK TRANSACTION replications;
				update migration with (rowlock) set [dateStart] = getdate() where id = @id
				update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = @id
				update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = @id
			end catch
		end
	end
	if exists (select * from migration where id = 115 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900''''))
			begin
				if (select count(*)
				from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
				where b.publisher_db = ''''CCenterRia''''
				and b.id = a.agent_id
				and comments like ''''%A snapshot of%%article(s) was generated.%''''
				and runstatus = 2
				and publication = ''''MenuReportsRia'''') = 1
				begin
					update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 115 and [dateEnd] = convert(datetime ,''''jan 1 1900'''')
					EXEC msdb.dbo.sp_update_job @job_name=N''''CW Merge Replication'''',@enabled = 0
				end
			end
if not exists (select * from migration where id = 115 and [dateStart] <> convert(datetime ,''''jan 1 1900'''') and [dateEnd] = convert(datetime ,''''jan 1 1900'''')) begin
	EXEC msdb.dbo.sp_update_job @job_name=N''''CW Merge Replication'''',@enabled = 0
end'',
		@database_name=N''CCenterRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''replication'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=1,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20130625,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		EXEC(@sql)

		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		-- exec ccsp_getVersion 'BD', @version
		-- exec ccsp_getVersion 'BDF', @versionFix

	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch

end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ''', version to release: ''' + cast(@version as varchar(5))
	end

set nocount off