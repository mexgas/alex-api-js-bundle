CREATE PROCEDURE ccsp_GalateaAdminBlackListACD-- Guiandose del sp ccsp_RIABlackListACD
@Type smallint,
@InboundID SmallInt = 0,
@InsertSchedule_id varchar(max),
@DeleteSchedule_id varchar(max),
@ManyInboundIDs varchar(max)=''

as
set nocount on

if @Type = 2 -- Relacion many ACDs with all BLists
 begin
	select cl.inbound_id as CampId, ca.descripcion as CampName, cl.idtipolista as BlacklistId , tl.Tipolista as BlacklistName
	from ACDlistanegra cl join ccInbound ca on cl.inbound_id = ca.inbound_id
	 join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
	where cl.status = 1  and  cl.inbound_id in (select value from dbo.fn_RIASplitDelimited(@ManyInboundIDs, ','))
	order by 1, 3
	return(0)
 end

if @Type = 3 -- Relacion only one ACD with BLists
 begin
	select cl.inbound_id as CampId, ca.descripcion as CampName, cl.idtipolista as BlacklistId , tl.Tipolista as BlacklistName
	from ACDlistanegra cl join ccInbound ca on cl.inbound_id = ca.inbound_id
	 join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
	where cl.status = 1  and cl.inbound_id = @InboundID
	order by 1, 3
	return(0)
 end

if @Type = 4 -- Asignar BList a ACD
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

if @Type = 5 -- Desasignar BList a ACD
 begin
	if @InboundID=0
	 begin
		update ACDlistanegra set status = 0 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, ','))
		return(0)
	 end
 
	update ACDlistanegra set status = 0 where Inbound_id = @InboundID and idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, ','))
	return(0)
 end

return(0)