CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositionRelations]
@command int,
@type tinyint = null, --0=In, 1=Out
@cam_id smallint = null,
@califIdLst varchar(8000) = null
AS
set nocount on
declare @sql as nvarchar(max)

If @command = 1
begin
	select 
		cast (0 as int) [type], 
		i.inbound_id as cam_id, 
		c.calif_id 
	from ccInbound i inner join ccCalifCamp c on i.inbound_id = c.cam_id and c.tipo = 0
	inner join ccTipoCalif t on c.calif_id = t.calif_id
	UNION
	select 
		cast (1 as int) [type], 
		o.cam_id, 
		c.calif_id 
	from ccCamps o inner join ccCalifCamp c on o.cam_id = c.cam_id and c.tipo = 1
	inner join ccTipoCalifOUT co on c.calif_id = co.calif_id
	order by [type], cam_id, calif_id
end
If @command=2  --Asignar calificacion(es) a una campaña de entrada o salida
 begin 
	if @Type=0 
	begin	
		set @sql = 'declare @NotAssigned table(NotAssigned int); 
		declare @Assigned table(Assigned int);

		insert into @NotAssigned (NotAssigned)
		select calif_id from ccTipoCalif where CanReprogram=1 and calif_id in (' + @califIdLst + ')
		and exists(select inbound_id from ccInbound where cam_id is null and Inbound_id= ' + cast(@cam_id as varchar(10)) + ')

		insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.inbound_id, 0 
		from ccInbound e, cctipoCalif f 
		where f.Calif_Status=1 and f.calif_id in (' + @califIdLst + ') and f.calif_id not in (select NotAssigned from @NotAssigned)
		and Inbound_id = ' + cast(@cam_id as varchar(10)) + '
		and not exists(
			select a.calif_id,c.inbound_id,0 from cctipoCalif a
			join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 0
			join ccInbound c on c.inbound_id = b.cam_id
			where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id
			and c.Inbound_id = ' + cast(@cam_id as varchar(10)) + ')

		insert into @Assigned (Assigned)
		select calif_id from ccTipoCalif where calif_id in (' + @califIdLst + ') and calif_id not in (select NotAssigned from @NotAssigned)

		declare @NotAssignedStr varchar(8000), @AssignedStr varchar(8000)
		SELECT @AssignedStr = COALESCE(@AssignedStr + '','', '''') + cast(Assigned as varchar(10)) from @Assigned
		select @NotAssignedStr = coalesce(@NotAssignedStr + '','', '''') + cast(NotAssigned as varchar(10)) from @NotAssigned

		select @AssignedStr [Assigned], @NotAssignedStr [NotAssigned]'
		execute sp_executesql @sql
	end
	else
	begin
		set @sql = 'insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalifOUT f where 
		f.CalifOut_Status=1 and f.calif_id in (' + @califIdLst + ') and cam_id = ' + cast(@cam_id as varchar(10)) + '
		and not exists(
		select a.calif_id,c.cam_id, 1 from cctipoCalifOUT a
		join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 1
		join ccCamps c on c.cam_id = b.cam_id
		where f.calif_id = a.calif_id and e.cam_id = c.cam_id
		and b.cam_id = ' + cast(@cam_id as varchar(10)) + ')'
		execute sp_executesql @sql
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id	
		return(0)
	end
 end
 If @command=3 -- Desasignar calificacion de campaña de entrada o salida
 begin
	delete ccCalifCamp where cam_id=@cam_id and tipo=@type and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
	if @type=0 and not exists(select C.calif_id from ccCalifCamp C join ccTipoCalif T on C.calif_id = T.calif_id and T.CanReprogram=1 and C.Tipo=0 and C.cam_id=@cam_id)
	begin
		update ccInbound set cam_id=null where Inbound_id=@cam_id
	end

	update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id
	return(0)
 end

set nocount off