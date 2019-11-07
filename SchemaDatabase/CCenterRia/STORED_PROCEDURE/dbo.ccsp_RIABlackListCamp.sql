CREATE PROCEDURE dbo.ccsp_RIABlackListCamp
@Type smallint,
@IDArea smallint = 0,
@CamID SmallInt = 0,
@InsertSchedule_id varchar(max) = '0',
@DeleteSchedule_id varchar(max) = '0',
@User_id int = null
as
set nocount on

if @Type = 1 -- Cat_BList
 begin
	Select idtipolista as ID, tipolista as TIPO from cctiposlistanegra where Status= 1 order by 2
	return(0)
 end

if @Type = 2 -- Cat_Camps
 begin
	Select c.cam_id as ID, c.cam_descripcion TIPO
	from ccCamps c join ccRIACat_Areas a on c.IDArea = a.IDArea
	where c.cam_id in (select cam_id from dbo.fGet_CampAcd_Area(@User_id, 1))
	order by 2
	return(0)
 end

if @Type = 3 -- Relacion Camps vs BList
 begin
	select cl.cam_id, ca.cam_descripcion, cl.idtipolista blist_id, tl.Tipolista list_description
	from Camplistanegra cl join ccCamps ca on cl.cam_id = ca.cam_id
	 join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
	where cl.status = 1 and cl.cam_id = @CamID
	order by 1, 3
	return(0)
 end

if @Type = 4 -- Inserta BList
 begin

	if @CamID = 0
	 begin
		update Camplistanegra set status = 1 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ','))

		insert into Camplistanegra (idtipolista, cam_id, status)
		select FN.value, C.cam_id, 1 from ccCamps C, dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',') FN where C.IDArea = @IDArea
		and C.cam_id not in (select CL.cam_id from Camplistanegra CL join dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',') FN
		on CL.idtipolista = FN.value where CL.status = 1)
		return(0)
	 end

 	update Camplistanegra set status = 1 where cam_id = @CamID
	and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ','))

	insert into Camplistanegra (idtipolista, cam_id, status)
	select value, @CamID, 1 from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',')
		where value not in (select idtipolista from Camplistanegra where cam_id = @CamID and status = 1
		and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',')))

	Insert Into ccAgendaListaNegra (campsid,fecharegs,fechaaplicar) values (@CamID,'20100101',getDate()) -- El 2010 es para que quite registros viejos con base en el cal fecha dial de ccocallsoutsource, principalmente para quitar callbacks de numeros cargados hace mucho tiempo

	declare @idAgenda as int
	select @idAgenda = SCOPE_IDENTITY()

	insert into ccAgenda_TipoListaNegra(idAgenda,idtipolista)
	select @idAgenda, value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',')

	return(0)
 end

if @Type = 5 -- Elimina BList
 begin
	if @CamID=0
	 begin
		update Camplistanegra set status = 0 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, ','))
		return(0)
	 end

	update Camplistanegra set status = 0 where cam_id = @CamID	and idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, ','))

	return(0)
 end

if @Type = 6 -- Regresa la lista de Areas
 begin
	if isnull(@User_id, 0) = 0 or (select login from ccusers
 where User_id = @User_id) = 'root'
	 begin
		select IDArea, AreaName from ccRIACAT_Areas order by AreaName
		return(0)
	 end

	select u.IDArea, a.AreaName
	from ccRIACAT_Areas a join ccusers u on u.IDArea = a.IDArea
	where u.User_id = @User_id
	order by AreaName
	return(0)
 end

if @Type = 7 -- trae las listas negras de la campaña
 begin
	select cl.cam_id, ca.cam_descripcion, cl.idtipolista blist_id, tl.Tipolista list_description
	from Camplistanegra cl join ccCamps ca on cl.cam_id = ca.cam_id
	 join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
	where cl.status = 1 and cl.cam_id = @CamID
	order by 1, 3
	return(0)
 end

return(0)
set nocount off