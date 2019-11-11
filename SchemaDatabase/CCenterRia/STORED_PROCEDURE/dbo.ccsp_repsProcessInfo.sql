CREATE PROCEDURE ccsp_repsProcessInfo
@sFecha as varchar(11)
AS
declare @sFechaFin	varchar(11)
select @sFechaFin = convert(varchar(10), dateadd(dd, 1, @sfecha), 101)

exec ccspLogAgente @sFecha
exec ccspLogCalifDia @sFecha, @sFechaFin
exec ccspLogCalifHora @sFecha
exec ccspLogCamps @sFecha
exec ccspLogResultDia @sFecha, @sFechaFin
exec ccspLogResultHora @sFecha