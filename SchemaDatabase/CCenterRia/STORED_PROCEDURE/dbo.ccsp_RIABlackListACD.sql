create PROCEDURE dbo.ccsp_RIABlackListACD
@Type smallint,
@IDArea smallint = 0,
@InboundID SmallInt = 0,
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

if @Type = 2 -- Cat_ACD
 begin
	Select c.inbound_id as ID, c.descripcion TIPO
	from ccInbound c join ccRIACat_Areas a on c.IDArea = a.IDArea
	where c.inbound_id in (select Inbound_id from dbo.fGet_CampAcd_Area(@User_id, 2))
	order by 2
	return(0)
 end

if @Type = 3 -- Relacion ACD vs BList
 begin
	select cl.inbound_id, ca.descripcion, cl.idtipolista blist_id, tl.Tipolista list_description
	from ACDlistanegra cl join ccInbound ca on cl.inbound_id = ca.inbound_id
	 join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
	where cl.status = 1 and cl.inbound_id = @InboundID
	order by 1, 3
	return(0)
 end

if @Type = 4 -- Inserta BList
 begin

	if @InboundID = 0
	 begin
		delete ACDlistanegra where idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ','))
	
		insert into ACDlistanegra (idtipolista, Inbound_id, status)
		select FN.value, C.Inbound_id, 1 from ccInbound C, dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',') FN 
		where C.Inbound_id not in (select CL.Inbound_id from ACDlistanegra CL join dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',') FN
		on CL.idtipolista = FN.value where CL.status = 1)
		return(0)
	 end

 	update ACDlistanegra set status = 1 where Inbound_id = @InboundID
	and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ','))
	
	insert into ACDlistanegra (idtipolista, Inbound_id, status)
	select value, @InboundID, 1 from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',') 
		where value not in (select idtipolista from ACDlistanegra where Inbound_id = @InboundID and status = 1
		and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',')))
	return(0)
 end

if @Type = 5 -- Elimina BList
 begin
	if @InboundID=0
	 begin
		update ACDlistanegra set status = 0 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, ','))
		return(0)
	 end
 
	update ACDlistanegra set status = 0 where Inbound_id = @InboundID and idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, ','))
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

return(0)
set nocount off