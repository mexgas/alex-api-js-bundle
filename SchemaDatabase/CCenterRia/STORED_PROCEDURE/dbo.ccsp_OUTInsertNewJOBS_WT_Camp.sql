CREATE PROCEDURE [dbo].[ccsp_OUTInsertNewJOBS_WT_Camp]
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
declare @space varchar(13)

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

set @space = '             '

Insert ccoWorkingTable ( callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw
	,iZonaHoraria,iZonaHoraria_verano
	,iZonaHoraria2,iZonaHoraria_verano2
	,iZonaHoraria3,iZonaHoraria_verano3
	,iZonaHoraria4,iZonaHoraria_verano4
	,iZonaHoraria5,iZonaHoraria_verano5)
SELECT callout_id, cam_id, 
	rtrim(left(ltrim(cal_telefono    +@space
	+ cal_telefono2 + @space
	+ cal_telefono3 + @space
	+ cal_telefono4 + @space
	+ cal_telefono5 + @space),13)) as cal_telefono,
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

if @prioridad is null set @prioridad='12345NNN'

UPDATE ccoCallsOutSource SET cal_status = 2, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) and cam_id = @camp_id
set nocount off