CREATE PROCEDURE [dbo].[ccsp_RIAChatACDSchedule]
@Option     AS SMALLINT,
@Inbound_Id AS INT
AS
SET NOCOUNT ON
SET DATEFIRST 1

declare @today  datetime
declare @day    smallint
declare @hour   smallint
declare @minute smallint
declare @total  smallint

IF @Option = 1 -- Schedule
BEGIN

select @today =  getdate()
select @day = datepart(dw,@today), @hour = datepart(hh,@today), @minute = datepart(mi,@today)

if ( @day=1 )	--LUNES
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND LUNES = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
if @day=2	--MARTES
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND MARTES = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
if @day=3	--MIERCOLES
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND MIERCOLES = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
if @day=4	--JUEVES
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND JUEVES = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
if @day=5	--VIERNES
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND VIERNES = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
if @day=6	--SABADO
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND SABADO = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
if @day=7	--DOMINGO
begin
	select @total = count(*)
	from ccInbound I join ccInboundHorarios IH
	on I.Inbound_id = IH.Inbound_id
	join ccHorarios H on IH.horario_id = H.Horario_id
	Where I.Inbound_id = @inbound_id
	AND DOMINGO = 1
	AND ( @hour > HoraInicio OR ( @hour = HoraInicio AND @minute >= MinInicio ) )
	AND ( @hour < HoraFin OR ( @hour = HoraFin AND @minute <= MinFin ) )
end
select @total as 'ValidACDSchedules'
END

SET NOCOUNT OFF