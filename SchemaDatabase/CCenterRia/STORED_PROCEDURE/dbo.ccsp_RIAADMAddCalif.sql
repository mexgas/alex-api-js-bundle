CREATE procedure [dbo].[ccsp_RIAADMAddCalif]
@calif_id varchar(8000) = null, --Id Calificacion
@Type tinyint = null, --0=In, 1=Out
@cam_id smallint = null, --Inbound_id, or cam_id, si es 0 la Agrega a Todos
@command tinyint,
@AreaId as smallint = null
AS
set nocount on	
declare @sql as nvarchar(2000)

If @command=1 -- Agrega Una calificacion a una campaña o especialidad
 begin 
 
	if not exists (select calif_id from ccCalifCamp where calif_id=@calif_id and cam_id=@cam_id and tipo=@Type) 
	begin 
		insert into ccCalifCamp(calif_id,cam_id,tipo) select @calif_id, @cam_id, @Type 		
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id					
	end	
	if  @Type=0 and exists (select calif_id from ccTipoCalif where CanReprogram=1 and calif_id=@calif_id) 
		and exists (select inbound_id from ccInbound where cam_id is null and Inbound_id=@cam_id) 
		and exists (select * from ccCalifCamp where tipo= @Type and cam_id= @cam_id and calif_id =@calif_id) 
	begin
		select -1 -- raiserror('Campaign unassigned for Reprogramation', 18, 1)
		return (0)
	end		
	select 1
	return (0)
 end

If @command=2 -- Agrega Una a calificacion a todas las campa?as o especialidades
 begin
	if @Type=0 -- InBound
	 begin	
		If @AreaId = 0
		 begin
			set @sql = 'insert into ccCalifCamp(calif_id,cam_id,tipo) 
			select f.calif_id, e.inbound_id, 0 from ccInbound e, cctipoCalif f where 
			f.Calif_Status=1 and f.calif_id in (' + @calif_id + ')
			and not exists(
			select a.calif_id,c.inbound_id,0 from cctipoCalif a
			join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 0
			join ccInbound c on c.inbound_id = b.cam_id and IDArea is null
			where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id)
			and IDArea is null' 

			set @sql = 'delete ccCalifCamp where cast(calif_id as varchar(100))+''&''+CAST(cam_id as varchar(100)) in 
			(select cast(C.calif_id as varchar(100))+''&''+CAST(C.cam_id as varchar(100))
			from ccCalifCamp C join ccInbound I on C.cam_id = I.inbound_ID
			join ccTipoCalif T on C.calif_id = T.calif_id
			where T.CanReprogram=1 and C.tipo=0 and I.cam_id is null and C.calif_id in (' + @calif_id + '))'
			execute sp_executesql @sql
		 end
		else
		 begin
			set @sql = 'insert into ccCalifCamp(calif_id,cam_id,tipo) 
			select f.calif_id, e.inbound_id, 0 from ccInbound e, cctipoCalif f where 
			f.Calif_Status=1 and f.calif_id in (' + @calif_id + ')
			and not exists(
			select a.calif_id,c.inbound_id,0 from cctipoCalif a
			join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 0
			join ccInbound c on c.inbound_id = b.cam_id and IDArea = ' + cast(@AreaId as varchar(10)) +
			'where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id)
			and IDArea = ' + cast(@AreaId as varchar(10)) 
			execute sp_executesql @sql
		end
		return(0)
	 end

	If @AreaId = 0
	 begin
		set @sql = 'insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalifOUT f where 
		f.CalifOut_Status=1 and f.calif_id in (' + @calif_id + ')
		and not exists(
		select a.calif_id,c.cam_id,1 from cctipoCalifOUT a
		join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 1
		join ccCamps c on c.cam_id = b.cam_id and IDArea is null 
		where f.calif_id = a.calif_id and e.cam_id = c.cam_id)
		and IDArea is null'
		execute sp_executesql @sql
	 end
	else
	 begin
		set @sql = 'insert into ccCalifCamp(calif_id,cam_id,tipo)  
		select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalifOUT f where 
		f.CalifOut_Status=1 and f.calif_id in (' + @calif_id + ')
		and not exists(select a.calif_id,c.cam_id,1 from cctipoCalifOUT a
		join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 1
		join ccCamps c on c.cam_id = b.cam_id and IDArea = ' + cast(@AreaId as varchar(10)) +
		'where f.calif_id = a.calif_id and e.cam_id = c.cam_id)
		and IDArea = ' + cast(@AreaId as varchar(10)) 
		execute sp_executesql @sql
	 end
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
 end

If @command=3 -- Verifica si de la opci?n uno se eliminaron todas sus calificaciones
 begin
	If exists(Select cam_id from ccCalifCamp where cam_id=@cam_id and tipo=@Type)
	 begin
		If @Type = 0
		 begin
			Update ccInbound set ShowCalifWnd = 1 where inbound_id = @cam_id
			return(0)
		 end

		Update ccCamps set cam_ShowCalifWnd = 1 where cam_id = @cam_id
	 end
	return(0)
 end

If @command=4 -- Verifica si de la opci?n dos se eliminaron todas sus calificaciones
 begin
	If @Type = 0
	 begin
		Update ccInbound set ShowCalifWnd = 0 where inbound_id not in (select A.inbound_id from ccInbound A
		left join ccCalifCamp B on A.inbound_id = B.cam_id and B.Tipo = 0
		group by A.inbound_id having count(B.cam_id)>0)
		and IDArea = @AreaId
		return(0)
	 end

	Update ccCamps set cam_ShowCalifWnd = 0 where cam_id not in (select A.cam_id from ccCamps A
	left join ccCalifCamp B on A.cam_id = B.cam_id and B.Tipo = 1
	group by A.cam_id having count(B.cam_id)>0)
	and IDArea = @AreaId
	return(0)
 end
set nocount off