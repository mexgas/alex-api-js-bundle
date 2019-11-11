CREATE PROCEDURE [dbo].[ccsp_AgentGetEspecialidadesActivas]
@userID INT,
@current integer = 0
as
declare @fecha datetime
declare @dia smallint
declare @hora smallint
declare @minuto smallint
declare @value int

SET DATEFIRST 1

select @fecha =  getdate()
select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)

set @value = 0
select @value = valor from ccSettings where setting_id = 191

if @value = 0
begin
select -8  as inbound_id, 'Survey' as name
	   union
	   select -1 as inbound_id, 'IVR' as name
	   union
	   select inbound_id as inbound_id, descripcion as name from ccInbound where inbound_id in
	   (
		  select inbound_id from ccInboundHorarios where horario_id in
		  (
			 select horario_id  from ccHorarios
			 where
			 ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
			 AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
			 AND (
				Lunes  = @dia or
				Martes *2 = @dia or
				Miercoles*3 = @dia or
				Jueves*4 = @dia or
				Viernes*5 = @dia or
				Sabado*6 = @dia or
				domingo*7 = @dia
			 )
		  )
	   )
	   and inbound_id <> @current
	   -- las activas
	   and status <> 0
	   -- las que tienen agentes firmados
	   -- and inbound_id  in ( select distinct inbound_id from ccInboundAgentes where user_id in ( select user_id from ccPosicion where user_id > 0 ))
	   order by 1
end

if @value = 1
begin
	   if (@current <> 0)
		  begin
			 select -1 as inbound_id, 'IVR' as name
			 union
			 select inbound_id as inbound_id, descripcion as name from ccInbound where inbound_id in
			 (
				select inbound_id from ccInboundHorarios where horario_id in
				(
					   select horario_id  from ccHorarios
					   where
					   ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
					   AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
					   AND (
						  Lunes  = @dia or
						  Martes *2 = @dia or
						  Miercoles*3 = @dia or
						  Jueves*4 = @dia or
						  Viernes*5 = @dia or
						  Sabado*6 = @dia or
						  domingo*7 = @dia
					   )
				)
			 )
			 and inbound_id <> @current
			 -- las activas
			 and status <> 0
			 and IDArea in (select cu.IDArea from ccUsers cu join ccInbound ci on cu.IDArea = ci.IDArea where inbound_id =  @current)
			 order by 2
		  end
	   else
		  begin
			 select -1 as inbound_id, 'IVR' as name
			 union
			 select inbound_id as inbound_id, descripcion as name from ccInbound where inbound_id in
			 (
				select inbound_id from ccInboundHorarios where horario_id in
				(
					   select horario_id  from ccHorarios
					   where
					   ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
					   AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
					   AND (
						  Lunes  = @dia or
						  Martes *2 = @dia or
						  Miercoles*3 = @dia or
						  Jueves*4 = @dia or
						  Viernes*5 = @dia or
						  Sabado*6 = @dia or
						  domingo*7 = @dia
					   )
				)
			 )
			 and inbound_id <> @current
			 -- las activas
			 and status <> 0
			 and IDArea in (
			 select IDArea from ccUsers where User_id = @userID
			 )
			 -- las que tienen agentes firmados
			 -- and inbound_id  in ( select distinct inbound_id from ccInboundAgentes where user_id in ( select user_id from ccPosicion where user_id > 0 ))
			 order by 2
		  end
end