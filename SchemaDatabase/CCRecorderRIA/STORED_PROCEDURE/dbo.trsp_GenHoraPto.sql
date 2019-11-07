/****** Object:  Stored Procedure dbo.trsp_GenHoraPto    Script Date: 07/10/2009 03:34:54 p.m. ******/




CREATE  PROCEDURE [dbo].[trsp_GenHoraPto] 
@from as smalldatetime,
@to as smalldatetime
AS

delete from trec_gen_hora_pto where timegroup between @from and @to

insert into trec_gen_hora_pto 
	select 
	CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121) as timegroup
	,puerto_id as puerto
	, count(*) as grabaciones
	, SUM(case when duracion<7 then 1 else 0 end) as shortcalls
	, sum(duracion) as duracion
	, (sum(duracion)/3600.0)*100 as promedio
	, sum(tamano) as tamano
from 
	trec_grabacion where finicio between @from and @to

group by 
	CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121),puerto_id
order by
	1