/****** Object:  Stored Procedure dbo.trsp_GenAgenteExt    Script Date: 07/10/2009 03:34:54 p.m. ******/




CREATE         PROCEDURE [dbo].[trsp_GenAgenteExt] 
@from smalldatetime, 
@to smalldatetime
AS
DECLARE @query AS VARCHAR(1500)

DELETE FROM trec_gen_agente_ext WHERE timegroup BETWEEN @from AND @to

	INSERT into trec_gen_agente_ext
	select 
	CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121) as timegroup 
	, ISNULL(age_id,0)
	, ISNULL(extension, 'SIN EXTENSION') extension
	, ISNULL(grab.pos_pc, 'SIN POSICION') posicion
	, count(distinct grab.grab_id) as grabaciones 
	, SUM(case when duracion<7 then 1 else 0 end) as shortcalls 
	, sum(duracion) as duracion 
	, sum(tamano) as tamano 
	from trec_grabacion grab 
	where grab.finicio between @from and @to  
	group by age_id,CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121), extension,
	grab.pos_pc
	order by 1