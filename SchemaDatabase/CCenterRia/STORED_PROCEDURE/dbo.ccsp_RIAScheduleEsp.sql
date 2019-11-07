CREATE PROCEDURE [dbo].[ccsp_RIAScheduleEsp]
@Type smallint,
@Type2 smallint,
@IDArea smallint=0,
@CamEspID smallint,
@User_id smallint,
@InOut_Id smallint,
@InsertSchedule_id varchar(1000),
@DeleteSchedule_id varchar(1000)
AS
set nocount on

If @Type=1--get camps
 begin
	SELECT a1.cam_id, a1.cam_descripcion, a3.frame,CASE a1.CallsBySurvey WHEN 0 THEN 0 ELSE 1 END as 'CallsBySurvey'  FROM ccCamps a1
	inner join ccRIACampsGraph a2 on(a1.cam_id=a2.cam_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where isnull(IDArea, -1) = case
	when @IDArea = 0 then -1
	when (select login from ccusers where user_id = @User_id) = 'root' then isnull(IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

If @Type=2--get ACDGroups
 begin
	SELECT a1.Inbound_id, descripcion, a2.graphic_id, a3.frame,a1.chat mode from ccInbound a1
	inner join ccRIAInboundGraph a2 on(a1.Inbound_id=a2.Inbound_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where isnull(a1.IDArea, -1) = case when @IDArea=0 then -1
	when (select login from ccusers where user_id = @User_id) = 'root' then isnull(a1.IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

IF @Type=3--query
 begin
	If(@Type2=0)--ACDGroup
	 begin
		select c.inbound_id, c.descripcion as c_descripcion, ih.horario_id, h.descripcion as h_descripcion,
		cast(lunes as int)as lunes, cast(martes as int)as martes, cast(miercoles as int)as miercoles, cast(jueves as int)as jueves, cast(viernes as int)as viernes, cast(sabado as int)as sabado, cast(domingo as int)as domingo,
		dbo.RIAtimeFormat(horainicio)as horaInicio, dbo.RIAtimeFormat(mininicio)as minInicio, dbo.RIAtimeFormat(horafin)as horaFin, dbo.RIAtimeFormat(minfin)as minFin
		from ccInbound c left join ccInboundHorarios ih on c.inbound_id=ih.inbound_id
		inner join ccHorarios h on ih.horario_id=h.horario_id where status=1
		and c.inbound_id=@CamEspID--in(select cam_id from ccSupervisorCam where tipo=0 and user_id=@User_id and cam_id=@CamEspID)
		ORDER BY 4
		return(0)
	 end

	If(@Type2=1)--Camp
	 begin
	  	select c.cam_id, c.cam_descripcion as c_descripcion, ch.horario_id, h.descripcion as h_descripcion,
	 	cast(lunes as int)as lunes, cast(martes as int)as martes, cast(miercoles as int)as miercoles, cast(jueves as int)as jueves, cast(viernes as int)as viernes, cast(sabado as int)as sabado, cast(domingo as int)as domingo,
	 	dbo.RIAtimeFormat(horainicio)as horaInicio, dbo.RIAtimeFormat(mininicio)as minInicio, dbo.RIAtimeFormat(horafin)as horaFin, dbo.RIAtimeFormat(minfin)as minFin
	 	from ccCamps c left join ccCampsHorarios ch on c.cam_id=Ch.cam_id
	 	inner join ccHorarios h on ch.horario_id=h.horario_id
	 	where c.cam_id=@CamEspID--in(select cam_id from ccSupervisorCam where tipo=0 and user_id=@User_id and cam_id=@CamEspID)
		ORDER BY 4
		return(0)
	 end
 end

If @Type=4
 begin
	if exists(select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id)
	and (select login from ccUsers where user_id=@User_id)<>'root'
		select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	else
		select * from ccRIACAT_Areas where StatusArea=1 order by AreaName
	return(0)
 end

declare @sql as nvarchar(1000), @nIDArea as varchar(10)

if @Type=5--Insert Schedules
 begin
	If @Type2=3
	 begin
		If exists(select inbound_id from ccInboundHorarios where inbound_id=@CamEspID and horario_id=@InsertSchedule_id)
			select 2
		else
			insert ccInboundHorarios(inbound_id, horario_id) select @CamEspID, @InsertSchedule_id
		return(0)
	 end

	If @Type2=2
	 begin
		If exists(select cam_id from ccCampsHorarios where cam_id=@CamEspID and horario_id=@InsertSchedule_id)
			select 2
		else
			insert ccCampsHorarios(cam_id, horario_id) select top 1 @CamEspID, @InsertSchedule_id
		return(0)
	 end

	If @Type2<>1
		return(0)

	If @InOut_Id=0--ACD
	 begin
		If @IDArea=0
		 begin
			set @sql='insert ccInboundHorarios
			select distinct a.inbound_id, b.horario_id from ccInbound a, ccHorarios b where
			b.horario_id in('+@InsertSchedule_id+')
			and not exists(select c.inbound_id, e.horario_id from ccInboundHorarios c
			join ccHorarios e on e.horario_id=c.horario_id
			join ccInbound d on d.inbound_id=c.inbound_id and IDArea is null
			where c.inbound_id=a.inbound_id and b.horario_id=e.horario_id)
			and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea is null)'
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql='insert ccInboundHorarios select distinct a.inbound_id, b.horario_id
		from ccInbound a, ccHorarios b where b.horario_id in('+@InsertSchedule_id+')
		and not exists(select c.inbound_id, e.horario_id from ccInboundHorarios c
		join ccHorarios e on e.horario_id=c.horario_id
		join ccInbound d on d.inbound_id=c.inbound_id and IDArea='+@nIDArea+
		' where c.inbound_id=a.inbound_id and b.horario_id=e.horario_id)
		and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea='+@nIDArea+')'
		execute sp_executesql @sql
		return(0)
	 end

	If @InOut_Id=1--Camp
	 begin
		If @IDArea=0
		 begin
			set @sql='insert ccCampsHorarios
			select distinct a.cam_id, b.horario_id from ccCamps a, ccHorarios b where
			b.horario_id in('+@InsertSchedule_id+')
			and not exists(select c.cam_id, e.horario_id from ccCampsHorarios c
			join ccHorarios e on e.horario_id=c.horario_id
			join ccCamps d on d.cam_id=c.cam_id and IDArea is null
			where c.cam_id=a.cam_id and b.horario_id=e.horario_id)
			and a.cam_id in(select x.cam_id from ccCamps x where IDArea is null)'
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql='insert ccCampsHorarios select distinct a.cam_id, b.horario_id
		from ccCamps a, ccHorarios b where b.horario_id in('+@InsertSchedule_id+')
		and not exists(select c.cam_id, e.horario_id from ccCampsHorarios c
		join ccHorarios e on e.horario_id=c.horario_id
		join ccCamps d on d.cam_id=c.cam_id and IDArea='+@nIDArea+
		' where c.cam_id=a.cam_id and b.horario_id=e.horario_id)
		and a.cam_id in(select x.cam_id from ccCamps x where IDArea='+@nIDArea+')'
		execute sp_executesql @sql
		return(0)
	 end
 end

If @Type=6--Delete Schedules
 begin
	If @Type2=3
	 begin
		delete ccInboundHorarios where inbound_id=@CamEspID	and horario_id=@DeleteSchedule_id
		return(0)
	 end

	If @Type2=2
	 begin
		delete ccCampsHorarios where cam_id=@CamEspID and horario_id=@DeleteSchedule_id
		return(0)
	 end

	If @Type2<>1
		return(0)

	If @InOut_Id=0--ACD
	 begin
		If @IDArea=0
		 begin
			set @sql='delete ccInboundHorarios where inbound_id in(select inbound_id from
			ccInbound where IDArea is null) and Horario_id in('+@DeleteSchedule_id+')'
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql='delete ccInboundHorarios where inbound_id in(select inbound_id from
		ccInbound where IDArea='+@nIDArea+') and Horario_id in('+@DeleteSchedule_id+')'
		execute sp_executesql @sql
		return(0)
	 end

	If @InOut_Id=1--Camp
	 begin
		If @IDArea=0
		 begin
			set @sql='delete ccCampsHorarios
			where cam_id in(select cam_id from ccCamps where IDArea is null)
			and Horario_id in('+@DeleteSchedule_id+')'
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql='delete ccCampsHorarios
		where cam_id in(select cam_id from ccCamps where IDArea='+@nIDArea+')
		and Horario_id in('+@DeleteSchedule_id+')'
		execute sp_executesql @sql
		return(0)
	 end
 end

return(0)
set nocount off