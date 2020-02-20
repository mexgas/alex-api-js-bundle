CREATE PROCEDURE [dbo].[ccsp_OUTGetAve_Camps] 
		@Tipo as tinyint=0,
		@Cam_ID as tinyint=0
		AS
		declare @FInicio as smalldatetime

		if @Tipo = 0 --para obtener la tabla de todo el día
		begin
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

		end
		if @Tipo = 1 --para obtener la tabla de todo el día
		begin
			select @FInicio = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
			select	A.cam_id, ((A.Abandon *100.0)/ A.Contesta) as AbandonRate,
			((D.Contesta *100.0)/ D.Marcaciones) as AnswerRate, A.Abandon, A.Contesta as Answer, D.Marcaciones as Calls
			from (
				select 
					cam_id,
					count(case statuscall_id when 6 then 1 else null end) as Abandon,
					count(*) as Contesta		
				from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
				where cal_Inicio > @FInicio
				and cam_id = @Cam_ID
				group by cam_id
			) A join 
			(
				select cam_id,
					count(case tipoResDial_id when 1 then 1 else null end) as Contesta,
					count(*) as Marcaciones
				from ccoLogDials with(nolock index(IX_ccoLogDials))
				where fecha > @FInicio
				and cam_id = @Cam_ID
				group by cam_id
			) D on A.cam_id=D.cam_id

		end