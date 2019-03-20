/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2018/04/19
Description:



Database: CCenterRia
Required version: 119.119.131

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

set @version = 119--**********actualizar a 119 sin fix
set @versionfix = 133
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 132
	begin
		begin tran
		begin try

		set @process = 'CW-1726 Version 119.124 -- alter SP ccsp_AGENTInsertCallOut'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_AGENTInsertCallOut]
@cam_id smallint,
@cal_Key varchar(20),
@cal_Telefono varchar(30),
@user_id int,
@cal_extension varchar(7),
@sData varchar(255) = '''', --HLAS para guardar notas de la llamada
@existCallOut as int = 0,
@callmode as smallint = 0
AS
set 
nocount on
declare @fecha as datetime, @callout_id as int, @cal_id as int, @calloutMaxTime as int
select @fecha=getdate()

if @callmode = 1 begin
	INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
	select @existCallOut, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 0, @cal_extension
	select @cal_id = scope_identity()

	insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
	select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
	from ccRIACampEspWG wg 
	where wg.tipo = 1 and wg.idcampesp =@cam_id

	select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
	select @existCallOut as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
  return(0)
end

if @existCallOut=0  begin
	declare @LasCallKey varchar(20)
	set @LasCallKey = @cal_Key
	declare @settingCallKey as int
	select @settingCallKey = valor from ccSettings where setting_id = 194
  
	if(@settingCallKey = 1) begin
		if (@cal_Key='''' or @cal_Key is null) begin   
			select top 1 @LasCallKey=cal_Key from ccoCallsOut where cam_id=@cam_id and cal_Inicio>=convert(datetime,getdate()) and cal_manual=0 order by cal_id desc
			set @cal_Key= @LasCallKey
		end
	end

	INSERT ccocallsoutsource (cal_key, cam_id, cal_telefono, cal_status, user_id, cal_fechaDial, dato1)
	select @cal_Key, @cam_id, substring(@cal_Telefono, 1, 19), 6, @user_id, @fecha, @sData
	select @callout_id = scope_identity()

	INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
	select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension
	select @cal_id = scope_identity()

	
 end

else begin --@existCallOut<>0
	Update ccocallsoutsource set cam_id=@cam_id, cal_telefono=substring(@cal_Telefono, 1, 19), dato1=@sData where callout_id = @existCallOut	
	Update ccocallsout set cam_id=@cam_id, cal_telefono=@cal_Telefono where callout_id = @existCallOut
	
	set @callout_id = @existCallOut

	select top 1 @cal_id=cal_id from ccocallsout where callout_id = @callout_id order by cal_id desc
	
	if exists(select * from ccoLogDials where cal_id=@cal_id) begin
		INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
		select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension
		select @cal_id = scope_identity()
	end
	 
 end
	
insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
from dbo.ccRIACampEspWG wg 
where wg.tipo = 1 and wg.idcampesp =@cam_id


select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
select @callout_id as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
return(0)
set nocount off'
    	EXEC(@Sql)

    	set @process = 'CW-1727 version 119.124 -- Alter SP ccsp_INInsertaCallBack'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_INInsertaCallBack]
@cal_key varchar(20) ='''',
@cam_id smallint,
@cal_telefono varchar(19),
@fechadial varchar(17),
@dato1 varchar(255),
@dato2 varchar(255),
@dato3 varchar(255),
@dato4 varchar(255),
@dato5 varchar(255),
@TelReprograma smallint = -1,
@user_id int=0,
@isAuto bit=0
AS
set nocount on
declare @TelOriginal as varchar(15)
declare @FechaOriginal as datetime

if len(@cal_telefono)<=3
	return(0)

if isnull(@cal_key,'''') = ''''
 begin
      -- Generamos cal_key aleatorio para casos de reprogramacion inbound --
      Genera_cal_key:
      select @cal_key = right(newID(), 10)
      if exists (select cal_key from ccoCallsOutSource where cal_key=@cal_key)
            goto Genera_cal_key
 end

declare @bIsDaylight as bit
declare @idioma as int
declare @country_id as varchar(3)

select @country_id = valor from ccsettings where setting_id = 104

select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

declare @difference as int
declare @Fecha smalldatetime, @callout_id int, @iZonaHoraria int,@iZonaHoraria_verano int, @cal_statusTemp tinyint
declare @iZonaHoraria2 int,@iZonaHoraria_verano2 int
declare @iZonaHoraria3 int,@iZonaHoraria_verano3 int
declare @iZonaHoraria4 int,@iZonaHoraria_verano4 int
declare @iZonaHoraria5 int,@iZonaHoraria_verano5 int
if @isAuto=0
	select @difference = isNull(dbo.fnGetTimeDifference(dbo.fnGetTimeZone(@cal_telefono,@bIsDaylight)),0)
else
	set @difference = 0
select @Fecha= dateadd(hh,@difference,convert(datetime,@FechaDial,101))

if exists(select cal_Key, cam_id from ccoCallsOutSource where cal_Key = @cal_key and cam_id =@cam_id)
 begin
	select @callout_id=callout_id,@cal_statusTemp =cal_status,
	@iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end,@iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end, 
	@iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end,@iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end, 
	@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end,@iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end, 
	@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end,@iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end, 
	@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end,@iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end, 
	@TelOriginal = cal_telefono, @FechaOriginal = cal_fechadial from ccoCallsOutSource 
	where cal_Key = @cal_key and cam_id = @cam_id

	update ccoCallsOutSource set cal_status = ''2'',cal_telefono=@cal_telefono where cal_key = @cal_key and cam_id = @cam_id

	if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
	else
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw
		,iZonaHoraria,iZonaHoraria_verano
		,iZonaHoraria2,iZonaHoraria_verano2
		,iZonaHoraria3,iZonaHoraria_verano3
		,iZonaHoraria4,iZonaHoraria_verano4
		,iZonaHoraria5,iZonaHoraria_verano5)
		select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key
		,@iZonaHoraria,@iZonaHoraria_verano
		,@iZonaHoraria2,@iZonaHoraria_verano2
		,@iZonaHoraria3,@iZonaHoraria_verano3
		,@iZonaHoraria4,@iZonaHoraria_verano4
		,@iZonaHoraria5,@iZonaHoraria_verano5

		if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
			begin
				insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
				values (@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
			end
		else
			begin
				update ccoCallBacks
				set user_id = @user_id, cam_id = @cam_id, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @cal_telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
				where callout_id = @callout_id
			end
  end

else
 begin
	select @FechaOriginal = getdate()

	insert into ccoCallsOutSource (cal_key,cam_id,cal_telefono,cal_fechadial,Dato1,Dato2,Dato3,Dato4,Dato5,dial_tels,cal_status)
	values (@cal_key,@cam_id,@cal_telefono,@FechaOriginal,@dato1,@dato2,@dato3,@dato4,@dato5,cast(@TelReprograma as char(1))+ replace(''2345NNN'',cast(@TelReprograma as char(1)),''1''),''2'')

	select @TelOriginal = @cal_telefono

	select @callout_id = scope_identity()
	select @iZonaHoraria=iZonaHoraria,@iZonaHoraria_verano=iZonaHoraria_verano from ccocallsoutsource where callout_id=@callout_id

	select @callout_id=callout_id,
	@iZonaHoraria=case when len(cal_telefono)>0 then iZonaHoraria else null end,@iZonaHoraria_verano=case when len(cal_telefono)>0 then iZonaHoraria_verano else null end, 
	@iZonaHoraria2=case when len(cal_telefono2)>0 then iZonaHoraria2 else null end,@iZonaHoraria_verano2=case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end, 
	@iZonaHoraria3=case when len(cal_telefono3)>0 then iZonaHoraria3 else null end,@iZonaHoraria_verano3=case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end, 
	@iZonaHoraria4=case when len(cal_telefono4)>0 then iZonaHoraria4 else null end,@iZonaHoraria_verano4=case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end, 
	@iZonaHoraria5=case when len(cal_telefono5)>0 then iZonaHoraria5 else null end,@iZonaHoraria_verano5=case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end
	from ccoCallsOutSource 
	where callout_id=@callout_id


	 if exists(select callout_id from ccoWorkingTable where callout_id=@callout_id)
		UPDATE ccoWorkingTable SET cal_telefono=@cal_telefono,cam_id=@cam_id,cal_fechaDial=@Fecha,cal_status=1,nTryingContact=3,prioridad_cb=1,[user_id]=@user_id,cal_keyw=@cal_key WHERE callout_id=@callout_id
	 else
		INSERT ccoWorkingTable(callout_id,cal_telefono,cam_id,cal_fechaDial,cal_status,nTryingContact,prioridad_cb,[user_id],cal_keyw
		,iZonaHoraria,iZonaHoraria_verano
		,iZonaHoraria2,iZonaHoraria_verano2
		,iZonaHoraria3,iZonaHoraria_verano3
		,iZonaHoraria4,iZonaHoraria_verano4
		,iZonaHoraria5,iZonaHoraria_verano5)
		select @callout_id,@cal_telefono,@cam_id,@Fecha,1,3,1,@user_id,@cal_key
		,@iZonaHoraria,@iZonaHoraria_verano
		,@iZonaHoraria2,@iZonaHoraria_verano2
		,@iZonaHoraria3,@iZonaHoraria_verano3
		,@iZonaHoraria4,@iZonaHoraria_verano4
		,@iZonaHoraria5,@iZonaHoraria_verano5

		if not exists (select callout_id from ccoCallBacks with(nolock) where callout_id = @callout_id)
			begin
				insert into ccoCallBacks (callout_id, user_id, cam_id, cal_key, cal_telefono, cal_telCB, cal_fecha, cal_fusercallback, cal_fcallback, status, schedulerStatus)
				values (@callout_id,@user_id,@cam_id,@cal_key,@TelOriginal,@cal_telefono,@FechaOriginal,@Fecha,NULL,0,1)
			end
		else
			begin
				update ccoCallBacks
				set user_id = @user_id, cam_id = @cam_id, cal_key = @cal_key, cal_telefono = @TelOriginal, cal_telCB = @cal_telefono, cal_fecha = @FechaOriginal, cal_fusercallback = @Fecha, cal_fcallback = NULL, status = 0, schedulerStatus = 1
				where callout_id = @callout_id
			end
end

if exists(select callbacks from ccRIAcallbacks where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id)
	update ccRIAcallbacks set callbacks=callbacks+1 where año=year(@Fecha)and mes=month(@Fecha)and dia=day(@Fecha)and hora=datepart(hh,@Fecha)and cam_id=@cam_id
else
	insert ccRIAcallbacks select year(@Fecha),month(@Fecha),day(@Fecha),datepart(hh,@Fecha),''1'',@cam_id

return(0)
set nocount off'
    	EXEC(@Sql)

    	set @process = 'CW-1727 version 119.124 -- -- Alter SP ccsp_OUTInsertNewJOBS_WT'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_OUTInsertNewJOBS_WT] 
AS
-- Para Traer los Datos de ccoCallsOutSource a  WorkingTable
-- ccoCallsOutSource ========> ccoWorkingTABLE
declare @callout_id int
declare @cam_id int
declare @cal_telefono varchar(20)
declare @cal_telefono2 varchar(20)
declare @cal_telefono3 varchar(20)
declare @cal_status int
declare @cal_fechaDial smalldatetime
declare @dato3 varchar(20)
declare @dato4 varchar(20)

Update ccoCallsOutSource set cal_status = 3 where callout_id in (select callout_id from ccoWorkingTable) --HLAS 2004/07/09 Mas rapido aqui que adentro
Update ccoCallsOutSource set cal_status = 4 where cal_key in 
	(select cal_key from ccoWorkingTable wt inner join ccoCallsOutSource cs on cs.callout_id = wt.callout_id and wt.cal_status in (0, 1, 2) )

Insert ccoWorkingTable (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw
	,iZonaHoraria,iZonaHoraria_verano
	,iZonaHoraria2,iZonaHoraria_verano2
	,iZonaHoraria3,iZonaHoraria_verano3
	,iZonaHoraria4,iZonaHoraria_verano4
	,iZonaHoraria5,iZonaHoraria_verano5)
SELECT callout_id, cam_id,
	rtrim(left(ltrim( cal_telefono    + ''        ''
	+ cal_telefono2 + ''         ''
	+ cal_telefono3 + ''         ''
	+ cal_telefono4 + ''         ''
	+ cal_telefono5 + ''         ''),13)) as cal_telefono,
	case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key
	,case when len(cal_telefono)>0 then iZonaHoraria else null end, case when len(cal_telefono)>0 then iZonaHoraria_verano else null end
	,case when len(cal_telefono2)>0 then iZonaHoraria2 else null end, case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end
	,case when len(cal_telefono3)>0 then iZonaHoraria3 else null end, case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end
	,case when len(cal_telefono4)>0 then iZonaHoraria4 else null end, case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end
	,case when len(cal_telefono5)>0 then iZonaHoraria5 else null end, case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end
FROM ccoCallsOutSource
WHERE cal_status <2 or cal_status=7-- Nuevos Jobs

UPDATE ccoCallsOutSource SET cal_status = 2, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7)  --IN PROGRESS'
    	EXEC(@Sql)

    	set @process = 'CW-1727 version 119.124 -- Alter SP ccsp_OUTInsertNewJOBS_WT_Camp'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_OUTInsertNewJOBS_WT_Camp]
@camp_id as int,
@reciclar as int = 1
AS
set nocount on
declare @callout_id int
declare @cam_id int
declare @cal_telefono varchar(20)
declare @cal_telefono2 varchar(20)
declare @cal_telefono3 varchar(20)
declare @cal_status int
declare @cal_fechaGNP smalldatetime
declare @cal_fechaDial smalldatetime
declare @dato3 varchar(20)
declare @dato4 varchar(20)
declare @prioridad varchar(8)

declare @dbname varchar(50)
select @dbname = c.name from sys.sysaltfiles a join sys.database_files c
 on a.filename = c.physical_name collate SQL_Latin1_General_CP1_CI_AS
 join master..sysprocesses d on a.dbid = d.dbid where d.spid=@@SPID and c.type=0

-- BORRAR LAS CUENTA QUE YA NO VIENEN 
--dejar en wt las que ya existen antes de subir y borrar las demas
if @reciclar = 1 and 1 = 0
 begin
	--Version HLAS 20041016
	update ccoWorkingTable set cal_Status = cal_Status + 22 
	from ccoWorkingTable wt left join ccUploadTemporal ut
	on wt.cal_keyw = ut.cal_key 
	where wt.cam_id = ut.cam_id and
	wt.cam_id = @camp_id
	and ut.cal_key is null
	and cal_status < 2

	insert into ccBorrardasReciclaje ( callout_id, cal_key, cal_status, cam_id)
	select callout_id, cal_keyw, cal_status - 22, cam_id from
	ccoWorkingTable where cam_id=@camp_id
	and cal_status in (22,23)

	delete ccoWorkingTable where cam_id=@camp_id
	and cal_status in (22,23)
 end

Delete ccUploadTemporal where cam_id = @camp_id

-- DEJAR LAS CUENTAS CON CALLBACK COMO ESTAN 
update ccoCallsOutSource set cal_Status = 4
from ccoCallsOutSource cs inner join ccoWorkingTable wt 
on cs.cal_key = wt.cal_keyw and cs.cam_id = wt.cam_id
where cs.cam_id = @camp_id
and wt.cal_status <= 2
and cs.cal_status in(0,7)

Insert ccoWorkingTable ( callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw
	,iZonaHoraria,iZonaHoraria_verano
	,iZonaHoraria2,iZonaHoraria_verano2
	,iZonaHoraria3,iZonaHoraria_verano3
	,iZonaHoraria4,iZonaHoraria_verano4
	,iZonaHoraria5,iZonaHoraria_verano5)
SELECT callout_id, cam_id, 
	rtrim(left(ltrim(cal_telefono    + ''        ''
	+ cal_telefono2 + ''         ''
	+ cal_telefono3 + ''         ''
	+ cal_telefono4 + ''         ''
	+ cal_telefono5 + ''         ''),13)) as cal_telefono,
	case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key
	,case when len(cal_telefono)>0 then iZonaHoraria else null end, case when len(cal_telefono)>0 then iZonaHoraria_verano else null end
	,case when len(cal_telefono2)>0 then iZonaHoraria2 else null end, case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end
	,case when len(cal_telefono3)>0 then iZonaHoraria3 else null end, case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end
	,case when len(cal_telefono4)>0 then iZonaHoraria4 else null end, case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end
	,case when len(cal_telefono5)>0 then iZonaHoraria5 else null end, case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end
FROM ccoCallsOutSource
WHERE cam_id = @camp_id and (cal_status <2 or cal_status=7) -- Nuevos Jobs

--la prioridad establecidad (si existe) 
select @prioridad = NULL
select @prioridad = Prioridad from ccCampsPrioridadTel where cam_id = @camp_id

if @prioridad is null set @prioridad=''12345NNN''

UPDATE ccoCallsOutSource SET cal_status = 2, dial_tels =  @prioridad, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) and cam_id = @camp_id
set nocount off'
    	EXEC(@Sql)

		
		set @process = 'Cambios lenguaje'
		set @Sql= 'update ccRIALog_Module set descripcion=''RECORDING SERVER|RECORDING SERVER'' where module_id=59
					update ccRIALog_Module set descripcion=''RECORDINGS MANAGER|RECORDINGS MANAGER'' where module_id=57
					update ccRIALog_Operation set descripcion=''ADJUNTAR EN EMAIL|EMAIL FILE''where operationType=172'
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
