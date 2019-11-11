CREATE procedure [dbo].[ccsp_RIAGetNotReadyTimes]
@user_id int = 0
AS
-- Para horarios depues de las 12 de la noche
declare @inicioTurno integer

declare @fecha smalldatetime
declare @fStart datetime
declare @fEnd datetime

set @inicioTurno = 2 --Cambio de dia a las 2 de la mañana
set @fecha = getdate()
if datepart( hh,  @fecha ) > @inicioTurno - 1
begin	
	set @fStart = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +':00', 121)
	set  @fEnd = dateadd( d,1, @fstart )
end
else
begin
	set @fEnd = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +':00', 121)
	set  @fStart = dateadd( d,-1, @fEnd )
end

print(@fEnd)
print(@fStart)

select sum(tStatus) as total
from ccRIALogAgentesNotReady l inner join ccTipoNotReady t
on l.tiponotready_id = t.tiponotready_id
where fecha between @fStart and @fEnd
and (user_id = @user_id or @user_id = 0)
group by t.descripcion