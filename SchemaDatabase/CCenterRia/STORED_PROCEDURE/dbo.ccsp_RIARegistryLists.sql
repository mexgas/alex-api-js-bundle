CREATE Procedure [dbo].[ccsp_RIARegistryLists]
@action tinyint = 0, 
@list_id int = 0,
@cam_id smallint = 0,
@name varchar(80) = '',
@status tinyint = 0,
@sequence smallint = 0
AS

--Status lista 0: inactiva, 1:pausa, 2:procesar

--Insert
IF @action = 1 begin

	IF @cam_id <> 0 begin
		select @sequence = isnull(max( sequence ),0) from ccRIARegistryLists where cam_id = @cam_id
		set @sequence = @sequence + 1
		Insert into ccRIARegistryLists(cam_id,name,status,sequence) values (@cam_id, @name, 2, @sequence)
		select max(list_id) from ccRIARegistryLists
	end
end

--Update sequence
IF @action = 2 begin
	
	declare @oldSeq as int
	select @oldSeq = sequence, @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id

	if @oldSeq <> @sequence begin
		
		if @oldSeq > @sequence begin
			update ccRIARegistryLists set sequence = sequence + 1 where cam_id = @cam_id and sequence >= @sequence and sequence < @oldSeq
		end

		if @oldSeq < @sequence begin
			update ccRIARegistryLists set sequence = sequence - 1 where cam_id = @cam_id and sequence <= @sequence and sequence > @oldSeq
		end

		update ccRIARegistryLists set sequence = @sequence where list_id = @list_id

	end

end

--Change status
IF @action = 3 begin
	
	update ccRIARegistryLists set status = @status where list_id = @list_id

end

-- lista campañas y listas de registros
IF @action = 4 begin
	select a.cam_id, b.cam_descripcion, count(list_id) as NoListas, c.graphic_id as Frame from ccRIARegistryLists a 
	left join cccamps b on a.cam_id = b.cam_id
	left join ccRIACampsGraph c on a.cam_id = c.cam_id
	where b.cam_activo = 1 and a.cam_id in ( select distinct(cam_id) from ccRIARegistryLists ) 
	group by a.cam_id,b.cam_descripcion,c.graphic_id order by a.cam_id asc

end

-- listas de registros y no. registros
IF @action = 5 
begin
	select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence   
	from ccRIARegistryLists a with(index(IX_ccRIARegistryLists_1),nolock) 
	left join ccocallsoutsource b with(index(IX_ccoCallsOutSource_13),nolock) 
	on b.cam_id = @cam_id and a.list_id = b.list_id 
	where a.status > 0 and a.cam_id = @cam_id and status > 0 
	group by a.list_id,a.name,a.sequence 
	order by a.sequence
end

-- borrar lista
IF @action = 6 begin

	select @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id
	select @sequence = max(sequence) from ccRIARegistryLists where cam_id = @cam_id
	exec ccsp_RIARegistryLists @action = 3, @status = 0, @list_id = @list_id
	exec ccsp_RIARegistryLists @action = 2, @sequence = @sequence, @list_id = @list_id

end

-- Detalle de numero de registros
IF @action = 7 begin

	declare @total as int

	select @total = count(*) from ccocallsoutsource where list_id = @list_id
	select @total = (@total - count(*)) from ccoworkingtable where list_id = @list_id

	if exists(select list_id from ccoWorkingTable where list_id = @list_id) begin
		select @status = status from ccRIARegistryLists where list_id = @list_id
		select @list_id as list_id,cam_id, @status as status,
			count(case cal_status when 0 then 1 else null end) as New,
			count(case cal_status when 1 then 1 else null end) as CB,
			count(case cal_status when 2 then 1 else null end) as Pro, 
			@total as Fin
		from ccoWorkingTable where list_id = @list_id group by cam_id
	end
	ELSE begin
		select list_id, cam_id, status, 
		0 as New,
		0 as CB,
		0 as Pro,
		0 as Fin
		from ccRIARegistryLists where list_id = @list_id
	end


end

-- Cambia de nombre a la lista
IF @action = 8 begin
	
	update ccRIARegistryLists set name = @name where list_id = @list_id

end

-- Borra listas sin registros y reordena las listas
IF @action = 9 begin

	Create table #TempRegs(
		list_id int,
		[name] varchar(100),
		NoRegistros int,
		sequence int)

	insert into #TempRegs 
		select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence 
		from ccRIARegistryLists a with(index(IX_ccRIARegistryLists_1),nolock)
		left join ccocallsoutsource b with(index(IX_ccoCallsOutSource_14),nolock)
		on a.list_id = b.list_id
		where a.status > 0 and a.cam_id = @cam_id and status > 0 
		group by a.list_id,a.name,a.sequence,a.status order by a.sequence

	while ( exists( select list_id from #TempRegs where NoRegistros = 0 ) ) begin
		declare @listToDelete as int
		select top 1 @listToDelete = list_id from #TempRegs where NoRegistros = 0
		exec ccsp_RIARegistryLists @action = 6, @list_id = @listToDelete
		delete from #TempRegs where list_id =  @listToDelete
	end

	drop table #TempRegs
	
	select @sequence=min(sequence) from ccRIARegistryLists where  cam_id = @cam_id and status = 0 

	select @list_id= list_id from ccRIARegistryLists where sequence =(
	select  max(sequence) as sequence from ccRIARegistryLists where  cam_id = @cam_id and status > 0 ) and cam_id = @cam_id

	exec ccsp_RIARegistryLists @action=2,@list_id=@list_id,@sequence=@sequence

end