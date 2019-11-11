CREATE PROCEDURE [dbo].[ccsp_OUTInsertNewJOBS_WT] 
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
	rtrim(left(ltrim( cal_telefono    + '        '
	+ cal_telefono2 + '         '
	+ cal_telefono3 + '         '
	+ cal_telefono4 + '         '
	+ cal_telefono5 + '         '),13)) as cal_telefono,
	case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key
	,case when len(cal_telefono)>0 then iZonaHoraria else null end, case when len(cal_telefono)>0 then iZonaHoraria_verano else null end
	,case when len(cal_telefono2)>0 then iZonaHoraria2 else null end, case when len(cal_telefono2)>0 then iZonaHoraria_verano2 else null end
	,case when len(cal_telefono3)>0 then iZonaHoraria3 else null end, case when len(cal_telefono3)>0 then iZonaHoraria_verano3 else null end
	,case when len(cal_telefono4)>0 then iZonaHoraria4 else null end, case when len(cal_telefono4)>0 then iZonaHoraria_verano4 else null end
	,case when len(cal_telefono5)>0 then iZonaHoraria5 else null end, case when len(cal_telefono5)>0 then iZonaHoraria_verano5 else null end
FROM ccoCallsOutSource
WHERE cal_status <2 or cal_status=7-- Nuevos Jobs

UPDATE ccoCallsOutSource SET cal_status = 2, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7)  --IN PROGRESS