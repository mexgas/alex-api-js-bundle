CREATE procedure [dbo].[ccsp_RIAGetSelectedNotReady]
@user_id int = 0,
@tipoNR int

AS

-- Para horarios depues de las 12 de la noche
declare @inicioTurno integer
declare @fecha smalldatetime
declare @fStart datetime
declare @fEnd datetime
declare @AcumTime int

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

select @AcumTime =isnull( sum(tStatus),0)  from ccRIALogAgentesNotReady where fecha between @fStart and @fEnd and tiponotready_id=@tipoNR and (user_id = @user_id)

select a1.tiponotready_id,descripcion, frame, time_acum, time_xev,  pas_sup, nextstatus, @AcumTime as AcumTime, 
dbo.NeventsNRdisp(@user_id, nextstatus, getdate())  as NeventsNRdisp
 from cctiponotready a1
inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
where a1.tiponotready_id=@tipoNR