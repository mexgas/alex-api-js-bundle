CREATE procedure [dbo].[ccsp_OUTcheckTimeZone]
@cam_id as int
AS
set nocount on
declare @horaUniversal datetime, @revHorario bit,@isShudulerLey bit
declare @valueShudulerLey varchar(max),@hourStart int,@hourEnd int,@minStart int,@minEnd int
declare @shourStart varchar(max),@shourEnd varchar(max)
declare @timeMaxContestacion int

set @timeMaxContestacion=60

select @revHorario=valor from ccsettings where setting_id = 112
select @valueShudulerLey = valor from ccsettings where setting_id=166
select @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex('|',@valueShudulerLey)) as int),@valueShudulerLey=substring(@valueShudulerLey, charindex('|',@valueShudulerLey) + 1, len(@valueShudulerLey))
select @timeMaxContestacion=(cam_tNoContesta*2) from cccamps where cam_id=@cam_id
set @timeMaxContestacion=CEILING(cast(@timeMaxContestacion as decimal(10,2)) / cast(60 as decimal(10,2)))
if @valueShudulerLey='' begin
      set @valueShudulerLey='0|07:00|22:00'
      update ccsettings set valor=@valueShudulerLey where setting_id=166
end
if @isShudulerLey = 1 begin
      select @shourStart=substring(@valueShudulerLey, 0, charindex('|',@valueShudulerLey)),@shourEnd=substring(@valueShudulerLey, charindex('|',@valueShudulerLey) + 1, len(@valueShudulerLey))
      select @hourStart=substring(@shourStart, 0, charindex(':',@shourStart)),@minStart=substring(@shourStart, charindex(':',@shourStart) + 1, len(@shourStart))
      select @hourEnd=substring(@shourEnd, 0, charindex(':',@shourEnd)),@minEnd=substring(@shourEnd, charindex(':',@shourEnd) + 1, len(@shourEnd))
end
else begin
      select @hourStart=0,@minStart=0,@hourEnd=23,@minEnd=59
end

SET DATEFIRST 1
set @horaUniversal = getutcdate()

-- Si la campaña no tiene horarios asignados, marcar todas las zonas
if @revHorario = 0
begin
      if not exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@cam_id)
            begin
                  select sum(distinct tz_id) from (
                  select tz_id,
                        dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
                        datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora,
                        datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
                        datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
                        from ccTimeZones
                  )zonas
                  where (hora > @hourStart or (hora = @hourStart and minuto >= @minStart) )and
                        ( hora < @hourEnd  or (hora = @hourEnd and minuto <= @minEnd) )
            return(0)
            end
end


select h.horario_id,Descripcion,
      case when HoraInicio>@hourStart then HoraInicio else @hourStart end HoraInicio,
      case when (horaInicio>@hourStart or (horaInicio=@hourStart and MinInicio>=@minStart) ) then MinInicio  else @minStart end MinInicio,
      case when horaFin<@hourEnd then horaFin else @hourEnd end HoraFin,
      case when ((horaFin < @hourEnd or (horaFin=@hourEnd and MinFin<=@minEnd) )) then MinFin  else @minEnd end MinFin,
      Lunes,Martes,Miercoles,Jueves,Viernes,Sabado,Domingo  
 into #tempCamp
 from cchorarios h
      inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on h.horario_id = ccCampsHorarios.horario_id and ccCampsHorarios.cam_id = @cam_id    


select isnull(sum( distinct tz_id),0) from
(
      select tz_id,
      dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
      datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora,
      datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
      datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
      from ccTimeZones
)zonas
inner join #tempCamp on
(
      (
            hora > HoraInicio OR  (hora = HoraInicio AND minuto >= MinInicio)
      )
      AND
      (
            hora < HoraFin    OR  (hora = HoraFin AND minuto <= (MinFin-@timeMaxContestacion) )
      )
      AND
      (
            Lunes  = dia or
            Martes *2 = dia or
            Miercoles*3 = dia or
            Jueves*4 = dia or
            Viernes*5 = dia or
            Sabado*6 = dia or
            domingo*7 = dia
      )

)
drop table #tempCamp