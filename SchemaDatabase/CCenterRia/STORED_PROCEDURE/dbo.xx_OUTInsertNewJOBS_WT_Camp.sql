CREATE PROCEDURE [dbo].[xx_OUTInsertNewJOBS_WT_Camp]
@camp_id as int
AS
set nocount on
declare @prioridad varchar(8)
declare @space varchar(13)

set @space = '             '

Insert ccoWorkingTable ( callout_id, user_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano,
iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5  )
SELECT callout_id, user_id, cam_id, 
rtrim(left(ltrim(cal_telefono + @space
		  + cal_telefono2 + @space
		  + cal_telefono3 + @space
		  + cal_telefono4 + @space
		  + cal_telefono5 + @space),13)) as cal_telefono,
case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key, 
case when len( cal_telefono ) > 0 then iZonaHoraria else null end, case when len( cal_telefono ) > 0 then iZonaHoraria_verano else null end, 
case when len( cal_telefono2 ) > 0 then iZonaHoraria2 else null end, case when len( cal_telefono2 ) > 0 then iZonaHoraria_verano2 else null end, 
case when len( cal_telefono3 ) > 0 then iZonaHoraria3 else null end, case when len( cal_telefono3 ) > 0 then iZonaHoraria_verano3 else null end, 
case when len( cal_telefono4 ) > 0 then iZonaHoraria4 else null end, case when len( cal_telefono4 ) > 0 then iZonaHoraria_verano4 else null end, 
case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end
FROM ccoCallsOutSource with( index(IX_ccoCallsOutSource_11), nolock)
WHERE cam_id = @camp_id and (cal_status <2 or cal_status=7) -- Nuevos Jobs

--la prioridad establecidad (si existe) 
select @prioridad = NULL
select @prioridad = Prioridad from ccCampsPrioridadTel (nolock) where cam_id = @camp_id

UPDATE ccoCallsOutSource with(rowlock) SET cal_status = 3, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) and cam_id = @camp_id