CREATE PROCEDURE [dbo].[ccsp_OUTGetAve_Camps] AS
declare @FInicio as smalldatetime
select @FInicio = dateadd(mi,-20, getdate())

select	A.cam_id, ((A.Abandon *100.0)/ A.Contesta) as AbanPorcentaje,
	((D.Contesta *100.0)/ D.Marcaciones) as AnswerPorcentaje, A.Abandon, A.Contesta, D.Marcaciones
from (
	select 
		cam_id,
		count(case statuscall_id when 6 then 1 else null end) as Abandon,
		count(*) as Contesta		
	from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
	where cal_Inicio > @FInicio
	group by cam_id
) A join 
(
	select cam_id,
		count(case tipoResDial_id when 1 then 1 else null end) as Contesta,
		count(*) as Marcaciones
	from ccoLogDials with(nolock index(IX_ccoLogDials))
	where fecha > @FInicio
	group by cam_id
) D on A.cam_id=D.cam_id