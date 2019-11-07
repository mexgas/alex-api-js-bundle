CREATE PROCEDURE ccsp_OUTGetAve_InfoCalls_Camps
AS

declare @FInicio as smalldatetime

select @FInicio = dateadd(mi,-20, getdate())

select	A.cam_id, ((A.Abandon *100)/ A.Contestan) as AbanPorcentaje,
	((L.Contestan *100)/ L.Marcaciones) as AnswerPorcentaje,
	A.Abandon, A.Contestan, L.Marcaciones,
	L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService,
	((L.Contestan*100)/ L.Marcaciones) as pContesta,
	((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
	((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
	((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
	((L.NoService*100)/ L.Marcaciones) as pNoService
from (
	select 
		cam_id,
		count(case statuscall_id when 6 then 1 else null end) as Abandon,
		count(*) as Contestan		
	from ccoCallsOut
	where cal_Inicio > @FInicio
	group by cam_id
) A join 
(
	select cam_id,
		count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
		count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
		count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
		count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
		count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		count(*) as Marcaciones
	from ccoLogDials
	where fecha > @FInicio
	group by cam_id
) L on A.cam_id=L.cam_id