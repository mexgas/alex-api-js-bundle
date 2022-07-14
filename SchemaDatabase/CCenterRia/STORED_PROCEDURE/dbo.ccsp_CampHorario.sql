CREATE PROCEDURE [dbo].[ccsp_CampHorario]
@campId as int
AS

declare @horaUniversal datetime
declare @isShudulerLey bit, @valueShudulerLey varchar(max),@hourStart int,@hourEnd int,@minStart int,@minEnd int
declare @shourStart varchar(max),@shourEnd varchar(max),@timeMaxContestacion tinyint,@revHorario bit

set @timeMaxContestacion=30

select @revHorario=valor from ccsettings where setting_id = 112
select @valueShudulerLey = valor from ccsettings where setting_id=166
select @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex('|',@valueShudulerLey)) as int),@valueShudulerLey=substring(@valueShudulerLey, charindex('|',@valueShudulerLey) + 1, len(@valueShudulerLey))
select @timeMaxContestacion=cam_tNoContesta from cccamps where cam_id=@campId

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

select h.horario_id,Descripcion,
 case when HoraInicio>@hourStart then HoraInicio else @hourStart end HoraInicio,
 case when (horaInicio>@hourStart or (horaInicio=@hourStart and MinInicio>=@minStart) ) then MinInicio  else @minStart end MinInicio,
 case when horaFin<@hourEnd then horaFin else @hourEnd end HoraFin,
 case when ((horaFin < @hourEnd or (horaFin=@hourEnd and MinFin<=@minEnd) )) then MinFin  else @minEnd end MinFin,
 Lunes,Martes,Miercoles,Jueves,Viernes,Sabado,Domingo
 into #tempCampLaw
 from cchorarios h
 inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on h.horario_id = ccCampsHorarios.horario_id and ccCampsHorarios.cam_id = @campId
 --where  horaInicio between @hourStart and @hourEnd or horaFin between @hourStart and @hourEnd


select distinct horario_id,HoraInicio,MinInicio,horaFin,MinFin into #tempCampLaw2 from
(
 select tz_id,
 dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
 datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora,
 datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
 datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
 from ccTimeZones
)zonas
inner join #tempCampLaw on
(
 (
  hora > HoraInicio OR  (hora = HoraInicio AND minuto >= MinInicio)
 )
 AND
 (
  hora < HoraFin  OR  (hora = HoraFin AND minuto <= (MinFin-@timeMaxContestacion) )
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

select distinct #tempCampLaw2.horario_id id,
(HoraInicio*3600)+(MinInicio*60) ini,
(HoraFin*3600)+(MinFin*60) fin,
(case when HoraInicio<10 then '0'+convert(varchar(2),HoraInicio) else convert(varchar(2),HoraInicio) end) + ':' + (case when MinInicio<10 then '0'+convert(varchar(2),MinInicio) else convert(varchar(2),MinInicio) end ) as HoraInicio ,
(case when HoraFin<10 then '0'+convert(varchar(2),HoraFin) else convert(varchar(2),HoraFin) end) + ':' + (case when MinFin<10 then '0'+convert(varchar(2),MinFin) else convert(varchar(2),MinFin) end ) as HoraFin
into #tempCamp from #tempCampLaw2

select id,min(ini) ini,max(fin) fin,min(HoraInicio) HoraInicio,max(HoraFin) HoraFin,@timeMaxContestacion timeMaxContestacion
 from(
select distinct min(a.id) id,(a.ini) ini,(case when a.fin>b.fin then a.fin else b.fin end) fin,min(a.HoraInicio) HoraInicio,
max(case when a.fin>b.fin then a.HoraFin else b.HoraFin end) HoraFin
 from #tempCamp a, #tempCamp b
where a.fin>b.ini and b.ini between a.ini and a.fin and a.id <> b.id
group by a.ini,(case when a.fin>b.fin then a.fin else b.fin end)
union
select a.* from #tempCamp a
where a.id not in(select distinct b.id from #tempCamp a, #tempCamp b where a.fin>b.ini and b.ini between a.ini and a.fin and a.id <> b.id)
)x
group by id
order by ini



drop table #tempCamp
drop table #tempCampLaw
drop table #tempCampLaw2